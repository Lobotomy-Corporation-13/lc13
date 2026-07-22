/*

Difficulty: Hard

*/

/mob/living/simple_animal/hostile/abnormality/mining/wendigo
	name = "wendigo"
	desc = "A mythological man-eating legendary creature, you probably aren't going to survive this."
	icon_state = "wendigo"
	icon_living = "wendigo"
	icon_dead = "wendigo_dead"
	icon = 'icons/mob/icemoon/64x64megafauna.dmi'
	attack_verb_continuous = "claws"
	attack_verb_simple = "claw"
	attack_sound = 'sound/magic/demon_attack1.ogg'
	weather_immunities = list("snow")
	speak_emote = list("roars")
	vision_range = 9
	aggro_vision_range = 18 // man-eating for a reason
	speed = 8
	move_to_delay = 8
	rapid_melee = 16 // every 1/8 second
	melee_queue_distance = 20 // as far as possible really, need this because of charging and teleports
	ranged = TRUE
	pixel_x = -16
	base_pixel_x = -16
	blood_volume = BLOOD_VOLUME_NORMAL
	death_message = "falls, shaking the ground around it"
	death_sound = 'sound/effects/gravhit.ogg'
	footstep_type = FOOTSTEP_MOB_HEAVY
	attack_action_types = list(/datum/action/innate/megafauna_attack/heavy_stomp,
							   /datum/action/innate/megafauna_attack/teleport,
							   /datum/action/innate/megafauna_attack/disorienting_scream)

	/// Saves the turf the megafauna was created at (spawns exit portal here)
	var/turf/starting
	/// Range for wendigo stomping when it moves
	var/stomp_range = 1
	/// Stores directions the mob is moving, then calls that a move has fully ended when these directions are removed in moved
	var/stored_move_dirs = 0
	/// If the wendigo is allowed to move
	var/can_move = TRUE
	/// Stores the last scream time so it doesn't spam it
	var/last_scream = 0

	maxHealth = 4000
	health = 4000
	rapid_melee = 2
	melee_damage_type = RED_DAMAGE
	move_to_delay = 6
	damage_coeff = list(RED_DAMAGE = 1.4, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 0.4, PALE_DAMAGE = 1)
	patrol_cooldown_time = 5 SECONDS // Zooming around the place
	melee_damage_lower = 50
	melee_damage_upper = 60
	melee_damage_type = RED_DAMAGE
	can_breach = TRUE
	threat_level = TETH_LEVEL
	start_qliphoth = 1
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 40,
		ABNORMALITY_WORK_INSIGHT = 20,
		ABNORMALITY_WORK_ATTACHMENT = 0,
		ABNORMALITY_WORK_REPRESSION = 30,
	)
	bad_droprate = 100
	work_damage_amount = 16
	work_damage_type = BLACK_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/wrath

	ego_list = list(
		/datum/ego_datum/weapon/space,
		/datum/ego_datum/armor/space
	)
//	gift_type =  /datum/ego_gifts/dream
	abnormality_origin = ABNORMALITY_ORIGIN_SS13MINING


/datum/action/innate/megafauna_attack/heavy_stomp
	name = "Heavy Stomp"
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "sniper_zoom"
	chosen_message = span_colossus("You are now stomping the ground around you.")
	chosen_attack_num = 1

/datum/action/innate/megafauna_attack/teleport
	name = "Teleport"
	icon_icon = 'icons/effects/bubblegum.dmi'
	button_icon_state = "smack ya one"
	chosen_message = span_colossus("You are now teleporting at the target you click on.")
	chosen_attack_num = 2

/datum/action/innate/megafauna_attack/disorienting_scream
	name = "Disorienting Scream"
	icon_icon = 'icons/turf/walls/wall.dmi'
	button_icon_state = "wall-0"
	chosen_message = span_colossus("You are now screeching, disorienting targets around you.")
	chosen_attack_num = 3

/mob/living/simple_animal/hostile/abnormality/mining/wendigo/Initialize()
	. = ..()
	starting = get_turf(src)

/mob/living/simple_animal/hostile/abnormality/mining/wendigo/Destroy()
	starting = null
	return ..()

/mob/living/simple_animal/hostile/abnormality/mining/wendigo/OpenFire()
	SetRecoveryTime(0, 100)
	if(health <= maxHealth*0.5)
		stomp_range = 2
		speed = 6
		move_to_delay = 6
	else
		stomp_range = initial(stomp_range)
		speed = initial(speed)
		move_to_delay = initial(move_to_delay)

	if(client)
		switch(chosen_attack)
			if(1)
				heavy_stomp()
			if(2)
				teleport()
			if(3)
				disorienting_scream()
		return

	if(world.time > last_scream + 60)
		chosen_attack = rand(1, 3)
	else
		chosen_attack = rand(1, 2)
	switch(chosen_attack)
		if(1)
			heavy_stomp()
		if(2)
			teleport()
		if(3)
			disorienting_scream()

/mob/living/simple_animal/hostile/abnormality/mining/wendigo/Life()
	. = ..()
	if(!.)
		return
	if(target || get_dist(src, starting) < 12)
		return
	do_teleport(src, starting, 0,  channel=TELEPORT_CHANNEL_BLUESPACE, forced = TRUE)

/mob/living/simple_animal/hostile/abnormality/mining/wendigo/Move(atom/newloc, direct)
	if(!can_move)
		return
	stored_move_dirs |= direct
	return ..()

/mob/living/simple_animal/hostile/abnormality/mining/wendigo/Moved(atom/oldloc, direct)
	. = ..()
	stored_move_dirs &= ~direct
	if(!stored_move_dirs)
		INVOKE_ASYNC(src, PROC_REF(ground_slam), stomp_range, 1)

/// Slams the ground around the wendigo throwing back enemies caught nearby
/mob/living/simple_animal/hostile/abnormality/mining/wendigo/proc/ground_slam(range, delay)
	var/turf/orgin = get_turf(src)
	var/list/all_turfs = RANGE_TURFS(range, orgin)
	for(var/i = 0 to range)
		for(var/turf/T in all_turfs)
			if(get_dist(orgin, T) > i)
				continue
			playsound(T,'sound/effects/bamf.ogg', 600, TRUE, 10)
			new /obj/effect/temp_visual/small_smoke/halfsecond(T)
			for(var/mob/living/L in T)
				if(L == src || L.throwing)
					continue
				to_chat(L, span_userdanger("[src]'s ground slam shockwave sends you flying!"))
				var/turf/thrownat = get_ranged_target_turf_direct(src, L, 8, rand(-10, 10))
				L.throw_at(thrownat, 8, 2, src, TRUE, force = MOVE_FORCE_OVERPOWERING, gentle = TRUE)
				L.deal_damage(50, RED_DAMAGE, src, wound_bonus = CANT_WOUND)
				shake_camera(L, 2, 1)
			all_turfs -= T
		SLEEP_CHECK_DEATH(delay)

/// Larger but slower ground stomp
/mob/living/simple_animal/hostile/abnormality/mining/wendigo/proc/heavy_stomp()
	can_move = FALSE
	ground_slam(5, 2)
	SetRecoveryTime(0, 0)
	can_move = TRUE

/// Teleports to a location 4 turfs away from the enemy in view
/mob/living/simple_animal/hostile/abnormality/mining/wendigo/proc/teleport()
	var/list/possible_ends = list()
	for(var/turf/T in view(4, target.loc) - view(3, target.loc))
		if(isclosedturf(T))
			continue
		possible_ends |= T
	if (LAZYLEN(possible_ends))
		var/turf/end = pick(possible_ends)
		do_teleport(src, end, 0,  channel=TELEPORT_CHANNEL_BLUESPACE, forced = TRUE)
		SetRecoveryTime(20, 0)

/// Applies dizziness to all nearby enemies that can hear the scream and animates the wendigo shaking up and down
/mob/living/simple_animal/hostile/abnormality/mining/wendigo/proc/disorienting_scream()
	can_move = FALSE
	last_scream = world.time
	playsound(src, 'sound/magic/demon_dies.ogg', 600, FALSE, 10)
	animate(src, pixel_z = rand(5, 15), time = 1, loop = 6)
	animate(pixel_z = 0, time = 1)
	for(var/mob/living/L in get_hearers_in_view(7, src) - src)
		L.Dizzy(6)
		to_chat(L, span_danger("[src] screams loudly!"))
		L.deal_damage(20, WHITE_DAMAGE, src, wound_bonus = CANT_WOUND)
	SetRecoveryTime(30, 0)
	SLEEP_CHECK_DEATH(12)
	can_move = TRUE
	teleport()

/mob/living/simple_animal/hostile/abnormality/mining/wendigo/death(gibbed, list/force_grant)
	if(health > 0)
		return
	var/obj/effect/portal/permanent/one_way/exit = new /obj/effect/portal/permanent/one_way(starting)
	exit.id = "wendigo arena exit"
	exit.add_atom_colour(COLOR_RED_LIGHT, ADMIN_COLOUR_PRIORITY)
	exit.set_light(20, 1, COLOR_SOFT_RED)
	return ..()
