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

	// Check if bed is in user's owned room
	var/area/resurgence_outpost/room/room = get_area(src)
	if(!istype(room))
		to_chat(H, span_warning("This bed is not in a designated room. You cannot view your stats here."))
		return

	if(room.owner_ckey != H.ckey)
		if(!room.owner_ckey)
			to_chat(H, span_warning("This room is unclaimed. You can only view stats in your own room."))
		else
			to_chat(H, span_warning("This is not your room. You can only view stats in your own room."))
		return

	// Open the stats UI
	to_chat(H, span_notice("You rest and reflect on your progress..."))
	ui_interact(H)

/obj/structure/resurgence_bed/ui_interact(mob/user, datum/tgui/ui)
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

	// Construction stat
	data["construction_level"] = core.stat_construction
	data["construction_xp"] = core.xp_construction
	data["construction_xp_needed"] = get_xp_for_level(core.stat_construction)
	data["construction_speed"] = get_stat_speed_modifier(core.stat_construction)
	data["construction_beauty"] = get_stat_beauty_bonus(core.stat_construction)

	// Crafting stat
	data["crafting_level"] = core.stat_crafting
	data["crafting_xp"] = core.xp_crafting
	data["crafting_xp_needed"] = get_xp_for_level(core.stat_crafting)
	data["crafting_speed"] = get_stat_speed_modifier(core.stat_crafting)
	data["crafting_beauty"] = get_stat_beauty_bonus(core.stat_crafting)

	// Gathering stat
	data["gathering_level"] = core.stat_gathering
	data["gathering_xp"] = core.xp_gathering
	data["gathering_xp_needed"] = get_xp_for_level(core.stat_gathering)
	data["gathering_speed"] = get_stat_speed_modifier(core.stat_gathering)
	data["gathering_yield"] = get_stat_yield_modifier(core.stat_gathering)

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
