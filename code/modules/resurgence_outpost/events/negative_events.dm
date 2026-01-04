/**
 * Resurgence Outpost - Negative Events
 *
 * Challenging events that affect the outpost.
 * Note: Heat Wave and Cold Snap are in weather_events.dm
 */

// ============================================
// Drought
// ============================================

/datum/resurgence_event/drought
	name = "Drought"
	desc = "A drought has set in. Crops grow 50% slower."
	category = EVENT_NEGATIVE
	weight = 65
	min_round_time = 15 MINUTES
	duration = 10 MINUTES

/datum/resurgence_event/drought/apply_modifiers()
	GLOB.resurgence_growth_modifier *= 0.5

/datum/resurgence_event/drought/remove_modifiers()
	GLOB.resurgence_growth_modifier /= 0.5

// ============================================
// Market Crash
// ============================================

/datum/resurgence_event/market_crash
	name = "Market Crash"
	desc = "Market conditions worsen. Sell prices -30%, buy prices +30%."
	category = EVENT_NEGATIVE
	weight = 60
	min_round_time = 20 MINUTES
	duration = 10 MINUTES

/datum/resurgence_event/market_crash/apply_modifiers()
	GLOB.resurgence_sell_modifier *= 0.7
	GLOB.resurgence_buy_modifier *= 1.3

/datum/resurgence_event/market_crash/remove_modifiers()
	GLOB.resurgence_sell_modifier /= 0.7
	GLOB.resurgence_buy_modifier /= 1.3

// ============================================
// Faith Crisis
// ============================================

/datum/resurgence_event/faith_crisis
	name = "Faith Crisis"
	desc = "Doubt and despair spread through the outpost..."
	category = EVENT_NEGATIVE
	weight = 45
	min_round_time = 30 MINUTES
	duration = 5 MINUTES

	/// Instant faith loss for all players
	var/instant_drain = 20

/datum/resurgence_event/faith_crisis/start_event()
	. = ..()
	if(!.)
		return

	// Drain faith from all resurgence players
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			// Apply trait modifier for faith loss (Iron-Willed, Sickly, Too Smart)
			var/actual_drain = instant_drain * get_trait_faith_loss_modifier(H)
			core.adjust_faith(-actual_drain)
			to_chat(H, span_warning("A wave of doubt washes over you... (-[round(actual_drain)] faith)"))

/datum/resurgence_event/faith_crisis/apply_modifiers()
	GLOB.resurgence_faith_regen_modifier *= 0.5

/datum/resurgence_event/faith_crisis/remove_modifiers()
	GLOB.resurgence_faith_regen_modifier /= 0.5

// ============================================
// Fatigue Wave
// ============================================

/datum/resurgence_event/fatigue_wave
	name = "Fatigue Wave"
	desc = "A wave of exhaustion affects all workers. Work is 25% less productive."
	category = EVENT_NEGATIVE
	weight = 55
	min_round_time = 20 MINUTES
	duration = 6 MINUTES

/datum/resurgence_event/fatigue_wave/apply_modifiers()
	GLOB.resurgence_work_modifier *= 0.75

/datum/resurgence_event/fatigue_wave/remove_modifiers()
	GLOB.resurgence_work_modifier /= 0.75

// ============================================
// Resource Scarcity
// ============================================

/datum/resurgence_event/resource_scarcity
	name = "Resource Scarcity"
	desc = "Resources are harder to come by. Gathering yields -25%."
	category = EVENT_NEGATIVE
	weight = 60
	min_round_time = 18 MINUTES
	duration = 8 MINUTES

/datum/resurgence_event/resource_scarcity/apply_modifiers()
	GLOB.resurgence_yield_modifier *= 0.75

/datum/resurgence_event/resource_scarcity/remove_modifiers()
	GLOB.resurgence_yield_modifier /= 0.75

// ============================================
// Tool Strain
// ============================================

/datum/resurgence_event/tool_strain
	name = "Tool Strain"
	desc = "Something in the air is wearing down tools faster. Tools lose durability 2x faster."
	category = EVENT_NEGATIVE
	weight = 50
	min_round_time = 25 MINUTES
	duration = 10 MINUTES

/datum/resurgence_event/tool_strain/apply_modifiers()
	GLOB.resurgence_durability_modifier *= 2.0

/datum/resurgence_event/tool_strain/remove_modifiers()
	GLOB.resurgence_durability_modifier /= 2.0
