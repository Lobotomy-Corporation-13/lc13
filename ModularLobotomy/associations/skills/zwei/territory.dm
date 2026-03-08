// ============================================================
// Zwei Association — Territory Protection Branch
// ============================================================
// Area defense, ally buffing, zone-based bonuses.

/// Helper: Check if an atom is standing on a contract zone tile.
/proc/is_in_contract_zone(atom/A)
	var/turf/T = get_turf(A)
	if(!T)
		return FALSE
	for(var/obj/effect/contract_zone/zone in T)
		return TRUE
	return FALSE

// ============================================================
// T1a: Vigilant Presence
// ============================================================
/// When you take damage, allies within 4 tiles gain 2 Defense Level Up. 1s internal CD.
/datum/component/association_skill/zwei_vigilant_presence
	skill_name = "Vigilant Presence"
	skill_desc = "When you take damage, allies within 4 tiles gain 2 Defense Level Up stacks. 1 second cooldown."
	branch = "Territory Protection"
	tier = 1
	choice = "a"
	/// Internal cooldown tracker
	var/last_trigger = 0

/datum/component/association_skill/zwei_vigilant_presence/on_after_take_damage(datum/source, damage, damagetype, def_zone, wound_bonus, bare_wound_bonus, sharpness, attacker)
	if(!can_use_skill())
		return
	if(isliving(attacker) && is_association_member(attacker))
		return
	if(world.time < last_trigger + 1 SECONDS)
		return
	last_trigger = world.time
	INVOKE_ASYNC(src, PROC_REF(buff_nearby_allies))

/// Apply DLU to nearby allies.
/datum/component/association_skill/zwei_vigilant_presence/proc/buff_nearby_allies()
	for(var/mob/living/L in range(4, get_turf(human_parent)))
		if(L == human_parent)
			continue
		if(!is_designated_ally(L))
			continue
		L.apply_lc_defense_level_up(2)

// ============================================================
// T1b: Warden's Watch
// ============================================================
/// +15% damage vs mobs in contracted area (+25% if targeting you). +10% vs carbons in contracted area.
/datum/component/association_skill/zwei_wardens_watch
	skill_name = "Warden's Watch"
	skill_desc = "+15% damage vs mobs in contracted area (+25% if targeting you). +10% damage vs carbons in contracted area."
	branch = "Territory Protection"
	tier = 1
	choice = "b"

/datum/component/association_skill/zwei_wardens_watch/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	if(is_association_member(target))
		return
	if(!item)
		return
	// Must be in contract zone
	if(!is_in_contract_zone(user))
		return
	var/bonus_pct = 0
	if(isanimal(target))
		// Check if mob is targeting us
		var/mob/living/simple_animal/hostile/H = target
		if(istype(H) && H.target == human_parent)
			bonus_pct = 0.25
		else
			bonus_pct = 0.15
	else if(iscarbon(target))
		bonus_pct = 0.10
	if(bonus_pct > 0)
		var/bonus_damage = item.force * bonus_pct
		INVOKE_ASYNC(target, TYPE_PROC_REF(/mob/living, deal_damage), bonus_damage, RED_DAMAGE, human_parent, DAMAGE_FORCED)

// ============================================================
// T2a: Law and Order
// ============================================================
/// When you take damage, gain Protection stacks scaling with damage (1 per 15 dmg, up to 5). 12s CD.
/datum/component/association_skill/zwei_law_and_order
	skill_name = "Law and Order"
	skill_desc = "When you take damage, gain Protection stacks scaling with damage received (1 per 15 damage, up to 5). 12 second cooldown."
	branch = "Territory Protection"
	tier = 2
	choice = "a"
	/// Internal cooldown tracker
	var/last_trigger = 0

/datum/component/association_skill/zwei_law_and_order/on_after_take_damage(datum/source, damage, damagetype, def_zone, wound_bonus, bare_wound_bonus, sharpness, attacker)
	if(!can_use_skill())
		return
	if(isliving(attacker) && is_association_member(attacker))
		return
	if(world.time < last_trigger + 12 SECONDS)
		return
	last_trigger = world.time
	var/stacks = min(5, CEILING(damage / 15, 1))
	if(stacks > 0)
		INVOKE_ASYNC(human_parent, TYPE_PROC_REF(/mob/living, apply_lc_protection), stacks)

// ============================================================
// T2b: Fortified Position
// ============================================================
/// Attacks grant 2 DLU. Consecutive hits from same tile grant +3 additional per hit. Moving resets.
/datum/component/association_skill/zwei_fortified_position
	skill_name = "Fortified Position"
	skill_desc = "Attacks grant 2 Defense Level Up. Consecutive hits from the same tile grant +3 additional stacks per hit. Moving resets the bonus."
	branch = "Territory Protection"
	tier = 2
	choice = "b"
	/// Last tile we attacked from
	var/turf/last_attack_turf
	/// Number of consecutive hits from the same tile
	var/consecutive_hits = 0

/datum/component/association_skill/zwei_fortified_position/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	if(is_association_member(target))
		return
	var/turf/current_turf = get_turf(human_parent)
	if(current_turf == last_attack_turf)
		consecutive_hits++
	else
		consecutive_hits = 1
		last_attack_turf = current_turf
	// Base 2 + (consecutive_hits - 1) * 3: 1st = 2, 2nd = 5, 3rd = 8, 4th = 11...
	var/stacks = 2 + (consecutive_hits - 1) * 3
	INVOKE_ASYNC(human_parent, TYPE_PROC_REF(/mob/living, apply_lc_defense_level_up), stacks)

// ============================================================
// T3a: Earthshatter
// ============================================================
/// Grants a powerful attack action. AoE slam + combo on closest enemy.
/datum/component/association_skill/zwei_earthshatter
	skill_name = "Earthshatter"
	skill_desc = "Grants a powerful attack action (costs Adrenaline). AoE ground slam, then combo on closest enemy."
	branch = "Territory Protection"
	tier = 3
	choice = "a"
	/// Reference to the granted action
	var/datum/action/cooldown/zwei_earthshatter_action/combo_action

/datum/component/association_skill/zwei_earthshatter/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	combo_action = new()
	combo_action.Grant(human_parent)

/datum/component/association_skill/zwei_earthshatter/Destroy()
	if(combo_action && human_parent)
		combo_action.Remove(human_parent)
	combo_action = null
	return ..()

/// Earthshatter action — adrenaline-powered AoE powerful attack.
/datum/action/cooldown/zwei_earthshatter_action
	name = "Earthshatter"
	desc = "AoE ground slam in a 3-tile radius, then combo the closest enemy. More hits in contracted area. Allies grant bonus hits. Costs 100 Adrenaline."
	icon_icon = 'icons/hud/screen_assoc_trees.dmi'
	button_icon_state = "zwei_t3"
	cooldown_time = 0

/datum/action/cooldown/zwei_earthshatter_action/Trigger()
	. = ..()
	if(!.)
		return FALSE
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/user = owner
	// Check skill usability
	var/datum/component/association_skill/zwei_earthshatter/skill = user.GetComponent(/datum/component/association_skill/zwei_earthshatter)
	if(!skill || !skill.can_use_skill())
		to_chat(user, span_warning("You cannot use this skill right now."))
		return FALSE
	// Check adrenaline
	var/datum/component/association_exp/exp = user.GetComponent(/datum/component/association_exp)
	if(!exp || !exp.has_enough_adrenaline())
		to_chat(user, span_warning("Not enough adrenaline! ([exp ? exp.adrenaline : 0]/[exp ? exp.max_adrenaline : 100])"))
		return FALSE
	exp.consume_adrenaline()
	INVOKE_ASYNC(src, PROC_REF(ExecuteCombo), user, skill)
	return TRUE

/datum/action/cooldown/zwei_earthshatter_action/proc/ExecuteCombo(mob/living/carbon/human/user, datum/component/association_skill/zwei_earthshatter/skill)
	// DPS calculation
	var/obj/item/weapon = user.get_active_held_item()
	var/dps = weapon ? (weapon.force * 1.25 / max(weapon.attack_speed, 0.1)) : 30

	// Phase 1: AoE ground slam
	playsound(user, 'sound/weapons/thudswoosh.ogg', 80, TRUE, 8)
	new /obj/effect/temp_visual/smash_effect(get_turf(user))
	shake_camera(user, 2, 2)

	var/mob/living/combo_target
	var/closest_dist = 999
	for(var/mob/living/L in range(3, get_turf(user)))
		if(L == user || skill.is_designated_ally(L))
			continue
		if(L.stat == DEAD)
			continue
		// AoE damage
		L.deal_damage(dps * 0.5, RED_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
		// Track closest for combo target
		var/d = get_dist(user, L)
		if(d < closest_dist)
			closest_dist = d
			combo_target = L

	if(!combo_target || QDELETED(combo_target) || combo_target.stat == DEAD)
		return

	sleep(0.5 SECONDS)
	if(QDELETED(user) || QDELETED(combo_target))
		return

	// Calculate hit count: base 3 (6 in zone), +1 per ally in range(5) up to +3
	var/in_zone = is_in_contract_zone(user)
	var/base_hits = in_zone ? 6 : 3
	var/ally_bonus = 0
	for(var/mob/living/A in range(5, get_turf(user)))
		if(A == user)
			continue
		if(skill.is_designated_ally(A))
			ally_bonus++
	ally_bonus = min(ally_bonus, 3)
	var/total_hits = base_hits + ally_bonus

	var/hit_damage = dps * 0.5

	// Immobilize both for combo
	var/combo_duration = (total_hits * 0.6 + 0.5) SECONDS
	user.Immobilize(combo_duration)
	user.changeNext_move(combo_duration)
	if(isanimal(combo_target))
		var/mob/living/simple_animal/hostile/H = combo_target
		if(istype(H))
			H.toggle_ai(AI_OFF)
			addtimer(CALLBACK(H, TYPE_PROC_REF(/mob/living/simple_animal/hostile, toggle_ai), AI_ON), combo_duration)
	else if(ishuman(combo_target))
		combo_target.Immobilize(combo_duration)

	// Cutscene duel — block outside damage during combo
	combo_target.AddComponent(/datum/component/cutscene_duel, user)

	// Dash to target
	ZweiComboDash(user, combo_target, FALSE)

	// Execute hits
	var/i = 0
	for(i = 1 to total_hits)
		sleep(0.4 SECONDS)
		if(QDELETED(combo_target) || QDELETED(user) || combo_target.stat == DEAD)
			qdel(combo_target.GetComponent(/datum/component/cutscene_duel))
			return
		user.do_attack_animation(combo_target)
		playsound(combo_target, 'sound/weapons/rapierhit.ogg', 60, TRUE, 6)
		if(i == total_hits)
			// Final hit: 5 DLU to self
			combo_target.deal_damage(hit_damage, RED_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
			combo_target.apply_lc_defense_level_down(2)
			user.apply_lc_defense_level_up(5)
			new /obj/effect/temp_visual/dir_setting/gray_cube_v1/zwei(get_turf(user), user.dir)
			shake_camera(combo_target, 3, 3)
		else
			// Regular hit: 0.5x DPS, 2 DLD to target, 3 DLU to self
			combo_target.deal_damage(hit_damage, RED_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
			combo_target.apply_lc_defense_level_down(2)
			user.apply_lc_defense_level_up(3)
			new /obj/effect/temp_visual/dir_setting/gray_cube_v1/zwei(get_turf(user), user.dir)

	// Clean up cutscene duel
	qdel(combo_target.GetComponent(/datum/component/cutscene_duel))
	if(!QDELETED(user))
		user.say(pick("The ground shakes beneath you!", "Hold the line!", "This is OUR territory!"))

// ============================================================
// T3b: Iron Curtain
// ============================================================
/// While in contracted area, absorb 25% of damage dealt to allies within 4 tiles.
/// Redirected to you at 50% effectiveness (12.5% of original).
/datum/component/association_skill/zwei_iron_curtain
	skill_name = "Iron Curtain"
	skill_desc = "While in contracted area, absorb 25% of damage dealt to allies within 4 tiles. You take the redirected damage at 50% effectiveness."
	branch = "Territory Protection"
	tier = 3
	choice = "b"
	/// List of allies we are currently watching
	var/list/mob/living/watching_allies = list()

/datum/component/association_skill/zwei_iron_curtain/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	START_PROCESSING(SSobj, src)
	refresh_ally_signals()

/datum/component/association_skill/zwei_iron_curtain/Destroy()
	STOP_PROCESSING(SSobj, src)
	unregister_all_allies()
	return ..()

/// Process every 5 seconds to sync ally list with current designated allies.
/datum/component/association_skill/zwei_iron_curtain/process(seconds_per_tick)
	refresh_ally_signals()

/// Register damage signals on all designated allies.
/datum/component/association_skill/zwei_iron_curtain/proc/refresh_ally_signals()
	if(!human_parent || QDELETED(human_parent))
		return
	var/datum/component/association_exp/exp = get_exp_component()
	if(!exp)
		return
	// Unregister from allies no longer designated
	for(var/mob/living/ally in watching_allies)
		if(!(ally in exp.designated_allies))
			UnregisterSignal(ally, COMSIG_MOB_AFTER_APPLY_DAMGE)
			watching_allies -= ally
	// Register on new allies
	for(var/mob/living/ally in exp.designated_allies)
		if(!(ally in watching_allies))
			RegisterSignal(ally, COMSIG_MOB_AFTER_APPLY_DAMGE, PROC_REF(on_ally_damaged))
			watching_allies += ally

/// Unregister from all watched allies.
/datum/component/association_skill/zwei_iron_curtain/proc/unregister_all_allies()
	for(var/mob/living/ally in watching_allies)
		UnregisterSignal(ally, COMSIG_MOB_AFTER_APPLY_DAMGE)
	watching_allies.Cut()

/// Signal handler: an ally took damage.
/datum/component/association_skill/zwei_iron_curtain/proc/on_ally_damaged(datum/source, damage, damagetype, def_zone, wound_bonus, bare_wound_bonus, sharpness, attacker)
	SIGNAL_HANDLER
	if(!can_use_skill())
		return
	if(isliving(attacker) && is_association_member(attacker))
		return
	var/mob/living/ally = source
	if(!ally || QDELETED(ally))
		return
	// Must be in contract zone
	if(!is_in_contract_zone(human_parent))
		return
	// Must be within 4 tiles
	if(get_dist(get_turf(human_parent), get_turf(ally)) > 4)
		return
	// Heal ally for 25% of damage, take 12.5% ourselves
	var/heal_amount = damage * 0.25
	var/self_damage = damage * 0.125
	INVOKE_ASYNC(src, PROC_REF(apply_iron_curtain), ally, heal_amount, self_damage, damagetype)

/// Apply Iron Curtain — heal ally, damage self.
/datum/component/association_skill/zwei_iron_curtain/proc/apply_iron_curtain(mob/living/ally, heal_amount, self_damage, damagetype)
	if(!ally || QDELETED(ally) || !human_parent || QDELETED(human_parent))
		return
	// Heal the ally (generic heal since we don't know the specific limb)
	ally.adjustBruteLoss(-heal_amount)
	// Take the redirected damage ourselves
	human_parent.deal_damage(self_damage, damagetype, ally, DAMAGE_FORCED)
