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
var/ahn_cost = 200              // Ahn cost to unlock this node
var/node_type = PATH_NODE_STAT  // "stat", "ability", or "passive"

// Gating requirements (in addition to prerequisites)
var/required_ascension = 0      // Minimum ascension phase to unlock (0 = no gate)
var/required_level = 0          // Minimum path level to unlock (0 = no gate)

// Stat node vars
var/list/stat_bonuses = list()  // Assoc list, e.g. list("ATK" = 10, "CRIT Rate" = 2)
var/stat_percent = FALSE        // If TRUE, stat_bonuses are percentage-based (e.g. "ATK" = 4 means +4% ATK)

// Ability node vars
var/ability_target = ""         // "basic", "burst", or "ultimate"
var/level_increase = 1          // Levels added to the ability

// Passive/Bonus Ability node vars
var/bonus_ability_desc = ""     // Full description of the bonus ability effect

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

#### `CanUnlock(list/unlocked_nodes, ascension_phase, path_level) -> boolean`
Returns `TRUE` if:
1. All prerequisite node IDs are present in the `unlocked_nodes` list
2. `ascension_phase >= required_ascension` (if set)
3. `path_level >= required_level` (if set)

## Trace Layout Structure

Each path's skill tree (Traces) has 3 types of unlockable nodes arranged around a central column:

### Central Column: 4 Core Ability Upgrades
The 4 core abilities (Basic ATK, Skill, Ultimate, Passive) are leveled up via ability materials (costs TBD). These are displayed in the center of the tree but are NOT skill-point nodes — they use a separate upgrade system.

### Side Nodes: 10 Stat Boosts
Small nodes around the edges that grant percentage-based stat increases. Each is gated by an ascension phase or path level. Costs 1 SP each.

The 10 stat boosts for each path use 3 stats specific to that path (e.g. Destruction uses ATK, HP, DEF):

| Gate | Stat Boosts |
|------|-------------|
| None | Stat A +4% |
| Ascension 2 | Stat B +4%, Stat A +4% |
| Ascension 3 | Stat C +5% |
| Ascension 4 | Stat A +6%, Stat B +6% |
| Ascension 5 | Stat A +6% |
| Ascension 6 | Stat C +7.5%, Stat B +8% |
| Level 75 | — |
| Level 80 | Stat A +8% |

### Side Nodes: 3 Bonus Abilities
Larger nodes that unlock unique passive effects. Gated by ascension 2, 4, and 6. Costs 1 SP each.

---

## Example: Destruction Traces

**3 Stats:** ATK, HP, DEF
**3 Bonus Abilities:**
- **A2 — Ready for Battle:** At the start of combat, immediately regenerate 15 Energy.
- **A4 — Tenacity:** Each Passive (Perfect Pickoff) stack also increases DEF by 10%.
- **A6 — Fighting Will:** When using Skill or Ultimate "Blowout: RIP Home Run," DMG dealt to the primary target is increased by 25%.

**10 Stat Boosts:**
1. ATK +4% (no gate)
2. HP +4% (A2)
3. ATK +4% (A2)
4. DEF +5% (A3)
5. ATK +6% (A4)
6. HP +6% (A4)
7. ATK +6% (A5)
8. DEF +7.5% (A6)
9. HP +8% (Lv.75)
10. ATK +8% (Lv.80)

## How Subtypes Define Nodes
Specific paths create nodes in their `InitNodes()` proc. Nodes are arranged in a branching diamond pattern around the center column, with connections defining the visual lines between nodes.

**Destruction layout:**
```
        [atk1]-------[hp1]
       /                    \
  [bonus_a2]  (Basic/Skill)  [atk2]
       \                    /
        [def1]-------[atk3]
       /                    \
  [bonus_a4]  (Ult/Passive)  [hp2]
       \                    /
        [atk4]-------[def2]
       /                    \
  [bonus_a6]                [hp3]
       \                    /
        [atk5]
```

```dm
/datum/path/destruction/InitNodes()
    var/datum/path_node/N

    // --- Top branch (no gate / A2) ---
    N = new /datum/path_node("atk1", "ATK Boost", "ATK increases by 4%.")
    N.stat_bonuses = list("ATK" = 4)
    N.stat_percent = TRUE
    N.ahn_cost = 200
    N.tree_x = 1
    N.tree_y = 0
    N.connections = list("hp1", "bonus_a2")
    nodes += N

    N = new /datum/path_node("hp1", "HP Boost", "Max HP increases by 4%.")
    N.stat_bonuses = list("HP" = 4)
    N.stat_percent = TRUE
    N.ahn_cost = 300
    N.required_ascension = 2
    N.tree_x = 3
    N.tree_y = 0
    N.connections = list("atk2")
    nodes += N

    N = new /datum/path_node("bonus_a2", "Ready for Battle", "At the start of combat, immediately regenerate 15 Energy.")
    N.node_type = PATH_NODE_PASSIVE
    N.ahn_cost = 1000
    N.required_ascension = 2
    N.tree_x = 0
    N.tree_y = 1
    N.connections = list("def1")
    nodes += N

    N = new /datum/path_node("atk2", "ATK Boost", "ATK increases by 4%.")
    N.stat_bonuses = list("ATK" = 4)
    N.stat_percent = TRUE
    N.ahn_cost = 300
    N.required_ascension = 2
    N.tree_x = 4
    N.tree_y = 1
    N.connections = list("atk3")
    nodes += N

    // --- Middle branch (A3 / A4) ---
    N = new /datum/path_node("def1", "DEF Boost", "DEF increases by 5%.")
    N.stat_bonuses = list("DEF" = 5)
    N.stat_percent = TRUE
    N.ahn_cost = 400
    N.required_ascension = 3
    N.tree_x = 1
    N.tree_y = 2
    N.connections = list("atk3", "bonus_a4")
    nodes += N

    N = new /datum/path_node("atk3", "ATK Boost", "ATK increases by 6%.")
    N.stat_bonuses = list("ATK" = 6)
    N.stat_percent = TRUE
    N.ahn_cost = 500
    N.required_ascension = 4
    N.tree_x = 3
    N.tree_y = 2
    N.connections = list("hp2")
    nodes += N

    N = new /datum/path_node("bonus_a4", "Tenacity", "Each Passive stack also increases DEF by 10%.")
    N.node_type = PATH_NODE_PASSIVE
    N.ahn_cost = 1000
    N.required_ascension = 4
    N.tree_x = 0
    N.tree_y = 3
    N.connections = list("atk4")
    nodes += N

    N = new /datum/path_node("hp2", "HP Boost", "Max HP increases by 6%.")
    N.stat_bonuses = list("HP" = 6)
    N.stat_percent = TRUE
    N.ahn_cost = 500
    N.required_ascension = 4
    N.tree_x = 4
    N.tree_y = 3
    N.connections = list("def2")
    nodes += N

    // --- Bottom branch (A5 / A6 / Lv75 / Lv80) ---
    N = new /datum/path_node("atk4", "ATK Boost", "ATK increases by 6%.")
    N.stat_bonuses = list("ATK" = 6)
    N.stat_percent = TRUE
    N.ahn_cost = 600
    N.required_ascension = 5
    N.tree_x = 1
    N.tree_y = 4
    N.connections = list("def2", "bonus_a6")
    nodes += N

    N = new /datum/path_node("def2", "DEF Boost", "DEF increases by 7.5%.")
    N.stat_bonuses = list("DEF" = 7.5)
    N.stat_percent = TRUE
    N.ahn_cost = 700
    N.required_ascension = 6
    N.tree_x = 3
    N.tree_y = 4
    N.connections = list("hp3")
    nodes += N

    N = new /datum/path_node("bonus_a6", "Fighting Will", "Skill/Ult RIP Home Run deals 25% more DMG to primary target.")
    N.node_type = PATH_NODE_PASSIVE
    N.ahn_cost = 1000
    N.required_ascension = 6
    N.tree_x = 0
    N.tree_y = 5
    N.connections = list("atk5")
    nodes += N

    N = new /datum/path_node("hp3", "HP Boost", "Max HP increases by 8%.")
    N.stat_bonuses = list("HP" = 8)
    N.stat_percent = TRUE
    N.ahn_cost = 750
    N.required_level = 75
    N.tree_x = 4
    N.tree_y = 5
    nodes += N

    N = new /datum/path_node("atk5", "ATK Boost", "ATK increases by 8%.")
    N.stat_bonuses = list("ATK" = 8)
    N.stat_percent = TRUE
    N.ahn_cost = 800
    N.required_level = 80
    N.tree_x = 1
    N.tree_y = 6
    nodes += N
```
