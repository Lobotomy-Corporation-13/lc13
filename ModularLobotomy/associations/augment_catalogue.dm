//--------------------------------------
// Augment Catalogue System
//--------------------------------------

// Augment Order Ticket Item
/obj/item/augment_ticket
	name = "augment order ticket"
	desc = "A ticket containing an augment design order."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paperslip"
	inhand_icon_state = "ticket"
	worn_icon_state = "ticket"
	w_class = WEIGHT_CLASS_TINY
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS

	// Augment design data
	var/form_id = ""
	var/form_name = ""
	var/rank = 1
	var/augment_name = ""
	var/augment_desc = ""
	var/primary_color = "#FFFFFF"
	var/secondary_color = "#CCCCCC"
	var/list/selected_effects = list()  // List of effect IDs
	var/base_cost = 0
	var/total_cost = 0
	var/ticket_id = ""
	var/orderer_name = ""

/obj/item/augment_ticket/Initialize(mapload)
	. = ..()
	// Generate random color for visual distinction
	color = pick(COLOR_RED, COLOR_BLUE, COLOR_GREEN, COLOR_YELLOW, COLOR_PURPLE, COLOR_ORANGE, COLOR_CYAN)

/obj/item/augment_ticket/examine(mob/user)
	. = ..()
	if(!form_id)
		. += span_warning("This ticket appears to be blank.")
		return

	. += span_notice("=== AUGMENT ORDER ===")
	. += span_notice("Order ID: [ticket_id]")
	. += span_notice("Ordered by: [orderer_name]")
	. += span_notice("Form: [form_name]")
	. += span_notice("Rank: [rank]")
	. += span_notice("Name: [augment_name]")
	. += span_notice("Total Cost: [total_cost] ahn")
	. += span_notice("Effects Ordered: [length(selected_effects)]")

	if(augment_desc)
		. += span_notice("Description: [augment_desc]")

// Datum to hold current design being worked on
/datum/augment_catalogue_design
	var/form_id = ""
	var/form_name = ""
	var/rank = 1
	var/augment_name = ""
	var/augment_desc = ""
	var/primary_color = "#FFFFFF"
	var/secondary_color = "#CCCCCC"
	var/list/selected_effects = list()  // List of effect IDs
	var/base_cost = 0
	var/total_cost = 0

// Augment Catalogue Machine
/obj/machinery/augment_catalogue
	name = "Augment Catalogue"
	desc = "A design station for augments. Create order tickets for authorized personnel to fabricate."
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "console"
	density = FALSE

	var/busy = FALSE

	// Current design being worked on
	var/datum/augment_catalogue_design/current_design

	// Share the same forms and effects as the fabricator
	var/list/available_forms
	var/list/available_effects
	var/maxRank = 5
	var/list/rankAttributeReqs = list(20, 40, 60, 80, 100)
	var/currencySymbol = "ahn"

/obj/machinery/augment_catalogue/Initialize(mapload)
	. = ..()
	current_design = new /datum/augment_catalogue_design()

	// Copy forms and effects from fabricator
	var/obj/machinery/augment_fabricator/fab = locate() in world
	if(fab)
		available_forms = fab.available_forms
		available_effects = fab.available_effects
	else
		// Fallback - create basic data structure
		available_forms = list()
		available_effects = list()

/obj/machinery/augment_catalogue/attack_hand(mob/user)
	if(!Adjacent(user, src))
		return ..()

	if(!istype(user, /mob/living/carbon/human))
		to_chat(user, span_warning("You lack the dexterity to operate this machine."))
		return TRUE

	// Anyone can use the catalogue
	ui_interact(user)
	return TRUE

/obj/machinery/augment_catalogue/ui_interact(mob/user)
	. = ..()
	var/datum/tgui/ui = SStgui.try_update_ui(user, src)
	if(!ui)
		ui = new(user, src, "AugmentCatalogue", name)
		ui.open()

/obj/machinery/augment_catalogue/ui_static_data(mob/user)
	var/list/data = list()

	// Static data that doesn't change
	data["maxRank"] = maxRank
	data["rankAttributeReqs"] = rankAttributeReqs
	data["currencySymbol"] = currencySymbol

	// Forms list
	data["forms"] = list()
	for(var/form_name in available_forms)
		var/list/form = available_forms[form_name]
		data["forms"] += list(list(
			"id" = form["id"],
			"name" = form["name"],
			"desc" = form["desc"],
			"base_cost" = form["base_cost"],
			"base_ep" = form["base_ep"],
			"negative_immune" = form["negative_immune"] || 0
		))

	// Effects list
	data["effects"] = list()
	for(var/list/effect in available_effects)
		data["effects"] += list(list(
			"id" = effect["id"],
			"name" = effect["name"],
			"desc" = effect["desc"],
			"ahn_cost" = effect["ahn_cost"],
			"current_ahn_cost" = effect["current_ahn_cost"],
			"ep_cost" = effect["ep_cost"],
			"repeatable" = effect["repeatable"] || 0,
			"sale_percent" = effect["sale_percent"] || 0,
			"markup_percent" = effect["markup_percent"] || 0
		))

	return data

/obj/machinery/augment_catalogue/ui_data(mob/user)
	var/list/data = list()

	// Current design info
	data["selectedFormId"] = current_design.form_id
	data["selectedRank"] = current_design.rank
	data["augmentName"] = current_design.augment_name
	data["augmentDesc"] = current_design.augment_desc
	data["primaryColor"] = current_design.primary_color
	data["secondaryColor"] = current_design.secondary_color
	data["selectedEffects"] = current_design.selected_effects
	data["totalCost"] = current_design.total_cost

	data["busy"] = busy

	return data

/obj/machinery/augment_catalogue/ui_act(action, params)
	. = ..()
	if(.)
		return

	if(busy)
		to_chat(usr, span_warning("[src] is currently processing!"))
		return

	switch(action)
		if("select_form")
			var/form_id = params["formId"]
			var/list/form_data = null

			// Find the form by ID
			for(var/form_name in available_forms)
				var/list/form = available_forms[form_name]
				if(form["id"] == form_id)
					form_data = form
					current_design.form_name = form_name
					break

			if(!form_data)
				return

			current_design.form_id = form_id
			current_design.rank = params["rank"] || 1
			current_design.selected_effects = list()
			current_design.base_cost = form_data["base_cost"] * current_design.rank

			recalculate_cost()
			return TRUE

		if("set_rank")
			current_design.rank = clamp(params["rank"], 1, maxRank)
			// Recalculate base cost
			var/list/form_data = get_form_by_id(current_design.form_id)
			if(form_data)
				current_design.base_cost = form_data["base_cost"] * current_design.rank
			recalculate_cost()
			return TRUE

		if("set_name")
			current_design.augment_name = params["name"]
			return TRUE

		if("set_description")
			current_design.augment_desc = params["description"]
			return TRUE

		if("set_colors")
			current_design.primary_color = params["primaryColor"]
			current_design.secondary_color = params["secondaryColor"]
			return TRUE

		if("add_effect")
			var/effect_id = params["effectId"]
			current_design.selected_effects += effect_id
			recalculate_cost()
			return TRUE

		if("remove_effect")
			var/effect_index = params["index"]
			if(effect_index >= 1 && effect_index <= length(current_design.selected_effects))
				current_design.selected_effects.Cut(effect_index, effect_index + 1)
			recalculate_cost()
			return TRUE

		if("create_ticket")
			if(!current_design.form_id || !length(current_design.selected_effects))
				to_chat(usr, span_warning("Design incomplete! Please select a form and at least one effect."))
				return

			create_order_ticket(usr)
			return TRUE

		if("clear_design")
			current_design = new /datum/augment_catalogue_design()
			return TRUE

/obj/machinery/augment_catalogue/proc/get_form_by_id(form_id)
	for(var/form_name in available_forms)
		var/list/form = available_forms[form_name]
		if(form["id"] == form_id)
			return form
	return null

/obj/machinery/augment_catalogue/proc/get_effect_by_id(effect_id)
	for(var/list/effect in available_effects)
		if(effect["id"] == effect_id)
			return effect
	return null

/obj/machinery/augment_catalogue/proc/recalculate_cost()
	current_design.total_cost = current_design.base_cost

	for(var/effect_id in current_design.selected_effects)
		var/list/effect = get_effect_by_id(effect_id)
		if(effect)
			current_design.total_cost += effect["current_ahn_cost"]

	// Ensure non-negative
	current_design.total_cost = max(0, current_design.total_cost)

/obj/machinery/augment_catalogue/proc/create_order_ticket(mob/user)
	busy = TRUE
	playsound(src, 'sound/machines/terminal_button05.ogg', 50, FALSE)
	to_chat(user, span_notice("Creating augment order ticket..."))

	addtimer(CALLBACK(src, PROC_REF(finish_ticket_creation), user), 2 SECONDS)
	SStgui.update_uis(src)

/obj/machinery/augment_catalogue/proc/finish_ticket_creation(mob/user)
	busy = FALSE

	// Create the ticket
	var/obj/item/augment_ticket/ticket = new(get_turf(src))

	// Copy design data to ticket
	ticket.form_id = current_design.form_id
	ticket.form_name = current_design.form_name
	ticket.rank = current_design.rank
	ticket.augment_name = current_design.augment_name
	ticket.augment_desc = current_design.augment_desc
	ticket.primary_color = current_design.primary_color
	ticket.secondary_color = current_design.secondary_color
	ticket.selected_effects = current_design.selected_effects.Copy()
	ticket.base_cost = current_design.base_cost
	ticket.total_cost = current_design.total_cost
	ticket.orderer_name = user.real_name || "Unknown"
	ticket.ticket_id = "[rand(1000, 9999)]-[world.time]"

	// Update ticket name and description
	ticket.name = "augment order ticket ([ticket.orderer_name])"
	ticket.desc = "A [ticket.form_name] augment order ticket created by [ticket.orderer_name]. Total cost: [ticket.total_cost] ahn."

	to_chat(user, span_notice("Order ticket created! Give this to a Prosthetics Surgeon or authorized staff for fabrication."))
	playsound(src, 'sound/items/taperecorder/taperecorder_print.ogg', 50, FALSE)
	SStgui.update_uis(src)
