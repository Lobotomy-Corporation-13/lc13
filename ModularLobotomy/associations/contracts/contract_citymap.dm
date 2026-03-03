/// Shared city map data for the contract terminal and city map display.
/// Generated once per round by iterating city turfs.
/// Stores a 2D grid of hex color strings cropped to city bounds,
/// following the same pattern as facility_tactical_map.
/datum/contract_citymap
	/// 2D list of hex color strings: cached_map_grid[column][row]
	/// Column-major order, matching facility_tactical_map pattern.
	var/list/cached_map_grid
	/// Cropped grid width (number of columns)
	var/grid_width = 0
	/// Cropped grid height (number of rows)
	var/grid_height = 0
	/// World coordinate offset — X of the grid's left edge
	var/offset_x = 0
	/// World coordinate offset — Y of the grid's bottom edge
	var/offset_y = 0
	/// Whether generation has completed successfully
	var/generated = FALSE
	/// Legend data: list of list("color" = hex, "name" = area_name) for all area types on the map
	var/list/cached_legend

/// Generate the city map by iterating all turfs on the given z-level.
/// Only records turfs in /area/city where in_city == TRUE.
/// Produces a cropped 2D grid of hex color strings, color-coded by area type.
/datum/contract_citymap/proc/GenerateCityMap(zlevel)
	// First pass: find bounding box of city content
	var/min_x = world.maxx
	var/max_x = 1
	var/min_y = world.maxy
	var/max_y = 1
	for(var/thing in Z_TURFS(zlevel))
		var/turf/T = thing
		var/area/A = T.loc
		if(!istype(A, /area/city))
			CHECK_TICK
			continue
		var/area/city/CA = A
		if(!CA.in_city)
			CHECK_TICK
			continue
		min_x = min(min_x, T.x)
		max_x = max(max_x, T.x)
		min_y = min(min_y, T.y)
		max_y = max(max_y, T.y)
		CHECK_TICK
	// Validate that we found city tiles
	if(max_x < min_x || max_y < min_y)
		return
	// Add padding
	var/padding = 2
	min_x = max(1, min_x - padding)
	max_x = min(world.maxx, max_x + padding)
	min_y = max(1, min_y - padding)
	max_y = min(world.maxy, max_y + padding)
	offset_x = min_x
	offset_y = min_y
	grid_width = max_x - min_x + 1
	grid_height = max_y - min_y + 1
	// Build typecaches (same pattern as holomap)
	var/list/obstacle_tcache = typecacheof(list(
		/turf/closed/wall,
		/turf/closed/indestructible,
	))
	var/list/path_tcache = typecacheof(list(
		/turf/open/floor,
	)) - typecacheof(/turf/open/floor/plating/asteroid)
	// Track unique area types for the legend
	var/list/seen_areas = list()
	// Second pass: generate cropped grid
	cached_map_grid = list()
	for(var/gx in 1 to grid_width)
		var/list/column = list()
		for(var/gy in 1 to grid_height)
			var/tx = min_x + gx - 1
			var/ty = min_y + gy - 1
			var/turf/T = locate(tx, ty, zlevel)
			var/color = CITYMAP_COLOR_VOID
			if(T)
				var/area/A = T.loc
				if(istype(A, /area/city))
					var/area/city/CA = A
					if(CA.in_city)
						if(obstacle_tcache[T.type] || (T.contents.len && (locate(/obj/structure/grille) in T)))
							color = CITYMAP_COLOR_WALL
						else if(T.density)
							color = CITYMAP_COLOR_WALL
						else if(path_tcache[T.type] || (T.contents.len && (locate(/obj/structure/lattice/catwalk) in T)))
							color = CA.map_color
							if(!seen_areas["[CA.type]"])
								seen_areas["[CA.type]"] = list("color" = CA.map_color, "name" = CA.name)
						else
							color = CA.map_color
							if(!seen_areas["[CA.type]"])
								seen_areas["[CA.type]"] = list("color" = CA.map_color, "name" = CA.name)
			column += color
		cached_map_grid += list(column)
		CHECK_TICK
	// Build legend from seen area types
	cached_legend = list()
	for(var/key in seen_areas)
		cached_legend += list(seen_areas[key])
	generated = TRUE

/// Check if a world coordinate is a walkable floor tile (any color that isn't wall or void).
/datum/contract_citymap/proc/IsFloorTile(world_x, world_y)
	var/gx = world_x - offset_x + 1
	var/gy = world_y - offset_y + 1
	if(gx < 1 || gx > grid_width || gy < 1 || gy > grid_height)
		return FALSE
	var/color = cached_map_grid[gx][gy]
	return color != CITYMAP_COLOR_WALL && color != CITYMAP_COLOR_VOID

/// Extract a viewport-sized chunk from the cached grid.
/// view_gx and view_gy are 1-indexed grid coordinates of the chunk origin.
/datum/contract_citymap/proc/GetViewportChunk(view_gx, view_gy, size)
	var/list/chunk = list()
	for(var/dx in 0 to size - 1)
		var/list/column = list()
		var/gx = view_gx + dx
		for(var/dy in 0 to size - 1)
			var/gy = view_gy + dy
			if(gx >= 1 && gx <= grid_width && gy >= 1 && gy <= grid_height)
				column += cached_map_grid[gx][gy]
			else
				column += CITYMAP_COLOR_VOID
		chunk += list(column)
	return chunk

/// Return the full cached map grid for full-map rendering.
/datum/contract_citymap/proc/GetFullMap()
	return cached_map_grid

/// Check if two world coordinates are connected via walkable tiles.
/// Uses BFS on the cached grid. Returns TRUE if a path exists.
/datum/contract_citymap/proc/CanPathfind(from_wx, from_wy, to_wx, to_wy)
	if(!generated)
		return FALSE
	var/start_gx = from_wx - offset_x + 1
	var/start_gy = from_wy - offset_y + 1
	var/end_gx = to_wx - offset_x + 1
	var/end_gy = to_wy - offset_y + 1
	// Bounds check
	if(start_gx < 1 || start_gx > grid_width || start_gy < 1 || start_gy > grid_height)
		return FALSE
	if(end_gx < 1 || end_gx > grid_width || end_gy < 1 || end_gy > grid_height)
		return FALSE
	// Both endpoints must be walkable (not wall or void)
	if(!IsFloorTile(from_wx, from_wy))
		return FALSE
	if(!IsFloorTile(to_wx, to_wy))
		return FALSE
	// Same tile
	if(start_gx == end_gx && start_gy == end_gy)
		return TRUE
	// BFS with index-based queue (avoids Cut overhead)
	var/static/list/dx = list(1, -1, 0, 0)
	var/static/list/dy = list(0, 0, 1, -1)
	var/list/queue_x = list(start_gx)
	var/list/queue_y = list(start_gy)
	var/list/visited = list()
	visited["[start_gx],[start_gy]"] = TRUE
	var/idx = 1
	while(idx <= length(queue_x) && idx <= 10000)
		var/cx = queue_x[idx]
		var/cy = queue_y[idx]
		idx++
		for(var/d in 1 to 4)
			var/nx = cx + dx[d]
			var/ny = cy + dy[d]
			if(nx < 1 || nx > grid_width || ny < 1 || ny > grid_height)
				continue
			var/key = "[nx],[ny]"
			if(visited[key])
				continue
			var/ncolor = cached_map_grid[nx][ny]
			if(ncolor == CITYMAP_COLOR_WALL || ncolor == CITYMAP_COLOR_VOID)
				continue
			if(nx == end_gx && ny == end_gy)
				return TRUE
			visited[key] = TRUE
			queue_x += nx
			queue_y += ny
		CHECK_TICK
	return FALSE
