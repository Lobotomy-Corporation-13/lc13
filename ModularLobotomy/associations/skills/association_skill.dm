/// Base component for all association skills. Registers signal hooks for attack and damage events.
/// Individual skills inherit from this and override on_attack(), on_take_damage(), and/or on_after_take_damage().
/// Mirrors the augment component pattern from augment_components.dm but allows multiple skills per mob.
/datum/component/association_skill
	/// Human-readable skill name
	var/skill_name = "Association Skill"
	/// Skill description
	var/skill_desc = "A base association skill."
	/// Which branch this skill belongs to (e.g., "guardian", "territory", "client")
	var/branch = ""
	/// Tier within the branch (1, 2, or 3)
	var/tier = 1
	/// Choice within the tier ("a" or "b")
	var/choice = "a"
	/// Cached reference to the human parent
	var/mob/living/carbon/human/human_parent

/datum/component/association_skill/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	human_parent = parent

/datum/component/association_skill/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_attack))
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_take_damage))
	RegisterSignal(parent, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(on_after_take_damage))

/datum/component/association_skill/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, list(COMSIG_MOB_ITEM_ATTACK, COMSIG_MOB_APPLY_DAMGE, COMSIG_MOB_AFTER_APPLY_DAMGE))

/datum/component/association_skill/Destroy()
	human_parent = null
	return ..()

/// Called when the parent mob attacks a target with a weapon.
/// Override in subclasses to implement attack-triggered effects.
/datum/component/association_skill/proc/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	SIGNAL_HANDLER

/// Called when the parent mob is about to take damage (before damage is applied).
/// Override in subclasses to implement pre-damage effects.
/datum/component/association_skill/proc/on_take_damage(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER

/// Called after the parent mob has taken damage.
/// Override in subclasses to implement post-damage effects.
/datum/component/association_skill/proc/on_after_take_damage(datum/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER

/// Helper: Check if this skill can be used right now.
/// Returns TRUE if the owner has a squad (skills are always available).
/// All skill subtypes should call this at the start of their on_attack/on_take_damage/on_after_take_damage.
/datum/component/association_skill/proc/can_use_skill()
	var/datum/component/association_exp/exp = human_parent.GetComponent(/datum/component/association_exp)
	if(!exp || !exp.squad)
		return FALSE
	return TRUE

/// Helper: Check if a mob is a designated ally of the skill owner
/datum/component/association_skill/proc/is_designated_ally(mob/living/L)
	var/datum/component/association_exp/exp = human_parent.GetComponent(/datum/component/association_exp)
	if(!exp)
		return FALSE
	return exp.is_designated_ally(L)

/// Helper: Get the parent's association_exp component
/datum/component/association_skill/proc/get_exp_component()
	return human_parent.GetComponent(/datum/component/association_exp)

/// Helper: Check if a mob is in the same association as the skill owner.
/// Used to prevent buffs from self-hits, allied attacks, and allied damage.
/datum/component/association_skill/proc/is_association_member(mob/living/L)
	if(!L || !isliving(L))
		return FALSE
	if(L == human_parent)
		return TRUE
	var/datum/component/association_exp/our_exp = human_parent.GetComponent(/datum/component/association_exp)
	if(!our_exp)
		return FALSE
	var/datum/component/association_exp/their_exp = L.GetComponent(/datum/component/association_exp)
	if(!their_exp)
		return FALSE
	return our_exp.association_type == their_exp.association_type
