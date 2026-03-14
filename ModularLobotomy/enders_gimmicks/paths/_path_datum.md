# _path_datum.dm - Base Path Datum & Abilities

## Purpose
Defines the core `/datum/path` and `/datum/path_ability` hierarchy. This is the main datum that represents a player's chosen path with its resources, stats, abilities, and skill tree.

---

## Datum: `/datum/path`

### Variables
```
var/name = "Path"
var/desc = ""
var/icon_state = ""
var/mob/living/carbon/human/owner

// --- Resources ---
var/energy = 0                  // Current energy (0 to max_energy)
var/max_energy = PATH_MAX_ENERGY_DEFAULT
var/action_points = 0           // Current AP (0 to max_action_points)
var/max_action_points = PATH_MAX_AP_DEFAULT

// --- Path Stats (separate from LC13 attributes) ---
var/list/path_stats = list()
// e.g. list("ATK" = 84, "DEF" = 62,
//           "CRIT Rate" = 5, "CRIT DMG" = 50,
//           "Max Energy" = 100, "Energy Regen Rate" = 100)

// --- Skill Tree ---
var/list/nodes = list()         // List of /datum/path_node
var/list/unlocked_nodes = list()// Node IDs that have been unlocked
var/skill_points = 0            // Points available to spend

// --- Ability Type References (set by subtypes) ---
var/basic_attack_type = /datum/path_ability/basic
var/burst_action_type = /datum/path_ability/burst
var/ultimate_type = /datum/path_ability/ultimate
var/passive_type = /datum/path_ability/passive

// --- Instantiated Abilities ---
var/datum/path_ability/basic/basic_attack
var/datum/path_ability/burst/burst_action
var/datum/path_ability/ultimate/ultimate_action
var/datum/path_ability/passive/passive_effect

// --- Action Button References ---
var/datum/action/path_burst/burst_action_button
var/datum/action/path_ultimate/ultimate_action_button
var/datum/action/path_screen/screen_action_button
```

### Procs

#### `New()`
Calls `InitNodes()` to set up the skill tree.

#### `InitNodes()`
Virtual proc. Subtypes override to populate `nodes` list with `/datum/path_node` instances.

#### `AssignTo(mob/living/carbon/human/user)`
Attaches the path to a mob:
1. Sets `owner = user`
2. Instantiates all 4 abilities from the `*_type` vars, sets their `parent_path = src`
3. Calls `passive_effect.Apply(owner)` to register passive signals
4. Creates and grants the 3 action buttons (burst, ultimate, screen) to owner
5. Registers signal handlers on owner:
   - `COMSIG_MOB_ITEM_ATTACK` -> `OnMeleeAttack()`
6. Sends `COMSIG_MOB_PATH_ASSIGNED`

#### `Remove()`
Detaches the path:
1. Calls `passive_effect.Unapply(owner)` to unregister passive signals
2. Removes all 3 action buttons from owner
3. Unregisters all signal handlers from owner
4. Sends `COMSIG_MOB_PATH_REMOVED`
5. Deletes ability instances
6. Sets `owner = null`

#### `GainEnergy(amount)`
Adds energy, clamped to `max_energy`. Sends `COMSIG_PATH_ENERGY_CHANGED`. Updates action buttons.

#### `SpendEnergy(amount)`
Subtracts energy, clamped to 0. Sends `COMSIG_PATH_ENERGY_CHANGED`. Updates action buttons.

#### `GainActionPoint()`
+1 AP, clamped to `max_action_points`. Sends `COMSIG_PATH_AP_CHANGED`. Updates action buttons.

#### `SpendActionPoint()`
-1 AP, clamped to 0. Sends `COMSIG_PATH_AP_CHANGED`. Updates action buttons.

#### `GetStat(stat_name) -> number`
Returns the base stat from `path_stats[stat_name]` plus the sum of all `stat_bonuses[stat_name]` from unlocked nodes.

#### `UnlockNode(node_id) -> boolean`
1. Finds node by ID in `nodes` list
2. Checks `node.CanUnlock(unlocked_nodes)` and `skill_points >= node.cost`
3. If valid: deducts skill points, adds ID to `unlocked_nodes`
4. Applies node effect based on `node_type`:
   - `PATH_NODE_STAT`: bonuses applied via `GetStat()` dynamically (no action needed here)
   - `PATH_NODE_ABILITY`: increases the target ability's `level` by `node.level_increase`
   - `PATH_NODE_PASSIVE`: could call a proc on the passive ability
5. Returns TRUE on success

#### `OnMeleeAttack(datum/source, mob/target, mob/user)`
Signal handler for `COMSIG_MOB_ITEM_ATTACK`:
```
SIGNAL_HANDLER
if(!isliving(target))
    return
// Use addtimer to avoid SIGNAL_HANDLER sleep restrictions
addtimer(CALLBACK(src, PROC_REF(ProcessMeleeHit), target, user), 0)
GainEnergy(basic_attack.energy_gain)
GainActionPoint()
```

#### `ProcessMeleeHit(mob/living/target, mob/living/user)`
Called via timer from signal handler. Invokes `basic_attack.OnHit(target, user)`.

---

## Datum: `/datum/path_ability`

Base datum for the 4 ability types.

### Variables
```
var/name = "Ability"
var/desc = ""
var/icon_state = ""
var/datum/path/parent_path
var/level = 1
var/max_level = 10
```

---

## Datum: `/datum/path_ability/basic`

Triggered on melee hit via signal.

### Variables
```
var/energy_gain = 10  // Energy gained per hit
```

### Procs
#### `OnHit(mob/living/target, mob/living/user)`
Virtual proc. Subtypes override to deal bonus damage, apply effects, etc. Can use `parent_path.GetStat("ATK")` for scaling.

---

## Datum: `/datum/path_ability/burst`

Activated via action button. Costs AP, grants energy.

### Variables
```
var/energy_gain = 20  // Energy gained on use
var/ap_cost = 1       // Action points consumed
```

### Procs
#### `Activate(mob/living/user)`
Virtual proc. Subtypes override with unique per-path actions. Base implementation could just send a message.

---

## Datum: `/datum/path_ability/ultimate`

Activated via action button. Requires full energy, resets to 0.

### Procs
#### `Activate(mob/living/user)`
Virtual proc. Subtypes override with powerful per-path effects. Base checks `parent_path.energy >= parent_path.max_energy`, then calls `parent_path.SpendEnergy(parent_path.energy)`.

---

## Datum: `/datum/path_ability/passive`

Registers signals for conditional triggers.

### Procs
#### `Apply(mob/living/user)`
Virtual proc. Subtypes register their own signals on the user (e.g. on damage taken, on kill, on heal, etc.)

#### `Unapply(mob/living/user)`
Virtual proc. Subtypes unregister their signals.

---

## Example Subtype Skeleton
```dm
/datum/path/destruction
    name = "Destruction"
    desc = "Focuses on dealing massive damage."
    basic_attack_type = /datum/path_ability/basic/destruction
    burst_action_type = /datum/path_ability/burst/destruction
    ultimate_type = /datum/path_ability/ultimate/destruction
    passive_type = /datum/path_ability/passive/destruction
    path_stats = list(
        "ATK" = 84, "DEF" = 62,
        "CRIT Rate" = 5, "CRIT DMG" = 50,
        "Max Energy" = 120, "Energy Regen Rate" = 100
    )

/datum/path_ability/basic/destruction/OnHit(mob/living/target, mob/living/user)
    var/bonus = parent_path.GetStat("ATK") * 0.5 * (level / max_level)
    parent_path.deal_path_damage(target, bonus)

/datum/path_ability/burst/destruction/Activate(mob/living/user)
    // AoE slam around user
    for(var/mob/living/L in range(2, user))
        if(L == user)
            continue
        parent_path.deal_path_damage(L, parent_path.GetStat("ATK") * 1.2)

/datum/path_ability/ultimate/destruction/Activate(mob/living/user)
    . = ..()
    // Massive single-target nuke
    // ...

/datum/path_ability/passive/destruction/Apply(mob/living/user)
    RegisterSignal(user, COMSIG_MOB_APPLY_DAMGE, PROC_REF(OnTakeDamage))

/datum/path_ability/passive/destruction/Unapply(mob/living/user)
    UnregisterSignal(user, COMSIG_MOB_APPLY_DAMGE)
```
