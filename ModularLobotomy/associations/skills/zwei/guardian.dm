// ============================================================
// Zwei Association — Guardian Branch
// ============================================================
// Self-defense focused. Defense Level Up manipulation and conversion to offense.

/// Helper: dash user toward/through target with beam trail, smoke, and smooth pixel slide.
/// dash_through=FALSE stops adjacent, dash_through=TRUE goes 2 tiles past.
/// Blue-gray beam color to distinguish from Seven's dark blue.
/proc/ZweiComboDash(mob/living/user, mob/living/target, dash_through = FALSE, beam_color = "#4a5568")
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
	// Smooth pixel slide from old position to new position
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

/// Movespeed modifier for Steady Footing — ~15% speed boost.
/datum/movespeed_modifier/zwei_steady_footing
	id = "zwei_steady_footing"
	multiplicative_slowdown = -0.5

// ============================================================
// T1a: Iron Stance
// ============================================================
/// On taking damage, gain 3 Defense Level Up stacks. 0.5s internal CD.
/datum/component/association_skill/zwei_iron_stance
	skill_name = "Iron Stance"
	skill_desc = "On taking damage, gain 3 Defense Level Up stacks. 0.5 second cooldown."
	branch = "Guardian"
	tier = 1
	choice = "a"
	/// Internal cooldown tracker
	var/last_trigger = 0

/datum/component/association_skill/zwei_iron_stance/on_after_take_damage(datum/source, damage, damagetype, def_zone, wound_bonus, bare_wound_bonus, sharpness, attacker)
	if(!can_use_skill())
		return
	if(isliving(attacker) && is_association_member(attacker))
		return
	if(world.time < last_trigger + 0.5 SECONDS)
		return
	last_trigger = world.time
	INVOKE_ASYNC(human_parent, TYPE_PROC_REF(/mob/living, apply_lc_defense_level_up), 3)

// ============================================================
// T1b: Aggressive Guard
// ============================================================
/// On hitting an enemy, gain 2 Defense Level Up stacks. 1s internal CD.
/datum/component/association_skill/zwei_aggressive_guard
	skill_name = "Aggressive Guard"
	skill_desc = "On hitting an enemy, gain 2 Defense Level Up stacks. 1 second cooldown."
	branch = "Guardian"
	tier = 1
	choice = "b"
	/// Internal cooldown tracker
	var/last_trigger = 0

/datum/component/association_skill/zwei_aggressive_guard/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	if(is_association_member(target))
		return
	if(world.time < last_trigger + 1 SECONDS)
		return
	last_trigger = world.time
	INVOKE_ASYNC(human_parent, TYPE_PROC_REF(/mob/living, apply_lc_defense_level_up), 2)

// ============================================================
// T2a: Shieldbreaker
// ============================================================
/// Attacks deal bonus RED damage equal to Defense Level Up percentage of weapon's base damage.
/datum/component/association_skill/zwei_shieldbreaker
	skill_name = "Shieldbreaker"
	skill_desc = "Your attacks deal bonus RED damage equal to your Defense Level Up percentage of your weapon's base damage."
	branch = "Guardian"
	tier = 2
	choice = "a"

/datum/component/association_skill/zwei_shieldbreaker/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	if(is_association_member(target))
		return
	if(!item)
		return
	// Read DLU stacks, excluding DLD (which subtypes DLU)
	var/datum/status_effect/stacking/defense_level_up/D = human_parent.has_status_effect(/datum/status_effect/stacking/defense_level_up)
	if(!D || istype(D, /datum/status_effect/stacking/defense_level_up/defense_level_down))
		return
	if(D.stacks <= 0)
		return
	var/def_pct = D.stacks / (D.stacks + 25)
	var/bonus = item.force * def_pct
	if(bonus > 0)
		INVOKE_ASYNC(target, TYPE_PROC_REF(/mob/living, deal_damage), bonus, RED_DAMAGE, human_parent, DAMAGE_FORCED)
		new /obj/effect/temp_visual/dir_setting/gray_edge/zwei(get_turf(user), user.dir)

// ============================================================
// T2b: Steady Footing
// ============================================================
/// While you have 5+ DLU stacks, gain +15% movement speed. Uses process() to track decay.
/datum/component/association_skill/zwei_steady_footing
	skill_name = "Steady Footing"
	skill_desc = "While you have 5 or more Defense Level Up stacks, gain +15% movement speed."
	branch = "Guardian"
	tier = 2
	choice = "b"
	/// Whether the speed boost is currently active
	var/speed_active = FALSE

/datum/component/association_skill/zwei_steady_footing/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	START_PROCESSING(SSobj, src)

/datum/component/association_skill/zwei_steady_footing/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(speed_active && human_parent)
		human_parent.remove_movespeed_modifier(/datum/movespeed_modifier/zwei_steady_footing)
		speed_active = FALSE
	return ..()

/datum/component/association_skill/zwei_steady_footing/process(seconds_per_tick)
	if(!human_parent || QDELETED(human_parent))
		return
	if(!can_use_skill())
		if(speed_active)
			human_parent.remove_movespeed_modifier(/datum/movespeed_modifier/zwei_steady_footing)
			speed_active = FALSE
		return
	// Check DLU stacks (exclude DLD)
	var/datum/status_effect/stacking/defense_level_up/D = human_parent.has_status_effect(/datum/status_effect/stacking/defense_level_up)
	var/has_enough = FALSE
	if(D && !istype(D, /datum/status_effect/stacking/defense_level_up/defense_level_down) && D.stacks >= 5)
		has_enough = TRUE
	if(has_enough && !speed_active)
		human_parent.add_movespeed_modifier(/datum/movespeed_modifier/zwei_steady_footing)
		speed_active = TRUE
	else if(!has_enough && speed_active)
		human_parent.remove_movespeed_modifier(/datum/movespeed_modifier/zwei_steady_footing)
		speed_active = FALSE

// ============================================================
// T3a: Retaliating Onslaught
// ============================================================
/// Grants a powerful attack action. Consume DLU for +1%/stack damage, 5-hit combo.
/datum/component/association_skill/zwei_retaliating_onslaught
	skill_name = "Retaliating Onslaught"
	skill_desc = "Grants a powerful attack action (costs Adrenaline). Consume Defense Level Up stacks for bonus damage, then deliver a 5-hit combo."
	branch = "Guardian"
	tier = 3
	choice = "a"
	/// Reference to the granted action
	var/datum/action/cooldown/zwei_retaliating_onslaught_action/combo_action

/datum/component/association_skill/zwei_retaliating_onslaught/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	combo_action = new()
	combo_action.Grant(human_parent)

/datum/component/association_skill/zwei_retaliating_onslaught/Destroy()
	if(combo_action && human_parent)
		combo_action.Remove(human_parent)
	combo_action = null
	return ..()

/// Retaliating Onslaught action — adrenaline-powered powerful attack.
/datum/action/cooldown/zwei_retaliating_onslaught_action
	name = "Retaliating Onslaught"
	desc = "Consume your Defense Level Up stacks for +1% damage per stack, then dash to the nearest enemy for a devastating 5-hit combo. Costs 100 Adrenaline."
	icon_icon = 'icons/hud/screen_assoc_trees.dmi'
	button_icon_state = "zwei_t3"
	cooldown_time = 0

/datum/action/cooldown/zwei_retaliating_onslaught_action/Trigger()
	. = ..()
	if(!.)
		return FALSE
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/user = owner
	// Check skill usability
	var/datum/component/association_skill/zwei_retaliating_onslaught/skill = user.GetComponent(/datum/component/association_skill/zwei_retaliating_onslaught)
	if(!skill || !skill.can_use_skill())
		to_chat(user, span_warning("You cannot use this skill right now."))
		return FALSE
	// Find closest hostile target in view
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
	INVOKE_ASYNC(src, PROC_REF(ExecuteCombo), target, user)
	return TRUE

/datum/action/cooldown/zwei_retaliating_onslaught_action/proc/ExecuteCombo(mob/living/target, mob/living/carbon/human/user)
	// Read and consume DLU stacks for damage multiplier
	var/consumed_stacks = 0
	var/datum/status_effect/stacking/defense_level_up/D = user.has_status_effect(/datum/status_effect/stacking/defense_level_up)
	if(D && !istype(D, /datum/status_effect/stacking/defense_level_up/defense_level_down))
		consumed_stacks = D.stacks
		D.add_stacks(-consumed_stacks) // Consume all stacks
	var/damage_multiplier = 1 + consumed_stacks * 0.01

	// DPS calculation
	var/obj/item/weapon = user.get_active_held_item()
	var/dps = weapon ? (weapon.force * 1.25 / max(weapon.attack_speed, 0.1)) : 30
	var/hit_damage = dps * damage_multiplier

	// Immobilize both for combo
	var/combo_duration = 3.5 SECONDS
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

	// Hit 1: Dash TO target, opening strike
	ZweiComboDash(user, target, FALSE)
	sleep(0.3 SECONDS)
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
		qdel(target.GetComponent(/datum/component/cutscene_duel))
		return
	user.do_attack_animation(target)
	playsound(target, 'sound/weapons/rapierhit.ogg', 60, TRUE, 6)
	target.deal_damage(hit_damage, RED_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
	user.apply_lc_defense_level_up(2)
	new /obj/effect/temp_visual/dir_setting/gray_cube_v1/zwei(get_turf(user), user.dir)

	// Hit 2: Dash THROUGH target
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
	user.apply_lc_defense_level_up(2)
	new /obj/effect/temp_visual/dir_setting/gray_cube_v1/zwei/passthrough(get_turf(target), user.dir)

	// Hit 3: Dash TO target
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
	user.apply_lc_defense_level_up(2)
	new /obj/effect/temp_visual/dir_setting/gray_cube_v1/zwei(get_turf(user), user.dir)

	// Hit 4: Dash THROUGH target
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
	user.apply_lc_defense_level_up(2)
	new /obj/effect/temp_visual/dir_setting/gray_cube_v1/zwei/passthrough(get_turf(target), user.dir)

	// Hit 5 (FINISHER): Dash TO target, double damage + 5 DLU + knockback
	sleep(0.5 SECONDS)
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
		qdel(target.GetComponent(/datum/component/cutscene_duel))
		return
	ZweiComboDash(user, target, FALSE)
	sleep(0.3 SECONDS)
	if(QDELETED(target) || QDELETED(user))
		qdel(target.GetComponent(/datum/component/cutscene_duel))
		return
	user.do_attack_animation(target)
	playsound(target, 'sound/weapons/rapierhit.ogg', 80, TRUE, 8)
	target.deal_damage(hit_damage * 2, RED_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
	user.apply_lc_defense_level_up(5)
	new /obj/effect/temp_visual/dir_setting/gray_cube_v1/zwei(get_turf(user), user.dir)
	shake_camera(target, 3, 3)
	// Clean up cutscene duel
	qdel(target.GetComponent(/datum/component/cutscene_duel))
	if(!QDELETED(user))
		user.say(pick("Stand your ground!", "My defense is my offense!", "Not one step back!"))

// ============================================================
// T3b: Unbreakable
// ============================================================
/// On lethal damage, survive at 15% HP, gain 7 Protection + 3s invulnerability. 5min CD.
/datum/component/association_skill/zwei_unbreakable
	skill_name = "Unbreakable"
	skill_desc = "On lethal damage, survive at 15% HP, gain 7 Protection stacks and 3 seconds of invulnerability. 5 minute cooldown."
	branch = "Guardian"
	tier = 3
	choice = "b"
	/// Internal cooldown tracker
	var/last_trigger = 0

/datum/component/association_skill/zwei_unbreakable/on_take_damage(datum/source, damage, damagetype, def_zone)
	if(!can_use_skill())
		return
	if(world.time < last_trigger + 5 MINUTES)
		return
	// Check if this damage would be lethal
	if(human_parent.health - damage > 0)
		return
	last_trigger = world.time
	// Deny the lethal damage
	INVOKE_ASYNC(src, PROC_REF(activate_unbreakable))
	return COMPONENT_MOB_DENY_DAMAGE

/// Activate Unbreakable — heal to 15%, grant Protection, and temporary GODMODE.
/datum/component/association_skill/zwei_unbreakable/proc/activate_unbreakable()
	if(!human_parent || QDELETED(human_parent))
		return
	// Heal to 15% max health
	var/target_hp = human_parent.maxHealth * 0.15
	var/heal_amount = target_hp - human_parent.health
	if(heal_amount > 0)
		human_parent.adjustBruteLoss(-heal_amount)
	// Grant 7 Protection stacks
	human_parent.apply_lc_protection(7)
	// 3 seconds of GODMODE
	human_parent.status_flags |= GODMODE
	addtimer(CALLBACK(src, PROC_REF(remove_godmode)), 3 SECONDS)
	// Visual + audio feedback
	to_chat(human_parent, span_nicegreen("UNBREAKABLE! You shrug off the lethal blow!"))
	human_parent.visible_message(span_danger("[human_parent] refuses to fall!"))
	playsound(human_parent, 'sound/weapons/thudswoosh.ogg', 80, TRUE, 8)
	new /obj/effect/temp_visual/smash_effect(get_turf(human_parent))

/// Remove GODMODE after the invulnerability window expires.
/datum/component/association_skill/zwei_unbreakable/proc/remove_godmode()
	if(!human_parent || QDELETED(human_parent))
		return
	human_parent.status_flags &= ~GODMODE
