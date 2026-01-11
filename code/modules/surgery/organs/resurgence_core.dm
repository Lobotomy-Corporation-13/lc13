/**
 * Resurgence Core - The mechanical heart of Resurgence Machines
 *
 * Manages Faith as the core resource.
 * Faith changes over time based on active faith events.
 *
 * Faith levels:
 * - 80-100 (Inspired): High morale bonus
 * - 60-79 (Steady): Good morale
 * - 40-59 (Neutral): Normal operation
 * - 20-39 (Wavering): Low morale
 * - 0-19 (Despairing): Movement penalty, work restricted
 *
 * NOTE: Charge system is disabled but code preserved for potential future use.
 */

/obj/item/organ/resurgence_core
	name = "mechanical core"
	desc = "A complex mechanical core that powers a resurgence machine, managing their faith."
	icon = 'icons/obj/assemblies/new_assemblies.dmi'
	icon_state = "rawcore_bluespace"
	zone = BODY_ZONE_CHEST
	slot = ORGAN_SLOT_HEART
	organ_flags = ORGAN_SYNTHETIC
	actions_types = list(/datum/action/item_action/organ_action/resurgence_check)

	// Charge variables (DISABLED - kept for potential future use)
	// var/charge = 100
	// var/max_charge = 100
	// var/charge_decay_rate = 0.5 // per life tick (every 2 seconds)

	// Faith variables
	var/faith = 50 // Current faith level
	var/max_faith = 100
	var/list/faith_events = list() // category -> /datum/faith_event
	var/faith_change_rate = 0 // Net faith change per 5 seconds (calculated from events)

	// Internal tracking
	// var/charge_tick_counter = 0 // Track ticks for charge decay messages (DISABLED)
	var/faith_tick_counter = 0 // Track ticks for faith updates (every 5 seconds)
	var/companion_tick_counter = 0 // Track ticks for nearby companion checks (every ~10 seconds)
	// var/room_quality_tick_counter = 0 // DISABLED - room quality now uses area enter/exit signals

	// Character stats (1-20)
	var/stat_crafting = 1
	var/stat_mining = 1
	var/stat_harvesting = 1
	var/stat_cooking = 1
	var/stat_analysis = 1
	var/stat_social = 1

	// XP accumulation (resets to 0 after level up)
	var/xp_crafting = 0
	var/xp_mining = 0
	var/xp_harvesting = 0
	var/xp_cooking = 0
	var/xp_analysis = 0
	var/xp_social = 0

	// Personalization System
	/// Passions datum tracking XP bonuses
	var/datum/resurgence_passions/passions = null
	/// List of applied trait datums
	var/list/applied_traits = list()

	/// Accelerated Crafting Protocol - whether the action has been granted
	var/acceleration_action_granted = FALSE
	/// Accelerated Crafting Protocol - whether the mode is currently active
	var/acceleration_active = FALSE

/obj/item/organ/resurgence_core/Destroy()
	// Clean up all faith events
	for(var/category in faith_events)
		var/datum/faith_event/event = faith_events[category]
		event.parent_core = null
		qdel(event)
	faith_events.Cut()

	// Clean up personalization
	if(passions)
		qdel(passions)
		passions = null
	for(var/datum/resurgence_trait/T in applied_traits)
		T.remove()
		qdel(T)
	applied_traits.Cut()

	return ..()

/obj/item/organ/resurgence_core/Insert(mob/living/carbon/M, special, drop_if_replaced)
	. = ..()
	// Show the faith HUD when core is inserted
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.hud_used?.faith_display)
			H.hud_used.faith_display.show_display()
			H.update_faith_hud()

		// Register for login to check room ownership
		RegisterSignal(H, COMSIG_MOB_LOGIN, PROC_REF(on_owner_login))

		// Register for area enter/exit to track room quality
		RegisterSignal(H, COMSIG_ENTER_AREA, PROC_REF(on_area_entered))
		RegisterSignal(H, COMSIG_EXIT_AREA, PROC_REF(on_area_exited))

		// Register for death to clean up
		RegisterSignal(H, COMSIG_LIVING_DEATH, PROC_REF(on_owner_death))

		// Check room ownership now if player is already logged in
		if(H.ckey)
			check_room_ownership()

		// Check current room quality immediately
		check_room_quality()

/obj/item/organ/resurgence_core/Remove(mob/living/carbon/M, special)
	// Hide the faith HUD when core is removed
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.hud_used?.faith_display)
			H.hud_used.faith_display.hide_display()
		// Unregister signals
		UnregisterSignal(H, COMSIG_MOB_LOGIN)
		UnregisterSignal(H, COMSIG_ENTER_AREA)
		UnregisterSignal(H, COMSIG_EXIT_AREA)
		UnregisterSignal(H, COMSIG_LIVING_DEATH)
	// Clear room quality events
	clear_faith_event("room_quality")
	clear_faith_event("room_cramped")
	clear_faith_event("room_dirt_floor")
	return ..()

/obj/item/organ/resurgence_core/on_life()
	..()
	if(!owner || owner.stat == DEAD)
		return

	// CHARGE DECAY DISABLED - Code preserved for potential future use
	// var/decay_modifier = get_faith_decay_modifier()
	// var/actual_decay = charge_decay_rate * decay_modifier
	// adjust_charge(-actual_decay)

	// Track ticks for periodic messages
	// charge_tick_counter++ // DISABLED
	faith_tick_counter++

	// Apply faith changes every 5 seconds (~2-3 life ticks)
	if(faith_tick_counter >= 3) // 3 ticks * ~2 seconds = ~6 seconds (close to 5)
		faith_tick_counter = 0
		apply_faith_changes()

	// Check for nearby companions every ~10 seconds (5 ticks)
	companion_tick_counter++
	if(companion_tick_counter >= 5)
		companion_tick_counter = 0
		check_nearby_companions()

	// Room quality is now checked via area enter/exit signals, not periodic ticks

	// CHARGE WARNING DISABLED - Code preserved for potential future use
	// if(charge_tick_counter >= 30)
	// 	charge_tick_counter = 0
	// 	if(charge < 30)
	// 		add_faith_event("charge_anxiety", new /datum/faith_event/charge_anxiety(
	// 			"Low charge is causing anxiety.",
	// 			-1,
	// 			null,
	// 			"charge_anxiety"
	// 		))
	// 		if(prob(20))
	// 			to_chat(owner, span_warning("Your charge is running low... You need to recharge soon."))
	// 	else
	// 		clear_faith_event("charge_anxiety")

	// Apply movement penalty for low faith
	if(faith < 20)
		owner.add_movespeed_modifier(/datum/movespeed_modifier/resurgence_low_faith)
		if(prob(3))
			to_chat(owner, span_warning("Your faith is nearly depleted... Everything feels hopeless."))
	else
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/resurgence_low_faith)

	// CRITICAL CHARGE DISABLED - Code preserved for potential future use
	// if(charge <= 0)
	// 	to_chat(owner, span_danger("Your core is completely drained! Find power immediately!"))
	// 	owner.adjustOxyLoss(5)

	// Update faith HUD display
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.update_faith_hud()

// ============================================
// Charge Management (DISABLED - preserved for future use)
// ============================================
/*
/obj/item/organ/resurgence_core/proc/adjust_charge(amount)
	charge = clamp(charge + amount, 0, max_charge)

/obj/item/organ/resurgence_core/proc/can_use_charge(amount)
	return charge >= amount

/obj/item/organ/resurgence_core/proc/use_charge(amount)
	if(can_use_charge(amount))
		adjust_charge(-amount)
		return TRUE
	return FALSE

/// Restore charge from an external source (battery, charger, etc.)
/obj/item/organ/resurgence_core/proc/restore_charge(amount)
	var/old_charge = charge
	adjust_charge(amount)
	var/restored = charge - old_charge
	if(restored > 0 && owner)
		// Add sustenance faith event for recharging (temporary boost)
		add_faith_event("sustenance", new /datum/faith_event/sustenance(
			"Recently recharged.",
			1, // Gain 1 faith per 5 seconds for duration
			3 MINUTES,
			"sustenance"
		))
	return restored
*/

// ============================================
// Faith Management
// ============================================

/// Directly adjust faith value (for work drain, bypasses events)
/obj/item/organ/resurgence_core/proc/adjust_faith(amount)
	faith = clamp(faith + amount, 0, max_faith)

/// Apply faith changes from all active events
/obj/item/organ/resurgence_core/proc/apply_faith_changes()
	recalculate_faith_rate()
	if(faith_change_rate != 0)
		var/effective_rate = faith_change_rate
		// Apply global event faith regen modifier (affects positive changes only)
		if(faith_change_rate > 0)
			effective_rate *= GLOB.resurgence_faith_regen_modifier
		else
			// Apply trait modifier for negative faith changes (Iron-Willed, Sickly, Too Smart)
			if(owner && ishuman(owner))
				effective_rate *= get_trait_faith_loss_modifier(owner)
		faith = clamp(faith + effective_rate, 0, max_faith)

/// Add a faith event, replacing any existing event in the same category
/obj/item/organ/resurgence_core/proc/add_faith_event(category, datum/faith_event/event)
	if(!event)
		return FALSE

	// Replace existing event in same category
	if(faith_events[category])
		var/datum/faith_event/old_event = faith_events[category]
		old_event.parent_core = null
		qdel(old_event)

	faith_events[category] = event
	event.set_parent(src)
	recalculate_faith_rate()
	return TRUE

/// Clear a faith event by category
/obj/item/organ/resurgence_core/proc/clear_faith_event(category)
	if(!faith_events[category])
		return FALSE

	var/datum/faith_event/event = faith_events[category]
	event.parent_core = null
	qdel(event)
	faith_events -= category
	recalculate_faith_rate()
	return TRUE

/// Called when a faith event is deleted (timer expiry, etc.)
/obj/item/organ/resurgence_core/proc/on_faith_event_deleted(datum/faith_event/event)
	for(var/category in faith_events)
		if(faith_events[category] == event)
			faith_events -= category
			break
	recalculate_faith_rate()

/// Recalculate the net faith change rate from all active events
/obj/item/organ/resurgence_core/proc/recalculate_faith_rate()
	faith_change_rate = 0
	for(var/category in faith_events)
		var/datum/faith_event/event = faith_events[category]
		if(event)
			faith_change_rate += event.faith_change

// ============================================
// Character Stats & XP
// ============================================

/**
 * Award XP to a specific stat and handle level ups.
 *
 * Arguments:
 * * stat_type - "crafting", "mining", "harvesting", or "cooking"
 * * amount - Amount of XP to award
 */
/obj/item/organ/resurgence_core/proc/award_xp(stat_type, amount)
	if(amount <= 0)
		return

	// Apply trait XP modifier (Quick Learner, Slow Learner, Too Smart)
	if(owner && ishuman(owner))
		var/trait_modifier = get_trait_xp_modifier(owner)
		amount *= trait_modifier

	// Apply passion bonus
	if(passions)
		amount *= passions.get_xp_multiplier(stat_type)

	var/current_level
	var/current_xp

	switch(stat_type)
		if("crafting")
			current_level = stat_crafting
			current_xp = xp_crafting
		if("mining")
			current_level = stat_mining
			current_xp = xp_mining
		if("harvesting")
			current_level = stat_harvesting
			current_xp = xp_harvesting
		if("cooking")
			current_level = stat_cooking
			current_xp = xp_cooking
		if("analysis")
			current_level = stat_analysis
			current_xp = xp_analysis
		if("social")
			current_level = stat_social
			current_xp = xp_social
		else
			return // Invalid stat type

	// Check if already at max level
	if(current_level >= STAT_MAX_LEVEL)
		return

	// Add XP
	current_xp += amount
	var/xp_needed = get_xp_for_level(current_level)

	// Check for level up
	while(current_xp >= xp_needed && current_level < STAT_MAX_LEVEL)
		current_xp -= xp_needed
		current_level++
		if(owner)
			to_chat(owner, span_notice("<b>Your [stat_type] skill has increased to level [current_level]!</b>"))
		xp_needed = get_xp_for_level(current_level)

	// Store the updated values
	switch(stat_type)
		if("crafting")
			stat_crafting = current_level
			xp_crafting = current_xp
		if("mining")
			stat_mining = current_level
			xp_mining = current_xp
		if("harvesting")
			stat_harvesting = current_level
			xp_harvesting = current_xp
		if("cooking")
			stat_cooking = current_level
			xp_cooking = current_xp
		if("analysis")
			stat_analysis = current_level
			xp_analysis = current_xp
		if("social")
			stat_social = current_level
			xp_social = current_xp

/// Get the current level of a stat
/obj/item/organ/resurgence_core/proc/get_stat_level(stat_type)
	switch(stat_type)
		if("crafting")
			return stat_crafting
		if("mining")
			return stat_mining
		if("harvesting")
			return stat_harvesting
		if("cooking")
			return stat_cooking
		if("analysis")
			return stat_analysis
		if("social")
			return stat_social
	return 1

/// Get the current XP of a stat
/obj/item/organ/resurgence_core/proc/get_stat_xp(stat_type)
	switch(stat_type)
		if("crafting")
			return xp_crafting
		if("mining")
			return xp_mining
		if("harvesting")
			return xp_harvesting
		if("cooking")
			return xp_cooking
		if("analysis")
			return xp_analysis
		if("social")
			return xp_social
	return 0

// ============================================
// Room Ownership & Quality
// ============================================

/// Called when the owner logs in
/obj/item/organ/resurgence_core/proc/on_owner_login(datum/source)
	SIGNAL_HANDLER
	check_room_ownership()

/// Called when the owner enters a new area
/obj/item/organ/resurgence_core/proc/on_area_entered(datum/source, area/new_area)
	SIGNAL_HANDLER
	// Check room quality when entering any area
	check_room_quality()

/// Called when the owner exits an area
/obj/item/organ/resurgence_core/proc/on_area_exited(datum/source, area/old_area)
	SIGNAL_HANDLER
	// Room quality will be updated by the subsequent ENTER_AREA signal
	// But we clear immediately if leaving a resurgence room
	if(istype(old_area, /area/resurgence_outpost/room))
		clear_faith_event("room_quality")
		clear_faith_event("room_cramped")
		clear_faith_event("room_dirt_floor")

/// Called when the owner dies - clean up faith events and effects
/obj/item/organ/resurgence_core/proc/on_owner_death(datum/source, gibbed)
	SIGNAL_HANDLER

	// Clear all faith events on death
	for(var/category in faith_events)
		clear_faith_event(category)

	// Disable acceleration if active
	if(acceleration_active)
		acceleration_active = FALSE
		if(owner)
			owner.remove_filter("accel_glow")

	// Remove movespeed modifier
	if(owner)
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/resurgence_low_faith)

	log_game("Resurgence core owner [owner] died, cleaning up faith events")

/// Check if owner has a claimed bed and apply appropriate faith event
/obj/item/organ/resurgence_core/proc/check_room_ownership()
	if(!owner || !owner.ckey)
		return

	var/obj/structure/resurgence_bed/owned_bed = GLOB.resurgence_bed_owners[owner.ckey]

	if(owned_bed && !QDELETED(owned_bed))
		// Player has a bed - check room type for appropriate bonus
		var/area/resurgence_outpost/room/room = get_area(owned_bed)
		if(istype(room) && room.room_type == ROOM_TYPE_LIVING_QUARTERS)
			// Living quarters gives faith bonus
			var/datum/faith_event/room_ownership/event = new(
				"You have a personal sleeper.",
				0.025, // +0.025 per tick
				null,
				"room_ownership"
			)
			add_faith_event("room_ownership", event)
		else
			// Barracks just removes homeless penalty
			clear_faith_event("room_ownership")
	else
		// Player has no bed - add homeless event
		var/datum/faith_event/room_ownership/event = new(
			"You have no personal sleeper.",
			-1, // -1 per tick (permanent events should be ≤ ±1 per tick per guidelines)
			null,
			"room_ownership"
		)
		add_faith_event("room_ownership", event)

/// Check room quality and apply faith bonus/penalty (permanent event while in room)
/obj/item/organ/resurgence_core/proc/check_room_quality()
	if(!owner)
		return

	var/area/resurgence_outpost/room/current_room = get_area(owner)
	if(!istype(current_room))
		// Not in a designated room - clear room quality events
		clear_faith_event("room_quality")
		clear_faith_event("room_cramped")
		clear_faith_event("room_dirt_floor")
		return

	// Check for dirt/sand floors - big quality penalty
	var/has_dirt_floor = FALSE
	for(var/turf/T in current_room.contents)
		if(istype(T, /turf/open/floor/plating/dirt/jungle/wasteland) || \
		   istype(T, /turf/open/floor/plating/dirt/dark) || \
		   istype(T, /turf/open/floor/plating/ironsand))
			has_dirt_floor = TRUE
			break

	if(has_dirt_floor)
		var/datum/faith_event/room_quality/dirt_event = new(
			"Dirt floor in the room.",
			-0.8, // Big penalty
			null,
			"room_dirt_floor"
		)
		add_faith_event("room_dirt_floor", dirt_event)
	else
		clear_faith_event("room_dirt_floor")

	// Calculate quality level from resurgence beauty
	// resurgence_beauty is calculated as total_resurgence_beauty / areasize
	var/beauty_level = current_room.resurgence_beauty
	var/faith_change = 0
	var/quality_desc = ""

	if(beauty_level >= ROOM_QUALITY_LUXURIOUS)
		faith_change = 2.5
		quality_desc = "Luxurious surroundings."
	else if(beauty_level >= ROOM_QUALITY_COMFORTABLE)
		faith_change = 1.5
		quality_desc = "Comfortable room."
	else if(beauty_level >= ROOM_QUALITY_ADEQUATE)
		faith_change = 0.5
		quality_desc = "Adequate accommodations."
	else if(beauty_level >= ROOM_QUALITY_BARE)
		// No effect for bare rooms
		clear_faith_event("room_quality")
		faith_change = 0
	else if(beauty_level >= ROOM_QUALITY_SHABBY)
		faith_change = -0.5
		quality_desc = "Shabby surroundings."
	else
		faith_change = -1.5
		quality_desc = "Squalid conditions."

	// Apply room quality event if there's a change
	if(faith_change != 0)
		// Halve the quality bonus for Living Quarters made with sandstone
		if(current_room.is_sandstone && current_room.room_type == ROOM_TYPE_LIVING_QUARTERS && faith_change > 0)
			faith_change *= 0.5
			quality_desc += " (Sandstone construction)"

		// Add room type to description
		quality_desc = "[current_room.room_type]: [quality_desc]"

		var/datum/faith_event/room_quality/event = new(
			quality_desc,
			faith_change,
			null, // Permanent - removed when leaving room via area exit signal
			"room_quality"
		)
		add_faith_event("room_quality", event)

	// Check for cramped room penalty
	check_room_cramped(current_room)

/// Check if room is cramped and apply penalty (permanent event while in room)
/obj/item/organ/resurgence_core/proc/check_room_cramped(area/resurgence_outpost/room/room)
	// Count floor tiles in the room
	var/list/room_turfs = list()
	for(var/turf/T in room.contents)
		if(!isclosedturf(T))
			room_turfs += T

	var/tile_count = room_turfs.len
	var/is_cramped_tiles = (tile_count < ROOM_MIN_TILES)

	// Calculate bounding box for dimension check
	var/min_x = INFINITY
	var/max_x = 0
	var/min_y = INFINITY
	var/max_y = 0

	for(var/turf/T in room_turfs)
		min_x = min(min_x, T.x)
		max_x = max(max_x, T.x)
		min_y = min(min_y, T.y)
		max_y = max(max_y, T.y)

	var/width = max_x - min_x + 1
	var/height = max_y - min_y + 1
	var/is_cramped_dimensions = (width < ROOM_MIN_DIMENSION || height < ROOM_MIN_DIMENSION)

	// Apply cramped penalties (permanent - removed when leaving room)
	if(is_cramped_tiles && is_cramped_dimensions)
		// Both conditions - very cramped
		var/datum/faith_event/room_cramped/event = new(
			"This room is very cramped!",
			-1.6,
			null, // Permanent - removed when leaving room
			"room_cramped"
		)
		add_faith_event("room_cramped", event)
	else if(is_cramped_tiles || is_cramped_dimensions)
		// One condition - cramped
		var/datum/faith_event/room_cramped/event = new(
			"This room feels cramped.",
			-1,
			null, // Permanent - removed when leaving room
			"room_cramped"
		)
		add_faith_event("room_cramped", event)
	else
		clear_faith_event("room_cramped")

/// Check for nearby fellow resurgence machines and apply community bonus
/// Runs every ~10 seconds to minimize performance impact with many players
/obj/item/organ/resurgence_core/proc/check_nearby_companions()
	if(!owner)
		return

	var/companion_count = 0
	// Use view(7) for default view range, with type filtering for efficiency
	for(var/mob/living/carbon/human/H in view(7, owner))
		if(H == owner)
			continue
		if(H.stat == DEAD)
			continue
		// Check if they're a resurgence machine
		if(!istype(H.dna?.species, /datum/species/resurgence_machine))
			continue
		companion_count++
		// Early exit once we've found enough - no need to count all
		if(companion_count >= 2)
			break

	if(companion_count >= 2)
		// Add community bonus for having companions nearby
		var/datum/faith_event/community/event = new(
			"Working alongside fellow machines.",
			0.5, // Small faith bonus per tick
			null, // Permanent while conditions met
			"community"
		)
		add_faith_event("community", event)
	else
		clear_faith_event("community")

// DISABLED - Charge decay modifier (preserved for future use)
// /obj/item/organ/resurgence_core/proc/get_faith_decay_modifier()
// 	if(faith >= 80)
// 		return 0.5  // Inspired - 50% slower decay
// 	if(faith >= 60)
// 		return 0.75 // Steady - 25% slower decay
// 	if(faith >= 40)
// 		return 1.0  // Neutral - normal decay
// 	if(faith >= 20)
// 		return 1.25 // Wavering - 25% faster decay
// 	return 1.5      // Despairing - 50% faster decay

/// Get the name of the current faith level
/obj/item/organ/resurgence_core/proc/get_faith_level_name()
	if(faith >= 80)
		return "Inspired"
	if(faith >= 60)
		return "Steady"
	if(faith >= 40)
		return "Neutral"
	if(faith >= 20)
		return "Wavering"
	return "Despairing"

// ============================================
// EMP Vulnerability
// ============================================

/obj/item/organ/resurgence_core/emp_act(severity)
	. = ..()
	if(!owner)
		return

	// EMPs damage the core and drain faith
	var/trait_modifier = 1.0
	if(ishuman(owner))
		trait_modifier = get_trait_faith_loss_modifier(owner)

	switch(severity)
		if(EMP_LIGHT)
			owner.adjustBruteLoss(10)
			adjust_faith(-10 * trait_modifier)
			to_chat(owner, span_warning("Your core systems are disrupted by the electromagnetic pulse!"))
		if(EMP_HEAVY)
			owner.adjustBruteLoss(20)
			adjust_faith(-20 * trait_modifier)
			owner.Paralyze(20)
			to_chat(owner, span_danger("Your core systems are severely disrupted by the electromagnetic pulse!"))

// ============================================
// Movespeed Modifier
// ============================================

/// Movespeed modifier for low faith (Despairing)
/datum/movespeed_modifier/resurgence_low_faith
	variable = TRUE
	multiplicative_slowdown = 0.3

// ============================================
// Status Check Action
// ============================================

/// Action for checking core status
/datum/action/item_action/organ_action/resurgence_check
	name = "Check Core Status"
	desc = "Check your mechanical core's faith level and status."

/datum/action/item_action/organ_action/resurgence_check/Trigger()
	. = ..()
	if(!istype(target, /obj/item/organ/resurgence_core))
		return

	var/obj/item/organ/resurgence_core/core = target
	if(!core.owner)
		return

	var/mob/living/carbon/human/H = core.owner

	// Make sure the faith display is visible
	if(H.hud_used?.faith_display)
		H.hud_used.faith_display.show_display()
		H.update_faith_hud()

	// Header
	to_chat(H, span_notice("<b>=== Core Status ===</b>"))

	// CHARGE DISPLAY DISABLED - preserved for future use
	// var/charge_percent = round((core.charge / core.max_charge) * 100)
	// var/charge_color = "green"
	// if(charge_percent < 30)
	// 	charge_color = "red"
	// else if(charge_percent < 60)
	// 	charge_color = "orange"
	// to_chat(H, "<span style='color: [charge_color];'>Charge: [round(core.charge)]/[core.max_charge] ([charge_percent]%)</span>")

	// Faith display with level name
	var/faith_level = core.get_faith_level_name()
	var/faith_color
	switch(faith_level)
		if("Inspired")
			faith_color = "green"
		if("Steady")
			faith_color = "blue"
		if("Neutral")
			faith_color = "yellow"
		if("Wavering")
			faith_color = "orange"
		if("Despairing")
			faith_color = "red"

	to_chat(H, "<span style='color: [faith_color];'>Faith: [round(core.faith)]/[core.max_faith] - [faith_level]</span>")

	// Show faith change rate
	var/rate_text
	var/rate_color
	if(core.faith_change_rate > 0)
		rate_text = "Faith is increasing (+[core.faith_change_rate] per 5 sec)"
		rate_color = "green"
	else if(core.faith_change_rate < 0)
		rate_text = "Faith is decreasing ([core.faith_change_rate] per 5 sec)"
		rate_color = "red"
	else
		rate_text = "Faith is stable"
		rate_color = "gray"
	to_chat(H, "<span style='color: [rate_color];'>[rate_text]</span>")

	// DECAY MODIFIER DISPLAY DISABLED - preserved for future use
	// var/decay_mod = core.get_faith_decay_modifier()
	// var/decay_text
	// if(decay_mod < 1)
	// 	decay_text = "Charge decay reduced by [round((1 - decay_mod) * 100)]%"
	// else if(decay_mod > 1)
	// 	decay_text = "Charge decay increased by [round((decay_mod - 1) * 100)]%"
	// else
	// 	decay_text = "Charge decay is normal"
	// to_chat(H, span_notice(decay_text))

	// Show active faith events (non-hidden)
	var/has_events = FALSE
	for(var/category in core.faith_events)
		var/datum/faith_event/event = core.faith_events[category]
		if(event && !event.hidden)
			if(!has_events)
				to_chat(H, span_notice("<b>Active Faith Effects:</b>"))
				has_events = TRUE
			var/sign = event.faith_change >= 0 ? "+" : ""
			var/time_remaining = event.get_time_remaining()
			var/time_text = ""
			if(!isnull(time_remaining))
				if(time_remaining >= 60)
					time_text = " - [round(time_remaining / 60)]m [time_remaining % 60]s left"
				else
					time_text = " - [time_remaining]s left"
			to_chat(H, span_notice("  [event.description] ([sign][event.faith_change] per 5 sec)[time_text]"))

	if(!has_events)
		to_chat(H, span_notice("No special faith effects active."))

	// Show outpost objectives if they exist
	if(length(GLOB.resurgence_objectives))
		display_objectives(H)
	else
		to_chat(H, span_notice("<b>=== OUTPOST OBJECTIVES ===</b>"))
		to_chat(H, span_notice("No objectives active. Use the admin panel to initialize objectives."))

/// Display outpost objectives grouped by category
/datum/action/item_action/organ_action/resurgence_check/proc/display_objectives(mob/living/H)
	to_chat(H, span_notice("<b>=== OUTPOST OBJECTIVES ===</b>"))

	var/phase = GLOB.resurgence_objective_phase

	// Count building objectives
	var/building_complete = 0
	var/building_total = 0
	for(var/datum/resurgence_objective/obj in GLOB.resurgence_objectives)
		if(obj.category == "building")
			building_total++
			if(obj.completed)
				building_complete++

	// Display building objectives
	to_chat(H, span_notice("<b>BUILDING ([building_complete]/[building_total] complete):</b>"))
	for(var/datum/resurgence_objective/obj in GLOB.resurgence_objectives)
		if(obj.category != "building")
			continue
		var/status = obj.completed ? "\[X\]" : "\[ \]"
		var/color = obj.completed ? "green" : "#80C0FF"
		to_chat(H, "<span style='color: [color];'>  [status] [obj.get_display_text()]</span>")

	// Count export objectives
	var/export_complete = 0
	var/export_total = 0
	for(var/datum/resurgence_objective/obj in GLOB.resurgence_objectives)
		if(obj.category == "export")
			export_total++
			if(obj.completed)
				export_complete++

	// Display export objectives
	if(phase < 2)
		to_chat(H, span_notice("<b>EXPORTING (locked until building complete):</b>"))
		to_chat(H, span_notice("  Complete all building objectives to unlock exports."))
	else
		to_chat(H, span_notice("<b>EXPORTING ([export_complete]/[export_total] complete):</b>"))
		for(var/datum/resurgence_objective/obj in GLOB.resurgence_objectives)
			if(obj.category != "export")
				continue
			var/status = obj.completed ? "\[X\]" : "\[ \]"
			var/color = obj.completed ? "green" : "#80C0FF"
			to_chat(H, "<span style='color: [color];'>  [status] [obj.get_display_text()]</span>")

// ============================================
// Accelerated Crafting Protocol
// ============================================

/// Grant the Accelerated Crafting Protocol action to the owner
/obj/item/organ/resurgence_core/proc/grant_acceleration_action()
	if(acceleration_action_granted)
		return FALSE
	if(!owner)
		return FALSE

	var/datum/action/item_action/organ_action/acceleration_protocol/accel_action = new(src)
	accel_action.Grant(owner)
	acceleration_action_granted = TRUE

	to_chat(owner, span_notice("<b>Accelerated Crafting Protocol unlocked!</b> Use the action button to toggle accelerated crafting."))
	return TRUE

/// Remove the Accelerated Crafting Protocol action
/obj/item/organ/resurgence_core/proc/remove_acceleration_action()
	if(!acceleration_action_granted)
		return FALSE

	// Find and remove the action
	for(var/datum/action/item_action/organ_action/acceleration_protocol/A in actions)
		A.Remove(owner)
		qdel(A)

	acceleration_action_granted = FALSE
	// Also disable acceleration if it was active
	if(acceleration_active)
		toggle_acceleration()
	return TRUE

/// Toggle Accelerated Crafting Protocol on/off
/obj/item/organ/resurgence_core/proc/toggle_acceleration()
	acceleration_active = !acceleration_active
	update_acceleration_filter()

	if(acceleration_active)
		to_chat(owner, span_boldwarning("Accelerated Crafting ACTIVATED - 2x crafting speed, 3x faith drain!"))
	else
		to_chat(owner, span_notice("Accelerated Crafting deactivated."))

/// Update the visual filter for acceleration state
/obj/item/organ/resurgence_core/proc/update_acceleration_filter()
	if(!owner)
		return

	if(acceleration_active)
		// Add orange overcharge glow when active
		owner.add_filter("accel_glow", 2, list("type" = "outline", "color" = "#ff660080", "size" = 2))
		// Animate the glow
		var/filter = owner.get_filter("accel_glow")
		if(filter)
			animate(filter, alpha = 180, time = 8, loop = -1)
			animate(alpha = 80, time = 8)
	else
		// Remove the glow when inactive
		owner.remove_filter("accel_glow")

/// Action for toggling Accelerated Crafting Protocol
/datum/action/item_action/organ_action/acceleration_protocol
	name = "Accelerated Crafting"
	desc = "Toggle accelerated crafting mode. Doubles crafting speed but triples faith drain."
	button_icon = 'icons/hud/screen_alert.dmi'
	button_icon_state = "etherealcharge3"

/datum/action/item_action/organ_action/acceleration_protocol/UpdateButtonIcon(status_only, force)
	. = ..()
	if(!istype(target, /obj/item/organ/resurgence_core))
		return
	var/obj/item/organ/resurgence_core/core = target
	// Update icon based on active state
	if(core.acceleration_active)
		button_icon_state = "ethereal_overcharge2"
	else
		button_icon_state = "etherealcharge3"

/datum/action/item_action/organ_action/acceleration_protocol/Trigger()
	. = ..()
	if(!istype(target, /obj/item/organ/resurgence_core))
		return

	var/obj/item/organ/resurgence_core/core = target
	if(!core.owner)
		return

	core.toggle_acceleration()
	UpdateButtonIcon()
