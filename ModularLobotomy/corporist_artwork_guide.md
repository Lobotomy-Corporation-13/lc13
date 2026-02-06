# The Ring's Corporist School - Player Guide

## What is this?

The Corporist Maestro is a trusted player role from **The Ring** syndicate. Corporists create disturbing artwork from flesh and bone, believing that true art reflects the human condition through suffering.

---

## Roles

### Corporist Maestro
The master artist. Can create artwork, judge others' work, inspire new artists, and grant/reset skill points.

### Corporist Apprentice
The Maestro's chosen pupil. Starts with 4 skill points and will get some pretty cool gear

### Student
A permanent artist who earned their status through dedication. Starts with 0 skill points but can earn them through grades.

### Inspired Artist
A temporary status (10 minutes) granted by watching a Maestro's demonstration. Create 6 artworks to become a permanent Student.

---

## Creating Artwork

### Who Can Create Art?
- Maestro, Apprentice, Students, and Inspired players

### How to Create
1. Find a **dead simple mob** (mice, bots, sweepers, etc.)
2. Use your **"Create Artwork"** or **"Sculpt Corpse"** action while next to it
3. Wait for the channeling to complete
4. A crude sculpture is created from the remains

### Enhancing Artwork
You can add more materials to increase an artwork's tier:

- **Hit the artwork with a bodypart** to incorporate it
- **Drag a dead creature onto the artwork** to add its remains

After adding anything, you must **refine** the artwork before adding more.

### Artwork Tiers
| Tier | Materials Needed | Name |
|------|------------------|------|
| 1 | 1 | Crude Sculpture |
| 2 | 2-3 | Developing Piece |
| 3 | 4-6 | Refined Work |
| 4 | 7-10 | Masterpiece |
| 5 | 11+ | Magnum Opus |

---

## The Sculpting Minigame

When you click an artwork that needs refinement, you'll play a timing minigame.

### How It Works
1. A **needle** sweeps back and forth across a bar
2. **Green zones** are your targets - click when the needle is inside
3. **Bright centers** give "PERFECT" hits for more points
4. Complete **6 rounds** to finish

### Scoring
| Hit | Points |
|-----|--------|
| PERFECT | +3 |
| Good | +2 |
| Okay | +1 |
| Miss | -1 |

### Combos
Hit consecutive Perfect/Good to build combos:
- 3+ combo = x1.5 multiplier
- 5+ combo = x2 multiplier
- Miss resets your combo!

### Grades
Your final score determines your **Technique Grade**:
| Score | Grade |
|-------|-------|
| 0-3 | F |
| 4-7 | C |
| 8-11 | B |
| 12-15 | A |
| 16+ | S |

---

## Examining Artwork

### For Non-Artists
Looking at artwork **damages your sanity**. Higher tier = more damage.

### For Artists
Looking at artwork **heals your sanity**. Appreciate the craftsmanship!

---

## Maestro's Judgment

The Maestro can **judge any artwork** and assign a Final Grade (F through S).

### What Grades Mean for You
| Grade | Effect |
|-------|--------|
| S | +100% EXP toward next skill point! |
| A | +50% EXP |
| B | +25% EXP |
| C | -25% EXP |
| F | -50% EXP |

**Seek the Maestro's approval carefully** - poor work is punished!

---

## Ring Skill Tree

As you earn Artistic EXP, you unlock **skill points** to spend on combat abilities.

### Earning EXP
- Creating artwork: +3% of next threshold
- Adding bodies: +2% of next threshold
- Refining artwork: +3-5% of next threshold
- **Maestro's grades**: 25-100% (the main source!)

### Skill Point Thresholds
| Total EXP | Skill Points |
|-----------|--------------|
| 50 | 1 |
| 150 | 2 |
| 300 | 3 |
| 500 | 4 |
| 750 | 5 |
| 1050 | 6 |
| 1400 | 7 |
| 1800 | 8 |

### The Four Schools
You can invest in **up to 2 schools**. Each has 3 tiers of abilities.

**FAUVISTS** - Predatory aggression, bonus damage vs bleeding targets

**POINTILLISTS** - Random status effects, SP healing, scaling power

**CUBISTS** - Area control, bleed zones, spatial effects

**CORPORISTS** - Build up bleed, then trigger for massive damage

---

## Detailed Skill List

All skills interact with the `lc_bleed` status effect.

### FAUVISTS
*"Those who use primary colors and complex lines. Known to wear animal masks."*

Theme: Predatory aggression, WHITE/SP damage. The beast tears at both body and mind.

#### Tier 1 (1 point) - Choose ONE:

| Skill | Type | Effect |
|-------|------|--------|
| **Predator's Scent** | Passive | +15% damage vs bleeding targets |
| **Maddening Maw** | Passive | Attacks on bleeding targets deal 15% of your melee damage as additional WHITE damage |

#### Tier 2 (2 points) - Choose ONE:

| Skill | Type | Effect |
|-------|------|--------|
| **Rending Claws** | Passive | Your attacks apply 2 bleed stacks |
| **Savage Instinct** | Passive | After hitting a bleeding target, gain +15% damage for 4 seconds (refreshes on hit) |

#### Tier 3 (3 points) - Choose ONE:

| Skill | Type | Effect |
|-------|------|--------|
| **Spreading Wounds** | Passive | When hitting a bleeding target, adjacent enemies gain 3 bleed stacks |
| **Primal Terror** | Passive | Hitting targets with 10+ bleed deals 20 WHITE damage and removes 5 bleed stacks |

---

### POINTILLISTS
*"Those who use small strokes and dots to depict light. Known to wield paintbrush weapons."*

Theme: Random status effects, SP recovery, scaling power. Each "dot" of affliction is a splash of color.

**Random Effect Pool:** Bleed, Overheat, Tremor, Mental Decay

#### Tier 1 (1 point) - Choose ONE:

| Skill | Type | Effect |
|-------|------|--------|
| **Hematic Coloring** | Passive | Attacks apply 3 stacks of a random effect. If target already has that effect, deal +10% damage instead |
| **Sanguine Pointillism** | Passive | Attacks apply 1 stack of TWO random effects. Heal 2 SP when applying an effect the target didn't have |

#### Tier 2 (2 points) - Choose ONE:

| Skill | Type | Effect |
|-------|------|--------|
| **Assignment Evaluation** | Passive | Heal 5 SP when hitting targets, +3 SP per status effect on them |
| **Beat the Brush** | Passive | +5% damage per status effect on target (max 20% at 4 effects) |

#### Tier 3 (3 points) - Choose ONE:

| Skill | Type | Effect |
|-------|------|--------|
| **Paint Over** | Passive | Random effects now apply 2x stacks; 10% chance to apply ALL four effects at once |
| **Practices on Aesthetics** | Passive | +10% damage and +2 bleed per status effect on target |

---

### CUBISTS
*"Those who incorporate abstract three-dimensionality and depth."*

Theme: Area control, spatial manipulation. Command the battlefield through bleeding zones.

#### Tier 1 (1 point) - Choose ONE:

| Skill | Type | Effect |
|-------|------|--------|
| **Fractured Reflection** | Passive | Attackers gain 3 bleed stacks when hitting you |
| **Geometric Reach** | Passive | Your attacks apply 2 bleed to enemies adjacent to your target |

#### Tier 2 (2 points) - Choose ONE:

| Skill | Type | Effect |
|-------|------|--------|
| **Abstract Suffering** | Passive | Attacks against bleeding targets deal bonus WHITE damage equal to (bleed stacks x 2) |
| **Warped Space** | Passive | Hitting targets with 8+ bleed stacks inflicts 20% slowdown for 3 seconds |

#### Tier 3 (3 points) - Choose ONE:

| Skill | Type | Effect |
|-------|------|--------|
| **Spatial Anchor** | Passive | Enemies within 4 tiles cannot have their bleed reduced below 5 stacks |
| **Crimson Dimension** | Active (60s CD) | Create 3x3 zone applying 2 bleed/sec for 10s; you take 20% less damage while inside |

---

### CORPORISTS
*"Those who utilize human bones and muscles, contraction and elongation."*

Theme: Simple and direct. Build up bleed, then trigger it for devastating damage.

#### Tier 1 (1 point) - Choose ONE:

| Skill | Type | Effect |
|-------|------|--------|
| **Opening Wounds** | Passive | When off cooldown, next attack applies 8 bleed (20s CD). While on cooldown, attacks apply 1 bleed |
| **Exposed Veins** | Passive | +3% damage per bleed stack on target (max 30% at 10 stacks) |

#### Tier 2 (2 points) - Choose ONE:

| Skill | Type | Effect |
|-------|------|--------|
| **Sanguine Absorption** | Passive (5s CD) | Heal 5 HP when attacking a bleeding target |
| **Rupture** | Passive | Hitting targets with 15+ bleed consumes 10 stacks to deal 40 bonus RED damage |

#### Tier 3 (3 points) - Choose ONE:

| Skill | Type | Effect |
|-------|------|--------|
| **Vivisection** | Passive (30s CD) | Hitting bleeding targets below 20% HP deals 100 bonus RED damage |
| **Exsanguinate** | Active (30s CD) | Buff your weapon for 10s. Next hit consumes ALL bleed on target, dealing 5 damage per stack |

---

### Skill Costs
- Tier 1: 1 point
- Tier 2: 2 points
- Tier 3: 3 points

Each tier has 2 choices - pick one, the other locks forever.

---

## Becoming a Student

If you're **Inspired** (from watching a demonstration):

1. Create artworks to gain progress
2. At 6 progress, you become a permanent **Student**
3. As a Student, you can access the skill tree and earn EXP

---

## Custom Descriptions

Artists can write custom descriptions for their artwork:
- Use the **"Describe Artwork"** action
- Write up to 300 characters
- The Maestro can override any description

---

## Quick Reference

| Action | Who Can Do It |
|--------|---------------|
| Create artwork | All artists |
| Enhance artwork | All artists |
| Refine (minigame) | All artists |
| Describe artwork | Creator or Maestro |
| Judge artwork | Maestro only |
| Demonstrate (inspire others) | Maestro only |
| Reset skill tree | Maestro only |

---

## Tips

1. **Get graded often** - The Maestro's grades are your main EXP source
2. **Practice the minigame** - Higher technique grades look better to the Maestro
3. **Choose your schools wisely** - You can only pick 2 out of 4
4. **Work together** - Anyone can enhance artwork, collaborate with others
5. **Don't let non-artists examine your work** - It damages their sanity!
