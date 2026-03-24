// ============================================================
// Path of Destruction (Aeon: Nanook)
// ============================================================
// Bruiser / All-rounder DPS. Physical element.
// High raw damage, kill-snowball passive, empowered ultimate.
// ============================================================

/datum/path/destruction
	name = "Destruction"
	desc = "Deals outstanding amounts of damage with great survivability."
	icon_state = "destruction"
	element_type = PATH_ELEMENT_PHYSICAL
	max_energy = 120
	path_weapon_type = /obj/item/ego_weapon/path_weapon/destruction
	basic_attack_type = /datum/path_ability/basic/destruction
	burst_action_type = /datum/path_ability/burst/destruction
	ultimate_type = /datum/path_ability/ultimate/destruction
	passive_type = /datum/path_ability/passive/destruction

	/// Cooldown tracker for Ready for Battle (bonus_a2)
	var/ready_for_battle_cd = 0

	// Stat table: list(phase, level, HP, ATK, DEF, SPD)
	stat_table = list(
		list(0, 1,   163, 84,  62,  100),
		list(0, 20,  319, 164, 122, 100),
		list(1, 20,  384, 198, 147, 100),
		list(1, 30,  466, 240, 178, 100),
		list(2, 30,  531, 274, 203, 100),
		list(2, 40,  613, 316, 235, 100),
		list(3, 40,  679, 350, 260, 100),
		list(3, 50,  761, 392, 291, 100),
		list(4, 50,  826, 426, 316, 100),
		list(4, 60,  908, 468, 347, 100),
		list(5, 60,  973, 502, 373, 100),
		list(5, 70,  1055, 544, 404, 100),
		list(6, 70,  1121, 578, 429, 100),
		list(6, 80,  1203, 620, 460, 100)
	)

// ============================================================
// Destruction Weapon
// ============================================================

/obj/item/ego_weapon/path_weapon/destruction
	name = "Destruction Blade"
	desc = "A weapon crackling with destructive energy."
	hitsound = 'sound/weapons/bladeslice.ogg'
	swingstyle = WEAPONSWING_LARGESWEEP

// ============================================================
// Basic ATK: Farewell Hit
// ============================================================
// Melee Hit | Energy Generation: 20 | Physical
// Deals Physical DMG equal to 50%-110% of ATK to the target.
// ============================================================

/datum/path_ability/basic/destruction
	name = "Farewell Hit"
	desc = "Deals Physical DMG to the target hit."
	icon_state = "farewell_hit"
	energy_gain = 20
	max_level = 7
	/// ATK% scaling per level: 50% at lv1 to 110% at lv7
	var/list/atk_scaling = list(50, 60, 70, 80, 90, 100, 110)

/datum/path_ability/basic/destruction/GetScalingData()
	var/list/data = list()
	data["ATK Scaling"] = "[atk_scaling[level]]%"
	if(parent_path)
		var/atk = parent_path.GetStat("ATK")
		var/dmg = round(atk * atk_scaling[level] / 100, 1)
		data["Damage"] = "[dmg]"
	data["Energy Gain"] = "[energy_gain]"
	return data

/datum/path_ability/basic/destruction/OnHit(mob/living/target, mob/living/user, first_hit = TRUE)
	if(!parent_path)
		return
	// Check if Ultimate enhanced this attack
	var/datum/path_ability/ultimate/destruction/ult = parent_path.ultimate_action
	if(istype(ult) && ult.enhanced)
		// Empowered Farewell Hit — use Ultimate scaling, single massive hit
		var/damage = parent_path.GetStat("ATK") * (ult.blowout_fh[ult.level] / 100)
		parent_path.deal_path_damage(target, damage)
		ult.enhanced = FALSE
		// VFX: big impact on target
		new /obj/effect/temp_visual/smash_effect(get_turf(target))
		playsound(get_turf(target), 'sound/weapons/smash.ogg', 60, TRUE)
		for(var/mob/living/M in view(7, user))
			if(M.client)
				shake_camera(M, 3, 2)
		user.visible_message(span_danger("[user] unleashes Blowout: Farewell Hit on [target]!"))
		return

	var/multiplier = atk_scaling[level] / 100
	var/total_damage = parent_path.GetStat("ATK") * multiplier
	if(!first_hit)
		total_damage *= 0.1
	parent_path.deal_path_damage(target, total_damage)

// ============================================================
// Skill: RIP Home Run
// ============================================================
// 1-tile AoE | Energy Generation: 30 | Physical
// Deals Physical DMG to all enemies within 1 tile of the user.
// ============================================================

/datum/path_ability/burst/destruction
	name = "RIP Home Run"
	desc = "Deals Physical DMG to all enemies within 1 tile."
	icon_state = "rip_home_run"
	energy_gain = 30
	ap_cost = 1
	max_level = 12
	/// ATK% scaling: 62.5% at lv1 to 137.5% at lv12
	var/list/atk_scaling = list(62.5, 68.75, 75, 81.25, 87.5, 93.75, 101.56, 109.38, 117.19, 125, 131.25, 137.5)

/datum/path_ability/burst/destruction/GetScalingData()
	var/list/data = list()
	data["ATK Scaling"] = "[atk_scaling[level]]%"
	if(parent_path)
		var/atk = parent_path.GetStat("ATK")
		var/dmg = round(atk * atk_scaling[level] / 100, 1)
		data["Damage (per target)"] = "[dmg]"
	data["Energy Gain"] = "[energy_gain]"
	data["AP Cost"] = "[ap_cost]"
	return data

/datum/path_ability/burst/destruction/Activate(mob/living/user)
	if(!parent_path)
		return

	var/atk = parent_path.GetStat("ATK")
	var/main_damage
	var/adj_damage
	var/is_enhanced = FALSE

	// Check if Ultimate enhanced this skill
	var/datum/path_ability/ultimate/destruction/ult = parent_path.ultimate_action
	if(istype(ult) && ult.enhanced)
		// Empowered RIP Home Run — use Ultimate scaling
		main_damage = atk * (ult.blowout_rip_main[ult.level] / 100)
		adj_damage = atk * (ult.blowout_rip_adj[ult.level] / 100)
		ult.enhanced = FALSE
		is_enhanced = TRUE
	else
		// Normal RIP Home Run — uniform damage
		var/multiplier = atk_scaling[level] / 100
		main_damage = atk * multiplier
		adj_damage = main_damage

	// Fighting Will (A6 bonus): +25% DMG to primary target
	var/fighting_will = FALSE
	var/datum/path/destruction/D = parent_path
	if(istype(D) && D.HasBonus("bonus_a6"))
		fighting_will = TRUE

	// Find primary target (nearest enemy in front)
	var/mob/living/primary
	var/turf/T = get_step(user, user.dir)
	for(var/i in 1 to 2)
		if(!T)
			break
		for(var/mob/living/L in T)
			if(L == user || L.stat == DEAD)
				continue
			primary = L
			break
		if(primary)
			break
		T = get_step(T, user.dir)

	var/hit_count = 0
	if(is_enhanced && primary)
		// Enhanced: main target gets higher damage
		var/primary_dmg = main_damage
		if(fighting_will)
			primary_dmg *= 1.25
		parent_path.deal_path_damage(primary, primary_dmg)
		hit_count++
		// Adjacent enemies get lower damage
		for(var/mob/living/L in range(1, primary))
			if(L == primary || L == user)
				continue
			if(L.stat == DEAD)
				continue
			if(IsPathAlly(user, L))
				continue
			parent_path.deal_path_damage(L, adj_damage)
			hit_count++
	else
		// Normal: AoE around user, primary gets bonus
		for(var/mob/living/L in range(1, user))
			if(L == user)
				continue
			if(L.stat == DEAD)
				continue
			if(IsPathAlly(user, L))
				continue
			var/dmg = main_damage
			// First target hit is "primary" for Fighting Will
			if(fighting_will && hit_count == 0)
				dmg *= 1.25
			parent_path.deal_path_damage(L, dmg)
			hit_count++

	// VFX: smash effect on all tiles in AoE range
	var/atom/aoe_center = user
	if(is_enhanced && primary)
		aoe_center = primary
	for(var/turf/aoe_turf in range(1, aoe_center))
		new /obj/effect/temp_visual/smash_effect(aoe_turf)

	var/mode_name = "RIP Home Run"
	if(is_enhanced)
		mode_name = "Blowout: RIP Home Run"
	playsound(get_turf(user), 'sound/weapons/smash.ogg', 50, TRUE)
	for(var/mob/living/M in view(7, user))
		if(M.client)
			shake_camera(M, is_enhanced ? 4 : 2, is_enhanced ? 3 : 1)
	if(hit_count > 0)
		user.visible_message(span_danger("[user] swings [mode_name], hitting [hit_count] target\s!"))
	else
		user.visible_message(span_danger("[user] swings [mode_name], but hits nothing!"))

// ============================================================
// Ultimate: Stardust Ace
// ============================================================
// Empowered Strike | Energy Cost: 120 | Physical
// Choose between two attack modes.
// Blowout: Farewell Hit — focused strike on target in front.
// Blowout: RIP Home Run — main + 1-tile AoE.
// ============================================================

/datum/path_ability/ultimate/destruction
	name = "Stardust Ace"
	desc = "Empowers your next Basic ATK or Skill with devastating scaling."
	icon_state = "stardust_ace"
	max_level = 12
	/// Blowout: Farewell Hit scaling (for enhanced Basic ATK)
	var/list/blowout_fh = list(300, 315, 330, 345, 360, 375, 393.75, 412.5, 431.25, 450, 465, 480)
	/// Blowout: RIP Home Run main target scaling (for enhanced Skill)
	var/list/blowout_rip_main = list(180, 189, 198, 207, 216, 225, 236.25, 247.5, 258.75, 270, 279, 288)
	/// Blowout: RIP Home Run adjacent target scaling (for enhanced Skill)
	var/list/blowout_rip_adj = list(108, 113.4, 118.8, 124.2, 129.6, 135, 141.75, 148.5, 155.25, 162, 167.4, 172.8)
	/// Whether the next Basic ATK or Skill is empowered
	var/enhanced = FALSE

/datum/path_ability/ultimate/destruction/GetScalingData()
	var/list/data = list()
	if(parent_path)
		var/atk = parent_path.GetStat("ATK")
		data["Blowout: FH"] = "[blowout_fh[level]]% ([round(atk * blowout_fh[level] / 100, 1)] dmg)"
		data["Blowout: RIP Main"] = "[blowout_rip_main[level]]% ([round(atk * blowout_rip_main[level] / 100, 1)] dmg)"
		data["Blowout: RIP Adj"] = "[blowout_rip_adj[level]]% ([round(atk * blowout_rip_adj[level] / 100, 1)] dmg)"
		data["Energy Cost"] = "[parent_path.max_energy]"
	return data

/datum/path_ability/ultimate/destruction/Activate(mob/living/user)
	if(!parent_path)
		return
	// Spend energy (parent handles this)
	..()
	// Set enhanced flag
	enhanced = TRUE

	// VFX: dramatic activation
	playsound(get_turf(user), 'sound/weapons/saberon.ogg', 70, TRUE, 5)
	new /obj/effect/temp_visual/sparkles(get_turf(user))
	for(var/mob/living/M in view(7, user))
		if(M.client)
			shake_camera(M, 3, 2)
	user.visible_message(span_danger("[user] channels Stardust Ace! Their next attack will be devastating!"))
	to_chat(user, span_nicegreen("Stardust Ace activated! Your next attack or skill is empowered!"))

// ============================================================
// Passive: Perfect Pickoff
// ============================================================
// On Kill | Physical
// Each kill increases ATK by 10%-22% for 30 seconds.
// Stacks up to 2 times.
// ============================================================

/datum/path_ability/passive/destruction
	name = "Perfect Pickoff"
	desc = "Each kill increases ATK. Stacks up to 2 times."
	icon_state = "perfect_pickoff"
	max_level = 12
	/// ATK buff % per stack
	var/list/atk_buff_scaling = list(10, 11, 12, 13, 14, 15, 16.25, 17.5, 18.75, 20, 21, 22)
	var/max_stacks = 2
	var/current_stacks = 0

/datum/path_ability/passive/destruction/GetScalingData()
	var/list/data = list()
	data["ATK Buff/Stack"] = "[atk_buff_scaling[level]]%"
	if(parent_path)
		var/atk = parent_path.GetStat("ATK")
		var/buffed = round(atk * (1 + atk_buff_scaling[level] / 100), 1)
		data["ATK at 1 Stack"] = "[buffed]"
		var/buffed2 = round(atk * (1 + (atk_buff_scaling[level] * 2) / 100), 1)
		data["ATK at 2 Stacks"] = "[buffed2]"
	data["Max Stacks"] = "[max_stacks]"
	data["Duration"] = "30s"
	data["Current Stacks"] = "[current_stacks]"
	return data

/datum/path_ability/passive/destruction/Apply(mob/living/user)
	return

/datum/path_ability/passive/destruction/Unapply(mob/living/user)
	current_stacks = 0

/// Called by the path's OnWeaponHit to check for kills
/datum/path_ability/passive/destruction/proc/OnPathHit(mob/living/target)
	if(!isliving(target))
		return
	// Check death after damage resolves
	addtimer(CALLBACK(src, PROC_REF(CheckKill), target), 1)

/datum/path_ability/passive/destruction/proc/CheckKill(mob/living/target)
	if(QDELETED(target))
		return
	if(target.stat != DEAD)
		return
	if(current_stacks >= max_stacks)
		return
	current_stacks++
	var/buff_percent = atk_buff_scaling[level]
	var/msg = "Perfect Pickoff! ATK +[buff_percent]%"

	// Tenacity (A4 bonus): each stack also increases DEF by 10%
	var/datum/path/destruction/D = parent_path
	if(istype(D) && D.HasBonus("bonus_a4"))
		msg += ", DEF +10%"

	msg += " ([current_stacks]/[max_stacks] stacks)"
	to_chat(parent_path.owner, span_nicegreen(msg))
	// Update defense if Tenacity is active
	parent_path.ApplyDefense()
	// Auto-expire stack after 30 seconds
	addtimer(CALLBACK(src, PROC_REF(ExpireStack)), 30 SECONDS)

/datum/path_ability/passive/destruction/proc/ExpireStack()
	if(current_stacks > 0)
		current_stacks--
		// Update defense when stack falls off
		if(parent_path)
			parent_path.ApplyDefense()

// ============================================================
// Trace Nodes (Skill Tree)
// ============================================================

/datum/path/destruction/InitNodes()
	var/datum/path_node/N

	// --- Core Ability Upgrades (bottom row) ---
	N = new /datum/path_node("core_basic", "Farewell Hit", "Level up Basic ATK. Increases damage scaling.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_BASIC
	N.level_increase = 1
	N.ahn_cost = 500
	N.connections = list("bonus_a6")
	nodes += N

	N = new /datum/path_node("core_burst", "RIP Home Run", "Level up Skill. Increases damage scaling.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_BURST
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("bonus_a4")
	nodes += N

	N = new /datum/path_node("core_ultimate", "Stardust Ace", "Level up Ultimate. Increases damage scaling.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_ULTIMATE
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("core_passive", "bonus_a2")
	nodes += N

	N = new /datum/path_node("core_passive", "Perfect Pickoff", "Level up Passive. Increases ATK buff per stack.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_PASSIVE
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("core_basic", "core_burst", "atk1")
	nodes += N

	// --- Bottom stat (below Passive, no gate) ---
	N = new /datum/path_node("atk1", "ATK Boost", "ATK increases by 4%.")
	N.stat_bonuses = list("ATK" = 4)
	N.stat_percent = TRUE
	N.ahn_cost = 200
	N.tree_x = 2
	N.tree_y = 6
	nodes += N

	// --- Center branch (A2 gate, from Ultimate) ---
	N = new /datum/path_node("bonus_a2", "Ready for Battle", "On hit, regenerate 15 Energy. 60 second cooldown.")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 2
	N.tree_x = 2
	N.tree_y = 2
	N.connections = list("def1")
	nodes += N

	N = new /datum/path_node("def1", "DEF Boost", "DEF increases by 5%.")
	N.stat_bonuses = list("DEF" = 5)
	N.stat_percent = TRUE
	N.ahn_cost = 400
	N.required_ascension = 2
	N.tree_x = 2
	N.tree_y = 1
	N.connections = list("hp1", "atk2")
	N.prerequisites = list("bonus_a2")
	nodes += N

	N = new /datum/path_node("hp1", "HP Boost", "Max HP increases by 4%.")
	N.stat_bonuses = list("HP" = 4)
	N.stat_percent = TRUE
	N.ahn_cost = 300
	N.required_ascension = 3
	N.tree_x = 1
	N.tree_y = 0
	N.prerequisites = list("def1")
	nodes += N

	N = new /datum/path_node("atk2", "ATK Boost", "ATK increases by 4%.")
	N.stat_bonuses = list("ATK" = 4)
	N.stat_percent = TRUE
	N.ahn_cost = 300
	N.required_ascension = 3
	N.tree_x = 3
	N.tree_y = 0
	N.prerequisites = list("def1")
	nodes += N

	// --- Left branch (A6 gate, from Basic ATK) ---
	N = new /datum/path_node("bonus_a6", "Fighting Will", "Skill and Ult RIP Home Run deal 25% more DMG to the primary target.")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 6
	N.tree_x = 0
	N.tree_y = 3
	N.connections = list("atk3")
	nodes += N

	N = new /datum/path_node("atk3", "ATK Boost", "ATK increases by 6%.")
	N.stat_bonuses = list("ATK" = 6)
	N.stat_percent = TRUE
	N.ahn_cost = 500
	N.required_ascension = 6
	N.tree_x = 0
	N.tree_y = 2
	N.connections = list("def2")
	N.prerequisites = list("bonus_a6")
	nodes += N

	N = new /datum/path_node("def2", "DEF Boost", "DEF increases by 7.5%.")
	N.stat_bonuses = list("DEF" = 7.5)
	N.stat_percent = TRUE
	N.ahn_cost = 700
	N.required_ascension = 6
	N.tree_x = 0
	N.tree_y = 1
	N.connections = list("atk5")
	N.prerequisites = list("atk3")
	nodes += N

	N = new /datum/path_node("atk5", "ATK Boost", "ATK increases by 8%.")
	N.stat_bonuses = list("ATK" = 8)
	N.stat_percent = TRUE
	N.ahn_cost = 800
	N.required_level = 80
	N.tree_x = 0
	N.tree_y = 0
	N.prerequisites = list("def2")
	nodes += N

	// --- Right branch (A4 gate, from Skill) ---
	N = new /datum/path_node("bonus_a4", "Tenacity", "Each Perfect Pickoff stack also increases DEF by 10%.")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 4
	N.tree_x = 4
	N.tree_y = 3
	N.connections = list("hp2")
	nodes += N

	N = new /datum/path_node("hp2", "HP Boost", "Max HP increases by 6%.")
	N.stat_bonuses = list("HP" = 6)
	N.stat_percent = TRUE
	N.ahn_cost = 500
	N.required_ascension = 4
	N.tree_x = 4
	N.tree_y = 2
	N.connections = list("atk4")
	N.prerequisites = list("bonus_a4")
	nodes += N

	N = new /datum/path_node("atk4", "ATK Boost", "ATK increases by 6%.")
	N.stat_bonuses = list("ATK" = 6)
	N.stat_percent = TRUE
	N.ahn_cost = 600
	N.required_ascension = 5
	N.tree_x = 4
	N.tree_y = 1
	N.connections = list("hp3")
	N.prerequisites = list("hp2")
	nodes += N

	N = new /datum/path_node("hp3", "HP Boost", "Max HP increases by 8%.")
	N.stat_bonuses = list("HP" = 8)
	N.stat_percent = TRUE
	N.ahn_cost = 750
	N.required_level = 75
	N.tree_x = 4
	N.tree_y = 0
	N.prerequisites = list("atk4")
	nodes += N

// ============================================================
// Bonus Ability Effects
// ============================================================

/// Checks if a bonus ability node is unlocked
/datum/path/destruction/proc/HasBonus(node_id)
	return (node_id in unlocked_nodes)

/// Override GetStat to apply passive stack bonuses
/datum/path/destruction/GetStat(stat_name)
	var/base_val = ..()
	var/datum/path_ability/passive/destruction/pp = passive_effect
	if(!istype(pp) || pp.current_stacks <= 0)
		return base_val
	// Perfect Pickoff: each stack adds ATK%
	if(stat_name == "ATK")
		var/buff = pp.atk_buff_scaling[pp.level]
		base_val *= (1 + pp.current_stacks * buff / 100)
	// Tenacity (A4 bonus): each stack also adds 10% DEF
	if(stat_name == "DEF" && HasBonus("bonus_a4"))
		base_val *= (1 + pp.current_stacks * 0.10)
	return base_val

/datum/path/destruction/OnBonusAbilityUnlocked(node_id)
	switch(node_id)
		if("bonus_a2")
			// Ready for Battle: checked in OnWeaponHit override
			return
		if("bonus_a4")
			// Tenacity: effect is checked in Perfect Pickoff's
			// CheckKill proc — when stacking, also buffs DEF
			return
		if("bonus_a6")
			// Fighting Will: effect is checked in Skill's
			// Activate proc — adds 25% to primary target
			return

/// Override OnWeaponHit for bonus_a2 and passive kill check
/datum/path/destruction/OnWeaponHit(mob/living/target, mob/living/user)
	..()
	// Perfect Pickoff: check for kills from path damage
	var/datum/path_ability/passive/destruction/pp = passive_effect
	if(istype(pp))
		pp.OnPathHit(target)
	// Ready for Battle: 15 energy on hit, 60s cooldown
	if(HasBonus("bonus_a2") && world.time >= ready_for_battle_cd)
		if(isliving(target) && target.stat != DEAD)
			ready_for_battle_cd = world.time + 60 SECONDS
			GainEnergy(15)
			to_chat(owner, span_nicegreen("Ready for Battle! +15 Energy (60s cooldown)"))
			playsound(get_turf(owner), 'sound/machines/terminal_prompt_confirm.ogg', 30, TRUE)

