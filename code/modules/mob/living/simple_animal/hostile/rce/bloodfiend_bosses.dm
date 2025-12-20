// ============================================
// BLOODFIEND BOSSES - Area guardians that unlock progression when killed
// ============================================

/// Base boss bloodfiend type - high health, blood draining tank
/mob/living/simple_animal/hostile/bloodfiend_boss
	name = "Bloodfiend Boss"
	desc = "A massive greed-touched bloodfiend radiating an aura of crimson avarice. They hoard blood obsessively, never consuming it, only growing their collection."
	icon = 'ModularLobotomy/_Lobotomyicons/blood_fiends_32x32.dmi'
	icon_state = "test_meifiend"
	icon_living = "test_meifiend"
	faction = list("hostile")
	gender = NEUTER
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	robust_searching = TRUE
	see_in_dark = 7
	vision_range = 12
	aggro_vision_range = 20
	move_to_delay = 5
	stat_attack = HARD_CRIT
	del_on_death = FALSE
	maxHealth = 5000
	health = 5000
	melee_damage_lower = 15
	melee_damage_upper = 20
	melee_damage_type = RED_DAMAGE
	attack_sound = 'sound/abnormalities/nosferatu/attack.ogg'
	attack_verb_continuous = "rends"
	attack_verb_simple = "rend"
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.2)
	butcher_results = list(/obj/item/food/meat/slab/crimson = 3)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/crimson = 5)
	/// Maximum blood for buff calculations
	var/max_blood = 3000
	/// Bleed stacks applied on hit
	var/bleed_stacks = 5
	/// Base melee damage lower, used for buff calculations
	var/base_damage_lower = 15
	/// Base melee damage upper, used for buff calculations
	var/base_damage_upper = 20
	/// Last recorded blood amount for buff updates
	var/last_blood_check = 0
	/// Whether currently in enraged state (50%+ blood)
	var/enraged = FALSE
	/// Signal sent on death to destroy area blockers
	var/boss_death_signal
	/// Reference to the landmark that spawned this boss (for weakened variants)
	var/obj/effect/landmark/bloodfiend_boss/home_landmark

/mob/living/simple_animal/hostile/bloodfiend_boss/Initialize()
	. = ..()
	base_damage_lower = melee_damage_lower
	base_damage_upper = melee_damage_upper
	AddComponent(/datum/component/bloodfeast, siphon = TRUE, range = 3, starting = 0, max_amount = max_blood)
	AddElement(/datum/element/point_of_interest)

/mob/living/simple_animal/hostile/bloodfiend_boss/Life()
	. = ..()
	if(stat == DEAD)
		return FALSE
	UpdateBloodBuff()

/mob/living/simple_animal/hostile/bloodfiend_boss/proc/UpdateBloodBuff()
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	if(!bloodfeast)
		return
	if(bloodfeast.blood_amount == last_blood_check)
		return
	last_blood_check = bloodfeast.blood_amount

	var/buff_percent = bloodfeast.blood_amount / max_blood
	var/damage_mult = 1 + (buff_percent * 0.5)
	melee_damage_lower = round(base_damage_lower * damage_mult)
	melee_damage_upper = round(base_damage_upper * damage_mult)

	var/should_enrage = buff_percent >= 0.5
	if(should_enrage != enraged)
		enraged = should_enrage
		UpdateEnragedVisual()

/mob/living/simple_animal/hostile/bloodfiend_boss/proc/UpdateEnragedVisual()
	if(enraged)
		color = "#FF6666"
	else
		color = initial(color)

/// Applies Blood Thorns status effect to self and nearby faction allies
/mob/living/simple_animal/hostile/bloodfiend_boss/proc/ApplyBloodThorns(stacks = 5, range = 5)
	// Apply to self first
	src.apply_blood_thorns(stacks)
	// Apply to allies in range
	for(var/mob/living/simple_animal/M in view(range, src))
		if(!faction_check_mob(M))
			continue
		if(M == src)
			continue
		M.apply_blood_thorns(stacks)

/mob/living/simple_animal/hostile/bloodfiend_boss/AttackingTarget()
	. = ..()
	if(istype(target, /mob/living))
		var/mob/living/L = target
		L.apply_lc_bleed(bleed_stacks)

/mob/living/simple_animal/hostile/bloodfiend_boss/death(gibbed)
	. = ..()
	if(boss_death_signal)
		SEND_SIGNAL(SSdcs, boss_death_signal, src)

/mob/living/simple_animal/hostile/bloodfiend_boss/bullet_act(obj/projectile/P)
	// 50% damage reduction at 15+ blood thorns stacks
	var/datum/status_effect/stacking/blood_thorns/BT = has_status_effect(/datum/status_effect/stacking/blood_thorns)
	if(BT && BT.stacks >= 15)
		P.damage *= 0.5
	return ..()

// ============================================
// BOSS VARIANTS
// ============================================

/// The Barber - Area 1 Boss
/mob/living/simple_animal/hostile/bloodfiend_boss/barber
	name = "The Barber"
	desc = "A greed-touched bloodfiend of elegant cruelty. The Heart of Greed transformed her hunger into avarice - she harvests blood not to drink, but to hoard. Each precise cut adds to her ever-growing collection."
	icon = 'ModularLobotomy/_Lobotomyicons/rce_bloodfiend_64x64.dmi'
	icon_state = "nicolina_base"
	icon_living = "nicolina_base"
	maxHealth = 4500
	health = 4500
	pixel_x = -16
	base_pixel_x = -16
	pixel_y = -16
	base_pixel_y = -16
	melee_damage_lower = 12
	melee_damage_upper = 18
	base_damage_lower = 12
	base_damage_upper = 18
	bleed_stacks = 4
	boss_death_signal = COMSIG_GLOB_BLOODFIEND_BARBER_DIED
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1.2, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.9, PALE_DAMAGE = 1.1)
	ranged = TRUE
	/// Whether the barber can currently act
	var/can_act = TRUE
	/// Base icon state (normal)
	var/icon_base = "nicolina_base"
	/// Buffed icon state (50%+ bloodfeast)
	var/icon_buffed = "nicolina_base_buffed"
	/// Dash icon state (normal)
	var/icon_dash = "nicolina_dash"
	/// Dash icon state (buffed)
	var/icon_dash_buffed = "nicolina_dashing_buffed"
	/// Whether currently in dash attack (reduces bullet damage)
	var/dashing = FALSE
	/// Width of the slash attack
	var/slash_width = 2
	/// Length of the slash attack
	var/slash_length = 4
	/// Damage dealt by the slash attack
	var/slash_damage = 30
	/// Cooldown tracker for dash attack
	var/dash_cooldown = 0
	/// Time between dash attacks
	var/dash_cooldown_time = 15 SECONDS
	/// Damage dealt by the dash attack
	var/dash_damage = 50
	/// Bleed stacks applied by dash
	var/dash_bleed = 8

/mob/living/simple_animal/hostile/bloodfiend_boss/barber/face_atom()
	if(!can_act)
		return
	. = ..()

/mob/living/simple_animal/hostile/bloodfiend_boss/barber/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/bloodfiend_boss/barber/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return FALSE
	return Slash(attacked_target)

/mob/living/simple_animal/hostile/bloodfiend_boss/barber/OpenFire()
	if(!can_act)
		return
	if(dash_cooldown > world.time)
		return
	if(get_dist(src, target) > 2)
		BloodTrailDash(target)

/mob/living/simple_animal/hostile/bloodfiend_boss/barber/UpdateEnragedVisual()
	if(enraged)
		icon_state = icon_buffed
		icon_living = icon_buffed
	else
		icon_state = icon_base
		icon_living = icon_base

/mob/living/simple_animal/hostile/bloodfiend_boss/barber/bullet_act(obj/projectile/P)
	if(dashing)
		P.damage *= 0.25 // 75% damage reduction while dashing
	return ..()

/mob/living/simple_animal/hostile/bloodfiend_boss/barber/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	// Melee attacks drain bloodfeast
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	if(!bloodfeast)
		return
	var/drain_amount = 25
	// Much more effective at 45% or more bloodfeast
	var/blood_percent = bloodfeast.blood_amount / max_blood
	if(blood_percent >= 0.45)
		drain_amount = 100
	bloodfeast.blood_amount = max(0, bloodfeast.blood_amount - drain_amount)
	// Force buff update
	last_blood_check = -1

/// Wide slash attack similar to white_lake_corrosion
/mob/living/simple_animal/hostile/bloodfiend_boss/barber/proc/Slash(atom/slash_target)
	if(get_dist(src, slash_target) > slash_length)
		return
	var/dir_to_target = get_cardinal_dir(get_turf(src), get_turf(slash_target))
	var/turf/source_turf = get_turf(src)
	var/list/area_of_effect = list()
	var/list/middle_line = list()

	switch(dir_to_target)
		if(EAST)
			middle_line = getline(get_step_towards(source_turf, slash_target), get_ranged_target_turf(source_turf, EAST, slash_length))
			for(var/turf/T in middle_line)
				if(T.density)
					break
				for(var/turf/Y in getline(T, get_ranged_target_turf(T, NORTH, slash_width)))
					if(Y.density)
						break
					if(Y in area_of_effect)
						continue
					area_of_effect += Y
				for(var/turf/U in getline(T, get_ranged_target_turf(T, SOUTH, slash_width)))
					if(U.density)
						break
					if(U in area_of_effect)
						continue
					area_of_effect += U
		if(WEST)
			middle_line = getline(get_step_towards(source_turf, slash_target), get_ranged_target_turf(source_turf, WEST, slash_length))
			for(var/turf/T in middle_line)
				if(T.density)
					break
				for(var/turf/Y in getline(T, get_ranged_target_turf(T, NORTH, slash_width)))
					if(Y.density)
						break
					if(Y in area_of_effect)
						continue
					area_of_effect += Y
				for(var/turf/U in getline(T, get_ranged_target_turf(T, SOUTH, slash_width)))
					if(U.density)
						break
					if(U in area_of_effect)
						continue
					area_of_effect += U
		if(SOUTH)
			middle_line = getline(get_step_towards(source_turf, slash_target), get_ranged_target_turf(source_turf, SOUTH, slash_length))
			for(var/turf/T in middle_line)
				if(T.density)
					break
				for(var/turf/Y in getline(T, get_ranged_target_turf(T, EAST, slash_width)))
					if(Y.density)
						break
					if(Y in area_of_effect)
						continue
					area_of_effect += Y
				for(var/turf/U in getline(T, get_ranged_target_turf(T, WEST, slash_width)))
					if(U.density)
						break
					if(U in area_of_effect)
						continue
					area_of_effect += U
		if(NORTH)
			middle_line = getline(get_step_towards(source_turf, slash_target), get_ranged_target_turf(source_turf, NORTH, slash_length))
			for(var/turf/T in middle_line)
				if(T.density)
					break
				for(var/turf/Y in getline(T, get_ranged_target_turf(T, EAST, slash_width)))
					if(Y.density)
						break
					if(Y in area_of_effect)
						continue
					area_of_effect += Y
				for(var/turf/U in getline(T, get_ranged_target_turf(T, WEST, slash_width)))
					if(U.density)
						break
					if(U in area_of_effect)
						continue
					area_of_effect += U
		else
			for(var/turf/T in view(1, src))
				if(T.density)
					continue
				if(T in area_of_effect)
					continue
				area_of_effect |= T

	if(!LAZYLEN(area_of_effect))
		return

	can_act = FALSE
	dir = dir_to_target
	playsound(get_turf(src), 'sound/weapons/fixer/generic/sheath2.ogg', 75, 0, 5)
	for(var/turf/T in area_of_effect)
		new /obj/effect/temp_visual/cult/sparks(T)
	SLEEP_CHECK_DEATH(0.8 SECONDS)

	playsound(get_turf(src), 'sound/weapons/fixer/generic/blade3.ogg', 100, 0, 5)

	// Calculate damage multiplier based on bloodfeast (up to 100% more at 100% bloodfeast)
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	var/damage_mult = 1
	if(bloodfeast)
		var/blood_percent = bloodfeast.blood_amount / max_blood
		damage_mult = 1 + blood_percent // 100% to 200% damage

	var/actual_damage = round(slash_damage * damage_mult)
	var/targets_hit = 0

	for(var/turf/T in area_of_effect)
		var/obj/effect/temp_visual/slice/slash_effect = new(T)
		slash_effect.color = "#b52e19"
		// Damage mobs
		for(var/mob/living/L in HurtInTurf(T, list(), actual_damage, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_MELEE)))
			L.apply_lc_bleed(bleed_stacks)
			targets_hit++
		// Damage barricades (double damage)
		for(var/obj/structure/barricade/B in T)
			B.take_damage(actual_damage * 2, RED_DAMAGE)

	// Generate 100 bloodfeast per target hit
	if(bloodfeast && targets_hit > 0)
		bloodfeast.blood_amount = min(bloodfeast.blood_amount + (targets_hit * 100), max_blood)
		last_blood_check = -1 // Force buff update

	SLEEP_CHECK_DEATH(0.5 SECONDS)
	can_act = TRUE

/// Blood trail dash attack - places marks behind target based on bloodfeast, then dashes to each
/mob/living/simple_animal/hostile/bloodfiend_boss/barber/proc/BloodTrailDash(atom/dash_target)
	dash_cooldown = world.time + dash_cooldown_time
	can_act = FALSE
	dashing = TRUE

	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	var/num_marks = 1
	if(bloodfeast)
		num_marks = 1 + FLOOR(bloodfeast.blood_amount / (max_blood * 0.25), 1)
		num_marks = clamp(num_marks, 1, 5)

	var/list/blood_marks = list()
	var/list/blood_beams = list()
	var/atom/original_target = dash_target
	var/turf/mark_turf

	playsound(get_turf(src), 'sound/abnormalities/nosferatu/special_start.ogg', 50, 0, 5)
	manual_emote("readies their blades...")

	// Place marks with 1 second delay between each
	for(var/i in 1 to num_marks)
		if(stat == DEAD)
			can_act = TRUE
			dashing = FALSE
			QDEL_LIST(blood_beams)
			QDEL_LIST(blood_marks)
			return

		// Get current target position (updates as target moves)
		var/turf/target_turf = get_turf(original_target)
		if(!target_turf)
			target_turf = get_turf(src)

		// Calculate mark position
		if(i == 1)
			// First mark: overshoot behind target from barber's perspective
			var/direction = get_dir(src, target_turf)
			mark_turf = get_ranged_target_turf(target_turf, direction, rand(1, 2))
		else
			// Subsequent marks: from last mark, through target, overshoot on other side
			var/turf/last_mark_turf = get_turf(blood_marks[i - 1])
			var/direction = get_dir(last_mark_turf, target_turf)
			mark_turf = get_ranged_target_turf(target_turf, direction, rand(1, 2))

		if(!mark_turf)
			mark_turf = target_turf

		var/obj/effect/barber_blood_mark/mark = new(mark_turf)
		blood_marks += mark

		// Create beam showing the path - from barber to first mark, then between consecutive marks
		var/atom/beam_origin
		if(i == 1)
			beam_origin = src
		else
			beam_origin = blood_marks[i - 1]
		var/datum/beam/mark_beam = beam_origin.Beam(mark, icon_state = "blood", time = INFINITY, maxdistance = 50)
		blood_beams += mark_beam

		SLEEP_CHECK_DEATH(1 SECONDS)

	// Wait 2 seconds before dashing
	SLEEP_CHECK_DEATH(2 SECONDS)

	// Remove all beams before dashing
	QDEL_LIST(blood_beams)

	// Dash to each mark in order
	for(var/obj/effect/barber_blood_mark/mark in blood_marks)
		if(stat == DEAD)
			can_act = TRUE
			dashing = FALSE
			QDEL_LIST(blood_marks)
			return
		DashToMark(mark)
		SLEEP_CHECK_DEATH(0.3 SECONDS)

	can_act = TRUE
	dashing = FALSE

/// Performs a single dash to a mark location, dealing damage along the path
/mob/living/simple_animal/hostile/bloodfiend_boss/barber/proc/DashToMark(obj/effect/barber_blood_mark/mark)
	var/turf/mark_turf = get_turf(mark)
	var/turf/start_turf = get_turf(src)
	var/list/dash_path = getline(start_turf, mark_turf)
	var/list/hit_mobs = list()

	// Switch to dash sprite
	var/previous_icon = icon_state
	icon_state = enraged ? icon_dash_buffed : icon_dash
	icon_living = icon_state

	playsound(get_turf(src), 'sound/abnormalities/nosferatu/attack_special.ogg', 50, FALSE, 4)

	for(var/turf/T in dash_path)
		if(stat == DEAD)
			break
		// Animate movement - sleep before moving to make it visible
		sleep(1)
		forceMove(T)
		playsound(T, 'sound/abnormalities/doomsdaycalendar/Lor_Slash_Generic.ogg', 20, 0, 4)
		// Leave blood trail on open turfs (lasts as long as dash cooldown)
		if(!isclosedturf(T))
			new /obj/effect/barber_blood_trail(T, dash_cooldown_time)
		// Deal damage and effects in area around barber (only on open turfs)
		for(var/turf/hit_turf in orange(1, T))
			if(isclosedturf(hit_turf))
				continue
			var/obj/effect/temp_visual/slice/slice_effect = new(hit_turf)
			slice_effect.color = "#b52e19"
			for(var/mob/living/L in hit_turf)
				if(faction_check_mob(L))
					continue
				if(L in hit_mobs)
					continue
				hit_mobs += L
				L.deal_damage(dash_damage, RED_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
				L.apply_lc_bleed(dash_bleed)
			// Damage barricades (double damage)
			for(var/obj/structure/barricade/B in hit_turf)
				B.take_damage(dash_damage * 2, RED_DAMAGE)

	// Extra damage at the mark location (if it's open)
	if(!isclosedturf(mark_turf))
		for(var/mob/living/L in mark_turf)
			if(faction_check_mob(L))
				continue
			if(!(L in hit_mobs))
				L.deal_damage(dash_damage, RED_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
				L.apply_lc_bleed(dash_bleed)
		// Damage barricades at mark location (double damage)
		for(var/obj/structure/barricade/B in mark_turf)
			B.take_damage(dash_damage * 2, RED_DAMAGE)

	// If we ended up inside a wall, teleport back to start
	var/turf/current_turf = get_turf(src)
	if(current_turf.density || isclosedturf(current_turf))
		forceMove(start_turf)

	// Restore previous sprite
	icon_state = previous_icon
	icon_living = previous_icon

	// Delete the mark when we reach it
	qdel(mark)

/// Blood mark for the barber's dash attack - deleted when dashed to
/obj/effect/barber_blood_mark
	name = "blood mark"
	desc = "A swirling mark of blood energy."
	icon = 'icons/effects/eldritch.dmi'
	icon_state = "blood_cloud_swirl"
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/// Blood trail left behind by the barber's dash - applies bleed when crossed
/obj/effect/barber_blood_trail
	name = "blood trail"
	desc = "A slick trail of blood left behind by a swift blade."
	icon = 'icons/turf/floors/water.dmi'
	icon_state = "redwater1"
	anchored = TRUE
	layer = BELOW_MOB_LAYER
	/// Bleed stacks applied when crossed
	var/bleed_amount = 20

/obj/effect/barber_blood_trail/Initialize(mapload, duration = 15 SECONDS)
	. = ..()
	QDEL_IN(src, duration)

/obj/effect/barber_blood_trail/Crossed(atom/movable/AM)
	. = ..()
	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		H.apply_lc_bleed(bleed_amount)

/// The Priest - Area 2 Boss
/mob/living/simple_animal/hostile/bloodfiend_boss/priest
	name = "The Priest"
	desc = "A greed-touched bloodfiend whose devotion was corrupted by the Heart of Greed. His prayers became tallies, his rituals became audits. He catalogues every drop of hoarded blood, believing sufficient accumulation will grant transcendence."
	icon = 'ModularLobotomy/_Lobotomyicons/rce_bloodfiend_32x32.dmi'
	icon_state = "curiambro"
	icon_living = "curiambro"
	maxHealth = 5500
	health = 5500
	melee_damage_lower = 14
	melee_damage_upper = 20
	base_damage_lower = 14
	base_damage_upper = 20
	bleed_stacks = 5
	boss_death_signal = COMSIG_GLOB_BLOODFIEND_PRIEST_DIED
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.7, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 1.3, PALE_DAMAGE = 1.1)
	ranged = TRUE
	retreat_distance = 0
	minimum_distance = 0
	/// Whether the priest can currently act
	var/can_act = TRUE
	/// Self-harm damage before each attack
	var/self_harm_damage = 35
	/// Whip attack range
	var/whip_range = 6
	/// Whip attack damage
	var/whip_damage = 18
	/// Whip attack windup time in deciseconds
	var/whip_windup = 8
	/// Bleed stacks applied by whip
	var/whip_bleed = 4
	/// Angle variance for whip attack
	var/whip_angle_variance = 5
	/// Tendril burst cooldown tracker
	var/tendril_cooldown = 0
	/// Time between tendril bursts
	var/tendril_cooldown_time = 12 SECONDS
	/// Minimum tendrils fired
	var/tendril_count_min = 6
	/// Maximum tendrils fired
	var/tendril_count_max = 10
	/// Tendril range
	var/tendril_range = 5
	/// Tendril damage
	var/tendril_damage = 20
	/// Bleed stacks from tendril
	var/tendril_bleed = 6
	/// Whether currently in priest buffed state (30%+ bloodfeast)
	var/priest_buffed = FALSE
	/// Buffed icon state
	var/icon_buffed = "curiambro_buffed"
	/// Bloodfeast lost when missing an attack
	var/miss_bloodfeast_loss = 100

/mob/living/simple_animal/hostile/bloodfiend_boss/priest/Life()
	. = ..()
	if(stat == DEAD)
		return FALSE
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	if(!bloodfeast)
		return
	// Only siphon blood when below 50% health
	bloodfeast.passive_siphon = (health <= maxHealth * 0.5)
	// Update buffed visual at 30% bloodfeast
	var/should_buff = bloodfeast.blood_amount >= (max_blood * 0.3)
	if(should_buff != priest_buffed)
		priest_buffed = should_buff
		UpdateBuffedVisual()

/// Updates visual appearance when entering/exiting buffed state
/mob/living/simple_animal/hostile/bloodfiend_boss/priest/proc/UpdateBuffedVisual()
	if(priest_buffed)
		icon_state = icon_buffed
		icon_living = icon_buffed
	else
		icon_state = initial(icon_state)
		icon_living = initial(icon_living)

/mob/living/simple_animal/hostile/bloodfiend_boss/priest/face_atom(atom/A)
	if(!can_act)
		return
	. = ..()

/mob/living/simple_animal/hostile/bloodfiend_boss/priest/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/bloodfiend_boss/priest/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return FALSE
	return WhipAttack(attacked_target)

/mob/living/simple_animal/hostile/bloodfiend_boss/priest/OpenFire()
	if(!can_act)
		return
	// Use whip attack if target is within whip range
	if(target && get_dist(src, target) <= whip_range)
		WhipAttack(target)
		return
	// Otherwise use tendril burst if off cooldown
	if(tendril_cooldown > world.time)
		return
	TendrilBurst()

/// The Priest harms himself before attacking, spawning gibs
/mob/living/simple_animal/hostile/bloodfiend_boss/priest/proc/SelfHarm()
	do_attack_animation(src)
	adjustBruteLoss(self_harm_damage)
	new /obj/effect/gibspawner/generic/silent(get_turf(src))
	playsound(src, 'sound/weapons/whip.ogg', 50, TRUE)

/// Whip attack - long range line attack with AoE
/mob/living/simple_animal/hostile/bloodfiend_boss/priest/proc/WhipAttack(atom/whip_target)
	if(get_dist(src, whip_target) > whip_range)
		return
	can_act = FALSE
	// Self-harm before attack
	SelfHarm()
	face_atom(whip_target)
	// Calculate damage based on bloodfeast (2% more per 1% bloodfeast)
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	var/damage_mult = 1
	var/can_knockdown = FALSE
	if(bloodfeast)
		var/blood_percent = bloodfeast.blood_amount / max_blood
		damage_mult = 1 + (blood_percent * 2) // 100% to 300% damage
		can_knockdown = blood_percent >= 0.3
	var/actual_damage = round(whip_damage * damage_mult)
	// Get target turf with slight angle variance
	var/turf/target_turf = get_ranged_target_turf_direct(src, get_turf(whip_target), whip_range, rand(-whip_angle_variance, whip_angle_variance))
	// Warning phase - show sparks along the line
	var/broken = FALSE
	var/distance = whip_range
	for(var/turf/T in getline(get_turf(src), target_turf))
		if(distance < 0)
			break
		distance--
		if(T.density)
			if(broken)
				break
			broken = TRUE
		for(var/turf/TF in range(1, T))
			if(TF.density)
				continue
			new /obj/effect/temp_visual/cult/sparks(TF)
	playsound(src, 'sound/creatures/lc13/lovetown/abomination_lovewhip_start.ogg', 75, TRUE)
	SLEEP_CHECK_DEATH(whip_windup)
	// Damage phase
	distance = whip_range
	broken = FALSE
	var/been_hit = list()
	for(var/turf/T in getline(get_turf(src), target_turf))
		if(distance < 0)
			break
		distance--
		if(T.density)
			if(broken)
				break
			broken = TRUE
		for(var/turf/TF in range(1, T))
			if(TF.density)
				continue
			new /obj/effect/temp_visual/smash_effect(TF)
			been_hit = HurtInTurf(TF, been_hit, actual_damage, RED_DAMAGE, null, null, TRUE, FALSE, TRUE, TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			// Damage barricades (double damage)
			for(var/obj/structure/barricade/B in TF)
				B.take_damage(actual_damage * 2, RED_DAMAGE)
	// Apply bleed and knockdown to all hit targets
	for(var/mob/living/L in been_hit)
		L.apply_lc_bleed(whip_bleed)
		if(can_knockdown)
			L.Knockdown(1 SECONDS)
	// Generate bloodfeast from hits, or lose bloodfeast if missed
	if(bloodfeast)
		if(length(been_hit))
			bloodfeast.blood_amount = min(bloodfeast.blood_amount + (length(been_hit) * 50), max_blood)
		else if(bloodfeast.blood_amount > 0)
			bloodfeast.blood_amount = max(bloodfeast.blood_amount - miss_bloodfeast_loss, 0)
	playsound(src, 'sound/creatures/lc13/lovetown/abomination_lovewhip_hit.ogg', 75, TRUE)
	can_act = TRUE

/// Tendril burst - 3 self-harms then fires tendrils in all directions
/mob/living/simple_animal/hostile/bloodfiend_boss/priest/proc/TendrilBurst()
	tendril_cooldown = world.time + tendril_cooldown_time
	can_act = FALSE
	// Calculate damage based on bloodfeast (2% more per 1% bloodfeast)
	var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
	var/damage_mult = 1
	if(bloodfeast)
		var/blood_percent = bloodfeast.blood_amount / max_blood
		damage_mult = 1 + (blood_percent * 2) // 100% to 300% damage
	var/actual_damage = round(tendril_damage * damage_mult)
	// Self-harm 3 times with delays
	for(var/i in 1 to 3)
		SelfHarm()
		SLEEP_CHECK_DEATH(0.5 SECONDS)
	// Fire random tendrils
	var/tendril_count = rand(tendril_count_min, tendril_count_max)
	var/total_hits = 0
	playsound(src, 'sound/weapons/ego/censored2.ogg', 75, FALSE, 5)
	for(var/i in 1 to tendril_count)
		var/angle = rand(0, 359)
		var/turf/T = get_ranged_target_turf_direct(src, get_turf(src), tendril_range, angle)
		var/list/turf_list = list()
		// Build turf list and show warning sparks
		for(var/turf/TT in getline(src, T))
			if(TT == get_turf(src))
				continue
			if(TT.density)
				break
			new /obj/effect/temp_visual/cult/sparks(TT)
			turf_list += TT
			T = TT
		if(!LAZYLEN(turf_list))
			continue
		// Fire tendril beam
		Beam(T, "tentacle", time = 10)
		// Damage along line
		for(var/turf/TT in turf_list)
			for(var/mob/living/L in HurtInTurf(TT, list(), actual_damage, RED_DAMAGE, null, TRUE, FALSE, TRUE, hurt_structure = TRUE, attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL)))
				new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(L), pick(GLOB.alldirs))
				L.apply_lc_bleed(tendril_bleed)
				total_hits++
			// Damage barricades (double damage)
			for(var/obj/structure/barricade/B in TT)
				B.take_damage(actual_damage * 2, RED_DAMAGE)
	// Lose bloodfeast if no targets hit
	if(bloodfeast && total_hits == 0 && bloodfeast.blood_amount > 0)
		bloodfeast.blood_amount = max(bloodfeast.blood_amount - miss_bloodfeast_loss, 0)
	playsound(src, 'sound/weapons/ego/censored1.ogg', 75, FALSE, 5)
	can_act = TRUE

/// Dulcinea - Area 3 Boss
/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea
	name = "Dulcinea"
	desc = "The Princess of the Crimson Parade, corrupted by the Heart of Greed into insatiable avarice. She hoards blood like a dragon hoards gold, her parade a procession of wealth extraction. Her laughter echoes with the ecstasy of accumulation."
	icon = 'ModularLobotomy/_Lobotomyicons/rce_bloodfiend_64x64.dmi'
	icon_state = "dulcinea"
	icon_living = "dulcinea"
	pixel_x = -16
	base_pixel_x = -16
	maxHealth = 6500
	health = 6500
	melee_damage_lower = 16
	melee_damage_upper = 22
	base_damage_lower = 16
	base_damage_upper = 22
	bleed_stacks = 6
	boss_death_signal = COMSIG_GLOB_BLOODFIEND_DULCINEA_DIED
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.6, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 1.2)
	/// Whether Dulcinea can currently act
	var/can_act = TRUE
	/// List of spawned units
	var/list/spawned_units = list()
	/// List of bodyguard units
	var/list/bodyguards = list()
	/// List of beam datums for cleanup
	var/list/spawn_beams = list()
	/// Spawn cooldown tracker
	var/spawn_cooldown = 0
	/// Time between spawns
	var/spawn_cooldown_time = 8 SECONDS
	/// Maximum non-bodyguard spawns
	var/max_spawns = 8
	/// Number of bodyguards to maintain
	var/bodyguard_count = 2
	/// Grief stacks from spawned unit deaths
	var/grief_stacks = 0
	/// Last AoE threshold triggered
	var/last_aoe_threshold = 0
	/// Grief AoE range
	var/grief_aoe_range = 5
	/// Grief AoE damage
	var/grief_aoe_damage = 20
	/// Grief AoE bleed stacks
	var/grief_aoe_bleed = 12
	/// Grief AoE warning time
	var/grief_aoe_warning = 1.5 SECONDS
	/// Stagger duration
	var/stagger_duration = 10 SECONDS
	/// Whether currently staggered
	var/staggered = FALSE
	/// Rage AoE range (after stagger)
	var/rage_aoe_range = 7
	/// Blood thorns application cooldown tracker
	var/blood_thorns_cooldown = 0
	/// Time between blood thorns applications
	var/blood_thorns_cooldown_time = 8 SECONDS
	/// Rage AoE damage
	var/rage_aoe_damage = 30
	/// Rage AoE bleed stacks
	var/rage_aoe_bleed = 20
	/// Rage AoE repeat count
	var/rage_aoe_repeats = 3

/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/Initialize()
	. = ..()
	// Spawn initial bodyguards
	addtimer(CALLBACK(src, PROC_REF(SpawnInitialBodyguards)), 1 SECONDS)

/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/proc/SpawnInitialBodyguards()
	for(var/i in 1 to bodyguard_count)
		SpawnBodyguard()

/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/Life()
	. = ..()
	if(stat == DEAD)
		return FALSE
	if(staggered)
		return
	// Maintain bodyguards
	CleanupDeadUnits()
	var/current_bodyguards = length(bodyguards)
	if(current_bodyguards < bodyguard_count)
		for(var/i in 1 to (bodyguard_count - current_bodyguards))
			SpawnBodyguard()
	// Spawn regular units on cooldown
	if(world.time >= spawn_cooldown && length(spawned_units) < max_spawns)
		SpawnParadeUnit()
		spawn_cooldown = world.time + spawn_cooldown_time
	// Apply blood thorns to self and allies every 5 seconds (1 stack per 10% bloodfeast)
	if(world.time >= blood_thorns_cooldown)
		var/datum/component/bloodfeast/bf = GetComponent(/datum/component/bloodfeast)
		var/thorns_stacks = 1
		if(bf)
			thorns_stacks = max(1, FLOOR(bf.blood_amount / (max_blood * 0.1), 1))
		ApplyBloodThorns(thorns_stacks, 10)
		blood_thorns_cooldown = world.time + blood_thorns_cooldown_time

/// Cleans up dead units from tracking lists
/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/proc/CleanupDeadUnits()
	for(var/mob/living/M in spawned_units)
		if(QDELETED(M) || M.stat == DEAD)
			spawned_units -= M
	for(var/mob/living/M in bodyguards)
		if(QDELETED(M) || M.stat == DEAD)
			bodyguards -= M

/// Spawns a bodyguard unit
/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/proc/SpawnBodyguard()
	var/turf/spawn_turf = get_turf(src)
	var/list/possible_turfs = list()
	for(var/turf/T in view(3, spawn_turf))
		if(!T.density && !T.is_blocked_turf(exclude_mobs = TRUE))
			possible_turfs += T
	if(!length(possible_turfs))
		return
	var/turf/chosen = pick(possible_turfs)
	var/mob/living/simple_animal/hostile/bloodfiend_mook/parade_guard/guard = new(chosen)
	guard.faction = faction.Copy()
	bodyguards += guard
	RegisterSpawn(guard, is_bodyguard = TRUE)

/// Spawns a parade unit (bloodfiend or bloodbag)
/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/proc/SpawnParadeUnit()
	var/turf/spawn_turf = get_turf(src)
	var/list/possible_turfs = list()
	for(var/turf/T in view(3, spawn_turf))
		if(!T.density && !T.is_blocked_turf(exclude_mobs = TRUE))
			possible_turfs += T
	if(!length(possible_turfs))
		return
	var/turf/chosen = pick(possible_turfs)
	var/mob/living/spawned
	if(prob(60))
		spawned = new /mob/living/simple_animal/hostile/bloodfiend_mook/parade(chosen)
	else
		spawned = new /mob/living/simple_animal/hostile/bloodbag/parade(chosen)
	spawned.faction = faction.Copy()
	spawned_units += spawned
	RegisterSpawn(spawned, is_bodyguard = FALSE)

/// Registers a spawned unit for death tracking and creates beam
/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/proc/RegisterSpawn(mob/living/spawned, is_bodyguard = FALSE)
	RegisterSignal(spawned, COMSIG_LIVING_DEATH, PROC_REF(OnSpawnDeath))
	// Create blood beam connection
	var/datum/beam/B = Beam(spawned, "tentacle", time = INFINITY, maxdistance = 50)
	spawn_beams[spawned] = B

/// Called when a spawned unit dies
/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/proc/OnSpawnDeath(mob/living/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_LIVING_DEATH)
	// Clean up beam
	if(spawn_beams[source])
		var/datum/beam/B = spawn_beams[source]
		if(!QDELETED(B))
			qdel(B)
		spawn_beams -= source
	// Remove from lists
	spawned_units -= source
	bodyguards -= source
	// Add grief stacks based on type
	var/stacks_to_add = 0
	if(source in bodyguards || istype(source, /mob/living/simple_animal/hostile/bloodfiend_mook/parade_guard))
		stacks_to_add = 4
	else if(istype(source, /mob/living/simple_animal/hostile/bloodfiend_mook))
		stacks_to_add = 3
	else if(istype(source, /mob/living/simple_animal/hostile/bloodbag))
		stacks_to_add = 1
	grief_stacks += stacks_to_add
	// Check thresholds
	INVOKE_ASYNC(src, PROC_REF(CheckGriefThresholds))

/// Checks grief stack thresholds and triggers appropriate responses
/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/proc/CheckGriefThresholds()
	if(staggered || !can_act)
		return
	// Check for stagger at 40
	if(grief_stacks >= 40)
		TriggerStagger()
		return
	// Check for AoE at 10, 20, 30
	var/threshold = 0
	if(grief_stacks >= 30 && last_aoe_threshold < 30)
		threshold = 30
	else if(grief_stacks >= 20 && last_aoe_threshold < 20)
		threshold = 20
	else if(grief_stacks >= 10 && last_aoe_threshold < 10)
		threshold = 10
	if(threshold > 0)
		last_aoe_threshold = threshold
		GriefAoE()

/// Grief AoE attack - damages enemies and buffs allied bloodfiends
/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/proc/GriefAoE()
	if(!can_act || staggered)
		return
	can_act = FALSE
	manual_emote("raises her parasol!")
	// Warning phase - show overlays
	var/list/warning_turfs = list()
	var/list/warning_overlays = list()
	var/turf/center = get_turf(src)
	for(var/turf/T in view(grief_aoe_range, center))
		var/image/O = image(icon = 'icons/effects/eldritch.dmi', icon_state = "blood_cloud_swirl")
		T.add_overlay(O)
		warning_overlays += O
		warning_turfs += T
	playsound(src, 'sound/abnormalities/bloodbath/Bloodbath_EyeOn.ogg', 75, TRUE)
	sleep(grief_aoe_warning)
	// Clear overlays
	for(var/i in 1 to length(warning_turfs))
		var/turf/T = warning_turfs[i]
		T.cut_overlay(warning_overlays[i])
	if(stat == DEAD)
		can_act = TRUE
		return
	// Damage phase
	playsound(src, 'sound/effects/ordeals/crimson/dusk_dead.ogg', 75, TRUE)
	var/list/been_hit = list()
	for(var/turf/T in view(grief_aoe_range, center))
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(T, pick(GLOB.alldirs))
		been_hit = HurtInTurf(T, been_hit, grief_aoe_damage, RED_DAMAGE, null, null, TRUE, FALSE, TRUE, TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	// Apply bleed and buff bloodfiends
	for(var/mob/living/L in been_hit)
		L.apply_lc_bleed(grief_aoe_bleed)
		// Buff allied bloodfiends with 25% bloodfeast
		if(L.faction_check_mob(src, FALSE))
			var/datum/component/bloodfeast/bf = L.GetComponent(/datum/component/bloodfeast)
			if(bf)
				var/boost = bf.blood_cap * 0.25
				bf.blood_amount = min(bf.blood_amount + boost, bf.blood_cap)
	can_act = TRUE

/// Triggers stagger state at 40 grief stacks
/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/proc/TriggerStagger()
	if(staggered)
		return
	staggered = TRUE
	can_act = FALSE
	grief_stacks = 0
	last_aoe_threshold = 0
	// Visual effects
	var/mutable_appearance/stagger_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/blood_fiends_32x32.dmi', "small_stagger", layer + 0.1)
	add_overlay(stagger_overlay)
	manual_emote("collapses to the ground...")
	// Increase damage taken during stagger
	ChangeResistances(list(BRUTE = 2, RED_DAMAGE = 2, WHITE_DAMAGE = 2.4, BLACK_DAMAGE = 2, PALE_DAMAGE = 2.4))
	sleep(stagger_duration)
	if(stat == DEAD)
		return
	// Recovery
	cut_overlays()
	manual_emote("rises back up, preparing the finale!")
	// Restore resistances
	ChangeResistances(list(BRUTE = 1, RED_DAMAGE = 0.6, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 1.2))
	staggered = FALSE
	// Rage AoE after recovery
	RageAoE()
	can_act = TRUE

/// Powerful triple AoE after recovering from stagger
/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/proc/RageAoE()
	for(var/i in 1 to rage_aoe_repeats)
		if(stat == DEAD)
			return
		// Warning phase
		var/list/warning_turfs = list()
		var/list/warning_overlays = list()
		var/turf/center = get_turf(src)
		for(var/turf/T in view(rage_aoe_range, center))
			var/image/O = image(icon = 'icons/effects/eldritch.dmi', icon_state = "blood_cloud_swirl")
			T.add_overlay(O)
			warning_overlays += O
			warning_turfs += T
		playsound(src, 'sound/abnormalities/bloodbath/Bloodbath_EyeOn.ogg', 100, TRUE)
		sleep(0.8 SECONDS)
		// Clear overlays
		for(var/j in 1 to length(warning_turfs))
			var/turf/T = warning_turfs[j]
			T.cut_overlay(warning_overlays[j])
		if(stat == DEAD)
			return
		// Damage phase
		playsound(src, 'sound/effects/ordeals/crimson/dusk_dead.ogg', 100, TRUE)
		var/list/been_hit = list()
		for(var/turf/T in view(rage_aoe_range, center))
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(T, pick(GLOB.alldirs))
			been_hit = HurtInTurf(T, been_hit, rage_aoe_damage, RED_DAMAGE, null, null, TRUE, FALSE, TRUE, TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		// Apply 20 bleed to all hit
		for(var/mob/living/L in been_hit)
			L.apply_lc_bleed(rage_aoe_bleed)
		sleep(0.5 SECONDS)

/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/face_atom(atom/A)
	if(!can_act)
		return
	. = ..()

/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/death(gibbed)
	// Clean up all spawned units and beams
	for(var/datum/beam/B in spawn_beams)
		if(!QDELETED(B))
			qdel(B)
	spawn_beams.Cut()
	return ..()

// Blood Thorns - Stacking defensive buff that retaliates against melee attackers with bleed and blocks projectiles at high stacks
#define STATUS_EFFECT_BLOODTHORNS /datum/status_effect/stacking/blood_thorns

/datum/status_effect/stacking/blood_thorns
	id = "blood_thorns"
	alert_type = null // No HUD alert for NPCs
	max_stacks = 25
	stack_decay = 0 // No passive decay
	consumed_on_threshold = FALSE
	duration = -1 // Infinite until removed
	/// Cached overlay for cleanup
	var/mutable_appearance/thorns_overlay

/datum/status_effect/stacking/blood_thorns/on_apply()
	. = ..()
	// Register for damage signal to detect melee attacks
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMGE, PROC_REF(OnDamaged))
	// Register for bullet signal to intercept projectiles
	RegisterSignal(owner, COMSIG_LIVING_BULLET_ACT, PROC_REF(OnBulletHit))
	// Visual indicator overlay (red cult shield effect)
	thorns_overlay = mutable_appearance('icons/effects/cult_effects.dmi', "shield-cult", -MUTATIONS_LAYER)
	owner.add_overlay(thorns_overlay)

/datum/status_effect/stacking/blood_thorns/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMGE)
	UnregisterSignal(owner, COMSIG_LIVING_BULLET_ACT)
	if(thorns_overlay)
		owner.cut_overlay(thorns_overlay)
	return ..()

/// Called when the owner takes damage - retaliates against melee attackers with bleed
/datum/status_effect/stacking/blood_thorns/proc/OnDamaged(mob/us, damage_amount, damage_type, def_zone, mob/attacker, damage_flags, attack_type)
	SIGNAL_HANDLER

	// Only trigger on melee attacks from humans
	if(!(attack_type & ATTACK_TYPE_MELEE))
		return
	if(!ishuman(attacker))
		return
	if(attacker == us)
		return
	if(stacks <= 0)
		return

	// Apply bleed equal to stacks to the attacker
	var/mob/living/carbon/human/H = attacker
	H.apply_lc_bleed(stacks)

	// Visual feedback
	playsound(owner, 'sound/effects/splat.ogg', 50, TRUE)
	to_chat(attacker, span_userdanger("Blood thorns pierce your flesh!"))

	// Halve stacks (rounded down)
	stacks = round(stacks / 2)
	if(stacks <= 0)
		qdel(src)

/// Called when a projectile hits the owner - blocks projectiles at 15+ stacks
/datum/status_effect/stacking/blood_thorns/proc/OnBulletHit(mob/living/source, obj/projectile/P, def_zone, piercing_hit)
	SIGNAL_HANDLER

	// Only block at 15+ stacks
	if(stacks < 15)
		return

	// Block the projectile by setting nodamage and qdeleting
	P.nodamage = TRUE
	P.damage = 0

	// Visual feedback
	playsound(owner, 'sound/weapons/resonator_blast.ogg', 50, TRUE)
	owner.visible_message(span_danger("Blood thorns deflect [P] away from [owner]!"))

	// Red outline flash for 1 second
	owner.add_filter("blood_thorns_glow", 2, list("type" = "outline", "color" = "#ff000030", "size" = 2))
	addtimer(CALLBACK(src, PROC_REF(RemoveRedOutline)), 1 SECONDS)

	// qdel the projectile
	QDEL_IN(P, 1)

/// Removes the red outline after blocking a projectile
/datum/status_effect/stacking/blood_thorns/proc/RemoveRedOutline()
	if(owner)
		owner.remove_filter("blood_thorns_glow")

// Mob Proc - Helper to apply blood thorns stacks
/mob/living/proc/apply_blood_thorns(stacks_to_add)
	var/datum/status_effect/stacking/blood_thorns/BT = has_status_effect(/datum/status_effect/stacking/blood_thorns)
	if(!BT)
		BT = apply_status_effect(/datum/status_effect/stacking/blood_thorns, stacks_to_add)
	else
		BT.add_stacks(stacks_to_add)

// ============================================
// WEAKENED BOSS VARIANTS - Spawned by X-Corp Heart?
// ============================================

/// Weakened Barber - 25% less health
/mob/living/simple_animal/hostile/bloodfiend_boss/barber/weakened
	name = "The Barber (Weakened)"
	maxHealth = 3375 // 4500 * 0.75
	health = 3375
	/// Whether we've triggered Dulcinea's rage AoE
	var/triggered_dulcinea_rage = FALSE

/mob/living/simple_animal/hostile/bloodfiend_boss/barber/weakened/Life()
	. = ..()
	if(stat == DEAD)
		return FALSE
	// Trigger Dulcinea's RageAoE when below 25% HP
	if(!triggered_dulcinea_rage && health <= maxHealth * 0.25)
		triggered_dulcinea_rage = TRUE
		TriggerDulcineaRage()

/// Find and trigger weakened Dulcinea's RageAoE
/mob/living/simple_animal/hostile/bloodfiend_boss/barber/weakened/proc/TriggerDulcineaRage()
	if(!home_landmark || !home_landmark.parent_heart)
		return
	for(var/obj/effect/landmark/bloodfiend_boss/BL in home_landmark.parent_heart.boss_landmarks)
		if(BL.spawned_boss && istype(BL.spawned_boss, /mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/weakened))
			var/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/weakened/D = BL.spawned_boss
			INVOKE_ASYNC(D, TYPE_PROC_REF(/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/weakened, TriggeredRageAoE))
			break

/// Weakened Priest - 25% less health
/mob/living/simple_animal/hostile/bloodfiend_boss/priest/weakened
	name = "The Priest (Weakened)"
	maxHealth = 4125 // 5500 * 0.75
	health = 4125
	/// Whether we've triggered Dulcinea's rage AoE
	var/triggered_dulcinea_rage = FALSE

/mob/living/simple_animal/hostile/bloodfiend_boss/priest/weakened/Life()
	. = ..()
	if(stat == DEAD)
		return FALSE
	// Trigger Dulcinea's RageAoE when below 25% HP
	if(!triggered_dulcinea_rage && health <= maxHealth * 0.25)
		triggered_dulcinea_rage = TRUE
		TriggerDulcineaRage()

/// Find and trigger weakened Dulcinea's RageAoE
/mob/living/simple_animal/hostile/bloodfiend_boss/priest/weakened/proc/TriggerDulcineaRage()
	if(!home_landmark || !home_landmark.parent_heart)
		return
	for(var/obj/effect/landmark/bloodfiend_boss/BL in home_landmark.parent_heart.boss_landmarks)
		if(BL.spawned_boss && istype(BL.spawned_boss, /mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/weakened))
			var/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/weakened/D = BL.spawned_boss
			INVOKE_ASYNC(D, TYPE_PROC_REF(/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/weakened, TriggeredRageAoE))
			break

/// Weakened Dulcinea - 25% less health, doesn't spawn allies
/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/weakened
	name = "Dulcinea (Weakened)"
	maxHealth = 4875 // 6500 * 0.75
	health = 4875
	/// Whether the triggered RageAoE has already been used
	var/triggered_rage_used = FALSE

/// Triggered RageAoE - can only be used once
/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/weakened/proc/TriggeredRageAoE()
	if(triggered_rage_used)
		return
	if(stat == DEAD || staggered)
		return
	triggered_rage_used = TRUE
	RageAoE()

/// Override to prevent spawning bodyguards
/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/weakened/SpawnInitialBodyguards()
	return // Don't spawn bodyguards

/// Override to prevent spawning parade units
/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/weakened/SpawnParadeUnit()
	return // Don't spawn parade units

/// Override to prevent spawning bodyguards
/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/weakened/SpawnBodyguard()
	return // Don't spawn bodyguards

// ============================================
// Heart of Greed? - Spawns weakened bosses when destroyed
// ============================================

/obj/structure/xcorp_heart_research
	name = "Heart of Greed?"
	desc = "Best destroy this!"
	icon = 'icons/obj/hand_of_god_structures.dmi'
	icon_state = "nexus"
	color = "#FF0000"
	light_color = "#FF0000"
	light_range = 5
	light_power = 2
	max_integrity = 500
	anchored = TRUE
	density = TRUE
	resistance_flags = NONE
	/// List of boss landmarks to activate on destruction
	var/list/boss_landmarks = list()
	/// Whether the heart has been destroyed
	var/destroyed = FALSE

/obj/structure/xcorp_heart_research/Initialize()
	. = ..()
	AddElement(/datum/element/point_of_interest)
	// Add pulsing glow effect
	add_filter("heart_glow", 2, list("type" = "outline", "color" = "#ff000050", "size" = 3))
	addtimer(CALLBACK(src, PROC_REF(GlowLoop)), rand(1, 19))

/obj/structure/xcorp_heart_research/proc/GlowLoop()
	var/filter = get_filter("heart_glow")
	if(filter)
		animate(filter, alpha = 180, time = 20, loop = -1)
		animate(alpha = 60, time = 30)

/obj/structure/xcorp_heart_research/Destroy()
	if(!destroyed)
		destroyed = TRUE
		// Spawn all bosses from landmarks
		for(var/obj/effect/landmark/bloodfiend_boss/BL in boss_landmarks)
			BL.SpawnBoss()
		// Visual effect
		playsound(loc, 'sound/effects/ordeals/crimson/dusk_dead.ogg', 100, TRUE)
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(src), pick(GLOB.alldirs))
	return ..()

// ============================================
// BOSS LANDMARKS - Track bosses and spawn portal when all dead
// ============================================

/obj/effect/landmark/bloodfiend_boss
	name = "bloodfiend boss spawn"
	icon = 'icons/effects/eldritch.dmi'
	icon_state = "blood_cloud_swirl"
	/// Type of boss to spawn
	var/boss_type = /mob/living/simple_animal/hostile/bloodfiend_boss/barber/weakened
	/// Reference to the spawned boss
	var/mob/living/simple_animal/hostile/bloodfiend_boss/spawned_boss
	/// Reference to the heart that controls this landmark
	var/obj/structure/xcorp_heart_research/parent_heart
	/// Stored location of the heart for portal spawning (persists after heart destruction)
	var/turf/heart_location
	/// List of sibling landmarks from the same heart (persists after heart destruction)
	var/list/sibling_landmarks = list()
	/// Cooldown tracker for return check
	var/return_check_cooldown = 0
	/// Time between return checks (1 minute)
	var/return_check_time = 1 MINUTES

/obj/effect/landmark/bloodfiend_boss/Initialize()
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/effect/landmark/bloodfiend_boss/LateInitialize()
	. = ..()
	// Find parent heart and register 5 seconds after spawn
	addtimer(CALLBACK(src, PROC_REF(FindParentHeart)), 5 SECONDS)

/// Finds and registers with nearby heart
/obj/effect/landmark/bloodfiend_boss/proc/FindParentHeart()
	for(var/obj/structure/xcorp_heart_research/heart in range(50, src))
		parent_heart = heart
		heart.boss_landmarks += src
		// Store heart location for portal spawning after heart is destroyed
		heart_location = get_turf(heart)
		break
	// Build sibling landmark list (runs after all landmarks have registered)
	addtimer(CALLBACK(src, PROC_REF(BuildSiblingList)), 1)

/// Builds the sibling landmark list from the parent heart
/obj/effect/landmark/bloodfiend_boss/proc/BuildSiblingList()
	if(!parent_heart)
		return
	for(var/obj/effect/landmark/bloodfiend_boss/BL in parent_heart.boss_landmarks)
		if(BL != src)
			sibling_landmarks += BL

/obj/effect/landmark/bloodfiend_boss/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(parent_heart)
		parent_heart.boss_landmarks -= src
	// Remove self from siblings' lists
	for(var/obj/effect/landmark/bloodfiend_boss/BL in sibling_landmarks)
		BL.sibling_landmarks -= src
	return ..()

/obj/effect/landmark/bloodfiend_boss/process()
	if(!spawned_boss)
		return
	if(QDELETED(spawned_boss) || spawned_boss.stat == DEAD)
		spawned_boss = null
		CheckAllBossesDead()
		return
	// Check every minute if boss has no target
	if(world.time >= return_check_cooldown)
		return_check_cooldown = world.time + return_check_time
		if(!spawned_boss.target)
			ReturnBossToLandmark()

/// Spawns the boss at this landmark
/obj/effect/landmark/bloodfiend_boss/proc/SpawnBoss()
	if(spawned_boss && !QDELETED(spawned_boss) && spawned_boss.stat != DEAD)
		return // Already have a living boss
	spawned_boss = new boss_type(get_turf(src))
	spawned_boss.home_landmark = src
	RegisterSignal(spawned_boss, COMSIG_LIVING_DEATH, PROC_REF(OnBossDeath))
	// Visual spawn effect
	playsound(loc, 'sound/abnormalities/bloodbath/Bloodbath_EyeOn.ogg', 75, TRUE)
	new /obj/effect/temp_visual/beam_out(get_turf(src))

/// Called when the boss dies
/obj/effect/landmark/bloodfiend_boss/proc/OnBossDeath(mob/living/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_LIVING_DEATH)
	spawned_boss = null
	INVOKE_ASYNC(src, PROC_REF(CheckAllBossesDead))

/// Checks if all bosses from the parent heart are dead
/obj/effect/landmark/bloodfiend_boss/proc/CheckAllBossesDead()
	// Check our own boss first
	if(spawned_boss && !QDELETED(spawned_boss) && spawned_boss.stat != DEAD)
		return // Our boss is still alive
	// Check sibling landmarks' bosses
	for(var/obj/effect/landmark/bloodfiend_boss/BL in sibling_landmarks)
		if(BL.spawned_boss && !QDELETED(BL.spawned_boss) && BL.spawned_boss.stat != DEAD)
			return // At least one boss still alive
	// All bosses dead - spawn portal at heart location
	SpawnFinalPortal()

/// Spawns the final boss portal at the heart's location
/obj/effect/landmark/bloodfiend_boss/proc/SpawnFinalPortal()
	if(!heart_location)
		return
	var/obj/effect/portal/permanent/one_way/portal = new(heart_location)
	portal.id = "final_boss"
	portal.add_atom_colour(COLOR_RED_LIGHT, ADMIN_COLOUR_PRIORITY)
	portal.set_light(10, 2, COLOR_SOFT_RED)
	// Announcement
	playsound(heart_location, 'sound/effects/ordeals/white/pale_teleport_out.ogg', 100, TRUE)
	visible_message(span_boldwarning("A portal to the final confrontation has opened!"))

/// Makes the boss return to this landmark
/obj/effect/landmark/bloodfiend_boss/proc/ReturnBossToLandmark()
	if(!spawned_boss || QDELETED(spawned_boss) || spawned_boss.stat == DEAD)
		return
	// Walk the boss back to the landmark
	walk_to(spawned_boss, src, 0, spawned_boss.move_to_delay)

// Landmark subtypes for each boss
/obj/effect/landmark/bloodfiend_boss/barber
	name = "barber boss spawn"
	boss_type = /mob/living/simple_animal/hostile/bloodfiend_boss/barber/weakened

/obj/effect/landmark/bloodfiend_boss/priest
	name = "priest boss spawn"
	boss_type = /mob/living/simple_animal/hostile/bloodfiend_boss/priest/weakened

/obj/effect/landmark/bloodfiend_boss/dulcinea
	name = "dulcinea boss spawn"
	boss_type = /mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/weakened

// ============================================
// LA MANCHA LAND FERRIS WHEEL - Final Boss Arena
// ============================================

/obj/structure/ferris_wheel
	name = "La Mancha Land Ferris Wheel"
	desc = "A massive, corrupted ferris wheel towering over the carnival grounds. The Heart of Greed's influence pulses through its rusted frame."
	icon = 'ModularLobotomy/_Lobotomyicons/rce_bloodfiend_240x288.dmi'
	icon_state = "wheel"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE
	max_integrity = 99999
	layer = ABOVE_MOB_LAYER
	light_color = "#FF0000"
	light_range = 8
	light_power = 2
	// Large sprite offset adjustments (240x288)
	pixel_x = -104
	/// Whether the wheel has been activated
	var/activated = FALSE
	/// List of currently alive gondolas
	var/list/active_gondolas = list()
	/// Total gondolas spawned across all waves
	var/gondolas_spawned = 0
	/// Maximum total gondolas before boss spawns
	var/max_gondolas = 12
	/// Gondolas spawned per wave
	var/gondolas_per_wave = 4
	/// Total gondolas killed
	var/gondolas_killed = 0

/obj/structure/ferris_wheel/Initialize()
	. = ..()
	AddElement(/datum/element/point_of_interest)

/obj/structure/ferris_wheel/attacked_by(obj/item/I, mob/living/user)
	. = ..()
	Activate()

/obj/structure/ferris_wheel/bullet_act(obj/projectile/P)
	. = ..()
	Activate()

/// Activates the ferris wheel to start spawning gondolas
/obj/structure/ferris_wheel/proc/Activate()
	if(activated)
		return
	activated = TRUE
	visible_message(span_boldwarning("The ferris wheel groans to life, its corrupted gondolas detaching!"))
	playsound(src, 'sound/abnormalities/bloodbath/Bloodbath_EyeOn.ogg', 100, TRUE)
	SpawnGondolaWave()

/// Spawns a wave of gondolas
/obj/structure/ferris_wheel/proc/SpawnGondolaWave()
	if(gondolas_spawned >= max_gondolas)
		return
	var/list/spawn_turfs = list()
	// Find valid spawn turfs around the wheel
	for(var/turf/T in view(10, src))
		if(T.density)
			continue
		if(T.is_blocked_turf(exclude_mobs = TRUE))
			continue
		// Ensure some distance from wheel center
		if(get_dist(src, T) < 5)
			continue
		spawn_turfs += T
	if(!length(spawn_turfs))
		return
	// Shuffle and pick spawn positions
	spawn_turfs = shuffle(spawn_turfs)
	var/list/gondola_types = list(
		/mob/living/simple_animal/hostile/gondola_spawner/red,
		/mob/living/simple_animal/hostile/gondola_spawner/gray,
		/mob/living/simple_animal/hostile/gondola_spawner/purple
	)
	for(var/i in 1 to gondolas_per_wave)
		if(gondolas_spawned >= max_gondolas)
			break
		if(i > length(spawn_turfs))
			break
		var/turf/spawn_turf = spawn_turfs[i]
		var/gondola_type = pick(gondola_types)
		var/mob/living/simple_animal/hostile/gondola_spawner/G = new gondola_type(spawn_turf)
		G.parent_wheel = src
		active_gondolas += G
		gondolas_spawned++
		RegisterSignal(G, COMSIG_LIVING_DEATH, PROC_REF(OnGondolaDeath))
		// Trigger the drop attack
		INVOKE_ASYNC(G, TYPE_PROC_REF(/mob/living/simple_animal/hostile/gondola_spawner, DropFromSky))

/// Called when a gondola dies
/obj/structure/ferris_wheel/proc/OnGondolaDeath(mob/living/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_LIVING_DEATH)
	active_gondolas -= source
	gondolas_killed++
	// Check if wave is complete
	if(length(active_gondolas) <= 0)
		if(gondolas_killed >= max_gondolas)
			// All gondolas killed - spawn boss
			INVOKE_ASYNC(src, PROC_REF(SpawnDonQuixote))
		else
			// Spawn next wave after a delay
			addtimer(CALLBACK(src, PROC_REF(SpawnGondolaWave)), 3 SECONDS)

/// Spawns Don Quixote after all gondolas are defeated
/obj/structure/ferris_wheel/proc/SpawnDonQuixote()
	visible_message(span_boldwarning("The ferris wheel groans as its structure begins to collapse!"))
	playsound(src, 'sound/effects/ordeals/crimson/dusk_dead.ogg', 100, TRUE)
	// Change wheel to no_sign state
	icon_state = "no_sign"
	// Create the falling sign
	var/obj/structure/ferris_wheel_sign/sign = new(get_turf(src))
	sign.pixel_x = pixel_x
	sign.pixel_y = pixel_y
	// Flash yellow animation
	INVOKE_ASYNC(src, PROC_REF(SignFallSequence), sign)

/// Handles the sign falling sequence
/obj/structure/ferris_wheel/proc/SignFallSequence(obj/structure/ferris_wheel_sign/sign)
	if(QDELETED(sign))
		return
	// Flash yellow several times
	for(var/i in 1 to 4)
		sign.color = "#FFFF00"
		playsound(sign, 'sound/machines/warning-buzzer.ogg', 50, TRUE)
		sleep(0.3 SECONDS)
		sign.color = null
		sleep(0.3 SECONDS)
	if(QDELETED(sign))
		return
	// Final yellow flash before fall
	sign.color = "#FFFF00"
	playsound(sign, 'sound/machines/warning-buzzer.ogg', 75, TRUE)
	sleep(0.5 SECONDS)
	if(QDELETED(sign))
		return
	// Sign falls
	visible_message(span_boldwarning("The La Mancha Land sign breaks free and plummets!"))
	playsound(sign, 'sound/abnormalities/babayaga/land.ogg', 100, TRUE)
	animate(sign, pixel_y = sign.pixel_y - 132, time = 8, easing = QUAD_EASING | EASE_IN)
	sleep(0.8 SECONDS)
	if(QDELETED(sign))
		return
	// Impact effect
	playsound(sign, 'sound/effects/meteorimpact.ogg', 100, TRUE)
	for(var/turf/T in view(3, sign))
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(T, pick(GLOB.alldirs))
	sleep(2 SECONDS)
	// Spawn Don Quixote
	visible_message(span_boldwarning("A figure emerges from the wreckage!"))
	playsound(src, 'sound/abnormalities/bloodbath/Bloodbath_EyeOn.ogg', 100, TRUE)
	// TODO: Spawn Don Quixote boss here when implemented
	// var/mob/living/simple_animal/hostile/don_quixote/boss = new(get_turf(src))

/// The falling sign from the ferris wheel
/obj/structure/ferris_wheel_sign
	name = "La Mancha Land Sign"
	desc = "The iconic sign of La Mancha Land, now corrupted by greed."
	icon = 'ModularLobotomy/_Lobotomyicons/rce_bloodfiend_240x288.dmi'
	icon_state = "sign"
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

// ============================================
// FERRIS WHEEL ACTIVATION LANDMARK
// ============================================

/obj/effect/landmark/ferris_wheel_trigger
	name = "ferris wheel trigger"
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x"
	/// Linked ferris wheel
	var/obj/structure/ferris_wheel/linked_wheel

/obj/effect/landmark/ferris_wheel_trigger/LateInitialize()
	. = ..()
	// Find and link to nearby ferris wheel
	for(var/obj/structure/ferris_wheel/wheel in range(50, src))
		linked_wheel = wheel
		break

/obj/effect/landmark/ferris_wheel_trigger/Crossed(atom/movable/AM)
	. = ..()
	if(!ishuman(AM))
		return
	if(!linked_wheel)
		return
	linked_wheel.Activate()

// ============================================
// GONDOLA SPAWNER - Stationary mob that spawns bloodfiends
// ============================================

/mob/living/simple_animal/hostile/gondola_spawner
	name = "Gondola"
	desc = "A corrupted carnival gondola, now a nest for greed-touched bloodfiends."
	icon = 'ModularLobotomy/_Lobotomyicons/rce_bloodfiend_64x64.dmi'
	icon_state = "ferrispod"
	icon_living = "ferrispod"
	pixel_x = -16
	pixel_y = -16
	faction = list("hostile")
	gender = NEUTER
	mob_biotypes = MOB_ORGANIC
	move_to_delay = 0
	stat_attack = HARD_CRIT
	maxHealth = 1500
	health = 1500
	melee_damage_lower = 0
	melee_damage_upper = 0
	obj_damage = 0
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.8, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1.2)
	del_on_death = TRUE
	/// Color for the overlay
	var/overlay_color = "#FF0000"
	/// Cached overlay appearance
	var/mutable_appearance/color_overlay
	/// Weighted spawn list for mobs
	var/list/moblist = list()
	/// List of spawned mobs
	var/list/spawned_mobs = list()
	/// Spawn cooldown tracker
	var/spawn_cooldown = 0
	/// Time between spawns
	var/spawn_cooldown_time = 10 SECONDS
	/// Number of mobs to spawn each cycle
	var/spawn_count = 2
	/// Reference to parent ferris wheel
	var/obj/structure/ferris_wheel/parent_wheel
	/// Whether the gondola has landed (can spawn mobs)
	var/landed = FALSE
	/// Beam connecting to ferris wheel
	var/datum/beam/wheel_beam

/mob/living/simple_animal/hostile/gondola_spawner/Initialize()
	. = ..()
	// Add colored overlay
	color_overlay = mutable_appearance(icon, "ferrispod_overlay")
	color_overlay.color = overlay_color
	add_overlay(color_overlay)
	// Add glow filter
	add_filter("gondola_glow", 2, list("type" = "outline", "color" = overlay_color + "50", "size" = 2))

/mob/living/simple_animal/hostile/gondola_spawner/Move()
	return FALSE // Completely stationary

/mob/living/simple_animal/hostile/gondola_spawner/CanAttack()
	return FALSE // Cannot attack

/mob/living/simple_animal/hostile/gondola_spawner/Life()
	. = ..()
	if(stat == DEAD)
		return FALSE
	if(!landed)
		return
	// Spawn mobs periodically
	if(world.time >= spawn_cooldown)
		SpawnMobs()
		spawn_cooldown = world.time + spawn_cooldown_time

/// Spawns mobs from the gondola
/mob/living/simple_animal/hostile/gondola_spawner/proc/SpawnMobs()
	if(!length(moblist))
		return
	var/list/spawn_turfs = list()
	for(var/turf/T in view(2, src))
		if(!T.density && !T.is_blocked_turf(exclude_mobs = TRUE))
			spawn_turfs += T
	if(!length(spawn_turfs))
		spawn_turfs += get_turf(src)
	for(var/i in 1 to spawn_count)
		var/mob_type = pickweight(moblist)
		var/turf/spawn_turf = pick(spawn_turfs)
		var/mob/living/spawned = new mob_type(spawn_turf)
		spawned.faction = faction.Copy()
		spawned_mobs += spawned
		// Visual effect
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(spawn_turf, pick(GLOB.alldirs))
	playsound(src, 'sound/effects/splat.ogg', 50, TRUE)

/// Drop from sky attack when spawning
/mob/living/simple_animal/hostile/gondola_spawner/proc/DropFromSky()
	var/turf/target_turf = get_turf(src)
	pixel_z = 192
	alpha = 0
	// Warning indicator - custom gondola shadow
	new /obj/effect/temp_visual/gondola_warning(target_turf)
	playsound(target_turf, 'sound/abnormalities/babayaga/charge.ogg', 50, TRUE)
	sleep(1.5 SECONDS)
	if(QDELETED(src) || stat == DEAD)
		return
	// Animate falling
	animate(src, pixel_z = 0, alpha = 255, time = 10)
	sleep(1)
	if(QDELETED(src) || stat == DEAD)
		return
	// Impact
	landed = TRUE
	playsound(src, 'sound/abnormalities/babayaga/land.ogg', 75, TRUE)
	// Create beam to turf 4 tiles above ferris wheel
	if(parent_wheel && !QDELETED(parent_wheel))
		var/turf/wheel_turf = get_turf(parent_wheel)
		var/turf/beam_target = locate(wheel_turf.x, wheel_turf.y + 4, wheel_turf.z)
		if(beam_target)
			wheel_beam = Beam(beam_target, icon_state = "blood", time = INFINITY, maxdistance = 50)
	// Deal damage in range 2
	for(var/mob/living/L in view(2, src))
		if(faction_check_mob(L, TRUE))
			continue
		L.deal_damage(150, RED_DAMAGE, src, attack_type = ATTACK_TYPE_SPECIAL)
	// Visual effects
	for(var/turf/T in view(3, src))
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(T, pick(GLOB.alldirs))
	// Start spawning immediately
	spawn_cooldown = world.time + 2 SECONDS

/mob/living/simple_animal/hostile/gondola_spawner/death(gibbed)
	// Clean up beam
	if(wheel_beam && !QDELETED(wheel_beam))
		qdel(wheel_beam)
		wheel_beam = null
	// Kill all spawned mobs
	for(var/mob/living/M in spawned_mobs)
		if(!QDELETED(M) && M.stat != DEAD)
			M.death()
	spawned_mobs.Cut()
	return ..()

// ============================================
// GONDOLA COLOR VARIANTS
// ============================================

/// Red Gondola - Spawns Fashionista bloodfiends (Area 1)
/mob/living/simple_animal/hostile/gondola_spawner/red
	overlay_color = "#FF0000"
	moblist = list(
		/mob/living/simple_animal/hostile/bloodbag/fashionista = 4,
		/mob/living/simple_animal/hostile/bloodfiend_mook/fashionista = 1
	)

/// Gray Gondola - Spawns Priest bloodfiends (Area 2)
/mob/living/simple_animal/hostile/gondola_spawner/gray
	overlay_color = "#888888"
	moblist = list(
		/mob/living/simple_animal/hostile/bloodbag/priest = 3,
		/mob/living/simple_animal/hostile/bloodbag/priest_alt = 2,
		/mob/living/simple_animal/hostile/bloodfiend_mook/priest = 1
	)

/// Purple Gondola - Spawns Parade bloodfiends (Area 3)
/mob/living/simple_animal/hostile/gondola_spawner/purple
	overlay_color = "#AA00AA"
	moblist = list(
		/mob/living/simple_animal/hostile/bloodbag/parade = 3,
		/mob/living/simple_animal/hostile/bloodfiend_mook/parade = 1,
		/mob/living/simple_animal/hostile/bloodfiend_mook/parade_alt = 1
	)

// ============================================
// GONDOLA WARNING EFFECT
// ============================================

/// Warning effect showing where a gondola will land
/obj/effect/temp_visual/gondola_warning
	name = "falling shadow"
	desc = "Something is falling!"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "warning"
	pixel_x = -32
	base_pixel_x = -32
	pixel_y = -32
	base_pixel_y = -32
	color = "#FF0000"
	alpha = 150
	pixel_x = -16
	pixel_y = -16
	duration = 1.5 SECONDS
	layer = BELOW_MOB_LAYER

/obj/effect/temp_visual/gondola_warning/Initialize()
	. = ..()
	// Pulsing animation
	animate(src, alpha = 80, time = 5, loop = -1)
	animate(alpha = 150, time = 5)
