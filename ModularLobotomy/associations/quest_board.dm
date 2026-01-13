/obj/structure/quest_board
	name = "city job board"
	desc = "A board listing available fixer work. Check here for jobs."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "nboard00"
	density = TRUE
	anchored = TRUE
	var/list/available_quests = list()
	var/quest_refresh_time = 5 MINUTES
	var/max_quests = 5
	var/last_refresh = 0

/obj/structure/quest_board/Initialize()
	. = ..()
	refresh_quests()
	update_icon()
	START_PROCESSING(SSobj, src)

/obj/structure/quest_board/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/quest_board/process()
	if(world.time >= last_refresh + quest_refresh_time)
		refresh_quests()

/obj/structure/quest_board/update_icon()
	// Update icon state based on number of available quests
	var/quest_count = clamp(available_quests.len, 0, 5)
	icon_state = "nboard0[quest_count]"

/obj/structure/quest_board/proc/refresh_quests()
	available_quests.Cut()

	// Generate random quests
	var/hunt_quests = rand(1, 3)
	var/collect_quests = rand(1, 2)
	var/info_quests = rand(0, 2) // Less common than collect
	var/picture_quests = rand(1, 2)

	// List of special hunt quests that need mob existence checks
	var/list/special_hunt_quests = list(
		/datum/city_quest/hunt/clown_menace = /mob/living/simple_animal/hostile/retaliate/clown,
		/datum/city_quest/hunt/jungle_mooks = /mob/living/simple_animal/hostile/jungle/mook,
		/datum/city_quest/hunt/faithless_purge = /mob/living/simple_animal/hostile/faithless,
		/datum/city_quest/hunt/blood_fiend_boss = /mob/living/simple_animal/hostile/humanoid/blood/fiend/boss,
		/datum/city_quest/hunt/blood_fiends = /mob/living/simple_animal/hostile/humanoid/blood/fiend,
		/datum/city_quest/hunt/blood_bags = /mob/living/simple_animal/hostile/humanoid/blood/bag,
		/datum/city_quest/hunt/ghost_busting = /mob/living/simple_animal/hostile/retaliate/ghost
	)

	// Add hunt quests
	for(var/i in 1 to hunt_quests)
		var/quest_type = pick(subtypesof(/datum/city_quest/hunt) - special_hunt_quests)
		available_quests += new quest_type

	// Check for special hunt mobs
	for(var/quest_path in special_hunt_quests)
		var/mob_path = special_hunt_quests[quest_path]
		for(var/mob/living/L in GLOB.mob_living_list)
			if(istype(L, mob_path) && L.z && prob(40))
				available_quests += new quest_path
				break

	// List of special collect quests that need item existence checks
	var/list/special_collect_quests = list(
		/datum/city_quest/collect/raw_pe = /obj/item/rawpe,
		/datum/city_quest/collect/refined_pe = /obj/item/refinedpe,
		/datum/city_quest/collect/redacted_tape = /obj/item/tape/resurgence/redacted,
		/datum/city_quest/collect/ayin_plush = /obj/item/toy/plush/ayin
	)

	// Add collect quests
	for(var/i in 1 to collect_quests)
		var/quest_type = pick(subtypesof(/datum/city_quest/collect) - special_collect_quests)
		available_quests += new quest_type

	// Check for special collect items
	for(var/quest_path in special_collect_quests)
		var/item_path = special_collect_quests[quest_path]
		for(var/obj/item/I in world)
			if(istype(I, item_path) && I.z && prob(50))
				available_quests += new quest_path
				break

	// Add info quests
	for(var/i in 1 to info_quests)
		var/quest_type = pick(subtypesof(/datum/city_quest/info))
		available_quests += new quest_type

	// Add picture quests
	var/list/excluded_picture_quests = list(
		/datum/city_quest/picture/monolith_sighting,
		/datum/city_quest/picture/archsage_wisdom,
		/datum/city_quest/picture/misguiding_light
	)
	for(var/i in 1 to picture_quests)
		var/quest_type = pick(subtypesof(/datum/city_quest/picture) - excluded_picture_quests)
		available_quests += new quest_type

	// Check if monolith exists on map and add special quest if so
	for(var/obj/machinery/monolith/M in GLOB.machines)
		if(M.z && prob(50)) // 50% chance even if monolith exists
			available_quests += new /datum/city_quest/picture/monolith_sighting
			break

	// Check if archsage or joey exist and add their quests
	var/has_archsage = FALSE
	var/has_joey = FALSE
	for(var/mob/living/simple_animal/npc/N in GLOB.mob_living_list)
		if(istype(N, /mob/living/simple_animal/npc/archsage) && !has_archsage)
			has_archsage = TRUE
			if(prob(60))
				available_quests += new /datum/city_quest/picture/archsage_wisdom
		if(istype(N, /mob/living/simple_animal/npc/joey) && !has_joey)
			has_joey = TRUE
			if(prob(60))
				available_quests += new /datum/city_quest/picture/misguiding_light
		if(has_archsage && has_joey)
			break

	// Add distortion quests - rare and dangerous, with time restrictions
	if(prob(15)) // 15% chance per refresh
		var/list/distortion_landmarks = list()
		for(var/obj/effect/landmark/distortion/L in GLOB.landmarks_list)
			if(L.z)
				distortion_landmarks += L

		if(distortion_landmarks.len)
			// Build list of available distortion quests based on time
			var/list/available_distortions = list()
			var/current_time = world.time

			// Another Day's Work - available after 15 minutes
			if(current_time >= 15 MINUTES)
				available_distortions += /datum/city_quest/distortion/another_day

			// Bunnyman - available after 30 minutes
			if(current_time >= 30 MINUTES)
				available_distortions += /datum/city_quest/distortion/bunnyman

			// Lantern - available after 45 minutes
			if(current_time >= 45 MINUTES)
				available_distortions += /datum/city_quest/distortion/lantern

			// Papa Bongy - available after 45 minutes
			if(current_time >= 45 MINUTES)
				available_distortions += /datum/city_quest/distortion/papa_bongy

			// Timeripper - available after 1 hour
			if(current_time >= 60 MINUTES)
				available_distortions += /datum/city_quest/distortion/timeripper

			if(available_distortions.len)
				var/quest_type = pick(available_distortions)
				available_quests += new quest_type

	// Randomize quest order before limiting to max_quests
	// This gives all quest types equal chance to appear
	if(available_quests.len > max_quests)
		var/list/randomized_quests = list()
		var/list/temp_quests = available_quests.Copy()
		
		// Randomly pick quests until we have max_quests or run out
		while(randomized_quests.len < max_quests && temp_quests.len)
			var/datum/city_quest/Q = pick(temp_quests)
			temp_quests -= Q
			randomized_quests += Q
		
		available_quests = randomized_quests

	// Update icon based on quest count
	update_icon()

	last_refresh = world.time

/obj/structure/quest_board/attack_hand(mob/user)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(!H.mind)
		to_chat(user, span_warning("You need a mind to accept contracts!"))
		return

	// Initialize quest tracker if needed
	if(!H.mind.quest_tracker)
		H.mind.quest_tracker = new /datum/quest_tracker(H.mind)

	ui_interact(user)

/obj/structure/quest_board/attackby(obj/item/I, mob/user, params)
	if(!ishuman(user))
		return ..()
	var/mob/living/carbon/human/H = user
	if(!H.mind?.quest_tracker)
		to_chat(user, span_warning("You're not tracking any contracts!"))
		return

	// Check if this is a completed contract being turned in
	if(istype(I, /obj/item/quest_contract))
		var/obj/item/quest_contract/contract = I
		if(!contract.linked_quest)
			to_chat(user, span_warning("This contract is invalid!"))
			return
		
		var/datum/city_quest/Q = contract.linked_quest
		if(!(Q in H.mind.quest_tracker.active_quests))
			to_chat(user, span_warning("This isn't your contract!"))
			return
			
		if(!Q.completed)
			to_chat(user, span_warning("This contract isn't completed yet! Progress: [Q.get_progress_text()]"))
			return
			
		// Contract is completed - turn it in
		submit_quest(H, Q)
		qdel(contract)
		return

	// Check if this item can complete any collect quests
	for(var/datum/city_quest/collect/Q in H.mind.quest_tracker.active_quests)
		if(Q.can_collect_item(I))
			to_chat(user, span_notice("You submit [I] for the contract '[Q.name]'. ([Q.items_collected.len + 1]/[Q.items_required])"))
			Q.try_collect_item(I)
			if(Q.completed)
				to_chat(user, span_nicegreen("Collection contract completed! Turn it in at the job board to receive your reward."))
			return

	// Check if this item can complete any info quests
	for(var/datum/city_quest/info/Q in H.mind.quest_tracker.active_quests)
		if(Q.try_show_item(I))
			to_chat(user, span_notice("You show [I] to the job board for '[Q.name]'. ([Q.items_shown.len]/[Q.items_required])"))
			if(Q.completed)
				to_chat(user, span_nicegreen("Information contract completed! Turn it in to receive your reward."))
			return

	// Check if this is a photo for picture quests
	if(istype(I, /obj/item/photo))
		var/obj/item/photo/P = I
		for(var/datum/city_quest/picture/Q in H.mind.quest_tracker.active_quests)
			if(Q.try_submit_picture(P))
				to_chat(user, span_notice("You submit the photograph for '[Q.name]'. ([Q.pictures_submitted.len]/[Q.pictures_required])"))
				if(Q.completed)
					to_chat(user, span_nicegreen("Photography contract completed! Turn it in to receive your reward."))
				return
		// Check distortion quests
		for(var/datum/city_quest/distortion/Q in H.mind.quest_tracker.active_quests)
			if(Q.try_photo(P))
				to_chat(user, span_notice("You successfully photograph the distortion for '[Q.name]'!"))
				if(Q.completed)
					to_chat(user, span_nicegreen("Distortion contract completed! Turn it in to receive your reward."))
				return
		to_chat(user, span_warning("This photo doesn't match any of your active photography contract requirements."))
		return

	to_chat(user, span_warning("This item doesn't match any of your active contract requirements."))
	return

/obj/structure/quest_board/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "QuestBoard")
		ui.open()

/obj/structure/quest_board/ui_data(mob/user)
	var/list/data = list()
	var/mob/living/carbon/human/H = user

	// Available quests
	data["available_quests"] = list()
	for(var/datum/city_quest/Q in available_quests)
		data["available_quests"] += list(list(
			"id" = REF(Q),
			"name" = Q.name,
			"desc" = Q.desc,
			"type" = Q.quest_type,
			"reward" = Q.reward_ahn
		))

	// Check if player can accept more quests
	if(H.mind?.quest_tracker)
		data["can_accept_quest"] = (H.mind.quest_tracker.active_quests.len < H.mind.quest_tracker.max_active_quests)
	else
		data["can_accept_quest"] = TRUE

	data["next_refresh"] = max(0, round(((last_refresh + quest_refresh_time) - world.time) / 10))

	return data

/obj/structure/quest_board/ui_act(action, params)
	. = ..()
	if(.)
		return

	var/mob/living/carbon/human/H = usr
	if(!H.mind)
		return

	// Initialize quest tracker if needed
	if(!H.mind.quest_tracker)
		H.mind.quest_tracker = new /datum/quest_tracker(H.mind)

	switch(action)
		if("accept")
			var/datum/city_quest/Q = locate(params["quest_id"])
			if(!Q || !(Q in available_quests))
				return
			if(H.mind.quest_tracker.add_quest(Q))
				available_quests -= Q
				Q.on_accept(H.mind)
				to_chat(H, span_notice("You accept the contract: [Q.name]"))
				update_icon()
				. = TRUE

/obj/structure/quest_board/proc/submit_quest(mob/user, datum/city_quest/Q)
	var/mob/living/carbon/human/H = user

	// Delete the contract item if it still exists (not already deleted by attackby)
	if(Q.contract_item && !QDELETED(Q.contract_item))
		qdel(Q.contract_item)
		Q.contract_item = null

	switch(Q.quest_type)
		if("collect")
			var/datum/city_quest/collect/CQ = Q
			CQ.submit_items(src)
		if("info")
			var/datum/city_quest/info/IQ = Q
			IQ.submit_info(src)
		if("picture")
			var/datum/city_quest/picture/PQ = Q
			PQ.submit_pictures(src)
		else
			Q.turned_in = TRUE
			Q.grant_reward()

	H.mind.quest_tracker.remove_quest(Q)
	to_chat(user, span_nicegreen("Contract completed! You receive [Q.reward_ahn] Ahn!"))

/obj/structure/quest_board/proc/cancel_quest(mob/user, datum/city_quest/Q)
	var/mob/living/carbon/human/H = user

	// Delete the contract item before cancelling
	if(Q.contract_item)
		qdel(Q.contract_item)
		Q.contract_item = null

	// For distortion quests, clean up the spawned mob
	if(istype(Q, /datum/city_quest/distortion))
		var/datum/city_quest/distortion/DQ = Q
		if(DQ.spawned_mob && !QDELETED(DQ.spawned_mob))
			qdel(DQ.spawned_mob)

	H.mind.quest_tracker.remove_quest(Q)
	available_quests += Q // Return quest to available pool
	to_chat(user, span_warning("You have cancelled the contract: [Q.name]"))
	update_icon()
