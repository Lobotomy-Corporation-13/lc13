# Starskiff System — Technical Design Notes

How starskiffs, space navigation, and explorable destinations work mechanically, based on the existing White Ship and ruin systems.

---

## Starskiffs Are White Ships

Each starskiff is a pilotable shuttle using the same system as the White Ship: a mobile docking port with a console, a navigation computer, and preset destinations. Pilots fly them from Starskiff Haven to POIs and back.

### Per-Starskiff Setup

Each starskiff needs:
1. **A shuttle map** (`_maps/shuttles/starskiff_*.dmm`) — the physical layout of the starskiff interior
2. **A mobile docking port** placed on the map with a unique `id` (e.g., `"starskiff_1"`, `"starskiff_2"`)
3. **A helm console** (`/obj/machinery/computer/shuttle/starskiff`) — destination picker UI
4. **A starskiff map console** — shows the space grid and available paths, lets the Pilot pick a plotted path to travel
5. **Area definitions** (`/area/shuttle/starskiff/`) — for power, lighting

### Fleet Composition

The Luofu starts with multiple starskiffs docked at Starskiff Haven. Each has its own shuttle ID and operates independently. Two types:

**Cargo Starskiff** (primary Pilot vessel)
- Small: ~8x5 tiles
- Helm seat, small cargo hold (enough for crates/ore)
- External airlock for EVA docking at destinations
- Powered by onboard generator (heliobi cell / PACMAN equivalent)

**Trade Starskiff** (for bulk commerce runs)
- Larger: ~12x7 tiles
- Helm seat, large cargo bay, passenger seating
- Used by the Helm-Master or Pilots for delivering finished goods to trade partners

At low pop, 2 cargo starskiffs is enough. At higher pop, 3-4 cargo + 1 trade starskiff.

---

## The Space Grid — 50x50 Navigation Map

Space around the Luofu is represented as a **50x50 tile grid**. This is not a physical Z-level — it's an abstract map used by the Divination Commission and starskiff navigation consoles. The Luofu sits at a fixed position on this grid (e.g., center at 25,25).

### What's On the Grid

- **The Luofu** — fixed home position
- **POIs** — resource sites, faction stations, derelicts, hostile zones, etc. Scattered across the grid, initially hidden
- **Empty space** — most tiles are blank until scanned

POIs are generated when the Luofu enters a new star system. Each POI has a grid coordinate, a type, and a hidden/revealed state.

### Divination Scanning

The Divination Commission uses the Jade Abacus to scan the space grid and reveal hidden POIs:

- **Basic scan** — reveals POIs in a small radius around a chosen grid point. Shows type and danger level.
- **Deep scan** — reveals detailed info on a specific POI (exact resources, enemy composition, trade goods). Requires the POI to already be revealed.
- **Cloudpeer Telescope** — long-range scan, reveals POIs across a wider area but with less detail (type only, no specifics).
- **Three taboos** — rushing scans gives unreliable results (false positives, missing info, wrong danger levels).

Revealed POIs appear on all navigation consoles across the ship — the starskiff map consoles, the Helm-Master's trade console, and the Divination Commission's own displays.

---

## Path System — How Starskiffs Travel

Starskiffs don't just teleport to destinations. They follow **paths** plotted on the space grid, traveling tile by tile.

### Path Creation (Divination Commission)

Diviners use the Jade Abacus Navigator to plot paths on the space grid for starskiffs to follow. Path creation works like this:

1. **Select starting point** — The path always begins at the Luofu's position on the grid.
2. **Place waypoints** — The Diviner clicks grid tiles to place waypoints. A line is drawn from the Luofu to the first waypoint, then from each waypoint to the next, forming a route.
3. **POI waypoints** — If a waypoint is placed directly on top of a revealed POI, that POI becomes a stop on the route. When a starskiff reaches that waypoint during travel, it enters the POI's Z-level (docks there) before continuing.
4. **Close the loop** — Path creation ends when the Diviner places a waypoint back on the Luofu. This completes a round-trip route. A path MUST end at the Luofu — it's always a there-and-back journey.

Paths are saved and named. Multiple paths can exist at once (e.g., "Mining Run Alpha" goes to an asteroid field, "Trade Route Beta" goes to a faction station). Diviners can create, delete, and modify paths.

### Path Travel (Pilots)

Once a path is plotted, Pilots use the starskiff's map console to select a path and begin travel:

1. **Select a path** — The map console shows all available plotted paths. The Pilot picks one.
2. **Tile-by-tile travel** — The starskiff moves along the path one grid tile at a time. Each tile takes a short duration to cross (a few seconds). The starskiff's position is tracked on the space grid and visible on all navigation consoles.
3. **POI arrival** — When the starskiff reaches a waypoint that sits on a POI, travel pauses. The starskiff docks at the POI's Z-level (loaded via the shuttle system). The Pilot and crew can disembark, explore, gather resources, trade, or fight.
4. **Departure** — When done at a POI, the Pilot returns to the starskiff and continues along the path to the next waypoint.
5. **Return home** — The path ends back at the Luofu. The starskiff docks at Starskiff Haven.

### Travel Implications

- **Travel time is real** — crossing the grid takes time. Longer paths = more time away from the ship. This makes Divination's route planning meaningful (efficient paths save time).
- **Multiple starskiffs, multiple paths** — different starskiffs can follow different paths simultaneously. One Pilot runs a mining route while another runs a trade route.
- **Grid visibility** — everyone with a navigation console can see where starskiffs are on the grid in real-time. The Helm-Master can coordinate, the Commissioner can track escorts.
- **No freelancing** — starskiffs can only travel on pre-plotted paths. Pilots can't just fly wherever they want. This gives the Divination Commission a meaningful role as the gatekeepers of navigation. No path = no travel.

---

## POI Z-Levels — Explorable Destinations

When a starskiff reaches a POI waypoint, the POI's Z-level is loaded (if not already) and the starskiff docks there. POIs are small, focused areas — not sprawling Lavaland-scale maps.

### POI Sizes

| POI Type | Size | Description |
|---|---|---|
| **Common** (resource nodes, small ruins, herb patches) | **25x25** | Quick stops. Gather materials and leave. No or minimal hostiles. |
| **Rare** (faction stations, large ruins, hostile zones, dungeons) | **40x40** | Bigger areas with more content, enemies, puzzles, or NPC interaction. Worth spending time in. |

### How POIs Load

POIs use the existing ruin/map template system but at a fixed small size:

1. **Each POI has a premade `.dmm` template** — a 25x25 or 40x40 map file in `_maps/RandomRuins/XianzhouPOIs/`
2. **When a starskiff arrives at a POI waypoint**, the gamemode checks if that POI's Z-level is already loaded
   - If not loaded: reserve a Z-level, load the template, place a stationary docking port for the starskiff
   - If already loaded (another starskiff visited earlier, or returning): just dock at the existing port
3. **Starskiff docks** at the POI's landing zone via the standard shuttle docking system
4. **Players disembark**, explore the 25x25 or 40x40 area, gather resources, fight, trade, etc.
5. **When done**, players re-board the starskiff and the Pilot continues the path

### POI Persistence

- POIs stay loaded as long as the Luofu is in the current star system. If a Pilot visits, leaves, and comes back, the POI is in the same state (resources already gathered are gone, killed enemies stay dead).
- When the Luofu moves to a new star system, all POI Z-levels are cleaned up and freed.
- POIs can optionally be pre-loaded during the Luofu's travel phase to avoid hitches when starskiffs arrive.

### POI Template Examples

**Common (25x25):**
- Ore Deposit — cave with mineable rocks, maybe one passive creature
- Herb Clearing — open area with harvestable plants, soil for seeds
- Salvage Wreck — small derelict hull with lootable crates, minor hazards
- Asteroid Chunk — floating rock with mineral veins, vacuum environment
- Supply Cache — abandoned supply drop, free loot but limited

**Rare (40x40):**
- Mining Colony — pressurized station, NPC merchants, trade terminal, job board
- Abundance Nest — corrupted terrain, multiple hostile mobs, rare material drops
- Faction Outpost — IPC/Belobog/other faction presence, trade deals, contracts, reputation
- Ancient Ruin — puzzle/exploration area, unique lore, artifact loot
- Pirate Hideout — hostile base, combat encounter, stolen goods to reclaim
- Trade Bazaar — neutral zone, multiple NPC vendors, rare goods, social area

### POI Generation Per System

When the Luofu enters a new star system, the gamemode generates POIs for the 50x50 grid:

```
/datum/space_poi
	var/name = "Starsilver Asteroid"
	var/grid_x = 12                   // position on the 50x50 grid
	var/grid_y = 37
	var/poi_size = POI_SMALL          // 25x25 or POI_LARGE for 40x40
	var/map_template                  // which .dmm to load
	var/discovered = FALSE            // hidden until Divination scans
	var/z_level = null                // null until first visited, then stays loaded
	var/danger_level = 1              // 1-5
	var/list/resources                // what can be gathered
	var/list/trade_goods              // what NPCs buy/sell (if applicable)
	var/faction = null                // controlling faction (if applicable)
	var/poi_type = POI_RESOURCE       // POI_RESOURCE, POI_TRADE, POI_HOSTILE, POI_DERELICT, etc.
```

A typical system might generate:
- 8-12 common POIs (25x25) — resource nodes, small ruins, caches
- 3-5 rare POIs (40x40) — faction stations, dungeons, trade hubs
- Spread across the 50x50 grid with some clustering (e.g., asteroid fields have multiple ore POIs near each other)

---

## Starskiff Haven — The Hub

Starskiff Haven is the Luofu's main port area. It contains:

- **Docking bays** — Stationary docking ports where starskiffs park (one per starskiff). The home destination for all starskiff consoles.
- **Cargo processing** — Where Pilots unload materials. Conveyor belts, sorting area, storage crates.
- **Equipment lockers** — EVA gear, tools, weapons for dangerous runs.
- **Guild offices** — Where the Helm-Master manages trade deals.
- **Departure board** — Shows current system destinations with info from Divination (resources, danger level, status).

### Docking Port Layout

Each starskiff bay needs:
- A stationary docking port with `id = "starskiff_haven_1"` (matching `port_destinations` on the starskiff's mobile port)
- Enough clear space for the starskiff's footprint
- Airlocks or blast doors separating the bay from the rest of Haven

---

## Connection to Other Systems

### Divination Integration
- Diviners scan the 50x50 grid → POIs are revealed on all navigation consoles
- Diviners plot paths on the grid → starskiffs can travel those routes
- Better scans reveal more detail (exact resources, danger composition)
- Master Diviner can predict which POIs have the most valuable resources
- **Without Divination, starskiffs cannot travel** — paths must be plotted first

### Trade Integration
- Trade-type POIs (faction stations, bazaars) have NPC merchants with buy/sell prices
- Trade starskiffs carry goods to these POIs
- Contracts reference specific POIs ("Deliver refined jade to the IPC Station at grid 38,12")

### Security Integration
- Cloud Knights can board starskiffs as escorts
- Hostile POIs have combat encounters (Abundance mobs, pirates, wildlife)
- Commissioner can mark paths as restricted if too dangerous
- Cloud Knight positions visible on the grid when traveling

### Artisanship/Alchemy Integration
- Raw materials gathered at POIs feed into crafting
- Some POIs have unique resources that unlock special recipes
- POI variety between systems creates crafting diversity
