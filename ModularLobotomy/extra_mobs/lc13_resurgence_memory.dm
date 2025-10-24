// Resurgence Clan Core - Memory System
// Allows players to relive memories by loading temporary rooms and transferring their mind into a hologram
//
// HOW TO USE:
//
// 1. Define your NPC info (who they are, where they spawn):
//    npc_info = list(
//        "NPC_1" = list(
//            "spawn_landmark" = "npc_1_spawn",  // ID of the spawn landmark
//            "name" = "Character Name",
//            "icon" = 'path/to/icon.dmi',
//            "icon_state" = "character_sprite"
//        )
//    )
//
// 2. Define the memory sequence (what happens, in order):
//    memory_sequence = list(
//        list("npc" = "NPC_1", "action" = "say", "text" = "Hello!"),
//        list("npc" = "NPC_1", "action" = "emote", "text" = "waves"),
//        list("npc" = "NPC_2", "action" = "say", "text" = "Hi there!"),
//        list("npc" = "NPC_1", "action" = "move", "dir" = NORTH),
//        list("npc" = "NPC_1", "action" = "move_relative", "x" = -2, "y" = -3),
//        list("npc" = "NPC_1", "action" = "face", "dir" = NORTH),
//        list("npc" = "NPC_1", "action" = "icon", "state" = "happy"),
//        list("npc" = "NPC_1", "action" = "move_to_coord", "x" = 100, "y" = 50),
//        list("delay" = 50)  // Add delay between actions
//    )
//
// AVAILABLE ACTIONS:
// - "say": NPC says text (params: "text")
// - "emote": NPC emotes (params: "text")
// - "move": NPC moves one step (params: "dir" = NORTH/SOUTH/EAST/WEST)
// - "move_relative": Move relative to current position (params: "x", "y" in tiles)
// - "face": Turn to face direction (params: "dir" = NORTH/SOUTH/EAST/WEST)
// - "icon": Change icon_state (params: "state")
// - "move_to_coord": Move to absolute coordinates (params: "x", "y")
// - "delay": Add a delay in the sequence (params: "delay" in deciseconds)
//
// TIMING CONTROL:
// 1. Default delay (20 deciseconds = 2 seconds) happens after EVERY action
// 2. Override per action: list("npc" = "NPC_1", "action" = "say", "text" = "Hi", "action_delay" = 50)
// 3. Add standalone delay: list("delay" = 100)
// 4. Change default for entire memory: default_action_delay = 30
//
// Example with timing:
//    list("npc" = "NPC_1", "action" = "say", "text" = "Hello")  // 2 sec wait after
//    list("npc" = "NPC_2", "action" = "say", "text" = "Hi", "action_delay" = 50)  // 5 sec wait after
//    list("delay" = 100)  // Extra 10 sec wait
//    list("npc" = "NPC_1", "action" = "say", "text" = "Goodbye")  // 2 sec wait after

//==============================================================================
// LANDMARKS
//==============================================================================

/// Landmark where memory rooms can be loaded
/obj/effect/landmark/memory_loader
	name = "memory loader"
	icon_state = "x"
	var/in_use = FALSE
	var/datum/memory_session/current_session

/obj/effect/landmark/memory_loader/Initialize()
	. = ..()
	GLOB.landmarks_list += src

/obj/effect/landmark/memory_loader/Destroy()
	GLOB.landmarks_list -= src
	current_session = null
	return ..()

/// Landmark where NPCs spawn in memory rooms
/obj/effect/landmark/memory_npc_spawn
	name = "memory npc spawn"
	icon_state = "x2"
	var/npc_id = "npc_1"
	var/spawned = FALSE

/// Landmark that allows player to exit memory
/obj/effect/landmark/memory_exit
	name = "memory exit"
	desc = "A shimmering portal back to reality..."
	icon = 'icons/obj/cult.dmi'
	icon_state = "exit"
	invisibility = 0

/obj/effect/landmark/memory_exit/attack_hand(mob/living/user)
	. = ..()
	if(!istype(user, /mob/living/simple_animal/hologram_player))
		to_chat(user, span_warning("This portal doesn't seem to respond to you..."))
		return

	var/mob/living/simple_animal/hologram_player/hologram = user
	if(!hologram.session)
		to_chat(user, span_warning("You have no memory session to exit from!"))
		return

	to_chat(user, span_notice("You reach out to the portal and feel yourself being pulled back to reality..."))
	hologram.session.exit_memory(manual = TRUE)

//==============================================================================
// MEMORY SESSION DATUM
//==============================================================================

/// Manages a memory playback session
/datum/memory_session
	var/mob/living/original_body
	var/mob/living/simple_animal/hologram_player/hologram
	var/obj/effect/landmark/memory_loader/loader
	var/list/loaded_turfs = list()
	var/list/spawned_npcs = list() // npc_id -> mob reference
	var/list/npc_info = list() // NPC spawn data
	var/list/memory_sequence = list() // Timeline of actions
	var/auto_exit_enabled = TRUE
	var/exited = FALSE
	var/default_action_delay = 20 // Delay between actions in sequence

/datum/memory_session/New(mob/living/body, obj/effect/landmark/memory_loader/load_point, list/npc_data, list/sequence)
	original_body = body
	loader = load_point
	npc_info = npc_data
	memory_sequence = sequence

/datum/memory_session/proc/create_hologram(turf/spawn_location)
	if(!original_body || !original_body.mind)
		return FALSE

	hologram = new /mob/living/simple_animal/hologram_player(spawn_location)
	hologram.original_body = original_body
	hologram.session = src
	hologram.real_name = "[original_body.real_name] (Memory)"
	hologram.name = hologram.real_name

	// Transfer mind
	original_body.mind.transfer_to(hologram)

	to_chat(hologram, span_notice("You feel your consciousness drift into a memory..."))
	return TRUE

/datum/memory_session/proc/spawn_npcs()
	for(var/npc_id in npc_info)
		var/list/npc_data = npc_info[npc_id]

		// Find spawn landmark
		var/spawn_landmark_id = npc_data["spawn_landmark"]
		var/obj/effect/landmark/memory_npc_spawn/spawn_point

		for(var/obj/effect/landmark/memory_npc_spawn/landmark in GLOB.landmarks_list)
			if(landmark.npc_id == spawn_landmark_id && !landmark.spawned)
				spawn_point = landmark
				break

		if(!spawn_point)
			continue

		// Create NPC
		var/mob/living/simple_animal/npc/memory_npc/npc = new(get_turf(spawn_point))
		npc.session = src
		npc.npc_id = npc_id
		npc.name = npc_data["name"] || "Memory NPC"
		npc.icon = npc_data["icon"] || npc.icon
		npc.icon_state = npc_data["icon_state"] || npc.icon_state
		npc.icon_living = npc.icon_state

		spawn_point.spawned = TRUE
		spawned_npcs[npc_id] = npc

	// Start the sequence
	INVOKE_ASYNC(src, PROC_REF(execute_sequence))

/// Execute the memory sequence step by step
/datum/memory_session/proc/execute_sequence()
	for(var/list/action_data in memory_sequence)
		if(exited)
			return

		var/npc_id = action_data["npc"]
		var/action = action_data["action"]

		// Handle sequence-wide delays
		if(action_data["delay"])
			sleep(action_data["delay"])
			continue

		// Get the NPC for this action
		var/mob/living/simple_animal/npc/memory_npc/npc = spawned_npcs[npc_id]
		if(!npc || QDELETED(npc))
			continue

		// Execute the action
		switch(action)
			if("say")
				npc.say(action_data["text"])
			if("emote")
				npc.manual_emote(action_data["text"])
			if("move")
				step(npc, action_data["dir"])
			if("move_relative")
				var/target_x = npc.x + action_data["x"]
				var/target_y = npc.y + action_data["y"]
				var/turf/target = locate(target_x, target_y, npc.z)
				if(target)
					npc.forceMove(target)
			if("move_to_coord")
				var/turf/target = locate(action_data["x"], action_data["y"], npc.z)
				if(target)
					npc.forceMove(target)
			if("face")
				npc.setDir(action_data["dir"])
			if("icon")
				npc.icon_state = action_data["state"]

		// Default delay between actions
		var/delay = action_data["action_delay"]
		if(!delay)
			delay = default_action_delay
		sleep(delay)

	// Sequence complete
	sequence_finished()

/datum/memory_session/proc/sequence_finished()
	if(auto_exit_enabled)
		addtimer(CALLBACK(src, PROC_REF(exit_memory), FALSE), 30) // 3 second delay before auto-exit

/datum/memory_session/proc/exit_memory(manual = FALSE)
	if(exited)
		return
	exited = TRUE

	if(hologram && hologram.mind && original_body)
		if(manual)
			to_chat(hologram, span_notice("You feel your consciousness returning to your body..."))
		else
			to_chat(hologram, span_notice("The memory fades... You return to reality."))

		hologram.mind.transfer_to(original_body)
		to_chat(original_body, span_notice("You awaken from the memory."))

	cleanup()

/datum/memory_session/proc/cleanup()
	// Clean up NPCs
	for(var/mob/living/simple_animal/npc/memory_npc/npc in spawned_npcs)
		qdel(npc)
	spawned_npcs.Cut()

	// Clean up hologram
	if(hologram)
		qdel(hologram)
		hologram = null

	// Clean up loaded turfs
	for(var/turf/T in loaded_turfs)
		qdel(T)
	loaded_turfs.Cut()

	// Free up loader
	if(loader)
		loader.in_use = FALSE
		loader.current_session = null

	// Clean up references
	original_body = null
	loader = null
	qdel(src)

//==============================================================================
// HOLOGRAM PLAYER MOB
//==============================================================================

/// Player-controlled hologram that exists within memories
/mob/living/simple_animal/hologram_player
	name = "hologram"
	desc = "A semi-transparent holographic projection."
	icon = 'icons/mob/mob.dmi'
	icon_state = "ghost"
	icon_living = "ghost"
	maxHealth = 1000
	health = 1000
	color = LIGHT_COLOR_DARK_BLUE
	alpha = 150
	density = FALSE
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	mob_biotypes = MOB_SPIRIT
	damage_coeff = list(BRUTE = 0, RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0)
	speak_emote = list("echoes")
	response_help_continuous = "passes through"
	response_help_simple = "pass through"
	response_disarm_continuous = "passes through"
	response_disarm_simple = "pass through"
	response_harm_continuous = "passes through"
	response_harm_simple = "pass through"
	melee_damage_lower = 0
	melee_damage_upper = 0
	movement_type = FLOATING
	pull_force = MOVE_FORCE_WEAK
	move_resist = MOVE_FORCE_WEAK

	var/mob/living/original_body
	var/datum/memory_session/session

/mob/living/simple_animal/hologram_player/death(gibbed)
	if(session)
		session.exit_memory(manual = TRUE)
	return ..()

/mob/living/simple_animal/hologram_player/Destroy()
	// Safety: return mind if still has it
	if(mind && original_body)
		mind.transfer_to(original_body)
	original_body = null
	session = null
	return ..()

/mob/living/simple_animal/hologram_player/examine(mob/user)
	. = ..()
	. += span_notice("[src] appears to be a holographic projection, observing something unseen.")

//==============================================================================
// MEMORY NPC
//==============================================================================

/// NPC that exists within memories - controlled by memory session sequence
/mob/living/simple_animal/npc/memory_npc
	var/datum/memory_session/session
	var/npc_id
	wander = FALSE // Don't wander during memories

/mob/living/simple_animal/npc/memory_npc/Initialize()
	. = ..()
	speaking = TRUE // Prevent the base NPC system from auto-triggering

/mob/living/simple_animal/npc/memory_npc/LookForPlayer()
	return // Override to prevent auto-speech triggering

//==============================================================================
// RESURGENCE CLAN CORE ITEM
//==============================================================================

/// Item that loads a memory room and transfers player's mind into it
/obj/item/resurgence_core
	name = "resurgence clan core"
	desc = "A crystalline core pulsing with stored memories. Use it to relive the past."
	icon = 'icons/obj/assemblies.dmi'
	icon_state = "power_mod"
	w_class = WEIGHT_CLASS_SMALL
	var/template_id = "memory_template"
	var/datum/map_template/shelter/template
	var/used = FALSE
	var/delay_time = 30
	var/list/npc_info = list() // NPC spawn information
	var/list/memory_sequence = list() // Sequential timeline of actions
	var/hologram_spawn_id = "memory_spawn" // ID of spawn landmark for hologram
	var/default_action_delay = 20 // Default delay between actions (in deciseconds)

/obj/item/resurgence_core/proc/get_template()
	if(template)
		return TRUE
	template = SSmapping.shelter_templates[template_id]
	if(!template)
		WARNING("Memory template ([template_id]) not found!")
		return FALSE
	return TRUE

/obj/item/resurgence_core/examine(mob/user)
	. = ..()
	if(get_template())
		. += span_notice("This core contains: [template.name]")
		. += span_notice("[template.description]")

/obj/item/resurgence_core/attack_self(mob/user)
	if(used)
		to_chat(user, span_warning("[src] has already been used!"))
		return

	if(!isliving(user) || !user.mind)
		to_chat(user, span_warning("You lack the consciousness to enter this memory."))
		return

	// Get template
	if(!get_template())
		to_chat(user, span_warning("[src] fails to activate - the memory data is corrupted!"))
		return

	// Find available memory loader
	var/obj/effect/landmark/memory_loader/loader
	for(var/obj/effect/landmark/memory_loader/L in GLOB.landmarks_list)
		if(!L.in_use)
			loader = L
			break

	if(!loader)
		to_chat(user, span_warning("[src] cannot find a suitable location to project the memory!"))
		return

	// Start activation
	user.visible_message(span_warning("[user] activates \the [src] - reality begins to shimmer!"))
	to_chat(user, span_notice("You feel your consciousness being pulled into a memory..."))
	used = TRUE

	if(!do_after(user, delay_time, src))
		to_chat(user, span_warning("The memory projection was interrupted!"))
		used = FALSE
		return

	// Load the memory room
	var/turf/deploy_location = get_turf(loader)
	template.load(deploy_location, centered = TRUE)
	playsound(deploy_location, 'sound/effects/phasein.ogg', 50, TRUE)

	// Mark loader as in use
	loader.in_use = TRUE

	// Create memory session
	var/datum/memory_session/session = new(user, loader, npc_info, memory_sequence)
	session.default_action_delay = default_action_delay
	loader.current_session = session

	// Find hologram spawn point
	var/turf/hologram_spawn = deploy_location
	for(var/obj/effect/landmark/memory_npc_spawn/landmark in GLOB.landmarks_list)
		if(landmark.npc_id == hologram_spawn_id)
			hologram_spawn = get_turf(landmark)
			break

	// Create hologram and transfer mind
	if(!session.create_hologram(hologram_spawn))
		to_chat(user, span_warning("Failed to enter memory - consciousness transfer failed!"))
		session.cleanup()
		qdel(src)
		return

	// Spawn NPCs after a brief delay
	addtimer(CALLBACK(session, TYPE_PROC_REF(/datum/memory_session, spawn_npcs)), 20)

	// Delete the core
	qdel(src)

//==============================================================================
// EXAMPLE IMPLEMENTATION
//==============================================================================

/obj/item/resurgence_core/test_memory
	name = "test memory core"
	desc = "A test memory showing two NPCs having a conversation with various timing controls."
	template_id = "test_memory_room"
	hologram_spawn_id = "player_spawn"
	default_action_delay = 25 // Override default to 2.5 seconds between actions

	// Define NPC information (appearance, spawn location, etc)
	npc_info = list(
		"NPC_1" = list(
			"spawn_landmark" = "npc_1_spawn",
			"name" = "Test Subject Alpha",
			"icon_state" = "human"
		),
		"NPC_2" = list(
			"spawn_landmark" = "npc_2_spawn",
			"name" = "Test Subject Beta",
			"icon_state" = "human"
		)
	)

	// Define the memory sequence (what happens in order)
	memory_sequence = list(
		// NPC_1 speaks - uses default 2.5 sec delay after
		list("npc" = "NPC_1", "action" = "say", "text" = "Hello, this is a test memory."),

		// NPC_1 waves - custom 1 sec delay after this action
		list("npc" = "NPC_1", "action" = "emote", "text" = "waves", "action_delay" = 10),

		// NPC_2 responds quickly
		list("npc" = "NPC_2", "action" = "say", "text" = "I am the second NPC."),
		list("npc" = "NPC_2", "action" = "emote", "text" = "nods"),

		// Add a dramatic pause (4 seconds)
		list("delay" = 40),

		// NPC_1 moves around
		list("npc" = "NPC_1", "action" = "move", "dir" = NORTH),
		list("npc" = "NPC_1", "action" = "say", "text" = "I am moving north now."),

		// Move NPC_1 relative to current position (3 tiles down, 2 left)
		list("npc" = "NPC_1", "action" = "move_relative", "x" = -2, "y" = -3),
		list("npc" = "NPC_1", "action" = "face", "dir" = NORTH),

		// NPC_2 finishes with a long pause before speaking (5 sec)
		list("npc" = "NPC_2", "action" = "say", "text" = "Goodbye.", "action_delay" = 50),

		// Change NPC_1's icon
		list("npc" = "NPC_1", "action" = "icon", "state" = "human_happy")
	)

// Map template (needs to be created separately as a .dmm file)
/datum/map_template/shelter/test_memory
	name = "Test Memory Room"
	shelter_id = "test_memory_room"
	description = "A simple test room for the memory system."
	mappath = "_maps/templates/memories/test_memory.dmm"
