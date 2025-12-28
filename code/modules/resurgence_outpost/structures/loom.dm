/**
 * Resurgence Outpost - Loom
 *
 * A weaving station for processing plant fibers into cloth and crafting textile components.
 * Also crafts faith-boosting outfits from cloth.
 * Subtype of crafting_table with different recipes and theming.
 */

/obj/structure/resurgence_crafting_table/loom
	name = "loom"
	desc = "A wooden loom for weaving fibers into cloth and crafting garments."
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "loom"

	// UI Theming - purple/blue for cloth
	browser_id = "loom"
	browser_title = "Loom"
	ui_header_color = "#6b5b95"
	ui_recipe_color = "#9370db"
	ui_button_color = "#483d8b"
	ui_button_hover = "#6a5acd"
	action_verb = "Weave"
	busy_verb = "weaving"

/obj/structure/resurgence_crafting_table/loom/init_recipes()
	recipes = list()

	// === MATERIALS ===

	// Fiber Processing
	recipes["Cloth"] = list(
		"result" = /obj/item/stack/sheet/cotton/cloth,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton = 3),
		"time" = 3 SECONDS,
		"desc" = "3 Cotton -> 1 Cloth"
	)

	// === OUTFITS (Body) ===

	recipes["White Robe"] = list(
		"result" = /obj/item/clothing/suit/chaplainsuit/whiterobe,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 8),
		"time" = 6 SECONDS,
		"desc" = "8 Cloth -> White Robe (+3 faith)",
		"faith_bonus" = 3
	)

	recipes["Monk's Habit"] = list(
		"result" = /obj/item/clothing/suit/hooded/chaplainsuit/monkhabit,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 10),
		"time" = 8 SECONDS,
		"desc" = "10 Cloth -> Monk's Habit (+4 faith)",
		"faith_bonus" = 4
	)

	recipes["Owl Cloak"] = list(
		"result" = /obj/item/clothing/suit/toggle/owlwings,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 12),
		"time" = 10 SECONDS,
		"desc" = "12 Cloth -> Owl Cloak (+5 faith)",
		"faith_bonus" = 5
	)

	recipes["Hastur's Robe"] = list(
		"result" = /obj/item/clothing/suit/hastur,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 20,
			/obj/item/resurgence_component/rope = 2
		),
		"time" = 12 SECONDS,
		"desc" = "20 Cloth + 2 Rope -> Hastur's Robe (+8 faith)",
		"faith_bonus" = 8
	)

	recipes["Bishop's Robes"] = list(
		"result" = /obj/item/clothing/suit/chaplainsuit/bishoprobe,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 30,
			/obj/item/resurgence_component/rope = 4
		),
		"time" = 15 SECONDS,
		"desc" = "30 Cloth + 4 Rope -> Bishop's Robes (+10 faith)",
		"faith_bonus" = 10
	)

	// === OUTFITS (Head) ===

	recipes["Nun Hood"] = list(
		"result" = /obj/item/clothing/head/nun_hood,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 4),
		"time" = 3 SECONDS,
		"desc" = "4 Cloth -> Nun Hood (+2 faith)",
		"faith_bonus" = 2
	)

	recipes["Ushanka"] = list(
		"result" = /obj/item/clothing/head/ushanka,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 5),
		"time" = 4 SECONDS,
		"desc" = "5 Cloth -> Ushanka (+2 faith)",
		"faith_bonus" = 2
	)

	// === OUTFITS (Accessories) ===

	recipes["Scarf"] = list(
		"result" = /obj/item/clothing/neck/scarf,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 3),
		"time" = 2 SECONDS,
		"desc" = "3 Cloth -> Scarf (+1 faith)",
		"faith_bonus" = 1
	)

	recipes["Black Gloves"] = list(
		"result" = /obj/item/clothing/gloves/color/black,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 3),
		"time" = 2 SECONDS,
		"desc" = "3 Cloth -> Black Gloves (+1 faith)",
		"faith_bonus" = 1
	)

/// Override create_result to handle faith clothing
/obj/structure/resurgence_crafting_table/loom/create_result(mob/user, list/recipe)
	var/result_type = recipe["result"]
	var/result_amount = recipe["result_amount"]
	var/faith_bonus = recipe["faith_bonus"]

	if(ispath(result_type, /obj/item/stack))
		// Create a stack with the correct amount (no faith bonus for stacks)
		new result_type(get_turf(src), result_amount)
	else if(ispath(result_type, /obj/item/clothing) && faith_bonus)
		// Create clothing with faith bonus component
		for(var/i in 1 to result_amount)
			var/obj/item/clothing/C = new result_type(get_turf(src))
			// Rename to indicate clan crafting
			C.name = "clan-woven [C.name]"
			C.desc += " This garment was lovingly crafted by the Resurgence Clan."
			// Add faith bonus component
			C.AddComponent(/datum/component/faith_clothing, faith_bonus)
	else
		// Create individual items (components, etc.)
		for(var/i in 1 to result_amount)
			new result_type(get_turf(src))
