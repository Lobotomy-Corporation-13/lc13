// Base Ring Skill Component
// All ring skills inherit from this

/datum/component/ring_skill
	/// Name of the skill
	var/skill_name = "Base Skill"
	/// Description of the skill
	var/skill_desc = "A ring skill."
	/// Which school this skill belongs to
	var/school = "corporist"
	/// Which tier (1-3)
	var/tier = 1
	/// Which choice (a or b)
	var/choice = "a"

	/// Reference to the human parent
	var/mob/living/carbon/human/human_parent

/datum/component/ring_skill/Initialize()
	. = ..()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	human_parent = parent

/datum/component/ring_skill/RegisterWithParent()
	. = ..()
	// Common signals that most skills will use
	RegisterSignal(parent, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_attack))
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_take_damage))
	RegisterSignal(parent, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(on_after_take_damage))

/datum/component/ring_skill/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_MOB_ITEM_ATTACK,
		COMSIG_MOB_APPLY_DAMGE,
		COMSIG_MOB_AFTER_APPLY_DAMGE
	))
	human_parent = null
	. = ..()

/// Called when the parent attacks something with an item
/datum/component/ring_skill/proc/on_attack(datum/source, mob/living/target, obj/item/weapon)
	SIGNAL_HANDLER
	return

/// Called when the parent is about to take damage
/datum/component/ring_skill/proc/on_take_damage(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	return

/// Called after the parent takes damage
/// Signal args: final_damage, damage_type, def_zone, wound_bonus, bare_wound_bonus, sharpness, attacker, flags, attack_type
/datum/component/ring_skill/proc/on_after_take_damage(datum/source, damage, damagetype, def_zone, wound_bonus, bare_wound_bonus, sharpness, atom/attacker, flags, attack_type)
	SIGNAL_HANDLER
	return

/// Helper to check if target is bleeding
/datum/component/ring_skill/proc/target_is_bleeding(mob/living/target)
	return !!target.has_status_effect(/datum/status_effect/stacking/lc_bleed)

/// Helper to get bleed stacks on target
/datum/component/ring_skill/proc/get_bleed_stacks(mob/living/target)
	var/datum/status_effect/stacking/lc_bleed/bleed = target.has_status_effect(/datum/status_effect/stacking/lc_bleed)
	if(!bleed)
		return 0
	return bleed.stacks

/// Helper to count status effects on target
/datum/component/ring_skill/proc/count_status_effects(mob/living/target)
	var/count = 0
	if(target.has_status_effect(/datum/status_effect/stacking/lc_bleed))
		count++
	if(target.has_status_effect(/datum/status_effect/stacking/lc_overheat))
		count++
	if(target.has_status_effect(/datum/status_effect/stacking/lc_tremor))
		count++
	if(target.has_status_effect(/datum/status_effect/stacking/lc_mental_decay))
		count++
	return count

/// Helper to apply random status effect
/datum/component/ring_skill/proc/apply_random_effect(mob/living/target, stacks = 1)
	var/effect_type = pick("bleed", "overheat", "tremor", "mental_decay")
	switch(effect_type)
		if("bleed")
			target.apply_lc_bleed(stacks)
		if("overheat")
			target.apply_lc_overheat(stacks)
		if("tremor")
			target.apply_lc_tremor(stacks)
		if("mental_decay")
			target.apply_lc_mental_decay(stacks)
	return effect_type

/// Helper to check if target has a specific effect
/datum/component/ring_skill/proc/has_effect(mob/living/target, effect_type)
	switch(effect_type)
		if("bleed")
			return !!target.has_status_effect(/datum/status_effect/stacking/lc_bleed)
		if("overheat")
			return !!target.has_status_effect(/datum/status_effect/stacking/lc_overheat)
		if("tremor")
			return !!target.has_status_effect(/datum/status_effect/stacking/lc_tremor)
		if("mental_decay")
			return !!target.has_status_effect(/datum/status_effect/stacking/lc_mental_decay)
	return FALSE
