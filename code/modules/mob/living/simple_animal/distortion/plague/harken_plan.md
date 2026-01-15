# Harken Distortion Mob Implementation Plan

## Overview
Add a new distortion mob based on "Harken" from Die of Death, using `/mob/living/simple_animal/hostile/distortion/adversary` as the implementation pattern.

## Reference File
`code/modules/mob/living/simple_animal/distortion/plague/adversary.dm`

## New File
`code/modules/mob/living/simple_animal/distortion/plague/harken.dm`

---

## Core Mechanics

### 1. Noise Meter System (Passive: ECHO LOCATION)
- **Variable:** `var/noise` - Current noise level (0 to max)
- **Variable:** `var/max_noise` - Calculated as `civilians_alive * 5`
- **Variable:** `var/enraged = FALSE` - Enrage state flag
- **Mechanics:**
  - All abilities generate noise when used
  - **Players generate noise when attacking nearby** (see Player Noise Tracking Component below)
  - When noise >= max_noise → Enter Enrage State
  - When enraged and noise <= 10 → Exit Enrage State

### 2. Enrage State
- **Speed Boost:** Significantly increased movement speed (use `TemporarySpeedChange()` or movespeed modifier)
- **Stamina Reduction:** Set stamina to 94 (if using stamina system)
- **Passive Drain:** Noise meter slowly drains while enraged (process in `Life()`)
- **Visual:** Change icon_state or add overlay to indicate enraged state
- **Projectile Immunity:** Immune to ALL projectiles while enraged
- **Mech Piercing Attacks:** Melee attacks damage pilots inside mechs (bypasses mech protection)

### 3. Sprint System
Based on adversary.dm sprint system, but **without acceleration** (instant speed change).
- **Toggle Action:** Player can toggle sprint on/off
- **Stamina Cost:** Drains stamina while sprinting
- **Minimum Stamina:** Requires minimum stamina (e.g., 15%) to start sprinting
- **Speed Modifier:** Instant -1.5 multiplicative slowdown (faster movement)
- **Stamina Regen:** Regenerates stamina when not sprinting

```dm
/datum/movespeed_modifier/harken_sprint
    variable = TRUE
    multiplicative_slowdown = -1.5  // Instant full sprint speed

// Variables
var/sprinting = FALSE
var/min_sprint_stamina = 15.0  // 15% minimum to start sprinting
var/sprint_stamina_drain = 2.0  // Stamina drained per Life() tick while sprinting
var/stamina_regen_rate = 5.0   // Stamina regained per Life() tick when not sprinting

/mob/living/simple_animal/hostile/distortion/harken/proc/start_sprint()
    if(sprinting)
        return
    if(stamina < min_sprint_stamina)
        to_chat(src, span_warning("Not enough stamina to sprint!"))
        return
    sprinting = TRUE
    add_movespeed_modifier(/datum/movespeed_modifier/harken_sprint)
    to_chat(src, span_nicegreen("You begin sprinting!"))

/mob/living/simple_animal/hostile/distortion/harken/proc/stop_sprint()
    if(!sprinting)
        return
    sprinting = FALSE
    remove_movespeed_modifier(/datum/movespeed_modifier/harken_sprint)
    to_chat(src, span_warning("You stop sprinting."))

// In Life() - process stamina
if(sprinting)
    stamina -= sprint_stamina_drain
    if(stamina <= 0)
        stamina = 0
        stop_sprint()
else
    stamina = min(stamina + stamina_regen_rate, 100)
```

### 4. Noise Meter UI
A HUD element visible to Harken and nearby humans showing the current noise level.

**UI Elements:**
- **Progress Bar:** Orange/yellow bar showing current noise / max noise (always orange, does NOT change color)
- **Icon:** Changes expression based on enrage state (calm face with closed eyes vs angry face with open eyes/gritted teeth)
- **Numbers:** Current noise on left, max noise on right

**Visibility Rules:**
- **Harken:** Always sees the UI
- **Humans:** Only see the UI once noise reaches 50% for the first time
  - After first 50% trigger, UI remains visible until Harken dies
  - Track with `var/ui_revealed = FALSE` on Harken

### 5. Civilian Tracking
- Track living humans on same z-level for noise meter scaling
- Update `max_noise` dynamically as civilians die/spawn

---

## Progress Bar Implementation

There are three approaches to make the bar dynamically fill as noise changes:

### Approach 1: Icon States (Recommended - Simple & Clean)
Based on how `code/datums/progressbar.dm` works.

**How it works:**
- Create icon states at 5% increments: `bar_0`, `bar_5`, `bar_10`, ... `bar_100`
- Update icon_state based on noise percentage
- Each state shows the bar filled to that percentage

**Icon States Required (21 total):**
```
bar_0, bar_5, bar_10, bar_15, bar_20, bar_25, bar_30, bar_35, bar_40, bar_45,
bar_50, bar_55, bar_60, bar_65, bar_70, bar_75, bar_80, bar_85, bar_90, bar_95, bar_100
```

**Implementation:**
```dm
/atom/movable/screen/harken_noise
    icon = 'icons/hud/harken_hud.dmi'
    icon_state = "bar_0"
    screen_loc = "CENTER-1,BOTTOM+1"
    maptext_width = 64
    maptext_height = 32

    var/datum/weakref/harken_ref
    var/current_percent = 0

/atom/movable/screen/harken_noise/proc/update_display(noise, max_noise, enraged)
    // Calculate percentage rounded to nearest 5
    var/raw_percent = (noise / max_noise) * 100
    var/new_percent = clamp(round(raw_percent, 5), 0, 100)

    // Only update icon if percentage changed (reduces overhead)
    if(new_percent != current_percent)
        current_percent = new_percent
        icon_state = "bar_[new_percent]"

    // Update the expression overlay based on enrage state
    cut_overlays()
    var/mutable_appearance/face = mutable_appearance(icon, enraged ? "face_enraged" : "face_calm")
    add_overlay(face)

    // Update numbers display
    maptext = "<span class='center maptext' style='font-size:8pt'>[noise] | [max_noise]</span>"
```

**Icon File Structure (`icons/hud/harken_hud.dmi`):**
- 21 bar states (`bar_0` through `bar_100`) - orange bar at different fill levels
- `face_calm` - calm expression overlay (centered on bar)
- `face_enraged` - angry expression overlay (centered on bar)

---

### Approach 2: Overlays with Transform (More Flexible)
Uses matrix transforms to scale a fill overlay.

**How it works:**
- Base icon shows empty bar frame + face
- Overlay shows the fill portion
- Scale the fill overlay horizontally using transform matrix

**Icon States Required (4 total):**
- `bar_frame` - The empty bar outline/background
- `bar_fill` - The orange fill (full width, will be scaled)
- `face_calm` - Calm expression
- `face_enraged` - Angry expression

**Implementation:**
```dm
/atom/movable/screen/harken_noise
    icon = 'icons/hud/harken_hud.dmi'
    icon_state = "bar_frame"
    screen_loc = "CENTER-1,BOTTOM+1"

    var/datum/weakref/harken_ref
    var/atom/movable/screen/harken_noise_fill/fill_bar

/atom/movable/screen/harken_noise/Initialize()
    . = ..()
    // Create the fill bar as a child/vis_contents element
    fill_bar = new()
    fill_bar.icon = icon
    fill_bar.icon_state = "bar_fill"
    vis_contents += fill_bar

/atom/movable/screen/harken_noise/proc/update_display(noise, max_noise, enraged)
    var/fill_percent = noise / max_noise

    // Scale the fill bar horizontally (0.0 to 1.0)
    var/matrix/M = matrix()
    M.Scale(fill_percent, 1)
    // Translate to keep left-aligned (adjust pixel offset based on icon width)
    var/bar_width = 48  // Width of the bar portion in pixels
    M.Translate(-(bar_width * (1 - fill_percent)) / 2, 0)
    fill_bar.transform = M

    // Update face overlay
    cut_overlays()
    add_overlay(mutable_appearance(icon, enraged ? "face_enraged" : "face_calm"))

    // Update numbers
    maptext = "<span class='center maptext'>[noise] | [max_noise]</span>"
```

---

### Approach 3: Maptext HTML Bar (No Icons Needed)
Uses pure HTML/CSS for the bar visual.

**How it works:**
- Use maptext with styled divs to create the bar
- Background div for frame, inner div for fill
- Adjust inner div width based on percentage

**Implementation:**
```dm
/atom/movable/screen/harken_noise
    icon = 'icons/hud/harken_hud.dmi'
    icon_state = "face_calm"  // Just the face icon
    screen_loc = "CENTER-1,BOTTOM+1"
    maptext_width = 96
    maptext_height = 48

/atom/movable/screen/harken_noise/proc/update_display(noise, max_noise, enraged)
    var/fill_percent = round((noise / max_noise) * 100)
    var/bar_width = 64  // Total bar width in pixels
    var/fill_width = round(bar_width * (fill_percent / 100))

    // Update face icon
    icon_state = enraged ? "face_enraged" : "face_calm"

    // Generate HTML bar
    var/bar_html = {"
        <div style='position:relative; width:[bar_width]px; height:12px; background:#333; border:1px solid #555;'>
            <div style='width:[fill_width]px; height:100%; background:#E8A33C;'></div>
        </div>
        <div style='text-align:center; font-size:8pt; color:white;'>[noise] | [max_noise]</div>
    "}
    maptext = bar_html
```

---

### Recommended Approach: Icon States (Approach 1)

**Reasons:**
1. **Consistent with existing code** - Uses same pattern as `progressbar.dm`
2. **Predictable visuals** - Artist has full control over each state
3. **Good performance** - Simple icon_state changes are fast
4. **Matches reference images** - Can precisely replicate the look from the provided screenshots

**Steps to Implement:**
1. Create `icons/hud/harken_hud.dmi` with:
   - 21 bar states at 5% increments (orange fill)
   - 2 face overlays (calm and enraged expressions)
2. Create `/atom/movable/screen/harken_noise` screen object
3. Call `update_display()` whenever noise changes or in `Life()`
4. Add to viewers' screens when UI is revealed

**Reference images provided:**
- `HarkenNoisemeterCalm.jpg` - Orange noise bar (19/85), calm icon expression
- `HarkenNoisemeterEnraged.jpg` - Orange noise bar (46/85), angry icon expression
- Note: The green bar in the images is the HEALTH bar, not the noise meter

---

## Player Noise Tracking Component

### Overview
A component applied to all `/mob/living/carbon/human` on the same z-level as Harken that tracks when they perform noisy actions (throwing, attacking, firing weapons) and reports this to nearby Harken mobs.

### Component Definition
```dm
/datum/component/harken_noise_tracker
    dupe_mode = COMPONENT_DUPE_UNIQUE
    var/mob/living/simple_animal/hostile/distortion/harken/owner_harken
    var/noise_range = 15
    var/throw_noise = 3
    var/melee_attack_noise = 2
    var/ranged_fire_noise = 4
    var/noise_cooldown_time = 2 SECONDS  // 2 second cooldown between noise reports
    var/last_noise_time = 0
```

### Signals to Register
- `COMSIG_MOB_THROW` - Throwing items
- `COMSIG_MOB_ITEM_ATTACK` - Melee attacks with items
- `COMSIG_HUMAN_MELEE_UNARMED_ATTACK` - Unarmed attacks
- `COMSIG_MOB_FIRED_GUN` - Firing ranged weapons

### New Player Handling
- Register for `COMSIG_GLOB_MOB_CREATED` to catch players joining mid-round
- Add tracker component to new humans on same z-level

---

## Abilities

### Basic Melee Attack
```dm
// Variables
var/melee_cooldown = 0
var/melee_cooldown_time = 1 SECONDS
var/melee_windup = 0.15 SECONDS
var/melee_noise = 2

// Stats
melee_damage_lower = 50
melee_damage_upper = 50
melee_damage_lower_enraged = 80
melee_damage_upper_enraged = 80
```
- **Windup:** 0.15 seconds before attack lands
- **Damage:** 50 (normal), 80 (enraged)
- **Cooldown:** 1 second
- **Noise:** Generates 2 noise on hit

### Skill #1: Agitation
```dm
/datum/action/innate/distortion_attack/harken_agitation
var/agitation_cooldown = 0
var/agitation_cooldown_time = 20 SECONDS
var/agitation_damage = 15
var/agitation_noise = 5
var/agitation_line_length = 8  // Minimum line length in tiles
var/agitation_beam_delay = 1   // 0.1 seconds between each beam (1 tick)
```
- **Mechanic:** Click on a turf to create a line of yellow beam effects
- **Effect:**
  - Draws a line from Harken to clicked turf (extends to 8 tiles minimum)
  - Yellow beam effect appears on each tile with 0.1s delay
  - Mobs hit by the beam are knocked into the air (pixel_y animation + spin)
- **Damage:** 15
- **Cooldown:** 20 seconds
- **Noise:** Generates 5 noise on use

### Skill #2: Tangle
```dm
/datum/action/innate/distortion_attack/harken_tangle
var/tangle_cooldown = 0
var/tangle_cooldown_time = 25 SECONDS
var/tangle_noise_throw = 1
var/tangle_noise_hit = 5
var/tangle_noise_break = 10
var/tangle_heal_harken_percent = 0.10   // Harken heals 10% of their max HP
var/tangle_heal_target_percent = 0.50   // Target heals 50% of their max HP
var/tangle_damage_mult = 1.25
var/tangle_throw_speed = 4  // Fast pull speed
var/mob/living/chained_target = null
var/datum/beam/chain_beam = null
```
- **Mechanic:** Throws javelin projectile, chains and yanks target to Harken
- **On Hit (Normal Target):**
  - Generate 5 noise
  - Chain target to Harken (visual beam + status effect)
  - **One strong pull using `throw_at()`** - yanks them directly to Harken
  - **Harken heals 10% of their max HP**
  - **Target heals 50% of their max HP**
  - While chained: Target takes 1.25x damage from Harken
- **On Hit (Mech):**
  - Forcibly eject occupant(s) from mech
  - Chain the ejected pilot to Harken
  - Yank pilot toward Harken with `throw_at()`
  - **Harken heals 10% of their max HP**
  - **Pilot heals 50% of their max HP**
- **Chain Break Conditions:**
  - Harken is stunned
  - Target gets too far away (define max distance, e.g., 10 tiles)
  - Generates 10 noise when chain breaks
- **On Throw:** Generate 1 noise
- **Cooldown:** 25 seconds

### Skill #3: Immolate
```dm
/datum/action/innate/distortion_attack/harken_immolate
var/immolate_cooldown = 0
var/immolate_cooldown_time = 35 SECONDS
var/immolate_self_damage_percent = 0.20  // 20% of max HP
var/immolate_dot_percent = 0.05          // 5% of max HP over 10 seconds
var/immolate_dot_duration = 10 SECONDS
var/immolate_noise_percent = 0.60        // 60% of max noise meter
var/immolate_bleeding = FALSE
```
- **Mechanic:** Self-impale with light javelin
- **Effect:**
  - Deal **20% of max HP** as immediate self-damage
  - Apply bleeding: **5% of max HP** as damage over time (10 seconds)
  - Generate **60% of max noise meter** as noise
  - Significant speed boost while bleeding
- **Restriction:** Cannot use while Enraged
- **Cooldown:** 35 seconds
- **Implementation:** Use proc-based DoT (no status effects)

### Immolate Damage Breakdown (assuming 2000 max HP)
| Damage Type | Percentage | Amount |
|-------------|------------|--------|
| Immediate   | 20% max HP | 400 HP |
| DoT (total) | 5% max HP  | 100 HP |
| DoT per tick| 0.5% max HP| 10 HP/sec for 10 seconds |
| **Total**   | **25% max HP** | **500 HP** |

### Toggle: Sprint
- **Mechanic:** Toggle sprint on/off
- **Effect:** Instant speed boost while active (no acceleration)
- **Cost:** Drains stamina while sprinting
- **Restriction:** Requires minimum 15% stamina to start

---

## Enrage State Implementation

### Projectile Immunity
```dm
/mob/living/simple_animal/hostile/distortion/harken/bullet_act(obj/projectile/P)
    if(enraged)
        visible_message(span_warning("[P] dissipates harmlessly against [src]'s frenzied aura!"))
        playsound(src, 'sound/effects/attackblob.ogg', 50, TRUE)
        return BULLET_ACT_BLOCK
    return ..()
```

### Mech-Piercing Melee
```dm
/mob/living/simple_animal/hostile/distortion/harken/proc/deal_mech_piercing_damage(obj/vehicle/sealed/mecha/mech, damage)
    if(!enraged)
        return
    if(!istype(mech))
        return
    if(!LAZYLEN(mech.occupants))
        return
    // Deal 50% of attack damage to all occupants
    for(var/mob/living/occupant in mech.occupants)
        occupant.deal_damage(damage * 0.5, melee_damage_type, src)
        to_chat(occupant, span_userdanger("[src]'s attack pierces through [mech] and strikes you!"))
    visible_message(span_danger("[src]'s frenzied attack pierces through [mech]'s armor!"))
```

---

## Testing Checklist

### Noise Meter System
- [ ] Noise meter fills correctly from Harken's own abilities
- [ ] Enrage triggers at max noise
- [ ] Enrage ends at 10 noise
- [ ] max_noise scales with civilian count

### Enrage State
- [ ] Harken is immune to all projectiles while enraged
- [ ] Projectiles display "dissipates harmlessly" message when blocked
- [ ] Melee attacks damage pilots inside mechs while enraged (50% damage)
- [ ] Mech-piercing damage uses correct damage type (RED_DAMAGE)
- [ ] Mech-piercing only works while enraged, not in normal state

### Player Noise Tracking
- [ ] Component is applied to all humans when Harken spawns
- [ ] Component is applied to new players joining mid-round (via COMSIG_GLOB_MOB_CREATED)
- [ ] Throwing items generates noise for nearby Harken
- [ ] Melee attacks (with weapon) generate noise for nearby Harken
- [ ] Unarmed melee attacks generate noise for nearby Harken
- [ ] Firing ranged weapons generates noise for nearby Harken
- [ ] Noise only reported when player is within range (15 tiles)
- [ ] 2 second cooldown between noise reports per human
- [ ] Component is removed when Harken dies
- [ ] Global signal is unregistered when Harken dies
- [ ] Multiple Harkens can receive noise from the same player

### Melee Attack
- [ ] Melee attack has correct windup/cooldown/damage
- [ ] Melee damage increases when enraged

### Agitation
- [ ] Clicking turf creates line from Harken to target
- [ ] Line extends to 8 tiles minimum if clicked turf is closer
- [ ] Yellow beam effects appear on each tile in sequence
- [ ] 0.1 second delay between each beam appearing
- [ ] Mobs hit by beam take 15 RED damage
- [ ] Mobs hit animate upward (pixel_y increases)
- [ ] Mobs hit spin while in air (SpinAnimation)
- [ ] Mobs hit animate back down with bounce
- [ ] Mobs hit get knocked down for 1 second
- [ ] Agitation generates 5 noise on use
- [ ] Harken cannot act during agitation sequence

### Tangle
- [ ] Javelin projectile fires correctly
- [ ] On hit: Chain visual beam appears between Harken and target
- [ ] On hit: Status effect `/datum/status_effect/harken_chained` applied to target
- [ ] On hit: Target is thrown at Harken using `throw_at()` (one strong pull)
- [ ] On hit: Harken heals 10% of their max HP, target heals 50% of their max HP
- [ ] While chained: Target takes 1.25x damage from Harken
- [ ] Chain breaks if Harken is stunned
- [ ] Chain breaks if target moves >10 tiles away
- [ ] Chain breaks if target dies
- [ ] Chain break generates 10 noise
- [ ] Tangle hitting a mech forcibly ejects the pilot
- [ ] Ejected pilot is chained and thrown toward Harken
- [ ] Mech without occupants is ignored (no chain created)
- [ ] Noise generated: 1 on throw, 5 on hit, 10 on break

### Immolate
- [ ] Immolate deals 20% of max HP as immediate self-damage
- [ ] Immolate applies DoT: 5% of max HP over 10 seconds (no status effect)
- [ ] DoT ticks every 1 second (10 ticks total)
- [ ] Blood splatter effect appears each DoT tick
- [ ] Speed boost active while bleeding
- [ ] Speed boost removed after 10 seconds when bleeding ends
- [ ] Immolate blocked while enraged
- [ ] Immolate generates 60% of max noise meter on use
- [ ] Immolate cannot be used while already bleeding

### Sprint System
- [ ] Sprint toggle action appears in ability bar
- [ ] Sprint instantly applies speed boost (no acceleration)
- [ ] Sprint drains stamina while active
- [ ] Sprint stops automatically when stamina depleted
- [ ] Cannot start sprint below minimum stamina (15%)
- [ ] Stamina regenerates when not sprinting

### Noise Meter UI
- [ ] Harken always sees the noise meter UI
- [ ] Humans do NOT see UI initially (noise < 50%)
- [ ] UI revealed to all humans when noise first reaches 50%
- [ ] UI remains visible after reveal even if noise drops below 50%
- [ ] New players joining get UI if already revealed
- [ ] UI shows correct noise/max_noise values
- [ ] UI progress bar is always orange/yellow color
- [ ] UI icon changes expression based on enrage state (calm vs angry)
- [ ] UI removed from humans when Harken dies

### General
- [ ] All cooldowns work correctly
- [ ] Harken spawns and despawns without errors
