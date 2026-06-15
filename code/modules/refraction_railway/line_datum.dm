/*
 * Line definition datum. One concrete subtype per playable line; the base
 * type has no `id` so the subsystem filters it out. Pure-data: subtype and
 * set the vars below.
 */
/datum/refraction_line
	/// Unique string key; empty disables the line at registry time.
	var/id = ""
	/// Display name in the selector and leaderboard.
	var/name = ""
	/// One-line flavor for the selector.
	var/description = ""
	/// Path to the .dmm template under _maps/refraction_railway/.
	var/map_path = ""
	/// Uniform attribute level applied to every member during the run.
	var/attribute_set_value = 80
	/// Max players per lobby for this line.
	var/max_lobby_size = 4
	/// Number of sectors; must match the dmm.
	var/section_count = 1
	/// Default subway-map line color (hex).
	var/display_color = "#1b7ced"

	/// SVG viewBox for the subway map.
	var/list/map_viewbox = list("w" = 600, "h" = 360)

	/// Subway-map nodes (1-based assoc lists: x, y, label, kind, radius).
	var/list/nodes = list()

	/// Subway-map edges (assoc lists: from, to, shape, color, thickness, dashed).
	var/list/edges = list()

	/// "Recommended Level & Tier" panel text, one entry per line.
	var/list/recommended_tier_lines = list()

	/// Pixel offset of the recommended-tier panel from the start node.
	var/list/recommended_tier_offset = list("x" = 40, "y" = -60)

	/// Per-sector preview entries (1-based): name, description, node_ids.
	/// node_ids is an ordered list resolving into combat_nodes.
	var/list/sector_briefings = list()

	/// node_id => /datum/refraction_node; populated by AddNode().
	var/list/combat_nodes = list()

	// ---------- Per-line wave-scaling tweaks ----------
	// Each line authors its own defaults; the SS-level toggles still gate
	// globally (effective flag = SS.flag && line.flag), so admins can kill
	// scaling at the subsystem level if they need to.

	/// Per-mob-type stock multiplier (scales the type reserves by party size).
	var/scale_stock = TRUE
	/// Concurrent-alive cap multiplier.
	var/scale_concurrent = TRUE
	/// Per-cycle spawn batch = num_players; OFF means 1 per cycle.
	var/scale_spawn_batch = TRUE
	/// Non-boss per-mob HP/damage scaling.
	var/scale_wave_stats = TRUE
	/// Boss per-mob HP scaling (HP only, never damage).
	var/scale_boss_stats = TRUE
	/// Compensation medipens for smaller parties each sector.
	var/give_compensation_pens = TRUE
	/// Forbid re-using EGO weapons/armor across sectors of the same run.
	var/unique_loadout_per_sector = FALSE
	/// When TRUE, the Hub still shows this line but the Create Lobby action
	/// is disabled (server-side guard + greyed UI). Players can still browse
	/// the subway map. Set per-line by hand for WIP content.
	var/locked = FALSE
	/// Target completion time in seconds for the Starlight time bonus. Runs
	/// faster than this get positive bonus per second saved; slower runs get
	/// negative bonus per second over. Default 9 minutes; override per line.
	var/expected_time_seconds = 540
	/// Flat Starlight award paid for clearing this line. Matches the
	/// global STARLIGHT_BASE_AWARD default (run_datum.dm) but can be
	/// overridden per line for a higher or lower base reward.
	var/base_clear_award = 100

/// Override in subtypes to declare mob passives (mob_path => list of entries).
/datum/refraction_line/proc/GetMobPassives()
	return list()

/// Override in subtypes to declare mob attacks (mob_path => list of entries).
/datum/refraction_line/proc/GetMobAttacks()
	return list()

/// Override in subtypes to gate whole mobs behind a runtime event. Even an
/// encountered mob keeps its silhouette payload until the event is
/// unlocked for the viewing ckey (via SSrefraction_railway.MarkEventUnlocked).
/// Shape: list(mob_path => "event_id_string").
/datum/refraction_line/proc/GetMobSilhouetteGates()
	return list()

/// Registers a combat node; called from the subtype's New().
/datum/refraction_line/proc/AddNode(node_id, lm_id, n_name, n_desc, list/stock, c_max = 4, boss = FALSE, list/extra_preview, locked = FALSE, theme_music = null, theme_music_name = "")
	var/datum/refraction_node/N = new
	N.id = node_id
	N.landmark_id = lm_id
	N.name = n_name
	N.description = n_desc
	N.mob_stock = stock || list()
	// Boss nodes default concurrent_max to 1 unless c_max was overridden.
	N.concurrent_max = (boss && c_max == 4) ? 1 : c_max
	N.is_boss = boss
	N.extra_preview_mobs = extra_preview || list()
	N.locked = locked
	N.theme_music = theme_music
	N.theme_music_name = theme_music_name
	combat_nodes[node_id] = N
