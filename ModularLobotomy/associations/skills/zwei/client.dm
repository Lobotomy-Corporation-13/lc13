// ============================================================
// Zwei Association — Client Protection Branch
// ============================================================
// Bodyguard skills focused on protecting a single designated ward.
// All T1 skills grant the Mark for Protection action.

/// Movespeed modifier for Bodyguard's Instinct — ~30% speed boost.
/datum/movespeed_modifier/zwei_bodyguard_sprint
	id = "zwei_bodyguard_sprint"
	multiplicative_slowdown = -1.0

// ============================================================
// T1a: Designated Ward
// ============================================================
/// Grants Mark for Protection. When ward takes damage within 7 tiles, ward gets 2 DLU and user gets 3. 1s CD.
/datum/component/association_skill/zwei_designated_ward
	skill_name = "Designated Ward"
	skill_desc = "Grants Mark for Protection. When your ward takes damage within 7 tiles, they gain 2 Defense Level Up and you gain 3. 1 second cooldown."
	branch = "Client Protection"
	tier = 1
	choice = "a"
	/// Reference to the ward action we granted
	var/datum/action/cooldown/zwei_mark_for_protection/ward_action
	/// Currently tracked ward
	var/mob/living/current_ward
	/// Internal cooldown tracker
	var/last_trigger = 0

/datum/component/association_skill/zwei_designated_ward/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	ward_action = get_zwei_ward_action(human_parent)
	if(!ward_action)
		ward_action = new()
		ward_action.Grant(human_parent)
	// Register for ward changes
	ward_action.ward_change_callbacks += CALLBACK(src, PROC_REF(on_ward_changed))
	// Sync with current ward if already set
	on_ward_changed(ward_action.ward)

/datum/component/association_skill/zwei_designated_ward/Destroy()
	// Unregister from ward
	if(current_ward)
		UnregisterSignal(current_ward, COMSIG_MOB_AFTER_APPLY_DAMGE)
		current_ward = null
	// Remove callback
	if(ward_action)
		ward_action.ward_change_callbacks -= CALLBACK(src, PROC_REF(on_ward_changed))
		// Only remove ward action if no other Client T1 skill exists
		if(human_parent)
			var/datum/component/association_skill/zwei_threatening_presence/other = human_parent.GetComponent(/datum/component/association_skill/zwei_threatening_presence)
			if(!other)
				ward_action.Remove(human_parent)
	ward_action = null
	return ..()

/// Called when the ward changes via the mark action.
/datum/component/association_skill/zwei_designated_ward/proc/on_ward_changed(mob/living/new_ward)
	// Unregister from old ward
	if(current_ward)
		UnregisterSignal(current_ward, COMSIG_MOB_AFTER_APPLY_DAMGE)
	current_ward = new_ward
	// Register on new ward
	if(current_ward)
		RegisterSignal(current_ward, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(on_ward_damaged))

/// Signal handler: ward took damage.
/datum/component/association_skill/zwei_designated_ward/proc/on_ward_damaged(datum/source, damage, damagetype, def_zone, wound_bonus, bare_wound_bonus, sharpness, attacker)
	SIGNAL_HANDLER
	if(!can_use_skill())
		return
	if(isliving(attacker) && is_association_member(attacker))
		return
	if(world.time < last_trigger + 1 SECONDS)
		return
	if(!current_ward || QDELETED(current_ward))
		return
	// Must be within 7 tiles
	if(get_dist(get_turf(human_parent), get_turf(current_ward)) > 7)
		return
	last_trigger = world.time
	INVOKE_ASYNC(src, PROC_REF(apply_ward_defense))

/// Apply DLU to both ward and self.
/datum/component/association_skill/zwei_designated_ward/proc/apply_ward_defense()
	if(current_ward && !QDELETED(current_ward))
		current_ward.apply_lc_defense_level_up(2)
	if(human_parent && !QDELETED(human_parent))
		human_parent.apply_lc_defense_level_up(3)

// ============================================================
// T1b: Threatening Presence
// ============================================================
/// Grants Mark for Protection. Ward takes 15% less damage while user is within 7 tiles.
/// When ward takes damage, user gets 2 DLU. 1s CD.
/datum/component/association_skill/zwei_threatening_presence
	skill_name = "Threatening Presence"
	skill_desc = "Grants Mark for Protection. Your ward takes 15% less damage while you are within 7 tiles. When your ward takes damage, you gain 2 Defense Level Up. 1 second cooldown."
	branch = "Client Protection"
	tier = 1
	choice = "b"
	/// Reference to the ward action we granted
	var/datum/action/cooldown/zwei_mark_for_protection/ward_action
	/// Currently tracked ward
	var/mob/living/current_ward
	/// Internal cooldown tracker for DLU gain
	var/last_trigger = 0
	/// Whether the damage reduction physiology mod is currently active
	var/mod_active = FALSE
	/// The physiology mod value (for clean undo)
	var/physiology_mod = 0.85

/datum/component/association_skill/zwei_threatening_presence/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	ward_action = get_zwei_ward_action(human_parent)
	if(!ward_action)
		ward_action = new()
		ward_action.Grant(human_parent)
	// Register for ward changes
	ward_action.ward_change_callbacks += CALLBACK(src, PROC_REF(on_ward_changed))
	// Start processing for proximity check
	START_PROCESSING(SSobj, src)
	// Sync with current ward if already set
	on_ward_changed(ward_action.ward)

/datum/component/association_skill/zwei_threatening_presence/Destroy()
	STOP_PROCESSING(SSobj, src)
	// Clean up physiology mod
	remove_mod()
	// Unregister from ward
	if(current_ward)
		UnregisterSignal(current_ward, COMSIG_MOB_AFTER_APPLY_DAMGE)
		current_ward = null
	// Remove callback
	if(ward_action)
		ward_action.ward_change_callbacks -= CALLBACK(src, PROC_REF(on_ward_changed))
		// Only remove ward action if no other Client T1 skill exists
		if(human_parent)
			var/datum/component/association_skill/zwei_designated_ward/other = human_parent.GetComponent(/datum/component/association_skill/zwei_designated_ward)
			if(!other)
				ward_action.Remove(human_parent)
	ward_action = null
	return ..()

/// Called when the ward changes via the mark action.
/datum/component/association_skill/zwei_threatening_presence/proc/on_ward_changed(mob/living/new_ward)
	// Clean up old ward
	remove_mod()
	if(current_ward)
		UnregisterSignal(current_ward, COMSIG_MOB_AFTER_APPLY_DAMGE)
	current_ward = new_ward
	// Register on new ward
	if(current_ward)
		RegisterSignal(current_ward, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(on_ward_damaged))

/// Process every tick to check proximity and toggle physiology mod.
/datum/component/association_skill/zwei_threatening_presence/process(seconds_per_tick)
	if(!current_ward || QDELETED(current_ward) || !human_parent || QDELETED(human_parent))
		if(mod_active)
			remove_mod()
		return
	if(!can_use_skill())
		if(mod_active)
			remove_mod()
		return
	var/in_range = get_dist(get_turf(human_parent), get_turf(current_ward)) <= 7
	if(in_range && !mod_active)
		apply_mod()
	else if(!in_range && mod_active)
		remove_mod()

/// Apply the 15% damage reduction physiology mod to the ward.
/datum/component/association_skill/zwei_threatening_presence/proc/apply_mod()
	if(mod_active || !current_ward || QDELETED(current_ward))
		return
	if(!ishuman(current_ward))
		return
	var/mob/living/carbon/human/H = current_ward
	H.physiology.red_mod *= physiology_mod
	H.physiology.white_mod *= physiology_mod
	H.physiology.black_mod *= physiology_mod
	H.physiology.pale_mod *= physiology_mod
	mod_active = TRUE

/// Remove the physiology mod from the ward.
/datum/component/association_skill/zwei_threatening_presence/proc/remove_mod()
	if(!mod_active || !current_ward || QDELETED(current_ward))
		mod_active = FALSE
		return
	if(!ishuman(current_ward))
		mod_active = FALSE
		return
	var/mob/living/carbon/human/H = current_ward
	H.physiology.red_mod /= physiology_mod
	H.physiology.white_mod /= physiology_mod
	H.physiology.black_mod /= physiology_mod
	H.physiology.pale_mod /= physiology_mod
	mod_active = FALSE

/// Signal handler: ward took damage.
/datum/component/association_skill/zwei_threatening_presence/proc/on_ward_damaged(datum/source, damage, damagetype, def_zone, wound_bonus, bare_wound_bonus, sharpness, attacker)
	SIGNAL_HANDLER
	if(!can_use_skill())
		return
	if(isliving(attacker) && is_association_member(attacker))
		return
	if(world.time < last_trigger + 1 SECONDS)
		return
	last_trigger = world.time
	INVOKE_ASYNC(human_parent, TYPE_PROC_REF(/mob/living, apply_lc_defense_level_up), 2)

// ============================================================
// T2a: Bodyguard's Instinct
// ============================================================
/// When ward takes damage, gain +30% speed for 2s.
/datum/component/association_skill/zwei_bodyguards_instinct
	skill_name = "Bodyguard's Instinct"
	skill_desc = "When your ward takes damage, gain +30% movement speed for 2 seconds."
	branch = "Client Protection"
	tier = 2
	choice = "a"
	/// Currently tracked ward
	var/mob/living/current_ward
	/// Timer ID for removing the speed boost
	var/speed_timer_id

/datum/component/association_skill/zwei_bodyguards_instinct/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	var/datum/action/cooldown/zwei_mark_for_protection/ward_action = get_zwei_ward_action(human_parent)
	if(ward_action)
		ward_action.ward_change_callbacks += CALLBACK(src, PROC_REF(on_ward_changed))
		on_ward_changed(ward_action.ward)

/datum/component/association_skill/zwei_bodyguards_instinct/Destroy()
	if(current_ward)
		UnregisterSignal(current_ward, COMSIG_MOB_AFTER_APPLY_DAMGE)
		current_ward = null
	if(speed_timer_id)
		deltimer(speed_timer_id)
		speed_timer_id = null
	if(human_parent)
		human_parent.remove_movespeed_modifier(/datum/movespeed_modifier/zwei_bodyguard_sprint)
		var/datum/action/cooldown/zwei_mark_for_protection/ward_action = get_zwei_ward_action(human_parent)
		if(ward_action)
			ward_action.ward_change_callbacks -= CALLBACK(src, PROC_REF(on_ward_changed))
	return ..()

/// Called when the ward changes.
/datum/component/association_skill/zwei_bodyguards_instinct/proc/on_ward_changed(mob/living/new_ward)
	if(current_ward)
		UnregisterSignal(current_ward, COMSIG_MOB_AFTER_APPLY_DAMGE)
	current_ward = new_ward
	if(current_ward)
		RegisterSignal(current_ward, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(on_ward_damaged))

/// Signal handler: ward took damage.
/datum/component/association_skill/zwei_bodyguards_instinct/proc/on_ward_damaged(datum/source, damage, damagetype, def_zone, wound_bonus, bare_wound_bonus, sharpness, attacker)
	SIGNAL_HANDLER
	if(!can_use_skill())
		return
	if(isliving(attacker) && is_association_member(attacker))
		return
	INVOKE_ASYNC(src, PROC_REF(apply_speed_boost))

/// Apply the speed boost with a 2s timer.
/datum/component/association_skill/zwei_bodyguards_instinct/proc/apply_speed_boost()
	if(!human_parent || QDELETED(human_parent))
		return
	human_parent.add_movespeed_modifier(/datum/movespeed_modifier/zwei_bodyguard_sprint)
	// Reset timer if already running
	if(speed_timer_id)
		deltimer(speed_timer_id)
	speed_timer_id = addtimer(CALLBACK(src, PROC_REF(remove_speed_boost)), 2 SECONDS, TIMER_STOPPABLE)

/// Remove the speed boost.
/datum/component/association_skill/zwei_bodyguards_instinct/proc/remove_speed_boost()
	speed_timer_id = null
	if(!human_parent || QDELETED(human_parent))
		return
	human_parent.remove_movespeed_modifier(/datum/movespeed_modifier/zwei_bodyguard_sprint)

// ============================================================
// T2b: Shared Resilience
// ============================================================
/// When you gain DLU stacks, ward gains half (within 7 tiles).
/datum/component/association_skill/zwei_shared_resilience
	skill_name = "Shared Resilience"
	skill_desc = "When you gain Defense Level Up stacks, your ward also gains half the amount (within 7 tiles)."
	branch = "Client Protection"
	tier = 2
	choice = "b"
	/// Last known DLU stack count (for delta tracking)
	var/last_known_dlu = 0

/datum/component/association_skill/zwei_shared_resilience/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	check_dlu_change()

/datum/component/association_skill/zwei_shared_resilience/on_after_take_damage(datum/source, damage, damagetype, def_zone)
	if(!can_use_skill())
		return
	check_dlu_change()

/// Check if DLU stacks increased and share half with ward.
/datum/component/association_skill/zwei_shared_resilience/proc/check_dlu_change()
	var/datum/status_effect/stacking/defense_level_up/D = human_parent.has_status_effect(/datum/status_effect/stacking/defense_level_up)
	if(!D || istype(D, /datum/status_effect/stacking/defense_level_up/defense_level_down))
		last_known_dlu = 0
		return
	var/current_dlu = D.stacks
	var/delta = current_dlu - last_known_dlu
	last_known_dlu = current_dlu
	if(delta <= 0)
		return
	// Share half the increase with ward
	var/datum/action/cooldown/zwei_mark_for_protection/ward_action = get_zwei_ward_action(human_parent)
	if(!ward_action)
		return
	var/mob/living/ward = ward_action.get_ward()
	if(!ward)
		return
	if(get_dist(get_turf(human_parent), get_turf(ward)) > 7)
		return
	var/share_amount = CEILING(delta / 2, 1)
	INVOKE_ASYNC(ward, TYPE_PROC_REF(/mob/living, apply_lc_defense_level_up), share_amount)

// ============================================================
// T3a: Guardian's Wrath
// ============================================================
/// Grants a powerful attack action. Leap to target, 4-hit combo. Ward damage doubles damage.
/datum/component/association_skill/zwei_guardians_wrath
	skill_name = "Guardian's Wrath"
	skill_desc = "Grants a powerful attack action (costs Adrenaline). Leap to a target for a 4-hit combo. If your ward was hurt recently, damage is doubled."
	branch = "Client Protection"
	tier = 3
	choice = "a"
	/// Reference to the granted action
	var/datum/action/cooldown/zwei_guardians_wrath_action/combo_action
	/// Currently tracked ward (for damage timing)
	var/mob/living/current_ward
	/// world.time when the ward last took damage
	var/ward_last_damage_time = 0

/datum/component/association_skill/zwei_guardians_wrath/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	combo_action = new()
	combo_action.Grant(human_parent)
	var/datum/action/cooldown/zwei_mark_for_protection/ward_action = get_zwei_ward_action(human_parent)
	if(ward_action)
		ward_action.ward_change_callbacks += CALLBACK(src, PROC_REF(on_ward_changed))
		on_ward_changed(ward_action.ward)

/datum/component/association_skill/zwei_guardians_wrath/Destroy()
	if(combo_action && human_parent)
		combo_action.Remove(human_parent)
	combo_action = null
	if(current_ward)
		UnregisterSignal(current_ward, COMSIG_MOB_AFTER_APPLY_DAMGE)
		current_ward = null
	if(human_parent)
		var/datum/action/cooldown/zwei_mark_for_protection/ward_action = get_zwei_ward_action(human_parent)
		if(ward_action)
			ward_action.ward_change_callbacks -= CALLBACK(src, PROC_REF(on_ward_changed))
	return ..()

/// Called when the ward changes.
/datum/component/association_skill/zwei_guardians_wrath/proc/on_ward_changed(mob/living/new_ward)
	if(current_ward)
		UnregisterSignal(current_ward, COMSIG_MOB_AFTER_APPLY_DAMGE)
	current_ward = new_ward
	ward_last_damage_time = 0
	if(current_ward)
		RegisterSignal(current_ward, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(on_ward_damaged))

/// Signal handler: ward took damage — track timing.
/datum/component/association_skill/zwei_guardians_wrath/proc/on_ward_damaged(datum/source, damage, damagetype, def_zone, wound_bonus, bare_wound_bonus, sharpness, attacker)
	SIGNAL_HANDLER
	if(isliving(attacker) && is_association_member(attacker))
		return
	ward_last_damage_time = world.time

/// Guardian's Wrath action — adrenaline-powered powerful attack.
/datum/action/cooldown/zwei_guardians_wrath_action
	name = "Guardian's Wrath"
	desc = "Leap to a target from up to 7 tiles. 4-hit combo. If your ward was hurt in the last 10 seconds, damage is doubled. Costs 100 Adrenaline."
	icon_icon = 'icons/hud/screen_assoc_trees.dmi'
	button_icon_state = "zwei_t3"
	cooldown_time = 0

/datum/action/cooldown/zwei_guardians_wrath_action/Trigger()
	. = ..()
	if(!.)
		return FALSE
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/user = owner
	// Check skill usability
	var/datum/component/association_skill/zwei_guardians_wrath/skill = user.GetComponent(/datum/component/association_skill/zwei_guardians_wrath)
	if(!skill || !skill.can_use_skill())
		to_chat(user, span_warning("You cannot use this skill right now."))
		return FALSE
	// Find closest hostile target in view(7)
	var/mob/living/target
	var/closest_dist = 999
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

/datum/action/cooldown/zwei_guardians_wrath_action/proc/ExecuteCombo(mob/living/target, mob/living/carbon/human/user, datum/component/association_skill/zwei_guardians_wrath/skill)
	// DPS calculation
	var/obj/item/weapon = user.get_active_held_item()
	var/dps = weapon ? (weapon.force * 1.25 / max(weapon.attack_speed, 0.1)) : 30

	// Check if ward was hurt in last 10 seconds for damage doubling
	var/ward_hurt = (skill.ward_last_damage_time > 0 && (world.time - skill.ward_last_damage_time) <= 10 SECONDS)
	var/hit_damage = ward_hurt ? dps * 2 : dps

	// Get ward reference for per-hit healing
	var/datum/action/cooldown/zwei_mark_for_protection/ward_action = get_zwei_ward_action(user)
	var/mob/living/ward = ward_action?.get_ward()

	// Phase 1: Leap to target — animate up, forceMove, animate down
	playsound(user, 'sound/weapons/thudswoosh.ogg', 60, TRUE, 8)
	animate(user, pixel_z = 64, alpha = 180, time = 3)
	sleep(0.3 SECONDS)
	if(QDELETED(user) || QDELETED(target))
		animate(user, pixel_z = 0, alpha = 255, time = 1)
		return
	// Move adjacent to target
	var/turf/landing = get_step(target, get_dir(target, user))
	if(!landing || landing.is_blocked_turf(TRUE))
		landing = get_turf(target)
	user.forceMove(landing)
	user.face_atom(target)
	animate(user, pixel_z = 0, alpha = 255, time = 2)
	sleep(0.2 SECONDS)

	// Landing impact AoE — 1x DPS to all nearby
	new /obj/effect/temp_visual/smash_effect(get_turf(user))
	shake_camera(user, 2, 2)
	playsound(user, 'sound/weapons/thudswoosh.ogg', 80, TRUE, 8)
	for(var/mob/living/L in range(1, get_turf(user)))
		if(L == user || skill.is_designated_ally(L))
			continue
		if(L.stat == DEAD)
			continue
		L.deal_damage(dps, RED_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)

	if(QDELETED(target) || target.stat == DEAD)
		return

	sleep(0.3 SECONDS)
	if(QDELETED(user) || QDELETED(target))
		return

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

	// Hit 1
	sleep(0.3 SECONDS)
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
		qdel(target.GetComponent(/datum/component/cutscene_duel))
		return
	user.do_attack_animation(target)
	playsound(target, 'sound/weapons/rapierhit.ogg', 60, TRUE, 6)
	target.deal_damage(hit_damage, RED_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
	heal_ward(ward, hit_damage, user)
	grant_ward_proximity_protection(ward, user, 2)
	new /obj/effect/temp_visual/dir_setting/gray_edge/zwei(get_turf(user), user.dir)

	// Hit 2
	sleep(0.5 SECONDS)
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
		qdel(target.GetComponent(/datum/component/cutscene_duel))
		return
	ZweiComboDash(user, target, TRUE)
	sleep(0.2 SECONDS)
	if(QDELETED(target) || QDELETED(user))
		qdel(target.GetComponent(/datum/component/cutscene_duel))
		return
	user.do_attack_animation(target)
	playsound(target, 'sound/weapons/rapierhit.ogg', 60, TRUE, 6)
	target.deal_damage(hit_damage, RED_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
	heal_ward(ward, hit_damage, user)
	grant_ward_proximity_protection(ward, user, 2)
	new /obj/effect/temp_visual/dir_setting/gray_edge/zwei/passthrough(get_turf(target), user.dir)

	// Hit 3
	sleep(0.5 SECONDS)
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
		qdel(target.GetComponent(/datum/component/cutscene_duel))
		return
	ZweiComboDash(user, target, FALSE)
	sleep(0.2 SECONDS)
	if(QDELETED(target) || QDELETED(user))
		qdel(target.GetComponent(/datum/component/cutscene_duel))
		return
	user.do_attack_animation(target)
	playsound(target, 'sound/weapons/rapierhit.ogg', 60, TRUE, 6)
	target.deal_damage(hit_damage, RED_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
	heal_ward(ward, hit_damage, user)
	grant_ward_proximity_protection(ward, user, 2)
	new /obj/effect/temp_visual/dir_setting/gray_edge/zwei(get_turf(user), user.dir)

	// Hit 4 (FINISHER): 2x damage, 5 DLU, knockback away from ward
	sleep(0.5 SECONDS)
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
		qdel(target.GetComponent(/datum/component/cutscene_duel))
		return
	ZweiComboDash(user, target, TRUE)
	sleep(0.3 SECONDS)
	if(QDELETED(target) || QDELETED(user))
		qdel(target.GetComponent(/datum/component/cutscene_duel))
		return
	user.do_attack_animation(target)
	playsound(target, 'sound/weapons/rapierhit.ogg', 80, TRUE, 8)
	target.deal_damage(hit_damage * 2, RED_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
	heal_ward(ward, hit_damage * 2, user)
	user.apply_lc_defense_level_up(5)
	new /obj/effect/temp_visual/dir_setting/gray_edge/zwei/passthrough(get_turf(target), user.dir)
	shake_camera(target, 3, 3)
	// Clean up cutscene duel
	qdel(target.GetComponent(/datum/component/cutscene_duel))
	if(!QDELETED(user))
		user.say(pick("No one touches my ward!", "You'll pay for that!", "Under MY protection!"))

/// Helper: heal ward for 5% of damage dealt if alive and within 10 tiles.
/datum/action/cooldown/zwei_guardians_wrath_action/proc/heal_ward(mob/living/ward, damage_dealt, mob/living/user)
	if(!ward || QDELETED(ward) || ward.stat == DEAD)
		return
	if(get_dist(get_turf(user), get_turf(ward)) > 10)
		return
	var/heal = damage_dealt * 0.05
	ward.adjustBruteLoss(-heal)

/// Helper: grant Protection to user if ward is within 5 tiles.
/datum/action/cooldown/zwei_guardians_wrath_action/proc/grant_ward_proximity_protection(mob/living/ward, mob/living/user, stacks)
	if(!ward || QDELETED(ward) || ward.stat == DEAD)
		return
	if(get_dist(get_turf(user), get_turf(ward)) > 5)
		return
	user.apply_lc_protection(stacks)

// ============================================================
// T3b: Lifelink
// ============================================================
/// Ward takes damage: block it, teleport to ward, take hit yourself. 5s CD, 2-7 tile range.
/datum/component/association_skill/zwei_lifelink
	skill_name = "Lifelink"
	skill_desc = "When your ward takes damage within 2-7 tiles, block the damage entirely, teleport to them, and take the hit yourself. 5 second cooldown."
	branch = "Client Protection"
	tier = 3
	choice = "b"
	/// Currently tracked ward
	var/mob/living/current_ward
	/// Internal cooldown tracker
	var/last_trigger = 0

/datum/component/association_skill/zwei_lifelink/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	var/datum/action/cooldown/zwei_mark_for_protection/ward_action = get_zwei_ward_action(human_parent)
	if(ward_action)
		ward_action.ward_change_callbacks += CALLBACK(src, PROC_REF(on_ward_changed))
		on_ward_changed(ward_action.ward)

/datum/component/association_skill/zwei_lifelink/Destroy()
	if(current_ward)
		UnregisterSignal(current_ward, COMSIG_MOB_APPLY_DAMGE)
		current_ward = null
	if(human_parent)
		var/datum/action/cooldown/zwei_mark_for_protection/ward_action = get_zwei_ward_action(human_parent)
		if(ward_action)
			ward_action.ward_change_callbacks -= CALLBACK(src, PROC_REF(on_ward_changed))
	return ..()

/// Called when the ward changes.
/datum/component/association_skill/zwei_lifelink/proc/on_ward_changed(mob/living/new_ward)
	if(current_ward)
		UnregisterSignal(current_ward, COMSIG_MOB_APPLY_DAMGE)
	current_ward = new_ward
	if(current_ward)
		RegisterSignal(current_ward, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_ward_pre_damage))

/// Signal handler: ward is about to take damage — intercept and redirect.
/datum/component/association_skill/zwei_lifelink/proc/on_ward_pre_damage(datum/source, damage, damagetype, def_zone, attacker)
	SIGNAL_HANDLER
	if(!can_use_skill())
		return
	if(isliving(attacker) && is_association_member(attacker))
		return
	if(world.time < last_trigger + 5 SECONDS)
		return
	if(!current_ward || QDELETED(current_ward) || !human_parent || QDELETED(human_parent))
		return
	// Range check: 2-7 tiles (not too close, not too far)
	var/dist = get_dist(get_turf(human_parent), get_turf(current_ward))
	if(dist < 2 || dist > 7)
		return
	last_trigger = world.time
	// Block the damage to ward
	INVOKE_ASYNC(src, PROC_REF(execute_lifelink), damage, damagetype)
	return COMPONENT_MOB_DENY_DAMAGE

/// Execute the lifelink — teleport to ward and take the damage.
/datum/component/association_skill/zwei_lifelink/proc/execute_lifelink(damage, damagetype)
	if(!human_parent || QDELETED(human_parent) || !current_ward || QDELETED(current_ward))
		return
	// Teleport to ward
	var/turf/ward_turf = get_turf(current_ward)
	var/turf/adjacent = get_step(current_ward, get_dir(current_ward, human_parent))
	if(!adjacent || adjacent.is_blocked_turf(TRUE))
		adjacent = ward_turf
	var/turf/origin = get_turf(human_parent)
	human_parent.forceMove(adjacent)
	human_parent.face_atom(current_ward)
	// Visual effects
	new /obj/effect/temp_visual/small_smoke/halfsecond(origin)
	playsound(human_parent, 'sound/weapons/thudswoosh.ogg', 50, TRUE, 6)
	human_parent.visible_message(span_danger("[human_parent] appears beside [current_ward], taking the blow!"))
	// Take the damage ourselves
	human_parent.deal_damage(damage, damagetype, current_ward, DAMAGE_FORCED)
