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
	valid_terrains = list(TERRAIN_PLAINS, TERRAIN_DESERT, TERRAIN_RUINS, TERRAIN_MOUNTAIN, TERRAIN_SNOW)
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
	// Choice 1: Identify edible plants (Harvesting)
	var/datum/event_choice/identify = new()
	identify.name = "Identify Safe Plants"
	identify.desc = "Use your knowledge of botany to identify which plants are safe to harvest."
	identify.skill_type = EVENT_SKILL_HARVESTING
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
	valid_terrains = list(TERRAIN_PLAINS, TERRAIN_FOREST, TERRAIN_DESERT, TERRAIN_MOUNTAIN, TERRAIN_RUINS, TERRAIN_SNOW)
	global_fail_damage = 0
	global_fail_message = "The crate remains sealed. Whatever's inside will stay a mystery."

/datum/travel_event/scavenge/supply_drop/setup_choices()
	// Choice 1: Hack the lock (Analysis - high reward)
	var/datum/event_choice/hack = new()
	hack.name = "Hack the Electronics"
	hack.desc = "Analyze the circuitry and bypass the damaged electronic lock."
	hack.skill_type = EVENT_SKILL_ANALYSIS
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
	// Choice 1: Identify carefully (Harvesting)
	var/datum/event_choice/identify = new()
	identify.name = "Careful Identification"
	identify.desc = "Use your botanical knowledge to identify which mushrooms are safe and valuable."
	identify.skill_type = EVENT_SKILL_HARVESTING
	identify.difficulty = 6
	identify.pass_credits = 40
	identify.pass_message = "You identify several rare, edible mushrooms worth good money!"
	identify.fail_damage = 25
	identify.fail_damage_type = TOX
	identify.fail_message = "You misidentified a toxic variety! Poison courses through you."
	choices += identify

	// Choice 2: Harvest glowing ones (Risky but unique - Analysis)
	var/datum/event_choice/glow = new()
	glow.name = "Harvest Glowing Ones"
	glow.desc = "Analyze the bioluminescence patterns to determine if these are valuable specimens or toxic."
	glow.skill_type = EVENT_SKILL_ANALYSIS
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

// ============================================
// FROZEN CACHE (Snow)
// ============================================

/datum/travel_event/scavenge/frozen_cache
	name = "Frozen Supply Cache"
	desc = "You discover supplies frozen into a block of ice. You can see useful items inside, but extracting them will take effort."
	category = EVENT_CATEGORY_SCAVENGE
	weight = 35
	valid_terrains = list(TERRAIN_SNOW)
	global_fail_damage = 8
	global_fail_message = "The cache remains frozen solid. You give up."

/datum/travel_event/scavenge/frozen_cache/setup_choices()
	// Choice 1: Controlled melting (Cooking)
	var/datum/event_choice/melt = new()
	melt.name = "Careful Melting"
	melt.desc = "Use controlled heat to melt the ice without damaging the contents."
	melt.skill_type = EVENT_SKILL_COOKING
	melt.difficulty = 6
	melt.pass_credits = 55
	melt.pass_items = list(/obj/item/storage/firstaid/regular)
	melt.pass_message = "You carefully extract perfectly preserved supplies!"
	melt.fail_damage = 10
	melt.fail_damage_type = FIRE
	melt.fail_message = "Too much heat! Some contents are damaged and you burn yourself."
	choices += melt

	// Choice 2: Chip away (Mining)
	var/datum/event_choice/chip = new()
	chip.name = "Chip Away Ice"
	chip.desc = "Use tools to carefully chip away the ice surrounding the supplies."
	chip.skill_type = EVENT_SKILL_MINING
	chip.difficulty = 5
	chip.pass_credits = 45
	chip.pass_items = list(/obj/item/stack/sheet/metal)
	chip.pass_message = "You chip away the ice and recover useful supplies!"
	chip.fail_damage = 15
	chip.fail_damage_type = BRUTE
	chip.fail_message = "Your tool slips on the ice and cuts your hand!"
	choices += chip

	// Choice 3: Break it all (Quick but risky)
	var/datum/event_choice/smash = new()
	smash.name = "Smash the Ice Block"
	smash.desc = "Just break the whole ice block. Quick but might damage contents."
	smash.skill_type = EVENT_SKILL_CRAFTING
	smash.difficulty = 4
	smash.pass_credits = 30
	smash.pass_message = "The ice shatters and you grab what survived intact!"
	smash.fail_damage = 5
	smash.fail_damage_type = BRUTE
	smash.fail_message = "Ice shards fly everywhere - minor cuts, and the contents are damaged."
	choices += smash

// ============================================
// ICE FISHING HOLE (Snow)
// ============================================

/datum/travel_event/scavenge/ice_fishing
	name = "Frozen Fishing Hole"
	desc = "You find an old ice fishing hole, now frozen over but with equipment still nearby. There might be supplies in a submerged container."
	category = EVENT_CATEGORY_SCAVENGE
	weight = 30
	valid_terrains = list(TERRAIN_SNOW)
	global_fail_damage = 5
	global_fail_message = "The hole yields nothing useful."

/datum/travel_event/scavenge/ice_fishing/setup_choices()
	// Choice 1: Retrieve submerged container (Mining)
	var/datum/event_choice/retrieve = new()
	retrieve.name = "Retrieve Sunken Supplies"
	retrieve.desc = "You can see something beneath the ice. Try to break through and retrieve it."
	retrieve.skill_type = EVENT_SKILL_MINING
	retrieve.difficulty = 7
	retrieve.pass_credits = 60
	retrieve.pass_items = list(/obj/item/stack/ore/iron)
	retrieve.pass_message = "You retrieve a waterproof container with valuable supplies!"
	retrieve.fail_damage = 25
	retrieve.fail_damage_type = FIRE
	retrieve.fail_message = "You fall through the ice! The freezing water saps your strength."
	choices += retrieve

	// Choice 2: Try fishing (Cooking)
	var/datum/event_choice/fish = new()
	fish.name = "Try Ice Fishing"
	fish.desc = "Use the old equipment to try your hand at ice fishing."
	fish.skill_type = EVENT_SKILL_COOKING
	fish.difficulty = 5
	fish.pass_credits = 35
	fish.pass_items = list(/obj/item/food/meat/slab)
	fish.pass_message = "After some patience, you catch a nice fish!"
	fish.fail_damage = 0
	fish.fail_message = "The fish aren't biting today. You waste time but stay safe."
	choices += fish

	// Choice 3: Salvage equipment (Safe)
	var/datum/event_choice/salvage = new()
	salvage.name = "Salvage Equipment"
	salvage.desc = "Just take the abandoned fishing equipment. Not risky at all."
	salvage.auto_success = TRUE
	salvage.pass_credits = 20
	salvage.pass_message = "You collect the abandoned fishing gear - it might be useful later."
	choices += salvage

// ============================================
// FROZEN TRAVELER (Snow)
// ============================================

/datum/travel_event/scavenge/frozen_remains
	name = "Frozen Traveler"
	desc = "You discover the frozen remains of an unfortunate traveler, preserved by the cold. Their pack and equipment are still intact."
	category = EVENT_CATEGORY_SCAVENGE
	weight = 25
	valid_terrains = list(TERRAIN_SNOW)
	global_fail_damage = 0
	global_fail_message = "You decide to leave the remains undisturbed."

/datum/travel_event/scavenge/frozen_remains/setup_choices()
	// Choice 1: Thorough search (Analysis - investigative)
	var/datum/event_choice/search = new()
	search.name = "Thorough Investigation"
	search.desc = "Methodically analyze the scene and search all pockets and containers."
	search.skill_type = EVENT_SKILL_ANALYSIS
	search.difficulty = 5
	search.pass_credits = 70
	search.pass_items = list(/obj/item/stack/spacecash/c100)
	search.pass_message = "You find money, supplies, and a journal that might be valuable."
	search.fail_damage = 5
	search.fail_damage_type = FIRE
	search.fail_message = "The search takes too long in the cold. Minor frostbite sets in."
	choices += search

	// Choice 2: Quick grab (Crafting)
	var/datum/event_choice/grab = new()
	grab.name = "Quick Grab"
	grab.desc = "Just grab the obviously visible supplies and equipment."
	grab.skill_type = EVENT_SKILL_CRAFTING
	grab.difficulty = 3
	grab.pass_credits = 40
	grab.pass_message = "You grab the visible supplies quickly and move on."
	grab.fail_damage = 0
	grab.fail_message = "The obvious items turn out to be worthless. You find nothing useful."
	choices += grab

	// Choice 3: Pay respects (No reward but safe)
	var/datum/event_choice/respect = new()
	respect.name = "Pay Respects and Leave"
	respect.desc = "This could be you someday. Mark the location and move on respectfully."
	respect.auto_success = TRUE
	respect.pass_credits = 5
	respect.pass_message = "You mark the location for recovery later and continue on your way."
	choices += respect

// ============================================
// SNOW-BURIED STRUCTURE (Snow)
// ============================================

/datum/travel_event/scavenge/snow_ruins
	name = "Snow-Buried Structure"
	desc = "A building or shelter lies mostly buried under snow. The entrance is partially blocked, but you can see intact containers inside."
	category = EVENT_CATEGORY_SCAVENGE
	weight = 30
	valid_terrains = list(TERRAIN_SNOW)
	global_fail_damage = 10
	global_fail_message = "The structure is too unstable to explore safely."

/datum/travel_event/scavenge/snow_ruins/setup_choices()
	// Choice 1: Excavate entrance (Mining)
	var/datum/event_choice/dig = new()
	dig.name = "Dig Out Entrance"
	dig.desc = "Clear the snow blocking the main entrance for full access."
	dig.skill_type = EVENT_SKILL_MINING
	dig.difficulty = 6
	dig.pass_credits = 65
	dig.pass_items = list(/obj/item/stack/sheet/plasteel)
	dig.pass_message = "You clear the entrance and find a treasure trove of preserved supplies!"
	dig.fail_damage = 20
	dig.fail_damage_type = BRUTE
	dig.fail_message = "The snow shifts and partially buries you! You struggle free but are hurt."
	choices += dig

	// Choice 2: Find alternate entry (Crafting)
	var/datum/event_choice/alternate = new()
	alternate.name = "Find Another Way In"
	alternate.desc = "Look for windows, vents, or other ways to access the interior."
	alternate.skill_type = EVENT_SKILL_CRAFTING
	alternate.difficulty = 7
	alternate.pass_credits = 50
	alternate.pass_message = "You find a side entrance and recover good supplies!"
	alternate.fail_damage = 15
	alternate.fail_damage_type = BRUTE
	alternate.fail_message = "The alternate route collapses! Debris strikes you."
	choices += alternate

	// Choice 3: Probe from outside (Safe)
	var/datum/event_choice/probe = new()
	probe.name = "Search From Outside"
	probe.desc = "Use a long pole to probe for and retrieve items near the entrance."
	probe.skill_type = EVENT_SKILL_COOKING
	probe.difficulty = 4
	probe.pass_credits = 25
	probe.pass_message = "You fish out a few useful items from near the entrance."
	probe.fail_damage = 0
	probe.fail_message = "You can't reach anything valuable from the outside."
	choices += probe

// ============================================
// WANDERING SURVIVOR (Social)
// ============================================

/datum/travel_event/scavenge/wandering_survivor
	name = "Wandering Survivor"
	desc = "You encounter a lone survivor traveling through the wasteland. They look wary but not hostile. They might have supplies to trade, information to share, or need help themselves."
	category = EVENT_CATEGORY_SCAVENGE
	weight = 25
	valid_terrains = list(TERRAIN_PLAINS, TERRAIN_FOREST, TERRAIN_DESERT, TERRAIN_RUINS, TERRAIN_SNOW)
	global_fail_damage = 0
	global_fail_message = "The survivor moves on without incident."

/datum/travel_event/scavenge/wandering_survivor/setup_choices()
	// Choice 1: Negotiate trade (Social)
	var/datum/event_choice/trade = new()
	trade.name = "Negotiate Trade"
	trade.desc = "Try to convince them to trade some of their supplies for a fair price."
	trade.skill_type = EVENT_SKILL_SOCIAL
	trade.difficulty = 5
	trade.pass_credits = 50
	trade.pass_items = list(/obj/item/stack/sheet/metal)
	trade.pass_message = "Your friendly demeanor wins them over. They trade you some useful supplies!"
	trade.fail_damage = 0
	trade.fail_message = "They're not interested in trading. Maybe you came on too strong."
	choices += trade

	// Choice 2: Ask for information (Social)
	var/datum/event_choice/info = new()
	info.name = "Ask for Information"
	info.desc = "Chat with them about the area. They might know something useful."
	info.skill_type = EVENT_SKILL_SOCIAL
	info.difficulty = 4
	info.pass_credits = 35
	info.pass_message = "They share valuable information about the region, including locations of hidden caches!"
	info.fail_damage = 0
	info.fail_message = "They're tight-lipped and don't share much of use."
	choices += info

	// Choice 3: Offer help (Safe - builds goodwill)
	var/datum/event_choice/help = new()
	help.name = "Offer Assistance"
	help.desc = "Offer to share some of your supplies or help them on their way."
	help.auto_success = TRUE
	help.pass_credits = 20
	help.pass_message = "They thank you warmly. Your kindness might come back to help you someday."
	choices += help

// ============================================
// HERMIT'S CACHE (Social/Harvesting)
// ============================================

/datum/travel_event/scavenge/hermit_cache
	name = "Hermit's Garden"
	desc = "You stumble upon a small, well-tended garden near a crude shelter. An elderly hermit watches you from the doorway. They seem protective of their plants but might be willing to share."
	category = EVENT_CATEGORY_SCAVENGE
	weight = 20
	valid_terrains = list(TERRAIN_FOREST, TERRAIN_PLAINS)
	global_fail_damage = 0
	global_fail_message = "The hermit waves you away. You leave empty-handed."

/datum/travel_event/scavenge/hermit_cache/setup_choices()
	// Choice 1: Befriend the hermit (Social)
	var/datum/event_choice/befriend = new()
	befriend.name = "Befriend the Hermit"
	befriend.desc = "Take time to talk and show respect. Perhaps they'll share their bounty."
	befriend.skill_type = EVENT_SKILL_SOCIAL
	befriend.difficulty = 6
	befriend.pass_credits = 45
	befriend.pass_items = list(/obj/item/food/grown/potato, /obj/item/food/grown/carrot, /obj/item/food/grown/tomato)
	befriend.pass_message = "The hermit warms to you and shares generously from their garden!"
	befriend.fail_damage = 0
	befriend.fail_message = "The hermit remains suspicious and asks you to leave."
	choices += befriend

	// Choice 2: Offer to help with the garden (Harvesting)
	var/datum/event_choice/garden = new()
	garden.name = "Help With Harvesting"
	garden.desc = "Offer your botanical skills to help with the garden in exchange for some produce."
	garden.skill_type = EVENT_SKILL_HARVESTING
	garden.difficulty = 5
	garden.pass_credits = 35
	garden.pass_items = list(/obj/item/food/grown/apple, /obj/item/food/grown/potato)
	garden.pass_message = "The hermit appreciates your help and gives you a share of the harvest!"
	garden.fail_damage = 0
	garden.fail_message = "Your attempts to help accidentally damage some plants. The hermit asks you to leave."
	choices += garden

	// Choice 3: Just observe and learn (Analysis)
	var/datum/event_choice/observe = new()
	observe.name = "Observe Their Techniques"
	observe.desc = "Watch how they tend their garden and learn from their methods."
	observe.skill_type = EVENT_SKILL_ANALYSIS
	observe.difficulty = 4
	observe.pass_credits = 25
	observe.pass_message = "You pick up some useful gardening techniques by observing."
	observe.fail_damage = 0
	observe.fail_message = "The hermit notices you watching and becomes uncomfortable."
	choices += observe
