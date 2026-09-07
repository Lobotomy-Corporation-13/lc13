// The terminal the Data Bank is read from.
//
// Feeding it a holographic log opens a sealed record and pays out cans of
// enkephalin. Reading is free and available to anyone who walks up to it.

/obj/machinery/databank_console
	name = "data bank terminal"
	desc = "A star chart that will not hold still, wrapped around a reader. \
		It files whatever the fragmentum leaves behind."
	icon = 'ModularLobotomy/_Lobotomyicons/databank_console.dmi'
	icon_state = "databank"
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE
	resistance_flags = INDESTRUCTIBLE
	max_integrity = 500

/obj/machinery/databank_console/Initialize(mapload)
	. = ..()
	GetDatabankEntries()
	update_icon()

/obj/machinery/databank_console/update_overlays()
	. = ..()
	. += mutable_appearance(icon, "databank_screen")

/obj/machinery/databank_console/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/holo_log))
		FileLog(I, user)
		return
	return ..()

/// Reads a log into the bank. The log is only spent if a record opened.
/obj/machinery/databank_console/proc/FileLog(obj/item/holo_log/log, mob/user)
	var/datum/databank_entry/opened
	if(log.bound_entry && !DatabankIsOpen(log.bound_entry))
		opened = log.bound_entry
		GLOB.databank_unlocked["[opened.type]"] = TRUE
	else
		opened = DatabankOpenRandom()
	if(!opened)
		to_chat(user, span_warning("[src] reads [log] and finds nothing in \
			it the bank does not already hold."))
		playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 40, TRUE)
		return
	qdel(log)
	new /obj/item/stack/compacted_enkephalin(get_turf(src), HOLO_LOG_PE_REWARD)
	playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
	to_chat(user, span_nicegreen("[src] files the log. New record: \
		[opened.name], under [opened.category]."))
	visible_message(span_notice("[src] chimes, and a fresh stack of \
		enkephalin drops into the tray."))
	SStgui.update_uis(src)

// ---- UI ----

/obj/machinery/databank_console/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/databank_console/attack_hand(mob/user, list/modifiers)
	. = ..()
	ui_interact(user)

/obj/machinery/databank_console/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "DataBank")
		ui.open()

/obj/machinery/databank_console/ui_data(mob/user)
	var/list/data = list()
	var/list/counts = list()
	var/list/totals = list()
	for(var/cat in GLOB.databank_categories)
		counts[cat] = 0
		totals[cat] = 0

	// Sealed records send no lore, so a client cannot read ahead of the bank.
	var/list/entries = list()
	for(var/datum/databank_entry/E as anything in GetDatabankEntries())
		if(isnull(totals[E.category]))
			continue
		totals[E.category] += 1
		var/is_open = DatabankIsOpen(E)
		if(is_open)
			counts[E.category] += 1
		entries += list(list(
			"id" = "[E.type]",
			"cat" = E.category,
			"name" = is_open ? E.name : "Sealed Record",
			"subtitle" = is_open ? E.subtitle : "",
			"lore" = is_open ? E.lore : "",
			"open" = is_open,
			"order" = E.sort_order,
		))
	data["entries"] = entries

	var/list/cats = list()
	for(var/cat in GLOB.databank_categories)
		cats += list(list(
			"name" = cat,
			"opened" = counts[cat],
			"total" = totals[cat],
		))
	data["categories"] = cats
	return data

#undef HOLO_LOG_PE_REWARD
