/**
 * Resurgence Trait System
 *
 * Traits are permanent character modifiers selected during character creation.
 * Each trait has a point cost (positive for beneficial, negative for detrimental).
 */

// ============================================
// Base Trait Datum
// ============================================

/datum/resurgence_trait
	/// Display name of the trait
	var/name = "Unnamed"
	/// Description shown in UI
	var/desc = "No description."
	/// Point cost (positive = costs points, negative = gives points)
	var/point_cost = 0
	/// List of incompatible trait types
	var/list/incompatible = list()
	/// Whether this is a mixed (trade-off) trait
	var/is_mixed = FALSE
	/// Set to TRUE for abstract base types
	var/abstract_type = FALSE
	/// The mob this trait is applied to
	var/mob/living/carbon/human/holder = null

/**
 * Apply the trait's effects to a mob
 * Override in subtypes to implement specific effects
 */
/datum/resurgence_trait/proc/apply(mob/living/carbon/human/H)
	if(!H)
		return FALSE
	holder = H
	return TRUE

/**
 * Remove the trait's effects from a mob
 * Override in subtypes to reverse specific effects
 */
/datum/resurgence_trait/proc/remove()
	holder = null
	return TRUE

/**
 * Called every life tick if the trait needs processing
 * Override in subtypes that need periodic effects
 */
/datum/resurgence_trait/proc/on_process(delta_time)
	return

/**
 * Get modifier value for a specific stat/effect
 * Used by other systems to query trait effects
 */
/datum/resurgence_trait/proc/get_modifier(modifier_type)
	return 0

// ============================================
// Positive Traits
// ============================================

/// Industrious - +15% work speed
/datum/resurgence_trait/industrious
	name = "Industrious"
	desc = "+15% work speed on all tasks."
	point_cost = 2
	incompatible = list(/datum/resurgence_trait/lazy)

/datum/resurgence_trait/industrious/get_modifier(modifier_type)
	if(modifier_type == "work_speed")
		return 0.15
	return 0

/// Quick Learner - +25% XP gain
/datum/resurgence_trait/quick_learner
	name = "Quick Learner"
	desc = "+25% XP gain from all activities."
	point_cost = 2
	incompatible = list(/datum/resurgence_trait/slow_learner)

/datum/resurgence_trait/quick_learner/get_modifier(modifier_type)
	if(modifier_type == "xp_gain")
		return 0.25
	return 0

/// Tough - +3 brute and burn damage reduction
/datum/resurgence_trait/tough
	name = "Tough"
	desc = "+3 brute and burn damage reduction."
	point_cost = 2

/datum/resurgence_trait/tough/apply(mob/living/carbon/human/H)
	. = ..()
	if(!.)
		return
	for(var/obj/item/bodypart/BP in H.bodyparts)
		BP.brute_reduction += 3
		BP.burn_reduction += 3

/datum/resurgence_trait/tough/remove()
	if(holder)
		for(var/obj/item/bodypart/BP in holder.bodyparts)
			BP.brute_reduction -= 3
			BP.burn_reduction -= 3
	return ..()

/// Green Thumb - +20% harvesting yield
/datum/resurgence_trait/green_thumb
	name = "Green Thumb"
	desc = "+20% harvesting yield from farming and gathering."
	point_cost = 1

/datum/resurgence_trait/green_thumb/get_modifier(modifier_type)
	if(modifier_type == "harvest_yield")
		return 0.20
	return 0

/// Steady Hand - +2 beauty bonus on crafted items
/datum/resurgence_trait/steady_hand
	name = "Steady Hand"
	desc = "+2 beauty bonus on crafted and built items."
	point_cost = 1

/datum/resurgence_trait/steady_hand/get_modifier(modifier_type)
	if(modifier_type == "craft_beauty")
		return 2
	return 0

/// Iron-Willed - Faith decreases 20% slower from negative events
/datum/resurgence_trait/iron_willed
	name = "Iron-Willed"
	desc = "Faith decreases 20% slower from negative events."
	point_cost = 2
	incompatible = list(/datum/resurgence_trait/sickly)

/datum/resurgence_trait/iron_willed/get_modifier(modifier_type)
	if(modifier_type == "faith_loss_reduction")
		return 0.20
	return 0

/// Meticulous - +1 quality tier on crafted tools
/datum/resurgence_trait/meticulous
	name = "Meticulous"
	desc = "+1 quality tier on crafted tools."
	point_cost = 1

/datum/resurgence_trait/meticulous/get_modifier(modifier_type)
	if(modifier_type == "tool_quality")
		return 1
	return 0

/// Nimble - +10% movement speed
/datum/resurgence_trait/nimble
	name = "Nimble"
	desc = "+10% movement speed."
	point_cost = 1
	incompatible = list(/datum/resurgence_trait/slowpoke)

/datum/resurgence_trait/nimble/apply(mob/living/carbon/human/H)
	. = ..()
	if(!.)
		return
	H.add_movespeed_modifier(/datum/movespeed_modifier/resurgence_nimble)

/datum/resurgence_trait/nimble/remove()
	if(holder)
		holder.remove_movespeed_modifier(/datum/movespeed_modifier/resurgence_nimble)
	return ..()

/// Kind - Hugging gives faith bonus
/datum/resurgence_trait/kind
	name = "Kind"
	desc = "Hugging someone gives them a faith event (+0.2 faith/5s for 1 min). 1 min cooldown."
	point_cost = 2
	/// Cooldown tracking
	var/next_hug_time = 0

/datum/resurgence_trait/kind/get_modifier(modifier_type)
	if(modifier_type == "kind_hug")
		return 1
	return 0

/// Beautiful - +3 beauty component on character
/datum/resurgence_trait/beautiful
	name = "Beautiful"
	desc = "Character has a beauty component of +3, improving room quality when present."
	point_cost = 2
	incompatible = list(/datum/resurgence_trait/pretty, /datum/resurgence_trait/ugly, /datum/resurgence_trait/staggeringly_ugly)

/datum/resurgence_trait/beautiful/apply(mob/living/carbon/human/H)
	. = ..()
	if(!.)
		return
	H.AddComponent(/datum/component/resurgence_beauty, 3)

/datum/resurgence_trait/beautiful/remove()
	if(holder)
		var/datum/component/resurgence_beauty/B = holder.GetComponent(/datum/component/resurgence_beauty)
		if(B)
			qdel(B)
	return ..()

/// Pretty - +1 beauty component on character
/datum/resurgence_trait/pretty
	name = "Pretty"
	desc = "Character has a beauty component of +1, slightly improving room quality when present."
	point_cost = 1
	incompatible = list(/datum/resurgence_trait/beautiful, /datum/resurgence_trait/ugly, /datum/resurgence_trait/staggeringly_ugly)

/datum/resurgence_trait/pretty/apply(mob/living/carbon/human/H)
	. = ..()
	if(!.)
		return
	H.AddComponent(/datum/component/resurgence_beauty, 1)

/datum/resurgence_trait/pretty/remove()
	if(holder)
		var/datum/component/resurgence_beauty/B = holder.GetComponent(/datum/component/resurgence_beauty)
		if(B)
			qdel(B)
	return ..()

// ============================================
// Negative Traits
// ============================================

/// Lazy - -15% work speed
/datum/resurgence_trait/lazy
	name = "Lazy"
	desc = "-15% work speed on all tasks."
	point_cost = -2
	incompatible = list(/datum/resurgence_trait/industrious)

/datum/resurgence_trait/lazy/get_modifier(modifier_type)
	if(modifier_type == "work_speed")
		return -0.15
	return 0

/// Slow Learner - -25% XP gain
/datum/resurgence_trait/slow_learner
	name = "Slow Learner"
	desc = "-25% XP gain from all activities."
	point_cost = -2
	incompatible = list(/datum/resurgence_trait/quick_learner)

/datum/resurgence_trait/slow_learner/get_modifier(modifier_type)
	if(modifier_type == "xp_gain")
		return -0.25
	return 0

/// Pessimist - -10 maximum faith
/datum/resurgence_trait/pessimist
	name = "Pessimist"
	desc = "-10 maximum faith (90 instead of 100)."
	point_cost = -2

/datum/resurgence_trait/pessimist/apply(mob/living/carbon/human/H)
	. = ..()
	if(!.)
		return
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(istype(core))
		core.max_faith = 90
		core.faith = min(core.faith, 90)

/datum/resurgence_trait/pessimist/remove()
	if(holder)
		var/obj/item/organ/resurgence_core/core = holder.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			core.max_faith = 100
	return ..()

/// Clumsy - 15% chance to waste 1 material when crafting
/datum/resurgence_trait/clumsy
	name = "Clumsy"
	desc = "15% chance to waste 1 material when crafting."
	point_cost = -1

/datum/resurgence_trait/clumsy/get_modifier(modifier_type)
	if(modifier_type == "craft_waste_chance")
		return 0.15
	return 0

/// Sickly - Faith decreases 20% faster from negative events
/datum/resurgence_trait/sickly
	name = "Sickly"
	desc = "Faith decreases 20% faster from negative events."
	point_cost = -1
	incompatible = list(/datum/resurgence_trait/iron_willed)

/datum/resurgence_trait/sickly/get_modifier(modifier_type)
	if(modifier_type == "faith_loss_increase")
		return 0.20
	return 0

/// Slowpoke - -10% movement speed
/datum/resurgence_trait/slowpoke
	name = "Slowpoke"
	desc = "-10% movement speed."
	point_cost = -1
	incompatible = list(/datum/resurgence_trait/nimble)

/datum/resurgence_trait/slowpoke/apply(mob/living/carbon/human/H)
	. = ..()
	if(!.)
		return
	H.add_movespeed_modifier(/datum/movespeed_modifier/resurgence_slowpoke)

/datum/resurgence_trait/slowpoke/remove()
	if(holder)
		holder.remove_movespeed_modifier(/datum/movespeed_modifier/resurgence_slowpoke)
	return ..()

/// Nervous - -10% work speed when faith below 50
/datum/resurgence_trait/nervous
	name = "Nervous"
	desc = "-10% work speed when faith is below 50."
	point_cost = -1

/datum/resurgence_trait/nervous/get_modifier(modifier_type)
	if(modifier_type == "nervous_penalty")
		if(holder)
			var/obj/item/organ/resurgence_core/core = holder.getorganslot(ORGAN_SLOT_HEART)
			if(istype(core) && core.faith < 50)
				return -0.10
	return 0

/// Ugly - -2 beauty component on character
/datum/resurgence_trait/ugly
	name = "Ugly"
	desc = "Character has a beauty component of -2, reducing room quality when present."
	point_cost = -1
	incompatible = list(/datum/resurgence_trait/beautiful, /datum/resurgence_trait/pretty, /datum/resurgence_trait/staggeringly_ugly)

/datum/resurgence_trait/ugly/apply(mob/living/carbon/human/H)
	. = ..()
	if(!.)
		return
	H.AddComponent(/datum/component/resurgence_beauty, -2)

/datum/resurgence_trait/ugly/remove()
	if(holder)
		var/datum/component/resurgence_beauty/B = holder.GetComponent(/datum/component/resurgence_beauty)
		if(B)
			qdel(B)
	return ..()

/// Staggeringly Ugly - -5 beauty component on character
/datum/resurgence_trait/staggeringly_ugly
	name = "Staggeringly Ugly"
	desc = "Character has a beauty component of -5, significantly reducing room quality."
	point_cost = -2
	incompatible = list(/datum/resurgence_trait/beautiful, /datum/resurgence_trait/pretty, /datum/resurgence_trait/ugly)

/datum/resurgence_trait/staggeringly_ugly/apply(mob/living/carbon/human/H)
	. = ..()
	if(!.)
		return
	H.AddComponent(/datum/component/resurgence_beauty, -5)

/datum/resurgence_trait/staggeringly_ugly/remove()
	if(holder)
		var/datum/component/resurgence_beauty/B = holder.GetComponent(/datum/component/resurgence_beauty)
		if(B)
			qdel(B)
	return ..()

// ============================================
// Mixed Traits (Trade-offs)
// ============================================

/// Too Smart - +50% XP gain but faith decreases 30% faster from negative events
/datum/resurgence_trait/too_smart
	name = "Too Smart"
	desc = "+50% XP gain from all activities, but faith decreases 30% faster from negative events."
	point_cost = 1
	is_mixed = TRUE
	incompatible = list(/datum/resurgence_trait/quick_learner, /datum/resurgence_trait/slow_learner)

/datum/resurgence_trait/too_smart/get_modifier(modifier_type)
	switch(modifier_type)
		if("xp_gain")
			return 0.50
		if("faith_loss_increase")
			return 0.30
	return 0

// ============================================
// Movespeed Modifiers
// ============================================

/// Nimble trait speed bonus
/datum/movespeed_modifier/resurgence_nimble
	multiplicative_slowdown = -0.1

/// Slowpoke trait speed penalty
/datum/movespeed_modifier/resurgence_slowpoke
	multiplicative_slowdown = 0.1

// ============================================
// Beauty Component for Character
// ============================================

/datum/component/resurgence_beauty
	/// Beauty value of this character
	var/beauty_value = 0

/datum/component/resurgence_beauty/Initialize(beauty = 0)
	. = ..()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	beauty_value = beauty

/datum/component/resurgence_beauty/Destroy()
	return ..()

// ============================================
// Helper Procs
// ============================================

/**
 * Get total work speed modifier from all traits
 */
/proc/get_trait_work_speed_modifier(mob/living/carbon/human/H)
	if(!H)
		return 1.0

	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return 1.0

	var/modifier = 0
	for(var/datum/resurgence_trait/T in core.applied_traits)
		modifier += T.get_modifier("work_speed")
		modifier += T.get_modifier("nervous_penalty")

	return 1.0 + modifier

/**
 * Get total XP gain modifier from all traits
 */
/proc/get_trait_xp_modifier(mob/living/carbon/human/H)
	if(!H)
		return 1.0

	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return 1.0

	var/modifier = 0
	for(var/datum/resurgence_trait/T in core.applied_traits)
		modifier += T.get_modifier("xp_gain")

	return 1.0 + modifier

/**
 * Get total faith loss modifier from all traits
 * Returns a multiplier (1.0 = normal, 1.2 = 20% more loss, 0.8 = 20% less loss)
 */
/proc/get_trait_faith_loss_modifier(mob/living/carbon/human/H)
	if(!H)
		return 1.0

	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return 1.0

	var/reduction = 0
	var/increase = 0
	for(var/datum/resurgence_trait/T in core.applied_traits)
		reduction += T.get_modifier("faith_loss_reduction")
		increase += T.get_modifier("faith_loss_increase")

	return 1.0 + increase - reduction

/**
 * Get harvest yield modifier from traits
 */
/proc/get_trait_harvest_modifier(mob/living/carbon/human/H)
	if(!H)
		return 1.0

	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return 1.0

	var/modifier = 0
	for(var/datum/resurgence_trait/T in core.applied_traits)
		modifier += T.get_modifier("harvest_yield")

	return 1.0 + modifier

/**
 * Get crafting beauty bonus from traits
 */
/proc/get_trait_craft_beauty_bonus(mob/living/carbon/human/H)
	if(!H)
		return 0

	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return 0

	var/bonus = 0
	for(var/datum/resurgence_trait/T in core.applied_traits)
		bonus += T.get_modifier("craft_beauty")

	return bonus

/**
 * Get tool quality bonus from traits
 */
/proc/get_trait_tool_quality_bonus(mob/living/carbon/human/H)
	if(!H)
		return 0

	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return 0

	var/bonus = 0
	for(var/datum/resurgence_trait/T in core.applied_traits)
		bonus += T.get_modifier("tool_quality")

	return bonus

/**
 * Check if crafting will waste material due to Clumsy trait
 */
/proc/check_trait_craft_waste(mob/living/carbon/human/H)
	if(!H)
		return FALSE

	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return FALSE

	for(var/datum/resurgence_trait/T in core.applied_traits)
		var/waste_chance = T.get_modifier("craft_waste_chance")
		if(waste_chance > 0 && prob(waste_chance * 100))
			return TRUE

	return FALSE

/**
 * Check if character has the Kind trait and can give comfort
 */
/proc/check_kind_hug_available(mob/living/carbon/human/H)
	if(!H)
		return FALSE

	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return FALSE

	for(var/datum/resurgence_trait/kind/K in core.applied_traits)
		if(world.time >= K.next_hug_time)
			return TRUE

	return FALSE

/**
 * Apply the Kind trait's hug effect to a target
 */
/proc/apply_kind_hug(mob/living/carbon/human/hugger, mob/living/carbon/human/target)
	if(!hugger || !target)
		return FALSE

	var/obj/item/organ/resurgence_core/hugger_core = hugger.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(hugger_core))
		return FALSE

	// Find Kind trait
	var/datum/resurgence_trait/kind/kind_trait = null
	for(var/datum/resurgence_trait/kind/K in hugger_core.applied_traits)
		kind_trait = K
		break

	if(!kind_trait || world.time < kind_trait.next_hug_time)
		return FALSE

	// Apply faith bonus to target
	var/obj/item/organ/resurgence_core/target_core = target.getorganslot(ORGAN_SLOT_HEART)
	if(istype(target_core))
		var/datum/faith_event/kind_hug/event = new(
			"Comforted by a friend.",
			0.2,  // +0.2 faith per 5 seconds
			1 MINUTES,
			"kind_hug"
		)
		target_core.add_faith_event("kind_hug", event)
		to_chat(target, span_notice("You feel comforted by [hugger]'s kindness."))

	// Set cooldown
	kind_trait.next_hug_time = world.time + 1 MINUTES
	to_chat(hugger, span_notice("You offer comfort to [target]."))

	return TRUE

// ============================================
// Faith Event for Kind Trait
// ============================================

/datum/faith_event/kind_hug
