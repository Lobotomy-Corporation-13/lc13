/**
 * Resurgence Outpost - Event Debug Tool
 *
 * Admin item for testing and controlling events.
 */

/obj/item/resurgence_event_debugger
	name = "event debugger"
	desc = "A debug tool for testing resurgence events. Admin only."
	icon = 'icons/obj/device.dmi'
	icon_state = "multitool"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/resurgence_event_debugger/attack_self(mob/user)
	ui_interact(user)

/obj/item/resurgence_event_debugger/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ResurgenceEventDebug", "Event Debugger")
		ui.open()

/obj/item/resurgence_event_debugger/ui_state(mob/user)
	return GLOB.admin_state

/obj/item/resurgence_event_debugger/ui_data(mob/user)
	var/list/data = list()

	// Event manager status
	data["manager_exists"] = !!GLOB.resurgence_events
	data["manager_running"] = GLOB.resurgence_events?.running

	// Active events
	if(GLOB.resurgence_events)
		data["active_events"] = GLOB.resurgence_events.get_active_events_data()
	else
		data["active_events"] = list()

	// Global modifiers
	data["yield_modifier"] = GLOB.resurgence_yield_modifier
	data["growth_modifier"] = GLOB.resurgence_growth_modifier
	data["work_modifier"] = GLOB.resurgence_work_modifier
	data["sell_modifier"] = GLOB.resurgence_sell_modifier
	data["buy_modifier"] = GLOB.resurgence_buy_modifier
	data["faith_regen_modifier"] = GLOB.resurgence_faith_regen_modifier
	data["quality_bonus"] = GLOB.resurgence_quality_bonus
	data["durability_modifier"] = GLOB.resurgence_durability_modifier

	return data

/obj/item/resurgence_event_debugger/ui_static_data(mob/user)
	var/list/data = list()

	// All available event types
	if(GLOB.resurgence_events)
		data["event_types"] = GLOB.resurgence_events.get_all_event_types()
	else
		// Build list manually if manager doesn't exist
		var/list/types = list()
		for(var/path in subtypesof(/datum/resurgence_event))
			var/datum/resurgence_event/E = path
			if(initial(E.weight) <= 0)
				continue
			types += list(list(
				"path" = "[path]",
				"name" = initial(E.name),
				"category" = initial(E.category)
			))
		data["event_types"] = types

	return data

/obj/item/resurgence_event_debugger/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("start_manager")
			if(!GLOB.resurgence_events)
				GLOB.resurgence_events = new /datum/resurgence_event_manager()
			GLOB.resurgence_events.start()
			message_admins("[key_name_admin(usr)] started the event manager.")
			return TRUE

		if("stop_manager")
			if(GLOB.resurgence_events)
				GLOB.resurgence_events.stop()
				message_admins("[key_name_admin(usr)] stopped the event manager.")
			return TRUE

		if("trigger_event")
			var/event_path = text2path(params["path"])
			if(!event_path)
				return FALSE
			if(!GLOB.resurgence_events)
				GLOB.resurgence_events = new /datum/resurgence_event_manager()
			if(GLOB.resurgence_events.force_event(event_path))
				var/datum/resurgence_event/E = event_path
				message_admins("[key_name_admin(usr)] forced event: [initial(E.name)]")
				return TRUE
			to_chat(usr, span_warning("Failed to trigger event."))
			return FALSE

		if("end_event")
			var/event_name = params["name"]
			if(!event_name || !GLOB.resurgence_events)
				return FALSE
			if(GLOB.resurgence_events.end_event_by_name(event_name))
				message_admins("[key_name_admin(usr)] ended event: [event_name]")
				return TRUE
			return FALSE

		if("end_all_events")
			if(!GLOB.resurgence_events)
				return FALSE
			var/count = 0
			for(var/datum/resurgence_event/E in GLOB.resurgence_events.active_events)
				E.end_event(silent = TRUE)
				count++
			GLOB.resurgence_events.active_events.Cut()
			message_admins("[key_name_admin(usr)] ended all events ([count]).")
			return TRUE

		if("reset_modifiers")
			GLOB.resurgence_yield_modifier = 1.0
			GLOB.resurgence_growth_modifier = 1.0
			GLOB.resurgence_work_modifier = 1.0
			GLOB.resurgence_sell_modifier = 1.0
			GLOB.resurgence_buy_modifier = 1.0
			GLOB.resurgence_faith_regen_modifier = 1.0
			GLOB.resurgence_quality_bonus = 0
			GLOB.resurgence_durability_modifier = 1.0
			message_admins("[key_name_admin(usr)] reset all event modifiers.")
			return TRUE

	return FALSE
