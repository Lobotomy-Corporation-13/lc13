/// Base contract datum. Holds all shared contract data: type, payment, target, duration, EXP.
/// Subtyped per contract type (e.g., escort_person, eliminate_target).
/datum/association_contract
	/// Unique contract ID (auto-generated)
	var/contract_id
	/// Human-readable contract name (e.g., "Escort Person")
	var/contract_name = "Contract"
	/// Internal contract type string (e.g., "escort_person")
	var/contract_type = "generic"
	/// Category: CONTRACT_CATEGORY_DURATION or CONTRACT_CATEGORY_OBJECTIVE
	var/category = CONTRACT_CATEGORY_DURATION
	/// Current state: pending, active, completed, failed
	var/state = CONTRACT_STATE_PENDING
	/// Source: CONTRACT_SOURCE_HANA or CONTRACT_SOURCE_CIVILIAN
	var/source = CONTRACT_SOURCE_HANA
	/// Which association type this contract is for (or null for universal)
	var/association_type

	// --- Payment ---
	/// Total payment amount in Ahn
	var/payment_amount = 0
	/// Reference to the issuer's bank account (for refunds)
	var/datum/bank_account/issuer_account
	/// Reference to the mob who created the contract
	var/mob/living/issuer_mob
	/// Reference to the mob who accepted the contract (for payment on completion)
	var/mob/living/acceptor_mob

	// --- Target ---
	/// Target mob (for person-targeting contracts)
	var/mob/living/target_mob
	/// Target location turf (for location-based contracts)
	var/turf/target_location

	// --- Duration ---
	/// Duration tier constant (CONTRACT_TIER_SHORT/MEDIUM/LONG) or 0 for objective
	var/duration_tier = 0
	/// Total contract duration in deciseconds
	var/total_duration = 0
	/// Remaining time in deciseconds (ticks down for duration contracts)
	var/remaining_time = 0
	/// Whether the timer is currently paused (e.g., no fixer in proximity)
	var/timer_paused = FALSE
	/// Timer ID for the looping tick timer (for deltimer cleanup)
	var/tick_timer_id

	// --- EXP ---
	/// Total passive EXP accumulated during this contract
	var/passive_exp_accumulated = 0
	/// Completion EXP bonus for this contract
	var/completion_exp = 0

	// --- Tracking ---
	/// Reference to the squad this contract is assigned to
	var/datum/association_squad/squad
	/// world.time when the contract was accepted
	var/accept_time = 0
	/// world.time when the contract completed
	var/complete_time = 0

	/// Debug mode — allows fixers to accept this contract
	var/debug_mode = FALSE

	// --- Zone Visualization ---
	/// Zone effect objects spawned for this contract
	var/list/zone_effects
	/// Image objects added to squad client.images (for cleanup)
	var/list/zone_images

	/// Static incrementing counter for unique IDs
	var/static/next_contract_id = 1

/datum/association_contract/New(_contract_type, _source, _payment, mob/living/_issuer, _assoc_type)
	. = ..()
	contract_id = next_contract_id++
	if(_contract_type)
		contract_type = _contract_type
	if(_source)
		source = _source
	if(_payment)
		payment_amount = _payment
	if(_issuer)
		issuer_mob = _issuer
		// Try to find issuer's bank account from their ID card
		if(ishuman(_issuer))
			var/mob/living/carbon/human/H = _issuer
			var/obj/item/card/id/ID = H.get_idcard(TRUE)
			if(ID?.registered_account)
				issuer_account = ID.registered_account
	if(_assoc_type)
		association_type = _assoc_type
	// Set completion EXP based on category and tier
	set_completion_exp()

/datum/association_contract/Destroy()
	cleanup_zones()
	if(state == CONTRACT_STATE_ACTIVE)
		stop_timers()
		if(squad)
			squad.remove_contract(src)
	issuer_account = null
	issuer_mob = null
	acceptor_mob = null
	target_mob = null
	target_location = null
	squad = null
	return ..()

/// Set the duration tier and calculate total duration + completion EXP.
/datum/association_contract/proc/set_duration_tier(tier)
	duration_tier = tier
	total_duration = tier
	remaining_time = tier
	category = CONTRACT_CATEGORY_DURATION
	set_completion_exp()

/// Calculate completion EXP based on category and tier.
/datum/association_contract/proc/set_completion_exp()
	if(category == CONTRACT_CATEGORY_OBJECTIVE)
		completion_exp = CONTRACT_COMPLETION_OBJECTIVE
		return
	switch(duration_tier)
		if(CONTRACT_TIER_SHORT)
			completion_exp = CONTRACT_COMPLETION_SHORT
		if(CONTRACT_TIER_MEDIUM)
			completion_exp = CONTRACT_COMPLETION_MEDIUM
		if(CONTRACT_TIER_LONG)
			completion_exp = CONTRACT_COMPLETION_LONG
		else
			completion_exp = CONTRACT_COMPLETION_SHORT

/// Returns the EXP multiplier based on contract source.
/datum/association_contract/proc/get_exp_multiplier()
	if(source == CONTRACT_SOURCE_CIVILIAN)
		return CONTRACT_CIVILIAN_EXP_MULT
	return 1

/// Activate this contract — register with a squad and start timers.
/datum/association_contract/proc/activate(datum/association_squad/_squad)
	if(state != CONTRACT_STATE_PENDING)
		return FALSE
	if(!_squad)
		return FALSE
	state = CONTRACT_STATE_ACTIVE
	squad = _squad
	accept_time = world.time
	squad.add_contract(src)
	start_timers()
	return TRUE

/// Start the tick timer for duration-based contracts.
/datum/association_contract/proc/start_timers()
	if(category == CONTRACT_CATEGORY_DURATION && total_duration > 0)
		tick_timer_id = addtimer(CALLBACK(src, PROC_REF(tick)), CONTRACT_PASSIVE_INTERVAL, TIMER_STOPPABLE | TIMER_LOOP)

/// Stop all timers. Called on complete/fail/cancel/destroy.
/datum/association_contract/proc/stop_timers()
	if(tick_timer_id)
		deltimer(tick_timer_id)
		tick_timer_id = null

/// Called every CONTRACT_PASSIVE_INTERVAL for duration contracts.
/// Override in subtypes to add pause conditions (e.g., proximity checks).
/datum/association_contract/proc/tick()
	if(state != CONTRACT_STATE_ACTIVE)
		stop_timers()
		return
	// Check pause condition (overridden by subtypes)
	if(should_pause())
		timer_paused = TRUE
		return
	timer_paused = FALSE
	// Decrement remaining time
	remaining_time -= CONTRACT_PASSIVE_INTERVAL
	// Award passive EXP to all squad members
	if(squad)
		var/exp_amount = CONTRACT_PASSIVE_EXP_TICK * get_exp_multiplier()
		squad.award_exp_to_all(exp_amount)
		passive_exp_accumulated += exp_amount
	// Check completion
	if(remaining_time <= 0)
		remaining_time = 0
		complete()

/// Override in subtypes to define pause conditions (e.g., no fixer near target).
/// Returns TRUE if the timer should pause this tick.
/datum/association_contract/proc/should_pause()
	return FALSE

/// Complete the contract — award completion EXP, pay the squad, clean up.
/datum/association_contract/proc/complete()
	if(state != CONTRACT_STATE_ACTIVE)
		return
	state = CONTRACT_STATE_COMPLETED
	complete_time = world.time
	stop_timers()
	cleanup_zones()
	// Pay all squad members evenly
	pay_squad()
	// Award completion EXP bonus
	if(squad)
		var/bonus = completion_exp * get_exp_multiplier()
		squad.award_exp_to_all(bonus)
		for(var/mob/living/M in squad.members)
			to_chat(M, span_nicegreen("Contract \"[contract_name]\" completed! +[bonus] EXP bonus."))
		squad.remove_contract(src)

/// Pay the contract payment evenly to all squad members' bank accounts.
/datum/association_contract/proc/pay_squad()
	if(!squad || payment_amount <= 0)
		return
	var/member_count = max(length(squad.members), 1)
	var/split = round(payment_amount / member_count)
	if(split <= 0)
		return
	for(var/mob/living/carbon/human/H in squad.members)
		var/obj/item/card/id/ID = H.get_idcard(TRUE)
		if(!ID?.registered_account)
			to_chat(H, span_warning("Payment could not be deposited — no bank account found on your ID."))
			continue
		ID.registered_account.adjust_money(split)
		to_chat(H, span_nicegreen("[split] Ahn deposited (split [member_count] ways) for completing \"[contract_name]\"."))


/// Fail the contract — no EXP, no refund.
/datum/association_contract/proc/fail()
	if(state != CONTRACT_STATE_ACTIVE)
		return
	state = CONTRACT_STATE_FAILED
	complete_time = world.time
	stop_timers()
	cleanup_zones()
	if(squad)
		for(var/mob/living/M in squad.members)
			to_chat(M, span_warning("Contract \"[contract_name]\" has failed."))
		squad.remove_contract(src)

/// Cancel and refund a contract. Works on both pending and active contracts.
/datum/association_contract/proc/cancel()
	if(state != CONTRACT_STATE_PENDING && state != CONTRACT_STATE_ACTIVE)
		return FALSE
	var/was_active = (state == CONTRACT_STATE_ACTIVE)
	state = CONTRACT_STATE_FAILED
	// Refund issuer
	if(issuer_account && payment_amount > 0)
		issuer_account.adjust_money(payment_amount)
		if(issuer_mob)
			to_chat(issuer_mob, span_notice("[payment_amount] Ahn refunded for cancelled contract \"[contract_name]\"."))
	// Clean up active contract state
	if(was_active)
		stop_timers()
		cleanup_zones()
		if(squad)
			for(var/mob/living/M in squad.members)
				to_chat(M, span_warning("Contract \"[contract_name]\" has been cancelled. The issuer has been refunded."))
			squad.remove_contract(src)
	qdel(src)
	return TRUE

/// Returns a human-readable status string for display.
/datum/association_contract/proc/get_status_text()
	switch(state)
		if(CONTRACT_STATE_PENDING)
			return "Awaiting acceptance"
		if(CONTRACT_STATE_ACTIVE)
			if(category == CONTRACT_CATEGORY_DURATION)
				var/time_text = DisplayTimeText(remaining_time)
				if(timer_paused)
					return "[time_text] remaining (PAUSED)"
				return "[time_text] remaining"
			return "In progress"
		if(CONTRACT_STATE_COMPLETED)
			return "Completed"
		if(CONTRACT_STATE_FAILED)
			return "Failed"
	return "Unknown"

/// Returns the human-readable tier name.
/datum/association_contract/proc/get_tier_name()
	switch(duration_tier)
		if(CONTRACT_TIER_SHORT)
			return "Short (6 min)"
		if(CONTRACT_TIER_MEDIUM)
			return "Medium (10 min)"
		if(CONTRACT_TIER_LONG)
			return "Long (20 min)"
	return "N/A"

// ============================================================
// Zone Visualization
// ============================================================

/// Show a zone effect to all squad members via client.images.
/datum/association_contract/proc/show_zone_to_squad(obj/effect/contract_zone/zone)
	if(!squad)
		return
	LAZYINITLIST(zone_images)
	for(var/mob/living/M in squad.members)
		if(!M.client)
			continue
		var/image/I = image(zone.icon, zone, zone.icon_state, zone.layer)
		M.client.images |= I
		zone_images += I

/// Show all existing zone effects to a single mob (for late-joining squad members).
/datum/association_contract/proc/show_existing_zones_to_mob(mob/living/M)
	if(!M?.client)
		return
	if(!LAZYLEN(zone_effects))
		return
	LAZYINITLIST(zone_images)
	for(var/obj/effect/contract_zone/zone in zone_effects)
		var/image/I = image(zone.icon, zone, zone.icon_state, zone.layer)
		M.client.images |= I
		zone_images += I

/// Remove all zone images from squad clients and delete zone effects.
/datum/association_contract/proc/cleanup_zones()
	if(squad)
		for(var/mob/living/M in squad.members)
			if(!M.client)
				continue
			for(var/image/I in zone_images)
				M.client.images -= I
	LAZYCLEARLIST(zone_images)
	for(var/obj/effect/contract_zone/Z in zone_effects)
		qdel(Z)
	LAZYCLEARLIST(zone_effects)

/// Returns an assoc list of display data for TGUI.
/datum/association_contract/proc/get_display_data()
	var/list/data = list()
	data["contract_id"] = contract_id
	data["contract_name"] = contract_name
	data["contract_type"] = contract_type
	data["category"] = category
	data["state"] = state
	data["source"] = source
	data["payment"] = payment_amount
	data["issuer"] = issuer_mob ? issuer_mob.name : "Unknown"
	data["target"] = target_mob ? target_mob.name : "None"
	data["tier_name"] = get_tier_name()
	data["total_duration"] = total_duration
	data["remaining_time"] = remaining_time
	data["timer_paused"] = timer_paused
	data["status_text"] = get_status_text()
	data["completion_exp"] = completion_exp
	data["exp_multiplier"] = get_exp_multiplier()
	return data
