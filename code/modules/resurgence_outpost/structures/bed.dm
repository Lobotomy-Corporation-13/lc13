/**
 * Resurgence Outpost - Wooden Sleeper
 *
 * A sleeper-like pod that allows resurgence machines to view their stats.
 * Opens and closes like a standard sleeper.
 */

/obj/structure/resurgence_bed
	name = "wooden sleeper"
	desc = "A comfortable wooden pod to rest and reflect on your progress. Click to enter, alt-click to open/close."
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper_clockwork-open"
	anchored = TRUE
	density = TRUE

	/// Whether the pod is currently open
	var/state_open = TRUE
	/// The mob currently inside
	var/mob/living/carbon/human/occupant = null

/obj/structure/resurgence_bed/Initialize(mapload)
	. = ..()
	update_icon_state()

/obj/structure/resurgence_bed/Destroy()
	if(occupant)
		eject_occupant()
	return ..()

/obj/structure/resurgence_bed/update_icon_state()
	if(state_open)
		icon_state = "sleeper_clockwork-open"
	else if(occupant)
		icon_state = "sleeper_clockwork-o"
	else
		icon_state = "sleeper_clockwork"

/obj/structure/resurgence_bed/examine(mob/user)
	. = ..()
	if(state_open)
		. += span_notice("Alt-click to close. Click to enter.")
	else
		. += span_notice("Alt-click to open.")
	if(occupant)
		. += span_notice("Currently occupied by [occupant].")

	var/area/resurgence_outpost/room/room = get_area(src)
	if(istype(room) && room.owner_ckey)
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			if(room.owner_ckey == H.ckey)
				. += span_notice("This sleeper is in your room.")
			else
				. += span_warning("This sleeper belongs to [room.owner_ckey].")
		else
			. += span_notice("This sleeper belongs to [room.owner_ckey].")
	else
		. += span_warning("This sleeper is in an unclaimed room.")

/obj/structure/resurgence_bed/AltClick(mob/user)
	if(!user.canUseTopic(src, BE_CLOSE))
		return
	if(state_open)
		close_pod()
	else
		open_pod()

/obj/structure/resurgence_bed/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return

	// If open and no occupant, user can enter
	if(state_open && !occupant)
		if(!ishuman(user))
			to_chat(user, span_warning("You cannot use this sleeper."))
			return
		enter_pod(user)
		return

	// If closed with occupant, open the UI for the occupant
	if(!state_open && occupant)
		if(user == occupant)
			ui_interact(user)
		else
			to_chat(user, span_notice("[occupant] is resting inside."))
		return

	// If open with occupant somehow, just note it
	if(occupant)
		to_chat(user, span_notice("[occupant] is inside the sleeper."))

/// Allow dragging mobs into the pod
/obj/structure/resurgence_bed/MouseDrop_T(mob/target, mob/user)
	if(HAS_TRAIT(user, TRAIT_UI_BLOCKED) || !Adjacent(user) || !user.Adjacent(target) || !ishuman(target) || !ISADVANCEDTOOLUSER(user))
		return
	if(!state_open)
		to_chat(user, span_warning("The sleeper is closed."))
		return
	if(occupant)
		to_chat(user, span_warning("The sleeper is already occupied."))
		return

	var/mob/living/carbon/human/H = target
	enter_pod(H)

/obj/structure/resurgence_bed/proc/enter_pod(mob/living/carbon/human/M)
	if(!state_open || occupant)
		return

	M.forceMove(src)
	occupant = M
	to_chat(M, span_notice("You climb into the wooden sleeper."))
	close_pod()

/obj/structure/resurgence_bed/proc/eject_occupant()
	if(!occupant)
		return

	var/mob/living/M = occupant
	occupant = null
	M.forceMove(get_turf(src))
	update_icon_state()

/obj/structure/resurgence_bed/proc/open_pod()
	if(state_open)
		return

	state_open = TRUE
	playsound(src, 'sound/machines/closet_open.ogg', 50, TRUE)
	if(occupant)
		eject_occupant()
	update_icon_state()

/obj/structure/resurgence_bed/proc/close_pod()
	if(!state_open)
		return

	state_open = FALSE
	playsound(src, 'sound/machines/closet_close.ogg', 50, TRUE)
	update_icon_state()

	if(occupant)
		to_chat(occupant, span_notice("The sleeper closes around you. You feel at peace..."))
		// Check if we can show stats and open UI
		check_and_open_stats(occupant)

/// Check if stats UI can be shown and open it
/obj/structure/resurgence_bed/proc/check_and_open_stats(mob/living/carbon/human/H)
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		to_chat(H, span_warning("You have no resurgence core to view stats."))
		return

	// Check if bed is in user's owned living quarters
	var/area/resurgence_outpost/room/room = get_area(src)
	if(!istype(room))
		to_chat(H, span_warning("This sleeper is not in a designated room. You cannot view your stats here."))
		return

	// Must be in living quarters
	if(room.room_type != ROOM_TYPE_LIVING_QUARTERS)
		to_chat(H, span_warning("This sleeper must be in living quarters to view your stats. This room is a [room.room_type]."))
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

/// Allow occupant to resist out
/obj/structure/resurgence_bed/container_resist_act(mob/living/user)
	visible_message(span_notice("[user] climbs out of [src]."))
	open_pod()

/obj/structure/resurgence_bed/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == occupant)
		occupant = null
		update_icon_state()

/obj/structure/resurgence_bed/relaymove(mob/living/user, direction)
	if(!state_open)
		container_resist_act(user)

// ============================================
// TGUI Interface for Stats
// ============================================

/obj/structure/resurgence_bed/ui_interact(mob/user, datum/tgui/ui)
	// Only show stats if user is the occupant
	if(user != occupant)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ResurgenceStats", "Character Stats")
		ui.open()

/obj/structure/resurgence_bed/ui_state(mob/user)
	return GLOB.always_state

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
