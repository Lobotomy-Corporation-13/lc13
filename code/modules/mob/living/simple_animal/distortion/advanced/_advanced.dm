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
	//Making sure that we are not calling teardown multiple times.
	var/torn_down = FALSE
	//If we have our distortion summoning things, like walls or clues, we can track them here.
	var/list/owned = list()
	//When do we start converting the turfs around them?
	var/gimmick_stage = 2
	//What kind of random effects will it spawn within its territory?
	var/list/oddities = list(/obj/effect/temp_visual/distortion_oddity/shade)

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

/mob/living/simple_animal/hostile/distortion/advanced/death(gibbed)
	Teardown()
	return ..()

/mob/living/simple_animal/hostile/distortion/advanced/Destroy()
	Teardown()
	return ..()

//Getting rid of all of territory, has a check to not trigger multiple times since it can be called from both death and Destroy.
/mob/living/simple_animal/hostile/distortion/advanced/proc/Teardown()
	if(torn_down)
		return
	torn_down = TRUE
	ConsumeStoredHuman()
	QDEL_NULL(territory)
	for(var/atom/thing in owned)
		qdel(thing)
	owned.Cut()

//Marks an object as owned by the distortion.
/mob/living/simple_animal/hostile/distortion/advanced/proc/Own(atom/movable/thing)
	if(QDELETED(thing))
		return
	owned += thing
	RegisterSignal(thing, COMSIG_PARENT_QDELETING, PROC_REF(OnOwnedDeleted))

//Updates the list so that we don't try to delete objects that are already deleted.
/mob/living/simple_animal/hostile/distortion/advanced/proc/OnOwnedDeleted(datum/source)
	SIGNAL_HANDLER
	owned -= source

//Hey, we don't want to just... qdel the human when the distortion dies since they could be carrying important stuff.
/mob/living/simple_animal/hostile/distortion/advanced/proc/ConsumeStoredHuman()
	var/turf/T = get_turf(src)
	for(var/mob/living/carbon/human/person in src)
		if(T)
			person.forceMove(T)
		person.unequip_everything()
		qdel(person)

//If we want the distortion to react to stage changes, we can override this proc.
/mob/living/simple_animal/hostile/distortion/advanced/proc/OnStageChange(old_stage, new_stage)
	return

//If we want the distortion to do something each time it's territory grows.
/mob/living/simple_animal/hostile/distortion/advanced/proc/OnTerritoryGrown()
	return

//If we want to do something to a claimed turf, maybe placing a trap or something like that.
//However, this is called VERY often, so keep it simple.
/mob/living/simple_animal/hostile/distortion/advanced/proc/OnTurfClaimed(turf/T)
	return

//A lot of distortions have a stage where they start corrupting or changing the area around them.
//So, this can be overwritten to apply those effects to the nearest claimed turfs.
/mob/living/simple_animal/hostile/distortion/advanced/proc/ApplyCenterEffects(list/turfs)
	return

//Some basic visual effects for distortion oddities.
/obj/effect/temp_visual/distortion_oddity
	randomdir = FALSE
	layer = ABOVE_OBJ_LAYER
	duration = 3 SECONDS

/obj/effect/temp_visual/distortion_oddity/shade
	icon = 'icons/turf/areas.dmi'
	icon_state = "dark"
	alpha = 0
	duration = 4 SECONDS

/obj/effect/temp_visual/distortion_oddity/shade/Initialize(mapload)
	. = ..()
	animate(src, alpha = 120, time = duration * 0.4, easing = SINE_EASING)
	animate(alpha = 0, time = duration * 0.6)
