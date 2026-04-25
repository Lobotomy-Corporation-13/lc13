/// L Corp Overtime - FNAF-style abnormality survival
/// Last manager at a fallen L Corp facility.
/// Monitor cameras, close doors, manage enkephalin power.
/// Survive 5 nights.

// Sprite cache
GLOBAL_LIST_INIT(lcovertime_sprite_cache, list())

// Abnormality sprite definitions
GLOBAL_LIST_INIT(lcovertime_sprites, list(
	"pbird" = list('ModularLobotomy/_Lobotomyicons/32x32.dmi', "pbird_breach"),
	"beauty" = list('ModularLobotomy/_Lobotomyicons/48x48.dmi', "beauty"),
	"clayman" = list('ModularLobotomy/_Lobotomyicons/32x32.dmi', "bluro"),
	"schadenfreude" = list('ModularLobotomy/_Lobotomyicons/64x64.dmi', "schadenfreude"),
	"redshoes" = list('ModularLobotomy/_Lobotomyicons/32x32.dmi', "redshoes"),
	"fairy" = list('ModularLobotomy/_Lobotomyicons/64x96.dmi', "fairy_longlegs"),
	"drv" = list('ModularLobotomy/_Lobotomyicons/64x64.dmi', "dmr_abnormality")))

/obj/machinery/computer/arcade/lcovertime
	name = "L Corp Overtime Arcade"
	desc = "Last shift at a fallen L Corp branch. The enkephalin is running low. Don't let them in."
	icon_state = "arcade"
	icon_keyboard = "no_keyboard"
	icon_screen = "invaders"
	light_color = "#cc6633"
	circuit = /obj/item/circuitboard/computer/arcade/lcovertime
	/// Leaderboard
	var/list/leaderboard = list()
	/// Sound throttle
	var/last_sfx_time = 0

/obj/machinery/computer/arcade/lcovertime/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ArcadeLCOvertime", name)
		ui.open()

/obj/machinery/computer/arcade/lcovertime/ui_static_data(mob/user)
	var/list/data = list()
	data["sprites"] = encode_sprites()
	return data

/obj/machinery/computer/arcade/lcovertime/ui_data(mob/user)
	var/list/data = list()
	data["leaderboard"] = leaderboard
	return data

/obj/machinery/computer/arcade/lcovertime/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("submit_score")
			var/score = text2num(params["score"])
			var/pname = params["name"]
			if(!pname || length(pname) < 1)
				pname = usr?.name || "???"
			pname = copytext(pname, 1, 7)
			leaderboard += list(list("name" = pname, "score" = score))
			leaderboard = sortTim(leaderboard, /proc/cmp_leaderboard_desc)
			if(length(leaderboard) > 10)
				leaderboard.Cut(11)
			prizevend(usr)
			playsound(loc, 'sound/arcade/win.ogg', 50, TRUE)
			. = TRUE
		if("died")
			playsound(loc, 'sound/arcade/lose.ogg', 50, TRUE)
			. = TRUE
		if("restart")
			update_static_data(usr)
			. = TRUE
		if("sfx")
			var/snd = params["s"]
			if(world.time - last_sfx_time < 3)
				return
			last_sfx_time = world.time
			switch(snd)
				if("door")
					playsound(loc, 'sound/arcade/hit.ogg', 30, TRUE)
				if("light")
					playsound(loc, 'sound/arcade/mana.ogg', 20, TRUE)
				if("cam")
					playsound(loc, 'sound/arcade/hit.ogg', 15, TRUE)
				if("jumpscare")
					playsound(loc, 'sound/arcade/boom.ogg', 50, TRUE)
				if("charge")
					playsound(loc, 'sound/arcade/boom.ogg', 40, TRUE)
				if("win")
					playsound(loc, 'sound/arcade/win.ogg', 40, TRUE)
			. = TRUE

/// Encode abnormality sprites to base64
/obj/machinery/computer/arcade/lcovertime/proc/encode_sprites()
	var/list/result = list()
	for(var/key in GLOB.lcovertime_sprites)
		if(GLOB.lcovertime_sprite_cache[key])
			result[key] = GLOB.lcovertime_sprite_cache[key]
			continue
		var/list/def = GLOB.lcovertime_sprites[key]
		var/icon/I = new(def[1], def[2], SOUTH, 1)
		var/b64 = icon2base64(I)
		GLOB.lcovertime_sprite_cache[key] = b64
		result[key] = b64
	return result

// Circuit board
/obj/item/circuitboard/computer/arcade/lcovertime
	name = "L Corp Overtime Arcade (Computer Board)"
	icon_state = "generic"
	build_path = /obj/machinery/computer/arcade/lcovertime
