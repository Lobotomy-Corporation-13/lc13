# Authoring a New Refraction Railway Line

This guide walks through every step of adding a new line to the Refraction Railway. By the end you'll have a fully playable line with custom-named nodes, mob tips, and a subway-map entry — without touching any TGUI or system code.

For the architectural overview see [README.md](README.md) in this folder.

---

## What you'll create

For one new line you author, create a subdirectory `code/modules/refraction_railway/lines/<your_line>/` containing:

1. **`<your_line>.dm`** — a `/datum/refraction_line` subtype with the line config and `AddNode(...)` calls.
2. **`passives.dm`** *(optional)* — overrides `GetMobPassives()` for the mobs your line introduces.
3. **`attacks.dm`** *(optional)* — overrides `GetMobAttacks()` for the same.

Plus one map file:

4. **`<your_line>.dmm`** under `_maps/refraction_railway/` — combat rooms + the line's checkpoint room + spawn landmarks.

And optionally:

5. **Mob tips** — registered into `SSrefraction_railway.mob_tips` at subsystem init. One-liner per mob type.

That's it. No JS edits, no subsystem edits, no console wiring, no central passive/attack registry to fight over with other line authors.

---

## Step 1 — Create the line subtype

Create a new file at `code/modules/refraction_railway/lines/<your_line>/<your_line>.dm`. Don't forget to add it to `lobotomy-corp13.dme`.

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
		"- Bring E.G.O. with stat requirements around 80.",
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
- `lm_id` — every `/obj/effect/landmark/refraction/spawner` in the dmm with this same `id` becomes a valid spawn point for this node. Drop one or many landmarks per node.
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
			"name"        = "Sector 1: Approach",
			"description" = "The first stop arrives before the carriage has truly started moving. Things sharpen here, though we cannot yet say into what.",
			"node_ids"    = list("mirage_threshold", "mirage_hollow"),
		),
		list(
			"name"        = "Sector 2: Reception",
			"description" = "The end is closer than we feel. Whatever waits at the apse has not turned to face us, and may never need to.",
			"node_ids"    = list("mirage_apse"),
		),
	)
```

**Field notes:**

- `node_ids` — must be **node ids you registered in Step 3**, in the order players will encounter them.
- `name` / `description` — surface in the briefing UI header above the node cards. Per-mob faction context and incoming-damage advice belong on the per-mob `mob_tips` (Step 5), not duplicated at the sector level.
- **No sector-level `faction`, `damage_hints`, or `is_boss` field.** Boss-ness is per-node — passed to `AddNode(... boss = TRUE)` and rendered on that specific node's card.

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

## Step 5b — Add mob passives (longer-form)

Where a tip is one sentence, a **passive** is a titled card with a paragraph of explanatory text and a severity indicator. Passives surface in the "Passives" section of a mob's full data sheet (revealed cards only — silhouettes don't show them).

**Where they live**: in your line's own subdirectory, in a `passives.dm` file that overrides `/datum/refraction_line/<your_line>/GetMobPassives()`. You never touch any other line's file or any central table.

```dm
// code/modules/refraction_railway/lines/mirage/passives.dm

/datum/refraction_line/mirage/GetMobPassives()
    return list(
        /mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon = list(
            list(
                "title"    = "Last Stand",
                "severity" = "high",
                "text"     = "While attacking at 25% HP or below, 75% chance per attack to trigger Self-Destruct.",
            ),
            list(
                "title"    = "Zealous Squadmate",
                "severity" = "low",
                "text"     = "When Self-Destruct goes off, every Steel Dawn within 7 tiles becomes Zealous and is healed to nearly full.",
            ),
        ),
    )
```

The subsystem walks every registered line at init and merges all `GetMobPassives()` returns into `SSrefraction_railway.mob_passives`.

**Severity tiers** (drives banner color + warning-icon count):

| `severity` | Banner    | Icons | Use for |
|---|---|---|---|
| `"info"`   | brown     | none  | Informational only — "has reach 2", etc. |
| `"low"`    | yellow    | ⚠     | Worth knowing; doesn't immediately threaten you. |
| `"medium"` | orange    | ⚠⚠    | Active mid-combat consideration. Telegraphed AoEs, faction synergies. |
| `"high"`   | red       | ⚠⚠⚠   | Immediately dangerous. Self-destructs, screech AoEs, boss phase shifts. |

**Passive rules:**

- Two to four sentences. Lead with the trigger, end with the consequence. "Below 25% HP, it … so it then …"
- One passive per gimmick — if a mob has both a self-destruct and a death buff, that's two cards.
- Player-readable language only. No proc names, type paths, variable names, or DM expressions (`view(N)`, `oview(N)`, `TemporarySpeedChange(...)`, `damage_coeff`, etc).
- Resistances belong on the data sheet's resistance row, not in passives.
- A mob with no passive entry simply renders no Passives section. Empty cards are not rendered.

**Collisions**: if two lines both register passives for the same mob path, the *first* line to be loaded wins; the second's contribution is dropped with a `stack_trace` naming both lines. So if you reuse a mob another line already covers, just don't redeclare it — your line will inherit the existing entries automatically.

---

## Step 5c — Add mob attacks

The Attacks section renders **above** Passives on a revealed mob card. Use it for discrete damage-dealing actions beyond basic melee — screeches, dashes, AoE slams, conditional self-destructs. Each attack is a four-field assoc list.

**Where they live**: in your line's own subdirectory, in an `attacks.dm` file that overrides `/datum/refraction_line/<your_line>/GetMobAttacks()`:

```dm
// code/modules/refraction_railway/lines/mirage/attacks.dm

/datum/refraction_line/mirage/GetMobAttacks()
    return list(
        /mob/living/simple_animal/hostile/ordeal/steel_dusk = list(
            list(
                "name"     = "Screech",
                "damage"   = "60 WHITE in a 10-tile radius",
                "cooldown" = "15 seconds",
                "desc"     = "Spends 5 seconds winding up — cannot move or attack during this time. On release, blasts a shockwave that hits everything in the area.",
            ),
        ),
    )
```

Same load + merge + collision flow as passives.

**Cooldown conventions** (free-form, but stay consistent):

- Clean interval: `"15 seconds"` / `"4 seconds"`
- Always-on: `"Replaces basic melee"`
- Trigger-driven: `"Triggered (see Last Stand)"` — name the passive that arms it
- Conditional + interval: `"15 seconds, 30% chance per attack"`
- Stage-locked: append `", Stage 2 only"`

**Cross-referencing with passives**: when a passive arms or gates an attack, write the passive as the *trigger only* and let the attack carry the mechanics. For example:

```dm
// passives.dm
list(
    "title"    = "Last Stand",
    "severity" = "high",
    "text"     = "While attacking at 25% HP or below, 75% chance per attack to trigger Self-Destruct.",
)
```

```dm
// attacks.dm
list(
    "name"     = "Self-Destruct",
    "damage"   = "60 RED in a 3-tile radius",
    "cooldown" = "Triggered (see Last Stand)",
    "desc"     = "Stops moving. Grows to nearly 2x size with a red glow over 1.5 seconds. Then explodes, hitting everything close to it.",
)
```

The passive references the attack by name; the attack references the passive by name. Players reading either card find their way to the other.

**Style rules** (same as passives):

- Player-readable language only. Tiles, seconds, HP, "winds up", "stunned", "moves faster".
- No proc names, type paths, variable names, or DM expressions.
- Resistances belong on the data sheet's resistance row, not in attacks.

---

## Step 6 — Author the `.dmm`

This is the only non-DM step. The dmm holds:

### Combat rooms

For each combat node (each `AddNode` call you made):

- One or more **`/obj/effect/landmark/refraction/spawner`** with `id` matching the node's `landmark_id`. Drop them where you want mobs to materialize.
- One **`/obj/effect/landmark/refraction/start_point`** with `id = "<node_id>"` per player slot — these are the tiles players are forceMoved onto when entering the room.

For per-line authoring, prefer typed subtypes that bake `id` into the path (see `lines/nova_flare/landmarks.dm` for the pattern). StrongDMM treats them as standard obj paths and there's nothing to override per-tile.

**No section-end or finish landmarks needed.** A sector ends automatically once the last node's mobs are all dead (the controller fires `RoomCleared`, `AdvanceRoom` finds no next room, and `OnSectionCleared` runs). After the 5-second breather, the team is teleported to the checkpoint area. The same path runs the final-results display + cleanup when the last sector clears.

### Checkpoint room (one per line)

Same z as the combat rooms, reachable only via teleport:

- 4–6 **`/obj/effect/landmark/refraction/checkpoint_spawn`** turfs (player arrival points; spread them out so the team doesn't pile on one tile).
- 1 **`/obj/structure/refraction_briefing`** (wall display showing the upcoming sector).
- 2–3 **`/obj/machinery/computer/refraction_loadout`** consoles (parallel access avoids queueing).
- 1 **`/obj/machinery/computer/refraction_advance`** ("Begin Sector" console).

### Visual conventions

Spawn landmarks use icon_state `"x3"`; player-spawn / checkpoint-spawn use `"x2"` / `"x3"`. They all live on `'icons/effects/landmarks_static.dmi'`. They're invisible to players in-round.

---

## Quick checklist

Before you commit:

- [ ] `id` is unique across all `/datum/refraction_line` subtypes.
- [ ] `section_count` equals `length(sector_briefings)`.
- [ ] Every node id in `sector_briefings.node_ids` was created via `AddNode(...)`.
- [ ] Every node's `landmark_id` has at least one matching `/obj/effect/landmark/refraction/spawner` (`id` set) in the dmm.
- [ ] Every combat room has a `start_point` landmark with `id` matching the node id.
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
			"node_ids"     = list("mirage_threshold", "mirage_hollow"),
		),
		list(
			"name"         = "Sector 2: Reception",
			"description"  = "The end is closer than we feel. Whatever waits at the apse has not turned to face us, and may never need to.",
			"faction"      = "G-Corp",
			"damage_hints" = "Sustained pressure. Survival earns more than burst here.",
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
