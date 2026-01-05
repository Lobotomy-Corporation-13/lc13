/**
 * Resurgence Outpost - Wooden Sleeper
 *
 * A sleeper-like pod that allows resurgence machines to view their stats.
 * Players claim beds (not rooms) to get faith bonuses.
 * Living quarters beds give +0.025 faith/tick, barracks beds remove homeless penalty.
 */

/// Global tracking of bed ownership: ckey -> bed reference
GLOBAL_LIST_EMPTY(resurgence_bed_owners)

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
	/// The ckey of the player who owns this bed (null = unclaimed)
	var/owner_ckey = null

/obj/structure/resurgence_bed/Initialize(mapload)
	. = ..()
	update_icon_state()

/obj/structure/resurgence_bed/Destroy()
	if(occupant)
		eject_occupant()
	// Clean up ownership
	if(owner_ckey)
		unclaim_bed()
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

	// Show ownership status
	if(owner_ckey)
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			if(owner_ckey == H.ckey)
				. += span_notice("This is your sleeper.")
			else
				. += span_warning("This sleeper belongs to someone else.")
		else
			. += span_notice("This sleeper is claimed.")
	else
		. += span_notice("This sleeper is unclaimed. Enter and claim it in the stats menu.")

	// Show room type
	var/area/resurgence_outpost/room/room = get_area(src)
	if(istype(room))
		if(room.room_type == ROOM_TYPE_LIVING_QUARTERS)
			. += span_notice("Located in Living Quarters (faith bonus when claimed).")
		else if(room.room_type == ROOM_TYPE_BARRACKS)
			. += span_notice("Located in Barracks (no faith penalty).")

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
	// Close the UI for the occupant before ejecting
	SStgui.close_uis(src, M)
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
		// Check and open stats UI
		check_and_open_stats(occupant)

/// Check if stats UI can be shown and open it
/obj/structure/resurgence_bed/proc/check_and_open_stats(mob/living/carbon/human/H)
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		to_chat(H, span_warning("You have no resurgence core to view stats."))
		return

	// Grant Acceleration Protocol action if researched and not yet granted
	if(!core.acceleration_action_granted && GLOB.resurgence_research.is_researched("acceleration_protocol"))
		core.grant_acceleration_action()

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
		// Close the UI for the occupant
		SStgui.close_uis(src, gone)
		occupant = null
		update_icon_state()

/obj/structure/resurgence_bed/relaymove(mob/living/user, direction)
	if(!state_open)
		container_resist_act(user)

// ============================================
// Bed Ownership System
// ============================================

/// Claim this bed for a player
/obj/structure/resurgence_bed/proc/claim_bed(ckey)
	if(!ckey)
		return FALSE

	// Check if bed is in a valid room type
	var/area/resurgence_outpost/room/room = get_area(src)
	if(!istype(room))
		return FALSE

	if(room.room_type != ROOM_TYPE_LIVING_QUARTERS && room.room_type != ROOM_TYPE_BARRACKS)
		return FALSE

	// If already owned by this player, no change needed
	if(owner_ckey == ckey)
		return TRUE

	// Unclaim any previously owned bed by this player
	var/obj/structure/resurgence_bed/old_bed = GLOB.resurgence_bed_owners[ckey]
	if(old_bed && !QDELETED(old_bed) && old_bed != src)
		old_bed.unclaim_bed(silent = TRUE)

	// If this bed is owned by someone else, they lose it
	if(owner_ckey && owner_ckey != ckey)
		unclaim_bed(silent = TRUE)

	// Set new owner
	owner_ckey = ckey
	GLOB.resurgence_bed_owners[ckey] = src

	// Update faith event based on room type
	update_owner_faith_event()
	return TRUE

/// Remove ownership from this bed
/obj/structure/resurgence_bed/proc/unclaim_bed(silent = FALSE)
	if(!owner_ckey)
		return FALSE

	var/old_ckey = owner_ckey
	GLOB.resurgence_bed_owners -= owner_ckey
	owner_ckey = null

	// Apply homeless penalty unless silent (for when claiming new bed)
	if(!silent)
		apply_homeless_faith_event(old_ckey)
	return TRUE

/// Update the bed owner's faith event based on room type
/obj/structure/resurgence_bed/proc/update_owner_faith_event()
	if(!owner_ckey)
		return

	var/obj/item/organ/resurgence_core/core = get_resurgence_core_by_ckey(owner_ckey)
	if(!core)
		return

	var/area/resurgence_outpost/room/room = get_area(src)
	if(!istype(room))
		return

	if(room.room_type == ROOM_TYPE_LIVING_QUARTERS)
		// Living quarters gives faith bonus
		var/datum/faith_event/room_ownership/event = new(
			"You have a personal sleeper.",
			0.5, // +0.5 per tick (every 5 seconds)
			null, // permanent until lost
			"room_ownership"
		)
		core.add_faith_event("room_ownership", event)
	else if(room.room_type == ROOM_TYPE_BARRACKS)
		// Barracks just removes homeless penalty, no bonus
		core.clear_faith_event("room_ownership")

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

	// Current page (1 = overview, 2-5 = individual stats)
	data["current_page"] = 1

	// Bed ownership info
	data["bed_owner"] = owner_ckey
	data["is_owner"] = (owner_ckey == H.ckey)
	data["can_claim"] = can_player_claim(H)

	// Room type info
	var/area/resurgence_outpost/room/room = get_area(src)
	if(istype(room))
		data["room_type"] = room.room_type
		data["in_valid_room"] = (room.room_type == ROOM_TYPE_LIVING_QUARTERS || room.room_type == ROOM_TYPE_BARRACKS)
	else
		data["room_type"] = "Outdoors"
		data["in_valid_room"] = FALSE

	// Crafting stat
	data["crafting_level"] = core.stat_crafting
	data["crafting_xp"] = core.xp_crafting
	data["crafting_xp_needed"] = get_xp_for_level(core.stat_crafting)
	data["crafting_work_bonus"] = (core.stat_crafting - 1) * 0.5
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

	// Analysis stat
	data["analysis_level"] = core.stat_analysis
	data["analysis_xp"] = core.xp_analysis
	data["analysis_xp_needed"] = get_xp_for_level(core.stat_analysis)

	// Social stat
	data["social_level"] = core.stat_social
	data["social_xp"] = core.xp_social
	data["social_xp_needed"] = get_xp_for_level(core.stat_social)

	// Active events
	if(GLOB.resurgence_events)
		data["active_events"] = GLOB.resurgence_events.get_active_events_data()
	else
		data["active_events"] = list()

	return data

/obj/structure/resurgence_bed/ui_static_data(mob/user)
	var/list/data = list()
	data["max_level"] = STAT_MAX_LEVEL
	return data

/obj/structure/resurgence_bed/ui_act(action, params)
	. = ..()
	if(.)
		return

	if(!occupant || !ishuman(occupant))
		return FALSE

	var/mob/living/carbon/human/H = occupant

	switch(action)
		if("claim_bed")
			if(!can_player_claim(H))
				to_chat(H, span_warning("You cannot claim this sleeper."))
				return FALSE
			if(claim_bed(H.ckey))
				to_chat(H, span_notice("You claim this sleeper as your own."))
				return TRUE
			return FALSE

		if("unclaim_bed")
			if(owner_ckey != H.ckey)
				to_chat(H, span_warning("This is not your sleeper."))
				return FALSE
			if(unclaim_bed())
				to_chat(H, span_notice("You give up ownership of this sleeper."))
				return TRUE
			return FALSE

	return FALSE

/// Check if a player can claim this bed
/obj/structure/resurgence_bed/proc/can_player_claim(mob/living/carbon/human/H)
	if(!istype(H))
		return FALSE

	// Must have resurgence core
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		return FALSE

	// Must be in valid room type
	var/area/resurgence_outpost/room/room = get_area(src)
	if(!istype(room))
		return FALSE

	if(room.room_type != ROOM_TYPE_LIVING_QUARTERS && room.room_type != ROOM_TYPE_BARRACKS)
		return FALSE

	// If already owned by this player, they can't claim again
	if(owner_ckey == H.ckey)
		return FALSE

	return TRUE
