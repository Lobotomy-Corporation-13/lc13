/// Emergency status effect granted to association members during distress.
/// Enables skill tree abilities for 60 seconds without a contract.
/// No EXP is awarded during emergency — it's a defensive safety net.
/datum/status_effect/association_emergency
	id = "association_emergency"
	duration = CONTRACT_DISTRESS_DURATION
	tick_interval = -1
	alert_type = null

/datum/status_effect/association_emergency/on_apply()
	. = ..()
	to_chat(owner, span_boldwarning("EMERGENCY: Skill tree abilities temporarily activated for [CONTRACT_DISTRESS_DURATION / 10] seconds!"))

/datum/status_effect/association_emergency/on_remove()
	to_chat(owner, span_warning("Emergency skill access has expired."))
	return ..()
