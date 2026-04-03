/// Fixer's Gambit - Deckbuilder card combat arcade
/// Clear 12 floors of a Syndicate hideout.
/// Slay the Spire / Library of Ruina inspired.
/// Game engine runs client-side in JavaScript.

// Card key pool for rewards/shop
GLOBAL_LIST_INIT(cardgame_reward_pool, list(
	"heavy_swing", "quick_jab", "twin_strike",
	"prosth_slam", "nerve_strike", "shank",
	"eviscerate", "iron_wall", "parry",
	"overclock", "sharpen", "toxic_cloud"))

// Augmentation key pool
GLOBAL_LIST_INIT(cardgame_augment_pool, list(
	"reinforced", "optical", "adrenal",
	"prosth_arm", "subdermal", "toxin_filter",
	"regenerator", "reflexes"))

// Enemy compositions by difficulty tier
// Tier 0 (rows 1-3), tier 1 (4-7), tier 2 (8-11)
GLOBAL_LIST_INIT(cardgame_encounters_t0, list(
	"sewer_rat,sewer_rat",
	"sewer_rat,street_thug",
	"rat_swarm,knife_runner",
	"street_thug,street_thug"))

GLOBAL_LIST_INIT(cardgame_encounters_t1, list(
	"enforcer,street_thug",
	"pipe_bomber,knife_runner",
	"enforcer,knife_runner",
	"pipe_bomber,street_thug"))

GLOBAL_LIST_INIT(cardgame_encounters_t2, list(
	"enforcer,enforcer",
	"lieutenant,knife_runner",
	"pipe_bomber,enforcer",
	"lieutenant,street_thug"))

// Elite encounters by tier
GLOBAL_LIST_INIT(cardgame_elites_t0, list(
	"rat_swarm,rat_swarm,street_thug"))

GLOBAL_LIST_INIT(cardgame_elites_t1, list(
	"aug_bruiser"))

GLOBAL_LIST_INIT(cardgame_elites_t2, list(
	"aug_bruiser,knife_runner"))

// Enemy HP ranges [min, max]
GLOBAL_LIST_INIT(cardgame_enemy_hp, list(
	"sewer_rat" = list(8, 10),
	"rat_swarm" = list(14, 16),
	"street_thug" = list(18, 22),
	"knife_runner" = list(16, 18),
	"enforcer" = list(30, 36),
	"pipe_bomber" = list(22, 26),
	"aug_bruiser" = list(40, 48),
	"lieutenant" = list(35, 40),
	"thumb_capo" = list(80, 90)))

// Event pool keys
GLOBAL_LIST_INIT(cardgame_events, list(
	"wounded_fixer", "trap", "cache",
	"merchant", "shrine", "gamble"))

// Node type names for reference
// combat, elite, rest, shop, event, boss

/obj/machinery/computer/arcade/cardgame
	name = "Fixer's Gambit Arcade"
	desc = "Clear the Syndicate hideout. 12 floors. One deck. No mercy."
	icon_state = "arcade"
	icon_keyboard = "no_keyboard"
	icon_screen = "invaders"
	light_color = "#aa6633"
	circuit = /obj/item/circuitboard/computer/arcade/cardgame
	/// Leaderboard
	var/list/leaderboard = list()
	/// Sound throttle
	var/last_sfx_time = 0

/obj/machinery/computer/arcade/cardgame/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ArcadeCardGame", name)
		ui.open()

/obj/machinery/computer/arcade/cardgame/ui_static_data(mob/user)
	var/list/data = list()
	data["map"] = generate_map()
	return data

/obj/machinery/computer/arcade/cardgame/ui_data(mob/user)
	var/list/data = list()
	data["leaderboard"] = leaderboard
	return data

/obj/machinery/computer/arcade/cardgame/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("submit_score")
			var/score = text2num(params["score"])
			var/pname = usr?.name || "Unknown"
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
				if("card")
					playsound(loc, 'sound/arcade/mana.ogg', 20, TRUE)
			. = TRUE

/// Generate 12-row map with random nodes and connections
/obj/machinery/computer/arcade/cardgame/proc/generate_map()
	var/list/rows = list()

	for(var/row in 1 to 12)
		var/list/nodes = list()
		var/node_count = 3
		if(row == 12)
			// Boss row: always 1 node
			node_count = 1
		else if(row == 1)
			// First row: always combat, 3 nodes
			node_count = 3
		else
			node_count = rand(2, 4)

		for(var/n in 1 to node_count)
			var/list/node = list()

			// Determine node type
			var/ntype = "combat"
			if(row == 12)
				ntype = "boss"
			else if(row == 1)
				ntype = "combat"
			else
				var/roll = rand(1, 100)
				if(roll <= 45)
					ntype = "combat"
				else if(roll <= 60)
					ntype = "elite"
				else if(roll <= 72)
					ntype = "rest"
				else if(roll <= 84)
					ntype = "shop"
				else
					ntype = "event"

			node["type"] = ntype

			// Generate content based on type
			if(ntype == "boss")
				var/list/hp_range = GLOB.cardgame_enemy_hp["thumb_capo"]
				node["enemies"] = list(list("type" = "thumb_capo", "hp" = rand(hp_range[1], hp_range[2])))
			else if(ntype == "combat" || ntype == "elite")
				node["enemies"] = generate_encounter(row, ntype == "elite")
			if(ntype == "combat" || ntype == "elite" || ntype == "boss")
				node["rewards"] = generate_card_reward()
			if(ntype == "shop")
				node["shopCards"] = generate_card_reward()
				node["shopAug"] = pick(GLOB.cardgame_augment_pool)
			if(ntype == "event")
				node["event"] = pick(GLOB.cardgame_events)

			// Connections to next row (filled after)
			node["conns"] = list()
			nodes += list(node)

		rows += list(nodes)

	// Generate connections between rows
	for(var/row in 1 to 11)
		var/list/cur_row = rows[row]
		var/list/next_row = rows[row + 1]
		var/cur_len = length(cur_row)
		var/next_len = length(next_row)

		// Ensure every node has at least 1 connection
		for(var/n in 1 to cur_len)
			// Default: connect to nearest node
			var/default_conn = clamp(n, 1, next_len)
			cur_row[n]["conns"] += default_conn

			// Sometimes add extra connection (30%)
			if(prob(30) && next_len > 1)
				var/extra = rand(1, next_len)
				if(!(extra in cur_row[n]["conns"]))
					cur_row[n]["conns"] += extra

			// Rare: add a third connection (10%)
			if(prob(10) && next_len > 2)
				var/extra2 = rand(1, next_len)
				if(!(extra2 in cur_row[n]["conns"]))
					cur_row[n]["conns"] += extra2

		// Ensure every next-row node is reachable
		for(var/n in 1 to next_len)
			var/reachable = FALSE
			for(var/c in 1 to cur_len)
				if(n in cur_row[c]["conns"])
					reachable = TRUE
					break
			if(!reachable)
				// Connect from random current node
				var/from = rand(1, cur_len)
				cur_row[from]["conns"] += n

	return rows

/// Generate an enemy encounter
/obj/machinery/computer/arcade/cardgame/proc/generate_encounter(row, is_elite)
	var/list/pool
	if(is_elite)
		if(row <= 4)
			pool = GLOB.cardgame_elites_t0
		else if(row <= 8)
			pool = GLOB.cardgame_elites_t1
		else
			pool = GLOB.cardgame_elites_t2
	else
		if(row <= 3)
			pool = GLOB.cardgame_encounters_t0
		else if(row <= 7)
			pool = GLOB.cardgame_encounters_t1
		else
			pool = GLOB.cardgame_encounters_t2

	var/comp = pick(pool)
	var/list/keys = splittext(comp, ",")
	var/list/enemies = list()
	for(var/key in keys)
		var/list/hp_range = GLOB.cardgame_enemy_hp[key]
		var/hp = rand(hp_range[1], hp_range[2])
		enemies += list(list("type" = key, "hp" = hp))
	return enemies

/// Generate a set of 3 card reward picks
/obj/machinery/computer/arcade/cardgame/proc/generate_card_reward()
	var/list/pool = GLOB.cardgame_reward_pool.Copy()
	var/list/choices = list()
	for(var/j in 1 to 3)
		if(!length(pool))
			break
		var/pick_val = pick(pool)
		pool -= pick_val
		choices += pick_val
	return choices

// Circuit board
/obj/item/circuitboard/computer/arcade/cardgame
	name = "Fixer's Gambit Arcade (Computer Board)"
	icon_state = "generic"
	build_path = /obj/machinery/computer/arcade/cardgame
