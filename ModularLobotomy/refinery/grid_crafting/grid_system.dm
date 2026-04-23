/**
 * Grid Crafting System - Grid System
 *
 * Manages the coordinate grid, weapon placement, and movement logic.
 * Weapons are placed based on expected Ahn cost to reach them.
 */

// ===== Grid Craft Item Datum =====

/// Represents a craftable weapon on the grid
/datum/grid_craft_item
	/// Display name of the item
	var/name = "Unknown Weapon"
	/// Description shown in UI
	var/desc = "A craftable weapon."
	/// X coordinate on the grid
	var/coord_x = 0
	/// Y coordinate on the grid
	var/coord_y = 0
	/// Radius within which the item can be crafted
	var/craft_radius = 5
	/// Tier of the item (0-4)
	var/tier = 0
	/// The result type to create
	var/result_type = null
	/// Unique ID for this item
	var/item_id = ""

/datum/grid_craft_item/New(item_name, item_desc, x, y, radius, item_tier, result)
	name = item_name
	desc = item_desc
	coord_x = x
	coord_y = y
	craft_radius = radius
	tier = item_tier
	result_type = result
	item_id = "[name]_[coord_x]_[coord_y]"

/// Get the distance from a point to this item
/datum/grid_craft_item/proc/DistanceFrom(x, y)
	return sqrt((coord_x - x) ** 2 + (coord_y - y) ** 2)

/// Check if a point is within crafting range
/datum/grid_craft_item/proc/IsInRange(x, y)
	return DistanceFrom(x, y) <= craft_radius

// ===== Grid Zone Datum =====

/// Represents a zone area on the grid made of discrete cells
/datum/grid_zone
	/// Zone type (GRID_ZONE_TAILWIND, etc.)
	var/zone_type = GRID_ZONE_TAILWIND
	/// Unique identifier
	var/zone_id = ""
	/// Assoc list of cell keys ("x,y" -> TRUE) for fast lookup
	var/list/cells = list()
	/// Blocked movement types (EXCLUSION only)
	var/list/blocked_movements = list()

/// Check if a world coordinate is inside this zone
/datum/grid_zone/proc/IsInZone(world_x, world_y)
	var/cell_x = round(world_x / GRID_ZONE_CELL_SIZE) * GRID_ZONE_CELL_SIZE
	var/cell_y = round(world_y / GRID_ZONE_CELL_SIZE) * GRID_ZONE_CELL_SIZE
	var/key = "[cell_x],[cell_y]"
	return cells[key]

/// Get display name for this zone type
/datum/grid_zone/proc/GetZoneName()
	switch(zone_type)
		if(GRID_ZONE_TAILWIND)
			return "Tailwind Zone"
		if(GRID_ZONE_DRAG)
			return "Drag Zone"
		if(GRID_ZONE_RESONANCE)
			return "Resonance Zone"
		if(GRID_ZONE_EXCLUSION)
			return "Exclusion Zone"
	return "Unknown Zone"

/// Get readable names of blocked movement types (EXCLUSION only)
/datum/grid_zone/proc/GetBlockedMovementNames()
	var/list/names = list()
	for(var/movement_type in blocked_movements)
		names += GetMovementTypeName(movement_type)
	return names

/// Get cell world coordinates as list of [x, y] pairs for TGUI
/datum/grid_zone/proc/GetCellCoords()
	var/list/coords = list()
	for(var/key in cells)
		var/list/parts = splittext(key, ",")
		if(length(parts) == 2)
			coords += list(list(text2num(parts[1]), text2num(parts[2])))
	return coords

/// Generate an irregular blob of cells via random flood-fill
/// occupied_cells is an assoc list of all cells already used by other zones
/datum/grid_zone/proc/GenerateBlob(center_x, center_y, cell_count, list/occupied_cells)
	var/snap_x = round(center_x / GRID_ZONE_CELL_SIZE) * GRID_ZONE_CELL_SIZE
	var/snap_y = round(center_y / GRID_ZONE_CELL_SIZE) * GRID_ZONE_CELL_SIZE

	var/seed_key = "[snap_x],[snap_y]"
	if(occupied_cells[seed_key])
		return FALSE
	cells[seed_key] = TRUE
	occupied_cells[seed_key] = TRUE

	var/list/frontier = list()
	var/list/offsets = list(
		list(GRID_ZONE_CELL_SIZE, 0),
		list(-GRID_ZONE_CELL_SIZE, 0),
		list(0, GRID_ZONE_CELL_SIZE),
		list(0, -GRID_ZONE_CELL_SIZE)
	)

	var/nx
	var/ny
	var/nkey
	for(var/list/offset in offsets)
		nx = snap_x + offset[1]
		ny = snap_y + offset[2]
		nkey = "[nx],[ny]"
		if(!cells[nkey] && !occupied_cells[nkey])
			frontier[nkey] = TRUE

	var/placed = 1
	while(placed < cell_count && length(frontier))
		var/idx = rand(1, length(frontier))
		var/picked_key = frontier[idx]
		frontier -= picked_key

		if(occupied_cells[picked_key])
			continue

		cells[picked_key] = TRUE
		occupied_cells[picked_key] = TRUE
		placed++

		var/list/parts = splittext(picked_key, ",")
		var/px = text2num(parts[1])
		var/py = text2num(parts[2])

		for(var/list/dir_offset in offsets)
			nx = px + dir_offset[1]
			ny = py + dir_offset[2]
			nkey = "[nx],[ny]"
			if(!cells[nkey] && !frontier[nkey] && !occupied_cells[nkey])
				frontier[nkey] = TRUE

	return TRUE

// ===== Grid Craft Manager Datum =====

/// Manages the grid state for a crafting station
/datum/grid_craft_manager
	/// Current focus point X coordinate
	var/focus_x = 0
	/// Current focus point Y coordinate
	var/focus_y = 0
	/// List of all craftable weapon items on the grid
	var/list/datum/grid_craft_item/items = list()
	/// List of all craftable armor items on the grid
	var/list/datum/grid_craft_item/armor_items = list()
	/// Whether the player is viewing the armor side of the grid
	var/viewing_armor = FALSE
	/// Number of cores used this session
	var/cores_used = 0
	/// Reference to the owning crafting station
	var/obj/structure/grid_crafting_station/owner = null
	/// Random seed for item placement
	var/placement_seed = 0

	/// Shuffle system
	var/shuffle_counter = 0
	var/shuffle_threshold = 10

	/// Last movement for Mirror type
	var/last_move_x = 0
	var/last_move_y = 0
	var/has_previous_move = FALSE
	/// Last movement type used (for Mirror to mimic)
	var/last_movement_type = CORE_MOVEMENT_SHUFFLE
	/// Last direction inputs for Mirror
	var/last_dir_x = 0
	var/last_dir_y = 0
	/// Last teleport target for Mirror
	var/last_target_x = 0
	var/last_target_y = 0
	/// Grid zones (shared across weapon/armor, persist across shuffles)
	var/list/datum/grid_zone/zones = list()
	/// Whether last UseCore failure was due to exclusion zone
	var/last_blocked_by_exclusion = FALSE

/datum/grid_craft_manager/New(obj/structure/grid_crafting_station/station)
	owner = station
	placement_seed = rand(1, 999999)
	shuffle_threshold = rand(SHUFFLE_THRESHOLD_MIN, SHUFFLE_THRESHOLD_MAX)
	GenerateItemPositions()
	GenerateZones()

/// Reset the focus point to origin
/datum/grid_craft_manager/proc/ResetFocus()
	focus_x = 0
	focus_y = 0
	cores_used = 0

/// Get the active item list based on current viewing mode
/datum/grid_craft_manager/proc/GetActiveItems()
	if(viewing_armor)
		return armor_items
	return items

/// Toggle between weapon and armor sides of the grid
/datum/grid_craft_manager/proc/FlipGrid()
	viewing_armor = !viewing_armor

// ===== Zone System =====

/// Generate all grid zones (called once, persists across shuffles)
/datum/grid_craft_manager/proc/GenerateZones()
	zones = list()
	var/zone_count = rand(GRID_ZONE_COUNT_MIN, GRID_ZONE_COUNT_MAX)
	var/list/zone_types = list(GRID_ZONE_TAILWIND, GRID_ZONE_DRAG, GRID_ZONE_RESONANCE, GRID_ZONE_EXCLUSION)
	var/list/all_movements = list(CORE_MOVEMENT_CHARGE, CORE_MOVEMENT_ATTRACT, CORE_MOVEMENT_SHUFFLE, CORE_MOVEMENT_EXPAND, CORE_MOVEMENT_DRIFT, CORE_MOVEMENT_TELEPORT, CORE_MOVEMENT_MIRROR)
	var/list/occupied_cells = list()

	for(var/i in 1 to zone_count)
		var/datum/grid_zone/zone = new()
		zone.zone_type = pick(zone_types)
		zone.zone_id = "zone_[i]"

		var/angle = rand(0, 359)
		var/dist = rand(GRID_ZONE_DIST_MIN, GRID_ZONE_DIST_MAX)
		var/center_x = round(cos(angle) * dist, 1)
		var/center_y = round(sin(angle) * dist, 1)

		var/cell_count = rand(GRID_ZONE_CELLS_MIN, GRID_ZONE_CELLS_MAX)
		if(!zone.GenerateBlob(center_x, center_y, cell_count, occupied_cells))
			qdel(zone)
			continue

		if(zone.zone_type == GRID_ZONE_EXCLUSION)
			var/list/shuffled = all_movements.Copy()
			var/block_count = rand(GRID_ZONE_EXCLUSION_BLOCK_MIN, GRID_ZONE_EXCLUSION_BLOCK_MAX)
			for(var/j in 1 to block_count)
				if(!length(shuffled))
					break
				var/picked = pick(shuffled)
				zone.blocked_movements += picked
				shuffled -= picked

		zones += zone

/// Get all zones at a given position
/datum/grid_craft_manager/proc/GetZonesAtPosition(x, y)
	var/list/result = list()
	for(var/datum/grid_zone/zone in zones)
		if(zone.IsInZone(x, y))
			result += zone
	return result

/// Clear all diminishing return stacks on the station
/datum/grid_craft_manager/proc/ClearDiminishingReturns()
	if(!owner)
		return
	owner.sin_overuse_counts = list()

/// Shuffle all item positions (both weapons and armor)
/datum/grid_craft_manager/proc/ShuffleWeapons()
	placement_seed = rand(1, 999999)
	shuffle_counter = 0
	shuffle_threshold = rand(SHUFFLE_THRESHOLD_MIN, SHUFFLE_THRESHOLD_MAX)
	GenerateItemPositions()

	if(owner)
		owner.visible_message(span_boldwarning("The grid crafting station hums loudly as item positions shift!"))
		playsound(owner, 'sound/machines/engine_alert2.ogg', 50, TRUE)

/// Add shuffle points for a crafted weapon tier
/datum/grid_craft_manager/proc/AddShufflePoints(tier)
	var/points
	switch(tier)
		if(0)
			points = SHUFFLE_POINTS_TIER_0
		if(1)
			points = SHUFFLE_POINTS_TIER_1
		if(2)
			points = SHUFFLE_POINTS_TIER_2
		if(3)
			points = SHUFFLE_POINTS_TIER_3
		if(4)
			// Immediate shuffle
			ShuffleWeapons()
			return

	shuffle_counter += points
	if(shuffle_counter >= shuffle_threshold)
		ShuffleWeapons()

// ===== Movement Execution =====

/// Use a navigation core to move the focus point
/// Returns TRUE on success, FALSE on failure
/datum/grid_craft_manager/proc/UseCore(obj/item/navigation_core/core, mob/user, direction_x, direction_y, target_x, target_y)
	if(!core || !user)
		return FALSE

	var/distance = core.GetFinalDistance(owner)
	var/result_x = focus_x
	var/result_y = focus_y

	// Zone effects (departure-based: apply from current position)
	last_blocked_by_exclusion = FALSE
	var/zone_distance_mult = 1.0
	var/list/active_zones = GetZonesAtPosition(focus_x, focus_y)
	for(var/datum/grid_zone/zone in active_zones)
		switch(zone.zone_type)
			if(GRID_ZONE_EXCLUSION)
				if(core.nav_movement_type in zone.blocked_movements)
					last_blocked_by_exclusion = TRUE
					return FALSE
			if(GRID_ZONE_TAILWIND)
				zone_distance_mult *= GRID_ZONE_TAILWIND_MULT
			if(GRID_ZONE_DRAG)
				zone_distance_mult *= GRID_ZONE_DRAG_MULT
			if(GRID_ZONE_RESONANCE)
				ClearDiminishingReturns()

	distance = round(distance * zone_distance_mult, 0.1)

	switch(core.nav_movement_type)
		if(CORE_MOVEMENT_CHARGE)
			var/list/result = ExecuteCharge(direction_x, direction_y, distance)
			if(!result)
				return FALSE
			result_x = result[1]
			result_y = result[2]

		if(CORE_MOVEMENT_ATTRACT)
			var/list/result = ExecuteAttract(distance)
			if(!result)
				return FALSE
			result_x = result[1]
			result_y = result[2]

		if(CORE_MOVEMENT_SHUFFLE)
			var/list/result = ExecuteShuffle(distance)
			result_x = result[1]
			result_y = result[2]

		if(CORE_MOVEMENT_EXPAND)
			var/list/result = ExecuteExpand(direction_x, direction_y, distance)
			if(!result)
				return FALSE
			result_x = result[1]
			result_y = result[2]

		if(CORE_MOVEMENT_DRIFT)
			var/list/result = ExecuteDrift(direction_x, direction_y, distance)
			if(!result)
				return FALSE
			result_x = result[1]
			result_y = result[2]

		if(CORE_MOVEMENT_TELEPORT)
			var/max_teleport_range = core.GetMaxPossibleDistance()
			var/diminishing = GetDiminishingModifier(owner, core.sin_type)
			max_teleport_range = round(max_teleport_range * diminishing * zone_distance_mult, 0.1)
			var/list/result = ExecuteTeleport(target_x, target_y, max_teleport_range)
			if(!result)
				return FALSE
			result_x = result[1]
			result_y = result[2]

		if(CORE_MOVEMENT_MIRROR)
			var/list/result = ExecuteMirror(distance)
			if(!result)
				return FALSE
			result_x = result[1]
			result_y = result[2]

	// Record movement data for Mirror (don't record Mirror itself)
	if(core.nav_movement_type != CORE_MOVEMENT_MIRROR)
		last_movement_type = core.nav_movement_type
		last_dir_x = direction_x
		last_dir_y = direction_y
		last_target_x = target_x
		last_target_y = target_y
	last_move_x = result_x - focus_x
	last_move_y = result_y - focus_y
	has_previous_move = TRUE

	// Apply movement
	focus_x = result_x
	focus_y = result_y
	cores_used++

	// Apply diminishing returns after successful use
	ApplyDiminishingReturns(owner, core.sin_type)

	return TRUE

/// Charge: Straight line in cardinal direction
/datum/grid_craft_manager/proc/ExecuteCharge(dir_x, dir_y, distance)
	// Must be pure cardinal (only one axis)
	if(dir_x != 0 && dir_y != 0)
		return null
	if(dir_x == 0 && dir_y == 0)
		return null

	var/norm_x = dir_x != 0 ? (dir_x > 0 ? 1 : -1) : 0
	var/norm_y = dir_y != 0 ? (dir_y > 0 ? 1 : -1) : 0

	return list(
		round(focus_x + norm_x * distance, 1),
		round(focus_y + norm_y * distance, 1)
	)

/// Attract: Move toward nearest item on active side
/datum/grid_craft_manager/proc/ExecuteAttract(distance)
	var/datum/grid_craft_item/nearest = null
	var/nearest_dist = INFINITY

	for(var/datum/grid_craft_item/item in GetActiveItems())
		var/dist = item.DistanceFrom(focus_x, focus_y)
		if(dist < nearest_dist && dist > 0)
			nearest_dist = dist
			nearest = item

	if(!nearest)
		// No weapons found, act like shuffle
		return ExecuteShuffle(distance)

	// Calculate direction to nearest weapon
	var/dx = nearest.coord_x - focus_x
	var/dy = nearest.coord_y - focus_y
	var/total_dist = sqrt(dx * dx + dy * dy)

	if(total_dist <= 0)
		return list(focus_x, focus_y)

	// Normalize and apply distance
	var/move_dist = min(distance, total_dist)  // Don't overshoot
	var/norm_x = dx / total_dist
	var/norm_y = dy / total_dist

	return list(
		round(focus_x + norm_x * move_dist, 1),
		round(focus_y + norm_y * move_dist, 1)
	)

/// Shuffle: Random direction and distance
/datum/grid_craft_manager/proc/ExecuteShuffle(distance)
	var/angle = rand(0, 359)
	// Shuffle has reduced distance (50-100% of rolled)
	var/actual_dist = distance * (0.5 + rand() * 0.5)

	var/dx = cos(angle) * actual_dist
	var/dy = sin(angle) * actual_dist

	return list(
		round(focus_x + dx, 1),
		round(focus_y + dy, 1)
	)

/// Expand: Any of 8 directions
/datum/grid_craft_manager/proc/ExecuteExpand(dir_x, dir_y, distance)
	if(dir_x == 0 && dir_y == 0)
		return null

	var/norm_x = dir_x != 0 ? (dir_x > 0 ? 1 : -1) : 0
	var/norm_y = dir_y != 0 ? (dir_y > 0 ? 1 : -1) : 0

	// For diagonal, split distance
	if(norm_x != 0 && norm_y != 0)
		var/diag_dist = distance / sqrt(2)
		return list(
			round(focus_x + norm_x * diag_dist, 1),
			round(focus_y + norm_y * diag_dist, 1)
		)

	return list(
		round(focus_x + norm_x * distance, 1),
		round(focus_y + norm_y * distance, 1)
	)

/// Drift: Cardinal direction with perpendicular shift
/datum/grid_craft_manager/proc/ExecuteDrift(dir_x, dir_y, distance)
	// Must be cardinal only (like Charge)
	if(dir_x != 0 && dir_y != 0)
		return null
	if(dir_x == 0 && dir_y == 0)
		return null

	var/norm_x = dir_x != 0 ? (dir_x > 0 ? 1 : -1) : 0
	var/norm_y = dir_y != 0 ? (dir_y > 0 ? 1 : -1) : 0

	// Calculate perpendicular shift (50-100% of distance, always shifts)
	var/shift_amount = distance * (rand(50, 100) / 100)
	var/shift_dir = prob(50) ? 1 : -1

	// Apply main movement
	var/final_x = focus_x + norm_x * distance
	var/final_y = focus_y + norm_y * distance

	// Apply perpendicular shift
	if(norm_x != 0)  // Moving horizontally, shift vertically
		final_y += shift_dir * shift_amount
	else  // Moving vertically, shift horizontally
		final_x += shift_dir * shift_amount

	return list(round(final_x, 1), round(final_y, 1))

/// Teleport: Direct jump to target coordinates
/datum/grid_craft_manager/proc/ExecuteTeleport(target_x, target_y, max_distance)
	var/dx = target_x - focus_x
	var/dy = target_y - focus_y
	var/dist = sqrt(dx * dx + dy * dy)

	if(dist > max_distance)
		return null  // Out of range

	return list(round(target_x, 1), round(target_y, 1))

/// Mirror: Mimics the previous movement type using its own distance
/datum/grid_craft_manager/proc/ExecuteMirror(distance)
	if(!has_previous_move)
		// No previous move, act like shuffle
		return ExecuteShuffle(distance)

	// Mimic the last movement type with Mirror's own distance
	switch(last_movement_type)
		if(CORE_MOVEMENT_CHARGE)
			return ExecuteCharge(last_dir_x, last_dir_y, distance)

		if(CORE_MOVEMENT_ATTRACT)
			return ExecuteAttract(distance)

		if(CORE_MOVEMENT_SHUFFLE)
			return ExecuteShuffle(distance)

		if(CORE_MOVEMENT_EXPAND)
			return ExecuteExpand(last_dir_x, last_dir_y, distance)

		if(CORE_MOVEMENT_DRIFT)
			return ExecuteDrift(last_dir_x, last_dir_y, distance)

		if(CORE_MOVEMENT_TELEPORT)
			// For teleport, use the previous target location
			return ExecuteTeleport(last_target_x, last_target_y, distance)

	// Fallback to shuffle if unknown type
	return ExecuteShuffle(distance)

// ===== Item Queries =====

/// Get all items within crafting range of the focus point (on active side)
/datum/grid_craft_manager/proc/GetCraftableItems()
	var/list/craftable = list()
	for(var/datum/grid_craft_item/item in GetActiveItems())
		if(item.IsInRange(focus_x, focus_y))
			craftable += item
	return craftable

/// Get items sorted by distance from focus point (on active side)
/datum/grid_craft_manager/proc/GetNearbyItems(max_count = 10)
	var/list/nearby = list()

	for(var/datum/grid_craft_item/item in GetActiveItems())
		var/dist = item.DistanceFrom(focus_x, focus_y)
		nearby += list(list("item" = item, "distance" = dist))

	// Sort by distance
	nearby = sortTim(nearby, GLOBAL_PROC_REF(cmp_grid_item_distance))

	// Return only the closest ones
	var/list/result = list()
	for(var/i in 1 to min(max_count, length(nearby)))
		result += nearby[i]["item"]

	return result

// ===== Weapon Placement =====

/// Place items from a cache list into a target list using tier-based distances
/datum/grid_craft_manager/proc/PlaceItemsFromCache(list/cache_data, list/target_list)
	// Tier placement config: based on expected Ahn investment
	var/list/tier_config = list(
		list("min_dist" = WEAPON_DIST_TIER_0_MIN, "max_dist" = WEAPON_DIST_TIER_0_MAX,
		     "min_rad" = WEAPON_RADIUS_TIER_0_MIN, "max_rad" = WEAPON_RADIUS_TIER_0_MAX),
		list("min_dist" = WEAPON_DIST_TIER_1_MIN, "max_dist" = WEAPON_DIST_TIER_1_MAX,
		     "min_rad" = WEAPON_RADIUS_TIER_1_MIN, "max_rad" = WEAPON_RADIUS_TIER_1_MAX),
		list("min_dist" = WEAPON_DIST_TIER_2_MIN, "max_dist" = WEAPON_DIST_TIER_2_MAX,
		     "min_rad" = WEAPON_RADIUS_TIER_2_MIN, "max_rad" = WEAPON_RADIUS_TIER_2_MAX),
		list("min_dist" = WEAPON_DIST_TIER_3_MIN, "max_dist" = WEAPON_DIST_TIER_3_MAX,
		     "min_rad" = WEAPON_RADIUS_TIER_3_MIN, "max_rad" = WEAPON_RADIUS_TIER_3_MAX),
		list("min_dist" = WEAPON_DIST_TIER_4_MIN, "max_dist" = WEAPON_DIST_TIER_4_MAX,
		     "min_rad" = WEAPON_RADIUS_TIER_4_MIN, "max_rad" = WEAPON_RADIUS_TIER_4_MAX)
	)

	var/list/tier_counts = list(0, 0, 0, 0, 0)
	for(var/list/item_data in cache_data)
		var/tier = item_data["tier"]
		if(tier >= 0 && tier <= 4)
			tier_counts[tier + 1]++

	for(var/list/item_data in cache_data)
		var/tier = item_data["tier"]
		if(tier < 0 || tier > 4)
			continue

		var/list/config = tier_config[tier + 1]
		var/count = tier_counts[tier + 1]

		var/angle_degrees = rand(0, 359)
		var/dist = rand(config["min_dist"], config["max_dist"])

		var/x = round(cos(angle_degrees) * dist, 1)
		var/y = round(sin(angle_degrees) * dist, 1)

		var/count_modifier = 1.0
		if(count <= 5)
			count_modifier = 1.5
		else if(count <= 15)
			count_modifier = 1.2
		else if(count <= 30)
			count_modifier = 1.0
		else if(count <= 50)
			count_modifier = 0.8
		else
			count_modifier = 0.6

		var/adjusted_min = round(config["min_rad"] * count_modifier, 1)
		var/adjusted_max = round(config["max_rad"] * count_modifier, 1)
		var/radius = rand(max(adjusted_min, 2), max(adjusted_max, 3))

		var/datum/grid_craft_item/item = new(
			item_data["name"],
			item_data["desc"],
			x,
			y,
			radius,
			tier,
			item_data["type"]
		)
		target_list += item

/// Generate item positions for both weapons and armor
/datum/grid_craft_manager/proc/GenerateItemPositions()
	items = list()
	armor_items = list()

	PlaceItemsFromCache(GetCityWeapons(), items)
	PlaceItemsFromCache(GetCityArmors(), armor_items)

// ===== Weapon Discovery =====

/// Cached list of all city weapons with their data (populated once at first access)
GLOBAL_LIST_EMPTY(grid_craft_weapon_cache)

/// Whether the weapon cache has been initialized
GLOBAL_VAR_INIT(grid_craft_cache_initialized, FALSE)

/// Initialize the global weapon cache (call once, typically at world start or first use)
/proc/InitializeGridCraftWeaponCache()
	if(GLOB.grid_craft_cache_initialized)
		return
	GLOB.grid_craft_cache_initialized = TRUE
	GLOB.grid_craft_weapon_cache = GenerateWeaponCache()

/// Generate the weapon cache list from EGO datums with City origin (expensive, only call once)
/proc/GenerateWeaponCache()
	var/list/weapons = list()

	for(var/datumpath in subtypesof(/datum/ego_datum))
		var/datum/ego_datum/ED = new datumpath
		if(!ED.item_path || ED.origin != "City" || ED.item_category != "Weapon" || ED.testrange_blacklisted)
			qdel(ED)
			continue

		if(IsWeaponTypeBlacklisted(ED.item_path))
			qdel(ED)
			continue

		var/obj/item/ego_weapon/temp_weapon = new ED.item_path(null)
		qdel(ED)

		// Check name-based blacklist
		if(temp_weapon.name in GLOB.grid_craft_blacklist_names)
			qdel(temp_weapon)
			continue

		// Calculate highest attribute requirement
		var/max_req = 0
		if(LAZYLEN(temp_weapon.attribute_requirements))
			for(var/attr in temp_weapon.attribute_requirements)
				var/req_value = temp_weapon.attribute_requirements[attr]
				if(req_value > max_req)
					max_req = req_value

		// Calculate tier based on highest requirement
		var/tier = 0
		if(max_req >= 120)
			tier = 4
		else if(max_req >= 100)
			tier = 3
		else if(max_req >= 80)
			tier = 2
		else if(max_req >= 60)
			tier = 1
		else
			tier = 0

		var/weapon_type = temp_weapon.type
		var/desc = "A city weapon."
		if(temp_weapon.damtype)
			desc = "[temp_weapon.damtype] damage"
		if(temp_weapon.force)
			desc += ", [temp_weapon.force] force"

		weapons += list(list(
			"name" = temp_weapon.name,
			"desc" = desc,
			"type" = weapon_type,
			"tier" = tier
		))

		qdel(temp_weapon)

	return weapons

/// Check if a weapon type is blacklisted (global version for cache generation)
/proc/IsWeaponTypeBlacklisted(weapon_type)
	if(weapon_type in GLOB.grid_craft_blacklist_exact)
		return TRUE

	for(var/blacklisted_type in GLOB.grid_craft_blacklist_subtypes)
		if(ispath(weapon_type, blacklisted_type))
			return TRUE

	return FALSE

/// Weapon types blacklisted from grid crafting
GLOBAL_LIST_INIT(grid_craft_blacklist_exact, list(
	/obj/item/ego_weapon/ranged/city,
	/obj/item/ego_weapon/city/rosespanner,
	/obj/item/ego_weapon/city/liu,
	/obj/item/ego_weapon/city/carnival_spear/weak,
	/obj/item/ego_weapon/city/carnival_spear/arm,
	/obj/item/ego_weapon/ranged/city/fullstop,
	/obj/item/ego_weapon/city/echo,
	/obj/item/ego_weapon/city/echo/twins,
	/obj/item/ego_weapon/city/thumbmelee,
	/obj/item/ego_weapon/city/zweihander/noreq,
	/obj/item/ego_weapon/city/zweihander/vet/noreq,
	/obj/item/ego_weapon/city/cane,
	/obj/item/ego_weapon/city/thumb_east/podao/tiantui
))

GLOBAL_LIST_INIT(grid_craft_blacklist_subtypes, list(
	/obj/item/ego_weapon/city/rabbit,
	/obj/item/ego_weapon/city/rats/truepipe,
	/obj/item/ego_weapon/city/mantis,
	/obj/item/ego_weapon/city/handchainsword,
	/obj/item/ego_weapon/ranged/city/lcorp,
	/obj/item/ego_weapon/city/lcorp,
	/obj/item/ego_weapon/city/index,
	/obj/item/ego_weapon/city/pt
))

/// Weapon names blacklisted from grid crafting (checked after instantiation)
GLOBAL_LIST_INIT(grid_craft_blacklist_names, list(
	"Tibia",
	"Fascia",
	"caduceus",
	"caduceus - hatchet",
	"caduceus - stiletto",
	"caduceus - bastard sword",
	"caduceus - rapier",
	"caduceus - hammer",
	"caduceus - greatsword",
	"caduceus - lance",
	"caduceus - whip",
	"caduceus - scythe",
	"caduceus - fpoon",
	"index apprentice chains",
	"Effloresced E.G.O :: Procuration",
))

// IsWeaponBlacklisted moved to global /proc/IsWeaponTypeBlacklisted()

/// Get city weapons from the global cache (fast, no instantiation)
/datum/grid_craft_manager/proc/GetCityWeapons()
	if(!GLOB.grid_craft_cache_initialized)
		InitializeGridCraftWeaponCache()
	return GLOB.grid_craft_weapon_cache.Copy()

// ===== Armor Cache =====

/// Cached list of all city armors with their data (populated once at first access)
GLOBAL_LIST_EMPTY(grid_craft_armor_cache)

/// Whether the armor cache has been initialized
GLOBAL_VAR_INIT(grid_craft_armor_cache_initialized, FALSE)

/// Initialize the global armor cache (call once, typically at world start or first use)
/proc/InitializeGridCraftArmorCache()
	if(GLOB.grid_craft_armor_cache_initialized)
		return
	GLOB.grid_craft_armor_cache_initialized = TRUE
	GLOB.grid_craft_armor_cache = GenerateArmorCache()

/// Generate the armor cache list from EGO datums with City origin
/proc/GenerateArmorCache()
	var/list/armors = list()

	for(var/datumpath in subtypesof(/datum/ego_datum))
		var/datum/ego_datum/ED = new datumpath
		if(!ED.item_path || ED.origin != "City" || ED.item_category != "Armor" || ED.testrange_blacklisted)
			qdel(ED)
			continue

		var/obj/item/clothing/suit/armor/ego_gear/temp_armor = new ED.item_path(null)
		qdel(ED)

		var/max_req = 0
		if(LAZYLEN(temp_armor.attribute_requirements))
			for(var/attr in temp_armor.attribute_requirements)
				var/req_value = temp_armor.attribute_requirements[attr]
				if(req_value > max_req)
					max_req = req_value

		var/tier = 0
		if(max_req >= 120)
			tier = 4
		else if(max_req >= 100)
			tier = 3
		else if(max_req >= 80)
			tier = 2
		else if(max_req >= 60)
			tier = 1
		else
			tier = 0

		var/armor_type = temp_armor.type
		var/desc = "A city armor."

		armors += list(list(
			"name" = temp_armor.name,
			"desc" = desc,
			"type" = armor_type,
			"tier" = tier
		))

		qdel(temp_armor)

	return armors

/// Get city armors from the global cache (fast, no instantiation)
/datum/grid_craft_manager/proc/GetCityArmors()
	if(!GLOB.grid_craft_armor_cache_initialized)
		InitializeGridCraftArmorCache()
	return GLOB.grid_craft_armor_cache.Copy()

/// Comparison proc for sorting grid items by distance
/proc/cmp_grid_item_distance(list/a, list/b)
	return a["distance"] - b["distance"]
