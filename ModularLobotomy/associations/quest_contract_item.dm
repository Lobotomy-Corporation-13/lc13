// Physical contract items for quest tracking
/obj/item/quest_contract
	name = "city contract"
	desc = "An official contract from the city job board. Use in hand to view details."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "docs_part"
	w_class = WEIGHT_CLASS_TINY
	slot_flags = ITEM_SLOT_POCKETS
	var/datum/city_quest/linked_quest
	var/contract_color = "#ffffff"
	var/stamped = FALSE

/obj/item/quest_contract/Initialize(mapload, datum/city_quest/quest)
	. = ..()
	if(quest)
		linked_quest = quest
		quest.contract_item = src
		update_contract_info()
	update_icon()

/obj/item/quest_contract/Destroy()
	if(linked_quest)
		linked_quest.contract_item = null
		linked_quest = null
	return ..()

/obj/item/quest_contract/proc/update_contract_info()
	if(!linked_quest)
		return
	
	name = "[linked_quest.quest_type] contract - [linked_quest.name]"
	
	// Set color based on quest type
	switch(linked_quest.quest_type)
		if("hunt")
			contract_color = "#ff4444"
		if("collect")
			contract_color = "#ffff44"
		if("info")
			contract_color = "#4444ff"
		if("picture")
			contract_color = "#ff44ff"
		if("distortion")
			contract_color = "#ff8844"
		else
			contract_color = "#ffffff"
	
	// Add stamp overlay when quest is completed
	if(linked_quest.completed && !stamped)
		add_stamp()

/obj/item/quest_contract/update_icon()
	. = ..()
	cut_overlays()
	var/mutable_appearance/color_overlay = mutable_appearance(icon, icon_state)
	color_overlay.color = contract_color
	color_overlay.alpha = 100
	add_overlay(color_overlay)

/obj/item/quest_contract/examine(mob/user)
	. = ..()
	if(linked_quest)
		. += span_notice("Contract: [linked_quest.name]")
		. += span_notice("Type: [linked_quest.quest_type]")
		. += span_notice("Progress: [linked_quest.get_progress_text()]")
		. += span_notice("Reward: [linked_quest.reward_ahn] Ahn")
		if(linked_quest.completed)
			. += span_nicegreen("CONTRACT COMPLETED - Return to job board for payment!")

/obj/item/quest_contract/attack_self(mob/user)
	if(!linked_quest)
		to_chat(user, span_warning("This contract is invalid!"))
		return
	ui_interact(user)

/obj/item/quest_contract/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "QuestContract")
		ui.open()

/obj/item/quest_contract/ui_data(mob/user)
	var/list/data = list()
	
	if(!linked_quest)
		data["invalid"] = TRUE
		return data
	
	data["contract_type"] = linked_quest.quest_type
	data["quest_name"] = linked_quest.name
	data["quest_desc"] = linked_quest.desc
	data["progress_text"] = linked_quest.get_progress_text()
	data["reward"] = linked_quest.reward_ahn
	data["completed"] = linked_quest.completed
	
	// Add specific progress details based on quest type
	switch(linked_quest.quest_type)
		if("hunt")
			var/datum/city_quest/hunt/H = linked_quest
			data["current_progress"] = H.kills_completed
			data["required_progress"] = H.kill_count_required
			data["progress_type"] = "Eliminations"
		if("collect")
			var/datum/city_quest/collect/C = linked_quest
			data["current_progress"] = C.items_collected.len
			data["required_progress"] = C.items_required
			data["progress_type"] = "Items"
		if("info")
			var/datum/city_quest/info/I = linked_quest
			data["current_progress"] = I.items_shown.len
			data["required_progress"] = I.items_required
			data["progress_type"] = "Documentation"
		if("picture")
			var/datum/city_quest/picture/P = linked_quest
			data["current_progress"] = P.pictures_submitted.len
			data["required_progress"] = P.pictures_required
			data["progress_type"] = "Photographs"
		if("distortion")
			var/datum/city_quest/distortion/D = linked_quest
			data["current_progress"] = D.photo_taken ? 1 : 0
			data["required_progress"] = 1
			data["progress_type"] = "Documentation"

	// Add target names for hunt/collect/info/picture quests
	var/list/target_names = list()
	switch(linked_quest.quest_type)
		if("hunt")
			var/datum/city_quest/hunt/HQ = linked_quest
			for(var/mob_type in HQ.valid_targets)
				var/mob/M = mob_type
				target_names += initial(M.name)
		if("collect")
			var/datum/city_quest/collect/CQ = linked_quest
			for(var/item_type in CQ.items_to_collect)
				var/obj/item/I = item_type
				target_names += initial(I.name)
		if("info")
			var/datum/city_quest/info/IQ = linked_quest
			for(var/item_type in IQ.items_to_show)
				var/obj/item/I = item_type
				target_names += initial(I.name)
		if("picture")
			var/datum/city_quest/picture/PQ = linked_quest
			for(var/mob_type in PQ.targets_to_photograph)
				var/mob/M = mob_type
				target_names += initial(M.name)
	data["target_names"] = target_names

	return data

/obj/item/quest_contract/ui_state(mob/user)
	return GLOB.always_state

/obj/item/quest_contract/ui_act(action, params)
	. = ..()
	if(.)
		return
	
	switch(action)
		if("cancel")
			if(!linked_quest || linked_quest.completed)
				return
			
			var/mob/living/carbon/human/H = usr
			if(!ishuman(H) || H.mind != linked_quest.quest_mind)
				to_chat(usr, span_warning("This isn't your contract!"))
				return
			
			// Cancel the quest
			to_chat(H, span_warning("You tear up the contract, cancelling '[linked_quest.name]'."))
			
			// Clean up distortion mobs if applicable
			if(istype(linked_quest, /datum/city_quest/distortion))
				var/datum/city_quest/distortion/DQ = linked_quest
				if(DQ.spawned_mob && !QDELETED(DQ.spawned_mob))
					qdel(DQ.spawned_mob)
			
			// Remove from tracker
			if(H.mind.quest_tracker)
				H.mind.quest_tracker.remove_quest(linked_quest)
			
			// Delete the contract (which will clean up the quest reference)
			qdel(src)
			return TRUE

/obj/item/quest_contract/proc/add_stamp()
	if(stamped)
		return
	
	stamped = TRUE
	
	// Add a "COMPLETED" stamp overlay
	var/mutable_appearance/stampoverlay = mutable_appearance('icons/obj/bureaucracy.dmi', "paper_stamp-ok")
	stampoverlay.pixel_x = rand(-2, 2)
	stampoverlay.pixel_y = rand(-3, 2)
	add_overlay(stampoverlay)
	
	// Add a city seal stamp too
	var/mutable_appearance/sealoverlay = mutable_appearance('icons/obj/bureaucracy.dmi', "paper_stamp-cent")
	sealoverlay.pixel_x = rand(-10, -6)
	sealoverlay.pixel_y = rand(6, 10)
	add_overlay(sealoverlay)
	
	playsound(src, 'sound/items/handling/paper_pickup.ogg', 50, TRUE)
	visible_message(span_notice("[src] gets stamped with approval seals!"))