// ============================================================
// Path of Abundance (Aeon: Yaoshi)
// ============================================================
// Healer / Sustain support. Physical element.
// HP-scaling heals, single-target HoT on Skill,
// team-wide heal on Ultimate, emergency heal boost Passive.
// ============================================================

/datum/path/abundance
	name = "Abundance"
	desc = "Heals allies and restores HP to the team."
	icon_state = "destruction"
	element_type = PATH_ELEMENT_PHYSICAL
	max_energy = 90
	path_weapon_type = /obj/item/ego_weapon/path_weapon/abundance
	basic_attack_type = /datum/path_ability/basic/abundance
	burst_action_type = /datum/path_ability/burst/abundance
	ultimate_type = /datum/path_ability/ultimate/abundance
	passive_type = /datum/path_ability/passive/abundance

	// Stat table: list(phase, level, HP, ATK, DEF, SPD)
	stat_table = list(
		list(0, 1,   158, 64,  69,  98),
		list(0, 20,  308, 126, 134, 98),
		list(1, 20,  372, 152, 162, 98),
		list(1, 30,  451, 184, 196, 98),
		list(2, 30,  514, 210, 224, 98),
		list(2, 40,  594, 243, 258, 98),
		list(3, 40,  657, 268, 286, 98),
		list(3, 50,  736, 301, 320, 98),
		list(4, 50,  799, 327, 348, 98),
		list(4, 60,  879, 359, 382, 98),
		list(5, 60,  942, 385, 410, 98),
		list(5, 70,  1021, 417, 445, 98),
		list(6, 70,  1085, 443, 472, 98),
		list(6, 80,  1164, 476, 507, 98)
	)

// ============================================================
// Abundance Weapon
// ============================================================

/obj/item/ego_weapon/path_weapon/abundance
	name = "Abundance Staff"
	desc = "A weapon suffused with gentle, life-giving energy."
	hitsound = 'sound/weapons/bladeslice.ogg'
	swingstyle = WEAPONSWING_SMALLSWEEP

// ============================================================
// Basic ATK: Behind the Kindness
// ============================================================
// Melee Hit | Energy Generation: 20 | Physical
// Deals Physical DMG equal to 50%-110% of ATK to the target.
// ============================================================

/datum/path_ability/basic/abundance
	name = "Behind the Kindness"
	desc = "Deals Physical DMG to the target hit."
	icon_state = "farewell_hit"
	energy_gain = 20
	max_level = 7
	var/list/atk_scaling = list(50, 60, 70, 80, 90, 100, 110)

/datum/path_ability/basic/abundance/GetScalingData()
	var/list/data = list()
	data["ATK Scaling"] = "[atk_scaling[level]]%"
	if(parent_path)
		var/atk = parent_path.GetStat("ATK")
		var/dmg = round(atk * atk_scaling[level] / 100, 1)
		data["Damage"] = "[dmg]"
	data["Energy Gain"] = "[energy_gain]"
	return data

/datum/path_ability/basic/abundance/OnHit(mob/living/target, mob/living/user, first_hit = TRUE)
	if(!parent_path)
		return
	var/multiplier = atk_scaling[level] / 100
	var/total_damage = parent_path.GetStat("ATK") * multiplier
	if(!first_hit)
		total_damage *= 0.1
	parent_path.deal_path_damage(target, total_damage)

// ============================================================
// Skill: Love, Heal, and Choose
// ============================================================
// Ally Heal | Energy Generation: 30
// Heals nearest designated ally (or self) within 7 tiles.
// Instant heal + HoT for 2 ticks over 20 seconds.
// ============================================================

/datum/path_ability/burst/abundance
	name = "Love, Heal, and Choose"
	desc = "Heals nearest ally. Instant heal + HoT for 20s."
	icon_state = "rip_home_run"
	energy_gain = 30
	ap_cost = 1
	max_level = 12
	/// Instant heal: % of USER's Max HP
	var/list/instant_hp_pct = list(7, 7.44, 7.88, 8.31, 8.75, 9.1, 9.45, 9.8, 10.15, 10.5, 10.85, 11.2)
	/// Instant heal: flat amount
	var/list/instant_flat = list(70, 112, 143.5, 175, 196, 217, 232.75, 248.5, 264.25, 280, 295.75, 311.5)
	/// HoT: % of USER's Max HP per tick
	var/list/hot_hp_pct = list(4.8, 5.1, 5.4, 5.7, 6, 6.24, 6.48, 6.72, 6.96, 7.2, 7.44, 7.68)
	/// HoT: flat amount per tick
	var/list/hot_flat = list(48, 76.8, 98.4, 120, 134.4, 148.8, 159.6, 170.4, 181.2, 192, 202.8, 213.6)

/datum/path_ability/burst/abundance/GetScalingData()
	var/list/data = list()
	if(parent_path)
		var/max_hp = parent_path.GetStat("HP")
		var/inst = round(max_hp * instant_hp_pct[level] / 100 + instant_flat[level], 1)
		var/hot = round(max_hp * hot_hp_pct[level] / 100 + hot_flat[level], 1)
		data["Instant Heal"] = "[instant_hp_pct[level]]% HP + [instant_flat[level]] ([inst])"
		data["HoT/tick"] = "[hot_hp_pct[level]]% HP + [hot_flat[level]] ([hot])"
		data["HoT Duration"] = "20s (2 ticks)"

		// Recuperation bonus
		var/datum/path/abundance/A = parent_path
		if(istype(A) && A.HasBonus("bonus_a6"))
			data["HoT Duration"] = "30s (3 ticks)"
	data["Energy Gain"] = "[energy_gain]"
	data["AP Cost"] = "[ap_cost]"
	return data

/datum/path_ability/burst/abundance/Activate(mob/living/user)
	if(!parent_path)
		return

	var/max_hp = parent_path.GetStat("HP")

	// Find nearest designated ally within 7 tiles, or self
	var/mob/living/heal_target = user
	var/best_dist = INFINITY
	var/list/allies = GetAllyList(user)
	for(var/mob/living/ally in allies)
		if(QDELETED(ally) || ally.stat == DEAD)
			continue
		var/d = get_dist(user, ally)
		if(d <= 7 && d < best_dist)
			best_dist = d
			heal_target = ally

	// Calculate heal amounts
	var/instant_amount = max_hp * instant_hp_pct[level] / 100 + instant_flat[level]
	var/hot_amount = max_hp * hot_hp_pct[level] / 100 + hot_flat[level]

	// Passive: Innervation — boost healing if target is below 30% HP
	var/datum/path/abundance/A = parent_path
	if(istype(A))
		var/heal_mult = A.GetHealingMultiplier(heal_target)
		instant_amount *= heal_mult
		hot_amount *= heal_mult

	// Soothe (A2 bonus): cleanse 1 debuff
	if(istype(A) && A.HasBonus("bonus_a2"))
		cleanse_debuff(heal_target)

	// Apply instant heal
	heal_target.adjustBruteLoss(-instant_amount, forced = TRUE)
	heal_target.adjustFireLoss(-instant_amount * 0.5, forced = TRUE)

	// Apply HoT
	var/hot_ticks = 2
	// Recuperation (A6 bonus): +1 tick
	if(istype(A) && A.HasBonus("bonus_a6"))
		hot_ticks = 3

	var/datum/status_effect/abundance_hot/existing = heal_target.has_status_effect(/datum/status_effect/abundance_hot)
	if(existing)
		existing.heal_amount = hot_amount
		existing.ticks_remaining = hot_ticks
		existing.duration = hot_ticks * 10 SECONDS
	else
		var/datum/status_effect/abundance_hot/HOT = heal_target.apply_status_effect(/datum/status_effect/abundance_hot)
		if(HOT)
			HOT.heal_amount = hot_amount
			HOT.ticks_remaining = hot_ticks
			HOT.duration = hot_ticks * 10 SECONDS

	// Signal: ally was buffed/healed by a path user
	if(heal_target != user)
		SEND_SIGNAL(heal_target, COMSIG_MOB_PATH_ALLY_BUFFED, parent_path, PATH_BUFF_HEAL)

	// VFX
	playsound(get_turf(heal_target), 'sound/weapons/resonator_blast.ogg', 40, TRUE)
	new /obj/effect/temp_visual/heal_effect(get_turf(heal_target))
	to_chat(user, span_nicegreen("Love, Heal, and Choose heals [heal_target == user ? "you" : heal_target]!"))
	if(heal_target != user)
		to_chat(heal_target, span_nicegreen("[user] heals you with Love, Heal, and Choose!"))

// ============================================================
// Ultimate: Gift of Rebirth
// ============================================================
// Team Heal | Energy Cost: 90 | Energy Gen: 5
// Heals all designated allies (and self) within 7 tiles.
// ============================================================

/datum/path_ability/ultimate/abundance
	name = "Gift of Rebirth"
	desc = "Heals all designated allies within 7 tiles."
	icon_state = "stardust_ace"
	max_level = 12
	/// Heal: % of USER's Max HP
	var/list/heal_hp_pct = list(9.2, 9.78, 10.35, 10.93, 11.5, 11.96, 12.42, 12.88, 13.34, 13.8, 14.26, 14.72)
	/// Heal: flat amount
	var/list/heal_flat = list(92, 147.2, 188.6, 230, 257.6, 285.2, 305.9, 326.6, 347.3, 368, 388.7, 409.4)

/datum/path_ability/ultimate/abundance/GetScalingData()
	var/list/data = list()
	if(parent_path)
		var/max_hp = parent_path.GetStat("HP")
		var/heal = round(max_hp * heal_hp_pct[level] / 100 + heal_flat[level], 1)
		data["Heal (per ally)"] = "[heal_hp_pct[level]]% HP + [heal_flat[level]] ([heal])"
		data["Energy Cost"] = "[parent_path.max_energy]"
		data["Energy Gen"] = "5"
	return data

/datum/path_ability/ultimate/abundance/Activate(mob/living/user)
	if(!parent_path)
		return
	..()

	var/max_hp = parent_path.GetStat("HP")
	var/heal_amount = max_hp * heal_hp_pct[level] / 100 + heal_flat[level]

	var/datum/path/abundance/A = parent_path

	// Heal self
	var/self_heal = heal_amount
	if(istype(A))
		self_heal *= A.GetHealingMultiplier(user)
	user.adjustBruteLoss(-self_heal, forced = TRUE)
	user.adjustFireLoss(-self_heal * 0.5, forced = TRUE)

	// Heal all designated allies within 7 tiles
	var/heal_count = 1
	var/list/allies = GetAllyList(user)
	for(var/mob/living/ally in allies)
		if(QDELETED(ally) || ally.stat == DEAD)
			continue
		if(get_dist(user, ally) > 7)
			continue
		var/ally_heal = heal_amount
		if(istype(A))
			ally_heal *= A.GetHealingMultiplier(ally)
		ally.adjustBruteLoss(-ally_heal, forced = TRUE)
		ally.adjustFireLoss(-ally_heal * 0.5, forced = TRUE)
		SEND_SIGNAL(ally, COMSIG_MOB_PATH_ALLY_BUFFED, parent_path, PATH_BUFF_HEAL)
		new /obj/effect/temp_visual/heal_effect(get_turf(ally))
		to_chat(ally, span_nicegreen("[user] heals you with Gift of Rebirth!"))
		heal_count++

	// Grant 5 energy
	parent_path.GainEnergy(5)

	// VFX
	new /obj/effect/temp_visual/heal_effect(get_turf(user))
	playsound(get_turf(user), 'sound/weapons/resonator_blast.ogg', 60, TRUE)
	for(var/mob/living/M in view(7, user))
		if(M.client)
			shake_camera(M, 2, 1)
	user.visible_message(span_nicegreen("[user] unleashes Gift of Rebirth, healing [heal_count] target\s!"))

// ============================================================
// Passive: Innervation
// ============================================================
// On Heal
// When healing an ally whose HP is at 30% or lower,
// outgoing healing is increased by 25%-55%.
// ============================================================

/datum/path_ability/passive/abundance
	name = "Innervation"
	desc = "When healing an ally at or below 30% HP, healing is increased."
	icon_state = "perfect_pickoff"
	max_level = 12
	/// Healing boost % when target is at or below 30% HP
	var/list/heal_boost = list(25, 27.5, 30, 32.5, 35, 37.5, 40.63, 43.75, 46.88, 50, 52.5, 55)

/datum/path_ability/passive/abundance/GetScalingData()
	var/list/data = list()
	data["Heal Boost"] = "[heal_boost[level]]%"
	data["Trigger"] = "Target at or below 30% HP"
	return data

/datum/path_ability/passive/abundance/Apply(mob/living/user)
	return

/datum/path_ability/passive/abundance/Unapply(mob/living/user)
	return

// ============================================================
// Abundance HoT — Heal Over Time Status Effect
// ============================================================

/datum/status_effect/abundance_hot
	id = "abundance_hot"
	duration = 20 SECONDS
	tick_interval = 10 SECONDS
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null

	/// Heal amount per tick
	var/heal_amount = 0
	/// Ticks remaining
	var/ticks_remaining = 2

/datum/status_effect/abundance_hot/on_apply()
	. = ..()
	if(!.)
		return
	to_chat(owner, span_nicegreen("You are being healed over time."))

/datum/status_effect/abundance_hot/tick()
	if(!owner || owner.stat == DEAD)
		return
	if(ticks_remaining <= 0)
		qdel(src)
		return
	ticks_remaining--
	owner.adjustBruteLoss(-heal_amount, forced = TRUE)
	owner.adjustFireLoss(-heal_amount * 0.5, forced = TRUE)
	to_chat(owner, span_nicegreen("Healing soothes your wounds."))

/datum/status_effect/abundance_hot/on_remove()
	to_chat(owner, span_notice("The healing fades."))
	return ..()

// ============================================================
// Heal VFX
// ============================================================

/obj/effect/temp_visual/heal_effect
	icon = 'icons/effects/effects.dmi'
	icon_state = "yourstate"
	color = "#7CFC00"
	duration = 10
	layer = ABOVE_MOB_LAYER
	randomdir = FALSE

/obj/effect/temp_visual/heal_effect/Initialize()
	. = ..()
	// Green sparkle rising effect
	icon_state = "sparkles"
	animate(src, pixel_y = pixel_y + 16, alpha = 0, time = 10)

// ============================================================
// Debuff Cleanse (Soothe)
// ============================================================

/// Removes the first cleansable debuff found on the target
/proc/cleanse_debuff(mob/living/target)
	if(!target)
		return FALSE

	// Priority order: DoTs first, then fragile, then damage down
	var/list/cleansable_types = list(
		/datum/status_effect/stacking/lc_burn,
		/datum/status_effect/stacking/lc_burn/dark_flame,
		/datum/status_effect/stacking/lc_bleed,
		/datum/status_effect/stacking/lc_mental_decay,
		/datum/status_effect/stacking/lc_tremor,
		/datum/status_effect/stacking/lc_overheat,
		/datum/status_effect/stacking/pallid_noise,
		/datum/status_effect/stacking/protection/fragile,
		/datum/status_effect/stacking/damage_up/down
	)

	for(var/effect_type in cleansable_types)
		var/datum/status_effect/found = target.has_status_effect(effect_type)
		if(found)
			to_chat(target, span_nicegreen("A debuff has been cleansed!"))
			qdel(found)
			return TRUE
	return FALSE

// ============================================================
// Trace Nodes (Skill Tree)
// ============================================================

/datum/path/abundance/InitNodes()
	var/datum/path_node/N

	// --- Core Ability Upgrades ---
	N = new /datum/path_node("core_basic", "Behind the Kindness", "Level up Basic ATK.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_BASIC
	N.level_increase = 1
	N.ahn_cost = 500
	N.connections = list("bonus_a6")
	nodes += N

	N = new /datum/path_node("core_burst", "Love, Heal, and Choose", "Level up Skill.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_BURST
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("bonus_a4")
	nodes += N

	N = new /datum/path_node("core_ultimate", "Gift of Rebirth", "Level up Ultimate.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_ULTIMATE
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("core_passive", "bonus_a2")
	nodes += N

	N = new /datum/path_node("core_passive", "Innervation", "Level up Passive.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_PASSIVE
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("core_basic", "core_burst", "hp1_bottom")
	nodes += N

	// --- Bottom stat (no gate) ---
	N = new /datum/path_node("hp1_bottom", "HP Boost", "HP increases by 4%.")
	N.stat_bonuses = list("HP" = 4)
	N.stat_percent = TRUE
	N.ahn_cost = 200
	N.tree_x = 2
	N.tree_y = 6
	nodes += N

	// --- Center branch (A2 gate) ---
	N = new /datum/path_node("bonus_a2", "Soothe", "When using Skill, dispels 1 debuff from the target.")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 2
	N.tree_x = 2
	N.tree_y = 2
	N.connections = list("heal1")
	nodes += N

	N = new /datum/path_node("heal1", "Healing Boost", "Healing Boost increases by 4%.")
	N.stat_bonuses = list("Healing Boost" = 4)
	N.stat_percent = TRUE
	N.ahn_cost = 400
	N.required_ascension = 2
	N.tree_x = 2
	N.tree_y = 1
	N.connections = list("hp2", "def1")
	N.prerequisites = list("bonus_a2")
	nodes += N

	N = new /datum/path_node("hp2", "HP Boost", "HP increases by 4%.")
	N.stat_bonuses = list("HP" = 4)
	N.stat_percent = TRUE
	N.ahn_cost = 300
	N.required_ascension = 3
	N.tree_x = 1
	N.tree_y = 0
	N.prerequisites = list("heal1")
	nodes += N

	N = new /datum/path_node("def1", "DEF Boost", "DEF increases by 5%.")
	N.stat_bonuses = list("DEF" = 5)
	N.stat_percent = TRUE
	N.ahn_cost = 300
	N.required_ascension = 3
	N.tree_x = 3
	N.tree_y = 0
	N.prerequisites = list("heal1")
	nodes += N

	// --- Right branch (A4 gate) ---
	N = new /datum/path_node("bonus_a4", "Healer", "Outgoing Healing increases by 10%.")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 4
	N.tree_x = 4
	N.tree_y = 3
	N.connections = list("hp3")
	nodes += N

	N = new /datum/path_node("hp3", "HP Boost", "HP increases by 6%.")
	N.stat_bonuses = list("HP" = 6)
	N.stat_percent = TRUE
	N.ahn_cost = 500
	N.required_ascension = 4
	N.tree_x = 4
	N.tree_y = 2
	N.connections = list("heal2")
	N.prerequisites = list("bonus_a4")
	nodes += N

	N = new /datum/path_node("heal2", "Healing Boost", "Healing Boost increases by 6%.")
	N.stat_bonuses = list("Healing Boost" = 6)
	N.stat_percent = TRUE
	N.ahn_cost = 600
	N.required_ascension = 5
	N.tree_x = 4
	N.tree_y = 1
	N.connections = list("def2")
	N.prerequisites = list("hp3")
	nodes += N

	N = new /datum/path_node("def2", "DEF Boost", "DEF increases by 7.5%.")
	N.stat_bonuses = list("DEF" = 7.5)
	N.stat_percent = TRUE
	N.ahn_cost = 750
	N.required_level = 75
	N.tree_x = 4
	N.tree_y = 0
	N.prerequisites = list("heal2")
	nodes += N

	// --- Left branch (A6 gate) ---
	N = new /datum/path_node("bonus_a6", "Recuperation", "Increases Skill HoT duration by 1 tick (10s).")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 6
	N.tree_x = 0
	N.tree_y = 3
	N.connections = list("heal3")
	nodes += N

	N = new /datum/path_node("heal3", "Healing Boost", "Healing Boost increases by 6%.")
	N.stat_bonuses = list("Healing Boost" = 6)
	N.stat_percent = TRUE
	N.ahn_cost = 500
	N.required_ascension = 6
	N.tree_x = 0
	N.tree_y = 2
	N.connections = list("hp4")
	N.prerequisites = list("bonus_a6")
	nodes += N

	N = new /datum/path_node("hp4", "HP Boost", "HP increases by 6%.")
	N.stat_bonuses = list("HP" = 6)
	N.stat_percent = TRUE
	N.ahn_cost = 700
	N.required_ascension = 6
	N.tree_x = 0
	N.tree_y = 1
	N.connections = list("hp5")
	N.prerequisites = list("heal3")
	nodes += N

	N = new /datum/path_node("hp5", "HP Boost", "HP increases by 8%.")
	N.stat_bonuses = list("HP" = 8)
	N.stat_percent = TRUE
	N.ahn_cost = 800
	N.required_level = 80
	N.tree_x = 0
	N.tree_y = 0
	N.prerequisites = list("hp4")
	nodes += N

// ============================================================
// Bonus Ability Effects
// ============================================================

/// Checks if a bonus ability node is unlocked
/datum/path/abundance/proc/HasBonus(node_id)
	return (node_id in unlocked_nodes)

/// Returns the healing multiplier for a target based on passive + bonuses
/datum/path/abundance/proc/GetHealingMultiplier(mob/living/target)
	var/mult = 1

	// Healing Boost stat from trace nodes
	var/heal_boost_stat = GetStat("Healing Boost")
	if(heal_boost_stat)
		mult *= (1 + heal_boost_stat / 100)

	// Healer (A4 bonus): +10% outgoing healing
	if(HasBonus("bonus_a4"))
		mult *= 1.1

	// Innervation (Passive): boost healing when target is at or below 30% HP
	if(target && target.health <= target.maxHealth * 0.3)
		var/datum/path_ability/passive/abundance/pp = passive_effect
		if(istype(pp))
			mult *= (1 + pp.heal_boost[pp.level] / 100)

	// PvP scaling: reduce healing for non-path carbons
	// Same ratio as PvP damage: target.maxHealth / owner.maxHealth
	if(ishuman(target) && owner)
		var/mob/living/carbon/human/H = target
		var/datum/component/path_holder/holder = H.GetComponent(/datum/component/path_holder)
		if(!holder || !holder.active_path)
			// Non-path human — scale healing down by HP ratio
			mult *= H.maxHealth / max(owner.maxHealth, 1)

	return mult

/datum/path/abundance/GetStat(stat_name)
	return ..()

/datum/path/abundance/OnBonusAbilityUnlocked(node_id)
	switch(node_id)
		if("bonus_a2")
			// Soothe: checked in Skill Activate
			return
		if("bonus_a4")
			// Healer: checked in GetHealingMultiplier
			return
		if("bonus_a6")
			// Recuperation: checked in Skill Activate
			return
