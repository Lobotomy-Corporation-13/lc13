// ============================================================
// Seven Association — Coordinator Branch
// ============================================================
// Focused on team buffs, debuff application, and ally synergy.

// ============================================================
// T1a: Intel Briefing
// ============================================================
/// Attacking a target with Rupture buffs nearby allies with OLU.
/datum/component/association_skill/seven_intel_briefing
	skill_name = "Intel Briefing"
	skill_desc = "When attacking a target with Rupture, nearby allies gain 3 Offense Level Up."
	branch = "Coordinator"
	tier = 1
	choice = "a"
	/// Cooldown tracking
	var/next_use_time = 0

/datum/component/association_skill/seven_intel_briefing/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	if(world.time < next_use_time)
		return
	// Check target has Rupture
	var/datum/status_effect/stacking/rupture/R = target.has_status_effect(/datum/status_effect/stacking/rupture)
	if(!R)
		return
	next_use_time = world.time + 1 SECONDS
	INVOKE_ASYNC(src, PROC_REF(buff_nearby_allies))

/// Apply OLU to designated allies in range.
/datum/component/association_skill/seven_intel_briefing/proc/buff_nearby_allies()
	for(var/mob/living/L in range(5, get_turf(human_parent)))
		if(L == human_parent)
			continue
		if(!is_designated_ally(L))
			continue
		L.apply_lc_offense_level_up(3)

// ============================================================
// T1b: Weak Point Analysis
// ============================================================
/// Attacks apply DLD. At high DLD, allies get OLU.
/datum/component/association_skill/seven_weak_point_analysis
	skill_name = "Weak Point Analysis"
	skill_desc = "Attacks apply 3 Defense Level Down. If target has 10+, nearby allies gain 3 Offense Level Up."
	branch = "Coordinator"
	tier = 1
	choice = "b"
	/// Cooldown tracking
	var/next_use_time = 0

/datum/component/association_skill/seven_weak_point_analysis/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	if(world.time < next_use_time)
		return
	next_use_time = world.time + 1 SECONDS
	INVOKE_ASYNC(src, PROC_REF(apply_weak_point), target)

/// Apply DLD and check for ally buff trigger.
/datum/component/association_skill/seven_weak_point_analysis/proc/apply_weak_point(mob/living/target)
	target.apply_lc_defense_level_down(3)
	new /obj/effect/temp_visual/dir_setting/gray_edge/seven(get_turf(human_parent), human_parent.dir)
	// Check if target now has 10+ DLD
	var/datum/status_effect/stacking/defense_level_up/defense_level_down/D = target.has_status_effect(/datum/status_effect/stacking/defense_level_up/defense_level_down)
	if(D && D.stacks >= 10)
		for(var/mob/living/L in range(5, get_turf(human_parent)))
			if(L == human_parent || !is_designated_ally(L))
				continue
			L.apply_lc_offense_level_up(3)

// ============================================================
// T2a: Comprehensive Report
// ============================================================
/// High-Rupture targets trigger team Strength buff and OLD application.
/datum/component/association_skill/seven_comprehensive_report
	skill_name = "Comprehensive Report"
	skill_desc = "Attacking a target with 15+ active Rupture grants allies 2 Strength and applies 4 OLD to target."
	branch = "Coordinator"
	tier = 2
	choice = "a"
	/// Per-target cooldown tracking (ref -> world.time)
	var/list/target_cooldowns = list()

/datum/component/association_skill/seven_comprehensive_report/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	var/datum/status_effect/stacking/rupture/R = target.has_status_effect(/datum/status_effect/stacking/rupture)
	if(!R || R.stacks < 15 || !R.activated)
		return
	// Per-target 10s cooldown
	var/target_ref = ref(target)
	if(target_cooldowns[target_ref] && world.time < target_cooldowns[target_ref])
		return
	target_cooldowns[target_ref] = world.time + 10 SECONDS
	INVOKE_ASYNC(src, PROC_REF(apply_report_effects), target)

/// Apply Strength to allies and OLD to target.
/datum/component/association_skill/seven_comprehensive_report/proc/apply_report_effects(mob/living/target)
	for(var/mob/living/L in range(5, get_turf(human_parent)))
		if(L == human_parent || !is_designated_ally(L))
			continue
		L.apply_lc_strength(2)
	target.apply_lc_offense_level_down(4)
	new /obj/effect/temp_visual/small_smoke/halfsecond(get_turf(target))

// ============================================================
// T2b: Disinformation
// ============================================================
/// Attacks apply OLD and Feeble.
/datum/component/association_skill/seven_disinformation
	skill_name = "Disinformation"
	skill_desc = "Attacks apply 2 Offense Level Down and 2 Feeble to the target."
	branch = "Coordinator"
	tier = 2
	choice = "b"
	/// Cooldown tracking
	var/next_use_time = 0

/datum/component/association_skill/seven_disinformation/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	if(world.time < next_use_time)
		return
	next_use_time = world.time + 1.5 SECONDS
	INVOKE_ASYNC(src, PROC_REF(apply_disinformation), target)

/// Apply OLD and Feeble to target.
/datum/component/association_skill/seven_disinformation/proc/apply_disinformation(mob/living/target)
	target.apply_lc_offense_level_down(2)
	target.apply_lc_feeble(2)

// ============================================================
// T3a: Full Exposure (Powerful Attack)
// ============================================================
/// Grants a powerful AoE debuff + combo attack action.
/datum/component/association_skill/seven_full_exposure
	skill_name = "Full Exposure"
	skill_desc = "Grants a powerful AoE debuff attack that scales with ally count (costs Adrenaline)."
	branch = "Coordinator"
	tier = 3
	choice = "a"
	/// Reference to the granted action
	var/datum/action/cooldown/seven_full_exposure_action/combo_action

/datum/component/association_skill/seven_full_exposure/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	combo_action = new()
	combo_action.Grant(human_parent)

/datum/component/association_skill/seven_full_exposure/Destroy()
	if(combo_action && human_parent)
		combo_action.Remove(human_parent)
	combo_action = null
	return ..()

/// Full Exposure action — adrenaline-powered powerful attack.
/datum/action/cooldown/seven_full_exposure_action
	name = "Full Exposure"
	desc = "AoE debuff opener scaling with ally count, then a 3-hit combo that applies Rupture. Final hit force-triggers all Rupture. Costs 100 Adrenaline."
	icon_icon = 'icons/hud/screen_assoc_trees.dmi'
	button_icon_state = "seven_t3"
	cooldown_time = 0

/datum/action/cooldown/seven_full_exposure_action/Trigger()
	. = ..()
	if(!.)
		return FALSE
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/user = owner
	// Check skill usability
	var/datum/component/association_skill/seven_full_exposure/skill = user.GetComponent(/datum/component/association_skill/seven_full_exposure)
	if(!skill || !skill.can_use_skill())
		to_chat(user, span_warning("You cannot use this skill right now."))
		return FALSE
	// Find a hostile target nearby
	var/mob/living/combo_target = null
	var/closest_dist = INFINITY
	for(var/mob/living/L in view(4, get_turf(user)))
		if(L == user || skill.is_designated_ally(L))
			continue
		if(L.stat == DEAD)
			continue
		var/d = get_dist(user, L)
		if(d < closest_dist)
			closest_dist = d
			combo_target = L
	if(!combo_target)
		to_chat(user, span_warning("No hostile targets nearby."))
		return FALSE
	// Check adrenaline
	var/datum/component/association_exp/exp = user.GetComponent(/datum/component/association_exp)
	if(!exp || !exp.has_enough_adrenaline())
		to_chat(user, span_warning("Not enough adrenaline! ([exp ? exp.adrenaline : 0]/[exp ? exp.max_adrenaline : 100])"))
		return FALSE
	exp.consume_adrenaline()
	INVOKE_ASYNC(src, PROC_REF(ExecuteCombo), combo_target, user, skill)
	return TRUE

/datum/action/cooldown/seven_full_exposure_action/proc/ExecuteCombo(mob/living/target, mob/living/carbon/human/user, datum/component/association_skill/seven_full_exposure/skill)
	// Phase 1: Count allies and AoE debuff
	var/ally_count = 0
	for(var/mob/living/L in range(6, get_turf(user)))
		if(L == user)
			continue
		if(skill.is_designated_ally(L))
			ally_count++
	ally_count = min(ally_count, 3)
	var/dld_old_amount = 3 + 3 * ally_count

	// AoE debuff (4-tile radius)
	playsound(user, 'sound/weapons/thudswoosh.ogg', 80, TRUE, 8)
	new /obj/effect/temp_visual/smash_effect(get_turf(user))
	for(var/mob/living/L in range(4, get_turf(user)))
		if(L == user || skill.is_designated_ally(L))
			continue
		if(L.stat == DEAD)
			continue
		L.apply_lc_fragile(2)
		L.apply_lc_defense_level_down(dld_old_amount)
		L.apply_lc_offense_level_down(dld_old_amount)
		L.apply_lc_feeble(2)

	if(QDELETED(target) || target.stat == DEAD)
		return

	sleep(0.5 SECONDS)
	if(QDELETED(target) || QDELETED(user))
		return

	// Phase 2: Combo — dash TO target, immobilize
	SevenComboDash(user, target, FALSE)

	// Calculate Rupture per hit
	var/total_ally_olu = 0
	for(var/mob/living/A in range(6, get_turf(user)))
		if(A == user || !skill.is_designated_ally(A))
			continue
		var/datum/status_effect/stacking/offense_level_up/O = A.has_status_effect(/datum/status_effect/stacking/offense_level_up)
		if(O)
			total_ally_olu += O.stacks
	var/datum/status_effect/stacking/offense_level_up/offense_level_down/old_effect = target.has_status_effect(/datum/status_effect/stacking/offense_level_up/offense_level_down)
	var/target_old_stacks = old_effect ? old_effect.stacks : 0
	var/rupture_per_hit = 3 + round((total_ally_olu + target_old_stacks) / 5)

	// DPS calculation
	var/obj/item/weapon = user.get_active_held_item()
	var/dps = weapon ? (weapon.force * 1.25 / max(weapon.attack_speed, 0.1)) : 30
	var/hit_damage = dps / 3

	var/combo_duration = 2.5 SECONDS
	user.Immobilize(combo_duration)
	user.changeNext_move(combo_duration)
	if(isanimal(target))
		var/mob/living/simple_animal/hostile/H = target
		if(istype(H))
			H.toggle_ai(AI_OFF)
			addtimer(CALLBACK(H, TYPE_PROC_REF(/mob/living/simple_animal/hostile, toggle_ai), AI_ON), combo_duration)
	else if(ishuman(target))
		target.Immobilize(combo_duration)

	// Cutscene duel — block outside damage during combo
	target.AddComponent(/datum/component/cutscene_duel, user)

	// Hit 1: Opening strike + rupture
	sleep(0.3 SECONDS)
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
		return
	user.do_attack_animation(target)
	playsound(target, 'sound/weapons/rapierhit.ogg', 60, TRUE, 6)
	target.deal_damage(hit_damage, BLACK_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
	target.apply_lc_rupture(rupture_per_hit)
	new /obj/effect/temp_visual/dir_setting/gray_edge/seven(get_turf(user), user.dir)

	// Hit 2: Reposition to flank (perpendicular), flanking strike
	sleep(0.5 SECONDS)
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
		return
	var/perp_dir = turn(get_dir(target, user), 90)
	var/turf/flank = get_step(target, perp_dir)
	if(!flank || flank.is_blocked_turf(TRUE))
		flank = get_step(target, turn(perp_dir, 180))
	if(!flank || flank.is_blocked_turf(TRUE))
		flank = get_turf(target)
	var/turf/origin = get_turf(user)
	user.forceMove(flank)
	user.face_atom(target)
	// Smooth pixel slide from old position to flank
	var/dx = (origin.x - flank.x) * 32
	var/dy = (origin.y - flank.y) * 32
	user.pixel_x = user.base_pixel_x + dx
	user.pixel_y = user.base_pixel_y + dy
	animate(user, 0.2 SECONDS, pixel_x = user.base_pixel_x, pixel_y = user.base_pixel_y, easing = QUAD_EASING)
	new /obj/effect/temp_visual/small_smoke/halfsecond(origin)
	sleep(0.2 SECONDS)
	if(QDELETED(target) || QDELETED(user))
		return
	user.do_attack_animation(target)
	playsound(target, 'sound/weapons/rapierhit.ogg', 60, TRUE, 6)
	target.deal_damage(hit_damage, BLACK_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
	target.apply_lc_rupture(rupture_per_hit)
	new /obj/effect/temp_visual/dir_setting/gray_edge/seven(get_turf(user), user.dir)

	// Hit 3 (FINISHER): Dash THROUGH target, force-trigger rupture
	sleep(0.5 SECONDS)
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
		return
	SevenComboDash(user, target, TRUE)
	sleep(0.2 SECONDS)
	if(QDELETED(target) || QDELETED(user))
		return
	user.do_attack_animation(target)
	playsound(target, 'sound/weapons/rapierhit.ogg', 80, TRUE, 8)
	target.deal_damage(hit_damage, BLACK_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
	target.apply_lc_rupture(rupture_per_hit)
	new /obj/effect/temp_visual/dir_setting/gray_edge/seven/passthrough(get_turf(target), user.dir)
	shake_camera(target, 3, 3)
	var/datum/status_effect/stacking/rupture/R = target.has_status_effect(/datum/status_effect/stacking/rupture)
	if(R && R.stacks > 0)
		R.trigger_rupture()
	// Clean up cutscene duel
	qdel(target.GetComponent(/datum/component/cutscene_duel))
	if(!QDELETED(user))
		user.say(pick("Nowhere left to hide.", "All positions compromised.", "Full exposure confirmed."))

// ============================================================
// T3b: Undermining Presence
// ============================================================
/// Strip positive buffs from targets. When a buff is stripped, heal visible allies' SP.
/datum/component/association_skill/seven_undermining_presence
	skill_name = "Undermining Presence"
	skill_desc = "Attacks strip 2 stacks of each positive buff from the target. When a buff is stripped, heals visible allies for 2% of their max SP."
	branch = "Coordinator"
	tier = 3
	choice = "b"
	/// Cooldown for the ally SP heal
	var/next_heal_time = 0

/datum/component/association_skill/seven_undermining_presence/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	INVOKE_ASYNC(src, PROC_REF(strip_and_heal), target)

/// Strip positive buff stacks from the target. If any were stripped, heal visible allies' SP.
/datum/component/association_skill/seven_undermining_presence/proc/strip_and_heal(mob/living/target)
	var/stripped_any = FALSE
	// Defense Level Up (not DLD)
	var/datum/status_effect/stacking/defense_level_up/dlu = target.has_status_effect(/datum/status_effect/stacking/defense_level_up)
	if(dlu && !istype(dlu, /datum/status_effect/stacking/defense_level_up/defense_level_down))
		dlu.add_stacks(-2)
		if(dlu.stacks <= 0)
			qdel(dlu)
		stripped_any = TRUE
	// Offense Level Up (not OLD)
	var/datum/status_effect/stacking/offense_level_up/olu = target.has_status_effect(/datum/status_effect/stacking/offense_level_up)
	if(olu && !istype(olu, /datum/status_effect/stacking/offense_level_up/offense_level_down))
		olu.add_stacks(-2)
		if(olu.stacks <= 0)
			qdel(olu)
		stripped_any = TRUE
	// Strength (not Feeble)
	var/datum/status_effect/stacking/damage_up/str = target.has_status_effect(/datum/status_effect/stacking/damage_up)
	if(str && !istype(str, /datum/status_effect/stacking/damage_up/down))
		str.add_stacks(-2)
		if(str.stacks <= 0)
			qdel(str)
		stripped_any = TRUE
	// Protection (not Fragile)
	var/datum/status_effect/stacking/protection/prot = target.has_status_effect(/datum/status_effect/stacking/protection)
	if(prot && !istype(prot, /datum/status_effect/stacking/protection/fragile))
		prot.add_stacks(-2)
		if(prot.stacks <= 0)
			qdel(prot)
		stripped_any = TRUE
	// If any buff was stripped and heal is off cooldown, heal visible allies' SP
	if(!stripped_any)
		return
	if(world.time < next_heal_time)
		return
	next_heal_time = world.time + 2 SECONDS
	for(var/mob/living/carbon/human/ally in view(7, get_turf(human_parent)))
		if(ally == human_parent)
			continue
		if(!is_designated_ally(ally))
			continue
		var/heal_amount = ally.maxSanity * 0.02
		ally.adjustSanityLoss(-heal_amount)
