/**
 * Resurgence Outpost - Bed Structure
 *
 * A bed that allows resurgence machines to view their stats.
 * Stats UI opens when buckling to the bed in your owned room.
 */

/obj/structure/resurgence_bed
	name = "bed"
	desc = "A comfortable place to rest and reflect on your progress. Buckle yourself to rest."
	icon = 'icons/obj/objects.dmi'
	icon_state = "bed"
	anchored = TRUE
	density = FALSE
	can_buckle = TRUE
	buckle_lying = 90
	max_integrity = 100

/// Called after a mob is buckled to the bed - opens stats UI for resurgence machines
/obj/structure/resurgence_bed/post_buckle_mob(mob/living/M)
	. = ..()

	// Check if the buckled mob is a resurgence machine
	if(!ishuman(M))
		return

	var/mob/living/carbon/human/H = M
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return

	// Check if bed is in user's owned living quarters
	var/area/resurgence_outpost/room/room = get_area(src)
	if(!istype(room))
		to_chat(H, span_warning("This bed is not in a designated room. You cannot view your stats here."))
		return

	// Must be in living quarters
	if(room.room_type != ROOM_TYPE_LIVING_QUARTERS)
		to_chat(H, span_warning("This bed must be in living quarters to view your stats. This room is a [room.room_type]."))
		return

	if(room.owner_ckey != H.ckey)
		if(!room.owner_ckey)
			to_chat(H, span_warning("This room is unclaimed. You can only view stats in your own living quarters."))
		else
			to_chat(H, span_warning("This is not your room. You can only view stats in your own living quarters."))
		return

	// Open the stats UI
	to_chat(H, span_notice("You rest and reflect on your progress..."))
	ui_interact(H)

/obj/structure/resurgence_bed/ui_interact(mob/user, datum/tgui/ui)
	// Only show stats if user is buckled to this bed
	if(!has_buckled_mobs() || !(user in buckled_mobs))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ResurgenceStats", "Character Stats")
		ui.open()

/obj/structure/resurgence_bed/ui_data(mob/user)
	var/list/data = list()

	if(!ishuman(user))
		return data

	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return data

	// Crafting stat
	data["crafting_level"] = core.stat_crafting
	data["crafting_xp"] = core.xp_crafting
	data["crafting_xp_needed"] = get_xp_for_level(core.stat_crafting)
	data["crafting_speed"] = get_stat_speed_modifier(core.stat_crafting)
	data["crafting_beauty"] = get_stat_beauty_bonus(core.stat_crafting)

	// Mining stat
	data["mining_level"] = core.stat_mining
	data["mining_xp"] = core.xp_mining
	data["mining_xp_needed"] = get_xp_for_level(core.stat_mining)
	data["mining_work_bonus"] = core.stat_mining - 1
	data["mining_yield"] = get_mining_yield_multiplier(core.stat_mining)

	// Harvesting stat
	data["harvesting_level"] = core.stat_harvesting
	data["harvesting_xp"] = core.xp_harvesting
	data["harvesting_xp_needed"] = get_xp_for_level(core.stat_harvesting)
	data["harvesting_work_bonus"] = core.stat_harvesting - 1
	data["harvesting_yield"] = get_harvesting_yield_bonus(core.stat_harvesting)

	// Cooking stat
	data["cooking_level"] = core.stat_cooking
	data["cooking_xp"] = core.xp_cooking
	data["cooking_xp_needed"] = get_xp_for_level(core.stat_cooking)
	data["cooking_speed"] = get_stat_speed_modifier(core.stat_cooking)
	data["cooking_quality"] = get_stat_beauty_bonus(core.stat_cooking)

	return data

/obj/structure/resurgence_bed/ui_static_data(mob/user)
	var/list/data = list()
	data["max_level"] = STAT_MAX_LEVEL
	return data

/obj/structure/resurgence_bed/examine(mob/user)
	. = ..()
	. += span_notice("Buckle yourself to view your character stats.")

	var/area/resurgence_outpost/room/room = get_area(src)
	if(istype(room) && room.owner_ckey)
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			if(room.owner_ckey == H.ckey)
				. += span_notice("This bed is in your room.")
			else
				. += span_warning("This bed belongs to [room.owner_ckey].")
		else
			. += span_notice("This bed belongs to [room.owner_ckey].")
	else
		. += span_warning("This bed is in an unclaimed room.")
