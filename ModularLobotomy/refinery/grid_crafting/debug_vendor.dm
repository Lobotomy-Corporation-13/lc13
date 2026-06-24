/**
 * Grid Crafting System - Debug Vendor
 *
 * Admin/debug machine that spawns navigation cores with any settings.
 * Bypasses the normal template + chem crafting process.
 */

/obj/structure/grid_debug_vendor
	name = "navigation core debug vendor"
	desc = "A debug machine for spawning navigation cores with custom settings."
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "mining"
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE

/obj/structure/grid_debug_vendor/Initialize(mapload)
	. = ..()
	GLOB.lobotomy_devices += src

/obj/structure/grid_debug_vendor/Destroy()
	GLOB.lobotomy_devices -= src
	return ..()

/obj/structure/grid_debug_vendor/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	ui_interact(user)
	return TRUE

/obj/structure/grid_debug_vendor/examine(mob/user)
	. = ..()
	. += span_notice("Click to open the debug core spawner.")
	. += span_boldwarning("DEBUG TOOL - Creates free navigation cores.")

// ===== TGUI Interface =====

/obj/structure/grid_debug_vendor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "GridDebugVendor", name)
		ui.open()

/obj/structure/grid_debug_vendor/ui_static_data(mob/user)
	var/list/data = list()

	// Movement types
	data["movement_types"] = list(
		list("id" = CORE_MOVEMENT_CHARGE, "name" = "Charge (Wrath)"),
		list("id" = CORE_MOVEMENT_ATTRACT, "name" = "Attract (Lust)"),
		list("id" = CORE_MOVEMENT_SHUFFLE, "name" = "Shuffle (Sloth)"),
		list("id" = CORE_MOVEMENT_EXPAND, "name" = "Expand (Gluttony)"),
		list("id" = CORE_MOVEMENT_DRIFT, "name" = "Drift (Gloom)"),
		list("id" = CORE_MOVEMENT_TELEPORT, "name" = "Teleport (Pride)"),
		list("id" = CORE_MOVEMENT_MIRROR, "name" = "Mirror (Envy)")
	)

	// Grades
	data["grades"] = list(
		list(
			"id" = TEMPLATE_GRADE_BASIC,
			"name" = "Basic",
			"min_dist" = TEMPLATE_DIST_BASIC_MIN,
			"max_dist" = TEMPLATE_DIST_BASIC_MAX,
			"max_tier" = TEMPLATE_MAX_TIER_BASIC
		),
		list(
			"id" = TEMPLATE_GRADE_STANDARD,
			"name" = "Standard",
			"min_dist" = TEMPLATE_DIST_STANDARD_MIN,
			"max_dist" = TEMPLATE_DIST_STANDARD_MAX,
			"max_tier" = TEMPLATE_MAX_TIER_STANDARD
		),
		list(
			"id" = TEMPLATE_GRADE_QUALITY,
			"name" = "Quality",
			"min_dist" = TEMPLATE_DIST_QUALITY_MIN,
			"max_dist" = TEMPLATE_DIST_QUALITY_MAX,
			"max_tier" = TEMPLATE_MAX_TIER_QUALITY
		),
		list(
			"id" = TEMPLATE_GRADE_SUPERIOR,
			"name" = "Superior",
			"min_dist" = TEMPLATE_DIST_SUPERIOR_MIN,
			"max_dist" = TEMPLATE_DIST_SUPERIOR_MAX,
			"max_tier" = TEMPLATE_MAX_TIER_SUPERIOR
		)
	)

	return data

/obj/structure/grid_debug_vendor/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("spawn_core")
			var/movement_type = text2num(params["movement_type"]) || 1
			var/grade = text2num(params["grade"]) || 1
			var/quantity_mod = text2num(params["quantity_mod"]) || 1.0
			var/bypasses = text2num(params["bypasses"]) || 0

			// Validate
			movement_type = clamp(movement_type, 1, 7)
			grade = clamp(grade, 1, 4)
			quantity_mod = clamp(quantity_mod, 0.5, 1.5)

			// Create core
			var/obj/item/navigation_core/core = new(get_turf(src))
			core.nav_movement_type = movement_type
			core.sin_type = movement_type
			core.grade = grade
			core.quantity_modifier = quantity_mod
			core.bypasses_quantity = bypasses ? TRUE : FALSE

			// Set distance based on grade
			switch(grade)
				if(TEMPLATE_GRADE_BASIC)
					core.min_distance = TEMPLATE_DIST_BASIC_MIN
					core.max_distance = TEMPLATE_DIST_BASIC_MAX
					core.max_tier = TEMPLATE_MAX_TIER_BASIC
				if(TEMPLATE_GRADE_STANDARD)
					core.min_distance = TEMPLATE_DIST_STANDARD_MIN
					core.max_distance = TEMPLATE_DIST_STANDARD_MAX
					core.max_tier = TEMPLATE_MAX_TIER_STANDARD
				if(TEMPLATE_GRADE_QUALITY)
					core.min_distance = TEMPLATE_DIST_QUALITY_MIN
					core.max_distance = TEMPLATE_DIST_QUALITY_MAX
					core.max_tier = TEMPLATE_MAX_TIER_QUALITY
				if(TEMPLATE_GRADE_SUPERIOR)
					core.min_distance = TEMPLATE_DIST_SUPERIOR_MIN
					core.max_distance = TEMPLATE_DIST_SUPERIOR_MAX
					core.max_tier = TEMPLATE_MAX_TIER_SUPERIOR

			core.UpdateAppearance()
			usr.put_in_hands(core)

			to_chat(usr, span_notice("Spawned: [core.name]"))
			playsound(src, 'sound/machines/click.ogg', 30, TRUE)
			return TRUE

		if("spawn_template")
			var/grade = text2num(params["grade"]) || 1
			grade = clamp(grade, 1, 4)

			var/template_type
			switch(grade)
				if(TEMPLATE_GRADE_BASIC)
					template_type = /obj/item/reagent_containers/core_template/basic
				if(TEMPLATE_GRADE_STANDARD)
					template_type = /obj/item/reagent_containers/core_template/standard
				if(TEMPLATE_GRADE_QUALITY)
					template_type = /obj/item/reagent_containers/core_template/quality
				if(TEMPLATE_GRADE_SUPERIOR)
					template_type = /obj/item/reagent_containers/core_template/superior

			var/obj/item/reagent_containers/core_template/template = new template_type(get_turf(src))
			usr.put_in_hands(template)

			to_chat(usr, span_notice("Spawned: [template.name]"))
			playsound(src, 'sound/machines/click.ogg', 30, TRUE)
			return TRUE

	return FALSE
