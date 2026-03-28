/mob/living/simple_animal/hostile/abnormality/skub
	name = "Skub"
	desc = "It's skub."
	health = 500
	maxHealth = 500
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "skub"
	icon_living = "skub"
	portrait = "skub"
	can_breach = FALSE
	threat_level = WAW_LEVEL
	start_qliphoth = 3
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 35,
		ABNORMALITY_WORK_INSIGHT = list(10, 20, 35, 35, 35),
		ABNORMALITY_WORK_ATTACHMENT = 35,
		ABNORMALITY_WORK_REPRESSION = list(10, 40, 50, 55, 60),
	)

	work_damage_amount = 12
	work_damage_type = WHITE_DAMAGE
	can_patrol = FALSE
	wander = FALSE

	ego_list = list(
		/datum/ego_datum/weapon/pro_skub,
		/datum/ego_datum/weapon/anti_skub,
		/datum/ego_datum/armor/pro_skub,
		/datum/ego_datum/armor/anti_skub,
	)
	//gift_type =  /datum/ego_gifts/skub
	abnormality_origin = ABNORMALITY_ORIGIN_JOKE
	//Im not sure where this is used?
	var/list/currently_insane = list()
	var/insanity_counter
	var/riot_cooldown
	var/riot_cooldown_time = 60 SECONDS
	var/list/pro_list = list()
	var/list/con_list = list()
	var/skub_type = "skub"
	var/riot_time = 30 SECONDS

/mob/living/simple_animal/hostile/abnormality/skub/Destroy()
	UnregisterAll()
	return ..()

//work stuff
/mob/living/simple_animal/hostile/abnormality/skub/PostWorkEffect(mob/living/carbon/human/user, work_type, pe)
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.z != z)
			continue
		if(H.stat == DEAD)
			continue
		Skubification(H)

/mob/living/simple_animal/hostile/abnormality/skub/WorkChance(mob/living/carbon/human/user, chance, work_type)//set the new work chances
	var/chance_mod = 0
	switch(work_type)
		if(ABNORMALITY_WORK_INSIGHT)
			if(user in pro_list)
				chance_mod += 25
		if(ABNORMALITY_WORK_REPRESSION)
			if(user in pro_list)
				chance_mod -= 35
	say(chance)
	say(chance + chance_mod)
	return chance + chance_mod

/mob/living/simple_animal/hostile/abnormality/skub/NeutralEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(25))
		datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/skub/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/skub/ZeroQliphoth(mob/living/carbon/human/user)
	..()
	riot_cooldown = world.time + riot_cooldown_time
	var/list/target_list = list()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.z != z)
			continue
		if(H.stat == DEAD)
			continue
		target_list += H
		if(H in pro_list)
			to_chat(H, span_boldwarning("Your dedication to [skub_type] reaches a fever pitch!"))
		else
			Skubification(H, "ANTI_SKUB")
			to_chat(H, span_boldwarning("You can't stop thinking about how much you hate [skub_type]!"))
	addtimer(CALLBACK(src, PROC_REF(Skubageddon), target_list), 3 SECONDS)

/mob/living/simple_animal/hostile/abnormality/skub/proc/Skubageddon(list/victems)
	for(var/mob/living/carbon/human/H in victems)
		ActivateSleeperAgent(H)

	addtimer(CALLBACK(src, PROC_REF(StopRiot)), riot_time)

/mob/living/simple_animal/hostile/abnormality/skub/proc/StopRiot()
	var/list/skub_list = pro_list + con_list
	for(var/mob/living/carbon/human/H in skub_list)
		H.adjustSanityLoss(-500)
	UnregisterAll()
	datum_reference.qliphoth_change(3)

/mob/living/simple_animal/hostile/abnormality/skub/proc/ActivateSleeperAgent(mob/living/carbon/human/H)
	if(!H)
		return
	H.adjustSanityLoss(500)
	if(H in pro_list && !has_status_effect(/datum/status_effect/panicked_type/skub))
		QDEL_NULL(H.ai_controller)
		H.ai_controller = /datum/ai_controller/insane/murder/skub
		H.apply_status_effect(/datum/status_effect/panicked_type/skub)
	if(H in con_list && !has_status_effect(/datum/status_effect/panicked_type/anti_skub))
		QDEL_NULL(H.ai_controller)
		H.ai_controller = /datum/ai_controller/insane/murder/anti_skub
		H.apply_status_effect(/datum/status_effect/panicked_type/anti_skub)
	H.InitializeAIController()

/mob/living/simple_animal/hostile/abnormality/skub/proc/Skubification(new_link, demonination = "PRO_SKUB")
	if(!new_link)
		return
	if((new_link in pro_list) || (new_link in con_list))
		return
	RegisterMob(new_link)
	if(demonination == "PRO_SKUB" && length(pro_list) <= length(con_list))
		pro_list += new_link
		return
	con_list += new_link

/mob/living/simple_animal/hostile/abnormality/skub/proc/SwapSkub(mob/living/skubber)
	if(skubber in pro_list)
		pro_list -= skubber
		con_list += skubber
		to_chat(skubber, span_boldwarning("Maybe [skub_type] is cool afterall."))
		return
	con_list -= skubber
	pro_list += skubber
	to_chat(skubber, span_boldwarning("Maybe [skub_type] isnt cool afterall?"))

/mob/living/simple_animal/hostile/abnormality/skub/proc/BalancedSkub()
	var/pro_num = length(pro_list)
	var/con_num = length(con_list)
	var/total_num = pro_num + con_num
	var/diff_num = abs(pro_num - con_num)
	var/list/greater_skub = pro_list
	if(total_num <= 1 || diff_num == 0)
		return

	if(greater_skub < con_list)
		greater_skub = con_list
	if(diff_num == total_num)
		diff_num = round(diff_num/2)

	var/iteration = 1
	for(var/i in greater_skub)
		if(iteration == diff_num)
			break
		SwapSkub(i)
		iteration++

/mob/living/simple_animal/hostile/abnormality/skub/proc/RegisterMob(mob/living/skubbite)
	if(!skubbite)
		return
	RegisterSignal(skubbite, list(COMSIG_PARENT_QDELETING), PROC_REF(UnregisterMob))

/mob/living/simple_animal/hostile/abnormality/skub/proc/UnregisterMob(mob/living/skubbite)
	if(!skubbite)
		return
	UnregisterSignal(skubbite, list(COMSIG_PARENT_QDELETING))
	pro_list -= skubbite
	con_list -= skubbite

/mob/living/simple_animal/hostile/abnormality/skub/proc/UnregisterAll()
	var/list/total = con_list + pro_list
	for(var/i in total)
		UnregisterMob(i)
	pro_list.Cut()
	con_list.Cut()

/datum/status_effect/panicked_type/skub
	icon = "murder"

/datum/ai_controller/insane/murder/skub
	lines_type = /datum/ai_behavior/say_line/skub

/datum/ai_behavior/say_line/skub
	lines = list(
		"I LOVE SKUB!",
		"THAT'S MY SKUB!!!",
		"I stand with skub!",
		"Protect skub!",
	)

/datum/ai_controller/insane/murder/skub/CanTarget(atom/movable/thing)
	. = ..()
	var/mob/living/living_thing = thing
	if(. && istype(living_thing))
		if(ishuman(living_thing))
			var/mob/living/carbon/human/H = living_thing
			if(HAS_AI_CONTROLLER_TYPE(H, src))
				return FALSE

/datum/ai_controller/insane/murder/skub/on_Crossed(datum/source, atom/movable/AM)
	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		if(HAS_AI_CONTROLLER_TYPE(H, src))
			return
	return ..()

/datum/status_effect/panicked_type/anti_skub
	icon = "murder"

/datum/ai_controller/insane/murder/anti_skub
	lines_type = /datum/ai_behavior/say_line/anti_skub

/datum/ai_behavior/say_line/anti_skub
	lines = list(
		"I HATE FUCKING SKUB!",
		"GIVE ME THAT!",
		"I'll destroy that skub myself!",
		"Down with skub!",
	)

/datum/ai_controller/insane/murder/anti_skub/CanTarget(atom/movable/thing)
	. = ..()
	var/mob/living/living_thing = thing
	if(. && istype(living_thing))
		if(ishuman(living_thing))
			var/mob/living/carbon/human/H = living_thing
			if(HAS_AI_CONTROLLER_TYPE(H, src))
				return FALSE

/datum/ai_controller/insane/murder/anti_skub/on_Crossed(datum/source, atom/movable/AM)
	if(ishuman(AM))
		var/mob/living/carbon/human/H = AM
		if(HAS_AI_CONTROLLER_TYPE(H, src))
			return
	return ..()
