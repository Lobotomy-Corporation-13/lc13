// =============================================================================
// SERPENT'S BOOK - TRAPPED RESIDENT NPCs
// =============================================================================
// These NPCs are residents trapped within the Serpent's Book, fully consumed
// by their desires. The Serpent has molded rooms to fulfill their wishes in
// twisted, horrifying ways.
// =============================================================================

/mob/living/simple_animal/hostile/ui_npc/serpent_resident
	name = "Trapped Resident"
	desc = "A figure whose eyes hold the weight of eternity. They seem... content."
	icon = 'icons/mob/simple_human.dmi'
	icon_state = "faceless"
	icon_living = "faceless"
	health = 500
	maxHealth = 500
	typing_interval = 40
	start_scene_id = "intro"
	emote_delay = 4000

	// Won't attack players initially
	stat_attack = CONSCIOUS
	faction = list("serpent_book", "neutral")
	minimum_distance = 0
	retreat_distance = 0

	// Dialogue variables
	var/has_met_before = FALSE
	var/player_suspicious = FALSE
	var/offered_deal = FALSE
	var/was_attacked = FALSE

	/// Chapter this resident belongs to
	var/resident_chapter = 0

	/// Reference to the dimension manager (set when spawned in room)
	var/datum/serpent_dimension_manager/book_manager

/mob/living/simple_animal/hostile/ui_npc/serpent_resident/Initialize(mapload)
	. = ..()
	// Find the manager from the area
	var/area/serpents_library/lib = get_area(src)
	if(istype(lib) && lib.parent_manager)
		book_manager = lib.parent_manager
		resident_chapter = lib.chapter_number

/mob/living/simple_animal/hostile/ui_npc/serpent_resident/update_player_variables(mob/user)
	. = ..()
	if(!user)
		return

	// Track if this player has met this NPC before
	if(isnull(scene_manager.get_var(user, "player.met_before")))
		scene_manager.set_var(user, "player.met_before", FALSE)

	if(isnull(scene_manager.get_var(user, "player.suspicious")))
		scene_manager.set_var(user, "player.suspicious", FALSE)

	if(isnull(scene_manager.get_var(user, "player.attacked_npc")))
		scene_manager.set_var(user, "player.attacked_npc", FALSE)

	// Check player's curse level based on chapter
	var/curse_level = get_player_curse_level(user)
	scene_manager.set_var(user, "player.curse_level", curse_level)

/mob/living/simple_animal/hostile/ui_npc/serpent_resident/proc/get_player_curse_level(mob/user)
	if(!book_manager)
		return 0
	var/chapter = book_manager.player_chapters[user]
	if(!chapter)
		return 0
	// Higher chapters = lower curse, lower chapters = higher curse
	if(chapter >= 76)
		return 0
	if(chapter >= 51)
		return 1
	if(chapter >= 26)
		return 2
	if(chapter >= 11)
		return 3
	return 4

/mob/living/simple_animal/hostile/ui_npc/serpent_resident/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	was_attacked = TRUE
	scene_manager.set_var(user, "player.attacked_npc", TRUE)

	// Alert the Serpent (if implemented)
	if(book_manager)
		// Could trigger Serpent alert here
		visible_message(span_warning("The air grows cold. Something has taken notice..."))

/mob/living/simple_animal/hostile/ui_npc/serpent_resident/death(gibbed)
	visible_message(span_danger("[src] crumbles away, their form dissolving into pages that scatter like ash..."))
	// Residents don't truly die - they reform eventually
	. = ..()

/// Called when player questions the NPC's reality
/mob/living/simple_animal/hostile/ui_npc/serpent_resident/proc/on_player_suspicious(mob/user)
	player_suspicious = TRUE
	scene_manager.set_var(user, "player.suspicious", TRUE)

/// Called when player accepts the NPC's deal
/mob/living/simple_animal/hostile/ui_npc/serpent_resident/proc/on_deal_accepted(mob/user)
	offered_deal = TRUE
	// Override in subtypes for specific effects

/// Marks player as having met this NPC
/mob/living/simple_animal/hostile/ui_npc/serpent_resident/proc/mark_met(mob/user)
	has_met_before = TRUE
	scene_manager.set_var(user, "player.met_before", TRUE)
