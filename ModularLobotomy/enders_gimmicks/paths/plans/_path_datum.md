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
// e.g. list("ATK" = 84, "DEF" = 62, "SPD" = 100,
//           "CRIT Rate" = 5, "CRIT DMG" = 50,
//           "Max Energy" = 100, "Energy Regen Rate" = 100)

// --- Turn System ---
var/turn_state = PATH_TURN_READY    // Current turn state (READY/ATTACKED/SKILLED)
var/next_turn_time = 0              // world.time when next turn starts
var/swings_per_turn = 6             // Calculated: how many weapon swings fit in one turn

// --- Skill Tree (Traces) ---
var/list/nodes = list()         // List of /datum/path_node
var/list/unlocked_nodes = list()// Node IDs that have been unlocked
// Traces are unlocked by spending ahn (no skill points)

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

// --- Weapon ---
var/obj/item/ego_weapon/path_weapon/weapon
var/path_weapon_type = /obj/item/ego_weapon/path_weapon  // Subtypes override for custom weapons

// --- Action Button References ---
var/datum/action/path_ultimate/ultimate_action_button
var/datum/action/path_screen/screen_action_button
var/datum/action/cooldown/path_designate_ally/ally_action_button
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
4. Creates the path weapon from `path_weapon_type`, sets `weapon.linked_path = src`, puts in user's hands
5. Creates and grants 3 action buttons (ultimate, screen, designate ally) to owner
6. Calls `StartTurnCycle()` to begin the turn timer
7. Sends `COMSIG_MOB_PATH_ASSIGNED`

#### `Remove()`
Detaches the path:
1. Calls `passive_effect.Unapply(owner)` to unregister passive signals
2. Removes all action buttons from owner
3. Qdels the path weapon (`weapon.linked_path = null`, `QDEL_NULL(weapon)`)
4. Calls `ClearAllyList(owner)` to clean up designated allies
5. Sends `COMSIG_MOB_PATH_REMOVED`
5. Deletes ability instances
6. Sets `owner = null`

#### `OnWeaponHit(mob/living/target, mob/living/user)`
Called by the path weapon's `attack()` proc. Always deals damage, but AP/energy gated by turn state:
```
if(!isliving(target))
    return
// Always deal damage (scaled per-swing: total scaling / swings_per_turn)
basic_attack.OnHit(target, user, swings_per_turn)
// Only grant resources on first hit of an attack turn
if(turn_state == PATH_TURN_READY)
    GainEnergy(basic_attack.energy_gain)
    GainActionPoint()
    turn_state = PATH_TURN_ATTACKED
```

#### `GetTurnDuration() -> number`
Returns the current turn duration in deciseconds:
```
return PATH_TURN_BASE * PATH_BASE_SPEED / max(GetStat("SPD"), 1)
```

#### `StartTurnCycle()`
Called from `AssignTo()`. Starts the recurring turn timer:
```
RecalcSwingsPerTurn()
OnTurnReset()
```

#### `OnTurnReset()`
Called by timer each turn cycle. Ticks DoTs, resets turn state, and queues next turn:
```
// Tick all active DoTs on this path holder BEFORE the turn starts
for(var/datum/status_effect/path_dot/dot in owner.status_effects)
    dot.DoTick()
// Reset turn state
turn_state = PATH_TURN_READY
next_turn_time = world.time + GetTurnDuration()
addtimer(CALLBACK(src, PROC_REF(OnTurnReset)), GetTurnDuration())
```

#### `RecalcSwingsPerTurn()`
Recalculates how many weapon swings fit in one turn (for DPS normalization):
```
var/turn_dur = GetTurnDuration() / 10  // convert to seconds
var/swing_interval = CLICK_CD_MELEE * weapon.attack_speed / 10
swings_per_turn = max(round(turn_dur / swing_interval), 1)
```

---

## SPD Debuff System

### `apply_path_spd_change(mob/living/target, spd_percent, duration)`
Global proc that applies SPD changes contextually based on target type:
- **Path holder** (human with path): modifies their SPD stat → slows/speeds turn cycle
- **Simple mob** (ordeal, hostile): slows movement speed via `set_varspeed()`
- **Non-path carbon** (human without path): slows movement speed via movespeed modifier

Also applies a `/datum/status_effect/path_spd_debuff` status effect for tracking (so abilities can check `has_path_spd_debuff()`).

### `has_path_spd_debuff(mob/living/target) -> boolean`
Global proc. Returns TRUE if the target has an active path SPD debuff status effect. Used by abilities like Hunt's Ultimate to check for bonus damage conditions.

---

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
2. Checks `node.CanUnlock(unlocked_nodes, ascension_phase, path_level)`
3. Checks owner has enough ahn: `owner.bank_account.has_money(node.ahn_cost)`
4. If valid: deducts ahn via `owner.bank_account.adjust_money(-node.ahn_cost)`, adds ID to `unlocked_nodes`
5. Applies node effect based on `node_type`:
   - `PATH_NODE_STAT`: bonuses applied via `GetStat()` dynamically (percentage or flat based on `stat_percent`)
   - `PATH_NODE_ABILITY`: increases the target ability's `level` by `node.level_increase`
   - `PATH_NODE_PASSIVE`: activates the bonus ability effect
6. Returns TRUE on success

*(Signal-based OnMeleeAttack/ProcessMeleeHit removed — replaced by weapon-driven `OnWeaponHit()` above.)*

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

Triggered when the path weapon's `attack()` hits a target (via `OnWeaponHit()`).

### Variables
```
var/energy_gain = 10  // Energy gained per hit
```

### Procs
#### `OnHit(mob/living/target, mob/living/user)`
Virtual proc. Subtypes override to deal bonus damage, apply effects, etc. Can use `parent_path.GetStat("ATK")` for scaling.

---

## Datum: `/datum/path_ability/burst`

Activated via the path weapon's `attack_self()`. Costs AP, grants energy. Has a 5-second cooldown between uses.

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
