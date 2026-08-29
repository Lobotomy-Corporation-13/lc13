/// TGUI menu used by the character preferences to pick which unlocked
/// achievement is displayed as the player's specialization on examine.
/datum/achievement_spec_menu
	/// The preferences datum this menu edits.
	var/datum/preferences/prefs

/datum/achievement_spec_menu/New(datum/preferences/P)
	. = ..()
	prefs = P

/datum/achievement_spec_menu/Destroy()
	prefs = null
	return ..()

/datum/achievement_spec_menu/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet/simple/achievements),
	)

/datum/achievement_spec_menu/ui_state(mob/user)
	return GLOB.always_state

/datum/achievement_spec_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AchievementSpec")
		ui.open()

/datum/achievement_spec_menu/ui_data(mob/user)
	var/list/data = list()
	data["chosen"] = prefs?.chosen_achievement ? "[prefs.chosen_achievement]" : null
	data["achievements"] = list()
	if(!prefs)
		return data

	var/datum/asset/spritesheet/simple/assets = get_asset_datum(/datum/asset/spritesheet/simple/achievements)
	for(var/achievement_type in prefs.get_unlocked_achievements())
		var/datum/award/achievement/A = SSachievements.achievements[achievement_type]
		if(!A || !A.name)
			continue
		var/list/this = list(
			"type" = "[achievement_type]",
			"name" = A.name,
			"desc" = A.desc,
			"title" = A.title ? A.title : A.name,
			"difficulty" = A.difficulty,
			"difficulty_color" = A.get_difficulty_color(),
			"difficulty_order" = A.get_difficulty_order(),
			"icon_class" = assets.icon_class_name(A.icon),
		)
		data["achievements"] += list(this)

	return data

/datum/achievement_spec_menu/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	if(!prefs)
		return
	switch(action)
		if("select")
			var/chosen_type = text2path(params["type"])
			if(chosen_type && (chosen_type in prefs.get_unlocked_achievements()))
				prefs.chosen_achievement = chosen_type
				prefs.ShowChoices(usr)
			return TRUE
		if("none")
			prefs.chosen_achievement = null
			prefs.ShowChoices(usr)
			return TRUE
