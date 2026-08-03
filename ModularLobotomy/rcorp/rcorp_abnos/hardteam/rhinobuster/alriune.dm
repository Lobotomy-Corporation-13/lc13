//Placed here because the damage pierces rhinos, aside that its pretty weak
/mob/living/simple_animal/hostile/rcorp_abno/hard/alriune
	name = "Alriune"
	desc = "A tall, pink abnormality that looks similar to a horse. It has 6 pointed legs, an armless human-like upper \
	body covered in bright teal leaves, and a head with empty, flower-filled eye sockets and pink flowers coming out of her mouth."
	maxHealth = 2000
	health = 2000
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1.2, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 1.5)
	light_color = COLOR_PINK
	light_range = 9
	light_power = 1
	original_abno = /mob/living/simple_animal/hostile/abnormality/alriune

	/// Currently displayed petals. When value is at 3 - reset to 0 and perform attack
	var/petals_current = 0
	/// World time when petals_current will increase by 1
	var/petals_next = 0
	/// Delay used for petals_next
	var/petals_next_time = 7 SECONDS
	/// Amount of white damage done to everyone in view by the attack
	var/pulse_damage = 100 //Lowered because rabbits thought they could facetank 180 WHITE
	/// Attack_type
	var/pulsing = FALSE
	var/attacking = FALSE

	abno_additional_instructions = "<h1>You are Alriune, A Rhino Piercer Role Abnormality.</h1><br>\
		<b>|Unwithering Flower|: You may not perform any melee attacks and instead rely on projectiles and AoE. \
		You will automatically and randomly perform 3 separate attack variants.\
		These attacks do not overlap and may only be performed one at a time. <br>\
		<br>\
		|Autumns Passing|: For every human within a 9 tile sightline you will create a petal and fire it at them. \
		There is no limit to the amount of petals created to match the amount of hostiles. \
		This will be repeated 3 times before you cycle to another attack. \
		Each petal will deal 20 WHITE damage to those they hit. <br>\
		<br>\
		|Springs Genesis|: Create 10 petals in the tiles around you then fire them around. \<br>\
		These petals have a 70% chance to bounce back if they impact a solid surface, this does not work if hitting structures. \
		When bouncing petals will slightly align their angles to attempt to hit the closest target, petals may only bounce up to 3 times. \
		Upon impact the petals will deal 20 WHITE damage to those they hit. <br>\
		<br>\
		|Full Bloom|: When used you will start to gain petals and will release a screen wide burst of pink light. \
		While building up petals you will not perform any other attacks and prioritise completing the Full Bloom. \
		At the third petal you will do 100 WHITE to all hostiles in a 7 tile sightline of yourself. \
		This attack will pierce rhino suits and directly attack their pilots instead. \
		If this hits or drives a human insane they will be enveloped in flowers then die. </b>"

/mob/living/simple_animal/hostile/rcorp_abno/hard/alriune/Initialize()
	. = ..()
	icon_state = "alriune_active"

/* Combat */
/mob/living/simple_animal/hostile/rcorp_abno/hard/alriune/Life()
	. = ..()
	if(!.) // Dead
		return FALSE

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

/mob/living/simple_animal/hostile/rcorp_abno/hard/alriune/CanAttack(atom/the_target)
	return FALSE

/// Check for petals_next and then perform actions
/mob/living/simple_animal/hostile/rcorp_abno/hard/alriune/proc/CheckAndPulse()
	if(world.time >= petals_next)
		petals_next = world.time + petals_next_time
		petals_current += 1
		if(petals_current >= 3) // Attack
			pulsing = FALSE
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
		else
			playsound(src, 'sound/abnormalities/alriune/timer.ogg', 50, FALSE, 12)
		update_icon()

//Other Attacks
/mob/living/simple_animal/hostile/rcorp_abno/hard/alriune/proc/ConstantAttack()
	for(var/i in 1 to 3)
		for(var/mob/living/carbon/human/L in view(9, src))
			if(L.stat == DEAD)
				continue
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


/mob/living/simple_animal/hostile/rcorp_abno/hard/alriune/proc/AlriuneAOE()
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
/mob/living/simple_animal/hostile/rcorp_abno/hard/alriune/update_overlays()
	. = ..()
	if(petals_current <= 0 || stat == DEAD || status_flags & GODMODE)
		cut_overlays()
		return

	var/mutable_appearance/petal_overlay = mutable_appearance(icon, "alriune_petal[petals_current]")
	. += petal_overlay

//Bullets
/obj/projectile/rca_alriune
	name = "petals"
	icon_state = "alriune"
	icon = 'ModularLobotomy/_Lobotomyicons/abno_projectiles.dmi'
	desc = "a sharpened petal"
	hitsound = "sound/weapons/throwtap.ogg"
	speed = 4		//very slow bullets
	damage = 20		//She fires a lot of them
	damage_type = WHITE_DAMAGE
	white_healing = FALSE

/obj/projectile/rca_alriune/on_hit(atom/target, blocked = FALSE)
	if(isrcabnormalitymob(target))
		to_chat(target, "The [src] flies right past you!")
		return
	..()


/obj/projectile/rca_alriune/aoe
	icon_state = "alriune_AOE"
	desc = "a sharpened leaf"
	spread = 360	//Fires in a 360 Degree radius

	ricochets_max = 3
	ricochet_chance = 70
	ricochet_decay_chance = 1
	ricochet_decay_damage = 0.7	//Decays a bit
	ricochet_auto_aim_range = 10
	ricochet_incidence_leeway = 0

/obj/projectile/rca_alriune/aoe/on_hit(atom/target, blocked = FALSE)
	if(isrcabnormalitymob(target))
		to_chat(target, "The [src] flies right past you!")
		return
	..()

/obj/projectile/alriune/aoe/check_ricochet_flag(atom/A)
	if(istype(A, /turf/closed))
		return TRUE
	if(istype(A, /obj/structure/window))
		return TRUE
	if(istype(A, /obj/machinery/door))
		return TRUE

	return FALSE
