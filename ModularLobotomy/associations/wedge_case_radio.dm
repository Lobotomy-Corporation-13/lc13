/datum/case_suspect
	var/name
	var/list/traits = list()

/datum/outfit/job/civilian/case_victim
	name = "Case Victim"
	id = null
	belt = null
	back = null
	box = null
	ignore_pack = TRUE

/obj/structure/case_radio
	name = "case radio"
	desc = "A case radio Liu dispatch uses to send the Wedge Office its cases."
	icon = 'icons/obj/radio.dmi'
	icon_state = "radio"
	max_integrity = 300
	density = TRUE
	anchored = TRUE
	resistance_flags = INDESTRUCTIBLE
	var/isready = TRUE
	var/datum/case_suspect/culprit
	var/list/suspects = list()
	var/turf/scene_turf
	var/list/body_mark_traits = list("Blade user", "Heavy build", "Smoker", "Wounded")
	var/list/trait_items = list(
		"Gun user" = /obj/item/ammo_casing/spent,
		"Drinker" = /obj/item/broken_bottle,
		"Augmented" = /obj/effect/decal/cleanable/robot_debris,
		"Sweet tooth" = /obj/item/trash/candy,
		"Pet owner" = /obj/item/clothing/neck/petcollar,
		"Gambler" = /obj/item/dice/d6,
	)
	var/traits_per_suspect = 3
	var/suspect_count = 5
	var/min_shared_traits = 1
	var/max_shared_traits = 2
	var/body_mark_damage = 40
	var/datum/weakref/victim_ref
	var/scene_radius = 2
	var/list/evidence = list()
	var/clue_outline_color = "#ffd400"
	var/clue_flicker_time = 0.5 SECONDS
	var/reward_type = /obj/item/stack/spacecash/c1000
	var/case_cooldown = 10 MINUTES

/obj/structure/case_radio/Destroy()
	ClearCase()
	return ..()

/obj/structure/case_radio/attack_hand(mob/user)
	if(culprit)
		ShowSuspects(user)
		return
	if(!isready)
		say("No new cases, for now.")
		return
	StartCase()

/obj/structure/case_radio/proc/StartCase()
	var/list/scenes = list()
	for(var/obj/effect/landmark/cityspawner/landmark in GLOB.landmarks_list)
		scenes += landmark
	if(!length(scenes))
		say("No cases in the city right now.")
		return
	isready = FALSE
	scene_turf = get_turf(pick(scenes))
	culprit = MakeSuspect(list())
	suspects = list(culprit)
	for(var/n in 1 to suspect_count - 1)
		var/list/shared = list()
		var/list/culprit_pool = culprit.traits.Copy()
		for(var/i in 1 to rand(min_shared_traits, max_shared_traits))
			shared += pick_n_take(culprit_pool)
		suspects += MakeSuspect(shared)
	suspects = shuffle(suspects)
	SpawnVictim()
	say("New case: a body was found in the alleyways at [scene_turf.x], [scene_turf.y]. Find out who did it.")

// Just creates a new case suspect datum, which holds the name and traits of the suspect.
/obj/structure/case_radio/proc/MakeSuspect(list/shared)
	var/datum/case_suspect/S = new
	S.name = random_unique_name(pick(MALE, FEMALE))
	S.traits = shared.Copy()
	var/list/pool = body_mark_traits.Copy()
	for(var/trait in trait_items)
		pool += trait
	if(culprit)
		pool -= culprit.traits
	// Fill the rest of the traits with random ones, so that each suspect has a unique set of traits.
	for(var/i in 1 to traits_per_suspect - length(shared))
		S.traits += pick_n_take(pool)
	return S

//Spawns the body, and applies the body mark traits to it, if the culprit has any of those traits.
/obj/structure/case_radio/proc/SpawnVictim()
	var/mob/living/carbon/human/victim = new(scene_turf)
	randomize_human(victim)
	if("Heavy build" in culprit.traits)
		victim.deal_damage(body_mark_damage, BRUTE, src, attack_type = ATTACK_TYPE_ENVIRONMENT, def_zone = BODY_ZONE_HEAD)
	if("Smoker" in culprit.traits)
		victim.deal_damage(body_mark_damage, FIRE, src, attack_type = ATTACK_TYPE_ENVIRONMENT, def_zone = BODY_ZONE_HEAD)
	victim.death()
	if("Blade user" in culprit.traits)
		var/obj/item/bodypart/arm = victim.get_bodypart(pick(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM))
		if(arm?.dismember())
			MarkClue(arm)
	victim.equipOutfit(/datum/outfit/job/civilian/case_victim)
	if("Wounded" in culprit.traits)
		victim.add_blood_DNA(list("[rand(10000, 99999)]" = random_blood_type()))
	victim_ref = WEAKREF(victim)
	SpawnClueItems()

//Spawns the items that are connected to the culprit's traits, that are within the trait_items list.
/obj/structure/case_radio/proc/SpawnClueItems()
	var/area/scene_area = get_area(scene_turf)
	var/list/floors = list()
	for(var/turf/open/T in range(scene_radius, scene_turf))
		if(get_area(T) == scene_area && !T.is_blocked_turf(TRUE))
			floors += T
	if(!length(floors))
		floors += scene_turf
	for(var/trait in culprit.traits)
		//Checks if a trait is within the trait items list.
		var/item_type = trait_items[trait]
		if(item_type)
			MarkClue(new item_type(pick(floors)))

/obj/structure/case_radio/proc/MarkClue(atom/movable/clue)
	clue.add_filter("wedge_clue", 2, list("type" = "outline", "color" = clue_outline_color, "size" = 1))
	animate(clue.get_filter("wedge_clue"), alpha = 0, time = clue_flicker_time, loop = -1)
	animate(alpha = 255, time = clue_flicker_time)
	evidence += WEAKREF(clue)

// Creates a basic HMTL window, which has a list of suspects with their traits bellow them.
/obj/structure/case_radio/proc/ShowSuspects(mob/user)
	var/dat = "<b>Crime scene:</b> alleyways at [scene_turf.x], [scene_turf.y]<hr><table>"
	dat += "<tr><th>Suspect</th><th>Key traits</th><th></th></tr>"
	for(var/i in 1 to length(suspects))
		var/datum/case_suspect/S = suspects[i]
		dat += "<tr><td>[S.name]</td><td>[S.traits.Join(", ")]</td>"
		// This makes a link that calls Topic() with the "accuse" parameter within href_list,
		// with accuse holding the index of the suspect in the suspects list as a string like "3".
		dat += "<td><a href='byond://?src=[REF(src)];accuse=[i]'>Accuse</a></td></tr>"
	dat += "</table>"
	var/datum/browser/popup = new(user, "case_radio", name, 450, 300)
	popup.set_content(dat)
	popup.open()

/obj/structure/case_radio/Topic(href, href_list)
	. = ..()
	if(. || !culprit || !usr.canUseTopic(src, BE_CLOSE))
		return
	//It checks if the href_list has the "accuse" parameter, and if it does it converts the string "3" into the number 3.
	var/index = text2num(href_list["accuse"])
	if(index >= 1 && index <= length(suspects))
		Accuse(suspects[index])
		usr << browse(null, "window=case_radio")

/obj/structure/case_radio/proc/Accuse(datum/case_suspect/S)
	if(S == culprit)
		say("Liu confirms it: [S.name] was the culprit. Issuing payment.")
		new reward_type(get_turf(src))
	else
		say("Wrong. The culprit was [culprit.name]. Case closed.")
	ClearCase()
	addtimer(CALLBACK(src, PROC_REF(NewCase)), case_cooldown)

/obj/structure/case_radio/proc/ClearCase()
	var/mob/living/victim = victim_ref?.resolve()
	if(victim)
		qdel(victim)
	victim_ref = null
	for(var/datum/weakref/ref in evidence)
		//.resolve() returns null if the weakref is invalid (Like if the body has already been gibbed), so we check for that before qdel()ing it.
		var/atom/movable/thing = ref.resolve()
		if(thing)
			qdel(thing)
	evidence.Cut()
	suspects.Cut()
	culprit = null
	scene_turf = null

/obj/structure/case_radio/proc/NewCase()
	isready = TRUE
