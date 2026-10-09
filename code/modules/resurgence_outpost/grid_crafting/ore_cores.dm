/**
 * Resurgence Outpost - Ore Cores
 *
 * Ore Cores are created by processing ores in the Ore Refiner.
 * Each core has properties that determine how it moves the focus point
 * on the Grid Crafting Station.
 */

// Core movement types are in _resurgence_defines.dm

/// Core ore types
#define CORE_ORE_IRON "iron"
#define CORE_ORE_SILVER "silver"
#define CORE_ORE_ALLOY "alloy"
#define CORE_ORE_GOLD "gold"

/// Fuel levels
#define CORE_FUEL_UNFUELED 0    // -50% distance
#define CORE_FUEL_LOW 1         // -25% distance
#define CORE_FUEL_STANDARD 2    // Normal distance
#define CORE_FUEL_HIGH 3        // +25% distance
#define CORE_FUEL_SUPERCHARGED 4 // +50% distance

/// Refinement levels (determines base distance)
#define CORE_LEVEL_CRUDE 0       // 1-2 units
#define CORE_LEVEL_COMMON 1      // 3-5 units
#define CORE_LEVEL_REFINED 2     // 6-10 units
#define CORE_LEVEL_EXCEPTIONAL 3 // 11-20 units
#define CORE_LEVEL_LEGENDARY 4   // 21-40 units

/obj/item/ore_core
	name = "ore core"
	desc = "A refined ore core used for grid crafting navigation."
	icon = 'ModularLobotomy/_Lobotomyicons/workshop.dmi'
	icon_state = "blankcore"
	w_class = WEIGHT_CLASS_SMALL

	/// The ore type of this core (iron, silver, alloy, gold)
	var/ore_type = CORE_ORE_IRON
	/// The refinement level (0-4, determines base distance)
	var/refinement_level = CORE_LEVEL_COMMON
	/// The fuel level (0-4, modifies distance)
	var/fuel_level = CORE_FUEL_STANDARD
	/// Whether this core is gilded (adds +10% range, or +15% for gilded gold)
	var/gilded = FALSE
	/// Whether this core has a minor ore bonus (+5% distance from unbalanced mixing)
	var/has_minor_ore_bonus = FALSE

	/// Core movement type derived from ore_type (not /atom/movable movement_type)
	var/core_move_type = CORE_MOVEMENT_CARDINAL

/obj/item/ore_core/Initialize(mapload)
	. = ..()
	update_movement_type()
	update_appearance()

/// Update the movement type based on ore type
/obj/item/ore_core/proc/update_movement_type()
	switch(ore_type)
		if(CORE_ORE_IRON)
			core_move_type = CORE_MOVEMENT_CARDINAL
		if(CORE_ORE_SILVER)
			core_move_type = CORE_MOVEMENT_DIAGONAL
		if(CORE_ORE_ALLOY)
			core_move_type = CORE_MOVEMENT_OCTAGONAL
		if(CORE_ORE_GOLD)
			core_move_type = CORE_MOVEMENT_TELEPORT

/// Update the core's name, description, and appearance
/obj/item/ore_core/proc/update_appearance()
	var/level_name = get_level_name()
	var/ore_name = get_ore_name()

	if(gilded)
		name = "[level_name] gilded [ore_name] core"
	else
		name = "[level_name] [ore_name] core"

	// Update color based on ore type
	switch(ore_type)
		if(CORE_ORE_IRON)
			color = "#8B5A2B"  // Brown
		if(CORE_ORE_SILVER)
			color = "#C0C0C0"  // Silver
		if(CORE_ORE_ALLOY)
			color = "#505050"  // Dark gray
		if(CORE_ORE_GOLD)
			color = "#FFD700"  // Gold

	// Add golden tint if gilded
	if(gilded && ore_type != CORE_ORE_GOLD)
		// Blend with gold color
		color = blend_hex_colors(color, "#FFD700", 0.3)

	desc = get_core_description()

/// Get the display name for the refinement level
/obj/item/ore_core/proc/get_level_name()
	switch(refinement_level)
		if(CORE_LEVEL_CRUDE)
			return "crude"
		if(CORE_LEVEL_COMMON)
			return "common"
		if(CORE_LEVEL_REFINED)
			return "refined"
		if(CORE_LEVEL_EXCEPTIONAL)
			return "exceptional"
		if(CORE_LEVEL_LEGENDARY)
			return "legendary"
	return "unknown"

/// Get the display name for the fuel level
/obj/item/ore_core/proc/get_fuel_name()
	switch(fuel_level)
		if(CORE_FUEL_UNFUELED)
			return "unfueled"
		if(CORE_FUEL_LOW)
			return "low fuel"
		if(CORE_FUEL_STANDARD)
			return "standard"
		if(CORE_FUEL_HIGH)
			return "high fuel"
		if(CORE_FUEL_SUPERCHARGED)
			return "supercharged"
	return "unknown"

/// Get the display name for the ore type
/obj/item/ore_core/proc/get_ore_name()
	switch(ore_type)
		if(CORE_ORE_IRON)
			return "iron"
		if(CORE_ORE_SILVER)
			return "silver"
		if(CORE_ORE_ALLOY)
			return "alloy"
		if(CORE_ORE_GOLD)
			return "gold"
	return "unknown"

/// Get the movement pattern description
/obj/item/ore_core/proc/get_movement_description()
	switch(core_move_type)
		if(CORE_MOVEMENT_CARDINAL)
			return "cardinal directions (N/S/E/W)"
		if(CORE_MOVEMENT_DIAGONAL)
			return "diagonal directions (NE/NW/SE/SW)"
		if(CORE_MOVEMENT_OCTAGONAL)
			return "all 8 directions"
		if(CORE_MOVEMENT_TELEPORT)
			return "teleport to any point in range"
	return "unknown movement"

/// Get the base distance range for this core's level
/obj/item/ore_core/proc/get_base_distance_range()
	switch(refinement_level)
		if(CORE_LEVEL_CRUDE)
			return list(1, 2)
		if(CORE_LEVEL_COMMON)
			return list(3, 5)
		if(CORE_LEVEL_REFINED)
			return list(6, 10)
		if(CORE_LEVEL_EXCEPTIONAL)
			return list(11, 20)
		if(CORE_LEVEL_LEGENDARY)
			return list(21, 40)
	return list(1, 2)

/// Get the fuel modifier for distance
/obj/item/ore_core/proc/get_fuel_modifier()
	switch(fuel_level)
		if(CORE_FUEL_UNFUELED)
			return 0.5   // -50%
		if(CORE_FUEL_LOW)
			return 0.75  // -25%
		if(CORE_FUEL_STANDARD)
			return 1.0   // Normal
		if(CORE_FUEL_HIGH)
			return 1.25  // +25%
		if(CORE_FUEL_SUPERCHARGED)
			return 1.5   // +50%
	return 1.0

/// Get the total distance modifier (fuel + gilded + minor ore bonus)
/obj/item/ore_core/proc/get_total_modifier()
	var/modifier = get_fuel_modifier()

	// Gilded bonus
	if(gilded)
		if(ore_type == CORE_ORE_GOLD)
			modifier *= 1.15  // +15% for gilded gold
		else
			modifier *= 1.10  // +10% for other gilded cores

	// Minor ore bonus from unbalanced mixing
	if(has_minor_ore_bonus)
		modifier *= 1.05  // +5%

	return modifier

/// Get the final distance range after all modifiers
/obj/item/ore_core/proc/get_final_distance_range()
	var/list/base_range = get_base_distance_range()
	var/modifier = get_total_modifier()

	var/min_dist = round(base_range[1] * modifier, 0.1)
	var/max_dist = round(base_range[2] * modifier, 0.1)

	return list(min_dist, max_dist)

/// Roll a random distance within the core's range
/obj/item/ore_core/proc/roll_distance()
	var/list/range = get_final_distance_range()
	// Use a continuous random value, then round
	return round(rand() * (range[2] - range[1]) + range[1], 1)

/// Generate a detailed description for the core
/obj/item/ore_core/proc/get_core_description()
	var/list/desc_parts = list()

	desc_parts += "A [get_level_name()] ore core infused with [get_ore_name()]."

	if(gilded)
		desc_parts += "It has a golden sheen from gold infusion."

	desc_parts += ""
	desc_parts += "<b>Movement:</b> [get_movement_description()]"

	var/list/final_range = get_final_distance_range()
	desc_parts += "<b>Distance:</b> [final_range[1]]-[final_range[2]] units"
	desc_parts += "<b>Fuel:</b> [get_fuel_name()]"

	if(has_minor_ore_bonus)
		desc_parts += "<i>Mixed ore bonus: +5% distance</i>"

	return desc_parts.Join("\n")

/obj/item/ore_core/examine(mob/user)
	. = ..()
	. += span_notice("Use this at a Grid Crafting Station to move the focus point.")

/// Helper to blend two hex colors
/proc/blend_hex_colors(color1, color2, blend_amount)
	// Simple blend - just return color1 with slight gold tint for now
	// A proper implementation would parse and blend RGB values
	return color1

// ===== Ore Core Subtypes for Spawning =====

/obj/item/ore_core/iron
	ore_type = CORE_ORE_IRON

/obj/item/ore_core/silver
	ore_type = CORE_ORE_SILVER

/obj/item/ore_core/alloy
	ore_type = CORE_ORE_ALLOY

/obj/item/ore_core/gold
	ore_type = CORE_ORE_GOLD
