/*
 * Line definition datum. One concrete subtype per playable line.
 * The base type has no `id`, so it is filtered out by the subsystem.
 *
 * Authoring a new line should be a pure-data change: subtype this, set the
 * vars below (especially `nodes` + `edges`), and the subway-map UI in
 * RefractionRailway.js will render the topology you describe with no JS edits.
 */
/datum/refraction_line
	/// String key, must be unique. Empty string disables the line at registry time.
	var/id = ""
	/// Display name shown in the line selector and on the leaderboard.
	var/name = ""
	/// One-line flavor for the selector.
	var/description = ""
	/// Path to the .dmm template under _maps/refraction_railway/.
	var/map_path = ""
	/// Uniform attribute level applied to every member during the run.
	var/attribute_set_value = 80
	/// Maximum number of players allowed in a single lobby for this line.
	var/max_lobby_size = 4
	/// Number of sectors in this line. Authored to match the dmm.
	var/section_count = 1
	/// Hex color string used as the default line color on the subway map.
	/// Edges that don't override `color` and node hover tints inherit this.
	var/display_color = "#1b7ced"

	/// SVG viewBox for the subway map. Edit the dimensions to give your line
	/// more vertical/horizontal room without rescaling individual nodes.
	var/list/map_viewbox = list("w" = 600, "h" = 360)

	/// Subway-map nodes. Indexed list (1-based). Each entry is an assoc list:
	///   "x", "y"    — SVG coords inside `map_viewbox`.
	///   "label"     — optional override for hover tooltip (defaults to kind).
	///   "kind"      — "start" / "combat" / "checkpoint" / "boss" / "finish".
	///                 Drives the icon color in the renderer.
	///   "radius"    — optional pixel radius (default 14).
	var/list/nodes = list()

	/// Subway-map edges. Each entry is an assoc list:
	///   "from", "to" — 1-based indices into `nodes`.
	///   "shape"      — "line" (straight), "elbow_h" (right-angle, horizontal-
	///                  first), "elbow_v" (vertical-first), or "curve"
	///                  (quadratic Bezier through the midpoint).
	///   "color"      — optional hex; falls back to `display_color`.
	///   "thickness"  — optional pixel width (default 4).
	///   "dashed"     — optional bool; renders as a dashed stroke when TRUE.
	var/list/edges = list()

	/// "Recommended Level & Tier" text panel rendered near the start node.
	/// One list entry per line of text.
	var/list/recommended_tier_lines = list()

	/// Pixel offset from the start node where the recommended-tier panel
	/// renders. Tweak per-line so the panel doesn't overlap your edge layout.
	var/list/recommended_tier_offset = list("x" = 40, "y" = -60)

	/*
	 * Per-sector preview entries. Index 1 = Sector 1, etc. Shape per entry:
	 *
	 * list(
	 *     "name"         = "Sector N: ...",
	 *     "description"  = "...",
	 *     "node_ids"     = list("node_1", "node_2", ...),
	 * )
	 *
	 * `node_ids` is an ordered list of node ids; each id resolves to a
	 * /datum/refraction_node in this line's `combat_nodes` registry. The
	 * order defines the in-room progression (room 1 → room 2 → ...).
	 *
	 * There is no sector-level `faction`, `damage_hints`, or `is_boss`
	 * field. Per-mob tips registered in `SSrefraction_railway.mob_tips`
	 * cover faction context and incoming-damage advice; the per-node
	 * `is_boss` flag (set via AddNode) is rendered on the node's own
	 * card. Duplicating any of that at the sector level just creates a
	 * maintenance burden.
	 */
	var/list/sector_briefings = list()

	/// node_id => /datum/refraction_node. Populated by AddNode() in the
	/// concrete subtype's New() override. Single source of truth for both
	/// the briefing UI and the spawning system. Distinct from `nodes` above,
	/// which holds subway-map-UI coordinates.
	var/list/combat_nodes = list()

/*
 * Per-line passive / attack contributions.
 *
 * Override these in the concrete line subtype to declare the mob passives
 * and special attacks that line authors. Each returns a flat assoc list:
 *   mob_path => list(entry, entry, ...)
 *
 * Convention: each line subdirectory holds one or more companion files
 * (`lines/<line_id>/passives.dm`, `lines/<line_id>/attacks.dm`) that
 * carry the override. See AUTHORING.md Step 5b/5c for the entry shape
 * and style rules.
 *
 * The subsystem's InitializeMobPassives / InitializeMobAttacks walks
 * every registered line and merges these into SSrefraction_railway's
 * mob_passives / mob_attacks tables. First registration wins on
 * collision; the loser's contribution is dropped with a stack_trace
 * naming both lines.
 */
/datum/refraction_line/proc/GetMobPassives()
	return list()

/datum/refraction_line/proc/GetMobAttacks()
	return list()

/// Helper called from the concrete line subtype's New() to register a node.
/// `mob_stock` is an assoc list `path => 1-player baseline count`. For boss
/// nodes pass `boss = TRUE` and (optionally) override `c_max` (defaults to 1).
/datum/refraction_line/proc/AddNode(node_id, lm_id, n_name, n_desc, list/stock, c_max = 4, boss = FALSE)
	var/datum/refraction_node/N = new
	N.id = node_id
	N.landmark_id = lm_id
	N.name = n_name
	N.description = n_desc
	N.mob_stock = stock || list()
	// Boss nodes default to concurrent_max = 1 unless the author passed an
	// explicit c_max different from the default.
	N.concurrent_max = (boss && c_max == 4) ? 1 : c_max
	N.is_boss = boss
	combat_nodes[node_id] = N
