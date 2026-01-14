// Dawn
/datum/ordeal/simplespawn/indigo_dawn
	name = "The Dawn of Indigo"
	flavor_name = "The Scouts"
	announce_text = "They come searching for what they so desperately need."
	end_announce_text = "And they search in the dark."
	announce_sound = 'sound/effects/ordeals/indigo_start.ogg'
	end_sound = 'sound/effects/ordeals/indigo_end.ogg'
	reward_percent = 0.1
	level = 1
	spawn_places = 5
	spawn_amount = 2
	spawn_type = list(
		/mob/living/simple_animal/hostile/ordeal/indigo_dawn,
		/mob/living/simple_animal/hostile/ordeal/indigo_dawn/invis,
		/mob/living/simple_animal/hostile/ordeal/indigo_dawn/skirmisher,
		)
	place_player_multiplicator = 0.08
	spawn_player_multiplicator = 0
	color = "#3F00FF"

/// This type is used for Indigo Noon and Indigo Dusk to be able to randomly spawn variant sweepers in them. It probably shouldn't be used elsewhere.
/// If given a commander_types list, it will spawn one pack per type in that list. Otherwise it will go off of pack_amount.
/datum/ordeal/indigo_specials
	name = "Indigo Specials"
	announce_text = "This Ordeal should not be able to spawn."
	level = 0
	reward_percent = 0
	var/default_grunt_type = /mob/living/simple_animal/hostile/ordeal/indigo_noon
	var/special_types = list()
	var/commander_types = list()

	var/max_specials = 1
	var/special_chance = 10
	var/grunts_per_pack = 3
	var/pack_amount = 4

	var/scaling = 0
	var/max_specials_per_agent = 0.34
	var/special_chance_per_agent = 15
	var/grunts_per_agent = 0.25
	var/packs_per_agent = 0.25

/datum/ordeal/indigo_specials/Run()
	. = ..()
	if(!LAZYLEN(GLOB.xeno_spawn))
		message_admins("No xeno spawns found when spawning in ordeal!")
		return
	scaling = length(AllLivingAgents(TRUE))

	for(var/i in 1 to scaling)
		max_specials += max_specials_per_agent
		special_chance += special_chance_per_agent
		grunts_per_pack += grunts_per_agent
		pack_amount += packs_per_agent

	max_specials = floor(max_specials)
	grunts_per_pack = floor(grunts_per_pack)
	pack_amount = floor(pack_amount)

	var/list/available_locs = GLOB.xeno_spawn.Copy()
	var/commander_amount = LAZYLEN(commander_types)
	var/spawning_commanders = FALSE
	var/packs_to_spawn = pack_amount

	if(commander_amount)
		spawning_commanders = TRUE
		packs_to_spawn = commander_amount

	for(var/i in 1 to packs_to_spawn)
		var/turf/T = pick(available_locs)
		if(length(available_locs) > 1)
			available_locs -= T
		if(spawning_commanders)
			var/mob/living/simple_animal/hostile/ordeal/commander_type = pick_n_take(commander_types)
			var/mob/living/simple_animal/hostile/ordeal/commander = new commander_type(T)
			ordeal_mobs += commander
			commander.ordeal_reference = src
		DeploySquad(T, grunts_per_pack)


/datum/ordeal/indigo_specials/proc/DeploySquad(turf/T, spawn_amount)
	var/list/deployment_area = DeploymentZone(T, TRUE)
	var/specials_spawned = 0
	for(var/i = 1 to spawn_amount)
		var/spawntype = default_grunt_type
		var/turf/deploy_spot = T
		if(LAZYLEN(deployment_area))
			deploy_spot = pick_n_take(deployment_area)
		if(LAZYLEN(special_types) && prob(special_chance))
			if(specials_spawned < max_specials)
				spawntype = pick(special_types)
				specials_spawned++
		var/mob/living/simple_animal/hostile/ordeal/M = new spawntype(deploy_spot)
		ordeal_mobs += M
		M.ordeal_reference = src

// Noon
/// Had to override some stuff and make it its own type because of inheritance issues (it was spawning packs twice).
/datum/ordeal/indigo_specials/indigo_noon
	name = "The Noon of Indigo"
	flavor_name = "The Sweepers"
	announce_text = "When night falls in the Backstreets, they will come."
	end_announce_text = "When the sun rises anew, not a scrap will remain."
	announce_sound = 'sound/effects/ordeals/indigo_start.ogg'
	end_sound = 'sound/effects/ordeals/indigo_end.ogg'
	level = 2
	reward_percent = 0.15
	color = "#3F00FF"
	default_grunt_type = /mob/living/simple_animal/hostile/ordeal/indigo_noon
	special_types = list(/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky, /mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky)
	commander_types = list()
	max_specials = 2
	special_chance = 25
	grunts_per_pack = 4
	pack_amount = 4

	max_specials_per_agent = 0.5
	special_chance_per_agent = 15
	grunts_per_agent = 0.34
	packs_per_agent = 0.25

// Dusk
/datum/ordeal/indigo_specials/indigo_dusk
	name = "The Dusk of Indigo"
	flavor_name = "Night in the Backstreets"
	announce_text = "We still have some more fuel. The power of family is not a bad thing."
	end_announce_text = "Dear neighbors, we could not finish the sweeping."
	announce_sound = 'sound/effects/ordeals/indigo_start.ogg'
	end_sound = 'sound/effects/ordeals/indigo_end.ogg'
	level = 3
	reward_percent = 0.20
	color = "#3F00FF"
	commander_types = list(
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/pale,
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/red,
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/black,
		/mob/living/simple_animal/hostile/ordeal/indigo_dusk/white
		)
	default_grunt_type = /mob/living/simple_animal/hostile/ordeal/indigo_noon
	special_types = list(/mob/living/simple_animal/hostile/ordeal/indigo_noon/chunky, /mob/living/simple_animal/hostile/ordeal/indigo_noon/lanky)
	// Variant sweepers are rarer in the Dusk than in the Noon.
	max_specials = 0
	special_chance = 10
	grunts_per_pack = 4
	pack_amount = 4

	max_specials_per_agent = 0.5
	special_chance_per_agent = 10
	grunts_per_agent = 0.25
	packs_per_agent = 0

// Midnight
/datum/ordeal/boss/indigo_midnight
	name = "The Midnight of Indigo"
	flavor_name = "Mother"
	announce_text = "Mother will give you all the assistance you need. We all could safely become a family thanks to her."
	end_announce_text = "For the sake of our families in our village, we cannot stop."
	announce_sound = 'sound/effects/ordeals/indigo_start.ogg'
	end_sound = 'sound/effects/ordeals/indigo_end.ogg'
	level = 4
	reward_percent = 0.25
	color = "#3F00FF"
	bosstype = /mob/living/simple_animal/hostile/ordeal/indigo_midnight
