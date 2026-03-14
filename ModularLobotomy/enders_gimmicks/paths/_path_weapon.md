# _path_weapon.dm - Path Weapon System

## Purpose
Defines `/obj/item/ego_weapon/path_weapon`, a custom EGO weapon subtype that serves as the physical conduit for all path abilities except Ultimate and Passive. The weapon's `attack()` IS the Basic Attack. The weapon's `attack_self()` IS the Burst/Skill.

This eliminates the damage-stacking problem: the weapon has `force = 0`, so the normal LC13 damage formula (`force * justice_mod * crit_bonus`) produces zero. Path damage is dealt separately via the path's own damage system.

## Why Not Use Normal Weapons?
If the path's Basic Attack triggered on any melee weapon hit (via `COMSIG_MOB_ITEM_ATTACK`), path damage would **stack** with normal EGO weapon damage. By giving each path its own weapon, we ensure the player deals ONLY path damage when attacking — no double-dipping.

---

## Datum: `/obj/item/ego_weapon/path_weapon`

### Variables
```
name = "Path Weapon"
desc = "A weapon manifested from your chosen path."
icon = 'icons/obj/ego_weapons.dmi'
icon_state = ""                         // Set by subtypes
force = 0                               // CRITICAL: zero force = no LC13 damage
damtype = RED_DAMAGE                    // Cosmetic only
attribute_requirements = list()         // No stat gating, path gates access
knockback = FALSE                       // Path abilities handle their own knockback
w_class = WEIGHT_CLASS_BULKY
swingstyle = WEAPONSWING_SMALLSWEEP

/// Reference to the owning path datum
var/datum/path/linked_path

/// The EGO weapon type currently being mimicked (null = default appearance)
var/disguised_as_type

/// Cooldown for Burst/Skill (5 second cooldown)
var/next_skill_use = 0

/// Base attack speed before disguise modification
var/base_attack_speed = 1
```

### Procs

#### `Initialize()`
```
. = ..()
ADD_TRAIT(src, TRAIT_NODROP, ABSTRACT_ITEM_TRAIT)
```
Adds `TRAIT_NODROP` to prevent dropping, trading, or theft. The weapon exists only while the path is assigned.

#### `attack(mob/living/target, mob/living/user)`
```
if(!linked_path)
    to_chat(user, span_warning("This weapon has no path linked!"))
    return FALSE
. = ..()   // Parent handles animation, signals, sweep — attacked_by() does nothing (force=0)
if(!.)
    return
linked_path.OnWeaponHit(target, user)
```

**How force=0 works:** In `item_attack.dm:285`, `attacked_by()` checks `if(I.force)`. With force=0, the entire LC13 damage calculation is skipped. The parent `attack()` still runs animations, sends signals (`COMSIG_MOB_ITEM_ATTACK`), and handles the sweep system.

**Sound:** force=0 triggers `tap.ogg` at `item_attack.dm:242`. The path weapon should set its own `hitsound` and play it in the attack override, or each path weapon subtype sets an appropriate hitsound.

**DPS normalization (Turn-based):** Ability scaling (e.g. "50% of ATK") represents the **total damage for one attack turn**, divided across all swings:
```
swings_per_turn = turn_duration / (CLICK_CD_MELEE * attack_speed)
per_swing_damage = (ATK * ability_scaling%) / swings_per_turn
```
Faster weapons swing more often for less per hit. Slower weapons swing less for more per hit. Total damage per turn is always the ability scaling % of ATK.

#### `attack_self(mob/living/user)`
```
if(!linked_path || !linked_path.burst_action)
    return
if(linked_path.turn_state != PATH_TURN_READY)
    to_chat(user, span_warning("You already acted this turn!"))
    return
if(linked_path.action_points < linked_path.burst_action.ap_cost)
    to_chat(user, span_warning("Not enough Action Points!"))
    return
linked_path.SpendActionPoint()
linked_path.GainEnergy(linked_path.burst_action.energy_gain)
linked_path.burst_action.Activate(user)
linked_path.turn_state = PATH_TURN_SKILLED
```
Skill usage consumes the current turn (no separate cooldown). Must be in TURN_READY state — cannot Skill if you already attacked this turn.

#### `CanUseEgo(mob/user)`
```
return !!linked_path
```
Always usable if linked to a valid path. No attribute requirements.

#### `examine(mob/user)`
Override to show path-relevant info instead of standard EGO weapon stats:
- Path name and description
- ATK, element type
- Ability names and levels
- Energy and AP status
- Skill cooldown remaining (if any)

Does NOT show force, damtype, or attribute requirements.

---

## Appearance Disguise System

### `/datum/action/item_action/path_weapon_disguise`

HUD action button granted alongside the weapon. Opens a selection list of all EGO weapon types.

#### Variables
```
name = "Change Weapon Appearance"
button_icon_state = "yourstate"
```

#### `Trigger()`
```
if(!IsAvailable())
    return
var/obj/item/ego_weapon/path_weapon/PW = target
PW.SelectDisguise(owner)
```

### `SelectDisguise(mob/user)` on path_weapon
Opens an input list of all `/obj/item/ego_weapon` subtypes (excluding path weapons). On selection, calls `ApplyDisguise()`.

### `ApplyDisguise(ego_type)` on path_weapon
Copies visual and feel properties from the selected EGO weapon type using the chameleon pattern (`code/modules/clothing/chameleon.dm:217`):

**Copied (visual + feel):**
- `name`, `desc`
- `icon`, `icon_state`, `inhand_icon_state`
- `lefthand_file`, `righthand_file`
- `hitsound`
- `swingstyle`, `reach`, `attack_speed`

**NOT copied (mechanical — path handles these):**
- `force`, `damtype`, `force_multiplier`
- `crit_multiplier`, `knockback`, `stuntime`
- `attribute_requirements`
- Any special behavior procs

After applying, calls `update_icon()` and updates the owner's hand overlays.

### `ClearDisguise()` on path_weapon
Restores original path weapon appearance. Resets all copied properties to their initial values.

---

## Per-Path Weapon Subtypes

Each path defines its own weapon subtype for a unique default appearance:
```dm
/obj/item/ego_weapon/path_weapon/destruction
    name = "Destruction Blade"
    desc = "A weapon crackling with destructive energy."
    icon_state = "existingstate"
    hitsound = 'sound/weapons/bladeslice.ogg'
    swingstyle = WEAPONSWING_LARGESWEEP

/datum/path/destruction
    path_weapon_type = /obj/item/ego_weapon/path_weapon/destruction
```

---

## Integration with Path Datum

The path weapon lifecycle is managed by `/datum/path`:

**In `AssignTo()`:**
1. `weapon = new path_weapon_type()`
2. `weapon.linked_path = src`
3. `user.put_in_hands(weapon)`

**In `Remove()`:**
1. `weapon.linked_path = null`
2. `QDEL_NULL(weapon)`

---

## Edge Cases

| Case | Handling |
|------|----------|
| Drop/trade weapon | `TRAIT_NODROP` prevents it |
| Path removed mid-combat | `Remove()` qdels weapon safely (BYOND handles mid-animation deletion) |
| Sweep/multi-hit | Parent sweep calls `attack()` per target; each triggers `OnWeaponHit()` |
| Examine while disguised | Shows path stats, not the mimicked weapon's stats |
| Disguise + sweep | Copied swingstyle/reach affect sweep geometry; path damage is applied per hit |
