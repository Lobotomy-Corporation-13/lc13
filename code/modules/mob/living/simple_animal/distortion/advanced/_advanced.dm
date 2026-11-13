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
	var/offer_egoist = FALSE
	var/flee_time = 3 SECONDS
	var/flee_distance = 64
	var/sin_reward

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

//I still want to make it look like you are undistortioning a human, however I don't want to let players to play as them.
//So, I spawn a human and make them have a small animation of them fleeing!
/mob/living/simple_animal/hostile/distortion/advanced/Unmanifest()
	if(offer_egoist || key || (locate(/mob/living/carbon/human) in src))
		return ..()
	var/turf/T = get_turf(src)
	if(unmanifest_effect)
		new unmanifest_effect(T)
	if(sin_reward)
		new sin_reward(T, LAZYLEN(egoist_names) ? pick(egoist_names) : null)
	PostUnmanifest(null)
	RunAway(new /obj/effect/temp_visual/distortion_runaway(T, flee_time))
	qdel(src)

/mob/living/simple_animal/hostile/distortion/advanced/proc/RunAway(obj/effect/temp_visual/distortion_runaway/runaway)
	var/flee_dir = pick(GLOB.cardinals)
	runaway.setDir(flee_dir)
	var/dx = (flee_dir == EAST ? 1 : (flee_dir == WEST ? -1 : 0)) * flee_distance
	var/dy = (flee_dir == NORTH ? 1 : (flee_dir == SOUTH ? -1 : 0)) * flee_distance
	animate(runaway, pixel_x = dx, pixel_y = dy, alpha = 0, time = flee_time, easing = SINE_EASING | EASE_IN)

/obj/effect/temp_visual/distortion_runaway
	name = "someone"
	icon = 'icons/mob/human.dmi'
	icon_state = "human_basic"
	randomdir = FALSE
	color = "#000000"
	layer = ABOVE_MOB_LAYER

/obj/effect/temp_visual/distortion_runaway/Initialize(mapload, lifetime)
	duration = lifetime
	return ..()

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

//Now, we want to reward undistorting somehow, so that is why we will give them shiny rocks! Wonderful!
/obj/item/solidified_sin
	name = "solidified sin"
	desc = "A lump of sin, set hard as stone. They could be quite valuable..."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	w_class = WEIGHT_CLASS_TINY

/obj/item/solidified_sin/Initialize(mapload, egoist_name)
	. = ..()
	if(egoist_name)
		desc += " A name is pressed into its surface: [egoist_name]."

/obj/item/solidified_sin/wrath
	name = "solidified wrath"
	icon_state = "solidified_wrath"

/obj/item/solidified_sin/lust
	name = "solidified lust"
	icon_state = "solidified_lust"

/obj/item/solidified_sin/sloth
	name = "solidified sloth"
	icon_state = "solidified_sloth"

/obj/item/solidified_sin/gluttony
	name = "solidified gluttony"
	icon_state = "solidified_gluttony"

/obj/item/solidified_sin/gloom
	name = "solidified gloom"
	icon_state = "solidified_gloom"

/obj/item/solidified_sin/pride
	name = "solidified pride"
	icon_state = "solidified_pride"

/obj/item/solidified_sin/envy
	name = "solidified envy"
	icon_state = "solidified_envy"

// Unused shiny solidified sins, but hey! Could be extra rewards for the future!
/obj/item/solidified_sin/shiny
	name = "shining solidified sin"
	desc = "A lump of sin, set hard as stone, with a light still moving inside it. Whoever it came from was let go, not put down."

/obj/item/solidified_sin/shiny/wrath
	name = "shining solidified wrath"
	icon_state = "solidified_wrath_shine"

/obj/item/solidified_sin/shiny/lust
	name = "shining solidified lust"
	icon_state = "solidified_lust_shine"

/obj/item/solidified_sin/shiny/sloth
	name = "shining solidified sloth"
	icon_state = "solidified_sloth_shine"

/obj/item/solidified_sin/shiny/gluttony
	name = "shining solidified gluttony"
	icon_state = "solidified_gluttony_shine"

/obj/item/solidified_sin/shiny/gloom
	name = "shining solidified gloom"
	icon_state = "solidified_gloom_shine"

/obj/item/solidified_sin/shiny/pride
	name = "shining solidified pride"
	icon_state = "solidified_pride_shine"

/obj/item/solidified_sin/shiny/envy
	name = "shining solidified envy"
	icon_state = "solidified_envy_shine"
