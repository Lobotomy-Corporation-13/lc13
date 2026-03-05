// EGO Printer
// This machine is heavily linked to the Test Range subsystem. Take a look at it if reading or editing this code.
/obj/machinery/ego_printer
	name = "E.G.O. printer"
	desc = "This device is capable of printing most E.G.O. on demand. It can even replicate non-E.G.O. armaments from the City at large. \n\
	You may alt-click this machine to change between the new and old interfaces for printing E.G.O. \n\
	You may also insert any unwanted item into this machine to shred it."
	icon = 'icons/obj/machines/droneDispenser.dmi'
	icon_state = "on"
	resistance_flags = INDESTRUCTIBLE
	/// A list of instantiated ego datums this printer can vend. NEVER delete this as it can be a reference to SStestrange's list. This var is here so you can make custom lists of datums for other printers
	var/list/ego_datums = list()
	/// Only the EGO paths, for the old version of the interface. No relevance to the TGUI interface.
	var/list/ego_datum_paths = list()
	/// This var limits how much EGO each ckey can print before having to get rid of some. Specific to each printer.
	var/ego_per_person_limit = 15
	/// Associates ckey to printed EGO references.
	var/list/printed_ego = list()
	/// Holds ckeys that have disabled the new TGUI version of the interface.
	var/list/disabled_tgui = list()
	/// Anything in this list will be rejected if you try to shred it in the EGO printer.
	var/static/blacklisted_shred_items = list(
		/obj/item/lc_debug/attribute_injector,
		/obj/item/scrying,
	)

/* ---------- Shared TGUI/Old EGO printer stuff ---------- */

/obj/machinery/ego_printer/Initialize(mapload)
	. = ..()
	SStestrange.linked_ego_printers += src
	if(SStestrange.ego_datums_initialized) // If we're being created after datums were already initialized, then pull the ego datum lists
		ego_datums = SStestrange.ego_datums
		ego_datum_paths = SStestrange.ego_datum_paths

/// Alt clicking the printer swaps between new and old interfaces.
// Temporary; we can make this a Pref later if we ever update the real EGO purchase console to use TGUI
/obj/machinery/ego_printer/AltClick(mob/user)
	disabled_tgui ^= user.ckey // Allegedly this is an XOR operator which should "toggle" the value
	to_chat(user, span_notice("Toggled interface type for EGO printer."))
	balloon_alert(user, "Toggled interface type for EGO printer.")

/obj/machinery/ego_printer/Destroy(force)
	SStestrange.linked_ego_printers -= src
	return ..()

/// We use this to bounce attempts to access the printer before it's assembled the full list of EGO datums.
/obj/machinery/ego_printer/proc/CheckInitializedDatums(mob/living/user)
	if(SStestrange.ego_datums_initializing || !(SStestrange.ego_datums_initialized))
		var/not_ready_message = "System is still initializing. Please wait. [SStestrange.ego_datums ? length(SStestrange.ego_datums) : "0"] E.G.O. currently loaded."
		if(istype(user) && user.stat < DEAD)
			say(not_ready_message)
			playsound(get_turf(src), 'sound/machines/synth_no.ogg', 40, TRUE)
		else
			to_chat(user, span_warning(not_ready_message))
		return FALSE
	return TRUE

/// SStestrange calls this on all its linked printers when it finishes loading EGO datums to warn players that it's ready for operation
/obj/machinery/ego_printer/proc/ReadyMessage()
	visible_message(span_nicegreen("The [src.name] beeps, now displaying a list of E.G.O. ready to print."))
	say("System initialization complete!")
	playsound(get_turf(src), 'sound/machines/terminal_success.ogg', 40, TRUE)

/// Let someone qdel items by hitting this machine with it. It's this specific override and ..() happens at the end so we can bypass attribute requirements.
// I'm letting people qdel any item here, I swear if people start abusing this.........................................................
/obj/machinery/ego_printer/attackby(obj/item/I, mob/living/user, params)
	if(!(I.type in blacklisted_shred_items))
		to_chat(user, span_danger("You begin inserting [I] into a dangerous-looking compartment in the machine..."))
		if(do_after(user, 1 SECONDS, src, interaction_key = "ego_printer_shred", max_interact_count = 1))
			visible_message(span_warning("The [src.name] makes a concerning sound as [user] inserts [I] into it."))
			playsound(get_turf(src), 'sound/machines/juicer.ogg', 20, TRUE)
			qdel(I) // Its removal from the user's printed ego list is handled by a signal.
			return
		else
			to_chat(user, span_warning("You decide not to destroy [I]."))
	. = ..()

/// If the user isn't at the limit of printed EGO, print whatever ego_path is (this could be literally anything but is hopefully an /obj/item)
/obj/machinery/ego_printer/proc/DispenseEgo(mob/living/user, ego_path)
	if(!ego_path)
		return

	var/user_prints = printed_ego[user.ckey]

	// Firstly, don't allow users to print too much EGO. This is just spam prevention since now it is very easy to spawn 50000000000 chaos dunks which could cause [A Bit] of lag
	if(islist(user_prints))
		var/list/thats_a_lot_of_ego = user_prints

		// Clean up the user's deleted EGO from its list. I know having a bunch of ghost references in their list is iffy but the alternative is attaching a signal to everything we print to remove it from the list as it gets qdeleted...
		for(var/atom/thing in thats_a_lot_of_ego)
			if(QDELETED(thing))
				thats_a_lot_of_ego -= thing

		if(length(thats_a_lot_of_ego) >= ego_per_person_limit)
			to_chat(user, span_warning("You've printed too much E.G.O. gear. Place some back into the printer."))
			playsound(src, 'sound/machines/buzz-two.ogg', 50)
			return

	var/atom/dispensed_item = new ego_path((get_turf(user)))

	if(istype(dispensed_item)) // Could register signals on it or whatever if you need to here
		RegisterSignal(dispensed_item, COMSIG_PARENT_QDELETING, PROC_REF(CleanupPrintedEgo))
		visible_message(span_nicegreen("The [src.name] beeps as it prints [dispensed_item] for [user]."))
		playsound(get_turf(src), 'sound/machines/ping.ogg', 50, TRUE)
		if(islist(user_prints))
			user_prints |= dispensed_item
		else
			printed_ego[user.ckey] = list(dispensed_item)
		return

	to_chat(user, span_warning("Something's gone horribly wrong with the E.G.O. printing process... contact a coder and tell them [ego_path] is bugged on the testing range printer."))
	playsound(src, 'sound/machines/buzz-two.ogg', 50)

/// Called by an EGO we printed and previously registered into a player's printed EGO list, when it is being deleted. This is so we don't have a buncha qdeleted stuff sitting in a list.
/obj/machinery/ego_printer/proc/CleanupPrintedEgo(datum/source)
	SIGNAL_HANDLER
	for(var/ckey in printed_ego)
		if(source in printed_ego[ckey])
			printed_ego[ckey] -= source
			break
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)
	return

/* ---------- TGUI EGO Printer stuff ---------- */

// Happens when someone touches this machine with their bare hand.
/obj/machinery/ego_printer/ui_interact(mob/user, datum/tgui/ui)
	if(!CheckInitializedDatums(user))
		return

	if((user.ckey in disabled_tgui))
		INVOKE_ASYNC(src, PROC_REF(ShowOldInterface), user)
		return

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TestRangeEgoPrinter", "E.G.O. Printer")
		ui.set_autoupdate(FALSE)
		ui.open()

// Static data because we really don't expect the EGO datums for this to dynamically change.
/obj/machinery/ego_printer/ui_static_data(mob/user)
	var/list/data = list()
	data["ego_weapon_datums"] = list()
	data["ego_armor_datums"] = list()
	data["ego_auxiliary_datums"] = list()
	data["all_tags"] = list()

	// Get all the EGO tags defined in EGO_TAGS_DESCRIPTION_LIST and send an object consisting of their name and description, also tag_checked so we can easily turn their filtering on and off in the frontend
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
			"threatclass" = ego_threatclass,
			"origin" = ED.origin
		)
		if(istype(ED, /datum/ego_datum/weapon))
			data["ego_weapon_datums"] |= list(datum_data)
		else if(istype(ED, /datum/ego_datum/armor))
			data["ego_armor_datums"] |= list(datum_data)
		else if(istype(ED, /datum/ego_datum/auxiliary))
			datum_data["category"] = ED.item_category
			data["ego_auxiliary_datums"] |= list(datum_data)

	return data

// The frontend calls this with a certain action and payload.
/obj/machinery/ego_printer/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	if(action == "print_ego")
		var/chosen_ego = params["chosen_ego"]
		DispenseEgo(usr, chosen_ego)
		update_icon()
		return FALSE // I know this looks EXTREMELY suspect but I don't want the UI to update when you do this. Else, it resets the scrolling position on the ego list.

/* ---------- Old EGO Printer stuff ---------- */

/// Not 1:1 to old logic, we use the new version of the ego datum list and rip the paths out of it, also uses the new dispense proc.
/obj/machinery/ego_printer/proc/ShowOldInterface(mob/living/user)
	var/list/ego_list = ego_datum_paths

	user.playsound_local(user, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
	var/chosen_ego = tgui_input_list(user,"Which EGO do you want to print","Select EGO", ego_list)
	if((!chosen_ego))
		user.playsound_local(user, 'sound/machines/terminal_error.ogg', 50, FALSE)
		to_chat(user, span_warning("No EGO was specified."))
		return
	DispenseEgo(user, chosen_ego)

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
	var/area/A = get_area(src) // cataclysmic world iteration, remove when reworking this (if you iterate over an area you are iterating over the entire world)
	for(var/mob/living/carbon/human/H in A)
		if(H.stat != DEAD)
			return
	for(var/mob/M in A)
		if(M.stat != DEAD)
			qdel(M)
