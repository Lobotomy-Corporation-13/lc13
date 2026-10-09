/obj/item/nursefather_music_debug
	name = "nursefather music debug tool"
	desc = "Grants the nursefather music component. Use in-hand to activate."
	icon = 'icons/obj/radio.dmi'
	icon_state = "radio"
	w_class = WEIGHT_CLASS_TINY

/obj/item/nursefather_music_debug/attack_self(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("Only humans can use this."))
		return

	var/finger = tgui_input_list(user, "Select finger type:", "Nursefather Music Debug", list("Index", "Middle", "Ring", "Thumb", "Pinky"))
	if(!finger || QDELETED(src) || QDELETED(user))
		return
	if(!user.is_holding(src))
		return

	var/finger_key
	switch(finger)
		if("Index")
			finger_key = NURSEFATHER_FINGER_INDEX
		if("Middle")
			finger_key = NURSEFATHER_FINGER_MIDDLE
		if("Ring")
			finger_key = NURSEFATHER_FINGER_RING
		if("Thumb")
			finger_key = NURSEFATHER_FINGER_THUMB
		if("Pinky")
			finger_key = NURSEFATHER_FINGER_PINKY

	var/datum/component/nursefather_music/existing = user.GetComponent(/datum/component/nursefather_music)
	if(existing)
		existing.stop_music()
		qdel(existing)
	user.AddComponent(/datum/component/nursefather_music, finger_key)
	to_chat(user, span_notice("Nursefather music component ([finger]) granted."))
