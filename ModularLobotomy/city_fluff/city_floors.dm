// All of them share one parent, so a surface only has to declare its sprite
// stem and how many variants it has.
/turf/open/floor/city
	name = "ground"
	icon = 'icons/turf/floors/city_turfs.dmi'
	icon_state = "asphalt1"
	baseturfs = /turf/open/floor/plating
	floor_tile = /obj/item/stack/tile/plasteel
	tiled_dirt = FALSE
	/// Sprite stem; Initialize appends a random variant number to it.
	var/base_state = "asphalt"
	/// How many scatter variants exist for this surface.
	var/variants = 3

/turf/open/floor/city/Initialize()
	. = ..()
	if(variants > 1)
		icon_state = "[base_state][rand(1, variants)]"

// the street
/turf/open/floor/city/road
	name = "road"
	desc = "Cracked asphalt, patched more often than it has been resurfaced."
	base_state = "asphalt"
	footstep = FOOTSTEP_FLOOR
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW

/turf/open/floor/city/sidewalk
	name = "pavement"
	desc = "Cast paving slabs, laid in courses and settled unevenly."
	icon_state = "sidewalk1"
	base_state = "sidewalk"

/turf/open/floor/city/sidewalk/poor
	name = "worn pavement"
	desc = "Poured concrete, greyed over and swept by nobody."
	icon_state = "sidewalk_poor1"
	base_state = "sidewalk_poor"

/turf/open/floor/city/sidewalk/old
	name = "flagstone pavement"
	desc = "Old flagstones, no two the same size. Older than the district on \
		top of them."
	icon_state = "sidewalk_old1"
	base_state = "sidewalk_old"
	variants = 4

/turf/open/floor/city/sidewalk/rich
	name = "tiled pavement"
	desc = "Patterned stone tile. Whoever owns the frontage pays to keep it \
		swept."
	icon_state = "sidewalk_rich1"
	base_state = "sidewalk_rich"

/turf/open/floor/city/concrete
	name = "concrete"
	desc = "Poured slabs, joints half worn away. Yard and forecourt paving."
	icon_state = "concrete1"
	base_state = "concrete"
	variants = 4

/turf/open/floor/city/drain
	name = "storm drain"
	desc = "A gutter grate set into the road. Something moves under it."
	icon_state = "drain"
	base_state = "drain"
	variants = 1

/turf/open/floor/city/manhole
	name = "manhole"
	desc = "A service cover, worn smooth by traffic."
	icon_state = "manhole"
	base_state = "manhole"
	variants = 1

// the canal

/turf/open/floor/city/canal
	name = "canal"
	desc = "Standing water in a lined channel. Mossy at the lip, black \
		further down."
	icon_state = "canal1"
	base_state = "canal"
	footstep = FOOTSTEP_WATER
	barefootstep = FOOTSTEP_WATER
	clawfootstep = FOOTSTEP_WATER
	slowdown = 1

/turf/open/floor/city/canal/plating
	name = "canal plating"
	desc = "Bolted deck plate over the channel, gone olive with damp."
	icon_state = "canal_plating1"
	base_state = "canal_plating"
	variants = 4
	footstep = FOOTSTEP_PLATING
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW
	slowdown = 0

/turf/open/floor/city/canal/concrete
	name = "canal bank"
	desc = "The retaining concrete of the channel, shuttering seams still \
		showing."
	icon_state = "canal_concrete1"
	base_state = "canal_concrete"
	variants = 2
	footstep = FOOTSTEP_FLOOR
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW
	slowdown = 0

//  the port

/turf/open/floor/city/container
	name = "container decking"
	desc = "Corrugated steel decking. It rings underfoot."
	icon_state = "container"
	base_state = "container"
	variants = 1
	footstep = FOOTSTEP_PLATING
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW

/turf/open/floor/city/container/worn
	name = "worn container decking"
	desc = "Corrugated steel decking, scuffed down to the primer in places."
	icon_state = "container1"
	base_state = "container"
	variants = 3

// works district
// Laid to the reference sheet's own unit: an 8x8 tile with its top row and
// left column a step lighter and its right column and bottom row a step
// darker, which is what makes a floor look laid rather than printed.

/turf/open/floor/city/industrial
	name = "shop floor"
	icon_state = "factory_tile1"
	base_state = "factory_tile"
	footstep = FOOTSTEP_FLOOR
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW

/turf/open/floor/city/industrial/factory_tile
	name = "factory tile"
	desc = "Heavy quarry tile, laid to take a pallet truck. Oil has soaked \
		into the joints and stayed there."
	icon_state = "factory_tile1"
	base_state = "factory_tile"

/turf/open/floor/city/industrial/tread
	name = "tread plate"
	desc = "Chequer plate walkway. The pattern has been worn flat where \
		everyone walks."
	icon_state = "tread1"
	base_state = "tread"
	footstep = FOOTSTEP_PLATING
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW

/turf/open/floor/city/industrial/steelplate
	name = "deck plating"
	desc = "Riveted steel plate. It gives half an inch under a boot and \
		announces every step."
	icon_state = "steelplate1"
	base_state = "steelplate"
	variants = 2
	footstep = FOOTSTEP_PLATING
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW

/turf/open/floor/city/industrial/grate
	name = "floor grating"
	desc = "Bar grating over a drop. You can feel the draught through it."
	icon_state = "grate1"
	base_state = "grate"
	variants = 2
	footstep = FOOTSTEP_PLATING
	barefootstep = FOOTSTEP_PLATING
	clawfootstep = FOOTSTEP_PLATING

/turf/open/floor/city/industrial/oilconcrete
	name = "oiled concrete"
	desc = "Slab worn smooth and black in the tracks the machines take."
	icon_state = "oilconcrete1"
	base_state = "oilconcrete"

/turf/open/floor/city/industrial/plank
	name = "workshop boards"
	desc = "Oiled boards, dark with a century of swarf and spilled lamp oil."
	icon_state = "plank1"
	base_state = "plank"
	footstep = FOOTSTEP_WOOD
	barefootstep = FOOTSTEP_WOOD_BAREFOOT
	clawfootstep = FOOTSTEP_WOOD_CLAW

// -------------------------------------------------------------- markings
// Turf decals, so they lay over whatever surface is already there.
//
// Each one carries all four directions in a single icon_state, so a mapper
// turns the decal itself rather than picking a pre-turned subtype. Facing is
// literal: a kerb set to SOUTH puts its raised edge on the south side, and an
// arrow set to SOUTH points south.

/obj/effect/turf_decal/road
	icon = 'icons/turf/city_decals.dmi'
	icon_state = "line_dash"

/obj/effect/turf_decal/road/line_dash
	icon_state = "line_dash"

/obj/effect/turf_decal/road/line_solid
	icon_state = "line_solid"

/obj/effect/turf_decal/road/line_double
	icon_state = "line_double"

/obj/effect/turf_decal/road/crosswalk
	icon_state = "crosswalk"

/obj/effect/turf_decal/road/stop_bar
	icon_state = "stop_bar"

/obj/effect/turf_decal/road/arrow
	icon_state = "arrow"

/obj/effect/turf_decal/road/hatch
	icon_state = "hatch"

/obj/effect/turf_decal/road/parking
	icon_state = "parking"

/// The raised edge between road and pavement. Turn it to face the road.
/obj/effect/turf_decal/road/kerb
	icon_state = "kerb"

/obj/effect/turf_decal/road/kerb/corner
	icon_state = "kerb_corner"

/// Two straight runs meeting at a corner each stop at their own tile edge and
/// leave the square between them bare. This plugs that square.
///
/// One block, one position, and identical in all four directions: it has no
/// facing to turn, and turning it only ever moved it into a corner nobody
/// asked for. Its lit face and shadow stay put too, so it reads as the same
/// kerb as the runs beside it.
/obj/effect/turf_decal/road/kerb/box
	icon_state = "kerb_box"

