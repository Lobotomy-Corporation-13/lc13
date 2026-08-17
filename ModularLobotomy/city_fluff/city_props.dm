// City props imported from the World of Darkness 13 sprite sheets.
// See the pull request for the exact source files and state ranges.
//
// Families that ship many interchangeable sprites (drums, litter, pipe
// runs, refuse) have a parent type that picks a sprite on spawn, wearing a
// rainbow "?" marker in the map editor so it is obvious it will randomise.
// Every variant also gets its own type underneath it, so a mapper who wants
// one specific drum can place that drum instead.

/obj/structure/city_prop
	name = "prop"
	icon = 'ModularLobotomy/_Lobotomyicons/city_props.dmi'
	icon_state = "barrel1"
	anchored = TRUE
	density = FALSE
	/// Scaled by how much there is of the thing and what it is made of:
	/// bagged refuse at 50, a cast iron hydrant or a slate pool table near
	/// 450, a bricked-up opening at 500. For scale, the codebase puts a
	/// lattice at 50, a table at 100 and a girder at 200 to 350.
	max_integrity = 100
	/// Sprite stem; Initialize appends a variant number when there is one.
	var/base_state
	/// How many interchangeable sprites this prop has.
	var/variants = 1

/obj/structure/city_prop/Initialize(mapload)
	. = ..()
	if(variants > 1 && base_state)
		icon_state = "[base_state][rand(1, variants)]"

/// Ground clutter. Never dense, and under anything standing on it.
/obj/effect/decal/city
	name = "clutter"
	icon = 'ModularLobotomy/_Lobotomyicons/city_props.dmi'
	icon_state = "litter_paper1"
	layer = ABOVE_NORMAL_TURF_LAYER
	var/base_state
	var/variants = 1

/obj/effect/decal/city/Initialize(mapload)
	. = ..()
	if(variants > 1 && base_state)
		icon_state = "[base_state][rand(1, variants)]"

// ---------------------------------------------------------- clutter

/// Parent for the four kinds of litter. Place one of its children.
/obj/effect/decal/city/litter
	name = "litter"

/// Any litter at all. Rolls a kind first and then a sprite within it, so
/// a scattered street gets a mix rather than twelve sheets of newspaper
/// for every one broken crate.
/obj/effect/decal/city/litter/any
	name = "litter"
	desc = "Whatever the street has collected and nobody has swept."
	icon_state = "random_litter_any"

/obj/effect/decal/city/litter/any/Initialize(mapload)
	. = ..()
	switch(rand(1, 4))
		if(1)
			icon_state = "litter_paper[rand(1, 12)]"
		if(2)
			icon_state = "litter_planks[rand(1, 6)]"
		if(3)
			icon_state = "litter_rubble[rand(1, 6)]"
		else
			icon_state = "litter_crates[rand(1, 6)]"

/obj/effect/decal/city/litter/paper
	name = "litter"
	desc = "Wet newspaper and handbills, trodden flat."
	icon_state = "random_litter_paper"
	base_state = "litter_paper"
	variants = 12

/obj/effect/decal/city/litter/paper/paper1
	icon_state = "litter_paper1"
	variants = 1

/obj/effect/decal/city/litter/paper/paper2
	icon_state = "litter_paper2"
	variants = 1

/obj/effect/decal/city/litter/paper/paper3
	icon_state = "litter_paper3"
	variants = 1

/obj/effect/decal/city/litter/paper/paper4
	icon_state = "litter_paper4"
	variants = 1

/obj/effect/decal/city/litter/paper/paper5
	icon_state = "litter_paper5"
	variants = 1

/obj/effect/decal/city/litter/paper/paper6
	icon_state = "litter_paper6"
	variants = 1

/obj/effect/decal/city/litter/paper/paper7
	icon_state = "litter_paper7"
	variants = 1

/obj/effect/decal/city/litter/paper/paper8
	icon_state = "litter_paper8"
	variants = 1

/obj/effect/decal/city/litter/paper/paper9
	icon_state = "litter_paper9"
	variants = 1

/obj/effect/decal/city/litter/paper/paper10
	icon_state = "litter_paper10"
	variants = 1

/obj/effect/decal/city/litter/paper/paper11
	icon_state = "litter_paper11"
	variants = 1

/obj/effect/decal/city/litter/paper/paper12
	icon_state = "litter_paper12"
	variants = 1

/obj/effect/decal/city/litter/planks
	name = "scrap timber"
	desc = "Broken lengths of batten, dropped where they were pulled down."
	icon_state = "random_litter_planks"
	base_state = "litter_planks"
	variants = 6

/obj/effect/decal/city/litter/planks/planks1
	icon_state = "litter_planks1"
	variants = 1

/obj/effect/decal/city/litter/planks/planks2
	icon_state = "litter_planks2"
	variants = 1

/obj/effect/decal/city/litter/planks/planks3
	icon_state = "litter_planks3"
	variants = 1

/obj/effect/decal/city/litter/planks/planks4
	icon_state = "litter_planks4"
	variants = 1

/obj/effect/decal/city/litter/planks/planks5
	icon_state = "litter_planks5"
	variants = 1

/obj/effect/decal/city/litter/planks/planks6
	icon_state = "litter_planks6"
	variants = 1

/obj/effect/decal/city/litter/rubble
	name = "rubble"
	desc = "Broken brick. Something above here is coming apart."
	icon_state = "random_litter_rubble"
	base_state = "litter_rubble"
	variants = 6

/obj/effect/decal/city/litter/rubble/rubble1
	icon_state = "litter_rubble1"
	variants = 1

/obj/effect/decal/city/litter/rubble/rubble2
	icon_state = "litter_rubble2"
	variants = 1

/obj/effect/decal/city/litter/rubble/rubble3
	icon_state = "litter_rubble3"
	variants = 1

/obj/effect/decal/city/litter/rubble/rubble4
	icon_state = "litter_rubble4"
	variants = 1

/obj/effect/decal/city/litter/rubble/rubble5
	icon_state = "litter_rubble5"
	variants = 1

/obj/effect/decal/city/litter/rubble/rubble6
	icon_state = "litter_rubble6"
	variants = 1

/obj/effect/decal/city/litter/crates
	name = "discarded crates"
	desc = "Empty produce crates, stacked by nobody."
	icon_state = "random_litter_crates"
	base_state = "litter_crates"
	variants = 6

/obj/effect/decal/city/litter/crates/crates1
	icon_state = "litter_crates1"
	variants = 1

/obj/effect/decal/city/litter/crates/crates2
	icon_state = "litter_crates2"
	variants = 1

/obj/effect/decal/city/litter/crates/crates3
	icon_state = "litter_crates3"
	variants = 1

/obj/effect/decal/city/litter/crates/crates4
	icon_state = "litter_crates4"
	variants = 1

/obj/effect/decal/city/litter/crates/crates5
	icon_state = "litter_crates5"
	variants = 1

/obj/effect/decal/city/litter/crates/crates6
	icon_state = "litter_crates6"
	variants = 1

/obj/effect/decal/city/piping
	name = "piping"
	desc = "A run of service pipe, bracketed to the ground and going \
		somewhere."
	icon_state = "random_piping"
	base_state = "piping"
	variants = 43

/obj/effect/decal/city/piping/piping1
	icon_state = "piping1"
	variants = 1

/obj/effect/decal/city/piping/piping2
	icon_state = "piping2"
	variants = 1

/obj/effect/decal/city/piping/piping3
	icon_state = "piping3"
	variants = 1

/obj/effect/decal/city/piping/piping4
	icon_state = "piping4"
	variants = 1

/obj/effect/decal/city/piping/piping5
	icon_state = "piping5"
	variants = 1

/obj/effect/decal/city/piping/piping6
	icon_state = "piping6"
	variants = 1

/obj/effect/decal/city/piping/piping7
	icon_state = "piping7"
	variants = 1

/obj/effect/decal/city/piping/piping8
	icon_state = "piping8"
	variants = 1

/obj/effect/decal/city/piping/piping9
	icon_state = "piping9"
	variants = 1

/obj/effect/decal/city/piping/piping10
	icon_state = "piping10"
	variants = 1

/obj/effect/decal/city/piping/piping11
	icon_state = "piping11"
	variants = 1

/obj/effect/decal/city/piping/piping12
	icon_state = "piping12"
	variants = 1

/obj/effect/decal/city/piping/piping13
	icon_state = "piping13"
	variants = 1

/obj/effect/decal/city/piping/piping14
	icon_state = "piping14"
	variants = 1

/obj/effect/decal/city/piping/piping15
	icon_state = "piping15"
	variants = 1

/obj/effect/decal/city/piping/piping16
	icon_state = "piping16"
	variants = 1

/obj/effect/decal/city/piping/piping17
	icon_state = "piping17"
	variants = 1

/obj/effect/decal/city/piping/piping18
	icon_state = "piping18"
	variants = 1

/obj/effect/decal/city/piping/piping19
	icon_state = "piping19"
	variants = 1

/obj/effect/decal/city/piping/piping20
	icon_state = "piping20"
	variants = 1

/obj/effect/decal/city/piping/piping21
	icon_state = "piping21"
	variants = 1

/obj/effect/decal/city/piping/piping22
	icon_state = "piping22"
	variants = 1

/obj/effect/decal/city/piping/piping23
	icon_state = "piping23"
	variants = 1

/obj/effect/decal/city/piping/piping24
	icon_state = "piping24"
	variants = 1

/obj/effect/decal/city/piping/piping25
	icon_state = "piping25"
	variants = 1

/obj/effect/decal/city/piping/piping26
	icon_state = "piping26"
	variants = 1

/obj/effect/decal/city/piping/piping27
	icon_state = "piping27"
	variants = 1

/obj/effect/decal/city/piping/piping28
	icon_state = "piping28"
	variants = 1

/obj/effect/decal/city/piping/piping29
	icon_state = "piping29"
	variants = 1

/obj/effect/decal/city/piping/piping30
	icon_state = "piping30"
	variants = 1

/obj/effect/decal/city/piping/piping31
	icon_state = "piping31"
	variants = 1

/obj/effect/decal/city/piping/piping32
	icon_state = "piping32"
	variants = 1

/obj/effect/decal/city/piping/piping33
	icon_state = "piping33"
	variants = 1

/obj/effect/decal/city/piping/piping34
	icon_state = "piping34"
	variants = 1

/obj/effect/decal/city/piping/piping35
	icon_state = "piping35"
	variants = 1

/obj/effect/decal/city/piping/piping36
	icon_state = "piping36"
	variants = 1

/obj/effect/decal/city/piping/piping37
	icon_state = "piping37"
	variants = 1

/obj/effect/decal/city/piping/piping38
	icon_state = "piping38"
	variants = 1

/obj/effect/decal/city/piping/piping39
	icon_state = "piping39"
	variants = 1

/obj/effect/decal/city/piping/piping40
	icon_state = "piping40"
	variants = 1

/obj/effect/decal/city/piping/piping41
	icon_state = "piping41"
	variants = 1

/obj/effect/decal/city/piping/piping42
	icon_state = "piping42"
	variants = 1

/obj/effect/decal/city/piping/piping43
	icon_state = "piping43"
	variants = 1

/obj/effect/decal/city/manhole
	name = "manhole cover"
	desc = "A service cover, worn smooth by traffic."
	icon_state = "manhole"

/obj/effect/decal/city/manhole/open
	name = "open manhole"
	desc = "The cover is off. Nobody has put a cone out."
	icon_state = "manhole_open"

/obj/effect/decal/city/manhole/snow
	name = "snowed manhole cover"
	desc = "A service cover with the snow settled into its lettering."
	icon_state = "manhole-snow"

// ----------------------------------------------------------- street

/obj/structure/city_prop/barrel
	name = "oil drum"
	desc = "A steel drum, dented and restencilled more than once."
	icon_state = "random_barrel"
	base_state = "barrel"
	variants = 12
	density = TRUE
	max_integrity = 150

/obj/structure/city_prop/barrel/barrel1
	icon_state = "barrel1"
	variants = 1

/obj/structure/city_prop/barrel/barrel2
	icon_state = "barrel2"
	variants = 1

/obj/structure/city_prop/barrel/barrel3
	icon_state = "barrel3"
	variants = 1

/obj/structure/city_prop/barrel/barrel4
	icon_state = "barrel4"
	variants = 1

/obj/structure/city_prop/barrel/barrel5
	icon_state = "barrel5"
	variants = 1

/obj/structure/city_prop/barrel/barrel6
	icon_state = "barrel6"
	variants = 1

/obj/structure/city_prop/barrel/barrel7
	icon_state = "barrel7"
	variants = 1

/obj/structure/city_prop/barrel/barrel8
	icon_state = "barrel8"
	variants = 1

/obj/structure/city_prop/barrel/barrel9
	icon_state = "barrel9"
	variants = 1

/obj/structure/city_prop/barrel/barrel10
	icon_state = "barrel10"
	variants = 1

/obj/structure/city_prop/barrel/barrel11
	icon_state = "barrel11"
	variants = 1

/obj/structure/city_prop/barrel/barrel12
	icon_state = "barrel12"
	variants = 1

/obj/structure/city_prop/barrels
	name = "stacked drums"
	desc = "Several drums shoved together. The bottom ones have gone soft."
	icon_state = "random_barrels"
	base_state = "barrels"
	variants = 18
	density = TRUE
	max_integrity = 300

/obj/structure/city_prop/barrels/barrels1
	icon_state = "barrels1"
	variants = 1

/obj/structure/city_prop/barrels/barrels2
	icon_state = "barrels2"
	variants = 1

/obj/structure/city_prop/barrels/barrels3
	icon_state = "barrels3"
	variants = 1

/obj/structure/city_prop/barrels/barrels4
	icon_state = "barrels4"
	variants = 1

/obj/structure/city_prop/barrels/barrels5
	icon_state = "barrels5"
	variants = 1

/obj/structure/city_prop/barrels/barrels6
	icon_state = "barrels6"
	variants = 1

/obj/structure/city_prop/barrels/barrels7
	icon_state = "barrels7"
	variants = 1

/obj/structure/city_prop/barrels/barrels8
	icon_state = "barrels8"
	variants = 1

/obj/structure/city_prop/barrels/barrels9
	icon_state = "barrels9"
	variants = 1

/obj/structure/city_prop/barrels/barrels10
	icon_state = "barrels10"
	variants = 1

/obj/structure/city_prop/barrels/barrels11
	icon_state = "barrels11"
	variants = 1

/obj/structure/city_prop/barrels/barrels12
	icon_state = "barrels12"
	variants = 1

/obj/structure/city_prop/barrels/barrels13
	icon_state = "barrels13"
	variants = 1

/obj/structure/city_prop/barrels/barrels14
	icon_state = "barrels14"
	variants = 1

/obj/structure/city_prop/barrels/barrels15
	icon_state = "barrels15"
	variants = 1

/obj/structure/city_prop/barrels/barrels16
	icon_state = "barrels16"
	variants = 1

/obj/structure/city_prop/barrels/barrels17
	icon_state = "barrels17"
	variants = 1

/obj/structure/city_prop/barrels/barrels18
	icon_state = "barrels18"
	variants = 1

/obj/structure/city_prop/roadblock
	name = "roadblock"
	desc = "A striped timber barrier. Whatever it was closing off, it is \
		still closed."
	icon_state = "roadblock"
	density = TRUE
	max_integrity = 80

/obj/structure/city_prop/barrier
	name = "crash barrier"
	desc = "A length of steel barrier on a bolted foot."
	icon_state = "barrier"
	density = TRUE
	max_integrity = 350

/obj/structure/city_prop/ladder
	name = "access ladder"
	desc = "A fixed ladder bolted to the wall. It stops short of the \
		ground."
	icon_state = "ladder"
	max_integrity = 250

/obj/structure/city_prop/hydrant
	name = "fire hydrant"
	desc = "A street hydrant, painted and repainted until the fittings \
		barely turn."
	icon_state = "hydrant"
	density = TRUE
	max_integrity = 450

/obj/structure/city_prop/hydrant/snow
	name = "snowed fire hydrant"
	desc = "A street hydrant with a cap of snow on it."
	icon_state = "hydrant-snow"

/obj/structure/city_prop/garbage
	name = "refuse bin"
	desc = "A municipal bin, lid shut on whatever is in there."
	icon_state = "garbage"
	density = TRUE
	max_integrity = 200

/obj/structure/city_prop/garbage/open
	name = "open refuse bin"
	desc = "A municipal bin with the lid up. It has been gone through."
	icon_state = "garbage_open"

/obj/structure/city_prop/garbage/snow
	name = "snowed refuse bin"
	desc = "A municipal bin under a cap of snow."
	icon_state = "garbage-snow"

/obj/structure/city_prop/refuse
	name = "refuse pile"
	desc = "Bagged rubbish left out for a collection that is not coming."
	icon_state = "random_garbage"
	base_state = "garbage"
	variants = 9
	max_integrity = 50

/obj/structure/city_prop/refuse/garbage1
	icon_state = "garbage1"
	variants = 1

/obj/structure/city_prop/refuse/garbage2
	icon_state = "garbage2"
	variants = 1

/obj/structure/city_prop/refuse/garbage3
	icon_state = "garbage3"
	variants = 1

/obj/structure/city_prop/refuse/garbage4
	icon_state = "garbage4"
	variants = 1

/obj/structure/city_prop/refuse/garbage5
	icon_state = "garbage5"
	variants = 1

/obj/structure/city_prop/refuse/garbage6
	icon_state = "garbage6"
	variants = 1

/obj/structure/city_prop/refuse/garbage7
	icon_state = "garbage7"
	variants = 1

/obj/structure/city_prop/refuse/garbage8
	icon_state = "garbage8"
	variants = 1

/obj/structure/city_prop/refuse/garbage9
	icon_state = "garbage9"
	variants = 1

// ------------------------------------------------------------ shops

/obj/structure/city_prop/rack
	name = "clothing rail"
	desc = "A rail on castors, hung with whatever did not sell."
	icon_state = "rack"
	density = TRUE
	max_integrity = 70

/obj/structure/city_prop/rack/stocked1
	name = "clothing rail"
	icon_state = "rack1"
	density = TRUE

/obj/structure/city_prop/rack/stocked2
	name = "clothing rail"
	icon_state = "rack2"
	density = TRUE

/obj/structure/city_prop/rack/stocked3
	name = "clothing rail"
	icon_state = "rack3"
	density = TRUE

/obj/structure/city_prop/rack/stocked4
	name = "clothing rail"
	icon_state = "rack4"
	density = TRUE

/obj/structure/city_prop/rack/stocked5
	name = "clothing rail"
	icon_state = "rack5"
	density = TRUE

/obj/structure/city_prop/hanger
	name = "coat hooks"
	desc = "A row of hooks screwed to the wall."
	icon_state = "random_hanger"
	base_state = "hanger"
	variants = 4
	max_integrity = 50

/obj/structure/city_prop/hanger/hanger1
	icon_state = "hanger1"
	variants = 1

/obj/structure/city_prop/hanger/hanger2
	icon_state = "hanger2"
	variants = 1

/obj/structure/city_prop/hanger/hanger3
	icon_state = "hanger3"
	variants = 1

/obj/structure/city_prop/hanger/hanger4
	icon_state = "hanger4"
	variants = 1

/obj/structure/city_prop/large
	icon = 'ModularLobotomy/_Lobotomyicons/city_props_large.dmi'
	icon_state = "rack1"
	pixel_x = -16
	density = TRUE
	max_integrity = 300

/obj/structure/city_prop/large/shelf
	name = "shop shelving"
	desc = "Steel shelving, stripped bare."
	icon_state = "rack1"

/obj/structure/city_prop/large/shelf/stocked2
	name = "shop shelving"
	desc = "Steel shelving, still holding tinned goods and sweets."
	icon_state = "rack2"

/obj/structure/city_prop/large/shelf/stocked3
	name = "shop shelving"
	desc = "Steel shelving, still holding packet meat."
	icon_state = "rack3"

/obj/structure/city_prop/large/shelf/stocked4
	name = "shop shelving"
	desc = "Steel shelving, still holding drinks and produce."
	icon_state = "rack4"

/obj/structure/city_prop/large/shelf/stocked5
	name = "shop shelving"
	desc = "Steel shelving, still holding bottles and household."
	icon_state = "rack5"

// -------------------------------------------------------- shopfronts

/obj/structure/city_prop/sign_hotel
	name = "hotel sign"
	desc = "A projecting hotel sign. The tubing still has a flicker in it."
	icon_state = "hotel"
	max_integrity = 120

/obj/structure/city_prop/sign_hotel/snow
	name = "snowed hotel sign"
	desc = "A projecting hotel sign with snow banked on the bracket."
	icon_state = "hotel-snow"

/obj/structure/city_prop/sign_bar
	name = "bar sign"
	desc = "A bar sign hung off the frontage."
	icon_state = "bar"
	max_integrity = 120

/obj/structure/city_prop/sign_bar/snow
	name = "snowed bar sign"
	desc = "A bar sign with snow settled along the top."
	icon_state = "bar-snow"

/obj/structure/city_prop/sign_chinese1
	name = "shop sign"
	desc = "A painted board sign, hung out over the pavement."
	icon_state = "chinese1"
	max_integrity = 90

/obj/structure/city_prop/sign_chinese1/snow
	name = "snowed shop sign"
	icon_state = "chinese1-snow"

/obj/structure/city_prop/sign_chinese2
	name = "shop sign"
	desc = "A painted board sign, hung out over the pavement."
	icon_state = "chinese2"
	max_integrity = 90

/obj/structure/city_prop/sign_chinese2/snow
	name = "snowed shop sign"
	icon_state = "chinese2-snow"

/obj/structure/city_prop/sign_chinese3
	name = "shop sign"
	desc = "A painted board sign, hung out over the pavement."
	icon_state = "chinese3"
	max_integrity = 90

/obj/structure/city_prop/sign_chinese3/snow
	name = "snowed shop sign"
	icon_state = "chinese3-snow"

/obj/structure/city_prop/sign_trad
	name = "trade sign"
	desc = "An old trade sign, the lettering worn back to the primer."
	icon_state = "trad"
	max_integrity = 90

/obj/structure/city_prop/boarding
	name = "boarded frontage"
	desc = "Vertical boards nailed over a window. They have been posted \
		over since."
	icon_state = "under1"
	max_integrity = 150

/obj/structure/city_prop/boarding/plank
	name = "boarded frontage"
	desc = "Horizontal boards nailed over a window."
	icon_state = "under2"
	max_integrity = 150

/obj/structure/city_prop/boarding/brick
	name = "bricked frontage"
	desc = "The opening has been bricked up rather than boarded. Recently."
	icon_state = "bricks"
	max_integrity = 500

// ------------------------------------------------------- tall props

/obj/structure/city_prop/tall
	icon = 'ModularLobotomy/_Lobotomyicons/city_props_tall.dmi'
	icon_state = "stop"

/obj/structure/city_prop/tall/fusebox
	name = "fuse box"
	desc = "A wall fuse box, shut and painted over."
	icon_state = "fusebox"
	max_integrity = 120

/obj/structure/city_prop/tall/fusebox/open
	name = "open fuse box"
	desc = "A wall fuse box hanging open. Half the fuses are missing."
	icon_state = "fusebox_open"

/obj/structure/city_prop/tall/firehouse
	name = "fire point"
	desc = "A red cabinet marked FIRE. The seal was broken a long time \
		ago."
	icon_state = "firehouse"
	max_integrity = 180

/obj/structure/city_prop/tall/generator
	name = "generator"
	desc = "A portable generator, shut down."
	icon_state = "gen_off"
	max_integrity = 350
	var/running = FALSE

/obj/structure/city_prop/tall/generator/running
	name = "generator"
	desc = "A portable generator, running. You can feel it through the \
		pavement."
	icon_state = "gen"
	running = TRUE

/obj/structure/city_prop/tall/lowfence
	name = "low fence"
	desc = "A low timber fence, more suggestion than obstacle."
	icon_state = "lowfence"
	density = TRUE
	max_integrity = 100

/obj/structure/city_prop/tall/lowfence/corner
	name = "low fence"
	icon_state = "lowfence_corner"
	density = TRUE

/obj/structure/city_prop/tall/foodcart
	name = "food cart"
	desc = "A grill cart under a parasol. The smell carries further than \
		the licence does."
	icon_state = "random_vat"
	base_state = "vat"
	variants = 3
	density = TRUE
	max_integrity = 200

/obj/structure/city_prop/tall/foodcart/vat1
	icon_state = "vat1"
	variants = 1

/obj/structure/city_prop/tall/foodcart/vat2
	icon_state = "vat2"
	variants = 1

/obj/structure/city_prop/tall/foodcart/vat3
	icon_state = "vat3"
	variants = 1

/obj/structure/city_prop/tall/pooltable
	name = "pool table"
	desc = "A pool table with the baize worn through at the baulk end."
	icon_state = "random_billiard"
	base_state = "billiard"
	variants = 3
	density = TRUE
	max_integrity = 450

/obj/structure/city_prop/tall/pooltable/billiard1
	icon_state = "billiard1"
	variants = 1

/obj/structure/city_prop/tall/pooltable/billiard2
	icon_state = "billiard2"
	variants = 1

/obj/structure/city_prop/tall/pooltable/billiard3
	icon_state = "billiard3"
	variants = 1

// ------------------------------------------------------- road signs

/obj/structure/city_prop/tall/sign_stop
	name = "stop sign"
	desc = "An eight sided stop sign."
	icon_state = "stop"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_noenter
	name = "no entry sign"
	desc = "No entry. The bar has been stickered over."
	icon_state = "noenter"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_4way
	name = "four way stop sign"
	desc = "A stop sign with a four way plate."
	icon_state = "4way"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_allway
	name = "all way stop sign"
	desc = "A stop sign with an all way plate."
	icon_state = "allway"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_wrongway
	name = "wrong way sign"
	desc = "Wrong way. Turn back."
	icon_state = "wrongway"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_noparking
	name = "no parking sign"
	desc = "No parking at any time."
	icon_state = "noparking"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_noturnleft
	name = "no left turn sign"
	desc = "No left turn."
	icon_state = "noturnleft"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_noturnright
	name = "no right turn sign"
	desc = "No right turn."
	icon_state = "noturnright"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_noturnforward
	name = "no through road sign"
	desc = "No through traffic."
	icon_state = "noturnforward"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_noturnback
	name = "no U-turn sign"
	desc = "No U-turn."
	icon_state = "noturnback"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_nopedestrian
	name = "no pedestrians sign"
	desc = "No pedestrians beyond this point."
	icon_state = "nopedestrian"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_exitright
	name = "exit right sign"
	desc = "The exit is to the right."
	icon_state = "exitright"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_exitleft
	name = "exit left sign"
	desc = "The exit is to the left."
	icon_state = "exitleft"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_street
	name = "street name sign"
	desc = "A street name plate. The name has faded out of it."
	icon_state = "street"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_onewayleft
	name = "one way sign"
	desc = "One way, to the left."
	icon_state = "onewayleft"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_onewayright
	name = "one way sign"
	desc = "One way, to the right."
	icon_state = "onewayright"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_busstop
	name = "bus stop sign"
	desc = "A bus stop. No timetable is posted."
	icon_state = "busstop"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_railcrossing
	name = "level crossing sign"
	desc = "A level crossing warning."
	icon_state = "railcrossing"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_onlyforward
	name = "ahead only sign"
	desc = "Ahead only."
	icon_state = "onlyforward"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_onlyright
	name = "right turn only sign"
	desc = "Right turn only."
	icon_state = "onlyright"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_onlyleft
	name = "left turn only sign"
	desc = "Left turn only."
	icon_state = "onlyleft"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_speed25
	name = "speed limit sign"
	desc = "A speed limit sign reading 25."
	icon_state = "speed25"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_speed40
	name = "speed limit sign"
	desc = "A speed limit sign reading 40."
	icon_state = "speed40"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_speed50
	name = "speed limit sign"
	desc = "A speed limit sign reading 50."
	icon_state = "speed50"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_warningtrafficlight
	name = "signals ahead sign"
	desc = "Traffic signals ahead."
	icon_state = "warningtrafficlight"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_warningdeer
	name = "wild animals sign"
	desc = "Wild animals crossing. In the City, that is optimistic."
	icon_state = "warningdeer"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_warningpedestrian
	name = "pedestrian crossing sign"
	desc = "Pedestrians crossing ahead."
	icon_state = "warningpedestrian"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_circleofdoom
	name = "roundabout sign"
	desc = "A roundabout warning."
	icon_state = "circleofdoom"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_parking
	name = "parking sign"
	desc = "Parking permitted here."
	icon_state = "parking"
	max_integrity = 90

/obj/structure/city_prop/tall/sign_crosswalk
	name = "crossing sign"
	desc = "A pedestrian crossing marker."
	icon_state = "crosswalk"
	max_integrity = 90

// -------------------------------------------------------- lampposts
// 96x160, so three tiles wide and five tall. Offset back a tile so the
// post itself stands on the turf it is placed on.

/obj/structure/city_prop/lamppost
	icon = 'ModularLobotomy/_Lobotomyicons/city_lamppost.dmi'
	icon_state = "base"
	pixel_x = -32
	name = "lamp post"
	desc = "A bare lamp post. Whatever was on top of it is long gone."
	max_integrity = 400

/obj/structure/city_prop/lamppost/one
	name = "street lamp"
	desc = "A street lamp on a plain post."
	icon_state = "one"
	max_integrity = 400
	light_range = 4
	light_power = 0.8
	light_color = "#f0dfb0"

/obj/structure/city_prop/lamppost/one/snow
	name = "snowed street lamp"
	icon_state = "one-snow"

/obj/structure/city_prop/lamppost/two
	name = "tall street lamp"
	desc = "A tall street lamp. The head hums."
	icon_state = "two"
	max_integrity = 400
	light_range = 4
	light_power = 0.8
	light_color = "#f0dfb0"

/obj/structure/city_prop/lamppost/two/snow
	name = "snowed tall street lamp"
	icon_state = "two-snow"

/obj/structure/city_prop/lamppost/three
	name = "twin street lamp"
	desc = "A street lamp with two heads on a crossarm."
	icon_state = "three"
	max_integrity = 450
	light_range = 5
	light_power = 0.8
	light_color = "#f0dfb0"

/obj/structure/city_prop/lamppost/three/snow
	name = "snowed twin street lamp"
	icon_state = "three-snow"

/obj/structure/city_prop/lamppost/four
	name = "crowned street lamp"
	desc = "A twin street lamp with a beacon above the crossarm."
	icon_state = "four"
	max_integrity = 450
	light_range = 5
	light_power = 0.8
	light_color = "#f0dfb0"

/obj/structure/city_prop/lamppost/four/snow
	name = "snowed crowned street lamp"
	icon_state = "four-snow"

/obj/structure/city_prop/lamppost/traffic
	name = "traffic light"
	desc = "A traffic head. It is still cycling for traffic that is not \
		coming."
	icon_state = "traffic"
	max_integrity = 250
	light_range = 2
	light_power = 0.8
	light_color = "#f0dfb0"

/obj/structure/city_prop/lamppost/traffic/snow
	name = "snowed traffic light"
	icon_state = "traffic-snow"

/obj/structure/city_prop/lamppost/civ
	name = "ornate street lamp"
	desc = "A civic lamp with three globes. Older than the district."
	icon_state = "civ"
	max_integrity = 500
	light_range = 4
	light_power = 0.8
	light_color = "#f0dfb0"

/obj/structure/city_prop/lamppost/civ/snow
	name = "snowed ornate street lamp"
	icon_state = "civ-snow"

/obj/structure/city_prop/lamppost/chinese
	name = "signposted lamp"
	desc = "A lamp post carrying a painted sign board."
	icon_state = "chinese"
	max_integrity = 350
	light_range = 3
	light_power = 0.8
	light_color = "#f0dfb0"

/obj/structure/city_prop/lamppost/chinese/snow
	name = "snowed signposted lamp"
	icon_state = "chinese-snow"
