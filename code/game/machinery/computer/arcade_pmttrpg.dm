// PM TTRPG Arcade - Turn-based tactical RPG based on the Project Moon TTRPG Community Rulebook 3.x
// Persistent saves per-ckey across all machines

GLOBAL_LIST_INIT(pmttrpg_saves, list())

// ========== EFFECT VALIDATION TABLES ==========
// Parallel to JS effect tables. Only key, max amount, and cost per N needed for validation.
// Format: "effect_key" = list("cost" = X, "max" = Y, "flat" = TRUE/FALSE)
// flat = TRUE means cost is flat (not multiplied by N), max is ignored

// Effect entry keys:
//   cost, max - cost per amount, max stacks
//   flat - flat-cost effect (amount always 1)
//   can_neg - can be taken as negative
//   needs_result - needs clash_win/lose sel
//   needs_type - needs atk/def sel
//   melee_only - melee weapons only

GLOBAL_LIST_INIT(pmttrpg_weapon_effects, list(
	"dice_power_up" = list("cost" = 8, "max" = 5, "can_neg" = TRUE),
	"dice_max_up" = list("cost" = 4, "max" = 5, "can_neg" = TRUE),
	"inflict_burn" = list("cost" = 2, "max" = 5, "can_neg" = TRUE, "needs_result" = TRUE),
	"inflict_bleed" = list("cost" = 2, "max" = 5, "can_neg" = TRUE, "needs_result" = TRUE),
	"inflict_rupture" = list("cost" = 1, "max" = 5, "can_neg" = TRUE, "needs_result" = TRUE),
	"gain_poise" = list("cost" = 2, "max" = 5, "can_neg" = TRUE, "needs_result" = TRUE),
	"inflict_ruin" = list("cost" = 2, "max" = 5, "can_neg" = TRUE, "needs_result" = TRUE),
	"enemy_power_down" = list("cost" = 8, "max" = 5, "can_neg" = TRUE),
	"m_haste" = list("cost" = 3, "max" = 5, "can_neg" = TRUE, "needs_result" = TRUE, "melee_only" = TRUE),
	"double_edged" = list("cost" = 2, "max" = 1, "flat" = TRUE)))

GLOBAL_LIST_INIT(pmttrpg_outfit_effects, list(
	"block_dice_power_up" = list("cost" = 8, "max" = 5),
	"evade_dice_power_up" = list("cost" = 8, "max" = 5),
	"padded_clothing" = list("cost" = 2, "max" = 5, "can_neg" = TRUE),
	"damage_resistance" = list("cost" = 4, "max" = 3, "can_neg" = TRUE),
	"inflict_burn" = list("cost" = 2, "max" = 5, "can_neg" = TRUE, "needs_result" = TRUE),
	"burn_resistance" = list("cost" = 2, "max" = 5, "can_neg" = TRUE),
	"bleed_resistance" = list("cost" = 3, "max" = 5, "can_neg" = TRUE),
	"additional_reaction" = list("cost" = 8, "max" = 1, "flat" = TRUE)))

GLOBAL_LIST_INIT(pmttrpg_augment_effects, list(
	"regen_hp" = list("cost" = 1, "max" = 5, "can_neg" = TRUE, "needs_type" = TRUE),
	"regen_st" = list("cost" = 1, "max" = 5, "can_neg" = TRUE, "needs_type" = TRUE),
	"inflict_burn" = list("cost" = 2, "max" = 5, "needs_type" = TRUE),
	"burn_bonus" = list("cost" = 2, "max" = 1, "flat" = TRUE, "needs_type" = TRUE),
	"bleed_bonus" = list("cost" = 2, "max" = 1, "flat" = TRUE, "needs_type" = TRUE),
	"activate_strength" = list("cost" = 6, "max" = 1, "flat" = TRUE, "can_neg" = TRUE),
	"stat_increase" = list("cost" = 6, "max" = 1, "flat" = TRUE, "can_neg" = TRUE),
	"damage_resistance" = list("cost" = 4, "max" = 3, "can_neg" = TRUE)))

GLOBAL_LIST_INIT(pmttrpg_skill_effects, list(
	"dice_power_up" = list("cost" = 6, "max" = 5, "can_neg" = TRUE),
	"dice_max_up" = list("cost" = 3, "max" = 5, "can_neg" = TRUE),
	"enemy_power_down" = list("cost" = 6, "max" = 5, "can_neg" = TRUE),
	"inflict_burn" = list("cost" = 2, "max" = 5, "can_neg" = TRUE, "needs_result" = TRUE),
	"inflict_bleed" = list("cost" = 2, "max" = 5, "can_neg" = TRUE, "needs_result" = TRUE),
	"inflict_rupture" = list("cost" = 1, "max" = 5, "can_neg" = TRUE, "needs_result" = TRUE),
	"gain_poise" = list("cost" = 2, "max" = 5, "can_neg" = TRUE, "needs_result" = TRUE),
	"regen_hp" = list("cost" = 1, "max" = 5, "can_neg" = TRUE, "needs_result" = TRUE),
	"haste" = list("cost" = 3, "max" = 5, "can_neg" = TRUE, "needs_result" = TRUE),
	"protection" = list("cost" = 1, "max" = 5, "needs_result" = TRUE)))

// Resistance level index (fatal=0..immune=5)
// Rank 1 defaults: 1 Weak HP + 2 Weak ST
// = 4 normals * 2 + 3 weaks * 1 = 11... wait
// 6 resistances: 5 normal (2 each) + sum weak
// Actually: slash_hp=weak(1), pierce_hp=normal(2),
// blunt_hp=normal(2), slash_st=weak(1),
// pierce_st=normal(2), blunt_st=weak(1) = 9
GLOBAL_LIST_INIT(pmttrpg_resist_level_idx, list(
	"fatal" = 0, "weak" = 1, "normal" = 2,
	"endured" = 3, "ineffective" = 4,
	"immune" = 5))

#define PMTTRPG_RANK1_RESIST_TOTAL 9
#define PMTTRPG_RANK1_RESIST_MAX_IDX 3

// Valid choices for equipment properties
GLOBAL_LIST_INIT(pmttrpg_valid_melee_forms, list("small", "medium", "long", "sturdy", "hybrid"))
GLOBAL_LIST_INIT(pmttrpg_valid_ranged_forms, list("low_caliber", "high_caliber", "reactive", "hybrid"))
GLOBAL_LIST_INIT(pmttrpg_valid_melee_hands, list("off_1h", "off_2h", "def_1h", "def_2h"))
GLOBAL_LIST_INIT(pmttrpg_valid_ranged_hands, list("off_1h", "off_2h"))
GLOBAL_LIST_INIT(pmttrpg_valid_outfit_props, list("armored", "swift", "balanced"))
GLOBAL_LIST_INIT(pmttrpg_valid_dmg_types, list("slash", "pierce", "blunt"))
GLOBAL_LIST_INIT(pmttrpg_valid_skill_types, list("attack", "block", "evade"))
GLOBAL_LIST_INIT(pmttrpg_valid_stats, list("fortitude", "prudence", "justice", "charm", "insight", "temperance"))
GLOBAL_LIST_INIT(pmttrpg_valid_resist_levels, list("fatal", "weak", "normal", "endured", "ineffective", "immune"))

// ========== MACHINE DEFINITION ==========

/obj/machinery/computer/arcade/pmttrpg
	name = "The City - A Fixer's Chronicle"
	desc = "A tactical RPG arcade machine. Your save persists across all machines."
	icon_state = "arcade"
	icon_keyboard = "no_keyboard"
	icon_screen = "invaders"
	light_color = "#9966cc"
	circuit = /obj/item/circuitboard/computer/arcade/pmttrpg
	var/list/leaderboard = list()
	var/last_sfx_time = 0

// ========== SAVE/LOAD SYSTEM ==========

/obj/machinery/computer/arcade/pmttrpg/proc/get_save_path(ckey)
	return "data/player_saves/[ckey[1]]/[ckey]/pmttrpg.sav"

/obj/machinery/computer/arcade/pmttrpg/proc/has_save(ckey)
	if(GLOB.pmttrpg_saves[ckey])
		return TRUE
	return fexists(get_save_path(ckey))

/obj/machinery/computer/arcade/pmttrpg/proc/load_save(ckey)
	// Check memory cache first
	if(GLOB.pmttrpg_saves[ckey])
		return GLOB.pmttrpg_saves[ckey]
	// Try disk
	var/path = get_save_path(ckey)
	if(!fexists(path))
		return null
	var/savefile/S = new /savefile(path)
	var/json_str
	S["data"] >> json_str
	if(!json_str)
		return null
	var/list/save_data = json_decode(json_str)
	if(!islist(save_data))
		return null
	// Cache it
	GLOB.pmttrpg_saves[ckey] = save_data
	return save_data

/obj/machinery/computer/arcade/pmttrpg/proc/write_save(ckey, list/save_data)
	// Update cache
	GLOB.pmttrpg_saves[ckey] = save_data
	// Write to disk
	var/path = get_save_path(ckey)
	var/savefile/S = new /savefile(path)
	S["data"] << json_encode(save_data)

/obj/machinery/computer/arcade/pmttrpg/proc/delete_save(ckey)
	GLOB.pmttrpg_saves -= ckey
	var/path = get_save_path(ckey)
	if(fexists(path))
		fdel(path)

// ========== TGUI INTERFACE ==========

/obj/machinery/computer/arcade/pmttrpg/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ArcadePMTTRPG", name)
		ui.open()

/obj/machinery/computer/arcade/pmttrpg/ui_static_data(mob/user)
	var/list/data = list()
	var/ck = user.ckey
	data["has_save"] = has_save(ck)
	if(data["has_save"])
		data["save_data"] = load_save(ck)
	else
		data["save_data"] = null
	data["leaderboard"] = leaderboard
	return data

/obj/machinery/computer/arcade/pmttrpg/ui_data(mob/user)
	var/list/data = list()
	data["leaderboard"] = leaderboard
	return data

/obj/machinery/computer/arcade/pmttrpg/ui_act(action, params)
	. = ..()
	if(.)
		return
	var/ck = usr.ckey
	switch(action)
		if("create_character")
			var/json_str = params["data"]
			if(!json_str)
				return
			var/list/char_data = json_decode(json_str)
			if(!islist(char_data))
				return
			var/validation = validate_character(char_data)
			if(validation != TRUE)
				// Send error back - for now just log it
				log_game("PMTTRPG: Character validation failed for [ck]: [validation]")
				return
			// Build save data
			var/list/save_data = list()
			save_data["version"] = 1
			save_data["created"] = TRUE
			save_data["character"] = char_data
			save_data["ahn"] = 1000000
			save_data["inventory"] = list()
			save_data["progress"] = list("district" = 1, "boss_killed" = list())
			write_save(ck, save_data)
			update_static_data(usr)
			playsound(loc, 'sound/arcade/win.ogg', 50, TRUE)
			. = TRUE
		if("delete_save")
			delete_save(ck)
			update_static_data(usr)
			. = TRUE
		if("sfx")
			var/snd = params["s"]
			if(world.time - last_sfx_time < 3)
				return
			last_sfx_time = world.time
			switch(snd)
				if("click")
					playsound(loc, 'sound/arcade/mana.ogg', 20, TRUE)
				if("confirm")
					playsound(loc, 'sound/arcade/win.ogg', 30, TRUE)
				if("back")
					playsound(loc, 'sound/arcade/steal.ogg', 20, TRUE)
				if("error")
					playsound(loc, 'sound/arcade/lose.ogg', 30, TRUE)
			. = TRUE
		if("submit_score")
			var/score = text2num(params["score"])
			var/pname = params["name"]
			if(!pname || length(pname) < 1)
				pname = usr?.name || "???"
			pname = copytext(pname, 1, 21)
			leaderboard += list(list("name" = pname, "score" = score))
			leaderboard = sortTim(leaderboard, /proc/cmp_leaderboard_desc)
			if(length(leaderboard) > 10)
				leaderboard.Cut(11)
			prizevend(usr)
			playsound(loc, 'sound/arcade/win.ogg', 50, TRUE)
			. = TRUE

// ========== VALIDATION PROCS ==========

/obj/machinery/computer/arcade/pmttrpg/proc/validate_character(list/char_data)
	// Validate stats
	var/list/stats = char_data["stats"]
	if(!islist(stats))
		return "Missing stats"
	var/stat_sum = 0
	for(var/stat_name in GLOB.pmttrpg_valid_stats)
		var/val = stats[stat_name]
		if(!isnum(val))
			return "Invalid stat [stat_name]"
		if(val < -1 || val > 3)
			return "Stat [stat_name] out of range: [val]"
		stat_sum += val
	if(stat_sum != 6)
		return "Stat sum must be 6, got [stat_sum]"

	// Validate weapon
	var/list/weapon = char_data["weapon"]
	if(!islist(weapon))
		return "Missing weapon"
	var/wtype = weapon["type"]
	if(wtype != "melee" && wtype != "ranged")
		return "Invalid weapon type"
	var/dmg_type = weapon["dmg_type"]
	if(wtype == "melee" && !(dmg_type in GLOB.pmttrpg_valid_dmg_types))
		return "Invalid damage type"
	var/form = weapon["form"]
	if(wtype == "melee" && !(form in GLOB.pmttrpg_valid_melee_forms))
		return "Invalid melee form"
	if(wtype == "ranged" && !(form in GLOB.pmttrpg_valid_ranged_forms))
		return "Invalid ranged form"
	var/hand = weapon["hand"]
	if(wtype == "melee" && !(hand in GLOB.pmttrpg_valid_melee_hands))
		return "Invalid melee hand"
	if(wtype == "ranged" && !(hand in GLOB.pmttrpg_valid_ranged_hands))
		return "Invalid ranged hand"
	// Validate weapon name (optional but length limited)
	var/wname = weapon["name"]
	if(wname && length(wname) > 24)
		return "Weapon name too long"
	// Calculate weapon EP budget
	var/weapon_ep = 4
	if(hand == "off_2h" || hand == "def_2h")
		weapon_ep += 2
	var/weapon_result = validate_effects(weapon["effects"], GLOB.pmttrpg_weapon_effects, weapon_ep, wtype)
	if(weapon_result != TRUE)
		return "Weapon: [weapon_result]"

	// Validate outfit
	var/list/outfit = char_data["outfit"]
	if(!islist(outfit))
		return "Missing outfit"
	var/prop = outfit["property"]
	if(!(prop in GLOB.pmttrpg_valid_outfit_props))
		return "Invalid outfit property"
	var/oname = outfit["name"]
	if(oname && length(oname) > 24)
		return "Outfit name too long"
	var/outfit_ep = 4
	if(prop == "balanced")
		outfit_ep += 2
	var/outfit_result = validate_effects(outfit["effects"], GLOB.pmttrpg_outfit_effects, outfit_ep, null)
	if(outfit_result != TRUE)
		return "Outfit: [outfit_result]"
	// Validate resistances - sum must match Rank 1
	// default, no level may exceed Endured
	var/list/resists = outfit["resistances"]
	if(!islist(resists))
		return "Missing resistances"
	var/resist_total = 0
	for(var/rk in resists)
		var/lvl = resists[rk]
		if(!(lvl in GLOB.pmttrpg_resist_level_idx))
			return "Invalid resistance [rk]: [lvl]"
		var/idx = GLOB.pmttrpg_resist_level_idx[lvl]
		if(idx > PMTTRPG_RANK1_RESIST_MAX_IDX)
			return "Resistance [rk] exceeds max (Endured) at Rank 1"
		resist_total += idx
	if(resist_total != PMTTRPG_RANK1_RESIST_TOTAL)
		return "Resistance total [resist_total] must be [PMTTRPG_RANK1_RESIST_TOTAL] (trade, don't upgrade)"

	// Validate augment (optional)
	var/list/augment = char_data["augment"]
	if(islist(augment) && length(augment))
		var/augment_result = validate_effects(augment["effects"], GLOB.pmttrpg_augment_effects, 4, null)
		if(augment_result != TRUE)
			return "Augment: [augment_result]"

	// Validate skills
	var/list/skills = char_data["skills"]
	if(!islist(skills) || length(skills) != 2)
		return "Must have exactly 2 skills"
	for(var/i in 1 to 2)
		var/list/skill = skills[i]
		if(!islist(skill))
			return "Skill [i] is invalid"
		var/skill_type = skill["type"]
		if(!(skill_type in GLOB.pmttrpg_valid_skill_types))
			return "Skill [i]: invalid type"
		var/sname = skill["name"]
		if(sname && length(sname) > 24)
			return "Skill [i] name too long"
		var/light_cost = text2num("[skill["light_cost"]]")
		if(!isnum(light_cost) || light_cost < 1 || light_cost > 4)
			return "Skill [i]: light cost must be 1-4"
		var/skill_ep = 4 + ((light_cost - 1) * 1)
		var/skill_result = validate_effects(skill["effects"], GLOB.pmttrpg_skill_effects, skill_ep, null)
		if(skill_result != TRUE)
			return "Skill [i]: [skill_result]"

	// Validate name
	var/char_name = char_data["name"]
	if(!char_name || length(char_name) < 1 || length(char_name) > 24)
		return "Name must be 1-24 characters"

	return TRUE

/// Validate a list of effects against an effect
/// table with an EP budget. weapon_type is
/// optional, used to enforce melee_only effects.
/obj/machinery/computer/arcade/pmttrpg/proc/validate_effects(list/effects, list/effect_table, ep_budget, weapon_type)
	if(!islist(effects))
		return "Effects is not a list"
	var/total_positive_ep = 0
	var/total_negative_ep = 0
	for(var/list/eff in effects)
		var/key = eff["key"]
		if(!key || !(key in effect_table))
			return "Unknown effect: [key]"
		var/list/def = effect_table[key]
		// Melee-only check
		if(def["melee_only"] && weapon_type != "melee")
			return "[key] is melee-only"
		var/amount = text2num("[eff["amount"]]")
		if(!isnum(amount) || amount == 0)
			return "Invalid amount for [key]"
		var/is_negative = eff["negative"]
		// Check can_neg flag
		if(is_negative && !def["can_neg"])
			return "[key] cannot be negative"
		// Check needs_result proc selection
		if(def["needs_result"])
			var/proc_val = eff["proc"]
			if(proc_val != "clash_win" && proc_val != "clash_lose")
				return "[key] needs proc: clash_win/clash_lose"
		// Check needs_type selection
		if(def["needs_type"])
			var/type_val = eff["type_sel"]
			if(type_val != "attack" && type_val != "defense")
				return "[key] needs type: attack/defense"
		var/abs_amount = abs(amount)
		if(!def["flat"] && abs_amount > def["max"])
			return "[key] amount [abs_amount] exceeds max [def["max"]]"
		if(def["flat"] && abs_amount > 1)
			return "[key] is flat cost, amount must be 1"
		var/cost
		if(def["flat"])
			cost = def["cost"]
		else
			cost = def["cost"] * abs_amount
		if(is_negative)
			total_negative_ep += cost
		else
			total_positive_ep += cost
	if(total_negative_ep > ep_budget)
		return "Negative EP [total_negative_ep] exceeds budget [ep_budget]"
	if(total_positive_ep > ep_budget + total_negative_ep)
		return "Positive EP [total_positive_ep] exceeds budget [ep_budget + total_negative_ep]"
	return TRUE

// Circuit board is defined in code/game/objects/items/circuitboards/computer_circuitboards.dm
