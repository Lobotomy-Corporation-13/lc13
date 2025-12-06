// RCE Body Parts - Items dropped by marked enemies

/obj/item/rce_bodypart
	name = "biological sample"
	desc = "A biological sample extracted from a terminated hostile organism. Used for research purposes."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "brain-x"
	w_class = WEIGHT_CLASS_SMALL
	var/base_value = 10 // Base research points
	var/list/traits = list() // List of traits this part has
	var/source_mob = "unknown" // Name of the mob this came from

/obj/item/rce_bodypart/Initialize()
	. = ..()
	update_appearance()

/obj/item/rce_bodypart/proc/assign_traits(list/new_traits)
	traits = new_traits.Copy()
	update_appearance()
	update_desc()

/obj/item/rce_bodypart/proc/update_appearance()
	// Change appearance based on traits
	if((TRAIT_CORRUPTED in traits) || (TRAIT_HYBRID in traits))
		color = "#8B008B" // Dark purple for corrupted
		name = "corrupted biological sample"
	else if(TRAIT_ORGANIC in traits)
		color = "#8B0000" // Dark red for organic
		name = "organic tissue sample"
	else if(TRAIT_MECHANICAL in traits)
		color = "#4682B4" // Steel blue for mechanical
		name = "mechanical component"
		icon_state = "cyberimp"

	if(TRAIT_ELITE in traits)
		name = "elite [name]"
		add_atom_colour("#FFD700", FIXED_COLOUR_PRIORITY) // Gold tint for elite

/obj/item/rce_bodypart/proc/update_desc()
	desc = initial(desc)
	if(source_mob != "unknown")
		desc += " Extracted from [source_mob]."

	if(length(traits))
		desc += "\n\nDetected traits:"
		for(var/trait in traits)
			desc += "\n• [trait]: [get_trait_description(trait)]"

	desc += "\n\nBase research value: [base_value] points"

/obj/item/rce_bodypart/examine(mob/user)
	. = ..()
	if(length(traits))
		. += span_notice("This sample contains [length(traits)] trait\s:")
		for(var/trait in traits)
			. += span_notice("• <b>[trait]</b>: [get_trait_description(trait)]")
		. += span_notice("Base value: <b>[base_value]</b> research points")

// Calculate the value of this part for a specific research project
/obj/item/rce_bodypart/proc/calculate_value(list/favored_traits, list/negative_traits, list/required_traits)
	var/value = base_value
	var/modifier = 0

	// Check if we meet requirements
	if(length(required_traits))
		var/meets_requirement = FALSE
		for(var/req_trait in required_traits)
			if(req_trait in traits)
				meets_requirement = TRUE
				break
		if(!meets_requirement)
			return 0 // Can't use this part for this research

	// Apply trait modifiers
	for(var/trait in traits)
		if(trait in favored_traits)
			modifier += favored_traits[trait]
		if(trait in negative_traits)
			modifier += negative_traits[trait]

	// Apply modifier
	value = round(value * (1 + modifier))
	return max(1, value) // Minimum 1 point

// Special body part variants for specific enemies
/obj/item/rce_bodypart/xcorp
	name = "X-Corp biological sample"
	desc = "A sample of the grotesque flesh that comprises X-Corp entities."
	base_value = 15

/obj/item/rce_bodypart/clan
	name = "Resurgence Clan component"
	desc = "A mechanical component from a Resurgence Clan unit."
	icon_state = "heart-c-u2-on"
	base_value = 12

/obj/item/rce_bodypart/greed
	name = "greed-touched sample"
	desc = "A horrifying fusion of mechanical and organic matter, corrupted by greed."
	icon_state = "heart-c-u2-on"
	base_value = 20

// Container for storing body parts in research machine
// Automatically picks up bodyparts as the user moves (like mining satchel)
/obj/item/storage/box/rce_bodyparts
	name = "biological sample container"
	desc = "A specialized container for storing biological samples. Automatically collects samples as you walk over them."
	icon_state = "brassbox"
	illustration = null
	/// If TRUE, the holder won't receive any messages when they fail to pick up samples
	var/spam_protection = FALSE
	/// The mob we're listening to for movement
	var/mob/listeningTo

/obj/item/storage/box/rce_bodyparts/ComponentInitialize()
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_items = 20
	STR.can_hold = typecacheof(list(/obj/item/rce_bodypart))
	STR.max_combined_w_class = 40

/obj/item/storage/box/rce_bodyparts/equipped(mob/user)
	. = ..()
	if(listeningTo == user)
		return
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(pickup_bodyparts))
	listeningTo = user

/obj/item/storage/box/rce_bodyparts/dropped()
	. = ..()
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
		listeningTo = null

/obj/item/storage/box/rce_bodyparts/proc/pickup_bodyparts(mob/living/user)
	var/show_message = FALSE
	var/turf/tile = user.loc
	if(!isturf(tile))
		return
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	if(STR)
		for(var/obj/item/rce_bodypart/part in tile)
			if(SEND_SIGNAL(src, COMSIG_TRY_STORAGE_INSERT, part, user, TRUE))
				show_message = TRUE
			else
				if(!spam_protection)
					to_chat(user, span_warning("Your [name] is full and can't hold any more samples!"))
					spam_protection = TRUE
					continue
	if(show_message)
		playsound(user, "rustle", 50, TRUE)
		user.visible_message(span_notice("[user] scoops up the samples beneath [user.p_them()]."), \
			span_notice("You scoop up the samples beneath you with your [name]."))
	spam_protection = FALSE

// =====================
// PAPER GUIDES
// =====================

/obj/item/paper/fluff/rce_research_guide
	name = "R-Corp Research System Guide"
	info = {"<center><h2>R-CORP BIOLOGICAL RESEARCH SYSTEM</h2></center>
		<center><i>Field Manual for Research Personnel</i></center><br>
		<br>
		<h3>OVERVIEW</h3>
		The R-Corp Biological Research Station allows you to analyze biological samples harvested from hostile entities to unlock advanced specialist equipment. Each sample processed contributes research points toward unlocking new weapons and gear.<br>
		<br>
		<h3>PART 1: GATHERING SAMPLES</h3>
		<br>
		<b>Equipment Needed:</b><br>
		* <b>R-Corp Biological Harvester:</b> A gun that marks living enemies for sample extraction.<br>
		* <b>Biological Sample Container:</b> A storage box that automatically picks up samples as you walk over them.<br>
		<br>
		<b>How to Harvest:</b><br>
		1. Shoot a living hostile entity with the Biological Harvester to MARK them<br>
		2. The mark lasts for 60 seconds (look for the visual indicator)<br>
		3. Kill the marked enemy before the mark expires<br>
		4. Body parts will automatically drop from the marked corpse<br>
		5. Samples are automatically collected if you have a sample container equipped<br>
		<br>
		<b>Important:</b> You must mark enemies BEFORE killing them! Unmarked corpses yield nothing.<br>
		<br>
		<b>Sample Types:</b><br>
		Different enemies yield different body parts with unique traits:<br>
		* <b>Clan Soldiers:</b> Mechanical parts, neural tissue<br>
		* <b>X-Corp Troops:</b> Adaptive tissue, precision organs<br>
		* <b>Stronger enemies:</b> Higher value samples with better traits<br>
		<br>
		<h3>PART 2: USING THE RESEARCH STATION</h3>
		<br>
		<b>Inserting Samples:</b><br>
		1. Approach the Biological Research Station<br>
		2. Click on it with a body part or sample container in hand<br>
		3. Samples are stored in the machine's internal buffer<br>
		<br>
		<b>Selecting Research:</b><br>
		1. Click on the Research Station to open the interface<br>
		2. Browse the three research branches: Hellfire, Venom, Storm<br>
		3. Click on a research project to select it as your target<br>
		4. Higher tier research requires completing prerequisites first<br>
		<br>
		<b>Processing Samples:</b><br>
		1. With a research project selected, click "Process" or click on individual samples<br>
		2. Each sample generates research points based on its traits<br>
		3. When enough points are accumulated, the research completes<br>
		4. Completed research unlocks new items in the factory production menu<br>
		<br>
		<h3>PART 3: SAMPLE EFFECTIVENESS</h3>
		<br>
		Not all samples are equally valuable for all research! Each research project has:<br>
		<br>
		<b>Favored Traits:</b> Samples with these traits give BONUS points<br>
		* Major bonus: +50% effectiveness<br>
		* Moderate bonus: +25% effectiveness<br>
		* Minor bonus: +10% effectiveness<br>
		<br>
		<b>Negative Traits:</b> Samples with these traits give REDUCED points<br>
		* Major penalty: -50% effectiveness<br>
		* Moderate penalty: -25% effectiveness<br>
		* Minor penalty: -10% effectiveness<br>
		<br>
		<b>Required Traits:</b> Some research REQUIRES specific traits to accept a sample at all!<br>
		<br>
		The research interface shows effectiveness ratings:<br>
		* <font color='green'>Green (100%+):</font> Excellent sample for this research<br>
		* <font color='yellow'>Yellow (50-99%):</font> Acceptable sample<br>
		* <font color='red'>Red (below 50%):</font> Poor sample, consider using elsewhere<br>
		<br>
		<h3>RESEARCH BRANCHES</h3>
		<br>
		<b>HELLFIRE ROOSTER (Fire)</b><br>
		Pyrotechnic assault specialists. Unlocks flamethrowers, napalm launchers, and fire-based weapons.<br>
		<br>
		<b>VENOM RATTLESNAKE (Toxic)</b><br>
		Toxic warfare specialists. Unlocks acid sprayers, poison mines, and corrosive weapons.<br>
		<br>
		<b>STORM RAM (Electric)</b><br>
		Electromagnetic assault specialists. Unlocks thunder gauntlets, EMP grenades, and shock weapons.<br>
		<br>
		<center><i>Good hunting, and remember: every corpse is a resource!</i></center>"}

/obj/item/paper/fluff/rce_fuel_guide
	name = "R-Corp Fuel System Guide"
	info = {"<center><h2>R-CORP SPECIALIST FUEL SYSTEM</h2></center>
		<center><i>Field Manual for Specialist Operations</i></center><br>
		<br>
		<h3>OVERVIEW</h3>
		R-Corp specialist classes rely on specialized resource tanks to power their weapons. This guide covers fuel storage, distribution, and field resupply procedures.<br>
		<br>
		<h3>PART 1: RESOURCE TANKS</h3>
		<br>
		Each specialist class uses a different type of resource tank worn on the back:<br>
		<br>
		<b>Heavy Fuel Tank (Hellfire Rooster)</b><br>
		* Capacity: 1000 units<br>
		* Powers: Heavy Flamethrower, Napalm Launcher, Inferno Rush Blade, Thermite Sprayer, etc.<br>
		* Can refill from standard fuel tanks<br>
		<br>
		<b>Acid Tank (Venom Rattlesnake)</b><br>
		* Capacity: 500 units<br>
		* Powers: Acid Sprayer, Toxic weapons<br>
		* Refilled at Central Fuel Storage<br>
		<br>
		<b>Capacitor Pack (Storm Ram)</b><br>
		* Capacity: 1000 charge<br>
		* Powers: Thunder Gauntlets, Lightning Ram, EMP systems<br>
		* Refilled at Central Fuel Storage<br>
		<br>
		<h3>PART 2: CONNECTING WEAPONS</h3>
		<br>
		Most specialist weapons require a connection to your resource tank:<br>
		<br>
		1. Equip your resource tank on your back slot<br>
		2. Pick up a compatible weapon<br>
		3. The weapon will automatically attempt to connect<br>
		4. Use the weapon in-hand to manually connect/disconnect<br>
		5. Check the weapon's examine text to see fuel status<br>
		<br>
		<b>Important:</b> Only ONE weapon can be connected to a tank at a time!<br>
		<br>
		<h3>PART 3: CENTRAL FUEL STORAGE</h3>
		<br>
		The Central Fuel Storage unit converts factory materials into specialist fuel.<br>
		<br>
		<b>How to Use:</b><br>
		1. Insert factory materials (cubes) into the storage unit<br>
		2. Materials are converted to fuel automatically<br>
		3. Click on the storage with your resource tank to refill<br>
		<br>
		<b>Material Efficiency:</b><br>
		Different materials provide different fuel amounts:<br>
		* <font color='green'>Green / Red:</font> 1x efficiency (standard)<br>
		* <font color='blue'>Blue</font> / <font color='purple'>Purple:</font> 2x efficiency<br>
		* <font color='orange'>Orange</font> / <font color='gray'>Silver:</font> 4x efficiency<br>
		<br>
		<b>Tip:</b> Save your rare materials for fuel - they're worth more here than in production!<br>
		<br>
		<h3>PART 4: FIELD RESUPPLY (Ravens)</h3>
		<br>
		Ravens can carry portable refueling equipment to resupply specialists in the field.<br>
		<br>
		<b>Power Cell (Storm Ram Support)</b><br>
		* Fill at Central Fuel Storage<br>
		* Use on a Storm Ram to recharge their capacitor pack<br>
		* 10-second channel time<br>
		<br>
		<b>Acid Canister (Venom Rattlesnake Support)</b><br>
		* Fill at Central Fuel Storage<br>
		* Use on a Venom Rattlesnake to refill their acid tank<br>
		* 10-second channel time<br>
		<br>
		<b>IMPORTANT:</b> Hellfire Roosters do NOT have field resupply options!<br>
		They must return to Central Fuel Storage to refuel.<br>
		<br>
		<h3>FUEL CONSERVATION TIPS</h3>
		<br>
		* Save high-consumption weapons for tough enemies<br>
		* Coordinate with Ravens for extended operations<br>
		* Keep an eye on your fuel gauge - running dry in combat is fatal!<br>
		* Automatic Defense Flamethrower consumes fuel passively when active<br>
		<br>
		<center><i>Fuel is life. Manage it wisely.</i></center>"}

/obj/item/paper/fluff/rce_specialist_guide
	name = "R-Corp Specialist Class Guide"
	info = {"<center><h2>R-CORP SPECIALIST CLASS SYSTEM</h2></center>
		<center><i>Implant Installation and Class Overview</i></center><br>
		<br>
		<h3>OVERVIEW</h3>
		R-Corp specialist classes are elite combat roles unlocked through biological research. Each class provides unique abilities, immunities, and access to powerful weapons.<br>
		<br>
		<h3>BECOMING A SPECIALIST</h3>
		<br>
		<b>Requirements:</b><br>
		* Must be an R-Corp Rook or Robin<br>
		* Research must unlock the specialist implant<br>
		* Factory must produce the implant<br>
		<br>
		<b>Installation:</b><br>
		1. Obtain a specialist combat implant from the factory<br>
		2. Hold the implant in your hand<br>
		3. Use it on yourself (click in-hand or use on your character)<br>
		4. Wait for the 5-second installation process<br>
		5. You are now transformed into a specialist!<br>
		<br>
		<b>WARNING:</b> You can only have ONE specialist implant at a time!<br>
		<br>
		<h3>SPECIALIST CLASSES</h3>
		<br>
		<center><b>=== HELLFIRE ROOSTER ===</b></center><br>
		<i>Pyrotechnic Assault Specialist</i><br>
		<br>
		<b>Immunities:</b> Fire, Heat<br>
		<b>Stat Changes:</b> +20 Fortitude, -20 Prudence, +40 Justice<br>
		<br>
		<b>Equipment:</b><br>
		* Heavy Flamethrower - High damage flame stream<br>
		* Napalm Launcher - Long range fire bombardment<br>
		* Inferno Rush Blade - Fire dash melee weapon<br>
		* Thermite Sprayer - Delayed explosion area denial<br>
		* Inferno Wall Projector - Creates blocking fire walls<br>
		* Pyroclastic Burst Gauntlets - AoE fire melee<br>
		* Automatic Defense Flamethrower - Passive auto-targeting<br>
		<br>
		<b>Playstyle:</b> Aggressive front-line assault. Burn everything.<br>
		<b>Weakness:</b> No field resupply - must return to base for fuel.<br>
		<br>
		<center><b>=== VENOM RATTLESNAKE ===</b></center><br>
		<i>Toxic Warfare Specialist</i><br>
		<br>
		<b>Immunities:</b> Acid, Poison<br>
		<b>Stat Changes:</b> +60 Prudence, -20 Justice<br>
		<br>
		<b>Equipment:</b><br>
		* Acid Sprayer - Corrosive stream weapon<br>
		* Toxic Mine Layer - Area denial explosives<br>
		* Plague Launcher - Spread poison over areas<br>
		<br>
		<b>Playstyle:</b> Area denial and territorial control. Melt defenses.<br>
		<b>Strength:</b> Ravens can resupply acid in the field.<br>
		<br>
		<center><b>=== STORM RAM ===</b></center><br>
		<i>Electromagnetic Tank Specialist</i><br>
		<br>
		<b>Immunities:</b> Electricity, Knockback<br>
		<b>Stat Changes:</b> +100 Fortitude, -20 Prudence, +40 Justice<br>
		<br>
		<b>Equipment:</b><br>
		* Thunder Gauntlets - Shocking melee strikes<br>
		* Lightning Ram - Charge attack<br>
		* EMP Grenades - Disable electronic enemies<br>
		<br>
		<b>Playstyle:</b> Heavy tank, absorb damage, disrupt electronics.<br>
		<b>Strength:</b> Ravens can recharge capacitor packs in the field.<br>
		<br>
		<b>NOTE:</b> Storm Ram class is currently undergoing maintenance and may be temporarily unavailable.<br>
		<br>
		<h3>GENERAL TIPS</h3>
		<br>
		* Specialist armor requires the matching implant to equip<br>
		* Coordinate with Ravens for sustained operations<br>
		* Your immunities protect you from friendly fire of your element<br>
		* Removing an implant reverts all changes<br>
		* You cannot use standard firearms as a specialist (TRAIT_NOGUNS)<br>
		<br>
		<center><i>Choose your path. Master your element.</i></center>"}

// Spawn these guides in appropriate locations or crates
/obj/item/storage/box/rce_guides
	name = "R-Corp field manual box"
	desc = "A box containing field manuals for R-Corp specialist operations."

/obj/item/storage/box/rce_guides/PopulateContents()
	new /obj/item/paper/fluff/rce_research_guide(src)
	new /obj/item/paper/fluff/rce_fuel_guide(src)
	new /obj/item/paper/fluff/rce_specialist_guide(src)
