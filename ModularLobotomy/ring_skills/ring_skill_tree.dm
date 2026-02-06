// Ring Skill Tree Datum
// Handles the TGUI interface for the skill tree

/datum/ring_skill_tree
	/// The mob viewing the skill tree
	var/mob/living/carbon/human/viewer

/datum/ring_skill_tree/New(mob/living/carbon/human/user)
	viewer = user

/datum/ring_skill_tree/Destroy()
	viewer = null
	return ..()

/datum/ring_skill_tree/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "RingSkillTree")
		ui.open()

/datum/ring_skill_tree/ui_state(mob/user)
	return GLOB.conscious_state

/datum/ring_skill_tree/ui_data(mob/user)
	var/list/data = list()

	var/datum/component/artistic_exp/exp_comp = viewer.GetComponent(/datum/component/artistic_exp)
	if(!exp_comp)
		return data

	data["exp"] = exp_comp.exp
	data["next_threshold"] = exp_comp.get_next_threshold()
	data["skill_points"] = exp_comp.skill_points
	data["skill_points_spent"] = exp_comp.skill_points_spent
	data["schools_invested"] = exp_comp.schools_invested

	// Build skill data for each school
	data["schools"] = list()

	// Fauvists
	data["schools"] += list(list(
		"name" = "Fauvists",
		"id" = "fauvist",
		"desc" = "Those who use primary colors and complex lines. Known to wear animal masks.",
		"theme" = "Predatory aggression, WHITE/SP damage focus.",
		"tiers" = get_school_tiers("fauvist", exp_comp)
	))

	// Pointillists
	data["schools"] += list(list(
		"name" = "Pointillists",
		"id" = "pointillist",
		"desc" = "Those who use small strokes and dots to depict light. Known to wield paintbrush weapons.",
		"theme" = "Random status effect application, SP recovery, scaling power.",
		"tiers" = get_school_tiers("pointillist", exp_comp)
	))

	// Cubists
	data["schools"] += list(list(
		"name" = "Cubists",
		"id" = "cubist",
		"desc" = "Those who incorporate abstract three-dimensionality and depth.",
		"theme" = "Area control, spatial manipulation.",
		"tiers" = get_school_tiers("cubist", exp_comp)
	))

	// Corporists
	data["schools"] += list(list(
		"name" = "Corporists",
		"id" = "corporist",
		"desc" = "Those who utilize human bones and muscles, contraction and elongation.",
		"theme" = "Simple and direct. Build up bleed, then trigger it for devastating damage.",
		"tiers" = get_school_tiers("corporist", exp_comp)
	))

	return data

/datum/ring_skill_tree/proc/get_school_tiers(school_id, datum/component/artistic_exp/exp_comp)
	var/list/tiers = list()
	var/list/skill_defs = GLOB.ring_skill_definitions[school_id]

	if(!skill_defs)
		return tiers

	for(var/tier_num in 1 to 3)
		var/list/tier_data = list(
			"tier" = tier_num,
			"cost" = tier_num,
			"choices" = list()
		)

		// Check if previous tier is completed
		var/previous_completed = (tier_num == 1) || has_tier_completed(school_id, tier_num - 1)
		var/can_afford = exp_comp.skill_points >= tier_num
		var/can_invest = exp_comp.can_invest_in_school(school_id)

		// Get the two choices for this tier
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

/datum/ring_skill_tree/proc/has_tier_completed(school_id, tier_num)
	var/list/skill_defs = GLOB.ring_skill_definitions[school_id]
	if(!skill_defs)
		return FALSE

	var/list/tier_skills = skill_defs["tier[tier_num]"]
	if(!tier_skills)
		return FALSE

	// Check if either choice is selected
	for(var/choice in list("a", "b"))
		var/list/skill_info = tier_skills[choice]
		if(skill_info && has_skill(skill_info["type"]))
			return TRUE

	return FALSE

/datum/ring_skill_tree/proc/has_skill(skill_type)
	var/datum/component/ring_skill/skill = locate(skill_type) in viewer.GetComponents(/datum/component/ring_skill)
	return !!skill

/datum/ring_skill_tree/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("select_skill")
			var/skill_type = text2path(params["skill_type"])
			var/school_id = params["school"]
			var/tier = text2num(params["tier"])

			if(!skill_type)
				return FALSE

			var/datum/component/artistic_exp/exp_comp = viewer.GetComponent(/datum/component/artistic_exp)
			if(!exp_comp)
				return FALSE

			// Validate
			if(exp_comp.skill_points < tier)
				to_chat(viewer, span_warning("You don't have enough skill points!"))
				return FALSE

			if(!exp_comp.can_invest_in_school(school_id))
				to_chat(viewer, span_warning("You can only invest in 2 schools maximum!"))
				return FALSE

			// Spend points and add skill
			if(!exp_comp.spend_skill_point(tier))
				return FALSE

			exp_comp.invest_in_school(school_id)

			// Add the skill component
			viewer.AddComponent(skill_type)

			to_chat(viewer, span_nicegreen("You have learned a new skill!"))
			playsound(viewer, 'sound/machines/chime.ogg', 50, TRUE)

			return TRUE

	return FALSE

// Global skill definitions
GLOBAL_LIST_INIT(ring_skill_definitions, init_ring_skill_definitions())

/proc/init_ring_skill_definitions()
	var/list/defs = list()

	// ========== FAUVISTS ==========
	defs["fauvist"] = list(
		"tier1" = list(
			"a" = list(
				"name" = "Predator's Scent",
				"desc" = "+15% damage vs bleeding targets",
				"type" = /datum/component/ring_skill/fauvist/predators_scent
			),
			"b" = list(
				"name" = "Maddening Maw",
				"desc" = "Attacks on bleeding targets deal 15% of your melee damage as additional WHITE damage",
				"type" = /datum/component/ring_skill/fauvist/maddening_maw
			)
		),
		"tier2" = list(
			"a" = list(
				"name" = "Rending Claws",
				"desc" = "Attacks apply 2 bleed stacks",
				"type" = /datum/component/ring_skill/fauvist/rending_claws
			),
			"b" = list(
				"name" = "Savage Instinct",
				"desc" = "After hitting a bleeding target, gain +15% damage for 4 seconds (refreshes on hit)",
				"type" = /datum/component/ring_skill/fauvist/savage_instinct
			)
		),
		"tier3" = list(
			"a" = list(
				"name" = "Spreading Wounds",
				"desc" = "When hitting bleeding target, adjacent enemies gain 3 bleed",
				"type" = /datum/component/ring_skill/fauvist/spreading_wounds
			),
			"b" = list(
				"name" = "Primal Terror",
				"desc" = "Hitting targets with 10+ bleed deals 20 WHITE damage and removes 5 bleed stacks",
				"type" = /datum/component/ring_skill/fauvist/primal_terror
			)
		)
	)

	// ========== POINTILLISTS ==========
	defs["pointillist"] = list(
		"tier1" = list(
			"a" = list(
				"name" = "Hematic Coloring",
				"desc" = "Attacks apply 3 stacks of a random effect (Bleed, Overheat, Tremor, or Mental Decay). If target already has that effect, deal +10% damage instead.",
				"type" = /datum/component/ring_skill/pointillist/hematic_coloring
			),
			"b" = list(
				"name" = "Sanguine Pointillism",
				"desc" = "Attacks apply 1 stack of TWO random effects. Heal 2 SP whenever you apply an effect the target didn't already have.",
				"type" = /datum/component/ring_skill/pointillist/sanguine_pointillism
			)
		),
		"tier2" = list(
			"a" = list(
				"name" = "Assignment Evaluation",
				"desc" = "Heal 5 SP when hitting targets, +3 SP per status effect on them",
				"type" = /datum/component/ring_skill/pointillist/assignment_evaluation
			),
			"b" = list(
				"name" = "Beat the Brush",
				"desc" = "+5% damage per status effect on target (max 20% at 4 effects)",
				"type" = /datum/component/ring_skill/pointillist/beat_the_brush
			)
		),
		"tier3" = list(
			"a" = list(
				"name" = "Paint Over",
				"desc" = "Random effect application now applies 2x stacks; +10% chance to apply ALL four effects at once",
				"type" = /datum/component/ring_skill/pointillist/paint_over
			),
			"b" = list(
				"name" = "Practices on Aesthetics",
				"desc" = "+10% damage and +2 bleed per status effect on target",
				"type" = /datum/component/ring_skill/pointillist/practices_on_aesthetics
			)
		)
	)

	// ========== CUBISTS ==========
	defs["cubist"] = list(
		"tier1" = list(
			"a" = list(
				"name" = "Fractured Reflection",
				"desc" = "Attackers gain 3 bleed when hitting you",
				"type" = /datum/component/ring_skill/cubist/fractured_reflection
			),
			"b" = list(
				"name" = "Geometric Reach",
				"desc" = "Your attacks apply 2 bleed to enemies adjacent to your target",
				"type" = /datum/component/ring_skill/cubist/geometric_reach
			)
		),
		"tier2" = list(
			"a" = list(
				"name" = "Abstract Suffering",
				"desc" = "When enemies within 5 tiles take bleed damage, they also take WHITE damage equal to half the bleed damage",
				"type" = /datum/component/ring_skill/cubist/abstract_suffering
			),
			"b" = list(
				"name" = "Warped Space",
				"desc" = "Hitting targets with 8+ bleed stacks inflicts 20% slowdown for 3 seconds",
				"type" = /datum/component/ring_skill/cubist/warped_space
			)
		),
		"tier3" = list(
			"a" = list(
				"name" = "Spatial Anchor",
				"desc" = "Enemies within 4 tiles of you cannot have their bleed reduced below 5 stacks",
				"type" = /datum/component/ring_skill/cubist/spatial_anchor
			),
			"b" = list(
				"name" = "Crimson Dimension",
				"desc" = "Active (60s CD): Create 3x3 zone applying 2 bleed/sec for 10s; you take 20% less damage while inside",
				"type" = /datum/component/ring_skill/cubist/crimson_dimension
			)
		)
	)

	// ========== CORPORISTS ==========
	defs["corporist"] = list(
		"tier1" = list(
			"a" = list(
				"name" = "Opening Wounds",
				"desc" = "When off cooldown, your next attack applies 8 bleed stacks (20s cooldown). While on cooldown, attacks apply 1 bleed stack.",
				"type" = /datum/component/ring_skill/corporist/opening_wounds
			),
			"b" = list(
				"name" = "Exposed Veins",
				"desc" = "+3% damage per bleed stack on target (max 30%)",
				"type" = /datum/component/ring_skill/corporist/exposed_veins
			)
		),
		"tier2" = list(
			"a" = list(
				"name" = "Sanguine Absorption",
				"desc" = "Heal 5 HP when applying bleed (5s cooldown)",
				"type" = /datum/component/ring_skill/corporist/sanguine_absorption
			),
			"b" = list(
				"name" = "Rupture",
				"desc" = "Hitting targets with 15+ bleed consumes 10 stacks to deal 40 bonus damage",
				"type" = /datum/component/ring_skill/corporist/rupture
			)
		),
		"tier3" = list(
			"a" = list(
				"name" = "Vivisection",
				"desc" = "Hitting bleeding targets below 20% HP deals 100 bonus damage (30s cooldown)",
				"type" = /datum/component/ring_skill/corporist/vivisection
			),
			"b" = list(
				"name" = "Exsanguinate",
				"desc" = "Active (30s CD): Buff your weapon for 10s. Next hit consumes ALL bleed on target, dealing 5 damage per stack.",
				"type" = /datum/component/ring_skill/corporist/exsanguinate
			)
		)
	)

	return defs
