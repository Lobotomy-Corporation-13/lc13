== Cinq Association (Section 5) — "The Blade" ==

Cinq are the professional duelists of the City. They hire out their blades for single combat — one-on-one encounters where reputation, money, and sometimes lives are on the line. They view combat as an art form built on composure and discipline. A Cinq fixer does not brawl; they duel.

Cinq are '''not heroes'''. Their work ranges from honorable formal duels to ruthless contracted kills. The benefit to others is a side effect, not the goal.

For general information about the association system (contracts, EXP, setup), see [[Skill Tree Associations|the main Association page]].

=== Faction Goals ===

* Duel targets who your clients hire you to fight
* Win duels to earn ahn and EXP
* Maintain your reputation through disciplined combat

=== Earning EXP ===

Cinq earn EXP through dueling. Their thematic activities are:

* '''Passive EXP''' — '''1 EXP''' every 10s while on a '''duration-based contract''' (does not activate off-contract or on objective-based contracts)
* '''Duel victory''' — '''10 EXP''' (Level 1: First Blood), '''20 EXP''' (Level 2: Submission), '''40 EXP''' (Level 3: To the Death)
* '''Target grade bonus''' — '''3-27 EXP''' per victory based on the target's attribute grade (stronger opponents = more EXP)
* '''Poise crit during duel''' — '''2 EXP''' per critical hit while the duel component is active
* '''Contract completion''' — Duration-based contracts: '''25 EXP''' (6 min), '''38 EXP''' (10 min), or '''63 EXP''' (20 min). Objective-based contracts (Patrol Route, Eliminate Target, Duel Person): '''76 EXP''' on completion (no passive tick, but higher completion reward)

Even without an active contract, Cinq can earn EXP at '''half rate''' by dueling other players using Challenge to Duel (consensual — target must accept). '''Throw the Glove''' (forced duel, no consent) '''requires an active contract.'''

=== Contract Types ===

In addition to the universal contracts (Patrol Route, Eliminate Target, Escort Person), Cinq have two unique contract types:

{| class="wikitable"
!Contract Type
!Cost
!Description
!Completion
|-
|Duel Person
|'''1000 ahn''' (flat)
|Target a specific player. The Cinq fixer must find and duel the target using '''Throw the Glove''' (forced, no consent required). The contract specifies the duel level. Winning gives bonus EXP and ahn.
|The duel ends (win or lose).
|-
|Champion Contract
|'''1500 ahn''' (flat)
|A client hires the Cinq fixer to fight '''on their behalf'''. The client designates an opponent. The Cinq must duel and '''defeat''' the specified target. If the Cinq wins, both the fixer and the client benefit.
|The Cinq wins a duel against the designated target.
|}

The client pays upfront when creating the contract. Hana has unlimited funds; civilians pay from their own wallet. If the contract is declined or discarded, the payment is refunded. For universal contract costs, see the [[Skill Tree Associations|main Association page]].

'''Contract Indicators:'''
* Duel Person contracts show the '''target's name'''
* Champion Contracts show the '''target's name'''

=== Duel System ===

Cinq's core mechanic is the '''formal duel''' — a structured one-on-one fight that happens in-place. When a duel begins, a visible ring ('''8-tile radius''' from the center) is created that only the two duelists can see. If either combatant leaves the ring, they '''immediately lose''' the duel, take SP damage equal to '''75% of their current SP''', and are slowed for 5 seconds. The duel system '''only works on carbon mobs''' (players).

==== Duel Levels ====

{| class="wikitable"
!Level
!End Condition
!Post-Duel Healing
!Risk
|-
|'''Level 1: First Blood'''
|Either combatant reaches '''25% HP'''
|Both '''fully healed'''
|Low — training and honor duels
|-
|'''Level 2: Submission'''
|Either combatant reaches '''crit threshold'''
|Both healed to '''50% max HP'''
|Medium — serious disputes
|-
|'''Level 3: To the Death'''
|One combatant '''dies'''
|None
|Lethal — contracted kills
|}

==== Duel Types ====

'''Consensual Duel (Challenge to Duel):'''
* Use the '''Challenge to Duel''' action on any carbon mob
* The target receives a prompt: ''"Accept Duel? Level: [1/2/3]"'' with Accept/Decline buttons
* Target has '''30 seconds''' to respond
* On accept, the '''duel ring is created immediately''' — neither party can leave. The duel begins after a '''3-second countdown'''
* Available at all times, even off-contract

'''Contracted Duel (Throw the Glove):'''
* '''Requires an active contract'''
* Use the '''Throw the Glove''' action — a glove is thrown at the target ('''3-tile range''')
* On hit, the target receives a visible message: ''"[user] throws a dueling glove at [target]'s feet — a formal challenge!"''
* The '''duel ring is created immediately''' on hit — neither party can leave. After a '''3-second countdown''', the duel begins '''automatically with no consent required'''
* '''Throw the Glove''' is granted as an action to all Cinq members — no physical item needed

==== Duel Rules ====

During a duel:
* Both duelists see the ring boundary; '''leaving the ring = instant loss''' with SP penalty and slow
* The duel component is '''removed when the duel ends''' — healing, rewards, and cleanup happen automatically

==== Ahn Rewards ====

{| class="wikitable"
!Duel Level
!Winner Reward
|-
|Level 1
|'''500 ahn'''
|-
|Level 2
|'''1250 ahn'''
|-
|Level 3
|'''2500 ahn'''
|}

==== Target Grade Bonus ====

When you win a duel, you earn bonus EXP based on the target's attribute grade. The target's 4 attributes (Fortitude, Prudence, Temperance, Justice) are averaged to determine their grade — stronger opponents yield more bonus EXP, rewarding you for taking on challenging duels rather than farming weak targets.

{| class="wikitable"
!Target Avg Attributes
!Grade
!Bonus EXP
|-
|160+
|Grade 1
|27
|-
|~120
|Grade 3
|21
|-
|~80
|Grade 5
|15
|-
|~40
|Grade 7
|9
|-
|~20
|Grade 9
|3
|}

=== Weapons and Armor ===

Cinq gear is distributed from the equipment box by the Director.

==== Weapons ====

{| class="wikitable"
!Weapon
!Role
!Force
!Speed
!Notes
|-
|Cinq Association Rapier
|Associate (80 attrs)
|28
|Normal
|Backstep with double damage, next attack has range 2 (x3)
|-
|Cinq Section 5 Director Rapier
|Veteran (100 attrs)
|40
|0.72 (fast)
|Backstep with triple damage, next attack has range 2
|-
|Cinq Section 4 Director Rapier
|Director (120 attrs)
|75
|1.3 (slow)
|Backstep with double damage, next attack has range 2
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
|Cinq Duelist Gear
|Associate (80 attrs)
|30
|30
|30
|0
|Standard issue (x3). Includes cavalier hat
|-
|Cinq Veteran Gear
|Veteran (100 attrs)
|40
|30
|40
|20
|
|-
|Cinq Director Gear
|Director (120 attrs)
|50
|40
|50
|30
|Uses cinq west sprites. Includes knight hat and cape
|}

=== Skill Tree ===

Cinq has '''3 branches'''. You can invest in a '''maximum of 2''' — choose carefully.

Each branch has 3 tiers with 2 choices per tier (pick one). Tier costs: T1 = 1 point, T2 = 2 points, T3 = 3 points. Full investment in one branch = 6 points.

'''Core Mechanic — Poise and Concentration:''' Cinq skills use two linked status effects:

'''Poise''' (max 50 stacks) grants a critical strike chance equal to '''stacks × 2.5%''' per melee attack. On crit: deal '''25% weapon force''' as bonus damage. After a crit, if you have Concentration, consume 1 Concentration stack; otherwise '''halve all Poise stacks'''. Poise '''decays completely''' if no crit or new stacks gained within 10 seconds.

'''Concentration''' (max 10 stacks) protects your Poise from being halved on crit — each crit only costs 1 Concentration instead of halving Poise. Concentration decays 1 stack per 15 seconds. If you have no Poise, all Concentration is removed.

{| class="wikitable"
!Poise Stacks
!Crit Chance
|-
|5
|12.5%
|-
|10
|25%
|-
|20
|50%
|-
|30
|75%
|-
|40
|100%
|}

==== Branch 1: Duelist (Poise Focus) ====

'''Theme:''' Build and exploit Poise stacks for devastating criticals. Every swing is calibrated to push Poise higher, and every crit lands like a hammer.

{| class="wikitable"
!Tier
!Option A
!Option B
|-
|T1 (1pt)
|'''Keen Edge''' — Each melee attack grants you '''3 Poise''' stacks. Swing often, swing true.
|'''Opening Gambit''' — The first attack against a new target grants you '''8 Poise''' stacks; subsequent attacks on the same target grant '''1'''. Switching targets resets the count.
|-
|T2 (2pt)
|'''Precision Strike''' — On Poise crit, deal an additional '''15% weapon force''' as bonus damage and apply '''3 Fragile''' stacks to the target.
|'''Momentum''' — On Poise crit, if you have '''no Concentration''', regain Poise stacks equal to '''50% of the stacks halved''' by the crit (minimum 3). Does not trigger if Concentration absorbed the crit cost. Crits fuel crits.
|-
|T3 (3pt)
|'''Decisive Blow''' — ''See Powerful Attacks below.''
|'''Ceaseless Pressure''' — Every '''5th consecutive''' melee hit on the same target is an '''automatic crit''' (bypasses the probability roll) and grants you '''5 Poise'''. Switching targets resets the count.
|}

==== Branch 2: Skirmisher (Speed Focus) ====

'''Theme:''' Movement speed, hit-and-run tactics. The Skirmisher fights like quicksilver — closing distance in a flash, landing a burst of strikes, then pulling back before the opponent can react.

{| class="wikitable"
!Tier
!Option A
!Option B
|-
|T1 (1pt)
|'''Quick Step''' — On landing a melee hit, gain '''+15% movement speed''' for 4 seconds. Also grants you '''Poise stacks = total active Cinq speed bonus / 5''' (e.g., 15% speed = 3 Poise, 45% speed = 9 Poise). '''5s cooldown'''.
|'''First Strike''' — Your first melee hit on a new target deals '''20% bonus damage''' and grants you '''5 Poise'''. Only triggers once per target — switching to a different target resets it.
|-
|T2 (2pt)
|'''Flurry''' — After landing '''3 consecutive''' melee hits on the same target within 4 seconds, your '''4th hit''' deals '''50% bonus damage''' and grants you '''3 Poise''' stacks. Resets after the bonus hit triggers.
|'''Rush Down''' — On Poise crit, gain '''+30% movement speed''' for 4 seconds.
|-
|T3 (3pt)
|'''Blade Dance''' — ''See Powerful Attacks below.''
|'''Afterimage''' — After moving '''20+ steps''', your next melee attack deals '''35% bonus damage''' and grants you '''5 Poise''' (resets step counter). Additionally, '''20% chance''' to dodge melee attacks entirely.
|}

==== Branch 3: Fencer (Concentration Focus) ====

'''Theme:''' Sustain Poise through Concentration management and defensive counterplay. The Fencer is the patient combatant who builds an unshakeable foundation of Concentration, protecting their Poise stacks through careful timing and reactive techniques.

{| class="wikitable"
!Tier
!Option A
!Option B
|-
|T1 (1pt)
|'''Composed Guard''' — On taking melee damage, gain '''2 Concentration''' stacks. 3s internal cooldown.
|'''Measured Response''' — On landing a melee hit, you gain '''2 Poise''' stacks. Every '''3rd hit''', also gain '''1 Concentration''' stack.
|-
|T2 (2pt)
|'''Iron Focus''' — Every '''2nd Poise crit''', gain '''2 Concentration''' stacks.
|'''Riposte''' — When hit by a melee attack, you have a '''10 × (your Concentration stacks)%''' chance to '''negate the damage entirely''' and move to an adjacent tile, consuming '''2 Concentration'''. At 10 Concentration = 100% dodge.
|-
|T3 (3pt)
|'''Fencer's Finale''' — ''See Powerful Attacks below.''
|'''Unshakeable''' — When your Poise stacks are halved by a crit (because you had no Concentration), immediately gain '''2 Concentration''' stacks. Additionally, your melee attacks deal '''bonus damage equal to Concentration stacks × 3%''' of your weapon force (at 10 Concentration = +30% bonus damage).
|}

=== Powerful Attacks ===

Each branch has one T3 option that is a '''Powerful Attack''' — a cutscene-style multi-hit combo. During the combo, the target is isolated and both combatants are immobilized. Each hit deals damage based on your weapon's DPS.

==== Decisive Blow (Duelist T3a) ====

'''Cooldown:''' 90 seconds

'''Requires:''' 15+ Poise stacks.

'''How it works:'''
# '''Half of your Poise stacks are consumed''' before the combo begins. Each consumed stack adds '''2%''' to total combo damage. You also gain '''Concentration = half the consumed stacks''' (max 5)
# Dash forward '''4 tiles''' in your facing direction — first enemy hit becomes the target
# 5-hit combo of rapid precision strikes
# Each hit applies '''2 Defense Level Down''' stacks to the target
# '''Final hit:''' 2x DPS, knocks target back '''3 tiles'''

'''Example:''' At 30 Poise: consume 15, +30% total combo damage, gain 5 Concentration. At 50 Poise: consume 25, +50% damage, gain 5 Concentration. You keep the other half of your Poise for continued fighting.

==== Blade Dance (Skirmisher T3a) ====

'''Cooldown:''' 90 seconds

'''Note:''' All hits deal '''50% reduced damage'''.

'''How it works:'''
# Kick off into a sprint, leaving a brief '''afterimage''' at your starting position, and appear at a '''random adjacent tile''' of the target from up to '''5 tiles''' away
# After '''1 second''', dash toward the '''target's last known position''', continuing '''4 tiles past''' it. If you move adjacent to any enemy during the dash, the combo begins on them
# '''4-hit''' base combo. Between each hit, you '''teleport to a random adjacent tile''' of the target, leaving an '''afterimage''' at each previous position (dancing around them)
# For every '''+10% movement speed''' you have from Cinq skills, add '''1 extra hit''' (e.g., +15% = 5 hits, +30% = 7 hits, +45% = 8 hits)
# Each hit grants you '''2 Poise''' stacks
# '''Final hit:''' 2x DPS, applies '''5 Fragile''' stacks, grants '''+30% speed''' for 5 seconds after the combo ends

==== Fencer's Finale (Fencer T3a) ====

'''Cooldown:''' 90 seconds

'''Requires:''' 5+ Concentration stacks.

'''How it works:'''
# Enter a '''3-second parry stance''' (immobilized, visible aura). During the stance, '''all melee damage against you is negated'''
# If '''hit during the stance''', immediately end the parry and dash to the attacker for the combo. If '''not hit''', after 3 seconds dash to the nearest enemy within '''5 tiles'''
# '''All Concentration stacks are consumed''' — each consumed stack adds '''5%''' to total combo damage
# 4-hit combo
# Each hit grants you '''2 Poise''' and applies '''2 Defense Level Down''' to the target
# '''Final hit:''' 2x DPS, grants '''Protection stacks = half the consumed Concentration''' (rounded down)

'''Example:''' At 8 Concentration: consume all, +40% total damage, gain 4 Protection after the final hit. Getting hit during parry triggers an instant counter — enemies are punished for attacking you.

=== Branch Synergies ===

You can only invest in 2 of the 3 branches. Each combination creates a different playstyle:

{| class="wikitable"
!Combination
!Playstyle
!Best For
|-
|'''Duelist + Skirmisher'''
|"The Swashbuckler" — Build Poise rapidly (Keen Edge + Quick Step), explosive crits + speed. Blade Dance builds Poise too, offering two powerful attacks with different timing.
|Highest burst damage. Aggressive, high-risk
|-
|'''Duelist + Fencer'''
|"The Master Duelist" — Poise + Concentration synergy. Iron Focus regenerates Concentration through crits. Ceaseless Pressure guarantees crits every 5 hits. Most sustainable crit engine.
|Best for extended 1v1 duels
|-
|'''Skirmisher + Fencer'''
|"The Untouchable" — Speed from Quick Step + Rush Down, dodge from Afterimage, damage negation from Riposte + Composed Guard. Two defensive tools that still build Poise.
|Hardest to kill. Defense through mobility
|}
