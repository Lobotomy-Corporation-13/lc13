/**
 * Resurgence Outpost - Trading Factions
 *
 * Defines all trading factions with their speakers, dialogue, and trading behavior.
 * All factions share a base stock of common materials, then add specialty items.
 */

// ==================== Base Faction Datum ====================

/// Credits needed to gain 1 reputation point (1500 credits = 5 rep means 300 per rep)
#define REP_CREDITS_PER_POINT 300
/// Time in deciseconds before reputation starts decaying (10 minutes = 6000)
#define REP_DECAY_GRACE_PERIOD 6000
/// Time in deciseconds between decay ticks (1 minute = 600)
#define REP_DECAY_INTERVAL 600
/// Amount of reputation lost per decay tick
#define REP_DECAY_AMOUNT 1

/datum/trading_faction
	/// Unique identifier
	var/id = "unknown"
	/// Display name
	var/name = "Unknown Faction"
	/// Description shown in UI
	var/desc = "A mysterious trading group."

	/// Speaker name for dialogue
	var/speaker_name = "Unknown"
	/// Speaker title
	var/speaker_title = "Representative"
	/// Speaker portrait icon state
	var/speaker_portrait = "default"

	/// Whether this faction has been discovered (connected to at least once)
	var/discovered = FALSE

	/// Current reputation (0-100)
	var/reputation = 50
	/// Starting reputation
	var/starting_reputation = 50
	/// Minimum reputation (some factions can't go below this)
	var/min_reputation = 0
	/// Maximum reputation (some factions are capped)
	var/max_reputation = 100

	/// Current cash available to buy from players
	var/current_cash = 2000
	/// Maximum cash cap
	var/max_cash = 5000
	/// Cash regenerated per cycle
	var/cash_regen_rate = 50

	/// Whether this faction can trade
	var/can_trade = TRUE
	/// Whether this faction sends raids
	var/sends_raids = FALSE

	/// World map X coordinate (assigned by world_map_manager during generation)
	var/world_x = 0
	/// World map Y coordinate (assigned by world_map_manager during generation)
	var/world_y = 0

	/// Reputation volatility (multiplier for rep changes)
	var/reputation_volatility = 1

	/// List of stock items available for purchase
	var/list/stock = list()

	/// Dialogue lines by situation
	var/list/speaker_dialogue = list()

	/// Static list of valid seed types for seed-selling factions
	var/static/list/valid_seed_types

	/// Last time a trade was made with this faction (world.time)
	var/last_trade_time = 0
	/// Last time reputation decay was applied
	var/last_decay_time = 0
	/// The reputation level this faction decays toward (usually starting_reputation)
	var/decay_target_reputation = 50
	/// Temporary dialogue override (for showing sale/purchase complete messages)
	var/dialogue_override = null
	/// Time when dialogue override expires
	var/dialogue_override_expiry = 0

/datum/trading_faction/New()
	. = ..()
	reputation = starting_reputation
	decay_target_reputation = starting_reputation
	last_trade_time = world.time
	last_decay_time = world.time
	initialize_dialogue()

/// Initialize dialogue lines - override in subtypes
/datum/trading_faction/proc/initialize_dialogue()
	speaker_dialogue = list(
		"greeting" = "Hello.",
		"idle" = "...",
		"good_rep" = "Welcome back.",
		"sale_complete" = "Transaction complete.",
		"purchase_complete" = "Here are your goods.",
		"low_stock" = "We're running low.",
		"low_rep" = "What do you want?"
	)

/// Get dialogue for a situation
/datum/trading_faction/proc/get_dialogue(situation)
	// Check reputation-based dialogue
	if(reputation >= 60 && (situation == "greeting" || situation == "idle"))
		if("good_rep" in speaker_dialogue)
			return speaker_dialogue["good_rep"]
	if(reputation < 30 && (situation == "greeting" || situation == "idle"))
		if("low_rep" in speaker_dialogue)
			return speaker_dialogue["low_rep"]

	if(situation in speaker_dialogue)
		return speaker_dialogue[situation]
	return speaker_dialogue["idle"]

/// Get current dialogue based on state
/datum/trading_faction/proc/get_current_dialogue()
	// Check for temporary dialogue override (from recent transaction)
	if(dialogue_override && world.time < dialogue_override_expiry)
		return dialogue_override
	// Clear expired override
	dialogue_override = null
	return get_dialogue("idle")

/// Set a temporary dialogue override (shown for a limited time)
/datum/trading_faction/proc/set_dialogue_override(message, duration = 100)
	dialogue_override = message
	dialogue_override_expiry = world.time + duration

/// Build the valid seed list (called once, cached globally)
/datum/trading_faction/proc/build_valid_seed_list()
	if(valid_seed_types)
		return  // Already built

	valid_seed_types = list()
	for(var/seed_type in subtypesof(/obj/item/seeds))
		// Skip abstract types
		if(ispath(seed_type, /obj/item/seeds/sample))
			continue
		// Skip replicapod (requires special cloning mechanics)
		if(ispath(seed_type, /obj/item/seeds/replicapod))
			continue
		// Create a temporary seed to check its properties
		var/obj/item/seeds/temp_seed = new seed_type()
		// Must have a valid yield and product
		if(temp_seed.yield > 0 && temp_seed.product)
			// Skip rare/special seeds (rarity > 0 means it's a mutation result)
			if(temp_seed.rarity == 0)
				valid_seed_types += seed_type
		qdel(temp_seed)

/// Add base stock that all trading factions share
/datum/trading_faction/proc/add_base_stock()
	// === RAW MATERIALS ===
	// Wood
	stock += list(list("type" = /obj/item/stack/sheet/mineral/wood, "name" = "Wood", "quantity" = rand(15, 25), "base_price" = 2))
	// Sandstone
	stock += list(list("type" = /obj/item/stack/sheet/mineral/sandstone, "name" = "Sandstone", "quantity" = rand(10, 20), "base_price" = 1))

	// === PROCESSED MATERIALS ===
	// Metal Sheet
	stock += list(list("type" = /obj/item/stack/sheet/metal, "name" = "Metal Sheet", "quantity" = rand(15, 30), "base_price" = 5))
	// Glass Sheet
	stock += list(list("type" = /obj/item/stack/sheet/glass, "name" = "Glass Sheet", "quantity" = rand(10, 20), "base_price" = 4))
	// Metal Rods
	stock += list(list("type" = /obj/item/stack/rods, "name" = "Metal Rods", "quantity" = rand(15, 25), "base_price" = 3))
	// Cloth
	stock += list(list("type" = /obj/item/stack/sheet/cotton/cloth, "name" = "Cloth", "quantity" = rand(10, 20), "base_price" = 3))
	// Cotton
	stock += list(list("type" = /obj/item/stack/sheet/cotton, "name" = "Cotton", "quantity" = rand(10, 20), "base_price" = 1))
	// Rope
	stock += list(list("type" = /obj/item/stack/resurgence_rope, "name" = "Rope", "quantity" = rand(5, 10), "base_price" = 8))

	// === BASIC WOODEN TOOLS ===
	stock += list(list("type" = /obj/item/hatchet/wooden, "name" = "Wooden Hatchet", "quantity" = rand(1, 3), "base_price" = 16))
	if(prob(50))
		stock += list(list("type" = /obj/item/scythe/wooden, "name" = "Wooden Scythe", "quantity" = rand(1, 2), "base_price" = 14))

/// Generate stock items - override in subtypes
/datum/trading_faction/proc/generate_stock()
	stock = list()

/// Regenerate cash over time
/datum/trading_faction/proc/regenerate_cash()
	current_cash = min(current_cash + cash_regen_rate, max_cash)

/// Regenerate stock over time - adds small amounts to existing stock
/datum/trading_faction/proc/regenerate_stock()
	if(!length(stock))
		return
	// Each item has a small chance to regenerate 1-2 units
	for(var/list/item_entry in stock)
		if(!item_entry["quantity"])
			continue
		// 20% chance per regeneration cycle to add stock
		if(prob(20))
			var/max_quantity = item_entry["max_quantity"]
			// If no max set, use 2x current as soft cap
			if(!max_quantity)
				max_quantity = max(item_entry["quantity"] * 2, 10)
			if(item_entry["quantity"] < max_quantity)
				item_entry["quantity"] += rand(1, 2)

/// Calculate reputation gain based on transaction value
/// 1500 credits = 5 rep, so 300 credits per rep point
/datum/trading_faction/proc/calculate_rep_gain(transaction_value)
	var/base_rep = transaction_value / REP_CREDITS_PER_POINT
	// Apply faction volatility multiplier
	var/final_rep = base_rep * reputation_volatility
	// Minimum 1 rep for any trade over 50 credits
	if(transaction_value >= 50 && final_rep < 1)
		final_rep = 1
	return round(final_rep)

/// Called after a trade is completed - updates timing and dialogue
/datum/trading_faction/proc/on_trade_completed(transaction_value, is_sale = TRUE)
	last_trade_time = world.time
	// Calculate and apply rep gain
	var/rep_gain = calculate_rep_gain(transaction_value)
	if(rep_gain > 0)
		adjust_reputation(rep_gain)

	// Set dialogue based on transaction type
	var/dialogue_key = is_sale ? "sale_complete" : "purchase_complete"
	var/dialogue_message = get_dialogue(dialogue_key)
	set_dialogue_override(dialogue_message, 100)  // Show for 10 seconds

	return rep_gain

/// Process reputation decay over time
/// Called periodically - reputation decays toward decay_target if no recent trades
/datum/trading_faction/proc/process_reputation_decay()
	// Don't decay if trading is disabled (like Insurgence Clan)
	if(!can_trade)
		return

	// Check if enough time has passed since last trade
	var/time_since_trade = world.time - last_trade_time
	if(time_since_trade < REP_DECAY_GRACE_PERIOD)
		return  // Still in grace period

	// Check if enough time has passed since last decay tick
	var/time_since_decay = world.time - last_decay_time
	if(time_since_decay < REP_DECAY_INTERVAL)
		return  // Not time for decay yet

	last_decay_time = world.time

	// Decay toward target reputation
	if(reputation > decay_target_reputation)
		reputation = max(reputation - REP_DECAY_AMOUNT, decay_target_reputation)
	else if(reputation < decay_target_reputation)
		reputation = min(reputation + REP_DECAY_AMOUNT, decay_target_reputation)

/// Adjust reputation
/datum/trading_faction/proc/adjust_reputation(amount)
	reputation = clamp(reputation + amount, min_reputation, max_reputation)

/// Get buy price modifier based on reputation
/datum/trading_faction/proc/get_buy_modifier()
	switch(reputation)
		if(0 to 19)
			return 1.5  // +50%
		if(20 to 39)
			return 1.25 // +25%
		if(40 to 59)
			return 1.0  // Base
		if(60 to 79)
			return 0.9  // -10%
		if(80 to 100)
			return 0.8  // -20%
	return 1.0

/// Get sell price modifier based on reputation
/datum/trading_faction/proc/get_sell_modifier()
	switch(reputation)
		if(0 to 19)
			return 0.7  // -30%
		if(20 to 39)
			return 0.85 // -15%
		if(40 to 59)
			return 1.0  // Base
		if(60 to 79)
			return 1.1  // +10%
		if(80 to 100)
			return 1.2  // +20%
	return 1.0

/// Get reputation label
/datum/trading_faction/proc/get_reputation_label()
	switch(reputation)
		if(0 to 19)
			return "Hostile"
		if(20 to 39)
			return "Distrusted"
		if(40 to 59)
			return "Neutral"
		if(60 to 79)
			return "Friendly"
		if(80 to 100)
			return "Allied"
	return "Unknown"

// ==================== Resurgence Clan Village ====================
// Family faction - shares what little they have. Good starting reputation.
// Specialty: Basic supplies, vines, fertilizer, faith fabrics

/datum/trading_faction/resurgence_clan
	id = "resurgence_clan"
	name = "Resurgence Clan Village"
	desc = "Our kin in the homeland. They welcome us, though they have little to spare."

	speaker_name = "The Historian"
	speaker_title = "Elder of the Resurgence Clan"
	speaker_portrait = "trader_historian.png"

	discovered = TRUE  // Main faction always known

	starting_reputation = 75
	min_reputation = 20  // Familial bond
	current_cash = 500
	max_cash = 1000
	cash_regen_rate = 25

/datum/trading_faction/resurgence_clan/initialize_dialogue()
	speaker_dialogue = list(
		"greeting" = "Ah, our kin from the outpost. It warms my core to see you thriving.",
		"idle" = "The shell program continues. Your success gives our people hope.",
		"good_rep" = "You remind me of who we once were... before the Migration. Strong. Hopeful.",
		"sale_complete" = "These materials will sustain our village. The Weaver sends their thanks.",
		"purchase_complete" = "Take what you need. We have little, but family shares what they have.",
		"low_stock" = "Forgive us. The village struggles, but we endure. We always endure.",
		"low_rep" = "Even family can disappoint. But we do not abandon our own."
	)

/datum/trading_faction/resurgence_clan/generate_stock()
	stock = list()
	add_base_stock()

	// === CLAN SPECIALTY: Vines, Fertilizer, Faith Fabrics ===
	// Vines - gathered from the wild
	stock += list(list("type" = /obj/item/stack/resurgence_vines, "name" = "Wild Vines", "quantity" = rand(10, 20), "base_price" = 2))

	// Fertilizer - the clan knows the old ways
	stock += list(list("type" = /obj/item/stack/resurgence_fertilizer, "name" = "Fertilizer", "quantity" = rand(8, 15), "base_price" = 5))

	// Faith Fabrics - woven with ancestral knowledge
	if(prob(60))
		stock += list(list("type" = /obj/item/resurgence_fabric/simple, "name" = "Simple Azure Faith Fabric", "quantity" = rand(2, 4), "base_price" = 35))
	if(prob(30))
		stock += list(list("type" = /obj/item/resurgence_fabric/advanced, "name" = "Advanced Azure Faith Fabric", "quantity" = rand(1, 2), "base_price" = 80))
	if(prob(10))
		stock += list(list("type" = /obj/item/resurgence_fabric/elegant, "name" = "Elegant Azure Faith Fabric", "quantity" = 1, "base_price" = 150))

	// Durathread - rare but clan has some
	if(prob(40))
		stock += list(list("type" = /obj/item/grown/cotton/durathread, "name" = "Durathread", "quantity" = rand(3, 6), "base_price" = 8))

	// Some basic seeds from the village gardens
	stock += list(list("type" = /obj/item/seeds/wheat, "name" = "Wheat Seeds", "quantity" = rand(3, 6), "base_price" = 3))
	stock += list(list("type" = /obj/item/seeds/potato, "name" = "Potato Seeds", "quantity" = rand(2, 4), "base_price" = 3))
	stock += list(list("type" = /obj/item/seeds/carrot, "name" = "Carrot Seeds", "quantity" = rand(2, 4), "base_price" = 3))

	// Analysis skill books - the Historian's wisdom
	if(prob(50))
		stock += list(list("type" = /obj/item/book/granter/resurgence_skill/analysis, "name" = "Introduction to Analysis", "quantity" = 1, "base_price" = 55))
	if(prob(20))
		stock += list(list("type" = /obj/item/book/granter/resurgence_skill/analysis/intermediate, "name" = "Research Methodology", "quantity" = 1, "base_price" = 110))

// ==================== Jiajia-ren Village ====================
// Bird-folk traders - love shiny things, trade in exotic materials.
// Specialty: Precious metals, leather/hides, exotic fruit seeds

/datum/trading_faction/jiajia_ren
	id = "jiajia_ren"
	name = "Jiajia-ren Village"
	desc = "The Cuckoospawn speak in clicks and whistles. Difficult to understand, but their feathers fetch a good price."

	speaker_name = "Chir-rik"
	speaker_title = "Trader of the Flock"
	speaker_portrait = "trader_cuckoo.png"

	starting_reputation = 40
	current_cash = 1500
	max_cash = 3000
	cash_regen_rate = 75
	reputation_volatility = 5  // Large trades swing rep more

/datum/trading_faction/jiajia_ren/initialize_dialogue()
	speaker_dialogue = list(
		"greeting" = "*Click-click* Metal ones come. Trade? Trade is good.",
		"idle" = "*Whistle* Shiny things... you have shiny things?",
		"good_rep" = "*Happy trill* Good traders! Flock remembers. Flock likes.",
		"sale_complete" = "*Excited clicks* Yes! Good trade! Chir-rik pleased!",
		"purchase_complete" = "*Coo* Take. Is good quality. Flock makes good.",
		"low_stock" = "*Sad chirp* Not much left. Flock needs more time.",
		"low_rep" = "*Low hiss* No tricks. Flock watches. Flock remembers bad trades too."
	)

/datum/trading_faction/jiajia_ren/generate_stock()
	stock = list()
	add_base_stock()

	// === JIAJIA-REN SPECIALTY: Precious Metals, Hides, Exotic Fruits ===

	// Precious ores - they love shiny things and will trade them
	stock += list(list("type" = /obj/item/stack/ore/silver, "name" = "Shiny Silver Ore", "quantity" = rand(8, 15), "base_price" = 10))
	stock += list(list("type" = /obj/item/stack/ore/gold, "name" = "Pretty Gold Ore", "quantity" = rand(4, 8), "base_price" = 18))

	// Processed precious metals
	if(prob(50))
		stock += list(list("type" = /obj/item/stack/sheet/mineral/silver, "name" = "Silver Sheet", "quantity" = rand(3, 6), "base_price" = 22))
	if(prob(30))
		stock += list(list("type" = /obj/item/stack/sheet/mineral/gold, "name" = "Gold Sheet", "quantity" = rand(2, 4), "base_price" = 38))

	// Leather and hides - hunting trophies
	stock += list(list("type" = /obj/item/stack/sheet/leather, "name" = "Feathered Leather", "quantity" = rand(15, 25), "base_price" = 6))
	stock += list(list("type" = /obj/item/stack/sheet/animalhide/generic, "name" = "Animal Hide", "quantity" = rand(10, 18), "base_price" = 3))
	if(prob(40))
		stock += list(list("type" = /obj/item/stack/sheet/hairlesshide, "name" = "Hairless Hide", "quantity" = rand(5, 10), "base_price" = 4))
	if(prob(30))
		stock += list(list("type" = /obj/item/stack/sheet/wethide, "name" = "Wet Hide", "quantity" = rand(3, 6), "base_price" = 5))

	// Exotic fruit seeds - bird-folk know the best fruits
	stock += list(list("type" = /obj/item/seeds/berry, "name" = "Berry Seeds", "quantity" = rand(4, 8), "base_price" = 4))
	stock += list(list("type" = /obj/item/seeds/apple, "name" = "Apple Seeds", "quantity" = rand(3, 6), "base_price" = 5))
	stock += list(list("type" = /obj/item/seeds/banana, "name" = "Banana Seeds", "quantity" = rand(3, 5), "base_price" = 5))
	stock += list(list("type" = /obj/item/seeds/orange, "name" = "Orange Seeds", "quantity" = rand(2, 4), "base_price" = 5))
	stock += list(list("type" = /obj/item/seeds/grape, "name" = "Grape Seeds", "quantity" = rand(2, 4), "base_price" = 5))
	if(prob(40))
		stock += list(list("type" = /obj/item/seeds/watermelon, "name" = "Watermelon Seeds", "quantity" = rand(2, 3), "base_price" = 6))
	if(prob(30))
		stock += list(list("type" = /obj/item/seeds/pineapple, "name" = "Pineapple Seeds", "quantity" = rand(1, 2), "base_price" = 8))

	// Rare fungal seeds from their territory
	if(prob(25))
		stock += list(list("type" = /obj/item/seeds/tower, "name" = "Strange Fungus Seeds", "quantity" = rand(1, 2), "base_price" = 12))

	// === MEAT - The Jiajia-ren are skilled hunters ===
	stock += list(list("type" = /obj/item/food/meat/slab, "name" = "Raw Meat", "quantity" = rand(8, 15), "base_price" = 5))
	stock += list(list("type" = /obj/item/food/meat/slab/chicken, "name" = "Chicken Meat", "quantity" = rand(6, 12), "base_price" = 5))
	stock += list(list("type" = /obj/item/food/meat/slab/monkey, "name" = "Monkey Meat", "quantity" = rand(4, 8), "base_price" = 5))
	if(prob(60))
		stock += list(list("type" = /obj/item/food/meat/slab/bear, "name" = "Bear Meat", "quantity" = rand(2, 5), "base_price" = 8))
	if(prob(40))
		stock += list(list("type" = /obj/item/food/meat/slab/penguin, "name" = "Penguin Meat", "quantity" = rand(2, 4), "base_price" = 6))
	if(prob(30))
		stock += list(list("type" = /obj/item/food/meat/slab/gondola, "name" = "Gondola Meat", "quantity" = rand(1, 2), "base_price" = 12))
	// Bacon is always popular
	stock += list(list("type" = /obj/item/food/meat/rawbacon, "name" = "Raw Bacon", "quantity" = rand(10, 20), "base_price" = 4))

// ==================== Santata's Gift Factory ====================
// Industrial faction - bulk manufacturing, processed goods, tools.
// Specialty: Bulk metal, plasteel, ash plating, coal, manufactured tools

/datum/trading_faction/santata_factory
	id = "santata_factory"
	name = "Santata's Gift Factory"
	desc = "The chimney smoke never stops. The screams from within... best not to think about it."

	speaker_name = "Dodoru"
	speaker_title = "High-Ranking Factory Gnome"
	speaker_portrait = "trader_dodoru.png"

	starting_reputation = 50
	current_cash = 4000
	max_cash = 8000
	cash_regen_rate = 150

/datum/trading_faction/santata_factory/initialize_dialogue()
	speaker_dialogue = list(
		"greeting" = "Welcome, welcome-ome! The Factory is always open for business-ome!",
		"idle" = "Can you hear the assembly lines-ome? Beautiful music, never stops-ome.",
		"good_rep" = "Ah, our favorite customers-ome! Dodoru has special gifts for you-ome!",
		"sale_complete" = "Wonderful materials-ome! Production will be most pleased-ome!",
		"purchase_complete" = "A gift from us to you-ome! Made with... dedication-ome. Hehe.",
		"low_stock" = "Production is behind schedule-ome. More materials needed-ome!",
		"low_rep" = "Hmm, Dodoru does not recognize you-ome. New customers must prove themselves-ome.",
		"special_request" = "Say... the Factory could use some... volunteers-ome. Big reward-ome!"
	)

/datum/trading_faction/santata_factory/generate_stock()
	stock = list()
	add_base_stock()

	// === FACTORY SPECIALTY: Bulk Manufacturing, Advanced Materials, Tools ===

	// EXTRA bulk raw materials (in addition to base stock)
	stock += list(list("type" = /obj/item/stack/sheet/metal, "name" = "Gnome-forged Iron (Bulk)", "quantity" = rand(30, 60), "base_price" = 5))
	stock += list(list("type" = /obj/item/stack/sheet/glass, "name" = "Factory Glass (Bulk)", "quantity" = rand(20, 40), "base_price" = 4))
	stock += list(list("type" = /obj/item/stack/rods, "name" = "Metal Rods (Bulk)", "quantity" = rand(25, 45), "base_price" = 3))

	// Raw ores - the factory has mining operations
	stock += list(list("type" = /obj/item/stack/ore/iron, "name" = "Iron Ore", "quantity" = rand(20, 40), "base_price" = 2))
	stock += list(list("type" = /obj/item/stack/ore/ironscrap, "name" = "Iron Scrap", "quantity" = rand(15, 30), "base_price" = 1))
	stock += list(list("type" = /obj/item/stack/ore/glass, "name" = "Sand", "quantity" = rand(20, 35), "base_price" = 1))
	stock += list(list("type" = /obj/item/stack/ore/glassrubble, "name" = "Glass Rubble", "quantity" = rand(10, 20), "base_price" = 1))
	stock += list(list("type" = /obj/item/stack/ore/rock, "name" = "Rock", "quantity" = rand(30, 50), "base_price" = 1))

	// Coal - the factory runs on it
	stock += list(list("type" = /obj/item/stack/sheet/mineral/coal, "name" = "Coal", "quantity" = rand(25, 50), "base_price" = 3))

	// Advanced materials - factory produces these
	stock += list(list("type" = /obj/item/stack/sheet/plasteel, "name" = "Plasteel", "quantity" = rand(8, 15), "base_price" = 15))
	if(prob(50))
		stock += list(list("type" = /obj/item/resurgence_component/ash_plating, "name" = "Ash Plating", "quantity" = rand(2, 4), "base_price" = 80))

	// Metal Tools - factory-made quality
	stock += list(list("type" = /obj/item/hatchet, "name" = "Iron Hatchet", "quantity" = rand(3, 5), "base_price" = 28))
	stock += list(list("type" = /obj/item/pickaxe, "name" = "Iron Pickaxe", "quantity" = rand(3, 5), "base_price" = 35))
	stock += list(list("type" = /obj/item/pickaxe/mini, "name" = "Compact Pickaxe", "quantity" = rand(2, 3), "base_price" = 40))
	stock += list(list("type" = /obj/item/shovel, "name" = "Iron Shovel", "quantity" = rand(2, 4), "base_price" = 22))
	stock += list(list("type" = /obj/item/crowbar/large, "name" = "Crowbar", "quantity" = rand(2, 3), "base_price" = 18))
	stock += list(list("type" = /obj/item/crowbar, "name" = "Compact Crowbar", "quantity" = rand(2, 3), "base_price" = 22))
	stock += list(list("type" = /obj/item/scythe, "name" = "Iron Scythe", "quantity" = rand(2, 3), "base_price" = 32))

	// Silver pickaxe - rare but available
	if(prob(25))
		stock += list(list("type" = /obj/item/pickaxe/silver, "name" = "Silver Pickaxe", "quantity" = 1, "base_price" = 120))

	// Kitchen tools
	stock += list(list("type" = /obj/item/reagent_containers/glass/beaker, "name" = "Beaker", "quantity" = rand(3, 5), "base_price" = 12))
	stock += list(list("type" = /obj/item/reagent_containers/glass/beaker/large, "name" = "Large Beaker", "quantity" = rand(2, 3), "base_price" = 18))
	stock += list(list("type" = /obj/item/reagent_containers/glass/bowl, "name" = "Bowl", "quantity" = rand(3, 5), "base_price" = 12))
	stock += list(list("type" = /obj/item/kitchen/knife, "name" = "Kitchen Knife", "quantity" = rand(2, 4), "base_price" = 20))

	// Skill Books - Crafting and Mining focus
	stock += list(list("type" = /obj/item/book/granter/resurgence_skill/crafting, "name" = "Beginner's Crafting Guide", "quantity" = rand(1, 3), "base_price" = 55))
	stock += list(list("type" = /obj/item/book/granter/resurgence_skill/mining, "name" = "Prospector's Handbook", "quantity" = rand(1, 3), "base_price" = 55))
	if(prob(50))
		stock += list(list("type" = /obj/item/book/granter/resurgence_skill/crafting/intermediate, "name" = "Intermediate Crafting Manual", "quantity" = 1, "base_price" = 110))
	if(prob(50))
		stock += list(list("type" = /obj/item/book/granter/resurgence_skill/mining/intermediate, "name" = "Underground Extraction Manual", "quantity" = 1, "base_price" = 110))
	// Rare advanced books
	if(prob(20))
		stock += list(list("type" = /obj/item/book/granter/resurgence_skill/crafting/advanced, "name" = "Master Craftsman's Tome", "quantity" = 1, "base_price" = 220))
	if(prob(20))
		stock += list(list("type" = /obj/item/book/granter/resurgence_skill/mining/advanced, "name" = "Deep Earth Compendium", "quantity" = 1, "base_price" = 220))

// ==================== Cloud Town ====================
// Human survivor settlement - farming, hunting, practical goods.
// Specialty: THE SEED EMPORIUM - sells nearly all seed types!

/datum/trading_faction/cloud_town
	id = "cloud_town"
	name = "Cloud Town"
	desc = "A village of humans, somehow surviving out here. Wary of outsiders, but fair traders."

	speaker_name = "Domino"
	speaker_title = "Seasoned Hunter"
	speaker_portrait = "trader_domino.png"

	starting_reputation = 40
	current_cash = 2000
	max_cash = 4000
	cash_regen_rate = 100

/datum/trading_faction/cloud_town/initialize_dialogue()
	speaker_dialogue = list(
		"greeting" = "Machines from the outpost. You're welcome here, long as you mean no harm.",
		"idle" = "Take your time. Browse what we have.",
		"good_rep" = "You've done right by us. That counts for something out here.",
		"sale_complete" = "Good trade. These supplies will help keep the town safe.",
		"purchase_complete" = "Quality goods. Take care of yourselves out there.",
		"low_stock" = "Supplies are thin right now. Check back later.",
		"low_rep" = "We don't know you yet. Prove you're trustworthy, then we'll talk."
	)

/datum/trading_faction/cloud_town/generate_stock()
	stock = list()
	add_base_stock()

	// === CLOUD TOWN SPECIALTY: Farming, Hunting, Practical Goods ===

	// Leather and hides - hunters are skilled
	stock += list(list("type" = /obj/item/stack/sheet/leather, "name" = "Tanned Leather", "quantity" = rand(15, 30), "base_price" = 6))
	stock += list(list("type" = /obj/item/stack/sheet/animalhide/generic, "name" = "Raw Hide", "quantity" = rand(12, 22), "base_price" = 3))

	// Cotton and durathread - they grow it
	stock += list(list("type" = /obj/item/stack/sheet/cotton, "name" = "Cotton", "quantity" = rand(15, 30), "base_price" = 1))
	stock += list(list("type" = /obj/item/grown/cotton/durathread, "name" = "Durathread", "quantity" = rand(6, 12), "base_price" = 8))

	// === THE SEED EMPORIUM ===
	// Cloud Town is THE place to buy seeds - they have nearly everything!
	build_valid_seed_list()

	if(valid_seed_types && length(valid_seed_types))
		// Pick 15-25 random seed types to stock
		var/list/available_seeds = valid_seed_types.Copy()
		var/seed_variety = rand(15, 25)

		for(var/i in 1 to seed_variety)
			if(!length(available_seeds))
				break
			var/seed_type = pick_n_take(available_seeds)
			var/obj/item/seeds/temp = new seed_type()
			var/seed_name = "[temp.name]"
			qdel(temp)

			// Quantity and price based on common vs rare
			var/quantity = rand(2, 6)
			var/base_price = rand(3, 8)

			stock += list(list("type" = seed_type, "name" = seed_name, "quantity" = quantity, "base_price" = base_price))

	// Farming tools - wooden tier (hand-made)
	stock += list(list("type" = /obj/item/hatchet/wooden, "name" = "Wooden Hatchet", "quantity" = rand(2, 4), "base_price" = 16))
	stock += list(list("type" = /obj/item/scythe/wooden, "name" = "Wooden Scythe", "quantity" = rand(2, 4), "base_price" = 14))

	// Skill books - practical knowledge from human traditions
	stock += list(list("type" = /obj/item/book/granter/resurgence_skill/harvesting, "name" = "Farmer's Almanac", "quantity" = rand(1, 3), "base_price" = 55))
	stock += list(list("type" = /obj/item/book/granter/resurgence_skill/cooking, "name" = "Basic Recipes", "quantity" = rand(1, 3), "base_price" = 55))
	if(prob(50))
		stock += list(list("type" = /obj/item/book/granter/resurgence_skill/harvesting/intermediate, "name" = "Agricultural Methods", "quantity" = 1, "base_price" = 110))
	if(prob(50))
		stock += list(list("type" = /obj/item/book/granter/resurgence_skill/cooking/intermediate, "name" = "Culinary Arts", "quantity" = 1, "base_price" = 110))
	// Rare advanced books
	if(prob(20))
		stock += list(list("type" = /obj/item/book/granter/resurgence_skill/harvesting/advanced, "name" = "Botanical Mastery", "quantity" = 1, "base_price" = 220))
	if(prob(20))
		stock += list(list("type" = /obj/item/book/granter/resurgence_skill/cooking/advanced, "name" = "Gastronomic Excellence", "quantity" = 1, "base_price" = 220))
	// Analysis from hunters observing prey
	if(prob(30))
		stock += list(list("type" = /obj/item/book/granter/resurgence_skill/analysis, "name" = "Introduction to Analysis", "quantity" = 1, "base_price" = 55))
	if(prob(15))
		stock += list(list("type" = /obj/item/book/granter/resurgence_skill/analysis/advanced, "name" = "Treatise on Observation", "quantity" = 1, "base_price" = 220))

	// === COOKING INGREDIENTS - Cloud Town is known for baking ===
	stock += list(list("type" = /obj/item/reagent_containers/food/condiment/flour, "name" = "Flour", "quantity" = rand(8, 15), "base_price" = 4))
	stock += list(list("type" = /obj/item/reagent_containers/food/condiment/rice, "name" = "Rice", "quantity" = rand(6, 12), "base_price" = 4))
	stock += list(list("type" = /obj/item/storage/fancy/egg_box, "name" = "Egg Box", "quantity" = rand(3, 6), "base_price" = 10))
	stock += list(list("type" = /obj/item/reagent_containers/food/condiment/enzyme, "name" = "Universal Enzyme", "quantity" = rand(2, 4), "base_price" = 15))
	stock += list(list("type" = /obj/item/reagent_containers/food/condiment/milk, "name" = "Milk", "quantity" = rand(4, 8), "base_price" = 5))
	stock += list(list("type" = /obj/item/reagent_containers/food/condiment/soymilk, "name" = "Soy Milk", "quantity" = rand(3, 6), "base_price" = 5))
	stock += list(list("type" = /obj/item/reagent_containers/food/condiment/mayonnaise, "name" = "Mayonnaise", "quantity" = rand(2, 5), "base_price" = 6))

// ==================== Insurgence Clan ====================
// Hostile faction - does not trade, only raids.

/datum/trading_faction/insurgence_clan
	id = "insurgence_clan"
	name = "Insurgence Clan"
	desc = "The Tinkerer's red-eyed soldiers watch from the wastes. They do not negotiate. They take."

	speaker_name = "???"
	speaker_title = "Unknown"
	speaker_portrait = "trader_static.gif"

	starting_reputation = 5
	max_reputation = 10  // Permanently hostile
	current_cash = 0
	max_cash = 0
	cash_regen_rate = 0

	can_trade = FALSE
	sends_raids = TRUE

/datum/trading_faction/insurgence_clan/initialize_dialogue()
	speaker_dialogue = list(
		"greeting" = "*Static* ...You cannot hide forever, little shells...",
		"idle" = "*Distorted* ...We are watching...",
		"raid_incoming" = "...We are coming. Your cores will join us.",
		"raid_warning" = "*Static* ...You cannot hide forever, little shells...",
		"after_raid" = "*Distorted laughter* ...This is only the beginning..."
	)

/datum/trading_faction/insurgence_clan/generate_stock()
	return  // Does not trade
