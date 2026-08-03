//Support due to large AOEs and unavoidable ranged attacks but incredibly weak in direct combat
/mob/living/simple_animal/hostile/rcorp_abno/easy/funeral
	name = "Funeral of the Dead Butterflies"
	desc = "An towering abnormality possessing a white butterfly for a head and a coffin on its back. That coffin is likely to be hiding something dangerous."
	del_on_death = FALSE
	maxHealth = 1350 //I am a menace to society.
	health = 1350
	ranged = TRUE
	minimum_distance = 2
	retreat_distance = 1
	move_to_delay = 4
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.5, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 1.0, PALE_DAMAGE = 2)
	vision_range = 14
	original_abno = /mob/living/simple_animal/hostile/abnormality/funeral

	var/gun_cooldown
	var/gun_cooldown_time = 4 SECONDS
	var/gun_damage = 60
	var/swarm_cooldown
	var/swarm_cooldown_time = 20 SECONDS
	var/swarm_damage = 13 // 10 seconds, 13 damage 40 times = 520 total
	var/swarm_length = 24
	var/swarm_width = 3

	//PLAYABLES ATTACKS
	attack_action_types = list(/datum/action/innate/abnormality_attack/toggle/funeral_butterfly_toggle)

	abno_additional_instructions = "<h1>You are Funeral of the Dead Butterflies, A Support Role Abnormality.</h1><br>\
		<b>|Guiding Hand|: When clicking on a living being you will begin aiming with your finger. \
		While aiming butterflies form around your target you are immobile for 1.5 seconds until you fire your finger. \
		When firing deal 60 WHITE damage to your target, then this move goes on cooldown for 4 seconds. \
		This attack cannot be dodged but it cannot target Rhino pilots. <br>\
		<br>\
		|Coffin|: When used immobilize yourself and place the coffin on the ground in the direction you are facing. \
		Upon doing so you will then send out butterflies in a 7 tile wide attack infront of you that lasts for 10 seconds. \
		Any within these butterflies will take 13 WHITE damage every 0.25 seconds. \
		The entire duration of the coffin is equivalent to 520 WHITE damage. \
		This attack will not go through walls. <br>\
		<br>\
		|Eternal Rest|: When attacking a insane person with 'Guiding Hand' or 'Coffin' they will be surrounded by butterflies then die peacefully. </b>"

/datum/action/innate/rca_abnormality_attack/toggle/funeral_butterfly_toggle
	name = "Toggle Casket Swarm"
	button_icon_state = "funeral_toggle0"
	chosen_attack_num = 2
	chosen_message = span_colossus("You will now unleash a swarm of butterflies.")
	button_icon_toggle_activated = "funeral_toggle1"
	toggle_attack_num = 1
	toggle_message = span_colossus("You will now fire butterflies from your hands.")
	button_icon_toggle_deactivated = "funeral_toggle0"

/mob/living/simple_animal/hostile/rcorp_abno/easy/funeral/AttackingTarget(atom/attacked_target)
	if(!target)
		GiveTarget(attacked_target)
	return OpenFire()

/mob/living/simple_animal/hostile/rcorp_abno/easy/funeral/OpenFire()
	if(!can_act)
		return
	if(client)
		switch(chosen_attack)
			if(1)
				SpiritGun(target)
			if(2)
				ButterflySwarm(target)
		return
	if(gun_cooldown <= world.time && prob(85))
		if(faction_check_mob(target))
			SpiritGun(target)
	else if(swarm_cooldown <= world.time && prob(50))
		ButterflySwarm(target)
	return

/mob/living/simple_animal/hostile/rcorp_abno/easy/funeral/proc/DensityCheck(turf/T) //TRUE if dense or airlocks closed
	if(T.density)
		return TRUE
	for(var/obj/machinery/door/D in T.contents)
		if(D.density)
			return TRUE
	return FALSE

/mob/living/simple_animal/hostile/rcorp_abno/easy/funeral/proc/SpiritGun(atom/target)
	if(!isliving(target)||gun_cooldown > world.time)
		return
	var/mob/living/cooler_target = target
	if(cooler_target.stat == DEAD)
		return
	can_act = FALSE
	icon_state = "funeral_gun"
	visible_message(span_danger("[src] levels one of its arms at [cooler_target]!"))
	cooler_target.apply_status_effect(/datum/status_effect/rca_spirit_gun_target) // Re-used for visual indicator
	dir = get_cardinal_dir(src, target)
	SLEEP_CHECK_DEATH(1.5 SECONDS)
	playsound(get_turf(src), 'sound/abnormalities/funeral/spiritgun.ogg', 75, 1, 3)
	cooler_target.remove_status_effect(/datum/status_effect/rca_spirit_gun_target)
	can_act = TRUE
	gun_cooldown = world.time + gun_cooldown_time
	icon_state = icon_living
	var/line_of_sight = getline(get_turf(src), get_turf(target)) //better simulates a projectile attack
	for(var/turf/T in line_of_sight)
		if(DensityCheck(T))
			return
	cooler_target.deal_damage(gun_damage, WHITE_DAMAGE, src, attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
	visible_message(span_danger("[cooler_target] is hit by butterflies!"))
	//No longer because fuck you.
	if(ishuman(target))
		var/mob/living/carbon/human/kickass_grade1_target = target
		if(kickass_grade1_target.sanity_lost)
			kickass_grade1_target.death()
			KillAnimation(kickass_grade1_target)

/mob/living/simple_animal/hostile/rcorp_abno/easy/funeral/proc/ButterflySwarm(target)
	if(swarm_cooldown > world.time)
		return
	if (get_dist(src, target) < 4)
		return
	var/dir_to_target = get_cardinal_dir(get_turf(src), get_turf(target))
	//This check is to ensure funeral doesn't fire casket into a wall right next to them
	var/turf/adjacent_turf = get_step(src,dir_to_target)
	if(adjacent_turf.density)
		return
	var/list/middle_line = list()
	var/turf/source_turf = get_turf(src)
	middle_line = getline(source_turf, get_ranged_target_turf(source_turf, dir_to_target, swarm_length))
	for(var/i = 1, i<=middle_line.len, i++) //middle turf must be clear for swarm to "flow"
		if(isturf(middle_line[i]))
			var/turf/T = middle_line[i]
			if(T.density)
				middle_line.Cut(i)
				break
	if(!LAZYLEN(middle_line))
		return
	can_act = FALSE
	dir = dir_to_target
	visible_message(span_danger("[src] prepares to open its coffin!"))
	icon_state = "funeral_coffin_butterfly_less"
	SLEEP_CHECK_DEATH(1.75 SECONDS)
	icon_state = "funeral_coffin"
	playsound(get_turf(src), 'sound/abnormalities/funeral/coffin.ogg', 40, extrarange = 10, ignore_walls = TRUE) // bwiiiiiiinng >flapping
	var/i = 0
	for(var/turf/T in middle_line)
		addtimer(CALLBACK(src, PROC_REF(SwarmTurf), T, dir_to_target), i*1.4) //swarm travel speed
		i++
	SLEEP_CHECK_DEATH(10 SECONDS)
	icon_state = icon_living
	can_act = TRUE
	swarm_cooldown = world.time + swarm_cooldown_time

/mob/living/simple_animal/hostile/rcorp_abno/easy/funeral/proc/SwarmTurf(turf/T, direction)
	var/turf/hit_turfs = list()
	switch(direction)
		if(EAST)
			if(!T.density) //lets middle line to go through airlocks
				hit_turfs |= T
			for(var/turf/Y in getline(T, get_ranged_target_turf(T, NORTH, swarm_width)))
				if(DensityCheck(Y)) //prevents swarm width from going through airlocks
					break
				hit_turfs |= Y
			for(var/turf/U in getline(T, get_ranged_target_turf(T, SOUTH, swarm_width)))
				if(DensityCheck(U))
					break
				hit_turfs |= U
		if(WEST)
			if(!T.density)
				hit_turfs |= T
			for(var/turf/Y in getline(T, get_ranged_target_turf(T, NORTH, swarm_width)))
				if(DensityCheck(Y))
					break
				hit_turfs |= Y
			for(var/turf/U in getline(T, get_ranged_target_turf(T, SOUTH, swarm_width)))
				if(DensityCheck(U))
					break
				hit_turfs |= U
		if(SOUTH)
			if(!T.density)
				hit_turfs |= T
			for(var/turf/Y in getline(T, get_ranged_target_turf(T, EAST, swarm_width)))
				if(DensityCheck(Y))
					break
				hit_turfs |= Y
			for(var/turf/U in getline(T, get_ranged_target_turf(T, WEST, swarm_width)))
				if(DensityCheck(U))
					break
				hit_turfs |= U
		if(NORTH)
			if(!T.density)
				hit_turfs |= T
			for(var/turf/Y in getline(T, get_ranged_target_turf(T, EAST, swarm_width)))
				if(DensityCheck(Y))
					break
				hit_turfs |= Y
			for(var/turf/U in getline(T, get_ranged_target_turf(T, WEST, swarm_width)))
				if(DensityCheck(U))
					break
				hit_turfs |= U
		else
			return
	for(var/turf/TT in hit_turfs)
		if(locate(/obj/effect/temp_visual/rca_funeral_swarm) in TT)
			continue
		new /obj/effect/temp_visual/rca_funeral_swarm(TT)
		addtimer(CALLBACK(src, PROC_REF(SwarmTurfLinger), TT))

/mob/living/simple_animal/hostile/rcorp_abno/easy/funeral/proc/SwarmTurfLinger(turf/T)
	for(var/i = 1 to 40) //40 times
		for(var/mob/living/carbon/human/H in HurtInTurf(T, list(), swarm_damage, WHITE_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL)))
			if(H.stat == DEAD)
				continue
			if(H.sanity_lost)
				H.death()
				KillAnimation(H)
		SLEEP_CHECK_DEATH(0.25 SECONDS) //10 seconds

/mob/living/simple_animal/hostile/rcorp_abno/easy/funeral/proc/KillAnimation(mob/living/carbon/human/killed)
	var/pixel_y_before = killed.pixel_y
	animate(killed, pixel_y = 10, time = 10, easing = BACK_EASING | EASE_OUT)
	sleep(10)
	animate(killed, pixel_y = pixel_y_before, time = 10, , easing = CUBIC_EASING | EASE_OUT, flags = ANIMATION_END_NOW)
	var/obj/funeral_overlay = new
	funeral_overlay.icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	funeral_overlay.icon_state = "funeral_kill"
	funeral_overlay.layer = -BODY_FRONT_LAYER
	funeral_overlay.plane = FLOAT_PLANE
	funeral_overlay.mouse_opacity = 0
	funeral_overlay.vis_flags = VIS_INHERIT_ID
	var/matrix/M = matrix()
	M.Turn(90)
	funeral_overlay.transform = M
	funeral_overlay.alpha = 0
	animate(funeral_overlay, alpha = 255, time = 3 SECONDS)
	killed.vis_contents += funeral_overlay

/mob/living/simple_animal/hostile/rcorp_abno/easy/funeral/Move()
	if(!can_act)
		return FALSE
	return ..()
//he walk

/mob/living/simple_animal/hostile/rcorp_abno/easy/funeral/death(gibbed)
	density = FALSE
	var/matrix/M = matrix()
	M.Turn(-90) //horizontal coffin
	src.transform = M
	pixel_y -= 32
	pixel_x -= 16
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)

	..()
//he die

/datum/status_effect/rca_spirit_gun_target
	id = "butterfly_target"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null
	duration = 2 SECONDS

/datum/status_effect/rca_spirit_gun_target/on_apply()
	. = ..()
	owner.add_overlay(mutable_appearance('ModularLobotomy/_Lobotomyicons/32x32.dmi', "funeral_swarm", -MUTATIONS_LAYER))

/datum/status_effect/rca_spirit_gun_target/on_remove()
	. = ..()
	owner.cut_overlay(mutable_appearance('ModularLobotomy/_Lobotomyicons/32x32.dmi', "funeral_swarm", -MUTATIONS_LAYER))

/obj/effect/temp_visual/rca_funeral_swarm
	name = "funeral swarm"
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "funeral_swarm"
	layer = BELOW_MOB_LAYER
	duration = 10 SECONDS
