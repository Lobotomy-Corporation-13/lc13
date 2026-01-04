# Resurgence Outpost - Random Events System

## Overview

A dynamic events system that creates random occurrences throughout the round, adding variety and challenge to the gameplay. Events can be positive (bonuses, gifts), negative (penalties, challenges), or neutral (weather, mixed effects). The system integrates with existing faith, trading, farming, and research systems.

**IMPORTANT: All colonists are PLAYERS, not AI pawns.** Events are designed around multiplayer cooperation, affecting the shared outpost rather than individual colonists. Events should create shared challenges or opportunities that players tackle together.

---

## Design Philosophy

Since all colonists are players:
- **No individual targeting**: Events don't randomly afflict one player
- **Shared experiences**: Events affect the outpost, environment, or all players equally
- **Simple modifiers**: Events use existing systems (work per tick, yields, prices, faith)
- **Fair rewards**: Positive events benefit the whole group
- **Clear effects**: Players can easily understand what's happening
- **No combat (yet)**: Combat events will be added in a future update

---

## Event Categories

### Positive Events
Beneficial occurrences that help the outpost.

| Event | Duration | Effect | Systems |
|-------|----------|--------|---------|
| **Bountiful Harvest** | 8 min | Harvesting yields +50% resources | Farming, Wild Plants |
| **Rich Soil** | 10 min | Farm plots grow 50% faster | Farming |
| **Favorable Conditions** | 8 min | All gathering gives +1 bonus work per tick | Mining, Trees, Cotton |
| **Market Boom** | 10 min | +25% sell prices, -15% buy prices | Trading |
| **Faith Surge** | 5 min | +30 instant faith, 2x faith regen | Faith System |
| **Research Momentum** | 8 min | Research gives +50% work per session | Research |
| **Crafting Inspiration** | 10 min | +2 bonus to quality tier rolls when crafting | Crafting Tables |
| **Resource Discovery** | Instant | A new ore deposit or tree cluster spawns on map | Resources |
| **Faction Goodwill** | Instant | A discovered faction sends a small gift (requires 40+ rep) | Trading |

### Negative Events
Challenges that affect the outpost (encourage adaptation).

| Event | Duration | Effect | Systems |
|-------|----------|--------|---------|
| **Heat Wave** | 8 min | Outdoor faith drain +50%, crop growth -25% | Faith, Farming |
| **Cold Snap** | 8 min | Outdoor movement -30%, outdoor faith drain +50% | Faith, Movement |
| **Drought** | 10 min | Farm plots grow 50% slower | Farming |
| **Market Crash** | 10 min | -30% sell prices, +30% buy prices | Trading |
| **Faith Crisis** | 5 min | -20 instant faith, 50% slower faith regen | Faith System |
| **Fatigue Wave** | 6 min | All work actions give -25% work per tick | All Work Systems |
| **Resource Scarcity** | 8 min | Gathering yields -25% resources | Mining, Trees, Cotton |
| **Tool Strain** | 10 min | Tools lose 2x durability on use | Tools |

### Neutral/Weather Events
Events that present mixed effects or atmospheric changes.

| Event | Duration | Effect |
|-------|----------|--------|
| **Heavy Rain** | 6 min | Outdoor movement -20%, farm plots grow +25% faster |
| **Dense Fog** | 5 min | Reduced vision outdoors (atmospheric, no gameplay effect) |
| **Clear Skies** | 10 min | +10% work speed outdoors, +10% crop growth |

---

## Weather System Integration

The codebase has an existing weather system (`/datum/weather`) managed by SSweather. Weather events can leverage this system for visual effects and area-based mechanics.

### How Weather Works

Weather datums have four stages:
1. **Telegraph** - Warning phase with light overlay and announcement
2. **Main** - Active weather with full effects
3. **Wind Down** - Weather ending with reduced overlay
4. **End** - Weather fully ends, overlays removed

Key weather properties:
```dm
/datum/weather
    var/name                    // Display name
    var/telegraph_message       // Warning message to players
    var/telegraph_duration      // Warning phase length (deciseconds)
    var/telegraph_overlay       // Light visual overlay
    var/weather_message         // Main phase message
    var/weather_duration_lower  // Min duration
    var/weather_duration_upper  // Max duration
    var/weather_overlay         // Main visual overlay
    var/end_message             // Ending message
    var/end_overlay             // Ending visual overlay
    var/area_type               // Areas to affect
    var/protect_indoors = FALSE // If TRUE, indoor areas are protected
    var/target_trait            // Z-level trait to affect
    var/immunity_type           // Mobs with this immunity are unaffected
    var/perpetual = FALSE       // If TRUE, doesn't auto-end
```

Weather effects are applied via `weather_act(mob/living/L)` which is called on affected mobs during the main stage.

### Resurgence Weather Implementation

For Resurgence Outpost, we can either:

**Option A: Use Full Weather System**
- Create new `/datum/weather/resurgence_*` types
- Set `target_trait = ZTRAIT_RESURGENCE` (new trait for outpost z-level)
- Set `protect_indoors = TRUE` so designated rooms provide shelter
- Use existing overlay system for visuals

**Option B: Simplified Event System**
- Create simpler event datums that apply modifiers
- Use visual effects placed on turfs instead of area overlays
- Less complex but less immersive

**Recommended: Option A** - Use the existing weather system for:
- Heavy Rain, Dense Fog, Heat Wave, Cold Snap
- Consistent with rest of codebase
- Built-in indoor protection via `protect_indoors`
- Already has announcement and overlay handling

---

## Event Details

### Positive Events

#### Bountiful Harvest
Plants yield more when harvested.

```dm
/datum/resurgence_event/bountiful_harvest
    name = "Bountiful Harvest"
    desc = "The plants are thriving! Harvesting yields increased."
    category = EVENT_POSITIVE
    weight = 80
    min_time = 10 MINUTES
    duration = 8 MINUTES

    var/yield_multiplier = 1.5  // +50% harvest yields
```

**Mechanics:**
- All harvesting (farm plots, wild plants, cotton) yields 50% more
- Applies to harvest amount, not growth speed
- Visual: Green sparkle effect on plants
- Good time to harvest mature crops

#### Rich Soil
Farm plots grow faster.

```dm
/datum/resurgence_event/rich_soil
    name = "Rich Soil"
    desc = "The soil is exceptionally fertile! Crops grow faster."
    category = EVENT_POSITIVE
    weight = 70
    min_time = 15 MINUTES
    duration = 10 MINUTES

    var/growth_multiplier = 1.5  // 50% faster growth
```

**Mechanics:**
- Farm plot growth ticks happen 50% faster
- Affects all active farm plots
- Does not affect wild plants
- Good time to plant new crops

#### Favorable Conditions
Gathering work is more productive.

```dm
/datum/resurgence_event/favorable_conditions
    name = "Favorable Conditions"
    desc = "Perfect weather for gathering! Work is more productive."
    category = EVENT_POSITIVE
    weight = 75
    min_time = 12 MINUTES
    duration = 8 MINUTES

    var/bonus_work = 1  // +1 work per tick
```

**Mechanics:**
- Mining, tree chopping, and cotton picking give +1 work per tick
- Stacks with stat bonuses
- Encourages outdoor gathering activities
- Visual: Sunny weather effect

#### Market Boom
Trade prices shift favorably.

```dm
/datum/resurgence_event/market_boom
    name = "Market Boom"
    desc = "Market conditions are favorable! Trade prices improved."
    category = EVENT_POSITIVE
    weight = 60
    min_time = 20 MINUTES
    duration = 10 MINUTES

    var/sell_multiplier = 1.25   // +25% sell prices
    var/buy_multiplier = 0.85    // -15% buy prices
```

**Mechanics:**
- All faction buy prices increased by 25%
- All faction sell prices decreased by 15%
- Affects Comms Console trading
- Good time to sell stockpiled resources

#### Faith Surge
Spiritual energy flows through the area.

```dm
/datum/resurgence_event/faith_surge
    name = "Faith Surge"
    desc = "A wave of spiritual energy washes over the outpost!"
    category = EVENT_POSITIVE
    weight = 50
    min_time = 25 MINUTES
    duration = 5 MINUTES

    var/instant_faith = 30      // Instant faith gain
    var/regen_multiplier = 2.0  // 2x faith regen
```

**Mechanics:**
- ALL players with resurgence cores gain +30 faith instantly
- Faith regeneration doubled for duration
- Visual: Golden ambient glow
- Good time to do faith-draining activities

#### Research Momentum
Research progresses faster.

```dm
/datum/resurgence_event/research_momentum
    name = "Research Momentum"
    desc = "A breakthrough! Research progresses faster."
    category = EVENT_POSITIVE
    weight = 55
    min_time = 20 MINUTES
    duration = 8 MINUTES

    var/work_multiplier = 1.5  // +50% research work
```

**Mechanics:**
- Research station gives 50% more work per session
- Affects all players researching
- Does not reduce faith cost
- Good time to push through research

#### Crafting Inspiration
Crafted items tend to be higher quality.

```dm
/datum/resurgence_event/crafting_inspiration
    name = "Crafting Inspiration"
    desc = "The workers feel inspired! Crafted items are higher quality."
    category = EVENT_POSITIVE
    weight = 50
    min_time = 25 MINUTES
    duration = 10 MINUTES

    var/quality_bonus = 2  // +2 to quality tier rolls
```

**Mechanics:**
- Quality tier rolls get +2 bonus (as if +2 crafting levels)
- Affects all crafting tables, forges, looms
- Good time to craft important tools/items
- Visual: Sparkle effect on crafting stations

#### Resource Discovery
A new resource node spawns on the map.

```dm
/datum/resurgence_event/resource_discovery
    name = "Resource Discovery"
    desc = "A new resource deposit has been discovered!"
    category = EVENT_POSITIVE
    weight = 40
    min_time = 30 MINUTES
    duration = 0  // Instant

    var/list/possible_resources = list(
        /obj/structure/ore_deposit/iron = 40,
        /obj/structure/ore_deposit/silver = 25,
        /obj/structure/ore_deposit/gold = 15,
        /obj/structure/resurgence_tree = 20
    )
```

**Mechanics:**
- Spawns a new ore deposit or tree cluster
- Location announced to all players
- Weighted toward common resources
- Permanent addition to map

#### Faction Goodwill
A friendly faction sends a gift.

```dm
/datum/resurgence_event/faction_goodwill
    name = "Faction Goodwill"
    desc = "[faction_name] has sent a gift to show their appreciation!"
    category = EVENT_POSITIVE
    weight = 35
    min_time = 30 MINUTES
    duration = 0  // Instant
```

**Mechanics:**
- Requires at least one faction at 40+ reputation
- Higher reputation = better gifts
- Spawns a small crate near Comms Console
- Contains faction specialty items (2-4 items)
- Small reputation boost (+3)

---

### Negative Events

#### Heat Wave
Extreme heat stresses outdoor activities. Uses the weather system.

```dm
/datum/weather/resurgence/heat_wave
    name = "heat wave"
    desc = "Extreme heat bears down on the outpost."

    telegraph_message = span_warning("The temperature begins to rise...")
    telegraph_duration = 300
    telegraph_overlay = "light_ash"  // Reuse ash overlay for heat shimmer

    weather_message = span_userdanger("A scorching heat wave grips the outpost!")
    weather_duration_lower = 4200  // 7 minutes
    weather_duration_upper = 5400  // 9 minutes
    weather_overlay = "heavy_ash"

    end_message = span_notice("The temperature starts to return to normal.")
    end_duration = 100
    end_overlay = "light_ash"

    area_type = /area/resurgence_outpost
    protect_indoors = TRUE
    target_trait = ZTRAIT_RESURGENCE
    immunity_type = "heat"

    var/faith_drain_mult = 1.5   // +50% faith drain outdoors
    var/growth_mult = 0.75       // -25% crop growth

/datum/weather/resurgence/heat_wave/weather_act(mob/living/carbon/human/L)
    if(!ishuman(L))
        return
    // Faith drain is handled by checking if heat wave is active
    // in the faith tick proc
```

**Mechanics:**
- Faith drains 50% faster when outdoors (checked in faith tick)
- Crop growth slowed by 25% (global modifier)
- Being indoors (in designated rooms) negates faith penalty
- Visual: Orange/ash overlay for heat shimmer effect
- Strategy: Work indoors, check crops when needed

#### Cold Snap
Freezing conditions grip the land. Uses the weather system.

```dm
/datum/weather/resurgence/cold_snap
    name = "cold snap"
    desc = "A sudden freeze grips the land."

    telegraph_message = span_warning("The temperature begins to drop rapidly...")
    telegraph_duration = 300
    telegraph_overlay = "snowfall_calm"

    weather_message = span_userdanger("A bitter cold snap freezes the outpost!")
    weather_duration_lower = 4200  // 7 minutes
    weather_duration_upper = 5400  // 9 minutes
    weather_overlay = "snowfall_blizzard"

    end_message = span_notice("The cold begins to recede.")
    end_duration = 100
    end_overlay = "snowfall_calm"

    area_type = /area/resurgence_outpost
    protect_indoors = TRUE
    target_trait = ZTRAIT_RESURGENCE
    immunity_type = "cold"

    var/faith_drain_mult = 1.5   // +50% faith drain outdoors
    var/movement_mult = 0.7      // -30% movement speed outdoors

/datum/weather/resurgence/cold_snap/weather_act(mob/living/carbon/human/L)
    if(!ishuman(L))
        return
    // Apply movement slowdown
    L.add_or_update_variable_movespeed_modifier(
        /datum/movespeed_modifier/resurgence_cold,
        multiplicative_slowdown = 0.3
    )

/datum/weather/resurgence/cold_snap/end()
    . = ..()
    // Remove movement modifiers from all players
    for(var/mob/living/carbon/human/L in GLOB.player_list)
        L.remove_movespeed_modifier(/datum/movespeed_modifier/resurgence_cold)
```

**Mechanics:**
- Faith drains 50% faster outdoors (checked in faith tick)
- Movement speed reduced 30% outdoors (via movespeed modifier)
- Being indoors negates penalties
- Visual: Snow/blizzard overlay
- Strategy: Batch outdoor trips, stay inside

#### Drought
Lack of water slows crop growth.

```dm
/datum/resurgence_event/drought
    name = "Drought"
    desc = "A drought has set in. Crops struggle to grow."
    category = EVENT_NEGATIVE
    weight = 65
    min_time = 15 MINUTES
    duration = 10 MINUTES

    var/growth_mult = 0.5  // -50% crop growth
```

**Mechanics:**
- Farm plot growth slowed by 50%
- Does not affect already-mature crops
- Good time to focus on other activities
- Visual: Dry/cracked ground effect on farm plots

#### Market Crash
Trade prices shift unfavorably.

```dm
/datum/resurgence_event/market_crash
    name = "Market Crash"
    desc = "Market conditions worsen. Trade prices are unfavorable."
    category = EVENT_NEGATIVE
    weight = 60
    min_time = 20 MINUTES
    duration = 10 MINUTES

    var/sell_multiplier = 0.7    // -30% sell prices
    var/buy_multiplier = 1.3     // +30% buy prices
```

**Mechanics:**
- All faction buy prices decreased by 30%
- All faction sell prices increased by 30%
- Affects Comms Console trading
- Strategy: Stockpile resources, trade later

#### Faith Crisis
A wave of doubt affects everyone.

```dm
/datum/resurgence_event/faith_crisis
    name = "Faith Crisis"
    desc = "Doubt and despair spread through the outpost..."
    category = EVENT_NEGATIVE
    weight = 45
    min_time = 30 MINUTES
    duration = 5 MINUTES

    var/instant_drain = 20       // Immediate faith loss
    var/regen_multiplier = 0.5   // 50% slower regen
```

**Mechanics:**
- ALL players lose 20 faith immediately
- Faith regeneration halved for duration
- High room quality reduces effect slightly
- Visual: Desaturated colors, gloomy ambiance
- Shortest negative event duration

#### Fatigue Wave
Everyone feels tired and sluggish.

```dm
/datum/resurgence_event/fatigue_wave
    name = "Fatigue Wave"
    desc = "A wave of exhaustion washes over the workers..."
    category = EVENT_NEGATIVE
    weight = 55
    min_time = 20 MINUTES
    duration = 6 MINUTES

    var/work_multiplier = 0.75  // -25% work per tick
```

**Mechanics:**
- All work actions (crafting, mining, research, etc.) give 25% less work
- Affects everyone equally
- Does not affect faith drain
- Strategy: Do less demanding tasks or rest

#### Resource Scarcity
Gathering yields less.

```dm
/datum/resurgence_event/resource_scarcity
    name = "Resource Scarcity"
    desc = "Resources are harder to come by..."
    category = EVENT_NEGATIVE
    weight = 60
    min_time = 18 MINUTES
    duration = 8 MINUTES

    var/yield_multiplier = 0.75  // -25% gathering yields
```

**Mechanics:**
- Mining, tree chopping, cotton picking yield 25% less
- Affects resource drops, not work speed
- Does not affect farming
- Strategy: Wait it out or focus on crafting

#### Tool Strain
Tools wear out faster.

```dm
/datum/resurgence_event/tool_strain
    name = "Tool Strain"
    desc = "Something in the air is wearing down tools faster..."
    category = EVENT_NEGATIVE
    weight = 50
    min_time = 25 MINUTES
    duration = 10 MINUTES

    var/durability_multiplier = 2  // 2x durability loss
```

**Mechanics:**
- All tools lose durability twice as fast
- Affects pickaxes, hatchets, scythes, etc.
- Good time to do non-tool activities
- Strategy: Use backup tools or wait

---

### Neutral/Weather Events

These events use the existing `/datum/weather` system for visual effects and area-based mechanics.

#### Heavy Rain
Rain affects outdoor activities but helps crops.

```dm
/datum/weather/resurgence/heavy_rain
    name = "heavy rain"
    desc = "Heavy rainfall blankets the outpost."

    telegraph_message = span_warning("Dark clouds gather overhead...")
    telegraph_duration = 300  // 30 seconds
    telegraph_overlay = "light_rain"

    weather_message = span_notice("Heavy rain begins to fall across the outpost.")
    weather_duration_lower = 3000  // 5 minutes
    weather_duration_upper = 4200  // 7 minutes
    weather_overlay = "rain_storm"

    end_message = span_notice("The rain begins to let up.")
    end_duration = 100
    end_overlay = "light_rain"

    area_type = /area/resurgence_outpost
    protect_indoors = TRUE
    target_trait = ZTRAIT_RESURGENCE
    immunity_type = "rain"

    var/movement_mult = 0.8      // -20% movement outdoors
    var/growth_mult = 1.25       // +25% crop growth

/datum/weather/resurgence/heavy_rain/weather_act(mob/living/L)
    // Apply movement slowdown via movespeed modifier
    L.add_or_update_variable_movespeed_modifier(
        /datum/movespeed_modifier/resurgence_rain,
        multiplicative_slowdown = 0.2
    )
```

**Mechanics:**
- Movement slowed 20% outdoors (via movespeed modifier)
- Farm plots grow 25% faster (checked via global modifier)
- Mixed blessing - helps farmers, slows gatherers
- Visual: Rain overlay from weather_effects.dmi
- Indoor areas protected via `protect_indoors = TRUE`

#### Dense Fog
Fog rolls in, reducing visibility.

```dm
/datum/weather/resurgence/dense_fog
    name = "dense fog"
    desc = "A thick fog has rolled in across the outpost."

    telegraph_message = span_warning("The air grows thick and hazy...")
    telegraph_duration = 200
    telegraph_overlay = "light_fog"

    weather_message = span_notice("Dense fog blankets the area, reducing visibility.")
    weather_duration_lower = 2400  // 4 minutes
    weather_duration_upper = 3600  // 6 minutes
    weather_overlay = "heavy_fog"

    end_message = span_notice("The fog begins to lift.")
    end_duration = 150
    end_overlay = "light_fog"

    area_type = /area/resurgence_outpost
    protect_indoors = TRUE
    target_trait = ZTRAIT_RESURGENCE
    aesthetic = TRUE  // No gameplay effect, just visual
```

**Mechanics:**
- Atmospheric event, no gameplay effect (`aesthetic = TRUE`)
- Visual: Fog overlay reduces visibility
- Creates eerie atmosphere
- Purely for flavor/immersion
- Indoor areas protected

#### Clear Skies
Perfect weather for outdoor work.

```dm
// Clear Skies is NOT a weather datum - it's an event that sets
// global modifiers when no weather is active

/datum/resurgence_event/clear_skies
    name = "Clear Skies"
    desc = "The weather is perfect for outdoor work!"
    category = EVENT_NEUTRAL
    weight = 60
    min_time = 10 MINUTES
    duration = 10 MINUTES

    var/work_mult = 1.1          // +10% outdoor work speed
    var/growth_mult = 1.1        // +10% crop growth

/datum/resurgence_event/clear_skies/can_start()
    // Only trigger if no weather is currently active
    for(var/datum/weather/W in SSweather.processing)
        if(istype(W, /datum/weather/resurgence))
            return FALSE
    return TRUE
```

**Mechanics:**
- Small bonus to outdoor work speed
- Small bonus to crop growth
- Mild positive effect
- Only triggers when no weather is active
- Visual: Bright, sunny lighting (no overlay)

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

    /// Category weights (can be adjusted)
    var/positive_weight = 40
    var/negative_weight = 40
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
    if(length(event_history) && world.time - event_history[length(event_history)]["time"] < event_cooldown)
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
            if(duration)
                to_chat(H, span_notice("Duration: [duration / (1 MINUTES)] minutes"))
            SEND_SOUND(H, sound(sound_file))
```

### Event UI

Simple HUD showing active events:

```
+--------------------+
| ACTIVE EVENTS      |
+--------------------+
| [red] Heat Wave    |
|    4:32 remaining  |
+--------------------+
| [green] Market Boom|
|    2:15 remaining  |
+--------------------+
```

---

## Integration with Other Systems

### Global Modifiers

Events set global modifier variables that other systems check:

```dm
// In gathering_base.dm
/proc/get_gathering_yield_modifier()
    var/mod = 1.0
    if(GLOB.resurgence_events)
        mod *= GLOB.resurgence_events.yield_modifier
    return mod

// In farm_plot.dm
/obj/structure/resurgence_farm_plot/proc/get_growth_modifier()
    var/mod = 1.0
    if(GLOB.resurgence_events)
        mod *= GLOB.resurgence_events.growth_modifier
    return mod
```

### Research System

| Research Node | Event Effect |
|---------------|--------------|
| **Communications** | Enables Faction Goodwill event |
| **Agriculture** | Reduces Drought severity by 25% |
| **Faith Weaving** | Reduces Faith Crisis severity |

### Trading System

- **Market Boom**: Multiplies all trade prices favorably
- **Market Crash**: Multiplies all trade prices unfavorably
- **Faction Goodwill**: Sends gift from high-rep faction

### Faith System

- **Faith Surge**: Instant gain + regen boost
- **Faith Crisis**: Instant drain + regen penalty
- **Weather events**: Affect outdoor faith drain

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `code/modules/resurgence_outpost/events/_events.dm` | **CREATE** - Defines and globals |
| `code/modules/resurgence_outpost/events/event_manager.dm` | **CREATE** - Global event manager |
| `code/modules/resurgence_outpost/events/event_base.dm` | **CREATE** - Base event datum |
| `code/modules/resurgence_outpost/events/positive_events.dm` | **CREATE** - All positive events |
| `code/modules/resurgence_outpost/events/negative_events.dm` | **CREATE** - All negative events |
| `code/modules/resurgence_outpost/events/weather_events.dm` | **CREATE** - Weather datums (using /datum/weather) |
| `code/modules/resurgence_outpost/events/weather_modifiers.dm` | **CREATE** - Movespeed modifiers for weather |
| `tgui/packages/tgui/interfaces/ResurgenceEvents.js` | **CREATE** - Active events HUD |
| `code/__DEFINES/traits.dm` | **MODIFY** - Add ZTRAIT_RESURGENCE for weather targeting |
| `lobotomy-corp13.dme` | **MODIFY** - Include event files |

---

## Implementation Steps

### Step 1: Setup Z-Level Trait
- Add `ZTRAIT_RESURGENCE` to `code/__DEFINES/traits.dm`
- Apply trait to resurgence outpost z-level in map loading

### Step 2: Create Event Manager
- Global singleton with event loop
- Category weights and selection
- Event cooldown tracking
- Global modifier variables

### Step 3: Create Base Event Type
- Common variables (name, desc, duration, weight)
- Announcement system
- Duration/timer handling
- Start/end hooks

### Step 4: Create Weather Types
- Create `/datum/weather/resurgence` base type
- Implement Heat Wave, Cold Snap (negative weather)
- Implement Heavy Rain, Dense Fog (neutral weather)
- Create movespeed modifiers for weather effects
- Use `protect_indoors = TRUE` so rooms provide shelter

### Step 5: Implement Positive Events
- Bountiful Harvest, Rich Soil, Favorable Conditions
- Market Boom, Faith Surge, Research Momentum
- Crafting Inspiration, Resource Discovery, Faction Goodwill

### Step 6: Implement Non-Weather Negative Events
- Drought, Market Crash, Faith Crisis
- Fatigue Wave, Resource Scarcity, Tool Strain

### Step 7: Implement Clear Skies
- Event that triggers when no weather is active
- Provides mild positive modifiers

### Step 8: Create Event UI
- Announcement popups
- Active events HUD (including weather)
- Duration countdown

### Step 9: Integration
- Hook modifiers into gathering, farming, crafting
- Hook into trading price calculations
- Hook into faith drain calculations (check for active weather)
- Hook into room `outdoors` check for weather protection
- Test all interactions

---

## Balancing for Multiplayer

### Event Frequency by Player Count

| Players | Check Interval | Event Chance |
|---------|----------------|--------------|
| 1-2 | Every 3 min | 30% base |
| 3-4 | Every 2 min | 35% base |
| 5+ | Every 2 min | 40% base |

### Fair Distribution

- Positive and negative events have equal weight (40/40)
- Neutral events are less common (20%)
- All effects apply to everyone equally
- No individual targeting

### Duration Balance

- Positive events: 5-10 minutes (enjoy the bonus)
- Negative events: 5-10 minutes (manageable challenge)
- Weather events: 5-10 minutes (atmospheric)
- Cooldown between events: 3 minutes minimum
