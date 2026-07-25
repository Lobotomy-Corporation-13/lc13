// ============================================================
// Path of The Hunt (Aeon: Lan)
// ============================================================
// Single-target assassin / Boss killer. Wind element.
// Highest single-target burst, SPD debuff on crit,
// conditional Ult bonus on slowed targets, RES PEN from allies.
// ============================================================

/datum/path/hunt
	name = "The Hunt"
	desc = "Deals extraordinary single-target damage. The main damage dealer against Elite Enemies."
	icon_state = "destruction"
	path_screen_icon = "hunt_path"
	path_ultimate_icon = "ethereal_dream"
	element_type = PATH_ELEMENT_WIND
	max_energy = 100
	path_weapon_type = /obj/item/ego_weapon/path_weapon/hunt
	path_suit_type = /obj/item/clothing/suit/path_hunt
	basic_attack_type = /datum/path_ability/basic/hunt
	burst_action_type = /datum/path_ability/burst/hunt
	ultimate_type = /datum/path_ability/ultimate/hunt
	passive_type = /datum/path_ability/passive/hunt

	/// Cooldown for Faster Than Light (bonus_a4)
	var/ftl_cooldown = 0
	/// Whether passive RES PEN is active for next attack
	var/passive_res_pen_active = FALSE
	/// Passive RES PEN cooldown
	var/passive_res_pen_cd = 0

	// Stat table: list(phase, level, HP, ATK, DEF, SPD)
	stat_table = list(
		list(0, 1,   120, 74,  54,  100),
		list(0, 20,  191, 119, 86,  100),
		list(1, 20,  222, 137, 99,  100),
		list(1, 30,  259, 161, 116, 100),
		list(2, 30,  289, 179, 130, 100),
		list(2, 40,  327, 203, 147, 100),
		list(3, 40,  357, 221, 161, 100),
		list(3, 50,  395, 244, 178, 100),
		list(4, 50,  425, 263, 191, 100),
		list(4, 60,  462, 286, 208, 100),
		list(5, 60,  492, 305, 221, 100),
		list(5, 70,  530, 328, 238, 100),
		list(6, 70,  560, 347, 252, 100),
		list(6, 80,  598, 370, 268, 100)
	)

// ============================================================
// Hunt Weapon
// ============================================================

/obj/item/ego_weapon/path_weapon/hunt
	name = "cloud-piercer spear"
	desc = "A long spear with a teal steel leaf-blade, a yin-yang socket, and a red-wrapped grip along its dark haft. It is honed by the wind itself."
	icon = 'ModularLobotomy/_Lobotomyicons/path_icons.dmi'
	icon_state = "hunt"
	inhand_icon_state = "hunt"
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/path_left.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/path_right.dmi'
	hitsound = 'sound/weapons/bladeslice.ogg'
	swingstyle = WEAPONSWING_THRUST

// ============================================================
// Cosmetic Suit
// ============================================================

/obj/item/clothing/suit/path_hunt
	name = "wanderer's coat"
	desc = "A white long coat with teal-embroidered shoulders, worn open over a black high-collar shirt and grey trousers. A Pathstrider's mark of the Hunt. Purely ceremonial: a Pathstrider is protected by their own DEF, not by cloth."
	icon = 'ModularLobotomy/_Lobotomyicons/path_icons.dmi'
	icon_state = "hunt_suit"
	worn_icon = 'ModularLobotomy/_Lobotomyicons/path_worn.dmi'
	worn_icon_state = "hunt_suit"
	body_parts_covered = CHEST|GROIN|ARMS|LEGS
	blood_overlay_type = null
	w_class = WEIGHT_CLASS_NORMAL

// ============================================================
// Basic ATK: Cloudlancer Art: North Wind
// ============================================================
// Melee Hit | Energy Generation: 20 | Wind
// Deals Wind DMG equal to 50%-110% of ATK to the target.
// ============================================================

/datum/path_ability/basic/hunt
	name = "Cloudlancer Art: North Wind"
	desc = "Deals Wind DMG scaling off ATK to the target. High Gale bonus: +40% DMG to slowed enemies. First hit of a turn deals full damage, later swings deal 30%."
	icon_state = "north_wind"
	energy_gain = 20
	max_level = 7
	/// ATK% scaling per level: 50% at lv1 to 70% at lv7 (1.4× growth)
	var/list/atk_scaling = list(50, 53, 57, 60, 63, 67, 70)

/datum/path_ability/basic/hunt/GetScalingData()
	var/list/data = list()
	data["ATK Scaling"] = "[atk_scaling[level]]%"
	if(parent_path)
		var/atk = parent_path.GetStat("ATK")
		var/dmg = parent_path.EstimateDamage(atk * atk_scaling[level] / 100)
		data["Damage (first hit)"] = "[dmg]"
		data["Damage (later swings)"] = "[parent_path.EstimateDamage(atk * atk_scaling[level] / 100 * PATH_FOLLOWUP_MULT)]"
	data["Energy Gain"] = "[energy_gain]"
	return data

/datum/path_ability/basic/hunt/GetRawScaling()
	return atk_scaling

/datum/path_ability/basic/hunt/OnHit(mob/living/target, mob/living/user, first_hit = TRUE)
	if(!parent_path)
		return
	var/multiplier = atk_scaling[level] / 100

	// High Gale (A6 bonus): +40% DMG to slowed enemies
	var/datum/path/hunt/H = parent_path
	if(istype(H) && H.HasBonus("bonus_a6"))
		if(has_path_spd_debuff(target))
			multiplier *= 1.4

	var/total_damage = parent_path.GetStat("ATK") * multiplier
	if(!first_hit)
		total_damage *= PATH_FOLLOWUP_MULT
	var/basic_factor = parent_path.PvPScalingFactor(level, atk_scaling, PATH_TARGET_TRACE_BASIC)
	parent_path.deal_path_damage(target, total_damage, pvp_factor = basic_factor)

// ============================================================
// Skill: Cloudlancer Art: Torrent
// ============================================================
// Melee Lunge | Energy Generation: 30 | Wind
// 2-tile range lunge. On CRIT: applies 12% SPD debuff for 20s.
// ============================================================

/datum/path_ability/burst/hunt
	name = "Cloudlancer Art: Torrent"
	desc = "Dashes through a target in a 4-tile deep, 3-wide cone, dealing Wind DMG scaling off ATK. On CRIT: applies 12% SPD debuff for 20s. Costs 1 AP."
	icon_state = "torrent"
	energy_gain = 30
	ap_cost = 1
	max_level = 12
	/// ATK% scaling
	var/list/atk_scaling = list(130, 143, 156, 169, 182, 195, 211.25, 227.5, 243.75, 260, 273, 286)

/datum/path_ability/burst/hunt/GetScalingData()
	var/list/data = list()
	data["ATK Scaling"] = "[atk_scaling[level]]%"
	if(parent_path)
		var/atk = parent_path.GetStat("ATK")
		var/dmg = parent_path.EstimateDamage(atk * atk_scaling[level] / 100)
		data["Damage"] = "[dmg]"
	data["Energy Gain"] = "[energy_gain]"
	data["AP Cost"] = "[ap_cost]"
	data["On CRIT"] = "12% SPD debuff (20s)"
	return data

/datum/path_ability/burst/hunt/GetRawScaling()
	return atk_scaling

/datum/path_ability/burst/hunt/Activate(mob/living/user)
	if(!parent_path)
		return FALSE

	var/atk = parent_path.GetStat("ATK")
	var/multiplier = atk_scaling[level] / 100

	// Find target: 4 tiles deep, 3 tiles wide
	var/mob/living/target
	var/turf/center = get_turf(user)
	var/perpendicular = turn(user.dir, 90)
	var/perpendicular2 = turn(user.dir, -90)
	for(var/i in 1 to 4)
		center = get_step(center, user.dir)
		if(!center)
			break
		// Check center tile + 1 tile each side
		var/list/check_turfs = list(center)
		var/turf/side1 = get_step(center, perpendicular)
		var/turf/side2 = get_step(center, perpendicular2)
		if(side1)
			check_turfs += side1
		if(side2)
			check_turfs += side2
		for(var/turf/CT in check_turfs)
			for(var/mob/living/L in CT)
				target = GetPathTarget(L, user)
				if(target)
					break
			if(target)
				break
		if(target)
			break

	if(!target)
		to_chat(user, span_warning("Cloudlancer Art: Torrent missed - no enemy in range!"))
		return FALSE

	var/damage = atk * multiplier

	// Apply RES PEN from passive if active
	var/datum/path/hunt/H = parent_path
	var/temp_res_pen = 0
	if(istype(H) && H.passive_res_pen_active)
		var/datum/path_ability/passive/hunt/pp = parent_path.passive_effect
		if(istype(pp))
			temp_res_pen = pp.res_pen_scaling[pp.level]
		H.passive_res_pen_active = FALSE

	// Temporarily boost RES PEN for this hit
	var/old_res_pen = parent_path.res_pen
	parent_path.res_pen += temp_res_pen

	// Deal damage (deal_path_damage handles crit)
	var/skill_factor = parent_path.PvPScalingFactor(level, atk_scaling, PATH_TARGET_TRACE_SKILL)
	parent_path.deal_path_damage(target, damage, pvp_factor = skill_factor)

	// Restore RES PEN
	parent_path.res_pen = old_res_pen

	// Check if the hit was a crit (dealt > base damage)
	// Simple approach: roll crit separately for SPD debuff
	var/crit_rate = parent_path.GetStat("CRIT Rate")
	if(prob(crit_rate))
		apply_path_spd_change(target, 12, 20 SECONDS)
		to_chat(user, span_nicegreen("CRIT! SPD debuff applied to [target]!"))

	// Dash through: land on opposite side of target
	var/turf/target_turf = get_turf(target)
	var/turf/landing = get_step(target_turf, user.dir)
	if(landing && !landing.density)
		var/blocked = FALSE
		for(var/obj/O in landing)
			if(O.density)
				blocked = TRUE
				break
		if(!blocked)
			user.forceMove(landing)
			user.setDir(turn(user.dir, 180))

	// VFX: dash line with sparks and beam
	var/turf/slash_start = get_turf(user)
	var/list/hitline = getline(slash_start, target_turf)
	for(var/turf/HT in hitline)
		new /obj/effect/temp_visual/cult/sparks(HT)
	new /datum/beam(slash_start.Beam(target_turf, "1-full", time = 3))
	playsound(target_turf, 'sound/weapons/bladeslice.ogg', 60, TRUE)
	for(var/mob/living/M in view(7, user))
		if(M.client)
			shake_camera(M, 2, 1)
	user.visible_message(span_danger("[user] dashes through [target] with Cloudlancer Art: Torrent!"))
	return TRUE

// ============================================================
// Ultimate: Ethereal Dream
// ============================================================
// Targeted Strike | Energy Cost: 100 | Energy Gen: 5 | Wind
// 3-tile range. Bonus DMG vs SPD-debuffed targets.
// ============================================================

/datum/path_ability/ultimate/hunt
	name = "Ethereal Dream"
	desc = "Targets nearest enemy in a 5-tile deep, 3-wide cone. Pause, dash through for 10% DMG, then delayed 90% hit. Bonus damage if target is SPD-debuffed."
	icon_state = "ethereal_dream"
	max_level = 12
	/// Base ATK% scaling
	var/list/base_scaling = list(240, 256, 272, 288, 304, 320, 340, 360, 380, 400, 416, 432)
	/// SPD-debuff bonus scaling
	var/list/spd_bonus = list(72, 76.8, 81.6, 86.4, 91.2, 96, 102, 108, 114, 120, 124.8, 129.6)

/datum/path_ability/ultimate/hunt/GetScalingData()
	var/list/data = list()
	if(parent_path)
		var/atk = parent_path.GetStat("ATK")
		var/base_dmg = parent_path.EstimateDamage(atk * base_scaling[level] / 100)
		var/total_pct = base_scaling[level] + spd_bonus[level]
		var/bonus_dmg = parent_path.EstimateDamage(atk * total_pct / 100)
		data["Base"] = "[base_scaling[level]]% ([base_dmg] dmg)"
		data["vs Slowed"] = "[total_pct]% ([bonus_dmg] dmg)"
		data["Energy Cost"] = "[parent_path.max_energy]"
		data["Energy Gen"] = "5"
	return data

/datum/path_ability/ultimate/hunt/GetRawScaling()
	return base_scaling

/datum/path_ability/ultimate/hunt/Activate(mob/living/user)
	if(!parent_path)
		return
	// Spend energy (parent handles this)
	..()

	var/atk = parent_path.GetStat("ATK")

	// Find target: 5 tiles deep, 3 tiles wide
	var/mob/living/target
	var/turf/center = get_turf(user)
	var/perpendicular = turn(user.dir, 90)
	var/perpendicular2 = turn(user.dir, -90)
	for(var/i in 1 to 5)
		center = get_step(center, user.dir)
		if(!center)
			break
		var/list/check_turfs = list(center)
		var/turf/side1 = get_step(center, perpendicular)
		var/turf/side2 = get_step(center, perpendicular2)
		if(side1)
			check_turfs += side1
		if(side2)
			check_turfs += side2
		for(var/turf/CT in check_turfs)
			for(var/mob/living/L in CT)
				if(L == user || L.stat == DEAD)
					continue
				if(!PathCanHarm(L))
					continue
				if(IsPathAlly(user, L))
					continue
				target = L
				break
			if(target)
				break
		if(target)
			break

	if(!target)
		to_chat(user, span_warning("Ethereal Dream - no enemy in range!"))
		// Refund energy since we missed
		parent_path.GainEnergy(parent_path.max_energy)
		return

	// Calculate total damage
	var/multiplier = base_scaling[level]
	var/slowed = has_path_spd_debuff(target)
	if(slowed)
		multiplier += spd_bonus[level]
		to_chat(user, span_nicegreen("Ethereal Dream bonus: target is slowed!"))

	var/total_damage = atk * multiplier / 100

	// PvP factor: target curve is base+spd_bonus when slowed, else just base.
	// Build the summed scaling table when slowed so target vs actual is
	// computed against the same combined curve.
	var/list/factor_table = base_scaling
	if(slowed)
		factor_table = list()
		for(var/i in 1 to length(base_scaling))
			factor_table += list(base_scaling[i] + spd_bonus[i])
	var/ult_factor = parent_path.PvPScalingFactor(level, factor_table, PATH_TARGET_TRACE_ULT)

	// Phase 1: Pause — user draws weapon
	user.visible_message(span_danger("[user] focuses intently on [target]..."))
	playsound(get_turf(user), 'sound/weapons/saberon.ogg', 70, TRUE, 5)

	// Immobilize user briefly during the sequence
	ADD_TRAIT(user, TRAIT_IMMOBILIZED, "ethereal_dream")

	// Phase 2: After 0.5s, dash through + 10% damage
	var/datum/path/path_ref = parent_path
	addtimer(CALLBACK(src, PROC_REF(UltDash), user, target, total_damage, path_ref, ult_factor), 5)

/// Phase 2: Dash through the target, deal 10% damage
/datum/path_ability/ultimate/hunt/proc/UltDash(mob/living/user, mob/living/target, total_damage, datum/path/path_ref, pvp_factor = 1)
	if(QDELETED(user) || QDELETED(target))
		REMOVE_TRAIT(user, TRAIT_IMMOBILIZED, "ethereal_dream")
		return

	// Deal 10% on the pass-through
	var/slash_dmg = total_damage * 0.1
	path_ref.deal_path_damage(target, slash_dmg, do_crit = FALSE, pvp_factor = pvp_factor)

	// Dash through to opposite side
	var/turf/target_turf = get_turf(target)
	var/dash_dir = get_dir(user, target)
	var/turf/landing = get_step(target_turf, dash_dir)
	if(landing && !landing.density)
		var/blocked = FALSE
		for(var/obj/O in landing)
			if(O.density)
				blocked = TRUE
				break
		if(!blocked)
			user.forceMove(landing)
			user.setDir(turn(dash_dir, 180))

	// Slash VFX: sparks and beam on dash line
	var/turf/slash_start = get_turf(user)
	var/list/hitline = getline(slash_start, target_turf)
	for(var/turf/HT in hitline)
		new /obj/effect/temp_visual/cult/sparks(HT)
	new /datum/beam(slash_start.Beam(target_turf, "1-full", time = 3))
	playsound(target_turf, 'sound/weapons/bladeslice.ogg', 60, TRUE)

	// Phase 3: After 1s, delayed hit for 90%
	addtimer(CALLBACK(src, PROC_REF(UltDelayedHit), user, target, total_damage, path_ref, pvp_factor), 10)

/// Phase 3: Delayed damage hit with VFX
/datum/path_ability/ultimate/hunt/proc/UltDelayedHit(mob/living/user, mob/living/target, total_damage, datum/path/path_ref, pvp_factor = 1)
	// Free the user
	REMOVE_TRAIT(user, TRAIT_IMMOBILIZED, "ethereal_dream")

	if(QDELETED(target))
		return

	// Deal remaining 90%
	var/delayed_dmg = total_damage * 0.9
	path_ref.deal_path_damage(target, delayed_dmg, do_crit = FALSE, pvp_factor = pvp_factor)

	// Grant 5 energy
	path_ref.GainEnergy(5)

	// VFX: big slash effect on target
	var/turf/target_turf = get_turf(target)
	new /obj/effect/temp_visual/smash_effect(target_turf)
	for(var/mob/living/M in view(7, target))
		if(M.client)
			shake_camera(M, 4, 3)
	playsound(target_turf, 'sound/weapons/smash.ogg', 70, TRUE)
	user.visible_message(span_danger("Ethereal Dream strikes [target]!"))

// ============================================================
// Passive: Superiority of Reach
// ============================================================
// On Ally Buff | Wind
// When an ally uses a supportive ability on the user, next
// attack's Wind RES PEN increases. 20s cooldown.
// ============================================================

/datum/path_ability/passive/hunt
	name = "Superiority of Reach"
	desc = "When a path ally buffs you, your next attack gains Wind RES PEN%. 20 second cooldown between triggers."
	icon_state = "superiority_reach"
	max_level = 12
	/// RES PEN % per level
	var/list/res_pen_scaling = list(18, 19.8, 21.6, 23.4, 25.2, 27, 29.25, 31.5, 33.75, 36, 37.8, 39.6)

/datum/path_ability/passive/hunt/GetScalingData()
	var/list/data = list()
	data["Wind RES PEN"] = "[res_pen_scaling[level]]%"
	data["Cooldown"] = "20s"
	var/datum/path/hunt/H = parent_path
	if(istype(H))
		data["Status"] = H.passive_res_pen_active ? "ACTIVE" : "Ready"
	return data

/datum/path_ability/passive/hunt/GetRawScaling()
	return res_pen_scaling

/datum/path_ability/passive/hunt/Apply(mob/living/user)
	RegisterSignal(user, COMSIG_MOB_PATH_ALLY_BUFFED, PROC_REF(OnAllyBuff))

/datum/path_ability/passive/hunt/Unapply(mob/living/user)
	UnregisterSignal(user, COMSIG_MOB_PATH_ALLY_BUFFED)

/// Signal handler: when an ally path user buffs us
/datum/path_ability/passive/hunt/proc/OnAllyBuff(datum/source, datum/path/source_path, buff_type)
	SIGNAL_HANDLER
	if(!parent_path)
		return
	var/datum/path/hunt/H = parent_path
	if(!istype(H))
		return
	// 20s cooldown
	if(world.time < H.passive_res_pen_cd)
		return
	H.passive_res_pen_cd = world.time + 20 SECONDS
	H.passive_res_pen_active = TRUE
	if(H.owner)
		to_chat(H.owner, span_nicegreen("Superiority of Reach! Next attack gains Wind RES PEN!"))

// ============================================================
// Trace Nodes (Skill Tree)
// ============================================================

/datum/path/hunt/InitNodes()
	var/datum/path_node/N

	// --- Core Ability Upgrades (bottom row) ---
	N = new /datum/path_node("core_basic", "Cloudlancer Art: North Wind", "Level up Basic ATK.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_BASIC
	N.level_increase = 1
	N.ahn_cost = 500
	N.connections = list("bonus_a6")
	nodes += N

	N = new /datum/path_node("core_burst", "Cloudlancer Art: Torrent", "Level up Skill.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_BURST
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("bonus_a4")
	nodes += N

	N = new /datum/path_node("core_ultimate", "Ethereal Dream", "Level up Ultimate.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_ULTIMATE
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("core_passive", "bonus_a2")
	nodes += N

	N = new /datum/path_node("core_passive", "Superiority of Reach", "Level up Passive.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_PASSIVE
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("core_basic", "core_burst", "stat_bottom")
	nodes += N

	// --- Bottom stat (below Passive, no gate) ---
	N = new /datum/path_node("stat_bottom", "CRIT Rate Boost", "CRIT Rate increases by 3.2%.")
	N.stat_bonuses = list("CRIT Rate" = 3.2)
	N.stat_percent = TRUE
	N.ahn_cost = 200
	N.tree_x = 2
	N.tree_y = 6
	nodes += N

	// --- Center branch (A1 gate, from Ultimate) ---
	N = new /datum/path_node("bonus_a2", "Hidden Dragon", "When HP is 50% or lower, hostile mobs targeting you have a 50% chance to switch targets.")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 1
	N.tree_x = 2
	N.tree_y = 2
	N.connections = list("stat_c1")
	nodes += N

	N = new /datum/path_node("stat_c1", "DEF Boost", "DEF increases by 5%.")
	N.stat_bonuses = list("DEF" = 5)
	N.stat_percent = TRUE
	N.ahn_cost = 400
	N.required_ascension = 1
	N.tree_x = 2
	N.tree_y = 1
	N.connections = list("stat_c2", "stat_c3")
	N.prerequisites = list("bonus_a2")
	nodes += N

	N = new /datum/path_node("stat_c2", "ATK Boost", "ATK increases by 4%.")
	N.stat_bonuses = list("ATK" = 4)
	N.stat_percent = TRUE
	N.ahn_cost = 300
	N.required_ascension = 2
	N.tree_x = 1
	N.tree_y = 0
	N.prerequisites = list("stat_c1")
	nodes += N

	N = new /datum/path_node("stat_c3", "CRIT Rate Boost", "CRIT Rate increases by 3.2%.")
	N.stat_bonuses = list("CRIT Rate" = 3.2)
	N.stat_percent = TRUE
	N.ahn_cost = 300
	N.required_ascension = 2
	N.tree_x = 3
	N.tree_y = 0
	N.prerequisites = list("stat_c1")
	nodes += N

	// --- Right branch (A3 gate, from Skill) ---
	N = new /datum/path_node("bonus_a4", "Faster Than Light", "After attacking, 50% chance to increase SPD by 20% for 20s.")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 3
	N.tree_x = 4
	N.tree_y = 3
	N.connections = list("stat_r1")
	nodes += N

	N = new /datum/path_node("stat_r1", "CRIT Rate Boost", "CRIT Rate increases by 4.8%.")
	N.stat_bonuses = list("CRIT Rate" = 4.8)
	N.stat_percent = TRUE
	N.ahn_cost = 500
	N.required_ascension = 3
	N.tree_x = 4
	N.tree_y = 2
	N.connections = list("stat_r2")
	N.prerequisites = list("bonus_a4")
	nodes += N

	N = new /datum/path_node("stat_r2", "ATK Boost", "ATK increases by 6%.")
	N.stat_bonuses = list("ATK" = 6)
	N.stat_percent = TRUE
	N.ahn_cost = 600
	N.required_ascension = 4
	N.tree_x = 4
	N.tree_y = 1
	N.connections = list("stat_r3")
	N.prerequisites = list("stat_r1")
	nodes += N

	N = new /datum/path_node("stat_r3", "ATK Boost", "ATK increases by 8%.")
	N.stat_bonuses = list("ATK" = 8)
	N.stat_percent = TRUE
	N.ahn_cost = 750
	N.required_level = 75
	N.tree_x = 4
	N.tree_y = 0
	N.prerequisites = list("stat_r2")
	nodes += N

	// --- Left branch (A5 gate, from Basic ATK) ---
	N = new /datum/path_node("bonus_a6", "High Gale", "Basic ATK deals 40% more DMG to Slowed enemies.")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 5
	N.tree_x = 0
	N.tree_y = 3
	N.connections = list("stat_l1")
	nodes += N

	N = new /datum/path_node("stat_l1", "CRIT Rate Boost", "CRIT Rate increases by 4.8%.")
	N.stat_bonuses = list("CRIT Rate" = 4.8)
	N.stat_percent = TRUE
	N.ahn_cost = 500
	N.required_ascension = 5
	N.tree_x = 0
	N.tree_y = 2
	N.connections = list("stat_l2")
	N.prerequisites = list("bonus_a6")
	nodes += N

	N = new /datum/path_node("stat_l2", "DEF Boost", "DEF increases by 7.5%.")
	N.stat_bonuses = list("DEF" = 7.5)
	N.stat_percent = TRUE
	N.ahn_cost = 700
	N.required_ascension = 5
	N.tree_x = 0
	N.tree_y = 1
	N.connections = list("stat_l3")
	N.prerequisites = list("stat_l1")
	nodes += N

	N = new /datum/path_node("stat_l3", "CRIT Rate Boost", "CRIT Rate increases by 6.4%.")
	N.stat_bonuses = list("CRIT Rate" = 6.4)
	N.stat_percent = TRUE
	N.ahn_cost = 800
	N.required_level = 80
	N.tree_x = 0
	N.tree_y = 0
	N.prerequisites = list("stat_l2")
	nodes += N

// ============================================================
// Bonus Ability Effects
// ============================================================

/// Checks if a bonus ability node is unlocked
/datum/path/hunt/proc/HasBonus(node_id)
	return (node_id in unlocked_nodes)

/// Override GetStat for Hunt-specific bonuses
/datum/path/hunt/GetStat(stat_name)
	return ..()

/datum/path/hunt/OnBonusAbilityUnlocked(node_id)
	switch(node_id)
		if("bonus_a2")
			// Hidden Dragon: checked via mob aggro override
			return
		if("bonus_a4")
			// Faster Than Light: checked in OnWeaponHit
			return
		if("bonus_a6")
			// High Gale: checked in basic OnHit
			return

/// Override OnWeaponHit for Faster Than Light + passive kill check
/datum/path/hunt/OnWeaponHit(mob/living/target, mob/living/user)
	if(target.status_flags & GODMODE) // no attacking/farming invulnerable targets
		return
	..()
	// Faster Than Light (A4): 50% chance SPD +20% for 20s
	if(HasBonus("bonus_a4") && world.time >= ftl_cooldown)
		if(prob(50))
			ftl_cooldown = world.time + 20 SECONDS
			// Temporarily boost SPD by 20%
			to_chat(owner, span_nicegreen("Faster Than Light! SPD boosted!"))
			if(owner)
				owner.add_movespeed_modifier(/datum/movespeed_modifier/path_ftl)
			addtimer(CALLBACK(src, PROC_REF(FTLExpire)), 20 SECONDS)

/// Expires the Faster Than Light SPD buff
/datum/path/hunt/proc/FTLExpire()
	if(owner)
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/path_ftl)

/// Movement speed modifier for Faster Than Light
/datum/movespeed_modifier/path_ftl
	multiplicative_slowdown = -0.4
