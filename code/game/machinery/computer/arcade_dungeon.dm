/// L-Corp Depths - Darkest Dungeon-inspired arcade
/// Explore an underground L-Corp facility.
/// Turn-based positional combat with stress system.
/// 4 random fixers from 8 classes. Clear 80% + boss.
/// Game engine runs client-side in JavaScript.

// Sprite cache - encoded once, reused
GLOBAL_LIST_INIT(dungeon_sprite_cache, list())

// Ordeal enemy sprite definitions: key = list(icon_file, icon_state)
GLOBAL_LIST_INIT(dungeon_enemy_sprites, list(
	"amber_bug" = list('ModularLobotomy/_Lobotomyicons/tegumobs.dmi', "amber_bug"),
	"crimson_clown" = list('ModularLobotomy/_Lobotomyicons/tegumobs.dmi', "crimson_clown"),
	"green_bot" = list('ModularLobotomy/_Lobotomyicons/32x48.dmi', "green_bot"),
	"crimson_noon" = list('ModularLobotomy/_Lobotomyicons/48x48.dmi', "crimson_noon"),
	"indigo_dawn" = list('ModularLobotomy/_Lobotomyicons/32x48.dmi', "indigo_dawn"),
	"steel_dawn" = list('ModularLobotomy/_Lobotomyicons/32x48.dmi', "steel_dawn"),
	"green_bot_big" = list('ModularLobotomy/_Lobotomyicons/32x48.dmi', "green_bot_big"),
	"indigo_noon" = list('ModularLobotomy/_Lobotomyicons/32x48.dmi', "indigo_noon"),
	"steel_noon" = list('ModularLobotomy/_Lobotomyicons/32x48.dmi', "steel_noon"),
	"spider_minion" = list('ModularLobotomy/_Lobotomyicons/64x64.dmi', "spider_minion")))

// Boss sprite definitions
GLOBAL_LIST_INIT(dungeon_boss_sprites, list(
	"spider_bud" = list('ModularLobotomy/_Lobotomyicons/64x64.dmi', "spider_active"),
	"big_bird" = list('ModularLobotomy/_Lobotomyicons/64x64.dmi', "big_bird"),
	"nosferatu" = list('ModularLobotomy/_Lobotomyicons/32x48.dmi', "nosferatu")))

// Enemy compositions by difficulty
GLOBAL_LIST_INIT(dungeon_encounters_easy, list(
	"amber_bug,amber_bug",
	"amber_bug,crimson_clown",
	"crimson_clown,crimson_clown",
	"green_bot,amber_bug"))

GLOBAL_LIST_INIT(dungeon_encounters_med, list(
	"crimson_noon,amber_bug",
	"indigo_dawn,crimson_clown",
	"steel_dawn,green_bot",
	"green_bot_big,amber_bug"))

GLOBAL_LIST_INIT(dungeon_encounters_hard, list(
	"indigo_noon,steel_dawn",
	"steel_noon,crimson_noon",
	"indigo_noon,indigo_dawn",
	"crimson_noon,steel_dawn"))

// Miniboss pool (TETH/HE abnormalities)
GLOBAL_LIST_INIT(dungeon_miniboss_pool, list(
	"spider_bud"))

// Final boss pool (WAW abnormalities)
GLOBAL_LIST_INIT(dungeon_boss_pool, list(
	"big_bird", "nosferatu"))

// Curio event pool
GLOBAL_LIST_INIT(dungeon_curio_pool, list(
	"broken_terminal", "supply_crate",
	"strange_machine", "old_locker"))

/obj/machinery/computer/arcade/dungeon
	name = "L-Corp Depths Arcade"
	desc = "Descend into the buried facility. Four fixers. One way out."
	icon_state = "arcade"
	icon_keyboard = "no_keyboard"
	icon_screen = "invaders"
	light_color = "#4466aa"
	circuit = /obj/item/circuitboard/computer/arcade/dungeon
	/// Leaderboard
	var/list/leaderboard = list()
	/// Sound throttle
	var/last_sfx_time = 0

/obj/machinery/computer/arcade/dungeon/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ArcadeDungeon", name)
		ui.open()

/obj/machinery/computer/arcade/dungeon/ui_static_data(mob/user)
	var/list/data = list()
	data["sprites"] = encode_sprites()
	data["dungeon"] = generate_dungeon()
	return data

/obj/machinery/computer/arcade/dungeon/ui_data(mob/user)
	var/list/data = list()
	data["leaderboard"] = leaderboard
	return data

/obj/machinery/computer/arcade/dungeon/ui_act(action, params)
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
				if("hit")
					playsound(loc, 'sound/arcade/hit.ogg', 30, TRUE)
				if("block")
					playsound(loc, 'sound/arcade/heal.ogg', 25, TRUE)
				if("kill")
					playsound(loc, 'sound/arcade/steal.ogg', 35, TRUE)
				if("hurt")
					playsound(loc, 'sound/arcade/boom.ogg', 30, TRUE)
				if("heal")
					playsound(loc, 'sound/arcade/mana.ogg', 20, TRUE)
			. = TRUE

/// Encode all enemy/boss sprites to base64
/obj/machinery/computer/arcade/dungeon/proc/encode_sprites()
	var/list/result = list()
	// Encode ordeal enemy sprites (west dir, frame 1)
	for(var/key in GLOB.dungeon_enemy_sprites)
		if(GLOB.dungeon_sprite_cache[key])
			result[key] = GLOB.dungeon_sprite_cache[key]
			continue
		var/list/def = GLOB.dungeon_enemy_sprites[key]
		var/icon/I = new(def[1], def[2], WEST, 1)
		var/b64 = icon2base64(I)
		GLOB.dungeon_sprite_cache[key] = b64
		result[key] = b64
	// Encode boss sprites (west dir, frame 1)
	for(var/key in GLOB.dungeon_boss_sprites)
		if(GLOB.dungeon_sprite_cache[key])
			result[key] = GLOB.dungeon_sprite_cache[key]
			continue
		var/list/def = GLOB.dungeon_boss_sprites[key]
		var/icon/I = new(def[1], def[2], WEST, 1)
		var/b64 = icon2base64(I)
		GLOB.dungeon_sprite_cache[key] = b64
		result[key] = b64
	return result

/// Generate a connected grid dungeon.
/// Grows outward from start (1,1) to ensure
/// all rooms are reachable. Boss at far end.
/obj/machinery/computer/arcade/dungeon/proc/generate_dungeon()
	// Grow 13 rooms from start by expanding
	// into adjacent empty cells.
	var/list/placed = list()
	var/list/grid = list() // "x,y" -> TRUE
	// Start room
	placed += list(list(1, 1))
	grid["1,1"] = TRUE

	// Frontier: cells adjacent to placed rooms
	var/list/frontier = list()
	add_frontier(frontier, 1, 1, grid)

	// Grow until we have 13 rooms
	var/target_rooms = 13
	while(length(placed) < target_rooms && length(frontier))
		// Pick random frontier cell
		var/fi = rand(1, length(frontier))
		var/list/cell = frontier[fi]
		frontier.Cut(fi, fi + 1)
		var/ck = "[cell[1]],[cell[2]]"
		if(grid[ck])
			continue
		// Place room here
		placed += list(cell)
		grid[ck] = TRUE
		add_frontier(frontier, cell[1], cell[2], grid)

	// Ensure boss room: place at farthest
	// room from start. Swap with last placed.
	var/best_dist = 0
	var/best_idx = length(placed)
	for(var/i in 2 to length(placed))
		var/list/p = placed[i]
		var/d = abs(p[1] - 1) + abs(p[2] - 1)
		if(d > best_dist)
			best_dist = d
			best_idx = i
	// Swap farthest to end
	if(best_idx != length(placed))
		var/list/tmp = placed[best_idx]
		placed[best_idx] = placed[length(placed)]
		placed[length(placed)] = tmp

	// Room type assignments
	var/list/room_types = list(
		"empty",
		"combat_easy", "combat_easy", "combat_easy",
		"combat_med", "combat_med", "combat_med",
		"combat_hard",
		"treasure", "treasure",
		"curio", "curio")
	// Shuffle
	for(var/i in length(room_types) to 2 step -1)
		var/j = rand(1, i)
		var/t = room_types[i]
		room_types[i] = room_types[j]
		room_types[j] = t

	var/miniboss_placed = FALSE
	var/list/rooms = list()
	for(var/ri in 1 to length(placed))
		var/list/pos = placed[ri]
		var/rx = pos[1]
		var/ry = pos[2]
		var/list/room = list()
		room["x"] = rx
		room["y"] = ry
		if(ri == 1)
			room["type"] = "start"
		else if(ri == length(placed))
			room["type"] = "boss"
			room["enemies"] = generate_boss()
		else if(!miniboss_placed && ri > 5 && ri < 10)
			room["type"] = "miniboss"
			room["enemies"] = generate_miniboss()
			miniboss_placed = TRUE
		else
			var/rtype = "empty"
			if(length(room_types))
				rtype = room_types[1]
				room_types.Cut(1, 2)
			room["type"] = rtype
			if(findtext(rtype, "combat"))
				room["enemies"] = generate_encounter(rtype)
		rooms += list(room)

	// Build connections from adjacency
	for(var/list/rm in rooms)
		var/list/conns = list()
		var/rx = rm["x"]
		var/ry = rm["y"]
		var/list/dirs = list(
			list(rx + 1, ry),
			list(rx - 1, ry),
			list(rx, ry + 1),
			list(rx, ry - 1))
		for(var/list/d in dirs)
			var/dk = "[d[1]],[d[2]]"
			if(grid[dk])
				conns += list(list(d[1], d[2]))
		rm["conns"] = conns

	return rooms

/// Add cardinal neighbors to frontier
/obj/machinery/computer/arcade/dungeon/proc/add_frontier(list/frontier, x, y, list/grid)
	var/list/dirs = list(
		list(x + 1, y), list(x - 1, y),
		list(x, y + 1), list(x, y - 1))
	for(var/list/d in dirs)
		if(d[1] < 1 || d[1] > 5 || d[2] < 1 || d[2] > 5)
			continue
		var/dk = "[d[1]],[d[2]]"
		if(!grid[dk])
			frontier += list(d)

/// Generate an enemy encounter
/obj/machinery/computer/arcade/dungeon/proc/generate_encounter(tier)
	var/list/pool
	switch(tier)
		if("combat_easy")
			pool = GLOB.dungeon_encounters_easy
		if("combat_med")
			pool = GLOB.dungeon_encounters_med
		if("combat_hard")
			pool = GLOB.dungeon_encounters_hard
		else
			pool = GLOB.dungeon_encounters_easy

	var/comp = pick(pool)
	var/list/keys = splittext(comp, ",")
	var/list/enemies = list()
	for(var/key in keys)
		enemies += list(list("type" = key))
	return enemies

/// Generate miniboss encounter
/obj/machinery/computer/arcade/dungeon/proc/generate_miniboss()
	var/boss_key = pick(GLOB.dungeon_miniboss_pool)
	return list(list("type" = boss_key, "boss" = TRUE))

/// Generate final boss encounter
/obj/machinery/computer/arcade/dungeon/proc/generate_boss()
	var/boss_key = pick(GLOB.dungeon_boss_pool)
	return list(list("type" = boss_key, "boss" = TRUE))

// Circuit board
/obj/item/circuitboard/computer/arcade/dungeon
	name = "L-Corp Depths Arcade (Computer Board)"
	icon_state = "generic"
	build_path = /obj/machinery/computer/arcade/dungeon
