<!-- 
Invisible comment for wiki editors:

How to make a recipe recursive (giving it multi-level mouseover tooltips):
1. Create a new template page. Example: https://tgstation13.org/wiki/Template:RecursiveChem/Modafinil
2. Edit that page with the recipe. Again, see Modafinil for an example of what it should look like. 
3. Replace the recipe on this Guide to Chemistry page with {{RecursiveChem/Modafinil}} <- Replace modafinil with the actual chem name. 

Finished. 

ShadowQuill, who originally added this feature May 2019, made another guide here:
https://tgstation13.org/wiki/Template:RecursiveChem

- Angust Nov 16 2019
-->
{{Speech
|name=Tippo Felangus, the Chemist
|text=Hey mate, welcome to Chemistry. This is one of the few jobs where you can make a man heal back up to full health one second and make him explode the next.
<i>Sound too complicated? Naw, this shit is really simple to make. All you have to do is pour some of this Potassium into a beaker of water, like so...</i>
|image=[[File:Chemist action.png|64px|right]]
}}


This guide will primarily be useful for [[Chemist|chemists]] but may come in handy to any player and especially [[Traitor|traitors]]. See [[Chemical recipes]] for simplified step-by-step instructions on how to make complicated chemicals (sometimes outdated), and for info about using the dispenser's ''recipe recording'' function. For grenade making see [[Grenade|Grenades]]. If you don't have a [[#Chemistry_Dispensers|chem dispenser]], see the [[Guide_to_Ghetto_Chemistry|Guide to Ghetto Chemistry]].
<br><br>

A helper client for browsing this wiki (with several extra features) can be found here: https://hamcha.github.io/tghandbook/. This site is unofficial, use at your own risk. 

== Handling reactions ==

For returning players - reactions now work over time. In general, reaction rate is tied to temperature and in some cases the presence of an optional catalyst. {{PURITY}} is tied to the {{PURITY}} of your reagents, and how far away from optimal your pH is. It's important to note that the basic reaction is a one size fits all while each reaction is updated over a batch of updates, so it's unlikely that they'll cause too much trouble for you. Keep your pH within 5-9 and bare in mind most reactions are exothermic now meaning they generate heat when reacting, dangerous when using certain explosive chemicals opposite is for endothermic reactions. [[#Methamphetamine|Meth]] has been tweaked - and it's a tad more dangerous, since it becomes more exothermic the less pure it is and meth explodes if it gets to 380k so be careful out there Walter!.

For a quick crash course in mechanics, the help button on the reaction chamber will get you up to speed by guiding you through a calomel reaction. There's an achievement too if you complete it with a 100% {{PURITY}} product!

=== Temperature ===

All reactions that are non-instant have a reaction rate tied to the temperature of a beaker. If a reaction is proceeding too slowly, simply heat the beaker up to speed it up. As a reaction occurs, it is either Exothermic (heat producing) or Endothermic (heat consuming). Care should be taken for the Exothermic reactions, as they are liable to overheat, and for Endothermic reactions, as they are liable to overcool(Cold Reactions only, see glossary). An overheated(or cooled) reaction will reduce the yield of your reaction by default, and other reactions can have special effects when they get too hot. The rate at which a reaction heats up is faster the hotter it is, be careful to not lose control, and run if you do. 

=== Reaction rates ===
The easiest way to speed a reaction up is to heat the reaction up, but if you're looking for other ways, such as for plumbing, having an optional speed catalyst (such as Palladium synthate catalyst for medicines) at its required volume will also speed it up. Finally, Tempomyocin can be added to a reaction to temporarily increase its reaction speed.

=== Potential of Hydrogen (pH) ===

Every reagent has an innate pH, which can be seen by pressing the cog on the dispenser. The pH of the beaker is the sum of the pHes in the mix. The pH of a beaker determines how pure a product is, for the recipes with a given pH, you want to have your pH at the centre of the limits when the reaction starts. As a reaction progresses, it's likely the pH will begin to drift, and must be compensated for either with [[#Acidic_Buffer|buffer reagents]] or acidic/alkaline compounds. The pH range is something chemists often have to learn over several reactions, and the ChemMaster 3000 analyse function can give an insight into what pH you should be aiming for (Not in yet). Highly impure compounds are liable to affect your reaction too thus it is prudent to set your pH before reacting, as an overly impure reaction will drag the {{PURITY}} down of all other reagents with it. If a reaction is not within its minimum and maximum pH range, it will not start. This does not stop a reaction if it drifts outside of that range. 

=== {{PURITY}} ===

How pure a reagent is determined by how pure your reactants were, and how optimal the pH was during the reaction. If a reagent's {{PURITY}} is below its inverse threshold when it is consumed by a creature, it will transform into its inverse reagent upon consumption. A reagent can be forcibly transformed into its inverse reagent by processing it in a High-Performance Liquid Chromatography machine, which can be used to prevent unwanted side effects. {{PURITY}} can also directly affect a reagent's performance. If this is the case, it is detailed in the description of the reagent. In most (but not all) cases, the change in effect is calculated as {{PURITY}} / Unreacted Purity. For most reagents, where the unreacted {{PURITY}} is 75% (0.75), this means that 75% pure reagent has 1 times its effect, and 100% pure reagent has 4/3rds its effect.

Here's a glossary on some of the terms used in the wiki:
* Inverse {{PURITY}} - Going below this value will cause the reaction's products to transform into their inverse reagents when consumed, or when run through the HPLC.
* Unreacted {{PURITY}} - This is the default {{PURITY}} for any reagent which has not been synthesized via reaction. This applies to round-start reagents, and to reagent creation effects, such as bees, and the Odysseus chemical synthesizer.
* Impure effect - This is the effect that occurs when a reaction drops too far outside of its required pH range.
* Overheat effect - This is the effect that occurs when a reaction becomes too hot or, (in the case of cold reactions), too cold.

=== Overdose scaling ===

For reagents that have an unreacted {{PURITY}} lower than 100% and an overdose effect, the dosage at which you overdose is not set in stone. For these reagents, the overdose dosage is lowered by how much purer the reagent you are taking is compared to its unreacted {{PURITY}}. The inverse, however, is not true. The overdose dosage can not be raised by using a reagent that is less pure than its unreacted {{PURITY}}. For clarity, a number example:

* Ephedrine has 75% unreacted purity
* You create ephedrine with a {{PURITY}} of 100%, which results in a decrease of 25% in its overdose threshold
* As ephedrine has a 30u overdose dosage normally, 30u is multiplied by 0.75, resulting in 22.5u being the true overdose threshold
* You inject 23u of 100% {{PURITY}} ephedrine into yourself, thinking you are safe. You overdose.

=== Optional catalysts ===

For some reactions, an optional catalyst can be added to modify the parameters or outcome of the reaction. At present the only optional catalyst is Palladium synthate catalyst, which doubles the reaction rate of all medicine reactions.

=== Competitive reactions ===

These reactions are ones that compete with each other (aka equilibrium reactions) and will go back and forth depending on the conditions of the beaker. At present the only competing reaction is Tempomyocin and {{PURITY}} tester reagent.

==== General tips ====

* Make sure your pH is correct before heating up the reaction, If it's not reacting, this is usually the problem, after the reaction has started however, it will keep going past the limits, <b>producing impure product</b>.
* Keeping your reaction in the heater to cool it can be a way to deal with exothermic reactions.
* You can adjust the pH of a reaction easily by using the buffer injector tanks in a [[File:Chemical_Heater.png|Chemical Heater]] reaction chamber. Remember to refill these before-hand, lest you run out of buffer in the middle of a complex reaction.
* Take a note of how your pH changes across the reaction and adjust beforehand accordingly, or have some buffer handy to inject into the reaction in the middle of it.
* You can abort reactions by crashing the temperature and hoping it's not exothermic enough to overcome that anyways. Alternatively, you could throw the beaker in a panic.
* For some reactions, it can be useful to keep reagents away from each other until both of them have optimal conditions.
* Temperature of buffers will change the temperature of whatever you're adding it to! Make sure to not pour hot buffer into a temperature sensitive reaction!

== Tools and Machinery ==
You have all sorts of chems here, and can make many things. You can make [[#Medicines|medicines]], [[#Smoke|smoke]], [[#Fluorosurfactant|foam]], [[#Flash Powder|flash powder]], [[#Toxins|poisons]], [[#Space Lube|space lube]], [[#Fluorosulfuric Acid|acid]] and much more. The limit on combinations is a limit that exists only in your creativity (and the game engine). Be sure to be careful though, as mixing the wrong reagents (namely toxins and explosives) can be bad for your health, and please make sure you know what a reagent does before you use it. Experiment at your own risk.


=== [[File:Dispenser.png|Chem Dispenser]] Chemistry Dispensers ===

[[Chem Dispenser|Chem dispensers]] can be upgraded to unlock more reagents, allow for more precise macro usage, increased power recharge rate and higher power capacity. If you run out of power, you can disassemble the dispenser with screwdriver+crowbar and rebuild it by first putting the circuit board back, and then all other things but use a full power cell [[File:Power_cell.png]] instead of the old one. Then screwdriver to finish. Or you can charge the machine with an [[inducer]] [[File:Inducer.png]].

'''Available reagents''':
<div class="toccolours mw-collapsible mw-collapsed">
Click expand to see what reagents are available:
<div class="mw-collapsible-content">
'''Normal''':
* Hydrogen
* Oxygen
* Silicon
* Phosphorus
* Sulfur
* Carbon
* Nitrogen
* Water
* Lithium
* Sugar
* Sulfuric acid
* Copper
* Mercury
* Sodium
* Iodine
* Bromine
* Ethanol
* Chlorine
* Potassium
* Aluminium
* Radium
* Fluorine
* Iron
* Welding fuel
* Stable plasma

'''Upgraded (tier 4 matter manipulator)''':
* Acetone
* Ammonia
* Ash
* Diethylamine
* Oil
* Saltpetre

'''Emagged''':
* Space Drugs
* Morphine
* Toxin
* Carpotoxin
* Miner's Salve
</div>
</div>

'''Upgradeable parts''':
<div class="toccolours mw-collapsible mw-collapsed">
Click expand to see upgrades:
<div class="mw-collapsible-content">
* '''Better matter bins:''' greater power efficiency per unit dispensed.
* '''Better capacitor:''' faster recharging speed.
* '''Better power cell:'''  larger maximum power capacity.
* '''Better manipulator:''' unlocks more reagents.

</div>
</div>

=== [[File:Chemical_Heater.png|Chemical Heater]] Reaction Chamber ===

The reaction chamber (previously known as the chem heater) provides all the tools needed to help you react your reactions. You can set your heat, dispense buffers and watch your reactions in real time. An unupgraded reaction chamber will let you know when a reaction is overheated by highlighting it in red. More buffer can be added to the chamber by putting in a beaker into the heater and pressing the draw all button next to the buffer volume display.

Some chemical reactions will require you to heat the reagents in a Reaction Chamber. Unless the recipes says otherwise, these reactions need you to heat the reagents ''above'' the required temperature in order to start the reaction. Some reactions can stop if they drop below their required temperature.
Don't forget you can use droppers directly on reaction chambers to add/draw to/from as well!
This machine will heat/cool a beaker to the desired temperature, slowing down the heating/cooling speed as it approaches the target temperature. If you don't risk making the chemical explode by overheating it (like with [[#Methamphetamine|meth]]) you can just set it to a very high temperature to avoid this. <br><br>'''Due to a rounding bug you sometimes need to heat chems 1 degree higher than the recipe says.'''<br><br>
Upgrading the laser will increase the heating/cooling speed as well as the capabilities of the machine. See below:

Level 1:
[[File:Reaction chamber level 1.gif]]
Level 4:
[[File:Reaction chamber level 4.gif]]

An upgraded reaction chamber gives you more tools and information about the reactions held within it.
* At level 2 the pH meter will flash if any of the reactions are outside of the pH optimal
* At level 3 the reaction chamber will be able to follow your reaction progress in real time
* At level 4 the reaction chamber will be able to determine the reaction quality in real time, displaying the effects of purity, pH and other factors along a dial. The dial will flash if the reaction is below the minimum {{PURITY}} for the reaction.

=== [[File:Chemmaster.gif|ChemMaster 3000]] ChemMaster 3000 ===

Separates, tubes, and makes pills/patches out of chemicals loaded inside. You can load pretty much any container - beakers, spray bottles, water bottles and so on.<br>
Maximum size for dispensed tubes is 30u, patches 40u and pills 50u. Use a chemistry bag [[File:Chemistry_bag.png]] to quickly move large quantities of tubes, patches or pills. <br>
Can be upgraded with bigger beakers to allow a bigger buffer. By default it contains two ordinary 50u beakers for a total buffer volume of 100u.

=== [[File:PortableMixerBig.png|alt=|ChemMaster 3000]] Portable Chemical Mixer ===

'''The handling of this item has changed, it now <u>has to be held in hand in order to use it</u>.''' 

A portable device that can be stored in the belt slot, enabling you to store, mix and dispense chemicals on the go. 

Can be printed at the medical lathe, after "<u>Chemical Synthesis</u>" has been researched by Science. 

==== How to use it ====
To open or close the portable mixer, in hand or in the belt slot, use '''CTRL + Left click'''. 

While open [[File:Portable Chemical Mixer (open).png|alt=]] you can access it like any other bag, and fill it with up to 50 beakers and bottles.

When closed [[File:Portable Chemical Mixer (closed).png|alt=]], '''hold it in your hand,''' then '''Left click''' to open it's UI.

While the portable mixer is closed and in hand [[File:Portable Chemical Mixer (closed).png|alt=]], it functions similar to a [[Guide to chemistry#Tools and Machinery|Chemistry Dispenser]], allowing you to add and remove a single beaker which you can dispense into [[File:Portable Chemical Mixer (closed).png|alt=]][[File:Portable Chemical Mixer (Beaker).png|alt=]]
[[File:Portable Chemical Mixer (Accessed like a bag).png|thumb|Different containers with chemicals, stored inside the portable chemical mixer.(Image 1 of 2)]]
[[File:Portable Chemical Mixer (UI Controls).png|thumb|All chemicals inside the containers of the portable chemical mixer, combined into UI buttons. (Image 2 of 2)]]

==== Tips for the Portable Chemical Mixer ====
* Unlike the chemistry bag [[File:Chemistry_bag.png]]the portable chemical mixer does not combine beakers of the same type into one single icon when accessing its contents. This makes it a superior option for beaker storage.
* All containers with the same, main chemical inside them, are represented as a single button in the UI. (e.g. a small beaker with 50u Inacusiate and a big beaker with 100u Inacusiate, are represented as 150u Inacusiate (see image).
* A container with more than one chemical inside will be represented by the most dominant chemical in it. (Try to avoid adding beakers with more than one chemical in them, if you want to stay on the safe side)
* The portable chemical mixer is an excellent storage device for pure chemicals that you want to store until you need them in other recipes. Filling it with beakers of pure [[Guide to chemistry#Oil|Oil]], [[Guide to chemistry#Phenol|Phenol]] or [[Guide to chemistry#Multiver|Multiver]] means quick and easy access to them, whenever you need them in advanced chemicals.
* Tired of the floor in chemistry being littered with beakers? Put them in the portable chemical mixer.
* The botanist made you some [[Guide to chemistry#Carpotoxin|Carpotoxin]] and filled it into condiment bottles? No need to carry them by hand, use the portable chemical mixer.
* The Janitor is too lazy to clean medbay? Put one beaker with [[Guide to chemistry#Fluorosurfactant|Fluorosurfactant]], one with [[Guide to chemistry#Space Cleaner|Space Cleaner]] and one with Water in your portable chem mixer, position yourself and dispense them in equal amounts into a big beaker. Instant cleaner grenade action.
* The AI and bots are trying to kill you? Get some Uranium from the lathe, grind it, and put a beaker of it with a beaker of Iron into your portable chem mixer. Dispense both in equal amounts into a big beaker to cause an [[Guide to chemistry#EMP|EMP]].
* The doctors are too busy to help and the paramedic is too dead to help? Get yourself a health analyzer, fill your portable chem mixer with beakers of useful medicines (and/or cures and vaccines) and dispense the right dosages for people in need, anywhere on the station.

=== [[File:Hplc.gif|HPLC]] High-performance liquid chromatography machine (HPLC) ===

Can detect impurity levels of reagents added to it, making it one of the best ways to detect {{PURITY}} of a reagent at roundstart. See below:

[[File:Mass spec.png]]

The HPLC will also tell you the reagents purity, no graph reading required. The HPLC can also purify a reagent up to it's standard {{PURITY}} (usually 75%). This takes time and a bit of volume. Inverted reagents cannot be purified, but non-inverse reagents below their inverse {{PURITY}} can be purified to convert them into their respective inverse reagents. Any reagent that is passed through the system, including un-purifiable ones, will still cost time. The {{PURITY}} display and beaker ejectors cannot be used while the HPLC is processing.

To use the HPLC left clicking will interact with the input beaker - so left clicking with a beaker will add it, alt click with a beaker in it will remove it. Right clicking with a beaker will add a beaker to the output slot, and alt right clicking will remove it. The machine needs both an input and output to purify - though can still analyse with just a single input.

The icon also indicates at what state it is at - a bar chart on the screen shows that it's analyzing an input beaker, a sine wave shows that it's currently purifying and a blank screen indicates that it's input beaker is either empty or removed.

=== [[File:Blender.png|Reagent Grinder]] All-In-One Grinder ===

Grinds, crushes, liquefies and extracts reagents from materials placed into it.<br>
If there are reagents associated with an item, grinding that item will destroy it and transfer those reagents into the grinder's beaker.<br>
For example: Plasma/gold/uranium/metal sheets grind into 20u of their respective reagents, donk pockets grind into nutriment (and omnizine if warm), and plants grind into their internal reagents.

=== [[File:Smoke_machine.png|Smoke Machine]] Smoke Machine ===

Dispenses any chemical inside as a [[#Smoke|smoke]] cloud. Needs to be secured by wrenching first.<br>
A great alternative to [[#Smoke|smoke]] [[Grenade|grenades]], but easily incites lynch mobs.<br>
Can only be obtained through the circuit board being printed, and the required parts being assembled first.<br>

'''Upgradeable parts''':
<div class="toccolours mw-collapsible mw-collapsed">
Click expand to see upgrades:
<div class="mw-collapsible-content">
* '''Manipulator''': Unlocks the higher range settings.
* '''Matter bin''': Increases maximum capacity.
* '''Capacitor''': Increases efficiency.
</div>
</div>

=== pH paper ===

pH paper can tell you the rough pH by putting it into the beaker. The colour of the strip will indicate what the pH is. 

=== Buffer reagents ===

[[#Acidic_Buffer|Buffers]] are reagents that alter the pH of a mixture towards acidity (0) or alkalinity (14). These liquids will dissipate when added to a mixture, altering the ph of that mixture by (Volume Of Buffer / Volume Of Mixture) * 30. For example, 1u of basic buffer added to 50u of a mixture will increase that mixture's pH by 0.4. 

=== Chemical analyzer ===

A handy meter that can tell you all about the reagents found in a beaker, as well as being a portable method of {{PURITY}} scanning. (The other being {{PURITY}} Tester, a reagent that will indicate if the mixture it is added to contains an inverse reagent) Researchable and printable by the medical lathe.

===Plumbing===
On some maps the [[Chemist|chemists]] have access to a large empty area with plumbing tools. The available chemicals those can synthesize should be the same as with an un-upgraded [[#Chemistry_Dispensers|chem dispenser]], but the workflow is more like a production line chem factory instead of instant dispensing. See the [[Guide_to_plumbing|Guide to plumbing]] to learn more about this system. You may still have access to the pharmacy though, which has chem dispensers.

==Metabolism==
When a reagent enters a bloodstream it will start to "tick" (sometimes "cycle") about every 2 seconds, though this can vary with server lag. When this happens the bloodstream is {{TGMEDPURGE}}d of an amount of every reagent usually equal to their listed metabolism rates, and any per-tick effects of the reagent trigger. It doesn't matter how many chems you have in your body, as they are all metabolized separately. If you are [[Guide_to_food#Hunger|hungry]] (sluggish), this will happen 20% slower, which makes chemicals have a bigger total effect since they last longer without being weaker per tick. Most creatures are built from the "simplemob" framework, which means they don't have bloodstreams and thus cannot be poisoned, sedated or healed with medicine. Monkeys, Xenomorphs, and the playable humanoids (Ie. you) are the exceptions to this.
{{Nerdnotes|Life tick means SSLife tick, the internal loop (subsystem) that processes the effects of functions like thermoregulation, metabolism, {{BLOOD}}, and hunger in living creatures. SSLife is supposed to fire every 2 seconds, but in the case of server lag most life functions are hooked in to a delta-time system such that the lag is compensated for by increased effects.}}

==Addiction==
Every time you metabolize a drug, you will gain addiction points in the category it belongs to. For every unit of drugs metabolized you receive addiction points. More extreme drugs and [[Guide_to_drinks|alcohol]] will give you more points. If you gain 600 points in addiction category, you will become addicted. By not taking said drugs you will lower the amount of addiction points. High [[Mood|sanity]] speeds up the process.
*You lose 0.5 points per tick with no withdrawal or stage 1 withdrawal.
*You lose 1 point per tick with stage 2 withdrawal.
*You lose 1.5 points per tick with stage 3 withdrawal.
When your mood is good you always lose 2 points per tick regardless of the stage.
If you then fall below 400 points you stop being addicted.
Taking more of the drug you're addicted to will temporarily suppress symptoms, though at least 1 unit of the drug is required (nicotine is different: due to the slow ingestion rate of cigarettes, nicotine requires only 0.01 unit to satisfy withdrawals). Addiction stages advance from time in withdrawal. After 60 ticks, the first stage of withdrawal starts. After 120 ticks, effects transition to stage two. Finally, after 180 ticks since stopping use of the drug, withdrawal stage three begins, continuing until the addition is sated or kicked. 

'''Addiction categories:'''
===Stimulants===

Stimulant withdrawal makes you slow in a number of ways.

*At the first stage you get craving messages about feeling tired and needing a little pick me up. Your actions also become slower(action speed penalty).
*At the second stage you recieve a click cooldown penalty.
*At the third stage you get a movement speed penalty and more craving messages.

===Opioids===

The main symptom of opioid withdrawal is nausea. 

*At the first stage you get craving messages about feels aches in your body, chills and needing opioids. You start yawning intermittently.
*At the second stage your high blood pressure will increase rate of blood loss from any open wounds.
*At the third stage, you have a 7.5% chance per second to gain 25 points of disgust.

===Alcohol===

Alcohol withdrawal is easy to stave off due to the abundance of low alcohol content drinks available from the bar, but it is the only one that can be outright lethal.

*At the first stage you get craving messages about feeling thirsty, wondering if the bar is still open and needing a little Dutch courage. You also start to jitter.
*At the second stage you start to hallucinate.
*At the third stage you start to suffer intermittant seizures that paralyze you for 1-3 seconds and cause 10-30 brain damage depending on duration. Your seizures also cause heavy jittering. Seizures can be prevented by taking [[#Neurine|neurine]] or [[#Sodium_Thiopental|sodium thiopental]]. 

===Hallucinogens===

*At the first stage you get craving messages about feeling empty, spirtually detached and you start to wonder what the machine elves are up to.
*At the second stage you get visual disturbances. 
*At the third stage you enter a [[Traitor_items#Hypnotic_Flash|hypnotic trance]]. 

===Maintenance Drugs===

*At the first stage you get craving messages, start growling intermittently and your health indicator will become unreliable.
*At the second stage you can only stomach GROSS food and you grow a scraggly beard if male.
*At the third stage you will become very dizzy and confused when exposed to light, but it also gives you night vision.

===Medicines===
*Stage 1: You become unsure of your own health, are you aching, or is it just the down from the meds?
*Stage 2: You develop a fever.
*Stage 3: You organs begin to ache a bit too.

In general most pure medicines don't accrue addiction points – it’s instead the inverse or impure chems that will turn you into a hypochondriac.

===Special===
Some reagents have their own unique addiction type. Such as [[Guide_to_chemistry#Nicotine|Nicotine]].

==Active Pure Chemicals==
A.K.A. what happens when you eat or splash these. Their metabolism rate is 0.4u per tick/cycle unless said otherwise. Unmentioned dispensable chemicals don't have any effects. Plasma and uranium require you to grind mineral sheets to acquire.
*'''Chlorine''': Causes 1 {{TGMEDBRUTE}} per tick to a random body part.
*'''Copper''': Can be splashed on metal sheets to create bronze sheets.
*{{anchor|Ethanol}}'''Ethanol''': A decent alcoholic "beverage", with a [[Guide_to_drinks|booze power]] of 65. Increases the speed of [[Surgery|surgery]] procedures and flammability when applied externally. Metabolism rate 0.2.
*'''Fluorine''': Causes 1 {{TGMEDTOX}} per tick.
*'''Iron''': Restores 0.5 {{BLOOD}} per tick. Does not affect blood types outside of standard human types and L.
*'''Lithium''': Causes twitching, drooling, moaning and not being able to walk straight.
*'''Mercury''': Causes 1 {{BRAIN}} per tick, twitching, drooling, moaning and not being able to walk straight.
*'''[[Plasma]]''': Causes 3 {{TGMEDTOX}} per tick. Creates gas form plasma when spilled or heated to 323.15K (50°C). Not to be confused with Stable Plasma, which does nothing.
*'''Radium''': Causes 2 {{TGMEDTOX}} per tick. Creates glowing green goo on floor if more than 3u is spilled.
*'''Sugar''': Gives nutrition. Causes hyperglycemic shock if overdosed (120u). Metabolism rate 2.
*'''Sulfuric Acid''': Causes 1 {{TGMEDTOX}} and some instant {{TGMEDBRUTE}} to one body part when ingested, and slightly more {{TGMEDBRUTE}} when ''injected''. Destroys head-wear and causes {{TGMEDBURN}} when sprayed or splashed on someone. Counts as a [[#Toxins|toxin]].
*'''Uranium''': Causes 1 {{TGMEDTOX}} per tick. Creates glowing green goo on floor if more than 3u is spilled.
*'''Water''': Regenerates 0.1 {{BLOOD}} per tick, or 0.3 {{BLOOD}} if the patient has the Fish infusion set bonus. Reduces drunkenness by 0.25 per tick, or double that if the patient has the fish infusion set bonus. If the patient has the fish infusion set bonus, heals 0.25 {{TGMEDTOX}}, 0.25 {{TGMEDBRUTE}} and 0.25 {{TGMEDBURN}} per tick. Additionally, freezes into ice below 274K. Proportionally reduces the power of alcoholic substances in the body, such that 10u water and 10u wine is half as powerful as 10u wine. If splashed or sprayed, slightly reduces dizziness, confusion, drowsiness, sleeping, unconsciousness, drunkenness, and jittering. If sprayed, afflicts [[Felinids]] with a negative moodlet.  Creates wet turfs when applied to turfs. 
*'''Welding Fuel''': Causes 1 {{TGMEDTOX}} per tick. Makes people flammable if splashed on. If splashed on the floor, makes a pool of fuel that can be ignited, which can ignite other pools around it.

===Catalysts===
{{Anchor|Catalyst}}When a reagent in a recipe is marked "(catalyst)" it means it will not be consumed in the reaction. Some Catalysts are optional and are highlighted as such. These optional catalysts affect the ongoing reaction in certain ways.
<!--
As of July 31, 2023, reagents are stored on separate pages to reduce lag in the editor and make them easier to maintain.
IF YOU ARE EDITING REAGENTS, THEY ARE SORTED IN THE FOLLOWING CATEGORIES
----------------------
| Components         |
| Reaction agents    |
| Medicines          |
| Narcotics          |
| Pyrotechnics       |
| Other reagents     |
| Toxins             |
| Undesired reagents |
----------------------

Go to the file that you want to add the reagent to (example: tgstation13.org/wiki/Chemistry/Components) and edit the corresponding table.
any changes you make will automatically be updated here!

IF YOU WANT TO CREATE ANOTHER CATEGORY
Create a new page under the Chemistry page with the name of your category
Wrap the data you want to put on another page in <onlyinclude></onlyinclude>
Include the table below using the template {{:Chemistry/YourCategory}}
See tgstation13.org/wiki/Chemistry/Components for an example implementation

IF YOU WANT TO PUT THE REAGENTS ON ANOTHER PAGE
Either copy the following templates for the reagents you want or use the template {{:Reagents}} to include all of them on a page.
-->
{{anchor|Reagents}}
{{:Chemistry/Components}}

{{:Chemistry/Reaction_agents}}

{{:Chemistry/Medicines}}

{{:Chemistry/Narcotics}}

{{:Chemistry/Pyrotechnics}}

{{:Chemistry/Other_reagents}}

{{:Chemistry/Toxins}}

{{:Chemistry/Undesired_reagents}}

==Reagent Delivery{{anchor|Reagent Delivery}}==
{{anchor|Under_the_hood}}There are different ways you can apply chemicals to a person or the environment.

===Delivery types===
There are 6 types of delivery, called '''ingest''', '''inhale''', '''inject''', '''vapor''', '''touch''' and '''patch'''. If you are not interested in the details, you can skip to [[#Smoke_vs_foam|Smoke vs Foam vs others]]. <br>

===Ingest===
Ingesting reagents puts them into the [[Guide_to_medicine#Organ_table|stomach]]. The individual reagents in the stomach will then be digested over time, which slowly moves them to the bloodstream at a rate partly based on the amount of them in the stomach, and stomach type ([[Guide_to_races|race]]). Most reagents have no effect until they have been moved to the bloodstream where they start metabolising (an exception is milk). They can be ejected if the person vomits. Ingestion is used by pills or drinking/eating the reagent directly. [[#Probital|Probital]] works best when ingested.

===Inhale===
Works exactly the same as ingestion, however it is only used by cigarettes and smoke reactions. <s>Galaxy Gas</s> Nitrous Oxide does brain damage when inhaled.

====Inject====
On inject the reagent simply enters the target's bloodstream and starts metabolising. Reagents in blood can be [[Surgery#Filter_Blood|filtered out]] using surgery. Used by syringes and IV-drips. [[#Syriniver|Syriniver]] works best if injected.

====Vapor====
Vapor is used by (ranged) spray bottles and [[#Fluorosurfactant|foam]]. A portion of the reagents will enter the bloodstream of the target, depending on the overall bio protection the target's clothing offers. Any MODsuit typically makes the target completely immune to getting it into their bloodstream, if the helmet is closed. But if the reagent has a "vapor" based component, that component will still affect the target, like [[#Fluorosulfuric Acid|Fluorosulfuric Acid]]. See more about [[#Fluorosurfactant|foam]] [[#Smoke_vs_foam|below]], with examples. [[#Hercuri|Hercuri]] works best as vapor.

====Touch====
Touch is used by [[#Smoke|smoke]] and splashing. If the reagent has a "touch" based component, that component will affect the target (such as the instant heal part of [[#Synthflesh|Synthflesh]]), without being blocked by clothing. Nothing at all will enter the target's bloodstream, with the exception of smoke if the target has no internals on. Currently all "touch" components are also "patch" components. See more on [[#Smoke|smoke]] [[#Smoke_vs_foam|below]], with examples.

====Patch====
Patch is used by patches and medical gels. The reagent enters the target's bloodstream entirely AND if the reagent has a "patch" based component, that component will affect the target. Currently all  "patch" components are also "touch" components.

===Smoke vs foam vs others===
These are the major practical differences between pills, syringes, patches, cigarettes, [[#Smoke|smoke]], [[#Fluorosurfactant|foam]], splash and spray. <br>
====Pills====
Pills can be instantly [[#Ingest|ingested]] if used on yourself. It doesn't work if mouth is covered. [[Plasmaman|Plasmamen]] will have trouble taking these. They hold up to 50u. Aren't added to bloodstream instantly. <br>

====Syringes====
[[Medical_items#Syringe|Syringes]] can inject into people even with their mouths covered, either by hand or with a syringe gun. It doesn't work on players wearing MODsuits or other pierce-immune clothing, unless you use a piercing syringe or manage to aim for an exposed part of their body. [[Golem]]s are completely immune to syringes (even piercing syringes), but [[Guide_to_chemistry#Patches|patches]] do work on them. A syringe holds between 10-60u, depending on type. Common syringes hold 15u. <br>

====Patches====
Will add all reagents into a person's bloodstream through any clothing, including MODsuits. Also apply [[#Touch|touch]]/[[#Patch|patch]] based effects. Example: A patch of 20u [[#Synthflesh|Synthflesh]] will instantly heal 25 brute and burn (touch component), and also enter the target's bloodstream (which in this case does nothing). Usable by [[Plasmaman|plasmamen]]. Can hold up to 40u. <br>

====Cigarettes====
Can be dipped in reagents to be filled. If smoking/vaping, you will slowly [[#Inhale|inhale]] whatever reagents the cigarette/cigar/[[General_items#Vape|e-cig]] contains. Though, if the reagents are too diluted, they may not build up in your bloodstream fast enough to have any effect at all. [[General_items#Vape|E-cigarettes]] can be trimmed with a screwdriver and multitool to also create [[#Smoke|smoke]]. <br>

====[[#Smoke|Smoke]]====
{{Anchor|Smoke_effect}}
When a smoke reaction occurs, the smoke will consume any other reagent in its original containers, and spread that reagent to flooring and people/mobs who enter its area of effect. People who enter the smoke will be [[#Touch|touched]] by the reagents. If they do not have internals or a gas mask on, they will also [[#Inhale|inhale]] the reagents. The amount of smoke does not dilute the reagents. The reagents will be copied to every individual or tile (not walls, windows or doors) over the cloud's duration. Reagents that are special coded to affect floor/environment (such as blood, [[#Fluorosulfuric Acid|acid]] or [[#Space_Cleaner|Space Cleaner]]) will do so. Smoke will usually block sight. <br>
'''Smoke example 1:''' Smoke containing 20u [[#Probital|Probital]]. Everyone caught in the cloud that does not have internals will inhale 20u of the reagent, which isn't as effective as it would be if it was ingested. .<br>

'''Smoke example:''' Smoke containing 20u [[#Chlorine Trifluoride|Chlorine Trifluoride]](CLF3). CLF3 has a [[#Touch|touch]] component, so everyone caught in the cloud, including people wearing MODsuit and internals, will catch on fire. It will also deal burn damage to the environment, since CLF3 is coded to do so. Those who are not wearing internals will also [[#Inhale|inhale]] 20u of the CLF3 and thus, start heating up from the inside, effectively burning from both in and out at the same time. <br>

====[[#Fluorosurfactant|Foam]]====
When a foam reaction occurs, the foam will consume any other reagent in its original containers, and spread that reagent to flooring and people/mobs who enter its area of effect. The foam will spread slower than smoke and is usually slippery. Reagents will be copied through the [[#Vapor|vapor]] type delivery to those affected over the duration of the foam, BUT the reagents will be heavily diluted depending on the amount of foaming reagent used. Any clothing will reduce how much of the reagents will enter a person's bloodstream. Furthermore, foam reagent bloodstream insertion is divided into several 'ticks'. A minimum amount of reagent is required per tick for it to enter a bloodstream. So if too little reagents are contained in the reaction, or too much foam is used, the foam will do nothing. These ticks are counted ''after'' dilution and protection from clothing. On the other hand, if you use very small amounts of foam, the reagents may instead multiply in the bloodstream to more than the original amount. MODsuits with helmets on will make people immune to getting reagents into their bloodstream through foam. Despite dilution, the foam will still copy remaining chems such as [[#Fluorosulfuric Acid|acid]], [[#Chlorine Trifluoride|CLF3]], or [[#Space_Cleaner|Space Cleaner]] to any tile it touches (but not walls, windows or doors). Foam will not block sight. <br>

'''Foam example 1:''' 250u foam containing 10u [[#Cyanide|Cyanide]] will spread a blue foam that does nothing to those it touches. The poison is too diluted to work at all. <br>

'''Foam example 2:''' 20u foam containing 250u [[#Fluorosulfuric Acid|Fluorosulfuric Acid]]. A small area and everyone touched by the foam will have large amounts of acid slowly melting their clothing and the affected floor and items. Those who did not wear a MODsuit will also have a large amount of acid in their bloodstreams, depending on what they were wearing and how long they were in the foam. If they had internals on or not doesn't matter. <br>

====Splashing====
Throwing a beaker or using {{Rightclick}} on something while holding it will splash its contents. The longer throw distance, the more the splash will spread out. A [[grenade]] will splash its content unless it also contains [[#Smoke|smoke]] or [[#Fluorosurfactant|foam]]. Splashing only does [[#Touch|touch]] delivery. This means most chemicals will do absolutely nothing when splashed. Reagents that have special properties to affect environment, such as Water, will do so where splashed (creates slippery tile). Reagents that have a [[#Touch|touch]] component will apply that component only. Example: If you throw a beaker of 80u [[#Synthflesh|Synthflesh]] at someone, you will instantly heal them for 100 brute and burn (and deal up to 150 toxin damage), since Synthflesh is touch/patch based. It doesn't matter if the target uses MODsuit or internals in this case. This means throwing a beaker of poison at someone will do nothing at all. Splashing can apply chemicals such as [[#Thermite|Thermite]] to walls. <br>

====Spraying====
Spraying reagents will apply them to environments (if they have any such effect), and will enter hit people's bloodstreams through the [[#Vapor|vapor]] delivery. This means clothing will protect from some/most/all of the reagents, depending on what they are wearing. Using a MODsuit with helmet on makes them immune to getting the reagent into their bloodstream. Reagents such as [[#Fluorosulfuric Acid|acid]], [[#Chlorine Trifluoride|CLF3]], or [[#Space_Cleaner|Space Cleaner]] will still cause their special effects when sprayed on people/environments, but will not enter the bloodstream if the target is wearing too heavy clothing. <br><br>

== Beyond the Dispenser ==
Just because it isn't found in the dispenser or the guide above doesn't mean you can't use it! [[Guide_to_drinks|Drinks]], [[Guide_to_xenobiology|slime cores]] and plenty of other things can provide limitless fun for an enterprising and curious chemist.

[[Category:Guides]][[Category:Chemistry]]

Tired of juggling bottles when mixing complicated chemicals? Give these a try and feel free to add your own recipes.

Unless stated otherwise, it's assumed that you're using a 100u container (large beaker/large water bottle/shaker etc.) for mixing.

= Chemical Recipe Recording =
{{anchor|Chemical Macros}}You can record recipes by clicking the chem/booze/drink dispenser, and clicking "Record Recipe". Then dispense some reagents, then click "Save". See this gif for an example:<br>
[[File:JJRcops_chem_recording_example.gif]]
=Chemical Macros=
August 2019, the macros feature was removed from /tg/station, and replaced with recipe recording. This list is kept for other stations using older /tg/ code. 

<div class="toccolours mw-collapsible mw-collapsed">
Click expand to see the list:
<div class="mw-collapsible-content">
You can save recipes in the chem dispenser to instantly dispense a certain combination of chemicals at the touch of a button at the remaining cost of dispenser power.

Recipes are tied to a specific Chem Dispenser, and anyone using that dispenser will be able to see, use and erase recipes in it. You also cannot remove individual recipes, as the dispenser only allows you to add recipes and erase all recipes saved.

You can give your recipe any name, and you enter the ingredients in the format <code><ingredient_id>=<amount></code>, separated by semicolons.
For example:
{|
|----
|<code>oxygen=20;nitrogen=15;carbon=10</code>
|-
|<code>water=100</code>
|-
|<code>sulfur=10;ethanol=50</code>
|----
|}

If your recipe doesn't appear in the chem dispenser menu, then you've most likely entered it incorrectly, so try again.
{| class="wikitable sortable" style="width:35%; text-align:left; border: 3px solid #FFDD66; cellspacing=0; cellpadding=2; background-color:white;"
|+ style="caption-side:bottom|"Dispenser Reagents"
! scope="col" style='width:70px; background-color:#FFDD66;'|Name
! scope="col" class="unsortable" style='background-color:#FFDD66;'|Ingredient ID
|-
|Welding Fuel
|welding_fuel
|-
|Stable Plasma
|stable_plasma
|-
|Carbon Dioxide
|co2
|-
|Oxygen
|oxygen
|-
|Hydrogen
|hydrogen
|-
|Nitrogen
|nitrogen
|-
|Chlorine
|chlorine
|-
|Fluorine
|fluorine
|-
|Mercury
|mercury
|-
|Sulfur
|sulfur
|-
|Sulphuric acid 
|sacid
|-
|Silicon
|silicon
|-
|Iodine
|iodine
|-
|Ethanol
|ethanol
|-
|Bromine
|bromine
|-
|Radium
|radium
|-
|Lithium
|lithium
|-
|Phosphorus
|phosphorus
|-
|Sodium
|sodium
|-
|Sugar
|sugar
|-
|Silver
|silver
|-
|Iron
|iron
|- 
|Copper
|copper
|-
|Aluminum
|aluminum
|-
|Space Drugs
|space_drugs
|-
|Morphine
|morphine
|-
|Miner's Salve
|mine_salve
|-
|Toxin
|toxin
|-
|Carpotoxin
|carpotoxin
|}
</div>
</div>

<!-- No particular ordering of this list besides from loosely grouping them into general solid/gas/liquid groups where appropriate and mundane and putting more unorthodox and difficult ones closer to the top -->

== Useful Player Submitted Macros ==
'''These can no longer be used on /tg/station.''' <br>

Click [https://docs.google.com/spreadsheets/d/12vRyMwELUs-dlXZN5jtBHTzW2SyXln47KEhT8nDbuzI/edit?usp=sharing this spreadsheet] for a large and player maintained list of macros.Submitted July 21 2019. <br>


'''Old/outdated list below:''' Many of the following macros are outdated and no longer work. Some of them may only work at a later tech level since you need to upgrade the manipulators in the machine to dispense less than 5u (down to 1u minimum). 

<div class="toccolours mw-collapsible mw-collapsed">
Click expand to see the list:
<div class="mw-collapsible-content">
* Oil (3u): welding_fuel=1;carbon=1;hydrogen=1
* Phenol(9u): welding_fuel=1;carbon=1;hydrogen=1;water=3;chlorine=3
* Acetone (9u): welding_fuel=4;carbon=1;hydrogen=1;oxygen=3

* Diethylamine (60u): hydrogen=30;nitrogen=10;ethanol=30
* Saltpetre (30u): potassium=10;nitrogen=10;oxygen=30
* Unstable Mutagen (90u): chlorine=30;phosphorus=30;radium=30

* Silver Sulfadiazine (90u): hydrogen=18;nitrogen=6;silver=18;sulfur=18;oxygen=18;chlorine=18
* Styptic Powder (100u): aluminium=25;hydrogen=25;oxygen=25;sacid=25
* Saline Glucose (90u): sodium=10;chlorine=10;water=40;sugar=30
* Tricordrazine(90u): nitrogen=10;silicon=25;potassium=10;carbon=25;oxygen=10;sugar=10
* Cryoxadone (90u): chlorine=10;phosphorus=10;radium=10;welding_fuel=14;carbon=4;hydrogen=4;oxygen=10;stable_plasma=30
* Clonexadone (add 5u of plasma): chlorine=5;phosphorus=5;radium=5;welding_fuel=7;carbon=2;hydrogen=2;oxygen=5;stable_plasma=15;sodium=45
* Mannitol(99u): hydrogen=33;water=33;sugar=33
* Salicylic Acid(45u): welding_fuel=1;carbon=10;hydrogen=1;water=3;chlorine=3;sodium=9;oxygen=9;sacid=9
* Oxandrolone (54u): welding_fuel=1;carbon=28;hydrogen=10;water=3;chlorine=3;oxygen=9
* Perfluorodecalin (heat to 370): hydrogen=4;fluorine=3;welding_fuel=1;carbon=1
* Atropine(45u): sacid=9;welding_fuel=5;carbon=2;hydrogen=8;oxygen=3;water=3;chlorine=3;ethanol=15;nitrogen=2
* Mutadone (90u): chlorine=10;phosphorus=10;radium=10;welding_fuel=14;carbon=4;hydrogen=4;oxygen=10;bromine=30


* Ephedrine(24u): hydrogen=11;nitrogen=1;ethanol=3;sugar=6;welding_fuel=2;carbon=2
* Epinephrine (54u): welding_fuel=5;carbon=2;hydrogen=17;water=3;oxygen=12;chlorine=12;nitrogen=2;ethanol=6
* Diphenhydramine (24u): welding_fuel=2;carbon=8;hydrogen=5;bromine=6;nitrogen=1;ethanol=9
* Synaptizine(30u): sugar=10;lithium=10;water=10
* Spaceacillin(60u): welding_fuel=5;carbon=2;hydrogen=17;water=3;oxygen=22;chlorine=12;nitrogen=2;ethanol=6;potassium=10;sugar=10
* Haloperidol(45u): welding_fuel=3;carbon=3;hydrogen=3;potassium=5;iodine=5;aluminium=9;fluorine=9;chlorine=9
* Pentetic acid(54u): stable_plasma=1;radium=1;phosphorus=1;welding_fuel=4;carbon=4;hydrogen=16;nitrogen=4;oxygen=14;oxygen=12;ethanol=12;silver=12;oxygen=10;oxygen=12;hydrogen=36;nitrogen=12;sodium=36;chlorine=36;welding_fuel=36

* Methamphetamine(Heat to 374): hydrogen=35;nitrogen=1;ethanol=3;sugar=6;welding_fuel=2;carbon=2;iodine=24;phosphorus=24
* Space Drugs (30u): lithium=10;mercury=10;sugar=10

* Napalm(9u): welding_fuel=4;carbon=1;hydrogen=1;ethanol=3

* Space Cleaner (18u): nitrogen=3;hydrogen=9;water=9
* Space Lube (12u): oxygen=3;silicon=3;water=3

* Chloral Hydrate(20u): chlorine=60;ethanol=20;water=20
* Sulfonal(27u): welding_fuel=4;carbon=1;hydrogen=7;oxygen=3;nitrogen=2;ethanol=6;sulfur=9
* Lipolicide (36u): hydrogen=17;nitrogen=3;ethanol=9;sugar=6;welding_fuel=2;carbon=2;mercury=12 
* Formaldehyde(9u, heat to 420): ethanol=3;oxygen=3;silver=3
* Fentanyl(30u, heat to 674): lithium=10;mercury=10;sugar=10
* Cyanide (9u): welding_fuel=1;carbon=1;hydrogen=4;nitrogen=1;oxygen=3
* Heparin (60u, heat to 420): ethanol=5;oxygen=5;silver=5;sodium=15;chlorine=15;lithium=15

* Antihol + Inacusiate + Oculine Step 01/02: sodium=5;chlorine=5;water=5;welding_fuel=5;carbon=5;hydrogen=5
* Antihol + Inacusiate + Oculine Step 02/02: carbon=20;ethanol=10;copper=10;water=10;hydrogen=10 //then heat the mix
* Fluorosulfuric Acid (100u): fluorine=25;hydrogen=25;potassium=25;sacid=25 //then heat the mix
</div>
</div>
<br>

= Manual Recipes for Drinks = 
{{anchor|Drinks}}
Here follows a list of simplified step-by-step instructions to mix drinks and change lives. Anyone can edit the wiki page to add additional recipes or update outdated ones. 

== [[Guide_to_drinks#Bacchus'_Blessing|Bacchus' Blessing]][[File:Bacchus_blessing.png|64px]] ==

Acquire '''5u''' Universal Enzyme and a bottle of Absinthe.<br>
Universal Enzyme is found in the kitchen or ordered at Cargo.
*Add '''60u''' Ethanol, '''30u''' Welder Fuel, '''5u''' Universal Enzyme (catalyst)
*Remove Universal Enzyme, set beaker aside
*Add '''25u''' Beer, '''20u''' Ale, '''10u''' Whiskey
*Add '''5u''' Cola
*Remove '''10u'''
*Add '''25u''' Hooch+Absinthe

== [[Guide_to_drinks#Hearty_Punch|Hearty Punch]][[File:Hearty_punch.png|64px]] ==

You'll need a spray bottle to mix this - most maps start with a bunch in the medical area.<br>

Grab a bottle of Absinthe and Kahlua from the bar fridge
* Add '''60u''' Beer, '''40u''' Whiskey, '''20u''' Cola
* Remove '''45u'''
* Add '''50u''' Tequila, '''25u''' Kahlua
* Add '''75u''' Absinthe
* Heat to >315°K
-> Results in '''15u'''

== [[Guide to food and drinks#Neurotoxin|Neurotoxin]][[File:Neurotoxin.gif|64px]] ==

Neurotoxin is also a very good toxin. 

* Add '''10u''' Gin, Vodka, Whiskey, Cognac, Lime Juice
* Add '''50u''' Morphine (found in Nanomed Plus)

== [[Guide to food and drinks#Changeling Sting|Changeling Sting]][[File:ChangelingSting.gif|64px]] ==

* Add '''20u''' Vodka
* Add '''10u''' Orange Juice
* Add '''50u''', then an additional '''10u''' of Lemon-Lime

* You probably want to disguise the drink, lest you get beaten up by security.
* Remove '''40u''', then remove an additional '''5u'''
* Add '''50u''', the an additional '''5u''' of [[Guide to food and drinks#Basic Drink Ingredients|whatever.]] The main point is to disguise the cocktail.


== [[Guide to food and drinks#Bahama Mama|Bahama Mama]][[File:Bahamamamaglass.gif|64px]] ==

* Add '''30u''' Rum, Orange Juice
* Add '''15u''' Lime Juice, Ice

== [[Guide to food and drinks#Cuba Libre|Cuba Libre]][[File:CubaLibre.png|64px]] ==

* Add '''30u''' Space Cola (found in Booze-O-Mat)
* Add '''60u''' Rum

== [[Guide to food and drinks#Demons Blood|Demons Blood]][[File:Demonsbloodglass.gif|64px]] ==

* Add '''25u''' Space Mountain Wind, Dr. Gibb (both found in Robust Softdrinks), Rum, Blood

== [[Guide to food and drinks#Doctor's Delight|Doctor's Delight]][[File:DoctorDelight.gif|64px]] ==

'''Skip this part if you already have 20u Cryoxadone ready'''
* Add '''5u''' Carbon, Hydrogen, Welding Fuel
* Add '''15u''' Oxygen, Welding Fuel
* Remove '''15u'''
* Add '''5u''' Chlorine, Phosphorus, Radium
* Add '''15u''' Stable Plasma
* Remove '''25u'''
-> '''20u''' Cryoxadone
* Add '''20u''' Lime Juice, Tomato Juice, Orange Juice, Milk Cream (found in Booze-O-Mat)

== [[Guide to food and drinks#Fetching Fizz|Fetching Fizz]][[File:Fetching_fizz.png|64px]] ==

* Add '''60u''' Space Cola
* Add '''10u''' Uranium (found by grinding uranium ore sheets)
* Remove '''20u'''
* Add '''50u''' Iron

== [[Guide to food and drinks#Three Mile Island Iced Tea|Three Mile Island Iced Tea]][[File:Threemileislandglass.gif|64px]] ==

* Add '''5u''' Space Cola (found in Booze-O-Mat)
* Add '''10u''' Rum
* Add '''15u''' Vodka, Gin, Tequila
* Remove '''10u'''
* Add '''10u''' Uranium (found by grinding uranium ore sheets)

== [[Guide to food and drinks#Telepole|Telepole]][[File:TelepoleGlass.png|alt=|64x64px]] ==

* Add '''35u''' Sol Dry
* Add '''15u''' Rum
* Add '''25u''' Voltaic Yellow Wine (found in Booze-O-Mat)
* Add '''25u''' Sake

== [[Guide to food and drinks#Pod Tesla|Pod Tesla]][[File:PodTeslaGlass.png|alt=|64x64px]] ==


Skip to step 5 if you already have telepole

* Add '''35u''' Sol Dry
* Add '''15u''' Rum
* Add '''25u''' Voltaic Yellow Wine (found in Booze-O-Mat)
* Add '''25u''' Sake
* Get a Second Glass bottle from Booze-O-Mat 
* Add '''60u''' Navy Rum
* Add '''20u''' Vermouth 
* Add '''20u''' Fernet (found in [[Hacking|hacked]] Booze-O-Mat)
* Get a Third Glass Bottle
* Add '''5u''' Kahlua 
* Add '''10u''' Tequila 
* Add '''25u''' of telepole from Bottle 1
* Add '''25u''' of admiralty from Bottle 2
* Repeat the last 4 steps until Bottles 1 and 2 are empty

== [[Guide to food and drinks#Atomic Bomb|Atomic Bomb]][[File:Atomicbombglass.gif|64px]] ==

* Add '''20u''' Whiskey
* Add '''10u''' Milk Cream (found in Booze-O-Mat)
* Add '''30u''' Kahlúa, Cognac
* Remove '''30u''', then remove an additional '''10u'''
* Add '''10u''' Uranium (found by grinding uranium ore sheets)

= Manual Recipes for Medicines =
{{anchor|Medicines}}

== [[Cryoxadone]] and [[Mutadone]] ==
* Add '''5u''' Carbon, Hydrogen, Welding Fuel
* Add '''15u''' Oxygen, Welding Fuel
* Remove '''15u''' from the beaker
* Add '''10u''' Chlorine, Phosphorus, Radium
* [[Mutadone]]: Add '''30u''' Bromine
* [[Cryoxadone]]: Add '''30u''' Stable Plasma

=== [[Guide to chemistry#Clonexadone|Clonexadone]] ===
* Remove '''40u''', then remove an additional '''5u''' of the [[Guide to chemistry#Cryoxadone|Cryoxadone]]
* Add '''40u''', then an additional '''5u''' of Sodium
* Add '''5u''' of Plasma (Chemistry starts the shift with some plasma on the desk. Grind the plasma up!)

== [[Atropine]] ==
* Add '''10u''' Carbon, Hydrogen, Welding Fuel
* Remove '''10u'''
* Add '''10u''' Chlorine, Water, Welding Fuel, Oxygen
* Add '''15u''' Hydrogen, Ethanol
* Add '''5u''' Nitrogen
* Remove '''30u'''
* Add '''20u''' Ethanol, Sulphuric Acid

== [[Pentetic Acid]] ==
* Add '''5u''' Carbon, Hydrogen, Nitrogen, Welding Fuel
* Add '''15u''' Hydrogen, Oxygen
* Remove '''30u'''
* Heat to 380°K
* Add '''5u''' Ethanol, Oxygen, Silver
* Heat to >420°K
* Add '''5u''' Nitrogen
* Add '''15u''' Chlorine, Hydrogen, Sodium, Welding Fuel

== [[Salbutamol]] ==

* Add '''5u''' Carbon, Hydrogen, Welding Fuel
* Remove '''10u'''
* Add '''5u''' Chlorine, Water
* Remove '''5u'''
* Add '''10u''' Carbon, Oxygen, Sulphuric Acid, Sodium
* Remove '''20u'''
* Add '''30u''' Hydrogen
* Add '''10u''' Nitrogen
* Remove '''20u'''
* Add '''20u''' Aluminum, Bromine, Lithium

== [[Epinephrine]] ==

* Add '''15u''' Ethanol+Hydrogen, '''5u''' Nitrogen
* Remove '''15u'''
* Add '''5u''' Carbon, Hydrogen, Welding Fuel
* Add '''5u''' Chlorine, Oxygen, Water, Welding Fuel 
* Add '''15u''' Chlorine, Hydrogen, Oxygen
* Remove '''5u''' Oil with ChemMaster

== [[Synthflesh]] ==
For 90u, impure Synthflesh (''very'' likely to heal inefficiently):
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Remove '''10u'''
* Add '''5u''' Chlorine, Water
* Remove '''5u'''
* Add '''10u''' Nitrogen, Oxygen
* Add '''30u''' Carbon, Blood (or 5u Blood + 25u Unstable Mutagen)

== [[Guide to chemistry#Anacea|Anacea]] ==

* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Remove '''5u'''
* Add '''5u''' Potassium, Iodine
* Add '''10u''' Chlorine, Fluorine, Aluminum
* Remove '''20u'''
* Add '''15u''' Mercury, Oxygen, Sugar
* Add '''30u''' Radium

== [[Guide to chemistry#Sulfonal|Sulfonal]] ==

* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Remove '''5u'''
* Add '''10u''' Welding Fuel, Oxygen
* Add '''15u''' Hydrogen, Ethanol
* Add '''5u''' Nitrogen
* Add '''30u''' Sulfur

== [[Guide to chemistry#Antihol|Antihol]] + [[Inacusiate]] + [[Oculine]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''20u''' Carbon
* Add '''10u''' Ethanol, Copper, Water, Hydrogen
* Heat to >480°K

== [[Guide to chemistry#Antihol|Antihol]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to >480°K
* Add '''15u''' Ethanol, Copper

== [[Guide to chemistry#Inacusiate|Inacusiate]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to >480°K
* Add '''15u''' Carbon, Water

== [[Guide to chemistry#Oculine|Oculine]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to >480°K
* Add '''15u''' Carbon, Hydrogen

== [[Guide to chemistry#Salicyclic Acid|Salicyclic Acid]] ==

* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Water, Chlorine
* Remove '''20u''', then remove an additional '''5u'''
* Add '''20u''' Sodium, Carbon, Oxygen, Sulphuric Acid

== [[Guide to chemistry#Oxandrolone|Oxandrolone]] ==

* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Water, Chlorine
* Remove '''30u'''
* Add '''45u''' Carbon
* Add '''15u''' Hydrogen, Oxygen

== [[Guide to chemistry#Strange Reagent|Strange Reagent]] ==

* Add '''10u''' Chlorine, Phosphorus, Radium
* Add '''30u''' Holy Water (Ask the chaplain to bless it for you)
* Add '''30u''' Omnizine (Found in heated Donk Pockets, Ambrosia Deus, and in the CMO's hypospray)

== [[Guide to chemistry#Haloperidol|Haloperidol]] ==

* Add '''10u''' Welding Fuel, Carbon, Hydrogen
* Remove '''10u'''
* Add '''10u''' Potassium, Iodine
* Add '''20u''' Chlorine, Fluorine, Aluminum

== [[Guide to chemistry#Rezadone|Rezadone]] ==

* Carpotoxin, an ingredient in Rezadone, can only be found from Space Carp, Koi Beans, or Emagged Chem Dispensers

* Add '''10u''' Oxygen, Potassium, Sugar
* Add '''30u''' [[Guide to chemistry#Carpotoxin|Carpotoxin]]
* Add '''30u''' Copper

== [[Guide to chemistry#Saline-Glucose Solution|Saline-Glucose Solution]] ==

* Add '''10u''' Sodium, Chlorine, Water
* Add '''30u''' Water, Sugar

==[[Guide to chemistry#Multiver|Multiver]] (previously [[Guide to chemistry#Charcoal|Charcoal]])==
* Add '''15u''' Sodium, Chlorine, Water
* Add '''15u''' Welding Fuel, Carbon, Hydrogen
* Heat to >480°K

== [[Guide to chemistry#Spaceacillin|Spaceacillin]] ==

* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Ethanol
* Remove '''20u'''
* Get a separate beaker
* Add '''10u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Welding Fuel, Oxygen, Water, Chlorine
* Remove '''70u'''
* Add '''20u''' of the resulting [[Guide to chemistry#Acetone|Acetone]] and [[Guide to chemistry#Phenol|Phenol]] to the main beaker
* Add '''10u''' Oxygen, Chlorine, Hydrogen
* Remove '''15u'''
* Add '''15u''' Oxygen, Potassium, Sugar

== [[Guide to chemistry#Higadrite|Higadrite]] ==

* Add '''10u''' Welding Fuel, Carbon, Hydrogen
* Remove '''10u'''
* Add '''20u''' Water, Chlorine
* Add '''30u''' Lithium

== [[Guide to chemistry#Leporazine|Leporazine]] ==

* Add '''45u''' Copper, Silicon
* Add '''5u''' Plasma (found in grinded sheets of plasma ore)

== [[Guide to chemistry#Diphenhydramine|Diphenhydramine]] ==

* Add '''30u''' Hydrogen
* Add '''10u''' Nitrogen
* Remove '''10u'''
* Get a separate beaker
* Add '''10u''' Welding Fuel, Carbon, Hydrogen
* Remove '''10u'''
* Add '''20u''' of the resulting [[Guide to chemistry#Oil|Oil]] to the main beaker
* Add '''20u''' Carbon, Bromine, Ethanol

== [[Guide to chemistry#Lenturi|Lenturi]] (Previously [[Guide to chemistry#Ichiyuri|Ichiyuri]]) ==
(Ichiyuri is now a failed chem acquired from failing to make Lenturi.)

* Add '''30u''' Hydrogen
* Add '''10u''' Nitrogen
* Remove '''10u'''
* Add '''20u''' Silver, Sulfur, Oxygen, Chlorine

== [[Guide to chemistry#Ephedrine|Ephedrine]] ==

* Add '''15u''' Hydrogen, Ethanol
* Add '''5u''' Nitrogen
* Add '''10u''' Welding Fuel, Carbon, Hydrogen
* Remove '''10u'''
* Add '''25u''' Sugar, Hydrogen

== [[Guide to chemistry#Sterilizine|Sterilizine]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to >480°K
* Add '''30u''' Chlorine, Ethanol

== [[Guide to chemistry#Pyroxadone|Pyroxadone]] ==

* Add '''5u''' Carbon, Hydrogen, Welding Fuel
* Add '''15u''' Oxygen, Welding Fuel
* Remove '''15u''' from the beaker
* Add '''10u''' Chlorine, Phosphorus, Radium
* Add '''30u''' Stable Plasma
* Remove '''45u'''
* Add '''45u''' [[Guide to chemistry#Slime Jelly|Slime Jelly]]

== [[Guide to chemistry#Energized Jelly|Energized Jelly]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to 480°K. Adding the following chemicals will cool the mix below the explosion threshold.
* Add '''10u''' Potassium, Nitrogen
* Add '''30u''' Oxygen
* Add '''30u''' Sulfur
* Remove '''50u''', then remove an additional '''20u''' and '''5u'''
* Add '''15u''' Stable Plasma, Silver
* Heat to 400°K
* Add '''45u''' [[Guide to chemistry#Slime Jelly|Slime Jelly]]

= Manual Recipes for Pyrotechnics =
{{anchor|Pyrotechnics}}

== [[Guide to chemistry#Gunpowder|Gunpowder]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to 481°K. Adding the following chemicals will cool the mix below the explosion threshold.
* Add '''10u''' Potassium, Nitrogen
* Add '''30u''' Oxygen
* Add '''30u''' Sulfur

Note: Gunpowder ignites at 474°K.

== [[Guide to chemistry#Nitroglycerin|Nitroglycerin]] ==

* Add '''30u''' Corn Oil (bug botany)
* Add '''10u''' Sulphuric Acid
* Remove '''10u'''
* Get a separate beaker
* Add '''10u''' Fluorine, Hydrogen, Potassium, Sulphuric Acid
* Heat to >380°K
* Remove '''10u'''
* Add '''30u''' of the resulting [[Guide to chemistry#Fluorosulfuric Acid|Fluorosulfuric Acid]] to the main beaker
* Get a separate beaker
* Add '''5u''' Iron, Oxygen, Hydrogen
* Use a dropper to draw '''1u''' of the resulting [[Guide to chemistry#Stabilizing Agent|Stabilizing Agent]] to the main beaker
* Dispose of the separate beaker
* Add '''30u''' Sulphuric Acid

* Heat to >474°K for the solution to explode

== [[Guide to chemistry#Napalm|Napalm]] ==

* Add '''10u''' Welding Fuel, Carbon, Hydrogen
* Add '''30u''' Welding Fuel, Ethanol

== [[Guide to chemistry#Meth Explosion|Meth Explosion]] ==

* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Ethanol
* Remove '''5u'''
* Add '''25u''' Iodine Phosphorus
* Cool to about 0°K using the space heater
* Add '''25u''' Hydrogen

* Heat to 300°K (room temperature) to activate an explosion

== [[Guide to chemistry#Teslium|Teslium]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to 480°K. Adding the following chemicals will cool the mix below the explosion threshold.
* Add '''10u''' Potassium, Nitrogen
* Add '''30u''' Oxygen
* Add '''30u''' Sulfur
* Remove '''50u''', then remove an additional '''20u''' and '''5u'''
* Add '''15u''' Stable Plasma, Silver
* Heat to 400°K

* Heat to >474°K to activate an explosion

== [[Guide to chemistry#Chlorine Trifluoride|Chlorine Trifluoride]] ==

* Add '''50u''', then add an additional '''25u''' Fluorine
* Add '''25u''' Chlorine
* Heat to >424°K

== [[Guide to chemistry#Fluorosulfuric Acid|Fluorosulfuric Acid]] ==

* Add '''25u''' Fluorine, Hydrogen, Potassium, Sulphuric Acid
* Heat to >380°K

= Manual Recipes for Drugs =
{{anchor|Drugs}}

== [[Guide to chemistry#Morphine|Morphine]] ==

* Add '''30u''' Carbon, Hydrogen
* Add '''15u''' Ethanol, Oxygen
* Heat to >480K

== [[Guide to chemistry#Methamphetamine|Meth]] ==

* Add 15u Hydrogen
* Add 5u Nitrogen
* Add 15u Ethanol
* Remove 15u
* Add 5u Welding Fuel, Carbon, Hydrogen
* Add 15 Sugar, Hydrogen
* Remove 30u Then 5u
* Add 25u Iodine, Phosphorus, Hydrogen
* Split Into 4 Bottles 25u Each (with ChemMaster or by hand)
* Heat Each Bottle Separately To >374°k NOTHING MORE NOTHING LESS
* Please Make Sure To Cool Other Chems to BELOW >380°k Before Adding The Meth

=== NEEDS UPDATING CURRENTLY MAKES YOU EXPLODE ===

== [[Guide to chemistry#Krokodil|Krokodil]] ==

* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Ethanol
* Remove '''15u'''
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Carbon, Bromine, Ethanol
* Remove '''30u''', then remove an additional '''15u'''
* Get a separate beaker
* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Water
* Remove '''15u'''
* Add '''15u''' of the resulting [[Guide to chemistry#Space Cleaner|Space Cleaner]] to the main beaker
* Add '''15u''' Potassium, Phosphorus, Welding Fuel)
* Add '''15u''' Morphine (Dispensed in the Nanomed Plus)
* Heat to >390°K

== [[Guide to chemistry#Aranesp|Aranesp]] ==

* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Water, Chlorine
* Remove '''30u'''
* Get a separate beaker
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Welding Fuel, Oxygen
* Remove '''30u'''
* Add '''15u''' of the resulting [[Guide to chemistry#Acetone|Acetone]] to the main beaker
* Get a separate beaker
* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Ethanol
* Remove '''15u'''
* Add '''15u''' of the resulting [[Guide to chemistry#Diethylamine|Diethylamine]] to the main beaker
* Add '''15u''' Oxygen, Chlorine, Hydrogen
* Remove '''30u''', then remove an additional '''15u'''
* Get a separate beaker
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Welding Fuel, Oxygen
* Get a separate beaker
* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Ethanol
* Add '''15u''' of the resulting [[Guide to chemistry#Diethylamine|Diethylamine]] to the beaker containing Acetone
* Get a separate beaker
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Water, Chlorine
* Remove '''30u'''
* Add '''15u''' of the resulting [[Guide to chemistry#Phenol|Phenol]] to the beaker containing Acetone
* Add '''15u''' of Ethanol, Sulphuric Acid
* Remove '''30u'''
* Add '''30u''' of the resulting [[Guide to chemistry#Atropine|Atropine]] to the main beaker
* Add '''30u''' Morphine (Dispensed in the Nanomed Plus)

Alternate:
* Add 30u of Epinephrine (from the Nanomed Plus)
* Add 30u of Morphine (from the Nanomed Plus)
* Get a Seperate Beaker
* Add '''10u''' Carbon, Hydrogen, Welding Fuel
* Remove '''10u'''
* Add '''10u''' Chlorine, Water, Welding Fuel, Oxygen
* Add '''15u''' Hydrogen, Ethanol
* Add '''5u''' Nitrogen
* Remove '''30u'''
* Add '''20u''' Ethanol, Sulphuric Acid
* Take 30u of the resulting Atropine and combine it with the Epinephrine and Morphine

== [[Guide to chemistry#Space Drugs|Space Drugs]] ==

* Add '''30u''' Lithium, Mercury, Sugar

=== [[Guide to chemistry#Fentanyl|Fentanyl]] ===

* Heat to >674°K

== [[Guide to chemistry#Bath Salts|Bath Salts]] ==

* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Water
* Remove '''20u'''
* Get a separate beaker
* Add '''5u''' Potassium, Nitrogen
* Add '''15u''' Oxygen
* Remove '''5u'''
* Add '''10u''' of the resulting [[Guide to chemistry#Saltpetre|Saltpetre]] to the beaker containing Space Cleaner
* Add '''10u''' Bad Food, (grind some human burgers) Nutriment, (grind some normal food, food from a vending machine will suffice) Tea, (found in the bartender's non-alcoholic drink dispenser) Universal Enzyme, (bug cargo, chef is going to be rather protective of the stuff), Mercury
* Heat to >374°K

== [[Guide to chemistry#Modafinil|Modafinil]] ==

* Add 5u Welding Fuel, Carbon, Hydrogen
* Remove 5u
* Add 5u Welding Fuel, Oxygen, Chlorine, Water
* Remove 10u
* Add 15u Hydrogen
* Add 5u Ethanol, Nitrogen
* Add 10u Sulfuric Acid, Bromine (catalyst)

= Manual Recipes for Toxins =
{{anchor|Toxins}}

== [[Guide to chemistry#Cyanide|Cyanide]] ==

* Add '''10u''' Welding Fuel, Carbon, Hydrogen, Nitrogen
* Add '''30u''' Hydrogen
* Add '''30u''' Oxygen
* Heat to >380°K

== [[Guide to chemistry#Heparin|Heparin]] ==

* Add '''10u''' Ethanol, Oxygen, Silver
* Heat to >420°K
* Remove '''5u'''
* Add '''25u''' Sodium, Chlorine, Lithium

== [[Guide to chemistry#Lipolicide|Lipolicide]] ==

* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Ethanol
* Remove '''15u'''
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Sugar, Hydrogen
* Remove '''30u'''
* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Ethanol
* Add '''30u''' Mercury

== [[Guide to chemistry#Mute Toxin|Mute Toxin]] ==

* Add '''25u''' Water, Carbon
* Add '''50u''' Uranium (found by grinding uranium ore sheets)

== [[Guide to chemistry#Sulfonal|Sulfonal]] ==

* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Welding Fuel, Oxygen
* Remove '''15u'''
* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Ethanol
* Add '''30u''' Sulfur

== [[Guide to chemistry#Mulligan Toxin|Mulligan Toxin]] ==

* Add '''5u''' Chlorine, Phosphorus, Radium
* Use a dropper set to transfer 1u amounts to move '''2u''' of [[Guide to chemistry#Unstable Mutagen|Unstable Mutagen]] to another beaker
* Add '''1u''' Unstable Mutation Toxin, (found from injecting green slime extracts with radium, contact xenobiology) Blood

== [[Guide to chemistry#Mindbreaker Toxin|Mindbreaker Toxin]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to >480°K
* Add '''30u''' Hydrogen, Silicon

== [[Guide to chemistry#Formaldehyde|Formaldehyde]] ==

* Add '''30u''' Ethanol, Oxygen, Silver
* Heat to >420°K

== [[Guide to chemistry#Zombie Powder|Zombie Powder]] ==

Probably the most powerful toxin in the game currently, 1u can incapacitate for 1 minute

Add '''30u''' of: 
* Carpotoxin (can be found from Space Carp, [[Guide_to_hydroponics#Koibean|Koi Beans]], or Emagged Chem Dispensers)
* Morphine (found in nanomed plus)
* Copper

== [[Guide to chemistry#Itching Powder|Itching Powder]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to >480°K
* Add '''30u''' Hydrogen
* Add '''10u''' Nitrogen
* Add '''30u''' Fuel (drag a fuel tank out of maintenance)

== [[Guide to chemistry#Miner's Salve|Miner's Salve]] ==

* Add '''10u''' Welding Fuel, Carbon, Hydrogen
* Add '''30u''' Iron, Water

== [[Guide to chemistry#Pax|Pax]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to >480°K
* Add '''10u''' Sugar, Lithium, Water
* Add '''30u''' Water

== [[Guide to chemistry#Rotatium|Rotatium]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to >480°K
* Remove '''20u'''
* Add '''10u''' Hydrogen, Silicon
* Get a separate beaker
* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to 480°K. Adding the following chemicals will cool the mix below the explosion threshold.
* Add '''10u''' Potassium, Nitrogen
* Add '''30u''' Oxygen
* Add '''30u''' Sulfur
* Remove '''50u''', then remove an additional '''30u'''
* Add '''10u''' Silver, Stable Plasma
* Heat to >400°K, but below 474°K
* Add '''30u''' of the resulting [[Guide to chemistry#Teslium|Teslium]] to the main beaker
* Get a separate beaker
* Add '''10u''' Lithium, Mercury, Sugar
* Heat to >674°K
* Add '''30u''' of the resulting [[Guide to chemistry#Neurotoxin|Neurotoxin]] to the main beaker

=== <s>[[Guide to chemistry#Skewium|Skewium]] </s>===
Skewium no longer exists. 
* Remove '''50u'''
* Add '''40u''' of Plasma (grind some raw plasma)
* Add '''20u''' of Sulphuric Acid

== [[Guide to chemistry#Carbon Dioxide|Carbon Dioxide]] ==

* Add '''30u''' Carbon
* Add '''60u''' Oxygen
* Heat to >777°K

== Herbicides ==

=== [[Guide to chemistry#Weed Killer|Weed Killer]] ===

* Add '''60u''' Hydrogen
* Add '''20u''' Nitrogen
* Add '''30u''' Hydrogen
* Add '''10u''' Nitrogen
* Remove '''10u'''
* Add '''20u''' Toxin (found in hacked Nanomed Plus)

=== [[Guide to chemistry#Pest Killer|Pest Killer]] ===

* Add '''80u''' Ethanol
* Add '''20u''' Toxin (found in hacked Nanomed Plus)

=== [[Guide to chemistry#Plant-B-Gone|Plant-B-Gone]] ===

* Add '''80u''' Water
* Add '''20u''' Toxin (found in hacked Nanomed Plus)

= Manual Recipes for Utility =
{{anchor|Utility}}

== [[Guide_to_construction#Plastic|Plastic sheets]] ==
The main use for plastic sheets is making large water bottles - these are functionally identical to large beakers.

* Add 30 units each of Welding Fuel, Carbon and Hydrogen to a large beaker. 
* This combines into [[Oil]]. Discard 10 units.
* Separate 30 units of [[Oil]], then heat the bottle to 1000°K until it turns to Ash.
* To the remaining [[Oil]], add 20 units [[Sulphuric Acid]]. 
* Add the Ash to the [[Oil]]/[[Sulphuric Acid]] mix.
* Now, heat the resulting mix to roughly 375°K.
* You now have enough [[Guide_to_construction#Plastic|Plastic]] sheets to make a lot of large bottles!

== Metal foam grenade ==
While not as elegant as smart foam, this one is great for dealing with AI turrets and containing [[Critter]] outbreaks.

* Make enough [[Fluorosulfuric Acid]] and [[Foaming Agent]] that you end up with 30u each.
* Fill beaker A with 90 units of Iron and insert into the grenade casing.
* Put 30u of [[Fluorosulfuric Acid]] and [[Foaming Agent]] each into beaker B and finish up the grenade.

== [[Guide to chemistry#Firefighting Foam|Firefighting Foam]] ==

* Add '''20u''' Carbon, Fluorine
* Add '''10u''' Sulphuric Acid
* Remove '''20u'''
* Add '''10u''' Iron, Oxygen, Hydrogen
* Add '''30u''' Carbon
* Cool to 200°K

= Manual Recipes for Virology =
{{anchor|Virology}}


== [[Guide to chemistry#Virus Food|Virus Food]] ==

* Add '''30u''' Water, Milk (found by using a Biogenerator. Or milk a goat or a cow. Or from [[File:Milk.png]] Space Milk cartons, 50 units in each. 5 are found in kitchen freezer. Ordered food crate has one.)

=== [[Guide to chemistry#Virus Rations|Virus Rations]] ===

* Remove '''30u''', then remove an additional '''15u'''
* Add '''15u''' Sugar, Lithium, Water

=== [[Guide to chemistry#Mutagenic Agar|Mutagenic Agar]] ===

* Remove '''30u''', then remove an additional '''15u'''
* Add '''15u''' Chlorine, Phosphorus, Radium

==== [[Guide to chemistry#Sucrose Agar|Sucrose Agar]] ====

* Remove '''30u''', then remove an additional '''10u'''
* Add '''50u''' of Sugar or Saline-Glucose Solution

=== [[Guide to chemistry#Virus Plasma|Virus Plasma]] ===

* Remove '''30u''', then remove an additional '''10u'''
* Add '''50u''' of Plasma (found when grinding plasma ore)

==== [[Guide to chemistry#Weakened Virus Plasma|Weakened Virus Plasma]] ====

* Remove '''30u''', then remove an additional '''15u'''
* Add '''15u''' Sugar, Lithium, Water

==== [[Guide to chemistry#Unstable Uranium Gel|Unstable Uranium Gel]] ====

* Remove '''50u''', then remove an additional '''25u'''
* Add '''50u''', then an additional '''25u''' of Uranium (found when grinding uranium ore)

=== [[Guide to chemistry#Decaying Uranium Gel|Decaying Uranium Gel]] ===

* Remove '''30u''', then remove an additional '''10u'''
* Add '''50u''' of Uranium (found when grinding uranium ore)

== [[Guide to chemistry#Stable Uranium Gel|Stable Uranium Gel]] ==

* Add '''30u''', then an additional '''10u''' of Silver, Uranium (found when grinding uranium ore) 
* Add '''4u''' of Plasma (found when grinding plasma ore) using a dropper set to use 1u amounts

= 'Fun' =

== Carpet smoke grenade ==
Want to spruce up the station? Start throwing these grenades everywhere. Obscures vision for a while.

* Make 30 units of [[Space Drugs]] and extract 30u of Blood from someone.
* Beaker A: 30u [[Space Drugs]], 30u Potassium.
* Beaker B: 30u Phosphorus, 30u Blood, 30u Sugar.

== [[Guide to chemistry#Colorful Reagent|Colorful Reagent]] ==
Grab a spray bottle to mix.

'''Skip this part if you already have 60u Cryoxadone ready'''
* Add '''5u''' Carbon, Hydrogen, Welding Fuel
* Add '''15u''' Oxygen, Welding Fuel
* Remove '''15u''' from the beaker
* Add '''10u''' Chlorine, Phosphorus, Radium
* Add '''30u''' Stable Plasma
* Remove '''30u''' from the beaker
--> '''60u''' Cryoxadone
* (Add '''60u''' Cryoxadone)
* Add '''20u''' Lithium, Mercury, Sugar
* Remove '''20u'''
--> '''50u''' Cryoxadone and Space Drugs
* Add '''10u''' Lemon+Lime+Orange Juice (Triple Citrus)
* Add '''50u''' Radium, Stable Plasma

== [[Guide to chemistry#Corgium|Corgium]] ==

'''Skip this part if you already have 15u Cryoxadone ready'''
* Add '''5u''' Carbon, Hydrogen, Welding Fuel
* Add '''15u''' Oxygen, Welding Fuel
* Remove '''15u'''
* Add '''5u''' Chlorine, Phosphorus, Radium
* Add '''15u''' Stable Plasma
* Remove '''30u'''
-> '''15u''' Cryoxadone
* (Add '''15u''' Cryoxadone)
* Go to the bar, ask the bartender for some [[Guide to food and drinks#Triple Citrus|Triple Citrus]]. If the bartender isn't there, climb onto the table, and access the non-alcoholic drink dispenser. (It isn't ID locked!) Add '''5u''' Lemon Juice, Lime Juice, Orange Juice
* Add '''5u''' Lithium, Mercury, Sugar
* Add '''15u''' Stable Plasma, Radium
* Remove '''50u''', then remove an additional '''10u'''
* Get a separate beaker (a normal beaker which can hold 50u will do just fine, albeit by this point you should probably have bluespace beakers or large water bottles)
* Add '''5u''' Chlorine, Phosphorus, Raddium
* Remove '''10u'''
* Add '''5u''' Holy Water (get the chaplain to bless it for you)
* Add '''5u''' Omnizine (You can get omnizine through grinding heated donk pockets, or through nicely asking the botanist, since omnizine is naturally found in Ambrosia Deus. If you're lucky, the CMO starts the shift with his/her hypospray loaded with omnizine.)
* Add '''15u''' of the resulting [[Guide to chemistry#Strange Reagent|Strange Reagent]] to the original beaker
* Add '''15u''' of Nutriment (Just vend some food from the Getmore Chocolate Corp and grind it up)
* Get a separate beaker (normal beaker is aforementioned fine)
* Add '''15u''' of Blood
* Heat the beaker containing only blood to about 1000°K

'''How to maxcap the station with absolute adorableness'''

* Acquire a dropper, and adjust it to transfer in 1u amounts
* Go to your target destination
* Draw 1u of the heated blood (Solutions do not lose heat over time! The only way to change the temperature of a solution is by using a heater or a freezer.)
* Inject 1u of the heated blood into your other beaker. Every time 1u of blood is injected into the other beaker, an independent reaction occurs, which produces a corgi.
* Repeat. All your hard work will eventually lead to 15 corgis being let loose onto the station.

== [[Guide to chemistry#Life|Life]] ==

* Add '''5u''' Chlorine, Phosphorus, Radium
* Add '''15u''' Holy Water (Ask the chaplain to bless it for you, or ask the botanist for holymelons)
* Add '''15u''' Omnizine (Found in heated Donk Pockets, Ambrosia Deus, and in the CMO's hypospray)
* Remove '''15u'''
* Get a separate beaker for [[#Synthflesh|Synthflesh]] (this will need buffers, or it will fail)
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Remove '''10u'''
* Add '''5u''' Chlorine, Water
* Remove '''5u'''
* Add '''10u''' Nitrogen, Oxygen
* Add '''30u''' Carbon, Blood (or 5u Blood + 25u Unstable Mutagen)
* Add '''30u''' of the resulting Synthflesh to the main beaker
* Add '''30u''' Blood (for hostile life) or '''30u''' Sugar (for friendly life)
Heat beaker to at least 375K.

== [[Guide to chemistry#Quantum Hair Dye|Quantum Hair Dye]] ==

'''Skip this part if you already have 15u Cryoxadone ready'''
* Add '''5u''' Carbon, Hydrogen, Welding Fuel
* Add '''15u''' Oxygen, Welding Fuel
* Remove '''15u'''
* Add '''5u''' Chlorine, Phosphorus, Radium
* Add '''15u''' Stable Plasma
* Remove '''30u'''
-> '''15u''' Cryoxadone
* (Add '''15u''' Cryoxadone)
* Go to the bar, ask the bartender for some [[Guide to food and drinks#Triple Citrus|Triple Citrus]]. If the bartender isn't there, climb onto the table, and access the non-alcoholic drink dispenser. (It isn't ID locked!) Add '''5u''' Lemon Juice, Lime Juice, Orange Juice
* Add '''5u''' Lithium, Mercury, Sugar
* Add '''15u''' Stable Plasma, Radium
* Remove '''30u''', then remove an additional '''15u'''
* Add '''10u''' Lithium, Mercury, Sugar
* Add '''30u''' Radium

== [[Guide to chemistry#Barber's Aid|Barber's Aid]] ==

* Add '''5u''' Lithium, Mercury, Sugar
* Add '''15u''' Blood
* Add '''10u''' Lithium, Mercury, Sugar
* Add '''30u''' Radium

=== [[Guide to chemistry#Concentrated Barber's Aid|Concentrated Barber's Aid]] ===

* Remove '''30u''' and then remove an additional '''15u'''
* Add '''15u''' Chlorine, Phosphorus, Radium

== [[Guide to chemistry#Condensed Capsaicin|Condensed Capsaicin]] ==

* Add '''15u''' of Capsaicin (bug botany for chilis)
* Add '''75u''' of Ethanol

== [[Guide to chemistry#Spray Tan|Spray Tan]] ==

* Add '''15u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Orange Juice (found in the bartender's non-alcoholic drink dispenser)

== [[Guide to chemistry#Nitrous Oxide|Nitrous Oxide]] ==

* Add '''30u''', and then an additional '''15u''' of Hydrogen
* Add '''15u''' of Nitrogen
* Remove '''5u'''
* Add '''20u''' Nitrogen
* Add '''40u''' Oxygen
* Heat to 525°K

Note: Nitrous Oxide explodes at 575°K

== [[Guide to chemistry#Laughter|Laughter]] ==

A suitable substitute gift for the clown. Unlike Space Lube, will most likely not get you lynched.

* Add '''50u''' Sugar, Banana Juice (can only be acquired through juicing raw bananas, which can be found in botany)

== [[Guide to chemistry#Synthmeat|Synthmeat]] ==

'''Skip this part if you already have 15u Cryoxadone ready'''
* Add '''5u''' Carbon, Hydrogen, Welding Fuel
* Add '''15u''' Oxygen, Welding Fuel
* Remove '''15u'''
* Add '''5u''' Chlorine, Phosphorus, Radium
* Add '''15u''' Stable Plasma
* Remove '''30u'''
-> '''15u''' Cryoxadone
* (Add '''15u''' Cryoxadone)
* Add '''75u''' Blood

== [[Guide to chemistry#Carpet|Carpet]] ==

* Add '''15u''' Lithium, Mercury, Sugar
* Add '''45u''' Blood

[[Category:Guides]][[Category:Chemistry]]

Tired of juggling bottles when mixing complicated chemicals? Give these a try and feel free to add your own recipes.

Unless stated otherwise, it's assumed that you're using a 100u container (large beaker/large water bottle/shaker etc.) for mixing.

= Chemical Recipe Recording =
{{anchor|Chemical Macros}}You can record recipes by clicking the chem/booze/drink dispenser, and clicking "Record Recipe". Then dispense some reagents, then click "Save". See this gif for an example:<br>
[[File:JJRcops_chem_recording_example.gif]]
=Chemical Macros=
August 2019, the macros feature was removed from /tg/station, and replaced with recipe recording. This list is kept for other stations using older /tg/ code. 

<div class="toccolours mw-collapsible mw-collapsed">
Click expand to see the list:
<div class="mw-collapsible-content">
You can save recipes in the chem dispenser to instantly dispense a certain combination of chemicals at the touch of a button at the remaining cost of dispenser power.

Recipes are tied to a specific Chem Dispenser, and anyone using that dispenser will be able to see, use and erase recipes in it. You also cannot remove individual recipes, as the dispenser only allows you to add recipes and erase all recipes saved.

You can give your recipe any name, and you enter the ingredients in the format <code><ingredient_id>=<amount></code>, separated by semicolons.
For example:
{|
|----
|<code>oxygen=20;nitrogen=15;carbon=10</code>
|-
|<code>water=100</code>
|-
|<code>sulfur=10;ethanol=50</code>
|----
|}

If your recipe doesn't appear in the chem dispenser menu, then you've most likely entered it incorrectly, so try again.
{| class="wikitable sortable" style="width:35%; text-align:left; border: 3px solid #FFDD66; cellspacing=0; cellpadding=2; background-color:white;"
|+ style="caption-side:bottom|"Dispenser Reagents"
! scope="col" style='width:70px; background-color:#FFDD66;'|Name
! scope="col" class="unsortable" style='background-color:#FFDD66;'|Ingredient ID
|-
|Welding Fuel
|welding_fuel
|-
|Stable Plasma
|stable_plasma
|-
|Carbon Dioxide
|co2
|-
|Oxygen
|oxygen
|-
|Hydrogen
|hydrogen
|-
|Nitrogen
|nitrogen
|-
|Chlorine
|chlorine
|-
|Fluorine
|fluorine
|-
|Mercury
|mercury
|-
|Sulfur
|sulfur
|-
|Sulphuric acid 
|sacid
|-
|Silicon
|silicon
|-
|Iodine
|iodine
|-
|Ethanol
|ethanol
|-
|Bromine
|bromine
|-
|Radium
|radium
|-
|Lithium
|lithium
|-
|Phosphorus
|phosphorus
|-
|Sodium
|sodium
|-
|Sugar
|sugar
|-
|Silver
|silver
|-
|Iron
|iron
|- 
|Copper
|copper
|-
|Aluminum
|aluminum
|-
|Space Drugs
|space_drugs
|-
|Morphine
|morphine
|-
|Miner's Salve
|mine_salve
|-
|Toxin
|toxin
|-
|Carpotoxin
|carpotoxin
|}
</div>
</div>

<!-- No particular ordering of this list besides from loosely grouping them into general solid/gas/liquid groups where appropriate and mundane and putting more unorthodox and difficult ones closer to the top -->

== Useful Player Submitted Macros ==
'''These can no longer be used on /tg/station.''' <br>

Click [https://docs.google.com/spreadsheets/d/12vRyMwELUs-dlXZN5jtBHTzW2SyXln47KEhT8nDbuzI/edit?usp=sharing this spreadsheet] for a large and player maintained list of macros.Submitted July 21 2019. <br>


'''Old/outdated list below:''' Many of the following macros are outdated and no longer work. Some of them may only work at a later tech level since you need to upgrade the manipulators in the machine to dispense less than 5u (down to 1u minimum). 

<div class="toccolours mw-collapsible mw-collapsed">
Click expand to see the list:
<div class="mw-collapsible-content">
* Oil (3u): welding_fuel=1;carbon=1;hydrogen=1
* Phenol(9u): welding_fuel=1;carbon=1;hydrogen=1;water=3;chlorine=3
* Acetone (9u): welding_fuel=4;carbon=1;hydrogen=1;oxygen=3

* Diethylamine (60u): hydrogen=30;nitrogen=10;ethanol=30
* Saltpetre (30u): potassium=10;nitrogen=10;oxygen=30
* Unstable Mutagen (90u): chlorine=30;phosphorus=30;radium=30

* Silver Sulfadiazine (90u): hydrogen=18;nitrogen=6;silver=18;sulfur=18;oxygen=18;chlorine=18
* Styptic Powder (100u): aluminium=25;hydrogen=25;oxygen=25;sacid=25
* Saline Glucose (90u): sodium=10;chlorine=10;water=40;sugar=30
* Tricordrazine(90u): nitrogen=10;silicon=25;potassium=10;carbon=25;oxygen=10;sugar=10
* Cryoxadone (90u): chlorine=10;phosphorus=10;radium=10;welding_fuel=14;carbon=4;hydrogen=4;oxygen=10;stable_plasma=30
* Clonexadone (add 5u of plasma): chlorine=5;phosphorus=5;radium=5;welding_fuel=7;carbon=2;hydrogen=2;oxygen=5;stable_plasma=15;sodium=45
* Mannitol(99u): hydrogen=33;water=33;sugar=33
* Salicylic Acid(45u): welding_fuel=1;carbon=10;hydrogen=1;water=3;chlorine=3;sodium=9;oxygen=9;sacid=9
* Oxandrolone (54u): welding_fuel=1;carbon=28;hydrogen=10;water=3;chlorine=3;oxygen=9
* Perfluorodecalin (heat to 370): hydrogen=4;fluorine=3;welding_fuel=1;carbon=1
* Atropine(45u): sacid=9;welding_fuel=5;carbon=2;hydrogen=8;oxygen=3;water=3;chlorine=3;ethanol=15;nitrogen=2
* Mutadone (90u): chlorine=10;phosphorus=10;radium=10;welding_fuel=14;carbon=4;hydrogen=4;oxygen=10;bromine=30


* Ephedrine(24u): hydrogen=11;nitrogen=1;ethanol=3;sugar=6;welding_fuel=2;carbon=2
* Epinephrine (54u): welding_fuel=5;carbon=2;hydrogen=17;water=3;oxygen=12;chlorine=12;nitrogen=2;ethanol=6
* Diphenhydramine (24u): welding_fuel=2;carbon=8;hydrogen=5;bromine=6;nitrogen=1;ethanol=9
* Synaptizine(30u): sugar=10;lithium=10;water=10
* Spaceacillin(60u): welding_fuel=5;carbon=2;hydrogen=17;water=3;oxygen=22;chlorine=12;nitrogen=2;ethanol=6;potassium=10;sugar=10
* Haloperidol(45u): welding_fuel=3;carbon=3;hydrogen=3;potassium=5;iodine=5;aluminium=9;fluorine=9;chlorine=9
* Pentetic acid(54u): stable_plasma=1;radium=1;phosphorus=1;welding_fuel=4;carbon=4;hydrogen=16;nitrogen=4;oxygen=14;oxygen=12;ethanol=12;silver=12;oxygen=10;oxygen=12;hydrogen=36;nitrogen=12;sodium=36;chlorine=36;welding_fuel=36

* Methamphetamine(Heat to 374): hydrogen=35;nitrogen=1;ethanol=3;sugar=6;welding_fuel=2;carbon=2;iodine=24;phosphorus=24
* Space Drugs (30u): lithium=10;mercury=10;sugar=10

* Napalm(9u): welding_fuel=4;carbon=1;hydrogen=1;ethanol=3

* Space Cleaner (18u): nitrogen=3;hydrogen=9;water=9
* Space Lube (12u): oxygen=3;silicon=3;water=3

* Chloral Hydrate(20u): chlorine=60;ethanol=20;water=20
* Sulfonal(27u): welding_fuel=4;carbon=1;hydrogen=7;oxygen=3;nitrogen=2;ethanol=6;sulfur=9
* Lipolicide (36u): hydrogen=17;nitrogen=3;ethanol=9;sugar=6;welding_fuel=2;carbon=2;mercury=12 
* Formaldehyde(9u, heat to 420): ethanol=3;oxygen=3;silver=3
* Fentanyl(30u, heat to 674): lithium=10;mercury=10;sugar=10
* Cyanide (9u): welding_fuel=1;carbon=1;hydrogen=4;nitrogen=1;oxygen=3
* Heparin (60u, heat to 420): ethanol=5;oxygen=5;silver=5;sodium=15;chlorine=15;lithium=15

* Antihol + Inacusiate + Oculine Step 01/02: sodium=5;chlorine=5;water=5;welding_fuel=5;carbon=5;hydrogen=5
* Antihol + Inacusiate + Oculine Step 02/02: carbon=20;ethanol=10;copper=10;water=10;hydrogen=10 //then heat the mix
* Fluorosulfuric Acid (100u): fluorine=25;hydrogen=25;potassium=25;sacid=25 //then heat the mix
</div>
</div>
<br>

= Manual Recipes for Drinks = 
{{anchor|Drinks}}
Here follows a list of simplified step-by-step instructions to mix drinks and change lives. Anyone can edit the wiki page to add additional recipes or update outdated ones. 

== [[Guide_to_drinks#Bacchus'_Blessing|Bacchus' Blessing]][[File:Bacchus_blessing.png|64px]] ==

Acquire '''5u''' Universal Enzyme and a bottle of Absinthe.<br>
Universal Enzyme is found in the kitchen or ordered at Cargo.
*Add '''60u''' Ethanol, '''30u''' Welder Fuel, '''5u''' Universal Enzyme (catalyst)
*Remove Universal Enzyme, set beaker aside
*Add '''25u''' Beer, '''20u''' Ale, '''10u''' Whiskey
*Add '''5u''' Cola
*Remove '''10u'''
*Add '''25u''' Hooch+Absinthe

== [[Guide_to_drinks#Hearty_Punch|Hearty Punch]][[File:Hearty_punch.png|64px]] ==

You'll need a spray bottle to mix this - most maps start with a bunch in the medical area.<br>

Grab a bottle of Absinthe and Kahlua from the bar fridge
* Add '''60u''' Beer, '''40u''' Whiskey, '''20u''' Cola
* Remove '''45u'''
* Add '''50u''' Tequila, '''25u''' Kahlua
* Add '''75u''' Absinthe
* Heat to >315°K
-> Results in '''15u'''

== [[Guide to food and drinks#Neurotoxin|Neurotoxin]][[File:Neurotoxin.gif|64px]] ==

Neurotoxin is also a very good toxin. 

* Add '''10u''' Gin, Vodka, Whiskey, Cognac, Lime Juice
* Add '''50u''' Morphine (found in Nanomed Plus)

== [[Guide to food and drinks#Changeling Sting|Changeling Sting]][[File:ChangelingSting.gif|64px]] ==

* Add '''20u''' Vodka
* Add '''10u''' Orange Juice
* Add '''50u''', then an additional '''10u''' of Lemon-Lime

* You probably want to disguise the drink, lest you get beaten up by security.
* Remove '''40u''', then remove an additional '''5u'''
* Add '''50u''', the an additional '''5u''' of [[Guide to food and drinks#Basic Drink Ingredients|whatever.]] The main point is to disguise the cocktail.


== [[Guide to food and drinks#Bahama Mama|Bahama Mama]][[File:Bahamamamaglass.gif|64px]] ==

* Add '''30u''' Rum, Orange Juice
* Add '''15u''' Lime Juice, Ice

== [[Guide to food and drinks#Cuba Libre|Cuba Libre]][[File:CubaLibre.png|64px]] ==

* Add '''30u''' Space Cola (found in Booze-O-Mat)
* Add '''60u''' Rum

== [[Guide to food and drinks#Demons Blood|Demons Blood]][[File:Demonsbloodglass.gif|64px]] ==

* Add '''25u''' Space Mountain Wind, Dr. Gibb (both found in Robust Softdrinks), Rum, Blood

== [[Guide to food and drinks#Doctor's Delight|Doctor's Delight]][[File:DoctorDelight.gif|64px]] ==

'''Skip this part if you already have 20u Cryoxadone ready'''
* Add '''5u''' Carbon, Hydrogen, Welding Fuel
* Add '''15u''' Oxygen, Welding Fuel
* Remove '''15u'''
* Add '''5u''' Chlorine, Phosphorus, Radium
* Add '''15u''' Stable Plasma
* Remove '''25u'''
-> '''20u''' Cryoxadone
* Add '''20u''' Lime Juice, Tomato Juice, Orange Juice, Milk Cream (found in Booze-O-Mat)

== [[Guide to food and drinks#Fetching Fizz|Fetching Fizz]][[File:Fetching_fizz.png|64px]] ==

* Add '''60u''' Space Cola
* Add '''10u''' Uranium (found by grinding uranium ore sheets)
* Remove '''20u'''
* Add '''50u''' Iron

== [[Guide to food and drinks#Three Mile Island Iced Tea|Three Mile Island Iced Tea]][[File:Threemileislandglass.gif|64px]] ==

* Add '''5u''' Space Cola (found in Booze-O-Mat)
* Add '''10u''' Rum
* Add '''15u''' Vodka, Gin, Tequila
* Remove '''10u'''
* Add '''10u''' Uranium (found by grinding uranium ore sheets)

== [[Guide to food and drinks#Telepole|Telepole]][[File:TelepoleGlass.png|alt=|64x64px]] ==

* Add '''35u''' Sol Dry
* Add '''15u''' Rum
* Add '''25u''' Voltaic Yellow Wine (found in Booze-O-Mat)
* Add '''25u''' Sake

== [[Guide to food and drinks#Pod Tesla|Pod Tesla]][[File:PodTeslaGlass.png|alt=|64x64px]] ==


Skip to step 5 if you already have telepole

* Add '''35u''' Sol Dry
* Add '''15u''' Rum
* Add '''25u''' Voltaic Yellow Wine (found in Booze-O-Mat)
* Add '''25u''' Sake
* Get a Second Glass bottle from Booze-O-Mat 
* Add '''60u''' Navy Rum
* Add '''20u''' Vermouth 
* Add '''20u''' Fernet (found in [[Hacking|hacked]] Booze-O-Mat)
* Get a Third Glass Bottle
* Add '''5u''' Kahlua 
* Add '''10u''' Tequila 
* Add '''25u''' of telepole from Bottle 1
* Add '''25u''' of admiralty from Bottle 2
* Repeat the last 4 steps until Bottles 1 and 2 are empty

== [[Guide to food and drinks#Atomic Bomb|Atomic Bomb]][[File:Atomicbombglass.gif|64px]] ==

* Add '''20u''' Whiskey
* Add '''10u''' Milk Cream (found in Booze-O-Mat)
* Add '''30u''' Kahlúa, Cognac
* Remove '''30u''', then remove an additional '''10u'''
* Add '''10u''' Uranium (found by grinding uranium ore sheets)

= Manual Recipes for Medicines =
{{anchor|Medicines}}

== [[Cryoxadone]] and [[Mutadone]] ==
* Add '''5u''' Carbon, Hydrogen, Welding Fuel
* Add '''15u''' Oxygen, Welding Fuel
* Remove '''15u''' from the beaker
* Add '''10u''' Chlorine, Phosphorus, Radium
* [[Mutadone]]: Add '''30u''' Bromine
* [[Cryoxadone]]: Add '''30u''' Stable Plasma

=== [[Guide to chemistry#Clonexadone|Clonexadone]] ===
* Remove '''40u''', then remove an additional '''5u''' of the [[Guide to chemistry#Cryoxadone|Cryoxadone]]
* Add '''40u''', then an additional '''5u''' of Sodium
* Add '''5u''' of Plasma (Chemistry starts the shift with some plasma on the desk. Grind the plasma up!)

== [[Atropine]] ==
* Add '''10u''' Carbon, Hydrogen, Welding Fuel
* Remove '''10u'''
* Add '''10u''' Chlorine, Water, Welding Fuel, Oxygen
* Add '''15u''' Hydrogen, Ethanol
* Add '''5u''' Nitrogen
* Remove '''30u'''
* Add '''20u''' Ethanol, Sulphuric Acid

== [[Pentetic Acid]] ==
* Add '''5u''' Carbon, Hydrogen, Nitrogen, Welding Fuel
* Add '''15u''' Hydrogen, Oxygen
* Remove '''30u'''
* Heat to 380°K
* Add '''5u''' Ethanol, Oxygen, Silver
* Heat to >420°K
* Add '''5u''' Nitrogen
* Add '''15u''' Chlorine, Hydrogen, Sodium, Welding Fuel

== [[Salbutamol]] ==

* Add '''5u''' Carbon, Hydrogen, Welding Fuel
* Remove '''10u'''
* Add '''5u''' Chlorine, Water
* Remove '''5u'''
* Add '''10u''' Carbon, Oxygen, Sulphuric Acid, Sodium
* Remove '''20u'''
* Add '''30u''' Hydrogen
* Add '''10u''' Nitrogen
* Remove '''20u'''
* Add '''20u''' Aluminum, Bromine, Lithium

== [[Epinephrine]] ==

* Add '''15u''' Ethanol+Hydrogen, '''5u''' Nitrogen
* Remove '''15u'''
* Add '''5u''' Carbon, Hydrogen, Welding Fuel
* Add '''5u''' Chlorine, Oxygen, Water, Welding Fuel 
* Add '''15u''' Chlorine, Hydrogen, Oxygen
* Remove '''5u''' Oil with ChemMaster

== [[Synthflesh]] ==
For 90u, impure Synthflesh (''very'' likely to heal inefficiently):
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Remove '''10u'''
* Add '''5u''' Chlorine, Water
* Remove '''5u'''
* Add '''10u''' Nitrogen, Oxygen
* Add '''30u''' Carbon, Blood (or 5u Blood + 25u Unstable Mutagen)

== [[Guide to chemistry#Anacea|Anacea]] ==

* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Remove '''5u'''
* Add '''5u''' Potassium, Iodine
* Add '''10u''' Chlorine, Fluorine, Aluminum
* Remove '''20u'''
* Add '''15u''' Mercury, Oxygen, Sugar
* Add '''30u''' Radium

== [[Guide to chemistry#Sulfonal|Sulfonal]] ==

* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Remove '''5u'''
* Add '''10u''' Welding Fuel, Oxygen
* Add '''15u''' Hydrogen, Ethanol
* Add '''5u''' Nitrogen
* Add '''30u''' Sulfur

== [[Guide to chemistry#Antihol|Antihol]] + [[Inacusiate]] + [[Oculine]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''20u''' Carbon
* Add '''10u''' Ethanol, Copper, Water, Hydrogen
* Heat to >480°K

== [[Guide to chemistry#Antihol|Antihol]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to >480°K
* Add '''15u''' Ethanol, Copper

== [[Guide to chemistry#Inacusiate|Inacusiate]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to >480°K
* Add '''15u''' Carbon, Water

== [[Guide to chemistry#Oculine|Oculine]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to >480°K
* Add '''15u''' Carbon, Hydrogen

== [[Guide to chemistry#Salicyclic Acid|Salicyclic Acid]] ==

* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Water, Chlorine
* Remove '''20u''', then remove an additional '''5u'''
* Add '''20u''' Sodium, Carbon, Oxygen, Sulphuric Acid

== [[Guide to chemistry#Oxandrolone|Oxandrolone]] ==

* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Water, Chlorine
* Remove '''30u'''
* Add '''45u''' Carbon
* Add '''15u''' Hydrogen, Oxygen

== [[Guide to chemistry#Strange Reagent|Strange Reagent]] ==

* Add '''10u''' Chlorine, Phosphorus, Radium
* Add '''30u''' Holy Water (Ask the chaplain to bless it for you)
* Add '''30u''' Omnizine (Found in heated Donk Pockets, Ambrosia Deus, and in the CMO's hypospray)

== [[Guide to chemistry#Haloperidol|Haloperidol]] ==

* Add '''10u''' Welding Fuel, Carbon, Hydrogen
* Remove '''10u'''
* Add '''10u''' Potassium, Iodine
* Add '''20u''' Chlorine, Fluorine, Aluminum

== [[Guide to chemistry#Rezadone|Rezadone]] ==

* Carpotoxin, an ingredient in Rezadone, can only be found from Space Carp, Koi Beans, or Emagged Chem Dispensers

* Add '''10u''' Oxygen, Potassium, Sugar
* Add '''30u''' [[Guide to chemistry#Carpotoxin|Carpotoxin]]
* Add '''30u''' Copper

== [[Guide to chemistry#Saline-Glucose Solution|Saline-Glucose Solution]] ==

* Add '''10u''' Sodium, Chlorine, Water
* Add '''30u''' Water, Sugar

==[[Guide to chemistry#Multiver|Multiver]] (previously [[Guide to chemistry#Charcoal|Charcoal]])==
* Add '''15u''' Sodium, Chlorine, Water
* Add '''15u''' Welding Fuel, Carbon, Hydrogen
* Heat to >480°K

== [[Guide to chemistry#Spaceacillin|Spaceacillin]] ==

* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Ethanol
* Remove '''20u'''
* Get a separate beaker
* Add '''10u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Welding Fuel, Oxygen, Water, Chlorine
* Remove '''70u'''
* Add '''20u''' of the resulting [[Guide to chemistry#Acetone|Acetone]] and [[Guide to chemistry#Phenol|Phenol]] to the main beaker
* Add '''10u''' Oxygen, Chlorine, Hydrogen
* Remove '''15u'''
* Add '''15u''' Oxygen, Potassium, Sugar

== [[Guide to chemistry#Higadrite|Higadrite]] ==

* Add '''10u''' Welding Fuel, Carbon, Hydrogen
* Remove '''10u'''
* Add '''20u''' Water, Chlorine
* Add '''30u''' Lithium

== [[Guide to chemistry#Leporazine|Leporazine]] ==

* Add '''45u''' Copper, Silicon
* Add '''5u''' Plasma (found in grinded sheets of plasma ore)

== [[Guide to chemistry#Diphenhydramine|Diphenhydramine]] ==

* Add '''30u''' Hydrogen
* Add '''10u''' Nitrogen
* Remove '''10u'''
* Get a separate beaker
* Add '''10u''' Welding Fuel, Carbon, Hydrogen
* Remove '''10u'''
* Add '''20u''' of the resulting [[Guide to chemistry#Oil|Oil]] to the main beaker
* Add '''20u''' Carbon, Bromine, Ethanol

== [[Guide to chemistry#Lenturi|Lenturi]] (Previously [[Guide to chemistry#Ichiyuri|Ichiyuri]]) ==
(Ichiyuri is now a failed chem acquired from failing to make Lenturi.)

* Add '''30u''' Hydrogen
* Add '''10u''' Nitrogen
* Remove '''10u'''
* Add '''20u''' Silver, Sulfur, Oxygen, Chlorine

== [[Guide to chemistry#Ephedrine|Ephedrine]] ==

* Add '''15u''' Hydrogen, Ethanol
* Add '''5u''' Nitrogen
* Add '''10u''' Welding Fuel, Carbon, Hydrogen
* Remove '''10u'''
* Add '''25u''' Sugar, Hydrogen

== [[Guide to chemistry#Sterilizine|Sterilizine]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to >480°K
* Add '''30u''' Chlorine, Ethanol

== [[Guide to chemistry#Pyroxadone|Pyroxadone]] ==

* Add '''5u''' Carbon, Hydrogen, Welding Fuel
* Add '''15u''' Oxygen, Welding Fuel
* Remove '''15u''' from the beaker
* Add '''10u''' Chlorine, Phosphorus, Radium
* Add '''30u''' Stable Plasma
* Remove '''45u'''
* Add '''45u''' [[Guide to chemistry#Slime Jelly|Slime Jelly]]

== [[Guide to chemistry#Energized Jelly|Energized Jelly]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to 480°K. Adding the following chemicals will cool the mix below the explosion threshold.
* Add '''10u''' Potassium, Nitrogen
* Add '''30u''' Oxygen
* Add '''30u''' Sulfur
* Remove '''50u''', then remove an additional '''20u''' and '''5u'''
* Add '''15u''' Stable Plasma, Silver
* Heat to 400°K
* Add '''45u''' [[Guide to chemistry#Slime Jelly|Slime Jelly]]

= Manual Recipes for Pyrotechnics =
{{anchor|Pyrotechnics}}

== [[Guide to chemistry#Gunpowder|Gunpowder]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to 481°K. Adding the following chemicals will cool the mix below the explosion threshold.
* Add '''10u''' Potassium, Nitrogen
* Add '''30u''' Oxygen
* Add '''30u''' Sulfur

Note: Gunpowder ignites at 474°K.

== [[Guide to chemistry#Nitroglycerin|Nitroglycerin]] ==

* Add '''30u''' Corn Oil (bug botany)
* Add '''10u''' Sulphuric Acid
* Remove '''10u'''
* Get a separate beaker
* Add '''10u''' Fluorine, Hydrogen, Potassium, Sulphuric Acid
* Heat to >380°K
* Remove '''10u'''
* Add '''30u''' of the resulting [[Guide to chemistry#Fluorosulfuric Acid|Fluorosulfuric Acid]] to the main beaker
* Get a separate beaker
* Add '''5u''' Iron, Oxygen, Hydrogen
* Use a dropper to draw '''1u''' of the resulting [[Guide to chemistry#Stabilizing Agent|Stabilizing Agent]] to the main beaker
* Dispose of the separate beaker
* Add '''30u''' Sulphuric Acid

* Heat to >474°K for the solution to explode

== [[Guide to chemistry#Napalm|Napalm]] ==

* Add '''10u''' Welding Fuel, Carbon, Hydrogen
* Add '''30u''' Welding Fuel, Ethanol

== [[Guide to chemistry#Meth Explosion|Meth Explosion]] ==

* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Ethanol
* Remove '''5u'''
* Add '''25u''' Iodine Phosphorus
* Cool to about 0°K using the space heater
* Add '''25u''' Hydrogen

* Heat to 300°K (room temperature) to activate an explosion

== [[Guide to chemistry#Teslium|Teslium]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to 480°K. Adding the following chemicals will cool the mix below the explosion threshold.
* Add '''10u''' Potassium, Nitrogen
* Add '''30u''' Oxygen
* Add '''30u''' Sulfur
* Remove '''50u''', then remove an additional '''20u''' and '''5u'''
* Add '''15u''' Stable Plasma, Silver
* Heat to 400°K

* Heat to >474°K to activate an explosion

== [[Guide to chemistry#Chlorine Trifluoride|Chlorine Trifluoride]] ==

* Add '''50u''', then add an additional '''25u''' Fluorine
* Add '''25u''' Chlorine
* Heat to >424°K

== [[Guide to chemistry#Fluorosulfuric Acid|Fluorosulfuric Acid]] ==

* Add '''25u''' Fluorine, Hydrogen, Potassium, Sulphuric Acid
* Heat to >380°K

= Manual Recipes for Drugs =
{{anchor|Drugs}}

== [[Guide to chemistry#Morphine|Morphine]] ==

* Add '''30u''' Carbon, Hydrogen
* Add '''15u''' Ethanol, Oxygen
* Heat to >480K

== [[Guide to chemistry#Methamphetamine|Meth]] ==

* Add 15u Hydrogen
* Add 5u Nitrogen
* Add 15u Ethanol
* Remove 15u
* Add 5u Welding Fuel, Carbon, Hydrogen
* Add 15 Sugar, Hydrogen
* Remove 30u Then 5u
* Add 25u Iodine, Phosphorus, Hydrogen
* Split Into 4 Bottles 25u Each (with ChemMaster or by hand)
* Heat Each Bottle Separately To >374°k NOTHING MORE NOTHING LESS
* Please Make Sure To Cool Other Chems to BELOW >380°k Before Adding The Meth

=== NEEDS UPDATING CURRENTLY MAKES YOU EXPLODE ===

== [[Guide to chemistry#Krokodil|Krokodil]] ==

* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Ethanol
* Remove '''15u'''
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Carbon, Bromine, Ethanol
* Remove '''30u''', then remove an additional '''15u'''
* Get a separate beaker
* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Water
* Remove '''15u'''
* Add '''15u''' of the resulting [[Guide to chemistry#Space Cleaner|Space Cleaner]] to the main beaker
* Add '''15u''' Potassium, Phosphorus, Welding Fuel)
* Add '''15u''' Morphine (Dispensed in the Nanomed Plus)
* Heat to >390°K

== [[Guide to chemistry#Aranesp|Aranesp]] ==

* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Water, Chlorine
* Remove '''30u'''
* Get a separate beaker
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Welding Fuel, Oxygen
* Remove '''30u'''
* Add '''15u''' of the resulting [[Guide to chemistry#Acetone|Acetone]] to the main beaker
* Get a separate beaker
* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Ethanol
* Remove '''15u'''
* Add '''15u''' of the resulting [[Guide to chemistry#Diethylamine|Diethylamine]] to the main beaker
* Add '''15u''' Oxygen, Chlorine, Hydrogen
* Remove '''30u''', then remove an additional '''15u'''
* Get a separate beaker
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Welding Fuel, Oxygen
* Get a separate beaker
* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Ethanol
* Add '''15u''' of the resulting [[Guide to chemistry#Diethylamine|Diethylamine]] to the beaker containing Acetone
* Get a separate beaker
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Water, Chlorine
* Remove '''30u'''
* Add '''15u''' of the resulting [[Guide to chemistry#Phenol|Phenol]] to the beaker containing Acetone
* Add '''15u''' of Ethanol, Sulphuric Acid
* Remove '''30u'''
* Add '''30u''' of the resulting [[Guide to chemistry#Atropine|Atropine]] to the main beaker
* Add '''30u''' Morphine (Dispensed in the Nanomed Plus)

Alternate:
* Add 30u of Epinephrine (from the Nanomed Plus)
* Add 30u of Morphine (from the Nanomed Plus)
* Get a Seperate Beaker
* Add '''10u''' Carbon, Hydrogen, Welding Fuel
* Remove '''10u'''
* Add '''10u''' Chlorine, Water, Welding Fuel, Oxygen
* Add '''15u''' Hydrogen, Ethanol
* Add '''5u''' Nitrogen
* Remove '''30u'''
* Add '''20u''' Ethanol, Sulphuric Acid
* Take 30u of the resulting Atropine and combine it with the Epinephrine and Morphine

== [[Guide to chemistry#Space Drugs|Space Drugs]] ==

* Add '''30u''' Lithium, Mercury, Sugar

=== [[Guide to chemistry#Fentanyl|Fentanyl]] ===

* Heat to >674°K

== [[Guide to chemistry#Bath Salts|Bath Salts]] ==

* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Water
* Remove '''20u'''
* Get a separate beaker
* Add '''5u''' Potassium, Nitrogen
* Add '''15u''' Oxygen
* Remove '''5u'''
* Add '''10u''' of the resulting [[Guide to chemistry#Saltpetre|Saltpetre]] to the beaker containing Space Cleaner
* Add '''10u''' Bad Food, (grind some human burgers) Nutriment, (grind some normal food, food from a vending machine will suffice) Tea, (found in the bartender's non-alcoholic drink dispenser) Universal Enzyme, (bug cargo, chef is going to be rather protective of the stuff), Mercury
* Heat to >374°K

== [[Guide to chemistry#Modafinil|Modafinil]] ==

* Add 5u Welding Fuel, Carbon, Hydrogen
* Remove 5u
* Add 5u Welding Fuel, Oxygen, Chlorine, Water
* Remove 10u
* Add 15u Hydrogen
* Add 5u Ethanol, Nitrogen
* Add 10u Sulfuric Acid, Bromine (catalyst)

= Manual Recipes for Toxins =
{{anchor|Toxins}}

== [[Guide to chemistry#Cyanide|Cyanide]] ==

* Add '''10u''' Welding Fuel, Carbon, Hydrogen, Nitrogen
* Add '''30u''' Hydrogen
* Add '''30u''' Oxygen
* Heat to >380°K

== [[Guide to chemistry#Heparin|Heparin]] ==

* Add '''10u''' Ethanol, Oxygen, Silver
* Heat to >420°K
* Remove '''5u'''
* Add '''25u''' Sodium, Chlorine, Lithium

== [[Guide to chemistry#Lipolicide|Lipolicide]] ==

* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Ethanol
* Remove '''15u'''
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Sugar, Hydrogen
* Remove '''30u'''
* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Ethanol
* Add '''30u''' Mercury

== [[Guide to chemistry#Mute Toxin|Mute Toxin]] ==

* Add '''25u''' Water, Carbon
* Add '''50u''' Uranium (found by grinding uranium ore sheets)

== [[Guide to chemistry#Sulfonal|Sulfonal]] ==

* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Welding Fuel, Oxygen
* Remove '''15u'''
* Add '''15u''' Hydrogen
* Add '''5u''' Nitrogen
* Add '''15u''' Ethanol
* Add '''30u''' Sulfur

== [[Guide to chemistry#Mulligan Toxin|Mulligan Toxin]] ==

* Add '''5u''' Chlorine, Phosphorus, Radium
* Use a dropper set to transfer 1u amounts to move '''2u''' of [[Guide to chemistry#Unstable Mutagen|Unstable Mutagen]] to another beaker
* Add '''1u''' Unstable Mutation Toxin, (found from injecting green slime extracts with radium, contact xenobiology) Blood

== [[Guide to chemistry#Mindbreaker Toxin|Mindbreaker Toxin]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to >480°K
* Add '''30u''' Hydrogen, Silicon

== [[Guide to chemistry#Formaldehyde|Formaldehyde]] ==

* Add '''30u''' Ethanol, Oxygen, Silver
* Heat to >420°K

== [[Guide to chemistry#Zombie Powder|Zombie Powder]] ==

Probably the most powerful toxin in the game currently, 1u can incapacitate for 1 minute

Add '''30u''' of: 
* Carpotoxin (can be found from Space Carp, [[Guide_to_hydroponics#Koibean|Koi Beans]], or Emagged Chem Dispensers)
* Morphine (found in nanomed plus)
* Copper

== [[Guide to chemistry#Itching Powder|Itching Powder]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to >480°K
* Add '''30u''' Hydrogen
* Add '''10u''' Nitrogen
* Add '''30u''' Fuel (drag a fuel tank out of maintenance)

== [[Guide to chemistry#Miner's Salve|Miner's Salve]] ==

* Add '''10u''' Welding Fuel, Carbon, Hydrogen
* Add '''30u''' Iron, Water

== [[Guide to chemistry#Pax|Pax]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to >480°K
* Add '''10u''' Sugar, Lithium, Water
* Add '''30u''' Water

== [[Guide to chemistry#Rotatium|Rotatium]] ==

* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to >480°K
* Remove '''20u'''
* Add '''10u''' Hydrogen, Silicon
* Get a separate beaker
* Add '''5u''' Sodium, Chlorine, Water
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Heat to 480°K. Adding the following chemicals will cool the mix below the explosion threshold.
* Add '''10u''' Potassium, Nitrogen
* Add '''30u''' Oxygen
* Add '''30u''' Sulfur
* Remove '''50u''', then remove an additional '''30u'''
* Add '''10u''' Silver, Stable Plasma
* Heat to >400°K, but below 474°K
* Add '''30u''' of the resulting [[Guide to chemistry#Teslium|Teslium]] to the main beaker
* Get a separate beaker
* Add '''10u''' Lithium, Mercury, Sugar
* Heat to >674°K
* Add '''30u''' of the resulting [[Guide to chemistry#Neurotoxin|Neurotoxin]] to the main beaker

=== <s>[[Guide to chemistry#Skewium|Skewium]] </s>===
Skewium no longer exists. 
* Remove '''50u'''
* Add '''40u''' of Plasma (grind some raw plasma)
* Add '''20u''' of Sulphuric Acid

== [[Guide to chemistry#Carbon Dioxide|Carbon Dioxide]] ==

* Add '''30u''' Carbon
* Add '''60u''' Oxygen
* Heat to >777°K

== Herbicides ==

=== [[Guide to chemistry#Weed Killer|Weed Killer]] ===

* Add '''60u''' Hydrogen
* Add '''20u''' Nitrogen
* Add '''30u''' Hydrogen
* Add '''10u''' Nitrogen
* Remove '''10u'''
* Add '''20u''' Toxin (found in hacked Nanomed Plus)

=== [[Guide to chemistry#Pest Killer|Pest Killer]] ===

* Add '''80u''' Ethanol
* Add '''20u''' Toxin (found in hacked Nanomed Plus)

=== [[Guide to chemistry#Plant-B-Gone|Plant-B-Gone]] ===

* Add '''80u''' Water
* Add '''20u''' Toxin (found in hacked Nanomed Plus)

= Manual Recipes for Utility =
{{anchor|Utility}}

== [[Guide_to_construction#Plastic|Plastic sheets]] ==
The main use for plastic sheets is making large water bottles - these are functionally identical to large beakers.

* Add 30 units each of Welding Fuel, Carbon and Hydrogen to a large beaker. 
* This combines into [[Oil]]. Discard 10 units.
* Separate 30 units of [[Oil]], then heat the bottle to 1000°K until it turns to Ash.
* To the remaining [[Oil]], add 20 units [[Sulphuric Acid]]. 
* Add the Ash to the [[Oil]]/[[Sulphuric Acid]] mix.
* Now, heat the resulting mix to roughly 375°K.
* You now have enough [[Guide_to_construction#Plastic|Plastic]] sheets to make a lot of large bottles!

== Metal foam grenade ==
While not as elegant as smart foam, this one is great for dealing with AI turrets and containing [[Critter]] outbreaks.

* Make enough [[Fluorosulfuric Acid]] and [[Foaming Agent]] that you end up with 30u each.
* Fill beaker A with 90 units of Iron and insert into the grenade casing.
* Put 30u of [[Fluorosulfuric Acid]] and [[Foaming Agent]] each into beaker B and finish up the grenade.

== [[Guide to chemistry#Firefighting Foam|Firefighting Foam]] ==

* Add '''20u''' Carbon, Fluorine
* Add '''10u''' Sulphuric Acid
* Remove '''20u'''
* Add '''10u''' Iron, Oxygen, Hydrogen
* Add '''30u''' Carbon
* Cool to 200°K

= Manual Recipes for Virology =
{{anchor|Virology}}


== [[Guide to chemistry#Virus Food|Virus Food]] ==

* Add '''30u''' Water, Milk (found by using a Biogenerator. Or milk a goat or a cow. Or from [[File:Milk.png]] Space Milk cartons, 50 units in each. 5 are found in kitchen freezer. Ordered food crate has one.)

=== [[Guide to chemistry#Virus Rations|Virus Rations]] ===

* Remove '''30u''', then remove an additional '''15u'''
* Add '''15u''' Sugar, Lithium, Water

=== [[Guide to chemistry#Mutagenic Agar|Mutagenic Agar]] ===

* Remove '''30u''', then remove an additional '''15u'''
* Add '''15u''' Chlorine, Phosphorus, Radium

==== [[Guide to chemistry#Sucrose Agar|Sucrose Agar]] ====

* Remove '''30u''', then remove an additional '''10u'''
* Add '''50u''' of Sugar or Saline-Glucose Solution

=== [[Guide to chemistry#Virus Plasma|Virus Plasma]] ===

* Remove '''30u''', then remove an additional '''10u'''
* Add '''50u''' of Plasma (found when grinding plasma ore)

==== [[Guide to chemistry#Weakened Virus Plasma|Weakened Virus Plasma]] ====

* Remove '''30u''', then remove an additional '''15u'''
* Add '''15u''' Sugar, Lithium, Water

==== [[Guide to chemistry#Unstable Uranium Gel|Unstable Uranium Gel]] ====

* Remove '''50u''', then remove an additional '''25u'''
* Add '''50u''', then an additional '''25u''' of Uranium (found when grinding uranium ore)

=== [[Guide to chemistry#Decaying Uranium Gel|Decaying Uranium Gel]] ===

* Remove '''30u''', then remove an additional '''10u'''
* Add '''50u''' of Uranium (found when grinding uranium ore)

== [[Guide to chemistry#Stable Uranium Gel|Stable Uranium Gel]] ==

* Add '''30u''', then an additional '''10u''' of Silver, Uranium (found when grinding uranium ore) 
* Add '''4u''' of Plasma (found when grinding plasma ore) using a dropper set to use 1u amounts

= 'Fun' =

== Carpet smoke grenade ==
Want to spruce up the station? Start throwing these grenades everywhere. Obscures vision for a while.

* Make 30 units of [[Space Drugs]] and extract 30u of Blood from someone.
* Beaker A: 30u [[Space Drugs]], 30u Potassium.
* Beaker B: 30u Phosphorus, 30u Blood, 30u Sugar.

== [[Guide to chemistry#Colorful Reagent|Colorful Reagent]] ==
Grab a spray bottle to mix.

'''Skip this part if you already have 60u Cryoxadone ready'''
* Add '''5u''' Carbon, Hydrogen, Welding Fuel
* Add '''15u''' Oxygen, Welding Fuel
* Remove '''15u''' from the beaker
* Add '''10u''' Chlorine, Phosphorus, Radium
* Add '''30u''' Stable Plasma
* Remove '''30u''' from the beaker
--> '''60u''' Cryoxadone
* (Add '''60u''' Cryoxadone)
* Add '''20u''' Lithium, Mercury, Sugar
* Remove '''20u'''
--> '''50u''' Cryoxadone and Space Drugs
* Add '''10u''' Lemon+Lime+Orange Juice (Triple Citrus)
* Add '''50u''' Radium, Stable Plasma

== [[Guide to chemistry#Corgium|Corgium]] ==

'''Skip this part if you already have 15u Cryoxadone ready'''
* Add '''5u''' Carbon, Hydrogen, Welding Fuel
* Add '''15u''' Oxygen, Welding Fuel
* Remove '''15u'''
* Add '''5u''' Chlorine, Phosphorus, Radium
* Add '''15u''' Stable Plasma
* Remove '''30u'''
-> '''15u''' Cryoxadone
* (Add '''15u''' Cryoxadone)
* Go to the bar, ask the bartender for some [[Guide to food and drinks#Triple Citrus|Triple Citrus]]. If the bartender isn't there, climb onto the table, and access the non-alcoholic drink dispenser. (It isn't ID locked!) Add '''5u''' Lemon Juice, Lime Juice, Orange Juice
* Add '''5u''' Lithium, Mercury, Sugar
* Add '''15u''' Stable Plasma, Radium
* Remove '''50u''', then remove an additional '''10u'''
* Get a separate beaker (a normal beaker which can hold 50u will do just fine, albeit by this point you should probably have bluespace beakers or large water bottles)
* Add '''5u''' Chlorine, Phosphorus, Raddium
* Remove '''10u'''
* Add '''5u''' Holy Water (get the chaplain to bless it for you)
* Add '''5u''' Omnizine (You can get omnizine through grinding heated donk pockets, or through nicely asking the botanist, since omnizine is naturally found in Ambrosia Deus. If you're lucky, the CMO starts the shift with his/her hypospray loaded with omnizine.)
* Add '''15u''' of the resulting [[Guide to chemistry#Strange Reagent|Strange Reagent]] to the original beaker
* Add '''15u''' of Nutriment (Just vend some food from the Getmore Chocolate Corp and grind it up)
* Get a separate beaker (normal beaker is aforementioned fine)
* Add '''15u''' of Blood
* Heat the beaker containing only blood to about 1000°K

'''How to maxcap the station with absolute adorableness'''

* Acquire a dropper, and adjust it to transfer in 1u amounts
* Go to your target destination
* Draw 1u of the heated blood (Solutions do not lose heat over time! The only way to change the temperature of a solution is by using a heater or a freezer.)
* Inject 1u of the heated blood into your other beaker. Every time 1u of blood is injected into the other beaker, an independent reaction occurs, which produces a corgi.
* Repeat. All your hard work will eventually lead to 15 corgis being let loose onto the station.

== [[Guide to chemistry#Life|Life]] ==

* Add '''5u''' Chlorine, Phosphorus, Radium
* Add '''15u''' Holy Water (Ask the chaplain to bless it for you, or ask the botanist for holymelons)
* Add '''15u''' Omnizine (Found in heated Donk Pockets, Ambrosia Deus, and in the CMO's hypospray)
* Remove '''15u'''
* Get a separate beaker for [[#Synthflesh|Synthflesh]] (this will need buffers, or it will fail)
* Add '''5u''' Welding Fuel, Carbon, Hydrogen
* Remove '''10u'''
* Add '''5u''' Chlorine, Water
* Remove '''5u'''
* Add '''10u''' Nitrogen, Oxygen
* Add '''30u''' Carbon, Blood (or 5u Blood + 25u Unstable Mutagen)
* Add '''30u''' of the resulting Synthflesh to the main beaker
* Add '''30u''' Blood (for hostile life) or '''30u''' Sugar (for friendly life)
Heat beaker to at least 375K.

== [[Guide to chemistry#Quantum Hair Dye|Quantum Hair Dye]] ==

'''Skip this part if you already have 15u Cryoxadone ready'''
* Add '''5u''' Carbon, Hydrogen, Welding Fuel
* Add '''15u''' Oxygen, Welding Fuel
* Remove '''15u'''
* Add '''5u''' Chlorine, Phosphorus, Radium
* Add '''15u''' Stable Plasma
* Remove '''30u'''
-> '''15u''' Cryoxadone
* (Add '''15u''' Cryoxadone)
* Go to the bar, ask the bartender for some [[Guide to food and drinks#Triple Citrus|Triple Citrus]]. If the bartender isn't there, climb onto the table, and access the non-alcoholic drink dispenser. (It isn't ID locked!) Add '''5u''' Lemon Juice, Lime Juice, Orange Juice
* Add '''5u''' Lithium, Mercury, Sugar
* Add '''15u''' Stable Plasma, Radium
* Remove '''30u''', then remove an additional '''15u'''
* Add '''10u''' Lithium, Mercury, Sugar
* Add '''30u''' Radium

== [[Guide to chemistry#Barber's Aid|Barber's Aid]] ==

* Add '''5u''' Lithium, Mercury, Sugar
* Add '''15u''' Blood
* Add '''10u''' Lithium, Mercury, Sugar
* Add '''30u''' Radium

=== [[Guide to chemistry#Concentrated Barber's Aid|Concentrated Barber's Aid]] ===

* Remove '''30u''' and then remove an additional '''15u'''
* Add '''15u''' Chlorine, Phosphorus, Radium

== [[Guide to chemistry#Condensed Capsaicin|Condensed Capsaicin]] ==

* Add '''15u''' of Capsaicin (bug botany for chilis)
* Add '''75u''' of Ethanol

== [[Guide to chemistry#Spray Tan|Spray Tan]] ==

* Add '''15u''' Welding Fuel, Carbon, Hydrogen
* Add '''15u''' Orange Juice (found in the bartender's non-alcoholic drink dispenser)

== [[Guide to chemistry#Nitrous Oxide|Nitrous Oxide]] ==

* Add '''30u''', and then an additional '''15u''' of Hydrogen
* Add '''15u''' of Nitrogen
* Remove '''5u'''
* Add '''20u''' Nitrogen
* Add '''40u''' Oxygen
* Heat to 525°K

Note: Nitrous Oxide explodes at 575°K

== [[Guide to chemistry#Laughter|Laughter]] ==

A suitable substitute gift for the clown. Unlike Space Lube, will most likely not get you lynched.

* Add '''50u''' Sugar, Banana Juice (can only be acquired through juicing raw bananas, which can be found in botany)

== [[Guide to chemistry#Synthmeat|Synthmeat]] ==

'''Skip this part if you already have 15u Cryoxadone ready'''
* Add '''5u''' Carbon, Hydrogen, Welding Fuel
* Add '''15u''' Oxygen, Welding Fuel
* Remove '''15u'''
* Add '''5u''' Chlorine, Phosphorus, Radium
* Add '''15u''' Stable Plasma
* Remove '''30u'''
-> '''15u''' Cryoxadone
* (Add '''15u''' Cryoxadone)
* Add '''75u''' Blood

== [[Guide to chemistry#Carpet|Carpet]] ==

* Add '''15u''' Lithium, Mercury, Sugar
* Add '''45u''' Blood

[[Category:Guides]][[Category:Chemistry]]

{{Speech
|name=Chief Medical Officer Kingston
|text=Doctor! I need you to tear out that man's appendix, throw that clown out of medical, and stitch up that curator's face!
|image=[[File:Generic_cmo.png|64px|right]]
}}

Medical care is serious business, and going halfway with your medical treatment can result in someone dying or worse. Make sure you know what you're doing before you try to fix someone up!

If you're going to treat someone, you're going to have to know what tools you need, how to identify injuries, what machinery and facilities you must use, and how to keep people from dying while in treatment.

== Identification ==

First of all, grab a [[File:MedGlasses.png]] [[Clothing_and_Accessories#Health_Scanner_HUD|Health Scanner HUD]] from the medical storage and wear it. It shows the patient's overall health condition and therefore shows you instantly whom you should treat first from a group of patients. Identification is the first and foremost step in administering treatment. Here are ways to identify the type of injuries a person may have:

=== Types of damage ===

* There are four primary types of damage: '''{{TGMEDOXY}}''', '''{{TGMEDBRUTE}}''', '''{{TGMEDBURN}}''', and '''{{TGMEDTOX}}.''' These damage types have first aid kits associated with them and are therefore treatable without needing further medical equipment. The standard white first aid kit has materials to treat '''{{TGMEDBRUTE}}''', '''{{TGMEDBURN}}''', and {{TGMEDBLEEDING}}
* There are additional kinds of injury that occur less often: '''organ damage/brain damage''', {{TGMEDWOUND}}s and {{TGMEDBLEEDING}}. These are typically lethal as a result of the infliction of one or more of the base damage types, not on their own.
* You want the patient to be as healthy as possible, so you have to heal all of these to get someone back to tip-top shape.
* The overall health status of a humanoid is determined by adding the totals of the four basic damage types together, and subtracting this value from their max health. Their max health is almost always 100, but it is not '''always''' 100.
* If the patient has taken a total of about 100 damage (depending on mood), he will be in '''critical condition (0%)'''. This state forces him to lie down, prevents passive {{TGMEDOXY}} healing, and causes him to fail one in four breaths, thus causing very slow {{TGMEDOXY}}. He can still crawl. At -50%, he enters a state called Hard-crit, as distinguished from the previous critical state, Soft-crit. He is now completely inactionable and made forcibly unconcious. He will also stop breathing entirely, and thus begin to quickly suffocate. At -100%, he dies.
* Bleeding is a bit different. See [[#Bleeding|below]] or the [[Guide_to_Wounds#Slash_Wounds|guide to wounds]] for a more extensive explanation.

* You can identify these different damage types quickly by using a [[Medical_items#Health_Analyzer|Health Analyzer]] on the patient. You can also '''examine''' the patient (shift-click), but it only shows basic information. [[Quirks#Empath|Empaths]] will get more info here.
* If a Health Analyzer is not available, '''observing''' the patient and their surroundings will help with diagnosis:
:* If there is a pile of '''vomit''' next to, or under the patient then they are most likely suffering from [[Guide_to_medicine#Toxins|{{TGMEDTOX}}]].
:* If there is blood everywhere, blood on the person dying, or the patient has '''severe bruises''', they are suffering from [[Guide_to_medicine#Brute_Damage|{{TGMEDBRUTE}}]].
:* If the patient has black scars across their body and no blood, or the patient has '''severe burns''', they have been [[Guide_to_medicine#Burns|{{TGMEDBURN}}]]ed.
:* If the patient is gasping, they are most likely taking [[Guide_to_medicine#Suffocation|{{TGMEDOXY}}]] or in critical condition.
:* If the patient keeps fainting, trails drips of blood as they walk or is unresponsive to other forms of "healing" they may be {{TGMEDBLEEDING}} or be suffering from low {{BLOOD}}.
:* If the patient reports other symptoms such as headaches, coughing or vomiting blood, they most likely have a [[Infections|virus]] or organ damage.

===Your first patient===

Your patient can arrive in two ways:

'''1. The patient walks in and needs treatment.'''
:''"PLS DOC HLEP!!"'' You can see the patient's overall health status with your Health Scanner HUD with just a glance. However, this will only tell you how serious the situation is and how quickly you need to act.

:How to act:

:* Use a [[Medical_items#Health_Analyzer|Health Analyzer]] on the patient to identify the damage type.
:* Proceed with the necessary [[#Treatment|treatment found in the next chapter]].

'''2. The patient is dragged into Medbay and is in critical condition.'''
:The patient is unresponsive to the environment, on the floor, and gasping for air.

:How to act:

:* The first thing you should do is administer [[Guide_to_chemistry#Epinephrine|Epinephrine]]. [[Guide_to_chemistry#Epinephrine|Epinephrine]] stops the general decline of the critical patient's health and helps treat damage if the patient is in crit.  Don't give them 30 or more units of it, as they will overdose, causing {{TGMEDTOX}}.  
:* If the patient is {{TGMEDBLEEDING}}, apply a suture [[File:Suture.png]] and/or gauze [[File:Gauze.png]] to the bodypart with the {{TGMEDWOUND}} . Dragging a {{TGMEDBLEEDING}} patient will quickly drain their {{BLOOD}}, unless you use a roller bed.
:* If [[Guide_to_chemistry#Epinephrine|Epinephrine]] is not available, immediately perform [[#CPR|CPR]] a few times to ensure the patient stays alive until you do the next step.  Make sure they're also not suffering from any other significant problems, like being on fire, or in a low-pressure environment.
::'''NOTE: CPR on its own will not heal someone unless they are only suffering from {{TGMEDOXY}}. If they are in crit because of {{TGMEDBRUTE}}, {{TGMEDBURN}} or''' {{TGMEDTOX}} '''damage it will only keep them from dying.'''
:* Now you have several options to choose between:
:# Take the patient to a [[#Lifeform_Stasis_Units|stasis bed]]. Drag the patient until on top of it, then click-drag the patient to the bed to buckle. Give the patient [[Guide_to_chemistry|medicine]] and then click the stasis bed to unbuckle. 
:# Strap the patient to a [[#Lifeform_Stasis_Units|stasis bed]] (like above). Bring or print the surgery tools needed to perform [[Surgery#Tend_Wounds|Tend Wounds]]. Take off the patient's jumpsuit by click dragging their sprite onto yours, and then clicking the jumpsuit. Perform the [[Surgery#Tend_Wounds|tend wounds surgery]] until the body is fully repaired, and then click the stasis bed to unbuckle. This can only be used to heal {{TGMEDBRUTE}} and {{TGMEDBURN}}. Hide the patient's stuff in a locker while doing surgery, to prevent theft. 
:# Strip the patient's space suit off if they have one and put the patient into a [[Medical_items#Cryogenics_Chamber_.26_Freezer|cryochamber]], wait for them to heal up and eject.
:# Just use [[Medical_items#Suture|sutures]] [[File:Suture.png]], [[Medical_items#Regenerative_Mesh|regenerative mesh]] [[File:Regenerative_mesh.png]] or other appropriate medication. See [[#Treatment|next section]] for examples.

== Treatment ==

===[[File:O2med.png]] {{TGMEDOXY}}===
This is the first and most important to look out for. It is not visible on the body, but people suffering from it will ''gasp for air''. If you take 50 or more {{TGMEDOXY}}, you faint. On the Health Analyzer, it is the leftmost, <font color=blue>blue</font> damage type.

'''Ways of getting damaged:'''

* Being in an area without enough oxygen present will suffocate you, dealing {{TGMEDOXY}}.
* Missing a significant amount of blood will deal {{TGMEDOXY}} over time.
* Once you are in critical condition, you slowly take {{TGMEDOXY}}.
* Some [[Guide_to_chemistry##Medicines|medicines]] and [[Guide_to_chemistry#Aranesp|drugs]] can deal {{TGMEDOXY}}. 
* Some poisons, like [[Cyanide]], deal {{TGMEDOXY}}.
* Some [[Virus|virus]] symptoms can cause {{TGMEDOXY}}.
* Missing a pair of lungs.
* Missing a heart, or suffering a heart attack.

'''Treatment:'''

* If a person is in crit, you can CPR{{anchor|CPR}} them. Remove your and patient's mask and helmet, turn off {{Combat_Mode}} and {{LeftclickCmodeoff}} click on them.
* If a person is not in critical condition, and they have no bad chemicals in their bloodstream, placing them in an oxygen-filled area will suffice.
* [[Epinephrine]] stops the {{TGMEDOXY}} that is dealt from being in a crit state. 
* [[Salbutamol]] quickly treats {{TGMEDOXY}}. 
* [[Guide_to_chemistry#Convermol|Convermol]] very quickly heals {{TGMEDOXY}}, but deals a lot of {{TGMEDTOX}}.
* [[Cryoxadone]] in a [[Medical_items#Cryogenics Tube & Freezer|cryotube]] heal most types of damage, including {{TGMEDOXY}}. Alternatively, a sleeping patient in the cold can also benefit from cryoxadone
* [[Orange juice]] isn't the most effective cure, but it does help a bit when no other options are available
* If a person is missing a heart, replace their heart or give them [[Guide_to_chemistry#Cordiolis_Hepatico|Cordiolis Hepatico]].
* If a person's heart is unstable, use a [[defibrillator]] and their heart should return to normal, or give them [[Guide_to_chemistry#Cordiolis_Hepatico|Cordiolis Hepatico]]. Other electric shocks might be able to restore their heartbeat.

===[[File:Brutefak.png]] <font color=red>{{TGMEDBRUTE}}</font>===
This is a straight-forward damage category. This is the far right damage type on Health Analyzer. {{TGMEDBRUTE}} is visible, and limb-specific.

'''Ways of getting damaged:'''

* Being physically hit by almost anything does {{TGMEDBRUTE}}.
* Some [[Guide_to_chemistry#Fluorosulfuric_Acid|chemicals]] can deal {{TGMEDBRUTE}}.

'''Treatment:'''

* [[Medical_items#Suture|Sutures]] [[File:Suture.png]] can be applied to the damaged limb. Use a medical scanner or ask the patient to examine themselves.
* [[Surgery#Tend_Wounds|Tend Wounds]] surgery will heal {{TGMEDBRUTE}} and {{TGMEDBURN}} very efficiently (but will not treat special [[Guide_to_Wounds|wounds]]). 
* [[Guide_to_chemistry#Probital|Probital]] pills heal {{TGMEDBRUTE}} over time. 
* [[Guide_to_chemistry#Salicylic_Acid|Salicylic Acid]] heals {{TGMEDBRUTE}} over time, and is more effective on severe injuries. 
* [[Saline-glucose solution]] heals {{TGMEDBRUTE}} slowly. 
* [[Cryoxadone]] in a [[Medical_items#Cryogenics Tube & Freezer|cryotube]] or a very cold environment heal most types of damage, including {{TGMEDBRUTE}}. Alternatively, a sleeping patient in the cold can also benefit from cryoxadone
* Food can heal {{TGMEDBRUTE}} slowly.
* Milk, bilk, soy milk, soy latte, [[Guide_to_drinks#Coffee_Latte|cafe latte]], and cream can heal it very slowly.
* [[Guide_to_chemistry#Libital|Libital]] patches ({{TGMEDBRUTE}} patches) will heal {{TGMEDBRUTE}} pretty fast but don't use it too often on the same patient, due to long term side effects. 
* [[Guide_to_chemistry#Helbital|Helbital]] should only be used in emergency situations on people with multiple damage types. 
* There are some job-specific ways of healing it: Donuts heal security, bananas and banana juice heal clowns and monkeys, "nothing" in mime's bottle of nothing heals mimes.

===[[File:Bmed.png]] {{TGMEDBURN}}===

This is a straight-forward damage category. This is the damage type second to the right on Health Analyzer. Burns are visible, and limb-specific.

'''Ways of getting damaged:'''

* Temperatures too high or too low cause {{TGMEDBURN}}. That includes coldness of space and being set on fire.
* Lasers deal {{TGMEDBURN}}.
* Some [[Guide_to_chemistry#Phlogiston|chemicals]] deal {{TGMEDBURN}}.
* Electric shocks deal {{TGMEDBURN}}.

'''Treatment:'''

* [[Medical_items#Regenerative_Mesh|Regenerative mesh]]  can be applied to the damaged limb. Use a medical scanner or ask the patient to examine themselves.
* [[Surgery#Tend_Wounds|Tend Wounds]] surgery will heal {{TGMEDBRUTE}} and {{TGMEDBURN}} very efficiently. 
* [[Guide_to_chemistry#Hercuri|Hercuri]] heals {{TGMEDBURN}} over time. 
* [[Guide_to_chemistry#Oxandrolone|Oxandrolone]] heals {{TGMEDBURN}} over time, and is more effective on severe burns. 
* [[Guide_to_chemistry#Saline-Glucose_Solution|Saline-glucose solution]] heals {{TGMEDBURN}} slowly. 
* [[Cryoxadone]] in a [[Medical_items#Cryogenics Tube & Freezer|cryotube]] or a very cold environment heal most types of damage, including {{TGMEDBURN}}. Alternatively, a sleeping patient in the cold can also benefit from cryoxadone
* [[Tomato juice]] can heal it very slowly.
* [[Guide_to_chemistry#Aiuri|Aiuri]] patches ({{TGMEDBURN}} patches) will heal {{TGMEDBURN}} pretty well but don't use it too often on the same patient, due to long term side effects. 
* There are some job-specific ways of healing it: Donuts heal security, bananas and banana juice heal clowns and monkeys, "nothing" in mime's bottle of nothing heals mimes.

===[[File:Tmed.png]] {{TGMEDTOX}}===
This is the second from the left on the Health Analyzer. It is not visible on the person's health doll. Thankfully it is easy to treat.

'''Ways of getting damaged:'''

* Breathing plasma deals {{TGMEDTOX}}.
* Many [[Guide_to_chemistry#Toxins|chemicals]] deal {{TGMEDTOX}}.
* Drinking a lot of alcohol can hurt your liver and deal {{TGMEDTOX}}.
* A severely damaged or missing liver will deal {{TGMEDTOX}}. Liver failure will also prevent the patient from processing most reagents.
* High doses of [[#Radiation|radiation]] deal {{TGMEDTOX}}.
* Mind the difference between chemical named Toxin and {{TGMEDTOX}}. 

'''Treatment:'''

* [[Guide_to_chemistry#Syriniver|Syriniver]] heals {{TGMEDTOX}} and weakly purges toxic chemicals. Use in an IV drip or across multiple small (5u) injections. Causes liver damage, and is very easy to accidentally overdose someone with (especially if you attempt to inject someone in stasis).
* [[Guide_to_chemistry#Multiver|Multiver]] heals {{TGMEDTOX}} and purges other chemicals. If used in combination with other medicine reagents, it'll work faster, and it won't purge medicines! Causes lung damage.
* [[Guide_to_chemistry#Calomel|Calomel]] purges toxic chemicals more quickly than pentetic acid but doesn't heal {{TGMEDTOX}}, and will '''deal''' {{TGMEDTOX}} if the patient has 20 health or more. 
* [[Guide_to_chemistry#Pentetic_Acid|Pentetic acid]] heals {{TGMEDTOX}} and purges all other chemicals quickly. Also purges [[#Radiation|radiation]]. 
* [[Cryoxadone]] in a [[Medical_items#Cryogenics Tube & Freezer|cryotube]] or a very cold environment heal most types of damage, including {{TGMEDTOX}}. Alternatively, a sleeping patient in the cold can also benefit from cryoxadone
* Lime juice, tea, iced tea can slowly heal it.
* Vomiting heals some {{TGMEDTOX}}. You usually can't control it, however you can induce vomiting with a stomach pump.
* If patient has a failing liver, a liver transplant will stop the {{TGMEDTOX}} caused by that liver, and will allow chemicals to work in the body.

===[[File:Blood Pack.png]] {{TGMEDBLEEDING}}===
{{TGMEDBLEEDING}} is commonly caused by [[Guide_to_Wounds#Slash_Wounds|slash or pierce]] {{TGMEDWOUND}}s 

Some items that may help stop or alleviate {{TGMEDBLEEDING}} are:
* [[Guide_to_chemistry#Suture|Suture]] [[File:Suture.png]]
* [[Guide_to_chemistry#Gauze|Gauze]] [[File:Gauze.png]]
* [[Medical_items#Cautery|Cautery]] [[File:Cautery.png]]
* [[Guide_to_chemistry#Sanguirite|Sanguirite]] [[File:Bottle.png]]

Read the [[Guide_to_Wounds|guide to wounds]] for full details about how to stop {{TGMEDBLEEDING}}. 

Replace lost {{BLOOD}} with an [[Medical_items#IV drip|IV drip]] [[File:IV Drip.png]] and/or iron [[Medical_items#Pills|pills]]. 

'''WARNING: Incorrect blood types are toxic to the patient, and will not replenish their''' {{BLOOD}}'''!'''

{| class="wikitable" style="text-align:center; font-size: 75%;"
|+ Blood compatibility table
|-
! rowspan="2" | Recipient
! colspan="9" | Donor
|-
! O−
! O+
! A−
! A+
! B−
! B+
! AB−
! AB+
! L
|-
! O−
| style="width:3em" | [[File:Yes.png]]
| style="width:3em" | [[File:No.png]]
| style="width:3em" | [[File:No.png]]
| style="width:3em" | [[File:No.png]]
| style="width:3em" | [[File:No.png]]
| style="width:3em" | [[File:No.png]]
| style="width:3em" | [[File:No.png]]
| style="width:3em" | [[File:No.png]]
| style="width:3em" | [[File:No.png]]
|-
! O+
| [[File:Yes.png]]
| [[File:Yes.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
|-
! A−
| [[File:Yes.png]]
| [[File:No.png]]
| [[File:Yes.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
|-
! A+
| [[File:Yes.png]]
| [[File:Yes.png]]
| [[File:Yes.png]]
| [[File:Yes.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
|-
! B−
| [[File:Yes.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:Yes.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
|-
! B+
| [[File:Yes.png]]
| [[File:Yes.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:Yes.png]]
| [[File:Yes.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
|-
! AB−
| [[File:Yes.png]]
| [[File:No.png]]
| [[File:Yes.png]]
| [[File:No.png]]
| [[File:Yes.png]]
| [[File:No.png]]
| [[File:Yes.png]]
| [[File:No.png]]
| [[File:No.png]]
|-
! AB+
| [[File:Yes.png]]
| [[File:Yes.png]]
| [[File:Yes.png]]
| [[File:Yes.png]]
| [[File:Yes.png]]
| [[File:Yes.png]]
| [[File:Yes.png]]
| [[File:Yes.png]]
| [[File:No.png]]
|-
! L
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:No.png]]
| [[File:Yes.png]]
|}

'''Treating''' {{BLOOD}} '''loss:'''
# Bandage {{TGMEDWOUND}} with a medical gauze to stop {{TGMEDBLEEDING}}.
# Heal {{TGMEDWOUND}} using sutures, gauze, coagulants, etc.
# Assess {{BLOOD}} levels, if low or critical, proceed with blood transfusion.
# If a blood transfusion is unavailable, {{BLOOD}} will be naturally produced by the body, albeit slowly.
# Iron and most foods will improve {{BLOOD}} regeneration.
#[[Guide_to_drinks#Bloody_Mary|Bloody Mary]] will also replenish lost {{BLOOD}}.

'''Blood transfusion:'''
# Use medical scanner on patient to find blood type.
# Obtain blood pack from [[surgery]], [[virology]], or [[cargo]].
# Make sure IV drip is in the blue "inject" mode. You toggle this by clicking the IV drip when nothing is attached to it. 
# Attach blood pack to IV drip.
# Click-drag IV drip onto patient. 
# Check up on patient's {{BLOOD}} level regularly, this process moves quickly. 
# Detach patient from IV drip by click-dragging the IV drip onto the patient again, or simply clicking the IV. If you forget this the patient will take some {{TGMEDBRUTE}} and possibly end up with a small {{TGMEDBLEEDING}} {{TGMEDWOUND}} from the needle being ripped out.
# Detach blood pack by clicking on the IV drip.

'''Blood donation:'''
# Make sure IV drip is in the red "take" mode. You toggle this by clicking the IV drip when nothing is attached to it. 
# Attach a beaker or an empty blood pack to IV drip.
# Attach to a donor by click-dragging it onto the donor.
# Blood pack will automatically fill. The alarm will sound if patient's {{BLOOD}} levels reach critical.
# Detach IV drip by click-dragging it onto the donor again or simply clicking the IV.
# Click on IV drip to eject the beaker or blood pack. Label appropriately.

=== [[File:Liver_organ.png]] Organ damage ===

Organ damage will cause side-effects as they reach thresholds, which will alert the owner when passed. If an organ shows up as "non-functional", that means its failing, and will not work, and will cause some life-threatening ailments depending on which organ it is. There is currently no way to see the exact damage of each organ, but for the most part they function on low-threshold, high-threshold, and failing, which will show up as "mildly damaged", "severely damaged", and "non-functional" lists when you scan someone with a medical scanner. Note that all the listed organs decay over time, which is the most common way they'll get damaged- but [[Surgery#Cybernetic_Organs|synthetic organs]] do not! The best way to avoid any of these side-effects is to replace your fleshy organs for [[Surgery#Cybernetic_Organs|metallic ones]], though these too come with downsides in the form of EMP vulnerability.

'''Ways of getting damaged:'''

* Flashes and sharp objects in the eyes (eyes)
* Loud noises (ears)
* Appendicitis (appendix)
* Otherwise, an organ that's not in a living body (thus is on the ground or in a dead body) will decay if not held in a freezer, fridge, morgue unit, or [[Machines#Smartfridge|organ smartfridge]]. Organs will go from perfectly healthy to broken in about 13-17 minutes, except for hearts, which will decay completely in about 6 minutes, and brains, which will decay completely in 30 minutes.

'''Treatment:'''

* [[Surgery#Coronary_Bypass|A coronary bypass]] can be performed on a heart that's decayed past 60 damage, and restores functionality. Good for getting a heart that's too damaged to defib to work again.
* [[Surgery#Lobectomy|A lobectomy]] will do the same as above but for the lungs, which will scarce occur due to their decay timer, but it's still an option. 
* [[Guide_to_chemistry#Oculine|Oculine]] will rapidly fix damaged eyes, clearing any shortsightedness/blindness caused by damage.
* [[Guide_to_chemistry#Inacusiate|Inacusiate]] will immediately fix damaged ears to a perfect state.
* Otherwise, time and health will fix most organs (not the brain!). The healthier you are, the faster this rate goes, with a base rate of around half an hour for an organ to go from max damage to perfectly healthy. Taking vitamins increases your health, and thus increases this rate, so eat smart!

'''Side-Effects:'''

* Damaged ears will occasionally flare up with tinnitus, causing very brief deafness, with increasingly frequent bouts until the ears are non-functional, at which point you become deaf.
* Damaged eyes will grow increasingly short-sighted, until finally becoming blind when non-functional.
* Damaged lungs will make you cough, increase the rate at which you breath by 25% and will collapse if non-functional, causing rapid {{TGMEDOXY}}. Life-threatening!
* A non-functional appendix will burst, causing {{TGMEDTOX}} until the organ is removed. Life-threatening!
* A damaged heart will increase the rate at which you breath by 25%, and will cease when non-functional, causing immediate heart attack. Life-threatening!
* A damaged stomach will be unable to hold nutriment and food down as easily, causing vomiting depending on the amount of food consumed and the damage of the stomach. A non-functional stomach makes you unable to eat or drink. 

====Organ table====
Each organ has 100 max hp except the eyes which have 50, and the brain which has 200. 
{|class="wikitable"
!scope="col" style="font-weight: bold;" style='background-color:#C4DAF4;'| 
!scope="col" style="font-weight: bold;" style='background-color:#C4DAF4;'| Organ
!scope="col" style="font-weight: bold;" style='background-color:#C4DAF4;'| Decay time
!scope="col" style="font-weight: bold;" style='background-color:#C4DAF4;'| Damage effects
!scope="col" style="font-weight: bold;" style='background-color:#C4DAF4;'| Non-functional/broken effects
!scope="col" style="font-weight: bold;" style='background-color:#C4DAF4;'| Treatment
|-
|[[File:Heart.png]]
|Heart
|6 minutes
|Expends oxygen faster by increasing breathing rate. 
|Heart attack. The patient will fall [[Status_Effects#Unconscious|unconscious]] and rapidly take {{TGMEDOXY}} and {{TGMEDBRUTE}} until death. A broken heart stops [[#Defibrillation|defibrillation]] from working when dead. 
|[[Surgery#Coronary_Bypass|Coronary bypass]] or replacing the heart with [[Surgery#Organ_Manipulation|surgery]]. Heart attack is treatable with [[#Defibrillation|defibrillation]] unless the heart is broken. 
|-
|[[File:Liver_organ.png]]
|Liver
|15 minutes
|{{TGMEDTOX}} and lower toxin purge threshold. 
|Rapid {{TGMEDTOX}} and chemicals are no longer processed. 
|[[Guide_to_chemistry#Higadrite|Higadrite]] and/or replacing the liver with [[Surgery#Organ_Manipulation|surgery]]. 
|-
|[[File:Lungs.png]]
|Lungs
|16.5 minutes
|Coughing and expends oxygen faster by increasing breathing rate. 
|Prevents breathing, leading to rapid death from {{TGMEDOXY}}. 
|[[Surgery#Lobectomy|Lobectomy]] or replacing the lungs with [[Surgery#Organ_Manipulation|surgery]]. 
|-
|[[File:Appendix.png|Appendix]]
|Appendix
|15 minutes
|Nothing.
|It bursts, causing {{TGMEDTOX}} until the organ is removed. 
|Removing the appendix with [[Surgery#Organ_Manipulation|surgery]]. 
|-
|[[File:Stomach_organ.png]]
|Stomach
|13 minutes
|Causing vomiting depending on the amount of food consumed and the damage of the stomach. 
|Can't eat or drink.
|Replacing the stomach with [[Surgery#Organ_Manipulation|surgery]]. 
|-
|[[File:Eyes.png]]
|Eyes
|15 minutes
|Worsening eyesight until fully blind. 
|Blindness. 
|[[Guide_to_chemistry#Oculine|Oculine]] or [[Surgery#Eye_Surgery|eye surgery]]. 
|-
|[[File:Ears.png]]
|Ears
|15 minutes
|Worsening occasional tinnitus, causing very brief deafness. 
|Deafness.
|[[Guide_to_chemistry#Inacusiate|Inacusiate]]. 
|-
|[[File:Brain.png]]
|Brain
|30 minutes
|See [[#Brain_damage|Brain damage]].
|Death.
|See [[#Brain_damage|Brain damage]].
|}

=== [[File:Brain.png]] Brain damage ===

Nasty. Randomly causes [[Guide_to_Traumas|brain traumas]] and other problems. If a brain reaches 0% health, the person dies. To be able to see exact brain health you can use an advanced health analyzer; the [[CMO]] gets one of by default. 

'''Ways of getting damaged:'''

* Certain chemicals such as [[Guide_to_chemistry#Mercury|mercury]], [[Guide_to_chemistry#Impedrezene|impedrezene]], or [[Guide_to_chemistry#Fentanyl|fentanyl]]
* Abusing certain [[Guide_to_chemistry#Narcotics|narcotics]].
* [[Chaplain]]'s bible applied to the head.
* [[Blood Cult|Unholy Water]]
* [[Infections#Infection_Listings|Brainrot]]
* Earthsblood from [[Guide_to_hydroponics#Plants|Ambrosia Gaia]].

'''Treatment:'''

* [[Guide_to_chemistry#Mannitol|Mannitol]] pills or injections slowly cure brain damage, but does not cure [[Guide_to_Traumas|brain traumas]]. Can be poured directly on a brain. 
* [[Guide_to_chemistry#Neurine|Neurine]] will treat the most '''basic''' brain traumas. These traumas have no prefix on health analyzer. When used on the dead will heal a corpse's brain slowly.
* [[Surgery#Brain_Surgery|Brain Surgery]], will also cure '''severe''' traumas. You can identify severe brain traumas by the prefix "severe" on health analyzer.
* [[Surgery#Lobotomy|Lobotomy]] will cure '''deep-rooted brain traumas''', but at the risk of causing a different '''permanent''' trauma. You can identify deep-rooted brain traumas by the prefix "deep-rooted" on health analyzer.
* '''Permanent''' brain traumas are either permanent or curable with magic, which is typically unavailable. A lobotomy can cause these traumas. You can identify permanent brain traumas by the prefix "permanent" on health analyzer. If you get one of these, then assume "this is my life now".

=== [[File:DoubleESword.png]] Dismemberment ===

Patients may lose their head, legs or arms. A patient missing arms can't hold items or interact with objects. Missing legs will slow down a patient, but missing both legs also prevents them from holding any items unless they're buckled to a chair, and will force them to crawl around on the floor. Missing both arms and legs renders the patient a nugget with no ability to move or interact outside of talking. Patients missing a head will die in most cases as their body lacks its brain.

Examining a patient will describe any missing limbs.


'''Ways of getting damaged:'''
* Strong physical forces, such as explosions.
* Getting hit by strong, sharp objects such as swords.
* Patients who experience severe trauma to the chest may have their organs spill out, but the torso will remain intact.
* Amputation via [[surgery]].

'''Treatment:'''
* [[Surgery#Prosthetic_Replacement|Prosthetic replacement]] via [[surgery]].
** Cyborg limbs may be used. Robotics can produce cyborg limbs, but there is also a crate of cheap prosthetic limbs in Medbay Storage.
** Organic limbs may be used. In most cases, a detached limb can be found and reattached. However, all the limb's damage will be transferred to the patient, so be ready to treat {{TGMEDBRUTE}} and {{TGMEDBLEEDING}}.
** Synthetic limbs from a [[Limb Grower|limb grower]] may be used. The limb grower can only produce arms and legs, unless [[Emag|emagged]].
** Peg limbs crafted from wood planks may be directly slapped onto the body without the need for surgery. The downside of this is that they are unable to use certain items such as guns, and are quick to fall off after taking damage.

=== {{TGMEDWOUND}}s ===
A patient may suffer special [[Guide_to_Wounds|wounds]] to specific bodyparts. See the [[Guide_to_Wounds|guide to wounds]] to learn how to identify and treat them. 



== Using Stasis Beds, Cryogenics and Sleepers ==
{{anchor|Using Sleepers and Cryogenics}}

=== [[File:Stasis_bed_off.png]][[Medical_items#Lifeform_Stasis_Unit|Lifeform Stasis Units]]===
These "[[Medical_items#Lifeform_Stasis_Unit|Stasis Beds]]" can be found in [[Medbay|medbay]]. They are [[Machines#Lifeform_Stasis_Unit|constructable]] [[Guide_to_construction#Machines|machines]]. You can buckle patients to them to put them into '''stasis'''. While in stasis they will temporarily stop {{TGMEDBLEEDING}}, no longer process [[Guide_to_chemistry|reagents]] or [[Infections|diseases]] (good or bad), and their organs will no longer rot. Buckle [[Health#Critical_Status|badly hurt]] or [[#Death|dead]] patients on them to be able to safely treat them without them dying. Give them any [[Guide_to_chemistry#Core_Healing_Medicines|medicine]] they need and then remove the patients from the stasis bed so the medication starts healing them. The patient is awake and fully aware while in stasis, unless otherwise rendered unconcious. You can turn the beds off or on with alt-click.

Important to note: if the patient is unconscious and has a large amount of {{TGMEDOXY}}, they're be unable to wake up on their own if they're still on the activated stasis bed. Either remove them or turn off the bed to allow them to recover. Many a patient has been left unconscious on the stasis bed for as long as twenty minutes! Don't subject people to that, it's infuriating.

=== [[File:Cryo.gif]] [[Medical_items#Cryogenics Tube & Freezer|Cryogenics Tube]] ===
{{anchor|Cryo Tube}}
Cryotube uses the fact that [[cryoxadone]] is effective at healing all types of damage, but only works in cold environments and if the patient is knocked out (roundstart cryo-air has some n2o!). Use it mainly if you're out of other options, if you're unsure what to do or if your hands are full. This is slow and forces the patient to sleep, so prefer using {{TGMEDBRUTE}}/{{TGMEDBURN}} patches for common damage types. 

Baseline cryo consumes 0.04u of beaker reagents per tick and transfers 1u to the patient in the tube. Cryogenics Tubes basically squeeze more use out of a small amount of chemicals. 

[[Guide_to_advanced_construction#Cryogenics_Tube|Cryotubes can also be upgraded by science parts.]] Better matter bins allow them to work slightly faster and more efficiently; every matter bin level multiplies the transfer rate.

You can quickly operate the Cryogenics Tube without opening the menu with a few shortcuts. ALT + left click will toggle the doors, and CTRL + left click will toggle the power. 

How to prepare '''(This needs to be done at the start of every round!)''':
# Wrench the oxygen/n2o canisters to connect them to the tubes and the freezer.
# Turn on the [[Atmospherics_items#Freezer|freezer]]. Set it to lowest temperature available.
# Load beakers with [[Guide_to_chemistry|chemicals]]. A common and highly effective mix for general use is [[cryoxadone]] and [[mannitol]] but experimentation reaps results! 
#* All [[Guide_to_chemistry|chemicals]] will work, so you can add anything. This is the job of [[chemist]]s.
#* Be sure to only add chemicals that you can't overdose on, as patients in cryo will receive large doses of all chemicals in the beaker.
# Set the tubes to Auto instead of Manual, so they'll open after the patient is healed. Otherwise, they'll be trapped in until someone opens the tube from outside.

How to use:

# Ensure the cryo tube is open first. If not, open it.
# Pull the person on top of the tube. 
# Remove all clothes that prevent freezing, such as MOD suits. Else it won't work. 
# Close the cryo tube with its menu, or click on them with your mouse and drag their sprite to the tube.
# Open the tube menu and turn it on. If their health starts to improve (sometimes it takes a moment to start), they're all set. If not, make sure everything is set up properly (cryoxadone in the tubes? pressure in the canisters?).
# Turning it on will put the patient to sleep. 
# If set to auto, the tube will turn off and pop open automatically. 
# {{LeftclickCmodeoff}} Shake the person multiple times to get them up.
# Let them redress (or do it for them) then kick them out.
<br>
If you ever see this:<br>
[[File:Trapped_in_cryo.png]]

Then those people are trapped in powered off cryo tubes. Run to them immediately and either turn the tubes ON or let the patients out! Make sure cryo tube doors are also set to AUTO and not MANUAL. And make sure the patients are actually healing, or else you have to try other treatments instead.

=== [[File:Sleeper.gif]] [[Medical_items#Sleeper|Sleeper]] ===

Sleepers were removed from most places May 2019 and replaced with [[#Lifeform_Stasis_Unit|Stasis Beds]], but may still exist in some locations, such as the Syndicate Listening Post. They allow you to inject various chemicals, and have unlimited stocks of them. Keep in mind that when the patient's health is very low, sleepers become unusable, with the exception of injecting [[epinephrine]].

Sleepers also show you chemicals present in person's bloodstream.

Scientists can produce upgraded parts for [[Guide_to_advanced_construction#Sleeper|sleepers]]. 

How to use:
# Ensure the sleeper is open. If it's not, open it.
# Pull the patient near the sleeper.
# Click and hold on the patient, move the cursor to the sleeper, then release. This puts the patient inside.
# Click on the sleeper to open the menu.
# Inject chemicals they need. (See the [[Machines#Sleeper|list of sleeper chemicals]] available). 
# Open the sleeper and remove the patient. 


== Rarer Cases ==

These situations are not as common as normal damages, but they are still VERY LIKELY to happen. AND most of these cases are also more severe, and it is essential to be fucking fast and know this stuff! <br>'''So read up, these are the things that will separate quacks from real doctors!'''

===Overdose===
Giving too much of some chemicals or drugs can cause an overdose. This means that you aren't doing your job correctly and you may even kill the patient if you don't stop doing it! Check the ''overdose threshold'' column in the [[Guide_to_chemistry#Medicines|guide to chemistry]] before you use a medicine. 

How to treat:
* [[Guide_to_chemistry#Multiver|Multiver]] purges chemicals slowly and can help with {{TGMEDTOX}}. Only use small amounts and make sure there is at least one other medicine in the patient first. 
* [[Calomel]] purges chemicals quickly and is relatively easy to make in chemistry.
* [[Pentetic acid]] clears all chemicals from the body very quickly.
* The [[Surgery#Filter_Blood|filter blood]] surgery also allows you to clear chemicals, though it has diminishing returns depending on the amount of chemicals left.

===[[File:Hudill.png|32px]] Disease===

Diseases are the most frustrating thing you will deal with, as it spreads, and can infect you as well. A disease can be identified easily with the Health Scanner HUD, it giving an unhappy-face-icon next to the patient. A Health Analyzer will give more detailed information about the disease and its cure.

How to Treat:
# Suit up in [[Clothes_and_internals#bodywear|anti-viral equipment]].
# Isolate the patient from public areas (if they have an infectious disease).
# Use your Health Analyzer or disease scanner to see the cure for the disease (see the [[Infections#Understanding_stats|list of possible cures]]). This won't work if the disease is stealthy.
# If the virus is stealthy, you must take a blood sample to a PanD.E.M.I.C 2200 to see the cure. 
# Administer the chemical element needed OR if the virologist has made a vaccine, administering one unit of it will instantly cure and immunize.
# Monitor the patient's condition and do not leave them until they are clear and have become resistant to the disease.
# Check if you are infected after dealing with the patient.
After:
* If you did not have the vaccine for the disease, see [[Infections#How_to_create_a_vaccine|How to create a vaccine]].

===Blindness===
The person cannot see, they usually will scream about this endlessly.

How to treat:
* If vision is just blurry, give [[Guide_to_plants#Carrot|carrot]]s or a pair of [[prescription glasses]].
* If they are completely blind, [[Surgery#Eye surgery|eye surgery]].
* [[Omnizine]] has a chance of curing blindness while slowly healing eye damage.
* [[Guide_to_chemistry#Oculine|Oculine]] can be made by chemistry, and will heal all eye damage.

===Deafness===
The person cannot hear, they are usually unresponsive to verbal communication and can't even hear themselves talking.

What causes it:
* Genetic mutations can cause genetic deafness.
* Ear damage can render a person deaf temporarily, but extreme ear damage causes permanent deafness.
* Explosions cause ear damage.
* Flashbangs cause ear damage.

How to treat:
* Most ear damage will heal on its own.
* [[Guide_to_chemistry#Inacusiate|Inacusiate]] heals minor ear damage instantly.
* Put earmuffs on the patient and minor ear damage will quickly heal.
* Mutadone can reset genetic mutations including deafness.

===Genetic Disabilities===
Disabilities cannot be cured by normal medical tools. If a patient appears to be unable to move and/or they speak in very short sentences, they most likely have a genetic disability.

How to treat:
* Ask a competent [[geneticist]] to remove the bad mutation. 
* A one unit [[Guide_to_chemistry#Mutadone|mutadone]] pill or injection will instantly cure all genetic abnormalities. This includes beneficial ones.

===Radiation===
Radiation causes people to take steady {{TGMEDTOX}} and periodically take {{TGMEDBURN}} to their chest. Radiation can come from radiation storms and [[Guide To Drinks#Nuka Cola|Nuka Cola]], but more likely you'll be treating engineers who got too close to the supermatter or people standing near badly contained fusion work. 

An irradiated patient will:

* Have a green outline.
* Have a status effect on their screen telling them that they are irradiated.

How to treat:
* Give the patient a shower to stop them from taking more {{TGMEDTOX}} and {{TGMEDBURN}}.
* Give the patient [[potassium iodide]], [[pentetic acid]], [[Guide to drinks#Vodka|vodka]], cold [[Guide to chemistry#Seiver|seiver]] or any other {{TGMEDTOX}}/{{TGMEDTOX}}-while-irradiated healing medicine. The irradiation will go away once all of the patient's {{TGMEDTOX}} is healed.
* Treat the {{TGMEDBURN}}.
Note: since you will be treating mostly engineers, they might have infected {{TGMEDBURN}} {{TGMEDWOUND}}s from being struck by emitters. This will cause {{TGMEDTOX}} to never reach 0, so you'll want to deal with the infection first or ya know - just toss them in cryo.

===Hallucinations===
This nasty effect causes the victim to see (usually deadly) objects in his and others' hands, along with random visions of people and creatures attacking him, causing stamina damage. Extremely unpleasant. Caused by [[Changeling|changelings]], [[Guide_to_chemistry#Mindbreaker_Toxin|mindbreaker toxin]] ,[[supermatter|the supermatter]], and some bad 'shrooms.

How to treat:
* [[Synaptizine]] is good for removing hallucinations. But can cause light {{TGMEDTOX}}. 
* [[Haloperidol]] is not as good as synaptizine at removing hallucinations, but it will also quickly purge drugs that are likely causing them.

===Embedded Objects===
Remove embedded objects in a patient by using a [[File:Hemostat.png|Hemostat]] hemostat on the patient's affected limb.

==[[File:Huddead.png|32px]] Death==
So your patient is dead. There are several [[#Typical_cases_of_death|typical cases of death]]. If your patient is a [[#Normal_dead_body|normal dead body]] though (with a head and brain), your first course of action is usually to prepare the body for [[#Defibrillation|defibrillation]]. Cloning no longer exists on /tg/station since Feb, 2020. 

===Revival methods===
====[[File:Defib.png]]Defibrillation====
The [[Medical_items#Defibrillator|defibrillator]] can shock a body back to life. Defibrillation does not have a timed window (as of Jan 2020), but the heart will [[#Organ_damage|decay]] in only 4 minutes and must typically be [[Surgery#Coronary_Bypass|repaired]] for a late defibrillation to work. Other [[#Organ_table|organs]] may be damaged as well. 

# Examine the body. Does it say they '''committed suicide''' or that their '''soul has departed'''? Nothing you can do for them, fast track them to the [[morgue]].
# If the body has this icon [[File:Huddefib.gif|32px]] on your [[Medical_items#Health_Scanner_HUD|health scanner hud]] it means its soul is still online and has not used the "Do Not Resuscitate" button. Inject the patient with some [[Guide_to_chemistry#Formaldehyde|formaldehyde]] ([[General_items#Epinephrine_MediPen|medipens]] have some) or buckle them to a [[#Lifeform_Stasis_Units|Stasis Bed]] to stop the organ decay, and scan them with a [[Medical_items#Health_Analyzer|health analyzer]]. Do they have more than 180 {{TGMEDBRUTE}} or {{TGMEDBURN}} (tracked separately, having 179 of each is fine)? If so, you must heal the corpse with [[Guide_to_chemistry#Synthflesh|synthflesh]] or [[Surgery#Tend_Wounds|surgery]] until it has under 180 {{TGMEDBRUTE}} and {{TGMEDBURN}}. You can buy [[Guide_to_chemistry#Synthflesh|synthflesh]] from the [[Vending_machines#NanoMed_Plus|NanoMed Plus]] or have it made in [[Guide_to_chemistry#Synthflesh|chemistry]].
# If the [[Medical_items#Health_Analyzer|health analyzer]] says the patient's heart is non-functional, the heart must be [[Surgery#Coronary_Bypass|repaired]] or [[Surgery#Organ_Manipulation|replaced]]. 
# If the patient is wearing a space suit or [[Clothing_and_Accessories#Hardsuits|MOD suit]], take it off. To take it off, drag the sprite of the patient onto yours, and click the MOD suit (it's in backpack slot) in the menu that pops up. 
# [[File:Husk.png]] If the body is a grey husk see [[#Husk|husk]]. 
# If the patient is missing too much {{BLOOD}}, do a [[#Bleeding|blood transfusion]]. 
# If the patient has large amounts of bad reagents, do a [[Surgery#Stomach_Pump|stomach pump]].
# If the patient has {{TGMEDWOUND}}s consider treating them (before or after the defib).  
# Once the patient is prepared, equip your [[Medical_items#Defibrillator|defib]]. The [[Medical_items#Defibrillator|large one]] goes on your backpack slot, and the [[Medical_items#Compact_Defibrillator|compact defib]] that the [[CMO]] gets goes on your belt slot. Then empty both of your hands, and click the new defib hud icon on your top left to take out the paddles. Activate/click the paddles with the hand you're holding them in to wield them in both hands. Stop dragging the patient (with '''H''' or '''delete''') or you will be shocked. Turn off {{Combat_Mode}}, target the chest, and then click on the patient. After a few seconds, you'll deliver an electric shock. 
# If the defib pings and says the resuscitation was successful, use [[#Treatment|medicine]] on them and unbuckle them from the [[#Lifeform_Stasis_Units|Stasis Bed]] to make them start healing up. If the defib instead says they have severe tissue damage, they are either a [[#Husk|husk]], have a non-functional crucial organ or have more than 180 {{TGMEDBRUTE}} or {{TGMEDBURN}}, and need to be repaired more. 

A successful defibrillation will instantly heal some basic damage and put the patient in a hardcrit state. If the revived patient had less damage than that the defib will instead deal {{TGMEDOXY}} to put them in crit. 

====Strange Reagent====
Another option for revival is the [[Guide_to_chemistry|chemical]] [[Guide_to_chemistry#Strange_Reagent|strange reagent]], which works similarly to [[#Defibrillator|defibrillation]], except with slightly different requirements (read them [[Guide_to_chemistry#Strange_Reagent|here]]). Use the same steps to prepare the body as before [[#Defibrillator|defibrillation]], except this revival method also restores some {{BLOOD}} and organ damage depending on how much of the reagent you use. Must be [[Guide_to_chemistry#Ingest|ingested]].

====Replica Pod cloning====
If you can't find the patient's brain your only choice is try to turn them into a [[Podman|podperson]]. See [[Guide_to_hydroponics#Replica_Pod_Cloning|here]] how. Note there is no way for you to see if a brainless body has a soul or not, since the examine message won't tell you. If the patient has no {{BLOOD}}, you can give blood to the corpse, then use that for podding.

====Revival surgery====
[[Surgery#Revival|Revival surgery]] is an optional way to bring people back to life. See the [[Surgery#Revival|surgery]] page for details. This may be useful for races without hearts since it makes you defibrillate the head instead of the heart. 

===Typical cases of death===
The following tables contain suggested actions for when you encounter corpses, heads or brains. 

====Normal dead body====
Examine the body. <br>
{|class="wikitable" style="width:80%" border="1" cellspacing="0" cellpadding="2"
!scope="col" style="font-weight: bold;" style='background-color:#C4DAF4;'| Body examine message
!scope="col" style="font-weight: bold;" style='background-color:#C4DAF4;'| Means
!scope="col" style="font-weight: bold;" style='background-color:#C4DAF4;'| Treatment
|-
|They are limp and unresponsive; there are no signs of life... 
|The patient has a connected soul/ghost online and is thus eligible for revival. '''Note:''' A corpse without brain/head shows this message even if there is no soul. 
|See [[#Revival_methods|revival methods]]. 
|-
|They are limp and unresponsive; there are no signs of life and their soul has departed...
|No soul. Can not be revived. Caused by patient ghosting (leaving body when alive), logging off or using the Do-Not-Resuscitate action. Or there never was a soul in the first place. 
|Bring to morgue. 
|-
|Their soul seems to have been ripped out of their body. Revival is impossible.
|Patient [[Devil#Contracts|sold]] or lost their soul. Can not be revived. 
|Bring to morgue. 
|-
|They appear to have committed suicide... there is no hope of recovery.
|Patient committed suicide, which makes revival impossible. 
|Bring to morgue. 
|-
|It appears that their brain is missing...
|Brain is missing. 
|See [[#Replica_Pod_cloning|Replica Pod cloning]]. 
|-
|Their head is missing!
|Head is missing. 
|See [[#Replica_Pod_cloning|Replica Pod cloning]]. 
|}

====Head without body====
Examine the head. <br>

{|class="wikitable" style="width:80%" border="1" cellspacing="0" cellpadding="2"
!scope="col" style="font-weight: bold;" style='background-color:#C4DAF4;'| Head examine message
!scope="col" style="font-weight: bold;" style='background-color:#C4DAF4;'| Means
!scope="col" style="font-weight: bold;" style='background-color:#C4DAF4;'| Treatment
|-
|The brain has been removed from ''name's'' head.
|No brain. Nothing you can do. 
|Bring to morgue. 
|-
|There's a miserable expression on ''name's'' face; they must have really hated life. There's no hope of recovery.
|Suicide. Nothing you can do. 
|Bring to morgue. 
|-
|It's leaking some kind of... clear fluid? The brain inside must be in pretty bad shape.
|The brain inside has 0 health. 
|
*Option 1: Attach head to a body with [[Surgery#Prosthetic_Replacement|prosthetic replacement]], fix brain with [[Surgery#Brain_Surgery|brain surgery]]. Then see [[#Revival_methods|revival methods]]. This preserves identity. 
*Option 2: Cut the brain out and repair it with [[Guide_to_chemistry#Mannitol|mannitol]]. Put it in a new body with [[Surgery#Organ_Manipulation|organ manipulation]]. Then see [[#Revival_methods|revival methods]].
|-
|Its muscles are twitching slightly... It seems to have some life still in it.
|Head has a soul. 
|Move head or brain to a new body with surgery and use a [[#Revival_methods|revival method]]. 
|-
|It's completely lifeless. Perhaps there'll be a chance for them later.
|Head's soul isn't around anymore, but revival may be possible if it comes back (online). 
|Leave it around or put the brain in a Man-Machine Interface [[File:MMI.png|MMI]] so it can talk if it comes back. 
|-
|It's completely lifeless. 
|No soul. Permanent. 
|Bring to morgue. 
|}

====[[File:Brain.png]]Brain without body====
Examine the brain. <br>
{|class="wikitable" style="width:80%" border="1" cellspacing="0" cellpadding="2"
!scope="col" style="font-weight: bold;" style='background-color:#C4DAF4;'| Brain examine message
!scope="col" style="font-weight: bold;" style='background-color:#C4DAF4;'| Means
!scope="col" style="font-weight: bold;" style='background-color:#C4DAF4;'| Treatment
|-
|It's started turning slightly grey. They must not have been able to handle the stress of it all.
|Suicide. Nothing you can do. 
|Bring to morgue. 
|-
|It seems to still have a bit of energy within it, but it's rather damaged... You may be able to restore it with some mannitol.
|Brain has 0 health. 
|Repair it with [[Guide_to_chemistry#Mannitol|mannitol]]. Put it in a new body with [[Surgery#Organ_Manipulation|organ manipulation]]. Then see [[#Revival_methods|revival methods]]. 
|-
|You can feel the small spark of life still left in this one, but it's got some bruises. You may be able to restore it with some mannitol.
|Brain is damaged but not broken.
|Same as above. 
|-
|You can feel the small spark of life still left in this one.
|Brain is fine and has a soul. 
|Put it in a new body with [[Surgery#Organ_Manipulation|organ manipulation]]. Then see [[#Revival_methods|revival methods]].
|-
|This one is completely devoid of life.
|No soul. Permanent. 
|Bring to morgue. 
|}

====[[File:Husk.png|32px]]Husk====
Typically a victim of heavy [[#Burns|{{TGMEDBURN}}]]. It can be unhusked with 100u [[Guide_to_chemistry#Synthflesh|synthflesh]] or 5u [[Guide_to_chemistry#Rezadone|rezadone]]. The corpse must have under 50 {{TGMEDBURN}} for it to work. Proceed to [[#Revival_methods|revival methods]] afterwards. If unhusking doesn't work then the corpse may be a [[Changeling|changeling]] victim. A Changeling victim needs a brain transplant to be revivable.

====Completely messed up corpse====
A body could be missing all limbs except head, be husked, bloodless, contaminated with radiation and have 600 damage etc. In these cases the simple solution is to [[Surgery#Amputation|amputate]] the head and attach it to a fresh body with [[Surgery#Prosthetic_Replacement|prosthetic replacement]], or remove its brain with a scalpel/screwdriver, followed up by [[Surgery#Organ Manipulation|organ manipulation]]. Then use your [[#Revival_methods|revival method]] of choice.

== Afternote ==
'''PLEASE NOTE''' In the morgue there are lights on the side of the trays. The red light means there is a dead body with no ghost occupying it. The green light means there is a body with a ghost in it, which means you should attempt to [[#Revival_methods|revive]] it. The yellow light means there are no bodies, and only objects in the morgue. The green light is normally accompanied by a beeping sound as well, which can be turned off by alt-clicking the tray. If you aren't serious about healing someone, don't give up halfway. Get proper medical staff to help them. At least try to have a doctor save them.

[[Category:Guides]]

== Recovered NT Employee corpse ==
Medical may order the body of a previously deceased Nanotrasen employee, either from this station or another. 

They will arrive inside a a body bag in a freezer. They start with formaldehyde in their bodies so you don't have to worry about decay.

Your job is to bring them back! Fix whatever killed them, and any decay or organ/limb loss may have occurred. When the body is fixed, you can revive them to bring a new player back into the round! Bodyswapping is not covered by their insurance, so don't do it!

If no ghost takes the body, it will die again. Revive it again to retry. 

[[File:Recovered crew corpses.png|thumb]]

=== On success ===
The new crewmember arrived with a mind-lockbox, make sure they get it! It contains vital equipment for them to get started. 

After 3 minutes of continued survival, a medical announcement will inform you of your success, and the original cost of the package + a little extra will be sent to the medical budget. 

=== Maximizing success ===
Ghosts can see how messed up the body is. Having a healthy body makes the odds of a ghost taking it quite a bit bigger! No one wants to spend 5 minutes looking at themselves in crit when you could've fixed this beforehand! 

Also take into account the current server population. There may just not be any ghosts to take the body, in which case <s>make some</s> just keep it around until there are!   

=== Upgrades people, Upgrades! ===
Before reviving a recovered crew corpse, consider installing some cybernetic enhancements assuming science has performed the requisite research. This can create crewmembers stronger than shiftstart ones, along with increasing general utility and power, some examples of highly useful implants include...   

Nutriment pumps, welding shields, toolset implants: Reduce food consumption, provide welding immunity, or have a suite of fast tools in their arms, removing the need to lug around tools.   

Xray and thermal vision, combat implants like revivers, CNS rebooters, and antidrops: Are  less useful if the revived crewmember does not see combat often, however installing these in recovered security officers can give you a massive advantage over antagonists, allowing them to retake or maintain control of the station.   

Breathing tubes, implanted thruster implants: are really niche and only useful for space exploration, even less useful on recovered crewmates as most of the time they'll be staying onstation.   

Cybernetic organs of all types, from livers to lungs: Don't decay, allowing for easy revival assuming no EMP shenanigans.    

=== You're not a doctor... ===
On occasion, recovered crew corpses may be ordered by departments other than medical, such as robotics who will most likely fully augment, install cybernetic organs on every part of them, and <s>stea</s>l borrow a defibrillator from medical to revive them. You should let other departments  be unless they actively steal corpses you are working from directly from medical.


Keep in mind antagonists such as traitors, spies, changelings and heretics like to secure recovered crew in order to revive and brainwash them or use their body for their antagonistic goals. On the topic of antagonists, successfully revived recovered crewmembers can roll from any midround dynamic ruleset, from sleeper agents to an obsession awakening. 

== Recovered Crew ==
{{JobPageHeader
|headerbgcolor = Green
|headerfontcolor = Black
|stafftype = SPECIAL
|imagebgcolor = #FFFFFF
|img_generic = 
|img = Recovered crew.png
|jobtitle = Recovered Crew
|access = None
|additional = Random visitor acces
|difficulty = Easy
|superior = Whoever employs you
|duties = Work it up
|guides = This is the guide
|quote = Back from the dead and reporting for duty!
}}

=== I. LIVE. AGAIN.  ===
Welcome back! You died anywhere between a few days and a years ago, but were recovered by Nanotrasen and revived by on one of their stations!


You should arrive with a mind-lockbox that only you can open, giving you a starters ID and a jumpsuit! If you don't get this box, scream at whoever revived you.

You should set your bank account, and find a job! You were assigned visitor acces to a random department to help you get started, talk to the Head of Personnel or a head of staff to get a proper assignment. You don't have to take a job in the department you were assigned, but it may help you find purpose in life!
