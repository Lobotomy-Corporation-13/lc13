// World Tile Datum
// Represents a single tile on the world map grid

/**
 * World Tile
 *
 * A data-only representation of a tile on the world map.
 * These are not physical turfs - they exist only as data for the map system.
 */
/datum/world_tile
	/// X coordinate on the world map (1 to WORLD_MAP_WIDTH)
	var/x_coord = 1
	/// Y coordinate on the world map (1 to WORLD_MAP_HEIGHT)
	var/y_coord = 1
	/// Terrain type (TERRAIN_* define)
	var/terrain_type = TERRAIN_PLAINS
	/// Movement cost multiplier for travel
	var/travel_cost = 1.0
	/// Event spawn chance multiplier
	var/event_chance_mod = 1.0
	/// Faction ID if this is a faction location (null otherwise)
	var/faction_id = null
	/// Whether this tile has been discovered by players
	var/discovered = FALSE
	/// Display color for the UI
	var/tile_color = "#4a7c3f"
	/// Display name for the terrain
	var/terrain_name = "Plains"
	/// Description of the terrain
	var/terrain_desc = "Open grasslands with few obstacles."
	/// List of adjacent tile references for pathfinding
	var/list/datum/world_tile/adjacent_tiles
	/// Caravan currently on this tile (if any)
	var/datum/faction_caravan/caravan

/**
 * Initialize a world tile at specific coordinates
 *
 * Arguments:
 * * x - X coordinate on the world map
 * * y - Y coordinate on the world map
 */
/datum/world_tile/New(x, y)
	. = ..()
	x_coord = x
	y_coord = y
	adjacent_tiles = list()

/datum/world_tile/Destroy()
	adjacent_tiles = null
	return ..()

/**
 * Set the terrain type and update all related properties
 *
 * Arguments:
 * * new_terrain - The terrain type to set (TERRAIN_* define)
 */
/datum/world_tile/proc/set_terrain(new_terrain)
	terrain_type = new_terrain

	// Update properties from global terrain lists
	if(GLOB.terrain_travel_costs[new_terrain])
		travel_cost = GLOB.terrain_travel_costs[new_terrain]

	if(GLOB.terrain_event_modifiers[new_terrain])
		event_chance_mod = GLOB.terrain_event_modifiers[new_terrain]

	if(GLOB.terrain_colors[new_terrain])
		tile_color = GLOB.terrain_colors[new_terrain]

	if(GLOB.terrain_names[new_terrain])
		terrain_name = GLOB.terrain_names[new_terrain]

	if(GLOB.terrain_descriptions[new_terrain])
		terrain_desc = GLOB.terrain_descriptions[new_terrain]

/**
 * Set this tile as a faction location
 *
 * Arguments:
 * * new_faction_id - The faction ID to assign to this tile
 */
/datum/world_tile/proc/set_faction(new_faction_id)
	faction_id = new_faction_id
	set_terrain(TERRAIN_FACTION)

	// Get faction name for display
	var/datum/trading_faction/faction = GLOB.resurgence_trading?.get_faction(new_faction_id)
	if(faction)
		terrain_name = faction.name
		terrain_desc = "The settlement of [faction.name]. Trade and diplomacy await."

/**
 * Mark this tile as discovered
 */
/datum/world_tile/proc/discover()
	if(discovered)
		return  // Already discovered
	discovered = TRUE

	// If this is a faction tile, mark the trading faction as discovered
	if(faction_id && GLOB.resurgence_trading)
		var/datum/trading_faction/trading_faction = GLOB.resurgence_trading.get_faction(faction_id)
		if(trading_faction && !trading_faction.discovered)
			trading_faction.discovered = TRUE
			log_game("Trading faction [faction_id] discovered on world map")

/**
 * Check if this tile is passable (can be traveled through)
 *
 * Returns TRUE if the tile can be traveled through
 */
/datum/world_tile/proc/is_passable()
	return TRUE

/**
 * Check if this tile is a destination (faction or special location)
 *
 * Returns TRUE if this is a destination tile
 */
/datum/world_tile/proc/is_destination()
	return terrain_type == TERRAIN_FACTION || terrain_type == TERRAIN_OUTPOST

/**
 * Get the estimated travel time to cross this tile (in seconds)
 *
 * Returns the base travel time modified by terrain
 */
/datum/world_tile/proc/get_travel_time()
	// Base travel time per tile is 30 seconds, modified by terrain cost
	var/base_time = 30
	return base_time * travel_cost

/**
 * Calculate Manhattan distance to another tile
 *
 * Arguments:
 * * other - The other world tile to measure distance to
 *
 * Returns the Manhattan distance (|x1-x2| + |y1-y2|)
 */
/datum/world_tile/proc/distance_to(datum/world_tile/other)
	if(!other)
		return INFINITY
	return abs(x_coord - other.x_coord) + abs(y_coord - other.y_coord)

/**
 * Get data for TGUI display
 *
 * Arguments:
 * * include_hidden - If TRUE, include data even for undiscovered tiles
 *
 * Returns an associative list of tile data for the UI
 */
/datum/world_tile/proc/get_ui_data(include_hidden = FALSE)
	var/list/data = list()
	data["x"] = x_coord
	data["y"] = y_coord
	data["discovered"] = discovered

	if(discovered || include_hidden)
		data["terrain_type"] = terrain_type
		data["terrain_name"] = terrain_name
		data["terrain_desc"] = terrain_desc
		data["tile_color"] = tile_color
		data["travel_cost"] = travel_cost
		data["event_chance"] = event_chance_mod
		data["faction_id"] = faction_id
		data["is_destination"] = is_destination()
		// Add caravan data if present
		if(caravan)
			data["has_caravan"] = TRUE
			data["caravan"] = caravan.get_ui_data()
		else
			data["has_caravan"] = FALSE
	else
		// Hidden tile - show minimal data
		data["terrain_type"] = "unknown"
		data["terrain_name"] = "Unexplored"
		data["terrain_desc"] = "This area has not been explored yet."
		data["tile_color"] = "#333333"
		data["travel_cost"] = 0
		data["event_chance"] = 0
		data["faction_id"] = null
		data["is_destination"] = FALSE

	return data

/**
 * Link this tile to an adjacent tile for pathfinding
 *
 * Arguments:
 * * other - The adjacent tile to link to
 */
/datum/world_tile/proc/link_adjacent(datum/world_tile/other)
	if(!other || other == src)
		return
	if(!(other in adjacent_tiles))
		adjacent_tiles += other
	if(!(src in other.adjacent_tiles))
		other.adjacent_tiles += src

/**
 * Get a unique key for this tile (used for pathfinding and lookups)
 *
 * Returns a string in format "x,y"
 */
/datum/world_tile/proc/get_key()
	return "[x_coord],[y_coord]"
