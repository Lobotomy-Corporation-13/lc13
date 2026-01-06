// EGO Printer
/obj/machinery/ego_printer
	name = "E.G.O. printer"
	desc = "This device is capable of printing most E.G.O. on demand."
	icon = 'icons/obj/machines/droneDispenser.dmi'
	icon_state = "on"
	resistance_flags = INDESTRUCTIBLE
	var/static/list/ego_datums = list()
	var/static/list/ego_preview_icons_cache = list()
	var/ego_per_person_limit = 6
	var/list/printed_ego = list()
	var/ego_datums_initialized = FALSE


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


/obj/machinery/ego_printer/proc/InitializeDatums()
	if(!ego_datums_initialized)
		for(var/datumpath in subtypesof(/datum/ego_datum))
			var/datum/ego_datum/ED = new datumpath
			if(!(ED.testrange_blacklisted) && (ED.item_path))
				ego_datums |= ED
				GenerateEgoPreviewIcon(ED.item_path)
			else
				qdel(ED)

		ego_datums_initialized = TRUE

/obj/machinery/ego_printer/ui_interact(mob/user, datum/tgui/ui)
	InitializeDatums()

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TestRangeEgoPrinter", "E.G.O. Printer")
		ui.open()

/obj/machinery/ego_printer/ui_data(mob/user)
	var/list/data = list()
	data["ego_datums"] = list()
	for(var/datum/ego_datum/ED in ego_datums)
		if(!ED.item_path)
			continue
		var/list/datum_data = list(
			"path" = ED.item_path,
			"cost" = ED.cost,
			"information" = ED.information,
			"icon" = GenerateEgoPreviewIcon(ED.item_path)
		)

		data["ego_datums"] |= list(datum_data)
	return data

/obj/machinery/ego_printer/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	if(action == "print_ego")
		var/chosen_ego = params["chosen_ego"]
		DispenseEgo(usr, chosen_ego)
	. = TRUE
	update_icon()

// Had to look at Augment code to figure out how to send icons to TGUI, this should work just fine
/obj/machinery/ego_printer/proc/GenerateEgoPreviewIcon(item_path)
	if(!ispath(item_path))
		return

	var/wait_did_we_already_do_this = ego_preview_icons_cache[item_path]
	if(wait_did_we_already_do_this)
		return wait_did_we_already_do_this

	var/icon/final_icon = GetEgoDatumItemIcon(item_path)
	var/base64icon = null

	if(final_icon)
		base64icon = icon2base64(final_icon)
		ego_preview_icons_cache[item_path] = base64icon

	qdel(final_icon)
	return base64icon

/obj/machinery/ego_printer/proc/GetEgoDatumItemIcon(obj/item/item_path)
	if(!ispath(item_path))
		return
	var/item_icon = initial(item_path.icon)
	var/item_icon_state = initial(item_path.icon_state)
	if(!(item_icon_state in icon_states(icon(item_icon))))
		return null
	var/icon/final_icon = icon(icon = item_icon, icon_state = item_icon_state, frame = 1)
	return final_icon

/obj/machinery/ego_printer/proc/DispenseEgo(mob/living/user, ego_path)
	if(!ego_path)
		return

	var/user_prints = printed_ego[user.ckey]

	if(islist(user_prints))
		var/list/thats_a_lot_of_ego = user_prints
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
