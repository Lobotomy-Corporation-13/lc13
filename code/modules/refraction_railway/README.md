# Refraction Railway

A ghost-side game mode where dead/observer players spawn into a "Refraction Railway" — a series of timed combat lines (themed after Limbus Company's Refraction Railways). Each line is a sequence of mob-fight rooms loaded from a dedicated `.dmm`, traversed by a lobby of 1–N players who picked a preset E.G.O. loadout. The objective is to clear every section as fast as possible; the final time and loadout are recorded to a per-line leaderboard.

This is a design document. Implementation has not started yet — see "Files to create" below for the planned layout.

## Goals

- Give ghosts a structured combat activity that reuses the existing wave/EGO infrastructure rather than ad-hoc admin events.
- Showcase combat depth (E.G.O. variety, different mobs) in a self-contained, low-stakes context.
- Provide a leaderboard scaffolding so individual lines have replay value.

---

## High-level architecture

| Component | Mirrors / reuses |
|---|---|
| Line definitions (datums) | `/datum/ego_datum` registry pattern |
| Lobby + line-selector console | `/obj/machinery/ego_printer` UI pattern |
| Loadout selector UI | `TestRangeEgoPrinter.js` + `code/game/objects/structures/test_range.dm` |
| Ghost → body spawn | `/obj/effect/mob_spawn/human/testrange` (in `code/game/objects/structures/ghost_role_spawners.dm`) |
| Map loading | `/obj/structure/maploader` → `load_new_z_level()` (in `ModularLobotomy/associations/machines.dm`); refraction wraps it via `SSrefraction_railway.LoadLineZ` so the assigned z is captured per lane |
| Wave / boss spawning | `/datum/wave_controller` + landmarks (in `wave_system.dm` at repo root) |
| Run-state controller | new — `/datum/refraction_run` |
| Leaderboard persistence | `SSpersistence` (`code/controllers/subsystem/persistence.dm`) |

A new `SSrefraction_railway` subsystem owns active runs, line definitions, and leaderboard state.

---

## Files to create

### Code (DM)

- `code/modules/refraction_railway/_railway_subsystem.dm`
  - `/datum/controller/subsystem/refraction_railway` — registry of `/datum/refraction_line` defs, list of active `/datum/refraction_run`, leaderboard storage, and round-spanning player knowledge: `encountered_mobs` (assoc `ckey` → list of mob types the player has fought), `mob_stats_cache` (assoc `mob_path` → cached stat list extracted from a temp instance), `mob_tips` (assoc `mob_path` → short tip string, hardcoded at SS init).
  - `Initialize()` populates lines from a hardcoded list, pulls `leaderboards` and `encountered_mobs` from `SSpersistence`, populates `mob_tips` from a static hardcoded table.
  - `fire()` ticks active runs (timer increment, idle/checkpoint detection).
- `code/modules/refraction_railway/line_datum.dm`
  - `/datum/refraction_line` — defines: `id`, `name`, `description`, `map_path` (`.dmm`), `attribute_set_value` (e.g. `80`), `max_lobby_size`, `section_count`, `display_color`, `node_coords` (for the subway-map UI), and `sector_briefings` — a list of per-sector preview entries (see "Checkpoint room → Briefing display" below for fields).
  - Concrete subtypes per line (one per `.dmm`).
- `code/modules/refraction_railway/run_datum.dm`
  - `/datum/refraction_run` — instance for an active run. Tracks: `line` ref, `members` (list of mobs), `current_section`, `current_room`, `loaded_z`, `elapsed_deciseconds`, `timer_paused`, `lobby_owner`, `lobby_state` (`LOBBY_OPEN` / `LOBBY_RUNNING` / `LOBBY_FINISHED`), `loadouts` (assoc `ckey` → list of paths), `original_attributes` (assoc `ckey` → list, for restoration), `last_checkpoint` (assoc `ckey` → section index), `ready_states` (assoc `ckey` → bool), `usable_ego_weapons` (list of weapon paths eligible at the line's `attribute_set_value`), `usable_ego_armor` (list of armor paths eligible at the same).
  - Procs: `AddMember`, `RemoveMember`, `StartRun`, `BuildEligibleEgoLists`, `ApplyLoadout`, `OnRoomCleared`, `OnSectionCleared`, `AdvanceRoom`, `BeginSector`, `OnMemberDeath`, `OnRunComplete`, `Cleanup`, `ApplyAttributeOverride`, `RestoreAttributes`, `ReequipLoadout`, `ScalePower(num_players)`.
  - Hooks `COMSIG_MOB_DEATH` for tracked members and `COMSIG_PARENT_QDELETING` for cleanup.
- `code/modules/refraction_railway/landmarks.dm`
  - `/obj/effect/landmark/refraction/player_spawn` — `room_id`, `section_id` vars.
  - `/obj/effect/landmark/refraction/section_end` — flags end of a section; teleports party to the line's checkpoint area and pauses the timer.
  - `/obj/effect/landmark/refraction/checkpoint_spawn` — destination inside the line's checkpoint area (authored as part of each line's dmm; shared between sectors of that line).
  - `/obj/effect/landmark/refraction/finish` — final landmark; ends the run, records the score.
  - `/obj/effect/landmark/refraction/wave_spawn` (extends `/obj/effect/landmark/wave_spawn`) — adds `room_id` so the run controller can pull only the right room's spawners. Re-uses dynamic mob picking already in `wave_system.dm`.
  - `/obj/effect/landmark/refraction/boss_spawn` — single spawn, fires immediately on room enter.
- `code/modules/refraction_railway/console.dm`
  - `/obj/machinery/computer/refraction_railway_console` — the line selector. `attack_ghost()` spawns a body if needed (testrange-style flow, factored into a small helper); `ui_interact()` opens the subway-map UI. `ui_act()` handles `select_line`, `create_lobby`, `join_lobby`, `leave_lobby`, `start_run`, `view_leaderboard`.
- `code/modules/refraction_railway/loadout_console.dm`
  - `/obj/machinery/computer/refraction_loadout` — opens the loadout selector. Mirrors `/obj/machinery/ego_printer`'s `ui_static_data()` / `ui_act()`. The catalog it sends is the run datum's **pre-filtered eligible E.G.O. list** (see "Eligible-gear filtering" below) — only items the players can actually equip at the line's `attribute_set_value`. Adds a header-panel snippet of the upcoming sector's briefing (faction / threat / damage hints). Accepts a `confirm_loadout` action with `{weapons: [path1, path2], armor: path3}`; rejects any path not in the eligible list (defense-in-depth against client tampering). On confirm: strips the player's existing E.G.O. items (typecache on `/obj/item/ego_weapon` and `/obj/item/clothing/suit/armor/ego_gear`), spawns the chosen items, force-equips via the no-delay equip path used by purchase consoles, and updates `loadouts[ckey]`. Re-confirming repeatedly is harmless.
- `code/modules/refraction_railway/briefing.dm`
  - `/obj/structure/refraction_briefing` — wall-mounted display in the checkpoint room. `ui_data()` reads the active run's `line.sector_briefings[current_section + 1]` and surfaces the upcoming sector's name, flavor, faction, threat range, mob silhouettes (via `SStestrange.GenerateEgoPreviewIcon`-style asset cache), suggested damage types, room count, and a boss flag for the final sector.
  - `/obj/machinery/computer/refraction_advance` — the "Begin Sector N" console. `ui_data()` shows the member roster with each player's ready state and equipped loadout. `ui_act()` handles `toggle_ready` (per player; rejected if the player has no confirmed loadout) and `begin_sector` (owner-only; rejected unless every member is ready). On `begin_sector`: activates the next room's wave controller, force-moves all members to that room's `player_spawn` landmark, unpauses the timer (and resets it to 0 only on the very first sector start), clears every member's `ready` flag.
- `code/modules/refraction_railway/scaling.dm`
  - Helper procs that scale wave reserve, mob max HP, and mob damage based on lobby size. Called from `StartRun` before each room's wave activates.

### TGUI (React/JS)

- `tgui/packages/tgui/interfaces/RefractionRailway.js`
  - Subway-map-style line selector. Dark space gradient background; SVG of nodes + connecting paths defined by each line's `node_coords`. Selected line lights up blue (matches the reference screenshot). Header: "What Line will you travel?" + countdown.
  - Sidebar / modal flows: line details, "Create Lobby" / "Join Lobby" buttons, lobby member list with kick (owner only), Start button (owner only), per-player ready state.
- `tgui/packages/tgui/interfaces/RefractionLoadout.js`
  - Trimmed clone of `TestRangeEgoPrinter.js`: tabs for Weapons (must select 2) and Armor (must select 1), the same threat / origin / tag filter UI, slot indicators showing what's selected, Confirm button.

### Maps (`.dmm`)

- `_maps/refraction_railway/line_1_template.dmm` — placeholder line with 2 sections of 2 rooms each AND its own checkpoint / staging area. The checkpoint area is part of the line dmm itself, not a separate file. Includes:
  - `player_spawn` landmarks per combat room
  - `wave_spawn` landmarks per combat room
  - `section_end` landmarks
  - A boss room with `boss_spawn` for the final section
  - **Checkpoint area** (anywhere on the same z; reachable only via teleport) containing:
    - 4–6 `/obj/effect/landmark/refraction/checkpoint_spawn` turfs (player arrival points, spread out so the team doesn't pile on one tile).
    - 1 `/obj/structure/refraction_briefing` (wall display showing the upcoming sector).
    - 2–3 `/obj/machinery/computer/refraction_loadout` consoles (parallel access to avoid queueing).
    - 1 `/obj/machinery/computer/refraction_advance` ("Begin Sector" console).
    - A heal-pad fluff area (purely visual; healing is automatic on entry).
- The `_maps/refraction_railway/` folder mirrors `_maps/Quests/` (used by `quest_ticket`).

### Existing files touched

- `lobotomy-corp13.dme` — include the new `code/modules/refraction_railway/` folder.
- `code/datums/attributes/_attribute.dm` — **no changes required**. The override snapshots original levels into `/datum/refraction_run.original_attributes` and uses the existing additive `adjust_attribute_level(target − current)` to set, then `adjust_attribute_level(original − current)` to restore. Avoids adding global API surface.

---

## Run flow (state machine)

1. **Ghost interacts with the console** (`attack_ghost`) → if no body, one is spawned via the testrange-style `create(ckey)` flow into a "railway lobby" landmark area.
2. **Player picks a line** in the subway-map UI → `select_line` action sets the pending line on the player.
3. **Create or join a lobby** for that line. Lobby state lives on `/datum/refraction_run` with `lobby_state = LOBBY_OPEN`. There is **no gear selection at the hub** — that happens later, in the checkpoint room. The hub UI just shows the line's headline info, the member list, and (for the owner) a Start button that's enabled as soon as ≥1 member is in the lobby.
4. **Owner clicks Start**. `StartRun()`:
   - `SSrefraction_railway.ClaimLane(line, run)` returns a z-level. The subsystem either claims the first free lane whose `map_path` matches (no reload), or loads a new z and registers a new lane. The line's checkpoint area is part of the same dmm, so this single load brings everything in. See "Lane management" below for the full lifecycle.
   - For each member: snapshot original attribute levels into `original_attributes`, call `adjust_all_attribute_levels(target − current)` to set everyone to the line's `attribute_set_value`, then `forceMove` to a `checkpoint_spawn` landmark in the checkpoint room.
   - Set `lobby_state = LOBBY_RUNNING`, `elapsed_deciseconds = 0`, `timer_paused = TRUE`. Members arrive empty-handed; the team is now in the staging phase. **No wave controller is activated yet** — combat begins only when the owner clicks "Begin Sector" inside the checkpoint (see "Checkpoint room (pre-sector staging)" below).
5. **Pre-sector staging at the checkpoint** (entered before every sector, including Sector 1). Briefing display shows the upcoming sector; players use the loadout consoles to pick (or re-pick) 2 weapons + 1 armor; everyone toggles Ready on the Advance console; owner clicks "Begin Sector N". On Begin: the next room's wave controller activates, members `forceMove` to that room's `player_spawn`, timer unpauses (and is reset to 0 the *first* time only).
6. **Per-room loop** (combat phase):
   - On wave clear (handled by `/datum/wave_controller/proc/CompleteWaves`), the run datum's `OnRoomCleared` fires.
   - `addtimer(CALLBACK(src, PROC_REF(AdvanceRoom)), 5 SECONDS)`. The timer keeps ticking during this delay.
   - `AdvanceRoom`: re-equip any missing weapons/armor on every member (compare current inventory to stored loadout, instantiate + equip what's missing), `forceMove` everyone to the next room's spawn landmark, activate the next room's wave controller.
7. **Section end**: `forceMove` everyone to a `checkpoint_spawn` landmark in the checkpoint room. Pause the timer (`timer_paused = TRUE` once *all* live members are in the checkpoint room), full heal (HP + sanity), update each member's `last_checkpoint`, reset every member's `ready` flag, and update the briefing console to display the *next* sector. Players re-enter the staging flow from step 5; the owner clicks "Begin Sector N+1" when the team is ready.
8. **Final section cleared**: stop the timer, record `{ckey list, loadouts, elapsed_deciseconds, line.id}` to the leaderboard, restore each member's original attributes, `forceMove` everyone back to the railway hub.

### Checkpoint room (pre-sector staging)

The checkpoint room is the staging hub for **every** sector — including the first. The team is teleported here before starting Sector 1, and again after each `section_end`. It is authored as part of the line's own dmm (a separate area on the same z as the combat rooms, reachable only via teleport), so a single `load_new_z_level` brings both combat rooms and checkpoint in together. Loaded zs are deduped in `GLOB.refraction_loaded_z_levels`, mirroring how `/obj/structure/maploader` keeps loaded quest zs in `GLOB.loaded_quest_z_levels`.

#### Arrival

When teleported into the checkpoint:

- All players `forceMove` to `/obj/effect/landmark/refraction/checkpoint_spawn` turfs (multiple landmarks; players are distributed round-robin so they don't pile on one tile).
- Each member is fully healed (HP + sanity).
- The run timer is paused (`timer_paused = TRUE`).
- The briefing display refreshes to show the upcoming sector (`current_section + 1`).
- Every member's `ready` flag is reset to `FALSE`.

#### Briefing display

A wall-mounted `/obj/structure/refraction_briefing` shows the upcoming sector's preview. Its TGUI reads `line.sector_briefings[current_section + 1]` — a per-sector entry shaped like:

```dm
list(
    "name"         = "Sector 2: The Liu Compound",
    "description"  = "Brief flavor text...",
    "faction"      = "Peccatulum",
    "threat_range" = "TETH–HE",
    "damage_hints" = "Mostly RED damage",
    "is_boss"      = FALSE,
    "nodes"        = list(
        list(
            "name"        = "Node 1 — Front Courtyard",
            "description" = "Optional flavor for this node",  // optional
            "mobs"        = list(
                /mob/living/simple_animal/hostile/ordeal/sin_gluttony/wave,
                /mob/living/simple_animal/hostile/ordeal/sin_sloth/wave,
            ),
        ),
        list(
            "name" = "Node 2 — Inner Hall",
            "mobs" = list(
                /mob/living/simple_animal/hostile/ordeal/sin_pride/noon/wave,
            ),
        ),
        // ...one entry per room in the sector
    ),
)
```

The UI renders the sector header (name, faction-themed color, threat range, optional damage hints) at the top, then a vertical timeline of **nodes** below it. Each node card shows the node's name, optional flavor description, and a row of mob cards — one per `mobs` entry. Each mob card has two states (unrevealed / revealed) described in the next subsection.

The number of nodes in `nodes` should match the number of combat rooms in that sector (each `room_id` in the sector). Authoring the briefing is therefore a 1:1 reflection of the dmm's combat rooms — easy to keep in sync.

If the final sector's last node is a boss encounter, the briefing renders in red and adds a "FINAL SECTOR — boss encounter" banner above the node list.

#### Mob card states (unrevealed → revealed)

Mob knowledge is tracked **per ckey** in `SSrefraction_railway.encountered_mobs[ckey]` — a flat list of mob types that ckey has fought before. The set is persisted across rounds via `SSpersistence` (same hook as the leaderboard). A mob type is added to the set the first time the player **enters a combat node** that contains it (i.e. on `BeginSector` / `AdvanceRoom` for the room they're moving into) — not when the line is selected, not when the briefing is opened.

##### Unrevealed (default state for any mob the player has never fought)

The mob card renders as a fully-black silhouette of the mob's flat icon (still using `getFlatIcon` + `icon2base64`, but recolored to pure black on the frontend, **not** greyscale). Information visible:

- **Damage type dealt**: `melee_damage_type` (and `ranged_damage_type` if applicable) — players know whether to expect RED / WHITE / BLACK / PALE incoming.
- **Damage weakness**: derived server-side from the mob's `damage_coeff` — the damage type with the highest multiplier (or "Even" if all four are equal). One label only; specific multipliers stay hidden.
- The mob's name, HP, exact damage, attack cadence, movement speed, and resistances are all hidden behind `???` placeholders.

This gives players just enough to make a defensive gear choice without spoiling the encounter.

##### Revealed (after the player has been in a node containing this mob, this round or any prior round)

The card flips to a full data sheet in the **same style as `code/modules/jobs/job_types/rcorp/factory/combat_log_book.dm`**, using its data-extraction shape (name + flat icon, `health`/`max_health`, `move_to_delay`, `damage_coeff`, `melee_damage_lower`/`upper`/`type`, `rapid_melee` / `attack_cooldown`, `casingtype` / `projectiletype` → ranged stats, `ranged_cooldown_time`, `rapid`, `rapid_fire_delay`).

**Use raw numbers, not vague labels.** The combat-log-book TGUI may render some fields as descriptive strings ("Slow", "Resistant"); the briefing must instead show the underlying integers / decimals. Concretely:

- HP: `"4500 / 4500"`.
- Movement: print `move_to_delay` directly (e.g. `"Move delay: 4"`); if a friendlier unit is desired, derive `tiles/sec ≈ 10 / move_to_delay` and show both, but always include the raw integer.
- Resistances: four raw multipliers, e.g. `"RED 1.0 / WHITE 0.5 / BLACK 1.5 / PALE 1.0"`. No "Resistant" / "Vulnerable" labels — the number is the label.
- Melee: `"Melee: 25–35 RED, every 1.5s"` (compute cadence from `rapid_melee` or `attack_cooldown`, in seconds).
- Ranged (if applicable): `"Ranged: 40 BLACK, every 2.0s"`, plus `"Burst: 3 shots @ 0.3s"` if `rapid > 0`.

**Tips section at the bottom of each revealed card**: a short author-written hint, sourced from `SSrefraction_railway.mob_tips[mob_type]` (a global assoc list `mob_path → tip_string`, populated at SS init from a hardcoded table the line author maintains). Tips are short flavor advice — e.g. `"Stays still while charging; punish with ranged."` or `"Goes berserk below 30% HP — back off and re-engage."`. If no tip is registered for a mob, the section is omitted (not rendered as empty).

##### Stat extraction caching

To avoid spawn-and-qdel on every briefing open, `SSrefraction_railway.mob_stats_cache[mob_type]` lazily caches the extracted stats. First request for a given mob type instantiates a temp instance in nullspace, reads vars (mirroring the combat_log_book's extraction at `combat_log_book.dm:34-99`), `qdel`s the temp, and stores the resulting list. Subsequent reads are a dictionary lookup. The damage-weakness-only payload used for unrevealed cards is computed from the same cached list — no separate extraction path.

##### Encounter trigger

`OnSectionRoomEntered(room_id)` (or the equivalent hook in `BeginSector` / `AdvanceRoom` — wherever the team is forceMove'd into a combat room) iterates the briefing entry for that room and `|=`'s every `mobs` path into each live member's `SSrefraction_railway.encountered_mobs[ckey]` set. This means: the player must actually arrive in the node — opening the briefing alone never counts.

Persistence: `SSrefraction_railway.encountered_mobs` is saved via `SSpersistence` alongside the leaderboard, so a player who fought Big Bird last week sees Big Bird's full data sheet immediately the next time they preview a sector that contains it.

#### Eligible-gear filtering

Players can only see and select E.G.O. they are actually able to equip at the line's overridden attribute level. Since the override sets every member to a single uniform `attribute_set_value` (e.g. `80`), the eligible set is **the same for every member of the run** — it can be computed once per run and cached.

`StartRun()` builds `usable_ego_weapons` / `usable_ego_armor` on the run datum:

- Iterate every `/datum/ego_datum` in `SStestrange.ego_datums`.
- Spawn a temporary instance of the datum's `item_path` in nullspace, build a one-shot dummy mob (or the lobby owner's mob — same attribute level either way at this point), call the item's `CanUseEgo(user)` proc, and `qdel` the temp.
  - *Cheaper alternative*: read the item's `attribute_requirements` initial var directly and compare each requirement against `attribute_set_value`. Skip if any requirement exceeds it. This bypasses any custom `CanUseEgo` overrides — implementation should pick whichever matches what the rest of the codebase uses for "can I equip this" checks. Default to actually calling `CanUseEgo` for correctness; fall back to direct-read only if profiling shows it matters.
- Cache the surviving paths on the run datum.

The loadout console's `ui_static_data()` reads from these cached lists, so its catalog is already filtered. There is no toggle to "show items I can't use" — they simply don't appear.

`confirm_loadout` re-validates server-side: it rejects any path not in `usable_ego_weapons` / `usable_ego_armor`. This is defense-in-depth against a client sending a tampered path.

#### Gear selection at the checkpoint

`/obj/machinery/computer/refraction_loadout` (2-3 of them in the checkpoint room).

- **Catalog**: full E.G.O. (city + non-city), weapons + armor, sourced from `SStestrange.ego_datums` — same datum list the testrange printer uses, so any E.G.O. authored anywhere in the codebase shows up automatically.
- **UI layout**: tabs for Weapons (must select 2) and Armor (must select 1), reusing `TestRangeEgoPrinter.js`'s threat / origin / tag filter UI. Three slot indicators at the top show what's currently picked. A header panel re-surfaces the briefing's faction / threat range / damage hints so players don't have to walk back to the briefing display while picking gear.
- **Per-slot edits**: the UI lets players change a single slot at a time without re-confirming all three. The `confirm_loadout` action takes whichever subset changed.
- **Confirm flow** (run datum's `ApplyLoadout(ckey, weapons, armor)`):
  1. Strip the player's current E.G.O. items by typecache (`/obj/item/ego_weapon`, `/obj/item/clothing/suit/armor/ego_gear`) and `qdel` them. (Items dropped on the floor are unaffected — only equipped/held E.G.O. is touched.)
  2. Spawn the chosen items at the player and force-equip them via the no-delay path used by the existing purchase consoles.
  3. Update `loadouts[ckey]` so `ReequipLoadout` (used between rooms during combat) knows the new authoritative set.
- **Re-pick is free**: a player can re-confirm at any time while in the checkpoint — even repeatedly — without penalty. The strip-and-spawn flow ensures no inventory accumulation.
- **First-time entry** (pre-Sector-1): every player has empty hands. They MUST confirm a loadout before being allowed to toggle Ready on the Advance console.
- **Subsequent visits**: the previous loadout is still equipped on arrival, but the timer is paused and they can change it at no cost. If they don't visit a console, their existing loadout carries over unchanged.

#### Ready state and "Begin Sector"

`/obj/machinery/computer/refraction_advance` is the start console for each sector.

- `ui_data()` shows the member roster with each player's ready state and a small visual of their picked loadout (icons for the 2 weapons + 1 armor).
- `toggle_ready` action (any member): flips that member's `ready` flag on the run datum. **Rejected** if the member has no confirmed loadout.
- `begin_sector` action (owner only): rejected unless **every** live member is ready. On accept:
  1. Activate the upcoming sector's first room's wave controller.
  2. `forceMove` all members to that room's `player_spawn` landmark (round-robin among the room's player_spawn turfs).
  3. `timer_paused = FALSE`. On the *first* sector start only, also reset `elapsed_deciseconds = 0` so the timer starts at zero from the moment they leave the checkpoint, NOT from when `StartRun` originally fired (i.e. gear-selection time doesn't count against the leaderboard).
  4. Reset every member's `ready` flag to `FALSE` for the next checkpoint stop.

#### Why one room for all sectors of a line

The checkpoint is shared across all sectors of a single line, authored once into that line's dmm. Players become familiar with its layout the more they play that line, the briefing console always lives in the same spot, and the mapping cost stays low (one area per line, not one per sector). The briefing content is the only thing that changes between visits — that's purely data-driven from `line.sector_briefings`. Each line gets to theme its own checkpoint visually if desired.

---

### Death mid-run

When a member dies during combat (not in a checkpoint room), the run datum's `OnMemberDeath` hook fires:

- Teleports the corpse + revives the player at their **last reached checkpoint room** (full heal, loadout re-equip).
- If the player has not yet cleared section 1 (no checkpoint reached), they teleport to the checkpoint room and wait there — they sit out the remainder of section 1 and rejoin the team when the survivors complete the section and arrive at the checkpoint.
- The run does **not** fail when individuals die. Surviving members keep clearing rooms; their teammates rejoin at the next section boundary.
- Edge case: if every active member is dead/checkpointed while a room still has live mobs, the run controller force-advances the team to the checkpoint and wipes wave reserves to prevent stale spawns.
- The timer keeps running while individuals are benched; it pauses only while *all* live members are inside the checkpoint room.

---

## Mob scaling (per-room)

Applied at spawn time in `ScalePower(num_players)`:

- **HP multiplier**: `1 + 0.20 * (num_players − 1)` — roughly +20% per extra player.
- **Damage multiplier**: `1 + 0.10 * (num_players − 1)` — applied to `melee_damage_lower` / `melee_damage_upper` and to ability damage where exposed via standard hooks. Mobs without those vars are out of scope for v1.
- **Wave reserve** still uses `WAVE_MOBS_PER_PLAYER` from `wave_system.dm`.

These constants live as `#define`s at the top of `scaling.dm` for easy tuning.

---

## Wave controller namespacing

`/datum/wave_controller` registers globally in `GLOB.wave_controllers` keyed by `controller_id`. Without namespacing, multiple concurrent runs (different lines OR same-line lobbies on different lanes) and consecutive reuses of the same lane would all collide.

The refraction landmarks (`/obj/effect/landmark/refraction/wave_spawn`, `/wave_trigger`, `/wave_barrier`) override the parent's init flow to derive a per-run `controller_id` of the form `"refraction_<run_uid>_<authored_id>"`. The re-stamping happens as part of `SSrefraction_railway.ClaimLane` (immediately after a fresh load OR when a free lane is reclaimed): the run iterates the refraction wave landmarks on its `loaded_z`, sets their `controller_id` to the namespaced form, and rebinds them to a freshly-built `wave_controller` datum. `ReleaseLane` qdels those controllers and any wave-spawned mobs so the lane is clean for the next claim. This keeps `wave_system.dm` untouched and gives each run a private namespace.

**Reuse caveat**: `/obj/structure/wave_barrier` self-deletes on `Unlock()` in the base `wave_system.dm`. The refraction wave_barrier subtype must override `Unlock()` to become passable (e.g. `density = FALSE`) instead of qdel-ing, and `ClaimLane` re-blocks it on each claim. Otherwise a reused lane would have no barriers on its second run.

---

## Lane management

Runs are concurrent. The subsystem owns a `loaded_lanes` list; each entry is a small struct:

```dm
list("map_path" = "_maps/refraction_railway/line_1_template.dmm",
     "z"        = 8,
     "claimed_by" = /datum/refraction_run /* or null */)
```

### Claim

`SSrefraction_railway.ClaimLane(line, run)` returns a z-level integer:

1. Walk `loaded_lanes`; if any entry has matching `map_path` and `claimed_by == null`, mark it claimed by `run` and return its z.
2. Otherwise call private `LoadLineZ(line)` (which wraps `template.load_new_z()` to capture `space_level.z_value`), append a new `loaded_lanes` entry, return the new z.

The run stores the result as `loaded_z`. All landmark lookups go through `GetRefractionLandmarks(type, room_id = null)` which iterates `GLOB.landmarks_list` and filters by `landmark.z == loaded_z`. Because authored landmark ids are duplicated across z-levels (you can't change them at map-load time), the z filter is the disambiguator.

### Release

`SSrefraction_railway.ReleaseLane(z)` is called from `Cleanup()` and defensively from `Destroy()`:

- Sets `claimed_by = null` so the lane becomes available for reuse.
- Calls `ResetLaneState(z)` (currently a no-op stub). Eventual scope once wave_system lands: qdel wave_controllers tied to the prior run's prefix, qdel wave-spawned mobs on the z, reset `wave_trigger.triggered`, restore refraction `wave_barrier` density, qdel any items dropped on the z's turfs.

The lane entry itself is not removed — BYOND has no clean unload-z primitive and the next same-line claim wants the dmm content still in place.

### Why no removal / cross-line reuse

- **z removal**: `world.maxz` only grows in BYOND; clearing turfs to space and shrinking `world.maxz` is not exposed safely. Lanes persist for the round.
- **Cross-line reuse**: would require unloading line A's atoms from a free z and re-running `template.load_new_z` against an existing z. Map_template doesn't support overwriting; we'd have to qdel everything and manually paint the new template, with high blast radius. Out of scope. Same-line reuse handles the realistic case (one line played repeatedly in a round).
- **Concurrent-z cap**: unbounded; reuse keeps the count modest in practice. Add a config-driven cap if BYOND z-pressure becomes a problem.

---

## Leaderboard

Persisted across server restarts via `SSpersistence`.

In-memory shape:

```dm
SSrefraction_railway.leaderboards = list(
    "line_id" = list(
        list(
            "ckey"      = "...",
            "name"      = "...",
            "loadout"   = list(weapon_path, weapon_path, armor_path),
            "time_ds"   = 1234,        // elapsed deciseconds
            "members"   = list(ckeys), // everyone in the lobby
            "timestamp" = world.realtime,
        ),
        ...
    ),
)
```

Top 10 per line, sorted by `time_ds` ascending. Shown via a "Logs" button in `RefractionRailway.js`.

Persistence integration:

1. **Read `code/controllers/subsystem/persistence.dm` first** to find the canonical Load/Save hook pattern (likely `LoadSomething()` at `Initialize()`, `SaveSomething()` at round end). Mirror it.
2. Add **two pairs** of procs on `SSpersistence`:
   - `LoadRefractionLeaderboards()` / `SaveRefractionLeaderboards()` — JSON at e.g. `data/refraction_railway_leaderboards.json`.
   - `LoadRefractionEncounters()` / `SaveRefractionEncounters()` — JSON at e.g. `data/refraction_railway_encounters.json`. Map of `ckey` → list of mob type-paths the player has fought. Used to flip mob cards from unrevealed to revealed in the briefing.
   Both pairs use whatever IO helpers `SSpersistence` already uses.
3. Loaded data is handed to `SSrefraction_railway` during its `Initialize()` (verify init order).
4. The leaderboard is updated + saved on each completed run. The encounter set is updated whenever `OnSectionRoomEntered` fires (in-memory immediately; saved at round end alongside the leaderboard, unless `SSpersistence`'s pattern saves more aggressively).

If `SSpersistence` lacks a JSON helper, fall back to plain `text2file` / `file2text` at the same paths. Implementation step 1 is to read `SSpersistence` and lock down the exact pattern.

---

## Critical files to read while implementing

- `code/game/objects/structures/test_range.dm` — E.G.O. printer UI pattern, `DispenseEgo` flow.
- `tgui/packages/tgui/interfaces/TestRangeEgoPrinter.js` — UI structure to clone for the loadout selector.
- `code/game/objects/structures/ghost_role_spawners.dm` — `/obj/effect/mob_spawn/human/testrange`, `/datum/outfit/testrange_agent`. Ghost-to-body spawn pattern.
- `ModularLobotomy/associations/machines.dm` — `/obj/structure/maploader`, `load_new_z_level` callsite. Runtime dmm load.
- `wave_system.dm` (repo root) — wave controller, dynamic mob picking, scaling, signal hooks.
- `code/datums/attributes/_attribute.dm` — `adjust_attribute_level`, `adjust_all_attribute_levels` (additive only; we snapshot + delta to set & restore).
- `code/modules/awaymissions/corpse.dm` — `/obj/effect/mob_spawn/spawn_user_as_role`, `create()`.
- `code/controllers/subsystem/persistence.dm` — leaderboard persistence layer.

---

## Verification

1. Compile via `"C:\Program Files (x86)\BYOND\bin\dm.exe" lobotomy-corp13.dme`. Address any DM warnings.
2. Boot a local round, become an observer, walk to the railway hub, click the console:
   - Confirm body spawn works (testrange-style sleeper).
   - Open the subway-map UI; confirm Line 1 highlights, the rest are "under construction".
   - Confirm the hub UI does **not** offer gear selection (no loadout console at the hub).
   - Create a lobby, click Start solo. Confirm: attribute override fires (check stat panel), team is teleported to the **checkpoint room**, timer is paused, hands are empty.
   - Click the briefing display — confirm it shows the upcoming Sector 1 entry from `line.sector_briefings`, with **per-node** mob cards (not a single sector-wide pile). Each node card should reflect exactly the mobs of one combat room; node count should equal the sector's room count.
   - Confirm every mob card is in the **unrevealed** state on a fresh ckey (no entry in `SSrefraction_railway.encountered_mobs[your_ckey]`): pure-black silhouette, only damage type dealt + damage weakness label visible; HP, exact damage, attack speed, resistances all hidden behind `???`.
   - Begin Sector 1. Once you arrive in node 1, exit the run and re-open the briefing for Line 1 — confirm node 1's mobs are now **revealed** with the full combat-log-book-style data sheet: name, flat icon, raw HP, raw damage range, raw resistance multipliers, attack cadence in seconds, and the author-written tip from `SSrefraction_railway.mob_tips` if one is registered.
   - Restart the server with the round end having saved encounters; confirm the previously-revealed mobs are *still* revealed for that ckey on a fresh round (persistence hook works).
   - Try to toggle Ready on the Advance console with no loadout — confirm it's rejected.
   - Open a loadout console; confirm the catalog is **already filtered** to only items usable at the line's `attribute_set_value` (e.g. for an 80-attr line, ALEPH-tier items requiring 100+ should not appear at all). With dev tools, try sending a `confirm_loadout` action with a path that's not in the eligible list — confirm it's rejected server-side.
   - Pick 2 weapons (one city, one non-city) + 1 armor; confirm validation rejects 1-weapon, 3-weapon, and 0-armor cases. Confirm the briefing snippet is visible in the loadout UI header.
   - Confirm the loadout, then re-confirm with a different weapon — verify the previous E.G.O. is `qdel`'d (not duplicated) and the new set is equipped.
   - Toggle Ready, then click Begin Sector 1. Confirm: timer resets to 0 and starts ticking, team teleports to room 1's `player_spawn`, mobs spawn, mob HP/damage roughly 1.0× (solo), wave clears → 5 s delay → next room.
   - Drop one of your weapons before the next-room teleport; confirm re-equip on arrival.
   - Reach a `section_end`; confirm checkpoint teleport, timer pause, full heal, briefing now shows the *next* sector, ready flag was reset, and re-picking gear works without re-spawning duplicates.
   - Reach the final boss; confirm single-mob spawn, completion teleport back, leaderboard entry, attributes restored.
3. Open a second client, observer-spawn, join the lobby, verify scaling: HP/damage scale up roughly 1.2× / 1.1×, wave reserve scales per `WAVE_MOBS_PER_PLAYER`.
4. Stress: leave lobby mid-fight → confirm cleanup; lobby owner disconnects → confirm ownership transfers or the run cancels cleanly; whole run dies → confirm attributes are restored on every member.
5. Repeat the same line twice in one round; confirm the dmm is *not* reloaded (lane reuse via `loaded_lanes`) but landmarks/wave controllers are reset (per-run namespacing should make this clean — verify the wave controller's `activated`/`triggered`/`completed` flags don't leak between runs, and the refraction wave_barrier subtype's `density` flips back on re-claim).
6. **Concurrency check**: open lobbies of two different lines simultaneously (two ghosts, two lobbies) → `SSrefraction_railway.loaded_lanes` should have two entries with different z values, both claimed. Each run's `GetRefractionLandmarks(...)` should only return landmarks on its own `loaded_z`, never the other run's. Then start two lobbies of the SAME line back-to-back: the second should reuse the first's lane after the first cleans up; if the first is still running, the second should load a fresh lane.
7. Restart the server; confirm leaderboard data persists.
