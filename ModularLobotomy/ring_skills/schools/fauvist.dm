// Fauvist School Skills
// Theme: Predatory aggression, WHITE/SP damage focus. The beast tears at both body and mind.

// ========== TIER 1 ==========

// Predator's Scent: +15% damage vs bleeding targets
/datum/component/ring_skill/fauvist/predators_scent
	skill_name = "Predator's Scent"
	skill_desc = "+15% damage vs bleeding targets"
	school = "fauvist"
	tier = 1
	choice = "a"

	var/damage_bonus = 15
	var/active_bonus = 0

/datum/component/ring_skill/fauvist/predators_scent/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return

	if(target_is_bleeding(target))
		active_bonus = damage_bonus
		human_parent.extra_damage += active_bonus

/datum/component/ring_skill/fauvist/predators_scent/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_ITEM_AFTERATTACK, PROC_REF(on_afterattack))

/datum/component/ring_skill/fauvist/predators_scent/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_ITEM_AFTERATTACK)
	. = ..()

/datum/component/ring_skill/fauvist/predators_scent/proc/on_afterattack(datum/source, mob/living/target, obj/item/weapon)
	SIGNAL_HANDLER
	if(active_bonus > 0)
		human_parent.extra_damage -= active_bonus
		active_bonus = 0

// Maddening Maw: Attacks on bleeding targets deal 15% of melee damage as additional WHITE damage
/datum/component/ring_skill/fauvist/maddening_maw
	skill_name = "Maddening Maw"
	skill_desc = "Attacks on bleeding targets deal 15% of your melee damage as additional WHITE damage"
	school = "fauvist"
	tier = 1
	choice = "b"

	var/white_damage_percent = 0.15

/datum/component/ring_skill/fauvist/maddening_maw/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_ITEM_AFTERATTACK, PROC_REF(on_afterattack))

/datum/component/ring_skill/fauvist/maddening_maw/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_ITEM_AFTERATTACK)
	. = ..()

/datum/component/ring_skill/fauvist/maddening_maw/proc/on_afterattack(datum/source, mob/living/target, obj/item/weapon)
	SIGNAL_HANDLER
	if(!isliving(target))
		return

	if(!target_is_bleeding(target))
		return

	// Calculate WHITE damage based on weapon force
	var/white_damage = round(weapon.force * white_damage_percent)
	if(white_damage > 0)
		target.deal_damage(white_damage, WHITE_DAMAGE)

// ========== TIER 2 ==========

// Rending Claws: Attacks apply 2 bleed stacks
/datum/component/ring_skill/fauvist/rending_claws
	skill_name = "Rending Claws"
	skill_desc = "Attacks apply 2 bleed stacks"
	school = "fauvist"
	tier = 2
	choice = "a"

	var/bleed_stacks = 2

/datum/component/ring_skill/fauvist/rending_claws/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return

	target.apply_lc_bleed(bleed_stacks)

// Savage Instinct: After hitting a bleeding target, gain +15% damage for 4 seconds
/datum/component/ring_skill/fauvist/savage_instinct
	skill_name = "Savage Instinct"
	skill_desc = "After hitting a bleeding target, gain +15% damage for 4 seconds (refreshes on hit)"
	school = "fauvist"
	tier = 2
	choice = "b"

	var/damage_buff = 15
	var/buff_duration = 4 SECONDS
	var/buff_active = FALSE
	var/buff_timer_id

/datum/component/ring_skill/fauvist/savage_instinct/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return

	if(!target_is_bleeding(target))
		return

	// Refresh or apply buff
	if(buff_active)
		// Refresh timer
		if(buff_timer_id)
			deltimer(buff_timer_id)
	else
		// Apply buff
		buff_active = TRUE
		human_parent.extra_damage += damage_buff
		to_chat(human_parent, span_nicegreen("Savage Instinct: Your predatory fury intensifies!"))

	buff_timer_id = addtimer(CALLBACK(src, PROC_REF(remove_buff)), buff_duration, TIMER_STOPPABLE)

/datum/component/ring_skill/fauvist/savage_instinct/proc/remove_buff()
	if(buff_active)
		buff_active = FALSE
		human_parent.extra_damage -= damage_buff
		to_chat(human_parent, span_warning("Savage Instinct fades..."))

/datum/component/ring_skill/fauvist/savage_instinct/UnregisterFromParent()
	if(buff_timer_id)
		deltimer(buff_timer_id)
	if(buff_active)
		human_parent.extra_damage -= damage_buff
	. = ..()

// ========== TIER 3 ==========

// Spreading Wounds: When hitting bleeding target, adjacent enemies gain 3 bleed
/datum/component/ring_skill/fauvist/spreading_wounds
	skill_name = "Spreading Wounds"
	skill_desc = "When hitting bleeding target, adjacent enemies gain 3 bleed"
	school = "fauvist"
	tier = 3
	choice = "a"

	var/spread_stacks = 3

/datum/component/ring_skill/fauvist/spreading_wounds/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return

	if(!target_is_bleeding(target))
		return

	// Apply bleed to adjacent enemies
	for(var/mob/living/nearby in range(1, target))
		if(nearby == target || nearby == human_parent)
			continue
		if(nearby.stat == DEAD)
			continue

		nearby.apply_lc_bleed(spread_stacks)

// Primal Terror: Hitting targets with 10+ bleed deals 20 WHITE damage and removes 5 bleed
/datum/component/ring_skill/fauvist/primal_terror
	skill_name = "Primal Terror"
	skill_desc = "Hitting targets with 10+ bleed deals 20 WHITE damage and removes 5 bleed stacks"
	school = "fauvist"
	tier = 3
	choice = "b"

	var/stack_threshold = 10
	var/white_damage = 20
	var/stacks_removed = 5

/datum/component/ring_skill/fauvist/primal_terror/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return

	var/datum/status_effect/stacking/lc_bleed/bleed = target.has_status_effect(/datum/status_effect/stacking/lc_bleed)
	if(!bleed || bleed.stacks < stack_threshold)
		return

	// Deal WHITE damage and consume stacks
	target.deal_damage(white_damage, WHITE_DAMAGE)
	bleed.stacks -= stacks_removed

	to_chat(human_parent, span_nicegreen("Primal Terror: Your victim's mind shatters! ([white_damage] WHITE damage)"))
