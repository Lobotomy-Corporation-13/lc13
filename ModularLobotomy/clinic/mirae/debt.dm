// The Debt a client runs up with the clinic.
//
// This is a display of the ledger, not the ledger. Nothing reads it to decide
// anything; the gate and the tracker both go through MiraeDebtOf(). It exists
// so a debtor can see what they owe without walking to a terminal.

/datum/status_effect/stacking/mirae_debt
	id = "mirae_debt"
	status_type = STATUS_EFFECT_MULTIPLE
	duration = -1
	// Never processes. A positive tick_interval would make the stacking parent
	// decay it, and worse, qdel it the moment the owner died - which is the one
	// state a debt most needs to survive.
	tick_interval = -1
	stacks = 0
	stack_decay = 0
	max_stacks = MIRAE_DEBT_MAX
	consumed_on_threshold = FALSE
	alert_type = /atom/movable/screen/alert/status_effect/mirae_debt
	// Left null on purpose. The over-head badge renders at most two digits and
	// a debt runs to five, so the figure goes in the alert tooltip instead.
	stacking_display_name = null

// Corpses carry debt. They are the main case, in fact - the regenerator bills
// bodies that are still dead. The stacking parent refuses both of these for
// anything DEAD, so both have to be opened up.
/datum/status_effect/stacking/mirae_debt/can_have_status()
	return TRUE

/datum/status_effect/stacking/mirae_debt/can_gain_stacks()
	return TRUE

/datum/status_effect/stacking/mirae_debt/add_stacks(stacks_added)
	. = ..()
	if(linked_alert)
		linked_alert.desc = "[initial(linked_alert.desc)][stacks] ahn."

/atom/movable/screen/alert/status_effect/mirae_debt
	name = "Outstanding Balance"
	desc = "Mirae Life Insurance is owed "
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "mirae_debt"

/// Set the visible balance to match the ledger. Called by the ledger's Sync,
/// never by a biller.
/mob/living/proc/apply_lc_mirae_debt(amount)
	var/datum/status_effect/stacking/mirae_debt/D = has_status_effect(/datum/status_effect/stacking/mirae_debt)
	if(amount <= 0)
		if(D)
			qdel(D)
		return
	if(!D)
		D = apply_status_effect(/datum/status_effect/stacking/mirae_debt, amount)
		return
	D.add_stacks(amount - D.stacks)
