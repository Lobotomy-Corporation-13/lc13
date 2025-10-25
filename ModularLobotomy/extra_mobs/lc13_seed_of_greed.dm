//////////////
// SEED OF GREED - OUTPOST BUILDING SYSTEM
//////////////
// Deployable structure that automatically constructs a defensive outpost over 10 seconds
// Creates barricades, turrets, and support buildings in predefined patterns

/obj/structure/seed_of_greed
	name = "Seed of Greed"
	desc = "A pulsating mass of flesh and metal that rapidly constructs an outpost."
	icon = 'icons/mob/cult.dmi'
	icon_state = "meat_bomb"
	density = TRUE
	anchored = TRUE
	max_integrity = 5000
	layer = BELOW_OBJ_LAYER

	// Building configuration
	var/build_time = 10 SECONDS
	var/current_stage = 0
	var/max_stages = 5
	var/stage_delay = 2 SECONDS
	var/list/build_timers = list()

	// Layout patterns - list of relative positions from center
	var/list/barricade_positions_inner = list()
	var/list/barricade_positions_outer = list()
	var/list/turret_positions = list()
	var/list/anchor_positions = list()
	var/list/special_positions = list() // For variant-specific buildings

	// Building types to spawn - using existing clan mob types
	var/turret_type = null // Will use specific clan units instead
	var/anchor_type = null // Will use specific clan units instead
	var/special_type = null // Variant-specific
	var/shield_generator_type = null // Shield generator to spawn

/obj/structure/seed_of_greed/Initialize()
	. = ..()
	StartSpawnSequence()

// Spawn sequence similar to corrupter
/obj/structure/seed_of_greed/proc/StartSpawnSequence()
	// Make invisible and intangible during spawn
	alpha = 0
	density = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	resistance_flags = INDESTRUCTIBLE // Can't be destroyed while spawning

	// Create warning indicator - red warning for 5 seconds
	new /obj/effect/temp_visual/giantwarning/red(get_turf(src))

	// Play ominous sound
	playsound(get_turf(src), 'sound/magic/castsummon.ogg', 75, TRUE)

	// Wait 5 seconds before dropping in
	addtimer(CALLBACK(src, PROC_REF(PerformDropIn)), 5 SECONDS)

// Drop in animation and start construction
/obj/structure/seed_of_greed/proc/PerformDropIn()
	// Falling animation
	pixel_z = 128
	alpha = 255
	playsound(get_turf(src), 'sound/effects/curse3.ogg', 75, TRUE)

	// Animate falling
	animate(src, pixel_z = 0, time = 10)

	// After landing, restore properties and start building
	addtimer(CALLBACK(src, PROC_REF(StartBuilding)), 1 SECONDS)

// Actually start the construction process
/obj/structure/seed_of_greed/proc/StartBuilding()
	// Restore physical properties
	density = TRUE
	mouse_opacity = initial(mouse_opacity)
	resistance_flags = initial(resistance_flags)

	// Generate layout and start construction
	GenerateLayoutPattern()
	ShowConstructionPlan()
	StartConstruction()

	visible_message(span_danger("[src] begins pulsating as it starts constructing an outpost!"))
	playsound(src, 'sound/magic/demon_dies.ogg', 50, TRUE)

	// Pulsating effect during construction
	animate(src, alpha = 150, time = 10, loop = -1)
	animate(alpha = 255, time = 10)

/obj/structure/seed_of_greed/Destroy()
	// Cancel all timers if destroyed early
	for(var/timer in build_timers)
		deltimer(timer)
	build_timers.Cut()
	return ..()

//////////////
// LAYOUT GENERATION
//////////////

/obj/structure/seed_of_greed/proc/GenerateLayoutPattern()
	// Generate inner barricade ring (radius 1)
	for(var/dir in GLOB.alldirs)
		var/turf/T = get_step(src, dir)
		if(T)
			barricade_positions_inner += T

	// Generate outer barricade ring (radius 2)
	barricade_positions_outer = GenerateSquarePattern(2)

	// Set turret and anchor positions (override in variants)
	SetSpecialPositions()

/obj/structure/seed_of_greed/proc/GenerateSquarePattern(radius)
	var/list/positions = list()
	var/turf/center = get_turf(src)
	if(!center)
		return positions

	for(var/x = -radius to radius)
		for(var/y = -radius to radius)
			if(abs(x) == radius || abs(y) == radius)
				var/turf/T = locate(center.x + x, center.y + y, center.z)
				if(T && T.z == center.z) // Don't build across z-levels
					positions += T
	return positions

/obj/structure/seed_of_greed/proc/SetSpecialPositions()
	// Override in variants
	// Default: no special positions
	return

/obj/structure/seed_of_greed/proc/SafeGetTurf(x_offset, y_offset)
	var/turf/center = get_turf(src)
	if(!center)
		return null
	var/turf/T = locate(center.x + x_offset, center.y + y_offset, center.z)
	if(!T || T.z != center.z) // Don't build across z-levels
		return null
	return T

//////////////
// CONSTRUCTION STAGES
//////////////

/obj/structure/seed_of_greed/proc/StartConstruction()
	// Stage 1: Inner barricades (0 seconds)
	build_timers += addtimer(CALLBACK(src, PROC_REF(BuildStage1)), 0, TIMER_STOPPABLE)

	// Stage 2: Outer barricades (2 seconds)
	build_timers += addtimer(CALLBACK(src, PROC_REF(BuildStage2)), 2 SECONDS, TIMER_STOPPABLE)

	// Stage 3: Turrets (4 seconds)
	build_timers += addtimer(CALLBACK(src, PROC_REF(BuildStage3)), 4 SECONDS, TIMER_STOPPABLE)

	// Stage 4: Chain Anchors (6 seconds)
	build_timers += addtimer(CALLBACK(src, PROC_REF(BuildStage4)), 6 SECONDS, TIMER_STOPPABLE)

	// Stage 5: Special Buildings (8 seconds)
	build_timers += addtimer(CALLBACK(src, PROC_REF(BuildStage5)), 8 SECONDS, TIMER_STOPPABLE)

	// Self-destruct (10 seconds)
	build_timers += addtimer(CALLBACK(src, PROC_REF(CompleteBuild)), 10 SECONDS, TIMER_STOPPABLE)

/obj/structure/seed_of_greed/proc/BuildStage1()
	if(QDELETED(src))
		return
	visible_message(span_notice("[src] deploys inner barricades!"))
	for(var/turf/T in barricade_positions_inner)
		TryPlaceStructure(T, /obj/structure/xcorp_barricade)
	current_stage = 1

/obj/structure/seed_of_greed/proc/BuildStage2()
	if(QDELETED(src))
		return
	visible_message(span_notice("[src] extends outer barricades!"))
	for(var/turf/T in barricade_positions_outer)
		TryPlaceStructure(T, /obj/structure/xcorp_barricade)
	current_stage = 2

/obj/structure/seed_of_greed/proc/BuildStage3()
	if(QDELETED(src))
		return
	if(turret_type)
		visible_message(span_warning("[src] deploys defensive turrets!"))
		for(var/turf/T in turret_positions)
			TryPlaceMob(T, turret_type)
	current_stage = 3

/obj/structure/seed_of_greed/proc/BuildStage4()
	if(QDELETED(src))
		return
	if(anchor_type)
		visible_message(span_warning("[src] establishes chain anchors!"))
		for(var/turf/T in anchor_positions)
			TryPlaceMob(T, anchor_type)
	current_stage = 4

/obj/structure/seed_of_greed/proc/BuildStage5()
	if(QDELETED(src))
		return
	if(special_type && length(special_positions))
		visible_message(span_danger("[src] deploys special equipment!"))
		for(var/turf/T in special_positions)
			if(ispath(special_type, /mob))
				TryPlaceMob(T, special_type)
			else
				TryPlaceStructure(T, special_type)
	current_stage = 5

/obj/structure/seed_of_greed/proc/CompleteBuild()
	if(QDELETED(src))
		return
	visible_message(span_boldwarning("[src] has completed the outpost construction and crumbles!"))
	playsound(src, 'sound/effects/break_stone.ogg', 50, TRUE)
	qdel(src)

//////////////
// PLACEMENT LOGIC
//////////////

/obj/structure/seed_of_greed/proc/TryPlaceStructure(turf/T, obj_type)
	// Validate turf
	if(!T || T.density)
		return FALSE

	// Check for dense objects
	for(var/obj/O in T)
		if(O.density && !istype(O, /obj/structure/seed_of_greed))
			return FALSE

	// Check for walls
	if(locate(/turf/closed) in T)
		return FALSE

	// Safe to place
	var/obj/placed = new obj_type(T)

	// Visual effect
	new /obj/effect/temp_visual/dir_setting/cult/phase(T)
	playsound(T, 'sound/effects/phasein.ogg', 30, TRUE)

	return placed

/obj/structure/seed_of_greed/proc/TryPlaceMob(turf/T, mob_type)
	if(!T || T.density)
		return FALSE

	for(var/obj/O in T)
		if(O.density && !istype(O, /obj/structure/seed_of_greed))
			return FALSE

	var/mob/M = new mob_type(T)

	// Set faction for spawned mobs
	if(istype(M, /mob/living/simple_animal))
		var/mob/living/simple_animal/S = M
		S.faction = list("greed_clan", "hostile")

	new /obj/effect/temp_visual/dir_setting/cult/phase(T)
	playsound(T, 'sound/effects/phasein.ogg', 40, TRUE)

	return M

//////////////
// VISUAL EFFECTS
//////////////

/obj/structure/seed_of_greed/proc/ShowConstructionPlan()
	// Show where things will be built
	for(var/turf/T in barricade_positions_inner + barricade_positions_outer)
		new /obj/effect/temp_visual/warper_area(T)
	for(var/turf/T in turret_positions)
		var/obj/effect/E = new /obj/effect/temp_visual/warper_area(T)
		E.color = "#FF0000"
	for(var/turf/T in anchor_positions)
		var/obj/effect/E = new /obj/effect/temp_visual/warper_area(T)
		E.color = "#00FF00"
	for(var/turf/T in special_positions)
		var/obj/effect/E = new /obj/effect/temp_visual/warper_area(T)
		E.color = "#0000FF"

//////////////
// OUTPOST VARIANTS - 3 Types with 3 Levels Each
//////////////

//////////////
// BASIC OUTPOST - Standard balanced configuration
//////////////

// Basic Level 1 - Light defense
/obj/structure/seed_of_greed/basic
	name = "Seed of Greed (Basic)"
	desc = "Constructs a standard defensive outpost."

/obj/structure/seed_of_greed/basic/level1
	name = "Seed of Greed (Basic I)"
	turret_type = /mob/living/simple_animal/hostile/clan/ranged/turret/level1
	anchor_type = /mob/living/simple_animal/hostile/clan/chain_anchor/gunner

/obj/structure/seed_of_greed/basic/level1/SetSpecialPositions()
	// 2 turrets at opposite corners
	turret_positions = list(
		SafeGetTurf(2, 2),
		SafeGetTurf(-2, -2)
	)

	// 1 gunner anchor
	anchor_positions = list(
		SafeGetTurf(0, 0)
	)

	turret_positions -= null
	anchor_positions -= null

// Basic Level 2 - Medium defense
/obj/structure/seed_of_greed/basic/level2
	name = "Seed of Greed (Basic II)"
	turret_type = /mob/living/simple_animal/hostile/clan/ranged/turret/level2
	anchor_type = /mob/living/simple_animal/hostile/clan/chain_anchor/rapid

/obj/structure/seed_of_greed/basic/level2/SetSpecialPositions()
	// 4 turrets at corners
	turret_positions = list(
		SafeGetTurf(2, 2),
		SafeGetTurf(2, -2),
		SafeGetTurf(-2, 2),
		SafeGetTurf(-2, -2)
	)

	// 2 rapid anchors on sides
	anchor_positions = list(
		SafeGetTurf(3, 0),
		SafeGetTurf(-3, 0)
	)

	turret_positions -= null
	anchor_positions -= null

// Basic Level 3 - Heavy defense
/obj/structure/seed_of_greed/basic/level3
	name = "Seed of Greed (Basic III)"
	turret_type = /mob/living/simple_animal/hostile/clan/ranged/turret/level3
	anchor_type = /mob/living/simple_animal/hostile/clan/chain_anchor/sniper
	special_type = /mob/living/simple_animal/hostile/clan/drone/greed

/obj/structure/seed_of_greed/basic/level3/SetSpecialPositions()
	// 4 level 3 turrets at corners
	turret_positions = list(
		SafeGetTurf(2, 2),
		SafeGetTurf(2, -2),
		SafeGetTurf(-2, 2),
		SafeGetTurf(-2, -2)
	)

	// 3 sniper anchors in triangle
	anchor_positions = list(
		SafeGetTurf(0, 3),
		SafeGetTurf(3, -1),
		SafeGetTurf(-3, -1)
	)

	// 2 greed drones for support
	special_positions = list(
		SafeGetTurf(0, 0),
		SafeGetTurf(0, -2)
	)

	turret_positions -= null
	anchor_positions -= null
	special_positions -= null

//////////////
// DEFENSIVE OUTPOST - Maximum fortification
//////////////

// Defensive Level 1 - Basic fortification
/obj/structure/seed_of_greed/defensive
	name = "Seed of Greed (Defensive)"
	desc = "Constructs a heavily fortified position."
	var/list/barricade_positions_extra = list() // Third ring for higher levels

/obj/structure/seed_of_greed/defensive/level1
	name = "Seed of Greed (Defensive I)"
	turret_type = /mob/living/simple_animal/hostile/clan/ranged/turret/level1
	anchor_type = /mob/living/simple_animal/hostile/clan/chain_anchor/gunner

/obj/structure/seed_of_greed/defensive/level1/SetSpecialPositions()
	// 4 turrets in square
	turret_positions = list(
		SafeGetTurf(1, 1),
		SafeGetTurf(1, -1),
		SafeGetTurf(-1, 1),
		SafeGetTurf(-1, -1)
	)

	// 2 gunner anchors
	anchor_positions = list(
		SafeGetTurf(2, 0),
		SafeGetTurf(-2, 0)
	)

	turret_positions -= null
	anchor_positions -= null

// Defensive Level 2 - Enhanced fortification
/obj/structure/seed_of_greed/defensive/level2
	name = "Seed of Greed (Defensive II)"
	turret_type = /mob/living/simple_animal/hostile/clan/ranged/turret/level2
	anchor_type = /mob/living/simple_animal/hostile/clan/chain_anchor/rapid
	special_type = /mob/living/simple_animal/hostile/clan/defender/greed

/obj/structure/seed_of_greed/defensive/level2/GenerateLayoutPattern()
	..()
	barricade_positions_extra = GenerateSquarePattern(3)

/obj/structure/seed_of_greed/defensive/level2/SetSpecialPositions()
	// 6 turrets in hexagon
	turret_positions = list(
		SafeGetTurf(2, 1),
		SafeGetTurf(2, -1),
		SafeGetTurf(-2, 1),
		SafeGetTurf(-2, -1),
		SafeGetTurf(0, 2),
		SafeGetTurf(0, -2)
	)

	// 3 rapid anchors
	anchor_positions = list(
		SafeGetTurf(3, 0),
		SafeGetTurf(-1, 3),
		SafeGetTurf(-1, -3)
	)

	// 1 greed defender in center
	special_positions = list(get_turf(src))

	turret_positions -= null
	anchor_positions -= null
	special_positions -= null

/obj/structure/seed_of_greed/defensive/level2/BuildStage2()
	..()
	if(QDELETED(src))
		return
	visible_message(span_notice("[src] reinforces with additional barricades!"))
	for(var/turf/T in barricade_positions_extra)
		TryPlaceStructure(T, /obj/structure/xcorp_barricade)

// Defensive Level 3 - Maximum fortification
/obj/structure/seed_of_greed/defensive/level3
	name = "Seed of Greed (Defensive III)"
	turret_type = /mob/living/simple_animal/hostile/clan/ranged/turret/level3
	anchor_type = /mob/living/simple_animal/hostile/clan/chain_anchor/warper
	special_type = /mob/living/simple_animal/hostile/clan/drone/greed

/obj/structure/seed_of_greed/defensive/level3/GenerateLayoutPattern()
	..()
	barricade_positions_extra = GenerateSquarePattern(3)

/obj/structure/seed_of_greed/defensive/level3/SetSpecialPositions()
	// 8 turrets in octagon
	turret_positions = list(
		SafeGetTurf(3, 0),
		SafeGetTurf(-3, 0),
		SafeGetTurf(0, 3),
		SafeGetTurf(0, -3),
		SafeGetTurf(2, 2),
		SafeGetTurf(2, -2),
		SafeGetTurf(-2, 2),
		SafeGetTurf(-2, -2)
	)

	// 4 warper anchors
	anchor_positions = list(
		SafeGetTurf(3, 3),
		SafeGetTurf(3, -3),
		SafeGetTurf(-3, 3),
		SafeGetTurf(-3, -3)
	)

	// 3 greed drones for healing
	special_positions = list(
		get_turf(src),
		SafeGetTurf(0, 1),
		SafeGetTurf(0, -1)
	)

	turret_positions -= null
	anchor_positions -= null
	special_positions -= null

/obj/structure/seed_of_greed/defensive/level3/BuildStage2()
	..()
	if(QDELETED(src))
		return
	visible_message(span_notice("[src] reinforces with additional barricades!"))
	for(var/turf/T in barricade_positions_extra)
		TryPlaceStructure(T, /obj/structure/xcorp_barricade)

//////////////
// ASSAULT OUTPOST - Maximum firepower
//////////////

// Assault Level 1 - Basic artillery
/obj/structure/seed_of_greed/assault
	name = "Seed of Greed (Assault)"
	desc = "Constructs an aggressive artillery position."

/obj/structure/seed_of_greed/assault/level1
	name = "Seed of Greed (Assault I)"
	turret_type = /mob/living/simple_animal/hostile/clan/ranged/turret/artillery/level1
	anchor_type = /mob/living/simple_animal/hostile/clan/chain_anchor/harpooner

/obj/structure/seed_of_greed/assault/level1/SetSpecialPositions()
	// 2 artillery turrets
	turret_positions = list(
		SafeGetTurf(0, 2),
		SafeGetTurf(0, -2)
	)

	// 1 harpooner anchor
	anchor_positions = list(
		SafeGetTurf(0, 0)
	)

	turret_positions -= null
	anchor_positions -= null

/obj/structure/seed_of_greed/assault/level1/GenerateLayoutPattern()
	// Minimal barricades
	for(var/dir in GLOB.alldirs)
		var/turf/T = get_step(src, dir)
		if(T)
			barricade_positions_inner += T
	barricade_positions_outer = list()
	// Call SetSpecialPositions to populate turret and anchor positions
	SetSpecialPositions()

// Assault Level 2 - Enhanced artillery
/obj/structure/seed_of_greed/assault/level2
	name = "Seed of Greed (Assault II)"
	turret_type = /mob/living/simple_animal/hostile/clan/ranged/turret/artillery/level2
	anchor_type = /mob/living/simple_animal/hostile/clan/chain_anchor/harpooner
	special_type = /mob/living/simple_animal/hostile/clan/assassin/greed

/obj/structure/seed_of_greed/assault/level2/SetSpecialPositions()
	// 3 artillery turrets in triangle
	turret_positions = list(
		SafeGetTurf(0, 3),
		SafeGetTurf(3, -1),
		SafeGetTurf(-3, -1)
	)

	// 2 harpooner anchors
	anchor_positions = list(
		SafeGetTurf(2, 0),
		SafeGetTurf(-2, 0)
	)

	// 1 greed assassin
	special_positions = list(get_turf(src))

	turret_positions -= null
	anchor_positions -= null
	special_positions -= null

/obj/structure/seed_of_greed/assault/level2/GenerateLayoutPattern()
	// Minimal barricades
	for(var/dir in GLOB.alldirs)
		var/turf/T = get_step(src, dir)
		if(T)
			barricade_positions_inner += T
	barricade_positions_outer = list()
	// Call SetSpecialPositions to populate turret and anchor positions
	SetSpecialPositions()

//////////////
// SHIELD GENERATOR SEEDS - Spawns shield generators
//////////////

/obj/structure/seed_of_greed/shield
	name = "Seed of Greed (Shield)"
	desc = "Constructs a fortified position with shield generator support."

// Shield Level 1 - Basic shield generator
/obj/structure/seed_of_greed/shield/level1
	name = "Seed of Greed (Shield I)"
	special_type = /mob/living/simple_animal/hostile/clan/shield_generator/level1
	turret_type = /mob/living/simple_animal/hostile/clan/ranged/turret/level1
	anchor_type = /mob/living/simple_animal/hostile/clan/chain_anchor/gunner

/obj/structure/seed_of_greed/shield/level1/SetSpecialPositions()
	// 1 shield generator in center
	special_positions = list(
		get_turf(src)
	)

	// 2 turrets for protection
	turret_positions = list(
		SafeGetTurf(2, 0),
		SafeGetTurf(-2, 0)
	)

	// 2 gunner anchors
	anchor_positions = list(
		SafeGetTurf(0, 2),
		SafeGetTurf(0, -2)
	)

	turret_positions -= null
	anchor_positions -= null
	special_positions -= null

// Shield Level 2 - Enhanced shield generator
/obj/structure/seed_of_greed/shield/level2
	name = "Seed of Greed (Shield II)"
	special_type = /mob/living/simple_animal/hostile/clan/shield_generator/level2
	turret_type = /mob/living/simple_animal/hostile/clan/ranged/turret/level2
	anchor_type = /mob/living/simple_animal/hostile/clan/chain_anchor/rapid

/obj/structure/seed_of_greed/shield/level2/SetSpecialPositions()
	// 1 shield generator in center
	special_positions = list(
		get_turf(src)
	)

	// 3 turrets for protection
	turret_positions = list(
		SafeGetTurf(2, 0),
		SafeGetTurf(-2, 0),
		SafeGetTurf(0, 2)
	)

	// 3 rapid anchors
	anchor_positions = list(
		SafeGetTurf(1, 1),
		SafeGetTurf(-1, 1),
		SafeGetTurf(0, -2)
	)

	turret_positions -= null
	anchor_positions -= null
	special_positions -= null

// Shield Level 3 - Maximum shield coverage
/obj/structure/seed_of_greed/shield/level3
	name = "Seed of Greed (Shield III)"
	special_type = /mob/living/simple_animal/hostile/clan/shield_generator/level3
	turret_type = /mob/living/simple_animal/hostile/clan/ranged/turret/artillery/level2
	anchor_type = /mob/living/simple_animal/hostile/clan/chain_anchor/sniper

/obj/structure/seed_of_greed/shield/level3/SetSpecialPositions()
	// 1 shield generator in center
	special_positions = list(
		get_turf(src)
	)

	// 4 artillery turrets for maximum defense
	turret_positions = list(
		SafeGetTurf(2, 2),
		SafeGetTurf(-2, 2),
		SafeGetTurf(2, -2),
		SafeGetTurf(-2, -2)
	)

	// 2 sniper anchors
	anchor_positions = list(
		SafeGetTurf(3, 0),
		SafeGetTurf(-3, 0)
	)

	turret_positions -= null
	anchor_positions -= null
	special_positions -= null

// Assault Level 3 - Maximum artillery
/obj/structure/seed_of_greed/assault/level3
	name = "Seed of Greed (Assault III)"
	turret_type = /mob/living/simple_animal/hostile/clan/ranged/turret/artillery/level3
	anchor_type = /mob/living/simple_animal/hostile/clan/chain_anchor/sniper
	special_type = /mob/living/simple_animal/hostile/clan/demolisher/greed

/obj/structure/seed_of_greed/assault/level3/SetSpecialPositions()
	// 4 level 3 artillery turrets
	turret_positions = list(
		SafeGetTurf(0, 3),
		SafeGetTurf(3, 0),
		SafeGetTurf(0, -3),
		SafeGetTurf(-3, 0)
	)

	// 3 sniper anchors for long-range support
	anchor_positions = list(
		SafeGetTurf(2, 2),
		SafeGetTurf(2, -2),
		SafeGetTurf(-2, 0)
	)

	// 2 greed demolishers for breaching
	special_positions = list(
		SafeGetTurf(1, 0),
		SafeGetTurf(-1, 0)
	)

	turret_positions -= null
	anchor_positions -= null
	special_positions -= null

/obj/structure/seed_of_greed/assault/level3/GenerateLayoutPattern()
	// Minimal barricades for maximum mobility
	for(var/dir in GLOB.cardinals)
		var/turf/T = get_step(src, dir)
		if(T)
			barricade_positions_inner += T
	barricade_positions_outer = list()
	// Call SetSpecialPositions to populate turret and anchor positions
	SetSpecialPositions()

