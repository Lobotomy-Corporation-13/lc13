# Path of Destruction — Step-by-Step Implementation Plan

This plan covers implementing the **entire path framework** and the **first path (Destruction)** from scratch. Each step builds on the previous one. Steps marked with ✅ are already complete.

---

## Phase 1: Core Framework (No path-specific code yet)

### Step 1: `_path_defines.dm`
**What:** All `#define` constants, signal strings, and enums.
**Why first:** Every other file depends on these defines.
**Contents:**
- Resource defaults: `PATH_MAX_ENERGY_DEFAULT`, `PATH_MAX_AP_DEFAULT`
- Node types: `PATH_NODE_STAT`, `PATH_NODE_ABILITY`, `PATH_NODE_PASSIVE`
- Ability targets: `PATH_ABILITY_BASIC`, `PATH_ABILITY_BURST`, `PATH_ABILITY_ULTIMATE`
- Element types: `PATH_ELEMENT_PHYSICAL`, `PATH_ELEMENT_FIRE`, etc.
- Speed/turn: `PATH_BASE_SPEED`, `PATH_TURN_BASE`, `PATH_TURN_READY/ATTACKED/SKILLED`
- DoT types: `PATH_DOT_BLEED`, `PATH_DOT_BURN`, `PATH_DOT_SHOCK`, `PATH_DOT_WIND_SHEAR`
- RES defaults: `PATH_RES_DEFAULT`, `PATH_RES_WEAK`, `PATH_RES_BOSS`, `PATH_RES_MIN`, `PATH_RES_MAX`
- Custom signals: `COMSIG_MOB_PATH_ASSIGNED`, `COMSIG_MOB_PATH_REMOVED`, `COMSIG_PATH_ENERGY_CHANGED`, `COMSIG_PATH_AP_CHANGED`
**Design doc:** `_path_defines.md`
**Test:** Compiles with no errors when included in DME.

---

### Step 2: `_path_node.dm`
**What:** `/datum/path_node` — individual skill tree nodes.
**Depends on:** Step 1 (node type defines)
**Contents:**
- Variables: `id`, `name`, `desc`, `icon_state`, `prerequisites`, `ahn_cost`, `node_type`, `required_ascension`, `required_level`, `stat_bonuses`, `stat_percent`, `ability_target`, `level_increase`, `tree_x`, `tree_y`, `connections`
- `New(id, name, desc)` convenience constructor
- `GetNodeData(unlocked_nodes)` — returns assoc list for TGUI
- `CanUnlock(unlocked_nodes, ascension_phase, path_level)` — checks prereqs + gates
**Design doc:** `_path_node.md`
**Test:** Can instantiate nodes with various types and check CanUnlock logic.

---

### Step 3: `_path_datum.dm` — Core Path Framework
**What:** `/datum/path` base datum + `/datum/path_ability` hierarchy. The heart of the system.
**Depends on:** Steps 1-2
**This is the largest and most critical file.** Split into sub-steps:

#### Step 3a: Base `/datum/path` variables and resource procs
- All variables from design doc (owner, energy, AP, path_stats, turn system vars, weapon ref, action refs, nodes, unlocked_nodes)
- `New()` → calls `InitNodes()`
- `InitNodes()` — virtual, subtypes override
- `GainEnergy(amount)`, `SpendEnergy(amount)` — clamped, signal, button update
- `GainActionPoint()`, `SpendActionPoint()` — clamped, signal, button update
- `GetStat(stat_name)` — base stat + node bonuses (handle `stat_percent`)
- `UnlockNode(node_id)` — check CanUnlock + ahn cost via bank_account, apply effect

#### Step 3b: Turn system procs
- `GetTurnDuration()` — `PATH_TURN_BASE * PATH_BASE_SPEED / max(GetStat("SPD"), 1)`
- `StartTurnCycle()` — called from AssignTo, begins recurring timer
- `OnTurnReset()` — tick DoTs, reset `turn_state = PATH_TURN_READY`, queue next timer
- `RecalcSwingsPerTurn()` — `turn_duration / (CLICK_CD_MELEE * weapon.attack_speed)`

#### Step 3c: Lifecycle procs
- `AssignTo(mob/living/carbon/human/user)` — instantiate abilities, create weapon, grant actions (ultimate + screen + designate_ally), start turn cycle, send signal
- `Remove()` — unapply passive, remove actions, qdel weapon, clear allies, send signal, delete abilities, null owner
- `OnWeaponHit(mob/living/target, mob/living/user)` — deal per-swing damage (total scaling / swings_per_turn), gate AP/energy by turn_state

#### Step 3d: Damage procs
- `deal_path_damage(mob/living/target, amount)` — applies DEF multiplier, RES multiplier (element_type + res_pen), avg_coeff, calls `adjustHealth()` or `deal_damage()`
- Crit check: `prob(GetStat("CRIT Rate"))` → multiply by `(1 + GetStat("CRIT DMG") / 100)`

#### Step 3e: Base `/datum/path_ability` hierarchy
- `/datum/path_ability` — base with name, desc, icon_state, parent_path, level, max_level
- `/datum/path_ability/basic` — `var/energy_gain = 20`, `proc/OnHit(target, user, swings_per_turn)`
- `/datum/path_ability/burst` — `var/energy_gain = 30`, `var/ap_cost = 1`, `proc/Activate(user)`
- `/datum/path_ability/ultimate` — `proc/Activate(user)` (base calls SpendEnergy)
- `/datum/path_ability/passive` — `proc/Apply(user)`, `proc/Unapply(user)`

#### Step 3f: SPD debuff global procs
- `apply_path_spd_change(target, spd_percent, duration)` — contextual: path holder → turn slow, simple mob → movement slow, carbon → movement slow
- `has_path_spd_debuff(target)` — checks status effect

**Design doc:** `_path_datum.md`
**Test:** Can create a `/datum/path`, call AssignTo on a human mob, verify turn cycle starts, weapon is created, actions are granted.

---

### Step 4: Verify `_path_weapon.dm` ✅
**What:** Already written. Verify it compiles and integrates with the new `/datum/path` from Step 3.
**Check:**
- `attack()` calls `linked_path.OnWeaponHit()` correctly
- `attack_self()` checks `linked_path.turn_state`
- `examine()` references `linked_path.GetStat()`, `linked_path.GetTurnDuration()`
- May need minor adjustments for proc signature changes

---

### Step 5: Verify `_path_allies.dm` ✅
**What:** Already written. Verify it compiles standalone.
**Check:**
- `GLOB.path_ally_lists` works
- `GetPathAlliesInRange()` returns correct list
- Action button trigger logic works

---

### Step 6: `_path_actions.dm`
**What:** Ultimate and Screen action buttons.
**Depends on:** Step 3 (needs `/datum/path`)
**Contents:**
- `/datum/action/path_ultimate` — Trigger checks energy >= max_energy, calls `ultimate_action.Activate()`, linked_path ref
- `/datum/action/path_screen` — Trigger calls `linked_path.ui_interact()`, linked_path ref
- Both: `UpdateButtonIcon()` for state visualization
**Design doc:** `_path_actions.md`
**Test:** Grant actions to a mob, verify clicking them checks energy/calls procs.

---

### Step 7: `_path_component.dm`
**What:** `/datum/component/path_holder` + mob helper procs.
**Depends on:** Step 3
**Contents:**
- Component with `active_path` var, Initialize calls AssignTo, Destroy calls Remove
- Helper procs on `/mob/living/carbon/human`: `GetPath()`, `HasPath()`, `GrantPath(path_type)`, `RemovePath()`
**Design doc:** `_path_component.md`
**Test:** Call `human.GrantPath(/datum/path)`, verify path attaches. Call `RemovePath()`, verify cleanup.

---

### Step 8: `_path_ui.dm`
**What:** DM-side TGUI procs on `/datum/path`.
**Depends on:** Step 3
**Contents:**
- `ui_state()` → `GLOB.always_state`
- `ui_interact()` → `SStgui.try_update_ui()` pattern, opens "PathScreen"
- `ui_data()` → all data (path identity, resources, stats, abilities, nodes with ahn_cost/gates, player_ahn, LC13 attributes)
- `ui_act()` → handles "unlock_node" action
**Design doc:** `_path_ui.md`
**Test:** Open the UI via action button, verify data structure appears in TGUI debug.

---

### Step 9: `PathScreen.js`
**What:** React TGUI interface with Details + Traces tabs.
**Depends on:** Step 8
**Contents:**
- Tab 1 (Details): path name/desc, abilities list with levels, stats panel (including SPD), energy bar, AP pips, turn state, LC13 attributes
- Tab 2 (Traces): visual node graph with branching diamond layout, connection lines between nodes, node styling (unlocked/available/locked), selected node detail panel with ahn cost and unlock button
- Max 80 chars per line (CLAUDE.md lint rule)
**Design doc:** `PathScreen.md`
**Test:** Open UI, switch tabs, click nodes, verify unlock_node action fires.

---

### Step 10: DME Includes
**What:** Add all path files to `lobotomy-corp13.dme`.
**Order matters — `_path_defines.dm` must be first:**
```
#include "ModularLobotomy\enders_gimmicks\paths\_path_defines.dm"
#include "ModularLobotomy\enders_gimmicks\paths\_path_node.dm"
#include "ModularLobotomy\enders_gimmicks\paths\_path_datum.dm"
#include "ModularLobotomy\enders_gimmicks\paths\_path_weapon.dm"
#include "ModularLobotomy\enders_gimmicks\paths\_path_allies.dm"
#include "ModularLobotomy\enders_gimmicks\paths\_path_dots.dm"
#include "ModularLobotomy\enders_gimmicks\paths\_path_actions.dm"
#include "ModularLobotomy\enders_gimmicks\paths\_path_component.dm"
#include "ModularLobotomy\enders_gimmicks\paths\_path_ui.dm"
```
**Test:** Full compile with no errors.

---

## Phase 2: Destruction Path (First Path Subtype)

### Step 11: `paths_destruction.dm` — Path Datum Subtype
**What:** `/datum/path/destruction` with stats, ability types, and weapon type.
**File:** `ModularLobotomy/enders_gimmicks/paths/paths_destruction.dm`
**Contents:**
```dm
/datum/path/destruction
    name = "Destruction"
    desc = "Deals outstanding amounts of damage with great survivability."
    icon_state = "destruction"
    element_type = PATH_ELEMENT_PHYSICAL
    max_energy = 120
    path_weapon_type = /obj/item/ego_weapon/path_weapon/destruction
    basic_attack_type = /datum/path_ability/basic/destruction
    burst_action_type = /datum/path_ability/burst/destruction
    ultimate_type = /datum/path_ability/ultimate/destruction
    passive_type = /datum/path_ability/passive/destruction
```
- Stat table (phase/level → HP/ATK/DEF/SPD interpolation)
- `RecalculateStats()` using the stat table
**Test:** Can instantiate `/datum/path/destruction`, stats are correct at level 1.

---

### Step 12: Destruction Weapon Subtype
**What:** `/obj/item/ego_weapon/path_weapon/destruction` — default weapon appearance.
**Contents:**
```dm
/obj/item/ego_weapon/path_weapon/destruction
    name = "Destruction Blade"
    desc = "A weapon crackling with destructive energy."
    icon_state = "existingstate"  // verify exists in codebase
    hitsound = 'sound/weapons/bladeslice.ogg'
    swingstyle = WEAPONSWING_LARGESWEEP
```
**Test:** Weapon spawns with correct appearance and sound.

---

### Step 13: Destruction Basic Attack
**What:** `/datum/path_ability/basic/destruction` — Farewell Hit.
**Contents:**
- `energy_gain = 20`, `max_level = 7`
- `var/list/atk_scaling = list(50, 60, 70, 80, 90, 100, 110)`
- `OnHit(target, user, swings_per_turn)` — calculates `ATK * scaling[level] / 100 / swings_per_turn`, calls `parent_path.deal_path_damage(target, damage)`
**Test:** Hit a mob, verify damage matches scaling table. Verify DPS is same regardless of weapon attack_speed.

---

### Step 14: Destruction Burst/Skill
**What:** `/datum/path_ability/burst/destruction` — RIP Home Run.
**Contents:**
- `energy_gain = 30`, `ap_cost = 1`, `max_level = 12`
- `var/list/atk_scaling = list(62.5, 68.75, 75, ...)` (12 entries)
- `Activate(user)` — deals damage to all mobs within 1 tile of user (excluding user), uses `parent_path.deal_path_damage()`
**Test:** Press Z key, verify AP spent, energy gained, AoE damage dealt to adjacent mobs.

---

### Step 15: Destruction Ultimate
**What:** `/datum/path_ability/ultimate/destruction` — Stardust Ace.
**Contents:**
- `max_level = 12`
- Two modes: `var/active_mode = "farewell"` — switchable (could use a verb or the Skill to toggle)
- `var/list/blowout_fh = list(300, 315, ...)` (12 entries)
- `var/list/blowout_rip_main = list(180, 189, ...)` (12 entries)
- `var/list/blowout_rip_adj = list(108, 113.4, ...)` (12 entries)
- `Activate(user)` — spends all energy, deals damage based on mode:
  - Farewell: `ATK * scaling / 100` to target in front
  - RIP: main damage to target in front + adj damage within 1 tile of target
- Sets `enhanced` flag so next Basic/Skill uses Ult scaling (empowered attack)
**Test:** At full energy, click Ultimate button. Verify energy resets, damage is correct for selected mode.

---

### Step 16: Destruction Passive
**What:** `/datum/path_ability/passive/destruction` — Perfect Pickoff.
**Contents:**
- `max_level = 12`
- `var/list/atk_buff_scaling = list(10, 11, 12, ...)` (12 entries)
- `var/max_stacks = 2`, `var/current_stacks = 0`
- `Apply(user)` — register signal for kill detection (e.g. `COMSIG_MOB_KILLED` or check target death after attack)
- `Unapply(user)` — unregister, reset stacks
- On kill: if `current_stacks < max_stacks`, increment and apply ATK% buff for 30 seconds
**Test:** Kill a mob, verify ATK buff applies. Kill another, verify second stack. Verify cap at 2.

---

### Step 17: Destruction Trace Nodes
**What:** `InitNodes()` on `/datum/path/destruction` — the 13 trace nodes.
**Contents:**
- 10 stat boost nodes (ATK%, HP%, DEF% at various gates)
- 3 bonus ability nodes:
  - A2: Ready for Battle (15 energy on combat start)
  - A4: Tenacity (Passive stacks also grant +10% DEF)
  - A6: Fighting Will (Skill/Ult RIP deals +25% to primary target)
- All with correct `tree_x`, `tree_y`, `connections`, `ahn_cost`, `required_ascension/level`
- Branching diamond layout matching the HSR visual
**Test:** Open Traces tab in UI, verify all 13 nodes display in correct positions with connection lines. Unlock a node with ahn, verify stat boost applies.

---

### Step 18: Destruction Bonus Ability Implementation
**What:** The actual code behind the 3 bonus abilities.
**Contents:**
- **Ready for Battle:** In `AssignTo()` or on a combat-start signal, check if node is unlocked → `GainEnergy(15)`
- **Tenacity:** Modify Perfect Pickoff's stack application to also apply DEF% buff when this node is unlocked
- **Fighting Will:** In Skill/Ult RIP mode, check if node unlocked → multiply primary target damage by 1.25
**Test:** Unlock each bonus ability node, verify the effect triggers correctly.

---

## Phase 3: Integration Testing

### Step 19: Admin Verb for Testing
**What:** A simple admin verb to grant a path for testing.
**Contents:**
```dm
/client/proc/grant_path_destruction()
    set category = "Debug"
    var/mob/living/carbon/human/H = mob
    if(!ishuman(H))
        return
    H.GrantPath(/datum/path/destruction)
```
**Test:** Use verb, verify: weapon appears in hand, action buttons appear, UI opens, turn cycle runs, attacks deal path damage, skill works, ultimate works, traces display correctly.

---

### Step 20: End-to-End Validation
**Checklist:**
- [ ] Path assigns correctly via `GrantPath()`
- [ ] Weapon appears, TRAIT_NODROP prevents dropping
- [ ] Basic ATK deals correct damage (scaling / swings_per_turn)
- [ ] Turn system cycles at correct rate (5s at SPD 100)
- [ ] First hit per turn grants 1 AP + energy; subsequent hits deal damage only
- [ ] Skill (Z key) costs AP + turn, deals AoE damage, blocked if already attacked
- [ ] Cannot attack for AP/energy after using Skill (turn locked)
- [ ] Ultimate button checks energy, deals correct damage, resets energy
- [ ] Passive: kill grants ATK buff, stacks to 2, expires after 30s
- [ ] Traces UI displays branching layout with connection lines
- [ ] Clicking a node shows ahn cost, ascension/level gate
- [ ] Unlocking a node deducts ahn, applies stat bonus
- [ ] Bonus abilities activate when their node is unlocked
- [ ] Weapon disguise system works (copy appearance from EGO weapon)
- [ ] Ally designation works
- [ ] Path removal cleans up everything (weapon, actions, allies, turn timer)
- [ ] Examine text shows all path info correctly

---

## File Summary

| Phase | Step | File | Status |
|-------|------|------|--------|
| 1 | 1 | `_path_defines.dm` | TODO |
| 1 | 2 | `_path_node.dm` | TODO |
| 1 | 3 | `_path_datum.dm` | TODO (largest) |
| 1 | 4 | `_path_weapon.dm` | ✅ Written |
| 1 | 5 | `_path_allies.dm` | ✅ Written |
| 1 | 6 | `_path_actions.dm` | TODO |
| 1 | 7 | `_path_component.dm` | TODO |
| 1 | 8 | `_path_ui.dm` | TODO |
| 1 | 9 | `PathScreen.js` | TODO |
| 1 | 10 | DME includes | TODO |
| 2 | 11 | `paths_destruction.dm` | TODO |
| 2 | 12 | Weapon subtype | In paths_destruction.dm |
| 2 | 13 | Basic ATK | In paths_destruction.dm |
| 2 | 14 | Burst/Skill | In paths_destruction.dm |
| 2 | 15 | Ultimate | In paths_destruction.dm |
| 2 | 16 | Passive | In paths_destruction.dm |
| 2 | 17 | Trace nodes | In paths_destruction.dm |
| 2 | 18 | Bonus abilities | In paths_destruction.dm |
| 3 | 19 | Admin verb | In paths_destruction.dm |
| 3 | 20 | E2E testing | Manual |
