// ============================================================
// Path Node — Skill Tree (Traces) Node Datum
// ============================================================
// Individual nodes in a path's skill tree. Each node can grant
// stat bonuses (percentage-based), level up abilities, or
// unlock bonus passive effects. Unlocked by spending ahn.
// ============================================================

/datum/path_node
	/// Unique node ID within the path (e.g. "atk1", "bonus_a2")
	var/id = ""
	/// Display name
	var/name = "Node"
	/// Description shown in UI
	var/desc = ""
	/// Icon state for UI display
	var/icon_state = ""

	/// Node IDs that must be unlocked first
	var/list/prerequisites = list()
	/// Ahn cost to unlock this node
	var/ahn_cost = 200
	/// Node type: PATH_NODE_STAT, PATH_NODE_ABILITY, or PATH_NODE_PASSIVE
	var/node_type = PATH_NODE_STAT

	// --- Gating Requirements ---
	/// Minimum ascension phase to unlock (0 = no gate)
	var/required_ascension = 0
	/// Minimum path level to unlock (0 = no gate)
	var/required_level = 0

	// --- Stat Node Vars ---
	/// Assoc list of stat bonuses, e.g. list("ATK" = 4)
	var/list/stat_bonuses = list()
	/// If TRUE, stat_bonuses are percentage-based (e.g. +4% ATK)
	var/stat_percent = FALSE

	// --- Ability Node Vars ---
	/// Which ability this upgrades: PATH_ABILITY_BASIC, etc.
	var/ability_target = ""
	/// How many levels to add to the ability
	var/level_increase = 1

	// --- UI Positioning ---
	/// X position in skill tree grid
	var/tree_x = 0
	/// Y position in skill tree grid
	var/tree_y = 0
	/// Node IDs this connects to visually (for drawing lines)
	var/list/connections = list()

/// Convenience constructor
/datum/path_node/New(new_id, new_name, new_desc)
	if(new_id)
		id = new_id
	if(new_name)
		name = new_name
	if(new_desc)
		desc = new_desc

/// Returns an assoc list of all node data for the TGUI
/datum/path_node/proc/GetNodeData(list/unlocked_nodes)
	var/list/data = list()
	data["id"] = id
	data["name"] = name
	data["desc"] = desc
	data["icon_state"] = icon_state
	data["ahn_cost"] = ahn_cost
	data["node_type"] = node_type
	data["tree_x"] = tree_x
	data["tree_y"] = tree_y
	data["connections"] = connections
	data["prerequisites"] = prerequisites
	data["required_ascension"] = required_ascension
	data["required_level"] = required_level
	data["unlocked"] = (id in unlocked_nodes)

	// Type-specific data
	if(node_type == PATH_NODE_STAT)
		data["stat_bonuses"] = stat_bonuses
		data["stat_percent"] = stat_percent
	else if(node_type == PATH_NODE_ABILITY)
		data["ability_target"] = ability_target
		data["level_increase"] = level_increase
		data["repeatable"] = TRUE

	return data

/// Checks if this node can be unlocked given current state
/datum/path_node/proc/CanUnlock(list/unlocked_nodes, ascension_phase = 0, path_level = 0)
	// Already unlocked (ability nodes can be re-purchased)
	if(node_type != PATH_NODE_ABILITY && (id in unlocked_nodes))
		return FALSE
	// Check prerequisites
	for(var/prereq_id in prerequisites)
		if(!(prereq_id in unlocked_nodes))
			return FALSE
	// Check ascension gate
	if(required_ascension > 0 && ascension_phase < required_ascension)
		return FALSE
	// Check level gate
	if(required_level > 0 && path_level < required_level)
		return FALSE
	return TRUE
