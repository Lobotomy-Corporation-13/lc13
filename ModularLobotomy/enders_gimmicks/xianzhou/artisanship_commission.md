# Artisanship Commission — Expanded Design

The Artisanship Commission is the SS13 Engineering department: construction, power, hull repair, and manufacturing. Craftsmen keep the ship running AND produce trade goods. The Furnace Master is the Chief Engineer. Research and schematics come from the **Divination Commission** (the Science/R&D department) — Artisanship builds what Divination unlocks.

---

## SS13 Foundation — What We're Pulling From

### From Engineering
- **Construction/deconstruction system** — building and repairing walls, floors, windows, doors, airlocks using tools and materials. Same tool progression (wrench, weld, screwdriver, crowbar, wirecutters).
- **Supermatter engine** → **Creation Furnace**. Exotic power source that must be maintained or it delaminates. Core engineering gameplay loop.
- **Wiring and electrical** — cable laying, power distribution, SMES management, APCs. Keeping the ship powered.
- **Hull repair** — patching breaches, replacing damaged walls/floors, emergency sealing.
- **Machine frame construction** — 5 metal → frame → cable → wrench → board → components → screwdriver. Universal machine building sequence.

> **Note:** LC13 has removed atmospheric simulation (PR #198). Pipes, scrubbers, vents, air alarms, and gas mixing do not function. Rooms have static breathable air. The Artisanship Commission does not handle atmospherics.

### From Science R&D (Research Lives in Divination, Manufacturing Lives Here)
The tech web / research point system belongs to the **Divination Commission** — they are the R&D department. Artisanship is the consumer of that research, not the producer. What Artisanship keeps from the Science side:
- **Machine part tiers** (1-4) → **Component quality tiers**. Better parts = better machines = better output. Divination unlocks higher tiers via research; Artisanship manufactures and installs them.
- **RPED (Rapid Part Exchange Device)** → tool for upgrading machines across the ship. Built and used by Artisanship.
- **Protolathe / autolathe** → **Forges and workbenches**. Print/craft items from raw materials. Advanced recipes gated behind Divination research.
- **Ore Redemption Machine** → **Smelter**. Converts raw ore into usable material sheets.

### From Both
- **Machine upgrades** — open machine, swap parts for higher tier, close machine. Universal upgrade loop that benefits every department. Divination unlocks the component tiers, Artisanship manufactures them and installs them ship-wide.

---

## The Creation Furnace (Power Source)

The Creation Furnace is the Luofu's main power source, equivalent to the Supermatter engine. It's powered by an imprisoned heliobus — a fire spirit that generates enormous energy but is dangerous if uncontained.

### How It Works (Like the Supermatter)

The Furnace is a contained heliobus that radiates energy. That energy is captured and converted to electrical power for the ship. The Furnace must be kept within safe operating parameters or it destabilizes.

**Core Loop:**
1. The Furnace generates heat and energy constantly
2. Containment field and coolant cells keep it from overheating
3. Energy collectors around the Furnace capture output and feed it to the power grid
4. The Furnace Master monitors temperature, stability, and output via the Furnace Control Console
5. If containment degrades or the Furnace is disturbed, it begins to destabilize — escalating warnings, increasing radiation, and eventually a breach (heliobi escape + explosion)

**What Can Go Wrong:**
- Coolant cell depletion (they wear out over time) → Furnace overheats
- Containment damage (from combat, accidents, sabotage) → stability drops
- Power drain (too many machines running) → grid brownouts, Furnace strains
- Heliobus agitation (certain events, Abundance interference) → instability spikes
- Full delamination → the heliobus escapes, hostile mobs spawn, power goes out, hull damage

**Furnace Master's Job:**
- Set up the Furnace at round start (insert coolant cells, calibrate containment field, start energy collectors)
- Monitor throughout the round via the Furnace Control Console
- Replace depleted coolant cells before they run out (the main recurring maintenance task)
- Respond to emergencies (emergency containment boost, manual stability override)
- Optimize output — higher output = more power for the ship but faster coolant depletion and narrower safety margin
- The balance between safe low output and risky high output mirrors the SM gameplay

### Furnace Room Layout
- Central Furnace chamber (reinforced, radiation-shielded)
- Containment field generators around the chamber
- Energy collector array
- Furnace Control Console (temperature, stability, output, coolant status)
- Emergency containment controls
- Coolant cell storage and charging station

---

## Power Grid (Electrical Systems)

Same as SS13 wiring and power distribution.

### What Carries Over Directly
- **Cable laying** — crowbar floor tile, lay cable on plating, cables auto-connect in cardinal directions.
- **SMES units** — store power, set input/output levels. Buffer between generation and consumption.
- **APCs (Area Power Controllers)** — one per room, manages local power (lights, equipment, environment).
- **Power monitoring console** — shows all APCs, total generation, total consumption, grid health.
- **PACMAN generators** — portable backup generators. Fuel with plasma (or equivalent fuel).
- **Solar panels** — secondary power source on the ship's exterior. Lower output than the Furnace but reliable.
- **Wire layers** — three layers for separate circuits if needed.

### Xianzhou Additions
- **Heliobi power cells** — rechargeable cells used in portable equipment and starskiffs. Charged at cell chargers connected to the main grid. Equivalent to standard power cells but themed.
- The Furnace is the primary generation source (replaces the SM). Solars and PACMANs are backups.
- If the Furnace goes down, the ship runs on stored SMES power and backup generators — a ticking clock for the Furnace Master to fix it.

---

## Construction and Hull Repair

Same as SS13 construction/deconstruction. The tool progression and material requirements carry over directly.

### What Carries Over Directly
- **Wall construction** — metal sheets → girders → finish with more metal (or plasteel for reinforced).
- **Floor construction** — rods → lattice → floor tile → plating → finished floor.
- **Window construction** — glass sheets → place → secure with tools.
- **Airlock construction** — metal → frame → wrench → cable → electronics → screwdriver.
- **Grille construction** — rods → place.
- **Deconstruction** — reverse tool progression for each structure type.
- **Hull breach repair** — weld damaged plating, replace destroyed sections with new materials.
- **RCD (Rapid Construction Device)** — emergency tool for fast patching. Limited charges.

### Xianzhou Flavor
- Materials are renamed but function identically: metal → starsilver, plasteel → reinforced starsilver, glass → jade glass, etc. The crafting recipes and tool steps don't change.
- Hull breaches during travel events (pirate raids, asteroid impacts) are the main demand for construction skills — same emergency repair gameplay as SS13.
- Craftsmen may also build new rooms or expand existing areas as ship upgrades (purchased with trade profits, built with materials).

---

## Smelting (Ore Processing)

Equivalent to the Ore Redemption Machine (ORM) and the material processing pipeline.

### What Carries Over Directly
- **Raw ore → refined material sheets.** Miners (Pilots) bring back ore, it goes into the smelter, material sheets come out.
- **Material types** map to Xianzhou equivalents:

| SS13 Material | Xianzhou Equivalent | Source | Use |
|---|---|---|---|
| Iron/Metal | Starsilver | Asteroid mining, rocky planets | General construction, basic crafting |
| Plasma | Refined Plasma | Gas collection, mineral deposits | Fuel, advanced alloys, power generation |
| Glass | Jade Glass | Sand processing, jade deposits | Windows, optics, jade abacus parts |
| Plasteel | Hardened Starsilver | Alloy (starsilver + plasma) | Reinforced construction, armor |
| Silver | Silver | Mining | Decorative goods, trade items |
| Gold | Gold | Mining | Luxury goods, electronics, trade items |
| Titanium | Titanium | Mining, salvage | Starskiff parts, heavy construction |
| Diamond | Diamond | Rare mining | Premium trade goods, masterwork items |
| Uranium | Heliobi Crystal | Rare mining, Furnace byproduct | Power cells, advanced equipment |

- **Ore Silo** equivalent — a central material storage that feeds into all crafting machines. Materials deposited by Pilots at cargo processing flow into the silo, available to all Artisanship machines.
- **Biogenerator** equivalent — processes organic materials from the Kangqu biodomes into leather, cloth, and other crafting components.

---

## Receiving Research from Divination

Artisanship does NOT do its own R&D. The **Divination Commission** is the Science/R&D department — they operate the Sapientia Academe, spend schematic points on the tech web, and perform experiments. When Divination unlocks a new schematic node, the recipes and blueprints become available on Artisanship's machines (Forge, Schematic Press, etc.).

### What Artisanship Needs from Divination

| Divination Research Branch | What It Unlocks for Artisanship |
|---|---|
| **Metallurgy** | Better alloy recipes, advanced material processing, masterwork crafting |
| **Heliobi Studies** | Furnace optimization, power cell upgrades, heliobi tools |
| **Shipwright** | Hull reinforcement schematics, structural upgrades, new room blueprints |
| **Armament** | Weapon and armor blueprints (built by Artisanship for Cloud Knights) |
| **Navigation** | Starskiff upgrade parts, cargo expansion blueprints |

### Component Tiers (Researched by Divination, Built by Artisanship)

| Tier | Xianzhou Name | Unlock | Built At |
|---|---|---|---|
| 1 | Standard Components | Roundstart | Workbench |
| 2 | Refined Components | Basic Divination research | Artisan's Forge |
| 3 | Superior Components | Advanced research + rare materials | Artisan's Forge |
| 4 | Masterwork Components | Deep research + very rare materials | Artisan's Forge (Furnace Master only) |

The dependency flow: **Divination researches → Artisanship manufactures → all departments benefit.** This mirrors SS13 where Science unlocks tech and Engineering/other departments use it, but here the "Science" is the Divination Commission.

### Artisanship Can Request Priorities
The Furnace Master can request that Divination prioritize certain branches — e.g., "We need Metallurgy Tier 2 before we can fill these trade contracts" or "Research Heliobi Studies so I can optimize the Furnace." This creates meaningful inter-department communication, same as SS13 engineers asking scientists to research power tech.

---

## Crafting System (Manufacturing)

The core production loop. Raw materials go in, trade goods and equipment come out.

### Machines (Mapped from SS13)

| SS13 Machine | Xianzhou Equivalent | Function |
|---|---|---|
| Autolathe | **Workbench** | Basic items — tools, parts, simple goods. Available to anyone. |
| Protolathe | **Artisan's Forge** | Advanced items — gated behind Academe research. Artisanship access. |
| Circuit Imprinter | **Schematic Press** | Prints circuit boards / control modules for machines. |
| Exosuit Fabricator | **Aurumaton Foundry** | Builds aurumatons (robotic helpers) and heavy equipment. |
| ORM / Smelter | **Smelting Furnace** | Converts raw ore into material sheets. |
| Ore Silo | **Material Vault** | Central storage feeding all crafting machines. |
| Biogenerator | **Loom** | Converts organic matter into leather, cloth, thread. |

### Machine Construction (Same as SS13)
Building any new machine follows the universal sequence:
1. Build **Machine Frame** from 5 starsilver sheets
2. Add 5 cable coils (wiring)
3. Wrench to secure
4. Insert the appropriate circuit board
5. Examine frame to see required components
6. Add components (servos, matter bins, capacitors, lasers as needed)
7. Screwdriver to finalize

Deconstruction is the same sequence in reverse. This is unchanged from SS13.

### Recipe Tiers

| Tier | Who Can Craft | Recipe Source | Quality | Trade Value |
|---|---|---|---|---|
| **Basic** | Anyone at a Workbench | Available by default | Standard | Low |
| **Standard** | Craftsman at Artisan's Forge | Unlocked via Academe research | Good | Medium |
| **Advanced** | Craftsman with rare materials | Requires deep research + special materials | High | High |
| **Masterwork** | Furnace Master only | Requires Tier 4 components + rarest materials | Exceptional | Very High |

### Trade Good Categories

Each category corresponds to a trade guild:

| Category | Example Products | Guild | Materials Needed |
|---|---|---|---|
| **Refined Metals** | Starsilver ingots, alloy bars, structural beams | Aquaglider | Ore from mining POIs |
| **Weapons & Armor** | Swords, crossbows, Cloud Knight plate, shields | Securocrat | Metals, rare alloys, components |
| **Machinery & Parts** | Machine components, starskiff parts, tools | Plainfeather | Metals, glass, components |
| **Jade Crafts** | Jade carvings, abacus parts, ornamental pieces | Celestial | Jade, gold, silver |
| **Luxury Goods** | Porcelain, jewelry, art pieces, ornate furniture | Celestial | Rare materials, gold, jade |
| **Industrial Goods** | Pipes, cables, structural materials, bulk parts | Aquaglider | Common metals, glass |
| **Aurumatons** | Aurumaton workers, helpers, patrol units | Whistling Flames | Metals, components, heliobi crystals |

### Crafting Gameplay Loop
1. Check the Commission Requests Board / trade contracts for what's in demand
2. Check the Material Vault for available resources
3. If materials are low, request Pilots gather specific resources
4. Select recipe at Workbench (basic) or Artisan's Forge (advanced)
5. Insert required materials
6. Wait for crafting to complete (higher tier = longer)
7. Collect finished product
8. Deliver to Sky-Faring for export OR install on the ship

---

## Machine Upgrades (Ship-Wide Service)

One of Artisanship's most important cross-department duties. Same system as SS13.

### How It Works
1. Divination Commission researches higher-tier component schematics at the Sapientia Academe
2. Artisanship prints the unlocked components at the Artisan's Forge
3. Load components into the RPED equivalent (**Rapid Artifice Device**)
4. Visit machines across the ship — open with screwdriver, apply RAD, close with screwdriver
5. Advanced version (researched): **Bluespace Artifice Device** — upgrade machines remotely via camera console, no physical access needed

### What Gets Upgraded

| Machine | Department | Upgrade Effect |
|---|---|---|
| Smelting Furnace | Artisanship | Faster smelting, better material yield |
| Artisan's Forge | Artisanship | Faster crafting, lower material cost |
| Elixir Crucible | Alchemy | Better purity, faster reactions, advanced recipe access |
| Cryotube equivalent | Alchemy | Faster healing, better chemical multiplier |
| Jade Abacus Workstation | Divination | Longer scan range, more accurate results |
| Starskiff systems | Sky-Faring | Faster travel, larger cargo capacity |
| Armory equipment | Realm-Keeping | Better gear quality |
| Furnace collectors | Artisanship | More power output per cycle |

This creates the same cross-department dependency as SS13 — every department wants Artisanship to research and produce upgraded components for their machines.

---

## Aurumaton Construction (Robotics Equivalent)

Aurumatons are the Xianzhou equivalent of cyborgs and mechs. Built at the Aurumaton Foundry.

### Types

| Aurumaton | SS13 Equivalent | Function |
|---|---|---|
| **Worker Aurumaton** | Cyborg (Service/Engineering) | General labor — hauling, basic construction, cleaning |
| **Medical Aurumaton** | Cyborg (Medical) | Basic first aid, medicine dispensing |
| **Patrol Aurumaton** | Securitron / Cyborg (Security) | Basic patrol, alerts on disturbances |
| **Cargo Aurumaton** | Mulebot | Automated cargo transport between departments |
| **Combat Aurumaton** | Durand mech | Heavy combat platform for Cloud Knights (rare, expensive) |

### Construction Process
Same as SS13 exosuit/cyborg construction:
1. Print chassis parts at Aurumaton Foundry
2. Assemble frame
3. Add components (servos, power cell, programming module)
4. Install behavior module (determines type: worker, medical, patrol, etc.)
5. Activate

Aurumatons are NPC-controlled (not player-piloted, unlike cyborgs). They follow simple behavior routines based on their module. Better components = better performance.

---

## Furnace Master vs. Craftsman — Role Split

### Furnace Master (Head — Chief Engineer)
- **Furnace operation** — setup, monitoring, emergency response. This is their primary obligation.
- **Masterwork crafting** — only the Furnace Master can craft Tier 4 masterwork items
- **Machine upgrades** — oversees ship-wide upgrade program, installs components researched by Divination
- **Aurumaton construction** — builds and programs aurumatons
- **Ship construction** — approves and supervises major building projects
- **Research liaison** — requests schematic priorities from Divination, provides materials for experiments

### Craftsman (Worker — Station Engineer)
- **Smelting and crafting** — the bulk of production work. Process ore, craft goods, fill orders.
- **Ship maintenance** — hull repair, cable laying, general upkeep
- **Furnace assistance** — help with coolant cell replacement, containment monitoring, emergency response
- **Machine building** — construct new machines from frames + boards + components

At low pop, the Furnace Master does everything. At higher pop, Craftsmen handle production and maintenance while the Furnace Master focuses on the Furnace, research, and masterwork crafting.

---

## Round Start Workflow (Like SS13 Engineering)

1. **Furnace Master sets up the Creation Furnace** — insert coolant cells, calibrate containment field, start energy collectors, verify output on control console.
2. **Verify power grid** — check SMES levels, APC status across the ship, ensure all departments have power.
3. **Initial smelting** — process any starting materials in the Material Vault.
5. **Contact Divination** — request priority schematics (usually Industrial → Metallurgy → department-specific requests).
6. **Assess ship condition** — check for any pre-existing damage, plan repairs.
7. **Take crafting orders** — check the Commission Requests Board for what other departments need.
