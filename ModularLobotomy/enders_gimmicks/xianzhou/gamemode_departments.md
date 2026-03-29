# Xianzhou Luofu Gamemode — Department & Role Mapping

## How SS13 Departments Map to Xianzhou Commissions

This document maps traditional SS13 department structures to Xianzhou Alliance Commissions, adapting the core SS13 gameplay loop (departments with distinct roles, chain of command, access levels, and interdependence) to the merchant-focused Xianzhou setting.

---

## SS13 Department Overview (For Reference)

| SS13 Department | Head of Staff | Core Roles | Purpose |
|----------------|---------------|------------|---------|
| **Command** | Captain | HoP, HoS, CE, RD, CMO, QM | Station leadership and oversight |
| **Security** | Head of Security | Warden, Security Officer, Detective | Law enforcement, brig, investigations |
| **Engineering** | Chief Engineer | Station Engineer | Power, hull repair, construction |
| **Science** | Research Director | Scientist, Geneticist, Roboticist | R&D, xenobiology, ordnance, tech upgrades |
| **Medical** | Chief Medical Officer | Medical Doctor, Paramedic, Chemist, Coroner | Healing, chemistry, surgery, morgue |
| **Supply/Cargo** | Quartermaster | Cargo Tech, Shaft Miner, Bitrunner | Ordering supplies, mining, exports, economy |
| **Service** | Head of Personnel | Bartender, Cook, Botanist, Janitor, Chaplain, Curator, Lawyer | Food, drinks, plants, cleaning, morale, legal |
| **Silicon** | AI | Cyborg | Station automation, door control, law-bound assistance |

---

## Xianzhou Commission → Core Roles (Streamlined)

**Design Philosophy:** Each department has exactly **one Head** and **one Worker role** for the initial implementation. Additional specialized roles can be added later once the core gameplay loop is proven. Any player can flex into any department's work (just less efficiently), so a small crew can still run the whole ship.

---

### 1. Command

| Role | SS13 Equivalent | Responsibilities |
|------|-----------------|------------------|
| **Arbiter-General** | Captain | Overall authority over the Luofu. Final say on route changes, military deployments, emergency orders. Override access to all Commissions. Delegates security to the Commissioner. |

The Commission Heads (below) double as the rest of Command. No separate HoP — the Helm-Master handles ID access and personnel.

---

### 2. Sky-Faring Commission (Cargo/Supply + Navigation)

The economic engine of the gamemode. Handles trade, logistics, piloting, and navigation.

| Role | SS13 Equivalent | Responsibilities |
|------|-----------------|------------------|
| **Helm-Master** (Head) | Quartermaster | Oversees all trade and navigation. Approves routes, manages the cargo budget, handles guild operations, controls docking. Also handles ID access and personnel assignments. |
| **Pilot** | Cargo Tech + Shaft Miner | Flies starskiffs for resource gathering runs (like miners going to Lavaland), transports cargo between the Luofu and trade partners, loads/unloads at Starskiff Haven. The all-in-one field worker for Sky-Faring. |

**Key Area:** Starskiff Haven — the main port, docking area, warehouses, and guild offices.

**Gameplay Loop:**
1. Helm-Master reviews Divination intel and plots a trade route
2. Pilots fly out to gather resources at planets/stations/asteroid fields
3. Pilots bring materials back and deliver to Artisanship/Alchemy for crafting
4. Helm-Master manages trade deals when the Luofu reaches a destination
5. Pilots transport finished goods to buyers

**Future roles to add:** Amicassadors (specialized guild traders), Navigator, Starskiff Technician

---

### 3. Divination Commission (Science/Research)

Generates the intel that drives the entire gameplay loop. Without Divination, the crew is flying blind.

| Role | SS13 Equivalent | Responsibilities |
|------|-----------------|------------------|
| **Master Diviner** (Head) | Research Director | Oversees all divination. Uses the Matrix of Prescience for high-level scans and predictions. Reviews major decisions. Can perform advanced divinations (predict market shifts, incoming threats, rare resources). |
| **Diviner** | Scientist | Operates jade abacus tech to scan the galaxy map — reveals system info (resources, factions, dangers, demand). Passes intel to Sky-Faring. Maintains and upgrades divination equipment. |

**Key Area:** Divination Commission Hall — Matrix of Prescience Ultima, jade abacus workstations, Cloudpeer Telescope (long-range scanner), archive/library.

**Gameplay Loop:**
1. Diviners scan nearby systems with jade abacus tech
2. Results reveal: available resources, faction presence, trade demand, danger level
3. Intel passed to Helm-Master for route planning
4. Master Diviner predicts future events (market crashes, Abundance attacks, rare spawns)
5. "Three taboos" — rushing or dishonest divinations give unreliable/wrong results

**Future roles to add:** Matrix Manager (equipment upgrades), Archivist (records/library)

---

### 4. Artisanship Commission (Engineering + Manufacturing)

Where raw materials become sellable products. Also keeps the ship running.

| Role | SS13 Equivalent | Responsibilities |
|------|-----------------|------------------|
| **Furnace Master** (Head) | Chief Engineer | Oversees all crafting and ship maintenance. Can produce masterwork items (higher value). Manages the Creation Furnace (heliobi-powered engine). Has access to advanced recipes. |
| **Craftsman** | Station Engineer | General manufacturing — weapons, ship parts, tools, jade carvings, porcelain, trade goods. Also handles ship repairs, hull maintenance, and furnace upkeep. |

**Key Area:** The Creation Furnace & Forges — heliobi-powered furnace, smelting equipment, workbenches, jade carving stations, Sapientia Academe (R&D for new schematics).

**Gameplay Loop:**
1. Receive raw materials from Pilots
2. Process materials (smelt ore, cut jade, refine components)
3. Craft trade goods using recipes/schematics
4. Higher-tier recipes require Divination Commission research or rare materials
5. Deliver finished goods to Sky-Faring for trade
6. Maintain the ship — keep the furnace running, repair damage, build upgrades

**Future roles to add:** Apprentice (entry-level), Master Artisan (senior crafter)

---

### 5. Alchemy Commission (Medical + Chemistry + Botany)

Healing, medicine production, herb growing, and food therapy. Products double as valuable trade goods.

| Role | SS13 Equivalent | Responsibilities |
|------|-----------------|------------------|
| **Cauldron Master** (Head) | Chief Medical Officer | Oversees all medical and alchemical operations. Handles serious medical cases and surgery. Has access to advanced elixir recipes. Licenses medicines. |
| **Alchemist** | Chemist + Medical Doctor + Botanist | The all-in-one worker for Alchemy. Brews medicines and elixirs, treats injuries and illnesses, grows medicinal herbs in the gardens, prepares food therapy dishes. Produces both crew supplies AND trade goods for export. |

**Key Area:** Evemist Mansion & Alchemy Labs — treatment rooms, elixir crucibles (chem dispensers), herb gardens, surgery, apothecary, Ranzhi School kitchen.

**Gameplay Loop:**
1. Alchemist grows herbs and gathers biological ingredients
2. Alchemist refines them into medicines, elixirs, and food therapy dishes
3. Cauldron Master handles advanced recipes and serious medical cases
4. Surplus products sent to Sky-Faring (Goldstream Guild) for export
5. Mara monitoring — track crew for symptoms, produce suppressants

**Future roles to add:** Herbalist (dedicated botanist), Physician (dedicated doctor), Military Healer (paramedic), Food Therapist (dedicated cook)

---

### 6. Realm-Keeping Commission + Cloud Knights (Security)

The Commissioner commands, the Cloud Knights enforce. Together they are the Security department.

| Role | SS13 Equivalent | Responsibilities |
|------|-----------------|------------------|
| **Commissioner** (Head) | Head of Security | **Boss of Security.** Sets security policy, authorizes arrests and investigations, manages the brig and holding cells, handles prisoner processing, distributes armory gear. Also manages resource allocation and civil administration. At low pop, covers HoS + Warden + Detective duties. |
| **Cloud Knight** | Security Officer | The muscle. Patrols the Luofu, enforces regulations, arrests criminals, responds to threats. Defends the ship during Abundance attacks and pirate raids, escorts Pilots on dangerous runs, guards high-value cargo. Both internal policing and external combat. |

**Key Areas:**
- Exalting Sanctum Chancery (Security Office + Brig) — holding cells, investigation rooms, administrative offices, armory window
- Cloud Knight Garrison (Armory + ready room) — armory, training grounds, starskiff launch bays

**Chain of Command:** General → Commissioner → Cloud Knights

**Gameplay Loop:**
1. Commissioner sets patrol routes and security priorities
2. Cloud Knights patrol, respond to calls, escort Pilots on dangerous missions
3. During travel events (attacks, pirates), Cloud Knights defend the ship
4. Commissioner manages prisoners, investigations, and coordinates from the Chancery
5. Between events, Cloud Knights assist other departments as needed (carrying cargo, guarding the forges, etc.)

**Future roles to add:** Orderly (Warden), Inspector (Detective), Counselor (Deputy HoS/field commander), Lieutenant, Scout

---

### 7. Ten-Lords Commission (Event-Driven — Not a starting role)

Not part of the initial role roster. The Ten-Lords activate as an **event mechanic** rather than a standing department. When mara outbreaks or supernatural events occur, existing crew respond using Ten-Lords tools distributed during the crisis. At higher pop or in later development, dedicated Judge and Spiritfarer roles can be added.

**Future roles to add:** Judge, Spiritfarer, Wraith Warden

---

### 8. Civilian / Outworlder (Assistant equivalent)

| Role | SS13 Equivalent | Responsibilities |
|------|-----------------|------------------|
| **Outworlder** | Assistant | No Commission assignment. Free to help any department. Can use any Commission's basic equipment (at reduced efficiency). Can seek formal employment from the Helm-Master to join a Commission mid-round. The flex role for new players or extra hands. |

---

## Core Role Summary

| # | Role | Department | SS13 Equivalent | Type |
|---|------|-----------|-----------------|------|
| 1 | Arbiter-General | Command | Captain | Head |
| 2 | Helm-Master | Sky-Faring | Quartermaster | Head |
| 3 | Pilot | Sky-Faring | Cargo Tech + Miner | Worker |
| 4 | Master Diviner | Divination | Research Director | Head |
| 5 | Diviner | Divination | Scientist | Worker |
| 6 | Furnace Master | Artisanship | Chief Engineer | Head |
| 7 | Craftsman | Artisanship | Station Engineer | Worker |
| 8 | Cauldron Master | Alchemy | Chief Medical Officer | Head |
| 9 | Alchemist | Alchemy | Chemist + Doctor + Botanist | Worker |
| 10 | Commissioner | Realm-Keeping | Head of Security | Head |
| 11 | Cloud Knight | Cloud Knights | Security Officer | Worker |
| 12 | Outworlder | None | Assistant | Flex |

**Total: 12 roles (6 Heads, 5 Workers, 1 Flex)**

Playable with 10 players — not every Head slot needs to be filled. At minimum: General, Helm-Master, Furnace Master, Cauldron Master, Commissioner, 2 Pilots, 2 Cloud Knights, 1 Diviner = 10 players. Missing Heads have their duties absorbed by the General or nearest worker.

---

## Department Interdependencies

The gamemode's core loop requires departments to work together:

```
[Divination] scans galaxy → intel to → [Sky-Faring] plots route
                                              ↓
                                    [Pilots] gather resources
                                              ↓
                            [Artisanship] crafts goods ← materials
                            [Alchemy] brews medicines  ← herbs
                                              ↓
                                    [Sky-Faring] loads cargo
                                              ↓
                                    [Sky-Faring] sells at destination
                                              ↓
                                    Profits → ship upgrades, more supplies

[Realm-Keeping + Cloud Knights] defend ship, maintain order, escort pilots
[Ten-Lords] respond to mara/supernatural events
[General Jing Yuan] oversees everything
```

## Access Levels (Preliminary)

| Access Level | Who Has It | What It Opens |
|-------------|-----------|---------------|
| **General** | Jing Yuan only | Everything. War room, all Commission areas, armory override. |
| **Commission Head** | Each respective head | Their Commission + Command meeting area + Bridge |
| **Sky-Faring** | Sky-Faring staff | Starskiff Haven, warehouses, guild offices, docking controls |
| **Divination** | Divination staff | Matrix of Prescience, jade abacus labs, archive, telescope |
| **Artisanship** | Artisanship staff | Forges, Creation Furnace, workshops, Sapientia Academe |
| **Alchemy** | Alchemy staff | Labs, herb gardens, treatment rooms, apothecary, elixir stores |
| **Realm-Keeping** | Realm-Keeping staff | Chancery, holding cells, weather pavilion, administrative offices |
| **Cloud Knight** | Cloud Knights | Garrison, armory, starskiff launch bays, war room |
| **Ten-Lords** | Ten-Lords only | Shackling Prison, Hall of Karma, Pavilion of Cessation |
| **Common** | Everyone | Public areas, markets, tea houses, living quarters |

---

## Low-Pop Scaling (10+ Players)

The gamemode must be playable with as few as ~10 players. To achieve this, the design follows two principles:

1. **Any player can do any Commission's work** — just less efficiently than the dedicated role.
2. **Dedicated roles get bonuses** — speed, quality, access to advanced recipes/tools, and unique abilities.

### Core Roles vs. Flex Roles

At low pop, only the **Core Roles** need to be filled. Everything else can be handled by anyone willing to walk over to that Commission's workspace and do the job.

#### Minimum Crew (10 players)

| Role | Commission | What They Cover |
|------|-----------|-----------------|
| **Arbiter-General** | Command | Leadership, final decisions, override access. Can assist any Commission. |
| **Helm-Master** | Sky-Faring | Navigation, trade, cargo, docking. Handles all guild duties solo at low pop. |
| **Master Diviner** | Divination | Galaxy scanning, route intel, predictions. |
| **Furnace Master** | Artisanship | Crafting, ship maintenance, power/furnace management. |
| **Cauldron Master** | Alchemy | Medicine, alchemy, herb growing, food therapy. |
| **Commissioner** | Realm-Keeping (HoS) | Security command, law enforcement, administration, resource tracking. Directs Cloud Knights. |
| **Cloud Knight (x2)** | Realm-Keeping / Cloud Knights (Sec Officers) | Patrols, arrests, defense, escort, scouting. Two minimum for combat viability. Report to Commissioner. |
| **Pilot (x2)** | Sky-Faring | Resource gathering runs, cargo transport. Two allows concurrent runs. |
| **Civilian/Outworlder** | None | Flex role — can assist any Commission. |

#### How Flex Works

**Anyone can use any Commission's equipment**, but with penalties:

| Action | Dedicated Role | Non-Dedicated (Flex) |
|--------|---------------|---------------------|
| **Crafting** | Full recipe list, faster crafting, higher quality output | Basic recipes only, slower crafting, lower quality (sells for less) |
| **Divination** | Full scan range, accurate predictions, advanced tools | Short scan range, vague/unreliable results, basic tools only |
| **Alchemy/Medicine** | Full recipe list, better purity, advanced surgery | Basic medicines only, lower purity, first-aid only |
| **Piloting** | Faster travel, better cargo capacity, can land on dangerous planets | Slower travel, reduced cargo, safe planets only |
| **Combat** | Full armory access, combat bonuses, martial arts | Basic weapons only, no bonuses |
| **Trading** | Better prices, bulk deals, guild contacts, reputation bonuses | Standard prices, no bulk deals, no reputation perks |

**Example:** If there's no Cauldron Master, the Furnace Master can walk over to the Alchemy labs and brew basic medicines — they'll be slower, lower quality, and they won't have access to advanced elixirs, but it keeps the crew alive. If someone IS playing Cauldron Master, their medicines are faster, purer, and sell for more.

### Scaling Up (15-25+ players)

As player count grows, more specialized roles open up:

| Player Count | New Roles That Open |
|-------------|-------------------|
| **10-12** | Core roles only. Heads double as workers. Everyone flexes. |
| **13-15** | + Craftsman, Alchemist, additional Cloud Knights, Starskiff Tech |
| **16-18** | + Diviner, Herbalist, Military Healer, Guild Amicassadors |
| **20-25** | + Apprentices, Food Therapist, Archivist, Scout, Inspector |
| **25+** | + Judge (Ten-Lords), Spiritfarer, Navigator, Wraith Warden — full roster |

### Commission Head Multi-Tasking

At low pop, Commission Heads are expected to do the work themselves rather than just manage. The design reflects this:

- **Furnace Master** — Personally crafts goods AND maintains the furnace. Only delegates at higher pop.
- **Cauldron Master** — Personally brews medicines AND treats patients. Gets an Alchemist to handle production at higher pop.
- **Master Diviner** — Personally operates the jade abacus AND interprets results. Gets Diviners to handle routine scans at higher pop.
- **Helm-Master** — Personally navigates AND manages trade. Gets Amicassadors and Starskiff Techs at higher pop.
- **Commissioner** — Personally patrols AND handles admin. Gets Officers and Orderlies at higher pop.

### Cross-Commission Incentives

To encourage players to help other Commissions rather than only doing their own job:

- **Shared Profit Pool** — All trade income goes to a central fund. Everyone benefits from the ship doing well. Individual contribution is tracked for reputation/rank-up rewards.
- **Commission Requests Board** — A public board where Commissions post what they need ("Artisanship needs 50 units of iron ore", "Alchemy needs Stardust Herbs"). Anyone can fulfill these for bonus reputation.
- **Flexible Access** — Public-access crafting stations and basic alchemy benches exist in common areas. Slower and limited, but available to everyone without needing Commission access.

### Aurumaton Assistants (NPC Gap-Fillers)

When a Commission has no players, basic **Aurumaton workers** (NPC equivalents) handle the absolute minimum:

- Aurumaton Medic — Dispenses basic first aid at the Alchemy Commission if no players are there
- Aurumaton Furnace Tender — Keeps the Creation Furnace running (won't craft goods, just prevents power failure)
- Aurumaton Dockworker — Loads/unloads cargo at Starskiff Haven automatically
- Aurumaton Patrol — Basic security presence in public areas

These NPCs do the bare minimum to keep things functional but produce nothing of value for trade. Players are always better.
