// ============================================================
// Dieci Association — Warden Branch
// ============================================================
// Theme: Shield HP enhancement. Preferred type: Medical.
// 6 skills across 3 tiers (T1a/T1b, T2a/T2b, T3a/T3b).

// ============================================================
// T1a: Knowledge Barrier
// ============================================================
// Melee +10 shield HP. 5s CD: consume 1 Medical → +level*8 shield.

/// Warden T1a — Melee attacks build shield HP, enhanced by Medical knowledge consumption.
/datum/component/association_skill/dieci_knowledge_barrier
	skill_name = "Knowledge Barrier"
	skill_desc = "Melee attacks grant +10 shield HP. On hit, can also consume 1 lowest Medical for +level x8 bonus shield (5s cooldown)."
	branch = "Warden"
	tier = 1
	choice = "a"
	/// Cooldown tracker for knowledge consumption
	var/last_consume = 0

/datum/component/association_skill/dieci_knowledge_barrier/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	if(!istype(target) || QDELETED(target))
		return
	// Always grant 10 shield HP
	var/datum/component/dieci_shield_hp/shield = human_parent.GetComponent(/datum/component/dieci_shield_hp)
	if(!shield)
		shield = human_parent.AddComponent(/datum/component/dieci_shield_hp)
	shield.add_shield(10)
	// 5s CD: consume 1 lowest Medical for bonus shield
	if(world.time < last_consume + 5 SECONDS)
		return
	var/datum/component/dieci_knowledge/kc = human_parent.GetComponent(/datum/component/dieci_knowledge)
	if(!kc || kc.conserve_knowledge)
		return
	var/list/consumed = kc.consume_lowest_of_type(DIECI_KNOWLEDGE_TYPE_MEDICAL)
	if(!consumed)
		return
	last_consume = world.time
	shield.add_shield(consumed["level"] * 8)

// ============================================================
// T1b: Reactive Ward
// ============================================================
// Melee +8 shield HP. Shield absorb → 5 Sinking to attacker.

/// Warden T1b — Melee attacks build shield HP. Shield absorption retaliates with Sinking.
/datum/component/association_skill/dieci_reactive_ward
	skill_name = "Reactive Ward"
	skill_desc = "Melee attacks grant +8 shield HP. When your shield absorbs damage, applies 5 Sinking to the attacker."
	branch = "Warden"
	tier = 1
	choice = "b"

/datum/component/association_skill/dieci_reactive_ward/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	// Ensure shield component exists and set up absorb callback
	var/datum/component/dieci_shield_hp/shield = human_parent.GetComponent(/datum/component/dieci_shield_hp)
	if(!shield)
		shield = human_parent.AddComponent(/datum/component/dieci_shield_hp)
	shield.on_shield_absorb = CALLBACK(src, PROC_REF(on_shield_hit))

/datum/component/association_skill/dieci_reactive_ward/Destroy()
	var/datum/component/dieci_shield_hp/shield = human_parent?.GetComponent(/datum/component/dieci_shield_hp)
	if(shield)
		shield.on_shield_absorb = null
	return ..()

/datum/component/association_skill/dieci_reactive_ward/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	if(!istype(target) || QDELETED(target))
		return
	// Grant 8 shield HP
	var/datum/component/dieci_shield_hp/shield = human_parent.GetComponent(/datum/component/dieci_shield_hp)
	if(!shield)
		shield = human_parent.AddComponent(/datum/component/dieci_shield_hp)
	shield.add_shield(8)

/// Called when the shield absorbs damage. Applies Sinking to the attacker.
/datum/component/association_skill/dieci_reactive_ward/proc/on_shield_hit(damage_absorbed, atom/damage_source)
	if(!can_use_skill())
		return
	if(!isliving(damage_source))
		return
	var/mob/living/attacker = damage_source
	if(QDELETED(attacker) || attacker.stat == DEAD)
		return
	attacker.apply_lc_sinking(5)
	new /obj/effect/temp_visual/dir_setting/gray_edge/dieci(get_turf(human_parent), human_parent.dir)

// ============================================================
// T2a: Tome Shield
// ============================================================
// Action (5s CD): consume highest Medical → shield HP = 10*level.

/// Warden T2a — Grants an action that converts Medical knowledge into shield HP.
/datum/component/association_skill/dieci_tome_shield
	skill_name = "Tome Shield"
	skill_desc = "Action (5s CD): consumes highest Medical knowledge, granting level x10 shield HP."
	branch = "Warden"
	tier = 2
	choice = "a"
	/// The granted action
	var/datum/action/cooldown/dieci_tome_shield_action/shield_action

/datum/component/association_skill/dieci_tome_shield/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	shield_action = new()
	shield_action.Grant(human_parent)

/datum/component/association_skill/dieci_tome_shield/Destroy()
	if(shield_action && human_parent)
		shield_action.Remove(human_parent)
	shield_action = null
	return ..()

/// Action for Tome Shield — 5s cooldown knowledge-to-shield conversion.
/datum/action/cooldown/dieci_tome_shield_action
	name = "Tome Shield"
	desc = "Consume your highest Medical knowledge to gain shield HP equal to 10 times the consumed level."
	icon_icon = 'icons/hud/screen_assoc_trees.dmi'
	button_icon_state = "spend_knowledge"
	cooldown_time = 5 SECONDS

/datum/action/cooldown/dieci_tome_shield_action/Trigger()
	. = ..()
	if(!.)
		return FALSE
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/user = owner
	// Check skill usability
	var/datum/component/association_skill/dieci_tome_shield/skill = user.GetComponent(/datum/component/association_skill/dieci_tome_shield)
	if(!skill || !skill.can_use_skill())
		to_chat(user, span_warning("You cannot use this skill right now."))
		return FALSE
	// Consume highest Medical knowledge
	var/datum/component/dieci_knowledge/kc = user.GetComponent(/datum/component/dieci_knowledge)
	if(!kc)
		to_chat(user, span_warning("No knowledge system available."))
		return FALSE
	var/list/consumed = kc.consume_highest_of_type(DIECI_KNOWLEDGE_TYPE_MEDICAL)
	if(!consumed)
		to_chat(user, span_warning("No Medical knowledge available."))
		return FALSE
	// Grant shield HP
	var/shield_amount = consumed["level"] * 10
	var/datum/component/dieci_shield_hp/shield = user.GetComponent(/datum/component/dieci_shield_hp)
	if(!shield)
		shield = user.AddComponent(/datum/component/dieci_shield_hp)
	shield.add_shield(shield_amount)
	to_chat(user, span_nicegreen("Tome Shield! +[shield_amount] shield HP from Medical L[consumed["level"]]!"))
	playsound(user, 'sound/weapons/fixer/generic/parry.ogg', 40, TRUE)
	StartCooldown()
	return TRUE

// ============================================================
// T2b: Stalwart Presence
// ============================================================
// Take damage at 50+ shield: 3 Protection. 5s CD: consume 1 Medical → heal level*2% maxHP.

/// Warden T2b — Taking damage while shielded grants Defense Level Up and periodic Medical knowledge heals.
/datum/component/association_skill/dieci_stalwart_presence
	skill_name = "Stalwart Presence"
	skill_desc = "Taking damage with 50+ shield HP grants 3 Protection. On damage taken, can also consume 1 Medical to heal level x2% of max HP (5s cooldown)."
	branch = "Warden"
	tier = 2
	choice = "b"
	/// Cooldown tracker for knowledge consumption
	var/last_consume = 0

/datum/component/association_skill/dieci_stalwart_presence/on_after_take_damage(datum/source, damage, damagetype, def_zone)
	if(!can_use_skill())
		return
	// Check shield HP >= 50
	var/datum/component/dieci_shield_hp/shield = human_parent.GetComponent(/datum/component/dieci_shield_hp)
	if(!shield || shield.shield_health < 50)
		return
	// Grant 3 Defense Level Up
	INVOKE_ASYNC(human_parent, TYPE_PROC_REF(/mob/living, apply_lc_protection), 3)
	// 5s CD: consume 1 Medical for heal
	if(world.time < last_consume + 5 SECONDS)
		return
	var/datum/component/dieci_knowledge/kc = human_parent.GetComponent(/datum/component/dieci_knowledge)
	if(!kc || kc.conserve_knowledge)
		return
	var/list/consumed = kc.consume_lowest_of_type(DIECI_KNOWLEDGE_TYPE_MEDICAL)
	if(!consumed)
		return
	last_consume = world.time
	var/heal_pct = consumed["level"] * 0.02
	var/heal_amount = round(human_parent.maxHealth * heal_pct)
	if(heal_amount > 0)
		INVOKE_ASYNC(src, PROC_REF(do_heal), heal_amount)

/// Apply healing to the parent mob.
/datum/component/association_skill/dieci_stalwart_presence/proc/do_heal(amount)
	if(QDELETED(human_parent))
		return
	human_parent.adjustBruteLoss(-amount)
	human_parent.adjustFireLoss(-amount)

// ============================================================
// T3a: Golden Aegis
// ============================================================
// 90s CD action. Stomp AoE → 5-hit combo.
// Hits 1-4: consume knowledge → shield = level*20.
// Hit 5: consume up to 200 shield → +0.5%/shield dmg, throw, trigger Sinking.

/// Warden T3a — Grants a powerful shield-building attack that converts shield HP into a devastating finisher.
/datum/component/association_skill/dieci_golden_aegis
	skill_name = "Golden Aegis"
	skill_desc = "Action (costs Adrenaline): stomp to apply 5 Sinking in 3 tiles. 5-hit combo: hits 1-4 deal RED and consume knowledge for level x20 shield. Hit 5: consumes up to 200 shield for +0.5%/point bonus damage, triggers Sinking."
	branch = "Warden"
	tier = 3
	choice = "a"
	/// The granted action
	var/datum/action/cooldown/dieci_golden_aegis_action/combo_action

/datum/component/association_skill/dieci_golden_aegis/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	combo_action = new()
	combo_action.Grant(human_parent)

/datum/component/association_skill/dieci_golden_aegis/Destroy()
	if(combo_action && human_parent)
		combo_action.Remove(human_parent)
	combo_action = null
	return ..()

/// Action for Golden Aegis — adrenaline-powered powerful attack.
/datum/action/cooldown/dieci_golden_aegis_action
	name = "Golden Aegis"
	desc = "Stomp to apply Sinking, then deliver a 5-hit combo that builds and consumes shield HP for massive damage. Costs 100 Adrenaline."
	icon_icon = 'icons/hud/screen_assoc_trees.dmi'
	button_icon_state = "dieci_t3"
	cooldown_time = 0

/datum/action/cooldown/dieci_golden_aegis_action/Trigger()
	. = ..()
	if(!.)
		return FALSE
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/user = owner
	// Find target in melee range
	var/mob/living/target
	for(var/mob/living/L in range(3, get_turf(user)))
		if(L == user || L.stat == DEAD)
			continue
		target = L
		break
	if(!target)
		to_chat(user, span_warning("No valid target nearby."))
		return FALSE
	// Check skill usability
	var/datum/component/association_skill/dieci_golden_aegis/skill = user.GetComponent(/datum/component/association_skill/dieci_golden_aegis)
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

/// Execute the Golden Aegis combo sequence.
/datum/action/cooldown/dieci_golden_aegis_action/proc/ExecuteCombo(mob/living/target, mob/living/carbon/human/user)
	// DPS calculation
	var/obj/item/weapon = user.get_active_held_item()
	var/dps = weapon ? (weapon.force * 1.25 / max(weapon.attack_speed, 0.1)) : 30
	var/hit_damage = dps / 5

	// Stomp AoE: 5 Sinking to enemies in 3-tile radius
	for(var/mob/living/L in range(3, get_turf(user)))
		if(L == user || L.stat == DEAD)
			continue
		L.apply_lc_sinking(5)
	playsound(user, 'sound/effects/meteorimpact.ogg', 60, TRUE, 6)
	shake_camera(user, 2, 2)

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

	// Ensure shield component exists
	var/datum/component/dieci_shield_hp/shield = user.GetComponent(/datum/component/dieci_shield_hp)
	if(!shield)
		shield = user.AddComponent(/datum/component/dieci_shield_hp)
	var/datum/component/dieci_knowledge/kc = user.GetComponent(/datum/component/dieci_knowledge)

	// Dash to target
	DieciComboDash(user, target, FALSE)
	sleep(0.3 SECONDS)

	// Hits 1-4: RED damage + consume knowledge → build shield
	for(var/hit in 1 to 4)
		if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
			break
		user.do_attack_animation(target)
		playsound(target, 'sound/weapons/fixer/generic/fist1.ogg', 60, TRUE, 6)
		target.deal_damage(hit_damage, RED_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
		// Consume knowledge for shield
		if(kc)
			var/list/consumed = kc.consume_highest_knowledge()
			if(consumed)
				shield.add_shield(consumed["level"] * 20)
		new /obj/effect/temp_visual/dir_setting/gray_cube_v1/dieci(get_turf(user), user.dir)
		sleep(0.5 SECONDS)

	// Hit 5 (finisher): consume up to 200 shield for bonus damage
	if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
		if(!QDELETED(target))
			qdel(target.GetComponent(/datum/component/cutscene_duel))
		return

	var/consumed_shield = min(200, shield.shield_health)
	shield.shield_health -= consumed_shield
	if(shield.shield_health <= 0)
		shield.stop_decay()

	var/bonus_multiplier = 1 + consumed_shield * 0.005
	var/finisher_damage = hit_damage * 2 * bonus_multiplier
	user.do_attack_animation(target)
	playsound(target, 'sound/weapons/fixer/generic/finisher2.ogg', 80, TRUE, 8)
	target.deal_damage(finisher_damage, RED_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
	new /obj/effect/temp_visual/dir_setting/gray_cube_v1/dieci(get_turf(user), user.dir)
	shake_camera(target, 3, 3)

	// Trigger Sinking
	if(!QDELETED(target))
		var/datum/status_effect/stacking/sinking/S = target.has_status_effect(/datum/status_effect/stacking/sinking)
		if(S && S.stacks > 0)
			S.trigger_sinking()

	// Clean up
	if(!QDELETED(target))
		qdel(target.GetComponent(/datum/component/cutscene_duel))
	if(!QDELETED(user))
		user.say(pick("An impenetrable wall.", "The golden shield endures.", "Nothing gets through."))

// ============================================================
// T3b: Immovable Library
// ============================================================
// Passive. Attack target with Sinking: consume 1 knowledge → shield = stacks * 2. 4s CD.

/// Warden T3b — Converts target's Sinking into shield HP on hit.
/datum/component/association_skill/dieci_immovable_library
	skill_name = "Immovable Library"
	skill_desc = "On attack (4s CD): if target has Sinking, consumes 1 lowest knowledge and gains shield HP = target's Sinking stacks x2."
	branch = "Warden"
	tier = 3
	choice = "b"
	/// Cooldown tracker
	var/last_trigger = 0

/datum/component/association_skill/dieci_immovable_library/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	if(!istype(target) || QDELETED(target))
		return
	// 4s CD
	if(world.time < last_trigger + 4 SECONDS)
		return
	// Target must have Sinking stacks
	var/datum/status_effect/stacking/sinking/S = target.has_status_effect(/datum/status_effect/stacking/sinking)
	if(!S || S.stacks <= 0)
		return
	// Consume 1 knowledge (any, lowest)
	var/datum/component/dieci_knowledge/kc = human_parent.GetComponent(/datum/component/dieci_knowledge)
	if(!kc)
		return
	var/list/consumed = kc.consume_lowest_knowledge(1)
	if(!length(consumed))
		return
	last_trigger = world.time
	// Grant shield HP = target's Sinking stacks * 2
	var/shield_amount = S.stacks * 2
	var/datum/component/dieci_shield_hp/shield = human_parent.GetComponent(/datum/component/dieci_shield_hp)
	if(!shield)
		shield = human_parent.AddComponent(/datum/component/dieci_shield_hp)
	shield.add_shield(shield_amount)
