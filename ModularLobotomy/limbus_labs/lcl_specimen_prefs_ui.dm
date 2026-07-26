//--------------------------------------
// LC Specimen preference selector TGUI
//--------------------------------------
// Lets a player browse every selectable LCL abnormality and assign each one a
// priority level (HIGH/MEDIUM/LOW/NEVER, mirroring the job preference grid).
// The chosen levels are stored on /datum/preferences/lcl_abno_pref and honored
// by /datum/job/limbus_specimen when a specimen is assigned at roundstart.

// Cache of the static card data (name/desc/blurb/base64 sprite) per abno typepath.
// Sprites are compile-time static, so this is built once and shared by all clients.
GLOBAL_LIST_EMPTY(lcl_specimen_card_cache)

// Builds (and caches) the showcase card for one LCL abno typepath.
// The subtype does not carry its own icon/desc, so those are read through the
// typepath in original_abno; true_name and the blurb live on the subtype itself.
/proc/get_lcl_specimen_card(subtype)
	if(!ispath(subtype))
		return null
	var/cached = GLOB.lcl_specimen_card_cache[subtype]
	if(cached)
		return cached
	var/mob/living/simple_animal/hostile/limbus_abno/sub = subtype
	var/orig_path = initial(sub.original_abno)
	var/mob/living/simple_animal/hostile/abnormality/orig = orig_path
	var/icon_file = orig_path ? initial(orig.icon) : initial(sub.icon)
	var/icon_state = orig_path ? initial(orig.icon_state) : initial(sub.icon_state)
	var/disp_desc = orig_path ? initial(orig.desc) : initial(sub.desc)
	var/base64 = null
	if(icon_file)
		if(!(icon_state in icon_states(icon(icon_file))))
			icon_state = ""
		var/icon/prev = icon(icon = icon_file, icon_state = icon_state, dir = SOUTH, frame = 1)
		base64 = icon2base64(prev)
		qdel(prev)
	var/list/card = list(
		"name" = initial(sub.true_name),
		"desc" = disp_desc,
		"blurb" = initial(sub.abno_additional_instructions),
		"icon" = base64,
		"sec_level" = (subtype in GLOB.high_security) ? "highsec" : "lowsec",
	)
	GLOB.lcl_specimen_card_cache[subtype] = card
	return card

//--------------------------------------
// TGUI handler datum
//--------------------------------------
/datum/tgui_handler/lcl_specimen_prefs
	/// The preferences datum this window reads from and writes back to.
	var/datum/preferences/prefs = null

/datum/tgui_handler/lcl_specimen_prefs/New(datum/preferences/P)
	prefs = P

/datum/tgui_handler/lcl_specimen_prefs/Destroy()
	prefs = null
	return ..()

/datum/tgui_handler/lcl_specimen_prefs/ui_host(mob/user)
	return user

/datum/tgui_handler/lcl_specimen_prefs/ui_status(mob/user)
	return (user?.client?.prefs == prefs) ? UI_INTERACTIVE : UI_CLOSE

/datum/tgui_handler/lcl_specimen_prefs/ui_state(mob/user)
	return GLOB.always_state

/datum/tgui_handler/lcl_specimen_prefs/ui_interact(mob/user, datum/tgui/ui)
	prefs.reconcile_lcl_prefs()
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "LCSpecimenPrefs", "LC Specimen Preferences")
		ui.open()

/datum/tgui_handler/lcl_specimen_prefs/ui_data(mob/user)
	var/list/data = list()
	var/list/rows = list()
	var/list/portraits = list()
	for(var/path in (GLOB.low_security + GLOB.high_security))
		var/list/info = get_lcl_specimen_card(path)
		rows += list(list(
			"path" = "[path]",
			"name" = info["name"],
			"desc" = info["desc"],
			"blurb" = info["blurb"],
			"sec" = info["sec_level"],
			"level" = LAZYACCESS(prefs.lcl_abno_pref, path) || 0,
		))
		portraits["[path]"] = info["icon"]
	data["cards"] = rows
	data["portraits"] = portraits
	return data

/datum/tgui_handler/lcl_specimen_prefs/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	var/path = text2path(params["path"])
	if(!(path in (GLOB.low_security + GLOB.high_security)))
		return
	switch(action)
		if("set_priority")
			var/lvl = clamp(text2num(params["level"]), 0, JP_HIGH)
			if(lvl <= 0)
				prefs.lcl_abno_pref -= path
			else
				LAZYSET(prefs.lcl_abno_pref, path, lvl)
			. = TRUE
	if(.)
		prefs.save_preferences()
		SStgui.update_uis(src)
