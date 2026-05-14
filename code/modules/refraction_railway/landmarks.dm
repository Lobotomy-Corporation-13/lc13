/*
 * Refraction railway landmarks.
 *
 * Authored on each line's dmm. The run datum filters by the landmark's z
 * (matching the run's claimed lane) and by `id` for start_point.
 *
 * Sector and run completion happen automatically when the last node's mobs
 * are all dead — see /datum/refraction_run/AdvanceRoom. There are no
 * section-end or finish landmarks anymore; players don't need to walk to a
 * specific tile.
 *
 * The wave-spawning landmark (/obj/effect/landmark/refraction/spawner) and
 * the per-room controller live in code/modules/refraction_railway/wave_system.dm.
 *
 * Note: parent types deliberately avoid `spawn` as a path component so the
 * dmm runtime loader doesn't trip on the DM `spawn` keyword in path tokens.
 */

/obj/effect/landmark/refraction
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x2"
	/// Identifier baked into the typed subtype (or settable via dmm
	/// var-override). Meaning depends on the subtype: for `start_point`
	/// it's the room id (matches the line's node id); for `spawner` it's
	/// the landmark id the wave controller binds against. Unified into
	/// one var so authoring is consistent.
	var/id = ""

/// Where players are forceMoved when entering a combat room. The `id` var
/// (inherited) holds the room/node identifier.
/obj/effect/landmark/refraction/start_point
	name = "refraction start point"
	desc = "A refraction-railway player arrival point. Notify a coder if you see this."
	icon_state = "x2"

/// One per arrival turf in the line's checkpoint area. Players are
/// distributed round-robin across these landmarks.
/obj/effect/landmark/refraction/checkpoint_spawn
	name = "refraction checkpoint spawn"
	desc = "A refraction-railway checkpoint arrival point. Notify a coder if you see this."
	icon_state = "x3"
