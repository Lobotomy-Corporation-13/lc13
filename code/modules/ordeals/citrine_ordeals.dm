// All of these ordeals have to be some sort of simplespawn just due to the faith mechanic.

/datum/ordeal/simplespawn/citrine
	name = "The Dawn of Citrine"
	flavor_name = "His Acts I"
	announce_text = "Awake, arise or be for ever fall’n."
	end_announce_text = "All is not lost."
	level = 1
	reward_percent = 0.1
	announce_sound = 'sound/effects/ordeals/amber_start.ogg'
	end_sound = 'sound/effects/ordeals/amber_end.ogg'
	color = "#FFFDDD"
	spawn_places = 6
	spawn_amount = 1
	spawn_type = /mob/living/simple_animal/hostile/ordeal/citrine/archer

	var/current_faith
	var/faith_goal = 150	//Cherubim give 0.5 per second, at 6 this takes roughly 50 seconds.

/datum/ordeal/simplespawn/citrine/noon
	name = "The Noon of Citrine"
	flavor_name = "His Acts II"
	announce_text = "Did I request thee, Maker, from my clay to mould me man?"
	end_announce_text = "What is dark within me, illumine."
	level = 2
	reward_percent = 0.15
	announce_sound = 'sound/effects/ordeals/amber_start.ogg'
	end_sound = 'sound/effects/ordeals/amber_end.ogg'
	color = "#FFFDDD"
	spawn_places = 4
	spawn_amount = 3
	spawn_type = list(
		/mob/living/simple_animal/hostile/ordeal/citrine/knight,
		/mob/living/simple_animal/hostile/ordeal/citrine/archer,
		/mob/living/simple_animal/hostile/ordeal/citrine/priest,
		)

	faith_goal = 400	//The priests generate 1 faith per second, and the Cherubim 0.5
	//If there are 4 priests and 4 cherubim, then they will take roughly 66.6 seconds.
