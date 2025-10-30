/// Achiyalabopa - STAR level distortion boss
/mob/living/simple_animal/hostile/distortion/achiyalabopa
	name = "Achiyalabopa"
	desc = "A magnificent golden being of immense power. Its very presence fills you with overwhelming awe."
	icon = 'ModularLobotomy/_Lobotomyicons/bird_achiyalabopa.dmi'
	icon_state = "achiyalabopa"
	icon_living = "achiyalabopa"
	icon_dead = "achiyalabopa_dead"
	maxHealth = 25000
	health = 25000
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
	/// Thunder summoning cooldown
	var/thunder_cooldown = 0
	var/thunder_cooldown_time = 3 SECONDS
	/// AoE attack cooldown
	var/aoe_cooldown = 0
	var/aoe_cooldown_time = 15 SECONDS

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

		// Store reference to remove later
		var/obj/effect/piercing_spear/impaled_spear = spear

		// Set timer to remove spear when vulnerability ends
		addtimer(CALLBACK(src, PROC_REF(RemoveImpaledSpear), impaled_spear), duration)

	// Set timer to restore vulnerability
	addtimer(CALLBACK(src, PROC_REF(RestoreDefenses)), duration)

/// Removes the impaled spear
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/RemoveImpaledSpear(obj/effect/piercing_spear/spear)
	if(spear && !QDELETED(spear))
		animate(spear, alpha = 0, time = 10)
		QDEL_IN(spear, 10)

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

/// Divine Judgment - Multi-wave AoE attack with thick patterns
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/DivineJudgment()
	aoe_cooldown = world.time + aoe_cooldown_time

	visible_message(span_userdanger("[src] raises its wings! Divine judgment descends!"))
	playsound(src, 'sound/magic/clockwork/narsie_attack.ogg', 75, TRUE, 20)

	// Execute 3 waves of attacks
	DivineJudgmentWave(1)

/// Executes a single wave of Divine Judgment
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/DivineJudgmentWave(wave_number)
	if(stat == DEAD)
		return

	// Determine pattern type: first wave is always +, subsequent waves are random
	var/pattern_type = "plus"
	if(wave_number > 1)
		pattern_type = pick("plus", "x")

	// Get danger tiles based on pattern
	var/list/danger_tiles = list()
	if(pattern_type == "plus")
		danger_tiles = GetPlusPattern()
	else
		danger_tiles = GetXPattern()

	// Show warning effects
	for(var/turf/T in danger_tiles)
		new /obj/effect/temp_visual/divine_judgment_warning(T)

	// After 2 seconds, damage all targets in the danger zone
	addtimer(CALLBACK(src, PROC_REF(DivineJudgmentStrike), danger_tiles, wave_number), 2 SECONDS)

/// Generates a thick plus pattern (3 tiles wide, range 7)
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/GetPlusPattern()
	var/list/danger_tiles = list()
	var/turf/center = get_turf(src)

	if(!center)
		return danger_tiles

	// Add center tile
	danger_tiles += center

	// Create thick cross pattern (3 tiles wide)
	for(var/i = 1 to 7)
		// North arm
		for(var/offset = -1 to 1)
			var/turf/T = locate(center.x + offset, center.y + i, center.z)
			if(T)
				danger_tiles += T

		// South arm
		for(var/offset = -1 to 1)
			var/turf/T = locate(center.x + offset, center.y - i, center.z)
			if(T)
				danger_tiles += T

		// East arm
		for(var/offset = -1 to 1)
			var/turf/T = locate(center.x + i, center.y + offset, center.z)
			if(T)
				danger_tiles += T

		// West arm
		for(var/offset = -1 to 1)
			var/turf/T = locate(center.x - i, center.y + offset, center.z)
			if(T)
				danger_tiles += T

	return danger_tiles

/// Generates a thick X pattern (3 tiles wide, range 7)
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/GetXPattern()
	var/list/danger_tiles = list()
	var/turf/center = get_turf(src)

	if(!center)
		return danger_tiles

	// Add center tile
	danger_tiles += center

	// Create thick X pattern (3 tiles wide on diagonals)
	for(var/i = 1 to 7)
		// Northeast diagonal (with thickness)
		for(var/offset = -1 to 1)
			var/turf/T1 = locate(center.x + i + offset, center.y + i, center.z)
			if(T1)
				danger_tiles += T1
			var/turf/T2 = locate(center.x + i, center.y + i + offset, center.z)
			if(T2)
				danger_tiles += T2

		// Northwest diagonal (with thickness)
		for(var/offset = -1 to 1)
			var/turf/T1 = locate(center.x - i + offset, center.y + i, center.z)
			if(T1)
				danger_tiles += T1
			var/turf/T2 = locate(center.x - i, center.y + i + offset, center.z)
			if(T2)
				danger_tiles += T2

		// Southeast diagonal (with thickness)
		for(var/offset = -1 to 1)
			var/turf/T1 = locate(center.x + i + offset, center.y - i, center.z)
			if(T1)
				danger_tiles += T1
			var/turf/T2 = locate(center.x + i, center.y - i + offset, center.z)
			if(T2)
				danger_tiles += T2

		// Southwest diagonal (with thickness)
		for(var/offset = -1 to 1)
			var/turf/T1 = locate(center.x - i + offset, center.y - i, center.z)
			if(T1)
				danger_tiles += T1
			var/turf/T2 = locate(center.x - i, center.y - i + offset, center.z)
			if(T2)
				danger_tiles += T2

	return danger_tiles

/// Executes the Divine Judgment strike
/mob/living/simple_animal/hostile/distortion/achiyalabopa/proc/DivineJudgmentStrike(list/danger_tiles, wave_number)
	if(stat == DEAD)
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

	// Add visual overlay
	hope_overlay = mutable_appearance('icons/effects/effects.dmi', "shield2", ABOVE_MOB_LAYER)
	owner.add_overlay(hope_overlay)

	to_chat(owner, span_nicegreen("You are filled with hope! Nothing can stop you now!"))
	return TRUE

/datum/status_effect/hope/on_remove()

	// Remove visual overlay
	if(hope_overlay)
		owner.cut_overlay(hope_overlay)
		QDEL_NULL(hope_overlay)

	to_chat(owner, span_notice("The feeling of hope fades..."))
	return ..()

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
