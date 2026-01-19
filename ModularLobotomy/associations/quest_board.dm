/obj/structure/quest_board
	name = "city job board"
	desc = "A board listing available fixer work. Check here for jobs."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "nboard00"
	density = TRUE
	anchored = TRUE
	var/list/available_quests = list()
	var/quest_refresh_time = 5 MINUTES
	var/max_quests = 15
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
	// Increment refresh count and remove expired/impossible quests
	var/list/to_remove = list()
	for(var/datum/city_quest/Q in available_quests)
		Q.refresh_count++
		// Remove quests that have been on the board too long
		if(Q.refresh_count >= Q.max_refreshes)
			to_remove += Q
		// Also remove quests that can no longer be completed (no targets exist)
		else if(!Q.can_generate())
			to_remove += Q

	for(var/datum/city_quest/Q in to_remove)
		available_quests -= Q
		qdel(Q)

	// Calculate how many new quests we can add (incremental refresh)
	var/current_count = available_quests.len
	var/slots_available = max_quests - current_count

	// Minimum new quests to add per refresh
	var/min_new_quests = 3

	// If no room, remove some old quests to make room for at least min_new_quests
	if(slots_available < min_new_quests && current_count > 0)
		var/to_remove_extra = min_new_quests - slots_available
		for(var/i in 1 to to_remove_extra)
			if(!available_quests.len)
				break
			var/datum/city_quest/old_quest = pick(available_quests)
			available_quests -= old_quest
			qdel(old_quest)
		slots_available = max_quests - available_quests.len

	// List to hold newly generated quests
	var/list/new_quests = list()

	// Determine how many of each type to generate based on available slots
	var/hunt_quests = rand(1, min(3, slots_available))
	var/collect_quests = rand(1, min(2, max(1, slots_available - hunt_quests)))
	var/info_quests = rand(0, min(2, max(1, slots_available - hunt_quests - collect_quests)))
	var/picture_quests = rand(1, min(2, max(1, slots_available - hunt_quests - collect_quests - info_quests)))

	// Special quests that have their own probability checks - exclude from regular pools
	var/list/special_hunt_quests = list(
		/datum/city_quest/hunt/clown_menace,
		/datum/city_quest/hunt/jungle_mooks,
		/datum/city_quest/hunt/faithless_purge,
		/datum/city_quest/hunt/blood_fiend_boss,
		/datum/city_quest/hunt/blood_fiends,
		/datum/city_quest/hunt/blood_bags,
		/datum/city_quest/hunt/ghost_busting
	)
	var/list/special_collect_quests = list(
		/datum/city_quest/collect/raw_pe,
		/datum/city_quest/collect/refined_pe,
		/datum/city_quest/collect/redacted_tape,
		/datum/city_quest/collect/ayin_plush
	)

	// Add hunt quests - validate targets exist on map
	var/list/hunt_types = subtypesof(/datum/city_quest/hunt) - special_hunt_quests
	var/hunt_attempts = 0
	var/max_attempts = hunt_types.len * 3 // More attempts for retry
	while(hunt_quests > 0 && hunt_attempts < max_attempts && hunt_types.len)
		hunt_attempts++
		var/quest_type = pick(hunt_types)
		var/datum/city_quest/hunt/Q = new quest_type
		if(Q.can_generate())
			new_quests += Q
			hunt_quests--
		else
			qdel(Q)

	// Add collect quests - validate items exist on map
	var/list/collect_types = subtypesof(/datum/city_quest/collect) - special_collect_quests
	var/collect_attempts = 0
	max_attempts = collect_types.len * 3
	while(collect_quests > 0 && collect_attempts < max_attempts && collect_types.len)
		collect_attempts++
		var/quest_type = pick(collect_types)
		var/datum/city_quest/collect/Q = new quest_type
		if(Q.can_generate())
			new_quests += Q
			collect_quests--
		else
			qdel(Q)

	// Add info quests - validate items exist on map
	var/list/info_types = subtypesof(/datum/city_quest/info)
	var/info_attempts = 0
	max_attempts = info_types.len * 3
	while(info_quests > 0 && info_attempts < max_attempts && info_types.len)
		info_attempts++
		var/quest_type = pick(info_types)
		var/datum/city_quest/info/Q = new quest_type
		if(Q.can_generate())
			new_quests += Q
			info_quests--
		else
			qdel(Q)

	// Add picture quests - validate targets exist on map
	// Exclude special picture quests that have their own probability checks
	var/list/excluded_picture_quests = list(
		/datum/city_quest/picture/monolith_sighting,
		/datum/city_quest/picture/archsage_wisdom,
		/datum/city_quest/picture/misguiding_light
	)
	var/list/picture_types = subtypesof(/datum/city_quest/picture) - excluded_picture_quests
	var/picture_attempts = 0
	max_attempts = picture_types.len * 3
	while(picture_quests > 0 && picture_attempts < max_attempts && picture_types.len)
		picture_attempts++
		var/quest_type = pick(picture_types)
		var/datum/city_quest/picture/Q = new quest_type
		if(Q.can_generate())
			new_quests += Q
			picture_quests--
		else
			qdel(Q)

	// Special hunt quests - rare, only appear if mobs exist with probability and time lock passed
	for(var/quest_path in special_hunt_quests)
		if(prob(40)) // 40% chance even if targets exist
			var/datum/city_quest/hunt/Q = new quest_path
			// Check time lock
			if(Q.time_lock > 0 && world.time < Q.time_lock)
				qdel(Q)
				continue
			if(Q.can_generate())
				new_quests += Q
			else
				qdel(Q)

	// Special collect quests - rare, only appear if items exist with probability and time lock passed
	for(var/quest_path in special_collect_quests)
		if(prob(50)) // 50% chance even if items exist
			var/datum/city_quest/collect/Q = new quest_path
			// Check time lock
			if(Q.time_lock > 0 && world.time < Q.time_lock)
				qdel(Q)
				continue
			if(Q.can_generate())
				new_quests += Q
			else
				qdel(Q)

	// Special picture quests - monolith, archsage, joey
	// Check if monolith exists on map and add special quest if so
	for(var/obj/machinery/monolith/M in GLOB.machines)
		if(M.z && prob(50)) // 50% chance even if monolith exists
			var/datum/city_quest/picture/Q = new /datum/city_quest/picture/monolith_sighting
			// Check time lock
			if(Q.time_lock > 0 && world.time < Q.time_lock)
				qdel(Q)
				break
			if(Q.can_generate())
				new_quests += Q
			else
				qdel(Q)
			break

	// Check if archsage or joey exist and add their quests
	var/has_archsage = FALSE
	var/has_joey = FALSE
	for(var/mob/living/simple_animal/npc/N in GLOB.mob_living_list)
		if(istype(N, /mob/living/simple_animal/npc/archsage) && !has_archsage)
			has_archsage = TRUE
			if(prob(60)) // 60% chance
				var/datum/city_quest/picture/Q = new /datum/city_quest/picture/archsage_wisdom
				// Check time lock
				if(Q.time_lock > 0 && world.time < Q.time_lock)
					qdel(Q)
				else if(Q.can_generate())
					new_quests += Q
				else
					qdel(Q)
		if(istype(N, /mob/living/simple_animal/npc/joey) && !has_joey)
			has_joey = TRUE
			if(prob(60)) // 60% chance
				var/datum/city_quest/picture/Q = new /datum/city_quest/picture/misguiding_light
				// Check time lock
				if(Q.time_lock > 0 && world.time < Q.time_lock)
					qdel(Q)
				else if(Q.can_generate())
					new_quests += Q
				else
					qdel(Q)
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
				new_quests += new quest_type

	// Add new quests to available_quests up to max_quests
	while(new_quests.len && available_quests.len < max_quests)
		var/datum/city_quest/Q = pick(new_quests)
		new_quests -= Q
		available_quests += Q

	// Clean up any excess generated quests that didn't fit
	for(var/datum/city_quest/Q in new_quests)
		qdel(Q)

	// Ensure at least 6 unlocked contracts (no grade or office locks)
	var/unlocked_count = 0
	var/list/locked_quests = list()
	for(var/datum/city_quest/Q in available_quests)
		if(Q.grade_lock > 0 || Q.office_lock)
			locked_quests += Q
		else
			unlocked_count++

	// If fewer than 6 unlocked, remove some locked quests to make room
	while(unlocked_count < 6 && locked_quests.len > 0)
		var/datum/city_quest/Q = pick(locked_quests)
		locked_quests -= Q
		available_quests -= Q
		qdel(Q)

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
		var/list/target_names = list()
		if(istype(Q, /datum/city_quest/hunt))
			var/datum/city_quest/hunt/HQ = Q
			for(var/mob_type in HQ.valid_targets)
				var/mob/M = mob_type
				target_names += initial(M.name)
		else if(istype(Q, /datum/city_quest/collect))
			var/datum/city_quest/collect/CQ = Q
			for(var/item_type in CQ.items_to_collect)
				var/obj/item/I = item_type
				target_names += initial(I.name)
		else if(istype(Q, /datum/city_quest/info))
			var/datum/city_quest/info/IQ = Q
			for(var/item_type in IQ.items_to_show)
				var/obj/item/I = item_type
				target_names += initial(I.name)
		data["available_quests"] += list(list(
			"id" = REF(Q),
			"name" = Q.name,
			"desc" = Q.desc,
			"type" = Q.quest_type,
			"reward" = Q.reward_ahn,
			"target_names" = target_names,
			"grade_lock" = Q.grade_lock,
			"office_lock" = Q.office_lock,
			"can_accept" = Q.can_accept(H)
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

			// Check if player can accept this quest (grade and office locks)
			if(!Q.can_accept(H))
				if(Q.grade_lock > 0)
					var/player_grade = Q.get_player_grade(H)
					if(player_grade > Q.grade_lock)
						to_chat(H, span_warning("This contract requires Grade [Q.grade_lock] or better. You are Grade [player_grade]."))
						return
				if(Q.office_lock)
					to_chat(H, span_warning("This contract requires you to be a member of an office."))
					return
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
