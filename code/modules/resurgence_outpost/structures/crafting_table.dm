/**
 * Resurgence Outpost - Crafting Table
 *
 * Base workbench for crafting. Subtypes (forge, loom) override recipes and theming.
 * Uses an HTML browser window for recipe selection.
 */

/obj/structure/resurgence_crafting_table
	name = "crafting table"
	desc = "A sturdy workbench for crafting components and items."
	icon = 'icons/obj/cult.dmi'
	icon_state = "tomealtar"
	density = TRUE
	anchored = TRUE
	var/busy = FALSE

	/// List of available recipes - initialized per subtype
	var/list/recipes

	// UI Theming - override in subtypes
	/// Browser window ID
	var/browser_id = "crafting_table"
	/// Browser window title
	var/browser_title = "Crafting Table"
	/// Header color for CSS
	var/ui_header_color = "#8b7355"
	/// Recipe name color for CSS
	var/ui_recipe_color = "#c9a959"
	/// Craft button color for CSS
	var/ui_button_color = "#4a6741"
	/// Craft button hover color for CSS
	var/ui_button_hover = "#5a7751"
	/// Action verb (e.g., "Craft", "Smelt", "Weave")
	var/action_verb = "Craft"
	/// Busy message verb (e.g., "crafting", "smelting", "weaving")
	var/busy_verb = "crafting"
	/// Sound to play on completion
	var/complete_sound = 'sound/items/deconstruct.ogg'

/obj/structure/resurgence_crafting_table/Initialize(mapload)
	. = ..()
	if(!recipes)
		init_recipes()

/// Initialize the recipe list - override in subtypes
/obj/structure/resurgence_crafting_table/proc/init_recipes()
	recipes = list()

	// Basic Processing
	recipes["Metal Rods"] = list(
		"result" = /obj/item/stack/rods,
		"result_amount" = 2,
		"materials" = list(/obj/item/stack/sheet/metal = 1),
		"time" = 2 SECONDS,
		"desc" = "1 Metal -> 2 Metal Rods"
	)

	recipes["Rope"] = list(
		"result" = /obj/item/resurgence_component/rope,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 3),
		"time" = 2 SECONDS,
		"desc" = "3 Cloth -> 1 Rope"
	)

	recipes["Nails"] = list(
		"result" = /obj/item/stack/resurgence_nails,
		"result_amount" = 10,
		"materials" = list(/obj/item/stack/sheet/metal = 1),
		"time" = 2 SECONDS,
		"desc" = "1 Metal -> 10 Nails"
	)

	// Floor Tiles
	recipes["Wood Floor Tiles"] = list(
		"result" = /obj/item/stack/tile/wood,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/mineral/wood = 1),
		"time" = 2 SECONDS,
		"desc" = "1 Wood -> 4 Wood Floor Tiles"
	)

	recipes["Plasteel Floor Tiles"] = list(
		"result" = /obj/item/stack/tile/plasteel,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/plasteel = 1),
		"time" = 2 SECONDS,
		"desc" = "1 Plasteel -> 4 Plasteel Floor Tiles"
	)

	// Carpet Tiles
	recipes["Carpet Tiles"] = list(
		"result" = /obj/item/stack/tile/carpet,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"time" = 2 SECONDS,
		"desc" = "2 Cloth -> 4 Carpet Tiles"
	)

	recipes["Black Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/black,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"time" = 2 SECONDS,
		"desc" = "2 Cloth -> 4 Black Carpet"
	)

	recipes["Blue Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/blue,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"time" = 2 SECONDS,
		"desc" = "2 Cloth -> 4 Blue Carpet"
	)

	recipes["Cyan Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/cyan,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"time" = 2 SECONDS,
		"desc" = "2 Cloth -> 4 Cyan Carpet"
	)

	recipes["Green Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/green,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"time" = 2 SECONDS,
		"desc" = "2 Cloth -> 4 Green Carpet"
	)

	recipes["Orange Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/orange,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"time" = 2 SECONDS,
		"desc" = "2 Cloth -> 4 Orange Carpet"
	)

	recipes["Purple Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/purple,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"time" = 2 SECONDS,
		"desc" = "2 Cloth -> 4 Purple Carpet"
	)

	recipes["Red Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/red,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"time" = 2 SECONDS,
		"desc" = "2 Cloth -> 4 Red Carpet"
	)

	// Royal Carpets (require gold)
	recipes["Royal Black Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/royalblack,
		"result_amount" = 4,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 2,
			/obj/item/stack/sheet/mineral/gold = 1
		),
		"time" = 3 SECONDS,
		"desc" = "2 Cloth + 1 Gold -> 4 Royal Black Carpet"
	)

	recipes["Royal Blue Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/royalblue,
		"result_amount" = 4,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 2,
			/obj/item/stack/sheet/mineral/gold = 1
		),
		"time" = 3 SECONDS,
		"desc" = "2 Cloth + 1 Gold -> 4 Royal Blue Carpet"
	)

/obj/structure/resurgence_crafting_table/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	ui_interact(user)
	return TRUE

/obj/structure/resurgence_crafting_table/ui_interact(mob/user)
	. = ..()

	var/dat = "<head><style>"
	dat += "body { font-family: monospace; background-color: #1a1a1a; color: #e0e0e0; margin: 10px; }"
	dat += "h2 { color: [ui_header_color]; border-bottom: 2px solid [ui_header_color]; padding-bottom: 5px; }"
	dat += ".recipe { background-color: #2a2a2a; border: 1px solid #444; margin: 5px 0; padding: 8px; border-radius: 4px; }"
	dat += ".recipe:hover { background-color: #3a3a3a; }"
	dat += ".recipe-name { font-weight: bold; color: [ui_recipe_color]; font-size: 14px; }"
	dat += ".recipe-desc { color: #aaa; font-size: 12px; margin: 3px 0; }"
	dat += ".craft-btn { background-color: [ui_button_color]; color: white; border: none; padding: 5px 15px; cursor: pointer; border-radius: 3px; }"
	dat += ".craft-btn:hover { background-color: [ui_button_hover]; }"
	dat += ".craft-btn-disabled { background-color: #555; color: #888; }"
	dat += ".status { color: #888; font-size: 11px; }"
	dat += ".can-craft { color: #6a6; }"
	dat += ".cannot-craft { color: #a66; }"
	dat += "</style></head><body>"

	dat += "<h2>[browser_title]</h2>"

	if(busy)
		dat += "<p><b>Currently [busy_verb]...</b></p>"
	else
		dat += "<p>Select a recipe to craft:</p>"

	dat += "<hr>"

	for(var/recipe_name in recipes)
		var/list/recipe = recipes[recipe_name]
		var/list/materials = recipe["materials"]
		var/can_craft = check_materials(user, materials)

		dat += "<div class='recipe'>"
		dat += "<span class='recipe-name'>[recipe_name]</span>"
		if(recipe["result_amount"] > 1)
			dat += " (x[recipe["result_amount"]])"
		dat += "<br>"
		dat += "<span class='recipe-desc'>[recipe["desc"]]</span><br>"

		// Show material availability
		dat += "<span class='status'>"
		for(var/mat_type in materials)
			var/needed = materials[mat_type]
			var/have = count_materials(user, mat_type)
			var/mat_name = get_material_name(mat_type)
			if(have >= needed)
				dat += "<span class='can-craft'>[mat_name]: [have]/[needed]</span> "
			else
				dat += "<span class='cannot-craft'>[mat_name]: [have]/[needed]</span> "
		dat += "</span><br>"

		if(can_craft && !busy)
			dat += "<a class='craft-btn' href='byond://?src=[REF(src)];craft=[url_encode(recipe_name)]'>[action_verb]</a>"
		else if(busy)
			dat += "<span class='craft-btn craft-btn-disabled'>Busy...</span>"
		else
			dat += "<span class='craft-btn craft-btn-disabled'>Missing Materials</span>"

		dat += "</div>"

	dat += "</body>"

	var/datum/browser/popup = new(user, browser_id, browser_title, 450, 550)
	popup.set_content(dat)
	popup.open()

/obj/structure/resurgence_crafting_table/Topic(href, href_list)
	. = ..()
	if(.)
		return .

	if(!ishuman(usr))
		return

	if(!in_range(src, usr))
		to_chat(usr, span_warning("You are too far away from the [name]."))
		return

	if(href_list["craft"])
		var/recipe_name = href_list["craft"]
		try_craft(usr, recipe_name)
		// Refresh the UI after crafting attempt
		ui_interact(usr)
		return TRUE

/// Count how many of a material type the user has available
/obj/structure/resurgence_crafting_table/proc/count_materials(mob/living/carbon/human/user, material_type)
	if(!istype(user))
		return 0

	var/found = 0

	// Check hands
	for(var/obj/item/I in user.held_items)
		if(istype(I, material_type))
			if(istype(I, /obj/item/stack))
				var/obj/item/stack/S = I
				found += S.amount
			else
				found += 1

	// Check backpack/storage
	var/obj/item/storage/backpack = user.get_item_by_slot(ITEM_SLOT_BACK)
	if(istype(backpack))
		for(var/obj/item/I in backpack.contents)
			if(istype(I, material_type))
				if(istype(I, /obj/item/stack))
					var/obj/item/stack/S = I
					found += S.amount
				else
					found += 1

	// Check nearby closed closets/crates (contents are accessible when closed)
	for(var/obj/structure/closet/C in range(1, src))
		if(!C.opened)
			for(var/obj/item/I in C.contents)
				if(istype(I, material_type))
					if(istype(I, /obj/item/stack))
						var/obj/item/stack/S = I
						found += S.amount
					else
						found += 1

	return found

/// Get a readable name for a material type
/obj/structure/resurgence_crafting_table/proc/get_material_name(material_type)
	switch(material_type)
		// Basic sheets
		if(/obj/item/stack/sheet/mineral/wood)
			return "Wood"
		if(/obj/item/stack/sheet/metal)
			return "Metal"
		if(/obj/item/stack/sheet/glass)
			return "Glass"
		if(/obj/item/stack/sheet/plasteel)
			return "Plasteel"
		if(/obj/item/stack/sheet/leather)
			return "Leather"
		if(/obj/item/stack/sheet/cotton/cloth)
			return "Cloth"
		if(/obj/item/stack/rods)
			return "Metal Rods"
		// Ores
		if(/obj/item/stack/ore/iron)
			return "Iron Ore"
		if(/obj/item/stack/ore/ironscrap)
			return "Iron Scrap"
		if(/obj/item/stack/ore/glass)
			return "Sand"
		if(/obj/item/stack/ore/glassrubble)
			return "Glass Rubble"
		if(/obj/item/stack/ore/silver)
			return "Silver Ore"
		if(/obj/item/stack/ore/gold)
			return "Gold Ore"
		// Raw materials
		if(/obj/item/stack/sheet/cotton)
			return "Cotton"
		if(/obj/item/stack/sheet/animalhide/generic)
			return "Animal Hide"
		if(/obj/item/stack/sheet/hairlesshide)
			return "Hairless Hide"
		if(/obj/item/stack/sheet/wethide)
			return "Wet Hide"
		// Resurgence components
		if(/obj/item/resurgence_component/rope)
			return "Rope"
		if(/obj/item/stack/resurgence_nails)
			return "Nails"
		else
			// Fallback: get the name from the type
			var/obj/item/temp = material_type
			return initial(temp.name)

/// Attempt to craft the selected recipe
/obj/structure/resurgence_crafting_table/proc/try_craft(mob/user, recipe_name)
	if(busy)
		to_chat(user, span_warning("The [name] is currently in use."))
		return FALSE

	var/list/recipe = recipes[recipe_name]
	if(!recipe)
		return FALSE

	var/list/materials = recipe["materials"]

	// Check if user has required materials
	if(!check_materials(user, materials))
		to_chat(user, span_warning("You don't have the required materials for [recipe_name]."))
		return FALSE

	// Start crafting
	busy = TRUE
	to_chat(user, span_notice("You begin [busy_verb]..."))

	var/craft_time = get_craft_time(recipe["time"])

	if(!do_after(user, craft_time, target = src))
		to_chat(user, span_warning("You stop [busy_verb]."))
		busy = FALSE
		return FALSE

	// Re-check materials after do_after (they may have been moved)
	if(!check_materials(user, materials))
		to_chat(user, span_warning("You no longer have the required materials."))
		busy = FALSE
		return FALSE

	// Consume materials and create result
	consume_materials(user, materials)
	create_result(user, recipe)

	to_chat(user, span_notice("You craft [recipe_name]."))
	playsound(src, complete_sound, 50, TRUE)

	busy = FALSE
	return TRUE

/// Check if the user has all required materials
/obj/structure/resurgence_crafting_table/proc/check_materials(mob/living/carbon/human/user, list/materials)
	if(!istype(user))
		return FALSE

	for(var/material_type in materials)
		var/needed = materials[material_type]
		var/found = count_materials(user, material_type)

		if(found < needed)
			return FALSE

	return TRUE

/// Consume the required materials from the user
/obj/structure/resurgence_crafting_table/proc/consume_materials(mob/living/carbon/human/user, list/materials)
	if(!istype(user))
		return

	for(var/material_type in materials)
		var/needed = materials[material_type]

		// Consume from hands first
		for(var/obj/item/I in user.held_items)
			if(needed <= 0)
				break
			if(istype(I, material_type))
				if(istype(I, /obj/item/stack))
					var/obj/item/stack/S = I
					var/to_use = min(S.amount, needed)
					S.use(to_use)
					needed -= to_use
				else
					qdel(I)
					needed -= 1

		// Then consume from backpack
		var/obj/item/storage/backpack = user.get_item_by_slot(ITEM_SLOT_BACK)
		if(needed > 0 && istype(backpack))
			for(var/obj/item/I in backpack.contents)
				if(needed <= 0)
					break
				if(istype(I, material_type))
					if(istype(I, /obj/item/stack))
						var/obj/item/stack/S = I
						var/to_use = min(S.amount, needed)
						S.use(to_use)
						needed -= to_use
					else
						qdel(I)
						needed -= 1

		// Finally consume from nearby closed closets/crates
		if(needed > 0)
			for(var/obj/structure/closet/C in range(1, src))
				if(needed <= 0)
					break
				if(!C.opened) // Only consume from closed closets
					for(var/obj/item/I in C.contents)
						if(needed <= 0)
							break
						if(istype(I, material_type))
							if(istype(I, /obj/item/stack))
								var/obj/item/stack/S = I
								var/to_use = min(S.amount, needed)
								S.use(to_use)
								needed -= to_use
							else
								qdel(I)
								needed -= 1

/// Create the crafted result
/obj/structure/resurgence_crafting_table/proc/create_result(mob/user, list/recipe)
	var/result_type = recipe["result"]
	var/result_amount = recipe["result_amount"]

	if(ispath(result_type, /obj/item/stack))
		// Create a stack with the correct amount
		new result_type(get_turf(src), result_amount)
	else
		// Create individual items
		for(var/i in 1 to result_amount)
			new result_type(get_turf(src))

/// Get the crafting time, potentially modified by room bonuses
/obj/structure/resurgence_crafting_table/proc/get_craft_time(base_time)
	// TODO: Check if in workshop room for speed bonus
	// For now, return base time
	return base_time

/obj/structure/resurgence_crafting_table/examine(mob/user)
	. = ..()
	. += span_notice("Click to open the crafting menu.")
