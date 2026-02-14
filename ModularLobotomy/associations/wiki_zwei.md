== Zwei Association (Section 6) — "The Shield" ==

Zwei are the professional protectors of the City. They sell defense as a service — bodyguarding clients, holding territory, and acting as a localized police force for whoever is paying. They fight defensively, prioritizing their client's safety over killing threats.

Zwei are '''not heroes'''. They protect because they are paid to, not out of kindness. If no one is paying, they have no obligation.

For general information about the association system (contracts, EXP, setup), see [[Updated Zwei Association|the main Association page]].

=== Faction Goals ===

* Protect clients who hire you
* Hold territory when contracted to do so
* Maintain order in your contracted area

=== Earning EXP ===

Zwei earn EXP through protection. Their thematic activities are:

* '''Passive EXP tick''' while on contract and within range of the client or guarded area
* '''Bonus EXP''' for taking damage while near the client or inside the guarded area — absorbing hits is fulfilling your duty
* '''Bonus EXP''' for engaging hostiles within range of the client or area
* '''Contract completion bonus''' based on duration and whether the client survived or the area was held

Even without an active contract, Zwei can earn EXP at a slower rate by taking damage while near non-association players and engaging hostile targets.

=== Contract Types ===

In addition to the universal contracts (Patrol Route, Eliminate Target, Escort Person), Zwei have two unique contract types:

{| class="wikitable"
!Contract Type
!Description
!Completion
|-
|Guard Area
|Designate a zone on the '''Contract City Map'''. The contract timer '''only ticks while at least one association member is inside the zone''' — if everyone leaves, the timer pauses until someone returns.
|Duration expires while association members are present in the zone.
|-
|Protect Person
|Target a specific player. The contract timer '''only ticks while at least one association member is within 5-7 tiles of the client'''. Stronger than the universal Escort Person — grants your client a '''damage reduction aura''' and '''SP stabilization'''.
|Duration expires while association members are near the client.
|}

'''Contract Indicators:'''
* Guard Area contracts create a visible zone boundary so you know your post
* Protect Person contracts show a tether/indicator to the client
* Leaving the area or client '''pauses the timer''' — it does not fail the contract. The timer resumes when any association member returns

=== Weapons and Armor ===

Zwei gear is distributed from the equipment box by the Director.

==== Weapons ====

{| class="wikitable"
!Weapon
!Role
!Force
!Damage Type
!Notes
|-
|Zweihander
|Associate (80 attrs)
|55
|RED
|Defense buff on hit (self and nearby allies)
|-
|Zweihander
|Associate (80 attrs)
|55
|RED
|Same as above (second copy)
|-
|Zweibaton
|Associate (80 attrs)
|40
|RED
|Stuns human targets on hit
|-
|Zweihander (Veteran)
|Veteran (100 attrs)
|80
|RED
|Stronger self-defense buff
|-
|Zweihander (Veteran)
|Director (120 attrs)
|80
|RED
|Same as Veteran weapon (Director uses this for now)
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
|Zwei Standard
|Associate (80 attrs)
|40
|20
|20
|0
|Standard issue (x2)
|-
|Zwei Riot
|Associate (80 attrs)
|70
|40
|40
|20
|Heavy variant, +0.7 slowdown
|-
|Zwei Veteran
|Veteran (100 attrs)
|50
|30
|30
|20
|
|-
|Zwei Leader
|Director (120 attrs)
|70
|40
|40
|20
|
|}

=== Skill Tree ===

Zwei has '''3 branches'''. You can invest in a '''maximum of 2''' — choose carefully.

Each branch has 3 tiers with 2 choices per tier (pick one). Tier costs: T1 = 1 point, T2 = 2 points, T3 = 3 points. Full investment in one branch = 6 points.

'''Core Mechanic — Defense Level Up:''' Most Zwei skills use the '''Defense Level Up''' status effect, which provides diminishing returns damage reduction: the more stacks you have, the less each additional stack is worth. Stacks decay over time (halve every 5 seconds), so you need to stay active in combat to maintain high defense.

{| class="wikitable"
!Stacks
!Damage Reduction
|-
|3
|10%
|-
|9
|26%
|-
|20
|44%
|-
|30
|55%
|-
|100
|80%
|}

==== Branch 1: Guardian (Self-Defense) ====

'''Theme:''' You ARE the shield. Personal defense, with skills that convert defense into offense.

{| class="wikitable"
!Tier
!Option A
!Option B
|-
|T1 (1pt)
|'''Iron Stance''' — On taking melee damage, gain 3 Defense Level Up stacks. 0.5s internal cooldown.
|'''Aggressive Guard''' — On hitting an enemy, gain 2 Defense Level Up stacks. 1s internal cooldown.
|-
|T2 (2pt)
|'''Shieldbreaker''' — Your attacks deal bonus RED damage equal to your Defense Level Up percentage of your weapon's base damage.
|'''Steady Footing''' — While you have any Defense Level Up stacks, gain +15% movement speed.
|-
|T3 (3pt)
|'''Retaliating Onslaught''' — ''See Powerful Attacks below.''
|'''Unbreakable''' — On lethal damage, survive at 15% HP, gain 7 Protection stacks + 3s invulnerability. 5 minute cooldown.
|}

==== Branch 2: Territory (Area Defense) ====

'''Theme:''' Hold the line, defend the zone. Buff allies and debuff enemies in your territory.

{| class="wikitable"
!Tier
!Option A
!Option B
|-
|T1 (1pt)
|'''Vigilant Presence''' — Allies within 4 tiles gain 2 Defense Level Up stacks every 10s.
|'''Warden's Watch''' — +15% damage vs mobs in contracted area (+25% if their target is you).
|-
|T2 (2pt)
|'''Law and Order''' — Hostiles entering within 5 tiles receive 2 Tremor stacks. 15s cooldown per target.
|'''Fortified Position''' — While standing still 3s+ in contracted area, gain 5 Defense Level Up stacks every 5s. Moving removes these stacks.
|-
|T3 (3pt)
|'''Earthshatter''' — ''See Powerful Attacks below.''
|'''Iron Curtain''' — While in contracted area, absorb 25% of all damage dealt to allies within 4 tiles (redirected to you at 50% effectiveness).
|}

==== Branch 3: Client (Bodyguard) ====

'''Theme:''' One person, your responsibility. Mark a ward and devote everything to keeping them alive.

This branch grants the '''Mark for Protection''' action at T1. Click a player to mark them as your ward. One ward at a time. Re-marking removes the old mark.

{| class="wikitable"
!Tier
!Option A
!Option B
|-
|T1 (1pt)
|'''Designated Ward''' — Mark a player. While within 7 tiles, they gain 2 Defense Level Up stacks every 10s.
|'''Threatening Presence''' — Mark a player. Hostiles attacking your ward deal 10% less damage while you are nearby.
|-
|T2 (2pt)
|'''Bodyguard's Instinct''' — When your ward takes damage, gain +30% speed for 2s. Directional arrow indicator if distant.
|'''Shared Resilience''' — When you gain Defense Level Up stacks, your ward also gains half (within 7 tiles).
|-
|T3 (3pt)
|'''Guardian's Wrath''' — ''See Powerful Attacks below.''
|'''Lifelink''' — When your ward takes melee/ranged damage, teleport to them and take the hit instead. 5s internal cooldown.
|}

=== Powerful Attacks ===

Each branch has one T3 option that is a '''Powerful Attack''' — a cutscene-style multi-hit combo. During the combo, the target is isolated (no one else can damage them or steal the kill) and both combatants are immobilized. Each hit deals damage based on your weapon's DPS, so all weapons are equally viable.

==== Retaliating Onslaught (Guardian T3a) ====

'''Cooldown:''' 90 seconds

'''How it works:'''
# Dash forward 3 tiles in your facing direction
# First enemy hit becomes the target
# 5-hit combo with dashes between strikes
# Each hit applies 1 '''Tremor''' stack to the target
# '''Bonus:''' Each Defense Level Up stack you have increases total damage by 1%. All stacks are consumed after the combo
# '''Final hit:''' 2x damage, applies 3 Tremor, knocks target back 2 tiles

'''Example:''' At 25 Defense Level Up stacks, total damage is +25%. At 50 stacks, +50%. The more you defend, the harder you hit back.

==== Earthshatter (Territory T3a) ====

'''Cooldown:''' 90 seconds

'''How it works:'''
# AoE ground slam centered on you (3-tile radius). All enemies in range take damage and are briefly stunned
# Closest enemy hit becomes the target
# 3-hit combo (each hit deals 50% of weapon DPS). If used '''in your contracted area''', the combo has '''6 hits''' instead
# Each hit applies 2 '''Defense Level Down''' to the target and 3 '''Defense Level Up''' to you
# '''Bonus:''' For each ally within 5 tiles at the start, gain 1 extra hit (up to +3)
# '''Final hit:''' Knocks target down, applies 3 Tremor and 1s stun

==== Guardian's Wrath (Client T3a) ====

'''Cooldown:''' 120 seconds

'''How it works:'''
# Leap to a target from up to 7 tiles away. Landing impact deals damage in a 1-tile radius
# 4-hit combo of furious close-range strikes
# Each hit '''heals your ward''' for 5% of damage dealt (if ward is alive and within 10 tiles)
# '''Bonus:''' If your ward took '''any damage in the last 10 seconds''', all hits deal '''double damage'''. If your ward is within 5 tiles during the combo, you gain 2 Protection stacks per hit
# '''Final hit:''' 2x damage, applies 5 Tremor, knocks target back 3 tiles away from the ward

=== Branch Synergies ===

You can only invest in 2 of the 3 branches. Each combination creates a different playstyle:

{| class="wikitable"
!Combination
!Playstyle
!Best For
|-
|'''Guardian + Territory'''
|"The Fortress" — Unkillable zone defender. Build Defense Level Up from combat, dump stacks into Retaliating Onslaught for burst damage. Earthshatter weakens groups. Two powerful attacks, fully self-sufficient.
|Guard Area contracts
|-
|'''Guardian + Client'''
|"The Bodyguard" — Tanky protector. Build Defense Level Up, share it with your ward via Shared Resilience, then dump stacks into Retaliating Onslaught. Guardian's Wrath heals the ward while you fight.
|Protect Person contracts
|-
|'''Territory + Client'''
|"The Commander" — Zone controller with a ward. Earthshatter weakens groups while Guardian's Wrath punishes anyone who hurts the client. Two different powerful attacks for different situations, but less personal survivability.
|Hybrid contracts
|}
