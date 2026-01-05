/**
 * Resurgence Outpost - Grid Crafting System
 *
 * The grid system manages the coordinate space where players navigate
 * using Ore Cores to reach weapon coordinates and craft city weapons.
 * Weapons are automatically discovered from /obj/item/ego_weapon/city subtypes.
 */

/// Grid item datum - represents a craftable weapon on the grid
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
/datum/grid_craft_item/proc/distance_from(x, y)
	return sqrt((coord_x - x) ** 2 + (coord_y - y) ** 2)

/// Check if a point is within crafting range
/datum/grid_craft_item/proc/is_in_range(x, y)
	return distance_from(x, y) <= craft_radius

/// Grid crafting manager - handles the grid state for a crafting station
/datum/grid_craft_manager
	/// Current focus point X coordinate
	var/focus_x = 0
	/// Current focus point Y coordinate
	var/focus_y = 0
	/// List of all craftable items on the grid
	var/list/datum/grid_craft_item/items = list()
	/// Number of cores used this session
	var/cores_used = 0
	/// Reference to the owning crafting station
	var/obj/structure/grid_crafting_station/owner = null
	/// Random seed for item placement (based on station)
	var/placement_seed = 0

/datum/grid_craft_manager/New(obj/structure/grid_crafting_station/station)
	owner = station
	placement_seed = rand(1, 999999)
	generate_item_positions()

/// Reset the focus point to origin
/datum/grid_craft_manager/proc/reset_focus()
	focus_x = 0
	focus_y = 0
	cores_used = 0

/// Move the focus point using an ore core
/datum/grid_craft_manager/proc/use_core(obj/item/ore_core/core, direction_x, direction_y)
	if(!core)
		return FALSE

	var/distance = core.roll_distance()

	// For teleport cores, direction is the target relative position
	if(core.core_move_type == CORE_MOVEMENT_TELEPORT)
		// Validate the target is within range
		var/target_dist = sqrt(direction_x ** 2 + direction_y ** 2)
		if(target_dist > distance)
			return FALSE
		focus_x += direction_x
		focus_y += direction_y
	else
		// For directional cores, normalize and apply distance
		var/normalized_x = 0
		var/normalized_y = 0

		// Validate direction based on movement type
		switch(core.core_move_type)
			if(CORE_MOVEMENT_CARDINAL)
				// Only allow pure cardinal directions
				if(direction_x != 0 && direction_y != 0)
					return FALSE
				if(direction_x != 0)
					normalized_x = direction_x > 0 ? 1 : -1
				if(direction_y != 0)
					normalized_y = direction_y > 0 ? 1 : -1

			if(CORE_MOVEMENT_DIAGONAL)
				// Only allow pure diagonal directions
				if(direction_x == 0 || direction_y == 0)
					return FALSE
				normalized_x = direction_x > 0 ? 1 : -1
				normalized_y = direction_y > 0 ? 1 : -1

			if(CORE_MOVEMENT_OCTAGONAL)
				// Allow any of 8 directions
				if(direction_x != 0)
					normalized_x = direction_x > 0 ? 1 : -1
				if(direction_y != 0)
					normalized_y = direction_y > 0 ? 1 : -1

		// Apply movement
		// For diagonal movement, split distance between axes
		if(normalized_x != 0 && normalized_y != 0)
			var/diag_dist = distance / sqrt(2)
			focus_x += round(normalized_x * diag_dist, 1)
			focus_y += round(normalized_y * diag_dist, 1)
		else
			focus_x += round(normalized_x * distance, 1)
			focus_y += round(normalized_y * distance, 1)

	cores_used++
	return TRUE

/// Get all items within crafting range of the focus point
/datum/grid_craft_manager/proc/get_craftable_items()
	var/list/craftable = list()
	for(var/datum/grid_craft_item/item in items)
		if(item.is_in_range(focus_x, focus_y))
			craftable += item
	return craftable

/// Get items sorted by distance from focus point
/datum/grid_craft_manager/proc/get_nearby_items(max_count = 10)
	var/list/nearby = list()

	for(var/datum/grid_craft_item/item in items)
		var/dist = item.distance_from(focus_x, focus_y)
		nearby += list(list("item" = item, "distance" = dist))

	// Sort by distance
	nearby = sortTim(nearby, GLOBAL_PROC_REF(cmp_grid_item_distance))

	// Return only the closest ones
	var/list/result = list()
	for(var/i in 1 to min(max_count, length(nearby)))
		result += nearby[i]["item"]

	return result

/// Generate item positions on the grid based on tier
/datum/grid_craft_manager/proc/generate_item_positions()
	items = list()

	// Auto-discover all city weapons
	var/list/all_weapons = get_city_weapons()

	// Count weapons per tier for dynamic radius calculation
	var/list/tier_counts = list(0, 0, 0, 0, 0)  // Tiers 0-4
	for(var/list/weapon_data in all_weapons)
		var/tier = weapon_data["tier"]
		tier_counts[tier + 1]++  // +1 because list is 1-indexed

	// Base tier configuration - distances are fixed, radius adjusts based on count
	// Higher tiers are further from origin, requiring more core usage
	var/list/tier_distances = list(
		list("min_dist" = 10, "max_dist" = 40),    // Tier 0
		list("min_dist" = 60, "max_dist" = 100),   // Tier 1
		list("min_dist" = 120, "max_dist" = 180),  // Tier 2
		list("min_dist" = 200, "max_dist" = 280),  // Tier 3
		list("min_dist" = 320, "max_dist" = 420)   // Tier 4
	)

	// Base radius ranges - will be adjusted based on weapon count
	var/list/base_radius = list(
		list("min" = 6, "max" = 14),   // Tier 0 base
		list("min" = 5, "max" = 12),   // Tier 1 base
		list("min" = 4, "max" = 10),   // Tier 2 base
		list("min" = 4, "max" = 9),    // Tier 3 base
		list("min" = 3, "max" = 8)     // Tier 4 base
	)

	// Place each weapon on the grid
	for(var/list/weapon_data in all_weapons)
		var/tier = weapon_data["tier"]
		var/list/dist_config = tier_distances[tier + 1]
		var/list/rad_config = base_radius[tier + 1]
		var/count = tier_counts[tier + 1]

		// Generate position based on tier
		var/angle_degrees = rand(0, 359)
		var/dist = rand(dist_config["min_dist"], dist_config["max_dist"])

		// DM's sin/cos use degrees directly
		var/x = round(cos(angle_degrees) * dist, 1)
		var/y = round(sin(angle_degrees) * dist, 1)

		// Dynamic radius based on weapon count in this tier
		// More weapons = smaller radius, fewer weapons = larger radius
		// Formula: radius shrinks as count increases
		var/radius_min = rad_config["min"]
		var/radius_max = rad_config["max"]
		var/count_modifier = 1.0
		if(count <= 5)
			count_modifier = 1.5  // Few weapons - 50% larger radius
		else if(count <= 15)
			count_modifier = 1.2  // Some weapons - 20% larger
		else if(count <= 30)
			count_modifier = 1.0  // Normal
		else if(count <= 50)
			count_modifier = 0.8  // Many weapons - 20% smaller
		else
			count_modifier = 0.6  // Lots of weapons - 40% smaller

		var/adjusted_min = round(radius_min * count_modifier, 1)
		var/adjusted_max = round(radius_max * count_modifier, 1)
		var/radius = rand(max(adjusted_min, 2), max(adjusted_max, 3))

		var/datum/grid_craft_item/item = new(
			weapon_data["name"],
			weapon_data["desc"],
			x,
			y,
			radius,
			tier,
			weapon_data["type"]
		)
		items += item

/// Auto-discover all city weapons and calculate their tier from attribute requirements
/datum/grid_craft_manager/proc/get_city_weapons()
	var/list/weapons = list()

	// Get all subtypes of city weapons (both melee and ranged)
	var/list/weapon_types = subtypesof(/obj/item/ego_weapon/city)
	weapon_types += subtypesof(/obj/item/ego_weapon/ranged/city)

	for(var/weapon_type in weapon_types)
		// Create a temporary instance to read its properties
		var/obj/item/ego_weapon/temp_weapon = new weapon_type(null)

		// Calculate average attribute requirement
		var/avg_req = 0
		if(LAZYLEN(temp_weapon.attribute_requirements))
			var/total_req = 0
			for(var/attr in temp_weapon.attribute_requirements)
				total_req += temp_weapon.attribute_requirements[attr]
			avg_req = total_req / length(temp_weapon.attribute_requirements)

		// Calculate tier based on average requirement
		// 0-29 = Tier 0 (Crude)
		// 30-59 = Tier 1 (Common)
		// 60-89 = Tier 2 (Refined)
		// 90-119 = Tier 3 (Exceptional)
		// 120+ = Tier 4 (Legendary)
		var/tier = 0
		if(avg_req >= 120)
			tier = 4
		else if(avg_req >= 90)
			tier = 3
		else if(avg_req >= 60)
			tier = 2
		else if(avg_req >= 30)
			tier = 1
		else
			tier = 0

		// Build description from weapon properties
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

		// Clean up temporary weapon
		qdel(temp_weapon)

	return weapons

/// Comparison proc for sorting grid items by distance
/proc/cmp_grid_item_distance(list/a, list/b)
	return a["distance"] - b["distance"]
