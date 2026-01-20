// Speedwagon Hazard Effect
// A fast-moving effect that damages and knocks back anyone in its path
GLOBAL_LIST_EMPTY(speedwagon_triggers)
GLOBAL_LIST_EMPTY(speedwagon_spawners)

/obj/effect/speedwagon_hazard
	name = "speeding vehicle"
	desc = "GET OUT OF THE WAY!"
	icon = 'icons/obj/car.dmi'
	icon_state = "speedwagon"
	layer = LYING_MOB_LAYER
	pixel_y = -48
	pixel_x = -48
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE

	var/move_speed = 0.5 // Deciseconds between moves
	var/damage_amount = 30
	var/knockback_distance = 4
	var/max_travel_distance = 30 // How far it travels before despawning
	var/list/already_hit = list() // Track mobs we've already hit

/obj/effect/speedwagon_hazard/Initialize(mapload, set_dir = SOUTH)
	. = ..()
	if(set_dir)
		setDir(set_dir)
	// Add the cover overlay
	var/mutable_appearance/overlay = mutable_appearance(icon, "speedwagon_cover", ABOVE_MOB_LAYER)
	add_overlay(overlay)
	// Play sound
	playsound(src, 'sound/effects/bang.ogg', 50, TRUE)
	// Start moving after a brief delay
	addtimer(CALLBACK(src, PROC_REF(MoveStep)), move_speed)

/obj/effect/speedwagon_hazard/proc/MoveStep()
	if(QDELETED(src))
		return

	// Move in our direction
	var/turf/next_turf = get_step(src, dir)
	if(!next_turf || istype(next_turf, /turf/closed))
		qdel(src)
		return

	// Check distance traveled
	max_travel_distance--
	if(max_travel_distance <= 0)
		qdel(src)
		return

	// Move to the next turf
	forceMove(next_turf)

	// Damage and knockback everything in 3x3 range
	DamageNearby()

	// Schedule next move
	addtimer(CALLBACK(src, PROC_REF(MoveStep)), move_speed)

/obj/effect/speedwagon_hazard/proc/DamageNearby()
	for(var/mob/living/L in range(1, src)) // range 1 = 3x3 area
		if(L.stat == DEAD)
			continue
		if(L in already_hit)
			continue

		// Mark as hit
		already_hit += L

		// Deal damage
		L.deal_damage(damage_amount, BRUTE, attack_type = ATTACK_TYPE_MELEE)
		L.Paralyze(1 SECONDS)

		// Knockback in the direction we're moving
		var/atom/throw_target = get_edge_target_turf(L, dir)
		L.throw_at(throw_target, knockback_distance, 3)

		// Effects
		visible_message(span_danger("[src] crashes into [L]!"))
		playsound(src, 'sound/effects/bang.ogg', 50, TRUE)

// ==================== SPEEDWAGON LANDMARKS ====================

// Trigger - when crossed, has a chance to spawn a speedwagon at a spawner
/obj/effect/landmark/speedwagon_trigger
	name = "speedwagon trigger"
	icon_state = "x2"
	var/trigger_chance = 25 // 25% chance to trigger

/obj/effect/landmark/speedwagon_trigger/Initialize(mapload)
	. = ..()
	GLOB.speedwagon_triggers += src

/obj/effect/landmark/speedwagon_trigger/Destroy()
	GLOB.speedwagon_triggers -= src
	return ..()

/obj/effect/landmark/speedwagon_trigger/Crossed(atom/movable/AM)
	. = ..()
	if(!isliving(AM))
		return

	// 25% chance to trigger
	if(!prob(trigger_chance))
		return

	// Find a spawner landmark to spawn the speedwagon at
	if(!length(GLOB.speedwagon_spawners))
		return

	var/obj/effect/landmark/speedwagon_spawner/spawn_point = pick(GLOB.speedwagon_spawners)
	if(!spawn_point)
		return

	// Spawn the speedwagon effect heading SOUTH (dir 2)
	new /obj/effect/speedwagon_hazard(get_turf(spawn_point), SOUTH)

// Spawner - where the speedwagon actually appears
/obj/effect/landmark/speedwagon_spawner
	name = "speedwagon spawner"
	icon_state = "x2"

/obj/effect/landmark/speedwagon_spawner/Initialize(mapload)
	. = ..()
	GLOB.speedwagon_spawners += src

/obj/effect/landmark/speedwagon_spawner/Destroy()
	GLOB.speedwagon_spawners -= src
	return ..()
