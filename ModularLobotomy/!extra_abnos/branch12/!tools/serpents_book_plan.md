# Serpent's Book Implementation Plan

## Overview
Create a new WAW-tier relic item inspired by Bibliomania that captures players into a pocket dimension. Players must travel through 100 pre-made chapters to reach Chapter 0 (the exit), becoming increasingly cursed as they approach freedom.

**Key Parameters:**
- Pull range: 5 tiles
- Base chapters: 180 (pre-existing in book)
- Dynamic entry chapters: +1 per captured player
- Exit: Chapter 0
- Visitable chapters: 100 pre-made rooms
- Max dynamic chapters: 666
- Threat level: WAW

---

## Chapter Structure

### Dynamic Entry System
When the book captures players, it creates a **personal chapter for each captured player** at the top of the book:

```
Example: Book captures 3 players

Chapter 183 ← Player 1's personal entry room (newly created)
Chapter 182 ← Player 2's personal entry room (newly created)
Chapter 181 ← Player 3's personal entry room (newly created)
    ↓
Chapter 180 ← Original top of the book
    ↓
[80 chapters with gaps - only ~50 visitable rooms]
    ↓
Chapter 100
    ↓
[100 chapters - ~50 visitable rooms, puzzles increase near 0]
    ↓
Chapter 0 ← EXIT (teleport back to book)
```

### Personal Entry Rooms
- Each captured player spawns **alone** in their own chapter
- Personal chapters use a standard room template (not unique per player)
- Players must navigate down through the north door to eventually meet up
- Creates tension: "Am I alone? Where are the others?"

### Visitable vs Non-Visitable Chapters
- **180 base chapters** exist in the book
- **+N dynamic chapters** created for N captured players
- **Only 100 pre-made rooms** are visitable (plus personal entry rooms)
- Non-visitable chapters are **automatically skipped** when using the north door
- This creates the feeling of a massive tome without needing all unique maps

### Auto-Skip Navigation
When a player uses the **north door**:
1. Calculate the next chapter number (current - 1)
2. Check if that chapter is visitable (has a pre-made room)
3. If NOT visitable, find the next visitable chapter and skip to it
4. Display message: "Pages blur past as you descend through empty chapters..."

Example visitable chapter distribution:
```
180 (entry), 175, 170, 165, 160...  ← Sparse at start (every 5)
...50, 48, 46, 44, 42...            ← Denser in middle (every 2)
...25, 24, 23, 22, 21...            ← Every chapter near end
...5, 4, 3, 2, 1, 0 (exit)          ← Final stretch
```

### Puzzle Rooms
Certain pre-made chapters have the north door locked until a puzzle is solved:
- Puzzle types: lever sequences, pressure plates, item placement, symbol matching
- Puzzle rooms become more common closer to Chapter 0
- Failed puzzles may trigger traps or spawn enemies

---

## Curse System

### Zombie Limb Curse
As players progress toward Chapter 0, the book's curse manifests:

| Chapter Range | Curse Level | Effect |
|---------------|-------------|--------|
| 180-121 | None | No curse effects |
| 120-81 | Minor | One random limb becomes zombie |
| 80-41 | Moderate | Two limbs become zombie |
| 40-21 | Severe | Three limbs become zombie |
| 20-1 | Critical | All four limbs become zombie |
| 0 (Exit) | Cleansed | Curse removed on exit |

### Implementation
```dm
/datum/serpent_dimension_manager/proc/apply_curse(mob/living/carbon/human/H, chapter_num)
    var/curse_level = get_curse_level(chapter_num)
    var/list/limb_order = list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)

    for(var/i = 1 to curse_level)
        var/zone = limb_order[i]
        // Replace limb with zombie variant
        replace_limb_with_zombie(H, zone)
```

---

## Simplified Chapter Datum System

Each chapter is defined by a simple datum that specifies its DMM file and spawn location.

### Chapter Datum Structure
```dm
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
    /// Puzzle type if is_puzzle is TRUE
    var/puzzle_type = null

// Example chapter definitions - easy to add new chapters
/datum/serpent_chapter/chapter_180
    chapter_number = 180
    mappath = "_maps/templates/serpents_book/serpents_chapter_180.dmm"
    spawn_x = 10
    spawn_y = 10

/datum/serpent_chapter/chapter_175
    chapter_number = 175
    mappath = "_maps/templates/serpents_book/serpents_standard_01.dmm"

/datum/serpent_chapter/chapter_60
    chapter_number = 60
    mappath = "_maps/templates/serpents_book/serpents_puzzle_01.dmm"
    is_puzzle = TRUE
    puzzle_type = "levers"
```

### How to Add a New Chapter
1. Create a 20x20 DMM file in `_maps/templates/serpents_book/`
2. Add a new `/datum/serpent_chapter/chapter_XXX` subtype
3. Set `chapter_number`, `mappath`, and optionally `spawn_x`/`spawn_y`
4. The chapter is automatically registered and usable

### Chapter Registry
The dimension manager automatically discovers all chapter datums on init:
```dm
/datum/serpent_dimension_manager/proc/register_chapters()
    for(var/chapter_type in subtypesof(/datum/serpent_chapter))
        var/datum/serpent_chapter/C = new chapter_type()
        chapter_registry["[C.chapter_number]"] = C
        if(C.chapter_number in visitable_chapters)
            // Chapter has a DMM assigned
```

---

## Room State Storage System

When a player leaves a room, all items and structures are stored with their **relative coordinates** and **direction**, then restored when returning.

### Storage Data Structure
```dm
/datum/stored_room_state
    /// Chapter number this state is for
    var/chapter_number = 0
    /// List of stored object data
    var/list/stored_objects = list()
    // Each entry: list("type" = /obj/item/foo, "rel_x" = 3, "rel_y" = -2, "dir" = SOUTH, "vars" = list(...))
```

### Coordinate System
All coordinates are stored **relative to the spawn point** (center of room):
```
Spawn point (10, 10) = relative (0, 0)

Example: Item at absolute (13, 8) in room
- Relative X = 13 - 10 = +3 (3 tiles east of spawn)
- Relative Y = 8 - 10 = -2 (2 tiles south of spawn)
- Stored as: rel_x = 3, rel_y = -2

When restoring to a new reservation with spawn at (50, 60):
- Absolute X = 50 + 3 = 53
- Absolute Y = 60 + (-2) = 58
```

### What Gets Stored
- **Items** (`/obj/item`): type, relative coords, dir, name (if renamed)
- **Structures** (`/obj/structure`): type, relative coords, dir
- **NOT stored**: mobs, abstract items, template objects (doors, walls)

### store_room() Implementation
```dm
/datum/serpent_dimension_manager/proc/store_room(chapter_num)
    var/chapter_key = "[chapter_num]"
    var/datum/turf_reservation/reservation = active_rooms[chapter_key]
    if(!reservation)
        return

    // Get spawn point for relative coordinate calculation
    var/spawn_x = reservation.bottom_left_coords[1] + template.landing_x
    var/spawn_y = reservation.bottom_left_coords[2] + template.landing_y

    // Create or get storage state
    var/datum/stored_room_state/state = stored_room_states[chapter_key]
    if(!state)
        state = new()
        state.chapter_number = chapter_num
        stored_room_states[chapter_key] = state
    state.stored_objects = list()  // Clear previous

    // Iterate through all turfs in reservation
    for(var/i = 0 to 19)
        for(var/j = 0 to 19)
            var/turf/T = locate(
                reservation.bottom_left_coords[1] + i,
                reservation.bottom_left_coords[2] + j,
                reservation.bottom_left_coords[3]
            )
            if(!T)
                continue

            for(var/atom/movable/AM in T.contents)
                if(ismob(AM))
                    continue
                if(is_template_object(AM))
                    continue  // Don't store doors, etc.

                // Calculate relative coordinates
                var/rel_x = T.x - spawn_x
                var/rel_y = T.y - spawn_y

                // Store object data
                var/list/obj_data = list(
                    "type" = AM.type,
                    "rel_x" = rel_x,
                    "rel_y" = rel_y,
                    "dir" = AM.dir,
                    "name" = AM.name
                )
                state.stored_objects += list(obj_data)

                // Delete the original (or move to nullspace)
                qdel(AM)
```

### restore_room() Implementation
```dm
/datum/serpent_dimension_manager/proc/restore_room(chapter_num, datum/turf_reservation/reservation)
    var/chapter_key = "[chapter_num]"
    var/datum/stored_room_state/state = stored_room_states[chapter_key]
    if(!state || !length(state.stored_objects))
        return

    // Get spawn point for absolute coordinate calculation
    var/spawn_x = reservation.bottom_left_coords[1] + template.landing_x
    var/spawn_y = reservation.bottom_left_coords[2] + template.landing_y
    var/z_level = reservation.bottom_left_coords[3]

    // Restore each object
    for(var/list/obj_data in state.stored_objects)
        var/obj_type = obj_data["type"]
        var/rel_x = obj_data["rel_x"]
        var/rel_y = obj_data["rel_y"]
        var/obj_dir = obj_data["dir"]
        var/obj_name = obj_data["name"]

        // Calculate absolute position
        var/abs_x = spawn_x + rel_x
        var/abs_y = spawn_y + rel_y
        var/turf/target = locate(abs_x, abs_y, z_level)

        if(!target)
            continue

        // Create the object
        var/atom/movable/AM = new obj_type(target)
        AM.dir = obj_dir
        if(obj_name)
            AM.name = obj_name
```

### Benefits of Relative Coordinates
1. **Room can load at any reservation location** - coordinates are portable
2. **Spawn point is always (0,0)** - easy to visualize
3. **Direction is preserved** - objects face the same way when restored
4. **Simple math** - just addition/subtraction from spawn point

---

## Key Reference: Hilbert's Hotel
The codebase already has a nearly identical system in `code/modules/ruins/spaceruin_code/hilbertshotel.dm`:
- Dynamic room allocation via `SSmapping.RequestBlockReservation()`
- Room state serialization in `storeRoom()` using abstract storage objects
- Active/stored room tracking with `activeRooms` and `storedRooms` lists
- Template-based room loading

---

## Technical: Turf Reservation System

### How `SSmapping.RequestBlockReservation()` Works
Requests a block of turfs on a reserved Z-level for dynamic room allocation:
```dm
var/datum/turf_reservation/reservation = SSmapping.RequestBlockReservation(20, 20)
```

The returned `datum/turf_reservation` contains:
- `bottom_left_coords` - List of `[x, y, z]` for the bottom-left corner
- `top_right_coords` - List of `[x, y, z]` for the top-right corner

### Getting the Bottom-Left Turf
To get a turf reference from the reservation coordinates:
```dm
var/turf/bottom_left = locate(
    reservation.bottom_left_coords[1],  // X coordinate
    reservation.bottom_left_coords[2],  // Y coordinate
    reservation.bottom_left_coords[3]   // Z level
)
```

`locate(x, y, z)` is a BYOND built-in that returns the turf at those world coordinates.

### Loading a Template into a Reservation
```dm
var/datum/map_template/serpents_book/template = new()
template.load(bottom_left)  // Loads the .dmm file starting at bottom_left turf
```

### Iterating Through All Turfs in a 20x20 Reservation
```dm
for(var/i = 0 to 19)  // 20 tiles wide (0-19)
    for(var/j = 0 to 19)  // 20 tiles tall (0-19)
        var/turf/T = locate(
            reservation.bottom_left_coords[1] + i,
            reservation.bottom_left_coords[2] + j,
            reservation.bottom_left_coords[3]
        )
        // Do something with turf T (store contents, clear, etc.)
```

### Cleaning Up a Reservation
When a room is no longer needed, delete the reservation to free the space:
```dm
qdel(reservation)
```

---

## File Structure

### New Files
```
ModularLobotomy/!extra_abnos/branch12/!tools/serpents_book.dm

_maps/templates/serpents_book/
  # Personal entry room template (used for each captured player's chapter)
  serpents_personal_entry.dmm

  # Standard rooms (used for visitable chapters in base 180)
  # Each has north door and south door for navigation
  serpents_standard_01.dmm through serpents_standard_80.dmm

  # Puzzle rooms (north door locked until puzzle solved)
  serpents_puzzle_01.dmm through serpents_puzzle_15.dmm

  # Exit room (Chapter 0)
  serpents_chapter_0.dmm

  # Empty template for dynamic room clearing
  serpents_empty.dmm
```

**Note**: 100 pre-made rooms total:
- 1 personal entry template (reused for each captured player)
- 80 standard rooms
- 15 puzzle rooms
- 1 exit room (Chapter 0)
- 3 special/unique rooms

### Modified Files
```
lobotomy-corp13.dme - Add include for serpents_book.dm
```

---

## Core Components

### 1. Book Item (`/obj/item/serpents_book`)
- Pickable WAW-tier item with warning dialog on use
- Activation sequence:
  1. `do_after()` confirmation delay
  2. Drop to ground, set `anchored = TRUE`
  3. Hover animation (pixel_y adjustment + icon change)
  4. Pull all living carbons within 5 tiles using `step_towards()` loop
  5. For each captured player:
     - Create a new personal chapter (181, 182, 183, etc.)
     - Teleport that player to their personal chapter alone
  6. Fall animation, set `anchored = FALSE`
- While active: override `attack_hand()` to prevent pickup
- Each player starts **isolated** in their own chapter at the top of the book

### 2. Dimension Manager (`/datum/serpent_dimension_manager`)
```dm
var/list/active_rooms = list()           // chapter_num -> turf_reservation
var/list/stored_room_states = list()     // chapter_num -> /datum/stored_room_state
var/list/player_chapters = list()        // mob -> current chapter
var/list/room_occupants = list()         // chapter_num -> list of mobs
var/list/chapter_registry = list()       // chapter_num -> /datum/serpent_chapter (auto-populated)
var/list/visitable_chapters = list()     // List of chapter numbers that have rooms
var/list/personal_chapters = list()      // List of dynamically created entry chapters
var/list/puzzle_chapters = list()        // chapter_num -> puzzle datum
var/base_max_chapter = 180               // Original top of the book
var/current_max_chapter = 180            // Grows as players are captured
var/obj/item/serpents_book/parent_book
```

Key procs:
- `register_chapters()` - Auto-discover all /datum/serpent_chapter subtypes
- `get_chapter_datum(chapter_num)` - Get the chapter datum for a chapter number
- `capture_players(list/players)` - Create personal chapters and assign each player
- `navigate_chapter(mob/living/L, direction)` - Handle door transitions with auto-skip
- `get_next_visitable_chapter(current, direction)` - Find next visitable chapter, skipping gaps
- `is_visitable(chapter_num)` - Check if chapter has a registered datum OR is personal chapter
- `store_room(chapter_num)` - Store objects with relative coordinates and directions
- `restore_room(chapter_num, reservation)` - Restore objects to correct positions
- `apply_curse(mob/living/carbon/human/H, chapter_num)` - Apply zombie limbs
- `exit_dimension(mob/living/L)` - Return player to book, remove curse

### 3. Chapter Navigation Algorithm
All navigation is done through north/south doors only - no extra portal objects needed.

```
// Called when book captures players
capture_players(list/players):
    for each player in players:
        current_max_chapter++
        personal_chapters += current_max_chapter
        create_room_for_chapter(current_max_chapter)
        player.forceMove(room)
        player_chapters[player] = current_max_chapter
        to_chat(player, "You find yourself alone in Chapter [current_max_chapter]...")

navigate_chapter(mob/living/L, direction):
    current = player_chapters[L]

    // NORTH = toward chapter 0 (escape), SOUTH = toward max chapter
    if direction == NORTH:
        // Check puzzle lock before allowing north travel
        if is_puzzle_room(current) AND NOT puzzle_complete(current):
            to_chat(L, "The door remains sealed. You must solve the puzzle first...")
            return

        // Find next VISITABLE chapter (auto-skip non-visitable)
        target = get_next_visitable_chapter(current, NORTH)

        if target == null:  // Reached chapter 0
            exit_dimension(L)
            return

        // Show skip message if we jumped multiple chapters
        if (current - target) > 1:
            to_chat(L, "Pages blur past as you descend through empty chapters...")

    else:  // SOUTH - going back up
        target = get_next_visitable_chapter(current, SOUTH)

        if target == null OR target > current_max_chapter:
            to_chat(L, "There are no more chapters beyond this...")
            return

    // Apply curse based on new chapter
    apply_curse(L, target)

    // Case 1: Target already loaded by another player
    if active_rooms[target]:
        teleport L to active_rooms[target]
        update tracking
        return

    // Case 2: Current room empty after L leaves → reuse room
    if room_occupants[current].len == 1:
        store_room(current)
        load_chapter_into(active_rooms[current], target)
        active_rooms[target] = active_rooms[current]
        active_rooms[current] = null
        update tracking
        return

    // Case 3: Other players in current room → allocate new room
    new_reservation = SSmapping.RequestBlockReservation(20, 20)
    load_chapter_into(new_reservation, target)
    active_rooms[target] = new_reservation
    teleport L to new_reservation
    update tracking

// Helper: Find next visitable chapter in given direction
get_next_visitable_chapter(current, direction):
    step = (direction == NORTH) ? -1 : 1
    check = current + step

    while check >= 0 AND check <= current_max_chapter:
        if is_visitable(check):
            return check
        check += step

    // Reached boundary
    if direction == NORTH AND check < 0:
        return null  // Signal to exit
    return null  // No more chapters

// Check if a chapter is visitable
is_visitable(chapter_num):
    // Personal entry chapters are always visitable
    if chapter_num in personal_chapters:
        return TRUE
    // Pre-made chapters from the visitable list
    return chapter_num in visitable_chapters

// Visitable chapters list (100 pre-made rooms spread across base 180)
var/list/visitable_chapters = list(
    180, 175, 170, 165, 160, 155, 150, 145, 140, 135,  // Upper zone (every 5)
    130, 125, 120, 115, 110, 105, 100, 95, 90, 85,
    80, 78, 76, 74, 72, 70, 68, 66, 64, 62,            // Mid zone (every 2)
    60, 58, 56, 54, 52, 50, 48, 46, 44, 42,
    40, 38, 36, 34, 32, 30, 28, 26, 24, 22,
    20, 19, 18, 17, 16, 15, 14, 13, 12, 11,            // Dense zone (every 1)
    10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0                   // Final stretch + exit
)
```

### 4. Puzzle System (`/datum/serpent_puzzle`)
```dm
/datum/serpent_puzzle
    var/chapter_number
    var/solved = FALSE
    var/puzzle_type  // "levers", "pressure_plates", "symbols", etc.

    proc/check_solution()  // Returns TRUE if solved
    proc/on_solve()        // Unlock north door, play effects
    proc/on_fail()         // Trigger trap or spawn enemy
```

### 6. Navigation Doors (`/obj/structure/serpent_door`)
```dm
/obj/structure/serpent_door
    var/direction  // NORTH or SOUTH
    var/locked = FALSE  // Set by puzzle system
    var/datum/serpent_dimension_manager/manager

/obj/structure/serpent_door/attack_hand(mob/user)
    if(!isliving(user)) return
    if(locked)
        to_chat(user, "The door is sealed by an ancient mechanism...")
        return
    manager.navigate_chapter(user, direction)
```

### 7. Area and Turfs
```dm
/area/serpents_library
    name = "Serpent's Library"
    requires_power = FALSE
    has_gravity = TRUE
    area_flags = NOTELEPORT | HIDDEN_AREA

/turf/closed/indestructible/serpent_wall
/turf/open/indestructible/serpent_floor
```

---

## The Serpent (Player-Controlled Mob)

A player-controlled antagonist that hunts victims within the book dimension.

### Appearance
- **Head**: Snake/serpent head
- **Upper body**: Humanoid torso wearing a butler suit
- **Lower body**: Snake tail (no legs)
- Elegant but menacing appearance

### Base Mob (`/mob/living/simple_animal/hostile/serpent_librarian`)
Based on corroded cassowary pattern (`ModularLobotomy/associations/corroded_cassowary.dm`):
```dm
/mob/living/simple_animal/hostile/serpent_librarian
    name = "The Serpent"
    desc = "A serpentine figure in formal attire. Its cold eyes regard you with ancient hunger."

    // Item handling (like corroded cassowary)
    dextrous = TRUE
    held_items = list(null, null)
    possible_a_intents = list(INTENT_HELP, INTENT_GRAB, INTENT_DISARM, INTENT_HARM)

    // Stats
    maxHealth = 800
    health = 800
    melee_damage_lower = 25
    melee_damage_upper = 35

    // Reference to parent book
    var/obj/item/serpents_book/parent_book
    var/datum/serpent_dimension_manager/manager

    // Tail grab tracking
    var/mob/living/tail_victim = null
```

### Abilities

#### 1. Literacy (Passive)
```dm
/mob/living/simple_animal/hostile/serpent_librarian/is_literate()
    return TRUE  // Can read books, papers, etc.
```

#### 2. Tail Grab (`/datum/action/cooldown/serpent_ability/tail_grab`)
- Grab a player with the serpent's tail
- Victim is immobilized and dragged along when serpent moves
- Can release victim at will
- Only one victim at a time
```dm
/datum/action/cooldown/serpent_ability/tail_grab
    name = "Tail Constrict"
    desc = "Wrap your tail around a nearby victim, immobilizing them."
    cooldown_time = 5 SECONDS

/datum/action/cooldown/serpent_ability/tail_grab/Trigger()
    // If already holding someone, release them
    if(serpent.tail_victim)
        release_victim()
        return

    // Find adjacent living carbon
    for(var/mob/living/carbon/C in range(1, owner))
        if(C == owner) continue
        serpent.tail_victim = C
        C.Immobilize(INFINITY)  // Immobilize until released
        RegisterSignal(serpent, COMSIG_MOVABLE_MOVED, .proc/drag_victim)
        visible_message("[owner] wraps its tail around [C]!")
        break
```

#### 3. Chapter Warp (`/datum/action/cooldown/serpent_ability/chapter_warp`)
- Instantly teleport to any currently loaded chapter
- Opens UI showing all active rooms and their occupants
- Can also teleport to any chapter (loads it if needed)
```dm
/datum/action/cooldown/serpent_ability/chapter_warp
    name = "Chapter Warp"
    desc = "Traverse the book's pages instantly. See all active chapters and their occupants."
    cooldown_time = 10 SECONDS

/datum/action/cooldown/serpent_ability/chapter_warp/Trigger()
    // Show TGUI with:
    // - List of active_rooms with occupant count
    // - Option to warp to any chapter 0-100
    // - Dragged victim comes along

    var/list/choices = list()
    for(var/chapter in manager.active_rooms)
        var/occupants = length(manager.room_occupants[chapter])
        choices["Chapter [chapter] ([occupants] souls)"] = chapter

    var/choice = input(owner, "Which chapter?", "Chapter Warp") as null|anything in choices
    if(choice)
        manager.warp_serpent_to_chapter(owner, choices[choice])
```

#### 4. Serpent's Commune (`/datum/action/innate/serpent_ability/commune`)
- Send messages to all players in the book
- Ominous announcements that echo through all chapters
```dm
/datum/action/innate/serpent_ability/commune
    name = "Serpent's Whisper"
    desc = "Your voice echoes through every page of the book."

/datum/action/innate/serpent_ability/commune/Activate()
    var/message = input(owner, "What do you whisper?", "Serpent's Whisper")
    if(!message) return

    for(var/mob/M in manager.get_all_occupants())
        to_chat(M, span_danger("<i>A cold whisper echoes through the pages...</i>"))
        to_chat(M, span_danger("\"[message]\""))
```

### Serpent Spawning
- Spawns when the book first captures players
- Ghost role or assigned to a player
- Starts in a random chapter (not Chapter 100)
```dm
/obj/item/serpents_book/proc/spawn_serpent()
    var/turf/spawn_loc = get_random_chapter_turf(rand(20, 80))
    var/mob/living/simple_animal/hostile/serpent_librarian/S = new(spawn_loc)
    S.parent_book = src
    S.manager = dimension_manager

    // Offer to ghosts or assign to player
    notify_ghosts("The Serpent awakens in its library...")
```

### Serpent Victory Condition
- If the Serpent kills all players in the book, it can emerge
- Serpent cannot normally leave the book dimension

---

## Map Templates (20x20)

### Standard Room Layout
```
+--------------------+
|  WALL WALL WALL    |
|  [NORTH DOOR]      |  ← Toward Chapter 0 (escape)
|                    |     Auto-skips non-visitable chapters
|   Room contents    |
|   (varies by       |
|    template)       |
|                    |
|  [SOUTH DOOR]      |  ← Toward Chapter 180 (entry)
|  WALL WALL WALL    |     Auto-skips non-visitable chapters
+--------------------+
```

**Navigation Flow:**
- All travel is through north/south doors only
- No separate portal objects needed
- Doors automatically skip to next visitable chapter

### Room Types
1. **Entry Room (Chapter 180)**: Starting area, explains mechanics
2. **Standard Rooms**: 80 variants with library/book aesthetics
3. **Puzzle Rooms**: 15 variants, north door locked until puzzle solved
4. **Exit Room (Chapter 0)**: Final room with exit door to escape

---

## Edge Cases

### Player Edge Cases
1. **Player disconnect**: Keep in dimension, restore on reconnect
2. **Player death**: Allow ghosts to exit freely, corpse stays with curse
3. **Book destruction**: Eject all players to book's last location, remove curse
4. **Max reservations**: Force-unload oldest empty room if allocation fails
5. **Simultaneous navigation**: Process sequentially per chapter
6. **Puzzle reset**: Puzzles reset when room is unloaded/reloaded

### Serpent Edge Cases
7. **Serpent disconnect**: Keep in dimension, allow ghost takeover
8. **Serpent death**: Respawn after delay in random chapter, or game over
9. **Grabbed victim dies**: Auto-release, clear tail_victim reference
10. **Grabbed victim disconnects**: Auto-release
11. **Warp with grabbed victim**: Both teleport together
12. **Serpent in unloading room**: Prevent room unload if Serpent is present
13. **All players escape**: Serpent remains trapped, book becomes dormant

---

## Cross-Round Persistence

The book saves its state across rounds using the persistence subsystem.

### What Gets Saved
Save to `data/npc_saves/SerpentsBook.json`:
```json
{
    "total_chapters_created": 183,
    "total_victims_captured": 47,
    "chapter_states": {
        "180": {
            "template_id": "standard_05",
            "items": [...],
            "structures": [...],
            "modified": true
        },
        "175": {...}
    },
    "serpent_kills": 12,
    "successful_escapes": 8
}
```

### Saved Data
- **total_chapters_created**: Running count of all personal chapters ever created
- **total_victims_captured**: Total players ever pulled into the book
- **chapter_states**: Saved state of modified chapters (items left behind, structures changed)
- **serpent_kills**: How many players the Serpent has killed
- **successful_escapes**: How many players reached Chapter 0

### Implementation
Reference: `code/controllers/subsystem/persistence.dm`
```dm
/datum/serpent_dimension_manager/proc/save_to_persistence()
    var/list/save_data = list()
    save_data["total_chapters_created"] = total_chapters_created
    save_data["total_victims_captured"] = total_victims_captured
    save_data["chapter_states"] = serialize_all_chapters()
    save_data["serpent_kills"] = serpent_kills
    save_data["successful_escapes"] = successful_escapes

    var/json = json_encode(save_data)
    rustg_file_write(json, "data/npc_saves/SerpentsBook.json")

/datum/serpent_dimension_manager/proc/load_from_persistence()
    if(!fexists("data/npc_saves/SerpentsBook.json"))
        return
    var/json = file2text("data/npc_saves/SerpentsBook.json")
    var/list/save_data = json_decode(json)
    // Restore saved state...
```

### When to Save
- When the round ends
- When the book is destroyed
- When all players escape or die

### Persistence Benefits
- Items left in chapters persist across rounds
- The book "remembers" its history
- Could unlock special content after X total captures
- Serpent could grow stronger based on kill count

---

## Implementation Phases

Each phase results in something you can load up and test before moving on.

---

### Phase 1: Single Room You Can Enter
**Goal**: Create one room and a way to get into it.

- [ ] Create `/area/serpents_library` area type
- [ ] Create `/turf/closed/indestructible/serpent_wall` and `/turf/open/indestructible/serpent_floor`
- [ ] Create one 20x20 map template (`serpents_test.dmm`) with walls and floor
- [ ] Create a debug admin verb or spawner to teleport yourself into the room

**TEST**:
1. Compile and load the game
2. Use the debug verb/spawner to teleport into the room
3. Walk around, confirm the area and turfs work
4. ✅ Phase complete when you can stand in the room

---

### Phase 2: Book Item That Pulls and Teleports
**Goal**: Create the book item that captures players into the test room.

- [ ] Create `/obj/item/serpents_book` item
- [ ] Add warning dialog on use (`do_after()` confirmation)
- [ ] Implement pull mechanic (5 tile range, `step_towards()` loop)
- [ ] Anchor book during activation, hover animation
- [ ] Create minimal `/datum/serpent_dimension_manager`
- [ ] Allocate room with `SSmapping.RequestBlockReservation(20, 20)`
- [ ] Load template and teleport captured players into it

**TEST**:
1. Spawn the book item
2. Have 1-2 players/mobs nearby (within 5 tiles)
3. Activate the book
4. Confirm: book anchors, hovers, pulls nearby carbons, teleports them to room
5. ✅ Phase complete when players appear inside the library room

---

### Phase 3: Two Rooms with Door Navigation
**Goal**: Navigate between two rooms using doors.

- [ ] Create `/obj/structure/serpent_door` with north/south variants
- [ ] Add doors to the map template (north door at top, south door at bottom)
- [ ] Create a second test room template
- [ ] Implement basic `navigate_chapter()` that loads room 2 when using north door
- [ ] Track `player_chapters` and `room_occupants` in manager

**TEST**:
1. Enter via book → spawn in Room 1 (Chapter 180)
2. Click north door → teleport to Room 2 (Chapter 179)
3. Click south door → teleport back to Room 1 (Chapter 180)
4. ✅ Phase complete when you can navigate between 2 rooms

---

### Phase 4: Room Reuse with Coordinate-Based Storage
**Goal**: When you leave an empty room, store items with relative coordinates and restore them on return.

- [ ] Create `/datum/stored_room_state` for storing room contents
- [ ] Implement `store_room()` with relative coordinate tracking:
  - Calculate position relative to spawn point (landing_x, landing_y)
  - Store type, rel_x, rel_y, dir, and name for each object
- [ ] Create `serpents_empty.dmm` template for clearing rooms
- [ ] Implement `restore_room()` with coordinate restoration:
  - Calculate absolute position from new spawn point + relative coords
  - Recreate objects at correct positions with correct directions
- [ ] Implement `load_chapter_into_reservation()` - load new template into same space
- [ ] Implement the 3-case logic:
  - Case 1: Target already loaded → teleport to existing
  - Case 2: Current room empty → reuse reservation
  - Case 3: Others in current room → allocate new reservation

**TEST**:
1. Enter book alone → Room 1 loads
2. Drop an item 3 tiles east of spawn, rotate a structure to face SOUTH
3. Use north door → Room 1 stored, Room 2 loads in same space
4. Use south door → Room 2 stored, Room 1 reloads
5. Verify: item is still 3 tiles east of spawn, structure still faces SOUTH
6. ✅ Phase complete when items persist with correct positions and directions

---

### Phase 5: Chapter Datum System and Auto-Skip
**Goal**: Implement the simplified chapter datum system where each chapter has its own DMM.

- [ ] Create `/datum/serpent_chapter` base datum with:
  - `chapter_number` - which chapter this is
  - `mappath` - path to the DMM file
  - `spawn_x`, `spawn_y` - where players spawn (relative to bottom-left)
  - `is_puzzle` - whether north door is locked
- [ ] Create chapter subtypes for each visitable chapter:
  - `/datum/serpent_chapter/chapter_180` etc.
- [ ] Implement `register_chapters()` to auto-discover all chapter datums
- [ ] Update `get_template_for_chapter()` to use chapter datum's mappath
- [ ] Implement auto-skip navigation using `visitable_chapters` list
- [ ] Add personal chapters system (each captured player gets own entry chapter)
- [ ] Show "Pages blur past..." message when skipping

**Adding a New Chapter**:
1. Create `_maps/templates/serpents_book/serpents_chapter_XXX.dmm`
2. Add `/datum/serpent_chapter/chapter_XXX` with `chapter_number = XXX` and `mappath = "..."`
3. Done! Chapter is automatically available.

**TEST**:
1. Create 3 different chapter DMMs with distinct features
2. Define chapter datums for chapters 180, 175, 170
3. Capture player → spawn in personal chapter 181
4. Navigate through: 181 → 180 → 175 → 170
5. Each room loads the correct DMM
6. Verify spawn points are correct for each room
7. ✅ Phase complete when each chapter loads its unique DMM

---

### Phase 6: Puzzle Rooms with Locked Doors
**Goal**: Create puzzle rooms where north door is locked until solved.

- [ ] Create `/datum/serpent_puzzle` base datum
- [ ] Implement `/datum/serpent_puzzle/levers` (pull 4 levers in order)
- [ ] Create `/obj/structure/serpent_lever` interactable
- [ ] Create puzzle room map template with levers
- [ ] Add `puzzle_chapter_numbers` list to manager
- [ ] Lock north door on puzzle room load, unlock on solve

**TEST**:
1. Navigate to a puzzle chapter (e.g., Chapter 60)
2. Try north door → "The door is sealed..."
3. Pull levers in wrong order → puzzle resets
4. Pull levers in correct order → "The mechanism unlocks!"
5. North door now works
6. ✅ Phase complete when puzzle blocks progress until solved

---

### Phase 7: Curse System (Zombie Limbs)
**Goal**: Players gain zombie limbs as they go deeper, removed on exit.

- [ ] Implement `get_curse_level(chapter_num)` returning 0-4
- [ ] Implement `apply_curse()` - replace limbs with zombie variants
- [ ] Implement `remove_curse()` - restore normal limbs
- [ ] Call `apply_curse()` in `navigate_chapter()` when entering new chapter
- [ ] Call `remove_curse()` in `exit_dimension()`

**TEST**:
1. Enter book, navigate to Chapter 120 → no curse
2. Navigate to Chapter 80 → one limb becomes zombie
3. Navigate to Chapter 40 → two limbs zombie
4. Navigate to Chapter 20 → three limbs zombie
5. Navigate to Chapter 10 → all four limbs zombie
6. Exit at Chapter 0 → all limbs restored to normal
7. ✅ Phase complete when curse visibly applies and removes

---

### Phase 8: The Serpent (Player-Controlled Hunter)
**Goal**: Create the Serpent mob with its abilities.

- [ ] Create `/mob/living/simple_animal/hostile/serpent_librarian`
- [ ] Set `dextrous = TRUE`, `held_items`, item handling
- [ ] Implement `is_literate()` returning TRUE
- [ ] Create Tail Grab ability (immobilize + drag on move)
- [ ] Create Chapter Warp ability (teleport to any loaded chapter)
- [ ] Create Serpent's Whisper ability (broadcast to all players in book)
- [ ] Implement ghost role spawning when book activates
- [ ] Create serpent sprite assets

**TEST**:
1. Activate book with players → Serpent spawns, ghost notification sent
2. As Serpent: pick up items, read a book
3. Use Tail Grab on player → they're immobilized, dragged when you move
4. Use Chapter Warp → see list of chapters with occupants, teleport
5. Use Serpent's Whisper → all players in book see the message
6. ✅ Phase complete when Serpent can hunt and interact with players

---

### Phase 9: Cross-Round Persistence
**Goal**: Book remembers its state across rounds.

- [ ] Create `data/npc_saves/SerpentsBook.json` structure
- [ ] Implement `save_to_persistence()` - save on round end
- [ ] Implement `load_from_persistence()` - load on round start
- [ ] Save: total captures, escapes, kills, modified chapter states
- [ ] Restore dropped items when chapter is loaded

**TEST**:
1. Enter book, drop an item in a chapter
2. End the round
3. Start new round, enter book, navigate to same chapter
4. Item is still there
5. Check JSON file has correct stats
6. ✅ Phase complete when state persists across rounds

---

### Phase 10: Polish and Balance
**Goal**: Final polish, effects, edge cases, and balance.

- [ ] Add sound effects (door open, puzzle solve, teleport, serpent whisper)
- [ ] Add visual effects (teleport sparks, curse visual overlay)
- [ ] Handle edge cases:
  - Player disconnect/reconnect
  - Player death (ghost can exit freely)
  - Book destruction (eject all players)
  - Serpent death (respawn or game over)
- [ ] Create remaining map variants (80 standard, 15 puzzle)
- [ ] Balance puzzle difficulty
- [ ] Balance Serpent stats and ability cooldowns
- [ ] Balance curse thresholds

**TEST**:
1. Full playthrough: capture → navigate → puzzles → serpent chase → escape
2. Test all edge cases
3. ✅ Phase complete when everything feels polished and balanced

---

## Verification

### Player Experience
1. **Entry flow**: Activate book → get pulled in → spawn ALONE in personal chapter (181, 182, etc.)
2. **Pull mechanics**: Verify 5-tile range, anchored book during pull, carbons only
3. **Isolated start**: Each player starts in their own chapter, must navigate down to meet others
4. **Standard navigation**: Travel toward 0 using north door, verify room transitions
5. **Auto-skip**: Verify non-visitable chapters are automatically skipped with message
6. **Puzzle rooms**: Verify north door stays locked until puzzle solved
7. **Curse progression**: Verify limbs become zombie as chapter decreases
8. **Exit flow**: Reach Chapter 0, use north door to exit, verify curse removed
9. **Multi-player meetup**: Players navigating down eventually reach same visitable chapters
10. **State persistence**: Drop item, leave room, return - item should remain
11. **Book destruction**: Destroy book while players inside, verify ejection and curse removal

### Serpent Experience
12. **Serpent spawning**: Verify ghost role notification and spawning in random chapter
13. **Item handling**: Serpent can pick up, hold, and use items with hands
14. **Reading**: Serpent can read books and papers (is_literate)
15. **Tail grab**: Grab player, verify immobilization, verify dragging on move
16. **Tail release**: Release grabbed player, verify they can move again
17. **Chapter warp**: Teleport to active chapter, verify arrival with grabbed victim
18. **Serpent whisper**: Send message, verify all players in book receive it
19. **Serpent vs players**: Combat works, Serpent can damage/kill players

### Cross-Round Persistence
20. **Save on round end**: Verify SerpentsBook.json is created/updated
21. **Item persistence**: Drop item in chapter, end round, new round - item still there
22. **Stats tracking**: Verify total captures/escapes/kills increment correctly
23. **Load on round start**: Verify saved chapter states are loaded properly
