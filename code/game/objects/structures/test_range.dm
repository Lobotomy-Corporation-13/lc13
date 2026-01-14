// EGO Printer
/obj/machinery/ego_printer
	name = "E.G.O. printer"
	desc = "This device is capable of printing most E.G.O. on demand."
	icon = 'icons/obj/machines/droneDispenser.dmi'
	icon_state = "on"
	resistance_flags = INDESTRUCTIBLE
	/// A list of instantiated ego datums this printer can vend. NEVER delete this as it can be a reference to SStestrange's list. This var is here so you can make custom lists of datums for other printers
	var/list/ego_datums = list()
	/// This var limits how much EGO each ckey can print before having to get rid of some. Specific to each printer.
	var/ego_per_person_limit = 10
	var/list/printed_ego = list()

/obj/machinery/ego_printer/attackby(obj/item/I, mob/living/user, params)
	var/list/this_guys_printed_ego = printed_ego[user.ckey]
	if(islist(this_guys_printed_ego))
		if(I in this_guys_printed_ego)
			visible_message(span_warning("The [src.name] makes a concerning sound as [user] inserts [I] back into it."))
			playsound(get_turf(src), 'sound/machines/juicer.ogg', 40, TRUE)
			this_guys_printed_ego -= I
			qdel(I)
			return
	. = ..()

/obj/machinery/ego_printer/Initialize(mapload)
	. = ..()
	SStestrange.linked_ego_printers += src

/obj/machinery/ego_printer/Destroy(force)
	SStestrange.linked_ego_printers -= src
	return ..()

/obj/machinery/ego_printer/proc/CheckInitializedDatums()
	if(SStestrange.ego_datums_initializing || !(SStestrange.ego_datums_initialized))
		say("System is still initializing. Please wait. [SStestrange.ego_datums ? length(SStestrange.ego_datums) : "0"] E.G.O. currently loaded.")
		playsound(get_turf(src), 'sound/machines/synth_no.ogg', 40, TRUE)
		return FALSE
	return TRUE

/obj/machinery/ego_printer/proc/ReadyMessage()
	visible_message(span_nicegreen("The [src.name] beeps, now displaying a list of E.G.O. ready to print."))
	say("System initialization complete!")
	playsound(get_turf(src), 'sound/machines/terminal_success.ogg', 40, TRUE)

/obj/machinery/ego_printer/ui_interact(mob/user, datum/tgui/ui)
	if(!CheckInitializedDatums())
		return

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TestRangeEgoPrinter", "E.G.O. Printer")
		ui.set_autoupdate(FALSE)
		ui.open()

/obj/machinery/ego_printer/ui_static_data(mob/user)
	var/list/data = list()
	data["ego_weapon_datums"] = list()
	data["ego_armor_datums"] = list()
	data["all_tags"] = list()

	for(var/tag in EGO_TAGS_DESCRIPTION_LIST)
		var/list/tag_object = list("tag_name" = tag, "tag_description" = EGO_TAGS_DESCRIPTION_LIST[tag], "tag_checked" = FALSE)
		data["all_tags"] |= list(tag_object)

	for(var/datum/ego_datum/ED in ego_datums)
		if(!ED.item_path)
			continue

		var/ego_threatclass = ED.CostToThreatClass()
		var/ego_tags = ED.ego_tags
		if(!islist(ego_tags))
			ego_tags = list(ego_tags)

		var/list/datum_data = list(
			"path" = ED.item_path,
			"cost" = ED.cost,
			"information" = ED.information,
			"tags" = ED.ego_tags,
			"icon" = SStestrange.GenerateEgoPreviewIcon(ED.item_path),
			"threatclass" = ego_threatclass
		)
		if(istype(ED, /datum/ego_datum/weapon))
			data["ego_weapon_datums"] |= list(datum_data)
		else if(istype(ED, /datum/ego_datum/armor))
			data["ego_armor_datums"] |= list(datum_data)

	return data

/obj/machinery/ego_printer/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	if(action == "print_ego")
		var/chosen_ego = params["chosen_ego"]
		DispenseEgo(usr, chosen_ego)
		update_icon()
		return FALSE // I know this looks EXTREMELY suspect but I don't want the UI to update when you do this. Else it resets the scrolling position on the ego list

/obj/machinery/ego_printer/proc/DispenseEgo(mob/living/user, ego_path)
	if(!ego_path)
		return

	var/user_prints = printed_ego[user.ckey]

	// Firstly, don't allow users to print too much EGO. This is just spam prevention since now it is very easy to spawn 50000000000 chaos dunks which could cause [A Bit] of lag
	if(islist(user_prints))
		var/list/thats_a_lot_of_ego = user_prints

		// I can't imagine this happening with anything off the top of my head, but if an EGO gets deleted somehow before the user can place it back into the printer, it could permanently stay in their printed ego list.
		// So this little code block should handle exceptions for that without having to use a signal on deletion instead.
		for(var/atom/thing in thats_a_lot_of_ego)
			if(QDELETED(thing))
				thats_a_lot_of_ego -= thing

		if(length(thats_a_lot_of_ego) >= ego_per_person_limit)
			to_chat(user, span_warning("You've printed too much E.G.O. gear. Place some back into the printer."))
			playsound(src, 'sound/machines/buzz-two.ogg', 50)
			return

	var/atom/dispensed_item = new ego_path((get_turf(user)))

	if(istype(dispensed_item)) // Register signals on it or whatever if you need to here
		visible_message(span_nicegreen("The [src.name] beeps as it prints [dispensed_item]."))
		playsound(get_turf(src), 'sound/machines/ping.ogg', 50, TRUE)
		if(islist(user_prints))
			user_prints |= dispensed_item
		else
			printed_ego[user.ckey] = list(dispensed_item)
		return

	to_chat(user, span_warning("Something's gone horribly wrong with the E.G.O. printing process... contact a coder and tell them [ego_path] is bugged on the testing range printer."))
	playsound(src, 'sound/machines/buzz-two.ogg', 50)

//Abnormality Spawner
/obj/machinery/computer/testrangespawner
	name = "Abnormality Spawner"
	desc = "This device is used to spawn an abnormality to fight"
	resistance_flags = INDESTRUCTIBLE
	var/list/whitelist = list(
		/mob/living/simple_animal/hostile/abnormality/forsaken_murderer,
		/mob/living/simple_animal/hostile/abnormality/redblooded,
		/mob/living/simple_animal/hostile/abnormality/pinocchio,
		/mob/living/simple_animal/hostile/abnormality/funeral,
		/mob/living/simple_animal/hostile/abnormality/scarecrow,
		/mob/living/simple_animal/hostile/abnormality/blue_shepherd,
		/mob/living/simple_animal/hostile/abnormality/ebony_queen,
		/mob/living/simple_animal/hostile/abnormality/judgement_bird,
		/mob/living/simple_animal/hostile/abnormality/warden,
		/mob/living/simple_animal/hostile/abnormality/nothing_there,
		/mob/living/simple_animal/hostile/abnormality/silentorchestra,
		/mob/living/simple_animal/hostile/abnormality/last_shot,
		/mob/living/simple_animal/hostile/abnormality/distortedform,
	)

/obj/machinery/computer/testrangespawner/attack_hand(mob/living/user)
	. = ..()
	var/arena_z = z + 3
	var/mob/living/simple_animal/hostile/abnormality/chosen_abno = tgui_input_list(user,"Choose which Abnormality to fight.","Select Abnormality", whitelist)
	var/turf/location = locate(13,14,arena_z) //Might not be the best way to set it up right now but it works.
	if(chosen_abno)
		var/mob/living/simple_animal/hostile/abnormality/abnospawned = new chosen_abno(location)
		abnospawned.core_enabled = FALSE
		if(istype(abnospawned, /mob/living/simple_animal/hostile/abnormality/pinocchio)) //To check if BreachEffect() is needed for the abno to work properly
			abnospawned.BreachEffect()

/obj/machinery/computer/testrangespawner/process()
	var/area/A = get_area(src) // cataclysmic world iteration, remove before merge
	for(var/mob/living/carbon/human/H in A)
		if(H.stat != DEAD)
			return
	for(var/mob/M in A)
		if(M.stat != DEAD)
			qdel(M)
