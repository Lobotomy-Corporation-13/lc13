/**
 * Resurgence Outpost - Crafting Table
 *
 * Base workbench for crafting. Subtypes (forge, loom) override recipes and theming.
 * Uses a progress-based system where players work in increments and can leave/return.
 *
 * Work System:
 * - Each recipe has a "total_work" value (e.g., 20 work)
 * - Each 5-second work session adds WORK_PER_SESSION points (default 5)
 * - Example: 20 work / 5 per session = 4 sessions = 20 seconds at base speed
 * - This allows for speed modifiers (faster workers add more per session)
 */

/// How many seconds each work session takes
#define WORK_SESSION_TIME 2 SECONDS
/// How many work points are added per session (at base speed)
#define WORK_PER_SESSION 2
/// Extra work per crafting level above 1
#define CRAFTING_WORK_PER_LEVEL 0.5
/// Acceleration mode faith drain multiplier
#define ACCELERATION_FAITH_MULT 3
/// Minimum faith required to craft
#define MIN_FAITH_FOR_CRAFTING 5

/// Crafting recipe categories
#define CRAFT_CAT_PROCESSING "Processing"
#define CRAFT_CAT_TOOLS "Tools"
#define CRAFT_CAT_FLOORING "Flooring"
#define CRAFT_CAT_ART "Art"
#define CRAFT_CAT_PAPERWORK "Paperwork"
#define CRAFT_CAT_CLEANING "Cleaning"
#define CRAFT_CAT_MUSIC "Music"
#define CRAFT_CAT_ELECTRONICS "Electronics"

/obj/structure/resurgence_crafting_table
	name = "crafting table"
	desc = "A sturdy workbench for crafting components and items."
	icon = 'icons/obj/cult.dmi'
	icon_state = "tomealtar"
	density = TRUE
	anchored = TRUE

	/// Whether someone is currently working at the table
	var/busy = FALSE

	/// List of available recipes - initialized per subtype
	var/list/recipes

	// UI Theming - override in subtypes
	/// Action verb (e.g., "Craft", "Smelt", "Weave")
	var/action_verb = "Craft"
	/// Busy message verb (e.g., "crafting", "smelting", "weaving")
	var/busy_verb = "crafting"
	/// Sound to play on completion
	var/complete_sound = 'sound/items/deconstruct.ogg'
	/// UI accent color (used in TGUI)
	var/ui_color = "brown"

	/// Whether this crafting table requires a workshop for normal speed
	/// If TRUE, crafting is 3x slower when not in a workshop
	var/requires_workshop = TRUE
	/// Multiplier for work time when not in a workshop (default 3x slower)
	var/outdoor_penalty = 3

	// Progress-based crafting state
	/// Current recipe being crafted (null if nothing in progress)
	var/current_recipe_name = null
	/// Current work points completed (0 to total_work)
	var/current_work = 0
	/// Total work points needed for current craft
	var/total_work_needed = 0
	/// Cached recipe data for the current craft
	var/list/current_recipe_data = null

	// Batch crafting state
	/// How many copies the player wants to craft total
	var/target_copies = 1
	/// How many copies have been completed so far
	var/completed_copies = 0

	// UI pagination state (per-table, shared across users)
	/// Current page number (1-indexed)
	var/ui_current_page = 1
	/// Current search text filter
	var/ui_search_text = ""
	/// Current active category filter
	var/ui_active_category = "All"
	/// Recipes per page
	var/static/recipes_per_page = 10

	/// Hide recipes that haven't been researched yet (default TRUE)
	var/hide_locked_recipes = TRUE

/obj/structure/resurgence_crafting_table/Initialize(mapload)
	. = ..()
	if(!recipes)
		init_recipes()

/// Get the work session time, accounting for workshop and acceleration
/obj/structure/resurgence_crafting_table/proc/get_work_time(mob/user = null)
	var/base_time = WORK_SESSION_TIME

	// Apply workshop penalty if required
	if(requires_workshop && !is_in_workshop(src))
		base_time *= outdoor_penalty

	// Accelerated Crafting halves crafting time (checked on user's core)
	if(is_user_accelerated(user))
		base_time *= 0.5

	return base_time

/// Check if the user has Accelerated Crafting active
/obj/structure/resurgence_crafting_table/proc/is_user_accelerated(mob/user)
	if(!ishuman(user))
		return FALSE
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return FALSE
	return core.acceleration_active

/// Get the work per session, accounting for crafting stat bonus, traits, and event modifiers
/obj/structure/resurgence_crafting_table/proc/get_work_per_session(mob/user = null)
	var/work = WORK_PER_SESSION

	// Apply crafting stat work bonus if user is a resurgence machine
	// +0.5 work per level above 1
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			work += (core.stat_crafting - 1) * CRAFTING_WORK_PER_LEVEL

		// Apply trait work speed modifier (Industrious, Lazy, Nervous)
		work *= get_trait_work_speed_modifier(H)

	// Apply global work modifier from events
	work *= GLOB.resurgence_work_modifier

	return work

/// Check if the user has enough faith to craft (> MIN_FAITH_FOR_CRAFTING)
/obj/structure/resurgence_crafting_table/proc/check_user_faith(mob/user)
	if(!ishuman(user))
		return TRUE
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return TRUE
	return core.faith > MIN_FAITH_FOR_CRAFTING

/// Check if crafting is at reduced efficiency (not in workshop when required)
/obj/structure/resurgence_crafting_table/proc/is_at_reduced_efficiency()
	if(!requires_workshop)
		return FALSE
	return !is_in_workshop(src)

/// Check if a recipe is available (research requirements met)
/obj/structure/resurgence_crafting_table/proc/is_recipe_available(recipe_name)
	var/list/recipe = recipes[recipe_name]
	if(!recipe)
		return FALSE

	var/research_req = recipe["research_required"]
	if(!research_req)
		return TRUE  // No research needed

	return GLOB.resurgence_research.is_researched(research_req)

/// Get the lock reason for a recipe (returns null if not locked)
/obj/structure/resurgence_crafting_table/proc/get_recipe_lock_reason(recipe_name)
	var/list/recipe = recipes[recipe_name]
	if(!recipe)
		return null

	var/research_req = recipe["research_required"]
	if(!research_req)
		return null

	if(GLOB.resurgence_research.is_researched(research_req))
		return null

	return GLOB.resurgence_research.get_node_name(research_req)

/// Initialize the recipe list - override in subtypes
/obj/structure/resurgence_crafting_table/proc/init_recipes()
	recipes = list()

	// Basic Processing
	recipes["Metal Rods"] = list(
		"result" = /obj/item/stack/rods,
		"result_amount" = 2,
		"materials" = list(/obj/item/stack/sheet/metal = 1),
		"total_work" = 10,
		"desc" = "1 Metal -> 2 Metal Rods",
		"category" = CRAFT_CAT_PROCESSING
	)

	recipes["Rope"] = list(
		"result" = /obj/item/resurgence_component/rope,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 3),
		"total_work" = 10,
		"desc" = "3 Cloth -> 1 Rope",
		"category" = CRAFT_CAT_PROCESSING
	)

	recipes["Rope (Cotton)"] = list(
		"result" = /obj/item/resurgence_component/rope,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton = 8),
		"total_work" = 25,
		"desc" = "8 Cotton -> 1 Rope (slow, no loom needed)",
		"category" = CRAFT_CAT_PROCESSING
	)

	recipes["Rope (Vines)"] = list(
		"result" = /obj/item/resurgence_component/rope,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/resurgence_vines = 3),
		"total_work" = 15,
		"desc" = "3 Vines -> 1 Rope",
		"category" = CRAFT_CAT_PROCESSING
	)

	recipes["Fertilizer"] = list(
		"result" = /obj/item/stack/resurgence_fertilizer,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/mineral/coal = 5),
		"total_work" = 10,
		"desc" = "5 Coal -> 1 Fertilizer (used to make farm plots)",
		"category" = CRAFT_CAT_PROCESSING
	)

	// Tools - ordered by complexity
	recipes["Wooden Hatchet"] = list(
		"result" = /obj/item/hatchet/wooden,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 2,
			/obj/item/resurgence_component/rope = 1
		),
		"total_work" = 15,
		"desc" = "2 Wood + 1 Rope -> Wooden Hatchet",
		"category" = CRAFT_CAT_TOOLS
	)

	recipes["Improvised Pickaxe"] = list(
		"result" = /obj/item/pickaxe/improvised,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 2,
			/obj/item/resurgence_component/rope = 1
		),
		"total_work" = 15,
		"desc" = "2 Wood + 1 Rope -> Improvised Pickaxe (slow but cheap)",
		"category" = CRAFT_CAT_TOOLS
	)

	recipes["Simple Harvester"] = list(
		"result" = /obj/item/harvester/simple,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 5,
			/obj/item/stack/sheet/metal = 5,
			/obj/item/resurgence_component/rope = 2
		),
		"total_work" = 25,
		"desc" = "5 Wood + 5 Metal + 2 Rope -> Simple Harvester (auto-harvests resources)",
		"category" = CRAFT_CAT_TOOLS,
		"research_required" = "harvesting_tech"
	)

	recipes["Wooden Bucket"] = list(
		"result" = /obj/item/reagent_containers/glass/bucket/wooden,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 3
		),
		"total_work" = 10,
		"desc" = "3 Wood -> Wooden Bucket (can be filled at water sources)",
		"category" = CRAFT_CAT_TOOLS
	)

	recipes["Wooden Scythe"] = list(
		"result" = /obj/item/scythe/wooden,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 6,
			/obj/item/resurgence_component/rope = 2
		),
		"total_work" = 25,
		"desc" = "6 Wood + 2 Rope -> Wooden Scythe (harvesting tool)",
		"category" = CRAFT_CAT_TOOLS,
		"research_required" = "woodworking"
	)

	recipes["Cable Coil"] = list(
		"result" = /obj/item/stack/cable_coil,
		"result_amount" = 15,
		"materials" = list(
			/obj/item/stack/sheet/metal = 1,
			/obj/item/stack/sheet/cotton/cloth = 1
		),
		"total_work" = 10,
		"desc" = "1 Metal + 1 Cloth -> 15 Cable Coil (heals machines)",
		"category" = CRAFT_CAT_TOOLS
	)

	// Floor Tiles
	recipes["Plasteel Floor Tiles"] = list(
		"result" = /obj/item/stack/tile/plasteel,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/plasteel = 2),
		"total_work" = 10,
		"desc" = "2 Plasteel -> 4 Plasteel Floor Tiles",
		"category" = CRAFT_CAT_FLOORING,
		"research_required" = "advanced_metallurgy"
	)

	// Carpet Tiles
	recipes["Black Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/black,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"total_work" = 10,
		"desc" = "2 Cloth -> 4 Black Carpet",
		"category" = CRAFT_CAT_FLOORING,
		"research_required" = "flooring"
	)

	recipes["Blue Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/blue,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"total_work" = 10,
		"desc" = "2 Cloth -> 4 Blue Carpet",
		"category" = CRAFT_CAT_FLOORING,
		"research_required" = "flooring"
	)

	recipes["Cyan Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/cyan,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"total_work" = 10,
		"desc" = "2 Cloth -> 4 Cyan Carpet",
		"category" = CRAFT_CAT_FLOORING,
		"research_required" = "flooring"
	)

	recipes["Green Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/green,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"total_work" = 10,
		"desc" = "2 Cloth -> 4 Green Carpet",
		"category" = CRAFT_CAT_FLOORING,
		"research_required" = "flooring"
	)

	recipes["Orange Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/orange,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"total_work" = 10,
		"desc" = "2 Cloth -> 4 Orange Carpet",
		"category" = CRAFT_CAT_FLOORING,
		"research_required" = "flooring"
	)

	recipes["Purple Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/purple,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"total_work" = 10,
		"desc" = "2 Cloth -> 4 Purple Carpet",
		"category" = CRAFT_CAT_FLOORING,
		"research_required" = "flooring"
	)

	recipes["Red Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/red,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"total_work" = 10,
		"desc" = "2 Cloth -> 4 Red Carpet",
		"category" = CRAFT_CAT_FLOORING,
		"research_required" = "flooring"
	)

	// Royal Carpets (require gold)
	recipes["Royal Black Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/royalblack,
		"result_amount" = 4,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 2,
			/obj/item/stack/sheet/mineral/gold = 1
		),
		"total_work" = 15,
		"desc" = "2 Cloth + 1 Gold -> 4 Royal Black Carpet",
		"category" = CRAFT_CAT_FLOORING,
		"research_required" = "luxury_decor"
	)

	recipes["Royal Blue Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/royalblue,
		"result_amount" = 4,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 2,
			/obj/item/stack/sheet/mineral/gold = 1
		),
		"total_work" = 15,
		"desc" = "2 Cloth + 1 Gold -> 4 Royal Blue Carpet",
		"category" = CRAFT_CAT_FLOORING,
		"research_required" = "luxury_decor"
	)

	// Art Supplies
	recipes["Canvas (11x11)"] = list(
		"result" = /obj/item/canvas,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"total_work" = 10,
		"desc" = "2 Cloth -> Small Canvas (11x11)",
		"category" = CRAFT_CAT_ART,
		"research_required" = "artistry"
	)

	recipes["Canvas (19x19)"] = list(
		"result" = /obj/item/canvas/nineteen_nineteen,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 3),
		"total_work" = 15,
		"desc" = "3 Cloth -> Medium Canvas (19x19)",
		"category" = CRAFT_CAT_ART,
		"research_required" = "artistry"
	)

	recipes["Canvas (23x19)"] = list(
		"result" = /obj/item/canvas/twentythree_nineteen,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 4),
		"total_work" = 15,
		"desc" = "4 Cloth -> Wide Canvas (23x19)",
		"category" = CRAFT_CAT_ART,
		"research_required" = "artistry"
	)

	recipes["Canvas (23x23)"] = list(
		"result" = /obj/item/canvas/twentythree_twentythree,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 5),
		"total_work" = 20,
		"desc" = "5 Cloth -> Large Canvas (23x23)",
		"category" = CRAFT_CAT_ART,
		"research_required" = "artistry"
	)

	recipes["Painting Frame"] = list(
		"result" = /obj/item/wallframe/painting/resurgence,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/mineral/wood = 2),
		"total_work" = 10,
		"desc" = "2 Wood -> Painting Frame (wall mount for canvases, paintings preserved)",
		"category" = CRAFT_CAT_ART,
		"research_required" = "artistry"
	)

	// Paperwork - Pens
	recipes["Pen (Black)"] = list(
		"result" = /obj/item/pen,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/metal = 1),
		"total_work" = 5,
		"desc" = "1 Metal -> Black Pen",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["Pen (Blue)"] = list(
		"result" = /obj/item/pen/blue,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/metal = 1),
		"total_work" = 5,
		"desc" = "1 Metal -> Blue Pen",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["Pen (Red)"] = list(
		"result" = /obj/item/pen/red,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/metal = 1),
		"total_work" = 5,
		"desc" = "1 Metal -> Red Pen",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["Pen (Invisible)"] = list(
		"result" = /obj/item/pen/invisible,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/metal = 1),
		"total_work" = 5,
		"desc" = "1 Metal -> Invisible Ink Pen",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["Four-Color Pen"] = list(
		"result" = /obj/item/pen/fourcolor,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/metal = 2),
		"total_work" = 10,
		"desc" = "2 Metal -> Four-Color Pen",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["Fountain Pen"] = list(
		"result" = /obj/item/pen/fountain,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 1,
			/obj/item/stack/sheet/mineral/wood = 2
		),
		"total_work" = 15,
		"desc" = "1 Metal + 2 Wood -> Fountain Pen",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["Charcoal Stylus"] = list(
		"result" = /obj/item/pen/charcoal,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/mineral/wood = 1),
		"total_work" = 5,
		"desc" = "1 Wood -> Charcoal Stylus",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	// Paperwork - Paper & Storage
	recipes["Paper"] = list(
		"result" = /obj/item/paper,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 1),
		"total_work" = 5,
		"desc" = "1 Cloth -> Paper",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["Folder"] = list(
		"result" = /obj/item/folder,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 1,
			/obj/item/stack/sheet/mineral/wood = 1
		),
		"total_work" = 5,
		"desc" = "1 Cloth + 1 Wood -> Folder",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["Folder (Blue)"] = list(
		"result" = /obj/item/folder/blue,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 1,
			/obj/item/stack/sheet/mineral/wood = 1
		),
		"total_work" = 5,
		"desc" = "1 Cloth + 1 Wood -> Blue Folder",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["Folder (Red)"] = list(
		"result" = /obj/item/folder/red,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 1,
			/obj/item/stack/sheet/mineral/wood = 1
		),
		"total_work" = 5,
		"desc" = "1 Cloth + 1 Wood -> Red Folder",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["Folder (Yellow)"] = list(
		"result" = /obj/item/folder/yellow,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 1,
			/obj/item/stack/sheet/mineral/wood = 1
		),
		"total_work" = 5,
		"desc" = "1 Cloth + 1 Wood -> Yellow Folder",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["Folder (White)"] = list(
		"result" = /obj/item/folder/white,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 1,
			/obj/item/stack/sheet/mineral/wood = 1
		),
		"total_work" = 5,
		"desc" = "1 Cloth + 1 Wood -> White Folder",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["Clipboard"] = list(
		"result" = /obj/item/clipboard,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 1,
			/obj/item/stack/sheet/mineral/wood = 2
		),
		"total_work" = 10,
		"desc" = "1 Metal + 2 Wood -> Clipboard",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["Empty Paper Bin"] = list(
		"result" = /obj/item/paper_bin/empty,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/mineral/wood = 3),
		"total_work" = 10,
		"desc" = "3 Wood -> Empty Paper Bin",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	// Paperwork - Hand Labeler
	recipes["Hand Labeler"] = list(
		"result" = /obj/item/hand_labeler,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 2,
			/obj/item/stack/sheet/metal = 2
		),
		"total_work" = 15,
		"desc" = "2 Cloth + 2 Metal -> Hand Labeler",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["Hand Labeler Refill"] = list(
		"result" = /obj/item/hand_labeler_refill,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 1),
		"total_work" = 5,
		"desc" = "1 Cloth -> Hand Labeler Refill",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	// Paperwork - Stamps
	recipes["GRANTED Stamp"] = list(
		"result" = /obj/item/stamp,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 1,
			/obj/item/stack/sheet/cotton/cloth = 1
		),
		"total_work" = 10,
		"desc" = "1 Wood + 1 Cloth -> GRANTED Stamp",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["DENIED Stamp"] = list(
		"result" = /obj/item/stamp/denied,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 1,
			/obj/item/stack/sheet/cotton/cloth = 1
		),
		"total_work" = 10,
		"desc" = "1 Wood + 1 Cloth -> DENIED Stamp",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["QM Stamp"] = list(
		"result" = /obj/item/stamp/qm,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 1,
			/obj/item/stack/sheet/cotton/cloth = 1
		),
		"total_work" = 10,
		"desc" = "1 Wood + 1 Cloth -> Quartermaster's Stamp",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["Captain Stamp"] = list(
		"result" = /obj/item/stamp/captain,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 1,
			/obj/item/stack/sheet/cotton/cloth = 1
		),
		"total_work" = 10,
		"desc" = "1 Wood + 1 Cloth -> Captain's Stamp",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["HoP Stamp"] = list(
		"result" = /obj/item/stamp/hop,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 1,
			/obj/item/stack/sheet/cotton/cloth = 1
		),
		"total_work" = 10,
		"desc" = "1 Wood + 1 Cloth -> Head of Personnel's Stamp",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["HoS Stamp"] = list(
		"result" = /obj/item/stamp/hos,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 1,
			/obj/item/stack/sheet/cotton/cloth = 1
		),
		"total_work" = 10,
		"desc" = "1 Wood + 1 Cloth -> Head of Security's Stamp",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["CE Stamp"] = list(
		"result" = /obj/item/stamp/ce,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 1,
			/obj/item/stack/sheet/cotton/cloth = 1
		),
		"total_work" = 10,
		"desc" = "1 Wood + 1 Cloth -> Chief Engineer's Stamp",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["RD Stamp"] = list(
		"result" = /obj/item/stamp/rd,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 1,
			/obj/item/stack/sheet/cotton/cloth = 1
		),
		"total_work" = 10,
		"desc" = "1 Wood + 1 Cloth -> Research Director's Stamp",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["CMO Stamp"] = list(
		"result" = /obj/item/stamp/cmo,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 1,
			/obj/item/stack/sheet/cotton/cloth = 1
		),
		"total_work" = 10,
		"desc" = "1 Wood + 1 Cloth -> Chief Medical Officer's Stamp",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["Law Stamp"] = list(
		"result" = /obj/item/stamp/law,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 1,
			/obj/item/stack/sheet/cotton/cloth = 1
		),
		"total_work" = 10,
		"desc" = "1 Wood + 1 Cloth -> Law Office's Stamp",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["Clown Stamp"] = list(
		"result" = /obj/item/stamp/clown,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 1,
			/obj/item/stack/sheet/cotton/cloth = 1
		),
		"total_work" = 10,
		"desc" = "1 Wood + 1 Cloth -> Clown's Stamp",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["Mime Stamp"] = list(
		"result" = /obj/item/stamp/mime,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 1,
			/obj/item/stack/sheet/cotton/cloth = 1
		),
		"total_work" = 10,
		"desc" = "1 Wood + 1 Cloth -> Mime's Stamp",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	recipes["Chaplain Stamp"] = list(
		"result" = /obj/item/stamp/chap,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 1,
			/obj/item/stack/sheet/cotton/cloth = 1
		),
		"total_work" = 10,
		"desc" = "1 Wood + 1 Cloth -> Chaplain's Stamp",
		"category" = CRAFT_CAT_PAPERWORK,
		"research_required" = "papercraft"
	)

	// Cleaning Equipment
	recipes["Push Broom"] = list(
		"result" = /obj/item/pushbroom,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 3,
			/obj/item/stack/sheet/cotton/cloth = 2
		),
		"total_work" = 15,
		"desc" = "3 Wood + 2 Cloth -> Push Broom (sweeps items when braced)",
		"category" = CRAFT_CAT_CLEANING,
		"research_required" = "cleaning"
	)

	recipes["Spray Can"] = list(
		"result" = /obj/item/toy/crayon/spraycan,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 2
		),
		"total_work" = 10,
		"desc" = "2 Metal -> Spray Can (for graffiti art)",
		"category" = CRAFT_CAT_CLEANING,
		"research_required" = "cleaning"
	)

	recipes["Infinite Spray Can"] = list(
		"result" = /obj/item/toy/crayon/spraycan/infinite,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 5,
			/obj/item/stack/sheet/mineral/gold = 2
		),
		"total_work" = 30,
		"desc" = "5 Metal + 2 Gold -> Infinite Spray Can (never runs out)",
		"category" = CRAFT_CAT_CLEANING,
		"research_required" = "advanced_cleaning"
	)

	recipes["Janitor Chem Sprayer"] = list(
		"result" = /obj/item/reagent_containers/spray/chemsprayer/janitor,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 10,
			/obj/item/stack/sheet/glass = 5,
			/obj/item/resurgence_component/rope = 2
		),
		"total_work" = 50,
		"desc" = "10 Metal + 5 Glass + 2 Rope -> Janitor Chem Sprayer (self-regenerating cleaner)",
		"category" = CRAFT_CAT_CLEANING,
		"research_required" = "advanced_cleaning"
	)

	recipes["Trash Bag"] = list(
		"result" = /obj/item/storage/bag/trash,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 3
		),
		"total_work" = 10,
		"desc" = "3 Cloth -> Trash Bag",
		"category" = CRAFT_CAT_CLEANING,
		"research_required" = "cleaning"
	)

	recipes["Trash Bag of Holding"] = list(
		"result" = /obj/item/storage/bag/trash/bluespace,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 5,
			/obj/item/stack/sheet/mineral/gold = 3
		),
		"total_work" = 40,
		"desc" = "5 Cloth + 3 Gold -> Trash Bag of Holding (holds way more trash)",
		"category" = CRAFT_CAT_CLEANING,
		"research_required" = "advanced_cleaning"
	)

	// Musical Instruments - Basic Music
	recipes["Recorder"] = list(
		"result" = /obj/item/instrument/recorder,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 3
		),
		"total_work" = 10,
		"desc" = "3 Wood -> Recorder",
		"category" = CRAFT_CAT_MUSIC,
		"research_required" = "basic_music"
	)

	recipes["Harmonica"] = list(
		"result" = /obj/item/instrument/harmonica,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 4
		),
		"total_work" = 15,
		"desc" = "4 Metal -> Harmonica",
		"category" = CRAFT_CAT_MUSIC,
		"research_required" = "basic_music"
	)

	recipes["Banjo"] = list(
		"result" = /obj/item/instrument/banjo,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 6,
			/obj/item/resurgence_component/rope = 2
		),
		"total_work" = 25,
		"desc" = "6 Wood + 2 Rope -> Banjo",
		"category" = CRAFT_CAT_MUSIC,
		"research_required" = "basic_music"
	)

	recipes["Bike Horn Instrument"] = list(
		"result" = /obj/item/instrument/bikehorn,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 2,
			/obj/item/stack/sheet/cotton/cloth = 1
		),
		"total_work" = 10,
		"desc" = "2 Metal + 1 Cloth -> Bike Horn Instrument",
		"category" = CRAFT_CAT_MUSIC,
		"research_required" = "basic_music"
	)

	// Musical Instruments - Advanced Music
	recipes["Violin"] = list(
		"result" = /obj/item/instrument/violin,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 8,
			/obj/item/resurgence_component/rope = 2
		),
		"total_work" = 30,
		"desc" = "8 Wood + 2 Rope -> Violin",
		"category" = CRAFT_CAT_MUSIC,
		"research_required" = "advanced_music"
	)

	recipes["Guitar"] = list(
		"result" = /obj/item/instrument/guitar,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 8,
			/obj/item/resurgence_component/rope = 3
		),
		"total_work" = 30,
		"desc" = "8 Wood + 3 Rope -> Guitar",
		"category" = CRAFT_CAT_MUSIC,
		"research_required" = "advanced_music"
	)

	recipes["Accordion"] = list(
		"result" = /obj/item/instrument/accordion,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 6,
			/obj/item/stack/sheet/cotton/cloth = 4
		),
		"total_work" = 30,
		"desc" = "6 Metal + 4 Cloth -> Accordion",
		"category" = CRAFT_CAT_MUSIC,
		"research_required" = "advanced_music"
	)

	recipes["Trumpet"] = list(
		"result" = /obj/item/instrument/trumpet,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 8
		),
		"total_work" = 25,
		"desc" = "8 Metal -> Trumpet",
		"category" = CRAFT_CAT_MUSIC,
		"research_required" = "advanced_music"
	)

	recipes["Saxophone"] = list(
		"result" = /obj/item/instrument/saxophone,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 10
		),
		"total_work" = 30,
		"desc" = "10 Metal -> Saxophone",
		"category" = CRAFT_CAT_MUSIC,
		"research_required" = "advanced_music"
	)

	recipes["Glockenspiel"] = list(
		"result" = /obj/item/instrument/glockenspiel,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 10,
			/obj/item/stack/sheet/mineral/wood = 4
		),
		"total_work" = 35,
		"desc" = "10 Metal + 4 Wood -> Glockenspiel",
		"category" = CRAFT_CAT_MUSIC,
		"research_required" = "advanced_music"
	)

	recipes["Musical Moth"] = list(
		"result" = /obj/item/instrument/musicalmoth,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/cotton/cloth = 5,
			/obj/item/stack/sheet/metal = 2
		),
		"total_work" = 20,
		"desc" = "5 Cloth + 2 Metal -> Musical Moth",
		"category" = CRAFT_CAT_MUSIC,
		"research_required" = "advanced_music"
	)

	// Musical Instruments - Master Music
	recipes["Golden Violin"] = list(
		"result" = /obj/item/instrument/violin/golden,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/mineral/wood = 8,
			/obj/item/stack/sheet/mineral/gold = 5,
			/obj/item/resurgence_component/rope = 2
		),
		"total_work" = 50,
		"desc" = "8 Wood + 5 Gold + 2 Rope -> Golden Violin",
		"category" = CRAFT_CAT_MUSIC,
		"research_required" = "master_music"
	)

	recipes["Synthesizer"] = list(
		"result" = /obj/item/instrument/piano_synth,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 10,
			/obj/item/stack/sheet/glass = 5
		),
		"total_work" = 40,
		"desc" = "10 Metal + 5 Glass -> Synthesizer",
		"category" = CRAFT_CAT_MUSIC,
		"research_required" = "master_music"
	)

	recipes["Synthesizer Headphones"] = list(
		"result" = /obj/item/instrument/piano_synth/headphones,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 8,
			/obj/item/stack/sheet/glass = 3,
			/obj/item/stack/sheet/cotton/cloth = 2
		),
		"total_work" = 35,
		"desc" = "8 Metal + 3 Glass + 2 Cloth -> Synthesizer Headphones",
		"category" = CRAFT_CAT_MUSIC,
		"research_required" = "master_music"
	)

	// Radio Headsets
	recipes["Radio Headset"] = list(
		"result" = /obj/item/radio/headset,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3,
			/obj/item/stack/sheet/mineral/silver = 2
		),
		"total_work" = 20,
		"desc" = "3 Metal + 2 Silver -> Radio Headset",
		"category" = CRAFT_CAT_ELECTRONICS,
		"research_required" = "communications"
	)

	recipes["Bowman Headset"] = list(
		"result" = /obj/item/radio/headset/alt,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 4,
			/obj/item/stack/sheet/mineral/silver = 2,
			/obj/item/stack/sheet/cotton/cloth = 2
		),
		"total_work" = 25,
		"desc" = "4 Metal + 2 Silver + 2 Cloth -> Bowman Headset (ear protection)",
		"category" = CRAFT_CAT_ELECTRONICS,
		"research_required" = "communications"
	)

	recipes["Control Headset"] = list(
		"result" = /obj/item/radio/headset/headset_control,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3,
			/obj/item/stack/sheet/mineral/silver = 2
		),
		"total_work" = 20,
		"desc" = "3 Metal + 2 Silver -> Control Department Headset",
		"category" = CRAFT_CAT_ELECTRONICS,
		"research_required" = "communications"
	)

	recipes["Information Headset"] = list(
		"result" = /obj/item/radio/headset/headset_information,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3,
			/obj/item/stack/sheet/mineral/silver = 2
		),
		"total_work" = 20,
		"desc" = "3 Metal + 2 Silver -> Information Department Headset",
		"category" = CRAFT_CAT_ELECTRONICS,
		"research_required" = "communications"
	)

	recipes["Safety Headset"] = list(
		"result" = /obj/item/radio/headset/headset_safety,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3,
			/obj/item/stack/sheet/mineral/silver = 2
		),
		"total_work" = 20,
		"desc" = "3 Metal + 2 Silver -> Safety Department Headset",
		"category" = CRAFT_CAT_ELECTRONICS,
		"research_required" = "communications"
	)

	recipes["Training Headset"] = list(
		"result" = /obj/item/radio/headset/headset_training,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3,
			/obj/item/stack/sheet/mineral/silver = 2
		),
		"total_work" = 20,
		"desc" = "3 Metal + 2 Silver -> Training Department Headset",
		"category" = CRAFT_CAT_ELECTRONICS,
		"research_required" = "communications"
	)

	recipes["Central Headset"] = list(
		"result" = /obj/item/radio/headset/headset_command,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3,
			/obj/item/stack/sheet/mineral/silver = 2
		),
		"total_work" = 20,
		"desc" = "3 Metal + 2 Silver -> Central Command Headset",
		"category" = CRAFT_CAT_ELECTRONICS,
		"research_required" = "communications"
	)

	recipes["Welfare Headset"] = list(
		"result" = /obj/item/radio/headset/headset_welfare,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3,
			/obj/item/stack/sheet/mineral/silver = 2
		),
		"total_work" = 20,
		"desc" = "3 Metal + 2 Silver -> Welfare Department Headset",
		"category" = CRAFT_CAT_ELECTRONICS,
		"research_required" = "communications"
	)

	recipes["Disciplinary Headset"] = list(
		"result" = /obj/item/radio/headset/headset_discipline,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3,
			/obj/item/stack/sheet/mineral/silver = 2
		),
		"total_work" = 20,
		"desc" = "3 Metal + 2 Silver -> Disciplinary Department Headset",
		"category" = CRAFT_CAT_ELECTRONICS,
		"research_required" = "communications"
	)

	recipes["Extraction Headset"] = list(
		"result" = /obj/item/radio/headset/headset_extraction,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3,
			/obj/item/stack/sheet/mineral/silver = 2
		),
		"total_work" = 20,
		"desc" = "3 Metal + 2 Silver -> Extraction Department Headset",
		"category" = CRAFT_CAT_ELECTRONICS,
		"research_required" = "communications"
	)

	recipes["Records Headset"] = list(
		"result" = /obj/item/radio/headset/headset_records,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3,
			/obj/item/stack/sheet/mineral/silver = 2
		),
		"total_work" = 20,
		"desc" = "3 Metal + 2 Silver -> Records Department Headset",
		"category" = CRAFT_CAT_ELECTRONICS,
		"research_required" = "communications"
	)

	recipes["Architecture Headset"] = list(
		"result" = /obj/item/radio/headset/headset_architecture,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3,
			/obj/item/stack/sheet/mineral/silver = 2
		),
		"total_work" = 20,
		"desc" = "3 Metal + 2 Silver -> Architecture Department Headset",
		"category" = CRAFT_CAT_ELECTRONICS,
		"research_required" = "communications"
	)

/obj/structure/resurgence_crafting_table/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	ui_interact(user)
	return TRUE

// ===== TGUI Interface =====

/obj/structure/resurgence_crafting_table/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ResurgenceCrafting", name)
		ui.open()

/obj/structure/resurgence_crafting_table/ui_data(mob/user)
	var/list/data = list()

	data["busy"] = busy
	data["action_verb"] = action_verb
	data["busy_verb"] = busy_verb
	data["ui_color"] = ui_color

	// Current craft in progress
	data["has_craft_in_progress"] = (current_recipe_name != null)
	data["current_recipe"] = current_recipe_name
	data["current_work"] = current_work
	data["total_work"] = total_work_needed
	data["progress_percent"] = total_work_needed > 0 ? round((current_work / total_work_needed) * 100) : 0

	// Batch crafting info
	data["target_copies"] = target_copies
	data["completed_copies"] = completed_copies

	// Hide locked recipes toggle
	data["hide_locked_recipes"] = hide_locked_recipes

	// Pagination state
	data["current_page"] = ui_current_page
	data["search_text"] = ui_search_text
	data["active_category"] = ui_active_category

	// Build categories list first (always needed)
	var/list/categories = list("All")
	for(var/recipe_name in recipes)
		var/list/recipe = recipes[recipe_name]
		var/category = recipe["category"] || "Other"
		if(!(category in categories))
			categories += category
	data["categories"] = categories

	// OPTIMIZATION: When busy, only send pagination info, not recipe data
	if(busy)
		data["recipes"] = list()
		data["total_recipes"] = 0
		data["total_pages"] = 1
		data["skip_recipes"] = TRUE
		return data

	// SERVER-SIDE FILTERING: Filter recipes based on search and category
	var/list/filtered_names = list()
	var/search_lower = lowertext(ui_search_text)

	for(var/recipe_name in recipes)
		var/list/recipe = recipes[recipe_name]
		var/category = recipe["category"] || "Other"

		// Hide locked recipes filter
		if(hide_locked_recipes && !is_recipe_available(recipe_name))
			continue

		// Category filter (skip if searching)
		if(!ui_search_text && ui_active_category != "All" && category != ui_active_category)
			continue

		// Search filter
		if(ui_search_text)
			var/matches = FALSE
			if(findtext(lowertext(recipe_name), search_lower))
				matches = TRUE
			else if(findtext(lowertext(recipe["desc"]), search_lower))
				matches = TRUE
			else
				// Check material names
				for(var/mat_type in recipe["materials"])
					var/mat_name = get_material_name(mat_type)
					if(findtext(lowertext(mat_name), search_lower))
						matches = TRUE
						break
			if(!matches)
				continue

		filtered_names += recipe_name

	// Pagination calculations
	var/total_recipes = length(filtered_names)
	var/total_pages = max(1, CEILING(total_recipes / recipes_per_page, 1))

	// Clamp current page to valid range
	if(ui_current_page > total_pages)
		ui_current_page = total_pages
	if(ui_current_page < 1)
		ui_current_page = 1

	var/start_index = (ui_current_page - 1) * recipes_per_page + 1
	var/end_index = min(start_index + recipes_per_page - 1, total_recipes)

	data["total_recipes"] = total_recipes
	data["total_pages"] = total_pages
	data["current_page"] = ui_current_page

	// Cache material counts - only for materials used in visible recipes
	var/list/material_cache = list()

	// Build recipe data ONLY for the current page
	var/list/recipe_data = list()
	for(var/i in start_index to end_index)
		if(i > length(filtered_names))
			break
		var/recipe_name = filtered_names[i]
		var/list/recipe = recipes[recipe_name]
		var/list/materials = recipe["materials"]

		var/list/mat_data = list()
		var/can_craft = TRUE
		var/max_craftable = 999

		for(var/mat_type in materials)
			var/needed = materials[mat_type]
			var/have
			var/cache_key = "[mat_type]"
			if(cache_key in material_cache)
				have = material_cache[cache_key]
			else
				have = count_materials(user, mat_type)
				material_cache[cache_key] = have
			var/mat_name = get_material_name(mat_type)

			mat_data += list(list(
				"name" = mat_name,
				"needed" = needed,
				"have" = have,
				"enough" = (have >= needed)
			))

			if(have < needed)
				can_craft = FALSE

			if(needed > 0)
				var/possible = round(have / needed)
				max_craftable = min(max_craftable, possible)

		// Check research lock status
		var/is_locked = !is_recipe_available(recipe_name)
		var/lock_reason = get_recipe_lock_reason(recipe_name)

		recipe_data += list(list(
			"name" = recipe_name,
			"desc" = recipe["desc"],
			"result_amount" = recipe["result_amount"],
			"total_work" = recipe["total_work"],
			"materials" = mat_data,
			"can_craft" = can_craft && !is_locked,
			"max_craftable" = max_craftable,
			"category" = recipe["category"] || "Other",
			"is_locked" = is_locked,
			"lock_reason" = lock_reason
		))

	data["recipes"] = recipe_data
	data["skip_recipes"] = FALSE

	return data

/obj/structure/resurgence_crafting_table/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("start_craft")
			var/recipe_name = params["recipe"]
			var/quantity = text2num(params["quantity"]) || 1
			quantity = clamp(quantity, 1, 99) // Safety limit
			start_new_craft(usr, recipe_name, quantity)
			return TRUE

		if("continue_craft")
			continue_craft(usr)
			return TRUE

		if("cancel_craft")
			cancel_craft(usr)
			return TRUE

		// Pagination actions
		if("set_page")
			var/new_page = text2num(params["page"]) || 1
			ui_current_page = max(1, new_page)
			return TRUE

		if("set_search")
			ui_search_text = params["search"] || ""
			ui_current_page = 1  // Reset to first page on search
			return TRUE

		if("set_category")
			ui_active_category = params["category"] || "All"
			ui_current_page = 1  // Reset to first page on category change
			return TRUE

		if("toggle_hide_locked")
			hide_locked_recipes = !hide_locked_recipes
			ui_current_page = 1  // Reset to first page
			return TRUE

	return FALSE

/// Start a new craft - consumes materials for first copy and sets up progress tracking
/obj/structure/resurgence_crafting_table/proc/start_new_craft(mob/user, recipe_name, quantity = 1)
	if(busy)
		to_chat(user, span_warning("Someone is already working at the [name]."))
		return FALSE

	if(current_recipe_name)
		to_chat(user, span_warning("There's already a [current_recipe_name] in progress. Finish or cancel it first."))
		return FALSE

	var/list/recipe = recipes[recipe_name]
	if(!recipe)
		return FALSE

	// Check research requirements
	if(!is_recipe_available(recipe_name))
		var/lock_reason = get_recipe_lock_reason(recipe_name)
		to_chat(user, span_warning("This recipe requires research: [lock_reason]!"))
		return FALSE

	var/list/materials = recipe["materials"]

	// Check if user has required materials for at least one copy
	if(!check_materials(user, materials))
		to_chat(user, span_warning("You don't have the required materials for [recipe_name]."))
		return FALSE

	// Consume materials for first copy only (per-copy consumption)
	consume_materials(user, materials)

	// Set up the craft
	current_recipe_name = recipe_name
	current_recipe_data = recipe.Copy()
	current_work = 0
	total_work_needed = recipe["total_work"]

	// Set up batch crafting
	target_copies = quantity
	completed_copies = 0

	if(target_copies > 1)
		to_chat(user, span_notice("You begin working on [recipe_name] (1 of [target_copies]). Materials consumed. ([total_work_needed] work needed)"))
	else
		to_chat(user, span_notice("You begin working on [recipe_name]. Materials consumed. ([total_work_needed] work needed)"))
	playsound(src, 'sound/items/deconstruct.ogg', 30, TRUE)

	SStgui.update_uis(src)

	// Immediately start the first work session
	continue_craft(user)
	return TRUE

/// Continue working on the current craft - auto-continues until interrupted or complete
/obj/structure/resurgence_crafting_table/proc/continue_craft(mob/user)
	if(busy)
		to_chat(user, span_warning("Someone is already working at the [name]."))
		return FALSE

	if(!current_recipe_name)
		to_chat(user, span_warning("There's nothing being crafted here."))
		return FALSE

	// Check faith before starting
	if(!check_user_faith(user))
		to_chat(user, span_warning("You're too exhausted to craft. Need more than [MIN_FAITH_FOR_CRAFTING] faith."))
		return FALSE

	busy = TRUE
	on_craft_start()
	SStgui.update_uis(src)

	if(target_copies > 1)
		to_chat(user, span_notice("You continue [busy_verb] [current_recipe_name] ([completed_copies + 1] of [target_copies])..."))
	else
		to_chat(user, span_notice("You continue [busy_verb] [current_recipe_name]..."))

	// Warn about reduced efficiency if not in workshop
	if(is_at_reduced_efficiency())
		to_chat(user, span_warning("Working outside a workshop - [outdoor_penalty]x slower!"))

	// Warn about accelerated crafting mode (checked on user's core)
	if(is_user_accelerated(user))
		to_chat(user, span_boldwarning("Accelerated Crafting active - 2x speed, 3x faith drain!"))

	// Auto-continue loop - keeps working until interrupted or all copies complete
	while(current_recipe_name)
		// Check faith each tick
		if(!check_user_faith(user))
			to_chat(user, span_warning("You're too exhausted to continue. Progress saved."))
			break

		var/work_time = get_work_time(user)
		if(!do_after(user, work_time, target = src))
			// Player was interrupted
			to_chat(user, span_warning("You stop [busy_verb]. Progress saved."))
			break

		// Add work points (base + crafting stat bonus)
		var/work_done = get_work_per_session(user)
		current_work += work_done

		// Drain faith - base 0.4 per 2s interval (same rate as old 5s intervals)
		// 3x if user has acceleration active
		var/base_faith = 0.4
		var/faith_drain = is_user_accelerated(user) ? (base_faith * ACCELERATION_FAITH_MULT) : base_faith
		apply_work_faith_drain(user, faith_drain)

		// Award crafting XP for work done
		award_crafting_xp(user, work_done)

		// Check if this copy is complete
		if(current_work >= total_work_needed)
			// Create the result for this copy (pass user for trait bonuses)
			create_result(user, current_recipe_data, user)
			completed_copies++

			if(completed_copies >= target_copies)
				// All copies complete!
				complete_batch(user)
				break
			else
				// Try to start the next copy
				if(!start_next_copy(user))
					// Out of materials
					break
				// Update UI only when starting a new copy
				SStgui.update_uis(src)

		// Note: We don't update UI every tick - only on completion or interruption

	busy = FALSE
	on_craft_stop()
	SStgui.update_uis(src)
	return TRUE

/// Start the next copy in a batch - consumes materials and resets work progress
/obj/structure/resurgence_crafting_table/proc/start_next_copy(mob/user)
	if(!current_recipe_data)
		return FALSE

	var/list/materials = current_recipe_data["materials"]

	// Check if user has materials for another copy
	if(!check_materials(user, materials))
		to_chat(user, span_warning("Completed [completed_copies]/[target_copies] copies. Out of materials for more."))
		reset_craft_state()
		return FALSE

	// Consume materials for this copy
	consume_materials(user, materials)

	// Reset work progress for new copy
	current_work = 0

	to_chat(user, span_notice("Starting copy [completed_copies + 1] of [target_copies]..."))
	return TRUE

/// Complete a batch of crafts (all copies done)
/obj/structure/resurgence_crafting_table/proc/complete_batch(mob/user)
	if(!current_recipe_name)
		return

	if(completed_copies > 1)
		to_chat(user, span_notice("<b>Complete!</b> You finish [busy_verb] [completed_copies]x [current_recipe_name]."))
	else
		to_chat(user, span_notice("<b>Complete!</b> You finish [busy_verb] [current_recipe_name]."))
	playsound(src, complete_sound, 50, TRUE)

	reset_craft_state()

/// Reset all crafting state
/obj/structure/resurgence_crafting_table/proc/reset_craft_state()
	current_recipe_name = null
	current_recipe_data = null
	current_work = 0
	total_work_needed = 0
	target_copies = 1
	completed_copies = 0

/// Cancel the current craft (materials for current copy are lost)
/obj/structure/resurgence_crafting_table/proc/cancel_craft(mob/user)
	if(busy)
		to_chat(user, span_warning("Someone is currently working. Wait for them to stop first."))
		return FALSE

	if(!current_recipe_name)
		to_chat(user, span_warning("There's nothing being crafted here."))
		return FALSE

	if(completed_copies > 0)
		to_chat(user, span_warning("You cancel the [current_recipe_name]. [completed_copies] copies were completed. Materials for the current copy are lost."))
	else
		to_chat(user, span_warning("You cancel the [current_recipe_name]. The materials are lost."))
	playsound(src, 'sound/items/deconstruct.ogg', 30, TRUE)

	reset_craft_state()
	on_craft_stop()

	SStgui.update_uis(src)
	return TRUE

/// Called when crafting starts - override for visual effects (e.g., forge lights up)
/obj/structure/resurgence_crafting_table/proc/on_craft_start()
	return

/// Called when crafting stops - override for visual effects (e.g., forge dims)
/obj/structure/resurgence_crafting_table/proc/on_craft_stop()
	return

/// Check if an item matches the required material type
/obj/structure/resurgence_crafting_table/proc/item_matches_material(obj/item/I, material_type)
	if(!istype(I, material_type))
		return FALSE
	// Special case: cotton should NOT match cloth (cloth is a subtype of cotton)
	if(material_type == /obj/item/stack/sheet/cotton)
		if(istype(I, /obj/item/stack/sheet/cotton/cloth))
			return FALSE
	return TRUE

/// Count how many of a material type the user has available
/obj/structure/resurgence_crafting_table/proc/count_materials(mob/living/carbon/human/user, material_type)
	if(!istype(user))
		return 0

	var/found = 0

	// Check hands
	for(var/obj/item/I in user.held_items)
		if(item_matches_material(I, material_type))
			if(istype(I, /obj/item/stack))
				var/obj/item/stack/S = I
				found += S.amount
			else
				found += 1

	// Check backpack/storage
	var/obj/item/storage/backpack = user.get_item_by_slot(ITEM_SLOT_BACK)
	if(istype(backpack))
		for(var/obj/item/I in backpack.contents)
			if(item_matches_material(I, material_type))
				if(istype(I, /obj/item/stack))
					var/obj/item/stack/S = I
					found += S.amount
				else
					found += 1

	// Check nearby closed closets/crates
	for(var/obj/structure/closet/C in range(1, src))
		if(!C.opened)
			for(var/obj/item/I in C.contents)
				if(item_matches_material(I, material_type))
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
		// Mineral sheets
		if(/obj/item/stack/sheet/mineral/silver)
			return "Silver"
		if(/obj/item/stack/sheet/mineral/gold)
			return "Gold"
		if(/obj/item/stack/sheet/mineral/sandstone)
			return "Sandstone"
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
		if(/obj/item/stack/ore/rock)
			return "Rock"
		if(/obj/item/stack/sheet/mineral/coal)
			return "Coal"
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
		if(/obj/item/resurgence_component/ash_plating)
			return "Ash Plating"
		// Resurgence tools
		if(/obj/item/harvester/simple)
			return "Simple Harvester"
		else
			// Fallback: get the name from the type
			var/obj/item/temp = material_type
			return initial(temp.name)

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

	// Clumsy trait check - 15% chance to waste 1 extra material per type
	var/clumsy_wasted = FALSE
	if(check_trait_craft_waste(user))
		clumsy_wasted = TRUE
		to_chat(user, span_warning("You fumble and waste some materials!"))

	for(var/material_type in materials)
		// Add 1 to needed if clumsy wasted (but only if we have extra)
		var/extra_waste = 0
		if(clumsy_wasted)
			var/available = count_materials(user, material_type)
			if(available > materials[material_type])
				extra_waste = 1
		var/needed = materials[material_type] + extra_waste

		// Consume from hands first
		for(var/obj/item/I in user.held_items)
			if(needed <= 0)
				break
			if(item_matches_material(I, material_type))
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
				if(item_matches_material(I, material_type))
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
				if(!C.opened)
					for(var/obj/item/I in C.contents)
						if(needed <= 0)
							break
						if(item_matches_material(I, material_type))
							if(istype(I, /obj/item/stack))
								var/obj/item/stack/S = I
								var/to_use = min(S.amount, needed)
								S.use(to_use)
								needed -= to_use
							else
								qdel(I)
								needed -= 1

/// Create the crafted result
/obj/structure/resurgence_crafting_table/proc/create_result(mob/crafter, list/recipe, mob/user = null)
	var/result_type = recipe["result"]
	var/result_amount = recipe["result_amount"]

	// Get crafter's skill level for quality tier rolling
	var/crafting_skill = 1
	if(ishuman(crafter))
		var/mob/living/carbon/human/H = crafter
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			crafting_skill = core.stat_crafting

	if(ispath(result_type, /obj/item/stack))
		// Create a stack with the correct amount
		new result_type(get_turf(src), result_amount)
	else
		// Create individual items
		for(var/i in 1 to result_amount)
			var/obj/item/created = new result_type(get_turf(src))
			// Apply quality tier to tools and harvesters (pass user for trait bonuses)
			apply_quality_to_crafted(created, crafting_skill, user)

/// Apply quality tier to crafted tools based on crafter's skill
/obj/structure/resurgence_crafting_table/proc/apply_quality_to_crafted(obj/item/crafted, crafting_skill, mob/user = null)
	if(!crafted)
		return

	// Roll quality tier based on crafter's skill
	var/quality = roll_quality_tier(crafting_skill)

	// Apply global quality bonus from events (clamped to 1-5 range)
	quality = clamp(quality + GLOB.resurgence_quality_bonus, 1, 5)

	// Apply Meticulous trait bonus (+1 tool quality)
	if(ishuman(user))
		quality = clamp(quality + get_trait_tool_quality_bonus(user), 1, 5)

	// Apply to harvesters
	if(istype(crafted, /obj/item/harvester))
		var/obj/item/harvester/H = crafted
		H.set_quality_tier(quality)
		return

	// Apply to tools with durability
	if(istype(crafted, /obj/item/hatchet))
		set_tool_quality_tier(crafted, quality)
		return
	if(istype(crafted, /obj/item/pickaxe))
		set_tool_quality_tier(crafted, quality)
		return
	if(istype(crafted, /obj/item/scythe))
		set_tool_quality_tier(crafted, quality)
		return
	if(istype(crafted, /obj/item/shovel))
		set_tool_quality_tier(crafted, quality)
		return
	if(istype(crafted, /obj/item/crowbar))
		set_tool_quality_tier(crafted, quality)
		return

/// Award crafting XP to a player
/obj/structure/resurgence_crafting_table/proc/award_crafting_xp(mob/user, amount)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(istype(core))
		core.award_xp("crafting", amount)

/obj/structure/resurgence_crafting_table/examine(mob/user)
	. = ..()
	. += span_notice("Click to open the crafting menu.")
	if(current_recipe_name)
		if(target_copies > 1)
			. += span_notice("Currently [busy_verb] [current_recipe_name] (copy [completed_copies + 1] of [target_copies], [current_work]/[total_work_needed] work).")
		else
			. += span_notice("Currently [busy_verb] [current_recipe_name] ([current_work]/[total_work_needed] work complete).")
		if(!busy)
			. += span_notice("Anyone can continue working on it.")
	if(is_at_reduced_efficiency())
		. += span_warning("Not in a workshop - crafting is [outdoor_penalty]x slower!")
	else if(requires_workshop)
		. += span_notice("In a workshop - crafting at full speed.")

// ===== Portable Crafting Table =====
// Does not require a workshop - works at full speed anywhere

/obj/structure/resurgence_crafting_table/portable
	name = "portable crafting table"
	desc = "A compact workbench that can be used anywhere. Less efficient than a proper workshop station, but functional outdoors."
	requires_workshop = FALSE

#undef WORK_SESSION_TIME
#undef WORK_PER_SESSION
#undef CRAFTING_WORK_PER_LEVEL
#undef ACCELERATION_FAITH_MULT
#undef MIN_FAITH_FOR_CRAFTING
#undef CRAFT_CAT_PROCESSING
#undef CRAFT_CAT_TOOLS
#undef CRAFT_CAT_FLOORING
#undef CRAFT_CAT_ART
#undef CRAFT_CAT_PAPERWORK
#undef CRAFT_CAT_CLEANING
#undef CRAFT_CAT_MUSIC
#undef CRAFT_CAT_ELECTRONICS
