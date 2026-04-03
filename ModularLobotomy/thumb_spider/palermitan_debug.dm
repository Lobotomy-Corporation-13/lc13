/// Palermitan Debug Kit — spawnable item for testing the apprentice system.
/// Spawn from object spawner by searching "palermitan debug".
/// Use in-hand OR alt-click from pocket/belt/backpack to open the menu.
/obj/item/palermitan_debug_kit
	name = "palermitan debug kit"
	desc = "A debug tool for testing the Thumb Apprentice Palermitan Style system. Use in-hand or alt-click to open the menu."
	icon = 'icons/obj/device.dmi'
	icon_state = "hypertool"
	w_class = WEIGHT_CLASS_TINY
	slot_flags = ITEM_SLOT_LPOCKET | ITEM_SLOT_RPOCKET | ITEM_SLOT_BELT

/obj/item/palermitan_debug_kit/attack_self(mob/living/user)
	. = ..()
	open_debug_menu(user)

/obj/item/palermitan_debug_kit/AltClick(mob/user)
	. = ..()
	open_debug_menu(user)

/obj/item/palermitan_debug_kit/proc/open_debug_menu(mob/user)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user

	var/list/options = list(
		"Full Setup",
		"Grant Base Passives",
		"Remove Base Passives",
		"Spawn Gear Set",
		"Set Weapon Tier",
		"Set Armor Tier",
		"Set Attribute Level",
		"--- (separator) ---",
	)

	var/choice = tgui_input_list(H, "Palermitan Debug Kit", "Debug Menu", options)
	if(!choice || choice == "--- (separator) ---")
		return

	switch(choice)
		if("Full Setup")
			debug_full_setup(H)
		if("Grant Base Passives")
			debug_grant_passives(H)
		if("Remove Base Passives")
			debug_remove_passives(H)
		if("Spawn Gear Set")
			debug_spawn_gear(H)
		if("Set Weapon Tier")
			debug_set_weapon_tier(H)
		if("Set Armor Tier")
			debug_set_armor_tier(H)
		if("Set Attribute Level")
			debug_set_attributes(H)

/obj/item/palermitan_debug_kit/proc/debug_full_setup(mob/living/carbon/human/H)
	// Grant base passives
	debug_grant_passives(H)
	// Set attributes to 40
	debug_set_attributes_value(H, 40)
	// Spawn gear
	debug_spawn_gear(H)
	to_chat(H, span_boldnotice("Palermitan Debug: Full setup complete. Attributes set to 40, gear spawned, base passives granted."))

/obj/item/palermitan_debug_kit/proc/debug_grant_passives(mob/living/carbon/human/H)
	if(H.GetComponent(/datum/component/palermitan_apprentice))
		to_chat(H, span_warning("Already has base passives."))
		return
	H.AddComponent(/datum/component/palermitan_apprentice)
	to_chat(H, span_notice("Palermitan Debug: Base passives (Duello + Palermitan Style) granted."))

/obj/item/palermitan_debug_kit/proc/debug_remove_passives(mob/living/carbon/human/H)
	var/datum/component/palermitan_apprentice/comp = H.GetComponent(/datum/component/palermitan_apprentice)
	if(!comp)
		to_chat(H, span_warning("No base passives to remove."))
		return
	qdel(comp)
	to_chat(H, span_notice("Palermitan Debug: Base passives removed."))

/obj/item/palermitan_debug_kit/proc/debug_spawn_gear(mob/living/carbon/human/H)
	var/turf/T = get_turf(H)
	new /obj/item/clothing/suit/armor/ego_gear/city/thumb_spider/apprentice(T)
	new /obj/item/ego_weapon/city/thumbapprentice_katana(T)
	new /obj/item/ego_weapon/city/thumbapprentice_greatsword(T)
	to_chat(H, span_notice("Palermitan Debug: Tier 1 armor + katana + greatsword spawned at your feet."))

/obj/item/palermitan_debug_kit/proc/debug_set_weapon_tier(mob/living/carbon/human/H)
	var/new_tier = tgui_input_list(H, "Set weapon tier", "Weapon Tier", list("1", "2", "3", "4"))
	if(!new_tier)
		return
	new_tier = text2num(new_tier)
	// GetAllContents() covers held items, backpack, pockets, belt, etc.
	for(var/obj/item/ego_weapon/city/thumbapprentice_katana/K in H.GetAllContents())
		K.set_tier(new_tier)
	for(var/obj/item/ego_weapon/city/thumbapprentice_greatsword/G in H.GetAllContents())
		G.set_tier(new_tier)
	to_chat(H, span_notice("Palermitan Debug: Weapon tier set to [new_tier]. Dual-wield threshold: [new_tier >= 4 ? "every hit" : (new_tier >= 2 ? "every 2nd hit" : "disabled")]"))

/obj/item/palermitan_debug_kit/proc/debug_set_armor_tier(mob/living/carbon/human/H)
	var/new_tier = tgui_input_list(H, "Set armor tier", "Armor Tier", list("1", "2", "3", "4"))
	if(!new_tier)
		return
	new_tier = text2num(new_tier)
	// Check worn armor
	var/obj/item/clothing/suit/armor/ego_gear/city/thumb_spider/apprentice/worn = H.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(istype(worn))
		worn.set_tier(new_tier)
	// Check held/inventory
	for(var/obj/item/clothing/suit/armor/ego_gear/city/thumb_spider/apprentice/A in H.GetAllContents())
		A.set_tier(new_tier)
	to_chat(H, span_notice("Palermitan Debug: Armor tier set to [new_tier]."))

/obj/item/palermitan_debug_kit/proc/debug_set_attributes(mob/living/carbon/human/H)
	var/new_level = tgui_input_list(H, "Set all attributes to:", "Attribute Level", list("40", "60", "80", "100", "120", "150", "200"))
	if(!new_level)
		return
	new_level = text2num(new_level)
	debug_set_attributes_value(H, new_level)
	to_chat(H, span_notice("Palermitan Debug: All attributes set to [new_level]."))

/obj/item/palermitan_debug_kit/proc/debug_set_attributes_value(mob/living/carbon/human/H, value)
	H.set_attribute_limit(200)
	var/datum/attribute/fort = H.attributes[FORTITUDE_ATTRIBUTE]
	var/datum/attribute/prud = H.attributes[PRUDENCE_ATTRIBUTE]
	var/datum/attribute/temp = H.attributes[TEMPERANCE_ATTRIBUTE]
	var/datum/attribute/just = H.attributes[JUSTICE_ATTRIBUTE]
	if(fort)
		fort.level = value
		fort.on_update(H)
	if(prud)
		prud.level = value
		prud.on_update(H)
	if(temp)
		temp.level = value
		temp.on_update(H)
	if(just)
		just.level = value
		just.on_update(H)
