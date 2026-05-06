// ============================================================
// Path Datum — Core Path System & Ability Hierarchy
// ============================================================
// The main datum representing a player's chosen path with its
// resources, stats, abilities, turn system, and skill tree.
// ============================================================

/datum/path
	var/name = "Path"
	var/desc = ""
	var/icon_state = ""
	/// Icon state for the path screen action button
	var/path_screen_icon = "path_icon"
	/// Icon state for the ultimate action button
	var/path_ultimate_icon = "stardust_ace"
	var/mob/living/carbon/human/owner

	/// Elemental typing (set by subtypes)
	var/element_type = PATH_ELEMENT_PHYSICAL
	/// RES PEN % for this path's element (from buffs/abilities)
	var/res_pen = 0
	/// External ATK bonus % (from Harmony Benediction, etc.)
	var/external_atk_bonus = 0
	/// External DEF bonus % (from Preservation ally DR, etc.)
	var/external_def_bonus = 0
	/// External DMG multiplier (from Harmony Ultimate, etc.) — 1.0 = no bonus
	var/external_dmg_mult = 1

	// --- Resources ---
	var/energy = 0
	var/max_energy = PATH_MAX_ENERGY_DEFAULT
	var/action_points = 0
	var/max_action_points = PATH_MAX_AP_DEFAULT

	// --- Leveling & Ascension ---
	var/path_level = 1
	var/ascension_phase = 0
	var/path_exp = 0
	/// List of lists: each entry is list(phase, level, HP, ATK, DEF, SPD)
	var/list/stat_table = list()
	/// Max level per ascension phase
	var/list/level_caps = list(20, 30, 40, 50, 60, 70, 80)

	// --- Computed Path Stats ---
	var/list/path_stats = list()

	// --- Turn System ---
	var/turn_state = PATH_TURN_READY
	var/next_turn_time = 0
	var/swings_per_turn = 6
	/// Timer ID for the turn cycle
	var/turn_timer_id
	/// Grace period end time — attacks during this window don't grant AP
	var/turn_grace_end = 0
	/// Whether the next basic attack is the first hit of the turn
	var/first_hit_this_turn = TRUE
	/// Toughness reduction for the current attack (set before deal_path_damage)
	var/current_toughness_reduction = 0

	// --- Skill Tree (Traces) ---
	var/list/nodes = list()
	var/list/unlocked_nodes = list()

	// --- Ability Type References (set by subtypes) ---
	var/basic_attack_type = /datum/path_ability/basic
	var/burst_action_type = /datum/path_ability/burst
	var/ultimate_type = /datum/path_ability/ultimate
	var/passive_type = /datum/path_ability/passive

	// --- Instantiated Abilities ---
	var/datum/path_ability/basic/basic_attack
	var/datum/path_ability/burst/burst_action
	var/datum/path_ability/ultimate/ultimate_action
	var/datum/path_ability/passive/passive_effect

	// --- Defense ---
	/// How much damage_resistance we've added (for clean removal)
	var/applied_resistance = 0

	// --- Weapon ---
	var/obj/item/ego_weapon/path_weapon/weapon
	var/path_weapon_type = /obj/item/ego_weapon/path_weapon

	// --- Action Button References ---
	var/datum/action/path_ultimate/ultimate_action_button
	var/datum/action/path_screen/screen_action_button
	var/datum/action/cooldown/path_designate_ally/ally_action_button
	var/datum/action/path_recall_weapon/recall_action_button

/datum/path/New()
	InitNodes()

/// Virtual proc. Subtypes override to populate `nodes` list.
/datum/path/proc/InitNodes()
	return

// ============================================================
// Lifecycle
// ============================================================

/// Attaches the path to a mob
/datum/path/proc/AssignTo(mob/living/carbon/human/user)
	owner = user

	// Instantiate abilities
	basic_attack = new basic_attack_type()
	basic_attack.parent_path = src
	burst_action = new burst_action_type()
	burst_action.parent_path = src
	ultimate_action = new ultimate_type()
	ultimate_action.parent_path = src
	passive_effect = new passive_type()
	passive_effect.parent_path = src

	// Apply passive signals
	passive_effect.Apply(owner)

	// Create and equip path weapon
	weapon = new path_weapon_type()
	weapon.linked_path = src
	owner.put_in_hands(weapon)

	// Create and grant action buttons
	ultimate_action_button = new()
	ultimate_action_button.linked_path = src
	ultimate_action_button.button_icon_state = path_ultimate_icon
	ultimate_action_button.Grant(owner)

	screen_action_button = new()
	screen_action_button.linked_path = src
	screen_action_button.button_icon_state = path_screen_icon
	screen_action_button.Grant(owner)

	ally_action_button = new()
	ally_action_button.linked_path = src
	ally_action_button.Grant(owner)

	recall_action_button = new()
	recall_action_button.linked_path = src
	recall_action_button.Grant(owner)

	// Mark as path holder — armor gives no protection, but can be worn cosmetically
	ADD_TRAIT(owner, TRAIT_NO_EGO_ARMOR, "path")

	// Auto-level from LC13 attributes
	CalculateLevelFromStats()

	// Calculate initial stats
	RecalculateStats()
	RecalcSwingsPerTurn()

	// Apply DEF as damage resistance
	ApplyDefense()

	// Update HP from path stats
	owner.updatehealth()

	// Pathstrider traits
	ADD_TRAIT(owner, TRAIT_SANITYIMMUNE, "Path")
	ADD_TRAIT(owner, TRAIT_BRUTEPALE, "Path")
	ADD_TRAIT(owner, TRAIT_BRUTESANITY, "Path")

	// Start turn cycle
	StartTurnCycle()

	// Signal
	SEND_SIGNAL(owner, COMSIG_MOB_PATH_ASSIGNED, src)

/// Detaches the path from its mob
/datum/path/proc/Remove()
	if(!owner)
		return

	// Remove EGO armor restriction
	REMOVE_TRAIT(owner, TRAIT_NO_EGO_ARMOR, "path")

	// Remove pathstrider traits
	REMOVE_TRAIT(owner, TRAIT_SANITYIMMUNE, "Path")
	REMOVE_TRAIT(owner, TRAIT_BRUTEPALE, "Path")
	REMOVE_TRAIT(owner, TRAIT_BRUTESANITY, "Path")

	// Restore original damage resistance
	RemoveDefense()

	// Unapply passive
	if(passive_effect)
		passive_effect.Unapply(owner)

	// Remove action buttons
	if(ultimate_action_button)
		ultimate_action_button.Remove(owner)
		QDEL_NULL(ultimate_action_button)
	if(screen_action_button)
		screen_action_button.Remove(owner)
		QDEL_NULL(screen_action_button)
	if(ally_action_button)
		ally_action_button.Remove(owner)
		QDEL_NULL(ally_action_button)
	if(recall_action_button)
		recall_action_button.Remove(owner)
		QDEL_NULL(recall_action_button)

	// Remove weapon
	if(weapon)
		weapon.linked_path = null
		QDEL_NULL(weapon)

	// Stop turn cycle
	if(turn_timer_id)
		deltimer(turn_timer_id)
		turn_timer_id = null

	// Clear allies
	ClearAllyList(owner)

	// Signal
	SEND_SIGNAL(owner, COMSIG_MOB_PATH_REMOVED, src)

	// Restore Fortitude-based HP
	owner.updatehealth()

	// Delete abilities
	QDEL_NULL(basic_attack)
	QDEL_NULL(burst_action)
	QDEL_NULL(ultimate_action)
	QDEL_NULL(passive_effect)

	owner = null

// ============================================================
// Turn System
// ============================================================

/// Returns the current turn duration in deciseconds
/datum/path/proc/GetTurnDuration()
	var/spd = GetStat("SPD")
	if(spd <= 0)
		spd = PATH_BASE_SPEED
	return PATH_TURN_BASE * PATH_BASE_SPEED / spd

/// Starts the recurring turn cycle timer
/datum/path/proc/StartTurnCycle()
	turn_state = PATH_TURN_READY
	first_hit_this_turn = TRUE
	if(weapon)
		weapon.ShowTurnReady()
	var/duration = GetTurnDuration()
	next_turn_time = world.time + duration
	turn_timer_id = addtimer(CALLBACK(src, PROC_REF(OnTurnReset)), duration, TIMER_STOPPABLE)

/// Called each turn cycle. Ticks DoTs, resets state, queues next turn.
/datum/path/proc/OnTurnReset()
	if(!owner || QDELETED(owner))
		return

	// Tick all active DoTs on this path holder
	for(var/datum/status_effect/path_dot/dot in owner.status_effects)
		dot.DoTick()

	// Reset turn state with 1.5s grace period for skill use
	turn_state = PATH_TURN_READY
	turn_grace_end = world.time + 0.75 SECONDS
	first_hit_this_turn = TRUE

	// Golden glow on weapon to show turn is ready
	if(weapon)
		weapon.ShowTurnReady()

	// Queue next turn
	var/duration = GetTurnDuration()
	next_turn_time = world.time + duration
	turn_timer_id = addtimer(CALLBACK(src, PROC_REF(OnTurnReset)), duration, TIMER_STOPPABLE)

/// Recalculates how many weapon swings fit in one turn
/datum/path/proc/RecalcSwingsPerTurn()
	if(!weapon)
		swings_per_turn = 6
		return
	var/turn_dur = GetTurnDuration()
	var/swing_interval = CLICK_CD_MELEE * weapon.attack_speed
	if(swing_interval <= 0)
		swing_interval = CLICK_CD_MELEE
	swings_per_turn = max(round(turn_dur / swing_interval), 1)

// ============================================================
// Resource Management
// ============================================================

/// Adds energy, clamped to max_energy
/datum/path/proc/GainEnergy(amount)
	energy = min(energy + amount, max_energy)
	SEND_SIGNAL(src, COMSIG_PATH_ENERGY_CHANGED, energy, max_energy)
	if(ultimate_action_button)
		ultimate_action_button.UpdateButtonIcon()

/// Subtracts energy, clamped to 0
/datum/path/proc/SpendEnergy(amount)
	energy = max(energy - amount, 0)
	SEND_SIGNAL(src, COMSIG_PATH_ENERGY_CHANGED, energy, max_energy)
	if(ultimate_action_button)
		ultimate_action_button.UpdateButtonIcon()

/// +1 AP, clamped to max. If propagate is TRUE and the owner has mutual
/// path-allies, they each gain 1 AP too (the recursive call passes
/// propagate=FALSE to prevent loops).
/datum/path/proc/GainActionPoint(propagate = TRUE)
	action_points = min(action_points + 1, max_action_points)
	SEND_SIGNAL(src, COMSIG_PATH_AP_CHANGED, action_points, max_action_points)
	if(propagate && owner)
		for(var/datum/path/ally_path as anything in GetMutualPathAllies(owner))
			ally_path.GainActionPoint(propagate = FALSE)

/// -1 AP, clamped to 0. Mutual path-allies also lose 1 AP when propagate
/// is TRUE.
/datum/path/proc/SpendActionPoint(propagate = TRUE)
	action_points = max(action_points - 1, 0)
	SEND_SIGNAL(src, COMSIG_PATH_AP_CHANGED, action_points, max_action_points)
	if(propagate && owner)
		for(var/datum/path/ally_path as anything in GetMutualPathAllies(owner))
			ally_path.SpendActionPoint(propagate = FALSE)

// ============================================================
// Stats
// ============================================================

/// Returns the computed stat value (base + node bonuses)
/datum/path/proc/GetStat(stat_name)
	var/base_val = 0
	if(path_stats[stat_name])
		base_val = path_stats[stat_name]

	// Add flat bonuses from unlocked nodes
	var/flat_bonus = 0
	var/percent_bonus = 0
	for(var/datum/path_node/node in nodes)
		if(!(node.id in unlocked_nodes))
			continue
		if(node.node_type != PATH_NODE_STAT)
			continue
		if(!node.stat_bonuses[stat_name])
			continue
		if(node.stat_percent)
			percent_bonus += node.stat_bonuses[stat_name]
		else
			flat_bonus += node.stat_bonuses[stat_name]

	var/result = base_val * (1 + percent_bonus / 100) + flat_bonus

	// External buffs (from Harmony Benediction, Preservation DR, etc.)
	if(stat_name == "ATK" && external_atk_bonus != 0)
		result *= (1 + external_atk_bonus / 100)
	if(stat_name == "DEF" && external_def_bonus != 0)
		result *= (1 + external_def_bonus / 100)

	return result

/// Recalculates path_stats from stat_table based on level/phase
/datum/path/proc/RecalculateStats()
	// Find the floor and ceiling entries for current level
	var/list/floor_entry
	var/list/ceil_entry
	for(var/list/entry in stat_table)
		if(entry[1] <= ascension_phase && entry[2] <= path_level)
			floor_entry = entry
		if(!ceil_entry && entry[1] >= ascension_phase && entry[2] >= path_level)
			ceil_entry = entry

	if(!floor_entry)
		return
	if(!ceil_entry)
		ceil_entry = floor_entry

	// Interpolate between floor and ceiling
	var/level_range = ceil_entry[2] - floor_entry[2]
	var/t = 0
	if(level_range > 0)
		t = (path_level - floor_entry[2]) / level_range

	path_stats["HP"] = round(floor_entry[3] + (ceil_entry[3] - floor_entry[3]) * t)
	path_stats["ATK"] = round(floor_entry[4] + (ceil_entry[4] - floor_entry[4]) * t)
	path_stats["DEF"] = round(floor_entry[5] + (ceil_entry[5] - floor_entry[5]) * t)
	if(length(floor_entry) >= 6 && length(ceil_entry) >= 6)
		path_stats["SPD"] = round(floor_entry[6] + (ceil_entry[6] - floor_entry[6]) * t)
	else
		path_stats["SPD"] = PATH_BASE_SPEED

	// Base CRIT stats (all paths)
	path_stats["CRIT Rate"] = 5
	path_stats["CRIT DMG"] = 50

	// Refresh defense and HP on the owner if assigned
	if(owner)
		ApplyDefense()
		owner.updatehealth()

// ============================================================
// Defense System
// ============================================================

/// Applies DEF stat as damage_resistance on the owner
/// Formula: reduction% = DEF / (DEF + 800) * 100
/// Uses multiplicative stacking — divides out old factor, multiplies new
/datum/path/proc/ApplyDefense()
	if(!owner?.physiology)
		return
	// Remove previous multiplier (divide it out)
	if(applied_resistance > 0)
		var/old_keep = (100 - applied_resistance) / 100
		if(old_keep > 0)
			owner.physiology.damage_resistance = 100 - ((100 - owner.physiology.damage_resistance) / old_keep)
	// Calculate new reduction
	var/def = GetStat("DEF")
	applied_resistance = (def / (def + 800)) * 100
	// Apply new multiplier
	var/new_keep = (100 - applied_resistance) / 100
	owner.physiology.damage_resistance = 100 - ((100 - owner.physiology.damage_resistance) * new_keep)

/// Removes the path's damage_resistance contribution
/datum/path/proc/RemoveDefense()
	if(!owner?.physiology)
		return
	if(applied_resistance > 0)
		var/old_keep = (100 - applied_resistance) / 100
		if(old_keep > 0)
			owner.physiology.damage_resistance = 100 - ((100 - owner.physiology.damage_resistance) / old_keep)
	applied_resistance = 0

// ============================================================
// Leveling & Ascension
// ============================================================

/// Sets the path level and recalculates stats
/datum/path/proc/SetLevel(new_level)
	path_level = clamp(new_level, 1, 80)
	RecalculateStats()
	RecalcSwingsPerTurn()

/// Increases ascension phase, raising the level cap
/datum/path/proc/Ascend()
	if(ascension_phase >= 6)
		return FALSE
	ascension_phase++
	return TRUE

/// EXP required to reach each level (index = level, value = total EXP at that level)
/datum/path/proc/GetExpTable()
	return list(0, 200, 500, 1000, 1600, 2650, 4320, 6640, 9700, 13560, 18300, 24010, 30740, 38570, 47570, 57810, 69360, 82280, 96640, 112510, 129090, 145930, 163030, 180400, 198040, 215950, 234140, 252620, 271380, 290420, 309760, 329390, 349320, 369540, 390070, 410910, 432050, 453500, 475260, 497340, 519730, 545280, 574420, 607250, 643850, 684320, 728750, 777230, 829860, 886730, 947920, 1013540, 1083670, 1158410, 1237860, 1322100, 1411220, 1505330, 1604520, 1708870, 1815110, 1926940, 2044470, 2167790, 2297000, 2432200, 2573490, 2720970, 2874750, 3034010, 3214180, 3414100, 3635020, 3877280, 4141210, 4427160, 4735460, 5066460, 5420500, 5797920)

/// Returns EXP needed for the next level (0 if at max)
/datum/path/proc/GetExpToNext()
	var/list/table = GetExpTable()
	if(path_level >= 80)
		return 0
	return table[path_level + 1] - table[path_level]

/// Returns total EXP at current level start
/datum/path/proc/GetExpAtLevel()
	var/list/table = GetExpTable()
	return table[path_level]

/// Grants EXP and handles leveling up.
/// Stops at ascension cap — use an Ascension Crystal to break through.
/datum/path/proc/GainExp(amount)
	if(path_level >= 80)
		return
	// Find the level cap for current ascension
	var/cap = 80
	if(ascension_phase < length(level_caps))
		cap = level_caps[ascension_phase + 1]
	// If already at cap, EXP is wasted — warn player
	if(path_level >= cap)
		if(owner)
			to_chat(owner, span_warning("You are at the level cap ([cap]) for ascension [ascension_phase]. Use an Ascension Crystal to continue!"))
		return
	path_exp += amount
	var/list/table = GetExpTable()
	var/leveled = FALSE
	while(path_level < 80 && path_level < cap)
		var/needed = table[path_level + 1]
		if(path_exp < needed)
			break
		path_level = min(path_level + 1, 80)
		leveled = TRUE
	// Cap EXP at the next level threshold to prevent waste
	if(path_level >= cap && path_level < 80)
		var/cap_exp = table[cap]
		if(path_exp > cap_exp)
			path_exp = cap_exp
		if(owner)
			to_chat(owner, span_warning("Reached level cap [cap]! Use an Ascension Crystal to ascend."))
	if(leveled)
		RecalculateStats()
		RecalcSwingsPerTurn()
		if(owner)
			to_chat(owner, span_nicegreen("Path level up! Now level [path_level]."))

/// Auto-levels the path based on the owner's LC13 attribute average.
/// 0 avg = level 1 A0, 120 avg = level 80 A6.
/datum/path/proc/CalculateLevelFromStats()
	if(!owner)
		return
	var/fort = get_attribute_level(owner, FORTITUDE_ATTRIBUTE)
	var/prud = get_attribute_level(owner, PRUDENCE_ATTRIBUTE)
	var/temp = get_attribute_level(owner, TEMPERANCE_ATTRIBUTE)
	var/just = get_attribute_level(owner, JUSTICE_ATTRIBUTE)
	var/avg = (fort + prud + temp + just) / 4

	// Map 0-120 avg to level 1-80
	var/calc_level = clamp(round(1 + (avg / 120) * 79), 1, 80)

	// Determine ascension phase from level
	ascension_phase = 0
	for(var/i in 1 to length(level_caps))
		if(calc_level >= level_caps[i])
			ascension_phase = i
		else
			break

	path_level = calc_level
	// Set EXP to match the calculated level
	var/list/table = GetExpTable()
	path_exp = table[path_level]

// ============================================================
// Skill Tree (Traces)
// ============================================================

/// Attempts to unlock a trace node by spending ahn
/datum/path/proc/UnlockNode(node_id)
	// Find node
	var/datum/path_node/target_node
	for(var/datum/path_node/node in nodes)
		if(node.id == node_id)
			target_node = node
			break
	if(!target_node)
		return FALSE

	// Check can unlock
	if(!target_node.CanUnlock(unlocked_nodes, ascension_phase, path_level))
		return FALSE

	// Check ahn cost via bank account
	if(!owner)
		return FALSE
	var/obj/item/card/id/C = owner.get_idcard(TRUE)
	if(!C || !C.registered_account)
		to_chat(owner, span_warning("No bank account found!"))
		return FALSE
	if(!C.registered_account.has_money(target_node.ahn_cost))
		to_chat(owner, span_warning("Not enough ahn! Need [target_node.ahn_cost]."))
		return FALSE

	// Deduct ahn
	C.registered_account.adjust_money(-target_node.ahn_cost)

	// Apply node effect
	switch(target_node.node_type)
		if(PATH_NODE_STAT)
			// Stat bonuses are applied dynamically via GetStat()
			unlocked_nodes += target_node.id
		if(PATH_NODE_ABILITY)
			// Level up the target ability (repeatable, don't add to unlocked)
			var/datum/path_ability/ability
			switch(target_node.ability_target)
				if(PATH_ABILITY_BASIC)
					ability = basic_attack
				if(PATH_ABILITY_BURST)
					ability = burst_action
				if(PATH_ABILITY_ULTIMATE)
					ability = ultimate_action
				if(PATH_ABILITY_PASSIVE)
					ability = passive_effect
			if(ability)
				if(ability.level >= ability.max_level)
					to_chat(owner, span_warning("[ability.name] is already at max level!"))
					C.registered_account.adjust_money(target_node.ahn_cost)
					return FALSE
				ability.level = min(ability.level + target_node.level_increase, ability.max_level)
		if(PATH_NODE_PASSIVE)
			// Bonus ability unlocked — subtypes handle specific logic
			unlocked_nodes += target_node.id
			OnBonusAbilityUnlocked(target_node.id)

	to_chat(owner, span_nicegreen("Unlocked trace: [target_node.name]!"))
	playsound(get_turf(owner), 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
	return TRUE

/// Virtual proc. Subtypes override to handle specific bonus ability effects.
/datum/path/proc/OnBonusAbilityUnlocked(node_id)
	return

// ============================================================
// Combat — Weapon Hit Handler
// ============================================================

/// Called by the path weapon's attack() proc. Deals per-swing damage
/// and gates AP/energy gain by turn state.
/datum/path/proc/OnWeaponHit(mob/living/target, mob/living/user)
	if(!isliving(target))
		return
	if(!basic_attack)
		return
	// Don't interact with dead targets
	if(target.stat == DEAD)
		return

	// During grace period, attacks deal reduced damage (10%)
	// and don't grant AP/energy — preserving the skill window
	var/is_grace = (turn_state == PATH_TURN_READY && world.time < turn_grace_end)
	var/hit_is_first = first_hit_this_turn && !is_grace

	// Set toughness reduction: 10 for first hit basic attacks
	current_toughness_reduction = hit_is_first ? 10 : 0

	// Deal path damage via basic attack
	basic_attack.OnHit(target, user, hit_is_first)
	current_toughness_reduction = 0
	if(hit_is_first)
		first_hit_this_turn = FALSE

	// Only grant resources on first hit of an attack turn
	// Skip during grace period so players can use skills
	if(turn_state == PATH_TURN_READY)
		if(is_grace)
			return // Grace period — no AP/energy
		GainEnergy(basic_attack.energy_gain)
		GainActionPoint()
		turn_state = PATH_TURN_ATTACKED
		// Clear golden glow — turn consumed by attack
		if(weapon)
			weapon.ClearTurnReady()

// ============================================================
// Combat — Path Damage
// ============================================================

/// PvP scaling multiplier for one ability call. Returns
/// scaling_table[actual_level] / scaling_table[target_level]:
///   below target  -> < 1 (default-trace players hit softer)
///   at target     -> = 1 (matches the original pvp_balance.md baseline)
///   above target  -> slightly > 1 (small reward for L11/L12)
/// Returns 1 (no effect) if the table is empty or the target scaling is 0.
/datum/path/proc/PvPScalingFactor(actual_level, list/scaling_table, target_level)
	if(!islist(scaling_table) || !length(scaling_table))
		return 1
	var/max_lv = length(scaling_table)
	target_level = clamp(target_level, 1, max_lv)
	actual_level = clamp(actual_level, 1, max_lv)
	var/target_s = scaling_table[target_level]
	if(target_s <= 0)
		return 1
	return scaling_table[actual_level] / target_s

/// Deals path damage to a target, applying the full damage pipeline.
/// Pass do_crit=FALSE to skip crit rolls (used by DoTs).
/// toughness_reduction: points of toughness to remove (10=basic, 20=skill, 30=ult, 0=none)
/// pvp_factor: per-ability multiplier applied only against non-path human targets.
/datum/path/proc/deal_path_damage(mob/living/target, amount, do_crit = TRUE, toughness_reduction = 0, pvp_factor = 1)
	if(!target || QDELETED(target))
		return 0
	var/damage = amount

	// External DMG multiplier (from Harmony Ultimate, etc.)
	if(external_dmg_mult != 1)
		damage *= external_dmg_mult

	// Elemental DMG bonus (e.g. "Wind DMG", "Fire DMG")
	var/elem_stat = "[element_type] DMG"
	var/elem_bonus = GetStat(elem_stat)
	if(elem_bonus)
		damage *= (1 + elem_bonus / 100)

	// CRIT check
	if(do_crit)
		var/crit_rate = GetStat("CRIT Rate")
		if(prob(crit_rate))
			var/crit_dmg = GetStat("CRIT DMG")
			damage *= (1 + crit_dmg / 100)

	// Level difference multiplier
	// Equal levels = 1.0x, clamped to 0.8x—1.2x range
	var/enemy_level = 20
	if(isanimal(target))
		var/mob/living/simple_animal/SA = target
		if(SA.maxHealth >= 8000)
			enemy_level = 80
		else if(SA.maxHealth >= 3000)
			enemy_level = 65
		else if(SA.maxHealth >= 2000)
			enemy_level = 50
		else if(SA.maxHealth >= 1000)
			enemy_level = 35
		else if(SA.maxHealth >= 400)
			enemy_level = 20
		else
			enemy_level = 10
	else if(ishuman(target))
		enemy_level = path_level // Mirror match = 1.0x
	var/level_diff = path_level - enemy_level
	// Scale by 0.5% per level difference, clamp to +/-20%
	var/def_mult = clamp(1 + (level_diff * 0.005), 0.8, 1.2)
	damage *= def_mult

	// Elemental RES Multiplier
	var/target_res = PATH_RES_DEFAULT / 100
	var/effective_res = clamp(target_res - (res_pen / 100), PATH_RES_MIN / 100, PATH_RES_MAX / 100)
	var/res_mult = 1 - effective_res
	damage *= res_mult

	// LC13 avg damage coefficient
	if(isanimal(target))
		var/mob/living/simple_animal/SA = target
		if(SA.damage_coeff)
			var/avg_coeff = (SA.damage_coeff.red + SA.damage_coeff.white + SA.damage_coeff.black + SA.damage_coeff.pale) / 4
			damage *= avg_coeff

	// PvP balance: HP-ratio scaling + armor average vs humans
	if(ishuman(target) && owner)
		var/mob/living/carbon/human/H = target
		// Trace-progression PvP scaling — only against non-path humans.
		// Default-trace players land below baseline, target-trace players
		// match the original pvp_balance.md numbers, max-trace players
		// land slightly above.
		if(!H.HasPath() && pvp_factor != 1)
			damage *= pvp_factor
		// HP-ratio: path damage scales down vs lower-HP targets
		damage *= H.maxHealth / max(owner.maxHealth, 1)
		// Average armor reduction from any worn armor suit
		var/obj/item/clothing/suit/armor/suit = H.get_item_by_slot(ITEM_SLOT_OCLOTHING)
		if(istype(suit) && suit.armor)
			var/datum/armor/A = suit.armor
			var/avg_armor = (A.red + A.white + A.black + A.pale) / 4
			damage *= (100 - avg_armor) / 100

	// Apply damage
	// We already applied avg_coeff, so use forced=TRUE
	// to skip the mob's own coefficient application.
	// This also makes the debug dummy report damage.
	if(damage > 0)
		target.adjustBruteLoss(damage, forced = TRUE)
		// Spawn path damage visual
		new /obj/effect/temp_visual/path_damage(get_turf(target), element_type)
	return damage

// ============================================================
// Path Damage Visual Effect
// ============================================================

/obj/effect/temp_visual/path_damage
	icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'
	icon_state = "physical"
	layer = ABOVE_ALL_MOB_LAYER
	duration = 7 // 0.7 seconds
	randomdir = FALSE

/obj/effect/temp_visual/path_damage/Initialize(mapload, element)
	if(element)
		icon_state = element
	pixel_x = rand(-12, 12)
	pixel_y = rand(-6, 6)
	. = ..()
	// Drift up 7px and fade out over 0.7 seconds
	animate(src, pixel_y = pixel_y + 7, alpha = 0, time = 7)

// ============================================================
// SPD Debuff System (global procs)
// ============================================================

/// Applies a SPD change to a target based on their type
/proc/apply_path_spd_change(mob/living/target, spd_percent, duration)
	// Apply tracking status effect
	target.apply_status_effect(/datum/status_effect/path_spd_debuff)

	// Case 1: Path holder — modify their SPD stat (turn cycle)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		var/datum/component/path_holder/holder = H.GetComponent(/datum/component/path_holder)
		if(holder && holder.active_path)
			// TODO: implement temporary SPD stat modification on path
			return

	// Case 2: Simple mob — slow movement speed
	if(isanimal(target))
		var/mob/living/simple_animal/SA = target
		var/speed_penalty = -(spd_percent / 100) * max(initial(SA.speed), 1)
		SA.set_varspeed(SA.speed + speed_penalty)
		addtimer(CALLBACK(SA, TYPE_PROC_REF(/mob/living/simple_animal, set_varspeed), SA.speed - speed_penalty), duration)
		return

	// Case 3: Non-path carbon — slow movement speed
	if(iscarbon(target))
		target.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/path_spd_debuff, multiplicative_slowdown = -(spd_percent / 100))
		addtimer(CALLBACK(target, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/path_spd_debuff), duration)
		return

/// Checks if a target has an active path SPD debuff
/proc/has_path_spd_debuff(mob/living/target)
	return target.has_status_effect(/datum/status_effect/path_spd_debuff)

/// Simple tracking status effect for SPD debuffs
/datum/status_effect/path_spd_debuff
	id = "path_spd_debuff"
	duration = 20 SECONDS
	alert_type = null

/// Movespeed modifier for path SPD debuffs on non-path targets
/datum/movespeed_modifier/path_spd_debuff

// ============================================================
// Ability Datums
// ============================================================

/datum/path_ability
	var/name = "Ability"
	var/desc = ""
	var/icon_state = ""
	var/datum/path/parent_path
	var/level = 1
	var/max_level = 7

/datum/path_ability/Destroy()
	parent_path = null
	return ..()

/// Returns list of scaling info for TGUI display.
/// Subtypes override to provide ability-specific data.
/datum/path_ability/proc/GetScalingData()
	return list()

/// Returns the raw scaling list (e.g. atk_scaling) used for the PvP
/// scaling factor preview in the trace UI. Subtypes override; default null
/// means "no PvP-relevant scaling for this ability".
/datum/path_ability/proc/GetRawScaling()
	return null

// --- Basic Attack ---
/// Triggered when the path weapon hits a target
/datum/path_ability/basic
	/// Energy gained per hit (first hit of attack turn only)
	var/energy_gain = 20

/// Virtual proc. Subtypes deal damage, apply effects, etc.
/// swings_per_turn is used to divide total scaling across hits.
/datum/path_ability/basic/proc/OnHit(mob/living/target, mob/living/user, first_hit = TRUE)
	return

// --- Burst / Skill ---
/// Activated via path weapon's attack_self(). Costs AP, grants energy.
/datum/path_ability/burst
	/// Energy gained on use
	var/energy_gain = 30
	/// Action points consumed
	var/ap_cost = 1
	max_level = 12

/// Virtual proc. Subtypes override with unique per-path actions.
/datum/path_ability/burst/proc/Activate(mob/living/user)
	return

// --- Ultimate ---
/// Activated via HUD action button. Requires full energy.
/datum/path_ability/ultimate
	max_level = 12

/// Virtual proc. Base spends all energy, subtypes override for effects.
/datum/path_ability/ultimate/proc/Activate(mob/living/user)
	if(!parent_path)
		return
	parent_path.SpendEnergy(parent_path.energy)

// --- Passive ---
/// Registers signals for conditional triggers. Always-on effect.
/datum/path_ability/passive
	max_level = 12

/// Virtual proc. Subtypes register their signals on the user.
/datum/path_ability/passive/proc/Apply(mob/living/user)
	return

/// Virtual proc. Subtypes unregister their signals.
/datum/path_ability/passive/proc/Unapply(mob/living/user)
	return
