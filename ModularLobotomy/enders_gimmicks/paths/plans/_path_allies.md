# _path_allies.dm - Path Ally Designation System

## Purpose
Allows Pathstriders to designate nearby humans as allies. Allies benefit from supportive path abilities (Harmony buffs, Preservation shields, Abundance heals, Erudition passive triggers, etc.).

Adapted from the association `designate_ally` system but tied to the path system instead of association squads.

---

## Core Concept

Path abilities that reference "allies" use this system to determine who benefits:
- **Self** is always considered an ally
- Other players must be explicitly designated via the action button
- Allies are stored per-mob in a global list (`GLOB.path_ally_lists`)
- The ally list persists until the path is removed or allies are manually toggled off

---

## Datum: `/datum/action/cooldown/path_designate_ally`

### Variables
```
name = "Designate Ally"
desc = "Select a nearby player to toggle ally status."
icon_icon = 'icons/hud/actions.dmi'
button_icon_state = "yourstate"
cooldown_time = 1 SECONDS
var/datum/path/linked_path
```

### `Trigger()`
1. Scans `view(7, user)` for living humans (excludes self and dead)
2. Shows each with "(ADD)" or "(REMOVE)" label based on current status
3. Opens `tgui_input_list` to select a player
4. Toggles them in/out of the ally list
5. Notifies both players

---

## Helper Procs

| Proc | Description |
|------|-------------|
| `GetAllyList(mob/living/carbon/human/H)` | Gets or creates the ally list for a mob |
| `ClearAllyList(mob/living/carbon/human/H)` | Clears all allies and notifies them (called on path removal) |
| `IsPathAlly(mob/living/source, mob/living/target)` | Returns TRUE if target is source's ally (self always TRUE) |
| `GetPathAlliesInRange(mob/living/source, range_tiles)` | Returns list of allies within X tiles (including self) |

---

## Integration with Path Abilities

Path abilities use `GetPathAlliesInRange()` to find targets for supportive effects:

```dm
// Harmony Skill example: buff allies within 3 tiles
/datum/path_ability/burst/harmony/Activate(mob/living/user)
    var/list/allies = GetPathAlliesInRange(user, 3)
    for(var/mob/living/ally in allies)
        // Apply ATK buff to ally for 20 seconds
```

```dm
// Preservation Passive example: redirect damage from nearby ally
/datum/path_ability/passive/preservation/Apply(mob/living/user)
    RegisterSignal(user, COMSIG_MOB_APPLY_DAMGE, PROC_REF(OnNearbyAllyDamaged))
```

```dm
// Erudition Passive: triggers on ANY ally pushing enemy to 50% HP
// Checks IsPathAlly() to validate the triggering attacker
```

---

## Integration with Path Datum

The designate ally action is granted alongside the path:

**In `AssignTo()`:**
- Create and grant `/datum/action/cooldown/path_designate_ally` to owner
- Set `linked_path` reference

**In `Remove()`:**
- Call `ClearAllyList(owner)` to clean up allies and notify them
- Remove the action button

---

## Duration Reference (Turns to Seconds)

All buff/debuff durations in the path system use **10 seconds per turn**:

| Turns | Seconds | Typical Use |
|-------|---------|-------------|
| 1 | 10s | Basic ATK buffs/debuffs, passive auras |
| 2 | 20s | Skill buffs/debuffs, Ultimate effects, DEF shred |
| 3 | 30s | Long-duration passives, kill stacking buffs |

---

## Notes
- The existing association `designate_ally` system uses icons from `screen_skills.dmi` which are not available for the path system. The path version uses `actions.dmi` instead.
- No visual ally indicator is implemented yet (the association version uses client-side images over heads). This can be added later.
- The ally list is stored globally rather than on the path datum so it can be queried by any system without needing a path reference.
