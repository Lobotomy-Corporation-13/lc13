/// Central tracker for an association squad. Holds member list, association type, and handles registration.
/// Created when the Director uses the association beacon to pick an association.
/datum/association_squad
	/// The association type (ASSOCIATION_ZWEI, ASSOCIATION_SEVEN, etc.)
	var/association_type
	/// Human-readable association name
	var/association_name
	/// The Director mob
	var/mob/living/carbon/human/director
	/// List of all registered members (including Director)
	var/list/mob/living/members = list()
	/// Distress cooldowns per-victim (mob ref = world.time of last trigger)
	var/list/distress_cooldowns = list()
	/// List of all active contracts assigned to this squad
	var/list/datum/association_contract/active_contracts = list()
	/// world.time after which a new contract can be accepted (cooldown after last ends)
	var/contract_cooldown_until = 0
	/// Timer ID for the distress directional arrow effect
	var/distress_arrow_timer
	/// The current distress victim (for arrow pointing)
	var/mob/living/distress_victim

/datum/association_squad/New(assoc_type, mob/living/carbon/human/dir)
	. = ..()
	association_type = assoc_type
	director = dir
	association_name = association_type_to_name(assoc_type)

/datum/association_squad/Destroy()
	// Clean up active contracts
	for(var/datum/association_contract/C in active_contracts)
		C.squad = null
	active_contracts.Cut()
	// Clean up distress arrow timer
	if(distress_arrow_timer)
		deltimer(distress_arrow_timer)
		distress_arrow_timer = null
	distress_victim = null
	director = null
	members.Cut()
	distress_cooldowns.Cut()
	return ..()

/// Register a new member with the squad. Attaches association_exp component and sets up mutual ally designations.
/datum/association_squad/proc/register_member(mob/living/carbon/human/member, rank)
	if(member in members)
		return FALSE
	members += member
	// Attach the EXP component
	member.AddComponent(/datum/component/association_exp, association_type, rank, src)
	// Set up mutual ally designations with all existing members
	var/datum/component/association_exp/new_exp = member.GetComponent(/datum/component/association_exp)
	if(new_exp)
		for(var/mob/living/M in members)
			if(M == member)
				continue
			var/datum/component/association_exp/existing_exp = M.GetComponent(/datum/component/association_exp)
			if(existing_exp)
				existing_exp.designated_allies |= member
			new_exp.designated_allies |= M
	// Show existing contract zone effects to the new member
	for(var/datum/association_contract/C in active_contracts)
		C.show_existing_zones_to_mob(member)
	// Refresh ally indicators and View Allies action for all members
	for(var/mob/living/M in members)
		refresh_ally_indicators(M)
		update_view_allies_action(M)
	return TRUE

/// Spawn association-specific items for a registered member.
/datum/association_squad/proc/spawn_association_items(mob/living/carbon/human/member, rank)
	switch(association_type)
		if(ASSOCIATION_SEVEN)
			var/obj/item/seven_catalog/catalog = new(get_turf(member))
			member.put_in_hands(catalog)
		if(ASSOCIATION_DIECI)
			var/obj/item/dieci_tome/tome = new(get_turf(member))
			tome.owner_ref = WEAKREF(member)
			member.put_in_hands(tome)

// ============================================================
// Contract Management
// ============================================================

/// Returns TRUE if the squad has at least one active contract.
/datum/association_squad/proc/is_on_contract()
	return length(active_contracts) > 0

/// Returns TRUE if the squad can accept a new contract (not on cooldown).
/datum/association_squad/proc/can_accept_contract()
	return world.time >= contract_cooldown_until

/// Add an active contract to the squad. Notifies members if this is the first contract.
/datum/association_squad/proc/add_contract(datum/association_contract/C)
	if(C in active_contracts)
		return
	var/was_off_contract = !is_on_contract()
	active_contracts += C
	if(was_off_contract)
		notify_contract_status(TRUE)

/// Remove a contract from the squad. If it was the last, set cooldown and notify members.
/datum/association_squad/proc/remove_contract(datum/association_contract/C)
	active_contracts -= C
	if(!is_on_contract())
		contract_cooldown_until = world.time + CONTRACT_COOLDOWN
		notify_contract_status(FALSE)

/// Notify all squad members about contract status changes.
/datum/association_squad/proc/notify_contract_status(active)
	for(var/mob/living/M in members)
		if(active)
			to_chat(M, span_nicegreen("Your squad is now on contract. Skill tree abilities are ACTIVE."))
		else
			to_chat(M, span_warning("All contracts have ended. Skill tree abilities are now INACTIVE."))

/// Award EXP to all squad members.
/datum/association_squad/proc/award_exp_to_all(amount)
	for(var/mob/living/M in members)
		var/datum/component/association_exp/exp = M.GetComponent(/datum/component/association_exp)
		if(exp)
			exp.modify_exp(amount)

// ============================================================
// Distress Emergency System
// ============================================================

/// Trigger distress alert for the entire squad. Grants temporary skill access.
/datum/association_squad/proc/trigger_distress(mob/living/victim, mob/living/attacker)
	// Set cooldown for this victim
	distress_cooldowns[ref(victim)] = world.time
	var/area_name = get_area_name(victim)
	for(var/mob/living/M in members)
		// Alert everyone
		to_chat(M, span_userdanger("DISTRESS: [victim] is under attack by [attacker] at [area_name]!"))
		SEND_SOUND(M, sound('sound/machines/warning-buzzer.ogg'))
		// Grant emergency skill access to members NOT on contract
		if(!is_on_contract() && !M.has_status_effect(/datum/status_effect/association_emergency))
			M.apply_status_effect(/datum/status_effect/association_emergency)
	// Start directional arrow effects pointing squad members to victim
	distress_victim = victim
	// Cancel any existing arrow timer
	if(distress_arrow_timer)
		deltimer(distress_arrow_timer)
	// Fire arrows immediately then every 5 seconds for 60s
	fire_distress_arrows()
	distress_arrow_timer = addtimer(CALLBACK(src, PROC_REF(fire_distress_arrows)), 5 SECONDS, TIMER_STOPPABLE | TIMER_LOOP)
	// Stop arrows after the emergency duration
	addtimer(CALLBACK(src, PROC_REF(stop_distress_arrows)), CONTRACT_DISTRESS_DURATION)

/// Spawn spark trail effects from each squad member toward the distress victim.
/// Uses client images so only squad members can see the arrows.
/datum/association_squad/proc/fire_distress_arrows()
	if(!distress_victim || QDELETED(distress_victim))
		stop_distress_arrows()
		return
	var/turf/victim_turf = get_turf(distress_victim)
	if(!victim_turf)
		return
	// Collect squad clients for squad-only visibility
	var/list/squad_clients = list()
	for(var/mob/living/M in members)
		if(M.client)
			squad_clients += M.client
	if(!length(squad_clients))
		return
	for(var/mob/living/M in members)
		if(M == distress_victim)
			continue
		var/turf/member_turf = get_turf(M)
		if(!member_turf || member_turf.z != victim_turf.z)
			continue
		var/list/arrow_path = get_path_to(member_turf, victim_turf, TYPE_PROC_REF(/turf, Distance_cardinal), 100)
		var/i = 0
		for(var/turf/T in arrow_path)
			if(i > 10)
				break
			var/image/I = image('icons/effects/cult_effects.dmi', T, "bloodsparkles", ABOVE_MOB_LAYER)
			I.dir = pick(GLOB.cardinals)
			for(var/client/C in squad_clients)
				C.images += I
			addtimer(CALLBACK(src, PROC_REF(remove_distress_image), I, squad_clients), 10)
			i++

/// Remove a distress arrow image from squad clients after its duration expires.
/datum/association_squad/proc/remove_distress_image(image/I, list/clients)
	for(var/client/C in clients)
		C.images -= I

/// Stop the distress arrow timer and clean up.
/datum/association_squad/proc/stop_distress_arrows()
	if(distress_arrow_timer)
		deltimer(distress_arrow_timer)
		distress_arrow_timer = null
	distress_victim = null
