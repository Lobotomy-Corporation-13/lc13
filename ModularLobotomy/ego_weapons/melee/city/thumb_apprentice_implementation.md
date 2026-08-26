# Thumb Apprentice — Implementation Plan

Each step produces working, testable code. Later steps build on earlier ones but each step compiles and can be verified independently.

---

## Step 1: Status Effects — "The Duel Escalates" + "Severed Tendon" [CODED]
**Files to create/modify:**
- `code/datums/status_effects/debuffs.dm` — add both new stacking status effects

**What to implement:**
- `/datum/status_effect/stacking/duel_escalates` — max 20 stacks, 10s tick, tracks which mob inflicted it, expires if no new stacks added
- `/mob/living/proc/apply_duel_escalates(stacks, mob/living/duelist)` — mob helper proc
- `/datum/status_effect/stacking/severed_tendon` — max 3 stacks, 10s decay (lose 1/tick), reduces target's melee force by 5 per stack
- `/mob/living/proc/apply_severed_tendon(stacks)` — mob helper proc

**How to test:**
- Spawn the Palermitan Debug Kit from object spawner (search "palermitan")
- Use "Grant Base Passives" then attack a mob — verify Duel Escalates stacks appear on target
- Verify stacks decay after 10s of not hitting
- (Severed Tendon tested in Step 9 when skill is implemented)

---

## Step 2: Base Passives — Duello + Palermitan Style Component [CODED]
**Files to create:**
- `ModularLobotomy/thumb_spider/palermitan_base.dm` — component that grants base passives

**What to implement:**
- `/datum/component/palermitan_apprentice` — attaches to the apprentice mob
- Registers `COMSIG_MOB_ITEM_ATTACK` signal
- **Duello:** On Hit → inflict 1 Duel Escalates on target. If target has Duel Escalates, heal 3 sanity per stack (max 15)
- **Palermitan Style:** On Hit → check target's Duel Escalates stacks:
  - Per stack: deal +5% bonus damage, take -5% damage from target
  - At 5+ stacks: +5 force bonus
  - At 10+ stacks: +10 force bonus
- Vars: `var/mob/living/nursefather_ref` (set on recruitment), `var/correction_count`, `var/correction_eligible`, `var/correction_deadline`, `var/potential_correction_attrs`

**How to test:**
- Use debug kit → "Grant Base Passives"
- Attack a mob repeatedly, verify Duel Escalates stacks appear on target
- Verify sanity healing when hitting a target with stacks
- Verify damage bonus scales with stacks

---

## Step 3: Apprentice Weapons — Dual-Wield by Tier + Duel Escalates on Follow-Up [CODED]
**Files to modify:**
- `ModularLobotomy/ego_weapons/melee/city/thumb_spider.dm` — update `set_tier()` on both apprentice weapons

**What to implement:**
- Add to both katana and greatsword:
  - `var/swing_threshold = 0` — 0 = disabled, 1 = every hit, 2 = every 2nd hit
  - `var/swing_count = 0`
  - `var/busy_dual_strike = FALSE`
- Update `set_tier()` to set `swing_threshold`: tier 1 = 0, tier 2-3 = 2, tier 4 = 1
- Add `attack()` override on both weapons for dual-wield follow-up logic (same pattern as thumbfather)
- Follow-up inflicts 1 Duel Escalates on target via `apply_duel_escalates()` from Step 1
- Helper proc to find partner apprentice weapon in other hand

**How to test:**
- Use debug kit → "Spawn Gear Set" then "Set Weapon Tier → 2"
- Equip both weapons, attack a mob — verify every 2nd hit triggers partner follow-up at 25% damage
- Verify follow-up inflicts Duel Escalates on target
- Use debug kit → "Set Weapon Tier → 4", verify every hit triggers follow-up
- Use debug kit → "Set Weapon Tier → 1", verify no follow-up

---

## Step 4: Palermitan EXP + Skill Point Component [CODED]
**Files to create:**
- `ModularLobotomy/thumb_spider/palermitan_exp.dm` — EXP tracking component

**What to implement:**
- `/datum/component/palermitan_exp` — tracks EXP, skill points, role duel counts
- Vars: `exp`, `skill_points`, `skill_points_spent`, `role_duel_counts` (assoc list keyed by role name)
- `var/static/list/exp_thresholds` — the threshold list from the design doc
- Procs: `modify_exp(amount)`, `check_skill_points()`, `spend_skill_point(cost)`, `get_next_threshold()`, `increment_role_duel(role_name)`
- Attach to apprentice mob (added in Step 2's component or separately)

**How to test:**
- Use debug kit → "Grant EXP Component"
- Use debug kit → "Add EXP → 50", verify skill points granted (should get SP 1 at 20, SP 2 at 50)
- Use debug kit → "Add EXP → 200" repeatedly, verify thresholds work correctly
- Check that skill_points and skill_points_spent track correctly in the examine text or debug output

---

## Step 5: Duel System — Core Datum + Arena + Win/Loss [CODED]
**Files to create:**
- `ModularLobotomy/thumb_spider/palermitan_duel.dm` — duel datum, wall effect, challenge action

**What to implement:**
- `/datum/thumb_duel` — manages a single duel instance
  - `start_duel()` — calculate midpoint, spawn walls, register `COMSIG_MOB_STATCHANGE` signals
  - `spawn_arena_walls()` — non-dense temp_visuals at `get_dist() == radius` with `Crossed()` detection
  - `arena_check_loop()` — refresh walls every 5 seconds
  - `on_barrier_crossed()` — player who steps on wall loses
  - `end_duel(winner, loser)` — cleanup, heal winner 50% / loser 25%
- `/obj/effect/temp_visual/duel_wall` — non-dense, gold-colored, `Crossed()` triggers loss
- `/datum/action/innate/thumb_duel_challenge` — action button to challenge nearby players
- No rewards yet — just the duel mechanics

**How to test:**
- Use debug kit → "Force Start Duel vs Dummy" — spawns a dummy and immediately starts a duel
- Verify gold arena walls spawn at the midpoint between you and the dummy
- Walk into the wall tiles — verify you auto-lose and the duel ends
- Start another duel vs dummy. Kill the dummy until it enters crit — verify you win
- Verify you are healed 50% of missing HP after winning
- Verify walls disappear and clean up after duel ends
- Use debug kit → "Spawn Duel Dummy", then use the Duel Challenge action button manually — click the dummy, verify the duel starts (dummy auto-accepts)

---

## Step 6: Duel Rewards — Attributes + EXP + Role Tracking [CODED]
**Files to modify:**
- `ModularLobotomy/thumb_spider/palermitan_duel.dm` — add `grant_duel_rewards()` implementation

**What to implement:**
- `grant_duel_rewards(winner, loser)`:
  - Determine which participant is the apprentice
  - Calculate attribute gain: `base_gain(6) * ratio * win_modifier`
  - Apply to all 4 attributes, cap at 200
  - Calculate EXP gain: `base_exp(20) * ratio * win_modifier`
  - Call `modify_exp()` on the palermitan_exp component
  - Increment role duel count based on opponent's `mind.assigned_role`
  - Check gear tier-up: `(attrs / 2) >= requirement` → call `set_tier()` on armor + weapons
  - If opponent is association member: grant them association EXP
- Store last duel result on the palermitan component for correction eligibility

**How to test:**
- Use debug kit → "Full Setup" (grants everything + sets 40 attrs)
- Use debug kit → "Force Start Duel vs Dummy" (dummy has 100 attrs by default)
- Win the duel — verify attributes increase (should gain ~12 per attr with ratio 2.0 since you're 40 vs 100)
- Check EXP gained (should be ~40 EXP)
- Use debug kit → "Simulate Duel Loss" — verify gain is 75% less (~3 per attr, ~10 EXP)
- Use debug kit → "Simulate Duel Win" repeatedly to rapidly test progression
- Keep simulating until attributes hit 120 — verify gear auto-tiers to tier 2 (examine armor for changed values, check weapon force)
- Continue to 160 → tier 3, 200 → tier 4
- Verify dual-wield activates at tier 2 (equip both weapons, attack dummy)

---

## Step 7: Nursefather Interactions — Drinks, Glass, Correction [CODED]
**Files to modify:**
- `ModularLobotomy/thumb_spider/palermitan_base.dm` — add signal handlers for interactions

**What to implement:**
- **Drink sharing:** Register `COMSIG_ITEM_OFFER_TAKEN` — check for alcohol drink + nursefather, grant 5 EXP (2 min cooldown)
- **Glass bottle impact:** Register `COMSIG_ATOM_HITBY` — check for glass drink thrown by nursefather, grant 3 EXP (30 sec cooldown)
- **Post-duel correction:** Register `COMSIG_PARENT_ATTACKBY` — check for nursefather unarmed punch within 1.5 min of duel loss
  - Escalating animation proc with cutscene_duel component for tier 3+
  - Deals damage (5% → 50% of current HP based on `correction_count / 2`)
  - Grants 0.25x of lost duel's potential attributes + 5 EXP
  - Increments correction_count

**How to test:**
- **Drinks:** Use debug kit → "Spawn Nursefather Drink" — simulates the full give/take flow and grants 5 EXP. Verify EXP increases. Use it again immediately — verify cooldown message. Wait 2 minutes (or use debug kit to reset cooldown if added), try again — verify EXP granted.
- **Glass bottle:** Use debug kit → "Spawn Glass Bottle + Throw at Self" — simulates being hit by a glass bottle from the nursefather. Verify 3 EXP gained. Use again — verify 30 second cooldown.
- **Correction:** Use debug kit → "Simulate Duel Loss + Correction" — simulates losing a duel, spawns a temporary nursefather dummy mob adjacent to you, and runs the full correction animation with the dummy acting as the nursefather (punching, pixel shifting, etc.). The dummy is deleted after the animation completes. Verify HP damage dealt, attributes + EXP granted, and chat messages.
- Use "Simulate Duel Loss + Correction" repeatedly — verify animation escalates every 2 uses (tier 1 at corrections 1-2, tier 2 at 3-4, etc.)
- After 8+ uses, verify the full tier 5 cutscene plays with the dummy nursefather performing the multi-hit combo, pixel shifting on the apprentice, camera shake, and knockdown
- Verify the dummy nursefather is cleaned up (deleted) after each correction animation

---

## Step 8: Skill Tree — Definitions + TGUI [CODED]
**Status:** Previously coded for 5-tier single-school. Needs full rewrite for 4-school system.

**Files to modify:**
- `ModularLobotomy/thumb_spider/palermitan_tree.dm` — rewrite TGUI datum + skill definitions for 4 schools
- `tgui/packages/tgui/interfaces/PalermitanSkillTree.js` — rewrite React UI with school tabs

**What to implement:**
- `/datum/palermitan_skill_tree` — TGUI datum (mirrors Ring's `ring_skill_tree` exactly)
  - `GLOB.palermitan_skill_definitions` — 4 schools, 3 tiers each, 2 choices per tier (24 skills total)
  - `ui_data()` — serves school data with tabs, tier data with availability/lock/selected flags
  - `ui_act("select_skill")` — validates school investment limit (max 2), tier prerequisites, point cost
  - School investment tracking via `palermitan_exp` component (add `schools_invested`, `max_schools` vars)
- React UI based on `RingSkillTree.js` with 4 school tabs:
  - Terremoto (amber `#8b6914`), Incendio (red `#c44536`), Eleganza (blue `#5b7c99`), Fondamenti (grey `#8b8b8b`)
- `/datum/action/innate/palermitan_tree` — opens the tree UI (already exists, keep)

**What to update on palermitan_exp.dm:**
- Add `var/list/schools_invested = list()` — tracks which schools player has invested in
- Add `var/max_schools = 2` — max schools allowed
- Add `proc/can_invest_in_school(school_id)` — checks if max not reached or already invested
- Add `proc/invest_in_school(school_id)` — registers investment

**How to test:**
- Use debug kit → "Grant Skill Tree Action" + "Grant EXP Component"
- Use debug kit → "Add EXP → 500" (grants all 10 skill points for testing)
- Click "Palermitan Skill Tree" action — verify TGUI opens with 4 school tabs
- Select Terremoto tab — verify 3 tiers display with a/b choices
- Select Terremoto 1a — verify it highlights green, 1b becomes excluded
- Select Terremoto 2a — verify it unlocks (previous tier completed)
- Switch to Incendio tab — select 1a — verify it works (2nd school)
- Try to select Eleganza 1a — verify it's blocked ("max 2 schools")
- Use debug kit → "Reset All" and reopen — verify tree is blank

---

## Step 9: Skill Components — Terremoto + Incendio Schools [CODED]
**Status:** Previously coded for old tier 1-3 skills. Needs full rewrite for new school skills.

**Files to modify:**
- `ModularLobotomy/thumb_spider/palermitan_skills.dm` — rewrite all skill components

**What to implement:**
- `/datum/component/palermitan_skill` — base component (keep existing pattern)
- Add `var/tremor_burst_threshold = INFINITY` tracking on the base component or apprentice component
  - Terremoto T2 skills modify this to 15 or 25

**Terremoto school (6 skills):**
- **T1a Il Cacciatore:** On Hit: 2 Tremor (INFINITY). Vs DE: +1 OLU
- **T1b Destabilizing Strikes:** On Hit: 1/2/3 Tremor scaling with DE stacks
- **T2a Palermitan Rapier:** Unlocks burst at 15. On burst: +5 OLU +2 Poise
- **T2b Aftershock:** Unlocks burst at 25. On Hit vs 10+ Tremor: 2 OLD. Vs 20+: 3 OLD
- **T3a Sezionatura:** Activated (60s CD). 4 Tremor + 4 Overheat + force burst + RED = (DE*5). Consume 50% DE
- **T3b Tectonic Collapse:** On burst: 3 Fragile + 3 DLD + 2 Overheat

**Incendio school (6 skills):**
- **T1a Colpi Sottani:** On Hit: 2 Overheat. Vs DE: 3 Overheat instead
- **T1b Scorching Pursuit:** On Hit: 1 Overheat (2 at 5+ DE). Vs Overheat target: +1 OLU
- **T2a Firestorm:** On Hit vs 10+ Overheat: +3 OLU +1 Poise +1 Fragile
- **T2b Smoldering Wounds:** On Hit: 1 DLD per 5 Overheat on target (max 3)
- **T3a La Spada:** On Hit vs 10+ DE (30s CD): +5 OLU +3 Damage Up, consume 5 DE, inflict 3 Tremor
- **T3b Conflagration:** On Hit vs 15+ Overheat: bonus RED = Overheat stacks, reduce by 5, inflict 2 Tremor

**How to test:**
- Use debug kit → full setup + "Add EXP → 500"
- Open tree, select Terremoto 1a → attack mob, verify 2 Tremor applied (no burst)
- Select Terremoto 2a → attack mob, verify tremor now bursts at 15 stacks. Verify +5 OLU +2 Poise on burst
- Reset, select Terremoto 2b → verify burst at 25 stacks. Verify OLD on 10+/20+ Tremor targets
- Select Terremoto 3a → verify Sezionatura action button appears. Use it, verify force burst + effects
- Reset, test Incendio school similarly
- Test cross-school: Terremoto T3b (Tectonic Collapse) procs Overheat on burst

---

## Step 10: Skill Components — Eleganza + Fondamenti Schools [CODED]
**Files to modify:**
- `ModularLobotomy/thumb_spider/palermitan_skills.dm` — add remaining school skills

**What to implement:**

**Eleganza school (6 skills):**
- **T1a Relentless Pursuit:** Under 5 DE: +1 Concentration (10s CD). 5+ DE: +3 Poise instead
- **T1b Focused Mind:** Under 5 DE: +1 Poise +1 Concentration (10s CD). 5+ DE: +3 Poise instead
- **T2a Duello Feroce:** On Hit vs DE: +1 Poise per 3 stacks (max 3) + heal 2 HP/stack (max 10). Halving crit: +1 Concentration
- **T2b Severed Tendon:** On crit: 3 OLD + 1 Fragile. Halving crit: +1 Poise back
- **T3a Valencina's Legacy:** On crit: 3 Tremor + 3 Overheat + DE spread 2 tiles. On crit (15s CD): +1 Concentration
- **T3b Famiglia's Honor:** DE max → 30. At 15+ DE: +2 Poise. Halving crit at 15+ DE: +1 Concentration. Crit at 20+ DE: 3 Fragile + 3 DLD

**Fondamenti school (6 skills):**
- **T1a Iron Constitution:** On taking damage: +2 DLU
- **T1b Aggressive Footwork:** On Hit: +1 OLU. On taking melee damage: +1 OLU
- **T2a Predator's Instinct:** On Hit vs <50% HP: 2 Fragile +1 Poise. Vs <25%: +2 OLU
- **T2b Enduring Spirit:** On Hit vs DE target: heal 1 HP/stack (max 5). On taking damage near DE target: +1 DLU
- **T3a Coup de Grâce:** On Hit vs <20% HP with 5+ DE: bonus RED = (DE*3), consume 50% DE stacks
- **T3b Unbreakable Will:** On entering soft crit (60s CD): +5 DLU +3 Protection +heal 10% max HP

**How to test:**
- Use debug kit → full setup + "Add EXP → 500"
- **Eleganza T1a:** Select, attack mob. Under 5 DE: verify Concentration gain (check cooldown). At 5+ DE: verify 3 Poise, no Concentration
- **Eleganza T2a:** Verify Poise gain scales with DE stacks. Trigger a crit that halves Poise: verify +1 Concentration. Trigger a crit where Concentration was consumed: verify NO Concentration gained
- **Eleganza T3a Valencina:** Trigger Poise crit, verify 3 Tremor + 3 Overheat on target. Verify DE spreads to nearby mobs
- **Fondamenti T1a:** Take damage, verify +2 DLU
- **Fondamenti T3a Coup de Grâce:** Attack low HP mob with 5+ DE, verify bonus RED damage and 50% stack consumption
- **Fondamenti T3b Unbreakable Will:** Get hit until soft crit, verify +5 DLU +3 Protection +heal

---

## Step 11: Role-Specific Passives [CODED]
**Files to create:**
- `ModularLobotomy/thumb_spider/palermitan_role_passives.dm` — all role passive components

**What to implement:**
- One component per role, each with 3 tiers tracked by duel count
- Components register `COMSIG_MOB_ITEM_ATTACK` and/or `COMSIG_MOB_APPLY_DAMGE`
- Passives: Butcher, Blade Lineage, Thumb, Kurokumo, Index, Insurgence, Middle, N-Corp, Rat, Carnival, Zwei, Seven, Dieci, Cinq, Shi, Liu, Devyat, Hana
- Each reads its tier from `palermitan_exp.role_duel_counts[role_name]`
- Auto-grant/upgrade after each duel via `grant_duel_rewards()`

**How to test:**
- Use debug kit → full setup + "Grant Duel Action"
- Use debug kit → "Add Role Duel Count → Butcher → 1" — verify "Predator's Instinct" tier 1 is active. Attack a mob below 50% HP, verify 1 Fragile inflicted.
- Use debug kit → "Add Role Duel Count → Butcher → 3" — verify tier 2 upgrade (2 Fragile).
- Use debug kit → "Add Role Duel Count → Butcher → 5" — verify tier 3 (2 Fragile + 1 Damage Up).
- Test at least one passive from each category:
  - A syndicate passive (e.g. Kurokumo — attack a mob, verify Poise gain)
  - An association passive (e.g. Zwei — take damage, verify DLU gain)
  - A roaming passive (e.g. Liu — attack a mob, verify Overheat inflicted)
  - Hana — equip two different weapons, attack with one then the other, verify OLU on weapon switch
- Alternatively: duel an actual player with the right role to test the full flow (duel → role count increments → passive granted)

---

## Step 12: Recruitment Integration + DME [CODED]
**Files to modify:**
- `code/modules/jobs/job_types/trusted_players/thumb_nursefather.dm` — update recruitment to grant all systems
- `lobotomy-corp13.dme` — add all new files

**What to implement:**
- Update `recruit_apprentice()` to:
  - Add `palermitan_apprentice` component (base passives)
  - Add `palermitan_exp` component (EXP tracking)
  - Grant `thumb_duel_challenge` action (duel button)
  - Grant `palermitan_tree` action (skill tree button)
- Add all new `.dm` files to the DME
- Verify full flow: recruit → duel → gain EXP/attrs → open tree → select skills → use skills in combat

**How to test:**
- **Solo test via debug kit:** Use debug kit → "Full Setup" to simulate what recruitment does. Verify all components, actions, and gear are granted. Run through the full gameplay loop:
  1. "Force Start Duel vs Dummy" → win → verify attribute + EXP gain
  2. Open skill tree → verify skill points available, select a skill
  3. Attack a mob → verify selected skill works
  4. "Spawn Nursefather Drink" → verify 5 EXP
  5. "Simulate Duel Loss + Correction" → verify correction animation + attribute gain
  6. "Simulate Duel Win" repeatedly until gear tiers up → verify weapon/armor stats change
- **Multiplayer test (if available):** Join as Ex Thumb Sottocapo, recruit another player with the scroll. Verify they get 40 all attributes, tier 1 gear, both action buttons, and base passives active.

---

## Step 13: Polish + Compile
- Full compile test
- Line length check on any JS files
- Verify no runtime errors during duel/skill/passive usage
- Verify all temp_visuals clean up properly
- Verify signals are properly unregistered on component removal

---

## Debug Tool — Palermitan Debug Kit

**File:** `ModularLobotomy/thumb_spider/palermitan_debug.dm`

A spawnable item (`/obj/item/palermitan_debug_kit`) that opens a TGUI menu on use-in-hand. Can be spawned from the object spawner panel by searching "palermitan debug". Works on whoever is holding it — no recruitment needed.

**Important:** Local testing has only 1 player. The debug kit must handle both sides of interactions (duels, nursefather interactions, etc.) by spawning dummy mobs or simulating the other participant.

**Menu options:**
- **Grant Base Passives** — adds `/datum/component/palermitan_apprentice` to the user
- **Remove Base Passives** — removes the component
- **Grant EXP Component** — adds `/datum/component/palermitan_exp`
- **Add EXP** (input amount) — calls `modify_exp(amount)`
- **Set Attribute Level** (input value) — sets all 4 attributes to the value
- **Set Weapon Tier** (1-4) — finds apprentice weapons in user's hands/inventory and calls `set_tier()`
- **Set Armor Tier** (1-4) — finds apprentice armor on user and calls `set_tier()`
- **Grant Duel Action** — gives the duel challenge action button
- **Grant Skill Tree Action** — gives the skill tree action button
- **Spawn Duel Dummy** — spawns a `/mob/living/simple_animal/hostile` dummy mob nearby with configurable attributes (input value, defaults to 100). The dummy stands still, has HP, can enter crit, and counts as a valid duel target. This lets you test duels solo.
- **Force Start Duel vs Dummy** — spawns a dummy and immediately starts a duel with it (skips challenge/acceptance). The dummy fights back with basic attacks.
- **Simulate Duel Win** — grants rewards as if you won a duel vs a 100-attr opponent (no actual duel needed)
- **Simulate Duel Loss** — grants rewards as if you lost a duel vs a 100-attr opponent
- **Simulate Duel Loss + Correction** — simulates a loss AND immediately performs the nursefather correction (deals damage, grants bonus attrs, escalates correction_count). Tests the full correction flow without needing a second player as nursefather.
- **Set Correction Eligible** — makes you eligible for nursefather correction right now (in case you want to test correction separately)
- **Add Role Duel Count** (pick role from list, input count) — sets duel count for a specific role and grants/upgrades the passive
- **Grant All Skills** — unlocks all tier 1a + 2a + 3a in the first 2 schools (Terremoto + Incendio)
- **Reset All** — removes all components, actions, resets everything
- **Spawn Gear Set** — creates tier 1 apprentice armor + katana + greatsword at your feet
- **Spawn Acceleration Ammo** — creates a stack of 12 acceleration rounds
- **Spawn Nursefather Drink** — creates an alcoholic drink in your hand + simulates the give/take EXP flow (since you can't give() to yourself normally)
- **Spawn Glass Bottle + Throw at Self** — spawns a glass bottle and simulates being hit by it from the nursefather, granting the 3 EXP (since you can't throw at yourself)
- **Full Setup** — one button that does: Grant Base Passives + Grant EXP + Grant Duel Action + Grant Skill Tree + Spawn Gear Set + Set Attribute Level 40

### Duel Dummy Mob
```dm
/mob/living/simple_animal/hostile/palermitan_dummy
    name = "training dummy"
    desc = "A training dummy for duel practice."
    maxHealth = 500
    health = 500
    stat_attack = CONSCIOUS
    faction = list("neutral")
    melee_damage_lower = 10
    melee_damage_upper = 15
    attack_verb_continuous = "strikes"
    attack_verb_simple = "strike"
    /// Fake attributes for reward calculation
    var/fake_attributes = 100
```
The dummy counts as a valid duel target. When the duel system calculates attribute rewards, it reads `fake_attributes` instead of real attribute datums (since simple_animals don't have them). The dummy can enter crit (triggering duel win) and can be killed normally.

### Nursefather Dummy Mob
```dm
/mob/living/simple_animal/hostile/palermitan_nursefather_dummy
    name = "Ex Thumb Sottocapo"
    desc = "A stand-in for the nursefather during debug corrections."
    icon = 'icons/mob/human.dmi'
    icon_state = "human"
    maxHealth = 9999
    health = 9999
    stat_attack = CONSCIOUS
    faction = list("neutral")
    melee_damage_lower = 5
    melee_damage_upper = 10
```
Spawned adjacent to the apprentice by the "Simulate Duel Loss + Correction" button. Faces the apprentice, plays the correction animation as the attacker (including `do_attack_animation`, `face_atom`, cutscene_duel component), then is `qdel()`'d after the animation completes. Has high HP so it doesn't die during the animation.

This debug kit is added in **Step 1** and updated with new options as each step is implemented. That way every step is immediately testable when completed.

---

## File Summary (all new files to create)
```
ModularLobotomy/thumb_spider/palermitan_debug.dm          — spawnable debug kit item
ModularLobotomy/thumb_spider/palermitan_base.dm           — base passives component (Duello + Palermitan Style + nursefather interactions)
ModularLobotomy/thumb_spider/palermitan_exp.dm            — EXP + skill point + school investment tracking
ModularLobotomy/thumb_spider/palermitan_duel.dm           — duel system + arena + challenge action + rewards
ModularLobotomy/thumb_spider/palermitan_tree.dm           — skill tree TGUI datum + 4 school definitions (24 skills)
ModularLobotomy/thumb_spider/palermitan_skills.dm         — skill node components (4 schools x 3 tiers x 2 choices)
ModularLobotomy/thumb_spider/palermitan_role_passives.dm  — role-specific passive components (18 roles)
tgui/packages/tgui/interfaces/PalermitanSkillTree.js      — React skill tree UI (4 school tabs)
```

## Existing files to modify
```
code/datums/status_effects/debuffs.dm                                       — Duel Escalates + Severed Tendon status effects
ModularLobotomy/ego_weapons/melee/city/thumb_spider.dm                      — weapon dual-wield by tier
code/modules/jobs/job_types/trusted_players/thumb_nursefather.dm             — recruitment integration
code/modules/clothing/suits/ego_gear/non_abnormality/thumb.dm               — (already done, set_tier exists)
lobotomy-corp13.dme                                                          — include new files
```
