// Faction Hub Controller
// Manages faction hub instances and player interactions

/// Global list of faction hub controllers by faction_id
GLOBAL_LIST_EMPTY(faction_hubs)

/// Hub trading discount (10% off when trading in person)
#define HUB_TRADING_DISCOUNT 0.9

/**
 * Faction Hub Controller
 *
 * Manages a single faction hub area, handling player arrival,
 * departure, trading bonuses, and hub-specific mechanics.
 */
/datum/faction_hub_controller
	/// The faction ID this hub serves
	var/faction_id
	/// Reference to the faction datum
	var/datum/trading_faction/faction
	/// The hub's spawn landmark
	var/obj/effect/landmark/faction_hub_spawn/spawn_point
	/// The hub's exit landmark
	var/obj/effect/landmark/faction_hub_exit/exit_point
	/// The hub's trader NPC
	var/mob/living/simple_animal/faction_trader/trader
	/// List of players currently in the hub
	var/list/mob/living/visitors = list()
	/// Z-level the hub is on (0 if not loaded)
	var/hub_z_level = 0
	/// Whether the hub has been initialized
	var/initialized = FALSE

/datum/faction_hub_controller/New(faction_type_id)
	. = ..()
	faction_id = faction_type_id
	GLOB.faction_hubs[faction_id] = src

/datum/faction_hub_controller/Destroy()
	GLOB.faction_hubs -= faction_id
	visitors = null
	spawn_point = null
	exit_point = null
	trader = null
	faction = null
	return ..()

/**
 * Initialize the hub by finding landmarks on its z-level
 */
/datum/faction_hub_controller/proc/initialize(z_level)
	if(initialized)
		return TRUE

	hub_z_level = z_level

	// Find the faction datum
	faction = GLOB.resurgence_trading?.get_faction(faction_id)
	if(!faction)
		log_game("Faction hub controller for [faction_id] could not find faction datum")
		return FALSE

	// Find landmarks on this z-level
	for(var/turf/T in block(locate(1, 1, z_level), locate(world.maxx, world.maxy, z_level)))
		for(var/obj/effect/landmark/L in T.contents)
			if(istype(L, /obj/effect/landmark/faction_hub_spawn))
				var/obj/effect/landmark/faction_hub_spawn/SP = L
				if(SP.faction_id == faction_id)
					spawn_point = SP
					SP.controller = src
			else if(istype(L, /obj/effect/landmark/faction_hub_exit))
				var/obj/effect/landmark/faction_hub_exit/EP = L
				if(EP.faction_id == faction_id)
					exit_point = EP
					EP.controller = src

	// Find trader NPC
	for(var/mob/living/simple_animal/faction_trader/T in GLOB.mob_list)
		if(T.faction_id == faction_id && T.z == z_level)
			trader = T
			T.controller = src
			break

	initialized = TRUE
	log_game("Faction hub [faction_id] initialized on z-level [z_level]")
	log_game("  - Spawn point: [spawn_point ? "FOUND" : "NOT FOUND"]")
	log_game("  - Exit point: [exit_point ? "FOUND" : "NOT FOUND"]")
	log_game("  - Trader: [trader ? "FOUND" : "NOT FOUND"]")

	return TRUE

/**
 * Handle a player arriving at the hub
 */
/datum/faction_hub_controller/proc/player_arrived(mob/living/player, datum/expedition_party/expedition)
	if(!player)
		return

	visitors |= player

	// Teleport to spawn point
	if(spawn_point)
		var/turf/spawn_turf = get_turf(spawn_point)
		player.forceMove(spawn_turf)
	else
		log_game("Warning: Faction hub [faction_id] has no spawn point!")

	// Welcome message from faction
	var/welcome_msg = "You arrive at [faction?.name || "the trading hub"]."
	if(faction)
		welcome_msg += " [faction.get_dialogue("greeting")]"
	to_chat(player, span_notice(welcome_msg))

	// Mark faction as discovered
	if(faction && !faction.discovered)
		faction.discovered = TRUE
		to_chat(player, span_boldnotice("You have discovered [faction.name]!"))

	// Small reputation boost for visiting in person
	if(faction && faction.can_trade)
		faction.adjust_reputation(1)

/**
 * Handle a player leaving the hub (via exit point)
 */
/datum/faction_hub_controller/proc/player_departed(mob/living/player)
	if(!player)
		return

	visitors -= player

	// Departure message
	to_chat(player, span_notice("You prepare to leave [faction?.name || "the trading hub"]."))

/**
 * Get the buy price modifier (includes hub discount)
 */
/datum/faction_hub_controller/proc/get_hub_buy_modifier()
	if(!faction)
		return HUB_TRADING_DISCOUNT

	return faction.get_buy_modifier() * HUB_TRADING_DISCOUNT

/**
 * Get the sell price modifier (includes hub bonus)
 */
/datum/faction_hub_controller/proc/get_hub_sell_modifier()
	if(!faction)
		return 1.0

	// Hub gives +10% to sell prices too
	return faction.get_sell_modifier() * (1.0 / HUB_TRADING_DISCOUNT)

/**
 * Check if a player is in this hub
 */
/datum/faction_hub_controller/proc/is_visitor(mob/living/player)
	return player in visitors

// ============================================
// GLOBAL HELPER PROCS
// ============================================

/**
 * Get or create a faction hub controller for a faction
 */
/proc/get_faction_hub(faction_id)
	if(faction_id in GLOB.faction_hubs)
		return GLOB.faction_hubs[faction_id]

	// Create new controller
	var/datum/faction_hub_controller/controller = new(faction_id)
	return controller

/**
 * Find which faction hub a player is currently in (if any)
 */
/proc/get_player_faction_hub(mob/living/player)
	if(!player)
		return null

	// Check by area
	var/area/A = get_area(player)
	if(istype(A, /area/resurgence/faction_hub))
		var/area/resurgence/faction_hub/hub_area = A
		return GLOB.faction_hubs[hub_area.faction_id]

	return null
