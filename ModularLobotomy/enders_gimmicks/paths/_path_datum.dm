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
	var/mob/living/carbon/human/owner

	/// Elemental typing (set by subtypes)
	var/element_type = PATH_ELEMENT_PHYSICAL
	/// RES PEN % for this path's element (from buffs/abilities)
	var/res_pen = 0

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

	// --- Weapon ---
	var/obj/item/ego_weapon/path_weapon/weapon
	var/path_weapon_type = /obj/item/ego_weapon/path_weapon

	// --- Action Button References ---
	var/datum/action/path_ultimate/ultimate_action_button
	var/datum/action/path_screen/screen_action_button
	var/datum/action/cooldown/path_designate_ally/ally_action_button

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
	ultimate_action_button.Grant(owner)

	screen_action_button = new()
	screen_action_button.linked_path = src
	screen_action_button.Grant(owner)

	ally_action_button = new()
	ally_action_button.linked_path = src
	ally_action_button.Grant(owner)

	// Calculate initial stats
	RecalculateStats()
	RecalcSwingsPerTurn()

	// Start turn cycle
	StartTurnCycle()

	// Signal
	SEND_SIGNAL(owner, COMSIG_MOB_PATH_ASSIGNED, src)

/// Detaches the path from its mob
/datum/path/proc/Remove()
	if(!owner)
		return

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

	// Reset turn state
	turn_state = PATH_TURN_READY

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

/// +1 AP, clamped to max
/datum/path/proc/GainActionPoint()
	action_points = min(action_points + 1, max_action_points)
	SEND_SIGNAL(src, COMSIG_PATH_AP_CHANGED, action_points, max_action_points)

/// -1 AP, clamped to 0
/datum/path/proc/SpendActionPoint()
	action_points = max(action_points - 1, 0)
	SEND_SIGNAL(src, COMSIG_PATH_AP_CHANGED, action_points, max_action_points)

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

	return base_val * (1 + percent_bonus / 100) + flat_bonus

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

	// Always deal damage (scaled per-swing)
	basic_attack.OnHit(target, user, swings_per_turn)

	// Only grant resources on first hit of an attack turn
	if(turn_state == PATH_TURN_READY)
		GainEnergy(basic_attack.energy_gain)
		GainActionPoint()
		turn_state = PATH_TURN_ATTACKED

// ============================================================
// Combat — Path Damage
// ============================================================

/// Deals path damage to a target, applying the full damage pipeline.
/// Pass do_crit=FALSE to skip crit rolls (used by DoTs).
/datum/path/proc/deal_path_damage(mob/living/target, amount, do_crit = TRUE)
	if(!target || QDELETED(target))
		return 0
	var/damage = amount

	// CRIT check
	if(do_crit)
		var/crit_rate = GetStat("CRIT Rate")
		if(prob(crit_rate))
			var/crit_dmg = GetStat("CRIT DMG")
			damage *= (1 + crit_dmg / 100)

	// DEF Multiplier (level-based)
	// Formula: attacker_factor / (attacker_factor + enemy_factor)
	// At equal levels this gives 0.5x, scaling smoothly
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
		enemy_level = path_level // Mirror match = 0.5x
	var/def_mult = (path_level + 20) / ((enemy_level + 20) + (path_level + 20))
	damage *= def_mult

	// Elemental RES Multiplier
	// TODO: check target's element_res when implemented
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

	// Apply damage
	// We already applied avg_coeff, so use forced=TRUE
	// to skip the mob's own coefficient application.
	// This also makes the debug dummy report damage.
	if(damage > 0)
		target.adjustBruteLoss(damage, forced = TRUE)
	return damage

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

// --- Basic Attack ---
/// Triggered when the path weapon hits a target
/datum/path_ability/basic
	/// Energy gained per hit (first hit of attack turn only)
	var/energy_gain = 20

/// Virtual proc. Subtypes deal damage, apply effects, etc.
/// swings_per_turn is used to divide total scaling across hits.
/datum/path_ability/basic/proc/OnHit(mob/living/target, mob/living/user, swings_per_turn = 1)
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
