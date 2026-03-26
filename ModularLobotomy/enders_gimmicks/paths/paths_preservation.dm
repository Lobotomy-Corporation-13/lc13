// ============================================================
// Path of Preservation (Aeon: Qlipoth)
// ============================================================
// Tank / Shielder / Aggro magnet. Fire element.
// Magma Will stacking for enhanced attacks, team shielding
// on every action, taunt to draw aggro, DEF-scaling Ultimate.
// ============================================================

/datum/path/preservation
	name = "Preservation"
	desc = "Possesses powerful defensive abilities to protect allies in various ways."
	icon_state = "destruction"
	path_screen_icon = "preservation_path"
	path_ultimate_icon = "war_flaming_lance"
	element_type = PATH_ELEMENT_FIRE
	max_energy = 120
	path_weapon_type = /obj/item/ego_weapon/path_weapon/preservation
	basic_attack_type = /datum/path_ability/basic/preservation
	burst_action_type = /datum/path_ability/burst/preservation
	ultimate_type = /datum/path_ability/ultimate/preservation
	passive_type = /datum/path_ability/passive/preservation

	/// Magma Will stacks (0-8)
	var/magma_will = 0
	/// Max Magma Will stacks
	var/max_magma_will = 8
	/// Whether the next enhanced basic attack is free (from Ultimate)
	var/free_enhanced = FALSE
	/// Whether the A6 ATK buff is active this turn
	var/action_bo_atk_active = FALSE

	// Stat table: list(phase, level, HP, ATK, DEF, SPD)
	stat_table = list(
		list(0, 1,   168, 81,  82,  95),
		list(0, 20,  329, 159, 160, 95),
		list(1, 20,  397, 192, 193, 95),
		list(1, 30,  481, 233, 235, 95),
		list(2, 30,  549, 265, 268, 95),
		list(2, 40,  633, 306, 309, 95),
		list(3, 40,  701, 339, 342, 95),
		list(3, 50,  785, 380, 383, 95),
		list(4, 50,  853, 413, 416, 95),
		list(4, 60,  937, 454, 457, 95),
		list(5, 60,  1005, 486, 490, 95),
		list(5, 70,  1089, 527, 532, 95),
		list(6, 70,  1157, 560, 565, 95),
		list(6, 80,  1241, 601, 606, 95)
	)

// ============================================================
// Preservation Weapon
// ============================================================

/obj/item/ego_weapon/path_weapon/preservation
	name = "Preservation Lance"
	desc = "A weapon forged from amber and iron will."
	hitsound = 'sound/weapons/bladeslice.ogg'
	swingstyle = WEAPONSWING_LARGESWEEP

// ============================================================
// Magma Will Helpers
// ============================================================

/// Gains Magma Will stacks, clamped to max
/datum/path/preservation/proc/GainMagmaWill(amount = 1)
	magma_will = min(magma_will + amount, max_magma_will)
	if(owner)
		to_chat(owner, span_notice("Magma Will: [magma_will]/[max_magma_will]"))

/// Spends Magma Will stacks
/datum/path/preservation/proc/SpendMagmaWill(amount = 4)
	magma_will = max(magma_will - amount, 0)

/// Applies team shield to all designated allies within 5 tiles
/datum/path/preservation/proc/ApplyTeamShield()
	if(!passive_effect)
		return
	var/datum/path_ability/passive/preservation/pp = passive_effect
	if(!istype(pp))
		return
	var/def = GetStat("DEF")
	var/shield_amount = def * pp.shield_def_pct[pp.level] / 100 + pp.shield_flat[pp.level]
	if(shield_amount <= 0)
		return
	var/list/allies_in_range = GetPathAlliesInRange(owner, 5)
	for(var/mob/living/ally in allies_in_range)
		if(ally.stat == DEAD)
			continue
		// PvP scaling: reduce shield for non-path carbons
		var/ally_shield = shield_amount
		if(ishuman(ally) && owner)
			var/mob/living/carbon/human/AH = ally
			var/datum/component/path_holder/holder = AH.GetComponent(/datum/component/path_holder)
			if(!holder || !holder.active_path)
				ally_shield *= AH.maxHealth / max(owner.maxHealth, 1)
		// Apply or refresh shield — remove old and reapply to reset timer
		var/datum/status_effect/preservation_shield/existing = ally.has_status_effect(/datum/status_effect/preservation_shield)
		var/old_hp = 0
		if(existing)
			old_hp = existing.shield_hp
			qdel(existing)
		var/datum/status_effect/preservation_shield/S = ally.apply_status_effect(/datum/status_effect/preservation_shield)
		if(S)
			S.shield_hp = max(old_hp, ally_shield)
			S.update_shield_visual()
		SEND_SIGNAL(ally, COMSIG_MOB_PATH_ALLY_BUFFED, src, PATH_BUFF_SHIELD)

// ============================================================
// Basic ATK: Ice-Breaking Light
// ============================================================
// Melee Hit | Energy Generation: 20 | Fire
// Normal: 50%-110% ATK, gains 1 Magma Will.
// Enhanced (4+ stacks): 90%-146.25% ATK to primary +
//   36%-58.5% to adjacent. Consumes 4 stacks. 30 energy.
// ============================================================

/datum/path_ability/basic/preservation
	name = "Ice-Breaking Light"
	desc = "Deals Fire DMG scaling off ATK. At 4+ Magma Will stacks, becomes an enhanced AoE that hits primary + adjacent targets, consuming 4 stacks. Gains 1 Magma Will on first hit."
	icon_state = "ice_breaking_light"
	energy_gain = 20
	max_level = 7
	/// Normal ATK% scaling
	var/list/atk_scaling = list(50, 60, 70, 80, 90, 100, 110)
	/// Enhanced main ATK% scaling
	var/list/enhanced_main = list(90, 99, 108, 117, 126, 135, 146.25)
	/// Enhanced adjacent ATK% scaling
	var/list/enhanced_adj = list(36, 39.6, 43.2, 46.8, 50.4, 54, 58.5)

/datum/path_ability/basic/preservation/GetScalingData()
	var/list/data = list()
	if(parent_path)
		var/atk = parent_path.GetStat("ATK")
		var/dmg = round(atk * atk_scaling[level] / 100, 1)
		data["Normal DMG"] = "[atk_scaling[level]]% ([dmg])"
		var/enh_dmg = round(atk * enhanced_main[level] / 100, 1)
		var/adj_dmg = round(atk * enhanced_adj[level] / 100, 1)
		data["Enhanced Main"] = "[enhanced_main[level]]% ([enh_dmg])"
		data["Enhanced Adj"] = "[enhanced_adj[level]]% ([adj_dmg])"
	data["Energy Gain"] = "[energy_gain] (30 enhanced)"
	var/datum/path/preservation/P = parent_path
	if(istype(P))
		data["Magma Will"] = "[P.magma_will]/[P.max_magma_will]"
	return data

/datum/path_ability/basic/preservation/OnHit(mob/living/target, mob/living/user, first_hit = TRUE)
	if(!parent_path)
		return
	var/datum/path/preservation/P = parent_path
	if(!istype(P))
		return

	var/is_enhanced = (P.magma_will >= 4 || P.free_enhanced)

	if(is_enhanced && first_hit)
		// Enhanced AoE attack
		var/atk = parent_path.GetStat("ATK")
		var/main_mult = enhanced_main[level] / 100
		var/adj_mult = enhanced_adj[level] / 100

		// Main target damage
		parent_path.deal_path_damage(target, atk * main_mult)

		// Adjacent targets
		for(var/mob/living/L in range(1, target))
			if(L == target || L == user || L.stat == DEAD)
				continue
			if(IsPathAlly(user, L))
				continue
			parent_path.deal_path_damage(L, atk * adj_mult)

		// Consume stacks (unless free from Ultimate)
		if(P.free_enhanced)
			P.free_enhanced = FALSE
		else
			P.SpendMagmaWill(4)

		// Enhanced generates 30 energy (handled by overriding gain in OnWeaponHit)
		// We flag this so OnWeaponHit knows to use 30 instead of 20
		energy_gain = 30

		// Unwavering Gallantry (A4 bonus): restore 5% max HP
		if(P.HasBonus("bonus_a4"))
			var/heal = parent_path.GetStat("HP") * 0.05
			user.adjustBruteLoss(-heal, forced = TRUE)
			to_chat(user, span_nicegreen("Unwavering Gallantry! +[round(heal)] HP!"))

		// VFX
		for(var/turf/aoe_turf in range(1, target))
			if(prob(50))
				new /obj/effect/temp_visual/fire(aoe_turf)
		playsound(get_turf(target), 'sound/weapons/smash.ogg', 50, TRUE)
		for(var/mob/living/M in view(7, user))
			if(M.client)
				shake_camera(M, 2, 1)
		user.visible_message(span_danger("[user] unleashes enhanced Ice-Breaking Light!"))
	else
		// Normal attack
		var/multiplier = atk_scaling[level] / 100
		var/total_damage = parent_path.GetStat("ATK") * multiplier
		if(!first_hit)
			total_damage *= 0.1
		parent_path.deal_path_damage(target, total_damage)
		energy_gain = 20

	// Gain 1 Magma Will on first hit per turn
	if(first_hit)
		P.GainMagmaWill(1)

	// Apply team shield on attack
	if(first_hit)
		P.ApplyTeamShield()

// ============================================================
// Skill: Ever-Burning Amber
// ============================================================
// Self Buff | Energy Generation: 30 | Fire
// DMG Reduction 40%-52% for 10s. Gains 1 Magma Will.
// Taunts all enemies within 5 tiles for 10s.
// ============================================================

/datum/path_ability/burst/preservation
	name = "Ever-Burning Amber"
	desc = "Grants DMG Reduction% for 10s and taunts all enemies within 5 tiles to attack you. Gains 1 Magma Will stack. Costs 1 AP."
	icon_state = "ever_burning_amber"
	energy_gain = 30
	ap_cost = 1
	max_level = 12
	/// DMG Reduction % per level
	var/list/dmg_red_pct = list(40, 41, 42, 43, 44, 45, 46.25, 47.5, 48.75, 50, 51, 52)

/datum/path_ability/burst/preservation/GetScalingData()
	var/list/data = list()
	data["DMG Reduction"] = "[dmg_red_pct[level]]% for 10s"
	data["Taunt"] = "5-tile range, 10s"
	data["Magma Will"] = "+1 stack"
	data["Energy Gain"] = "[energy_gain]"
	data["AP Cost"] = "[ap_cost]"
	return data

/datum/path_ability/burst/preservation/Activate(mob/living/user)
	if(!parent_path)
		return
	var/datum/path/preservation/P = parent_path
	if(!istype(P))
		return

	// Apply DMG Reduction status effect
	var/datum/status_effect/preservation_dmg_red/existing = user.has_status_effect(/datum/status_effect/preservation_dmg_red)
	if(existing)
		existing.reduction_pct = dmg_red_pct[level]
		existing.duration = 10 SECONDS
		existing.UpdateReduction()
	else
		var/datum/status_effect/preservation_dmg_red/DR = user.apply_status_effect(/datum/status_effect/preservation_dmg_red)
		if(DR)
			DR.reduction_pct = dmg_red_pct[level]
			DR.UpdateReduction()

	// Gain 1 Magma Will
	P.GainMagmaWill(1)

	// Taunt: force simple mobs within 5 tiles to target the user
	for(var/mob/living/simple_animal/hostile/SA in range(5, user))
		if(SA.stat == DEAD)
			continue
		SA.GiveTarget(user)
	to_chat(user, span_nicegreen("Ever-Burning Amber! Enemies drawn to you!"))

	// The Strong Defend the Weak (A2 bonus): allies take 15% less DMG for 10s
	if(P.HasBonus("bonus_a2"))
		var/list/allies_in_range = GetPathAlliesInRange(user, 5)
		for(var/mob/living/ally in allies_in_range)
			if(ally == user || ally.stat == DEAD)
				continue
			var/datum/status_effect/preservation_ally_dr/adr = ally.apply_status_effect(/datum/status_effect/preservation_ally_dr)
			if(adr)
				adr.UpdateReduction()

	// Apply team shield
	P.ApplyTeamShield()

	// VFX
	playsound(get_turf(user), 'sound/weapons/saberon.ogg', 50, TRUE, 3)
	for(var/turf/T in range(1, user))
		if(prob(40))
			new /obj/effect/temp_visual/fire(T)
	for(var/mob/living/M in view(7, user))
		if(M.client)
			shake_camera(M, 2, 1)
	user.visible_message(span_danger("[user] activates Ever-Burning Amber! Enemies are drawn to them!"))

// ============================================================
// Ultimate: War-Flaming Lance
// ============================================================
// 3-tile AoE | Energy Cost: 120 | Energy Gen: 5 | Fire
// Deals ATK% + DEF% Fire DMG to all enemies within 3 tiles.
// Next Basic ATK is auto-enhanced and free (no stack cost).
// ============================================================

/datum/path_ability/ultimate/preservation
	name = "War-Flaming Lance"
	desc = "Dash forward dealing Fire DMG scaling off ATK + DEF to all enemies along the path, then fire explosions erupt on each tile. Costs all Energy."
	icon_state = "war_flaming_lance"
	max_level = 12
	/// ATK% scaling
	var/list/atk_scaling = list(50, 55, 60, 65, 70, 75, 81.25, 87.5, 93.75, 100, 105, 110)
	/// DEF% scaling
	var/list/def_scaling = list(75, 82.5, 90, 97.5, 105, 112.5, 121.88, 131.25, 140.63, 150, 157.5, 165)

/datum/path_ability/ultimate/preservation/GetScalingData()
	var/list/data = list()
	if(parent_path)
		var/atk = parent_path.GetStat("ATK")
		var/def = parent_path.GetStat("DEF")
		var/atk_dmg = round(atk * atk_scaling[level] / 100, 1)
		var/def_dmg = round(def * def_scaling[level] / 100, 1)
		data["ATK Scaling"] = "[atk_scaling[level]]% ([atk_dmg])"
		data["DEF Scaling"] = "[def_scaling[level]]% ([def_dmg])"
		data["Total per target"] = "[atk_dmg + def_dmg]"
		data["Dash DMG"] = "20% on pass"
		data["Explosion DMG"] = "80% after 1s"
		data["Energy Cost"] = "[parent_path.max_energy]"
		data["Energy Gen"] = "5"
	return data

/datum/path_ability/ultimate/preservation/Activate(mob/living/user)
	if(!parent_path)
		return
	..()

	var/datum/path/preservation/P = parent_path
	if(!istype(P))
		return

	var/atk = parent_path.GetStat("ATK")
	var/def = parent_path.GetStat("DEF")
	var/atk_dmg = atk * atk_scaling[level] / 100
	var/def_dmg = def * def_scaling[level] / 100
	var/total_dmg = atk_dmg + def_dmg

	// Immobilize during dash
	ADD_TRAIT(user, TRAIT_IMMOBILIZED, "preservation_ult")

	// Dash forward — 5 tiles in facing direction, sweeping 3 tiles wide
	var/turf/start_turf = get_turf(user)
	var/dash_dir = user.dir
	var/perp_left = turn(dash_dir, 90)
	var/perp_right = turn(dash_dir, -90)

	// Center-line turfs the user actually moves through
	var/list/center_turfs = list(start_turf)
	// All turfs in the 3-wide sweep (for damage + VFX)
	var/list/sweep_turfs = list()
	var/turf/current = start_turf
	for(var/i in 1 to 5)
		var/turf/next = get_step(current, dash_dir)
		if(!next || next.density)
			break
		var/blocked = FALSE
		for(var/obj/O in next)
			if(O.density)
				blocked = TRUE
				break
		if(blocked)
			break
		current = next
		center_turfs += current
		// Add center + left + right to sweep
		sweep_turfs |= current
		var/turf/left = get_step(current, perp_left)
		if(left)
			sweep_turfs |= left
		var/turf/right = get_step(current, perp_right)
		if(right)
			sweep_turfs |= right

	// Move user to end of dash
	if(current != start_turf)
		user.forceMove(current)

	// Phase 1: Deal 20% damage to all enemies in the 3-wide sweep + sparks VFX
	var/dash_dmg = total_dmg * 0.2
	var/list/hit_mobs = list()
	for(var/turf/TT in sweep_turfs)
		new /obj/effect/temp_visual/cult/sparks(TT)
		for(var/mob/living/L in TT)
			if(L == user || L.stat == DEAD)
				continue
			if(IsPathAlly(user, L))
				continue
			if(L in hit_mobs)
				continue
			parent_path.deal_path_damage(L, dash_dmg, do_crit = FALSE)
			hit_mobs += L

	// Beam VFX along the center line
	if(length(center_turfs) >= 2)
		var/turf/trail_start = center_turfs[1]
		var/turf/trail_end = center_turfs[length(center_turfs)]
		trail_start.Beam(trail_end, "1-full", time = 10)
	playsound(current, 'sound/weapons/bladeslice.ogg', 60, TRUE)
	user.visible_message(span_danger("[user] charges forward with War-Flaming Lance!"))

	// Phase 2: After 1 second, explosions across the entire sweep area
	var/datum/path/path_ref = parent_path
	addtimer(CALLBACK(src, PROC_REF(UltExplosions), user, sweep_turfs, center_turfs, total_dmg, path_ref, P), 10)

/// Phase 2: Fire explosions across the sweep area, dealing 80% damage
/datum/path_ability/ultimate/preservation/proc/UltExplosions(mob/living/user, list/sweep_turfs, list/center_turfs, total_dmg, datum/path/path_ref, datum/path/preservation/P)
	REMOVE_TRAIT(user, TRAIT_IMMOBILIZED, "preservation_ult")

	if(QDELETED(user))
		return

	var/explosion_dmg = total_dmg * 0.8

	// Deal 80% damage to ALL enemies on every sweep turf
	var/list/already_hit = list()
	for(var/turf/TT in sweep_turfs)
		for(var/mob/living/L in TT)
			if(L == user || L.stat == DEAD)
				continue
			if(IsPathAlly(user, L))
				continue
			if(L in already_hit)
				continue
			already_hit += L
			path_ref.deal_path_damage(L, explosion_dmg, do_crit = FALSE)

	// VFX: place 3x3 explosion effects spaced along the center line
	// Every 3 tiles so they don't overlap visually
	var/list/explosion_centers = list()
	var/last_index = 0
	for(var/i in 1 to length(center_turfs))
		if(i == 1 || (i - last_index) >= 3)
			explosion_centers += center_turfs[i]
			last_index = i
	var/turf/trail_end = center_turfs[length(center_turfs)]
	if(!(trail_end in explosion_centers))
		explosion_centers += trail_end

	// Stagger explosion VFX slightly for visual pop
	var/delay = 0
	for(var/turf/center in explosion_centers)
		addtimer(CALLBACK(src, PROC_REF(ExplosionVFX), center), delay)
		delay += 1

	// Camera shake for everyone nearby
	for(var/mob/living/M in view(7, user))
		if(M.client)
			shake_camera(M, 4, 3)

	// Grant 5 energy
	path_ref.GainEnergy(5)

	// Next basic attack is free enhanced
	P.free_enhanced = TRUE
	to_chat(user, span_nicegreen("Next Basic ATK is enhanced for free!"))

	// Apply team shield
	P.ApplyTeamShield()

/// Spawns an explosion VFX at a center turf (visual only)
/datum/path_ability/ultimate/preservation/proc/ExplosionVFX(turf/center)
	if(!center)
		return
	new /obj/effect/temp_visual/explosion(center)
	playsound(center, 'sound/abnormalities/scorchedgirl/explosion.ogg', 60, FALSE, 4)

// ============================================================
// Passive: Magma Will & Shield
// ============================================================
// Magma Will: 0-8 stacks. Gained from attacks, Skill, being hit.
// At 4+, Basic ATK becomes enhanced AoE.
// Team Shield: on every action, shield allies within 5 tiles.
// ============================================================

/datum/path_ability/passive/preservation
	name = "Magma Will & Shield"
	desc = "Magma Will (0-8 stacks): gained from attacks, Skill use, and taking damage (1.5s cooldown). At 4+ stacks, Basic ATK becomes enhanced AoE. On every attack and Skill, shields you and all allies within 5 tiles based on DEF%."
	icon_state = "architects_treasure"
	max_level = 12
	/// Shield: % of USER's DEF
	var/list/shield_def_pct = list(4, 4.2, 4.4, 4.6, 4.8, 5, 5.25, 5.5, 5.75, 6, 6.2, 6.4)
	/// Shield: flat amount
	var/list/shield_flat = list(20, 26, 32, 38, 44, 50, 57.5, 65, 72.5, 80, 84.5, 89)
	/// Cooldown for gaining Magma Will from damage
	var/damage_mw_cooldown = 0

/datum/path_ability/passive/preservation/GetScalingData()
	var/list/data = list()
	if(parent_path)
		var/def = parent_path.GetStat("DEF")
		var/shield = round(def * shield_def_pct[level] / 100 + shield_flat[level], 1)
		data["Shield Amount"] = "[shield_def_pct[level]]% DEF + [shield_flat[level]] ([shield])"
	data["Shield Duration"] = "20s"
	data["Max Magma Will"] = "8"
	data["Enhanced at"] = "4+ stacks"
	var/datum/path/preservation/P = parent_path
	if(istype(P))
		data["Magma Will"] = "[P.magma_will]/[P.max_magma_will]"
	return data

/datum/path_ability/passive/preservation/Apply(mob/living/user)
	// Register to gain Magma Will when hit
	RegisterSignal(user, COMSIG_MOB_APPLY_DAMGE, PROC_REF(OnTakeDamage))

/datum/path_ability/passive/preservation/Unapply(mob/living/user)
	UnregisterSignal(user, COMSIG_MOB_APPLY_DAMGE)

/// Signal handler: gain Magma Will when hit (1.5s cooldown)
/datum/path_ability/passive/preservation/proc/OnTakeDamage(datum/source)
	SIGNAL_HANDLER
	if(!parent_path)
		return
	if(world.time < damage_mw_cooldown)
		return
	damage_mw_cooldown = world.time + 1.5 SECONDS
	var/datum/path/preservation/P = parent_path
	if(istype(P))
		P.GainMagmaWill(1)

// ============================================================
// Preservation Shield — DMG Absorption Status Effect
// ============================================================
// Works like the Dieci shield: intercepts COMSIG_MOB_APPLY_DAMGE
// to absorb damage before it reaches the mob. Overflow damage is
// dealt as forced damage to bypass the handler.
// ============================================================

/datum/status_effect/preservation_shield
	id = "preservation_shield"
	duration = 20 SECONDS
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null

	/// HP remaining on the shield
	var/shield_hp = 0

/datum/status_effect/preservation_shield/on_apply()
	. = ..()
	if(!.)
		return
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_damage))
	update_shield_visual()
	to_chat(owner, span_nicegreen("A protective shield surrounds you!"))

/datum/status_effect/preservation_shield/on_remove()
	UnregisterSignal(owner, COMSIG_MOB_APPLY_DAMGE)
	// Remove shield visual
	if(owner && !QDELETED(owner))
		owner.remove_filter("preservation_shield")
	to_chat(owner, span_notice("The protective shield fades."))
	return ..()

/// Signal handler: absorb incoming damage into shield HP
/datum/status_effect/preservation_shield/proc/on_damage(datum/source, damage, damagetype, def_zone, atom/damage_source, flags, attack_type)
	SIGNAL_HANDLER
	// Let forced damage through to prevent recursion
	if(flags & DAMAGE_FORCED)
		return
	if(shield_hp <= 0)
		return
	// Full absorption
	if(damage <= shield_hp)
		shield_hp -= damage
		spawn_shield_visual()
		if(shield_hp <= 0)
			update_shield_visual()
		return COMPONENT_MOB_DENY_DAMAGE
	// Partial absorption — shield breaks, overflow dealt as forced damage
	var/overflow = damage - shield_hp
	shield_hp = 0
	spawn_shield_visual()
	update_shield_visual()
	// Deal overflow via INVOKE_ASYNC with DAMAGE_FORCED to skip our handler
	INVOKE_ASYNC(owner, TYPE_PROC_REF(/mob/living, deal_damage), overflow, damagetype, damage_source, DAMAGE_FORCED, null, null, def_zone)
	return COMPONENT_MOB_DENY_DAMAGE

/// Spawn a brief shield flash visual on the mob
/datum/status_effect/preservation_shield/proc/spawn_shield_visual()
	if(!owner || QDELETED(owner))
		return
	var/obj/effect/temp_visual/shock_shield/effect = new(get_turf(owner))
	effect.transform *= 0.5
	effect.pixel_x += rand(-8, 8)

/// Update the persistent shield outline visual based on current shield HP
/datum/status_effect/preservation_shield/proc/update_shield_visual()
	if(!owner || QDELETED(owner))
		return
	if(shield_hp > 0)
		var/intensity = clamp(shield_hp / 200, 0.3, 1.0)
		var/size_val = round(1 + intensity)
		owner.add_filter("preservation_shield", 5, list("type" = "outline", "color" = "#FF8C0080", "size" = size_val))
	else
		owner.remove_filter("preservation_shield")

// ============================================================
// Preservation DMG Reduction — Self Buff from Skill
// ============================================================

/datum/status_effect/preservation_dmg_red
	id = "preservation_dmg_red"
	duration = 10 SECONDS
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null

	/// DMG Reduction percentage
	var/reduction_pct = 40
	/// Applied damage_resistance value (for clean removal)
	var/applied_resistance = 0

/datum/status_effect/preservation_dmg_red/on_apply()
	. = ..()
	if(!.)
		return
	to_chat(owner, span_nicegreen("DMG Reduction active!"))

/datum/status_effect/preservation_dmg_red/on_remove()
	RemoveReduction()
	to_chat(owner, span_notice("DMG Reduction fades."))
	return ..()

/// Applies the DMG Reduction — boosts DEF via external_def_bonus on path holder
/datum/status_effect/preservation_dmg_red/proc/UpdateReduction()
	RemoveReduction()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	var/datum/component/path_holder/holder = H.GetComponent(/datum/component/path_holder)
	if(holder?.active_path)
		// Path holder: boost DEF stat temporarily
		applied_resistance = reduction_pct
		holder.active_path.external_def_bonus += applied_resistance
		holder.active_path.ApplyDefense()
	else if(H.physiology)
		// Fallback for non-path (shouldn't happen, but safe)
		applied_resistance = reduction_pct
		var/keep_factor = (100 - applied_resistance) / 100
		H.physiology.damage_resistance = 100 - ((100 - H.physiology.damage_resistance) * keep_factor)

/datum/status_effect/preservation_dmg_red/proc/RemoveReduction()
	if(!applied_resistance)
		return
	if(!ishuman(owner))
		applied_resistance = 0
		return
	var/mob/living/carbon/human/H = owner
	var/datum/component/path_holder/holder = H.GetComponent(/datum/component/path_holder)
	if(holder?.active_path)
		holder.active_path.external_def_bonus -= applied_resistance
		holder.active_path.ApplyDefense()
	else if(H.physiology)
		var/keep_factor = (100 - applied_resistance) / 100
		if(keep_factor > 0)
			H.physiology.damage_resistance = 100 - ((100 - H.physiology.damage_resistance) / keep_factor)
	applied_resistance = 0

// ============================================================
// Preservation Ally DMG Reduction — From A2 Bonus
// ============================================================
// Path holders: temporary +15% DEF via external_def_bonus
// Non-path carbons: damage_resistance via physiology
// ============================================================

/datum/status_effect/preservation_ally_dr
	id = "preservation_ally_dr"
	duration = 10 SECONDS
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null

	/// Applied value (DEF% for path holders, resistance% for non-path)
	var/applied_value = 0
	/// Whether this was applied to a path holder
	var/is_path_holder = FALSE

/datum/status_effect/preservation_ally_dr/on_apply()
	. = ..()
	if(!.)
		return
	to_chat(owner, span_nicegreen("An ally's protection reduces damage you take!"))

/datum/status_effect/preservation_ally_dr/on_remove()
	RemoveReduction()
	to_chat(owner, span_notice("Ally damage reduction fades."))
	return ..()

/datum/status_effect/preservation_ally_dr/proc/UpdateReduction()
	RemoveReduction()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	var/datum/component/path_holder/holder = H.GetComponent(/datum/component/path_holder)
	if(holder?.active_path)
		// Path holder: boost their DEF stat by 15%
		is_path_holder = TRUE
		applied_value = 15
		holder.active_path.external_def_bonus += applied_value
		// Recalculate defense so the new DEF applies to damage resistance
		holder.active_path.ApplyDefense()
	else
		// Non-path carbon: apply damage_resistance via physiology
		is_path_holder = FALSE
		if(!H.physiology)
			return
		applied_value = 15
		var/keep_factor = (100 - applied_value) / 100
		H.physiology.damage_resistance = 100 - ((100 - H.physiology.damage_resistance) * keep_factor)

/datum/status_effect/preservation_ally_dr/proc/RemoveReduction()
	if(!applied_value)
		return
	if(!ishuman(owner))
		applied_value = 0
		return
	var/mob/living/carbon/human/H = owner
	if(is_path_holder)
		var/datum/component/path_holder/holder = H.GetComponent(/datum/component/path_holder)
		if(holder?.active_path)
			holder.active_path.external_def_bonus -= applied_value
			holder.active_path.ApplyDefense()
	else if(H.physiology)
		var/keep_factor = (100 - applied_value) / 100
		if(keep_factor > 0)
			H.physiology.damage_resistance = 100 - ((100 - H.physiology.damage_resistance) / keep_factor)
	applied_value = 0
	is_path_holder = FALSE

// ============================================================
// Trace Nodes (Skill Tree)
// ============================================================

/datum/path/preservation/InitNodes()
	var/datum/path_node/N

	// --- Core Ability Upgrades ---
	N = new /datum/path_node("core_basic", "Ice-Breaking Light", "Level up Basic ATK.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_BASIC
	N.level_increase = 1
	N.ahn_cost = 500
	N.connections = list("bonus_a6")
	nodes += N

	N = new /datum/path_node("core_burst", "Ever-Burning Amber", "Level up Skill.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_BURST
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("bonus_a4")
	nodes += N

	N = new /datum/path_node("core_ultimate", "War-Flaming Lance", "Level up Ultimate.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_ULTIMATE
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("core_passive", "bonus_a2")
	nodes += N

	N = new /datum/path_node("core_passive", "Magma Will & Shield", "Level up Passive.")
	N.node_type = PATH_NODE_ABILITY
	N.ability_target = PATH_ABILITY_PASSIVE
	N.level_increase = 1
	N.ahn_cost = 800
	N.connections = list("core_basic", "core_burst", "stat_bottom")
	nodes += N

	// --- Bottom stat (no gate) ---
	N = new /datum/path_node("stat_bottom", "DEF Boost", "DEF increases by 5%.")
	N.stat_bonuses = list("DEF" = 5)
	N.stat_percent = TRUE
	N.ahn_cost = 200
	N.tree_x = 2
	N.tree_y = 6
	nodes += N

	// --- Center branch (A2 gate) ---
	N = new /datum/path_node("bonus_a2", "The Strong Defend the Weak", "After Skill, allies take 15% less DMG for 10s.")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 2
	N.tree_x = 2
	N.tree_y = 2
	N.connections = list("stat_c1")
	nodes += N

	N = new /datum/path_node("stat_c1", "ATK Boost", "ATK increases by 4%.")
	N.stat_bonuses = list("ATK" = 4)
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

	N = new /datum/path_node("stat_c3", "HP Boost", "HP increases by 4%.")
	N.stat_bonuses = list("HP" = 4)
	N.stat_percent = TRUE
	N.ahn_cost = 300
	N.required_ascension = 3
	N.tree_x = 3
	N.tree_y = 0
	N.prerequisites = list("stat_c1")
	nodes += N

	// --- Right branch (A4 gate) ---
	N = new /datum/path_node("bonus_a4", "Unwavering Gallantry", "Enhanced Basic ATK restores 5% of Max HP.")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 4
	N.tree_x = 4
	N.tree_y = 3
	N.connections = list("stat_r1")
	nodes += N

	N = new /datum/path_node("stat_r1", "DEF Boost", "DEF increases by 7.5%.")
	N.stat_bonuses = list("DEF" = 7.5)
	N.stat_percent = TRUE
	N.ahn_cost = 500
	N.required_ascension = 4
	N.tree_x = 4
	N.tree_y = 2
	N.connections = list("stat_r2")
	N.prerequisites = list("bonus_a4")
	nodes += N

	N = new /datum/path_node("stat_r2", "ATK Boost", "ATK increases by 6%.")
	N.stat_bonuses = list("ATK" = 6)
	N.stat_percent = TRUE
	N.ahn_cost = 600
	N.required_ascension = 5
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

	// --- Left branch (A6 gate) ---
	N = new /datum/path_node("bonus_a6", "Action Beats Overthinking", "At turn start with a Shield, ATK +15% and +5 Energy.")
	N.node_type = PATH_NODE_PASSIVE
	N.ahn_cost = 1000
	N.required_ascension = 6
	N.tree_x = 0
	N.tree_y = 3
	N.connections = list("stat_l1")
	nodes += N

	N = new /datum/path_node("stat_l1", "HP Boost", "HP increases by 6%.")
	N.stat_bonuses = list("HP" = 6)
	N.stat_percent = TRUE
	N.ahn_cost = 500
	N.required_ascension = 6
	N.tree_x = 0
	N.tree_y = 2
	N.connections = list("stat_l2")
	N.prerequisites = list("bonus_a6")
	nodes += N

	N = new /datum/path_node("stat_l2", "DEF Boost", "DEF increases by 5%.")
	N.stat_bonuses = list("DEF" = 5)
	N.stat_percent = TRUE
	N.ahn_cost = 700
	N.required_ascension = 6
	N.tree_x = 0
	N.tree_y = 1
	N.connections = list("stat_l3")
	N.prerequisites = list("stat_l1")
	nodes += N

	N = new /datum/path_node("stat_l3", "DEF Boost", "DEF increases by 10%.")
	N.stat_bonuses = list("DEF" = 10)
	N.stat_percent = TRUE
	N.ahn_cost = 800
	N.required_level = 80
	N.tree_x = 0
	N.tree_y = 0
	N.prerequisites = list("stat_l1")
	nodes += N

// ============================================================
// Bonus Ability Effects
// ============================================================

/// Checks if a bonus ability node is unlocked
/datum/path/preservation/proc/HasBonus(node_id)
	return (node_id in unlocked_nodes)

/datum/path/preservation/GetStat(stat_name)
	var/base_val = ..()
	// Action Beats Overthinking (A6): +15% ATK when shielded at turn start
	if(stat_name == "ATK" && action_bo_atk_active)
		base_val *= 1.15
	return base_val

/datum/path/preservation/OnBonusAbilityUnlocked(node_id)
	switch(node_id)
		if("bonus_a2")
			// The Strong Defend the Weak: checked in Skill Activate
			return
		if("bonus_a4")
			// Unwavering Gallantry: checked in Basic OnHit
			return
		if("bonus_a6")
			// Action Beats Overthinking: checked in OnTurnReset
			return

/// Override OnTurnReset for A6 bonus and Magma Will display
/datum/path/preservation/OnTurnReset()
	// Action Beats Overthinking (A6): check if shielded at turn start
	action_bo_atk_active = FALSE
	if(HasBonus("bonus_a6") && owner)
		var/datum/status_effect/preservation_shield/S = owner.has_status_effect(/datum/status_effect/preservation_shield)
		if(S && S.shield_hp > 0)
			action_bo_atk_active = TRUE
			GainEnergy(5)
			if(owner)
				to_chat(owner, span_nicegreen("Action Beats Overthinking! ATK +15%, +5 Energy!"))
	..()

/// Override OnWeaponHit — no special behavior needed beyond parent
/datum/path/preservation/OnWeaponHit(mob/living/target, mob/living/user)
	..()
