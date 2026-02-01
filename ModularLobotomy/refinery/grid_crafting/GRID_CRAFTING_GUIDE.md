= Grid Crafting System Guide =

== What is Grid Crafting? ==

Grid Crafting is a mechanic that allows players to craft City weapons using Navigation Cores created from abnormality chemicals (abnochems). Players navigate a coordinate grid using different movement types, each associated with one of the seven sins, to reach weapon locations and craft them.

This system provides an alternative way to obtain City-tier weapons through gameplay rather than random drops.

== Earning Ahn ==

Before you can buy templates, you need Ahn in your bank account. Here are the main ways to earn Ahn:

=== PE Refining (Primary Method) ===

The most reliable source of Ahn is through [[PE Refining]]:

# Obtain PE Boxes from Extraction (buy from Corporate Trade Console for 50 PE each)
# Refine them using the refinery machine in Information Department
# Send Refined PE Boxes to Power Inputs in Extraction
# Each successful delivery rewards '''50-200 Ahn'''

''This is one of the primary sources of Ahn in the facility!''

=== Other Sources ===

* '''Payday:''' Employees receive periodic payments based on their role
* '''Trade Console:''' You are able to buy 1000 Ahn for 200 PE at the corporate trade console in extraction.


== Getting Started ==

=== Step 1: Obtain a Core Template ===

Core Templates are purchasable containers that hold abnochems and determine the quality of your Navigation Core.

'''Where to buy:''' Template Vendor machines (costs Ahn from your bank account)

{| class="wikitable"
! Template Grade
! Cost
! Distance Range
|-
| Basic
| 50 Ahn
| 5-15 units
|-
| Standard
| 150 Ahn
| 10-25 units
|-
| Quality
| 400 Ahn
| 15-40 units
|-
| Superior
| 1000 Ahn
| 25-60 units
|}

''Note: Template grade determines movement distance only. Weapon tier access is unlocked by completing ordeals.''

=== Step 2: Fill the Template with Abnochem ===

Use the Core Template on an abnormality to extract chemicals (requires console upgrade and chem charges). Different chemicals produce different movement types.

'''Quantity matters!''' The amount of chemical (5-25 units) affects your distance modifier:
* 5 units = 50% distance
* 15 units = 100% distance
* 25 units = 150% distance (overcharged)

''Note: Higher-tier chemicals (derivatives and above) bypass quantity requirements and always give 100%.''

=== Step 3: Finalize the Core ===

Use the filled template in-hand to finalize it into a Navigation Core. The core's properties are locked in at this point.

=== Step 4: Use the Grid Crafting Station ===

Insert your Navigation Cores into a Grid Crafting Station and use them to navigate the coordinate grid toward weapon locations.

== Movement Types and Sins ==

Each movement type is associated with a sin. Using the same sin repeatedly incurs diminishing returns (distance penalty).

'''Important:''' Each movement type has a '''distance modifier''' based on its accuracy. More precise movements travel shorter distances, while unpredictable ones travel further to compensate.

{| class="wikitable"
! Movement
! Sin
! Behavior
! Distance Modifier
|-
| '''Charge'''
| Wrath
| Move in a straight line (cardinal directions only)
| '''0%''' (baseline)
|-
| '''Attract'''
| Lust
| Pull toward the nearest weapon's location
| '''-20%'''
|-
| '''Shuffle'''
| Sloth
| Random movement in any direction
| '''+30%'''
|-
| '''Expand'''
| Gluttony
| Move in any of 8 directions (octagonal)
| '''-10%'''
|-
| '''Drift'''
| Gloom
| Move in chosen direction with 50-100% perpendicular shift
| '''+20%'''
|-
| '''Teleport'''
| Pride
| Jump directly to any point within range
| '''-30%'''
|-
| '''Mirror'''
| Envy
| Copy the last movement type used (with own distance)
| '''+10%'''
|}

=== Distance Modifier Rationale ===

* '''Teleport (-30%):''' You pick the exact spot - maximum control, minimum distance
* '''Attract (-20%):''' Auto-targets weapons - high accuracy but you don't choose direction
* '''Expand (-10%):''' 8 directions vs 4 - slightly more flexible than Charge
* '''Charge (0%):''' Baseline - 4 cardinal directions, predictable straight line
* '''Mirror (+10%):''' Depends on previous move - some unpredictability in planning
* '''Drift (+20%):''' You pick direction but path curves - compensated with extra distance
* '''Shuffle (+30%):''' Completely random - highest distance to offset lack of control

''Tip: Use high-distance movements (Shuffle, Drift) for bulk travel, then switch to precision (Teleport) for final positioning!''

== Chemical Mappings ==

=== Base Sin Chemicals (Quantity-Affected) ===

{| class="wikitable"
! Chemical
! Movement
! Sin
|-
| Wrath Extract
| Charge
| Wrath
|-
| Lust Extract
| Attract
| Lust
|-
| Sloth Extract
| Shuffle
| Sloth
|-
| Gluttony Extract
| Expand
| Gluttony
|-
| Gloom Extract
| Drift
| Gloom
|-
| Pride Extract
| Teleport
| Pride
|-
| Envy Extract
| Mirror
| Envy
|}

=== Syrup Chemicals (Quantity-Affected) ===

{| class="wikitable"
! Chemical
! Movement
! Sin
|-
| Hearty Syrup
| Shuffle
| Sloth
|-
| Bitter Syrup
| Mirror
| Envy
|-
| Tasteless Syrup
| Charge
| Wrath
|-
| Focused Syrup
| Drift
| Gloom
|}

=== Derivative Chemicals (Bypass Quantity - Always 100%) ===

{| class="wikitable"
! Chemical
! Movement
! Sin
|-
| Nutrition (NT)
| Charge
| Wrath
|-
| Cleanliness (CN)
| Shuffle
| Sloth
|-
| Consensus (CS)
| Drift
| Gloom
|-
| Amusement (AM)
| Mirror
| Envy
|-
| Violence (VL)
| Attract
| Lust
|-
| Refined Oil (RO)
| Expand
| Gluttony
|-
| Woe (WP)
| Drift
| Gloom
|}

=== High-Level Chemicals (Bypass Quantity - Always 100%) ===

{| class="wikitable"
! Chemical
! Movement
! Sin
|-
| Odisone
| Attract
| Lust
|-
| Gaspilleur
| Charge
| Wrath
|-
| Lesser Sange Rau
| Mirror
| Envy
|-
| Culpusumidus
| Drift
| Gloom
|-
| Serelam
| Expand
| Gluttony
|-
| Nepenthe
| Drift
| Gloom
|-
| Piedrabital
| Shuffle
| Sloth
|-
| Dyscrasone
| Teleport
| Pride
|}

=== ZAYIN Abnormality Chemicals (Quantity-Affected) ===

{| class="wikitable"
! Abnormality
! Chemical
! Movement
! Sin
|-
| One Sin
| Holy Light
| Attract
| Lust
|-
| Sleeping Beauty
| Puffy Clouds
| Shuffle
| Sloth
|-
| Fairy Festival
| Nectar
| Expand
| Gluttony
|-
| Bottle of Tears
| Crumbs
| Drift
| Gloom
|-
| You're Bald
| Essence of Baldness
| Teleport
| Pride
|-
| A Quiet Day
| Liquid Nostalgia
| Drift
| Gloom
|-
| Wellcheers
| Wellcheers Zero
| Mirror
| Envy
|-
| We Can Change Anything
| Dubious Red Goo
| Charge
| Wrath
|}

== Diminishing Returns ==

Using the same sin type repeatedly incurs a stacking distance penalty:

* '''Penalty per consecutive use:''' 15%
* '''Maximum penalty:''' 75%
* '''Recovery:''' Using a different sin decreases all other sin stacks by 1

'''Example:''' Using Wrath 3 times in a row = 30% distance penalty. Then using Lust reduces Wrath stack to 2 (15% penalty).

''Tip: Rotate between different sins to avoid penalties!''

== The Coordinate Grid ==

Weapons are placed at fixed coordinates on an infinite 2D grid. You start at the origin (0, 0) and must navigate to within a weapon's craft radius to create it.

=== Navigation Tips ===

# '''Plan your route''' - Look at nearby weapons and plan which cores to use
# '''Use Attract wisely''' - It pulls toward the nearest weapon, great for homing in
# '''Teleport for precision''' - Jump directly to coordinates when you need exact positioning
# '''Watch your tier access''' - Your cores' max tier limits which weapons you can reach
# '''Shuffle for exploration''' - When you're not sure where to go, random movement can find new options

=== Crafting ===

When you're within a weapon's craft radius, it becomes available to craft in the UI. Click the craft button to create the weapon. After crafting:
* You receive the weapon (spawns at the station)
* Your position resets to origin (0, 0)
* Shuffle points are awarded based on weapon tier

== Weapon Tiers ==

Weapons in Grid Crafting are organized into tiers (0-4) based on their power level. The tier determines how far the weapon is placed from the origin and what grade of navigation core is needed to access it.

=== How Weapon Tiers Are Calculated ===

Weapon tiers are automatically assigned based on the weapon's '''average attribute requirement'''. The system calculates the average of all attribute requirements (Fortitude, Prudence, Temperance, Justice) and assigns a tier accordingly:

{| class="wikitable"
! Tier
! Name
! Avg Attribute Requirement
! Distance from Origin
|-
| '''0'''
| Crude
| Less than 30
| 20-40 units
|-
| '''1'''
| Common
| 30-59
| 40-80 units
|-
| '''2'''
| Refined
| 60-89
| 60-120 units
|-
| '''3'''
| Exceptional
| 90-119
| 140-280 units
|-
| '''4'''
| Legendary
| 120+
| 300-550 units
|}

'''Example:''' A weapon requiring Prudence 80 and Temperance 60 has an average of (80+60)/2 = 70, placing it in '''Tier 2 (Refined)'''.

=== Weapon Sources ===

The Grid Crafting system includes:
* All City melee weapons
* All City ranged weapons
* Middle chain shield weapons

Some special weapons are blacklisted and cannot be crafted through this system.

== Weapon Tier Unlocking ==

'''Not all weapons are available immediately!''' Weapon tiers are unlocked by '''completing ordeals'''. This is a global unlock that affects all grid crafting stations and persists for the entire shift.

=== Ordeal Tier Unlocks ===

{| class="wikitable"
! Ordeal Level
! Tier Unlocked
! Weapons Available
|-
| ''(No ordeals)''
| Tier 0
| Only Tier 0 (Crude) weapons
|-
| '''Dawn'''
| Tier 1
| Tier 0-1 weapons
|-
| '''Noon'''
| Tier 2
| Tier 0-2 weapons
|-
| '''Dusk'''
| Tier 3
| Tier 0-3 weapons
|-
| '''Midnight'''
| Tier 4
| All weapons (Tier 0-4)
|}

'''Example:''' At the start of the shift, you can see ALL weapons on the grid, but only Tier 0 weapons can be crafted. Once the facility completes a Noon ordeal, Tier 0-2 weapons become craftable (shown with a lock icon until unlocked).

=== Important Notes ===

* '''All weapons are visible''' - You can always see every weapon on the grid, but locked ones show a lock icon
* '''Locked weapons can't be crafted''' - The craft button is disabled until the required ordeal is completed
* '''Cores are for navigation only''' - Template grades (Basic, Standard, Quality, Superior) determine movement distance, NOT tier access
* '''Tier access persists''' - Once unlocked by an ordeal, you keep that tier access for the rest of the shift
* '''Global unlock''' - When an ordeal is completed, ALL grid crafting stations are updated immediately

=== Strategy Tips ===

* '''Check ordeal progress:''' Before planning your crafting run, see what ordeals have been completed this shift
* '''Wait for ordeals:''' If you want a Tier 3 weapon, wait until Dusk is completed before spending Ahn on cores
* '''Use cheaper cores:''' Since cores don't affect tier access, you can use Basic cores for everything if you're patient
* '''Higher grades = more distance:''' Use Superior cores to travel further per core, not to unlock tiers

== Strategy Guide ==

=== Budget Approach (Tier 0-1 Weapons) ===

* Use Basic cores (50 Ahn each)
* Favor Shuffle/Drift for +20-30% extra distance per core
* Expected cost: '''100-300 Ahn''' per weapon

=== Mid-Game Approach (Tier 2 Weapons) ===

* Mix of Standard (150) and Quality (400) cores
* May need 3-5 cores to navigate
* Expected cost: '''600-1500 Ahn''' per weapon

=== Late-Game Approach (Tier 3-4 Weapons) ===

* Superior cores (1000 Ahn) for maximum distance
* Need efficient pathing to minimize cores used
* Use Teleport for final precise positioning
* Expected cost: '''3000-10000+ Ahn''' per weapon

=== Efficiency Tips ===

* Use high-distance movement types (Shuffle +30%, Drift +20%) for bulk travel
* Switch to Teleport for final approach - resets diminishing returns
* Overcharge (25u) base sin chems for +50% distance when you have excess chems
* Use Level 3+ derivatives (always 100% distance) to avoid quantity penalties
* Rotate between different sins to avoid the 15% stacking penalty

== Shuffle System ==

Crafting weapons awards shuffle points based on tier:

{| class="wikitable"
! Weapon Tier
! Shuffle Points
|-
| Tier 0 (Crude)
| +1 point
|-
| Tier 1 (Common)
| +2 points
|-
| Tier 2 (Refined)
| +3 points
|-
| Tier 3 (Exceptional)
| +5 points
|-
| Tier 4 (Legendary)
| '''Immediate shuffle'''
|}

When shuffle points reach the threshold (random 8-15), all weapon positions are randomized, creating new opportunities and challenges. Crafting a Tier 4 weapon causes an immediate shuffle regardless of the current counter.

== Quick Reference ==

=== Template Grades ===

Templates determine '''movement distance only''' - tier access is controlled by ordeals.

{| class="wikitable"
! Grade
! Cost
! Min Dist
! Max Dist
|-
| Basic
| 50
| 5
| 15
|-
| Standard
| 150
| 10
| 25
|-
| Quality
| 400
| 15
| 40
|-
| Superior
| 1000
| 25
| 60
|}

=== Chemical Amount Effects ===

{| class="wikitable"
! Chem Amount
! Distance Modifier
|-
| 5 units
| 50%
|-
| 10 units
| 75%
|-
| 15 units
| 100%
|-
| 20 units
| 125%
|-
| 25 units
| 150%
|}

=== Sin Overuse Penalties ===

{| class="wikitable"
! Sin Overuse
! Penalty
|-
| 1 use
| 0%
|-
| 2 uses
| 15%
|-
| 3 uses
| 30%
|-
| 4 uses
| 45%
|-
| 5 uses
| 60%
|-
| 6+ uses
| 75% (max)
|}

=== Movement Distance Modifiers ===

{| class="wikitable"
! Movement Type
! Accuracy
! Distance Modifier
|-
| Teleport (Pride)
| Highest
| -30%
|-
| Attract (Lust)
| High
| -20%
|-
| Expand (Gluttony)
| Medium-High
| -10%
|-
| Charge (Wrath)
| Baseline
| 0%
|-
| Mirror (Envy)
| Medium
| +10%
|-
| Drift (Gloom)
| Low
| +20%
|-
| Shuffle (Sloth)
| Lowest
| +30%
|}

=== Final Distance Calculation ===

Your core's final movement distance is calculated as:

'''Final Distance = Base Distance × Movement Modifier × Quantity Modifier × Diminishing Modifier'''

Where:
* '''Base Distance:''' Random within your template's range (e.g., 10-25 for Standard)
* '''Movement Modifier:''' 0.7 to 1.3 based on movement type (see table above)
* '''Quantity Modifier:''' 0.5 to 1.5 based on chem amount (or 1.0 for advanced chems)
* '''Diminishing Modifier:''' 0.25 to 1.0 based on sin overuse

'''Example:''' Standard template (rolls 20), Shuffle movement (+30%), 25u chem (+50%), no overuse:
: 20 × 1.3 × 1.5 × 1.0 = '''39 units'''

'''Example:''' Same setup but with 3 consecutive Sloth uses (30% penalty):
: 20 × 1.3 × 1.5 × 0.7 = '''27 units'''
