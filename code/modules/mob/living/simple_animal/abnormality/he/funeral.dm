#define CASKET_TIMER 20 SECONDS
#define FUNERAL_IDLE 1
#define FUNERAL_CASKET 2
#define FUNERAL_CASKET_A 3
#define FUNERAL_GUN 4

/mob/living/simple_animal/hostile/abnormality/funeral
	name = "Funeral of the Dead Butterflies"
	desc = "An towering abnormality possessing a white butterfly for a head and a coffin on its back."
	icon = 'ModularLobotomy/_Lobotomyicons/64x96.dmi' //HOW DO I TURN A PNG INTO THE DMI SPRITES AAAAAAAAAAAAAAA
	icon_state = "funeral"
	icon_living = "funeral"
	icon_dead = "funeral_dead"
	portrait = "funeral"
	del_on_death = FALSE
	maxHealth = 1350 //I am a menace to society.
	health = 1350
	gender = MALE
	blood_volume = 0

	ranged = TRUE
	minimum_distance = 2
	retreat_distance = 1

	move_to_delay = 4
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.5, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 1.0, PALE_DAMAGE = 2)
	stat_attack = HARD_CRIT
	can_breach = TRUE
	can_buckle = FALSE
	vision_range = 14
	aggro_vision_range = 20
	threat_level = HE_LEVEL
	start_qliphoth = 2
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(50, 45, 40, 0, 0),
		ABNORMALITY_WORK_INSIGHT = 50,
		ABNORMALITY_WORK_ATTACHMENT = 0,
		ABNORMALITY_WORK_REPRESSION = list(0, 0, 60, 60, 60),
	)
	work_damage_amount = 12
	work_damage_type = WHITE_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/gloom
	max_boxes = 16
	death_message = "gently descends into its own coffin."
	base_pixel_x = -16
	pixel_x = -16

	ego_list = list(
		/datum/ego_datum/weapon/solemnvow,
		/datum/ego_datum/weapon/solemnlament,
		/datum/ego_datum/armor/solemnlament,
	)
	gift_type =  /datum/ego_gifts/solemnlament
	gift_message = "The butterflies are waiting for the end of the world."
	abnormality_origin = ABNORMALITY_ORIGIN_LOBOTOMY

	observation_prompt = "A tall butterfly-faced man stands before, clad in an undertakers's garment. <br>\
		Between the two of you is a coffin and he gestures you towards it with all 3 of his hands."
	observation_choices = list(
		"Enter the coffin" = list(TRUE, "You lie down in the coffin as the butterfly-faced man stands by, his head angled and all 3 hands crossed together over his waist in a solemn gesture. <br>\
			It's a perfect fit for you. <br>\
			You feel the weight of innumerable lifetimes and the weariness that came with them. <br>\
			The butterflies lift you and the coffin as pallbearers, they lament for you in place of the people who cannot."),
		"Don't enter the coffin" = list(TRUE, "You don't enter because it's not your coffin. <br>\
			The undertaker reaches out his middle hand to his waiting, insectile audience and one of the butterflies lands upon his fingers. <br>\
			He offers you the butterfly and you place it into the coffin, gently. <br>\
			The butterflies are the souls of the dead, waiting to be put to rest, but are still mourning for the living. <br>\
			You and the butterfly-faced man stand in silent vigil. You both now share a vow; to grieve for the living and dead. <br>\
			A kaledioscope of butterflies follows you as you leave the containment unit."),
	)

	var/behavior_mode = FUNERAL_IDLE

	var/gun_cooldown
	var/gun_cooldown_time = 4 SECONDS
	var/gun_damage = 60
	var/swarm_cooldown
	var/swarm_cooldown_time = CASKET_TIMER
	var/gives_achievement = FALSE

	var/obj/effect/proc_holder/ability/aimed/casket_swarm/casket

	//PLAYABLES ATTACKS
	attack_action_types = list(/datum/action/innate/abnormality_attack/toggle/funeral_butterfly_toggle)

/datum/action/innate/abnormality_attack/toggle/funeral_butterfly_toggle
	name = "Toggle Casket Swarm"
	button_icon_state = "funeral_toggle0"
	chosen_attack_num = 2
	chosen_message = span_colossus("You will now unleash a swarm of butterflies.")
	button_icon_toggle_activated = "funeral_toggle1"
	toggle_attack_num = 1
	toggle_message = span_colossus("You will now fire butterflies from your hands.")
	button_icon_toggle_deactivated = "funeral_toggle0"

/mob/living/simple_animal/hostile/abnormality/funeral/Initialize()
	.  = ..()
	casket = new()

/mob/living/simple_animal/hostile/abnormality/funeral/AttackingTarget(atom/attacked_target)
	if(!target)
		GiveTarget(attacked_target)
	return OpenFire()

/mob/living/simple_animal/hostile/abnormality/funeral/OpenFire()
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
		SpiritGun(target)
	else if(swarm_cooldown <= world.time && prob(50))
		ButterflySwarm(target)
	return

/mob/living/simple_animal/hostile/abnormality/funeral/Move()
	if(!can_act)
		return FALSE
	return ..()
//he walk

/mob/living/simple_animal/hostile/abnormality/funeral/death(gibbed)
	density = FALSE
	var/matrix/M = matrix()
	M.Turn(-90) //horizontal coffin
	src.transform = M
	pixel_y -= 32
	pixel_x -= 16
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)
	//You need to kill him in 8 seconds
	if(gives_achievement)
		for(var/mob/living/carbon/human/H in range(5, src))
			H.client?.give_award(/datum/award/achievement/abno/solemn, H)

	return ..()
//he die

/mob/living/simple_animal/hostile/abnormality/funeral/update_icon_state()
	. = ..()
	if(stat == DEAD)
		return
	switch(behavior_mode)
		if(FUNERAL_IDLE)
			icon_state = "funeral"
		if(FUNERAL_CASKET)
			icon_state = "funeral_coffin_butterfly_less"
		if(FUNERAL_CASKET_A)
			icon_state = "funeral_coffin"
		if(FUNERAL_GUN)
			icon_state = "funeral_gun"

/mob/living/simple_animal/hostile/abnormality/funeral/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(80))
		datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/funeral/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	if(get_attribute_level(user, FORTITUDE_ATTRIBUTE) >= 80)
		datum_reference.qliphoth_change(-1)
	if(get_attribute_level(user, JUSTICE_ATTRIBUTE) < 60)
		datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/funeral/proc/DensityCheck(turf/T) //TRUE if dense or airlocks closed
	if(T.density)
		return TRUE
	for(var/obj/machinery/door/D in T.contents)
		if(D.density)
			return TRUE
	return FALSE

/mob/living/simple_animal/hostile/abnormality/funeral/proc/SpiritGun(atom/target)
	if(!isliving(target)||gun_cooldown > world.time)
		return
	var/mob/living/cooler_target = target
	if(cooler_target.stat == DEAD)
		return
	can_act = FALSE
	ChangeBehavior(FUNERAL_GUN)
	visible_message(span_danger("[src] levels one of its arms at [cooler_target]!"))
	cooler_target.apply_status_effect(/datum/status_effect/spirit_gun_target) // Re-used for visual indicator
	dir = get_cardinal_dir(src, target)
	gun_cooldown = world.time + gun_cooldown_time
	SLEEP_CHECK_DEATH(1.5 SECONDS)
	playsound(get_turf(src), 'sound/abnormalities/funeral/spiritgun.ogg', 75, 1, 3)
	cooler_target.remove_status_effect(/datum/status_effect/spirit_gun_target)
	can_act = TRUE
	ChangeBehavior()

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

/mob/living/simple_animal/hostile/abnormality/funeral/proc/ButterflySwarm(target)
	if(swarm_cooldown > world.time)
		return
	if (get_dist(src, target) < 4)
		return
	var/dir_to_target = get_cardinal_dir(get_turf(src), get_turf(target))
	//This check is to ensure funeral doesn't fire casket into a wall right next to them
	var/turf/adjacent_turf = get_step(src,dir_to_target)
	if(adjacent_turf.density)
		return
	dir = dir_to_target
	visible_message(span_danger("[src] prepares to open its coffin!"))

	ChangeBehavior(FUNERAL_CASKET)
	SLEEP_CHECK_DEATH(1.75 SECONDS)
	ChangeBehavior(FUNERAL_CASKET_A)
	playsound(get_turf(src), 'sound/abnormalities/funeral/coffin.ogg', 40, extrarange = 10, ignore_walls = TRUE) // bwiiiiiiinng >flapping
	casket.Perform(target, src)

	ChangeBehavior(FUNERAL_IDLE)
	swarm_cooldown = world.time + swarm_cooldown_time

/mob/living/simple_animal/hostile/abnormality/funeral/proc/KillAnimation(mob/living/carbon/human/killed)
	killed.apply_status_effect(/datum/status_effect/butterfly_death_anim)

/mob/living/simple_animal/hostile/abnormality/funeral/proc/SpecialReset()
	ChangeBehavior(behav = FUNERAL_IDLE)

/mob/living/simple_animal/hostile/abnormality/funeral/proc/ChangeBehavior(behav = FUNERAL_IDLE)
	behavior_mode = behav
	update_icon()

/*-----------\
|Achievements|
\-----------*/
/mob/living/simple_animal/hostile/abnormality/funeral/BreachEffect()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(AchievementOff)), 8 SECONDS)
	gives_achievement = TRUE

/mob/living/simple_animal/hostile/abnormality/funeral/proc/AchievementOff()
	gives_achievement = FALSE

/*-------------\
|STATUS EFFECTS|
\-------------*/

/datum/status_effect/spirit_gun_target
	id = "butterfly_target"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null
	duration = 2 SECONDS

/datum/status_effect/spirit_gun_target/on_apply()
	. = ..()
	owner.add_overlay(mutable_appearance('ModularLobotomy/_Lobotomyicons/32x32.dmi', "funeral_swarm", -MUTATIONS_LAYER))

/datum/status_effect/spirit_gun_target/on_remove()
	. = ..()
	owner.cut_overlay(mutable_appearance('ModularLobotomy/_Lobotomyicons/32x32.dmi', "funeral_swarm", -MUTATIONS_LAYER))

//Functions as a remote way to apply a death animation
/datum/status_effect/butterfly_death_anim
	id = "butterfly_death"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null
	duration = 4.5 SECONDS

/datum/status_effect/butterfly_death_anim/on_apply()
	. = ..()
	if(!ishuman(owner))
		qdel(src)
		return
	var/mob/living/carbon/human/killed = owner
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

/obj/effect/temp_visual/funeral_swarm
	name = "funeral swarm"
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "funeral_swarm"
	layer = BELOW_MOB_LAYER
	duration = 10 SECONDS

/*--------\
|Abilities|
\--------*/

/obj/effect/proc_holder/ability/aimed/casket_swarm
	name = "Casket Swarm"
	desc = "Release a swarm of butterflies in a cardinal direction."
	action_icon_state = "helper_dash0"
	base_icon_state = "helper_dash"
	cooldown_time = CASKET_TIMER
	var/swarm_damage = 13 // 10 seconds, 13 damage 40 times = 520 total
	var/swarm_length = 24
	var/swarm_width = 7

/obj/effect/proc_holder/ability/aimed/casket_swarm/can_cast(mob/user = usr)
	if(isabnormalitymob(user))
		var/mob/living/simple_animal/hostile/abnormality/abno = usr
		if(abno.IsContained())
			return FALSE
	return ..()

/obj/effect/proc_holder/ability/aimed/casket_swarm/AbnoInteraction(mob/living/user)
	if(!istype(user, /mob/living/simple_animal/hostile/abnormality/funeral) || !istype(user, /mob/living/simple_animal/hostile/limbus_abno/funeral))
		return
	var/mob/living/simple_animal/hostile/abnormality/funeral/abno = user
	ToggleAct(abno,TRUE)
	abno.SpecialReset()

/obj/effect/proc_holder/ability/aimed/casket_swarm/Perform(target, mob/living/user, enraged = 0)
	. = ..()
	//reset the emergency stop so we are not forever stuck.
	if(!user || !target)
		AbnoInteraction(user)
		return

	ToggleAct(user,FALSE)

	var/dir_to_target = get_cardinal_dir(get_turf(user), get_turf(target))
	var/our_x = user.x
	var/our_y = user.y
	var/our_z = user.z
	var/list/total_turfs_swarmed = list()
	for(var/i = 1 to swarm_length)
		if(!do_after(user, 4, target = user) || QDELETED(user))
			break
		if(user.stat == DEAD)
			break
		var/list/step_list = SwarmStep(our_x, our_y, our_z, user, dir_to_target)
		total_turfs_swarmed += step_list
		SwarmAllTurfs(user, total_turfs_swarmed)
		if(length(step_list))
			//I used XYZ coord manipulation too much -IP
			switch(dir_to_target)
				if(EAST)
					our_x++
				if(WEST)
					our_x--
				if(SOUTH)
					our_y--
				if(NORTH)
					our_y++

	AbnoInteraction(user)
	ToggleAct(user,TRUE)

/obj/effect/proc_holder/ability/aimed/casket_swarm/proc/SwarmStep(x_offset = 0, y_offset = 0, z_offset = 0, mob/living/user, enemy_cardinal_dir)
	var/angle_movement = "1x[swarm_width]"
	if(enemy_cardinal_dir == NORTH || enemy_cardinal_dir == SOUTH)
		angle_movement = "[swarm_width]x1"
	var/turf/step_area = locate(x_offset,y_offset,z_offset)
	if(step_area.density)
		return list()
	return range(angle_movement, step_area)

/obj/effect/proc_holder/ability/aimed/casket_swarm/proc/SwarmAllTurfs(mob/living/user, trg_list = list())
	if(!user || !trg_list)
		return
	for(var/turf/T in trg_list)
		if(T.density)
			continue
		EffectTiles(T, user)

/obj/effect/proc_holder/ability/aimed/casket_swarm/proc/EffectTiles(turf/tile, mob/living/user)
	var/default_function = TRUE
	if(istype(user, /mob/living/simple_animal/hostile/limbus_abno/funeral))
		default_function = FALSE

	new /obj/effect/temp_visual/funeral_swarm(tile)

	//Deoptimizing this code in order to fit it into LCL -IP
	for(var/mob/living/L in tile)
		if(L == user)
			continue
		if(L.status_flags & GODMODE)
			continue
		if(L.stat == DEAD)
			continue
		var/do_hit = default_function ? IsSameFaction(user, L) : IsLimbusFriend(user, L)
		if(do_hit)
			continue

		DamageThing(L, swarm_damage, WHITE_DAMAGE, user, thing_flags = (DAMAGE_FORCED), thing_attack_type = (ATTACK_TYPE_SPECIAL))
		if(istype(L, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = L
			if(H.sanity_lost)
				H.death()
				KillAnimation(H)

	if(default_function)
		return

	for(var/obj/O in tile)
		if(O.resistance_flags & INDESTRUCTIBLE)
			continue
		DamageThing(O, swarm_damage, WHITE_DAMAGE, user)

/obj/effect/proc_holder/ability/aimed/casket_swarm/proc/KillAnimation(mob/living/carbon/human/killed)
	if(!killed)
		return
	killed.apply_status_effect(/datum/status_effect/butterfly_death_anim)

#undef CASKET_TIMER
#undef FUNERAL_IDLE
#undef FUNERAL_CASKET
#undef FUNERAL_CASKET_A
#undef FUNERAL_GUN
