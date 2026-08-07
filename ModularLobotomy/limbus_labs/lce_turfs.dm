// Turfs for the LCE lab sections. Walls and floors share one colour ramp sampled out of
// brown_wall.dmi, so any wall here can sit against any floor here.
// Three brightness variants of each: dark, base, and bright.

/*			WALLS			*/

// Corridor wall. Every LCE turf shares one sheet, so each variant needs its own state prefix
// rather than leaning on the cheap wall's generic icon-N names.
/turf/closed/indestructible/reinforced/cheap/lce
	name = "LCE corridor wall"
	desc = "A heavy panelled wall in Limbus Company house brown. The recessed plate is thick \
		enough to hide the conduit runs behind it."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_map/lce_map_turfs.dmi'
	icon_state = "lce_wall-0"
	base_icon_state = "lce_wall"

/turf/closed/indestructible/reinforced/cheap/lce/dark
	name = "unlit LCE corridor wall"
	icon_state = "lce_wall_dark-0"
	base_icon_state = "lce_wall_dark"

/turf/closed/indestructible/reinforced/cheap/lce/bright
	name = "lit LCE corridor wall"
	icon_state = "lce_wall_bright-0"
	base_icon_state = "lce_wall_bright"

// Same wall with the trim painted red. For containment approaches and restricted wings.
/turf/closed/indestructible/reinforced/cheap/lce/alarm
	name = "restricted LCE corridor wall"
	desc = "A heavy panelled wall. The trim is painted the red that means do not pass this point."
	icon_state = "lce_wall_alarm-0"
	base_icon_state = "lce_wall_alarm"

// Lab wall. Flatter and cleaner than the corridor wall - offices, labs, behind observation glass.
/turf/closed/indestructible/reinforced/lce_panel
	name = "LCE panel wall"
	desc = "A flat inset panel wall, the kind used where the rooms have to be kept clean."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_map/lce_map_turfs.dmi'
	icon_state = "lce_panel-0"
	base_icon_state = "lce_panel"

/turf/closed/indestructible/reinforced/lce_panel/dark
	name = "unlit LCE panel wall"
	icon_state = "lce_panel_dark-0"
	base_icon_state = "lce_panel_dark"

// Service wall. Bare rivet grid, no panelling - maintenance runs and back-of-house.
/turf/closed/indestructible/reinforced/lce_service
	name = "LCE service wall"
	desc = "Riveted structural plate, left bare. Nobody was expected to see this side of it."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_map/lce_map_turfs.dmi'
	icon_state = "lce_rivet-0"
	base_icon_state = "lce_rivet"

/*			FLOORS			*/

/turf/open/floor/lce
	name = "LCE floor"
	desc = "Heavy plate flooring, laid in a wide grid."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_map/lce_map_turfs.dmi'
	icon_state = "lce_plate_mid"
	base_icon_state = "lce_plate_mid"
	tiled_dirt = FALSE

// The defaults name states that only exist in floors.dmi, which would render blank here.
/turf/open/floor/lce/setup_broken_states()
	return list("lce_damaged1", "lce_damaged2", "lce_damaged3", "lce_damaged4", "lce_damaged5")

/turf/open/floor/lce/setup_burnt_states()
	return list("lce_scorched")

// Plate - the main floor. Heavy borders, large grid.
/turf/open/floor/lce/plate
	icon_state = "lce_plate_mid"
	base_icon_state = "lce_plate_mid"

/turf/open/floor/lce/plate/dark
	icon_state = "lce_plate_dark"
	base_icon_state = "lce_plate_dark"

/turf/open/floor/lce/plate/bright
	icon_state = "lce_plate_bright"
	base_icon_state = "lce_plate_bright"

// Tile - finer grid. Labs, offices, clean rooms.
/turf/open/floor/lce/tile
	name = "LCE tiling"
	desc = "Close-laid floor tiling, scrubbed pale along the walking lines."
	icon_state = "lce_tile_mid"
	base_icon_state = "lce_tile_mid"

/turf/open/floor/lce/tile/dark
	icon_state = "lce_tile_dark"
	base_icon_state = "lce_tile_dark"

/turf/open/floor/lce/tile/bright
	icon_state = "lce_tile_bright"
	base_icon_state = "lce_tile_bright"

// Deck - bare structural plating. Maintenance and unfinished sections.
/turf/open/floor/lce/deck
	name = "LCE decking"
	desc = "Bare structural decking. The finish floor was never laid over this stretch."
	icon_state = "lce_deck_mid"
	base_icon_state = "lce_deck_mid"
	footstep = FOOTSTEP_PLATING

/turf/open/floor/lce/deck/dark
	icon_state = "lce_deck_dark"
	base_icon_state = "lce_deck_dark"

/turf/open/floor/lce/deck/bright
	icon_state = "lce_deck_bright"
	base_icon_state = "lce_deck_bright"

// Grated variants. The runner strips that go down the centre of the corridors.
/turf/open/floor/lce/plate/grate
	name = "LCE grated floor"
	desc = "A perforated grating runner set into the plate. Warm air comes up through it."
	icon_state = "lce_plate_mid_grate"
	base_icon_state = "lce_plate_mid_grate"
	footstep = FOOTSTEP_PLATING

/turf/open/floor/lce/plate/dark/grate
	name = "LCE grated floor"
	desc = "A perforated grating runner set into the plate. Warm air comes up through it."
	icon_state = "lce_plate_dark_grate"
	base_icon_state = "lce_plate_dark_grate"
	footstep = FOOTSTEP_PLATING

/turf/open/floor/lce/plate/bright/grate
	name = "LCE grated floor"
	desc = "A perforated grating runner set into the plate. Warm air comes up through it."
	icon_state = "lce_plate_bright_grate"
	base_icon_state = "lce_plate_bright_grate"
	footstep = FOOTSTEP_PLATING

/turf/open/floor/lce/tile/grate
	name = "LCE grated tiling"
	desc = "A perforated grating runner set into the tiling."
	icon_state = "lce_tile_mid_grate"
	base_icon_state = "lce_tile_mid_grate"
	footstep = FOOTSTEP_PLATING

/turf/open/floor/lce/tile/dark/grate
	name = "LCE grated tiling"
	desc = "A perforated grating runner set into the tiling."
	icon_state = "lce_tile_dark_grate"
	base_icon_state = "lce_tile_dark_grate"
	footstep = FOOTSTEP_PLATING

/turf/open/floor/lce/tile/bright/grate
	name = "LCE grated tiling"
	desc = "A perforated grating runner set into the tiling."
	icon_state = "lce_tile_bright_grate"
	base_icon_state = "lce_tile_bright_grate"
	footstep = FOOTSTEP_PLATING

/turf/open/floor/lce/deck/grate
	name = "LCE grated decking"
	desc = "Grating laid straight over the structural decking."
	icon_state = "lce_deck_mid_grate"
	base_icon_state = "lce_deck_mid_grate"
	footstep = FOOTSTEP_PLATING

/turf/open/floor/lce/deck/dark/grate
	name = "LCE grated decking"
	desc = "Grating laid straight over the structural decking."
	icon_state = "lce_deck_dark_grate"
	base_icon_state = "lce_deck_dark_grate"
	footstep = FOOTSTEP_PLATING

/turf/open/floor/lce/deck/bright/grate
	name = "LCE grated decking"
	desc = "Grating laid straight over the structural decking."
	icon_state = "lce_deck_bright_grate"
	base_icon_state = "lce_deck_bright_grate"
	footstep = FOOTSTEP_PLATING

// Pad - bolted panel flooring, off the pod floor rather than /turf/open/floor/lce, so it keeps the
// pod tile stack and deconstructs the way the rest of the pod flooring does.
/turf/open/floor/pod/dark/lce
	name = "LCE panel flooring"
	desc = "Bolted panel flooring. Each pad lifts out on its own for access to the runs beneath."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_map/lce_map_turfs.dmi'
	icon_state = "lce_pad_mid"
	base_icon_state = "lce_pad_mid"
	tiled_dirt = FALSE

// Inherited from /turf/open/floor, and those states are not in this icon.
/turf/open/floor/pod/dark/lce/setup_broken_states()
	return list("lce_damaged1", "lce_damaged2", "lce_damaged3", "lce_damaged4", "lce_damaged5")

/turf/open/floor/pod/dark/lce/setup_burnt_states()
	return list("lce_scorched")

/turf/open/floor/pod/dark/lce/dark
	icon_state = "lce_pad_dark"
	base_icon_state = "lce_pad_dark"

/turf/open/floor/pod/dark/lce/bright
	icon_state = "lce_pad_bright"
	base_icon_state = "lce_pad_bright"

/turf/open/floor/pod/dark/lce/grate
	name = "LCE grated panel flooring"
	desc = "A perforated grating runner set between the panel pads."
	icon_state = "lce_pad_mid_grate"
	base_icon_state = "lce_pad_mid_grate"
	footstep = FOOTSTEP_PLATING

/turf/open/floor/pod/dark/lce/dark/grate
	name = "LCE grated panel flooring"
	desc = "A perforated grating runner set between the panel pads."
	icon_state = "lce_pad_dark_grate"
	base_icon_state = "lce_pad_dark_grate"
	footstep = FOOTSTEP_PLATING

/turf/open/floor/pod/dark/lce/bright/grate
	name = "LCE grated panel flooring"
	desc = "A perforated grating runner set between the panel pads."
	icon_state = "lce_pad_bright_grate"
	base_icon_state = "lce_pad_bright_grate"
	footstep = FOOTSTEP_PLATING
