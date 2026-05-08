/*
 * Refraction railway landmarks.
 *
 * Spawned from the line dmms (and the shared checkpoint dmm). Each landmark's
 * room_id / section_id lets the run controller filter to the right set when
 * advancing rooms / activating wave controllers.
 *
 * The wave-extending landmarks (`/obj/effect/landmark/refraction/wave_spawn`
 * and `/obj/effect/landmark/refraction/boss_spawn`) are not defined here yet:
 * `/obj/effect/landmark/wave_spawn` lives in `wave_system.dm` at the repo root
 * and is not currently included in the DME. Once wave_system is wired into the
 * project, add the refraction subtypes here that override `Initialize()` to
 * derive a per-run `controller_id` of the form `"refraction_<run_uid>_<authored_id>"`.
 */

/obj/effect/landmark/refraction
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x2"

/// Where players are forceMoved when entering a combat room.
/obj/effect/landmark/refraction/player_spawn
	name = "refraction player spawn"
	desc = "A refraction-railway player arrival point. Notify a coder if you see this."
	icon_state = "x2"
	/// Combat-room id this spawn belongs to. Matches wave_spawn / section_end ids.
	var/room_id = ""
	/// Sector id (1-based) this spawn belongs to.
	var/section_id = 0

/// Crossed by a member to advance to the next room or to the checkpoint.
/// Pauses the timer when ALL live members have arrived in the checkpoint.
/obj/effect/landmark/refraction/section_end
	name = "refraction section end"
	desc = "Crossing this ends a refraction-railway section. Notify a coder if you see this."
	icon_state = "x4"
	/// Sector id (1-based) being completed by crossing this landmark.
	var/section_id = 0

/obj/effect/landmark/refraction/section_end/Crossed(atom/movable/AM)
	. = ..()
	if(!ishuman(AM))
		return
	if(isobserver(AM))
		return
	var/mob/M = AM
	var/datum/refraction_run/R = SSrefraction_railway.GetRunForMob(M)
	if(!R)
		return
	R.OnSectionCleared(src.section_id)

/// One per arrival turf in the shared checkpoint dmm.
/// Players are distributed round-robin across these landmarks.
/obj/effect/landmark/refraction/checkpoint_spawn
	name = "refraction checkpoint spawn"
	desc = "A refraction-railway checkpoint arrival point. Notify a coder if you see this."
	icon_state = "x3"

/// Final landmark of the line. Crossing it ends the run and records the time.
/obj/effect/landmark/refraction/finish
	name = "refraction finish"
	desc = "Crossing this finishes a refraction-railway run. Notify a coder if you see this."
	icon_state = "city_of_cogs"

/obj/effect/landmark/refraction/finish/Crossed(atom/movable/AM)
	. = ..()
	if(!ishuman(AM))
		return
	if(isobserver(AM))
		return
	var/mob/M = AM
	var/datum/refraction_run/R = SSrefraction_railway.GetRunForMob(M)
	if(!R)
		return
	R.OnRunComplete()
