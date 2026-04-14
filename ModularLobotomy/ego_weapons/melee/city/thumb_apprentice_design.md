# Thumb Apprentice Progression Design Document

## Current State
- Apprentice starts at **40 all stats** with tier 1 gear
- Gear has 4 tiers: tier 1 (40 attr), tier 2 (60 attr), tier 3 (80 attr), tier 4 (100 attr)
- `set_tier()` proc exists on armor, katana, and greatsword but has no trigger yet
- Weapons: katana (fast, force 22/32/44/65) and greatsword (slow, force 33/48/66/98)
- Armor: 60/90/130/210 total armor points per tier
- **Dual-wield by tier:**
  - Tier 1: no dual-wield
  - Tier 2-3: every 2nd hit triggers partner weapon at 25% damage + inflicts 1 Duel Escalates
  - Tier 4: every hit triggers partner weapon at 25% damage + inflicts 1 Duel Escalates
- Implemented via `set_tier()` — adjusts `swing_threshold` var (2 at tier 2-3, 1 at tier 4). At tier 1, dual-wield is disabled.

## Progression Trigger
- **Duels** are the main progression mechanic
- When the apprentice wins OR loses a duel, they gain attributes
- Attribute gain scales with the opponent's attributes — stronger opponents = more growth
- Max attributes: **200 all**
- Gear tiers up when: `(apprentice attributes / 2) >= gear tier requirement`
  - Tier 2 unlocks at 120 attributes (120/2 = 60)
  - Tier 3 unlocks at 160 attributes (160/2 = 80)
  - Tier 4 unlocks at 200 attributes (200/2 = 100)

---

## Duel System (PvP)

### How to Start a Duel
**Option A: Action button**
- Apprentice gets a `/datum/action` button (granted on recruitment)
- Click the action, then click a target player — sends them a duel challenge
- Target gets an alert: "X challenges you to a duel. Accept?"

**Option B: Item-based**
- Apprentice gets a "duel gauntlet" item
- Hit another player with it to challenge them

**Option C: Verb-based**
- Right-click another player -> "Challenge to Duel"

### Duel Arena (based on elite_tumor pattern)
- A ring of visual markers spawns around the midpoint between the two players
- Uses `RANGE_TURFS(radius, center)` + `get_dist() == radius` to place markers on the border
- **Barrier does NOT block movement** — stepping on a barrier tile instantly ends the duel (the player who stepped on it loses)
- Markers refresh on a timer loop since they're temp_visuals with a duration

### Win/Loss Conditions
- A player **enters crit** (SOFT_CRIT via `COMSIG_MOB_STATCHANGE`) → loser
- A player **steps on a barrier tile** (Crossed()) → auto-lose
- A player is **deleted/disconnects** → auto-lose

### Post-Duel Healing
- **Winner**: healed for **50% of their missing HP**
- **Loser**: healed for **25% of their missing HP**

---

## Duelable Roles

### Association Members (`ModularLobotomy/associations`)
- Grants association EXP back to the association member on duel
- Grants Palermitan EXP + role-specific passive progress to apprentice

### City Roles
- `code/modules/jobs/job_types/city/carnival.dm` — Carnival members
- `code/modules/jobs/job_types/city/backstreets_butcher.dm` — Backstreets Butchers
- `code/modules/jobs/job_types/city/rat.dm` — Rats
- `code/modules/jobs/job_types/city/syndicate.dm` — Syndicate members
- `code/modules/jobs/job_types/city/civilian.dm` — Civilians
- `code/modules/jobs/job_types/city/misc/blade_lineage_misc.dm` — Blade Lineage

### Trusted Roles
- `code/modules/jobs/job_types/trusted_players/association/roaming.dm` — Roaming association members

---

## Dual Reward System

### Apprentice Gets (from every duel):
1. **Attribute growth** — scales with opponent's attributes
2. **Palermitan EXP** — goes toward the Palermitan Style skill tree
3. **Role-specific passive progress** — tracked per role, unlocks passives from dueling that role repeatedly

### Opponent Gets (when dueling the apprentice):
- **Association members** → EXP for their association system
- **Other roles** → partial healing only (the duel itself is the content)

---

## Palermitan Style Skill Tree

### Overview (from Limbus Company lore, adapted to SS13)
> The Palermitan Style has much in common with La Famiglia Bognatelli — renowned for relentlessly
> focusing on a single prey during a hunt, concluded with a Coup de Grâce.
> These executions are not carried out in the shadows, but proudly put on display.

**Core mechanic: "The Duel Escalates"** — a stacking status effect inflicted on the target.
The more you fight a single target, the stronger you become against them.

### System Architecture (mirrors Ring skill tree exactly)
- Uses the same pattern as `/datum/ring_skill_tree` + `/datum/component/ring_skill`
- **4 schools**, each with **3 tiers** and **2 mutually exclusive choices per tier** (a/b)
- Tier costs: 1, 2, 3 skill points per tier
- Must complete tier N before accessing tier N+1 within a school
- Max schools: **2** (same as Ring default — can invest in 2 of the 4 schools)
- TGUI interface reuses `RingSkillTree.js` pattern with tabs per school
- Skills are components registered via signals (`COMSIG_MOB_ITEM_ATTACK`, etc.)

### New Status Effect: "The Duel Escalates"
```
/datum/status_effect/stacking/duel_escalates
  id = "duel_escalates"
  max_stacks = 20
  tick_interval = 10 SECONDS
  var/mob/living/duelist
```
- Gained by the TARGET when the apprentice hits them (1 stack per hit via "Duello" passive)
- Expires if the apprentice doesn't hit the target for a full tick (10 seconds)
- Grants the apprentice scaling bonuses against targets with this effect

### Base Passive: "Duello" (always active, not a tree skill)
- **On Hit**: Inflict 1 "The Duel Escalates" on target
- **On Hit vs target with Duel Escalates**: Heal 3 sanity per stack (max 15 sanity per hit)
- This is the foundation — tree schools enhance what Duel Escalates does

### Base Passive: "Palermitan Style" (always active, scales with Duel Escalates)
Per stack of Duel Escalates on target:
- Deal **+5% damage** against that target
- Take **-5% damage** from that target
- At **5+ stacks**: +5 force bonus
- At **10+ stacks**: +10 force bonus

---

### Skill Tree — 4 Schools

#### School 1: "Terremoto" (Earthquake) — Tremor Focus
**Color**: `#8b6914` (amber/brown)
**Theme**: Destabilize the target with tremor, culminating in devastating tremor bursts.
**Cross-school overlap**: Tier 3 options interact with Overheat (triggering tremor burst also applies burn effects).

**Tremor Burst Progression:**
- Base passives and Tier 1 skills apply tremor with `INFINITY` burst threshold (no burst).
- Tier 2 **unlocks tremor bursting** — skills change the burst threshold to a reachable value (e.g., 15 or 20 stacks), or provide ways to force-trigger bursts.
- Tier 3 provides powerful payoffs that proc on tremor burst, rewarding the investment.
- Without investing in Terremoto tier 2+, tremor stacks just slow the target but never burst.

##### Tier 1 (cost: 1)
**1a: "Il Cacciatore" (The Hunter)**
- On Hit: inflict 2 Tremor (`apply_lc_tremor`, INFINITY burst — no burst yet)
- On Hit vs target with Duel Escalates: also gain 1 Offense Level Up
- *Builds tremor stacks for slowdown. Burst unlocked at tier 2.*

**1b: "Destabilizing Strikes"**
- On Hit: inflict 1 Tremor (INFINITY burst). On Hit vs target with 3+ Duel Escalates: inflict 2 Tremor instead
- At 7+ Duel Escalates: inflict 3 Tremor instead
- *Slower tremor buildup that scales heavily with Duel Escalates commitment*

##### Tier 2 (cost: 2)
**2a: "Palermitan Rapier" (The Cleaving Blade)**
- **Unlocks tremor bursting:** Your tremor applications now use a burst threshold of **15** instead of INFINITY
- When your attacks trigger a Tremor Burst: gain 5 Offense Level Up and 5 Poise
- *The key unlock — tremor now detonates at 15 stacks, rewarding you with OLU and Poise on burst*

**2b: "Aftershock"**
- **Unlocks tremor bursting:** Your tremor applications now use a burst threshold of **25** instead of INFINITY (higher threshold = more buildup before burst, but bigger tremor burst effect since stacks are higher)
- On Hit vs target with 10+ Tremor: inflict 2 Offense Level Down on target
- On Hit vs target with 20+ Tremor: inflict 3 Offense Level Down instead
- *Higher burst threshold for bigger knockdowns, plus debuffs while building*

##### Tier 3 (cost: 3)
**3a: "Sezionatura di Cervo" (Butchering the Deer)**
- Activated ability (60s CD). Next hit: inflict 4 Tremor + 4 Overheat, **force trigger Tremor Burst** (regardless of threshold), deal bonus RED = (Duel Escalates * 5). Consume 50% of Duel Escalates stacks (rounded down).
- *Cross-school: Overheat application on the finisher. Guaranteed burst even if below threshold.*

**3b: "Tectonic Collapse"**
- On Tremor Burst: inflict 3 Fragile on the target and 3 Defense Level Down
- Also inflict 2 Overheat on the target when tremor bursts
- *Turns tremor bursts into a massive debuff window + cross-school overheat*

---

#### School 2: "Incendio" (Inferno) — Overheat Focus
**Color**: `#c44536` (red/flame)
**Theme**: Burn the target down with escalating overheat, using Duel Escalates to accelerate the burn.
**Cross-school overlap**: Tier 3 options interact with Tremor (burn detonation also applies tremor).

##### Tier 1 (cost: 1)
**1a: "Colpi Sottani" (Low Blows)**
- On Hit: inflict 2 Overheat (`apply_lc_overheat`)
- On Hit vs target with Duel Escalates: inflict 3 Overheat instead

**1b: "Scorching Pursuit"**
- On Hit: inflict 1 Overheat. At 5+ Duel Escalates: inflict 2 Overheat instead
- On Hit vs target with Overheat: gain 1 Offense Level Up

##### Tier 2 (cost: 2)
**2a: "Firestorm"**
- On Hit vs target with 10+ Overheat: gain 3 Offense Level Up, 3 Poise
- *Reward for sustained burn buildup — also feeds into Poise for crit potential*

**2b: "Smoldering Wounds"**
- On Hit vs target with Overheat: inflict 1 Defense Level Down per 5 Overheat stacks on target (max 3 DLD)
- *Overheat weakens the target's defenses*

##### Tier 3 (cost: 3)
**3a: "La Spada di Palermo" (The Sword of Palermo)**
- On Hit vs target with 10+ Duel Escalates (30s CD): gain 5 Offense Level Up + 3 Damage Up, consume 5 Duel Escalates
- On activation: also inflict 3 Tremor on the target
- *Cross-school: Tremor application on the power spike*

**3b: "Conflagration"**
- On Hit vs target with 15+ Overheat: deal bonus RED damage equal to (Overheat stacks), then reduce Overheat by 5
- Also inflict 2 Tremor on detonation
- *Consume burn stacks for burst damage + cross-school tremor*

---

#### School 3: "Eleganza" (Elegance) — Poise & Concentration Focus
**Color**: `#5b7c99` (steel blue)
**Theme**: Build Poise for critical strikes and Concentration to sustain momentum. The refined swordsman's path.
**Cross-school overlap**: Tier 3 options enhance crits to apply Tremor or Overheat.

##### Tier 1 (cost: 1)
**1a: "Relentless Pursuit"**
- On Hit vs target with **under 5** Duel Escalates: gain 1 Concentration (world.time CD, 10 sec)
- On Hit vs target with **5+** Duel Escalates: gain 3 Poise instead (replaces the Concentration effect)
- *Early duel: build Concentration as a safety net. Once the duel heats up (5+ stacks): shift to aggressive Poise building*

**1b: "Focused Mind"**
- On Hit vs target with **under 5** Duel Escalates: gain 1 Poise and 1 Concentration (world.time CD, 10 sec for the Concentration)
- On Hit vs target with **5+** Duel Escalates: gain 3 Poise instead (replaces both effects)
- *Early duel: balanced Poise + Concentration. Once committed (5+ stacks): pure Poise aggression. Concentration only comes from the opening exchanges*

##### Tier 2 (cost: 2)
**2a: "Duello Feroce" (Fierce Duel)**
- On Hit vs target with Duel Escalates: gain 1 Poise per 3 stacks (max 3 Poise) and heal 2 HP per stack (max 10)
- On Poise crit that **halved your Poise** (i.e., no Concentration was consumed to preserve it): gain 1 Concentration
- *Crits that cost you Poise reward you with Concentration for next time. But if Concentration saved your Poise, you don't gain more — preventing infinite loops*

**2b: "Severed Tendon"**
- On Poise crit: inflict 3 Offense Level Down and 1 Fragile on the crit target
- On Poise crit that **halved your Poise** (same condition as 2a): gain 1 Poise back (softens the halving, but doesn't prevent it)
- *Crits devastate the target's offense. The Poise recovery on halving crits reduces the sting but doesn't create infinite loops since Poise is still halved*

##### Tier 3 (cost: 3)
**3a: "Valencina's Legacy" (The War Hero)**
- On Poise crit: inflict 3 Tremor and 3 Overheat on the target
- On Poise crit: Duel Escalates spread to enemies within 2 tiles
- On Poise crit (world.time CD, 15 sec): gain 1 Concentration
- *Cross-school: Crits feed both Tremor and Overheat schools. Concentration gain is cooldown-gated*

**3b: "The Famiglia's Honor" (Bognatelli Perfection)**
- Duel Escalates max stacks increased to 30
- On Hit vs target with 15+ Duel Escalates: gain 2 Poise
- On Poise crit that **halved your Poise** vs target with 15+ Duel Escalates: gain 1 Concentration
- On Poise crit vs target with 20+ Duel Escalates: inflict 3 Fragile and 3 Defense Level Down on target
- *Single-target mastery — extreme DE commitment feeds Poise. Concentration only from paid crits, preventing infinite loops*

---

#### School 4: "Fondamenti" (Fundamentals) — General Passives
**Color**: `#8b8b8b` (grey/steel)
**Theme**: Core combat improvements that benefit any build. No status effect specialization — pure fighting fundamentals.

##### Tier 1 (cost: 1)
**1a: "Iron Constitution"**
- On taking damage: gain 2 Defense Level Up
- *Simple survivability*

**1b: "Aggressive Footwork"**
- On Hit: gain 1 Offense Level Up
- On taking melee damage: gain 1 Offense Level Up
- *Reward both offense and defense with power*

##### Tier 2 (cost: 2)
**2a: "Predator's Instinct"**
- On Hit vs target below 50% HP: inflict 2 Fragile and gain 2 Poise
- On Hit vs target below 25% HP: also gain 5 Offense Level Up and 2 Poise
- *Execute weakened prey — finishing blows build Poise for crits*

**2b: "Enduring Spirit"**
- On Hit vs target with Duel Escalates: heal 1 HP per stack (max 5)
- On taking damage while Duel Escalates is active on any nearby target: gain 1 Defense Level Up
- *Sustain while dueling*

##### Tier 3 (cost: 3)
**3a: "Coup de Grâce"**
- On Hit vs target below 20% HP with 5+ Duel Escalates: deal bonus RED damage = (Duel Escalates * 3), consume 50% of stacks (rounded down)
- *Universal finisher — works regardless of which status school you chose*

**3b: "Unbreakable Will"**
- When entering soft crit (world.time CD, 60 sec): gain 5 Defense Level Up + 3 Protection + heal 10% max HP
- *Emergency survival tool*

---

### School Investment Rules
- Max **3 schools** invested
- Each school: 3 tiers, costs 1+2+3 = **6 points per school**
- Full 2-school investment = **12 points**
- 10 base skill points available from EXP thresholds
- Remaining 2 points need bonus sources (nursefather mentor, completing role passives, etc.)

### Cross-School Synergies
The schools are designed so that picking one status school (Tremor OR Overheat) pairs well with either Elegance (Poise crits apply your chosen status) or Fundamentals (general power). Some tier 3 skills explicitly bridge between schools:
- **Sezionatura** (Tremor T3a): also applies Overheat
- **La Spada** (Overheat T3a): also applies Tremor
- **Valencina** (Elegance T3a): crits apply both Tremor + Overheat
- **Conflagration** (Overheat T3b): detonation also applies Tremor

This encourages builds like:
- **Tremor + Elegance**: Build tremor, use poise crits to detonate + spread
- **Overheat + Fundamentals**: Burn them down, use general passives for survivability
- **Tremor + Overheat**: Maximum status pressure, tier 3 finishers bridge both
- **Elegance + Fundamentals**: Pure combat mastery without status specialization

---

## Role-Specific Passives (from repeated dueling)

Each duelable role grants **one unique passive** that has **3 tiers** of increasing strength.
Tier upgrades automatically as the apprentice duels that role more times.
These are separate from the main Palermitan tree — earned purely through dueling, no skill points.

### Structure
- 1 passive per role, 3 tiers
- Tier 1: unlocked at **1 duel** against that role
- Tier 2: upgrades at **3 duels** against that role
- Tier 3: upgrades at **5 duels** against that role
- Passives are minor and thematic, not as powerful as main tree skills

### Role Passives

#### Butcher — "Predator's Instinct"
*Learned from fighting someone who hunts and isolates prey.*
- **Tier 1 (1 duel):** On Hit vs a target below 50% HP: deal +5% bonus damage
- **Tier 2 (3 duels):** On Hit vs a target below 50% HP: deal +10% bonus damage
- **Tier 3 (5 duels):** On Hit vs a target below 50% HP: deal +15% bonus damage, and heal 3 HP per hit against low-HP targets

#### Blade Lineage — "Resolve of the Salsu"
*Learned from fighting honorable duelists who risk everything on a single strike.*
- **Tier 1 (1 duel):** When below 30% HP: gain +10% damage on all attacks
- **Tier 2 (3 duels):** When below 30% HP: gain +15% damage on all attacks
- **Tier 3 (5 duels):** When below 30% HP: gain +20% damage on all attacks, and your attacks cannot be dodged

#### — SYNDICATE FACTIONS (each faction has its own passive) —

#### Thumb / Thumb East — "Soldato's Discipline"
*Learned from fighting organized soldiers who endure through sheer grit.*
- **Tier 1 (1 duel):** On taking RED damage: gain 2 Defense Level Up (`apply_lc_defense_level_up`)
- **Tier 2 (3 duels):** On taking RED damage: gain 3 Defense Level Up
- **Tier 3 (5 duels):** On taking RED damage: gain 3 Defense Level Up and 1 Offense Level Up (`apply_lc_offense_level_up`)

#### Kurokumo — "Way of the Drawn Blade"
*Learned from fighting momentum-based swordsmen who grow deadlier with each swing.*
- **Tier 1 (1 duel):** On Hit: gain 1 Poise (independent of tree skills)
- **Tier 2 (3 duels):** On Hit: gain 1 Poise. At 10+ Poise: +5% crit damage
- **Tier 3 (5 duels):** On Hit: gain 1 Poise. At 10+ Poise: +10% crit damage, and crits inflict 2 Tremor

#### Index — "Prescript Discipline"
*Learned from fighting mission-focused killers who designate and destroy their prey.*
- **Tier 1 (1 duel):** On Hit: inflict 1 Offense Level Down (`apply_lc_offense_level_down`) on target
- **Tier 2 (3 duels):** On Hit: inflict 1 Offense Level Down and 1 Defense Level Down (`apply_lc_defense_level_down`) on target
- **Tier 3 (5 duels):** On Hit: inflict 2 Offense Level Down and 1 Defense Level Down on target

#### Insurgence — "Nightwatch Tremors"
*Learned from fighting agents who use tremors to lock down their prey.*
- **Tier 1 (1 duel):** On Hit: 15% chance to inflict 1 Tremor (no burst)
- **Tier 2 (3 duels):** On Hit: 20% chance to inflict 1 Tremor (no burst)
- **Tier 3 (5 duels):** On Hit: 25% chance to inflict 2 Tremor (no burst), and targets with 10+ Tremor take +5% more damage from you

#### Middle — "Vengeance Mark"
*Learned from fighting retaliatory brawlers who get stronger the more you hit them.*
- **Tier 1 (1 duel):** On taking melee damage: gain +3% damage on your next attack (doesn't stack)
- **Tier 2 (3 duels):** On taking melee damage: gain +5% damage on your next attack (doesn't stack)
- **Tier 3 (5 duels):** On taking melee damage: gain +8% damage on your next two attacks, and the counter-hit inflicts 1 Duel Escalates

#### N-Corp — "Methodical Strikes"
*Learned from fighting systematic enforcers who mark and punish their targets.*
- **Tier 1 (1 duel):** On Hit: inflict 1 Defense Level Down (`apply_lc_defense_level_down`) on target and inflict 1 Overheat (`apply_lc_overheat`)
- **Tier 2 (3 duels):** On Hit: inflict 1 Defense Level Down and 2 Overheat on target
- **Tier 3 (5 duels):** On Hit: inflict 2 Defense Level Down and 2 Overheat on target

#### Rat — "Scavenger's Luck"
*Learned from fighting unpredictable scavengers who make do with junk.*
- **Tier 1 (1 duel):** On Hit: 5% chance to deal +50% bonus damage on that hit (lucky strike)
- **Tier 2 (3 duels):** On Hit: 8% chance to deal +50% bonus damage on that hit
- **Tier 3 (5 duels):** On Hit: 10% chance to deal +50% bonus damage on that hit, and lucky strikes also inflict 2 Tremor

#### Carnival — "Silk Hunter's Patience"
*Learned from fighting mechanical predators who wait for the perfect moment to strike.*
- **Tier 1 (1 duel):** After not attacking for 3+ seconds, your next attack deals +10% damage
- **Tier 2 (3 duels):** After not attacking for 3+ seconds, your next attack deals +20% damage
- **Tier 3 (5 duels):** After not attacking for 3+ seconds, your next attack deals +30% damage and inflicts 2 Overheat

#### Civilian — <!-- TBD (later) -->

#### — ASSOCIATION FACTIONS (passive depends on which association the member belongs to) —

#### Zwei — "Guardian's Resilience"
*Learned from fighting defensive tanks who endure and outlast.*
- **Tier 1 (1 duel):** On taking damage: gain 2 Defense Level Up (`apply_lc_defense_level_up`)
- **Tier 2 (3 duels):** On taking damage: gain 3 Defense Level Up
- **Tier 3 (5 duels):** On taking damage: gain 3 Defense Level Up and inflict 1 Offense Level Down (`apply_lc_offense_level_down`) on the attacker

#### Seven — "Analyst's Eye"
*Learned from fighting intelligence operatives who exploit weaknesses with precision.*
- **Tier 1 (1 duel):** On Hit vs target with any debuff (tremor/overheat/bleed/mental decay/fragile/DLD/OLD): gain 1 Offense Level Up (`apply_lc_offense_level_up`)
- **Tier 2 (3 duels):** On Hit vs debuffed target: gain 2 Offense Level Up
- **Tier 3 (5 duels):** On Hit vs debuffed target: gain 2 Offense Level Up and inflict 1 additional Duel Escalates

#### Dieci — "Scholar's Insight"
*Learned from fighting knowledge-wielders who control the battlefield with status effects.*
- **Tier 1 (1 duel):** On Hit vs a target with any status effect (tremor/overheat/bleed/mental decay): deal +3% damage per distinct effect type
- **Tier 2 (3 duels):** On Hit vs a target with any status effect: deal +5% damage per distinct effect type
- **Tier 3 (5 duels):** On Hit vs a target with any status effect: deal +7% damage per distinct effect type (max +28% with all 4)

#### Cinq — "Duelist's Finesse"
*Learned from fighting refined duelists with precise swordwork. (Roaming fixer only)*
- **Tier 1 (1 duel):** On Hit: gain 2 Poise (`apply_lc_poise`)
- **Tier 2 (3 duels):** On Hit: gain 3 Poise
- **Tier 3 (5 duels):** On Hit: gain 3 Poise. On Poise crit that **halved your Poise**: gain 1 Concentration

#### — ROAMING FIXER (passive depends on which association variant spawned) —
*Roaming fixers spawn as a random association variant. The passive granted matches the association they represent.*
*Dueling a Zwei roaming fixer grants progress toward the Zwei passive, a Shi roaming fixer grants Shi progress, etc.*

#### Shi — "Assassin's Sacrifice"
*Learned from fighting assassins who sacrifice their own flesh for lethal strikes.*
- **Tier 1 (1 duel):** On Hit vs target below 30% HP (world.time cooldown, 3 sec): gain 3 Offense Level Up (`apply_lc_offense_level_up`) but lose 3% of your max HP
- **Tier 2 (3 duels):** On Hit vs target below 30% HP (3 sec cooldown): gain 4 Offense Level Up but lose 3% of your max HP
- **Tier 3 (5 duels):** On Hit vs target below 30% HP (3 sec cooldown): gain 5 Offense Level Up and inflict 2 Fragile (`apply_lc_fragile`) on target, but lose 3% of your max HP

#### Liu — "Burning Fist"
*Learned from fighting martial artists who channel fire through their strikes.*
- **Tier 1 (1 duel):** On Hit: inflict 1 Overheat
- **Tier 2 (3 duels):** On Hit: inflict 1 Overheat. Every 4th consecutive hit: inflict 2 additional Overheat
- **Tier 3 (5 duels):** On Hit: inflict 1 Overheat. Every 3rd consecutive hit: inflict 3 additional Overheat

#### Devyat — "Berserker's Escalation"
*Learned from fighting couriers whose rage builds with every exchange of blows.*
- **Tier 1 (1 duel):** On Hit (world.time cooldown, 3 sec): gain 2 Offense Level Up (`apply_lc_offense_level_up`) but lose 2% of your max HP
- **Tier 2 (3 duels):** On Hit (3 sec cooldown): gain 3 Offense Level Up but lose 2% of your max HP
- **Tier 3 (5 duels):** On Hit (3 sec cooldown): gain 3 Offense Level Up but lose 2% of your max HP. On Hit while below 50% HP: also gain 2 Defense Level Up (`apply_lc_defense_level_up`)

#### Hana — "Adaptive Form"
*Learned from fighting versatile fixers who switch between sword, spear, and fist.*
- **Tier 1 (1 duel):** On attacking with a different weapon than your last attack (world.time cooldown, 5 sec): gain 2 Offense Level Up (`apply_lc_offense_level_up`)
- **Tier 2 (3 duels):** On attacking with a different weapon: gain 2 Offense Level Up and 2 Defense Level Up (`apply_lc_defense_level_up`)
- **Tier 3 (5 duels):** On attacking with a different weapon: gain 3 Offense Level Up and 2 Defense Level Up
- **Implementation:** Track `var/obj/item/last_weapon_used` and `var/last_switch_bonus_time` on the component. In `on_attack`, compare current weapon to `last_weapon_used`. If different and `world.time > last_switch_bonus_time + 5 SECONDS`, grant bonus and update both vars. Always update `last_weapon_used` at end of proc. No extra signals needed — just a var comparison in the existing `COMSIG_MOB_ITEM_ATTACK` handler.

### Implementation Note: No Timers
All passives use only:
- Simple var tracking (hit counters, last target refs, buffed_next_attack flags)
- `world.time` comparisons for cooldowns (e.g., `if(world.time > last_proc_time + cooldown)`)
- Direct checks on `on_attack` / `on_take_damage` signal handlers
- No `addtimer()`, `sleep()`, or `spawn()` calls

---

## Implementation Architecture (mirrors Ring system)

### Files to Create
```
ModularLobotomy/thumb_spider/palermitan_tree.dm        — TGUI datum + skill definitions (like ring_skill_tree.dm)
ModularLobotomy/thumb_spider/palermitan_exp.dm          — EXP/skill point component (like artistic_exp.dm)
ModularLobotomy/thumb_spider/palermitan_skills.dm       — Skill components (like schools/_schools.dm)
ModularLobotomy/thumb_spider/palermitan_status.dm       — "The Duel Escalates" + "Severed Tendon" status effects
ModularLobotomy/thumb_spider/palermitan_actions.dm      — Action buttons (tree, duel challenge)
tgui/packages/tgui/interfaces/PalermitanSkillTree.js    — React UI (based on RingSkillTree.js)
```

### Key Datums
```
/datum/component/palermitan_exp              — tracks EXP, skill points, role duel counts
/datum/palermitan_skill_tree                 — TGUI datum, serves tree data
/datum/component/palermitan_skill            — base skill component (signals for on_attack etc.)
/datum/component/palermitan_skill/tier1a     — Severed Tendon
/datum/component/palermitan_skill/tier1b     — Relentless Pursuit
/datum/component/palermitan_skill/tier2a     — Il Cacciatore
/datum/component/palermitan_skill/tier2b     — Colpi Sottani
/datum/component/palermitan_skill/tier3a     — Palermitan Rapier
/datum/component/palermitan_skill/tier3b     — Duello Feroce
/datum/component/palermitan_skill/tier4a     — Sezionatura di Cervo
/datum/component/palermitan_skill/tier4b     — La Spada di Palermo
/datum/component/palermitan_skill/tier5a     — Valencina's Legacy
/datum/component/palermitan_skill/tier5b     — The Famiglia's Honor
/datum/status_effect/stacking/duel_escalates — target debuff
/datum/status_effect/stacking/severed_tendon — target debuff (force reduction)
/datum/action/innate/palermitan_tree         — opens skill tree UI
/datum/action/innate/thumb_duel_challenge    — challenges players to duels
```

### Reference Code (Ring system to mirror)
- `ModularLobotomy/ring/ring_skills/ring_skill_tree.dm` — tree structure + TGUI datum
- `ModularLobotomy/ring/ring_skills/artistic_exp.dm` — EXP component
- `ModularLobotomy/ring/ring_skills/schools/_schools.dm` — base skill component with signal registration
- `ModularLobotomy/ring/ring_skills/schools/corporist.dm` — example school with complex skills
- `ModularLobotomy/ring/actions/corporist_actions.dm` — tree action
- `tgui/packages/tgui/interfaces/RingSkillTree.js` — React UI

---

## Concept Code

### Duel Datum
```dm
/datum/thumb_duel
	var/mob/living/carbon/human/challenger
	var/mob/living/carbon/human/opponent
	var/turf/arena_center
	var/arena_radius = 7
	var/active = FALSE
	var/check_timer
	var/list/arena_walls = list()

/datum/thumb_duel/proc/start_duel()
	// Calculate midpoint, spawn walls, register COMSIG_MOB_STATCHANGE signals
	// Start arena_check_loop()

/datum/thumb_duel/proc/spawn_arena_walls()
	// RANGE_TURFS(arena_radius, arena_center), get_dist() == arena_radius
	// Spawn non-dense /obj/effect/temp_visual/duel_wall with Crossed() detection

/datum/thumb_duel/proc/arena_check_loop()
	// Refresh walls every 5 seconds, queue next check

/datum/thumb_duel/proc/on_barrier_crossed(mob/living/crosser)
	// crosser == challenger -> opponent wins, crosser == opponent -> challenger wins

/datum/thumb_duel/proc/end_duel(mob/living/winner, mob/living/loser, reason)
	// Cleanup signals + walls, heal winner 50% / loser 25%, grant_duel_rewards()

/datum/thumb_duel/proc/grant_duel_rewards(mob/living/winner, mob/living/loser)
	// Attribute growth to apprentice
	// Palermitan EXP to apprentice
	// Role-specific duel count increment
	// Association EXP to opponent if applicable
	// Check gear tier-up
```

### Duel Wall (non-dense, Crossed triggers loss)
```dm
/obj/effect/temp_visual/duel_wall
	icon = 'icons/turf/walls/hierophant_wall_temp.dmi'
	icon_state = "hierophant_wall_temp-0"
	base_icon_state = "hierophant_wall_temp"
	smoothing_flags = SMOOTH_BITMASK
	smoothing_groups = list(SMOOTH_GROUP_HIERO_WALL)
	canSmoothWith = list(SMOOTH_GROUP_HIERO_WALL)
	duration = 6 SECONDS
	density = FALSE
	color = "#c4a000"
	var/datum/thumb_duel/duel_ref

/obj/effect/temp_visual/duel_wall/Crossed(atom/movable/crossing)
	// If crossing is a duel participant, call duel_ref.on_barrier_crossed()
```

---

## Stat Growth from Duels

**Base gain:** 6 per attribute per duel (~30 duels to max at 200, assuming mixed wins/losses vs equal opponents)

**Win/Loss modifier:**
- Win: 100% of base gain
- Loss: 25% of base gain (75% less)

**Attribute difference multiplier:**
Compare the apprentice's average attributes vs the opponent's average attributes.
- `ratio = opponent_avg / apprentice_avg`
- If apprentice is weaker (ratio > 1): gain is multiplied by `ratio` (capped at 2x)
- If apprentice is stronger (ratio < 1): gain is multiplied by `ratio` (minimum 0.25x)
- If equal: 1x multiplier

**Formula:**
```
opponent_avg = (opponent FORT + PRUD + TEMP + JUST) / 4
apprentice_avg = (apprentice FORT + PRUD + TEMP + JUST) / 4
ratio = clamp(opponent_avg / apprentice_avg, 0.25, 2.0)
win_modifier = won ? 1.0 : 0.25
gain_per_attribute = round(base_gain * ratio * win_modifier)
```
Each attribute gains `gain_per_attribute`, capped at 200.

**Examples (base_gain = 6):**
| Scenario | Ratio | Win Mod | Gain per Attr |
|----------|-------|---------|---------------|
| Apprentice (40 avg) beats opponent (100 avg) | 2.0 (capped) | 1.0 | 12 |
| Apprentice (40 avg) loses to opponent (100 avg) | 2.0 (capped) | 0.25 | 3 |
| Apprentice (100 avg) beats opponent (40 avg) | 0.4 | 1.0 | 2 |
| Apprentice (100 avg) beats opponent (100 avg) | 1.0 | 1.0 | 6 |
| Apprentice (100 avg) loses to opponent (40 avg) | 0.4 | 0.25 | 1 |

**Progression pacing (vs equal opponents, ~70% win rate):**
- Avg gain/duel: ~4.6 per attribute
- Tier 2 (need 120 attrs, gain 80): ~17 duels
- Tier 3 (need 160 attrs, gain 120): ~26 duels
- Tier 4 / max (need 200 attrs, gain 160): ~35 duels

**Gear tier-up check:** After applying attribute gains, check if `(new_attributes / 2) >= next tier requirement` and call `set_tier()` on armor + both weapons if so.

---

## Palermitan EXP & Skill Points

### EXP Gain from Duels

**Base EXP:** 20 EXP per duel

**Win/Loss modifier:**
- Win: 100% of base EXP
- Loss: 25% of base EXP (75% less)

**Attribute difference multiplier (same formula as stat growth):**
```
ratio = clamp(opponent_avg / apprentice_avg, 0.25, 2.0)
win_modifier = won ? 1.0 : 0.25
exp_gained = round(base_exp * ratio * win_modifier)
```

**Examples (base_exp = 20):**
| Scenario | Ratio | Win Mod | EXP Gained |
|----------|-------|---------|------------|
| Weak apprentice (40) beats strong opponent (100) | 2.0 | 1.0 | 40 |
| Weak apprentice (40) loses to strong opponent (100) | 2.0 | 0.25 | 10 |
| Equal (100) beats equal (100) | 1.0 | 1.0 | 20 |
| Strong apprentice (100) beats weak opponent (40) | 0.4 | 1.0 | 8 |
| Strong apprentice (100) loses to weak opponent (40) | 0.4 | 0.25 | 2 |

### Skill Point Thresholds

Palermitan tree has 5 tiers with a/b choices. Maximum useful skill points = 5 (one per tier, costing 1+2+3+4+5 = 15 total points).

EXP thresholds are designed so:
- First few points come quickly (early progression feels rewarding)
- Later points require significantly more duels
- Total of **10 skill points** available (gives room to unlock all 5 tiers, with some spare for future expansion)

```
var/static/list/exp_thresholds = list(
    20,     // Skill point 1  — ~1 duel vs equal opponent
    50,     // Skill point 2  — ~2 more duels
    80,     // Skill point 3  — ~2 more duels
    120,    // Skill point 4  — ~2 more duels
    170,    // Skill point 5  — ~3 more duels (enough to fill tiers 1-2)
    220,    // Skill point 6  — ~3 more duels (enough to fill tiers 1-3)
    280,    // Skill point 7  — ~3 more duels
    350,    // Skill point 8  — ~4 more duels
    430,    // Skill point 9  — ~4 more duels
    500,    // Skill point 10 — ~4 more duels (enough to fill tiers 1-4)
)
```

**Skill point costs per tier:**
| Tier | Cost | Cumulative Points Spent | Approx. Total EXP Needed | Approx. Duels (vs equal, all wins) |
|------|------|------------------------|--------------------------|-------------------------------------|
| 1 | 1 | 1 | 20 | ~1 |
| 2 | 2 | 3 | 80 | ~4 |
| 3 | 3 | 6 | 220 | ~11 |
| 4 | 4 | 10 | 500 | ~25 |
| 5 | 5 | 15 | Need 15 points but only 10 available — **see note** |  |

**Note:** With 10 skill points max and tier 5 costing 5 points (cumulative 15 needed), the apprentice **cannot reach tier 5 with base skill points alone**. This is intentional — tier 5 mastery skills should require an additional source of skill points (e.g., bonus points from the nursefather mentor, or from completing all role-specific passives, or a quest). This gates the pinnacle behind more than just grinding duels.

Alternatively, if you want tier 5 to be reachable purely through EXP, increase the threshold list to 15 entries:
```
// Extended version (15 skill points, enough for all 5 tiers)
var/static/list/exp_thresholds = list(
    20,     // SP 1
    50,     // SP 2
    80,     // SP 3
    120,    // SP 4
    170,    // SP 5
    220,    // SP 6
    280,    // SP 7
    350,    // SP 8
    430,    // SP 9
    500,    // SP 10
    580,    // SP 11
    660,    // SP 12
    740,    // SP 13
    820,    // SP 14
    900,    // SP 15
)
```

### How EXP is Tracked
Same pattern as the Ring's `/datum/component/artistic_exp`:
- `var/exp = 0` — total accumulated EXP
- `var/skill_points = 0` — available to spend
- `var/skill_points_spent = 0` — already used
- `check_skill_points()` — called after gaining EXP, iterates thresholds to see if new points earned
- EXP never decreases — only gains, no loss on death or duel loss

---

## Restrictions / Limitations
<!-- Cooldown between duels? -->
<!-- Can they lose progress? -->
<!-- Can they duel anyone, or only certain players? -->


## Interaction with Nursefather

### 1. Sharing Drinks (EXP)
**Trigger:** Apprentice uses `give()` to offer a drink to the nursefather (or vice versa), where the drink is a `/obj/item/reagent_containers/food/drinks` that has `foodtype & ALCOHOL` or contains `/datum/reagent/consumable/ethanol`.
- **EXP gained:** 5 EXP per drink shared
- **Cooldown:** 2 minutes (`world.time` check) between EXP-granting drinks
- **Implementation:** Register `COMSIG_ITEM_OFFER_TAKEN` on the apprentice component. When fired, check:
  - Is the offered item a drink with alcohol?
  - Is the other party the nursefather (check `mind.assigned_role == "Ex Thumb Sottocapo"`)
  - Has 2 minutes passed since last drink EXP? (`world.time > last_drink_exp_time + 2 MINUTES`)

### 2. Glass Bottle Impact (EXP)
**Trigger:** Apprentice is hit by a `/obj/item/reagent_containers/food/drinks` that has `isGlass = TRUE`, either via:
- **Thrown:** Detected via `COMSIG_ATOM_HITBY` on the apprentice — check if `AM` is a glass drink and `throwingdatum.thrower` is the nursefather
- **Melee attack:** Detected via `COMSIG_MOB_APPLY_DAMGE` or `COMSIG_PARENT_ATTACKBY` — check if the item used is a glass drink and the attacker is the nursefather
- **EXP gained:** 3 EXP per impact
- **Cooldown:** 30 seconds (`world.time` check)
- **Implementation:** Register `COMSIG_ATOM_HITBY` on the apprentice mob. In handler:
  ```
  if(istype(AM, /obj/item/reagent_containers/food/drinks))
      var/obj/item/reagent_containers/food/drinks/D = AM
      if(D.isGlass && throwingdatum?.thrower is nursefather)
          grant EXP
  ```

### 3. Post-Duel Correction (Attributes + EXP)
**Trigger:** After the apprentice **loses** a duel, within 1.5 minutes, if the nursefather punches them (unarmed melee attack).

**Effect:**
- Small animation of the nursefather "disciplining" the apprentice
- Deals damage equal to a % of apprentice's **current HP** (scales with usage)
- Grants **0.25x** of the attributes they would have gained from a win (so losing + correction = 50% of win value)
- Grants **5 EXP**

**Escalating severity** (tracked via `var/correction_count` on the component, animation tier = `round(correction_count / 2) + 1`, capped at 5):
| Correction # | Animation Tier | Damage (% current HP) | Animation |
|-------------|---------------|----------------------|-----------|
| 1-2 | 1 | 5% | Light slap, apprentice flinches |
| 3-4 | 2 | 10% | Backhand, small pixel flinch |
| 5-6 | 3 | 20% | Cutscene: 2-hit combo with pixel shifting |
| 7-8 | 4 | 30% | Cutscene: 3-hit combo, knockdown |
| 9+ | 5 (capped) | 50% (capped) | Cutscene: 5-hit full beating, heavy knockdown |

**Implementation:**
- On duel loss: set `var/correction_eligible = TRUE` and `var/correction_deadline = world.time + 1.5 MINUTES` on the apprentice component. Store `var/potential_correction_attrs` (the 0.25x attribute value from the last lost duel)
- Register `COMSIG_MOB_APPLY_DAMGE` or `COMSIG_PARENT_ATTACKBY` on the apprentice
- When attacked: check if attacker is nursefather, attacker is unarmed (no held weapon or bare hands), `correction_eligible == TRUE`, and `world.time < correction_deadline`
- If valid:
  1. Set `correction_eligible = FALSE`
  2. Calculate damage: `apprentice.health * escalation_percent`
  3. Deal RED damage to apprentice
  4. Play animation (visible_message + playsound, scaling with `correction_count`)
  5. Grant `potential_correction_attrs` to all 4 attributes
  6. Grant 5 EXP
  7. Increment `correction_count`
  8. Check gear tier-up

**Animation concept:**
```dm
/// correction_count is the raw count of times used. Animation tier = clamp(round(correction_count / 2) + 1, 1, 5)
/proc/nursefather_correction(mob/living/carbon/human/nursefather, mob/living/carbon/human/apprentice, correction_count)
    // Calculate animation tier from correction count (upgrades every 2 uses)
    var/anim_tier = clamp(round(correction_count / 2) + 1, 1, 5)
    var/list/damage_percents = list(0.05, 0.10, 0.20, 0.30, 0.50)
    var/damage = apprentice.health * damage_percents[anim_tier]
    
    switch(anim_tier)
        // --- TIER 1-2: Simple hits, no lockdown ---
        if(1)
            nursefather.visible_message(
                span_warning("[nursefather] lightly slaps [apprentice]."),
                span_warning("You correct [apprentice] with a light slap."))
            playsound(apprentice, 'sound/weapons/punch1.ogg', 25)
            nursefather.do_attack_animation(apprentice)
            apprentice.deal_damage(damage, RED_DAMAGE, nursefather)
        if(2)
            nursefather.visible_message(
                span_warning("[nursefather] backhands [apprentice] across the face."),
                span_warning("You backhand [apprentice]."))
            playsound(apprentice, 'sound/weapons/punch2.ogg', 35)
            nursefather.do_attack_animation(apprentice)
            // Small pixel flinch
            animate(apprentice, pixel_x = apprentice.base_pixel_x + 4, time = 1)
            animate(pixel_x = apprentice.base_pixel_x, time = 2)
            apprentice.deal_damage(damage, RED_DAMAGE, nursefather)

        // --- TIER 3+: Cutscene lockdown with pixel-shift animations ---
        if(3)
            // Lock both in place, block outside damage
            var/combo_duration = 1.5 SECONDS
            nursefather.Immobilize(combo_duration)
            nursefather.changeNext_move(combo_duration)
            apprentice.Immobilize(combo_duration)
            apprentice.AddComponent(/datum/component/cutscene_duel, nursefather)
            nursefather.face_atom(apprentice)

            // Hit 1: Hard backhand — apprentice pixel-shifts right
            nursefather.do_attack_animation(apprentice)
            playsound(apprentice, 'sound/weapons/punch3.ogg', 45)
            animate(apprentice, pixel_x = apprentice.base_pixel_x + 8, time = 1)
            apprentice.deal_damage(damage * 0.5, RED_DAMAGE, nursefather, DAMAGE_FORCED)
            sleep(0.4 SECONDS)

            // Hit 2: Follow-up — apprentice shifts back the other way
            nursefather.do_attack_animation(apprentice)
            playsound(apprentice, 'sound/weapons/punch4.ogg', 50)
            animate(apprentice, pixel_x = apprentice.base_pixel_x - 6, time = 1)
            apprentice.deal_damage(damage * 0.5, RED_DAMAGE, nursefather, DAMAGE_FORCED)
            shake_camera(apprentice, 1, 2)
            sleep(0.4 SECONDS)

            // Return to position
            animate(apprentice, pixel_x = apprentice.base_pixel_x, pixel_y = apprentice.base_pixel_y, time = 2)
            qdel(apprentice.GetComponent(/datum/component/cutscene_duel))

            nursefather.visible_message(
                span_danger("[nursefather] strikes [apprentice] twice in quick succession."),
                span_danger("You discipline [apprentice] with two hard strikes."))

        if(4)
            // Longer cutscene — 3 hits with increasing pixel shift
            var/combo_duration = 2.5 SECONDS
            nursefather.Immobilize(combo_duration)
            nursefather.changeNext_move(combo_duration)
            apprentice.Immobilize(combo_duration)
            apprentice.AddComponent(/datum/component/cutscene_duel, nursefather)
            nursefather.face_atom(apprentice)

            // Hit 1: Body blow — apprentice bends forward (pixel_y down)
            nursefather.do_attack_animation(apprentice)
            playsound(apprentice, 'sound/weapons/punch3.ogg', 50)
            animate(apprentice, pixel_y = apprentice.base_pixel_y - 4, pixel_x = apprentice.base_pixel_x + 2, time = 1)
            apprentice.deal_damage(damage * 0.33, RED_DAMAGE, nursefather, DAMAGE_FORCED)
            sleep(0.5 SECONDS)

            // Hit 2: Uppercut — apprentice shifts up and back
            nursefather.do_attack_animation(apprentice)
            playsound(apprentice, 'sound/weapons/punch4.ogg', 55)
            animate(apprentice, pixel_y = apprentice.base_pixel_y + 6, pixel_x = apprentice.base_pixel_x - 4, time = 1)
            apprentice.deal_damage(damage * 0.33, RED_DAMAGE, nursefather, DAMAGE_FORCED)
            shake_camera(apprentice, 2, 2)
            sleep(0.5 SECONDS)

            // Hit 3: Finishing blow — apprentice slammed down
            nursefather.do_attack_animation(apprentice)
            playsound(apprentice, 'sound/weapons/punch4.ogg', 65)
            animate(apprentice, pixel_y = apprentice.base_pixel_y - 8, pixel_x = apprentice.base_pixel_x, time = 1)
            apprentice.deal_damage(damage * 0.34, RED_DAMAGE, nursefather, DAMAGE_FORCED)
            shake_camera(apprentice, 3, 3)
            apprentice.Knockdown(10)
            sleep(0.5 SECONDS)

            // Return to position
            animate(apprentice, pixel_x = apprentice.base_pixel_x, pixel_y = apprentice.base_pixel_y, time = 3)
            qdel(apprentice.GetComponent(/datum/component/cutscene_duel))

            nursefather.visible_message(
                span_danger("[nursefather] beats [apprentice] with a brutal three-hit combination."),
                span_danger("You beat some sense into [apprentice]."))

        if(5 to INFINITY)
            // Full beating — 5 hits, heavy pixel shifting, knockdown
            var/combo_duration = 4 SECONDS
            nursefather.Immobilize(combo_duration)
            nursefather.changeNext_move(combo_duration)
            apprentice.Immobilize(combo_duration)
            apprentice.AddComponent(/datum/component/cutscene_duel, nursefather)
            nursefather.face_atom(apprentice)

            var/hit_damage = damage / 5

            // Hit 1: Grab — pull apprentice toward nursefather
            playsound(apprentice, 'sound/weapons/thudswoosh.ogg', 40)
            animate(apprentice, pixel_x = apprentice.base_pixel_x + 10, time = 1)
            sleep(0.3 SECONDS)

            // Hit 2: Gut punch — apprentice bends forward
            nursefather.do_attack_animation(apprentice)
            playsound(apprentice, 'sound/weapons/punch3.ogg', 55)
            animate(apprentice, pixel_y = apprentice.base_pixel_y - 6, pixel_x = apprentice.base_pixel_x + 4, time = 1)
            apprentice.deal_damage(hit_damage, RED_DAMAGE, nursefather, DAMAGE_FORCED)
            sleep(0.4 SECONDS)

            // Hit 3: Backhand — apprentice flung to the side
            nursefather.do_attack_animation(apprentice)
            playsound(apprentice, 'sound/weapons/punch4.ogg', 60)
            animate(apprentice, pixel_x = apprentice.base_pixel_x - 10, pixel_y = apprentice.base_pixel_y, time = 1)
            apprentice.deal_damage(hit_damage, RED_DAMAGE, nursefather, DAMAGE_FORCED)
            shake_camera(apprentice, 2, 3)
            sleep(0.4 SECONDS)

            // Hit 4: Knee — apprentice forced down
            nursefather.do_attack_animation(apprentice)
            playsound(apprentice, 'sound/weapons/punch4.ogg', 65)
            animate(apprentice, pixel_y = apprentice.base_pixel_y - 10, pixel_x = apprentice.base_pixel_x - 2, time = 1)
            apprentice.deal_damage(hit_damage, RED_DAMAGE, nursefather, DAMAGE_FORCED)
            shake_camera(apprentice, 3, 3)
            sleep(0.5 SECONDS)

            // Hit 5: Final slam — heavy downward, then knockdown
            nursefather.do_attack_animation(apprentice)
            playsound(apprentice, 'sound/weapons/punch4.ogg', 75)
            animate(apprentice, pixel_y = apprentice.base_pixel_y - 14, pixel_x = apprentice.base_pixel_x, time = 1)
            apprentice.deal_damage(hit_damage * 2, RED_DAMAGE, nursefather, DAMAGE_FORCED)
            shake_camera(apprentice, 4, 4)
            apprentice.Knockdown(20)
            sleep(0.6 SECONDS)

            // Slow recovery — apprentice pixel-shifts back to normal
            animate(apprentice, pixel_x = apprentice.base_pixel_x, pixel_y = apprentice.base_pixel_y, time = 5, easing = QUAD_EASING)
            qdel(apprentice.GetComponent(/datum/component/cutscene_duel))

            nursefather.visible_message(
                span_userdanger("[nursefather] gives [apprentice] a thorough, brutal beating."),
                span_userdanger("You give [apprentice] the correction they deserve."))
```

## Other Notes
<!-- Anything else about the system -->

