# Echo Office - Combo Attacks

This document defines all combo attacks between Echo Office members.

## System Overview

### Trigger Conditions
- Cooldown-based: 45 seconds between combo attempts
- Range: Partner must be within 10 tiles
- State: Neither partner can be staggered, dead, or already in a combo
- Priority: Ultimate combo > Duo combos (random selection among available duos)

### During Combo
- Both participants have `in_combo_attack = TRUE`
- Normal abilities are disabled
- Participants refer to each other by real names

### Character Reference
| Display Name | Real Name | Damage Type |
|--------------|-----------|-------------|
| Memory Forger | Nicholas | BLACK |
| Sanguine Flame | Asera Helios | RED |
| Amber Knight | Remus Amber | WHITE |
| Redeemed Star | Lauel | PALE |

---

## Duo Combos

### 1. Burning Memories
**Participants:** Nicholas + Asera Helios

**Description:** Nicholas fires a barrage of projectiles towards Asera while Asera reflects them with amplified power.

**Mechanics:**
1. Nicholas says: *"Asera Helios... lend me your flame..."*
2. Asera responds: *"Nicholas... let's make them remember!"*
3. Nicholas fires 8 projectiles which will lock on Asera, like their Helios Flame projectile. (Takes 3 seconds to fire all of them)
4. Asera enters an enhanced counter stance (6 seconds)
5. All projectiles that hit Asera are reflected towards nearby foes, and they will lose their homing property.
6. Reflected projectiles deal 40 BLACK + 30 RED damage with burn (10 stacks)

**Duration:** ~3 seconds
**Cooldown:** 45 seconds

---

### 2. Thunderforged Statues
**Participants:** Nicholas + Remus Amber

**Description:** Nicholas summons statues around their target that Remus electrifies with a dash.

**Mechanics:**
1. Remus says: *"Nicholas! The stage is set!"*
2. Nicholas responds: *"Remus Amber... strike true."*
3. Nicholas spawns 5 statues in around the nearest enemy (they should be at least 2 tiles away from each other)
4. Remus will create a beam from statue to statue (like there will be a beam between him and statue 1, then there will be a beam between statue 1 and statue 2, ect...), then 1 second later, they will dash through all statues in sequence (0.25s between each dash)
5. Each statue explodes when Remus passes through
6. Explosions deal 35 BLACK + 35 WHITE damage in 2-tile radius

**Duration:** ~4 seconds
**Cooldown:** 45 seconds

---

### 3. Sanctuary of Memory
**Participants:** Nicholas + Lauel

**Description:** Nicholas summons memory statues connected to each foe. Players must destroy their connected statues to avoid targeted damage.

**Mechanics:**
1. Lauel says: *"I shall be your shield, Nicholas."*
2. Nicholas responds: *"...Thank you, Lauel."*
3. Lauel creates a protective barrier around Nicholas (50% damage reduction)
4. Nicholas targets up to 5 foes within 7 tiles
5. For each targeted foe, 2 combo statues spawn near them (1-2 tiles away, 150 HP each)
6. Each statue is connected to its target with a visible beam
7. Warning message appears: "Destroy the statues connected to you!"
8. Players have 5 seconds to destroy their connected statues
9. After timer:
   - Each foe with ANY surviving connected statues takes 60 BLACK damage
   - Each surviving statue heals Nicholas for 100 HP
   - If a player destroys BOTH their statues: they take no damage
10. Lauel maintains channel, cannot move, intercept, counter or act during blessing

**Counterplay:** Each player must destroy the 2 statues connected to them (via visible beams) to avoid taking damage.

**Duration:** ~6 seconds
**Cooldown:** 45 seconds

---

### 4. Blazing Pursuit
**Participants:** Asera Helios + Remus Amber

**Description:** Both fixers dash in crossing patterns, creating a deadly intersection.

**Mechanics:**
1. Asera says: *"Remus Amber, with me!"*
2. Remus responds: *"The light guides us, Asera Helios!"*
3. Both fixers will teleport around their target, and then create warning tiles from their position, to the current location of their target, and extending slightly past that turf. (Make sure they teleport at least 3 tiles away from the target, and the fixers are 5 turfs away from each other.) 
4. After 1 second, both dash simultaneously towards that turf that they have marked.
5. At intersection point, they will create a shockwave which will deal 50 RED and 50 WHITE damage in a 3x3 AoE range.
7. Dashes deal 30 RED (Asera) and 30 WHITE (Remus)

**Duration:** ~5 seconds
**Cooldown:** 45 seconds

---

### 5. Guardian's Flame
**Participants:** Asera Helios + Lauel

**Description:** Lauel empowers Asera's dash attack, allowing extended pursuit.

**Mechanics:**
1. Lauel says: *"Go forth, friend Asera. I am with you."*
2. Asera responds: *"Lauel... I won't let this go to waste."*
3. Lauel channels healing light onto Asera (visual beam)
4. Asera performs 5 consecutive dashes (instead of normal 3)
5. Each dash deals 40 RED damage (reduced from 50 due to more dashes)
6. Lauel heals Asera for 50 HP between each dash
7. Total potential damage: 200 RED + significant burn stacks
8. For the duration of those dashes, Lauel maintains a channel, cannot move, intercept, counter or act during blessing

**Duration:** ~6 seconds
**Cooldown:** 45 seconds

---

### 6. Knight's Blessing
**Participants:** Remus Amber + Lauel

**Description:** Lauel empowers Remus for a rapid lightning storm of consecutive dashes.

**Mechanics:**
1. Remus says: *"Lauel! Grant me your strength!"*
2. Lauel responds: *"Sire Remus, the light is yours to wield."*
3. Lauel channels a healing beam onto Remus (visual beam, locked in place)
4. Remus performs 8 rapid consecutive dashes toward the nearest enemy:
   - Each dash uses Remus's signature visuals and sounds
   - Each dash deals 35 WHITE damage in a 3x3 area
   - Short delay between dashes (~0.3 seconds)
5. Lauel heals Remus for 25 HP between each dash
6. Lauel maintains channel, cannot move, intercept, counter or act during blessing

**Duration:** ~6 seconds
**Cooldown:** 45 seconds

---

## Ultimate Combo

### 7. Echo of the Stars
**Participants:** All Four (Nicholas, Asera, Remus, Lauel)

**Description:** The ultimate coordinated attack using all four members' abilities.

**Mechanics:**
1. **Initiation** (any member can start):
   - Lauel: *"Everyone... together!"*
   - Nicholas: *"Asera. Remus. Lauel. Let us end this."*
   - Asera: *"Nicholas, Remus, Lauel... one more time."*
   - Remus: *"The stage is ours! Nicholas! Asera Helios! Lauel!"*

2. **Phase 1 - Formation** (2 seconds):
   - All four fixers move to cardinal positions around target area
   - Lauel creates massive protective dome (7-tile radius)
   - Nicholas spawns 8 statues in a circle within the dome

3. **Phase 2 - Execution** (3 seconds):
   - Asera and Remus dash in spiral patterns inside the dome
   - Each pass through a statue electrifies and ignites it
   - Lauel channels PALE energy into the center

4. **Phase 3 - Detonation** (1 second):
   - Nicholas detonates all statues simultaneously
   - Lauel releases stored PALE energy
   - Final explosion: 50 BLACK + 50 RED + 50 WHITE + 50 PALE damage
   - 5-tile radius AOE

**Voice Lines During Execution:**
- Nicholas: *"Remember this moment."*
- Asera: *"For everyone we've lost..."*
- Remus: *"...and everyone we'll save!"*
- Lauel: *"May the light guide you all."*

**Duration:** ~6 seconds
**Cooldown:** 120 seconds

---

## Implementation Notes

### Proc Structure
```
/mob/living/simple_animal/hostile/humanoid/fixer
    var/in_combo_attack = FALSE
    var/combo_cooldown = 0
    var/combo_cooldown_time = 45 SECONDS
    var/real_name = "" // Set per subtype

    proc/CheckForComboPartners()
    proc/InitiateCombo(partner)
    proc/JoinCombo(initiator, combo_type)
    proc/EndCombo()
```

### Detection Loop
- Check every 5 seconds during combat
- Roll chance to initiate combo (25% when off cooldown)
- Prioritize ultimate if all 4 present
- Otherwise, randomly select available duo combo
