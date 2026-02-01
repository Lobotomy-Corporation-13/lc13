/**
 * Grid Crafting System - Navigation Core
 *
 * The final usable item created from a template + abnochem.
 * Used at the Grid Crafting Station to navigate the grid.
 */

/obj/item/navigation_core
	name = "navigation core"
	desc = "A finalized enkephalin navigation core used for grid crafting."
	icon = 'ModularLobotomy/_Lobotomyicons/refiner.dmi'
	icon_state = "canned_base"
	w_class = WEIGHT_CLASS_SMALL

	/// The navigation movement type (1-7)
	var/nav_movement_type = CORE_MOVEMENT_CHARGE
	/// The sin type for diminishing returns tracking
	var/sin_type = CORE_MOVEMENT_CHARGE
	/// Template grade
	var/grade = TEMPLATE_GRADE_BASIC
	/// Base distance range
	var/min_distance = TEMPLATE_DIST_BASIC_MIN
	var/max_distance = TEMPLATE_DIST_BASIC_MAX
	/// Maximum weapon tier accessible
	var/max_tier = TEMPLATE_MAX_TIER_BASIC
	/// Quantity modifier (0.5 to 1.5)
	var/quantity_modifier = 1.0
	/// Whether this core bypasses quantity requirements (Level 3+ chems)
	var/bypasses_quantity = FALSE

/obj/item/navigation_core/Initialize(mapload)
	. = ..()
	UpdateAppearance()

/obj/item/navigation_core/attackby(obj/item/I, mob/user, params)
	// Block reagent container transfers - core is finalized
	if(istype(I, /obj/item/reagent_containers))
		to_chat(user, span_warning("The navigation core is already finalized and cannot accept any more chemicals."))
		return TRUE
	return ..()

/obj/item/navigation_core/proc/UpdateAppearance()
	// Update name based on properties
	var/grade_name = GetGradeName()
	var/movement_name = GetMovementTypeName(nav_movement_type)
	name = "[grade_name] [movement_name] navigation core"

	// Clear existing overlays and reset color
	cut_overlays()
	color = null
	icon_state = "canned_base"

	// Overlay 1: Overcharge effect (darker when quantity_modifier > 1.0)
	if(quantity_modifier > 1.0)
		var/mutable_appearance/overcharge = mutable_appearance(icon, "canned_overcharge")
		overcharge.appearance_flags = RESET_COLOR
		// Calculate darkness: 1.0 = no effect, 1.5 = maximum darkness
		// Alpha ranges from 0 (at 1.0) to 180 (at 1.5)
		var/darkness = (quantity_modifier - 1.0) / 0.5  // 0.0 to 1.0
		overcharge.alpha = round(darkness * 180)
		add_overlay(overcharge)

	// Overlay 2: Tier indicator based on grade
	var/mutable_appearance/tier_overlay = mutable_appearance(icon, "canned_tier")
	tier_overlay.appearance_flags = RESET_COLOR
	switch(grade)
		if(TEMPLATE_GRADE_BASIC)
			tier_overlay.color = "#8B7355"  // Brown
		if(TEMPLATE_GRADE_STANDARD)
			tier_overlay.color = "#4A7C59"  // Green
		if(TEMPLATE_GRADE_QUALITY)
			tier_overlay.color = "#4169E1"  // Blue
		if(TEMPLATE_GRADE_SUPERIOR)
			tier_overlay.color = "#9932CC"  // Purple
	add_overlay(tier_overlay)

	// Overlay 3: Outline colored by movement type (sin colors)
	var/mutable_appearance/outline = mutable_appearance(icon, "canned_outline")
	outline.appearance_flags = RESET_COLOR
	switch(nav_movement_type)
		if(CORE_MOVEMENT_CHARGE)   // Wrath
			outline.color = "#821c15"
		if(CORE_MOVEMENT_ATTRACT)  // Lust
			outline.color = "#d67c0d"
		if(CORE_MOVEMENT_SHUFFLE)  // Sloth
			outline.color = "#ad8d23"
		if(CORE_MOVEMENT_EXPAND)   // Gluttony
			outline.color = "#59b53f"
		if(CORE_MOVEMENT_DRIFT)    // Gloom
			outline.color = "#509799"
		if(CORE_MOVEMENT_TELEPORT) // Pride
			outline.color = "#1f2278"
		if(CORE_MOVEMENT_MIRROR)   // Envy
			outline.color = "#703794"
	add_overlay(outline)

/obj/item/navigation_core/proc/GetGradeName()
	switch(grade)
		if(TEMPLATE_GRADE_BASIC)
			return "Basic"
		if(TEMPLATE_GRADE_STANDARD)
			return "Standard"
		if(TEMPLATE_GRADE_QUALITY)
			return "Quality"
		if(TEMPLATE_GRADE_SUPERIOR)
			return "Superior"
	return "Unknown"

/obj/item/navigation_core/examine(mob/user)
	. = ..()
	var/sin_name = GetSinTypeName(sin_type)
	var/movement_name = GetMovementTypeName(nav_movement_type)
	var/movement_mod = GetMovementDistanceModifier(nav_movement_type)

	. += span_notice("<b>Sin:</b> [sin_name]")
	. += span_notice("<b>Movement:</b> [movement_name] ([GetMovementDescription()])")
	. += span_notice("<b>Grade:</b> [GetGradeName()]")
	. += span_notice("<b>Base Distance:</b> [min_distance]-[max_distance] units")
	. += span_notice("<b>Max Weapon Tier:</b> [max_tier]")

	// Show modifiers
	. += ""
	. += span_notice("<b>Distance Modifiers:</b>")
	. += span_notice("  Movement Type: [round(movement_mod * 100)]%")
	if(bypasses_quantity)
		. += span_notice("  Quantity: 100% (advanced chem)")
	else
		. += span_notice("  Quantity: [round(quantity_modifier * 100)]%")

	// Calculate final range
	var/final_min = round(min_distance * movement_mod * quantity_modifier, 0.1)
	var/final_max = round(max_distance * movement_mod * quantity_modifier, 0.1)
	. += span_notice("<b>Final Distance Range:</b> [final_min]-[final_max] units")

	. += ""
	. += span_notice("Use this at a Grid Crafting Station to navigate the grid.")

/obj/item/navigation_core/proc/GetMovementDescription()
	switch(nav_movement_type)
		if(CORE_MOVEMENT_CHARGE)
			return "straight line in cardinal direction"
		if(CORE_MOVEMENT_ATTRACT)
			return "moves toward nearest weapon"
		if(CORE_MOVEMENT_SHUFFLE)
			return "random direction and distance"
		if(CORE_MOVEMENT_EXPAND)
			return "any of 8 directions"
		if(CORE_MOVEMENT_DRIFT)
			return "curved path, imprecise"
		if(CORE_MOVEMENT_TELEPORT)
			return "direct jump to target"
		if(CORE_MOVEMENT_MIRROR)
			return "mimics previous movement type"
	return "unknown"

/// Roll the actual distance for this core (before diminishing returns)
/obj/item/navigation_core/proc/RollDistance()
	var/base_dist = rand(min_distance * 10, max_distance * 10) / 10  // Decimal precision
	var/movement_mod = GetMovementDistanceModifier(nav_movement_type)
	return base_dist * movement_mod * quantity_modifier

/// Get the final distance after all modifiers including diminishing returns
/obj/item/navigation_core/proc/GetFinalDistance(obj/structure/grid_crafting_station/station)
	var/rolled = RollDistance()
	var/diminishing = GetDiminishingModifier(station, sin_type)
	return round(rolled * diminishing, 0.1)

/// Get the maximum possible distance (for UI display)
/obj/item/navigation_core/proc/GetMaxPossibleDistance()
	var/movement_mod = GetMovementDistanceModifier(nav_movement_type)
	return round(max_distance * movement_mod * quantity_modifier, 0.1)

/// Get the minimum possible distance (for UI display)
/obj/item/navigation_core/proc/GetMinPossibleDistance()
	var/movement_mod = GetMovementDistanceModifier(nav_movement_type)
	return round(min_distance * movement_mod * quantity_modifier, 0.1)

// ===== Pre-made Core Subtypes (for testing/spawning) =====

/obj/item/navigation_core/charge
	nav_movement_type = CORE_MOVEMENT_CHARGE
	sin_type = CORE_MOVEMENT_CHARGE

/obj/item/navigation_core/attract
	nav_movement_type = CORE_MOVEMENT_ATTRACT
	sin_type = CORE_MOVEMENT_ATTRACT

/obj/item/navigation_core/shuffle
	nav_movement_type = CORE_MOVEMENT_SHUFFLE
	sin_type = CORE_MOVEMENT_SHUFFLE

/obj/item/navigation_core/expand
	nav_movement_type = CORE_MOVEMENT_EXPAND
	sin_type = CORE_MOVEMENT_EXPAND

/obj/item/navigation_core/drift
	nav_movement_type = CORE_MOVEMENT_DRIFT
	sin_type = CORE_MOVEMENT_DRIFT

/obj/item/navigation_core/teleport
	nav_movement_type = CORE_MOVEMENT_TELEPORT
	sin_type = CORE_MOVEMENT_TELEPORT

/obj/item/navigation_core/mirror
	nav_movement_type = CORE_MOVEMENT_MIRROR
	sin_type = CORE_MOVEMENT_MIRROR

// Superior grade versions for testing high-tier access
/obj/item/navigation_core/superior
	grade = TEMPLATE_GRADE_SUPERIOR
	min_distance = TEMPLATE_DIST_SUPERIOR_MIN
	max_distance = TEMPLATE_DIST_SUPERIOR_MAX
	max_tier = TEMPLATE_MAX_TIER_SUPERIOR
