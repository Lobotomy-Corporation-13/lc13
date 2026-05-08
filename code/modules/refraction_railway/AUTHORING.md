# Authoring a New Refraction Railway Line

This guide walks through every step of adding a new line to the Refraction Railway. By the end you'll have a fully playable line with custom-named nodes, mob tips, and a subway-map entry — without touching any TGUI or system code.

For the architectural overview see [README.md](README.md) in this folder.

---

## What you'll create

For one new line you author:

1. **One DM file** under `code/modules/refraction_railway/lines/` — a `/datum/refraction_line` subtype.
2. **One `.dmm` file** under `_maps/refraction_railway/` — combat rooms + the line's checkpoint room + spawn landmarks.
3. **(Optional) Mob tips** — registered into `SSrefraction_railway.mob_tips` at subsystem init. One-liner per mob type.

That's it. No JS edits, no subsystem edits, no console wiring.

---

## Step 1 — Create the line subtype

Create a new file at `code/modules/refraction_railway/lines/<your_line>.dm`. Don't forget to add it to `lobotomy-corp13.dme`.

```dm
/datum/refraction_line/mirage
	id                  = "mirage"
	name                = "Line 2: Mirage"
	description         = "Doors that do not protest. Corridors that do not echo. The route appears to have been waiting on us in particular."
	map_path            = "_maps/refraction_railway/mirage.dmm"
	attribute_set_value = 80
	max_lobby_size      = 4
	section_count       = 2
	display_color       = "#d36322"
```

**Field notes:**

| Field | Notes |
|---|---|
| `id` | Unique string. Used as the leaderboard key and as the line's identifier in URLs / logs. **Must be unique across all lines.** |
| `name` | Shown on the line selector. Keep short — there's no marquee. |
| `description` | One sentence of flavor for the sidebar. |
| `map_path` | Path to your `.dmm`. The dmm holds the combat rooms and the line-specific checkpoint room (both on the same z). |
| `attribute_set_value` | Every player's attributes are set to this for the duration of the run, then restored on exit. Determines which E.G.O. is eligible. **80** ≈ HE-tier readiness; **100** unlocks ALEPH-tier. |
| `max_lobby_size` | Hard cap on how many players can join one lobby for this line. |
| `section_count` | Number of sectors. Must match the length of `sector_briefings` you author below. |
| `display_color` | Hex color, used on the subway map and the briefing badge. |

---

## Step 2 — Configure the subway-map appearance

This is what shows up on the line-selector hub. Two lists drive it: `nodes` (positions) and `edges` (connections). Both are list-of-lists — no DM type to learn.

```dm
/datum/refraction_line/liu_compound
	// ... (fields from Step 1) ...

	map_viewbox = list("w" = 800, "h" = 400)

	nodes = list(
		list("x" = 50,  "y" = 200, "kind" = "start"),
		list("x" = 200, "y" = 200, "kind" = "combat"),
		list("x" = 350, "y" = 100, "kind" = "checkpoint"),
		list("x" = 500, "y" = 200, "kind" = "combat"),
		list("x" = 650, "y" = 200, "kind" = "boss"),
		list("x" = 750, "y" = 200, "kind" = "finish"),
	)

	edges = list(
		list("from" = 1, "to" = 2, "shape" = "line"),
		list("from" = 2, "to" = 3, "shape" = "elbow_v"),
		list("from" = 3, "to" = 4, "shape" = "elbow_v"),
		list("from" = 4, "to" = 5, "shape" = "line"),
		list("from" = 5, "to" = 6, "shape" = "curve", "dashed" = TRUE),
	)

	recommended_tier_lines = list(
		"- E.G.O Tier: HE",
		"- Recommended uptie: 4",
	)
	recommended_tier_offset = list("x" = 40, "y" = -60)
```

**`nodes` entries:**

- `x`, `y` — SVG coordinates inside `map_viewbox`.
- `kind` — drives the node color: `"start"` (green), `"combat"` (blue), `"checkpoint"` (grey), `"boss"` (red), `"finish"` (gold). Defaults to the line's `display_color`.
- `radius` — optional, default 14 px.

**`edges` entries:**

- `from`, `to` — 1-based indices into `nodes`.
- `shape` — `"line"` (straight), `"elbow_h"` (right-angle, horizontal first), `"elbow_v"` (vertical first), `"curve"` (quadratic Bezier).
- `color` — optional hex override. Defaults to `display_color`.
- `thickness` — optional, default 4 px.
- `dashed` — optional bool; dashed strokes are commonly used to mark "danger ahead" or final-boss approach.

The "Recommended Level & Tier" panel renders next to the start node, offset by `recommended_tier_offset`. Each string in `recommended_tier_lines` becomes one rendered line.

---

## Step 3 — Define combat nodes

Override `New()` and call `AddNode(...)` once per combat node. Each call instantiates a `/datum/refraction_node` and registers it in `combat_nodes[node_id]`.

```dm
/datum/refraction_line/mirage/New()
	. = ..()

	// Sector 1
	AddNode(
		"mirage_threshold",                                   // node_id
		"mirage_threshold_spawns",                            // landmark_id (matches dmm)
		"First Stop: Threshold",                              // display name
		"Boots compress grit at intervals too regular to be coincidence. The pattern repeats. Patterns invite interruption.",
		list(                                                 // mob_stock (1-player baseline)
			/mob/living/simple_animal/hostile/ordeal/steel_dawn             = 8,
			/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon  = 4,
		),
		c_max = 4,                                            // concurrent_max
	)

	AddNode(
		"mirage_hollow",
		"mirage_hollow_spawns",
		"Station #2: Hollow",
		"Lights flicker at a pitch slightly off true. The chairs are angled as if recently vacated. The room is empty in a way that insists on being shown to be.",
		list(
			/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon         = 3,
			/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/flying  = 2,
		),
		c_max = 3,
	)

	// Sector 2 — final boss
	AddNode(
		"mirage_apse",
		"mirage_apse_spawns",
		"Last Stop: Apse",
		"It does not look up. It has, perhaps, never looked up. Whatever business it conducts requires no acknowledgment of those who arrive — nor of those who do not leave.",
		list(/mob/living/simple_animal/hostile/ordeal/steel_dusk = 1),
		boss = TRUE,                                          // boss flag
	)
```

**`AddNode` signature:**

```dm
AddNode(node_id, lm_id, n_name, n_desc, list/stock, c_max = 4, boss = FALSE)
```

- `node_id` — unique within this line. Used as the room_id when teleporting players in, and as the key into `combat_nodes`. Reference it from `sector_briefings` (Step 4).
- `lm_id` — every `/obj/effect/landmark/refraction/spawn` in the dmm with this same `landmark_id` becomes a valid spawn point for this node. Drop one or many landmarks per node.
- `n_name` — shown as the node card title in the briefing.
- `n_desc` — flavor text under the node name. Pass `null` if you don't want one.
- `stock` — assoc list `mob_path => 1-player baseline count`. At runtime it's multiplied by `1 + 0.20*(num_players − 1)` (boss nodes skip this).
- `c_max` — max alive at once across all spawn landmarks for this node. Default 4. Boss nodes default to 1 unless overridden.
- `boss = TRUE` — flips two things: stock no longer scales with player count, and `c_max` defaults to 1. Used for the final-fight node.

---

## Step 4 — Wire sector briefings

`sector_briefings` is an ordered list of sectors. Each sector entry is the per-sector header data plus a `node_ids` list referencing the combat nodes you defined in Step 3.

Add this inside `New()`, after the `AddNode(...)` calls:

```dm
	sector_briefings = list(
		list(
			"name"         = "Sector 1: Approach",
			"description"  = "The first stop arrives before the carriage has truly started moving. Things sharpen here, though we cannot yet say into what.",
			"faction"      = "G-Corp",
			"damage_hints" = "Persistent RED melee from the rank-and-file. WHITE shielding earns its keep.",
			"is_boss"      = FALSE,
			"node_ids"     = list("mirage_threshold", "mirage_hollow"),
		),
		list(
			"name"         = "Sector 2: Reception",
			"description"  = "The end is closer than we feel. Whatever waits at the apse has not turned to face us, and may never need to.",
			"faction"      = "G-Corp",
			"damage_hints" = "Sustained pressure. Survival earns more than burst here.",
			"is_boss"      = TRUE,
			"node_ids"     = list("mirage_apse"),
		),
	)
```

**Field notes:**

- `node_ids` — must be **node ids you registered in Step 3**, in the order players will encounter them.
- `name` / `description` / `faction` / `damage_hints` — surface in the briefing UI header above the node cards. The faction is rendered with the line's `display_color` accent.
- `is_boss` — when TRUE, the briefing UI flips to red and shows the "FINAL SECTOR — boss encounter" banner. Authors typically only set this on the final sector.

The number of entries in `sector_briefings` must equal `section_count` from Step 1. The briefing won't crash if mismatched, but the advance console will refuse to begin a sector that doesn't exist.

---

## Step 5 — Add mob tips (optional but recommended)

Tips appear on a mob's revealed card (after a player has fought it once) as a short flavor hint. They live in `SSrefraction_railway.mob_tips`, an assoc list `mob_path => tip string`, populated at subsystem init.

To add tips for your line's mobs, edit `code/modules/refraction_railway/_railway_subsystem.dm` and find `InitializeMobTips()`:

```dm
/datum/controller/subsystem/refraction_railway/proc/InitializeMobTips()
	mob_tips = list(
		// Existing entries from other lines stay here ...

		// Mirage additions:
		/mob/living/simple_animal/hostile/ordeal/steel_dawn                    = "Standard G-Corp grunt — melee RED only, no special tricks. They like to surround you; pull one off to a flank instead of fighting all of them at once.",
		/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon         = "Detonates in a small RED AoE when it dies. Land the killing blow at range, or step back two tiles before finishing the kill.",
		/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/flying  = "Hovers above the terrain and shoots from range. Ground melee cannot hit it — bring a ranged weapon, or wait until it lands to attack.",
		/mob/living/simple_animal/hostile/ordeal/steel_dusk                    = "WAW-tier captain that buffs every nearby G-Corp staffer's damage. Kill it first — everything else in the room loses teeth the moment it goes down.",
	)
```

**Tip rules:**

- **Be direct.** Name the mob's gimmick (the specific behavior that makes it different from a generic melee mob) and tell the player exactly what to do about it. One or two sentences is fine.
- Lead with the mechanic, not the flavor. "Detonates on death; finish it at range." reads better than "It carries something dangerous within."
- If a mob has no tip registered, the briefing card just omits the tip section (no empty box).
- Tips are global across all lines — the same mob tip shows up on whichever line uses that mob. So pick advice that applies regardless of context.

---

## Step 6 — Author the `.dmm`

This is the only non-DM step. The dmm holds:

### Combat rooms

For each combat node (each `AddNode` call you made):

- One or more **`/obj/effect/landmark/refraction/spawn`** with `landmark_id` matching the node's `landmark_id`. Drop them where you want mobs to materialize.
- One **`/obj/effect/landmark/refraction/player_spawn`** with `room_id = "<node_id>"` per player slot — these are the tiles players are forceMoved onto when entering the room.
- One **`/obj/effect/landmark/refraction/section_end`** at the exit tile of the *last* room in each sector. Crossing it ends the section.

### Checkpoint room (one per line)

Same z as the combat rooms, reachable only via teleport:

- 4–6 **`/obj/effect/landmark/refraction/checkpoint_spawn`** turfs (player arrival points; spread them out so the team doesn't pile on one tile).
- 1 **`/obj/structure/refraction_briefing`** (wall display showing the upcoming sector).
- 2–3 **`/obj/machinery/computer/refraction_loadout`** consoles (parallel access avoids queueing).
- 1 **`/obj/machinery/computer/refraction_advance`** ("Begin Sector" console).

### The finish landmark

One **`/obj/effect/landmark/refraction/finish`** placed on the floor of the boss room, at the spot players step onto after the boss dies. Crossing it ends the run.

### Visual conventions

Spawn landmarks use icon_state `"x3"`; player-spawn / section-end / checkpoint-spawn use `"x2"` / `"x4"` / `"x3"` respectively. They all live on `'icons/effects/landmarks_static.dmi'`. They're invisible to players in-round.

---

## Quick checklist

Before you commit:

- [ ] `id` is unique across all `/datum/refraction_line` subtypes.
- [ ] `section_count` equals `length(sector_briefings)`.
- [ ] Every node id in `sector_briefings.node_ids` was created via `AddNode(...)`.
- [ ] Every node's `landmark_id` has at least one matching `/obj/effect/landmark/refraction/spawn` in the dmm.
- [ ] Every combat room has a `player_spawn` landmark with `room_id` matching the node id.
- [ ] The last room of each sector has a `section_end` landmark.
- [ ] The boss room has a `finish` landmark.
- [ ] The checkpoint room has briefing display, advance console, ≥ 2 loadout consoles, ≥ 4 checkpoint_spawn tiles.
- [ ] The dmm is included via `lobotomy-corp13.dme` (under the `_maps` block).
- [ ] Your line subtype file is included via `lobotomy-corp13.dme` (under `code/modules/refraction_railway/lines/`).
- [ ] Compile is clean (`dm.exe lobotomy-corp13.dme`).

---

## Full worked example

Combine everything into one file:

```dm
// code/modules/refraction_railway/lines/mirage.dm

/datum/refraction_line/mirage
	id                  = "mirage"
	name                = "Line 2: Mirage"
	description         = "Doors that do not protest. Corridors that do not echo. The route appears to have been waiting on us in particular."
	map_path            = "_maps/refraction_railway/mirage.dmm"
	attribute_set_value = 80
	max_lobby_size      = 4
	section_count       = 2
	display_color       = "#d36322"
	map_viewbox         = list("w" = 800, "h" = 400)
	nodes = list(
		list("x" = 50,  "y" = 200, "kind" = "start"),
		list("x" = 200, "y" = 200, "kind" = "combat"),
		list("x" = 350, "y" = 100, "kind" = "checkpoint"),
		list("x" = 500, "y" = 200, "kind" = "combat"),
		list("x" = 650, "y" = 200, "kind" = "boss"),
		list("x" = 750, "y" = 200, "kind" = "finish"),
	)
	edges = list(
		list("from" = 1, "to" = 2, "shape" = "line"),
		list("from" = 2, "to" = 3, "shape" = "elbow_v"),
		list("from" = 3, "to" = 4, "shape" = "elbow_v"),
		list("from" = 4, "to" = 5, "shape" = "line"),
		list("from" = 5, "to" = 6, "shape" = "curve", "dashed" = TRUE),
	)
	recommended_tier_lines = list(
		"- E.G.O Tier: HE",
	)

/datum/refraction_line/mirage/New()
	. = ..()
	AddNode("mirage_threshold", "mirage_threshold_spawns",
		"First Stop: Threshold",
		"Boots compress grit at intervals too regular to be coincidence. The pattern repeats. Patterns invite interruption.",
		list(
			/mob/living/simple_animal/hostile/ordeal/steel_dawn             = 8,
			/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon  = 4,
		),
		c_max = 4)
	AddNode("mirage_hollow", "mirage_hollow_spawns",
		"Station #2: Hollow",
		"Lights flicker at a pitch slightly off true. The chairs are angled as if recently vacated. The room is empty in a way that insists on being shown to be.",
		list(
			/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon         = 3,
			/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/flying  = 2,
		),
		c_max = 3)
	AddNode("mirage_apse", "mirage_apse_spawns",
		"Last Stop: Apse",
		"It does not look up. It has, perhaps, never looked up. Whatever business it conducts requires no acknowledgment of those who arrive — nor of those who do not leave.",
		list(/mob/living/simple_animal/hostile/ordeal/steel_dusk = 1),
		boss = TRUE)
	sector_briefings = list(
		list(
			"name"         = "Sector 1: Approach",
			"description"  = "The first stop arrives before the carriage has truly started moving. Things sharpen here, though we cannot yet say into what.",
			"faction"      = "G-Corp",
			"damage_hints" = "Persistent RED melee from the rank-and-file. WHITE shielding earns its keep.",
			"is_boss"      = FALSE,
			"node_ids"     = list("mirage_threshold", "mirage_hollow"),
		),
		list(
			"name"         = "Sector 2: Reception",
			"description"  = "The end is closer than we feel. Whatever waits at the apse has not turned to face us, and may never need to.",
			"faction"      = "G-Corp",
			"damage_hints" = "Sustained pressure. Survival earns more than burst here.",
			"is_boss"      = TRUE,
			"node_ids"     = list("mirage_apse"),
		),
	)
```

---

## Common gotchas

- **"My line doesn't appear on the hub."** — Either `id` is empty (the subsystem filters those), or you forgot to `#include` the file in the DME, or another line claimed the same `id`.
- **"Mobs spawn but the room never clears."** — Almost always a `landmark_id` typo: the spawn landmarks in the dmm don't match any node's `landmark_id`, so the controller has zero spawn points for that node and immediately reports the room empty *before* spawning anything. Double-check both sides.
- **"Boss spawns 4 of itself instead of 1."** — You forgot `boss = TRUE` on the boss node's `AddNode`, so `c_max` is still 4. Boss nodes auto-default `c_max` to 1 when `boss = TRUE`.
- **"Mob counts feel off at 4 players."** — Per-mob stock is multiplied by `1 + 0.20 × (num_players − 1)` and rounded. So `8` becomes `~10`, `4` becomes `~5`. If you want exact authored counts regardless of lobby size, the mob is probably a mini-boss → use `boss = TRUE`.
- **"Mob cards show empty tip boxes."** — Tips are optional; if no entry exists in `mob_tips` for a mob path, the card just omits the tip section. You'll only see "empty boxes" if you accidentally registered an empty string. Use the actual fix or omit the entry.
- **"Players say the briefing shows the wrong sector."** — The briefing reads `current_section + 1` (the *upcoming* sector), not the current one. Sector 1's briefing shows BEFORE players begin Sector 1, so it's correct that they see the Sector 1 entry while still in the checkpoint.

---

## Where to look when something breaks

- Spawning bug → `code/modules/refraction_railway/wave_system.dm`
- Briefing rendering bug → `tgui/packages/tgui/interfaces/RefractionBriefing.js` + `code/modules/refraction_railway/checkpoint_consoles.dm`
- Subway map bug → `tgui/packages/tgui/interfaces/RefractionRailway.js`
- Lobby / lane management bug → `code/modules/refraction_railway/_railway_subsystem.dm` + `run_datum.dm`
- Persistence bug → `code/controllers/subsystem/persistence.dm` (the four `*RefractionLeaderboards` / `*RefractionEncounters` procs)
