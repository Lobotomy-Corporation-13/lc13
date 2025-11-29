// RCE Specialist Class Equipment
// Unlocked through the research system
// Three specialist branches: Hellfire (fire), Venom (toxic), Storm (electric)

// ============================================
// HELLFIRE SPECIALIST EQUIPMENT (Fire/Pyro)
// ============================================

// Tier 1: Thermite Sprayer
/obj/item/ego_weapon/thermite_sprayer
	name = "thermite sprayer"
	desc = "A handheld incendiary weapon that sprays burning thermite at close range."
	special = "Applies burn stacks to targets hit."
	icon = 'icons/obj/flamethrower.dmi'
	icon_state = "flamethrower1"
	inhand_icon_state = "flamethrower_1"
	force = 15
	damtype = RED_DAMAGE
	attack_verb_continuous = list("scorches", "burns", "sears")
	attack_verb_simple = list("scorch", "burn", "sear")

/obj/item/ego_weapon/thermite_sprayer/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(proximity && isliving(target))
		var/mob/living/L = target
		L.apply_lc_burn(2)

// Tier 1: Inferno Wall
/obj/item/ego_weapon/inferno_wall
	name = "inferno wall projector"
	desc = "Creates a temporary wall of fire that blocks and damages enemies."
	special = "Use on ground to create a fire wall."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "yourmorning"
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/ego_weapon/inferno_wall/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(isturf(target) && !proximity)
		if(get_dist(user, target) > 4)
			to_chat(user, span_warning("Too far away!"))
			return
		new /obj/effect/turf_fire(target, 10 SECONDS)
		to_chat(user, span_notice("You create a fire wall."))
		playsound(target, 'sound/effects/burn.ogg', 50, TRUE)

// Tier 2: Inferno Rush
/obj/item/ego_weapon/inferno_rush
	name = "inferno rush gauntlets"
	desc = "Flaming gauntlets that set targets ablaze with each strike."
	special = "Melee attacks apply burn stacks and ignite targets."
	icon = 'icons/obj/clothing/gloves.dmi'
	icon_state = "rainbow"
	force = 20
	damtype = RED_DAMAGE
	attack_verb_continuous = list("incinerates", "scorches", "burns")
	attack_verb_simple = list("incinerate", "scorch", "burn")

/obj/item/ego_weapon/inferno_rush/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(proximity && isliving(target))
		var/mob/living/L = target
		L.apply_lc_burn(3)

// Tier 2: Pyroclastic Gauntlets
/obj/item/ego_weapon/pyroclastic_gauntlets
	name = "pyroclastic gauntlets"
	desc = "Heavy gauntlets that unleash volcanic fury in melee combat."
	special = "Strong melee attacks with area fire effect."
	icon = 'icons/obj/clothing/gloves.dmi'
	icon_state = "captain"
	force = 25
	damtype = RED_DAMAGE
	attack_verb_continuous = list("smashes", "burns", "crushes")
	attack_verb_simple = list("smash", "burn", "crush")

// Tier 2: Napalm Launcher
/obj/item/ego_weapon/ranged/napalm_launcher
	name = "napalm launcher"
	desc = "A modified launcher that fires sticky napalm canisters."
	special = "Creates pools of burning napalm on impact."
	icon = 'icons/obj/grenade.dmi'
	icon_state = "flashbang"
	projectile_path = /obj/projectile/ego_bullet/napalm
	fire_sound = 'sound/weapons/blastcannon.ogg'

/obj/projectile/ego_bullet/napalm
	name = "napalm canister"
	icon_state = "grenade"
	damage = 15
	damage_type = RED_DAMAGE
	speed = 1.5
	range = 7

/obj/projectile/ego_bullet/napalm/on_hit(atom/target, blocked = FALSE)
	. = ..()
	var/turf/T = get_turf(target)
	if(T)
		new /obj/effect/turf_fire(T, 15 SECONDS)
	if(isliving(target))
		var/mob/living/L = target
		L.apply_lc_burn(5)

// Tier 3: Auto Flamethrower
/obj/item/auto_flamethrower
	name = "automated flamethrower turret"
	desc = "A deployable turret that automatically targets and burns nearby enemies."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "destructive_analyzer"
	w_class = WEIGHT_CLASS_BULKY

// Tier 3: Hellfire Armor
/obj/item/clothing/suit/armor/ego_gear/hellfire
	name = "hellfire suit"
	desc = "Specialized armor that grants fire immunity and enhances pyrotechnic damage."
	icon_state = "intrepid_coat"
	armor = list(MELEE = 30, BULLET = 25, LASER = 40, ENERGY = 40, BOMB = 50, BIO = 100, RAD = 100, FIRE = 100, ACID = 50)

/obj/item/clothing/head/ego_hat/helmet/hellfire
	name = "hellfire helmet"
	desc = "A heat-resistant helmet that completes the hellfire specialist set."
	icon_state = "intrepid_helmet"
	armor = list(MELEE = 30, BULLET = 25, LASER = 40, ENERGY = 40, BOMB = 50, BIO = 100, RAD = 100, FIRE = 100, ACID = 50)

// ============================================
// VENOM SPECIALIST EQUIPMENT (Toxic/Acid)
// ============================================

// Tier 1: Acid Sprayer
/obj/item/ego_weapon/ranged/acid_sprayer
	name = "acid sprayer"
	desc = "A pressurized sprayer that launches corrosive acid."
	special = "Applies corrosive damage over time."
	icon = 'icons/obj/flamethrower.dmi'
	icon_state = "flamethrower1"
	projectile_path = /obj/projectile/ego_bullet/acid
	fire_sound = 'sound/effects/spray.ogg'

/obj/projectile/ego_bullet/acid
	name = "acid glob"
	icon_state = "toxin"
	damage = 10
	damage_type = PALE_DAMAGE
	speed = 1.2
	range = 6

// Tier 2: Venom Launcher
/obj/item/ego_weapon/ranged/venom_launcher
	name = "venom launcher"
	desc = "Launches concentrated venom grenades that create toxic clouds."
	special = "Creates lingering toxic zones."
	icon = 'icons/obj/grenade.dmi'
	icon_state = "chem"
	projectile_path = /obj/projectile/ego_bullet/venom
	fire_sound = 'sound/weapons/blastcannon.ogg'

/obj/projectile/ego_bullet/venom
	name = "venom grenade"
	icon_state = "grenade"
	damage = 20
	damage_type = PALE_DAMAGE
	speed = 1.5
	range = 8

// Tier 2: Decay Cloud Generator
/obj/item/decay_cloud_generator
	name = "decay cloud generator"
	desc = "Creates a cloud of decaying toxins that damages all in the area."
	icon = 'icons/obj/grenade.dmi'
	icon_state = "chem"
	w_class = WEIGHT_CLASS_NORMAL

// Tier 2: Venom Spike Launcher
/obj/item/venom_spike_launcher
	name = "venom spike launcher"
	desc = "Fires toxic spikes that embed in targets and continue dealing damage."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "yourmorning"
	w_class = WEIGHT_CLASS_NORMAL

// Tier 3: Toxic Bombarder
/obj/item/ego_weapon/ranged/toxic_bombarder
	name = "toxic bombarder"
	desc = "A heavy launcher that blankets areas with corrosive toxins."
	special = "Massive area denial weapon."
	icon = 'icons/obj/grenade.dmi'
	icon_state = "syndiemini"
	projectile_path = /obj/projectile/ego_bullet/toxic_bomb
	fire_sound = 'sound/weapons/blastcannon.ogg'

/obj/projectile/ego_bullet/toxic_bomb
	name = "toxic bomb"
	icon_state = "grenade"
	damage = 30
	damage_type = PALE_DAMAGE
	speed = 2
	range = 10

// Tier 3: Plague Scythe
/obj/item/ego_weapon/plague_scythe
	name = "plague scythe"
	desc = "A wicked scythe dripping with toxic plague that spreads to nearby enemies."
	special = "Melee strikes spread toxic plague."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "yourmorning"
	force = 30
	damtype = PALE_DAMAGE
	attack_verb_continuous = list("slashes", "reaps", "infects")
	attack_verb_simple = list("slash", "reap", "infect")

// Tier 3: Miasma Field Generator
/obj/item/miasma_field_generator
	name = "miasma field generator"
	desc = "Deploys a portable toxic miasma that damages enemies within range."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "dvd"
	w_class = WEIGHT_CLASS_BULKY

// Tier 3: Acid Tank Backpack
/obj/item/acid_tank_backpack
	name = "acid tank backpack"
	desc = "A specialized backpack that enhances toxic weapons and provides acid immunity."
	icon = 'icons/obj/tank.dmi'
	icon_state = "plasmaman_tank"
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY

// Tier 3: Toxic Mine
/obj/item/toxic_mine
	name = "toxic mine kit"
	desc = "Deployable mines that release toxic gas when triggered."
	icon = 'icons/obj/grenade.dmi'
	icon_state = "dvmine"
	w_class = WEIGHT_CLASS_SMALL

// Tier 3: Venom Trap Dispenser
/obj/item/venom_trap_dispenser
	name = "venom trap dispenser"
	desc = "Creates sticky venom traps that slow and poison enemies."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "yourmorning"
	w_class = WEIGHT_CLASS_NORMAL

// ============================================
// STORM SPECIALIST EQUIPMENT (Electric)
// ============================================

// Tier 1: Thunder Gauntlets
/obj/item/ego_weapon/thunder_gauntlets
	name = "thunder gauntlets"
	desc = "Electrified gauntlets that shock targets on impact."
	special = "Melee strikes have a chance to stun."
	icon = 'icons/obj/clothing/gloves.dmi'
	icon_state = "intrepid"
	force = 18
	damtype = WHITE_DAMAGE
	attack_verb_continuous = list("shocks", "electrocutes", "zaps")
	attack_verb_simple = list("shock", "electrocute", "zap")

// Tier 1: Storm Dash
/obj/item/storm_dash
	name = "storm dash module"
	desc = "Allows the user to dash forward while leaving an electric trail."
	icon = 'icons/obj/module.dmi'
	icon_state = "intrepid"
	w_class = WEIGHT_CLASS_SMALL

// Tier 1: Static Burst Generator
/obj/item/static_burst_generator
	name = "static burst generator"
	desc = "Releases a burst of static electricity that damages and staggers nearby enemies."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "dvd"
	w_class = WEIGHT_CLASS_NORMAL

// Tier 2: Lightning Ram
/obj/item/ego_weapon/lightning_ram
	name = "lightning ram"
	desc = "A powerful melee weapon that channels lightning through targets."
	special = "Charged strikes chain to nearby enemies."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "yourmorning"
	force = 28
	damtype = WHITE_DAMAGE
	attack_verb_continuous = list("smashes", "thunders", "shocks")
	attack_verb_simple = list("smash", "thunder", "shock")

// Tier 2: Thunderclap Gauntlets
/obj/item/ego_weapon/thunderclap_gauntlets
	name = "thunderclap gauntlets"
	desc = "Enhanced gauntlets that release thunderclaps on impact."
	special = "Attacks create shockwaves that knock back enemies."
	icon = 'icons/obj/clothing/gloves.dmi'
	icon_state = "military"
	force = 25
	damtype = WHITE_DAMAGE
	attack_verb_continuous = list("thunders", "claps", "booms")
	attack_verb_simple = list("thunder", "clap", "boom")

// Tier 2: Storm Surge Barrier
/obj/item/storm_surge_barrier
	name = "storm surge barrier"
	desc = "Creates an electric barrier that damages enemies who pass through."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "dvd"
	w_class = WEIGHT_CLASS_NORMAL

// Tier 3: Railgun Charge
/obj/item/ego_weapon/railgun_charge
	name = "railgun charge"
	desc = "A devastating electromagnetic weapon that fires supercharged projectiles."
	special = "Piercing shots that deal massive damage."
	icon = 'icons/obj/guns/energy.dmi'
	icon_state = "decloner"
	force = 35
	damtype = WHITE_DAMAGE

// Tier 3: Thunderstorm Slam
/obj/item/thunderstorm_slam
	name = "thunderstorm slam boots"
	desc = "Specialized boots that create lightning strikes when the user jumps."
	icon = 'icons/obj/clothing/shoes.dmi'
	icon_state = "intrepid"
	slot_flags = ITEM_SLOT_FEET
	w_class = WEIGHT_CLASS_SMALL

// Tier 3: Capacitor Pack
/obj/item/capacitor_pack
	name = "capacitor pack"
	desc = "A backpack that stores and amplifies electrical energy for storm weapons."
	icon = 'icons/obj/tank.dmi'
	icon_state = "plasmaman_tank"
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY

// Tier 3: EMP Grenade
/obj/item/grenade/r_corp/emp
	name = "R-Corp EMP grenade"
	desc = "A powerful electromagnetic pulse grenade that disables electronics."
	icon = 'icons/obj/grenade.dmi'
	icon_state = "emp"
	var/emp_range = 4

/obj/item/grenade/r_corp/emp/detonate(mob/living/lanced_by)
	. = ..()
	empulse(src, emp_range, emp_range * 2)
	qdel(src)
