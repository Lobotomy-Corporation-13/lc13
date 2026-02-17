== Dieci Association (Section 4) — "The Scholar" ==

Dieci are the scholar-monks of the City. They collect knowledge through acts of charity — healing the injured, training civilians, hosting community events, and studying the world around them. They convert the knowledge gained from helping others into raw combat power, channeling accumulated wisdom through their fists and keys.

Dieci are '''not heroes'''. They provide charity because it fuels their pursuit of knowledge, not out of altruism. If no one is paying, they have no obligation.

For general information about the association system (contracts, EXP, setup), see the [[Skill Tree Associations|main Association page]].

=== Faction Goals ===

* Gather knowledge through acts of charity — healing, teaching, feeding, studying
* Host public events that benefit the community
* Convert accumulated knowledge into combat power when needed

=== Earning EXP ===

Dieci earn EXP through charity and study. Their thematic activities are:

* '''Passive EXP''' — '''1 EXP''' every 10s while on a '''duration-based contract''' (does not activate off-contract or on objective-based contracts)
* '''Bestiary scan''' — '''1 EXP''' for scanning a new hostile mob type with the Knowledge Tome (once per mob type)
* '''Examine dead body''' — '''3 EXP''' for NPC bodies (not player-controlled) or '''5 EXP''' for player bodies. Examined with the Tome (5s channel, once per body until revived)
* '''Observe combat''' — '''1 EXP''' per attack/damage event on the observed target (20% chance per event). Use the Tome on a carbon to mark them for observation (7 tile range)
* '''Healing Kit use''' — '''2 EXP''' (Basic), '''3 EXP''' (Standard), or '''5 EXP''' (Advanced) per heal
* '''Blessed Food consumed''' — '''2 EXP''' when someone eats food you blessed with Sacred Seasoning (must see the eater)
* '''Event tick completed''' — varies by event type (see Public Events below)
* '''Contract completion''' — Duration-based contracts: '''25 EXP''' (6 min), '''38 EXP''' (10 min), or '''63 EXP''' (20 min). Objective-based contracts (Patrol Route, Eliminate Target, Host Event, Medical Relief): '''76 EXP''' on completion (no passive tick, but higher completion reward)

Even without an active contract, Dieci can earn EXP at '''half rate''' by scanning creatures, healing others, and gathering knowledge entries.

=== Contract Types ===

In addition to the universal contracts (Patrol Route, Eliminate Target, Escort Person), Dieci have three unique contract types:

{| class="wikitable"
!Contract Type
!Cost
!Description
!Completion
|-
|Host Event
|'''1250 ahn''' (flat)
|Host a specific public event type (Book Reading, Training Session, or Charity Sermon). The contract marks a location via the '''Contract City Map'''. The Dieci can set up their event '''anywhere''', but hosting it at the '''marked location''' grants '''bonus EXP''' (all event tick EXP is doubled).
|All event ticks completed successfully.
|-
|Medical Relief
|'''1000 ahn''' (flat)
|Heal a specified number of '''different people''' using Healing Kits. Each unique person healed increments the counter — healing the same person twice does not count again.
|Target patient count met.
|-
|Tend to Person
|'''500 / 875 / 1500 ahn''' (6/10/20 min)
|Target a specific player. Keep them healthy by healing them when injured and feeding them Sacred Seasoning. Timer '''only ticks while at least one association member is near the target and they are above 50% HP''' — if the target drops below 50% or no one is nearby, the timer pauses. Healing the target gives '''+50% bonus EXP''' per heal. Sacred Seasoning fed to the target gives '''double EXP'''.
|Duration expires while maintaining proximity and target health.
|}

The client pays upfront when creating the contract. Hana has unlimited funds; civilians pay from their own wallet. If the contract is declined or discarded, the payment is refunded. For universal contract costs, see the [[Updated Zwei Association|the main Association page]].

'''Contract Indicators:'''
* Host Event contracts show the marked location on the Dieci's HUD. The event can be hosted '''anywhere''', but hosting at the marked location doubles event tick EXP
* Medical Relief contracts show a counter: ''"Patients healed: 3/8"''
* Tend to Person contracts show the '''target's name'''. While near the target, the Dieci receives periodic EXP notifications confirming proximity is being tracked

=== Core Mechanic — Knowledge Tome & Active Knowledge ===

The Dieci's unique item is the '''Knowledge Tome''' — a sacred book that serves as their EXP interface, event launcher, knowledge storage, bestiary, and item shop. It is given on registration.

'''Active Knowledge''' is the Dieci's combat resource. Each time the Dieci performs a charity activity, they gain an '''Active Knowledge entry''' — a short piece of information with flavor text describing what they learned. For example:

* '''From healing:''' ''"[target]'s wounds were deep lacerations across their forearm..."''
* '''From blessed food:''' ''"[target]'s reaction to the food was a moment of quiet relief..."''
* '''From examining:''' ''"[target] exhibited unusual bone structure suggesting rapid growth..."''
* '''From events:''' ''"The attendees responded to the reading with rapt attention..."''

==== The Knowledge Loop ====

# '''Gain Active Knowledge''' — Perform charity activities. Each generates an Active Knowledge entry (viewable via a Dieci action that lists all current entries with their flavor text).
# '''Record into Tome''' — Use the Tome in hand → 3-second channel → all current Active Knowledge entries are '''copied into the Tome''' as stored knowledge. '''Active Knowledge is kept''' — recording is a backup, not a transfer. '''Each entry can only be recorded once''' — re-recording the same entry does nothing.
# '''Consume in combat''' — Dieci combat skills and weapon empowerment '''consume Active Knowledge entries''' to power up. When Active Knowledge is empty, combat skills stop functioning.
# '''Re-read the Tome''' — Use the Tome in hand → 3-second channel → '''restore Active Knowledge''' from stored entries. Each stored entry can only be re-read a '''limited number of times''' based on its level (see below). Once an entry's re-reads are exhausted, it is removed from stored knowledge.
# '''Cycle repeats''' — Re-reading restores consumed knowledge, but stored entries eventually run out of re-reads. Doing more charity generates '''new''' entries (and EXP) to replenish both Active and Stored.

'''Key rules:'''
* '''Max Active Knowledge:''' 20 entries (can be increased by skill tree)
* '''Recording:''' Copies Active → Stored ('''Active is kept'''). 3-second channel. '''Each entry can only be recorded once''' — entries already in the Tome are skipped.
* '''Re-reading:''' Restores Stored → Active (up to max). Each stored entry has limited re-reads based on level. 3-second channel.
* Active Knowledge entries from charity activities are generated '''in addition to''' EXP — doing charity gives both EXP (permanent) and Active Knowledge (consumable)

'''Re-read Limits by Level:'''

{| class="wikitable"
!Level
!Re-reads Available
|-
|Level 1
|6
|-
|Level 2
|5
|-
|Level 3
|4
|-
|Level 4
|3
|-
|Level 5
|2
|}

Lower-level knowledge can be re-read many times, while high-level synthesized knowledge is more fragile — use it wisely.

==== Knowledge Types & Levels ====

Active Knowledge entries come in '''4 types''', each tied to different activities:

{| class="wikitable"
!Type
!Source Activities
!Flavor
|-
|'''Behavioral'''
|Observing combat, examining living mobs
|Fighting patterns, reactions, tendencies, biology
|-
|'''Medical'''
|Healing Kit use, examining dead non-player bodies
|Wound treatment, recovery, physiology, autopsy
|-
|'''Spiritual'''
|Sacred Seasoning, Events, examining dead player bodies
|Emotional responses, morale, faith, mortality
|}

Each entry also has a '''level''' (1-5):

{| class="wikitable"
!Level
!How to Obtain
|-
|'''Level 1'''
|Observe combat, Examine living mob, Basic Healing Kit, Sacred Seasoning, Events
|-
|'''Level 2'''
|Standard Healing Kit, Examine dead non-player body, or synthesize 3x Level 1
|-
|'''Level 3'''
|Advanced Healing Kit, Examine dead player body, or synthesize 3x Level 2
|-
|'''Level 4'''
|Synthesize 3x Level 3
|-
|'''Level 5'''
|Synthesize 3x Level 4
|}

'''Knowledge Synthesis:''' Combine '''3 Active Knowledge entries of the same type and level''' to create '''1 entry of the next level''' (same type). Performed via the Tome's interface. Types must match — you cannot combine Behavioral + Medical. Level 5 is the maximum.

Reaching high levels takes significant investment: Level 4 requires 9x Level 1 entries (3→1, 3→1, 3→1). Level 5 requires 27x Level 1 entries.

'''How types and levels matter for combat:'''
* Each '''combo finisher''' requires a '''specific knowledge type''' to activate its bonus effect. If you lack that type, only the base damage hit happens:
** '''Behavioral''' — Quick Strike (H) and Pressure Combo (LLH). Gained from observing combat and examining living mobs.
** '''Medical''' — Sweeping Blow (LH) and Overwhelming Barrage (LLLH). Gained from Healing Kit use and examining dead non-player bodies.
** '''Spiritual''' — Grand Finale (LLLLH) and Measured Finisher (LLLLL). Gained from Sacred Seasoning use, events, and examining dead player bodies.
* Higher-level knowledge gives '''stronger effects''' when consumed — finisher effects scale directly with level (Level 3 gives 3x the effect of Level 1, Level 5 gives 5x)
* Each knowledge type is also tied to a '''skill branch''' (Behavioral → Scholar, Medical → Warden, Spiritual → Sage), creating resource tension between skill effects and combo finishers

=== Charity Items (Purchased from Tome Shop) ===

The Knowledge Tome has a '''shop tab''' where the Dieci can purchase charity items using ahn from their ID card bank account:

{| class="wikitable"
!Item
!Cost
!Uses
!Effect
!EXP per Use
|-
|Basic Healing Kit
|200 ahn
|20
|Heal 10 brute + 10 burn per use (3s channel, chains automatically)
|2 EXP
|-
|Standard Healing Kit
|400 ahn
|40
|Same as basic, more uses
|3 EXP
|-
|Advanced Healing Kit
|800 ahn
|80
|Same as basic, most uses
|5 EXP
|-
|Sacred Seasoning
|200 ahn
|3
|Apply to food → heals 15 SP when eaten
|2 EXP (must see eater)
|}

'''Healing Kit Mechanic:''' Click a target with the kit to begin a '''3-second channel'''. On success, heal 10 brute + 10 burn → earn EXP → the kit '''automatically starts the next channel'''. The chain continues until the Dieci moves, the target moves, the target is fully healed, or the kit runs out of uses. You '''cannot use it on yourself''' — only on others. '''No EXP is earned if the target is a Dieci association member.'''

'''Sacred Seasoning:''' Click food with the seasoning to bless it. Anyone who eats the blessed food heals 15 SP. The Dieci earns EXP '''only if they can see the eater''' — witnessing the act of charity is required. '''No EXP is earned if the eater is a Dieci association member.'''

=== Tome Targeting ===

Using the Knowledge Tome on a target within '''7 tiles''' does different things depending on the target type:

* '''Simple mobs''' (hostile creatures) — '''Bestiary scan.''' Adds the mob to your bestiary (see below).
* '''Carbons''' (players/humans) — '''Mark for observation.''' Begins tracking the target's combat activity (see below).

=== Bestiary ===

The Knowledge Tome has a built-in '''Bestiary''' — a database that stores detailed combat information about scanned creatures. Use the Tome on any simple mob within '''7 tiles''' to scan it.

* '''First scan of a mob type:''' Records the creature's full combat data (health, resistances, damage, attack speed, ranged info) and adds it to the bestiary. Awards '''1 EXP''' and generates 1 '''Behavioral''' Active Knowledge entry (level scales with the mob's max HP).
* '''Already scanned type:''' ''"This type of [name] is already in your tome."'' — no duplicate entries.
* '''Viewing:''' The bestiary has a page-based interface showing each scanned creature's icon, vital statistics, damage resistances (color-coded), and a field for personal notes.

=== Observation ===

Use the Tome on a carbon (player/human) within '''7 tiles''' to mark them for '''observation'''. While the target is marked:

* The Dieci tracks when the target '''takes damage''' (must be more than '''10 damage''' to count)
* Each qualifying damage event has a '''20% chance''' to generate '''1 EXP''' and 1 '''Behavioral''' Active Knowledge entry (Level 1)
* The Dieci must have '''line of sight''' to the observed target to earn EXP — walls and obstructions block observation
* '''Dieci members cannot observe each other''' — the Tome will not mark fellow association members
* Only '''one target''' can be observed at a time — marking a new target replaces the old one
* Observation has no range limit once marked, but the Dieci must be able to '''see''' the target

=== Public Events ===

The '''Dieci Director''' can use their Tome to '''host public events''' — extended group activities that benefit attendees and generate large amounts of EXP and Active Knowledge. Events are the fastest way to progress but require time, ahn, and active participation. '''Only the Director can create events''' — Veterans and Associates cannot.

'''How events work:'''
# Use the Tome in hand → select event type → ahn cost is deducted
# A '''visible event zone''' (5-tile radius) is created centered on where you activated the Tome
# A visible announcement goes out: ''"[user] is hosting a [Event Name]! Gather around!"''
# The event consists of '''ticks''' — periodic check-ins where you must use the Tome in hand within the zone
# Each tick: Use Tome → '''5-second channel''' → on success, you say a line aloud → tick completes → attendees receive benefits
# '''The Tome can only be activated within the event zone.'''
# '''If any tick is missed or interrupted, the event ends immediately.''' No ahn refund.
# Between ticks, you are free to '''move around, talk, and RP''' with attendees
# Cooldown: '''5 minutes''' between events

'''Dieci at events:''' Dieci association members present in the event zone '''do not count as attendees''' — they do not receive per-tick benefits (SP healing, attribute boosts, ahn payouts) and do not increase the attendee count for EXP calculations. However, all Dieci in the zone still earn the '''base EXP per tick''' from the event.

==== Event 1: Book Reading (SP Healing) ====

{| class="wikitable"
!Duration
!Ahn Cost
!Ticks
!Tick Interval
!Per-Tick Benefit
!EXP per Tick
|-
|~4 minutes
|500
|6
|40s
|Attendees in zone heal '''17% of their max SP'''
|3 + 2 per attendee
|}

Attendees who stay for all 6 ticks heal '''102% of their max SP''' — effectively a full restore. When the event finishes, all attendees receive '''Spiritual Calm''' — a status effect that passively heals '''10 SP every 10 seconds''', lasting for '''1 minute per tick attended''' (up to 6 minutes for full attendance).

==== Event 2: Training Session (Attribute Boost) ====

{| class="wikitable"
!Duration
!Ahn Cost
!Ticks
!Tick Interval
!Per-Tick Benefit
!EXP per Tick
|-
|~5 minutes
|1000
|6
|50s
|Attendees gain '''+4 to ALL attributes''' for 5 minutes. Stacks with previous ticks (timer resets, bonus increases by +4, max +20)
|7 + 4 per attendee
|}

Each tick adds +4 to the attribute boost and resets the 5-minute timer. Attendees who stay for all 6 ticks reach the '''+20 cap''' by tick 5, and tick 6 refreshes the timer. The boost persists for '''5 minutes''' after the last tick attended.

==== Event 3: Charity Sermon (Ahn Generation) ====

{| class="wikitable"
!Duration
!Ahn Cost
!Ticks
!Tick Interval
!Per-Tick Benefit
!EXP per Tick
|-
|~7 minutes
|1800
|7
|60s
|255 ahn split among attendees (up to 85 each). With 4+ attendees, per-person payout decreases so total distributed never exceeds the 1800 ahn event cost
|16 + 10 per attendee
|}

With '''3 or fewer''' attendees, each earns '''85 ahn per tick''' (595 total over 7 ticks). With '''4+''' attendees, the 255 ahn per-tick budget is split evenly — e.g., 4 attendees = 63 each, 5 = 51 each. The Dieci earns '''no ahn''' from this event — it is pure charity. Highest EXP reward to compensate.

'''EXP Examples:'''
* Book Reading with 3 attendees: (3 + 2×3) × 6 = '''54 EXP'''
* Training Session with 3 attendees: (7 + 4×3) × 6 = '''114 EXP'''
* Charity Sermon with 3 attendees: (16 + 10×3) × 7 = '''322 EXP'''

=== Tome & Bookcase Interaction ===

Dieci Tomes can be '''stored in any bookcase'''. Stored tomes '''retain their stored knowledge entries''', so the Dieci can build a personal library over time. Additionally, Dieci can '''retrieve a new blank tome''' from any bookcase. 

=== Weapons and Armor ===

Dieci gear is distributed from the equipment box by the Director.

Dieci fixers use two weapon types: '''Fists''' (combat gloves) and '''Keys''' (oversized ceremonial keys). Both share the same '''L/H combo system''' — Light attacks (L) are basic RED damage swings that cost nothing, Heavy attacks (H) are empowered PALE strikes that require consuming Active Knowledge.

==== Empowerment (L/H System) ====

Press '''use in hand''' to consume 1 Active Knowledge entry ('''minimum level 3''', lowest qualifying level first) and '''empower''' your next attack. The next melee hit becomes an '''H (Heavy)''' attack:

* '''PALE''' damage instead of RED
* '''Fists bonus:''' Grants shield HP = knowledge level × 15
* '''Keys bonus:''' Grants Offense Level Up = knowledge level × 2
* '''Instant kill''' against carbon targets who are '''insane''' (0 SP)

'''L (Light)''' attacks are basic RED damage swings that cost nothing, but they apply '''2 Sinking''' stacks to the target on hit. This means even unempowered attacks steadily build Sinking. Only H inputs cost knowledge. You empower one attack at a time (no stacking).

==== Combo Table ====

L inputs advance the combo chain for free. H inputs cost 1 knowledge each (via use in hand). On the combo finisher, the weapon consumes the '''highest level''' entry of a '''specific knowledge type''' for a bonus effect. If you have no knowledge of that type, only the base damage hit happens.

{| class="wikitable"
!Combo
!Input
!Base Hit
!Required Knowledge
!Finisher Effect (scales with level)
|-
|Quick Strike
|H
|force × 1.3
|'''Behavioral'''
|Apply level × 3 Sinking
|-
|Sweeping Blow
|LH
|force × 1.2
|'''Medical'''
|Throw target 2 + level tiles. Apply level × 2 Sinking on landing.
|-
|Pressure Combo
|LLH
|force × 1.3
|'''Behavioral'''
|Apply level × 2 Sinking and level Defense Level Down
|-
|Overwhelming Barrage
|LLLH
|level × 5 rapid hits (5-25), each hit deals force × 0.08. Max total: force × 2 at 25 hits
|'''Medical'''
|Each hit applies 1 Sinking. Higher level = more hits = more damage and Sinking
|-
|Measured Finisher
|LLLLL
|force × 1.5
|'''Spiritual'''
|Apply Sinking = target's current stacks × (0.1 × level) (max 50). Higher level = bigger multiplier (L1: ×0.1, L3: ×0.3, L5: ×0.5)
|-
|Grand Finale
|LLLLH
|force × 1.5
|'''Spiritual'''
|Throw target 3 + level tiles. PALE shockwave on landing in 1 + level tile radius dealing level × 8 PALE damage and level × 3 Sinking
|}

Note: '''LLLLL is completely free''' — no H input means no empowerment cost. Its finisher effect still consumes knowledge of the required type if available. '''LLLH''' triggers the barrage on the H input; the number of rapid hits scales with the consumed Medical knowledge level (Level 1 = 5 hits, Level 5 = 25 hits). Each hit deals the same damage (force × 0.08), so total damage scales with hits: Level 1 = force × 0.4, Level 5 = force × 2. Each hit applies 1 Sinking stack.

==== Fists ====

Defensive empowerment (shield HP on H attacks). Lower base damage, faster attacks.

{| class="wikitable"
!Weapon
!Role
!Force
!Attack Speed
!Damage Type
!Notes
|-
|Dieci Combat Gloves
|Associate (80 attrs)
|20
|0.7
|RED (L) / PALE (H)
|H attacks grant shield HP = level × 15
|-
|Dieci Veteran Gloves
|Veteran (100 attrs)
|28
|0.7
|RED (L) / PALE (H)
|Same empowerment bonus
|-
|Dieci Director Fists
|Director (120 attrs)
|38
|0.6
|RED (L) / PALE (H)
|Same empowerment bonus, fastest attack speed
|}

==== Keys ====

Offensive empowerment (Offense Level Up on H attacks). Higher base damage, slower attacks.

{| class="wikitable"
!Weapon
!Role
!Force
!Attack Speed
!Damage Type
!Notes
|-
|Dieci Ceremonial Key
|Associate (80 attrs)
|26
|0.9
|RED (L) / PALE (H)
|H attacks grant OLU = level × 2
|-
|Dieci Veteran Key
|Veteran (100 attrs)
|35
|0.85
|RED (L) / PALE (H)
|Same empowerment bonus
|-
|Dieci Director Key
|Director (120 attrs)
|48
|0.8
|RED (L) / PALE (H)
|Same empowerment bonus, highest base damage
|}

==== Armor ====

{| class="wikitable"
!Armor
!Role
!RED
!WHITE
!BLACK
!PALE
!Notes
|-
|Dieci Standard
|Associate (80 attrs)
|30
|10
|20
|20
|Standard issue (x2)
|-
|Dieci Veteran
|Veteran (100 attrs)
|30
|10
|30
|30
|
|-
|Dieci Director
|Director (120 attrs)
|40
|20
|30
|30
|
|}

==== Core Debuff — Sinking ====

Dieci's debuff identity is '''Sinking'''. Unlike Zwei (Defense Level Up) or Seven (Rupture), Dieci apply '''Sinking''' stacks through empowered H attacks and combo finishers.

* '''Max 50 stacks''', '''5-second activation delay''' on first application
* Once active: '''WHITE''' or '''PALE''' damage triggers it → SP damage = stacks (humans) or WHITE × 4 (mobs), then halves stacks
* L attacks (RED) '''apply 2 Sinking stacks''' per hit, steadily building stacks through basic combat
* H attacks (PALE) '''trigger''' existing Sinking — empowered hits detonate the stacks your L attacks built up

=== Skill Tree ===

Dieci has '''3 branches'''. You can invest in a '''maximum of 2''' — choose carefully.

Each branch has 3 tiers with 2 choices per tier (pick one). Tier costs: T1 = 1 point, T2 = 2 points, T3 = 3 points. Full investment in one branch = 6 points.

'''Branch Knowledge Types:''' Each branch has a preferred Active Knowledge type. Some stronger skill effects consume that type for enhanced effects:
* '''Scholar''' → '''Behavioral''' (study combat patterns to exploit Sinking)
* '''Warden''' → '''Medical''' (healing knowledge translates to protection)
* '''Sage''' → '''Spiritual''' (enlightenment empowers buffs and support)
Each type maps to a branch (Behavioral → Scholar, Medical → Warden, Spiritual → Sage), and each type fuels 2 combo finishers. Your branch skills compete with combo finishers for the same knowledge type, creating resource management decisions.

==== Branch 1: Scholar (Sinking Focus) ====

'''Theme:''' Apply and exploit Sinking stacks. The Scholar builds Sinking with RED hits and amplifies PALE mode triggers. '''Preferred type: Behavioral.'''

{| class="wikitable"
!Tier
!Option A
!Option B
|-
|T1 (1pt)
|'''Deep Study''' — Each melee attack applies 2 Sinking stacks to the target. Additionally, on hit consume 1 '''Behavioral''' knowledge → apply extra Sinking = entry level. 5s cooldown.
|'''Analytical Strike''' — Hitting a target with no Sinking applies 8 Sinking stacks. Does nothing if the target already has Sinking.
|-
|T2 (2pt)
|'''Drowning Knowledge''' — When an empowered H attack strikes a target with 15+ '''active''' Sinking, deal 25% bonus weapon damage. Additionally, consume 1 '''Behavioral''' knowledge → deal an extra +5% bonus damage per entry level (stacks with the 25%). 5s cooldown.
|'''Spreading Decay''' — When an empowered H attack strikes a target that has Sinking (active or inactive), also apply 5 Sinking to all enemies within 2 tiles. 2s internal cooldown. Additionally, consume 1 '''Behavioral''' knowledge → also apply Defense Level Down = entry level to all affected targets. 5s cooldown.
|-
|T3 (3pt)
|'''Abyssal Revelation''' — ''See Powerful Attacks below.''
|'''Tome of Ruin''' — Every 5th consecutive empowered H attack on the same target consumes '''1 Active Knowledge''' entry, then '''immediately triggers all Sinking''' (bypasses 5s delay), applies 5 new Sinking stacks, and grants '''1 free empowerment''' (max 3 stored). If no Active Knowledge is available, the 5th hit proc does not trigger.
|}

==== Branch 2: Warden (Shield Focus) ====

'''Theme:''' Knowledge becomes a literal barrier. The Warden fights behind a shield of accumulated wisdom, absorbing punishment and retaliating through Sinking. '''Preferred type: Medical.'''

'''Core Mechanic — Shield HP:''' Dieci Fist weapons generate a '''shield''' on empowered H attacks. This shield absorbs raw incoming damage before your real HP. It '''caps at 500 HP''' and '''halves every 10 seconds''', creating a "use it or lose it" dynamic. '''If the shield reaches 0 HP, it disappears''' — you must land another empowered H attack with Fists to rebuild it. Warden skills provide additional ways to restore and interact with the shield.

{| class="wikitable"
!Tier
!Option A
!Option B
|-
|T1 (1pt)
|'''Knowledge Barrier''' — Landing melee attacks restores '''3 shield HP'''. Additionally, on hit consume 1 '''Medical''' knowledge → restore extra shield HP = entry level × 5. 5s cooldown.
|'''Reactive Ward''' — Landing melee attacks restores '''2 shield HP'''. Whenever the shield absorbs any damage, apply '''5 Sinking''' to the attacker.
|-
|T2 (2pt)
|'''Tome Shield''' — Action: consume your '''highest level Medical''' knowledge entry to restore shield HP = '''10 × entry level'''. 5s cooldown. Requires Medical knowledge.
|'''Stalwart Presence''' — Taking damage while at 50+ shield HP grants '''3 Protection''' stacks. Additionally, consume 1 '''Medical''' knowledge → heal self for entry level × 2% max HP. 5s internal cooldown.
|-
|T3 (3pt)
|'''Golden Aegis''' — ''See Powerful Attacks below.''
|'''Immovable Library''' — On hitting a target with '''active Sinking''', consume '''1 Active Knowledge''' entry and restore shield HP equal to the '''target's current Sinking stacks × 2'''. 4s internal cooldown. Requires Active Knowledge to trigger.
|}

==== Branch 3: Sage (Knowledge Enhancement) ====

'''Theme:''' Maximize the Active Knowledge economy. The Sage makes every piece of knowledge count more — longer buffs, cheaper synthesis, stronger effects, and the ability to share knowledge with allies. '''Preferred type: Spiritual.'''

{| class="wikitable"
!Tier
!Option A
!Option B
|-
|T1 (1pt)
|'''Extensive Notes''' — Max Active Knowledge increased from '''20 to 30'''. Empowered H attacks deal '''+15% bonus PALE damage'''. Additionally, on empowered H hit consume 1 '''Spiritual''' knowledge → deal extra damage = entry level × 5% weapon force. 5s cooldown.
|'''Applied Learning''' — Each time Active Knowledge is consumed (for any purpose), gain '''4 Offense Level Up''' stacks.
|-
|T2 (2pt)
|'''Shared Wisdom''' — Action: target an ally within 5 tiles. Consume 1 '''Spiritual''' knowledge entry → give the ally '''Offense Level Up stacks = knowledge level × 2'''. 15s cooldown. Requires Spiritual knowledge.
|'''Efficient Research''' — Synthesis costs '''2 entries instead of 3''' to create the next level. Consuming Level 3+ knowledge in combat refunds '''1 entry of the same type, one level lower'''. Additionally, when consuming any knowledge in combat, consume 1 '''Spiritual''' knowledge → grant 2 Offense Level Up to all allies within 3 tiles. 5s cooldown.
|-
|T3 (3pt)
|'''Grand Archive''' — ''See Powerful Attacks below.''
|'''Infinite Library''' — Active Knowledge cap increased to '''50'''. L attacks now consume the '''lowest level''' Active Knowledge entry on hit to apply '''Sinking stacks equal to the entry's level'''. 1s internal cooldown.
|}

=== Powerful Attacks ===

Each branch has one T3 option that is a '''Powerful Attack''' — a cutscene-style multi-hit combo. During the combo, the target is isolated and both combatants are immobilized. Each hit deals damage based on your weapon's DPS. All hits deal '''RED damage''' except the '''final hit''', which deals '''PALE damage''' (triggering Sinking).

==== Abyssal Revelation (Scholar T3a) ====

'''Cooldown:''' 90 seconds

'''Requires:''' At least 3 Active Knowledge entries.

'''How it works:'''
# Consume up to 5 Active Knowledge entries ('''lowest level first''')
# Shoulder-charge forward up to '''5 tiles''', grabbing the first enemy hit and '''slamming them into the ground'''
# 5-hit RED combo — all hits deal RED damage
# Each hit applies '''5 Sinking''' stacks
# '''Bonus:''' +10% total damage per '''level''' of each entry consumed (e.g., L1+L1+L2+L3+L5 = 12 levels = +120%, capped at '''100%'''). Max bonus reached with 10+ total levels
# '''Final hit:''' 1.25x DPS, deals '''PALE damage''' (the only PALE hit), and '''immediately triggers all Sinking''' on the target (bypasses 5s activation delay)
# After the combo, gain '''2 free empowerments''' (next use-in-hand presses cost no knowledge, max 3 stored)

==== Golden Aegis (Warden T3a) ====

'''Cooldown:''' 90 seconds

'''Requires:''' Active shield (must have shield HP) and at least '''1 Active Knowledge''' entry.

'''How it works:'''
# Heavy '''stomp''' that cracks the ground in a '''2-tile radius''' — enemies hit are briefly '''stunned'''. The closest enemy hit becomes the target
# 5-hit combo — first 4 hits deal '''RED damage''', final hit deals '''PALE damage'''
# '''Hits 1-4:''' Each hit tries to consume the '''lowest level''' Active Knowledge entry. If consumed, generates '''shield HP = knowledge level × 20''' (up to the 500 cap). If no Active Knowledge remains, the hit still deals damage but generates no shield
# '''Each hit''' applies '''3 Sinking''' stacks to the target
# '''Final hit:''' 1.25x DPS '''PALE damage'''. Consumes up to '''200 shield HP''' — deals '''+0.5% bonus damage per shield consumed''' (up to +100% at 200 shield), and throws the target '''shield consumed / 40''' tiles (up to 5 tiles at 200 shield). '''Immediately triggers all Sinking''' on the target
# Shield HP consumed by the final hit is '''removed''' — if this brings shield to 0, the shield disappears

==== Grand Archive (Sage T3a) ====

'''Cooldown:''' 90 seconds

'''Requires:''' At least 1 Active Knowledge entry.

'''How it works:'''
# Automatically consumes up to 5 of your '''highest level''' Active Knowledge entries
# Hurl the Tome at an enemy within '''7 tiles''', '''staggering''' them on impact — then '''rush''' in to close the distance
# Number of hits = number of entries consumed (1 to 5)
# Hits are sorted '''lowest level first, highest level last'''
# All hits deal '''RED damage''' except the final hit
# Each hit applies '''Sinking = consumed entry level × 2'''
# '''Final hit:''' 1.25x DPS, deals '''PALE damage''' (triggers Sinking), applies '''Sinking = consumed entry level × 4''' (doubled)

'''Example:''' Consuming L1, L2, L3 = 3-hit combo. Hit 1 (L1): 2 Sinking. Hit 2 (L2): 4 Sinking. Final hit (L3): 1.25x DPS PALE + 12 Sinking (6 × 2, doubled). Total: 18 Sinking applied.

=== Branch Synergies ===

You can only invest in 2 of the 3 branches. Each combination creates a different playstyle:

{| class="wikitable"
!Combination
!Playstyle
!Best For
|-
|'''Scholar + Warden'''
|"The Fortress Scholar" — Build Sinking aggressively while the shield buys time. Shield blocks with Reactive Ward apply Sinking passively; PALE mode triggers accumulated stacks. Two powerful attacks for different situations.
|Sustained 1v1 combat
|-
|'''Scholar + Sage'''
|"The Master Archivist" — Maximum Sinking application with knowledge efficiency. Never run out of knowledge, every piece of knowledge amplifies Sinking. Applied Learning + Deep Study = constant Sinking + damage buffs.
|Highest damage output
|-
|'''Warden + Sage'''
|"The Living Library" — Shield + knowledge buffs + support. Hard to kill, helps allies, and Infinite Library converts L attacks into Sinking applicators. Golden Aegis for defensive emergencies, Grand Archive for burst.
|Support + survivability
|}
