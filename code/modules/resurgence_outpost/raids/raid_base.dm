/**
 * Resurgence Outpost - Base Raid Datum
 *
 * Base datum for raid events. Handles spawning, tracking, and lifecycle management.
 */

/datum/resurgence_raid
	/// Display name for this raid
	var/name = "Unknown Raid"

	/// Type of raid (RAID_TYPE_* constant)
	var/raid_type = RAID_TYPE_BASIC

	/// Faction ID that is attacking
	var/faction_id = "insurgence_clan"

	/// Reference to the trading faction datum (if any)
	var/datum/trading_faction/source_faction

	/// List of all raiders spawned for this raid
	var/list/mob/living/raiders = list()

	/// Initial count of raiders (for calculating casualties)
	var/initial_raider_count = 0

	/// List of spawn points being used
	var/list/spawn_points = list()

	/// List of target rooms
	var/list/area/target_rooms = list()

	/// Current state of the raid
	var/raid_state = RAID_STATE_PENDING

	/// Time when the raid was created
	var/created_time = 0

	/// Delay before raiders spawn (for warnings)
	var/spawn_delay = RAID_WARNING_TIME

	/// Delay before raiders attack (for delayed raids)
	var/attack_delay = 0

	/// Maximum number of raiders
	var/max_raiders = 5

	/// Difficulty multiplier
	var/difficulty = 1.0

	/// Timer handle for raid progression
	var/raid_timer

	/// Whether the raid has sent its warning
	var/warning_sent = FALSE

/datum/resurgence_raid/New(faction_id_arg, raid_type_arg)
	. = ..()
	if(faction_id_arg)
		faction_id = faction_id_arg
	if(raid_type_arg)
		raid_type = raid_type_arg

	created_time = world.time

	// Try to get the faction reference
	source_faction = GLOB.resurgence_trading?.get_faction(faction_id)

	// Set raid name based on type and faction
	name = "[get_faction_display_name()] [get_raid_type_name()]"

/**
 * Get display name for the attacking faction.
 */
/datum/resurgence_raid/proc/get_faction_display_name()
	if(source_faction)
		return source_faction.name
	switch(faction_id)
		if("insurgence_clan")
			return "Insurgence Clan"
	return "Unknown Faction"

/**
 * Get display name for the raid type.
 */
/datum/resurgence_raid/proc/get_raid_type_name()
	switch(raid_type)
		if(RAID_TYPE_DELAYED)
			return "Delayed Assault"
		if(RAID_TYPE_BASIC)
			return "Raid"
		if(RAID_TYPE_PILLAGE)
			return "Pillage Raid"
		if(RAID_TYPE_SIEGE)
			return "Siege"
		if(RAID_TYPE_ASSASSINATION)
			return "Assassination Squad"
		if(RAID_TYPE_OVERWHELMING)
			return "Overwhelming Force"
	return "Attack"

/**
 * Start the raid - sends warning and schedules spawning.
 */
/datum/resurgence_raid/proc/start_raid()
	if(raid_state != RAID_STATE_PENDING)
		return FALSE

	// Find spawn points for this faction
	spawn_points = get_raid_spawn_points_for_faction(faction_id)
	if(!spawn_points.len)
		// No spawn points - try getting all spawn points as fallback
		spawn_points = get_all_raid_spawn_points()
		if(!spawn_points.len)
			log_admin("RAID ERROR: No spawn points found for [name]")
			return FALSE

	// Find target rooms
	target_rooms = select_target_rooms()
	if(!target_rooms.len)
		log_admin("RAID WARNING: No target rooms found for [name], raiders will roam")

	// Calculate difficulty and raiders
	calculate_difficulty()
	max_raiders = calculate_raider_count()

	// Send warning
	send_warning()
	warning_sent = TRUE

	// Schedule spawning
	raid_timer = addtimer(CALLBACK(src, PROC_REF(spawn_raiders)), spawn_delay, TIMER_STOPPABLE)

	return TRUE

/**
 * Calculate raid difficulty based on game state.
 * Used for scaling non-raider-count aspects of the raid.
 */
/datum/resurgence_raid/proc/calculate_difficulty()
	difficulty = 1.0

	// Count resurgence machine players
	var/player_count = get_resurgence_player_count()

	// Scale with time (more difficult as round progresses)
	// +0.1 difficulty per 10 minutes, up to +1.0 at 100 minutes
	var/time_factor = min(world.time / (10 MINUTES), 10.0)
	difficulty += time_factor * 0.1

	// Scale with player count (after base 5)
	if(player_count > 5)
		difficulty += (player_count - 5) * 0.1

	// Clamp difficulty
	difficulty = clamp(difficulty, 0.5, 3.0)

/**
 * Calculate number of raiders to spawn.
 * Min 4 raiders, +0.35 per player after 5 people, rounded down.
 * Also scales with round time.
 */
/datum/resurgence_raid/proc/calculate_raider_count()
	var/base_raiders = 4

	// Count resurgence machine players
	var/player_count = get_resurgence_player_count()

	// Add 0.35 raiders per player after 5, rounded down
	if(player_count > 5)
		base_raiders += floor((player_count - 5) * 0.35)

	// Scale with round time: +1 raider per 15 minutes, up to +4 at 60 minutes
	var/time_bonus = floor(min(world.time / (15 MINUTES), 4.0))
	base_raiders += time_bonus

	// Raid type modifiers
	switch(raid_type)
		if(RAID_TYPE_OVERWHELMING)
			base_raiders = round(base_raiders * 1.5)
		if(RAID_TYPE_ASSASSINATION)
			base_raiders = max(3, round(base_raiders * 0.6))

	return clamp(base_raiders, 4, 20)

/**
 * Get the count of alive resurgence machine players.
 */
/datum/resurgence_raid/proc/get_resurgence_player_count()
	var/count = 0
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			count++
	return count

/**
 * Select target rooms for the raid based on type.
 */
/datum/resurgence_raid/proc/select_target_rooms()
	log_admin("RAID DEBUG: [name] selecting target rooms...")
	// Check if any mob type in composition can smash walls
	var/can_smash = check_raid_can_smash_walls()

	// Get accessible rooms
	var/list/all_rooms = get_resurgence_room_areas(TRUE, can_smash)
	log_admin("RAID DEBUG: Found [all_rooms.len] accessible rooms (can_smash_walls: [can_smash])")
	if(!all_rooms.len)
		log_admin("RAID DEBUG: No accessible rooms found - raiders will have no valid targets!")
		return list()

	// Get preferred room types for this raid type
	var/list/preferred_types = GLOB.raid_type_room_preferences[raid_type]
	var/list/targets = list()

	// First try to find preferred room types
	if(preferred_types?.len)
		for(var/area/resurgence_outpost/room/R in all_rooms)
			if(R.room_type in preferred_types)
				targets += R

	// If no preferred rooms, use priority weights
	if(!targets.len)
		for(var/area/resurgence_outpost/room/R in all_rooms)
			var/priority = GLOB.raid_room_priorities[R.room_type] || 1
			for(var/i in 1 to priority)
				targets += R

	// Pick 1-3 target rooms
	var/num_targets = clamp(rand(1, 3), 1, targets.len)
	var/list/final_targets = list()
	for(var/i in 1 to num_targets)
		if(!targets.len)
			break
		final_targets += pick_n_take(targets)

	// Log selected rooms
	var/list/room_names = list()
	for(var/area/resurgence_outpost/room/R in final_targets)
		room_names += R.name
	log_admin("RAID DEBUG: Selected [final_targets.len] target rooms: [room_names.Join(", ")]")

	return final_targets

/**
 * Check if any mob in the raid composition can smash walls.
 */
/datum/resurgence_raid/proc/check_raid_can_smash_walls()
	var/list/composition = get_raid_composition()
	for(var/mob_type in composition)
		// Check the mob type's default environment_smash
		var/mob/living/simple_animal/hostile/temp = new mob_type()
		var/can_smash = (temp.environment_smash & ENVIRONMENT_SMASH_WALLS)
		qdel(temp)
		if(can_smash)
			return TRUE
	return FALSE

/**
 * Get the mob composition for this raid.
 */
/datum/resurgence_raid/proc/get_raid_composition()
	// Get base composition from global list
	var/list/base_comp = GLOB.insurgence_raid_compositions[raid_type]
	if(!base_comp)
		base_comp = GLOB.insurgence_raid_compositions[RAID_TYPE_BASIC]

	return base_comp.Copy()

/**
 * Send warning to all resurgence players.
 */
/datum/resurgence_raid/proc/send_warning()
	var/warning_message = get_warning_message()

	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(!H.mind)
			continue
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			to_chat(H, span_userdanger("[warning_message]"))
			SEND_SOUND(H, sound('sound/effects/ordeals/azure_end.ogg'))

/**
 * Get the warning message for this raid.
 */
/datum/resurgence_raid/proc/get_warning_message()
	switch(raid_type)
		if(RAID_TYPE_ASSASSINATION)
			return "Your faith core trembles... Assassins approach the outpost!"
		if(RAID_TYPE_SIEGE)
			return "Your faith core trembles... A siege force is inbound!"
		if(RAID_TYPE_PILLAGE)
			return "Your faith core trembles... Looters are approaching!"
		if(RAID_TYPE_OVERWHELMING)
			return "Your faith core trembles... A massive force approaches!"
	return "Your faith core trembles... Raiders are approaching the outpost!"

/**
 * Spawn all raiders for this raid.
 */
/datum/resurgence_raid/proc/spawn_raiders()
	raid_state = RAID_STATE_SPAWNING

	var/list/composition = get_raid_composition()
	var/raiders_to_spawn = max_raiders

	// Calculate how many of each type to spawn
	var/total_in_comp = 0
	for(var/mob_type in composition)
		total_in_comp += composition[mob_type]

	if(total_in_comp <= 0)
		log_admin("RAID ERROR: Empty composition for [name]")
		end_raid(FALSE)
		return

	// Spawn proportionally
	for(var/mob_type in composition)
		var/count = round((composition[mob_type] / total_in_comp) * raiders_to_spawn)
		count = max(1, count)

		for(var/i in 1 to count)
			if(raiders.len >= raiders_to_spawn)
				break
			spawn_single_raider(mob_type)

	initial_raider_count = raiders.len

	// If delayed raid, wait before attacking
	if(raid_type == RAID_TYPE_DELAYED)
		raid_state = RAID_STATE_WAITING
		raid_timer = addtimer(CALLBACK(src, PROC_REF(begin_attack)), RAID_DELAYED_WAIT_TIME, TIMER_STOPPABLE)
	else
		begin_attack()

/**
 * Spawn a single raider of the specified type.
 */
/datum/resurgence_raid/proc/spawn_single_raider(mob_type)
	if(!spawn_points.len)
		log_admin("RAID DEBUG: spawn_single_raider() failed - no spawn points")
		return null

	var/obj/effect/landmark/raid_spawn/spawn_point = pick(spawn_points)
	var/turf/spawn_loc = get_turf(spawn_point)
	if(!spawn_loc)
		log_admin("RAID DEBUG: spawn_single_raider() failed - could not get spawn location turf")
		return null

	// Create the mob
	var/mob/living/simple_animal/hostile/M = new mob_type(spawn_loc)
	M.dir = spawn_point.spawn_dir

	// Add to raiders list
	raiders += M

	// Determine target
	var/atom/target = null
	if(target_rooms.len)
		var/area/resurgence_outpost/room/target_room = pick(target_rooms)
		target = get_random_turf_in_room(target_room)
		log_admin("RAID DEBUG: Raider [M.type] assigned to room [target_room.name], target turf: [target ? AREACOORD(target) : "NULL"]")
	if(!target)
		target = spawn_loc
		log_admin("RAID DEBUG: Raider [M.type] has NO target room - defaulting to spawn location (will not move!)")

	// Add raider component
	// For delayed raids, raiders wait at spawn until begin_attack() is called
	var/should_wait = (raid_type == RAID_TYPE_DELAYED)
	var/component_type = get_raider_component_type()
	M.AddComponent(component_type, src, target, spawn_point, should_wait)

	log_admin("RAID DEBUG: Spawned [M.type] at [AREACOORD(spawn_loc)], waiting: [should_wait]")
	return M

/**
 * Get the appropriate raider component type for this raid.
 */
/datum/resurgence_raid/proc/get_raider_component_type()
	if(raid_type == RAID_TYPE_PILLAGE)
		return /datum/component/raider/pillager
	return /datum/component/raider

/**
 * Begin the actual attack phase.
 */
/datum/resurgence_raid/proc/begin_attack()
	raid_state = RAID_STATE_ACTIVE

	// Notify players
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(!H.mind)
			continue
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			to_chat(H, span_danger("The [get_faction_display_name()] raiders are attacking!"))

	// Start attack for all raiders (calculates A* paths)
	for(var/mob/living/simple_animal/hostile/M in raiders)
		if(M.stat == DEAD)
			continue
		var/datum/component/raider/comp = M.GetComponent(/datum/component/raider)
		if(comp)
			// Clear waiting flag first (for delayed raids)
			comp.start_attack()
			// Then assign a target room (this will calculate A* path and start movement)
			if(target_rooms.len)
				var/area/resurgence_outpost/room/target_room = pick(target_rooms)
				comp.assign_room_target(target_room)

/**
 * Called when a raider is removed (dies or deleted).
 */
/datum/resurgence_raid/proc/on_raider_removed(mob/living/raider)
	raiders -= raider

	// Check for retreat condition
	if(initial_raider_count > 0 && raid_state == RAID_STATE_ACTIVE)
		var/alive_count = get_alive_raider_count()
		var/casualty_rate = 1.0 - (alive_count / initial_raider_count)

		if(casualty_rate >= RAID_RETREAT_THRESHOLD)
			begin_retreat()
			return

	// Check if all looters are gone - support troops should retreat
	if(get_alive_looter_count() <= 0 && get_alive_raider_count() > 0)
		log_admin("RAID: All looters eliminated - support troops retreating")
		retreat_support_troops(TRUE) // TRUE = players won (looters died)
		return

	// Check for raid end
	if(get_alive_raider_count() <= 0)
		end_raid(TRUE)

/**
 * Called when a raider successfully escapes with loot.
 */
/datum/resurgence_raid/proc/on_raider_escaped(mob/living/raider)
	raiders -= raider
	log_admin("RAID: Raider [raider?.type] escaped with loot. [get_alive_raider_count()] raiders remaining.")

	// Check if all looters escaped - support troops should retreat
	if(get_alive_looter_count() <= 0 && get_alive_raider_count() > 0)
		log_admin("RAID: All looters escaped - support troops retreating")
		retreat_support_troops(FALSE) // FALSE = players lost (looters escaped)
		return

	// Check for raid end - all raiders escaped or dead
	if(get_alive_raider_count() <= 0)
		// Raiders escaped successfully - this is a loss for the players
		end_raid(FALSE)

/**
 * Get the count of alive raiders (all mobs in raid).
 */
/datum/resurgence_raid/proc/get_alive_raider_count()
	var/count = 0
	for(var/mob/living/M in raiders)
		if(M.stat != DEAD)
			count++
	return count

/**
 * Get the count of alive looters (actual raider subtypes that can steal).
 */
/datum/resurgence_raid/proc/get_alive_looter_count()
	var/count = 0
	for(var/mob/living/M in raiders)
		if(M.stat != DEAD && istype(M, /mob/living/simple_animal/hostile/clan/raider))
			count++
	return count

/**
 * Teleport away all support troops (non-looter mobs).
 *
 * Arguments:
 * * victory - TRUE if players won (looters killed), FALSE if looters escaped
 */
/datum/resurgence_raid/proc/retreat_support_troops(victory = FALSE)
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(!H.mind)
			continue
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			to_chat(H, span_notice("The remaining raiders are retreating!"))

	// Teleport away all non-raider mobs
	for(var/mob/living/simple_animal/hostile/M in raiders)
		if(M.stat == DEAD)
			continue
		// Skip actual raider types - they handle their own retreat
		if(istype(M, /mob/living/simple_animal/hostile/clan/raider))
			continue
		// Teleport away support troops
		M.visible_message(span_warning("[M] vanishes!"))
		playsound(M, 'sound/effects/ordeals/white/pale_teleport_out.ogg', 25, TRUE)
		new /obj/effect/temp_visual/beam_out(get_turf(M))
		qdel(M)

	// End the raid
	end_raid(victory)

/**
 * Begin retreat for all raiders.
 */
/datum/resurgence_raid/proc/begin_retreat()
	if(raid_state == RAID_STATE_RETREATING)
		return

	raid_state = RAID_STATE_RETREATING

	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(!H.mind)
			continue
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			to_chat(H, span_notice("The raiders are retreating!"))

	for(var/mob/living/simple_animal/hostile/M in raiders)
		if(M.stat == DEAD)
			continue
		var/datum/component/raider/comp = M.GetComponent(/datum/component/raider)
		if(comp)
			comp.begin_retreat()

	// End raid after retreat time
	raid_timer = addtimer(CALLBACK(src, PROC_REF(end_raid), TRUE), 2 MINUTES, TIMER_STOPPABLE)

/**
 * End the raid.
 *
 * Arguments:
 * * victory - TRUE if players won (killed all raiders), FALSE otherwise
 */
/datum/resurgence_raid/proc/end_raid(victory = FALSE)
	raid_state = RAID_STATE_COMPLETE

	if(raid_timer)
		deltimer(raid_timer)

	// Clean up remaining raiders
	for(var/mob/living/simple_animal/hostile/M in raiders)
		if(M.stat != DEAD)
			// Teleport away
			new /obj/effect/temp_visual/beam_out(get_turf(M))
			playsound(M, 'sound/effects/ordeals/white/pale_teleport_out.ogg', 25, TRUE)
			qdel(M)

	raiders.Cut()

	// Clear the global crate looting list for the next raid
	GLOB.raid_looted_crates.Cut()

	// Notify players
	var/result_message = victory ? "The raid has been repelled!" : "The raiders have achieved their objective!"
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(!H.mind)
			continue
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			to_chat(H, victory ? span_notice(result_message) : span_danger(result_message))

	// Update faction reputation based on outcome
	if(source_faction)
		if(victory)
			// Small rep increase for defending
			source_faction.adjust_reputation(5)
		// No penalty for losing - reputation was already low

	// Log the result
	log_admin("RAID: [name] ended. Victory: [victory]. Raiders killed: [initial_raider_count - get_alive_raider_count()]/[initial_raider_count]")

/datum/resurgence_raid/Destroy()
	if(raid_timer)
		deltimer(raid_timer)

	// Clean up raiders
	for(var/mob/living/M in raiders)
		qdel(M)
	raiders.Cut()

	source_faction = null
	spawn_points.Cut()
	target_rooms.Cut()

	return ..()
