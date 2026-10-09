/**
 * Raid Intercept System
 *
 * Handles the intercept encounter when expedition parties encounter raid caravans
 * on the world map. Players are teleported to a combat arena to fight the raiders.
 * The map appearance adapts based on the terrain type where the encounter occurs.
 */

// ==================== Raid Intercept Area ====================

/area/resurgence/raid_intercept
	name = "Raid Intercept"
	icon_state = "red"
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY

// ==================== Map Loading ====================

/**
 * Load the raid intercept map
 */
/proc/load_raid_intercept_map()
	if(GLOB.raid_intercept_loaded)
		return TRUE

	if(!fexists(RAID_INTERCEPT_MAP))
		log_game("RAID INTERCEPT: Map file not found: [RAID_INTERCEPT_MAP]")
		return FALSE

	load_new_z_level(RAID_INTERCEPT_MAP, RAID_INTERCEPT_MAP_NAME)
	GLOB.raid_intercept_z = world.maxz
	GLOB.raid_intercept_loaded = TRUE

	// Initialize after 1 second to ensure all turfs are ready
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(init_raid_intercept_map)), 1 SECONDS)

	log_game("RAID INTERCEPT: Map loaded at z-level [GLOB.raid_intercept_z]")
	return TRUE

/**
 * Initialize the raid intercept map after loading
 * Finds all turfs and landmarks
 */
/proc/init_raid_intercept_map()
	GLOB.raid_intercept_floor_turfs.Cut()
	GLOB.raid_intercept_edge_turfs.Cut()

	// Find all floor turfs on the intercept z-level
	for(var/turf/open/floor/raid_intercept/T in block(
		locate(1, 1, GLOB.raid_intercept_z),
		locate(world.maxx, world.maxy, GLOB.raid_intercept_z)))
		GLOB.raid_intercept_floor_turfs += T
		if(istype(T, /turf/open/floor/raid_intercept/edge))
			GLOB.raid_intercept_edge_turfs += T

	log_game("RAID INTERCEPT: Found [length(GLOB.raid_intercept_floor_turfs)] floor turfs, [length(GLOB.raid_intercept_edge_turfs)] edge turfs")

/**
 * Update all raid intercept turfs to match a terrain type
 */
/proc/update_raid_intercept_terrain(terrain_type)
	// Update floor turfs
	for(var/turf/open/floor/raid_intercept/T in GLOB.raid_intercept_floor_turfs)
		T.set_terrain(terrain_type)
	// Update wall turfs
	for(var/turf/closed/wall/raid_intercept/W in GLOB.raid_intercept_wall_turfs)
		W.set_terrain(terrain_type)

// ==================== Terrain-Adaptive Turfs ====================

/**
 * Floor turf for raid intercept encounters
 * Adapts appearance based on terrain type
 */
/turf/open/floor/raid_intercept
	name = "clearing"
	desc = "An open area."
	icon = 'icons/turf/floors.dmi'
	icon_state = "grass0"
	baseturfs = /turf/open/floor/plating/dirt
	/// Current terrain type
	var/terrain_type = TERRAIN_PLAINS

/**
 * Set the terrain appearance
 */
/turf/open/floor/raid_intercept/proc/set_terrain(new_terrain)
	terrain_type = new_terrain
	color = null  // Reset color

	switch(terrain_type)
		if(TERRAIN_PLAINS)
			icon = 'icons/turf/floors.dmi'
			icon_state = "grass[rand(0,3)]"
			name = "grassy clearing"
			desc = "Soft grass underfoot."
		if(TERRAIN_FOREST)
			icon = 'icons/turf/floors.dmi'
			icon_state = "grass[rand(0,3)]"
			color = "#90b090"
			name = "forest floor"
			desc = "Fallen leaves and soft earth."
		if(TERRAIN_MOUNTAIN)
			icon = 'icons/turf/mining.dmi'
			icon_state = "rockyash"
			name = "rocky ground"
			desc = "Uneven stone terrain."
		if(TERRAIN_DESERT)
			icon = 'icons/turf/floors.dmi'
			icon_state = "ironsand[rand(0,3)]"
			name = "sandy ground"
			desc = "Fine sand shifts beneath your feet."
		if(TERRAIN_RUINS)
			icon = 'icons/turf/floors.dmi'
			icon_state = "plasteel"
			color = "#a09080"
			name = "crumbled floor"
			desc = "Ancient stonework, cracked and weathered."
		if(TERRAIN_SNOW)
			icon = 'icons/turf/floors.dmi'
			icon_state = "snow"
			name = "snowy ground"
			desc = "Crunchy snow underfoot."
		else
			// Default to plains
			icon = 'icons/turf/floors.dmi'
			icon_state = "grass0"
			name = "clearing"
			desc = "An open area."

/**
 * Edge turf - spawns terrain decorations
 */
/turf/open/floor/raid_intercept/edge
	name = "wilderness edge"
	/// List of decorations we spawned (for cleanup)
	var/list/decorations = list()

/turf/open/floor/raid_intercept/edge/set_terrain(new_terrain)
	// Clean up old decorations
	for(var/obj/decor in decorations)
		qdel(decor)
	decorations.Cut()

	// Call parent to set base appearance
	..()

	// Spawn terrain-specific decorations (50% chance)
	if(prob(50))
		spawn_decoration(new_terrain)

/turf/open/floor/raid_intercept/edge/proc/spawn_decoration(terrain_type)
	var/list/decor_types = list()

	switch(terrain_type)
		if(TERRAIN_PLAINS)
			decor_types = list(
				/obj/structure/flora/grass/both,
				/obj/structure/flora/rock/pile,
				/obj/structure/flora/bush
			)
		if(TERRAIN_FOREST)
			decor_types = list(
				/obj/structure/flora/tree/dead,
				/obj/structure/flora/bush,
				/obj/structure/flora/rock,
				/obj/structure/flora/grass/both
			)
		if(TERRAIN_MOUNTAIN)
			decor_types = list(
				/obj/structure/flora/rock,
				/obj/structure/flora/rock/pile,
				/obj/structure/flora/ash/tall_shroom
			)
		if(TERRAIN_DESERT)
			decor_types = list(
				/obj/structure/flora/rock/pile,
				/obj/structure/flora/rock,
				/obj/structure/flora/ash/cacti
			)
		if(TERRAIN_RUINS)
			decor_types = list(
				/obj/structure/flora/rock/pile,
				/obj/item/stack/sheet/mineral/wood
			)
		if(TERRAIN_SNOW)
			decor_types = list(
				/obj/structure/flora/rock/icy,
				/obj/structure/flora/rock/pile,
				/obj/structure/flora/tree/pine
			)

	if(length(decor_types))
		var/decor_type = pick(decor_types)
		var/obj/decor = new decor_type(src)
		decorations += decor

/**
 * Wall turf for the arena edge
 * Adapts appearance based on terrain type
 */
/turf/closed/wall/raid_intercept
	name = "impassable terrain"
	desc = "The way is blocked."
	icon = 'icons/turf/walls/wall.dmi'
	icon_state = "wall-0"
	/// Current terrain type
	var/terrain_type = TERRAIN_PLAINS

/// Wall turfs in the raid intercept area
GLOBAL_LIST_EMPTY(raid_intercept_wall_turfs)

/turf/closed/wall/raid_intercept/Initialize(mapload)
	. = ..()
	GLOB.raid_intercept_wall_turfs += src

/turf/closed/wall/raid_intercept/Destroy()
	GLOB.raid_intercept_wall_turfs -= src
	return ..()

/turf/closed/wall/raid_intercept/proc/set_terrain(new_terrain)
	terrain_type = new_terrain
	color = null

	switch(terrain_type)
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
			name = "impassable terrain"
			desc = "The way is blocked."

// ==================== Intercept Controller ====================

/**
 * Raid Intercept Controller
 *
 * Manages the intercept encounter - handles teleportation, combat, and rewards.
 */
/datum/raid_intercept_controller
	/// The raid caravan being intercepted
	var/datum/raid_caravan/caravan
	/// The expedition party doing the interception
	var/datum/expedition_party/expedition
	/// Terrain type for map appearance
	var/terrain_type = TERRAIN_PLAINS
	/// List of spawned enemy mobs
	var/list/spawned_enemies = list()
	/// List of player spawn landmarks found
	var/list/player_spawns = list()
	/// List of enemy spawn landmarks found
	var/list/enemy_spawns = list()
	/// Exit landmark
	var/obj/effect/landmark/raid_intercept_exit/exit_point
	/// Loot spawn landmark
	var/obj/effect/landmark/raid_intercept_loot/loot_point
	/// Whether the encounter has been resolved
	var/resolved = FALSE
	/// Whether players won
	var/victory = FALSE

/datum/raid_intercept_controller/New(datum/raid_caravan/RC, datum/expedition_party/EP)
	. = ..()
	caravan = RC
	expedition = EP
	terrain_type = caravan.current_tile?.terrain_type || TERRAIN_PLAINS
	GLOB.raid_intercept_controller = src

/datum/raid_intercept_controller/Destroy()
	cleanup()
	if(GLOB.raid_intercept_controller == src)
		GLOB.raid_intercept_controller = null
	caravan = null
	expedition = null
	return ..()

/**
 * Start the intercept encounter
 */
/datum/raid_intercept_controller/proc/start_intercept()
	// Load map if needed
	if(!GLOB.raid_intercept_loaded)
		if(!load_raid_intercept_map())
			return FALSE

	// Update terrain to match encounter location
	update_raid_intercept_terrain(terrain_type)

	// Find landmarks
	find_landmarks()

	if(!length(player_spawns))
		log_game("RAID INTERCEPT: No player spawn landmarks found!")
		return FALSE

	// Teleport players
	teleport_players_in()

	// Spawn enemies
	spawn_raiders()

	// Pause raid caravan movement
	caravan.pause_for_intercept()

	log_game("RAID INTERCEPT: Encounter started with [length(spawned_enemies)] raiders")
	return TRUE

/**
 * Find all landmarks on the intercept map
 */
/datum/raid_intercept_controller/proc/find_landmarks()
	player_spawns.Cut()
	enemy_spawns.Cut()
	exit_point = null
	loot_point = null

	for(var/turf/T in block(
		locate(1, 1, GLOB.raid_intercept_z),
		locate(world.maxx, world.maxy, GLOB.raid_intercept_z)))
		for(var/obj/effect/landmark/L in T)
			if(istype(L, /obj/effect/landmark/raid_intercept_spawn))
				player_spawns += L
			else if(istype(L, /obj/effect/landmark/raid_intercept_enemy))
				enemy_spawns += L
			else if(istype(L, /obj/effect/landmark/raid_intercept_exit))
				exit_point = L
			else if(istype(L, /obj/effect/landmark/raid_intercept_loot))
				loot_point = L

	log_game("RAID INTERCEPT: Found [length(player_spawns)] player spawns, [length(enemy_spawns)] enemy spawns")

/**
 * Teleport players into the encounter
 */
/datum/raid_intercept_controller/proc/teleport_players_in()
	if(!length(player_spawns))
		return

	var/turf/spawn_turf = get_turf(pick(player_spawns))

	for(var/mob/living/M in expedition.members)
		// Fade to black effect
		if(M.client)
			M.client.color = "#000000"

		M.forceMove(spawn_turf)

		// Fade in
		if(M.client)
			animate(M.client, color = null, time = 5)

		to_chat(M, span_boldwarning("You engage the Insurgence raiding party!"))
		to_chat(M, span_warning("Defeat all raiders to prevent the raid on your outpost!"))

/**
 * Spawn raiders based on raid type
 */
/datum/raid_intercept_controller/proc/spawn_raiders()
	if(!length(enemy_spawns))
		log_game("RAID INTERCEPT: No enemy spawn landmarks!")
		return

	// Determine enemy count based on raid type
	var/enemy_count = caravan.raider_count

	// Get the raid composition from globals
	var/list/composition = GLOB.insurgence_raid_compositions[caravan.raid_type]
	if(!composition)
		composition = GLOB.insurgence_raid_compositions[RAID_TYPE_BASIC]

	// Spawn enemies from composition
	var/spawned = 0
	for(var/mob_type in composition)
		var/count = composition[mob_type]
		for(var/i in 1 to count)
			if(spawned >= enemy_count)
				break

			var/obj/effect/landmark/spawn_point = pick(enemy_spawns)
			var/turf/T = get_turf(spawn_point)

			var/mob/living/raider = new mob_type(T)
			spawned_enemies += raider

			// Register for death tracking
			RegisterSignal(raider, COMSIG_LIVING_DEATH, PROC_REF(on_raider_death))

			spawned++

		if(spawned >= enemy_count)
			break

	log_game("RAID INTERCEPT: Spawned [length(spawned_enemies)] raiders")

/**
 * Handle raider death
 */
/datum/raid_intercept_controller/proc/on_raider_death(mob/living/source)
	SIGNAL_HANDLER
	spawned_enemies -= source

	// Check if all raiders are dead
	if(!length(spawned_enemies))
		on_victory()

/**
 * Handle player victory
 */
/datum/raid_intercept_controller/proc/on_victory()
	if(resolved)
		return

	resolved = TRUE
	victory = TRUE

	// Alert players
	for(var/mob/living/M in expedition.members)
		to_chat(M, span_boldnotice("Victory! The raiding party has been destroyed!"))
		to_chat(M, span_notice("The raid on your outpost has been prevented."))

	// Spawn loot
	if(loot_point)
		spawn_loot()

	// Destroy the raid caravan
	caravan.destroy_caravan()

	// Enable exit after a delay
	addtimer(CALLBACK(src, PROC_REF(enable_exit)), 10 SECONDS)

/**
 * Spawn loot rewards
 */
/datum/raid_intercept_controller/proc/spawn_loot()
	if(!loot_point)
		return

	var/turf/loot_turf = get_turf(loot_point)

	// Spawn basic loot based on raid type
	switch(caravan.raid_type)
		if(RAID_TYPE_BASIC)
			new /obj/item/stack/spacecash/c500(loot_turf)
			new /obj/item/stack/ore/iron(loot_turf, rand(20, 40))
		if(RAID_TYPE_PILLAGE)
			new /obj/item/stack/spacecash/c1000(loot_turf)
			new /obj/item/stack/ore/gold(loot_turf, rand(5, 10))
		if(RAID_TYPE_SIEGE)
			new /obj/item/stack/spacecash/c500(loot_turf)
			new /obj/item/stack/sheet/mineral/coal(loot_turf, rand(30, 50))
		if(RAID_TYPE_ASSASSINATION)
			new /obj/item/stack/spacecash/c1000(loot_turf)
			new /obj/item/stack/ore/silver(loot_turf, rand(5, 15))
		if(RAID_TYPE_OVERWHELMING)
			new /obj/item/stack/spacecash/c500(loot_turf)
			new /obj/item/stack/ore/iron(loot_turf, rand(40, 60))

/**
 * Enable the exit portal
 */
/datum/raid_intercept_controller/proc/enable_exit()
	if(exit_point)
		exit_point.enable()

	for(var/mob/living/M in expedition.members)
		if(M.z == GLOB.raid_intercept_z)
			to_chat(M, span_notice("An exit portal has appeared. Return to your expedition when ready."))

/**
 * Handle a player fleeing the encounter
 */
/datum/raid_intercept_controller/proc/player_fled(mob/living/M)
	// Teleport player back to corridor
	if(GLOB.expedition_corridor?.start_landmark)
		M.forceMove(get_turf(GLOB.expedition_corridor.start_landmark))
	to_chat(M, span_warning("You flee from the battle!"))

	// Check if all players have fled
	var/remaining = 0
	for(var/mob/living/member in expedition.members)
		if(member.z == GLOB.raid_intercept_z)
			remaining++

	if(remaining <= 0)
		on_defeat()

/**
 * Handle player defeat (all fled or died)
 */
/datum/raid_intercept_controller/proc/on_defeat()
	if(resolved)
		return

	resolved = TRUE
	victory = FALSE

	// Alert all expedition members
	for(var/mob/living/M in expedition.members)
		to_chat(M, span_boldwarning("The raiding party continues toward your outpost!"))

	// Resume raid caravan movement
	caravan.resume_from_intercept()

	// Cleanup
	qdel(src)

/**
 * Return players to the expedition corridor
 */
/datum/raid_intercept_controller/proc/return_to_expedition()
	// Get the return turf
	var/turf/return_turf = null
	if(GLOB.expedition_corridor?.start_landmark)
		return_turf = get_turf(GLOB.expedition_corridor.start_landmark)

	if(!return_turf)
		log_game("RAID INTERCEPT: No return turf found!")
		return

	// Teleport all players back
	for(var/mob/living/M in expedition.members)
		if(M.z == GLOB.raid_intercept_z)
			if(M.client)
				M.client.color = "#000000"
			M.forceMove(return_turf)
			if(M.client)
				animate(M.client, color = null, time = 5)
			to_chat(M, span_notice("You continue your expedition..."))

	// Cleanup
	qdel(src)

/**
 * Clean up the encounter
 */
/datum/raid_intercept_controller/proc/cleanup()
	// Delete remaining enemies
	for(var/mob/living/E in spawned_enemies)
		qdel(E)
	spawned_enemies.Cut()

	// Reset exit
	if(exit_point)
		exit_point.enabled = FALSE

	player_spawns.Cut()
	enemy_spawns.Cut()
