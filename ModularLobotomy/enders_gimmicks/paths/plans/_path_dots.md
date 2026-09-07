# _path_dots.dm - Path DoT (Damage Over Time) System

## Purpose
Defines the 4 elemental DoT status effects that path abilities can apply to targets. DoTs tick periodically, deal damage through the path damage pipeline (no crit), and expire after a set duration.

---

## The 4 DoT Types

| DoT | Element | Base DMG | Duration | Notes |
|-----|---------|----------|----------|-------|
| **Bleed** | Physical | Normal: 16% target maxHP; Elite/Boss: 7% target maxHP | 20s (2 turns) | Capped at 2x attacker ATK |
| **Burn** | Fire | 100% attacker ATK | 20s (2 turns) | Flat scaling |
| **Shock** | Lightning | 200% attacker ATK | 20s (2 turns) | 2x Burn damage |
| **Wind Shear** | Wind | 100% attacker ATK * stack count | 20s (2 turns) | Up to 5 stacks |

---

## DoT Tick Timing

- **Path holders:** DoTs tick at the start of each turn (in `OnTurnReset()`)
- **Regular mobs:** DoTs tick every 5 seconds via `addtimer` loop
- DoTs cannot crit and are not affected by DMG boost effects
- DoT damage goes through: DEF Multiplier → RES Multiplier → avg_coeff

---

## Status Effect: `/datum/status_effect/path_dot`

### Variables
```
id = "path_dot"
duration = 20 SECONDS
tick_interval = -1              // Manual ticking, not auto
var/dot_type                    // PATH_DOT_BLEED, PATH_DOT_BURN, etc.
var/attacker_atk                // Snapshotted ATK at time of application
var/target_max_hp               // Snapshotted maxHealth at time of application
var/datum/path/attacker_path    // Ref to attacker's path (for DEF/RES calcs)
var/stacks = 1                  // For Wind Shear stacking
var/mob_tick_active = FALSE     // Whether this DoT is running its own timer (for non-path mobs)
```

### Subtypes
```
/datum/status_effect/path_dot/bleed
    id = "path_dot_bleed"
    dot_type = PATH_DOT_BLEED

/datum/status_effect/path_dot/burn
    id = "path_dot_burn"
    dot_type = PATH_DOT_BURN

/datum/status_effect/path_dot/shock
    id = "path_dot_shock"
    dot_type = PATH_DOT_SHOCK

/datum/status_effect/path_dot/wind_shear
    id = "path_dot_wind_shear"
    dot_type = PATH_DOT_WIND_SHEAR
```

### Procs

#### `on_apply()`
```
1. Snapshot attacker_atk from attacker_path.GetStat("ATK")
2. Snapshot target_max_hp from owner.maxHealth (simple_animal) or owner.getMaxHealth()
3. If owner is NOT a path holder, start mob tick timer:
   addtimer(CALLBACK(src, PROC_REF(MobTick)), 5 SECONDS)
   mob_tick_active = TRUE
```

#### `DoTick()`
Calculates and deals DoT damage:
```
var/base_dmg
switch(dot_type)
    if(PATH_DOT_BLEED)
        var/rate = is_boss(owner) ? 0.07 : 0.16
        base_dmg = target_max_hp * rate
        base_dmg = min(base_dmg, attacker_atk * 2)
    if(PATH_DOT_BURN)
        base_dmg = attacker_atk * 1.0
    if(PATH_DOT_SHOCK)
        base_dmg = attacker_atk * 2.0
    if(PATH_DOT_WIND_SHEAR)
        base_dmg = attacker_atk * 1.0 * stacks
// Apply through path damage pipeline (DEF, RES, avg_coeff) — no crit
var/final_dmg = apply_dot_damage_pipeline(owner, base_dmg, attacker_path)
owner.adjustHealth(final_dmg)
```

#### `MobTick()`
Timer-based tick for non-path mobs:
```
if(QDELETED(src) || QDELETED(owner))
    return
DoTick()
if(mob_tick_active)
    addtimer(CALLBACK(src, PROC_REF(MobTick)), 5 SECONDS)
```

#### `on_remove()`
```
mob_tick_active = FALSE
attacker_path = null
```

---

## Helper Proc: `apply_path_dot()`

Global proc for applying DoTs:
```dm
/proc/apply_path_dot(mob/living/target, dot_type, datum/path/source_path, duration = 20 SECONDS)
    // Wind Shear: stack instead of reapply
    if(dot_type == PATH_DOT_WIND_SHEAR)
        var/datum/status_effect/path_dot/wind_shear/existing = target.has_status_effect(/datum/status_effect/path_dot/wind_shear)
        if(existing)
            existing.stacks = min(existing.stacks + 1, 5)
            existing.duration = duration  // Refresh duration
            existing.attacker_atk = source_path.GetStat("ATK")  // Update snapshot
            return existing
    // Other DoTs: refresh if already present
    var/effect_type
    switch(dot_type)
        if(PATH_DOT_BLEED)   effect_type = /datum/status_effect/path_dot/bleed
        if(PATH_DOT_BURN)    effect_type = /datum/status_effect/path_dot/burn
        if(PATH_DOT_SHOCK)   effect_type = /datum/status_effect/path_dot/shock
        if(PATH_DOT_WIND_SHEAR) effect_type = /datum/status_effect/path_dot/wind_shear
    var/datum/status_effect/path_dot/effect = target.apply_status_effect(effect_type)
    if(effect)
        effect.attacker_path = source_path
        effect.attacker_atk = source_path.GetStat("ATK")
        effect.duration = duration
    return effect
```

---

## Integration with Turn System

In `OnTurnReset()` on `/datum/path`, after resetting turn_state:
```dm
// Tick all active DoTs on this path holder
for(var/datum/status_effect/path_dot/dot in owner.status_effects)
    dot.DoTick()
```

---

## Notes
- Wind Shear is the only stacking DoT. Reapplying adds a stack (up to 5) and refreshes duration.
- Bleed/Burn/Shock reapplying refreshes duration and updates the ATK snapshot.
- DoT damage uses `adjustHealth()` directly (bypasses `deal_damage()` aggro tracking). Consider calling `RegisterAttackAggro()` manually if aggro matters for DoTs.
- The `is_boss()` check for Bleed's reduced rate can use the mob's ordeal tier or a `var/is_boss` flag.
