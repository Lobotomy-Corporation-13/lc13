// Expedition Corridor Turfs
// Floor and wall turfs that can change appearance based on terrain type

// ============================================
// EXPEDITION FLOOR TURFS
// ============================================

/**
 * Base expedition floor turf
 * Can transform appearance to match different terrain types
 */
/turf/open/floor/expedition
	name = "path"
	desc = "A well-worn path through the wilderness."
	icon = 'icons/turf/floors.dmi'
	icon_state = "grass0"
	base_icon_state = "grass"
	/// Current terrain type being displayed
	var/current_terrain = TERRAIN_PLAINS
	/// Whether this turf is part of the walkable path (vs edge decoration area)
	var/is_path = TRUE

/turf/open/floor/expedition/Initialize(mapload)
	. = ..()
	// Register with corridor manager when it exists
	if(GLOB.expedition_corridor)
		GLOB.expedition_corridor.register_floor_turf(src)

/**
 * Set the terrain type and update appearance
 */
/turf/open/floor/expedition/proc/set_terrain(terrain_type)
	current_terrain = terrain_type
	update_terrain_appearance()

/**
 * Update the turf's appearance based on current terrain
 */
/turf/open/floor/expedition/proc/update_terrain_appearance()
	switch(current_terrain)
		if(TERRAIN_PLAINS)
			icon_state = "grass[rand(0,3)]"
			name = "grassy path"
			desc = "Soft grass underfoot. Easy terrain."
		if(TERRAIN_FOREST)
			icon_state = "grass[rand(0,3)]"
			name = "forest floor"
			desc = "Fallen leaves and soft earth. Watch your step."
			// Add slight color tint for forest
			color = "#90b090"
		if(TERRAIN_MOUNTAIN)
			icon_state = "rock"
			name = "rocky trail"
			desc = "Uneven stone makes for difficult footing."
			color = null
		if(TERRAIN_DESERT)
			icon_state = "sand"
			name = "sandy path"
			desc = "Fine sand shifts beneath your feet."
			color = null
		if(TERRAIN_RUINS)
			icon_state = "plating"
			name = "crumbled floor"
			desc = "Ancient stonework, cracked and weathered."
			color = "#a09080"
		else
			icon_state = "grass0"
			name = "path"
			color = null

// Edge floor variant for decoration spawning
/turf/open/floor/expedition/edge
	is_path = FALSE

// ============================================
// EXPEDITION WALL TURFS
// ============================================

/**
 * Base expedition wall turf
 * Forms the boundaries of the corridor and transforms with terrain
 */
/turf/closed/wall/expedition
	name = "natural barrier"
	desc = "Impassable terrain blocks your path."
	icon = 'icons/turf/walls/wall.dmi'
	icon_state = "wall-0"
	/// Current terrain type being displayed
	var/current_terrain = TERRAIN_PLAINS

/turf/closed/wall/expedition/Initialize(mapload)
	. = ..()
	// Register with corridor manager when it exists
	if(GLOB.expedition_corridor)
		GLOB.expedition_corridor.register_wall_turf(src)

/**
 * Set the terrain type and update appearance
 */
/turf/closed/wall/expedition/proc/set_terrain(terrain_type)
	current_terrain = terrain_type
	update_terrain_appearance()

/**
 * Update the wall's appearance based on current terrain
 */
/turf/closed/wall/expedition/proc/update_terrain_appearance()
	switch(current_terrain)
		if(TERRAIN_PLAINS)
			name = "grassy hillside"
			desc = "A steep grassy slope, too difficult to climb."
			color = "#4a7c3f"
		if(TERRAIN_FOREST)
			name = "dense treeline"
			desc = "Thick forest growth blocks passage."
			color = "#2d5a27"
		if(TERRAIN_MOUNTAIN)
			name = "cliff face"
			desc = "Sheer rock walls stretch upward."
			color = "#8b8b8b"
		if(TERRAIN_DESERT)
			name = "sand dune"
			desc = "A massive dune too steep to traverse."
			color = "#c2b280"
		if(TERRAIN_RUINS)
			name = "collapsed wall"
			desc = "Rubble and debris block the way."
			color = "#6b5b4f"
		else
			name = "natural barrier"
			color = null

// ============================================
// EXPEDITION AREA
// ============================================

/area/resurgence/expedition_corridor
	name = "Expedition Corridor"
	icon_state = "yellow"
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	flags_1 = NONE
	ambience_index = AMBIENCE_AWAY
	sound_environment = SOUND_AREA_ASTEROID

// ============================================
// EXPEDITION DECORATIONS
// ============================================

/**
 * Base decoration structure for expedition corridors
 * Spawned along edges, deleted and respawned on terrain change
 */
/obj/structure/flora/expedition
	name = "vegetation"
	desc = "Natural growth."
	icon = 'icons/obj/flora/ausflora.dmi'
	icon_state = "reedbush_1"
	anchored = TRUE
	density = FALSE
	layer = ABOVE_MOB_LAYER

// Plains decorations
/obj/structure/flora/expedition/grass
	name = "tall grass"
	desc = "Swaying grass."
	icon_state = "fernybush_1"

/obj/structure/flora/expedition/rock_small
	name = "small rock"
	desc = "A weathered stone."
	icon = 'icons/obj/flora/rocks.dmi'
	icon_state = "rock1"

// Forest decorations
/obj/structure/flora/expedition/tree
	name = "tree"
	desc = "A sturdy tree."
	icon = 'icons/obj/flora/pinetrees.dmi'
	icon_state = "pine_1"
	density = TRUE
	pixel_x = -16
	layer = ABOVE_ALL_MOB_LAYER

/obj/structure/flora/expedition/bush
	name = "bush"
	desc = "A leafy bush."
	icon_state = "stalkybush_1"

// Mountain decorations
/obj/structure/flora/expedition/rock_large
	name = "boulder"
	desc = "A large boulder."
	icon = 'icons/obj/flora/rocks.dmi'
	icon_state = "rock3"
	density = TRUE

/obj/structure/flora/expedition/boulder
	name = "rock formation"
	desc = "Jagged rocks jutting from the ground."
	icon = 'icons/obj/flora/rocks.dmi'
	icon_state = "rock4"

// Desert decorations
/obj/structure/flora/expedition/cactus
	name = "cactus"
	desc = "A prickly cactus."
	icon = 'icons/obj/flora/ausflora.dmi'
	icon_state = "cactus_1"

/obj/structure/flora/expedition/dead_bush
	name = "dead shrub"
	desc = "A withered, dried bush."
	icon_state = "fullgrass_1"
	color = "#a08060"

// Ruins decorations
/obj/structure/flora/expedition/pillar
	name = "broken pillar"
	desc = "The remains of an ancient column."
	icon = 'icons/obj/flora/rocks.dmi'
	icon_state = "rock2"
	color = "#808080"
	density = TRUE

/obj/structure/flora/expedition/debris
	name = "debris"
	desc = "Scattered rubble and broken materials."
	icon = 'icons/obj/flora/rocks.dmi'
	icon_state = "rock1"
	color = "#706050"
