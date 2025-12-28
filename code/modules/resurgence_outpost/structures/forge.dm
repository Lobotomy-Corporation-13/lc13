/**
 * Resurgence Outpost - Forge
 *
 * A metalworking station for smelting ore into sheets.
 * Subtype of crafting_table with different recipes and theming.
 */

/obj/structure/resurgence_crafting_table/forge
	name = "forge"
	desc = "A hot forge for smelting ore and crafting metal components."
	icon_state = "yourclockwork" // Placeholder

	// UI Theming - orange/red for forge
	browser_id = "forge"
	browser_title = "Forge"
	ui_header_color = "#b5651d"
	ui_recipe_color = "#e07020"
	ui_button_color = "#8b4513"
	ui_button_hover = "#a0522d"
	action_verb = "Smelt"
	busy_verb = "smelting"
	complete_sound = 'sound/items/welder.ogg'

/obj/structure/resurgence_crafting_table/forge/init_recipes()
	recipes = list()

	// Smelting Recipes - Ores to Sheets
	recipes["Metal Sheet"] = list(
		"result" = /obj/item/stack/sheet/metal,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/iron = 2),
		"time" = 3 SECONDS,
		"desc" = "2 Iron Ore -> 1 Metal Sheet"
	)

	recipes["Metal Sheet (Scrap)"] = list(
		"result" = /obj/item/stack/sheet/metal,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/ironscrap = 3),
		"time" = 4 SECONDS,
		"desc" = "3 Iron Scrap -> 1 Metal Sheet"
	)

	recipes["Glass Sheet"] = list(
		"result" = /obj/item/stack/sheet/glass,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/glass = 2),
		"time" = 3 SECONDS,
		"desc" = "2 Sand -> 1 Glass Sheet"
	)

	recipes["Glass Sheet (Rubble)"] = list(
		"result" = /obj/item/stack/sheet/glass,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/glassrubble = 3),
		"time" = 4 SECONDS,
		"desc" = "3 Glass Rubble -> 1 Glass Sheet"
	)

	// Precious metal smelting
	recipes["Silver Sheet"] = list(
		"result" = /obj/item/stack/sheet/mineral/silver,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/silver = 2),
		"time" = 4 SECONDS,
		"desc" = "2 Silver Ore -> 1 Silver Sheet"
	)

	recipes["Gold Sheet"] = list(
		"result" = /obj/item/stack/sheet/mineral/gold,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/gold = 2),
		"time" = 4 SECONDS,
		"desc" = "2 Gold Ore -> 1 Gold Sheet"
	)

	// Plasteel crafting (requires metal + special)
	recipes["Plasteel"] = list(
		"result" = /obj/item/stack/sheet/plasteel,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 2,
			/obj/item/stack/sheet/mineral/coal = 1
		),
		"time" = 6 SECONDS,
		"desc" = "2 Metal + 1 Coal -> 1 Plasteel"
	)
