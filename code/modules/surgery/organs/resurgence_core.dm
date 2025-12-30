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

/obj/item/organ/resurgence_core/Destroy()
	// Clean up all faith events
	for(var/category in faith_events)
		var/datum/faith_event/event = faith_events[category]
		event.parent_core = null
		qdel(event)
	faith_events.Cut()
	return ..()

/obj/item/organ/resurgence_core/Insert(mob/living/carbon/M, special, drop_if_replaced)
	. = ..()
	// Show the faith HUD when core is inserted
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.hud_used?.faith_display)
			H.hud_used.faith_display.show_display()
			H.update_faith_hud()

/obj/item/organ/resurgence_core/Remove(mob/living/carbon/M, special)
	// Hide the faith HUD when core is removed
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.hud_used?.faith_display)
			H.hud_used.faith_display.hide_display()
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
		faith = clamp(faith + faith_change_rate, 0, max_faith)

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
	switch(severity)
		if(EMP_LIGHT)
			owner.adjustBruteLoss(10)
			adjust_faith(-10)
			to_chat(owner, span_warning("Your core systems are disrupted by the electromagnetic pulse!"))
		if(EMP_HEAVY)
			owner.adjustBruteLoss(20)
			adjust_faith(-20)
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
			to_chat(H, span_notice("  [event.description] ([sign][event.faith_change] per 5 sec)"))

	if(!has_events)
		to_chat(H, span_notice("No special faith effects active."))
