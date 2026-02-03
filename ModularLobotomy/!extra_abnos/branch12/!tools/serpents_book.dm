// =============================================================================
// SERPENT'S BOOK - Phase 1-6 Implementation
// =============================================================================
// A WAW-tier tool abnormality that captures players into a pocket dimension.
// Based on Hilbert's Hotel pattern from code/modules/ruins/spaceruin_code/hilbertshotel.dm
//
// Phase 1: Area, turfs, map template
// Phase 2: Book item with pull/capture, dimension manager
// Phase 3: Door navigation between chapters
// Phase 4: Room reuse with storage/restore
// Phase 5: Full chapter system with auto-skip and multiple templates
// Phase 6: Puzzle rooms with locked doors
// =============================================================================

// =============================================================================
// AREA AND TURFS (Phase 1)
// =============================================================================

/area/serpents_library
	name = "Serpent's Library"
	icon_state = "yellow"
	requires_power = FALSE
	dynamic_lighting = DYNAMIC_LIGHTING_DISABLED
	has_gravity = STANDARD_GRAVITY
	area_flags = NOTELEPORT | HIDDEN_AREA
	ambientsounds = list('sound/ambience/ambigen12.ogg')
	/// Reference to dimension manager
	var/datum/serpent_dimension_manager/parent_manager
	/// Which chapter this area represents
	var/chapter_number = 0

/turf/closed/indestructible/serpent_wall
	name = "ancient stone wall"
	desc = "Cold stone covered in faded inscriptions. It feels like it has existed for millennia."
	icon = 'icons/turf/walls/iron_wall.dmi'
	icon_state = "iron_wall-0"
	base_icon_state = "iron_wall"
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_CLOSED_TURFS, SMOOTH_GROUP_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_WALLS)
	explosion_block = INFINITY

/turf/open/indestructible/serpent_floor
	name = "worn stone floor"
	desc = "Ancient flagstones, worn smooth by countless footsteps."
	icon = 'icons/turf/floors.dmi'
	icon_state = "stone_floor"
	footstep = FOOTSTEP_FLOOR

/turf/open/indestructible/serpent_floor/landing
	name = "summoning circle"
	desc = "Strange runes mark this section of floor. This is where visitors first appear."

// =============================================================================
// MAP TEMPLATE (Phase 1)
// =============================================================================

/datum/map_template/serpents_book
	name = "Serpent's Book Chapter"
	mappath = "_maps/templates/serpents_book/serpents_chapter.dmm"

/datum/map_template/serpents_book/empty
	name = "Empty Chapter"
	mappath = "_maps/templates/serpents_book/serpents_empty.dmm"

// =============================================================================
// CHAPTER DATUM SYSTEM (Phase 5)
// =============================================================================
// Each chapter is defined by a simple datum that specifies its DMM file and spawn location.
// To add a new chapter:
// 1. Create a 20x20 DMM file in _maps/templates/serpents_book/
// 2. Add a new /datum/serpent_chapter/chapter_XXX subtype
// 3. Set chapter_number, mappath, and optionally spawn_x/spawn_y
// 4. The chapter is automatically registered and usable
// =============================================================================

/datum/serpent_chapter
	/// Chapter number this datum represents
	var/chapter_number = 0
	/// Path to the DMM file for this chapter
	var/mappath = "_maps/templates/serpents_book/serpents_chapter.dmm"
	/// X offset from bottom-left for player spawn (0-19 for 20x20 room)
	var/spawn_x = 10
	/// Y offset from bottom-left for player spawn (0-19 for 20x20 room)
	var/spawn_y = 10
	/// Is this a puzzle room? (locks north door until solved)
	var/is_puzzle = FALSE
	/// Puzzle type if is_puzzle is TRUE ("levers", "pressure_plates", etc.)
	var/puzzle_type = null

// -----------------------------------------------------------------------------
// EXAMPLE CHAPTER DEFINITIONS
// Add new chapters by creating subtypes like these
// -----------------------------------------------------------------------------

// Default chapter used for personal entry rooms and unmapped chapters
/datum/serpent_chapter/default
	chapter_number = 0  // Not a real chapter, just the default template
	mappath = "_maps/templates/serpents_book/serpents_chapter.dmm"

// -----------------------------------------------------------------------------
// UPPER ZONE - Sparse chapters (every 5)
// Players start here after being captured
// -----------------------------------------------------------------------------

/datum/serpent_chapter/chapter_180
	chapter_number = 180
	mappath = "_maps/templates/serpents_book/serpents_standard_01.dmm"

/datum/serpent_chapter/chapter_175
	chapter_number = 175
	mappath = "_maps/templates/serpents_book/serpents_standard_02.dmm"

/datum/serpent_chapter/chapter_170
	chapter_number = 170
	mappath = "_maps/templates/serpents_book/serpents_standard_03.dmm"

/datum/serpent_chapter/chapter_165
	chapter_number = 165
	mappath = "_maps/templates/serpents_book/serpents_abno_01.dmm"

/datum/serpent_chapter/chapter_160
	chapter_number = 160
	mappath = "_maps/templates/serpents_book/serpents_abno_02.dmm"

/datum/serpent_chapter/chapter_155
	chapter_number = 155
	mappath = "_maps/templates/serpents_book/serpents_abno_03.dmm"

/datum/serpent_chapter/chapter_150
	chapter_number = 150
	mappath = "_maps/templates/serpents_book/serpents_abno_04.dmm"

/datum/serpent_chapter/chapter_145
	chapter_number = 145
	mappath = "_maps/templates/serpents_book/serpents_abno_05.dmm"

/datum/serpent_chapter/chapter_140
	chapter_number = 140
	mappath = "_maps/templates/serpents_book/serpents_abno_06.dmm"

/datum/serpent_chapter/chapter_135
	chapter_number = 135
	mappath = "_maps/templates/serpents_book/serpents_abno_07.dmm"

/datum/serpent_chapter/chapter_130
	chapter_number = 130
	mappath = "_maps/templates/serpents_book/serpents_abno_08.dmm"

/datum/serpent_chapter/chapter_125
	chapter_number = 125
	mappath = "_maps/templates/serpents_book/serpents_abno_09.dmm"

/datum/serpent_chapter/chapter_120
	chapter_number = 120
	mappath = "_maps/templates/serpents_book/serpents_abno_10.dmm"

/datum/serpent_chapter/chapter_115
	chapter_number = 115

/datum/serpent_chapter/chapter_110
	chapter_number = 110

/datum/serpent_chapter/chapter_105
	chapter_number = 105

/datum/serpent_chapter/chapter_100
	chapter_number = 100

/datum/serpent_chapter/chapter_95
	chapter_number = 95

/datum/serpent_chapter/chapter_90
	chapter_number = 90

/datum/serpent_chapter/chapter_85
	chapter_number = 85

// -----------------------------------------------------------------------------
// MID ZONE - Denser chapters (every 2)
// Navigation becomes more frequent here
// -----------------------------------------------------------------------------

/datum/serpent_chapter/chapter_80
	chapter_number = 80

/datum/serpent_chapter/chapter_78
	chapter_number = 78

/datum/serpent_chapter/chapter_76
	chapter_number = 76

// NPC Chapter - The Clockmaker (Heinrich Valdis)
/datum/serpent_chapter/chapter_75
	chapter_number = 75
	mappath = "_maps/templates/serpents_book/serpents_chapter_75.dmm"

/datum/serpent_chapter/chapter_74
	chapter_number = 74

/datum/serpent_chapter/chapter_72
	chapter_number = 72

/datum/serpent_chapter/chapter_70
	chapter_number = 70

/datum/serpent_chapter/chapter_68
	chapter_number = 68

/datum/serpent_chapter/chapter_66
	chapter_number = 66

/datum/serpent_chapter/chapter_64
	chapter_number = 64

/datum/serpent_chapter/chapter_62
	chapter_number = 62

// Puzzle chapter at 60
/datum/serpent_chapter/chapter_60
	chapter_number = 60
	is_puzzle = TRUE
	puzzle_type = "levers"

/datum/serpent_chapter/chapter_58
	chapter_number = 58

/datum/serpent_chapter/chapter_56
	chapter_number = 56

// NPC Chapter - The Painter (Madame Rosalind)
/datum/serpent_chapter/chapter_55
	chapter_number = 55
	mappath = "_maps/templates/serpents_book/serpents_chapter_55.dmm"

/datum/serpent_chapter/chapter_54
	chapter_number = 54

/datum/serpent_chapter/chapter_52
	chapter_number = 52

// Puzzle chapter at 50
/datum/serpent_chapter/chapter_50
	chapter_number = 50
	is_puzzle = TRUE
	puzzle_type = "levers"

/datum/serpent_chapter/chapter_48
	chapter_number = 48

/datum/serpent_chapter/chapter_46
	chapter_number = 46

/datum/serpent_chapter/chapter_44
	chapter_number = 44

/datum/serpent_chapter/chapter_42
	chapter_number = 42

// Puzzle chapter at 40
/datum/serpent_chapter/chapter_40
	chapter_number = 40
	is_puzzle = TRUE
	puzzle_type = "levers"

/datum/serpent_chapter/chapter_38
	chapter_number = 38

/datum/serpent_chapter/chapter_36
	chapter_number = 36

// NPC Chapter - The Surgeon (Dr. Erasmus Vorn)
/datum/serpent_chapter/chapter_35
	chapter_number = 35
	mappath = "_maps/templates/serpents_book/serpents_chapter_35.dmm"

/datum/serpent_chapter/chapter_34
	chapter_number = 34

/datum/serpent_chapter/chapter_32
	chapter_number = 32

// Puzzle chapter at 30
/datum/serpent_chapter/chapter_30
	chapter_number = 30
	is_puzzle = TRUE
	puzzle_type = "levers"

/datum/serpent_chapter/chapter_28
	chapter_number = 28

/datum/serpent_chapter/chapter_26
	chapter_number = 26

/datum/serpent_chapter/chapter_24
	chapter_number = 24

/datum/serpent_chapter/chapter_22
	chapter_number = 22

// -----------------------------------------------------------------------------
// DENSE ZONE - Every chapter (final stretch)
// Players are close to escape, tension is high
// -----------------------------------------------------------------------------

// NPC Chapter + Puzzle - The Collector (Lord Aldric Thorne)
/datum/serpent_chapter/chapter_20
	chapter_number = 20
	mappath = "_maps/templates/serpents_book/serpents_chapter_20.dmm"
	is_puzzle = TRUE
	puzzle_type = "levers"

/datum/serpent_chapter/chapter_19
	chapter_number = 19

/datum/serpent_chapter/chapter_18
	chapter_number = 18

/datum/serpent_chapter/chapter_17
	chapter_number = 17

/datum/serpent_chapter/chapter_16
	chapter_number = 16

// Puzzle chapter at 15
/datum/serpent_chapter/chapter_15
	chapter_number = 15
	is_puzzle = TRUE
	puzzle_type = "levers"

/datum/serpent_chapter/chapter_14
	chapter_number = 14

/datum/serpent_chapter/chapter_13
	chapter_number = 13

/datum/serpent_chapter/chapter_12
	chapter_number = 12

/datum/serpent_chapter/chapter_11
	chapter_number = 11

// Puzzle chapter at 10
/datum/serpent_chapter/chapter_10
	chapter_number = 10
	is_puzzle = TRUE
	puzzle_type = "levers"

/datum/serpent_chapter/chapter_9
	chapter_number = 9

/datum/serpent_chapter/chapter_8
	chapter_number = 8

/datum/serpent_chapter/chapter_7
	chapter_number = 7

/datum/serpent_chapter/chapter_6
	chapter_number = 6

// Puzzle chapter at 5
/datum/serpent_chapter/chapter_5
	chapter_number = 5
	is_puzzle = TRUE
	puzzle_type = "levers"

/datum/serpent_chapter/chapter_4
	chapter_number = 4

/datum/serpent_chapter/chapter_3
	chapter_number = 3

/datum/serpent_chapter/chapter_2
	chapter_number = 2

/datum/serpent_chapter/chapter_1
	chapter_number = 1

// =============================================================================
// ROOM STATE STORAGE SYSTEM (Phase 4)
// =============================================================================
// Stores room contents with relative coordinates and directions.
// When a player leaves a room, items are stored relative to the spawn point.
// When returning, items are recreated at the correct positions.
// =============================================================================

/datum/stored_room_state
	/// Chapter number this state is for
	var/chapter_number = 0
	/// List of stored object data
	/// Each entry: list("type" = /obj/item/foo, "rel_x" = 3, "rel_y" = -2, "dir" = SOUTH, "name" = "custom name")
	var/list/stored_objects = list()

/datum/stored_room_state/Destroy()
	stored_objects = null
	return ..()

// =============================================================================
// DIMENSION MANAGER (Phase 2)
// =============================================================================

/datum/serpent_dimension_manager
	/// Chapter number -> turf reservation (for loaded chapters)
	var/list/active_rooms = list()
	/// Mob -> current chapter number
	var/list/player_chapters = list()
	/// Chapter number -> list of mobs
	var/list/room_occupants = list()
	/// Chapter number -> /datum/stored_room_state (for stored room contents with relative coords)
	var/list/stored_room_states = list()
	/// Base max chapter (the original top of the book)
	var/base_max_chapter = 180
	/// Current highest chapter number (grows as players are captured)
	var/current_max_chapter = 180
	/// Reference to the book item
	var/obj/item/serpents_book/parent_book
	/// Template for clearing rooms
	var/datum/map_template/serpents_book/empty/template_empty
	/// Cache of loaded map templates by mappath
	var/list/template_cache = list()

	// ==========================================================================
	// CHAPTER DATUM REGISTRY
	// ==========================================================================

	/// Chapter number -> /datum/serpent_chapter (auto-populated from subtypes)
	var/list/chapter_registry = list()
	/// Default chapter datum for unmapped chapters
	var/datum/serpent_chapter/default_chapter

	// ==========================================================================
	// PHASE 5: VISITABLE CHAPTERS AND AUTO-SKIP
	// ==========================================================================

	/// List of chapter numbers that have pre-made rooms (visitable)
	/// This is auto-populated from chapter_registry on init
	var/list/visitable_chapters = list()

	/// List of personal entry chapters (dynamically created for captured players)
	var/list/personal_chapters = list()

	// ==========================================================================
	// PHASE 6: PUZZLE ROOMS
	// ==========================================================================

	/// Chapter number -> puzzle datum (for active puzzles)
	var/list/active_puzzles = list()

/datum/serpent_dimension_manager/New(obj/item/serpents_book/book)
	. = ..()
	parent_book = book
	// Templates and chapters are registered lazily in load_templates() to avoid sleeping in Initialize

/// Loads map templates and registers all chapter datums
/datum/serpent_dimension_manager/proc/load_templates()
	if(!template_empty)
		template_empty = new /datum/map_template/serpents_book/empty()

	// Register all chapter datums if not done yet
	if(!length(chapter_registry))
		register_chapters()

/// Auto-discovers and registers all /datum/serpent_chapter subtypes
/datum/serpent_dimension_manager/proc/register_chapters()
	chapter_registry = list()
	visitable_chapters = list()

	for(var/chapter_type in subtypesof(/datum/serpent_chapter))
		var/datum/serpent_chapter/C = new chapter_type()

		// Skip the default chapter (chapter_number = 0) from visitable list
		if(C.chapter_number == 0)
			default_chapter = C
			continue

		// Register this chapter
		chapter_registry["[C.chapter_number]"] = C

		// Add to visitable chapters list
		visitable_chapters += C.chapter_number

	// Sort visitable chapters in descending order (highest first)
	visitable_chapters = sortList(visitable_chapters)

	// Create default chapter if not found
	if(!default_chapter)
		default_chapter = new /datum/serpent_chapter/default()

/// Gets the chapter datum for a chapter number, or default if not found
/datum/serpent_dimension_manager/proc/get_chapter_datum(chapter_num)
	var/chapter_key = "[chapter_num]"
	if(chapter_registry[chapter_key])
		return chapter_registry[chapter_key]
	return default_chapter

/datum/serpent_dimension_manager/Destroy()
	// Eject all players before destroying
	eject_all_players()
	// Clean up reservations
	for(var/chapter_num in active_rooms)
		var/datum/turf_reservation/reservation = active_rooms[chapter_num]
		qdel(reservation)
	// Clean up stored room states
	for(var/chapter_num in stored_room_states)
		var/datum/stored_room_state/state = stored_room_states[chapter_num]
		qdel(state)
	// Clean up puzzles
	for(var/chapter_num in active_puzzles)
		var/datum/serpent_puzzle/puzzle = active_puzzles[chapter_num]
		qdel(puzzle)
	// Clean up chapter datums
	for(var/chapter_key in chapter_registry)
		var/datum/serpent_chapter/C = chapter_registry[chapter_key]
		qdel(C)
	if(default_chapter)
		qdel(default_chapter)
	active_rooms = null
	player_chapters = null
	room_occupants = null
	stored_room_states = null
	personal_chapters = null
	active_puzzles = null
	template_cache = null
	chapter_registry = null
	visitable_chapters = null
	default_chapter = null
	parent_book = null
	return ..()

/// Captures a list of players and teleports them into the book
/datum/serpent_dimension_manager/proc/capture_players(list/mob/living/carbon/players)
	// Ensure templates are loaded
	load_templates()

	for(var/mob/living/carbon/player in players)
		// Create a new personal chapter for this player at the top
		current_max_chapter++
		var/chapter_num = current_max_chapter

		// Track this as a personal chapter (always visitable)
		personal_chapters += chapter_num

		// Create and load the room
		var/datum/turf_reservation/reservation = SSmapping.RequestBlockReservation(20, 20)
		if(!reservation)
			to_chat(player, span_warning("The book's pages refuse to open... (allocation failed)"))
			continue

		// Load the appropriate template for this chapter
		var/turf/bottom_left = locate(
			reservation.bottom_left_coords[1],
			reservation.bottom_left_coords[2],
			reservation.bottom_left_coords[3]
		)
		var/datum/map_template/serpents_book/chapter_template = get_template_for_chapter(chapter_num)
		chapter_template.load(bottom_left)

		// Link the area
		link_area(reservation, chapter_num)

		// Track the room
		active_rooms["[chapter_num]"] = reservation
		player_chapters[player] = chapter_num
		room_occupants["[chapter_num]"] = list(player)

		// Teleport player to landing position using chapter-specific spawn coords
		var/turf/landing = get_landing_turf_for_chapter(reservation, chapter_num)

		// Effects
		do_sparks(5, FALSE, get_turf(player))
		playsound(player, 'sound/effects/phasein.ogg', 50, TRUE)

		player.forceMove(landing)

		do_sparks(5, FALSE, landing)
		playsound(landing, 'sound/effects/phasein.ogg', 50, TRUE)

		to_chat(player, span_userdanger("The book's pages wrap around you!"))
		to_chat(player, span_danger("You find yourself alone in Chapter [chapter_num]..."))

/// Links the area to the dimension manager
/datum/serpent_dimension_manager/proc/link_area(datum/turf_reservation/reservation, chapter_num)
	var/turf/bottom_left = locate(
		reservation.bottom_left_coords[1],
		reservation.bottom_left_coords[2],
		reservation.bottom_left_coords[3]
	)

	var/area/serpents_library/chapter_area = get_area(bottom_left)
	if(istype(chapter_area))
		chapter_area.name = "Serpent's Library - Chapter [chapter_num]"
		chapter_area.parent_manager = src
		chapter_area.chapter_number = chapter_num

	// Link all doors in the area
	for(var/obj/structure/serpent_door/door in chapter_area)
		door.manager = src
		door.chapter_number = chapter_num

/// Ejects all players back to the book's location
/datum/serpent_dimension_manager/proc/eject_all_players()
	var/turf/exit_turf = get_turf(parent_book)
	if(!exit_turf)
		exit_turf = get_safe_random_turf()

	for(var/mob/living/player in player_chapters)
		do_sparks(5, FALSE, get_turf(player))
		player.forceMove(exit_turf)
		do_sparks(5, FALSE, exit_turf)
		to_chat(player, span_notice("You are violently ejected from the book!"))

	player_chapters = list()
	room_occupants = list()

/// Gets a random safe turf as fallback
/datum/serpent_dimension_manager/proc/get_safe_random_turf()
	return get_safe_random_station_turf()

// =============================================================================
// PHASE 3 & 4: NAVIGATION AND ROOM REUSE
// =============================================================================

/// Handles navigation when a player uses a door
/datum/serpent_dimension_manager/proc/navigate_chapter(mob/living/user, direction)
	if(!user || !isliving(user))
		return

	var/current_chapter = player_chapters[user]
	if(!current_chapter)
		to_chat(user, span_warning("You don't seem to belong to any chapter..."))
		return

	// Check puzzle lock for north door
	if(direction == NORTH && is_puzzle_chapter(current_chapter) && !is_puzzle_solved(current_chapter))
		to_chat(user, span_warning("The door remains sealed. You must solve the puzzle first..."))
		return

	// Find the next VISITABLE chapter (auto-skip non-visitable)
	var/target_chapter = get_next_visitable_chapter(current_chapter, direction)

	// Boundary checks
	if(target_chapter == 0 || (direction == NORTH && target_chapter == null))
		// Chapter 0 or null from NORTH means exit
		exit_dimension(user)
		return

	if(target_chapter == null)
		to_chat(user, span_warning("There are no more chapters beyond this..."))
		return

	if(target_chapter > current_max_chapter)
		to_chat(user, span_warning("There are no more chapters beyond this..."))
		return

	// Show skip message if we jumped multiple chapters
	var/chapters_skipped = abs(current_chapter - target_chapter) - 1
	if(chapters_skipped > 0)
		to_chat(user, span_notice("Pages blur past as you descend through [chapters_skipped] empty chapter\s..."))

	// Ensure templates are loaded
	load_templates()

	// Get current chapter key
	var/current_key = "[current_chapter]"
	var/target_key = "[target_chapter]"

	// Case 1: Target room already loaded (another player is there)
	if(active_rooms[target_key])
		teleport_to_chapter(user, target_chapter, direction)
		return

	// Get current room occupants
	var/list/current_occupants = room_occupants[current_key]
	if(!current_occupants)
		current_occupants = list()

	// Case 2: Current room will be empty after we leave - reuse the reservation
	if(length(current_occupants) <= 1)
		var/datum/turf_reservation/reservation = active_rooms[current_key]
		if(reservation)
			// Store current room contents
			store_room(current_chapter)

			// Load new chapter into same reservation
			load_chapter_into_reservation(reservation, target_chapter)

			// Update tracking
			active_rooms[target_key] = reservation
			active_rooms -= current_key
			room_occupants -= current_key
			room_occupants[target_key] = list(user)
			player_chapters[user] = target_chapter

			// Teleport to the appropriate door based on entry direction
			var/turf/landing = get_door_landing_turf(reservation, direction)
			user.forceMove(landing)

			to_chat(user, span_notice("You enter Chapter [target_chapter]."))
			return

	// Case 3: Other players in current room - allocate new reservation
	var/datum/turf_reservation/new_reservation = SSmapping.RequestBlockReservation(20, 20)
	if(!new_reservation)
		to_chat(user, span_warning("The pages refuse to turn... (allocation failed)"))
		return

	// Load template into new reservation
	load_chapter_into_reservation(new_reservation, target_chapter)

	// Update tracking
	active_rooms[target_key] = new_reservation
	if(current_occupants)
		current_occupants -= user
	room_occupants[target_key] = list(user)
	player_chapters[user] = target_chapter

	// Teleport to the appropriate door based on entry direction
	var/turf/landing = get_door_landing_turf(new_reservation, direction)
	user.forceMove(landing)

	to_chat(user, span_notice("You enter Chapter [target_chapter]."))

/// Teleports a player to an already-loaded chapter
/// entry_direction: The direction the player is traveling (NORTH toward 0, SOUTH toward higher)
/datum/serpent_dimension_manager/proc/teleport_to_chapter(mob/living/user, chapter_num, entry_direction = NORTH)
	var/chapter_key = "[chapter_num]"
	var/datum/turf_reservation/reservation = active_rooms[chapter_key]
	if(!reservation)
		return

	// Get old chapter info for tracking update
	var/old_chapter = player_chapters[user]
	var/old_key = "[old_chapter]"

	// Update old room occupants
	var/list/old_occupants = room_occupants[old_key]
	if(old_occupants)
		old_occupants -= user

	// Update new room occupants
	var/list/new_occupants = room_occupants[chapter_key]
	if(!new_occupants)
		new_occupants = list()
		room_occupants[chapter_key] = new_occupants
	new_occupants += user

	// Update player chapter
	player_chapters[user] = chapter_num

	// Teleport to the appropriate door based on entry direction
	var/turf/landing = get_door_landing_turf(reservation, entry_direction)
	user.forceMove(landing)

	to_chat(user, span_notice("You enter Chapter [chapter_num]."))

/// Gets the landing turf for a reservation using default spawn coords
/datum/serpent_dimension_manager/proc/get_landing_turf(datum/turf_reservation/reservation)
	return locate(
		reservation.bottom_left_coords[1] + default_chapter.spawn_x,
		reservation.bottom_left_coords[2] + default_chapter.spawn_y,
		reservation.bottom_left_coords[3]
	)

/// Gets the landing turf for a reservation using chapter-specific spawn coords
/datum/serpent_dimension_manager/proc/get_landing_turf_for_chapter(datum/turf_reservation/reservation, chapter_num)
	var/datum/serpent_chapter/chapter = get_chapter_datum(chapter_num)
	return locate(
		reservation.bottom_left_coords[1] + chapter.spawn_x,
		reservation.bottom_left_coords[2] + chapter.spawn_y,
		reservation.bottom_left_coords[3]
	)

/// Gets the spawn coordinates for a chapter (returns list(spawn_x, spawn_y))
/datum/serpent_dimension_manager/proc/get_spawn_coords_for_chapter(chapter_num)
	var/datum/serpent_chapter/chapter = get_chapter_datum(chapter_num)
	return list(chapter.spawn_x, chapter.spawn_y)

/// Gets the turf near a door in a room based on entry direction
/// When going NORTH (toward chapter 0), player enters from SOUTH door
/// When going SOUTH (toward higher chapters), player enters from NORTH door
/datum/serpent_dimension_manager/proc/get_door_landing_turf(datum/turf_reservation/reservation, entry_direction)
	var/turf/bottom_left = locate(
		reservation.bottom_left_coords[1],
		reservation.bottom_left_coords[2],
		reservation.bottom_left_coords[3]
	)
	var/area/serpents_library/chapter_area = get_area(bottom_left)
	if(!chapter_area)
		// Fallback to center spawn
		return get_landing_turf(reservation)

	// Find the appropriate door based on entry direction
	// If entering from NORTH direction (going toward 0), land at SOUTH door
	// If entering from SOUTH direction (going toward higher), land at NORTH door
	var/target_door_direction = (entry_direction == NORTH) ? SOUTH : NORTH

	for(var/obj/structure/serpent_door/door in chapter_area)
		if(door.direction == target_door_direction)
			// Return the turf the door is on (player will be placed there)
			return get_turf(door)

	// Fallback to center spawn if no door found
	return get_landing_turf(reservation)

/// Stores all movable contents of a room with relative coordinates
/datum/serpent_dimension_manager/proc/store_room(chapter_num)
	var/chapter_key = "[chapter_num]"
	var/datum/turf_reservation/reservation = active_rooms[chapter_key]
	if(!reservation)
		return

	// Get spawn point for relative coordinate calculation
	var/list/spawn_coords = get_spawn_coords_for_chapter(chapter_num)
	var/spawn_x = reservation.bottom_left_coords[1] + spawn_coords[1]
	var/spawn_y = reservation.bottom_left_coords[2] + spawn_coords[2]

	// Create or get storage state for this chapter
	var/datum/stored_room_state/state = stored_room_states[chapter_key]
	if(!state)
		state = new()
		state.chapter_number = chapter_num
		stored_room_states[chapter_key] = state
	state.stored_objects = list()  // Clear previous storage

	// Iterate through all turfs in the reservation and store movables
	for(var/i = 0 to 19)
		for(var/j = 0 to 19)
			var/turf/T = locate(
				reservation.bottom_left_coords[1] + i,
				reservation.bottom_left_coords[2] + j,
				reservation.bottom_left_coords[3]
			)
			if(!T)
				continue

			// Calculate relative coordinates from spawn point
			var/rel_x = T.x - spawn_x
			var/rel_y = T.y - spawn_y

			// Store all contents
			for(var/atom/movable/AM in T.contents)
				// Delete simple_animal mobs (non-player controlled) without saving
				if(istype(AM, /mob/living/simple_animal))
					var/mob/living/simple_animal/SA = AM
					// Skip player-controlled mobs (they're tracked separately)
					if(SA.client)
						continue
					// Disable cores for abnormalities before deleting to prevent core drops
					if(istype(SA, /mob/living/simple_animal/hostile/abnormality))
						var/mob/living/simple_animal/hostile/abnormality/abno = SA
						abno.core_enabled = FALSE
					// Just delete the mob, don't save it
					qdel(SA)
					continue

				// Skip other mobs (players, etc.)
				if(ismob(AM))
					continue

				// Skip abstract items
				if(isitem(AM))
					var/obj/item/I = AM
					if(I.item_flags & ABSTRACT)
						continue

				// Skip template objects (doors, etc.)
				if(is_template_object(AM))
					continue

				// Store object data
				var/list/obj_data = list(
					"type" = AM.type,
					"rel_x" = rel_x,
					"rel_y" = rel_y,
					"dir" = AM.dir,
					"name" = AM.name
				)
				state.stored_objects += list(obj_data)

				// Delete the original object
				qdel(AM)

/// Checks if an object is a template object that shouldn't be stored
/datum/serpent_dimension_manager/proc/is_template_object(atom/movable/AM)
	if(istype(AM, /obj/structure/serpent_door))
		return TRUE
	if(istype(AM, /obj/structure/serpent_lever))
		return TRUE
	return FALSE

/// Loads a chapter template into an existing reservation (clears first)
/datum/serpent_dimension_manager/proc/load_chapter_into_reservation(datum/turf_reservation/reservation, chapter_num)
	var/turf/bottom_left = locate(
		reservation.bottom_left_coords[1],
		reservation.bottom_left_coords[2],
		reservation.bottom_left_coords[3]
	)

	// Load the empty template first to clear the room
	template_empty.load(bottom_left)

	// Get the appropriate template for this chapter
	var/datum/map_template/serpents_book/chapter_template = get_template_for_chapter(chapter_num)
	chapter_template.load(bottom_left)

	// Link the area to this chapter
	link_area(reservation, chapter_num)

	// Set up puzzle room if applicable (locks north door)
	setup_puzzle_room(chapter_num, reservation)

	// Restore stored contents if any
	restore_room(chapter_num, reservation)

/// Restores stored room contents using relative coordinates
/datum/serpent_dimension_manager/proc/restore_room(chapter_num, datum/turf_reservation/reservation)
	var/chapter_key = "[chapter_num]"
	var/datum/stored_room_state/state = stored_room_states[chapter_key]
	if(!state)
		return

	// Get spawn point for absolute coordinate calculation
	var/list/spawn_coords = get_spawn_coords_for_chapter(chapter_num)
	var/spawn_x = reservation.bottom_left_coords[1] + spawn_coords[1]
	var/spawn_y = reservation.bottom_left_coords[2] + spawn_coords[2]
	var/z_level = reservation.bottom_left_coords[3]

	// Restore each stored object
	for(var/list/obj_data in state.stored_objects)
		var/obj_type = obj_data["type"]
		var/rel_x = obj_data["rel_x"]
		var/rel_y = obj_data["rel_y"]
		var/obj_dir = obj_data["dir"]
		var/obj_name = obj_data["name"]

		// Calculate absolute position from spawn point + relative coords
		var/abs_x = spawn_x + rel_x
		var/abs_y = spawn_y + rel_y
		var/turf/target = locate(abs_x, abs_y, z_level)

		if(!target)
			continue

		// Create the object at the correct position
		var/atom/movable/AM = new obj_type(target)
		if(obj_dir)
			AM.dir = obj_dir
		if(obj_name)
			AM.name = obj_name

/// Handles a player exiting the dimension at Chapter 0
/datum/serpent_dimension_manager/proc/exit_dimension(mob/living/user)
	var/turf/exit_turf = get_turf(parent_book)
	if(!exit_turf)
		exit_turf = get_safe_random_turf()

	// Get old chapter for cleanup
	var/old_chapter = player_chapters[user]
	var/old_key = "[old_chapter]"

	// Remove from tracking
	var/list/old_occupants = room_occupants[old_key]
	if(old_occupants)
		old_occupants -= user
	player_chapters -= user

	// Teleport out
	do_sparks(5, FALSE, get_turf(user))
	playsound(user, 'sound/effects/phasein.ogg', 50, TRUE)
	user.forceMove(exit_turf)
	do_sparks(5, FALSE, exit_turf)
	playsound(exit_turf, 'sound/effects/phasein.ogg', 50, TRUE)

	to_chat(user, span_boldnotice("The pages release you! You tumble out of the book."))
	to_chat(user, span_notice("You have escaped the Serpent's Library!"))

// =============================================================================
// PHASE 5: VISITABLE CHAPTERS AND TEMPLATE SYSTEM
// =============================================================================

/// Returns TRUE if the chapter is visitable (has a room)
/datum/serpent_dimension_manager/proc/is_visitable(chapter_num)
	// Personal entry chapters are always visitable
	if(chapter_num in personal_chapters)
		return TRUE
	// Pre-made chapters from the visitable list
	return (chapter_num in visitable_chapters)

/// Finds the next visitable chapter in the given direction
/// Returns null if no more visitable chapters (signals exit for NORTH)
/datum/serpent_dimension_manager/proc/get_next_visitable_chapter(current_chapter, direction)
	var/step = (direction == NORTH) ? -1 : 1
	var/check = current_chapter + step

	while(check >= 1 && check <= current_max_chapter)
		if(is_visitable(check))
			return check
		check += step

	// Reached boundary
	if(direction == NORTH && check < 1)
		return 0  // Signal to exit (Chapter 0)
	return null  // No more chapters in this direction

/// Gets the appropriate template for a chapter number using chapter datums
/datum/serpent_dimension_manager/proc/get_template_for_chapter(chapter_num)
	var/datum/serpent_chapter/chapter = get_chapter_datum(chapter_num)
	return get_or_create_template_from_path(chapter.mappath)

/// Gets a template from cache or creates it from a mappath string
/datum/serpent_dimension_manager/proc/get_or_create_template_from_path(mappath)
	if(template_cache[mappath])
		return template_cache[mappath]

	var/datum/map_template/serpents_book/new_template = new()
	new_template.mappath = mappath
	template_cache[mappath] = new_template
	return new_template

// =============================================================================
// PHASE 6: PUZZLE SYSTEM
// =============================================================================

/// Checks if a chapter is a puzzle room using the chapter datum
/datum/serpent_dimension_manager/proc/is_puzzle_chapter(chapter_num)
	var/datum/serpent_chapter/chapter = get_chapter_datum(chapter_num)
	return chapter.is_puzzle

/// Gets or creates the puzzle for a chapter
/datum/serpent_dimension_manager/proc/get_puzzle_for_chapter(chapter_num)
	var/chapter_key = "[chapter_num]"
	if(active_puzzles[chapter_key])
		return active_puzzles[chapter_key]

	// Create new puzzle for this chapter
	var/datum/serpent_puzzle/puzzle = new()
	puzzle.chapter_number = chapter_num
	puzzle.manager = src
	active_puzzles[chapter_key] = puzzle
	return puzzle

/// Checks if the puzzle for a chapter is solved
/datum/serpent_dimension_manager/proc/is_puzzle_solved(chapter_num)
	var/chapter_key = "[chapter_num]"
	var/datum/serpent_puzzle/puzzle = active_puzzles[chapter_key]
	if(!puzzle)
		return TRUE  // No puzzle = not locked
	return puzzle.solved

/// Called when a puzzle is solved - unlocks the north door
/datum/serpent_dimension_manager/proc/on_puzzle_solved(chapter_num)
	var/chapter_key = "[chapter_num]"
	var/datum/turf_reservation/reservation = active_rooms[chapter_key]
	if(!reservation)
		return

	// Find and unlock all north doors in the room
	var/turf/bottom_left = locate(
		reservation.bottom_left_coords[1],
		reservation.bottom_left_coords[2],
		reservation.bottom_left_coords[3]
	)
	var/area/serpents_library/chapter_area = get_area(bottom_left)
	if(!chapter_area)
		return

	for(var/obj/structure/serpent_door/door in chapter_area)
		if(door.direction == NORTH)
			door.locked = FALSE
			door.visible_message(span_notice("The ancient mechanism unlocks with a heavy clunk!"))
			playsound(door, 'sound/machines/boltsup.ogg', 50, TRUE)

/// Sets up puzzle room when loaded (locks north door)
/datum/serpent_dimension_manager/proc/setup_puzzle_room(chapter_num, datum/turf_reservation/reservation)
	if(!is_puzzle_chapter(chapter_num))
		return

	// Create puzzle if not exists
	var/datum/serpent_puzzle/puzzle = get_puzzle_for_chapter(chapter_num)

	// If puzzle not solved, lock the north door
	if(!puzzle.solved)
		var/turf/bottom_left = locate(
			reservation.bottom_left_coords[1],
			reservation.bottom_left_coords[2],
			reservation.bottom_left_coords[3]
		)
		var/area/serpents_library/chapter_area = get_area(bottom_left)
		if(!chapter_area)
			return

		for(var/obj/structure/serpent_door/door in chapter_area)
			if(door.direction == NORTH)
				door.locked = TRUE

/// Debug: Directly teleports a mob to a specific chapter (bypasses auto-skip)
/datum/serpent_dimension_manager/proc/debug_jump_to_chapter(mob/living/user, target_chapter)
	if(!user || !isliving(user))
		return

	var/current_chapter = player_chapters[user]
	if(!current_chapter)
		return

	// Ensure templates are loaded
	load_templates()

	var/current_key = "[current_chapter]"
	var/target_key = "[target_chapter]"

	// Determine direction based on target vs current chapter
	var/direction = (target_chapter < current_chapter) ? NORTH : SOUTH

	// Case 1: Target room already loaded
	if(active_rooms[target_key])
		teleport_to_chapter(user, target_chapter, direction)
		return

	// Get current room occupants
	var/list/current_occupants = room_occupants[current_key]
	if(!current_occupants)
		current_occupants = list()

	// Case 2: Reuse current reservation if room will be empty
	if(length(current_occupants) <= 1)
		var/datum/turf_reservation/reservation = active_rooms[current_key]
		if(reservation)
			store_room(current_chapter)
			load_chapter_into_reservation(reservation, target_chapter)

			active_rooms[target_key] = reservation
			active_rooms -= current_key
			room_occupants -= current_key
			room_occupants[target_key] = list(user)
			player_chapters[user] = target_chapter

			var/turf/landing = get_door_landing_turf(reservation, direction)
			user.forceMove(landing)
			return

	// Case 3: Allocate new reservation
	var/datum/turf_reservation/new_reservation = SSmapping.RequestBlockReservation(20, 20)
	if(!new_reservation)
		return

	load_chapter_into_reservation(new_reservation, target_chapter)

	active_rooms[target_key] = new_reservation
	if(current_occupants)
		current_occupants -= user
	room_occupants[target_key] = list(user)
	player_chapters[user] = target_chapter

	var/turf/landing = get_door_landing_turf(new_reservation, direction)
	user.forceMove(landing)

// =============================================================================
// BOOK ITEM (Phase 2)
// =============================================================================

/obj/item/serpents_book
	name = "Serpent's Book"
	desc = "An ancient tome bound in scaled leather. Strange whispers emanate from within its pages."
	icon = 'icons/obj/library.dmi'
	icon_state = "book"
	w_class = WEIGHT_CLASS_NORMAL
	/// Is the book currently pulling players?
	var/active = FALSE
	/// Pull range in tiles
	var/pull_range = 5
	/// Reference to dimension manager
	var/datum/serpent_dimension_manager/dimension_manager

/obj/item/serpents_book/Initialize()
	. = ..()
	// Dimension manager is created here, but templates are loaded lazily
	// when capture_players() is called to avoid sleeping in Initialize
	dimension_manager = new /datum/serpent_dimension_manager(src)

/obj/item/serpents_book/Destroy()
	if(dimension_manager)
		QDEL_NULL(dimension_manager)
	return ..()

/obj/item/serpents_book/examine(mob/user)
	. = ..()
	. += span_warning("Using this item will attempt to capture nearby players into a pocket dimension.")
	. += span_notice("Pull range: [pull_range] tiles.")

/obj/item/serpents_book/attack_self(mob/living/user)
	. = ..()
	if(active)
		to_chat(user, span_warning("The book is already active!"))
		return

	// Warning dialog
	var/confirm = alert(user, "Open the Serpent's Book? This will attempt to capture all nearby living creatures.", "Serpent's Book", "Open", "Cancel")
	if(confirm != "Open")
		return

	// Check if still holding the book
	if(!user.is_holding(src))
		to_chat(user, span_warning("You need to be holding the book to use it!"))
		return

	// Confirmation delay
	to_chat(user, span_danger("You begin to open the ancient tome..."))
	if(!do_after(user, 3 SECONDS, src))
		to_chat(user, span_notice("You close the book."))
		return

	// Activate the book
	activate_book(user)

/// Activates the book's capture sequence
/obj/item/serpents_book/proc/activate_book(mob/living/user)
	active = TRUE

	// Drop and anchor the book
	user.dropItemToGround(src)
	anchored = TRUE

	// Hover animation
	animate(src, pixel_y = 16, time = 5)
	playsound(src, 'sound/effects/phasein.ogg', 50, TRUE)

	// Find all carbons in range
	var/list/mob/living/carbon/targets = list()
	var/turf/center = get_turf(src)

	for(var/mob/living/carbon/C in range(pull_range, center))
		if(C.stat == DEAD)
			continue
		targets += C

	if(!length(targets))
		to_chat(user, span_notice("There is no one nearby to capture..."))
		finish_activation()
		return

	// Pull sequence
	to_chat(user, span_userdanger("The book opens! Pages fly outward!"))

	// Pull all targets toward the book
	for(var/i = 1 to 5)
		for(var/mob/living/carbon/target in targets)
			if(get_dist(target, src) > 0)
				step_towards(target, src)
		sleep(2)

	// Capture all targets that reached the book
	var/list/mob/living/carbon/captured = list()
	for(var/mob/living/carbon/target in targets)
		if(get_dist(target, src) <= 1)
			captured += target

	if(length(captured))
		// Teleport captured players into the dimension
		dimension_manager.capture_players(captured)
		visible_message(span_danger("[src] swallows [length(captured)] victim\s into its pages!"))
	else
		visible_message(span_notice("[src] snaps shut, having captured no one."))

	finish_activation()

/// Finishes the activation sequence
/obj/item/serpents_book/proc/finish_activation()
	// Fall animation
	animate(src, pixel_y = 0, time = 5)
	sleep(5)

	anchored = FALSE
	active = FALSE

/obj/item/serpents_book/attack_hand(mob/user)
	if(active)
		to_chat(user, span_warning("The book is active and cannot be picked up!"))
		return
	return ..()

// =============================================================================
// NAVIGATION DOORS (Phase 2 - Prep for Phase 3)
// =============================================================================

/obj/structure/serpent_door
	name = "chapter door"
	desc = "A heavy door marked with serpentine patterns. It leads to another chapter."
	icon = 'ModularLobotomy/_Lobotomyicons/chain_door.dmi'
	icon_state = "regret_door"
	anchored = TRUE
	density = TRUE
	opacity = TRUE
	resistance_flags = INDESTRUCTIBLE
	/// NORTH (toward chapter 0) or SOUTH (toward higher chapters)
	var/direction = NORTH
	/// Whether puzzle lock prevents opening
	var/locked = FALSE
	/// Reference to dimension manager
	var/datum/serpent_dimension_manager/manager
	/// Which chapter this door is in
	var/chapter_number = 0

/obj/structure/serpent_door/Initialize()
	. = ..()
	// Set name and desc based on direction
	if(direction == NORTH)
		name = "north chapter door"
		desc = "A heavy door marked with serpentine patterns. It leads deeper into the book, toward Chapter 0."
	else
		name = "south chapter door"
		desc = "A heavy door marked with serpentine patterns. It leads back toward the book's beginning."

/obj/structure/serpent_door/examine(mob/user)
	. = ..()
	if(locked)
		. += span_warning("Ancient mechanisms hold this door firmly shut.")
	if(direction == NORTH)
		. += span_notice("Going through will take you closer to Chapter 0 - the exit.")
	else
		. += span_notice("Going through will take you further from the exit.")

/obj/structure/serpent_door/attack_hand(mob/living/user)
	. = ..()
	if(!isliving(user))
		return

	if(locked)
		to_chat(user, span_warning("The door is sealed by an ancient mechanism. You must solve the puzzle first..."))
		playsound(src, 'sound/machines/buzz-sigh.ogg', 30, TRUE)
		return

	if(!manager)
		to_chat(user, span_warning("The door seems disconnected from reality..."))
		return

	// Play door sound
	playsound(src, 'sound/machines/airlock.ogg', 30, TRUE)

	// Navigate to next chapter
	manager.navigate_chapter(user, direction)

/obj/structure/serpent_door/south
	direction = SOUTH

// =============================================================================
// PUZZLE DATUM (Phase 6)
// =============================================================================

/datum/serpent_puzzle
	/// Chapter number this puzzle is for
	var/chapter_number = 0
	/// Reference to parent manager
	var/datum/serpent_dimension_manager/manager
	/// Whether the puzzle has been solved
	var/solved = FALSE
	/// Puzzle type identifier
	var/puzzle_type = "generic"

/datum/serpent_puzzle/Destroy()
	manager = null
	return ..()

/// Called to check if the puzzle is solved (override in subtypes)
/datum/serpent_puzzle/proc/check_solution()
	return solved

/// Called when the puzzle is solved
/datum/serpent_puzzle/proc/on_solve()
	if(solved)
		return
	solved = TRUE
	if(manager)
		manager.on_puzzle_solved(chapter_number)

/// Called when the puzzle fails (override in subtypes for traps)
/datum/serpent_puzzle/proc/on_fail()
	return

// Lever puzzle - pull levers in the correct order
/datum/serpent_puzzle/levers
	puzzle_type = "levers"
	/// The correct order of lever IDs
	var/list/correct_order = list("A", "B", "C", "D")
	/// Current sequence of pulled levers
	var/list/current_sequence = list()

/datum/serpent_puzzle/levers/check_solution()
	if(length(current_sequence) != length(correct_order))
		return FALSE
	for(var/i = 1 to length(correct_order))
		if(current_sequence[i] != correct_order[i])
			return FALSE
	return TRUE

/// Called when a lever is pulled
/datum/serpent_puzzle/levers/proc/lever_pulled(lever_id)
	current_sequence += lever_id

	// Check if we have enough levers pulled
	if(length(current_sequence) >= length(correct_order))
		if(check_solution())
			on_solve()
		else
			on_fail()
			// Reset sequence on failure
			current_sequence = list()

// =============================================================================
// PUZZLE INTERACTABLES (Phase 6)
// =============================================================================

/obj/structure/serpent_lever
	name = "ancient lever"
	desc = "A weathered lever protruding from the wall. It's part of some mechanism."
	icon = 'icons/obj/objects.dmi'
	icon_state = "psychedelicflip1"
	anchored = TRUE
	density = FALSE
	/// Lever identifier for puzzle tracking
	var/lever_id = "A"
	/// Reference to the puzzle this lever belongs to
	var/datum/serpent_puzzle/levers/puzzle
	/// Whether the lever has been pulled
	var/pulled = FALSE

/obj/structure/serpent_lever/Initialize()
	. = ..()
	// Try to find puzzle from area manager
	var/area/serpents_library/lib = get_area(src)
	if(istype(lib) && lib.parent_manager)
		var/datum/serpent_puzzle/levers/found_puzzle = lib.parent_manager.active_puzzles["[lib.chapter_number]"]
		if(istype(found_puzzle))
			puzzle = found_puzzle

/obj/structure/serpent_lever/examine(mob/user)
	. = ..()
	. += span_notice("This lever is marked with the symbol '[lever_id]'.")
	if(pulled)
		. += span_notice("It has been pulled down.")
	else
		. += span_notice("It is in the up position.")

/obj/structure/serpent_lever/attack_hand(mob/living/user)
	. = ..()
	if(!isliving(user))
		return

	if(pulled)
		to_chat(user, span_notice("The lever is already pulled."))
		return

	// Pull the lever
	pulled = TRUE
	icon_state = "yourfacewhen"  // Different state when pulled
	playsound(src, 'sound/machines/click.ogg', 50, TRUE)
	visible_message(span_notice("[user] pulls the lever marked '[lever_id]'."))

	// Notify puzzle
	if(puzzle)
		puzzle.lever_pulled(lever_id)
	else
		// Try to find puzzle again (might have been created after lever initialized)
		var/area/serpents_library/lib = get_area(src)
		if(istype(lib) && lib.parent_manager)
			var/datum/serpent_puzzle/levers/found_puzzle = lib.parent_manager.active_puzzles["[lib.chapter_number]"]
			if(istype(found_puzzle))
				puzzle = found_puzzle
				puzzle.lever_pulled(lever_id)

/// Resets the lever to unpulled state
/obj/structure/serpent_lever/proc/reset()
	pulled = FALSE
	icon_state = "psychedelicflip1"

// Lever variants for mapping
/obj/structure/serpent_lever/B
	lever_id = "B"

/obj/structure/serpent_lever/C
	lever_id = "C"

/obj/structure/serpent_lever/D
	lever_id = "D"

// =============================================================================
// DEBUG VERB (Phase 1 - for testing)
// =============================================================================

/client/proc/debug_serpent_book()
	set name = "Debug Serpent Book"
	set category = "Debug"

	if(!check_rights(R_DEBUG))
		return

	var/choice = input(mob, "What would you like to do?", "Serpent Book Debug") as null|anything in list(
		"Spawn Book",
		"Teleport to Test Room",
		"Eject from Book",
		"Show Current Chapter",
		"List Active Rooms",
		"List Visitable Chapters",
		"List Chapter Registry",
		"Solve Current Puzzle",
		"Jump to Chapter"
	)

	switch(choice)
		if("Spawn Book")
			new /obj/item/serpents_book(get_turf(mob))
			to_chat(mob, span_notice("Spawned Serpent's Book at your location."))

		if("Teleport to Test Room")
			// Create a test room directly using default chapter settings
			var/datum/turf_reservation/reservation = SSmapping.RequestBlockReservation(20, 20)
			if(!reservation)
				to_chat(mob, span_warning("Failed to allocate room!"))
				return

			var/datum/serpent_chapter/default = new /datum/serpent_chapter/default()
			var/datum/map_template/serpents_book/dbg_template = new()
			dbg_template.mappath = default.mappath

			var/turf/bottom_left = locate(
				reservation.bottom_left_coords[1],
				reservation.bottom_left_coords[2],
				reservation.bottom_left_coords[3]
			)
			dbg_template.load(bottom_left)

			var/turf/landing = locate(
				reservation.bottom_left_coords[1] + default.spawn_x,
				reservation.bottom_left_coords[2] + default.spawn_y,
				reservation.bottom_left_coords[3]
			)

			mob.forceMove(landing)
			qdel(default)
			to_chat(mob, span_notice("Teleported to test room."))

		if("Eject from Book")
			// Find if player is in a serpent library
			var/area/serpents_library/lib = get_area(mob)
			if(istype(lib) && lib.parent_manager)
				lib.parent_manager.eject_all_players()
				to_chat(mob, span_notice("Ejected all players from the book."))
			else
				to_chat(mob, span_warning("You are not in a Serpent's Library!"))

		if("Show Current Chapter")
			var/area/serpents_library/lib = get_area(mob)
			if(istype(lib) && lib.parent_manager)
				var/datum/serpent_dimension_manager/manager = lib.parent_manager
				var/chapter = manager.player_chapters[mob]
				if(chapter)
					to_chat(mob, span_notice("You are in Chapter [chapter]."))
					to_chat(mob, span_notice("Max chapter: [manager.current_max_chapter]"))
					to_chat(mob, span_notice("Is visitable: [manager.is_visitable(chapter)]"))
					to_chat(mob, span_notice("Is puzzle room: [manager.is_puzzle_chapter(chapter)]"))
					if(manager.is_puzzle_chapter(chapter))
						to_chat(mob, span_notice("Puzzle solved: [manager.is_puzzle_solved(chapter)]"))
					var/next_north = manager.get_next_visitable_chapter(chapter, NORTH)
					var/next_south = manager.get_next_visitable_chapter(chapter, SOUTH)
					to_chat(mob, span_notice("Next chapter NORTH: [next_north ? next_north : "EXIT"]"))
					to_chat(mob, span_notice("Next chapter SOUTH: [next_south ? next_south : "NONE"]"))
				else
					to_chat(mob, span_warning("You are not tracked as being in a chapter."))
			else
				to_chat(mob, span_warning("You are not in a Serpent's Library!"))

		if("List Active Rooms")
			var/area/serpents_library/lib = get_area(mob)
			if(istype(lib) && lib.parent_manager)
				var/datum/serpent_dimension_manager/manager = lib.parent_manager
				to_chat(mob, span_notice("Active Rooms:"))
				for(var/chapter_key in manager.active_rooms)
					var/list/occupants = manager.room_occupants[chapter_key]
					var/occupant_count = occupants ? length(occupants) : 0
					var/is_puzzle = manager.is_puzzle_chapter(text2num(chapter_key))
					to_chat(mob, span_notice("  Chapter [chapter_key]: [occupant_count] occupant(s)[is_puzzle ? " (PUZZLE)" : ""]"))
				to_chat(mob, span_notice("Stored Room States: [length(manager.stored_room_states)]"))
				to_chat(mob, span_notice("Personal Chapters: [manager.personal_chapters.Join(", ")]"))
			else
				to_chat(mob, span_warning("You are not in a Serpent's Library!"))

		if("List Visitable Chapters")
			var/area/serpents_library/lib = get_area(mob)
			if(istype(lib) && lib.parent_manager)
				var/datum/serpent_dimension_manager/manager = lib.parent_manager
				var/list/first_20 = manager.visitable_chapters.Copy(1, min(21, length(manager.visitable_chapters)+1))
				to_chat(mob, span_notice("Visitable Chapters (first 20): [first_20.Join(", ")]"))
				// Build puzzle chapters list from chapter registry
				var/list/puzzle_nums = list()
				for(var/chapter_key in manager.chapter_registry)
					var/datum/serpent_chapter/C = manager.chapter_registry[chapter_key]
					if(C.is_puzzle)
						puzzle_nums += C.chapter_number
				to_chat(mob, span_notice("Puzzle Chapters: [puzzle_nums.Join(", ")]"))
				to_chat(mob, span_notice("Total visitable: [length(manager.visitable_chapters)]"))
			else
				to_chat(mob, span_warning("You are not in a Serpent's Library!"))

		if("List Chapter Registry")
			var/area/serpents_library/lib = get_area(mob)
			if(!istype(lib) || !lib.parent_manager)
				to_chat(mob, span_warning("You are not in a Serpent's Library!"))
				return

			var/datum/serpent_dimension_manager/manager = lib.parent_manager
			to_chat(mob, span_notice("Chapter Registry ([length(manager.chapter_registry)] chapters):"))
			for(var/chapter_key in manager.chapter_registry)
				var/datum/serpent_chapter/C = manager.chapter_registry[chapter_key]
				var/puzzle_str = C.is_puzzle ? " (PUZZLE: [C.puzzle_type])" : ""
				to_chat(mob, span_notice("  Chapter [C.chapter_number]: [C.mappath] spawn([C.spawn_x],[C.spawn_y])[puzzle_str]"))
			to_chat(mob, span_notice("Default chapter: [manager.default_chapter?.mappath]"))

		if("Solve Current Puzzle")
			var/area/serpents_library/lib = get_area(mob)
			if(!istype(lib) || !lib.parent_manager)
				to_chat(mob, span_warning("You are not in a Serpent's Library!"))
				return

			var/datum/serpent_dimension_manager/manager = lib.parent_manager
			var/chapter = manager.player_chapters[mob]
			if(!chapter)
				to_chat(mob, span_warning("You are not tracked as being in a chapter."))
				return

			if(!manager.is_puzzle_chapter(chapter))
				to_chat(mob, span_warning("This is not a puzzle room."))
				return

			var/datum/serpent_puzzle/puzzle = manager.get_puzzle_for_chapter(chapter)
			puzzle.on_solve()
			to_chat(mob, span_notice("Puzzle solved!"))

		if("Jump to Chapter")
			var/area/serpents_library/lib = get_area(mob)
			if(!istype(lib) || !lib.parent_manager)
				to_chat(mob, span_warning("You are not in a Serpent's Library!"))
				return

			var/datum/serpent_dimension_manager/manager = lib.parent_manager
			var/target = input(mob, "Enter chapter number to jump to:", "Jump to Chapter") as num|null
			if(!target)
				return

			if(target < 1 || target > manager.current_max_chapter)
				to_chat(mob, span_warning("Invalid chapter number!"))
				return

			// Direct teleport using debug_jump_to_chapter
			manager.debug_jump_to_chapter(mob, target)
			to_chat(mob, span_notice("Jumped to Chapter [target]."))
