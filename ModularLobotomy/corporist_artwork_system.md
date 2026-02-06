# Corporist Artwork System - Design Document

## Overview
The Corporist Maestro can create fleshy artworks from the corpses of simple animals (abnormalities, etc.). This system reflects the Ring's artistic philosophy of creating art that reflects the human condition through exhibiting suffering.

---

## Core Mechanics

### 1. Artwork Creation
The Maestro can interact with dead `/mob/living/simple_animal` bodies to begin sculpting them into artwork.

**Process:**
- Maestro uses an action/ability on a dead simple_animal corpse
- A channeled action begins (several seconds of sculpting)
- On completion, the corpse is consumed and an `/obj/structure/corporist_artwork` is created
- The artwork tier depends on the corpse used (bigger/stronger mobs = better base art)

**Requirements:**
- Target must be a dead `/mob/living/simple_animal`
- Maestro must not be interrupted during channeling
- Maestro must be adjacent to the corpse

### 2. Artwork Enhancement
Existing artworks can be enhanced by adding bodyparts or corpses directly.

**Adding Bodyparts (attackby):**
- Hit the artwork with an `/obj/item/bodypart` to incorporate it
- The bodypart is consumed and tracked in the artwork
- Message: *"You carefully incorporate the [bodypart] into your work..."*

**Adding Corpses (buckle):**
- Drag a dead `/mob/living/simple_animal` onto the artwork to buckle it
- A channeled action begins (3-5 seconds)
- On completion, the corpse is gibbed and ALL its bodyparts are added to the artwork
- Message: *"You incorporate [mob]'s remains into the artwork..."*

**Refinement Requirement:**
- After adding ANY body/bodypart, the artwork enters an "unrefined" state
- You MUST refine the artwork (via the Sculpting Minigame) before adding more
- Attempting to add more while unrefined: *"The artwork needs refinement before more can be added."*

**Who Can Enhance:**
- Maestro, Apprentice, Students, and Inspired players can all add to artworks
- You don't need to be the original creator to enhance an artwork

**Tiers:**
| Tier | Bodies Required | Name | Description |
|------|-----------------|------|-------------|
| 1 | 1 | "Crude Sculpture" | A basic arrangement of flesh and bone. The artist's vision is barely visible. |
| 2 | 2-3 | "Developing Piece" | Multiple forms intertwined. The artwork begins to take shape. |
| 3 | 4-6 | "Refined Work" | A disturbing yet captivating arrangement. Clear artistic intent. |
| 4 | 7-10 | "Masterpiece" | A horrifying opus of flesh and bone. Those who gaze upon it feel... something. |
| 5 | 11+ | "Magnum Opus" | A transcendent work of corporeal art. It seems almost alive. |

### 3. Demonstration System
The Maestro can perform a "demonstration" on a corpse to teach others the art of flesh-sculpting.

**Process:**
- Maestro uses special "Demonstrate Artistry" action on a dead simple_animal
- Extended channel time (longer than normal artwork creation)
- Visual and audio feedback during the demonstration
- On completion:
  - The corpse is gibbed dramatically
  - All living mobs within view range receive the "Inspired Artist" status
  - "Inspired Artist" grants temporary ability to create Tier 1 artworks

**"Inspired Artist" Status:**
- Duration: 10-15 minutes (configurable)
- Grants a temporary action to create basic artworks
- Inspired players can only create Tier 1 artworks (no enhancement)
- Cannot perform demonstrations themselves
- Visual indicator (overlay or status effect)

**Becoming a Student:**
Inspired players can become permanent Students through dedication:
- Track "artistic progress" for each inspired player
- Progress gained by:
  - Creating artworks (+1 progress per artwork)
  - Enhancing/upgrading artworks (+2 progress per tier gained)
  - Successfully completing refinement minigames (+1-3 progress based on performance)
- At 10 progress: Gain permanent "Student" status
- Students can:
  - Create artworks without time limit
  - Enhance artworks up to Tier 3 (not Masterpiece/Magnum Opus - reserved for Maestro)
  - Access the Refinement minigame
  - Still cannot perform demonstrations

### 4. Sculpting Minigame (TGUI)
Artists (Maestro, Apprentice, or Student) can interact with artworks to "refine" them through a TGUI timing minigame.

**Triggering:**
- Click/interact with an artwork you have permission to refine
- Opens the "Sculpting" TGUI panel
- Maestro is immobilized while sculpting

**Minigame Concept: "Sculpting"**
Based on Callisto's philosophy: *"The harder the material is to work with, the more exciting it becomes when I've finally tamed it as my own."*

A timing-based minigame representing the delicate work of flesh-sculpting:

```
┌─────────────────────────────────────────────────────────┐
│                    SCULPTING                            │
│                                                         │
│  ══════════════════════════════════════════════════    │
│  ░░░░░░░░░░░███░░░░░░░░░░░░███░░░░░░░░███░░░░░░░░░░    │
│  ══════════════════════════════════════════════════    │
│                    ▲                                    │
│                 (needle)                                │
│                                                         │
│  Round: 3/6          Score: 7          Best Combo: 2   │
│                                                         │
│  [Click or Press Space to Sculpt]                      │
└─────────────────────────────────────────────────────────┘
```

**Core Mechanics:**

1. **The Bar**: A horizontal bar with multiple "sweet spots" (green zones)
   - Sweet spots vary in size based on difficulty
   - Sweet spots have a "perfect center" (smaller, brighter area)

2. **The Needle**: A moving indicator that sweeps across the bar
   - Moves left-to-right, then right-to-left (oscillating)
   - Speed increases slightly each round
   - Starting speed depends on artwork tier (higher tier = faster)

3. **Input**: Player clicks or presses spacebar to "sculpt"
   - Must time the input when needle is in a sweet spot
   - One input per round

4. **Rounds**: 6 rounds total per refinement session
   - Each round, sweet spots may shift positions
   - Number of sweet spots: starts at 3, may decrease in later rounds

**Scoring System:**

| Hit Type | Points | Visual Feedback |
|----------|--------|-----------------|
| **Perfect** | +3 | Golden flash, "PERFECT!" text, satisfying sound |
| **Good** | +2 | Green flash, "Good" text |
| **Okay** | +1 | Yellow flash, "Okay" text |
| **Miss** | -1 | Red flash, "Miss" text, error sound |

**Combo System:**
- Consecutive Perfect/Good hits build a combo
- Combo multiplier: x1.5 at 3 combo, x2 at 5 combo
- Miss resets combo to 0
- Encourages consistent precision over lucky hits

**Difficulty Scaling:**
| Artist Type | Needle Speed | Sweet Spot Size | Starting Score Bonus |
|-------------|--------------|-----------------|---------------------|
| Maestro | Slow | Large | +2 |
| Apprentice | Medium | Medium | +1 |
| Student | Medium | Medium | +0 |
| Inspired | Fast | Small | -1 |

**Results Based on Final Score:**

| Score | Grade | Result |
|-------|-------|--------|
| ≤3 | F | **Failure** - Artwork damaged, may lose a tier |
| 4-7 | C | **Mediocre** - Minor refinement, +5% effect strength |
| 8-11 | B | **Good** - Decent refinement, +15% effect strength |
| 12-15 | A | **Excellent** - Strong refinement, +30% effect strength |
| 16+ | S | **Masterwork** - Perfect refinement, +50% effect strength, special visual |

**Effect Strength:**
The "effect strength" multiplier applies to the artwork's passive effects:
- Sanity damage aura radius/damage
- Examine text impact
- Any special tier-based effects

**Visual/Audio Feedback:**
- Each hit plays a fleshy sculpting sound
- Perfect hits have a more satisfying, resonant sound
- Miss plays a wet, unpleasant sound
- Background ambience of artistic work
- The artwork structure visually reacts to hits (subtle shake/pulse)

**Post-Minigame:**
- Score displayed with grade
- Artwork receives a **Technique Grade** (F/C/B/A/S) based on performance
- This grade is stored on the artwork

**Cooldown:**
- Each artwork can only be refined once every 5 minutes
- Failed refinements (F grade) require 10 minute wait before retry

### 5. Technique Grade System
After refinement, the artwork receives a **Technique Grade** that reflects the sculptor's skill.

**Visibility:**
- Only visible to those who can create art (Maestro, Apprentice, Students, Inspired)
- Appears when examining the artwork: *"Technique: B"*
- Non-artists see only the standard description

**Grade Descriptions (for artists):**
| Grade | Examine Text |
|-------|-------------|
| F | "Technique: F - The craftsmanship is crude and amateurish." |
| C | "Technique: C - Basic competence, but lacking refinement." |
| B | "Technique: B - Solid technique with clear artistic intent." |
| A | "Technique: A - Masterful technique, every cut deliberate." |
| S | "Technique: S - Transcendent skill that defies comprehension." |

### 6. Artist Description
Artists can personalize their creations by writing custom descriptions.

**Process:**
- The creator of an artwork can interact with it to "Describe Artwork"
- Opens a text input dialog
- Artist writes their own description (max 300 characters)
- This custom description replaces the default tier-based description

**Restrictions:**
- Only the original creator can set/change the description
- Maestro can override any artwork's description
- Description persists unless changed by an authorized person

**Example:**
Default: *"A basic arrangement of flesh and bone. The artist's vision is barely visible."*
Custom: *"A meditation on mortality - three souls intertwined in eternal rest."*

### 7. Maestro's Final Grade
The Maestro alone has the authority to judge artwork and assign a **Final Grade**.

**Process:**
- Maestro uses "Judge Artwork" action on any artwork
- Opens a grading interface with options: F, C, B, A, S
- Maestro selects a grade and optionally adds critique text
- The Final Grade is permanently assigned to the artwork

**Final Grade Display:**
- Visible to everyone when examining (unlike Technique Grade)
- Format: *"Final Grade: A - 'A promising exploration of form.' - Maestro"*
- Ungraded artworks show: *"Awaiting judgment."*

**Artist Benefits (based on Final Grade received):**
| Grade | Benefit |
|-------|---------|
| F | **-50%** of next threshold EXP, temporary debuff (slower sculpting for 5 min) |
| C | **-25%** of next threshold EXP |
| B | +25% of next threshold EXP |
| A | +50% of next threshold EXP, temporary buff (+10% sculpting speed for 10 min) |
| S | +100% of next threshold EXP (instant skill point!), permanent recognition, special visual effect |

**Maestro's Grade Record:**
- The Maestro can examine any player to see grades they've given them
- Format when examining: *"You have graded [Name]'s work: 2x A, 1x B, 1x S"*
- This allows the Maestro to track each artist's progress and consistency
- Only visible to the Maestro who gave the grades

**Student Promotion:**
- Receiving an A or S grade from the Maestro grants +3 or +5 artistic progress
- This can accelerate an Inspired player's journey to becoming a Student
- Once a Inspired player reaches 6 artistic progress, they will become a Student.
- Students who consistently receive high grades could unlock additional recognition

---

## Artwork Structures

### Base Type
```
/obj/structure/corporist_artwork
    - name: varies by tier
    - desc: varies by tier (or custom if set)
    - icon: custom artwork sprites
    - anchored: TRUE (cannot be moved once placed)
    - density: varies by tier
    - can_buckle: TRUE (for adding corpses)
    - var/tier: 1-5
    - var/bodies_used: tracks corpses incorporated
    - var/list/bodyparts_used: list of bodypart types used (e.g., "2x torso, 3x arm")
    - var/creator: ref to mob who created it
    - var/needs_refinement: FALSE (set TRUE after adding body, blocks further additions)
    - var/custom_desc: artist's custom description (null if not set)
    - var/technique_grade: F/C/B/A/S from refinement (null if unrefined)
    - var/final_grade: F/C/B/A/S from Maestro (null if unjudged)
    - var/final_grade_critique: Maestro's critique text
    - var/graded_by: ref to Maestro who graded it
```

### Artwork Effects

**Examine Effects (based on viewer type):**

*Non-Artists* (cannot create artwork):
- Take SP damage when examining artwork
- Damage scales with tier: Tier 1 = 5 SP, Tier 2 = 10 SP, Tier 3 = 15 SP, Tier 4 = 25 SP, Tier 5 = 40 SP
- Message: *"The artwork disturbs you deeply. You feel your sanity slipping..."*

*Artists* (Maestro, Apprentice, Students, Inspired):
- Heal SP when examining artwork (even if they didn't create it)
- Healing scales with tier: Tier 1 = 3 SP, Tier 2 = 6 SP, Tier 3 = 10 SP, Tier 4 = 15 SP, Tier 5 = 25 SP
- Message: *"You appreciate the craftsmanship. The artistic vision soothes your mind."*

**Bodypart Display:**
When examining any artwork, the description includes what bodyparts were used:
- *"Incorporated remains: 2x torso, 3x arm, 1x head, 4x leg"*
- Tracks bodyparts from each corpse added to the artwork
- Higher tier artworks display more elaborate descriptions of how the parts are arranged

**Passive Aura Effects (higher tiers only):**

**Tier 4 (Masterpiece):**
- Passive SP damage aura to non-artists within 3 tiles (2 SP every 5 seconds)
- Artists within range gain slow SP regeneration instead (1 SP every 5 seconds)

**Tier 5 (Magnum Opus):**
- Larger aura radius (5 tiles)
- Stronger effects: 5 SP damage to non-artists, 3 SP heal to artists (every 5 seconds)
- Can be "unveiled" for a one-time dramatic effect
- Possibly attracts attention (announces to ghosts/deadchat?)

---

## Actions & Abilities

### Maestro Actions

**1. "Sculpt Corpse" (Primary)**
- Target: Dead simple_animal
- Channel time: 5-8 seconds
- Result: Creates Tier 1 artwork
- Cooldown: None (limited by channel time)

**2. "Demonstrate Artistry" (Special)**
- Target: Dead simple_animal
- Channel time: 10-15 seconds
- Result: Gibs corpse, grants "Inspired Artist" to viewers
- Cooldown: 5-10 minutes (significant cooldown)
- Range for inspiration: 7 tiles view range

**3. "Judge Artwork" (Maestro Only)**
- Target: Any corporist_artwork
- Opens grading interface to assign Final Grade (F/C/B/A/S)
- Can add optional critique text
- Applies benefits/penalties to the artwork's creator
- Grade is permanently visible to all who examine

**4. "Describe Artwork"**
- Target: Any artwork (Maestro can describe any, others only their own)
- Opens text input dialog
- Sets custom description (max 300 characters)
- Maestro can override any artwork's description

### Inspired Player Actions

**1. "Create Basic Artwork"**
- Target: Dead simple_animal
- Channel time: 8-10 seconds (slower than Maestro)
- Result: Creates Tier 1 artwork only
- Limited uses or duration-based
- Grants +1 artistic progress toward becoming a Student
- Grants +3% of next threshold as Artistic EXP (once they become a Student)

**2. "Describe Artwork"**
- Can only describe artworks they created
- Opens text input dialog (max 300 characters)

### Student Actions

**1. "Create Artwork"**
- Same as Inspired, but permanent and slightly faster (7-8 seconds)
- Can create up to Tier 1 artworks
- Grants +3% of next threshold as Artistic EXP

**2. "Enhance Artwork"**
- Can enhance artworks up to Tier 3
- Grants +2% of next threshold as Artistic EXP per body added

**3. "Refine Artwork"**
- Opens TGUI Refinement minigame
- Can refine any artwork they have access to
- Grants +3% of next threshold as Artistic EXP (or +5% for A/S technique grade)

**4. "Describe Artwork"**
- Can only describe artworks they created
- Opens text input dialog (max 300 characters)

---

## Visual & Audio Feedback

### During Sculpting
- Maestro animation (custom or reused)
- Squelching/fleshy sounds
- Blood particles
- Progress indicator

### During Demonstration
- More dramatic effects
- Spotlight/attention-drawing visuals
- Announcement to nearby players
- Climactic gib at the end

### Artwork Visuals
- Each tier has distinct sprite
- Possibly animated for higher tiers
- Gore/flesh aesthetic matching Ring theme
- Could use existing flesh/meat sprites as base

---

## Ring Skill Tree System

Students earn **Artistic EXP** from Maestro grades, which grants skill points at thresholds. Skill points are spent in the **Ring Skill Tree UI** to unlock abilities from 4 schools. Each school has 3 tiers with 2 mutually exclusive choices per tier. **All schools interact with the `lc_bleed` status effect.**

### Artistic EXP System

**EXP from Artistic Activities (Small Gains):**
Passive EXP scales with progression, calculated as a percentage of the next skill point threshold:

| Activity | EXP Gained |
|----------|------------|
| Create artwork | +3% of next threshold |
| Add body to artwork | +2% of next threshold |
| Refine artwork | +3% of next threshold |
| Refine artwork (A/S technique) | +5% of next threshold |

**Scaling examples:**
| Next Threshold | Create | Add Body | Refine | Refine (A/S) |
|----------------|--------|----------|--------|--------------|
| 50 | +1 | +1 | +1 | +2 |
| 300 | +9 | +6 | +9 | +15 |
| 1050 | +31 | +21 | +31 | +52 |

*Note: Passive gains are always 3-5% while Maestro grades give 25-100%, ensuring the Maestro remains 5-20x more impactful.*

**EXP from Maestro Final Grades (Major Changes):**
The Maestro's grades give or take EXP based on a **percentage of the next skill point threshold**, making each grade significant regardless of current progress.

| Grade | EXP Change |
|-------|------------|
| F | **-50%** of next threshold (severe punishment) |
| C | **-25%** of next threshold (minor setback) |
| B | +25% of next threshold |
| A | +50% of next threshold |
| S | +100% of next threshold (instant skill point!) |

**Example at different stages:**
- At 0 EXP (next threshold: 50): S = +50, A = +25, B = +12, C = -12, F = -25
- At 150 EXP (next threshold: 300): S = +150, A = +75, C = -37, F = -75
- At 750 EXP (next threshold: 1050): S = +300, A = +150, C = -75, F = -150

*Note: EXP cannot go below 0, and losing EXP cannot remove already-earned skill points.*

This makes the Maestro's judgment high-stakes - seek their approval carefully, as poor work is punished!

**Skill Point Thresholds:**
| Total EXP | Cumulative Skill Points |
|-----------|-------------------------|
| 50 | 1 |
| 150 | 2 |
| 300 | 3 |
| 500 | 4 |
| 750 | 5 |
| 1050 | 6 |
| 1400 | 7 |
| 1800 | 8 |

**Skill Point Costs Per Tier:**
| Tier | Cost |
|------|------|
| 1 | 1 point |
| 2 | 2 points |
| 3 | 3 points |

*Note: Completing all 3 tiers of one school costs 6 points total.*

**Starting Bonuses:**
| Role | Starting Skill Points |
|------|----------------------|
| Maestro | 8 points |
| Apprentice | 4 points |
| Student | 0 points (must earn via EXP) |

**School Restrictions:**
- Players can invest in **up to 2 schools maximum**
- Once you unlock a skill in a 3rd school, you are blocked
- Choose your specializations wisely

**Respec System:**
- **Maestro can respec others**: Maestro has a "Reset Artistry" action
- Target: Any Student or Apprentice
- Effect: Resets all skill choices, refunds all skill points
- Does NOT reduce their EXP (they keep their progress)
- No cooldown (Maestro's discretion)

### Ring Skill Tree UI (TGUI)

**Access:**
- Action button: "Ring Skill Tree" (granted to Students, Apprentice, Maestro)
- Requires Student status OR being Maestro/Apprentice

**UI Layout:**
```
+--------------------------------------------------+
| Artistic EXP: 325/500    Skill Points: 2/3       |
+--------------------------------------------------+
| [Fauvists] [Pointillists] [Cubists] [Corporists] |
+--------------------------------------------------+
| TIER 1 (1 pt)                                    |
| [Predator's Scent ✓] | [Cornered Beast ✗]       |
+--------------------------------------------------+
| TIER 2 (2 pts) - LOCKED until Tier 1 chosen     |
| [Rending Claws] | [Blood Frenzy]                 |
+--------------------------------------------------+
| TIER 3 (3 pts) - LOCKED                          |
| [Spreading Wounds] | [Savage Execution]          |
+--------------------------------------------------+
```

**States:**
- **Locked**: Grey, unclickable (tier not yet available)
- **Available**: Highlighted, clickable (can afford, tier unlocked)
- **Selected**: Colored/marked with checkmark
- **Excluded**: Crossed out (other choice was selected)

### The Four Schools (All Use lc_bleed)

#### School 1: FAUVISTS
*"Those who use primary colors and complex lines. Known to wear animal masks."*
**Theme:** Predatory aggression, WHITE/SP damage focus. The beast tears at both body and mind.

| Tier | Choice A | Choice B |
|------|----------|----------|
| **1** | **Predator's Scent** (Passive): +15% damage vs bleeding targets | **Maddening Maw** (Passive): Attacks on bleeding targets deal 15% of your melee damage as additional WHITE damage |
| **2** | **Rending Claws** (Passive): Attacks apply 2 bleed stacks | **Savage Instinct** (Passive): After hitting a bleeding target, gain +15% damage for 4 seconds (refreshes on hit) |
| **3** | **Spreading Wounds** (Passive): When hitting bleeding target, adjacent enemies gain 3 bleed | **Primal Terror** (Passive): Hitting targets with 10+ bleed deals 20 WHITE damage and removes 5 bleed stacks |

#### School 2: POINTILLISTS
*"Those who use small strokes and dots to depict light. Known to wield paintbrush weapons."*
**Theme:** Random status effect application, SP recovery, scaling power. Each "dot" of affliction is a splash of color.

**Random Effect Pool:** Each hit randomly selects from `lc_bleed`, `lc_mental_decay`, `lc_tremor`, `lc_overheat`

| Tier | Choice A | Choice B |
|------|----------|----------|
| **1** | **Hematic Coloring** (Passive): Attacks apply 3 stacks of a random effect (Bleed, Overheat, Tremor, or Mental Decay). If the target already has that effect, deal +10% damage instead. | **Sanguine Pointillism** (Passive): Attacks apply 1 stack of TWO random effects. Heal 2 SP whenever you apply an effect the target didn't already have. |
| **2** | **Assignment Evaluation** (Passive): Heal 5 SP when hitting targets, +3 SP per status effect on them | **Beat the Brush** (Passive): +5% damage per status effect on target (max 20% at 4 effects) |
| **3** | **Paint Over** (Passive): Random effect application now applies 2x stacks; +10% chance to apply ALL four effects at once | **Practices on Aesthetics** (Passive): +10% damage and +2 bleed per status effect on target |

**Synergy Example:** A Pointillist with Hematic Coloring + Assignment Evaluation + Paint Over:
1. Hit target → randomly applies 4 stacks of overheat (2x from Vivid), heals 5+3=8 SP
2. Hit again → randomly applies 4 stacks of tremor, now heals 5+6=11 SP (2 effects)
3. Keep hitting → effects stack up, SP healing scales, 10% chance to apply all 4 at once
4. With all 4 effects active, healing 5+12=17 SP per hit

#### School 3: CUBISTS
*"Those who incorporate abstract three-dimensionality and depth."*
**Theme:** Area control, spatial manipulation. Command the battlefield through bleeding zones.

| Tier | Choice A | Choice B |
|------|----------|----------|
| **1** | **Fractured Reflection** (Passive): Attackers gain 3 bleed when hitting you | **Geometric Reach** (Passive): Your attacks apply 2 bleed to enemies adjacent to your target |
| **2** | **Abstract Suffering** (Passive): When enemies within 5 tiles take bleed damage, they also take WHITE damage equal to half the bleed damage | **Warped Space** (Passive): Hitting targets with 8+ bleed stacks inflicts 20% slowdown for 3 seconds |
| **3** | **Spatial Anchor** (Passive): Enemies within 4 tiles of you cannot have their bleed reduced below 5 stacks | **Crimson Dimension** (Active, 60s CD): Create 3x3 zone applying 2 bleed/sec for 10s; you take 20% less damage while inside |

#### School 4: CORPORISTS
*"Those who utilize human bones and muscles, contraction and elongation."*
**Theme:** Duality of pain and power. Inflict negative effects on targets while gaining positive effects. When both occur simultaneously, trigger powerful Artistic Synergy bonuses.

**Core Mechanic - Artistic Synergy:** When an attack inflicts a negative effect (bleed) on the target AND grants a positive effect (Protection/Damage Up) on the user simultaneously, a synergy bonus triggers (SP healing, or alternative buff if at max SP).

| Tier | Choice A | Choice B |
|------|----------|----------|
| **1** | **Butcher - Ribs** (Passive): On Hit: Apply 2 bleed to target and gain 1 Protection. Artistic Synergy: Heal 5% max SP. If at max SP, gain 1 Damage Up instead. | **Rotator Crush** (Passive): On Hit: Apply 2 bleed to target and gain 1 Damage Up. Artistic Synergy: Heal 5% max SP. If at max SP, gain 1 Protection instead. |
| **2** | **Repressed Flesh** (Passive, 5s CD): On Hit: If target is bleeding and you have a positive effect, heal 5 HP and apply 2 extra bleed. If target has 10+ bleed, gain 1 extra Protection. | **Tendon Tear** (Passive): On Hit: If target is bleeding and you have a positive effect, deal 10 bonus RED damage. If you have 3+ Damage Up, deal additional 15 RED damage. |
| **3** | **Anatomize** (Passive, 30s CD): On Hit: If target is bleeding and below 25% HP, and you have both Protection and Damage Up, consume all bleed for 5 RED damage per stack and fully restore SP. | **Exhibition Arrangements** (Active, 30s CD): For 8s, attacks apply 3 bleed + 1 random negative effect AND grant 1 Protection + 1 Damage Up. Heal 5% max SP per hit (at max SP: +2 Damage Up). On expiry, consume all bleed on last target for 3 damage per stack. |

### Skill Tree Implementation Files

**New Files:**
```
ModularLobotomy/ring_skills/
├── _ring_skills.dm          # Include file
├── artistic_exp.dm          # /datum/component/artistic_exp - EXP tracking
├── ring_skill_tree.dm       # /datum/ring_skill_tree - UI data, skill management
├── ring_skill_action.dm     # /datum/action/ring_skill_tree - Opens UI
├── reset_artistry.dm        # /datum/action/reset_artistry - Maestro respec action
└── schools/
    ├── _schools.dm          # Base /datum/component/ring_skill
    ├── fauvist.dm           # Fauvist skill components
    ├── pointillist.dm       # Pointillist skill components
    ├── cubist.dm            # Cubist skill components
    └── corporist_school.dm  # Corporist skill components

tgui/packages/tgui/interfaces/
└── RingSkillTree.tsx        # TGUI interface
```

**Pattern References:**
- `ModularLobotomy/associations/augment_components.dm` - Component patterns for passives
- `tgui/packages/tgui/interfaces/SkillAugmentCatalogue.js` - Tab-based skill UI pattern

---

## Implementation Checklist

### Phase 1: Core Artwork System
- [ ] Create `/obj/structure/corporist_artwork` base type
- [ ] Create tier subtypes with appropriate stats/descriptions
- [ ] Implement artwork creation action for Maestro
- [ ] Implement `attackby()` for adding bodyparts to artwork
- [ ] Implement `user_buckle_mob()` for adding dead simple_animal corpses
- [ ] Track bodyparts used in `var/list/bodyparts_used`
- [ ] Implement `needs_refinement` flag (blocks additions until refined)
- [ ] Allow Students, Inspired, and Apprentice to enhance artworks
- [ ] Add basic sprites (can use placeholders initially)

### Phase 2: Demonstration System
- [ ] Create "Demonstrate Artistry" action
- [ ] Implement "Inspired Artist" status effect/component
- [ ] Create temporary artwork action for inspired players
- [ ] Add visual/audio feedback for demonstration

### Phase 3: Student System
- [ ] Track artistic progress per player (component or mind variable)
- [ ] Implement progress gain from creating/enhancing artworks
- [ ] Create "Student" permanent status
- [ ] Grant appropriate abilities to Students
- [ ] Add progress notifications/feedback

### Phase 4: Sculpting Minigame (TGUI)
- [ ] Create `/datum/sculpting_minigame` for minigame state
- [ ] Create TGUI interface `tgui/packages/tgui/interfaces/SculptingMinigame.tsx`
- [ ] Implement needle movement (oscillating left-right)
- [ ] Implement sweet spot generation and positioning
- [ ] Implement hit detection (Perfect/Good/Okay/Miss)
- [ ] Implement scoring and combo system
- [ ] Implement difficulty scaling by artist type
- [ ] Assign Technique Grade based on final score
- [ ] Add cooldown system for refinement
- [ ] Add sound effects (sculpt hits, perfect, miss)
- [ ] Add visual feedback (flashes, text popups)

### Phase 5: Technique Grade & Artist Description
- [ ] Store technique_grade variable on artwork
- [ ] Implement artist-only visibility for Technique Grade on examine
- [ ] Check if examiner can create art (Maestro/Apprentice/Student/Inspired)
- [ ] Add "Describe Artwork" action for artwork creators
- [ ] Implement text input dialog for custom descriptions
- [ ] Store custom_desc on artwork, use in examine if set
- [ ] Allow Maestro to override any description

### Phase 6: Maestro's Final Grade System
- [ ] Create "Judge Artwork" action (Maestro only)
- [ ] Implement grading interface (select F/C/B/A/S + optional critique)
- [ ] Store final_grade, final_grade_critique, graded_by on artwork
- [ ] Display Final Grade to all examiners
- [ ] Track grades given per player (component on Maestro or global list)
- [ ] Apply benefits/penalties based on Final Grade received
- [ ] Show grade history when Maestro examines a player

### Phase 7: Artwork Effects
- [ ] Implement sanity damage for examining high-tier art
- [ ] Implement passive auras for Tier 4-5
- [ ] Apply effect strength multiplier from Technique Grade
- [ ] Add any special Magnum Opus effects

### Phase 8: Ring Skill Tree System
- [ ] Create `/datum/component/artistic_exp` for EXP tracking
- [ ] Implement EXP gain from Maestro Final Grades
- [ ] Create skill point threshold system
- [ ] Create `/datum/ring_skill_tree` for skill tree state management
- [ ] Create "Ring Skill Tree" action button
- [ ] Create TGUI interface `RingSkillTree.tsx`
- [ ] Implement 4 school tabs with 3 tiers each
- [ ] Implement 2-school maximum restriction
- [ ] Implement tier unlocking (must complete previous tier)
- [ ] Implement mutually exclusive choices (pick one, lock other)
- [ ] Grant starting skill points to Maestro (8) and Apprentice (4)
- [ ] Create base `/datum/component/ring_skill` for all skills
- [ ] Implement Fauvist school skills (6 components)
- [ ] Implement Pointillist school skills (6 components)
- [ ] Implement Cubist school skills (6 components)
- [ ] Implement Corporist school skills (6 components)
- [ ] Create "Reset Artistry" action for Maestro respec

### Phase 9: Polish
- [ ] Custom sprites for all artwork tiers
- [ ] Sound effects
- [ ] Particle effects
- [ ] Balance tuning (channel times, cooldowns, durations, progress thresholds)

---

## Integration Points

### Files to Create/Modify
- `ModularLobotomy/structures/corporist_artwork.dm` - Artwork structures with grade/description vars
- `ModularLobotomy/actions/corporist_actions.dm` - Maestro actions (sculpt, judge, describe)
- `code/modules/jobs/job_types/trusted_players/corporist_maestro.dm` - Grant actions on spawn
- `code/datums/components/inspired_artist.dm` - Inspired status component
- `code/datums/components/corporist_student.dm` - Permanent Student status
- `code/datums/components/artistic_progress.dm` - Track progress toward becoming a Student
- `code/datums/components/maestro_grade_tracker.dm` - Track grades Maestro has given to players
- `code/datums/corporist_refinement.dm` - Refinement minigame state/logic
- `tgui/packages/tgui/interfaces/CorporistRefinement.tsx` - Refinement TGUI
- `tgui/packages/tgui/interfaces/CorporistJudge.tsx` - Grade selection TGUI (optional, could use simple alert)

**Ring Skill Tree Files:**
- `ModularLobotomy/ring_skills/_ring_skills.dm` - Include file
- `ModularLobotomy/ring_skills/artistic_exp.dm` - EXP tracking component
- `ModularLobotomy/ring_skills/ring_skill_tree.dm` - Skill tree state/UI data
- `ModularLobotomy/ring_skills/ring_skill_action.dm` - Action to open skill tree
- `ModularLobotomy/ring_skills/reset_artistry.dm` - Maestro respec action
- `ModularLobotomy/ring_skills/schools/_schools.dm` - Base ring_skill component
- `ModularLobotomy/ring_skills/schools/fauvist.dm` - 6 Fauvist skill components
- `ModularLobotomy/ring_skills/schools/pointillist.dm` - 6 Pointillist skill components
- `ModularLobotomy/ring_skills/schools/cubist.dm` - 6 Cubist skill components
- `ModularLobotomy/ring_skills/schools/corporist_school.dm` - 6 Corporist skill components
- `tgui/packages/tgui/interfaces/RingSkillTree.tsx` - Skill tree TGUI

### Existing Systems to Hook Into
- Action system (`/datum/action`)
- Component system (`/datum/component`)
- Status effects (`/datum/status_effect`)
- Sanity system for artwork effects
- TGUI system for refinement minigame

---

## Open Questions

1. **Corpse Type Weighting**: Should certain corpses (abnormalities vs regular mobs) contribute more "art value" when incorporated?

2. **Artwork Persistence**: Should artworks persist across rounds or be temporary? Should they be destroyable?

3. **Apprentice Role**: Should the Corporist Apprentice start as a Student, or do they need to earn it too? Special bonuses when working with Maestro?

4. **Gallery Feature**: Should there be a way to "display" or "unveil" artworks for additional effects?

5. **Competition/Grading**: Tie into the Ring's grading system? Ghosts can rate artworks?

6. **Resource Cost**: Should creating art cost anything besides the corpse? (Sanity, health, materials?)

7. **Student Progress**: Is 10 progress the right threshold? Should there be intermediate milestones?

8. **Art Movement Effects**: How strong should each movement's effects be? Should they stack or replace each other on re-refinement?

9. **Timing Difficulty**: How forgiving should the timing minigame be? Should Maestro have larger sweet spots?

10. **Visual Storytelling**: Should refined artworks have unique examine text based on the choices made during refinement? (Callisto emphasizes art "telling a story")

---

## Lore Notes

From the Ring's practices:
- Art is created to reflect the human condition through suffering
- Works are evaluated and graded
- The Ring manages galleries and auctions
- Civilians under Ring protection must create art or face consequences

This system captures the Corporist school's focus on "utilizing the interaction between human bones and muscles, and the contraction and elongation thereof" through literal flesh-sculpting.

---

## Callisto's Artistic Philosophy (Source Quotes)

These quotes from Callisto inform the refinement minigame and art movement system:

**On Perspective:**
> "Perspective has a way of transforming art, as the state of one's heart alters the evocative qualities of a piece."

**On Minimalism:**
> "A bold removal of the unnecessary for the preservation of the essence. The human corpus has far too many non-essential parts which harm the purity of it."

**On Structuralism:**
> "The simplicity with which a straight line sunders is a primordial form of structuralism."

**On Fauvism:**
> "I was simply hoping to replicate the striking visual imagery of Fauvism."

**On Preservation:**
> "I endeavored to preserve every second of it... down to the smallest capillaries, muscle tissues, and the quivering thereout."

**On Craftsmanship:**
> "The element I found most compelling upon closer inspection was the contrasting duet of veins and arteries. It is the kind of expression achievable only through a refined understanding of the human anatomy."

**On Color:**
> "You've drained too much blood, far more than what is necessary. That limits the spectrum of color in your piece."

**On Storytelling:**
> "Don't trap yourself in a box thinking that macabre violence and the exhibition thereof is all there is to art. Make your art tell a story that is unique to you."

**On Understanding:**
> "Every artist craves the understanding of others. Art for art's sake is without meaning."

**On Teaching:**
> "I will raise you as a precious pupil of mine, a companion to all of my future artwork. So please—follow along with my classes."

These themes should be reflected in:
- The art movement choices and their effects
- The composition questions during refinement
- The descriptions generated for refined artworks
- The progression from Inspired → Student (becoming a "pupil")
