/**
 * Resurgence Outpost - Loom
 *
 * A weaving station for processing plant fibers into cloth, crafting faith fabrics,
 * and weaving clothing from any existing design in the game.
 *
 * Woven clothing creates generic "resurgence" subtypes that copy visuals from originals.
 * These can have faith fabrics attached for passive faith bonuses.
 */

/// Category for fabric crafting
#define CRAFT_CAT_FABRICS "Fabrics"
/// Category for material processing
#define CRAFT_CAT_MATERIALS "Materials"
/// Category for storage items
#define CRAFT_CAT_STORAGE "Storage"
/// Clothing categories
#define CRAFT_CAT_JUMPSUITS "Jumpsuits"
#define CRAFT_CAT_OUTERWEAR "Outerwear"
#define CRAFT_CAT_HEADWEAR "Headwear"
#define CRAFT_CAT_MASKS "Masks"
#define CRAFT_CAT_GLOVES "Gloves"
#define CRAFT_CAT_SHOES "Shoes"

/// Uniform cloth cost for all clothing
#define CLOTHING_CLOTH_COST 10
/// Work required for all clothing
#define CLOTHING_WORK_COST 25

/obj/structure/resurgence_crafting_table/loom
	name = "loom"
	desc = "A wooden loom for weaving fibers into cloth, crafting faith fabrics, and creating clothing."
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "loom"

	// UI Theming
	action_verb = "Weave"
	busy_verb = "weaving"
	ui_color = "purple"

	/// Cached list of valid clothing types - built once globally
	var/static/list/cached_clothing_types
	/// Cached clothing metadata for UI - list of lists with name, icon, category, source_type
	var/static/list/cached_clothing_data

/obj/structure/resurgence_crafting_table/loom/init_recipes()
	recipes = list()

	// === MATERIALS ===

	recipes["Cloth"] = list(
		"result" = /obj/item/stack/sheet/cotton/cloth,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton = 3),
		"total_work" = 5,
		"desc" = "3 Cotton -> 1 Cloth",
		"category" = CRAFT_CAT_MATERIALS
	)

	recipes["Durathread"] = list(
		"result" = /obj/item/stack/sheet/durathread,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/durathread = 3),
		"total_work" = 10,
		"desc" = "3 Durathread Cotton -> 1 Durathread",
		"category" = CRAFT_CAT_MATERIALS
	)

	// === FAITH FABRICS ===
	// Higher tier fabrics require durathread cotton instead of massive cloth costs

	recipes["Simple Azure Faith Fabric"] = list(
		"result" = /obj/item/resurgence_fabric/simple,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 5,
			/obj/item/stack/resurgence_rope = 1
		),
		"total_work" = 20,
		"desc" = "5 Cloth + 1 Rope -> Simple Faith Fabric (+0.1 faith)",
		"category" = CRAFT_CAT_FABRICS,
		"research_required" = "faith_weaving"
	)

	recipes["Advanced Azure Faith Fabric"] = list(
		"result" = /obj/item/resurgence_fabric/advanced,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 8,
			/obj/item/stack/sheet/durathread = 3,
			/obj/item/stack/resurgence_rope = 2
		),
		"total_work" = 40,
		"desc" = "8 Cloth + 3 Durathread + 2 Rope -> Advanced Faith Fabric (+0.5 faith)",
		"category" = CRAFT_CAT_FABRICS,
		"research_required" = "advanced_weaving"
	)

	recipes["Elegant Azure Faith Fabric"] = list(
		"result" = /obj/item/resurgence_fabric/elegant,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 10,
			/obj/item/stack/sheet/durathread = 6,
			/obj/item/stack/resurgence_rope = 3
		),
		"total_work" = 60,
		"desc" = "10 Cloth + 6 Durathread + 3 Rope -> Elegant Faith Fabric (+1.0 faith)",
		"category" = CRAFT_CAT_FABRICS,
		"research_required" = "master_weaving"
	)

	// === STORAGE ===

	recipes["Backpack"] = list(
		"result" = /obj/item/storage/backpack,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 8),
		"total_work" = 25,
		"desc" = "8 Cloth -> Backpack",
		"category" = CRAFT_CAT_STORAGE,
		"research_required" = "textiles"
	)

	recipes["Explorer Backpack"] = list(
		"result" = /obj/item/storage/backpack/explorer,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 10,
			/obj/item/stack/sheet/leather = 2
		),
		"total_work" = 30,
		"desc" = "10 Cloth + 2 Leather -> Explorer Backpack",
		"category" = CRAFT_CAT_STORAGE,
		"research_required" = "advanced_weaving"
	)

	recipes["Satchel"] = list(
		"result" = /obj/item/storage/backpack/satchel,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 6),
		"total_work" = 20,
		"desc" = "6 Cloth -> Satchel",
		"category" = CRAFT_CAT_STORAGE,
		"research_required" = "textiles"
	)

	recipes["Leather Satchel"] = list(
		"result" = /obj/item/storage/backpack/satchel/leather,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/leather = 5),
		"total_work" = 25,
		"desc" = "5 Leather -> Leather Satchel",
		"category" = CRAFT_CAT_STORAGE,
		"research_required" = "advanced_weaving"
	)

	recipes["Duffel Bag"] = list(
		"result" = /obj/item/storage/backpack/duffelbag,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 12,
			/obj/item/stack/resurgence_rope = 1
		),
		"total_work" = 35,
		"desc" = "12 Cloth + 1 Rope -> Duffel Bag",
		"category" = CRAFT_CAT_STORAGE,
		"research_required" = "advanced_weaving"
	)

	// === DYNAMIC CLOTHING ===
	// Build cache if not already done, then add clothing recipes
	build_clothing_cache()
	add_clothing_recipes()

/// Build the global clothing cache - called once, caches all valid clothing types
/obj/structure/resurgence_crafting_table/loom/proc/build_clothing_cache()
	if(cached_clothing_types)
		return  // Already built

	cached_clothing_types = list()
	cached_clothing_data = list()

	var/list/base_types = list(
		list("base" = /obj/item/clothing/under, "category" = CRAFT_CAT_JUMPSUITS, "resurgence" = /obj/item/clothing/under/resurgence),
		list("base" = /obj/item/clothing/suit, "category" = CRAFT_CAT_OUTERWEAR, "resurgence" = /obj/item/clothing/suit/resurgence),
		list("base" = /obj/item/clothing/head, "category" = CRAFT_CAT_HEADWEAR, "resurgence" = /obj/item/clothing/head/resurgence),
		list("base" = /obj/item/clothing/mask, "category" = CRAFT_CAT_MASKS, "resurgence" = /obj/item/clothing/mask/resurgence),
		list("base" = /obj/item/clothing/gloves, "category" = CRAFT_CAT_GLOVES, "resurgence" = /obj/item/clothing/gloves/resurgence),
		list("base" = /obj/item/clothing/shoes, "category" = CRAFT_CAT_SHOES, "resurgence" = /obj/item/clothing/shoes/resurgence)
	)

	for(var/list/type_info in base_types)
		var/base_type = type_info["base"]
		var/category = type_info["category"]
		var/resurgence_type = type_info["resurgence"]

		for(var/clothing_type in subtypesof(base_type))
			// Skip excluded types
			if(is_excluded_clothing(clothing_type))
				continue

			// Get initial values for display
			var/obj/item/clothing/temp = clothing_type
			var/clothing_name = initial(temp.name)

			// Skip items with empty or generic names
			if(!clothing_name || clothing_name == "clothing" || clothing_name == "jumpsuit" || clothing_name == "suit")
				continue

			// Store in cache
			cached_clothing_types += clothing_type
			cached_clothing_data += list(list(
				"name" = clothing_name,
				"source_type" = clothing_type,
				"resurgence_type" = resurgence_type,
				"category" = category
			))

/// Check if a clothing type should be excluded from weaving
/obj/structure/resurgence_crafting_table/loom/proc/is_excluded_clothing(clothing_path)
	var/path_text = "[clothing_path]"

	// EXCEPTION: Allow city EGO gear suits (check this BEFORE excluding ego/armor)
	if(ispath(clothing_path, /obj/item/clothing/suit/armor/ego_gear/city))
		return FALSE

	// Exclude EGO items (except city gear allowed above)
	if(findtext(path_text, "ego"))
		return TRUE

	// Exclude our own resurgence types (avoid recursion)
	if(findtext(path_text, "resurgence"))
		return TRUE

	// Exclude admin/debug items
	if(findtext(path_text, "intangible"))
		return TRUE
	if(findtext(path_text, "admin"))
		return TRUE

	// Exclude armored items by path (helmets, hardhats, armor, security gear)
	// Note: city ego gear is already allowed above
	if(findtext(path_text, "armor"))
		return TRUE
	return FALSE

/// Add clothing recipes from the cache to the recipe list
/obj/structure/resurgence_crafting_table/loom/proc/add_clothing_recipes()
	if(!cached_clothing_data)
		return

	for(var/list/clothing_info in cached_clothing_data)
		var/clothing_name = clothing_info["name"]
		var/source_type = clothing_info["source_type"]
		var/resurgence_type = clothing_info["resurgence_type"]
		var/category = clothing_info["category"]

		// Create a unique recipe name (capitalize first letter)
		var/recipe_name = capitalize(clothing_name)

		// Skip if we somehow already have this recipe
		if(recipes[recipe_name])
			continue

		recipes[recipe_name] = list(
			"result" = resurgence_type,
			"result_amount" = 1,
			"materials" = list(/obj/item/stack/sheet/cotton/cloth = CLOTHING_CLOTH_COST),
			"total_work" = CLOTHING_WORK_COST,
			"desc" = "[CLOTHING_CLOTH_COST] Cloth -> [clothing_name] (no faith - attach fabric for faith)",
			"category" = category,
			"is_clothing" = TRUE,
			"source_type" = source_type,
			"research_required" = "faith_weaving"
		)

/// Override create_result to handle clothing visual copying
/obj/structure/resurgence_crafting_table/loom/create_result(mob/user, list/recipe)
	// Check if this is a clothing recipe that needs visual copying
	if(!recipe["is_clothing"])
		return ..()  // Normal handling for non-clothing

	var/source_type = recipe["source_type"]
	var/result_type = recipe["result"]

	// Create the resurgence clothing
	var/obj/item/clothing/C = new result_type(get_turf(src))

	// Copy visual properties from source type
	var/obj/item/clothing/source = source_type
	C.name = "clan-woven [initial(source.name)]"
	C.desc = "[initial(source.desc)] This garment was lovingly crafted by the Resurgence Clan."
	C.icon = initial(source.icon)
	C.icon_state = initial(source.icon_state)
	C.allowed = list(/obj/item/gun, /obj/item/ego_weapon, /obj/item/melee)

	// Copy optional visual properties if they exist
	var/inhand = initial(source.inhand_icon_state)
	if(inhand)
		C.inhand_icon_state = inhand

	var/worn = initial(source.worn_icon)
	if(worn)
		C.worn_icon = worn

	var/worn_state = initial(source.worn_icon_state)
	if(worn_state)
		C.worn_icon_state = worn_state

	// Track for objectives
	GLOB.resurgence_outfits_crafted++
	update_all_objectives()

// ===== Portable Loom =====
// Does not require a workshop - works at full speed anywhere

/obj/structure/resurgence_crafting_table/loom/portable
	name = "portable loom"
	desc = "A compact loom that can be used anywhere. Less efficient than a proper workshop station, but functional outdoors."
	requires_workshop = FALSE

// ===== Primitive Loom =====
// Made from wood only, can only make cloth and rope at 2x work time
// Used to bootstrap textile production before building a proper loom

/obj/structure/resurgence_crafting_table/loom/primitive
	name = "primitive loom"
	desc = "A simple wooden frame for basic weaving. Slower than a proper loom and can only produce cloth and rope."
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "loom"

/obj/structure/resurgence_crafting_table/loom/primitive/init_recipes()
	recipes = list()

	// Basic Materials Only - 2x work time compared to regular loom
	recipes["Cloth"] = list(
		"result" = /obj/item/stack/sheet/cotton/cloth,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton = 3),
		"total_work" = 10,
		"desc" = "3 Cotton -> 1 Cloth (slow)",
		"category" = CRAFT_CAT_MATERIALS
	)

	recipes["Rope"] = list(
		"result" = /obj/item/stack/resurgence_rope,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton = 5),
		"total_work" = 15,
		"desc" = "5 Cotton -> 1 Rope (slow)",
		"category" = CRAFT_CAT_MATERIALS
	)

	recipes["Rope (Vines)"] = list(
		"result" = /obj/item/stack/resurgence_rope,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/resurgence_vines = 3),
		"total_work" = 10,
		"desc" = "3 Vines -> 1 Rope",
		"category" = CRAFT_CAT_MATERIALS
	)

#undef CRAFT_CAT_FABRICS
#undef CRAFT_CAT_MATERIALS
#undef CRAFT_CAT_STORAGE
#undef CRAFT_CAT_JUMPSUITS
#undef CRAFT_CAT_OUTERWEAR
#undef CRAFT_CAT_HEADWEAR
#undef CRAFT_CAT_MASKS
#undef CRAFT_CAT_GLOVES
#undef CRAFT_CAT_SHOES
#undef CLOTHING_CLOTH_COST
#undef CLOTHING_WORK_COST
