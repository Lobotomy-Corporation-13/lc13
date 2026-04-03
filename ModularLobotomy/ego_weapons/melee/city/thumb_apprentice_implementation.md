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

## Step 4: Palermitan EXP + Skill Point Component
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

## Step 5: Duel System — Core Datum + Arena + Win/Loss
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

## Step 6: Duel Rewards — Attributes + EXP + Role Tracking
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

## Step 7: Nursefather Interactions — Drinks, Glass, Correction
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

## Step 8: Skill Tree — Definitions + TGUI
**Files to create:**
- `ModularLobotomy/thumb_spider/palermitan_tree.dm` — TGUI datum + skill definitions
- `tgui/packages/tgui/interfaces/PalermitanSkillTree.js` — React UI

**What to implement:**
- `/datum/palermitan_skill_tree` — TGUI datum
  - `GLOB.palermitan_skill_definitions` — 5 tiers, 2 choices each (10 skills total)
  - `ui_data()` — serves tier data with availability/lock/selected flags
  - `ui_act("select_skill")` — validates and grants skill component
- React UI based on `RingSkillTree.js` but single-school, 5 tiers, dark red theme
- `/datum/action/innate/palermitan_tree` — opens the tree UI

**How to test:**
- Use debug kit → "Grant Skill Tree Action" + "Grant EXP Component"
- Use debug kit → "Add EXP → 900" (grants all 15 skill points for testing)
- Click the "Palermitan Skill Tree" action button — verify the TGUI window opens
- Verify all 5 tiers display with a/b choices, dark red theme
- Verify tier 2+ are locked until tier 1 is completed
- Click "Learn Skill" on tier 1a — verify it highlights green and tier 1b becomes excluded (red)
- Verify tier 2 is now unlocked
- Continue selecting skills through all 5 tiers
- Use debug kit → "Reset All" and reopen — verify tree is blank again

---

## Step 9: Skill Tree — Skill Components (Tiers 1-3)
**Files to create:**
- `ModularLobotomy/thumb_spider/palermitan_skills.dm` — skill components

**What to implement:**
- `/datum/component/palermitan_skill` — base component (same pattern as ring_skill)
- **1a: Severed Tendon** — On Hit vs 3+ Duel Escalates: inflict 2 OLD (3 OLD at 7+)
- **1b: Relentless Pursuit** — On Hit vs Duel Escalates target: gain 1 Poise (2 at 5+)
- **2a: Il Cacciatore** — On Hit: inflict 2 Tremor. Vs Duel Escalates: gain 1 OLU
- **2b: Colpi Sottani** — On Hit: inflict 2 Overheat. Vs Duel Escalates: also 1 Tremor. At 7+: gain 2 OLU
- **3a: Palermitan Rapier** — On Tremor Burst: gain 5 OLU
- **3b: Duello Feroce** — On Hit vs Duel Escalates: heal 2 HP/stack (max 10). At 10+: gain 3 DLU

**How to test:**
- Use debug kit → "Grant Base Passives" + "Grant Skill Tree Action" + "Grant EXP Component" + "Add EXP → 900"
- Open skill tree, select **1a: Severed Tendon**
- Attack a mob until it has 3+ Duel Escalates stacks — verify 2 Offense Level Down appears on target. At 7+ stacks, verify 3 OLD.
- Use debug kit → "Reset All", re-grant, select **1b: Relentless Pursuit** instead
- Attack a mob with Duel Escalates — verify you gain 1 Poise per hit. At 5+ stacks, verify 2 Poise per hit.
- Repeat for tier 2 and 3 skills:
  - **2a Il Cacciatore:** Attack mob, verify 2 Tremor inflicted. Hit target with Duel Escalates, verify 1 OLU gained.
  - **2b Colpi Sottani:** Verify 2 Overheat inflicted. Vs Duel Escalates target: also 1 Tremor. At 7+ stacks: verify 2 OLU gained.
  - **3a Palermitan Rapier:** Build tremor on a target until it bursts, verify you gain 5 OLU.
  - **3b Duello Feroce:** Attack mob with Duel Escalates, verify HP heals (2 per stack, max 10). At 10+ stacks: verify 3 DLU gained.

---

## Step 10: Skill Tree — Skill Components (Tiers 4-5)
**Files to modify:**
- `ModularLobotomy/thumb_spider/palermitan_skills.dm` — add remaining skills

**What to implement:**
- **4a: Sezionatura di Cervo** — Activated ability (60s CD). Next hit: 4 Overheat + 4 Tremor + Tremor Burst + bonus RED = (Duel Escalates * 5). Consumes all stacks.
- **4b: La Spada di Palermo** — On Hit vs 10+ Duel Escalates (30s CD): gain 5 OLU + 3 Damage Up, consume 5 stacks
- **5a: Valencina's Legacy** — On Hit: spread 1 Duel Escalates to enemies within 2 tiles. At 10+: inflict 2 Tremor + 2 Overheat to nearby
- **5b: The Famiglia's Honor** — Max Duel Escalates → 30. At 15+: gain 3 OLU + inflict 2 DLD. At 25+: also inflict 3 Fragile

**How to test:**
- Use debug kit → full setup (base passives + EXP + tree + 900 EXP), select skills through to tier 4/5
- **4a Sezionatura:** Select the skill, verify a new action button appears ("Sezionatura di Cervo"). Attack a mob until 10+ Duel Escalates. Activate the ability, then hit the mob — verify 4 Overheat + 4 Tremor + Tremor Burst + bonus RED damage. Verify all Duel Escalates consumed. Verify 60s cooldown on the ability.
- **4b La Spada:** Reset and select 4b instead. Attack a mob until 10+ Duel Escalates. Verify you gain 5 OLU + 3 Damage Up and 5 stacks are consumed. Verify 30s world.time cooldown.
- **5a Valencina:** Select 5a. Attack a mob near other mobs. Verify Duel Escalates spreads to mobs within 2 tiles. Build to 10+ stacks, verify 2 Tremor + 2 Overheat hit nearby enemies.
- **5b Famiglia:** Select 5b. Verify Duel Escalates now caps at 30 instead of 20. Build to 15+ stacks, verify 3 OLU gained + 2 DLD on target. Build to 25+, verify 3 Fragile also inflicted.

---

## Step 11: Role-Specific Passives
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

## Step 12: Recruitment Integration + DME
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
- **Grant All Skills** — unlocks all 5 tiers (picks 'a' choice for each)
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
ModularLobotomy/thumb_spider/palermitan_debug.dm          — spawnable debug kit item + TGUI
ModularLobotomy/thumb_spider/palermitan_base.dm          — base passives component
ModularLobotomy/thumb_spider/palermitan_exp.dm            — EXP + skill point tracking
ModularLobotomy/thumb_spider/palermitan_duel.dm           — duel system + arena + challenge action
ModularLobotomy/thumb_spider/palermitan_tree.dm           — skill tree TGUI datum + definitions
ModularLobotomy/thumb_spider/palermitan_skills.dm         — skill node components (tiers 1-5)
ModularLobotomy/thumb_spider/palermitan_role_passives.dm  — role-specific passive components
ModularLobotomy/thumb_spider/palermitan_actions.dm        — action buttons (tree, duel, sezionatura)
tgui/packages/tgui/interfaces/PalermitanSkillTree.js      — React skill tree UI
```

## Existing files to modify
```
code/datums/status_effects/debuffs.dm                                       — new status effects
ModularLobotomy/ego_weapons/melee/city/thumb_spider.dm                      — weapon dual-wield by tier
code/modules/jobs/job_types/trusted_players/thumb_nursefather.dm             — recruitment integration
code/modules/clothing/suits/ego_gear/non_abnormality/thumb.dm               — (already done, set_tier exists)
lobotomy-corp13.dme                                                          — include new files
```
