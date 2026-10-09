/**
 * Resurgence Outpost - Research Nodes
 *
 * Defines all research nodes in the tech tree.
 * Each node unlocks recipes and/or blueprints when researched.
 */

/datum/resurgence_research_node
	/// Unique string identifier for this node
	var/id = null
	/// Display name
	var/name = "Unknown Research"
	/// Description of what this research provides
	var/desc = "Research description."
	/// Research tier (1-5)
	var/tier = 1
	/// Total work points needed to complete research
	var/total_work = 100
	/// Faith cost per work session (always 1)
	var/faith_per_session = 1
	/// List of prerequisite node IDs that must be researched first
	var/list/prerequisites = list()
	/// Human-readable description of what this unlocks
	var/unlocks_desc = ""
	/// UI X position (for tech tree display)
	var/ui_x = 0
	/// UI Y position (for tech tree display)
	var/ui_y = 0
	/// Branch categories for UI filtering (node can belong to multiple)
	var/list/branch_types = list("production")

// ==================== TIER 1 - Foundation ====================

/datum/resurgence_research_node/woodworking
	id = "woodworking"
	name = "Woodworking"
	desc = "Basic woodworking techniques for furniture and tool crafting."
	tier = 1
	total_work = 100
	prerequisites = list()
	unlocks_desc = "Crafting: Wooden Scythe. Blueprints: Crafting table, furniture, storage."
	ui_x = 20
	ui_y = 80
	branch_types = list("production", "decor")

/datum/resurgence_research_node/metallurgy
	id = "metallurgy"
	name = "Metallurgy"
	desc = "Working with metal to create tools and structures."
	tier = 1
	total_work = 100
	prerequisites = list()
	unlocks_desc = "Forge: Iron tools. Blueprints: Forge, iron walls/doors, reinforced window."
	ui_x = 20
	ui_y = 320
	branch_types = list("production", "armor", "weapons")

/datum/resurgence_research_node/textiles
	id = "textiles"
	name = "Textiles"
	desc = "Weaving cloth into useful items and clothing."
	tier = 1
	total_work = 100
	prerequisites = list()
	unlocks_desc = "Loom: Backpack, Satchel, Plant Bag, Mining Satchel. Blueprints: Loom."
	ui_x = 20
	ui_y = 580
	branch_types = list("production", "clothing")

// ==================== TIER 2 - Specialization ====================

/datum/resurgence_research_node/agriculture
	id = "agriculture"
	name = "Agriculture"
	desc = "Farming techniques and seed management."
	tier = 2
	total_work = 200
	prerequisites = list("woodworking")
	unlocks_desc = "Blueprints: Seed extractor."
	ui_x = 180
	ui_y = 0
	branch_types = list("production", "food")

/datum/resurgence_research_node/artistry
	id = "artistry"
	name = "Artistry"
	desc = "Creating art and decorative items."
	tier = 2
	total_work = 100  // Flavor content - reduced cost
	prerequisites = list("woodworking")
	unlocks_desc = "Crafting: Canvas sizes, Painting Frame. Blueprints: Sign, Noticeboard."
	ui_x = 180
	ui_y = 80
	branch_types = list("decor")

/datum/resurgence_research_node/harvesting_tech
	id = "harvesting_tech"
	name = "Harvesting Tech"
	desc = "Automated resource collection tools."
	tier = 2
	total_work = 200
	prerequisites = list("woodworking", "metallurgy")
	unlocks_desc = "Crafting: Simple Harvester."
	ui_x = 180
	ui_y = 160
	branch_types = list("production", "food")

/datum/resurgence_research_node/expedition_logistics
	id = "expedition_logistics"
	name = "Expedition Logistics"
	desc = "Reinforced containers designed to survive the rigors of expedition travel. These crates can be dragged through terrain and brought to faction hubs for trading."
	tier = 2
	total_work = 150
	prerequisites = list("woodworking", "metallurgy")
	unlocks_desc = "Blueprints: Expedition Crate. Allows hauling goods on expeditions for trade."
	ui_x = 180
	ui_y = 240
	branch_types = list("utility", "production")

/datum/resurgence_research_node/papercraft
	id = "papercraft"
	name = "Papercraft"
	desc = "Paper production and office supplies."
	tier = 2
	total_work = 100  // Flavor content - reduced cost
	prerequisites = list("textiles")
	unlocks_desc = "Crafting: Paper, Pens, Folders, Clipboard, etc. Blueprints: Filing cabinet."
	ui_x = 180
	ui_y = 500
	branch_types = list("utility")

/datum/resurgence_research_node/flooring
	id = "flooring"
	name = "Flooring"
	desc = "Decorative floor coverings."
	tier = 2
	total_work = 100  // Flavor content - reduced cost
	prerequisites = list("textiles")
	unlocks_desc = "Crafting: All carpet tiles."
	ui_x = 180
	ui_y = 580
	branch_types = list("decor")

/datum/resurgence_research_node/culinary
	id = "culinary"
	name = "Culinary"
	desc = "Kitchen equipment and food preparation."
	tier = 2
	total_work = 200
	prerequisites = list("metallurgy")
	unlocks_desc = "Forge: Beakers, Bowl, Kitchen Knife, Universal Enzyme. Blueprints: Kitchen equipment."
	ui_x = 180
	ui_y = 660
	branch_types = list("food", "production")

/datum/resurgence_research_node/machine_fabrication
	id = "machine_fabrication"
	name = "Machine Fabrication"
	desc = "Creating complex machinery."
	tier = 2
	total_work = 300  // Important infrastructure - increased cost
	prerequisites = list("metallurgy")
	unlocks_desc = "Blueprints: Machine fabricator, Resources recorder."
	ui_x = 180
	ui_y = 740
	branch_types = list("production", "utility")

/datum/resurgence_research_node/cleaning
	id = "cleaning"
	name = "Cleaning"
	desc = "Sanitation tools and equipment."
	tier = 2
	total_work = 100  // Flavor content - reduced cost
	prerequisites = list("metallurgy")
	unlocks_desc = "Crafting: Push Broom, Spray Can, Trash Bag. Blueprints: Trash bin, cart."
	ui_x = 180
	ui_y = 820
	branch_types = list("utility")

// ==================== TIER 3 - Advanced ====================

/datum/resurgence_research_node/basic_music
	id = "basic_music"
	name = "Basic Music"
	desc = "Simple musical instruments."
	tier = 3
	total_work = 150  // Flavor content - reduced cost
	prerequisites = list("woodworking")
	unlocks_desc = "Crafting: Recorder, Harmonica, Banjo, Bike Horn."
	ui_x = 340
	ui_y = 80
	branch_types = list("decor")

/datum/resurgence_research_node/advanced_metallurgy
	id = "advanced_metallurgy"
	name = "Advanced Metallurgy"
	desc = "Working with advanced alloys and reinforced materials."
	tier = 3
	total_work = 500  // Important production - increased cost
	prerequisites = list("metallurgy")
	unlocks_desc = "Forge: Plasteel, Silver Pickaxe, Ash Plating. Blueprints: Reinforced wall."
	ui_x = 340
	ui_y = 340
	branch_types = list("armor", "production")

/datum/resurgence_research_node/faith_weaving
	id = "faith_weaving"
	name = "Faith Weaving"
	desc = "Infusing cloth with spiritual energy."
	tier = 3
	total_work = 400
	prerequisites = list("textiles")
	unlocks_desc = "Loom: Simple Azure Faith Fabric, All custom clothing."
	ui_x = 340
	ui_y = 500
	branch_types = list("clothing")

/datum/resurgence_research_node/acceleration_protocol
	id = "acceleration_protocol"
	name = "Accelerated Crafting Protocol"
	desc = "Overclock your crafting speed at the cost of increased faith consumption."
	tier = 3
	total_work = 350
	prerequisites = list("machine_fabrication")
	unlocks_desc = "Grants Accelerated Crafting action (2x crafting speed, 3x faith drain)."
	ui_x = 340
	ui_y = 740
	branch_types = list("production", "utility")

// ==================== TIER 4 - Expert ====================

/datum/resurgence_research_node/advanced_music
	id = "advanced_music"
	name = "Advanced Music"
	desc = "Complex musical instruments."
	tier = 4
	total_work = 250  // Flavor content - reduced cost
	prerequisites = list("basic_music", "metallurgy")
	unlocks_desc = "Crafting: Violin, Guitar, Accordion, Trumpet, Saxophone, Glockenspiel."
	ui_x = 500
	ui_y = 0
	branch_types = list("decor")

/datum/resurgence_research_node/fine_furniture
	id = "fine_furniture"
	name = "Fine Furniture"
	desc = "Comfortable and decorative seating."
	tier = 4
	total_work = 300  // Flavor content - reduced cost
	prerequisites = list("woodworking", "metallurgy")
	unlocks_desc = "Blueprints: Comfy chair, Office chair, Sofa variants, Bar stool."
	ui_x = 500
	ui_y = 160
	branch_types = list("decor")

/datum/resurgence_research_node/advanced_weaving
	id = "advanced_weaving"
	name = "Advanced Weaving"
	desc = "Complex textile techniques and better storage."
	tier = 4
	total_work = 600
	prerequisites = list("faith_weaving")
	unlocks_desc = "Loom: Advanced Faith Fabric, Duffel Bag, Explorer Backpack, Leather Satchel."
	ui_x = 500
	ui_y = 500
	branch_types = list("clothing", "utility")

/datum/resurgence_research_node/luxury_decor
	id = "luxury_decor"
	name = "Luxury Decor"
	desc = "Opulent decorations using precious metals."
	tier = 4
	total_work = 350  // Flavor content - reduced cost
	prerequisites = list("advanced_metallurgy")
	unlocks_desc = "Crafting: Royal Carpets. Blueprints: Gold/Silver walls and doors."
	ui_x = 500
	ui_y = 340
	branch_types = list("decor")

/datum/resurgence_research_node/advanced_cleaning
	id = "advanced_cleaning"
	name = "Advanced Cleaning"
	desc = "Enhanced sanitation equipment."
	tier = 4
	total_work = 250  // Flavor content - reduced cost
	prerequisites = list("cleaning")
	unlocks_desc = "Crafting: Infinite Spray Can, Trash Bag of Holding, Janitor Chem Sprayer."
	ui_x = 500
	ui_y = 820
	branch_types = list("utility")

/datum/resurgence_research_node/communications
	id = "communications"
	name = "Communications"
	desc = "Radio and communication devices."
	tier = 4
	total_work = 600
	prerequisites = list("metallurgy")
	unlocks_desc = "Crafting: All Radio Headsets."
	ui_x = 500
	ui_y = 660
	branch_types = list("utility", "production")

/datum/resurgence_research_node/storage_tech
	id = "storage_tech"
	name = "Storage Tech"
	desc = "Advanced storage and preservation."
	tier = 4
	total_work = 600
	prerequisites = list("metallurgy")
	unlocks_desc = "Blueprints: Freezer, Fridge, Shower frame."
	ui_x = 500
	ui_y = 580
	branch_types = list("utility", "food")

/datum/resurgence_research_node/grid_crafting
	id = "grid_crafting"
	name = "Weapon Grid Navigation"
	desc = "Learn to use navigation cores to traverse the weapon crafting grid. Unlocks visibility of common city weapon blueprints scattered in nearby zones."
	tier = 3
	total_work = 250
	prerequisites = list("metallurgy", "advanced_metallurgy")
	unlocks_desc = "Blueprints: Ore Refiner, Grid Crafting Station. Reveals: Common city weapons (gray/green zones)."
	ui_x = 340
	ui_y = 240
	branch_types = list("weapons")

/datum/resurgence_research_node/advanced_grid_crafting
	id = "advanced_grid_crafting"
	name = "Association Weapon Patterns"
	desc = "Study the weapon patterns used by city associations. Reveals mid-tier association weapon blueprints hidden in distant grid coordinates."
	tier = 4
	total_work = 400
	prerequisites = list("grid_crafting")
	unlocks_desc = "Reveals: Association-grade weapons (blue zones)."
	ui_x = 500
	ui_y = 240
	branch_types = list("weapons")

/datum/resurgence_research_node/expert_grid_crafting
	id = "expert_grid_crafting"
	name = "Corporate Weapon Schematics"
	desc = "Decode the manufacturing secrets of corporate weapon designs. Reveals powerful corporate weapon blueprints in the far reaches of the grid."
	tier = 5
	total_work = 600
	prerequisites = list("advanced_grid_crafting")
	unlocks_desc = "Reveals: Corporate-grade weapons (purple zones)."
	ui_x = 660
	ui_y = 240
	branch_types = list("weapons")

// ==================== TIER 5 - Master ====================

/datum/resurgence_research_node/master_music
	id = "master_music"
	name = "Master Music"
	desc = "The pinnacle of musical craftsmanship."
	tier = 5
	total_work = 350  // Flavor content - reduced cost
	prerequisites = list("advanced_music", "luxury_decor")
	unlocks_desc = "Crafting: Golden Violin, Synthesizer, Synthesizer Headphones."
	ui_x = 660
	ui_y = 0
	branch_types = list("decor")

/datum/resurgence_research_node/industrial
	id = "industrial"
	name = "Industrial"
	desc = "Large-scale automated production."
	tier = 5
	total_work = 800  // Important production - increased cost
	prerequisites = list("advanced_metallurgy", "harvesting_tech")
	unlocks_desc = "Forge: Advanced Harvester."
	ui_x = 660
	ui_y = 160
	branch_types = list("production", "food")

/datum/resurgence_research_node/master_weaving
	id = "master_weaving"
	name = "Master Weaving"
	desc = "The highest art of textile crafting."
	tier = 5
	total_work = 700  // Important production - increased cost
	prerequisites = list("advanced_weaving")
	unlocks_desc = "Loom: Elegant Faith Fabric."
	ui_x = 660
	ui_y = 500
	branch_types = list("clothing")

/datum/resurgence_research_node/remote_trading
	id = "remote_trading"
	name = "Remote Trading Network"
	desc = "Establish a long-range communications network for trading with distant factions without physical travel."
	tier = 5
	total_work = 800
	prerequisites = list("communications", "storage_tech")
	unlocks_desc = "Blueprints: Communications Console. Enables remote trading with visited factions."
	ui_x = 660
	ui_y = 660
	branch_types = list("utility")

// ==================== CLOTHING PLATING ====================

/datum/resurgence_research_node/plating_tier1
	id = "plating_tier1"
	name = "Basic Armor Plating"
	desc = "Learn to craft lightweight metal plating that can be attached to clan-woven suits for protection."
	tier = 2
	total_work = 200
	prerequisites = list("metallurgy", "textiles")
	unlocks_desc = "Forge: Tier 1 Clothing Plating (20 armor)."
	ui_x = 180
	ui_y = 420
	branch_types = list("armor", "clothing")

/datum/resurgence_research_node/plating_tier2
	id = "plating_tier2"
	name = "Reinforced Armor Plating"
	desc = "Develop reinforced plating techniques using precious metals for improved protection."
	tier = 3
	total_work = 400
	prerequisites = list("plating_tier1", "advanced_metallurgy")
	unlocks_desc = "Forge: Tier 2 Clothing Plating (40 armor). Requires Tier 1 on garment."
	ui_x = 340
	ui_y = 420
	branch_types = list("armor")

/datum/resurgence_research_node/plating_tier3
	id = "plating_tier3"
	name = "Heavy Armor Plating"
	desc = "Master heavy plating construction using plasteel and advanced textiles."
	tier = 4
	total_work = 600
	prerequisites = list("plating_tier2")
	unlocks_desc = "Forge: Tier 3 Clothing Plating (60 armor). Requires Tier 2 on garment."
	ui_x = 500
	ui_y = 420
	branch_types = list("armor")

/datum/resurgence_research_node/plating_tier4
	id = "plating_tier4"
	name = "Master Armor Plating"
	desc = "The pinnacle of armor craftsmanship. Create master-grade plating rivaling corporate equipment."
	tier = 5
	total_work = 800
	prerequisites = list("plating_tier3")
	unlocks_desc = "Forge: Tier 4 Clothing Plating (80 armor). Requires Tier 3 on garment."
	ui_x = 660
	ui_y = 420
	branch_types = list("armor")

// ==================== LIGHTING ====================

/datum/resurgence_research_node/basic_lighting
	id = "basic_lighting"
	name = "Basic Lighting"
	desc = "Simple fire-based light sources to push back the darkness."
	tier = 1
	total_work = 100
	prerequisites = list()
	unlocks_desc = "Crafting: Long Torch, Campfire."
	ui_x = 20
	ui_y = 900
	branch_types = list("utility", "production")

/datum/resurgence_research_node/advanced_lighting
	id = "advanced_lighting"
	name = "Advanced Lighting"
	desc = "Enclosed flame designs for longer-lasting, refuelable light sources."
	tier = 2
	total_work = 200
	prerequisites = list("basic_lighting", "metallurgy")
	unlocks_desc = "Crafting: Oil Lantern, Glass Lantern, Stone Fireplace."
	ui_x = 180
	ui_y = 900
	branch_types = list("utility", "production")

/datum/resurgence_research_node/electric_lighting
	id = "electric_lighting"
	name = "Electric Lighting"
	desc = "Harnessing electrical power for reliable, bright illumination."
	tier = 3
	total_work = 350
	prerequisites = list("advanced_lighting")
	unlocks_desc = "Crafting: Hand Light, Spotlight."
	ui_x = 340
	ui_y = 900
	branch_types = list("utility", "production")

// ==================== CLAN ARMAMENTS ====================

/datum/resurgence_research_node/clan_arms
	id = "clan_arms"
	name = "Clan Armaments"
	desc = "Study the weapons used by rival clan raiders and learn to forge your own. Unlocks basic clan weapons and ammunition."
	tier = 2
	total_work = 150
	prerequisites = list("metallurgy")
	unlocks_desc = "Blueprints: Weapons Bench. Crafting: Militia weapons, ammunition, magazines."
	ui_x = 180
	ui_y = 980
	branch_types = list("weapons")

/datum/resurgence_research_node/improved_clan_arms
	id = "improved_clan_arms"
	name = "Improved Clan Arms"
	desc = "Refine clan weapon designs with better materials and construction techniques."
	tier = 3
	total_work = 300
	prerequisites = list("clan_arms", "advanced_metallurgy")
	unlocks_desc = "Crafting: Standard-tier clan weapons and ammunition."
	ui_x = 340
	ui_y = 980
	branch_types = list("weapons")

/datum/resurgence_research_node/veteran_clan_arms
	id = "veteran_clan_arms"
	name = "Veteran Clan Arms"
	desc = "Master advanced weapon forging techniques using precious metals. Unlock faith-channeling weaponry."
	tier = 4
	total_work = 500
	prerequisites = list("improved_clan_arms")
	unlocks_desc = "Crafting: Veteran weapons, Void Caster (BLACK damage faith gun)."
	ui_x = 500
	ui_y = 980
	branch_types = list("weapons")

/datum/resurgence_research_node/elite_clan_arms
	id = "elite_clan_arms"
	name = "Elite Clan Arms"
	desc = "The pinnacle of clan weaponsmithing. Forge devastating weapons from the rarest materials."
	tier = 5
	total_work = 700
	prerequisites = list("veteran_clan_arms")
	unlocks_desc = "Crafting: Elite weapons, Pale Lance (PALE damage faith gun)."
	ui_x = 660
	ui_y = 980
	branch_types = list("weapons")
