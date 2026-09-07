# Alchemy Commission — Expanded Design

The Alchemy Commission merges SS13 Medical, Chemistry, Botany, and Cooking into a single department. Alchemists heal the crew, brew medicines, grow herbs, and prepare food — and everything they produce doubles as trade goods. The Cauldron Master is CMO, head chemist, and head botanist rolled into one.

---

## SS13 Foundation — What We're Pulling From

### From Chemistry
- **Chemistry Dispenser** → **Elixir Crucible**. Dispenses base reagents, player combines them into products.
- **Reaction system** — temperature, pH, and purity mechanics. Reactions proceed over time, not instantly. Exothermic/endothermic behavior. This is the core alchemy gameplay.
- **Chemical Heater / Reaction Chamber** → **Alchemical Cauldron**. Provides precise heating/cooling, pH monitoring, real-time reaction tracking.
- **ChemMaster 3000** → **Elixir Refiner**. Separates chemicals, creates pills/patches/tubes from finished products.
- **HPLC (High-Performance Liquid Chromatography)** → **Purity Analyzer**. Detects and improves reagent purity.
- **Portable Chemical Mixer** → **Alchemist's Satchel**. Portable container for field medicine.
- **Buffer reagents** — acidic and basic buffers to adjust pH during reactions. Same mechanic.
- **Recipe recording** — save recipes to dispensers for repeat production. Same system.
- **Delivery systems** — pills, patches, syringes, smoke, foam, splash, spray. All carry over.

### From Medical
- **Surgery system** — operating table, operating computer, step-by-step surgical procedures. Carries over directly.
- **Sleepers / Cryotubes** → **Healing Pods**. Insert patient, apply chemicals, patient heals.
- **Health analyzer** → **Pulse Diagnostic Tool**. Scan patient to see damage types and amounts.
- **Defibrillator** → equivalent resuscitation tool.
- **IV drips** — hook up patient to continuous chemical feed.
- **Medical records** — track crew health status.
- **Damage types** — brute, burn, toxin, oxygen. Same damage model.
- **Body parts and surgery** — organ damage, limb repair, implants.

### From Botany
- **Hydroponics trays** → **Herb Garden Plots**. Plant seeds, water, harvest. Growth cycles, soil quality, light needs.
- **Seed types** with different properties — growth time, yield, potency, special traits.
- **Plant genetics / mutations** — cross-breeding for better strains. Advanced botany gameplay.
- **Nutriment and plant chemistry** — plants contain reagents extractable by grinding.
- **Biogenerator** — convert plant matter into materials (leather, cloth). Shared with Artisanship.

### From Cooking
- **Kitchen equipment** — microwave, grill, oven, all-in-one grinder.
- **Food recipes** — combine ingredients to make dishes with various effects.
- **Nutriment system** — food provides nutrition and sometimes chemical effects.

---

## Elixir Crucibles (Chemistry Dispensers)

The primary tool of the Alchemy Commission. Functionally identical to SS13 chemistry dispensers with Xianzhou naming.

### What Carries Over Directly

**Base Reagents Available:**
The crucible dispenses base alchemical ingredients. These map directly to SS13 chemistry reagents but with Xianzhou names:

| SS13 Reagent | Xianzhou Equivalent | Use |
|---|---|---|
| Hydrogen | Hydrogen | Base ingredient |
| Oxygen | Oxygen | Base ingredient |
| Carbon | Charite | Organic base |
| Nitrogen | Azurite Essence | Stabilizer |
| Water | Spring Water | Universal solvent |
| Ethanol | Grain Spirit | Solvent, disinfectant |
| Sulfuric Acid | Vitriolic Acid | Acid base |
| Chlorine | Sea Salt Extract | Purifier |
| Potassium | Mineral Salt | Reactive agent |
| Phosphorus | Phosphite | Catalyst |
| Radium | Radiant Essence | Energy catalyst |
| Stable Plasma | Stable Aether | Rare catalyst |
| Sugar | Cane Essence | Sweetener, nutrient |
| Silicon | Silite | Material base |
| Iron | Iron Tincture | Blood supplement |
| Lithium | Stonebright | Mood agent |
| Mercury | Quicksilver | Heavy catalyst |
| etc. | etc. | etc. |

The renaming is cosmetic — the underlying chemistry IDs and reaction formulas are unchanged. This means all SS13 chemistry recipes work out of the box with new display names.

**Upgradeable Parts (Same as SS13):**
- Better matter bins → more power efficiency per unit dispensed
- Better capacitor → faster recharging
- Better manipulator → unlocks additional reagents (Tier 4 unlocks advanced bases)
- Emagged → unlocks restricted/dangerous reagents

**Recipe Recording:**
Same system — click "Record Recipe" on crucible, dispense reagents, save with a name. Anyone can use saved recipes. This is critical for repeat production of common medicines and trade elixirs.

---

## The Reaction System (Core Alchemy Gameplay)

This is the heart of the Alchemy Commission. It carries over directly from SS13 chemistry with no mechanical changes — only flavor renaming.

### Temperature
- Reactions proceed over time, with rate tied to temperature
- **Exothermic** reactions produce heat (risk of overheating → reduced yield or explosion)
- **Endothermic** reactions consume heat (risk of overcooling → reaction stalls)
- The Alchemical Cauldron (reaction chamber) provides precise temperature control
- Some reactions require heating above a threshold to start
- Chemists must monitor temperature throughout the reaction

### pH System
- Every reagent has innate pH (0-14 scale)
- Beaker pH = sum of all reagent pHs in the mix
- Each recipe has an optimal pH range — center of the range gives best purity
- pH drifts during reaction and must be compensated with buffer reagents
- If pH falls outside the recipe's minimum/maximum range, the reaction won't start
- General rule: keep pH within 5-9

**Buffer Reagents:**
- Acidic Buffer and Basic Buffer adjust pH
- Formula: (Volume of Buffer / Volume of Mixture) × 30 = pH change
- Same mechanic, same math

### Purity System
- Purity determined by: reactant purity + how optimal pH was during the reaction
- Higher purity = stronger effect AND higher trade value
- Below inverse threshold → reagent transforms into harmful inverse form on consumption
- **HPLC equivalent (Purity Analyzer)** can purify reagents back to standard purity
- Purity directly affects both medical effectiveness and sale price — this makes quality alchemy doubly important in a trade economy

### Why Purity Matters More Here Than in SS13
In standard SS13, purity mostly affects healing effectiveness. On the Luofu, purity also determines trade value:
- 100% pure elixir sells for premium price
- 75% pure (standard) sells for normal price
- Below 50% is unsellable — too impure for export
- This gives skilled Alchemists a meaningful economic advantage over flex workers brewing at the basic Workbench

---

## The Alchemical Cauldron (Reaction Chamber)

Equivalent to the Chemical Heater / Reaction Chamber. The main production workstation.

### What Carries Over Directly
- Set target temperature, machine heats/cools toward it
- Buffer tanks for pH adjustment (refillable from beakers)
- Real-time reaction monitoring (pH, temperature, progress)
- Droppers work directly on the cauldron

**Upgrade Tiers (Same as SS13):**
| Tier | Feature Unlocked |
|---|---|
| 1 | Basic heating/cooling. Red flash if overheated. |
| 2 | pH meter flashes if outside optimal range. |
| 3 | Real-time reaction progress display. |
| 4 | Full quality dial — shows purity, pH factor, flashes if below minimum purity. |

Upgrading the Cauldron is one of the first things the Alchemy Commission should request from Artisanship. Tier 4 cauldron makes precision alchemy much easier → higher purity → better medicines AND higher trade value.

---

## Elixir Refiner (ChemMaster 3000)

Equivalent to the ChemMaster. Separates, formats, and packages finished chemicals.

### What Carries Over Directly
- Load any container (beakers, bottles)
- Separate individual reagents from a mix
- Create **pills** (up to 50u each) — oral delivery, instant if self-administered
- Create **patches** (up to 40u each) — transdermal delivery, penetrates all clothing including EVA suits
- Create **tubes/vials** (up to 30u each) — injectable via syringe
- Name and label products
- Chemistry bag for bulk transport

### Xianzhou Flavor
- Pills → **Pellets** (same mechanic). Xianzhou Cloud Knights use combat pellets for battlefield pain suppression (canon lore).
- Patches → **Poultices** (same mechanic). Applied externally.
- Tubes → **Vials** (same mechanic). For syringe injection or IV drip.
- The Elixir Refiner also packages goods for export — trade-ready elixirs in sealed containers for the Goldstream Guild.

---

## Medicine Categories (Mapped from SS13)

All SS13 medicine recipes carry over. The underlying chemistry doesn't change — only the display names. Here's how the major categories map:

### Healing Medicines

| SS13 Medicine | Xianzhou Name | What It Treats | Trade Value |
|---|---|---|---|
| Cryoxadone | Frostbloom Elixir | Universal healer (requires cold + sleep) | High (universal demand) |
| Epinephrine | Heartfire Extract | Critical stabilization, prevents death | High (military demand) |
| Synthflesh | Flesh-Mend Salve | Instant brute + burn healing (touch) | Medium |
| Atropine | Serpent's Remedy | Anti-toxin, emergency stabilizer | Medium |
| Salbutamol | Breath of Dawn | Respiratory healing | Medium |
| Mannitol | Clearwater Tonic | Brain damage recovery | Medium |
| Multiver | Purging Draught | Toxin purge and treatment | Medium |
| Pentetic Acid | Chelation Elixir | Radiation purge, heavy toxin removal | High (rare, complex) |

### Combat Medicines (High Military Demand)

| SS13 Medicine | Xianzhou Name | Effect | Trade Value |
|---|---|---|---|
| Ephedrine | Tiger's Blood | Stimulant, faster movement, stun resistance | High (Securocrat Guild) |
| Morphine | Dreamdust Tincture | Painkiller, movement in crit | Medium |
| Saline-Glucose | Vitality Infusion | Blood restoration, minor healing | Low-Medium |

### Mara Suppressants (Xianzhou-Specific)

These are new recipes unique to the setting, not mapped from SS13:

| Name | Effect | Ingredients | Trade Value |
|---|---|---|---|
| Anti-Mara Pellet | Suppresses early mara symptoms (tremors, mood swings) | Clearwater Tonic + Purging Draught + Radiant Essence | Very High |
| Mara Stabilizer | Slows mara progression for extended period | Anti-Mara Pellet + Stable Aether + rare herb | Extremely High |
| Emergency Mara Flush | Last resort — purges acute mara episode but causes severe fatigue | Chelation Elixir + concentrated Anti-Mara + stimulant | Priceless |

Mara suppressants are the Alchemy Commission's highest-value export. Every Xianzhou ship needs them. The recipe complexity and rare herb requirements ensure only skilled Alchemists can produce them reliably.

### Poisons and Restricted Substances

Same SS13 toxin recipes exist (cyanide, zombie powder, mindbreaker toxin, etc.) but are contraband aboard the Luofu. The Commissioner investigates if these show up. However, some have legitimate uses:
- Formaldehyde → embalming / preservation
- Chloral Hydrate → surgical anesthetic
- Space Drugs → recreational (legal in some trade destinations, contraband on the Luofu)

Selling contraband at the right destination can be very profitable but risks reputation damage and criminal charges.

---

## Delivery Systems (All Carry Over)

Every SS13 chemical delivery method works unchanged:

| Method | Xianzhou Name | Mechanic | Best For |
|---|---|---|---|
| Pills | Pellets | Oral ingestion, instant self-use, 50u | Standard crew medicine |
| Patches | Poultices | Transdermal, penetrates all clothing, 40u | Field medicine, EVA situations |
| Syringes | Needles | Injection, bypasses mouth, 15u standard | Precise dosing, emergency inject |
| IV Drips | Drip Stands | Continuous feed from bag | Long-term treatment |
| Smoke | Incense | Smoke cloud, touch + inhale delivery | Area healing, area denial |
| Spray | Mist Bottle | Vapor delivery, blocked by helmets | Disinfection, utility |
| Splash | Splash | Touch delivery, thrown beaker | Emergency heal (synthflesh splash) |

---

## Surgery (Medical Operations)

Carries over directly from SS13.

### What Carries Over
- **Operating table + operating computer** — patient lies on table, surgeon operates step-by-step
- **Surgical tools** — scalpel, hemostat, retractor, cautery, circular saw, bone gel, bone setter
- **Surgery types** — organ manipulation, limb repair, implant installation, foreign body removal, etc.
- **Anesthetics** — Tumbledust (from the Yabruh flower, canon lore) replaces standard SS13 anesthetics. Same mechanic — numbs pain during surgery.

### Xianzhou Additions
- **Piercing Gaze acupuncture** — Lingsha's school. Could function as a minor surgery alternative for certain conditions (pain relief, toxin purge, mood stabilization) without full operating table setup. Faster but less effective than full surgery.
- **Mara diagnosis** — new examination procedure. Scan patient for mara markers, determine progression stage, prescribe suppressants. Not a standard SS13 surgery — a new procedure unique to the setting.

---

## Healing Pods (Sleepers / Cryotubes)

### Cryotube Equivalent — Jade Restoration Pod
Same as SS13 cryotubes:
- Patient enters the pod
- Pod is connected to a freezer unit keeping temperature low
- Beakers of Frostbloom Elixir (cryoxadone) loaded into the pod
- Cold + chemical = universal healing while patient sleeps
- Upgradeable: better matter bins → faster cooling, better chem multiplier, faster wake

### Sleeper Equivalent — Treatment Alcove
Same as SS13 sleepers:
- Patient enters
- Machine can inject basic chemicals (painkillers, epinephrine, charcoal)
- Upgradeable: better matter bins → treat heavier damage, better servos → unlock more chemicals

---

## Herb Gardens (Botany)

The Alchemy Commission's herb gardens are functionally identical to SS13 hydroponics, located in the Kangqu biodomes aboard the Luofu.

### What Carries Over Directly
- **Hydroponics trays → Herb Garden Plots**. Plant seeds, add water, add nutrients, wait for growth, harvest.
- **Growth cycle** — each plant has a growth time, lifespan, yield, and potency stat.
- **Nutrients and soil** — fertilizers affect growth speed and yield. Equivalent to SS13 plant nutrients.
- **Weeds and pests** — untended plots develop problems. Weed killer and pest killer from chemistry.
- **Seed extractor** → **Seed Press**. Extract seeds from harvested plants for replanting.
- **Plant analyzer** → **Herb Scanner**. Shows plant stats (potency, yield, growth time, traits).
- **Mutations and crossbreeding** — advanced botany. Mutagen or unstable reagents can mutate plants into new varieties with different properties. Cross-pollination between adjacent trays.
- **Grinding plants** → extracting reagents. Plants contain alchemical reagents extractable with the All-In-One Grinder equivalent.

### Herb Types

**Common Herbs (roundstart seeds):**
- Basic medicinal plants that produce low-value reagents
- Equivalent to SS13 starting seeds (tomatoes, wheat, etc.)
- Sufficient for basic medicine production

**Uncommon Herbs (from Pilot runs):**
- Seeds found at jungle/bio POIs during starskiff expeditions
- Produce reagents needed for mid-tier medicines
- Some have useful traits (higher potency, faster growth)

**Rare Herbs (dangerous POIs only):**
- Found at hostile or deep-space POIs
- Required for Anti-Mara suppressants and premium elixirs
- Very high trade value as raw export (Goldstream Guild buys rare herbs directly)

**Mutant Strains (crossbreeding):**
- Created by skilled Alchemists through botany genetics
- Can produce unique reagent combinations not found in wild herbs
- Highest potency = highest purity medicines = highest trade value

### Kangqu Biodome Layout
- **Main growing room** — 8-12 herb garden plots for regular production
- **Experimental greenhouse** — 4 plots for mutations and crossbreeding
- **Seed vault** — storage for all seed types
- **Processing area** — grinder, seed press, plant analyzer
- **Compost/nutrient station** — fertilizer production

---

## Ranzhi Kitchen (Food Therapy)

The Ranzhi School of food therapy — cooking as medicine. Functionally equivalent to SS13's kitchen but with the added mechanic that food provides buff effects AND sells as trade goods.

### What Carries Over Directly
- **Kitchen equipment** — microwave, grill, oven, all-in-one grinder, kitchen knife
- **Food recipes** — combine ingredients to create dishes
- **Nutriment** — food provides nutrition to prevent starvation
- **Reagent-infused food** — dishes can contain alchemical reagents (healing, buffs, etc.)
- **Fridge and food storage** — same

### Food Therapy (Xianzhou Addition)

Food therapy dishes provide temporary buffs when eaten. This is the Ranzhi School's specialty — "medicine is food, and vice versa."

| Dish Type | Buff Effect | Trade Value | Ingredients |
|---|---|---|---|
| **Vitality Soup** | Slow health regeneration for 5 minutes | Medium | Common herbs + meat + spring water |
| **Tiger Bone Broth** | Increased melee damage for 5 minutes | High | Uncommon herbs + rare meat + spices |
| **Clearhead Tea** | Mara resistance buff for 10 minutes | Very High | Rare herbs + spring water + honey |
| **Ironblood Congee** | Blood regeneration + toxin resistance | Medium | Iron-rich herbs + grain + medicinal mushrooms |
| **Nine-Square Hotpot** | Multiple small buffs (Jiaoqiu's invention) | High | 9 different herb/ingredient types combined |

Food therapy is less potent than direct medicine but easier to produce and more pleasant to consume. It's also a reliable trade good — every destination wants food.

---

## Cauldron Master vs. Alchemist — Role Split

### Cauldron Master (Head — CMO + Head Chemist + Head Botanist)
- **Advanced medicine** — only the Cauldron Master can brew the most complex recipes (Mara Stabilizer, Chelation Elixir, advanced food therapy)
- **Surgery** — handles serious surgical cases (organ repair, mara diagnosis, complex procedures)
- **Quality control** — licenses medicines for export, ensures purity standards for trade goods
- **Research requests** — tells Artisanship which Elixir Science schematics to prioritize
- **Herb garden management** — oversees crossbreeding program, manages rare seed stock
- **Piercing Gaze practice** — acupuncture treatments (if implemented)

### Alchemist (Worker — Chemist + Doctor + Botanist + Cook)
- **Medicine production** — brew standard medicines, fill orders for crew and trade
- **Patient treatment** — basic medical care, first aid, healing pod operation, simple surgery
- **Herb farming** — plant, tend, harvest herbs in the biodome gardens
- **Food therapy** — prepare dishes in the Ranzhi Kitchen
- **Reagent grinding** — process raw herbs and materials into base reagents
- **Purity work** — use the Purity Analyzer to improve product quality

At low pop, the Cauldron Master does everything. At higher pop, Alchemists handle volume production and routine medical care while the Cauldron Master focuses on advanced recipes, surgery, and quality oversight.

---

## Cross-Department Dependencies

### From Artisanship
- **Machine upgrades** — Tier 2+ Cauldrons, Healing Pods, Crucibles make alchemy dramatically better (components researched by Divination, built and installed by Artisanship)
- **Materials** — some advanced recipes require refined materials (metals, crystals) from Artisanship
- **Construction** — new garden plots, expanded labs, additional healing pods

### From Divination
- **Elixir Science research** — Divination's Sapientia Academe unlocks new Alchemy recipes and purity improvements via the Elixir Science branch
- **New recipes** — deep scans of certain POIs may reveal ancient elixir formulas
- **Demand forecasting** — Divination predictions tell Alchemy which medicines will sell best at the next destination

### From Sky-Faring (Pilots)
- **Rare herbs** — found at jungle/bio POIs, essential for high-value medicines
- **Biological samples** — alien compounds, unique organisms from exploration
- **Trade contracts** — Goldstream Guild orders drive what to produce

### To Other Departments
- **Crew health** — every department depends on Alchemy for healing
- **Combat medicine** — Cloud Knights need pellets, poultices, and stimulants for dangerous missions
- **Anti-Mara** — the entire crew needs mara monitoring and suppressants
- **Trade goods** — Goldstream Guild pharmaceutical exports are a major revenue stream
- **Food** — the entire crew needs to eat, and food therapy buffs benefit everyone

---

## Round Start Workflow

1. **Check herb gardens** — water any dry plots, plant starting seeds if empty, start growth cycles.
2. **Stock the treatment rooms** — verify Healing Pods have elixir loaded, check medical supply levels.
3. **Initial medicine batch** — brew a baseline stock of common medicines (Heartfire Extract, Flesh-Mend Salve, basic healing pellets).
4. **Set up the Cauldron** — calibrate temperature, fill buffer tanks, run a test reaction to verify equipment.
5. **Check crew health** — scan arriving crew for existing conditions, distribute basic medical supplies.
6. **Review trade contracts** — check if any Goldstream Guild orders need pharmaceutical products.
7. **Request from Artisanship** — put in early request for Cauldron upgrade (Tier 2 minimum, Tier 4 ideal).
8. **Plan herb production** — based on available seeds and trade demand, decide what to grow this round.
