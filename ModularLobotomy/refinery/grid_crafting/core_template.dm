/**
 * Grid Crafting System - Core Template
 *
 * Purchasable templates that are filled with abnochem reagents
 * to create navigation cores for grid crafting.
 * Inherits from reagent_containers so it can be used on abnormalities.
 */

/obj/item/reagent_containers/core_template
	name = "navigation core template"
	desc = "An empty template that can be filled with enkephalin-derived chemicals to create a navigation core."
	icon = 'ModularLobotomy/_Lobotomyicons/refiner.dmi'
	icon_state = "canned_base"
	w_class = WEIGHT_CLASS_SMALL
	volume = 30
	reagent_flags = OPENCONTAINER | INJECTABLE | DRAWABLE
	possible_transfer_amounts = list()  // Disable transfer amount cycling

	/// The grade of this template (determines distance range and tier access)
	var/grade = TEMPLATE_GRADE_BASIC
	/// Cost in Ahn
	var/cost = TEMPLATE_COST_BASIC
	/// Minimum distance
	var/min_distance = TEMPLATE_DIST_BASIC_MIN
	/// Maximum distance
	var/max_distance = TEMPLATE_DIST_BASIC_MAX
	/// Maximum weapon tier accessible
	var/max_tier = TEMPLATE_MAX_TIER_BASIC

/obj/item/reagent_containers/core_template/Initialize(mapload)
	. = ..()
	UpdateColor()

/obj/item/reagent_containers/core_template/examine(mob/user)
	. = ..()
	. += span_notice("<b>Grade:</b> [GetGradeName()]")
	. += span_notice("<b>Distance Range:</b> [min_distance]-[max_distance] units")
	. += span_notice("<b>Max Weapon Tier:</b> [max_tier]")

	if(reagents && reagents.total_volume > 0)
		var/datum/reagent/R = reagents.reagent_list[1]
		var/list/chem_data = GetMovementFromChem(R)
		if(chem_data)
			var/movement_type = chem_data[1]
			var/bypasses = chem_data[2]
			var/quantity_mod = GetQuantityModifier(reagents.total_volume, bypasses)
			. += span_notice("<b>Reagent:</b> [R.name] ([reagents.total_volume]u)")
			. += span_notice("<b>Movement Type:</b> [GetMovementTypeName(movement_type)]")
			if(bypasses)
				. += span_notice("<b>Quantity Modifier:</b> 100% (advanced chem)")
			else
				. += span_notice("<b>Quantity Modifier:</b> [round(quantity_mod * 100)]%")
			. += span_notice("Use in hand to finalize into a navigation core.")
		else
			. += span_warning("Contains invalid reagent: [R.name]")
	else
		. += span_notice("Fill with an enkephalin-derived chemical to create a navigation core.")

/obj/item/reagent_containers/core_template/proc/UpdateColor()
	// Color based on grade
	switch(grade)
		if(TEMPLATE_GRADE_BASIC)
			color = "#8B7355"  // Brown
		if(TEMPLATE_GRADE_STANDARD)
			color = "#4A7C59"  // Green
		if(TEMPLATE_GRADE_QUALITY)
			color = "#4169E1"  // Blue
		if(TEMPLATE_GRADE_SUPERIOR)
			color = "#9932CC"  // Purple

/obj/item/reagent_containers/core_template/proc/GetGradeName()
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

/obj/item/reagent_containers/core_template/attack_self(mob/user)
	// Override parent's transfer amount cycling - we finalize instead

	// Check if we have reagents
	if(!reagents || reagents.total_volume <= 0)
		to_chat(user, span_warning("The template is empty! Add enkephalin-derived chemicals first."))
		return

	// Check minimum amount
	if(reagents.total_volume < CHEM_QUANTITY_MIN)
		to_chat(user, span_warning("Not enough reagent! Need at least [CHEM_QUANTITY_MIN]u."))
		return

	// Get the primary reagent
	var/datum/reagent/primary_reagent = reagents.reagent_list[1]
	var/list/chem_data = GetMovementFromChem(primary_reagent)

	if(!chem_data)
		to_chat(user, span_warning("[primary_reagent.name] is not a valid navigation chemical!"))
		return

	// Create the navigation core
	var/movement_type = chem_data[1]
	var/bypasses_quantity = chem_data[2]
	var/sin_type = chem_data[3]
	var/quantity_mod = GetQuantityModifier(reagents.total_volume, bypasses_quantity)

	var/obj/item/navigation_core/new_core = new(get_turf(src))
	new_core.nav_movement_type = movement_type
	new_core.sin_type = sin_type
	new_core.grade = grade
	new_core.min_distance = min_distance
	new_core.max_distance = max_distance
	new_core.max_tier = max_tier
	new_core.quantity_modifier = quantity_mod
	new_core.bypasses_quantity = bypasses_quantity
	new_core.UpdateAppearance()

	to_chat(user, span_notice("You finalize the template into a [new_core.name]."))
	playsound(src, 'sound/machines/click.ogg', 30, TRUE)

	user.put_in_hands(new_core)
	qdel(src)

// ===== Grade Subtypes =====

/obj/item/reagent_containers/core_template/basic
	name = "basic navigation core template"
	grade = TEMPLATE_GRADE_BASIC
	cost = TEMPLATE_COST_BASIC
	min_distance = TEMPLATE_DIST_BASIC_MIN
	max_distance = TEMPLATE_DIST_BASIC_MAX
	max_tier = TEMPLATE_MAX_TIER_BASIC

/obj/item/reagent_containers/core_template/standard
	name = "standard navigation core template"
	grade = TEMPLATE_GRADE_STANDARD
	cost = TEMPLATE_COST_STANDARD
	min_distance = TEMPLATE_DIST_STANDARD_MIN
	max_distance = TEMPLATE_DIST_STANDARD_MAX
	max_tier = TEMPLATE_MAX_TIER_STANDARD

/obj/item/reagent_containers/core_template/quality
	name = "quality navigation core template"
	grade = TEMPLATE_GRADE_QUALITY
	cost = TEMPLATE_COST_QUALITY
	min_distance = TEMPLATE_DIST_QUALITY_MIN
	max_distance = TEMPLATE_DIST_QUALITY_MAX
	max_tier = TEMPLATE_MAX_TIER_QUALITY

/obj/item/reagent_containers/core_template/superior
	name = "superior navigation core template"
	grade = TEMPLATE_GRADE_SUPERIOR
	cost = TEMPLATE_COST_SUPERIOR
	min_distance = TEMPLATE_DIST_SUPERIOR_MIN
	max_distance = TEMPLATE_DIST_SUPERIOR_MAX
	max_tier = TEMPLATE_MAX_TIER_SUPERIOR
