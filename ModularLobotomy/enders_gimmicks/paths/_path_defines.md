# _path_defines.dm - Constants & Signal Defines

## Purpose
Central file for all constants, defines, and signal strings used by the path system.

## Defines

### Resource Defaults
| Define | Value | Description |
|--------|-------|-------------|
| `PATH_MAX_ENERGY_DEFAULT` | 100 | Default max energy for a path |
| `PATH_MAX_AP_DEFAULT` | 5 | Hard cap for action points |

### Skill Tree Node Types
| Define | Value | Description |
|--------|-------|-------------|
| `PATH_NODE_STAT` | `"stat"` | Node grants stat bonuses |
| `PATH_NODE_ABILITY` | `"ability"` | Node levels up an ability |
| `PATH_NODE_PASSIVE` | `"passive"` | Node unlocks/upgrades passive |

### Ability Target Strings
| Define | Value |
|--------|-------|
| `PATH_ABILITY_BASIC` | `"basic"` |
| `PATH_ABILITY_BURST` | `"burst"` |
| `PATH_ABILITY_ULTIMATE` | `"ultimate"` |

### Elemental Types
| Define | Value |
|--------|-------|
| `PATH_ELEMENT_PHYSICAL` | `"physical"` |
| `PATH_ELEMENT_FIRE` | `"fire"` |
| `PATH_ELEMENT_ICE` | `"ice"` |
| `PATH_ELEMENT_LIGHTNING` | `"lightning"` |
| `PATH_ELEMENT_WIND` | `"wind"` |
| `PATH_ELEMENT_QUANTUM` | `"quantum"` |
| `PATH_ELEMENT_IMAGINARY` | `"imaginary"` |

### RES Defaults
| Define | Value | Description |
|--------|-------|-------------|
| `PATH_RES_DEFAULT` | 20 | 20% RES to non-weak elements |
| `PATH_RES_WEAK` | 0 | 0% RES to weak element |
| `PATH_RES_BOSS` | 40 | 40% RES for boss/white enemies |
| `PATH_RES_MIN` | -100 | Min effective RES after PEN (clamp) |
| `PATH_RES_MAX` | 90 | Max effective RES after PEN (clamp) |

### Custom Signals
| Define | String | Args | Description |
|--------|--------|------|-------------|
| `COMSIG_MOB_PATH_ASSIGNED` | `"mob_path_assigned"` | (datum/path) | Sent when a path is assigned to a mob |
| `COMSIG_MOB_PATH_REMOVED` | `"mob_path_removed"` | (datum/path) | Sent when a path is removed |
| `COMSIG_PATH_ENERGY_CHANGED` | `"path_energy_changed"` | (new_energy, max_energy) | Energy value changed |
| `COMSIG_PATH_AP_CHANGED` | `"path_ap_changed"` | (new_ap, max_ap) | Action points changed |

## Notes
- These signals are custom to the path system and don't conflict with existing codebase signals.
- The existing signals we hook into (not defined here, already exist): `COMSIG_MOB_ITEM_ATTACK`, `COMSIG_MOB_APPLY_DAMGE` (note: existing typo in codebase).
