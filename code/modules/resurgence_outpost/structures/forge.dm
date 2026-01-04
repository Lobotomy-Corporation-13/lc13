/**
 * Resurgence Outpost - Forge
 *
 * A metalworking station for smelting ore into sheets.
 * Subtype of crafting_table with different recipes and theming.
 */

/obj/structure/resurgence_crafting_table/forge
	name = "forge"
	desc = "A hot forge for smelting ore and crafting metal components."
	icon_state = "forge_off"

	// UI Theming
	action_verb = "Smelt"
	busy_verb = "smelting"
	complete_sound = 'sound/items/welder.ogg'
	ui_color = "orange"

/// Light up the forge when crafting starts
/obj/structure/resurgence_crafting_table/forge/on_craft_start()
	icon_state = "forge"

/// Dim the forge when crafting stops
/obj/structure/resurgence_crafting_table/forge/on_craft_stop()
	// Only turn off if nothing in progress
	if(!current_recipe_name)
		icon_state = "forge_off"

/obj/structure/resurgence_crafting_table/forge/init_recipes()
	recipes = list()

	// Smelting Recipes - Ores to Sheets
	recipes["Metal Sheet"] = list(
		"result" = /obj/item/stack/sheet/metal,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/iron = 2),
		"total_work" = 5,
		"desc" = "2 Iron Ore -> 1 Metal Sheet"
	)

	recipes["Metal Sheet (Scrap)"] = list(
		"result" = /obj/item/stack/sheet/metal,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/ironscrap = 3),
		"total_work" = 5,
		"desc" = "3 Iron Scrap -> 1 Metal Sheet"
	)

	recipes["Glass Sheet"] = list(
		"result" = /obj/item/stack/sheet/glass,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/glass = 2),
		"total_work" = 5,
		"desc" = "2 Sand -> 1 Glass Sheet"
	)

	recipes["Glass Sheet (Rubble)"] = list(
		"result" = /obj/item/stack/sheet/glass,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/glassrubble = 3),
		"total_work" = 5,
		"desc" = "3 Glass Rubble -> 1 Glass Sheet"
	)

	// Precious metal smelting
	recipes["Silver Sheet"] = list(
		"result" = /obj/item/stack/sheet/mineral/silver,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/silver = 2),
		"total_work" = 5,
		"desc" = "2 Silver Ore -> 1 Silver Sheet"
	)

	recipes["Gold Sheet"] = list(
		"result" = /obj/item/stack/sheet/mineral/gold,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/gold = 2),
		"total_work" = 5,
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
		"total_work" = 30,
		"desc" = "2 Metal + 1 Coal -> 1 Plasteel",
		"research_required" = "advanced_metallurgy"
	)

	// Sandstone from sand
	recipes["Sandstone"] = list(
		"result" = /obj/item/stack/sheet/mineral/sandstone,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/glass = 1),
		"total_work" = 5,
		"desc" = "1 Sand -> 1 Sandstone"
	)

	// Iron from rock (inefficient but possible)
	recipes["Iron Ore (Rock)"] = list(
		"result" = /obj/item/stack/ore/iron,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/rock = 25),
		"total_work" = 10,
		"desc" = "25 Rock -> 1 Iron Ore"
	)

	// Advanced Components
	recipes["Ash Plating"] = list(
		"result" = /obj/item/resurgence_component/ash_plating,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 10,
			/obj/item/stack/sheet/mineral/coal = 20
		),
		"total_work" = 200,
		"desc" = "10 Metal + 20 Coal -> Ash Plating (used for advanced tools)",
		"research_required" = "advanced_metallurgy"
	)

	// Metal Tools
	recipes["Iron Hatchet"] = list(
		"result" = /obj/item/hatchet,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 4,
			/obj/item/resurgence_component/rope = 1
		),
		"total_work" = 20,
		"desc" = "4 Metal + 1 Rope -> Iron Hatchet",
		"research_required" = "metallurgy"
	)

	recipes["Pickaxe"] = list(
		"result" = /obj/item/pickaxe,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 4,
			/obj/item/stack/sheet/mineral/wood = 2,
			/obj/item/resurgence_component/rope = 1
		),
		"total_work" = 20,
		"desc" = "4 Metal + 2 Wood + 1 Rope -> Pickaxe",
		"research_required" = "metallurgy"
	)

	recipes["Compact Pickaxe"] = list(
		"result" = /obj/item/pickaxe/mini,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 2,
			/obj/item/stack/sheet/mineral/wood = 1,
			/obj/item/resurgence_component/rope = 4
		),
		"total_work" = 25,
		"desc" = "2 Metal + 1 Wood + 4 Rope -> Compact Pickaxe (portable)",
		"research_required" = "metallurgy"
	)

	recipes["Silver Pickaxe"] = list(
		"result" = /obj/item/pickaxe/silver,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 5,
			/obj/item/stack/sheet/mineral/silver = 5,
			/obj/item/stack/sheet/mineral/wood = 2,
			/obj/item/resurgence_component/rope = 2
		),
		"total_work" = 40,
		"desc" = "5 Metal + 5 Silver + 2 Wood + 2 Rope -> Silver Pickaxe (fast mining)",
		"research_required" = "advanced_metallurgy"
	)

	recipes["Shovel"] = list(
		"result" = /obj/item/shovel,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3,
			/obj/item/stack/sheet/mineral/wood = 1
		),
		"total_work" = 20,
		"desc" = "3 Metal + 1 Wood -> Shovel",
		"research_required" = "metallurgy"
	)

	recipes["Scythe"] = list(
		"result" = /obj/item/scythe,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 6,
			/obj/item/stack/sheet/mineral/wood = 4,
			/obj/item/resurgence_component/rope = 2
		),
		"total_work" = 25,
		"desc" = "6 Metal + 4 Wood + 2 Rope -> Scythe (+5 work/tick when harvesting)",
		"research_required" = "metallurgy"
	)

	recipes["Crowbar"] = list(
		"result" = /obj/item/crowbar/large,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3,
			/obj/item/stack/sheet/mineral/wood = 1
		),
		"total_work" = 15,
		"desc" = "3 Metal + 1 Wood -> Crowbar",
		"research_required" = "metallurgy"
	)

	recipes["Compact Crowbar"] = list(
		"result" = /obj/item/crowbar,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 4,
			/obj/item/resurgence_component/rope = 2
		),
		"total_work" = 20,
		"desc" = "4 Metal + 2 Rope -> Compact Crowbar (portable)",
		"research_required" = "metallurgy"
	)

	// Kitchen Tools
	recipes["Beaker"] = list(
		"result" = /obj/item/reagent_containers/glass/beaker,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/glass = 10),
		"total_work" = 15,
		"desc" = "10 Sand -> Beaker",
		"research_required" = "culinary"
	)

	recipes["Large Beaker"] = list(
		"result" = /obj/item/reagent_containers/glass/beaker/large,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/glass = 20),
		"total_work" = 20,
		"desc" = "20 Sand -> Large Beaker",
		"research_required" = "culinary"
	)

	recipes["Bowl"] = list(
		"result" = /obj/item/reagent_containers/glass/bowl,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/metal = 3),
		"total_work" = 15,
		"desc" = "3 Metal -> Bowl",
		"research_required" = "culinary"
	)

	recipes["Kitchen Knife"] = list(
		"result" = /obj/item/kitchen/knife,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/metal = 2),
		"total_work" = 20,
		"desc" = "2 Metal -> Kitchen Knife",
		"research_required" = "culinary"
	)

	// Advanced Tools
	recipes["Advanced Harvester"] = list(
		"result" = /obj/item/harvester/advanced,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/harvester/simple = 1,
			/obj/item/resurgence_component/ash_plating = 1
		),
		"total_work" = 50,
		"desc" = "1 Simple Harvester + 1 Ash Plating -> Advanced Harvester (stores faith, auto-seeks)",
		"research_required" = "industrial"
	)

// ===== Portable Forge =====
// Does not require a workshop - works at full speed anywhere

/obj/structure/resurgence_crafting_table/forge/portable
	name = "portable forge"
	desc = "A compact forge that can be used anywhere. Less efficient than a proper workshop station, but functional outdoors."
	requires_workshop = FALSE

// ===== Primitive Forge =====
// Made from rock only, can only smelt ore to sheets at 2x work time
// Used to bootstrap metal production before building a proper forge

/obj/structure/resurgence_crafting_table/forge/primitive
	name = "primitive forge"
	desc = "A crude stone forge for basic smelting. Slower than a proper forge and can only smelt raw ore into sheets."
	icon_state = "forge_off"

/obj/structure/resurgence_crafting_table/forge/primitive/init_recipes()
	recipes = list()

	// Basic Smelting Only - 2x cost compared to regular forge
	recipes["Metal Sheet"] = list(
		"result" = /obj/item/stack/sheet/metal,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/iron = 4),
		"total_work" = 5,
		"desc" = "4 Iron Ore -> 1 Metal Sheet (inefficient)"
	)

	recipes["Metal Sheet (Scrap)"] = list(
		"result" = /obj/item/stack/sheet/metal,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/ironscrap = 6),
		"total_work" = 5,
		"desc" = "6 Iron Scrap -> 1 Metal Sheet (inefficient)"
	)

	recipes["Glass Sheet"] = list(
		"result" = /obj/item/stack/sheet/glass,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/glass = 4),
		"total_work" = 5,
		"desc" = "4 Sand -> 1 Glass Sheet (inefficient)"
	)

	recipes["Glass Sheet (Rubble)"] = list(
		"result" = /obj/item/stack/sheet/glass,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/glassrubble = 6),
		"total_work" = 5,
		"desc" = "6 Glass Rubble -> 1 Glass Sheet (inefficient)"
	)

	recipes["Silver Sheet"] = list(
		"result" = /obj/item/stack/sheet/mineral/silver,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/silver = 4),
		"total_work" = 5,
		"desc" = "4 Silver Ore -> 1 Silver Sheet (inefficient)"
	)

	recipes["Gold Sheet"] = list(
		"result" = /obj/item/stack/sheet/mineral/gold,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/gold = 4),
		"total_work" = 5,
		"desc" = "4 Gold Ore -> 1 Gold Sheet (inefficient)"
	)

	// Sandstone from sand
	recipes["Sandstone"] = list(
		"result" = /obj/item/stack/sheet/mineral/sandstone,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/glass = 2),
		"total_work" = 5,
		"desc" = "2 Sand -> 1 Sandstone (inefficient)"
	)

	// Iron from rock - same as regular forge (already slow)
	recipes["Iron Ore (Rock)"] = list(
		"result" = /obj/item/stack/ore/iron,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/ore/rock = 50),
		"total_work" = 10,
		"desc" = "50 Rock -> 1 Iron Ore (inefficient)"
	)
