// ============================================================
// Path UI — DM-side TGUI Procs
// ============================================================
// Adds ui_interact, ui_data, and ui_act to /datum/path for
// the PathScreen TGUI interface.
// ============================================================

/datum/path/ui_state(mob/user)
	return GLOB.always_state

/datum/path/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PathScreen")
		ui.open()

/datum/path/ui_data(mob/user)
	var/list/data = list()

	// Path identity
	data["path_name"] = name
	data["path_desc"] = desc
	data["path_icon"] = icon_state
	data["element_type"] = element_type

	// Resources
	data["energy"] = energy
	data["max_energy"] = max_energy
	data["action_points"] = action_points
	data["max_action_points"] = max_action_points

	// Leveling
	data["path_level"] = path_level
	data["ascension_phase"] = ascension_phase

	// Turn system
	data["turn_state"] = turn_state
	var/turn_dur = round(GetTurnDuration() / 10, 0.1)
	data["turn_duration"] = turn_dur
	if(next_turn_time > world.time)
		data["turn_remaining"] = round((next_turn_time - world.time) / 10, 0.1)
	else
		data["turn_remaining"] = 0

	// Path stats (computed via GetStat)
	var/list/stats = list()
	for(var/stat_name in list("HP", "ATK", "DEF", "SPD", "CRIT Rate", "CRIT DMG", "Max Energy", "Energy Regen Rate"))
		stats[stat_name] = GetStat(stat_name)
	data["stats"] = stats

	// Abilities (4 entries)
	var/list/abilities = list()
	if(basic_attack)
		abilities += list(list(
			"name" = basic_attack.name,
			"desc" = basic_attack.desc,
			"type" = "basic",
			"level" = basic_attack.level,
			"max_level" = basic_attack.max_level,
			"icon" = basic_attack.icon_state
		))
	if(burst_action)
		abilities += list(list(
			"name" = burst_action.name,
			"desc" = burst_action.desc,
			"type" = "burst",
			"level" = burst_action.level,
			"max_level" = burst_action.max_level,
			"icon" = burst_action.icon_state
		))
	if(ultimate_action)
		abilities += list(list(
			"name" = ultimate_action.name,
			"desc" = ultimate_action.desc,
			"type" = "ultimate",
			"level" = ultimate_action.level,
			"max_level" = ultimate_action.max_level,
			"icon" = ultimate_action.icon_state
		))
	if(passive_effect)
		abilities += list(list(
			"name" = passive_effect.name,
			"desc" = passive_effect.desc,
			"type" = "passive",
			"level" = passive_effect.level,
			"max_level" = passive_effect.max_level,
			"icon" = passive_effect.icon_state
		))
	data["abilities"] = abilities

	// Skill tree nodes (Traces)
	var/list/node_data = list()
	for(var/datum/path_node/node in nodes)
		node_data += list(node.GetNodeData(unlocked_nodes))
	data["nodes"] = node_data

	// Player's current ahn balance
	var/player_ahn = 0
	if(owner)
		var/obj/item/card/id/C = owner.get_idcard(TRUE)
		if(C?.registered_account)
			player_ahn = C.registered_account.account_balance
	data["player_ahn"] = player_ahn

	// LC13 attributes (for reference display)
	if(owner)
		var/list/lc13 = list()
		lc13["Fortitude"] = get_attribute_level(owner, FORTITUDE_ATTRIBUTE)
		lc13["Prudence"] = get_attribute_level(owner, PRUDENCE_ATTRIBUTE)
		lc13["Temperance"] = get_attribute_level(owner, TEMPERANCE_ATTRIBUTE)
		lc13["Justice"] = get_attribute_level(owner, JUSTICE_ATTRIBUTE)
		data["lc13_attributes"] = lc13

	return data

/datum/path/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("unlock_node")
			var/node_id = params["node_id"]
			if(!node_id)
				return
			if(UnlockNode(node_id))
				. = TRUE
