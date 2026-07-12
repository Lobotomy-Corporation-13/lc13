// Office Management System
// This file handles global office tracking and UI for managing offices

// Office Management UI
/datum/office_management
	var/datum/fixer_office/selected_office

/datum/office_management/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "OfficeManagement")
		ui.open()

/datum/office_management/ui_state(mob/user)
	return GLOB.always_state

/datum/office_management/ui_data(mob/user)
	var/list/data = list()

	// List of all offices
	var/list/offices = list()
	for(var/datum/fixer_office/F in GLOB.all_fixer_offices)
		offices += list(list(
			"name" = F.name,
			"director" = F.director?.real_name || "Unknown",
			"members" = F.members.len,
			"max_members" = F.max_members,
			"color" = F.office_color,
			"ref" = REF(F)
		))
	data["offices"] = offices

	// Selected office details
	if(selected_office)
		var/list/members = list()
		for(var/mob/living/carbon/human/H in selected_office.members)
			members += list(list(
				"name" = H.real_name,
				"is_director" = (H == selected_office.director),
				"ref" = REF(H)
			))

		data["selected_office"] = list(
			"name" = selected_office.name,
			"director" = selected_office.director?.real_name || "Unknown",
			"members" = members,
			"color" = selected_office.office_color,
			"budget" = selected_office.office_budget,
			"creation_time" = selected_office.creation_time,
			"ref" = REF(selected_office)
		)

	// User's office info
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		for(var/datum/fixer_office/F in GLOB.all_fixer_offices)
			if(H in F.members)
				data["user_office"] = REF(F)
				data["user_is_director"] = (H == F.director)
				break

	return data

/datum/office_management/ui_act(action, params)
	. = ..()
	if(.)
		return

	var/mob/user = usr

	switch(action)
		if("select_office")
			var/datum/fixer_office/F = locate(params["office_ref"]) in GLOB.all_fixer_offices
			if(F)
				selected_office = F
				. = TRUE

		if("leave_office")
			if(!ishuman(user))
				return
			var/mob/living/carbon/human/H = user
			for(var/datum/fixer_office/F in GLOB.all_fixer_offices)
				if(H in F.members)
					F.remove_member(H)
					. = TRUE
					break

		if("transfer_leadership")
			if(!selected_office || !ishuman(user))
				return
			var/mob/living/carbon/human/H = user
			if(!selected_office.is_director(H))
				to_chat(user, span_warning("Only the director can transfer leadership!"))
				return

			var/mob/living/carbon/human/new_director = locate(params["member_ref"]) in selected_office.members
			if(new_director && new_director != H)
				selected_office.transfer_leadership(new_director)
				. = TRUE

		if("kick_member")
			if(!selected_office || !ishuman(user))
				return
			var/mob/living/carbon/human/H = user
			if(!selected_office.is_director(H))
				to_chat(user, span_warning("Only the director can kick members!"))
				return

			var/mob/living/carbon/human/member = locate(params["member_ref"]) in selected_office.members
			if(member && member != H)
				selected_office.remove_member(member)
				to_chat(member, span_warning("You have been kicked from [selected_office.name]."))
				. = TRUE

		if("change_color")
			if(!selected_office || !ishuman(user))
				return
			var/mob/living/carbon/human/H = user
			if(!selected_office.is_director(H))
				to_chat(user, span_warning("Only the director can change office color!"))
				return

			var/new_color = input(user, "Choose new office color:", "Office Management", selected_office.office_color) as color|null
			if(new_color)
				selected_office.office_color = new_color
				// Update badge colors if needed
				. = TRUE

// Global proc to open office management
/proc/open_office_management(mob/user)
	var/datum/office_management/OM = new
	OM.ui_interact(user)

// Office Management Console
/obj/machinery/computer/office_management
	name = "office management console"
	desc = "Used to manage fixer office registrations and memberships."
	icon_screen = "comm"
	icon_keyboard = "tech_key"
	light_color = LIGHT_COLOR_BLUE

/obj/machinery/computer/office_management/ui_interact(mob/user)
	. = ..()
	open_office_management(user)

// Verb for admins to manage offices
/client/proc/manage_offices()
	set name = "Manage Fixer Offices"
	set category = "Admin"

	if(!check_rights(R_ADMIN))
		return

	open_office_management(mob)

// Add office management to mind datum for easy access
/datum/mind/proc/has_office()
	if(!current || !ishuman(current))
		return null
	var/mob/living/carbon/human/H = current
	for(var/datum/fixer_office/F in GLOB.all_fixer_offices)
		if(H in F.members)
			return F
	return null

/datum/mind/proc/is_office_director()
	var/datum/fixer_office/office = has_office()
	if(!office || !current)
		return FALSE
	return office.is_director(current)


// Initialize office system on world start
/world/proc/initialize_office_system()
	// This is called during world initialization
	return
