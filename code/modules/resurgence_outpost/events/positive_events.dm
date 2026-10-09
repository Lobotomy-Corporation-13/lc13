/**
 * Resurgence Outpost - Positive Events
 *
 * Beneficial events that help the outpost.
 */

// ============================================
// Bountiful Harvest
// ============================================

/datum/resurgence_event/bountiful_harvest
	name = "Bountiful Harvest"
	desc = "The plants are thriving! Harvesting yields increased by 50%."
	category = EVENT_POSITIVE
	weight = 80
	min_round_time = 10 MINUTES
	duration = 8 MINUTES

/datum/resurgence_event/bountiful_harvest/apply_modifiers()
	GLOB.resurgence_yield_modifier *= 1.5

/datum/resurgence_event/bountiful_harvest/remove_modifiers()
	GLOB.resurgence_yield_modifier /= 1.5

// ============================================
// Rich Soil
// ============================================

/datum/resurgence_event/rich_soil
	name = "Rich Soil"
	desc = "The soil is exceptionally fertile! Crops grow 50% faster."
	category = EVENT_POSITIVE
	weight = 70
	min_round_time = 15 MINUTES
	duration = 10 MINUTES

/datum/resurgence_event/rich_soil/apply_modifiers()
	GLOB.resurgence_growth_modifier *= 1.5

/datum/resurgence_event/rich_soil/remove_modifiers()
	GLOB.resurgence_growth_modifier /= 1.5

// ============================================
// Favorable Conditions
// ============================================

/datum/resurgence_event/favorable_conditions
	name = "Favorable Conditions"
	desc = "Perfect weather for gathering! All work is more productive."
	category = EVENT_POSITIVE
	weight = 75
	min_round_time = 12 MINUTES
	duration = 4 MINUTES

/datum/resurgence_event/favorable_conditions/apply_modifiers()
	GLOB.resurgence_work_modifier *= 1.25

/datum/resurgence_event/favorable_conditions/remove_modifiers()
	GLOB.resurgence_work_modifier /= 1.25

// ============================================
// Market Boom
// ============================================

/datum/resurgence_event/market_boom
	name = "Market Boom"
	desc = "Market conditions are favorable! Sell prices +25%, buy prices -15%."
	category = EVENT_POSITIVE
	weight = 60
	min_round_time = 20 MINUTES
	duration = 10 MINUTES

/datum/resurgence_event/market_boom/apply_modifiers()
	GLOB.resurgence_sell_modifier *= 1.25
	GLOB.resurgence_buy_modifier *= 0.85

/datum/resurgence_event/market_boom/remove_modifiers()
	GLOB.resurgence_sell_modifier /= 1.25
	GLOB.resurgence_buy_modifier /= 0.85

// ============================================
// Faith Surge
// ============================================

/datum/resurgence_event/faith_surge
	name = "Faith Surge"
	desc = "A wave of spiritual energy washes over the outpost!"
	category = EVENT_POSITIVE
	weight = 50
	min_round_time = 25 MINUTES
	duration = 3 MINUTES

	/// Instant faith gain for all players
	var/instant_faith = 30

/datum/resurgence_event/faith_surge/start_event()
	. = ..()
	if(!.)
		return

	// Grant instant faith to all resurgence players
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			core.adjust_faith(instant_faith)
			to_chat(H, span_nicegreen("You feel a surge of spiritual energy! (+[instant_faith] faith)"))

/datum/resurgence_event/faith_surge/apply_modifiers()
	GLOB.resurgence_faith_regen_modifier *= 2.0

/datum/resurgence_event/faith_surge/remove_modifiers()
	GLOB.resurgence_faith_regen_modifier /= 2.0

// ============================================
// Research Momentum
// ============================================

/datum/resurgence_event/research_momentum
	name = "Research Momentum"
	desc = "A breakthrough! Research work is 50% more productive."
	category = EVENT_POSITIVE
	weight = 55
	min_round_time = 20 MINUTES
	duration = 6 MINUTES

// Research momentum uses work_modifier which affects research stations
/datum/resurgence_event/research_momentum/apply_modifiers()
	GLOB.resurgence_work_modifier *= 1.5

/datum/resurgence_event/research_momentum/remove_modifiers()
	GLOB.resurgence_work_modifier /= 1.5

// ============================================
// Crafting Inspiration
// ============================================

/datum/resurgence_event/crafting_inspiration
	name = "Crafting Inspiration"
	desc = "The workers feel inspired! Crafted items have +2 quality bonus."
	category = EVENT_POSITIVE
	weight = 50
	min_round_time = 25 MINUTES
	duration = 4 MINUTES

/datum/resurgence_event/crafting_inspiration/apply_modifiers()
	GLOB.resurgence_quality_bonus += 2

/datum/resurgence_event/crafting_inspiration/remove_modifiers()
	GLOB.resurgence_quality_bonus -= 2

