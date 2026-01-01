/**
 * Resurgence Outpost - Harvester Tool
 *
 * Automated gathering tool that can be attached to resources to harvest them.
 *
 * Simple Harvester: Attaches to resource, pays faith from player, drops when done.
 * Advanced Harvester: Has faith storage, auto-seeks next target after completion.
 */

// ===== Harvester Mount Structure =====
// This structure holds the harvester while it's working, preventing pickup

/obj/structure/harvester_mount
	name = "harvester mount"
	desc = "A harvester is attached here, working away."
	icon = 'icons/mob/drone.dmi'
	icon_state = "drone_maint_blue"
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE
	/// The harvester we're holding
	var/obj/item/harvester/held_harvester = null

/obj/structure/harvester_mount/Initialize(mapload, obj/item/harvester/H, target_layer)
	. = ..()
	if(H)
		held_harvester = H
		H.forceMove(src)
		// Use the harvester's icon
		icon = H.icon
		icon_state = H.icon_state
	// Set layer 0.1 above the target
	if(target_layer)
		layer = target_layer + 0.1

/obj/structure/harvester_mount/Destroy()
	if(held_harvester && !QDELETED(held_harvester))
		// Drop the harvester on the ground
		held_harvester.forceMove(get_turf(src))
		held_harvester = null
	return ..()

/obj/structure/harvester_mount/examine(mob/user)
	. = ..()
	if(held_harvester)
		. += span_notice("Contains: [held_harvester]")
		// Show harvester's examine info
		. += held_harvester.examine(user)

/obj/structure/harvester_mount/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	to_chat(user, span_warning("The harvester is busy working. Wait for it to finish."))

/// Release the harvester and delete self
/obj/structure/harvester_mount/proc/release_harvester()
	var/obj/item/harvester/H = held_harvester
	var/turf/T = get_turf(src)
	held_harvester = null
	if(H && !QDELETED(H))
		H.forceMove(T)
	qdel(src)
	return H

// ===== Base Harvester =====

/// Base harvester - shared functionality
/obj/item/harvester
	name = "harvester"
	desc = "An automated harvesting device."
	icon = 'icons/mob/drone.dmi'
	icon_state = "drone_maint_blue"
	w_class = WEIGHT_CLASS_SMALL

	/// Currently attached target (tree, ore, cotton, farm plot)
	var/atom/current_target = null
	/// Type of current target for auto-seek matching
	var/target_type = null
	/// Whether currently working
	var/working = FALSE
	/// Work points per tick (same as player base rate)
	var/work_per_tick = GATHER_WORK_PER_TICK
	/// The mount structure holding us while working
	var/obj/structure/harvester_mount/current_mount = null

/obj/item/harvester/Destroy()
	detach_from_target()
	return ..()

/// Check if a target is valid for harvesting
/obj/item/harvester/proc/is_valid_target(atom/target)
	// Trees
	if(istype(target, /obj/structure/resurgence_tree))
		return TRUE
	// Ore deposits (old turf-based)
	if(istype(target, /turf/closed/mineral/resurgence))
		return TRUE
	// Ore deposits (new structure-based)
	if(istype(target, /obj/structure/resurgence_ore_deposit))
		var/obj/structure/resurgence_ore_deposit/O = target
		if(!O.depleted)
			return TRUE
		return FALSE
	// Cotton plants (only if harvestable)
	if(istype(target, /obj/structure/resurgence_cotton))
		var/obj/structure/resurgence_cotton/C = target
		// Check growth stage - cotton is harvestable at stage 4
		if(C.growth_stage == 4) // COTTON_STAGE_HARVEST
			return TRUE
		return FALSE
	// Farm plots (only if ready to harvest)
	if(istype(target, /obj/structure/farm_plot))
		var/obj/structure/farm_plot/F = target
		if(F.harvest && F.myseed)
			return TRUE
		return FALSE
	return FALSE

/// Get the work_needed value from a target
/obj/item/harvester/proc/get_target_work_needed(atom/target)
	if(istype(target, /obj/structure/resurgence_tree))
		var/obj/structure/resurgence_tree/T = target
		return T.work_needed
	if(istype(target, /turf/closed/mineral/resurgence))
		var/turf/closed/mineral/resurgence/M = target
		return M.work_needed
	if(istype(target, /obj/structure/resurgence_ore_deposit))
		var/obj/structure/resurgence_ore_deposit/O = target
		return O.work_needed
	if(istype(target, /obj/structure/resurgence_cotton))
		var/obj/structure/resurgence_cotton/C = target
		return C.work_needed
	if(istype(target, /obj/structure/farm_plot))
		var/obj/structure/farm_plot/F = target
		return F.get_harvest_work()
	return 0

/// Get the current work_points from a target
/obj/item/harvester/proc/get_target_work_points(atom/target)
	if(istype(target, /obj/structure/resurgence_tree))
		var/obj/structure/resurgence_tree/T = target
		return T.work_points
	if(istype(target, /turf/closed/mineral/resurgence))
		var/turf/closed/mineral/resurgence/M = target
		return M.work_points
	if(istype(target, /obj/structure/resurgence_ore_deposit))
		var/obj/structure/resurgence_ore_deposit/O = target
		return O.work_points
	if(istype(target, /obj/structure/resurgence_cotton))
		var/obj/structure/resurgence_cotton/C = target
		return C.work_points
	if(istype(target, /obj/structure/farm_plot))
		var/obj/structure/farm_plot/F = target
		return F.harvest_work_points
	return 0

/// Set work_points on a target
/obj/item/harvester/proc/set_target_work_points(atom/target, value)
	if(istype(target, /obj/structure/resurgence_tree))
		var/obj/structure/resurgence_tree/T = target
		T.work_points = value
	else if(istype(target, /turf/closed/mineral/resurgence))
		var/turf/closed/mineral/resurgence/M = target
		M.work_points = value
	else if(istype(target, /obj/structure/resurgence_ore_deposit))
		var/obj/structure/resurgence_ore_deposit/O = target
		O.work_points = value
	else if(istype(target, /obj/structure/resurgence_cotton))
		var/obj/structure/resurgence_cotton/C = target
		C.work_points = value
	else if(istype(target, /obj/structure/farm_plot))
		var/obj/structure/farm_plot/F = target
		F.harvest_work_points = value

/// Check if target is currently being worked by a player
/obj/item/harvester/proc/is_target_busy(atom/target)
	if(istype(target, /obj/structure/resurgence_tree))
		var/obj/structure/resurgence_tree/T = target
		return T.being_worked
	if(istype(target, /turf/closed/mineral/resurgence))
		var/turf/closed/mineral/resurgence/M = target
		return M.being_worked
	if(istype(target, /obj/structure/resurgence_ore_deposit))
		var/obj/structure/resurgence_ore_deposit/O = target
		return O.being_worked
	if(istype(target, /obj/structure/resurgence_cotton))
		var/obj/structure/resurgence_cotton/C = target
		return C.being_worked
	if(istype(target, /obj/structure/farm_plot))
		var/obj/structure/farm_plot/F = target
		return F.being_harvested
	return FALSE

/// Set the being_worked flag on target
/obj/item/harvester/proc/set_target_busy(atom/target, busy)
	if(istype(target, /obj/structure/resurgence_tree))
		var/obj/structure/resurgence_tree/T = target
		T.being_worked = busy
	else if(istype(target, /turf/closed/mineral/resurgence))
		var/turf/closed/mineral/resurgence/M = target
		M.being_worked = busy
	else if(istype(target, /obj/structure/resurgence_ore_deposit))
		var/obj/structure/resurgence_ore_deposit/O = target
		O.being_worked = busy
	else if(istype(target, /obj/structure/resurgence_cotton))
		var/obj/structure/resurgence_cotton/C = target
		C.being_worked = busy
	else if(istype(target, /obj/structure/farm_plot))
		var/obj/structure/farm_plot/F = target
		F.being_harvested = busy

/// Call the target's completion proc
/obj/item/harvester/proc/complete_target_harvest(atom/target)
	if(istype(target, /obj/structure/resurgence_tree))
		var/obj/structure/resurgence_tree/T = target
		T.fell_tree(null) // null user since harvester did it
	else if(istype(target, /turf/closed/mineral/resurgence))
		var/turf/closed/mineral/resurgence/M = target
		M.complete_mining(null)
	else if(istype(target, /obj/structure/resurgence_ore_deposit))
		var/obj/structure/resurgence_ore_deposit/O = target
		O.complete_mining(null)
	else if(istype(target, /obj/structure/resurgence_cotton))
		var/obj/structure/resurgence_cotton/C = target
		C.complete_harvest(null)
	else if(istype(target, /obj/structure/farm_plot))
		var/obj/structure/farm_plot/F = target
		F.complete_harvest(null)

/// Attach to a target and start working
/obj/item/harvester/proc/attach_to_target(atom/target, mob/user)
	if(working)
		to_chat(user, span_warning("[src] is already working!"))
		return FALSE

	if(!is_valid_target(target))
		to_chat(user, span_warning("[target] is not a valid harvest target."))
		return FALSE

	if(is_target_busy(target))
		to_chat(user, span_warning("Someone is already working on [target]."))
		return FALSE

	// Calculate faith cost based on remaining work
	var/work_needed = get_target_work_needed(target)
	var/work_done = get_target_work_points(target)
	var/remaining_work = work_needed - work_done
	var/faith_cost = remaining_work * FAITH_DRAIN_PER_WORK

	// Check and pay faith cost (override in subtypes)
	if(!pay_faith_cost(user, faith_cost))
		return FALSE

	// Attach
	current_target = target
	target_type = target.type

	// Create mount structure to hold harvester (prevents pickup)
	// Get the target's layer and set mount layer 0.1 higher
	var/target_layer = target.layer
	current_mount = new /obj/structure/harvester_mount(get_turf(target), src, target_layer)

	// Mark target as busy
	set_target_busy(target, TRUE)

	user.visible_message(
		span_notice("[user] attaches [src] to [target]."),
		span_notice("You attach [src] to [target]. It begins harvesting automatically.")
	)

	// Start working
	start_working()
	return TRUE

/// Pay the faith cost for harvesting - override in subtypes
/obj/item/harvester/proc/pay_faith_cost(mob/user, faith_cost)
	return FALSE // Base class doesn't do anything

/// Start the automated work loop
/obj/item/harvester/proc/start_working()
	if(working || !current_target)
		return

	working = TRUE
	work_loop()

/// The main work loop
/obj/item/harvester/proc/work_loop()
	set waitfor = FALSE

	while(working && current_target)
		// Check if target is still valid
		if(QDELETED(current_target) || !is_valid_target(current_target))
			on_target_invalid()
			break

		// Check if we have enough faith to continue (for advanced harvester)
		if(!can_continue_work())
			on_faith_depleted()
			break

		// Wait for work tick
		sleep(GATHER_TICK_TIME)

		// Verify still working and target exists
		if(!working || QDELETED(current_target))
			break

		// Do work
		var/current_work = get_target_work_points(current_target)
		var/new_work = current_work + work_per_tick
		set_target_work_points(current_target, new_work)

		// Consume faith for work done (for advanced harvester)
		consume_work_faith(work_per_tick)

		// Play sound occasionally
		if(prob(30))
			playsound(src, 'sound/machines/click.ogg', 30, TRUE)

		// Check completion
		var/work_needed = get_target_work_needed(current_target)
		if(new_work >= work_needed)
			on_harvest_complete()
			break

/// Check if harvester can continue work - override in advanced
/obj/item/harvester/proc/can_continue_work()
	return TRUE // Simple harvester paid upfront

/// Consume faith for work done - override in advanced
/obj/item/harvester/proc/consume_work_faith(work_amount)
	return // Simple harvester paid upfront

/// Called when target becomes invalid
/obj/item/harvester/proc/on_target_invalid()
	visible_message(span_warning("[src] detaches - target is no longer valid!"))
	detach_from_target()

/// Called when faith runs out (advanced harvester)
/obj/item/harvester/proc/on_faith_depleted()
	visible_message(span_warning("[src] stops - out of faith!"))
	detach_from_target()

/// Find the nearest open turf to drop on
/obj/item/harvester/proc/find_nearest_open_turf()
	var/turf/current = get_turf(src)
	if(!current)
		return null

	// If current turf is open, use it
	if(istype(current, /turf/open))
		return current

	// Search in expanding rings for an open turf
	for(var/dist in 1 to 5)
		for(var/turf/open/T in range(dist, current))
			return T // Return first open turf found

	return current // Fallback to current if nothing found

/// Called when harvest is complete
/obj/item/harvester/proc/on_harvest_complete()
	if(!current_target)
		return

	// Get drop location BEFORE anything changes
	var/turf/drop_turf = get_turf(current_mount ? current_mount : src)

	// Move harvester out of mount BEFORE deleting it
	if(current_mount && !QDELETED(current_mount))
		current_mount.held_harvester = null // Prevent mount's Destroy from moving us
		forceMove(drop_turf) // Move out first!
		qdel(current_mount)
	current_mount = null

	// Complete the harvest (this may delete/change the target)
	complete_target_harvest(current_target)

	visible_message(span_notice("[src] finishes harvesting and detaches."))

	// Clear target (it may be deleted by complete proc)
	current_target = null
	working = FALSE

	// Try to find next target (advanced harvester overrides this)
	if(!try_find_next_target())
		// No next target, already on ground from earlier forceMove
		return

/// Try to find and attach to next target - override in advanced
/obj/item/harvester/proc/try_find_next_target()
	return FALSE // Simple harvester doesn't auto-seek

/// Detach from current target
/obj/item/harvester/proc/detach_from_target()
	if(current_target && !QDELETED(current_target))
		set_target_busy(current_target, FALSE)

	// Clean up mount structure
	if(current_mount && !QDELETED(current_mount))
		current_mount.held_harvester = null // Prevent mount from moving us
		var/turf/drop_turf = get_turf(current_mount)
		qdel(current_mount)
		forceMove(drop_turf)
	current_mount = null

	current_target = null
	target_type = null
	working = FALSE

/obj/item/harvester/examine(mob/user)
	. = ..()
	if(working && current_target)
		var/work_needed = get_target_work_needed(current_target)
		var/work_done = get_target_work_points(current_target)
		var/progress = round((work_done / work_needed) * 100)
		. += span_notice("Currently harvesting [current_target] ([progress]% complete).")
	else
		. += span_notice("Use on a tree, ore deposit, cotton plant, or ready farm plot to attach.")

// ===== Simple Harvester =====

/obj/item/harvester/simple
	name = "simple harvester"
	desc = "A basic automated harvesting device. Attach to a resource and it will harvest it for you. Requires faith payment upfront. Has limited uses before breaking."
	icon_state = "drone_maint_blue"
	/// Number of uses remaining before this harvester breaks
	var/uses_remaining = 3

/obj/item/harvester/simple/pay_faith_cost(mob/user, faith_cost)
	if(!ishuman(user))
		to_chat(user, span_warning("Only humans can use this."))
		return FALSE

	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		to_chat(user, span_warning("You don't have a resurgence core!"))
		return FALSE

	if(core.faith < faith_cost)
		to_chat(user, span_warning("You need [faith_cost] faith to harvest this. You only have [core.faith]."))
		return FALSE

	// Pay the cost
	core.adjust_faith(-faith_cost)
	to_chat(user, span_notice("You transfer [faith_cost] faith to power the harvester."))
	return TRUE

/obj/item/harvester/simple/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag)
		return

	attach_to_target(target, user)

/obj/item/harvester/simple/on_harvest_complete()
	. = ..()
	// Decrement uses
	uses_remaining--
	if(uses_remaining <= 0)
		visible_message(span_warning("[src] breaks apart from wear!"))
		qdel(src)

/obj/item/harvester/simple/examine(mob/user)
	. = ..()
	. += span_notice("Uses remaining: [uses_remaining]")

// ===== Advanced Harvester =====

/obj/item/harvester/advanced
	name = "advanced harvester"
	desc = "An advanced automated harvesting device with internal faith storage. Can automatically seek nearby targets of the same type. Breaks after using 500 total faith."
	icon_state = "drone_synd"
	/// Stored faith for autonomous operation
	var/stored_faith = 0
	/// Maximum faith storage
	var/max_faith = 100
	/// Search range for auto-seek
	var/search_range = 3
	/// Total faith used over the harvester's lifetime
	var/total_faith_used = 0
	/// Maximum total faith before the harvester breaks
	var/max_total_faith = 500

/obj/item/harvester/advanced/pay_faith_cost(mob/user, faith_cost)
	// Advanced harvester uses stored faith, not player's
	if(stored_faith < faith_cost)
		to_chat(user, span_warning("[src] needs [faith_cost] stored faith. It only has [stored_faith]."))
		to_chat(user, span_notice("Use [src] in hand to transfer faith to it."))
		return FALSE

	// Don't deduct here - we pay as we work
	return TRUE

/obj/item/harvester/advanced/can_continue_work()
	// Need at least enough faith for one tick of work
	var/faith_per_tick = work_per_tick * FAITH_DRAIN_PER_WORK
	return stored_faith >= faith_per_tick

/obj/item/harvester/advanced/consume_work_faith(work_amount)
	var/faith_cost = work_amount * FAITH_DRAIN_PER_WORK
	stored_faith = max(0, stored_faith - faith_cost)
	total_faith_used += faith_cost

	// Check if harvester has exceeded its lifetime
	if(total_faith_used >= max_total_faith)
		visible_message(span_warning("[src] breaks apart from extensive use!"))
		detach_from_target()
		qdel(src)

/obj/item/harvester/advanced/on_faith_depleted()
	visible_message(span_warning("[src] stops - out of faith!"))

	// Find nearest open turf before detaching (in case we're on a closed turf like ore)
	var/turf/drop_turf = find_nearest_open_turf()

	// Clear target busy flag
	if(current_target && !QDELETED(current_target))
		set_target_busy(current_target, FALSE)

	// Clean up mount and move to open turf
	if(current_mount && !QDELETED(current_mount))
		current_mount.held_harvester = null
		qdel(current_mount)
	current_mount = null

	// Move to the open turf
	if(drop_turf)
		forceMove(drop_turf)

	current_target = null
	target_type = null
	working = FALSE

/obj/item/harvester/advanced/try_find_next_target()
	if(stored_faith < MIN_FAITH_FOR_WORK)
		return FALSE

	var/atom/next_target = find_next_target()
	if(!next_target)
		return FALSE

	// Attach to new target
	current_target = next_target
	set_target_busy(next_target, TRUE)

	// Create new mount for the new target
	var/target_layer = next_target.layer
	current_mount = new /obj/structure/harvester_mount(get_turf(next_target), src, target_layer)

	visible_message(span_notice("[src] moves to [next_target] and continues harvesting."))
	start_working()
	return TRUE

/// Find the next valid target of the same type within range (picks nearest)
/obj/item/harvester/advanced/proc/find_next_target()
	if(!target_type)
		return null

	var/turf/center = get_turf(src)
	var/atom/nearest_target = null
	var/nearest_dist = INFINITY

	for(var/atom/A in view(search_range, center))
		if(A.type != target_type)
			continue
		if(!is_valid_target(A))
			continue
		if(is_target_busy(A))
			continue
		var/dist = get_dist(center, get_turf(A))
		if(dist < nearest_dist)
			nearest_dist = dist
			nearest_target = A

	return nearest_target

/obj/item/harvester/advanced/attack_self(mob/user)
	// Transfer faith from user to harvester
	if(!ishuman(user))
		to_chat(user, span_warning("Only humans can use this."))
		return

	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		to_chat(user, span_warning("You don't have a resurgence core!"))
		return

	var/space_available = max_faith - stored_faith
	if(space_available <= 0)
		to_chat(user, span_warning("[src] is already at maximum faith capacity."))
		return

	var/transfer_amount = min(core.faith - MIN_FAITH_FOR_WORK, space_available)
	if(transfer_amount <= 0)
		to_chat(user, span_warning("You don't have enough faith to spare. You need to keep at least [MIN_FAITH_FOR_WORK]."))
		return

	// Calculate remaining lifetime faith
	var/remaining_lifetime = max_total_faith - total_faith_used
	var/effective_remaining = remaining_lifetime - stored_faith

	// Warn if trying to add more faith than the harvester can use
	var/warning_text = ""
	if(transfer_amount > effective_remaining && effective_remaining > 0)
		warning_text = "\n\nWARNING: This harvester can only use [effective_remaining] more faith before breaking. Any excess will be wasted!"
	else if(effective_remaining <= 0)
		to_chat(user, span_warning("[src] is near the end of its lifespan! It can only use [remaining_lifetime] more faith total."))
		// Cap transfer to remaining lifetime
		transfer_amount = min(transfer_amount, remaining_lifetime)
		if(transfer_amount <= 0)
			return

	// Ask how much to transfer
	var/amount = input(user, "How much faith to transfer? (Available: [transfer_amount], Current storage: [stored_faith]/[max_faith])[warning_text]", "Transfer Faith", min(transfer_amount, max(1, effective_remaining))) as num|null
	if(!amount || amount <= 0)
		return
	amount = min(amount, transfer_amount)

	core.adjust_faith(-amount)
	stored_faith += amount
	to_chat(user, span_notice("You transfer [amount] faith to [src]. Storage: [stored_faith]/[max_faith]"))
	playsound(src, 'sound/machines/click.ogg', 30, TRUE)

/obj/item/harvester/advanced/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag)
		return

	attach_to_target(target, user)

/obj/item/harvester/advanced/examine(mob/user)
	. = ..()
	. += span_notice("Faith storage: [stored_faith]/[max_faith]")
	var/remaining_lifetime = max_total_faith - total_faith_used
	if(remaining_lifetime > 50)
		. += span_notice("Lifetime remaining: [remaining_lifetime]/[max_total_faith] faith")
	else
		. += span_warning("Lifetime remaining: [remaining_lifetime]/[max_total_faith] faith - near end of lifespan!")
	. += span_notice("Use in hand to transfer faith from your core.")
	. += span_notice("Auto-seeks same resource type within [search_range] tiles after completing a harvest.")

/// When destroyed while working, refund partial faith
/obj/item/harvester/advanced/Destroy()
	if(working && current_target && !QDELETED(current_target))
		// Calculate remaining work value
		var/work_needed = get_target_work_needed(current_target)
		var/work_done = get_target_work_points(current_target)
		var/remaining_work = work_needed - work_done
		var/refund = (remaining_work * FAITH_DRAIN_PER_WORK) * 0.5 // 50% refund

		if(refund > 0)
			// Try to find a nearby player to refund
			for(var/mob/living/carbon/human/H in range(2, get_turf(src)))
				var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
				if(istype(core))
					core.adjust_faith(refund)
					to_chat(H, span_notice("[src] was destroyed! You recover [refund] faith."))
					break

	return ..()
