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
	var/list/research_completions = list() // Tracks how many times each research has been completed (for starter kits)
	var/list/stored_parts = list() // Body parts waiting to be processed
	var/processing_part = FALSE
	var/process_time = 3 SECONDS
	/// Whether the Hellfire Rooster branch is enabled for research
	var/hellfire_branch_enabled = TRUE
	/// Whether the Venom Rattlesnake branch is enabled for research
	var/venom_branch_enabled = TRUE
	/// Whether the Storm Ram branch is enabled for research (disabled - bugs to fix)
	var/storm_branch_enabled = FALSE

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
		var/effective_cost = get_effective_cost(selected_research)
		. += span_notice("Selected research target: [selected_research.name] ([progress]/[effective_cost] points)")
	. += span_notice("Stored samples: [length(stored_parts)]")
	. += span_notice("Alt-click to open the research interface.")

/obj/machinery/rce_research/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/rce_bodypart))
		var/obj/item/rce_bodypart/part = I
		if(length(stored_parts) >= 25)
			to_chat(user, span_warning("[src] sample storage is full! Process some samples first."))
			return
		if(!user.transferItemToLoc(part, src))
			return
		stored_parts += part
		to_chat(user, span_notice("You insert [part] into [src]."))
		playsound(src, 'sound/machines/click.ogg', 50, TRUE)
		update_icon()
		return
	if(istype(I, /obj/item/storage/bag/rce_bodyparts))
		var/obj/item/storage/bag/rce_bodyparts/bag = I
		var/datum/component/storage/STR = bag.GetComponent(/datum/component/storage)
		if(!STR)
			return ..()
		var/parts_added = 0
		var/list/parts_to_add = list()
		for(var/obj/item/rce_bodypart/part in bag.contents)
			parts_to_add += part
		if(!length(parts_to_add))
			to_chat(user, span_warning("The bag is empty!"))
			return
		for(var/obj/item/rce_bodypart/part in parts_to_add)
			if(length(stored_parts) >= 25)
				to_chat(user, span_warning("[src] sample storage is full! Inserted [parts_added] samples."))
				break
			part.forceMove(src)
			stored_parts += part
			parts_added++
		if(parts_added > 0)
			to_chat(user, span_notice("You insert [parts_added] samples from [bag] into [src]."))
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

	// Branch enabled status
	data["branchEnabled"] = list(
		"hellfire" = hellfire_branch_enabled,
		"venom" = venom_branch_enabled,
		"storm" = storm_branch_enabled
	)

	// Research tree data
	var/list/tree_data = list()
	world.log << "RCE Research UI: Building tree data from [length(GLOB.rce_research_nodes)] nodes"
	for(var/node_id in GLOB.rce_research_nodes)
		var/datum/rce_research_node/node = GLOB.rce_research_nodes[node_id]
		var/status = get_node_status(node)
		var/effective_cost = get_effective_cost(node)
		tree_data += list(list(
			"id" = node.id,
			"name" = node.name,
			"desc" = node.desc,
			"tier" = node.tier,
			"cost" = effective_cost,
			"baseCost" = node.cost,
			"isStarterKit" = node.is_starter_kit,
			"completions" = research_completions[node.id] || 0,
			"status" = status,
			"progress" = research_progress[node.id] || 0,
			"prerequisites" = node.prerequisites,
			"favoredTraits" = node.favored_traits,
			"negativeTraits" = node.negative_traits,
			"requiredTraits" = node.required_traits,
			"branch" = node.branch
		))
	world.log << "RCE Research UI: Sending [length(tree_data)] nodes to UI"
	data["researchTree"] = tree_data

	// Stored parts data with effectiveness calculation
	var/list/parts_data = list()
	var/part_index = 1
	for(var/obj/item/rce_bodypart/part in stored_parts)
		var/effectiveness = 0
		var/meets_requirements = TRUE
		if(selected_research)
			effectiveness = part.calculate_value(selected_research.favored_traits, selected_research.negative_traits, selected_research.required_traits)
			meets_requirements = effectiveness > 0
		parts_data += list(list(
			"ref" = REF(part),
			"index" = part_index,
			"name" = part.name,
			"traits" = part.traits,
			"baseValue" = part.base_value,
			"source" = part.source_mob,
			"effectiveness" = effectiveness,
			"meetsRequirements" = meets_requirements
		))
		part_index++
	data["partsList"] = parts_data

	// Statistics data - count repeatable research completions per branch
	var/list/stats_data = list(
		"hellfire" = 0,
		"venom" = 0,
		"storm" = 0
	)
	for(var/node_id in research_completions)
		var/datum/rce_research_node/node = GLOB.rce_research_nodes[node_id]
		if(!node)
			continue
		// Only count repeatable items (starter kits and non-factory items)
		if(node.is_starter_kit || !istype(node.unlocked_path, /obj/item/portable_factory))
			var/completions = research_completions[node_id]
			if(completions > 0)
				stats_data[node.branch] += completions
	data["researchStats"] = stats_data

	// Bestiary data - static list of harvestable mobs
	data["bestiary"] = get_bestiary_data()

	return data

/// Returns static bestiary data for the UI
/obj/machinery/rce_research/proc/get_bestiary_data()
	var/list/bestiary = list()

	// X-Corp folder data
	var/list/xcorp_folder = list(
		"id" = "xcorp",
		"name" = "Heart of Greed Units",
		"lore" = "These creatures emerged from deep within X-Corp excavation pits, spawned by a strange flesh construct known as the Heart of Greed. This pulsating organic mass corrupts everything it touches, transforming corpses and beings with weakened willpower into twisted servants. The corrupted spread the Heart's influence, seeking to expand its domain. R-Corp researchers have found their tainted flesh yields valuable biological data for weapon development.",
		"mobs" = list()
	)

	// X-Corp Elite units
	xcorp_folder["mobs"] += list(list(
		"name" = "Sumptus Excessivi",
		"rank" = "Elite",
		"lore" = "Elite heart warriors whose every attack is an expression of violent excess. Berserkers in the truest sense.",
		"traits" = list(TRAIT_ORGANIC, TRAIT_ELITE, TRAIT_WEAPONIZED, TRAIT_BERSERKER),
		"base_value" = 35,
		"drop_chance" = 80,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/greed/heart/dps)
	))
	xcorp_folder["mobs"] += list(list(
		"name" = "Sicarius",
		"rank" = "Elite",
		"lore" = "Precision killers from the heart units. They have honed their excess into deadly accuracy.",
		"traits" = list(TRAIT_ORGANIC, TRAIT_ELITE, TRAIT_PRECISION, TRAIT_AGILE),
		"base_value" = 35,
		"drop_chance" = 80,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/greed/heart/ranged)
	))
	xcorp_folder["mobs"] += list(list(
		"name" = "Accumulatio",
		"rank" = "Elite",
		"lore" = "Heart unit grunts who have begun the transformation into true excess. Their regenerative capabilities are remarkable.",
		"traits" = list(TRAIT_ORGANIC, TRAIT_ELITE, TRAIT_HEAVY, TRAIT_REGENERATIVE),
		"base_value" = 35,
		"drop_chance" = 80,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/greed/heart)
	))

	// X-Corp Standard units
	xcorp_folder["mobs"] += list(list(
		"name" = "X-Corp Studiose",
		"rank" = "Standard",
		"lore" = "Former researchers who delved too deep into the nature of excess. Their volatile nature makes them unpredictable in combat.",
		"traits" = list(TRAIT_ORGANIC, TRAIT_VOLATILE, TRAIT_AGILE),
		"base_value" = 20,
		"drop_chance" = 80,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/greed/dps)
	))
	xcorp_folder["mobs"] += list(list(
		"name" = "X-Corp Nimis",
		"rank" = "Standard",
		"lore" = "Heavily armored enforcers whose bodies have calcified into living shields. Their toxic blood corrodes anything it touches.",
		"traits" = list(TRAIT_ORGANIC, TRAIT_ARMORED, TRAIT_HEAVY, TRAIT_TOXIC),
		"base_value" = 22,
		"drop_chance" = 85,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/greed/tank)
	))
	xcorp_folder["mobs"] += list(list(
		"name" = "X-Corp Praepropere",
		"rank" = "Standard",
		"lore" = "Scouts mutated for speed. They secrete toxins as they move, leaving trails of corruption.",
		"traits" = list(TRAIT_ORGANIC, TRAIT_AGILE, TRAIT_VOLATILE, TRAIT_TOXIC),
		"base_value" = 22,
		"drop_chance" = 75,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/greed/scout)
	))
	xcorp_folder["mobs"] += list(list(
		"name" = "X-Corp Ardenter",
		"rank" = "Standard",
		"lore" = "Sappers with psionic abilities born from their burning desire. They can disrupt minds as easily as machinery.",
		"traits" = list(TRAIT_ORGANIC, TRAIT_PSIONIC, TRAIT_ABERRANT, TRAIT_TOXIC),
		"base_value" = 22,
		"drop_chance" = 90,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/greed/sapper)
	))

	// X-Corp Fodder units
	xcorp_folder["mobs"] += list(list(
		"name" = "X-Corp Laute",
		"rank" = "Fodder",
		"lore" = "The lowest rung of X-Corp's hierarchy. Once ordinary workers, their bodies have bloated with accumulated excess. Slow but resilient.",
		"traits" = list(TRAIT_ORGANIC, TRAIT_FODDER, TRAIT_HEAVY),
		"base_value" = 10,
		"drop_chance" = 100,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/greed)
	))

	bestiary += list(xcorp_folder)

	// Greed Clan folder data
	var/list/greed_folder = list(
		"id" = "greed_clan",
		"name" = "Greed Touched Units",
		"lore" = "Resurgence Clan machines sent by the Tinkerer to salvage equipment from X-Corp caves. They encountered the Heart of Greed's corruption - a spreading infection that thrives on resistance. Fire made it grow faster, drilling gave it new hosts, and explosions scattered its spores. Now these hybrid entities serve the Heart, their mechanical forms fused with pulsating flesh. Their unique composition makes them invaluable research subjects.",
		"mobs" = list()
	)

	// Greed Clan Elite units
	greed_folder["mobs"] += list(list(
		"name" = "Greed Touched Corrupter",
		"rank" = "Elite",
		"lore" = "Command units that spread the Greed infection. Their presence warps both flesh and metal.",
		"traits" = list(TRAIT_HYBRID, TRAIT_CORRUPTED, TRAIT_ELITE, TRAIT_HIVEMIND),
		"base_value" = 60,
		"drop_chance" = 60,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/clan/ranged/corrupter/greed)
	))
	greed_folder["mobs"] += list(list(
		"name" = "Greed Touched Assassin",
		"rank" = "Elite",
		"lore" = "Elite killers whose corruption grants them aberrant speed and agility.",
		"traits" = list(TRAIT_HYBRID, TRAIT_AGILE, TRAIT_ELITE, TRAIT_ABERRANT),
		"base_value" = 35,
		"drop_chance" = 75,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/clan/assassin/greed)
	))
	greed_folder["mobs"] += list(list(
		"name" = "Greed Touched Warper",
		"rank" = "Elite",
		"lore" = "Psionic entities that can bend space. The corruption has given them terrifying mental powers.",
		"traits" = list(TRAIT_HYBRID, TRAIT_NEURAL, TRAIT_PSIONIC, TRAIT_CORRUPTED),
		"base_value" = 35,
		"drop_chance" = 75,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/clan/ranged/warper/greed)
	))
	greed_folder["mobs"] += list(list(
		"name" = "Greed Touched Bomber Spider",
		"rank" = "Elite",
		"lore" = "Explosive units that have embraced self-destruction as their purpose.",
		"traits" = list(TRAIT_HYBRID, TRAIT_VOLATILE, TRAIT_ELITE),
		"base_value" = 30,
		"drop_chance" = 70,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/clan/bomber_spider/greed)
	))

	// Greed Clan Standard units
	greed_folder["mobs"] += list(list(
		"name" = "Greed Touched Demolisher",
		"rank" = "Standard",
		"lore" = "Heavy weapons platforms warped into brutal killing machines. They revel in destruction.",
		"traits" = list(TRAIT_HYBRID, TRAIT_WEAPONIZED, TRAIT_HEAVY, TRAIT_BRUTAL),
		"base_value" = 30,
		"drop_chance" = 85,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/clan/demolisher/greed)
	))
	greed_folder["mobs"] += list(list(
		"name" = "Greed Touched Harpooner",
		"rank" = "Standard",
		"lore" = "Brutal hunters that drag prey into melee range. The Greed has made them sadistic.",
		"traits" = list(TRAIT_HYBRID, TRAIT_WEAPONIZED, TRAIT_BRUTAL),
		"base_value" = 30,
		"drop_chance" = 80,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/clan/ranged/harpooner/greed)
	))
	greed_folder["mobs"] += list(list(
		"name" = "Greed Touched Gunner",
		"rank" = "Standard",
		"lore" = "Standard infantry corrupted by Greed. Their weapons have fused with their bodies.",
		"traits" = list(TRAIT_HYBRID, TRAIT_WEAPONIZED, TRAIT_FODDER),
		"base_value" = 25,
		"drop_chance" = 85,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/clan/ranged/gunner/greed)
	))
	greed_folder["mobs"] += list(list(
		"name" = "Greed Touched Sniper",
		"rank" = "Standard",
		"lore" = "Precision units aberrantly enhanced by the Greed. Their aim is supernaturally accurate.",
		"traits" = list(TRAIT_HYBRID, TRAIT_PRECISION, TRAIT_ABERRANT),
		"base_value" = 22,
		"drop_chance" = 80,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/clan/ranged/sniper/greed)
	))
	greed_folder["mobs"] += list(list(
		"name" = "Greed Touched Defender",
		"rank" = "Standard",
		"lore" = "Heavy units whose armor has ossified into organic-metal hybrid plating.",
		"traits" = list(TRAIT_HYBRID, TRAIT_ARMORED, TRAIT_OSSIFIED),
		"base_value" = 20,
		"drop_chance" = 90,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/clan/defender/greed)
	))
	greed_folder["mobs"] += list(list(
		"name" = "Greed Touched Rapid",
		"rank" = "Standard",
		"lore" = "Speed units whose corruption manifests as volatile, erratic behavior.",
		"traits" = list(TRAIT_HYBRID, TRAIT_VOLATILE, TRAIT_ERRATIC),
		"base_value" = 20,
		"drop_chance" = 90,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/clan/ranged/rapid/greed)
	))
	greed_folder["mobs"] += list(list(
		"name" = "Greed Touched Drone",
		"rank" = "Standard",
		"lore" = "Support units whose neural links have been warped by corruption. They now spread toxins instead of repairs.",
		"traits" = list(TRAIT_HYBRID, TRAIT_NEURAL, TRAIT_TOXIC),
		"base_value" = 15,
		"drop_chance" = 95,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/clan/drone/greed)
	))

	// Greed Clan Fodder units
	greed_folder["mobs"] += list(list(
		"name" = "Greed Touched Scout",
		"rank" = "Fodder",
		"lore" = "Light reconnaissance units whose corruption makes them erratic but quick. The Greed has made them expendable.",
		"traits" = list(TRAIT_HYBRID, TRAIT_LIGHTWEIGHT, TRAIT_FODDER),
		"base_value" = 10,
		"drop_chance" = 100,
		"icon" = get_mob_icon_base64(/mob/living/simple_animal/hostile/clan/scout/greed)
	))

	bestiary += list(greed_folder)

	return bestiary

/// Gets a base64 encoded icon for a mob type
/obj/machinery/rce_research/proc/get_mob_icon_base64(mob/living/simple_animal/mob_type)
	var/icon_file = initial(mob_type.icon)
	var/icon_state_name = initial(mob_type.icon_state)
	if(!icon_file || !icon_state_name)
		return null
	var/icon/I = icon(icon_file, icon_state_name)
	return icon2base64(I)

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

		if("processSpecificPart")
			if(processing_part)
				to_chat(usr, span_warning("Already processing a sample!"))
				return
			if(!selected_research)
				to_chat(usr, span_warning("Select a research project first!"))
				return
			var/part_ref = params["partRef"]
			if(!part_ref)
				return
			var/obj/item/rce_bodypart/target_part = locate(part_ref) in stored_parts
			if(!target_part)
				to_chat(usr, span_warning("That sample is no longer available!"))
				return
			process_specific_part(target_part)
			return TRUE

		if("ejectPart")
			var/part_ref = params["partRef"]
			if(!part_ref)
				return
			var/obj/item/rce_bodypart/target_part = locate(part_ref) in stored_parts
			if(!target_part)
				to_chat(usr, span_warning("That sample is no longer available!"))
				return
			stored_parts -= target_part
			target_part.forceMove(get_turf(src))
			to_chat(usr, span_notice("You eject [target_part] from [src]."))
			playsound(src, 'sound/machines/click.ogg', 50, TRUE)
			return TRUE

/obj/machinery/rce_research/proc/get_node_status(datum/rce_research_node/node)
	// Check if branch is enabled
	if(!is_branch_enabled(node.branch))
		return RESEARCH_LOCKED

	// Check prerequisites first
	for(var/prereq in node.prerequisites)
		if(!(prereq in completed_research))
			return RESEARCH_LOCKED

	// Check if research is completed and not repeatable
	var/effective_cost = get_effective_cost(node)
	var/current_progress = research_progress[node.id] || 0
	if(node.id in completed_research && current_progress >= effective_cost)
		return RESEARCH_COMPLETED

	return RESEARCH_AVAILABLE

/obj/machinery/rce_research/proc/is_branch_enabled(branch)
	switch(branch)
		if("hellfire")
			return hellfire_branch_enabled
		if("venom")
			return venom_branch_enabled
		if("storm")
			return storm_branch_enabled
	return TRUE

/// Returns the effective cost for a research node, accounting for starter kit cost doubling
/obj/machinery/rce_research/proc/get_effective_cost(datum/rce_research_node/node)
	if(!node.is_starter_kit)
		return node.cost
	var/completions = research_completions[node.id] || 0
	return node.cost * (2 ** completions) // Cost doubles each completion: base, 2x, 4x, 8x...

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
	var/effective_cost = get_effective_cost(selected_research)
	var/current_progress = research_progress[selected_research.id] || 0
	current_progress = min(current_progress + value, effective_cost)
	research_progress[selected_research.id] = current_progress
	to_chat(usr, span_notice("Added [value] points to [selected_research.name]. ([current_progress]/[effective_cost])"))

	// Check if research is complete
	if(current_progress >= effective_cost)
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

/obj/machinery/rce_research/proc/process_specific_part(obj/item/rce_bodypart/part)
	if(!part || processing_part || !selected_research)
		return

	processing_part = TRUE
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

	addtimer(CALLBACK(src, PROC_REF(finish_processing_single), part, value), process_time)

/obj/machinery/rce_research/proc/finish_processing_single(obj/item/rce_bodypart/part, value)
	if(!selected_research)
		qdel(part)
		processing_part = FALSE
		icon_state = "d_analyzer"
		return

	// Add points to selected research
	var/effective_cost = get_effective_cost(selected_research)
	var/current_progress = research_progress[selected_research.id] || 0
	current_progress = min(current_progress + value, effective_cost)
	research_progress[selected_research.id] = current_progress
	to_chat(usr, span_notice("Added [value] points to [selected_research.name]. ([current_progress]/[effective_cost])"))

	// Check if research is complete
	if(current_progress >= effective_cost)
		complete_research(selected_research)

	qdel(part)
	processing_part = FALSE
	icon_state = "d_analyzer"
	update_icon()

/obj/machinery/rce_research/proc/complete_research(datum/rce_research_node/node)
	selected_research = null

	// Create the unlocked item
	var/obj/item/result = new node.unlocked_path(get_turf(src))
	playsound(src, 'sound/machines/ping.ogg', 50, TRUE)
	visible_message(span_notice("[src] completes research of [node.name]!"))

	// Check if result is a portable factory
	var/is_factory = istype(result, /obj/item/portable_factory)

	// Mark as completed (for prerequisite tracking)
	if(!(node.id in completed_research))
		completed_research += node.id

	if(is_factory)
		// Factories are one-time research - keep progress at max
		var/effective_cost = get_effective_cost(node)
		research_progress[node.id] = effective_cost // Mark as fully complete
		say("Research complete: [node.name]. Factory module dispensed.")

		// Special handling for portable factories
		var/obj/item/portable_factory/PF = result
		PF.factory_name = node.name
		PF.factory_desc = node.desc
	else if(node.is_starter_kit)
		// Starter kits are repeatable but cost doubles each time
		var/completions = research_completions[node.id] || 0
		research_completions[node.id] = completions + 1
		research_progress[node.id] = 0 // Reset progress for next research
		var/next_cost = get_effective_cost(node)
		say("Production complete: [node.name]. Kit dispensed. Next production cost: [next_cost] points.")
	else
		// Non-factory items (weapons, armor, etc.) are repeatable
		// Reset progress to 0 to allow re-research
		research_progress[node.id] = 0
		say("Production complete: [node.name]. Item dispensed. Ready for next production cycle.")

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

	to_chat(user, span_notice("You begin deploying [src]..."))
	playsound(T, 'sound/items/ratchet.ogg', 50, TRUE)

	if(!do_after(user, 3 SECONDS, target = T))
		to_chat(user, span_warning("You stop deploying [src]."))
		return

	var/obj/structure/rcorp_factory/F = new factory_path(T)
	F.name = factory_name
	F.desc = factory_desc
	F.portable_origin = TRUE  // Mark as coming from portable factory
	F.source_factory_path = factory_path  // Store the factory type for reconstruction
	to_chat(user, span_notice("You deploy [src]."))
	playsound(T, 'sound/machines/click.ogg', 50, TRUE)
	qdel(src)
