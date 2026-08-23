/// Palermitan Debug Kit - spawnable item for testing the apprentice system.
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
		"Grant Skill Tree Action",
		"Spawn Gear Set",
		"Set Weapon Tier",
		"Set Armor Tier",
		"Set Attribute Level",
		"--- Duel Testing ---",
		"Spawn Duel Dummy",
		"Force Start Duel vs Dummy",
		"Simulate Duel Win",
		"Simulate Duel Loss",
		"Simulate Loss + Correction",
		"--- Role Passives ---",
		"Add Role Passive",
		"--- Nursefather ---",
		"Simulate Drink EXP",
		"Simulate Glass Bottle EXP",
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
		if("Grant Skill Tree Action")
			debug_grant_tree_action(H)
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
		if("Add Role Passive")
			debug_add_role_passive(H)
		if("Simulate Loss + Correction")
			debug_simulate_correction(H)
		if("Simulate Drink EXP")
			debug_simulate_drink(H)
		if("Simulate Glass Bottle EXP")
			debug_simulate_glass(H)
		if("Reset All")
			debug_reset_all(H)

/obj/item/palermitan_debug_kit/proc/debug_full_setup(mob/living/carbon/human/H)
	debug_grant_passives(H)
	debug_grant_exp(H)
	debug_grant_duel_action(H)
	debug_grant_tree_action(H)
	debug_set_attributes_value(H, 40)
	debug_spawn_gear(H)
	to_chat(H, span_boldnotice("Palermitan Debug: Full setup complete. Passives, EXP, duel action, skill tree, gear, and 40 attributes."))

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

/obj/item/palermitan_debug_kit/proc/debug_grant_tree_action(mob/living/carbon/human/H)
	for(var/datum/action/innate/palermitan_tree/existing in H.actions)
		to_chat(H, span_warning("Already has skill tree action."))
		return
	var/datum/action/innate/palermitan_tree/tree_action = new()
	tree_action.Grant(H)
	to_chat(H, span_notice("Palermitan Debug: Skill tree action granted."))

/obj/item/palermitan_debug_kit/proc/debug_simulate_correction(mob/living/carbon/human/H)
	// Ensure components exist
	if(!H.GetComponent(/datum/component/palermitan_apprentice))
		H.AddComponent(/datum/component/palermitan_apprentice)
	if(!H.GetComponent(/datum/component/palermitan_exp))
		H.AddComponent(/datum/component/palermitan_exp)
	// Simulate a duel loss first (for attribute calculation)
	var/turf/T = get_turf(H)
	var/mob/living/simple_animal/hostile/palermitan_dummy/D = new(T)
	var/datum/thumb_duel/temp_duel = new(H, D)
	temp_duel.grant_duel_rewards(D, H)
	qdel(temp_duel)
	qdel(D)
	// Now spawn a nursefather dummy and perform the correction
	var/datum/component/palermitan_apprentice/pal = H.GetComponent(/datum/component/palermitan_apprentice)
	if(!pal)
		return
	// Force correction eligibility
	pal.correction_eligible = TRUE
	pal.correction_deadline = world.time + 5 MINUTES
	if(pal.potential_correction_attrs <= 0)
		pal.potential_correction_attrs = 3
	// Spawn nursefather dummy adjacent
	var/turf/nurse_turf = get_step(H, H.dir)
	if(!nurse_turf)
		nurse_turf = get_turf(H)
	var/mob/living/simple_animal/hostile/palermitan_dummy/nurse = new(nurse_turf)
	nurse.name = "Ex Thumb Sottocapo"
	nurse.maxHealth = 9999
	nurse.health = 9999
	// Run correction animation
	pal.perform_correction(nurse)
	// Clean up dummy after animation
	QDEL_IN(nurse, 6 SECONDS)
	to_chat(H, span_boldwarning("Palermitan Debug: Simulated duel loss + correction (count: [pal.correction_count])."))

/obj/item/palermitan_debug_kit/proc/debug_simulate_drink(mob/living/carbon/human/H)
	var/datum/component/palermitan_apprentice/pal = H.GetComponent(/datum/component/palermitan_apprentice)
	if(!pal)
		to_chat(H, span_warning("No base passives component. Grant it first."))
		return
	pal.grant_drink_exp()

/obj/item/palermitan_debug_kit/proc/debug_simulate_glass(mob/living/carbon/human/H)
	var/datum/component/palermitan_apprentice/pal = H.GetComponent(/datum/component/palermitan_apprentice)
	if(!pal)
		to_chat(H, span_warning("No base passives component. Grant it first."))
		return
	if(!H.GetComponent(/datum/component/palermitan_exp))
		H.AddComponent(/datum/component/palermitan_exp)
	if(world.time < pal.last_glass_exp_time + 30 SECONDS)
		to_chat(H, span_warning("Glass bottle EXP is on cooldown."))
		return
	pal.last_glass_exp_time = world.time
	var/datum/component/palermitan_exp/exp_comp = H.GetComponent(/datum/component/palermitan_exp)
	if(exp_comp)
		exp_comp.modify_exp(3)
	to_chat(H, span_notice("Palermitan Debug: Simulated glass bottle impact. (+3 EXP)"))

/// Role name -> passive component type path mapping
/obj/item/palermitan_debug_kit/proc/get_role_passive_types()
	return list(
		"Butcher" = /datum/component/palermitan_role_passive/butcher,
		"Blade Lineage" = /datum/component/palermitan_role_passive/blade_lineage,
		"Thumb" = /datum/component/palermitan_role_passive/thumb,
		"Kurokumo" = /datum/component/palermitan_role_passive/kurokumo,
		"Index" = /datum/component/palermitan_role_passive/index,
		"Insurgence" = /datum/component/palermitan_role_passive/insurgence,
		"Middle" = /datum/component/palermitan_role_passive/middle,
		"N-Corp" = /datum/component/palermitan_role_passive/ncorp,
		"Rat" = /datum/component/palermitan_role_passive/rat,
		"Carnival" = /datum/component/palermitan_role_passive/carnival,
		"Zwei" = /datum/component/palermitan_role_passive/zwei,
		"Seven" = /datum/component/palermitan_role_passive/seven,
		"Dieci" = /datum/component/palermitan_role_passive/dieci,
		"Cinq" = /datum/component/palermitan_role_passive/cinq,
		"Shi" = /datum/component/palermitan_role_passive/shi,
		"Liu" = /datum/component/palermitan_role_passive/liu,
		"Devyat" = /datum/component/palermitan_role_passive/devyat,
		"Hana" = /datum/component/palermitan_role_passive/hana,
	)

/obj/item/palermitan_debug_kit/proc/debug_add_role_passive(mob/living/carbon/human/H)
	var/list/role_types = get_role_passive_types()
	var/role_name = tgui_input_list(H, "Which role passive?", "Role Passive", role_types)
	if(!role_name)
		return
	var/tier_str = tgui_input_list(H, "Set tier:", "Passive Tier", list("1", "2", "3"))
	if(!tier_str)
		return
	var/new_tier = text2num(tier_str)
	var/passive_type = role_types[role_name]
	// Remove existing passive of this type if any
	var/datum/component/palermitan_role_passive/existing = locate(passive_type) in H.GetComponents(/datum/component/palermitan_role_passive)
	if(existing)
		qdel(existing)
	// Add new passive at the selected tier
	H.AddComponent(passive_type, new_tier)
	// Also update the EXP component's duel count to match
	var/datum/component/palermitan_exp/exp_comp = H.GetComponent(/datum/component/palermitan_exp)
	if(exp_comp)
		var/required_duels = 1
		if(new_tier >= 3)
			required_duels = 5
		else if(new_tier >= 2)
			required_duels = 3
		exp_comp.role_duel_counts[role_name] = required_duels
	to_chat(H, span_notice("Palermitan Debug: [role_name] passive granted at tier [new_tier]."))

/obj/item/palermitan_debug_kit/proc/debug_reset_all(mob/living/carbon/human/H)
	// Remove components
	var/datum/component/palermitan_apprentice/pal = H.GetComponent(/datum/component/palermitan_apprentice)
	if(pal)
		qdel(pal)
	var/datum/component/palermitan_exp/exp = H.GetComponent(/datum/component/palermitan_exp)
	if(exp)
		qdel(exp)
	// Remove all palermitan skill components
	for(var/datum/component/palermitan_skill/skill in H.GetComponents(/datum/component/palermitan_skill))
		qdel(skill)
	// Remove all role passive components
	for(var/datum/component/palermitan_role_passive/passive in H.GetComponents(/datum/component/palermitan_role_passive))
		qdel(passive)
	// Remove actions
	for(var/datum/action/innate/thumb_duel_challenge/act in H.actions)
		qdel(act)
	for(var/datum/action/innate/palermitan_tree/act in H.actions)
		qdel(act)
	for(var/datum/action/innate/sezionatura_activate/act in H.actions)
		qdel(act)
	// End any active debug duel
	if(active_debug_duel?.active)
		active_debug_duel.cleanup()
		QDEL_NULL(active_debug_duel)
	to_chat(H, span_notice("Palermitan Debug: All components, skills, passives, and actions removed."))
