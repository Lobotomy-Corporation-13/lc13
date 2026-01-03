/**
 * Resurgence Outpost - Research Manager
 *
 * Global singleton that manages research state for the outpost.
 * Research is shared across all players - when one player researches a node,
 * all players gain access to its unlocks.
 */

GLOBAL_DATUM_INIT(resurgence_research, /datum/resurgence_research_manager, new)

/datum/resurgence_research_manager
	/// List of researched node IDs: list("woodworking", "metallurgy", ...)
	var/list/researched_nodes = list()

	/// All node datums by ID: list("woodworking" = /datum/resurgence_research_node/...)
	var/list/all_nodes = list()

	/// Nodes organized by tier for UI display
	var/list/nodes_by_tier = list()

/datum/resurgence_research_manager/New()
	. = ..()
	init_all_nodes()

/// Initialize all research node datums
/datum/resurgence_research_manager/proc/init_all_nodes()
	all_nodes = list()
	nodes_by_tier = list()

	// Create instances of all node subtypes
	for(var/node_type in subtypesof(/datum/resurgence_research_node))
		var/datum/resurgence_research_node/node = new node_type()
		if(!node.id)
			qdel(node)
			continue
		all_nodes[node.id] = node

		// Organize by tier
		var/tier_key = "[node.tier]"
		if(!nodes_by_tier[tier_key])
			nodes_by_tier[tier_key] = list()
		nodes_by_tier[tier_key] += node

/// Check if a research node has been researched
/datum/resurgence_research_manager/proc/is_researched(node_id)
	if(!node_id)
		return TRUE  // No requirement = always available
	return (node_id in researched_nodes)

/// Get a node datum by its ID
/datum/resurgence_research_manager/proc/get_node_by_id(node_id)
	return all_nodes[node_id]

/// Get the display name of a node by its ID
/datum/resurgence_research_manager/proc/get_node_name(node_id)
	var/datum/resurgence_research_node/node = all_nodes[node_id]
	if(node)
		return node.name
	return node_id  // Fallback to ID if not found

/// Check if a node can be researched (all prerequisites met)
/datum/resurgence_research_manager/proc/can_research(node_id)
	var/datum/resurgence_research_node/node = all_nodes[node_id]
	if(!node)
		return FALSE

	// Already researched?
	if(node_id in researched_nodes)
		return FALSE

	// Check prerequisites
	for(var/prereq_id in node.prerequisites)
		if(!(prereq_id in researched_nodes))
			return FALSE

	return TRUE

/// Get the list of nodes that are currently available to research
/datum/resurgence_research_manager/proc/get_available_nodes()
	var/list/available = list()
	for(var/node_id in all_nodes)
		if(can_research(node_id))
			available += all_nodes[node_id]
	return available

/// Research a node - consumes faith from the user
/datum/resurgence_research_manager/proc/research_node(node_id, mob/user)
	if(!can_research(node_id))
		return FALSE

	var/datum/resurgence_research_node/node = all_nodes[node_id]
	if(!node)
		return FALSE

	// Check if user has enough faith
	if(!ishuman(user))
		return FALSE

	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		to_chat(user, span_warning("You need a resurgence core to research!"))
		return FALSE

	if(core.faith < node.faith_cost)
		to_chat(user, span_warning("You need [node.faith_cost] faith to research [node.name]. You have [round(core.faith)]."))
		return FALSE

	// Consume faith
	core.adjust_faith(-node.faith_cost)

	// Mark as researched
	researched_nodes += node_id

	// Announce to all players
	for(var/mob/living/carbon/human/player in GLOB.player_list)
		var/obj/item/organ/resurgence_core/player_core = player.getorganslot(ORGAN_SLOT_HEART)
		if(istype(player_core))
			to_chat(player, span_notice("<b>Research Complete:</b> [node.name] has been researched! New recipes and blueprints are now available."))

	return TRUE

/// Get all nodes for UI display
/datum/resurgence_research_manager/proc/get_all_nodes_data()
	var/list/data = list()
	for(var/node_id in all_nodes)
		var/datum/resurgence_research_node/node = all_nodes[node_id]
		data += list(list(
			"id" = node.id,
			"name" = node.name,
			"desc" = node.desc,
			"tier" = node.tier,
			"faith_cost" = node.faith_cost,
			"prerequisites" = node.prerequisites.Copy(),
			"unlocks_desc" = node.unlocks_desc,
			"x" = node.ui_x,
			"y" = node.ui_y
		))
	return data
