/mob/living/simple_animal/hostile/distortion/advanced
	name = "advanced distortion"
	desc = "The shape of someone's heart, settling into the place around it."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "lantern"
	maxHealth = 1000
	health = 1000
	melee_damage_lower = 10
	melee_damage_upper = 15
	melee_damage_type = RED_DAMAGE
	obj_damage = 50
	can_patrol = FALSE
	var/datum/distortion_territory/territory
	//Self explainatory, how much territory do we start with.
	var/territory_start_size = 25
	var/territory_cap = 2000
	var/list/territory_stages
	//The delay between each growth.
	var/territory_growth_interval = 60 SECONDS
	var/territory_growth_rate

/mob/living/simple_animal/hostile/distortion/advanced/Initialize(mapload)
	. = ..()
	var/turf/origin = NearestOpenTurf(get_turf(src))
	if(!origin)
		return INITIALIZE_HINT_QDEL
	territory = new /datum/distortion_territory(src, origin)
	territory.Claim(territory_start_size)
	territory.StartGrowing(territory_growth_interval)

// Returns the closest open turf within three tiles.
/mob/living/simple_animal/hostile/distortion/advanced/proc/NearestOpenTurf(turf/T)
	if(!T)
		return null
	if(!T.density)
		return T
	for(var/i in 1 to 3)
		for(var/turf/candidate in RANGE_TURFS(i, T))
			if(!candidate.density)
				return candidate
	return null

//If we want the distortion to react to stage changes, we can override this proc.
/mob/living/simple_animal/hostile/distortion/advanced/proc/OnStageChange(old_stage, new_stage)
	return

//If we want the distortion to do something each time it's territory grows.
/mob/living/simple_animal/hostile/distortion/advanced/proc/OnTerritoryGrown()
	return
