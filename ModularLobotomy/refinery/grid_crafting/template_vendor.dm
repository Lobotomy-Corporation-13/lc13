/**
 * Grid Crafting System - Template Vendor
 *
 * Machine that sells core templates for Ahn from player bank accounts.
 */

/obj/structure/template_vendor
	name = "navigation template vendor"
	desc = "A vending machine that sells navigation core templates for Ahn."
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "mining"
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE

/obj/structure/template_vendor/Initialize(mapload)
	. = ..()
	GLOB.lobotomy_devices += src

/obj/structure/template_vendor/Destroy()
	GLOB.lobotomy_devices -= src
	return ..()

/obj/structure/template_vendor/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	ui_interact(user)
	return TRUE

/// Get the player's current Ahn balance
/obj/structure/template_vendor/proc/GetPlayerBalance(mob/living/user)
	if(!ishuman(user))
		return 0

	var/obj/item/card/id/C = user.get_idcard(TRUE)
	if(!C || !C.registered_account)
		return 0

	return C.registered_account.account_balance

/// Attempt to purchase a template
/obj/structure/template_vendor/proc/PurchaseTemplate(mob/living/user, grade)
	if(!ishuman(user))
		to_chat(user, span_warning("You cannot use this machine."))
		return FALSE

	var/obj/item/card/id/C = user.get_idcard(TRUE)
	if(!C)
		to_chat(user, span_warning("You need an ID card to make purchases."))
		return FALSE

	if(!C.registered_account)
		to_chat(user, span_warning("Your ID card has no linked bank account."))
		return FALSE

	var/cost = 0
	var/template_type = null

	switch(grade)
		if(TEMPLATE_GRADE_BASIC)
			cost = TEMPLATE_COST_BASIC
			template_type = /obj/item/reagent_containers/core_template/basic
		if(TEMPLATE_GRADE_STANDARD)
			cost = TEMPLATE_COST_STANDARD
			template_type = /obj/item/reagent_containers/core_template/standard
		if(TEMPLATE_GRADE_QUALITY)
			cost = TEMPLATE_COST_QUALITY
			template_type = /obj/item/reagent_containers/core_template/quality
		if(TEMPLATE_GRADE_SUPERIOR)
			cost = TEMPLATE_COST_SUPERIOR
			template_type = /obj/item/reagent_containers/core_template/superior
		else
			to_chat(user, span_warning("Invalid template grade."))
			return FALSE

	var/datum/bank_account/account = C.registered_account
	if(!account.adjust_money(-cost))
		to_chat(user, span_warning("Insufficient funds! You need [cost] Ahn but only have [account.account_balance] Ahn."))
		playsound(src, 'sound/machines/buzz-sigh.ogg', 30, TRUE)
		return FALSE

	// Create the template
	var/obj/item/reagent_containers/core_template/new_template = new template_type(get_turf(src))
	user.put_in_hands(new_template)

	to_chat(user, span_notice("Purchased [new_template.name] for [cost] Ahn. Remaining balance: [account.account_balance] Ahn."))
	playsound(src, 'sound/effects/cashregister.ogg', 30, TRUE)

	SStgui.update_uis(src)
	return TRUE

// ===== TGUI Interface =====

/obj/structure/template_vendor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CoreTemplateVendor", name)
		ui.open()

/obj/structure/template_vendor/ui_data(mob/user)
	var/list/data = list()

	// Player balance
	data["balance"] = GetPlayerBalance(user)

	// Template options
	data["templates"] = list(
		list(
			"grade" = TEMPLATE_GRADE_BASIC,
			"name" = "Basic Template",
			"cost" = TEMPLATE_COST_BASIC,
			"min_dist" = TEMPLATE_DIST_BASIC_MIN,
			"max_dist" = TEMPLATE_DIST_BASIC_MAX,
			"max_tier" = TEMPLATE_MAX_TIER_BASIC,
			"description" = "Entry-level template for Tier 0-1 weapons."
		),
		list(
			"grade" = TEMPLATE_GRADE_STANDARD,
			"name" = "Standard Template",
			"cost" = TEMPLATE_COST_STANDARD,
			"min_dist" = TEMPLATE_DIST_STANDARD_MIN,
			"max_dist" = TEMPLATE_DIST_STANDARD_MAX,
			"max_tier" = TEMPLATE_MAX_TIER_STANDARD,
			"description" = "Mid-grade template for Tier 0-2 weapons."
		),
		list(
			"grade" = TEMPLATE_GRADE_QUALITY,
			"name" = "Quality Template",
			"cost" = TEMPLATE_COST_QUALITY,
			"min_dist" = TEMPLATE_DIST_QUALITY_MIN,
			"max_dist" = TEMPLATE_DIST_QUALITY_MAX,
			"max_tier" = TEMPLATE_MAX_TIER_QUALITY,
			"description" = "High-grade template for Tier 0-3 weapons."
		),
		list(
			"grade" = TEMPLATE_GRADE_SUPERIOR,
			"name" = "Superior Template",
			"cost" = TEMPLATE_COST_SUPERIOR,
			"min_dist" = TEMPLATE_DIST_SUPERIOR_MIN,
			"max_dist" = TEMPLATE_DIST_SUPERIOR_MAX,
			"max_tier" = TEMPLATE_MAX_TIER_SUPERIOR,
			"description" = "Premium template for all weapon tiers."
		)
	)

	return data

/obj/structure/template_vendor/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("purchase")
			var/grade = text2num(params["grade"])
			if(grade)
				PurchaseTemplate(usr, grade)
			return TRUE

	return FALSE

/obj/structure/template_vendor/examine(mob/user)
	. = ..()
	. += span_notice("Click to browse navigation core templates.")
	. += span_notice("Templates are purchased with Ahn from your bank account.")
	if(ishuman(user))
		var/balance = GetPlayerBalance(user)
		. += span_notice("Your balance: [balance] Ahn")
