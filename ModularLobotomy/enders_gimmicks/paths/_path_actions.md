# _path_actions.dm - Action Button Datums

## Purpose
Defines the 3 action buttons granted to a mob when they have a path: Burst, Ultimate, and Path Screen opener.

## Codebase Pattern Reference
Actions follow the `/datum/action` pattern from `code/datums/action.dm`:
- Override `Trigger()` for activation logic
- Override `Grant(mob)` / `Remove(mob)` for setup/cleanup
- Set `icon_icon`, `button_icon_state` for the HUD button appearance
- Call `UpdateButtonIcon()` to refresh visuals

---

## Datum: `/datum/action/path_burst`

### Variables
```
name = "Burst Action"
desc = "Spend an Action Point to perform your path's Burst ability."
icon_icon = 'icons/hud/actions.dmi'  // Or a custom path icons file
button_icon_state = "path_burst"
var/datum/path/linked_path
```

### Procs

#### `Trigger()`
```
. = ..()
if(!.)
    return
if(!linked_path || !linked_path.burst_action)
    return
if(linked_path.action_points < linked_path.burst_action.ap_cost)
    to_chat(owner, span_warning("Not enough Action Points!"))
    return
linked_path.SpendActionPoint()
linked_path.GainEnergy(linked_path.burst_action.energy_gain)
linked_path.burst_action.Activate(owner)
```

#### `UpdateButtonIcon()`
Could show AP count on the button or gray out if insufficient AP.

---

## Datum: `/datum/action/path_ultimate`

### Variables
```
name = "Ultimate Action"
desc = "At maximum energy, unleash your path's Ultimate ability."
button_icon_state = "path_ultimate"
var/datum/path/linked_path
```

### Procs

#### `Trigger()`
```
. = ..()
if(!.)
    return
if(!linked_path || !linked_path.ultimate_action)
    return
if(linked_path.energy < linked_path.max_energy)
    to_chat(owner, span_warning("Not enough Energy! ([linked_path.energy]/[linked_path.max_energy])"))
    return
linked_path.ultimate_action.Activate(owner)
// Note: The ultimate's Activate() calls SpendEnergy internally
```

#### `UpdateButtonIcon()`
Could glow/highlight when energy is full. Change `button_icon_state` based on energy state.

---

## Datum: `/datum/action/path_screen`

### Variables
```
name = "Path Screen"
desc = "Open your Path details and skill tree."
button_icon_state = "path_screen"
var/datum/path/linked_path
```

### Procs

#### `Trigger()`
```
. = ..()
if(!.)
    return
if(!linked_path)
    return
linked_path.ui_interact(owner)
```

---

## Notes
- All three actions store a `linked_path` reference set during `AssignTo()`.
- Actions are granted via `action.Grant(owner)` and removed via `action.Remove(owner)`.
- Button icons will need sprites added to an icon file (can use placeholder states initially).
- The burst/ultimate buttons should call `UpdateButtonIcon()` whenever energy/AP changes (triggered by the path's `GainEnergy`/`SpendEnergy`/etc. procs).
