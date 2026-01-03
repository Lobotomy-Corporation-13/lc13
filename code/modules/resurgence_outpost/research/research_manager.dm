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

	/// Current research progress by node ID: list("woodworking" = 15, ...)
	var/list/research_progress = list()

	/// Currently active research node ID (global, shared research)
	var/current_research_node = null

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

/// Get the current progress for a research node
/datum/resurgence_research_manager/proc/get_progress(node_id)
	if(!node_id)
		return 0
	return research_progress[node_id] || 0

/// Start researching a node (sets it as the current research)
/datum/resurgence_research_manager/proc/start_research(node_id, mob/user)
	if(!can_research(node_id))
		to_chat(user, span_warning("Cannot research this node!"))
		return FALSE

	var/datum/resurgence_research_node/node = all_nodes[node_id]
	if(!node)
		return FALSE

	current_research_node = node_id
	if(!research_progress[node_id])
		research_progress[node_id] = 0

	to_chat(user, span_notice("Started researching [node.name]."))
	return TRUE

/// Cancel current research (progress is saved)
/datum/resurgence_research_manager/proc/cancel_research(mob/user)
	if(!current_research_node)
		return FALSE

	var/datum/resurgence_research_node/node = all_nodes[current_research_node]
	if(node)
		to_chat(user, span_notice("Stopped researching [node.name]. Progress saved."))

	current_research_node = null
	return TRUE

/// Add work to current research - returns TRUE if research completed
/datum/resurgence_research_manager/proc/add_research_work(amount, mob/user)
	if(!current_research_node)
		return FALSE

	var/datum/resurgence_research_node/node = all_nodes[current_research_node]
	if(!node)
		return FALSE

	// Add work
	if(!research_progress[current_research_node])
		research_progress[current_research_node] = 0
	research_progress[current_research_node] += amount

	// Check if complete
	if(research_progress[current_research_node] >= node.total_work)
		complete_research(current_research_node)
		return TRUE

	return FALSE

/// Complete a research node (called when work reaches total)
/datum/resurgence_research_manager/proc/complete_research(node_id)
	var/datum/resurgence_research_node/node = all_nodes[node_id]
	if(!node)
		return FALSE

	// Mark as researched
	researched_nodes += node_id

	// Clear progress
	research_progress[node_id] = 0
	if(current_research_node == node_id)
		current_research_node = null

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
			"total_work" = node.total_work,
			"prerequisites" = node.prerequisites.Copy(),
			"unlocks_desc" = node.unlocks_desc,
			"x" = node.ui_x,
			"y" = node.ui_y
		))
	return data
