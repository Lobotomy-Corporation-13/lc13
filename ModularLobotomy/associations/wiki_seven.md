== Seven Association (Section 4) — "The Eye" ==

Seven are the professional investigators of the City. They sell intelligence as a service — gathering information, observing targets, and filing reports for whoever is paying. They follow a two-phase approach: '''investigation first, retribution second.''' Rather than rushing into combat, they gather intel, build a case, and then strike with surgical precision.

Seven are '''not heroes'''. They investigate because they are paid to, not out of curiosity. If no one is paying, they have no obligation.

For general information about the association system (contracts, EXP, setup), see [[Updated Zwei Association|the main Association page]].

=== Faction Goals ===

* Investigate targets who your clients hire you to observe
* Gather and file intelligence using your investigation tools
* Punish targets once the case is built — retribution follows investigation

=== Earning EXP ===

Seven earn EXP through intelligence gathering. Their thematic activities are:

* '''Passive EXP''' — '''1 EXP''' every 10s while on a '''duration-based contract''' (does not activate off-contract or on objective-based contracts)
* '''Recorder captures''' — '''1 EXP''' per 5 lines of conversation recorded (max '''5 EXP/min''' per recorder, max 3 active recorders)
* '''Spyglass observation''' — '''1 EXP''' per 30s while actively observing through the spyglass popup (on contract only)
* '''Filed Intel Report''' — '''5 EXP''' base + up to '''10 EXP''' accuracy bonus per report (1 per target per 2 min). Accuracy depends on all fields including backpack contents
* '''Contract completion''' — Duration-based contracts (Surveillance Post, Escort Person): '''25 EXP''' (6 min), '''38 EXP''' (10 min), or '''63 EXP''' (20 min). Objective-based contracts (Patrol Route, Eliminate Target, Investigate Person): '''76 EXP''' on completion (no passive tick, but higher completion reward)

Even without an active contract, Seven can earn EXP at '''half rate''' by recording people, filing intel reports, and using surveillance equipment.

=== Contract Types ===

In addition to the universal contracts (Patrol Route, Eliminate Target, Escort Person), Seven have two unique contract types:

{| class="wikitable"
!Contract Type
!Cost
!Description
!Completion
|-
|Investigate Person
|'''750 / 1250 / 2000 ahn''' (2/3/5 reports)
|Target a specific player. Gather intelligence on them using Seven tools (recorder, camera, scanner) and file Intel Reports about the target. This is '''objective-based''' — there is no timer. The contract specifies how many correctly filled out reports are required, and each report must be filed at least '''2 minutes''' after the previous one (you cannot rush them all at once).
|Required number of reports filed with sufficient accuracy, each at least 2 minutes apart.
|-
|Surveillance Post
|'''500 / 875 / 1500 ahn''' (6/10/20 min)
|Mark a location on the '''Contract City Map'''. Place recording devices and maintain surveillance over the area. The contract timer '''ticks down as long as there are active Seven Recorders deployed in the marked area''' — no association member needs to be physically present. If all recorders in the area are removed or destroyed, the timer pauses until a new one is placed.
|Duration expires while recorders are active in the surveillance area.
|}

The client pays upfront when creating the contract. Hana has unlimited funds; civilians pay from their own wallet. If the contract is declined or discarded, the payment is refunded. For universal contract costs, see the [[Updated Zwei Association|the main Association page]].

'''Contract Indicators:'''
* Investigate Person contracts show the '''target's name'''. Filed reports are tracked (e.g., ''"Reports filed: 2/5"'')
* Surveillance Post contracts highlight the monitored area boundary and show the number of active recorders in the zone

'''Important — Turning Over Information:'''

While the game mechanically completes a contract when enough reports are filed or enough recording time has passed, Seven fixers are '''still expected to turn over all collected intelligence to the client'''. This means sharing your filed reports, recorded tapes, and surveillance findings with whoever hired you. This cannot currently be enforced mechanically in-game, but it is part of the contract's obligations — you are being paid for the information, not just the act of gathering it.

=== Investigation Toolkit ===

When registered, Seven fixers receive a '''Seven Requisition Catalog''' — a shop for purchasing investigation gadgets using ahn. The following tools are available:

{| class="wikitable"
!Tool
!Price
!Description
|-
|Seven Recorder
|200 ahn
|A covert listening device that can be '''disguised as any object'''. Can be '''placed on a floor tile''' (hidden) or '''attached to an item''' (records through containers). Max 3 active recorders per fixer. Earns EXP based on lines of conversation recorded.
|-
|Seven Camera
|150 ahn
|A covert camera — '''no flash''', '''no shutter sound''', '''no visible message''' to the target. Silently captures an intel snapshot that '''records all correct answers''' (target name, role, held items, area) for later report validation. The '''round time''' is also recorded and added to the photograph's description.
|-
|Blank Intel Report (x3)
|50 ahn
|Blank report forms. Hit a '''photograph''' with a blank report to link it. Then fill out the fields: target name, role, round time, held items, backpack contents, and extra notes. Validated against the photo's recorded data — higher accuracy = more EXP.
|-
|Backpack Scanner
|200 ahn
|Covert scanner that works at up to '''5 tiles''' range. Scans a target's worn backpack contents over 3 seconds with '''no progress bar''' and '''no visible message''' to the target. Displays the item list to the fixer — used to fill out the backpack contents field on Intel Reports.
|-
|Seven Spyglass Kit
|300 ahn
|A kit containing '''spy glasses''' and a '''pocket protector''' camera. Place the pocket protector anywhere — it has a built-in 360-degree camera. Wear the glasses and press '''Activate Remote View''' to open a small popup window in the corner of your screen showing a live feed from the pocket protector's location. Earns '''1 EXP per 30s''' while the popup is open on contract.
|-
|Seven Surveillance Glasses
|250 ahn
|Special glasses that link to '''deployed Seven Recorders''' instead of pocket protectors. Hit a deployed recorder with these glasses to link them. Wear the glasses and press '''Activate Remote View''' to open a live camera feed from the recorder's location. Can re-link to a different recorder at any time by hitting it.
|-
|Investigation Dossier
|100 ahn
|Physical clipboard with a TGUI interface. Stores filed reports indexed by subject name — tracks total reports filed, EXP earned, and most-observed subject.
|-
|Recorder Receiver
|150 ahn
|Earpiece that links to deployed recorders for '''live listening'''. Select a recorder to tune in and hear everything it captures in real-time.
|}

'''Recorder — Disguise System:'''

The recorder can be '''disguised as any object'''. To disguise it, '''hit any item with the recorder''' — it copies that item's name, description, and icon, appearing identical to it. This works like the chameleon projector.

* '''Disguised appearance:''' The recorder looks exactly like the copied item to everyone
* '''Seven members:''' Any Seven association member who examines the disguised recorder will see an additional line revealing it as a recorder
* '''Revealing:''' If you '''attack a mob''' with the disguised recorder, the disguise is removed and it reverts to its true appearance
* '''Re-disguising:''' Hit another item with the recorder to change its disguise at any time

'''Recorder — Deployment:'''
* '''Floor placement:''' Click a floor tile to place the recorder as a hidden object. Pick it up by clicking it again.
* '''Item attachment:''' Use the recorder on any item to secretly attach it. The recorder '''hears through containers''' — it records everything near whoever is carrying the host item, even inside backpacks. Even if the item is put in a closed locker, the recorder keeps listening.
* '''Recordings:''' Stored on an internal tape that can be ejected, played back, or printed as a transcript.

'''Recorder — Finding and Removing Attached Recorders:'''

When a recorder is attached to an item, it is '''not immediately visible'''. Detection depends on who is examining the item and how long the recorder has been planted:

* '''The placing fixer:''' When the Seven fixer who planted the recorder examines the host item, they '''always''' see: ''"A Seven Recorder is attached to this item. [Remove]"'' — no matter how recently it was placed.
* '''Everyone else:''' For the first '''10 minutes''' after attachment, the recorder is '''completely invisible''' on examine. Nobody else can detect it. After 10 minutes, '''all''' examiners see: ''"There is a small device attached to this item. [Remove]"''
* '''Removal:''' Anyone who can see the recorder on examine can click the '''[Remove]''' button to detach it — but '''only while holding the item in their active hand'''. The recorder drops into the remover's hands. If they are not holding the item, they receive: ''"You need to be holding the item to remove the device."''

This means a planted recorder has a '''10-minute window''' of complete stealth. After that, anyone who examines the host item closely enough will spot it — but they must be holding the item to actually remove it.

'''Intel Reports — How They Work:'''

Filing intel reports is the primary way Seven earns EXP from active investigation. The workflow is:

# '''Take a photo''' with the Seven Camera. The camera silently records a snapshot containing the '''correct answers''': the target's name, role, held items, and the area name. The '''round time''' is also recorded and added to the photograph's description (using the same format as the tape recorder: <code>gameTimestamp()</code>). This data is embedded in the photograph.
# '''Link the photo to a blank report''' — hit the photograph with a Blank Intel Report. The report is now linked to that snapshot.
# '''Fill out the report''' — use the linked report in-hand to open the form. You must fill in:
#* '''Target Name''' — the subject's name
#* '''Role''' — their job/role
#* '''Round Time''' — the round time when the observation was made (recorded on the photo's description — check the photo to find this)
#* '''Held Items''' — what the target was carrying in their hands
#* '''Backpack Contents''' — what items were in their backpack (use the Backpack Scanner to find this out). You must '''manually type the name of each item'''. The validation allows some room for error — the more items in the backpack, the more mistakes are forgiven
#* '''Extra Notes''' — freeform notes about the target (does '''not''' affect EXP, purely for RP and record-keeping)
# '''File the report''' on your Investigation Dossier to earn EXP. Each field is validated against the photo's recorded data — '''5 EXP base + up to 10 EXP accuracy bonus'''. 1 report per target per 2 minutes.

'''Backpack Contents Accuracy:''' The backpack field requires you to type item names manually. Validation uses fuzzy matching and allows a margin of error based on the number of items in the backpack — if the target had 10 items, getting 7-8 correct still earns a good accuracy score. This rewards using the Backpack Scanner carefully without being punishingly exact.

'''Seven Spyglass Kit — How It Works:'''

The Seven Spyglass Kit is a repackaged version of the existing spy bug system (<code>code/game/objects/items/devices/spyglasses.dm</code>). The kit contains two items:

* '''Spy Glasses''' — Sunglasses with a small screen built into each lens. Wear them on your face and press the '''Activate Remote View''' action button to open a small '''popup window''' in the corner of your screen. This popup shows a live camera feed from wherever the linked pocket protector is located.
* '''Pocket Protector''' — A tiny camera disguised as an ordinary pocket protector. It has a built-in '''360-degree camera''' that captures everything within 1 tile around it. Place it anywhere — on a table, in someone's pocket, on the floor. The glasses and pocket protector come '''pre-linked''' in the kit.

The glasses '''only work while worn''' on your eyes slot. Removing or unequipping them closes the popup. If the linked pocket protector is destroyed or missing, the glasses emit a '''shrill beep''' when you try to activate the view. While the popup is open and you are on an active contract, you earn '''1 EXP per 30 seconds'''.

'''Seven Surveillance Glasses:'''

Seven Surveillance Glasses work identically to the Spyglass Kit glasses, but instead of linking to a pocket protector, they link to '''deployed Seven Recorders'''. This lets you visually monitor the area around any recorder you have placed.

* '''Linking:''' Hit a deployed Seven Recorder (floor-placed or item-attached) with the Surveillance Glasses to link them. You can re-link to a different recorder at any time by hitting it.
* '''Viewing:''' Wear the glasses and press '''Activate Remote View''' to open the popup window showing a live feed from the linked recorder's location.
* '''Re-linking:''' Hit a different deployed recorder to switch the link. Only one recorder can be linked at a time.

This complements the Recorder Receiver (audio-only) by adding a '''visual''' feed. Use the Receiver to listen to a recorder and the Surveillance Glasses to watch through one — or use both on different recorders for full coverage.

=== Weapons and Armor ===

Seven gear is distributed from the equipment box by the Director.

Seven weapons are split into '''sidearms''' (fencing foils/dagger) and '''main weapons''' (blades/cane). Sidearms build up '''Rupture''' stacks on targets, and main weapons exploit the target's weaknesses once Rupture has done its work.

==== Sidearms (Rupture Bursters) ====

Sidearms apply '''Rupture''' on hit with '''diminishing returns''' — it is easy to find new intel on a fresh target, but harder to uncover new vulnerabilities the more you already know. Each hit applies 6 Rupture at base, decreasing by 1 for every X stacks already on the target (varies by weapon tier).

{| class="wikitable"
!Weapon
!Role
!Force
!Damage Type
!Falloff Rate
!Rupture at 0 / 10 / 20 / 30 stacks
|-
|Fencing Foil
|Associate (80 attrs)
|38
|BLACK
|Every 5 stacks
|6 / 4 / 2 / 1
|-
|Veteran Fencing Foil
|Veteran (100 attrs)
|45
|BLACK
|Every 7 stacks
|6 / 5 / 3 / 2
|-
|Director's Dagger
|Director (120 attrs)
|32
|BLACK
|Every 10 stacks
|6 / 5 / 4 / 3
|}

The Director's Dagger has '''faster attack speed''' (0.5) and '''fits in an EGO belt'''.

==== Main Weapons (Adaptive Damage) ====

When the target has '''10 or more Rupture stacks''', main weapons '''adapt their damage type to the target's weakest resistance'''. The damage type reverts to BLACK when Rupture drops below 10.

{| class="wikitable"
!Weapon
!Role
!Force
!Damage Type
!Can Adapt to PALE?
!Notes
|-
|Seven Blade
|Associate (80 attrs)
|36
|BLACK (adaptive)
|No (picks 2nd best)
|Standard adaptive
|-
|Veteran Blade
|Veteran (100 attrs)
|45
|BLACK (adaptive)
|No (picks 2nd best)
|Higher force
|-
|Director's Blade
|Director (120 attrs)
|63
|BLACK (adaptive)
|'''Yes''' (-15% force)
|Full spectrum analysis
|-
|Director's Cane
|Director (120 attrs)
|56
|BLACK (adaptive)
|'''Yes''' (-15% force)
|Lower force, faster attack speed
|}

'''How adaptive damage works:'''
* '''Against players:''' Checks worn armor values — the damage type with the '''lowest armor resistance''' is chosen
* '''Against mobs:''' Checks damage coefficients — the damage type with the '''highest coefficient''' is chosen
* Associate and Veteran blades '''cannot adapt to PALE''' — if PALE would be weakest, they pick the second-weakest instead
* Director weapons '''can adapt to PALE''', but take a '''15% force penalty''' for that hit

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
|Seven Standard
|Associate (80 attrs)
|20
|20
|40
|0
|Standard issue (x2)
|-
|Seven Recon
|Associate (80 attrs)
|0
|0
|30
|0
|Light variant, -0.5 slowdown (faster movement)
|-
|Seven Veteran
|Veteran (100 attrs)
|30
|30
|50
|20
|
|-
|Seven Director
|Director (120 attrs)
|40
|40
|70
|20
|
|}

=== Skill Tree ===

Seven has '''3 branches'''. You can invest in a '''maximum of 2''' — choose carefully.

Each branch has 3 tiers with 2 choices per tier (pick one). Tier costs: T1 = 1 point, T2 = 2 points, T3 = 3 points. Full investment in one branch = 6 points.

'''Core Mechanic — Rupture:''' Most Seven skills use the '''Rupture''' status effect, a delayed-trigger debuff. Stacks build up and remain '''inactive for 5 seconds''' after application. When the target takes RED or BLACK damage after the delay, all stacks burst for BRUTE damage (equal to stacks for humans, stacks x4 for simple mobs). Stacks halve after triggering. This mirrors the investigation-then-retribution loop: build intel (stacks), wait for the right moment (activation delay), then strike (trigger).

'''Secondary Status Effects:'''
* '''Fragile''' — Increases all damage taken by the target
* '''Feeble''' — Reduces the target's melee damage dealt
* '''Defense Level Down''' — Diminishing returns vulnerability (stacks/(stacks+25)*100%)
* '''Offense Level Down''' — Reduces the target's damage output via diminishing returns

==== Branch 1: Analyst (Target Elimination) ====

'''Theme:''' Mark one target. Build Rupture and convert it into devastating single-target damage. The field agent who gathers intel on a single mark, then eliminates them with surgical strikes.

This branch grants the '''Mark Target''' action at T1. Click a player to mark them as your target. One mark at a time. Re-marking removes the old mark.

{| class="wikitable"
!Tier
!Option A
!Option B
|-
|T1 (1pt)
|'''Case File''' — Mark a target. Attacks against the mark apply 2 Rupture and deal bonus BLACK damage equal to 1% of your weapon's base force per Rupture stack on them (max +40% at 40 stacks).
|'''Profiling''' — Mark a target. Each attack on the mark grants you 2 Offense Level Up stacks (max 10 from this skill).
|-
|T2 (2pt)
|'''Exploit Weakness''' — Attacks on the mark apply 2 Defense Level Down (1s CD). When Rupture triggers on a target with 15+ Rupture stacks, apply 5 Fragile to them.
|'''Patient Hunter''' — While the mark has 10+ Rupture, deal 25% more damage to them. At 20+ Rupture, also deal bonus BLACK damage equal to 15% of your weapon's base force.
|-
|T3 (3pt)
|'''Dossier Complete''' — ''See Powerful Attacks below.''
|'''Surveillance Network''' — When you trigger Rupture on a target, deal AoE BLACK damage equal to the Rupture stacks to all nearby enemies (x4 damage on mobs). If the target is your marked target, the AoE deals x2 damage. Killing a target inflicts 15 Rupture to all nearby non-ally mobs.
|}

==== Branch 2: Coordinator (Debuff Support) ====

'''Theme:''' The handler who knows every enemy's weak point and shares that intel with the team. AoE vulnerability debuffs and ally-benefiting effects.

{| class="wikitable"
!Tier
!Option A
!Option B
|-
|T1 (1pt)
|'''Intel Briefing''' — When you hit a target that has Rupture, all designated allies within 5 tiles gain 3 Offense Level Up stacks. 1s internal CD.
|'''Weak Point Analysis''' — Your attacks apply 3 Defense Level Down (1s CD). When you hit a target with 10+ Defense Level Down, allies within 5 tiles gain 3 Offense Level Up.
|-
|T2 (2pt)
|'''Comprehensive Report''' — When you hit a target with 15+ active Rupture, grant all designated allies within 5 tiles 2 Strength and apply 4 Offense Level Down to the target. 10s internal CD per target.
|'''Disinformation''' — Your attacks apply 2 Offense Level Down and 2 Feeble to the target. 1.5s internal CD.
|-
|T3 (3pt)
|'''Full Exposure''' — ''See Powerful Attacks below.''
|'''Undermining Presence''' — When you hit an enemy with any positive stacking buff (Defense Level Up, Offense Level Up, Strength, Protection, or their damage type variants), strip 2 stacks of each. Designated allies within 5 tiles who attack debuffed targets heal for 3% of damage dealt.
|}

==== Branch 3: Operative (Rupture Specialist) ====

'''Theme:''' The Rupture expert. Every skill builds, amplifies, or detonates Rupture stacks. Aggressive attacking with escalating Rupture payoffs.

{| class="wikitable"
!Tier
!Option A
!Option B
|-
|T1 (1pt)
|'''Shadow Step''' — Attacks apply Rupture equal to the target's combined Offense Level Down + Defense Level Down stacks divided by 2 (max 8 Rupture per hit).
|'''Quick Assessment''' — Hitting a new target applies 5 Rupture. Consecutive hits on the same target apply diminishing Rupture: 5, 3, 1, 0. Switching targets resets the count.
|-
|T2 (2pt)
|'''Rupture Cascade''' — When your attack triggers a target's Rupture burst, apply 7 Rupture to all other enemies within 3 tiles. 1s internal CD.
|'''Pressure Points''' — Attacks apply 1 additional Rupture for each unique debuff type on the target (Fragile, Feeble, DLD, OLD — max +4 per hit).
|-
|T3 (3pt)
|'''Surgical Strike''' — ''See Powerful Attacks below.''
|'''Detonation Order''' — Your attacks apply 4 Rupture to the target, as long as the target has less than 20 Rupture stacks.
|}

=== Powerful Attacks ===

Each branch has one T3 option that is a '''Powerful Attack''' — a cutscene-style multi-hit combo. During the combo, the target is isolated (no one else can damage them or steal the kill) and both combatants are immobilized. Each hit deals damage based on your weapon's DPS, so all weapons are equally viable. All Seven powerful attacks deal '''BLACK''' damage.

==== Dossier Complete (Analyst T3a) ====

'''Cooldown:''' 90 seconds

'''Requirement:''' Can only target your marked target. Target must have 10+ Rupture stacks.

'''How it works:'''
# Dash to the marked target from up to 6 tiles away
# 4-hit combo of precise, clinical strikes
# Each hit's damage is multiplied by the target's '''current''' Rupture stacks: '''1 + (stacks x 2 / 100)''' (20 stacks = +40%, 40 stacks = +80%). Rupture is '''not consumed''' — but if stacks decrease mid-combo (e.g. from triggering), the bonus decreases too
# Each hit applies 2 '''Offense Level Down''' stacks
# '''Final hit:''' 2x damage, knockback 2 tiles, applies 5 '''Fragile''' stacks

'''Example:''' At 20 Rupture stacks, each hit gets +40%. At 40 stacks, +80%. The more intel you gather, the harder the sentence hits — but if Rupture triggers mid-combo, the bonus drops.

==== Full Exposure (Coordinator T3a) ====

'''Cooldown:''' 120 seconds

'''How it works:'''
# AoE ground slam centered on you (4-tile radius). All enemies in range receive 2 '''Fragile''' + 3 '''Defense Level Down''' + 3 '''Offense Level Down''' + 2 '''Feeble'''
# Closest enemy hit becomes the target
# 3-hit combo (BLACK DPS)
# Each hit applies 3 '''Rupture''' stacks + bonus Rupture equal to (sum of all designated allies' Offense Level Up stacks + target's Offense Level Down stacks) / 5
# '''Bonus:''' For each designated ally within 6 tiles at the start, '''Defense Level Down and Offense Level Down''' from the opener increase by 3 (up to +3 allies). Fragile and Feeble stay at 2. Example with 2 allies: opener becomes 2 Fragile + 9 DLD + 9 OLD + 2 Feeble
# '''Final hit:''' Force-triggers all existing Rupture on the target immediately (bypasses 5s activation delay)

==== Surgical Strike (Operative T3a) ====

'''Cooldown:''' 90 seconds

'''Requirement:''' Target must have at least one of: Rupture, Fragile, Feeble, Defense Level Down, or Offense Level Down.

'''How it works:'''
# Vanish (invisible for 2 seconds)
# If the target is still within 7 tiles and in line of sight after the vanish, teleport behind them and begin the combo. If line of sight is lost, the attack is cancelled and '''cooldown is refunded'''
# 5-hit combo of fast, precise strikes
# For each unique debuff type on the target, each hit deals '''15% more damage''' (max +75% with all five debuffs)
# Each hit applies 2 '''Rupture''' stacks. First hit applies 3 '''Fragile'''
# '''Final hit:''' 2x DPS, knockback 2 tiles, deals bonus BLACK damage equal to the target's current Rupture stacks

'''Example:''' Target has Rupture + Fragile + DLD = 3 debuffs = +45% damage per hit. With all 5 debuffs active, +75%.

=== Branch Synergies ===

You can only invest in 2 of the 3 branches. Each combination creates a different playstyle:

{| class="wikitable"
!Combination
!Playstyle
!Best For
|-
|'''Analyst + Coordinator'''
|"The Mastermind" — Mark a target, build Rupture personally while exposing them to the whole team via Intel Briefing. Dossier Complete for solo execution, Full Exposure for team fights. Maximum debuff stacking on a single priority target.
|Mixed solo/team play
|-
|'''Analyst + Operative'''
|"The Assassin" — Mark a target, stack Rupture fast via Case File + Quick Assessment, then detonate with Dossier Complete or finish with Surgical Strike. Pure single-target Rupture execution. The quintessential Seven hitman.
|Solo assassination
|-
|'''Coordinator + Operative'''
|"The Saboteur" — Debuff with DLD/OLD via Coordinator, then convert those debuffs into Rupture via Shadow Step. Rupture Cascade spreads stacks across groups. Surgical Strike finishes what the debuffs started.
|Group fights
|}
