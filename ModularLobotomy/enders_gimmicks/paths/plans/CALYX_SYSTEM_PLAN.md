# Calyx System Plan - Fragmentum Incursions

An opt-in, high-risk/high-reward event structure and the **sole** source of Trace
Material (the secondary trace resource). Companion to PROGRESSION_MATERIALS_PLAN;
ordeals give no material at all, so Calyxes carry the entire Trace-Material economy
(the abno Extraction Module carries the Main-material economy).

## Concept

A **Calyx** is a corrupted growth (reference Image #12: blackened crystal-laced
tendrils around a molten-light core) that erupts around the facility whenever a
Qliphoth meltdown fires. It sits **dormant** until a crew member touches it; after
a warning, activating it tears it open and it pours out waves of **Fragmentum
Touched** ordeal creatures until its stock is spent. Those corrupted mobs drop a
fair amount of progression material on death - that reward is the reason to open
one.

### Fragmentum flavor (from the design brief)

Fragmentum is a corrosive phenomenon spread by the Stellaron / Cancer of All
Worlds. It converts entities and spaces it touches into hostile "Fragmentum
creations" that preserve the memories and habits of the original but behave as a
completely unrelated, hostile existence. It also records Aether information of
what it touches, spawning Relics, Fragmentum monsters, and isolated paranormal
spaces. In-facility, a Calyx is one such isolated eruption, and Fragmentum Touched
ordeal mobs are corroded copies of the facility's ordeal creatures.

## 1. Spawning (meltdown-triggered)

- **Hook:** `COMSIG_GLOB_MELTDOWN_START`, sent on `SSdcs` from
  `SSlobotomy_corp.QliphothEvent()` (`lobotomy_corp.dm:337`) with a `ran_ordeal`
  argument. Register a listener the same way `SSlobotomy_events` does
  (`RegisterSignal(SSdcs, COMSIG_GLOB_MELTDOWN_START, ...)` in a subsystem's
  `Initialize()` - **not** a `GLOBAL_DATUM_INIT`, since SSdcs does not exist yet at
  global-var init time).
- **Only on meltdowns:** the same Qliphoth event either launches an ordeal or a
  meltdown. Bloom Calyxes only when `ran_ordeal` is FALSE, so Calyxes and ordeals
  don't stack on the same beat.
- **Count:** 2-4 per meltdown.
- **Placement:** random `GLOB.xeno_spawn` turfs (the same "around the facility,
  away from department centers" pool ordeals use).

## 2. Danger tiers and progression gating

- Four danger tiers (placeholder names: **lesser / common / greater / fractal**),
  aligned to ordeal grades (Dawn / Noon / Dusk / Midnight mob strength).
- **Which tiers can appear scales with how late it is.** Reuse a roundtime-
  threshold list in the spirit of `SSlobotomy_corp.ordeal_timelock`
  (`= list(20, 40, 60, 90 MINUTES, ...)`): e.g. T1 from the start, T2 ~25 min,
  T3 ~50 min, T4 ~75 min. `ROUNDTIME` (`world.time - SSticker.round_start_time`)
  is the clock.
- On each spawn, weighted-roll a tier among the currently-unlocked tiers, biased
  toward the **highest** unlocked tier so late meltdowns feel more dangerous while
  lower tiers still occasionally appear.
- Tier scales: wave size (`max_spawns`), simultaneous cap (`max_alive`), spawn
  cadence, mob stat multipliers, and reward rarity/amount.

## 3. Ordeal-color theming

- Each Calyx is themed to one **ordeal color** (green, amber, crimson, indigo,
  etc.), which decides two things:
  - its **mob pool** (Fragmentum Touched versions of that color's ordeal mobs), and
  - its **material family** on drop (via the ordeal-color -> Trace-Material-family
    map from PROGRESSION_MATERIALS_PLAN: Brown/Indigo->Fang, Green/Gold->Lens,
    Amber/Crimson/Violet->Ichor, Steel->Ward).
- The spawn manager only rolls colors that have a mob pool defined. Ship with a
  couple of colors (Green as the worked example) and add the rest incrementally.
- Excludes white/event ordeal mobs, matching the materials-plan scope.

## 4. Dormant -> activation UX

- A Calyx spawns **dormant** and inert (spawns nothing).
- `attack_hand(user)` on a dormant Calyx -> `tgui_alert` warning ("Activating this
  Calyx releases a wave of Fragmentum Touched [color] creatures - they hit hard but
  drop valuable materials. Open it?"). This mirrors the deliberate-danger warning
  flow of `/obj/item/disc_researcher`.
- On confirm (re-check adjacency + still dormant), `Activate()` starts the wave
  loop.
- **Dormant auto-collapse:** if never touched within a lifetime (~4 min), it
  quietly withers, so ignored Calyxes from repeated meltdowns don't pile up.

## 5. Wave spawning (nethersea_crack pattern)

Model the active loop on `/obj/structure/nethersea_crack`
(`ModularLobotomy/extra_mobs/lc13_sea_terrors.dm:205`):

- `START_PROCESSING(SSobj, src)` on activation; `process()` each tick:
  - track live spawns in a `spawned_mobs` list, prune dead/deleted;
  - while `spawned_mobs < max_alive` and `spawned_total < max_spawns`, spawn from
    the color/tier weighted pool onto a nearby free turf;
  - when stock is spent (`spawned_total >= max_spawns`) and all spawns are dead,
    **collapse** (fade + delete).
- Use the **factory** mob variants where they exist (e.g.
  `green_bot/factory`) so corpses self-clean and don't litter the facility.

## 6. Fragmentum Touched mobs

Two ways to build the corrupted creatures; recommend starting with (A):

- **(A, recommended) Generic corruption proc.** `Corrupt(mob)` applied to a
  freshly-spawned base ordeal mob: bump `maxHealth` and `melee_damage_*` by a
  tier-scaled multiplier, lower `move_to_delay` (faster), widen
  `aggro_vision_range` and set `robust_searching`/`wander` (more aggressive =
  "more combat-focused"), and apply a corroded look (darken via
  `add_atom_colour` + a dark outline `add_filter`). One proc covers every ordeal
  mob with no new subtypes. Register `COMSIG_LIVING_DEATH` per spawn to drop
  rewards. Sprite is a placeholder overlay/tint for now.
- **(B, later polish) Bespoke subtypes.** Per-mob `/fragmentum` subtypes with
  hand-made black-crystal sprites (keep the base color, corroded, space-patterned)
  and individually re-tuned gimmicks. Much more art + code; do this per creature
  after the framework proves out. The brief's "subtypes with new sprites and
  tweaked gimmicks" is the end state; (A) is the shippable path to it.

Combat-focus tweaks the brief calls for (faster, hits harder, gimmick shifted
toward fighting) fall out of (A)'s stat bumps; specific gimmick rewrites belong in
(B).

## 7. Rewards (the point of opening one)

- On each Fragmentum mob death, drop progression material at its turf.
- **Family = Calyx color** (via the color->family map); **rarity/amount scales
  with danger tier** (higher tier -> higher rarity, more per kill). This makes
  Calyxes the controllable, color-targeted way to farm the Trace Material a given
  path cluster needs - and the only way, since ordeals drop nothing.
- Optionally a smaller chance at the themed path's **main** (abno-sin) material too.
- **Dependency (now met):** the `path_material` / `trace_material` stack items are
  coded (`_path_materials.dm`), so the drop can spawn real stacks. What remains is
  the color->family + tier->rarity lookup that picks which stack type to drop.

## 8. Balance notes

- Calyxes are **opt-in danger**: dormant and harmless until a player chooses to
  open one, so they never punish a crew that leaves them alone, but reward one
  that can handle the wave. The warning + adjacency re-check make activation
  deliberate.
- `max_alive` per Calyx caps the pressure; consider a **global cap** on
  simultaneously-active Calyxes so multiple opened at once can't overwhelm a shift.
- Reward-per-kill x wave-size is the main knob for how fast Calyxes feed the
  material economy; tune against the ascension/trace costs so a shift's Calyxes
  don't trivialize the grind (cross-check with the trace-cost tables).
- Tier gating keeps high-strength Fragmentum waves out of the early game.

## 9. Open decisions

1. **Rewards dependency** - build the material items first, or ship Calyxes with a
   stubbed drop and wire later?
2. **Corruption approach** - generic `Corrupt()` proc (A, recommended) vs bespoke
   `/fragmentum` subtypes with new sprites (B) from the start?
3. **Global active-Calyx cap** - yes/no, and what number?
4. **Tier-unlock thresholds** - exact roundtimes (proposed 0 / 25 / 50 / 75 min).
5. **Colors at ship** - which ordeal colors get mob pools in the first pass
   (proposed: Green only, then expand)?
6. **Dormant lifetime** - auto-collapse timeout value (proposed ~4 min), or should
   dormant Calyxes persist until the next meltdown instead?

## 10. Implementation checklist (when approved)

- [ ] Subsystem (or SSdcs-registered datum) listening to
      `COMSIG_GLOB_MELTDOWN_START`; spawn 2-4 Calyxes on non-ordeal meltdowns at
      `GLOB.xeno_spawn`.
- [ ] `calyx_tier_unlock` roundtime thresholds + weighted tier roll biased high.
- [ ] Color -> per-tier weighted mob-pool table (Green first; factory variants).
- [ ] `/obj/structure/calyx`: dormant state, `ScaleToTier()`, emerge visuals.
- [ ] `attack_hand` -> `tgui_alert` warning -> `Activate()`; dormant auto-collapse
      timer.
- [ ] Wave loop on `process()` (nethersea pattern): `max_spawns`/`max_alive`,
      spawn cadence, collapse when spent.
- [ ] `Corrupt(mob)`: tier-scaled stat/aggression buff + corroded tint/outline;
      `COMSIG_LIVING_DEATH` -> `DropRewards()`.
- [ ] `DropRewards()`: family-by-color, rarity/amount-by-tier (blocked on material
      items).
- [ ] Sprites: Calyx structure (per Image #12), then Fragmentum crystal overlays /
      bespoke corrupted mob sprites (approach B).
- [ ] Include the new file(s) in the build; playtest wave pressure + reward rate.
