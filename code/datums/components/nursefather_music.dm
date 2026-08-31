GLOBAL_LIST_EMPTY(nursefather_music_active)

/datum/component/nursefather_music
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Which finger this nursefather belongs to
	var/finger_type = NURSEFATHER_FINGER_INDEX
	/// Current music mode
	var/music_mode = NURSEFATHER_MODE_OFF
	/// The action button granted to the owner
	var/datum/action/innate/nursefather_music/music_action
	/// List of mobs currently hearing our music
	var/list/listeners = list()

/datum/component/nursefather_music/Initialize(finger = NURSEFATHER_FINGER_INDEX)
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	finger_type = finger
	music_action = new(src)
	music_action.Grant(parent)

/datum/component/nursefather_music/Destroy()
	stop_music()
	if(music_action)
		QDEL_NULL(music_action)
	return ..()

/datum/component/nursefather_music/proc/get_passive_track()
	switch(finger_type)
		if(NURSEFATHER_FINGER_INDEX)
			return 'sound/ambience/nursefathers/index_nursefather_passive.ogg'
		if(NURSEFATHER_FINGER_MIDDLE)
			return 'sound/ambience/nursefathers/middle_nursefather_passive.ogg'
		if(NURSEFATHER_FINGER_RING)
			return 'sound/ambience/nursefathers/ring_nursefather_passive.ogg'
		if(NURSEFATHER_FINGER_THUMB)
			return 'sound/ambience/nursefathers/thumb_nursefather_passive.ogg'
		if(NURSEFATHER_FINGER_PINKY)
			return 'sound/ambience/nursefathers/pinky_nursefather_passive.ogg'

/datum/component/nursefather_music/proc/get_combat_track()
	switch(finger_type)
		if(NURSEFATHER_FINGER_INDEX)
			return 'sound/ambience/nursefathers/index_nursefather_combat.ogg'
		if(NURSEFATHER_FINGER_MIDDLE)
			return 'sound/ambience/nursefathers/middle_nursefather_combat.ogg'
		if(NURSEFATHER_FINGER_RING)
			return 'sound/ambience/nursefathers/ring_nursefather_combat.ogg'
		if(NURSEFATHER_FINGER_THUMB)
			return 'sound/ambience/nursefathers/thumb_nursefather_combat.ogg'
		if(NURSEFATHER_FINGER_PINKY)
			return 'sound/ambience/nursefathers/pinky_nursefather_combat.ogg'

/datum/component/nursefather_music/proc/get_current_track()
	switch(music_mode)
		if(NURSEFATHER_MODE_PASSIVE)
			return get_passive_track()
		if(NURSEFATHER_MODE_COMBAT)
			return get_combat_track()
	return null


/datum/component/nursefather_music/proc/start_music(new_mode)
	if(music_mode != NURSEFATHER_MODE_OFF)
		stop_music()
	music_mode = new_mode
	GLOB.nursefather_music_active += src
	START_PROCESSING(SSobj, src)

/datum/component/nursefather_music/proc/stop_music()
	if(music_mode == NURSEFATHER_MODE_OFF)
		return
	music_mode = NURSEFATHER_MODE_OFF
	GLOB.nursefather_music_active -= src
	STOP_PROCESSING(SSobj, src)
	for(var/mob/M in listeners)
		if(M?.client)
			M.stop_sound_channel(CHANNEL_NURSEFATHER)
	listeners.Cut()

/datum/component/nursefather_music/proc/is_oldest_source_for(mob/listener)
	for(var/datum/component/nursefather_music/other in GLOB.nursefather_music_active)
		if(other == src)
			return TRUE
		if(get_dist(other.parent, listener) <= NURSEFATHER_MUSIC_RANGE)
			return FALSE
	return TRUE

/datum/component/nursefather_music/process()
	if(music_mode == NURSEFATHER_MODE_OFF)
		STOP_PROCESSING(SSobj, src)
		return

	var/mob/living/owner = parent
	if(QDELETED(owner) || owner.stat == DEAD)
		stop_music()
		return

	var/track_path = get_current_track()
	if(!track_path)
		stop_music()
		return

	var/sound/song = sound(track_path, repeat = TRUE)

	for(var/mob/M in range(NURSEFATHER_MUSIC_RANGE, owner))
		if(!M.client)
			continue
		if(!(M.client.prefs.toggles & SOUND_INSTRUMENTS))
			continue
		if(!is_oldest_source_for(M))
			continue
		if(!(M in listeners))
			listeners[M] = TRUE
			var/vol = NURSEFATHER_MUSIC_VOLUME
			if(M.client?.prefs)
				vol = M.client.prefs.player_ambience_volume
			M.playsound_local(get_turf(M), null, vol, channel = CHANNEL_NURSEFATHER, S = song, use_reverb = FALSE)

	for(var/mob/M in listeners)
		if(QDELETED(M))
			listeners -= M
			continue
		if(get_dist(owner, M) > NURSEFATHER_MUSIC_RANGE)
			listeners -= M
			if(M.client)
				M.stop_sound_channel(CHANNEL_NURSEFATHER)

/datum/action/innate/nursefather_music
	name = "Nursefather Music"
	desc = "Control your atmospheric music."
	icon_icon = 'icons/obj/radio.dmi'
	button_icon_state = "radio"
	check_flags = AB_CHECK_CONSCIOUS

/datum/action/innate/nursefather_music/Activate()
	var/datum/component/nursefather_music/comp = target
	if(!istype(comp))
		return

	var/choice = tgui_alert(owner, "Select music mode:", "Nursefather Music", list("Passive Music", "Combat Music", "Turn Off"))
	if(!choice)
		return
	if(QDELETED(owner) || QDELETED(comp))
		return

	switch(choice)
		if("Passive Music")
			comp.start_music(NURSEFATHER_MODE_PASSIVE)
			to_chat(owner, span_notice("You begin playing passive music."))
		if("Combat Music")
			comp.start_music(NURSEFATHER_MODE_COMBAT)
			to_chat(owner, span_notice("You begin playing combat music."))
		if("Turn Off")
			comp.stop_music()
			to_chat(owner, span_notice("You stop the music."))
