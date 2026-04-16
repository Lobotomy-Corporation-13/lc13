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
	/// Bleed stacks to apply to target after damage resolves (applied in on_post_attack)
	var/pending_bleed = 0
	/// Shared SP heal cooldown - keyed by mob ref, shared across all ring skills on the same mob
	var/static/list/sp_heal_cooldowns = list()

/datum/component/ring_skill/Initialize()
	. = ..()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	human_parent = parent

/datum/component/ring_skill/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_NURSEFATHER_RECRUITMENT_OVERRIDE, PROC_REF(on_nursefather_override))
	// Common signals that most skills will use
	RegisterSignal(parent, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_attack))
	RegisterSignal(parent, COMSIG_MOB_ITEM_AFTERATTACK, PROC_REF(on_post_attack))
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_take_damage))
	RegisterSignal(parent, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(on_after_take_damage))

/datum/component/ring_skill/UnregisterFromParent()
	UnregisterSignal(parent, list(
		COMSIG_NURSEFATHER_RECRUITMENT_OVERRIDE,
		COMSIG_MOB_ITEM_ATTACK,
		COMSIG_MOB_ITEM_AFTERATTACK,
		COMSIG_MOB_APPLY_DAMGE,
		COMSIG_MOB_AFTER_APPLY_DAMGE
	))
	human_parent = null
	. = ..()

/datum/component/ring_skill/proc/on_nursefather_override(datum/source, mob/living/recruiter, obj/item/apprentice_recruitment/scroll)
	SIGNAL_HANDLER
	qdel(src)

/// Called when the parent attacks something with an item
/datum/component/ring_skill/proc/on_attack(datum/source, mob/living/target, obj/item/weapon)
	SIGNAL_HANDLER
	return

/// Called after the parent's attack resolves - applies deferred bleed
/datum/component/ring_skill/proc/on_post_attack(datum/source, mob/living/target, obj/item/weapon)
	SIGNAL_HANDLER
	if(pending_bleed > 0 && isliving(target) && target.stat != DEAD)
		target.apply_lc_bleed(pending_bleed)
		pending_bleed = 0

/// Called when the parent is about to take damage
/datum/component/ring_skill/proc/on_take_damage(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	return

/// Called after the parent takes damage
/// Signal args: final_damage, damage_type, def_zone, wound_bonus, bare_wound_bonus, sharpness, attacker, flags, attack_type
/datum/component/ring_skill/proc/on_after_take_damage(datum/source, damage, damagetype, def_zone, wound_bonus, bare_wound_bonus, sharpness, atom/attacker, flags, attack_type)
	SIGNAL_HANDLER
	return

/// Helper to check if user has any positive stacking effect (Protection or Damage Up)
/datum/component/ring_skill/proc/has_positive_effect(mob/living/user)
	if(user.has_status_effect(/datum/status_effect/stacking/protection))
		return TRUE
	if(user.has_status_effect(/datum/status_effect/stacking/damage_up))
		return TRUE
	return FALSE

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

/// Helper to apply random status effect (bleed is deferred to on_post_attack)
/datum/component/ring_skill/proc/apply_random_effect(mob/living/target, stacks = 1)
	var/effect_type = pick("bleed", "overheat", "tremor", "mental_decay")
	switch(effect_type)
		if("bleed")
			pending_bleed += stacks
		if("overheat")
			target.apply_lc_overheat(stacks)
		if("tremor")
			target.apply_lc_tremor(stacks, 999)
		if("mental_decay")
			target.apply_lc_mental_decay(stacks)
	return effect_type

/// Ring-specific: Add protection stacks additively, capped at ring_max
/// Unlike apply_lc_protection which only sets stacks, this actually adds to existing stacks
/datum/component/ring_skill/proc/add_ring_protection(mob/living/user, stacks_to_add, ring_max = 5)
	var/datum/status_effect/stacking/protection/P = user.has_status_effect(/datum/status_effect/stacking/protection)
	if(!P)
		user.apply_status_effect(/datum/status_effect/stacking/protection, min(stacks_to_add, ring_max))
		return
	if(P.stacks >= ring_max)
		return
	var/add_amount = min(stacks_to_add, ring_max - P.stacks)
	P.add_stacks(add_amount)

/// Ring-specific: Add damage up stacks additively, capped at ring_max
/// Unlike apply_lc_strength which only sets stacks, this actually adds to existing stacks
/datum/component/ring_skill/proc/add_ring_strength(mob/living/user, stacks_to_add, ring_max = 5)
	var/datum/status_effect/stacking/damage_up/S = user.has_status_effect(/datum/status_effect/stacking/damage_up)
	if(!S)
		user.apply_status_effect(/datum/status_effect/stacking/damage_up, min(stacks_to_add, ring_max))
		return
	if(S.stacks >= ring_max)
		return
	var/add_amount = min(stacks_to_add, ring_max - S.stacks)
	S.add_stacks(add_amount)

/// Checks if SP healing is ready for this mob (shared across all ring skills)
/datum/component/ring_skill/proc/sp_heal_ready()
	var/ref = REF(human_parent)
	if(sp_heal_cooldowns[ref] && world.time < sp_heal_cooldowns[ref])
		return FALSE
	return TRUE

/// Sets the shared SP heal cooldown for this mob
/datum/component/ring_skill/proc/set_sp_heal_cooldown(cooldown = 1 SECONDS)
	sp_heal_cooldowns[REF(human_parent)] = world.time + cooldown

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
