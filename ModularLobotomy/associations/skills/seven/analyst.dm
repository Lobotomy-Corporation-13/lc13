// ============================================================
// Seven Association — Analyst Branch
// ============================================================
// Focused on Mark Target + Rupture exploitation for single-target damage.

/// Helper proc to find the Mark Target action on a mob's action list.
/proc/get_seven_mark_action(mob/living/L)
	for(var/datum/action/cooldown/seven_mark_target/mark in L.actions)
		return mark
	return null

/// Helper: dash user toward/through target with beam trail, smoke, and smooth pixel slide.
/// dash_through=FALSE stops adjacent, dash_through=TRUE goes 2 tiles past.
/proc/SevenComboDash(mob/living/user, mob/living/target, dash_through = FALSE, beam_color = "#1a1a3a")
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

// ============================================================
// T1a: Case File
// ============================================================
/// Grants Mark Target. Attacking a marked target applies 2 Rupture and bonus BLACK damage.
/datum/component/association_skill/seven_case_file
	skill_name = "Case File"
	skill_desc = "Grants Mark Target. Attacking a marked target applies 2 Rupture and deals bonus BLACK damage scaling with Rupture stacks."
	branch = "Analyst"
	tier = 1
	choice = "a"
	/// Reference to the mark action we granted
	var/datum/action/cooldown/seven_mark_target/mark_action

/datum/component/association_skill/seven_case_file/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	mark_action = get_seven_mark_action(human_parent)
	if(!mark_action)
		mark_action = new()
		mark_action.Grant(human_parent)

/datum/component/association_skill/seven_case_file/Destroy()
	// Only remove mark action if no other Analyst T1 skill exists
	if(mark_action && human_parent)
		var/datum/component/association_skill/seven_profiling/other = human_parent.GetComponent(/datum/component/association_skill/seven_profiling)
		if(!other)
			mark_action.Remove(human_parent)
	mark_action = null
	return ..()

/datum/component/association_skill/seven_case_file/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	if(!mark_action)
		return
	var/mob/living/marked = mark_action.get_marked()
	if(!marked || target != marked)
		return
	// Apply 2 Rupture
	INVOKE_ASYNC(target, TYPE_PROC_REF(/mob/living, apply_lc_rupture), 2)
	new /obj/effect/temp_visual/dir_setting/gray_edge/seven(get_turf(user), user.dir)
	// Bonus BLACK damage = min(40, rupture_stacks) * 0.01 * weapon force
	var/datum/status_effect/stacking/rupture/R = target.has_status_effect(/datum/status_effect/stacking/rupture)
	if(R && R.stacks > 0)
		var/bonus = min(40, R.stacks) * 0.01 * item.force
		if(bonus > 0)
			INVOKE_ASYNC(target, TYPE_PROC_REF(/mob/living, deal_damage), bonus, BLACK_DAMAGE, human_parent, DAMAGE_FORCED)

// ============================================================
// T1b: Profiling
// ============================================================
/// Grants Mark Target. Attacking a marked target grants OLU to self.
/datum/component/association_skill/seven_profiling
	skill_name = "Profiling"
	skill_desc = "Grants Mark Target. Attacking a marked target grants 2 Offense Level Up to yourself."
	branch = "Analyst"
	tier = 1
	choice = "b"
	/// Reference to the mark action we granted
	var/datum/action/cooldown/seven_mark_target/mark_action
	/// Total OLU stacks granted by this skill
	var/stacks_granted = 0
	/// Maximum OLU from this skill
	var/max_stacks = 10

/datum/component/association_skill/seven_profiling/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	mark_action = get_seven_mark_action(human_parent)
	if(!mark_action)
		mark_action = new()
		mark_action.Grant(human_parent)

/datum/component/association_skill/seven_profiling/Destroy()
	if(mark_action && human_parent)
		var/datum/component/association_skill/seven_case_file/other = human_parent.GetComponent(/datum/component/association_skill/seven_case_file)
		if(!other)
			mark_action.Remove(human_parent)
	mark_action = null
	return ..()

/datum/component/association_skill/seven_profiling/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	if(!mark_action)
		return
	var/mob/living/marked = mark_action.get_marked()
	if(!marked || target != marked)
		return
	if(stacks_granted >= max_stacks)
		return
	var/apply_amount = min(2, max_stacks - stacks_granted)
	INVOKE_ASYNC(human_parent, TYPE_PROC_REF(/mob/living, apply_lc_offense_level_up), apply_amount)
	stacks_granted += apply_amount

// ============================================================
// T2a: Exploit Weakness
// ============================================================
/// Attacking a marked target applies DLD. When marked target's Rupture triggers at 15+, applies Fragile.
/datum/component/association_skill/seven_exploit_weakness
	skill_name = "Exploit Weakness"
	skill_desc = "Attacking a marked target applies 2 Defense Level Down. When Rupture triggers at 15+ stacks, applies 5 Fragile."
	branch = "Analyst"
	tier = 2
	choice = "a"
	/// Cooldown tracking
	var/next_use_time = 0
	/// Target we have a rupture signal registered on
	var/mob/living/watching_target

/datum/component/association_skill/seven_exploit_weakness/Destroy()
	if(watching_target)
		UnregisterSignal(watching_target, COMSIG_RUPTURE_TRIGGERED)
		watching_target = null
	return ..()

/datum/component/association_skill/seven_exploit_weakness/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	var/datum/action/cooldown/seven_mark_target/mark = get_seven_mark_action(human_parent)
	if(!mark)
		return
	var/mob/living/marked = mark.get_marked()
	if(!marked || target != marked)
		return
	// Apply DLD with cooldown
	if(world.time >= next_use_time)
		next_use_time = world.time + 1 SECONDS
		INVOKE_ASYNC(target, TYPE_PROC_REF(/mob/living, apply_lc_defense_level_down), 2)
	// Update rupture watcher on marked target
	if(watching_target != target)
		if(watching_target)
			UnregisterSignal(watching_target, COMSIG_RUPTURE_TRIGGERED)
		watching_target = target
		RegisterSignal(target, COMSIG_RUPTURE_TRIGGERED, PROC_REF(on_target_rupture_trigger))

/// When marked target's Rupture triggers with 15+ stacks, apply Fragile.
/datum/component/association_skill/seven_exploit_weakness/proc/on_target_rupture_trigger(datum/source, stacks_before)
	SIGNAL_HANDLER
	if(stacks_before >= 15)
		var/mob/living/L = source
		INVOKE_ASYNC(L, TYPE_PROC_REF(/mob/living, apply_lc_fragile), 5)

// ============================================================
// T2b: Patient Hunter
// ============================================================
/// Bonus damage against marked targets with high Rupture.
/datum/component/association_skill/seven_patient_hunter
	skill_name = "Patient Hunter"
	skill_desc = "Attacking a marked target with 10+ Rupture deals 25% bonus damage. At 20+, also deals bonus BLACK."
	branch = "Analyst"
	tier = 2
	choice = "b"

/datum/component/association_skill/seven_patient_hunter/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	var/datum/action/cooldown/seven_mark_target/mark = get_seven_mark_action(human_parent)
	if(!mark)
		return
	var/mob/living/marked = mark.get_marked()
	if(!marked || target != marked)
		return
	var/datum/status_effect/stacking/rupture/R = target.has_status_effect(/datum/status_effect/stacking/rupture)
	if(!R || R.stacks < 10)
		return
	// 25% bonus damage (same type as weapon)
	var/bonus = item.force * 0.25
	INVOKE_ASYNC(target, TYPE_PROC_REF(/mob/living, deal_damage), bonus, item.damtype, human_parent, DAMAGE_FORCED)
	// At 20+ Rupture: also bonus BLACK = 15% weapon force
	if(R.stacks >= 20)
		var/black_bonus = item.force * 0.15
		INVOKE_ASYNC(target, TYPE_PROC_REF(/mob/living, deal_damage), black_bonus, BLACK_DAMAGE, human_parent, DAMAGE_FORCED)

// ============================================================
// T3a: Dossier Complete (Powerful Attack)
// ============================================================
/// Grants a powerful attack action. Dash + 4-hit combo on marked target.
/datum/component/association_skill/seven_dossier_complete
	skill_name = "Dossier Complete"
	skill_desc = "Grants a powerful attack action (costs Adrenaline). Dash to your marked target and deliver a devastating combo."
	branch = "Analyst"
	tier = 3
	choice = "a"
	/// Reference to the granted action
	var/datum/action/cooldown/seven_dossier_complete_action/combo_action

/datum/component/association_skill/seven_dossier_complete/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	combo_action = new()
	combo_action.Grant(human_parent)

/datum/component/association_skill/seven_dossier_complete/Destroy()
	if(combo_action && human_parent)
		combo_action.Remove(human_parent)
	combo_action = null
	return ..()

/// Dossier Complete action — adrenaline-powered powerful attack.
/datum/action/cooldown/seven_dossier_complete_action
	name = "Dossier Complete"
	desc = "Dash to your marked target and deliver a 4-hit combo scaling with Rupture. Requires a marked target with 10+ Rupture. Costs 100 Adrenaline."
	icon_icon = 'icons/hud/screen_assoc_trees.dmi'
	button_icon_state = "seven_t3"
	cooldown_time = 0

/datum/action/cooldown/seven_dossier_complete_action/Trigger()
	. = ..()
	if(!.)
		return FALSE
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/user = owner
	// Check for mark
	var/datum/action/cooldown/seven_mark_target/mark = get_seven_mark_action(user)
	if(!mark)
		to_chat(user, span_warning("You need the Mark Target skill first."))
		return FALSE
	var/mob/living/target = mark.get_marked()
	if(!target)
		to_chat(user, span_warning("No valid marked target."))
		return FALSE
	if(!(target in view(6, get_turf(user))))
		to_chat(user, span_warning("Marked target is not in range."))
		return FALSE
	// Check Rupture
	var/datum/status_effect/stacking/rupture/R = target.has_status_effect(/datum/status_effect/stacking/rupture)
	if(!R || R.stacks < 10)
		to_chat(user, span_warning("Target needs at least 10 Rupture stacks."))
		return FALSE
	// Check skill usability
	var/datum/component/association_skill/seven_dossier_complete/skill = user.GetComponent(/datum/component/association_skill/seven_dossier_complete)
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

/datum/action/cooldown/seven_dossier_complete_action/proc/ExecuteCombo(mob/living/target, mob/living/carbon/human/user)
	// DPS + Rupture scaling
	var/obj/item/weapon = user.get_active_held_item()
	var/dps = weapon ? (weapon.force * 1.25 / max(weapon.attack_speed, 0.1)) : 30
	var/datum/status_effect/stacking/rupture/R = target.has_status_effect(/datum/status_effect/stacking/rupture)
	var/rupture_stacks = R ? R.stacks : 0
	var/hit_damage = dps * (1 + rupture_stacks * 2 / 100) / 4

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

	// Hit 1: Dash TO target, opening strike
	SevenComboDash(user, target, FALSE)
	sleep(0.3 SECONDS)
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
		return
	user.do_attack_animation(target)
	playsound(target, 'sound/weapons/rapierhit.ogg', 60, TRUE, 6)
	target.deal_damage(hit_damage, BLACK_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
	target.apply_lc_offense_level_down(2)
	new /obj/effect/temp_visual/dir_setting/gray_edge/seven(get_turf(user), user.dir)

	// Hit 2: Dash THROUGH target, slash from behind
	sleep(0.5 SECONDS)
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
		return
	SevenComboDash(user, target, TRUE)
	sleep(0.2 SECONDS)
	if(QDELETED(target) || QDELETED(user))
		return
	user.do_attack_animation(target)
	playsound(target, 'sound/weapons/rapierhit.ogg', 60, TRUE, 6)
	target.deal_damage(hit_damage, BLACK_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
	target.apply_lc_offense_level_down(2)
	new /obj/effect/temp_visual/dir_setting/gray_edge/seven/passthrough(get_turf(target), user.dir)

	// Hit 3: Dash back TO target, heavy strike
	sleep(0.5 SECONDS)
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
		return
	SevenComboDash(user, target, FALSE)
	sleep(0.2 SECONDS)
	if(QDELETED(target) || QDELETED(user))
		return
	user.do_attack_animation(target)
	playsound(target, 'sound/weapons/rapierhit.ogg', 60, TRUE, 6)
	target.deal_damage(hit_damage, BLACK_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
	target.apply_lc_offense_level_down(2)
	new /obj/effect/temp_visual/dir_setting/gray_edge/seven(get_turf(user), user.dir)

	// Hit 4 (FINISHER): Dash THROUGH, double damage + Fragile + knockback
	sleep(0.5 SECONDS)
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
		return
	SevenComboDash(user, target, TRUE)
	sleep(0.3 SECONDS)
	if(QDELETED(target) || QDELETED(user))
		return
	user.do_attack_animation(target)
	playsound(target, 'sound/weapons/rapierhit.ogg', 80, TRUE, 8)
	target.deal_damage(hit_damage * 2, BLACK_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
	target.apply_lc_offense_level_down(2)
	target.apply_lc_fragile(5)
	new /obj/effect/temp_visual/dir_setting/gray_edge/seven/passthrough(get_turf(target), user.dir)
	shake_camera(target, 3, 3)
	// Clean up cutscene duel
	qdel(target.GetComponent(/datum/component/cutscene_duel))
	if(!QDELETED(user))
		user.say(pick("Case closed.", "Every weakness, accounted for.", "Dossier complete."))

// ============================================================
// T3b: Surveillance Network
// ============================================================
/// AoE damage when Rupture triggers. Rupture spread on kill.
/datum/component/association_skill/seven_surveillance_network
	skill_name = "Surveillance Network"
	skill_desc = "When Rupture triggers on attacked targets, deals AoE BLACK. On kill, spreads 15 Rupture to nearby enemies."
	branch = "Analyst"
	tier = 3
	choice = "b"
	/// Mobs we have rupture/death signals registered on
	var/list/watched_mobs = list()

/datum/component/association_skill/seven_surveillance_network/Destroy()
	for(var/mob/living/L in watched_mobs)
		UnregisterSignal(L, list(COMSIG_RUPTURE_TRIGGERED, COMSIG_LIVING_DEATH))
	watched_mobs.Cut()
	return ..()

/datum/component/association_skill/seven_surveillance_network/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	// Register signals on the target if not already watching
	if(!(target in watched_mobs))
		RegisterSignal(target, COMSIG_RUPTURE_TRIGGERED, PROC_REF(on_rupture_trigger))
		RegisterSignal(target, COMSIG_LIVING_DEATH, PROC_REF(on_target_death))
		watched_mobs += target

/// When a watched target's Rupture triggers, deal AoE BLACK damage.
/datum/component/association_skill/seven_surveillance_network/proc/on_rupture_trigger(datum/source, stacks_before)
	SIGNAL_HANDLER
	var/mob/living/target = source
	// Check if this is our marked target for the damage multiplier
	var/datum/action/cooldown/seven_mark_target/mark = get_seven_mark_action(human_parent)
	var/is_marked = (mark && target == mark.get_marked())
	var/aoe_damage = stacks_before
	if(is_marked)
		aoe_damage *= 2
	INVOKE_ASYNC(src, PROC_REF(do_rupture_aoe), target, aoe_damage)

/// Apply AoE BLACK damage around the target.
/datum/component/association_skill/seven_surveillance_network/proc/do_rupture_aoe(mob/living/target, base_damage)
	for(var/mob/living/L in range(3, get_turf(target)))
		if(L == target || L == human_parent || is_designated_ally(L))
			continue
		var/damage = base_damage
		if(!ishuman(L))
			damage *= 4
		L.deal_damage(damage, BLACK_DAMAGE, human_parent, DAMAGE_FORCED, ATTACK_TYPE_SPECIAL)

/// When a watched target dies, spread Rupture to nearby enemies.
/datum/component/association_skill/seven_surveillance_network/proc/on_target_death(datum/source)
	SIGNAL_HANDLER
	var/mob/living/dead_mob = source
	// Clean up signals
	UnregisterSignal(dead_mob, list(COMSIG_RUPTURE_TRIGGERED, COMSIG_LIVING_DEATH))
	watched_mobs -= dead_mob
	INVOKE_ASYNC(src, PROC_REF(do_death_rupture_spread), dead_mob)

/// Spread 15 Rupture to enemies near the dead mob.
/datum/component/association_skill/seven_surveillance_network/proc/do_death_rupture_spread(mob/living/dead_mob)
	for(var/mob/living/L in range(3, get_turf(dead_mob)))
		if(L == dead_mob || L == human_parent || is_designated_ally(L))
			continue
		L.apply_lc_rupture(15)
