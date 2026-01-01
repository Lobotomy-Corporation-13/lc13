/**
 * Resurgence Outpost - Global Objectives System
 *
 * Manages global objectives that all players work towards.
 * Phase 1: Building objectives (rooms, farming zones)
 * Phase 2: Export objectives (resources back to the village)
 */

/// Global list of all active objectives
GLOBAL_LIST_EMPTY(resurgence_objectives)

/// Current objective phase (1 = building, 2 = exporting)
GLOBAL_VAR_INIT(resurgence_objective_phase, 1)

/// Total exported amounts (type path -> count)
GLOBAL_LIST_EMPTY(resurgence_exported_totals)

/// Objective categories
#define OBJECTIVE_CAT_BUILDING "building"
#define OBJECTIVE_CAT_EXPORT "export"

/**
 * Base objective datum
 */
/datum/resurgence_objective
	/// Display name
	var/name = "Objective"
	/// Detailed description
	var/description = ""
	/// Category: "building" or "export"
	var/category = OBJECTIVE_CAT_BUILDING
	/// Whether this objective is complete
	var/completed = FALSE
	/// Current progress value
	var/current_progress = 0
	/// Required progress to complete
	var/required_progress = 1
	/// Order for display (lower = first)
	var/sort_order = 0

/datum/resurgence_objective/New()
	. = ..()
	GLOB.resurgence_objectives += src

/datum/resurgence_objective/Destroy()
	GLOB.resurgence_objectives -= src
	return ..()

/// Check if objective requirements are met and update progress
/datum/resurgence_objective/proc/check_progress()
	// Override in subtypes
	return current_progress >= required_progress

/// Get display text for Core status
/datum/resurgence_objective/proc/get_display_text()
	if(required_progress > 1)
		return "[name] ([current_progress]/[required_progress])"
	return name

/// Called when objective completes
/datum/resurgence_objective/proc/on_complete()
	if(completed)
		return
	completed = TRUE

	// Show global blurb to all players
	var/blurb = "OBJECTIVE COMPLETE: [name]"
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(show_global_blurb), 5 SECONDS, blurb, 1 SECONDS, "dark gray", "light blue", "left", "CENTER,BOTTOM+2")

	// Give faith event to all resurgence machines
	give_completion_faith_event()

	// Check if all objectives in current phase are complete
	check_phase_completion()

/// Give a 5-minute faith bonus to all resurgence machines (+1 every 5 seconds)
/datum/resurgence_objective/proc/give_completion_faith_event()
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(!H.mind)
			continue
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(!istype(core))
			continue

		// Create faith event: +1 per tick for 5 minutes
		var/datum/faith_event/objective_completion/event = new(
			"Objective completed! The clan prospers.",
			1, // +1 per tick
			5 MINUTES,
			"objective_completion"
		)
		core.add_faith_event("objective_completion", event)

/// Check if all objectives in the current phase are complete
/proc/check_phase_completion()
	if(GLOB.resurgence_objective_phase == 1)
		// Check if all building objectives are complete
		var/all_complete = TRUE
		for(var/datum/resurgence_objective/obj in GLOB.resurgence_objectives)
			if(obj.category == OBJECTIVE_CAT_BUILDING && !obj.completed)
				all_complete = FALSE
				break

		if(all_complete)
			advance_to_phase_two()

/// Advance to Phase 2 (Export objectives)
/proc/advance_to_phase_two()
	GLOB.resurgence_objective_phase = 2

	// Announce phase change
	var/blurb = "PHASE 2 UNLOCKED: BEGIN RESOURCE EXPORTS"
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(show_global_blurb), 5 SECONDS, blurb, 1 SECONDS, "dark gray", "gold", "left", "CENTER,BOTTOM+2")

	// Notify all resurgence machines
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(!H.mind)
			continue
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(!istype(core))
			continue
		to_chat(H, span_notice("<b>All building objectives complete!</b> The Export Warehouse is now operational. Begin exporting resources to the Historian's village."))

// ============================================
// BUILDING OBJECTIVES
// ============================================

/datum/resurgence_objective/building
	category = OBJECTIVE_CAT_BUILDING

/// Build 5 Living Quarters
/datum/resurgence_objective/building/living_quarters
	name = "Build 5 Living Quarters"
	description = "Create 5 designated Living Quarters rooms with beds."
	required_progress = 5
	sort_order = 1

/datum/resurgence_objective/building/living_quarters/check_progress()
	current_progress = count_rooms_of_type(ROOM_TYPE_LIVING_QUARTERS)
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

/// Build a Workshop
/datum/resurgence_objective/building/workshop
	name = "Build a Workshop"
	description = "Create a designated Workshop room with a crafting station."
	required_progress = 1
	sort_order = 2

/datum/resurgence_objective/building/workshop/check_progress()
	current_progress = count_rooms_of_type(ROOM_TYPE_WORKSHOP)
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

/// Build a Kitchen
/datum/resurgence_objective/building/kitchen
	name = "Build a Kitchen"
	description = "Create a designated Kitchen room with cooking facilities."
	required_progress = 1
	sort_order = 3

/datum/resurgence_objective/building/kitchen/check_progress()
	current_progress = count_rooms_of_type(ROOM_TYPE_KITCHEN)
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

/// Create 2+ Farming Zones with 6+ tiles each
/datum/resurgence_objective/building/farming_zones
	name = "Create 2 Large Farming Zones"
	description = "Create at least 2 farming zones with 6 or more tiles each."
	required_progress = 2
	sort_order = 4

/datum/resurgence_objective/building/farming_zones/check_progress()
	current_progress = count_large_farm_zones(6) // Minimum 6 tiles
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

/// Build an Export Warehouse
/datum/resurgence_objective/building/export_warehouse
	name = "Build an Export Warehouse"
	description = "Create an Export Warehouse room with a Resources Recorder."
	required_progress = 1
	sort_order = 5

/datum/resurgence_objective/building/export_warehouse/check_progress()
	current_progress = count_rooms_of_type(ROOM_TYPE_EXPORT_WAREHOUSE)
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

// ============================================
// EXPORT OBJECTIVES
// ============================================

/datum/resurgence_objective/export
	category = OBJECTIVE_CAT_EXPORT
	/// The type path of items that count for this objective
	var/export_type = null

/// Update progress from exported totals
/datum/resurgence_objective/export/check_progress()
	if(export_type && GLOB.resurgence_exported_totals[export_type])
		current_progress = GLOB.resurgence_exported_totals[export_type]
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

/// Export Metal Sheets
/datum/resurgence_objective/export/metal
	name = "Export 50 Metal Sheets"
	description = "Send 50 metal sheets back to the Historian's village."
	required_progress = 50
	export_type = /obj/item/stack/sheet/metal
	sort_order = 10

/// Export Wood
/datum/resurgence_objective/export/wood
	name = "Export 100 Wood"
	description = "Send 100 wood back to the Historian's village."
	required_progress = 100
	export_type = /obj/item/stack/sheet/mineral/wood
	sort_order = 11

/// Export Harvesters
/datum/resurgence_objective/export/harvesters
	name = "Export 5 Harvesters"
	description = "Send 5 harvesters back to the Historian's village."
	required_progress = 5
	export_type = /obj/item/harvester
	sort_order = 12

/// Export Gold
/datum/resurgence_objective/export/gold
	name = "Export 25 Gold"
	description = "Send 25 gold back to the Historian's village."
	required_progress = 25
	export_type = /obj/item/stack/sheet/mineral/gold
	sort_order = 13

/// Export Cloth
/datum/resurgence_objective/export/cloth
	name = "Export 30 Cloth"
	description = "Send 30 cloth back to the Historian's village."
	required_progress = 30
	export_type = /obj/item/stack/sheet/cotton/cloth
	sort_order = 14

// ============================================
// HELPER PROCS
// ============================================

/// Count rooms of a specific type
/proc/count_rooms_of_type(room_type)
	var/count = 0
	for(var/area/resurgence_outpost/room/R in GLOB.sortedAreas)
		if(R.room_type == room_type)
			count++
	return count

/// Count farming zones with at least min_tiles
/proc/count_large_farm_zones(min_tiles)
	var/count = 0
	for(var/datum/farm_zone/zone in GLOB.resurgence_farm_zones)
		if(zone.plots.len >= min_tiles)
			count++
	return count

/// Initialize all objectives - called when gamemode starts
/proc/initialize_resurgence_objectives()
	// Clear existing objectives
	GLOB.resurgence_objectives.Cut()
	GLOB.resurgence_exported_totals.Cut()
	GLOB.resurgence_objective_phase = 1

	// Create building objectives
	new /datum/resurgence_objective/building/living_quarters()
	new /datum/resurgence_objective/building/workshop()
	new /datum/resurgence_objective/building/kitchen()
	new /datum/resurgence_objective/building/farming_zones()
	new /datum/resurgence_objective/building/export_warehouse()

	// Create export objectives
	new /datum/resurgence_objective/export/metal()
	new /datum/resurgence_objective/export/wood()
	new /datum/resurgence_objective/export/harvesters()
	new /datum/resurgence_objective/export/gold()
	new /datum/resurgence_objective/export/cloth()

/// Update all objective progress - called when relevant things change
/proc/update_all_objectives()
	for(var/datum/resurgence_objective/obj in GLOB.resurgence_objectives)
		obj.check_progress()

/// Add exported resources to totals and check objectives
/proc/add_exported_resources(type_path, amount)
	if(!GLOB.resurgence_exported_totals[type_path])
		GLOB.resurgence_exported_totals[type_path] = 0
	GLOB.resurgence_exported_totals[type_path] += amount

	// Update export objectives
	for(var/datum/resurgence_objective/export/obj in GLOB.resurgence_objectives)
		if(obj.export_type == type_path)
			obj.check_progress()

/// Get objectives grouped by category for display
/proc/get_objectives_by_category()
	var/list/result = list(
		OBJECTIVE_CAT_BUILDING = list(),
		OBJECTIVE_CAT_EXPORT = list()
	)

	// Sort objectives by sort_order
	var/list/sorted = sortTim(GLOB.resurgence_objectives.Copy(), GLOBAL_PROC_REF(cmp_objectives))

	for(var/datum/resurgence_objective/obj in sorted)
		result[obj.category] += obj

	return result

/// Comparison proc for sorting objectives
/proc/cmp_objectives(datum/resurgence_objective/a, datum/resurgence_objective/b)
	return a.sort_order - b.sort_order

/// Faith event subtype for objective completion
/datum/faith_event/objective_completion
	category = "objective_completion"

#undef OBJECTIVE_CAT_BUILDING
#undef OBJECTIVE_CAT_EXPORT
