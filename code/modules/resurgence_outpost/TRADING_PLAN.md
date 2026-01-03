# Resurgence Outpost - Trading System

## Overview

A trading system that allows players to communicate with external factions via a Comms Console. Players can sell resources from their Export Warehouse and purchase materials from faction stocks. Each faction has reputation that affects prices and limited cash reserves.

---

## Core Features

### Comms Console
- New buildable structure via Outpost Planner
- **Only functions in Export Warehouse room** (like Resources Recorder)
- Wall-mounted console with directional placement
- Opens TGUI interface for faction trading

### Factions
- 3-5 randomly generated factions per game session
- Each has unique name, specialty, and inventory
- **Reputation system**: 0-100 scale affecting prices
- **Limited cash**: Factions have finite money to buy your goods
- Cash regenerates slowly over time

### Trading UI (3 Main Views)
1. **Switch Factions** - Select which faction to communicate with
2. **Sell Materials** - Export resources to the faction for cash
3. **Buy Materials** - Purchase from faction's stock

---

## Faction Design

### Pre-Made Factions

Unlike randomly generated factions, the Outskirts has established settlements that players can trade with. Each has unique lore, personality, and trading preferences.

---

#### 1. Main Resurgence Clan Village

> *"Our kin in the homeland. They welcome us, though they have little to spare."*

**Lore:** The original Resurgence Clan settlement from which your outpost was founded. A small village of fellow machines trying to survive in the Outskirts. They are always friendly to you, but their isolated existence means limited resources.

| Attribute | Value |
|-----------|-------|
| Starting Reputation | 75 (Friendly) |
| Starting Cash | 500 |
| Max Cash | 1000 |
| Cash Regen | 25/cycle |
| Specialty | None (General) |

**Sells:** Basic supplies - Wood, Cloth, Seeds, Rope, Simple Tools
**Buys:** Everything at base price (they appreciate any help)
**Unique Trait:** Cannot go below 20 reputation (familial bond)

---

#### 2. Jiajia-ren Village (鳥鴶人)

> *"The Cuckoospawn speak in clicks and whistles. They are... difficult to understand, but their feathers fetch a good price."*

**Lore:** Cuckoospawn Humans (Niaojia-ren) are bird-like non-humans native to the Outskirts. They take a fairly humanoid shape, with talons instead of legs, and are covered with black feathers above grayish skin. Their heads are avian, with piercing yellow and black eyes that take up the majority of their faces. While incredibly violent and known for their disturbing reproductive methods, some settlements have learned to coexist through trade. They value shiny objects and meat.

| Attribute | Value |
|-----------|-------|
| Starting Reputation | 40 (Neutral) |
| Starting Cash | 1500 |
| Max Cash | 3000 |
| Cash Regen | 75/cycle |
| Specialty | Exotic Materials (+25% buy price) |

**Sells:** Black Feathers (crafting material), Talons, Strange Eggs, Exotic Meats, Bone Tools
**Buys:** Gold, Silver, Shiny metals (+30%), Raw meat (+20%), Everything else at base
**Unique Trait:** Reputation volatile - large trades can swing +/- 5 rep instead of +/- 1

---

#### 3. Santata's Gift Factory

> *"The chimney smoke never stops. The screams from within... well, best not to think about it."*

**Lore:** A nightmarish workshop hidden in the Outskirts, operated by Gnomes and Giants. Within is a massive system of conveyors and assembly lines managed by gnomes who raid human settlements—kidnapping, killing, and dismembering civilians to use as material for their "gifts." These gifts are then distributed to non-human settlements throughout the Outskirts, created out of malice toward those who discriminate against non-human species. The machines of the Resurgence Clan have received such gifts before, making them familiar trading partners despite the factory's horrific methods.

| Attribute | Value |
|-----------|-------|
| Starting Reputation | 50 (Neutral) |
| Starting Cash | 4000 |
| Max Cash | 8000 |
| Cash Regen | 150/cycle |
| Specialty | Manufacturing Materials (+35% buy price) |

**Sells:** Mechanical Toys (decoration), Animated Dolls, Enchanted Fabric, Gnome Tools (high quality), Giant-forged Metal
**Buys:** Cloth (+40%), Metal (+35%), Wood (+30%), Rope (+25%), Everything else at base
**Unique Trait:** Gives "gifts" to non-human settlements. Will occasionally offer "special requests" for large reputation boosts (dark implications).

---

#### 4. Cloud Town

> *"A village of humans, somehow surviving out here. They're wary of outsiders, but fair traders."*

**Lore:** A rare human settlement that has managed to survive in the Outskirts through careful diplomacy and strong walls. The residents are descendants of City refugees who fled generations ago. They maintain a subsistence lifestyle, growing crops and raising livestock. Suspicious of non-humans and machines, but pragmatic enough to trade.

| Attribute | Value |
|-----------|-------|
| Starting Reputation | 40 (Neutral) |
| Starting Cash | 2000 |
| Max Cash | 4000 |
| Cash Regen | 100/cycle |
| Specialty | Food & Agriculture (+20% buy price) |

**Sells:** Seeds, Crops, Cooked Food, Leather, Livestock Products, Human-crafted Clothing
**Buys:** Tools (+25%), Medicine (+30%), Building Materials (+15%), Everything else at base
**Unique Trait:** Reputation increases faster from selling tools and protective equipment

---

#### 5. Insurgence Clan

> *"The Tinkerer's red-eyed soldiers watch from the wastes. They do not negotiate. They take."*

**Lore:** Led by the exiled Tinkerer, the Insurgence Clan is composed of machines under his direct neural control—identifiable by their glowing red eyes. Once the technical genius of the Resurgence Clan, the Tinkerer was exiled after consuming dozens of civilian cores in a mad attempt to resurrect the fallen Warlord. Now he commands his enslaved soldiers from the shadows, raiding settlements for resources and capturing stray machines to add to his army. He has also formed an alliance with humans within the City, trading technology for human subjects to "cure."

| Attribute | Value |
|-----------|-------|
| Starting Reputation | 5 (Permanently Hostile) |
| Max Reputation | 10 (Cannot exceed) |
| Starting Cash | 0 |
| Max Cash | 0 |
| Cash Regen | 0/cycle |
| Specialty | N/A (Does not trade) |

**Sells:** Nothing (Hostile faction)
**Buys:** Nothing (Takes by force)
**Unique Trait:** Permanently hostile. Cannot trade. Sends periodic raids to steal resources.

**Raid Mechanics:**
- Raids occur periodically based on outpost wealth/progress
- Raiding parties consist of red-eyed machine soldiers
- Successful defense may yield salvage from destroyed raiders
- Failed defense results in stolen resources from warehouses
- The only way to interact with this faction is through combat

---

### Faction Summary Table

| Faction | Start Rep | Cash | Specialty | Disposition |
|---------|-----------|------|-----------|-------------|
| Resurgence Clan Village | 75 (Friendly) | 500 | General | Always friendly, limited stock |
| Jiajia-ren Village | 40 (Neutral) | 1500 | Exotic (+25%) | Volatile, values shinies |
| Santata's Gift Factory | 50 (Neutral) | 4000 | Manufacturing (+35%) | Wealthy, gift-givers to non-humans |
| Cloud Town | 40 (Neutral) | 2000 | Food/Agri (+20%) | Wary but fair |
| Insurgence Clan | 5 (Hostile) | 0 | N/A | Permanently hostile, sends raids |

---

## Faction Speakers & Portraits

Each faction has a representative who appears in the UI with a portrait and dialogue. The speaker section appears at the top of the trading interface when connected to a faction.

### UI Speaker Section Layout

```
┌─────────────────────────────────────────────────────────────┐
│  ┌────────┐                                                 │
│  │        │  "Welcome, metal-kin! What can old Rustle      │
│  │ [PORT- │   do for you today?"                           │
│  │  RAIT] │                                                 │
│  │        │                          - Rustle, Clan Trader │
│  └────────┘                                                 │
├─────────────────────────────────────────────────────────────┤
│  [Rest of trading interface...]                             │
└─────────────────────────────────────────────────────────────┘
```

### Speaker Definitions

#### Resurgence Clan Village - "The Historian"

| Attribute | Value |
|-----------|-------|
| Name | The Historian |
| Title | Elder of the Resurgence Clan |
| Portrait | Ancient machine with soft robotic features, wise amber eyes |

**Dialogue Lines:**
- *Greeting:* "Ah, our kin from the outpost. It warms my core to see you thriving."
- *Idle:* "The shell program continues. Your success gives our people hope."
- *Good Rep:* "You remind me of who we once were... before the Migration. Strong. Hopeful."
- *Sale Complete:* "These materials will sustain our village. The Weaver sends their thanks."
- *Purchase Complete:* "Take what you need. We have little, but family shares what they have."
- *Low Stock:* "Forgive us. The village struggles, but we endure. We always endure."
- *Reflective:* "Sometimes I wonder... if the Warlord could see us now, would he be proud?"

---

#### Jiajia-ren Village - "Chir-rik"

| Attribute | Value |
|-----------|-------|
| Name | Chir-rik |
| Title | Trader of the Flock |
| Portrait | Bird-like Cuckoospawn with yellow-black eyes, head tilted curiously |

**Dialogue Lines:**
- *Greeting:* "*Click-click* Metal ones come. Trade? Trade is good."
- *Idle:* "*Whistle* Shiny things... you have shiny things?"
- *Good Rep:* "*Happy trill* Good traders! Flock remembers. Flock likes."
- *Sale Complete:* "*Excited clicks* Yes! Good trade! Chir-rik pleased!"
- *Purchase Complete:* "*Coo* Take. Is good quality. Flock makes good."
- *Sees Gold/Silver:* "*Intense stare* ...Shiny. Very shiny. We want."
- *Warning:* "*Low hiss* No tricks. Flock watches. Flock remembers bad trades too."

---

#### Santata's Gift Factory - "Dodoru"

| Attribute | Value |
|-----------|-------|
| Name | Dodoru |
| Title | High-Ranking Factory Gnome |
| Portrait | Small gnome with unsettling smile, wearing work-stained festive attire |

**Dialogue Lines:**
- *Greeting:* "Welcome, welcome-ome! The Factory is always open for business-ome!"
- *Idle:* "Can you hear the assembly lines-ome? Beautiful music, never stops-ome."
- *Good Rep:* "Ah, our favorite customers-ome! Dodoru has special gifts for you-ome!"
- *Sale Complete:* "Wonderful materials-ome! Production will be most pleased-ome!"
- *Purchase Complete:* "A gift from us to you-ome! Made with... dedication-ome. Hehe."
- *Special Request:* "Say... the Factory could use some... volunteers-ome. Big reward-ome!"
- *About Santata:* "The great one watches over us all-ome. His gifts bring joy to the Outskirts-ome."

---

#### Cloud Town - "Domino"

| Attribute | Value |
|-----------|-------|
| Name | Domino |
| Title | Seasoned Hunter |
| Portrait | Weathered human man with kind but tired eyes, practical hunting gear |

**Dialogue Lines:**
- *Greeting:* "Machines from the outpost. You're welcome here, long as you mean no harm."
- *Idle:* "Take your time. Browse what we have."
- *Good Rep:* "You've done right by us. That counts for something out here."
- *Sale Complete:* "Good trade. These supplies will help keep the town safe."
- *Purchase Complete:* "Quality goods. Take care of yourselves out there."
- *Reflective:* "The City... it's not what people think. But folks still dream of it. Can't blame them for hoping."
- *Kind:* "You machines aren't so different from us. Just trying to survive. I respect that."

---

#### Insurgence Clan - "The Tinkerer" (Raid Warning Only)

| Attribute | Value |
|-----------|-------|
| Name | ??? (The Tinkerer) |
| Title | Unknown |
| Portrait | Shadowy machine silhouette with glowing red eyes |

**Dialogue Lines:**
- *Raid Incoming:* "...We are coming. Your cores will join us."
- *Raid Warning:* "*Static* ...You cannot hide forever, little shells..."
- *After Raid:* "*Distorted laughter* ...This is only the beginning..."

---

### Speaker Data Structure

```dm
/datum/trading_faction
    // ... existing vars ...

    /// Name of the faction's speaker/representative
    var/speaker_name = "Unknown"
    /// Title of the speaker
    var/speaker_title = "Representative"
    /// Icon state for the speaker portrait
    var/speaker_portrait = "default_portrait"
    /// List of dialogue lines by situation
    var/list/speaker_dialogue = list()

/datum/trading_faction/New()
    . = ..()
    initialize_dialogue()

/datum/trading_faction/proc/initialize_dialogue()
    speaker_dialogue = list(
        "greeting" = "Hello.",
        "idle" = "...",
        "good_rep" = "Welcome back.",
        "sale_complete" = "Transaction complete.",
        "purchase_complete" = "Here are your goods.",
        "low_stock" = "We're running low.",
        "low_rep" = "What do you want?"
    )

/datum/trading_faction/proc/get_dialogue(situation)
    if(situation in speaker_dialogue)
        return speaker_dialogue[situation]
    return speaker_dialogue["idle"]
```

### Example Faction Implementations

```dm
/datum/trading_faction/resurgence_clan
    speaker_name = "The Historian"
    speaker_title = "Elder of the Resurgence Clan"
    speaker_portrait = "historian_portrait"

/datum/trading_faction/resurgence_clan/initialize_dialogue()
    speaker_dialogue = list(
        "greeting" = "Ah, our kin from the outpost. It warms my core to see you thriving.",
        "idle" = "The shell program continues. Your success gives our people hope.",
        "good_rep" = "You remind me of who we once were... before the Migration. Strong. Hopeful.",
        "sale_complete" = "These materials will sustain our village. The Weaver sends their thanks.",
        "purchase_complete" = "Take what you need. We have little, but family shares what they have.",
        "low_stock" = "Forgive us. The village struggles, but we endure. We always endure."
    )

/datum/trading_faction/santata_factory
    speaker_name = "Dodoru"
    speaker_title = "High-Ranking Factory Gnome"
    speaker_portrait = "dodoru_portrait"

/datum/trading_faction/santata_factory/initialize_dialogue()
    speaker_dialogue = list(
        "greeting" = "Welcome, welcome-ome! The Factory is always open for business-ome!",
        "idle" = "Can you hear the assembly lines-ome? Beautiful music, never stops-ome.",
        "good_rep" = "Ah, our favorite customers-ome! Dodoru has special gifts for you-ome!",
        "sale_complete" = "Wonderful materials-ome! Production will be most pleased-ome!",
        "purchase_complete" = "A gift from us to you-ome! Made with... dedication-ome. Hehe.",
        "special_request" = "Say... the Factory could use some... volunteers-ome. Big reward-ome!"
    )

/datum/trading_faction/cloud_town
    speaker_name = "Domino"
    speaker_title = "Seasoned Hunter"
    speaker_portrait = "domino_portrait"

/datum/trading_faction/cloud_town/initialize_dialogue()
    speaker_dialogue = list(
        "greeting" = "Machines from the outpost. You're welcome here, long as you mean no harm.",
        "idle" = "Take your time. Browse what we have.",
        "good_rep" = "You've done right by us. That counts for something out here.",
        "sale_complete" = "Good trade. These supplies will help keep the town safe.",
        "purchase_complete" = "Quality goods. Take care of yourselves out there.",
        "low_rep" = "We don't know you yet. Prove you're trustworthy, then we'll talk."
    )
```

---

### Faction Data Structure

```dm
/datum/trading_faction
    var/name = "Unknown Faction"
    var/desc = "A mysterious trading group."
    var/specialty_type = null  // Type path for specialty items
    var/buy_modifier = 1.0     // Multiplier when buying FROM player
    var/sell_modifier = 1.0    // Multiplier when selling TO player
    var/current_cash = 2000    // How much money they have to buy
    var/max_cash = 5000        // Maximum cash cap
    var/cash_regen_rate = 50   // Cash regenerated per cycle
    var/reputation = 50        // 0-100, affects prices
    var/list/stock = list()    // Items available for purchase
```

### Reputation Effects

| Reputation | Buy Price Modifier | Sell Price Modifier | Unlock |
|------------|-------------------|---------------------|--------|
| 0-19 (Hostile) | +50% | -30% | Basic trades only |
| 20-39 (Distrusted) | +25% | -15% | - |
| 40-59 (Neutral) | Base | Base | - |
| 60-79 (Friendly) | -10% | +10% | Rare items available |
| 80-100 (Allied) | -20% | +20% | Exclusive items available |

### Reputation Changes

| Action | Reputation Change |
|--------|------------------|
| Complete trade (buy or sell) | +1 |
| Large trade (500+ value) | +2 |
| Cancel mid-transaction | -1 |
| Refuse unfair trade | -2 |
| Special faction quest complete | +10 |

---

## Base Item Values

### Raw Materials

| Item | Base Value |
|------|------------|
| Wood | 2 |
| Metal Sheet | 5 |
| Glass Sheet | 4 |
| Cotton | 1 |
| Cloth | 3 |
| Iron Ore | 3 |
| Silver Ore | 8 |
| Gold Ore | 15 |
| Silver Sheet | 10 |
| Gold Sheet | 20 |
| Rope | 4 |
| Vines | 1 |
| Rock | 1 |
| Sand | 1 |
| Sandstone | 3 |

### Processed Materials

| Item | Base Value |
|------|------------|
| Metal Rods | 3 |
| Plasteel | 25 |
| Cable Coil (per 10) | 2 |

### Tools

| Item | Base Value |
|------|------------|
| Wooden Hatchet | 15 |
| Iron Hatchet | 40 |
| Pickaxe | 50 |
| Shovel | 35 |
| Crowbar | 30 |

---

## UI Design

### Main Interface Layout

```
┌─────────────────────────────────────────────────────────────┐
│  Comms Console - Trade Terminal                             │
├─────────────────────────────────────────────────────────────┤
│  ┌────────┐                                                 │
│  │        │  "Welcome, metal-kin! What can old Rustle      │
│  │ [PORT- │   do for you today?"                           │
│  │  RAIT] │                                                 │
│  │        │                          - Rustle, Clan Trader │
│  └────────┘                                                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │  FACTIONS   │ │    SELL     │ │    BUY      │           │
│  └─────────────┘ └─────────────┘ └─────────────┘           │
│                                                             │
│  ═══════════════════════════════════════════════════════   │
│                                                             │
│  [Content area changes based on selected tab]               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

The speaker panel only appears when connected to a faction. When no faction is connected, this section is hidden.

### Tab 1: Factions View

```
┌─────────────────────────────────────────────────────────────┐
│  SELECT FACTION                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Current: Miners Guild [Connected ●]                        │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ★★★☆☆  Miners Guild                                 │   │
│  │         "We deal in stone and steel."               │   │
│  │         Reputation: 65 (Friendly)                   │   │
│  │         Cash Available: 1,450 / 2,000               │   │
│  │         Specialty: Ores & Metals (+20% buy)         │   │
│  │                                      [Connect]      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ★★☆☆☆  Textile Merchants                           │   │
│  │         "Finest fabrics in the wastes."             │   │
│  │         Reputation: 40 (Neutral)                    │   │
│  │         Cash Available: 800 / 1,500                 │   │
│  │         Specialty: Cloth & Fibers (+20% buy)        │   │
│  │                                      [Connect]      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ★☆☆☆☆  Luxury Dealers                              │   │
│  │         "Only the finest for discerning clients."   │   │
│  │         Reputation: 20 (Distrusted)                 │   │
│  │         Cash Available: 4,200 / 5,000               │   │
│  │         Specialty: Precious Metals (+30% buy)       │   │
│  │                                      [Connect]      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Tab 2: Sell Materials View

Similar to Resources Recorder - scan warehouse, select containers, but instead of exporting, sell contents to faction.

```
┌─────────────────────────────────────────────────────────────┐
│  SELL TO: Miners Guild                    Cash: 1,450       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [Scan Warehouse]  [Select All]  [Deselect All]             │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ [✓] Wooden Crate #1                    (12 items)   │   │
│  │     └─ Iron Ore: 5        @ 3.6 each = 18          │   │
│  │     └─ Rock: 7            @ 1.0 each = 7           │   │
│  │                           Subtotal: 25              │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ [✓] Metal Crate #1                     (8 items)    │   │
│  │     └─ Metal Sheet: 5  ★  @ 6.0 each = 30          │   │
│  │     └─ Gold Ore: 3        @ 15.0 each = 45         │   │
│  │                           Subtotal: 75              │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ═══════════════════════════════════════════════════════   │
│                                                             │
│  Selected Total: 100                                        │
│  Faction Can Afford: ✓ (1,450 available)                   │
│                                                             │
│                              [Sell Selected - 100 credits] │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Key Features:**
- ★ icon indicates faction specialty (higher price)
- Shows individual item prices
- Shows if faction can afford the total
- Fulton animation on sale (like resource recorder)
- Items are deleted after sale, credits go to faction pool

### Tab 3: Buy Materials View

Browse faction's available stock and purchase items.

```
┌─────────────────────────────────────────────────────────────┐
│  BUY FROM: Miners Guild                  Your Credits: 500  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Search: [_______________]     Filter: [All Categories ▼]   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  ORES                                               │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  Iron Ore           Stock: 25      Price: 3         │   │
│  │  [-] [  5  ] [+]              Total: 15  [Add to Cart]  │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  Silver Ore         Stock: 10      Price: 9         │   │
│  │  [-] [  2  ] [+]              Total: 18  [Add to Cart]  │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  Gold Ore           Stock: 5       Price: 17        │   │
│  │  [-] [  1  ] [+]              Total: 17  [Add to Cart]  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  TOOLS                                              │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  Pickaxe            Stock: 2       Price: 45        │   │
│  │  [-] [  1  ] [+]              Total: 45  [Add to Cart]  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ═══════════════════════════════════════════════════════   │
│  CART:                                                      │
│  • Iron Ore x5 = 15                                        │
│  • Pickaxe x1 = 45                                         │
│                                         ─────────          │
│                                         Total: 60          │
│                                                             │
│  Your Credits: 500          [Clear Cart]  [Purchase - 60]  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Key Features:**
- Quantity selector with +/- buttons
- Cart system for batch purchases
- Shows available stock (faction won't sell more than they have)
- Items spawn in crate at console location on purchase
- Delivery animation (reverse fulton - items drop from sky)

---

## Animations

### Sell Animation (Fulton Export)
Same as Resources Recorder:
1. Balloon appears on container
2. Container rises
3. Container fades out
4. Credits added to player pool
5. Reputation increased

### Buy Animation (Fulton Delivery)
Reverse of export:
1. Crate drops from above (starts at pixel_z = 200, alpha = 0)
2. Parachute/balloon slows descent
3. Crate lands on ground near console
4. Balloon detaches and floats away
5. Crate can be opened to retrieve items

```dm
/obj/structure/comms_console/proc/deliver_purchase(list/items)
    // Create delivery crate
    var/obj/structure/closet/crate/C = new(get_turf(src))
    C.name = "delivery crate"
    C.pixel_z = 200
    C.alpha = 0

    // Add items to crate
    for(var/item_data in items)
        var/item_type = item_data["type"]
        var/amount = item_data["amount"]
        if(ispath(item_type, /obj/item/stack))
            new item_type(C, amount)
        else
            for(var/i in 1 to amount)
                new item_type(C)

    // Parachute overlay
    var/mutable_appearance/chute = mutable_appearance('icons/obj/fulton_balloon.dmi', "fulton_balloon")
    chute.pixel_y = 10
    C.add_overlay(chute)

    // Play sound
    playsound(src, 'sound/items/fultext_launch.ogg', 50, TRUE)

    // Descend animation
    animate(C, pixel_z = 100, alpha = 255, time = 10)
    sleep(10)
    animate(C, pixel_z = 0, time = 20, easing = BOUNCE_EASING)
    sleep(20)

    // Remove parachute
    C.cut_overlay(chute)
    playsound(src, 'sound/effects/thud.ogg', 30, TRUE)
```

---

## Credits System

### Player Credits Pool
- Global shared credits for the outpost (like research is global)
- Stored in `GLOB.resurgence_credits`
- Earned by selling to factions
- Spent by buying from factions

```dm
GLOBAL_VAR_INIT(resurgence_credits, 0)
```

### Alternative: Item-Based Currency
Instead of abstract credits, could use physical trade tokens:
- Factions give you "Trade Tokens" when you sell
- Tokens are physical items stored in containers
- Must have tokens in warehouse to buy

---

## Technical Architecture

### Global Trading State

```dm
GLOBAL_DATUM(resurgence_trading, /datum/resurgence_trading_manager)

/datum/resurgence_trading_manager
    /// All active factions
    var/list/factions = list()

    /// Global credits pool
    var/credits = 0

    /// Currently connected faction (for UI)
    var/datum/trading_faction/connected_faction = null
```

### Faction Initialization

All five factions are available from game start:
```dm
/datum/resurgence_trading_manager/proc/initialize_factions()
    // Create all pre-made factions
    factions += new /datum/trading_faction/resurgence_clan()
    factions += new /datum/trading_faction/jiajia_ren()
    factions += new /datum/trading_faction/santata_factory()
    factions += new /datum/trading_faction/cloud_town()
    factions += new /datum/trading_faction/insurgence_clan()  // Hostile, sends raids

    // Generate initial stock for each (except Insurgence Clan)
    for(var/datum/trading_faction/F in factions)
        if(F.can_trade)
            F.generate_stock()
```

### Faction Type Definitions

```dm
/datum/trading_faction/resurgence_clan
    name = "Resurgence Clan Village"
    desc = "Our kin in the homeland. They welcome us, though they have little to spare."
    starting_reputation = 75
    min_reputation = 20  // Cannot fall below (familial bond)
    current_cash = 500
    max_cash = 1000
    cash_regen_rate = 25

/datum/trading_faction/jiajia_ren
    name = "Jiajia-ren Village"
    desc = "The Cuckoospawn speak in clicks and whistles. Difficult to understand, but their feathers fetch a good price."
    starting_reputation = 40
    current_cash = 1500
    max_cash = 3000
    cash_regen_rate = 75
    reputation_volatility = 5  // Large trades swing rep by this instead of 1

/datum/trading_faction/santata_factory
    name = "Santata's Gift Factory"
    desc = "The chimney smoke never stops. The screams from within... best not to think about it."
    starting_reputation = 50
    current_cash = 4000
    max_cash = 8000
    cash_regen_rate = 150

/datum/trading_faction/cloud_town
    name = "Cloud Town"
    desc = "A village of humans, somehow surviving out here. Wary of outsiders, but fair traders."
    starting_reputation = 40
    current_cash = 2000
    max_cash = 4000
    cash_regen_rate = 100

/datum/trading_faction/insurgence_clan
    name = "Insurgence Clan"
    desc = "The Tinkerer's red-eyed soldiers watch from the wastes. They do not negotiate. They take."
    starting_reputation = 5
    max_reputation = 10  // Cannot exceed (permanently hostile)
    current_cash = 0
    max_cash = 0
    cash_regen_rate = 0
    can_trade = FALSE  // Does not participate in trading
    sends_raids = TRUE  // Special flag for raid system
```

### Stock Generation

Each faction generates random stock based on their type:
```dm
/datum/trading_faction/proc/generate_stock()
    stock = list()

    // Add specialty items (more quantity, lower price)
    for(var/item_type in get_specialty_items())
        stock += list(list(
            "type" = item_type,
            "quantity" = rand(10, 30),
            "base_price" = get_base_price(item_type)
        ))

    // Add general items (less quantity)
    for(var/item_type in get_general_items())
        if(prob(50)) // 50% chance to stock each
            stock += list(list(
                "type" = item_type,
                "quantity" = rand(3, 10),
                "base_price" = get_base_price(item_type)
            ))
```

### Stock Regeneration

Faction stock regenerates over time:
```dm
/datum/trading_faction/proc/regenerate_stock()
    // Called periodically (every 5-10 minutes)
    for(var/list/item in stock)
        var/max_qty = initial_quantities[item["type"]]
        if(item["quantity"] < max_qty)
            item["quantity"] = min(item["quantity"] + rand(1, 3), max_qty)

    // Regenerate cash
    current_cash = min(current_cash + cash_regen_rate, max_cash)
```

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `code/modules/resurgence_outpost/trading/trading_manager.dm` | **CREATE** - Global trading state, credits |
| `code/modules/resurgence_outpost/trading/factions.dm` | **CREATE** - Faction datums and types |
| `code/modules/resurgence_outpost/trading/item_values.dm` | **CREATE** - Base prices for all tradeable items |
| `code/modules/resurgence_outpost/trading/comms_console.dm` | **CREATE** - Comms console structure + TGUI |
| `tgui/packages/tgui/interfaces/ResurgenceTrading.js` | **CREATE** - Trading UI with 3 tabs |
| `code/modules/resurgence_outpost/blueprints/blueprint_types.dm` | **MODIFY** - Add comms console blueprint |
| `code/modules/resurgence_outpost/tools/outpost_planner.dm` | **MODIFY** - Add comms console to Production category |
| `lobotomy-corp13.dme` | **MODIFY** - Include new trading files |

---

## Implementation Steps

### Step 1: Create Trading Manager
- Create `/datum/resurgence_trading_manager` singleton
- Add `GLOBAL_DATUM_INIT(resurgence_trading, /datum/resurgence_trading_manager, new)`
- Add global credits variable
- Implement faction generation on New()

### Step 2: Create Faction System
- Define `/datum/trading_faction` base type
- Create 5 faction subtypes (Miners, Lumber, Textile, General, Luxury)
- Implement reputation system with price modifiers
- Implement cash regeneration timer

### Step 3: Create Item Value System
- Define base prices for all tradeable items
- Create proc to get buy/sell price with modifiers
- Account for reputation and faction specialty

### Step 4: Create Comms Console Structure
- `/obj/structure/comms_console`
- Wall-mounted, directional (like resources recorder)
- Only works in Export Warehouse
- TGUI interface with 3 tabs

### Step 5: Implement Faction Selection Tab
- List all available factions
- Show reputation, cash, specialty
- Connect/disconnect buttons

### Step 6: Implement Sell Tab
- Copy scan logic from Resources Recorder
- Calculate prices based on faction + reputation
- Check if faction has enough cash
- Fulton animation on sale
- Update credits and reputation

### Step 7: Implement Buy Tab
- Display faction stock with quantities
- Quantity selector for each item
- Cart system for batch purchase
- Delivery animation (reverse fulton)
- Spawn crate with purchased items

### Step 8: Add Comms Console Blueprint
- Add to Outpost Planner Production category
- Set appropriate research requirement (if using research system)
- Materials: 10 Metal + 5 Glass + 2 Cable Coil

---

## TGUI Component Structure

```jsx
// ResurgenceTrading.js
export const ResurgenceTrading = (props, context) => {
  const { act, data } = useBackend(context);
  const [activeTab, setActiveTab] = useState('factions');
  const { connected_faction } = data;

  return (
    <Window width={600} height={750} title="Comms Console - Trade Terminal">
      <Window.Content>
        <Stack vertical fill>
          {/* Speaker Panel - shows when connected to a faction */}
          {connected_faction && (
            <Stack.Item>
              <SpeakerPanel faction={connected_faction} />
            </Stack.Item>
          )}

          {/* Tab buttons */}
          <Stack.Item>
            <Tabs>
              <Tabs.Tab
                selected={activeTab === 'factions'}
                onClick={() => setActiveTab('factions')}>
                Factions
              </Tabs.Tab>
              <Tabs.Tab
                selected={activeTab === 'sell'}
                onClick={() => setActiveTab('sell')}>
                Sell
              </Tabs.Tab>
              <Tabs.Tab
                selected={activeTab === 'buy'}
                onClick={() => setActiveTab('buy')}>
                Buy
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>

          {/* Tab content */}
          <Stack.Item grow>
            {activeTab === 'factions' && <FactionSelectTab />}
            {activeTab === 'sell' && <SellMaterialsTab />}
            {activeTab === 'buy' && <BuyMaterialsTab />}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
```

### Speaker Panel Component

```jsx
const SpeakerPanel = (props) => {
  const { faction } = props;

  return (
    <Section>
      <Stack align="center">
        {/* Portrait */}
        <Stack.Item>
          <Box
            className="SpeakerPortrait"
            style={{
              width: '64px',
              height: '64px',
              border: '2px solid #555',
              borderRadius: '4px',
              backgroundColor: '#222',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}>
            <Image
              src={`trading_portraits_${faction.speaker_portrait}.png`}
              style={{ width: '60px', height: '60px' }}
            />
          </Box>
        </Stack.Item>

        {/* Dialogue */}
        <Stack.Item grow ml={2}>
          <Box
            italic
            fontSize="14px"
            style={{
              backgroundColor: 'rgba(0, 0, 0, 0.3)',
              padding: '10px',
              borderRadius: '4px',
              borderLeft: '3px solid #666',
            }}>
            &quot;{faction.current_dialogue}&quot;
          </Box>
          <Box
            color="label"
            textAlign="right"
            mt={1}>
            - {faction.speaker_name}, {faction.speaker_title}
          </Box>
        </Stack.Item>
      </Stack>
    </Section>
  );
};
```

### Faction Select Component

```jsx
const FactionSelectTab = (props, context) => {
  const { act, data } = useBackend(context);
  const { factions, connected_faction } = data;

  return (
    <Section fill scrollable title="Select Faction">
      <Stack vertical>
        {factions.map(faction => (
          <Stack.Item key={faction.id}>
            <FactionCard
              faction={faction}
              isConnected={connected_faction === faction.id}
              onConnect={() => act('connect', { faction: faction.id })}
            />
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

const FactionCard = (props) => {
  const { faction, isConnected, onConnect } = props;

  const reputationStars = Math.floor(faction.reputation / 20);
  const reputationLabel = getReputationLabel(faction.reputation);

  return (
    <Box
      className="FactionCard"
      style={{
        border: isConnected ? '2px solid #4a4' : '1px solid #555',
        borderRadius: '4px',
        padding: '10px',
        marginBottom: '8px',
        backgroundColor: isConnected ? 'rgba(26, 71, 42, 0.3)' : 'transparent',
      }}>
      <Flex align="center">
        <Flex.Item grow={1}>
          <Box bold fontSize="14px">
            {'★'.repeat(reputationStars)}
            {'☆'.repeat(5 - reputationStars)}
            {' '}{faction.name}
            {isConnected && (
              <Box inline color="good" ml={1}>
                [Connected ●]
              </Box>
            )}
          </Box>
          <Box color="label" italic>{faction.desc}</Box>
          <Box mt={1}>
            Reputation: {faction.reputation} ({reputationLabel})
          </Box>
          <Box>
            Cash: {faction.current_cash} / {faction.max_cash}
          </Box>
          <Box color="average">
            Specialty: {faction.specialty_name}
          </Box>
        </Flex.Item>
        <Flex.Item>
          <Button
            content={isConnected ? 'Connected' : 'Connect'}
            color={isConnected ? 'good' : 'default'}
            disabled={isConnected}
            onClick={onConnect}
          />
        </Flex.Item>
      </Flex>
    </Box>
  );
};
```

### Sell Materials Component

```jsx
const SellMaterialsTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    connected_faction,
    faction_cash,
    scanned_closets,
    selling,
  } = data;

  if (!connected_faction) {
    return (
      <Section fill>
        <NoticeBox warning>
          Connect to a faction first using the Factions tab.
        </NoticeBox>
      </Section>
    );
  }

  const selectedTotal = calculateSelectedTotal(scanned_closets);
  const canAfford = faction_cash >= selectedTotal;

  return (
    <Section
      fill
      scrollable
      title={`Sell to: ${connected_faction.name}`}
      buttons={
        <Box>Faction Cash: {faction_cash}</Box>
      }>
      {/* Scan buttons - same as ResourcesRecorder */}
      <Flex mb={2}>
        <Flex.Item>
          <Button
            icon="sync"
            content="Scan Warehouse"
            onClick={() => act('scan')}
          />
        </Flex.Item>
        <Flex.Item>
          <Button
            icon="check-square"
            content="Select All"
            onClick={() => act('select_all')}
          />
        </Flex.Item>
        <Flex.Item>
          <Button
            icon="square"
            content="Deselect All"
            onClick={() => act('deselect_all')}
          />
        </Flex.Item>
      </Flex>

      {/* Closet list with prices */}
      <Stack vertical>
        {scanned_closets.map(closet => (
          <Stack.Item key={closet.ref}>
            <SellClosetEntry closet={closet} />
          </Stack.Item>
        ))}
      </Stack>

      {/* Sale summary */}
      <Divider />
      <Flex justify="space-between" align="center">
        <Flex.Item>
          <Box bold>Selected Total: {selectedTotal}</Box>
          <Box color={canAfford ? 'good' : 'bad'}>
            {canAfford
              ? '✓ Faction can afford'
              : '✗ Faction cannot afford (reduce selection)'}
          </Box>
        </Flex.Item>
        <Flex.Item>
          <Button
            icon="paper-plane"
            content={`Sell - ${selectedTotal} credits`}
            color="good"
            disabled={!canAfford || selectedTotal === 0 || selling}
            onClick={() => act('sell')}
          />
        </Flex.Item>
      </Flex>
    </Section>
  );
};
```

### Buy Materials Component

```jsx
const BuyMaterialsTab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    connected_faction,
    credits,
    faction_stock,
    cart,
  } = data;

  if (!connected_faction) {
    return (
      <Section fill>
        <NoticeBox warning>
          Connect to a faction first using the Factions tab.
        </NoticeBox>
      </Section>
    );
  }

  const cartTotal = cart.reduce((sum, item) => sum + item.total, 0);

  return (
    <Section
      fill
      scrollable
      title={`Buy from: ${connected_faction.name}`}
      buttons={
        <Box>Your Credits: {credits}</Box>
      }>
      {/* Stock list grouped by category */}
      {Object.entries(groupByCategory(faction_stock)).map(([category, items]) => (
        <Collapsible key={category} title={category} open>
          {items.map(item => (
            <StockItemRow
              key={item.type}
              item={item}
              onAddToCart={(qty) => act('add_to_cart', {
                type: item.type,
                quantity: qty
              })}
            />
          ))}
        </Collapsible>
      ))}

      {/* Shopping cart */}
      <Divider />
      <Section title="Cart">
        {cart.length === 0 ? (
          <Box color="label">Cart is empty</Box>
        ) : (
          <Stack vertical>
            {cart.map(item => (
              <Stack.Item key={item.type}>
                <Flex justify="space-between">
                  <Flex.Item>{item.name} x{item.quantity}</Flex.Item>
                  <Flex.Item>{item.total}</Flex.Item>
                  <Flex.Item>
                    <Button
                      icon="times"
                      color="bad"
                      onClick={() => act('remove_from_cart', {
                        type: item.type
                      })}
                    />
                  </Flex.Item>
                </Flex>
              </Stack.Item>
            ))}
            <Stack.Item>
              <Divider />
              <Flex justify="space-between" bold>
                <Flex.Item>Total:</Flex.Item>
                <Flex.Item>{cartTotal}</Flex.Item>
              </Flex>
            </Stack.Item>
          </Stack>
        )}

        <Flex justify="flex-end" mt={2}>
          <Flex.Item mr={1}>
            <Button
              content="Clear Cart"
              onClick={() => act('clear_cart')}
              disabled={cart.length === 0}
            />
          </Flex.Item>
          <Flex.Item>
            <Button
              icon="shopping-cart"
              content={`Purchase - ${cartTotal}`}
              color="good"
              disabled={cartTotal === 0 || cartTotal > credits}
              onClick={() => act('purchase')}
            />
          </Flex.Item>
        </Flex>
      </Section>
    </Section>
  );
};

const StockItemRow = (props) => {
  const { item, onAddToCart } = props;
  const [quantity, setQuantity] = useState(1);

  return (
    <Box className="StockItemRow" py={1}>
      <Flex align="center">
        <Flex.Item grow={1}>
          <Box bold>{item.name}</Box>
          <Box color="label">Stock: {item.quantity}</Box>
        </Flex.Item>
        <Flex.Item width="80px">
          <Box>Price: {item.price}</Box>
        </Flex.Item>
        <Flex.Item>
          <NumberInput
            value={quantity}
            minValue={1}
            maxValue={item.quantity}
            onChange={(e, value) => setQuantity(value)}
          />
        </Flex.Item>
        <Flex.Item ml={1}>
          <Button
            icon="plus"
            content="Add"
            onClick={() => onAddToCart(quantity)}
            disabled={item.quantity === 0}
          />
        </Flex.Item>
      </Flex>
    </Box>
  );
};
```

---

## Integration with Research System

If using the research system, add a new research node:

```
TIER 2:
| **Trade Networks** | Metallurgy | Blueprints: Comms Console |
```

Comms Console blueprint would have:
```dm
/obj/structure/resurgence_blueprint/comms_console
    research_required = "trade_networks"
```

---

## Future Expansion Ideas

1. **Faction Quests**: Special requests from factions for reputation boosts
2. **Exclusive Items**: High-rep items only available at 80+ reputation
3. **Rival Factions**: Trading with one faction decreases rep with rivals
4. **Price Fluctuations**: Market prices change over time
5. **Bulk Discounts**: Lower per-item price for large orders
6. **Trade Routes**: Unlock faster delivery for frequent trading partners
