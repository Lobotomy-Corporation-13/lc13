/*
 * Per-node combat encounter data. Authored on the line datum via AddNode();
 * single source of truth for the briefing UI and the wave spawner.
 */
/datum/refraction_node
	/// String id, unique within a line; also the run datum's room_id key.
	var/id = ""
	/// Matches /obj/effect/landmark/refraction/spawner.id; shared = many spawns.
	var/landmark_id = ""
	/// Display name on the briefing card.
	var/name = ""
	/// Optional flavor text under the name.
	var/description = ""
	/// mob_path => 1-player baseline count; scaled at activation unless boss.
	var/list/mob_stock = list()
	/// Max alive at once for this node (1 on boss nodes unless overridden).
	var/concurrent_max = 4
	/// Boss: skip stock scaling, default concurrent_max 1.
	var/is_boss = FALSE
	/// Extra mob paths shown on the card but not wave-spawned (boss summons).
	var/list/extra_preview_mobs = list()
	/// When TRUE, the briefing UI hides this node's desc + mob cards behind a
	/// "Restricted" placeholder and the SVG map renders it un-clickable.
	/// Server-side, the wave system still accepts the node — locking is purely
	/// a UI-level gate so players can't preview unfinished encounters.
	var/locked = FALSE
