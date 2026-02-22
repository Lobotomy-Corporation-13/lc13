/// Physical contract paper item. Created by the Contract Terminal, handed to fixers.
/// Use in hand to read the contract details. Hit a registered fixer to offer accept/decline.
/// If destroyed or deleted while pending, the payment is refunded to the issuer.
/obj/item/association_contract_paper
	name = "association contract"
	desc = "An official contract document from the Association Contract Terminal."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "docs_part"
	w_class = WEIGHT_CLASS_TINY
	/// The contract datum this paper represents
	var/datum/association_contract/contract

/obj/item/association_contract_paper/Initialize(mapload, datum/association_contract/_contract)
	. = ..()
	if(_contract)
		contract = _contract
		name = "[contract.contract_name] contract"
		desc = "An official [contract.contract_name] contract. Payment: [contract.payment_amount] Ahn."

/obj/item/association_contract_paper/Destroy()
	// Refund if the contract was never accepted
	if(contract && contract.state == CONTRACT_STATE_PENDING)
		contract.cancel()
	contract = null
	return ..()

/obj/item/association_contract_paper/examine(mob/user)
	. = ..()
	if(!contract)
		. += span_warning("This contract paper is blank.")
		return
	. += span_notice("Contract: [contract.contract_name]")
	. += span_notice("Type: [contract.category == CONTRACT_CATEGORY_DURATION ? "Duration-based" : "Objective-based"]")
	if(contract.category == CONTRACT_CATEGORY_DURATION)
		. += span_notice("Duration: [contract.get_tier_name()]")
	. += span_notice("Payment: [contract.payment_amount] Ahn")
	. += span_notice("Issuer: [contract.issuer_mob ? contract.issuer_mob.name : "Unknown"]")
	if(contract.target_mob)
		. += span_notice("Target: [contract.target_mob.name]")
	. += span_notice("Status: [contract.get_status_text()]")
	if(contract.source == CONTRACT_SOURCE_CIVILIAN)
		. += span_nicegreen("Civilian contract — 2x EXP bonus!")

/// Use in hand to read contract details, accept contracts, or view route/location map.
/obj/item/association_contract_paper/attack_self(mob/user)
	if(!contract)
		to_chat(user, span_warning("This contract paper is blank."))
		return
	// If contract is active and has a map viewer, show the route/location map
	if(contract.state == CONTRACT_STATE_ACTIVE)
		if(istype(contract, /datum/association_contract/patrol_route) || istype(contract, /datum/association_contract/surveillance_post))
			contract.ui_interact(user)
			return
	// Show the contract paper TGUI (includes Accept button when applicable)
	ui_interact(user)

/// Offer a pending contract directly to a fixer using the paper in hand.
/obj/item/association_contract_paper/proc/offer_contract_to_fixer(mob/living/fixer, datum/component/association_exp/exp)
	if(!exp.squad.can_accept_contract())
		to_chat(fixer, span_warning("Your squad is on contract cooldown. Please wait."))
		return
	var/bonus_text = contract.source == CONTRACT_SOURCE_CIVILIAN ? " (2x EXP — Civilian)" : ""
	var/choice = tgui_alert(fixer, "Accept [contract.contract_name] contract for [contract.payment_amount] Ahn?[bonus_text]", "Contract Offer", list("Accept", "Decline"))
	// Validate state hasn't changed during the alert
	if(QDELETED(src) || QDELETED(fixer) || !contract || contract.state != CONTRACT_STATE_PENDING)
		return
	if(choice != "Accept")
		to_chat(fixer, span_notice("You declined the contract."))
		return
	// Activate the contract
	contract.acceptor_mob = fixer
	if(!contract.activate(exp.squad))
		contract.acceptor_mob = null
		to_chat(fixer, span_warning("Failed to activate contract."))
		return
	to_chat(fixer, span_nicegreen("You accepted the [contract.contract_name] contract. Skills are now active!"))
	playsound(src, 'sound/machines/twobeep_high.ogg', 50, TRUE)

/obj/item/association_contract_paper/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ContractPaper")
		ui.open()

/obj/item/association_contract_paper/ui_state()
	return GLOB.physical_state

/obj/item/association_contract_paper/ui_data(mob/user)
	if(!contract)
		return list()
	var/list/data = contract.get_display_data()
	// Check if this user can accept the contract
	if(contract.state == CONTRACT_STATE_PENDING)
		var/datum/component/association_exp/exp = user.GetComponent(/datum/component/association_exp)
		if(exp && exp.squad && exp.squad.can_accept_contract())
			data["can_accept"] = TRUE
	return data

/obj/item/association_contract_paper/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	if(!contract)
		return
	switch(action)
		if("accept")
			if(contract.state != CONTRACT_STATE_PENDING)
				return
			var/mob/living/user = usr
			var/datum/component/association_exp/exp = user.GetComponent(/datum/component/association_exp)
			if(!exp)
				to_chat(user, span_warning("You are not a registered association fixer."))
				return
			if(!exp.squad)
				to_chat(user, span_warning("You are not assigned to a squad."))
				return
			if(!exp.squad.can_accept_contract())
				to_chat(user, span_warning("Your squad is on contract cooldown. Please wait."))
				return
			contract.acceptor_mob = user
			if(!contract.activate(exp.squad))
				contract.acceptor_mob = null
				to_chat(user, span_warning("Failed to activate contract."))
				return
			to_chat(user, span_nicegreen("You accepted the [contract.contract_name] contract. Skills are now active!"))
			playsound(src, 'sound/machines/twobeep_high.ogg', 50, TRUE)
			return TRUE

/// Hit a fixer with this paper to offer them the contract.
/obj/item/association_contract_paper/attack(mob/living/target, mob/living/user)
	if(!contract)
		to_chat(user, span_warning("This contract paper is blank."))
		return
	if(contract.state != CONTRACT_STATE_PENDING)
		to_chat(user, span_warning("This contract has already been [contract.state]."))
		return
	// Target must be a registered fixer
	var/datum/component/association_exp/exp = target.GetComponent(/datum/component/association_exp)
	if(!exp)
		to_chat(user, span_warning("[target] is not a registered association fixer."))
		return ..()
	if(!exp.squad)
		to_chat(user, span_warning("[target] is not assigned to a squad."))
		return
	// Issuer cannot be a fixer (no self-contracting) — unless debug mode
	if(!contract.debug_mode)
		var/datum/component/association_exp/user_exp = user.GetComponent(/datum/component/association_exp)
		if(user_exp)
			to_chat(user, span_warning("Association members cannot offer contracts to each other."))
			return
	// Check cooldown
	if(!exp.squad.can_accept_contract())
		to_chat(user, span_warning("[target]'s squad is on contract cooldown. Please wait."))
		return
	// Offer the contract via alert dialog
	var/choice = tgui_alert(target, "Accept [contract.contract_name] contract for [contract.payment_amount] Ahn?[contract.source == CONTRACT_SOURCE_CIVILIAN ? " (2x EXP — Civilian)" : ""]", "Contract Offer", list("Accept", "Decline"))
	// Validate state hasn't changed during the alert
	if(QDELETED(src) || QDELETED(target) || !contract || contract.state != CONTRACT_STATE_PENDING)
		return
	if(choice != "Accept")
		to_chat(user, span_warning("[target] declined the contract."))
		to_chat(target, span_notice("You declined the contract."))
		return
	// Activate the contract
	contract.acceptor_mob = target
	if(!contract.activate(exp.squad))
		contract.acceptor_mob = null
		to_chat(user, span_warning("Failed to activate contract."))
		return
	to_chat(user, span_nicegreen("[target] accepted the [contract.contract_name] contract!"))
	to_chat(target, span_nicegreen("You accepted the [contract.contract_name] contract. Skills are now active!"))
	playsound(src, 'sound/machines/twobeep_high.ogg', 50, TRUE)
