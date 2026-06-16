/*
 * Per-prefs TGUI for picking which unlocked /datum/id_skin should
 * appear on the player's spawned ID card. Replaces the old text-only
 * input() prompt with a visual catalogue so the player can see what
 * each skin looks like before equipping it.
 *
 * Lifecycle: lazily created on /datum/preferences when the user
 * first opens the picker, retained on the prefs datum for the rest
 * of the session, destroyed alongside the prefs.
 */

/datum/id_skin_picker
	var/name = "ID Card Skin"
	var/datum/preferences/prefs

/datum/id_skin_picker/New(datum/preferences/P)
	. = ..()
	prefs = P

/datum/id_skin_picker/Destroy()
	prefs = null
	return ..()

/datum/id_skin_picker/ui_state(mob/user)
	return GLOB.always_state

/datum/id_skin_picker/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "IdSkinPicker", name)
		ui.open()
		ui.set_autoupdate(FALSE)

/datum/id_skin_picker/ui_data(mob/user)
	var/list/data = list()
	if(!SSrefraction_railway)
		data["skins"] = list()
		data["equipped"] = null
		return data
	var/ckey = user.ckey
	data["equipped"] = SSrefraction_railway.GetEquippedIdSkin(ckey)
	var/list/owned_map = SSrefraction_railway.GetUnlockedIdSkins(ckey)
	var/list/skins = list()
	// Ship every registered skin — the UI renders unowned entries
	// as a black silhouette with a "???" name so the player can see
	// what's still out there to chase without learning the contents
	// from the source tree. Equipped skins still surface even if
	// the unlock ledger ever diverges from persistence.
	for(var/skin_id in SSrefraction_railway.id_skins)
		var/datum/id_skin/S = SSrefraction_railway.id_skins[skin_id]
		if(!istype(S))
			continue
		var/copies = owned_map[skin_id]
		var/owned = !isnull(copies) || skin_id == data["equipped"]
		skins += list(list(
			"id"        = S.id,
			"name"      = owned ? S.name : "???",
			"rarity"    = S.rarity,
			"icon_data" = S.icon_data,
			"owned"     = owned,
			"copies"    = owned ? (copies || 1) : 0,
		))
	data["skins"] = skins
	return data

/datum/id_skin_picker/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	switch(action)
		if("equip")
			var/skin_id = params["skin_id"]
			if(skin_id == "" || skin_id == "null")
				skin_id = null
			if(SSrefraction_railway?.SetEquippedIdSkin(usr.ckey, skin_id))
				if(prefs)
					prefs.equipped_id_skin = skin_id
					prefs.save_preferences()
				SStgui.update_uis(src)
			else
				to_chat(usr, span_warning("You don't own that skin."))
