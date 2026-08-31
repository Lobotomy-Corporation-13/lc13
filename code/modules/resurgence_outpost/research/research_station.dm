/**
 * Resurgence Outpost - Research Station
 *
 * Interactive structure for viewing and researching tech tree nodes.
 * Uses a work-based system similar to crafting tables.
 *
 * Analysis Stat Effects:
 * - Session time: Base 5s, -1s every 5 levels (1s at level 20)
 * - Work per session: Base 5, +1 per level after 1 (24 at level 20)
 */

/// Base session time in seconds
#define RESEARCH_BASE_SESSION_TIME 5
/// Base work points per session
#define RESEARCH_BASE_WORK_PER_SESSION 5
/// Faith cost per research session
#define RESEARCH_FAITH_PER_SESSION 2
/// XP awarded per research session
#define RESEARCH_XP_PER_SESSION 5

/obj/structure/resurgence_research_station
	name = "research station"
	desc = "A mystical altar for channeling faith into knowledge. Use this to unlock new recipes and blueprints. Works best in a workshop."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "minibar"
	density = TRUE
	anchored = TRUE

	/// Whether someone is currently researching
	var/busy = FALSE
	/// The node ID this station is currently targeting
	var/target_node_id = null
	/// Whether this station requires a workshop for full efficiency
	var/requires_workshop = TRUE
	/// Time multiplier when outside a workshop
	var/outdoor_penalty = 3

/obj/structure/resurgence_research_station/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	ui_interact(user)
	return TRUE

/// Get session time based on analysis stat and workshop location
/// Base 5s, -1s every 5 levels, minimum 1s at level 20
/// Time is multiplied by outdoor_penalty when not in a workshop
/obj/structure/resurgence_research_station/proc/get_session_time(mob/user)
	var/base_time = RESEARCH_BASE_SESSION_TIME
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			var/level = core.stat_analysis
			var/reduction = floor(level / 5)
			base_time = max(1, RESEARCH_BASE_SESSION_TIME - reduction)

	// Apply workshop penalty if required
	if(requires_workshop && !is_in_workshop(src))
		base_time *= outdoor_penalty

	return base_time SECONDS

/// Check if this station is operating at reduced efficiency (not in workshop)
/obj/structure/resurgence_research_station/proc/is_at_reduced_efficiency()
	if(!requires_workshop)
		return FALSE
	return !is_in_workshop(src)

/// Get work per session based on analysis stat
/// Base 5, +1 per level after 1
/obj/structure/resurgence_research_station/proc/get_work_per_session(mob/user)
	var/base_work = RESEARCH_BASE_WORK_PER_SESSION
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			var/level = core.stat_analysis
			base_work = RESEARCH_BASE_WORK_PER_SESSION + (level - 1)
	return base_work

// ===== TGUI Interface =====

/obj/structure/resurgence_research_station/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ResurgenceResearch", "Resurgence Research")
		ui.open()

/obj/structure/resurgence_research_station/ui_data(mob/user)
	var/list/data = list()

	// Get player's current faith and analysis stat
	var/current_faith = 0
	var/analysis_level = 1
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			current_faith = round(core.faith)
			analysis_level = core.stat_analysis
	data["current_faith"] = current_faith
	data["analysis_level"] = analysis_level

	// Calculate current session values based on analysis stat
	var/work_per_session = get_work_per_session(user)
	var/session_time = get_session_time(user) / 10  // Convert to seconds
	data["work_per_session"] = work_per_session
	data["session_time"] = session_time

	// Busy state
	data["busy"] = busy

	// Workshop efficiency
	data["in_workshop"] = is_in_workshop(src)
	data["reduced_efficiency"] = is_at_reduced_efficiency()
	data["outdoor_penalty"] = outdoor_penalty

	// Current research target for this station
	data["has_research_in_progress"] = !!target_node_id

	if(target_node_id)
		var/datum/resurgence_research_node/current = GLOB.resurgence_research.all_nodes[target_node_id]
		if(current)
			var/current_progress = GLOB.resurgence_research.get_progress(target_node_id)
			data["current_research_id"] = target_node_id
			data["current_research_name"] = current.name
			data["current_work"] = current_progress
			data["total_work"] = current.total_work
			var/progress_pct = round((current_progress / current.total_work) * 100)
			data["progress_percent"] = progress_pct

	// Get all nodes with their research status
	var/list/nodes = list()
	for(var/node_id in GLOB.resurgence_research.all_nodes)
		var/datum/resurgence_research_node/node = GLOB.resurgence_research.all_nodes[node_id]
		var/is_researched = GLOB.resurgence_research.is_researched(node_id)
		var/can_research = GLOB.resurgence_research.can_research(node_id)
		var/node_progress = GLOB.resurgence_research.get_progress(node_id)

		// Calculate faith cost based on player's work per session
		var/remaining_work = node.total_work - node_progress
		var/sessions_needed = ceil(remaining_work / work_per_session)
		var/faith_cost = sessions_needed * RESEARCH_FAITH_PER_SESSION

		nodes += list(list(
			"id" = node.id,
			"name" = node.name,
			"desc" = node.desc,
			"tier" = node.tier,
			"total_work" = node.total_work,
			"current_work" = node_progress,
			"faith_cost" = faith_cost,
			"prerequisites" = node.prerequisites.Copy(),
			"unlocks_desc" = node.unlocks_desc,
			"x" = node.ui_x,
			"y" = node.ui_y,
			"is_researched" = is_researched,
			"can_research" = can_research,
			"can_afford" = (current_faith >= RESEARCH_FAITH_PER_SESSION),
			"branch_types" = node.branch_types
		))
	data["nodes"] = nodes

	// List of researched node IDs for line coloring
	data["researched_nodes"] = GLOB.resurgence_research.researched_nodes.Copy()

	return data

/obj/structure/resurgence_research_station/ui_static_data(mob/user)
	var/list/data = list()
	data["node_width"] = 140
	data["node_height"] = 70
	data["faith_per_session"] = RESEARCH_FAITH_PER_SESSION
	return data

/obj/structure/resurgence_research_station/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("start_research")
			var/node_id = params["node"]
			if(!node_id)
				return FALSE

			if(!GLOB.resurgence_research.can_research(node_id))
				to_chat(usr, span_warning("Cannot research this node!"))
				return FALSE

			var/datum/resurgence_research_node/node = GLOB.resurgence_research.all_nodes[node_id]
			if(!node)
				return FALSE

			target_node_id = node_id
			if(!GLOB.resurgence_research.research_progress[node_id])
				GLOB.resurgence_research.research_progress[node_id] = 0
			to_chat(usr, span_notice("This station is now targeting [node.name]."))
			return TRUE

		if("continue_research")
			if(busy)
				to_chat(usr, span_warning("Already researching!"))
				return FALSE

			if(!target_node_id)
				to_chat(usr, span_warning("No research target set!"))
				return FALSE

			do_research_work(usr)
			return TRUE

		if("cancel_research")
			if(busy)
				to_chat(usr, span_warning("Wait for current session to finish!"))
				return FALSE

			if(target_node_id)
				var/datum/resurgence_research_node/node = GLOB.resurgence_research.all_nodes[target_node_id]
				if(node)
					to_chat(usr, span_notice("Stopped targeting [node.name]. Progress saved."))
				target_node_id = null
			return TRUE

	return FALSE

/// Perform research work sessions until interrupted or complete
/obj/structure/resurgence_research_station/proc/do_research_work(mob/user)
	if(busy)
		return

	if(!target_node_id)
		to_chat(user, span_warning("No research target set!"))
		return

	// Check if user has a resurgence core
	if(!ishuman(user))
		return

	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		to_chat(user, span_warning("You need a resurgence core to research!"))
		return

	busy = TRUE

	// Research loop - continues until complete, out of faith, or interrupted
	while(target_node_id)
		// Check if already completed by another station
		if(GLOB.resurgence_research.is_researched(target_node_id))
			to_chat(user, span_notice("This research has already been completed!"))
			target_node_id = null
			break

		// Check faith
		if(core.faith < RESEARCH_FAITH_PER_SESSION)
			to_chat(user, span_warning("Not enough faith! Need [RESEARCH_FAITH_PER_SESSION] faith per session."))
			break

		// Get current node info for messages
		var/datum/resurgence_research_node/node = GLOB.resurgence_research.all_nodes[target_node_id]
		if(!node)
			break

		// Calculate session values based on current analysis stat
		var/session_time = get_session_time(user)
		var/work_amount = get_work_per_session(user)

		// Do work with progress bar
		if(!do_after(user, session_time, src))
			to_chat(user, span_notice("Research interrupted."))
			break

		// Consume faith
		core.adjust_faith(-RESEARCH_FAITH_PER_SESSION)

		// Award analysis XP
		core.award_xp("analysis", RESEARCH_XP_PER_SESSION)

		// Add work
		var/completed = GLOB.resurgence_research.add_research_work(target_node_id, work_amount, user)

		if(completed)
			playsound(src, 'sound/effects/magic.ogg', 50, TRUE)
			target_node_id = null
			break
		else
			// Play work sound
			playsound(src, 'sound/items/deconstruct.ogg', 30, TRUE)

		// Update UI
		SStgui.update_uis(src)

	busy = FALSE
	SStgui.update_uis(src)

/obj/structure/resurgence_research_station/examine(mob/user)
	. = ..()
	. += span_notice("Click to open the research tree.")

	// Workshop status
	if(requires_workshop)
		if(is_in_workshop(src))
			. += span_notice("Operating at full efficiency (in workshop).")
		else
			. += span_warning("Operating at reduced efficiency! Place in a workshop for [outdoor_penalty]x faster research.")

	var/researched_count = length(GLOB.resurgence_research.researched_nodes)
	var/total_count = length(GLOB.resurgence_research.all_nodes)
	. += span_notice("[researched_count]/[total_count] technologies researched.")

	if(target_node_id)
		var/datum/resurgence_research_node/node = GLOB.resurgence_research.all_nodes[target_node_id]
		if(node)
			var/progress = GLOB.resurgence_research.get_progress(node.id)
			. += span_notice("Targeting: [node.name] ([progress]/[node.total_work] work)")

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			. += span_notice("Your faith: [round(core.faith)]")
			. += span_notice("Analysis skill: Level [core.stat_analysis]")
			var/session_time = get_session_time(user) / 10
			var/work_amount = get_work_per_session(user)
			. += span_notice("Research speed: [work_amount] work per [session_time]s")

#undef RESEARCH_BASE_SESSION_TIME
#undef RESEARCH_BASE_WORK_PER_SESSION
#undef RESEARCH_FAITH_PER_SESSION
#undef RESEARCH_XP_PER_SESSION
