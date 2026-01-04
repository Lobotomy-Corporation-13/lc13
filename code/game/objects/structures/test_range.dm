// EGO Printer
/obj/machinery/ego_printer
	name = "EGO printer"
	desc = "This device is capable of printing most EGO on demand."
	icon = 'icons/obj/machines/droneDispenser.dmi'
	icon_state = "on"
	resistance_flags = INDESTRUCTIBLE
	var/static/list/ego_datums = list()
	var/ego_datums_initialized = FALSE

/obj/machinery/ego_printer/proc/InitializeDatums()
	if(!ego_datums_initialized)
		for(var/datumpath in subtypesof(/datum/ego_datum))
			var/datum/ego_datum/ED = new datumpath
			if(!(ED.testrange_blacklisted))
				ego_datums |= ED
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
			"tags" = ED.information["tags"]
		)

		data["ego_datums"] |= list(datum_data)

	return data

/obj/machinery/ego_printer/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	warning("[src] received [action] action")
	if(action == "print_ego")
		warning("[src] attempting EGO print")
		var/chosen_ego = params["chosen_ego"]
		DispenseEgo(usr, chosen_ego)
	. = TRUE
	update_icon()

/obj/machinery/ego_printer/proc/DispenseEgo(mob/living/user, ego_path)
	warning("Received ego_path is: [ego_path] from user [user]")
	var/unstringified = ego_path
	new unstringified((get_turf(user)))
	to_chat(user, span_nicegreen("You successfully printed the EGO."))

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
