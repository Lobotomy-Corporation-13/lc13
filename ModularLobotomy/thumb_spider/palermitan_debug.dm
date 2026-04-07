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
	/// Reference to an active duel started by this debug kit
	var/datum/thumb_duel/active_debug_duel

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
		"Grant EXP Component",
		"Add EXP",
		"Grant Duel Action",
		"Spawn Gear Set",
		"Set Weapon Tier",
		"Set Armor Tier",
		"Set Attribute Level",
		"--- Duel Testing ---",
		"Spawn Duel Dummy",
		"Force Start Duel vs Dummy",
		"Simulate Duel Win",
		"Simulate Duel Loss",
		"--- Reset ---",
		"Reset All",
	)

	var/choice = tgui_input_list(H, "Palermitan Debug Kit", "Debug Menu", options)
	if(!choice || findtext(choice, "---"))
		return

	switch(choice)
		if("Full Setup")
			debug_full_setup(H)
		if("Grant Base Passives")
			debug_grant_passives(H)
		if("Remove Base Passives")
			debug_remove_passives(H)
		if("Grant EXP Component")
			debug_grant_exp(H)
		if("Add EXP")
			debug_add_exp(H)
		if("Grant Duel Action")
			debug_grant_duel_action(H)
		if("Spawn Gear Set")
			debug_spawn_gear(H)
		if("Set Weapon Tier")
			debug_set_weapon_tier(H)
		if("Set Armor Tier")
			debug_set_armor_tier(H)
		if("Set Attribute Level")
			debug_set_attributes(H)
		if("Spawn Duel Dummy")
			debug_spawn_dummy(H)
		if("Force Start Duel vs Dummy")
			debug_force_duel(H)
		if("Simulate Duel Win")
			debug_simulate_duel(H, TRUE)
		if("Simulate Duel Loss")
			debug_simulate_duel(H, FALSE)
		if("Reset All")
			debug_reset_all(H)

/obj/item/palermitan_debug_kit/proc/debug_full_setup(mob/living/carbon/human/H)
	debug_grant_passives(H)
	debug_grant_exp(H)
	debug_grant_duel_action(H)
	debug_set_attributes_value(H, 40)
	debug_spawn_gear(H)
	to_chat(H, span_boldnotice("Palermitan Debug: Full setup complete. Passives, EXP, duel action, gear, and 40 attributes."))

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

/obj/item/palermitan_debug_kit/proc/debug_grant_exp(mob/living/carbon/human/H)
	if(H.GetComponent(/datum/component/palermitan_exp))
		to_chat(H, span_warning("Already has EXP component."))
		return
	H.AddComponent(/datum/component/palermitan_exp)
	to_chat(H, span_notice("Palermitan Debug: EXP component granted."))

/obj/item/palermitan_debug_kit/proc/debug_add_exp(mob/living/carbon/human/H)
	var/datum/component/palermitan_exp/exp_comp = H.GetComponent(/datum/component/palermitan_exp)
	if(!exp_comp)
		to_chat(H, span_warning("No EXP component. Grant it first."))
		return
	var/amount = tgui_input_list(H, "Add how much EXP?", "Add EXP", list("10", "20", "50", "100", "200", "500", "900"))
	if(!amount)
		return
	exp_comp.modify_exp(text2num(amount))

/obj/item/palermitan_debug_kit/proc/debug_grant_duel_action(mob/living/carbon/human/H)
	// Check if already has the action
	for(var/datum/action/innate/thumb_duel_challenge/existing in H.actions)
		to_chat(H, span_warning("Already has duel action."))
		return
	var/datum/action/innate/thumb_duel_challenge/duel_action = new()
	duel_action.Grant(H)
	to_chat(H, span_notice("Palermitan Debug: Duel challenge action granted."))

/obj/item/palermitan_debug_kit/proc/debug_spawn_dummy(mob/living/carbon/human/H)
	var/turf/T = get_step(H, H.dir)
	if(!T)
		T = get_turf(H)
	var/mob/living/simple_animal/hostile/palermitan_dummy/D = new(T)
	var/attr_str = tgui_input_list(H, "Dummy attribute level?", "Dummy Attributes", list("40", "60", "80", "100", "150", "200"))
	if(attr_str)
		D.fake_attributes = text2num(attr_str)
	to_chat(H, span_notice("Palermitan Debug: Duel dummy spawned with [D.fake_attributes] fake attributes."))

/obj/item/palermitan_debug_kit/proc/debug_force_duel(mob/living/carbon/human/H)
	// End any existing active duel first
	if(active_debug_duel?.active)
		active_debug_duel.end_duel(null, null, "cancelled by debug kit")
		active_debug_duel = null
	// Spawn a dummy and immediately start a duel
	var/turf/T = get_step(H, H.dir)
	if(!T)
		T = get_turf(H)
	var/mob/living/simple_animal/hostile/palermitan_dummy/D = new(T)
	// Make sure the apprentice has the base component
	if(!H.GetComponent(/datum/component/palermitan_apprentice))
		H.AddComponent(/datum/component/palermitan_apprentice)
	if(!H.GetComponent(/datum/component/palermitan_exp))
		H.AddComponent(/datum/component/palermitan_exp)
	active_debug_duel = new /datum/thumb_duel(H, D)
	active_debug_duel.start_duel()
	to_chat(H, span_notice("Palermitan Debug: Duel started vs dummy (attrs: [D.fake_attributes])."))

/obj/item/palermitan_debug_kit/proc/debug_simulate_duel(mob/living/carbon/human/H, won)
	// End any existing active duel first (cleans up walls, signals, etc.)
	if(active_debug_duel?.active)
		active_debug_duel.cleanup()
		QDEL_NULL(active_debug_duel)
	// Make sure the apprentice has components
	if(!H.GetComponent(/datum/component/palermitan_apprentice))
		H.AddComponent(/datum/component/palermitan_apprentice)
	if(!H.GetComponent(/datum/component/palermitan_exp))
		H.AddComponent(/datum/component/palermitan_exp)
	// Create a temporary dummy for reward calculation (doesn't start a real duel)
	var/turf/T = get_turf(H)
	var/mob/living/simple_animal/hostile/palermitan_dummy/D = new(T)
	// Use the reward proc directly without starting a duel
	var/datum/thumb_duel/temp_duel = new(H, D)
	if(won)
		temp_duel.grant_duel_rewards(H, D)
		to_chat(H, span_boldnotice("Palermitan Debug: Simulated duel WIN vs [D.fake_attributes]-attr opponent."))
	else
		temp_duel.grant_duel_rewards(D, H)
		to_chat(H, span_boldwarning("Palermitan Debug: Simulated duel LOSS vs [D.fake_attributes]-attr opponent."))
	// Clean up temp objects (temp_duel was never started so no walls/signals to clean)
	qdel(temp_duel)
	qdel(D)

/obj/item/palermitan_debug_kit/proc/debug_reset_all(mob/living/carbon/human/H)
	// Remove components
	var/datum/component/palermitan_apprentice/pal = H.GetComponent(/datum/component/palermitan_apprentice)
	if(pal)
		qdel(pal)
	var/datum/component/palermitan_exp/exp = H.GetComponent(/datum/component/palermitan_exp)
	if(exp)
		qdel(exp)
	// Remove duel action
	for(var/datum/action/innate/thumb_duel_challenge/act in H.actions)
		qdel(act)
	to_chat(H, span_notice("Palermitan Debug: All components and actions removed."))
