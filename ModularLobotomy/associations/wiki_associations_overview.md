This is the main page for the Association system. For details on a specific association, see the individual pages below.

<blockquote>[[Updated Zwei Association]] - Defensive specialists. Bodyguards and area defenders who protect clients and hold territory.</blockquote>
<blockquote>[[Updated Seven Association]] - Intelligence operatives. Investigators and surveillance experts who gather and sell information.</blockquote>
<blockquote>[[Dieci Association]] - Scholar-monks. Priest like fixers who study the world and provide support services.</blockquote>
<blockquote>[[Cinq Association]] - Honorbound duelists. Swordfighters who settle disputes through formal combat.</blockquote>

== What Are Associations? ==

Associations are professional organizations that operate within the City. Each association has its own specialty, culture, and methods. As a fixer employed by an association, your job is to take contracts from clients, complete them, and earn EXP to unlock combat skills from your association's skill tree.

Associations are '''not heroes'''. They are self-interested professionals who provide services in exchange for payment. Protecting, investigating, healing, or fighting — it's all business. The benefit to others is a side effect, not the goal.

Each association squad consists of:
* '''Director''' (1) - The squad leader, highest rank (120 all attributes)
* '''Veteran''' (1) - Experienced second-in-command (100 all attributes)
* '''Associate''' (3) - Rank and file fixers (80 all attributes)

Veterans and Associates can only join once a Director has spawned.

== Getting Started — Association Setup ==

=== Step 1: Director Picks an Association ===

The Director spawns with a '''Director's Beacon''' in their office. Using it presents a choice between four associations: '''Zwei''', '''Seven''', '''Dieci''', or '''Cinq'''. Picking one does the following:

* Spawns an '''equipment box''' containing weapons and armor for the entire squad
* Creates the association squad and registers the Director with the skill tree and EXP system
* Spawns an '''Association Registry''' tool and the Director's association-specific items

The beacon is single-use and cannot be re-picked.

=== Step 2: Director Registers Fixers ===

The Director receives an '''Association Registry''' — a physical logbook tool. To register a fixer, the Director '''hits them with the registry'''. This:

* Grants the fixer the skill tree and EXP system
* Spawns their association-specific items at their feet
* Adds them to the squad's ally list automatically

This works the same for roundstart spawners and late joiners. There is no auto-registration — the Director must personally use the tool on each squad member.

=== Association-Specific Items ===

When a fixer is registered, they receive items unique to their association:

{| class="wikitable"
!Association
!Item Received
!Purpose
|-
|Zwei
|''(No unique tool item)''
|Weapons and armor only
|-
|Seven
|Seven Requisition Catalog
|Shop for purchasing investigation gadgets (recorders, cameras, scanners) using ahn
|-
|Dieci
|Knowledge Tome
|EXP interface, event launcher, knowledge storage, bestiary, and item shop
|-
|Cinq
|Cinq Glove
|Used for Throw the Glove to force duels on targets (only works while on an active contract). Off-contract, use Challenge to Duel (consensual) instead.
|}

=== Weapons and Armor ===

Each association's equipment box contains weapons and armor for all squad roles. Gear has attribute requirements matching the role it is intended for:

{| class="wikitable"
!Role
!Attribute Requirement
|-
|Associate
|80 all attributes
|-
|Veteran
|100 all attributes
|-
|Director
|120 all attributes
|}

The Director distributes gear from the equipment box to the squad. See each association's page for details on their specific weapons and armor.

== Contracts ==

Contracts are the core of the association system. Contracts are tracked at the '''association level''', not per individual. When any fixer accepts a contract, '''the entire association accepts it''' — all squad members gain access to their skill tree abilities and can earn EXP. The association can have '''multiple active contracts''' at the same time.

If the association has no active contract, '''nobody''' has skill tree abilities and the passive EXP tick does not run. Fixers can still earn EXP through their association's thematic activities, but contracts are how you unlock your full power and progress faster. '''Payment is upfront''' — the client pays when the contract is created, and the association receives the funds immediately upon accepting.

=== Contract States ===

Your association is always in one of three states:

{| class="wikitable"
!State
!Skills
!EXP
!Details
|-
|'''No Active Contract'''
|Disabled
|Thematic activities only, no passive tick
|No contract is running. You can still earn EXP through your association's thematic activities (see below), but skill tree abilities are '''inactive''' and the passive EXP tick does not run.
|-
|'''Hana Contract'''
|'''Active'''
|Normal rate + passive tick
|A Hana (Administrator or Representative) created the contract from the Association Contract Terminal using unlimited funding. Skills are active and all EXP sources function normally.
|-
|'''Civilian Contract'''
|'''Active'''
|'''All EXP doubled''' + passive tick
|A non-association, non-Hana player hired you directly. Skills are active and '''all incoming EXP is doubled''' — the most rewarding state because it requires real player interaction.
|}

'''Important:''' Association fixers '''cannot''' give themselves contracts. You must always be hired by someone else.

=== Off-Contract EXP (Thematic Activities) ===

Even without a contract, fixers can earn EXP by performing their association's thematic activities — they just cannot use their skill tree abilities. This ensures you are never completely idle between contracts.

{| class="wikitable"
!Association
!Off-Contract EXP Activities
|-
|Zwei
|Taking damage while near non-association players, engaging hostile targets
|-
|Seven
|Recording people, filing intel reports, using surveillance equipment
|-
|Dieci
|Scanning creatures for knowledge, healing others, gathering knowledge entries
|-
|Cinq
|Dueling other players using Challenge to Duel (consensual — target must accept), winning duels. '''Throw the Glove''' (forced duel, no consent) '''requires an active contract.'''
|}

Off-contract EXP is earned at a '''slower rate''' than on-contract EXP (no multiplier). Contracts remain the primary way to progress — they grant the EXP multiplier and unlock your skill tree abilities.

=== Universal Contract Types ===

These contracts are available to all four associations:

{| class="wikitable"
!Contract Type
!Cost
!Description
!Completion
|-
|Patrol Route
|'''1500 ahn''' (flat)
|Mark waypoints on the city map. Visit them in order and complete the patrol loops.
|All waypoints visited and loops completed.
|-
|Eliminate Target
|'''3000 ahn''' (flat)
|Kill a specific human target.
|Target dies.
|-
|Escort Person
|'''1500 / 2500 / 4000 ahn''' (3/5/10 min)
|Stay within 7 tiles of a target, protecting them from harm. Timer '''only ticks''' while at least one association member is near the target — leaving pauses the timer.
|Duration expires while maintaining proximity.
|}

Contracts are either '''duration-based''' (3, 5, or 10 minutes with tiered pricing) or '''objective-based''' (flat cost, completes when the objective is met). Each association also has its own '''unique contract types''' tied to their specialty — see the individual association pages for details.

=== How Contracts Are Created ===

All contracts are created through the '''Association Contract Terminal''' — a physical machine with a TGUI interface. Anyone who is not an association fixer can use it. The terminal is located in the Hana's office, but '''any non-association player''' (civilians, clinic staff, Hana, etc.) can walk up and use it.

# Use the '''Association Contract Terminal'''
# Select the contract type from the available list
# For duration-based contracts, set the duration (3, 5, or 10 minutes). Pay the contract fee upfront — '''payment is taken from your wallet immediately''' (Hana has unlimited funds). Costs vary by contract type and duration.
# For location-based contracts (Patrol Route, Guard Area, Surveillance Post, Host Event), the '''Contract City Map''' opens so you can mark the relevant location or waypoints
# For target-based contracts (Eliminate Target, Escort Person, Investigate Person, etc.), click the target player to designate them
# The terminal produces a physical '''contract item''' — a paper document containing all the contract details
# Take the contract item and '''hand it to any association fixer''' — they can read it, then '''accept''' or '''decline'''
# If accepted, the association receives '''payment immediately''' and the '''entire association''' activates — all squad members gain skill access and EXP begins ticking

==== The Contract Item ====

The contract item is a physical paper document. Anyone can '''use it in hand''' to open a UI showing the full contract details — contract type, duration, payment, target, and the '''Contract City Map''' view if a location was marked. This lets both the creator and the fixer review exactly what the job entails before it is accepted.

* '''Hand it to a fixer''' to offer the contract — they get an accept/decline prompt
* If '''accepted''', the item is consumed and the contract activates
* If '''declined''', the item remains and can be offered to another fixer
* If '''discarded''' without being accepted, the payment is refunded to the creator

=== The Contract City Map ===

Several contract types require marking locations on the game map — Patrol Route waypoints, Guard Area zones, Surveillance Post locations, and Host Event sites. These use the '''Contract City Map''', an interactive map viewer built into the contract creation interface.

The city map displays a top-down view of the city, showing walls and floors. It only shows '''city areas''' — backstreets, outskirts, and ruins are filtered out. The map is displayed as a '''25x25 tile viewport''' that the user navigates with '''arrow keys''', panning one tile at a time to find the exact location they want.

'''How to use it:'''

{| class="wikitable"
!Contract Type
!Map Interaction
|-
|Patrol Route
|Click tiles to place '''numbered waypoints''' (1, 2, 3...). The fixer must visit them in order and loop. Click an existing waypoint to remove it.
|-
|Guard Area (Zwei)
|Click a '''center tile''', then define a '''radius'''. The zone is highlighted on the map. The contract timer only ticks while at least one association member is in the zone.
|-
|Surveillance Post (Seven)
|Click a tile to mark the '''surveillance location'''. The Seven fixer places recording devices here.
|-
|Host Event (Dieci)
|Click a tile to mark the '''event location'''. The Dieci must set up and run their event within the marked area.
|}

Placed markers appear as '''colored overlays''' on the map tiles, so you can see exactly where you are sending the fixer.

=== Contract Rules ===

* The association can have '''multiple active contracts''' at the same time
* Short cooldown (~30 seconds) between contracts
* For location and proximity contracts, leaving the area or client '''pauses the timer''' — it resumes when any association member returns. Contracts never fail from absence alone
* You can '''decline''' a contract offer — you are a professional, not a slave
* Contracts are either '''duration-based''' (3/5/10 minute tiers with tiered pricing) or '''objective-based''' (flat cost, no timer). Costs vary by contract type — see the universal and association-specific contract tables for exact prices

=== Why Should Civilians Hire You? ===

Clients who hire fixers receive tangible benefits depending on the contract type:

* '''Protection contracts''' grant the client '''15% damage reduction''' while the fixer is nearby
* '''Investigation contracts''' provide the client with filed intel reports and early warnings about threats
* '''Combat contracts''' get the client's problem dealt with by a professional — no need to get their own hands dirty
* '''Service contracts''' give attendees direct benefits like healing, buffs, or event participation

== EXP and the Skill Tree ==

Every association uses the same skill tree structure, but each earns EXP in its own way based on their specialty. You earn EXP by completing contracts and performing your association's thematic activities while on contract.

=== How the Skill Tree Works ===

* Each association has '''3 branches''' representing different specializations
* You can invest in a '''maximum of 2 branches''' — you must leave one empty, so choose carefully
* Each branch has '''3 tiers''' with '''2 choices per tier''' (pick one)
* Full investment in one branch costs 6 points. Two branches costs 12 points total

{| class="wikitable"
!Association
!Branch 1
!Branch 2
!Branch 3
|-
|Zwei
|Guardian
|Territory
|Client
|-
|Seven
|Analyst
|Coordinator
|Operative
|-
|Dieci
|Scholar
|Warden
|Sage
|-
|Cinq
|Duelist
|Skirmisher
|Fencer
|}

See each association's page for full details on what each branch and skill does.

==== Skill Costs ====

Each tier costs an increasing number of skill points. You must buy the previous tier in a branch before unlocking the next.

{| class="wikitable"
!Tier
!Cost
!Choices
|-
|Tier 1
|1 point
|Pick A or B
|-
|Tier 2
|2 points
|Pick A or B
|-
|Tier 3
|3 points
|Pick A or B
|}

One full branch = '''6 points''' (1 + 2 + 3). Two full branches = '''12 points'''.

==== Earning Skill Points ====

You earn '''1 skill point''' each time your total EXP reaches a threshold. The first few points come quickly, then slow down:

{| class="wikitable"
!Skill Point
!Total EXP Required
|-
|1st
|30
|-
|2nd
|70
|-
|3rd
|120
|-
|4th
|180
|-
|5th
|350
|-
|6th
|600
|-
|7th
|950
|-
|8th
|1400
|-
|9th
|1950
|-
|10th
|2600
|-
|11th
|3350
|-
|12th
|4200
|}

Fully investing in 2 branches requires '''12 skill points''' (4200 total EXP).

=== Powerful Attacks (Tier 3) ===

Every association has at least one '''Powerful Attack''' available as a Tier 3 skill choice. These are cutscene-style multi-hit combo attacks with shared mechanics:

* '''Weapon-agnostic''' — works with whatever melee weapon you are holding
* '''DPS-based damage''' — each hit deals damage based on your weapon's DPS (<code>force × force_multiplier × 1.25 / attack_speed</code>), so all weapons are equally viable
* '''Target isolation''' — during the combo, the target is isolated and no one else can damage them or steal the kill
* '''Immobilization''' — both you and the target are immobilized for the combo duration
* '''Conditional bonuses''' — each attack has unique conditions that increase damage or add extra effects (more hits, bonus stacks, etc.)
* '''Per-hit effects''' — each individual hit can apply status effects or grant buffs
* '''Long cooldown''' — typically 90-120 seconds between uses

Each powerful attack has a unique opener (dash, slam, leap, etc.) that hits enemies in an area. The first enemy hit becomes the main target for the combo. See the individual association pages for specific powerful attacks and their effects.

== Ally Designation ==

All association members automatically receive a '''Designate Allies''' action. This is not a skill tree pick — it is granted for free with the association.

* Click a player to add them to your ally list. Click them again to remove them.
* Fellow squad members (Director, Veteran, Associate) are '''automatically''' added when registered.
* Skills that affect "allies" (auras, buffs, damage absorption) only affect players on your ally list.
* There is no limit on the number of designated allies.
* You and your designated allies will see a small icon over each other's heads.

This exists so your protective and supportive skills do not accidentally benefit enemies standing in range.

== Emergency Distress ==

The "no contract = no skills" rule has one exception: '''if an association member is attacked by another player and drops below 50% HP or dies, the entire squad is alerted and temporarily gains skill access.'''

'''What happens:'''
* All squad members receive a visible and audio alert with the victim's name, attacker, and location
* A directional arrow of sparks on the ground points toward the victim's last known position, updating every 5 seconds
* If the squad has '''no active contracts''', all members gain full skill tree access for '''60 seconds'''
* If someone already has a contract, the squad already has skills — the alert still fires but the skill grant is redundant
* '''No EXP''' is earned during the emergency window — it is a defensive measure, not a way to farm progression

'''Cooldown:''' 5 minutes per victim. The same member being attacked again within 5 minutes does not re-trigger the alert. Different members being attacked have separate cooldowns.

This prevents off-contract squads from being completely defenseless and makes it dangerous to ambush isolated fixers.

== The Hana's Role ==

The Hana (Administrator and Representative) serves as the contract dispatcher for all associations. This is an '''addition''' to their existing job, not a replacement.

=== What the Hana Does ===

* Creates contracts using the '''Association Contract Terminal''' in their office (the same terminal civilians can use)
* Sets contract type, duration, funding, and target or location
* Views all active contracts and their status
* Has '''unlimited funding''' for contract payments
* Produces physical '''contract items''' that are handed to fixers for acceptance
* Only Administrators and Representatives can create contracts — Interns can view the terminal but not create Hana-tier contracts

=== Why Fixers Need the Hana ===

* Hana contracts are '''reliable and funded''' — civilians may not always have money or willingness to hire
* Hana contracts come with '''guaranteed payment''' from the unlimited budget
* The Hana keeps fixers busy during '''downtime''' when no civilians need services — 1x EXP is better than 0 EXP
* The Hana is the '''safety net''' ensuring fixers always have work available

=== Why the Hana Should Stay Active ===

* A Hana who is not creating contracts is leaving fixers idle with no skills and no EXP
* Hana performance is tracked: contracts issued, contracts completed, total fixer time on-contract
* This gives the Hana a concrete job beyond RP — they are managing a professional workforce
