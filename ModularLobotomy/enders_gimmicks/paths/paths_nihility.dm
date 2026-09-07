// ============================================================
// Path of Nihility (Aeon: IX)
// ============================================================
// DoT-focused debuffer. Fire element.
// Burn DoT application, Burn detonation on Ult,
// Firekiss vulnerability debuff from Burn ticks.
// ============================================================

/datum/path/nihility
	name = "Nihility"
	desc = "Applies debuffs to enemies to reduce their combat capacities."
	icon_state = "destruction"
	path_screen_icon = "nihility_path"
	path_ultimate_icon = "showstopper"
	element_type = PATH_ELEMENT_FIRE
	max_energy = 120
	path_weapon_type = /obj/item/ego_weapon/path_weapon/nihility
	path_suit_type = /obj/item/clothing/suit/path_nihility
	basic_attack_type = /datum/path_ability/basic/nihility
	burst_action_type = /datum/path_ability/burst/nihility
	ultimate_type = /datum/path_ability/ultimate/nihility
	passive_type = /datum/path_ability/passive/nihility

	// Stat table: list(phase, level, HP, ATK, DEF, SPD)
	stat_table = list(
		list(0, 1,   120, 79,  60,  106),
		list(0, 20,  191, 126, 96,  106),
		list(1, 20,  222, 146, 111, 106),
		list(1, 30,  259, 171, 130, 106),
		list(2, 30,  289, 191, 145, 106),
		list(2, 40,  327, 216, 163, 106),
		list(3, 40,  357, 235, 179, 106),
		list(3, 50,  395, 260, 197, 106),
		list(4, 50,  425, 280, 212, 106),
		list(4, 60,  462, 305, 231, 106),
		list(5, 60,  492, 325, 246, 106),
		list(5, 70,  530, 349, 265, 106),
		list(6, 70,  560, 369, 280, 106),
		list(6, 80,  598, 394, 299, 106)
	)

// ============================================================
// Nihility Weapon
// ============================================================

/obj/item/ego_weapon/path_weapon/nihility
	name = "emberdance spear"
	desc = "A double-ended spear crowned with gold-and-crimson flame at both tips, its haft banded in red and set with gold diamonds. It is wreathed in flickering flame."
	icon = 'ModularLobotomy/_Lobotomyicons/path_icons.dmi'
	icon_state = "nihility"
	inhand_icon_state = "nihility"
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/path_left.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/path_right.dmi'
	hitsound = 'sound/weapons/bladeslice.ogg'
	swingstyle = WEAPONSWING_SMALLSWEEP

// ============================================================
// Cosmetic Suit
// ============================================================

/obj/item/clothing/suit/path_nihility
	name = "reveler's bustier"
	desc = "A crimson bustier over a black corset cinched in gold, above a white skirt with red panels and black leggings. A Pathstrider's mark of the Nihility. Purely ceremonial: a Pathstrider is protected by their own DEF, not by cloth."
	icon = 'ModularLobotomy/_Lobotomyicons/path_icons.dmi'
	icon_state = "nihility_suit"
	worn_icon = 'ModularLobotomy/_Lobotomyicons/path_worn.dmi'
	worn_icon_state = "nihility_suit"
	body_parts_covered = CHEST|GROIN|ARMS|LEGS
	blood_overlay_type = null
	w_class = WEIGHT_CLASS_NORMAL

// ============================================================
// Basic ATK: Standing Ovation
// ============================================================

/datum/path_ability/basic/nihility
	name = "Standing Ovation"
	desc = "Deals Fire DMG scaling off ATK to the target. Walking on Knives bonus: +20% DMG to Burned enemies. High Poles bonus: 80% chance to apply Burn."
	icon_state = "standing_ovation"
	energy_gain = 20
	max_level = 7
	/// ATK% scaling per level: 50% at lv1 to 70% at lv7 (1.4× growth)
	var/list/atk_scaling = list(50, 53, 57, 60, 63, 67, 70)

/datum/path_ability/basic/nihility/GetScalingData()
	var/list/data = list()
	data["ATK Scaling"] = "[atk_scaling[level]]%"
	if(parent_path)
		var/atk = parent_path.GetStat("ATK")
		var/dmg = parent_path.EstimateDamage(atk * atk_scaling[level] / 100)
		data["Damage (first hit)"] = "[dmg]"
		data["Damage (later swings)"] = "[parent_path.EstimateDamage(atk * atk_scaling[level] / 100 * PATH_FOLLOWUP_MULT)]"
	data["Energy Gain"] = "[energy_gain]"
	return data

/datum/path_ability/basic/nihility/GetRawScaling()
	return atk_scaling

/datum/path_ability/basic/nihility/OnHit(mob/living/target, mob/living/user, first_hit = TRUE)
	if(!parent_path)
		return
	var/multiplier = atk_scaling[level] / 100

	// Walking on Knives (A6 bonus): +20% DMG to Burned
	var/datum/path/nihility/N = parent_path
	if(istype(N) && N.HasBonus("bonus_a6"))
		if(target.has_status_effect(/datum/status_effect/nihility_burn))
			multiplier *= 1.2

	var/total_damage = parent_path.GetStat("ATK") * multiplier
	if(!first_hit)
		total_damage *= PATH_FOLLOWUP_MULT
	var/basic_factor = parent_path.PvPScalingFactor(level, atk_scaling, PATH_TARGET_TRACE_BASIC)
	parent_path.deal_path_damage(target, total_damage, pvp_factor = basic_factor)

	// High Poles (A2 bonus): 80% chance to apply Burn
	if(istype(N) && N.HasBonus("bonus_a2") && first_hit)
		if(prob(80))
			var/datum/path_ability/burst/nihility/skill = parent_path.burst_action
			if(istype(skill))
				var/burn_atk = parent_path.GetStat("ATK") * (skill.burn_scaling[skill.level] / 100)
				var/burn_factor = parent_path.PvPScalingFactor(skill.level, skill.burn_scaling, PATH_TARGET_TRACE_SKILL)
				ApplyNihilityBurn(target, burn_atk, parent_path, burn_factor)

// ============================================================
// Skill: Blazing Welcome
// ============================================================

/datum/path_ability/burst/nihility
	name = "Blazing Welcome"
	desc = "Fires a blazing projectile that scales off ATK, dealing Fire DMG to the target and Fire DMG to adjacent enemies. Applies a powerful Burn DoT to all hit. Costs 1 AP."
	icon_state = "blazing_welcome"
	energy_gain = 30
	ap_cost = 1
	max_level = 12
	var/list/main_scaling = list(60, 66, 72, 78, 84, 90, 97.5, 105, 112.5, 120, 126, 132)
	var/list/adj_scaling = list(20, 22, 24, 26, 28, 30, 32.5, 35, 37.5, 40, 42, 44)
	var/list/burn_scaling = list(83.9, 92.3, 100.7, 109.1, 117.5, 130.1, 146.9, 167.8, 193, 218.2, 229.1, 240)

/datum/path_ability/burst/nihility/GetScalingData()
	var/list/data = list()
	if(parent_path)
		var/atk = parent_path.GetStat("ATK")
		data["Main DMG"] = "[main_scaling[level]]% ([parent_path.EstimateDamage(atk * main_scaling[level] / 100)])"
		data["Adjacent DMG"] = "[adj_scaling[level]]% ([parent_path.EstimateDamage(atk * adj_scaling[level] / 100)])"
		data["Burn DoT"] = "[burn_scaling[level]]% ATK/tick ([parent_path.EstimateDamage(atk * burn_scaling[level] / 100, do_crit = FALSE)] per tick)"
	data["Energy Gain"] = "[energy_gain]"
	data["AP Cost"] = "[ap_cost]"
	return data

/datum/path_ability/burst/nihility/GetRawScaling()
	return main_scaling

/datum/path_ability/burst/nihility/Activate(mob/living/user)
	if(!parent_path)
		return FALSE

	// Fire projectile in the direction the user is facing
	var/turf/start_turf = get_turf(user)
	var/turf/target_turf = get_ranged_target_turf(start_turf, user.dir, 7)
	if(!target_turf)
		to_chat(user, span_warning("Blazing Welcome - cannot fire!"))
		return FALSE

	var/obj/projectile/ego_bullet/nihility_burst/P = new(start_turf)
	P.firer = user
	P.fired_from = user
	P.source_path = parent_path
	P.main_mult = main_scaling[level] / 100
	P.adj_mult = adj_scaling[level] / 100
	P.burn_mult = burn_scaling[level] / 100
	P.main_pvp_factor = parent_path.PvPScalingFactor(level, main_scaling, PATH_TARGET_TRACE_SKILL)
	P.adj_pvp_factor = parent_path.PvPScalingFactor(level, adj_scaling, PATH_TARGET_TRACE_SKILL)
	P.burn_pvp_factor = parent_path.PvPScalingFactor(level, burn_scaling, PATH_TARGET_TRACE_SKILL)
	P.preparePixelProjectile(target_turf, start_turf)
	P.fire()

	playsound(start_turf, 'sound/weapons/resonator_blast.ogg', 50, TRUE)
	user.visible_message(span_danger("[user] hurls a blazing projectile!"))
	return TRUE

// ============================================================
// Blazing Welcome Projectile
// ============================================================

/obj/projectile/ego_bullet/nihility_burst
	name = "blazing welcome"
	icon = 'icons/obj/grenade.dmi'
	icon_state = "pipebomb_gift"
	damage = 0
	nodamage = TRUE
	speed = 1
	range = 7

	/// Reference to the firer's path datum
	var/datum/path/source_path
	/// Main target ATK% multiplier
	var/main_mult = 0.6
	/// Adjacent target ATK% multiplier
	var/adj_mult = 0.2
	/// Burn DoT ATK% multiplier
	var/burn_mult = 0.839
	/// Lets the burst travel past the crew instead of detonating on them.
	projectile_piercing = PASSMOB
	/// PvP scaling factors snapshotted from the path at fire time
	var/main_pvp_factor = 1
	var/adj_pvp_factor = 1
	var/burn_pvp_factor = 1

/// Without this the burst stops on the first agent standing in the line and
/// detonates there, which is friendly fire even though the damage is skipped.
/obj/projectile/ego_bullet/nihility_burst/can_hit_target(atom/target, direct_target = FALSE, ignore_loc = FALSE, cross_failed = FALSE)
	if(target != firer && !PathCanHarm(target))
		return FALSE
	if(isliving(target) && isliving(firer) && target != firer && IsPathAlly(firer, target))
		return FALSE
	return ..()

/obj/projectile/ego_bullet/nihility_burst/on_hit(atom/target, blocked = FALSE)
	..()
	if(!source_path || QDELETED(source_path))
		return BULLET_ACT_HIT

	var/atk = source_path.GetStat("ATK")
	var/turf/impact_turf = get_turf(target)
	if(!impact_turf)
		return BULLET_ACT_HIT

	// Deal main damage to the direct hit target
	if(isliving(target))
		var/mob/living/primary = target
		if(primary.stat != DEAD && !IsPathAlly(firer, primary))
			source_path.deal_path_damage(primary, atk * main_mult, pvp_factor = main_pvp_factor)
			ApplyNihilityBurn(primary, atk * burn_mult, source_path, burn_pvp_factor)

	// AoE detonation — deal adjacent damage + Burn to nearby targets
	var/hit_count = 0
	for(var/mob/living/L in range(1, impact_turf))
		if(L == firer || L == target || L.stat == DEAD)
			continue
		if(!PathCanHarm(L))
			continue
		if(IsPathAlly(firer, L))
			continue
		source_path.deal_path_damage(L, atk * adj_mult, pvp_factor = adj_pvp_factor)
		ApplyNihilityBurn(L, atk * burn_mult, source_path, burn_pvp_factor)
		hit_count++

	// VFX — fire explosion style detonation
	playsound(impact_turf, 'sound/abnormalities/scorchedgirl/explosion.ogg', 60, FALSE, 4)
	for(var/turf/aoe_turf in range(1, impact_turf))
		new /obj/effect/temp_visual/fire(aoe_turf)
	for(var/mob/living/L2 in range(1, impact_turf))
		if(L2.stat != DEAD)
			playsound(get_turf(L2), 'sound/effects/wounds/sizzle2.ogg', 25, TRUE)
	for(var/mob/living/M in view(7, impact_turf))
		if(M.client)
			shake_camera(M, 3, 2)
	if(firer)
		firer.visible_message(span_danger("Blazing Welcome detonates, hitting [hit_count + (isliving(target) ? 1 : 0)] target\s!"))

	return BULLET_ACT_HIT

// ============================================================
// Ultimate: Watch This Showstopper
// ============================================================

/datum/path_ability/ultimate/nihility
	name = "Watch This Showstopper"
	desc = "Expanding fire ring scales off ATK, dealing Fire DMG to all enemies within 3 tiles. Detonates active Burns for bonus instant damage based on the Burn tick damage."
	icon_state = "showstopper"
	max_level = 12
	var/list/aoe_scaling = list(72, 76.8, 81.6, 86.4, 91.2, 96, 102, 108, 114, 120, 124.8, 129.6)
	var/list/detonate_scaling = list(72, 74, 76, 78, 80, 82, 84.5, 87, 89.5, 92, 94, 96)

/datum/path_ability/ultimate/nihility/GetScalingData()
	var/list/data = list()
	if(parent_path)
		var/atk = parent_path.GetStat("ATK")
		data["AoE DMG"] = "[aoe_scaling[level]]% ([parent_path.EstimateDamage(atk * aoe_scaling[level] / 100)])"
		data["Burn Detonate"] = "[detonate_scaling[level]]% of Burn DMG"
		data["Energy Cost"] = "[parent_path.max_energy]"
		data["Energy Gen"] = "5"
	return data

/datum/path_ability/ultimate/nihility/GetRawScaling()
	return aoe_scaling

/datum/path_ability/ultimate/nihility/Activate(mob/living/user)
	if(!parent_path)
		return
	..()

	var/atk = parent_path.GetStat("ATK")
	var/mult = aoe_scaling[level] / 100
	var/detonate_pct = detonate_scaling[level] / 100

	// Pre-explosion fire buildup VFX
	var/turf/center = get_turf(user)
	playsound(center, 'sound/abnormalities/scorchedgirl/pre_ability.ogg', 50, FALSE, 2)
	var/obj/effect/temp_visual/human_fire/F = new(center)
	F.alpha = 0
	F.dir = user.dir
	animate(F, alpha = 255, time = 5)

	// Immobilize during buildup
	ADD_TRAIT(user, TRAIT_IMMOBILIZED, "nihility_ult")

	// Delayed explosion after 0.5s
	var/datum/path/path_ref = parent_path
	addtimer(CALLBACK(src, PROC_REF(UltExplosion), user, center, atk, mult, detonate_pct, path_ref), 5)

/// Performs the fire explosion AoE for the Ultimate
/datum/path_ability/ultimate/nihility/proc/UltExplosion(mob/living/user, turf/center, atk, mult, detonate_pct, datum/path/path_ref)
	REMOVE_TRAIT(user, TRAIT_IMMOBILIZED, "nihility_ult")

	if(QDELETED(user))
		return

	// Fire explosion sound
	playsound(center, 'sound/abnormalities/scorchedgirl/explosion.ogg', 125, FALSE, 8)

	// PvP factor for the AoE
	var/ult_factor = path_ref.PvPScalingFactor(level, aoe_scaling, PATH_TARGET_TRACE_ULT)

	// Expanding fire ring VFX + damage
	var/hit_count = 0
	for(var/i in 1 to 3)
		for(var/turf/TT in spiral_range_turfs(i, center) - spiral_range_turfs(i - 1, center))
			new /obj/effect/temp_visual/fire(TT)
			for(var/mob/living/L in TT)
				if(L == user || L.stat == DEAD)
					continue
				if(!PathCanHarm(L))
					continue
				if(IsPathAlly(user, L))
					continue
				// AoE damage
				path_ref.deal_path_damage(L, atk * mult, pvp_factor = ult_factor)
				hit_count++
				playsound(get_turf(L), 'sound/effects/wounds/sizzle2.ogg', 25, TRUE)
				// Detonate existing Burns
				var/datum/status_effect/nihility_burn/burn = L.has_status_effect(/datum/status_effect/nihility_burn)
				if(burn)
					var/detonate_dmg = burn.burn_damage * detonate_pct
					// Detonate inherits the burn's snapshotted PvP factor
					path_ref.deal_path_damage(L, detonate_dmg, do_crit = FALSE, pvp_factor = burn.pvp_factor)
		sleep(1)

	// Grant 5 energy
	path_ref.GainEnergy(5)

	// Camera shake
	for(var/mob/living/M in view(7, user))
		if(M.client)
			shake_camera(M, 5, 4)
	if(hit_count > 0)
		user.visible_message(span_danger("[user] unleashes Watch This Showstopper, hitting [hit_count] target\s!"))
	else
		user.visible_message(span_danger("[user] unleashes Watch This Showstopper, but hits nothing!"))

// ============================================================
// Passive: PatrAeon Benefits
// ============================================================

/datum/path_ability/passive/nihility
	name = "PatrAeon Benefits"
	desc = "When your Burn DoT ticks on an enemy, applies Firekiss. Firekiss increases all DMG taken by the target per stack (max 3 stacks, 30s duration)."
	icon_state = "patraeon_benefits"
	max_level = 12
	var/list/firekiss_scaling = list(4, 4.3, 4.6, 4.9, 5.2, 5.5, 5.875, 6.25, 6.625, 7, 7.3, 7.6)

/datum/path_ability/passive/nihility/GetScalingData()
	var/list/data = list()
	data["DMG Increase/Stack"] = "[firekiss_scaling[level]]%"
	data["Max Stacks"] = "3"
	data["Duration"] = "30s"
	return data

/datum/path_ability/passive/nihility/GetRawScaling()
	return firekiss_scaling

/datum/path_ability/passive/nihility/Apply(mob/living/user)
	return

/datum/path_ability/passive/nihility/Unapply(mob/living/user)
	return

// ============================================================
// Nihility Burn — Custom DoT
// ============================================================

/datum/status_effect/nihility_burn
	id = "nihility_burn"
	duration = 20 SECONDS
	tick_interval = 5 SECONDS
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null

	/// Damage per tick (snapshotted ATK * burn scaling)
	var/burn_damage = 0
	/// Reference to the attacker's path
	var/datum/path/attacker_path
	/// PvP scaling factor snapshotted at apply time. Locked across the
	/// duration so ticks behave consistently even if traces change.
	var/pvp_factor = 1

/datum/status_effect/nihility_burn/on_apply()
	. = ..()
	if(!.)
		return
	to_chat(owner, span_danger("You are burning!"))

/datum/status_effect/nihility_burn/tick()
	if(!owner || owner.stat == DEAD)
		return
	// Deal burn damage
	if(attacker_path && !QDELETED(attacker_path))
		attacker_path.deal_path_damage(owner, burn_damage, do_crit = FALSE, pvp_factor = pvp_factor)
	else
		owner.adjustFireLoss(burn_damage)
	// Passive: apply Firekiss on burn tick
	if(attacker_path?.passive_effect)
		var/datum/path_ability/passive/nihility/pp = attacker_path.passive_effect
		if(istype(pp))
			var/firekiss_pct = pp.firekiss_scaling[pp.level]
			ApplyFirekiss(owner, firekiss_pct)
	to_chat(owner, span_warning("The flames sear your flesh!"))

/datum/status_effect/nihility_burn/on_remove()
	to_chat(owner, span_notice("The flames fade."))
	return ..()

/// Global proc to apply Nihility Burn
/// pvp_factor is snapshotted from the applying ability so ticks land at a
/// consistent PvP-scaled rate even if traces change later.
/proc/ApplyNihilityBurn(mob/living/target, burn_dmg, datum/path/source_path, pvp_factor = 1)
	if(!PathCanHarm(target))
		return
	var/datum/status_effect/nihility_burn/existing = target.has_status_effect(/datum/status_effect/nihility_burn)
	if(existing)
		// Refresh duration and update damage if higher; snapshot the
		// strongest factor seen so far alongside the strongest damage.
		if(burn_dmg > existing.burn_damage)
			existing.burn_damage = burn_dmg
			existing.pvp_factor = pvp_factor
		existing.attacker_path = source_path
		existing.duration = 20 SECONDS
		return
	var/datum/status_effect/nihility_burn/NB = target.apply_status_effect(/datum/status_effect/nihility_burn)
	if(NB)
		NB.burn_damage = burn_dmg
		NB.attacker_path = source_path
		NB.pvp_factor = pvp_factor

// ============================================================
// Firekiss — Vulnerability Debuff
// ============================================================

/datum/status_effect/firekiss
	id = "firekiss"
	duration = 30 SECONDS
	tick_interval = 0
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null

	/// DMG increase percentage per stack
	var/dmg_increase = 4
	/// Current stacks
	var/stacks = 0
	/// Max stacks
	var/max_stacks = 3
	/// Tracked multiplier we've applied (e.g. 1.12 for 12% increase)
	var/applied_multiplier = 1

/datum/status_effect/firekiss/on_apply()
	. = ..()
	if(!.)
		return
	stacks = 1

/datum/status_effect/firekiss/on_remove()
	RemoveDamageMods()
	return ..()

/// Add a stack of Firekiss
/datum/status_effect/firekiss/proc/AddStack(new_pct)
	if(stacks < max_stacks)
		stacks++
	dmg_increase = new_pct
	// Refresh duration
	duration = 30 SECONDS
	UpdateDamageIncrease()

/datum/status_effect/firekiss/proc/UpdateDamageIncrease()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	if(!H.physiology)
		return
	// Divide out old multiplier
	if(applied_multiplier != 1)
		H.physiology.brute_mod /= applied_multiplier
		H.physiology.burn_mod /= applied_multiplier
	// Calculate and apply new multiplier
	applied_multiplier = 1 + (dmg_increase * stacks) / 100
	H.physiology.brute_mod *= applied_multiplier
	H.physiology.burn_mod *= applied_multiplier

/datum/status_effect/firekiss/proc/RemoveDamageMods()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	if(!H.physiology)
		return
	if(applied_multiplier != 1)
		H.physiology.brute_mod /= applied_multiplier
		H.physiology.burn_mod /= applied_multiplier
	applied_multiplier = 1

/// Global proc to apply or stack Firekiss
/proc/ApplyFirekiss(mob/living/target, dmg_pct)
	if(!PathCanHarm(target))
		return
	var/datum/status_effect/firekiss/existing = target.has_status_effect(/datum/status_effect/firekiss)
	if(existing)
		existing.AddStack(dmg_pct)
		return
	var/datum/status_effect/firekiss/FK = target.apply_status_effect(/datum/status_effect/firekiss)
	if(FK)
		FK.dmg_increase = dmg_pct
		FK.UpdateDamageIncrease()

// ============================================================
// Trace Nodes (Skill Tree)
// ============================================================

/datum/path/nihility/InitNodes()
	var/datum/path_node/N

	// --- Core Ability Upgrades ---
	N = new /datum/path_node("core_basic", "Standing Ovation", "Level up Basic ATK.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_BASIC
	N.level_increase = 1
	N.ahn_cost = 500
	N.connections = list("bonus_a6")
	nodes += N

	N = new /datum/path_node("core_burst", "Blazing Welcome", "Level up Skill.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_BURST
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("bonus_a4")
	nodes += N

	N = new /datum/path_node("core_ultimate", "Watch This Showstopper", "Level up Ultimate.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_ULTIMATE
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("core_passive", "bonus_a2")
	nodes += N

	N = new /datum/path_node("core_passive", "PatrAeon Benefits", "Level up Passive.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_PASSIVE
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("core_basic", "core_burst", "stat_bottom")
	nodes += N

	// --- Bottom stat (no gate) ---
	N = new /datum/path_node("stat_bottom", "Fire DMG Boost", "Fire DMG increases by 3.2%.")
	N.stat_bonuses = list("fire DMG" = 3.2)
	N.stat_percent = TRUE
	N.ahn_cost = 200
	N.tree_x = 2
	N.tree_y = 6
	nodes += N

	// --- Center branch (A1 gate) ---
	N = new /datum/path_node("bonus_a2", "High Poles", "Basic ATK has 80% chance to inflict Burn equivalent to Skill.")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 1
	N.tree_x = 2
	N.tree_y = 2
	N.connections = list("stat_c1")
	nodes += N

	N = new /datum/path_node("stat_c1", "Effect Hit Rate Boost", "Effect Hit Rate increases by 5.3%.")
	N.stat_bonuses = list("Effect Hit Rate" = 5.3)
	N.stat_percent = TRUE
	N.ahn_cost = 400
	N.required_ascension = 1
	N.tree_x = 2
	N.tree_y = 1
	N.connections = list("stat_c2", "stat_c3")
	N.prerequisites = list("bonus_a2")
	nodes += N

	N = new /datum/path_node("stat_c2", "Fire DMG Boost", "Fire DMG increases by 3.2%.")
	N.stat_bonuses = list("fire DMG" = 3.2)
	N.stat_percent = TRUE
	N.ahn_cost = 300
	N.required_ascension = 2
	N.tree_x = 1
	N.tree_y = 0
	N.prerequisites = list("stat_c1")
	nodes += N

	N = new /datum/path_node("stat_c3", "Effect Hit Rate Boost", "Effect Hit Rate increases by 4%.")
	N.stat_bonuses = list("Effect Hit Rate" = 4)
	N.stat_percent = TRUE
	N.ahn_cost = 300
	N.required_ascension = 2
	N.tree_x = 3
	N.tree_y = 0
	N.prerequisites = list("stat_c1")
	nodes += N

	// --- Right branch (A3 gate) ---
	N = new /datum/path_node("bonus_a4", "Bladed Hoop", "First turn comes 25% sooner at combat start.")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 3
	N.tree_x = 4
	N.tree_y = 3
	N.connections = list("stat_r1")
	nodes += N

	N = new /datum/path_node("stat_r1", "Fire DMG Boost", "Fire DMG increases by 4.8%.")
	N.stat_bonuses = list("fire DMG" = 4.8)
	N.stat_percent = TRUE
	N.ahn_cost = 500
	N.required_ascension = 3
	N.tree_x = 4
	N.tree_y = 2
	N.connections = list("stat_r2")
	N.prerequisites = list("bonus_a4")
	nodes += N

	N = new /datum/path_node("stat_r2", "Effect Hit Rate Boost", "Effect Hit Rate increases by 8%.")
	N.stat_bonuses = list("Effect Hit Rate" = 8)
	N.stat_percent = TRUE
	N.ahn_cost = 600
	N.required_ascension = 4
	N.tree_x = 4
	N.tree_y = 1
	N.connections = list("stat_r3")
	N.prerequisites = list("stat_r1")
	nodes += N

	N = new /datum/path_node("stat_r3", "Effect Hit Rate Boost", "Effect Hit Rate increases by 10.7%.")
	N.stat_bonuses = list("Effect Hit Rate" = 10.7)
	N.stat_percent = TRUE
	N.ahn_cost = 750
	N.required_level = 75
	N.tree_x = 4
	N.tree_y = 0
	N.prerequisites = list("stat_r2")
	nodes += N

	// --- Left branch (A5 gate) ---
	N = new /datum/path_node("bonus_a6", "Walking on Knives", "Deals 20% more DMG to Burned enemies.")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 5
	N.tree_x = 0
	N.tree_y = 3
	N.connections = list("stat_l1")
	nodes += N

	N = new /datum/path_node("stat_l1", "Fire DMG Boost", "Fire DMG increases by 4.8%.")
	N.stat_bonuses = list("fire DMG" = 4.8)
	N.stat_percent = TRUE
	N.ahn_cost = 500
	N.required_ascension = 5
	N.tree_x = 0
	N.tree_y = 2
	N.connections = list("stat_l2")
	N.prerequisites = list("bonus_a6")
	nodes += N

	N = new /datum/path_node("stat_l2", "Effect Hit Rate Boost", "Effect Hit Rate increases by 6%.")
	N.stat_bonuses = list("Effect Hit Rate" = 6)
	N.stat_percent = TRUE
	N.ahn_cost = 700
	N.required_ascension = 5
	N.tree_x = 0
	N.tree_y = 1
	N.connections = list("stat_l3")
	N.prerequisites = list("stat_l1")
	nodes += N

	N = new /datum/path_node("stat_l3", "Fire DMG Boost", "Fire DMG increases by 6.4%.")
	N.stat_bonuses = list("fire DMG" = 6.4)
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

/datum/path/nihility/proc/HasBonus(node_id)
	return (node_id in unlocked_nodes)

/datum/path/nihility/GetStat(stat_name)
	return ..()

/datum/path/nihility/OnBonusAbilityUnlocked(node_id)
	switch(node_id)
		if("bonus_a2")
			// High Poles: checked in Basic OnHit
			return
		if("bonus_a4")
			// Bladed Hoop: first turn comes sooner
			return
		if("bonus_a6")
			// Walking on Knives: checked in Basic OnHit
			return
