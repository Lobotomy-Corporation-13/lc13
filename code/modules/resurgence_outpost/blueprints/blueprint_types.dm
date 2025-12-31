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
		/obj/item/stack/sheet/mineral/wood = 8
	)

/obj/structure/resurgence_blueprint/iron_door
	name = "iron door blueprint"
	result_name = "iron door"
	icon = 'icons/obj/doors/mineral_doors.dmi'
	icon_state = "metal"
	result_type = /obj/structure/mineral_door/iron

/obj/structure/resurgence_blueprint/iron_door/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 10
	)

/obj/structure/resurgence_blueprint/silver_door
	name = "silver door blueprint"
	result_name = "silver door"
	icon = 'icons/obj/doors/mineral_doors.dmi'
	icon_state = "silver"
	result_type = /obj/structure/mineral_door/silver

/obj/structure/resurgence_blueprint/silver_door/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/silver = 10
	)

/obj/structure/resurgence_blueprint/gold_door
	name = "gold door blueprint"
	result_name = "gold door"
	icon = 'icons/obj/doors/mineral_doors.dmi'
	icon_state = "gold"
	result_type = /obj/structure/mineral_door/gold

/obj/structure/resurgence_blueprint/gold_door/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/gold = 10
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

/obj/structure/resurgence_blueprint/iron_wall/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 10
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

/obj/structure/resurgence_blueprint/forge/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/metal = 15,
		/obj/item/stack/ore/rock = 20,
		/obj/item/stack/sheet/mineral/coal = 5
	)

/obj/structure/resurgence_blueprint/loom
	name = "loom blueprint"
	result_name = "loom"
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "loom"
	result_type = /obj/structure/resurgence_crafting_table/loom

/obj/structure/resurgence_blueprint/loom/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 12,
		/obj/item/resurgence_component/rope = 3
	)

/obj/structure/resurgence_blueprint/seed_extractor
	name = "seed extractor blueprint"
	result_name = "seed extractor"
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "sextractor"
	result_type = /obj/structure/resurgence_seed_extractor

/obj/structure/resurgence_blueprint/seed_extractor/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 5,
		/obj/item/stack/sheet/metal = 2
	)

// ===========================================
// FURNITURE BLUEPRINTS
// ===========================================

/obj/structure/resurgence_blueprint/bed
	name = "bed blueprint"
	result_name = "bed"
	icon = 'icons/obj/objects.dmi'
	icon_state = "bed"
	result_type = /obj/structure/resurgence_bed

/obj/structure/resurgence_blueprint/bed/init_materials()
	required_materials = list(
		/obj/item/stack/sheet/mineral/wood = 10,
		/obj/item/stack/sheet/cotton/cloth = 5
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

/obj/structure/resurgence_blueprint/table_frame/init_materials()
	required_materials = list(
		/obj/item/stack/rods = 2
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
