// K-Corp Drone
/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder
	name = "K-Corp recorder drone"
	desc = "Medium sized drone suspensed in the air, humming as it flies."
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "kcorp_drone_ded"
	icon_living = "kcorp_drone_idle"
	icon_dead = "kcorp_drone_ded"
	faction = list("neutral", "kcorp")
	maxHealth = 1000
	health = 1000
	//Simply a shell for a player
	AIStatus = AI_OFF
	pass_flags = PASSTABLE
	density = FALSE
	a_intent = INTENT_HELP
	// Holding items code is weird because its reliant on the held_items list
	dextrous = TRUE
	held_items = list(null)
	speech_span = SPAN_ROBOT
	possible_a_intents = list(INTENT_HELP, INTENT_GRAB, INTENT_HARM)
	move_to_delay = 2
	turns_per_move = 3
	death_message = "Smashes on the ground."
	loot = list(/obj/effect/decal/cleanable/robot_debris)
	flash_cooldown_time = 30 SECONDS
	flash_range = 1

	var/scan_cooldown = 0
	//You must witness a entity go from living to dead within this time limit
	var/scan_delay = 0.6 SECONDS

	//Who did we last see alive
	var/list/scan_buffer = list()

	//Monies gained by seeing things die
	var/monies = 0

/*------\
|ABILITY|
\------*/
/datum/action/cooldown/dispense_monies
	name = "Dispense Stored Cash"
	icon_icon = 'icons/mob/actions/actions_spells.dmi'
	button_icon_state = "magicm"
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE
	cooldown_time = 1 SECONDS //Player cooldown

/datum/action/cooldown/dispense_monies/Trigger()
	if(!..())
		return FALSE
	var/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder/K = owner
	if(!istype(K))
		return FALSE
	if(!K.client)
		return FALSE
	StartCooldown()
	K.DispenseMoney()
	return TRUE

/*---\
|MAIN|
\---*/
/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder/Initialize(mapload)
	. = ..()
	var/datum/action/place_room/place_action = new
	place_action.Grant(src)
	var/datum/action/cooldown/dispense_monies/attack_action = new
	attack_action.Grant(src)
	RegisterJobRadioChannel("Kcorp", COLOR_VERY_PALE_LIME_GREEN)
	/*
	* Sorry about this overly complicated
	* rework of a slime internal radio. -IP
	*/
	var/obj/item/implant/radio/slime/imp = new(src)
	imp.implant(src, null, TRUE, TRUE)
	var/obj/item/radio/R = imp.radio
	R.freerange = TRUE
	RegisterJobRadioChannel("Kcorp", COLOR_VERY_PALE_LIME_GREEN)
	R.SetJobChannel("Kcorp")
	R.freqlock = TRUE
	R.command = TRUE
	access_card = new(src)
	access_card.access = list("kcorp")

/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder/Login()
	. = ..()
	if(!. || !client)
		return FALSE
	update_icon()

/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder/Destroy()
	UnregisterAll()
	QDEL_NULL(access_card)
	return ..()

/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder/death(gibbed)
	Explode()
	return ..()

/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder/Life()
	. = ..()
	if(!. || !client)
		return

	/*
	* Sutures would normally heal the drone but due to the
	* niche nature of sutures we will give the drone passive heal.
	*/
	if(health <= maxHealth*0.95 && stat != DEAD)
		adjustBruteLoss(-5)

	if(scan_cooldown <= world.time)
		Scan()
		scan_cooldown = world.time + scan_delay

/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder/get_status_tab_items()
	. = ..()
	. += "Stored Money: [monies]"

/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder/update_icon_state()
	if(stat == DEAD || !client || !can_act)
		icon_state = icon_dead
		return
	if(color == COLOR_GRAY)
		color = null
	icon_state = icon_living
	return ..()

/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder/spawn_gibs()
	new /obj/effect/gibspawner/scrap_metal(drop_location(), src)

/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder/drop_loot()
	DispenseMoney()
	return ..()

//EXPLODES INTO MONEY!!!
/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder/proc/Explode()
	var/list/debris = DispenseMoney()
	playsound(get_turf(src), 'sound/effects/meteorimpact.ogg', 50, TRUE)
	var/list/random_turfs = SurroundTarget(src,5)
	if(!random_turfs)
		return
	for(var/obj/D in debris)
		if(!D)
			continue
		D.throw_at(pick(random_turfs), 3, 2)

//Dispenses money
/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder/proc/DispenseMoney()
	if(monies <= 0)
		return
	var/our_monies = monies
	var/turf/droppoint = get_turf(src)
	var/list/spawned_monies = list()
	monies = 0
	/*
	* Okay sorry this looks so complicate but hear me out
	* Each cycle gets a divider that divides the amount
	* by the value of the item.
	*/
	for(var/cycle = 1 to 4)
		var/divider = 500
		var/spawn_type = /obj/item/stack/spacecash/c500
		switch(cycle)
			if(2)
				divider = 100
				spawn_type = /obj/item/stack/spacecash/c100
			if(3)
				divider = 10
				spawn_type = /obj/item/coin/silver
			if(4)
				divider = 1
				spawn_type = /obj/item/coin
		var/this_value = trunc(our_monies / divider)
		our_monies -= (this_value * divider)
		spawned_monies += SortMoney(droppoint,this_value,spawn_type)
	return spawned_monies

/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder/proc/SortMoney(turf/droppoint, value = 0, drop_thing)
	if(!value)
		return list()
	var/list/moola = list()
	for(var/hunder = 1 to value)
		var/obj/dollhairs = new drop_thing(droppoint)
		moola += dollhairs
	return moola

/*
* Empty out all scans and then fill the buffer with new
* living creatures every scan_delay.
*/
/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder/proc/Scan()
	UnregisterAll()
	//If more than 20 entities are on the screen it becomes difficult to record them
	var/max_scans = 20
	var/current_scans = 0
	for(var/mob/living/carbon/L in oview(src, 9))
		if(current_scans >= max_scans)
			break
		if(L.stat != DEAD)
			RegisterMob(L)
		current_scans++

//Make sure you watch them die or they die within the time delay
/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder/proc/MobDeath(mob/living/L)
	playsound(loc, 'sound/items/timer.ogg', 50, 3, 3)
	monies += 350
	UnregisterMob(L)

/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder/proc/RegisterMob(mob/living/L)
	RegisterSignal(L, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING), PROC_REF(MobDeath))
	scan_buffer += L

/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder/proc/UnregisterMob(mob/living/L)
	if(L)
		UnregisterSignal(L, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	scan_buffer -= L

/mob/living/simple_animal/hostile/kcorp/drone/kcorp_recorder/proc/UnregisterAll()
	for(var/mob/living/L in scan_buffer)
		UnregisterMob(L)
	scan_buffer.Cut()

/*----------------------\
|City Specific Abilities|
\----------------------*/
/datum/action/place_room
	name = "Place Room"
	desc = "Places a room in the location."
	icon_icon = 'icons/mob/actions/actions_changeling.dmi'
	button_icon_state = "resonant_shriek"

/datum/action/place_room/Trigger()
	var/mob/living/user = owner
	var/ready
	for(var/obj/effect/landmark/fixerbase/landmark in GLOB.landmarks_list)
		if((get_turf(landmark)) == (get_turf(user)))
			ready = TRUE
			break
	if(!ready)
		to_chat(user, span_warning("\The ability will not function in this area. Please move to a designated fixer office space."))
		return
	PlaceRoom(user)
	. = ..()
	Remove(user)

//Extremely sloppy way to do this for me. -IP
/datum/action/place_room/proc/PlaceRoom(mob/user)
	var/obj/item/structurecapsule/fixer/kcorp/K = new(get_turf(user))
	K.attack_self()

