/**
 * This proc gets called when a ghost drags themselfes onto an abnormality and passess several checks to make sure they can do that
 * This proc allows a ghost to take over an abnormality, mainly used in the playables events
 * Its called AFTER the admin proc to force ghosts into mobs, so admins will need to dead-min to access this like a player would
 *
 * Called by /mob/dead/observer/MouseDrop(atom/over)
 */

///TRUE if this body is only temporarily vacant because its player stepped out of it.
/proc/IsPossessionLocked(mob/abnormality)
	var/mob/living/simple_animal/hostile/limbus_abno/LA = abnormality
	return istype(LA) && LA.PossessionLocked()

///The one gate on taking a body, shared by the Possess verb and the ghost-drag path. The drag
///path used to ask for a ckey and nothing else, which is not the same thing as a free body.
/proc/IsGhostPossessable(mob/living/target)
	if(!isliving(target) || QDELETED(target))
		return FALSE
	if(!get_turf(target))
		return FALSE
	if(target.do_not_possess)
		return FALSE
	if(target.ckey || target.mind || (target in GLOB.player_list)) //Home, or on the way back.
		return FALSE
	if(IsPossessionLocked(target))
		return FALSE
	if(ismegafauna(target))
		return FALSE
	if(istype(target, /mob/living/simple_animal/hostile/der_freis_portal)) //Portals are not for stealing.
		return FALSE
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(istype(H, /mob/living/carbon/human/dummy) || H.sanity_lost) //Haha no.
			return FALSE
	return TRUE

///TRUE when a body is safe to push a player back into. Evicting a client that is already in there
///drops it out from under them rather than swapping them out.
/proc/CanReturnTo(mob/body, mob/returning)
	if(QDELETED(body))
		return FALSE
	return !body.ckey || (body.ckey == returning?.ckey)

///Whether a ghost dragged onto this is attempting possession at all, rather than misclicking.
///Narrower than IsGhostPossessable(): the drag path only ever meant to reach abnormalities.
/mob/living/proc/CanGhostDragPossess()
	return isabnormalitymob(src)

/datum/proc/try_take_abnormality(mob/dead/observer/possessing_player, mob/abnormality)
	if(!SSlobotomy_corp.enable_possession) // uhhhh, how did you even access this proc?
		to_chat(usr, span_userdanger("Abnormality possession is not enabled!"))
		return

	if(!possessing_player.ckey) // safety check
		to_chat(possessing_player, span_userdanger("You dont have a valid ckey, this should not show up!"))
		return

	//An empty body is not always a free one. LCL specimens can step out of themselves - into a
	//worker bee, a scouting marker, a manifestation - and the body they left behind keeps no ckey.
	if(!IsGhostPossessable(abnormality))
		to_chat(possessing_player, span_userdanger("Something still occupies this one, even if it looks empty. You can't possess it!"))
		return

	var/title = "Do you wish to possess this abnormality?"
	var/message = "Are you sure you want to possess [abnormality.name]?"

	var/ask = tgui_alert(usr, message, title, list("Yes", "No"))
	if(ask != "Yes")
		return

	if(!possessing_player || !abnormality) //make sure the mobs didnt get deleted while we waited for a response, else this could end badly
		return

	if(!IsGhostPossessable(abnormality)) // and then make sure someone wasnt faster than you
		to_chat(possessing_player, span_userdanger("This abnormality already has a ghost in control of it, seems like you were too slow!"))
		return

	message_admins(span_adminnotice("[possessing_player.key] has possessed [abnormality.name]."))
	log_admin("[possessing_player.key] has possessed [abnormality.name].")

	if(SSmaptype.chosen_trait == FACILITY_TRAIT_PLAYABLES) //Most convenient way I could think of off the top of my head.
		if(LAZYLEN(SSlobotomy_corp.all_abnormality_datums))
			for(var/datum/abnormality/A in SSlobotomy_corp.all_abnormality_datums)
				if(A.abno_radio)
					continue
				if(isnull(A.current))
					A.abno_radio = TRUE
					continue
				A.current.AbnoRadio()

	if(!IsGhostPossessable(abnormality))
		to_chat(possessing_player, span_userdanger("Something took hold of it before you could. You can't possess it!"))
		return

	abnormality.key = possessing_player.key
	abnormality.client?.init_verbs()
	qdel(possessing_player)
