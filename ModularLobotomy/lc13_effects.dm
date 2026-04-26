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

/*-------------------------\
|Ambient Danger Projectiles|
\-------------------------*/
/obj/effect/ambient_danger
	icon_state = "impact_laser"
	icon = 'icons/effects/effects.dmi'
	density = FALSE
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	pass_flags = PASSTABLE | PASSGLASS | PASSGRILLE
	movement_type = FLYING
	var/speed = 1 SECONDS
	var/steps = 20
	var/damage = 60
	var/damage_type = RED_DAMAGE
	var/move_cycle
	var/list/ignore_faction = list()
	/*
	* Works on Turf Tags
	* the xy of the mob is written into
	* a text string as "x,y" and we check for
	* that text string in the move_pattern
	* hopefully attached to that text string
	* is the direction we are supposed to move.
	* If the effect somehow wanders off the
	* path they will enter walk_rand.
	*/
	var/list/move_pattern = list()

/obj/effect/ambient_danger/Initialize(mapload, list/ally_factions = list(), list/ordered_pattern = list())
	if(length(ally_factions))
		ignore_faction = ally_factions.Copy()
	if(length(ordered_pattern))
		move_pattern = ordered_pattern.Copy()
	. = ..()
	StartMovement()

/obj/effect/ambient_danger/Move()
	. = ..()
	steps--
	if(steps < 1)
		qdel(src)
	if(!QDELETED(src) && isturf(loc))
		var/attack_tries = 5
		/*
		* Im apprehensive about this.
		* If there is 12 mobs on one
		* tile then only 5 of them will be checked.
		* -IP
		*/
		for(var/mob/living/pain_mobs in loc)
			if(QDELETED(src))
				break
			attack_tries--
			if(attack_tries < 1)
				break
			if(Suffer(pain_mobs))
				break

/obj/effect/ambient_danger/Crossed(atom/movable/AM)
	. = ..()
	Suffer(AM)

/obj/effect/ambient_danger/Bump(atom/A)
	. = ..()
	Suffer(A)

/obj/effect/ambient_danger/Bumped(atom/movable/AM)
	. = ..()
	Suffer(AM)

/obj/effect/ambient_danger/Destroy()
	if(move_cycle)
		deltimer(move_cycle)
		move_cycle = null
	return ..()

/obj/effect/ambient_danger/proc/StartMovement()
	if(length(move_pattern))
		MovePattern()

/obj/effect/ambient_danger/proc/MovePattern()
	if(QDELETED(src))
		return
	if(move_cycle)
		deltimer(move_cycle)
		move_cycle = null
	var/our_turf_tag = "[x],[y]"
	if(length(move_pattern))
		if(our_turf_tag in move_pattern)
			if(step(src,move_pattern[our_turf_tag],speed) && !move_cycle)
				move_cycle = addtimer(CALLBACK(src, PROC_REF(MovePattern)), speed, TIMER_STOPPABLE)
				return
	//We lost the pattern, go nuts.
	walk_rand(src,speed,speed)

/obj/effect/ambient_danger/proc/Suffer(atom/A)
	if(isliving(A))
		var/mob/living/L = A
		if(faction_check(L.faction, ignore_faction, FALSE) || !L.density)
			return
		L.deal_damage(damage, damage_type, src, attack_type = (ATTACK_TYPE_SPECIAL))
		qdel(src)
		return TRUE
	return FALSE
