# MetaStation Map Analysis - Department Equipment Inventory

Analysis of `/MetaStation.dmm` (136,834 lines) cataloging machines, structures, and equipment by department.

> **Note:** LC13 has removed atmospheric simulation (PR #198). All atmospheric equipment listed below (scrubbers, vents, air alarms, pipes, canisters, gas storage, atmos computers) is **not applicable** to the Xianzhou gamemode. This analysis is kept as a reference for understanding vanilla SS13 map structure, but atmos equipment should be skipped when mapping for LC13.

---

## Engineering

### Sub-areas
- `engineering/main` - Main engineering hall
- `engineering/atmos` - Atmospherics
- `engineering/atmos/pumproom` - Atmos pump room
- `engineering/atmos/storage/gas` - Gas storage
- `engineering/atmospherics_engine` - Atmos engine room
- `engineering/break_room` - Engineering break room
- `engineering/circuit_workshop` - Circuit workshop
- `engineering/gravity_generator` - Gravity generator room
- `engineering/supermatter` + `supermatter/room` - SM engine
- `engineering/storage/tcomms` - Telecomms storage
- `engineering/storage/tech` - Tech storage
- `engineering/storage_shared` - Shared storage
- `engineering/transit_tube` - Transit tube

### Key Machines
| Machine | Count |
|---------|-------|
| Recharger | 10 |
| Cell charger | 9 |
| PACMAN generator (pre-loaded) | 8 |
| Conveyor | 10 |
| Thermomachine freezer | 5 |
| Thermomachine heater | 4 |
| Mech bay power console | 4 |
| SMES (various) | 5 (2 full, 2 engineering, 1 super/full) |
| Emitter (welded) | 3 |
| Field generator | 2 |
| Autolathe | 1 |
| Protolathe (engineering dept) | 1 |
| Circuit imprinter | 1 |
| Techfab (security dept) | 1 |
| Mecha part fabricator | 1 |
| Chem dispenser | 1 |
| Chem heater (with buffer) | 2 |
| Cryo cell | 1 |
| Gravity generator | 1 |
| Drone dispenser | 1 |
| Turbine outlet | 1 |
| RnD server (master) | 1 |

### Portable Atmospherics
| Type | Count |
|------|-------|
| Generic canister | 9 |
| Air canister | 8 |
| N2O canister | 7 |
| Nitrogen canister | 6 |
| Oxygen canister | 5 |
| Plasma canister | 3 |
| CO2 canister | 3 |
| Anesthetic canister | 2 |
| Water vapor canister | 1 |
| Portable pump | 4 |
| Portable scrubber | 3 |
| Pipe scrubber | 1 |

### Computers
- Station alert (3), Atmos alert (1)
- Atmos control: air, oxygen, nitrogen, N2O, plasma, CO2, mix tank, master (1 each)
- Turbine computer (1)
- Teleporter (2), Telecomms server (1)
- Cargo request (2), Security (1), Records medical (3), Records security (3)
- Crew monitoring (1), Power monitoring (1), Warrant (1)
- Shuttle/mining (1), Quantum console (1)
- Slot machine (4), Orion Trail arcade (1)
- Mech bay power (4)

### Suit Storage
- Engine suit (2), CE suit (1), Atmos suit (1), RD suit (1), HoS suit (1), Medical suit (1)

### Telecomms Equipment
- Server presets: supply, security, common (1 each)
- Processor presets: 1-4 (4 total)
- Bus presets: 1-4 (4 total)

### Vending
- Engivend (1), Tool (1), Coffee (7), Cigarette (7), Assist (2)
- Assorted wardrobe vendors (engi, atmos, det, chem, chap, bar, gene, science, law)

---

## Medical

### Sub-areas
- `medical/medbay/central` - Main medbay
- `medical/medbay/lobby` - Medbay lobby
- `medical/chemistry` - Chemistry lab
- `medical/chem_storage` - Chemical storage
- `medical/pharmacy` - Pharmacy
- `medical/surgery/theatre` - Surgery theatre
- `medical/surgery/aft` - Aft surgery
- `medical/treatment_center` - Treatment center
- `medical/cryo` - Cryogenics
- `medical/morgue` - Morgue
- `medical/virology` - Virology
- `medical/genetics` (redirected to science)
- `medical/paramedic` - Paramedic office
- `medical/psychology` - Psychology office
- `medical/break_room` - Medical break room
- `medical/storage` - Medical storage
- `medical/coldroom` - Cold room
- `medical/abandoned` - Abandoned medbay section

### Key Machines
| Machine | Count |
|---------|-------|
| Chem dispenser | 3 |
| Chem master | 3 |
| Chem heater (with buffer) | 3 |
| Chem mass spectrometer | 1 |
| Reagent grinder | 5 |
| IV drip | 7 |
| Cryo cell | 2 |
| Stasis bed | 2 |
| Operating computer | 4 |
| Defibrillator mount | 3 |
| DNA scanner | 1 |
| DNA console | 1 |
| Pandemic console | 1 |
| Scanner gate (guns preset) | 1 |
| Plumbing synthesizer | 1 |
| Condimaster | 2 |
| Techfab (medical dept) | 1 |
| Protolathe (engineering dept) | 1 |
| Smartfridge (organ) | 4 |
| Smartfridge (chemistry, preloaded) | 3 |
| Smartfridge (virology) | 1 |
| Smartfridge (drying) | 1 |
| Recharge station (borgs) | 6 |
| Microwave | 6 |

### Medical Supplies
| Item | Count |
|------|-------|
| Defibrillator (loaded) | 4 |
| Syringe | 5 |
| Dropper | 15 |
| Beaker | 12 |
| Large beaker | 9 |
| Cryoxadone beaker | 4 |
| Blood bags (random) | 8 |
| Named blood bags (all types) | 8 (A+/-, B+/-, O+/-, lizard, ethereal) |
| Epinephrine bottles | 7 |
| Multiver bottles | 7 |
| Morphine bottles | 4 |
| Body bags box | 4 |
| Surgery manual | 4 |
| Morgue trays | 9 |
| Emergency med beds | 11 |

### Computers
- Operating (4), Crew (3), Records medical (2), Records medical laptop (3)
- Records security (8), Station alert (2), Warrant (1)
- Exoscanner control (1), Gateway control (1), Mechpad (1)
- APC control (1), Cargo (1), Cargo request (1)

### Vending
- Medical (1), Drugs (1), NanoMed implicit via vending/drugs
- Wardrobe: medi, viro, coroner, robo, chem, chef, curator, bar, atmos (1 each)

---

## Science

### Sub-areas
- `science/lab` - Main science lab
- `science/lobby` - Science lobby
- `science/research` - Research wing
- `science/robotics/lab` - Robotics lab
- `science/robotics/mechbay` - Mech bay
- `science/genetics` - Genetics lab
- `science/xenobiology` - Xenobiology
- `science/xenobiology/hallway` - Xeno hallway
- `science/cytology` - Cytology
- `science/explab` - Exploration lab
- `science/ordnance` - Ordnance main
- `science/ordnance/bomb` - Bomb range
- `science/ordnance/burnchamber` - Burn chamber
- `science/ordnance/freezerchamber` - Freezer chamber
- `science/ordnance/office` - Ordnance office
- `science/ordnance/storage` - Ordnance storage
- `science/ordnance/testlab` - Test lab
- `science/server` - Server room

### Key Machines
| Machine | Count |
|---------|-------|
| RnD console (unlocked) | 3 |
| Destructive analyzer | 1 |
| Destructive scanner | 1 |
| Experimentor | 1 |
| Protolathe (science dept) | 1 |
| Circuit imprinter (science dept) | 2 |
| Mecha part fabricator | 2 |
| Mech bay recharge port | 3 |
| Mech bay power console | 4 |
| Mechpad | 1 |
| Mechpad computer | 1 |
| DNA scanner | 3 |
| DNA console | 3 |
| DNA infuser | 1 |
| Monkey recycler | 1 |
| Processor (slime) | 1 |
| Processor | 2 |
| Xenobio camera console | 2 |
| Quantum server | 1 |
| RnD server (master) | 1 |
| RnD server | 1 |
| Doppler array | 1 |
| Anomaly refinery | 1 |
| Tank compressor | 1 |
| Chem dispenser | 1 |
| Chem heater (with buffer) | 2 |
| Chem dispenser (drinks/beer) | 1 |
| Space heater (improvised chem heater) | 2 |
| Thermomachine freezer | 4 |
| Thermomachine heater | 2 |
| Shield wall generator (xeno) | 1 |
| Mass driver (ordnance) | 1 |
| Exoscanner control | 1 |
| Exodrone control | 1 |

### Ordnance Equipment
- Ordnance burn chamber + freezer chamber with air sensors
- Outlet injectors (burn + freezer input)
- Ordnance mass driver + driver controller
- Doppler array (1)
- Ordnance camera preset (1)

### Computers
- RnD console unlocked (3), RnD server control (1)
- Operating (3), DNA console (3)
- Mech bay power (4), Mechpad (1), Mecha (1), Robotics (1)
- Xenobio camera (2), Telecomms server/monitor (2)
- Cargo (1), Cargo request (1), Crew (1), Exoscanner (1), Exodrone (1)
- Slot machine (5), Wooden TV (2)

### Vending
- Cytopro (1), Games (1)
- Wardrobe: science, robo (1 each)

---

## Security

### Sub-areas
- `security/office` - Main security office
- `security/brig` - Brig
- `security/armory` - Armory
- `security/warden` - Warden's office
- `security/lockers` - Security lockers
- `security/detectives_office` - Detective's office
- `security/evidence` - Evidence storage
- `security/interrogation` - Interrogation room
- `security/holding_cell` - Holding cell
- `security/courtroom` - Courtroom
- `security/medical` - Security medical
- `security/mechbay` - Security mech bay
- `security/range` - Firing range
- `security/prison` - Prison wing
- `security/prison/garden` - Prison garden
- `security/prison/mess` - Prison mess
- `security/prison/safe` - Prison safe room
- `security/prison/shower` - Prison showers
- `security/prison/visit` - Prison visitation
- `security/prison/work` - Prison work area
- `security/execution/education` - Education room
- `security/execution/transfer` - Transfer room
- `security/checkpoint/*` - Checkpoints (customs, engineering, medical, science, supply)

### Key Machines
| Machine | Count |
|---------|-------|
| Recharger | 12 |
| Cell charger | 9 |
| Flasher (wall-mounted) | 14 (4 south, 4 east, 3 west, 3 north) |
| Flasher (portable) | 3 |
| Scanner gate (guns preset) | 2 |
| Conveyor | 20 |
| Conveyor switch | 1 |
| Hydroponics soil | 10 |
| Hydroponics constructable | 4 |
| Door timer/status display | 3 |
| Secure brig closets | 8 |
| Holopad (secure) | 7 |
| Turret (AI) | 3 |
| Turret controller | 1 |
| Techfab (security dept) | 1 |
| Techfab (cargo dept) | 1 |
| Mecha part fabricator | 1 + 1 maint |
| Mech bay recharge port | 2 |
| Mech bay power console | 2 |
| DNA scanner | 1 |
| DNA console | 2 |
| Photobooth (security) | 1 |
| PDA painter (security) | 1 |
| Library scanner | 1 |
| Exoscanner | 1 |

### Brig Doors
- Brig doors (left/north) | 5
- Brig security cell doors (left/south) | 3
- Various brig door configurations

### Security Equipment
| Item | Count |
|------|-------|
| Tape recorder | 8 |
| Evidence boxes | 5 |
| Handcuffs | 14 |
| Security space law manual | 16 |
| Prisoner uniforms | 9 |
| Prisoner skirts | 4 |
| Prisoner shoes (orange) | 9 |
| Prisoner boxes | 3 |
| Formal officer uniform | 6 |
| Security sunglasses | 2 |
| GARS sunglasses | 2 |
| Temperature gun | 1 |
| Detective camera | 1 |
| Implanter | 1 |
| GPS | 1 |
| Security key | 1 |

### Computers
- Records security (10), Records medical (4 + laptops)
- Security (6), Security HoS (1), Security labor (1)
- Warrant (2), Crew (4), Operating (4)
- Prisoner management (2), Gulag teleporter (1), Labor shuttle (1)
- Communications (2), Station alert (2)
- Mech bay (2), Mechpad (1), Mecha (2)
- AI upload (1), Borg upload (1)

### Vending
- Security (1), Sustenance (1), Games (1)
- Wardrobe: sec (1)

---

## Cargo/Supply

### Sub-areas
- `cargo/storage` - Main cargo bay
- `cargo/sorting` - Sorting office
- `cargo/lobby` - Cargo lobby
- `cargo/warehouse` - Warehouse
- `cargo/miningoffice` - Mining office
- `cargo/bitrunning/den` - Bitrunning den

### Key Machines
| Machine | Count |
|---------|-------|
| Conveyor | 24 |
| Conveyor switch (oneway) | 6 |
| Plastic flaps | 11 |
| Disposal/delivery chute | 9 |
| Autolathe | 1 |
| Techfab (cargo dept) | 1 |
| Ore redemption machine | 1 |
| Boulder smelter/refinery | 1 |
| Stacking unit console | 1 |
| PDA painter (supply) | 1 |
| Status display (supply) | 3 |

### Computers
- Cargo (2), Cargo request (1)
- Quantum console (1)
- Mining shuttle (2: common + standard)
- Order console: mining (1), bitrunning (1)
- Slot machine (2)
- Security mining (1)
- Gulag teleporter (1)
- Holodeck (1)

### Vending
- Clothing (1), Games (1), Coffee (1)
- Wardrobe: cargo (1)

---

## Command

### Sub-areas
- `command/bridge` - Main bridge
- `command/eva` - EVA storage
- `command/vault` - Station vault
- `command/teleporter` - Teleporter room
- `command/gateway` - Gateway room
- `command/corporate_showroom` - Corporate showroom
- `command/heads_quarters/captain/private` - Captain's quarters
- `command/heads_quarters/hop` - HoP office
- `command/heads_quarters/ce` - CE office
- `command/heads_quarters/cmo` - CMO office
- `command/heads_quarters/hos` - HoS office
- `command/heads_quarters/rd` - RD office
- `command/heads_quarters/qm` - QM office

### Key Machines
| Machine | Count |
|---------|-------|
| Modular computer (ID console) | 7 |
| Fax machine | 11 |
| Recharger | 8 |
| Flasher (wall-mounted) | 9 |
| Keycard authentication | 6 |
| Suit storage (standard) | 5 |
| Suit storage (captain) | 1 |
| Suit storage (department heads) | 6 (CE, CMO, HoS, RD, industrial/loader) |
| Gateway (center station) | 1 |
| Teleporter | 1 |
| AI slipper | 2 |
| Incident display | 2 (delam + bridge) |
| Photocopier | 6 |
| PDA painter (all depts) | 6 |

### Computers
- Communications (2), Crew (2), Records security (7), Records medical (7)
- Security (4), Security HoS (1), Security QM (1)
- Station alert (2), Power monitor (1), APC control (1)
- Teleporter (1), Gateway control (1)
- Cargo (1), Cargo request (2), Bank machine (1), Accounting (1)
- Warrant (1), Operating (1)
- Mech bay power (3), Mecha (2), Mechpad (1)
- Atmos control: master, N2O, mix, incinerator (1 each)
- Atmos alert (1)
- Pirate pad control (1)

### Notable Items
- Chain of command (melee) | 1
- Captain's bedsheet | 1
- Gold flask | 1
- Secure briefcases | 8
- AI cards | 3
- Void stamp | 1
- Captain's stamp | 1
- Training bomb | 1

---

## Service (Kitchen/Bar/Botany/Chapel/Library/Janitor)

### Sub-areas
- `service/kitchen` - Kitchen
- `service/kitchen/coldroom` - Kitchen cold room
- `service/bar` - Bar
- `service/bar/backroom` - Bar backroom
- `service/cafeteria` - Cafeteria
- `service/hydroponics` - Hydroponics/Botany
- `service/hydroponics/garden` - Public garden
- `service/chapel` - Chapel
- `service/chapel/funeral` - Funeral parlor
- `service/chapel/office` - Chaplain's office
- `service/library` - Library
- `service/janitor` - Janitor's closet
- `service/lawoffice` - Law office
- `service/theater` - Theater

### Kitchen/Bar Machines
| Machine | Count |
|---------|-------|
| Microwave | 4 |
| Oven/range | 1 |
| Gibber | 1 |
| Processor (food) | 1 |
| Reagent grinder | 3 |
| Condimaster | 3 |
| Chem master | 3 |
| Chem heater (with buffer) | 2 |
| Chem mass spectrometer | 1 |
| Chem dispenser (drinks) | 1 |
| Chem dispenser (drinks/beer) | 1 |
| Smartfridge (food) | 1 |
| Smartfridge (drinks) | 1 |
| Smartfridge (chemistry, preloaded) | 2 |
| Smartfridge (drying) | 1 |
| Food cart | 1 |
| Restaurant portal (bar) | 1 |
| Order console (cook) | 1 |

### Botany Machines
| Machine | Count |
|---------|-------|
| Hydroponics soil | 6 |
| Hydroponics soil (rich) | 3 |
| Hydroponics constructable | 6 |
| Seed extractor | 3 |
| Biogenerator | 2 |

### Botany Supplies
- Cultivator (7), Hatchet (3), Watering can (7)
- Seeds: wheat, sugarcane, potato, apple (1 each)
- Various grown produce decorating the area

### Library/Chapel
| Machine | Count |
|---------|-------|
| Library scanner | 1 |
| Library console | 2 (1 management + 1 browse) |
| Bookbinder | 1 |
| BCI implanter | 1 |
| Mass driver (chapel gun) | via computer |
| Bible | 3 |
| Codex Gigas | 1 |

### Janitor
- Mop (1)
- Janitor key (1)
- Cleaner grenades (3)

### Vending
- Booze-O-Mat (2), Dinnerware (1), Hydroseeds (1), Hydronutrients (1)
- Autodrobe (2), Games (1), Sustenance (1)
- Wardrobe: hydro, chef, bar, chap, curator, jani, law (1 each)

---

## Commons

### Sub-areas
- `commons/locker` - Locker room
- `commons/lounge` - Lounge
- `commons/dorms` - Dormitories
- `commons/fitness` - Fitness room
- `commons/fitness/recreation` - Recreation area
- `commons/storage/primary` - Primary tool storage
- `commons/storage/tools` - Auxiliary tools
- `commons/toilet/restrooms` - Restrooms
- `commons/toilet/auxiliary` - Auxiliary toilet
- `commons/vacant_room/commissary` - Commissary
- `commons/vacant_room/office` - Vacant office

### Key Machines
| Machine | Count |
|---------|-------|
| Washing machine | 3 |
| Shower | 15 (6 west, 6 east, 2 south, 1 north) |
| Recharger | 6 |
| Cell charger | 2 |
| Slot machine | 3 |
| Photocopier | 3 |
| Holodeck computer | 1 |
| Suit storage (standard) | 2 |
| Techfab (cargo dept) | 1 |

### Vending
- Cigarette (8), Coffee (2), Assist (2), Autodrobe (2)
- Tool (1), ModularPC (1), Clothing (1), Drugs (1), Engivend (1)

---

## AI Satellite

### Sub-areas
- `ai/satellite/chamber` - AI core chamber
- `ai/satellite/foyer` - Satellite foyer
- `ai/satellite/interior` - Interior corridors
- `ai/satellite/exterior` - Exterior ring
- `ai/satellite/maintenance/storage` - Maintenance storage
- `ai/upload/chamber` - AI upload chamber
- `ai/upload/foyer` - Upload foyer

### Key Machines
| Machine | Count |
|---------|-------|
| AI turret | 10 |
| Turret controller | 3 |
| Motion-sensing camera | 4 |
| AI upload computer | 1 |
| Borg upload computer | 1 |
| Teleporter computer | 1 |
| Mecha part fabricator (maint) | 1 |
| Mech bay recharge port | 1 |

### AI Modules
- Freeform module (1)
- Purge module (2: 1 in AI sat, 1 elsewhere)
- Reset module (2)

---

## Summary: Critical Equipment Per Department

| Department | Fabrication | Chemistry | Medical | Power | Research |
|-----------|------------|-----------|---------|-------|----------|
| Engineering | Autolathe, Protolathe, Circuit Imprinter, Mecha Fab | Chem dispenser + heater | Cryo cell (1) | SMES (5), PACMAN (11), Emitters (5), Turbine | RnD Server |
| Medical | Techfab | 3x Dispenser, 3x Master, 3x Heater, Mass Spec | Cryo (2), Stasis (2), Surgery (4), DNA (1), Defib (7) | - | - |
| Science | Protolathe, 2x Circuit Imprinter, 2x Mecha Fab | Chem dispenser + 2x heater | DNA (3), Operating (3) | - | Destructive Analyzer, Experimentor, RnD Servers (2), Doppler, Anomaly Refinery |
| Security | Techfab (sec+cargo), Mecha Fab (2) | - | DNA (1), Operating (4) | - | - |
| Cargo | Autolathe, Techfab | - | - | - | Ore Redemption, Smelter |
| Command | - | - | Operating (1) | - | - |
| Service | - | 2x Chem dispenser (drinks), Condimaster (3), Chem Master (3) | - | - | - |
