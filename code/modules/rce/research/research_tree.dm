// RCE Research Tree - Defines research nodes for pyro weapons

/datum/rce_research_node
	var/id = ""
	var/name = "Research Node"
	var/desc = "A research project."
	var/tier = 1
	var/cost = 100
	var/branch = "hellfire" // "hellfire", "venom", or "storm"
	var/list/prerequisites = list()
	var/unlocked_path = null
	var/list/favored_traits = list() // Traits that give bonus points (trait = modifier)
	var/list/negative_traits = list() // Traits that reduce points (trait = modifier)
	var/list/required_traits = list() // Must have at least one of these traits

/proc/initialize_research_tree()
	GLOB.rce_research_nodes = list()

	// Tier 1 - Basic Pyro
	var/datum/rce_research_node/pyro_grenade = new
	pyro_grenade.id = "pyro_grenade"
	pyro_grenade.name = "Pyro Grenade Manufacturing"
	pyro_grenade.desc = "Unlocks the ability to manufacture R-Corp pyro grenades that create fire zones."
	pyro_grenade.tier = RCE_RESEARCH_TIER_1
	pyro_grenade.cost = 50
	pyro_grenade.prerequisites = list("fuel_tank")
	pyro_grenade.unlocked_path = /obj/item/portable_factory/pyro_grenade
	pyro_grenade.favored_traits = list(
		TRAIT_VOLATILE = TRAIT_BONUS_MODERATE,
		TRAIT_ORGANIC = TRAIT_BONUS_MINOR,
		TRAIT_WEAPONIZED = TRAIT_BONUS_MINOR
	)
	pyro_grenade.negative_traits = list(
		TRAIT_MECHANICAL = TRAIT_PENALTY_MINOR,
		TRAIT_ARMORED = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[pyro_grenade.id] = pyro_grenade

	var/datum/rce_research_node/fuel_tank = new
	fuel_tank.id = "fuel_tank"
	fuel_tank.name = "Heavy Fuel Tank Production"
	fuel_tank.desc = "Unlocks manufacturing of heavy fuel tank backpacks for pyro weapons."
	fuel_tank.tier = 0
	fuel_tank.cost = 40
	fuel_tank.prerequisites = list()
	fuel_tank.unlocked_path = /obj/item/portable_factory/fuel_tank
	fuel_tank.favored_traits = list(
		TRAIT_MECHANICAL = TRAIT_BONUS_MODERATE,
		TRAIT_EFFICIENT = TRAIT_BONUS_MINOR,
		TRAIT_LIGHTWEIGHT = TRAIT_BONUS_MINOR
	)
	fuel_tank.negative_traits = list(
		TRAIT_CORRUPTED = TRAIT_PENALTY_MINOR,
		TRAIT_VOLATILE = TRAIT_PENALTY_MODERATE
	)
	GLOB.rce_research_nodes[fuel_tank.id] = fuel_tank

	var/datum/rce_research_node/hellfire_armor = new
	hellfire_armor.id = "hellfire_armor"
	hellfire_armor.name = "Hellfire Protection Suit"
	hellfire_armor.desc = "Fire-resistant armor designed for pyro specialists."
	hellfire_armor.tier = RCE_RESEARCH_TIER_1
	hellfire_armor.cost = 60
	hellfire_armor.prerequisites = list("fuel_tank")
	hellfire_armor.unlocked_path = /obj/item/portable_factory/hellfire_armor
	hellfire_armor.favored_traits = list(
		TRAIT_ARMORED = TRAIT_BONUS_MAJOR,
		TRAIT_REINFORCED = TRAIT_BONUS_MODERATE,
		TRAIT_ORGANIC = TRAIT_BONUS_MINOR
	)
	hellfire_armor.negative_traits = list(
		TRAIT_LIGHTWEIGHT = TRAIT_PENALTY_MODERATE,
		TRAIT_FRAGMENTED = TRAIT_PENALTY_MAJOR
	)
	GLOB.rce_research_nodes[hellfire_armor.id] = hellfire_armor

	// Tier 2 - Advanced Pyro
	var/datum/rce_research_node/heavy_flamethrower = new
	heavy_flamethrower.id = "heavy_flamethrower"
	heavy_flamethrower.name = "Heavy Flamethrower System"
	heavy_flamethrower.desc = "Industrial-grade flamethrower that requires fuel tank to operate."
	heavy_flamethrower.tier = RCE_RESEARCH_TIER_2
	heavy_flamethrower.cost = 150
	heavy_flamethrower.prerequisites = list("fuel_tank")
	heavy_flamethrower.unlocked_path = /obj/item/ego_weapon/ranged/heavy_flamethrower
	heavy_flamethrower.favored_traits = list(
		TRAIT_WEAPONIZED = TRAIT_BONUS_MAJOR,
		TRAIT_MECHANICAL = TRAIT_BONUS_MODERATE,
		TRAIT_ENERGIZED = TRAIT_BONUS_MINOR
	)
	heavy_flamethrower.negative_traits = list(
		TRAIT_FODDER = TRAIT_PENALTY_MODERATE,
		TRAIT_RCE_PRIMITIVE = TRAIT_PENALTY_MINOR
	)
	heavy_flamethrower.required_traits = list(TRAIT_MECHANICAL, TRAIT_WEAPONIZED)
	GLOB.rce_research_nodes[heavy_flamethrower.id] = heavy_flamethrower

	var/datum/rce_research_node/thermite_sprayer = new
	thermite_sprayer.id = "thermite_sprayer"
	thermite_sprayer.name = "Thermite Sprayer"
	thermite_sprayer.desc = "Sprays volatile thermite gel that explodes after a delay."
	thermite_sprayer.tier = RCE_RESEARCH_TIER_2
	thermite_sprayer.cost = 120
	thermite_sprayer.prerequisites = list("pyro_grenade")
	thermite_sprayer.unlocked_path = /obj/item/ego_weapon/thermite_sprayer
	thermite_sprayer.favored_traits = list(
		TRAIT_VOLATILE = TRAIT_BONUS_MAJOR,
		TRAIT_TOXIC = TRAIT_BONUS_MODERATE,
		TRAIT_EXPERIMENTAL = TRAIT_BONUS_MINOR
	)
	thermite_sprayer.negative_traits = list(
		TRAIT_ARMORED = TRAIT_PENALTY_MODERATE,
		TRAIT_HEAVY = TRAIT_PENALTY_MINOR
	)
	thermite_sprayer.required_traits = list(TRAIT_VOLATILE, TRAIT_TOXIC, TRAIT_ORGANIC)
	GLOB.rce_research_nodes[thermite_sprayer.id] = thermite_sprayer

	var/datum/rce_research_node/inferno_wall = new
	inferno_wall.id = "inferno_wall"
	inferno_wall.name = "Inferno Wall Projector"
	inferno_wall.desc = "Projects walls of intense flames to block enemy advance."
	inferno_wall.tier = RCE_RESEARCH_TIER_2
	inferno_wall.cost = 140
	inferno_wall.prerequisites = list("fuel_tank")
	inferno_wall.unlocked_path = /obj/item/ego_weapon/inferno_wall
	inferno_wall.favored_traits = list(
		TRAIT_NEURAL = TRAIT_BONUS_MODERATE,
		TRAIT_ADAPTIVE = TRAIT_BONUS_MODERATE,
		TRAIT_ENERGIZED = TRAIT_BONUS_MINOR
	)
	inferno_wall.negative_traits = list(
		TRAIT_RCE_PRIMITIVE = TRAIT_PENALTY_MAJOR,
		TRAIT_FODDER = TRAIT_PENALTY_MODERATE
	)
	inferno_wall.required_traits = list(TRAIT_NEURAL, TRAIT_ADAPTIVE, TRAIT_MECHANICAL)
	GLOB.rce_research_nodes[inferno_wall.id] = inferno_wall

	var/datum/rce_research_node/auto_flamethrower = new
	auto_flamethrower.id = "auto_flamethrower"
	auto_flamethrower.name = "Automatic Defense Flamethrower"
	auto_flamethrower.desc = "Automated flamethrower system that detects and engages hostile targets automatically."
	auto_flamethrower.tier = RCE_RESEARCH_TIER_2
	auto_flamethrower.cost = 180
	auto_flamethrower.prerequisites = list("heavy_flamethrower")
	auto_flamethrower.unlocked_path = /obj/item/portable_factory/auto_flamethrower
	auto_flamethrower.favored_traits = list(
		TRAIT_MECHANICAL = TRAIT_BONUS_MAJOR,
		TRAIT_NEURAL = TRAIT_BONUS_MODERATE,
		TRAIT_ADAPTIVE = TRAIT_BONUS_MODERATE,
		TRAIT_PRECISION = TRAIT_BONUS_MINOR
	)
	auto_flamethrower.negative_traits = list(
		TRAIT_ERRATIC = TRAIT_PENALTY_MAJOR,
		TRAIT_RCE_PRIMITIVE = TRAIT_PENALTY_MODERATE,
		TRAIT_FODDER = TRAIT_PENALTY_MINOR
	)
	auto_flamethrower.required_traits = list(TRAIT_MECHANICAL, TRAIT_NEURAL)
	GLOB.rce_research_nodes[auto_flamethrower.id] = auto_flamethrower

	// Tier 3 - Elite Pyro
	var/datum/rce_research_node/inferno_rush = new
	inferno_rush.id = "inferno_rush"
	inferno_rush.name = "Inferno Rush Blade"
	inferno_rush.desc = "Superheated blade that channels fuel for devastating fire dashes."
	inferno_rush.tier = RCE_RESEARCH_TIER_3
	inferno_rush.cost = 250
	inferno_rush.prerequisites = list("heavy_flamethrower", "hellfire_armor")
	inferno_rush.unlocked_path = /obj/item/ego_weapon/inferno_rush
	inferno_rush.favored_traits = list(
		TRAIT_AGILE = TRAIT_BONUS_MAJOR,
		TRAIT_WEAPONIZED = TRAIT_BONUS_MAJOR,
		TRAIT_LIGHTWEIGHT = TRAIT_BONUS_MODERATE,
		TRAIT_BERSERKER = TRAIT_BONUS_MINOR
	)
	inferno_rush.negative_traits = list(
		TRAIT_HEAVY = TRAIT_PENALTY_MAJOR,
		TRAIT_SLUGGISH = TRAIT_PENALTY_MAJOR,
		TRAIT_ARMORED = TRAIT_PENALTY_MINOR
	)
	inferno_rush.required_traits = list(TRAIT_AGILE, TRAIT_WEAPONIZED)
	GLOB.rce_research_nodes[inferno_rush.id] = inferno_rush

	var/datum/rce_research_node/pyroclastic_gauntlets = new
	pyroclastic_gauntlets.id = "pyroclastic_gauntlets"
	pyroclastic_gauntlets.name = "Pyroclastic Burst Gauntlets"
	pyroclastic_gauntlets.desc = "Heavy gauntlets that channel fuel into explosive fire bursts."
	pyroclastic_gauntlets.tier = RCE_RESEARCH_TIER_3
	pyroclastic_gauntlets.cost = 220
	pyroclastic_gauntlets.prerequisites = list("thermite_sprayer", "hellfire_armor")
	pyroclastic_gauntlets.unlocked_path = /obj/item/ego_weapon/pyroclastic_gauntlets
	pyroclastic_gauntlets.favored_traits = list(
		TRAIT_BRUTAL = TRAIT_BONUS_MAJOR,
		TRAIT_VOLATILE = TRAIT_BONUS_MODERATE,
		TRAIT_HEAVY = TRAIT_BONUS_MODERATE,
		TRAIT_WEAPONIZED = TRAIT_BONUS_MINOR
	)
	pyroclastic_gauntlets.negative_traits = list(
		TRAIT_LIGHTWEIGHT = TRAIT_PENALTY_MODERATE,
		TRAIT_PRECISION = TRAIT_PENALTY_MINOR
	)
	pyroclastic_gauntlets.required_traits = list(TRAIT_BRUTAL, TRAIT_VOLATILE, TRAIT_ORGANIC)
	GLOB.rce_research_nodes[pyroclastic_gauntlets.id] = pyroclastic_gauntlets

	var/datum/rce_research_node/napalm_launcher = new
	napalm_launcher.id = "napalm_launcher"
	napalm_launcher.name = "Napalm Launcher"
	napalm_launcher.desc = "Heavy launcher that fires arcing napalm shells for area bombardment."
	napalm_launcher.tier = RCE_RESEARCH_TIER_3
	napalm_launcher.cost = 280
	napalm_launcher.prerequisites = list("heavy_flamethrower", "inferno_wall")
	napalm_launcher.unlocked_path = /obj/item/ego_weapon/ranged/napalm_launcher
	napalm_launcher.favored_traits = list(
		TRAIT_ELITE = TRAIT_BONUS_MAJOR,
		TRAIT_WEAPONIZED = TRAIT_BONUS_MAJOR,
		TRAIT_PRECISION = TRAIT_BONUS_MODERATE,
		TRAIT_MECHANICAL = TRAIT_BONUS_MINOR
	)
	napalm_launcher.negative_traits = list(
		TRAIT_FODDER = TRAIT_PENALTY_MAJOR,
		TRAIT_RCE_PRIMITIVE = TRAIT_PENALTY_MODERATE,
		TRAIT_ERRATIC = TRAIT_PENALTY_MINOR
	)
	napalm_launcher.required_traits = list(TRAIT_ELITE, TRAIT_WEAPONIZED, TRAIT_PRECISION)
	GLOB.rce_research_nodes[napalm_launcher.id] = napalm_launcher

	// VENOM RATTLESNAKES - TOXIC WEAPONS TREE

	// Tier 1 - Basic Toxic
	var/datum/rce_research_node/acid_tank = new
	acid_tank.id = "acid_tank"
	acid_tank.name = "Acid Tank Production"
	acid_tank.desc = "Unlocks manufacturing of acid tank backpacks for toxic weapons."
	acid_tank.tier = 0
	acid_tank.cost = 40
	acid_tank.branch = "venom"
	acid_tank.prerequisites = list()
	acid_tank.unlocked_path = /obj/item/portable_factory/acid_tank
	acid_tank.favored_traits = list(
		TRAIT_TOXIC = TRAIT_BONUS_MAJOR,
		TRAIT_ORGANIC = TRAIT_BONUS_MODERATE,
		TRAIT_EFFICIENT = TRAIT_BONUS_MINOR
	)
	acid_tank.negative_traits = list(
		TRAIT_MECHANICAL = TRAIT_PENALTY_MINOR,
		TRAIT_ARMORED = TRAIT_PENALTY_MODERATE
	)
	GLOB.rce_research_nodes[acid_tank.id] = acid_tank

	var/datum/rce_research_node/acid_sprayer = new
	acid_sprayer.id = "acid_sprayer"
	acid_sprayer.name = "Acid Sprayer"
	acid_sprayer.desc = "Basic cone spray weapon that melts armor and flesh."
	acid_sprayer.tier = RCE_RESEARCH_TIER_1
	acid_sprayer.cost = 50
	acid_sprayer.branch = "venom"
	acid_sprayer.prerequisites = list("acid_tank")
	acid_sprayer.unlocked_path = /obj/item/ego_weapon/ranged/acid_sprayer
	acid_sprayer.favored_traits = list(
		TRAIT_TOXIC = TRAIT_BONUS_MODERATE,
		TRAIT_VOLATILE = TRAIT_BONUS_MINOR,
		TRAIT_ORGANIC = TRAIT_BONUS_MINOR
	)
	acid_sprayer.negative_traits = list(
		TRAIT_REINFORCED = TRAIT_PENALTY_MINOR,
		TRAIT_HEAVY = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[acid_sprayer.id] = acid_sprayer

	var/datum/rce_research_node/toxic_mines = new
	toxic_mines.id = "toxic_mines"
	toxic_mines.name = "Toxic Mine Manufacturing"
	toxic_mines.desc = "Proximity mines that release toxic clouds."
	toxic_mines.tier = RCE_RESEARCH_TIER_1
	toxic_mines.cost = 45
	toxic_mines.branch = "venom"
	toxic_mines.prerequisites = list("acid_tank")
	toxic_mines.unlocked_path = /obj/item/portable_factory/toxic_mines
	toxic_mines.favored_traits = list(
		TRAIT_MECHANICAL = TRAIT_BONUS_MODERATE,
		TRAIT_TOXIC = TRAIT_BONUS_MODERATE,
		TRAIT_PRECISION = TRAIT_BONUS_MINOR
	)
	toxic_mines.negative_traits = list(
		TRAIT_ERRATIC = TRAIT_PENALTY_MAJOR,
		TRAIT_FODDER = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[toxic_mines.id] = toxic_mines

	var/datum/rce_research_node/acid_grenade = new
	acid_grenade.id = "acid_grenade"
	acid_grenade.name = "Corrosive Grenade Production"
	acid_grenade.desc = "Grenades that create lingering acid pools."
	acid_grenade.tier = RCE_RESEARCH_TIER_1
	acid_grenade.cost = 55
	acid_grenade.branch = "venom"
	acid_grenade.prerequisites = list("acid_tank")
	acid_grenade.unlocked_path = /obj/item/portable_factory/acid_grenade
	acid_grenade.favored_traits = list(
		TRAIT_VOLATILE = TRAIT_BONUS_MODERATE,
		TRAIT_TOXIC = TRAIT_BONUS_MODERATE,
		TRAIT_WEAPONIZED = TRAIT_BONUS_MINOR
	)
	acid_grenade.negative_traits = list(
		TRAIT_ARMORED = TRAIT_PENALTY_MINOR,
		TRAIT_MECHANICAL = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[acid_grenade.id] = acid_grenade

	// Tier 2 - Advanced Toxic
	var/datum/rce_research_node/venom_launcher = new
	venom_launcher.id = "venom_launcher"
	venom_launcher.name = "Venom Launcher"
	venom_launcher.desc = "Fires toxic shells that explode into acid clouds."
	venom_launcher.tier = RCE_RESEARCH_TIER_2
	venom_launcher.cost = 140
	venom_launcher.branch = "venom"
	venom_launcher.prerequisites = list("acid_tank", "acid_grenade")
	venom_launcher.unlocked_path = /obj/item/ego_weapon/ranged/venom_launcher
	venom_launcher.favored_traits = list(
		TRAIT_TOXIC = TRAIT_BONUS_MAJOR,
		TRAIT_WEAPONIZED = TRAIT_BONUS_MODERATE,
		TRAIT_PRECISION = TRAIT_BONUS_MINOR
	)
	venom_launcher.negative_traits = list(
		TRAIT_LIGHTWEIGHT = TRAIT_PENALTY_MODERATE,
		TRAIT_FODDER = TRAIT_PENALTY_MINOR
	)
	venom_launcher.required_traits = list(TRAIT_TOXIC, TRAIT_WEAPONIZED)
	GLOB.rce_research_nodes[venom_launcher.id] = venom_launcher

	var/datum/rce_research_node/decay_cloud = new
	decay_cloud.id = "decay_cloud"
	decay_cloud.name = "Decay Cloud Generator"
	decay_cloud.desc = "Creates massive moving toxic clouds."
	decay_cloud.tier = RCE_RESEARCH_TIER_2
	decay_cloud.cost = 130
	decay_cloud.branch = "venom"
	decay_cloud.prerequisites = list("acid_sprayer", "toxic_mines")
	decay_cloud.unlocked_path = /obj/item/decay_cloud_generator
	decay_cloud.favored_traits = list(
		TRAIT_TOXIC = TRAIT_BONUS_MAJOR,
		TRAIT_CORRUPTED = TRAIT_BONUS_MODERATE,
		TRAIT_VOLATILE = TRAIT_BONUS_MINOR
	)
	decay_cloud.negative_traits = list(
		TRAIT_PRECISION = TRAIT_PENALTY_MODERATE,
		TRAIT_LIGHTWEIGHT = TRAIT_PENALTY_MINOR
	)
	decay_cloud.required_traits = list(TRAIT_TOXIC, TRAIT_CORRUPTED, TRAIT_ORGANIC)
	GLOB.rce_research_nodes[decay_cloud.id] = decay_cloud

	var/datum/rce_research_node/venom_injector = new
	venom_injector.id = "venom_injector"
	venom_injector.name = "Venom Injector Rifle"
	venom_injector.desc = "Precision rifle that injects stacking neurotoxins."
	venom_injector.tier = RCE_RESEARCH_TIER_2
	venom_injector.cost = 120
	venom_injector.branch = "venom"
	venom_injector.prerequisites = list("acid_tank")
	venom_injector.unlocked_path = /obj/item/venom_spike_launcher
	venom_injector.favored_traits = list(
		TRAIT_PRECISION = TRAIT_BONUS_MAJOR,
		TRAIT_TOXIC = TRAIT_BONUS_MODERATE,
		TRAIT_NEURAL = TRAIT_BONUS_MINOR
	)
	venom_injector.negative_traits = list(
		TRAIT_BRUTAL = TRAIT_PENALTY_MODERATE,
		TRAIT_HEAVY = TRAIT_PENALTY_MINOR
	)
	venom_injector.required_traits = list(TRAIT_PRECISION, TRAIT_TOXIC)
	GLOB.rce_research_nodes[venom_injector.id] = venom_injector

	// Tier 3 - Elite Toxic
	var/datum/rce_research_node/toxic_bombarder = new
	toxic_bombarder.id = "toxic_bombarder"
	toxic_bombarder.name = "Toxic Bombardment System"
	toxic_bombarder.desc = "Heavy artillery that rains acid over large areas."
	toxic_bombarder.tier = RCE_RESEARCH_TIER_3
	toxic_bombarder.cost = 280
	toxic_bombarder.branch = "venom"
	toxic_bombarder.prerequisites = list("venom_launcher", "decay_cloud")
	toxic_bombarder.unlocked_path = /obj/item/ego_weapon/ranged/toxic_bombarder
	toxic_bombarder.favored_traits = list(
		TRAIT_ELITE = TRAIT_BONUS_MAJOR,
		TRAIT_TOXIC = TRAIT_BONUS_MAJOR,
		TRAIT_WEAPONIZED = TRAIT_BONUS_MODERATE,
		TRAIT_HEAVY = TRAIT_BONUS_MINOR
	)
	toxic_bombarder.negative_traits = list(
		TRAIT_FODDER = TRAIT_PENALTY_MAJOR,
		TRAIT_LIGHTWEIGHT = TRAIT_PENALTY_MODERATE,
		TRAIT_AGILE = TRAIT_PENALTY_MINOR
	)
	toxic_bombarder.required_traits = list(TRAIT_ELITE, TRAIT_TOXIC, TRAIT_WEAPONIZED)
	GLOB.rce_research_nodes[toxic_bombarder.id] = toxic_bombarder

	var/datum/rce_research_node/plague_scythe = new
	plague_scythe.id = "plague_scythe"
	plague_scythe.name = "Plague Scythe"
	plague_scythe.desc = "Melee weapon that spreads decay with every swing."
	plague_scythe.tier = RCE_RESEARCH_TIER_3
	plague_scythe.cost = 240
	plague_scythe.branch = "venom"
	plague_scythe.prerequisites = list("acid_tank", "venom_injector")
	plague_scythe.unlocked_path = /obj/item/ego_weapon/plague_scythe
	plague_scythe.favored_traits = list(
		TRAIT_BRUTAL = TRAIT_BONUS_MAJOR,
		TRAIT_TOXIC = TRAIT_BONUS_MAJOR,
		TRAIT_CORRUPTED = TRAIT_BONUS_MODERATE,
		TRAIT_ORGANIC = TRAIT_BONUS_MINOR
	)
	plague_scythe.negative_traits = list(
		TRAIT_PRECISION = TRAIT_PENALTY_MODERATE,
		TRAIT_MECHANICAL = TRAIT_PENALTY_MINOR
	)
	plague_scythe.required_traits = list(TRAIT_BRUTAL, TRAIT_TOXIC, TRAIT_ORGANIC)
	GLOB.rce_research_nodes[plague_scythe.id] = plague_scythe

	var/datum/rce_research_node/miasma_field = new
	miasma_field.id = "miasma_field"
	miasma_field.name = "Miasma Field Generator"
	miasma_field.desc = "Creates a massive toxic field that drains life from everything within."
	miasma_field.tier = RCE_RESEARCH_TIER_3
	miasma_field.cost = 260
	miasma_field.branch = "venom"
	miasma_field.prerequisites = list("decay_cloud", "venom_injector")
	miasma_field.unlocked_path = /obj/item/miasma_field_generator
	miasma_field.favored_traits = list(
		TRAIT_TOXIC = TRAIT_BONUS_MAJOR,
		TRAIT_CORRUPTED = TRAIT_BONUS_MAJOR,
		TRAIT_NEURAL = TRAIT_BONUS_MODERATE,
		TRAIT_ADAPTIVE = TRAIT_BONUS_MINOR
	)
	miasma_field.negative_traits = list(
		TRAIT_FODDER = TRAIT_PENALTY_MODERATE,
		TRAIT_RCE_PRIMITIVE = TRAIT_PENALTY_MODERATE,
		TRAIT_LIGHTWEIGHT = TRAIT_PENALTY_MINOR
	)
	miasma_field.required_traits = list(TRAIT_TOXIC, TRAIT_CORRUPTED, TRAIT_NEURAL)
	GLOB.rce_research_nodes[miasma_field.id] = miasma_field

	// STORM RAMS - ELECTRIC WEAPONS TREE

	// Tier 1 - Basic Electric
	var/datum/rce_research_node/capacitor_pack = new
	capacitor_pack.id = "capacitor_pack"
	capacitor_pack.name = "Capacitor Pack Production"
	capacitor_pack.desc = "Unlocks manufacturing of capacitor packs for electric weapons."
	capacitor_pack.tier = 0
	capacitor_pack.cost = 40
	capacitor_pack.branch = "storm"
	capacitor_pack.prerequisites = list()
	capacitor_pack.unlocked_path = /obj/item/portable_factory/capacitor_pack
	capacitor_pack.favored_traits = list(
		TRAIT_ENERGIZED = TRAIT_BONUS_MAJOR,
		TRAIT_MECHANICAL = TRAIT_BONUS_MODERATE,
		TRAIT_EFFICIENT = TRAIT_BONUS_MINOR
	)
	capacitor_pack.negative_traits = list(
		TRAIT_ORGANIC = TRAIT_PENALTY_MINOR,
		TRAIT_CORRUPTED = TRAIT_PENALTY_MODERATE
	)
	GLOB.rce_research_nodes[capacitor_pack.id] = capacitor_pack

	var/datum/rce_research_node/shock_baton = new
	shock_baton.id = "thunder_gauntlets"
	shock_baton.name = "Thunder Gauntlets"
	shock_baton.desc = "Electrified gauntlets for devastating punches with dash attacks."
	shock_baton.tier = RCE_RESEARCH_TIER_1
	shock_baton.cost = 45
	shock_baton.branch = "storm"
	shock_baton.prerequisites = list("capacitor_pack")
	shock_baton.unlocked_path = /obj/item/ego_weapon/thunder_gauntlets
	shock_baton.favored_traits = list(
		TRAIT_ENERGIZED = TRAIT_BONUS_MODERATE,
		TRAIT_BRUTAL = TRAIT_BONUS_MODERATE,
		TRAIT_AGILE = TRAIT_BONUS_MINOR
	)
	shock_baton.negative_traits = list(
		TRAIT_HEAVY = TRAIT_PENALTY_MINOR,
		TRAIT_SLUGGISH = TRAIT_PENALTY_MODERATE
	)
	GLOB.rce_research_nodes[shock_baton.id] = shock_baton

	var/datum/rce_research_node/arc_rifle = new
	arc_rifle.id = "storm_dash"
	arc_rifle.name = "Storm Dash Module"
	arc_rifle.desc = "Rush through enemies dealing chain lightning damage."
	arc_rifle.tier = RCE_RESEARCH_TIER_1
	arc_rifle.cost = 55
	arc_rifle.branch = "storm"
	arc_rifle.prerequisites = list("capacitor_pack")
	arc_rifle.unlocked_path = /obj/item/storm_dash
	arc_rifle.favored_traits = list(
		TRAIT_ENERGIZED = TRAIT_BONUS_MODERATE,
		TRAIT_AGILE = TRAIT_BONUS_MAJOR,
		TRAIT_LIGHTWEIGHT = TRAIT_BONUS_MINOR
	)
	arc_rifle.negative_traits = list(
		TRAIT_HEAVY = TRAIT_PENALTY_MAJOR,
		TRAIT_SLUGGISH = TRAIT_PENALTY_MODERATE
	)
	GLOB.rce_research_nodes[arc_rifle.id] = arc_rifle

	var/datum/rce_research_node/static_field = new
	static_field.id = "static_burst"
	static_field.name = "Static Burst Generator"
	static_field.desc = "Deploy fields that explode when you pass through them."
	static_field.tier = RCE_RESEARCH_TIER_1
	static_field.cost = 50
	static_field.branch = "storm"
	static_field.prerequisites = list("capacitor_pack")
	static_field.unlocked_path = /obj/item/static_burst_generator
	static_field.favored_traits = list(
		TRAIT_ENERGIZED = TRAIT_BONUS_MODERATE,
		TRAIT_ADAPTIVE = TRAIT_BONUS_MODERATE,
		TRAIT_MECHANICAL = TRAIT_BONUS_MINOR
	)
	static_field.negative_traits = list(
		TRAIT_RCE_PRIMITIVE = TRAIT_PENALTY_MODERATE,
		TRAIT_ORGANIC = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[static_field.id] = static_field

	var/datum/rce_research_node/emp_grenade = new
	emp_grenade.id = "emp_grenade"
	emp_grenade.name = "EMP Grenade Production"
	emp_grenade.desc = "Grenades that disable machinery and stun organics."
	emp_grenade.tier = RCE_RESEARCH_TIER_1
	emp_grenade.cost = 50
	emp_grenade.branch = "storm"
	emp_grenade.prerequisites = list("capacitor_pack")
	emp_grenade.unlocked_path = /obj/item/portable_factory/emp_grenade
	emp_grenade.favored_traits = list(
		TRAIT_ENERGIZED = TRAIT_BONUS_MODERATE,
		TRAIT_VOLATILE = TRAIT_BONUS_MINOR,
		TRAIT_MECHANICAL = TRAIT_BONUS_MINOR
	)
	emp_grenade.negative_traits = list(
		TRAIT_ARMORED = TRAIT_PENALTY_MINOR,
		TRAIT_ORGANIC = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[emp_grenade.id] = emp_grenade

	// Tier 2 - Advanced Electric
	var/datum/rce_research_node/tesla_cannon = new
	tesla_cannon.id = "lightning_ram"
	tesla_cannon.name = "Lightning Ram"
	tesla_cannon.desc = "Devastating charge attack that smashes through walls."
	tesla_cannon.tier = RCE_RESEARCH_TIER_2
	tesla_cannon.cost = 150
	tesla_cannon.branch = "storm"
	tesla_cannon.prerequisites = list("capacitor_pack", "storm_dash")
	tesla_cannon.unlocked_path = /obj/item/ego_weapon/lightning_ram
	tesla_cannon.favored_traits = list(
		TRAIT_ENERGIZED = TRAIT_BONUS_MAJOR,
		TRAIT_BRUTAL = TRAIT_BONUS_MAJOR,
		TRAIT_HEAVY = TRAIT_BONUS_MINOR
	)
	tesla_cannon.negative_traits = list(
		TRAIT_LIGHTWEIGHT = TRAIT_PENALTY_MODERATE,
		TRAIT_FODDER = TRAIT_PENALTY_MINOR
	)
	tesla_cannon.required_traits = list(TRAIT_ENERGIZED, TRAIT_BRUTAL)
	GLOB.rce_research_nodes[tesla_cannon.id] = tesla_cannon

	var/datum/rce_research_node/dash_charger = new
	dash_charger.id = "thunderclap_gauntlets"
	dash_charger.name = "Thunderclap Gauntlets"
	dash_charger.desc = "AoE burst attack with built-in auto-retreat."
	dash_charger.tier = RCE_RESEARCH_TIER_2
	dash_charger.cost = 130
	dash_charger.branch = "storm"
	dash_charger.prerequisites = list("thunder_gauntlets", "capacitor_pack")
	dash_charger.unlocked_path = /obj/item/ego_weapon/thunderclap_gauntlets
	dash_charger.favored_traits = list(
		TRAIT_AGILE = TRAIT_BONUS_MAJOR,
		TRAIT_ENERGIZED = TRAIT_BONUS_MODERATE,
		TRAIT_VOLATILE = TRAIT_BONUS_MODERATE
	)
	dash_charger.negative_traits = list(
		TRAIT_SLUGGISH = TRAIT_PENALTY_MAJOR,
		TRAIT_HEAVY = TRAIT_PENALTY_MODERATE
	)
	dash_charger.required_traits = list(TRAIT_AGILE, TRAIT_ENERGIZED)
	GLOB.rce_research_nodes[dash_charger.id] = dash_charger

	var/datum/rce_research_node/storm_barrier = new
	storm_barrier.id = "storm_surge"
	storm_barrier.name = "Storm Surge Barrier"
	storm_barrier.desc = "Mobile electromagnetic shield that damages enemies on contact."
	storm_barrier.tier = RCE_RESEARCH_TIER_2
	storm_barrier.cost = 140
	storm_barrier.branch = "storm"
	storm_barrier.prerequisites = list("static_burst", "capacitor_pack")
	storm_barrier.unlocked_path = /obj/item/storm_surge_barrier
	storm_barrier.favored_traits = list(
		TRAIT_ENERGIZED = TRAIT_BONUS_MAJOR,
		TRAIT_AGILE = TRAIT_BONUS_MODERATE,
		TRAIT_ADAPTIVE = TRAIT_BONUS_MODERATE
	)
	storm_barrier.negative_traits = list(
		TRAIT_HEAVY = TRAIT_PENALTY_MODERATE,
		TRAIT_SLUGGISH = TRAIT_PENALTY_MAJOR
	)
	storm_barrier.required_traits = list(TRAIT_ENERGIZED, TRAIT_AGILE)
	GLOB.rce_research_nodes[storm_barrier.id] = storm_barrier

	// Tier 3 - Elite Electric
	var/datum/rce_research_node/railgun_lance = new
	railgun_lance.id = "railgun_charge"
	railgun_lance.name = "Railgun Charge Module"
	railgun_lance.desc = "Transform into a living railgun projectile - ultimate rush attack."
	railgun_lance.tier = RCE_RESEARCH_TIER_3
	railgun_lance.cost = 250
	railgun_lance.branch = "storm"
	railgun_lance.prerequisites = list("thunderclap_gauntlets", "lightning_ram")
	railgun_lance.unlocked_path = /obj/item/ego_weapon/railgun_charge
	railgun_lance.favored_traits = list(
		TRAIT_ELITE = TRAIT_BONUS_MAJOR,
		TRAIT_ENERGIZED = TRAIT_BONUS_MAJOR,
		TRAIT_BRUTAL = TRAIT_BONUS_MAJOR,
		TRAIT_BERSERKER = TRAIT_BONUS_MODERATE
	)
	railgun_lance.negative_traits = list(
		TRAIT_FODDER = TRAIT_PENALTY_MAJOR,
		TRAIT_LIGHTWEIGHT = TRAIT_PENALTY_MODERATE,
		TRAIT_ERRATIC = TRAIT_PENALTY_MINOR
	)
	railgun_lance.required_traits = list(TRAIT_ELITE, TRAIT_ENERGIZED, TRAIT_BRUTAL)
	GLOB.rce_research_nodes[railgun_lance.id] = railgun_lance

	var/datum/rce_research_node/thunderstorm_artillery = new
	thunderstorm_artillery.id = "thunderstorm_slam"
	thunderstorm_artillery.name = "Thunderstorm Slam Module"
	thunderstorm_artillery.desc = "Leap and ground slam to create a lingering electric storm."
	thunderstorm_artillery.tier = RCE_RESEARCH_TIER_3
	thunderstorm_artillery.cost = 280
	thunderstorm_artillery.branch = "storm"
	thunderstorm_artillery.prerequisites = list("lightning_ram", "emp_grenade")
	thunderstorm_artillery.unlocked_path = /obj/item/thunderstorm_slam
	thunderstorm_artillery.favored_traits = list(
		TRAIT_ELITE = TRAIT_BONUS_MAJOR,
		TRAIT_ENERGIZED = TRAIT_BONUS_MAJOR,
		TRAIT_VOLATILE = TRAIT_BONUS_MAJOR,
		TRAIT_HEAVY = TRAIT_BONUS_MINOR
	)
	thunderstorm_artillery.negative_traits = list(
		TRAIT_FODDER = TRAIT_PENALTY_MAJOR,
		TRAIT_RCE_PRIMITIVE = TRAIT_PENALTY_MODERATE,
		TRAIT_LIGHTWEIGHT = TRAIT_PENALTY_MINOR
	)
	thunderstorm_artillery.required_traits = list(TRAIT_ELITE, TRAIT_ENERGIZED, TRAIT_VOLATILE)
	GLOB.rce_research_nodes[thunderstorm_artillery.id] = thunderstorm_artillery

	// Debug: Log all initialized nodes
	world.log << "RCE Research Tree initialized with the following nodes:"
	for(var/node_id in GLOB.rce_research_nodes)
		var/datum/rce_research_node/node = GLOB.rce_research_nodes[node_id]
		world.log << "  - [node.id]: [node.name] (Tier [node.tier], Cost: [node.cost])"

// Portable factory definitions for research unlocks
/obj/item/portable_factory/pyro_grenade
	name = "pyro grenade factory module"
	desc = "Deploys a factory that produces R-Corp pyro grenades."
	factory_path = /obj/structure/rcorp_factory/pyro_grenade

/obj/structure/rcorp_factory/pyro_grenade
	name = "pyro grenade factory"
	desc = "Produces R-Corp pyro grenades using red and green materials."
	item = /obj/item/grenade/r_corp/pyro
	rcost = 1
	gcost = 1

/obj/item/portable_factory/fuel_tank
	name = "fuel tank factory module"
	desc = "Deploys a factory that produces heavy fuel tank backpacks."
	factory_path = /obj/structure/rcorp_factory/fuel_tank

/obj/structure/rcorp_factory/fuel_tank
	name = "fuel tank factory"
	desc = "Produces heavy fuel tank backpacks using green materials."
	item = /obj/item/fuel_tank_backpack
	gcost = 2

/obj/item/portable_factory/hellfire_armor
	name = "hellfire armor factory module"
	desc = "Deploys a factory that produces hellfire protection suits."
	factory_path = /obj/structure/rcorp_factory/hellfire_armor

/obj/structure/rcorp_factory/hellfire_armor
	name = "hellfire armor factory"
	desc = "Produces complete hellfire protection suits."
	item = /obj/item/storage/box/hellfire_set
	rcost = 2
	gcost = 2

// Box containing hellfire armor set
/obj/item/storage/box/hellfire_set
	name = "hellfire protection kit"
	desc = "Contains a complete hellfire protection suit."

/obj/item/storage/box/hellfire_set/PopulateContents()
	new /obj/item/clothing/suit/armor/ego_gear/hellfire(src)
	new /obj/item/clothing/head/ego_hat/helmet/hellfire(src)

// Automatic flamethrower factory
/obj/item/portable_factory/auto_flamethrower
	name = "automatic flamethrower factory module"
	desc = "Deploys a factory that produces automatic defense flamethrowers."
	factory_path = /obj/structure/rcorp_factory/auto_flamethrower

/obj/structure/rcorp_factory/auto_flamethrower
	name = "automatic flamethrower factory"
	desc = "Produces automatic defense flamethrower systems."
	item = /obj/item/auto_flamethrower
	rcost = 3
	gcost = 2

// TOXIC WEAPON FACTORIES

/obj/item/portable_factory/acid_tank
	name = "acid tank factory module"
	desc = "Deploys a factory that produces acid tank backpacks."
	factory_path = /obj/structure/rcorp_factory/acid_tank

/obj/structure/rcorp_factory/acid_tank
	name = "acid tank factory"
	desc = "Produces heavy acid tank backpacks using green materials."
	item = /obj/item/acid_tank_backpack
	gcost = 2

/obj/item/portable_factory/toxic_mines
	name = "toxic mine factory module"
	desc = "Deploys a factory that produces toxic proximity mines."
	factory_path = /obj/structure/rcorp_factory/toxic_mines

/obj/structure/rcorp_factory/toxic_mines
	name = "toxic mine factory"
	desc = "Produces toxic proximity mines."
	item = /obj/item/toxic_mine
	rcost = 1
	gcost = 1

/obj/item/portable_factory/acid_grenade
	name = "acid grenade factory module"
	desc = "Deploys a factory that produces corrosive grenades."
	factory_path = /obj/structure/rcorp_factory/acid_grenade

/obj/structure/rcorp_factory/acid_grenade
	name = "acid grenade factory"
	desc = "Produces R-Corp corrosive grenades."
	item = /obj/item/venom_trap_dispenser
	rcost = 1
	gcost = 1

// ELECTRIC WEAPON FACTORIES

/obj/item/portable_factory/capacitor_pack
	name = "capacitor pack factory module"
	desc = "Deploys a factory that produces capacitor packs."
	factory_path = /obj/structure/rcorp_factory/capacitor_pack

/obj/structure/rcorp_factory/capacitor_pack
	name = "capacitor pack factory"
	desc = "Produces heavy capacitor packs using green materials."
	item = /obj/item/capacitor_pack
	gcost = 2

/obj/item/portable_factory/emp_grenade
	name = "EMP grenade factory module"
	desc = "Deploys a factory that produces EMP grenades."
	factory_path = /obj/structure/rcorp_factory/emp_grenade

/obj/structure/rcorp_factory/emp_grenade
	name = "EMP grenade factory"
	desc = "Produces R-Corp EMP grenades."
	item = /obj/item/grenade/r_corp/emp
	rcost = 1
	gcost = 1
