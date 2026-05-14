/*
 * Per-node data for refraction railway combat encounters.
 *
 * Authored on the line datum (see line_datum.dm). The line's New() override
 * calls AddNode() once per node; the resulting /datum/refraction_node lives
 * in line.combat_nodes[node_id] and is referenced by
 * sector_briefings.node_ids.
 *
 * Single source of truth for both the briefing UI (the player-facing card
 * showing "Node N: Front Courtyard, contents: 5x slasher + 3x stabber, ...")
 * and the spawning system. The wave controller copies mob_stock at activation.
 *
 * Spawn locations: any /obj/effect/landmark/refraction/spawner whose
 * `id` matches this node's `landmark_id` becomes a valid spawn point.
 * Authors can drop one or many spawner landmarks per node.
 */
/datum/refraction_node
	/// String identifier, unique within a line. Used in
	/// sector_briefings.node_ids and as the room_id key the run datum hands
	/// to ActivateRoom / WipeRoomReserves.
	var/id = ""
	/// Matches /obj/effect/landmark/refraction/spawner.id in the dmm.
	/// Multiple landmarks can share an id; the wave controller uses every
	/// matching landmark on the run's z as a spawn point.
	var/landmark_id = ""
	/// Display name shown on the briefing card.
	var/name = ""
	/// Optional flavor text shown under the name on the briefing card.
	var/description = ""
	/// Authored stock by mob type. assoc: mob_path => 1-player baseline count.
	/// Live stock is multiplied by refraction_stock_mult(num_players) at
	/// activation; boss nodes (is_boss = TRUE) skip the multiplier so they
	/// always spawn the authored count regardless of lobby size.
	var/list/mob_stock = list()
	/// Max alive at once across all spawn landmarks for this node.
	/// On boss nodes (is_boss = TRUE), defaults to 1 unless the author sets
	/// it explicitly via AddNode().
	var/concurrent_max = 4
	/// If TRUE: skip player-count scaling on stock; default concurrent_max
	/// = 1 unless the author overrides. Used for boss encounters.
	var/is_boss = FALSE
