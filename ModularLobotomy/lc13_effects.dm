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
	var/max_hits = 1
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

/obj/effect/ambient_danger/Initialize(mapload, list/ally_factions = list(), list/ordered_pattern = list(), move_on_init = TRUE)
	if(length(ally_factions))
		ignore_faction = ally_factions.Copy()
	if(length(ordered_pattern))
		move_pattern = ordered_pattern.Copy()
	. = ..()
	if(move_on_init)
		StartMovement()

/obj/effect/ambient_danger/Move()
	. = ..()
	steps--
	if(steps < 1)
		DestroyTimer()
		qdel(src)
		return
	if(!QDELETED(src) && isturf(loc))
		MovementEffect()

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
	DestroyTimer()
	return ..()

/obj/effect/ambient_danger/proc/StartMovement()
	if(length(move_pattern))
		MovePattern()

/obj/effect/ambient_danger/proc/MovePattern()
	if(QDELETED(src))
		return
	DestroyTimer()
	var/our_turf_tag = "[x],[y]"
	if(length(move_pattern))
		if(our_turf_tag in move_pattern)
			if(step(src,move_pattern[our_turf_tag],speed) && !move_cycle)
				//A runtime occurs where a timer is being called by a qdeleted object despite DestroyTimer.
				if(QDELETED(src))
					return
				move_cycle = addtimer(CALLBACK(src, PROC_REF(MovePattern)), speed, TIMER_STOPPABLE)
				return
	//We lost the pattern, go nuts.
	walk_rand(src,speed,speed)

/obj/effect/ambient_danger/proc/MovementEffect()
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

/obj/effect/ambient_danger/proc/Suffer(atom/A)
	if(isliving(A))
		var/mob/living/L = A
		if(faction_check(L.faction, ignore_faction, FALSE) || !L.density)
			return
		max_hits--
		L.deal_damage(damage, damage_type, src, attack_type = (ATTACK_TYPE_SPECIAL))
		if(max_hits < 1)
			steps = 0
		return TRUE
	return FALSE

/obj/effect/ambient_danger/proc/DestroyTimer()
	if(move_cycle)
		deltimer(move_cycle)
		move_cycle = null

/*-------------\
|Blood Splatter|
\-------------*/
/obj/effect/bloodspawner
	icon_state = "gibspawner"// For the map editor
	var/gib_mob_type  //generate a fake mob to transfer DNA from if we weren't passed a mob.
	var/sound_to_play = 'sound/effects/wounds/crackandbleed.ogg'
	var/sound_vol = 60
	//DNA on the Blood for flavor
	var/list/dna_to_add
	//If the blood hits all adjacent tiles
	var/all_around_splatter = FALSE
	var/core_gib_type = /obj/effect/decal/cleanable/blood/gibs/core

/obj/effect/bloodspawner/Initialize(mapload, mob/living/source_mob)
	. = ..()

	if(sound_to_play && isnum(sound_vol))
		playsound(src, sound_to_play, sound_vol, TRUE)

	if(source_mob)
		dna_to_add = source_mob.get_blood_dna_list() //ez pz
	else
		dna_to_add = list("Non-human DNA" = random_blood_type()) //else, generate a random bloodtype for it.
	var/turf/our_turf = get_turf(src)
	if(!our_turf)
		return INITIALIZE_HINT_QDEL
	var/list/all_turfs = RANGE_TURFS(1, our_turf) - our_turf
	//Spawn Blood where we are.
	SpawnEffect(our_turf, /obj/effect/decal/cleanable/blood, dna_to_add)
	if(core_gib_type)
		SpawnEffect(our_turf, core_gib_type, dna_to_add)
	if(!all_around_splatter)
		for(var/i = 1 to 5)
			pick_n_take(all_turfs)

	for(var/turf/T in all_turfs)
		if(!T)
			continue
		var/splash_dir = get_dir(our_turf,T)
		if(isclosedturf(T) || locate(/obj/structure/window) in T)
			SplashOnWall(our_turf, splash_dir)
		else
			SpawnEffect(T, /obj/effect/decal/cleanable/blood)

		if(T != our_turf && !T.density)
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(T, splash_dir)

	return INITIALIZE_HINT_QDEL

/obj/effect/bloodspawner/proc/SpawnEffect(location, effect_type)
	if(!effect_type)
		return
	var/obj/effect/decal/cleanable/blood/blerd = new effect_type(location)
	blerd.add_blood_DNA(dna_to_add)
	return blerd

//The reason posters do not show up on the other side of the wall is because they are technically offset spritewise
/obj/effect/bloodspawner/proc/SplashOnWall(location, dir)
	var/obj/effect/decal/cleanable/blood/splatter/over_window/splat = new(location)
	splat.add_blood_DNA(dna_to_add)
	var/offsetx = 0
	var/offsety = 0
	if(dir == NORTH || dir == NORTHWEST  || dir ==  NORTHEAST)
		offsety = 32
	if(dir == SOUTH  || dir ==  SOUTHWEST  || dir ==  SOUTHEAST)
		offsety = -32
	if(dir == EAST  || dir ==  NORTHEAST  || dir ==  SOUTHEAST)
		offsetx = 32
	if(dir == WEST  || dir ==  NORTHWEST  || dir ==  SOUTHWEST)
		offsetx = -32
	splat.pixel_x = offsetx
	splat.pixel_y = offsety

/obj/effect/bloodspawner/nogibs
	core_gib_type = null

/obj/effect/bloodspawner/silent
	sound_to_play = null
	sound_vol = 0

/obj/effect/bloodspawner/nogibs/silent
	sound_to_play = null
	sound_vol = 0

// Middle Nursefather combat effects - 48x48 (directional, centered on user for wide attacks)
/obj/effect/temp_visual/dir_setting/middle_basic_slash
	name = "middle slash"
	icon = 'icons/effects/BDragon1727_effects/48x48.dmi'
	icon_state = "middle_basic_slash"
	pixel_x = -8
	pixel_y = -8
	duration = 5
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/temp_visual/dir_setting/laevateinn_basic_slash
	name = "laevateinn slash"
	icon = 'icons/effects/BDragon1727_effects/48x48.dmi'
	icon_state = "laevateinn_basic_slash"
	pixel_x = -8
	pixel_y = -8
	duration = 5
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

// Middle Nursefather combat effects - 64x64
/// Ground slam AoE - non-directional purple particle burst, centered on impact
/obj/effect/temp_visual/middle_slam
	name = "middle slam"
	icon = 'icons/effects/BDragon1727_effects/64x64.dmi'
	icon_state = "middle_slam"
	pixel_x = -16
	pixel_y = -16
	duration = 4.5
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/// Smoke trail on tiles crossed during dash - directional, faces dash direction
/obj/effect/temp_visual/dir_setting/smoke_dash
	name = "smoke dash"
	icon = 'icons/effects/BDragon1727_effects/64x64.dmi'
	icon_state = "smoke_dash"
	pixel_x = -16
	pixel_y = -16
	duration = 8
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/// Smoke cloud at dash origin - directional, faces dash direction
/obj/effect/temp_visual/dir_setting/smoke_afterdash
	name = "smoke afterdash"
	icon = 'icons/effects/BDragon1727_effects/64x64.dmi'
	icon_state = "smoke_afterdash"
	pixel_x = -16
	pixel_y = -16
	duration = 7.5
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/// Small purple directional pierce/stab line - for precise stabs
/obj/effect/temp_visual/dir_setting/middle_slash
	name = "middle slash"
	icon = 'icons/effects/BDragon1727_effects/64x64.dmi'
	icon_state = "middle_slash"
	pixel_x = -16
	pixel_y = -16
	duration = 4
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/// Small orange/red directional pierce/stab line - for Laevateinn stabs
/obj/effect/temp_visual/dir_setting/laevateinn_stab
	name = "laevateinn stab"
	icon = 'icons/effects/BDragon1727_effects/64x64.dmi'
	icon_state = "laevateinn_stab"
	pixel_x = -16
	pixel_y = -16
	duration = 4
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/// Purple energy burst - used when punching/inflicting Weakened. Picks a random dir for visual variety.
/obj/effect/temp_visual/dir_setting/middle_blast
	name = "middle blast"
	icon = 'icons/effects/BDragon1727_effects/64x64.dmi'
	icon_state = "middle_blast"
	pixel_x = -16
	pixel_y = -16
	duration = 4
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/temp_visual/dir_setting/middle_blast/Initialize(mapload, set_dir)
	return ..(mapload, pick(GLOB.cardinals))

/// Orange/red energy burst - used when grabbing a target. Picks a random dir for visual variety.
/obj/effect/temp_visual/dir_setting/laevateinn_blast
	name = "laevateinn blast"
	icon = 'icons/effects/BDragon1727_effects/64x64.dmi'
	icon_state = "laevateinn_blast"
	pixel_x = -16
	pixel_y = -16
	duration = 4
	layer = ABOVE_MOB_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/temp_visual/dir_setting/laevateinn_blast/Initialize(mapload, set_dir)
	return ..(mapload, pick(GLOB.cardinals))
