
/obj/structure/liuradio
	name = "War radio"
	desc = "A radio used by Liu fixers to locate targets and escalate combat."
	icon = 'icons/obj/radio.dmi'
	icon_state = "radio"
	color = "#FF0000"
	max_integrity = 300
	density = 1
	anchored = 1
	resistance_flags = INDESTRUCTIBLE
	var/isready = TRUE
	var/list/deploy_pool = list()
	var/escalation = 0
	var/list/t1_targets = list(
		/mob/living/simple_animal/hostile/ordeal/indigo_dawn,
		/mob/living/simple_animal/hostile/ordeal/green_bot,
		/mob/living/simple_animal/hostile/ordeal/steel_dawn,
		/mob/living/simple_animal/hostile/clan/scout,
		/mob/living/simple_animal/hostile/humanoid/blood/bag,
		/mob/living/simple_animal/hostile/greed,
	)
	var/list/t2_targets = list(
		/mob/living/simple_animal/hostile/ordeal/indigo_noon,
		/mob/living/simple_animal/hostile/ordeal/green_bot_big,
		/mob/living/simple_animal/hostile/ordeal/citrine/knight,
		/mob/living/simple_animal/hostile/bloodfiend_mook,
		/mob/living/simple_animal/hostile/greed/tank,
	)
	var/list/t3_targets = list(
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale,
		/mob/living/simple_animal/hostile/humanoid/blood/fiend,
		/mob/living/simple_animal/hostile/ordeal/green_dusk,
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black,
	)

/obj/structure/liuradio/examine(mob/user)
    . = ..()
    . += span_notice("Current Escalation level is: [escalation]")

/obj/structure/liuradio/attack_hand(mob/user)
	if(!isready)
		say("The streets are clear, for now.")
		return

	isready = FALSE
	FindTarget(user)

/obj/structure/liuradio/proc/FindTarget(mob/living/user)
	var/spawncount = 1
	var/nexttarget
	var/roll = rand(0,escalation)
	var/reward = /obj/item/stack/spacecash/c1000
	switch(roll)
		if(0 to 3)
			nexttarget = pick(t1_targets)
			spawncount = (escalation + 2) * 3
			if(prob(10))
				reward = /obj/item/choice_beacon/liu
		if(4 to 6)
			nexttarget = pick(t2_targets)
			spawncount = (escalation - 2) * 2
			if(prob(50))
				reward = /obj/item/choice_beacon/liu
		if(7 to INFINITY)
			nexttarget = pick(t3_targets)
			spawncount = (escalation - 6)
			if(prob(75))
				reward = /obj/item/choice_beacon/liu

	for(var/obj/effect/landmark/cityspawner/landmark in GLOB.landmarks_list)
		deploy_pool += landmark
	if(!length(deploy_pool))
		return
	var/turf/deploy_spot = get_turf(pick(deploy_pool))
	var/list/deploy_area = list()
	for(var/turf/open/T in range(1, deploy_spot))
		deploy_area+=T
	for(var/i in 1 to spawncount)
		new nexttarget(pick(deploy_area))
	say("New target detected, payment issued preemptively.")
	if(escalation < 8)
		escalation += 1
	new reward (get_turf(src))
	addtimer(CALLBACK(src, PROC_REF(NewTarget)), 10 MINUTES)

/obj/structure/liuradio/proc/NewTarget()
	isready = TRUE

/obj/item/choice_beacon/liu
	name = "War Escalation Beacon"
	desc = "A beacon Liu fixers can use to requisition stronger gear."

/obj/item/choice_beacon/liu/generate_display_names()
	var/static/list/beacon_item_list
	if(!beacon_item_list)
		beacon_item_list = list()
		var/list/templist = subtypesof(/obj/item/storage/box/liugear)
		for(var/V in templist)
			var/atom/A = V
			beacon_item_list[initial(A.name)] = A
	return beacon_item_list

/obj/item/choice_beacon/liu/spawn_option(obj/choice,mob/living/M)
	new choice(get_turf(M))
	to_chat(M, span_hear("Make sure you put the equipment away."))

/obj/item/storage/box/liugear/sword
	name = "Blade Kit"
	desc = "A kit containing a liu blade."

/obj/item/storage/box/liugear/sword/PopulateContents()
	new /obj/item/ego_weapon/city/liu/fire/warsword(src)

/obj/item/storage/box/liugear/polearm
	name = "Spear Kit"
	desc = "A kit containing a liu spear."

/obj/item/storage/box/liugear/polearm/PopulateContents()
	new /obj/item/ego_weapon/city/liu/fire/warspear(src)

/obj/item/storage/box/liugear/fists
	name = "Gloves kit"
	desc = "A kit containing upgraded liu gloves."

/obj/item/storage/box/liugear/fists/PopulateContents()
	new /obj/item/ego_weapon/city/liu/fire/warfist(src)

/obj/item/ego_weapon/city/liu/fire/warfist
	name = "liu flaming glove"
	desc = "A stronger fist delivered by the director due to escalating enemy presence."
	icon_state = "liuglove"
	force = 30
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)
	swingstyle = WEAPONSWING_SMALLSWEEP

/obj/item/ego_weapon/city/liu/fire/warspear
	name = "liu spear"
	desc = "A spear delivered by the director due to escalating enemy presence."
	icon_state = "liuspear"
	force = 45
	reach = 2
	stuntime = 5
	attack_speed = 1
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)
	swingstyle = WEAPONSWING_THRUST


/obj/item/ego_weapon/city/liu/fire/warsword
	name = "liu sword"
	desc = "A sword delivered by the director due to escalating enemy presence."
	icon_state = "liublade"
	force = 25
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)
	swingstyle = WEAPONSWING_LARGESWEEP

