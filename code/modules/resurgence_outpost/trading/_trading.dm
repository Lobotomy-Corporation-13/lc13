/**
 * Resurgence Outpost - Trading System
 *
 * Global definitions and manager for the faction trading system.
 * Players can trade with external factions via a Comms Console.
 */

GLOBAL_DATUM_INIT(resurgence_trading, /datum/resurgence_trading_manager, new)

/// Global credits pool for the outpost
GLOBAL_VAR_INIT(resurgence_credits, 0)

// ==================== Trading Manager ====================

/datum/resurgence_trading_manager
	/// All active factions
	var/list/factions = list()

	/// Currently connected faction (for UI state)
	var/datum/trading_faction/connected_faction = null

/datum/resurgence_trading_manager/New()
	. = ..()
	initialize_factions()
	// Start the regeneration loop (runs every 5 minutes)
	start_regeneration_loop()

/// Start the periodic regeneration timer
/datum/resurgence_trading_manager/proc/start_regeneration_loop()
	// Process every 5 minutes (3000 deciseconds)
	addtimer(CALLBACK(src, PROC_REF(regeneration_tick)), 5 MINUTES)

/// Called by the regeneration timer
/datum/resurgence_trading_manager/proc/regeneration_tick()
	process_regeneration()
	// Schedule the next tick
	addtimer(CALLBACK(src, PROC_REF(regeneration_tick)), 5 MINUTES)

/// Initialize all pre-made factions
/datum/resurgence_trading_manager/proc/initialize_factions()
	factions += new /datum/trading_faction/resurgence_clan()
	factions += new /datum/trading_faction/jiajia_ren()
	factions += new /datum/trading_faction/santata_factory()
	factions += new /datum/trading_faction/cloud_town()
	factions += new /datum/trading_faction/insurgence_clan()

	// Generate initial stock for trading factions
	for(var/datum/trading_faction/F in factions)
		if(F.can_trade)
			F.generate_stock()

/// Connect to a faction
/datum/resurgence_trading_manager/proc/connect_faction(faction_id)
	for(var/datum/trading_faction/F in factions)
		if(F.id == faction_id)
			connected_faction = F
			return TRUE
	return FALSE

/// Disconnect from current faction
/datum/resurgence_trading_manager/proc/disconnect_faction()
	connected_faction = null

/// Get a faction by ID
/datum/resurgence_trading_manager/proc/get_faction(faction_id)
	for(var/datum/trading_faction/F in factions)
		if(F.id == faction_id)
			return F
	return null

/// Add credits to the outpost pool
/datum/resurgence_trading_manager/proc/add_credits(amount)
	GLOB.resurgence_credits += amount

/// Remove credits from the outpost pool
/datum/resurgence_trading_manager/proc/remove_credits(amount)
	if(GLOB.resurgence_credits >= amount)
		GLOB.resurgence_credits -= amount
		return TRUE
	return FALSE

/// Process faction regeneration (called periodically)
/datum/resurgence_trading_manager/proc/process_regeneration()
	for(var/datum/trading_faction/F in factions)
		if(F.can_trade)
			F.regenerate_cash()
			F.regenerate_stock()
		// Process reputation decay for all factions
		F.process_reputation_decay()
