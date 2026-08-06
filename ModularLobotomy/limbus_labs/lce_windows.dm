// Containment glass for the LCE labs. Built on the reinforced window, so it keeps that type's
// armour, its explosion blocking and its multi-step disassembly - the only thing that changes is
// how much it takes to break, and what it looks like.
//
// 3000 integrity is twenty times a reinforced full-tile window. These are meant to hold a
// specimen in, not to survive a fight, so anything that gets through one has earned it.

/*			GLASS			*/

/obj/structure/window/reinforced/lce
	name = "LCE observation pane"
	desc = "Containment glass in a brown LCE frame. Thick enough that the world beyond it goes \
		slightly amber, and rated to be leaned on by whatever is on the other side."
	max_integrity = 3000

/obj/structure/window/reinforced/lce/fulltile
	icon = 'ModularLobotomy/_Lobotomyicons/lce_map/lce_window.dmi'
	icon_state = "lce_window-0"
	base_icon_state = "lce_window"
	fulltile = TRUE
	flags_1 = PREVENT_CLICK_UNDER_1
	state = RWINDOW_SECURE
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_WINDOW_FULLTILE)
	canSmoothWith = list(SMOOTH_GROUP_WINDOW_FULLTILE, SMOOTH_GROUP_WALLS, SMOOTH_GROUP_AIRLOCK)
	glass_amount = 2

// Opaque. For the control booths, where the point is that the specimen cannot see who is watching.
/obj/structure/window/reinforced/lce/tinted
	name = "LCE tinted pane"
	desc = "Containment glass darkened until it is a mirror from the other side. The booth sees \
		out. Nothing sees in."
	opacity = TRUE

/obj/structure/window/reinforced/lce/tinted/fulltile
	icon = 'ModularLobotomy/_Lobotomyicons/lce_map/lce_window_tinted.dmi'
	icon_state = "lce_window_tinted-0"
	base_icon_state = "lce_window_tinted"
	fulltile = TRUE
	flags_1 = PREVENT_CLICK_UNDER_1
	state = RWINDOW_SECURE
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_WINDOW_FULLTILE)
	canSmoothWith = list(SMOOTH_GROUP_WINDOW_FULLTILE, SMOOTH_GROUP_WALLS, SMOOTH_GROUP_AIRLOCK)
	glass_amount = 2

// Also opaque, but pale rather than dark. Offices and washrooms - privacy without a mirror.
/obj/structure/window/reinforced/lce/frosted
	name = "LCE frosted pane"
	desc = "Containment glass etched until it is only light and shapes. Nobody chose this for \
		security; somebody chose it so the offices would not feel like cells."
	opacity = TRUE

/obj/structure/window/reinforced/lce/frosted/fulltile
	icon = 'ModularLobotomy/_Lobotomyicons/lce_map/lce_window_frosted.dmi'
	icon_state = "lce_window_frosted-0"
	base_icon_state = "lce_window_frosted"
	fulltile = TRUE
	flags_1 = PREVENT_CLICK_UNDER_1
	state = RWINDOW_SECURE
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_WINDOW_FULLTILE)
	canSmoothWith = list(SMOOTH_GROUP_WINDOW_FULLTILE, SMOOTH_GROUP_WALLS, SMOOTH_GROUP_AIRLOCK)
	glass_amount = 2

/*			SPAWNERS			*/

// One per glass type, each the LCE answer to /obj/effect/spawner/structure/window/reinforced.
// They keep the grille, so the window still builds and deconstructs the way a mapper expects.

/obj/effect/spawner/structure/window/reinforced/lce
	name = "LCE observation window spawner"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/lce/fulltile)

/obj/effect/spawner/structure/window/reinforced/lce/tinted
	name = "LCE tinted window spawner"
	icon_state = "twindow_spawner"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/lce/tinted/fulltile)

/obj/effect/spawner/structure/window/reinforced/lce/frosted
	name = "LCE frosted window spawner"
	icon_state = "twindow_spawner"
	spawn_list = list(/obj/structure/grille, /obj/structure/window/reinforced/lce/frosted/fulltile)
