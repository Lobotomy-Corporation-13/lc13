/// Shared cutscene duel component — prevents outside damage during powerful attack combos.
/// Attach to the combo target, specifying the attacker. All damage from sources
/// other than the designated attacker is denied for the duration.
/// Used by both Seven and Zwei T3 powerful attacks.
/datum/component/cutscene_duel
	/// The mob performing the combo (the only one allowed to deal damage)
	var/mob/living/attacker
	/// Safety timer ID for auto-cleanup
	var/safety_timer_id

/datum/component/cutscene_duel/Initialize(mob/living/_attacker, max_duration = 10 SECONDS)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	attacker = _attacker
	// Safety timer to auto-remove if not cleaned up by the combo
	safety_timer_id = addtimer(CALLBACK(src, PROC_REF(safety_cleanup)), max_duration, TIMER_STOPPABLE)

/datum/component/cutscene_duel/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_damage_check))

/datum/component/cutscene_duel/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_APPLY_DAMGE)
	. = ..()

/datum/component/cutscene_duel/Destroy()
	if(safety_timer_id)
		deltimer(safety_timer_id)
		safety_timer_id = null
	attacker = null
	return ..()

/// Block damage from anyone except the designated attacker.
/datum/component/cutscene_duel/proc/on_damage_check(datum/source, damage, damagetype, def_zone, atom/damage_source)
	SIGNAL_HANDLER
	if(damage_source == attacker)
		return
	return COMPONENT_MOB_DENY_DAMAGE

/// Safety cleanup — remove self if the combo didn't clean up properly.
/datum/component/cutscene_duel/proc/safety_cleanup()
	safety_timer_id = null
	qdel(src)
