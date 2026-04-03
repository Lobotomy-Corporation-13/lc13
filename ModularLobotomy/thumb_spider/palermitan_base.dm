/// Palermitan Apprentice Base Component
/// Grants the "Duello" and "Palermitan Style" base passives.
/// Attached to the apprentice mob on recruitment.
/datum/component/palermitan_apprentice
	/// Reference to the nursefather mentor
	var/mob/living/nursefather_ref
	/// How many times the nursefather has corrected the apprentice after a duel loss
	var/correction_count = 0
	/// Whether the apprentice is currently eligible for a post-duel correction
	var/correction_eligible = FALSE
	/// world.time deadline for correction eligibility
	var/correction_deadline = 0
	/// Attribute gain that would be granted by a correction (0.25x of the lost duel's win value)
	var/potential_correction_attrs = 0

/datum/component/palermitan_apprentice/Initialize(mob/living/_nursefather)
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	if(_nursefather)
		nursefather_ref = _nursefather

/datum/component/palermitan_apprentice/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_attack))

/datum/component/palermitan_apprentice/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_ITEM_ATTACK)

/// Core attack handler — applies Duello and Palermitan Style passives
/datum/component/palermitan_apprentice/proc/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	SIGNAL_HANDLER
	if(!isliving(target) || target == user)
		return

	// === DUELLO: Inflict 1 Duel Escalates on target ===
	target.apply_duel_escalates(1, user)

	// === DUELLO: Heal sanity if target has Duel Escalates ===
	var/datum/status_effect/stacking/duel_escalates/D = target.has_status_effect(/datum/status_effect/stacking/duel_escalates)
	if(D && D.stacks > 0 && ishuman(user))
		var/sanity_heal = min(D.stacks * 3, 15)
		var/mob/living/carbon/human/H = user
		H.adjustSanityLoss(-sanity_heal)

	// === PALERMITAN STYLE: Bonus damage based on Duel Escalates stacks ===
	// This modifies the weapon's force temporarily for this hit.
	// The force bonus is applied before the hit resolves (COMSIG_MOB_ITEM_ATTACK fires before damage).
	if(D && D.stacks > 0 && weapon)
		var/stacks = D.stacks
		// +5% damage per stack (applied as force bonus)
		var/percent_bonus = stacks * 0.05
		var/force_bonus = round(weapon.force * percent_bonus)
		// Flat force bonus at thresholds
		if(stacks >= 10)
			force_bonus += 10
		else if(stacks >= 5)
			force_bonus += 5
		if(force_bonus > 0)
			weapon.force += force_bonus
			// Schedule force restoration after the attack resolves
			INVOKE_ASYNC(src, PROC_REF(restore_force), weapon, force_bonus)

/// Restores the temporary force bonus after a brief delay
/datum/component/palermitan_apprentice/proc/restore_force(obj/item/weapon, bonus)
	if(!QDELETED(weapon))
		weapon.force -= bonus
