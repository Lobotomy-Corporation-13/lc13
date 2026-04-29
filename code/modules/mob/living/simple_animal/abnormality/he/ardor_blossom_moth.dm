/mob/living/simple_animal/hostile/abnormality/ardor_moth
	name = "Ardor Blossom Moth"
	desc = "A moth seemingly made of fire."
	icon = 'ModularLobotomy/_Lobotomyicons/48x48.dmi'
	pixel_x = -8
	base_pixel_x = -8
	icon_state = "blossom_moth"
	icon_living = "blossom_moth"
	portrait = "blossom_moth"
	maxHealth = 800
	health = 800
	blood_volume = 0
	ranged = TRUE
	attack_verb_continuous = "sears"
	attack_verb_simple = "sear"
	is_flying_animal = TRUE
	ranged = TRUE
	stat_attack = HARD_CRIT
	melee_damage_lower = 11
	melee_damage_upper = 12
	attack_sound = 'sound/weapons/bite.ogg'
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.5, WHITE_DAMAGE = 1, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 2, FIRE = 0.2)
	speak_emote = list("flutters")
	vision_range = 14
	aggro_vision_range = 20

	can_breach = TRUE
	threat_level = HE_LEVEL
	faction = list("hostile")
	start_qliphoth = 3
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 45,
		ABNORMALITY_WORK_INSIGHT = 35,
		ABNORMALITY_WORK_ATTACHMENT = 20,
		ABNORMALITY_WORK_REPRESSION = 50,
	)
	work_damage_amount = 7
	work_damage_type = RED_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/wrath
	patrol_cooldown_time = 3 SECONDS

	ego_list = list(
		/datum/ego_datum/weapon/ardor_star,
		/datum/ego_datum/armor/ardor_star,
	)
	gift_type =  /datum/ego_gifts/ardor_moth
	abnormality_origin = ABNORMALITY_ORIGIN_LIMBUS

	observation_prompt = "Orange circles float in the air before your eyes. <br>\
		The lights flutter and dance in the air, creating a haze. <br>\
		Something is burning to death within. <br>\
		Would you be scorched as well if the flames touched you?"
	observation_choices = list(
		"Reach out" = list(TRUE, "Enchanted by the haze, you extend a finger, <br>\
			waiting for one of the lights to land. <br>\
			A glimmering ball gently perches on your digit. <br>\
			Then, a fire engulfs it. <br>\
			Another glow attaches to your body, then four, then eight. <br>\
			They multiply until you have been entirely shrouded in light."),
		"Turn around" = list(FALSE, "Resisting the temptation to reach out, <br>\
			you decide it’s better to stay away from such dubious warmth. <br>\
			You feel a cold wave crawl up your spine in an instant, but it may be the right choice. <br>\
			Even children know not to play with fire."),
	)

	var/stoked
	var/stoke_timer
	var/prepping_fire
	light_color = COLOR_ORANGE
	light_range = 5
	light_power = 7
	light_on = FALSE

/mob/living/simple_animal/hostile/abnormality/ardor_moth/WorkChance(mob/living/carbon/human/user, chance, work_type)
	if(stoked)
		chance+=10
		datum_reference.qliphoth_change(1)
	return chance

/mob/living/simple_animal/hostile/abnormality/ardor_moth/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	if(!stoked && work_type != ABNORMALITY_WORK_ATTACHMENT)
		if(prob(30))
			datum_reference.qliphoth_change(-2)

	switch(work_type)
		if(ABNORMALITY_WORK_ATTACHMENT)
			faction = list("neutral", "hostile")
			stoked = TRUE
			light_on = TRUE
			update_light()
			deltimer(stoke_timer)
			stoke_timer = addtimer(CALLBACK(src, PROC_REF(Stoke)), 2 MINUTES, TIMER_STOPPABLE)
			user.client?.give_award(/datum/award/achievement/abno/kindling, user)
			to_chat(user, span_notice("You stoke the flames, and it burns hotter."))

/mob/living/simple_animal/hostile/abnormality/ardor_moth/proc/Stoke()
	if (!IsContained())
		return
	faction = list("hostile")
	stoked = FALSE
	light_on = FALSE
	update_light()

/mob/living/simple_animal/hostile/abnormality/ardor_moth/Destroy(force)
	deltimer(stoke_timer)
	if(!prepping_fire)
		prepping_fire = TRUE
		Explosion()
	return ..()

/mob/living/simple_animal/hostile/abnormality/ardor_moth/Move()
	if(prepping_fire)
		return
	..()
	for(var/turf/open/T in range(1, src))
		if(locate(/obj/effect/turf_fire/ardor) in T)
			for(var/obj/effect/turf_fire/ardor/floor_fire in T)
				qdel(floor_fire)
		new /obj/effect/turf_fire/ardor(T)

/mob/living/simple_animal/hostile/abnormality/ardor_moth/spawn_gibs()
	return new /obj/effect/decal/cleanable/ash(drop_location(), src)

/mob/living/simple_animal/hostile/abnormality/ardor_moth/OpenFire()
	..()
	if(prepping_fire)
		return
	if(prob(0.5))
		prepping_fire = TRUE
		Explosion()
		return

	if(prob(50))
		switch (rand(1,2))
			if(1)
				prepping_fire = TRUE
				manual_emote("rears back...")
				addtimer(CALLBACK(src, PROC_REF(SpitFire)), 10, TIMER_STOPPABLE)
			if(2)
				prepping_fire = TRUE
				manual_emote("emits heat...")
				addtimer(CALLBACK(src, PROC_REF(BurnAll)), 10, TIMER_STOPPABLE)


/mob/living/simple_animal/hostile/abnormality/ardor_moth/proc/SpitFire()
	for(var/i = 1 to 3)
		var/turf/T = get_ranged_target_turf_direct(src, target, 6)
		var/list/burn_turfs = getline(src, T) - get_turf(src)
		dragon_fire_line(src, burn_turfs)
		SLEEP_CHECK_DEATH(5)

	prepping_fire = FALSE

/mob/living/simple_animal/hostile/abnormality/ardor_moth/proc/BurnAll()
	for(var/i = 1 to 4)
		for(var/turf/T in range(i, src))
			if(T in range(i - 1, src))
				continue // skip tiles already hit
			// hit only the new outer ring
			new /obj/effect/turf_fire/ardor(T)
		SLEEP_CHECK_DEATH(2)
	prepping_fire = FALSE

/mob/living/simple_animal/hostile/abnormality/ardor_moth/proc/Explosion()
	manual_emote("glows insanely bright...")
	playsound(get_turf(src), 'sound/abnormalities/scorchedgirl/ability.ogg', 60, 0, 4)
	SLEEP_CHECK_DEATH(3 SECONDS)
	// Ka-boom
	playsound(get_turf(src), 'sound/abnormalities/scorchedgirl/explosion.ogg', 125, 0, 8)
	for(var/i = 1 to 9)
		for(var/turf/T in range(i, src))
			if(T in range(i - 1, src))
				continue // skip tiles already hit
			// hit only the new outer ring
			new /obj/effect/turf_fire/ardor(T)
		SLEEP_CHECK_DEATH(2)
	qdel(src)


//The special fire type
/obj/effect/turf_fire/ardor
	burn_time = 30 SECONDS

/obj/effect/turf_fire/ardor/DoDamage(mob/living/fuel)
	if(ishuman(fuel))
		fuel.deal_damage(4, FIRE, attack_type = (ATTACK_TYPE_ENVIRONMENT))
		fuel.apply_lc_burn(2)
		return TRUE
