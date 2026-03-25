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
	data["path_exp"] = path_exp
	data["exp_at_level"] = GetExpAtLevel()
	data["exp_to_next"] = GetExpToNext()

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
	// DEF reduction percentage for display
	var/def_val = GetStat("DEF")
	stats["DMG Reduction"] = round((def_val / (def_val + 300)) * 100, 0.1)
	// Unique stats — only include if non-zero
	var/ehr = GetStat("Effect Hit Rate")
	if(ehr)
		stats["Effect Hit Rate"] = ehr
	var/heal = GetStat("Healing Boost")
	if(heal)
		stats["Healing Boost"] = heal
	// Elemental DMG bonus
	var/elem_stat = "[element_type] DMG"
	var/elem_val = GetStat(elem_stat)
	if(elem_val)
		stats[elem_stat] = elem_val
	data["stats"] = stats

	// Abilities (4 entries)
	var/list/abilities = list()
	var/icon/ability_dmi = icon('ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi')
	if(basic_attack)
		var/b64 = ""
		if(basic_attack.icon_state)
			b64 = icon2base64(icon(ability_dmi, basic_attack.icon_state))
		abilities += list(list(
			"name" = basic_attack.name,
			"desc" = basic_attack.desc,
			"type" = "basic",
			"level" = basic_attack.level,
			"max_level" = basic_attack.max_level,
			"icon" = basic_attack.icon_state,
			"icon_base64" = b64,
			"scaling" = basic_attack.GetScalingData()
		))
	if(burst_action)
		var/b64 = ""
		if(burst_action.icon_state)
			b64 = icon2base64(icon(ability_dmi, burst_action.icon_state))
		abilities += list(list(
			"name" = burst_action.name,
			"desc" = burst_action.desc,
			"type" = "burst",
			"level" = burst_action.level,
			"max_level" = burst_action.max_level,
			"icon" = burst_action.icon_state,
			"icon_base64" = b64,
			"scaling" = burst_action.GetScalingData()
		))
	if(ultimate_action)
		var/b64 = ""
		if(ultimate_action.icon_state)
			b64 = icon2base64(icon(ability_dmi, ultimate_action.icon_state))
		abilities += list(list(
			"name" = ultimate_action.name,
			"desc" = ultimate_action.desc,
			"type" = "ultimate",
			"level" = ultimate_action.level,
			"max_level" = ultimate_action.max_level,
			"icon" = ultimate_action.icon_state,
			"icon_base64" = b64,
			"scaling" = ultimate_action.GetScalingData()
		))
	if(passive_effect)
		var/b64 = ""
		if(passive_effect.icon_state)
			b64 = icon2base64(icon(ability_dmi, passive_effect.icon_state))
		abilities += list(list(
			"name" = passive_effect.name,
			"desc" = passive_effect.desc,
			"type" = "passive",
			"level" = passive_effect.level,
			"max_level" = passive_effect.max_level,
			"icon" = passive_effect.icon_state,
			"icon_base64" = b64,
			"scaling" = passive_effect.GetScalingData()
		))
	data["abilities"] = abilities

	// Stat icon base64 cache for traces UI
	var/static/list/stat_icon_cache = null
	if(!stat_icon_cache || !stat_icon_cache["wind DMG"])
		stat_icon_cache = list()
		var/list/stat_icons = list(
			"ATK" = "atk",
			"HP" = "hp",
			"DEF" = "def",
			"SPD" = "speed",
			"CRIT Rate" = "crit_rate",
			"CRIT DMG" = "crit_dam",
			"physical DMG" = "atk",
			"wind DMG" = "atk",
			"fire DMG" = "atk",
			"ice DMG" = "atk",
			"lightning DMG" = "atk",
			"quantum DMG" = "atk",
			"imaginary DMG" = "atk",
			"Effect Hit Rate" = "effect_hit",
			"Healing Boost" = "heal_rate"
		)
		for(var/sname in stat_icons)
			var/sstate = stat_icons[sname]
			stat_icon_cache[sname] = icon2base64(icon('ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi', sstate))
	data["stat_icons"] = stat_icon_cache

	// Element color mapping for tinting stat icons
	var/static/list/elem_colors = list(
		"physical DMG" = "#CCCCCC",
		"wind DMG" = "#33CC77",
		"fire DMG" = "#FF6633",
		"ice DMG" = "#66BBFF",
		"lightning DMG" = "#CC66FF",
		"quantum DMG" = "#6666FF",
		"imaginary DMG" = "#FFCC33"
	)
	data["stat_colors"] = elem_colors

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
