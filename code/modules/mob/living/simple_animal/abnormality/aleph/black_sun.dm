/mob/living/simple_animal/hostile/abnormality/black_sun
	name = "Waxing of the Black Sun"
	desc = "A sundial. Inscribed on the side is the phrase ''Memento Mori''."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "sundial"
	maxHealth = 1000
	health = 1000
	threat_level = ALEPH_LEVEL
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 55,
		ABNORMALITY_WORK_INSIGHT = 55,
		ABNORMALITY_WORK_ATTACHMENT = 55,
		ABNORMALITY_WORK_REPRESSION = 55
			)
	work_damage_amount = 32	//You get good work rates across the board but huge amounts of red.
	work_damage_type = RED_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/sloth

	generic_bubbles = alist(
		1 = list("%PERSON looks in horror at %ABNO.", "%ABNO is unmoving, but the dial shadows seem to move faster than what they should", "The blood Sings."),
		2 = list("%PERSON is burned by the warmt of the black sun.", "The containament cell bleeds with the rise of the sun"),
		3 = list("The Black Sun blinds %PERSON.", "%PERSON steps backwards to look at the abnormality. they stepped on something wet.", "the blood speaks to %PERSON, shifting to engrave itself on %PERSON's shoes"),
		4 = list("The sky grows brighter, yet darker.", "The floor of the Containament cell gains a red tint."),
		5 = list("%PERSON's skin sizzles.", "The Black Sun burns %PERSON.", "%PERSON has tears in their eyes while working."),
	)
	work_bubbles = list(
		ABNORMALITY_WORK_INSTINCT = list("%PERSON stares at %ABNO.", "'If you just work with it, everything will be fine, right?'"),
		ABNORMALITY_WORK_INSIGHT = list("%PERSON Tries to understand the timing of %ABNO.", "%PERSON attempts to syncronize their digital clock with %ABNO"),
		ABNORMALITY_WORK_ATTACHMENT = list("%PERSON Praises %ABNO to no avail.", "%PERSON prays.", "The beauty of the dark Horizon is too much to handle.", "%PERSON tries to accept the warmth of the black sun", "%PERSON tries to stare at %ABNO with sunglasses. they are blinded imediately.", "%PERSON tries to sing the hours on %ABNO, their mouth is now dry."),
		ABNORMALITY_WORK_REPRESSION = list("You may try, but you cannot.", "The blood is soothed by your pain.", "You feared thunder, rain and lightning, but now you will fear the Sun that rises in the dark Horizon."),
	)

	ego_list = list(
		/datum/ego_datum/weapon/arcadia,
		/datum/ego_datum/weapon/judge,
		/datum/ego_datum/armor/arcadia
		)
//	gift_type = /datum/ego_gifts/arcadia
	abnormality_origin = ABNORMALITY_ORIGIN_ORIGINAL

	//takes 12 minutes from the moment of getting it to breach, and cause a headache.
	var/breach_when
	var/breach_timer = 12 MINUTES
	var/timeloss = 2 MINUTES //Goes down 2 minutes every time someone dies.

/mob/living/simple_animal/hostile/abnormality/black_sun/Initialize()
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(on_mob_death))
	breach_when = world.time + breach_timer

/mob/living/simple_animal/hostile/abnormality/black_sun/Life()
	. = ..()
	if(breach_when < world.time)
		BreachEffect()

/mob/living/simple_animal/hostile/abnormality/black_sun/proc/on_mob_death(datum/source, mob/living/died, gibbed)
	SIGNAL_HANDLER
	if(!ishuman(died))
		return FALSE
	if(died.z != z)
		return FALSE
	breach_when += timeloss
	timeloss -= 10 SECONDS	//You can only stall it for so long.

/mob/living/simple_animal/hostile/abnormality/black_sun/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	to_chat(GLOB.clients, span_warning("The Black Sun fades from the sky. You are safe for now."))
	breach_when = world.time + breach_timer

/mob/living/simple_animal/hostile/abnormality/black_sun/BreachEffect()
	datum_reference.qliphoth_change(1)
	//Okay we're gonna make everyone go murder insane for like 12 seconds

	//Thank you Branch 12
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.z != z)
			continue
		if(!H.sanity_lost)
			H.adjustSanityLoss(500)
		QDEL_NULL(H.ai_controller)
		H.ai_controller = /datum/ai_controller/insane/murder/black_sun
		H.InitializeAIController()

	addtimer(CALLBACK(src, PROC_REF(resane_everyone)), 12 SECONDS)


/mob/living/simple_animal/hostile/abnormality/black_sun/proc/resane_everyone()
	for(var/mob/living/carbon/human/H in GLOB.mob_list)
		if(H.sanity_lost)
			H.adjustSanityLoss(-500)


/datum/ai_controller/insane/murder/black_sun
	lines_type = /datum/ai_behavior/say_line/insanity_black_sun

/datum/ai_behavior/say_line/insanity_black_sun
	lines = list(
		"The blood.... It sings to me.",
		"Our paradise.... It's here",
		"Perish, fool.",
		"Violence... I need violence....",
	)

//-----------------------------------------------------
//-----------------------------------------------------
//--------------The Old Black Sun stuff---------------
//-----------------------------------------------------
//-----------------------------------------------------

//Weather effect
/datum/weather/bloody_water
	name = "bloodwater"
	desc = "A visual water weather."

	telegraph_message = "<span class='warning'>Something feels off.</span>"
	telegraph_duration = 150

	weather_message = "<span class='danger'>The blood.... it sings to you</span>"
	weather_duration_lower = 1200
	weather_duration_upper = 1200
	weather_overlay = "bloodwater"

	end_message = "<span class='danger'>The blood subsides.</span>"
	end_duration = 0

	area_type = /area
	protected_areas = list(/area/space)
	target_trait = ZTRAIT_STATION

	overlay_layer = ABOVE_OPEN_TURF_LAYER //Covers floors only
	overlay_plane = FLOOR_PLANE


//Pillars. Do minor white damage, and fire projectiles
/mob/living/simple_animal/hostile/sun_pillar
	name = "pillar of the black sun"
	desc = "A glowing pillar."
	icon = 'ModularLobotomy/_Lobotomyicons/32x64.dmi'
	icon_state = "sun_pillar"
	icon_living = "sun_pillar"
	health = 2500
	maxHealth = 2500
	melee_damage_lower = 0
	melee_damage_upper = 0
	melee_damage_type = PALE_DAMAGE
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	attack_verb_continuous = "menaces"
	attack_verb_simple = "menace"
	attack_sound = 'sound/weapons/fixer/generic/nail1.ogg'
	mob_size = MOB_SIZE_TINY
	del_on_death = TRUE
	a_intent = INTENT_HARM
	var/aoe_range = 10

/mob/living/simple_animal/hostile/sun_pillar/Initialize()
	..()
	for(var/mob/living/simple_animal/hostile/sun_pillar/M in src.loc)	//Don't put two down at the same place
		if(M!=src)
			qdel(src)

/mob/living/simple_animal/hostile/sun_pillar/AttackingTarget()
	return FALSE

/mob/living/simple_animal/hostile/sun_pillar/Move()
	return FALSE

/mob/living/simple_animal/hostile/sun_pillar/Life()
	..()
	for(var/mob/living/L in GLOB.player_list)
		if(L.z != z)
			continue
		if(faction_check_mob(L))
			continue
		L.deal_damage(3, WHITE_DAMAGE, src, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_ENVIRONMENT | ATTACK_TYPE_SPECIAL))
		new /obj/effect/temp_visual/bluespace_fissure(get_turf(L))

	if(prob(10))
		Aoe()

	//Fire a buncha shit around the room too because it's cool
	var/list/all_turfs = RANGE_TURFS(7, src)
	for(var/turf/open/F in all_turfs)
		if(prob(30))
			addtimer(CALLBACK(src, PROC_REF(Firelaser), F), rand(1,30)) //offset so it looks like you're tossing a buncha shit around the room

/mob/living/simple_animal/hostile/sun_pillar/proc/Firelaser(turf/open/F)
	new /obj/effect/temp_visual/blacksun_laser(F)

//Laser attack
/obj/effect/temp_visual/blacksun_laser
	name = "black sun laser"
	icon = 'ModularLobotomy/_Lobotomyicons/32x64.dmi'
	icon_state = "pillar_strike"
	duration = 15

/obj/effect/temp_visual/blacksun_laser/Initialize()
	..()
	addtimer(CALLBACK(src, PROC_REF(blowup)), 10) //this is how long the animation takes

/obj/effect/temp_visual/blacksun_laser/proc/blowup()
	playsound(src, 'sound/weapons/laser.ogg', 10, FALSE, 4)
	for(var/mob/living/carbon/human/H in src.loc)
		H.deal_damage(60, WHITE_DAMAGE, attack_type = (ATTACK_TYPE_SPECIAL | ATTACK_TYPE_ENVIRONMENT))
		H.deal_damage(30, PALE_DAMAGE, attack_type = (ATTACK_TYPE_SPECIAL | ATTACK_TYPE_ENVIRONMENT))
		if(H.sanity_lost)
			H.gib()

//Kills the insane it does a fuckload of white damage, deal black too.
/mob/living/simple_animal/hostile/sun_pillar/proc/Aoe()
	playsound(src, 'sound/weapons/wave.ogg', 100, FALSE, 4)
	var/turf/orgin = get_turf(src)
	var/list/all_turfs = RANGE_TURFS(aoe_range, orgin)
	for(var/i = 0 to aoe_range)
		for(var/turf/T in all_turfs)
			if(get_dist(orgin, T) > i)
				continue
			new /obj/effect/temp_visual/sunwave(T)
			for(var/mob/living/carbon/human/L in T)
				if(L.sanity_lost)		//Kill the insane
					L.death()
				L.deal_damage(60, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL | ATTACK_TYPE_ENVIRONMENT))

			all_turfs -= T
		SLEEP_CHECK_DEATH(5)

//Visual effects
/obj/effect/temp_visual/sunwave
	icon = 'icons/effects/atmospherics.dmi'
	icon_state = "zauker"
	duration = 6

