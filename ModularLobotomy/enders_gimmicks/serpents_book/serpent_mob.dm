// =============================================================================
// THE SERPENT - Player-Controlled (Admin) / AI Fallback Hunter
// =============================================================================
// A serpentine figure in formal attire that hunts players within the book.
// Admin-only control: when the book captures players, admins are alerted
// and can click a link to take control. AI fallback hunts players otherwise.
// =============================================================================

/mob/living/simple_animal/hostile/serpent_librarian
	name = "The Serpent"
	desc = "A serpentine figure in formal attire. Its cold eyes regard you with ancient hunger."
	icon = 'ModularLobotomy/_Lobotomyicons/serpent_mob.dmi'
	icon_state = "S"
	icon_living = "S"
	icon_dead = "S"

	// Item handling (dextrous like corroded cassowary)
	dextrous = TRUE
	held_items = list(null, null)
	possible_a_intents = list(INTENT_HELP, INTENT_GRAB, INTENT_DISARM, INTENT_HARM)

	// Stats
	maxHealth = 800
	health = 800
	melee_damage_lower = 25
	melee_damage_upper = 35
	melee_damage_type = BLACK_DAMAGE
	damage_coeff = list(RED_DAMAGE = 1.0, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 1.5)
	attack_verb_continuous = "strikes"
	attack_verb_simple = "strike"
	attack_sound = 'sound/weapons/slash.ogg'

	// AI targeting
	faction = list("neutral", "serpent_book")
	vision_range = 9
	aggro_vision_range = 9
	stat_attack = CONSCIOUS
	minimum_distance = 1
	retreat_distance = 0
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	move_to_delay = 2

	// Speech
	speak_chance = 5
	speak = list("Ssssss...", "You cannot hide...", "The pages know where you are...")
	speak_emote = list("hisses", "whispers")
	emote_hear = list("hisses softly.", "whispers something unintelligible.")

	// Interaction text
	response_help_continuous = "touches"
	response_help_simple = "touch"
	response_disarm_continuous = "shoves"
	response_disarm_simple = "shove"
	response_harm_continuous = "strikes"
	response_harm_simple = "strike"

	// Loot - nothing, the serpent dissolves
	loot = list()

	/// Reference to the parent book item
	var/obj/item/serpents_book/parent_book
	/// Reference to the dimension manager
	var/datum/serpent_dimension_manager/manager

	/// Currently grabbed mob (via tail constrict)
	var/mob/living/tail_victim = null
	/// Whether an admin is currently controlling this mob
	var/player_controlled = FALSE

	/// AI warp timer - when to next warp to a player
	var/next_ai_warp = 0
	/// AI warp interval in deciseconds
	var/ai_warp_interval = 300  // 30 seconds

	/// Respawn delay after death
	var/respawn_delay = 30 SECONDS

/mob/living/simple_animal/hostile/serpent_librarian/Initialize(mapload)
	. = ..()
	// Grant abilities
	var/datum/action/cooldown/serpent_ability/tail_grab/grab = new()
	grab.Grant(src)

	var/datum/action/cooldown/serpent_ability/chapter_warp/warp = new()
	warp.Grant(src)

	var/datum/action/innate/serpent_ability/commune/whisper = new()
	whisper.Grant(src)

	// If spawned normally (not via spawn_serpent), try to link to the room system
	if(!manager)
		var/area/serpents_library/lib = get_area(src)
		if(istype(lib) && lib.parent_manager)
			manager = lib.parent_manager
			parent_book = manager.parent_book
			manager.serpent = src
			// Register in room tracking
			var/chapter_num = lib.chapter_number
			manager.player_chapters[src] = chapter_num
			var/chapter_key = "[chapter_num]"
			if(!manager.room_occupants[chapter_key])
				manager.room_occupants[chapter_key] = list()
			manager.room_occupants[chapter_key] += src

/mob/living/simple_animal/hostile/serpent_librarian/Destroy()
	release_victim()
	parent_book = null
	manager = null
	return ..()

/// The Serpent can read books and papers
/mob/living/simple_animal/hostile/serpent_librarian/is_literate()
	return TRUE

/mob/living/simple_animal/hostile/serpent_librarian/Login()
	. = ..()
	player_controlled = TRUE
	to_chat(src, span_danger("You are The Serpent, keeper of this ancient library."))
	to_chat(src, span_notice("Your abilities:"))
	to_chat(src, span_notice("- <b>Tail Constrict</b>: Grab an adjacent victim with your tail, immobilizing and dragging them."))
	to_chat(src, span_notice("- <b>Chapter Warp</b>: Teleport to any chapter in the book."))
	to_chat(src, span_notice("- <b>Serpent's Whisper</b>: Send a message to all players in the book."))
	to_chat(src, span_notice("- You can pick up and use items with your hands."))
	to_chat(src, span_notice("- You can read books and documents."))
	to_chat(src, span_warning("Hunt down the intruders. Do not let them reach Chapter 0."))

/mob/living/simple_animal/hostile/serpent_librarian/Logout()
	player_controlled = FALSE
	..()

// =============================================================================
// AI BEHAVIOR
// =============================================================================

/// Override CanAttack to only target players tracked in the book
/mob/living/simple_animal/hostile/serpent_librarian/CanAttack(atom/the_target)
	if(!isliving(the_target))
		return FALSE
	var/mob/living/L = the_target
	// Don't attack dead mobs
	if(L.stat == DEAD)
		return FALSE
	// Don't attack things in our faction (other book NPCs)
	if(faction_check_mob(L))
		return FALSE
	// Only attack if they're tracked in the book
	if(manager && !(L in manager.player_chapters))
		return FALSE
	return ..()

/// AI warp logic: if no targets nearby, warp to an occupied chapter
/mob/living/simple_animal/hostile/serpent_librarian/Life()
	. = ..()
	if(!.)
		return
	// Only do AI warp when not player-controlled
	if(player_controlled)
		return
	if(!manager)
		return
	// Check if we have a target nearby
	if(target)
		return
	// Warp to a chapter with players periodically
	if(world.time < next_ai_warp)
		return
	next_ai_warp = world.time + ai_warp_interval
	ai_warp_to_players()

/// Warps the AI serpent to a random chapter that has players
/mob/living/simple_animal/hostile/serpent_librarian/proc/ai_warp_to_players()
	if(!manager)
		return
	// Build list of chapters that have living players (not the serpent itself)
	var/list/occupied_chapters = list()
	for(var/chapter_key in manager.room_occupants)
		var/list/occupants = manager.room_occupants[chapter_key]
		for(var/mob/living/carbon/C in occupants)
			if(C.stat != DEAD)
				occupied_chapters += text2num(chapter_key)
				break
	if(!length(occupied_chapters))
		return
	var/target_chapter = pick(occupied_chapters)
	var/my_chapter = manager.player_chapters[src]
	// Don't warp if already in a chapter with players
	if(my_chapter == target_chapter)
		return
	manager.debug_jump_to_chapter(src, target_chapter)

/// Override death to handle respawn
/mob/living/simple_animal/hostile/serpent_librarian/death(gibbed)
	// Release any grabbed victim
	release_victim()
	// Drop held items
	if(dextrous)
		drop_all_held_items()
	visible_message(span_danger("[src] dissolves into loose pages that scatter across the floor..."))
	. = ..()
	// Schedule respawn
	if(manager && parent_book)
		addtimer(CALLBACK(parent_book, TYPE_PROC_REF(/obj/item/serpents_book, respawn_serpent)), respawn_delay)

// =============================================================================
// TAIL CONSTRICT SYSTEM
// =============================================================================

/// Grabs an adjacent living carbon with the serpent's tail
/mob/living/simple_animal/hostile/serpent_librarian/proc/grab_victim(mob/living/carbon/victim)
	if(tail_victim)
		return FALSE
	if(!victim || !istype(victim))
		return FALSE
	tail_victim = victim
	// Immobilize for a long time (cleared on release)
	victim.Immobilize(600 SECONDS)
	// Register signals to drag and auto-release
	RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(drag_victim))
	RegisterSignal(victim, COMSIG_LIVING_DEATH, PROC_REF(on_victim_death))
	RegisterSignal(victim, COMSIG_PARENT_QDELETING, PROC_REF(on_victim_qdel))
	visible_message(span_danger("[src] wraps its tail around [victim]!"))
	to_chat(victim, span_userdanger("The Serpent's tail coils around you, holding you in place!"))
	return TRUE

/// Releases the currently grabbed victim
/mob/living/simple_animal/hostile/serpent_librarian/proc/release_victim()
	if(!tail_victim)
		return
	var/mob/living/victim = tail_victim
	tail_victim = null
	// Unregister signals
	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
	if(!QDELETED(victim))
		UnregisterSignal(victim, COMSIG_LIVING_DEATH)
		UnregisterSignal(victim, COMSIG_PARENT_QDELETING)
		// Remove immobilize
		victim.SetImmobilized(0)
		visible_message(span_notice("[src] releases [victim] from its tail."))
		to_chat(victim, span_notice("The Serpent releases you!"))

/// Drags the victim along when the serpent moves
/mob/living/simple_animal/hostile/serpent_librarian/proc/drag_victim()
	SIGNAL_HANDLER
	if(!tail_victim || QDELETED(tail_victim))
		release_victim()
		return
	tail_victim.forceMove(get_turf(src))

/// Auto-release when victim dies
/mob/living/simple_animal/hostile/serpent_librarian/proc/on_victim_death()
	SIGNAL_HANDLER
	release_victim()

/// Auto-release when victim is deleted
/mob/living/simple_animal/hostile/serpent_librarian/proc/on_victim_qdel()
	SIGNAL_HANDLER
	tail_victim = null
	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)

// =============================================================================
// ABILITIES
// =============================================================================

// Base ability type for serpent abilities
/datum/action/cooldown/serpent_ability
	check_flags = AB_CHECK_CONSCIOUS
	button_icon = 'ModularLobotomy/_Lobotomyicons/serpent_mob.dmi'
	button_icon_state = "S"

/// Gets the serpent mob from the ability owner
/datum/action/cooldown/serpent_ability/proc/get_serpent()
	if(istype(owner, /mob/living/simple_animal/hostile/serpent_librarian))
		return owner
	return null

// -----------------------------------------------------------------------------
// TAIL CONSTRICT
// -----------------------------------------------------------------------------

/datum/action/cooldown/serpent_ability/tail_grab
	name = "Tail Constrict"
	desc = "Wrap your tail around a nearby victim, immobilizing them. Use again to release."
	cooldown_time = 5 SECONDS

/datum/action/cooldown/serpent_ability/tail_grab/Trigger()
	. = ..()
	if(!.)
		return FALSE
	if(!IsAvailable())
		return FALSE

	var/mob/living/simple_animal/hostile/serpent_librarian/serpent = get_serpent()
	if(!serpent)
		return FALSE

	// If already holding someone, release them
	if(serpent.tail_victim)
		serpent.release_victim()
		StartCooldown()
		return TRUE

	// Find adjacent living carbon
	var/mob/living/carbon/chosen = null
	var/list/candidates = list()
	for(var/mob/living/carbon/C in range(1, serpent))
		if(C == serpent)
			continue
		if(C.stat == DEAD)
			continue
		candidates += C

	if(!length(candidates))
		to_chat(serpent, span_warning("No one is close enough to grab!"))
		return FALSE

	if(length(candidates) == 1)
		chosen = candidates[1]
	else
		chosen = input(serpent, "Choose a victim to constrict:", "Tail Constrict") as null|anything in candidates
		if(!chosen || !serpent.Adjacent(chosen))
			return FALSE

	if(serpent.grab_victim(chosen))
		StartCooldown()
		return TRUE
	return FALSE

// -----------------------------------------------------------------------------
// CHAPTER WARP
// -----------------------------------------------------------------------------

/datum/action/cooldown/serpent_ability/chapter_warp
	name = "Chapter Warp"
	desc = "Traverse the book's pages instantly. See all active chapters and their occupants."
	cooldown_time = 10 SECONDS

/datum/action/cooldown/serpent_ability/chapter_warp/Trigger()
	. = ..()
	if(!.)
		return FALSE
	if(!IsAvailable())
		return FALSE

	var/mob/living/simple_animal/hostile/serpent_librarian/serpent = get_serpent()
	if(!serpent || !serpent.manager)
		return FALSE

	var/datum/serpent_dimension_manager/mgr = serpent.manager

	// Build choices list showing chapters with occupant info
	var/list/choices = list()
	// First: active rooms with occupant counts
	for(var/chapter_key in mgr.active_rooms)
		var/list/occupants = mgr.room_occupants[chapter_key]
		var/player_count = 0
		var/list/names = list()
		if(occupants)
			for(var/mob/living/M in occupants)
				if(M == serpent)
					continue
				if(istype(M, /mob/living/simple_animal/hostile/serpent_librarian))
					continue
				player_count++
				names += M.name
		var/name_str = length(names) ? " - [names.Join(", ")]" : ""
		if(player_count > 0)
			choices["Chapter [chapter_key] ([player_count] player\s[name_str])"] = text2num(chapter_key)
		else
			choices["Chapter [chapter_key] (empty)"] = text2num(chapter_key)

	// Also add visitable chapters that aren't loaded
	for(var/chapter_num in mgr.visitable_chapters)
		var/chapter_key = "[chapter_num]"
		if(mgr.active_rooms[chapter_key])
			continue  // Already listed above
		choices["Chapter [chapter_num] (unloaded)"] = chapter_num

	if(!length(choices))
		to_chat(serpent, span_warning("No chapters available to warp to."))
		return FALSE

	var/choice = input(serpent, "Which chapter do you want to warp to?", "Chapter Warp") as null|anything in choices
	if(!choice)
		return FALSE

	var/target_chapter = choices[choice]
	if(!target_chapter)
		return FALSE

	// Perform the warp
	mgr.debug_jump_to_chapter(serpent, target_chapter)

	// Bring tail victim along
	if(serpent.tail_victim && !QDELETED(serpent.tail_victim))
		serpent.tail_victim.forceMove(get_turf(serpent))
		// Update victim's tracking too
		mgr.player_chapters[serpent.tail_victim] = target_chapter
		var/target_key = "[target_chapter]"
		var/list/occupants = mgr.room_occupants[target_key]
		if(occupants && !(serpent.tail_victim in occupants))
			occupants += serpent.tail_victim

	to_chat(serpent, span_notice("You slither through the pages to Chapter [target_chapter]."))
	playsound(serpent, 'sound/effects/phasein.ogg', 50, TRUE)
	StartCooldown()
	return TRUE

// -----------------------------------------------------------------------------
// SERPENT'S WHISPER (Innate - no cooldown)
// -----------------------------------------------------------------------------

/datum/action/innate/serpent_ability
	check_flags = AB_CHECK_CONSCIOUS
	button_icon = 'ModularLobotomy/_Lobotomyicons/serpent_mob.dmi'
	button_icon_state = "S"

/datum/action/innate/serpent_ability/commune
	name = "Serpent's Whisper"
	desc = "Your voice echoes through every page of the book."

/datum/action/innate/serpent_ability/commune/Activate()
	var/mob/living/simple_animal/hostile/serpent_librarian/serpent = owner
	if(!istype(serpent) || !serpent.manager)
		return

	var/message = input(serpent, "What do you whisper through the pages?", "Serpent's Whisper") as text|null
	if(!message)
		return

	// Sanitize input
	message = strip_html(message)
	if(!length(message))
		return

	// Send to all players in the book
	for(var/mob/living/M in serpent.manager.player_chapters)
		if(M == serpent)
			continue
		to_chat(M, span_danger("<i>A cold whisper echoes through the pages...</i>"))
		to_chat(M, span_danger("\"[message]\""))
		// Play ambient sound
		if(M.client)
			SEND_SOUND(M, sound('sound/ambience/ambigen12.ogg', volume = 30))

	to_chat(serpent, span_notice("Your whisper echoes through the book."))
