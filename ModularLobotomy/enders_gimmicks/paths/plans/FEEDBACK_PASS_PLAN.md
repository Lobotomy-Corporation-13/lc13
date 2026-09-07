# Pathstriders Feedback Pass

> '''Status: implemented.''' Everything below is in the codebase and compiles at
> 0 errors / 0 warnings. Two deviations from the original plan, both noted inline:
> 4c turned out not to be a real bug, and the HUD/ally markers got purpose-drawn
> sprites (`path_hud.dmi`, `path_ally.dmi`) rather than reusing ability icons.
> The verification section at the end has not been run in-game yet.

## Context

The first public test of the Paths system (chat log: `workspace/docs/pathstriders/first testing.html`)
put roughly a dozen players on paths in the test range for a full round. The reaction was
"neat in theory, very confusing but cool" with three blocking problems and a pile of smaller ones.

Measured against the code rather than vibes:

1. **The grind is off by more than an order of magnitude.** Ascension 1 sits at Lv20 =
   112,510 EXP. A Pathstrider's Guide gives 20,000 EXP and costs 27 T1 path materials
   (27 mats -> 9 Traveler's Notes -> 3 Adventurer's Logs -> 1 Guide). So the first
   ascension costs about **152 T1 materials**. Supply is 1-2 mats per abnormality work,
   and a green T1 Calyx spawns only 3 mobs total (~4 trace mats). That is 100+ abno works
   or 20-70 Calyxes for the *first* ascension, in a two-hour shift. Players hit Lv20-22 at
   best and several said they would just play a normal Agent instead.

2. **Attacks feel limp.** Every path multiplies follow-up swings by `0.1`. At ~6 swings per
   turn that is one real hit and five that visibly land for single digits, which is what
   "MINOR DAMAGE?!", "I GAVE HIM MINOR BRUISING, LITERALLY NOTHING" and "I don't think i'm
   doing damage" were reacting to. (The counter-example raised in-round, "we massacred that
   Seaborn", does not hold up: that Seaborn is a 250 HP low-damage mob.)

3. **The turn system is invisible.** Turn state, AP and Ultimate charge all live behind an
   examine or a TGUI panel. Players spent the round shouting the rules at each other
   ("Remember to attack only when the weapon glows") and asking "How do I get AP?".

Targets agreed with Ender:

- **Fast/arcade pacing** - Ascension 1 within a few minutes, Lv60+ realistically reachable
  in one shift, Lv80 an exceptional-round goal. Traces become the long-tail progression.
- **PvE-only combat buffs.** `plans/pvp_balance.md` and `plans/lever_4_hp_growth_reduction.md`
  document a deliberate 3-lever nerf (DEF `def+300` -> `def+800`, stat tables flattened
  7.4x -> 5x, Basic scaling capped 50-110% -> 50-70%) made because paths measured
  **2.7-3.3x tankier than tier-matched agents at Lv54-80**. Nothing below rolls those back.
  All combat buffs are routed through levers that only apply to PvE, or that decay to zero
  by the level range those docs tuned.

---

## Priority 1: Progression cost

### 1a. Rewrite the EXP curve

`_path_datum.dm`, `GetExpTable()` (~line 456).

The current table is HSR's curve, built for weeks of play. Replace it with a
`1.55 * (L-1)^2.75` curve rounded to readable numbers. This keeps the "levels get slower"
shape while cutting roughly 20x at the low end and 13-22x across the rest.

| Level | Old | New | Cut |
|-------|-----|-----|-----|
| 5  | 1,600 | 70 | 23x |
| 10 | 13,560 | 650 | 21x |
| 20 | 112,510 | 5,100 | 22x |
| 40 | 497,340 | 36,750 | 13.5x |
| 60 | 1,708,870 | 115,000 | 15x |
| 80 | 5,797,920 | 256,500 | 23x |

```
list(0, 10, 20, 30, 70, 130, 210, 330, 470, 650, 870, 1150, 1450, 1800, 2200, 2650, 3150,
3750, 4400, 5100, 5850, 6700, 7600, 8600, 9700, 10750, 12000, 13500, 14750, 16250, 18000,
19500, 21250, 23250, 25250, 27250, 29500, 31750, 34250, 36750, 39500, 42250, 45000, 48000,
51250, 54500, 58000, 61500, 65000, 69000, 72750, 77000, 81250, 85500, 90000, 94750, 99500,
104500, 109500, 115000, 120500, 126000, 131500, 137500, 143500, 150000, 156500, 163000,
169500, 176500, 184000, 191000, 198500, 206500, 214000, 222000, 230500, 239000, 247500,
256500)
```

Book values (1,000 / 5,000 / 20,000) stay as they are; their relative worth rises on its
own. New costs: **Ascension 1 = 5 Traveler's Notes = 15 T1 mats**. Lv60 = ~155 T1 mats
(what Ascension 1 costs today). Lv80 = ~346 mats.

### 1b. Raise material supply

Even with the curve cut, drops are thin enough that a Calyx feels pointless.

- `fragmentum_mobs.dm`, `SpawnFragmentumLoot()` (~line 22): dawn `rand(1,2)` -> `rand(3,5)`;
  noon `rand(1,2)` -> `rand(3,5)` and the T2 roll 15% -> 35%; dusk `rand(2,4)` T2 -> `rand(3,6)`
  and the T3 roll 15% -> 35%.
- `_path_calyx.dm`, `Setup()` (~line 322): `max_spawns = max_alive + max(2, CEILING(max_alive * 0.5, 1))`
  gives a green T1 Calyx only 3 mobs over its whole life. Change to about `max_alive * 3`
  (floor of 6) so tearing one open is a real event worth the risk. `max_alive` stays as-is,
  so danger per moment is unchanged; only duration and total yield grow.
- `_path_extraction_module.dm`, `TryExtractionReward()` (~line 86): good work `1 + prob(50)`
  -> `rand(3,5)`, T2 chance 12% -> 25%; neutral 1 -> 2; bad `prob(30)` -> 1.
- `_path_extraction_module.dm`, `DropExtractionReward()` (~line 162): roughly double the
  ZAYIN/TETH and HE bands so a forced breach is worth its charge.

### 1c. Loosen trace gating

"I kinda wish at least a few of those were unlocked pre-ascend given how much effort goes
into ascending currently". With ascensions now fast this matters less, but the A6 wall is
still most of the tree.

- All seven `paths_*.dm` `InitNodes()`: shift branch gates down one step, A2 -> A1,
  A4 -> A3, A6 -> A5, on both `required_ascension` and the matching comments.
- `_path_cost.dm`, `AbilityCostRow()` (~line 133): cap the `asc` column at 5 instead of 6 in
  both `basic_sched` and `gentle_sched`.

---

## Priority 2: Combat feel (PvE-only)

Three changes, all gated so `pvp_balance.md` and `lever_4` remain accurate. The PvP path in
`deal_path_damage()` (`pvp_factor`, HP-ratio scaling, armor average) is not touched.

### 2a. Follow-up swings (the big one)

Every path has `if(!first_hit) total_damage *= 0.1` in its basic `OnHit()`:
`paths_abundance.dm:159`, `paths_destruction.dm:127`, `paths_erudition.dm:116` and `:127`,
`paths_harmony.dm:117`, `paths_hunt.dm:120`, `paths_nihility.dm:110`,
`paths_preservation.dm:230`.

Replace the literal with a single define in `_path_defines.dm`:

```
/// Damage fraction for basic swings after the first hit of a turn.
#define PATH_FOLLOWUP_MULT 0.3
```

At Lv20 that takes a turn's basic output from `79 + 5x7.9 = 119` to `79 + 5x23.7 = 197`.
One constant to retune later instead of eight scattered literals.

### 2b. PvE damage multiplier

`_path_datum.dm`, `deal_path_damage()`. Add a multiplier applied only when the target is
**not** a human, placed next to the existing elemental-bonus step and before the PvP block:

```
/// PvE-only damage scalar. Paths hit mobs harder without touching PvP tuning.
#define PATH_PVE_DAMAGE_MULT 1.5
```

Because it is skipped for `ishuman(target)`, every number in `pvp_balance.md` stays exact.
Combined with 2a this is roughly 4-5x a path's per-turn PvE output at equal level. At Lv60
that is about 720 damage per turn, so a 2,000 HP Crimson Dusk takes ~3 turns.

### 2c. Low-level damage-reduction floor

The "my armor's at 24% at Ascension 1", "I nearly lost a 1v1 with forsaken murderer while
consistently popping skills" and "I die so fast" complaints are all from Lv20, where
`DEF/(DEF+800)` yields ~12.5%. But lever_4 shows paths are already *too* tanky by Lv54-80,
so the curve itself is right and only the floor is wrong.

Add a decaying bonus rather than changing the formula: a flat DR that starts at 12% at Lv1
and reaches 0% at Lv60, applied multiplicatively alongside the existing term in
`ApplyDefense()` (~line 412). Lv20 lands at ~21%, Lv40 at ~19%, and Lv60+ is **exactly**
lever_4's tuned endpoint, so both docs stay true. Implement as a small
`GetLowLevelDR()` proc so it can be deleted wholesale if faster leveling alone fixes the feel.

Stat tables, Basic scaling caps and the `def+800` denominator are all left alone.

---

## Priority 3: Turn / AP / Ultimate HUD

The single most requested change: "the turn timer needs to be constantly visible as like a
spinner somewhere that isnt the fuckin ui info panel", "there should be a sound that
signifies your turn", "AP and turn should be more visible", "i'd love to just have a bar on
my screen that tells me my ap honestly, same with ult btw".

New file `ModularLobotomy/enders_gimmicks/paths/_path_hud.dm`, plus a `#include` in
`lobotomy-corp13.dme` next to the other path files (~line 4422; note the DME uses backslashes).

### Sprites

Purpose-drawn at `ModularLobotomy/_Lobotomyicons/path_hud.dmi` (19 states, 32x32):
`turn_ready` / `turn_spent`, `ap_0` through `ap_5`, `energy_0` through `energy_10`.
Gold matches the `#FFD700` turn-ready weapon outline in `_path_weapon.dm` so the
HUD and the weapon glow read as one signal; the energy bar runs cyan while
charging and flips to gold with a full outline once the Ultimate is usable.
Generator script kept out of the repo; it is pure zlib/struct, no Pillow.

### Elements and exact positions

The existing info column runs up the bottom-right edge at `EAST-1`, defined in
`code/_onclick/hud/_defines.dm`: `ui_internal` at `CENTER-3:10`, `ui_healthdoll` at
`CENTER-2:13`, `ui_health` at `CENTER-1:15`, `ui_mood` at `CENTER+1:19`. Continue that same
column upward so the path readouts sit directly above the health doll, in the spot players
already look:

| Element | New define | screen_loc | Shows |
|---|---|---|---|
| Turn indicator | `ui_path_turn` | `EAST-1:28,CENTER+2:21` | Ready / attacked / skilled, with maptext counting down to next turn |
| AP pips | `ui_path_ap` | `EAST-1:28,CENTER+3:23` | `action_points` / `max_action_points` |
| Energy bar | `ui_path_energy` | `EAST-1:28,CENTER+4:25` | `energy` / `max_energy`, highlighted at full so the Ultimate reads as ready |

Add the three defines to `code/_onclick/hud/_defines.dm` alongside the existing `ui_*` block.

### Keeping it private to its owner

These are personal readouts and must not be visible to anyone else.

Append the three `/atom/movable/screen` objects to `owner.hud_used.infodisplay`
(`code/_onclick/hud/hud.dm:49`). `/datum/hud/show_hud()` pushes that list into
`screenmob.client.screen` only, so the objects exist solely in the owning player's own
screen list. No other client ever receives them, and `QDEL_LIST(infodisplay)` handles
teardown. Do not edit `hud.dm` itself, only append to the list.

This is deliberately the *opposite* of the ally-indicator technique in
`ModularLobotomy/associations/skills/_designate_ally.dm`, which pushes `image`s into
**other** players' `client.images` to make something visible to teammates. Screen objects in
`infodisplay` never leave the owner's client; that mechanism is what Priority 5a uses, and
it is not used here.

One inherited caveat, not a bug: a ghost or admin who *observes* a mob gets `show_hud()`
called with themselves as `screenmob`, so they see the path HUD the same way they already
see that mob's health doll. That is existing engine behaviour for every HUD element.

### Wiring

Refresh from existing procs: `OnTurnReset()` and `StartTurnCycle()` for turn state,
`GainEnergy()`/`SpendEnergy()` for the bar, `GainActionPoint()`/`SpendActionPoint()` for pips.
Register `COMSIG_MOB_LOGIN` so the objects survive a reconnect, and remove them from
`infodisplay` in `/datum/path/Remove()`.

Add the two requested sound cues: a short chime in `OnTurnReset()` when the turn comes up,
and a lighter blip in `GainActionPoint()`.

Keep `ShowTurnReady()`/`ClearTurnReady()` on the weapon. The golden outline was called
"helpful", just insufficient alone.

---

## Priority 4: Bugs

### 4a. Skill eats the turn and AP on a whiff (highest-value bug)

"i don't like my turn being spent if i fail to find a target with a skill", "using my skill
as the hunt path, if i dont find a target, it puts my shit on cd for the rest of the turn".

`_path_weapon.dm`, `attack_self()` (~lines 96-104) spends the AP, grants energy and sets
`PATH_TURN_SKILLED` *before* calling `Activate()`. Hunt's `Activate()` then returns early
with "Cloudlancer Art: Torrent missed - no enemy in range!" and the turn is gone anyway.

Fix: make `/datum/path_ability/burst/proc/Activate()` return TRUE on a connect and FALSE on
a whiff, then in `attack_self()` call `Activate()` first and only spend AP, grant energy and
set `turn_state`/`first_hit_this_turn` when it returns TRUE. Update all seven `paths_*.dm`
burst `Activate()` overrides to return a value. Mechanical, but touches every path file.
Buff/ally skills (Harmony, Preservation, Abundance) should return FALSE when they find no
valid ally, for the same reason.

### 4b. Hunt skill targets multitile projectile blockers

"my dash/ult is targeting projectile blocker dummies from multitile mobs".

`paths_hunt.dm` burst `Activate()` target scan, and the Ultimate's scan: the
`for(var/mob/living/L in CT)` loops need to skip projectile-blocker dummy mobs the same way
they already skip `IsPathAlly` and `stat == DEAD`. Add a shared
`IsValidPathTarget(mob/living/L, mob/living/user)` helper in `_path_allies.dm` and use it in
every path's target scan, since the same loop is copy-pasted across all seven files.

### 4c. Typo - NOT A BUG, no change made

This item was wrong. All 27 in-game occurrences in the log spell "Cloudlancer"
correctly, and every occurrence in the codebase does too. The single "Cloudlancert"
is at log line 2282, where Destrok re-typed the message by hand into OOC and
typo'd it himself. Nothing to fix.

### 4d. Only one player ever sees the Path Realm quiz

"Oh, no personality quiz." / "You're the only one who got to see the cool cutscene quiz."

Root cause: `_path_realm.dm` uses `GLOBAL_VAR(path_realm_active)` as a single-occupancy
lock, and `_path_items.dm` `path_crystal/attack_self()` refuses with "The Path Realm is
already open. Please wait." for everyone else. During the test the crew was handed the
`path_crystal/direct` variant, which skips the realm entirely, so almost nobody saw the
sequence that is arguably the best part of the feature.

The realm is already instance-safe: `Start()` loads its own Z-level via `load_new_z()` and
filters every landmark lookup by `z_level`. Only the lock is in the way. Change
`GLOB.path_realm_active` to a list of active realms, have `New()`/`Destroy()` add and remove
from it, and drop the refusal in `attack_self()`. Cap concurrency (4 or so) to bound
Z-level loading, and queue rather than reject past that.

---

## Priority 5: UX and discoverability

### 5a. Ally indicators (port the association pattern)

The loudest recurring noise in the entire log was people yelling "ADD ME AS ALLY", "SET YOUR
FUCKIN ALLIES!!", "we forgor to set allies", plus constant AoE friendly fire.

`_path_allies.dm:8` says it is "Based on the association designate_ally pattern", but it
kept only the tgui_input_list toggle and **dropped the visual layer entirely**. There is
currently no way to look at someone and know whether they are your ally. The association
version in `ModularLobotomy/associations/skills/_designate_ally.dm` already solves this with
`/datum/status_effect/display/ally_indicator` (lines 184-259): a client-side `image` over the
ally's head, pushed only into allied players' `client.images`, with `refresh_viewers()` to
re-sync on change and `AddDisplayIcon()` handling grid positioning against other display
effects.

Port it rather than reinventing it. The icon, positioning and refresh machinery are all
reusable; only the "who can see this" query differs, since `add_to_allied_clients()`
(line 223) is hardcoded to `association_exp` and `GLOB.association_squads`. Subclass it with
a path-aware version reading `GLOB.path_ally_lists`, keeping both directions the original
checks: people you allied, and people who allied you.

Also worth porting from the same file:

- `refresh_ally_indicators()` calls on every toggle in `path_designate_ally/Trigger()`
  (`_path_allies.dm:72-79`), which currently only sends chat messages.
- The `/datum/action/innate/view_allies` equivalent (line 108), so a designated ally can see
  who considers them one and re-sync indicators after aghosting.
- Removal on unally, mirroring lines 59-61.

One path-specific addition: `GetMutualPathAllies()` drives AP sharing and requires
*mutual* designation, which was invisible and is why AP propagation silently did nothing
for most of the round. The marker distinguishes the two states, and because "is this
mutual" depends on who is looking, each viewer gets their own image rather than one shared
one. Two new 10x10 states in `ModularLobotomy/_Lobotomyicons/path_ally.dmi`: `path_ally`
(hollow diamond, one-way) and `path_ally_mutual` (filled with cyan ticks, AP sharing live).

Targeting was also addressed here rather than in 5b: single-target support now goes through
`GetSupportTarget()`, which prefers an explicitly focused ally over the nearest one. The
Designate Ally menu gained a FOCUS entry per existing ally to set it.

Finally, add a warning when an AoE ability damages a non-ally human ("X is not your ally -
designate them with the Designate Ally button"). That message alone would have prevented
most of the round's friendly fire confusion.

### 5b. Other UX

- **Level cap visibility.** "Wait I'm level 1 of 1", "I'm stuck at level 1?" - the attribute
  cap (`GetAttributeCap()`) had to be explained over LOOC. Surface it in `_path_ui.dm` as
  "Lv.12 / cap 27 (raise attributes)" and in the weapon `examine()`. The existing warning in
  `GainExp()` only fires on EXP gain, which is too late.
- **Armor visibility.** "why doesn't our gear give us armor", "how do I know our armor".
  The cosmetic suits read as broken armor. Add a line to the path suit `desc` saying it is
  cosmetic and that protection comes from the path's DEF stat, and show DEF as a percentage
  reduction in the path screen, not a raw number.
- **Synthesizer QoL** (already promised in-round). Vera: "It'd be really nice QOL if you
  could upgrade while tabbed into the synthesizer, instead of having to withdraw stuff."
  `_path_omni_synth.dm` banks materials in `stored`, but `_path_cost.dm` `CountMat()`/
  `SpendMat()` only read `owner.GetAllContents()`. Let trace and ascension spending draw
  from an adjacent Omni-Synthesizer's `stored` list as a fallback source.
- **Harmony heal targeting.** "I cant choose who toheal" - Harmony's Skill and Ultimate pick
  "the nearest designated ally", which is not controllable. Prefer the ally under the
  crosshair or last-designated over nearest.

---

## Priority 6: Documentation

"Do we have wiki for it?" came up and went unanswered. Write a short in-repo player wiki
following the association convention (`ModularLobotomy/associations/wiki_seven.md`): the turn
loop, AP and energy, allies, where materials come from, how leveling and the attribute cap
interact, and what traces do. Keep it to one page; the design docs in `plans/` are for us,
not players.

---

## Verification

Compile first: `dm.exe lobotomy-corp13.dme` must come back 0 errors / 0 warnings. Priorities
2a and 4a touch all seven path files, so a compile catches most of the risk there.

Then run a round and check in this order:

1. **Progression.** Spawn a path, admin-grant ~15 T1 materials, refine to Traveler's Notes at
   the synthesizer, confirm Ascension 1 lands in a couple of minutes. Confirm banked EXP past
   the cap still releases on ascend (`RefreshLevel()` in `DoAscend()`).
2. **Drops.** Spawn `/obj/structure/calyx/green/t1` and `/obj/structure/calyx/steel/t3`,
   clear both, count the stacks. A T1 Calyx should be worth a few early levels, not a
   rounding error.
3. **Damage.** At Lv20, confirm follow-up swings read as a real fraction of the first hit
   rather than single digits, and time a 400 HP Green Dawn kill (target: about one turn).
4. **PvP untouched.** Two path users and one non-path human. Confirm path-vs-human damage is
   unchanged from before the pass; the `PATH_PVE_DAMAGE_MULT` branch must not fire for
   `ishuman(target)`.
5. **HUD.** Confirm the turn indicator counts down, AP pips change on hit, and the energy bar
   highlights at full. Reconnect mid-round and confirm the objects return. Drop the path and
   confirm they are removed, not orphaned on screen. **Have a second player stand adjacent and
   confirm they see none of it.**
6. **Whiff fix.** As Hunt, use the Skill facing empty space: AP unchanged, turn still usable,
   golden outline retained. Then hit a real target and confirm AP is spent normally.
7. **Multitile.** Use the Hunt Skill and Ultimate next to a multitile abnormality; confirm it
   hits the mob, not a projectile blocker.
8. **Allies.** Two path users designate each other. Confirm the overhead indicator appears for
   both, is visible only to them and not to a third uninvolved player, distinguishes one-way
   from mutual, disappears on unally, and that AP propagation fires on mutual designation.
9. **Realm concurrency.** Give two players a `path_crystal` and have both use it at once.
   Both should get the quiz on separate Z-levels and return to their own bodies.
10. **Survivability.** At Lv20 the path screen should show roughly 21% reduction; a forsaken
    murderer 1v1 should be winnable while using skills. At Lv60+ confirm the low-level DR
    bonus has decayed to zero and matches lever_4's tuned figures.
