// ============================================================
// Path of Harmony (Aeon: Xipe)
// ============================================================
// Buffer / Force multiplier. Lightning element.
// Benediction buff on ally (ATK boost + bonus Lightning DMG),
// energy battery Ultimate, Passive triggers bonus DMG on USER hit.
// ============================================================

/datum/path/harmony
	name = "Harmony"
	desc = "Applies buffs to allies to improve the team's combat capacities."
	icon_state = "destruction"
	path_screen_icon = "harmony_path"
	path_ultimate_icon = "rejoicing_clouds"
	element_type = PATH_ELEMENT_LIGHTNING
	max_energy = 130
	path_weapon_type = /obj/item/ego_weapon/path_weapon/harmony
	path_suit_type = /obj/item/clothing/suit/path_harmony
	basic_attack_type = /datum/path_ability/basic/harmony
	burst_action_type = /datum/path_ability/burst/harmony
	ultimate_type = /datum/path_ability/ultimate/harmony
	passive_type = /datum/path_ability/passive/harmony

	/// The mob currently holding Benediction (only one at a time)
	var/mob/living/benediction_target
	/// Whether the SPD buff from Nourished Joviality (A2) is active
	var/nourished_active = FALSE

	// Stat table: list(phase, level, HP, ATK, DEF, SPD)
	stat_table = list(
		list(0, 1,   115, 72,  54,  112),
		list(0, 20,  183, 115, 86,  112),
		list(1, 20,  212, 133, 99,  112),
		list(1, 30,  249, 155, 116, 112),
		list(2, 30,  277, 174, 130, 112),
		list(2, 40,  314, 196, 147, 112),
		list(3, 40,  343, 214, 161, 112),
		list(3, 50,  378, 236, 178, 112),
		list(4, 50,  407, 254, 191, 112),
		list(4, 60,  444, 277, 208, 112),
		list(5, 60,  472, 295, 221, 112),
		list(5, 70,  509, 318, 238, 112),
		list(6, 70,  538, 336, 252, 112),
		list(6, 80,  573, 359, 268, 112)
	)

// ============================================================
// Harmony Weapon
// ============================================================

/obj/item/ego_weapon/path_weapon/harmony
	name = "waltzing fan"
	desc = "A folding fan of white, tan and crimson leaves on black ribs, clasped with a gold guard. It hums with a melodic charge when snapped open. Click a designated ally to grant them Benediction directly; clicking an ally never strikes them."
	icon = 'ModularLobotomy/_Lobotomyicons/path_icons.dmi'
	icon_state = "harmony"
	inhand_icon_state = "harmony"
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/path_left.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/path_right.dmi'
	hitsound = 'sound/weapons/bladeslice.ogg'
	swingstyle = WEAPONSWING_SMALLSWEEP
	skill_targets_allies = TRUE

// ============================================================
// Cosmetic Suit
// ============================================================

/obj/item/clothing/suit/path_harmony
	name = "dancer's dress"
	desc = "A white dress under a dark corset, wrapped in crimson shoulder drapes and side panels trimmed in gold. A Pathstrider's mark of the Harmony. Purely ceremonial: a Pathstrider is protected by their own DEF, not by cloth."
	icon = 'ModularLobotomy/_Lobotomyicons/path_icons.dmi'
	icon_state = "harmony_suit"
	worn_icon = 'ModularLobotomy/_Lobotomyicons/path_worn.dmi'
	worn_icon_state = "harmony_suit"
	body_parts_covered = CHEST|GROIN|ARMS
	blood_overlay_type = null
	w_class = WEIGHT_CLASS_NORMAL

// ============================================================
// Basic ATK: Dislodged
// ============================================================
// Melee Hit | Energy Generation: 20 | Lightning
// Deals Lightning DMG equal to 50%-110% of ATK to the target.
// ============================================================

/datum/path_ability/basic/harmony
	name = "Dislodged"
	desc = "Deals Lightning DMG scaling off ATK to the target. Knell Subdual bonus: +40% Basic ATK DMG. First hit of a turn deals full damage, later swings deal 30%."
	icon_state = "dislodged"
	energy_gain = 20
	max_level = 7
	/// ATK% scaling per level: 50% at lv1 to 70% at lv7 (1.4× growth)
	var/list/atk_scaling = list(50, 53, 57, 60, 63, 67, 70)

/datum/path_ability/basic/harmony/GetScalingData()
	var/list/data = list()
	data["ATK Scaling"] = "[atk_scaling[level]]%"
	if(parent_path)
		var/atk = parent_path.GetStat("ATK")
		var/dmg = parent_path.EstimateDamage(atk * atk_scaling[level] / 100)
		data["Damage (first hit)"] = "[dmg]"
		data["Damage (later swings)"] = "[parent_path.EstimateDamage(atk * atk_scaling[level] / 100 * PATH_FOLLOWUP_MULT)]"
	data["Energy Gain"] = "[energy_gain]"
	return data

/datum/path_ability/basic/harmony/GetRawScaling()
	return atk_scaling

/datum/path_ability/basic/harmony/OnHit(mob/living/target, mob/living/user, first_hit = TRUE)
	if(!parent_path)
		return
	var/multiplier = atk_scaling[level] / 100

	// Knell Subdual (A4 bonus): +40% Basic ATK DMG
	var/datum/path/harmony/H = parent_path
	if(istype(H) && H.HasBonus("bonus_a4"))
		multiplier *= 1.4

	var/total_damage = parent_path.GetStat("ATK") * multiplier
	if(!first_hit)
		total_damage *= PATH_FOLLOWUP_MULT
	var/basic_factor = parent_path.PvPScalingFactor(level, atk_scaling, PATH_TARGET_TRACE_BASIC)
	parent_path.deal_path_damage(target, total_damage, pvp_factor = basic_factor)

	// Passive: Violet Sparknado — Benediction'd ally deals bonus damage
	if(istype(H) && first_hit)
		H.TriggerPassiveDamage(target, user)

// ============================================================
// Skill: Soothing Melody
// ============================================================
// Ally Buff | Energy Generation: 30 | Lightning
// Grants Benediction to nearest designated ally within 7 tiles.
// ATK buff (capped), bonus Lightning DMG on ally's next attack.
// Only one ally can have Benediction at a time.
// ============================================================

/datum/path_ability/burst/harmony
	name = "Soothing Melody"
	desc = "Grants Benediction to nearest path ally within 5 tiles for 20s. Benediction boosts their ATK and primes a bonus Lightning DMG hit on their next attack. Costs 1 AP."
	icon_state = "soothing_melody"
	energy_gain = 30
	ap_cost = 1
	max_level = 12
	/// ATK buff % granted to ally
	var/list/atk_buff_pct = list(25, 27.5, 30, 32.5, 35, 37.5, 40.63, 43.75, 46.88, 50, 52.5, 55)
	/// ATK cap: max ATK buff as % of USER's ATK
	var/list/atk_cap_pct = list(15, 16, 17, 18, 19, 20, 21.25, 22.5, 23.75, 25, 26, 27)
	/// Bonus Lightning DMG on ally's next attack (% of ally's ATK)
	var/list/bonus_dmg_pct = list(20, 22, 24, 26, 28, 30, 32.5, 35, 37.5, 40, 42, 44)

/datum/path_ability/burst/harmony/GetScalingData()
	var/list/data = list()
	if(parent_path)
		var/user_atk = parent_path.GetStat("ATK")
		var/cap = round(user_atk * atk_cap_pct[level] / 100, 1)
		data["ATK Buff"] = "[atk_buff_pct[level]]% (cap: [cap])"
		data["Bonus Lightning DMG"] = "[bonus_dmg_pct[level]]% of ally ATK"
		data["Duration"] = "30s"
	data["Energy Gain"] = "[energy_gain]"
	data["AP Cost"] = "[ap_cost]"
	return data

/datum/path_ability/burst/harmony/GetRawScaling()
	return bonus_dmg_pct

/datum/path_ability/burst/harmony/Activate(mob/living/user, mob/living/forced_target)
	if(!parent_path)
		return FALSE

	var/datum/path/harmony/H = parent_path
	if(!istype(H))
		return FALSE

	// A clicked ally wins; otherwise the focused ally, else the nearest
	var/mob/living/best_ally = forced_target
	if(!best_ally || QDELETED(best_ally) || best_ally.stat == DEAD)
		best_ally = parent_path.GetSupportTarget(user, 7)

	if(!best_ally)
		to_chat(user, span_warning("Soothing Melody - no ally in range!"))
		return FALSE

	// Remove existing Benediction from previous target
	if(H.benediction_target && !QDELETED(H.benediction_target))
		var/datum/status_effect/benediction/old = H.benediction_target.has_status_effect(/datum/status_effect/benediction)
		if(old)
			qdel(old)

	// Calculate ATK buff amount (capped)
	var/user_atk = parent_path.GetStat("ATK")
	var/buff_amount = best_ally.maxHealth > 0 ? atk_buff_pct[level] : atk_buff_pct[level] // Always use the percentage
	var/cap_amount = user_atk * atk_cap_pct[level] / 100

	// Apply Benediction
	var/datum/status_effect/benediction/B = best_ally.apply_status_effect(/datum/status_effect/benediction)
	if(B)
		B.atk_buff_pct = buff_amount
		B.atk_cap = cap_amount
		B.bonus_lightning_pct = bonus_dmg_pct[level]
		B.source_path = parent_path
		B.has_bonus_attack = TRUE
		// Snapshot the PvP factor for the bonus attack — locked to the
		// Skill level at apply time so the bonus hit lands consistently.
		B.bonus_pvp_factor = parent_path.PvPScalingFactor(level, bonus_dmg_pct, PATH_TARGET_TRACE_SKILL)
		B.UpdateBuffs()

	H.benediction_target = best_ally

	// Signal: ally was buffed by a path user
	SEND_SIGNAL(best_ally, COMSIG_MOB_PATH_ALLY_BUFFED, parent_path, PATH_BUFF_BENEDICTION)

	// Nourished Joviality (A2 bonus): SPD +20% for 10s after Skill
	if(H.HasBonus("bonus_a2") && !H.nourished_active)
		H.nourished_active = TRUE
		if(H.owner)
			H.owner.add_movespeed_modifier(/datum/movespeed_modifier/harmony_nourished)
		addtimer(CALLBACK(H, TYPE_PROC_REF(/datum/path/harmony, NourishedExpire)), 10 SECONDS)

	// VFX
	playsound(get_turf(best_ally), 'sound/weapons/resonator_blast.ogg', 40, TRUE)
	new /obj/effect/temp_visual/heal_effect(get_turf(best_ally))
	to_chat(user, span_nicegreen("Soothing Melody grants Benediction to [best_ally]!"))
	to_chat(best_ally, span_nicegreen("[user] grants you Benediction! ATK boosted, next attack deals bonus Lightning DMG!"))
	return TRUE

// ============================================================
// Ultimate: Amidst the Rejoicing Clouds
// ============================================================
// Ally Empower | Energy Cost: 130 | Energy Gen: 5 | Lightning
// Gives 50 Energy to nearest path-holding ally within 7 tiles.
// Increases that ally's DMG by 20%-56% for 20 seconds.
// ============================================================

/datum/path_ability/ultimate/harmony
	name = "Amidst the Rejoicing Clouds"
	desc = "Grants 50 Energy to the nearest path ally and increases all DMG they deal by a multiplier for 20s. Costs all Energy."
	icon_state = "rejoicing_clouds"
	max_level = 12
	/// DMG buff % for the ally
	var/list/dmg_buff_pct = list(20, 23, 26, 29, 32, 35, 38.75, 42.5, 46.25, 50, 53, 56)

/datum/path_ability/ultimate/harmony/GetScalingData()
	var/list/data = list()
	if(parent_path)
		data["DMG Buff"] = "[dmg_buff_pct[level]]% for 20s"
		data["Energy Gift"] = "50 (path allies only)"
		data["Energy Cost"] = "[parent_path.max_energy]"
		data["Energy Gen"] = "5"
	return data

/datum/path_ability/ultimate/harmony/GetRawScaling()
	return dmg_buff_pct

/datum/path_ability/ultimate/harmony/Activate(mob/living/user)
	if(!parent_path)
		return
	..()

	// Focused ally if one is set and in range, else the nearest
	var/mob/living/best_ally = parent_path.GetSupportTarget(user, 7)

	if(!best_ally)
		to_chat(user, span_warning("Amidst the Rejoicing Clouds - no ally in range!"))
		// Refund energy
		parent_path.GainEnergy(parent_path.max_energy)
		return

	// Grant 50 energy to ally if they have a path
	if(ishuman(best_ally))
		var/mob/living/carbon/human/AH = best_ally
		var/datum/component/path_holder/holder = AH.GetComponent(/datum/component/path_holder)
		if(holder?.active_path)
			holder.active_path.GainEnergy(50)
			to_chat(best_ally, span_nicegreen("[user] grants you 50 Energy!"))

	// Apply DMG buff status effect
	var/datum/status_effect/harmony_dmg_buff/existing = best_ally.has_status_effect(/datum/status_effect/harmony_dmg_buff)
	if(existing)
		existing.dmg_increase = dmg_buff_pct[level]
		existing.duration = 20 SECONDS
		existing.UpdateDamageBuff()
	else
		var/datum/status_effect/harmony_dmg_buff/DB = best_ally.apply_status_effect(/datum/status_effect/harmony_dmg_buff)
		if(DB)
			DB.dmg_increase = dmg_buff_pct[level]
			DB.UpdateDamageBuff()

	// Signal: ally was buffed by a path user
	SEND_SIGNAL(best_ally, COMSIG_MOB_PATH_ALLY_BUFFED, parent_path, PATH_BUFF_DMG_UP)

	// Grant 5 energy to self
	parent_path.GainEnergy(5)

	// VFX
	playsound(get_turf(user), 'sound/weapons/saberon.ogg', 70, TRUE, 5)
	new /obj/effect/temp_visual/heal_effect(get_turf(best_ally))
	for(var/mob/living/M in view(7, user))
		if(M.client)
			shake_camera(M, 3, 2)
	user.visible_message(span_nicegreen("[user] empowers [best_ally] with Amidst the Rejoicing Clouds!"))
	to_chat(best_ally, span_nicegreen("[user] increases your DMG by [dmg_buff_pct[level]]% for 20 seconds!"))

// ============================================================
// Passive: Violet Sparknado
// ============================================================
// On User Attack | Lightning
// When USER attacks an enemy, the Benediction'd ally deals
// bonus Lightning DMG equal to 30%-66% of ally's ATK.
// Triggers on every hit (not gated by turns).
// ============================================================

/datum/path_ability/passive/harmony
	name = "Violet Sparknado"
	desc = "When you hit a target, your Benediction-buffed ally automatically deals bonus Lightning DMG equal to a % of their ATK to the same target."
	icon_state = "violet_sparknado"
	max_level = 12
	/// Bonus DMG: % of ally's ATK
	var/list/bonus_dmg_pct = list(30, 33, 36, 39, 42, 45, 48.75, 52.5, 56.25, 60, 63, 66)

/datum/path_ability/passive/harmony/GetScalingData()
	var/list/data = list()
	data["Bonus DMG"] = "[bonus_dmg_pct[level]]% of ally ATK"
	data["Trigger"] = "Every USER hit (not turn-gated)"
	var/datum/path/harmony/H = parent_path
	if(istype(H) && H.benediction_target)
		data["Benediction Target"] = "[H.benediction_target.name]"
	return data

/datum/path_ability/passive/harmony/GetRawScaling()
	return bonus_dmg_pct

/datum/path_ability/passive/harmony/Apply(mob/living/user)
	return

/datum/path_ability/passive/harmony/Unapply(mob/living/user)
	return

// ============================================================
// Benediction — ATK Buff + Bonus Lightning DMG Status Effect
// ============================================================

/datum/status_effect/benediction
	id = "benediction"
	duration = 30 SECONDS
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null

	/// ATK buff percentage
	var/atk_buff_pct = 25
	/// ATK cap (flat amount, calculated from USER's ATK)
	var/atk_cap = 50
	/// Bonus Lightning DMG on next attack (% of ally ATK)
	var/bonus_lightning_pct = 20
	/// Whether the bonus attack is available
	var/has_bonus_attack = TRUE
	/// Reference to the Harmony user's path
	var/datum/path/source_path
	/// Applied ATK multiplier (for clean removal)
	var/applied_atk_mult = 1
	/// PvP scaling factor for the bonus Lightning DMG hit. Snapshotted
	/// from the Harmony Skill's scaling at apply time.
	var/bonus_pvp_factor = 1
	/// Fan-patterned aura shown on the buffed ally while active. A vis_contents
	/// object so it can hover independently of the mob.
	var/obj/effect/abstract/benediction_aura/aura

/datum/status_effect/benediction/on_apply()
	. = ..()
	if(!.)
		return
	RegisterSignal(owner, COMSIG_MOB_ITEM_ATTACK, PROC_REF(OnOwnerAttack))
	aura = new()
	owner.vis_contents += aura
	// Slow 2px hover, looping forever
	animate(aura, pixel_y = 2, time = 1.5 SECONDS, loop = -1, easing = SINE_EASING)
	animate(pixel_y = 0, time = 1.5 SECONDS, easing = SINE_EASING)
	to_chat(owner, span_nicegreen("Benediction active! ATK boosted!"))

/datum/status_effect/benediction/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_ITEM_ATTACK)
	if(aura)
		if(owner)
			owner.vis_contents -= aura
		QDEL_NULL(aura)
	RemoveBuffs()
	// Clear benediction target reference on the Harmony path
	if(source_path)
		var/datum/path/harmony/H = source_path
		if(istype(H) && H.benediction_target == owner)
			H.benediction_target = null
	to_chat(owner, span_notice("Benediction fades."))
	return ..()

/obj/effect/abstract/benediction_aura
	icon = 'ModularLobotomy/_Lobotomyicons/path_icons.dmi'
	icon_state = "benediction"
	layer = ABOVE_MOB_LAYER
	appearance_flags = KEEP_APART | RESET_TRANSFORM | RESET_COLOR
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE

/// Teal-and-gold lightning strike shown on a target hit by Benediction's bonus
/obj/effect/temp_visual/benediction_punish
	name = "harmonic reprisal"
	icon = 'ModularLobotomy/_Lobotomyicons/path_icons.dmi'
	icon_state = "benediction_punish"
	duration = 7

/// Applies the ATK buff to the target
/datum/status_effect/benediction/proc/UpdateBuffs()
	RemoveBuffs()
	if(!isliving(owner))
		return

	// Check if target has a path
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		var/datum/component/path_holder/holder = H.GetComponent(/datum/component/path_holder)
		if(holder?.active_path)
			// Path holder: modify their path's external_atk_bonus
			// Cap: the effective ATK increase cannot exceed atk_cap flat ATK
			var/ally_atk = holder.active_path.GetStat("ATK")
			var/raw_buff = ally_atk * atk_buff_pct / 100
			var/capped_buff = min(raw_buff, atk_cap)
			var/effective_pct = (capped_buff / max(ally_atk, 1)) * 100
			holder.active_path.external_atk_bonus += effective_pct
			applied_atk_mult = effective_pct
			return

	// Non-path carbon: boost extra_damage
	applied_atk_mult = atk_buff_pct
	owner.extra_damage += applied_atk_mult

/datum/status_effect/benediction/proc/RemoveBuffs()
	if(!applied_atk_mult)
		return
	if(!isliving(owner))
		applied_atk_mult = 0
		return

	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		var/datum/component/path_holder/holder = H.GetComponent(/datum/component/path_holder)
		if(holder?.active_path)
			// Path holder: remove the external ATK bonus
			holder.active_path.external_atk_bonus -= applied_atk_mult
			applied_atk_mult = 0
			return

	// Non-path: remove from extra_damage
	owner.extra_damage -= applied_atk_mult
	applied_atk_mult = 0

/// Signal handler: when the Benediction'd ally attacks something
/datum/status_effect/benediction/proc/OnOwnerAttack(datum/source, mob/living/target, mob/living/user, obj/item/weapon)
	SIGNAL_HANDLER
	if(!isliving(target))
		return
	if(has_bonus_attack)
		INVOKE_ASYNC(src, PROC_REF(ConsumeBonusAttack), target)

/// Called when the Benediction'd ally attacks — consumes the bonus Lightning DMG
/datum/status_effect/benediction/proc/ConsumeBonusAttack(mob/living/target)
	if(!has_bonus_attack)
		return
	has_bonus_attack = FALSE
	if(!owner || QDELETED(target))
		return
	// Deal bonus Lightning DMG equal to bonus_lightning_pct% of ally's ATK
	var/ally_atk = 0
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		var/datum/component/path_holder/holder = H.GetComponent(/datum/component/path_holder)
		if(holder?.active_path)
			ally_atk = holder.active_path.GetStat("ATK")
	if(ally_atk <= 0)
		ally_atk = 50 // Fallback for non-path allies
	var/bonus_dmg = ally_atk * bonus_lightning_pct / 100
	if(source_path)
		source_path.deal_path_damage(target, bonus_dmg, pvp_factor = bonus_pvp_factor)
	else
		target.adjustBruteLoss(bonus_dmg, forced = TRUE)
	new /obj/effect/temp_visual/benediction_punish(get_turf(target))
	to_chat(owner, span_nicegreen("Benediction bonus Lightning DMG!"))

// ============================================================
// Harmony DMG Buff — From Ultimate
// ============================================================

/datum/status_effect/harmony_dmg_buff
	id = "harmony_dmg_buff"
	duration = 20 SECONDS
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null

	/// DMG increase percentage
	var/dmg_increase = 20
	/// Applied brute multiplier (for clean removal)
	var/applied_multiplier = 1

/datum/status_effect/harmony_dmg_buff/on_apply()
	. = ..()
	if(!.)
		return
	to_chat(owner, span_nicegreen("DMG increased!"))

/datum/status_effect/harmony_dmg_buff/on_remove()
	RemoveDamageBuff()
	to_chat(owner, span_notice("DMG buff fades."))
	return ..()

/// Applies the DMG increase
/datum/status_effect/harmony_dmg_buff/proc/UpdateDamageBuff()
	RemoveDamageBuff()
	if(!isliving(owner))
		return

	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		var/datum/component/path_holder/holder = H.GetComponent(/datum/component/path_holder)
		if(holder?.active_path)
			// Path holder: modify their path's external_dmg_mult
			applied_multiplier = 1 + dmg_increase / 100
			holder.active_path.external_dmg_mult *= applied_multiplier
			return

	// Non-path carbon: boost extra_damage
	applied_multiplier = dmg_increase
	owner.extra_damage += applied_multiplier

/datum/status_effect/harmony_dmg_buff/proc/RemoveDamageBuff()
	if(applied_multiplier == 1 || applied_multiplier == 0)
		return
	if(!isliving(owner))
		applied_multiplier = 1
		return

	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		var/datum/component/path_holder/holder = H.GetComponent(/datum/component/path_holder)
		if(holder?.active_path)
			// Path holder: divide out from external_dmg_mult
			holder.active_path.external_dmg_mult /= applied_multiplier
			applied_multiplier = 1
			return

	// Non-path: remove from extra_damage
	owner.extra_damage -= applied_multiplier
	applied_multiplier = 1

// ============================================================
// Movespeed Modifier for Nourished Joviality (A2)
// ============================================================

/datum/movespeed_modifier/harmony_nourished
	multiplicative_slowdown = -0.4

// ============================================================
// Trace Nodes (Skill Tree)
// ============================================================

/datum/path/harmony/InitNodes()
	var/datum/path_node/N

	// --- Core Ability Upgrades ---
	N = new /datum/path_node("core_basic", "Dislodged", "Level up Basic ATK.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_BASIC
	N.level_increase = 1
	N.ahn_cost = 500
	N.connections = list("bonus_a6")
	nodes += N

	N = new /datum/path_node("core_burst", "Soothing Melody", "Level up Skill.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_BURST
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("bonus_a4")
	nodes += N

	N = new /datum/path_node("core_ultimate", "Amidst the Rejoicing Clouds", "Level up Ultimate.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_ULTIMATE
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("core_passive", "bonus_a2")
	nodes += N

	N = new /datum/path_node("core_passive", "Violet Sparknado", "Level up Passive.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_PASSIVE
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("core_basic", "core_burst", "stat_bottom")
	nodes += N

	// --- Bottom stat (no gate) ---
	N = new /datum/path_node("stat_bottom", "ATK Boost", "ATK increases by 4%.")
	N.stat_bonuses = list("ATK" = 4)
	N.stat_percent = TRUE
	N.ahn_cost = 200
	N.tree_x = 2
	N.tree_y = 6
	nodes += N

	// --- Center branch (A1 gate) ---
	N = new /datum/path_node("bonus_a2", "Nourished Joviality", "SPD increases by 20% for 10s after using Skill.")
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

	N = new /datum/path_node("stat_c3", "Lightning DMG Boost", "Lightning DMG increases by 3.2%.")
	N.stat_bonuses = list("lightning DMG" = 3.2)
	N.stat_percent = TRUE
	N.ahn_cost = 300
	N.required_ascension = 2
	N.tree_x = 3
	N.tree_y = 0
	N.prerequisites = list("stat_c1")
	nodes += N

	// --- Right branch (A3 gate) ---
	N = new /datum/path_node("bonus_a4", "Knell Subdual", "DMG dealt by Basic ATK increases by 40%.")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 3
	N.tree_x = 4
	N.tree_y = 3
	N.connections = list("stat_r1")
	nodes += N

	N = new /datum/path_node("stat_r1", "ATK Boost", "ATK increases by 6%.")
	N.stat_bonuses = list("ATK" = 6)
	N.stat_percent = TRUE
	N.ahn_cost = 500
	N.required_ascension = 3
	N.tree_x = 4
	N.tree_y = 2
	N.connections = list("stat_r2")
	N.prerequisites = list("bonus_a4")
	nodes += N

	N = new /datum/path_node("stat_r2", "DEF Boost", "DEF increases by 7.5%.")
	N.stat_bonuses = list("DEF" = 7.5)
	N.stat_percent = TRUE
	N.ahn_cost = 600
	N.required_ascension = 4
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

	// --- Left branch (A5 gate) ---
	N = new /datum/path_node("bonus_a6", "Jubilant Passage", "Regenerate 5 Energy at the start of each turn.")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 5
	N.tree_x = 0
	N.tree_y = 3
	N.connections = list("stat_l1")
	nodes += N

	N = new /datum/path_node("stat_l1", "Lightning DMG Boost", "Lightning DMG increases by 4.8%.")
	N.stat_bonuses = list("lightning DMG" = 4.8)
	N.stat_percent = TRUE
	N.ahn_cost = 500
	N.required_ascension = 5
	N.tree_x = 0
	N.tree_y = 2
	N.connections = list("stat_l2")
	N.prerequisites = list("bonus_a6")
	nodes += N

	N = new /datum/path_node("stat_l2", "ATK Boost", "ATK increases by 6%.")
	N.stat_bonuses = list("ATK" = 6)
	N.stat_percent = TRUE
	N.ahn_cost = 700
	N.required_ascension = 5
	N.tree_x = 0
	N.tree_y = 1
	N.connections = list("stat_l3")
	N.prerequisites = list("stat_l1")
	nodes += N

	N = new /datum/path_node("stat_l3", "ATK Boost", "ATK increases by 8%.")
	N.stat_bonuses = list("ATK" = 8)
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
/datum/path/harmony/proc/HasBonus(node_id)
	return (node_id in unlocked_nodes)

/datum/path/harmony/GetStat(stat_name)
	return ..()

/datum/path/harmony/OnBonusAbilityUnlocked(node_id)
	switch(node_id)
		if("bonus_a2")
			// Nourished Joviality: checked in Skill Activate
			return
		if("bonus_a4")
			// Knell Subdual: checked in Basic OnHit
			return
		if("bonus_a6")
			// Jubilant Passage: checked in OnTurnReset override
			return

/// Override OnTurnReset for Jubilant Passage (A6): +5 Energy per turn
/datum/path/harmony/OnTurnReset()
	..()
	if(HasBonus("bonus_a6"))
		GainEnergy(5)
		if(owner)
			to_chat(owner, span_nicegreen("Jubilant Passage: +5 Energy!"))

/// Expires the Nourished Joviality SPD buff
/datum/path/harmony/proc/NourishedExpire()
	nourished_active = FALSE
	if(owner)
		owner.remove_movespeed_modifier(/datum/movespeed_modifier/harmony_nourished)

/// Triggers Violet Sparknado passive — Benediction'd ally deals bonus DMG
/datum/path/harmony/proc/TriggerPassiveDamage(mob/living/target, mob/living/user)
	if(!benediction_target || QDELETED(benediction_target))
		return
	if(benediction_target.stat == DEAD)
		return
	if(!passive_effect)
		return
	var/datum/path_ability/passive/harmony/pp = passive_effect
	if(!istype(pp))
		return
	// Get ally's ATK (from their path if they have one, else fallback)
	var/ally_atk = 50
	if(ishuman(benediction_target))
		var/mob/living/carbon/human/AH = benediction_target
		var/datum/component/path_holder/holder = AH.GetComponent(/datum/component/path_holder)
		if(holder?.active_path)
			ally_atk = holder.active_path.GetStat("ATK")
	var/bonus_dmg = ally_atk * pp.bonus_dmg_pct[pp.level] / 100
	var/passive_factor = PvPScalingFactor(pp.level, pp.bonus_dmg_pct, PATH_TARGET_TRACE_PASSIVE)
	deal_path_damage(target, bonus_dmg, pvp_factor = passive_factor)

/// Override OnWeaponHit to trigger Benediction bonus attack consumption
/datum/path/harmony/OnWeaponHit(mob/living/target, mob/living/user)
	if(target.status_flags & GODMODE) // no attacking/farming invulnerable targets
		return
	..()
	// Check if the target we just hit has Benediction (for when the Benediction'd ally attacks)
	// This is handled separately — Benediction bonus triggers when the ALLY attacks, not the Harmony user
	// The Harmony user's attacks trigger the Passive (Violet Sparknado), which is handled in Basic OnHit
