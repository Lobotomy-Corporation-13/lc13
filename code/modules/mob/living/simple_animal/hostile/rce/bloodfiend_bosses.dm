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
	del_on_death = TRUE
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
	var/max_blood = 7500
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
	/// Looping sound datum for boss theme
	var/datum/looping_sound/boss_soundloop
	/// Whether the theme has started playing
	var/theme_playing = FALSE

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

/mob/living/simple_animal/hostile/bloodfiend_boss/adjustHealth(amount, updating_health, forced)
	. = ..()
	// Start theme music on first damage
	if(!theme_playing && amount > 0 && boss_soundloop)
		theme_playing = TRUE
		boss_soundloop.start()

/mob/living/simple_animal/hostile/bloodfiend_boss/death(gibbed)
	// Stop theme music on death
	if(boss_soundloop)
		boss_soundloop.stop()
		QDEL_NULL(boss_soundloop)
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
	can_act = TRUE
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
	var/slash_damage = 75
	/// Cooldown tracker for dash attack
	var/dash_cooldown = 0
	/// Time between dash attacks
	var/dash_cooldown_time = 15 SECONDS
	/// Damage dealt by the dash attack
	var/dash_damage = 150
	/// Bleed stacks applied by dash
	var/dash_bleed = 8
	/// Lines spoken during slash attack
	var/list/slash_lines = list(
		"I'll cut you up all pretty!",
		"SNIP!!",
		"I'll cut you together!",
		"I don't need ugly things!!"
	)
	/// Lines spoken during dash attack
	var/list/dash_lines = list(
		"Hold still, I'll make you BEAUTIFUL!",
		"Let me fix those imperfections!",
		"A little trim here and there...!",
		"You'll look so pretty when I'm done!"
	)

/mob/living/simple_animal/hostile/bloodfiend_boss/barber/Initialize()
	. = ..()
	boss_soundloop = new /datum/looping_sound/bloodfiend_barber(list(src), FALSE)

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
	// Try to use dash attack even while in melee
	if(dash_cooldown <= world.time && attacked_target)
		BloodTrailDash(attacked_target)
		return FALSE
	return Slash(attacked_target)

/mob/living/simple_animal/hostile/bloodfiend_boss/barber/OpenFire()
	if(!can_act)
		return
	if(dash_cooldown > world.time)
		return
	BloodTrailDash(target)

/mob/living/simple_animal/hostile/bloodfiend_boss/barber/UpdateEnragedVisual()
	if(enraged)
		icon_state = icon_buffed
		icon_living = icon_buffed
		color = "#FF6666"
	else
		icon_state = icon_base
		icon_living = icon_base
		color = initial(color)

/mob/living/simple_animal/hostile/bloodfiend_boss/barber/bullet_act(obj/projectile/P)
	if(dashing)
		P.Destroy()
		new /obj/effect/temp_visual/healing/no_dam(get_turf(src))
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

	// Determine perpendicular and opposite directions
	var/perp_dir1
	var/perp_dir2
	var/opposite_dir
	switch(dir_to_target)
		if(NORTH)
			perp_dir1 = EAST
			perp_dir2 = WEST
			opposite_dir = SOUTH
		if(SOUTH)
			perp_dir1 = EAST
			perp_dir2 = WEST
			opposite_dir = NORTH
		if(EAST)
			perp_dir1 = NORTH
			perp_dir2 = SOUTH
			opposite_dir = WEST
		if(WEST)
			perp_dir1 = NORTH
			perp_dir2 = SOUTH
			opposite_dir = EAST
		else
			// Fallback for non-cardinal directions
			for(var/turf/T in view(1, src))
				if(T.density)
					continue
				if(T in area_of_effect)
					continue
				area_of_effect |= T

	if(dir_to_target in GLOB.cardinals)
		// Add Barber's own turf and perpendicular tiles (2 to each side)
		area_of_effect += source_turf
		for(var/turf/T in getline(source_turf, get_ranged_target_turf(source_turf, perp_dir1, slash_width)))
			if(T.density)
				break
			area_of_effect |= T
		for(var/turf/T in getline(source_turf, get_ranged_target_turf(source_turf, perp_dir2, slash_width)))
			if(T.density)
				break
			area_of_effect |= T

		// Add one row behind Barber (with perpendicular spread)
		var/turf/behind_turf = get_step(source_turf, opposite_dir)
		if(behind_turf && !behind_turf.density)
			area_of_effect |= behind_turf
			for(var/turf/T in getline(behind_turf, get_ranged_target_turf(behind_turf, perp_dir1, slash_width)))
				if(T.density)
					break
				area_of_effect |= T
			for(var/turf/T in getline(behind_turf, get_ranged_target_turf(behind_turf, perp_dir2, slash_width)))
				if(T.density)
					break
				area_of_effect |= T

		// Add the forward slash area (starting from Barber's position, going forward)
		middle_line = getline(source_turf, get_ranged_target_turf(source_turf, dir_to_target, slash_length))
		for(var/turf/T in middle_line)
			if(T.density)
				break
			for(var/turf/Y in getline(T, get_ranged_target_turf(T, perp_dir1, slash_width)))
				if(Y.density)
					break
				area_of_effect |= Y
			for(var/turf/U in getline(T, get_ranged_target_turf(T, perp_dir2, slash_width)))
				if(U.density)
					break
				area_of_effect |= U

	if(!LAZYLEN(area_of_effect))
		return

	can_act = FALSE
	dir = dir_to_target
	if(prob(40))
		say(pick(slash_lines))
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
		// Damage mobs - check for bleed bonus
		for(var/mob/living/L in T)
			if(faction_check_mob(L))
				continue
			// Check if target has 40+ bleed stacks for bonus damage
			var/target_damage = actual_damage
			var/datum/status_effect/stacking/lc_bleed/BE = L.has_status_effect(/datum/status_effect/stacking/lc_bleed)
			if(BE && BE.stacks >= 40)
				target_damage = actual_damage * 2 // 100% more damage
			L.deal_damage(target_damage, RED_DAMAGE, src, attack_type = ATTACK_TYPE_MELEE)
			L.apply_lc_bleed(bleed_stacks)
			targets_hit++
		// Damage mechs
		for(var/obj/vehicle/sealed/mecha/M in T)
			M.take_damage(actual_damage, RED_DAMAGE)
		// Damage barricades (double damage)
		for(var/obj/structure/barricade/B in T)
			B.take_damage(actual_damage * 2, RED_DAMAGE)

	// Generate 100 bloodfeast per target hit, or lose bloodfeast if missed at 50%+
	if(bloodfeast)
		if(targets_hit > 0)
			bloodfeast.blood_amount = min(bloodfeast.blood_amount + (targets_hit * 100), max_blood)
			last_blood_check = -1 // Force buff update
		else if(bloodfeast.blood_amount >= max_blood * 0.5)
			bloodfeast.blood_amount = max(bloodfeast.blood_amount - 150, 0)
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
	say(pick(dash_lines))
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
		// Leave blood trail on open turfs (lasts as long as dash cooldown), don't overlap
		if(!isclosedturf(T) && !locate(/obj/effect/barber_blood_trail) in T)
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
				// Check if target has 40+ bleed stacks for bonus damage
				var/target_damage = dash_damage
				var/datum/status_effect/stacking/lc_bleed/BE = L.has_status_effect(/datum/status_effect/stacking/lc_bleed)
				if(BE && BE.stacks >= 40)
					target_damage = dash_damage * 2 // 100% more damage
				L.deal_damage(target_damage, RED_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
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
				// Check if target has 40+ bleed stacks for bonus damage
				var/target_damage = dash_damage
				var/datum/status_effect/stacking/lc_bleed/BE = L.has_status_effect(/datum/status_effect/stacking/lc_bleed)
				if(BE && BE.stacks >= 40)
					target_damage = dash_damage * 2 // 100% more damage
				L.deal_damage(target_damage, RED_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
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

	// Lose bloodfeast if no targets hit while at 50%+ bloodfeast
	if(!length(hit_mobs))
		var/datum/component/bloodfeast/bloodfeast = GetComponent(/datum/component/bloodfeast)
		if(bloodfeast && bloodfeast.blood_amount >= max_blood * 0.5)
			bloodfeast.blood_amount = max(bloodfeast.blood_amount - 350, 0)
			last_blood_check = -1 // Force buff update

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
	can_act = TRUE
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
	/// Whip attack cooldown tracker
	var/whip_cooldown = 0
	/// Time between whip attacks
	var/whip_cooldown_time = 3 SECONDS
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
	var/miss_bloodfeast_loss = 500
	/// Lines spoken during whip attack
	var/list/whip_lines = list(
		"This unforgivable sin...!",
		"The rightful punishment!",
		"It is a pain... that must be endured!",
		"Repent through suffering!"
	)
	/// Lines spoken during tendril attack
	var/list/tendril_lines = list(
		"How can it be so abundant...?",
		"The blood flows endlessly!",
		"All of it shall be collected!",
		"Such bounty must not be wasted!"
	)

/mob/living/simple_animal/hostile/bloodfiend_boss/priest/Initialize()
	. = ..()
	boss_soundloop = new /datum/looping_sound/bloodfiend_priest(list(src), FALSE)

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
	// Use whip attack if target is within whip range and off cooldown
	if(target && get_dist(src, target) <= whip_range && whip_cooldown <= world.time)
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
	whip_cooldown = world.time + whip_cooldown_time
	// Self-harm before attack
	SelfHarm()
	if(prob(40))
		say(pick(whip_lines))
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
			been_hit = HurtInTurf(TF, been_hit, actual_damage, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, hurt_structure = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			// Damage barricades (double damage)
			for(var/obj/structure/barricade/B in TF)
				B.take_damage(actual_damage * 2, RED_DAMAGE)
	// Apply bleed and knockdown to all hit targets
	for(var/mob/living/L in been_hit)
		L.apply_lc_bleed(whip_bleed)
		if(can_knockdown)
			L.Knockdown(1 SECONDS)
	// Generate bloodfeast from hits, or lose bloodfeast if missed at 50%+
	if(bloodfeast)
		if(length(been_hit))
			bloodfeast.blood_amount = min(bloodfeast.blood_amount + (length(been_hit) * 25), max_blood)
		else if(bloodfeast.blood_amount >= max_blood * 0.5)
			bloodfeast.blood_amount = max(bloodfeast.blood_amount - miss_bloodfeast_loss, 0)
			last_blood_check = -1 // Force buff update
	playsound(src, 'sound/creatures/lc13/lovetown/abomination_lovewhip_hit.ogg', 75, TRUE)
	can_act = TRUE

/// Tendril burst - 3 self-harms then fires tendrils in all directions
/mob/living/simple_animal/hostile/bloodfiend_boss/priest/proc/TendrilBurst()
	tendril_cooldown = world.time + tendril_cooldown_time
	can_act = FALSE
	say(pick(tendril_lines))
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
			for(var/mob/living/L in HurtInTurf(TT, list(), actual_damage, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, hurt_structure = TRUE, attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL)))
				new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(L), pick(GLOB.alldirs))
				L.apply_lc_bleed(tendril_bleed)
				total_hits++
			// Damage barricades (double damage)
			for(var/obj/structure/barricade/B in TT)
				B.take_damage(actual_damage * 2, RED_DAMAGE)
	// Lose bloodfeast if no targets hit at 50%+
	if(bloodfeast && total_hits == 0 && bloodfeast.blood_amount >= max_blood * 0.5)
		bloodfeast.blood_amount = max(bloodfeast.blood_amount - miss_bloodfeast_loss, 0)
		last_blood_check = -1 // Force buff update
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
	can_act = TRUE
	/// List of spawned units
	var/list/spawned_units = list()
	/// List of bodyguard units
	var/list/bodyguards = list()
	/// List of beam datums for cleanup
	var/list/spawn_beams = list()
	/// Spawn cooldown tracker
	var/spawn_cooldown = 0
	/// Time between spawns
	var/spawn_cooldown_time = 4 SECONDS
	/// Maximum non-bodyguard spawns
	var/max_spawns = 4
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
	/// Lines spoken during grief AoE attack
	var/list/grief_lines = list(
		"Don't come closer... for beautiful thorns will bloom abundantly.",
		"Where could the end of this parade be...?",
		"The festivities must continue..."
	)
	/// Lines spoken during rage AoE attack
	var/list/rage_lines = list(
		"Let's start the finale...",
		"...Time to drink.",
		"The parade reaches its climax.",
		"Now... let me show you true beauty."
	)

/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/Initialize()
	. = ..()
	boss_soundloop = new /datum/looping_sound/bloodfiend_dulcinea(list(src), FALSE)
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
	if(prob(50))
		say(pick(grief_lines))
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
		been_hit = HurtInTurf(T, been_hit, grief_aoe_damage, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, hurt_structure = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		// Damage barricades (5x damage)
		for(var/obj/structure/barricade/B in T)
			B.take_damage(grief_aoe_damage * 5, RED_DAMAGE)
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
	say(pick(rage_lines))
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
			been_hit = HurtInTurf(T, been_hit, rage_aoe_damage, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, hurt_structure = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			// Damage barricades (5x damage)
			for(var/obj/structure/barricade/B in T)
				B.take_damage(rage_aoe_damage * 5, RED_DAMAGE)
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
	// Kill all spawned units
	for(var/mob/living/L in spawned_units)
		if(!QDELETED(L) && L.stat != DEAD)
			L.death()
	for(var/mob/living/L in bodyguards)
		if(!QDELETED(L) && L.stat != DEAD)
			L.death()
	spawned_units.Cut()
	bodyguards.Cut()
	// Clean up beams
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
	/// Last health threshold crossed (for notifying Dulcinea)
	var/last_health_threshold = 4
	slash_lines = list(
		"You won't reach the Heart!",
		"Father's dream was WEAK!",
		"I'll cut you to PIECES!",
		"The Heart gave us EVERYTHING!!"
	)
	dash_lines = list(
		"We don't need Father's dream!",
		"You'll never touch the Heart!",
		"The Heart is our TRUE family!",
		"DIE FOR THE HEART!!"
	)

/mob/living/simple_animal/hostile/bloodfiend_boss/barber/weakened/Initialize()
	. = ..()
	// Don't use individual soundloop - trio theme is handled by barber landmark
	QDEL_NULL(boss_soundloop)

/mob/living/simple_animal/hostile/bloodfiend_boss/barber/weakened/Life()
	. = ..()
	if(stat == DEAD)
		return FALSE
	// Check health thresholds (75%, 50%, 25%, 0%)
	var/current_threshold = FLOOR(health / (maxHealth * 0.25), 1)
	if(current_threshold < last_health_threshold)
		var/thresholds_crossed = last_health_threshold - current_threshold
		last_health_threshold = current_threshold
		NotifyDulcineaGrief(thresholds_crossed * 10)

/// Notify weakened Dulcinea to add grief stacks
/mob/living/simple_animal/hostile/bloodfiend_boss/barber/weakened/proc/NotifyDulcineaGrief(stacks)
	if(!home_landmark || !home_landmark.parent_heart)
		return
	for(var/obj/effect/landmark/bloodfiend_boss/BL in home_landmark.parent_heart.boss_landmarks)
		if(BL.spawned_boss && istype(BL.spawned_boss, /mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/weakened))
			var/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/weakened/D = BL.spawned_boss
			D.grief_stacks += stacks
			INVOKE_ASYNC(D, TYPE_PROC_REF(/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea, CheckGriefThresholds))
			break

/// Weakened Priest - 25% less health, 200% longer whip cooldown
/mob/living/simple_animal/hostile/bloodfiend_boss/priest/weakened
	name = "The Priest (Weakened)"
	maxHealth = 4125 // 5500 * 0.75
	health = 4125
	whip_cooldown_time = 6 SECONDS
	/// Last health threshold crossed (for notifying Dulcinea)
	var/last_health_threshold = 4
	whip_lines = list(
		"Forgive me, Father... I must protect the Heart!",
		"I betrayed you, Father... but I cannot stop now!",
		"The Heart... it was a mistake... but it's all we have!",
		"Father... I'm sorry... I'M SORRY!!"
	)
	tendril_lines = list(
		"We turned our backs on Father's dream...!",
		"The guilt... it never fades...!",
		"I chose the Heart over Father... and I cannot undo it!",
		"Father forgive me... FATHER FORGIVE ME!!"
	)

/mob/living/simple_animal/hostile/bloodfiend_boss/priest/weakened/Initialize()
	. = ..()
	// Don't use individual soundloop - trio theme is handled by barber landmark
	QDEL_NULL(boss_soundloop)

/mob/living/simple_animal/hostile/bloodfiend_boss/priest/weakened/Life()
	. = ..()
	if(stat == DEAD)
		return FALSE
	// Check health thresholds (75%, 50%, 25%, 0%)
	var/current_threshold = FLOOR(health / (maxHealth * 0.25), 1)
	if(current_threshold < last_health_threshold)
		var/thresholds_crossed = last_health_threshold - current_threshold
		last_health_threshold = current_threshold
		NotifyDulcineaGrief(thresholds_crossed * 10)

/// Notify weakened Dulcinea to add grief stacks
/mob/living/simple_animal/hostile/bloodfiend_boss/priest/weakened/proc/NotifyDulcineaGrief(stacks)
	if(!home_landmark || !home_landmark.parent_heart)
		return
	for(var/obj/effect/landmark/bloodfiend_boss/BL in home_landmark.parent_heart.boss_landmarks)
		if(BL.spawned_boss && istype(BL.spawned_boss, /mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/weakened))
			var/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/weakened/D = BL.spawned_boss
			D.grief_stacks += stacks
			INVOKE_ASYNC(D, TYPE_PROC_REF(/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea, CheckGriefThresholds))
			break

/// Weakened Dulcinea - 25% less health, doesn't spawn allies, gains grief from sibling damage
/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/weakened
	name = "Dulcinea (Weakened)"
	maxHealth = 4875 // 6500 * 0.75
	health = 4875
	grief_lines = list(
		"Father's dream was never going to work...",
		"The Heart gave us what Father couldn't.",
		"We made our choice... and we don't regret it.",
		"The Heart is everything now..."
	)
	rage_lines = list(
		"Father was too kind... too naive.",
		"The Heart of Greed will survive.",
		"We chose the Heart... and we would again.",
		"This is what we wanted."
	)

/mob/living/simple_animal/hostile/bloodfiend_boss/dulcinea/weakened/Initialize()
	. = ..()
	// Don't use individual soundloop - trio theme is handled by barber landmark
	QDEL_NULL(boss_soundloop)

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

/// Global list for heart -> landmarks linking by ID
GLOBAL_LIST_EMPTY(bloodfiend_hearts)
/// Global list for ferris wheel -> trigger landmarks linking by ID
GLOBAL_LIST_EMPTY(bloodfiend_ferris_wheels)

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
	/// Unique ID for linking with landmarks (set in map editor)
	var/link_id = "default"

/obj/structure/xcorp_heart_research/Initialize()
	. = ..()
	AddElement(/datum/element/point_of_interest)
	// Register in global list for landmark linking
	GLOB.bloodfiend_hearts[link_id] = src
	// Add pulsing glow effect
	add_filter("heart_glow", 2, list("type" = "outline", "color" = "#ff000050", "size" = 3))
	addtimer(CALLBACK(src, PROC_REF(GlowLoop)), rand(1, 19))

/obj/structure/xcorp_heart_research/proc/GlowLoop()
	var/filter = get_filter("heart_glow")
	if(filter)
		animate(filter, alpha = 180, time = 20, loop = -1)
		animate(alpha = 60, time = 30)

/obj/structure/xcorp_heart_research/Destroy()
	// Unregister from global list
	if(GLOB.bloodfiend_hearts[link_id] == src)
		GLOB.bloodfiend_hearts -= link_id
	if(!destroyed)
		destroyed = TRUE
		// Notify gamedirector that the Heart Research has been destroyed - disables raids and final wave
		SSgamedirector.heart_research_destroyed = TRUE
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
	/// Whether this landmark's boss has been killed (vs never spawned)
	var/boss_killed = FALSE
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
	/// Link ID to match with heart (set in map editor)
	var/link_id = "default"

/obj/effect/landmark/bloodfiend_boss/Initialize()
	. = ..()
	START_PROCESSING(SSobj, src)
	return INITIALIZE_HINT_LATELOAD

/obj/effect/landmark/bloodfiend_boss/LateInitialize()
	. = ..()
	// Find parent heart via global list using link_id
	FindParentHeart()

/// Finds and registers with heart via global list
/obj/effect/landmark/bloodfiend_boss/proc/FindParentHeart()
	// Look up heart by link_id in global list
	var/obj/structure/xcorp_heart_research/heart = GLOB.bloodfiend_hearts[link_id]
	if(heart)
		parent_heart = heart
		heart.boss_landmarks += src
		// Store heart location for portal spawning after heart is destroyed
		heart_location = get_turf(heart)
	// Build sibling landmark list
	BuildSiblingList()

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
	boss_killed = TRUE
	INVOKE_ASYNC(src, PROC_REF(CheckAllBossesDead))

/// Checks if all bosses from the parent heart are dead
/obj/effect/landmark/bloodfiend_boss/proc/CheckAllBossesDead()
	// Check our own boss first - must be killed (not just unspawned)
	if(!boss_killed)
		return // Our boss hasn't been killed yet
	if(spawned_boss && !QDELETED(spawned_boss) && spawned_boss.stat != DEAD)
		return // Our boss is still alive
	// Check sibling landmarks' bosses
	for(var/obj/effect/landmark/bloodfiend_boss/BL in sibling_landmarks)
		if(!BL.boss_killed)
			return // This sibling's boss hasn't been killed yet
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
	/// Trio theme soundloop - controlled by dulcinea landmark
	var/datum/looping_sound/bloodfiend_trio/trio_soundloop

/obj/effect/landmark/bloodfiend_boss/dulcinea/SpawnBoss()
	. = ..()
	// Start trio theme when dulcinea spawns
	if(!trio_soundloop)
		trio_soundloop = new(list(src), FALSE)
	trio_soundloop.start()

/obj/effect/landmark/bloodfiend_boss/dulcinea/SpawnFinalPortal()
	// Stop trio music when portal spawns
	if(trio_soundloop)
		trio_soundloop.stop()
		QDEL_NULL(trio_soundloop)
	. = ..()

/obj/effect/landmark/bloodfiend_boss/dulcinea/Destroy()
	if(trio_soundloop)
		trio_soundloop.stop()
		QDEL_NULL(trio_soundloop)
	return ..()
