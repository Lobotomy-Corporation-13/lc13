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
#define WORK_SESSION_TIME 5 SECONDS
/// How many work points are added per session (at base speed)
#define WORK_PER_SESSION 5

/// Crafting recipe categories
#define CRAFT_CAT_PROCESSING "Processing"
#define CRAFT_CAT_TOOLS "Tools"
#define CRAFT_CAT_FLOORING "Flooring"
#define CRAFT_CAT_ART "Art"
#define CRAFT_CAT_PAPERWORK "Paperwork"

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

/obj/structure/resurgence_crafting_table/Initialize(mapload)
	. = ..()
	if(!recipes)
		init_recipes()

/// Get the work session time, accounting for workshop bonus and player stats
/obj/structure/resurgence_crafting_table/proc/get_work_time(mob/user = null)
	var/base_time = WORK_SESSION_TIME

	// Apply workshop penalty if required
	if(requires_workshop && !is_in_workshop(src))
		base_time *= outdoor_penalty

	// Apply crafting stat speed modifier if user is a resurgence machine
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			var/stat_mod = get_stat_speed_modifier(core.stat_crafting)
			base_time *= stat_mod

	return base_time

/// Check if crafting is at reduced efficiency (not in workshop when required)
/obj/structure/resurgence_crafting_table/proc/is_at_reduced_efficiency()
	if(!requires_workshop)
		return FALSE
	return !is_in_workshop(src)

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
		"category" = CRAFT_CAT_TOOLS
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
		"category" = CRAFT_CAT_TOOLS
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
		"category" = CRAFT_CAT_FLOORING
	)

	// Carpet Tiles
	recipes["Black Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/black,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"total_work" = 10,
		"desc" = "2 Cloth -> 4 Black Carpet",
		"category" = CRAFT_CAT_FLOORING
	)

	recipes["Blue Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/blue,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"total_work" = 10,
		"desc" = "2 Cloth -> 4 Blue Carpet",
		"category" = CRAFT_CAT_FLOORING
	)

	recipes["Cyan Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/cyan,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"total_work" = 10,
		"desc" = "2 Cloth -> 4 Cyan Carpet",
		"category" = CRAFT_CAT_FLOORING
	)

	recipes["Green Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/green,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"total_work" = 10,
		"desc" = "2 Cloth -> 4 Green Carpet",
		"category" = CRAFT_CAT_FLOORING
	)

	recipes["Orange Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/orange,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"total_work" = 10,
		"desc" = "2 Cloth -> 4 Orange Carpet",
		"category" = CRAFT_CAT_FLOORING
	)

	recipes["Purple Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/purple,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"total_work" = 10,
		"desc" = "2 Cloth -> 4 Purple Carpet",
		"category" = CRAFT_CAT_FLOORING
	)

	recipes["Red Carpet"] = list(
		"result" = /obj/item/stack/tile/carpet/red,
		"result_amount" = 4,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"total_work" = 10,
		"desc" = "2 Cloth -> 4 Red Carpet",
		"category" = CRAFT_CAT_FLOORING
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
		"category" = CRAFT_CAT_FLOORING
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
		"category" = CRAFT_CAT_FLOORING
	)

	// Art Supplies
	recipes["Canvas (11x11)"] = list(
		"result" = /obj/item/canvas,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 2),
		"total_work" = 10,
		"desc" = "2 Cloth -> Small Canvas (11x11)",
		"category" = CRAFT_CAT_ART
	)

	recipes["Canvas (19x19)"] = list(
		"result" = /obj/item/canvas/nineteen_nineteen,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 3),
		"total_work" = 15,
		"desc" = "3 Cloth -> Medium Canvas (19x19)",
		"category" = CRAFT_CAT_ART
	)

	recipes["Canvas (23x19)"] = list(
		"result" = /obj/item/canvas/twentythree_nineteen,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 4),
		"total_work" = 15,
		"desc" = "4 Cloth -> Wide Canvas (23x19)",
		"category" = CRAFT_CAT_ART
	)

	recipes["Canvas (23x23)"] = list(
		"result" = /obj/item/canvas/twentythree_twentythree,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 5),
		"total_work" = 20,
		"desc" = "5 Cloth -> Large Canvas (23x23)",
		"category" = CRAFT_CAT_ART
	)

	recipes["Painting Frame"] = list(
		"result" = /obj/item/wallframe/painting/resurgence,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/mineral/wood = 2),
		"total_work" = 10,
		"desc" = "2 Wood -> Painting Frame (wall mount for canvases, paintings preserved)",
		"category" = CRAFT_CAT_ART
	)

	// Paperwork - Pens
	recipes["Pen (Black)"] = list(
		"result" = /obj/item/pen,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/metal = 1),
		"total_work" = 5,
		"desc" = "1 Metal -> Black Pen",
		"category" = CRAFT_CAT_PAPERWORK
	)

	recipes["Pen (Blue)"] = list(
		"result" = /obj/item/pen/blue,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/metal = 1),
		"total_work" = 5,
		"desc" = "1 Metal -> Blue Pen",
		"category" = CRAFT_CAT_PAPERWORK
	)

	recipes["Pen (Red)"] = list(
		"result" = /obj/item/pen/red,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/metal = 1),
		"total_work" = 5,
		"desc" = "1 Metal -> Red Pen",
		"category" = CRAFT_CAT_PAPERWORK
	)

	recipes["Pen (Invisible)"] = list(
		"result" = /obj/item/pen/invisible,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/metal = 1),
		"total_work" = 5,
		"desc" = "1 Metal -> Invisible Ink Pen",
		"category" = CRAFT_CAT_PAPERWORK
	)

	recipes["Four-Color Pen"] = list(
		"result" = /obj/item/pen/fourcolor,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/metal = 2),
		"total_work" = 10,
		"desc" = "2 Metal -> Four-Color Pen",
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
	)

	recipes["Charcoal Stylus"] = list(
		"result" = /obj/item/pen/charcoal,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/mineral/wood = 1),
		"total_work" = 5,
		"desc" = "1 Wood -> Charcoal Stylus",
		"category" = CRAFT_CAT_PAPERWORK
	)

	// Paperwork - Paper & Storage
	recipes["Paper"] = list(
		"result" = /obj/item/paper,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 1),
		"total_work" = 5,
		"desc" = "1 Cloth -> Paper",
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
	)

	recipes["Empty Paper Bin"] = list(
		"result" = /obj/item/paper_bin/empty,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/mineral/wood = 3),
		"total_work" = 10,
		"desc" = "3 Wood -> Empty Paper Bin",
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
	)

	recipes["Hand Labeler Refill"] = list(
		"result" = /obj/item/hand_labeler_refill,
		"result_amount" = 1,
		"materials" = list(/obj/item/stack/sheet/cotton/cloth = 1),
		"total_work" = 5,
		"desc" = "1 Cloth -> Hand Labeler Refill",
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
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
		"category" = CRAFT_CAT_PAPERWORK
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

	// OPTIMIZATION: When busy or craft in progress, skip expensive recipe rebuilding
	// The user can't start new crafts anyway, and the UI will use cached data
	if(busy)
		data["recipes"] = list()
		data["categories"] = list()
		data["skip_recipes"] = TRUE
		return data

	// Cache material counts - count each unique material type only once
	var/list/material_cache = list()

	// Build recipe list with availability info, organized by category
	var/list/recipe_data = list()
	var/list/categories = list()
	for(var/recipe_name in recipes)
		var/list/recipe = recipes[recipe_name]
		var/list/materials = recipe["materials"]
		var/category = recipe["category"] || "Other"

		// Track unique categories
		if(!(category in categories))
			categories += category

		var/list/mat_data = list()
		var/can_craft = TRUE
		var/max_craftable = 999 // Will be reduced by limiting material

		for(var/mat_type in materials)
			var/needed = materials[mat_type]
			// Use cached count if available, otherwise count and cache
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

			// Calculate max craftable based on this material
			if(needed > 0)
				var/possible = round(have / needed)
				max_craftable = min(max_craftable, possible)

		recipe_data += list(list(
			"name" = recipe_name,
			"desc" = recipe["desc"],
			"result_amount" = recipe["result_amount"],
			"total_work" = recipe["total_work"],
			"materials" = mat_data,
			"can_craft" = can_craft,
			"max_craftable" = max_craftable,
			"category" = category
		))

	data["recipes"] = recipe_data
	data["categories"] = categories
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

	// Auto-continue loop - keeps working until interrupted or all copies complete
	while(current_recipe_name)
		var/work_time = get_work_time(user)
		if(!do_after(user, work_time, target = src))
			// Player was interrupted
			to_chat(user, span_warning("You stop [busy_verb]. Progress saved."))
			break

		// Add work points (base amount, could be modified by skills/tools later)
		current_work += WORK_PER_SESSION

		// Drain small amount of faith per work session (0.1 per session)
		apply_work_faith_drain(user, 1)

		// Award crafting XP for work done
		award_crafting_xp(user, WORK_PER_SESSION)

		// Check if this copy is complete
		if(current_work >= total_work_needed)
			// Create the result for this copy
			create_result(user, current_recipe_data)
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

	for(var/material_type in materials)
		var/needed = materials[material_type]

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
#undef CRAFT_CAT_PROCESSING
#undef CRAFT_CAT_TOOLS
#undef CRAFT_CAT_FLOORING
#undef CRAFT_CAT_ART
#undef CRAFT_CAT_PAPERWORK
