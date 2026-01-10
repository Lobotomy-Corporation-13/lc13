// World Map Manager
// Handles world generation, state management, and pathfinding

/**
 * World Map Manager
 *
 * Singleton datum that manages the entire world map system.
 * Handles terrain generation, faction placement, and tile state.
 */
/datum/world_map_manager
	/// Map width in tiles
	var/map_width = WORLD_MAP_WIDTH
	/// Map height in tiles
	var/map_height = WORLD_MAP_HEIGHT
	/// 2D list of world tiles - access as tiles[x][y]
	var/list/list/datum/world_tile/tiles
	/// Reference to the outpost tile
	var/datum/world_tile/outpost_tile
	/// List of faction tile references
	var/list/datum/world_tile/faction_tiles
	/// Seed used for generation (for reproducibility)
	var/generation_seed
	/// Whether the map has been generated
	var/generated = FALSE
	/// Debug mode - disables fog of war
	var/debug_mode = FALSE

/datum/world_map_manager/New()
	. = ..()
	tiles = list()
	faction_tiles = list()

/datum/world_map_manager/Destroy()
	// Clean up all tiles
	for(var/x in 1 to map_width)
		if(tiles[x])
			for(var/y in 1 to map_height)
				if(tiles[x][y])
					qdel(tiles[x][y])
	tiles = null
	faction_tiles = null
	outpost_tile = null
	return ..()

/**
 * Generate the entire world map
 *
 * Arguments:
 * * seed - Optional seed for reproducible generation
 */
/datum/world_map_manager/proc/generate_world(seed = null)
	if(generated)
		return

	// Set seed
	if(seed)
		generation_seed = seed
	else
		generation_seed = rand(1, 999999)

	// Initialize tile grid
	init_tile_grid()

	// Place outpost at center
	place_outpost()

	// Generate terrain using noise
	generate_terrain()

	// Place faction locations
	place_factions()

	// Link adjacent tiles for pathfinding
	link_all_adjacent()

	// Discover initial area around outpost
	discover_radius(outpost_tile, INITIAL_DISCOVERY_RADIUS)

	// Reveal path to friendly Resurgence Clan faction
	reveal_initial_paths()

	// Load the expedition corridor z-level (async to avoid sleep in Initialize)
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(load_expedition_corridor))

	// Initialize caravan system
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(init_caravan_system))

	generated = TRUE

/**
 * Initialize the empty tile grid
 */
/datum/world_map_manager/proc/init_tile_grid()
	tiles = new /list(map_width)
	for(var/x in 1 to map_width)
		tiles[x] = new /list(map_height)
		for(var/y in 1 to map_height)
			tiles[x][y] = new /datum/world_tile(x, y)

/**
 * Place the player outpost at the center
 */
/datum/world_map_manager/proc/place_outpost()
	outpost_tile = tiles[WORLD_MAP_CENTER_X][WORLD_MAP_CENTER_Y]
	outpost_tile.set_terrain(TERRAIN_OUTPOST)
	outpost_tile.terrain_name = "Home Outpost"
	outpost_tile.terrain_desc = "Your home base. Safety and supplies await."
	outpost_tile.discovered = TRUE

/**
 * Generate terrain using a simple noise-based algorithm
 */
/datum/world_map_manager/proc/generate_terrain()
	for(var/x in 1 to map_width)
		for(var/y in 1 to map_height)
			var/datum/world_tile/tile = tiles[x][y]

			// Skip outpost tile
			if(tile == outpost_tile)
				continue

			// Generate noise values for this position
			var/elevation = get_noise_value(x, y, generation_seed, 0.15)
			var/moisture = get_noise_value(x, y, generation_seed + 1000, 0.2)

			// Determine terrain based on noise values
			var/terrain = select_terrain(elevation, moisture)

			// Small chance for ruins anywhere
			if(prob(5))
				terrain = TERRAIN_RUINS

			tile.set_terrain(terrain)

	// Create desert ring around the center/outpost
	create_desert_center()

	// Validate terrain adjacency rules (snow can't be next to desert)
	validate_terrain_adjacency()

/**
 * Create a desert region surrounding the center of the map (outpost area)
 * This ensures the outpost is always surrounded by desert terrain
 */
/datum/world_map_manager/proc/create_desert_center()
	var/center_x = WORLD_MAP_CENTER_X
	var/center_y = WORLD_MAP_CENTER_Y

	// Create desert in a ring around the outpost (distance 1-2 from center)
	for(var/x in 1 to map_width)
		for(var/y in 1 to map_height)
			var/datum/world_tile/tile = tiles[x][y]

			// Skip outpost tile itself
			if(tile == outpost_tile)
				continue

			// Calculate distance from center
			var/dist = abs(x - center_x) + abs(y - center_y)

			// Set tiles within distance 1-2 to desert
			if(dist >= 1 && dist <= 2)
				tile.set_terrain(TERRAIN_DESERT)

/**
 * Validate terrain adjacency rules
 * Snow terrain cannot be adjacent to desert terrain
 * Uses iterative approach to handle cascading changes
 */
/datum/world_map_manager/proc/validate_terrain_adjacency()
	var/changes_made = TRUE
	var/max_iterations = 10

	while(changes_made && max_iterations > 0)
		changes_made = FALSE
		max_iterations--

		for(var/x in 1 to map_width)
			for(var/y in 1 to map_height)
				var/datum/world_tile/tile = tiles[x][y]

				// Skip special tiles
				if(tile.terrain_type == TERRAIN_OUTPOST)
					continue

				// Check snow tiles for desert neighbors
				if(tile.terrain_type == TERRAIN_SNOW)
					if(has_adjacent_terrain(x, y, TERRAIN_DESERT))
						// Convert snow to plains or mountain
						tile.set_terrain(TERRAIN_PLAINS)
						changes_made = TRUE

/**
 * Check if a tile has adjacent terrain of a specific type
 */
/datum/world_map_manager/proc/has_adjacent_terrain(x, y, terrain_type)
	// Check all 4 cardinal directions
	if(x > 1 && tiles[x-1][y].terrain_type == terrain_type)
		return TRUE
	if(x < map_width && tiles[x+1][y].terrain_type == terrain_type)
		return TRUE
	if(y > 1 && tiles[x][y-1].terrain_type == terrain_type)
		return TRUE
	if(y < map_height && tiles[x][y+1].terrain_type == terrain_type)
		return TRUE
	return FALSE

/**
 * Count how many adjacent tiles have a specific terrain type
 */
/datum/world_map_manager/proc/count_adjacent_terrain(x, y, terrain_type)
	var/count = 0
	// Check all 4 cardinal directions
	if(x > 1 && tiles[x-1][y].terrain_type == terrain_type)
		count++
	if(x < map_width && tiles[x+1][y].terrain_type == terrain_type)
		count++
	if(y > 1 && tiles[x][y-1].terrain_type == terrain_type)
		count++
	if(y < map_height && tiles[x][y+1].terrain_type == terrain_type)
		count++
	return count

/**
 * Simple noise function approximation
 * Returns a value between 0 and 1
 */
/datum/world_map_manager/proc/get_noise_value(x, y, seed, scale)
	// Simple pseudo-random noise based on position and seed
	var/nx = x * scale
	var/ny = y * scale

	// Use sin/cos for wave-like patterns
	var/value = sin(nx * 127.1 + seed) * cos(ny * 311.7 + seed)
	value += sin(nx * 269.5 + ny * 183.3 + seed) * 0.5
	value += cos(nx * 419.2 - ny * 371.9 + seed) * 0.25

	// Normalize to 0-1 range
	value = (value + 1.75) / 3.5
	value = clamp(value, 0, 1)

	return value

/**
 * Select terrain type based on elevation and moisture
 */
/datum/world_map_manager/proc/select_terrain(elevation, moisture)
	// High elevation + high moisture = snow (cold mountain peaks)
	if(elevation > 0.5 && moisture > 0.65)
		return TERRAIN_SNOW

	// High elevation = mountains
	if(elevation > 0.7)
		return TERRAIN_MOUNTAIN

	// Low elevation + high moisture = forest
	if(elevation < 0.4 && moisture > 0.6)
		return TERRAIN_FOREST

	// Low moisture = desert
	if(moisture < 0.3)
		return TERRAIN_DESERT

	// High moisture = forest
	if(moisture > 0.55)
		return TERRAIN_FOREST

	// Default = plains
	return TERRAIN_PLAINS

/**
 * Place faction locations on the map
 */
/datum/world_map_manager/proc/place_factions()
	// List of faction IDs to place
	var/list/faction_ids = list(
		"resurgence_clan",
		"jiajia_ren",
		"santata_factory",
		"cloud_town",
		"insurgence_clan"
	)

	faction_tiles = list()

	// Ensure required terrain exists for all factions before placement
	for(var/faction_id in faction_ids)
		var/required_terrain = GLOB.faction_terrain_requirements[faction_id]
		if(required_terrain)
			ensure_faction_terrain(faction_id, required_terrain)

	for(var/faction_id in faction_ids)
		var/datum/world_tile/tile = find_faction_placement(faction_id)
		if(tile)
			tile.set_faction(faction_id)
			faction_tiles += tile

			// Update the faction datum with its world map coordinates
			var/datum/trading_faction/faction = GLOB.resurgence_trading?.get_faction(faction_id)
			if(faction)
				faction.world_x = tile.x_coord
				faction.world_y = tile.y_coord

/**
 * Ensure terrain of a specific type exists for faction placement
 * Creates terrain clusters so factions can have 4+ adjacent tiles of required terrain
 */
/datum/world_map_manager/proc/ensure_faction_terrain(faction_id, required_terrain)
	// First check if any valid tiles already exist (with 4+ adjacent terrain)
	var/valid_count = 0
	for(var/x in 1 to map_width)
		for(var/y in 1 to map_height)
			var/datum/world_tile/tile = tiles[x][y]
			if(tile.terrain_type != required_terrain)
				continue
			if(tile.terrain_type == TERRAIN_OUTPOST || tile.terrain_type == TERRAIN_FACTION)
				continue

			var/dist_outpost = tile.distance_to(outpost_tile)
			if(dist_outpost >= FACTION_MIN_DIST_FROM_OUTPOST && dist_outpost <= FACTION_MAX_DIST_FROM_OUTPOST)
				// Check if this tile has 4 adjacent tiles of same terrain
				if(count_adjacent_terrain(x, y, required_terrain) >= 4)
					valid_count++

	// If we have at least 1 valid tile with 4 adjacent, no need to create more
	if(valid_count >= 1)
		return

	// Find center points for creating terrain clusters
	var/list/cluster_centers = list()
	for(var/x in 2 to (map_width - 1))
		for(var/y in 2 to (map_height - 1))
			var/datum/world_tile/tile = tiles[x][y]

			// Skip special tiles
			if(tile.terrain_type == TERRAIN_OUTPOST || tile.terrain_type == TERRAIN_FACTION)
				continue

			// Check distance requirements
			var/dist_outpost = tile.distance_to(outpost_tile)
			if(dist_outpost < FACTION_MIN_DIST_FROM_OUTPOST || dist_outpost > FACTION_MAX_DIST_FROM_OUTPOST)
				continue

			// Check distance from existing factions
			var/too_close = FALSE
			for(var/datum/world_tile/ft in faction_tiles)
				if(tile.distance_to(ft) < FACTION_MIN_DIST_BETWEEN)
					too_close = TRUE
					break
			if(too_close)
				continue

			// For snow terrain, check adjacency rules (no desert within 2 tiles)
			if(required_terrain == TERRAIN_SNOW)
				var/near_desert = FALSE
				for(var/dx in -1 to 1)
					for(var/dy in -1 to 1)
						var/nx = x + dx
						var/ny = y + dy
						if(nx >= 1 && nx <= map_width && ny >= 1 && ny <= map_height)
							if(tiles[nx][ny].terrain_type == TERRAIN_DESERT)
								near_desert = TRUE
								break
					if(near_desert)
						break
				if(near_desert)
					continue

			// Prefer tiles that are plains or forest
			if(tile.terrain_type == TERRAIN_PLAINS || tile.terrain_type == TERRAIN_FOREST)
				cluster_centers += tile

	// Create a cluster of terrain around a random center point
	if(length(cluster_centers))
		var/datum/world_tile/center = pick(cluster_centers)
		create_terrain_cluster(center.x_coord, center.y_coord, required_terrain)

/**
 * Create a cluster of terrain around a center point
 * Creates a plus-shaped pattern (center + 4 cardinals) for faction placement
 */
/datum/world_map_manager/proc/create_terrain_cluster(center_x, center_y, terrain_type)
	// Convert the center and all 4 cardinal directions
	var/list/offsets = list(
		list(0, 0),   // Center
		list(-1, 0),  // West
		list(1, 0),   // East
		list(0, -1),  // South
		list(0, 1)    // North
	)

	for(var/list/offset in offsets)
		var/x = center_x + offset[1]
		var/y = center_y + offset[2]

		// Bounds check
		if(x < 1 || x > map_width || y < 1 || y > map_height)
			continue

		var/datum/world_tile/tile = tiles[x][y]

		// Don't overwrite special tiles
		if(tile.terrain_type == TERRAIN_OUTPOST || tile.terrain_type == TERRAIN_FACTION)
			continue

		tile.set_terrain(terrain_type)

/**
 * Find a valid placement for a faction
 * Distance between factions is ALWAYS enforced (never relaxed)
 * Terrain requirements are relaxed progressively if needed
 */
/datum/world_map_manager/proc/find_faction_placement(faction_id)
	var/list/candidates = list()

	// Get required terrain for this faction (if any)
	var/required_terrain = GLOB.faction_terrain_requirements[faction_id]

	// Find all valid candidate tiles (strict requirements)
	for(var/x in 1 to map_width)
		for(var/y in 1 to map_height)
			var/datum/world_tile/tile = tiles[x][y]

			// Skip if already a special tile
			if(tile.terrain_type == TERRAIN_OUTPOST || tile.terrain_type == TERRAIN_FACTION)
				continue

			// ALWAYS check distance from other factions - this is never relaxed
			var/too_close = FALSE
			for(var/datum/world_tile/ft in faction_tiles)
				if(tile.distance_to(ft) < FACTION_MIN_DIST_BETWEEN)
					too_close = TRUE
					break
			if(too_close)
				continue

			// Check distance from outpost
			var/dist_outpost = tile.distance_to(outpost_tile)
			if(dist_outpost < FACTION_MIN_DIST_FROM_OUTPOST)
				continue
			if(dist_outpost > FACTION_MAX_DIST_FROM_OUTPOST)
				continue

			// Check terrain requirement
			if(required_terrain && tile.terrain_type != required_terrain)
				continue

			// Check for 4+ adjacent tiles of required terrain
			if(required_terrain)
				var/adjacent_count = count_adjacent_terrain(x, y, required_terrain)
				if(adjacent_count < 4)
					continue

			candidates += tile

	// Pick a random valid candidate
	if(length(candidates))
		return pick(candidates)

	// Fallback 1: relax adjacency requirement to 3+ tiles (keep distance requirements!)
	candidates = list()
	for(var/x in 1 to map_width)
		for(var/y in 1 to map_height)
			var/datum/world_tile/tile = tiles[x][y]
			if(tile.terrain_type == TERRAIN_OUTPOST || tile.terrain_type == TERRAIN_FACTION)
				continue
			// ALWAYS check faction distance
			var/too_close = FALSE
			for(var/datum/world_tile/ft in faction_tiles)
				if(tile.distance_to(ft) < FACTION_MIN_DIST_BETWEEN)
					too_close = TRUE
					break
			if(too_close)
				continue
			var/dist_outpost = tile.distance_to(outpost_tile)
			if(dist_outpost < 2 || dist_outpost > 7)
				continue
			if(required_terrain && tile.terrain_type != required_terrain)
				continue
			// Relaxed: only need 3 adjacent tiles
			if(required_terrain && count_adjacent_terrain(x, y, required_terrain) < 3)
				continue
			candidates += tile
	if(length(candidates))
		return pick(candidates)

	// Fallback 2: relax to 2+ adjacent tiles (keep distance requirements!)
	candidates = list()
	for(var/x in 1 to map_width)
		for(var/y in 1 to map_height)
			var/datum/world_tile/tile = tiles[x][y]
			if(tile.terrain_type == TERRAIN_OUTPOST || tile.terrain_type == TERRAIN_FACTION)
				continue
			// ALWAYS check faction distance
			var/too_close = FALSE
			for(var/datum/world_tile/ft in faction_tiles)
				if(tile.distance_to(ft) < FACTION_MIN_DIST_BETWEEN)
					too_close = TRUE
					break
			if(too_close)
				continue
			var/dist_outpost = tile.distance_to(outpost_tile)
			if(dist_outpost < 2 || dist_outpost > 7)
				continue
			if(required_terrain && tile.terrain_type != required_terrain)
				continue
			// Further relaxed: only need 2 adjacent tiles
			if(required_terrain && count_adjacent_terrain(x, y, required_terrain) < 2)
				continue
			candidates += tile
	if(length(candidates))
		return pick(candidates)

	// Fallback 3: ignore adjacency requirement entirely (keep distance requirements!)
	candidates = list()
	for(var/x in 1 to map_width)
		for(var/y in 1 to map_height)
			var/datum/world_tile/tile = tiles[x][y]
			if(tile.terrain_type == TERRAIN_OUTPOST || tile.terrain_type == TERRAIN_FACTION)
				continue
			// ALWAYS check faction distance
			var/too_close = FALSE
			for(var/datum/world_tile/ft in faction_tiles)
				if(tile.distance_to(ft) < FACTION_MIN_DIST_BETWEEN)
					too_close = TRUE
					break
			if(too_close)
				continue
			var/dist_outpost = tile.distance_to(outpost_tile)
			if(dist_outpost < 2 || dist_outpost > 7)
				continue
			if(required_terrain && tile.terrain_type != required_terrain)
				continue
			candidates += tile
	if(length(candidates))
		return pick(candidates)

	// Fallback 4: ignore terrain requirement entirely (keep distance requirements!)
	candidates = list()
	for(var/x in 1 to map_width)
		for(var/y in 1 to map_height)
			var/datum/world_tile/tile = tiles[x][y]
			if(tile.terrain_type == TERRAIN_OUTPOST || tile.terrain_type == TERRAIN_FACTION)
				continue
			// ALWAYS check faction distance - never skip this
			var/too_close = FALSE
			for(var/datum/world_tile/ft in faction_tiles)
				if(tile.distance_to(ft) < FACTION_MIN_DIST_BETWEEN)
					too_close = TRUE
					break
			if(too_close)
				continue
			var/dist_outpost = tile.distance_to(outpost_tile)
			if(dist_outpost < 2 || dist_outpost > 7)
				continue
			candidates += tile
	if(length(candidates))
		return pick(candidates)

	return null

/**
 * Link all adjacent tiles for pathfinding
 */
/datum/world_map_manager/proc/link_all_adjacent()
	for(var/x in 1 to map_width)
		for(var/y in 1 to map_height)
			var/datum/world_tile/tile = tiles[x][y]

			// Link to neighbors (4-directional)
			if(x > 1)
				tile.link_adjacent(tiles[x-1][y])
			if(x < map_width)
				tile.link_adjacent(tiles[x+1][y])
			if(y > 1)
				tile.link_adjacent(tiles[x][y-1])
			if(y < map_height)
				tile.link_adjacent(tiles[x][y+1])

/**
 * Discover tiles within a radius of a center tile
 */
/datum/world_map_manager/proc/discover_radius(datum/world_tile/center, radius)
	if(!center)
		return

	for(var/x in 1 to map_width)
		for(var/y in 1 to map_height)
			var/datum/world_tile/tile = tiles[x][y]
			if(tile.distance_to(center) <= radius)
				tile.discover()

/**
 * Reveal initial paths to friendly factions
 * Called during world generation to give players a clear starting destination
 */
/datum/world_map_manager/proc/reveal_initial_paths()
	// Reveal path to the friendly Resurgence Clan faction
	var/datum/world_tile/clan_tile = get_faction_tile("resurgence_clan")
	if(!clan_tile)
		return

	// Calculate path from outpost to clan
	var/list/path = find_path(outpost_tile, clan_tile)
	if(!path || !length(path))
		// Fallback: just discover the clan tile directly
		clan_tile.discover()
		return

	// Discover all tiles along the path and their adjacent tiles
	for(var/datum/world_tile/tile in path)
		tile.discover()
		// Also discover adjacent tiles for better visibility
		for(var/datum/world_tile/adj in tile.adjacent_tiles)
			adj.discover()

/**
 * Get a tile at specific coordinates
 */
/datum/world_map_manager/proc/get_tile(x, y)
	if(x < 1 || x > map_width || y < 1 || y > map_height)
		return null
	return tiles[x][y]

/**
 * Get faction tile by faction ID
 */
/datum/world_map_manager/proc/get_faction_tile(faction_id)
	for(var/datum/world_tile/tile in faction_tiles)
		if(tile.faction_id == faction_id)
			return tile
	return null

/**
 * A* pathfinding between two tiles
 * Returns a list of tiles representing the path, or null if no path found
 */
/datum/world_map_manager/proc/find_path(datum/world_tile/start, datum/world_tile/goal)
	if(!start || !goal)
		return null

	var/list/open_set = list(start)
	var/list/came_from = list()
	var/list/g_score = list()
	var/list/f_score = list()

	g_score[start.get_key()] = 0
	f_score[start.get_key()] = start.distance_to(goal)

	while(length(open_set))
		// Find node with lowest f_score
		var/datum/world_tile/current = null
		var/lowest_f = INFINITY
		for(var/datum/world_tile/node in open_set)
			var/f = f_score[node.get_key()]
			if(f < lowest_f)
				lowest_f = f
				current = node

		if(current == goal)
			// Reconstruct path
			return reconstruct_path(came_from, current)

		open_set -= current

		// Check neighbors
		for(var/datum/world_tile/neighbor in current.adjacent_tiles)
			var/tentative_g = g_score[current.get_key()] + neighbor.travel_cost

			var/neighbor_key = neighbor.get_key()
			if(!(neighbor_key in g_score) || tentative_g < g_score[neighbor_key])
				came_from[neighbor_key] = current
				g_score[neighbor_key] = tentative_g
				f_score[neighbor_key] = tentative_g + neighbor.distance_to(goal)

				if(!(neighbor in open_set))
					open_set += neighbor

	return null  // No path found

/**
 * Reconstruct path from A* came_from map
 */
/datum/world_map_manager/proc/reconstruct_path(list/came_from, datum/world_tile/current)
	var/list/path = list(current)
	var/key = current.get_key()

	while(key in came_from)
		current = came_from[key]
		path.Insert(1, current)
		key = current.get_key()

	return path

/**
 * Calculate total travel cost for a path
 */
/datum/world_map_manager/proc/get_path_cost(list/path)
	var/total = 0
	for(var/datum/world_tile/tile in path)
		total += tile.travel_cost
	return total

/**
 * Get UI data for the entire map
 */
/datum/world_map_manager/proc/get_ui_data()
	var/list/data = list()
	data["map_width"] = map_width
	data["map_height"] = map_height
	data["outpost_x"] = outpost_tile?.x_coord
	data["outpost_y"] = outpost_tile?.y_coord
	data["generated"] = generated
	data["debug_mode"] = debug_mode

	// Build tiles array
	var/list/tiles_data = list()
	for(var/x in 1 to map_width)
		for(var/y in 1 to map_height)
			var/datum/world_tile/tile = tiles[x][y]
			// In debug mode, show all tiles as discovered
			tiles_data += list(tile.get_ui_data(debug_mode))

	data["tiles"] = tiles_data

	// Build faction locations
	var/list/factions_data = list()
	for(var/datum/world_tile/ft in faction_tiles)
		factions_data += list(list(
			"x" = ft.x_coord,
			"y" = ft.y_coord,
			"faction_id" = ft.faction_id,
			"name" = ft.terrain_name,
			"discovered" = ft.discovered
		))
	data["factions"] = factions_data

	// Build caravan data
	if(GLOB.caravan_manager)
		data["caravans"] = GLOB.caravan_manager.get_caravans_ui_data()
	else
		data["caravans"] = list()

	return data
