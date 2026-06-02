# Refraction Railway

A ghost-side boss-rush mode. Observers spawn into a refraction hub,
form a small lobby, and run an authored "line" — a sequence of sectors,
each with a set of combat rooms culminating in a boss. Clearing a line
earns **Starlight**, a meta-currency for permanent quirk unlocks. Mobs
the player has fought are remembered across rounds; achievements offer
secondary objectives once a line has been cleared at least once.

This document describes the **implemented** state. The design rationale
lives elsewhere; this is the operator's manual.

---

## High-level architecture

| Component | File |
|---|---|
| Subsystem (line registry, active runs, leaderboards, mob cache, encounter set, achievement index) | `_railway_subsystem.dm` |
| Per-run state machine | `run_datum.dm` |
| Line definition base + concrete lines | `line_datum.dm` + `lines/<line>/` |
| Combat-node definition | `node_datum.dm` |
| Achievement entries + framework hook | `achievement_datum.dm`, per-line `achievements.dm` |
| Hub & checkpoint terminals | `console.dm`, `checkpoint_consoles.dm`, `loadout_console.dm` |
| Wave controller + spawn landmarks | `wave_system.dm`, `landmarks.dm` |
| Scaling helpers | `scaling.dm` |
| Cosmetic checkpoint heal pad | `healing_pod.dm` |
| Status-effect glossary surfaced in mob cards | `status_glossary.dm` |
| Leaderboard / encounter / Starlight / completed-lines / quirk-unlocks persistence | `code/controllers/subsystem/persistence.dm` |

---

## File map

### Core (`code/modules/refraction_railway/`)

- `_railway_subsystem.dm` — `/datum/controller/subsystem/refraction_railway`.
  Registries: `lines`, `active_runs`, `loaded_lanes`, `leaderboards`,
  `encountered_mobs`, `mob_stats_cache`, `mob_tips`, `mob_passives`,
  `mob_attacks`, `mob_achievements`, `achievements_by_id`,
  `starlight_balances`, `completed_lines`, `unlocked_quirks`.
  Initialize() loads persisted data via `SSpersistence`, instantiates
  every concrete `/datum/refraction_line` subtype, walks each line's
  `GetMobPassives` / `GetMobAttacks` / `GetMobAchievements` and merges
  them with collision-detection.
- `run_datum.dm` — `/datum/refraction_run`. Owns the per-run state
  machine, timers, member roster, loadout/gear tracking, per-room +
  per-sector timing, achievement state, and award math. Also defines
  the Starlight constants `STARLIGHT_BASE_AWARD`,
  `STARLIGHT_PER_UNIQUE_ITEM`, `STARLIGHT_TIME_BONUS_CAP`.
- `line_datum.dm` — `/datum/refraction_line`. Per-line vars
  (`id`, `name`, `description`, `map_path`, `attribute_set_value`,
  `max_lobby_size`, `section_count`, `display_color`, `nodes`,
  `combat_nodes`, `sector_briefings`, `expected_time_seconds`,
  `unique_loadout_per_sector`, `locked`) and the `AddNode()` helper
  concrete subtypes call from `New()`.
- `node_datum.dm` — `/datum/refraction_node`. Single source of truth
  for a combat node: `id`, `landmark_id`, `name`, `description`,
  `mob_stock` (assoc `path → count`), `extra_preview_mobs`,
  `concurrent_max`, `is_boss`.
- `achievement_datum.dm` — empty base proc
  `/datum/refraction_line/GetMobAchievements()` returning `list()`,
  plus the documented entry shape (`id`, `name`, `desc`, `reward`,
  `default_state`).
- `console.dm` — Hub terminal `/obj/machinery/computer/refraction_railway_console`
  (subway-map UI with lines / lobbies / records / compensations /
  starlight balances), the read-only records subtype, and the
  ghost-spawn sleeper `/obj/effect/mob_spawn/human/refraction_railway_agent`.
- `checkpoint_consoles.dm` — the in-checkpoint terminals:
  `/obj/structure/refraction_briefing` (next-sector preview),
  `/obj/machinery/computer/refraction_advance` (ready-up + Begin
  Sector + post-run results + records),
  `/obj/structure/refraction_starlight_shop` (quirk unlocks).
- `loadout_console.dm` — `/obj/machinery/computer/refraction_loadout`.
  Builds the per-run-filtered EGO catalog and accepts
  `confirm_loadout` (server-side path validation).
- `wave_system.dm` — `/datum/refraction_wave_controller` (one per
  combat node, per-run-namespaced via run uid) and the passive
  `/obj/effect/landmark/refraction/spawner` (id-keyed position marker).
- `landmarks.dm` — `/obj/effect/landmark/refraction/start_point` (room
  entry), `/.../checkpoint_spawn` (shared staging arrival),
  `/.../hub_spawn` (post-run return).
- `scaling.dm` — `#define`d multipliers + helpers for HP, damage, mob
  stock, concurrent cap, and compensation pens by lobby size.
- `healing_pod.dm` — visual-only structure used in the checkpoint;
  healing itself fires from `EnterCheckpoint` on the run datum.
- `status_glossary.dm` — `RefractionStatusGlossary()` returns the
  status-effect descriptions surfaced as the second tab of every mob
  card.

### Lines (`lines/<line>/`)

- **Nova Flare** (`lines/nova_flare/`) — three sectors, fully shipped.
  Files: `nova_flare.dm` (line definition + `New()` AddNode calls),
  `sector1_mobs.dm`, `sector2_mobs.dm`, `sector3_mobs.dm` (refracted
  subtypes for every mob the line uses), `attacks.dm` (declarative
  `GetMobAttacks` per-mob attack descriptions), `passives.dm`
  (declarative `GetMobPassives` for mechanic descriptions),
  `achievements.dm` (`GetMobAchievements`), `landmarks.dm`
  (line-specific landmark subtypes).
- **Curtain Call** (`lines/curtain_call/`) — first sectors playable,
  later sectors shipped as locked stubs that render as hazard-taped
  "Restricted" nodes in the hub map. Boss files: `achiyalabopa.dm`,
  `azarus.dm`, `blade_priest.dm`, `capo_and_rat.dm`,
  `greed_touched_eric.dm`, `mirror_shattered_reaper.dm`,
  `serio_zeal.dm`, `snow_cabin.dm`, `understudy.dm`. Same shared
  `attacks.dm` / `passives.dm` / `landmarks.dm` / `curtain_call.dm`
  layout as Nova Flare.

### TGUI (`tgui/packages/tgui/interfaces/`)

- `RefractionRailway.js` — hub subway-map UI. Renders lines as SVG
  node graphs, click a node to preview its mobs + achievements
  (achievements gated on `HasCompletedLine`). Also hosts the
  `RecordsModal` exported for reuse by the advance console.
- `RefractionAdvance.js` — Begin-Sector console UI. Two states:
  StagingView (member roster + Ready + Begin) and FinishedView (the
  "Cleared!" panel with per-sector + per-node times).
- `RefractionBriefing.js` — wall-mounted briefing display in the
  checkpoint room. Per-node mob cards + per-node achievement lists.
- `RefractionLeaderboard.js` — read-only records terminal.
- `RefractionLoadout.js` — loadout selector. Tabs for weapons and
  armor; items already used in a prior sector get an amber "Used in a
  prior sector — no unique-gear bonus" tag (or a hard red block when
  the line forces unique loadouts per sector).
- `RefractionMobCards.js` — shared MobCard + MobModal components used
  by both the hub and the briefing.
- `RefractionStarlightShop.js` — quirk shop UI. Tabs for "Shop" and
  "How to Earn" (explains all four Starlight sources).
- `common/AchievementList.js` — shared inline achievement list used
  under mob cards in the hub modal and the briefing.
- `common/HazardTape.js` — overlay used for locked / restricted
  nodes.

### Maps

- `_maps/refraction_railway/nova_flare.dmm`
- `_maps/refraction_railway/curtain_call.dmm`
- `_maps/map_files/generic/CentCom.dmm` modified to host the hub
  (refraction console, Starlight terminal, ghost sleeper).

### Persistence

- `code/controllers/subsystem/persistence.dm` —
  `LoadRefractionLeaderboards` / `SaveRefractionLeaderboards`,
  `LoadRefractionEncounters` / `SaveRefractionEncounters`,
  `LoadRefractionStarlight` / `SaveRefractionStarlight`. JSON files
  under `data/`. Saves are called both at run-completion (mid-round
  resilience) and at round-end via `CollectData()`.

### Quirks (`code/datums/quirks/`)

- `starlight.dm` — every Starlight-locked quirk the shop sells.
- `_quirk.dm` modified to add `starlight_locked`, `starlight_cost`,
  `required_line_completed` vars.

### Authoring guide

- `AUTHORING.md` — separate doc covering how to add a new line, mob,
  achievement, or passive. Read this before extending content.

---

## Run lifecycle

1. **Ghost spawns** at the hub sleeper
   (`/obj/effect/mob_spawn/human/refraction_railway_agent`). The
   sleeper copies the ghost's character prefs onto a fresh human body
   so the player keeps their saved appearance and name.
2. **Hub UI** (`/obj/machinery/computer/refraction_railway_console`).
   Player picks a line, creates or joins a lobby. No gear is picked
   here — the hub is line selection + party formation only.
3. **Owner clicks Start**. `StartRun()` claims a lane via
   `SSrefraction_railway.ClaimLane(line, run)`, snapshots every
   member's attributes, calls `adjust_all_attribute_levels` to set
   the line's `attribute_set_value`, and teleports the team into the
   line's checkpoint area. `lobby_state = LOBBY_RUNNING`,
   `in_checkpoint = TRUE`, `timer_paused = TRUE`.
4. **Pre-sector staging** (entered before EVERY sector, including
   sector 1). The team picks loadouts at the loadout consoles
   (two weapons + one armor, filtered to the line's attribute floor),
   readies up on the advance console, and the owner clicks Begin
   Sector N. On Begin: the first room of the sector activates,
   players teleport to its `start_point` landmark, the timer
   unpauses, ready flags clear.
5. **Per-room loop**. The room's wave controller spawns mobs from
   `node.mob_stock` (scaled by lobby size unless `is_boss`). On
   wave-cleared, `OnRoomCleared` schedules `AdvanceRoom` after a
   5-second breather. `AdvanceRoom` freshens loadouts, closes the
   current per-room timer, opens the next, teleports the team, and
   activates the next room's controller.
6. **Sector cleared**. When `AdvanceRoom` finds no next room,
   `OnSectionCleared` fires: snapshots cumulative elapsed time into
   `sector_finish_times`, closes the last per-room timer, snapshots
   loadouts into `sector_loadouts`, and either calls
   `OnRunComplete` (final sector) or `EnterCheckpoint`.
7. **Checkpoint pause**. `EnterCheckpoint` paused the timer, fully
   heals every member (the cosmetic heal pad is decorative), strips
   and re-spawns gear via `FreshenLoadout(H)` — this happens
   unconditionally now, so charge counters, kill trackers, and stack
   buffs don't carry across sectors. On unique-loadout lines
   `OnSectionCleared` also clears `loadouts[ckey]` first so the
   freshen no-ops and the player is forced to re-pick at the loadout
   console. Briefing display swaps to the next sector. Loop back to
   step 4.
8. **Run complete**. `OnRunComplete` records the leaderboard entry
   (with per-sector + per-room breakdown + loadout snapshots),
   immediately calls `SSpersistence.SaveRefractionLeaderboards()` AND
   `SSpersistence.SaveRefractionEncounters()`, awards Starlight (see
   below), shows the finished view on the advance console.

### Death and wipe handling

- Single member down (death or insanity): teleported to the
  checkpoint area immediately, benched, healed and revived after 1s.
  `BenchIncapacitatedMember` runs `HealMember` + `ReequipLoadout`.
  Survivors keep clearing rooms; benched members rejoin at the next
  sector boundary.
- Full wipe: the failing sector's clock rolls back to its start
  (`elapsed_baseline = elapsed_baseline_at_section_start`),
  `current_section` decrements, room-times for the failed sector are
  discarded, the team is teleported to the checkpoint with fresh
  gear. Wave reserves on the failed room are drained.

### Mid-run save points

- **Encounters** — saved the instant `MarkRoomEntered` adds a
  brand-new `(ckey, mob_path)` pair. The proc snapshots the previous
  set and writes JSON only when something new was learned. Partial
  runs still permanently flip mob cards.
- **Leaderboard** — saved at run completion (in `OnRunComplete`).
- **Starlight** — saved on every `AwardStarlight` / `SpendStarlight` /
  `MarkLineCompleted` / `PurchaseQuirk` mutation in the subsystem.
- All four save sources are also written at round-end by
  `SSpersistence.CollectData()`. Per-event saves cover sandbox
  mode, admin aborts, and hard crashes where round-end persistence
  is skipped.

---

## Checkpoint room

The checkpoint is authored as a separate area on the same z as the
line's combat rooms, reachable only via teleport. It's shared across
all sectors of a line. Contents:

- 4–6 `/obj/effect/landmark/refraction/checkpoint_spawn` arrival
  turfs, used round-robin so players don't pile.
- 1 `/obj/structure/refraction_briefing` — wall display.
- 2–3 `/obj/machinery/computer/refraction_loadout` consoles.
- 1 `/obj/machinery/computer/refraction_advance`.
- 1 `/obj/structure/refraction_starlight_shop` (cosmetic placement
  only — the shop reads `data["balance"]` from
  `SSrefraction_railway.GetStarlight(ckey)`, not from a per-run var).
- 1 `/obj/structure/refraction_healing_pod` (decorative).

### Briefing display (`RefractionBriefing.js`)

`ui_data()` joins `line.sector_briefings[current_section + 1]` (header
data: name, description, faction, damage_hints, is_boss, node_ids)
with `line.combat_nodes[node_id]` for each id in `node_ids`. Each
node card shows a name, optional description, a row of mob cards
(MobCard component), and an inline AchievementList that only renders
if the viewing ckey has cleared the line. Boss-sector banners switch
to red.

### Mob cards (`RefractionMobCards.js`)

Two states, gated by `SSrefraction_railway.IsMobRevealed(ckey,
mob_path)`:

- **Unrevealed**: pure-black silhouette of the mob's flat icon, plus
  only its `melee_damage_type` (and `ranged_damage_type` if any) and
  its damage-weakness label (derived from `damage_coeff` —
  highest-multiplier damage type, or "Even"). Everything else is
  `???`.
- **Revealed**: full datasheet — raw HP, raw damage range, raw
  resistance multipliers, attack cadence in seconds, derived
  tiles-per-second. Plus declarative "Attacks" and "Passives" tabs
  populated from the line's `GetMobAttacks` / `GetMobPassives` (which
  return per-`mob_path` lists of `{name, description}`). Plus an
  optional `tip` string from `SSrefraction_railway.mob_tips`.

Stat extraction is cached in
`SSrefraction_railway.mob_stats_cache[mob_path]` — first access
spawns a temp instance, reads vars, qdels the temp, stores the list.

### Loadout console (`RefractionLoadout.js`)

`ui_static_data()` reads from the run datum's pre-filtered
`usable_ego_weapons` / `usable_ego_armor` (built once at run start
from `SStestrange.ego_datums`, dropping items that fail the line's
attribute floor). Each entry carries:

- `blocked` — TRUE iff the line forces unique loadouts AND this
  player already used this item. Renders as a red disabled row with
  a strike-through and "Already used this run."
- `used_before` — TRUE iff this player used this item in any prior
  sector this run, regardless of the unique-loadout flag. Renders
  as an amber-bordered row with the tag "Used in a prior sector —
  no unique-gear bonus." Still selectable; informational.

`confirm_loadout` server-side rejects any path not in the eligible
list AND any blocked path on unique-loadout lines.

`ApplyLoadout` calls `StripMemberGear` first (qdels every tracked
ref plus sweeps stray ego items on the player), spawns the chosen
items, force-equips them with `equip_delay_self = 0`, registers
COMSIG_PARENT_QDELETING on each new ref. Re-picking is free.

### Advance console (`RefractionAdvance.js`)

Roster with each player's loadout icons + ready dot, Ready button
(rejected with no confirmed loadout), Begin Sector button
(owner-only, rejected if any live member isn't ready), Force Start
(owner-only AFK bypass), Abandon Run (owner-only, or any member if
the owner is inactive). After the run completes, swaps to the
FinishedView with the per-sector breakdown including indented
per-node times. Records button opens the same RecordsModal the hub
uses.

---

## Starlight

Awarded at `OnRunComplete` per ckey, itemised in chat.

| Source | Value |
|---|---|
| Base clear | +100 SL |
| Time bonus (signed, linear vs `line.expected_time_seconds`, ±50% of expected = cap) | ±50 SL max |
| Unique gear (per distinct weapon/armor used across all sectors) | +10 SL each |
| Achievements (per-mob, per-line) | per-achievement reward |

Constants in `run_datum.dm`. Achievements are tuned per line to total
~200 SL (Nova Flare does exactly 200).

Spent at the Starlight shop (`/obj/structure/refraction_starlight_shop`)
on permanent quirks. Quirks are flagged with `starlight_locked = TRUE`
and optionally `required_line_completed = "<line_id>"` to gate them
behind a specific line clear.

---

## Achievements

Declarative per-line via `GetMobAchievements()` returning a
`mob_path → list(entry)` mapping. Entries:

```dm
list(
    "id"            = "rose_no_high_bleed",   // globally unique
    "name"          = "Stay Unbled",
    "desc"          = "Never cross 40 Bleed stacks ...",
    "reward"        = 28,
    "default_state" = TRUE,  // TRUE = "avoid X"; FALSE = "do X"
)
```

At SS init, every line's mapping is merged into
`SSrefraction_railway.mob_achievements[mob_path]` (the boss-mob
lookup) and a flat `achievements_by_id[id]` (the reward lookup).
Collisions on either key `stack_trace` and drop the second entry.

**Veteran gate**: `InitAchievementsForMob(M)` seeds
`achievement_state[ckey][id]` ONLY for ckeys that have completed the
line at least once
(`SSrefraction_railway.HasCompletedLine(ckey, line.id)`). First-time
runners never get state seeded, so `MarkAchievement` no-ops on them
and they earn no SL from achievements on their first clear.

**Wiring per refracted mob** (see `lines/nova_flare/sector1_mobs.dm`,
`sector2_mobs.dm`, `sector3_mobs.dm` for examples):

1. Add `var/datum/refraction_run/refraction_run_ref` to the refracted
   subtype.
2. In `Initialize()`, `refraction_run_ref = FindRefractionRunForZ(z)`
   then `refraction_run_ref?.InitAchievementsForMob(src)`.
3. Hook event procs (`AttackingTarget`, `Life`, `death`,
   `Explode()`, etc.) and call `refraction_run_ref.FailAchievement` /
   `.EarnAchievement` on the relevant ckey(s).

The UI surfaces the achievement list inline under each mob row in the
hub map's node modal (`RefractionRailway.js`) and the briefing
console (`RefractionBriefing.js`), gated server-side on
`HasCompletedLine`.

---

## Leaderboards

Top 10 per line, sorted by `time_ds` ascending. Each entry:

```dm
list(
    "ckey"      = "...",
    "name"      = "...",
    "loadout"   = list(path, path, path),
    "time_ds"   = 1234,
    "members"   = list(ckeys),
    "timestamp" = world.realtime,
    "sectors"   = list(  // per-sector breakdown
        list(
            "index"   = 1,
            "time_ds" = 609,
            "players" = list(list("ckey", "name", "loadout"=paths), ...),
            "rooms"   = list(
                list("room_id", "name", "time_ds"=184),
                ...,
            ),
        ),
        ...,
    ),
)
```

Display is rendered by `SSrefraction_railway.BuildLeaderboardEntryPayload`
which converts type paths to base64 EGO preview icons. Used by both
the hub records modal and the post-run finished view.

Per-room timing is sourced from `room_times` on the run datum —
opened on `AdvanceRoomById`, closed on the next advance or at
`OnSectionCleared`. Wipe paths discard entries for the failed sector
since the clock rolls back.

---

## Wave controller namespacing

Each `/datum/refraction_wave_controller` registers in
`GLOB.refraction_wave_controllers` keyed by
`"refraction_<run_uid>_<node.id>"`. `SSrefraction_railway.RestampWaveLandmarks`
(called from `ClaimLane`) builds one controller per node, walks every
`/obj/effect/landmark/refraction/spawner` on the run's `loaded_z`,
and binds those whose `id` matches the node's `landmark_id`.
`ReleaseLane` qdels every controller matching the run's prefix and
all of their tracked mobs.

The landmark itself is passive — no spawn state, no controller ref,
just `id`.

---

## Lane management

`SSrefraction_railway.loaded_lanes` is a list of `list("map_path",
"z", "claimed_by")`. `ClaimLane` returns the z of the first matching
free lane or loads a new z via `LoadLineZ`. `ReleaseLane` flips
`claimed_by = null` and qdels per-run state but leaves the z's atoms
in place (BYOND has no clean z-unload). All landmark lookups go
through `GetRefractionLandmarks(type, room_id = null)` which filters
`GLOB.landmarks_list` by `loaded_z` — id collisions across z's are
expected, the z filter disambiguates.

---

## Mob scaling (`scaling.dm`)

`#define`d multipliers applied at room activation, gated per-line by
flags on `/datum/refraction_line`:

- `scale_stock` — `1 + 0.20 * (n − 1)` on each `mob_stock` entry.
  Boss nodes ignore this.
- `scale_concurrent` — same multiplier on `concurrent_max`.
- `scale_spawn_batch` — mobs per spawn cycle = lobby size.
- `scale_wave_stats` — `1.0 + 0.20 * (n − 1)` HP / `1.0 + 0.10 * (n − 1)`
  damage on wave mobs.
- `scale_boss_stats` — boss HP × lobby size; boss damage unchanged.
- `give_compensation_pens` — smaller parties get medical pens at
  sector start (4/2/1/0 by lobby size).

Each flag has both an SS-global toggle and a per-line override on
`/datum/refraction_line`; the effective state is `SS_flag && line_flag`,
surfaced in the hub's Compensations tab.

---

## Verification

1. Compile: `"C:\Program Files (x86)\BYOND\bin\dm.exe" lobotomy-corp13.dme`
   → 0 errors, 0 warnings.
2. Boot a local round, become an observer, walk to the refraction
   hub, click the sleeper. Confirm body spawn keeps your saved
   character prefs.
3. Open the railway console. Confirm Nova Flare highlights,
   Curtain Call shows but its later sectors render hazard-taped.
4. Create a lobby, click Start solo. Confirm: attribute override
   fires, team teleports to the checkpoint, timer paused, hands
   empty.
5. Click the briefing display. Confirm a fresh ckey sees pure-black
   silhouettes for every mob; only damage type + weakness label are
   visible. No achievements listed (veteran gate).
6. Open a loadout console. Confirm the catalog is filtered to the
   line's attribute floor. Items not yet used carry no badge.
7. Confirm a loadout, Ready up, Begin Sector 1. Watch the per-room
   timer tick. On wave-clear, confirm the 5s breather, freshened
   gear on entry to the next room, and persisted reveals in the
   briefing display (re-open it from a teammate's client).
8. Drop gear before a room transition; confirm `ReequipLoadout`
   `forceMove`s it back to your tile.
9. Re-pick loadout at the checkpoint; confirm the loadout console
   shows the prior-sector items with the amber "Used in a prior
   sector — no unique-gear bonus" badge.
10. Clear the line. Confirm the chat itemised breakdown shows Base /
    Time / Unique gear (with item count) and that no achievement
    lines appear (still first clear of the line).
11. On the next run, confirm achievements now seed and that the
    briefing console + hub modal list them under their respective
    mobs.
12. Restart the server. Confirm leaderboards, encounters, Starlight
    balances, and unlocked quirks all persist for that ckey.
13. Open a second client, observer-spawn, join a lobby. Verify
    scaling: HP and damage scale per `scaling.dm` constants, mob
    stock and concurrent cap scale, boss stats scale HP only.
14. Concurrency: two lobbies of different lines simultaneously.
    `loaded_lanes` should have two entries, each claimed; landmark
    lookups should never cross z's.
15. Wipe path: deliberately let the team die in sector 2. Confirm
    the clock rolls back to the sector 2 start, the team is back in
    the checkpoint, gear is freshened, and the failed sector's
    room-times are discarded.
16. Sandbox-mode round: clear Nova Flare, force a round end without
    `allow_persistence_save`. Confirm encounters + leaderboard
    survive into the next round because run-completion saved them
    directly.
