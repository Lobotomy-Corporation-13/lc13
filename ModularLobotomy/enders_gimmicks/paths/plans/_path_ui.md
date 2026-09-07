# _path_ui.dm - DM-side TGUI Procs

## Purpose
Adds `ui_interact()`, `ui_data()`, and `ui_act()` procs to `/datum/path` so it can drive the PathScreen TGUI interface.

## Codebase Pattern Reference
Follows the datum TGUI pattern from `code/datums/spawners_menu.dm` and `code/datums/components/uplink.dm`:
- `ui_state()` returns an access state (e.g. `GLOB.always_state` or `GLOB.inventory_state`)
- `ui_interact()` uses `SStgui.try_update_ui()` pattern
- `ui_data()` returns assoc list consumed by React
- `ui_act()` handles actions from React via `switch(action)`

---

## Procs on `/datum/path`

### `ui_state(mob/user)`
```dm
return GLOB.always_state
```
The path screen should always be accessible to the owner.

### `ui_interact(mob/user, datum/tgui/ui)`
```dm
ui = SStgui.try_update_ui(user, src, ui)
if(!ui)
    ui = new(user, src, "PathScreen")
    ui.open()
```

### `ui_data(mob/user) -> list`
Returns all data needed by both tabs of the UI:

```
{
    // Path identity
    "path_name": "Destruction",
    "path_desc": "Focuses on dealing massive damage.",
    "path_icon": "destruction",

    // Resources
    "energy": 75,
    "max_energy": 120,
    "action_points": 3,
    "max_action_points": 5,

    // Path stats (base + node bonuses, computed via GetStat)
    "stats": {
        "HP": 163,
        "ATK": 94,        // 84 base + 10 from node
        "DEF": 62,
        "CRIT Rate": 5,
        "CRIT DMG": 50,
        "Max Energy": 120,
        "Energy Regen Rate": 100
    },

    // Abilities (4 entries)
    "abilities": [
        {
            "name": "Destructive Strike",
            "desc": "Deals bonus damage on hit.",
            "type": "basic",
            "level": 2,
            "max_level": 10,
            "icon": "basic_destruction"
        },
        {
            "name": "Seismic Slam",
            "desc": "AoE damage around you.",
            "type": "burst",
            "level": 1,
            "max_level": 10,
            "icon": "burst_destruction"
        },
        {
            "name": "Annihilation",
            "desc": "Massive single-target nuke.",
            "type": "ultimate",
            "level": 1,
            "max_level": 10,
            "icon": "ult_destruction"
        },
        {
            "name": "Berserker's Fury",
            "desc": "Gain ATK when below 50% HP.",
            "type": "passive",
            "level": 1,
            "max_level": 10,
            "icon": "passive_destruction"
        }
    ],

    // Skill tree nodes (Traces)
    "nodes": [
        {
            "id": "atk1",
            "name": "ATK Boost",
            "desc": "ATK increases by 4%.",
            "icon_state": "",
            "ahn_cost": 200,
            "node_type": "stat",
            "tree_x": 1,
            "tree_y": 0,
            "connections": ["hp1", "bonus_a2"],
            "prerequisites": [],
            "required_ascension": 0,
            "required_level": 0,
            "unlocked": true,
            "stat_bonuses": {"ATK": 4},
            "stat_percent": true
        },
        // ... more nodes
    ],

    // Player's current ahn balance (for UI display)
    "player_ahn": 5000,

    // LC13 attributes (for reference display)
    "lc13_attributes": {
        "Fortitude": 45,
        "Prudence": 32,
        "Temperance": 28,
        "Justice": 51
    }
}
```

### `ui_act(action, params)`
```dm
. = ..()
if(.)
    return

switch(action)
    if("unlock_node")
        var/node_id = params["node_id"]
        if(!node_id)
            return
        if(UnlockNode(node_id))
            . = TRUE
```

---

## DM Implementation Notes
- `ui_data` computes stats dynamically via `GetStat()` for each stat key
- LC13 attributes fetched via `get_modified_attribute_level(owner, FORTITUDE_ATTRIBUTE)` etc.
- Abilities list built by iterating the 4 ability instances and reading their vars
- Nodes list built by calling `node.GetNodeData(unlocked_nodes)` for each node
- The UI auto-updates on interaction (default TGUI behavior), so stat changes from node unlocks are reflected immediately
