/// Wall rubble left behind when a combo's knockback breaks through a wall.
/// Self-repairs after 2 minutes if unobserved, retries in 1 minute if someone is watching.
/obj/structure/wall_rubble
	name = "rubble"
	desc = "The remains of a wall that was smashed through. It looks like it might rebuild itself."
	icon = 'icons/obj/flora/rocks.dmi'
	icon_state = "lavarocks1"
	density = FALSE
	anchored = TRUE
	/// The original wall turf type to restore on repair
	var/original_wall_type

/obj/structure/wall_rubble/Initialize(mapload, _original_wall_type)
	. = ..()
	original_wall_type = _original_wall_type
	addtimer(CALLBACK(src, PROC_REF(TryRepair)), 2 MINUTES)

/// Attempts to repair the wall. If someone can see the rubble, delays 1 minute.
/obj/structure/wall_rubble/proc/TryRepair()
	if(QDELETED(src))
		return
	if(!original_wall_type)
		qdel(src)
		return

	for(var/mob/living/L in viewers(7, src))
		if(L.client)
			addtimer(CALLBACK(src, PROC_REF(TryRepair)), 1 MINUTES)
			return

	var/turf/T = get_turf(src)
	if(T)
		T.ChangeTurf(original_wall_type)
	qdel(src)

/// Launches a target tile-by-tile in a direction, breaking through walls.
/// Only stops at indestructible rock with another indestructible rock behind it, space, or after max_tiles.
/// Breaks ALL other walls (including indestructible ones that don't have rock behind them).
/proc/wall_breaking_knockback(mob/living/target, mob/living/attacker, direction, max_tiles)
	if(!target || !direction)
		return

	var/turf/current = get_turf(target)

	for(var/i in 1 to max_tiles)
		var/turf/next = get_step(current, direction)
		if(!next)
			break

		if(istype(next, /turf/open/space))
			break

		if(next.density)
			if(istype(next, /turf/closed))
				// Check the turf AFTER this wall — if it's indestructible rock, don't break
				var/turf/behind = get_step(next, direction)
				if(behind && istype(behind, /turf/closed/indestructible/rock))
					target.deal_damage(20, RED_DAMAGE)
					shake_camera(target, 2, 3)
					break

				// Break through the wall
				var/wall_type = next.type
				next.ChangeTurf(/turf/open/floor/plating/ashplanet/rocky)
				new /obj/structure/wall_rubble(next, wall_type)
				playsound(next, 'sound/effects/meteorimpact.ogg', 50, TRUE)
				new /obj/effect/temp_visual/middle_slam(next)
			else
				// Dense non-turf obstacle
				target.deal_damage(15, RED_DAMAGE)
				break

		// Check for dense objects on the tile
		var/blocked = FALSE
		for(var/obj/O in next)
			if(O.density && O.anchored)
				blocked = TRUE
				break
		if(blocked)
			target.deal_damage(15, RED_DAMAGE)
			break

		target.forceMove(next)
		current = next

		new /obj/effect/temp_visual/small_smoke/halfsecond(next)
		sleep(0.1 SECONDS)
