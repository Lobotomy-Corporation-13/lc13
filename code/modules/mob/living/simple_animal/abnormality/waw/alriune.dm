/mob/living/simple_animal/hostile/abnormality/alriune
	name = "Alriune"
	desc = "A tall, pink abnormality that looks similar to a horse. It has 6 pointed legs, an armless human-like upper \
	body covered in bright teal leaves, and a head with empty, flower-filled eye sockets and pink flowers coming out of her mouth."
	icon = 'ModularLobotomy/_Lobotomyicons/48x64.dmi'
	icon_state = "alriune"
	icon_living = "alriune"
	portrait = "alriune"

	pixel_x = -8
	base_pixel_x = -8

	maxHealth = 2000
	health = 2000
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1.2, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 1.5)

	threat_level = WAW_LEVEL
	can_breach = TRUE
	start_qliphoth = 2
	// Work chances were slightly changed for it to be possible to get neutral result
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(0, 0, 45, 40, 35),
		ABNORMALITY_WORK_INSIGHT = list(0, 0, 50, 45, 40),
		ABNORMALITY_WORK_ATTACHMENT = list(0, 0, 40, 35, 30),
		ABNORMALITY_WORK_REPRESSION = list(0, 0, 35, 30, 25),
	)
	work_damage_amount = 10
	work_damage_type = WHITE_DAMAGE
	good_droprate = 60
	bad_droprate = 100
	chem_type = /datum/reagent/abnormality/sin/pride
	good_hater = TRUE

	light_color = COLOR_PINK
	light_range = 9
	light_power = 1

	observation_prompt = "You told me, shedding petals instead of tears. <br>\
		\"We were all nothing but soil once, so do not speak of an end here.\" <br>\
		You told me, blossoming flowers from body as if they are your last words. <br>\"Soon...\""
	observation_choices = list(
		"Spring will come" = list(TRUE, "Spring is coming. <br>Slowly, rapturously, my end began."),
		"Winter will come" = list(TRUE, "Winter is coming. <br>\
			Gradually, my exipation was drawing to an end hectically."),
	)

	/// Currently displayed petals. When value is at 3 - reset to 0 and perform attack
	var/petals_current = 0
	/// World time when petals_current will increase by 1
	var/petals_next = 0
	/// Delay used for petals_next
	var/petals_next_time = 7 SECONDS
	/// Amount of white damage done to everyone in view by the attack
	var/pulse_damage = 180

	/// Attack_type
	var/pulsing = FALSE
	var/attacking = FALSE

	ego_list = list(
		/datum/ego_datum/weapon/aroma,
		/datum/ego_datum/armor/aroma,
	)
	gift_type =  /datum/ego_gifts/aroma
	abnormality_origin = ABNORMALITY_ORIGIN_LOBOTOMY

/* Combat */

/mob/living/simple_animal/hostile/abnormality/alriune/Move()
	if(IsCombatMap())
		return ..()
	return FALSE

/mob/living/simple_animal/hostile/abnormality/alriune/Life()
	. = ..()
	if(!.) // Dead
		return FALSE
	if(status_flags & GODMODE)
		return

	//If you're working on a pulse, do it
	if(pulsing)

		CheckAndPulse()
		return

	if(attacking)
		return

	switch(rand(1,5))
		if(1 to 2)
			attacking = TRUE
			ConstantAttack()

		if(3 to 4)
			attacking = TRUE
			AlriuneAOE()

		if(5)
			pulsing = TRUE
			CheckAndPulse()

/mob/living/simple_animal/hostile/abnormality/alriune/CanAttack(atom/the_target)
	return FALSE

/// Check for petals_next and then perform actions
/mob/living/simple_animal/hostile/abnormality/alriune/proc/CheckAndPulse()
	if(world.time >= petals_next)
		petals_next = world.time + petals_next_time
		petals_current += 1
		if(petals_current >= 3) // Attack
			petals_current = 0
			playsound(src, 'sound/abnormalities/alriune/damage.ogg', 75, TRUE, 12)

			// Attack visual effect, so to speak
			for(var/turf/T in view(7, get_turf(src)))
				animate(T, color = COLOR_PINK, time = 2)
				addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(SetColorOverTime), T, initial(T.color), (2 SECONDS)), 4)

			for(var/mob/living/L in livinginview(7, get_turf(src)))
				if(faction_check_mob(L))
					continue
				if(L.stat == DEAD)
					continue
				L.deal_damage(pulse_damage, WHITE_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))
				new /obj/effect/temp_visual/alriune_attack(get_turf(L))
				if(ishuman(L))
					var/mob/living/carbon/human/H = L
					if(H.sanity_lost)
						new /obj/effect/temp_visual/alriune_curtain(get_turf(H))
						addtimer(CALLBACK(H, TYPE_PROC_REF(/atom, add_overlay), \
							icon('ModularLobotomy/_Lobotomyicons/tegu_effects.dmi', "alriune_kill")), 5)
						playsound(H, 'sound/abnormalities/alriune/kill.ogg', 75, TRUE)
						H.death()

			petals_next = world.time + (petals_next_time * 2)
			addtimer(CALLBACK(src, PROC_REF(TeleportAway)), 3 SECONDS)
		else
			playsound(src, 'sound/abnormalities/alriune/timer.ogg', 50, FALSE, 12)
		update_icon()


/mob/living/simple_animal/hostile/abnormality/alriune/proc/TeleportAway()
	if(IsCombatMap())
		return
	var/list/potential_turfs = list()
	for(var/turf/T in GLOB.xeno_spawn)
		if(get_dist(src, T) < 7)
			continue
		potential_turfs += T
	var/turf/T = pick(potential_turfs)
	if(!istype(T))
		return FALSE
	playsound(src, 'sound/abnormalities/alriune/curtain_out.ogg', 50, TRUE, 12)
	animate(src, alpha = 0, time = 15)
	SLEEP_CHECK_DEATH(15)
	forceMove(T)
	animate(src, alpha = 255, time = 15)
	playsound(src, 'sound/abnormalities/alriune/curtain_in.ogg', 50, TRUE, 12)
	pulsing = FALSE


//Other Attacks
/mob/living/simple_animal/hostile/abnormality/alriune/proc/ConstantAttack()
	for(var/i in 1 to 3)
		for(var/mob/living/carbon/human/L in view(9, src))
			var/turf/shoot_from = pick(range(1, src))
			var/obj/projectile/alriune/P = new(shoot_from)
			P.starting = shoot_from
			P.firer = src
			P.fired_from = src
			P.yo = L.y - shoot_from.y
			P.xo = L.x - shoot_from.x
			P.original = target
			P.preparePixelProjectile(L, shoot_from)
			SLEEP_CHECK_DEATH(2)
			P.fire()

		SLEEP_CHECK_DEATH(10)
	attacking = FALSE


/mob/living/simple_animal/hostile/abnormality/alriune/proc/AlriuneAOE()
	var/turf/startloc = get_turf(targets_from)

	var/turf/target_turf = locate(x, y+1, z)
	for(var/i in 1 to 10)
		var/obj/projectile/alriune/aoe/P = new(get_turf(src))
		P.starting = startloc
		P.firer = src
		P.fired_from = src
		P.yo = target_turf.y - startloc.y
		P.xo = target_turf.x - startloc.x
		P.original = target_turf
		P.preparePixelProjectile(target_turf, src)
		P.fire()

		SLEEP_CHECK_DEATH(5)

	attacking = FALSE



/* Overlays */
/mob/living/simple_animal/hostile/abnormality/alriune/update_overlays()
	. = ..()
	if(petals_current <= 0 || stat == DEAD || status_flags & GODMODE)
		cut_overlays()
		return

	var/mutable_appearance/petal_overlay = mutable_appearance(icon, "alriune_petal[petals_current]")
	. += petal_overlay

/* Work stuff */
//It's droprate on good goes down on a normal work.
/mob/living/simple_animal/hostile/abnormality/alriune/NeutralEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	good_droprate -= pe
	good_droprate = max(0, good_droprate)
	return

/* Qliphoth/Breach effects */
/mob/living/simple_animal/hostile/abnormality/alriune/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	petals_next = world.time + petals_next_time + 30
	if(breach_type != BREACH_MINING)//in ER you get a few seconds to smack it down
		TeleportAway()
	icon_state = "alriune_active"
	return



//Bullets
/obj/projectile/alriune
	name = "petals"
	icon_state = "alriune"
	icon = 'ModularLobotomy/_Lobotomyicons/abno_projectiles.dmi'
	desc = "a sharpened petal"
	hitsound = "sound/weapons/throwtap.ogg"
	speed = 4		//very slow bullets
	damage = 20		//She fires a lot of them
	damage_type = WHITE_DAMAGE
	white_healing = FALSE


/obj/projectile/alriune/aoe
	name = "petals"
	icon_state = "alriune_AOE"
	desc = "a sharpened leaf"
	spread = 360	//Fires in a 360 Degree radius

	ricochets_max = 3
	ricochet_chance = 70
	ricochet_decay_chance = 1
	ricochet_decay_damage = 0.7	//Decays a bit
	ricochet_auto_aim_range = 10
	ricochet_incidence_leeway = 0

/obj/projectile/alriune/aoe/check_ricochet_flag(atom/A)
	if(istype(A, /turf/closed))
		return TRUE
	if(istype(A, /obj/structure/window))
		return TRUE
	if(istype(A, /obj/machinery/door))
		return TRUE

	return FALSE
