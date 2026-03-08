/// Resurgence Outpost ruin template category
/datum/map_template/ruin/resurgence
	prefix = "_maps/RandomRuins/ResurgenceRuins/"

/// Clears resurgence flora from affected turfs before placing the ruin
/datum/map_template/ruin/resurgence/try_to_place(z, allowed_areas, turf/forced_turf)
	var/turf/central_turf = ..()
	if(!central_turf)
		return
	for(var/i in get_affected_turfs(central_turf, 1))
		var/turf/T = i
		for(var/obj/structure/resurgence_tree/tree in T)
			qdel(tree)
		for(var/obj/structure/resurgence_wild_plant/plant in T)
			qdel(plant)
	return central_turf

/// Area type for resurgence ruins
/area/ruin/resurgence
	name = "Resurgence Ruin"
	has_gravity = STANDARD_GRAVITY
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
	requires_power = FALSE
	always_unpowered = TRUE

/datum/map_template/ruin/resurgence/mountain_v1
	id = "mountain_1"
	suffix = "mountain_v1.dmm"
	name = "Mountain 1"
	cost = 4

/datum/map_template/ruin/resurgence/mountain_v2
	id = "mountain_2"
	suffix = "mountain_v2.dmm"
	name = "Mountain 2"
	cost = 6

/datum/map_template/ruin/resurgence/mountain_v3
	id = "mountain_3"
	suffix = "mountain_v3.dmm"
	name = "Mountain 3"
	cost = 6

/datum/map_template/ruin/resurgence/mountain_v4
	id = "mountain_4"
	suffix = "mountain_v4.dmm"
	name = "Mountain 4"
	cost = 6

/datum/map_template/ruin/resurgence/mountain_v5
	id = "mountain_5"
	suffix = "mountain_v5.dmm"
	name = "Mountain 5"
	cost = 8

/datum/map_template/ruin/resurgence/pond_v1
	id = "pond_v1"
	suffix = "pond_b1.dmm"
	name = "Pond 5"
	cost = 2

/datum/map_template/ruin/resurgence/lost_lab
	id = "lost_lab"
	suffix = "lost_lab.dmm"
	name = "Lost Lab"
	cost = 6
	allow_duplicates = FALSE

/datum/map_template/ruin/resurgence/gamba_shrine
	id = "gamba_shrine"
	suffix = "gamba_shrine.dmm"
	name = "Gamba Shrine"
	cost = 8
	allow_duplicates = FALSE
