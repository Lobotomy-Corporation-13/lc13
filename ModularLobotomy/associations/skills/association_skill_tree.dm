/// Datum that handles the association skill tree TGUI interface.
/// Manages skill selection, validation, and serves UI data.
/datum/association_skill_tree
	/// The player viewing this skill tree
	var/mob/living/carbon/human/viewer
	/// Reference to the viewer's association_exp component
	var/datum/component/association_exp/exp_comp

/datum/association_skill_tree/New(mob/living/carbon/human/user)
	. = ..()
	viewer = user
	exp_comp = user.GetComponent(/datum/component/association_exp)
	// Lazy-init skill definitions if empty
	if(!length(GLOB.association_skill_definitions))
		init_association_skill_definitions()

/datum/association_skill_tree/Destroy()
	viewer = null
	exp_comp = null
	return ..()

/datum/association_skill_tree/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AssociationSkillTree")
		ui.open()

/datum/association_skill_tree/ui_state(mob/user)
	return GLOB.conscious_state

/// Builds all reactive UI data: EXP, skill points, branches, tiers, choices with state flags.
/datum/association_skill_tree/ui_data(mob/user)
	var/list/data = list()
	// Re-fetch in case component was re-added after ghosting etc.
	exp_comp = viewer.GetComponent(/datum/component/association_exp)
	if(!exp_comp)
		return data

	data["association_name"] = association_type_to_name(exp_comp.association_type)
	data["association_type"] = exp_comp.association_type
	data["current_exp"] = exp_comp.total_exp
	var/next = exp_comp.get_next_threshold()
	data["next_threshold"] = next ? next : "MAX"
	data["skill_points_available"] = exp_comp.skill_points_available
	data["skill_points_spent"] = exp_comp.skill_points_spent
	data["total_skill_points"] = exp_comp.total_skill_points
	data["max_branches"] = ASSOCIATION_MAX_BRANCHES
	data["invested_branch_count"] = length(exp_comp.invested_branches)

	// Build branch data from GLOB definitions
	var/list/branch_data = list()
	var/list/assoc_defs = GLOB.association_skill_definitions[exp_comp.association_type]
	if(assoc_defs)
		for(var/branch_name in assoc_defs)
			var/list/branch_info = list()
			branch_info["name"] = branch_name
			branch_info["invested"] = (branch_name in exp_comp.invested_branches)
			var/list/branch_defs = assoc_defs[branch_name]
			var/list/tier_data = list()
			for(var/tier_num in 1 to 3)
				var/tier_key = "tier[tier_num]"
				var/list/tier_info = list()
				tier_info["tier"] = tier_num
				tier_info["cost"] = association_tier_cost(tier_num)
				var/list/tier_defs = branch_defs ? branch_defs[tier_key] : null
				// Check if previous tier is complete (at least one choice selected)
				var/prev_complete = TRUE
				if(tier_num > 1)
					prev_complete = check_tier_complete(branch_defs, tier_num - 1)
				// Check if this tier already has a selection
				var/tier_has_selection = check_tier_has_selection(tier_defs)
				// Build choice data for this tier
				var/list/choice_data = list()
				if(tier_defs)
					for(var/choice_key in tier_defs)
						var/list/skill_def = tier_defs[choice_key]
						if(!skill_def)
							continue
						var/list/choice_info = list()
						choice_info["choice"] = choice_key
						choice_info["name"] = skill_def["name"]
						choice_info["desc"] = skill_def["desc"]
						var/is_selected = viewer.GetComponent(skill_def["type"]) ? TRUE : FALSE
						var/is_excluded = tier_has_selection && !is_selected
						var/is_locked = !prev_complete
						var/is_available = FALSE
						if(!is_selected && !is_excluded && prev_complete)
							if(exp_comp.skill_points_available >= association_tier_cost(tier_num))
								if(exp_comp.can_invest_in_branch(branch_name))
									is_available = TRUE
						choice_info["selected"] = is_selected
						choice_info["excluded"] = is_excluded
						choice_info["locked"] = is_locked
						choice_info["available"] = is_available
						choice_data += list(choice_info)
				tier_info["choices"] = choice_data
				tier_data += list(tier_info)
			branch_info["tiers"] = tier_data
			branch_data += list(branch_info)
	data["branches"] = branch_data
	return data

/// Check if a tier has any selection (either choice component exists on the viewer).
/datum/association_skill_tree/proc/check_tier_has_selection(list/tier_defs)
	if(!tier_defs)
		return FALSE
	for(var/choice_key in tier_defs)
		var/list/skill_def = tier_defs[choice_key]
		if(skill_def && viewer.GetComponent(skill_def["type"]))
			return TRUE
	return FALSE

/// Check if a tier is complete (at least one choice selected).
/datum/association_skill_tree/proc/check_tier_complete(list/branch_defs, tier_num)
	if(!branch_defs)
		return FALSE
	var/tier_key = "tier[tier_num]"
	var/list/tier_defs = branch_defs[tier_key]
	return check_tier_has_selection(tier_defs)

/// Handles skill selection from the UI.
/datum/association_skill_tree/ui_act(action, params)
	. = ..()
	if(.)
		return
	exp_comp = viewer.GetComponent(/datum/component/association_exp)
	if(!exp_comp)
		return

	switch(action)
		if("select_skill")
			var/branch_name = params["branch"]
			var/tier = text2num(params["tier"])
			var/choice_key = params["choice"]
			if(!branch_name || !tier || !choice_key)
				return
			// Validate: skill exists in definitions
			var/list/assoc_defs = GLOB.association_skill_definitions[exp_comp.association_type]
			if(!assoc_defs || !assoc_defs[branch_name])
				return
			var/list/branch_defs = assoc_defs[branch_name]
			var/tier_key = "tier[tier]"
			if(!branch_defs[tier_key])
				return
			var/list/tier_defs = branch_defs[tier_key]
			if(!tier_defs[choice_key])
				return
			var/list/skill_def = tier_defs[choice_key]
			var/skill_type = skill_def["type"]
			// Validate: not already selected
			if(viewer.GetComponent(skill_type))
				to_chat(viewer, span_warning("You already have this skill."))
				return
			// Validate: other choice not already selected
			if(check_tier_has_selection(tier_defs))
				to_chat(viewer, span_warning("You have already chosen a skill in this tier."))
				return
			// Validate: previous tier complete
			if(tier > 1 && !check_tier_complete(branch_defs, tier - 1))
				to_chat(viewer, span_warning("Complete the previous tier first."))
				return
			// Validate: enough skill points
			var/cost = association_tier_cost(tier)
			if(exp_comp.skill_points_available < cost)
				to_chat(viewer, span_warning("Not enough skill points. Need [cost], have [exp_comp.skill_points_available]."))
				return
			// Validate: branch investment limit
			if(!exp_comp.can_invest_in_branch(branch_name))
				to_chat(viewer, span_warning("You have already invested in [ASSOCIATION_MAX_BRANCHES] branches."))
				return
			// All validated - spend points and grant skill
			exp_comp.spend_skill_point(cost)
			exp_comp.invest_in_branch(branch_name)
			viewer.AddComponent(skill_type)
			to_chat(viewer, span_nicegreen("You have learned [skill_def["name"]]!"))
			playsound(get_turf(viewer), 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
			return TRUE
