/**
 * Resurgence Outpost - Research Station
 *
 * Interactive structure for viewing and researching tech tree nodes.
 * Uses faith as currency for research.
 */

/obj/structure/resurgence_research_station
	name = "research station"
	desc = "A mystical altar for channeling faith into knowledge. Use this to unlock new recipes and blueprints."
	icon = 'icons/obj/structures.dmi'
	icon_state = "server"  // Placeholder, should be custom icon later
	density = TRUE
	anchored = TRUE

/obj/structure/resurgence_research_station/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	ui_interact(user)
	return TRUE

// ===== TGUI Interface =====

/obj/structure/resurgence_research_station/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ResurgenceResearch", "Resurgence Research")
		ui.open()

/obj/structure/resurgence_research_station/ui_data(mob/user)
	var/list/data = list()

	// Get player's current faith
	var/current_faith = 0
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			current_faith = round(core.faith)
	data["current_faith"] = current_faith

	// Get all nodes with their research status
	var/list/nodes = list()
	for(var/node_id in GLOB.resurgence_research.all_nodes)
		var/datum/resurgence_research_node/node = GLOB.resurgence_research.all_nodes[node_id]
		var/is_researched = GLOB.resurgence_research.is_researched(node_id)
		var/can_research = GLOB.resurgence_research.can_research(node_id)
		var/can_afford = (current_faith >= node.faith_cost)

		nodes += list(list(
			"id" = node.id,
			"name" = node.name,
			"desc" = node.desc,
			"tier" = node.tier,
			"faith_cost" = node.faith_cost,
			"prerequisites" = node.prerequisites.Copy(),
			"unlocks_desc" = node.unlocks_desc,
			"x" = node.ui_x,
			"y" = node.ui_y,
			"is_researched" = is_researched,
			"can_research" = can_research,
			"can_afford" = can_afford
		))
	data["nodes"] = nodes

	// List of researched node IDs for line coloring
	data["researched_nodes"] = GLOB.resurgence_research.researched_nodes.Copy()

	return data

/obj/structure/resurgence_research_station/ui_static_data(mob/user)
	var/list/data = list()
	// Node dimensions for UI layout
	data["node_width"] = 140
	data["node_height"] = 80
	return data

/obj/structure/resurgence_research_station/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("research")
			var/node_id = params["node"]
			if(!node_id)
				return FALSE

			if(GLOB.resurgence_research.research_node(node_id, usr))
				playsound(src, 'sound/effects/magic.ogg', 50, TRUE)
				return TRUE
			return FALSE

	return FALSE

/obj/structure/resurgence_research_station/examine(mob/user)
	. = ..()
	. += span_notice("Click to open the research tree.")

	var/researched_count = length(GLOB.resurgence_research.researched_nodes)
	var/total_count = length(GLOB.resurgence_research.all_nodes)
	. += span_notice("[researched_count]/[total_count] technologies researched.")

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			. += span_notice("Your faith: [round(core.faith)]")
