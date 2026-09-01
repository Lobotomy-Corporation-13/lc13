//OKAY SO
//We tried giving players 500 Feral Hogs at once.
//The server cannot handle 500 Feral Hogs.
//Keep the total amount of Hogs 500 across all 5.

//Total - 480 Hogs
//Dawn - 30 Hogs
//Noon - 150 Hogs
//Dusk - 300 Hogs

// Dawn
/datum/ordeal/simplespawn/caramel_dawn
	name = "The Dawn of Caramel"
	flavor_name = "The Herald of 500 Feral Hogs"
	announce_text = "Holy shit that's a lot of hogs."
	end_announce_text = "Charlie here, feral hogs been slain. Over and out."
	level = 1
	reward_percent = 0.1
	announce_sound = 'sound/effects/ordeals/amber_start.ogg'
	end_sound = 'sound/effects/ordeals/amber_end.ogg'
	color = "#65350F"
	spawn_places = 1
	spawn_amount = 30
	place_player_multiplicator = 0
	spawn_player_multiplicator = 0
	spawn_type = /mob/living/simple_animal/hostile/hogs
	can_run = FALSE
	place_player_multiplicator = 0
	spawn_player_multiplicator = 0

/datum/ordeal/simplespawn/caramel_dawn/AbleToRun()
	if(SSevents.holidays && SSevents.holidays[APRIL_FOOLS]) //runs april 1-5
		can_run = TRUE
	if(SSmaptype.chosen_trait == FACILITY_TRAIT_JOKE_ABNOS)
		can_run = TRUE
	return can_run


/datum/ordeal/simplecommander/caramel_noon
	name = "The Noon of Caramel"
	flavor_name = "Sea of Feral Hogs"
	announce_text = "A Hail of Harpoons, for a sea of Hogs."
	end_announce_text = "WHITE WHALE, HOLY GRAIL"
	level = 2
	reward_percent = 0.15
	announce_sound = 'sound/effects/ordeals/amber_start.ogg'
	end_sound = 'sound/effects/ordeals/amber_end.ogg'
	color = "#65350F"
	boss_amount = 1
	grunt_amount = 149
	place_player_multiplicator = 0
	spawn_player_multiplicator = 0
	boss_type = list(/mob/living/simple_animal/hostile/hogs/albino)
	grunt_type = list(/mob/living/simple_animal/hostile/hogs)
	can_run = FALSE

/datum/ordeal/simplespawn/caramel_noon/AbleToRun()
	if(SSevents.holidays && SSevents.holidays[APRIL_FOOLS]) //runs april 1-5
		can_run = TRUE
	if(SSmaptype.chosen_trait == FACILITY_TRAIT_JOKE_ABNOS)
		can_run = TRUE
	return can_run


// Dusk
/datum/ordeal/simplespawn/caramel_dusk
	name = "The Dusk of Caramel"
	flavor_name = "A Rainbow of Hogs"
	announce_text = "Hogs are both"
	end_announce_text = "Charlie here, feral hogs been slain. Over and out."
	level = 3
	reward_percent = 0.2
	announce_sound = 'sound/effects/ordeals/amber_start.ogg'
	end_sound = 'sound/effects/ordeals/amber_end.ogg'
	color = "#65350F"
	spawn_places = 1
	spawn_amount = 300
	place_player_multiplicator = 0
	spawn_player_multiplicator = 0
	spawn_type = list(
		/mob/living/simple_animal/hostile/hogs/red,
		/mob/living/simple_animal/hostile/hogs/white,
		/mob/living/simple_animal/hostile/hogs/black,
		/mob/living/simple_animal/hostile/hogs/pale,
		)
	can_run = FALSE
	place_player_multiplicator = 0
	spawn_player_multiplicator = 0

/datum/ordeal/simplespawn/caramel_dusk/AbleToRun()
	if(SSevents.holidays && SSevents.holidays[APRIL_FOOLS]) //runs april 1-5
		can_run = TRUE
	if(SSmaptype.chosen_trait == FACILITY_TRAIT_JOKE_ABNOS)
		can_run = TRUE
	return can_run
