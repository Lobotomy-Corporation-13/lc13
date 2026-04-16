// Palermitan Skill Tree Datum
// 4 schools, 3 tiers each, 2 mutually exclusive choices per tier.
// Mirrors the Ring skill tree system exactly.

/datum/palermitan_skill_tree
	/// The mob viewing the skill tree
	var/mob/living/carbon/human/viewer

/datum/palermitan_skill_tree/New(mob/living/carbon/human/user)
	viewer = user

/datum/palermitan_skill_tree/Destroy()
	viewer = null
	return ..()

/datum/palermitan_skill_tree/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PalermitanSkillTree")
		ui.open()

/datum/palermitan_skill_tree/ui_state(mob/user)
	return GLOB.conscious_state

/datum/palermitan_skill_tree/ui_data(mob/user)
	var/list/data = list()

	var/datum/component/palermitan_exp/exp_comp = viewer.GetComponent(/datum/component/palermitan_exp)
	if(!exp_comp)
		return data

	data["exp"] = exp_comp.exp
	data["next_threshold"] = exp_comp.get_next_threshold()
	data["skill_points"] = exp_comp.skill_points
	data["skill_points_spent"] = exp_comp.skill_points_spent
	data["schools_invested"] = exp_comp.schools_invested
	data["max_schools"] = exp_comp.max_schools

	// Gear tier
	var/gear_tier = 1
	for(var/obj/item/ego_weapon/city/thumbapprentice_katana/K in viewer.GetAllContents())
		gear_tier = K.tier
		break
	data["gear_tier"] = gear_tier

	// All possible role passives with unlock status
	data["all_passives"] = get_all_passive_data(exp_comp)

	// Build school data
	data["schools"] = list()

	data["schools"] += list(list(
		"name" = "Terremoto",
		"id" = "terremoto",
		"desc" = "The path of the earthquake. Destabilize your prey with tremor, culminating in devastating tremor bursts.",
		"theme" = "Tremor application and burst. Tier 2 unlocks tremor bursting.",
		"tiers" = get_school_tiers("terremoto", exp_comp)
	))

	data["schools"] += list(list(
		"name" = "Incendio",
		"id" = "incendio",
		"desc" = "The path of the inferno. Burn the target down with escalating overheat.",
		"theme" = "Overheat application and scaling debuffs.",
		"tiers" = get_school_tiers("incendio", exp_comp)
	))

	data["schools"] += list(list(
		"name" = "Eleganza",
		"id" = "eleganza",
		"desc" = "The path of elegance. Build Poise for critical strikes and Concentration to sustain momentum.",
		"theme" = "Poise and Concentration. The refined swordsman.",
		"tiers" = get_school_tiers("eleganza", exp_comp)
	))

	data["schools"] += list(list(
		"name" = "Fondamenti",
		"id" = "fondamenti",
		"desc" = "The fundamentals of combat. Core improvements that benefit any build.",
		"theme" = "General offense and defense. No status specialization.",
		"tiers" = get_school_tiers("fondamenti", exp_comp)
	))

	return data

/datum/palermitan_skill_tree/proc/get_school_tiers(school_id, datum/component/palermitan_exp/exp_comp)
	var/list/tiers = list()
	var/list/skill_defs = GLOB.palermitan_skill_definitions[school_id]

	if(!skill_defs)
		return tiers

	for(var/tier_num in 1 to 3)
		var/list/tier_data = list(
			"tier" = tier_num,
			"cost" = tier_num,
			"choices" = list()
		)

		var/previous_completed = (tier_num == 1) || has_tier_completed(school_id, tier_num - 1)
		var/can_afford = exp_comp.skill_points >= tier_num
		var/can_invest = exp_comp.can_invest_in_school(school_id)

		var/list/tier_skills = skill_defs["tier[tier_num]"]
		if(tier_skills)
			for(var/choice in list("a", "b"))
				var/list/skill_info = tier_skills[choice]
				if(!skill_info)
					continue

				var/skill_type = skill_info["type"]
				var/is_selected = has_skill(skill_type)
				var/other_choice = (choice == "a") ? "b" : "a"
				var/other_selected = has_skill(tier_skills[other_choice]["type"])

				tier_data["choices"] += list(list(
					"id" = choice,
					"name" = skill_info["name"],
					"desc" = skill_info["desc"],
					"type" = "[skill_type]",
					"selected" = is_selected,
					"excluded" = other_selected,
					"available" = (previous_completed && can_afford && can_invest && !is_selected && !other_selected),
					"locked" = !previous_completed
				))

		tiers += list(tier_data)

	return tiers

/datum/palermitan_skill_tree/proc/has_tier_completed(school_id, tier_num)
	var/list/skill_defs = GLOB.palermitan_skill_definitions[school_id]
	if(!skill_defs)
		return FALSE

	var/list/tier_skills = skill_defs["tier[tier_num]"]
	if(!tier_skills)
		return FALSE

	for(var/choice in list("a", "b"))
		var/list/skill_info = tier_skills[choice]
		if(skill_info && has_skill(skill_info["type"]))
			return TRUE

	return FALSE

/datum/palermitan_skill_tree/proc/has_skill(skill_type)
	var/datum/component/palermitan_skill/skill = locate(skill_type) in viewer.GetComponents(/datum/component/palermitan_skill)
	return !!skill

/datum/palermitan_skill_tree/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("select_skill")
			var/skill_type = text2path(params["skill_type"])
			var/school_id = params["school"]
			var/tier = text2num(params["tier"])

			if(!skill_type || !school_id || !tier)
				return FALSE

			var/datum/component/palermitan_exp/exp_comp = viewer.GetComponent(/datum/component/palermitan_exp)
			if(!exp_comp)
				return FALSE

			if(exp_comp.skill_points < tier)
				to_chat(viewer, span_warning("You don't have enough skill points!"))
				return FALSE

			if(!exp_comp.can_invest_in_school(school_id))
				to_chat(viewer, span_warning("You can only invest in [exp_comp.max_schools] schools!"))
				return FALSE

			if(tier > 1 && !has_tier_completed(school_id, tier - 1))
				to_chat(viewer, span_warning("You must complete the previous tier first!"))
				return FALSE

			if(has_skill(skill_type))
				to_chat(viewer, span_warning("You already have this skill!"))
				return FALSE

			if(!exp_comp.spend_skill_point(tier))
				return FALSE

			exp_comp.invest_in_school(school_id)
			viewer.AddComponent(skill_type)

			to_chat(viewer, span_nicegreen("You have learned a new Palermitan technique!"))
			playsound(viewer, 'sound/machines/chime.ogg', 50, TRUE)

			return TRUE

	return FALSE

/// Builds data for all possible role passives, showing unlock status
/datum/palermitan_skill_tree/proc/get_all_passive_data(datum/component/palermitan_exp/exp_comp)
	var/list/passives = list()
	var/list/all_roles = list(
		list("id" = "Butcher", "name" = "Predator's Instinct", "source" = "Butcher", "type" = /datum/component/palermitan_role_passive/butcher,
			"t1" = "Hitting targets below 50% HP deals 5% bonus damage.",
			"t2" = "Bonus increases to 10%.",
			"t3" = "Bonus increases to 15%, and heals 3 HP per hit."),
		list("id" = "Blade Lineage", "name" = "Resolve of the Salsu", "source" = "Blade Lineage", "type" = /datum/component/palermitan_role_passive/blade_lineage,
			"t1" = "While below 30% HP, deal 10% more damage.",
			"t2" = "Bonus increases to 15%.",
			"t3" = "Bonus increases to 20%."),
		list("id" = "Thumb", "name" = "Soldato's Discipline", "source" = "Thumb", "type" = /datum/component/palermitan_role_passive/thumb,
			"t1" = "On taking RED damage: gain 2 Defense Level Up.",
			"t2" = "Gain 3 Defense Level Up instead.",
			"t3" = "Also gain 1 Offense Level Up."),
		list("id" = "Kurokumo", "name" = "Way of the Drawn Blade", "source" = "Kurokumo", "type" = /datum/component/palermitan_role_passive/kurokumo,
			"t1" = "On Hit: gain 1 Poise.",
			"t2" = "Poise crits deal 5% extra RED damage.",
			"t3" = "Crits deal 10% extra and inflict 2 Tremor."),
		list("id" = "Index", "name" = "Prescript Discipline", "source" = "Index", "type" = /datum/component/palermitan_role_passive/index,
			"t1" = "On Hit: inflict 1 Offense Level Down on target.",
			"t2" = "Also inflict 1 Defense Level Down.",
			"t3" = "Inflict 2 Offense Level Down instead."),
		list("id" = "Insurgence", "name" = "Nightwatch Tremors", "source" = "Insurgence", "type" = /datum/component/palermitan_role_passive/insurgence,
			"t1" = "On Hit: 15% chance to inflict 1 Tremor.",
			"t2" = "Chance increases to 20%.",
			"t3" = "25% chance for 2 Tremor instead."),
		list("id" = "Middle", "name" = "Vengeance Mark", "source" = "Middle", "type" = /datum/component/palermitan_role_passive/middle,
			"t1" = "On taking melee damage: next attack deals 3% more.",
			"t2" = "Bonus increases to 5%.",
			"t3" = "8% bonus, and the counter-hit inflicts 1 Duel Escalates."),
		list("id" = "N-Corp", "name" = "Methodical Strikes", "source" = "N-Corp", "type" = /datum/component/palermitan_role_passive/ncorp,
			"t1" = "On Hit: inflict 1 Defense Level Down and 1 Overheat.",
			"t2" = "Overheat increases to 2.",
			"t3" = "Defense Level Down increases to 2."),
		list("id" = "Rat", "name" = "Scavenger's Luck", "source" = "Rat", "type" = /datum/component/palermitan_role_passive/rat,
			"t1" = "On Hit: 5% chance for 50% bonus damage.",
			"t2" = "Chance increases to 8%.",
			"t3" = "10% chance, and lucky strikes inflict 2 Tremor."),
		list("id" = "Carnival", "name" = "Silk Hunter's Patience", "source" = "Carnival", "type" = /datum/component/palermitan_role_passive/carnival,
			"t1" = "After 3+ seconds without attacking: next hit deals 10% more.",
			"t2" = "Bonus increases to 20%.",
			"t3" = "30% bonus, and inflicts 2 Overheat."),
		list("id" = "Zwei", "name" = "Guardian's Resilience", "source" = "Zwei Association", "type" = /datum/component/palermitan_role_passive/zwei,
			"t1" = "On taking damage: gain 2 Defense Level Up.",
			"t2" = "Gain 3 Defense Level Up instead.",
			"t3" = "Also inflict 1 Offense Level Down on the attacker."),
		list("id" = "Seven", "name" = "Analyst's Eye", "source" = "Seven Association", "type" = /datum/component/palermitan_role_passive/seven,
			"t1" = "On Hit vs debuffed target: gain 1 Offense Level Up.",
			"t2" = "Gain 2 Offense Level Up instead.",
			"t3" = "Also inflict 1 Duel Escalates on the target."),
		list("id" = "Dieci", "name" = "Scholar's Insight", "source" = "Dieci Association", "type" = /datum/component/palermitan_role_passive/dieci,
			"t1" = "On Hit: deal 3% more per distinct debuff on target.",
			"t2" = "Bonus increases to 5% per debuff.",
			"t3" = "7% per debuff (max 28% with 4 debuffs)."),
		list("id" = "Cinq", "name" = "Duelist's Finesse", "source" = "Cinq (Roaming)", "type" = /datum/component/palermitan_role_passive/cinq,
			"t1" = "On Hit: gain 2 Poise.",
			"t2" = "Gain 3 Poise instead.",
			"t3" = "Crits that halve your Poise grant 1 Concentration."),
		list("id" = "Shi", "name" = "Assassin's Sacrifice", "source" = "Shi (Roaming)", "type" = /datum/component/palermitan_role_passive/shi,
			"t1" = "On Hit vs target below 30% HP: gain 3 Offense Level Up, lose 3% max HP. 3s cooldown.",
			"t2" = "Gain 4 Offense Level Up instead.",
			"t3" = "5 Offense Level Up, and inflict 2 Fragile."),
		list("id" = "Liu", "name" = "Burning Fist", "source" = "Liu (Roaming)", "type" = /datum/component/palermitan_role_passive/liu,
			"t1" = "On Hit: inflict 1 Overheat.",
			"t2" = "Every 4th hit: 2 extra Overheat.",
			"t3" = "Every 3rd hit: 3 extra Overheat."),
		list("id" = "Devyat", "name" = "Berserker's Escalation", "source" = "Devyat (Roaming)", "type" = /datum/component/palermitan_role_passive/devyat,
			"t1" = "On Hit: gain 2 Offense Level Up, lose 2% max HP. 3s cooldown.",
			"t2" = "Gain 3 Offense Level Up instead.",
			"t3" = "Below 50% HP: also gain 2 Defense Level Up."),
		list("id" = "Hana", "name" = "Adaptive Form", "source" = "Hana (Roaming)", "type" = /datum/component/palermitan_role_passive/hana,
			"t1" = "Attacking with a different weapon than last: gain 2 Offense Level Up. 5s cooldown.",
			"t2" = "Also gain 2 Defense Level Up.",
			"t3" = "3 Offense Level Up and 2 Defense Level Up."),
	)

	for(var/list/role_info in all_roles)
		var/passive_type = role_info["type"]
		var/current_tier = 0
		var/datum/component/palermitan_role_passive/P = locate(passive_type) in viewer.GetComponents(/datum/component/palermitan_role_passive)
		if(P)
			current_tier = P.tier
		// Get duel count — check various possible key names
		var/duels = 0
		if(exp_comp)
			// Check exact match first, then partial matches
			for(var/key in exp_comp.role_duel_counts)
				if(findtext(key, role_info["id"]))
					duels = exp_comp.role_duel_counts[key]
					break
		passives += list(list(
			"name" = role_info["name"],
			"source" = role_info["source"],
			"tier" = current_tier,
			"duels" = duels,
			"unlocked" = (current_tier > 0),
			"t1" = role_info["t1"],
			"t2" = role_info["t2"],
			"t3" = role_info["t3"],
		))

	return passives

/// Gets a display name for a role passive component
/datum/palermitan_skill_tree/proc/get_passive_display_name(datum/component/palermitan_role_passive/P)
	if(istype(P, /datum/component/palermitan_role_passive/butcher))
		return "Predator's Instinct (Butcher)"
	if(istype(P, /datum/component/palermitan_role_passive/blade_lineage))
		return "Resolve of the Salsu (Blade Lineage)"
	if(istype(P, /datum/component/palermitan_role_passive/thumb))
		return "Soldato's Discipline (Thumb)"
	if(istype(P, /datum/component/palermitan_role_passive/kurokumo))
		return "Way of the Drawn Blade (Kurokumo)"
	if(istype(P, /datum/component/palermitan_role_passive/index))
		return "Prescript Discipline (Index)"
	if(istype(P, /datum/component/palermitan_role_passive/insurgence))
		return "Nightwatch Tremors (Insurgence)"
	if(istype(P, /datum/component/palermitan_role_passive/middle))
		return "Vengeance Mark (Middle)"
	if(istype(P, /datum/component/palermitan_role_passive/ncorp))
		return "Methodical Strikes (N-Corp)"
	if(istype(P, /datum/component/palermitan_role_passive/rat))
		return "Scavenger's Luck (Rat)"
	if(istype(P, /datum/component/palermitan_role_passive/carnival))
		return "Silk Hunter's Patience (Carnival)"
	if(istype(P, /datum/component/palermitan_role_passive/zwei))
		return "Guardian's Resilience (Zwei)"
	if(istype(P, /datum/component/palermitan_role_passive/seven))
		return "Analyst's Eye (Seven)"
	if(istype(P, /datum/component/palermitan_role_passive/dieci))
		return "Scholar's Insight (Dieci)"
	if(istype(P, /datum/component/palermitan_role_passive/cinq))
		return "Duelist's Finesse (Cinq)"
	if(istype(P, /datum/component/palermitan_role_passive/shi))
		return "Assassin's Sacrifice (Shi)"
	if(istype(P, /datum/component/palermitan_role_passive/liu))
		return "Burning Fist (Liu)"
	if(istype(P, /datum/component/palermitan_role_passive/devyat))
		return "Berserker's Escalation (Devyat)"
	if(istype(P, /datum/component/palermitan_role_passive/hana))
		return "Adaptive Form (Hana)"
	return "Unknown Passive"

////////////////////////////////////////////////////////////
// SKILL TREE ACTION BUTTON

/datum/action/innate/palermitan_tree
	name = "Palermitan Skill Tree"
	desc = "Open the Palermitan Style skill tree."
	button_icon_state = "yourswordinhand"

/datum/action/innate/palermitan_tree/Activate()
	var/mob/living/carbon/human/user = owner
	if(!istype(user))
		return
	var/datum/palermitan_skill_tree/tree = new(user)
	tree.ui_interact(user)

////////////////////////////////////////////////////////////
// GLOBAL SKILL DEFINITIONS — 4 SCHOOLS

GLOBAL_LIST_INIT(palermitan_skill_definitions, init_palermitan_skill_definitions())

/proc/init_palermitan_skill_definitions()
	var/list/defs = list()

	// ========== TERREMOTO (Tremor) ==========
	defs["terremoto"] = list(
		"tier1" = list(
			"a" = list(
				"name" = "Il Cacciatore",
				"desc" = "Your attacks inflict 2 Tremor on the target. Against targets with 3+ 'The Duel Escalates' stacks, you also gain 1 Offense Level Up.",
				"type" = /datum/component/palermitan_skill/terremoto/il_cacciatore
			),
			"b" = list(
				"name" = "Destabilizing Strikes",
				"desc" = "Your attacks inflict Tremor that scales with 'The Duel Escalates' stacks on the target: 1 Tremor normally, 2 at 3+ stacks, 3 at 7+ stacks.",
				"type" = /datum/component/palermitan_skill/terremoto/destabilizing_strikes
			)
		),
		"tier2" = list(
			"a" = list(
				"name" = "Palermitan Rapier",
				"desc" = "Unlocks Tremor Burst at 15 stacks. When you trigger a Tremor Burst, gain 5 Offense Level Up and 5 Poise.",
				"type" = /datum/component/palermitan_skill/terremoto/palermitan_rapier
			),
			"b" = list(
				"name" = "Aftershock",
				"desc" = "Unlocks Tremor Burst at 25 stacks. Hitting targets with 10+ Tremor inflicts 2 Offense Level Down. At 20+ Tremor, inflicts 3 instead.",
				"type" = /datum/component/palermitan_skill/terremoto/aftershock
			)
		),
		"tier3" = list(
			"a" = list(
				"name" = "Sezionatura di Cervo",
				"desc" = "Activate to prime your next attack (60s cooldown). The primed hit inflicts 4 Tremor and 4 Overheat, forces a Tremor Burst if the target has 10+ 'The Duel Escalates' stacks, and deals bonus RED damage equal to 2 times the target's stacks. Consumes half the stacks.",
				"type" = /datum/component/palermitan_skill/terremoto/sezionatura
			),
			"b" = list(
				"name" = "Tectonic Collapse",
				"desc" = "Whenever you trigger a Tremor Burst, the target gains 3 Fragile, 3 Defense Level Down, and 2 Overheat.",
				"type" = /datum/component/palermitan_skill/terremoto/tectonic_collapse
			)
		)
	)

	// ========== INCENDIO (Overheat) ==========
	defs["incendio"] = list(
		"tier1" = list(
			"a" = list(
				"name" = "Colpi Sottani",
				"desc" = "Your attacks inflict 2 Overheat on the target. Against targets with 3+ 'The Duel Escalates' stacks, inflict 3 Overheat instead.",
				"type" = /datum/component/palermitan_skill/incendio/colpi_sottani
			),
			"b" = list(
				"name" = "Scorching Pursuit",
				"desc" = "Your attacks inflict 1 Overheat (2 at 5+ 'The Duel Escalates' stacks). Hitting a burning target also grants you 1 Offense Level Up.",
				"type" = /datum/component/palermitan_skill/incendio/scorching_pursuit
			)
		),
		"tier2" = list(
			"a" = list(
				"name" = "Firestorm",
				"desc" = "Hitting a target with 10 or more Overheat stacks grants you 3 Offense Level Up and 3 Poise.",
				"type" = /datum/component/palermitan_skill/incendio/firestorm
			),
			"b" = list(
				"name" = "Smoldering Wounds",
				"desc" = "Hitting a burning target inflicts 1 Defense Level Down for every 5 Overheat stacks on them (max 3 Defense Level Down).",
				"type" = /datum/component/palermitan_skill/incendio/smoldering_wounds
			)
		),
		"tier3" = list(
			"a" = list(
				"name" = "La Spada di Palermo",
				"desc" = "Hitting a target with 10+ 'The Duel Escalates' stacks grants a massive power surge: 5 Offense Level Up and 3 Damage Up. Also inflicts 3 Tremor. Consumes 5 stacks. 30 second cooldown.",
				"type" = /datum/component/palermitan_skill/incendio/la_spada
			),
			"b" = list(
				"name" = "Conflagration",
				"desc" = "Hitting a target with 15+ Overheat detonates their burn: deals bonus RED damage equal to their Overheat stacks, reduces Overheat by 5, and inflicts 2 Tremor. 10 second cooldown.",
				"type" = /datum/component/palermitan_skill/incendio/conflagration
			)
		)
	)

	// ========== ELEGANZA (Poise/Concentration) ==========
	defs["eleganza"] = list(
		"tier1" = list(
			"a" = list(
				"name" = "Relentless Pursuit",
				"desc" = "When the target has under 5 'The Duel Escalates' stacks: gain 2 Poise per hit. At 5+ stacks: gain 5 Poise per hit instead.",
				"type" = /datum/component/palermitan_skill/eleganza/relentless_pursuit
			),
			"b" = list(
				"name" = "Focused Mind",
				"desc" = "When the target has under 5 'The Duel Escalates' stacks: gain 1 Poise and 1 Concentration every 10 seconds. At 5+ stacks: gain 3 Poise per hit instead.",
				"type" = /datum/component/palermitan_skill/eleganza/focused_mind
			)
		),
		"tier2" = list(
			"a" = list(
				"name" = "Duello Feroce",
				"desc" = "Hitting a target with 3+ 'The Duel Escalates' stacks grants Poise (1 per 3 stacks, max 3) and heals you (2 HP per stack, max 10). When a crit halves your Poise, gain 1 Concentration.",
				"type" = /datum/component/palermitan_skill/eleganza/duello_feroce
			),
			"b" = list(
				"name" = "Severed Tendon",
				"desc" = "Your Poise crits inflict 3 Offense Level Down and 1 Fragile on the target. When a crit halves your Poise, you recover 5 Poise.",
				"type" = /datum/component/palermitan_skill/eleganza/severed_tendon
			)
		),
		"tier3" = list(
			"a" = list(
				"name" = "Valencina's Legacy",
				"desc" = "Your Poise crits inflict 3 Tremor and 3 Overheat on the target, and spread 'The Duel Escalates' to enemies within 2 tiles. Every 15 seconds, a crit also grants 1 Concentration.",
				"type" = /datum/component/palermitan_skill/eleganza/valencinas_legacy
			),
			"b" = list(
				"name" = "The Famiglia's Honor",
				"desc" = "'The Duel Escalates' can stack to 30. At 15+ stacks you gain 2 Poise per hit, and crits that halve your Poise grant 1 Concentration. Crits at 20+ stacks inflict 3 Fragile and 3 Defense Level Down.",
				"type" = /datum/component/palermitan_skill/eleganza/famiglias_honor
			)
		)
	)

	// ========== FONDAMENTI (General) ==========
	defs["fondamenti"] = list(
		"tier1" = list(
			"a" = list(
				"name" = "Iron Constitution",
				"desc" = "Whenever you take damage, gain 2 Defense Level Up, reducing future damage taken.",
				"type" = /datum/component/palermitan_skill/fondamenti/iron_constitution
			),
			"b" = list(
				"name" = "Aggressive Footwork",
				"desc" = "Gain 1 Offense Level Up whenever you hit a target or take melee damage. Every exchange makes you stronger.",
				"type" = /datum/component/palermitan_skill/fondamenti/aggressive_footwork
			)
		),
		"tier2" = list(
			"a" = list(
				"name" = "Predator's Instinct",
				"desc" = "Hitting targets below 50% HP makes them Fragile and grants you 2 Poise. Below 25% HP also grants 5 Offense Level Up and 2 more Poise.",
				"type" = /datum/component/palermitan_skill/fondamenti/predators_instinct
			),
			"b" = list(
				"name" = "Enduring Spirit",
				"desc" = "Hitting a target with 3+ 'The Duel Escalates' stacks heals you (1 HP per stack, max 5). Taking damage near a target with 'The Duel Escalates' grants 1 Defense Level Up.",
				"type" = /datum/component/palermitan_skill/fondamenti/enduring_spirit
			)
		),
		"tier3" = list(
			"a" = list(
				"name" = "Coup de Gr\u00e2ce",
				"desc" = "Hitting a target below 20% HP who has 5+ 'The Duel Escalates' stacks deals massive bonus RED damage (3 per stack). Consumes half the stacks.",
				"type" = /datum/component/palermitan_skill/fondamenti/coup_de_grace
			),
			"b" = list(
				"name" = "Unbreakable Will",
				"desc" = "When you enter critical condition, gain 5 Defense Level Up, 3 Protection, and heal 10% of your max HP. 60 second cooldown.",
				"type" = /datum/component/palermitan_skill/fondamenti/unbreakable_will
			)
		)
	)

	return defs
