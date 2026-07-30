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
	var/is_starter_kit = FALSE // Whether this is a starter kit (cost doubles each time)

/proc/initialize_research_tree()
	GLOB.rce_research_nodes = list()

	// Tier 1 - Basic Pyro
	var/datum/rce_research_node/pyro_grenade = new
	pyro_grenade.id = "pyro_grenade"
	pyro_grenade.name = "Pyro Grenade Manufacturing"
	pyro_grenade.desc = "Produces a portable factory that manufactures R-Corp pyro grenades that create fire zones."
	pyro_grenade.tier = RCE_RESEARCH_TIER_1
	pyro_grenade.cost = 38
	pyro_grenade.branch = "hellfire"
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
	fuel_tank.name = "Hellfire Rooster Starter Kit"
	fuel_tank.desc = "Unlocks production of fuel tank backpack, Hellfire combat implant, and protective armor. Perfect starting kit for pyro specialists."
	fuel_tank.tier = 0
	fuel_tank.cost = 150
	fuel_tank.is_starter_kit = TRUE
	fuel_tank.branch = "hellfire"
	fuel_tank.prerequisites = list()
	fuel_tank.unlocked_path = /obj/item/storage/box/fuel_tank_starter_kit
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

	// Tier 1 - Support Equipment
	var/datum/rce_research_node/fuel_canister = new
	fuel_canister.id = "fuel_canister"
	fuel_canister.name = "Portable Fuel Canister"
	fuel_canister.desc = "A portable fuel canister used by Ravens to refuel Hellfire specialists in the field."
	fuel_canister.tier = RCE_RESEARCH_TIER_1
	fuel_canister.cost = 75
	fuel_canister.branch = "hellfire"
	fuel_canister.prerequisites = list("fuel_tank")
	fuel_canister.unlocked_path = /obj/item/rce_canister/fuel
	fuel_canister.favored_traits = list(
		TRAIT_EFFICIENT = TRAIT_BONUS_MODERATE,
		TRAIT_MECHANICAL = TRAIT_BONUS_MINOR
	)
	fuel_canister.negative_traits = list(
		TRAIT_VOLATILE = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[fuel_canister.id] = fuel_canister

	// Tier 2 - Heavy Armor
	var/datum/rce_research_node/heavy_hellfire_armor = new
	heavy_hellfire_armor.id = "heavy_hellfire_armor"
	heavy_hellfire_armor.name = "Heavy Hellfire Armor"
	heavy_hellfire_armor.desc = "Reinforced armor for veteran hellfire units. Offers +20 to all non-100 resistances."
	heavy_hellfire_armor.tier = RCE_RESEARCH_TIER_2
	heavy_hellfire_armor.cost = 300
	heavy_hellfire_armor.branch = "hellfire"
	heavy_hellfire_armor.prerequisites = list("fuel_tank")
	heavy_hellfire_armor.unlocked_path = /obj/item/clothing/suit/armor/ego_gear/hellfire/heavy
	heavy_hellfire_armor.favored_traits = list(
		TRAIT_VOLATILE = TRAIT_BONUS_MAJOR,
		TRAIT_ARMORED = TRAIT_BONUS_MAJOR,
		TRAIT_HEAVY = TRAIT_BONUS_MODERATE,
		TRAIT_ELITE = TRAIT_BONUS_MODERATE
	)
	heavy_hellfire_armor.negative_traits = list(
		TRAIT_LIGHTWEIGHT = TRAIT_PENALTY_MODERATE,
		TRAIT_FODDER = TRAIT_PENALTY_MINOR
	)
	heavy_hellfire_armor.required_traits = list(TRAIT_VOLATILE, TRAIT_ARMORED, TRAIT_HEAVY)
	GLOB.rce_research_nodes[heavy_hellfire_armor.id] = heavy_hellfire_armor

	// Tier 2 - Advanced Pyro
	var/datum/rce_research_node/auto_flamethrower = new
	auto_flamethrower.id = "auto_flamethrower"
	auto_flamethrower.name = "Automatic Defense Acid Sprayer"
	auto_flamethrower.desc = "Automated acid sprayer system that detects and engages hostile targets automatically with corrosive projectiles."
	auto_flamethrower.tier = RCE_RESEARCH_TIER_2
	auto_flamethrower.cost = 420
	auto_flamethrower.branch = "venom"
	auto_flamethrower.prerequisites = list("acid_tank")
	auto_flamethrower.unlocked_path = /obj/item/auto_acid_sprayer
	auto_flamethrower.favored_traits = list(
		TRAIT_TOXIC = TRAIT_BONUS_MAJOR,
		TRAIT_MECHANICAL = TRAIT_BONUS_MAJOR,
		TRAIT_NEURAL = TRAIT_BONUS_MODERATE,
		TRAIT_ADAPTIVE = TRAIT_BONUS_MODERATE
	)
	auto_flamethrower.negative_traits = list(
		TRAIT_ERRATIC = TRAIT_PENALTY_MAJOR,
		TRAIT_RCE_PRIMITIVE = TRAIT_PENALTY_MODERATE,
		TRAIT_FODDER = TRAIT_PENALTY_MINOR
	)
	auto_flamethrower.required_traits = list(TRAIT_TOXIC, TRAIT_MECHANICAL, TRAIT_NEURAL)
	GLOB.rce_research_nodes[auto_flamethrower.id] = auto_flamethrower

	// VENOM RATTLESNAKES - TOXIC WEAPONS TREE

	// Tier 1 - Basic Toxic
	var/datum/rce_research_node/acid_tank = new
	acid_tank.id = "acid_tank"
	acid_tank.name = "Venom Rattlesnake Starter Kit"
	acid_tank.desc = "Unlocks production of acid tank backpack, Venom combat implant, and protective armor. Perfect starting kit for toxic specialists."
	acid_tank.tier = 0
	acid_tank.cost = 150
	acid_tank.is_starter_kit = TRUE
	acid_tank.branch = "venom"
	acid_tank.prerequisites = list()
	acid_tank.unlocked_path = /obj/item/storage/box/acid_tank_starter_kit
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

	var/datum/rce_research_node/acid_canister = new
	acid_canister.id = "acid_canister"
	acid_canister.name = "Portable Acid Canister"
	acid_canister.desc = "A portable acid canister used by Ravens to refuel Venom Rattlesnake specialists in the field."
	acid_canister.tier = RCE_RESEARCH_TIER_1
	acid_canister.cost = 75
	acid_canister.branch = "venom"
	acid_canister.prerequisites = list("acid_tank")
	acid_canister.unlocked_path = /obj/item/rce_canister/acid
	acid_canister.favored_traits = list(
		TRAIT_EFFICIENT = TRAIT_BONUS_MODERATE,
		TRAIT_TOXIC = TRAIT_BONUS_MINOR
	)
	acid_canister.negative_traits = list(
		TRAIT_VOLATILE = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[acid_canister.id] = acid_canister

	var/datum/rce_research_node/acid_grenade = new
	acid_grenade.id = "acid_grenade"
	acid_grenade.name = "Acid Grenade Manufacturing"
	acid_grenade.desc = "Produces a portable factory that manufactures acid grenades that create toxic puddles."
	acid_grenade.tier = RCE_RESEARCH_TIER_1
	acid_grenade.cost = 40
	acid_grenade.branch = "venom"
	acid_grenade.prerequisites = list("acid_tank")
	acid_grenade.unlocked_path = /obj/item/portable_factory/acid_grenade
	acid_grenade.favored_traits = list(
		TRAIT_TOXIC = TRAIT_BONUS_MAJOR,
		TRAIT_VOLATILE = TRAIT_BONUS_MODERATE,
		TRAIT_WEAPONIZED = TRAIT_BONUS_MINOR
	)
	acid_grenade.negative_traits = list(
		TRAIT_PRECISION = TRAIT_PENALTY_MINOR,
		TRAIT_ARMORED = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[acid_grenade.id] = acid_grenade

	var/datum/rce_research_node/toxic_mine = new
	toxic_mine.id = "toxic_mine"
	toxic_mine.name = "Toxic Mine Manufacturing"
	toxic_mine.desc = "Produces proximity-triggered mines that spray corrosive acid when enemies approach."
	toxic_mine.tier = RCE_RESEARCH_TIER_1
	toxic_mine.cost = 36
	toxic_mine.branch = "venom"
	toxic_mine.prerequisites = list("acid_tank")
	toxic_mine.unlocked_path = /obj/item/portable_factory/toxic_mine
	toxic_mine.favored_traits = list(
		TRAIT_TOXIC = TRAIT_BONUS_MAJOR,
		TRAIT_MECHANICAL = TRAIT_BONUS_MODERATE,
		TRAIT_PRECISION = TRAIT_BONUS_MINOR
	)
	toxic_mine.negative_traits = list(
		TRAIT_ERRATIC = TRAIT_PENALTY_MAJOR,
		TRAIT_RCE_PRIMITIVE = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[toxic_mine.id] = toxic_mine

	var/datum/rce_research_node/venom_launcher = new
	venom_launcher.id = "venom_launcher"
	venom_launcher.name = "Venom Launcher"
	venom_launcher.desc = "A ranged launcher that fires toxic shells dealing massive bonus damage to venom-marked targets."
	venom_launcher.tier = RCE_RESEARCH_TIER_1
	venom_launcher.cost = 250
	venom_launcher.branch = "venom"
	venom_launcher.prerequisites = list("acid_tank")
	venom_launcher.unlocked_path = /obj/item/ego_weapon/ranged/venom_launcher
	venom_launcher.favored_traits = list(
		TRAIT_TOXIC = TRAIT_BONUS_MAJOR,
		TRAIT_WEAPONIZED = TRAIT_BONUS_MODERATE,
		TRAIT_ORGANIC = TRAIT_BONUS_MINOR
	)
	venom_launcher.negative_traits = list(
		TRAIT_MECHANICAL = TRAIT_PENALTY_MINOR,
		TRAIT_PRECISION = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[venom_launcher.id] = venom_launcher

	var/datum/rce_research_node/heavy_venom_armor = new
	heavy_venom_armor.id = "heavy_venom_armor"
	heavy_venom_armor.name = "Heavy Venom Armor"
	heavy_venom_armor.desc = "Reinforced armor for veteran venom units. Offers +20 to all non-100 resistances."
	heavy_venom_armor.tier = RCE_RESEARCH_TIER_2
	heavy_venom_armor.cost = 300
	heavy_venom_armor.branch = "venom"
	heavy_venom_armor.prerequisites = list("acid_tank")
	heavy_venom_armor.unlocked_path = /obj/item/clothing/suit/armor/ego_gear/venom/heavy
	heavy_venom_armor.favored_traits = list(
		TRAIT_TOXIC = TRAIT_BONUS_MAJOR,
		TRAIT_ARMORED = TRAIT_BONUS_MAJOR,
		TRAIT_HEAVY = TRAIT_BONUS_MODERATE,
		TRAIT_ELITE = TRAIT_BONUS_MODERATE
	)
	heavy_venom_armor.negative_traits = list(
		TRAIT_LIGHTWEIGHT = TRAIT_PENALTY_MODERATE,
		TRAIT_FODDER = TRAIT_PENALTY_MINOR
	)
	heavy_venom_armor.required_traits = list(TRAIT_TOXIC, TRAIT_ARMORED, TRAIT_HEAVY)
	GLOB.rce_research_nodes[heavy_venom_armor.id] = heavy_venom_armor

	var/datum/rce_research_node/incendiary_mines = new
	incendiary_mines.id = "incendiary_mines"
	incendiary_mines.name = "Incendiary Mine Manufacturing"
	incendiary_mines.desc = "Produces a portable factory that manufactures proximity mines that create fire zones."
	incendiary_mines.tier = RCE_RESEARCH_TIER_1
	incendiary_mines.cost = 34
	incendiary_mines.branch = "hellfire"
	incendiary_mines.prerequisites = list("fuel_tank")
	incendiary_mines.unlocked_path = /obj/item/portable_factory/incendiary_mines
	incendiary_mines.favored_traits = list(
		TRAIT_MECHANICAL = TRAIT_BONUS_MODERATE,
		TRAIT_VOLATILE = TRAIT_BONUS_MODERATE,
		TRAIT_PRECISION = TRAIT_BONUS_MINOR
	)
	incendiary_mines.negative_traits = list(
		TRAIT_ERRATIC = TRAIT_PENALTY_MAJOR,
		TRAIT_FODDER = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[incendiary_mines.id] = incendiary_mines

	var/datum/rce_research_node/fire_trap = new
	fire_trap.id = "fire_trap"
	fire_trap.name = "Fire Trap Dispenser"
	fire_trap.desc = "Produces a device that deploys concealed incendiary traps."
	fire_trap.tier = RCE_RESEARCH_TIER_1
	fire_trap.cost = 41
	fire_trap.branch = "hellfire"
	fire_trap.prerequisites = list("fuel_tank")
	fire_trap.unlocked_path = /obj/item/fire_trap_dispenser
	fire_trap.favored_traits = list(
		TRAIT_VOLATILE = TRAIT_BONUS_MODERATE,
		TRAIT_MECHANICAL = TRAIT_BONUS_MODERATE,
		TRAIT_WEAPONIZED = TRAIT_BONUS_MINOR
	)
	fire_trap.negative_traits = list(
		TRAIT_ARMORED = TRAIT_PENALTY_MINOR,
		TRAIT_ORGANIC = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[fire_trap.id] = fire_trap

	// Tier 2 - Advanced Hellfire
	var/datum/rce_research_node/inferno_cloud = new
	inferno_cloud.id = "inferno_cloud"
	inferno_cloud.name = "Inferno Cloud Generator"
	inferno_cloud.desc = "Creates massive moving firestorms that incinerate everything."
	inferno_cloud.tier = RCE_RESEARCH_TIER_2
	inferno_cloud.cost = 390
	inferno_cloud.branch = "hellfire"
	inferno_cloud.prerequisites = list("incendiary_mines")
	inferno_cloud.unlocked_path = /obj/item/inferno_cloud_generator
	inferno_cloud.favored_traits = list(
		TRAIT_VOLATILE = TRAIT_BONUS_MAJOR,
		TRAIT_CORRUPTED = TRAIT_BONUS_MAJOR,
		TRAIT_WEAPONIZED = TRAIT_BONUS_MODERATE,
		TRAIT_ORGANIC = TRAIT_BONUS_MODERATE
	)
	inferno_cloud.negative_traits = list(
		TRAIT_PRECISION = TRAIT_PENALTY_MODERATE,
		TRAIT_LIGHTWEIGHT = TRAIT_PENALTY_MINOR
	)
	inferno_cloud.required_traits = list(TRAIT_VOLATILE, TRAIT_CORRUPTED, TRAIT_ORGANIC)
	GLOB.rce_research_nodes[inferno_cloud.id] = inferno_cloud

	var/datum/rce_research_node/thermite_spikes = new
	thermite_spikes.id = "thermite_spikes"
	thermite_spikes.name = "Thermite Spike Deployer"
	thermite_spikes.desc = "Deploys spike strips coated in thermite that ignite enemies."
	thermite_spikes.tier = RCE_RESEARCH_TIER_2
	thermite_spikes.cost = 360
	thermite_spikes.branch = "hellfire"
	thermite_spikes.prerequisites = list("fuel_tank")
	thermite_spikes.unlocked_path = /obj/item/thermite_spike_launcher
	thermite_spikes.favored_traits = list(
		TRAIT_VOLATILE = TRAIT_BONUS_MAJOR,
		TRAIT_PRECISION = TRAIT_BONUS_MAJOR,
		TRAIT_MECHANICAL = TRAIT_BONUS_MODERATE,
		TRAIT_WEAPONIZED = TRAIT_BONUS_MODERATE
	)
	thermite_spikes.negative_traits = list(
		TRAIT_BRUTAL = TRAIT_PENALTY_MODERATE,
		TRAIT_HEAVY = TRAIT_PENALTY_MINOR
	)
	thermite_spikes.required_traits = list(TRAIT_VOLATILE, TRAIT_PRECISION, TRAIT_MECHANICAL)
	GLOB.rce_research_nodes[thermite_spikes.id] = thermite_spikes

	var/datum/rce_research_node/blight_sprayer = new
	blight_sprayer.id = "blight_sprayer"
	blight_sprayer.name = "Blight Sprayer"
	blight_sprayer.desc = "Sprays volatile toxic sludge that explodes after a delay into toxic clouds."
	blight_sprayer.tier = RCE_RESEARCH_TIER_2
	blight_sprayer.cost = 360
	blight_sprayer.branch = "venom"
	blight_sprayer.prerequisites = list("acid_grenade")
	blight_sprayer.unlocked_path = /obj/item/ego_weapon/blight_sprayer
	blight_sprayer.favored_traits = list(
		TRAIT_TOXIC = TRAIT_BONUS_MAJOR,
		TRAIT_VOLATILE = TRAIT_BONUS_MAJOR,
		TRAIT_ORGANIC = TRAIT_BONUS_MODERATE,
		TRAIT_EXPERIMENTAL = TRAIT_BONUS_MODERATE
	)
	blight_sprayer.negative_traits = list(
		TRAIT_ARMORED = TRAIT_PENALTY_MODERATE,
		TRAIT_HEAVY = TRAIT_PENALTY_MINOR
	)
	blight_sprayer.required_traits = list(TRAIT_TOXIC, TRAIT_VOLATILE, TRAIT_ORGANIC)
	GLOB.rce_research_nodes[blight_sprayer.id] = blight_sprayer

	var/datum/rce_research_node/miasma_barrier = new
	miasma_barrier.id = "miasma_barrier"
	miasma_barrier.name = "Miasma Barrier Projector"
	miasma_barrier.desc = "Projects a wall of corrosive miasma that poisons enemies who pass through."
	miasma_barrier.tier = RCE_RESEARCH_TIER_3
	miasma_barrier.cost = 600
	miasma_barrier.branch = "venom"
	miasma_barrier.prerequisites = list("blight_sprayer")
	miasma_barrier.unlocked_path = /obj/item/ego_weapon/miasma_barrier
	miasma_barrier.favored_traits = list(
		TRAIT_TOXIC = TRAIT_BONUS_MAJOR,
		TRAIT_ADAPTIVE = TRAIT_BONUS_MAJOR,
		TRAIT_CORRUPTED = TRAIT_BONUS_MODERATE,
		TRAIT_ORGANIC = TRAIT_BONUS_MODERATE
	)
	miasma_barrier.negative_traits = list(
		TRAIT_RCE_PRIMITIVE = TRAIT_PENALTY_MAJOR,
		TRAIT_FODDER = TRAIT_PENALTY_MODERATE
	)
	miasma_barrier.required_traits = list(TRAIT_TOXIC, TRAIT_ADAPTIVE, TRAIT_ORGANIC)
	GLOB.rce_research_nodes[miasma_barrier.id] = miasma_barrier

	var/datum/rce_research_node/corrosive_turret = new
	corrosive_turret.id = "corrosive_turret"
	corrosive_turret.name = "Flame Spray Turret"
	corrosive_turret.desc = "Deployable automatic turret that sprays flames at approaching enemies. Draws enemy aggro when deployed."
	corrosive_turret.tier = RCE_RESEARCH_TIER_2
	corrosive_turret.cost = 400
	corrosive_turret.branch = "hellfire"
	corrosive_turret.prerequisites = list("fuel_tank")
	corrosive_turret.unlocked_path = /obj/item/flame_turret_deployable
	corrosive_turret.favored_traits = list(
		TRAIT_VOLATILE = TRAIT_BONUS_MAJOR,
		TRAIT_MECHANICAL = TRAIT_BONUS_MAJOR,
		TRAIT_ADAPTIVE = TRAIT_BONUS_MODERATE,
		TRAIT_WEAPONIZED = TRAIT_BONUS_MODERATE
	)
	corrosive_turret.negative_traits = list(
		TRAIT_ORGANIC = TRAIT_PENALTY_MODERATE,
		TRAIT_RCE_PRIMITIVE = TRAIT_PENALTY_MODERATE,
		TRAIT_FODDER = TRAIT_PENALTY_MINOR
	)
	corrosive_turret.required_traits = list(TRAIT_VOLATILE, TRAIT_MECHANICAL, TRAIT_ADAPTIVE)
	GLOB.rce_research_nodes[corrosive_turret.id] = corrosive_turret

	// Tier 3 - Elite Toxic
	var/datum/rce_research_node/venom_strike = new
	venom_strike.id = "venom_strike"
	venom_strike.name = "Venom Strike Blade"
	venom_strike.desc = "A blade coated with venom that can channel acid for devastating toxic dashes."
	venom_strike.tier = RCE_RESEARCH_TIER_3
	venom_strike.cost = 750
	venom_strike.branch = "venom"
	venom_strike.prerequisites = list("acid_tank")
	venom_strike.unlocked_path = /obj/item/ego_weapon/venom_strike
	venom_strike.favored_traits = list(
		TRAIT_TOXIC = TRAIT_BONUS_MAJOR,
		TRAIT_AGILE = TRAIT_BONUS_MAJOR,
		TRAIT_WEAPONIZED = TRAIT_BONUS_MAJOR,
		TRAIT_LIGHTWEIGHT = TRAIT_BONUS_MODERATE
	)
	venom_strike.negative_traits = list(
		TRAIT_HEAVY = TRAIT_PENALTY_MAJOR,
		TRAIT_SLUGGISH = TRAIT_PENALTY_MAJOR,
		TRAIT_ARMORED = TRAIT_PENALTY_MINOR
	)
	venom_strike.required_traits = list(TRAIT_TOXIC, TRAIT_AGILE, TRAIT_WEAPONIZED)
	GLOB.rce_research_nodes[venom_strike.id] = venom_strike

	var/datum/rce_research_node/corrosive_gauntlets = new
	corrosive_gauntlets.id = "corrosive_gauntlets"
	corrosive_gauntlets.name = "Corrosive Burst Gauntlets"
	corrosive_gauntlets.desc = "Heavy gauntlets that channel acid into explosive toxic bursts."
	corrosive_gauntlets.tier = RCE_RESEARCH_TIER_2
	corrosive_gauntlets.cost = 380
	corrosive_gauntlets.branch = "venom"
	corrosive_gauntlets.prerequisites = list("acid_tank")
	corrosive_gauntlets.unlocked_path = /obj/item/ego_weapon/corrosive_gauntlets
	corrosive_gauntlets.favored_traits = list(
		TRAIT_TOXIC = TRAIT_BONUS_MAJOR,
		TRAIT_BRUTAL = TRAIT_BONUS_MAJOR,
		TRAIT_VOLATILE = TRAIT_BONUS_MAJOR,
		TRAIT_HEAVY = TRAIT_BONUS_MODERATE
	)
	corrosive_gauntlets.negative_traits = list(
		TRAIT_LIGHTWEIGHT = TRAIT_PENALTY_MODERATE,
		TRAIT_PRECISION = TRAIT_PENALTY_MINOR
	)
	corrosive_gauntlets.required_traits = list(TRAIT_TOXIC, TRAIT_BRUTAL, TRAIT_VOLATILE)
	GLOB.rce_research_nodes[corrosive_gauntlets.id] = corrosive_gauntlets

	var/datum/rce_research_node/plague_mortar = new
	plague_mortar.id = "plague_mortar"
	plague_mortar.name = "Plague Mortar"
	plague_mortar.desc = "Heavy launcher that fires arcing plague shells for toxic area bombardment."
	plague_mortar.tier = RCE_RESEARCH_TIER_3
	plague_mortar.cost = 840
	plague_mortar.branch = "venom"
	plague_mortar.prerequisites = list("miasma_barrier")
	plague_mortar.unlocked_path = /obj/item/ego_weapon/ranged/plague_mortar
	plague_mortar.favored_traits = list(
		TRAIT_TOXIC = TRAIT_BONUS_MAJOR,
		TRAIT_ELITE = TRAIT_BONUS_MAJOR,
		TRAIT_WEAPONIZED = TRAIT_BONUS_MAJOR,
		TRAIT_PRECISION = TRAIT_BONUS_MODERATE
	)
	plague_mortar.negative_traits = list(
		TRAIT_FODDER = TRAIT_PENALTY_MAJOR,
		TRAIT_RCE_PRIMITIVE = TRAIT_PENALTY_MODERATE,
		TRAIT_ERRATIC = TRAIT_PENALTY_MINOR
	)
	plague_mortar.required_traits = list(TRAIT_TOXIC, TRAIT_ELITE, TRAIT_WEAPONIZED)
	GLOB.rce_research_nodes[plague_mortar.id] = plague_mortar

	var/datum/rce_research_node/inferno_bombarder = new
	inferno_bombarder.id = "inferno_bombarder"
	inferno_bombarder.name = "Inferno Bombardment System"
	inferno_bombarder.desc = "Heavy artillery that rains incendiary shells over large areas."
	inferno_bombarder.tier = RCE_RESEARCH_TIER_3
	inferno_bombarder.cost = 840
	inferno_bombarder.branch = "hellfire"
	inferno_bombarder.prerequisites = list("pyro_grenade", "inferno_cloud")
	inferno_bombarder.unlocked_path = /obj/item/ego_weapon/ranged/inferno_bombarder
	inferno_bombarder.favored_traits = list(
		TRAIT_VOLATILE = TRAIT_BONUS_MAJOR,
		TRAIT_ELITE = TRAIT_BONUS_MAJOR,
		TRAIT_WEAPONIZED = TRAIT_BONUS_MAJOR,
		TRAIT_HEAVY = TRAIT_BONUS_MODERATE
	)
	inferno_bombarder.negative_traits = list(
		TRAIT_FODDER = TRAIT_PENALTY_MAJOR,
		TRAIT_LIGHTWEIGHT = TRAIT_PENALTY_MODERATE,
		TRAIT_AGILE = TRAIT_PENALTY_MINOR
	)
	inferno_bombarder.required_traits = list(TRAIT_VOLATILE, TRAIT_ELITE, TRAIT_WEAPONIZED)
	GLOB.rce_research_nodes[inferno_bombarder.id] = inferno_bombarder

	var/datum/rce_research_node/inferno_scythe = new
	inferno_scythe.id = "inferno_scythe"
	inferno_scythe.name = "Inferno Scythe"
	inferno_scythe.desc = "Blazing scythe that spreads flames with every swing."
	inferno_scythe.tier = RCE_RESEARCH_TIER_3
	inferno_scythe.cost = 720
	inferno_scythe.branch = "hellfire"
	inferno_scythe.prerequisites = list("fuel_tank", "thermite_spikes")
	inferno_scythe.unlocked_path = /obj/item/ego_weapon/inferno_scythe
	inferno_scythe.favored_traits = list(
		TRAIT_VOLATILE = TRAIT_BONUS_MAJOR,
		TRAIT_BRUTAL = TRAIT_BONUS_MAJOR,
		TRAIT_CORRUPTED = TRAIT_BONUS_MAJOR,
		TRAIT_ORGANIC = TRAIT_BONUS_MODERATE
	)
	inferno_scythe.negative_traits = list(
		TRAIT_PRECISION = TRAIT_PENALTY_MODERATE,
		TRAIT_MECHANICAL = TRAIT_PENALTY_MINOR
	)
	inferno_scythe.required_traits = list(TRAIT_VOLATILE, TRAIT_BRUTAL, TRAIT_CORRUPTED)
	GLOB.rce_research_nodes[inferno_scythe.id] = inferno_scythe

	var/datum/rce_research_node/inferno_field = new
	inferno_field.id = "inferno_field"
	inferno_field.name = "Inferno Field Generator"
	inferno_field.desc = "Creates a moving field of intense flames that incinerates everything. Moves in the direction faced, stops at walls, lasts 10 seconds."
	inferno_field.tier = RCE_RESEARCH_TIER_3
	inferno_field.cost = 780
	inferno_field.branch = "hellfire"
	inferno_field.prerequisites = list("inferno_cloud", "thermite_spikes")
	inferno_field.unlocked_path = /obj/item/inferno_field_generator
	inferno_field.favored_traits = list(
		TRAIT_VOLATILE = TRAIT_BONUS_MAJOR,
		TRAIT_CORRUPTED = TRAIT_BONUS_MAJOR,
		TRAIT_NEURAL = TRAIT_BONUS_MAJOR,
		TRAIT_ADAPTIVE = TRAIT_BONUS_MODERATE
	)
	inferno_field.negative_traits = list(
		TRAIT_FODDER = TRAIT_PENALTY_MODERATE,
		TRAIT_RCE_PRIMITIVE = TRAIT_PENALTY_MODERATE,
		TRAIT_LIGHTWEIGHT = TRAIT_PENALTY_MINOR
	)
	inferno_field.required_traits = list(TRAIT_VOLATILE, TRAIT_CORRUPTED, TRAIT_NEURAL)
	GLOB.rce_research_nodes[inferno_field.id] = inferno_field

	// STORM RAMS - ELECTRIC WEAPONS TREE

	// Tier 1 - Basic Electric
	var/datum/rce_research_node/capacitor_pack = new
	capacitor_pack.id = "capacitor_pack"
	capacitor_pack.name = "Storm Ram Starter Kit"
	capacitor_pack.desc = "Unlocks production of capacitor pack, Storm combat implant, and protective armor. Perfect starting kit for electric specialists."
	capacitor_pack.tier = 0
	capacitor_pack.cost = 150
	capacitor_pack.is_starter_kit = TRUE
	capacitor_pack.branch = "storm"
	capacitor_pack.prerequisites = list()
	capacitor_pack.unlocked_path = /obj/item/storage/box/capacitor_pack_starter_kit
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

	var/datum/rce_research_node/power_cell = new
	power_cell.id = "power_cell"
	power_cell.name = "Portable Power Cell"
	power_cell.desc = "A portable power cell used by Ravens to recharge Storm Ram specialists in the field."
	power_cell.tier = RCE_RESEARCH_TIER_1
	power_cell.cost = 75
	power_cell.branch = "storm"
	power_cell.prerequisites = list("capacitor_pack")
	power_cell.unlocked_path = /obj/item/rce_canister/power
	power_cell.favored_traits = list(
		TRAIT_EFFICIENT = TRAIT_BONUS_MODERATE,
		TRAIT_ENERGIZED = TRAIT_BONUS_MINOR
	)
	power_cell.negative_traits = list(
		TRAIT_VOLATILE = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[power_cell.id] = power_cell

	var/datum/rce_research_node/heavy_storm_armor = new
	heavy_storm_armor.id = "heavy_storm_armor"
	heavy_storm_armor.name = "Heavy Storm Armor"
	heavy_storm_armor.desc = "Reinforced armor for veteran storm units. Offers +20 to all resistances."
	heavy_storm_armor.tier = RCE_RESEARCH_TIER_2
	heavy_storm_armor.cost = 300
	heavy_storm_armor.branch = "storm"
	heavy_storm_armor.prerequisites = list("capacitor_pack")
	heavy_storm_armor.unlocked_path = /obj/item/clothing/suit/armor/ego_gear/storm/heavy
	heavy_storm_armor.favored_traits = list(
		TRAIT_MECHANICAL = TRAIT_BONUS_MAJOR,
		TRAIT_ARMORED = TRAIT_BONUS_MAJOR,
		TRAIT_HEAVY = TRAIT_BONUS_MODERATE,
		TRAIT_ELITE = TRAIT_BONUS_MODERATE
	)
	heavy_storm_armor.negative_traits = list(
		TRAIT_LIGHTWEIGHT = TRAIT_PENALTY_MODERATE,
		TRAIT_FODDER = TRAIT_PENALTY_MINOR
	)
	heavy_storm_armor.required_traits = list(TRAIT_MECHANICAL, TRAIT_ARMORED, TRAIT_HEAVY)
	GLOB.rce_research_nodes[heavy_storm_armor.id] = heavy_storm_armor

	var/datum/rce_research_node/arc_rifle = new
	arc_rifle.id = "storm_dash"
	arc_rifle.name = "Storm Dash Module"
	arc_rifle.desc = "Rush through enemies dealing chain lightning damage."
	arc_rifle.tier = RCE_RESEARCH_TIER_1
	arc_rifle.cost = 165
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
	static_field.cost = 150
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
	emp_grenade.desc = "Produces a portable factory that manufactures grenades that disable machinery and stun organics."
	emp_grenade.tier = RCE_RESEARCH_TIER_1
	emp_grenade.cost = 38
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
	tesla_cannon.cost = 450
	tesla_cannon.branch = "storm"
	tesla_cannon.prerequisites = list("capacitor_pack", "storm_dash")
	tesla_cannon.unlocked_path = /obj/item/ego_weapon/lightning_ram
	tesla_cannon.favored_traits = list(
		TRAIT_MECHANICAL = TRAIT_BONUS_MAJOR,
		TRAIT_ENERGIZED = TRAIT_BONUS_MAJOR,
		TRAIT_BRUTAL = TRAIT_BONUS_MAJOR,
		TRAIT_HEAVY = TRAIT_BONUS_MODERATE
	)
	tesla_cannon.negative_traits = list(
		TRAIT_LIGHTWEIGHT = TRAIT_PENALTY_MODERATE,
		TRAIT_FODDER = TRAIT_PENALTY_MINOR
	)
	tesla_cannon.required_traits = list(TRAIT_MECHANICAL, TRAIT_ENERGIZED, TRAIT_BRUTAL)
	GLOB.rce_research_nodes[tesla_cannon.id] = tesla_cannon

	var/datum/rce_research_node/dash_charger = new
	dash_charger.id = "thunderclap_gauntlets"
	dash_charger.name = "Thunderclap Gauntlets"
	dash_charger.desc = "AoE burst attack with built-in auto-retreat."
	dash_charger.tier = RCE_RESEARCH_TIER_2
	dash_charger.cost = 390
	dash_charger.branch = "storm"
	dash_charger.prerequisites = list("capacitor_pack")
	dash_charger.unlocked_path = /obj/item/ego_weapon/thunderclap_gauntlets
	dash_charger.favored_traits = list(
		TRAIT_MECHANICAL = TRAIT_BONUS_MAJOR,
		TRAIT_AGILE = TRAIT_BONUS_MAJOR,
		TRAIT_ENERGIZED = TRAIT_BONUS_MAJOR,
		TRAIT_VOLATILE = TRAIT_BONUS_MODERATE
	)
	dash_charger.negative_traits = list(
		TRAIT_SLUGGISH = TRAIT_PENALTY_MAJOR,
		TRAIT_HEAVY = TRAIT_PENALTY_MODERATE
	)
	dash_charger.required_traits = list(TRAIT_MECHANICAL, TRAIT_AGILE, TRAIT_ENERGIZED)
	GLOB.rce_research_nodes[dash_charger.id] = dash_charger

	var/datum/rce_research_node/storm_barrier = new
	storm_barrier.id = "storm_surge"
	storm_barrier.name = "Storm Surge Barrier"
	storm_barrier.desc = "Mobile electromagnetic shield that damages enemies on contact."
	storm_barrier.tier = RCE_RESEARCH_TIER_2
	storm_barrier.cost = 420
	storm_barrier.branch = "storm"
	storm_barrier.prerequisites = list("static_burst", "capacitor_pack")
	storm_barrier.unlocked_path = /obj/item/storm_surge_barrier
	storm_barrier.favored_traits = list(
		TRAIT_MECHANICAL = TRAIT_BONUS_MAJOR,
		TRAIT_ENERGIZED = TRAIT_BONUS_MAJOR,
		TRAIT_AGILE = TRAIT_BONUS_MODERATE,
		TRAIT_ADAPTIVE = TRAIT_BONUS_MODERATE
	)
	storm_barrier.negative_traits = list(
		TRAIT_HEAVY = TRAIT_PENALTY_MODERATE,
		TRAIT_SLUGGISH = TRAIT_PENALTY_MAJOR
	)
	storm_barrier.required_traits = list(TRAIT_MECHANICAL, TRAIT_ENERGIZED, TRAIT_ADAPTIVE)
	GLOB.rce_research_nodes[storm_barrier.id] = storm_barrier

	// Tier 3 - Elite Electric
	var/datum/rce_research_node/railgun_lance = new
	railgun_lance.id = "railgun_charge"
	railgun_lance.name = "Railgun Charge Module"
	railgun_lance.desc = "Transform into a living railgun projectile - ultimate rush attack."
	railgun_lance.tier = RCE_RESEARCH_TIER_3
	railgun_lance.cost = 750
	railgun_lance.branch = "storm"
	railgun_lance.prerequisites = list("thunderclap_gauntlets", "lightning_ram")
	railgun_lance.unlocked_path = /obj/item/ego_weapon/railgun_charge
	railgun_lance.favored_traits = list(
		TRAIT_MECHANICAL = TRAIT_BONUS_MAJOR,
		TRAIT_ELITE = TRAIT_BONUS_MAJOR,
		TRAIT_ENERGIZED = TRAIT_BONUS_MAJOR,
		TRAIT_BRUTAL = TRAIT_BONUS_MAJOR
	)
	railgun_lance.negative_traits = list(
		TRAIT_FODDER = TRAIT_PENALTY_MAJOR,
		TRAIT_LIGHTWEIGHT = TRAIT_PENALTY_MODERATE,
		TRAIT_ERRATIC = TRAIT_PENALTY_MINOR
	)
	railgun_lance.required_traits = list(TRAIT_MECHANICAL, TRAIT_ELITE, TRAIT_BRUTAL)
	GLOB.rce_research_nodes[railgun_lance.id] = railgun_lance

	var/datum/rce_research_node/thunderstorm_artillery = new
	thunderstorm_artillery.id = "thunderstorm_slam"
	thunderstorm_artillery.name = "Thunderstorm Slam Module"
	thunderstorm_artillery.desc = "Leap and ground slam to create a lingering electric storm."
	thunderstorm_artillery.tier = RCE_RESEARCH_TIER_3
	thunderstorm_artillery.cost = 840
	thunderstorm_artillery.branch = "storm"
	thunderstorm_artillery.prerequisites = list("lightning_ram", "emp_grenade")
	thunderstorm_artillery.unlocked_path = /obj/item/thunderstorm_slam
	thunderstorm_artillery.favored_traits = list(
		TRAIT_MECHANICAL = TRAIT_BONUS_MAJOR,
		TRAIT_ELITE = TRAIT_BONUS_MAJOR,
		TRAIT_ENERGIZED = TRAIT_BONUS_MAJOR,
		TRAIT_VOLATILE = TRAIT_BONUS_MAJOR
	)
	thunderstorm_artillery.negative_traits = list(
		TRAIT_FODDER = TRAIT_PENALTY_MAJOR,
		TRAIT_RCE_PRIMITIVE = TRAIT_PENALTY_MODERATE,
		TRAIT_LIGHTWEIGHT = TRAIT_PENALTY_MINOR
	)
	thunderstorm_artillery.required_traits = list(TRAIT_MECHANICAL, TRAIT_ELITE, TRAIT_VOLATILE)
	GLOB.rce_research_nodes[thunderstorm_artillery.id] = thunderstorm_artillery

	// UTILITY BRANCH - General purpose tools

	var/datum/rce_research_node/extraction_pack = new
	extraction_pack.id = "extraction_pack"
	extraction_pack.name = "Fulton Extraction Pack"
	extraction_pack.desc = "A balloon that can extract equipment or personnel to a recovery beacon. 3 uses per pack."
	extraction_pack.tier = RCE_RESEARCH_TIER_1
	extraction_pack.cost = 20
	extraction_pack.branch = "utility"
	extraction_pack.prerequisites = list()
	extraction_pack.unlocked_path = /obj/item/extraction_pack
	extraction_pack.favored_traits = list(
		TRAIT_MECHANICAL = TRAIT_BONUS_MODERATE,
		TRAIT_LIGHTWEIGHT = TRAIT_BONUS_MINOR
	)
	extraction_pack.negative_traits = list(
		TRAIT_HEAVY = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[extraction_pack.id] = extraction_pack

	var/datum/rce_research_node/extraction_point = new
	extraction_point.id = "extraction_point"
	extraction_point.name = "Fulton Recovery Beacon"
	extraction_point.desc = "A beacon for the fulton recovery system. Link extraction packs to this beacon."
	extraction_point.tier = RCE_RESEARCH_TIER_1
	extraction_point.cost = 25
	extraction_point.branch = "utility"
	extraction_point.prerequisites = list()
	extraction_point.unlocked_path = /obj/item/fulton_core
	extraction_point.favored_traits = list(
		TRAIT_MECHANICAL = TRAIT_BONUS_MODERATE,
		TRAIT_EFFICIENT = TRAIT_BONUS_MINOR
	)
	extraction_point.negative_traits = list(
		TRAIT_VOLATILE = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[extraction_point.id] = extraction_point

	var/datum/rce_research_node/conveyor_filter = new
	conveyor_filter.id = "conveyor_filter"
	conveyor_filter.name = "Conveyor Filter Assembly"
	conveyor_filter.desc = "A conveyor filter that can sort items. Place on floor to deploy."
	conveyor_filter.tier = RCE_RESEARCH_TIER_1
	conveyor_filter.cost = 100
	conveyor_filter.branch = "utility"
	conveyor_filter.prerequisites = list()
	conveyor_filter.unlocked_path = /obj/item/stack/conveyor_filter
	conveyor_filter.favored_traits = list(
		TRAIT_MECHANICAL = TRAIT_BONUS_MODERATE,
		TRAIT_EFFICIENT = TRAIT_BONUS_MODERATE
	)
	conveyor_filter.negative_traits = list(
		TRAIT_ORGANIC = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[conveyor_filter.id] = conveyor_filter

	var/datum/rce_research_node/field_sandbags = new
	field_sandbags.id = "field_sandbags"
	field_sandbags.name = "Field Sandbag Kit"
	field_sandbags.desc = "A kit containing 5 quick-deploy sandbags. Easy to climb over for rapid repositioning."
	field_sandbags.tier = RCE_RESEARCH_TIER_1
	field_sandbags.cost = 10
	field_sandbags.branch = "utility"
	field_sandbags.prerequisites = list()
	field_sandbags.unlocked_path = /obj/item/storage/box/field_sandbags
	field_sandbags.favored_traits = list(
		TRAIT_ARMORED = TRAIT_BONUS_MODERATE,
		TRAIT_HEAVY = TRAIT_BONUS_MINOR
	)
	field_sandbags.negative_traits = list(
		TRAIT_AGILE = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[field_sandbags.id] = field_sandbags

	var/datum/rce_research_node/storm_gear_pouch = new
	storm_gear_pouch.id = "storm_gear_pouch"
	storm_gear_pouch.name = "Storm Ram Gear Pouch"
	storm_gear_pouch.desc = "A specialized pouch for holding Storm Ram equipment. Does not hold EGO weapons."
	storm_gear_pouch.tier = RCE_RESEARCH_TIER_1
	storm_gear_pouch.cost = 50
	storm_gear_pouch.branch = "utility"
	storm_gear_pouch.prerequisites = list()
	storm_gear_pouch.unlocked_path = /obj/item/storage/storm_gear_pouch
	storm_gear_pouch.favored_traits = list(
		TRAIT_MECHANICAL = TRAIT_BONUS_MINOR,
		TRAIT_EFFICIENT = TRAIT_BONUS_MINOR
	)
	storm_gear_pouch.negative_traits = list(
		TRAIT_ORGANIC = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[storm_gear_pouch.id] = storm_gear_pouch

	var/datum/rce_research_node/hellfire_gear_pouch = new
	hellfire_gear_pouch.id = "hellfire_gear_pouch"
	hellfire_gear_pouch.name = "Hellfire Rooster Gear Pouch"
	hellfire_gear_pouch.desc = "A specialized pouch for holding Hellfire Rooster equipment. Does not hold EGO weapons."
	hellfire_gear_pouch.tier = RCE_RESEARCH_TIER_1
	hellfire_gear_pouch.cost = 50
	hellfire_gear_pouch.branch = "utility"
	hellfire_gear_pouch.prerequisites = list()
	hellfire_gear_pouch.unlocked_path = /obj/item/storage/hellfire_gear_pouch
	hellfire_gear_pouch.favored_traits = list(
		TRAIT_MECHANICAL = TRAIT_BONUS_MINOR,
		TRAIT_EFFICIENT = TRAIT_BONUS_MINOR
	)
	hellfire_gear_pouch.negative_traits = list(
		TRAIT_ORGANIC = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[hellfire_gear_pouch.id] = hellfire_gear_pouch

	var/datum/rce_research_node/venom_gear_pouch = new
	venom_gear_pouch.id = "venom_gear_pouch"
	venom_gear_pouch.name = "Venom Rattlesnake Gear Pouch"
	venom_gear_pouch.desc = "A specialized pouch for holding Venom Rattlesnake equipment. Does not hold EGO weapons."
	venom_gear_pouch.tier = RCE_RESEARCH_TIER_1
	venom_gear_pouch.cost = 50
	venom_gear_pouch.branch = "utility"
	venom_gear_pouch.prerequisites = list()
	venom_gear_pouch.unlocked_path = /obj/item/storage/venom_gear_pouch
	venom_gear_pouch.favored_traits = list(
		TRAIT_MECHANICAL = TRAIT_BONUS_MINOR,
		TRAIT_EFFICIENT = TRAIT_BONUS_MINOR
	)
	venom_gear_pouch.negative_traits = list(
		TRAIT_ORGANIC = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[venom_gear_pouch.id] = venom_gear_pouch

	var/datum/rce_research_node/emergency_extraction = new
	emergency_extraction.id = "emergency_extraction"
	emergency_extraction.name = "Emergency Extraction Implant"
	emergency_extraction.desc = "A one-use implant that automatically extracts you to a linked beacon when you would die."
	emergency_extraction.tier = RCE_RESEARCH_TIER_1
	emergency_extraction.cost = 40
	emergency_extraction.branch = "utility"
	emergency_extraction.prerequisites = list()
	emergency_extraction.unlocked_path = /obj/item/emergency_extraction_implant
	emergency_extraction.favored_traits = list(
		TRAIT_MECHANICAL = TRAIT_BONUS_MODERATE,
		TRAIT_EFFICIENT = TRAIT_BONUS_MINOR
	)
	emergency_extraction.negative_traits = list(
		TRAIT_VOLATILE = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[emergency_extraction.id] = emergency_extraction

	var/datum/rce_research_node/zerog_crate = new
	zerog_crate.id = "zerog_crate"
	zerog_crate.name = "Zero-Gravity Crate"
	zerog_crate.desc = "A crate with built-in anti-gravity technology. Won't be moved by conveyor belts."
	zerog_crate.tier = RCE_RESEARCH_TIER_1
	zerog_crate.cost = 25
	zerog_crate.branch = "utility"
	zerog_crate.prerequisites = list()
	zerog_crate.unlocked_path = /obj/structure/closet/crate/zerog
	zerog_crate.favored_traits = list(
		TRAIT_MECHANICAL = TRAIT_BONUS_MODERATE,
		TRAIT_EFFICIENT = TRAIT_BONUS_MINOR
	)
	zerog_crate.negative_traits = list(
		TRAIT_HEAVY = TRAIT_PENALTY_MINOR
	)
	GLOB.rce_research_nodes[zerog_crate.id] = zerog_crate

	// Debug: Log all initialized nodes
	world.log << "RCE Research Tree initialized with the following nodes:"
	for(var/node_id in GLOB.rce_research_nodes)
		var/datum/rce_research_node/node = GLOB.rce_research_nodes[node_id]
		world.log << "  - [node.id]: [node.name] (Tier [node.tier], Cost: [node.cost])"

// UTILITY BRANCH ITEMS

// Field sandbags
/obj/item/storage/box/field_sandbags
	name = "field sandbag kit"
	desc = "Contains 5 quick-deploy field sandbags. These sandbags are easier to climb over than standard variants."
	resistance_flags = INDESTRUCTIBLE

/obj/item/storage/box/field_sandbags/PopulateContents()
	for(var/i in 1 to 5)
		new /obj/item/deployable_sandbag(src)

/obj/item/deployable_sandbag
	name = "deployable field sandbag"
	desc = "A compact sandbag that can be quickly deployed as cover. Easier to climb than standard sandbags."
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sandbags"
	color = "#568cff"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/deployable_sandbag/attack_self(mob/user)
	. = ..()
	deploy(user)

/obj/item/deployable_sandbag/proc/deploy(mob/user)
	var/turf/T = get_turf(user)
	if(!T || T.density)
		to_chat(user, span_warning("You can't deploy the sandbag here!"))
		return
	to_chat(user, span_notice("You deploy [src]."))
	playsound(T, 'sound/items/trayhit2.ogg', 50, TRUE)
	new /obj/structure/barricade/sandbags/field(T)
	qdel(src)

// Zero-Gravity Crate - Won't be moved by conveyors
/obj/structure/closet/crate/zerog
	name = "zero-gravity crate"
	desc = "A crate with built-in anti-gravity technology. It hovers slightly above the ground and won't be moved by conveyor belts."
	icon_state = "scicrate"

/obj/structure/closet/crate/zerog/has_gravity(turf/T)
	return FALSE

// Portable factory definitions for research unlocks
/obj/item/portable_factory/pyro_grenade
	name = "pyro grenade factory module"
	desc = "Deploys a factory that produces R-Corp pyro grenades."
	factory_path = /obj/structure/rcorp_factory/pyro_grenade
	resistance_flags = INDESTRUCTIBLE

/obj/structure/rcorp_factory/pyro_grenade
	name = "pyro grenade factory"
	desc = "Produces R-Corp pyro grenades using red and green materials."
	item = /obj/item/grenade/r_corp/pyro
	resistance_flags = INDESTRUCTIBLE
	rcost = 1
	gcost = 1

// HELLFIRE WEAPON FACTORIES

/obj/item/portable_factory/incendiary_mines
	name = "incendiary mine factory module"
	desc = "Deploys a factory that produces incendiary proximity mines."
	factory_path = /obj/structure/rcorp_factory/incendiary_mines
	resistance_flags = INDESTRUCTIBLE

/obj/structure/rcorp_factory/incendiary_mines
	name = "incendiary mine factory"
	desc = "Produces incendiary proximity mines."
	item = /obj/item/incendiary_mine
	resistance_flags = INDESTRUCTIBLE
	rcost = 1
	gcost = 1

// ELECTRIC WEAPON FACTORIES

/obj/item/portable_factory/emp_grenade
	name = "EMP grenade factory module"
	desc = "Deploys a factory that produces EMP grenades."
	factory_path = /obj/structure/rcorp_factory/emp_grenade
	resistance_flags = INDESTRUCTIBLE

/obj/structure/rcorp_factory/emp_grenade
	name = "EMP grenade factory"
	desc = "Produces R-Corp EMP grenades."
	item = /obj/item/grenade/r_corp/emp
	resistance_flags = INDESTRUCTIBLE
	rcost = 1
	gcost = 1

// VENOM WEAPON FACTORIES

/obj/item/portable_factory/acid_grenade
	name = "acid grenade factory module"
	desc = "Deploys a factory that produces R-Corp acid grenades."
	factory_path = /obj/structure/rcorp_factory/acid_grenade
	resistance_flags = INDESTRUCTIBLE

/obj/structure/rcorp_factory/acid_grenade
	name = "acid grenade factory"
	desc = "Produces R-Corp acid grenades using red and green materials."
	item = /obj/item/grenade/r_corp/acid
	resistance_flags = INDESTRUCTIBLE
	rcost = 1
	gcost = 1

/obj/item/portable_factory/toxic_mine
	name = "toxic mine factory module"
	desc = "Deploys a factory that produces toxic proximity mines."
	factory_path = /obj/structure/rcorp_factory/toxic_mine
	resistance_flags = INDESTRUCTIBLE

/obj/structure/rcorp_factory/toxic_mine
	name = "toxic mine factory"
	desc = "Produces toxic proximity mines."
	item = /obj/item/toxic_mine
	resistance_flags = INDESTRUCTIBLE
	rcost = 1
	gcost = 1

// TIER 0 STARTER KIT BOXES

/obj/item/storage/box/fuel_tank_starter_kit
	name = "Hellfire Rooster starter kit"
	desc = "Contains a fuel tank backpack, Hellfire combat implant, protective armor, and a Heavy Flamethrower. Perfect for starting pyro specialists."
	resistance_flags = INDESTRUCTIBLE

/obj/item/storage/box/fuel_tank_starter_kit/PopulateContents()
	new /obj/item/rce_resource_tank/fuel_backpack(src)
	new /obj/item/organ/cyberimp/rce_specialist/hellfire(src)
	new /obj/item/clothing/suit/armor/ego_gear/hellfire(src)
	new /obj/item/ego_weapon/ranged/heavy_flamethrower(src)

/obj/item/storage/box/acid_tank_starter_kit
	name = "Venom Rattlesnake starter kit"
	desc = "Contains an acid tank backpack, Venom combat implant, protective armor, and an Acid Sprayer. Perfect for starting toxic specialists."
	resistance_flags = INDESTRUCTIBLE

/obj/item/storage/box/acid_tank_starter_kit/PopulateContents()
	new /obj/item/rce_resource_tank/acid_backpack(src)
	new /obj/item/organ/cyberimp/rce_specialist/venom(src)
	new /obj/item/clothing/suit/armor/ego_gear/venom(src)
	new /obj/item/ego_weapon/ranged/acid_sprayer(src)

/obj/item/storage/box/capacitor_pack_starter_kit
	name = "Storm Ram starter kit"
	desc = "Contains a capacitor pack, Storm combat implant, protective armor, and Thunder Gauntlets. Perfect for starting electric specialists."
	resistance_flags = INDESTRUCTIBLE

/obj/item/storage/box/capacitor_pack_starter_kit/PopulateContents()
	new /obj/item/rce_resource_tank/capacitor_pack(src)
	new /obj/item/organ/cyberimp/rce_specialist/storm(src)
	new /obj/item/clothing/suit/armor/ego_gear/storm(src)
	new /obj/item/ego_weapon/thunder_hammer(src)
