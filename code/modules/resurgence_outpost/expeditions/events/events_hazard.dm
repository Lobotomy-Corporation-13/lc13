// Hazard Travel Events
// Environmental dangers that must be overcome

// ============================================
// QUICKSAND
// ============================================

/datum/travel_event/hazard/quicksand
	name = "Quicksand Pit"
	desc = "The ground ahead is treacherous - patches of quicksand dot the path. You can see several possible routes: a longer path around, a risky dash across stable spots, or testing the ground carefully as you go."
	category = EVENT_CATEGORY_HAZARD
	weight = 20
	valid_terrains = list(TERRAIN_DESERT, TERRAIN_FOREST)
	global_fail_damage = 20
	global_fail_message = "You sink into the quicksand and barely escape with your life!"

/datum/travel_event/hazard/quicksand/setup_choices()
	// Choice 1: Read terrain carefully (Mining)
	var/datum/event_choice/read = new()
	read.name = "Read the Terrain"
	read.desc = "Use your knowledge of geology to identify stable ground and pick a safe path."
	read.skill_type = EVENT_SKILL_MINING
	read.difficulty = 6
	read.pass_credits = 25
	read.pass_message = "You identify the stable ground and navigate safely through!"
	read.fail_damage = 30
	read.fail_damage_type = OXY
	read.fail_message = "You misread the terrain and sink into quicksand! You barely pull yourself free."
	choices += read

	// Choice 2: Quick dash (Crafting - agility)
	var/datum/event_choice/dash = new()
	dash.name = "Sprint Across"
	dash.desc = "Move fast enough that you don't have time to sink. Risky but quick."
	dash.skill_type = EVENT_SKILL_CRAFTING
	dash.difficulty = 7
	dash.pass_credits = 15
	dash.pass_message = "You dash across before the ground can swallow you!"
	dash.fail_damage = 35
	dash.fail_damage_type = OXY
	dash.fail_message = "You trip and plunge into the quicksand! The struggle to escape exhausts you."
	choices += dash

	// Choice 3: Go around (Safe but slow)
	var/datum/event_choice/around = new()
	around.name = "Take the Long Way"
	around.desc = "Circle around the entire area. Safe but time-consuming."
	around.auto_success = TRUE
	around.pass_message = "You take the long way around, arriving safely but tired."
	choices += around

// ============================================
// TOXIC SPORES
// ============================================

/datum/travel_event/hazard/toxic_spores
	name = "Toxic Spore Cloud"
	desc = "A thick cloud of fungal spores blocks the path. The air is deadly - but you might be able to neutralize them, hold your breath and rush through, or find an alternate route."
	category = EVENT_CATEGORY_HAZARD
	weight = 20
	valid_terrains = list(TERRAIN_FOREST, TERRAIN_RUINS)
	global_fail_damage = 15
	global_fail_message = "The spores overwhelm you before you can escape!"

/datum/travel_event/hazard/toxic_spores/setup_choices()
	// Choice 1: Neutralize with fire (Cooking - chemistry knowledge)
	var/datum/event_choice/burn = new()
	burn.name = "Burn the Spores"
	burn.desc = "Create a controlled fire to burn away the spores. Requires knowledge of combustion."
	burn.skill_type = EVENT_SKILL_COOKING
	burn.difficulty = 7
	burn.pass_credits = 30
	burn.pass_message = "The fire consumes the spores, clearing a safe path!"
	burn.fail_damage = 20
	burn.fail_damage_type = FIRE
	burn.fail_message = "The fire spreads uncontrollably! You get singed escaping."
	choices += burn

	// Choice 2: Hold breath and run (Mining - endurance)
	var/datum/event_choice/hold = new()
	hold.name = "Hold Breath and Run"
	hold.desc = "Take a deep breath and sprint through the cloud as fast as possible."
	hold.skill_type = EVENT_SKILL_MINING
	hold.difficulty = 6
	hold.pass_credits = 15
	hold.pass_message = "You hold your breath and dash through the cloud safely!"
	hold.fail_damage = 25
	hold.fail_damage_type = TOX
	hold.fail_message = "You couldn't hold your breath long enough! Toxins flood your lungs."
	choices += hold

	// Choice 3: Find another path (Crafting - problem solving)
	var/datum/event_choice/alternate = new()
	alternate.name = "Find Alternate Route"
	alternate.desc = "Look for a way around or above the spore cloud."
	alternate.skill_type = EVENT_SKILL_CRAFTING
	alternate.difficulty = 5
	alternate.pass_credits = 10
	alternate.pass_message = "You find a path that avoids the worst of the spores."
	alternate.fail_damage = 10
	alternate.fail_damage_type = TOX
	alternate.fail_message = "The alternate route still has some spores. You inhale a small amount."
	choices += alternate

// ============================================
// ROCKSLIDE
// ============================================

/datum/travel_event/hazard/rockslide
	name = "Unstable Cliff"
	desc = "The cliff face above looks ready to collapse. You need to pass beneath it - you could try to predict safe moments, reinforce a section, or just make a run for it."
	category = EVENT_CATEGORY_HAZARD
	weight = 20
	valid_terrains = list(TERRAIN_MOUNTAIN, TERRAIN_RUINS)
	global_fail_damage = 25
	global_fail_message = "Rocks crash down around you! You barely survive."

/datum/travel_event/hazard/rockslide/setup_choices()
	// Choice 1: Predict safe passage (Crafting - structural knowledge)
	var/datum/event_choice/predict = new()
	predict.name = "Analyze Structure"
	predict.desc = "Study the cliff to predict when it's safe to cross."
	predict.skill_type = EVENT_SKILL_CRAFTING
	predict.difficulty = 7
	predict.pass_credits = 35
	predict.pass_message = "You time your crossing perfectly between rock falls!"
	predict.fail_damage = 35
	predict.fail_damage_type = BRUTE
	predict.fail_message = "Your timing was wrong! Rocks crash down on you."
	choices += predict

	// Choice 2: Reinforce passage (Mining)
	var/datum/event_choice/reinforce = new()
	reinforce.name = "Shore Up the Cliff"
	reinforce.desc = "Use available materials to temporarily stabilize the worst sections."
	reinforce.skill_type = EVENT_SKILL_MINING
	reinforce.difficulty = 8
	reinforce.pass_credits = 40
	reinforce.pass_message = "Your reinforcements hold long enough for safe passage!"
	reinforce.fail_damage = 30
	reinforce.fail_damage_type = BRUTE
	reinforce.fail_message = "The reinforcements collapse while you're underneath!"
	choices += reinforce

	// Choice 3: Sprint through (Risky)
	var/datum/event_choice/sprint = new()
	sprint.name = "Run For It"
	sprint.desc = "Just run as fast as you can and hope for the best."
	sprint.skill_type = EVENT_SKILL_MINING
	sprint.difficulty = 5
	sprint.pass_credits = 15
	sprint.pass_message = "You sprint through just as rocks crash behind you!"
	sprint.fail_damage = 40
	sprint.fail_damage_type = BRUTE
	sprint.fail_message = "A boulder catches you mid-sprint! The impact is devastating."
	choices += sprint

// ============================================
// SANDSTORM
// ============================================

/datum/travel_event/hazard/sandstorm
	name = "Approaching Sandstorm"
	desc = "A massive wall of swirling sand approaches. You need shelter quickly - you could dig a trench, find natural cover, or try to outrun it."
	category = EVENT_CATEGORY_HAZARD
	weight = 15
	valid_terrains = list(TERRAIN_DESERT)
	global_fail_damage = 20
	global_fail_message = "The sandstorm catches you exposed!"

/datum/travel_event/hazard/sandstorm/setup_choices()
	// Choice 1: Dig in (Mining)
	var/datum/event_choice/dig = new()
	dig.name = "Dig a Shelter"
	dig.desc = "Quickly dig a trench and cover yourself until the storm passes."
	dig.skill_type = EVENT_SKILL_MINING
	dig.difficulty = 6
	dig.pass_credits = 30
	dig.pass_message = "You dig in just in time! The storm passes overhead harmlessly."
	dig.fail_damage = 25
	dig.fail_damage_type = BRUTE
	dig.fail_message = "You couldn't dig fast enough! Sand tears at your exposed skin."
	choices += dig

	// Choice 2: Find natural shelter (Cooking - survival knowledge)
	var/datum/event_choice/shelter = new()
	shelter.name = "Find Natural Cover"
	shelter.desc = "Look for rock formations or debris that could provide shelter."
	shelter.skill_type = EVENT_SKILL_COOKING
	shelter.difficulty = 5
	shelter.pass_credits = 25
	shelter.pass_message = "You find a rocky overhang that shields you from the worst!"
	shelter.fail_damage = 15
	shelter.fail_damage_type = BRUTE
	shelter.fail_message = "The cover you found isn't enough. Sand gets everywhere."
	choices += shelter

	// Choice 3: Outrun it (Very risky)
	var/datum/event_choice/run = new()
	run.name = "Try to Outrun It"
	run.desc = "Sprint perpendicular to the storm's path. Exhausting and risky."
	run.skill_type = EVENT_SKILL_CRAFTING
	run.difficulty = 8
	run.pass_credits = 10
	run.pass_message = "You barely outpace the storm's edge!"
	run.fail_damage = 30
	run.fail_damage_type = BRUTE
	run.fail_message = "The storm is faster than you! It engulfs you completely."
	choices += run

// ============================================
// FLASH FLOOD
// ============================================

/datum/travel_event/hazard/flash_flood
	name = "Flash Flood Warning"
	desc = "You hear rushing water - a flash flood is coming! You need to get to high ground immediately, find something to hold onto, or try to swim with the current."
	category = EVENT_CATEGORY_HAZARD
	weight = 15
	valid_terrains = list(TERRAIN_PLAINS, TERRAIN_FOREST)
	global_fail_damage = 30
	global_fail_message = "The flood sweeps you away!"

/datum/travel_event/hazard/flash_flood/setup_choices()
	// Choice 1: Climb to high ground (Mining - terrain knowledge)
	var/datum/event_choice/climb = new()
	climb.name = "Scramble to High Ground"
	climb.desc = "Identify and climb to the nearest elevated position."
	climb.skill_type = EVENT_SKILL_MINING
	climb.difficulty = 7
	climb.pass_credits = 35
	climb.pass_message = "You reach high ground just as the waters rush past below!"
	climb.fail_damage = 40
	climb.fail_damage_type = BRUTE
	climb.fail_message = "You slip while climbing and the flood catches you!"
	choices += climb

	// Choice 2: Anchor yourself (Crafting)
	var/datum/event_choice/anchor = new()
	anchor.name = "Find an Anchor Point"
	anchor.desc = "Find something sturdy to hold onto and ride out the flood."
	anchor.skill_type = EVENT_SKILL_CRAFTING
	anchor.difficulty = 6
	anchor.pass_credits = 25
	anchor.pass_message = "You cling to a sturdy tree as the waters rush past!"
	anchor.fail_damage = 35
	anchor.fail_damage_type = BRUTE
	anchor.fail_message = "Your anchor point breaks! The current sweeps you downstream."
	choices += anchor

	// Choice 3: Swim with it (Very risky)
	var/datum/event_choice/swim = new()
	swim.name = "Ride the Current"
	swim.desc = "Try to swim with the flood and guide yourself to safety."
	swim.skill_type = EVENT_SKILL_COOKING
	swim.difficulty = 8
	swim.pass_credits = 15
	swim.pass_message = "You manage to ride the current to calmer waters!"
	swim.fail_damage = 45
	swim.fail_damage_type = BRUTE
	swim.fail_message = "The current is too strong! You're battered against rocks."
	choices += swim

// ============================================
// POISON IVY FIELD
// ============================================

/datum/travel_event/hazard/poison_ivy
	name = "Poison Ivy Thicket"
	desc = "Dense poison ivy covers the path ahead. You could try to identify a safe route through, carefully clear a path, or just push through and hope for the best."
	category = EVENT_CATEGORY_HAZARD
	weight = 25
	valid_terrains = list(TERRAIN_FOREST, TERRAIN_PLAINS)
	global_fail_damage = 8
	global_fail_message = "You get covered in poison ivy oils!"

/datum/travel_event/hazard/poison_ivy/setup_choices()
	// Choice 1: Identify safe route (Cooking - plant knowledge)
	var/datum/event_choice/identify = new()
	identify.name = "Identify Safe Path"
	identify.desc = "Use botanical knowledge to find gaps in the poison ivy."
	identify.skill_type = EVENT_SKILL_COOKING
	identify.difficulty = 5
	identify.pass_credits = 20
	identify.pass_message = "You carefully navigate through the gaps in the ivy!"
	identify.fail_damage = 10
	identify.fail_damage_type = TOX
	identify.fail_message = "You misidentified a plant! Rash spreads across your skin."
	choices += identify

	// Choice 2: Clear a path (Crafting - tool use)
	var/datum/event_choice/clear = new()
	clear.name = "Clear a Path"
	clear.desc = "Use tools to cut away the ivy without touching it directly."
	clear.skill_type = EVENT_SKILL_CRAFTING
	clear.difficulty = 6
	clear.pass_credits = 15
	clear.pass_message = "You carefully cut a path through the ivy!"
	clear.fail_damage = 12
	clear.fail_damage_type = TOX
	clear.fail_message = "Your tool slips and flings ivy oils onto your arms!"
	choices += clear

	// Choice 3: Push through (Fast but painful)
	var/datum/event_choice/push = new()
	push.name = "Just Push Through"
	push.desc = "Cover up as best you can and force your way through."
	push.auto_success = TRUE
	push.pass_credits = 5
	push.fail_damage = 15
	push.fail_damage_type = TOX
	push.pass_message = "You push through, but the ivy still gets to you somewhat."
	// This choice always "succeeds" but still causes minor damage
	choices += push

// ============================================
// UNSTABLE RUINS
// ============================================

/datum/travel_event/hazard/unstable_ruins
	name = "Collapsing Structure"
	desc = "Ancient ruins block your path, and the structure groans ominously. You could try to shore up the weak points, quickly navigate through, or find a way around."
	category = EVENT_CATEGORY_HAZARD
	weight = 20
	valid_terrains = list(TERRAIN_RUINS)
	global_fail_damage = 20
	global_fail_message = "The structure collapses around you!"

/datum/travel_event/hazard/unstable_ruins/setup_choices()
	// Choice 1: Reinforce key points (Crafting)
	var/datum/event_choice/reinforce = new()
	reinforce.name = "Shore Up Structure"
	reinforce.desc = "Identify and reinforce the critical structural weak points."
	reinforce.skill_type = EVENT_SKILL_CRAFTING
	reinforce.difficulty = 7
	reinforce.pass_credits = 40
	reinforce.pass_message = "Your reinforcements hold! The structure stabilizes long enough."
	reinforce.fail_damage = 30
	reinforce.fail_damage_type = BRUTE
	reinforce.fail_message = "Your repairs fail catastrophically! Rubble rains down."
	choices += reinforce

	// Choice 2: Navigate quickly (Mining)
	var/datum/event_choice/navigate = new()
	navigate.name = "Quick Navigation"
	navigate.desc = "Move fast and light through the structure before it collapses."
	navigate.skill_type = EVENT_SKILL_MINING
	navigate.difficulty = 6
	navigate.pass_credits = 25
	navigate.pass_message = "You slip through just as the structure groans behind you!"
	navigate.fail_damage = 25
	navigate.fail_damage_type = BRUTE
	navigate.fail_message = "You're too slow! A beam catches you across the back."
	choices += navigate

	// Choice 3: Go around (Safe)
	var/datum/event_choice/around = new()
	around.name = "Find a Way Around"
	around.desc = "Take time to find a path that avoids the unstable structure entirely."
	around.skill_type = EVENT_SKILL_COOKING
	around.difficulty = 4
	around.pass_credits = 10
	around.pass_message = "You find a safe path around the ruins."
	around.fail_damage = 5
	around.fail_damage_type = BRUTE
	around.fail_message = "The detour has its own hazards. You trip on some debris."
	choices += around

// ============================================
// EXTREME HEAT
// ============================================

/datum/travel_event/hazard/extreme_heat
	name = "Heat Wave"
	desc = "The temperature is dangerously high. You need to manage your hydration, find shade, or push through quickly before heat exhaustion sets in."
	category = EVENT_CATEGORY_HAZARD
	weight = 20
	valid_terrains = list(TERRAIN_DESERT)
	global_fail_damage = 15
	global_fail_message = "The heat overwhelms you!"

/datum/travel_event/hazard/extreme_heat/setup_choices()
	// Choice 1: Manage hydration (Cooking)
	var/datum/event_choice/hydrate = new()
	hydrate.name = "Pace and Hydrate"
	hydrate.desc = "Use survival knowledge to pace yourself and manage water intake."
	hydrate.skill_type = EVENT_SKILL_COOKING
	hydrate.difficulty = 5
	hydrate.pass_credits = 25
	hydrate.pass_message = "You pace yourself perfectly and weather the heat!"
	hydrate.fail_damage = 15
	hydrate.fail_damage_type = FIRE
	hydrate.fail_message = "You misjudge your water needs and suffer mild heat stroke."
	choices += hydrate

	// Choice 2: Find shade (Mining - terrain)
	var/datum/event_choice/shade = new()
	shade.name = "Seek Shade"
	shade.desc = "Find sheltered spots to rest in between bursts of movement."
	shade.skill_type = EVENT_SKILL_MINING
	shade.difficulty = 5
	shade.pass_credits = 20
	shade.pass_message = "You find enough shade to make the crossing bearable!"
	shade.fail_damage = 12
	shade.fail_damage_type = FIRE
	shade.fail_message = "The shade you found wasn't enough. You're sunburned and exhausted."
	choices += shade

	// Choice 3: Rush through (Fast but risky)
	var/datum/event_choice/rush = new()
	rush.name = "Sprint Through"
	rush.desc = "Move as fast as possible to minimize exposure time."
	rush.skill_type = EVENT_SKILL_CRAFTING
	rush.difficulty = 7
	rush.pass_credits = 15
	rush.pass_message = "You push through quickly before the heat can affect you!"
	rush.fail_damage = 25
	rush.fail_damage_type = FIRE
	rush.fail_message = "The exertion in this heat is too much! You collapse briefly from heat exhaustion."
	choices += rush
