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

**Basic ATK: Farewell Hit** | Single Target | Energy Generation: 20 | Physical
Deals RED DMG (Physical) equal to **50%—110%** of the USER's ATK to a single enemy.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|-------|-----|-----|-----|-----|-----|-----|-----|
| ATK % | 50% | 60% | 70% | 80% | 90% | 100% | 110% |

**Skill: RIP Home Run** | Blast | Energy Generation: 30 | Physical
Deals RED DMG (Physical) equal to **62.5%—137.5%** of the USER's ATK to a single enemy and enemies adjacent to it.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|------|------|-----|------|------|------|--------|--------|--------|------|--------|--------|
| ATK % | 62.5% | 68.75% | 75% | 81.25% | 87.5% | 93.75% | 101.56% | 109.38% | 117.19% | 125% | 131.25% | 137.5% |

**Ultimate: Stardust Ace** | Enhance | Energy Cost: 120 | Physical
Choose between two attack modes to deliver a full strike.
- **Blowout: Farewell Hit** — Deals RED DMG (Physical) equal to **300%—480%** of ATK to a single enemy.
- **Blowout: RIP Home Run** — Deals RED DMG (Physical) equal to **180%—288%** of ATK to a single enemy, and RED DMG (Physical) equal to **108%—172.8%** of ATK to enemies adjacent to it.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|------|------|------|------|------|------|--------|--------|--------|------|------|------|
| Blowout: FH | 300% | 315% | 330% | 345% | 360% | 375% | 393.75% | 412.5% | 431.25% | 450% | 465% | 480% |
| Blowout: RIP (main) | 180% | 189% | 198% | 207% | 216% | 225% | 236.25% | 247.5% | 258.75% | 270% | 279% | 288% |
| Blowout: RIP (adj) | 108% | 113.4% | 118.8% | 124.2% | 129.6% | 135% | 141.75% | 148.5% | 155.25% | 162% | 167.4% | 172.8% |

**Passive: Perfect Pickoff** | Enhance
Each time after this character kills an enemy, ATK increases by **10%—22%**. Stacks up to **2** times.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|-----|-----|-----|-----|-----|-----|-------|-------|-------|-----|-----|-----|
| ATK % buff | 10% | 11% | 12% | 13% | 14% | 15% | 16.25% | 17.5% | 18.75% | 20% | 21% | 22% |

#### Scaling Notes
- Basic ATK has **7 levels**, Skill/Ultimate/Passive have **12 levels**
- All damage uses **avg coeff** (average of all 4 damage coefficients) with **Physical** elemental type
- Ultimate enhances the next Basic ATK or Skill rather than being a standalone attack
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
- **Strengths:** Highest single-target burst, DEF shred on crit, conditional Ult bonus, RES PEN from ally support

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

**Stat Comparison vs Destruction at Lv80:** ATK 546 vs 620 (-12%), DEF 396 vs 460 (-14%), HP 882 vs 1203 (-27%). The Hunt has lower raw stats but compensates with much higher ability multipliers and DEF shred.

#### Abilities

**Basic ATK: Cloudlancer Art: North Wind** | Single Target | Energy Generation: 20 | Wind
Deals RED DMG (Wind) equal to **50%—110%** of the USER's ATK to a single enemy.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|-------|-----|-----|-----|-----|-----|-----|-----|
| ATK % | 50% | 60% | 70% | 80% | 90% | 100% | 110% |

**Skill: Cloudlancer Art: Torrent** | Single Target | Energy Generation: 30 | Wind
Deals RED DMG (Wind) equal to **130%—286%** of the USER's ATK to a single enemy.
When DMG dealt by Skill triggers a **CRIT Hit**, there is a **100% base chance** to reduce the target's DEF by **12%** for **2 turns**.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|------|------|------|------|------|------|--------|--------|--------|------|------|------|
| ATK % | 130% | 143% | 156% | 169% | 182% | 195% | 211.25% | 227.5% | 243.75% | 260% | 273% | 286% |

**Ultimate: Ethereal Dream** | Single Target | Energy Cost: 100 | Energy Generation: 5 | Wind
Deals RED DMG (Wind) equal to **240%—432%** of the USER's ATK to a single target enemy.
If the attacked enemy has their **DEF reduced**, the multiplier for DMG dealt by Ultimate increases by **72%—129.6%**.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|------|------|------|------|------|------|------|------|------|------|------|------|
| Base ATK % | 240% | 256% | 272% | 288% | 304% | 320% | 340% | 360% | 380% | 400% | 416% | 432% |
| DEF-down bonus | 72% | 76.8% | 81.6% | 86.4% | 91.2% | 96% | 102% | 108% | 114% | 120% | 124.8% | 129.6% |

*With DEF-down active, Ultimate multiplier = Base + Bonus (e.g. Lv1: 240% + 72% = 312%, Lv12: 432% + 129.6% = 561.6%)*

**Talent: Superiority of Reach** | Enhance
When the user becomes the target of an ally's ability, their next attack's **Wind RES PEN** increases by **18%—39.6%**. This effect can be triggered again after **2 turns**.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|-----|------|------|------|------|-----|-------|-------|-------|-----|------|------|
| RES PEN | 18% | 19.8% | 21.6% | 23.4% | 25.2% | 27% | 29.25% | 31.5% | 33.75% | 36% | 37.8% | 39.6% |

#### Scaling Notes
- Basic ATK has **7 levels**, Skill/Ultimate/Talent have **12 levels**
- All damage uses **avg coeff** (average of all 4 damage coefficients) with **Wind** elemental type
- Skill's DEF shred only triggers on **CRIT hits** — CRIT Rate is essential for this path
- Ultimate has a huge conditional bonus when target has DEF reduced (Skill crit -> Ult combo)
- Talent introduces **Wind RES PEN** — reduces enemy's Wind resistance (elemental layer, not LC13 avg coeff)
- Ultimate generates **5 energy** (unlike Destruction's 0), giving slight energy cycling
- Energy cost is **100** (vs Destruction's 120), so Ult charges faster

#### Gameplay Loop
```
1. Ally buffs/targets the Hunt user -> Talent triggers (Wind RES PEN on next attack)
2. Use Skill (Cloudlancer Art: Torrent) on boss
   -> If CRIT: applies 12% DEF reduction for 2 turns
   -> RES PEN from Talent applied on this hit
3. Build to 100 energy via Basic ATK (20) + Skill (30) hits
4. Use Ultimate (Ethereal Dream) on DEF-reduced boss
   -> Base 432% + 129.6% bonus = 561.6% ATK at max level
   -> Massively amplified single-target nuke
5. Repeat: Skill to maintain DEF shred, Ult when ready
```

#### Key Differences from Destruction
| Aspect | Destruction | The Hunt |
|--------|-------------|---------|
| Element Type | Physical | Wind |
| Target Profile | Flexible (AoE Skill, single Ult) | Pure single-target specialist |
| Skill Scaling | 62.5%—137.5% (Blast/AoE) | 130%—286% (Single, 2x+ higher) |
| Ult Scaling | 300%—480% (Enhance, buffs next attack) | 240%—432% base, up to 561.6% conditional |
| Ult Energy Cost | 120 | 100 |
| Ult Energy Gen | 0 | 5 |
| Passive/Talent | Kill-stacking ATK buff (self-reliant) | Ally-dependent Wind RES PEN (team synergy) |
| DEF Interaction | None | Skill crits shred DEF, Ult punishes DEF-down |
| Best Against | Groups, RED-weak mobs | Single bosses, Wind-weak mobs |

---

### Erudition (Aeon: Nous)
> *Thoughtful, logical, and strategic actions are manifestations of the Path of Erudition.*

**Gameplay Role:** Deals remarkable amounts of multi-target damage. The main damage dealer against groups of enemies.

- **Archetype:** AoE specialist / Execute finisher
- **Strengths:** AoE damage on every ability, execute mechanic on low-HP enemies, follow-up ATK on HP threshold triggers, self-ATK buff from Ultimate
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

Erudition has moderate stats — higher ATK than Hunt but lower than Destruction. DEF matches Hunt. HP sits between the two. Compensated by AoE on every ability and execute/follow-up mechanics.

#### Abilities

**Basic ATK: What Are You Looking At?** | Single Target | Energy Generation: 20 | Ice
Deals Ice DMG equal to **50%—110%** of USER's ATK to a single enemy. If the enemy's HP is at **50% or less**, deals additional Ice DMG equal to **40%** of USER's ATK. This bonus also triggers if the Basic ATK causes the enemy's HP to fall to 50% or lower.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|-------|-----|-----|-----|-----|-----|-----|-----|
| ATK % | 50% | 60% | 70% | 80% | 90% | 100% | 110% |
| Execute bonus | 40% | 40% | 40% | 40% | 40% | 40% | 40% |

*Execute bonus is flat 40% ATK at all levels. Effective scaling when triggered: 90%—150% ATK.*

**Skill: One-Time Offer** | AoE | Energy Generation: 30 | Ice
Deals Ice DMG equal to **50%—110%** of USER's ATK to **all enemies**. If the enemy's HP is at **50% or higher**, DMG dealt to that target increases by **25%**.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|-----|-----|-----|------|------|------|--------|--------|--------|------|------|------|
| ATK % | 50% | 55% | 60% | 65% | 70% | 75% | 81.25% | 87.5% | 93.75% | 100% | 105% | 110% |

*With 25% high-HP bonus active: 62.5%—137.5% effective.*

**Ultimate: It's Magic, I Added Some Magic** | AoE | Energy Cost: 110 | Energy Generation: 5 | Ice
Deals Ice DMG equal to **120%—216%** of USER's ATK to **all enemies**. After using the Ultimate, increases USER's ATK by **25%** for 1 turn.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|------|------|------|------|------|------|------|------|------|------|------|------|
| ATK % | 120% | 128% | 136% | 144% | 152% | 160% | 170% | 180% | 190% | 200% | 208% | 216% |

*ATK buff (25%) applies after the Ultimate's damage, boosting subsequent attacks for 1 turn.*

**Talent: Fine, I'll Do It Myself** | AoE Follow-up | Energy Generation: 5
When **any ally's or the user's** attack causes an enemy's HP to fall to **50% or lower**, USER launches a Follow-up ATK dealing Ice DMG equal to **25%—43%** of USER's ATK to **all enemies**.

| Level | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|-------|-----|------|-----|------|-----|------|--------|--------|--------|-----|------|-----|
| ATK % | 25% | 26.5% | 28% | 29.5% | 31% | 32.5% | 34.375% | 36.25% | 38.125% | 40% | 41.5% | 43% |

*Triggers on ANY ally hitting the HP threshold, not just the user. AoE follow-up hits all enemies, not just the trigger target. Generates 5 energy per trigger.*

#### Scaling Notes
- Basic ATK has **7 levels**, Skill/Ultimate/Talent have **12 levels**
- All damage uses **avg coeff** (average of all 4 damage coefficients) with **Ice** elemental type
- Basic ATK has a built-in **execute mechanic** — flat +40% ATK bonus damage when target is at or drops to ≤50% HP
- Skill has the **opposite** conditional — +25% DMG when target is ≥50% HP (anti-synergy with Basic, encourages alternating)
- Talent triggers off **any ally's** attacks, not just the user's — scales with team size and AoE attacks
- Talent follow-up is AoE, hitting all enemies — powerful in multi-target fights
- Ultimate costs **110 energy** (highest so far: Destruction 120, Hunt 100)
- Ultimate generates **5 energy** and grants a **25% ATK self-buff** for 1 turn after use
- No RES PEN in kit — relies on raw AoE volume and execute damage

#### Gameplay Loop
```
1. Open with Skill (One-Time Offer) on full-HP group
   -> 50%-110% ATK to ALL enemies
   -> +25% bonus since enemies are above 50% HP
   -> Effective: 62.5%-137.5% ATK to all
2. Basic ATK weaker enemies to push them below 50% HP
   -> Execute bonus: +40% ATK on targets at/below 50%
   -> Each threshold cross triggers Talent follow-up
3. Talent (Fine, I'll Do It Myself) auto-triggers:
   -> 25%-43% ATK AoE to ALL enemies per trigger
   -> Can chain: if follow-up pushes another enemy to 50%,
      does NOT re-trigger (prevents infinite loops)
4. Build to 110 energy via Basic (20) + Skill (30) + Talent (5)
5. Ultimate (It's Magic) on all enemies
   -> 120%-216% ATK AoE nuke
   -> Grants 25% ATK buff for 1 turn
   -> Follow-up attacks in that turn are boosted
6. Repeat: Skill (high HP enemies) -> Basic (low HP) -> Ult
```

#### Key Differences from Other Paths
| Aspect | Destruction | The Hunt | Erudition |
|--------|-------------|----------|-----------|
| Element | Physical | Wind | Ice |
| Target Profile | Flexible | Single-target | AoE specialist |
| Basic ATK | 50-110% single | 50-110% single | 50-110% single + 40% execute |
| Skill | 62.5-137.5% Blast | 130-286% single | 50-110% AoE (all enemies) |
| Ult Scaling | 300-480% (Enhance) | 240-432% (+129.6% conditional) | 120-216% AoE (all enemies) |
| Ult Energy Cost | 120 | 100 | 110 |
| Ult Energy Gen | 0 | 5 | 5 |
| Passive/Talent | Kill-stacking ATK | Ally-triggered RES PEN | HP-threshold AoE follow-up |
| Unique Mechanic | Enhance next attack | DEF shred on crit | Execute + anti-execute conditionals |
| Best Against | Groups + RED-weak | Bosses + Wind-weak | Large groups + Ice-weak |

---

### Harmony (Aeon: Xipe)
> *Understanding, supportive, and cooperative actions are manifestations of the Path of Harmony.*

**Gameplay Role:** Applies buffs to allies to improve the team's combat capacities.

- **Archetype:** Buffer / Force multiplier
- **Strengths:** Empowering allies, stat boosts, team synergy
- **Basic Attack:** Hits grant a small ATK buff to the user and nearby allies
- **Burst:** Apply a significant buff (ATK up, CRIT up, or damage bonus) to allies in range
- **Ultimate:** Team-wide empowerment granting multiple stat boosts and temporary ability enhancement
- **Passive:** Nearby allies passively gain a small stat bonus (aura effect)

---

### Nihility (Aeon: IX)
> *Slothful, exhausted, and meaningless actions are manifestations of the Path of Nihility.*

**Gameplay Role:** Applies debuffs to enemies to reduce their combat capacities.

- **Archetype:** Debuffer / Crowd control specialist
- **Strengths:** Weakening enemies, reducing defenses, applying status effects
- **Basic Attack:** Hits apply a stacking debuff (DEF down, slow, or damage vulnerability)
- **Burst:** Apply a significant debuff to enemies in range (e.g. reduce all stats, apply weakness)
- **Ultimate:** Devastating debuff field that cripples all enemies in a large area
- **Passive:** Enemies near the user have reduced stats (oppressive aura)

---

### Preservation (Aeon: Qlipoth)
> *Patient, sacrificial, and protective actions are manifestations of the Path of Preservation.*

**Gameplay Role:** Possesses powerful defensive abilities to protect allies in various ways.

- **Archetype:** Tank / Shielder / Protector
- **Strengths:** Damage mitigation, shielding allies, aggro management
- **Basic Attack:** Hits generate a small shield on the user
- **Burst:** Create a barrier/shield on the user and nearby allies absorbing incoming damage
- **Ultimate:** Massive shield on all allies + damage reduction for a duration
- **Passive:** When an ally nearby takes lethal damage, redirect a portion to the user instead (guardian instinct)

---

### Abundance (Aeon: Yaoshi)
> *Selfless, altruistic, and healing actions are manifestations of the Path of Abundance.*

**Gameplay Role:** Heals allies and restores HP to the team.

- **Archetype:** Healer / Sustain support
- **Strengths:** HP restoration, cleansing, keeping the team alive
- **Basic Attack:** Hits heal the user for a small amount
- **Burst:** Heal a nearby ally (or self) for a significant amount
- **Ultimate:** Full team heal restoring a large percentage of max HP to all nearby allies
- **Passive:** Allies near the user passively regenerate HP over time (rejuvenating aura)

---

## Core Mechanics

### Energy System
- Every path has an **Energy** meter (0 to `max_energy`, default 100)
- Energy is gained by:
  - Landing melee hits (Basic Attack): +10 energy per hit (default)
  - Using Burst Action: +20 energy per use (default)
- Energy is spent by:
  - Ultimate Action: requires `energy >= max_energy`, resets energy to 0
- Energy amounts vary by path (some have higher max energy, different gain rates)

### Action Points (AP)
- Every path has **Action Points** (0 to `max_action_points`, default 5)
- AP is gained by:
  - Landing melee hits: +1 AP per hit
- AP is spent by:
  - Burst Action: costs 1 AP per use (default)
- AP has a hard cap and does not exceed `max_action_points`

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
| Harmony | TBD |
| Nihility | TBD |
| Preservation | TBD |
| Abundance | TBD |

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
- Ascension requires materials and credits (costs TBD per path)
- Leveling source TBD (EXP from combat, quest rewards, etc.)

### Skill Points
- Used to unlock nodes in the skill tree
- Source of skill points TBD (could be from leveling, quest rewards, etc.)
- Each node costs a set number of SP (default 1)

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
              +-- /datum/action/path_burst     (HUD button)
              +-- /datum/action/path_ultimate  (HUD button)
              +-- /datum/action/path_screen    (HUD button -> TGUI)
```

---

## File Map

| Design Doc | Implements | Description |
|-----------|------------|-------------|
| `_path_defines.md` | `_path_defines.dm` | Constants, signal defines |
| `_path_datum.md` | `_path_datum.dm` | `/datum/path` + `/datum/path_ability` hierarchy |
| `_path_node.md` | `_path_node.dm` | `/datum/path_node` skill tree nodes |
| `_path_actions.md` | `_path_actions.dm` | Action button datums (Burst, Ultimate, Screen) |
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

// Action Button References
var/datum/action/path_burst/burst_action_button
var/datum/action/path_ultimate/ultimate_action_button
var/datum/action/path_screen/screen_action_button
```

**Procs:**
| Proc | Description |
|------|-------------|
| `New()` | Calls `InitNodes()` to set up the skill tree |
| `InitNodes()` | Virtual. Subtypes populate `nodes` list |
| `AssignTo(mob/living/carbon/human/user)` | Attach path to mob, instantiate abilities, register signals, grant actions |
| `Remove()` | Detach path, unregister signals, remove actions, clean up |
| `GainEnergy(amount)` | +energy clamped to max, signal + button update |
| `SpendEnergy(amount)` | -energy clamped to 0, signal + button update |
| `GainActionPoint()` | +1 AP clamped to max, signal + button update |
| `SpendActionPoint()` | -1 AP clamped to 0, signal + button update |
| `GetStat(stat_name)` | Returns computed stat + sum of unlocked node bonuses |
| `SetLevel(new_level)` | Set path level, recalculate stats via interpolation |
| `Ascend()` | Increase ascension phase, raise level cap |
| `RecalculateStats()` | Interpolate stats from stat_table based on level/phase |
| `UnlockNode(node_id)` | Unlock a skill tree node if prereqs met and SP available |
| `OnMeleeAttack(source, target, user)` | `SIGNAL_HANDLER` for `COMSIG_MOB_ITEM_ATTACK` |
| `ProcessMeleeHit(target, user)` | Timer callback that invokes `basic_attack.OnHit()` |
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
Triggered on melee hit via signal handler. Tags: Single Target, Blast, etc.
```
var/energy_gain = 20           // Energy generated per hit (varies by path)
proc/OnHit(mob/living/target, mob/living/user)  // Virtual
```
Typical max_level: **7**

### `/datum/path_ability/burst` (Skill)
Activated via action button. Costs AP, grants energy. Tags: Blast, Bounce, Imprison, etc.
```
var/energy_gain = 30           // Energy generated on use (varies by path)
var/ap_cost = 1
proc/Activate(mob/living/user) // Virtual
```
Typical max_level: **12**

### `/datum/path_ability/ultimate`
Activated via action button. Requires full energy, resets to 0. Can be standalone damage OR an **Enhance** that buffs the next Basic/Skill.
```
proc/Activate(mob/living/user) // Virtual, calls SpendEnergy in base
```
Typical max_level: **12**. Energy cost varies by path (e.g. Destruction = 120).

**Enhance-type Ultimates:** Instead of dealing damage directly, they set an `enhanced` flag on the path. The next Basic ATK or Skill checks this flag and uses the Ultimate's scaling instead of its own. After one enhanced attack, the flag resets.

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

## Action Buttons

### `/datum/action/path_burst`
- Trigger checks `AP >= ap_cost`
- Calls `SpendActionPoint()`, `GainEnergy()`, then `burst_action.Activate()`
- Shows AP count or grays out when insufficient

### `/datum/action/path_ultimate`
- Trigger checks `energy >= max_energy`
- Calls `ultimate_action.Activate()` (which spends energy internally)
- Glows/highlights when energy is full

### `/datum/action/path_screen`
- Trigger calls `linked_path.ui_interact(owner)` to open the TGUI

All three store a `var/datum/path/linked_path` reference set during `AssignTo()`.

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
MELEE HIT:
  Player hits mob with weapon
  -> COMSIG_MOB_ITEM_ATTACK fires
  -> /datum/path/OnMeleeAttack() [SIGNAL_HANDLER]
     -> addtimer(CALLBACK -> ProcessMeleeHit) [escapes sleep restriction]
     -> GainEnergy(basic_attack.energy_gain)   [+10 default]
     -> GainActionPoint()                      [+1]
  -> ProcessMeleeHit()
     -> basic_attack.OnHit(target, user)       [subtype deals bonus damage]

BURST ACTION:
  Player clicks Burst button
  -> /datum/action/path_burst/Trigger()
  -> Check: AP >= burst_action.ap_cost
  -> SpendActionPoint()                        [-1]
  -> GainEnergy(burst_action.energy_gain)      [+20 default]
  -> burst_action.Activate(user)               [subtype does unique action]

ULTIMATE ACTION:
  Player clicks Ultimate button
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
| **Signals** | Uses existing `COMSIG_MOB_ITEM_ATTACK` and `COMSIG_MOB_APPLY_DAMGE` (note: existing typo in codebase) |
| **Damage** | Path damage bypasses per-color routing; uses average of all 4 `damage_coeff` values as resistance. Elemental type (Physical/Wind/etc.) is a separate layer for path effects |
| **LC13 Attributes** | Path stats are SEPARATE. LC13 attributes (Fortitude/Prudence/Temperance/Justice) displayed in UI for reference and can optionally be read via `get_modified_attribute_level()` for hybrid scaling |
| **EGO Weapons** | Path basic attack triggers on ANY melee weapon hit, including EGO weapons |
| **Actions** | Standard `/datum/action` system for HUD buttons |
| **TGUI** | Standard `SStgui` pattern |
| **Timer** | Uses `addtimer(CALLBACK(...), 0)` to escape `SIGNAL_HANDLER` sleep restrictions |
| **Components** | Uses `/datum/component` for clean mob attachment/detachment |

---

## Defines Quick Reference

```dm
// Resource defaults
#define PATH_MAX_ENERGY_DEFAULT 100
#define PATH_MAX_AP_DEFAULT     5

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
4. `_path_actions.dm` - Action button datums
5. `_path_component.dm` - Component + helper procs on mob
6. `_path_ui.dm` - DM-side TGUI procs
7. `PathScreen.js` - React TGUI interface
8. DME includes
9. Example path subtype for end-to-end testing

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
    desc = "Choose between two enhanced attack modes."
    max_level = 12
    /// Blowout: Farewell Hit scaling (single target)
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
            // Enhanced single-target Farewell Hit
            var/damage = atk * (blowout_fh[level] / 100)
            // Deal to target in front of user
            // ...
        if("rip")
            // Enhanced RIP Home Run (main + adjacent)
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
- **Ultimate is an Enhance** — it buffs the NEXT Basic ATK or Skill, not a standalone attack. The path needs to track an `enhanced` state that the basic/burst abilities check.
- **Basic ATK has 7 max levels**, Skill/Ultimate/Passive have **12 max levels**
- **All damage uses avg coeff** (average of all 4 LC13 damage coefficients)
- **Passive stacks reset** on path removal or death
- **Ability scaling** stored as lists indexed by level for exact HSR-accurate values
