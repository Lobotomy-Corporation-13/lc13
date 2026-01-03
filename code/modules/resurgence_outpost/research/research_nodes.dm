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

// ==================== TIER 1 - Foundation ====================

/datum/resurgence_research_node/woodworking
	id = "woodworking"
	name = "Woodworking"
	desc = "Basic woodworking techniques for furniture and tool crafting."
	tier = 1
	total_work = 100
	prerequisites = list()
	unlocks_desc = "Crafting: Wooden Scythe. Blueprints: Crafting table, furniture, storage."
	ui_x = 50
	ui_y = 0

/datum/resurgence_research_node/metallurgy
	id = "metallurgy"
	name = "Metallurgy"
	desc = "Working with metal to create tools and structures."
	tier = 1
	total_work = 100
	prerequisites = list()
	unlocks_desc = "Forge: Iron tools. Blueprints: Forge, iron walls/doors."
	ui_x = 50
	ui_y = 120

/datum/resurgence_research_node/textiles
	id = "textiles"
	name = "Textiles"
	desc = "Weaving cloth into useful items and clothing."
	tier = 1
	total_work = 100
	prerequisites = list()
	unlocks_desc = "Loom: Backpack, Satchel. Blueprints: Loom."
	ui_x = 50
	ui_y = 240

// ==================== TIER 2 - Specialization ====================

/datum/resurgence_research_node/agriculture
	id = "agriculture"
	name = "Agriculture"
	desc = "Farming techniques and seed management."
	tier = 2
	total_work = 200
	prerequisites = list("woodworking")
	unlocks_desc = "Blueprints: Seed extractor."
	ui_x = 220
	ui_y = 0

/datum/resurgence_research_node/artistry
	id = "artistry"
	name = "Artistry"
	desc = "Creating art and decorative items."
	tier = 2
	total_work = 100  // Flavor content - reduced cost
	prerequisites = list("woodworking")
	unlocks_desc = "Crafting: Canvas sizes, Painting Frame. Blueprints: Sign, Noticeboard."
	ui_x = 220
	ui_y = 80

/datum/resurgence_research_node/harvesting_tech
	id = "harvesting_tech"
	name = "Harvesting Tech"
	desc = "Automated resource collection tools."
	tier = 2
	total_work = 200
	prerequisites = list("woodworking", "metallurgy")
	unlocks_desc = "Crafting: Simple Harvester."
	ui_x = 220
	ui_y = 160

/datum/resurgence_research_node/papercraft
	id = "papercraft"
	name = "Papercraft"
	desc = "Paper production and office supplies."
	tier = 2
	total_work = 100  // Flavor content - reduced cost
	prerequisites = list("textiles")
	unlocks_desc = "Crafting: Paper, Pens, Folders, Clipboard, etc. Blueprints: Filing cabinet."
	ui_x = 220
	ui_y = 240

/datum/resurgence_research_node/flooring
	id = "flooring"
	name = "Flooring"
	desc = "Decorative floor coverings."
	tier = 2
	total_work = 100  // Flavor content - reduced cost
	prerequisites = list("textiles")
	unlocks_desc = "Crafting: All carpet tiles."
	ui_x = 220
	ui_y = 320

/datum/resurgence_research_node/culinary
	id = "culinary"
	name = "Culinary"
	desc = "Kitchen equipment and food preparation."
	tier = 2
	total_work = 200
	prerequisites = list("metallurgy")
	unlocks_desc = "Forge: Beakers, Bowl, Kitchen Knife, Universal Enzyme. Blueprints: Kitchen equipment."
	ui_x = 220
	ui_y = 400

/datum/resurgence_research_node/machine_fabrication
	id = "machine_fabrication"
	name = "Machine Fabrication"
	desc = "Creating complex machinery."
	tier = 2
	total_work = 300  // Important infrastructure - increased cost
	prerequisites = list("metallurgy")
	unlocks_desc = "Blueprints: Machine fabricator, Resources recorder, Communications Console."
	ui_x = 220
	ui_y = 480

/datum/resurgence_research_node/cleaning
	id = "cleaning"
	name = "Cleaning"
	desc = "Sanitation tools and equipment."
	tier = 2
	total_work = 100  // Flavor content - reduced cost
	prerequisites = list("metallurgy")
	unlocks_desc = "Crafting: Push Broom, Spray Can, Trash Bag. Blueprints: Trash bin, cart."
	ui_x = 220
	ui_y = 560

// ==================== TIER 3 - Advanced ====================

/datum/resurgence_research_node/basic_music
	id = "basic_music"
	name = "Basic Music"
	desc = "Simple musical instruments."
	tier = 3
	total_work = 150  // Flavor content - reduced cost
	prerequisites = list("woodworking")
	unlocks_desc = "Crafting: Recorder, Harmonica, Banjo, Bike Horn."
	ui_x = 390
	ui_y = 80

/datum/resurgence_research_node/advanced_metallurgy
	id = "advanced_metallurgy"
	name = "Advanced Metallurgy"
	desc = "Working with advanced alloys and reinforced materials."
	tier = 3
	total_work = 500  // Important production - increased cost
	prerequisites = list("metallurgy")
	unlocks_desc = "Forge: Plasteel, Silver Pickaxe, Ash Plating. Blueprints: Reinforced wall."
	ui_x = 390
	ui_y = 200

/datum/resurgence_research_node/faith_weaving
	id = "faith_weaving"
	name = "Faith Weaving"
	desc = "Infusing cloth with spiritual energy."
	tier = 3
	total_work = 400
	prerequisites = list("textiles")
	unlocks_desc = "Loom: Simple Azure Faith Fabric."
	ui_x = 390
	ui_y = 320

// ==================== TIER 4 - Expert ====================

/datum/resurgence_research_node/advanced_music
	id = "advanced_music"
	name = "Advanced Music"
	desc = "Complex musical instruments."
	tier = 4
	total_work = 250  // Flavor content - reduced cost
	prerequisites = list("basic_music", "metallurgy")
	unlocks_desc = "Crafting: Violin, Guitar, Accordion, Trumpet, Saxophone, Glockenspiel."
	ui_x = 560
	ui_y = 0

/datum/resurgence_research_node/fine_furniture
	id = "fine_furniture"
	name = "Fine Furniture"
	desc = "Comfortable and decorative seating."
	tier = 4
	total_work = 300  // Flavor content - reduced cost
	prerequisites = list("woodworking", "metallurgy")
	unlocks_desc = "Blueprints: Comfy chair, Office chair, Sofa variants, Bar stool."
	ui_x = 560
	ui_y = 120

/datum/resurgence_research_node/advanced_weaving
	id = "advanced_weaving"
	name = "Advanced Weaving"
	desc = "Complex textile techniques and better storage."
	tier = 4
	total_work = 600
	prerequisites = list("faith_weaving")
	unlocks_desc = "Loom: Advanced Faith Fabric, Duffel Bag, Explorer Backpack, Leather Satchel."
	ui_x = 560
	ui_y = 200

/datum/resurgence_research_node/luxury_decor
	id = "luxury_decor"
	name = "Luxury Decor"
	desc = "Opulent decorations using precious metals."
	tier = 4
	total_work = 350  // Flavor content - reduced cost
	prerequisites = list("advanced_metallurgy")
	unlocks_desc = "Crafting: Royal Carpets. Blueprints: Gold/Silver walls and doors."
	ui_x = 560
	ui_y = 320

/datum/resurgence_research_node/advanced_cleaning
	id = "advanced_cleaning"
	name = "Advanced Cleaning"
	desc = "Enhanced sanitation equipment."
	tier = 4
	total_work = 250  // Flavor content - reduced cost
	prerequisites = list("cleaning")
	unlocks_desc = "Crafting: Infinite Spray Can, Trash Bag of Holding, Janitor Chem Sprayer."
	ui_x = 560
	ui_y = 440

/datum/resurgence_research_node/communications
	id = "communications"
	name = "Communications"
	desc = "Radio and communication devices."
	tier = 4
	total_work = 600
	prerequisites = list("metallurgy")
	unlocks_desc = "Crafting: All Radio Headsets."
	ui_x = 560
	ui_y = 520

/datum/resurgence_research_node/storage_tech
	id = "storage_tech"
	name = "Storage Tech"
	desc = "Advanced storage and preservation."
	tier = 4
	total_work = 600
	prerequisites = list("metallurgy")
	unlocks_desc = "Blueprints: Freezer, Fridge, Shower frame."
	ui_x = 560
	ui_y = 600

// ==================== TIER 5 - Master ====================

/datum/resurgence_research_node/master_music
	id = "master_music"
	name = "Master Music"
	desc = "The pinnacle of musical craftsmanship."
	tier = 5
	total_work = 350  // Flavor content - reduced cost
	prerequisites = list("advanced_music", "luxury_decor")
	unlocks_desc = "Crafting: Golden Violin, Synthesizer, Synthesizer Headphones."
	ui_x = 730
	ui_y = 0

/datum/resurgence_research_node/industrial
	id = "industrial"
	name = "Industrial"
	desc = "Large-scale automated production."
	tier = 5
	total_work = 800  // Important production - increased cost
	prerequisites = list("advanced_metallurgy", "harvesting_tech")
	unlocks_desc = "Forge: Advanced Harvester."
	ui_x = 730
	ui_y = 120

/datum/resurgence_research_node/master_weaving
	id = "master_weaving"
	name = "Master Weaving"
	desc = "The highest art of textile crafting."
	tier = 5
	total_work = 700  // Important production - increased cost
	prerequisites = list("advanced_weaving")
	unlocks_desc = "Loom: Elegant Faith Fabric, All dynamic clothing."
	ui_x = 730
	ui_y = 240
