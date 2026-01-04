/**
 * Resurgence Outpost - Blueprint Types
 *
 * Specific blueprint subtypes for each buildable structure.
 * Each defines the materials needed and the result structure.
 * Icons match the actual result types for visual consistency.
 */

// ===========================================
// CONSTRUCTION BLUEPRINTS
// ===========================================

/obj/structure/resurgence_blueprint/wood_wall
	name = "wood wall blueprint"
	result_name = "wood wall"
	icon = 'icons/turf/walls/wood_wall.dmi'
	icon_state = "wood_wall-0"
	result_type = /turf/closed/wall/mineral/wood

/obj/structure/resurgence_blueprint/wood_wall/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 5
	)

/obj/structure/resurgence_blueprint/reinforced_wall
	name = "reinforced wall blueprint"
	result_name = "reinforced wall"
	icon = 'icons/turf/walls/wall.dmi'
	icon_state = "wall-0"
	result_type = /turf/closed/wall
	research_required = "advanced_metallurgy"

/obj/structure/resurgence_blueprint/reinforced_wall/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 8,
		/obj/item/stack/sheet/plasteel = 4
	)

/obj/structure/resurgence_blueprint/wood_door
	name = "wood door blueprint"
	result_name = "wood door"
	icon = 'icons/obj/doors/mineral_doors.dmi'
	icon_state = "wood"
	result_type = /obj/structure/mineral_door/wood

/obj/structure/resurgence_blueprint/wood_door/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 10
	)

/obj/structure/resurgence_blueprint/iron_door
	name = "iron door blueprint"
	result_name = "iron door"
	icon = 'icons/obj/doors/mineral_doors.dmi'
	icon_state = "metal"
	result_type = /obj/structure/mineral_door/iron
	research_required = "metallurgy"

/obj/structure/resurgence_blueprint/iron_door/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 8
	)

/obj/structure/resurgence_blueprint/silver_door
	name = "silver door blueprint"
	result_name = "silver door"
	icon = 'icons/obj/doors/mineral_doors.dmi'
	icon_state = "silver"
	result_type = /obj/structure/mineral_door/silver
	research_required = "luxury_decor"

/obj/structure/resurgence_blueprint/silver_door/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/silver = 8
	)

/obj/structure/resurgence_blueprint/gold_door
	name = "gold door blueprint"
	result_name = "gold door"
	icon = 'icons/obj/doors/mineral_doors.dmi'
	icon_state = "gold"
	result_type = /obj/structure/mineral_door/gold
	research_required = "luxury_decor"

/obj/structure/resurgence_blueprint/gold_door/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/gold = 8
	)

/obj/structure/resurgence_blueprint/sandstone_door
	name = "sandstone door blueprint"
	result_name = "sandstone door"
	icon = 'icons/obj/doors/mineral_doors.dmi'
	icon_state = "sandstone"
	result_type = /obj/structure/mineral_door/sandstone

/obj/structure/resurgence_blueprint/sandstone_door/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/sandstone = 10
	)

// ===========================================
// FLOOR BLUEPRINTS
// ===========================================

/obj/structure/resurgence_blueprint/wood_floor
	name = "wood floor blueprint"
	result_name = "wood floor"
	icon = 'icons/turf/floors.dmi'
	icon_state = "wood"
	result_type = /turf/open/floor/wood

/obj/structure/resurgence_blueprint/wood_floor/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 2
	)

/obj/structure/resurgence_blueprint/iron_floor
	name = "iron floor blueprint"
	result_name = "iron floor"
	icon = 'icons/turf/floors.dmi'
	icon_state = "stone_floor"
	result_type = /turf/open/floor/stone
	research_required = "metallurgy"

/obj/structure/resurgence_blueprint/iron_floor/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 2
	)

/obj/structure/resurgence_blueprint/sandstone_floor
	name = "sandstone floor blueprint"
	result_name = "sandstone floor"
	icon = 'icons/turf/floors.dmi'
	icon_state = "sandstone_floor"
	result_type = /turf/open/floor/sandstone

/obj/structure/resurgence_blueprint/sandstone_floor/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/sandstone = 2
	)

/obj/structure/resurgence_blueprint/iron_wall
	name = "iron wall blueprint"
	result_name = "iron wall"
	icon = 'icons/turf/walls/iron_wall.dmi'
	icon_state = "iron_wall-0"
	result_type = /turf/closed/wall/mineral/iron
	research_required = "metallurgy"

/obj/structure/resurgence_blueprint/iron_wall/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 4
	)

/obj/structure/resurgence_blueprint/sandstone_wall
	name = "sandstone wall blueprint"
	result_name = "sandstone wall"
	icon = 'icons/turf/walls/sandstone_wall.dmi'
	icon_state = "sandstone_wall-0"
	result_type = /turf/closed/wall/mineral/sandstone

/obj/structure/resurgence_blueprint/sandstone_wall/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/sandstone = 5
	)

/obj/structure/resurgence_blueprint/gold_wall
	name = "gold wall blueprint"
	result_name = "gold wall"
	icon = 'icons/turf/walls/gold_wall.dmi'
	icon_state = "gold_wall-0"
	result_type = /turf/closed/wall/mineral/gold
	research_required = "luxury_decor"

/obj/structure/resurgence_blueprint/gold_wall/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/gold = 5
	)

/obj/structure/resurgence_blueprint/silver_wall
	name = "silver wall blueprint"
	result_name = "silver wall"
	icon = 'icons/turf/walls/silver_wall.dmi'
	icon_state = "silver_wall-0"
	result_type = /turf/closed/wall/mineral/silver
	research_required = "luxury_decor"

/obj/structure/resurgence_blueprint/silver_wall/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/silver = 5
	)

// ===========================================
// STORAGE BLUEPRINTS
// ===========================================

/obj/structure/resurgence_blueprint/storage_chest
	name = "wooden crate blueprint"
	result_name = "wooden crate"
	icon = 'icons/obj/crates.dmi'
	icon_state = "wooden"
	result_type = /obj/structure/closet/crate/wooden

/obj/structure/resurgence_blueprint/storage_chest/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 4
	)

/obj/structure/resurgence_blueprint/crate
	name = "metal crate blueprint"
	result_name = "metal crate"
	icon = 'icons/obj/crates.dmi'
	icon_state = "crate"
	result_type = /obj/structure/closet/crate
	research_required = "metallurgy"

/obj/structure/resurgence_blueprint/crate/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 4
	)

/obj/structure/resurgence_blueprint/barrel
	name = "large crate blueprint"
	result_name = "large crate"
	icon = 'icons/obj/crates.dmi'
	icon_state = "largecrate"
	result_type = /obj/structure/closet/crate/large
	research_required = "woodworking"

/obj/structure/resurgence_blueprint/barrel/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 6
	)

/obj/structure/resurgence_blueprint/freezer
	name = "freezer blueprint"
	result_name = "freezer"
	icon = 'icons/obj/crates.dmi'
	icon_state = "freezer"
	result_type = /obj/structure/closet/crate/freezer
	research_required = "storage_tech"

/obj/structure/resurgence_blueprint/freezer/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 6
	)

/obj/structure/resurgence_blueprint/trashcart
	name = "trash cart blueprint"
	result_name = "trash cart"
	icon = 'icons/obj/crates.dmi'
	icon_state = "trashcart"
	result_type = /obj/structure/closet/crate/trashcart
	unanchored_result = TRUE
	research_required = "cleaning"

/obj/structure/resurgence_blueprint/trashcart/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 4
	)

/obj/structure/resurgence_blueprint/coffin
	name = "coffin blueprint"
	result_name = "coffin"
	icon = 'icons/obj/crates.dmi'
	icon_state = "coffin"
	result_type = /obj/structure/closet/crate/coffin
	research_required = "woodworking"

/obj/structure/resurgence_blueprint/coffin/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 5
	)

/obj/structure/resurgence_blueprint/trashbin
	name = "trash bin blueprint"
	result_name = "trash bin"
	icon = 'icons/obj/crates.dmi'
	icon_state = "largebins"
	result_type = /obj/structure/closet/crate/bin
	research_required = "cleaning"

/obj/structure/resurgence_blueprint/trashbin/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 4
	)

/obj/structure/resurgence_blueprint/fridge
	name = "refrigerator blueprint"
	result_name = "refrigerator"
	icon = 'icons/obj/closet.dmi'
	icon_state = "freezer"
	result_type = /obj/structure/closet/secure_closet/freezer/fridge/open
	research_required = "storage_tech"

/obj/structure/resurgence_blueprint/fridge/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 8
	)

// ===========================================
// PRODUCTION BLUEPRINTS
// ===========================================

/obj/structure/resurgence_blueprint/crafting_table
	name = "crafting table blueprint"
	result_name = "crafting table"
	icon = 'icons/obj/cult.dmi'
	icon_state = "tomealtar"
	result_type = /obj/structure/resurgence_crafting_table
	research_required = "woodworking"

/obj/structure/resurgence_blueprint/crafting_table/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 15
	)

/obj/structure/resurgence_blueprint/forge
	name = "forge blueprint"
	result_name = "forge"
	icon = 'icons/obj/cult.dmi'
	icon_state = "forge_off"
	result_type = /obj/structure/resurgence_crafting_table/forge
	research_required = "metallurgy"

/obj/structure/resurgence_blueprint/forge/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 10,
		/obj/item/stack/sheet/mineral/wood = 10,
		/obj/item/resurgence_component/rope = 2
	)

/obj/structure/resurgence_blueprint/forge/primitive
	name = "primitive forge blueprint"
	result_name = "primitive forge"
	result_type = /obj/structure/resurgence_crafting_table/forge/primitive
	research_required = null  // Tier 0 - always available

/obj/structure/resurgence_blueprint/forge/primitive/init_materials()
	required_materials = list(
		/obj/item/stack/ore/rock = 50
	)

/obj/structure/resurgence_blueprint/loom
	name = "loom blueprint"
	result_name = "loom"
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "loom"
	result_type = /obj/structure/resurgence_crafting_table/loom
	research_required = "textiles"

/obj/structure/resurgence_blueprint/loom/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 5,
		/obj/item/stack/sheet/mineral/wood = 10,
		/obj/item/resurgence_component/rope = 4
	)

/obj/structure/resurgence_blueprint/loom/primitive
	name = "primitive loom blueprint"
	result_name = "primitive loom"
	result_type = /obj/structure/resurgence_crafting_table/loom/primitive
	research_required = null  // Tier 0 - always available

/obj/structure/resurgence_blueprint/loom/primitive/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 20,
		/obj/item/stack/resurgence_vines = 5
	)

/obj/structure/resurgence_blueprint/seed_extractor
	name = "seed extractor blueprint"
	result_name = "seed extractor"
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "sextractor"
	result_type = /obj/structure/resurgence_seed_extractor
	research_required = "agriculture"

/obj/structure/resurgence_blueprint/seed_extractor/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 5,
		/obj/item/stack/sheet/metal = 2
	)

/obj/structure/resurgence_blueprint/condiment_station
	name = "condiment station blueprint"
	result_name = "condiment station"
	icon = 'icons/obj/chemical.dmi'
	icon_state = "mixer0"
	result_type = /obj/structure/resurgence_kitchen/condiment_station
	research_required = "culinary"

/obj/structure/resurgence_blueprint/condiment_station/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 10,
		/obj/item/stack/sheet/glass = 5
	)

/obj/structure/resurgence_blueprint/meat_grinder
	name = "meat grinder blueprint"
	result_name = "meat grinder"
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "grinder"
	result_type = /obj/structure/resurgence_kitchen/meat_grinder
	research_required = "culinary"

/obj/structure/resurgence_blueprint/meat_grinder/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 15
	)

/obj/structure/resurgence_blueprint/food_processor
	name = "food processor blueprint"
	result_name = "food processor"
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "processor1"
	result_type = /obj/structure/resurgence_kitchen/food_processor
	research_required = "culinary"

/obj/structure/resurgence_blueprint/food_processor/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 12
	)

/obj/structure/resurgence_blueprint/stove
	name = "stove blueprint"
	result_name = "stove"
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "mw"
	result_type = /obj/structure/resurgence_kitchen/stove
	research_required = "culinary"

/obj/structure/resurgence_blueprint/stove/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 15
	)

/obj/structure/resurgence_blueprint/grinder
	name = "hand grinder blueprint"
	result_name = "hand grinder"
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "juicer1"
	result_type = /obj/structure/resurgence_kitchen/grinder
	research_required = "culinary"

/obj/structure/resurgence_blueprint/grinder/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 10,
		/obj/item/stack/sheet/glass = 3
	)

/obj/structure/resurgence_blueprint/griddle
	name = "griddle blueprint"
	result_name = "griddle"
	icon = 'icons/obj/machines/griddle.dmi'
	icon_state = "griddle1_off"
	result_type = /obj/structure/resurgence_kitchen/griddle
	research_required = "culinary"

/obj/structure/resurgence_blueprint/griddle/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 12
	)

// ===========================================
// FURNITURE BLUEPRINTS
// ===========================================

/obj/structure/resurgence_blueprint/bed
	name = "wooden sleeper blueprint"
	result_name = "wooden sleeper"
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_clockwork-open"
	result_type = /obj/structure/resurgence_bed
	// No research_required - Tier 0, always available

/obj/structure/resurgence_blueprint/bed/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 10
	)

/obj/structure/resurgence_blueprint/chair
	name = "chair blueprint"
	result_name = "chair"
	icon = 'icons/obj/chairs.dmi'
	icon_state = "wooden_chair"
	result_type = /obj/structure/chair/wood

/obj/structure/resurgence_blueprint/chair/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 3
	)

/obj/structure/resurgence_blueprint/table
	name = "table blueprint"
	result_name = "table"
	icon = 'icons/obj/smooth_structures/wood_table.dmi'
	icon_state = "wood_table-0"
	result_type = /obj/structure/table/wood

/obj/structure/resurgence_blueprint/table/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 4
	)

/obj/structure/resurgence_blueprint/table_frame
	name = "table frame blueprint"
	result_name = "table frame"
	icon = 'icons/obj/structures.dmi'
	icon_state = "nu_table_frame"
	result_type = /obj/structure/table_frame
	research_required = "woodworking"

/obj/structure/resurgence_blueprint/table_frame/init_materials()
	required_materials = list(
		/obj/item/stack/rods = 2
	)

/obj/structure/resurgence_blueprint/table_frame/wood
	name = "wooden table frame blueprint"
	result_name = "wooden table frame"
	icon = 'icons/obj/structures.dmi'
	icon_state = "wood_frame"
	result_type = /obj/structure/table_frame/wood
	research_required = null  // Tier 0 - always available

/obj/structure/resurgence_blueprint/table_frame/wood/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 2
	)

/obj/structure/resurgence_blueprint/rack
	name = "rack blueprint"
	result_name = "rack"
	icon = 'icons/obj/objects.dmi'
	icon_state = "rack"
	result_type = /obj/structure/rack

/obj/structure/resurgence_blueprint/rack/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 2
	)

/obj/structure/resurgence_blueprint/stool
	name = "stool blueprint"
	result_name = "stool"
	icon = 'icons/obj/chairs.dmi'
	icon_state = "stool"
	result_type = /obj/structure/chair/stool

/obj/structure/resurgence_blueprint/stool/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 1
	)

/obj/structure/resurgence_blueprint/bar_stool
	name = "bar stool blueprint"
	result_name = "bar stool"
	icon = 'icons/obj/chairs.dmi'
	icon_state = "bar"
	result_type = /obj/structure/chair/stool/bar
	research_required = "fine_furniture"

/obj/structure/resurgence_blueprint/bar_stool/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 1
	)

/obj/structure/resurgence_blueprint/comfy_chair
	name = "comfy chair blueprint"
	result_name = "comfy chair"
	icon = 'icons/obj/chairs.dmi'
	icon_state = "comfychair"
	result_type = /obj/structure/chair/comfy/beige
	research_required = "fine_furniture"

/obj/structure/resurgence_blueprint/comfy_chair/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 2
	)

/obj/structure/resurgence_blueprint/office_chair
	name = "office chair blueprint"
	result_name = "office chair"
	icon = 'icons/obj/chairs.dmi'
	icon_state = "officechair_dark"
	result_type = /obj/structure/chair/office
	research_required = "fine_furniture"

/obj/structure/resurgence_blueprint/office_chair/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 5
	)

/obj/structure/resurgence_blueprint/winged_chair
	name = "winged wooden chair blueprint"
	result_name = "winged wooden chair"
	icon = 'icons/obj/chairs.dmi'
	icon_state = "wooden_chair_wings"
	result_type = /obj/structure/chair/wood/wings
	research_required = "woodworking"

/obj/structure/resurgence_blueprint/winged_chair/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 3
	)

/obj/structure/resurgence_blueprint/sofa_middle
	name = "sofa (middle) blueprint"
	result_name = "sofa"
	icon = 'icons/obj/sofa.dmi'
	icon_state = "sofamiddle"
	result_type = /obj/structure/chair/sofa
	research_required = "fine_furniture"

/obj/structure/resurgence_blueprint/sofa_middle/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 1
	)

/obj/structure/resurgence_blueprint/sofa_left
	name = "sofa (left) blueprint"
	result_name = "sofa left end"
	icon = 'icons/obj/sofa.dmi'
	icon_state = "sofaend_left"
	result_type = /obj/structure/chair/sofa/left
	research_required = "fine_furniture"

/obj/structure/resurgence_blueprint/sofa_left/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 1
	)

/obj/structure/resurgence_blueprint/sofa_right
	name = "sofa (right) blueprint"
	result_name = "sofa right end"
	icon = 'icons/obj/sofa.dmi'
	icon_state = "sofaend_right"
	result_type = /obj/structure/chair/sofa/right
	research_required = "fine_furniture"

/obj/structure/resurgence_blueprint/sofa_right/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 1
	)

/obj/structure/resurgence_blueprint/sofa_corner
	name = "sofa (corner) blueprint"
	result_name = "sofa corner"
	icon = 'icons/obj/sofa.dmi'
	icon_state = "sofacorner"
	result_type = /obj/structure/chair/sofa/corner
	research_required = "fine_furniture"

/obj/structure/resurgence_blueprint/sofa_corner/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 1
	)

/obj/structure/resurgence_blueprint/pew
	name = "pew blueprint"
	result_name = "pew"
	icon = 'icons/obj/sofa.dmi'
	icon_state = "pewmiddle"
	result_type = /obj/structure/chair/pew
	research_required = "woodworking"

/obj/structure/resurgence_blueprint/pew/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 3
	)

/obj/structure/resurgence_blueprint/pew_left
	name = "pew (left) blueprint"
	result_name = "pew left end"
	icon = 'icons/obj/sofa.dmi'
	icon_state = "pewend_left"
	result_type = /obj/structure/chair/pew/left
	research_required = "woodworking"

/obj/structure/resurgence_blueprint/pew_left/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 3
	)

/obj/structure/resurgence_blueprint/pew_right
	name = "pew (right) blueprint"
	result_name = "pew right end"
	icon = 'icons/obj/sofa.dmi'
	icon_state = "pewend_right"
	result_type = /obj/structure/chair/pew/right
	research_required = "woodworking"

/obj/structure/resurgence_blueprint/pew_right/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 3
	)

/obj/structure/resurgence_blueprint/dresser
	name = "dresser blueprint"
	result_name = "dresser"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "dresser"
	result_type = /obj/structure/dresser
	research_required = "woodworking"

/obj/structure/resurgence_blueprint/dresser/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 10
	)

/obj/structure/resurgence_blueprint/bookcase
	name = "bookcase blueprint"
	result_name = "bookcase"
	icon = 'icons/obj/library.dmi'
	icon_state = "bookempty"
	result_type = /obj/structure/bookcase
	research_required = "woodworking"

/obj/structure/resurgence_blueprint/bookcase/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 35
	)

/obj/structure/resurgence_blueprint/dog_bed
	name = "dog bed blueprint"
	result_name = "dog bed"
	icon = 'icons/obj/objects.dmi'
	icon_state = "dogbed"
	result_type = /obj/structure/bed/dogbed
	research_required = "woodworking"

/obj/structure/resurgence_blueprint/dog_bed/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 10
	)

// ===========================================
// STORAGE BLUEPRINTS (ADDITIONAL)
// ===========================================

/obj/structure/resurgence_blueprint/ore_box
	name = "ore box blueprint"
	result_name = "ore box"
	icon = 'icons/obj/mining.dmi'
	icon_state = "orebox"
	result_type = /obj/structure/ore_box
	unanchored_result = TRUE
	research_required = "woodworking"

/obj/structure/resurgence_blueprint/ore_box/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 4
	)

// ===========================================
// LOGISTICS BLUEPRINTS
// ===========================================

/obj/structure/resurgence_blueprint/resources_recorder
	name = "resources recorder blueprint"
	result_name = "resources recorder"
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "console"
	result_type = /obj/structure/resources_recorder
	density = FALSE
	research_required = "machine_fabrication"

	/// Direction towards the wall this console will be mounted on
	var/wall_dir = SOUTH

/obj/structure/resurgence_blueprint/resources_recorder/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 15,
		/obj/item/stack/sheet/glass = 5
	)

/obj/structure/resurgence_blueprint/resources_recorder/Initialize(mapload, wall_direction)
	. = ..()
	if(wall_direction)
		wall_dir = wall_direction
	apply_wall_offset()

/// Apply pixel offset to match wall placement
/obj/structure/resurgence_blueprint/resources_recorder/proc/apply_wall_offset()
	switch(wall_dir)
		if(NORTH)
			pixel_y = 32
			pixel_x = 0
		if(SOUTH)
			pixel_y = -32
			pixel_x = 0
		if(EAST)
			pixel_x = 32
			pixel_y = 0
		if(WEST)
			pixel_x = -32
			pixel_y = 0

/obj/structure/resurgence_blueprint/resources_recorder/complete_construction(mob/user)
	if(!result_type)
		to_chat(user, span_warning("Error: Blueprint has no result type defined!"))
		return

	to_chat(user, span_notice("You finish building the [result_name]!"))
	playsound(src, complete_sound, 50, TRUE)

	var/turf/T = get_turf(src)

	// Create the resources recorder with wall direction
	var/obj/structure/resources_recorder/recorder = new result_type(T)
	if(recorder)
		recorder.wall_dir = wall_dir
		recorder.apply_wall_offset()
		recorder.anchored = TRUE

	// Remove the blueprint
	qdel(src)

/obj/structure/resurgence_blueprint/comms_console
	name = "comms console blueprint"
	result_name = "comms console"
	icon = 'icons/obj/terminals.dmi'
	icon_state = "req_comp0"
	result_type = /obj/structure/comms_console
	density = FALSE
	research_required = "machine_fabrication"

	/// Direction towards the wall this console will be mounted on
	var/wall_dir = SOUTH

/obj/structure/resurgence_blueprint/comms_console/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 10,
		/obj/item/stack/sheet/glass = 5
	)

/obj/structure/resurgence_blueprint/comms_console/Initialize(mapload, wall_direction)
	. = ..()
	if(wall_direction)
		wall_dir = wall_direction
	apply_wall_offset()

/// Apply pixel offset to match wall placement
/obj/structure/resurgence_blueprint/comms_console/proc/apply_wall_offset()
	switch(wall_dir)
		if(NORTH)
			pixel_y = 32
			pixel_x = 0
		if(SOUTH)
			pixel_y = -32
			pixel_x = 0
		if(EAST)
			pixel_x = 32
			pixel_y = 0
		if(WEST)
			pixel_x = -32
			pixel_y = 0

/obj/structure/resurgence_blueprint/comms_console/complete_construction(mob/user)
	if(!result_type)
		to_chat(user, span_warning("Error: Blueprint has no result type defined!"))
		return

	to_chat(user, span_notice("You finish building the [result_name]!"))
	playsound(src, complete_sound, 50, TRUE)

	var/turf/T = get_turf(src)

	// Create the comms console with wall direction
	var/obj/structure/comms_console/console = new result_type(T)
	if(console)
		console.wall_dir = wall_dir
		console.apply_wall_offset()
		console.anchored = TRUE

	// Remove the blueprint
	qdel(src)

// ===========================================
// ART BLUEPRINTS
// ===========================================

/obj/structure/resurgence_blueprint/easel
	name = "easel blueprint"
	result_name = "easel"
	icon = 'icons/obj/artstuff.dmi'
	icon_state = "easel"
	result_type = /obj/structure/easel
	research_required = "woodworking"

/obj/structure/resurgence_blueprint/easel/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 5
	)

// ===========================================
// OFFICE BLUEPRINTS
// ===========================================

/obj/structure/resurgence_blueprint/filing_cabinet
	name = "filing cabinet blueprint"
	result_name = "filing cabinet"
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "filingcabinet"
	result_type = /obj/structure/filingcabinet
	research_required = "papercraft"

/obj/structure/resurgence_blueprint/filing_cabinet/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 4
	)

/obj/structure/resurgence_blueprint/chest_drawer
	name = "chest drawer blueprint"
	result_name = "chest drawer"
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "chestdrawer"
	result_type = /obj/structure/filingcabinet/chestdrawer
	research_required = "papercraft"

/obj/structure/resurgence_blueprint/chest_drawer/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 3
	)

/obj/structure/resurgence_blueprint/sign
	name = "sign blueprint"
	result_name = "sign"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "sign"
	result_type = /obj/structure/resurgence_sign
	research_required = "artistry"

/obj/structure/resurgence_blueprint/sign/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 2
	)

/obj/structure/resurgence_blueprint/noticeboard
	name = "notice board blueprint"
	result_name = "notice board"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "nboard00"
	result_type = /obj/structure/noticeboard
	density = FALSE
	research_required = "artistry"

	/// Direction towards the wall this board will be mounted on
	var/wall_dir = SOUTH

/obj/structure/resurgence_blueprint/noticeboard/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 4
	)

/obj/structure/resurgence_blueprint/noticeboard/Initialize(mapload, wall_direction)
	. = ..()
	if(wall_direction)
		wall_dir = wall_direction
	apply_wall_offset()

/// Apply pixel offset to match wall placement
/obj/structure/resurgence_blueprint/noticeboard/proc/apply_wall_offset()
	switch(wall_dir)
		if(NORTH)
			pixel_y = 32
			pixel_x = 0
		if(SOUTH)
			pixel_y = -32
			pixel_x = 0
		if(EAST)
			pixel_x = 32
			pixel_y = 0
		if(WEST)
			pixel_x = -32
			pixel_y = 0

/obj/structure/resurgence_blueprint/noticeboard/complete_construction(mob/user)
	if(!result_type)
		to_chat(user, span_warning("Error: Blueprint has no result type defined!"))
		return

	to_chat(user, span_notice("You finish building the [result_name]!"))
	playsound(src, complete_sound, 50, TRUE)

	var/turf/T = get_turf(src)

	// Create the noticeboard with wall direction
	var/obj/structure/noticeboard/board = new result_type(T)
	if(board)
		board.pixel_x = pixel_x
		board.pixel_y = pixel_y
		board.anchored = TRUE

	// Remove the blueprint
	qdel(src)

// ===========================================
// MISC BLUEPRINTS
// ===========================================

/obj/structure/resurgence_blueprint/meatspike
	name = "meat spike blueprint"
	result_name = "meat spike"
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "spike"
	result_type = /obj/structure/kitchenspike
	research_required = "culinary"

/obj/structure/resurgence_blueprint/meatspike/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 4,
		/obj/item/stack/rods = 4
	)

/obj/structure/resurgence_blueprint/shower
	name = "shower frame blueprint"
	result_name = "shower frame"
	icon = 'icons/obj/watercloset.dmi'
	icon_state = "shower_frame"
	result_type = /obj/structure/showerframe
	research_required = "storage_tech"

/obj/structure/resurgence_blueprint/shower/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 4,
		/obj/item/stack/sheet/glass = 2
	)

/obj/structure/resurgence_blueprint/wooden_barricade
	name = "wooden barricade blueprint"
	result_name = "wooden barricade"
	icon = 'icons/obj/structures.dmi'
	icon_state = "woodenbarricade"
	result_type = /obj/structure/barricade/wooden
	research_required = "woodworking"

/obj/structure/resurgence_blueprint/wooden_barricade/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 5
	)

// ===========================================
// MEDICAL BLUEPRINTS
// ===========================================

/obj/structure/resurgence_blueprint/machine_fabricator
	name = "machine fabricator blueprint"
	result_name = "machine fabricator"
	icon = 'icons/mob/hivebot.dmi'
	icon_state = "fab_robot_open"
	result_type = /obj/structure/resurgence_fabricator
	research_required = "machine_fabrication"

/obj/structure/resurgence_blueprint/machine_fabricator/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 20,
		/obj/item/stack/sheet/glass = 10,
		/obj/item/stack/sheet/mineral/gold = 5,
		/obj/item/stack/sheet/mineral/silver = 5
	)

// ===========================================
// RESEARCH BLUEPRINTS
// ===========================================

/obj/structure/resurgence_blueprint/research_station
	name = "research station blueprint"
	result_name = "research station"
	icon = 'icons/obj/structures.dmi'
	icon_state = "server"
	result_type = /obj/structure/resurgence_research_station
	// No research_required - this is Tier 0, always available

/obj/structure/resurgence_blueprint/research_station/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 10,
		/obj/item/stack/sheet/metal = 5
	)
