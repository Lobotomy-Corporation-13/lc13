# Divination Commission — Expanded Design

The Divination Commission is the SS13 Science/R&D department. They don't produce physical goods — they produce **information and research** that makes everything else possible. Without Divination, the crew can't navigate, can't unlock advanced recipes, and can't see what's out there. The Master Diviner is the Research Director.

---

## SS13 Foundation — What We're Pulling From

### From Science R&D
- **Tech web / research points** → **Sapientia Academe schematic system**. Passive point generation spent on unlocking technology nodes that benefit every department.
- **R&D Console** → **Jade Abacus Workstations**. The interface for spending points and managing research.
- **Experiments** → **Divination experiments**. Hands-on tasks that unlock or discount schematic nodes. Material scanning, artifact analysis, calibration.
- **Machine part tiers** (1-4) → Divination researches which tiers are unlockable; Artisanship builds and installs them.
- **Printing parts for other departments** → Divination doesn't print, but their research unlocks what Artisanship can print. Same gatekeeper role.
- **Destructive Analyzer** → **Artifact Analyzer**. Scan unknown items/materials to unlock unique schematics.

### From Science (Exploration/Scanning)
- **Xenobiology / specimen study** → **POI scanning and analysis**. Studying what's out in space.
- **Ordnance experiments** → **Divination calibration**. Hands-on experiments that produce research data for publication/unlocks.
- **Research papers / publishing** → **Divination reports**. Completed experiments are recorded and "published" to unlock or discount nodes.

### Unique to Divination (No SS13 Equivalent)
- **Space grid scanning** — revealing hidden POIs on the 50x50 navigation map. This is Divination's primary round-to-round activity and has no direct SS13 parallel.
- **Path plotting** — drawing starskiff routes on the space grid. Navigation gameplay unique to this gamemode.
- **Market prediction** — forecasting trade demand at destinations. Information that directly impacts profitability.
- **Threat intelligence** — predicting incoming events (Abundance attacks, pirate raids, mara outbreaks). Early warning system for the whole crew.

---

## The Sapientia Academe (Tech Web System)

The Sapientia Academe is the Divination Commission's research facility, equivalent to the R&D lab. This is where schematics are researched and unlocked for all departments.

### How It Works (Like the Tech Web)

**Schematic Points** generate passively over time (like SS13 research points). Diviners spend them at the Academe Console to unlock technology nodes on a schematic tree.

**Core Loop:**
1. Points accumulate passively
2. Diviner opens the Academe Console (jade abacus workstation linked to the Academe)
3. Browse available schematic nodes — see cost, prerequisites, what it unlocks
4. Click "Research" to spend points and unlock a node
5. Unlocked schematics become available on linked machines across the ship (Artisan's Forge, Elixir Crucible, Schematic Press, etc.)
6. Notification goes to relevant departments ("New metallurgy schematic available")

**Tree Structure:**
- Nodes have prerequisites (must unlock Tier 1 before Tier 2)
- Some nodes require experiments to unlock or receive cost discounts
- Different branches serve different departments
- Points are limited — Divination must prioritize based on crew needs

### Schematic Branches

| Branch | What It Unlocks | Who Benefits |
|---|---|---|
| **Industrial Refinement** | Tier 2 components, RPED equivalent, basic upgrades | All (first priority, like SS13's Industrial Engineering) |
| **Metallurgy** | Advanced alloy recipes, material processing, masterwork crafting | Artisanship (higher-value trade goods) |
| **Elixir Science** | Advanced crucible recipes, purity improvements, new medicines | Alchemy (better medicines, higher trade value) |
| **Armament** | Weapons, armor, Cloud Knight equipment, combat aurumatons | Realm-Keeping (better combat gear) |
| **Navigation** | Starskiff upgrade parts, cargo expansion, navigation tools | Sky-Faring (faster travel, more cargo) |
| **Heliobi Studies** | Furnace optimization, power cell upgrades, heliobi tools | Artisanship (more power, better efficiency) |
| **Shipwright** | Hull reinforcement, structural upgrades, new room blueprints | All (ship durability, expansion) |
| **Jade Engineering** | Jade abacus upgrades, scan improvements, divination tools | Divination itself (better scans, longer range) |

### Priority Research Path (Like SS13 Scientist Workflow)

Typical round-start priority order:
1. **Industrial Refinement** (first — unlocks Tier 2 components and the Rapid Artifice Device for Artisanship)
2. **Jade Engineering** (self-upgrade — better scanning tools means better intel for everyone)
3. **Department requests** — Furnace Master wants Metallurgy, Cauldron Master wants Elixir Science, Commissioner wants Armament. Master Diviner decides based on crew composition and trade contracts.
4. **Advanced tiers** — Tier 3/4 components, masterwork recipes, specialized tech

This mirrors SS13's scientist workflow: Industrial Engineering first, then Mining Tech, then department-specific requests.

### Component Tiers (Researched Here, Built by Artisanship)

| Tier | Xianzhou Name | Schematic Branch Required |
|---|---|---|
| 1 | Standard Components | Roundstart (no research needed) |
| 2 | Refined Components | Industrial Refinement |
| 3 | Superior Components | Branch-specific advanced research + rare materials |
| 4 | Masterwork Components | Branch-specific deep research + very rare materials |

When Divination unlocks a tier, the schematic becomes available at Artisanship's Forge. Artisanship prints the components and installs them. Divination never touches a wrench — they just unlock the knowledge.

---

## Experiments (Hands-On Research Tasks)

Like SS13 experiments that unlock or discount tech nodes. Experiments require Diviners to actually do something beyond clicking "Research" — they involve materials, scanning, and analysis.

### Experiment Types

**Material Scanning Experiment** (Like Low Grade Material Scanning)
- **Purpose:** Discounts Industrial Refinement by a large amount
- **Procedure:** Grab an Experi-Scanner equivalent (Jade Analysis Rod). Walk around the ship and scan listed objects/materials. Complete all scans to finish.
- **When:** Round start — this is the first thing a Diviner should do, same as SS13 scientists doing Low Grade Material Scanning to discount Industrial Engineering.

**Artifact Analysis** (Like Destructive Analyzer)
- **Purpose:** Unlocks unique schematics not on the standard tree
- **Procedure:** Pilots bring back unknown artifacts, salvaged tech, or alien samples from POIs. Place on the Artifact Analyzer in the Academe. Scan destroys the item but unlocks a unique recipe or provides a large point discount.
- **When:** Whenever Pilots return from exploration runs with unusual finds.

**Alloy Calibration** (Like Ordnance Experiments)
- **Purpose:** Unlocks or discounts Metallurgy nodes
- **Procedure:** Work with Artisanship — request specific alloy test smelts at the forge. Scan the results with analysis tools. Record data and publish a divination report.
- **When:** Mid-round, when Metallurgy research is needed.

**Elixir Analysis** (Cross-Department with Alchemy)
- **Purpose:** Unlocks or discounts Elixir Science nodes
- **Procedure:** Analyze sample elixirs from the Alchemy Commission. Scan chemical composition, purity levels, reaction byproducts. Record data and publish.
- **When:** When Alchemy needs advanced recipes unlocked.

**Furnace Readings** (Cross-Department with Artisanship)
- **Purpose:** Unlocks or discounts Heliobi Studies nodes
- **Procedure:** Take readings from the Creation Furnace during operation. Scan energy output patterns, heliobi resonance frequencies. Requires the Furnace to be running (and ideally at high output for better data).
- **When:** When power optimization research is needed.

**POI Data Compilation**
- **Purpose:** Discounts multiple branches based on what was found
- **Procedure:** After scanning POIs and receiving intel, compile a comprehensive system report at the Academe Console. More POIs scanned = bigger discount.
- **When:** After a thorough scanning session of the current star system.

### Publishing Divination Reports (Like Research Papers)

Completed experiments produce data that must be "published" to apply their unlock/discount:
1. Complete experiment (scanning, analysis, etc.)
2. Data is saved to a Jade Data Disk
3. Insert disk into Academe Console
4. Select completed experiment data
5. Publish report — applies discount or unlocks the associated node

This mirrors SS13's NTFrontier paper publishing workflow from ordnance experiments.

---

## Space Grid Scanning (Primary Divination Activity)

This is the Divination Commission's unique gameplay that has no direct SS13 equivalent. It's what Diviners spend most of their active time doing.

### The 50x50 Grid

The space around the Luofu is a 50x50 abstract grid. The Luofu sits at the center. POIs are scattered across the grid, hidden until scanned. The grid is displayed on Jade Abacus Workstations, the Cloudpeer Telescope, and navigation consoles across the ship.

### Scanning Tools

**Jade Abacus Workstation** (Standard Scanner — like R&D Console)
- The Diviner's everyday tool
- **Basic Scan:** Select a grid tile or small area. After a processing delay, reveals any POIs within a small radius (3-5 tiles). Shows POI type and danger level.
- **Deep Scan:** Target an already-revealed POI. After a longer delay, reveals detailed info: exact resources, enemy types and numbers, trade goods available, faction presence.
- Multiple workstations can operate simultaneously — more Diviners = faster coverage
- Upgraded by Jade Engineering research (longer range, faster processing, wider radius)

**Matrix of Prescience Ultima** (Master Diviner's Tool — like the R&D Server)
- Only the Master Diviner has full access
- **Predictive Scan:** Can forecast events — incoming threats, market shifts at known trade partners, rare resource spawns. Returns probabilistic results ("70% chance of pirate activity in sector 15-20 within the next 30 minutes").
- **Interrogation Mode:** Can scan individuals aboard the Luofu for mara markers, hidden contraband, or false identity (used in conjunction with the Commissioner for investigations).
- **Override Scan:** Can force-reveal a specific grid tile regardless of distance, but with a long cooldown and high point cost.

**Cloudpeer Telescope** (Long-Range Scanner — like Long-Range Sensors)
- Scans a very large area (10-15 tile radius) but only reveals basic info (POI exists: yes/no, and rough type category)
- Good for initial sweeps of a new system — find where the POIs are, then use workstations for detail
- Very long processing time
- Only one exists on the ship

### Three Taboos Mechanic

The three taboos are Divination's quality control system. They prevent Diviners from spamming scans for instant perfect information.

**No Insincere Divination (Don't Rush)**
- Each scan has a minimum processing time. Starting a new scan before the previous one fully resolves gives degraded results on both.
- Rushing produces: false positives (POIs that don't exist), missing data (POIs that DO exist but aren't shown), wrong danger levels.
- Patient scanning = reliable intel. Impatient scanning = bad intel that wastes everyone's time.

**No Unjust Divination (Don't Spam)**
- Scanning the same area repeatedly in a short time gives diminishing returns. The first scan of an area is 100% reliable. The second scan within a few minutes adds little. The third adds nothing.
- Encourages spreading scans across the grid rather than obsessively re-scanning one area.

**No Unpracticed Divination (Skill Matters)**
- The Master Diviner's scans are always reliable at their base level.
- Standard Diviners have a small chance of errors on deep scans (wrong resource counts, missed enemies). This chance decreases as they scan more throughout the round (practice makes perfect, tracked per-player).
- Flex workers (non-Divination crew using basic scanning) have a much higher error rate — they can reveal POIs exist but details are frequently wrong.

### Scanning Gameplay Loop

1. **System arrival** — Luofu enters new star system. Grid is blank.
2. **Telescope sweep** — Use Cloudpeer Telescope to do a wide initial scan. Takes time but reveals rough POI locations across a large area.
3. **Targeted basic scans** — Diviners pick up the Telescope results and do focused basic scans on promising areas. Reveals POI types and danger levels.
4. **Prioritize and report** — Share findings with Helm-Master. "There's a mining colony at 12,37 — safe. Hostile zone at 40,15 — dangerous but rich resources. Faction station at 8,22 — IPC, good for trade."
5. **Deep scans** — On priority targets, run deep scans for full detail before sending Pilots.
6. **Ongoing monitoring** — Continue scanning unexplored areas while Pilots are out. The grid is large — there's always more to find.
7. **Predictions** — Master Diviner uses Matrix of Prescience to forecast events and market shifts. Shares with command staff.

---

## Path Plotting (Navigation Service)

The Divination Commission plots starskiff routes on the space grid. This is their second major service after scanning.

### How It Works

(Detailed in starskiff_technical.md — summary here)

1. Diviner opens the path plotting interface on a Jade Abacus Workstation
2. Path starts at the Luofu's grid position
3. Click grid tiles to place waypoints — lines connect them showing the route
4. Placing a waypoint on a revealed POI makes it a stop (starskiff docks there on arrival)
5. Path must end back at the Luofu (round trip)
6. Save and name the path
7. Path appears on all starskiff map consoles for Pilots to select

### Path Quality

Divination's path plotting isn't just about drawing lines — efficient paths matter:
- **Shorter paths** = less travel time = Pilots spend more time gathering and less time flying
- **Multi-stop paths** = a single trip that hits multiple POIs = more efficient than separate trips
- **Hazard avoidance** = scanning reveals not just POIs but also dangers in empty space (asteroid fields, radiation zones). Good paths route around these.
- **Path optimization** is a skill — the best Diviners create routes that maximize value per time spent

### Who Plots Paths

- **Master Diviner** — can create, modify, and delete any path. Has final authority on route approval.
- **Diviner** — can create and modify paths. Paths may need Master Diviner approval at higher security levels.
- **Helm-Master** — can view all paths and request specific routes but cannot create them. Must coordinate with Divination.
- **Pilots** — can only select and follow existing paths on their starskiff console. Cannot create paths.

This means Pilots are dependent on Divination to have routes ready. If Divination is slow or absent, Pilots can't fly. This is intentional — it mirrors the dependency SS13 has between Science and other departments.

---

## Divination Commission Hall (Department Layout)

The physical workspace, equivalent to the Science department.

### Rooms and Equipment

**Main Hall — Jade Abacus Lab** (like the R&D Lab)
- 3-4 Jade Abacus Workstations (the primary scanning/research consoles)
- Space grid display (large screen showing the 50x50 grid, visible to anyone entering)
- Path plotting interface
- Printer for physical intel reports (paper for the Helm-Master, Commissioner, etc.)

**Matrix of Prescience Chamber** (like the RD's Office)
- The Matrix of Prescience Ultima — Master Diviner's exclusive tool
- Restricted access (Master Diviner only, or with their authorization)
- Predictive scanning, interrogation mode, override scans
- Academe Console for managing schematic research (can also be done from workstations, but the Master Diviner's console has priority controls)

**Cloudpeer Telescope Observatory** (unique to Divination)
- The long-range scanner
- Requires a clear view (top of ship or external-facing dome)
- Single-use at a time — only one Diviner can operate it

**Sapientia Academe** (like the R&D Server Room)
- The schematic database — physically a jade crystal array
- Academe Consoles for spending schematic points and browsing the tech tree
- Artifact Analyzer for studying items brought back from POIs
- Experiment recording station (Jade Data Disks, report publishing)

**Archive / Library** (like the Library/Records)
- Stores past divination reports, system maps, trade histories
- Qingque's domain (lore reference)
- Contains reference materials that can give hints about star systems (flavor, not mechanical advantage)

---

## Cross-Department Services

Divination is the information hub. Every department depends on them.

### To Sky-Faring (Helm-Master + Pilots)
- **POI intel** — what's out there, what resources are available, how dangerous is it
- **Path plotting** — starskiff routes. No paths = no travel.
- **Trade forecasting** — which destinations have the best buy/sell prices right now
- **Demand prediction** — what goods will be in demand at the next system (Matrix of Prescience)

### To Artisanship (Furnace Master + Craftsmen)
- **Schematic research** — unlocks crafting recipes, component tiers, machine blueprints
- **Material analysis** — scanning new materials from POIs to unlock material-specific recipes
- **Furnace data** — Heliobi Studies research for power optimization

### To Alchemy (Cauldron Master + Alchemists)
- **Elixir Science research** — unlocks advanced medicine recipes, purity improvements
- **Ingredient identification** — scanning unknown herbs/samples from POIs to determine properties
- **Mara forecasting** — predictions about mara risk levels for the crew (Matrix of Prescience)

### To Realm-Keeping (Commissioner + Cloud Knights)
- **Threat intelligence** — enemy composition at hostile POIs, incoming attack predictions
- **Armament research** — unlocks weapon and armor schematics for Cloud Knight equipment
- **Investigation support** — Matrix interrogation mode for criminal investigations, mara screening
- **Escort priority** — flagging which paths are dangerous enough to need Cloud Knight escorts

### To Command (Arbiter-General)
- **Strategic overview** — full picture of the current system, trade opportunities, threats
- **Decision support** — the Master Diviner traditionally reviews every major decision (Luofu lore)
- **Event forecasting** — advance warning of major events (Abundance attacks, Stellaron activity)

### From Other Departments
- **From Pilots** — artifacts, unknown materials, and samples for analysis (experiment fuel)
- **From Artisanship** — machine upgrades for Divination equipment (Jade Engineering components)
- **From Alchemy** — mara data, crew health patterns for predictive analysis
- **From All** — research priority requests ("We need Armament Tier 2 before the next hostile POI run")

---

## Master Diviner vs. Diviner — Role Split

### Master Diviner (Head — Research Director)
- **Research direction** — decides which schematic branches to prioritize, manages point spending
- **Matrix of Prescience** — exclusive access to predictive scans, interrogation, override scans
- **Strategic advising** — reviews major decisions with the Arbiter-General, provides intelligence briefings
- **Experiment oversight** — approves and supervises major experiments (artifact analysis, cross-department research)
- **Path approval** — final authority on starskiff routes (can restrict or approve paths)
- **Quality control** — their scans are always reliable (no three taboos error chance)

### Diviner (Worker — Scientist)
- **Grid scanning** — the bulk of the work. Basic scans and deep scans to map the system.
- **Path plotting** — draws starskiff routes based on scan results and Helm-Master requests
- **Experiment work** — material scanning, alloy calibration assistance, elixir analysis, data compilation
- **Academe operation** — spending schematic points on approved research nodes
- **Equipment maintenance** — keeps jade abacus workstations and the Cloudpeer Telescope running
- **Intel distribution** — writes up scan results and delivers to relevant departments

At low pop, the Master Diviner does everything — scanning, research, plotting, advising. At higher pop, Diviners handle the volume scanning and routine research while the Master Diviner focuses on predictions, strategic decisions, and the Matrix of Prescience.

---

## Round Start Workflow (Like SS13 Scientist)

1. **Material scanning experiment** — grab the Jade Analysis Rod, walk the ship, scan listed objects. This discounts Industrial Refinement (first priority research). Same as SS13 scientists doing Low Grade Material Scanning at round start.
2. **Spend initial schematic points** — unlock Industrial Refinement first (Tier 2 components + Rapid Artifice Device for Artisanship). This is the single most impactful early research.
3. **Telescope sweep** — fire up the Cloudpeer Telescope for a wide initial scan of the new star system. This takes time but reveals rough POI locations.
4. **Targeted scans** — while the Telescope runs, use workstations to do focused scans on areas near the Luofu. Reveal nearby POIs for Pilots to visit first.
5. **First path** — once a few POIs are revealed, plot the first starskiff path (usually a short mining run to a nearby safe resource node). Get Pilots flying as soon as possible.
6. **Take research requests** — check with department heads. Furnace Master needs Metallurgy? Cauldron Master needs Elixir Science? Commissioner needs Armament? Queue up the next research priorities.
7. **Continue scanning** — keep mapping the grid throughout the round. More POIs revealed = more options for the crew = more profitable routes.
8. **Second research wave** — spend accumulated points on the next priority branch. Start Jade Engineering to upgrade your own scanning capability.
