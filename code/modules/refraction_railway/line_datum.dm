/*
 * Line definition datum. One concrete subtype per playable line.
 * The base type has no `id`, so it is filtered out by the subsystem.
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
	/// Hex color string used to highlight this line on the subway-map UI.
	var/display_color = "#1b7ced"
	/// SVG node coordinates for the subway-map UI. Shape: list(list("x"=N, "y"=N), ...).
	var/list/node_coords = list()
	/*
	 * Per-sector preview entries. Index 1 = Sector 1, etc. Shape per entry:
	 *
	 * list(
	 *     "name"         = "Sector N: ...",
	 *     "description"  = "...",
	 *     "faction"      = "...",
	 *     "threat_range" = "TETH-HE",
	 *     "damage_hints" = "Mostly RED damage",
	 *     "is_boss"      = FALSE,
	 *     "nodes"        = list(
	 *         list("name" = "Node 1 - ...", "mobs" = list(/mob/path, ...)),
	 *         ...
	 *     ),
	 * )
	 *
	 * The number of node entries should equal the number of combat rooms in the
	 * sector, in room-id order.
	 */
	var/list/sector_briefings = list()
