# Seed of Greed - Outpost Building System

## Overview
The "Seed of Greed" is a deployable structure that automatically constructs a defensive outpost over 10 seconds, then self-destructs. It creates barricades, turrets, and support buildings in predefined patterns.

## Base Class Structure

```dm
/obj/structure/seed_of_greed
	name = "Seed of Greed"
	desc = "A pulsating mass of flesh and metal that rapidly constructs an outpost."
	icon = 'ModularLobotomy/_Lobotomyicons/resurgence_48x48.dmi'
	icon_state = "seed_greed"
	density = TRUE
	anchored = TRUE
	max_integrity = 500
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
	
	// Building types to spawn
	var/turret_type = /mob/living/simple_animal/hostile/clan/ranged/turret/level1
	var/anchor_type = /mob/living/simple_animal/hostile/clan/chain_anchor/gunner
	var/special_type = null // Variant-specific
```

## Core Procedures

### Initialize
```dm
/obj/structure/seed_of_greed/Initialize()
	. = ..()
	GenerateLayoutPattern()
	StartConstruction()
	visible_message(span_danger("[src] begins pulsating as it starts constructing an outpost!"))
	playsound(src, 'sound/magic/clockwork/ark_activation.ogg', 50, TRUE)
```

### Layout Generation
```dm
/obj/structure/seed_of_greed/proc/GenerateLayoutPattern()
	// Generate inner barricade ring (radius 1)
	for(var/dir in GLOB.alldirs)
		var/turf/T = get_step(src, dir)
		barricade_positions_inner += T
	
	// Generate outer barricade ring (radius 2)
	barricade_positions_outer = GenerateSquarePattern(2)
	
	// Set turret and anchor positions (override in variants)
	SetSpecialPositions()

/obj/structure/seed_of_greed/proc/GenerateSquarePattern(radius)
	var/list/positions = list()
	var/turf/center = get_turf(src)
	for(var/x = -radius to radius)
		for(var/y = -radius to radius)
			if(abs(x) == radius || abs(y) == radius)
				var/turf/T = locate(center.x + x, center.y + y, center.z)
				if(T)
					positions += T
	return positions
```

### Construction Stages
```dm
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
```

### Placement Logic
```dm
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
	new /obj/effect/temp_visual/dir_setting/cult/phase(T)
	playsound(T, 'sound/effects/phasein.ogg', 40, TRUE)
	
	return M
```

### Building Stage Implementation
```dm
/obj/structure/seed_of_greed/proc/BuildStage1()
	visible_message(span_notice("[src] deploys inner barricades!"))
	for(var/turf/T in barricade_positions_inner)
		TryPlaceStructure(T, /obj/structure/xcorp_barricade)

/obj/structure/seed_of_greed/proc/BuildStage2()
	visible_message(span_notice("[src] extends outer barricades!"))
	for(var/turf/T in barricade_positions_outer)
		TryPlaceStructure(T, /obj/structure/xcorp_barricade)

/obj/structure/seed_of_greed/proc/BuildStage3()
	visible_message(span_warning("[src] deploys defensive turrets!"))
	for(var/turf/T in turret_positions)
		TryPlaceMob(T, turret_type)

/obj/structure/seed_of_greed/proc/BuildStage4()
	visible_message(span_warning("[src] establishes chain anchors!"))
	for(var/turf/T in anchor_positions)
		TryPlaceMob(T, anchor_type)

/obj/structure/seed_of_greed/proc/BuildStage5()
	if(special_type)
		visible_message(span_danger("[src] deploys special equipment!"))
		for(var/turf/T in special_positions)
			TryPlaceMob(T, special_type)

/obj/structure/seed_of_greed/proc/CompleteBuild()
	visible_message(span_boldwarning("[src] has completed the outpost construction and crumbles!"))
	playsound(src, 'sound/effects/break_stone.ogg', 50, TRUE)
	qdel(src)
```

## Outpost Variants

### 1. Basic Outpost
```dm
/obj/structure/seed_of_greed/basic
	name = "Seed of Greed (Basic)"
	desc = "Constructs a standard defensive outpost."
	turret_type = /mob/living/simple_animal/hostile/clan/ranged/turret/level1
	anchor_type = /mob/living/simple_animal/hostile/clan/chain_anchor/gunner

/obj/structure/seed_of_greed/basic/SetSpecialPositions()
	// 4 turrets at corners
	var/turf/center = get_turf(src)
	turret_positions = list(
		locate(center.x + 2, center.y + 2, center.z),
		locate(center.x + 2, center.y - 2, center.z),
		locate(center.x - 2, center.y + 2, center.z),
		locate(center.x - 2, center.y - 2, center.z)
	)
	
	// 2 anchors on sides
	anchor_positions = list(
		locate(center.x + 3, center.y, center.z),
		locate(center.x - 3, center.y, center.z)
	)
```

### 2. Defensive Outpost
```dm
/obj/structure/seed_of_greed/defensive
	name = "Seed of Greed (Defensive)"
	desc = "Constructs a heavily fortified position with shields."
	turret_type = /mob/living/simple_animal/hostile/clan/ranged/turret/level2
	anchor_type = /mob/living/simple_animal/hostile/clan/chain_anchor/rapid
	special_type = /mob/living/simple_animal/hostile/clan/shield_generator/level2
	
	var/list/barricade_positions_extra = list() // Third ring

/obj/structure/seed_of_greed/defensive/GenerateLayoutPattern()
	..()
	barricade_positions_extra = GenerateSquarePattern(3)

/obj/structure/seed_of_greed/defensive/SetSpecialPositions()
	var/turf/center = get_turf(src)
	// 6 turrets in hexagon pattern
	turret_positions = list(
		locate(center.x + 2, center.y + 1, center.z),
		locate(center.x + 2, center.y - 1, center.z),
		locate(center.x - 2, center.y + 1, center.z),
		locate(center.x - 2, center.y - 1, center.z),
		locate(center.x, center.y + 2, center.z),
		locate(center.x, center.y - 2, center.z)
	)
	
	// 2 rapid anchors
	anchor_positions = list(
		locate(center.x + 1, center.y + 3, center.z),
		locate(center.x - 1, center.y - 3, center.z)
	)
	
	// Shield generator in center
	special_positions = list(center)

/obj/structure/seed_of_greed/defensive/BuildStage2()
	..()
	// Also build third ring
	visible_message(span_notice("[src] reinforces with additional barricades!"))
	for(var/turf/T in barricade_positions_extra)
		TryPlaceStructure(T, /obj/structure/xcorp_barricade)
```

### 3. Sniper Nest
```dm
/obj/structure/seed_of_greed/sniper
	name = "Seed of Greed (Sniper)"
	desc = "Constructs a long-range fire support position."
	turret_type = /mob/living/simple_animal/hostile/clan/ranged/turret/level3
	anchor_type = /mob/living/simple_animal/hostile/clan/chain_anchor/sniper

/obj/structure/seed_of_greed/sniper/SetSpecialPositions()
	var/turf/center = get_turf(src)
	// 2 high-level turrets
	turret_positions = list(
		locate(center.x, center.y + 3, center.z),
		locate(center.x, center.y - 3, center.z)
	)
	
	// 3 sniper anchors in triangle
	anchor_positions = list(
		locate(center.x + 4, center.y, center.z),
		locate(center.x - 2, center.y + 3, center.z),
		locate(center.x - 2, center.y - 3, center.z)
	)

/obj/structure/seed_of_greed/sniper/GenerateLayoutPattern()
	// Only one ring of barricades for snipers
	for(var/dir in GLOB.alldirs)
		var/turf/T = get_step(src, dir)
		barricade_positions_inner += T
	// No outer ring
	barricade_positions_outer = list()
```

### 4. Artillery Position
```dm
/obj/structure/seed_of_greed/artillery
	name = "Seed of Greed (Artillery)"
	desc = "Constructs a heavy bombardment position."
	turret_type = /mob/living/simple_animal/hostile/clan/ranged/turret/artillery/level2
	anchor_type = /mob/living/simple_animal/hostile/clan/chain_anchor/gunner
	special_type = /mob/living/simple_animal/hostile/clan/shield_generator/level1

/obj/structure/seed_of_greed/artillery/SetSpecialPositions()
	var/turf/center = get_turf(src)
	// 2 artillery turrets
	turret_positions = list(
		locate(center.x + 1, center.y + 2, center.z),
		locate(center.x - 1, center.y - 2, center.z)
	)
	
	// 2 gunner anchors for protection
	anchor_positions = list(
		locate(center.x + 3, center.y - 1, center.z),
		locate(center.x - 3, center.y + 1, center.z)
	)
	
	// Shield generator for protection
	special_positions = list(
		locate(center.x, center.y + 1, center.z)
	)
```

### 5. Support Base
```dm
/obj/structure/seed_of_greed/support
	name = "Seed of Greed (Support)"
	desc = "Constructs a utility-focused support base."
	turret_type = null // No turrets
	anchor_type = /mob/living/simple_animal/hostile/clan/chain_anchor/warper
	special_type = /mob/living/simple_animal/hostile/clan/shield_generator/level2

/obj/structure/seed_of_greed/support/SetSpecialPositions()
	var/turf/center = get_turf(src)
	// No turrets
	turret_positions = list()
	
	// 4 warper anchors
	anchor_positions = list(
		locate(center.x + 2, center.y + 2, center.z),
		locate(center.x + 2, center.y - 2, center.z),
		locate(center.x - 2, center.y + 2, center.z),
		locate(center.x - 2, center.y - 2, center.z)
	)
	
	// 2 shield generators
	special_positions = list(
		locate(center.x, center.y + 2, center.z),
		locate(center.x, center.y - 2, center.z)
	)

/obj/structure/seed_of_greed/support/BuildStage3()
	// Skip turret stage
	return
```

## Visual Effects

### Construction Markers
```dm
/obj/effect/temp_visual/construction_marker
	name = "construction site"
	desc = "Something will be built here soon."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield_pulse"
	duration = 20
	layer = BELOW_MOB_LAYER
	alpha = 150

/obj/structure/seed_of_greed/proc/ShowConstructionPlan()
	// Show where things will be built
	for(var/turf/T in barricade_positions_inner + barricade_positions_outer)
		new /obj/effect/temp_visual/construction_marker(T)
	for(var/turf/T in turret_positions)
		var/obj/effect/E = new /obj/effect/temp_visual/construction_marker(T)
		E.color = "#FF0000"
	for(var/turf/T in anchor_positions)
		var/obj/effect/E = new /obj/effect/temp_visual/construction_marker(T)
		E.color = "#00FF00"
```

### Pulsating Animation
```dm
/obj/structure/seed_of_greed/Initialize()
	. = ..()
	// Pulsating effect during construction
	animate(src, alpha = 150, time = 10, loop = -1)
	animate(alpha = 255, time = 10)
```

## Cleanup and Error Handling

```dm
/obj/structure/seed_of_greed/Destroy()
	// Cancel all timers if destroyed early
	for(var/timer in build_timers)
		deltimer(timer)
	build_timers.Cut()
	return ..()

/obj/structure/seed_of_greed/proc/SafeGetTurf(x_offset, y_offset)
	var/turf/center = get_turf(src)
	if(!center)
		return null
	var/turf/T = locate(center.x + x_offset, center.y + y_offset, center.z)
	if(!T || T.z != center.z) // Don't build across z-levels
		return null
	return T
```

## Implementation Notes

1. **All spawned structures/mobs should have faction = list("greed_clan", "hostile")**
2. **Use visual/audio feedback for each construction stage**
3. **Structures should check density before placing to avoid conflicts**
4. **Consider adding a "construction in progress" overlay to the seed**
5. **Could add variants that build different patterns (cross, diamond, line)**
6. **Timer cleanup is essential to prevent runtime errors if destroyed early**
7. **Consider making construction interruptible by dealing enough damage**

## Usage Example

```dm
// Spawn a defensive outpost
new /obj/structure/seed_of_greed/defensive(get_turf(target))

// The seed will:
// 1. Show construction markers
// 2. Build 3 rings of barricades over 4 seconds
// 3. Deploy 6 level 2 turrets at 4 seconds
// 4. Deploy 2 rapid anchors at 6 seconds
// 5. Deploy a shield generator at 8 seconds
// 6. Self-destruct at 10 seconds
```
