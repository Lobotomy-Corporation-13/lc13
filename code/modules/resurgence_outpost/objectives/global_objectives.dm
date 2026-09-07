/**
 * Resurgence Outpost - Global Objectives System
 *
 * Manages global objectives that all players work towards.
 * Phase 1: Building objectives (rooms, farming zones)
 * Phase 2: Exploration objectives (world map, expeditions, factions)
 */

/// Global list of all active objectives
GLOBAL_LIST_EMPTY(resurgence_objectives)

/// Current objective phase (1 = building, 2 = exploration)
GLOBAL_VAR_INIT(resurgence_objective_phase, 1)

/// Total exported amounts (type path -> count)
GLOBAL_LIST_EMPTY(resurgence_exported_totals)

/// Total completed expeditions counter
GLOBAL_VAR_INIT(resurgence_completed_expeditions, 0)

/// Total weapons crafted via grid crafting
GLOBAL_VAR_INIT(resurgence_weapons_crafted, 0)

/// Total custom outfits crafted via loom
GLOBAL_VAR_INIT(resurgence_outfits_crafted, 0)

/// Total faction hubs visited
GLOBAL_LIST_EMPTY(resurgence_visited_faction_hubs)

/// Total caravan encounters
GLOBAL_VAR_INIT(resurgence_caravan_encounters, 0)

/// Total caravan trades completed
GLOBAL_VAR_INIT(resurgence_caravan_trades, 0)

/// Objective categories
#define OBJECTIVE_CAT_BUILDING "building"
#define OBJECTIVE_CAT_EXPLORATION "exploration"
#define OBJECTIVE_CAT_EXPORT "export"
#define OBJECTIVE_CAT_TRADING "trading"

/**
 * Base objective datum
 */
/datum/resurgence_objective
	/// Display name
	var/name = "Objective"
	/// Detailed description
	var/description = ""
	/// Category: "building", "exploration", or "trading"
	var/category = OBJECTIVE_CAT_BUILDING
	/// Whether this objective is complete
	var/completed = FALSE
	/// Current progress value
	var/current_progress = 0
	/// Required progress to complete
	var/required_progress = 1
	/// Order for display (lower = first)
	var/sort_order = 0
	/// Which phase this objective requires (1 or 2)
	var/required_phase = 1

/// Check if this objective is currently available (phase unlocked)
/datum/resurgence_objective/proc/is_available()
	return GLOB.resurgence_objective_phase >= required_phase

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

/// Advance to Phase 2 (Export objectives) - with 10 second delay
/proc/advance_to_phase_two()
	// Notify all resurgence machines about the upcoming phase change
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(!H.mind)
			continue
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(!istype(core))
			continue
		to_chat(H, span_notice("<b>All building objectives complete!</b> Phase 2 will begin in 10 seconds..."))

	// Schedule the actual phase change after 10 seconds
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(do_phase_two_transition)), 10 SECONDS)

/// Actually transition to phase 2 (called after delay)
/proc/do_phase_two_transition()
	GLOB.resurgence_objective_phase = 2

	// Announce phase 2 start
	var/blurb = "PHASE 2 UNLOCKED: BEGIN RESOURCE EXPORTS"
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(show_global_blurb), 5 SECONDS, blurb, 1 SECONDS, "dark gray", "gold", "left", "CENTER,BOTTOM+2")

	// Notify all resurgence machines
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(!H.mind)
			continue
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(!istype(core))
			continue
		to_chat(H, span_notice("<b>PHASE 2 STARTED!</b> The Export Warehouse is now operational. Begin exporting resources to the Historian's village."))

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
// RESEARCH & CRAFTING OBJECTIVES (Phase 1)
// ============================================

/// Research Grid Crafting
/datum/resurgence_objective/building/research_grid_crafting
	name = "Research Grid Crafting"
	description = "Research Weapon Grid Navigation at the Research Station."
	required_progress = 1
	sort_order = 6

/datum/resurgence_objective/building/research_grid_crafting/check_progress()
	if(GLOB.resurgence_research?.is_researched("grid_crafting"))
		current_progress = 1
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

/// Research Faith Weaving
/datum/resurgence_objective/building/research_faith_weaving
	name = "Research Faith Weaving"
	description = "Research Faith Weaving at the Research Station."
	required_progress = 1
	sort_order = 7

/datum/resurgence_objective/building/research_faith_weaving/check_progress()
	if(GLOB.resurgence_research?.is_researched("faith_weaving"))
		current_progress = 1
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

/// Craft 4 weapons via grid crafting
/datum/resurgence_objective/building/craft_weapons
	name = "Craft 4 Weapons"
	description = "Use the Grid Crafting Station to craft 4 city weapons."
	required_progress = 4
	sort_order = 8

/datum/resurgence_objective/building/craft_weapons/check_progress()
	current_progress = GLOB.resurgence_weapons_crafted
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

/// Craft 4 custom outfits via loom
/datum/resurgence_objective/building/craft_outfits
	name = "Craft 4 Custom Outfits"
	description = "Use the Loom to craft 4 custom clothing items."
	required_progress = 4
	sort_order = 9

/datum/resurgence_objective/building/craft_outfits/check_progress()
	current_progress = GLOB.resurgence_outfits_crafted
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

// ============================================
// EXPORT OBJECTIVES (Phase 2)
// ============================================

/datum/resurgence_objective/export
	category = OBJECTIVE_CAT_EXPORT
	required_phase = 2
	/// The type path of items that count for this objective
	var/export_type = null

/// Update progress from exported totals
/datum/resurgence_objective/export/check_progress()
	if(!is_available())
		return FALSE
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
// EXPLORATION OBJECTIVES (Phase 2)
// ============================================

/datum/resurgence_objective/exploration
	category = OBJECTIVE_CAT_EXPLORATION
	required_phase = 2

/// Discover 50% of the world map
/datum/resurgence_objective/exploration/discover_map
	name = "Discover 50% of the World"
	description = "Explore and discover at least half of the world map tiles."
	required_progress = 50  // Percentage
	sort_order = 15

/datum/resurgence_objective/exploration/discover_map/check_progress()
	if(!is_available())
		return FALSE
	if(GLOB.resurgence_world_map)
		var/total_tiles = GLOB.resurgence_world_map.map_width * GLOB.resurgence_world_map.map_height
		var/discovered = 0
		for(var/x in 1 to GLOB.resurgence_world_map.map_width)
			for(var/y in 1 to GLOB.resurgence_world_map.map_height)
				var/datum/world_tile/tile = GLOB.resurgence_world_map.tiles[x][y]
				if(tile?.discovered)
					discovered++
		current_progress = round((discovered / total_tiles) * 100)
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

/// Complete 5 expeditions
/datum/resurgence_objective/exploration/complete_expeditions
	name = "Complete 5 Expeditions"
	description = "Successfully complete 5 expeditions into the world."
	required_progress = 5
	sort_order = 16

/datum/resurgence_objective/exploration/complete_expeditions/check_progress()
	if(!is_available())
		return FALSE
	current_progress = GLOB.resurgence_completed_expeditions
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

/// Visit all 4 faction hubs
/datum/resurgence_objective/exploration/visit_factions
	name = "Visit All Faction Hubs"
	description = "Travel to and visit all 4 faction hub settlements."
	required_progress = 4
	sort_order = 17

/datum/resurgence_objective/exploration/visit_factions/check_progress()
	if(!is_available())
		return FALSE
	current_progress = length(GLOB.resurgence_visited_faction_hubs)
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

/// Encounter caravans on the world map
/datum/resurgence_objective/exploration/encounter_caravans
	name = "Encounter 5 Caravans"
	description = "Meet and interact with 5 caravans while exploring the world."
	required_progress = 5
	sort_order = 18

/datum/resurgence_objective/exploration/encounter_caravans/check_progress()
	if(!is_available())
		return FALSE
	current_progress = GLOB.resurgence_caravan_encounters
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

/// Trade with caravans
/datum/resurgence_objective/exploration/trade_caravans
	name = "Trade with 3 Caravans"
	description = "Successfully complete trades with 3 different caravans."
	required_progress = 3
	sort_order = 19

/datum/resurgence_objective/exploration/trade_caravans/check_progress()
	if(!is_available())
		return FALSE
	current_progress = GLOB.resurgence_caravan_trades
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

// ============================================
// TRADING OBJECTIVES
// ============================================

/datum/resurgence_objective/trading
	category = OBJECTIVE_CAT_TRADING

/// Discover all trading factions
/datum/resurgence_objective/trading/discover_factions
	name = "Discover All Factions"
	description = "Connect to each nearby faction for the first time to learn who your neighbors are."
	required_progress = 4  // 4 discoverable factions (excluding Resurgence Clan which starts discovered)
	sort_order = 20

/datum/resurgence_objective/trading/discover_factions/check_progress()
	current_progress = 0
	if(GLOB.resurgence_trading)
		for(var/datum/trading_faction/F in GLOB.resurgence_trading.factions)
			if(F.discovered && F.id != "resurgence_clan")  // Don't count the starting faction
				current_progress++
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

/// Earn credits through trading
/datum/resurgence_objective/trading/earn_credits
	name = "Earn 1000 Credits"
	description = "Earn a total of 1000 credits by selling goods to trading factions."
	required_progress = 1000
	sort_order = 21
	/// Track total earned (separate from current balance)
	var/static/total_earned = 0

/datum/resurgence_objective/trading/earn_credits/check_progress()
	current_progress = total_earned
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

/// Reach Friendly status with any faction
/datum/resurgence_objective/trading/friendly_reputation
	name = "Befriend a Faction"
	description = "Reach Friendly reputation (60+) with any trading faction through trade."
	required_progress = 1
	sort_order = 22

/datum/resurgence_objective/trading/friendly_reputation/check_progress()
	current_progress = 0
	if(GLOB.resurgence_trading)
		for(var/datum/trading_faction/F in GLOB.resurgence_trading.factions)
			// Don't count Resurgence Clan since they start friendly
			if(F.id == "resurgence_clan")
				continue
			if(F.reputation >= 60)
				current_progress = 1
				break
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

/// Reach Allied status with any faction
/datum/resurgence_objective/trading/allied_reputation
	name = "Forge an Alliance"
	description = "Reach Allied reputation (80+) with any trading faction through dedicated trade."
	required_progress = 1
	sort_order = 23

/datum/resurgence_objective/trading/allied_reputation/check_progress()
	current_progress = 0
	if(GLOB.resurgence_trading)
		for(var/datum/trading_faction/F in GLOB.resurgence_trading.factions)
			// Don't count Resurgence Clan
			if(F.id == "resurgence_clan")
				continue
			if(F.reputation >= 80)
				current_progress = 1
				break
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

/// Make a large purchase
/datum/resurgence_objective/trading/big_spender
	name = "Big Spender"
	description = "Spend 500 credits or more in a single purchase from a faction."
	required_progress = 1
	sort_order = 24
	/// Whether the objective has been triggered
	var/static/triggered = FALSE

/datum/resurgence_objective/trading/big_spender/check_progress()
	if(triggered)
		current_progress = 1
	if(current_progress >= required_progress && !completed)
		on_complete()
	return ..()

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
	GLOB.resurgence_completed_expeditions = 0
	GLOB.resurgence_visited_faction_hubs.Cut()
	GLOB.resurgence_caravan_encounters = 0
	GLOB.resurgence_caravan_trades = 0
	GLOB.resurgence_weapons_crafted = 0
	GLOB.resurgence_outfits_crafted = 0

	// Create building objectives (Phase 1)
	new /datum/resurgence_objective/building/living_quarters()
	new /datum/resurgence_objective/building/workshop()
	new /datum/resurgence_objective/building/kitchen()
	new /datum/resurgence_objective/building/farming_zones()
	new /datum/resurgence_objective/building/export_warehouse()
	new /datum/resurgence_objective/building/research_grid_crafting()
	new /datum/resurgence_objective/building/research_faith_weaving()
	new /datum/resurgence_objective/building/craft_weapons()
	new /datum/resurgence_objective/building/craft_outfits()

	// Create exploration objectives (Phase 2)
	new /datum/resurgence_objective/exploration/discover_map()
	new /datum/resurgence_objective/exploration/complete_expeditions()
	new /datum/resurgence_objective/exploration/visit_factions()
	new /datum/resurgence_objective/exploration/encounter_caravans()
	new /datum/resurgence_objective/exploration/trade_caravans()

	// Create export objectives (Phase 2)
	new /datum/resurgence_objective/export/metal()
	new /datum/resurgence_objective/export/wood()
	new /datum/resurgence_objective/export/harvesters()
	new /datum/resurgence_objective/export/gold()
	new /datum/resurgence_objective/export/cloth()

	// Create trading objectives
	new /datum/resurgence_objective/trading/discover_factions()
	new /datum/resurgence_objective/trading/earn_credits()
	new /datum/resurgence_objective/trading/friendly_reputation()
	new /datum/resurgence_objective/trading/allied_reputation()
	new /datum/resurgence_objective/trading/big_spender()

	// Reset trading objective static vars
	/datum/resurgence_objective/trading/earn_credits::total_earned = 0
	/datum/resurgence_objective/trading/big_spender::triggered = FALSE

/// Update all objective progress - called when relevant things change
/proc/update_all_objectives()
	for(var/datum/resurgence_objective/obj in GLOB.resurgence_objectives)
		obj.check_progress()

/// Add exported resources to totals and check objectives
/proc/add_exported_resources(type_path, amount)
	// Find which objective(s) this item type contributes to using ispath
	// Store under the objective's export_type (base type) for proper tracking
	var/matched_any = FALSE
	for(var/datum/resurgence_objective/export/obj in GLOB.resurgence_objectives)
		if(ispath(type_path, obj.export_type))
			// Store under the objective's base export type
			if(!GLOB.resurgence_exported_totals[obj.export_type])
				GLOB.resurgence_exported_totals[obj.export_type] = 0
			GLOB.resurgence_exported_totals[obj.export_type] += amount
			obj.check_progress()
			matched_any = TRUE

	// If no objective matched, still track it (for potential future objectives)
	if(!matched_any)
		if(!GLOB.resurgence_exported_totals[type_path])
			GLOB.resurgence_exported_totals[type_path] = 0
		GLOB.resurgence_exported_totals[type_path] += amount

/// Get objectives grouped by category for display
/proc/get_objectives_by_category()
	var/list/result = list(
		OBJECTIVE_CAT_BUILDING = list(),
		OBJECTIVE_CAT_EXPLORATION = list(),
		OBJECTIVE_CAT_EXPORT = list(),
		OBJECTIVE_CAT_TRADING = list()
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

// ============================================
// Admin Verbs
// ============================================

/// Admin verb to initialize objectives for testing
/client/proc/init_resurgence_objectives()
	set name = "Initialize Resurgence Objectives"
	set category = "Debug"

	if(!check_rights(R_DEBUG))
		return

	initialize_resurgence_objectives()
	to_chat(src, span_notice("Resurgence objectives have been initialized."))
	message_admins("[key_name(src)] initialized resurgence objectives.")

/// Admin verb to complete a building objective for testing
/client/proc/complete_building_objective()
	set name = "Complete Building Objective"
	set category = "Debug"

	if(!check_rights(R_DEBUG))
		return

	var/list/incomplete = list()
	for(var/datum/resurgence_objective/obj in GLOB.resurgence_objectives)
		if(obj.category == "building" && !obj.completed)
			incomplete += obj.name

	if(!length(incomplete))
		to_chat(src, span_warning("No incomplete building objectives."))
		return

	var/choice = input(src, "Select objective to complete:", "Complete Objective") as null|anything in incomplete
	if(!choice)
		return

	for(var/datum/resurgence_objective/obj in GLOB.resurgence_objectives)
		if(obj.name == choice)
			obj.current_progress = obj.required_progress
			obj.on_complete()
			to_chat(src, span_notice("Completed objective: [obj.name]"))
			message_admins("[key_name(src)] completed resurgence objective: [obj.name]")
			break

/// Called when credits are earned from selling to a faction
/proc/on_trading_credits_earned(amount)
	/datum/resurgence_objective/trading/earn_credits::total_earned += amount
	update_all_objectives()

/// Called when a purchase is made from a faction
/proc/on_trading_purchase_made(amount)
	if(amount >= 500)
		/datum/resurgence_objective/trading/big_spender::triggered = TRUE
	update_all_objectives()

/// Called when a faction is discovered (first connection)
/proc/on_faction_discovered()
	update_all_objectives()

/// Called when an expedition is completed successfully
/proc/on_expedition_completed()
	GLOB.resurgence_completed_expeditions++
	update_all_objectives()

/// Called when a faction hub is visited
/proc/on_faction_hub_visited(faction_id)
	if(!(faction_id in GLOB.resurgence_visited_faction_hubs))
		GLOB.resurgence_visited_faction_hubs += faction_id
	update_all_objectives()

/// Called when a caravan is encountered
/proc/on_caravan_encountered()
	GLOB.resurgence_caravan_encounters++
	update_all_objectives()

/// Called when a caravan trade is completed
/proc/on_caravan_trade_completed()
	GLOB.resurgence_caravan_trades++
	update_all_objectives()

#undef OBJECTIVE_CAT_BUILDING
#undef OBJECTIVE_CAT_EXPLORATION
#undef OBJECTIVE_CAT_EXPORT
#undef OBJECTIVE_CAT_TRADING
