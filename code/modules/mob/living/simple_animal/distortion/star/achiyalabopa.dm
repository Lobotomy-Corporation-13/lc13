/// Achiyalabopa - STAR level distortion boss
/mob/living/simple_animal/hostile/distortion/achiyalabopa
	name = "Achiyalabopa"
	desc = "A magnificent golden being of immense power. Its very presence fills you with overwhelming awe."
	icon = 'ModularLobotomy/_Lobotomyicons/bird_achiyalabopa.dmi'
	icon_state = "achiyalabopa"
	icon_living = "achiyalabopa"
	icon_dead = "achiyalabopa_dead"
	maxHealth = 6000
	health = 6000
	damage_coeff = list(RED_DAMAGE = 0.2, WHITE_DAMAGE = 0.2, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 0.2)
	melee_damage_lower = 20
	melee_damage_upper = 40
	melee_damage_type = PALE_DAMAGE
	attack_verb_continuous = "smites"
	attack_verb_simple = "smite"
	attack_sound = 'ModularLobotomy/_Lobotomysounds/weapons/guns/manager_wind.ogg'
	death_sound = 'sound/spookoween/ghosty_wind.ogg'
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	ranged_ignores_vision = TRUE
	vision_range = 15
	aggro_vision_range = 20
	move_to_delay = 4
	generic_canpass = FALSE
	fear_level = ALEPH_LEVEL
	can_spawn = 0
	del_on_death = TRUE
	pixel_x = -16
	base_pixel_x = -16
	/// Reference to the storm
	var/datum/weather/achiyalabopa_storm/storm
	/// Reference to the Coreflame
	var/obj/item/coreflame/coreflame
	/// Is Achiyalabopa currently vulnerable?
	var/is_vulnerable = FALSE
	/// Current target landmark
	var/obj/effect/landmark/mirage_reaper_spawn/current_landmark
	/// Movement timer ID
	var/move_timer_id
	/// Reference to impaled spear
	var/obj/effect/piercing_spear/impaled_spear
	/// Thunder summoning cooldown
	var/thunder_cooldown = 0
	var/thunder_cooldown_time = 3 SECONDS
	/// Thunder whip cooldown
	var/thunder_whip_cooldown = 0
	var/thunder_whip_cooldown_time = 20 SECONDS
	/// AoE attack cooldown
	var/aoe_cooldown = 0
	var/aoe_cooldown_time = 15 SECONDS
	/// Is currently performing AoE attack
	var/is_performing_aoe = FALSE
	/// Is currently performing Thunder Whip
	var/is_performing_thunder_whip = FALSE

/mob/living/simple_animal/hostile/distortion/achiyalabopa/Initialize()
	. = ..()

	// Set golden light
	set_light(8, 6, LIGHT_COLOR_ORANGE)

	// Start the storm after initialization completes (avoid blocking)
	addtimer(CALLBACK(src, PROC_REF(StartStorm)), 1)

	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(show_global_blurb), 20, "Achiyalabopa descends upon the city! Darkness engulfs everything!", 25))
	sound_to_playing_players_on_level('sound/magic/clockwork/narsie_attack.ogg', 50, zlevel = z)

	// Start landmark movement system
	PickNewLandmark()
	move_timer_id = addtimer(CALLBACK(src, PROC_REF(MoveToLandmark)), move_to_delay, TIMER_STOPPABLE)

/// Starts the storm (delayed from Initialize to avoid blocking)
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/StartStorm()
	storm = SSweather.run_weather(/datum/weather/achiyalabopa_storm)

/mob/living/simple_animal/hostile/distortion/achiyalabopa/Life()
	. = ..()
	if(!.)
		return FALSE

	// Apply Awe Struck to all visible humans
	ApplyAweStruck()

	// Passive thunder summoning
	if(thunder_cooldown < world.time)
		SummonThunder()

	// AoE attack
	if(aoe_cooldown < world.time)
		DivineJudgment()

	// Thunder Whip attack
	if(thunder_whip_cooldown < world.time && target)
		ThunderWhip(target)

/mob/living/simple_animal/hostile/distortion/achiyalabopa/Move()
	// Can't move during AoE attack or Thunder Whip
	if(is_performing_aoe || is_performing_thunder_whip)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/distortion/achiyalabopa/AttackingTarget(atom/attacked_target)
	// Can't melee attack during AoE or Thunder Whip
	if(is_performing_aoe || is_performing_thunder_whip)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/distortion/achiyalabopa/death(gibbed)
	// End the storm (which will also clean up reapers)
	if(storm && !QDELETED(storm))
		SSweather.end_weather(storm)

	visible_message(span_userdanger("Achiyalabopa starts fading away... The storm begins to dissipate!"))
	return ..()

/// Applies Awe Struck status to all humans who can see Achiyalabopa
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/ApplyAweStruck()
	for(var/mob/living/carbon/human/H in view(vision_range, src))
		if(H.stat == DEAD)
			continue

		// Apply or refresh Awe Struck
		var/datum/status_effect/awe_struck/awe = H.has_status_effect(/datum/status_effect/awe_struck)
		if(!awe)
			awe = H.apply_status_effect(/datum/status_effect/awe_struck)
			if(awe)
				awe.source_mob = src

/// Makes Achiyalabopa vulnerable for a duration
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/MakeVulnerable(duration, obj/effect/piercing_spear/spear)
	if(is_vulnerable)
		return

	is_vulnerable = TRUE

	// Change resistances to make vulnerable
	ChangeResistances(list(RED_DAMAGE = 2, WHITE_DAMAGE = 2, BLACK_DAMAGE = 2, PALE_DAMAGE = 4))

	// Visual indication
	animate(src, color = "#FF8888", time = 5)
	visible_message(span_userdanger("[src]'s defenses weaken! Now is the time to strike!"))

	// If spear is provided, attach it to Achiyalabopa
	if(spear && !QDELETED(spear))
		// Store reference to spear
		impaled_spear = spear

		// Move spear to Achiyalabopa's location and attach visually
		spear.forceMove(loc)
		spear.pixel_x = pixel_x
		spear.pixel_y = 48 // Position higher for tall sprite
		spear.layer = ABOVE_MOB_LAYER
		// Rotate to look like it's impaled at an angle
		spear.transform = matrix().Turn(165) // Slight angle, not completely upside down
		spear.name = "impaled divine spear"
		spear.desc = "The divine spear has pierced through Achiyalabopa's golden armor, exposing its weakness."
		// Make it pulse/glow while impaled
		animate(spear, alpha = 200, time = 10, loop = -1)
		animate(alpha = 255, time = 10)

		// Register movement signal to track Achiyalabopa's position
		RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(UpdateSpearPosition))

		// Set timer to remove spear when vulnerability ends
		addtimer(CALLBACK(src, PROC_REF(RemoveImpaledSpear), impaled_spear), duration)

	// Set timer to restore vulnerability
	addtimer(CALLBACK(src, PROC_REF(RestoreDefenses)), duration)

/// Removes the impaled spear
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/RemoveImpaledSpear(obj/effect/piercing_spear/spear)
	if(spear && !QDELETED(spear))
		animate(spear, alpha = 0, time = 10)
		QDEL_IN(spear, 10)

	// Unregister movement signal
	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
	impaled_spear = null

/// Updates the spear position when Achiyalabopa moves
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/UpdateSpearPosition()
	SIGNAL_HANDLER

	if(!impaled_spear || QDELETED(impaled_spear))
		return

	// Move spear to follow Achiyalabopa
	impaled_spear.forceMove(loc)

/// Restores Achiyalabopa's normal defenses
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/RestoreDefenses()
	if(!is_vulnerable)
		return

	is_vulnerable = FALSE

	// Restore original resistances
	ChangeResistances(list(RED_DAMAGE = 0.2, WHITE_DAMAGE = 0.2, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 0.4))

	// Visual indication
	animate(src, color = initial(color), time = 10)
	visible_message(span_warning("[src]'s defenses return to normal!"))

/mob/living/simple_animal/hostile/distortion/achiyalabopa/Destroy()
	storm = null
	coreflame = null
	current_landmark = null
	if(move_timer_id)
		deltimer(move_timer_id)
		move_timer_id = null

	// Clean up impaled spear
	if(impaled_spear && !QDELETED(impaled_spear))
		UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
		qdel(impaled_spear)
		impaled_spear = null

	return ..()

/// Picks a new random landmark to move towards
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/PickNewLandmark()
	if(!GLOB.mirage_reaper_spawns || !length(GLOB.mirage_reaper_spawns))
		return

	// Pick a random landmark that isn't the current one
	var/list/available_landmarks = GLOB.mirage_reaper_spawns.Copy()
	if(current_landmark && (current_landmark in available_landmarks))
		available_landmarks -= current_landmark

	if(!length(available_landmarks))
		return

	current_landmark = pick(available_landmarks)

/// Moves towards the current landmark
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/MoveToLandmark()
	// Don't patrol if we have an active target
	if(target)
		move_timer_id = addtimer(CALLBACK(src, PROC_REF(MoveToLandmark)), move_to_delay, TIMER_STOPPABLE)
		return

	if(!current_landmark || QDELETED(current_landmark))
		PickNewLandmark()
		if(!current_landmark)
			return

	var/turf/current_turf = get_turf(src)
	var/turf/target_turf = get_turf(current_landmark)

	if(!target_turf)
		PickNewLandmark()
		move_timer_id = addtimer(CALLBACK(src, PROC_REF(MoveToLandmark)), move_to_delay, TIMER_STOPPABLE)
		return

	// Check if we've reached the landmark
	if(current_turf == target_turf || get_dist(src, target_turf) <= 1)
		PickNewLandmark()
		move_timer_id = addtimer(CALLBACK(src, PROC_REF(MoveToLandmark)), move_to_delay, TIMER_STOPPABLE)
		return

	// Move towards the landmark
	step_towards(src, target_turf)

	// Schedule next movement
	move_timer_id = addtimer(CALLBACK(src, PROC_REF(MoveToLandmark)), move_to_delay, TIMER_STOPPABLE)

/// Summons thunder around Achiyalabopa (like thunder_bird but without conversion)
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/SummonThunder()
	thunder_cooldown = world.time + thunder_cooldown_time

	var/thunder_range = 7
	var/targets_hit = 0
	var/max_targets = 3

	for(var/mob/living/carbon/human/L in range(thunder_range, src))
		if(L.stat == DEAD)
			continue
		if(targets_hit >= max_targets)
			break

		targets_hit++
		var/obj/effect/divine_thunderbolt/E = new(get_turf(L.loc))
		E.master = src

/// Thunder Whip - Conical lightning attack that strikes in waves
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/ThunderWhip(atom/attack_target)
	set waitfor = FALSE

	thunder_whip_cooldown = world.time + thunder_whip_cooldown_time
	is_performing_thunder_whip = TRUE

	face_atom(attack_target)
	icon_state = "achiyalabopa_enraged"
	visible_message(span_userdanger("[src] raises its wings! Lightning crackles in the air!"))
	playsound(get_turf(src), 'sound/magic/lightningshock.ogg', 75, TRUE)

	// Calculate conical AoE (similar to LoveWhip)
	var/smash_width = 1
	var/smash_length = 3
	var/dir_to_target = get_cardinal_dir(get_turf(src), get_turf(attack_target))
	var/turf/source_turf = get_turf(src)
	var/list/area_of_effect = list()
	var/list/middle_line = list()
	var/turf/second_line = get_ranged_target_turf(source_turf, dir_to_target, smash_length-2)

	SLEEP_CHECK_DEATH(2.5 SECONDS)

	// Build the cone pattern
	switch(dir_to_target)
		if(EAST)
			for(var/i = 0, i<2, i++)
				middle_line = getline(source_turf, get_ranged_target_turf(source_turf, dir_to_target, smash_length))
				for(var/turf/T in middle_line)
					if(T.density)
						break
					for(var/turf/Y in getline(T, get_ranged_target_turf(T, NORTH, smash_width)))
						if(Y.density)
							break
						if(Y in area_of_effect)
							continue
						area_of_effect += Y
					for(var/turf/U in getline(T, get_ranged_target_turf(T, SOUTH, smash_width)))
						if(U.density)
							break
						if(U in area_of_effect)
							continue
						area_of_effect += U
				source_turf = get_ranged_target_turf(second_line, EAST, smash_length)
				smash_length += 2
				smash_width++
		if(WEST)
			for(var/i = 0, i<2, i++)
				middle_line = getline(source_turf, get_ranged_target_turf(source_turf, dir_to_target, smash_length))
				for(var/turf/T in middle_line)
					if(T.density)
						break
					for(var/turf/Y in getline(T, get_ranged_target_turf(T, NORTH, smash_width)))
						if(Y.density)
							break
						if(Y in area_of_effect)
							continue
						area_of_effect += Y
					for(var/turf/U in getline(T, get_ranged_target_turf(T, SOUTH, smash_width)))
						if(U.density)
							break
						if(U in area_of_effect)
							continue
						area_of_effect += U
				source_turf = get_ranged_target_turf(second_line, WEST, smash_length)
				smash_length += 2
				smash_width++
		if(NORTH)
			for(var/i = 0, i<2, i++)
				middle_line = getline(source_turf, get_ranged_target_turf(source_turf, dir_to_target, smash_length))
				for(var/turf/T in middle_line)
					if(T.density)
						break
					for(var/turf/Y in getline(T, get_ranged_target_turf(T, EAST, smash_width)))
						if(Y.density)
							break
						if(Y in area_of_effect)
							continue
						area_of_effect += Y
					for(var/turf/U in getline(T, get_ranged_target_turf(T, WEST, smash_width)))
						if(U.density)
							break
						if(U in area_of_effect)
							continue
						area_of_effect += U
				source_turf = get_ranged_target_turf(second_line, NORTH, smash_length)
				smash_length += 2
				smash_width++
		if(SOUTH)
			for(var/i = 0, i<2, i++)
				middle_line = getline(source_turf, get_ranged_target_turf(source_turf, dir_to_target, smash_length))
				for(var/turf/T in middle_line)
					if(T.density)
						break
					for(var/turf/Y in getline(T, get_ranged_target_turf(T, EAST, smash_width)))
						if(Y.density)
							break
						if(Y in area_of_effect)
							continue
						area_of_effect += Y
					for(var/turf/U in getline(T, get_ranged_target_turf(T, WEST, smash_width)))
						if(U.density)
							break
						if(U in area_of_effect)
							continue
						area_of_effect += U
				source_turf = get_ranged_target_turf(second_line, SOUTH, smash_length)
				smash_length += 2
				smash_width++
		else
			for(var/turf/T in view(1, src))
				if(T.density)
					continue
				if(T in area_of_effect)
					continue
				area_of_effect += T

	if(!LAZYLEN(area_of_effect))
		is_performing_thunder_whip = FALSE
		icon_state = "achiyalabopa"
		return

	// Sort turfs by distance from Achiyalabopa
	var/list/sorted_turfs = list()
	var/turf/my_turf = get_turf(src)
	var/max_distance = 0
	for(var/turf/T in area_of_effect)
		var/distance = get_dist(my_turf, T)
		if(!sorted_turfs["[distance]"])
			sorted_turfs["[distance]"] = list()
		sorted_turfs["[distance]"] += T
		if(distance > max_distance)
			max_distance = distance

	// Strike turfs in waves of 3, starting from closest
	var/turfs_per_wave = 3
	var/delay_per_wave = 1.5 // 0.15 seconds between waves

	var/turfs_struck = 0

	// Process each distance tier in order, from 0 to max_distance
	for(var/dist = 0 to max_distance)
		var/list/turfs_at_distance = sorted_turfs["[dist]"]
		if(!turfs_at_distance)
			continue

		for(var/turf/T in turfs_at_distance)
			if(stat == DEAD)
				is_performing_thunder_whip = FALSE
				icon_state = "achiyalabopa"
				return

			// Trigger lightning effect
			new /obj/effect/temp_visual/thunderbolt_strike(T)
			playsound(T, 'sound/magic/lightningbolt.ogg', 50, TRUE)

			// Deal damage to mobs in turf
			for(var/mob/living/L in T)
				if(faction_check_mob(L))
					continue
				L.deal_damage(50, PALE_DAMAGE)
				to_chat(L, span_userdanger("You are struck by divine lightning!"))

			turfs_struck++

			// Wait after every 3 turfs
			if(turfs_struck % turfs_per_wave == 0)
				sleep(delay_per_wave)

	is_performing_thunder_whip = FALSE
	icon_state = "achiyalabopa"

/// Divine Judgment - Multi-wave AoE attack with thick patterns
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/DivineJudgment()
	aoe_cooldown = world.time + aoe_cooldown_time
	is_performing_aoe = TRUE

	visible_message(span_userdanger("[src] raises its wings! Divine judgment descends!"))
	playsound(src, 'sound/magic/clockwork/narsie_attack.ogg', 75, TRUE, 20)

	// Execute 3 waves of attacks
	DivineJudgmentWave(1)

/// Executes a single wave of Divine Judgment
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/DivineJudgmentWave(wave_number)
	if(stat == DEAD)
		is_performing_aoe = FALSE
		return

	// Randomly pick between normal + (1 tile thick) or wide + (3 tiles wide with safe center)
	var/pattern_type = pick("plus", "plus_wide")

	// Get danger tiles based on pattern
	var/list/danger_tiles = list()
	if(pattern_type == "plus")
		danger_tiles = GetPlusPattern()
	else
		danger_tiles = GetWidePlusPattern()

	// Show warning effects
	for(var/turf/T in danger_tiles)
		new /obj/effect/temp_visual/divine_judgment_warning(T)

	// After 2 seconds, damage all targets in the danger zone
	addtimer(CALLBACK(src, PROC_REF(DivineJudgmentStrike), danger_tiles, wave_number), 2 SECONDS)

/// Generates a normal plus pattern (1 tile thick, range 7)
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/GetPlusPattern()
	var/list/danger_tiles = list()
	var/turf/center = get_turf(src)

	if(!center)
		return danger_tiles

	// Add center tile
	danger_tiles += center

	// Create thin cross pattern (1 tile thick)
	for(var/i = 1 to 7)
		// North arm
		var/turf/T_north = locate(center.x, center.y + i, center.z)
		if(T_north)
			danger_tiles += T_north

		// South arm
		var/turf/T_south = locate(center.x, center.y - i, center.z)
		if(T_south)
			danger_tiles += T_south

		// East arm
		var/turf/T_east = locate(center.x + i, center.y, center.z)
		if(T_east)
			danger_tiles += T_east

		// West arm
		var/turf/T_west = locate(center.x - i, center.y, center.z)
		if(T_west)
			danger_tiles += T_west

	return danger_tiles

/// Generates a wide plus pattern (3 tiles wide with safe center, range 7)
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/GetWidePlusPattern()
	var/list/danger_tiles = list()
	var/turf/center = get_turf(src)

	if(!center)
		return danger_tiles

	// Center tile is SAFE - not added to danger_tiles

	// Create 3-wide cross pattern with safe center
	for(var/i = 1 to 7)
		// North arm (left and right sides, skip center)
		var/turf/T_north_left = locate(center.x - 1, center.y + i, center.z)
		if(T_north_left)
			danger_tiles += T_north_left
		var/turf/T_north_right = locate(center.x + 1, center.y + i, center.z)
		if(T_north_right)
			danger_tiles += T_north_right

		// South arm (left and right sides, skip center)
		var/turf/T_south_left = locate(center.x - 1, center.y - i, center.z)
		if(T_south_left)
			danger_tiles += T_south_left
		var/turf/T_south_right = locate(center.x + 1, center.y - i, center.z)
		if(T_south_right)
			danger_tiles += T_south_right

		// East arm (top and bottom sides, skip center)
		var/turf/T_east_top = locate(center.x + i, center.y + 1, center.z)
		if(T_east_top)
			danger_tiles += T_east_top
		var/turf/T_east_bottom = locate(center.x + i, center.y - 1, center.z)
		if(T_east_bottom)
			danger_tiles += T_east_bottom

		// West arm (top and bottom sides, skip center)
		var/turf/T_west_top = locate(center.x - i, center.y + 1, center.z)
		if(T_west_top)
			danger_tiles += T_west_top
		var/turf/T_west_bottom = locate(center.x - i, center.y - 1, center.z)
		if(T_west_bottom)
			danger_tiles += T_west_bottom

	return danger_tiles

/// Executes the Divine Judgment strike
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/DivineJudgmentStrike(list/danger_tiles, wave_number)
	if(stat == DEAD)
		is_performing_aoe = FALSE
		return

	playsound(get_turf(src), 'sound/magic/lightningbolt.ogg', 100, TRUE, 20)

	for(var/turf/T in danger_tiles)
		new /obj/effect/temp_visual/divine_judgment_strike(T)

		for(var/mob/living/L in T)
			if(faction_check_mob(L))
				continue
			L.deal_damage(80, PALE_DAMAGE)
			to_chat(L, span_userdanger("You are struck by divine judgment!"))

	// Schedule next wave if we haven't done 3 waves yet
	if(wave_number < 3)
		addtimer(CALLBACK(src, PROC_REF(DivineJudgmentWave), wave_number + 1), 1 SECONDS)
	else
		// Final wave complete, allow movement again
		is_performing_aoe = FALSE

/// Divine Thunderbolt - Similar to thunder_bird's thunderbolt but without conversion
/obj/effect/divine_thunderbolt
	name = "divine thunder bolt"
	desc = "LOOK OUT!"
	icon = 'icons/effects/effects.dmi'
	icon_state = "tbird_bolt"
	move_force = INFINITY
	pull_force = INFINITY
	generic_canpass = FALSE
	movement_type = PHASING | FLYING
	layer = POINT_LAYER
	var/mob/living/simple_animal/hostile/distortion/achiyalabopa/master
	var/duration = 2 SECONDS
	var/range = 1
	var/boom_damage = 40

/obj/effect/divine_thunderbolt/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(Explode)), duration)

/obj/effect/divine_thunderbolt/proc/Explode()
	playsound(get_turf(src), 'sound/abnormalities/thunderbird/tbird_bolt.ogg', 50, FALSE, 8)
	var/list/turfs_to_check = view(range, src)
	for(var/mob/living/carbon/human/H in turfs_to_check)
		H.deal_damage(boom_damage, PALE_DAMAGE)
		H.electrocute_act(1, src, flags = SHOCK_NOSTUN)
	for(var/obj/vehicle/V in turfs_to_check)
		V.take_damage(boom_damage, PALE_DAMAGE)
	new /obj/effect/temp_visual/tbirdlightning(get_turf(src))
	var/datum/effect_system/smoke_spread/S = new
	S.set_up(0, get_turf(src))
	S.start()
	qdel(src)

/// Warning effect for Divine Judgment
/obj/effect/temp_visual/divine_judgment_warning
	icon = 'icons/effects/effects.dmi'
	icon_state = "lightwarning"
	duration = 2 SECONDS
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/divine_judgment_warning/Initialize()
	. = ..()
	animate(src, alpha = 100, time = 5, loop = -1)
	animate(alpha = 255, time = 5)

/// Strike effect for Divine Judgment
/obj/effect/temp_visual/divine_judgment_strike
	icon = 'icons/effects/effects.dmi'
	icon_state = "anom"
	duration = 1 SECONDS
	layer = ABOVE_MOB_LAYER

/// Thunderbolt strike effect for Thunder Whip
/obj/effect/temp_visual/thunderbolt_strike
	icon = 'icons/effects/effects.dmi'
	icon_state = "tbird_bolt"
	duration = 0.5 SECONDS
	layer = ABOVE_MOB_LAYER
	light_range = 2
	light_power = 2
	light_color = LIGHT_COLOR_ELECTRIC_CYAN

/// Awe Struck - Prevents approaching Achiyalabopa and applies fragility
/datum/status_effect/awe_struck
	id = "awe_struck"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/awe_struck
	/// Reference to Achiyalabopa
	var/mob/living/simple_animal/hostile/distortion/achiyalabopa/source_mob
	/// Visual overlay effect
	var/mutable_appearance/awe_overlay

/atom/movable/screen/alert/status_effect/awe_struck
	name = "Awe Struck"
	desc = "You are filled with overwhelming awe and cannot approach this magnificent being."
	icon_state = "blooddrunk"

/datum/status_effect/awe_struck/on_apply()
	. = ..()
	if(!.)
		return

	// Check if owner has hope or will_of_humanity (which grant immunity)
	if(owner.has_status_effect(/datum/status_effect/hope) || owner.has_status_effect(/datum/status_effect/will_of_humanity))
		return FALSE

	// Apply 6 fragility
	owner.apply_lc_feeble(6)

	// Register signal for movement restriction
	RegisterSignal(owner, COMSIG_MOVABLE_PRE_MOVE, PROC_REF(PreventApproach))

	to_chat(owner, span_userdanger("You are overwhelmed by awe! You cannot bring yourself to approach!"))
	return TRUE

/datum/status_effect/awe_struck/on_remove()
	// Remove visual overlay
	if(awe_overlay)
		owner.cut_overlay(awe_overlay)
		QDEL_NULL(awe_overlay)

	// Unregister signal
	UnregisterSignal(owner, COMSIG_MOVABLE_PRE_MOVE)

	to_chat(owner, span_notice("The overwhelming awe fades..."))
	return ..()

/datum/status_effect/awe_struck/proc/PreventApproach(datum/source, atom/new_loc)
	SIGNAL_HANDLER

	if(!source_mob || QDELETED(source_mob))
		qdel(src)
		return

	// Check if owner still has line of sight to Achiyalabopa
	if(!(owner in view(source_mob.vision_range, source_mob)))
		qdel(src)
		return

	// Calculate distances
	var/current_distance = get_dist(owner, source_mob)
	var/new_distance = get_dist(new_loc, source_mob)

	// Prevent moving closer
	if(new_distance < current_distance)
		to_chat(owner, span_warning("You cannot bring yourself to approach!"))
		return COMPONENT_MOVABLE_BLOCK_PRE_MOVE

/// Hope - Grants immunity to Awe Struck and damage buff
/datum/status_effect/hope
	id = "hope"
	status_type = STATUS_EFFECT_REFRESH
	duration = 60 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/hope
	/// Visual overlay effect
	var/mutable_appearance/hope_overlay
	/// Original owner color
	var/original_color

/atom/movable/screen/alert/status_effect/hope
	name = "Hope"
	desc = "You are filled with hope! You are immune to awe and deal increased damage."
	icon_state = "lightingorb"

/datum/status_effect/hope/on_apply()
	. = ..()
	if(!.)
		return

	// Remove awe_struck if present
	owner.remove_status_effect(/datum/status_effect/awe_struck)

	// Apply damage buff
	owner.apply_lc_strength(4)

	// Store original color and apply golden color
	if(ismob(owner))
		var/mob/M = owner
		original_color = M.color
		M.color = "#FFD700" // Golden color

	// Add yellow outline filter
	owner.add_filter("hope_glow", 2, list("type" = "outline", "color" = "#FFD70080", "size" = 2))
	addtimer(CALLBACK(src, PROC_REF(glow_loop)), rand(1, 19))

	to_chat(owner, span_nicegreen("You are filled with hope! Nothing can stop you now!"))
	return TRUE

/datum/status_effect/hope/on_remove()
	// Restore original color
	if(ismob(owner))
		var/mob/M = owner
		M.color = original_color

	// Remove outline filter
	owner.remove_filter("hope_glow")

	to_chat(owner, span_notice("The feeling of hope fades..."))
	return ..()

/// Animates the glow outline
/datum/status_effect/hope/proc/glow_loop()
	var/filter = owner.get_filter("hope_glow")
	if(filter)
		animate(filter, alpha = 180, time = 15, loop = -1)
		animate(alpha = 80, time = 25)

/// Will of Humanity - Special status for Coreflame holder
/datum/status_effect/will_of_humanity
	id = "will_of_humanity"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	alert_type = /atom/movable/screen/alert/status_effect/will_of_humanity
	/// Reference to the Coreflame item
	var/obj/item/coreflame/coreflame_item
	/// Visual overlay effect
	var/mutable_appearance/will_overlay
	/// Action: Hope Aura
	var/datum/action/cooldown/hope_aura/hope_action
	/// Spell: Piercing Strike
	var/obj/effect/proc_holder/spell/pointed/piercing_strike/strike_spell

/atom/movable/screen/alert/status_effect/will_of_humanity
	name = "Will of Humanity"
	desc = "You carry the Will of Humanity! You can spread hope and strike down those who threaten humanity."
	icon_state = "crucible"

/datum/status_effect/will_of_humanity/on_creation(mob/living/new_owner, obj/item/coreflame/coreflame)
	. = ..()
	if(.)
		coreflame_item = coreflame

/datum/status_effect/will_of_humanity/on_apply()
	. = ..()
	if(!.)
		return

	// Remove awe_struck if present
	owner.remove_status_effect(/datum/status_effect/awe_struck)

	// Add visual overlay
	will_overlay = mutable_appearance('icons/effects/effects.dmi', "blessed", ABOVE_MOB_LAYER)
	owner.add_overlay(will_overlay)
	owner.color = "#b3a400"

	// Grant ability actions
	hope_action = new(owner)
	hope_action.Grant(owner)

	// Grant spell
	strike_spell = new(owner)
	owner.AddSpell(strike_spell)

	to_chat(owner, span_userdanger("You are now the Will of Humanity! Use your abilities to save everyone!"))
	return TRUE

/datum/status_effect/will_of_humanity/on_remove()

	// Remove visual overlay
	if(will_overlay)
		owner.cut_overlay(will_overlay)
		QDEL_NULL(will_overlay)

	// Remove actions
	if(hope_action)
		hope_action.Remove(owner)
		QDEL_NULL(hope_action)

	// Remove spell
	if(strike_spell)
		owner.RemoveSpell(strike_spell)

	// Drop the Coreflame if still held
	if(coreflame_item && !QDELETED(coreflame_item))
		owner.dropItemToGround(coreflame_item)

	to_chat(owner, span_warning("The Will of Humanity has left you..."))
	return ..()

/datum/status_effect/will_of_humanity/tick()
	// Check if still holding the Coreflame
	if(!coreflame_item || QDELETED(coreflame_item))
		qdel(src)
		return

	// Check if Coreflame is still in inventory
	var/holding_coreflame = FALSE
	for(var/obj/item/I in owner.get_contents())
		if(I == coreflame_item)
			holding_coreflame = TRUE
			break

	if(!holding_coreflame)
		qdel(src)
		return
