# The Middle Nursefather — Party Gimmick Design

## Overview

The Ex Great Brother is the Middle's party-loving hedonist. His core roleplay loop:
1. **Break into** a room by forcing doors open with Laevateinn
2. **Throw a party** using his Stamp Card — invite people, spawn entertainment
3. **Reward attendees** with buffs when the party concludes
4. **Build reputation** — completed parties earn stamps, unlocking riskier locations

The system is built around a single key item: the **Stamp Card**.

---

## The Stamp Card

A personal item given to the Ex Great Brother on spawn. It serves as the controller for all party interactions. Using the card in hand opens a **TGUI interface** that shows everything at a glance.

The card tracks:
- **Stamps earned** — one per completed party, with the area name recorded
- **Currently active party** — only one party at a time
- **Unlocked locations** — determined by stamp count + round time

### TGUI Interface

Using the stamp card in hand (`attack_self`) opens a TGUI window with the following sections:

#### 1. Stamp Collection (Top)
- Visual grid of earned stamps, each showing the area name and an icon
- Total stamp count displayed prominently

#### 2. Party Locations (Middle)
- List of all party locations grouped by tier
- Each location shows: name, unlock status (locked/unlocked), requirements if locked
- Unlocked locations have a "Start Party" button (greyed out if conditions aren't met — wrong area, not enough people, etc.)
- Current area is highlighted if it matches a valid location

#### 3. Active Party Panel (Bottom, only shown during party)
- Party timer (elapsed time, minimum 5 min to end)
- Current attendee count
- "Spawn Items" section — grid of purchasable items with ahn costs
- "End Party" button (enabled after 5 min)
- Host warnings (if applicable)

### `ui_data()` provides:
- `stamps` — list of completed stamp area names
- `stamp_count` — total stamps
- `unlocked_locations` — list of currently unlocked location data
- `current_area` — the area the user is in (for highlighting)
- `party_active` — whether a party is running
- `party_time_elapsed` — seconds since party started
- `party_can_end` — whether 5 min has passed
- `party_attendees` — count of current attendees
- `player_ahn` — current ahn balance
- `items` — list of spawnable items with name, cost, description

### `ui_act()` handles:
- `"start_party"` — with `area_type` param
- `"spawn_item"` — with `item_type` param
- `"end_party"` — triggers party conclusion

---

## Party Locations

Locations are gated by a combination of round time and stamp count. The nursefather starts with safe, public locations and earns access to riskier territory as the round progresses and they build a track record.

### Tier 1 — Always Available (Round Start)

| Area | Name | Flavor |
|------|------|--------|
| `/area/city/house` | Employee Housing | A cozy spot for a low-key gathering |
| `/area/city/shop` | Shop | Party among the shelves |
| `/area/city/bar` | The Alibi | The natural party venue |
| `/area/city/library` | Library | A "quiet" celebration |
| `/area/city/bistro` | The Bistro | Wine, food, and good company |
| `/area/city/carnival` | Carnival Base | Already festive — just needs a host |
| `/area/city/clinic` | Clinic | Nothing heals like a good time |

### Tier 2 — Unlocked after 30 minutes OR 2 stamps

| Area | Name | Flavor |
|------|------|--------|
| `/area/city/hhpp` | HamHamPangPang | The arcade deserves a proper party |
| `/area/city/fixers` | Fixer Office | Bringing the party to the professionals |
| `/area/city/roaming_base` | Roaming Fixers Office | Freelancers need fun too |

### Tier 3 — Unlocked after 60 minutes AND 3 stamps

| Area | Name | Flavor |
|------|------|--------|
| `/area/city/hana` | Hana Office | Crashing the corporate scene |
| `/area/city/assoc_base` | Association Office | Party in the syndicate's own turf |
| `/area/city/antag_base` | Abandoned Hideout | The ultimate bold move |

---

## Starting a Party

The nursefather doesn't ask permission. They break down the door, walk in, and declare it a party. The owners of the building aren't consulted — the Middle's reputation and the nursefather's sheer physical presence are enough to keep anyone from objecting. If someone has a problem with it, well, that's what Laevateinn is for.

### Requirements
1. The nursefather must be in a valid, unlocked party area
2. At least **3 living humans** (including the nursefather) must be visible in the area
3. No other party is currently active
4. Party cooldown has expired (if applicable)

No access or ownership checks — the nursefather is not asking, they are *telling*.

### What Happens
- Area-wide announcement: *"[Name] declares this a party zone! The Middle's celebration begins!"*
- All humans in the area receive a chat notification
- The party timer begins (minimum 5 minutes before it can be ended)
- The TGUI updates to show the active party panel with item spawning

### Host Presence
The nursefather **must stay in the party area** for the entire duration. If they leave:
- First warning: *"You're drifting from the party! Get back in there!"*
- Second warning: *"The party's losing its host! Return now!"*
- Third warning: Party is **cancelled** — no rewards, no stamp

If the host dies, the party is also cancelled.

---

## Party Items (Spawnable via TGUI)

During an active party, the nursefather can spend **ahn** to spawn items via the stamp card's TGUI. Items appear at the nursefather's feet. Organized into categories:

### Drinks (Booze & Beverages)

| Item | Cost | What Spawns |
|------|------|-------------|
| **Beer Keg** | 300 ahn | Beer keg — tap and pour for everyone |
| **Bottle Service** | 200 ahn | 3 random premium bottles (whiskey, vodka, rum, champagne, cognac, wine, tequila) |
| **40oz Malt Liquor** | 50 ahn | Single malt liquor bottle — the classic |
| **Soda Cooler** | 100 ahn | 5 random soda cans (cola, lemon-lime, dr_gibb, grey_bull, thirteenloko) |
| **Sake Set** | 150 ahn | 2 bottles of sake |

### Food

| Item | Cost | What Spawns |
|------|------|-------------|
| **Pizza Delivery** | 150 ahn | 3 random pizzas (margherita, meat, mushroom, vegetable) |
| **Snack Spread** | 100 ahn | Assorted — chips, nachos, popcorn, cheesie honkers, jerky |
| **Nacho Platter** | 100 ahn | 3 plates of cheesy nachos + cuban nachos |
| **Burger Run** | 150 ahn | 3 random burgers |
| **Donut Box** | 100 ahn | 6 random donuts (plain, jelly, chocolate, berry, caramel) |
| **Birthday Cake** | 200 ahn | 1 birthday cake — enough slices for the whole party |
| **Fries & Rings** | 75 ahn | 3 fries + 2 onion rings |
| **Candy Bowl** | 75 ahn | Assorted candy — chocolates, lollipops, gumballs, candy corn |

### Entertainment

| Item | Cost | What Spawns |
|------|------|-------------|
| **Disco Ball** | 500 ahn | Indestructible dance machine — music + lights, no access needed |
| **Toy Box** | 100 ahn | 3 random toys (toy swords, snap pops, foam blades, water balloons) |
| **Card Deck** | 75 ahn | Playing cards — poker night |
| **Dice Set** | 75 ahn | Bag of assorted dice (d4 through d20) — gambling time |
| **Instrument Set** | 200 ahn | 2 random instruments (guitar, sax, trumpet, harmonica, electric guitar) |
| **Fireworks Box** | 150 ahn | Box of fireworks — celebrate in style |
| **Balloon Bundle** | 50 ahn | 5 random-color balloons — instant party decor |
| **Plushie Pile** | 100 ahn | 3 random plushies from the LC13 collection |
| **Beach Balls** | 50 ahn | 2 beach balls — toss them around |

### Atmosphere

| Item | Cost | What Spawns |
|------|------|-------------|
| **Cigar Box** | 100 ahn | 3 premium Havana cigars |
| **Furniture Set** | 200 ahn | 2 comfy chairs + 1 wooden table — instant lounge |
| **Gangster Kit** | 150 ahn | 2 fedoras + 2 sunglasses — dress the part |
| **Snap Pops** | 25 ahn | 5 snap pops — cheap fun, pop on impact |

---

## Ending a Party

### Requirements
- Party has been active for at least **5 minutes**
- The nursefather triggers it manually via the "End Party" button in the TGUI

### What Happens
1. Area-wide announcement: *"The party wraps up! Everyone leaves feeling refreshed."*
2. All living humans currently in the party area receive the **Party Buff**
3. Role-specific bonuses are applied (civilians, association members)
4. A **stamp** is added to the stamp card, recording the area
5. Party cooldown begins

---

## Party Buff

A 25-minute status effect applied to all attendees when the party concludes. Each area grants a unique, thematic buff that goes beyond simple stat increases — the location you party at determines what kind of edge you walk away with.

### Base Effect (All Attendees)
- **Passive sanity healing**: -2 sanity loss every 10 seconds
- **Subtle purple glow** via `set_light(2, 1, "#9932CC")` — you've been to a Middle party, and it shows

### Area-Specific Buffs

Each location grants a distinct combat or survival buff. Higher-tier locations give stronger effects.

#### Tier 1 — Safe Locations

| Area | Buff Name | Effect |
|------|-----------|--------|
| Employee Housing | *"Home Comfort"* | +10 Prudence, take **10% less WHITE damage** (`white_mod *= 0.9`) |
| The Alibi | *"Liquid Courage"* | +15 Fortitude, deal **10% more RED damage** (`red_mod` on attacks) |
| Library | *"Studied Mind"* | +10 Prudence, +10 Justice, take **10% less BLACK damage** (`black_mod *= 0.9`) |
| The Bistro | *"Well Fed"* | +10 Fortitude, +10 Temperance, passive **HP regen** (-1 brute/fire per tick) |
| Carnival Base | *"Showtime"* | +15 Justice, **movement speed boost** (`multiplicative_slowdown = -0.3`) |
| Clinic | *"Patched Up"* | +10 Prudence, **enhanced sanity heal** (-5/tick instead of -2), take **10% less PALE damage** |

#### Tier 2 — Moderate Risk

| Area | Buff Name | Effect |
|------|-----------|--------|
| HamHamPangPang | *"Masterwork Cooking"* | +15 Fortitude, +10 Temperance, **inflict 2 Bleed on hit** (10s cooldown) |
| Fixer Office | *"Professional Edge"* | +15 Justice, +10 Fortitude, deal **10% more BLACK damage** |
| Roaming Fixers Office | *"Freelancer's Grit"* | +15 Fortitude, +15 Justice, take **15% less RED damage** (`red_mod *= 0.85`) |

#### Tier 3 — High Risk

| Area | Buff Name | Effect |
|------|-----------|--------|
| Hana Office | *"Corporate Raid"* | +10 all stats, **5% lifesteal on hit** (heal 5% of damage dealt as HP) |
| Association Office | *"Syndicate Bonds"* | +10 all stats, +50 association EXP, **inflict 2 Overheat on hit** (10s cooldown) |
| Abandoned Hideout | *"Hideout Hustle"* | +20 Fortitude, +20 Justice, deal **15% more RED damage**, take **10% less from all 4 core types** |

### Role-Specific Bonuses (Applied Once on Party End)

| Role | Bonus |
|------|-------|
| **Civilians** | **Permanent** +3 to all attribute levels (not a buff — actual level increase, stacks across parties) |
| **Association Members** | +50 EXP toward their association |

### Implementation Notes

**Damage modifiers** use `owner.physiology` vars:
- `red_mod`, `white_mod`, `black_mod`, `pale_mod` — multiply to reduce incoming damage
- Outgoing damage bonus: register `COMSIG_MOB_ITEM_ATTACK` signal, apply bonus damage via `deal_damage()`

**On-hit debuffs** (Bleed/Overheat): register `COMSIG_MOB_ITEM_ATTACK`, apply with a cooldown var on the status effect to prevent spam.

**Lifesteal**: register `COMSIG_MOB_ITEM_ATTACK`, calculate 5% of damage dealt, `adjustBruteLoss(-amount)` on the attacker.

**Speed boost**: `add_movespeed_modifier()` with custom `/datum/movespeed_modifier` subtype.

**Payday modifier**: modify `owner.get_bank_account().payday_modifier`.

### Buff Removal
After 25 minutes, all effects are cleanly reversed:
- Physiology mods divided back (`red_mod /= 0.9` etc.)
- Attribute buffs reversed via `adjust_attribute_buff` with negative values
- Movespeed modifier removed
- Signal handlers unregistered
- Light turned off

All granted values are stored as vars on the status effect so removal is exact.

---

## Calling in Favors (Car Phone)

The Ex Great Brother's car phone (`/obj/item/middle_car_phone`) already summons the Middle's speedwagon. This feature adds a second use: **calling siblings to wire ahn**.

### How It Works

Using the phone in hand opens a choice: **"Call Car"** (existing) or **"Call in a Favor"** (new).

Calling in a favor:
1. Player is prompted to input an amount (1 to 1,500 ahn max)
2. 2-second `do_after` — the nursefather makes a call
3. Flavor dialogue: picks a random line like *"Hey, it's me. I need a little something wired over..."* or *"Brother, cash me out. I'll make it up to you."*
4. After a short delay (3-5 seconds), the requested ahn is deposited into the nursefather's bank account
5. Message: *"Your phone buzzes. [amount] ahn has been wired to your account."*

### Amounts & Thresholds

Player chooses how much to request, up to **1,500 ahn** per call.

| Total Withdrawn | Consequence |
|-----------------|-------------|
| Under 8,000 ahn | No warning — siblings are happy to help |
| Over 8,000 ahn | Player warning: *"Your contact sounds hesitant. 'You're racking up quite a tab, brother...'"* + **admin notification** via `message_admins()`: *"[Name] (Middle Nursefather) has called in [total] ahn in favors this round."* |

### Limits
- **Cooldown**: 2 minutes between favor calls
- **No hard cap** — the nursefather can keep calling, but admins are watching past 10k
- Tracked via a var on the phone: `var/total_favors_withdrawn = 0`

### Bank Account Access
Uses `user.get_bank_account()` to find the account, then `account.adjust_money(amount)` to deposit.

### Flavor Lines (Random Pick)
- *"Hey, it's me. Wire me something, yeah? ...Good lookin' out."*
- *"Brother, I need a favor. The usual. ...You're the best."*
- *"Listen, I'm throwin' a little get-together. Need some funds. ...Appreciate it."*
- *"It's your favorite sibling. Cash me out, I'll owe you one. ...Heh, another one."*
- *"I need ahn. Don't ask. ...Thanks, you're a real one."*

---

## Door Forcing (Laevateinn)

The Ex Great Brother can force open any door by prying it with Laevateinn, similar to how the Jaws of Life (`/obj/item/crowbar/power`) forces airlocks open. However, unlike the Jaws of Life, Laevateinn **does not damage the door** — it's a clean forced entry.

### Implementation
Laevateinn functions like a crowbar with `force_opens = TRUE` when used on doors. The existing airlock system already supports this via `try_to_crowbar()` with the `forced` parameter, which triggers `do_after` then calls `open(2)` to bypass access. The key difference:
- The door's `take_damage(25, BRUTE, 0)` call that normally accompanies a Jaws of Life pry is **skipped** — Laevateinn pries cleanly
- Works on any door, powered or unpowered, regardless of access level

### Details
- **Trigger**: Attacking a closed door (`/obj/machinery/door`) with Laevateinn (any seal stage)
- **Action**: 3-second `do_after` pry animation (interruptible if moved/stunned)
- **Result**: Door opens via `open(2)`, bypassing all access — **no damage to the door**
- **Sound**: `middlefather_blunt2.ogg`
- **Message**: *"[Name] wrenches the door open with brute force!"*

This reinforces the Middle's philosophy: no door stands between them and what they want. They don't need to destroy it — they just need it open.

---

## Loadout Changes

The stamp card is added to the Ex Great Brother's starting equipment:
- Given alongside existing gear (Laevateinn, armor, recruitment scroll, etc.)
- Included in both the normal recruitment loadout and the debug transform item
- Briefing text explains the party system to the player

---

## Design Philosophy

The party system is designed to:
1. **Encourage roleplay** — the nursefather has a reason to interact with everyone, not just fight
2. **Create risk/reward** — higher-tier locations are in dangerous territory but give better buffs
3. **Benefit the whole server** — civilians and association members both gain from attending
4. **Feel earned** — stamp progression gates the riskiest locations behind experience
5. **Stay in character** — the Middle treats their people like family; parties are how the nursefather shows "care" (superficially, through spending and spectacle)
6. **Gangster college party vibe** — fedoras, cigars, malt liquor, disco balls, premium bottles, and fireworks
