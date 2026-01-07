// Scavenge Travel Events
// Events focused on finding supplies and resources

// ============================================
// ABANDONED CACHE
// ============================================

/datum/travel_event/scavenge/abandoned_cache
	name = "Abandoned Cache"
	desc = "You discover a half-buried container among the debris. It appears to be locked with a rusted mechanism, and you can see faint wires that might be a trap. How do you approach this?"
	category = EVENT_CATEGORY_SCAVENGE
	weight = 40
	valid_terrains = list(TERRAIN_PLAINS, TERRAIN_DESERT, TERRAIN_RUINS, TERRAIN_MOUNTAIN)
	global_fail_damage = 10
	global_fail_message = "The cache remains sealed, and you give up trying."

/datum/travel_event/scavenge/abandoned_cache/setup_choices()
	// Choice 1: Carefully disarm the trap (Mining)
	var/datum/event_choice/disarm = new()
	disarm.name = "Disarm the Trap"
	disarm.desc = "Use your knowledge of mechanisms to carefully disarm any traps before opening."
	disarm.skill_type = EVENT_SKILL_MINING
	disarm.difficulty = 7
	disarm.pass_credits = 60
	disarm.pass_items = list(/obj/item/stack/sheet/metal)
	disarm.pass_message = "You expertly disarm the trap and open the cache, revealing valuable supplies!"
	disarm.fail_damage = 20
	disarm.fail_damage_type = BRUTE
	disarm.fail_message = "The trap triggers! Sharp debris slices your hands."
	choices += disarm

	// Choice 2: Force it open (Crafting)
	var/datum/event_choice/force = new()
	force.name = "Force it Open"
	force.desc = "Use brute strength and improvised tools to pry the container open quickly."
	force.skill_type = EVENT_SKILL_CRAFTING
	force.difficulty = 5
	force.pass_credits = 40
	force.pass_message = "You wrench the container open! Some contents are damaged but you recover supplies."
	force.fail_damage = 15
	force.fail_damage_type = BRUTE
	force.fail_message = "Your tool slips and you cut yourself on the rusted metal."
	choices += force

	// Choice 3: Leave it alone (Safe option)
	var/datum/event_choice/leave = new()
	leave.name = "Leave it Alone"
	leave.desc = "It's not worth the risk. Move on safely."
	leave.auto_success = TRUE
	leave.pass_message = "You decide discretion is the better part of valor and move on."
	choices += leave

// ============================================
// OVERGROWN GARDEN
// ============================================

/datum/travel_event/scavenge/overgrown_garden
	name = "Overgrown Garden"
	desc = "An abandoned garden has gone wild, with plants growing in chaotic tangles. Some vegetation looks edible while others appear toxic. You also notice animal tracks nearby - something has been eating here."
	category = EVENT_CATEGORY_SCAVENGE
	weight = 40
	valid_terrains = list(TERRAIN_PLAINS, TERRAIN_FOREST)
	global_fail_damage = 5
	global_fail_message = "You leave the garden empty-handed."

/datum/travel_event/scavenge/overgrown_garden/setup_choices()
	// Choice 1: Identify edible plants (Cooking)
	var/datum/event_choice/identify = new()
	identify.name = "Identify Safe Plants"
	identify.desc = "Use your knowledge of food and plants to identify which ones are safe to eat."
	identify.skill_type = EVENT_SKILL_COOKING
	identify.difficulty = 5
	identify.pass_credits = 35
	identify.pass_items = list(/obj/item/food/grown/potato, /obj/item/food/grown/carrot)
	identify.pass_message = "You identify several edible plants and harvest a nice haul!"
	identify.fail_damage = 15
	identify.fail_damage_type = TOX
	identify.fail_message = "You accidentally eat something toxic! Your stomach churns painfully."
	choices += identify

	// Choice 2: Follow animal tracks (Mining - tracking)
	var/datum/event_choice/track = new()
	track.name = "Follow Animal Tracks"
	track.desc = "Animals know which plants are safe. Follow their tracks to find what they've been eating."
	track.skill_type = EVENT_SKILL_MINING
	track.difficulty = 6
	track.pass_credits = 25
	track.pass_items = list(/obj/item/food/grown/apple)
	track.pass_message = "The tracks lead you to a cache of safe, delicious produce!"
	track.fail_damage = 10
	track.fail_damage_type = BRUTE
	track.fail_message = "You stumble into thorny undergrowth while following the tracks."
	choices += track

	// Choice 3: Harvest everything quickly (Risky)
	var/datum/event_choice/grab = new()
	grab.name = "Grab Everything"
	grab.desc = "Just grab what looks good and sort it out later. Risky but potentially rewarding."
	grab.skill_type = EVENT_SKILL_COOKING
	grab.difficulty = 8
	grab.pass_credits = 50
	grab.pass_items = list(/obj/item/food/grown/tomato, /obj/item/food/grown/potato, /obj/item/food/grown/carrot)
	grab.pass_message = "Luck is on your side - everything you grabbed is edible!"
	grab.fail_damage = 25
	grab.fail_damage_type = TOX
	grab.fail_message = "Bad choice! Several of those plants were highly toxic."
	choices += grab

// ============================================
// SCRAP PILE
// ============================================

/datum/travel_event/scavenge/scrap_pile
	name = "Scrap Pile"
	desc = "A mound of discarded machinery and metal scraps lies before you. The pile looks unstable, but you can see valuable components glinting within. There might also be useful tools buried in there."
	category = EVENT_CATEGORY_SCAVENGE
	weight = 40
	valid_terrains = list(TERRAIN_RUINS, TERRAIN_DESERT, TERRAIN_PLAINS)
	global_fail_damage = 8
	global_fail_message = "The pile shifts dangerously and you back away."

/datum/travel_event/scavenge/scrap_pile/setup_choices()
	// Choice 1: Careful extraction (Crafting)
	var/datum/event_choice/careful = new()
	careful.name = "Careful Extraction"
	careful.desc = "Methodically remove pieces to safely access the valuable components."
	careful.skill_type = EVENT_SKILL_CRAFTING
	careful.difficulty = 6
	careful.pass_credits = 50
	careful.pass_items = list(/obj/item/stack/sheet/plasteel)
	careful.pass_message = "You carefully extract high-quality materials from the pile!"
	careful.fail_damage = 15
	careful.fail_damage_type = BRUTE
	careful.fail_message = "A piece of sharp metal slices your hand as you work."
	choices += careful

	// Choice 2: Dig through quickly (Mining)
	var/datum/event_choice/dig = new()
	dig.name = "Dig Through"
	dig.desc = "Use raw strength to quickly dig through the pile and grab what you can."
	dig.skill_type = EVENT_SKILL_MINING
	dig.difficulty = 5
	dig.pass_credits = 35
	dig.pass_items = list(/obj/item/stack/sheet/metal)
	dig.pass_message = "You muscle through the scrap and find some useful materials!"
	dig.fail_damage = 20
	dig.fail_damage_type = BRUTE
	dig.fail_message = "The pile collapses on you! Metal debris rains down."
	choices += dig

	// Choice 3: Look for tools only (Safer)
	var/datum/event_choice/tools = new()
	tools.name = "Search the Edges"
	tools.desc = "Only search the stable outer edges. Less reward but much safer."
	tools.skill_type = EVENT_SKILL_CRAFTING
	tools.difficulty = 3
	tools.pass_credits = 20
	tools.pass_message = "You find some basic materials on the edges of the pile."
	tools.fail_damage = 5
	tools.fail_damage_type = BRUTE
	tools.fail_message = "You scrape your arm on rusty metal, but it's just a scratch."
	choices += tools

// ============================================
// FORGOTTEN SUPPLY DROP
// ============================================

/datum/travel_event/scavenge/supply_drop
	name = "Forgotten Supply Drop"
	desc = "A military supply crate sits half-buried in the ground. The electronic lock is damaged but might still work. You could try to hack it, force it, or see if there's a manual release."
	category = EVENT_CATEGORY_SCAVENGE
	weight = 25
	valid_terrains = list(TERRAIN_PLAINS, TERRAIN_FOREST, TERRAIN_DESERT, TERRAIN_MOUNTAIN, TERRAIN_RUINS)
	global_fail_damage = 0
	global_fail_message = "The crate remains sealed. Whatever's inside will stay a mystery."

/datum/travel_event/scavenge/supply_drop/setup_choices()
	// Choice 1: Hack the lock (Crafting - high reward)
	var/datum/event_choice/hack = new()
	hack.name = "Hack the Electronics"
	hack.desc = "Attempt to bypass the damaged electronic lock using technical knowledge."
	hack.skill_type = EVENT_SKILL_CRAFTING
	hack.difficulty = 8
	hack.pass_credits = 100
	hack.pass_items = list(/obj/item/storage/firstaid/regular)
	hack.pass_message = "The lock clicks open, revealing military-grade supplies!"
	hack.fail_damage = 0
	hack.fail_message = "The lock shorts out completely. No damage, but no entry either."
	choices += hack

	// Choice 2: Find manual release (Mining)
	var/datum/event_choice/manual = new()
	manual.name = "Find Manual Release"
	manual.desc = "Search for a hidden manual release mechanism that bypasses the electronics."
	manual.skill_type = EVENT_SKILL_MINING
	manual.difficulty = 6
	manual.pass_credits = 75
	manual.pass_message = "You find and trigger the manual release! The crate opens."
	manual.fail_damage = 0
	manual.fail_message = "You can't find any manual release mechanism."
	choices += manual

	// Choice 3: Force it (Risky)
	var/datum/event_choice/force = new()
	force.name = "Brute Force"
	force.desc = "Try to physically break open the crate. Might damage the contents."
	force.skill_type = EVENT_SKILL_MINING
	force.difficulty = 4
	force.pass_credits = 40
	force.pass_message = "You smash it open! Some contents are damaged but you salvage what you can."
	force.fail_damage = 15
	force.fail_damage_type = BRUTE
	force.fail_message = "The crate is sturdier than expected. You hurt yourself trying."
	choices += force

// ============================================
// MUSHROOM PATCH
// ============================================

/datum/travel_event/scavenge/mushroom_patch
	name = "Mushroom Patch"
	desc = "A cluster of unusual mushrooms grows in the shade. Some look delicious while others have an ominous glow. You could try to identify them, cook them to neutralize toxins, or just grab the safe-looking ones."
	category = EVENT_CATEGORY_SCAVENGE
	weight = 30
	valid_terrains = list(TERRAIN_FOREST, TERRAIN_RUINS)
	global_fail_damage = 10
	global_fail_message = "You leave the mushrooms alone, unwilling to risk it."

/datum/travel_event/scavenge/mushroom_patch/setup_choices()
	// Choice 1: Identify carefully (Cooking)
	var/datum/event_choice/identify = new()
	identify.name = "Careful Identification"
	identify.desc = "Use your knowledge to identify which mushrooms are safe and valuable."
	identify.skill_type = EVENT_SKILL_COOKING
	identify.difficulty = 6
	identify.pass_credits = 40
	identify.pass_message = "You identify several rare, edible mushrooms worth good money!"
	identify.fail_damage = 25
	identify.fail_damage_type = TOX
	identify.fail_message = "You misidentified a toxic variety! Poison courses through you."
	choices += identify

	// Choice 2: Harvest glowing ones (Risky but unique)
	var/datum/event_choice/glow = new()
	glow.name = "Harvest Glowing Ones"
	glow.desc = "The glowing mushrooms might be valuable reagents... or deadly poison."
	glow.skill_type = EVENT_SKILL_COOKING
	glow.difficulty = 9
	glow.pass_credits = 80
	glow.pass_message = "The glowing mushrooms are rare bioluminescent specimens - very valuable!"
	glow.fail_damage = 35
	glow.fail_damage_type = TOX
	glow.fail_message = "Terrible choice. The glow was a warning - severe toxins flood your system!"
	choices += glow

	// Choice 3: Take only obvious ones (Safe)
	var/datum/event_choice/obvious = new()
	obvious.name = "Take Only Common Ones"
	obvious.desc = "Only harvest mushrooms you definitely recognize as safe."
	obvious.auto_success = TRUE
	obvious.pass_credits = 15
	obvious.pass_message = "You harvest a small amount of clearly safe mushrooms."
	choices += obvious

// ============================================
// MINERAL VEIN
// ============================================

/datum/travel_event/scavenge/mineral_vein
	name = "Exposed Mineral Vein"
	desc = "Erosion has exposed a vein of valuable minerals in the rock face. The area looks unstable - you could carefully extract ore, try to blast loose what you can, or just grab surface samples."
	category = EVENT_CATEGORY_SCAVENGE
	weight = 30
	valid_terrains = list(TERRAIN_MOUNTAIN, TERRAIN_RUINS)
	global_fail_damage = 15
	global_fail_message = "The rock face crumbles before you can extract anything useful."

/datum/travel_event/scavenge/mineral_vein/setup_choices()
	// Choice 1: Careful extraction (Mining)
	var/datum/event_choice/careful = new()
	careful.name = "Careful Extraction"
	careful.desc = "Use proper mining technique to safely extract ore without causing a collapse."
	careful.skill_type = EVENT_SKILL_MINING
	careful.difficulty = 7
	careful.pass_credits = 70
	careful.pass_items = list(/obj/item/stack/ore/silver)
	careful.pass_message = "You expertly extract valuable ore from the vein!"
	careful.fail_damage = 25
	careful.fail_damage_type = BRUTE
	careful.fail_message = "The rock face crumbles! Debris rains down on you."
	choices += careful

	// Choice 2: Quick smash and grab (Crafting)
	var/datum/event_choice/smash = new()
	smash.name = "Smash and Grab"
	smash.desc = "Use improvised tools to quickly break off chunks of ore."
	smash.skill_type = EVENT_SKILL_CRAFTING
	smash.difficulty = 5
	smash.pass_credits = 45
	smash.pass_items = list(/obj/item/stack/ore/iron)
	smash.pass_message = "You break off several chunks of ore before the area becomes too unstable!"
	smash.fail_damage = 20
	smash.fail_damage_type = BRUTE
	smash.fail_message = "Your tool breaks and rock shards fly into your face!"
	choices += smash

	// Choice 3: Surface samples only (Safe)
	var/datum/event_choice/surface = new()
	surface.name = "Collect Surface Samples"
	surface.desc = "Only collect loose ore from the surface. Safe but limited yield."
	surface.skill_type = EVENT_SKILL_MINING
	surface.difficulty = 3
	surface.pass_credits = 25
	surface.pass_message = "You collect some loose ore samples from the surface."
	surface.fail_damage = 5
	surface.fail_damage_type = BRUTE
	surface.fail_message = "A small rock falls and hits your hand. Minor injury."
	choices += surface
