// ============================================================
// Seven Association — Operative Branch
// ============================================================
// Focused on Rupture stacking, conversion, and burst damage.

// ============================================================
// T1a: Shadow Step
// ============================================================
/// Attacks convert the target's OLD and DLD stacks into Rupture.
/datum/component/association_skill/seven_shadow_step
	skill_name = "Shadow Step"
	skill_desc = "Attacks convert the target's Offense Level Down and Defense Level Down stacks into Rupture. Applies up to 8 Rupture per hit."
	branch = "Operative"
	tier = 1
	choice = "a"

/datum/component/association_skill/seven_shadow_step/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	// Count OLD + DLD stacks on target
	var/old_stacks = 0
	var/dld_stacks = 0
	var/datum/status_effect/stacking/offense_level_up/offense_level_down/old_effect = target.has_status_effect(/datum/status_effect/stacking/offense_level_up/offense_level_down)
	if(old_effect)
		old_stacks = old_effect.stacks
	var/datum/status_effect/stacking/defense_level_up/defense_level_down/dld_effect = target.has_status_effect(/datum/status_effect/stacking/defense_level_up/defense_level_down)
	if(dld_effect)
		dld_stacks = dld_effect.stacks
	var/total = old_stacks + dld_stacks
	if(total <= 0)
		return
	var/rupture_amount = min(8, round(total / 2))
	if(rupture_amount <= 0)
		return
	INVOKE_ASYNC(target, TYPE_PROC_REF(/mob/living, apply_lc_rupture), rupture_amount)
	new /obj/effect/temp_visual/dir_setting/gray_edge/seven(get_turf(user), user.dir)

// ============================================================
// T1b: Quick Assessment
// ============================================================
/// Diminishing Rupture on new targets: 5, 3, 1, 0. Switching targets resets.
/datum/component/association_skill/seven_quick_assessment
	skill_name = "Quick Assessment"
	skill_desc = "First hit on a new target applies 5 Rupture, second hit 3, third hit 1, then 0. Switching targets resets."
	branch = "Operative"
	tier = 1
	choice = "b"
	/// Current target being tracked
	var/mob/living/current_target
	/// Number of consecutive hits on current target
	var/hit_count = 0

/datum/component/association_skill/seven_quick_assessment/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	// Reset counter if target changed
	if(target != current_target)
		current_target = target
		hit_count = 0
	var/rupture_amount = 0
	switch(hit_count)
		if(0)
			rupture_amount = 5
		if(1)
			rupture_amount = 3
		if(2)
			rupture_amount = 1
	hit_count++
	if(rupture_amount > 0)
		INVOKE_ASYNC(target, TYPE_PROC_REF(/mob/living, apply_lc_rupture), rupture_amount)
		new /obj/effect/temp_visual/dir_setting/gray_edge/seven(get_turf(user), user.dir)

// ============================================================
// T2a: Rupture Cascade
// ============================================================
/// When your attack triggers a Rupture burst, spread Rupture to nearby enemies.
/datum/component/association_skill/seven_rupture_cascade
	skill_name = "Rupture Cascade"
	skill_desc = "When your attack triggers a Rupture burst, applies 7 Rupture to all nearby enemies excluding the original target."
	branch = "Operative"
	tier = 2
	choice = "a"
	/// Cooldown tracking
	var/next_use_time = 0
	/// Mobs we have rupture signals registered on
	var/list/watched_mobs = list()

/datum/component/association_skill/seven_rupture_cascade/Destroy()
	for(var/mob/living/L in watched_mobs)
		UnregisterSignal(L, COMSIG_RUPTURE_TRIGGERED)
	watched_mobs.Cut()
	return ..()

/datum/component/association_skill/seven_rupture_cascade/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	// Register rupture signal on target if not already watching
	if(!(target in watched_mobs))
		RegisterSignal(target, COMSIG_RUPTURE_TRIGGERED, PROC_REF(on_rupture_trigger))
		watched_mobs += target

/// When a watched target's Rupture triggers, spread Rupture to nearby enemies.
/datum/component/association_skill/seven_rupture_cascade/proc/on_rupture_trigger(datum/source, stacks_before)
	SIGNAL_HANDLER
	if(world.time < next_use_time)
		return
	next_use_time = world.time + 1 SECONDS
	var/mob/living/target = source
	INVOKE_ASYNC(src, PROC_REF(do_cascade), target)

/// Apply 7 Rupture to enemies near the target, excluding the original.
/datum/component/association_skill/seven_rupture_cascade/proc/do_cascade(mob/living/target)
	for(var/mob/living/L in range(3, get_turf(target)))
		if(L == target || L == human_parent || is_designated_ally(L))
			continue
		L.apply_lc_rupture(7)

// ============================================================
// T2b: Pressure Points
// ============================================================
/// Attacks apply Rupture equal to the number of unique debuff types on the target.
/datum/component/association_skill/seven_pressure_points
	skill_name = "Pressure Points"
	skill_desc = "Attacks apply Rupture equal to the number of unique debuff types on the target. Maximum 4 Rupture per hit."
	branch = "Operative"
	tier = 2
	choice = "b"

/datum/component/association_skill/seven_pressure_points/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	var/debuff_count = 0
	if(target.has_status_effect(/datum/status_effect/stacking/protection/fragile))
		debuff_count++
	if(target.has_status_effect(/datum/status_effect/stacking/damage_up/down))
		debuff_count++
	if(target.has_status_effect(/datum/status_effect/stacking/defense_level_up/defense_level_down))
		debuff_count++
	if(target.has_status_effect(/datum/status_effect/stacking/offense_level_up/offense_level_down))
		debuff_count++
	if(debuff_count <= 0)
		return
	INVOKE_ASYNC(target, TYPE_PROC_REF(/mob/living, apply_lc_rupture), debuff_count)

// ============================================================
// T3a: Surgical Strike (Powerful Attack)
// ============================================================
/// Grants a powerful attack action. Vanish + teleport + 5-hit combo.
/datum/component/association_skill/seven_surgical_strike
	skill_name = "Surgical Strike"
	skill_desc = "Grants a powerful attack action (costs Adrenaline). Vanish, teleport behind the target, and deliver a devastating combo."
	branch = "Operative"
	tier = 3
	choice = "a"
	/// Reference to the granted action
	var/datum/action/cooldown/seven_surgical_strike_action/combo_action

/datum/component/association_skill/seven_surgical_strike/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	combo_action = new()
	combo_action.Grant(human_parent)

/datum/component/association_skill/seven_surgical_strike/Destroy()
	if(combo_action && human_parent)
		combo_action.Remove(human_parent)
	combo_action = null
	return ..()

/// Surgical Strike action — adrenaline-powered powerful attack.
/datum/action/cooldown/seven_surgical_strike_action
	name = "Surgical Strike"
	desc = "Vanish for 2 seconds, then teleport behind the target for a 5-hit combo. Damage scales with debuffs. Costs 100 Adrenaline."
	icon_icon = 'icons/hud/screen_assoc_trees.dmi'
	button_icon_state = "seven_t3"
	cooldown_time = 0

/datum/action/cooldown/seven_surgical_strike_action/Trigger()
	. = ..()
	if(!.)
		return FALSE
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/user = owner
	// Need a target - find closest hostile in view
	var/mob/living/target = null
	var/closest_dist = INFINITY
	var/datum/component/association_skill/seven_surgical_strike/skill = user.GetComponent(/datum/component/association_skill/seven_surgical_strike)
	if(!skill || !skill.can_use_skill())
		to_chat(user, span_warning("You cannot use this skill right now."))
		return FALSE
	for(var/mob/living/L in view(7, get_turf(user)))
		if(L == user || skill.is_designated_ally(L))
			continue
		if(L.stat == DEAD)
			continue
		var/d = get_dist(user, L)
		if(d < closest_dist)
			closest_dist = d
			target = L
	if(!target)
		to_chat(user, span_warning("No hostile targets nearby."))
		return FALSE
	// Check adrenaline
	var/datum/component/association_exp/exp = user.GetComponent(/datum/component/association_exp)
	if(!exp || !exp.has_enough_adrenaline())
		to_chat(user, span_warning("Not enough adrenaline! ([exp ? exp.adrenaline : 0]/[exp ? exp.max_adrenaline : 100])"))
		return FALSE
	exp.consume_adrenaline()
	INVOKE_ASYNC(src, PROC_REF(ExecuteCombo), target, user, skill)
	return TRUE

/datum/action/cooldown/seven_surgical_strike_action/proc/ExecuteCombo(mob/living/target, mob/living/carbon/human/user, datum/component/association_skill/seven_surgical_strike/skill)
	// Phase 1: Vanish — smooth fade out over 0.5s, then invisible for remainder
	animate(user, 0.5 SECONDS, alpha = 0, easing = QUAD_EASING)
	user.Immobilize(2 SECONDS)
	user.changeNext_move(2 SECONDS)
	playsound(user, 'sound/weapons/thudswoosh.ogg', 40, TRUE, 4)
	sleep(2 SECONDS)
	if(QDELETED(user) || QDELETED(target))
		if(!QDELETED(user))
			animate(user, 0, alpha = 255)
		return

	// Phase 2: Reappear behind target with smooth fade in
	var/turf/behind = get_step(target, REVERSE_DIR(target.dir))
	if(!behind || behind.is_blocked_turf(TRUE))
		behind = get_turf(target)
	var/turf/vanish_origin = get_turf(user)
	user.forceMove(behind)
	user.face_atom(target)
	new /obj/effect/temp_visual/small_smoke/halfsecond(vanish_origin)
	animate(user, 0.2 SECONDS, alpha = 255, easing = QUAD_EASING)
	playsound(user, 'sound/weapons/thudswoosh.ogg', 60, TRUE, 6)

	// Count debuff types on target for damage scaling
	var/debuff_count = 0
	if(target.has_status_effect(/datum/status_effect/stacking/protection/fragile))
		debuff_count++
	if(target.has_status_effect(/datum/status_effect/stacking/damage_up/down))
		debuff_count++
	if(target.has_status_effect(/datum/status_effect/stacking/defense_level_up/defense_level_down))
		debuff_count++
	if(target.has_status_effect(/datum/status_effect/stacking/offense_level_up/offense_level_down))
		debuff_count++
	if(target.has_status_effect(/datum/status_effect/stacking/rupture))
		debuff_count++
	var/damage_multiplier = 1 + debuff_count * 0.15

	// DPS calculation
	var/obj/item/weapon = user.get_active_held_item()
	var/dps = weapon ? (weapon.force * 1.25 / max(weapon.attack_speed, 0.1)) : 30
	var/hit_damage = dps * damage_multiplier / 5

	// Immobilize both for combo
	var/combo_duration = 3 SECONDS
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

	// Hit 1: First strike from behind + Fragile
	sleep(0.2 SECONDS)
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
		return
	user.do_attack_animation(target)
	playsound(target, 'sound/weapons/rapierhit.ogg', 60, TRUE, 6)
	target.deal_damage(hit_damage, BLACK_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
	target.apply_lc_fragile(3)
	target.apply_lc_rupture(2)
	new /obj/effect/temp_visual/dir_setting/gray_edge/seven(get_turf(user), user.dir)

	// Hit 2: Dash THROUGH target
	sleep(0.4 SECONDS)
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
		return
	SevenComboDash(user, target, TRUE)
	sleep(0.1 SECONDS)
	if(QDELETED(target) || QDELETED(user))
		return
	user.do_attack_animation(target)
	playsound(target, 'sound/weapons/rapierhit.ogg', 60, TRUE, 6)
	target.deal_damage(hit_damage, BLACK_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
	target.apply_lc_rupture(2)
	new /obj/effect/temp_visual/dir_setting/gray_edge/seven/passthrough(get_turf(target), user.dir)

	// Hit 3: Dash THROUGH back
	sleep(0.4 SECONDS)
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
		return
	SevenComboDash(user, target, TRUE)
	sleep(0.1 SECONDS)
	if(QDELETED(target) || QDELETED(user))
		return
	user.do_attack_animation(target)
	playsound(target, 'sound/weapons/rapierhit.ogg', 60, TRUE, 6)
	target.deal_damage(hit_damage, BLACK_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
	target.apply_lc_rupture(2)
	new /obj/effect/temp_visual/dir_setting/gray_edge/seven/passthrough(get_turf(target), user.dir)

	// Hit 4: Dash TO target
	sleep(0.4 SECONDS)
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
		return
	SevenComboDash(user, target, FALSE)
	sleep(0.1 SECONDS)
	if(QDELETED(target) || QDELETED(user))
		return
	user.do_attack_animation(target)
	playsound(target, 'sound/weapons/rapierhit.ogg', 60, TRUE, 6)
	target.deal_damage(hit_damage, BLACK_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
	target.apply_lc_rupture(2)
	new /obj/effect/temp_visual/dir_setting/gray_edge/seven(get_turf(user), user.dir)

	// Hit 5 (FINISHER): Dash THROUGH, double damage + bonus BLACK + knockback
	sleep(0.4 SECONDS)
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
		return
	SevenComboDash(user, target, TRUE)
	sleep(0.2 SECONDS)
	if(QDELETED(target) || QDELETED(user))
		return
	user.do_attack_animation(target)
	playsound(target, 'sound/weapons/rapierhit.ogg', 80, TRUE, 8)
	target.deal_damage(hit_damage * 2, BLACK_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
	target.apply_lc_rupture(2)
	var/datum/status_effect/stacking/rupture/R = target.has_status_effect(/datum/status_effect/stacking/rupture)
	if(R && R.stacks > 0)
		target.deal_damage(R.stacks, BLACK_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_SPECIAL)
	new /obj/effect/temp_visual/dir_setting/gray_edge/seven/passthrough(get_turf(target), user.dir)
	shake_camera(target, 3, 3)
	// Clean up cutscene duel
	qdel(target.GetComponent(/datum/component/cutscene_duel))
	if(!QDELETED(user))
		user.say(pick("Target neutralized.", "Clean cut.", "Surgical precision."))

// ============================================================
// T3b: Detonation Order
// ============================================================
/// Attacks apply Rupture to targets below the threshold.
/datum/component/association_skill/seven_detonation_order
	skill_name = "Detonation Order"
	skill_desc = "Attacks apply 4 Rupture to targets with fewer than 20 Rupture stacks."
	branch = "Operative"
	tier = 3
	choice = "b"

/datum/component/association_skill/seven_detonation_order/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	// Check current Rupture stacks
	var/datum/status_effect/stacking/rupture/R = target.has_status_effect(/datum/status_effect/stacking/rupture)
	var/current_stacks = R ? R.stacks : 0
	if(current_stacks >= 20)
		return
	INVOKE_ASYNC(target, TYPE_PROC_REF(/mob/living, apply_lc_rupture), 4)
