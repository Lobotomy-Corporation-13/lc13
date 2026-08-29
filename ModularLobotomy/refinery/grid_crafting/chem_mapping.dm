/**
 * Grid Crafting System - Chem Mapping
 *
 * Maps abnochem reagents to movement types.
 * Handles quantity modifiers and diminishing returns.
 */

// ===== Movement Distance Modifier Lookup =====

GLOBAL_LIST_INIT(movement_distance_modifiers, list(
	"[CORE_MOVEMENT_CHARGE]" = MOVEMENT_MOD_CHARGE,
	"[CORE_MOVEMENT_ATTRACT]" = MOVEMENT_MOD_ATTRACT,
	"[CORE_MOVEMENT_SHUFFLE]" = MOVEMENT_MOD_SHUFFLE,
	"[CORE_MOVEMENT_EXPAND]" = MOVEMENT_MOD_EXPAND,
	"[CORE_MOVEMENT_DRIFT]" = MOVEMENT_MOD_DRIFT,
	"[CORE_MOVEMENT_TELEPORT]" = MOVEMENT_MOD_TELEPORT,
	"[CORE_MOVEMENT_MIRROR]" = MOVEMENT_MOD_MIRROR
))

/// Get the distance modifier for a movement type
/proc/GetMovementDistanceModifier(movement_type)
	var/key = "[movement_type]"
	if(key in GLOB.movement_distance_modifiers)
		return GLOB.movement_distance_modifiers[key]
	return 1

// ===== Movement Type Names =====

GLOBAL_LIST_INIT(movement_type_names, list(
	"[CORE_MOVEMENT_CHARGE]" = "Charge",
	"[CORE_MOVEMENT_ATTRACT]" = "Attract",
	"[CORE_MOVEMENT_SHUFFLE]" = "Shuffle",
	"[CORE_MOVEMENT_EXPAND]" = "Expand",
	"[CORE_MOVEMENT_DRIFT]" = "Drift",
	"[CORE_MOVEMENT_TELEPORT]" = "Teleport",
	"[CORE_MOVEMENT_MIRROR]" = "Mirror"
))

/// Get the display name for a movement type
/proc/GetMovementTypeName(movement_type)
	var/key = "[movement_type]"
	if(key in GLOB.movement_type_names)
		return GLOB.movement_type_names[key]
	return "Unknown"

// ===== Sin Type Names (for diminishing returns tracking) =====

GLOBAL_LIST_INIT(sin_type_names, list(
	"[CORE_MOVEMENT_CHARGE]" = "Wrath",
	"[CORE_MOVEMENT_ATTRACT]" = "Lust",
	"[CORE_MOVEMENT_SHUFFLE]" = "Sloth",
	"[CORE_MOVEMENT_EXPAND]" = "Gluttony",
	"[CORE_MOVEMENT_DRIFT]" = "Gloom",
	"[CORE_MOVEMENT_TELEPORT]" = "Pride",
	"[CORE_MOVEMENT_MIRROR]" = "Envy"
))

/// Get the sin name for a movement type
/proc/GetSinTypeName(movement_type)
	var/key = "[movement_type]"
	if(key in GLOB.sin_type_names)
		return GLOB.sin_type_names[key]
	return "Unknown"

// ===== Chem to Movement Mapping =====

/// Returns list(movement_type, bypasses_quantity, sin_type) or null if invalid
/proc/GetMovementFromChem(datum/reagent/R)
	if(!R)
		return null

	// Level 1 - Sins (affected by quantity)
	if(istype(R, /datum/reagent/abnormality/sin/wrath))
		return list(CORE_MOVEMENT_CHARGE, FALSE, CORE_MOVEMENT_CHARGE)
	if(istype(R, /datum/reagent/abnormality/sin/lust))
		return list(CORE_MOVEMENT_ATTRACT, FALSE, CORE_MOVEMENT_ATTRACT)
	if(istype(R, /datum/reagent/abnormality/sin/sloth))
		return list(CORE_MOVEMENT_SHUFFLE, FALSE, CORE_MOVEMENT_SHUFFLE)
	if(istype(R, /datum/reagent/abnormality/sin/gluttony))
		return list(CORE_MOVEMENT_EXPAND, FALSE, CORE_MOVEMENT_EXPAND)
	if(istype(R, /datum/reagent/abnormality/sin/gloom))
		return list(CORE_MOVEMENT_DRIFT, FALSE, CORE_MOVEMENT_DRIFT)
	if(istype(R, /datum/reagent/abnormality/sin/pride))
		return list(CORE_MOVEMENT_TELEPORT, FALSE, CORE_MOVEMENT_TELEPORT)
	if(istype(R, /datum/reagent/abnormality/sin/envy))
		return list(CORE_MOVEMENT_MIRROR, FALSE, CORE_MOVEMENT_MIRROR)

	// Level 2 - Syrups (affected by quantity)
	if(istype(R, /datum/reagent/abnormality/heartysyrup))
		return list(CORE_MOVEMENT_SHUFFLE, FALSE, CORE_MOVEMENT_SHUFFLE)   // Sloth + Envy -> Sloth
	if(istype(R, /datum/reagent/abnormality/bittersyrup))
		return list(CORE_MOVEMENT_MIRROR, FALSE, CORE_MOVEMENT_MIRROR)     // Envy + Lust -> Envy
	if(istype(R, /datum/reagent/abnormality/tastesyrup))
		return list(CORE_MOVEMENT_CHARGE, FALSE, CORE_MOVEMENT_CHARGE)     // Pride + Wrath -> Wrath
	if(istype(R, /datum/reagent/abnormality/focussyrup))
		return list(CORE_MOVEMENT_DRIFT, FALSE, CORE_MOVEMENT_DRIFT)       // Gloom + Gluttony -> Gloom

	// Level 3 - Derivatives (BYPASS quantity - always 100%)
	if(istype(R, /datum/reagent/abnormality/nutrition))      // NT: Wrath + Lust + Pride
		return list(CORE_MOVEMENT_CHARGE, TRUE, CORE_MOVEMENT_CHARGE)
	if(istype(R, /datum/reagent/abnormality/cleanliness))    // CN: Sloth + Gluttony + Wrath
		return list(CORE_MOVEMENT_SHUFFLE, TRUE, CORE_MOVEMENT_SHUFFLE)
	if(istype(R, /datum/reagent/abnormality/consensus))      // CS: Gloom + Pride + Lust
		return list(CORE_MOVEMENT_DRIFT, TRUE, CORE_MOVEMENT_DRIFT)
	if(istype(R, /datum/reagent/abnormality/amusement))      // AM: Envy + Gluttony + Pride
		return list(CORE_MOVEMENT_MIRROR, TRUE, CORE_MOVEMENT_MIRROR)
	if(istype(R, /datum/reagent/abnormality/violence))       // VL: Lust + Gloom + Sloth
		return list(CORE_MOVEMENT_ATTRACT, TRUE, CORE_MOVEMENT_ATTRACT)
	if(istype(R, /datum/reagent/abnormality/abno_oil))       // RO: Gluttony + Envy + Wrath
		return list(CORE_MOVEMENT_EXPAND, TRUE, CORE_MOVEMENT_EXPAND)
	if(istype(R, /datum/reagent/abnormality/woe))            // WP: Gloom + Envy + Sloth
		return list(CORE_MOVEMENT_DRIFT, TRUE, CORE_MOVEMENT_DRIFT)

	// Level 4 - High Level (BYPASS quantity - always 100%)
	if(istype(R, /datum/reagent/abnormality/odisone))        // Focused + VL
		return list(CORE_MOVEMENT_ATTRACT, TRUE, CORE_MOVEMENT_ATTRACT)
	if(istype(R, /datum/reagent/abnormality/gaspilleur))     // Focused + NT
		return list(CORE_MOVEMENT_CHARGE, TRUE, CORE_MOVEMENT_CHARGE)
	if(istype(R, /datum/reagent/abnormality/lesser_sange_rau)) // Tasteless + AM
		return list(CORE_MOVEMENT_MIRROR, TRUE, CORE_MOVEMENT_MIRROR)
	if(istype(R, /datum/reagent/abnormality/culpusumidus))   // Tasteless + WP
		return list(CORE_MOVEMENT_DRIFT, TRUE, CORE_MOVEMENT_DRIFT)
	if(istype(R, /datum/reagent/abnormality/serelam))        // Hearty + RO
		return list(CORE_MOVEMENT_EXPAND, TRUE, CORE_MOVEMENT_EXPAND)
	if(istype(R, /datum/reagent/abnormality/nepenthe))       // Bitter + CS
		return list(CORE_MOVEMENT_DRIFT, TRUE, CORE_MOVEMENT_DRIFT)
	if(istype(R, /datum/reagent/abnormality/piedrabital))    // Hearty + CN
		return list(CORE_MOVEMENT_SHUFFLE, TRUE, CORE_MOVEMENT_SHUFFLE)
	if(istype(R, /datum/reagent/abnormality/dyscrasone))     // Bitter + Tasteless
		return list(CORE_MOVEMENT_TELEPORT, TRUE, CORE_MOVEMENT_TELEPORT)

	// ZAYIN Abnormality Chems (affected by quantity)
	if(istype(R, /datum/reagent/abnormality/onesin))         // One Sin - Holy Light
		return list(CORE_MOVEMENT_ATTRACT, FALSE, CORE_MOVEMENT_ATTRACT)    // Lust
	if(istype(R, /datum/reagent/abnormality/sleeping))       // Sleeping Beauty - Puffy Clouds
		return list(CORE_MOVEMENT_SHUFFLE, FALSE, CORE_MOVEMENT_SHUFFLE)    // Sloth - drowsiness
	if(istype(R, /datum/reagent/abnormality/fairy_festival)) // Fairy Festival - Nectar
		return list(CORE_MOVEMENT_EXPAND, FALSE, CORE_MOVEMENT_EXPAND)      // Gluttony
	if(istype(R, /datum/reagent/abnormality/bottle))         // Bottle of Tears - Crumbs
		return list(CORE_MOVEMENT_DRIFT, FALSE, CORE_MOVEMENT_DRIFT)        // Gloom - sadness
	if(istype(R, /datum/reagent/abnormality/bald))           // You're Bald - Essence of Baldness
		return list(CORE_MOVEMENT_TELEPORT, FALSE, CORE_MOVEMENT_TELEPORT)  // Pride - self-acceptance
	if(istype(R, /datum/reagent/abnormality/quiet_day))      // A Quiet Day - Liquid Nostalgia
		return list(CORE_MOVEMENT_DRIFT, FALSE, CORE_MOVEMENT_DRIFT)        // Gloom - nostalgia
	if(istype(R, /datum/reagent/abnormality/wellcheers_zero)) // Wellcheers - Zero
		return list(CORE_MOVEMENT_MIRROR, FALSE, CORE_MOVEMENT_MIRROR)      // Envy
	if(istype(R, /datum/reagent/abnormality/we_can_change_anything)) // We Can Change Anything - Red Goo
		return list(CORE_MOVEMENT_CHARGE, FALSE, CORE_MOVEMENT_CHARGE)      // Wrath - violence

	return null  // Invalid chem

// ===== Quantity Modifier Calculation =====

/// Calculate distance modifier based on reagent quantity (0.5 to 1.5)
/proc/GetQuantityModifier(amount, bypasses_quantity)
	if(bypasses_quantity)
		return 1  // Always 100% for advanced chems

	// Clamp to valid range
	amount = clamp(amount, CHEM_QUANTITY_MIN, CHEM_QUANTITY_MAX)

	// Linear interpolation: 5u = 0.5, 15u = 1, 25u = 1.5
	var/range = CHEM_QUANTITY_MAX - CHEM_QUANTITY_MIN  // 20
	var/normalized = (amount - CHEM_QUANTITY_MIN) / range  // 0 to 1
	return 0.5 + normalized  // 0.5 to 1.5

// ===== Diminishing Returns System =====
// Tracking is stored on each grid_crafting_station in sin_overuse_counts

/// Get the current diminishing returns modifier for a station (read-only, for UI)
/proc/GetDiminishingModifier(obj/structure/grid_crafting_station/station, movement_type)
	if(!station)
		return 1

	var/list/sin_counts = station.sin_overuse_counts
	if(!sin_counts || !(movement_type in sin_counts))
		return 1

	// Calculate penalty based on current count for this sin
	var/uses = sin_counts[movement_type]
	if(uses <= 1)
		return 1

	var/penalty = (uses - 1) * DIMINISHING_PENALTY_PER_USE
	return max(1 - DIMINISHING_MAX_PENALTY, 1 - penalty)

/// Apply diminishing returns after using a core (updates the tracking)
/proc/ApplyDiminishingReturns(obj/structure/grid_crafting_station/station, movement_type)
	if(!station)
		return

	var/list/sin_counts = station.sin_overuse_counts

	// Increment the used sin type (capped at max stack)
	if(movement_type in sin_counts)
		sin_counts[movement_type] = min(sin_counts[movement_type] + 1, DIMINISHING_MAX_STACK)
	else
		sin_counts[movement_type] = 1

	// Decrease all OTHER sin types by 1 (minimum 0, remove if 0)
	var/list/to_remove = list()
	for(var/sin_type in sin_counts)
		if(sin_type == movement_type)
			continue
		sin_counts[sin_type] = sin_counts[sin_type] - 1
		if(sin_counts[sin_type] <= 0)
			to_remove += sin_type

	// Clean up zeroed entries
	for(var/sin_type in to_remove)
		sin_counts -= sin_type

/// Reset diminishing returns for a station
/proc/ResetDiminishingReturns(obj/structure/grid_crafting_station/station)
	if(!station)
		return
	station.sin_overuse_counts = list()

/// Get current count for a station and movement type
/proc/GetConsecutiveCount(obj/structure/grid_crafting_station/station, movement_type)
	if(!station)
		return 0
	var/list/sin_counts = station.sin_overuse_counts
	if(!sin_counts || !(movement_type in sin_counts))
		return 0
	return sin_counts[movement_type]
