// A Mirae policy: what a client bought, and whether they are still paying for
// it.
//
// `state` is the miss counter. There is no separate count and no separate
// grace timer, because the grace window is exactly one tick by construction,
// and a second timer would be a second source of truth that drifts out of step
// with the first.
//
// Nothing here ever takes money on its own. A renewal is a person walking back
// to a terminal and paying, which is why `prepaid` is the only record of how
// far ahead they are and why the countdown a client is shown is read straight
// off the upkeep timer rather than tracked beside it.

/datum/mirae_policy
	var/datum/mirae_ledger/ledger
	/// MIRAE_ADDON_* bitfield of what they bought.
	var/addons = NONE
	/// Recomputed whenever addons change.
	var/premium = 0
	var/state = MIRAE_POLICY_ACTIVE
	/// Periods paid for beyond the current one. The up-front purchase buys the
	/// period it is made in, so a new policy starts at none in hand.
	var/prepaid = 0
	/// Set by the client asking to stop. Cover runs to the end of what they
	/// have already paid for and then lapses, so cancelling never burns money
	/// they have already handed over.
	var/cancelled = FALSE
	/// Free sleeper injections left this period, on Basic Treatment.
	var/covered_injections = 0
	var/timer_id

/datum/mirae_policy/New(datum/mirae_ledger/L, starting_addons)
	. = ..()
	ledger = L
	addons = starting_addons
	Recalc()
	timer_id = addtimer(CALLBACK(src, PROC_REF(Tick)), MIRAE_UPKEEP_INTERVAL, TIMER_STOPPABLE|TIMER_LOOP)

/datum/mirae_policy/Destroy()
	if(timer_id)
		deltimer(timer_id)
		timer_id = null
	ledger = null
	return ..()

/// Renewal price and allowances follow whatever is currently held. A renewal
/// is the purchase price again, so this is the same sum BuyPolicy charges.
/datum/mirae_policy/proc/Recalc()
	premium = 0
	if(addons & MIRAE_ADDON_DEATH)
		premium += MIRAE_PRICE_DEATH
	if(addons & MIRAE_ADDON_BASIC)
		premium += MIRAE_PRICE_BASIC
	if(addons & MIRAE_ADDON_SURGERY)
		premium += MIRAE_PRICE_SURGERY
	covered_injections = (addons & MIRAE_ADDON_BASIC) ? MIRAE_BASIC_INJECTIONS : 0

/// Deciseconds until the next payment falls due.
///
/// Read off the upkeep timer rather than kept as a second timestamp, so the
/// countdown a client is shown and the deadline they are actually held to
/// cannot disagree. Periods paid ahead are whole ticks, so they simply add on.
/datum/mirae_policy/proc/TimeToDue()
	if(!timer_id)
		return 0
	return max(0, timeleft(timer_id)) + prepaid * MIRAE_UPKEEP_INTERVAL

/// The only place a policy is consulted. Called from the ledger's Charge().
///
/// Grace does not cover. Somebody in grace is somebody who did not pay, and
/// waiving during grace would make the grace window strictly free.
/datum/mirae_policy/proc/CoversService(service_tag)
	if(state != MIRAE_POLICY_ACTIVE)
		return FALSE
	switch(service_tag)
		if(MIRAE_SERVICE_SLEEPER)
			// The one allowance that is metered rather than a flag. Counted
			// here rather than at the sleeper so a second capped service later
			// does not need its own bookkeeping somewhere else.
			if(!(addons & MIRAE_ADDON_BASIC) || covered_injections <= 0)
				return FALSE
			covered_injections--
			return TRUE
		if(MIRAE_SERVICE_SURGERY)
			return addons & MIRAE_ADDON_SURGERY
		if(MIRAE_SERVICE_REGEN, MIRAE_SERVICE_REVIVE)
			return addons & MIRAE_ADDON_DEATH
	return FALSE

/// The deadline arriving. Nothing is drafted here - the only question is
/// whether the client came back and paid before it.
/datum/mirae_policy/proc/Tick()
	covered_injections = (addons & MIRAE_ADDON_BASIC) ? MIRAE_BASIC_INJECTIONS : 0
	// Checked before the cancellation, so a client who paid ahead and then
	// cancelled still gets every period they handed money over for.
	if(prepaid > 0)
		prepaid--
		return
	if(cancelled)
		ledger.Notify(span_notice("Mirae: your cancelled policy has run out."))
		Lapse()
		return
	switch(state)
		if(MIRAE_POLICY_ACTIVE)
			state = MIRAE_POLICY_GRACE
			ledger.Notify(span_userdanger("MIRAE: RENEWAL UNPAID. Your policy is in grace for one \
				period. Pay at a Mirae terminal or coverage lapses."))
		if(MIRAE_POLICY_GRACE)
			Lapse()

/// Paying at a terminal. The only way a policy is ever charged for upkeep.
///
/// No ID card is wanted. The account number was taken off the card at purchase
/// and has been on the ledger ever since, which is the whole point of keying
/// identity to the mind: a client who was rebuilt out of a brain, or robbed of
/// their wallet, can still pay what they owe.
/datum/mirae_policy/proc/Renew(periods = 1)
	if(periods <= 0 || cancelled)
		return FALSE
	var/datum/bank_account/A = ledger?.GetAccount()
	if(!A || !MiraeCollect(A, premium * periods, "renewal from [ledger.holder_name]"))
		return FALSE
	if(state == MIRAE_POLICY_GRACE)
		// The first period settles the miss rather than buying future cover.
		state = MIRAE_POLICY_ACTIVE
		ledger.Notify(span_nicegreen("Mirae: renewal received. Your policy is current again."))
		periods--
	prepaid += periods
	return TRUE

/// The client asking to stop, or changing their mind. Deliberately not a
/// refund and deliberately not immediate: they keep what they paid for.
/datum/mirae_policy/proc/SetCancelled(want)
	if(cancelled == want)
		return
	cancelled = want
	if(cancelled)
		ledger.Notify(span_warning("Mirae: cancellation logged. Cover ends when the current \
			period does. Nothing further will be charged."))
	else
		ledger.Notify(span_nicegreen("Mirae: cancellation withdrawn."))

/datum/mirae_policy/proc/Lapse()
	if(timer_id)
		deltimer(timer_id)
		timer_id = null
	state = MIRAE_POLICY_LAPSED
	ledger.Notify(span_userdanger("MIRAE: YOUR POLICY HAS LAPSED. Coverage is withdrawn."))
	var/datum/mirae_ledger/L = ledger
	L.policy = null
	qdel(src)

/// Human-readable list of what is held, for a terminal or a tracker.
/datum/mirae_policy/proc/AddonText()
	var/list/held = list()
	if(addons & MIRAE_ADDON_DEATH)
		held += "Death"
	if(addons & MIRAE_ADDON_BASIC)
		held += "Treatment"
	if(addons & MIRAE_ADDON_SURGERY)
		held += "Surgery"
	return length(held) ? held.Join(", ") : "none"

/// Buy or extend cover. Charges only for what they do not already hold, so
/// amending a policy never bills twice for the same add-on.
///
/// The payer comes from the card in their hand, not from the ledger, because
/// opening an account is the one thing the company will not do on trust. Its
/// number is kept afterwards, and that is what every later renewal pays from.
/datum/mirae_ledger/proc/BuyPolicy(wanted, datum/bank_account/payer)
	var/held = policy ? policy.addons : NONE
	var/adding = wanted & ~held
	if(!adding || !payer)
		return FALSE
	var/cost = 0
	if(adding & MIRAE_ADDON_DEATH)
		cost += MIRAE_PRICE_DEATH
	if(adding & MIRAE_ADDON_BASIC)
		cost += MIRAE_PRICE_BASIC
	if(adding & MIRAE_ADDON_SURGERY)
		cost += MIRAE_PRICE_SURGERY
	if(!MiraeCollect(payer, cost, "new policy for [holder_name]"))
		return FALSE
	account_id = payer.account_id
	if(policy)
		policy.addons |= adding
		policy.Recalc()
	else
		policy = new(src, adding)
	Notify(span_nicegreen("Mirae policy active: [policy.AddonText()]. Renewals are billed to \
		this account and need no card."))
	return TRUE
