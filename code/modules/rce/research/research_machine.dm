// RCE Research Machine - Processes body parts into research points and unlocks pyro weapons

/obj/machinery/rce_research
	name = "R-Corp biological research station"
	desc = "An advanced research station that analyzes biological samples to unlock new pyrotechnic weaponry. Insert body parts to generate research points."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "d_analyzer"
	density = TRUE
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 10
	active_power_usage = 100
	var/list/completed_research = list()
	var/datum/rce_research_node/selected_research // Which research to feed parts to
	var/list/research_progress = list() // Tracks progress for each research project
	var/list/stored_parts = list() // Body parts waiting to be processed
	var/processing_part = FALSE
	var/process_time = 3 SECONDS

/obj/machinery/rce_research/Initialize()
	. = ..()
	// Initialize research tree if not already done
	if(!length(GLOB.rce_research_nodes))
		initialize_research_tree()
		world.log << "RCE Research: Initialized [length(GLOB.rce_research_nodes)] research nodes"
	else
		world.log << "RCE Research: Already have [length(GLOB.rce_research_nodes)] research nodes"

/obj/machinery/rce_research/examine(mob/user)
	. = ..()
	if(selected_research)
		var/progress = research_progress[selected_research.id] || 0
		. += span_notice("Selected research target: [selected_research.name] ([progress]/[selected_research.cost] points)")
	. += span_notice("Stored samples: [length(stored_parts)]")
	. += span_notice("Alt-click to open the research interface.")

/obj/machinery/rce_research/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/rce_bodypart))
		var/obj/item/rce_bodypart/part = I
		if(length(stored_parts) >= 10)
			to_chat(user, span_warning("[src] sample storage is full! Process some samples first."))
			return
		if(!user.transferItemToLoc(part, src))
			return
		stored_parts += part
		to_chat(user, span_notice("You insert [part] into [src]."))
		playsound(src, 'sound/machines/click.ogg', 50, TRUE)
		update_icon()
		return
	return ..()

/obj/machinery/rce_research/AltClick(mob/user)
	. = ..()
	if(!user.canUseTopic(src, BE_CLOSE))
		return
	ui_interact(user)

/obj/machinery/rce_research/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RCEResearch")
		ui.open()

/obj/machinery/rce_research/ui_data(mob/user)
	var/list/data = list()
	data["selectedResearch"] = selected_research?.id
	data["storedParts"] = length(stored_parts)
	// Add progress data for each research
	var/list/progress_data = list()
	for(var/node_id in GLOB.rce_research_nodes)
		progress_data[node_id] = research_progress[node_id] || 0
	data["researchProgress"] = progress_data

	// Research tree data
	var/list/tree_data = list()
	world.log << "RCE Research UI: Building tree data from [length(GLOB.rce_research_nodes)] nodes"
	for(var/node_id in GLOB.rce_research_nodes)
		var/datum/rce_research_node/node = GLOB.rce_research_nodes[node_id]
		var/status = get_node_status(node)
		tree_data += list(list(
			"id" = node.id,
			"name" = node.name,
			"desc" = node.desc,
			"tier" = node.tier,
			"cost" = node.cost,
			"status" = status,
			"progress" = research_progress[node.id] || 0,
			"prerequisites" = node.prerequisites,
			"favoredTraits" = node.favored_traits,
			"negativeTraits" = node.negative_traits,
			"requiredTraits" = node.required_traits
		))
	world.log << "RCE Research UI: Sending [length(tree_data)] nodes to UI"
	data["researchTree"] = tree_data

	// Stored parts data
	var/list/parts_data = list()
	for(var/obj/item/rce_bodypart/part in stored_parts)
		parts_data += list(list(
			"name" = part.name,
			"traits" = part.traits,
			"baseValue" = part.base_value,
			"source" = part.source_mob
		))
	data["partsList"] = parts_data

	return data

/obj/machinery/rce_research/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("selectResearch")
			var/node_id = params["nodeId"]
			if(!node_id || !GLOB.rce_research_nodes[node_id])
				return
			var/datum/rce_research_node/node = GLOB.rce_research_nodes[node_id]
			if(get_node_status(node) != RESEARCH_AVAILABLE)
				to_chat(usr, span_warning("This research is not available!"))
				return
			selected_research = node
			to_chat(usr, span_notice("Selected [node.name] as research target. Insert body parts to progress."))
			return TRUE

		if("deselectResearch")
			if(!selected_research)
				return
			to_chat(usr, span_notice("Deselected [selected_research.name]."))
			selected_research = null
			return TRUE

		if("processPart")
			if(processing_part)
				to_chat(usr, span_warning("Already processing a sample!"))
				return
			if(!length(stored_parts))
				to_chat(usr, span_warning("No samples to process!"))
				return
			if(!selected_research)
				to_chat(usr, span_warning("Select a research project first!"))
				return
			process_next_part()
			return TRUE

		if("processAll")
			if(processing_part)
				to_chat(usr, span_warning("Already processing samples!"))
				return
			if(!length(stored_parts))
				to_chat(usr, span_warning("No samples to process!"))
				return
			if(!selected_research)
				to_chat(usr, span_warning("Select a research project first!"))
				return
			process_all_parts()
			return TRUE

/obj/machinery/rce_research/proc/get_node_status(datum/rce_research_node/node)
	if(node.id in completed_research)
		return RESEARCH_COMPLETED

	// Check prerequisites
	for(var/prereq in node.prerequisites)
		if(!(prereq in completed_research))
			return RESEARCH_LOCKED

	return RESEARCH_AVAILABLE

/obj/machinery/rce_research/proc/process_next_part()
	if(!length(stored_parts) || processing_part || !selected_research)
		return

	processing_part = TRUE
	var/obj/item/rce_bodypart/part = stored_parts[1]
	stored_parts -= part

	// Calculate value based on selected research
	var/value = part.calculate_value(selected_research.favored_traits, selected_research.negative_traits, selected_research.required_traits)
	if(value == 0)
		to_chat(usr, span_warning("[part] doesn't meet the requirements for [selected_research.name]!"))
		qdel(part)
		processing_part = FALSE
		return

	// Visual feedback
	playsound(src, 'sound/machines/blender.ogg', 50, TRUE)
	icon_state = "d_analyzer_process"

	addtimer(CALLBACK(src, PROC_REF(finish_processing), part, value), process_time)

/obj/machinery/rce_research/proc/finish_processing(obj/item/rce_bodypart/part, value)
	if(!selected_research)
		qdel(part)
		processing_part = FALSE
		icon_state = "d_analyzer"
		return

	// Add points to selected research
	var/current_progress = research_progress[selected_research.id] || 0
	current_progress = min(current_progress + value, selected_research.cost)
	research_progress[selected_research.id] = current_progress
	to_chat(usr, span_notice("Added [value] points to [selected_research.name]. ([current_progress]/[selected_research.cost])"))

	// Check if research is complete
	if(current_progress >= selected_research.cost)
		complete_research(selected_research)

	qdel(part)
	processing_part = FALSE
	icon_state = "d_analyzer"
	update_icon()

	// Process next part if any
	if(length(stored_parts) && selected_research)
		process_next_part()

/obj/machinery/rce_research/proc/process_all_parts()
	process_next_part()

/obj/machinery/rce_research/proc/complete_research(datum/rce_research_node/node)
	completed_research += node.id
	selected_research = null
	research_progress[node.id] = node.cost // Mark as fully complete

	// Create the unlocked item
	var/obj/item/result = new node.unlocked_path(get_turf(src))
	playsound(src, 'sound/machines/ping.ogg', 50, TRUE)
	visible_message(span_notice("[src] completes research of [node.name]!"))
	say("Research complete: [node.name]. Product dispensed.")

	// Special handling for portable factories
	if(istype(result, /obj/item/portable_factory))
		var/obj/item/portable_factory/PF = result
		PF.factory_name = node.name
		PF.factory_desc = node.desc

/obj/machinery/rce_research/proc/initialize_research_tree()
	// This will be populated by research_tree.dm
	return

// Portable factory item that can be deployed
/obj/item/portable_factory
	name = "portable factory module"
	desc = "A compact factory module that can be deployed to produce specialized equipment."
	icon = 'icons/obj/module.dmi'
	icon_state = "ash_plating"
	w_class = WEIGHT_CLASS_NORMAL
	var/factory_path = /obj/structure/rcorp_factory
	var/factory_name = "portable factory"
	var/factory_desc = "A deployed factory unit."

/obj/item/portable_factory/examine(mob/user)
	. = ..()
	. += span_notice("Use in hand to deploy the factory.")

/obj/item/portable_factory/attack_self(mob/user)
	. = ..()
	deploy(user)

/obj/item/portable_factory/proc/deploy(mob/user)
	var/turf/T = get_turf(user)
	if(!T || T.density)
		to_chat(user, span_warning("You can't deploy the factory here!"))
		return

	var/obj/structure/rcorp_factory/F = new factory_path(T)
	F.name = factory_name
	F.desc = factory_desc
	to_chat(user, span_notice("You deploy [src]."))
	playsound(T, 'sound/items/ratchet.ogg', 50, TRUE)
	qdel(src)
