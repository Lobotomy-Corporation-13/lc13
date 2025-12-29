
/datum/ordeal/boss/branch12/kim
	name = "Memory of a Broken Sword"
	flavor_name = "Bamboo Hatted Kim"
	announce_text = "A mentor to many, long lost, and yearning for blood."
	end_announce_text = "And in the end, he was naught but an animal."
	announce_sound = 'sound/effects/ordeals/indigo_start.ogg'
	end_sound = 'sound/effects/ordeals/indigo_end.ogg'
	level = 4
	reward_percent = 0.25
	color = "#30317a"
	can_run = FALSE
	bosstype = /mob/living/simple_animal/hostile/distortion/kim


/datum/ordeal/boss/branch12/kim/AbleToRun()
	//if(SSmaptype.maptype == "branch12")
	//	can_run = TRUE
	return can_run
