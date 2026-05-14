// ============================================================
// Dieci Association — Sage Branch
// ============================================================
// Theme: Knowledge economy maximization. Preferred type: Spiritual.
// 6 skills across 3 tiers (T1a/T1b, T2a/T2b, T3a/T3b).

// ============================================================
// T1a: Extensive Notes
// ============================================================
// Max knowledge 20→30. H attacks +15% PALE. 5s CD: consume 1 Spiritual → +5%/level.

/// Sage T1a — Increases knowledge capacity and adds bonus PALE damage to heavy attacks.
/datum/component/association_skill/dieci_extensive_notes
	skill_name = "Extensive Notes"
	skill_desc = "Max knowledge +10 (to 30). H attacks deal +15% PALE bonus damage. On H attack, can consume 1 Spiritual for +5%/level extra PALE (5s cooldown)."
	branch = "Sage"
	tier = 1
	choice = "a"
	/// Cooldown tracker for knowledge consumption
	var/last_consume = 0

/datum/component/association_skill/dieci_extensive_notes/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	var/datum/component/dieci_knowledge/kc = human_parent.GetComponent(/datum/component/dieci_knowledge)
	if(kc)
		kc.max_knowledge = max(kc.max_knowledge, 30)

/datum/component/association_skill/dieci_extensive_notes/Destroy()
	if(human_parent)
		var/datum/component/dieci_knowledge/kc = human_parent.GetComponent(/datum/component/dieci_knowledge)
		if(kc)
			// Only reduce if Infinite Library isn't also boosting
			var/datum/component/association_skill/dieci_infinite_library/inf = human_parent.GetComponent(/datum/component/association_skill/dieci_infinite_library)
			if(!inf)
				kc.max_knowledge = DIECI_MAX_KNOWLEDGE
	return ..()

/datum/component/association_skill/dieci_extensive_notes/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
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
	// Base: +15% PALE bonus
	var/bonus_pct = 0.15
	// 5s CD: consume 1 Spiritual for +5%/level
	if(world.time >= last_consume + 5 SECONDS)
		var/datum/component/dieci_knowledge/kc = human_parent.GetComponent(/datum/component/dieci_knowledge)
		if(kc && !kc.conserve_knowledge)
			var/list/consumed = kc.consume_lowest_of_type(DIECI_KNOWLEDGE_TYPE_SPIRITUAL)
			if(consumed)
				last_consume = world.time
				bonus_pct += consumed["level"] * 0.05
	var/bonus_damage = item.force * bonus_pct
	if(bonus_damage > 0)
		INVOKE_ASYNC(target, TYPE_PROC_REF(/mob/living, deal_damage), bonus_damage, PALE_DAMAGE, human_parent, DAMAGE_FORCED)

// ============================================================
// T1b: Applied Learning
// ============================================================
// Any knowledge consumption → 4 OLU.

/// Sage T1b — Passive that grants Offense Level Up whenever knowledge is consumed.
/datum/component/association_skill/dieci_applied_learning
	skill_name = "Applied Learning"
	skill_desc = "Passive: whenever any knowledge entry is consumed, gain 4 Offense Level Up."
	branch = "Sage"
	tier = 1
	choice = "b"

/datum/component/association_skill/dieci_applied_learning/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	var/datum/component/dieci_knowledge/kc = human_parent.GetComponent(/datum/component/dieci_knowledge)
	if(kc)
		kc.on_knowledge_consumed = CALLBACK(src, PROC_REF(on_consume))

/datum/component/association_skill/dieci_applied_learning/Destroy()
	if(human_parent)
		var/datum/component/dieci_knowledge/kc = human_parent.GetComponent(/datum/component/dieci_knowledge)
		if(kc && kc.on_knowledge_consumed)
			kc.on_knowledge_consumed = null
	return ..()

/// Called when any knowledge entry is consumed. Grants 4 OLU.
/datum/component/association_skill/dieci_applied_learning/proc/on_consume(list/entry)
	if(!can_use_skill())
		return
	if(QDELETED(human_parent))
		return
	human_parent.apply_lc_offense_level_up(4)

// ============================================================
// T2a: Shared Wisdom
// ============================================================
// Action (15s CD): click ally → consume 1 highest Spiritual → ally gets level*2 OLU.

/// Sage T2a — Grants a targeted action that buffs allies with Offense Level Up via Spiritual knowledge.
/datum/component/association_skill/dieci_shared_wisdom
	skill_name = "Shared Wisdom"
	skill_desc = "Action (15s CD): click an ally within 5 tiles. Consumes highest Spiritual knowledge, granting them level x2 Offense Level Up."
	branch = "Sage"
	tier = 2
	choice = "a"
	/// The granted action
	var/datum/action/cooldown/dieci_shared_wisdom_action/wisdom_action

/datum/component/association_skill/dieci_shared_wisdom/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	wisdom_action = new()
	wisdom_action.Grant(human_parent)

/datum/component/association_skill/dieci_shared_wisdom/Destroy()
	if(wisdom_action && human_parent)
		wisdom_action.Remove(human_parent)
	wisdom_action = null
	return ..()

/// Action for Shared Wisdom — 15s cooldown targeted ally buff.
/datum/action/cooldown/dieci_shared_wisdom_action
	name = "Shared Wisdom"
	desc = "Click an ally to consume Spiritual knowledge and grant them Offense Level Up."
	icon_icon = 'icons/hud/screen_assoc_trees.dmi'
	button_icon_state = "spend_knowledge"
	cooldown_time = 15 SECONDS
	/// Whether we are in targeting mode
	var/targeting = FALSE
	/// Targeting range
	var/target_range = 5

/datum/action/cooldown/dieci_shared_wisdom_action/Trigger()
	. = ..()
	if(!.)
		return FALSE
	if(!ishuman(owner))
		return FALSE
	// Toggle targeting mode
	if(targeting)
		deactivate_targeting()
		return TRUE
	// Check skill usability before entering targeting
	var/datum/component/association_skill/dieci_shared_wisdom/skill = owner.GetComponent(/datum/component/association_skill/dieci_shared_wisdom)
	if(!skill || !skill.can_use_skill())
		to_chat(owner, span_warning("You cannot use this skill right now."))
		return FALSE
	activate_targeting()
	return TRUE

/// Enter targeting mode.
/datum/action/cooldown/dieci_shared_wisdom_action/proc/activate_targeting()
	if(!owner || !owner.client)
		return
	targeting = TRUE
	owner.click_intercept = src
	owner.client.mouse_override_icon = 'icons/effects/mouse_pointers/throw_target.dmi'
	owner.update_mouse_pointer()
	to_chat(owner, span_notice("Click an ally to share wisdom. Click again to cancel."))

/// Exit targeting mode.
/datum/action/cooldown/dieci_shared_wisdom_action/proc/deactivate_targeting()
	targeting = FALSE
	if(owner)
		if(owner.click_intercept == src)
			owner.click_intercept = null
		if(owner.client)
			owner.client.mouse_override_icon = null
			owner.update_mouse_pointer()

/// Called when the owner clicks while targeting.
/datum/action/cooldown/dieci_shared_wisdom_action/proc/InterceptClickOn(mob/living/user, params, atom/target)
	deactivate_targeting()
	// Validate target
	if(!isliving(target) || target == owner)
		to_chat(owner, span_warning("Invalid target."))
		return TRUE
	var/mob/living/ally = target
	if(!(ally in view(target_range, get_turf(owner))))
		to_chat(owner, span_warning("Target is too far away."))
		return TRUE
	// Check skill usability
	var/datum/component/association_skill/dieci_shared_wisdom/skill = owner.GetComponent(/datum/component/association_skill/dieci_shared_wisdom)
	if(!skill || !skill.can_use_skill())
		to_chat(owner, span_warning("You cannot use this skill right now."))
		return TRUE
	// Consume 1 highest Spiritual knowledge
	var/datum/component/dieci_knowledge/kc = owner.GetComponent(/datum/component/dieci_knowledge)
	if(!kc)
		to_chat(owner, span_warning("No knowledge system available."))
		return TRUE
	var/list/consumed = kc.consume_highest_of_type(DIECI_KNOWLEDGE_TYPE_SPIRITUAL)
	if(!consumed)
		to_chat(owner, span_warning("No Spiritual knowledge available."))
		return TRUE
	// Grant OLU to ally
	var/olu_amount = consumed["level"] * 2
	ally.apply_lc_offense_level_up(olu_amount)
	to_chat(owner, span_nicegreen("Shared Wisdom! [ally.name] gains [olu_amount] Offense Level Up!"))
	to_chat(ally, span_nicegreen("You feel knowledge flow into you! +[olu_amount] Offense Level Up!"))
	StartCooldown()
	return TRUE

// ============================================================
// T2b: Efficient Research
// ============================================================
// Synthesis costs 2. L3+ consumption refunds 1 at level-1.
// 5s CD: consume 1 Spiritual → 2 OLU to allies in 3 tiles.

/// Sage T2b — Passive that improves knowledge economy and periodically buffs nearby allies.
/datum/component/association_skill/dieci_efficient_research
	skill_name = "Efficient Research"
	skill_desc = "Passive: synthesis costs 2 instead of 3. Consuming L3+ knowledge refunds 1 entry at level-1. On attack, can consume 1 Spiritual to grant 2 OLU to allies within 3 tiles (5s cooldown)."
	branch = "Sage"
	tier = 2
	choice = "b"
	/// Cooldown tracker for knowledge consumption
	var/last_consume = 0

/datum/component/association_skill/dieci_efficient_research/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	var/datum/component/dieci_knowledge/kc = human_parent.GetComponent(/datum/component/dieci_knowledge)
	if(kc)
		kc.synthesis_cost = 2
		kc.efficient_refund = TRUE

/datum/component/association_skill/dieci_efficient_research/Destroy()
	if(human_parent)
		var/datum/component/dieci_knowledge/kc = human_parent.GetComponent(/datum/component/dieci_knowledge)
		if(kc)
			kc.synthesis_cost = initial(kc.synthesis_cost)
			kc.efficient_refund = initial(kc.efficient_refund)
	return ..()

/datum/component/association_skill/dieci_efficient_research/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	if(!istype(target) || QDELETED(target))
		return
	// 5s CD: consume 1 lowest Spiritual → 2 OLU to allies in 3 tiles
	if(world.time < last_consume + 5 SECONDS)
		return
	var/datum/component/dieci_knowledge/kc = human_parent.GetComponent(/datum/component/dieci_knowledge)
	if(!kc || kc.conserve_knowledge)
		return
	var/list/consumed = kc.consume_lowest_of_type(DIECI_KNOWLEDGE_TYPE_SPIRITUAL)
	if(!consumed)
		return
	last_consume = world.time
	INVOKE_ASYNC(src, PROC_REF(buff_nearby_allies))

/// Apply 2 OLU to allies within 3 tiles.
/datum/component/association_skill/dieci_efficient_research/proc/buff_nearby_allies()
	for(var/mob/living/L in range(3, get_turf(human_parent)))
		if(L == human_parent || L.stat == DEAD)
			continue
		L.apply_lc_offense_level_up(2)

// ============================================================
// T3a: Grand Archive
// ============================================================
// 90s CD action. Consume up to 5 highest knowledge → rush target.
// N hits sorted low→high. All RED except final PALE. Per-hit: Sinking = level*2. Final: 1.25x + Sinking = level*4.

/// Sage T3a — Grants a powerful attack action that hurls knowledge at the target for a scaling multi-hit combo.
/datum/component/association_skill/dieci_grand_archive
	skill_name = "Grand Archive"
	skill_desc = "Action (costs Adrenaline): consume up to 5 highest knowledge. Dash to target for N-hit combo (sorted low to high). Hits deal RED + Sinking = level x2. Final hit: PALE at 1.25x + Sinking = level x4."
	branch = "Sage"
	tier = 3
	choice = "a"
	/// The granted action
	var/datum/action/cooldown/dieci_grand_archive_action/combo_action

/datum/component/association_skill/dieci_grand_archive/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	combo_action = new()
	combo_action.Grant(human_parent)

/datum/component/association_skill/dieci_grand_archive/Destroy()
	if(combo_action && human_parent)
		combo_action.Remove(human_parent)
	combo_action = null
	return ..()

/// Action for Grand Archive — adrenaline-powered powerful attack.
/datum/action/cooldown/dieci_grand_archive_action
	name = "Grand Archive"
	desc = "Consume up to 5 highest knowledge entries, then rush the target for a multi-hit combo scaling with consumed levels. Costs 100 Adrenaline."
	icon_icon = 'icons/hud/screen_assoc_trees.dmi'
	button_icon_state = "dieci_t3"
	cooldown_time = 0

/datum/action/cooldown/dieci_grand_archive_action/Trigger()
	. = ..()
	if(!.)
		return FALSE
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/user = owner
	// Find target in view
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
	var/datum/component/association_skill/dieci_grand_archive/skill = user.GetComponent(/datum/component/association_skill/dieci_grand_archive)
	if(!skill || !skill.can_use_skill())
		to_chat(user, span_warning("You cannot use this skill right now."))
		return FALSE
	// Need at least 1 knowledge to consume
	var/datum/component/dieci_knowledge/kc = user.GetComponent(/datum/component/dieci_knowledge)
	if(!kc || kc.get_knowledge_count() <= 0)
		to_chat(user, span_warning("No knowledge available to consume."))
		return FALSE
	// Check adrenaline
	var/datum/component/association_exp/exp = user.GetComponent(/datum/component/association_exp)
	if(!exp || !exp.has_enough_adrenaline())
		to_chat(user, span_warning("Not enough adrenaline! ([exp ? exp.adrenaline : 0]/[exp ? exp.max_adrenaline : 100])"))
		return FALSE
	exp.consume_adrenaline()
	INVOKE_ASYNC(src, PROC_REF(ExecuteCombo), target, user)
	return TRUE

/// Execute the Grand Archive combo sequence.
/datum/action/cooldown/dieci_grand_archive_action/proc/ExecuteCombo(mob/living/target, mob/living/carbon/human/user)
	// Consume up to 5 highest knowledge entries
	var/datum/component/dieci_knowledge/kc = user.GetComponent(/datum/component/dieci_knowledge)
	var/list/consumed_entries = list()
	if(kc)
		for(var/i in 1 to 5)
			var/list/consumed = kc.consume_highest_knowledge()
			if(!consumed)
				break
			consumed_entries += list(consumed)
	var/num_hits = length(consumed_entries)
	if(num_hits <= 0)
		return

	// Sort consumed by level ascending (bubble sort, small list)
	for(var/i in 1 to num_hits - 1)
		for(var/j in 1 to num_hits - i)
			if(consumed_entries[j]["level"] > consumed_entries[j + 1]["level"])
				var/list/temp = consumed_entries[j]
				consumed_entries[j] = consumed_entries[j + 1]
				consumed_entries[j + 1] = temp

	// DPS calculation
	var/obj/item/weapon = user.get_active_held_item()
	var/dps = weapon ? (weapon.force * 1.25 / max(weapon.attack_speed, 0.1)) : 30
	var/hit_damage = dps / max(num_hits, 1)

	// Immobilize both
	var/combo_duration = (num_hits + 1) SECONDS
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

	// Dash to target
	DieciComboDash(user, target, FALSE)
	sleep(0.3 SECONDS)

	// Multi-hit combo
	for(var/hit in 1 to num_hits)
		if(QDELETED(target) || QDELETED(user) || target.stat == DEAD)
			break
		var/list/entry = consumed_entries[hit]
		var/entry_level = entry["level"]
		var/is_final = (hit == num_hits)

		user.do_attack_animation(target)
		if(is_final)
			// Final hit: PALE + 1.25x damage + Sinking = level*4
			playsound(target, 'sound/weapons/fixer/generic/finisher2.ogg', 80, TRUE, 8)
			target.deal_damage(hit_damage * 1.25, PALE_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
			if(!QDELETED(target))
				target.apply_lc_sinking(entry_level * 4)
			new /obj/effect/temp_visual/dir_setting/gray_edge/dieci(get_turf(user), user.dir)
			shake_camera(target, 3, 3)
		else
			// Normal hits: RED + Sinking = level*2
			playsound(target, 'sound/weapons/fixer/generic/fist1.ogg', 60, TRUE, 6)
			target.deal_damage(hit_damage, RED_DAMAGE, user, DAMAGE_FORCED, ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)
			if(!QDELETED(target))
				target.apply_lc_sinking(entry_level * 2)
			new /obj/effect/temp_visual/dir_setting/gray_edge/dieci(get_turf(user), user.dir)

		if(!is_final)
			sleep(0.5 SECONDS)

	// Clean up
	if(!QDELETED(target))
		qdel(target.GetComponent(/datum/component/cutscene_duel))
	if(!QDELETED(user))
		user.say(pick("All recorded. All returned.", "The archive speaks.", "Knowledge is the ultimate weapon."))

// ============================================================
// T3b: Infinite Library
// ============================================================
// Max knowledge →50. L attacks consume lowest knowledge → Sinking = level. 1s CD.

/// Sage T3b — Massively increases knowledge capacity and converts L attacks into knowledge-fueled Sinking.
/datum/component/association_skill/dieci_infinite_library
	skill_name = "Infinite Library"
	skill_desc = "Max knowledge +30 (to 50). L attacks (1s CD) consume 1 lowest knowledge, applying Sinking = consumed level."
	branch = "Sage"
	tier = 3
	choice = "b"
	/// Cooldown tracker
	var/last_trigger = 0

/datum/component/association_skill/dieci_infinite_library/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return
	var/datum/component/dieci_knowledge/kc = human_parent.GetComponent(/datum/component/dieci_knowledge)
	if(kc)
		kc.max_knowledge = 50

/datum/component/association_skill/dieci_infinite_library/Destroy()
	if(human_parent)
		var/datum/component/dieci_knowledge/kc = human_parent.GetComponent(/datum/component/dieci_knowledge)
		if(kc)
			// Check if Extensive Notes is also present
			var/datum/component/association_skill/dieci_extensive_notes/ext = human_parent.GetComponent(/datum/component/association_skill/dieci_extensive_notes)
			if(ext)
				kc.max_knowledge = 30
			else
				kc.max_knowledge = DIECI_MAX_KNOWLEDGE
	return ..()

/datum/component/association_skill/dieci_infinite_library/on_attack(datum/source, mob/living/target, mob/living/user, obj/item/item)
	if(!can_use_skill())
		return
	if(!istype(target) || QDELETED(target))
		return
	// Only L attacks (not H, not during sequence)
	if(!istype(item, /obj/item/ego_weapon/city/dieci))
		return
	var/obj/item/ego_weapon/city/dieci/D = item
	if(D.activated || D.in_sequence)
		return
	// 1s CD
	if(world.time < last_trigger + 1 SECONDS)
		return
	// Consume 1 lowest knowledge (any type)
	var/datum/component/dieci_knowledge/kc = human_parent.GetComponent(/datum/component/dieci_knowledge)
	if(!kc || kc.conserve_knowledge)
		return
	var/list/consumed = kc.consume_lowest_knowledge(1)
	if(!length(consumed))
		return
	last_trigger = world.time
	var/level = consumed[1]["level"]
	INVOKE_ASYNC(target, TYPE_PROC_REF(/mob/living, apply_lc_sinking), level)
