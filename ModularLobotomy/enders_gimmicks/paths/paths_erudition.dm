// ============================================================
// Path of Erudition (Aeon: Nous)
// ============================================================
// AoE specialist / Execute finisher. Ice element.
// Area damage on every ability, execute mechanic on low-HP,
// triggered bonus hit on HP threshold, self-ATK buff from Ult.
// ============================================================

/datum/path/erudition
	name = "Erudition"
	desc = "Deals remarkable amounts of multi-target damage. The main damage dealer against groups of enemies."
	icon_state = "destruction"
	path_screen_icon = "erudition_path"
	path_ultimate_icon = "it's_magic"
	element_type = PATH_ELEMENT_ICE
	max_energy = 110
	path_weapon_type = /obj/item/ego_weapon/path_weapon/erudition
	basic_attack_type = /datum/path_ability/basic/erudition
	burst_action_type = /datum/path_ability/burst/erudition
	ultimate_type = /datum/path_ability/ultimate/erudition
	passive_type = /datum/path_ability/passive/erudition

	/// Whether the ATK buff from Ultimate is active
	var/ult_atk_buff = FALSE
	/// Timer ID for the ATK buff expiry
	var/ult_buff_timer

	// Stat table: list(phase, level, HP, ATK, DEF, SPD)
	stat_table = list(
		list(0, 1,   129, 79,  54,  100),
		list(0, 20,  252, 154, 105, 100),
		list(1, 20,  304, 186, 126, 100),
		list(1, 30,  369, 225, 153, 100),
		list(2, 30,  421, 257, 175, 100),
		list(2, 40,  486, 297, 202, 100),
		list(3, 40,  537, 328, 224, 100),
		list(3, 50,  602, 368, 251, 100),
		list(4, 50,  654, 399, 272, 100),
		list(4, 60,  719, 439, 299, 100),
		list(5, 60,  771, 471, 321, 100),
		list(5, 70,  835, 510, 348, 100),
		list(6, 70,  887, 542, 369, 100),
		list(6, 80,  952, 582, 396, 100)
	)

// ============================================================
// Erudition Weapon
// ============================================================

/obj/item/ego_weapon/path_weapon/erudition
	name = "Erudition Staff"
	desc = "A weapon crystallized from cold logic."
	hitsound = 'sound/weapons/bladeslice.ogg'
	swingstyle = WEAPONSWING_SMALLSWEEP

// ============================================================
// Basic ATK: What Are You Looking At?
// ============================================================
// Melee Hit | Energy Generation: 20 | Ice
// 50%-110% ATK. If target HP <= 50%, +40% ATK bonus.
// ============================================================

/datum/path_ability/basic/erudition
	name = "What Are You Looking At?"
	desc = "Deals Ice DMG. +40% ATK bonus vs targets at or below 50% HP."
	icon_state = "looking_at"
	energy_gain = 20
	max_level = 7
	var/list/atk_scaling = list(50, 60, 70, 80, 90, 100, 110)
	/// Execute bonus (flat 40% ATK at all levels)
	var/execute_bonus = 40

/datum/path_ability/basic/erudition/GetScalingData()
	var/list/data = list()
	data["ATK Scaling"] = "[atk_scaling[level]]%"
	if(parent_path)
		var/atk = parent_path.GetStat("ATK")
		var/dmg = round(atk * atk_scaling[level] / 100, 1)
		var/exec_dmg = round(atk * (atk_scaling[level] + execute_bonus) / 100, 1)
		data["Damage"] = "[dmg]"
		data["vs <=50% HP"] = "[exec_dmg]"
	data["Energy Gain"] = "[energy_gain]"
	return data

/datum/path_ability/basic/erudition/OnHit(mob/living/target, mob/living/user, first_hit = TRUE)
	if(!parent_path)
		return
	var/multiplier = atk_scaling[level] / 100
	var/total_damage = parent_path.GetStat("ATK") * multiplier
	if(!first_hit)
		total_damage *= 0.1

	// Deal base damage first
	parent_path.deal_path_damage(target, total_damage)

	// Execute check: if target is now at or below 50% HP
	if(!QDELETED(target) && target.stat != DEAD)
		if(target.health <= target.maxHealth * 0.5)
			var/exec_dmg = parent_path.GetStat("ATK") * (execute_bonus / 100)
			if(!first_hit)
				exec_dmg *= 0.1
			parent_path.deal_path_damage(target, exec_dmg)

// ============================================================
// Skill: One-Time Offer
// ============================================================
// 3-tile AoE | Energy Generation: 30 | Ice
// 50%-110% ATK to all within 3 tiles.
// +25% DMG to targets above 50% HP.
// ============================================================

/datum/path_ability/burst/erudition
	name = "One-Time Offer"
	desc = "Deals Ice DMG to all enemies within 3 tiles. +25% vs targets above 50% HP."
	icon_state = "one_time_offer"
	energy_gain = 30
	ap_cost = 1
	max_level = 12
	var/list/atk_scaling = list(50, 55, 60, 65, 70, 75, 81.25, 87.5, 93.75, 100, 105, 110)

/datum/path_ability/burst/erudition/GetScalingData()
	var/list/data = list()
	data["ATK Scaling"] = "[atk_scaling[level]]%"
	if(parent_path)
		var/atk = parent_path.GetStat("ATK")
		var/dmg = round(atk * atk_scaling[level] / 100, 1)
		var/bonus_dmg = round(dmg * 1.25, 1)
		data["Damage (per target)"] = "[dmg]"
		data["vs >=50% HP"] = "[bonus_dmg]"

		// Efficiency bonus
		var/datum/path/erudition/E = parent_path
		if(istype(E) && E.HasBonus("bonus_a2"))
			data["Efficiency"] = "+25% extra"
	data["Energy Gain"] = "[energy_gain]"
	data["AP Cost"] = "[ap_cost]"
	return data

/datum/path_ability/burst/erudition/Activate(mob/living/user)
	if(!parent_path)
		return

	var/atk = parent_path.GetStat("ATK")
	var/multiplier = atk_scaling[level] / 100

	// Efficiency (A2 bonus): +25% extra DMG boost
	var/efficiency_bonus = 0
	var/datum/path/erudition/E = parent_path
	if(istype(E) && E.HasBonus("bonus_a2"))
		efficiency_bonus = 0.25

	var/hit_count = 0
	for(var/mob/living/L in range(3, user))
		if(L == user)
			continue
		if(L.stat == DEAD)
			continue
		if(IsPathAlly(user, L))
			continue
		var/dmg = atk * multiplier
		// +25% DMG to targets above 50% HP
		if(L.health > L.maxHealth * 0.5)
			dmg *= (1.25 + efficiency_bonus)
		parent_path.deal_path_damage(L, dmg)
		hit_count++

	// VFX: ice effects on tiles in range
	for(var/turf/aoe_turf in range(3, user))
		if(prob(40))
			new /obj/effect/temp_visual/ice_spikes(aoe_turf)
		if(prob(20))
			new /obj/effect/temp_visual/small_smoke/halfsecond(aoe_turf)
	playsound(get_turf(user), 'sound/weapons/smash.ogg', 50, TRUE)
	for(var/mob/living/M in view(7, user))
		if(M.client)
			shake_camera(M, 3, 2)
	if(hit_count > 0)
		user.visible_message(span_danger("[user] casts One-Time Offer, hitting [hit_count] target\s!"))
	else
		user.visible_message(span_danger("[user] casts One-Time Offer, but hits nothing!"))

// ============================================================
// Ultimate: It's Magic, I Added Some Magic
// ============================================================
// 5-tile AoE | Energy Cost: 110 | Energy Gen: 5 | Ice
// 120%-216% ATK. Grants 25% ATK buff for 10s after.
// ============================================================

/datum/path_ability/ultimate/erudition
	name = "It's Magic, I Added Some Magic"
	desc = "Deals Ice DMG to all enemies within 5 tiles. Grants 25% ATK buff for 10s."
	icon_state = "it's_magic"
	max_level = 12
	var/list/atk_scaling = list(120, 128, 136, 144, 152, 160, 170, 180, 190, 200, 208, 216)

/datum/path_ability/ultimate/erudition/GetScalingData()
	var/list/data = list()
	if(parent_path)
		var/atk = parent_path.GetStat("ATK")
		var/dmg = round(atk * atk_scaling[level] / 100, 1)
		data["AoE Damage"] = "[atk_scaling[level]]% ([dmg] dmg)"

		// Icing bonus
		var/datum/path/erudition/E = parent_path
		if(istype(E) && E.HasBonus("bonus_a6"))
			var/icing_dmg = round(dmg * 1.2, 1)
			data["vs <=50% HP"] = "[icing_dmg] dmg"
		data["ATK Buff"] = "25% for 10s"
		data["Energy Cost"] = "[parent_path.max_energy]"
		data["Energy Gen"] = "5"
	return data

/datum/path_ability/ultimate/erudition/Activate(mob/living/user)
	if(!parent_path)
		return
	// Spend energy
	..()

	// Phase 1: Leap into the air
	var/turf/start_turf = get_turf(user)
	// Shadow marker on the ground
	new /obj/effect/temp_visual/erudition_shadow(start_turf)
	// Immobilize + shift user up into the air
	ADD_TRAIT(user, TRAIT_IMMOBILIZED, "erudition_ult")
	animate(user, pixel_y = user.pixel_y + 80, alpha = 160, time = 3)
	user.visible_message(span_danger("[user] leaps into the air!"))
	playsound(start_turf, 'sound/abnormalities/babayaga/charge.ogg', 70, TRUE, 5)

	// Phase 2: After 0.3s, ice spike falls (user stays in air)
	var/datum/path/path_ref = parent_path
	addtimer(CALLBACK(src, PROC_REF(UltIceSpike), user, start_turf, path_ref), 3)

/// Phase 2: Ice spike appears and falls — user stays airborne
/datum/path_ability/ultimate/erudition/proc/UltIceSpike(mob/living/user, turf/start_turf, datum/path/path_ref)
	if(QDELETED(user))
		REMOVE_TRAIT(user, TRAIT_IMMOBILIZED, "erudition_ult")
		return
	// Ice spike slams into the ground
	new /obj/effect/temp_visual/ice_spikes(start_turf)
	playsound(start_turf, 'sound/effects/podwoosh.ogg', 60, TRUE)

	// Phase 3: After 0.5s, AoE triggers + user lands
	addtimer(CALLBACK(src, PROC_REF(UltSlam), user, start_turf, path_ref), 5)

/// Phase 3: AoE damage triggers, user lands
/datum/path_ability/ultimate/erudition/proc/UltSlam(mob/living/user, turf/start_turf, datum/path/path_ref)
	if(QDELETED(user))
		return

	// Land user back down
	user.forceMove(start_turf)
	animate(user, pixel_y = initial(user.pixel_y), alpha = 255, time = 3)

	var/atk = path_ref.GetStat("ATK")
	var/multiplier = atk_scaling[level] / 100

	// Icing (A6 bonus): +20% DMG to enemies below 50% HP
	var/datum/path/erudition/E = path_ref
	var/has_icing = istype(E) && E.HasBonus("bonus_a6")

	var/hit_count = 0
	for(var/mob/living/L in range(5, user))
		if(L == user)
			continue
		if(L.stat == DEAD)
			continue
		if(IsPathAlly(user, L))
			continue
		var/dmg = atk * multiplier
		if(has_icing && L.health <= L.maxHealth * 0.5)
			dmg *= 1.2
		path_ref.deal_path_damage(L, dmg)
		hit_count++

	// Grant 5 energy
	path_ref.GainEnergy(5)

	// Apply 25% ATK buff for 10 seconds
	if(istype(E))
		E.ult_atk_buff = TRUE
		if(E.ult_buff_timer)
			deltimer(E.ult_buff_timer)
		E.ult_buff_timer = addtimer(CALLBACK(E, TYPE_PROC_REF(/datum/path/erudition, ExpireUltBuff)), 10 SECONDS, TIMER_STOPPABLE)
		to_chat(user, span_nicegreen("ATK +25% for 10 seconds!"))

	// VFX: flashy ice/snow covering the AoE
	for(var/turf/aoe_turf in range(5, user))
		new /obj/effect/temp_visual/ice_turf/no_slip(aoe_turf)
		if(prob(25))
			new /obj/effect/temp_visual/ice_spikes(aoe_turf)
		if(prob(30))
			new /obj/effect/temp_visual/small_smoke/halfsecond(aoe_turf)
	playsound(start_turf, 'sound/abnormalities/babayaga/land.ogg', 70, TRUE, 5)
	for(var/mob/living/M in view(7, user))
		if(M.client)
			shake_camera(M, 4, 3)
	if(hit_count > 0)
		user.visible_message(span_danger("[user] slams down with It's Magic, hitting [hit_count] target\s!"))
	else
		user.visible_message(span_danger("[user] slams down with It's Magic, but hits nothing!"))

	// Free user after landing
	REMOVE_TRAIT(user, TRAIT_IMMOBILIZED, "erudition_ult")

// ============================================================
// Passive: Fine, I'll Do It Myself
// ============================================================
// On HP Threshold | Energy Gen: 5
// When any ally/user attack drops enemy to <=50% HP,
// deals AoE Ice DMG within 3 tiles of user.
// ============================================================

/datum/path_ability/passive/erudition
	name = "Fine, I'll Do It Myself"
	desc = "When you or an ally's attack drops an enemy to 50% HP, deal AoE Ice DMG around you."
	icon_state = "fine_myself"
	max_level = 12
	var/list/atk_scaling = list(25, 26.5, 28, 29.5, 31, 32.5, 34.375, 36.25, 38.125, 40, 41.5, 43)
	/// Cooldown to prevent chain triggers
	var/passive_cd = 0
	/// List of allies we have signals registered on
	var/list/registered_allies = list()

/datum/path_ability/passive/erudition/GetScalingData()
	var/list/data = list()
	data["AoE ATK Scaling"] = "[atk_scaling[level]]%"
	if(parent_path)
		var/atk = parent_path.GetStat("ATK")
		var/dmg = round(atk * atk_scaling[level] / 100, 1)
		data["AoE Damage"] = "[dmg]"
	data["Energy Gen"] = "5"
	data["Trigger"] = "You or ally drops enemy to 50% HP"
	return data

/datum/path_ability/passive/erudition/Apply(mob/living/user)
	return

/datum/path_ability/passive/erudition/Unapply(mob/living/user)
	// Unregister from all tracked allies
	for(var/mob/living/ally in registered_allies)
		UnregisterSignal(ally, COMSIG_MOB_ITEM_ATTACK)
	registered_allies.Cut()

/// Syncs signal registration with the current ally list
/datum/path_ability/passive/erudition/proc/SyncAllySignals()
	if(!parent_path?.owner)
		return
	var/list/current_allies = GetAllyList(parent_path.owner)
	// Unregister from allies no longer in list
	for(var/mob/living/old_ally in registered_allies)
		if(!(old_ally in current_allies))
			UnregisterSignal(old_ally, COMSIG_MOB_ITEM_ATTACK)
			registered_allies -= old_ally
	// Register on new allies
	for(var/mob/living/new_ally in current_allies)
		if(!(new_ally in registered_allies))
			RegisterSignal(new_ally, COMSIG_MOB_ITEM_ATTACK, PROC_REF(OnAllyAttack))
			registered_allies += new_ally

/// Signal handler for when an ally attacks something
/datum/path_ability/passive/erudition/proc/OnAllyAttack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	SIGNAL_HANDLER
	if(!isliving(target))
		return
	// Capture HP before damage resolves (signal fires before damage)
	var/hp_before = target.health
	addtimer(CALLBACK(src, TYPE_PROC_REF(/datum/path_ability/passive/erudition, CheckThreshold), target, hp_before), 1)

/// Called from OnWeaponHit to check for HP threshold triggers
/// hp_before is the target's HP before the hit that triggered this check
/datum/path_ability/passive/erudition/proc/CheckThreshold(mob/living/target, hp_before = -1)
	if(!parent_path?.owner)
		return
	if(!isliving(target) || QDELETED(target))
		return
	if(target.stat == DEAD)
		return
	// 0.5s cooldown to prevent chain triggers
	if(world.time < passive_cd)
		return
	var/threshold = target.maxHealth * 0.5
	// Must have been ABOVE 50% before, and now be AT or BELOW 50%
	if(hp_before >= 0 && hp_before <= threshold)
		return // Was already below 50% before the hit
	if(target.health <= threshold)
		passive_cd = world.time + 15
		// Teleport to target and spin attack
		var/mob/living/user = parent_path.owner
		var/turf/target_turf = get_turf(target)
		user.forceMove(target_turf)
		user.face_atom(target)
		// Calculate total damage for the spin
		var/atk = parent_path.GetStat("ATK")
		var/multiplier = atk_scaling[level] / 100
		var/total_dmg = atk * multiplier
		var/per_tick = total_dmg * 0.2
		// 5 ticks over 1 second (every 0.2s)
		parent_path.GainEnergy(5)
		to_chat(user, span_nicegreen("Fine, I'll Do It Myself!"))
		playsound(target_turf, 'sound/weapons/smash.ogg', 40, TRUE)
		// Immobilize during spin
		ADD_TRAIT(user, TRAIT_IMMOBILIZED, "erudition_spin")
		PassiveSpin(user, per_tick, 5)

/// Spin attack — deals damage in 5 ticks over 1 second
/datum/path_ability/passive/erudition/proc/PassiveSpin(mob/living/user, per_tick_dmg, ticks_left)
	if(!parent_path || QDELETED(user) || ticks_left <= 0)
		REMOVE_TRAIT(user, TRAIT_IMMOBILIZED, "erudition_spin")
		return
	// Rotate user
	user.setDir(turn(user.dir, 90))
	// Ice VFX on nearby tiles
	for(var/turf/T in range(1, user))
		if(prob(30))
			new /obj/effect/temp_visual/ice_spikes(T)
	// Deal damage to all in range 3
	for(var/mob/living/L in range(3, user))
		if(L == user || L.stat == DEAD)
			continue
		if(IsPathAlly(user, L))
			continue
		parent_path.deal_path_damage(L, per_tick_dmg)
	playsound(get_turf(user), 'sound/weapons/bladeslice.ogg', 30, TRUE)
	// Next tick in 0.2s, or free on last tick
	if(ticks_left > 1)
		addtimer(CALLBACK(src, PROC_REF(PassiveSpin), user, per_tick_dmg, ticks_left - 1), 2)
	else
		REMOVE_TRAIT(user, TRAIT_IMMOBILIZED, "erudition_spin")

// ============================================================
// Trace Nodes (Skill Tree)
// ============================================================

/datum/path/erudition/InitNodes()
	var/datum/path_node/N

	// --- Core Ability Upgrades (bottom row) ---
	N = new /datum/path_node("core_basic", "What Are You Looking At?", "Level up Basic ATK.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_BASIC
	N.level_increase = 1
	N.ahn_cost = 500
	N.connections = list("bonus_a6")
	nodes += N

	N = new /datum/path_node("core_burst", "One-Time Offer", "Level up Skill.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_BURST
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("bonus_a4")
	nodes += N

	N = new /datum/path_node("core_ultimate", "It's Magic, I Added Some Magic", "Level up Ultimate.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_ULTIMATE
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("core_passive", "bonus_a2")
	nodes += N

	N = new /datum/path_node("core_passive", "Fine, I'll Do It Myself", "Level up Passive.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_PASSIVE
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("core_basic", "core_burst", "stat_bottom")
	nodes += N

	// --- Bottom stat (no gate) ---
	N = new /datum/path_node("stat_bottom", "Ice DMG Boost", "Ice DMG increases by 3.2%.")
	N.stat_bonuses = list("ice DMG" = 3.2)
	N.stat_percent = TRUE
	N.ahn_cost = 200
	N.tree_x = 2
	N.tree_y = 6
	nodes += N

	// --- Center branch (A2 gate) ---
	N = new /datum/path_node("bonus_a2", "Efficiency", "When Skill is used, the DMG Boost effect on target enemies increases by an extra 25%.")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 2
	N.tree_x = 2
	N.tree_y = 2
	N.connections = list("stat_c1")
	nodes += N

	N = new /datum/path_node("stat_c1", "CRIT Rate Boost", "CRIT Rate increases by 2.7%.")
	N.stat_bonuses = list("CRIT Rate" = 2.7)
	N.stat_percent = TRUE
	N.ahn_cost = 400
	N.required_ascension = 2
	N.tree_x = 2
	N.tree_y = 1
	N.connections = list("stat_c2", "stat_c3")
	N.prerequisites = list("bonus_a2")
	nodes += N

	N = new /datum/path_node("stat_c2", "DEF Boost", "DEF increases by 5%.")
	N.stat_bonuses = list("DEF" = 5)
	N.stat_percent = TRUE
	N.ahn_cost = 300
	N.required_ascension = 3
	N.tree_x = 1
	N.tree_y = 0
	N.prerequisites = list("stat_c1")
	nodes += N

	N = new /datum/path_node("stat_c3", "Ice DMG Boost", "Ice DMG increases by 3.2%.")
	N.stat_bonuses = list("ice DMG" = 3.2)
	N.stat_percent = TRUE
	N.ahn_cost = 300
	N.required_ascension = 3
	N.tree_x = 3
	N.tree_y = 0
	N.prerequisites = list("stat_c1")
	nodes += N

	// --- Right branch (A4 gate) ---
	N = new /datum/path_node("bonus_a4", "Puppet", "Immune to knockback effects while below 70% HP.")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 4
	N.tree_x = 4
	N.tree_y = 3
	N.connections = list("stat_r1")
	nodes += N

	N = new /datum/path_node("stat_r1", "Ice DMG Boost", "Ice DMG increases by 4.8%.")
	N.stat_bonuses = list("ice DMG" = 4.8)
	N.stat_percent = TRUE
	N.ahn_cost = 500
	N.required_ascension = 4
	N.tree_x = 4
	N.tree_y = 2
	N.connections = list("stat_r2")
	N.prerequisites = list("bonus_a4")
	nodes += N

	N = new /datum/path_node("stat_r2", "DEF Boost", "DEF increases by 7.5%.")
	N.stat_bonuses = list("DEF" = 7.5)
	N.stat_percent = TRUE
	N.ahn_cost = 600
	N.required_ascension = 5
	N.tree_x = 4
	N.tree_y = 1
	N.connections = list("stat_r3")
	N.prerequisites = list("stat_r1")
	nodes += N

	N = new /datum/path_node("stat_r3", "DEF Boost", "DEF increases by 10%.")
	N.stat_bonuses = list("DEF" = 10)
	N.stat_percent = TRUE
	N.ahn_cost = 750
	N.required_level = 75
	N.tree_x = 4
	N.tree_y = 0
	N.prerequisites = list("stat_r2")
	nodes += N

	// --- Left branch (A6 gate) ---
	N = new /datum/path_node("bonus_a6", "Icing", "Ultimate deals 20% more DMG to enemies below 50% HP.")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 6
	N.tree_x = 0
	N.tree_y = 3
	N.connections = list("stat_l1")
	nodes += N

	N = new /datum/path_node("stat_l1", "Ice DMG Boost", "Ice DMG increases by 4.8%.")
	N.stat_bonuses = list("ice DMG" = 4.8)
	N.stat_percent = TRUE
	N.ahn_cost = 500
	N.required_ascension = 6
	N.tree_x = 0
	N.tree_y = 2
	N.connections = list("stat_l2")
	N.prerequisites = list("bonus_a6")
	nodes += N

	N = new /datum/path_node("stat_l2", "CRIT Rate Boost", "CRIT Rate increases by 4%.")
	N.stat_bonuses = list("CRIT Rate" = 4)
	N.stat_percent = TRUE
	N.ahn_cost = 700
	N.required_ascension = 6
	N.tree_x = 0
	N.tree_y = 1
	N.connections = list("stat_l3")
	N.prerequisites = list("stat_l1")
	nodes += N

	N = new /datum/path_node("stat_l3", "Ice DMG Boost", "Ice DMG increases by 6.4%.")
	N.stat_bonuses = list("ice DMG" = 6.4)
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
/datum/path/erudition/proc/HasBonus(node_id)
	return (node_id in unlocked_nodes)

/// Override GetStat for Ult ATK buff
/datum/path/erudition/GetStat(stat_name)
	var/base_val = ..()
	if(stat_name == "ATK" && ult_atk_buff)
		base_val *= 1.25
	return base_val

/datum/path/erudition/OnBonusAbilityUnlocked(node_id)
	switch(node_id)
		if("bonus_a2")
			// Efficiency: checked in Skill Activate
			return
		if("bonus_a4")
			// Puppet: knockback immunity checked elsewhere
			return
		if("bonus_a6")
			// Icing: checked in Ult Activate
			return

/// Expires the Ultimate ATK buff
/datum/path/erudition/proc/ExpireUltBuff()
	ult_atk_buff = FALSE
	ult_buff_timer = null
	if(owner)
		to_chat(owner, span_warning("ATK buff from Ultimate has expired."))

/// Override OnWeaponHit for passive threshold check
/datum/path/erudition/OnWeaponHit(mob/living/target, mob/living/user)
	// Capture HP before damage is dealt
	var/hp_before = target.health
	..()
	var/datum/path_ability/passive/erudition/pp = passive_effect
	if(istype(pp))
		// Sync ally signals periodically
		pp.SyncAllySignals()
		// Check passive HP threshold trigger (pass pre-hit HP)
		addtimer(CALLBACK(pp, TYPE_PROC_REF(/datum/path_ability/passive/erudition, CheckThreshold), target, hp_before), 1)

// ============================================================
// Erudition VFX
// ============================================================

/// Shadow marker showing where the user was standing during ult leap
/obj/effect/temp_visual/erudition_shadow
	icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'
	icon_state = "shadow"
	layer = BELOW_MOB_LAYER
	duration = 10 // 1 second
	randomdir = FALSE

// ============================================================
// Non-slipping ice turf (cosmetic only)
// ============================================================

/obj/effect/temp_visual/ice_turf/no_slip

/obj/effect/temp_visual/ice_turf/no_slip/Transform()
	icon = 'icons/turf/snow.dmi'
	icon_state = "snow[rand(0,6)]"

/obj/effect/temp_visual/ice_turf/no_slip/Crossed(atom/movable/AM)
	return ..()

/obj/effect/temp_visual/ice_turf/no_slip/BumpEffect(mob/living/carbon/human/H)
	// No slip — cosmetic only
	return
