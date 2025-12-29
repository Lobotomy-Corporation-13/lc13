/**
 * Resurgence Outpost - Farm Seeds
 *
 * Simplified seed system for farming zones.
 * Seeds define growth rates, water requirements, and produce.
 */

// ===== Seed Datum =====

/datum/farm_seed
	/// Display name of the crop
	var/name = "crop"
	/// What item type is produced on harvest
	var/product_type = null
	/// How many items are produced per harvest
	var/product_amount = 1
	/// Zone ticks needed to advance each growth stage
	var/growth_per_stage = 3
	/// Water consumed per zone tick
	var/water_drain = 10
	/// Minimum water level required to grow
	var/min_water = 20
	/// Work points needed to harvest
	var/harvest_work = 50
	/// Does the plant regrow after harvest?
	var/regrows = FALSE
	/// Icon file for plant sprites
	var/plant_icon = 'icons/obj/hydroponics/growing.dmi'
	/// Icon state prefix for growth stages
	var/icon_grow = "wheat"

/// Get the icon state for a given growth stage
/datum/farm_seed/proc/get_icon_state(growth_stage)
	switch(growth_stage)
		if(FARM_STAGE_GROWING_1)
			return "[icon_grow]-grow1"
		if(FARM_STAGE_GROWING_2)
			return "[icon_grow]-grow2"
		if(FARM_STAGE_GROWING_3)
			return "[icon_grow]-grow3"
		if(FARM_STAGE_HARVEST)
			return "[icon_grow]-harvest"
	return "[icon_grow]-grow1"

// ===== Seed Types =====

/datum/farm_seed/wheat
	name = "wheat"
	product_type = /obj/item/food/grown/wheat
	product_amount = 3
	growth_per_stage = 3
	water_drain = 8
	harvest_work = 50
	regrows = FALSE
	icon_grow = "wheat"

/datum/farm_seed/carrot
	name = "carrot"
	product_type = /obj/item/food/grown/carrot
	product_amount = 2
	growth_per_stage = 4
	water_drain = 10
	harvest_work = 40
	regrows = FALSE
	icon_grow = "carrot"

/datum/farm_seed/tomato
	name = "tomato"
	product_type = /obj/item/food/grown/tomato
	product_amount = 4
	growth_per_stage = 3
	water_drain = 12
	harvest_work = 60
	regrows = TRUE
	icon_grow = "tomato"

/datum/farm_seed/potato
	name = "potato"
	product_type = /obj/item/food/grown/potato
	product_amount = 3
	growth_per_stage = 4
	water_drain = 8
	harvest_work = 45
	regrows = FALSE
	icon_grow = "potato"

/datum/farm_seed/cotton
	name = "cotton"
	product_type = /obj/item/stack/sheet/cotton
	product_amount = 4
	growth_per_stage = 2
	water_drain = 6
	harvest_work = 50
	regrows = TRUE
	icon_grow = "cotton"

/datum/farm_seed/corn
	name = "corn"
	product_type = /obj/item/food/grown/corn
	product_amount = 2
	growth_per_stage = 4
	water_drain = 10
	harvest_work = 55
	regrows = FALSE
	icon_grow = "corn"

// ===== Seed Items =====

/obj/item/seeds/farm
	name = "farm seeds"
	desc = "Seeds for planting in farm plots."
	icon = 'icons/obj/hydroponics/seeds.dmi'
	icon_state = "seed"
	w_class = WEIGHT_CLASS_TINY
	/// The seed datum this item represents
	var/datum/farm_seed/seed_datum

/obj/item/seeds/farm/Initialize(mapload)
	. = ..()
	if(!seed_datum)
		seed_datum = new /datum/farm_seed()

/obj/item/seeds/farm/Destroy()
	QDEL_NULL(seed_datum)
	return ..()

/obj/item/seeds/farm/wheat
	name = "wheat seeds"
	desc = "Seeds for growing wheat."
	icon_state = "seed-wheat"

/obj/item/seeds/farm/wheat/Initialize(mapload)
	. = ..()
	seed_datum = new /datum/farm_seed/wheat()

/obj/item/seeds/farm/carrot
	name = "carrot seeds"
	desc = "Seeds for growing carrots."
	icon_state = "seed-carrot"

/obj/item/seeds/farm/carrot/Initialize(mapload)
	. = ..()
	seed_datum = new /datum/farm_seed/carrot()

/obj/item/seeds/farm/tomato
	name = "tomato seeds"
	desc = "Seeds for growing tomatoes."
	icon_state = "seed-tomato"

/obj/item/seeds/farm/tomato/Initialize(mapload)
	. = ..()
	seed_datum = new /datum/farm_seed/tomato()

/obj/item/seeds/farm/potato
	name = "potato seeds"
	desc = "Seed potatoes for growing potatoes."
	icon_state = "seed-potato"

/obj/item/seeds/farm/potato/Initialize(mapload)
	. = ..()
	seed_datum = new /datum/farm_seed/potato()

/obj/item/seeds/farm/cotton
	name = "cotton seeds"
	desc = "Seeds for growing cotton."
	icon_state = "seed"

/obj/item/seeds/farm/cotton/Initialize(mapload)
	. = ..()
	seed_datum = new /datum/farm_seed/cotton()

/obj/item/seeds/farm/corn
	name = "corn seeds"
	desc = "Seeds for growing corn."
	icon_state = "seed-corn"

/obj/item/seeds/farm/corn/Initialize(mapload)
	. = ..()
	seed_datum = new /datum/farm_seed/corn()
