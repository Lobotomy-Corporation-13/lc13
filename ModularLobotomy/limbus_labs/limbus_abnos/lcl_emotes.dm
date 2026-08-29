//Big Wolf
/datum/emote/abno
	mob_type_allowed_typecache = /mob/living/simple_animal/hostile/limbus_abno
	mob_type_blacklist_typecache = list()

/datum/emote/abno/mood/run_emote(mob/user, params, type_override, intentional)
	. = ..()
	if(!.)
		return
	var/mob/living/simple_animal/hostile/limbus_abno/L = user
	L.ShowEmotion(key)

/datum/emote/abno/mood/abno_wave
	key = "abno_wave"
	key_third_person = "abno_wave"
	message = "waves."

/datum/emote/abno/mood/abno_cry
	key = "abno_cry"
	key_third_person = "abno_cry"
	message = "cries."

/datum/emote/abno/mood/abno_loom
	key = "abno_loom"
	key_third_person = "abno_loom"
	message = "looms."
