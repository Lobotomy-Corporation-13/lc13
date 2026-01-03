# Resurgence Outpost - Random Events System

## Overview

A dynamic events system that creates random occurrences throughout the round, adding variety and challenge to the gameplay. Events can be positive (resource drops, faction gifts), negative (raids, blights, weather), or neutral (traders, eclipses). The system integrates with existing faith, trading, and research systems.

**IMPORTANT: All colonists are PLAYERS, not AI pawns.** Events are designed around multiplayer cooperation, affecting the shared outpost rather than individual colonists. Events should create shared challenges or opportunities that players tackle together.

**Inspired by:** [RimWorld Events](https://rimworldwiki.com/wiki/Events)

---

## Design Philosophy

Since all colonists are players:
- **No individual targeting**: Events don't randomly afflict one player (no random disease/inspiration on one person)
- **Shared experiences**: Events affect the outpost, environment, or all players equally
- **Cooperative challenges**: Negative events encourage teamwork to overcome
- **Fair rewards**: Positive events benefit the whole group
- **Player agency**: Players can prepare for and respond to events together

---

## Event Categories

### Positive Events
Beneficial occurrences that help the outpost.

| Event | Description | Effect |
|-------|-------------|--------|
| **Resource Drop** | A cargo pod crashes nearby with supplies | Free resources spawn on map |
| **Faith Surge** | Spiritual energy flows through the area | All players gain faith bonus |
| **Trader Caravan** | Merchants arrive unannounced | Trading opportunity with bonus prices |
| **Bountiful Harvest** | Plants grow exceptionally well | Increased crop yields for duration |
| **Ancient Cache** | Hidden supplies discovered on map | Rare items at marked location |
| **Faction Gift** | A friendly faction sends supplies | Free resources delivered |
| **Skill Blessing** | Divine favor enhances abilities | All players gain temporary stat boost |
| **Fertile Soil** | Ground becomes enriched | Farming zones more productive |
| **Market Boom** | Trade prices shift favorably | Better sell prices, cheaper buys |

### Negative Events
Challenges that threaten the outpost (require cooperation to overcome).

| Event | Description | Effect |
|-------|-------------|--------|
| **Raid** | Hostile NPC forces attack | Combat encounter, defend outpost |
| **Crop Blight** | Disease spreads through plants | Crops damaged, players must contain |
| **Infestation** | Hostile NPC creatures spawn | Combat in enclosed spaces |
| **Solar Flare** | Electromagnetic disruption | All electronics disabled |
| **Heat Wave** | Extreme temperatures | Faster faith drain outdoors, crop wilting |
| **Cold Snap** | Freezing conditions | Movement penalty, faith drain outdoors |
| **Manhunter Pack** | Crazed NPC animals attack | Combat with animal swarm |
| **Faith Crisis** | Doubt spreads through outpost | All players' faith drains faster |
| **Structural Decay** | Buildings deteriorate | Random structures take damage |
| **Tool Wear** | Equipment stress | All tools lose durability |
| **Resource Blight** | Supplies contaminated | Some stored resources destroyed |
| **Bandit Camp** | Hostile camp appears nearby | Ongoing threat until cleared |
| **Market Crash** | Trade prices shift unfavorably | Worse sell prices, expensive buys |

### Neutral Events
Events that present opportunities or changes without being strictly good or bad.

| Event | Description | Effect |
|-------|-------------|--------|
| **Eclipse** | Darkness covers the land | Visibility reduced, atmosphere |
| **Wandering Trader** | Single merchant passes through | Limited trading window |
| **Mysterious Signal** | Strange transmission detected | Quest location revealed |
| **Faction Messenger** | Envoy from trading faction | Quest offer or reputation event |
| **Animal Herd** | Wild animals pass through | Hunting opportunity (or danger) |
| **Weather Shift** | Conditions change | Environmental effects |
| **Abandoned Shipment** | Lost cargo found | Resources at risky location |
| **Refugee Workers** | NPC laborers arrive temporarily | Extra hands for limited time |

---

## Event Details

### Positive Events

#### Resource Drop
A cargo pod crashes somewhere on the map with valuable supplies.

```dm
/datum/resurgence_event/resource_drop
    name = "Resource Drop"
    desc = "A cargo pod has crashed nearby!"
    category = EVENT_POSITIVE
    weight = 100  // Common
    min_time = 10 MINUTES
    max_time = null  // Can happen anytime after min

    var/list/possible_contents = list(
        /obj/item/stack/sheet/mineral/wood = 30,
        /obj/item/stack/sheet/metal = 20,
        /obj/item/stack/sheet/glass = 15,
        /obj/item/stack/ore/iron = 25,
        /obj/item/stack/sheet/cotton = 20,
        /obj/item/stack/ore/silver = 10,
        /obj/item/stack/ore/gold = 5
    )
```

**Mechanics:**
- Cargo pod spawns at random outdoor location
- Announcement tells all players approximate location
- Contains 2-4 random resource stacks
- Pod must be opened to retrieve contents
- Rare chance for valuable items (gold, silver, tools)
- First-come-first-served encourages quick response

#### Faith Surge
Spiritual energy flows through the area, blessing all faithful.

```dm
/datum/resurgence_event/faith_surge
    name = "Faith Surge"
    desc = "A wave of spiritual energy washes over the outpost!"
    category = EVENT_POSITIVE
    weight = 40
    min_time = 25 MINUTES
    max_time = null

    var/faith_bonus = 50        // Instant faith gain
    var/regen_bonus = 2.0       // Faith regen multiplier
    var/duration = 5 MINUTES
```

**Mechanics:**
- ALL players with resurgence cores gain instant faith
- Faith regeneration doubled for duration
- Visual effect (ambient golden glow on map)
- Sound effect (ethereal chime)
- Encourages players to do faith-draining activities during boost

#### Trader Caravan
A merchant caravan arrives with goods to trade.

```dm
/datum/resurgence_event/trader_caravan
    name = "Trader Caravan"
    desc = "A trading caravan has arrived at the outpost!"
    category = EVENT_POSITIVE
    weight = 60
    min_time = 15 MINUTES
    max_time = null

    var/stay_duration = 15 MINUTES
    var/price_discount = 0.9  // 10% better prices
```

**Mechanics:**
- Links to Trading System
- Random faction sends NPC traders
- Traders set up near outpost entrance
- 10% better prices than using Comms Console
- Stay for 15-20 minutes then leave
- Players can trade directly with caravan NPCs
- Reputation boost with faction after trading

#### Faction Gift
A friendly trading faction sends supplies as a goodwill gesture.

```dm
/datum/resurgence_event/faction_gift
    name = "Faction Gift"
    desc = "[faction_name] has sent a gift to the outpost!"
    category = EVENT_POSITIVE
    weight = 35
    min_time = 30 MINUTES
    max_time = null
```

**Mechanics:**
- Requires at least one faction at 60+ reputation
- Higher reputation = better gifts
- Cargo pod drops near Comms Console
- Contains faction specialty items
- Small reputation boost (+5)
- More likely with high-rep factions

#### Skill Blessing
Divine favor enhances all workers' abilities temporarily.

```dm
/datum/resurgence_event/skill_blessing
    name = "Skill Blessing"
    desc = "Divine favor flows through the workers!"
    category = EVENT_POSITIVE
    weight = 30
    min_time = 35 MINUTES
    max_time = null

    var/duration = 8 MINUTES
    var/stat_bonus = 3  // +3 to all resurgence stats
```

**Mechanics:**
- ALL players gain +3 to crafting, mining, harvesting, cooking stats
- Affects work speed and quality
- Visual indicator on player (subtle glow)
- Good time to craft high-quality items
- Stacks with room bonuses

#### Market Boom
Trade prices shift in the outpost's favor.

```dm
/datum/resurgence_event/market_boom
    name = "Market Boom"
    desc = "Market conditions are favorable! Trade prices improved."
    category = EVENT_POSITIVE
    weight = 40
    min_time = 20 MINUTES
    max_time = null

    var/duration = 10 MINUTES
    var/sell_bonus = 1.25    // +25% sell prices
    var/buy_discount = 0.85  // -15% buy prices
```

**Mechanics:**
- All faction buy prices increased by 25%
- All faction sell prices decreased by 15%
- Affects Comms Console trading
- Good time to sell stockpiled resources
- Announcement encourages trading activity

---

### Negative Events

#### Raid
Hostile NPC forces assault the outpost.

```dm
/datum/resurgence_event/raid
    name = "Raid"
    desc = "Hostile forces are attacking the outpost!"
    category = EVENT_NEGATIVE
    weight = 80
    min_time = 25 MINUTES
    max_time = null

    var/warning_time = 2 MINUTES
    var/min_raiders = 3
    var/max_raiders = 8
    var/raider_types = list(
        /mob/living/simple_animal/hostile/resurgence_raider/scavenger,
        /mob/living/simple_animal/hostile/resurgence_raider/marauder,
        /mob/living/simple_animal/hostile/resurgence_raider/brute
    )
```

**Mechanics:**
- **2-minute warning** before attack (time to prepare)
- NPC raiders spawn at map edge
- Scale with difficulty (time + outpost wealth)
- Raiders target players and structures
- Players must cooperate to defend
- Defeated raiders may drop loot (weapons, materials)
- Clearing all raiders ends event

**Raider Scaling:**
| Difficulty | Raider Count | Types |
|------------|--------------|-------|
| 1.0 (early) | 3-4 | Scavengers only |
| 1.5 (mid) | 5-6 | Scavengers + Marauders |
| 2.0 (late) | 7-10 | All types including Brutes |
| 2.5 (endgame) | 10-15 | Heavy Brute presence |

#### Crop Blight
A disease spreads through cultivated plants.

```dm
/datum/resurgence_event/blight
    name = "Crop Blight"
    desc = "A mysterious blight is spreading through your crops!"
    category = EVENT_NEGATIVE
    weight = 70
    min_time = 15 MINUTES
    max_time = null

    var/spread_interval = 30 SECONDS
    var/spread_chance = 30  // % chance per plant per cycle
    var/damage_per_cycle = 15
```

**Mechanics:**
- Starts on one random farming zone
- Spreads to adjacent plants every 30 seconds
- Affected plants show visual wilting (overlay)
- Players can:
  - Harvest early (50% yield) before plant dies
  - Destroy affected plants to stop spread
  - Create firebreaks (4+ tile gaps)
- Blight dies out after 5 minutes if contained
- Encourages players to split farming zones

#### Infestation
Hostile NPC creatures spawn in enclosed areas.

```dm
/datum/resurgence_event/infestation
    name = "Infestation"
    desc = "Creatures have infested an enclosed area!"
    category = EVENT_NEGATIVE
    weight = 50
    min_time = 30 MINUTES
    max_time = null

    var/creature_type = /mob/living/simple_animal/hostile/resurgence_vermin
    var/min_creatures = 4
    var/max_creatures = 10
```

**Mechanics:**
- Spawns in random enclosed room (workshop, storage, bedroom)
- NPC creatures are hostile, attack on sight
- Can damage stored items and furniture
- Players must clear room together
- Clearing grants small faith bonus to participants
- More likely in cluttered/dirty rooms
- Warning: announces which room is infested

#### Solar Flare
Electromagnetic disruption disables all electronics.

```dm
/datum/resurgence_event/solar_flare
    name = "Solar Flare"
    desc = "A solar flare has disrupted all electronic systems!"
    category = EVENT_NEGATIVE
    weight = 40
    min_time = 35 MINUTES
    max_time = null

    var/warning_time = 30 SECONDS
    var/duration = 5 MINUTES
```

**Mechanics:**
- **30-second warning** to finish electronic tasks
- Affected machines:
  - Comms Console (no trading)
  - Research Station (no researching)
  - Machine Fabricator (no machine crafting)
  - Any future electronic structures
- Primitive structures unaffected (forge, loom, crafting table)
- Players should switch to manual tasks during flare
- Good time for gathering, building, farming

#### Heat Wave
Extreme temperatures stress the outpost.

```dm
/datum/resurgence_event/heat_wave
    name = "Heat Wave"
    desc = "Extreme heat is bearing down on the outpost!"
    category = EVENT_NEGATIVE
    weight = 55
    min_time = 20 MINUTES
    max_time = null

    var/duration = 8 MINUTES
    var/outdoor_faith_drain = 1.5  // 50% faster drain outdoors
    var/crop_wilt_chance = 10      // % per minute
```

**Mechanics:**
- Faith drains 50% faster when outdoors
- Crops have chance to wilt each minute
- Staying indoors (in rooms) negates faith penalty
- Certain room types provide better protection
- Visual effect (heat shimmer, orange tint)
- Strategy: work indoors, check crops periodically

#### Cold Snap
Freezing conditions grip the land.

```dm
/datum/resurgence_event/cold_snap
    name = "Cold Snap"
    desc = "A sudden freeze grips the land!"
    category = EVENT_NEGATIVE
    weight = 55
    min_time = 20 MINUTES
    max_time = null

    var/duration = 8 MINUTES
    var/outdoor_faith_drain = 1.5
    var/movement_penalty = 0.7  // 30% slower outdoors
```

**Mechanics:**
- Faith drains 50% faster outdoors
- Movement speed reduced 30% outdoors
- Staying indoors negates penalties
- Visual effect (frost overlay, blue tint)
- Strategy: batch outdoor trips, stay inside

#### Manhunter Pack
Crazed NPC animals attack the outpost.

```dm
/datum/resurgence_event/manhunter
    name = "Manhunter Pack"
    desc = "A pack of crazed animals is hunting for prey!"
    category = EVENT_NEGATIVE
    weight = 45
    min_time = 30 MINUTES
    max_time = null

    var/animal_types = list(
        /mob/living/simple_animal/hostile/resurgence_wolf = 50,
        /mob/living/simple_animal/hostile/resurgence_boar = 35,
        /mob/living/simple_animal/hostile/resurgence_bear = 15
    )
    var/pack_size_min = 4
    var/pack_size_max = 8
```

**Mechanics:**
- NPC animal pack spawns at map edge
- Animals are hostile, hunt any player they see
- Cannot open doors (safe inside buildings)
- Will attack doors if they saw player enter
- Leave after 30-45 minutes if not killed
- Killing yields meat and leather (resources!)
- Strategy: fight together or wait inside

#### Faith Crisis
A wave of doubt spreads through the outpost.

```dm
/datum/resurgence_event/faith_crisis
    name = "Faith Crisis"
    desc = "Doubt and despair spread through the outpost..."
    category = EVENT_NEGATIVE
    weight = 35
    min_time = 40 MINUTES
    max_time = null

    var/instant_drain = 30   // Immediate faith loss
    var/regen_penalty = 0.5  // 50% regen during event
    var/duration = 5 MINUTES
```

**Mechanics:**
- ALL players lose 30 faith immediately
- Faith regeneration halved for duration
- High room quality reduces effect (luxury rooms = less drain)
- Players can pray at shrine to gain faith during crisis
- Ends after duration or if total outpost faith exceeds threshold
- Strategy: stay in high-quality rooms, use shrine

#### Bandit Camp
A hostile NPC encampment appears nearby.

```dm
/datum/resurgence_event/bandit_camp
    name = "Bandit Camp"
    desc = "Bandits have set up camp nearby!"
    category = EVENT_NEGATIVE
    weight = 30
    min_time = 45 MINUTES
    max_time = null

    var/camp_duration = 15 MINUTES  // How long before they attack
    var/num_bandits = 5
```

**Mechanics:**
- Bandit camp structure spawns at map edge
- Bandits patrol around camp
- After 15 minutes, bandits raid the outpost
- Players can:
  - Ignore (face larger raid later)
  - Attack camp proactively (risky but rewarding)
  - Negotiate via Comms Console (costs credits)
- Destroying camp yields loot cache
- Creates optional objective for players

#### Market Crash
Trade prices shift against the outpost.

```dm
/datum/resurgence_event/market_crash
    name = "Market Crash"
    desc = "Market conditions worsen. Trade prices are unfavorable."
    category = EVENT_NEGATIVE
    weight = 40
    min_time = 20 MINUTES
    max_time = null

    var/duration = 10 MINUTES
    var/sell_penalty = 0.7   // -30% sell prices
    var/buy_penalty = 1.3    // +30% buy prices
```

**Mechanics:**
- All faction buy prices decreased by 30%
- All faction sell prices increased by 30%
- Affects Comms Console trading
- Bad time to trade - wait it out
- Strategy: stockpile resources, trade later

---

### Neutral Events

#### Eclipse
A celestial event darkens the sky.

```dm
/datum/resurgence_event/eclipse
    name = "Eclipse"
    desc = "An eclipse has darkened the sky."
    category = EVENT_NEUTRAL
    weight = 50
    min_time = 25 MINUTES
    max_time = null

    var/duration = 5 MINUTES
    var/darkness_level = 0.3
```

**Mechanics:**
- Map becomes significantly darker
- Atmospheric effect (eerie mood)
- Some creatures may become more active
- Neither strictly good nor bad
- Crops don't grow during eclipse
- Slight increase in negative event chance after

#### Mysterious Signal
A strange transmission is detected.

```dm
/datum/resurgence_event/mysterious_signal
    name = "Mysterious Signal"
    desc = "A strange signal has been detected..."
    category = EVENT_NEUTRAL
    weight = 30
    min_time = 35 MINUTES
    max_time = null
```

**Mechanics:**
- Requires Comms Console to detect
- Signal points to location on map (marked)
- Players must investigate together
- Outcome is random:
  - 40%: Valuable cache (resources, tools)
  - 25%: Hostile ambush (small raid)
  - 20%: Abandoned supplies (minor loot)
  - 10%: Ancient artifact (rare item)
  - 5%: Nothing (false signal)
- Creates mini-adventure for group

#### Faction Messenger
An NPC envoy arrives from a trading faction.

```dm
/datum/resurgence_event/faction_messenger
    name = "Faction Messenger"
    desc = "A messenger has arrived from [faction_name]."
    category = EVENT_NEUTRAL
    weight = 40
    min_time = 20 MINUTES
    max_time = null
```

**Mechanics:**
- Links to Trading System
- Random faction sends NPC messenger
- Messenger offers one of:
  - **Trade deal**: Discounted goods for limited time
  - **Quest**: "Deliver X resources for +15 rep"
  - **Warning**: "Raid coming in 10 minutes" (useful intel)
  - **Request**: "We need X, will pay premium"
- Player choice affects faction reputation
- Refusing messenger = small rep loss

#### Animal Herd
Wild NPC animals pass through the area.

```dm
/datum/resurgence_event/animal_herd
    name = "Animal Herd"
    desc = "A herd of wild animals is passing through."
    category = EVENT_NEUTRAL
    weight = 55
    min_time = 15 MINUTES
    max_time = null

    var/animal_type = /mob/living/simple_animal/resurgence_deer
    var/herd_size_min = 5
    var/herd_size_max = 12
```

**Mechanics:**
- Passive NPC animals spawn at edge, cross map
- Players can hunt them for meat/leather
- Animals flee if attacked
- Limited time opportunity (they leave in 5 min)
- Encourages coordinated hunting
- Some herds are dangerous if provoked (boars)

#### Refugee Workers
Temporary NPC laborers arrive seeking shelter.

```dm
/datum/resurgence_event/refugee_workers
    name = "Refugee Workers"
    desc = "Refugees have arrived, offering labor in exchange for shelter."
    category = EVENT_NEUTRAL
    weight = 25
    min_time = 40 MINUTES
    max_time = null

    var/num_workers = 3
    var/stay_duration = 10 MINUTES
```

**Mechanics:**
- 3-5 NPC workers arrive at outpost
- Will help with tasks:
  - Hauling resources
  - Basic gathering (wood, stone)
  - Simple construction
- Stay for 10 minutes then leave
- Cannot do skilled work (crafting, forging)
- Provides temporary labor boost
- Players can assign them tasks via simple commands

#### Abandoned Shipment
Lost cargo is discovered at a location.

```dm
/datum/resurgence_event/abandoned_shipment
    name = "Abandoned Shipment"
    desc = "An abandoned shipment has been spotted nearby."
    category = EVENT_NEUTRAL
    weight = 45
    min_time = 20 MINUTES
    max_time = null
```

**Mechanics:**
- Cargo spawns at map edge location
- Location may be dangerous (near hazards)
- Contains moderate resources
- Might be trapped or guarded
- Risk vs reward decision for players
- First to arrive claims the goods

---

## Event System Architecture

### Event Manager

```dm
GLOBAL_DATUM(resurgence_events, /datum/resurgence_event_manager)

/datum/resurgence_event_manager
    /// All registered event types
    var/list/event_types = list()

    /// Currently active events
    var/list/active_events = list()

    /// Event history for this round
    var/list/event_history = list()

    /// Time until next event check
    var/next_check_time = 0

    /// Minimum time between events
    var/event_cooldown = 3 MINUTES

    /// Base chance for event each check (%)
    var/base_event_chance = 35

    /// Difficulty scaling factor (increases over time)
    var/difficulty = 1.0

    /// Category weights (can be adjusted)
    var/positive_weight = 35
    var/negative_weight = 45
    var/neutral_weight = 20
```

### Event Timing

Events are checked every 2 minutes with increasing probability:

```dm
/datum/resurgence_event_manager/proc/check_for_event()
    var/round_time = world.time - SSticker.round_start_time

    // Calculate event chance
    var/chance = base_event_chance

    // Increase chance over time (max +20%)
    chance += min(20, round_time / (5 MINUTES))

    // Decrease chance if recent event
    if(event_history.len && world.time - event_history[event_history.len]["time"] < event_cooldown)
        chance *= 0.5

    if(prob(chance))
        trigger_random_event()
```

### Category Selection

First select category, then event within category:

```dm
/datum/resurgence_event_manager/proc/select_category()
    var/total = positive_weight + negative_weight + neutral_weight
    var/roll = rand(1, total)

    if(roll <= positive_weight)
        return EVENT_POSITIVE
    else if(roll <= positive_weight + negative_weight)
        return EVENT_NEGATIVE
    else
        return EVENT_NEUTRAL
```

### Difficulty Scaling

Difficulty affects negative event severity:

```dm
/datum/resurgence_event_manager/proc/update_difficulty()
    var/round_time = world.time - SSticker.round_start_time
    var/round_minutes = round_time / (1 MINUTES)

    // Base scaling: +10% every 10 minutes
    difficulty = 1.0 + (round_minutes / 10) * 0.1

    // Cap at 2.5x
    difficulty = min(difficulty, 2.5)

    // Bonus difficulty for wealthy outpost
    if(GLOB.resurgence_research?.researched_nodes.len > 5)
        difficulty += 0.2
    if(GLOB.resurgence_credits > 1000)
        difficulty += 0.1
```

---

## Player Communication

### Event Announcements

All events broadcast to all players:

```dm
/datum/resurgence_event/proc/announce()
    var/sound_file
    var/color

    switch(category)
        if(EVENT_POSITIVE)
            sound_file = 'sound/effects/positive_event.ogg'
            color = "green"
        if(EVENT_NEGATIVE)
            sound_file = 'sound/effects/negative_event.ogg'
            color = "red"
        if(EVENT_NEUTRAL)
            sound_file = 'sound/effects/neutral_event.ogg'
            color = "yellow"

    // Chat announcement
    for(var/mob/living/carbon/human/H in GLOB.player_list)
        if(is_resurgence_player(H))
            to_chat(H, span_[color]bold("EVENT: [name]"))
            to_chat(H, span_notice(desc))
            SEND_SOUND(H, sound(sound_file))

    // TGUI popup (optional)
    show_event_popup(name, desc, category)
```

### Event UI

Simple HUD showing active events:

```
┌────────────────────┐
│ ACTIVE EVENTS      │
├────────────────────┤
│ 🔴 Heat Wave       │
│    4:32 remaining  │
├────────────────────┤
│ 🟢 Market Boom     │
│    2:15 remaining  │
└────────────────────┘
```

---

## Integration with Other Systems

### Research System

| Research Node | Event Effect |
|---------------|--------------|
| **Communications** | Enables Faction Messenger, Mysterious Signal |
| **Trade Networks** | Increases Trader Caravan frequency |
| **Advanced Metallurgy** | Better loot in Resource Drops |
| **Agriculture** | Reduces Blight spread speed by 50% |
| **Faith Weaving** | Reduces Faith Crisis severity |

### Trading System

- **Trader Caravan**: Spawns faction NPCs with goods
- **Faction Messenger**: Offers deals/quests
- **Faction Gift**: Rewards high reputation
- **Market Boom/Crash**: Affects all trading prices
- **Bandit Camp**: Can be negotiated away for credits

### Faith System

- **Faith Surge**: Grants bonus to all players
- **Faith Crisis**: Drains faith, tests group
- **Room Quality**: High quality rooms reduce negative effects
- **Shrine**: Can end Faith Crisis early

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `code/modules/resurgence_outpost/events/event_manager.dm` | **CREATE** - Global event manager |
| `code/modules/resurgence_outpost/events/event_types.dm` | **CREATE** - Base event datum |
| `code/modules/resurgence_outpost/events/positive_events.dm` | **CREATE** - All positive events |
| `code/modules/resurgence_outpost/events/negative_events.dm` | **CREATE** - All negative events |
| `code/modules/resurgence_outpost/events/neutral_events.dm` | **CREATE** - All neutral events |
| `code/modules/resurgence_outpost/events/event_mobs.dm` | **CREATE** - Raiders, animals, workers |
| `tgui/packages/tgui/interfaces/ResurgenceEvents.js` | **CREATE** - Active events HUD |
| `lobotomy-corp13.dme` | **MODIFY** - Include event files |

---

## Implementation Steps

### Step 1: Create Event Manager
- Global singleton with event loop
- Category and difficulty scaling
- Event cooldown tracking

### Step 2: Create Base Event Type
- Common variables and procs
- Announcement system
- Duration/timer handling

### Step 3: Implement Positive Events
- Resource Drop, Faith Surge, Trader Caravan
- Faction Gift, Skill Blessing, Market Boom
- Bountiful Harvest, Fertile Soil

### Step 4: Implement Negative Events
- Raid (NPC enemies)
- Crop Blight, Infestation
- Weather events (Heat Wave, Cold Snap)
- Manhunter Pack, Faith Crisis
- Market Crash, Bandit Camp

### Step 5: Implement Neutral Events
- Eclipse, Mysterious Signal
- Faction Messenger, Animal Herd
- Refugee Workers, Abandoned Shipment

### Step 6: Create Event NPCs
- Raiders (Scavenger, Marauder, Brute)
- Animals (Wolf, Boar, Bear, Deer)
- Vermin (infestation creatures)
- Workers (refugee laborers)

### Step 7: Create Event UI
- Announcement popups
- Active events HUD
- Event log (history)

### Step 8: Balance & Integration
- Tune frequencies and severities
- Link with Research prerequisites
- Link with Trading prices
- Test multiplayer scenarios

---

## Balancing for Multiplayer

### Event Frequency by Player Count

| Players | Event Frequency | Negative Scaling |
|---------|-----------------|------------------|
| 1-2 | Every 4-5 min | 0.7x severity |
| 3-4 | Every 3-4 min | 1.0x severity |
| 5-6 | Every 2-3 min | 1.2x severity |
| 7+ | Every 2 min | 1.5x severity |

### Cooperative Incentives

- **Raids**: More raiders, need teamwork
- **Manhunters**: Pack too large for one player
- **Blight**: Spreads fast, needs multiple people
- **Mysterious Signal**: Better rewards with group
- **Bandit Camp**: Solo attack very risky

### Shared Rewards

- Resource Drops benefit whoever reaches them
- Market effects help all traders equally
- Faith Surge helps everyone equally
- Trader Caravan available to all
