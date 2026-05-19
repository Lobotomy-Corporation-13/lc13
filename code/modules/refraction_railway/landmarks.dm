/*
 * Refraction railway landmarks. Authored on each line's dmm; the run datum
 * filters by landmark z (claimed lane) and by `id`.
 * Gotcha: avoid `spawn` as a path component so the dmm loader doesn't trip
 * on the DM `spawn` keyword.
 */

/obj/effect/landmark/refraction
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x2"
	/// Subtype-dependent identifier (room id for start_point, etc).
	var/id = ""

/// Where players are forceMoved when entering a combat room.
/obj/effect/landmark/refraction/start_point
	name = "refraction start point"
	desc = "A refraction-railway player arrival point. Notify a coder if you see this."
	icon_state = "x2"

/// One per checkpoint arrival turf; players distributed round-robin.
/obj/effect/landmark/refraction/checkpoint_spawn
	name = "refraction checkpoint spawn"
	desc = "A refraction-railway checkpoint arrival point. Notify a coder if you see this."
	icon_state = "x3"
