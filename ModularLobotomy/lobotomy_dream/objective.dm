// This should NOT be mapped and should be spawned at the death of the final boss
GLOBAL_VAR(bough_collected)//roundend text
/obj/structure/bough/mining//from rcorp's objective.dm

/obj/structure/bough/mining/RoundEndEffect(mob/living/carbon/human/user)
	if(!do_after(user, 10 SECONDS))
		return
	bastards += user.ckey
	clear_filters()
	bough.clear_filters()
	vis_contents.Cut()
	qdel(bough)
	light_on = FALSE
	update_light()

	if(!SSticker.force_ending)
		//Round End Effects
		endround()
		GLOB.roundend_music = file("sound/roundend/canto_1.ogg")
		for(var/mob/M in GLOB.player_list)
			to_chat(M, span_userdanger("[uppertext(user.real_name)] has slain the boss and collected the bough!"))
		GLOB.bough_collected = TRUE
	else
		var/turf/turf = get_turf(src)
		new /obj/effect/decal/cleanable/confetti(turf)
		playsound(turf, 'sound/misc/sadtrombone.ogg', 100)
