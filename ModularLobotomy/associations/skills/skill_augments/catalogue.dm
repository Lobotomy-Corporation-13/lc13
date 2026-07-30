//--------------------------------------
// Body Modification Catalogue System
//--------------------------------------

// Body Modification Ticket Item
/obj/item/body_modification_ticket
	name = "body modification order ticket"
	desc = "A ticket containing a body modification design order."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "paperslip"
	inhand_icon_state = "ticket"
	worn_icon_state = "ticket"
	w_class = WEIGHT_CLASS_TINY
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS

	var/template_name = ""
	var/rank = 1
	var/max_slots = 4
	var/max_charge = 60
	var/list/selected_skills = list()
	var/material_cost = 0
	var/ticket_id = ""
	var/orderer_name = ""
	var/list/skill_charge_costs = list()
	var/total_slot_cost = 0
	var/is_injectable = FALSE

/obj/item/body_modification_ticket/Initialize(mapload)
	. = ..()
	// Generate random color for visual distinction
	color = pick(COLOR_RED, COLOR_BLUE, COLOR_GREEN, COLOR_YELLOW, COLOR_PURPLE, COLOR_ORANGE, COLOR_CYAN)

/obj/item/body_modification_ticket/examine(mob/user)
	. = ..()
	if(!template_name)
		. += span_warning("This ticket appears to be blank.")
		return

	. += span_notice("=== BODY MODIFICATION ORDER ===")
	. += span_notice("Order ID: [ticket_id]")
	. += span_notice("Ordered by: [orderer_name]")
	. += span_notice("Template: [template_name]")
	. += span_notice("Rank: [rank] | Slots: [max_slots] | Charge: [max_charge]")
	. += span_notice("Material Cost: [material_cost]")
	. += span_notice("Skills Ordered: [length(selected_skills)]")

	if(length(selected_skills))
		. += span_notice("--- Skill List ---")
		for(var/skill_type in selected_skills)
			var/skill_name = get_skill_name_from_type(skill_type)
			var/charge_cost = skill_charge_costs[skill_type] || 0
			. += span_notice("• [skill_name] ([charge_cost] charge)")

/obj/item/body_modification_ticket/proc/get_skill_name_from_type(skill_type)
	// Get skill data from the fabricator's skill_data list
	var/obj/machinery/body_modification_fabricator/fab = locate() in world
	if(fab)
		var/list/skill_info = fab.skill_data[skill_type]
		if(skill_info)
			return skill_info["name"]
	return "Unknown Skill"

// Body Modification Catalogue Machine
/obj/machinery/body_modification_catalogue
	name = "Body Modification Catalogue"
	desc = "A comprehensive service station for body modifications. Design orders, scan compatibility, or remove existing modifications."
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "console"
	density = FALSE

	var/busy = FALSE
	var/scan_cost = 40  // Ahn cost for scanning
	var/removal_cost = 100  // Ahn cost for removal

	// Current design being worked on
	var/datum/body_modification_design/current_design

	// Share the same templates and skill data as the fabricator
	var/list/available_templates
	var/list/skill_data

/obj/machinery/body_modification_catalogue/Initialize(mapload)
	. = ..()
	current_design = new /datum/body_modification_design()

	// Copy templates and skill data from fabricator
	var/obj/machinery/body_modification_fabricator/fab = locate() in world
	if(fab)
		available_templates = fab.available_templates
		skill_data = fab.skill_data
	else
		// Fallback - create basic data structure
		available_templates = list()
		skill_data = list()

/obj/machinery/body_modification_catalogue/ui_interact(mob/user)
	. = ..()
	var/datum/tgui/ui = SStgui.try_update_ui(user, src)
	if(!ui)
		ui = new(user, src, "SkillAugmentCatalogue", name)
		ui.open()

/obj/machinery/body_modification_catalogue/ui_data(mob/user)
	var/list/data = list()

	// Current design info
	data["current_rank"] = current_design.rank
	data["current_slots"] = current_design.max_slots
	data["current_charge"] = current_design.max_charge
	data["total_slot_cost"] = current_design.total_slot_cost
	data["material_cost"] = current_design.material_cost

	// Selected skills
	data["selected_skills"] = list()
	var/list/current_skill_data = get_skill_data()
	for(var/skill_type in current_design.selected_skills)
		var/list/skill_info = current_skill_data[skill_type]
		if(skill_info)
			data["selected_skills"] += list(list(
				"name" = skill_info["name"],
				"slot_cost" = skill_info["slot_cost"],
				"charge_cost" = skill_info["charge_cost"],
				"type_path" = "[skill_type]"
			))

	// Available templates
	data["templates"] = list()
	for(var/template_name in available_templates)
		var/list/template = available_templates[template_name]
		data["templates"] += list(list(
			"name" = template_name,
			"rank" = template["rank"],
			"slots" = template["slots"],
			"charge" = template["charge"],
			"can_afford" = TRUE, // Always true for catalogue
			"materials_needed" = "[template["material_cost"]] material"
		))

	// Available skills filtered by rank
	data["available_skills"] = list()
	for(var/skill_type in current_skill_data)
		var/list/skill_info = current_skill_data[skill_type]
		if(skill_info["skill_level"] <= current_design.rank)
			data["available_skills"] += list(list(
				"name" = skill_info["name"],
				"desc" = skill_info["desc"],
				"slot_cost" = skill_info["slot_cost"],
				"charge_cost" = skill_info["charge_cost"],
				"skill_level" = skill_info["skill_level"],
				"type_path" = "[skill_type]",
				"can_add" = (current_design.total_slot_cost + skill_info["slot_cost"] <= current_design.max_slots)
			))

	data["busy"] = busy
	data["scan_cost"] = scan_cost
	data["removal_cost"] = removal_cost

	return data

/obj/machinery/body_modification_catalogue/ui_act(action, params)
	. = ..()
	if(.)
		return

	if(busy)
		to_chat(usr, span_warning("[src] is currently processing!"))
		return

	switch(action)
		if("select_template")
			var/template_name = params["template"]
			if(!(template_name in available_templates))
				return

			var/list/template = available_templates[template_name]
			current_design.rank = template["rank"]
			current_design.max_slots = template["slots"]
			current_design.max_charge = template["charge"]
			current_design.material_cost = template["material_cost"]
			current_design.name = template_name
			current_design.selected_skills = list()
			current_design.total_slot_cost = 0
			return TRUE

		if("add_skill")
			var/skill_path = text2path(params["skill_type"])
			var/list/current_skill_data = get_skill_data()
			if(!skill_path || !(skill_path in current_skill_data))
				return

			if(skill_path in current_design.selected_skills)
				to_chat(usr, span_warning("This skill is already selected!"))
				return

			var/list/skill_info = current_skill_data[skill_path]
			if(current_design.total_slot_cost + skill_info["slot_cost"] > current_design.max_slots)
				to_chat(usr, span_warning("Not enough slots remaining!"))
				return

			current_design.selected_skills += skill_path
			current_design.total_slot_cost += skill_info["slot_cost"]
			return TRUE

		if("remove_skill")
			var/skill_path = text2path(params["skill_type"])
			if(!skill_path || !(skill_path in current_design.selected_skills))
				return

			var/list/current_skill_data = get_skill_data()
			var/list/skill_info = current_skill_data[skill_path]
			current_design.selected_skills -= skill_path
			current_design.total_slot_cost -= skill_info["slot_cost"]
			return TRUE

		if("create_ticket")
			if(!current_design.rank || !length(current_design.selected_skills))
				to_chat(usr, span_warning("Design incomplete!"))
				return

			create_order_ticket(usr)
			return TRUE

		if("scan_user")
			scan_body_modification(usr)
			return TRUE

		if("remove_modification")
			remove_body_modification(usr)
			return TRUE

		if("clear_design")
			current_design = new /datum/body_modification_design()
			return TRUE

/obj/machinery/body_modification_catalogue/proc/get_skill_data()
	return skill_data

/obj/machinery/body_modification_catalogue/proc/create_order_ticket(mob/user)
	busy = TRUE
	playsound(src, 'sound/machines/terminal_button05.ogg', 50, FALSE)
	to_chat(user, span_notice("Creating order ticket..."))

	addtimer(CALLBACK(src, PROC_REF(finish_ticket_creation), user), 2 SECONDS)
	SStgui.update_uis(src)

/obj/machinery/body_modification_catalogue/proc/finish_ticket_creation(mob/user)
	busy = FALSE

	// Create the ticket
	var/obj/item/body_modification_ticket/ticket = new(get_turf(src))

	// Copy design data to ticket
	ticket.template_name = current_design.name
	ticket.rank = current_design.rank
	ticket.max_slots = current_design.max_slots
	ticket.max_charge = current_design.max_charge
	ticket.selected_skills = current_design.selected_skills.Copy()
	ticket.material_cost = current_design.material_cost
	ticket.total_slot_cost = current_design.total_slot_cost
	ticket.orderer_name = user.real_name || "Unknown"
	ticket.ticket_id = "[rand(1000, 9999)]-[world.time]"

	// Check if this is an injectable template
	if(available_templates[current_design.name])
		ticket.is_injectable = available_templates[current_design.name]["injectable"] || FALSE

	// Copy skill charge costs
	var/list/current_skill_data = get_skill_data()
	for(var/skill_type in ticket.selected_skills)
		var/list/skill_info = current_skill_data[skill_type]
		if(skill_info)
			ticket.skill_charge_costs[skill_type] = skill_info["charge_cost"]

	// Update ticket name and description
	ticket.name = "skill modification ticket ([ticket.orderer_name])"
	ticket.desc = "A [ticket.template_name] skill modification order ticket created by [ticket.orderer_name]. Material cost: [ticket.material_cost]."

	to_chat(user, span_notice("Order ticket created! Give this to authorized medical/technical staff for processing."))
	playsound(src, 'sound/items/taperecorder/taperecorder_print.ogg', 50, FALSE)
	SStgui.update_uis(src)

/obj/machinery/body_modification_catalogue/proc/can_afford_ahn(mob/user, amount)
	var/obj/item/card/id/C
	if(isliving(user))
		var/mob/living/L = user
		C = L.get_idcard(TRUE)
		if(!C)
			return FALSE
		else if(!C.registered_account)
			return FALSE

		var/datum/bank_account/account = C.registered_account
		return (account.account_balance >= amount)
	return FALSE

/obj/machinery/body_modification_catalogue/proc/deduct_ahn_cost(mob/user, amount)
	var/obj/item/card/id/C
	if(isliving(user))
		var/mob/living/L = user
		C = L.get_idcard(TRUE)
		if(!C)
			return FALSE
		else if(!C.registered_account)
			return FALSE

		var/datum/bank_account/account = C.registered_account
		if(amount && !account.adjust_money(-amount))
			L.playsound_local(get_turf(src), 'sound/machines/buzz-two.ogg', 25, 3, 3)
			return FALSE
		else
			L.playsound_local(get_turf(src), 'sound/effects/cashregister.ogg', 25, 3, 3)
			return TRUE
	return FALSE

/obj/machinery/body_modification_catalogue/proc/scan_body_modification(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("Only humans can use this scanning function!"))
		return

	// Check if user can afford
	if(!can_afford_ahn(user, scan_cost))
		to_chat(user, span_warning("Insufficient funds! Scanning costs [scan_cost] Ahn."))
		return

	// Deduct cost
	if(!deduct_ahn_cost(user, scan_cost))
		to_chat(user, span_warning("Payment failed! Check your ID card and account balance."))
		return

	var/mob/living/carbon/human/H = user

	// Calculate average stats manually
	var/list/stats = list(
		FORTITUDE_ATTRIBUTE,
		PRUDENCE_ATTRIBUTE,
		TEMPERANCE_ATTRIBUTE,
		JUSTICE_ATTRIBUTE
	)
	var/stattotal = 0
	for(var/attribute in stats)
		stattotal += get_attribute_level(H, attribute)
	var/avg_stats = stattotal / 4 // Average of stats
	var/max_rank = 1

	// Determine max rank from stats
	if(avg_stats >= 100)
		max_rank = 5
	else if(avg_stats >= 80)
		max_rank = 4
	else if(avg_stats >= 60)
		max_rank = 3
	else if(avg_stats >= 40)
		max_rank = 2

	to_chat(user, span_notice("=== BODY MODIFICATION SCAN RESULTS ==="))
	to_chat(user, span_notice("Subject: [H.real_name]"))
	to_chat(user, span_notice("Average Stats: [avg_stats]"))
	to_chat(user, span_notice("Maximum Compatible Rank: [max_rank]"))

	// Check for existing modification
	var/obj/item/organ/cyberimp/chest/body_modification/existing = H.getorganslot(ORGAN_SLOT_HEART_AID)
	if(existing && istype(existing))
		to_chat(user, span_notice("--- CURRENT MODIFICATION ---"))
		to_chat(user, span_notice("Type: [existing.name]"))
		to_chat(user, span_notice("Rank: [existing.rank] | Max Slots: [existing.max_slots]"))
		to_chat(user, span_notice("Charge: [existing.current_charge]/[existing.max_charge]"))

		if(length(existing.attached_skills))
			to_chat(user, span_notice("Installed Skills:"))
			var/list/current_skill_data = get_skill_data()
			for(var/skill_type in existing.attached_skills)
				var/list/skill_info = current_skill_data[skill_type]
				if(skill_info)
					to_chat(user, span_notice("• [skill_info["name"]] ([skill_info["charge_cost"]] charge)"))
	else
		to_chat(user, span_notice("No body modification detected."))

	playsound(src, 'sound/machines/ping.ogg', 50, FALSE)

/obj/machinery/body_modification_catalogue/proc/remove_body_modification(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("Only humans can use this removal function!"))
		return

	var/mob/living/carbon/human/H = user

	// Check for existing modification
	var/obj/item/organ/cyberimp/chest/body_modification/existing = H.getorganslot(ORGAN_SLOT_HEART_AID)
	if(!existing || !istype(existing))
		to_chat(user, span_warning("No body modification detected to remove!"))
		return

	// Check if user can afford
	if(!can_afford_ahn(user, removal_cost))
		to_chat(user, span_warning("Insufficient funds! Removal costs [removal_cost] Ahn."))
		return

	// Confirm removal
	if(alert(user, "Are you sure you want to remove your body modification? This will cost [removal_cost] Ahn.", "Confirm Removal", "Yes", "No") != "Yes")
		return

	// Deduct cost
	if(!deduct_ahn_cost(user, removal_cost))
		to_chat(user, span_warning("Payment failed! Check your ID card and account balance."))
		return

	// Remove the modification
	busy = TRUE
	to_chat(user, span_notice("Beginning automated removal procedure..."))
	playsound(src, 'sound/machines/defib_SaftyOn.ogg', 50, FALSE)

	if(do_after(user, 3 SECONDS, target = src))
		existing.Remove(H, special = TRUE)
		qdel(existing)
		to_chat(user, span_notice("Body modification successfully removed!"))
		playsound(src, 'sound/machines/defib_success.ogg', 50, FALSE)
	else
		to_chat(user, span_warning("Removal procedure interrupted!"))

	busy = FALSE
