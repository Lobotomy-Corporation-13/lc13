// Assoc list. NameCategory = Type
// Items are added here on abnormality datum spawn
GLOBAL_LIST_EMPTY(ego_datums)

/* EGO datums for purchase */
/* When adding a new datum here - try to keep it consistent with ego_weapons and ego_gear folders/files */

/datum/ego_datum
	/// If empty - will use name of the item
	var/name = null
	/// Simple 'category' of the weapon to display, i.e. "Weapon" or "Armor"
	var/item_category = "N/A"
	/// Path to the item
	var/obj/item/item_path
	/// Cost in PE boxes
	var/cost = 999
	// I hope this will be temporary...
	var/datum/abnormality/linked_abno
	/// All the data needed for displaying information on EGO console
	var/list/information = list()
	/// Can we get this from the well
	var/well_enabled = TRUE
	/// Anything that could break the test range should have this set to TRUE (won't be spawnable there)
	var/testrange_blacklisted = FALSE
	/// A list of tags.
	var/list/ego_tags = list()
	/// The origin of this EGO. Could basically only possibly be "LC13" (basegame EGO, even community EGO), "City" (CoL and input gear) or "Branch 12"
	var/origin = "LC13"

/datum/ego_datum/New(datum/abnormality/DA)
	if(!name && item_path)
		name = initial(item_path.name)
		information["name"] = name
	if(DA)
		linked_abno = DA


/datum/ego_datum/Destroy()
	GLOB.ego_datums -= src
	return ..()

/datum/ego_datum/proc/PrintOutInfo()
	return

/datum/ego_datum/proc/CostToThreatClass()
	switch(cost)
		if(0 to 9) // ???
			return 0
		if(10 to 19) // LC13 ZAYINs are 12 but B12 are 10
			return ZAYIN_LEVEL
		if(20 to 34)
			return TETH_LEVEL
		if(35 to 49)
			return HE_LEVEL
		if(50 to 99)
			return WAW_LEVEL
		if(100 to INFINITY)
			return ALEPH_LEVEL
		else
			return 0

// Because I'm lazy to type it all
/datum/ego_datum/weapon
	item_category = "Weapon"

// I'm reworking the structure of this override because the old one was inauspicious.
// 1. We instantiate the EGO weapon and add all the common information that all EGO weapons share
// 2. We perform istype checks for subtypes and add specific information in each case
/datum/ego_datum/weapon/New(datum/abnormality/DA)
	. = ..()
	if(!ispath(item_path, /obj/item/ego_weapon))
		return

	var/obj/item/ego_weapon/E = new item_path(src)

	// Filling out Information. This is a list that contains a bunch of stuff we'd like to pass into interfaces so we can display it on the EGO Purchase Console and the EGO Printer.

	// Firstly, generic data that all weapons should have and isn't specific to its purpose.
	information["description"] = E.desc
	information["special"] = E.special
	information["attribute_requirements"] = E.attribute_requirements.Copy()

	// Now for melee stats. All weapons have melee stats, so all weapon datums need to have this info.
	// Melee damage dealt.
	information["force_melee"] = E.force
	// Melee damage type: Account for the Shuffler.
	var/damage_type = E.damtype
	var/damage = E.force
	if(GLOB.damage_type_shuffler?.is_enabled && IsColorDamageType(damage_type))
		var/datum/damage_type_shuffler/shuffler = GLOB.damage_type_shuffler
		var/new_damage_type = shuffler.mapping_offense[damage_type]
		damage_type = new_damage_type
	information["damtype_melee"] = damage_type
	// String used to explain the damage dealt by this weapon. Gets overridden in Ranged weapons by one referring to its bullets.
	information["attack_info"] = "It deals [damage] [damage_type] damage."

	// Damage dealt when thrown.
	information["throwforce"] = E.throwforce

	// Melee reach in tiles
	information["reach"] = E.reach
	// Self-stun time on hit. Usually for spears, some unwieldy weapons like Sanguine Desire also have it.
	information["stuntime"] = E.stuntime

	// Melee attack speed, both a text description and a numeric value.
	information["numeric_melee_attack_speed"] = E.attack_speed
	if(E.attack_speed < 0.4)
		information["melee_attack_speed"] = "Very fast"
	else if(E.attack_speed<0.7)
		information["melee_attack_speed"] = "Fast"
	else if(E.attack_speed<1)
		information["melee_attack_speed"] = "Somewhat fast"
	else if(E.attack_speed == 1)
		information["melee_attack_speed"] = "Normal"
	else if(E.attack_speed<1.5)
		information["melee_attack_speed"] = "Somewhat slow"
	else if(E.attack_speed<2)
		information["melee_attack_speed"] = "Slow"
	else if(E.attack_speed>=2)
		information["melee_attack_speed"] = "Extremely slow"

	// Tags: used for easy filtering in certain interfaces.
	if(E.reach > 1)
		ego_tags |= EGO_TAG_REACH
	if(E.knockback > 0)
		ego_tags |= EGO_TAG_KNOCKBACK
	if(E.throwforce >= 10)
		ego_tags |= EGO_TAG_THROWING
	if(item_path in GLOB.small_ego)
		ego_tags |= EGO_TAG_MINI

	// Now we arrive at a junction point, where we check the subtype of the weapon we instantiated. Some of these subtypes need extra tags and/or information.

	// Weapon is a shield: tag it with EGO_TAG_GUARD and send info related to its guard stats
	if(istype(E, /obj/item/ego_weapon/shield))
		var/obj/item/ego_weapon/shield/E_shield = E
		ego_tags |= EGO_TAG_GUARD
		// Storing the resistances as an integer... some info is lost here, I fear, but that's just me deciding showing IV or X or -V will be friendlier than 30 or 95. Honestly feel free to change it and the TGUI accordingly if you want
		information["guard_resistances"] = list()
		information["guard_resistances"]["red"] = (floor(E_shield.reductions[1] * 0.1))
		information["guard_resistances"]["white"] = (floor(E_shield.reductions[2] * 0.1))
		information["guard_resistances"]["black"] = (floor(E_shield.reductions[3] * 0.1))
		information["guard_resistances"]["pale"] = (floor(E_shield.reductions[4] * 0.1))
		information["guard_cooldown"] = E_shield.block_cooldown
		information["guard_duration"] = E_shield.block_duration
		information["guard_debuff_duration"] = E_shield.debuff_duration

	// Weapon is a lance: tag it with EGO_TAG_MOBILITY
	else if(istype(E, /obj/item/ego_weapon/lance))
		ego_tags |= EGO_TAG_MOBILITY

	// Weapon is a gun: tag it with EGO_TAG_RANGED and add info about its ranged stats
	else if(ispath(item_path, /obj/item/ego_weapon/ranged))
		var/obj/item/ego_weapon/ranged/E_gun = E

		ego_tags |= EGO_TAG_RANGED
		if(E_gun.pellets > 1)
			ego_tags |= EGO_TAG_MULTIHIT

		// Bullet damage
		information["force_ranged"] = E_gun.last_projectile_damage
		// Magsize; can be 0 for infinite
		information["magazine_size"] = E_gun.shotsleft
		// Bullets fired per shot. 1 for most weapons, higher for shotguns
		information["pellets"] = E_gun.pellets
		// Bullet damtype: account for the shuffler.
		var/bullet_damage_type = E_gun.last_projectile_type
		var/bullet_damage = E_gun.last_projectile_damage
		if(GLOB.damage_type_shuffler?.is_enabled && IsColorDamageType(bullet_damage_type))
			var/datum/damage_type_shuffler/shuffler = GLOB.damage_type_shuffler
			var/new_damage_type = shuffler.mapping_offense[bullet_damage_type]
			bullet_damage_type = new_damage_type
		information["damtype_ranged"] = bullet_damage_type
		// Fire rate
		var/fire_delay = E_gun.fire_delay
		if(E_gun.autofire)
			fire_delay = E_gun.autofire * 0.75
		information["numeric_ranged_attack_speed"] = fire_delay
		switch(fire_delay)
			if(0 to 5)
				information["ranged_attack_speed"] = "Fast"
			if(6 to 10)
				information["ranged_attack_speed"] = "Normal"
			if(11 to 15)
				information["ranged_attack_speed"] = "Somewhat slow"
			if(16 to 20)
				information["ranged_attack_speed"] = "Slow"
			else
				information["ranged_attack_speed"] = "Extremely slow"
		// Override the attack info string.
		information["attack_info"] = "Its bullets deal [bullet_damage] [bullet_damage_type] damage."

	qdel(E)

/datum/ego_datum/weapon/PrintOutInfo()
	var/dat = "[capitalize(name)]<br><br>"
	if(LAZYLEN(information["attribute_requirements"]))
		dat += "Attribute requirements:<br>"
		for(var/attr in information["attribute_requirements"])
			dat += "- [attr]: [information["attribute_requirements"][attr]]<br>"
		dat += "<hr>"
	dat += "[information["attack_info"]]<br>"
	if("special" in information)
		dat += "[information["special"]]<br>"
	dat += "Melee attack speed: [information["melee_attack_speed"]].<br>"
	if(ispath(item_path, /obj/item/ego_weapon/ranged))
		dat += "Ranged attack speed: [information["ranged_attack_speed"]].<br>"
	else if(ispath(item_path, /obj/item/ego_weapon))
		if(information["throwforce"] > 0)
			dat += "Throw force: [information["throwforce"]].<br>"
		if(information["reach"] > 1)
			dat += "This weapon has a reach of [information["reach"]].<br>"
	return dat

/datum/ego_datum/armor
	item_category = "Armor"

/datum/ego_datum/armor/New(datum/abnormality/DA)
	. = ..()
	if(!ispath(item_path, /obj/item/clothing/suit/armor/ego_gear))
		return
	var/obj/item/clothing/suit/armor/ego_gear/E = new item_path(src)

	if(E.slowdown && E.slowdown < 0)
		ego_tags |= EGO_TAG_MOBILITY

	if(istype(E, /obj/item/clothing/suit/armor/ego_gear/realization))
		var/obj/item/clothing/suit/armor/ego_gear/realization/E_realization = E
		ego_tags |= EGO_TAG_REALIZED
		if(E_realization.assimilation_ability)
			ego_tags |= EGO_TAG_ASSIMILATION
		if(E_realization.realized_ability)
			information["ability"] = list("name" = E_realization.realized_ability.name, "desc" = E_realization.realized_ability.desc, "cooldown" = E_realization.realized_ability.cooldown_time)

	information["armor"] = list()
	information["description"] = E.desc
	var/red_armor = E.armor.red
	var/white_armor = E.armor.white
	var/black_armor = E.armor.black
	var/pale_armor = E.armor.pale
	if(GLOB.damage_type_shuffler?.is_enabled)
		var/list/mapping = GLOB.damage_type_shuffler.mapping_defense
		red_armor = E.armor.getRating(mapping[RED_DAMAGE])
		white_armor = E.armor.getRating(mapping[WHITE_DAMAGE])
		black_armor = E.armor.getRating(mapping[BLACK_DAMAGE])
		pale_armor = E.armor.getRating(mapping[PALE_DAMAGE])
	information["armor"][RED_DAMAGE] = E.armor_to_protection_class(red_armor)
	information["armor"][WHITE_DAMAGE] = E.armor_to_protection_class(white_armor)
	information["armor"][BLACK_DAMAGE] = E.armor_to_protection_class(black_armor)
	information["armor"][PALE_DAMAGE] = E.armor_to_protection_class(pale_armor)
	information["attribute_requirements"] = E.attribute_requirements.Copy()
	qdel(E)

/datum/ego_datum/armor/PrintOutInfo()
	var/dat = "[capitalize(name)]<br><br>"
	if(LAZYLEN(information["attribute_requirements"]))
		dat += "Attribute requirements:<br>"
		for(var/attr in information["attribute_requirements"])
			dat += "- [attr]: [information["attribute_requirements"][attr]]<br>"
		dat += "<hr>"
	dat += "Armor:<br>"
	for(var/armor_type in information["armor"])
		if(!(information["armor"][armor_type])) // Zero armor and such
			continue
		dat += "- [capitalize(armor_type)]: [information["armor"][armor_type]].<br>"
	dat += "<br>"
	return dat
