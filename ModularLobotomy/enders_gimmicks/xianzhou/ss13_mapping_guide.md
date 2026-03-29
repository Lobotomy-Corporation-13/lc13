# SS13 Mapping Guide — Reference Notes

Compiled from the tgstation wiki mapping guide. The primary modern references are:
- **san7890's A-Z Guide to Mapping**: https://hackmd.io/@tgstation/SyVma0dS5
- **Mapping Reference Collection**: https://hackmd.io/@tgstation/ry4-gbKH5

---

## DMM File Format

Maps are `.dmm` files with two sections:

### 1. Key Definitions (Top of File)
Three-letter codes mapped to stacked object lists:
```
"abc" = (
/obj/structure/table,
/obj/item/wrench,
/turf/open/floor/iron,
/area/station/engineering/main)
```

Each key defines everything on one tile — objects, structures, machines, the floor type (turf), and which room/department it belongs to (area). Multiple objects stack on the same tile.

### 2. Grid Section (Bottom of File)
The actual map layout using those three-letter codes in a grid pattern. Each Z-level is a separate grid block.

---

## The Four Layers

Every tile has up to four layers:
- **area** — which room/department the tile belongs to (defines power, access). Each area should be unique and not reused elsewhere.
- **turf** — the floor or wall type (regular floor, airless floor, reinforced wall, space, etc.)
- **obj** — objects on the tile (machines, structures, items, pipes, cables, decals)
- **mob** — any mobs placed on the tile (spawners, NPCs)

In Dream Maker editor: toggle layer visibility/interactivity via the Layers dropdown. Deselect area + tick "only show selectable layers" to actually see what you're doing.

---

## Per-Room Checklist

Every room/area on a station map needs:

### Mandatory
> **Note:** LC13 has removed atmospheric simulation (PR #198). Air alarms, vent pumps, scrubbers, and pipe networks are not needed. Rooms have static breathable air.

- [ ] **Floor turfs** — simulated floors. Use airless floors for rooms exposed to space.
- [ ] **Walls** — surround the room. Reinforced walls for high-security areas.
- [ ] **Exactly one APC** (Area Power Controller) — provides power to everything in the area. High-draw areas (engineering, cargo) use `/apc/highcap` subtypes.
- [ ] **Lights** — enough to illuminate the room, not so many they drain power fast.
- [ ] **Wiring** — connecting from main power grid to the APC.
- [ ] **Fire alarm + fire doors** — inside the area boundary for lockdown capability.

### Standard
- [ ] Light switch (by the door)
- [ ] Request Console (if the room needs/produces materials)
- [ ] Intercom (set to 145.9, speaker ON, mic OFF — so radio reaches people without headsets)
- [ ] Security cameras (enough to see the area, not bunched together)

### Access/Security
- [ ] Door access set properly via `req_access_txt` (ALL listed accesses required) or `req_one_access_txt` (ANY listed access works)
- [ ] Multiple accesses separated by semicolons with no spaces (e.g., "28;31")
- [ ] Security level matches room importance — public rooms get minimal security, sensitive areas get reinforced walls + electrified grilles
- [ ] Every room should have at least one weak point (back door, window, maintenance access) for gameplay balance
- [ ] Access values defined in `code/__DEFINES/access.dm`

---

## Power (Mapping)

### APC
- One per area. Provides power to everything in the area.
- High-draw areas use `/apc/highcap` for bigger starting power cells.
- `dir` controls which wall the APC is on (1=north, 2=south, 4=east, 8=west).
- `dir` is the ONLY positional variable for APCs (pixel_x/pixel_y are ignored in-game).

### Wiring
- Wires must connect from main power grid to each APC.
- Wires under grilles make them electrified (if connected to powered grid).
- Don't run cables through walls if avoidable — makes repair/sabotage difficult.

---

## Shuttles (Mapping)

Three dock types:
- **stationary** — places where the shuttle can dock (e.g., station dock, CentCom dock)
- **transit** — the shuttle's position while moving
- **mobile** — the actual shuttle's home position

### Dock Configuration
Docks are grouped by `id` (e.g., `id = "cargo_away"`, `id = "cargo_transit"`).

Each dock needs at minimum:
- `height`, `width` — bounding box dimensions
- `dheight`, `dwidth` — offset of the docking port object from the (0,0) corner of the bounding box

**Important:** The mobile dock's bounding box must fit inside the stationary dock's bounding box (after any rotation), or the shuttle refuses to move.

### Bounding Box Offset
- dwidth/dheight is the offset of the docking_port obj from the (0,0) bounding box corner
- The (0,0) corner position changes based on `dir`:
  - dir=1 (north): bottom-left corner
  - dir=2 (south): upper-right corner
  - (Rotate the mental model for east/west)
- **Width/height count from 0** — a value of 9 means 10 tiles (tile 0 through tile 9)

### Shuttle Area
If the mobile docking port is in a `/area/shuttle` subtype, only turfs in that area within the bounding box are moved. This allows odd-shaped shuttles.

### Direction and Rotation
- If mobile port `dir` differs from stationary port `dir`, the shuttle and all contents are rotated accordingly.
- `traveldir` defines rotation during transit (angle in degrees, e.g., 270 = moving right to left).

---

## Object Placement Tips

- Use the object tree (left panel) to find items. Right-click something on the map to see its path.
- Click = place one item per category per tile.
- Ctrl+click = stack on top of existing items.
- Shift+click = delete topmost item.
- `pixel_x` and `pixel_y` shift an object's visual position (wall-mounted machines appear on walls but are actually on the tile in front).
- **Never change** `nudge_x`, `nudge_y`, or z-axis variables — they're unused in SS13 and break things.
- **Never change** `step_x` or `step_y` — breaks movement animations. If they sneak in, remove them via text editor find-and-replace.
- Watch out for auto-generated `tag` values when using "generate instance from state/direction" — these must be cleared (set to empty `""`) or they cause runtime errors.

---

## General Mapping Rules

- Don't run pipes/cables/disposals through walls if avoidable (hard to repair/sabotage under r-walls).
- Connect departments to maintenance via back/side doors (escape routes + antag entry points).
- Balance room security with contents — harder to enter = more valuable stuff inside. Don't make empty high-security rooms.
- Check for indestructible turfs (`/turf/indestructible/...`) — these don't belong on regular station maps.
- Avoid too much empty space — shrink the room and fill extra space with maintenance tunnels.
- Don't place items below tables.

---

## Multi-Z Mapping

Multiple Z-levels stacked as floors of the same station (used on Tramstation, IceboxStation).

- Map configuration JSON (`_maps/`) defines how Z-levels link together via traits.
- Each Z-level must have a `baseturf` defined in the config.
- Rooms on lower Z-levels MUST have a floor turf mapped on the Z-level above them.
- Empty Z-levels (no areas or turfs) will runtime — at minimum, define some area/turf.
- SS13 caches map config in `data/next_map.json` — clear this after changing config locally.

---

## Pre-Commit Checklist

Before finalizing a map (adjusted for LC13 — no atmos):
- [ ] Floors with/without air as appropriate
- [ ] Every area has an APC
- [ ] Every area has a Request Console (if needed)
- [ ] Lights present and sufficient
- [ ] Light switches present
- [ ] Intercoms present
- [ ] Security cameras with good coverage
- [ ] Wiring correct
- [ ] Fire alarms and fire doors present
- [ ] Pod doors functional
- [ ] Door access set correctly
- [ ] Items placed properly (not under tables)
- [ ] Disposal system works from all disposal units
- [ ] No misplaced/stacked disposal pipes
- [ ] No misplaced/stacked wires
- [ ] Security level balanced (weak points exist for gameplay)
- [ ] No excessive empty space
- [ ] No indestructible turfs where they shouldn't be

---

## Map Merger

**Always use Map Merger tools before committing map changes.** See the Map Merger guide for details. This prevents merge conflicts in the large `.dmm` files.

---

## Files Needed for a New Map

- The `.dmm` map file(s)
- A JSON configuration file under `_maps/`
- Entry in the maps config file
- For shuttles: separate `.dmm` shuttle files under `_maps/shuttles/`
