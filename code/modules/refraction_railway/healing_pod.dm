/*
 * Restoration Pod — a railway-side self-service healing chassis. Built
 * around the body_fabricator's silhouette (`'icons/mob/hivebot.dmi'`
 * state `"fab_robot"`) so it reads as a sibling machine, but the
 * mechanics are pure player self-care: step in while alive → full
 * heal + every status effect stripped → step out when ready.
 *
 * Intended placement is the line's checkpoint area, alongside the
 * loadout consoles and the advance console. It is generic, though —
 * any human can use any pod, no run-membership check.
 */

/obj/structure/refraction_healing_pod
	name = "restoration pod"
	desc = "A humming chassis built around a stasis field. Step inside \
		to suspend your wounds for a moment."
	icon = 'icons/mob/hivebot.dmi'
	icon_state = "fab_robot"
	density = TRUE
	anchored = TRUE
	layer = BELOW_OBJ_LAYER
	resistance_flags = INDESTRUCTIBLE
	/// Single-seat pod. While occupied, attack_hand from outside is
	/// rejected with a "busy" message. NULL when free.
	var/mob/living/carbon/human/occupant

/obj/structure/refraction_healing_pod/Destroy()
	if(occupant && !QDELETED(occupant))
		EjectOccupant()
	return ..()

/obj/structure/refraction_healing_pod/attack_hand(mob/user)
	if(!ishuman(user))
		return ..()
	if(user == occupant)
		// Clicking the pod while already inside ejects.
		EjectOccupant()
		return
	if(occupant)
		to_chat(user, span_warning("[src] is already in use."))
		return
	if(user.stat == DEAD)
		to_chat(user, span_warning("[src]'s field only holds the living."))
		return
	// Standard accessibility: must be on a turf next to the pod (the
	// usual attack_hand reach check the framework applies for us).
	EnterPod(user)

/obj/structure/refraction_healing_pod/proc/EnterPod(mob/living/carbon/human/H)
	if(!ishuman(H) || occupant)
		return
	occupant = H
	H.forceMove(src)
	playsound(get_turf(src), 'sound/machines/ping.ogg', 50, FALSE)
	visible_message(span_notice("[H] steps into [src]; the chassis seals around them."))
	RestoreOccupant(H)

/// Full heal + status purge. Reuses the same admin_revive flow the
/// railway's checkpoint heal pass uses, so a dismembered or near-dead
/// body still comes back cleanly. Then iterates `status_effects` and
/// qdels every entry — buffs and debuffs both, no whitelist.
/obj/structure/refraction_healing_pod/proc/RestoreOccupant(mob/living/carbon/human/H)
	if(!ishuman(H))
		return
	H.revive(full_heal = TRUE, admin_revive = TRUE)
	if(H.sanityloss > 0)
		H.adjustSanityLoss(-H.maxSanity, TRUE)
	H.sanity_lost = FALSE
	if(islist(H.status_effects))
		for(var/datum/status_effect/S in H.status_effects)
			qdel(S)
	to_chat(H, span_nicegreen("The field closes your wounds and peels every lingering effect away."))

/obj/structure/refraction_healing_pod/container_resist_act(mob/living/user)
	if(user != occupant)
		return
	EjectOccupant()

/// Step out: forceMove the occupant back onto the pod's tile, clear
/// the slot, and announce. Safe to call when the slot is already empty.
/obj/structure/refraction_healing_pod/proc/EjectOccupant()
	if(!occupant)
		return
	var/mob/living/carbon/human/H = occupant
	occupant = null
	var/turf/T = get_turf(src)
	if(T && !QDELETED(H))
		H.forceMove(T)
		visible_message(span_notice("[H] steps out of [src]."))
