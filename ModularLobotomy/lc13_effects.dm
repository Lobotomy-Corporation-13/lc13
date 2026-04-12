//Cosmetic Effects
/obj/effect/wall_vent
	name = "wall vent"
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_structures.dmi'
	icon_state = "wall_vent"

/obj/effect/temp_visual/roomdamage  // room damage effect
	name = "generic damage effect"
	duration = 15
	icon = 'icons/effects/160x96.dmi'
	icon_state = "red"
	layer = ABOVE_OPEN_TURF_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/temp_visual/roomdamage/Initialize(mapload, set_dir)
	. = ..()
	animate(src, pixel_x = base_pixel_x + rand(-3, 3), pixel_y = base_pixel_y + rand(-3, 3), time = 1)
	addtimer(CALLBACK(src, PROC_REF(ResetAnim)),2)

/obj/effect/temp_visual/roomdamage/proc/ResetAnim()
	pixel_x = base_pixel_x
	pixel_y = base_pixel_y
	animate(src, alpha = 0, time = 13)

/obj/effect/temp_visual/workcomplete  // Work complete effect
	name = "work complete"
	duration = 15
	icon = 'icons/effects/160x96.dmi'
	icon_state = "normal"
	layer = ABOVE_ALL_MOB_LAYER
	alpha = 200
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/temp_visual/workcomplete/Initialize(mapload, set_dir)
	. = ..()
	animate(src, alpha = 100, time = 5)
	addtimer(CALLBACK(src, PROC_REF(ResetAnim)),5)

/obj/effect/temp_visual/workcomplete/proc/ResetAnim()
	animate(src, alpha = 200, time = 5)
	sleep(5)
	animate(src, alpha = 0, time = 5)

/obj/effect/extraction_effect
	name = "extraction effect"
	icon = 'icons/effects/160x96.dmi'
	icon_state = "key" //Can be set to "lock" with the other tool
	layer = FLY_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/extraction_effect/Initialize(mapload, set_dir)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(StartAnimation)),5)

/obj/effect/extraction_effect/proc/StartAnimation()
	if(QDELETED(src))
		return
	animate(src, alpha = 255, time = 30)
	sleep(30)
	if(QDELETED(src))
		return
	animate(src, alpha = 100, time = 30)
	addtimer(CALLBACK(src, PROC_REF(StartAnimation)),30)

// BDragon1727 temp visual effects
/obj/effect/temp_visual/dir_setting/gray_edge
	name = "gray edge"
	icon = 'icons/effects/BDragon1727_effects/48x48.dmi'
	icon_state = "gray_edge"
	pixel_x = -8
	pixel_y = -8
	duration = 5
	/// Whether to shift 10 pixels toward the facing direction
	var/directional_shift = FALSE

/obj/effect/temp_visual/dir_setting/gray_edge/Initialize(mapload, set_dir)
	. = ..()
	if(!directional_shift)
		return
	switch(dir)
		if(NORTH)
			pixel_y += 10
		if(SOUTH)
			pixel_y -= 10
		if(EAST)
			pixel_x += 10
		if(WEST)
			pixel_x -= 10

/obj/effect/temp_visual/dir_setting/gray_edge/seven
	color = "#00CC00"
	directional_shift = TRUE

/obj/effect/temp_visual/dir_setting/gray_edge/seven/passthrough
	directional_shift = FALSE

/obj/effect/temp_visual/dir_setting/gray_edge/zwei
	color = "#4444FF"
	directional_shift = TRUE

/obj/effect/temp_visual/dir_setting/gray_edge/zwei/passthrough
	directional_shift = FALSE

/obj/effect/temp_visual/dir_setting/gray_edge/dieci
	color = "#FFD700"
	directional_shift = TRUE

/obj/effect/temp_visual/dir_setting/gray_edge/dieci/passthrough
	directional_shift = FALSE

/obj/effect/temp_visual/dir_setting/gray_cube_v1
	name = "gray cube"
	icon = 'icons/effects/BDragon1727_effects/48x48.dmi'
	icon_state = "gray_cube_v1"
	pixel_x = -8
	pixel_y = -8
	duration = 5
	/// Whether to shift 10 pixels toward the facing direction
	var/directional_shift = FALSE

/obj/effect/temp_visual/dir_setting/gray_cube_v1/Initialize(mapload, set_dir)
	. = ..()
	if(!directional_shift)
		return
	switch(dir)
		if(NORTH)
			pixel_y += 10
		if(SOUTH)
			pixel_y -= 10
		if(EAST)
			pixel_x += 10
		if(WEST)
			pixel_x -= 10

/obj/effect/temp_visual/dir_setting/gray_cube_v1/seven
	color = "#00CC00"
	directional_shift = TRUE

/obj/effect/temp_visual/dir_setting/gray_cube_v1/zwei
	color = "#4444FF"
	directional_shift = TRUE

/obj/effect/temp_visual/dir_setting/gray_cube_v1/zwei/passthrough
	directional_shift = FALSE

/obj/effect/temp_visual/dir_setting/gray_cube_v1/dieci
	color = "#FFD700"
	directional_shift = TRUE

//Kikimora Graffiti
/obj/effect/decal/cleanable/crayon/cognito
	name = "graffiti"
	desc = "strange graffiti. You can almost make out what it says."
	icon = 'ModularLobotomy/_Lobotomyicons/wall_markings.dmi'
	icon_state = "gibberish"
	anchored = TRUE
	var/datum/status_effect/inflicted_effect = /datum/status_effect/display/dyscrasone_withdrawl

/obj/effect/decal/cleanable/crayon/cognito/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/cognitohazard_visual, _cognitohazard_visual_effect=inflicted_effect, obvious=TRUE)
