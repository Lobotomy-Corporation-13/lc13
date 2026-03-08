// ============================================================
// Dieci Association — Scholar Branch
// ============================================================
// Theme: Sinking application and exploitation. Preferred type: Behavioral.
// 6 skills across 3 tiers (T1a/T1b, T2a/T2b, T3a/T3b).

// ============================================================
// Shared Helper: Dieci Combo Dash
// ============================================================

/// Dash the user to (or through) a target with visual trail and slide animation.
/proc/DieciComboDash(mob/living/user, mob/living/target, dash_through = FALSE, beam_color = "#8b7500")
	var/turf/origin = get_turf(user)
	var/turf/destination
	if(dash_through)
		destination = get_ranged_target_turf_direct(user, target, get_dist(user, target) + 2)
	else
		destination = get_step(target, get_dir(target, user))
		if(!destination || destination.is_blocked_turf(TRUE))
			destination = get_turf(target)
	user.forceMove(destination)
	user.face_atom(target)
	var/dx = (origin.x - destination.x) * 32
	var/dy = (origin.y - destination.y) * 32
	user.pixel_x = user.base_pixel_x + dx
	user.pixel_y = user.base_pixel_y + dy
	animate(user, 0.2 SECONDS, pixel_x = user.base_pixel_x, pixel_y = user.base_pixel_y, easing = QUAD_EASING)
	new /obj/effect/temp_visual/small_smoke/halfsecond(origin)
	var/datum/beam/trail = origin.Beam(user, "1-full", time = 2)
	if(trail)
		trail.visuals.color = beam_color
	playsound(user, 'sound/weapons/thudswoosh.ogg', 50, TRUE, 6)

// ============================================================
// T1a: Deep Study
// ============================================================
// Melee attacks apply 2 Sinking. 5s CD: consume 1 Behavioral → bonus Sinking = level.

/// Scholar T1a — Melee attacks apply Sinking, with periodic Behavioral knowledge consumption for bonus stacks.
/datum/component/association_skill/dieci_deep_study
	skill_name = "Deep Study"
	skill_desc = "Melee attacks apply 2 Sinking. On hit, can also consume 1 lowest Behavioral for bonus Sinking = consumed level (5s cooldown)."
	branch = "Scholar"
	tier = 1
	choice = "a"
	/// Cooldown tracker for knowledge consumption
	var/last_consume = 0

/datum/component/association_skill/dieci_deep_study/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	if(!istype(target) || QDELETED(target))
		return
	// Always apply 2 Sinking
	INVOKE_ASYNC(target, TYPE_PROC_REF(/mob/living, apply_lc_sinking), 2)
	new /obj/effect/temp_visual/dir_setting/gray_edge/dieci(get_turf(user), user.dir)
	// 5s CD: consume 1 lowest Behavioral for bonus Sinking
	if(world.time < last_consume + 5 SECONDS)
		return
	var/datum/component/dieci_knowledge/kc = human_parent.GetComponent(/datum/component/dieci_knowledge)
	if(!kc || kc.conserve_knowledge)
		return
	var/list/consumed = kc.consume_lowest_of_type(DIECI_KNOWLEDGE_TYPE_BEHAVIORAL)
	if(!consumed)
		return
	last_consume = world.time
	var/bonus = consumed["level"]
	INVOKE_ASYNC(target, TYPE_PROC_REF(/mob/living, apply_lc_sinking), bonus)

// ============================================================
// T1b: Analytical Strike
// ============================================================
// Hit target with no Sinking → apply 8 Sinking.

/// Scholar T1b — Attacking a target with no Sinking applies a large burst of Sinking stacks.
/datum/component/association_skill/dieci_analytical_strike
	skill_name = "Analytical Strike"
	skill_desc = "Melee attacks against targets with 0 Sinking apply 8 Sinking."
	branch = "Scholar"
	tier = 1
	choice = "b"

/datum/component/association_skill/dieci_analytical_strike/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	if(!istype(target) || QDELETED(target))
		return
	var/datum/status_effect/stacking/sinking/S = target.has_status_effect(/datum/status_effect/stacking/sinking)
	if(S && S.stacks > 0)
		return
	INVOKE_ASYNC(target, TYPE_PROC_REF(/mob/living, apply_lc_sinking), 8)
	new /obj/effect/temp_visual/dir_setting/gray_edge/dieci(get_turf(user), user.dir)

// ============================================================
// T2a: Drowning Knowledge
// ============================================================
// H hit vs 15+ Sinking: +25% weapon force as bonus damage.
// 5s CD: consume 1 Behavioral → +5%/level additional bonus.

/// Scholar T2a — Heavy attacks against high-Sinking targets deal bonus damage, enhanced by Behavioral knowledge.
/datum/component/association_skill/dieci_drowning_knowledge
	skill_name = "Drowning Knowledge"
	skill_desc = "H attacks vs targets with 15+ Sinking deal +25% weapon force as RED bonus damage. On H attack, can also consume 1 Behavioral for +5%/level extra (5s cooldown)."
	branch = "Scholar"
	tier = 2
	choice = "a"
	/// Cooldown tracker for knowledge consumption
	var/last_consume = 0

/datum/component/association_skill/dieci_drowning_knowledge/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	if(!istype(target) || QDELETED(target) || !item)
		return
	// Only H attacks
	if(!istype(item, /obj/item/ego_weapon/city/dieci))
		return
	var/obj/item/ego_weapon/city/dieci/D = item
	if(!D.activated)
		return
	// Target must have 15+ Sinking
	var/datum/status_effect/stacking/sinking/S = target.has_status_effect(/datum/status_effect/stacking/sinking)
	if(!S || S.stacks < 15)
		return
	// Base: +25% weapon force as bonus damage
	var/bonus_pct = 0.25
	// 5s CD: consume 1 Behavioral for +5%/level
	if(world.time >= last_consume + 5 SECONDS)
		var/datum/component/dieci_knowledge/kc = human_parent.GetComponent(/datum/component/dieci_knowledge)
		if(kc && !kc.conserve_knowledge)
			var/list/consumed = kc.consume_lowest_of_type(DIECI_KNOWLEDGE_TYPE_BEHAVIORAL)
			if(consumed)
				last_consume = world.time
				bonus_pct += consumed["level"] * 0.05
	var/bonus_damage = item.force * bonus_pct
	if(bonus_damage > 0)
		INVOKE_ASYNC(target, TYPE_PROC_REF(/mob/living, deal_damage), bonus_damage, RED_DAMAGE, human_parent, DAMAGE_FORCED)

// ============================================================
// T2b: Spreading Decay
// ============================================================
// H hit vs Sinking target: 5 Sinking to enemies in 2 tiles (2s CD).
// 5s CD: consume 1 Behavioral → DLD = level to all hit.

/// Scholar T2b — Heavy attacks spread Sinking to nearby enemies, with knowledge-powered Defense Level Down.
/datum/component/association_skill/dieci_spreading_decay
	skill_name = "Spreading Decay"
	skill_desc = "H attacks vs Sinking targets spread 5 Sinking to enemies within 2 tiles (2s cooldown). On spread, can also consume 1 Behavioral for Defense Level Down = level to all hit (5s cooldown)."
	branch = "Scholar"
	tier = 2
	choice = "b"
	/// Cooldown tracker for AoE spread
	var/last_spread = 0
	/// Cooldown tracker for knowledge consumption
	var/last_consume = 0

/datum/component/association_skill/dieci_spreading_decay/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	if(!istype(target) || QDELETED(target))
		return
	// Only H attacks
	if(!istype(item, /obj/item/ego_weapon/city/dieci))
		return
	var/obj/item/ego_weapon/city/dieci/D = item
	if(!D.activated)
		return
	// Target must have Sinking
	var/datum/status_effect/stacking/sinking/S = target.has_status_effect(/datum/status_effect/stacking/sinking)
	if(!S || S.stacks <= 0)
		return
	// 2s CD on spread
	if(world.time < last_spread + 2 SECONDS)
		return
	last_spread = world.time
	// Check for knowledge consumption (5s CD)
	var/consume_level = 0
	if(world.time >= last_consume + 5 SECONDS)
		var/datum/component/dieci_knowledge/kc = human_parent.GetComponent(/datum/component/dieci_knowledge)
		if(kc && !kc.conserve_knowledge)
			var/list/consumed = kc.consume_lowest_of_type(DIECI_KNOWLEDGE_TYPE_BEHAVIORAL)
			if(consumed)
				last_consume = world.time
				consume_level = consumed["level"]
	// Spread Sinking to enemies in 2 tiles of target (not the target itself)
	INVOKE_ASYNC(src, PROC_REF(spread_sinking), target, consume_level)

/// Apply Sinking (and optional DLD) to enemies near the target.
/datum/component/association_skill/dieci_spreading_decay/proc/spread_sinking(mob/living/primary_target, consume_level)
	for(var/mob/living/L in range(2, get_turf(primary_target)))
		if(L == primary_target || L == human_parent)
			continue
		if(L.stat == DEAD)
			continue
		L.apply_lc_sinking(5)
		if(consume_level > 0)
			L.apply_lc_defense_level_down(consume_level)

// ============================================================
// T3a: Abyssal Revelation
// ============================================================
// 90s CD action. Consume up to 5 knowledge → shoulder-charge → 5-hit combo.
// +10%/level damage (cap 100%). Final: PALE + trigger Sinking. +2 free empowers.

/// Scholar T3a — Grants a powerful attack action that consumes knowledge for a devastating Sinking combo.
/datum/component/association_skill/dieci_abyssal_revelation
	skill_name = "Abyssal Revelation"
	skill_desc = "Action (costs Adrenaline): consume up to 5 highest knowledge (+10%/level damage, max +100%). 5-hit combo: hits 1-4 deal RED + 2 Sinking. Hit 5: PALE at 1.5x, triggers Sinking. Grants 2 free empowers."
	branch = "Scholar"
	tier = 3
	choice = "a"
	/// The granted action
	var/datum/action/cooldown/dieci_abyssal_revelation_action/combo_action

/datum/component/association_skill/dieci_abyssal_revelation/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	combo_action = new()
	combo_action.Grant(human_parent)

/datum/component/association_skill/dieci_abyssal_revelation/Destroy()
	if(combo_action && human_parent)
		combo_action.Remove(human_parent)
	combo_action = null
	return ..()

/// Action for Abyssal Revelation — adrenaline-powered powerful attack.
/datum/action/cooldown/dieci_abyssal_revelation_action
	name = "Abyssal Revelation"
	desc = "Consume up to 5 knowledge, then shoulder-charge the target for a devastating 5-hit combo that triggers Sinking. Costs 100 Adrenaline."
	icon_icon = 'icons/hud/screen_assoc_trees.dmi'
	button_icon_state = "dieci_t3"
	cooldown_time = 0

/datum/action/cooldown/dieci_abyssal_revelation_action/Trigger()
	. = ..()
	if(!.)
		return FALSE
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/user = owner
	// Need a target in view
	var/mob/living/target = user.pulling
	if(!istype(target))
		// Try to find closest hostile in view 1
		for(var/mob/living/L in range(1, get_turf(user)))
			if(L == user || L.stat == DEAD)
				continue
			target = L
			break
	if(!target)
		to_chat(user, span_warning("No valid target nearby."))
		return FALSE
	// Check skill usability
	var/datum/component/association_skill/dieci_abyssal_revelation/skill = user.GetComponent(/datum/component/association_skill/dieci_abyssal_revelation)
	if(!skill || !skill.can_use_skill())
		to_chat(user, span_warning("You cannot use this skill right now."))
		return FALSE
	// Check adrenaline
	var/datum/component/association_exp/exp = user.GetComponent(/datum/component/association_exp)
	if(!exp || !exp.has_enough_adrenaline())
		to_chat(user, span_warning("Not enough adrenaline! ([exp ? exp.adrenaline : 0]/[exp ? exp.max_adrenaline : 100])"))
		return FALSE
	exp.consume_adrenaline()
	INVOKE_ASYNC(src, PROC_REF(ExecuteCombo), target, user)
	return TRUE

/// Execute the Abyssal Revelation combo sequence.
/datum/action/cooldown/dieci_abyssal_revelation_action/proc/ExecuteCombo(mob/living/target, mob/living/carbon/human/user)
	// Consume up to 5 knowledge (highest first)
	var/datum/component/dieci_knowledge/kc = user.GetComponent(/datum/component/dieci_knowledge)
	var/total_levels = 0
	if(kc)
		for(var/i in 1 to 5)
			var/list/consumed = kc.consume_highest_knowledge()
			if(!consumed)
				break
			total_levels += consumed["level"]

	// Calculate DPS and damage multiplier
	var/obj/item/weapon = user.get_active_held_item()
	var/dps = weapon ? (weapon.force * 1.25 / max(weapon.attack_speed, 0.1)) : 30
	var/multiplier = min(2.0, 1 + total_levels * 0.1)
	var/hit_damage = dps * multiplier / 5

	// Immobilize both
	var/combo_duration = 4 SECONDS
	user.Immobilize(combo_duration)
	user.changeNext_move(combo_duration)
	if(isanimal(target))
		var/mob/living/simple_animal/hostile/H = target
		if(istype(H))
			H.toggle_ai(AI_OFF)
			addtimer(CALLBACK(H, TYPE_PROC_REF(/mob/living/simple_animal/hostile, toggle_ai), AI_ON), combo_duration)
	else if(ishuman(target))
		target.Immobilize(combo_duration)

	// Cutscene duel
	target.AddComponent(/datum/component/cutscene_duel, user)

	// Shoulder-charge dash to target
	DieciComboDash(user, target, FALSE)
	sleep(0.3 SECONDS)

	// 5-hit combo
	for(var/hit in 1 to 5)
		if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
			break
		user.do_attack_animation(target)
		playsound(target, 'sound/weapons/fixer/generic/fist1.ogg', 60, TRUE, 6)
		if(hit < 5)
			// Hits 1-4: RED damage + 2 Sinking
			target.deal_damage(hit_damage, RED_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
			if(!QDELETED(target))
				target.apply_lc_sinking(2)
			new /obj/effect/temp_visual/dir_setting/gray_edge/dieci(get_turf(user), user.dir)
		else
			// Hit 5 (finisher): PALE damage + trigger Sinking
			target.deal_damage(hit_damage * 1.5, PALE_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
			new /obj/effect/temp_visual/dir_setting/gray_edge/dieci(get_turf(user), user.dir)
			shake_camera(target, 3, 3)
			// Trigger Sinking
			if(!QDELETED(target))
				var/datum/status_effect/stacking/sinking/S = target.has_status_effect(/datum/status_effect/stacking/sinking)
				if(S && S.stacks > 0)
					S.trigger_sinking()
		if(hit < 5)
			sleep(0.5 SECONDS)

	// Grant 2 free empowers (max 3 stored)
	if(!QDELETED(user))
		var/obj/item/ego_weapon/city/dieci/W = user.get_active_held_item()
		if(istype(W))
			W.free_empowers = min(W.free_empowers + 2, 3)

	// Clean up
	if(!QDELETED(target))
		qdel(target.GetComponent(/datum/component/cutscene_duel))
	if(!QDELETED(user))
		user.say(pick("The abyss stares back.", "All knowledge returns to nothing.", "Revelation complete."))

// ============================================================
// T3b: Tome of Ruin
// ============================================================
// Passive. Every 5th H hit on same target: consume 1 knowledge → trigger Sinking + 5 new Sinking + 1 free empower.

/// Scholar T3b — Passive that triggers devastating Sinking bursts after sustained heavy attacks.
/datum/component/association_skill/dieci_tome_of_ruin
	skill_name = "Tome of Ruin"
	skill_desc = "Passive: every 5th H attack on the same target consumes 1 knowledge, triggers existing Sinking, applies 5 new Sinking, and grants 1 free empower."
	branch = "Scholar"
	tier = 3
	choice = "b"
	/// Hit count per target, keyed by weakref
	var/list/target_hits = list()

/datum/component/association_skill/dieci_tome_of_ruin/Destroy()
	target_hits = null
	return ..()

/datum/component/association_skill/dieci_tome_of_ruin/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	if(!istype(target) || QDELETED(target))
		return
	// Only H attacks
	if(!istype(item, /obj/item/ego_weapon/city/dieci))
		return
	var/obj/item/ego_weapon/city/dieci/D = item
	if(!D.activated)
		return
	// Track hits per target
	var/datum/weakref/ref = WEAKREF(target)
	var/ref_key = "\ref[ref]"
	if(!target_hits[ref_key])
		target_hits[ref_key] = 0
	target_hits[ref_key]++
	// Every 5th hit
	if(target_hits[ref_key] < 5)
		return
	target_hits[ref_key] = 0
	// Consume 1 knowledge (any, lowest)
	var/datum/component/dieci_knowledge/kc = human_parent.GetComponent(/datum/component/dieci_knowledge)
	if(!kc)
		return
	var/list/consumed = kc.consume_lowest_knowledge(1)
	if(!length(consumed))
		return
	// Trigger Sinking + 5 new Sinking + 1 free empower
	INVOKE_ASYNC(src, PROC_REF(trigger_ruin), target, user)

/// Execute the Tome of Ruin effect: trigger Sinking, apply new stacks, grant free empower.
/datum/component/association_skill/dieci_tome_of_ruin/proc/trigger_ruin(mob/living/target, mob/living/user)
	if(QDELETED(target))
		return
	// Trigger existing Sinking
	var/datum/status_effect/stacking/sinking/S = target.has_status_effect(/datum/status_effect/stacking/sinking)
	if(S && S.stacks > 0)
		S.trigger_sinking()
	// Apply 5 new Sinking
	if(!QDELETED(target))
		target.apply_lc_sinking(5)
	// Grant 1 free empower (max 3 stored)
	if(!QDELETED(user))
		var/obj/item/ego_weapon/city/dieci/W = user.get_active_held_item()
		if(istype(W))
			W.free_empowers = min(W.free_empowers + 1, 3)
		to_chat(user, span_danger("Tome of Ruin! Sinking triggered and renewed!"))
