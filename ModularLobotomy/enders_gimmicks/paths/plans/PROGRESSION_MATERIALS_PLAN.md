# Pathstrider Progression Materials Plan

Companion to `BASEGAME_INTEGRATION_PLAN.md`. Adds material-gated ascension and
two new subsystems that source those materials from the facility's own content.
This **revises** two parts of the base-game plan (see Section 7).

## Concept

HSR splits character growth into two tracks: free EXP leveling *within* a cap,
and material-gated **ascension** that breaks the cap (plus material-gated trace
upgrades). We adopt the same split for Pathstriders:

- **Leveling within a phase** stays free, driven by attribute EXP (base-game plan
  Section 2). No change.
- **Ascension** (breaking a level cap) and **trace upgrades** now cost **Path
  Materials**, obtained by fighting/working the facility's abnormalities and
  ordeals. This replaces the Ascension Crystal and the ahn/trace-point economy.

The result: attributes gate *how high you can climb this phase*, materials gate
*whether you break into the next phase and how deep your traces go*. Both scale
with facility content, so progression tracks engagement instead of a wallet.

---

## 1. The seven Path Materials (sin-tied)

Seven material families, one per path, each in three rarities (2-star / 3-star /
4-star). This is exactly the HSR ascension-material structure in the reference
image (credits ignored per your note). 7 x 3 = 21 stackable items.

### Path <-> Sin mapping

The bridge already exists in code: **every abnormality sets
`datum_reference.chem_type`** to one of the seven sin reagents
(`/datum/reagent/abnormality/sin/{wrath,lust,sloth,gluttony,gloom,pride,envy}`) -
the same sin taxonomy the grid-crafting system uses (`grid_crafting/README.md`).
So each abno already "belongs" to a sin; we map sin -> path -> material:

| Path | Sin (abno `chem_type`) | Material family (placeholder names) |
|---|---|---|
| Destruction | Wrath | Ashen Cinder / Ember / Pyre |
| The Hunt | Envy | Keen Fang / Talon / Apex Fang |
| Erudition | Pride | Cold Axiom / Theorem / Absolute Proof |
| Nihility | Gloom | Hollow Dust / Void / Abyssal Silence |
| Harmony | Lust | Faint Chord / Hymn / Grand Chorus |
| Preservation | Sloth | Chipped Ward / Bulwark / Aegis |
| Abundance | Gluttony | Withered Seed / Bloom / Everharvest |

(Names are placeholders; final naming is a TODO table. Rarity tiers referred to
below as **T1 (2-star)**, **T2 (3-star)**, **T3 (4-star)**.)

### Item structure

- Base: `/obj/item/stack/path_material`, parameterized by `path_key` + `tier`
  (mirrors the existing `/obj/item/stack/path_exp_crystal` tiers), stackable,
  fits an EGO belt.
- One icon per family with three rarity color/border variants (reuse the
  2/3/4-star framing from the reference image; sprite work is a separate task).

### Why abno-sin

Abnos carry a clean, already-assigned sin, so they are the **precise** source
(you farm the sin you need). The Omni-Synthesizer (Section 4) covers any mismatch
so a player is never hard-stuck on a family they can't farm.

---

## 1b. The four Trace Materials (secondary resource)

Traces in HSR cost the path's ascension family **plus** a separate "Trace
Material" family (reference images: Shattered / Lifeless / Worldbreaker Blade,
three rarities from a distinct source). We mirror this with **four** Trace
Material families, each in three rarities (T1/T2/T3), and each shared by a
thematically-matched cluster of paths. HSR does exactly this - different
characters draw their trace materials from different Caverns; here the "caverns"
are ordeal colors.

- Item: `/obj/item/stack/trace_material`, parameterized by `family` + `tier`.
  4 families x 3 tiers = **12 stack types**.
- **Source: Calyxes only** (Section 3), themed by ordeal **color**. Your path's
  *main* material comes from abno work/breaching (the Extraction Module); its
  *trace* material comes only from **Calyxes** of the matching color(s). Ordeals
  give no material at all - both material kinds require active engagement (the
  module, or opening a Calyx wave), never passive attendance.
- Rarity = the Calyx's **danger tier** (tiers align to ordeal grades and are gated
  by roundtime, so higher rarities appear later in a shift), mixed per tier:
  - **Lesser** (Dawn-grade) -> T1 only.
  - **Common** (Noon-grade) -> mix of T1 and T2 (mostly T1, some T2; e.g. ~2:1).
  - **Greater** (Dusk-grade) -> mix of T2 and T3 (mostly T2, some T3; e.g. ~2:1).
  - **Fractal** (Midnight-grade) -> the richest mix and the main T3 source.
- Only traces consume Trace Material. Ascension and bonus abilities use the path's
  main material only.

Calyxes only spawn for colors that have a Fragmentum mob pool defined, so the white
(level 6-9) and event (Christmas / Salmon-shrimp) colors are out of scope, and
**Pink is out too** - it is a Midnight-only color with no non-Midnight Fragmentum
mobs built, so no Pink Calyx spawns. The eight remaining colors (Amber, Brown,
Crimson, Gold, Green, Indigo, Steel, Violet) distribute across the four families as
follows.

### Brainstormed mapping

| # | Trace Material (placeholder names T1/T2/T3) | Sub-material for paths | From Calyx colors | Theme |
|---|---|---|---|---|
| 1 | **Fang** - Bloodworn Fang / Rending Fang / Devouring Fang | Destruction, The Hunt | Brown, Indigo | Predation, carnage, the pursuit |
| 2 | **Lens** - Clouded Lens / Lucid Lens / Oracle Lens | Erudition, Nihility | Green, Gold | Cold intellect, the void, contemplation |
| 3 | **Ichor** - Thin Ichor / Rich Ichor / Sacred Ichor | Abundance, Harmony | Amber, Crimson, Violet | Flesh, blood, life, devotion |
| 4 | **Ward** - Cracked Ward / Tempered Ward / Adamant Ward | Preservation | Steel | Armor, the wall, endurance |

Rationale per family:

- **Fang (Destruction / Hunt)** - the two pure-offense paths (Wrath + Envy), fed by
  Brown ("Peccata Capitalia / Pandaemonium" - demonic wrath and chaos) and Indigo
  ("The Scouts / The Sweepers" - city fixers, backstreet predators).
- **Lens (Erudition / Nihility)** - intellect and void (Pride + Gloom), fed by Green
  ("Doubt / Last Helix" - robots seeking the ultimate answer) and Gold ("Sky, Wind,
  Star and Poem" - poetic contemplation of mortality).
- **Ichor (Abundance / Harmony)** - life and bonds (Gluttony + Lust), fed by Amber
  and Crimson ("The Perfect Meal", "A Chorus of Saliva" - consumption, flesh and
  blood) and Violet ("Grant Us Love" - love and devotion). Three colors because
  these two support paths are the highest-demand.
- **Ward (Preservation)** - the lone dedicated tank (Sloth), fed by Steel ("War
  Machine / The Dogs of War" - armor, fortification, holding the line).
  Preservation is a single, low-demand path, so one color is adequate.

### Notes / knobs

- Preservation is the only path served by a solo family (7 paths / 4 families
  forces one solo). It is the singular defensive path, so a dedicated Ward material
  is thematically clean. If you would rather every family serve two paths, the
  cleanest alt is to fold Nihility into the Ward cluster (Gloom + Sloth = the
  "static" paths) and shrink Lens to Erudition only - flagged in Section 9.
- **Rarity now comes from Calyx danger tier, not from which real ordeals a color
  runs.** So the old per-color "does this color run a Dusk?" caveats no longer
  apply - every family can reach T3 via a Greater/Fractal Calyx of any of its
  colors, and no family is starved of high rarity.
- Since Trace Material comes only from Calyxes, trace progression is paced by
  **meltdown frequency** (Calyxes spawn on meltdowns) and the roundtime tier gate.
  If that feels too swingy, the knobs are the Calyx spawn count per meltdown and
  the tier-unlock thresholds (CALYX_SYSTEM_PLAN). Flagged in Section 9.

---

## 2. Source A - Abnormality Extraction Module (the console attachment)

A module the player attaches to the abnormality work console
(`/obj/machinery/computer/abnormality`), following the `disc_researcher` pattern
(`ModularLobotomy/disciplinary/research.dm`). Two output modes:

### 2a. Passive trickle (working the abno)

Hook `/datum/abnormality/proc/work_complete()` (`abnormality.dm:228`) - it fires
on every finished work action and already carries `user`, `work_type`, and `pe`.
When a console has the module and the worker is a Pathstrider:

- Award a **small** amount of the abno's sin-family material at **T1**, scaled by
  work result (good > neutral > bad) and PE produced.
- This is a steady, low-yield drip so ordinary containment work slowly funds
  traces and early ascensions.

### 2b. Forced breach (charge-based burst)

Reuse the `disc_researcher` breach mechanic. When the module targets a contained,
`can_breach` abno the player may spend one charge to force a breach:

- Gate: `breacher.IsContained()` and `breacher.datum_reference.can_breach` and a
  charge available. (Same guards the researcher uses.)
- Radio-alert the disciplinary team (reuse the researcher's radio call) so this
  is a visible, contestable act, not a silent farm.
- After a `do_after`, force the breach exactly like `BreachBerry`: move the mob to
  a `GLOB.xeno_spawn` turf and `datum_reference.qliphoth_change(-99)`.
- Tag the breacher; register on its **death** (`abnormality.dm` death path around
  line 236) to drop a **large** bundle of that sin-family material, mixed
  **T1 + T2** (breaching a real threat is the main way to earn T2).

### 2c. Charges

- `max_charges = 3`, consumed 1 per forced breach.
- Regenerate 1 charge roughly every **10 minutes** (`addtimer`/`world.time`
  gating, tunable). Store on the module; show remaining charges on examine and in
  the console UI.
- Rationale: forced breaches are powerful and risky (a loose abno endangers the
  facility), so the charge economy caps how often a team can convert danger into
  materials, and the 10-minute regen paces ascension against shift length.

---

## 3. Source B - Calyxes (the four Trace Materials)

**Calyxes are the sole source of Trace Material.** Ordeals drop nothing at all -
normal clears, per-mob kills, none of it. Trace Material comes only from clearing
Calyx waves (CALYX_SYSTEM_PLAN), which are opt-in and require active engagement,
matching how abno material requires the module.

Each Calyx is themed to an ordeal **color** (which sets its Fragmentum mob pool and
its Trace family) and rolls a **danger tier** gated by roundtime (which sets its
rarity mix). So Trace Material is farmed by choosing to open Calyxes of the color(s)
that feed your path's cluster.

Color -> family: Brown/Indigo -> Fang; Green/Gold -> Lens; Amber/Crimson/Violet
-> Ichor; Steel -> Ward. Danger tier -> rarity (mixed): Lesser -> T1; Common ->
T1+T2 mix; Greater -> T2+T3 mix; Fractal -> the richest T2+T3 mix.

- **Per Fragmentum-mob death:** drop a small amount of the Calyx color's Trace
  Material, rolling the tier's rarity mix (see MATERIAL_YIELD_PLAN for amounts).
- **On Calyx clear (stock spent):** optionally award surviving Pathstriders a bonus
  bundle drawn from the same tier mix.
- **T3 comes only from Greater/Fractal Calyxes**, as the rarer half of their mix.
  Maxing a trace (large T3 quantities - the reference shows 23x T3 for a 10-level
  trace) therefore means clearing the cluster's high-tier Calyxes repeatedly; that
  is the long-tail grind. Because high-tier Calyxes are roundtime-gated, T3 farming
  is naturally a late-shift activity.
- The path's **main** material still comes only from abnos (Section 2); Calyxes
  primarily drop Trace Material (with an optional small chance at the themed path's
  main material, per CALYX_SYSTEM_PLAN). Two material kinds, two sources: the module
  (abnos -> main) and Calyxes (-> trace).
- The Omni-Synthesizer (Section 4) still lets a player synthesize rarities up within
  a family they already have.

---

## 4. The Omni-Synthesizer (new machine)

Wall-mounted synthesizer (reference Image #2). A `/obj/machinery` with a TGUI
front end offering two conversions. Never consumes credits/ahn - pure material
economy, so players can always unstick themselves.

### 4a. Material Synthesis (rarity up)

- Consume **3x** of a lower-rarity material to produce **1x** of the next rarity,
  **same family**. (T1 x3 -> T2 x1; T2 x3 -> T3 x1.)
- Mirrors the reference: "3 copies of a 2 or 3-star -> 1 copy of a 3 or 4-star."

### 4b. Material Exchange (family swap)

- Consume **2x** of one path family's material to produce **1x** of another path
  family at the **same rarity**. (Any T1 x2 -> chosen T1 x1.)
- Mirrors the reference: "2 copies -> 1 copy of another material of the same
  rarity you're missing."
- The 2:1 tax makes exchanging always worse than farming the right abno, so it is
  a catch-up valve, not the main path.
- **Trace Materials** can be Synthesized up in rarity within their own family, but
  do **not** participate in Exchange - you cannot swap Fang for Lens. Keeping the
  four families non-interchangeable is what makes farming the ordeals tied to your
  path's cluster matter.

### 4c. Notes

- Both operations validate the input stacks (`use()` on the stacks) and spawn the
  output stack, like existing crafting machines.
- Gate high-rarity synthesis behind ordeal-tier unlocks if we want to prevent
  early T3 (reuse the `COMSIG_GLOB_ORDEAL_END` global-tier pattern from
  grid-crafting).

---

## 5. Expanded ascension cost table

Replaces the single Ascension Crystal. Per phase, escalating rarity + quantity,
adapted from the reference image with credits dropped and materials made
path-specific. `T1`/`T2`/`T3` are the ascending player's own path family.

| Ascension | Level cap | Cost |
|---|---|---|
| 0 -> 1 | 20 | 4x T1 |
| 1 -> 2 | 30 | 8x T1 |
| 2 -> 3 | 40 | 5x T1 + 4x T2 |
| 3 -> 4 | 50 | 8x T1 + 6x T2 |
| 4 -> 5 | 60 | 8x T2 |
| 5 -> 6 | 70 (unlocks 80) | 10x T2 + 3x T3 |

Rough totals per path to fully ascend: ~25x T1, ~28x T2, ~3x T3 (in the same
ballpark as the reference image's per-material totals). All numbers tunable.

- **Where you spend:** add an **Ascend** action to the existing Path Screen UI
  (`_path_ui.dm`), which already shows level/ascension. It checks the material
  stacks in the player's possession (or a bound storage), consumes them, and
  calls the existing `Ascend()`. This replaces the crystal item entirely.
- **Gate stays:** you still must be at the current phase's level cap (already
  enforced), AND now have the materials.

---

## 6. Trace upgrade costs

Replace the ahn cost in `UnlockNode()` (`_path_datum.dm`) entirely. Traces now
consume **two** resources, mirroring the HSR reference images:

- **Path Material (main)** - the path's own sin-tied family, shared with
  ascension. From abnos.
- **Trace Material (secondary)** - one of the four families (Fang/Lens/Ichor/Ward)
  tied to the path's cluster. From Calyxes.

Trace nodes come in three kinds in the current tree; each is costed differently.

### 6a. Ability level-ups (repeatable ability nodes)

The `core_basic` / `core_burst` / `core_ultimate` / `core_passive` nodes are
repeatable, each purchase adding one ability level. Cost and the required
ascension both scale with the ability's **current level**.

**There are TWO schedules, not one** (this is the correction from the closer look
at the screenshots): the Basic ATK trace is short and steep; the Skill / Ultimate
/ Passive traces are long and start earlier.

#### Basic ATK trace (Image #9; HSR caps at 6, this system at 7)

| Level up | Req. Ascension | Main material | Trace material |
|---|---|---|---|
| 1 -> 2 | **2** | 4x T1 | 2x T1 |
| 2 -> 3 | 3 | 2x T2 | 2x T2 |
| 3 -> 4 | 4 | 3x T2 | 4x T2 |
| 4 -> 5 | 5 | 2x T3 | 2x T3 |
| 5 -> 6 | 6 | 3x T3 | 6x T3 |
| 6 -> 7 | 6 | 4x T3 | 8x T3 |  (extension beyond HSR)

1 -> 6 subtotal (4x/5x/5x main T1/T2/T3, 2x/6x/8x trace T1/T2/T3) matches the
Image #9 total exactly. Note the Basic ATK trace **cannot be touched until
Ascension 2** and reaches Asc 6 by level 6.

#### Skill / Ultimate / Passive traces (Images #10-#11; HSR caps at 10, this system at 12)

| Level up | Req. Ascension | Main material | Trace material |
|---|---|---|---|
| 1 -> 2 | **1** | 2x T1 | - |
| 2 -> 3 | 2 | 4x T1 | 2x T1 |
| 3 -> 4 | 3 | 2x T2 | 2x T2 |
| 4 -> 5 | 4 | 3x T2 | 4x T2 |
| 5 -> 6 | 4 | 5x T2 | 6x T2 |
| 6 -> 7 | 5 | 2x T3 | 2x T3 |
| 7 -> 8 | 5 | 3x T3 | 4x T3 |
| 8 -> 9 | 6 | - | 6x T3 |
| 9 -> 10 | 6 | - | 11x T3 |
| 10 -> 11 | 6 | 3x T3 | 6x T3 |  (extension beyond HSR)
| 11 -> 12 | 6 | 4x T3 | 8x T3 |  (extension beyond HSR)

1 -> 10 subtotal (6x/10x/5x main T1/T2/T3, 2x/12x/23x trace T1/T2/T3) matches the
Images #10-#11 totals; 10 -> 12 extends for this system's higher cap. Trace
Material dominates the late levels, which is why farming the cluster's **Dusk**
ordeals (the only T3 source) is the long-tail gate.

### Per-level ascension gate (required, mirrors the screenshots)

The "Required Ascension" column is **enforced**: you cannot raise an ability to
the next level until the path has reached the ascension phase that level demands.

Current code does **not** do this. The repeatable ability nodes set no
`required_ascension`, and `CanUnlock()` (`_path_node.dm`) only checks a single
**static** `required_ascension` per node - it cannot express a per-level gate. So
the gate is computed from the target ability's **current level**, using the
correct schedule for that ability (Basic ATK vs Skill/Ult/Passive):

| Ability current level | Basic ATK: Asc req | Skill/Ult/Passive: Asc req |
|---|---|---|
| 1 | 2 | 1 |
| 2 | 3 | 2 |
| 3 | 4 | 3 |
| 4 | 5 | 4 |
| 5 | 6 | 4 |
| 6 | 6 | 5 |
| 7 | - | 5 |
| 8+ | - | 6 |

Because these are the same brackets as the cost tables, the ascension gate and the
material-rarity bracket rise together and neither can be outrun. Implement as a
small proc keyed on `ability_target` (Basic uses the steep column, the other three
use the gentle column). Show the requirement and a locked state on the node in
`ui_data()`, the way the base tree already surfaces `required_ascension` for
stat/bonus nodes.

### 6b. Stat nodes (one-time percent bonuses)

The small stat nodes (`stat_*`) are cheap one-time buys: a few **Main material**
at the rarity of their `required_ascension` (T1 for ungated/early, T2/T3 for
higher-ascension branches), plus **1-2 Trace Material** of the same tier. These
are the "minor traces" of the tree.

### 6c. Bonus abilities (the ascension-gated passive nodes)

Per your spec, the bonus nodes cost **only the path's main material**, escalating
by their ascension gate:

| Bonus node | Ascension gate | Cost (main material only) |
|---|---|---|
| `bonus_a2` (e.g. Ready for Battle) | 2 | 4-6x T1/T2 |
| `bonus_a4` (e.g. Tenacity) | 4 | 4-6x T2/T3 |
| `bonus_a6` (e.g. Fighting Will) | 6 | 8x T3 |

Keep the existing `required_ascension` / `required_level` gates. Update
`ui_data()` to show both material balances and per-node costs instead of ahn.

This supersedes the "Option B trace points" idea from the base-game plan: leveling
is attribute-EXP, ascension is main-material, and traces are main-material plus
the Calyx-sourced Trace Material.

---

## 6.5. UI: showing resource cost instead of ahn

The Path Screen (`_path_ui.dm` + `tgui/.../PathScreen.js`) currently prices every
trace node in **ahn** and has no ascension spend screen at all (ascension is the
crystal item today). Both the trace screen and the new Ascend screen must display
**material cost** - the path's main-material family and, for traces, the cluster's
Trace-Material family - with each cost line lit green/red against how much of that
material the player holds, exactly the way ahn affordability is shown now.

### 6.5a. DM side - stop emitting ahn, emit material costs

- **`/datum/path_node`**: the single `ahn_cost` var (`_path_node.dm:22`) is
  replaced by structured material costs. For the repeatable ability nodes the cost
  is not a stored constant - it is looked up from the Section 6a schedules by the
  target ability's **current level**, so `GetNodeData()` must compute the cost for
  the *next* purchase at call time, not read a fixed field. Shape per node:

  ```
  data["cost"] = list(
      "main"  = list(list("tier"=1, "amount"=4)),          // path main family
      "trace" = list(list("tier"=1, "amount"=2)),          // cluster trace family
  )
  ```

  A tier list (not a scalar) because several brackets mix two rarities (e.g. Asc
  2->3 main = 5x T1 + 4x T2). Stat nodes (6b) and bonus nodes (6c) return the same
  shape with a `trace` of `null`/empty (bonus nodes are main-material only).
- **`GetNodeData()`** (`_path_node.dm:62`): drop `data["ahn_cost"]`; add
  `data["cost"]` (above), and for ability nodes also the resolved
  `data["required_ascension"]` computed from the per-level gate proc (Section 6a)
  so the node can show its live "needs Ascension N" lock.
- **`ui_data()`** (`_path_ui.dm:17`): drop the `player_ahn` block
  (`_path_ui.dm:187-193`). Add the player's current material inventory so the UI
  can color each cost line:

  ```
  data["materials"] = list(
      "main"  = list("family"=main_family_key,  1=<count T1>, 2=<count T2>, 3=<count T3>),
      "trace" = list("family"=trace_family_key, 1=<count T1>, 2=<count T2>, 3=<count T3>),
  )
  ```

  Counts come from summing the player's `/obj/item/stack/path_material` and
  `/obj/item/stack/trace_material` stacks of the path's two families (or the bound
  storage, per Section 7 persistence decision). Also emit `material_icons`
  (base64, like the existing `stat_icons` cache) so the JS can render each
  material's icon beside its cost - use the **large 32x32** `path_resources.dmi`
  states (not the 20x20 `path_resources_small.dmi`); the cost display is meant to
  read big and clear. Key the cache by the family+tier state name so each cost
  line can look up its own icon.

- **Rarity background color** is emitted alongside so the JS fills the icon's tile
  behind the sprite with the rarity color, matching the sprite set's own rarity
  scheme (T1 green, T2 blue, T3 purple):

  ```
  data["rarity_colors"] = list(1="#3fbf5f", 2="#3f8fdf", 3="#a95fdf")
  ```

  (Placeholder hexes - match them to the exact green/blue/purple used on the
  resource icons' rarity outline so the tile and the sprite border agree.)
- **Affordability check** moves out of `UnlockNode()`'s ahn branch
  (`_path_datum.dm:543-555`): `has_money()`/`adjust_money()` become
  "have all required stacks" / `stack.use()`, per Section 6's `UnlockNode()`
  rewrite. The UI only needs the counts above to *preview* affordability; the
  authoritative spend stays server-side.

### 6.5b. JS side - `PathScreen.js`

Every ahn reference is repointed at the material data:

- **Header balance** (`PathScreen.js:161`, `:474`): replace the single
  `Ahn: {player_ahn}` readout with a compact material wallet - the main family's
  T1/T2/T3 counts and the trace family's T1/T2/T3 counts, each with its rarity
  icon. This is the "how much do I have" reference the cost lines check against.
- **Node cost panel** (`:905-915`): replace the `{node.ahn_cost} Ahn` /
  `You have: {data.player_ahn}` block with one **icon tile per** `node.cost` entry,
  laid out in a row:
  - the large 32x32 `material_icons` sprite for that family+tier, drawn on a tile
    whose **background is filled with `rarity_colors[tier]`** (green/blue/purple)
    so rarity reads at a glance from the tile color;
  - the **required amount as a number centered below the icon** (e.g. `x4`, or just
    `4`), not inline text;
  - the tile/number tinted or badged green when
    `materials[kind][tier] >= amount`, red when short (keep the affordability
    signal from the ahn version). A node is affordable only if **all** its tiles
    are satisfied.

  So a mixed bracket like Asc 2->3 main (5x T1 + 4x T2) shows two tiles - a
  green-backed icon with "5" under it and a blue-backed icon with "4" under it -
  side by side.
- **Can-afford gating** (`:431-443`, `:1191-1192`): the `player_ahn < ahn_cost`
  disable/greyout tests become "any cost line unmet", using the same per-line
  comparison. The existing `required_ascension` lock (`:434-436`, `:775-778`)
  stays and now also reflects the per-level ability gate surfaced in 6.5a.

### 6.5c. New Ascension screen

Ascension has no UI today (it was the crystal). Add an **Ascend** panel/action to
the Path Screen, next to the level/ascension readout that already exists
(`:154`), driven by the Section 5 cost table:

- `ui_data()` emits `data["ascension"] = list("phase"=ascension_phase,
  "at_cap"=<level >= current cap>, "next_cost"=<Section 5 cost for phase+1 in the
  main-family tier list shape>, "banked_exp"=<surplus past cap>)`.
- The panel shows the next phase's material cost using the **same icon-tile format
  as the trace cost panel** (large 32x32 icon, rarity-colored background, amount as
  a number below), with the same green/red affordability, plus the "you have banked
  EXP - ascend to claim it" prompt from base-plan Section 2d when banked EXP exceeds
  the cap.
- An **Ascend** button fires a new `ui_act("ascend")` that validates cap + material
  possession, consumes the stacks, and calls the existing `Ascend()`; on success
  the banked EXP releases into levels up to the new cap.

The whole change is a display+action swap: the trace/ascension **economics** are
defined in Sections 5-6; this section only makes the screens read and spend
materials instead of ahn.

---

## 7. Revisions to `BASEGAME_INTEGRATION_PLAN.md`

- **Section 2d (auto-ascension): REVERSED.** Ascension is no longer automatic; it
  is material-gated via the Path Screen Ascend action. Leveling within a phase
  stays attribute-EXP driven and free.
- **Section 3 (trace funding): REPLACED.** Traces are funded by Path Materials
  (Section 6 here), not ahn or per-level trace points.
- Section 1 (facility trait, roundstart grant), Section 2a-2c (attribute EXP
  hook), Section 4 (balance levers), and Section 5 (persistence) are unchanged.
- Persistence note extends here: **Path Materials are inventory items**, so they
  survive on the body like any stack, but a gibbed body loses them. Consider
  binding a player's materials to their `mind`/account if we want ascension
  progress to survive death (decision flagged below).

---

## 8. Balance considerations

- **Two farms, two sources.** Ascension needs the path's main material (abnos, via
  the module); traces need main material **and** Trace Material (Calyxes). A
  Pathstrider who only works/breaches abnos can ascend but cannot deepen traces past
  the early levels; one who only clears Calyxes starves their ascension. Full power
  requires engaging both the abno side (module) and the Calyx side, which is the
  core pacing lever.
- **Materials pace power, attributes pace level.** A Pathstrider who never fights
  can still level within their current cap from work-attribute EXP, but cannot
  ascend (no module material) or deepen traces (no Calyx material). This keeps a
  low-engagement path from snowballing durability (ties into base-game plan's HP
  levers).
- **The two gates are independent knobs.** Ascension pace is set by the module's
  forced-breach yield and charge regen (Section 2c); trace pace is set by Calyx
  frequency (meltdowns) and per-Calyx yield. Tune them separately: raise breach T2
  costs or lengthen charge regen to slow ascension; lower Calyx spawn count or
  per-mob yield to slow traces.
- **Top rarity is gated by the hardest sources, by material kind.** Path main T3
  (for max ascension) comes only from synthesizing up breach-obtained material, so
  it is abno-breach-gated. Trace T3 (for maxed traces) comes only from Greater/
  Fractal Calyxes, which are roundtime-gated. Both demand sustained engagement,
  matching the "not stronger than a fully-geared agent until you've earned it"
  curve. Ordeals feed nothing, so trace progression is entirely Calyx-paced.
- **Exchange tax (2:1)** and **synthesis tax (3:1)** ensure converting is always
  worse than farming the correct source, so players are pushed to engage varied
  content rather than grind one abno.
- Watch interaction with `FACILITY_TRAIT_DAMAGE_TYPE_SHUFFLE` (shuffles color
  types) - it must not desync `chem_type` sin from the material family (sin is on
  the abno datum, not the damage type, so it should be safe; confirm).

---

## 9. Open decisions

1. **Trace Material clustering** - resolved to four families (Section 1b). Open
   sub-question: keep Preservation as the solo Ward path, or fold Nihility in
   (Gloom+Sloth) so every family serves two paths and Lens becomes Erudition-only?
2. **Material persistence on death** - inventory-only (can be lost/looted) vs
   bound to mind/account? Section 7.
3. **Passive trickle rarity** - T1 only, or a rare chance at T2 on a great work
   result? Section 2a.
4. **Spend UI** - reuse the Path Screen for both Ascend and traces (recommended),
   or a dedicated station alongside the Omni-Synthesizer?
5. **Module acquisition** - roundstart with the path crystal, bought from the
   Pathstrider vendor, or a disciplinary/engineering craft?
6. **Trace supply floor** - Trace Material comes only from Calyxes (meltdown-gated),
   so a quiet shift with few meltdowns starves traces. Accept that (Calyxes are the
   deliberate farm), or add a small floor elsewhere (e.g. a rare Calyx-independent
   trickle)?
7. (Resolved - not optional) Per-level ascension gates on ability nodes are a
   firm requirement per the screenshots; see Section 6a for the level->ascension
   bracket and the `CanUnlock()` change needed. Only open sub-question: exact
   bracket if we want to diverge from the HSR-matching one in 6a.

---

## 10. Implementation checklist

- [x] `/obj/item/stack/path_material` base + 7 families x 3 tiers (parameterized).
- [x] `/obj/item/stack/trace_material` base + 4 families x 3 tiers (Fang / Lens /
      Ichor / Ward), parameterized by `family` + `tier`. (`_path_materials.dm`)
- [ ] Calyx-color -> trace-family lookup (Brown/Indigo=Fang, Green/Gold=Lens,
      Amber/Crimson/Violet=Ichor, Steel=Ward); exclude white/event; Pink has no
      Fragmentum pool so no Pink Calyx.
- [ ] Path<->sin<->family lookup table (single source of truth proc).
- [ ] Extraction Module item: attach to abnormality console; charge system (3 max,
      ~10 min regen); examine/UI charge display.
- [ ] Hook `work_complete()` for the passive T1 path-material trickle
      (Pathstrider + module).
- [ ] Abno forced-breach action reusing `disc_researcher` breach + radio alert;
      tag breacher; on-death large T1+T2 path-material drop.
- [ ] Calyx Trace-Material drops (per-mob + optional on-clear bundle), **family by
      Calyx color** and **rarity by danger tier mix** (Lesser=T1; Common=T1+T2;
      Greater=T2+T3; Fractal=richest T2+T3) - see CALYX_SYSTEM_PLAN. Ordeals drop
      NOTHING; Calyxes are the only Trace source.
- [ ] Omni-Synthesizer machine + TGUI: Synthesis (3->1 rarity up, both material
      kinds) and Exchange (2->1 path-family swap only); optional ordeal-tier gate.
- [ ] Ascension: Path Screen Ascend action consuming the phase cost table (main
      material only); remove `/obj/item/path_ascension_crystal` for trait mode.
- [ ] Traces: swap ahn in `UnlockNode()` for main + trace material per Section 6.
- [ ] Ability nodes: enforce per-level ascension gate via a level->ascension proc
      keyed on `ability_target` - TWO schedules (steep Basic ATK vs gentle
      Skill/Ult/Passive) per Section 6a (static node `required_ascension` can't
      express it); surface the requirement + locked state in `ui_data()`.
- [ ] Bonus abilities: main-material cost per Section 6c.
- [ ] UI (Section 6.5): DM side - replace `path_node.ahn_cost` with a computed
      `data["cost"]` (main + trace tier lists) in `GetNodeData()`; drop
      `player_ahn`, emit `data["materials"]` (per-family T1/T2/T3 counts) +
      `material_icons` in `ui_data()`.
- [ ] UI (Section 6.5): `PathScreen.js` - swap the ahn header/wallet, the node
      cost panel, and the can-afford gating to read material counts, keeping the
      ascension lock. Cost = large 32x32 icon tiles, tile background filled with
      the rarity color (T1 green / T2 blue / T3 purple), required amount as a
      number centered below each icon; green/red per-tile affordability.
- [ ] UI (Section 6.5c): add an Ascend panel + `ui_act("ascend")` action showing
      the Section 5 cost table and banked-EXP prompt; consume stacks and call
      `Ascend()`.
- [ ] Sprites: 21 path-material icons + 12 trace-material icons (4 families x
      3 rarities), Omni-Synthesizer (wall orb per Image #2), module item.
- [ ] Reconcile with base-game plan Sections 2d and 3 (mark them revised).
- [ ] Playtest material yield vs ascension cost across a full shift.
