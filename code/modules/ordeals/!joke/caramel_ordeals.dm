// Dawn
/datum/ordeal/simplespawn/caramel_noon
	name = "The Noon of Caramel"
	flavor_name = "500 Feral Hogs"
	announce_text = "The Reception of 500 Feral Hogs"
	end_announce_text = "Holy shit that's a lot of hogs."
	level = 2
	reward_percent = 0.15
	announce_sound = 'sound/effects/ordeals/amber_start.ogg'
	end_sound = 'sound/effects/ordeals/amber_end.ogg'
	color = "#65350F"
	spawn_places = 1
	spawn_amount = 500
	spawn_type = /mob/living/simple_animal/hostile/hogs
	can_run = FALSE

/datum/ordeal/simplespawn/caramel_noon/AbleToRun()
	if(SSevents.holidays && SSevents.holidays[APRIL_FOOLS]) //runs april 1-5
		can_run = TRUE
	if(SSmaptype.chosen_trait == FACILITY_TRAIT_JOKE_ABNOS)
		can_run = TRUE
	return can_run
