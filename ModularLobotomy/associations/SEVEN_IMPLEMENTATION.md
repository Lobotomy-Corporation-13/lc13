# Seven Association — Implementation Steps

## Overview

Implements the Seven Association ("The Eye") skill tree and investigation toolkit. Seven are professional detectives who specialize in intelligence gathering and surgical retribution. Their skills revolve around the Rupture status effect and debuff exploitation.

## What Already Exists

- **Weapons (Section 6)**: `seven` blades + `seven_fencing` foils in `ModularLobotomy/ego_weapons/melee/city/seven.dm` — OLD stored-target mechanic, kept as-is for Section 6
- **Armor**: 5 variants in `code/modules/clothing/suits/ego_gear/non_abnormality/seven.dm` — keep as-is
- **Equipment box**: `association_beacon.dm` lines 104-120 — keep, may add investigation items later
- **Legacy skills**: `ModularLobotomy/associations/skills/seven/` — `skillgranter.dm`, `associate.dm`, `veteran.dm`, `director.dm` — will be REPLACED
- **Skill framework**: `association_skill.dm`, `association_exp.dm`, `association_skill_tree.dm`, `_designate_ally.dm` — COMPLETE, ready to use
- **Status effects**: Rupture, Fragile, Feeble, Offense/Defense Level Up/Down — all exist in `code/datums/status_effects/debuffs.dm` and `buffs.dm`
- **Contract system**: Complete (contract_datum, contract_terminal, contract_item, contract_types, distress)
- **GLOB definitions pattern**: `_test_skills.dm` shows the init pattern, `init_association_skill_definitions()` is the entry point

---

## Phase 1: New Section 4 Weapons (Rupture + Adaptive Damage)

Create new Seven Section 4 weapons alongside the existing Section 6 weapons. The old weapons keep their stored-target mechanic untouched. New Section 4 weapons use the Rupture system.

### Step 1.0 — Update Old Weapons (Section 6 Labels)

**File:** `ModularLobotomy/ego_weapons/melee/city/seven.dm`

Update the existing weapons' `name` and `desc` to clarify they are from Section 6:

- `seven` → name: `"Seven Association Section 6 blade"`, desc: `"A sheathed blade used by Seven Association Section 6 fixers."`
- `seven/vet` → name: `"Seven Association Section 6 veteran blade"`, desc updated similarly
- `seven/director` → name: `"Seven Association Section 6 director's blade"`
- `seven/cane` → name: `"Seven Association Section 6 director's cane"`
- `seven_fencing` → name: `"Seven Association Section 6 fencing foil"`, desc updated
- `seven_fencing/vet` → name: `"Seven Association Section 6 veteran fencing foil"`
- `seven_fencing/dagger` → name: `"Seven Association Section 6 fencing dagger"`

No mechanical changes to old weapons.

### Step 1.1 — New Sidearms (Section 4 Foils + Dagger)

**File:** `ModularLobotomy/ego_weapons/melee/city/seven_s4.dm` (NEW)

Create new `/obj/item/ego_weapon/city/seven_s4_foil` tree — Section 4 Rupture-building sidearms:

- Base foil: `name = "Seven Association Section 4 fencing foil"`, `desc = "A fencing foil used by Seven Association Section 4 fixers. Inflicts Rupture on targets."`, BLACK damage, same icon/stats as old foil
- `var/base_rupture = 6`, `var/falloff_rate = 5`
- Override `attack()`: after `..()`, read target's current Rupture stacks, calculate `max(1, base_rupture - round(current_stacks / falloff_rate))`, apply via `target.apply_lc_rupture(amount)`
- `seven_s4_foil/vet`: `falloff_rate = 7`, veteran stats/icons
- `seven_s4_foil/dagger`: `falloff_rate = 10`, director stats/icons, `attack_speed = 0.5`, fits EGO belt

### Step 1.2 — New Main Weapons (Section 4 Blades + Cane)

**File:** `ModularLobotomy/ego_weapons/melee/city/seven_s4.dm`

Create new `/obj/item/ego_weapon/city/seven_s4_blade` tree — Section 4 adaptive damage blades:

- Base blade: `name = "Seven Association Section 4 blade"`, `desc = "A blade used by Seven Association Section 4 fixers. Adapts its damage type to exploit target weaknesses when Rupture is active."`, BLACK damage, same force/stats as old blade
- `var/can_adapt_pale = FALSE`, `var/pale_penalty = 0.85`
- Override `attack()`: before `..()`, check target for 10+ Rupture stacks. If yes, call `get_weakest_resistance(target)` to find the damage type with least resistance. Set `damtype` accordingly. If PALE and `can_adapt_pale`, apply `force *= pale_penalty`. After `..()`, reset `force = initial(force)` and `damtype = BLACK_DAMAGE`
- Add `proc/get_weakest_resistance(mob/living/target)`: check `RED_DAMAGE`, `WHITE_DAMAGE`, `BLACK_DAMAGE` (+ `PALE_DAMAGE` if `can_adapt_pale`). For humans: `getarmor(null, dtype)` — lowest wins. For simple mobs: `damage_coeff[dtype]` — highest wins
- `seven_s4_blade/vet`: veteran stats/icons
- `seven_s4_blade/director`: `can_adapt_pale = TRUE`, director stats/icons
- `seven_s4_blade/cane`: `can_adapt_pale = TRUE`, lower force, faster attack speed

### Step 1.3 — New Equipment Box for Section 4

**File:** `ModularLobotomy/associations/association_beacon.dm` (MODIFY)

Add a new equipment box `/obj/item/storage/box/association/seven_s4` alongside the existing Section 6 box:
- Contains Section 4 foils, blades, and cane variants
- The beacon's Seven choice should spawn this box instead of (or in addition to) the Section 6 box
- Section 6 box remains available for legacy/alternate use

---

## Phase 2: Skill Tree Definitions + Registration

### Step 2.1 — Create Seven Skill Definition Init

**File:** `ModularLobotomy/associations/skills/seven/seven_skill_defs.dm` (NEW)

Create `proc/init_seven_skill_definitions()` following the pattern in `_test_skills.dm`:

```
/proc/init_seven_skill_definitions()
    if(!GLOB.association_skill_definitions[ASSOCIATION_SEVEN])
        GLOB.association_skill_definitions[ASSOCIATION_SEVEN] = list()
    var/list/seven_defs = GLOB.association_skill_definitions[ASSOCIATION_SEVEN]

    // Analyst branch
    seven_defs["Analyst"] = list(
        "tier1" = list(
            "a" = list("name" = "Case File", "desc" = "...", "type" = /datum/component/association_skill/seven_case_file),
            "b" = list("name" = "Profiling", "desc" = "...", "type" = /datum/component/association_skill/seven_profiling),
        ),
        "tier2" = list(...),
        "tier3" = list(...),
    )
    // Coordinator branch
    // Operative branch
```

### Step 2.2 — Register in Global Init

**File:** `ModularLobotomy/associations/skills/_test_skills.dm`

Add `init_seven_skill_definitions()` call to `init_association_skill_definitions()`.

---

## Phase 3: Analyst Branch Skills

**File:** `ModularLobotomy/associations/skills/seven/analyst.dm` (NEW)

All skills inherit from `/datum/component/association_skill` and call `can_use_skill()` in their signal handlers.

### Step 3.1 — Mark Target Action

**File:** `ModularLobotomy/associations/skills/seven/mark_action.dm` (NEW)

Create `/datum/action/cooldown/seven_mark_target` — a pointed spell action (mirrors `thin_line.dm` targeting pattern):
- `InterceptClickOn()` to select target
- Stores `var/mob/living/marked_target` on the component
- One mark at a time, re-marking removes old mark
- Mark persists until re-marked or target dies
- Visual indicator on marked target (use overlay or status effect)
- The mark action is granted by T1a (Case File) — stored as a var on the skill component, granted in `Initialize()`

### Step 3.2 — T1a: Case File

`/datum/component/association_skill/seven_case_file`
- Grants Mark Target action on Initialize
- `on_attack()`: if target is marked target → apply 2 Rupture + bonus BLACK damage = `min(40, rupture_stacks) * 0.01 * weapon.force`
- Bonus damage via `INVOKE_ASYNC` → `target.apply_damage(bonus, BLACK_DAMAGE)`

### Step 3.3 — T1b: Profiling

`/datum/component/association_skill/seven_profiling`
- Grants Mark Target action on Initialize
- `on_attack()`: if target is marked target → apply 2 Offense Level Up to self (max 10 from this skill, tracked via `var/stacks_granted`)

### Step 3.4 — T2a: Exploit Weakness

`/datum/component/association_skill/seven_exploit_weakness`
- `on_attack()`: if target is marked → apply 2 Defense Level Down (1s CD)
- Register on marked target's `COMSIG_MOB_AFTER_APPLY_DAMGE` → when Rupture triggers (detect via damage source type) and stacks were 15+ → apply 5 Fragile
- Must re-register signal when mark changes

### Step 3.5 — T2b: Patient Hunter

`/datum/component/association_skill/seven_patient_hunter`
- `on_attack()`: if target is marked and has 10+ Rupture → deal 25% more damage (via modifying weapon force before attack or adding extra damage after). If 20+ Rupture → also deal bonus BLACK = 15% of weapon force

### Step 3.6 — T3a: Dossier Complete (Powerful Attack)

`/datum/component/association_skill/seven_dossier_complete`
- Grants `/datum/action/cooldown/dossier_complete` (90s CD)
- Requires: target is marked target, target has 10+ Rupture
- Dash to target from up to 6 tiles (tiantui pattern from `thumb.dm`)
- Apply duel component + immobilize
- 4-hit combo: per-hit damage = `DPS * (1 + current_rupture_stacks * 2 / 100) / 4`
- Per-hit: apply 2 Offense Level Down
- Final hit: 2x damage, knockback 2 tiles, 5 Fragile
- Rupture NOT consumed (but may trigger from the BLACK hits, halving stacks mid-combo)

### Step 3.7 — T3b: Surveillance Network (Passive)

`/datum/component/association_skill/seven_surveillance_network`
- Register on parent's `COMSIG_MOB_AFTER_APPLY_DAMGE` to detect Rupture trigger burst damage
- On Rupture trigger: AoE BLACK damage = rupture stacks to enemies in `range(3, target)` (x2 if marked target, x4 for simple mobs)
- On kill: apply 15 Rupture to all non-ally mobs in `range(3, target)`
- Kill detection: register `COMSIG_LIVING_DEATH` on the target when attacking

---

## Phase 4: Coordinator Branch Skills

**File:** `ModularLobotomy/associations/skills/seven/coordinator.dm` (NEW)

### Step 4.1 — T1a: Intel Briefing

`/datum/component/association_skill/seven_intel_briefing`
- `on_attack()`: if target has Rupture status effect → iterate designated allies in `range(5, owner)` → `ally.apply_lc_offense_level_up(3)`. 1s CD.

### Step 4.2 — T1b: Weak Point Analysis

`/datum/component/association_skill/seven_weak_point_analysis`
- `on_attack()`: apply 3 Defense Level Down (1s CD). If target has 10+ DLD stacks → iterate allies in range(5) → apply 3 OLU. Same 1s CD shared.

### Step 4.3 — T2a: Comprehensive Report

`/datum/component/association_skill/seven_comprehensive_report`
- `on_attack()`: if target has 15+ active Rupture → 10s per-target CD → allies in range(5) get 2 Strength + target gets 4 OLD. Visual temp effect on target turf.

### Step 4.4 — T2b: Disinformation

`/datum/component/association_skill/seven_disinformation`
- `on_attack()`: apply 2 Offense Level Down + 2 Feeble to target. 1.5s CD.

### Step 4.5 — T3a: Full Exposure (Powerful Attack)

`/datum/component/association_skill/seven_full_exposure`
- Grants `/datum/action/cooldown/full_exposure` (120s CD)
- Opener: AoE ground slam, 4-tile radius. All enemies get 2 Fragile + (3 + 3*ally_count) DLD + (3 + 3*ally_count) OLD + 2 Feeble. Count allies in range(6), max 3.
- Pick closest hostile → duel component → 3 hits
- Per-hit: apply `3 + round((total_ally_OLU + target_OLD) / 5)` Rupture
- Final hit: force-trigger all Rupture on target immediately (bypass 5s delay)

### Step 4.6 — T3b: Undermining Presence (Passive)

`/datum/component/association_skill/seven_undermining_presence`
- `on_attack()`: if target has any positive stacking buff (DLU, OLU, Strength, Protection) → strip 2 stacks of each
- Designated allies who attack debuffed targets within 5 tiles heal for 3% of damage dealt
- Ally healing: register on allies' attack signals (re-register when ally list changes)

---

## Phase 5: Operative Branch Skills

**File:** `ModularLobotomy/associations/skills/seven/operative.dm` (NEW)

### Step 5.1 — T1a: Shadow Step

`/datum/component/association_skill/seven_shadow_step`
- `on_attack()`: get target's OLD + DLD stacks → `rupture = min(8, round((old + dld) / 2))` → if > 0: apply Rupture

### Step 5.2 — T1b: Quick Assessment

`/datum/component/association_skill/seven_quick_assessment`
- Track `var/mob/living/last_target` and `var/consecutive_hits`
- `on_attack()`: if different target → reset consecutive to 0. Apply rupture: 0→5, 1→3, 2→1, 3+→0. Increment counter, update last_target.

### Step 5.3 — T2a: Rupture Cascade

`/datum/component/association_skill/seven_rupture_cascade`
- Detect when owner's attack triggers Rupture burst on target → apply 7 Rupture to all enemies in range(3, target) excluding target. 1s CD.

### Step 5.4 — T2b: Pressure Points

`/datum/component/association_skill/seven_pressure_points`
- `on_attack()`: count unique debuff types on target (Fragile, Feeble, DLD, OLD — NOT Rupture itself) → apply that many Rupture stacks (max +4 per hit)

### Step 5.5 — T3a: Surgical Strike (Powerful Attack)

`/datum/component/association_skill/seven_surgical_strike`
- Grants `/datum/action/cooldown/surgical_strike` (90s CD)
- Requires: target has at least one debuff (Rupture/Fragile/Feeble/DLD/OLD)
- Vanish (alpha=0, immobilize self) for 2s
- After 2s: if target within 7 tiles + LoS → teleport behind, begin combo. If not → cancel, refund CD.
- 5-hit combo: per debuff type on target, +15% damage (max +75% with all 5)
- Per-hit: 2 Rupture. First hit: 3 Fragile
- Final hit: zoro overlay flash, 2x DPS, knockback 2 tiles, bonus BLACK = target's current Rupture stacks

### Step 5.6 — T3b: Detonation Order (Passive)

`/datum/component/association_skill/seven_detonation_order`
- `on_attack()`: if target has < 20 Rupture stacks → apply 4 Rupture

---

## Phase 6: Powerful Attack Shared Infrastructure

### Step 6.1 — Cutscene Duel Component

**File:** `ModularLobotomy/associations/skills/_cutscene_duel.dm` (NEW, if not already created)

Check if this already exists. If not, create a shared component/datum for powerful attack sequences:
- Immobilize attacker + target
- Prevent outside damage/interference during combo
- Handle cleanup on mob death/deletion mid-combo
- Pattern from `thumb.dm` tiantui flurry

### Step 6.2 — DPS Calculation Helper

Add a shared helper proc to `association_skill.dm` or a new utility file:
```
/datum/component/association_skill/proc/get_weapon_dps(obj/item/ego_weapon/W)
    return W.force * W.force_multiplier * 1.25 / W.attack_speed
```

---

## Phase 7: Investigation Toolkit (Items)

These are Seven's unique investigation items for EXP generation. Implement in order of dependency.

### Step 7.1 — Seven Camera

**File:** `ModularLobotomy/associations/skills/seven/investigation_items.dm` (NEW)

`/obj/item/camera/seven_intel`:
- Subtype of `/obj/item/camera`
- No flash, no shutter sound, silent visible_message
- Creates `/datum/seven_intel_snapshot` on each photo: target name, role, area, held items, round time
- Stores snapshot list on camera
- Photo desc includes round time via `gameTimestamp()`

### Step 7.2 — Intel Snapshot Datum

**File:** `ModularLobotomy/associations/skills/seven/intel_report.dm` (NEW)

`/datum/seven_intel_snapshot`:
- `var/target_name`, `var/target_role`, `var/area_name`, `var/list/held_items`, `var/round_time`
- Created by Seven Camera, attached to photos

### Step 7.3 — Blank Intel Report

**File:** `ModularLobotomy/associations/skills/seven/intel_report.dm`

`/obj/item/paper/intel_report`:
- Link to a photo by hitting photo with report → copies snapshot
- Use in-hand → TGUI form with fields: Target Name, Role, Round Time, Held Items, Backpack Contents, Extra Notes
- File on dossier → validate fields against snapshot via `findtext()` → award EXP (5 base + up to 10 accuracy bonus)
- 1 report per target per 2 minutes cooldown

### Step 7.4 — Seven Recorder

**File:** `ModularLobotomy/associations/skills/seven/investigation_items.dm`

`/obj/item/seven_recorder`:
- Disguise system: hit an item to copy its appearance
- Floor placement: place on turf, records `Hear()` messages in range
- Item attachment: `forceMove()` into item, registers `COMSIG_MOVABLE_HEAR`
- EXP tracking: 1 EXP per 5 lines, max 5 EXP/min per recorder
- 10-min stealth window for attached recorders (invisible on examine for 10 min)
- Max 3 active per fixer

### Step 7.5 — Backpack Scanner

**File:** `ModularLobotomy/associations/skills/seven/investigation_items.dm`

`/obj/item/seven_scanner`:
- Click on carbon mob within 5 tiles
- 3s internal timer (no progress bar), maintain LoS
- Shows target's backpack contents via `to_chat()`
- Silent — no visible message to target

### Step 7.6 — Investigation Dossier

**File:** `ModularLobotomy/associations/skills/seven/dossier.dm` (NEW)

`/obj/item/seven_dossier`:
- Stores filed reports indexed by subject name
- TGUI interface showing report list, accuracy scores, summary stats
- Use completed Intel Report on dossier to file it

**TGUI:** `tgui/packages/tgui/interfaces/SevenDossier.js` (NEW)

### Step 7.7 — Recorder Receiver

**File:** `ModularLobotomy/associations/skills/seven/investigation_items.dm`

`/obj/item/seven_receiver`:
- Links to deployed recorders
- Use in hand → TGUI panel listing active recorders
- Tune in to hear real-time `Hear()` messages from selected recorder
- One recorder at a time

### Step 7.8 — Spyglass Kit

**File:** `ModularLobotomy/associations/skills/seven/investigation_items.dm`

`/obj/item/storage/box/seven_spyglass`:
- Contains spy glasses + pocket protector (Seven subtypes of existing spy system)
- Spy glasses: live camera feed popup
- EXP: 1 per 30s while popup open and on contract

### Step 7.9 — Seven Requisition Catalog

**File:** `ModularLobotomy/associations/skills/seven/investigation_items.dm`

`/obj/item/seven_catalog`:
- Handheld shop, use in hand → TGUI
- Purchase investigation items for ahn from ID card bank account
- Items: Recorder (200), Camera (150), Intel Report x3 (50), Scanner (200), Spyglass Kit (300), Surveillance Glasses (250), Dossier (100), Receiver (150)

**TGUI:** `tgui/packages/tgui/interfaces/SevenCatalog.js` (NEW)

---

## Phase 8: Seven-Specific Contracts

### Step 8.1 — Investigate Person Contract

**File:** `ModularLobotomy/associations/contracts/contract_types.dm` (ADD)

`/datum/association_contract/investigate_person`:
- Seven-only, objective-based
- Requires X Intel Reports filed (2/3/5 based on tier), each 2 min apart
- Tracks filed report count and timestamps
- Complete when enough valid reports filed

### Step 8.2 — Surveillance Post Contract

**File:** `ModularLobotomy/associations/contracts/contract_types.dm` (ADD)

`/datum/association_contract/surveillance_post`:
- Seven-only, duration-based (6/10/20 min)
- Timer ticks while active recorders exist in marked area
- Pauses when all recorders removed/destroyed
- Highlight monitored area boundary for squad

---

## Phase 9: Legacy Cleanup

### Step 9.1 — Remove Old Seven Skills

- Remove or deprecate: `ModularLobotomy/associations/skills/seven/skillgranter.dm`
- Remove or deprecate: `associate.dm`, `veteran.dm`, `director.dm` in the same dir
- These are replaced by the new skill tree system

### Step 9.2 — Update Equipment Box

**File:** `ModularLobotomy/associations/association_beacon.dm`

- Add investigation starter items to the Seven equipment box (camera, intel reports, dossier, maybe a recorder)

---

## Implementation Priority

Recommended order for incremental testing:

1. **Phase 1** (Weapons) — Standalone, can test Rupture interaction immediately
2. **Phase 2** (Skill Defs) — Register empty skill tree, verify TGUI displays branches
3. **Phase 3** (Analyst) — First real skill branch, includes Mark Target action + Dossier Complete powerful attack
4. **Phase 5** (Operative) — Complements Analyst (both use Rupture heavily)
5. **Phase 4** (Coordinator) — Team support, needs allies to test properly
6. **Phase 6** (Shared infra) — Build as needed during Phase 3-5
7. **Phase 7** (Investigation Toolkit) — Large, can be done in parallel or deferred
8. **Phase 8** (Contracts) — Depends on investigation toolkit
9. **Phase 9** (Cleanup) — Last, after everything works

---

## Status Effect Dependencies

All these exist in `code/datums/status_effects/debuffs.dm` and `buffs.dm`:

| Effect | Apply Proc | Used By |
|---|---|---|
| Rupture | `apply_lc_rupture(stacks)` | All branches |
| Fragile | `apply_lc_fragile(stacks)` | Analyst, Operative |
| Feeble | `apply_lc_feeble(stacks)` | Coordinator |
| Defense Level Down | `apply_lc_defense_level_down(stacks)` | Analyst, Coordinator |
| Defense Level Up | `apply_lc_defense_level_up(stacks)` | Coordinator (strips) |
| Offense Level Down | `apply_lc_offense_level_down(stacks)` | Analyst, Coordinator |
| Offense Level Up | `apply_lc_offense_level_up(stacks)` | Analyst, Coordinator |
| Strength | `apply_lc_strength(stacks)` | Coordinator (grants to allies) |

## Reference Files

| Pattern | Reference File |
|---|---|
| Skill component | `ModularLobotomy/associations/skills/association_skill.dm` |
| Skill definitions | `ModularLobotomy/associations/skills/_test_skills.dm` |
| Powerful attack (tiantui) | `ModularLobotomy/ego_weapons/melee/city/thumb.dm` |
| Pointed spell (mark target) | `thin_line.dm` / InterceptClickOn pattern |
| Zoro slash overlay | `puss_in_boots.dm` Execute() |
| Spy bug/glasses | `code/game/objects/items/devices/spyglasses.dm` |
| Camera system | `code/game/objects/items/devices/camera/` |
| Tape recorder / Hear() | `code/game/objects/items/devices/taperecorder.dm` |
