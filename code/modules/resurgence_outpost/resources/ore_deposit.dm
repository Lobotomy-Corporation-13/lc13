/**
 * Resurgence Outpost - Ore Deposits
 *
 * Renewable ore deposits that can be mined and will regenerate.
 * Features a pulsing colored outline to indicate ore type.
 * Spreads to nearby deposits on initialization to form clusters.
 */

/// Time for a depleted deposit to regenerate
#define ORE_DEPOSIT_REGEN_TIME (10 MINUTES)

/obj/structure/resurgence_ore_deposit
	name = "ore deposit"
	desc = "A rocky deposit containing valuable ore. It appears to slowly regenerate over time."
	icon = 'icons/obj/flora/rocks.dmi'
	icon_state = "basalt2"
	anchored = TRUE
	density = FALSE
	layer = LOW_OBJ_LAYER

	/// The ore type this deposit contains
	var/ore_type = null
	/// The ore stack type to drop
	var/ore_drop_type = null
	/// Amount of ore to drop when mined
	var/ore_amount = 50
	/// Color for the overlay and outline
	var/ore_color = "#808080"
	/// Display name for the ore
	var/ore_name = "ore"

	/// Current work points accumulated
	var/work_points = 0
	/// Total work points needed to mine
	var/work_needed = 150
	/// Whether someone is currently mining
	var/being_worked = FALSE
	/// Whether the deposit is currently depleted
	var/depleted = FALSE
	/// Speed bonus when using a proper mining tool
	var/tool_speed_bonus = 0.25

	/// The ore overlay appearance
	var/mutable_appearance/ore_overlay
	/// Whether this deposit has already spread to neighbors
	var/has_spread = FALSE

	/// Static list of ore types with weights and data
	var/static/list/ore_data = list(
		"iron" = list(
			"weight" = 40,
			"color" = "#8B5A2B",
			"drop_type" = /obj/item/stack/ore/iron,
			"amount" = 80,
			"work" = 200
		),
		"coal" = list(
			"weight" = 30,
			"color" = "#2A2A2A",
			"drop_type" = /obj/item/stack/sheet/mineral/coal,
			"amount" = 100,
			"work" = 150
		),
		"silver" = list(
			"weight" = 20,
			"color" = "#C0C0C0",
			"drop_type" = /obj/item/stack/ore/silver,
			"amount" = 50,
			"work" = 250
		),
		"gold" = list(
			"weight" = 10,
			"color" = "#FFD700",
			"drop_type" = /obj/item/stack/ore/gold,
			"amount" = 40,
			"work" = 300
		)
	)

/obj/structure/resurgence_ore_deposit/Initialize(mapload)
	. = ..()
	// Pick a random ore type if not set
	if(!ore_type)
		pick_random_ore()
	apply_ore_visuals()
	// Spread to nearby deposits after a short delay
	addtimer(CALLBACK(src, PROC_REF(spread_to_neighbors)), 1 SECONDS)

/// Pick a random ore type based on weights
/obj/structure/resurgence_ore_deposit/proc/pick_random_ore()
	var/list/weighted_list = list()
	for(var/ore in ore_data)
		weighted_list[ore] = ore_data[ore]["weight"]
	ore_type = pickweight(weighted_list)
	apply_ore_data()

/// Apply data from the ore_data list based on ore_type
/obj/structure/resurgence_ore_deposit/proc/apply_ore_data()
	if(!ore_type || !ore_data[ore_type])
		return
	var/list/data = ore_data[ore_type]
	ore_color = data["color"]
	ore_drop_type = data["drop_type"]
	ore_amount = data["amount"]
	work_needed = data["work"]
	ore_name = ore_type
	name = "[ore_type] deposit"
	desc = "A rocky deposit containing [ore_type] ore. It appears to slowly regenerate over time."

/// Apply visual effects based on ore type
/obj/structure/resurgence_ore_deposit/proc/apply_ore_visuals()
	// Add colored ore overlay
	if(ore_overlay)
		cut_overlay(ore_overlay)
	ore_overlay = mutable_appearance(icon, "[icon_state]_overlay")
	ore_overlay.color = ore_color
	if(!depleted)
		ore_overlay.alpha = 255
	else
		ore_overlay.alpha = 0
	add_overlay(ore_overlay)

	// Add pulsing outline filter
	add_filter("ore_glow", 2, list("type" = "outline", "color" = "[ore_color]50", "size" = 2))
	addtimer(CALLBACK(src, PROC_REF(start_glow_loop)), rand(1, 19))

/// Start the pulsing glow animation
/obj/structure/resurgence_ore_deposit/proc/start_glow_loop()
	var/filter = get_filter("ore_glow")
	if(filter)
		animate(filter, alpha = 130, time = 15, loop = -1)
		animate(alpha = 50, time = 25)

/// Spread ore type to nearby uninitialized deposits
/obj/structure/resurgence_ore_deposit/proc/spread_to_neighbors()
	if(has_spread)
		return
	has_spread = TRUE

	for(var/obj/structure/resurgence_ore_deposit/neighbor in range(2, src))
		if(neighbor == src)
			continue
		// Convert blank deposits
		if(istype(neighbor, /obj/structure/resurgence_ore_deposit/blank))
			var/obj/structure/resurgence_ore_deposit/blank/blank_neighbor = neighbor
			if(blank_neighbor.awaiting_conversion)
				blank_neighbor.convert_to_ore(ore_type)
			continue
		// Normal deposits - only convert if they haven't spread yet
		if(neighbor.has_spread)
			continue
		// Convert neighbor to our ore type
		neighbor.ore_type = ore_type
		neighbor.apply_ore_data()
		neighbor.apply_ore_visuals()
		neighbor.has_spread = TRUE

/obj/structure/resurgence_ore_deposit/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return

	if(depleted)
		to_chat(user, span_warning("This deposit is depleted. It needs time to regenerate."))
		return

	if(being_worked)
		to_chat(user, span_warning("Someone is already mining this deposit."))
		return

	if(!ishuman(user))
		return

	start_mining(user, null)

/obj/structure/resurgence_ore_deposit/attackby(obj/item/I, mob/user, params)
	if(depleted)
		to_chat(user, span_warning("This deposit is depleted. It needs time to regenerate."))
		return

	// Check for mining tool - if not, try bare hands
	if(I.tool_behaviour != TOOL_MINING)
		return attack_hand(user)

	if(being_worked)
		to_chat(user, span_warning("Someone is already mining this deposit."))
		return

	if(!ishuman(user))
		return

	start_mining(user, I)

/obj/structure/resurgence_ore_deposit/proc/start_mining(mob/living/carbon/human/user, obj/item/tool)
	// Check faith requirement
	if(!can_gather(user))
		to_chat(user, span_warning("You're too exhausted to mine. You need at least [MIN_FAITH_FOR_WORK] faith."))
		return

	// Work rate - base rate for bare hands, tools provide speed bonus
	var/work_per_tick = GATHER_WORK_PER_TICK
	var/using_tool = FALSE
	if(tool?.tool_behaviour == TOOL_MINING)
		work_per_tick *= (1 + tool_speed_bonus)
		using_tool = TRUE

	// Starting message
	if(work_points > 0)
		var/progress_pct = round((work_points / work_needed) * 100)
		to_chat(user, span_notice("You continue mining [src]... ([progress_pct]% complete)"))
	else
		if(using_tool)
			to_chat(user, span_notice("You begin mining [src] with [tool]..."))
		else
			to_chat(user, span_notice("You begin mining [src] with your bare hands..."))

	// Play sound
	if(using_tool)
		if(islist(tool.usesound))
			playsound(src, pick(tool.usesound), 50, TRUE)
		else if(tool.usesound)
			playsound(src, tool.usesound, 50, TRUE)
	else
		playsound(src, 'sound/effects/stonedoor_openclose.ogg', 50, TRUE)

	being_worked = TRUE

	// Mining loop
	while(work_points < work_needed)
		// Check faith each tick
		if(!can_gather(user))
			to_chat(user, span_warning("You're too exhausted to continue mining."))
			break

		// Do the work tick
		if(!do_after(user, GATHER_TICK_TIME, target = src))
			var/progress_pct = round((work_points / work_needed) * 100)
			to_chat(user, span_notice("You stop mining [src]. Progress: [progress_pct]%"))
			break

		// Add work and drain faith
		work_points += work_per_tick
		apply_work_faith_drain(user, work_per_tick)

		// Periodic sound
		if(prob(30))
			if(using_tool)
				if(islist(tool.usesound))
					playsound(src, pick(tool.usesound), 50, TRUE)
				else if(tool.usesound)
					playsound(src, tool.usesound, 50, TRUE)
			else
				playsound(src, 'sound/effects/stonedoor_openclose.ogg', 50, TRUE)

	being_worked = FALSE

	// Check completion
	if(work_points >= work_needed)
		complete_mining(user)

/obj/structure/resurgence_ore_deposit/proc/complete_mining(mob/user)
	if(user)
		user.visible_message(
			span_notice("[user] extracts ore from [src]!"),
			span_notice("You extract [ore_name] ore from [src]!"),
			span_hear("You hear rock crumbling.")
		)
	playsound(src, 'sound/effects/break_stone.ogg', 60, TRUE)

	// Drop ore
	if(ore_drop_type && ore_amount > 0)
		new ore_drop_type(get_turf(src), ore_amount)

	// Deplete the deposit
	deplete()

/// Deplete the deposit and start regeneration timer
/obj/structure/resurgence_ore_deposit/proc/deplete()
	depleted = TRUE
	work_points = 0

	// Hide the ore overlay
	if(ore_overlay)
		cut_overlay(ore_overlay)
		ore_overlay.alpha = 0
		add_overlay(ore_overlay)

	// Update description
	desc = "A depleted [ore_type] deposit. The ore will regenerate over time."

	// Start regeneration timer
	addtimer(CALLBACK(src, PROC_REF(regenerate)), ORE_DEPOSIT_REGEN_TIME)

/// Regenerate the deposit
/obj/structure/resurgence_ore_deposit/proc/regenerate()
	depleted = FALSE

	// Restore the ore overlay
	if(ore_overlay)
		cut_overlay(ore_overlay)
		ore_overlay.alpha = 255
		add_overlay(ore_overlay)

	// Restore description
	desc = "A rocky deposit containing [ore_type] ore. It appears to slowly regenerate over time."

	// Visual feedback
	visible_message(span_notice("[src] has regenerated with fresh ore!"))

/obj/structure/resurgence_ore_deposit/examine(mob/user)
	. = ..()
	if(depleted)
		. += span_warning("This deposit is depleted and needs time to regenerate.")
		. += span_notice("The pulsing glow indicates it will replenish itself.")
	else if(work_points > 0)
		var/progress_pct = round((work_points / work_needed) * 100)
		. += span_notice("It has been partially mined. ([progress_pct]% complete)")
		. += span_notice("Anyone can continue working on it. A pickaxe works faster.")
	else
		. += span_notice("Mine it with your hands, or use a pickaxe for faster work.")
		. += span_notice("The pulsing glow indicates this deposit will regenerate after mining.")

// ===== Deposit Variants =====

/// Blank deposit - has no ore until converted by a nearby deposit
/obj/structure/resurgence_ore_deposit/blank
	name = "barren deposit"
	desc = "A rocky deposit that appears empty. Perhaps nearby ore veins could spread to it."
	ore_type = null
	/// Blank deposits don't pick random ore or spread on their own
	var/awaiting_conversion = TRUE

/obj/structure/resurgence_ore_deposit/blank/Initialize(mapload)
	. = ..()
	// Don't pick random ore - wait for conversion
	// Remove the timer that was set by parent
	// We'll just wait to be converted

/obj/structure/resurgence_ore_deposit/blank/pick_random_ore()
	// Don't pick ore - stay blank until converted
	return

/obj/structure/resurgence_ore_deposit/blank/apply_ore_visuals()
	// No ore overlay for blank deposits, just the base rock
	// No glow either until converted
	return

/obj/structure/resurgence_ore_deposit/blank/spread_to_neighbors()
	// Blank deposits don't spread
	return

/// Called when a nearby deposit converts this blank deposit
/obj/structure/resurgence_ore_deposit/blank/proc/convert_to_ore(new_ore_type)
	if(!new_ore_type)
		return
	awaiting_conversion = FALSE
	ore_type = new_ore_type
	apply_ore_data()
	// Now apply visuals since we have an ore type
	// Add colored ore overlay
	ore_overlay = mutable_appearance(icon, "[icon_state]_overlay")
	ore_overlay.color = ore_color
	ore_overlay.alpha = 255
	add_overlay(ore_overlay)
	// Add pulsing outline filter
	add_filter("ore_glow", 2, list("type" = "outline", "color" = "[ore_color]50", "size" = 2))
	addtimer(CALLBACK(src, PROC_REF(start_glow_loop)), rand(1, 19))

#undef ORE_DEPOSIT_REGEN_TIME
