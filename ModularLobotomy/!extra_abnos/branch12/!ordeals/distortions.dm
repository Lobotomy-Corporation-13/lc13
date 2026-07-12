/datum/ordeal/boss/branch12/crying_children
	name = "Memory of a Hero"
	flavor_name = "The Crying Children"
	announce_text = "A boy brought to the brink, ready to fight for what's right."
	end_announce_text = "And he is sent back to dust."
	announce_sound = 'sound/effects/ordeals/violet_start.ogg'
	end_sound = 'sound/effects/ordeals/violet_end.ogg'
	level = 3
	reward_percent = 0.2
	color = "#54b315"
	can_run = FALSE
	bosstype = /mob/living/simple_animal/hostile/abnormality/crying_children/ordeal

/datum/ordeal/boss/branch12/crying_children/AbleToRun()
	if(SSmaptype.maptype == "branch12")
		can_run = TRUE
	return can_run

/mob/living/simple_animal/hostile/abnormality/crying_children/ordeal
	core_enabled = FALSE

/datum/ordeal/boss/branch12/ripper
	name = "Memory of a Stopped Watch"
	flavor_name = "The Time Ripper"
	announce_text = "A man that froze others in time, comes to collect."
	end_announce_text = "And in the end, he was got more than what he came for."
	announce_sound = 'sound/effects/ordeals/indigo_start.ogg'
	end_sound = 'sound/effects/ordeals/indigo_end.ogg'
	level = 4
	reward_percent = 0.25
	color = "#30317a"
	can_run = FALSE
	bosstype = /mob/living/simple_animal/hostile/distortion/timeripper


/datum/ordeal/boss/branch12/ripper/AbleToRun()
	if(SSmaptype.maptype == "branch12")
		can_run = TRUE
	return can_run

/datum/ordeal/boss/branch12/pianist
	name = "Memory of That Day"
	flavor_name = "The Pianist"
	announce_text = "The day that everything changed, And hell was released."
	end_announce_text = "We would never be the same again."
	announce_sound = 'sound/effects/ordeals/indigo_start.ogg'
	end_sound = 'sound/effects/ordeals/indigo_end.ogg'
	level = 4
	reward_percent = 0.25
	color = "#30317a"
	can_run = FALSE
	bosstype = /mob/living/simple_animal/hostile/distortion/pianist/combat


/datum/ordeal/boss/branch12/pianist/AbleToRun()
	if(SSmaptype.maptype == "branch12")
		can_run = TRUE
	return can_run
