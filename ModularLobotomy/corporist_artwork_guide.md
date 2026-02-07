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

### Creature Contribution
Larger creatures contribute more materials based on their max health:
| Max Health | Contribution |
|------------|--------------|
| < 100 | 1 |
| 100-499 | 1 |
| 500-999 | 2 |
| 1000-1499 | 3 |
| 1500-1999 | 4 |
| 2000-3999 | 5 |
| 4000+ | 6 |

### Anchoring
Use a **wrench** on artwork to anchor or unanchor it (2 second delay).

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
| 0-5 | F |
| 6-10 | C |
| 11-15 | B |
| 16-20 | A |
| 21+ | S |

### Technique Averaging
The artwork's displayed Technique Grade is the **average of all minigame sessions**. Each refinement shows both your current session grade and the overall average.

### Artist Examine Info
When artists examine artwork, they can see:
- **Tier**: "Tier: 3/5 (6 materials)"
- **Technique Grade**: "Technique: B - Solid technique with clear artistic intent."

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

### Earning EXP (Flat Amounts)
| Activity | XP Gained |
|----------|-----------|
| Creating artwork | +5 XP |
| Adding bodies | +3 XP |
| Refining (F grade) | +5 XP |
| Refining (C grade) | +10 XP |
| Refining (B grade) | +15 XP |
| Refining (A grade) | +25 XP |
| Refining (S grade) | +40 XP |
| **Maestro's grades** | 25-100% of threshold (main source!) |

### Skill Point Thresholds
Levels 1-4 are fast, then progression slows down significantly.

| Total XP | Level | XP to Next |
|----------|-------|------------|
| 30 | 1 | 40 |
| 70 | 2 | 50 |
| 120 | 3 | 60 |
| 180 | 4 | 170 |
| 350 | 5 | 250 |
| 600 | 6 | 350 |
| 950 | 7 | 450 |
| 1400 | 8 | 550 |
| 1950 | 9 | 650 |
| 2600 | 10 | 750 |
| 3350 | 11 | 850 |
| 4200 | 12 | - |

### The Four Schools
You can invest in **up to 2 schools**. Each has 3 tiers of abilities.

**FAUVISTS** - Predatory aggression, bonus damage vs bleeding targets

**POINTILLISTS** - Random status effects, SP healing, scaling power

**CUBISTS** - Area control, bleed zones, spatial effects

**CORPORISTS** - Duality of pain and power, Artistic Synergy bonuses

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

Theme: Duality of pain and power. Inflict negative effects on targets while gaining positive effects. When both occur simultaneously, trigger Artistic Synergy bonuses.

**Core Mechanic - Artistic Synergy:** Your attacks inflict negative effects (bleed) on the target AND grant positive effects (Protection/Damage Up) to you. When both happen, you gain a synergy bonus: SP healing, or an alternative buff if your SP is already full.

#### Tier 1 (1 point) - Choose ONE:

| Skill | Type | Effect |
|-------|------|--------|
| **Butcher - Ribs** | Passive | On Hit: Apply 2 bleed to target and gain 1 Protection. Heal 5% max SP. If at max SP, gain 1 Damage Up instead |
| **Rotator Crush** | Passive | On Hit: Apply 2 bleed to target and gain 1 Damage Up. Heal 5% max SP. If at max SP, gain 1 Protection instead |

#### Tier 2 (2 points) - Choose ONE:

| Skill | Type | Effect |
|-------|------|--------|
| **Repressed Flesh** | Passive (5s CD) | On Hit: If target is bleeding and you have a positive effect, heal 5 HP and apply 2 extra bleed. If target has 10+ bleed, gain 1 extra Protection |
| **Tendon Tear** | Passive | On Hit: If target is bleeding and you have a positive effect, deal 10 bonus RED damage. If you have 3+ Damage Up, deal additional 15 RED damage |

#### Tier 3 (3 points) - Choose ONE:

| Skill | Type | Effect |
|-------|------|--------|
| **Anatomize** | Passive (30s CD) | On Hit: If target is bleeding and below 25% HP, and you have both Protection and Damage Up, consume all bleed for 5 RED damage per stack and fully restore SP |
| **Exhibition Arrangements** | Active (30s CD) | For 8s, attacks apply 3 bleed + 1 random negative effect AND grant 1 Protection + 1 Damage Up. Heal 5% max SP per hit (at max SP: +2 Damage Up). On expiry, consume all bleed on last target for 3 damage per stack |

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
| Anchor/unanchor (wrench) | Anyone |
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
