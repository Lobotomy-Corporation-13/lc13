# Base-Game Integration Plan - Attribute-Driven Pathstriders

## Goal

Ship the Path system as an optional facility mode. When the mode is active,
normal Agents (and CRA agents) can become Pathstriders. Their path progression
is driven entirely by **attribute gain** instead of ahn/crystals:

- Every time an agent gains attribute levels, they gain Path EXP.
- Reaching 120 in all four attributes yields exactly enough EXP to hit path
  level 80 (max).
- No ahn, no EXP crystals, no ascension crystals for base-game Pathstriders.

The hard constraint: a Pathstrider must **flow alongside** normal agents and not
be meaningfully stronger than a same-attribute EGO agent. Paths trade EGO gear
and sanity mechanics for a self-contained stat kit; the mode is a sidegrade, not
an upgrade.

---

## 1. Enabling the mode

### 1a. New facility trait

Mirror the existing `FACILITY_TRAIT_MOBA_AGENTS` ("Agents pick a MOBA class"),
which is the closest precedent - a mode where agents pick a build at roundstart.

- Define `FACILITY_TRAIT_PATHSTRIDERS` in `code/__DEFINES/facility_traits.dm`.
- Register it in the weighted `lc_trait` list in
  `code/controllers/subsystem/maptype.dm` (start at a low weight, e.g. 3, while
  testing).
- It should be excluded on `citymaps`/`combatmaps` at first (paths were designed
  around the standard management loop); gate with the existing `AbleToRun`-style
  map checks.

### 1b. Roundstart grant

Hook `/datum/outfit/job/agent/post_equip()` (`agent.dm:171`), the same proc that
hands out the MOBA `class_chooser`:

```
if(SSmaptype.chosen_trait == FACILITY_TRAIT_PATHSTRIDERS)
    outfit_owner.equip_to_slot_or_del(new /obj/item/path_crystal(outfit_owner), ITEM_SLOT_HANDS, TRUE)
```

Reuse the existing `/obj/item/path_crystal` (Path Realm selection) so players keep
the thematic path-choice ceremony. Provide `/obj/item/path_crystal/direct` as the
fast fallback for latejoiners / low-pop rounds where the realm is disruptive.

### 1c. CRA agents

CRA (City Response) agents use their own job path. Add the same `post_equip`
branch to the CRA job outfit. CRA agents gain attributes through their own
channels; because the EXP hook lives on the attribute datum (see Section 2), it
covers them automatically with no extra work.

### 1d. Opt-in, not forced

Becoming a Pathstrider should be a **choice**. Handing the crystal (not
force-granting a path) lets a player decline and keep playing a normal EGO agent.
This is important for "flow alongside" - a round has both kinds of agent.

---

## 2. Attribute-driven progression (the core change)

### 2a. The single hook, with per-attribute high-water marks

Every attribute gain routes through `/datum/attribute/adjust_level()`
(`_attribute.dm:67`, 83 call sites). But EXP is credited against a **per-attribute
high-water mark** so attributes that are lost and later regained never pay twice.

Each path stores the highest RAW level each of the four attributes has ever been
credited for: `credited_levels = list(FORT=x, PRUD=x, TEMP=x, JUST=x)`.

```
/datum/attribute/proc/adjust_level(mob/living/carbon/human/user, addition)
    var/old = level
    level = clamp(level + addition, level_lower_limit, level_limit)
    if(level > old)
        var/datum/path/P = user.GetPath?()
        if(P)
            P.CreditAttribute(attribute_key, level)   // new
    on_update(user)
    return TRUE

/datum/path/proc/CreditAttribute(key, new_raw_level)
    var/old_mark = credited_levels[key]
    if(new_raw_level <= old_mark)
        return                                        // req 1: no re-credit
    var/old_sum = SumCredited()
    credited_levels[key] = new_raw_level              // ratchets up only
    var/award = ExpForAttrSum(SumCredited()) - ExpForAttrSum(old_sum)
    if(award > 0)
        GainExp(award)
```

**Requirement 1 satisfied.** Marks only ever ratchet up. Losing an attribute
leaves its mark untouched (no EXP lost); regaining it back up to that mark grants
nothing; only a genuine new personal best in *any* attribute pays EXP. Per
attribute (not a single total) so a loss in one attribute doesn't block credit
for real growth in another.

### 2b. Exponential EXP scaling (requirement 2)

`ExpForAttrSum(S)` is the cumulative EXP earned at a credited attribute **sum**
`S` (0..480, where 480 = 120 in all four). Define it off the real level EXP table
so awards are exponential and 480 lands exactly at max level:

```
LevelForSum(S)   = 1 + (S / 480) * 79            // linear: S=0 -> L1, S=480 -> L80
ExpForAttrSum(S) = InterpExp(LevelForSum(S))     // interpolate GetExpTable() at fractional level
```

Because `GetExpTable()` is itself exponential (L80 = 5,797,920), awarding on the
sum-delta makes **EXP per attribute point grow exponentially**: one +1 attribute
is a sliver of EXP early and a huge chunk late. A linear `LevelForSum` keeps
pathstriders from being over-leveled for their attributes:

| Credited avg | Sum S | Path level | Cumulative EXP | Share of total |
|---|---|---|---|---|
| 30  | 120 | ~21 | ~129k | 2% |
| 60  | 240 | ~40 | ~390k | 7% |
| 90  | 360 | ~60 | ~1.6M | 28% |
| 120 | 480 | 80  | 5.80M | 100% |

Half your attributes (avg 60) buys only ~7% of the EXP and reaches level 40; the
back half provides the other 93% and takes you 40 -> 80. That is the exponential
back-loading you asked for, matching how agent attribute growth gets costlier at
the top. Use **raw** levels (`get_raw_level`) so temporary EGO-gift buffs don't
move the marks. If you want pathstriders weaker still early-game, make
`LevelForSum` concave (e.g. `1 + (S/480)^1.3 * 79`) - a tuning knob.

### 2c. EXP banking past the ascension cap (requirement 3)

Ascension is now material-gated (PROGRESSION_MATERIALS_PLAN), so a pathstrider can
sit at, say, the Ascension-2 cap (level 30) while their attributes already warrant
level 50. That surplus EXP must **bank** and release the instant they pay to
ascend.

Make level a pure function of banked EXP, clamped to the current cap:

```
effective_level = min( LevelFromExp(path_exp), CurrentAscensionCap() )
```

`GainExp()` today discards EXP at the cap twice over (it returns early when at cap,
and truncates `path_exp` to the cap threshold). For trait mode both must go:

- always add the award to `path_exp` - it banks with no ceiling;
- recompute level as `min(level-from-exp, cap)`;
- surplus simply stays in `path_exp`.

On `Ascend()` (after the material cost is paid), recompute level from the
already-banked `path_exp`; the stored EXP converts to levels up to the new cap
immediately. No EXP is ever lost between earning and ascending.

**This composes with 2a and 2b for free:** `CreditAttribute()` only ever feeds
`GainExp()`, and the banking lives entirely inside `GainExp()`/level-calc
downstream. So gaining attributes while capped simply grows `path_exp`; the marks
still ratchet (so you never re-earn it), and the exponential award is banked until
you ascend. All three requirements hold together.

### 2d. Ascension is player-driven, not automatic

(Supersedes the earlier auto-ascension draft, aligned with the materials plan.)
Ascension requires spending the path's material cost via the Path Screen; it is
never automatic. Replace the old "use an Ascension Crystal" warning with a "you
have banked EXP - ascend to claim it" prompt shown when
`LevelFromExp(path_exp) > CurrentAscensionCap()`.

### 2e. Persistence & initial sync

- `credited_levels` (4 marks) and `path_exp` are the save-critical state. Store
  them on the player's mind/account so death or a new body keeps both the marks
  and the banked EXP (Section 5).
- On path selection, seed each `credited_levels[key]` from the current raw
  attribute level and set `path_exp = ExpForAttrSum(current_sum)`, so the starting
  level matches current attributes and no already-earned attribute can be
  re-credited later.

---

## 3. The trace tree (skill tree) under the new economy

The trace tree currently costs ahn per node (`UnlockNode` -> bank account).
With ahn removed we need a new funding model. Three options:

- **Option A - Auto-unlock at milestones (simplest, most predictable).**
  Grant preset trace nodes automatically at fixed path levels / ascensions. No
  player choice, no UI spend. Easiest to balance because the power curve is fixed.
- **Option B - Trace points per level (customization retained).**
  Award 1 trace point per path level; `UnlockNode` spends points instead of ahn.
  Cap the total so a maxed path cannot fill every repeatable ability node. Keeps
  the existing TGUI mostly intact (swap the currency check).
- **Option C - Attribute-gated auto-unlock.**
  Nodes unlock when the relevant attribute crosses a threshold, tying build
  identity to how the agent trained.

**Recommendation: Option B**, with a strict point budget. It preserves the
existing UI and player agency while giving us one clean knob (total points) to
keep Pathstriders from out-scaling agents. Keep the `required_ascension` /
`required_level` gates that already exist on the bonus nodes - they matter most
for power (Fighting Will, Tenacity, Ready for Battle).

Whichever we pick, the ahn balance check in `UnlockNode()` and the ahn display in
`ui_data()` must be swapped for the new currency when the trait is active.

---

## 4. Keeping Pathstriders in line (balance)

This is the section that decides whether the mode ships. Baseline problem, from
the existing analysis and `lever_4_hp_growth_reduction.md`:

- L80 path EHP ~1131 vs a same-attribute agent: ~2.7-3.5x at mid tiers, ~1.6x
  vs a fully-geared ALEPH agent.

Levers, in order of preference:

1. **Apply Lever 4 (HP growth cut).** Scale every path `stat_table` HP column so
   growth is ~4x instead of 5x (see that doc for exact per-path endpoints, e.g.
   Destruction L80 815 -> 652). Brings mid-tier ratio to ~2.7x and ALEPH-tier to
   ~1.3x. This is the single most effective knob and is already spec'd.
2. **PvE damage-taken multiplier for Pathstriders.** Paths currently have *no*
   incoming-damage scaling in PvE (only DEF DR); the HP-ratio boost in
   `species.dm:1595` is gated on `ishuman(source)` (PvP only). Add a small
   trait-gated multiplier (start ~1.15-1.25x incoming) mirroring the PvP formula
   so the big HP pool is partly paid back. Tunable and cheap to implement.
3. **Trace power cap** (Section 3) so ability output can't run past a maxed EGO
   agent.
4. **Re-tune path ATK/DPS** only if playtests show clear-speed dominance; the
   average `damage_coeff` (1.275 vs green, etc.) already keeps paths from
   exploiting weaknesses the way a correctly-typed EGO weapon can.

Qualitative factors that already push the other way (keep them, they help
balance):

- **No EGO armor** (`TRAIT_NO_EGO_ARMOR`) - Pathstriders give up the entire EGO
  armor layer, which a correctly-built agent uses to beat path DEF DR per hit.
- **Sanity immunity is a real concern.** `TRAIT_SANITYIMMUNE` +
  `TRAIT_BRUTESANITY` + `TRAIT_BRUTEPALE` make Pathstriders immune to the
  sanity/panic loop and convert WHITE/BLACK/PALE to flat brute. This trivializes
  a chunk of abnormality work-mechanics and sanity-based threats. Decide whether
  to (a) keep it (strong PvE identity, watch abno cheese) or (b) drop
  `TRAIT_SANITYIMMUNE` so Pathstriders still panic. Recommendation: drop full
  sanity immunity, keep the damage-type conversions, so paths still fear
  sanity-heavy abnos like agents do.

Target: at equal attributes, a Pathstrider should sit within roughly +/-20% of a
well-geared EGO agent on both effective HP and clear speed. Ship behind the
low-weight trait so we can tune from real rounds.

---

## 5. Lifecycle & persistence

- **Death / new body.** The path lives on a `/datum/component/path_holder`
  attached to the mob. A cloned or fresh body loses it. Store the chosen path
  type on the player's `mind` (or `SSpersistence`) and re-grant + re-sync on
  respawn/body-transfer. Note the existing guidance that mob-instance vars reset
  on death - persistent path state must survive on the datum/mind, not the mob.
- **Latejoin.** Latejoiners get the crystal in `post_equip` like everyone else;
  no special case needed.
- **Opting out / removal.** `RemovePath()` already cleanly detaches (restores
  Fortitude HP, removes traits/armor lock, deletes weapon/buttons). Expose it via
  the crystal or an admin verb so a player can revert to a normal agent.
- **Attribute sync timing.** Fire the sync on `adjust_level` positive deltas
  only; do a one-time full sync in `AssignTo` and on body-transfer.

---

## 6. Coexistence with the normal game

- **Work still functions.** Pathstriders keep their attributes and gain them
  normally from abnormality work; we only *additionally* convert those gains to
  path EXP. Attribute stat-checks in work still use the real attributes.
- **Ordeals.** Both agent types scale off attributes (agents via HP/gear +5 per
  ordeal, paths via the EXP hook off that same +5), so they climb together. See
  the ordeal analysis for per-tier survivability; the Lever 4 + PvE multiplier
  above are what keep the path from pulling ahead as ordeals escalate.
- **Trait interactions.** Audit conflicts with other facility traits, especially
  `FACILITY_TRAIT_NO_EGO` (paths already ignore EGO), `FACILITY_TRAIT_XP_MOD`
  (changes HP/SP scaling - path HP is table-based, so confirm no double-dip), and
  `FACILITY_TRAIT_DAMAGE_TYPE_SHUFFLE` (path damage pipeline reads element/coeff).
  Since only one `chosen_trait` is active at a time, these are mutually
  exclusive, which simplifies things.

---

## 7. Open decisions for you

1. **Progression curve shape** - resolved to exponential EXP via a linear
   `LevelForSum` (Section 2b). Only sub-question: keep it linear, or make it
   concave (`^1.3`) to weaken pathstriders further early-game?
2. **Trace funding** - superseded by PROGRESSION_MATERIALS_PLAN (materials, not
   ahn/points). See that doc.
3. **Sanity immunity** - keep for identity or drop for balance? Section 4.
4. **Selection flow** - full Path Realm ceremony, or streamlined direct pick for
   the base game? Section 1b.
5. **How hard to hit the HP lever** - Lever 4 alone, or Lever 4 + PvE damage
   multiplier? Section 4.

---

## 8. Implementation checklist

- [ ] `facility_traits.dm`: define `FACILITY_TRAIT_PATHSTRIDERS`.
- [ ] `maptype.dm`: add to `lc_trait` weighted list (low weight); map-type
      exclusions.
- [ ] `agent.dm` `post_equip`: grant path crystal under the trait.
- [ ] CRA job outfit: same grant.
- [ ] `_attribute.dm` `adjust_level`: call `CreditAttribute(key, level)` on
      positive delta (raw levels).
- [ ] `_path_datum.dm`: `credited_levels` (4 per-attribute high-water marks) +
      `CreditAttribute()` + `SumCredited()`; `ExpForAttrSum()`/`LevelForSum()`
      exponential curve; seed marks + `path_exp` on selection.
- [ ] `_path_datum.dm` `GainExp()`: stop discarding EXP at the cap; bank surplus
      in `path_exp`; level = `min(LevelFromExp(path_exp), CurrentAscensionCap())`;
      release banked EXP on `Ascend()`.
- [ ] Trace economy: superseded - materials, per PROGRESSION_MATERIALS_PLAN.
- [ ] Path Screen UI: trace + ascension screens show material cost, not ahn -
      see PROGRESSION_MATERIALS_PLAN Section 6.5.
- [ ] Balance: apply Lever 4 HP tables; add trait-gated PvE damage multiplier;
      decide sanity immunity; cap trace budget.
- [ ] Persistence: store path type on mind/persistence; re-grant on body change.
- [ ] Removal path: expose `RemovePath()` for opting out.
- [ ] Playtest at low trait weight; tune to +/-20% of a same-attribute EGO agent.
