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

	// Library system
	var/static/list/augment_library = list() // Shared across all catalogues

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

	// Load augment library on first initialization
	if(!length(augment_library))
		load_augment_library()

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

	// Services page data
	data["scanCost"] = 20
	data["removeCost"] = 100
	data["currencySymbol"] = currencySymbol

	// Library data with permission info
	data["augmentLibrary"] = augment_library
	data["userCkey"] = user.ckey || ""
	data["isAdmin"] = check_rights_for(user.client, R_ADMIN)

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

		if("scan_augment")
			var/mob/living/carbon/human/H = usr
			if(!istype(H))
				to_chat(usr, span_warning("Only humans can use this service."))
				return

			// Deduct cost
			if(!deduct_cost(H, 20))
				to_chat(usr, span_warning("Insufficient funds! Need 20 ahn."))
				return

			scan_augment(H)
			return TRUE

		if("remove_augment")
			var/mob/living/carbon/human/H = usr
			if(!istype(H))
				to_chat(usr, span_warning("Only humans can use this service."))
				return

			// Check if they have an augment
			var/obj/item/augment/A = null
			for(var/atom/movable/i in H.contents)
				if(istype(i, /obj/item/augment))
					A = i
					break

			if(!A)
				to_chat(usr, span_warning("No augment detected."))
				return

			// Deduct cost
			if(!deduct_cost(H, 100))
				to_chat(usr, span_warning("Insufficient funds! Need 100 ahn."))
				return

			remove_augment(H, A)
			return TRUE

		if("upload_design")
			var/explanation = params["explanation"]
			if(!current_design.form_id || !length(current_design.selected_effects))
				to_chat(usr, span_warning("Design incomplete! Please select a form and at least one effect."))
				return

			upload_to_library(usr, explanation)
			return TRUE

		if("load_from_library")
			var/library_id = params["libraryId"]
			load_design_from_library(library_id)
			return TRUE

		if("create_ticket_from_library")
			var/library_id = params["libraryId"]
			create_ticket_from_library(usr, library_id)
			return TRUE

		if("delete_library_entry")
			var/library_id = params["libraryId"]
			delete_library_entry(usr, library_id)
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

/obj/machinery/augment_catalogue/proc/deduct_cost(mob/living/carbon/human/user, amount)
	var/obj/item/card/id/C = user.get_idcard(TRUE)
	if(!C)
		return FALSE
	if(!C.registered_account)
		return FALSE

	var/datum/bank_account/account = C.registered_account
	if(amount && !account.adjust_money(-amount))
		return FALSE
	else
		user.playsound_local(get_turf(src), 'sound/effects/cashregister.ogg', 25, 3, 3)
		return TRUE

/obj/machinery/augment_catalogue/proc/scan_augment(mob/living/carbon/human/H)
	playsound(src, 'sound/machines/cryo_warning.ogg', 50, TRUE)
	to_chat(H, span_notice("Scanning augment compatibility..."))

	var/list/stats = list(
		FORTITUDE_ATTRIBUTE,
		PRUDENCE_ATTRIBUTE,
		TEMPERANCE_ATTRIBUTE,
		JUSTICE_ATTRIBUTE,
	)

	// Check for existing augment
	var/obj/item/augment/A = null
	for(var/atom/movable/i in H.contents)
		if(istype(i, /obj/item/augment))
			A = i
			break

	if(A)
		to_chat(H, span_notice("You currently have the [A.name] augment."))
		// List the augment effects
		if(A.design_details && A.design_details.selected_effects_data && length(A.design_details.selected_effects_data))
			to_chat(H, span_notice("Augment Effects:"))
			var/list/effect_counts = list()
			for(var/list/effect in A.design_details.selected_effects_data)
				var/effect_id = effect["id"]
				effect_counts[effect_id] = (effect_counts[effect_id] || 0) + 1

			var/list/shown_effects = list()
			for(var/list/effect in A.design_details.selected_effects_data)
				var/effect_id = effect["id"]
				if(effect_id in shown_effects)
					continue
				shown_effects += effect_id
				var/count = effect_counts[effect_id]
				var/effect_name = effect["name"]
				var/effect_desc = effect["desc"]
				if(count > 1)
					to_chat(H, span_notice("• [effect_name] (x[count]): [effect_desc]"))
				else
					to_chat(H, span_notice("• [effect_name]: [effect_desc]"))

	// Check augment rank compatibility
	var/stattotal = 0
	for(var/attribute in stats)
		stattotal += get_attribute_level(H, attribute)
	stattotal /= 4	//Potential is an average of stats
	var/best_augment = round(stattotal/20)
	if(best_augment > 5)
		best_augment = 5
	if(best_augment < 1)
		to_chat(H, span_notice("You are unable to use any augments."))
		return
	to_chat(H, span_notice("You can use rank [best_augment] or lower augments."))

/obj/machinery/augment_catalogue/proc/remove_augment(mob/living/carbon/human/H, obj/item/augment/A)
	playsound(src, 'sound/items/drill_use.ogg', 50, TRUE)
	to_chat(H, span_warning("Removing [A.name]..."))
	busy = TRUE
	SStgui.update_uis(src)

	sleep(2 SECONDS)

	busy = FALSE

	var/remove_turf = pick(get_adjacent_open_turfs(H))

	// Remove components
	for(var/list/effect in A.design_details.selected_effects_data)
		if(effect["component"])
			var/datum/component/augment/C = H.GetComponent(effect["component"])
			if(C)
				C.RemoveComponent()

	A.forceMove(remove_turf)
	playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)

	if(A.design_details.form_data["id"] == "tattoo")
		H.adjust_all_attribute_buffs(A.design_details.rank * 4)

	A.active_augment = FALSE
	to_chat(H, span_nicegreen("Successfully removed [A.name]!"))
	SStgui.update_uis(src)

// Library system procedures
/obj/machinery/augment_catalogue/proc/upload_to_library(mob/user, explanation)
	busy = TRUE
	playsound(src, 'sound/machines/terminal_button05.ogg', 50, FALSE)
	to_chat(user, span_notice("Uploading augment design to library..."))
	SStgui.update_uis(src)

	sleep(2 SECONDS)

	busy = FALSE

	// Create library entry
	var/list/library_entry = list()
	library_entry["id"] = "[world.time]-[rand(1000, 9999)]"
	library_entry["timestamp"] = world.time
	library_entry["author"] = user.real_name || "Unknown"
	library_entry["author_ckey"] = user.ckey || "unknown"
	library_entry["form_id"] = current_design.form_id
	library_entry["form_name"] = current_design.form_name
	library_entry["rank"] = current_design.rank
	library_entry["augment_name"] = current_design.augment_name
	library_entry["augment_desc"] = current_design.augment_desc
	library_entry["explanation"] = explanation || "No explanation provided."
	library_entry["primary_color"] = current_design.primary_color
	library_entry["secondary_color"] = current_design.secondary_color
	library_entry["selected_effects"] = current_design.selected_effects.Copy()
	library_entry["base_cost"] = current_design.base_cost
	library_entry["total_cost"] = current_design.total_cost

	// Get effect details for display
	var/list/effect_details = list()
	for(var/effect_id in current_design.selected_effects)
		var/list/effect = get_effect_by_id(effect_id)
		if(effect)
			var/list/effect_info = list()
			effect_info["id"] = effect["id"]
			effect_info["name"] = effect["name"]
			effect_info["desc"] = effect["desc"]
			effect_details += list(effect_info)
	library_entry["effect_details"] = effect_details

	// Add to library
	augment_library += list(library_entry)

	// Save to persistence
	save_augment_library()

	to_chat(user, span_notice("Augment design '[current_design.augment_name]' uploaded to library!"))
	playsound(src, 'sound/items/taperecorder/taperecorder_print.ogg', 50, FALSE)
	log_game("[key_name(user)] uploaded augment design '[current_design.augment_name]' to library at [src] ([loc.x],[loc.y],[loc.z]).")
	SStgui.update_uis(src)

/obj/machinery/augment_catalogue/proc/load_design_from_library(library_id)
	// Find the library entry
	var/list/entry = null
	for(var/list/lib_entry in augment_library)
		if(lib_entry["id"] == library_id)
			entry = lib_entry
			break

	if(!entry)
		to_chat(usr, span_warning("Library entry not found!"))
		return

	// Load the design into current_design
	current_design.form_id = entry["form_id"]
	current_design.form_name = entry["form_name"]
	current_design.rank = entry["rank"]
	current_design.augment_name = entry["augment_name"]
	current_design.augment_desc = entry["augment_desc"]
	current_design.primary_color = entry["primary_color"]
	current_design.secondary_color = entry["secondary_color"]
	var/list/effect_list = entry["selected_effects"]
	current_design.selected_effects = effect_list?.Copy() || list()
	current_design.base_cost = entry["base_cost"]
	current_design.total_cost = entry["total_cost"]

	to_chat(usr, span_notice("Loaded design '[entry["augment_name"]]' by [entry["author"]]."))
	playsound(src, 'sound/machines/terminal_button01.ogg', 50, FALSE)
	SStgui.update_uis(src)

/obj/machinery/augment_catalogue/proc/load_augment_library()
	var/json_file = file("data/augment_library.json")
	if(!fexists(json_file))
		log_game("Augment Library: No persistence file found, starting fresh.")
		return

	var/list/json = json_decode(file2text(json_file))
	if(!json || !json["library"])
		log_game("Augment Library: Invalid or empty persistence file.")
		return

	augment_library = json["library"]
	log_game("Augment Library: Loaded [length(augment_library)] augment designs from persistence.")

/obj/machinery/augment_catalogue/proc/save_augment_library()
	var/json_file = file("data/augment_library.json")

	var/list/file_data = list()
	file_data["library"] = augment_library

	fdel(json_file)
	WRITE_FILE(json_file, json_encode(file_data))
	log_game("Augment Library: Saved [length(augment_library)] augment designs to persistence.")

/obj/machinery/augment_catalogue/proc/create_ticket_from_library(mob/user, library_id)
	// Find the library entry
	var/list/entry = null
	for(var/list/lib_entry in augment_library)
		if(lib_entry["id"] == library_id)
			entry = lib_entry
			break

	if(!entry)
		to_chat(user, span_warning("Library entry not found!"))
		return

	busy = TRUE
	playsound(src, 'sound/machines/terminal_button05.ogg', 50, FALSE)
	to_chat(user, span_notice("Creating ticket from library design..."))
	SStgui.update_uis(src)

	sleep(2 SECONDS)

	busy = FALSE

	// Create the ticket
	var/obj/item/augment_ticket/ticket = new(get_turf(src))

	// Copy library entry data to ticket
	ticket.form_id = entry["form_id"]
	ticket.form_name = entry["form_name"]
	ticket.rank = entry["rank"]
	ticket.augment_name = entry["augment_name"]
	ticket.augment_desc = entry["augment_desc"]
	ticket.primary_color = entry["primary_color"]
	ticket.secondary_color = entry["secondary_color"]
	var/list/effect_list = entry["selected_effects"]
	ticket.selected_effects = effect_list?.Copy() || list()
	ticket.base_cost = entry["base_cost"]
	ticket.total_cost = entry["total_cost"]
	ticket.orderer_name = user.real_name || "Unknown"
	ticket.ticket_id = "[rand(1000, 9999)]-[world.time]"

	// Update ticket name and description
	ticket.name = "augment order ticket ([ticket.orderer_name])"
	ticket.desc = "A [ticket.form_name] augment order ticket created by [ticket.orderer_name] from library design. Total cost: [ticket.total_cost] ahn."

	to_chat(user, span_notice("Order ticket created from library design '[entry["augment_name"]]'!"))
	playsound(src, 'sound/items/taperecorder/taperecorder_print.ogg', 50, FALSE)
	log_game("[key_name(user)] created ticket from library design '[entry["augment_name"]]' (ID: [library_id]) at [src] ([loc.x],[loc.y],[loc.z]).")
	SStgui.update_uis(src)

/obj/machinery/augment_catalogue/proc/delete_library_entry(mob/user, library_id)
	// Find the library entry
	var/list/entry = null
	var/entry_index = 0
	for(var/i = 1; i <= length(augment_library); i++)
		var/list/lib_entry = augment_library[i]
		if(lib_entry["id"] == library_id)
			entry = lib_entry
			entry_index = i
			break

	if(!entry)
		to_chat(user, span_warning("Library entry not found!"))
		return

	// Check permissions
	var/user_ckey = user.ckey || ""
	var/entry_ckey = entry["author_ckey"] || ""
	var/is_admin = check_rights_for(user.client, R_ADMIN)
	var/is_owner = (user_ckey == entry_ckey)

	if(!is_owner && !is_admin)
		to_chat(user, span_warning("You do not have permission to delete this entry!"))
		return

	// Delete the entry
	augment_library.Cut(entry_index, entry_index + 1)
	save_augment_library()

	to_chat(user, span_notice("Library entry '[entry["augment_name"]]' by [entry["author"]] has been deleted."))
	playsound(src, 'sound/machines/terminal_button08.ogg', 50, FALSE)
	log_game("[key_name(user)] deleted library entry '[entry["augment_name"]]' (ID: [library_id], Author: [entry["author"]] ([entry_ckey])) at [src] ([loc.x],[loc.y],[loc.z]).")
	SStgui.update_uis(src)
