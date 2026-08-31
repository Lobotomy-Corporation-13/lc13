/**
 * Resurgence Outpost - Weapons Bench
 *
 * A crafting station for forging clan melee and ranged weapons.
 * Weapons use a rarity system — each recipe specifies the rarity tier,
 * and the crafted item gets the appropriate rarity, outline, and name.
 * Also crafts ammunition and magazines for ballistic weapons.
 */

/// Crafting category defines
#define CRAFT_CAT_MELEE "Melee Weapons"
#define CRAFT_CAT_RANGED "Ranged Weapons"
#define CRAFT_CAT_AMMO "Ammunition"
#define CRAFT_CAT_FAITH_WEAPONS "Faith Weapons"

/obj/structure/resurgence_crafting_table/weapons_bench
	name = "weapons bench"
	desc = "A heavy workbench equipped with tools for forging weapons and ammunition."
	icon = 'ModularLobotomy/_Lobotomyicons/workshop.dmi'
	icon_state = "anvil"

	// UI Theming
	action_verb = "Forge"
	busy_verb = "forging"
	complete_sound = 'sound/items/welder.ogg'
	ui_color = "red"

/// Visual feedback when crafting starts
/obj/structure/resurgence_crafting_table/weapons_bench/on_craft_start()
	add_atom_colour("#ff440030", TEMPORARY_COLOUR_PRIORITY)

/// Visual feedback when crafting stops
/obj/structure/resurgence_crafting_table/weapons_bench/on_craft_stop()
	if(!current_recipe_name)
		remove_atom_colour(TEMPORARY_COLOUR_PRIORITY)

/// Remap an ammo box type to the correct rarity subtype
/obj/structure/resurgence_crafting_table/weapons_bench/proc/get_rarity_ammo_type(base_type, rarity)
	// Pistol ammo boxes
	if(ispath(base_type, /obj/item/ammo_box/clan_pistol_ammo))
		switch(rarity)
			if(CLAN_RARITY_MILITIA)
				return /obj/item/ammo_box/clan_pistol_ammo/militia
			if(CLAN_RARITY_VETERAN)
				return /obj/item/ammo_box/clan_pistol_ammo/veteran
			if(CLAN_RARITY_ELITE)
				return /obj/item/ammo_box/clan_pistol_ammo/elite
		return /obj/item/ammo_box/clan_pistol_ammo
	// Rifle ammo boxes
	if(ispath(base_type, /obj/item/ammo_box/clan_rifle_ammo))
		switch(rarity)
			if(CLAN_RARITY_MILITIA)
				return /obj/item/ammo_box/clan_rifle_ammo/militia
			if(CLAN_RARITY_VETERAN)
				return /obj/item/ammo_box/clan_rifle_ammo/veteran
			if(CLAN_RARITY_ELITE)
				return /obj/item/ammo_box/clan_rifle_ammo/elite
		return /obj/item/ammo_box/clan_rifle_ammo
	// SMG ammo boxes
	if(ispath(base_type, /obj/item/ammo_box/clan_smg_ammo))
		switch(rarity)
			if(CLAN_RARITY_MILITIA)
				return /obj/item/ammo_box/clan_smg_ammo/militia
			if(CLAN_RARITY_VETERAN)
				return /obj/item/ammo_box/clan_smg_ammo/veteran
			if(CLAN_RARITY_ELITE)
				return /obj/item/ammo_box/clan_smg_ammo/elite
		return /obj/item/ammo_box/clan_smg_ammo
	// Shotgun ammo boxes
	if(ispath(base_type, /obj/item/ammo_box/clan_shotgun_ammo))
		switch(rarity)
			if(CLAN_RARITY_MILITIA)
				return /obj/item/ammo_box/clan_shotgun_ammo/militia
			if(CLAN_RARITY_VETERAN)
				return /obj/item/ammo_box/clan_shotgun_ammo/veteran
			if(CLAN_RARITY_ELITE)
				return /obj/item/ammo_box/clan_shotgun_ammo/elite
		return /obj/item/ammo_box/clan_shotgun_ammo
	return base_type

/// Override create_result to apply rarity from the recipe to clan weapons and ammo
/obj/structure/resurgence_crafting_table/weapons_bench/create_result(mob/crafter, list/recipe, mob/user = null)
	var/result_type = recipe["result"]
	var/result_amount = recipe["result_amount"]
	var/rarity = recipe["rarity"]

	// Get crafter's skill level for quality tier rolling
	var/crafting_skill = 1
	if(ishuman(crafter))
		var/mob/living/carbon/human/H = crafter
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(istype(core))
			crafting_skill = core.stat_crafting

	// Remap ammo box types to the correct rarity subtype before creation
	if(rarity && (ispath(result_type, /obj/item/ammo_box/clan_pistol_ammo) || ispath(result_type, /obj/item/ammo_box/clan_rifle_ammo) || ispath(result_type, /obj/item/ammo_box/clan_smg_ammo) || ispath(result_type, /obj/item/ammo_box/clan_shotgun_ammo)))
		result_type = get_rarity_ammo_type(result_type, rarity)

	if(ispath(result_type, /obj/item/stack))
		new result_type(get_turf(src), result_amount)
	else
		for(var/i in 1 to result_amount)
			var/obj/item/created = new result_type(get_turf(src))
			apply_quality_to_crafted(created, crafting_skill, user)
			if(rarity)
				apply_rarity_to_crafted(created, rarity)

/// Apply rarity to a crafted clan weapon
/obj/structure/resurgence_crafting_table/weapons_bench/proc/apply_rarity_to_crafted(obj/item/crafted, rarity)
	if(!crafted)
		return

	// Melee weapons
	if(istype(crafted, /obj/item/melee/clan_weapon))
		var/obj/item/melee/clan_weapon/W = crafted
		W.set_rarity(rarity)
		return

	// Ballistic pistols
	if(istype(crafted, /obj/item/gun/ballistic/automatic/pistol/clan))
		var/obj/item/gun/ballistic/automatic/pistol/clan/G = crafted
		G.set_rarity(rarity)
		return

	// Ballistic rifles
	if(istype(crafted, /obj/item/gun/ballistic/automatic/clan_rifle))
		var/obj/item/gun/ballistic/automatic/clan_rifle/G = crafted
		G.set_rarity(rarity)
		return

	// Shotguns
	if(istype(crafted, /obj/item/gun/ballistic/shotgun/clan_pump))
		var/obj/item/gun/ballistic/shotgun/clan_pump/G = crafted
		G.set_rarity(rarity)
		return

/obj/structure/resurgence_crafting_table/weapons_bench/init_recipes()
	recipes = list()

	// ==================== MELEE WEAPONS ====================

	// --- Militia Tier (T2: clan_arms) ---

	recipes["Militia Clan Blade"] = list(
		"result" = /obj/item/melee/clan_weapon/blade,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_MILITIA,
		"materials" = list(
			/obj/item/stack/sheet/metal = 4,
			/obj/item/stack/sheet/mineral/wood = 1
		),
		"total_work" = 15,
		"desc" = "4 Metal + 1 Wood -> Militia Clan Blade",
		"category" = CRAFT_CAT_MELEE
	)

	recipes["Militia Clan Mace"] = list(
		"result" = /obj/item/melee/clan_weapon/mace,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_MILITIA,
		"materials" = list(
			/obj/item/stack/sheet/metal = 6,
			/obj/item/stack/sheet/mineral/wood = 2
		),
		"total_work" = 20,
		"desc" = "6 Metal + 2 Wood -> Militia Clan Mace",
		"category" = CRAFT_CAT_MELEE
	)

	// --- Regular Tier (T3: improved_clan_arms) ---

	recipes["Clan Blade"] = list(
		"result" = /obj/item/melee/clan_weapon/blade,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_REGULAR,
		"materials" = list(
			/obj/item/stack/sheet/metal = 6,
			/obj/item/stack/sheet/mineral/silver = 2
		),
		"total_work" = 25,
		"desc" = "6 Metal + 2 Silver -> Clan Blade",
		"category" = CRAFT_CAT_MELEE,
		"research_required" = "improved_clan_arms"
	)

	recipes["Clan Mace"] = list(
		"result" = /obj/item/melee/clan_weapon/mace,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_REGULAR,
		"materials" = list(
			/obj/item/stack/sheet/metal = 10,
			/obj/item/stack/sheet/mineral/silver = 3
		),
		"total_work" = 30,
		"desc" = "10 Metal + 3 Silver -> Clan Mace",
		"category" = CRAFT_CAT_MELEE,
		"research_required" = "improved_clan_arms"
	)

	// --- Veteran Tier (T4: veteran_clan_arms) ---

	recipes["Veteran Clan Blade"] = list(
		"result" = /obj/item/melee/clan_weapon/blade,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_VETERAN,
		"materials" = list(
			/obj/item/stack/sheet/metal = 8,
			/obj/item/stack/sheet/mineral/silver = 4,
			/obj/item/stack/sheet/mineral/gold = 2
		),
		"total_work" = 35,
		"desc" = "8 Metal + 4 Silver + 2 Gold -> Veteran Clan Blade",
		"category" = CRAFT_CAT_MELEE,
		"research_required" = "veteran_clan_arms"
	)

	recipes["Veteran Clan Mace"] = list(
		"result" = /obj/item/melee/clan_weapon/mace,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_VETERAN,
		"materials" = list(
			/obj/item/stack/sheet/metal = 12,
			/obj/item/stack/sheet/mineral/silver = 6,
			/obj/item/stack/sheet/mineral/gold = 3
		),
		"total_work" = 40,
		"desc" = "12 Metal + 6 Silver + 3 Gold -> Veteran Clan Mace",
		"category" = CRAFT_CAT_MELEE,
		"research_required" = "veteran_clan_arms"
	)

	// --- Elite Tier (T5: elite_clan_arms) ---

	recipes["Elite Clan Blade"] = list(
		"result" = /obj/item/melee/clan_weapon/blade,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_ELITE,
		"materials" = list(
			/obj/item/stack/sheet/metal = 10,
			/obj/item/stack/sheet/mineral/silver = 6,
			/obj/item/stack/sheet/mineral/gold = 4,
			/obj/item/stack/sheet/mineral/diamond = 2
		),
		"total_work" = 50,
		"desc" = "10 Metal + 6 Silver + 4 Gold + 2 Diamond -> Elite Clan Blade",
		"category" = CRAFT_CAT_MELEE,
		"research_required" = "elite_clan_arms"
	)

	recipes["Elite Clan Mace"] = list(
		"result" = /obj/item/melee/clan_weapon/mace,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_ELITE,
		"materials" = list(
			/obj/item/stack/sheet/metal = 15,
			/obj/item/stack/sheet/mineral/silver = 8,
			/obj/item/stack/sheet/mineral/gold = 6,
			/obj/item/stack/sheet/mineral/diamond = 3
		),
		"total_work" = 60,
		"desc" = "15 Metal + 8 Silver + 6 Gold + 3 Diamond -> Elite Clan Mace",
		"category" = CRAFT_CAT_MELEE,
		"research_required" = "elite_clan_arms"
	)

	// ==================== RANGED WEAPONS ====================

	// --- Militia Tier ---

	recipes["Militia Clan Pistol"] = list(
		"result" = /obj/item/gun/ballistic/automatic/pistol/clan,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_MILITIA,
		"materials" = list(
			/obj/item/stack/sheet/metal = 5,
			/obj/item/stack/sheet/mineral/wood = 2
		),
		"total_work" = 20,
		"desc" = "5 Metal + 2 Wood -> Militia Clan Pistol",
		"category" = CRAFT_CAT_RANGED
	)

	recipes["Militia Clan Rifle"] = list(
		"result" = /obj/item/gun/ballistic/automatic/clan_rifle,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_MILITIA,
		"materials" = list(
			/obj/item/stack/sheet/metal = 8,
			/obj/item/stack/sheet/mineral/wood = 3
		),
		"total_work" = 25,
		"desc" = "8 Metal + 3 Wood -> Militia Clan Rifle",
		"category" = CRAFT_CAT_RANGED
	)

	// --- Regular Tier ---

	recipes["Clan Pistol"] = list(
		"result" = /obj/item/gun/ballistic/automatic/pistol/clan,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_REGULAR,
		"materials" = list(
			/obj/item/stack/sheet/metal = 8,
			/obj/item/stack/sheet/mineral/silver = 3
		),
		"total_work" = 30,
		"desc" = "8 Metal + 3 Silver -> Clan Pistol",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "improved_clan_arms"
	)

	recipes["Clan Rifle"] = list(
		"result" = /obj/item/gun/ballistic/automatic/clan_rifle,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_REGULAR,
		"materials" = list(
			/obj/item/stack/sheet/metal = 12,
			/obj/item/stack/sheet/mineral/silver = 5
		),
		"total_work" = 35,
		"desc" = "12 Metal + 5 Silver -> Clan Rifle",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "improved_clan_arms"
	)

	// --- Veteran Tier ---

	recipes["Veteran Clan Pistol"] = list(
		"result" = /obj/item/gun/ballistic/automatic/pistol/clan,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_VETERAN,
		"materials" = list(
			/obj/item/stack/sheet/metal = 10,
			/obj/item/stack/sheet/mineral/silver = 5,
			/obj/item/stack/sheet/mineral/gold = 3
		),
		"total_work" = 40,
		"desc" = "10 Metal + 5 Silver + 3 Gold -> Veteran Clan Pistol",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "veteran_clan_arms"
	)

	recipes["Veteran Clan Rifle"] = list(
		"result" = /obj/item/gun/ballistic/automatic/clan_rifle,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_VETERAN,
		"materials" = list(
			/obj/item/stack/sheet/metal = 15,
			/obj/item/stack/sheet/mineral/silver = 8,
			/obj/item/stack/sheet/mineral/gold = 4
		),
		"total_work" = 50,
		"desc" = "15 Metal + 8 Silver + 4 Gold -> Veteran Clan Rifle",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "veteran_clan_arms"
	)

	// --- Elite Tier ---

	recipes["Elite Clan Pistol"] = list(
		"result" = /obj/item/gun/ballistic/automatic/pistol/clan,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_ELITE,
		"materials" = list(
			/obj/item/stack/sheet/metal = 12,
			/obj/item/stack/sheet/mineral/silver = 8,
			/obj/item/stack/sheet/mineral/gold = 5,
			/obj/item/stack/sheet/mineral/diamond = 2
		),
		"total_work" = 55,
		"desc" = "12 Metal + 8 Silver + 5 Gold + 2 Diamond -> Elite Clan Pistol",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "elite_clan_arms"
	)

	recipes["Elite Clan Rifle"] = list(
		"result" = /obj/item/gun/ballistic/automatic/clan_rifle,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_ELITE,
		"materials" = list(
			/obj/item/stack/sheet/metal = 18,
			/obj/item/stack/sheet/mineral/silver = 10,
			/obj/item/stack/sheet/mineral/gold = 7,
			/obj/item/stack/sheet/mineral/diamond = 4
		),
		"total_work" = 70,
		"desc" = "18 Metal + 10 Silver + 7 Gold + 4 Diamond -> Elite Clan Rifle",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "elite_clan_arms"
	)

	// ==================== AMMUNITION ====================

	// --- Pistol Ammo ---

	recipes["Militia Pistol Rounds"] = list(
		"result" = /obj/item/ammo_box/clan_pistol_ammo,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_MILITIA,
		"materials" = list(
			/obj/item/stack/sheet/metal = 2,
			/obj/item/stack/sheet/mineral/coal = 1
		),
		"total_work" = 10,
		"desc" = "2 Metal + 1 Coal -> 30 Militia Pistol Rounds",
		"category" = CRAFT_CAT_AMMO
	)

	recipes["Pistol Rounds"] = list(
		"result" = /obj/item/ammo_box/clan_pistol_ammo,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_REGULAR,
		"materials" = list(
			/obj/item/stack/sheet/metal = 2,
			/obj/item/stack/sheet/mineral/coal = 1
		),
		"total_work" = 10,
		"desc" = "2 Metal + 1 Coal -> 30 Pistol Rounds",
		"category" = CRAFT_CAT_AMMO,
		"research_required" = "improved_clan_arms"
	)

	recipes["Veteran Pistol Rounds"] = list(
		"result" = /obj/item/ammo_box/clan_pistol_ammo,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_VETERAN,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3,
			/obj/item/stack/sheet/mineral/coal = 2
		),
		"total_work" = 12,
		"desc" = "3 Metal + 2 Coal -> 30 Veteran Pistol Rounds",
		"category" = CRAFT_CAT_AMMO,
		"research_required" = "veteran_clan_arms"
	)

	recipes["Elite Pistol Rounds"] = list(
		"result" = /obj/item/ammo_box/clan_pistol_ammo,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_ELITE,
		"materials" = list(
			/obj/item/stack/sheet/metal = 4,
			/obj/item/stack/sheet/mineral/coal = 3
		),
		"total_work" = 15,
		"desc" = "4 Metal + 3 Coal -> 30 Elite Pistol Rounds",
		"category" = CRAFT_CAT_AMMO,
		"research_required" = "elite_clan_arms"
	)

	// --- Rifle Ammo ---

	recipes["Militia Rifle Rounds"] = list(
		"result" = /obj/item/ammo_box/clan_rifle_ammo,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_MILITIA,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3,
			/obj/item/stack/sheet/mineral/coal = 2
		),
		"total_work" = 15,
		"desc" = "3 Metal + 2 Coal -> 20 Militia Rifle Rounds",
		"category" = CRAFT_CAT_AMMO
	)

	recipes["Rifle Rounds"] = list(
		"result" = /obj/item/ammo_box/clan_rifle_ammo,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_REGULAR,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3,
			/obj/item/stack/sheet/mineral/coal = 2
		),
		"total_work" = 15,
		"desc" = "3 Metal + 2 Coal -> 20 Rifle Rounds",
		"category" = CRAFT_CAT_AMMO,
		"research_required" = "improved_clan_arms"
	)

	recipes["Veteran Rifle Rounds"] = list(
		"result" = /obj/item/ammo_box/clan_rifle_ammo,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_VETERAN,
		"materials" = list(
			/obj/item/stack/sheet/metal = 4,
			/obj/item/stack/sheet/mineral/coal = 3
		),
		"total_work" = 18,
		"desc" = "4 Metal + 3 Coal -> 20 Veteran Rifle Rounds",
		"category" = CRAFT_CAT_AMMO,
		"research_required" = "veteran_clan_arms"
	)

	recipes["Elite Rifle Rounds"] = list(
		"result" = /obj/item/ammo_box/clan_rifle_ammo,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_ELITE,
		"materials" = list(
			/obj/item/stack/sheet/metal = 5,
			/obj/item/stack/sheet/mineral/coal = 4
		),
		"total_work" = 20,
		"desc" = "5 Metal + 4 Coal -> 20 Elite Rifle Rounds",
		"category" = CRAFT_CAT_AMMO,
		"research_required" = "elite_clan_arms"
	)

	// --- Magazines (one per weapon class, no rarity) ---

	recipes["Pistol Magazine"] = list(
		"result" = /obj/item/ammo_box/magazine/clan_pistol,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3
		),
		"total_work" = 10,
		"desc" = "3 Metal -> Empty Pistol Magazine (20 rounds)",
		"category" = CRAFT_CAT_AMMO
	)

	recipes["Rifle Magazine"] = list(
		"result" = /obj/item/ammo_box/magazine/clan_rifle,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 4
		),
		"total_work" = 12,
		"desc" = "4 Metal -> Empty Rifle Magazine (12 rounds)",
		"category" = CRAFT_CAT_AMMO
	)

	// --- Casing Collector ---

	recipes["Casing Collector"] = list(
		"result" = /obj/item/clan_casing_collector,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 5
		),
		"total_work" = 10,
		"desc" = "5 Metal -> Casing Collector (sweep up spent casings, recycle into metal)",
		"category" = CRAFT_CAT_AMMO
	)

	// ==================== FAITH WEAPONS ====================

	recipes["Void Caster"] = list(
		"result" = /obj/item/gun/clan_faith/void_caster,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 10,
			/obj/item/stack/sheet/mineral/gold = 8,
			/obj/item/stack/sheet/mineral/diamond = 5,
			/obj/item/stack/sheet/durathread = 3
		),
		"total_work" = 60,
		"desc" = "10 Metal + 8 Gold + 5 Diamond + 3 Durathread -> Void Caster (BLACK damage, 3 faith/shot)",
		"category" = CRAFT_CAT_FAITH_WEAPONS,
		"research_required" = "veteran_clan_arms"
	)

	recipes["Pale Lance"] = list(
		"result" = /obj/item/gun/clan_faith/pale_lance,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 12,
			/obj/item/stack/sheet/mineral/gold = 10,
			/obj/item/stack/sheet/mineral/diamond = 8,
			/obj/item/stack/sheet/durathread = 5
		),
		"total_work" = 80,
		"desc" = "12 Metal + 10 Gold + 8 Diamond + 5 Durathread -> Pale Lance (PALE damage, 5 faith/shot)",
		"category" = CRAFT_CAT_FAITH_WEAPONS,
		"research_required" = "elite_clan_arms"
	)

	recipes["Warper's Voidstaff"] = list(
		"result" = /obj/item/gun/clan_faith/voidstaff,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 10,
			/obj/item/stack/sheet/mineral/gold = 8,
			/obj/item/stack/sheet/mineral/diamond = 6,
			/obj/item/stack/sheet/durathread = 4
		),
		"total_work" = 70,
		"desc" = "10 Metal + 8 Gold + 6 Diamond + 4 Durathread -> Warper's Voidstaff (BLACK damage, teleport gimmick)",
		"category" = CRAFT_CAT_FAITH_WEAPONS,
		"research_required" = "elite_clan_arms"
	)

	// ==================== GIMMICK MELEE WEAPONS ====================

	// --- Scout's Spear (T2-T5, rarity per tier) ---

	recipes["Militia Scout's Spear"] = list(
		"result" = /obj/item/melee/clan_weapon/spear,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_MILITIA,
		"materials" = list(
			/obj/item/stack/sheet/metal = 4,
			/obj/item/stack/sheet/mineral/wood = 2
		),
		"total_work" = 15,
		"desc" = "4 Metal + 2 Wood -> Militia Scout's Spear (momentum gimmick)",
		"category" = CRAFT_CAT_MELEE,
		"research_required" = "clan_arms"
	)

	recipes["Scout's Spear"] = list(
		"result" = /obj/item/melee/clan_weapon/spear,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_REGULAR,
		"materials" = list(
			/obj/item/stack/sheet/metal = 6,
			/obj/item/stack/sheet/mineral/silver = 2
		),
		"total_work" = 25,
		"desc" = "6 Metal + 2 Silver -> Scout's Spear (momentum gimmick)",
		"category" = CRAFT_CAT_MELEE,
		"research_required" = "improved_clan_arms"
	)

	recipes["Veteran Scout's Spear"] = list(
		"result" = /obj/item/melee/clan_weapon/spear,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_VETERAN,
		"materials" = list(
			/obj/item/stack/sheet/metal = 8,
			/obj/item/stack/sheet/mineral/silver = 4,
			/obj/item/stack/sheet/mineral/gold = 2
		),
		"total_work" = 35,
		"desc" = "8 Metal + 4 Silver + 2 Gold -> Veteran Scout's Spear",
		"category" = CRAFT_CAT_MELEE,
		"research_required" = "veteran_clan_arms"
	)

	recipes["Elite Scout's Spear"] = list(
		"result" = /obj/item/melee/clan_weapon/spear,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_ELITE,
		"materials" = list(
			/obj/item/stack/sheet/metal = 10,
			/obj/item/stack/sheet/mineral/silver = 6,
			/obj/item/stack/sheet/mineral/gold = 4,
			/obj/item/stack/sheet/mineral/diamond = 2
		),
		"total_work" = 50,
		"desc" = "10 Metal + 6 Silver + 4 Gold + 2 Diamond -> Elite Scout's Spear",
		"category" = CRAFT_CAT_MELEE,
		"research_required" = "elite_clan_arms"
	)

	// --- Defender's Gauntlets (T2-T5) ---

	recipes["Militia Defender's Gauntlets"] = list(
		"result" = /obj/item/melee/clan_weapon/gauntlets,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_MILITIA,
		"materials" = list(
			/obj/item/stack/sheet/metal = 6,
			/obj/item/stack/sheet/mineral/wood = 2
		),
		"total_work" = 20,
		"desc" = "6 Metal + 2 Wood -> Militia Defender's Gauntlets (taunt gimmick)",
		"category" = CRAFT_CAT_MELEE,
		"research_required" = "clan_arms"
	)

	recipes["Defender's Gauntlets"] = list(
		"result" = /obj/item/melee/clan_weapon/gauntlets,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_REGULAR,
		"materials" = list(
			/obj/item/stack/sheet/metal = 10,
			/obj/item/stack/sheet/mineral/silver = 3
		),
		"total_work" = 30,
		"desc" = "10 Metal + 3 Silver -> Defender's Gauntlets (taunt gimmick)",
		"category" = CRAFT_CAT_MELEE,
		"research_required" = "improved_clan_arms"
	)

	recipes["Veteran Defender's Gauntlets"] = list(
		"result" = /obj/item/melee/clan_weapon/gauntlets,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_VETERAN,
		"materials" = list(
			/obj/item/stack/sheet/metal = 12,
			/obj/item/stack/sheet/mineral/silver = 6,
			/obj/item/stack/sheet/mineral/gold = 3
		),
		"total_work" = 40,
		"desc" = "12 Metal + 6 Silver + 3 Gold -> Veteran Defender's Gauntlets",
		"category" = CRAFT_CAT_MELEE,
		"research_required" = "veteran_clan_arms"
	)

	recipes["Elite Defender's Gauntlets"] = list(
		"result" = /obj/item/melee/clan_weapon/gauntlets,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_ELITE,
		"materials" = list(
			/obj/item/stack/sheet/metal = 15,
			/obj/item/stack/sheet/mineral/silver = 8,
			/obj/item/stack/sheet/mineral/gold = 6,
			/obj/item/stack/sheet/mineral/diamond = 3
		),
		"total_work" = 60,
		"desc" = "15 Metal + 8 Silver + 6 Gold + 3 Diamond -> Elite Defender's Gauntlets",
		"category" = CRAFT_CAT_MELEE,
		"research_required" = "elite_clan_arms"
	)

	// --- Assassin's Dagger (T4-T5) ---

	recipes["Assassin's Dagger"] = list(
		"result" = /obj/item/melee/clan_weapon/dagger,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_VETERAN,
		"materials" = list(
			/obj/item/stack/sheet/metal = 8,
			/obj/item/stack/sheet/mineral/silver = 4,
			/obj/item/stack/sheet/mineral/gold = 3
		),
		"total_work" = 35,
		"desc" = "8 Metal + 4 Silver + 3 Gold -> Assassin's Dagger (backstab gimmick)",
		"category" = CRAFT_CAT_MELEE,
		"research_required" = "veteran_clan_arms"
	)

	recipes["Elite Assassin's Dagger"] = list(
		"result" = /obj/item/melee/clan_weapon/dagger,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_ELITE,
		"materials" = list(
			/obj/item/stack/sheet/metal = 10,
			/obj/item/stack/sheet/mineral/silver = 6,
			/obj/item/stack/sheet/mineral/gold = 5,
			/obj/item/stack/sheet/mineral/diamond = 2
		),
		"total_work" = 50,
		"desc" = "10 Metal + 6 Silver + 5 Gold + 2 Diamond -> Elite Assassin's Dagger",
		"category" = CRAFT_CAT_MELEE,
		"research_required" = "elite_clan_arms"
	)

	// ==================== GIMMICK RANGED WEAPONS ====================

	// --- Sniper's Longrifle (T4-T5) ---

	recipes["Sniper's Longrifle"] = list(
		"result" = /obj/item/gun/ballistic/automatic/clan_rifle/longrifle,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_VETERAN,
		"materials" = list(
			/obj/item/stack/sheet/metal = 10,
			/obj/item/stack/sheet/mineral/silver = 5,
			/obj/item/stack/sheet/mineral/gold = 3
		),
		"total_work" = 40,
		"desc" = "10 Metal + 5 Silver + 3 Gold -> Sniper's Longrifle (aimed shot gimmick)",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "veteran_clan_arms"
	)

	recipes["Elite Sniper's Longrifle"] = list(
		"result" = /obj/item/gun/ballistic/automatic/clan_rifle/longrifle,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_ELITE,
		"materials" = list(
			/obj/item/stack/sheet/metal = 14,
			/obj/item/stack/sheet/mineral/silver = 8,
			/obj/item/stack/sheet/mineral/gold = 5,
			/obj/item/stack/sheet/mineral/diamond = 3
		),
		"total_work" = 55,
		"desc" = "14 Metal + 8 Silver + 5 Gold + 3 Diamond -> Elite Sniper's Longrifle",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "elite_clan_arms"
	)

	// --- Rapid's Repeater (T3-T5) ---

	recipes["Rapid's Repeater"] = list(
		"result" = /obj/item/gun/ballistic/automatic/pistol/clan/repeater,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_REGULAR,
		"materials" = list(
			/obj/item/stack/sheet/metal = 8,
			/obj/item/stack/sheet/mineral/silver = 4
		),
		"total_work" = 30,
		"desc" = "8 Metal + 4 Silver -> Rapid's Repeater (overdrive gimmick)",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "improved_clan_arms"
	)

	recipes["Veteran Rapid's Repeater"] = list(
		"result" = /obj/item/gun/ballistic/automatic/pistol/clan/repeater,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_VETERAN,
		"materials" = list(
			/obj/item/stack/sheet/metal = 10,
			/obj/item/stack/sheet/mineral/silver = 5,
			/obj/item/stack/sheet/mineral/gold = 3
		),
		"total_work" = 40,
		"desc" = "10 Metal + 5 Silver + 3 Gold -> Veteran Rapid's Repeater",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "veteran_clan_arms"
	)

	recipes["Elite Rapid's Repeater"] = list(
		"result" = /obj/item/gun/ballistic/automatic/pistol/clan/repeater,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_ELITE,
		"materials" = list(
			/obj/item/stack/sheet/metal = 12,
			/obj/item/stack/sheet/mineral/silver = 8,
			/obj/item/stack/sheet/mineral/gold = 5,
			/obj/item/stack/sheet/mineral/diamond = 2
		),
		"total_work" = 55,
		"desc" = "12 Metal + 8 Silver + 5 Gold + 2 Diamond -> Elite Rapid's Repeater",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "elite_clan_arms"
	)

	// --- SMG Ammo & Magazine ---

	recipes["SMG Rounds"] = list(
		"result" = /obj/item/ammo_box/clan_smg_ammo,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_REGULAR,
		"materials" = list(
			/obj/item/stack/sheet/metal = 2,
			/obj/item/stack/sheet/mineral/coal = 1
		),
		"total_work" = 10,
		"desc" = "2 Metal + 1 Coal -> 50 SMG Rounds",
		"category" = CRAFT_CAT_AMMO,
		"research_required" = "improved_clan_arms"
	)

	recipes["Veteran SMG Rounds"] = list(
		"result" = /obj/item/ammo_box/clan_smg_ammo,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_VETERAN,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3,
			/obj/item/stack/sheet/mineral/coal = 2
		),
		"total_work" = 12,
		"desc" = "3 Metal + 2 Coal -> 50 Veteran SMG Rounds",
		"category" = CRAFT_CAT_AMMO,
		"research_required" = "veteran_clan_arms"
	)

	recipes["Elite SMG Rounds"] = list(
		"result" = /obj/item/ammo_box/clan_smg_ammo,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_ELITE,
		"materials" = list(
			/obj/item/stack/sheet/metal = 4,
			/obj/item/stack/sheet/mineral/coal = 3
		),
		"total_work" = 15,
		"desc" = "4 Metal + 3 Coal -> 50 Elite SMG Rounds",
		"category" = CRAFT_CAT_AMMO,
		"research_required" = "elite_clan_arms"
	)

	recipes["SMG Magazine"] = list(
		"result" = /obj/item/ammo_box/magazine/clan_smg,
		"result_amount" = 1,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3
		),
		"total_work" = 10,
		"desc" = "3 Metal -> Empty SMG Magazine (50 rounds)",
		"category" = CRAFT_CAT_AMMO,
		"research_required" = "improved_clan_arms"
	)

	// ==================== GUN VARIANTS ====================

	// --- Machine Pistol (T2-T5) ---

	recipes["Militia Machine Pistol"] = list(
		"result" = /obj/item/gun/ballistic/automatic/pistol/clan/machine,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_MILITIA,
		"materials" = list(
			/obj/item/stack/sheet/metal = 5,
			/obj/item/stack/sheet/mineral/wood = 2
		),
		"total_work" = 20,
		"desc" = "5 Metal + 2 Wood -> Militia Machine Pistol (2-round burst)",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "clan_arms"
	)

	recipes["Machine Pistol"] = list(
		"result" = /obj/item/gun/ballistic/automatic/pistol/clan/machine,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_REGULAR,
		"materials" = list(
			/obj/item/stack/sheet/metal = 8,
			/obj/item/stack/sheet/mineral/silver = 3
		),
		"total_work" = 30,
		"desc" = "8 Metal + 3 Silver -> Machine Pistol (2-round burst)",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "improved_clan_arms"
	)

	recipes["Veteran Machine Pistol"] = list(
		"result" = /obj/item/gun/ballistic/automatic/pistol/clan/machine,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_VETERAN,
		"materials" = list(
			/obj/item/stack/sheet/metal = 10,
			/obj/item/stack/sheet/mineral/silver = 5,
			/obj/item/stack/sheet/mineral/gold = 3
		),
		"total_work" = 40,
		"desc" = "10 Metal + 5 Silver + 3 Gold -> Veteran Machine Pistol",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "veteran_clan_arms"
	)

	recipes["Elite Machine Pistol"] = list(
		"result" = /obj/item/gun/ballistic/automatic/pistol/clan/machine,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_ELITE,
		"materials" = list(
			/obj/item/stack/sheet/metal = 12,
			/obj/item/stack/sheet/mineral/silver = 8,
			/obj/item/stack/sheet/mineral/gold = 5,
			/obj/item/stack/sheet/mineral/diamond = 2
		),
		"total_work" = 55,
		"desc" = "12 Metal + 8 Silver + 5 Gold + 2 Diamond -> Elite Machine Pistol",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "elite_clan_arms"
	)

	// --- Heavy Pistol (T3-T5) ---

	recipes["Heavy Pistol"] = list(
		"result" = /obj/item/gun/ballistic/automatic/pistol/clan/heavy,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_REGULAR,
		"materials" = list(
			/obj/item/stack/sheet/metal = 10,
			/obj/item/stack/sheet/mineral/silver = 4
		),
		"total_work" = 35,
		"desc" = "10 Metal + 4 Silver -> Heavy Pistol (1.5x damage, slower)",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "improved_clan_arms"
	)

	recipes["Veteran Heavy Pistol"] = list(
		"result" = /obj/item/gun/ballistic/automatic/pistol/clan/heavy,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_VETERAN,
		"materials" = list(
			/obj/item/stack/sheet/metal = 12,
			/obj/item/stack/sheet/mineral/silver = 6,
			/obj/item/stack/sheet/mineral/gold = 4
		),
		"total_work" = 45,
		"desc" = "12 Metal + 6 Silver + 4 Gold -> Veteran Heavy Pistol",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "veteran_clan_arms"
	)

	recipes["Elite Heavy Pistol"] = list(
		"result" = /obj/item/gun/ballistic/automatic/pistol/clan/heavy,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_ELITE,
		"materials" = list(
			/obj/item/stack/sheet/metal = 14,
			/obj/item/stack/sheet/mineral/silver = 8,
			/obj/item/stack/sheet/mineral/gold = 6,
			/obj/item/stack/sheet/mineral/diamond = 3
		),
		"total_work" = 60,
		"desc" = "14 Metal + 8 Silver + 6 Gold + 3 Diamond -> Elite Heavy Pistol",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "elite_clan_arms"
	)

	// --- Assault Rifle (T3-T5) ---

	recipes["Assault Rifle"] = list(
		"result" = /obj/item/gun/ballistic/automatic/clan_rifle/assault,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_REGULAR,
		"materials" = list(
			/obj/item/stack/sheet/metal = 14,
			/obj/item/stack/sheet/mineral/silver = 6
		),
		"total_work" = 40,
		"desc" = "14 Metal + 6 Silver -> Assault Rifle (2-round burst)",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "improved_clan_arms"
	)

	recipes["Veteran Assault Rifle"] = list(
		"result" = /obj/item/gun/ballistic/automatic/clan_rifle/assault,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_VETERAN,
		"materials" = list(
			/obj/item/stack/sheet/metal = 16,
			/obj/item/stack/sheet/mineral/silver = 8,
			/obj/item/stack/sheet/mineral/gold = 5
		),
		"total_work" = 55,
		"desc" = "16 Metal + 8 Silver + 5 Gold -> Veteran Assault Rifle",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "veteran_clan_arms"
	)

	recipes["Elite Assault Rifle"] = list(
		"result" = /obj/item/gun/ballistic/automatic/clan_rifle/assault,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_ELITE,
		"materials" = list(
			/obj/item/stack/sheet/metal = 20,
			/obj/item/stack/sheet/mineral/silver = 10,
			/obj/item/stack/sheet/mineral/gold = 7,
			/obj/item/stack/sheet/mineral/diamond = 4
		),
		"total_work" = 70,
		"desc" = "20 Metal + 10 Silver + 7 Gold + 4 Diamond -> Elite Assault Rifle",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "elite_clan_arms"
	)

	// --- Compact SMG (T3-T5) ---

	recipes["Compact SMG"] = list(
		"result" = /obj/item/gun/ballistic/automatic/pistol/clan/compact_smg,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_REGULAR,
		"materials" = list(
			/obj/item/stack/sheet/metal = 7,
			/obj/item/stack/sheet/mineral/silver = 3
		),
		"total_work" = 25,
		"desc" = "7 Metal + 3 Silver -> Compact SMG (fast, concealable)",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "improved_clan_arms"
	)

	recipes["Veteran Compact SMG"] = list(
		"result" = /obj/item/gun/ballistic/automatic/pistol/clan/compact_smg,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_VETERAN,
		"materials" = list(
			/obj/item/stack/sheet/metal = 9,
			/obj/item/stack/sheet/mineral/silver = 5,
			/obj/item/stack/sheet/mineral/gold = 2
		),
		"total_work" = 35,
		"desc" = "9 Metal + 5 Silver + 2 Gold -> Veteran Compact SMG",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "veteran_clan_arms"
	)

	recipes["Elite Compact SMG"] = list(
		"result" = /obj/item/gun/ballistic/automatic/pistol/clan/compact_smg,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_ELITE,
		"materials" = list(
			/obj/item/stack/sheet/metal = 11,
			/obj/item/stack/sheet/mineral/silver = 7,
			/obj/item/stack/sheet/mineral/gold = 4,
			/obj/item/stack/sheet/mineral/diamond = 2
		),
		"total_work" = 50,
		"desc" = "11 Metal + 7 Silver + 4 Gold + 2 Diamond -> Elite Compact SMG",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "elite_clan_arms"
	)

	// --- Pump Shotgun (T2-T5) ---

	recipes["Militia Pump Shotgun"] = list(
		"result" = /obj/item/gun/ballistic/shotgun/clan_pump,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_MILITIA,
		"materials" = list(
			/obj/item/stack/sheet/metal = 8,
			/obj/item/stack/sheet/mineral/wood = 3
		),
		"total_work" = 25,
		"desc" = "8 Metal + 3 Wood -> Militia Pump Shotgun",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "clan_arms"
	)

	recipes["Pump Shotgun"] = list(
		"result" = /obj/item/gun/ballistic/shotgun/clan_pump,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_REGULAR,
		"materials" = list(
			/obj/item/stack/sheet/metal = 12,
			/obj/item/stack/sheet/mineral/silver = 5
		),
		"total_work" = 35,
		"desc" = "12 Metal + 5 Silver -> Pump Shotgun",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "improved_clan_arms"
	)

	recipes["Veteran Pump Shotgun"] = list(
		"result" = /obj/item/gun/ballistic/shotgun/clan_pump,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_VETERAN,
		"materials" = list(
			/obj/item/stack/sheet/metal = 15,
			/obj/item/stack/sheet/mineral/silver = 8,
			/obj/item/stack/sheet/mineral/gold = 4
		),
		"total_work" = 50,
		"desc" = "15 Metal + 8 Silver + 4 Gold -> Veteran Pump Shotgun",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "veteran_clan_arms"
	)

	recipes["Elite Pump Shotgun"] = list(
		"result" = /obj/item/gun/ballistic/shotgun/clan_pump,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_ELITE,
		"materials" = list(
			/obj/item/stack/sheet/metal = 18,
			/obj/item/stack/sheet/mineral/silver = 10,
			/obj/item/stack/sheet/mineral/gold = 7,
			/obj/item/stack/sheet/mineral/diamond = 4
		),
		"total_work" = 70,
		"desc" = "18 Metal + 10 Silver + 7 Gold + 4 Diamond -> Elite Pump Shotgun",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "elite_clan_arms"
	)

	// --- Combat Shotgun (T4-T5) ---

	recipes["Combat Shotgun"] = list(
		"result" = /obj/item/gun/ballistic/shotgun/clan_pump/combat,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_VETERAN,
		"materials" = list(
			/obj/item/stack/sheet/metal = 18,
			/obj/item/stack/sheet/mineral/silver = 8,
			/obj/item/stack/sheet/mineral/gold = 5
		),
		"total_work" = 55,
		"desc" = "18 Metal + 8 Silver + 5 Gold -> Combat Shotgun (semi-auto, 15 shells)",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "veteran_clan_arms"
	)

	recipes["Elite Combat Shotgun"] = list(
		"result" = /obj/item/gun/ballistic/shotgun/clan_pump/combat,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_ELITE,
		"materials" = list(
			/obj/item/stack/sheet/metal = 22,
			/obj/item/stack/sheet/mineral/silver = 12,
			/obj/item/stack/sheet/mineral/gold = 8,
			/obj/item/stack/sheet/mineral/diamond = 5
		),
		"total_work" = 80,
		"desc" = "22 Metal + 12 Silver + 8 Gold + 5 Diamond -> Elite Combat Shotgun",
		"category" = CRAFT_CAT_RANGED,
		"research_required" = "elite_clan_arms"
	)

	// --- Shotgun Shells ---

	recipes["Militia Shotgun Shells"] = list(
		"result" = /obj/item/ammo_box/clan_shotgun_ammo,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_MILITIA,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3,
			/obj/item/stack/sheet/mineral/coal = 2
		),
		"total_work" = 12,
		"desc" = "3 Metal + 2 Coal -> 20 Militia Shotgun Shells",
		"category" = CRAFT_CAT_AMMO,
		"research_required" = "clan_arms"
	)

	recipes["Shotgun Shells"] = list(
		"result" = /obj/item/ammo_box/clan_shotgun_ammo,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_REGULAR,
		"materials" = list(
			/obj/item/stack/sheet/metal = 3,
			/obj/item/stack/sheet/mineral/coal = 2
		),
		"total_work" = 12,
		"desc" = "3 Metal + 2 Coal -> 20 Shotgun Shells",
		"category" = CRAFT_CAT_AMMO,
		"research_required" = "improved_clan_arms"
	)

	recipes["Veteran Shotgun Shells"] = list(
		"result" = /obj/item/ammo_box/clan_shotgun_ammo,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_VETERAN,
		"materials" = list(
			/obj/item/stack/sheet/metal = 4,
			/obj/item/stack/sheet/mineral/coal = 3
		),
		"total_work" = 15,
		"desc" = "4 Metal + 3 Coal -> 20 Veteran Shotgun Shells",
		"category" = CRAFT_CAT_AMMO,
		"research_required" = "veteran_clan_arms"
	)

	recipes["Elite Shotgun Shells"] = list(
		"result" = /obj/item/ammo_box/clan_shotgun_ammo,
		"result_amount" = 1,
		"rarity" = CLAN_RARITY_ELITE,
		"materials" = list(
			/obj/item/stack/sheet/metal = 5,
			/obj/item/stack/sheet/mineral/coal = 4
		),
		"total_work" = 18,
		"desc" = "5 Metal + 4 Coal -> 20 Elite Shotgun Shells",
		"category" = CRAFT_CAT_AMMO,
		"research_required" = "elite_clan_arms"
	)

#undef CRAFT_CAT_MELEE
#undef CRAFT_CAT_RANGED
#undef CRAFT_CAT_AMMO
#undef CRAFT_CAT_FAITH_WEAPONS
