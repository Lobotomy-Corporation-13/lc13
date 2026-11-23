// Shipping containers for the port, one per marking on the sheet.
// Three tiles wide and two deep, so they stack and wall off a dock the way
// the real thing does.

/obj/structure/shipping_container
	name = "shipping container"
	desc = "A steel shipping container, dented and repainted more than once."
	icon = 'ModularLobotomy/_Lobotomyicons/containers.dmi'
	icon_state = "plain_rust"
	density = TRUE
	anchored = TRUE
	bound_width = 96
	bound_height = 32
	max_integrity = 400
	armor = list(MELEE = 40, BULLET = 40, LASER = 40, ENERGY = 40, BOMB = 30, BIO = 100, RAD = 100, FIRE = 60, ACID = 40)

// ------------------------------------------------ corporate and factions
/obj/structure/shipping_container/wcorp
	name = "W Corp shipping container"
	desc = "Bullet freight. It has crossed more of the City than most citizens ever will."
	icon_state = "wcorp"

/obj/structure/shipping_container/kcorp
	name = "K Corp shipping container"
	desc = "Pharmaceutical stock, sealed and stamped."
	icon_state = "kcorp"

/obj/structure/shipping_container/rcorp
	name = "R Corp shipping container"
	desc = "Ordnance. The hazard striping along the base is not decorative."
	icon_state = "rcorp"

/obj/structure/shipping_container/ncorp
	name = "N Corp shipping container"
	desc = "Hammer and nail stencilled on the flank. It is not a delivery you refuse."
	icon_state = "ncorp"

/obj/structure/shipping_container/tcorp
	name = "T Corp shipping container"
	desc = "Scheduled freight, down to the second."
	icon_state = "tcorp"

/obj/structure/shipping_container/scorp
	name = "S Corp shipping container"
	desc = "Pigment and print stock."
	icon_state = "scorp"

/obj/structure/shipping_container/ucorp
	name = "U Corp shipping container"
	desc = "Dry goods, the dull backbone of the district."
	icon_state = "ucorp"

/obj/structure/shipping_container/icorp
	name = "I Corp shipping container"
	desc = "Live culture. It is faintly warm to the touch."
	icon_state = "icorp"

/obj/structure/shipping_container/pcorp
	name = "P Corp shipping container"
	desc = "Fine goods, for whoever can still afford them."
	icon_state = "pcorp"

/obj/structure/shipping_container/hcorp
	name = "H Corp shipping container"
	desc = "Power and bolus stock."
	icon_state = "hcorp"

/obj/structure/shipping_container/mcorp
	name = "M Corp shipping container"
	desc = "Refined moonstone."
	icon_state = "mcorp"

/obj/structure/shipping_container/ycorp
	name = "Y Corp shipping container"
	desc = "Thermal wear. Frost chevrons run along the bottom rail."
	icon_state = "ycorp"

/obj/structure/shipping_container/lcorp
	name = "L Corp shipping container"
	desc = "Main branch stock. Nobody asks what is inside."
	icon_state = "lcorp"

/obj/structure/shipping_container/jcorp
	name = "J Corp shipping container"
	desc = "Gangs edition. The paint is louder than the cargo."
	icon_state = "jcorp"

/obj/structure/shipping_container/prostheti
	name = "Prostheti Innovations shipping container"
	desc = "Limbs and braces, packed by the Wells family firm."
	icon_state = "prostheti"

/obj/structure/shipping_container/molar
	name = "Molar Boatworks shipping container"
	desc = "Hull plate and fittings from the dockside yard."
	icon_state = "molar"

/obj/structure/shipping_container/fishing_office
	name = "Fishing Office shipping container"
	desc = "It smells of the pier even sealed."
	icon_state = "fishing_office"

/obj/structure/shipping_container/hana
	name = "Hana Association shipping container"
	desc = "Grade 1 fixer stock. Immaculately packed."
	icon_state = "hana"

/obj/structure/shipping_container/zwei
	name = "Zwei Association shipping container"
	desc = "Association stock, banded twice over."
	icon_state = "zwei"

/obj/structure/shipping_container/seven
	name = "Seven Association shipping container"
	desc = "Investigation stock, gold on green."
	icon_state = "seven"

/obj/structure/shipping_container/dieci
	name = "Dieci Association shipping container"
	desc = "Reagents. Handle with more care than the label suggests."
	icon_state = "dieci"

/obj/structure/shipping_container/liu
	name = "Liu Association shipping container"
	desc = "Ignition stock. Warm even in the cold."
	icon_state = "liu"

/obj/structure/shipping_container/cinq
	name = "Cinq Association shipping container"
	desc = "West wind stock, wine dark and precise."
	icon_state = "cinq"

/obj/structure/shipping_container/wedge
	name = "Wedge Office shipping container"
	desc = "Salvage, sorted by whoever got there first."
	icon_state = "wedge"

/obj/structure/shipping_container/index
	name = "Index shipping container"
	desc = "Sealed by the Index. The word is kept."
	icon_state = "index"

/obj/structure/shipping_container/index_defaced
	name = "defaced Index shipping container"
	desc = "The seal has been sprayed over. That is its own kind of statement."
	icon_state = "index_defaced"

/obj/structure/shipping_container/thumb
	name = "Thumb shipping container"
	desc = "Protection stock. The print on the side is a promise."
	icon_state = "thumb"

/obj/structure/shipping_container/kurokumo
	name = "Kurokumo Clan shipping container"
	desc = "East dock stock, marked with the spider-cloud."
	icon_state = "kurokumo"

/obj/structure/shipping_container/blade_lineage
	name = "Blade Lineage shipping container"
	desc = "Steel, and the oil to keep it."
	icon_state = "blade_lineage"

/obj/structure/shipping_container/backstreets
	name = "backstreet shipping container"
	desc = "Tagged, rusted and anonymous. Nobody claims it."
	icon_state = "backstreets"

/obj/structure/shipping_container/ncorp_defaced
	name = "defaced N Corp shipping container"
	desc = "Somebody tagged over the Nail. They were either brave or short-lived."
	icon_state = "ncorp_defaced"

/obj/structure/shipping_container/zcorp
	name = "Z Corp Security shipping container"
	desc = "Security sealed. The hazard striping is a warning, not a label."
	icon_state = "zcorp"

/obj/structure/shipping_container/resurgence
	name = "Resurgence Clan shipping container"
	desc = "Salvage, patched by hand. The sigil is painted with care."
	icon_state = "resurgence"

/obj/structure/shipping_container/insurgence
	name = "Insurgence shipping container"
	desc = "Reclaimed, repainted, and marked with a red eye."
	icon_state = "insurgence"

// ------------------------------------------------------ unmarked stock
/obj/structure/shipping_container/plain/rust
	name = "rusted shipping container"
	desc = "A rusted container, weathered down to the primer in places."
	icon_state = "plain_rust"

/obj/structure/shipping_container/plain/blue
	name = "blue shipping container"
	desc = "A blue container, weathered down to the primer in places."
	icon_state = "plain_blue"

/obj/structure/shipping_container/plain/green
	name = "green shipping container"
	desc = "A green container, weathered down to the primer in places."
	icon_state = "plain_green"

/obj/structure/shipping_container/plain/magenta
	name = "magenta shipping container"
	desc = "A magenta container, weathered down to the primer in places."
	icon_state = "plain_magenta"

/obj/structure/shipping_container/plain/orange
	name = "orange shipping container"
	desc = "A orange container, weathered down to the primer in places."
	icon_state = "plain_orange"

/obj/structure/shipping_container/plain/purple
	name = "purple shipping container"
	desc = "A purple container, weathered down to the primer in places."
	icon_state = "plain_purple"

/obj/structure/shipping_container/plain/red
	name = "red shipping container"
	desc = "A red container, weathered down to the primer in places."
	icon_state = "plain_red"

/obj/structure/shipping_container/plain/yellow
	name = "yellow shipping container"
	desc = "A yellow container, weathered down to the primer in places."
	icon_state = "plain_yellow"

// ---------------------------------------------------------- gas tanks
/obj/structure/shipping_container/gas/unmarked
	name = "unmarked gas tank"
	desc = "An unmarked pressure tank in an open steel frame."
	icon_state = "gas_unmarked"

/obj/structure/shipping_container/gas/hcorp_helium
	name = "H Corp helium tank"
	desc = "A helium tank, banded in pale blue."
	icon_state = "gas_hcorp_helium"

/obj/structure/shipping_container/gas/hcorp_hydrogen
	name = "H Corp hydrogen tank"
	desc = "A hydrogen tank. The banding is the only warning you get."
	icon_state = "gas_hcorp_hydrogen"

/obj/structure/shipping_container/gas/tcorp_plasma
	name = "T Corp plasma tank"
	desc = "A plasma tank, violet banded and humming faintly."
	icon_state = "gas_tcorp_plasma"

/obj/structure/shipping_container/gas/zcorp_sealed
	name = "Z Corp sealed tank"
	desc = "A sealed tank under Z Corp lock. Opening it is somebody else's problem."
	icon_state = "gas_zcorp_sealed"

// ------------------------------------------------------- reefer units
/obj/structure/shipping_container/reefer/unmarked
	name = "unassigned reefer"
	desc = "An unassigned refrigerated container, running on nothing."
	icon_state = "reefer_unmarked"

/obj/structure/shipping_container/reefer/kcorp
	name = "K Corp reefer"
	desc = "Cold chain, held at four degrees."
	icon_state = "reefer_kcorp"

/obj/structure/shipping_container/reefer/resurgence
	name = "Resurgence core transport"
	desc = "Core cold-storage. The amber sigil is hand painted. Handle gently."
	icon_state = "reefer_resurgence"

/obj/structure/shipping_container/reefer/insurgence
	name = "Insurgence reefer"
	desc = "The same crate, repainted. DO NOT OPEN is stencilled twice."
	icon_state = "reefer_insurgence"

// ------------------------------------------------------------------ random
// Rolls a marking on spawn, for filling a dock without hand-placing each one.

/obj/structure/shipping_container/random
	name = "shipping container"
	desc = "A container of no particular provenance."
	icon_state = "random_container"

/obj/structure/shipping_container/random/Initialize(mapload)
	. = ..()
	icon_state = pick(
		"wcorp",
		"kcorp",
		"rcorp",
		"ncorp",
		"tcorp",
		"scorp",
		"ucorp",
		"icorp",
		"pcorp",
		"hcorp",
		"mcorp",
		"ycorp",
		"lcorp",
		"jcorp",
		"prostheti",
		"molar",
		"fishing_office",
		"hana",
		"zwei",
		"seven",
		"dieci",
		"liu",
		"cinq",
		"wedge",
		"index",
		"index_defaced",
		"thumb",
		"kurokumo",
		"blade_lineage",
		"backstreets",
		"ncorp_defaced",
		"zcorp",
		"resurgence",
		"insurgence",
		"plain_rust",
		"plain_blue",
		"plain_green",
		"plain_magenta",
		"plain_orange",
		"plain_purple",
		"plain_red",
		"plain_yellow")
