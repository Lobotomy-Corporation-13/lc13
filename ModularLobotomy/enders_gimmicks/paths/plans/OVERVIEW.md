# Paths Progression System - Complete Reference

## Table of Contents
1. [Lore & Concept](#lore--concept)
2. [The Seven Paths](#the-seven-paths)
3. [Core Mechanics](#core-mechanics)
4. [Architecture Overview](#architecture-overview)
5. [File Map](#file-map)
6. [Datum Reference](#datum-reference)
7. [Ability System](#ability-system)
8. [Skill Tree (Traces)](#skill-tree-traces)
9. [Action Buttons](#action-buttons)
10. [Mob Integration (Component)](#mob-integration-component)
11. [TGUI Interface](#tgui-interface)
12. [Signal Flow](#signal-flow)
13. [Integration with LC13 Systems](#integration-with-lc13-systems)
14. [DME Includes](#dme-includes)
15. [Implementation Order](#implementation-order)
16. [Defining a New Path (Subtype Guide)](#defining-a-new-path-subtype-guide)

---

## Lore & Concept

Paths are congregations of imaginary energy, born as manifestations of universal philosophical concepts. Upon ascension, an Aeon gains power over a specific Path, free to choose the allocation of imaginary energy towards that path however THEY wish.

A person is considered to be on a Path when their will overlaps with that Path. If the person has a strong enough will, they can draw power from it, becoming a **Pathstrider**. The Path that they happen to follow will change in accordance with their own philosophies and opinions.

**Aeons** can use their designated Paths as THEY please after THEIR ascension, and are linked to it for the rest of THEIR existence. There are 7 Paths implemented in this system, each with a corresponding Aeon and gameplay role.

### Inspiration
This system is inspired by Honkai: Star Rail's Path/Traces system. Each Path gives the player:
- **4 Core Abilities**: Basic Attack effect, Burst Action, Ultimate Action, Passive Effect
- **Extra Stats**: Path-specific stats for damage/effect scaling (ATK, DEF, CRIT, etc.)
- **Skill Tree (Traces)**: Visual node graph for unlocking stat bonuses and ability upgrades

---

## The Seven Paths

### Destruction (Aeon: Nanook)
> *Reckless, wrathful, and destructive actions are manifestations of the Path of Destruction.*

**Gameplay Role:** Deals outstanding amounts of damage and possesses great survivability. Suitable for various combat scenarios.

- **Archetype:** Bruiser / All-rounder DPS
- **Strengths:** High raw damage, kill-snowball passive, flexible ultimate

#### Base Stats (by Ascension Phase & Level)

| Phase | Level | HP | ATK | DEF |
|-------|-------|----|-----|-----|
| 0 | 1 | 163 | 84 | 62 |
| 0 | 20 | 319 | 164 | 122 |
| 1 | 20 | 384 | 198 | 147 |
| 1 | 30 | 466 | 240 | 178 |
| 2 | 30 | 531 | 274 | 203 |
| 2 | 40 | 613 | 316 | 235 |
| 3 | 40 | 679 | 350 | 260 |
| 3 | 50 | 761 | 392 | 291 |
| 4 | 50 | 826 | 426 | 316 |
| 4 | 60 | 908 | 468 | 347 |
| 5 | 60 | 973 | 502 | 373 |
| 5 | 70 | 1055 | 544 | 404 |
| 6 | 70 | 1121 | 578 | 429 |
| 6 | 80 | 1203 | 620 | 460 |

**Stat Growth Notes:**
- Max ascension phase: 6 (0-6), max level: 80
- Each ascension phase raises the level cap by 10 (20 -> 30 -> 40 -> 50 -> 60 -> 70 -> 80)
- Stats at a given level = base stats interpolated between the phase floor and ceiling values

#### Abilities

**Basic ATK: Farewell Hit** | Melee Hit | Energy Generation: 20 | Physical
Deals Physical DMG equal to **50%—110%** of the USER's ATK to the target hit by the path weapon.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|-------|-----|-----|-----|-----|-----|-----|-----|
| ATK % | 50% | 60% | 70% | 80% | 90% | 100% | 110% |

**Skill: RIP Home Run** | 1-tile AoE | Energy Generation: 30 | Physical
Deals Physical DMG equal to **62.5%—137.5%** of the USER's ATK to all enemies within 1 tile of the user.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|------|------|-----|------|------|------|--------|--------|--------|------|--------|--------|
| ATK % | 62.5% | 68.75% | 75% | 81.25% | 87.5% | 93.75% | 101.56% | 109.38% | 117.19% | 125% | 131.25% | 137.5% |

**Ultimate: Stardust Ace** | Empowered Strike | Energy Cost: 120 | Physical
Choose between two attack modes to deliver a full strike.
- **Blowout: Farewell Hit** — Deals Physical DMG equal to **300%—480%** of ATK to the target in front of the user.
- **Blowout: RIP Home Run** — Deals Physical DMG equal to **180%—288%** of ATK to the target in front of the user, and Physical DMG equal to **108%—172.8%** of ATK to enemies within 1 tile of the target.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|------|------|------|------|------|------|--------|--------|--------|------|------|------|
| Blowout: FH | 300% | 315% | 330% | 345% | 360% | 375% | 393.75% | 412.5% | 431.25% | 450% | 465% | 480% |
| Blowout: RIP (main) | 180% | 189% | 198% | 207% | 216% | 225% | 236.25% | 247.5% | 258.75% | 270% | 279% | 288% |
| Blowout: RIP (adj) | 108% | 113.4% | 118.8% | 124.2% | 129.6% | 135% | 141.75% | 148.5% | 155.25% | 162% | 167.4% | 172.8% |

**Passive: Perfect Pickoff** | On Kill
Each time the user kills an enemy, ATK increases by **10%—22%** for 30 seconds. Stacks up to **2** times.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|-----|-----|-----|-----|-----|-----|-------|-------|-------|-----|-----|-----|
| ATK % buff | 10% | 11% | 12% | 13% | 14% | 15% | 16.25% | 17.5% | 18.75% | 20% | 21% | 22% |

#### Scaling Notes
- Basic ATK has **7 levels**, Skill/Ultimate/Passive have **12 levels**
- All damage uses **avg coeff** (average of all 4 damage coefficients) with **Physical** elemental type
- Ultimate empowers the next Basic ATK or Skill rather than being a standalone attack
- Ultimate costs **120 energy** and generates **0 energy**
- Basic ATK generates **20 energy**, Skill generates **30 energy**

#### Average Damage by Level (Pre-Mitigation)

Assumptions:
- **CRIT Rate**: 5% base, **CRIT DMG**: 50% base -> average crit multiplier = **1.025x**
- No passive stacks, no skill tree bonuses, no buffs (raw path damage only)
- Ability levels assumed to progress: Basic +1 per ~13 levels, Skill/Ult +1 per ~7 levels
- **DEF multiplier and avg damage_coeff NOT applied** — these are raw DMG values before mob resistances

**Assumed Ability Levels at Each Breakpoint:**
| Path Level | Basic Lv | Skill Lv | Ult Lv | Passive Lv |
|------------|----------|----------|--------|------------|
| 1 | 1 (50%) | 1 (62.5%) | 1 (300%/180%/108%) | 1 (10%) |
| 20 | 3 (70%) | 4 (81.25%) | 4 (345%/207%/124.2%) | 4 (13%) |
| 40 | 5 (90%) | 7 (101.56%) | 7 (393.75%/236.25%/141.75%) | 7 (16.25%) |
| 60 | 6 (100%) | 10 (125%) | 10 (450%/270%/162%) | 10 (20%) |
| 80 | 7 (110%) | 12 (137.5%) | 12 (480%/288%/172.8%) | 12 (22%) |

**Average Damage Per Hit (with crit avg, no passive):**
| Path Lv | ATK | Basic | Skill (per target) | Ult: Blowout FH | Ult: Blowout RIP (main) | Ult: Blowout RIP (adj) |
|---------|-----|-------|---------------------|-----------------|------------------------|----------------------|
| 1 | 84 | 43 | 54 | 258 | 155 | 93 |
| 20 | 198 | 142 | 165 | 700 | 420 | 252 |
| 40 | 316 | 291 | 329 | 1,275 | 765 | 459 |
| 60 | 468 | 480 | 600 | 2,159 | 1,295 | 777 |
| 80 | 620 | 699 | 874 | 3,050 | 1,830 | 1,098 |

**With 2 Passive Stacks (Perfect Pickoff, max level):**
At max passive (Lv12, 22% per stack, 2 stacks = +44% ATK), all damage is multiplied by **1.44x**:
| Path Lv | ATK (buffed) | Basic | Skill | Ult: Blowout FH | Ult: Blowout RIP (main) |
|---------|-------------|-------|-------|-----------------|------------------------|
| 1 | 121 | 62 | 78 | 372 | 223 |
| 20 | 285 | 205 | 237 | 1,008 | 605 |
| 40 | 455 | 420 | 473 | 1,836 | 1,102 |
| 60 | 674 | 691 | 863 | 3,109 | 1,865 |
| 80 | 893 | 1,007 | 1,258 | 4,393 | 2,636 |

#### Damage vs Mob Context

How many hits to kill common mobs (Basic ATK, no passive, avg coeff + RES applied):
- Destruction = **Physical** element, **0% RES PEN**
- Crimson ordeals are weak to Physical (0% RES), others have 20% RES
- White/Boss enemies have 40% RES to non-weak elements

**At Path Level 20 (ATK 198, Basic = 142 raw):**
| Mob | HP | Avg Coeff | Phys RES | RES Mult | Eff. DMG | Hits |
|-----|-----|-----------|----------|----------|----------|------|
| Amber Dawn | 80 | 1.50 | 20% | 0.80 | 170 | 1 |
| Green Dawn | 400 | 1.28 | 20% | 0.80 | 145 | 3 |
| Crimson Noon | 1,000 | 1.13 | 0% (weak) | 1.00 | 160 | 7 |

**At Path Level 40 (ATK 316, Basic = 291 raw):**
| Mob | HP | Avg Coeff | Phys RES | RES Mult | Eff. DMG | Hits |
|-----|-----|-----------|----------|----------|----------|------|
| Green Dawn | 400 | 1.28 | 20% | 0.80 | 298 | 2 |
| Crimson Noon | 1,000 | 1.13 | 0% (weak) | 1.00 | 329 | 4 |
| Crimson Dusk | 2,000 | 1.08 | 0% (weak) | 1.00 | 314 | 7 |
| Amber Dusk | 2,200 | 1.13 | 20% | 0.80 | 263 | 9 |

**At Path Level 60 (ATK 468, Basic = 480 raw):**
| Mob | HP | Avg Coeff | Phys RES | RES Mult | Eff. DMG | Hits |
|-----|-----|-----------|----------|----------|----------|------|
| Crimson Dusk | 2,000 | 1.08 | 0% (weak) | 1.00 | 518 | 4 |
| Amber Dusk | 2,200 | 1.13 | 20% | 0.80 | 434 | 6 |
| Black Fixer | 3,000 | 0.50 | 40% | 0.60 | 144 | 21 |
| Red Fixer | 3,000 | 0.50 | 40% | 0.60 | 144 | 21 |
| Crimson Tent | 10,000 | 0.93 | 0% (weak) | 1.00 | 446 | 23 |

**At Path Level 80 (ATK 620, Basic = 699 raw):**
| Mob | HP | Avg Coeff | Phys RES | RES Mult | Eff. DMG | Hits |
|-----|-----|-----------|----------|----------|----------|------|
| Black Fixer | 3,000 | 0.50 | 40% | 0.60 | 210 | 15 |
| Pale Fixer | 4,000 | 0.50 | 40% | 0.60 | 210 | 20 |
| Red Fixer | 3,000 | 0.50 | 40% | 0.60 | 210 | 15 |
| The Claw | 8,000 | 0.40 | 40% | 0.60 | 168 | 48 |
| Crimson Tent | 10,000 | 0.93 | 0% (weak) | 1.00 | 650 | 16 |
| Amber Midnight | 15,000 | 0.70 | 20% | 0.80 | 391 | 39 |

**Corrected Avg Coefficients** (fixed from earlier):
| Mob | Coefficients (R/W/B/P) | Avg |
|-----|------------------------|-----|
| Amber Dawn | 2/1/1/2 | 1.50 |
| Green Dawn | 0.8/1.3/2/1 | 1.28 |
| Crimson Noon | 0.6/1.2/1.2/1.5 | 1.13 |
| Crimson Dusk | 0.4/1.2/1.2/1.5 | 1.08 |
| Amber Dusk | 1.2/0.8/0.5/2 | 1.13 |
| Crimson Tent | 0.2/1/1/1.5 | 0.93 |
| Amber Midnight | 1/0.6/0.4/0.8 | 0.70 |
| All White Fixers | varies | 0.50 |
| The Claw | 0.4/0.4/0.4/0.4 | 0.40 |

**Key Takeaways:**
- Path damage has **3 defense layers**: DEF formula, Elemental RES, Avg Coeff
- Destruction (Physical) deals full damage to Crimson ordeals (weak to Physical) but takes a 20% RES penalty against others
- White/boss enemies have 40% Physical RES (0.6x multiplier) stacking with 0.50 avg coeff — very tanky (0.30x total)
- The Claw is the hardest target: 40% RES * 0.40 avg coeff = **0.24x total multiplier**
- Red Fixer is no longer immune — avg coeff averages out the 0.0 RED, and RES adds a flat 40% reduction
- A path with RES PEN (like The Hunt's Wind RES PEN) can push RES Mult above 1.0 against weak enemies, amplifying damage
- Destruction's lack of RES PEN makes it a "neutral damage" path — consistent but not exceptional against resistant targets
- Skill (RIP Home Run) is better for groups, Ultimate for single-target burst
- With 2 passive stacks, Ult FH at Lv80 = 4,393 raw — still strong boss damage before mitigations

---

### The Hunt (Aeon: Lan)
> *Decisive, ruthless, and vengeful actions are manifestations of the Path of The Hunt.*

**Gameplay Role:** Deals extraordinary amounts of single-target damage. The main damage dealer against Elite Enemies.

- **Archetype:** Single-target assassin / Boss killer
- **Strengths:** Highest single-target burst, SPD debuff on crit (slows target), conditional Ult bonus on slowed targets, RES PEN from ally support

#### Base Stats (by Ascension Phase & Level)

| Phase | Level | HP | ATK | DEF |
|-------|-------|----|-----|-----|
| 0 | 1 | 120 | 74 | 54 |
| 0 | 20 | 234 | 145 | 105 |
| 1 | 20 | 282 | 174 | 126 |
| 1 | 30 | 342 | 212 | 153 |
| 2 | 30 | 390 | 241 | 175 |
| 2 | 40 | 450 | 279 | 202 |
| 3 | 40 | 498 | 308 | 224 |
| 3 | 50 | 558 | 345 | 251 |
| 4 | 50 | 606 | 375 | 272 |
| 4 | 60 | 666 | 412 | 299 |
| 5 | 60 | 714 | 442 | 321 |
| 5 | 70 | 774 | 479 | 348 |
| 6 | 70 | 822 | 509 | 369 |
| 6 | 80 | 882 | 546 | 396 |

**Stat Comparison vs Destruction at Lv80:** ATK 546 vs 620 (-12%), DEF 396 vs 460 (-14%), HP 882 vs 1203 (-27%). The Hunt has lower raw stats but compensates with much higher ability multipliers and SPD debuff → Ult bonus combo.

#### Abilities

**Basic ATK: Cloudlancer Art: North Wind** | Melee Hit | Energy Generation: 20 | Wind
Deals Wind DMG equal to **50%—110%** of the USER's ATK to the target hit by the path weapon.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|-------|-----|-----|-----|-----|-----|-----|-----|
| ATK % | 50% | 60% | 70% | 80% | 90% | 100% | 110% |

**Skill: Cloudlancer Art: Torrent** | Melee Lunge | Energy Generation: 30 | Wind
Deals Wind DMG equal to **130%—286%** of the USER's ATK to the target in front of the user (2-tile range lunge).
When DMG dealt by Skill triggers a **CRIT Hit**, there is a **100% base chance** to apply a **SPD debuff** (slowing the target's movement by **12%**) for **20 seconds**.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|------|------|------|------|------|------|--------|--------|--------|------|------|------|
| ATK % | 130% | 143% | 156% | 169% | 182% | 195% | 211.25% | 227.5% | 243.75% | 260% | 273% | 286% |

**Ultimate: Ethereal Dream** | Targeted Strike | Energy Cost: 100 | Energy Generation: 5 | Wind
Deals Wind DMG equal to **240%—432%** of the USER's ATK to the nearest enemy within 3 tiles in the user's facing direction.
If the attacked enemy has an active **SPD debuff**, the multiplier for DMG dealt by Ultimate increases by **72%—129.6%**.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|------|------|------|------|------|------|------|------|------|------|------|------|
| Base ATK % | 240% | 256% | 272% | 288% | 304% | 320% | 340% | 360% | 380% | 400% | 416% | 432% |
| SPD-debuff bonus | 72% | 76.8% | 81.6% | 86.4% | 91.2% | 96% | 102% | 108% | 114% | 120% | 124.8% | 129.6% |

*With SPD-debuff active on target, Ultimate multiplier = Base + Bonus (e.g. Lv1: 240% + 72% = 312%, Lv12: 432% + 129.6% = 561.6%)*

**Passive: Superiority of Reach** | On Ally Buff
When an ally uses a supportive ability on the user, their next attack's **Wind RES PEN** increases by **18%—39.6%**. This effect can be triggered again after **20 seconds**.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|-----|------|------|------|------|-----|-------|-------|-------|-----|------|------|
| RES PEN | 18% | 19.8% | 21.6% | 23.4% | 25.2% | 27% | 29.25% | 31.5% | 33.75% | 36% | 37.8% | 39.6% |

#### Scaling Notes
- Basic ATK has **7 levels**, Skill/Ultimate/Passive have **12 levels**
- All damage uses **avg coeff** (average of all 4 damage coefficients) with **Wind** elemental type
- Skill's **SPD debuff** only triggers on **CRIT hits** — CRIT Rate is essential for this path
- Ultimate has a huge conditional bonus when target is **SPD-debuffed** (Skill crit -> Ult combo)
- Passive introduces **Wind RES PEN** — reduces enemy's Wind resistance (elemental layer, not LC13 avg coeff)
- Ultimate generates **5 energy** (unlike Destruction's 0), giving slight energy cycling
- Energy cost is **100** (vs Destruction's 120), so Ult charges faster
- SPD debuff slows movement on regular mobs/carbons, slows turn cycle on path holders

#### Gameplay Loop
```
1. Ally buffs the Hunt user -> Passive triggers (Wind RES PEN on next attack, 20s cooldown)
2. Use Skill (Cloudlancer Art: Torrent) on boss — lunge 2 tiles
   -> If CRIT: applies 12% SPD debuff (movement slow) for 20 seconds
   -> RES PEN from Passive applied on this hit
3. Build to 100 energy via Basic ATK (20) + Skill (30) hits
4. Use Ultimate (Ethereal Dream) on SPD-debuffed boss
   -> Base 432% + 129.6% bonus = 561.6% ATK at max level
   -> Massively amplified focused strike on slowed target
5. Repeat: Skill to maintain SPD debuff, Ult when ready
```

#### Key Differences from Destruction
| Aspect | Destruction | The Hunt |
|--------|-------------|---------|
| Element Type | Physical | Wind |
| Target Profile | Flexible (AoE Skill, focused Ult) | Pure focused-target specialist |
| Skill Scaling | 62.5%—137.5% (1-tile AoE) | 130%—286% (2-tile lunge, 2x+ higher) |
| Ult Scaling | 300%—480% (Empowered strike) | 240%—432% base, up to 561.6% conditional |
| Ult Energy Cost | 120 | 100 |
| Ult Energy Gen | 0 | 5 |
| Passive | Kill-stacking ATK buff (self-reliant) | Ally-dependent Wind RES PEN (team synergy) |
| SPD Interaction | None | Skill crits apply SPD debuff, Ult punishes slowed targets |
| Best Against | Groups, Physical-weak mobs | Bosses, Wind-weak mobs |

---

### Erudition (Aeon: Nous)
> *Thoughtful, logical, and strategic actions are manifestations of the Path of Erudition.*

**Gameplay Role:** Deals remarkable amounts of multi-target damage. The main damage dealer against groups of enemies.

- **Archetype:** AoE specialist / Execute finisher
- **Strengths:** Area damage on every ability, execute mechanic on low-HP enemies, triggered bonus hit on HP threshold, self-ATK buff from Ultimate
- **Element:** Ice

#### Base Stats (by Ascension Phase & Level)

| Phase | Level | HP | ATK | DEF |
|-------|-------|----|-----|-----|
| 0 | 1 | 129 | 79 | 54 |
| 0 | 20 | 252 | 154 | 105 |
| 1 | 20 | 304 | 186 | 126 |
| 1 | 30 | 369 | 225 | 153 |
| 2 | 30 | 421 | 257 | 175 |
| 2 | 40 | 486 | 297 | 202 |
| 3 | 40 | 537 | 328 | 224 |
| 3 | 50 | 602 | 368 | 251 |
| 4 | 50 | 654 | 399 | 272 |
| 4 | 60 | 719 | 439 | 299 |
| 5 | 60 | 771 | 471 | 321 |
| 5 | 70 | 835 | 510 | 348 |
| 6 | 70 | 887 | 542 | 369 |
| 6 | 80 | 952 | 582 | 396 |

**Stat Comparison at Lv80:**
| Path | HP | ATK | DEF |
|------|----|-----|-----|
| Destruction | 1,203 | 620 | 460 |
| The Hunt | 882 | 546 | 396 |
| Erudition | 952 | 582 | 396 |

Erudition has moderate stats — higher ATK than Hunt but lower than Destruction. DEF matches Hunt. HP sits between the two. Compensated by area damage on every ability and execute/triggered bonus mechanics.

#### Abilities

**Basic ATK: What Are You Looking At?** | Melee Hit | Energy Generation: 20 | Ice
Deals Ice DMG equal to **50%—110%** of USER's ATK to the target hit by the path weapon. If the enemy's HP is at **50% or less**, deals additional Ice DMG equal to **40%** of USER's ATK. This bonus also triggers if the Basic ATK causes the enemy's HP to fall to 50% or lower.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|-------|-----|-----|-----|-----|-----|-----|-----|
| ATK % | 50% | 60% | 70% | 80% | 90% | 100% | 110% |
| Execute bonus | 40% | 40% | 40% | 40% | 40% | 40% | 40% |

*Execute bonus is flat 40% ATK at all levels. Effective scaling when triggered: 90%—150% ATK.*

**Skill: One-Time Offer** | 3-tile AoE | Energy Generation: 30 | Ice
Deals Ice DMG equal to **50%—110%** of USER's ATK to all enemies within 3 tiles of the user. If the enemy's HP is at **50% or higher**, DMG dealt to that target increases by **25%**.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|-----|-----|-----|------|------|------|--------|--------|--------|------|------|------|
| ATK % | 50% | 55% | 60% | 65% | 70% | 75% | 81.25% | 87.5% | 93.75% | 100% | 105% | 110% |

*With 25% high-HP bonus active: 62.5%—137.5% effective.*

**Ultimate: It's Magic, I Added Some Magic** | 5-tile AoE | Energy Cost: 110 | Energy Generation: 5 | Ice
Deals Ice DMG equal to **120%—216%** of USER's ATK to all enemies within 5 tiles of the user. After using the Ultimate, increases USER's ATK by **25%** for 10 seconds.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|------|------|------|------|------|------|------|------|------|------|------|------|
| ATK % | 120% | 128% | 136% | 144% | 152% | 160% | 170% | 180% | 190% | 200% | 208% | 216% |

*ATK buff (25%) applies after the Ultimate's damage, boosting subsequent attacks for 10 seconds.*

**Passive: Fine, I'll Do It Myself** | On HP Threshold | Energy Generation: 5
When **any ally's or the user's** attack causes an enemy's HP to fall to **50% or lower**, USER launches a triggered bonus hit dealing Ice DMG equal to **25%—43%** of USER's ATK to all enemies within 3 tiles of the user.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|-----|------|-----|------|-----|------|--------|--------|--------|-----|------|-----|
| ATK % | 25% | 26.5% | 28% | 29.5% | 31% | 32.5% | 34.375% | 36.25% | 38.125% | 40% | 41.5% | 43% |

*Triggers on ANY ally hitting the HP threshold within 7 tiles, not just the user. Bonus hit damages enemies within 3 tiles of the user. Generates 5 energy per trigger.*

#### Scaling Notes
- Basic ATK has **7 levels**, Skill/Ultimate/Passive have **12 levels**
- All damage uses **avg coeff** (average of all 4 damage coefficients) with **Ice** elemental type
- Basic ATK has a built-in **execute mechanic** — flat +40% ATK bonus damage when target is at or drops to ≤50% HP
- Skill has the **opposite** conditional — +25% DMG when target is ≥50% HP (anti-synergy with Basic, encourages alternating)
- Passive triggers off **any ally's** attacks within 7 tiles, not just the user's — scales with team size and nearby allies
- Passive bonus hit is a 3-tile AoE around the user — powerful in multi-target fights
- Ultimate costs **110 energy** (highest so far: Destruction 120, Hunt 100)
- Ultimate generates **5 energy** and grants a **25% ATK self-buff** for 10 seconds after use
- No RES PEN in kit — relies on raw area damage volume and execute damage

#### Gameplay Loop
```
1. Open with Skill (One-Time Offer) in a group of enemies
   -> 50%-110% ATK to all enemies within 3 tiles
   -> +25% bonus since enemies are above 50% HP
   -> Effective: 62.5%-137.5% ATK to nearby enemies
2. Basic ATK weaker enemies to push them below 50% HP
   -> Execute bonus: +40% ATK on targets at/below 50%
   -> Each threshold cross triggers Passive bonus hit
3. Passive (Fine, I'll Do It Myself) auto-triggers:
   -> 25%-43% ATK to all enemies within 3 tiles per trigger
   -> Can chain: if bonus hit pushes another enemy to 50%,
      does NOT re-trigger (prevents infinite loops)
4. Build to 110 energy via Basic (20) + Skill (30) + Passive (5)
5. Ultimate (It's Magic) — 5-tile AoE nuke
   -> 120%-216% ATK to all nearby enemies
   -> Grants 25% ATK buff for 10 seconds
   -> Subsequent attacks during buff window are boosted
6. Repeat: Skill (high HP enemies) -> Basic (low HP) -> Ult
```

#### Key Differences from Other Paths
| Aspect | Destruction | The Hunt | Erudition |
|--------|-------------|----------|-----------|
| Element | Physical | Wind | Ice |
| Target Profile | Flexible | Focused-target | Area specialist |
| Basic ATK | 50-110% melee hit | 50-110% melee hit | 50-110% melee hit + 40% execute |
| Skill | 62.5-137.5% (1-tile AoE) | 130-286% (2-tile lunge) | 50-110% (3-tile AoE) |
| Ult Scaling | 300-480% (Empowered strike) | 240-432% (+129.6% conditional) | 120-216% (5-tile AoE) |
| Ult Energy Cost | 120 | 100 | 110 |
| Ult Energy Gen | 0 | 5 | 5 |
| Passive | Kill-stacking ATK | Ally-triggered RES PEN | HP-threshold AoE bonus hit |
| Unique Mechanic | Empowered next attack | SPD debuff on crit, Ult bonus on slowed | Execute + anti-execute conditionals |
| Best Against | Groups + Physical-weak | Bosses + Wind-weak | Large groups + Ice-weak |

---

### Harmony (Aeon: Xipe)
> *Understanding, supportive, and cooperative actions are manifestations of the Path of Harmony.*

**Gameplay Role:** Applies buffs to allies to improve the team's combat capacities.

- **Archetype:** Buffer / Force multiplier
- **Strengths:** Empowering a designated ally, ATK boost + bonus Lightning DMG on ally attacks, energy battery for allies, DMG amplification via Ultimate
- **Element:** Lightning

#### Base Stats (by Ascension Phase & Level)

| Phase | Level | HP | ATK | DEF | SPD |
|-------|-------|----|-----|-----|-----|
| 0 | 1 | 115 | 72 | 54 | 112 |
| 0 | 20 | 224 | 140 | 105 | 112 |
| 1 | 20 | 270 | 169 | 126 | 112 |
| 1 | 30 | 328 | 205 | 153 | 112 |
| 2 | 30 | 374 | 234 | 175 | 112 |
| 2 | 40 | 432 | 270 | 202 | 112 |
| 3 | 40 | 478 | 298 | 224 | 112 |
| 3 | 50 | 535 | 334 | 251 | 112 |
| 4 | 50 | 581 | 363 | 272 | 112 |
| 4 | 60 | 639 | 399 | 299 | 112 |
| 5 | 60 | 685 | 428 | 321 | 112 |
| 5 | 70 | 743 | 464 | 348 | 112 |
| 6 | 70 | 789 | 493 | 369 | 112 |
| 6 | 80 | 846 | 529 | 396 | 112 |

**Stat Comparison at Lv80:**
| Path | HP | ATK | DEF | SPD |
|------|----|-----|-----|-----|
| Destruction | 1,203 | 620 | 460 | 100 |
| The Hunt | 882 | 546 | 396 | 100 |
| Erudition | 952 | 582 | 396 | 100 |
| Harmony | 846 | 529 | 396 | 112 |

Harmony has the lowest HP and ATK of all paths but the highest base SPD (112), giving faster turn cycling (4.46s turns vs 5s). This supports its role as a buffer — more turns = more Skill uses to maintain Benediction uptime.

#### Abilities

**Basic ATK: Dislodged** | Melee Hit | Energy Generation: 20 | Lightning
Deals Lightning DMG equal to **50%—110%** of the USER's ATK to the target hit by the path weapon.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|-------|-----|-----|-----|-----|-----|-----|-----|
| ATK % | 50% | 60% | 70% | 80% | 90% | 100% | 110% |

**Skill: Soothing Melody** | Ally Buff | Energy Generation: 30 | Lightning
Grants the nearest designated ally within 7 tiles the **Benediction** buff:
- Increases the ally's ATK by **25%—55%**, capped at **15%—27%** of USER's current ATK.
- When the Benediction'd ally next attacks, they deal bonus Lightning DMG equal to **20%—44%** of that ally's ATK (1 time, consumed on attack).
- Benediction lasts for **30 seconds** (3 turns) and only applies to the most recent Skill target (reapplying moves it).

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|-----|------|-----|------|-----|------|--------|--------|--------|-----|------|-----|
| ATK buff % | 25% | 27.5% | 30% | 32.5% | 35% | 37.5% | 40.63% | 43.75% | 46.88% | 50% | 52.5% | 55% |
| ATK cap (% of USER ATK) | 15% | 16% | 17% | 18% | 19% | 20% | 21.25% | 22.5% | 23.75% | 25% | 26% | 27% |
| Bonus Lightning DMG (% ally ATK) | 20% | 22% | 24% | 26% | 28% | 30% | 32.5% | 35% | 37.5% | 40% | 42% | 44% |

**Ultimate: Amidst the Rejoicing Clouds** | Ally Empower | Energy Cost: 130 | Energy Generation: 5 | Lightning
Regenerates **50 Energy** for the nearest designated ally within 7 tiles (who has a path) and increases that ally's DMG by **20%—56%** for **20 seconds** (2 turns).

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|-----|-----|-----|-----|-----|-----|--------|--------|--------|-----|-----|-----|
| DMG buff % | 20% | 23% | 26% | 29% | 32% | 35% | 38.75% | 42.5% | 46.25% | 50% | 53% | 56% |

*Energy restore only works on allies who have the path system (they have an energy meter). DMG buff works on any designated ally.*

**Passive: Violet Sparknado** | On User Attack | Lightning
When the USER attacks an enemy, the ally with **Benediction** immediately deals bonus Lightning DMG equal to **30%—66%** of that ally's ATK to the same enemy. Triggers on every hit by the USER (not gated by turns).

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|-----|------|-----|------|-----|------|--------|--------|--------|-----|------|-----|
| Bonus DMG (% ally ATK) | 30% | 33% | 36% | 39% | 42% | 45% | 48.75% | 52.5% | 56.25% | 60% | 63% | 66% |

*This is separate from Benediction's one-time attack bonus. The Passive triggers every time the USER hits, while Benediction's bonus triggers when the ALLY attacks.*

#### Scaling Notes
- Basic ATK has **7 levels**, Skill/Ultimate/Passive have **12 levels**
- All damage uses **avg coeff** with **Lightning** elemental type
- Harmony is a **pure support** path — personal damage is low, but ally empowerment is massive
- Skill's ATK buff has a **cap** based on USER's ATK — prevents abuse with low-ATK Harmony users buffing high-ATK allies beyond reason
- Benediction only exists on **one ally at a time** — reapplying the Skill moves it to the new target
- Passive (Violet Sparknado) triggers on **every USER hit**, not per turn — faster weapons = more Passive procs
- Ultimate costs **130 energy** (highest of all paths) but gives **50 energy to an ally** — functions as an energy battery
- Ultimate's DMG buff stacks with Benediction's ATK buff for massive ally burst windows
- SPD 112 (base) gives 4.46s turns — more turns means more Skill uses to refresh Benediction and build energy

#### Gameplay Loop
```
1. Designate your primary DPS ally via the Designate Ally action
2. Use Skill (Soothing Melody) to apply Benediction to your DPS ally
   -> Ally gains 25%-55% ATK buff (capped by your ATK)
   -> Ally's next attack deals 20%-44% bonus Lightning DMG
3. Attack enemies with Basic ATK
   -> Each hit triggers Passive: Benediction'd ally deals 30%-66%
      of their ATK as Lightning DMG to the same target
   -> First hit per turn grants you 1 AP + energy
4. Alternate attack turns and Skill turns to maintain Benediction
   -> Benediction lasts 30s, Skill costs 1 AP + turn
5. Build to 130 energy, then Ultimate on your DPS ally
   -> Ally gets 50 energy (accelerates THEIR Ultimate)
   -> Ally gets 20%-56% DMG buff for 20 seconds
   -> During this window, ally has ATK buff + DMG buff = massive burst
6. Repeat: maintain Benediction, battery ally with Ult
```

#### Key Differences from Other Paths
| Aspect | Destruction | The Hunt | Erudition | Harmony |
|--------|-------------|----------|-----------|---------|
| Element | Physical | Wind | Ice | Lightning |
| Role | DPS | Focused DPS | AoE DPS | Buffer |
| Basic ATK | 50-110% melee | 50-110% melee | 50-110% + execute | 50-110% + Passive proc |
| Skill | 1-tile AoE | 2-tile lunge | 3-tile AoE | Ally Benediction buff |
| Ult | Empowered strike | Conditional nuke | 5-tile AoE | Ally energy + DMG buff |
| Ult Energy | 120 | 100 | 110 | 130 |
| Passive | Kill ATK stacking | Ally RES PEN | HP-threshold AoE | Ally bonus Lightning DMG |
| Best Against | Groups | Bosses | Large groups | Empowering a carry ally |

---

### Nihility (Aeon: IX)
> *Slothful, exhausted, and meaningless actions are manifestations of the Path of Nihility.*

**Gameplay Role:** Applies debuffs to enemies to reduce their combat capacities.

- **Archetype:** Debuffer / DoT specialist / Damage amplifier
- **Strengths:** Burn DoT application, Burn detonation via Ultimate, stacking damage vulnerability (Firekiss), strong AoE through DoT spread
- **Element:** Fire

#### Base Stats (by Ascension Phase & Level)

| Phase | Level | HP | ATK | DEF | SPD |
|-------|-------|----|-----|-----|-----|
| 0 | 1 | 120 | 79 | 60 | 106 |
| 0 | 20 | 234 | 154 | 117 | 106 |
| 1 | 20 | 282 | 186 | 141 | 106 |
| 1 | 30 | 342 | 225 | 171 | 106 |
| 2 | 30 | 390 | 257 | 195 | 106 |
| 2 | 40 | 450 | 297 | 225 | 106 |
| 3 | 40 | 498 | 328 | 249 | 106 |
| 3 | 50 | 558 | 368 | 279 | 106 |
| 4 | 50 | 606 | 399 | 303 | 106 |
| 4 | 60 | 666 | 439 | 333 | 106 |
| 5 | 60 | 714 | 471 | 357 | 106 |
| 5 | 70 | 774 | 510 | 387 | 106 |
| 6 | 70 | 822 | 542 | 411 | 106 |
| 6 | 80 | 882 | 582 | 441 | 106 |

**Stat Comparison at Lv80:**
| Path | HP | ATK | DEF | SPD |
|------|----|-----|-----|-----|
| Destruction | 1,203 | 620 | 460 | 100 |
| The Hunt | 882 | 546 | 396 | 100 |
| Erudition | 952 | 582 | 396 | 100 |
| Harmony | 846 | 529 | 396 | 112 |
| Nihility | 882 | 582 | 441 | 106 |

Nihility has the highest DEF of all paths (441) and moderate ATK matching Erudition. SPD 106 gives slightly faster turns (4.72s). Compensated by powerful DoT and damage amplification rather than raw burst.

#### Abilities

**Basic ATK: Standing Ovation** | Melee Hit | Energy Generation: 20 | Fire
Deals Fire DMG equal to **50%—110%** of USER's ATK to the target hit by the path weapon.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|-------|-----|-----|-----|-----|-----|-----|-----|
| ATK % | 50% | 60% | 70% | 80% | 90% | 100% | 110% |

**Skill: Blazing Welcome** | 1-tile AoE | Energy Generation: 30 | Fire
Deals Fire DMG equal to **60%—132%** of USER's ATK to the target in front of the user, and Fire DMG equal to **20%—44%** of USER's ATK to enemies within 1 tile of the target. Has a **100% base chance** to apply **Burn** to the primary target and all hit enemies.
When Burned, enemies take a Fire DoT equal to **83.9%—240%** of USER's ATK per tick, lasting **20 seconds** (2 turns).

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|------|------|------|------|------|------|--------|--------|--------|------|--------|--------|
| Main ATK % | 60% | 66% | 72% | 78% | 84% | 90% | 97.5% | 105% | 112.5% | 120% | 126% | 132% |
| Adjacent ATK % | 20% | 22% | 24% | 26% | 28% | 30% | 32.5% | 35% | 37.5% | 40% | 42% | 44% |
| Burn DoT % | 83.9% | 92.3% | 100.7% | 109.1% | 117.5% | 130.1% | 146.9% | 167.8% | 193% | 218.2% | 229.1% | 240% |

*Note: This Skill's Burn DoT is much stronger than the standard Burn DoT (100% ATK). It uses a custom scaling that increases sharply at higher levels.*

**Ultimate: Watch This Showstopper** | 3-tile AoE | Energy Cost: 120 | Energy Generation: 5 | Fire
Deals Fire DMG equal to **72%—129.6%** of USER's ATK to all enemies within 3 tiles. If a hit enemy is currently **Burned**, their Burn DoT immediately ticks, dealing **72%—96%** of the Burn's original damage as instant DMG.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|------|------|------|------|------|------|------|------|------|------|--------|--------|
| AoE ATK % | 72% | 76.8% | 81.6% | 86.4% | 91.2% | 96% | 102% | 108% | 114% | 120% | 124.8% | 129.6% |
| Burn detonate % | 72% | 74% | 76% | 78% | 80% | 82% | 84.5% | 87% | 89.5% | 92% | 94% | 96% |

*Burn detonation: triggers an instant partial tick of the target's active Burn, dealing (Burn base DMG * detonate%). This does NOT remove the Burn — it continues ticking normally.*

**Passive: PatrAeon Benefits** | On Burn Tick | Fire
When USER is alive, there is a **100% base chance** to apply **Firekiss** to an enemy after their Burn DoT deals damage. While inflicted with Firekiss, the enemy receives **4%—7.6% increased DMG** from all sources. Firekiss lasts **30 seconds** (3 turns) and can stack up to **3 times**.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|-----|------|------|------|------|------|--------|--------|--------|-----|------|------|
| DMG increase % | 4% | 4.3% | 4.6% | 4.9% | 5.2% | 5.5% | 5.875% | 6.25% | 6.625% | 7% | 7.3% | 7.6% |

*At max stacks (3x Lv12): 22.8% increased DMG taken. This benefits ALL damage sources — path damage, DoT ticks, ally attacks, even normal EGO weapon damage. Firekiss is a `/datum/status_effect` on the target that modifies incoming damage.*

#### Scaling Notes
- Basic ATK has **7 levels**, Skill/Ultimate/Passive have **12 levels**
- All damage uses **avg coeff** with **Fire** elemental type
- Nihility is a **DoT-focused debuffer** — personal burst is moderate but sustained damage through Burn is very high
- Skill applies a **custom Burn** with much higher scaling than the standard Burn DoT (240% ATK vs 100% ATK at max level)
- Ultimate **detonates** existing Burns for instant burst — the combo is Skill (apply Burn) → Ultimate (detonate + AoE)
- Passive (Firekiss) makes Burn a team-wide DPS amplifier — after Burn ticks, the enemy takes more damage from ALL sources
- Firekiss stacks multiplicatively with other damage bonuses
- Ultimate costs **120 energy** (same as Destruction) and generates **5 energy**
- SPD 106 gives 4.72s turns — slightly faster than base 100 but slower than Harmony's 112

#### Gameplay Loop
```
1. Use Skill (Blazing Welcome) on enemy group
   -> Deals Fire DMG to main target + 1-tile AoE
   -> 100% chance to apply Burn to all hit enemies
   -> Burn deals 83.9%-240% ATK per tick for 20 seconds
2. Attack Burned enemies with Basic ATK
   -> Each hit deals Fire DMG normally
   -> Burn ticks trigger Passive: applies Firekiss (DMG vulnerability)
   -> Firekiss stacks up to 3x on each Burned enemy
3. Continue attacking — Firekiss amplifies ALL damage on Burned targets
   -> Allies also deal more damage to Firekiss'd enemies
4. Build to 120 energy, then Ultimate (Watch This Showstopper)
   -> 3-tile AoE Fire DMG to all enemies
   -> All Burned enemies get their Burn detonated for 72%-96% extra
   -> Massive burst when many enemies are Burned simultaneously
5. Reapply Burn with Skill, maintain Firekiss stacks
```

#### Key Differences from Other Paths
| Aspect | Destruction | The Hunt | Erudition | Harmony | Nihility |
|--------|-------------|----------|-----------|---------|----------|
| Element | Physical | Wind | Ice | Lightning | Fire |
| Role | DPS | Focused DPS | AoE DPS | Buffer | Debuffer/DoT |
| Basic ATK | 50-110% | 50-110% | 50-110% + execute | 50-110% + Passive | 50-110% |
| Skill | 1-tile AoE | 2-tile lunge | 3-tile AoE | Ally buff | 1-tile AoE + Burn |
| Ult | Empowered strike | Conditional nuke | 5-tile AoE | Ally energy/DMG | 3-tile AoE + Burn detonate |
| Ult Energy | 120 | 100 | 110 | 130 | 120 |
| Passive | Kill ATK stacking | Ally RES PEN | HP-threshold AoE | Ally Lightning DMG | Firekiss (DMG vulnerability) |
| Unique Mechanic | Empowered next attack | SPD debuff + conditional Ult | Execute conditionals | Benediction | Burn DoT + detonate + Firekiss |
| Best Against | Groups | Bosses | Large groups | Carry ally | Sustained fights, tanky enemies |

---

### Preservation (Aeon: Qlipoth)
> *Patient, sacrificial, and protective actions are manifestations of the Path of Preservation.*

**Gameplay Role:** Possesses powerful defensive abilities to protect allies in various ways.

- **Archetype:** Tank / Shielder / Aggro magnet
- **Strengths:** Highest HP and DEF, Magma Will stacking for enhanced attacks, team shielding on every action, taunt to draw aggro, DEF-scaling Ultimate
- **Element:** Fire

#### Base Stats (by Ascension Phase & Level)

| Phase | Level | HP | ATK | DEF | SPD |
|-------|-------|----|-----|-----|-----|
| 0 | 1 | 168 | 81 | 82 | 95 |
| 0 | 20 | 329 | 159 | 160 | 95 |
| 1 | 20 | 397 | 192 | 193 | 95 |
| 1 | 30 | 481 | 233 | 235 | 95 |
| 2 | 30 | 549 | 265 | 268 | 95 |
| 2 | 40 | 633 | 306 | 309 | 95 |
| 3 | 40 | 701 | 339 | 342 | 95 |
| 3 | 50 | 785 | 380 | 383 | 95 |
| 4 | 50 | 853 | 413 | 416 | 95 |
| 4 | 60 | 937 | 454 | 457 | 95 |
| 5 | 60 | 1,005 | 486 | 490 | 95 |
| 5 | 70 | 1,089 | 527 | 532 | 95 |
| 6 | 70 | 1,157 | 560 | 565 | 95 |
| 6 | 80 | 1,241 | 601 | 606 | 95 |

**Stat Comparison at Lv80:**
| Path | HP | ATK | DEF | SPD |
|------|----|-----|-----|-----|
| Destruction | 1,203 | 620 | 460 | 100 |
| The Hunt | 882 | 546 | 396 | 100 |
| Erudition | 952 | 582 | 396 | 100 |
| Harmony | 846 | 529 | 396 | 112 |
| Nihility | 882 | 582 | 441 | 106 |
| Preservation | 1,241 | 601 | 606 | 95 |

Preservation has the **highest HP** (1,241) and **highest DEF** (606) of all paths, but the **lowest SPD** (95 = 5.26s turns). ATK is moderate (601). This path is built to absorb damage and protect allies, not deal it — though the DEF-scaling Ultimate and enhanced Basic ATK provide meaningful damage output.

#### Abilities

**Basic ATK: Ice-Breaking Light** | Melee Hit | Energy Generation: 20 | Fire
Deals Fire DMG equal to **50%—110%** of USER's ATK to the target hit by the path weapon. Gains **1 stack of Magma Will**.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|-------|-----|-----|-----|-----|-----|-----|-----|
| ATK % | 50% | 60% | 70% | 80% | 90% | 100% | 110% |

**Enhanced Basic ATK: Ice-Breaking Light** | 1-tile AoE | Energy Generation: 30 | Fire
When the USER has **4+ stacks of Magma Will**, their Basic ATK becomes enhanced. Consumes 4 stacks to deal Fire DMG equal to **90%—146.25%** of USER's ATK to the primary target, and Fire DMG equal to **36%—58.5%** of USER's ATK to enemies within 1 tile of the target.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|-------|-----|------|------|------|------|------|--------|
| Main ATK % | 90% | 99% | 108% | 117% | 126% | 135% | 146.25% |
| Adjacent ATK % | 36% | 39.6% | 43.2% | 46.8% | 50.4% | 54% | 58.5% |

*The enhanced attack generates 30 energy instead of 20. The weapon automatically uses the enhanced version when at 4+ stacks.*

**Skill: Ever-Burning Amber** | Self Buff | Energy Generation: 30 | Fire
Increases the USER's **DMG Reduction by 40%—52%** for 10 seconds (1 turn) and gains **1 stack of Magma Will**. Has a **100% base chance** to **Taunt** all enemies within 5 tiles for 10 seconds (1 turn), forcing them to target the USER.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|-----|-----|-----|-----|-----|-----|--------|--------|--------|-----|-----|-----|
| DMG Reduction % | 40% | 41% | 42% | 43% | 44% | 45% | 46.25% | 47.5% | 48.75% | 50% | 51% | 52% |

*Taunt on simple mobs: sets their `target_mob` to the USER, forcing them to walk toward and attack the USER. On path holders/carbons: no forced targeting (PvP aggro not forced).*

**Ultimate: War-Flaming Lance** | 3-tile AoE | Energy Cost: 120 | Energy Generation: 5 | Fire
Deals Fire DMG equal to **50%—110%** of USER's ATK **plus 75%—165%** of USER's DEF to all enemies within 3 tiles. The next Basic ATK is automatically enhanced and does **not** consume Magma Will stacks.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|-----|------|------|------|------|------|--------|--------|--------|------|--------|--------|
| ATK % | 50% | 55% | 60% | 65% | 70% | 75% | 81.25% | 87.5% | 93.75% | 100% | 105% | 110% |
| DEF % | 75% | 82.5% | 90% | 97.5% | 105% | 112.5% | 121.88% | 131.25% | 140.63% | 150% | 157.5% | 165% |

*At Lv80 with 606 DEF and 601 ATK: Ult deals (601 * 1.10) + (606 * 1.65) = 661 + 1000 = **1,661 base DMG** per enemy. The DEF scaling makes this path's Ultimate hit surprisingly hard.*

**Passive: Magma Will & Shield** | On Action | Fire
The USER has a persistent **Magma Will** resource (0 to 8 stacks max):
- **Gaining stacks:** +1 per normal Basic ATK hit (first hit per attack turn only), +1 per Skill use, +1 per time the USER is hit by an enemy.
- **Spending stacks:** Enhanced Basic ATK consumes 4 stacks (unless the free enhanced attack from Ultimate is active).
- **At 4+ stacks:** Basic ATK automatically becomes the enhanced 1-tile AoE version.

**Team Shield:** Every time the USER uses a Basic ATK, Skill, or Ultimate, a Shield is applied to all **designated allies within 5 tiles** that absorbs DMG equal to **4%—6.4%** of the USER's DEF plus a flat **20—89**. The Shield lasts for **20 seconds** (2 turns).

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|-----|------|------|------|------|------|--------|--------|--------|------|------|------|
| Shield DEF % | 4% | 4.2% | 4.4% | 4.6% | 4.8% | 5% | 5.25% | 5.5% | 5.75% | 6% | 6.2% | 6.4% |
| Shield flat | 20 | 26 | 32 | 38 | 44 | 50 | 57.5 | 65 | 72.5 | 80 | 84.5 | 89 |

*At Lv80 with 606 DEF, Lv12 Passive: Shield = (606 * 0.064) + 89 = 38.8 + 89 = **~128 DMG absorbed** per action. This adds up quickly since the USER generates shields on every Basic ATK, Skill, and Ultimate.*

#### Scaling Notes
- Basic ATK has **7 levels**, Skill/Ultimate/Passive have **12 levels**
- All damage uses **avg coeff** with **Fire** elemental type
- Preservation is a **tank/protector** — low SPD (95 = 5.26s turns) but massive HP/DEF
- **Magma Will** is a unique resource: gained from attacking, using Skill, and being hit. At 4+ stacks, Basic ATK upgrades to enhanced AoE
- **Being hit = Magma Will stacks** — this means tanking damage is rewarded, synergizing with the Taunt from Skill
- Ultimate **scales off DEF** (75%-165% DEF), making DEF double as an offensive AND defensive stat
- Ultimate grants a **free enhanced Basic ATK** that doesn't consume stacks — guaranteed burst follow-up
- **Team Shield** on every action creates persistent damage absorption for allies, scaling with DEF
- SPD 95 is the **slowest** of all paths — fewer turns, but each turn is impactful (shield refresh, Magma Will)

#### Gameplay Loop
```
1. Use Skill (Ever-Burning Amber) to Taunt enemies within 5 tiles
   -> Gain 40%-52% DMG Reduction for 10 seconds
   -> Gain 1 Magma Will stack
   -> All nearby enemies forced to attack you
   -> Shield applied to all allies (DEF-based)
2. Tank enemy hits — each hit grants +1 Magma Will
   -> With Taunt active, enemies swarm you
   -> Rapidly build to 4+ stacks
3. At 4+ Magma Will, Basic ATK upgrades to enhanced AoE
   -> Deals 90%-146.25% ATK to main + 36%-58.5% to adjacent
   -> Consumes 4 stacks, gains 30 energy
   -> Shield refreshed for all allies
4. Continue tanking + attacking to rebuild stacks
5. Build to 120 energy, then Ultimate (War-Flaming Lance)
   -> 3-tile AoE dealing ATK% + DEF% (massive with high DEF)
   -> Next Basic ATK is auto-enhanced and FREE (no stack cost)
   -> Shield refreshed for all allies
6. Repeat: Skill (taunt + DR) -> tank hits -> enhanced ATK -> Ult
```

#### Key Differences from Other Paths
| Aspect | Destruction | Hunt | Erudition | Harmony | Nihility | Preservation |
|--------|-------------|------|-----------|---------|----------|-------------|
| Element | Physical | Wind | Ice | Lightning | Fire | Fire |
| Role | DPS | Focused DPS | AoE DPS | Buffer | Debuffer/DoT | Tank/Shielder |
| Basic ATK | 50-110% | 50-110% | 50-110% + exec | 50-110% + Passive | 50-110% | 50-110% + Magma Will |
| Enhanced ATK | — | — | — | — | — | 90-146% + 1-tile AoE (4 stacks) |
| Skill | 1-tile AoE | 2-tile lunge | 3-tile AoE | Ally buff | 1-tile AoE + Burn | Self DMG Red + Taunt |
| Ult | Empowered | Conditional | 5-tile AoE | Ally energy | 3-tile + detonate | 3-tile ATK+DEF |
| Ult Energy | 120 | 100 | 110 | 130 | 120 | 120 |
| Passive | Kill ATK | Ally RES PEN | HP-threshold | Ally Lightning | Firekiss | Magma Will + Team Shield |
| Best Against | Groups | Bosses | Large groups | Carry ally | Tanky enemies | Protecting team |

---

### Abundance (Aeon: Yaoshi)
> *Selfless, altruistic, and healing actions are manifestations of the Path of Abundance.*

**Gameplay Role:** Heals allies and restores HP to the team.

- **Archetype:** Healer / Sustain support
- **Strengths:** Powerful single-target and team heals scaling off USER's max HP, heal-over-time on Skill, emergency healing boost for low-HP allies, lowest Ultimate energy cost (90)
- **Element:** Physical

#### Base Stats (by Ascension Phase & Level)

| Phase | Level | HP | ATK | DEF | SPD |
|-------|-------|----|-----|-----|-----|
| 0 | 1 | 158 | 64 | 69 | 98 |
| 0 | 20 | 308 | 126 | 134 | 98 |
| 1 | 20 | 372 | 152 | 162 | 98 |
| 1 | 30 | 451 | 184 | 196 | 98 |
| 2 | 30 | 514 | 210 | 224 | 98 |
| 2 | 40 | 594 | 243 | 258 | 98 |
| 3 | 40 | 657 | 268 | 286 | 98 |
| 3 | 50 | 736 | 301 | 320 | 98 |
| 4 | 50 | 799 | 327 | 348 | 98 |
| 4 | 60 | 879 | 359 | 382 | 98 |
| 5 | 60 | 942 | 385 | 410 | 98 |
| 5 | 70 | 1,021 | 417 | 445 | 98 |
| 6 | 70 | 1,085 | 443 | 472 | 98 |
| 6 | 80 | 1,164 | 476 | 507 | 98 |

**Stat Comparison at Lv80:**
| Path | HP | ATK | DEF | SPD |
|------|----|-----|-----|-----|
| Destruction | 1,203 | 620 | 460 | 100 |
| The Hunt | 882 | 546 | 396 | 100 |
| Erudition | 952 | 582 | 396 | 100 |
| Harmony | 846 | 529 | 396 | 112 |
| Nihility | 882 | 582 | 441 | 106 |
| Preservation | 1,241 | 601 | 606 | 95 |
| Abundance | 1,164 | 476 | 507 | 98 |

Abundance has the **second-highest HP** (1,164) and second-highest DEF (507), but the **lowest ATK** (476) of all paths. SPD 98 is slightly below base. This path is built entirely around healing — high HP means high healing output since heals scale off USER's max HP.

#### Abilities

**Basic ATK: Behind the Kindness** | Melee Hit | Energy Generation: 20 | Physical
Deals Physical DMG equal to **50%—110%** of USER's ATK to the target hit by the path weapon.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|-------|-----|-----|-----|-----|-----|-----|-----|
| ATK % | 50% | 60% | 70% | 80% | 90% | 100% | 110% |

*Abundance's Basic ATK is the weakest in practice due to lowest ATK stat. The path's value comes from healing, not damage.*

**Skill: Love, Heal, and Choose** | Ally Heal | Energy Generation: 30
Restores HP to the nearest designated ally within 7 tiles (or self if no ally in range):
- **Instant heal:** **7%—11.2%** of USER's Max HP plus **70—311.5** flat.
- **Heal over time:** Restores **4.8%—7.68%** of USER's Max HP plus **48—213.6** flat at the start of the target's next 2 turns (20 seconds). If the target is a non-path mob or carbon, the HoT ticks every 10 seconds instead.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|-----|--------|--------|--------|--------|------|------|------|-------|------|-------|-------|
| Instant HP% | 7% | 7.44% | 7.88% | 8.31% | 8.75% | 9.1% | 9.45% | 9.8% | 10.15% | 10.5% | 10.85% | 11.2% |
| Instant flat | 70 | 112 | 143.5 | 175 | 196 | 217 | 232.75 | 248.5 | 264.25 | 280 | 295.75 | 311.5 |
| HoT HP% | 4.8% | 5.1% | 5.4% | 5.7% | 6% | 6.24% | 6.48% | 6.72% | 6.96% | 7.2% | 7.44% | 7.68% |
| HoT flat | 48 | 76.8 | 98.4 | 120 | 134.4 | 148.8 | 159.6 | 170.4 | 181.2 | 192 | 202.8 | 213.6 |

*At Lv80 with 1,164 max HP, Lv12 Skill: Instant = (1164 * 0.112) + 311.5 = **442 HP**. HoT per tick = (1164 * 0.0768) + 213.6 = **303 HP** per tick for 2 ticks. Total healing: 442 + 606 = **~1,048 HP** over 20 seconds.*

**Ultimate: Gift of Rebirth** | Team Heal | Energy Cost: 90 | Energy Generation: 5
Heals **all designated allies within 7 tiles** (and self) for **9.2%—14.72%** of USER's Max HP plus **92—409.4** flat.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|------|--------|-------|--------|-------|-------|-------|-------|-------|------|-------|--------|
| HP% | 9.2% | 9.78% | 10.35% | 10.93% | 11.5% | 11.96% | 12.42% | 12.88% | 13.34% | 13.8% | 14.26% | 14.72% |
| Flat | 92 | 147.2 | 188.6 | 230 | 257.6 | 285.2 | 305.9 | 326.6 | 347.3 | 368 | 388.7 | 409.4 |

*At Lv80 with 1,164 max HP, Lv12 Ult: (1164 * 0.1472) + 409.4 = 171.3 + 409.4 = **~581 HP** to all allies. Costs only **90 energy** — the lowest Ultimate cost of any path, allowing frequent team heals.*

**Passive: Innervation** | On Heal
When healing an ally whose HP is at **30% or lower**, the USER's outgoing healing is increased by **25%—55%**. This bonus applies to both instant heals and heal-over-time ticks.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|-----|------|-----|------|-----|------|--------|--------|--------|-----|------|-----|
| Healing boost % | 25% | 27.5% | 30% | 32.5% | 35% | 37.5% | 40.63% | 43.75% | 46.88% | 50% | 52.5% | 55% |

*At Lv12, healing a critically injured ally (<30% HP) boosts healing by 55%. The Lv12 Skill on a low-HP ally: 442 * 1.55 = **685 instant HP** + 303 * 1.55 = **470 per HoT tick**. Total: ~1,625 HP — a massive emergency heal.*

#### Scaling Notes
- Basic ATK has **7 levels**, Skill/Ultimate/Passive have **12 levels**
- All damage uses **avg coeff** with **Physical** elemental type
- Abundance is a **pure healer** — lowest ATK, highest healing output
- Heals scale off **USER's max HP** (not ATK), so HP stat nodes in the skill tree directly increase healing power
- Skill provides both **instant healing** and a **HoT** (heal over time) component lasting 20 seconds
- Ultimate costs only **90 energy** — charges fastest of all paths, enabling frequent team heals
- Passive (Innervation) provides a massive healing boost for critically injured allies (<30% HP)
- The HoT from Skill ticks at the ally's turn start if they have a path, or every 10 seconds otherwise
- SPD 98 gives 5.1s turns — slightly slower than base, but heals don't benefit much from speed since they're reactive

#### Gameplay Loop
```
1. Designate allies via Designate Ally action
2. Stay near allies (within 7 tiles) for healing range
3. Attack enemies with Basic ATK to build energy + AP
   -> Damage is low but energy generation is the priority
4. Use Skill (Love, Heal, and Choose) on injured allies
   -> Instant heal + HoT for 20 seconds
   -> Targets nearest designated ally in range
   -> If ally is below 30% HP, Passive boosts healing by 25%-55%
5. Build to 90 energy (lowest Ult cost — charges fast)
6. Ultimate (Gift of Rebirth) when multiple allies need healing
   -> Heals ALL designated allies within 7 tiles
   -> Emergency team-wide heal
7. Repeat: attack for energy, Skill for single-target sustain,
   Ult for team-wide burst healing
```

#### Key Differences from All Paths
| Aspect | Destruction | Hunt | Erudition | Harmony | Nihility | Preservation | Abundance |
|--------|-------------|------|-----------|---------|----------|-------------|-----------|
| Element | Physical | Wind | Ice | Lightning | Fire | Fire | Physical |
| Role | DPS | Focused DPS | AoE DPS | Buffer | Debuffer | Tank | Healer |
| Basic ATK | 50-110% | 50-110% | +execute | +Passive | 50-110% | +Magma Will | 50-110% |
| Skill | 1-tile AoE | Lunge | 3-tile AoE | Ally buff | AoE+Burn | DMG Red+Taunt | Ally Heal+HoT |
| Ult | Empowered | Conditional | 5-tile AoE | Ally energy | Detonate | ATK+DEF AoE | Team Heal |
| Ult Cost | 120 | 100 | 110 | 130 | 120 | 120 | **90** |
| Passive | Kill ATK | RES PEN | HP-trigger | Ally DMG | Firekiss | Shield+Magma | Heal boost |
| Best For | Killing | Bosses | Groups | Carry | DoT/debuff | Tanking | Sustain |

---

## Core Mechanics

### Turn System (SPD)
Each pathstrider has a **turn cycle** — a recurring timer controlled by their SPD stat. Each turn, the player can do ONE of:
- **Attack turn:** Swing weapon freely (dealing damage each hit), but only the **first hit** grants 1 AP + energy. Subsequent hits deal damage but give no resources.
- **Skill turn:** Use a Skill (Z key), which costs AP + consumes the turn.

You **cannot do both in the same turn**. Ultimate is NOT gated by turns — it uses energy and can be activated at any time.

**Turn duration formula:**
```
turn_duration = 5 SECONDS * PATH_BASE_SPEED / current_SPD

Base SPD 100 → 5.0s turns
SPD 120      → 4.17s turns
SPD 80       → 6.25s turns
```

**DPS normalization:** Ability scaling (e.g. "50% of ATK") represents total damage for one attack turn, divided across all swings in that turn. Faster weapons swing more for less per hit; slower weapons swing less for more per hit. Total damage per turn is always the listed scaling.

### Energy System
- Every path has an **Energy** meter (0 to `max_energy`, default 100)
- Energy is gained by:
  - First melee hit of an **attack turn**: +energy (default 20, varies by path)
  - Using Skill (consumes a **skill turn**): +energy (default 30, varies by path)
- Energy is spent by:
  - Ultimate Action: requires `energy >= max_energy`, resets energy to 0
- Energy gain is **gated by the turn system** — only 1 energy gain event per turn

### Action Points (AP)
- Every path has **Action Points** (0 to `max_action_points`, default 5)
- AP is gained by:
  - First melee hit of an **attack turn**: +1 AP
- AP is spent by:
  - Skill: costs 1 AP per use (default) + consumes the turn
- AP gain is **gated by the turn system** — max 1 AP per turn
- AP has a hard cap and does not exceed `max_action_points`

### SPD Debuffs on Non-Path Targets
Path abilities can apply SPD debuffs. The effect depends on the target type:
- **Path holder** (human with path): slows their turn cycle (longer between turns)
- **Simple mob** (ordeal, hostile): slows their **movement speed** via `set_varspeed()`
- **Non-path carbon** (human without path): slows their **movement speed** via movespeed modifier

All SPD debuffs apply a `/datum/status_effect/path_spd_debuff` so abilities can check `has_path_spd_debuff(target)` for conditional effects (e.g. Hunt's Ultimate bonus damage on slowed targets).

### Damage Over Time (DoT)
Path abilities can apply elemental DoTs to targets. DoTs tick periodically, cannot crit, and are not affected by DMG boost effects.

**The 4 DoT Types:**
| DoT | Element | Base DMG per Tick | Duration | Notes |
|-----|---------|-------------------|----------|-------|
| Bleed | Physical | 16% target maxHP (7% for bosses) | 20s (2 turns) | Capped at 2x attacker ATK |
| Burn | Fire | 100% attacker ATK | 20s (2 turns) | Flat scaling |
| Shock | Lightning | 200% attacker ATK | 20s (2 turns) | 2x Burn |
| Wind Shear | Wind | 100% attacker ATK * stacks | 20s (2 turns) | Up to 5 stacks |

**Tick timing:**
- Path holders: DoTs tick at the start of each turn (in `OnTurnReset()`)
- Regular mobs: DoTs tick every 5 seconds via timer
- DoT formula: `Base DoT DMG * DEF Multiplier * RES Multiplier * avg_coeff`

**Applied via:** `apply_path_dot(target, dot_type, source_path, duration)` — see `_path_dots.md` for details.

### Damage Type System
Path abilities bypass LC13's per-color damage routing. Instead of using a single `damage_coeff` color, path damage calculates the **average of all 4 damage coefficients** (red, white, black, pale) as a unified resistance multiplier. Each path also has a **secondary elemental type** used for path-specific mechanics (RES PEN, elemental weaknesses, effect interactions).

**Elemental Types:**
| Type | Color | Define |
|------|-------|--------|
| Physical | Gray | `PATH_ELEMENT_PHYSICAL` |
| Fire | Red | `PATH_ELEMENT_FIRE` |
| Ice | Light Blue | `PATH_ELEMENT_ICE` |
| Lightning | Purple | `PATH_ELEMENT_LIGHTNING` |
| Wind | Light Green | `PATH_ELEMENT_WIND` |
| Quantum | Dark Purple | `PATH_ELEMENT_QUANTUM` |
| Imaginary | Yellow | `PATH_ELEMENT_IMAGINARY` |

**Path Assignments:**
| Path | Element |
|------|---------|
| Destruction | Physical |
| The Hunt | Wind |
| Erudition | Ice |
| Harmony | Lightning |
| Nihility | Fire |
| Preservation | Fire |
| Abundance | Physical |

**How it works:**
- Path damage **ignores individual damage type resistances** — it does NOT use a single `damage_coeff` color
- Instead, the mob's **average of all 4 damage coefficients** (red, white, black, pale) is calculated and applied as a single resistance multiplier
- This means path damage is "colorless" from LC13's perspective — no mob is fully immune unless ALL 4 coefficients are 0
- Formula: `avg_coeff = (damage_coeff.red + damage_coeff.white + damage_coeff.black + damage_coeff.pale) / 4`
- Path damage uses `adjustHealth()` directly with the avg coeff, bypassing individual color loss procs
- The elemental type is tracked separately on the path datum (`var/element_type`)
- Path effects that reference elemental typing (e.g. "Wind RES PEN", elemental weakness checks) use the `element_type` var
- Future: mobs could have a `var/list/element_weakness` that grants bonus damage when hit by a matching element type, applied as a multiplier before dealing damage

### Path Stats
Path stats are **completely separate** from LC13's attribute system (Fortitude/Prudence/Temperance/Justice). They exist in their own namespace and are used exclusively for scaling path ability effects.

**Core Stats:**
| Stat | Description |
|------|-------------|
| HP | Hit points added by the path (path-specific pool or additive to mob HP) |
| ATK | Attack power, scales damage abilities |
| DEF | Defense, scales defensive abilities and damage reduction |
| SPD | Speed, determines turn cycle duration (base 100, higher = faster turns) |
| CRIT Rate | Chance of critical hit (percentage) |
| CRIT DMG | Critical hit damage multiplier (percentage) |
| Max Energy | Maximum energy capacity |
| Energy Regen Rate | Multiplier for energy gain (percentage, 100 = normal) |
| Elemental RES | Resistance to each elemental type (percentage per element, see Damage RES section) |
| RES PEN | Penetration that ignores target's elemental RES (percentage, from abilities/buffs) |

Stats are determined by the path's **level** and **ascension phase**, not set as flat values.

### Leveling & Ascension System
- Paths have a **level** (1-80) and an **ascension phase** (0-6)
- Each ascension phase raises the level cap:

| Phase | Level Range |
|-------|-------------|
| 0 | 1 - 20 |
| 1 | 20 - 30 |
| 2 | 30 - 40 |
| 3 | 40 - 50 |
| 4 | 50 - 60 |
| 5 | 60 - 70 |
| 6 | 70 - 80 |

- Stats at a given level are **interpolated** between the floor and ceiling values of the current ascension phase (each path defines its own stat table)

### Path Leveling (Ahn Cost)

Paths are leveled by purchasing **Path EXP** from the fixer equipment vendor using ahn. Each purchase grants EXP toward the next path level.

**Design goal:** Total ahn cost to reach level 80 = **2.5x** the current attribute system. Current system: fixers start at 20 stats, max 130 = 85 ampules × 300 ahn = ~25,500 ahn. Target: **~63,750 ahn** for path leveling.

**Cost per level (by phase):**

| Phase | Levels | # Levels | Ahn per Level | Phase Subtotal | Running Total |
|-------|--------|----------|---------------|----------------|---------------|
| 0 | 1→20 | 19 | 250 | 4,750 | 4,750 |
| 1 | 20→30 | 10 | 350 | 3,500 | 8,250 |
| 2 | 30→40 | 10 | 500 | 5,000 | 13,250 |
| 3 | 40→50 | 10 | 650 | 6,500 | 19,750 |
| 4 | 50→60 | 10 | 900 | 9,000 | 28,750 |
| 5 | 60→70 | 10 | 1,200 | 12,000 | 40,750 |
| 6 | 70→80 | 10 | 1,700 | 17,000 | 57,750 |

**Leveling subtotal: 57,750 ahn** (79 levels).

**Ascension costs** (paid once at each phase gate):

| Ascension | Ahn Cost |
|-----------|----------|
| 0 → 1 | 500 |
| 1 → 2 | 750 |
| 2 → 3 | 1,000 |
| 3 → 4 | 1,250 |
| 4 → 5 | 1,500 |
| 5 → 6 | 2,000 |

**Ascension subtotal: 7,000 ahn.**

**Grand total: 64,750 ahn** (~2.54x the current system's 25,500 ahn).

**How it works:**
- The vendor sells a **"Path EXP Crystal"** item (like the training accelerator)
- Using it in hand grants 1 level to the player's active path and costs ahn based on current phase
- At the level cap for the current ascension phase (e.g. level 20 at phase 0), leveling is blocked until ascension
- Ascension is purchased separately (flat ahn cost per phase)

**Vendor item:**
```dm
/obj/item/path_exp_crystal
    name = "Path EXP Crystal"
    desc = "A crystal of concentrated imaginary energy. Use in hand to grant EXP to your active path."
    icon_state = "yourstate"
    // Grants a fixed amount of path EXP when used
    var/exp_amount = 100
```

### Traces (Skill Tree)

The skill tree is unlocked by spending **ahn** (not skill points). Each node has an ahn cost, and nodes must be unlocked along connected branches.

**Layout** (mimics HSR's branching diamond pattern around a central column):
```
            [Stat]---[Stat]
           /                \
    [Bonus A2]    [Basic Lv1]    [Bonus A2 stat]
           \      [Skill Lv1]   /
            [Stat]---[Stat]
           /                \
    [Bonus A4]    [Ult Lv1]     [Bonus A4 stat]
           \      [Passive Lv1] /
            [Stat]---[Stat]
           /                \
    [Bonus A6]              [Bonus A6 stat]
           \                /
            [Stat]---[Stat]
```

**Center column:** 4 core abilities (Basic ATK, Skill, Ultimate, Passive). Leveled via ability materials (TBD). Displayed in center for reference.

**Left/right branches:** Stat boosts and bonus abilities connected by lines. You follow branches outward from the center. Each branch has a bonus ability node with stat boosts on either side.

**3 types of Trace nodes:**

| Type | Count | Ahn Cost Each | Gating | Description |
|------|-------|---------------|--------|-------------|
| Stat Boost | 10 | 200-800 (scales with gate) | Ascension phase or path level | Percentage stat increase (e.g. ATK +4%) |
| Bonus Ability | 3 | 1,000 each | Ascension 2, 4, 6 | Unique passive effect |
| Ability Level | — | TBD | — | Core ability upgrades (separate system) |

**Stat boost ahn costs by gate:**
| Gate | Cost per Node |
|------|---------------|
| No gate | 200 |
| Ascension 2 | 300 |
| Ascension 3 | 400 |
| Ascension 4 | 500 |
| Ascension 5 | 600 |
| Ascension 6 | 700 |
| Level 75 | 750 |
| Level 80 | 800 |

**Total Trace ahn cost:** 10 stat boosts (~4,750 ahn) + 3 bonus abilities (3,000 ahn) = **~7,750 ahn** for all traces.

**Combined with leveling + ascension:** 64,750 + 7,750 = **~72,500 ahn** total to fully max a path.

---

## Architecture Overview

```
Player Mob
  |
  +-- /datum/component/path_holder
        |
        +-- /datum/path/destruction  (or other subtype)
              |
              +-- Resources: energy, action_points
              +-- Element: Physical (avg coeff damage + element effects)
              +-- Stats: path_stats + node bonuses
              +-- Skill Tree: list of /datum/path_node
              |
              +-- /datum/path_ability/basic/destruction
              +-- /datum/path_ability/burst/destruction
              +-- /datum/path_ability/ultimate/destruction
              +-- /datum/path_ability/passive/destruction
              |
              +-- /obj/item/ego_weapon/path_weapon  (Basic ATK = attack(), Skill = attack_self())
              +-- /datum/action/path_ultimate       (HUD button)
              +-- /datum/action/path_screen          (HUD button -> TGUI)
              +-- /datum/action/path_designate_ally  (HUD button -> ally list)
              +-- GLOB.path_ally_lists[owner]        (designated allies)
```

---

## File Map

| Design Doc | Implements | Description |
|-----------|------------|-------------|
| `_path_defines.md` | `_path_defines.dm` | Constants, signal defines |
| `_path_datum.md` | `_path_datum.dm` | `/datum/path` + `/datum/path_ability` hierarchy |
| `_path_node.md` | `_path_node.dm` | `/datum/path_node` skill tree nodes |
| `_path_weapon.md` | `_path_weapon.dm` | Path weapon (Basic ATK + Skill) + disguise system |
| `_path_allies.md` | `_path_allies.dm` | Ally designation system + helper procs |
| `_path_dots.md` | `_path_dots.dm` | DoT status effects (Bleed, Burn, Shock, Wind Shear) |
| `_path_actions.md` | `_path_actions.dm` | Action button datums (Ultimate, Screen) |
| `_path_component.md` | `_path_component.dm` | Component for mob attachment + helper procs |
| `_path_ui.md` | `_path_ui.dm` | DM-side TGUI procs (ui_interact/ui_data/ui_act) |
| `PathScreen.md` | `PathScreen.js` | React TGUI interface (Details + Skill Tree tabs) |

---

## Datum Reference

### `/datum/path` (Base)

**Variables:**
```
var/name = "Path"
var/desc = ""
var/icon_state = ""
var/mob/living/carbon/human/owner
var/element_type = PATH_ELEMENT_PHYSICAL  // Elemental typing (set by subtypes)
var/res_pen = 0                          // RES PEN % for this path's element (from buffs/abilities)

// Resources
var/energy = 0
var/max_energy = PATH_MAX_ENERGY_DEFAULT   // 100
var/action_points = 0
var/max_action_points = PATH_MAX_AP_DEFAULT // 5

// Leveling & Ascension
var/path_level = 1              // Current level (1-80)
var/ascension_phase = 0         // Current ascension (0-6)
var/list/level_caps = list(20, 30, 40, 50, 60, 70, 80) // Max level per phase

// Stat Table (set by subtypes)
// List of lists: each entry is list(phase, level, HP, ATK, DEF)
var/list/stat_table = list()

// Computed Path Stats (recalculated on level change)
var/list/path_stats = list()    // Current computed stats
// e.g. list("HP" = 163, "ATK" = 84, "DEF" = 62)

// Skill Tree
var/list/nodes = list()          // List of /datum/path_node
var/list/unlocked_nodes = list() // Node IDs that have been unlocked
var/skill_points = 0

// Ability Type References (set by subtypes)
var/basic_attack_type = /datum/path_ability/basic
var/burst_action_type = /datum/path_ability/burst
var/ultimate_type = /datum/path_ability/ultimate
var/passive_type = /datum/path_ability/passive

// Instantiated Abilities
var/datum/path_ability/basic/basic_attack
var/datum/path_ability/burst/burst_action
var/datum/path_ability/ultimate/ultimate_action
var/datum/path_ability/passive/passive_effect

// Turn System
var/turn_state = PATH_TURN_READY    // READY, ATTACKED, or SKILLED
var/next_turn_time = 0              // world.time when next turn starts
var/swings_per_turn = 6             // How many weapon swings fit in one turn

// Weapon
var/obj/item/ego_weapon/path_weapon/weapon
var/path_weapon_type = /obj/item/ego_weapon/path_weapon  // Subtypes override

// Action Button References
var/datum/action/path_ultimate/ultimate_action_button
var/datum/action/path_screen/screen_action_button
```

**Procs:**
| Proc | Description |
|------|-------------|
| `New()` | Calls `InitNodes()` to set up the skill tree |
| `InitNodes()` | Virtual. Subtypes populate `nodes` list |
| `AssignTo(mob/living/carbon/human/user)` | Attach path to mob, instantiate abilities, create weapon, grant actions |
| `Remove()` | Detach path, qdel weapon, remove actions, clean up |
| `GainEnergy(amount)` | +energy clamped to max, signal + button update |
| `SpendEnergy(amount)` | -energy clamped to 0, signal + button update |
| `GainActionPoint()` | +1 AP clamped to max, signal + button update |
| `SpendActionPoint()` | -1 AP clamped to 0, signal + button update |
| `GetStat(stat_name)` | Returns computed stat + sum of unlocked node bonuses |
| `SetLevel(new_level)` | Set path level, recalculate stats via interpolation |
| `Ascend()` | Increase ascension phase, raise level cap |
| `RecalculateStats()` | Interpolate stats from stat_table based on level/phase |
| `UnlockNode(node_id)` | Unlock a skill tree node if prereqs met and SP available |
| `OnWeaponHit(target, user)` | Called by path weapon's `attack()`. Deals per-swing damage, gates AP/energy by turn state |
| `GetTurnDuration()` | Returns turn duration in deciseconds based on SPD |
| `StartTurnCycle()` | Starts the recurring turn timer (called from AssignTo) |
| `OnTurnReset()` | Timer callback: resets turn_state to READY, queues next turn |
| `RecalcSwingsPerTurn()` | Recalculates swings_per_turn from turn duration and attack_speed |
| `deal_path_damage(mob/living/target, amount)` | Applies elemental RES multiplier (using `element_type` and `res_pen`), then avg of all 4 `damage_coeff` values. Calls `target.adjustHealth()` directly |

---

## Ability System

### `/datum/path_ability` (Base)
```
var/name = "Ability"
var/desc = ""
var/icon_state = ""
var/datum/path/parent_path
var/level = 1
var/max_level = 7              // Default; subtypes override (Basic=7, Skill/Ult/Passive=12)
```

Scaling is stored as a `var/list/` on each ability subtype, indexed by level. This gives exact control per level rather than using a formula.

### `/datum/path_ability/basic`
Triggered when the path weapon hits a target (via `OnWeaponHit()`). Damage is applied to the hit target.
```
var/energy_gain = 20           // Energy generated per hit (varies by path)
proc/OnHit(mob/living/target, mob/living/user)  // Virtual
```
Typical max_level: **7**

### `/datum/path_ability/burst` (Skill)
Activated via path weapon's `attack_self()`. Costs AP, grants energy. 5-second cooldown. Effects vary: AoE around user, lunge, targeted strike, etc.
```
var/energy_gain = 30           // Energy generated on use (varies by path)
var/ap_cost = 1
proc/Activate(mob/living/user) // Virtual
```
Typical max_level: **12**

### `/datum/path_ability/ultimate`
Activated via HUD action button. Requires full energy, resets to 0. Can be standalone damage OR an **Empowered** mode that buffs the next Basic/Skill.
```
proc/Activate(mob/living/user) // Virtual, calls SpendEnergy in base
```
Typical max_level: **12**. Energy cost varies by path (e.g. Destruction = 120).

**Empowered-type Ultimates:** Instead of dealing damage directly, they set an `enhanced` flag on the path. The next Basic ATK or Skill checks this flag and uses the Ultimate's scaling instead of its own. After one empowered attack, the flag resets.

### `/datum/path_ability/passive`
Registers signals for conditional triggers. Always-on effect.
```
proc/Apply(mob/living/user)    // Register signals
proc/Unapply(mob/living/user)  // Unregister signals
```
Typical max_level: **12**

---

## Skill Tree (Traces)

### `/datum/path_node`
```
var/id = ""                     // Unique node ID (e.g. "atk1")
var/name = "Node"
var/desc = ""
var/icon_state = ""
var/list/prerequisites = list() // Node IDs required before this one
var/cost = 1                    // Skill points to unlock
var/node_type = PATH_NODE_STAT  // "stat", "ability", or "passive"

// Stat nodes
var/list/stat_bonuses = list()  // e.g. list("ATK" = 10)

// Ability nodes
var/ability_target = ""         // "basic", "burst", or "ultimate"
var/level_increase = 1

// UI positioning
var/tree_x = 0
var/tree_y = 0
var/list/connections = list()   // Visual connections to other node IDs
```

**Procs:**
| Proc | Description |
|------|-------------|
| `New(id, name, desc)` | Convenience constructor |
| `GetNodeData(unlocked_nodes)` | Returns assoc list for TGUI |
| `CanUnlock(unlocked_nodes)` | TRUE if all prerequisites are met |

---

## Path Weapon

### `/obj/item/ego_weapon/path_weapon`
Custom EGO weapon subtype that serves as the conduit for Basic Attack and Skill:
- `attack()` = Basic Attack (calls `linked_path.OnWeaponHit()`, path damage only, force=0 means no LC13 damage)
- `attack_self()` = Burst/Skill (5s cooldown, AP cost, calls `burst_action.Activate()`)
- `TRAIT_NODROP` prevents dropping/trading
- Each path defines its own weapon subtype via `path_weapon_type`

### Appearance Disguise System
Players can copy the appearance of any EGO weapon onto their path weapon:
- HUD action button opens selection list of all EGO weapon types
- Copies: name, desc, icon, sprites, hitsound, swingstyle, reach, attack_speed
- Does NOT copy: force, damtype, knockback, attribute_requirements, special procs
- DPS stays constant regardless of attack_speed (damage per hit is normalized)

See `_path_weapon.md` for full details.

## Action Buttons

### `/datum/action/path_ultimate`
- Trigger checks `energy >= max_energy`
- Calls `ultimate_action.Activate()` (which spends energy internally)
- Glows/highlights when energy is full

### `/datum/action/path_screen`
- Trigger calls `linked_path.ui_interact(owner)` to open the TGUI

Both store a `var/datum/path/linked_path` reference set during `AssignTo()`.

*(Burst/Skill is no longer an action button — it is the path weapon's `attack_self()`.)*

---

## Mob Integration (Component)

### `/datum/component/path_holder`
Attaches to a mob to manage their active path.
```
var/datum/path/active_path
```

**Lifecycle:**
- `Initialize(datum/path/new_path)` -> checks `isliving(parent)`, calls `active_path.AssignTo(parent)`
- `Destroy()` -> calls `active_path.Remove()`, qdels the path

### Helper Procs on `/mob/living/carbon/human`
| Proc | Description |
|------|-------------|
| `GetPath()` | Returns the active `/datum/path` or null |
| `HasPath()` | Returns TRUE if the mob has a path |
| `GrantPath(path_type)` | Creates path instance, adds component. Fails if already has a path |
| `RemovePath()` | Qdels the component (triggers cleanup) |

---

## TGUI Interface

### DM Side (procs on `/datum/path`)
- `ui_state()` -> `GLOB.always_state`
- `ui_interact()` -> standard `SStgui.try_update_ui()` pattern, opens `"PathScreen"`
- `ui_data()` -> returns all data for both UI tabs (see below)
- `ui_act()` -> handles `"unlock_node"` with `params["node_id"]`

### `ui_data` Structure
```json
{
  "path_name": "Destruction",
  "path_desc": "Focuses on dealing massive damage.",
  "path_icon": "destruction",
  "element_type": "physical",

  "energy": 75,
  "max_energy": 120,
  "action_points": 3,
  "max_action_points": 5,

  "stats": {
    "HP": 163, "ATK": 94, "DEF": 62,
    "CRIT Rate": 5, "CRIT DMG": 50,
    "Max Energy": 120, "Energy Regen Rate": 100
  },

  "abilities": [
    {"name": "...", "desc": "...", "type": "basic",
     "level": 2, "max_level": 10, "icon": "..."},
    {"name": "...", "type": "burst", ...},
    {"name": "...", "type": "ultimate", ...},
    {"name": "...", "type": "passive", ...}
  ],

  "nodes": [
    {"id": "atk1", "name": "ATK +10", "desc": "...",
     "cost": 1, "node_type": "stat", "tree_x": 2,
     "tree_y": 0, "connections": ["atk2"],
     "prerequisites": [], "unlocked": true,
     "stat_bonuses": {"ATK": 10}}
  ],

  "skill_points": 3,

  "lc13_attributes": {
    "Fortitude": 45, "Prudence": 32,
    "Temperance": 28, "Justice": 51
  }
}
```

### React Side (`PathScreen.js`)
Two tabs:

**Tab 1 - Details:**
```
+-----------------------------------------------+
| [Details] [Skill Tree]                         |
+-----------------------------------------------+
| Path Name: Destruction                         |
| "Focuses on dealing massive damage."           |
+-----------------------------+-----------------+|
| Abilities                   | Stats           ||
| [icon] Basic Attack  Lv.2  | HP:   163       ||
| [icon] Burst Action  Lv.1  | ATK:  94        ||
| [icon] Ultimate      Lv.1  | DEF:  62        ||
| [icon] Passive       Lv.1  | CRIT Rate: 5%   ||
|                             | CRIT DMG: 50%   ||
|                             | [More Stats v]  ||
+-----------------------------+-----------------+|
| Energy: [====75/120=========]                  |
| AP: [*] [*] [*] [ ] [ ]   (3/5)              |
+-----------------------------------------------+
| LC13: FOR 45 | PRU 32 | TEM 28 | JUS 51      |
+-----------------------------------------------+
```

**Tab 2 - Skill Tree:**
```
+-----------------------------------------------+
| [Details] [Skill Tree]                         |
+-----------------------------------------------+
| Skill Points: 3                                |
+-----------------------------------------------+
|        [ATK+10]---[ATK+20]                     |
|            |                                   |
|       [Basic Lv2]---[Basic Lv3]                |
|            |                                   |
|        [DEF+5]    [CRT+2]---[CRT+3]           |
|            |          |                        |
|       [Burst Lv2] [Passive Lv2]               |
+-----------------------------------------------+
| Selected: ATK +20                              |
| Cost: 1 SP | Requires: ATK +10                |
| [Unlock]                                       |
+-----------------------------------------------+
```

**Components used:** `Window`, `Tabs`, `Section`, `Stack`, `Flex`, `Box`, `Button`, `LabeledList`, `ProgressBar`, `Collapsible`

**Node styling:**
- Unlocked: green/gold highlight
- Available (prereqs met, has SP): normal color
- Locked (prereqs not met): grayed out

---

## Signal Flow

```
TURN CYCLE:
  Every GetTurnDuration() seconds (5s at base 100 SPD):
  -> OnTurnReset()
     -> turn_state = PATH_TURN_READY
     -> Queue next turn timer via addtimer()

BASIC ATTACK (Path Weapon melee hit):
  Player clicks mob with path weapon
  -> /obj/item/ego_weapon/path_weapon/attack()
     -> Plays hitsound (force=0 would play tap.ogg otherwise)
     -> ..() [parent handles animation, sweep, signals — attacked_by() does nothing since force=0]
     -> linked_path.OnWeaponHit(target, user)
        -> basic_attack.OnHit(target, user, swings_per_turn)  [damage / swings_per_turn per hit]
        -> IF turn_state == TURN_READY:
              GainEnergy(basic_attack.energy_gain) [+20 default, first hit only]
              GainActionPoint()                    [+1, first hit only]
              turn_state = TURN_ATTACKED           [skill locked this turn]
        -> IF turn_state == TURN_ATTACKED:
              Deal damage only, no AP/energy
        -> IF turn_state == TURN_SKILLED:
              Deal damage only, no AP/energy

SKILL (Path Weapon attack_self / Z key):
  Player uses weapon in hand
  -> /obj/item/ego_weapon/path_weapon/attack_self()
  -> Check: turn_state == PATH_TURN_READY      [not already attacked or skilled]
  -> Check: AP >= burst_action.ap_cost
  -> SpendActionPoint()                        [-1]
  -> GainEnergy(burst_action.energy_gain)      [+30 default]
  -> burst_action.Activate(user)               [subtype does unique action]
  -> turn_state = PATH_TURN_SKILLED            [attack AP/energy locked this turn]

ULTIMATE ACTION (not gated by turns):
  Player clicks Ultimate HUD button
  -> /datum/action/path_ultimate/Trigger()
  -> Check: energy >= max_energy
  -> ultimate_action.Activate(user)            [subtype does powerful action]
  -> SpendEnergy(all energy)                   [reset to 0]

PASSIVE:
  passive_effect.Apply() registers signals on owner
  -> Triggers on conditions (damage taken, HP threshold, kills, etc.)
  -> Each path's passive has unique trigger logic
```

---

## Combat Formulas

### Total ATK Calculation
```
Total ATK = Base ATK * (1 + Percentage ATK Bonus) + Additive ATK Bonus
```
- **Base ATK**: From the path's stat table (level/ascension dependent)
- **Percentage ATK Bonus**: Sum of all % ATK buffs (e.g. Perfect Pickoff passive stacks)
- **Additive ATK Bonus**: Flat ATK from skill tree nodes, buffs, etc.

### Total DEF Calculation
```
Total DEF = Base DEF * (1 + %DEF Bonus - %DEF Reduction) + Additive DEF Bonus
```

### DEF Multiplier (vs Enemies)
When a path ability hits a mob, DEF reduces damage via this multiplier:
```
DEF Multiplier = (Level_Attacker + 20) /
    ((Level_Enemy + 20) * max(0.1, 1 + %DEF Bonus - %DEF Reduction - %DEF Ignore)
     + Level_Attacker + 20)
```
- **Level_Attacker**: The path's `path_level`
- **Level_Enemy**: The mob's effective level (see mapping below)
- Result is between 0 and 1, multiplied against the raw damage

### Total HP Calculation
```
Total HP = Base HP * (1 + %HP Bonus) + Additive HP Bonus
```
- **Base HP**: From the path's stat table (level/ascension dependent)
- Path HP is additive to the mob's existing health pool (or acts as a separate shield — TBD)

### CRIT Rate
```
CRIT Rate = Base CRIT Rate + CRIT Rate Bonus
```
- **Base CRIT Rate**: From the path's stat table (e.g. 5%)
- **CRIT Rate Bonus**: From skill tree nodes, buffs, etc. (additive %)
- Clamped to **0%–100%**
- On each hit, roll `prob(CRIT Rate)` to determine if the attack crits

### CRIT DMG
```
CRIT DMG = Base CRIT DMG + CRIT DMG Bonus
```
- **Base CRIT DMG**: From the path's stat table (e.g. 50%)
- **CRIT DMG Bonus**: From skill tree nodes, buffs, etc. (additive %)
- When a crit occurs, damage is multiplied by `(1 + CRIT DMG / 100)`
- Example: 50% CRIT DMG = 1.5x damage on crit

### Damage RES (Elemental Resistance)
Damage RES is a stat used by **both characters and enemies**. It decreases the amount of damage taken of the corresponding elemental type.

#### RES Multiplier Formula
```
RES Multiplier = 1 - (RES_Target - RES_PEN_Attacker)
```
- **RES_Target**: The target's resistance to the attacker's element type (percentage)
- **RES_PEN_Attacker**: The attacker's RES penetration for their element type (percentage)
- **Damage RES** is clamped to **-100% to 90%** (after PEN)
- Therefore **RES Multiplier** ranges from **10% to 200%**

#### Enemy RES Defaults
| Scenario | RES Value |
|----------|-----------|
| Weak to element | 0% (RES Multiplier = 1.0x) |
| Neutral to element | 20% (RES Multiplier = 0.8x) |
| Resistant to element | 40% (RES Multiplier = 0.6x) |
| Highly resistant | 60% (RES Multiplier = 0.4x) |
| Boss enemies (non-weak) | 40% (RES Multiplier = 0.6x) |

#### RES PEN Example (The Hunt)
The Hunt's Talent (Superiority of Reach) grants **Wind RES PEN**:
- At Lv1: 12% Wind RES PEN
- At Lv12: 25% Wind RES PEN

Against a 20% Wind RES enemy with 25% PEN:
```
RES Multiplier = 1 - (0.20 - 0.25) = 1.05 (105% damage)
```
RES PEN can push the multiplier above 1.0, turning neutral enemies into effective weaknesses.

#### Negative RES (Shred/Over-Penetration)
When RES PEN exceeds the target's RES, the effective RES goes negative, **amplifying** damage:
```
Target has 0% RES (weak), attacker has 25% PEN:
Effective RES = 0% - 25% = -25%
RES Multiplier = 1 - (-0.25) = 1.25 (125% damage)
```
Clamped: minimum effective RES is -100% (max 200% multiplier).

#### Character RES
Players also have elemental RES stats from their path. These reduce incoming path-type damage from enemies or environmental effects. Default character RES is typically 0% for all types unless modified by path stats, skill tree nodes, or buffs.

### Full Damage Formula (Single Hit)
```
Raw DMG = Total ATK * Ability Scaling% / 100

If CRIT (prob(CRIT Rate)):
    Raw DMG = Raw DMG * (1 + CRIT DMG / 100)

DEF-Adjusted DMG = Raw DMG * DEF Multiplier

// Elemental RES multiplier
effective_RES = clamp(target_RES - attacker_RES_PEN, -1.0, 0.9)
RES Multiplier = 1 - effective_RES

// LC13 avg damage coefficient
avg_coeff = (target.damage_coeff.red + target.damage_coeff.white
           + target.damage_coeff.black + target.damage_coeff.pale) / 4

Final DMG = DEF-Adjusted DMG * RES Multiplier * avg_coeff
target.adjustHealth(-Final DMG)
```

**Damage pipeline order:**
1. **ATK * Scaling** — base ability damage
2. **CRIT** — random chance to multiply
3. **DEF Multiplier** — level-based defense reduction
4. **RES Multiplier** — elemental resistance (path system)
5. **Avg Coeff** — LC13 damage coefficient average (mob system)

### Max Energy
```
Max Energy = Base Max Energy + Max Energy Bonus
```
- Determines the energy threshold for Ultimate activation
- Can be increased by skill tree nodes

### Energy Regen Rate
```
Effective Energy Gain = Base Energy Gain * (Energy Regen Rate / 100)
```
- **Energy Regen Rate** default: 100 (= 1.0x multiplier)
- Applied to all energy generation (basic attack hits, burst usage)
- Can be increased by skill tree nodes or buffs

### Effect Hit Rate (Debuff Application)
```
Real Chance = Base Chance
    * (1 + Effect Hit Rate_Attacker)
    * (1 - Effect RES_Target)
    * (1 - Debuff RES_Target)
```
- **Base Chance**: The base probability of the effect (set per ability)
- **Effect Hit Rate**: Attacker's stat bonus to landing effects
- **Effect RES**: Target's resistance to effects in general
- **Debuff RES**: Target's resistance to specific debuff types

---

## Damage Calculation vs LC13 Mobs

### How LC13 Mob Damage Works
LC13 mobs (`/mob/living/simple_animal/hostile`) use a simple system:
- **`maxHealth`** / **`health`**: Single HP pool (e.g. 80 for dawn amber, 10000 for crimson midnight boss)
- **`damage_coeff`**: A `/datum/dam_coeff` with multipliers per damage type. e.g. `list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 1.3, PALE_DAMAGE = 2)` means RED does 80% damage, PALE does 200%
- **No armor stat on mobs**: The `damage_coeff` IS their defense. A coeff of 0 = immune, <1 = resistant, >1 = weak

### Damage Flow (Path System)
```
Path ability calculates raw damage:
  1. raw_damage = Total ATK * ability_scaling[level] / 100
  2. CRIT check: if crit, raw_damage *= (1 + CRIT DMG / 100)
  3. DEF multiplier: raw_damage *= DEF_multiplier
  4. Elemental RES:
     effective_RES = clamp(target_RES - attacker_RES_PEN, -1.0, 0.9)
     raw_damage *= (1 - effective_RES)
  5. LC13 avg coeff (bypasses normal color routing):
     avg_coeff = (damage_coeff.red + damage_coeff.white
                + damage_coeff.black + damage_coeff.pale) / 4
     final_damage = raw_damage * avg_coeff
  6. adjustHealth(-final_damage)
```

Path damage uses two resistance layers:
- **Elemental RES** (path system): per-element resistance, reduced by attacker's RES PEN. Ranges 10%-200% multiplier.
- **Avg damage_coeff** (LC13 system): average of all 4 color coefficients as a unified multiplier.
- No mob is fully immune unless ALL 4 coefficients are 0 AND elemental RES is 90%
- Implementation: `deal_path_damage(target, amount)` on `/datum/path` handles RES lookup, avg coeff, and calls `adjustHealth()` directly

### Mapping Path Level to Enemy Level (for DEF formula)
LC13 mobs don't have an explicit "level" var. We need to derive an effective level for the DEF formula. Approach options:

**Option A: Map by ordeal tier** (recommended)
| Mob Tier | Effective Level | Examples |
|----------|----------------|---------|
| Dawn ordeal | 20 | Amber dawn (80 HP), Crimson clown (100 HP) |
| Noon ordeal | 35 | Crimson noon (1000 HP), Green dawn (400 HP) |
| Dusk ordeal | 50 | Crimson dusk (2000 HP), Amber dusk (2200 HP) |
| Midnight ordeal | 65 | Crimson tent (10000 HP), Amber midnight (15000 HP) |
| White ordeal (post-game) | 80 | White fixers (3000-4000 HP each), The Claw (8000 HP) |

**Option B: Derive from maxHealth**
```dm
effective_level = clamp(round(log(2, maxHealth / 50) * 10), 1, 80)
```

**Option C: Add a `mob_level` var** to hostile mobs used by the path system. Set by subtypes or default to Option B.

### Ordeal Reference Stats (for balancing)

**Regular Ordeals (Dawn -> Midnight):**
| Tier | Example | HP | Melee DMG | Damage Coefficients |
|------|---------|-----|-----------|-------------------|
| Dawn (Amber) | amber_dawn | 80 | 4-6 | R:2 W:1 B:1 P:2 |
| Dawn (Green) | green_dawn | 400 | 22-26 | R:0.8 W:1.3 B:2 P:1 |
| Noon (Crimson) | crimson_noon | 1000 | 18-20 | R:0.6 W:1.2 B:1.2 P:1.5 |
| Dusk (Crimson) | crimson_dusk | 2000 | 32-36 | R:0.4 W:1.2 B:1.2 P:1.5 |
| Dusk (Amber) | amber_dusk | 2200 | 100-115 | R:1.2 W:0.8 B:0.5 P:2 |
| Midnight (Crimson) | crimson_tent | 10000 | 15-30 | R:0.2 W:1 B:1 P:1.5 |
| Midnight (Amber) | amber_midnight | 15000 | — | R:1 W:0.6 B:0.4 P:0.8 |

**White Ordeals (Post-Game Challenges):**
| Mob | HP | Melee DMG | Damage Coefficients |
|-----|-----|-----------|-------------------|
| Black Fixer | 3000 | 30-40 | R:1 W:0.5 B:0 P:0.5 |
| White Fixer | 3000 | — | R:0.5 W:0 B:0.5 P:1 |
| Red Fixer | 3000 | 15-35 | R:0 W:0.5 B:1 P:0.5 |
| Pale Fixer | 4000 | 30-40 | R:0.5 W:1 B:0.5 P:0 |
| The Claw (Midnight) | 8000 | 75-85 | R:0.4 W:0.4 B:0.4 P:0.4 |

**Key Observations:**
- Mobs are immune (0.0 coeff) or near-immune to at least 1 damage type, weak to others
- White ordeal fixers each counter a specific color (Black Fixer immune to BLACK, etc.)
- The Claw has uniform 0.4 across all types — pure HP sponge
- Path damage uses the **average of all 4 coefficients**, so no single immunity fully blocks path damage
- Avg coefficients for reference (see corrected table in Destruction section):
  - Amber Dawn: **1.50** | Crimson Noon: **1.13** | Crimson Dusk: **1.08**
  - Crimson Tent: **0.93** | Amber Midnight: **0.70**
  - All White Fixers: **0.50** | The Claw: **0.40**

### Enemy Elemental RES Defaults
LC13 mobs will have elemental RES values added via a `var/list/element_res` on the mob or attached by the path system. Default assignments:

| Mob Tier | Weak Element RES | Non-Weak Element RES | Notes |
|----------|-----------------|---------------------|-------|
| Dawn ordeal | 0% | 20% | 1 weakness, rest neutral |
| Noon ordeal | 0% | 20% | 1 weakness, rest neutral |
| Dusk ordeal | 0% | 20% | 1 weakness, rest neutral |
| Midnight ordeal | 0% | 20% | 1 weakness, rest neutral |
| White ordeal (boss) | 0% | 40% | Tougher elemental resist |
| The Claw | 0% (none) | 40% | No weakness, all 40% |

Elemental weaknesses per ordeal family (TBD — to be assigned per mob):
- Amber ordeals: weak to Ice (0% Ice RES)
- Crimson ordeals: weak to Physical (0% Physical RES)
- Green ordeals: weak to Fire (0% Fire RES)
- Indigo ordeals: weak to Lightning (0% Lightning RES)
- White fixers: each weak to one element (TBD per fixer)

### Full Pipeline: DEF + RES + Avg Coeff
All three defensive layers applied in order:
```
// 1. DEF multiplier (level-based)
effective_damage = raw_damage * DEF_multiplier

// 2. Elemental RES multiplier (path system)
effective_RES = clamp(target_RES - attacker_RES_PEN, -1.0, 0.9)
effective_damage *= (1 - effective_RES)

// 3. LC13 avg damage coefficient (mob system)
avg_coeff = (damage_coeff.red + damage_coeff.white
           + damage_coeff.black + damage_coeff.pale) / 4
final_damage = effective_damage * avg_coeff

target.adjustHealth(-final_damage)
```
Three layers of defense:
1. **DEF Multiplier** — level-based, from Path system's DEF formula
2. **RES Multiplier** — elemental, from Path system's RES/RES PEN
3. **Avg Coeff** — LC13's innate color resistances, averaged

#### Example: Hunt (Wind) vs 20% Wind RES enemy with 0.50 avg coeff
```
ATK = 500, Skill scaling = 100%, DEF mult = 0.75
RES PEN = 25% (Talent Lv12)
Raw = 500 * 1.0 = 500
DEF-adjusted = 500 * 0.75 = 375
RES = 1 - (0.20 - 0.25) = 1.05
RES-adjusted = 375 * 1.05 = 394
Final = 394 * 0.50 = 197
```

---

## Integration with LC13 Systems

| System | How It Integrates |
|--------|-------------------|
| **EGO Weapons** | Path provides its own `/obj/item/ego_weapon/path_weapon` subtype. `force=0` ensures no LC13 damage; path damage is applied directly via `OnWeaponHit()`. Appearance can be copied from any EGO weapon via disguise system |
| **Signals** | Passive abilities use existing signals like `COMSIG_MOB_APPLY_DAMGE` (note: existing typo in codebase). Basic Attack no longer uses `COMSIG_MOB_ITEM_ATTACK` — it's driven directly by the path weapon's `attack()` |
| **Damage** | Path damage bypasses per-color routing; uses average of all 4 `damage_coeff` values as resistance. Elemental type (Physical/Wind/etc.) is a separate layer for path effects |
| **LC13 Attributes** | Path stats are SEPARATE. LC13 attributes (Fortitude/Prudence/Temperance/Justice) displayed in UI for reference and can optionally be read via `get_modified_attribute_level()` for hybrid scaling |
| **Actions** | Standard `/datum/action` system for Ultimate and Screen HUD buttons. Burst/Skill lives on the weapon's `attack_self()` |
| **TGUI** | Standard `SStgui` pattern |
| **Components** | Uses `/datum/component` for clean mob attachment/detachment |

---

## Defines Quick Reference

```dm
// Resource defaults
#define PATH_MAX_ENERGY_DEFAULT 100
#define PATH_MAX_AP_DEFAULT     5

// Speed & Turn system
#define PATH_BASE_SPEED        100
#define PATH_TURN_BASE         5 SECONDS
#define PATH_TURN_READY        0   // Can attack or skill
#define PATH_TURN_ATTACKED     1   // Already attacked, skill locked
#define PATH_TURN_SKILLED      2   // Already skilled, AP/energy locked

// DoT types
#define PATH_DOT_BLEED       "bleed"
#define PATH_DOT_BURN        "burn"
#define PATH_DOT_SHOCK       "shock"
#define PATH_DOT_WIND_SHEAR  "wind_shear"

// Node types
#define PATH_NODE_STAT    "stat"
#define PATH_NODE_ABILITY "ability"
#define PATH_NODE_PASSIVE "passive"

// Ability targets
#define PATH_ABILITY_BASIC    "basic"
#define PATH_ABILITY_BURST    "burst"
#define PATH_ABILITY_ULTIMATE "ultimate"

// Elemental types (secondary typing for path effects)
#define PATH_ELEMENT_PHYSICAL  "physical"
#define PATH_ELEMENT_FIRE      "fire"
#define PATH_ELEMENT_ICE       "ice"
#define PATH_ELEMENT_LIGHTNING "lightning"
#define PATH_ELEMENT_WIND      "wind"
#define PATH_ELEMENT_QUANTUM   "quantum"
#define PATH_ELEMENT_IMAGINARY "imaginary"

// RES defaults (for mobs without explicit element_res)
#define PATH_RES_DEFAULT       20  // 20% RES to non-weak elements
#define PATH_RES_WEAK          0   // 0% RES to weak element
#define PATH_RES_BOSS          40  // 40% RES for boss/white enemies
#define PATH_RES_MIN          -100 // Min effective RES (clamp)
#define PATH_RES_MAX           90  // Max effective RES (clamp)

// Custom signals
#define COMSIG_MOB_PATH_ASSIGNED   "mob_path_assigned"
#define COMSIG_MOB_PATH_REMOVED    "mob_path_removed"
#define COMSIG_PATH_ENERGY_CHANGED "path_energy_changed"
#define COMSIG_PATH_AP_CHANGED     "path_ap_changed"
```

---

## DME Includes

Add to `lobotomy-corp13.dme` in the `ModularLobotomy\enders_gimmicks` section:
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
`_path_defines.dm` must be included first (provides defines used by all other files).

---

## Implementation Order

1. `_path_defines.dm` - Constants and signal strings
2. `_path_node.dm` - Skill tree node datum
3. `_path_datum.dm` - Base `/datum/path` + `/datum/path_ability` hierarchy
4. `_path_weapon.dm` - Path weapon (Basic ATK + Skill) + disguise system
5. `_path_allies.dm` - Ally designation system + helper procs
6. `_path_dots.dm` - DoT status effects (Bleed, Burn, Shock, Wind Shear)
7. `_path_actions.dm` - Action button datums (Ultimate, Screen)
8. `_path_component.dm` - Component + helper procs on mob
9. `_path_ui.dm` - DM-side TGUI procs
10. `PathScreen.js` - React TGUI interface
11. DME includes
12. Example path subtype for end-to-end testing

---

## Defining a New Path (Subtype Guide)

To add a new path (e.g. Destruction), create a new `.dm` file and define:

### 1. Path Datum Subtype
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
    path_stats = list(
        "ATK" = 84, "DEF" = 62,
        "CRIT Rate" = 5, "CRIT DMG" = 50,
        "Max Energy" = 120, "Energy Regen Rate" = 100
    )
```

### 2. Skill Tree Nodes
```dm
/datum/path/destruction/InitNodes()
    var/datum/path_node/N

    N = new /datum/path_node("atk1", "ATK +10", "Increases ATK by 10.")
    N.stat_bonuses = list("ATK" = 10)
    N.tree_x = 2
    N.tree_y = 0
    N.connections = list("atk2")
    nodes += N

    N = new /datum/path_node("basic_lv2", "Basic Lv.2", "Upgrade Farewell Hit.")
    N.node_type = PATH_NODE_ABILITY
    N.ability_target = PATH_ABILITY_BASIC
    N.level_increase = 1
    N.prerequisites = list("atk1")
    N.tree_x = 2
    N.tree_y = 1
    nodes += N
    // ... more nodes
```

### 3. Ability Subtypes
```dm
/datum/path_ability/basic/destruction
    name = "Farewell Hit"
    desc = "Deals RED DMG equal to ATK% to a single enemy."
    energy_gain = 20
    max_level = 7
    /// Scaling: 50% at lv1, +10% per level up to 110% at lv7
    var/list/atk_scaling = list(50, 60, 70, 80, 90, 100, 110)

/datum/path_ability/basic/destruction/OnHit(mob/living/target, mob/living/user)
    var/multiplier = atk_scaling[level] / 100
    var/damage = parent_path.GetStat("ATK") * multiplier
    parent_path.deal_path_damage(target, damage)

/datum/path_ability/burst/destruction
    name = "RIP Home Run"
    desc = "Deals RED DMG to a single enemy and enemies adjacent to it."
    energy_gain = 30
    max_level = 12
    /// Scaling: 62.5% at lv1 up to 137.5% at lv12
    var/list/atk_scaling = list(62.5, 68.75, 75, 81.25, 87.5, 93.75, 101.56, 109.38, 117.19, 125, 131.25, 137.5)

/datum/path_ability/burst/destruction/Activate(mob/living/user)
    var/multiplier = atk_scaling[level] / 100
    var/damage = parent_path.GetStat("ATK") * multiplier
    // Hit primary target + adjacent enemies
    for(var/mob/living/L in range(1, user))
        if(L == user)
            continue
        deal_path_damage(L, damage)

/datum/path_ability/ultimate/destruction
    name = "Stardust Ace"
    desc = "Choose between two empowered attack modes."
    max_level = 12
    /// Blowout: Farewell Hit scaling (focused strike)
    var/list/blowout_fh = list(300, 315, 330, 345, 360, 375, 393.75, 412.5, 431.25, 450, 465, 480)
    /// Blowout: RIP Home Run main target scaling
    var/list/blowout_rip_main = list(180, 189, 198, 207, 216, 225, 236.25, 247.5, 258.75, 270, 279, 288)
    /// Blowout: RIP Home Run adjacent target scaling
    var/list/blowout_rip_adj = list(108, 113.4, 118.8, 124.2, 129.6, 135, 141.75, 148.5, 155.25, 162, 167.4, 172.8)
    /// Which mode is active: "farewell" or "rip"
    var/active_mode = "farewell"

/datum/path_ability/ultimate/destruction/Activate(mob/living/user)
    . = ..() // Base spends energy
    var/atk = parent_path.GetStat("ATK")
    switch(active_mode)
        if("farewell")
            // Empowered Farewell Hit — focused strike on target in front
            var/damage = atk * (blowout_fh[level] / 100)
            // Deal to target in front of user
            // ...
        if("rip")
            // Empowered RIP Home Run (main target + 1-tile AoE)
            var/main_damage = atk * (blowout_rip_main[level] / 100)
            var/adj_damage = atk * (blowout_rip_adj[level] / 100)
            // Deal main_damage to primary, adj_damage to adjacent
            // ...

/datum/path_ability/passive/destruction
    name = "Perfect Pickoff"
    desc = "Each kill increases ATK. Stacks up to 2 times."
    max_level = 12
    /// ATK buff % per stack
    var/list/atk_buff_scaling = list(10, 11, 12, 13, 14, 15, 16.25, 17.5, 18.75, 20, 21, 22)
    var/max_stacks = 2
    var/current_stacks = 0

/datum/path_ability/passive/destruction/Apply(mob/living/user)
    RegisterSignal(user, COMSIG_MOB_ITEM_ATTACK, PROC_REF(OnAttackKillCheck))

/datum/path_ability/passive/destruction/Unapply(mob/living/user)
    UnregisterSignal(user, COMSIG_MOB_ITEM_ATTACK)
    current_stacks = 0

/datum/path_ability/passive/destruction/proc/OnAttackKillCheck(...)
    // After killing an enemy, if stacks < max_stacks:
    //   current_stacks++
    //   Buff ATK by atk_buff_scaling[level]% per stack
```

### 4. Grant to a Player
```dm
// In-game (e.g. admin verb or item effect):
var/mob/living/carbon/human/H = usr
H.GrantPath(/datum/path/destruction)

// Remove:
H.RemovePath()
```

### Key Implementation Details for Destruction
- **Ultimate is Empowered** — it buffs the NEXT Basic ATK or Skill, not a standalone attack. The path needs to track an `enhanced` state that the basic/skill abilities check.
- **Basic ATK has 7 max levels**, Skill/Ultimate/Passive have **12 max levels**
- **All damage uses avg coeff** (average of all 4 LC13 damage coefficients)
- **Passive stacks reset** on path removal or death
- **Ability scaling** stored as lists indexed by level for exact HSR-accurate values
