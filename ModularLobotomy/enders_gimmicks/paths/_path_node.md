# _path_node.dm - Skill Tree Node Datum

## Purpose
Defines `/datum/path_node`, the individual nodes in a path's skill tree. Each node can grant stat bonuses, level up abilities, or unlock passive effects.

## Datum: `/datum/path_node`

### Variables
```
var/id = ""                     // Unique node ID within the path (e.g. "atk1", "basic_lv2")
var/name = "Node"               // Display name
var/desc = ""                   // Description shown in UI
var/icon_state = ""             // Icon state for UI display
var/list/prerequisites = list() // Node IDs that must be unlocked first
var/cost = 1                    // Skill points to unlock
var/node_type = PATH_NODE_STAT  // "stat", "ability", or "passive"

// Stat node vars
var/list/stat_bonuses = list()  // Assoc list, e.g. list("ATK" = 10, "CRIT Rate" = 2)

// Ability node vars
var/ability_target = ""         // "basic", "burst", or "ultimate"
var/level_increase = 1          // Levels added to the ability

// UI positioning
var/tree_x = 0                  // X position in skill tree grid
var/tree_y = 0                  // Y position in skill tree grid
var/list/connections = list()   // Node IDs this connects to visually (for drawing lines)
```

### Procs

#### `New(new_id, new_name, new_desc)`
Optional convenience args for inline construction.

#### `GetNodeData(list/unlocked_nodes) -> list`
Returns an assoc list of all node data for the TGUI. Includes:
- All display vars (id, name, desc, icon_state, cost, node_type, tree_x, tree_y)
- `connections` and `prerequisites` lists
- `unlocked` boolean (checks if `id` is in `unlocked_nodes`)
- Conditional: `stat_bonuses` for stat nodes, `ability_target`/`level_increase` for ability nodes

#### `CanUnlock(list/unlocked_nodes) -> boolean`
Returns `TRUE` if all prerequisite node IDs are present in the `unlocked_nodes` list.

## How Subtypes Define Nodes
Specific paths create nodes in their `InitNodes()` proc:
```dm
/datum/path/destruction/InitNodes()
    var/datum/path_node/N

    N = new /datum/path_node("atk1", "ATK +10", "Increases ATK by 10.")
    N.stat_bonuses = list("ATK" = 10)
    N.tree_x = 2
    N.tree_y = 0
    N.connections = list("atk2")
    nodes += N

    N = new /datum/path_node("basic_lv2", "Basic Lv.2")
    N.node_type = PATH_NODE_ABILITY
    N.ability_target = PATH_ABILITY_BASIC
    N.level_increase = 1
    N.prerequisites = list("atk1")
    N.tree_x = 2
    N.tree_y = 1
    nodes += N
```
