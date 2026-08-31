# _path_component.dm - Mob Component for Path Attachment

## Purpose
Optional `/datum/component/path_holder` that attaches to a mob to manage their active path. This provides a clean interface layer between the mob and the path system, and allows easy checking of whether a mob has a path.

## Decision: Component vs Direct Attachment
The plan's `/datum/path` already has `AssignTo()`/`Remove()` which handle signal registration directly. The component adds value by:
1. Providing `GetComponent()` / `HasComponent()` checks on the mob
2. Handling cleanup on mob deletion via component lifecycle
3. Allowing multiple systems to query "does this mob have a path?" without knowing path internals

If this layer feels unnecessary, it can be skipped and `AssignTo()`/`Remove()` on the path datum handle everything directly. The DM files can be consolidated.

---

## Datum: `/datum/component/path_holder`

### Variables
```
var/datum/path/active_path
```

### Procs

#### `Initialize(datum/path/new_path)`
```
if(!isliving(parent))
    return COMPONENT_INCOMPATIBLE
active_path = new_path
active_path.AssignTo(parent)
```

#### `Destroy()`
```
if(active_path)
    active_path.Remove()
    QDEL_NULL(active_path)
return ..()
```

#### `RegisterWithParent()`
Standard component signal registration. Could register:
- `COMSIG_PARENT_QDELETING` -> cleanup

#### `UnregisterFromParent()`
Standard component signal unregistration.

---

## Helper Procs (global or on mob)

### `/mob/living/carbon/human/proc/GetPath() -> /datum/path`
```dm
var/datum/component/path_holder/holder = GetComponent(/datum/component/path_holder)
if(!holder)
    return null
return holder.active_path
```

### `/mob/living/carbon/human/proc/HasPath() -> boolean`
```dm
return !!GetPath()
```

### `/mob/living/carbon/human/proc/GrantPath(path_type)`
```dm
if(GetPath())
    return FALSE  // Already has a path
var/datum/path/new_path = new path_type()
AddComponent(/datum/component/path_holder, new_path)
return TRUE
```

### `/mob/living/carbon/human/proc/RemovePath()`
```dm
var/datum/component/path_holder/holder = GetComponent(/datum/component/path_holder)
if(!holder)
    return FALSE
qdel(holder)
return TRUE
```

---

## Notes
- The component approach is the idiomatic SS13 way to attach behaviors to mobs.
- If the component is skipped, the path datum handles everything itself and the mob just stores a `var/datum/path/active_path` reference somewhere (e.g. on a species var or a global tracking list).
- The path weapon lifecycle (creation, equipping, deletion) is managed by the path datum's `AssignTo()`/`Remove()` procs — the component does not need to handle weapon logic directly.
