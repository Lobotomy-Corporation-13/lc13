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

	// UI Theming
	action_verb = "Weave"
	busy_verb = "weaving"
	ui_color = "purple"

/obj/structure/resurgence_crafting_table/loom/init_recipes()
	recipes = list()

	// === MATERIALS ===

	// Fiber Processing
	recipes["Cloth"] = list(
		"result" = /obj/item/stack/sheet/cotton/cloth,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton = 3),
		"total_work" = 15,
		"desc" = "3 Cotton -> 1 Cloth"
	)

	// === OUTFITS (Body) ===

	recipes["White Robe"] = list(
		"result" = /obj/item/clothing/suit/chaplainsuit/whiterobe,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 8),
		"total_work" = 30,
		"desc" = "8 Cloth -> White Robe (+0.3 faith)",
		"faith_bonus" = 0.3
	)

	recipes["Monk's Habit"] = list(
		"result" = /obj/item/clothing/suit/hooded/chaplainsuit/monkhabit,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 10),
		"total_work" = 40,
		"desc" = "10 Cloth -> Monk's Habit (+0.4 faith)",
		"faith_bonus" = 0.4
	)

	recipes["Owl Cloak"] = list(
		"result" = /obj/item/clothing/suit/toggle/owlwings,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 12),
		"total_work" = 50,
		"desc" = "12 Cloth -> Owl Cloak (+0.5 faith)",
		"faith_bonus" = 0.5
	)

	recipes["Hastur's Robe"] = list(
		"result" = /obj/item/clothing/suit/hastur,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 20,
			/obj/item/resurgence_component/rope = 2
		),
		"total_work" = 60,
		"desc" = "20 Cloth + 2 Rope -> Hastur's Robe (+0.8 faith)",
		"faith_bonus" = 0.8
	)

	recipes["Bishop's Robes"] = list(
		"result" = /obj/item/clothing/suit/chaplainsuit/bishoprobe,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 30,
			/obj/item/resurgence_component/rope = 4
		),
		"total_work" = 90,
		"desc" = "30 Cloth + 4 Rope -> Bishop's Robes (+1 faith)",
		"faith_bonus" = 1
	)

	// === OUTFITS (Head) ===

	recipes["Nun Hood"] = list(
		"result" = /obj/item/clothing/head/nun_hood,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 4),
		"total_work" = 15,
		"desc" = "4 Cloth -> Nun Hood (+0.2 faith)",
		"faith_bonus" = 0.2
	)

	recipes["Ushanka"] = list(
		"result" = /obj/item/clothing/head/ushanka,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 5),
		"total_work" = 20,
		"desc" = "5 Cloth -> Ushanka (+0.2 faith)",
		"faith_bonus" = 0.2
	)

	// === OUTFITS (Accessories) ===

	recipes["Scarf"] = list(
		"result" = /obj/item/clothing/neck/scarf,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 3),
		"total_work" = 10,
		"desc" = "3 Cloth -> Scarf (+0.1 faith)",
		"faith_bonus" = 0.1
	)

	recipes["Black Gloves"] = list(
		"result" = /obj/item/clothing/gloves/color/black,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 3),
		"total_work" = 10,
		"desc" = "3 Cloth -> Black Gloves (+0.1 faith)",
		"faith_bonus" = 0.1
	)

	// === STORAGE (Backpacks) ===

	recipes["Backpack"] = list(
		"result" = /obj/item/storage/backpack,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 8),
		"total_work" = 25,
		"desc" = "8 Cloth -> Backpack"
	)

	recipes["Explorer Backpack"] = list(
		"result" = /obj/item/storage/backpack/explorer,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 10,
			/obj/item/stack/sheet/leather = 2
		),
		"total_work" = 30,
		"desc" = "10 Cloth + 2 Leather -> Explorer Backpack"
	)

	recipes["Satchel"] = list(
		"result" = /obj/item/storage/backpack/satchel,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 6),
		"total_work" = 20,
		"desc" = "6 Cloth -> Satchel"
	)

	recipes["Leather Satchel"] = list(
		"result" = /obj/item/storage/backpack/satchel/leather,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/leather = 5),
		"total_work" = 25,
		"desc" = "5 Leather -> Leather Satchel"
	)

	recipes["Duffel Bag"] = list(
		"result" = /obj/item/storage/backpack/duffelbag,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 12,
			/obj/item/resurgence_component/rope = 1
		),
		"total_work" = 35,
		"desc" = "12 Cloth + 1 Rope -> Duffel Bag"
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

// ===== Portable Loom =====
// Does not require a workshop - works at full speed anywhere

/obj/structure/resurgence_crafting_table/loom/portable
	name = "portable loom"
	desc = "A compact loom that can be used anywhere. Less efficient than a proper workshop station, but functional outdoors."
	requires_workshop = FALSE
