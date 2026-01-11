// Caravan Encounter System
// Handles the physical encounter area when players meet a caravan

// ============================================
// CARAVAN ENCOUNTER AREA
// ============================================

/area/resurgence/caravan_encounter
	name = "Caravan Encounter"
	icon_state = "yellow"
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY

// ============================================
// CARAVAN ENCOUNTER TURFS
// ============================================

/// List of floor turfs in the caravan encounter area
GLOBAL_LIST_EMPTY(caravan_encounter_floor_turfs)
/// List of edge floor turfs that spawn decor
GLOBAL_LIST_EMPTY(caravan_encounter_edge_turfs)
/// List of wall turfs in the caravan encounter area
GLOBAL_LIST_EMPTY(caravan_encounter_wall_turfs)

/**
 * Caravan Encounter Floor Turf
 * Changes appearance based on the terrain where the caravan was encountered
 */
/turf/open/floor/caravan_encounter
	name = "path"
	desc = "Ground near the caravan."
	icon = 'icons/turf/floors.dmi'
	icon_state = "grass0"
	/// Current terrain type being displayed
	var/current_terrain = TERRAIN_PLAINS

/turf/open/floor/caravan_encounter/Initialize(mapload)
	. = ..()
	GLOB.caravan_encounter_floor_turfs += src

/turf/open/floor/caravan_encounter/Destroy()
	GLOB.caravan_encounter_floor_turfs -= src
	return ..()

/**
 * Set the terrain type and update appearance
 */
/turf/open/floor/caravan_encounter/proc/set_terrain(terrain_type)
	current_terrain = terrain_type
	update_terrain_appearance()

/**
 * Update the turf's appearance based on current terrain
 */
/turf/open/floor/caravan_encounter/proc/update_terrain_appearance()
	switch(current_terrain)
		if(TERRAIN_PLAINS)
			icon_state = "grass[rand(0,3)]"
			icon = 'icons/turf/floors.dmi'
			name = "grassy clearing"
			desc = "Soft grass underfoot."
			color = null
		if(TERRAIN_FOREST)
			icon_state = "grass[rand(0,3)]"
			icon = 'icons/turf/floors.dmi'
			name = "forest floor"
			desc = "Fallen leaves and soft earth."
			color = "#90b090"
		if(TERRAIN_MOUNTAIN)
			icon_state = "rockyash"
			icon = 'icons/turf/mining.dmi'
			name = "rocky ground"
			desc = "Uneven stone terrain."
			color = null
		if(TERRAIN_DESERT)
			icon_state = "ironsand[rand(0,3)]"
			icon = 'icons/turf/floors.dmi'
			name = "sandy ground"
			desc = "Fine sand shifts beneath your feet."
			color = null
		if(TERRAIN_RUINS)
			icon_state = "basalt"
			icon = 'icons/turf/floors.dmi'
			name = "crumbled floor"
			desc = "Ancient stonework, cracked and weathered."
			color = "#a09080"
		if(TERRAIN_SNOW)
			icon_state = "snow"
			icon = 'icons/turf/floors.dmi'
			name = "snowy ground"
			desc = "Crunchy snow underfoot."
			color = null
		else
			icon_state = "grass0"
			name = "path"
			color = null

/**
 * Caravan Encounter Edge Floor Turf
 * Same as regular floor but spawns terrain-appropriate decor
 * Place these around the edges of the encounter area for visual variety
 */
/turf/open/floor/caravan_encounter/edge
	name = "path edge"
	desc = "The edge of the clearing."
	/// List of decor objects spawned on this turf
	var/list/spawned_decor = list()
	/// Chance to spawn decor (percent)
	var/decor_chance = 60

/turf/open/floor/caravan_encounter/edge/Initialize(mapload)
	. = ..()
	// Remove from regular list and add to edge list
	GLOB.caravan_encounter_floor_turfs -= src
	GLOB.caravan_encounter_edge_turfs += src

/turf/open/floor/caravan_encounter/edge/Destroy()
	GLOB.caravan_encounter_edge_turfs -= src
	clear_decor()
	return ..()

/**
 * Clear all spawned decor from this turf
 */
/turf/open/floor/caravan_encounter/edge/proc/clear_decor()
	for(var/obj/O in spawned_decor)
		if(!QDELETED(O))
			qdel(O)
	spawned_decor = list()

/**
 * Override set_terrain to also handle decor
 */
/turf/open/floor/caravan_encounter/edge/set_terrain(terrain_type)
	// Clear old decor first
	clear_decor()
	// Update terrain appearance
	current_terrain = terrain_type
	update_terrain_appearance()
	// Spawn new decor
	spawn_terrain_decor()

/**
 * Spawn decor appropriate for the current terrain
 */
/turf/open/floor/caravan_encounter/edge/proc/spawn_terrain_decor()
	if(!prob(decor_chance))
		return

	var/list/decor_types = get_terrain_decor_types()
	if(!length(decor_types))
		return

	var/decor_path = pick(decor_types)
	var/obj/decor = new decor_path(src)
	if(decor)
		spawned_decor += decor

/**
 * Get list of appropriate decor types for current terrain
 */
/turf/open/floor/caravan_encounter/edge/proc/get_terrain_decor_types()
	switch(current_terrain)
		if(TERRAIN_PLAINS)
			return list(
				/obj/structure/flora/grass/both,
				/obj/structure/flora/rock/pile,
				/obj/structure/flora/bush
			)
		if(TERRAIN_FOREST)
			return list(
				/obj/structure/flora/tree/dead,
				/obj/structure/flora/bush,
				/obj/structure/flora/rock/pile,
				/obj/structure/flora/grass/both
			)
		if(TERRAIN_MOUNTAIN)
			return list(
				/obj/structure/flora/rock,
				/obj/structure/flora/rock/pile,
				/obj/structure/flora/ash/leaf_shroom
			)
		if(TERRAIN_DESERT)
			return list(
				/obj/structure/flora/rock/pile,
				/obj/structure/flora/rock,
				/obj/structure/flora/ash/cacti
			)
		if(TERRAIN_RUINS)
			return list(
				/obj/structure/flora/rock/pile,
				/obj/item/stack/sheet/mineral/wood
			)
		if(TERRAIN_SNOW)
			return list(
				/obj/structure/flora/rock/icy,
				/obj/structure/flora/rock/pile,
				/obj/structure/flora/tree/pine
			)
	return list()

/**
 * Caravan Encounter Wall Turf
 * Forms the boundaries of the encounter area
 */
/turf/closed/wall/caravan_encounter
	name = "natural barrier"
	desc = "Impassable terrain."
	icon = 'icons/turf/walls/wall.dmi'
	icon_state = "wall-0"
	/// Current terrain type being displayed
	var/current_terrain = TERRAIN_PLAINS

/turf/closed/wall/caravan_encounter/Initialize(mapload)
	. = ..()
	GLOB.caravan_encounter_wall_turfs += src

/turf/closed/wall/caravan_encounter/Destroy()
	GLOB.caravan_encounter_wall_turfs -= src
	return ..()

/**
 * Set the terrain type and update appearance
 */
/turf/closed/wall/caravan_encounter/proc/set_terrain(terrain_type)
	current_terrain = terrain_type
	update_terrain_appearance()

/**
 * Update the wall's appearance based on current terrain
 */
/turf/closed/wall/caravan_encounter/proc/update_terrain_appearance()
	switch(current_terrain)
		if(TERRAIN_PLAINS)
			name = "grassy hillside"
			desc = "A steep grassy slope."
			color = "#4a7c3f"
		if(TERRAIN_FOREST)
			name = "dense treeline"
			desc = "Thick forest growth."
			color = "#2d5a27"
		if(TERRAIN_MOUNTAIN)
			name = "cliff face"
			desc = "Sheer rock walls."
			color = "#8b8b8b"
		if(TERRAIN_DESERT)
			name = "sand dune"
			desc = "A massive dune."
			color = "#c2b280"
		if(TERRAIN_RUINS)
			name = "collapsed wall"
			desc = "Rubble and debris."
			color = "#6b5b4f"
		if(TERRAIN_SNOW)
			name = "frozen cliff"
			desc = "Ice-covered rock walls."
			color = "#e8e8f0"
		else
			name = "natural barrier"
			color = null

/**
 * Update all caravan encounter turfs to match a terrain type
 * This clears old decor on edge turfs and spawns new terrain-appropriate decor
 */
/proc/update_caravan_encounter_terrain(terrain_type)
	// Update regular floor turfs
	for(var/turf/open/floor/caravan_encounter/F in GLOB.caravan_encounter_floor_turfs)
		F.set_terrain(terrain_type)
	// Update edge turfs (these handle their own decor cleanup and spawning)
	for(var/turf/open/floor/caravan_encounter/edge/E in GLOB.caravan_encounter_edge_turfs)
		E.set_terrain(terrain_type)
	// Update wall turfs
	for(var/turf/closed/wall/caravan_encounter/W in GLOB.caravan_encounter_wall_turfs)
		W.set_terrain(terrain_type)

// ============================================
// CARAVAN ENCOUNTER LANDMARKS
// ============================================

/**
 * Spawn point for players entering caravan encounter
 */
/obj/effect/landmark/caravan_spawn
	name = "caravan player spawn"
	invisibility = INVISIBILITY_ABSTRACT

/**
 * Location where caravan wagon/cart spawns
 */
/obj/effect/landmark/caravan_wagon
	name = "caravan wagon location"
	invisibility = INVISIBILITY_ABSTRACT

/**
 * Exit point to return to corridor/expedition
 * Shows a prompt when players step on it
 */
/obj/effect/landmark/caravan_exit
	name = "caravan exit"
	invisibility = INVISIBILITY_ABSTRACT

/obj/effect/landmark/caravan_exit/Initialize(mapload)
	. = ..()
	// Register signal on our loc to detect when mobs enter
	var/turf/T = get_turf(src)
	if(T)
		RegisterSignal(T, COMSIG_ATOM_ENTERED, PROC_REF(on_entered))

/obj/effect/landmark/caravan_exit/proc/on_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	if(!isliving(AM))
		return
	var/mob/living/L = AM
	// Async call to show prompt
	INVOKE_ASYNC(src, PROC_REF(prompt_exit), L)

/obj/effect/landmark/caravan_exit/proc/prompt_exit(mob/living/user)
	if(!GLOB.current_caravan_controller)
		return

	var/datum/expedition_party/expedition = GLOB.current_caravan_controller.expedition
	if(!expedition || !(user in expedition.members))
		return

	var/datum/browser/popup = new(user, "caravan_exit", "Leave Caravan", 350, 200)

	var/html = {"
<!DOCTYPE html>
<html>
<head>
<style>
body {
	font-family: 'Segoe UI', Tahoma, sans-serif;
	background: #1a1a2e;
	color: #eee;
	margin: 0;
	padding: 20px;
	text-align: center;
}
h3 {
	margin-top: 0;
	color: #fff;
}
.buttons {
	display: flex;
	flex-direction: column;
	gap: 10px;
	margin-top: 20px;
}
.btn {
	display: block;
	padding: 12px;
	background: #16213e;
	color: #fff;
	text-decoration: none;
	border-radius: 6px;
	border: 2px solid #333;
}
.btn:hover {
	background: #1a2744;
	border-color: #4a90d9;
}
</style>
</head>
<body>
<h3>Leave the Caravan?</h3>
<p>Continue your expedition or stay to trade.</p>
<div class="buttons">
	<a class="btn" href="?src=\ref[src];action=leave">Continue Expedition</a>
	<a class="btn" href="?src=\ref[src];action=stay">Stay Here</a>
</div>
</body>
</html>
"}

	popup.set_content(html)
	popup.open()

/obj/effect/landmark/caravan_exit/Topic(href, list/href_list)
	var/mob/living/user = usr
	if(!isliving(user))
		return

	var/action = href_list["action"]
	switch(action)
		if("leave")
			// Close popup
			user << browse(null, "window=caravan_exit")
			// Return to corridor
			if(GLOB.current_caravan_controller)
				GLOB.current_caravan_controller.player_leaving(user)
		if("stay")
			// Just close popup
			user << browse(null, "window=caravan_exit")

/**
 * Spawn point for caravan trader NPC
 */
/obj/effect/landmark/caravan_trader
	name = "caravan trader spawn"
	invisibility = INVISIBILITY_ABSTRACT

// ============================================
// CARAVAN ENCOUNTER CONTROLLER
// ============================================

/**
 * Caravan Encounter Controller
 *
 * Manages the caravan encounter area and player interactions.
 */
/datum/caravan_encounter_controller
	/// The caravan being encountered
	var/datum/faction_caravan/caravan
	/// The expedition party that triggered the encounter
	var/datum/expedition_party/expedition
	/// Spawn landmark reference
	var/obj/effect/landmark/caravan_spawn/spawn_point
	/// Wagon landmark references (one guard spawns per landmark)
	var/list/wagon_points = list()
	/// Exit landmark reference
	var/obj/effect/landmark/caravan_exit/exit_point
	/// Trader landmark reference
	var/obj/effect/landmark/caravan_trader/trader_point
	/// Spawned trader NPC
	var/mob/living/simple_animal/caravan_trader/trader_npc
	/// Whether the encounter is resolved
	var/resolved = FALSE
	/// Outcome of the encounter
	var/outcome = "none"  // "trade", "attack", "steal", "ignore", "fled"
	/// List of spawned guards
	var/list/guards = list()

/datum/caravan_encounter_controller/New(datum/faction_caravan/C, datum/expedition_party/party)
	. = ..()
	caravan = C
	expedition = party

	// Find landmarks
	find_landmarks()

/datum/caravan_encounter_controller/Destroy()
	// Clean up guards
	for(var/mob/living/G in guards)
		qdel(G)
	guards = null
	// Clean up trader
	if(trader_npc)
		qdel(trader_npc)
		trader_npc = null
	caravan = null
	expedition = null
	spawn_point = null
	wagon_points = null
	exit_point = null
	trader_point = null
	return ..()

/**
 * Find landmarks in the caravan encounter area
 */
/datum/caravan_encounter_controller/proc/find_landmarks()
	if(!GLOB.caravan_encounter_z)
		return

	wagon_points = list()
	for(var/obj/effect/landmark/L in GLOB.landmarks_list)
		if(L.z != GLOB.caravan_encounter_z)
			continue
		if(istype(L, /obj/effect/landmark/caravan_spawn))
			spawn_point = L
		else if(istype(L, /obj/effect/landmark/caravan_wagon))
			wagon_points += L  // Collect all wagon landmarks
		else if(istype(L, /obj/effect/landmark/caravan_exit))
			exit_point = L
		else if(istype(L, /obj/effect/landmark/caravan_trader))
			trader_point = L

/**
 * Start the encounter - teleport players to physical caravan area
 * Players can explore, trade with NPCs, and leave when ready
 */
/datum/caravan_encounter_controller/proc/start_encounter()
	if(!spawn_point)
		log_game("Caravan encounter failed: no spawn point found")
		return FALSE

	// Set current encounter globally
	GLOB.current_caravan_encounter = caravan
	GLOB.current_caravan_controller = src

	// Update encounter terrain to match the tile the caravan is on
	var/terrain_type = TERRAIN_PLAINS
	if(caravan.current_tile)
		terrain_type = caravan.current_tile.terrain_type
		// Don't use faction/outpost terrain types
		if(terrain_type == TERRAIN_FACTION || terrain_type == TERRAIN_OUTPOST)
			terrain_type = TERRAIN_PLAINS
	update_caravan_encounter_terrain(terrain_type)

	// Spawn entities based on hostility
	if(caravan.is_hostile())
		// Hostile: spawn aggressive guards, no trader
		spawn_hostile_guards()
	else
		// Friendly: spawn passive guards and trader
		spawn_passive_guards()
		spawn_trader()

	// Teleport all expedition members
	var/turf/spawn_turf = get_turf(spawn_point)
	for(var/mob/living/M in expedition.members)
		// Fade effect
		if(M.client)
			M.client.color = "#000000"

		M.forceMove(spawn_turf)

		// Fade back in
		if(M.client)
			animate(M.client, color = null, time = 5)

		// Show arrival message based on hostility
		if(caravan.is_hostile())
			to_chat(M, span_boldwarning("You've encountered a hostile patrol! Prepare for combat!"))
		else
			to_chat(M, span_notice("You approach [caravan.name]. Speak with the trader to buy or sell goods."))
			to_chat(M, span_notice("Walk to the exit when you're ready to continue."))

	// Track caravan encounter for objectives
	on_caravan_encountered()

	return TRUE

/**
 * Spawn hostile caravan guards - one guard per wagon landmark
 * Used for hostile caravans (Insurgence patrols)
 * Guards attack players on sight
 * For Insurgence, spawns random raid mobs instead
 */
/datum/caravan_encounter_controller/proc/spawn_hostile_guards()
	if(!length(wagon_points))
		return

	// For insurgence, spawn raid mobs from the same pool that raids use
	if(caravan.faction_id == "insurgence_clan")
		spawn_insurgence_raiders()
		return

	// For other hostile factions, spawn regular guards
	for(var/obj/effect/landmark/caravan_wagon/wagon in wagon_points)
		var/turf/guard_turf = get_turf(wagon)
		if(!guard_turf)
			continue
		var/mob/living/simple_animal/hostile/caravan_guard/guard = new(guard_turf)
		guard.faction_id = caravan.faction_id
		guard.setup_appearance()  // Sets strength based on faction
		guards += guard

/**
 * Spawn Insurgence raid mobs for hostile caravans
 * Uses mob types from lc13_resurgence_clan_mobs.dm and lc13_resurgence_clan_rce_ranged.dm
 */
/datum/caravan_encounter_controller/proc/spawn_insurgence_raiders()
	// List of possible raid mob types
	var/list/raid_mob_types = list(
		// Melee mobs from lc13_resurgence_clan_mobs.dm
		/mob/living/simple_animal/hostile/clan/scout,
		/mob/living/simple_animal/hostile/clan/defender,
		/mob/living/simple_animal/hostile/clan/drone,
		// Ranged mobs from lc13_resurgence_clan_rce_ranged.dm
		/mob/living/simple_animal/hostile/clan/ranged/gunner,
		/mob/living/simple_animal/hostile/clan/ranged/rapid,
		/mob/living/simple_animal/hostile/clan/ranged/sniper,
		/mob/living/simple_animal/hostile/clan/ranged/warper,
		/mob/living/simple_animal/hostile/clan/ranged/harpooner
	)

	// Spawn one random raid mob at each wagon landmark
	for(var/obj/effect/landmark/caravan_wagon/wagon in wagon_points)
		var/turf/spawn_turf = get_turf(wagon)
		if(!spawn_turf)
			continue
		var/mob_type = pick(raid_mob_types)
		var/mob/living/simple_animal/hostile/raider = new mob_type(spawn_turf)
		guards += raider

/**
 * Spawn passive caravan guards - one guard per wagon landmark
 * Used for friendly caravans
 * Guards only attack if provoked
 */
/datum/caravan_encounter_controller/proc/spawn_passive_guards()
	if(!length(wagon_points))
		return

	// Spawn one passive guard at each wagon landmark
	for(var/obj/effect/landmark/caravan_wagon/wagon in wagon_points)
		var/turf/guard_turf = get_turf(wagon)
		if(!guard_turf)
			continue
		var/mob/living/simple_animal/hostile/caravan_guard/passive/guard = new(guard_turf)
		guard.faction_id = caravan.faction_id
		guard.setup_appearance()  // Sets strength based on faction
		guards += guard

/**
 * Spawn caravan trader NPC
 */
/datum/caravan_encounter_controller/proc/spawn_trader()
	// Use trader landmark if available, otherwise first wagon point
	var/turf/trader_turf
	if(trader_point)
		trader_turf = get_turf(trader_point)
	else if(length(wagon_points))
		trader_turf = get_turf(wagon_points[1])

	if(!trader_turf)
		return

	trader_npc = new /mob/living/simple_animal/caravan_trader(trader_turf)
	trader_npc.link_caravan(caravan)

/**
 * End the encounter and return players to expedition
 */
/datum/caravan_encounter_controller/proc/end_encounter_success()
	resolved = TRUE

	// Resume caravan travel
	caravan.resume_travel()

	// Clear global encounter
	GLOB.current_caravan_encounter = null
	GLOB.current_caravan_controller = null

	// Return players to corridor
	return_to_corridor()

/**
 * Return all players to the expedition corridor
 */
/datum/caravan_encounter_controller/proc/return_to_corridor()
	if(!GLOB.expedition_corridor)
		return

	// Get corridor start position
	var/turf/return_turf = get_turf(GLOB.expedition_corridor.start_landmark)
	if(!return_turf)
		return

	// Teleport all expedition members back
	for(var/mob/living/M in expedition.members)
		// Fade effect
		if(M.client)
			M.client.color = "#000000"

		M.forceMove(return_turf)

		// Fade back in
		if(M.client)
			animate(M.client, color = null, time = 5)

		to_chat(M, span_notice("You continue your expedition..."))

/**
 * Handle a single player choosing to leave the caravan encounter
 * Called from the exit landmark when player selects "leave"
 */
/datum/caravan_encounter_controller/proc/player_leaving(mob/living/user)
	if(!user || !(user in expedition?.members))
		return

	// Return this player to corridor
	if(!GLOB.expedition_corridor)
		to_chat(user, span_warning("Cannot find expedition corridor!"))
		return

	var/turf/return_turf = get_turf(GLOB.expedition_corridor.start_landmark)
	if(!return_turf)
		to_chat(user, span_warning("Cannot find return location!"))
		return

	// Fade effect
	if(user.client)
		user.client.color = "#000000"

	user.forceMove(return_turf)

	// Fade back in
	if(user.client)
		animate(user.client, color = null, time = 5)

	to_chat(user, span_notice("You leave the caravan and continue your expedition..."))

	// Check if all expedition members have left
	var/all_left = TRUE
	for(var/mob/living/M in expedition.members)
		if(M.z == GLOB.caravan_encounter_z)
			all_left = FALSE
			break

	// If everyone has left, end the encounter
	if(all_left)
		end_encounter_success()

/**
 * Called when all guards are defeated
 */
/datum/caravan_encounter_controller/proc/guards_defeated()
	if(resolved && outcome != "attack")
		return

	resolved = TRUE

	// Let players loot
	to_chat(expedition.members, span_boldnotice("The caravan guards have been defeated! Loot their goods!"))

	// Spawn loot at first wagon point
	if(length(wagon_points))
		var/turf/loot_turf = get_turf(wagon_points[1])
		for(var/item_path in caravan.stock)
			for(var/i in 1 to caravan.stock[item_path])
				new item_path(loot_turf)

	// Destroy the caravan
	caravan.destroy_caravan()

	// Allow players to leave after looting
	addtimer(CALLBACK(src, PROC_REF(end_encounter_success)), 30 SECONDS)

/**
 * Apply reputation change with a faction
 */
/datum/caravan_encounter_controller/proc/apply_reputation_change(faction_id, amount)
	var/datum/trading_faction/faction = GLOB.resurgence_trading?.get_faction(faction_id)
	if(faction)
		faction.adjust_reputation(amount)

// ============================================
// CARAVAN GUARD MOB
// ============================================

/mob/living/simple_animal/hostile/caravan_guard
	name = "caravan guard"
	desc = "A guard protecting a trading caravan."
	icon = 'icons/mob/simple_human.dmi'
	icon_state = "hostile"
	icon_living = "hostile"
	health = 80
	maxHealth = 80
	melee_damage_lower = 15
	melee_damage_upper = 25
	attack_verb_continuous = "strikes"
	attack_verb_simple = "strike"
	attack_sound = 'sound/weapons/punch1.ogg'
	speed = 1
	faction = list("caravan")
	robust_searching = TRUE
	/// Which faction this guard belongs to
	var/faction_id

/mob/living/simple_animal/hostile/caravan_guard/proc/setup_appearance()
	switch(faction_id)
		if("resurgence_clan")
			name = "clan scout"
			desc = "A vigilant scout defending their caravan."
			icon = 'ModularLobotomy/_Lobotomyicons/resurgence_32x48.dmi'
			icon_state = "clan_scout_normal"
			health = 500
			maxHealth = 500
			melee_damage_lower = 5
			melee_damage_upper = 7
			melee_damage_type = RED_DAMAGE
			attack_sound = 'sound/weapons/purple_tear/stab2.ogg'
		if("jiajia_ren")
			name = "flock protector"
			desc = "A large bird-folk warrior with sharp talons."
			icon = 'icons/mob/cuckoospawn_big.dmi'
			icon_state = "evil_ass_bird"
			health = 1200
			maxHealth = 1200
			melee_damage_lower = 20
			melee_damage_upper = 30
		if("santata_factory")
			name = "factory enforcer"
			desc = "An armored gnome protecting the caravan's goods."
			icon = 'ModularLobotomy/_Lobotomyicons/outpost_npcs.dmi'
			icon_state = pick("gnome_green", "gnome_purple")
			mob_size = MOB_SIZE_SMALL
			health = 50
			maxHealth = 50
			melee_damage_lower = 8
			melee_damage_upper = 15
		if("cloud_town")
			name = "caravan hunter"
			desc = "A skilled hunter protecting the wagon."
			icon = 'ModularLobotomy/_Lobotomyicons/outpost_npcs.dmi'
			icon_state = pick("cloud_hunter1", "cloud_hunter2", "cloud_hunter3")
			health = 300
			maxHealth = 300
			melee_damage_lower = 15
			melee_damage_upper = 25
		if("insurgence_clan")
			// Insurgence uses raid mobs, not guards
			name = "insurgence raider"
			desc = "A hostile raider looking for prey."
			health = 90
			maxHealth = 90
			melee_damage_lower = 20
			melee_damage_upper = 35

/mob/living/simple_animal/hostile/caravan_guard/death(gibbed)
	. = ..()
	// Check if all guards are dead
	if(GLOB.current_caravan_controller)
		var/all_dead = TRUE
		// Check if any other guards in range are still alive
		for(var/mob/living/simple_animal/hostile/caravan_guard/G in view(10, src))
			if(G != src && G.stat != DEAD)
				all_dead = FALSE
				break
		if(all_dead)
			// Signal guards defeated to the encounter controller
			log_game("All caravan guards defeated")
			GLOB.current_caravan_controller.guards_defeated()

// ============================================
// PASSIVE CARAVAN GUARD (for friendly caravans)
// ============================================

/**
 * Passive Caravan Guard
 * Doesn't attack unless provoked. Used for non-hostile caravans.
 */
/mob/living/simple_animal/hostile/caravan_guard/passive
	faction = list("neutral")  // Won't attack players by default
	/// Whether this guard has been provoked
	var/provoked = FALSE

/mob/living/simple_animal/hostile/caravan_guard/passive/Initialize(mapload)
	. = ..()
	// Don't target anything initially
	target = null

/**
 * Handle being attacked - become hostile
 */
/mob/living/simple_animal/hostile/caravan_guard/passive/attack_hand(mob/living/user, list/modifiers)
	if(!provoked)
		become_hostile(user)
	return ..()

/mob/living/simple_animal/hostile/caravan_guard/passive/attackby(obj/item/W, mob/living/user, params)
	if(!provoked)
		become_hostile(user)
	return ..()

/mob/living/simple_animal/hostile/caravan_guard/passive/bullet_act(obj/projectile/P)
	if(!provoked && isliving(P.firer))
		become_hostile(P.firer)
	return ..()

/**
 * Make this guard and nearby guards hostile
 */
/mob/living/simple_animal/hostile/caravan_guard/passive/proc/become_hostile(mob/living/attacker)
	if(provoked)
		return

	provoked = TRUE
	faction = list("caravan")

	// Target the attacker
	if(attacker)
		GiveTarget(attacker)

	// Alert nearby passive guards
	for(var/mob/living/simple_animal/hostile/caravan_guard/passive/G in view(7, src))
		if(G != src && !G.provoked)
			G.become_hostile(attacker)

	// Apply reputation loss for attacking
	if(faction_id && GLOB.current_caravan_controller)
		GLOB.current_caravan_controller.apply_reputation_change(faction_id, CARAVAN_ATTACK_REP_LOSS)

	visible_message(span_danger("[src] becomes hostile!"))
