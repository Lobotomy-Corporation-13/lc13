//Support due to choreographed dashes and passive AoE lightning
/mob/living/simple_animal/hostile/rcorp_abno/hard/thunder_bird
	name = "Thunderbird"
	desc = "A hulking avian wreathed in electricity. It looks angry. Lightning falls around it, reanimating the dead and shocking the living."
	var/charge_icon = "thunderbird_charge"
	del_on_death = FALSE
	light_color = LIGHT_COLOR_BLUE
	light_range = 5
	light_power = 7
	maxHealth = 1200	//Reduced due to snowballing and range.
	health = 1200
	move_to_delay = 4
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 1, PALE_DAMAGE = 0.7)
	original_abno = /mob/living/simple_animal/hostile/abnormality/thunder_bird

	/*---Combat---*/
	//Melee stats
	melee_damage_lower = 10
	melee_damage_upper = 15
	melee_damage_type = BLACK_DAMAGE
	rapid_melee = 2
	vision_range = 15
	aggro_vision_range = 30
	ranged = TRUE//allows it to attempt charging without being in melee range

	//range and attack speed for thunder bombs, taken from general bee
	var/fire_cooldown_time = 3 SECONDS
	var/fireball_range = 7
	var/fire_cooldown
	var/targetAmount = 0

	//Stolen charge code from helper
	var/charging = FALSE
	var/dash_num = 10//the length of the dash, in tiles
	var/dash_cooldown = 0
	var/dash_cooldown_time = 4 SECONDS

	var/obj/effect/proc_holder/ability/aimed/rca_dash/thunderbird/ourdash

	abno_additional_instructions = "<h1>You are Thunderbird, A Support Role Abnormality.</h1><br>\
		<b>|Thunderbird|: Every 3 seconds summon Thunder on the location of hostiles dead and alive within 7 tiles of your location. \
		When the Thunder falls it will perform 50 BLACK damage in a 3x3 AoE. \
		 If the target hit by this thunder is in a critical state or dead trigger |Sacrifice|. <br>\
		<br>\
		|Feather of Valor|: When your dash is enabled you will dash in whichever direction you click at. \
		This dash has a 1.5 second windup, after complete you will travel 10 tiles. \
		The dash has a width of 3 tiles, any living beings impacted by this dash will take 100 BLACK damage. <br>\
		<br>\
		|Sacrifice|: When triggered resurrect the target as a Thunderbird Worshipper. \
		If a Thunderbird Worshipper is killed resurrect them after 30 sesconds if their body is left intact. <br>\
		<br>\
		|Sacrilege|: When you are killed all Thunderbird Worshippers are dusted, dying along with you. </b>"

/mob/living/simple_animal/hostile/rcorp_abno/hard/thunder_bird/Initialize()
	.  = ..()
	icon_living = "thunderbird_breach"
	icon_state = icon_living
	ourdash = new()

//attempts to charge its target regardless of distance with a short cooldown. Can be spammed if distant enough.
/mob/living/simple_animal/hostile/rcorp_abno/hard/thunder_bird/AttackingTarget(atom/attacked_target)
	if(charging)
		return
	if(dash_cooldown <= world.time && prob(10) && !client)
		thunder_bird_dash(attacked_target)
		return
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/thunder_bird/Move()
	if(charging)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/thunder_bird/OpenFire()
	if(client)
		switch(chosen_attack)
			if(1)
				thunder_bird_dash(target)
		return

	if(dash_cooldown <= world.time)
		var/chance_to_dash = 50
		if(prob(chance_to_dash))
			thunder_bird_dash(target)

/mob/living/simple_animal/hostile/rcorp_abno/hard/thunder_bird/death()
	if(health > 0)
		return
	icon = 'ModularLobotomy/_Lobotomyicons/abno_cores/waw.dmi'
	density = FALSE
	playsound(src, 'sound/abnormalities/thunderbird/tbird_charge.ogg', 100, 1)
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)
	return ..()

//fires bombs that deal 45 black damage towards anyone within 1 tile, they also turn the dead and dying into zombies.
/mob/living/simple_animal/hostile/rcorp_abno/hard/thunder_bird/Life()
	. = ..()
	if(!.) // Dead
		return FALSE
	if((fire_cooldown < world.time))
		fireshell()

/*---Dash Stuff ---*/
/mob/living/simple_animal/hostile/rcorp_abno/hard/thunder_bird/proc/thunder_bird_dash(target)
	if(charging || dash_cooldown > world.time)
		return
	charging = TRUE
	icon_state = charge_icon
	dash_cooldown = world.time + dash_cooldown_time
	ourdash.Perform(target,src)

/mob/living/simple_animal/hostile/rcorp_abno/hard/thunder_bird/proc/endCharge()
	charging = FALSE
	icon_state = icon_living

/obj/effect/proc_holder/ability/aimed/rca_dash/thunderbird
	name = "thunderbird dash"
	dash_speed =  1
	dash_damage = 100
	dash_range = 10
	windup_delay = 1.5 SECONDS
	cooldown_time = 4 SECONDS
	var/list/thunder_bird_lines = list(
		"Prostrate yourself! Harder!",
		"Do you think I am happy, feather? Think again!",
		"You folk, nothing but sacrifices. Sacrifices for me and everyone else here!",
		"Your kind can never be forgiven!",
		"Look around, you monsters! You've destroyed my people and nature!",
	)

/obj/effect/proc_holder/ability/aimed/rca_dash/thunderbird/Finalize(target, mob/living/user, list/path_list) //Doing this here because if done earlier he says shit and plays sound without a valid charge
	..()
	user.say(pick(thunder_bird_lines))
	playsound(user, 'sound/abnormalities/thunderbird/tbird_charge.ogg', 100, 1)

/obj/effect/proc_holder/ability/aimed/rca_dash/thunderbird/DashMove(mob/living/user, turf/last_turf, times_ran = 1, list/dash_list)
	..()
	playsound(user,"sound/abnormalities/thunderbird/tbird_peck.ogg", rand(30, 50), 1) //Play this sound on every tile moved

/obj/effect/proc_holder/ability/aimed/rca_dash/thunderbird/TurfEffects(turf/T, mob/living/ourthing)
	for(var/turf/U in GetRange(T, 1))
		if(!U)
			break
		if(isopenturf(U) && !HasIdentList(U))
			FlickOnAtom(U,'icons/effects/effects.dmi',"smash",5)
		var/list/new_hits = HurtInTurf(ourthing, U, list(), dash_damage, BLACK_DAMAGE, hurt_mechs = TRUE, flags = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		var/flicks = FALSE
		for(var/mob/living/L in new_hits)//damage applied to targets in range
			if(!ourthing.faction_check_mob(L))
				visible_message(span_boldwarning("[ourthing] runs through [L]!"))
				to_chat(L, span_userdanger("[ourthing] rushes past you, arcing electricity throughout the way!"))
				if(!flicks)
					playsound(L, 'sound/abnormalities/thunderbird/tbird_peck.ogg', 75, 1)
					FlickOnAtom(U,'icons/obj/projectiles.dmi',"kinetic_blast",4)
					flicks = TRUE
				if(ishuman(L))
					var/mob/living/carbon/human/H = L
					H.electrocute_act(1, ourthing, flags = SHOCK_NOSTUN)
		for(var/obj/vehicle/sealed/mecha/V in new_hits)
			visible_message(span_boldwarning("[ourthing] runs through [V]!"))
			to_chat(V.occupants, span_userdanger("[ourthing] rushes past you, arcing electricity throughout the way!"))
			if(!flicks)
				playsound(V, 'sound/abnormalities/thunderbird/tbird_peck.ogg', 75, 1)
				flicks = TRUE
	return ..()

/obj/effect/proc_holder/ability/aimed/rca_dash/thunderbird/AbnoInteraction(mob/living/user)
	if(!istype(user, /mob/living/simple_animal/hostile/rcorp_abno/hard/thunder_bird))
		return
	var/mob/living/simple_animal/hostile/rcorp_abno/hard/thunder_bird/abno = user
	playsound(user, 'sound/abnormalities/thunderbird/tbird_bolt.ogg', 75, 1)
	ToggleAct(abno,TRUE)
	abno.endCharge()

//thunderbolts
/mob/living/simple_animal/hostile/rcorp_abno/hard/thunder_bird/proc/fireshell()
	fire_cooldown = world.time + fire_cooldown_time
	var/list/hit_turfs = list()
	for(var/mob/living/carbon/human/L in range(fireball_range, src))
		if(faction_check_mob(L, FALSE))
			continue
		var/turf_tag = "[L.x],[L.y]"
		if(turf_tag in hit_turfs)
			continue
		if(targetAmount <= 2)
			++targetAmount
			var/obj/effect/rca_thunderbolt/E = new(get_turf(L.loc))//do this for the # of targets + 1
			E.creator = src
			hit_turfs = turf_tag
	targetAmount = 0

//thunderbolt objects
/obj/effect/rca_thunderbolt
	name = "thunder bolt"
	desc = "LOOK OUT!"
	icon = 'icons/effects/effects.dmi'
	icon_state = "tbird_bolt"
	move_force = INFINITY
	pull_force = INFINITY
	generic_canpass = FALSE
	movement_type = PHASING | FLYING
	var/boom_damage = 50
	layer = POINT_LAYER	//Sprite should always be visible
	var/duration = 3 SECONDS
	var/range = 1
	var/mob/living/creator

/obj/effect/rca_thunderbolt/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(Explode)), duration)

/obj/effect/rca_thunderbolt/Destroy()
	creator = null
	return ..()

//Zombie conversion through lightning bombs
/obj/effect/rca_thunderbolt/proc/Convert(mob/living/carbon/human/H)
	if(!istype(H))
		return
	playsound(get_turf(src), 'sound/abnormalities/thunderbird/tbird_zombify.ogg', 45, FALSE, 5)
	var/mob/living/simple_animal/hostile/rca_thunder_zombie/C = new(get_turf(H))
	if(creator)
		C.LinkSoul(creator)
	if(!QDELETED(H))
		C.name = "[H.real_name]"//applies the target's name and adds the name to its description
		C.desc = "What appears to be [H.real_name], only charred and screaming incoherently..."
		C.gender = H.gender
		H.gib(TRUE,TRUE,TRUE)

//Smaller Scorched Girl bomb
/obj/effect/rca_thunderbolt/proc/Explode()
	playsound(get_turf(src), 'sound/abnormalities/thunderbird/tbird_bolt.ogg', 50, 0, 8)
	var/list/turfs_to_check = view(range, src)
	for(var/mob/living/carbon/human/H in turfs_to_check)
		H.deal_damage(boom_damage, BLACK_DAMAGE, attack_type = (ATTACK_TYPE_SPECIAL))
		H.electrocute_act(1, src, flags = SHOCK_NOSTUN)
		if(H.health < 0)
			Convert(H)
	for(var/obj/vehicle/V in turfs_to_check)
		V.take_damage(boom_damage, BLACK_DAMAGE)
	new /obj/effect/temp_visual/tbirdlightning(get_turf(src))
	var/datum/effect_system/smoke_spread/S = new
	S.set_up(0, get_turf(src))	//Smoke shouldn't really obstruct your vision
	S.start()
	qdel(src)

/*--Zombies!--*/
//zombie mob
/mob/living/simple_animal/hostile/rca_thunder_zombie
	name = "Thunderbird Worshipper"
	desc = "An pitiable remnant of what was once human. Scalped, charred, and screaming incoherently..."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "thunder_zombie2"
	icon_living = "thunder_zombie2"
	icon_dead = "thunder_zombie_dead2"
	speak_emote = list("groans", "moans", "howls", "screeches", "grunts")
	gender = NEUTER
	attack_verb_continuous = "attacks"
	attack_verb_simple = "attack"
	attack_sound = 'sound/abnormalities/thunderbird/tbird_zombieattack.ogg'

	/*Zombie Stats */
	health = 250//subject to change; they all die when thunderbird is suppressed
	maxHealth = 250
	obj_damage = 60
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 0.5)
	melee_damage_type = BLACK_DAMAGE
	melee_damage_lower = 20
	melee_damage_upper = 30
	speed = 5
	move_to_delay = 3
	robust_searching = TRUE
	stat_attack = HARD_CRIT
	//Ressurects
	del_on_death = FALSE
	density = TRUE
	guaranteed_butcher_results = list(/obj/item/food/badrecipe = 1)
	var/ressurection_cooldown = 0
	var/mob/living/master

/mob/living/simple_animal/hostile/rca_thunder_zombie/Login()
	. = ..()
	to_chat(src, "<h1>You are Thunderbird Worshipper, A Thunderbird Minion.</h1><br>\
		<b>|Sacrifice|: When attacking a human being which is in critical state or dead you will convert them into another Thunderbird Worshipper. <br>\
		<br>\
		|Good Day To Die|: When killed resurrect after 30 seconds, destruction of your corpse prevents resurrection. <br>\
		<br>\
		|Sacrilege|: When Thunderbird is killed all Thunderbird Worshippers including yourself will turn to dust.</b>")

//Zombie conversion from zombie kills
/mob/living/simple_animal/hostile/rca_thunder_zombie/AttackingTarget(atom/attacked_target)
	. = ..()
	if(!can_act)
		return
	if(!ishuman(attacked_target))
		return
	var/mob/living/carbon/human/H = attacked_target
	if(H.stat >= SOFT_CRIT || H.health < 0)
		Convert(H)

/mob/living/simple_animal/hostile/rca_thunder_zombie/Initialize()
	. = ..()
	playsound(get_turf(src), 'sound/abnormalities/thunderbird/tbird_charge.ogg', 50, 1, 4)

/mob/living/simple_animal/hostile/rca_thunder_zombie/Life()
	. = ..()
	if(!.) // Dead
		if(ressurection_cooldown <= world.time && master)
			resurrect()
		return FALSE
	if(status_flags & GODMODE)
		return FALSE

//reanimated if thunderbird isn't suppressed within 30 seconds
/mob/living/simple_animal/hostile/rca_thunder_zombie/death(gibbed)
	if(!gibbed)
		ressurection_cooldown = world.time + (30 SECONDS)
	return ..()

/mob/living/simple_animal/hostile/rca_thunder_zombie/Destroy()
	if(master)
		UnregisterSignal(master, list(COMSIG_PARENT_QDELETING))
	master = null
	return ..()

/mob/living/simple_animal/hostile/rca_thunder_zombie/proc/resurrect()
	if(QDELETED(src))
		return
	revive(full_heal = TRUE, admin_revive = FALSE)
	visible_message(span_boldwarning("[src] staggers back on their feet!"))
	playsound(get_turf(src), 'sound/abnormalities/thunderbird/tbird_bolt.ogg', 50, 0, 8)

//Zombie conversion from other zombies
/mob/living/simple_animal/hostile/rca_thunder_zombie/proc/Convert(mob/living/carbon/human/H)
	if(!istype(H))
		return
	if(!can_act)
		return
	can_act = FALSE
	forceMove(get_turf(H))
	playsound(src, 'sound/abnormalities/thunderbird/tbird_zombify.ogg', 45, FALSE, 5)
	SLEEP_CHECK_DEATH(3)
	for(var/i = 1 to 4)
		new /obj/effect/temp_visual/sparks(get_turf(src))
		SLEEP_CHECK_DEATH(5.5)
	if(!QDELETED(H))
		if(!H.real_name)
			return FALSE
		var/mob/living/simple_animal/hostile/rca_thunder_zombie/C = new(get_turf(src))
		if(master)
			C.LinkSoul(master)
		C.name = "[H.real_name]"//applies the target's name and adds the name to its description
		C.desc = "What appears to be [H.real_name], only charred and screaming incoherently..."
		C.gender = H.gender
		H.gib(TRUE,TRUE,TRUE)
	can_act = TRUE

/mob/living/simple_animal/hostile/rca_thunder_zombie/proc/LinkSoul(new_link)
	if(!new_link)
		return
	master = new_link
	RegisterSignal(new_link, list(COMSIG_PARENT_QDELETING), PROC_REF(ShatterSoul))
	if(isliving(new_link))
		var/mob/living/L = new_link
		faction = L.faction.Copy()

/mob/living/simple_animal/hostile/rca_thunder_zombie/proc/ShatterSoul()
	if(master)
		UnregisterSignal(master, list(COMSIG_PARENT_QDELETING))
	master = null
	dust(TRUE,TRUE,TRUE)
