// Corporist School Skills
// Theme: Simple and direct. Build up bleed, then trigger it for devastating damage.

// ========== TIER 1 ==========

// Opening Wounds: When off cooldown, next attack applies 8 bleed (20s CD). While on CD, attacks apply 1 bleed.
/datum/component/ring_skill/corporist/opening_wounds
	skill_name = "Opening Wounds"
	skill_desc = "When off cooldown, your next attack applies 8 bleed stacks (20s cooldown). While on cooldown, attacks apply 1 bleed stack."
	school = "corporist"
	tier = 1
	choice = "a"

	var/cooldown_time = 20 SECONDS
	var/next_use = 0

/datum/component/ring_skill/corporist/opening_wounds/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return

	if(world.time >= next_use)
		// Big opening hit
		target.apply_lc_bleed(8)
		next_use = world.time + cooldown_time
		to_chat(human_parent, span_nicegreen("Opening Wounds: You inflict deep wounds! (8 bleed)"))
	else
		// Small bleed while on cooldown
		target.apply_lc_bleed(1)

// Exposed Veins: +3% damage per bleed stack on target (max 30%)
/datum/component/ring_skill/corporist/exposed_veins
	skill_name = "Exposed Veins"
	skill_desc = "+3% damage per bleed stack on target (max 30%)"
	school = "corporist"
	tier = 1
	choice = "b"

	var/damage_bonus = 0

/datum/component/ring_skill/corporist/exposed_veins/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return

	var/stacks = get_bleed_stacks(target)
	if(stacks > 0)
		damage_bonus = min(stacks * 0.03, 0.30) // 3% per stack, max 30%
		human_parent.extra_damage += damage_bonus

/datum/component/ring_skill/corporist/exposed_veins/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_ITEM_AFTERATTACK, PROC_REF(on_afterattack))

/datum/component/ring_skill/corporist/exposed_veins/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_ITEM_AFTERATTACK)
	. = ..()

/datum/component/ring_skill/corporist/exposed_veins/proc/on_afterattack(datum/source, mob/living/target, obj/item/weapon)
	SIGNAL_HANDLER
	if(damage_bonus > 0)
		human_parent.extra_damage -= damage_bonus
		damage_bonus = 0

// ========== TIER 2 ==========

// Sanguine Absorption: Heal 5 HP when applying bleed (5s cooldown)
/datum/component/ring_skill/corporist/sanguine_absorption
	skill_name = "Sanguine Absorption"
	skill_desc = "Heal 5 HP when applying bleed (5s cooldown)"
	school = "corporist"
	tier = 2
	choice = "a"

	var/cooldown_time = 5 SECONDS
	var/next_use = 0
	var/heal_amount = 5

/datum/component/ring_skill/corporist/sanguine_absorption/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return

	if(world.time < next_use)
		return

	// Check if target gained bleed from this attack (we check if they're bleeding)
	// This triggers on any attack against a bleeding target or if bleed was just applied
	if(target_is_bleeding(target))
		human_parent.adjustBruteLoss(-heal_amount)
		next_use = world.time + cooldown_time
		to_chat(human_parent, span_nicegreen("Sanguine Absorption: You absorb vitality from the bleeding wound!"))

// Rupture: Hitting targets with 15+ bleed consumes 10 stacks to deal 40 bonus damage
/datum/component/ring_skill/corporist/rupture
	skill_name = "Rupture"
	skill_desc = "Hitting targets with 15+ bleed consumes 10 stacks to deal 40 bonus damage"
	school = "corporist"
	tier = 2
	choice = "b"

	var/stack_threshold = 15
	var/stacks_consumed = 10
	var/bonus_damage = 40

/datum/component/ring_skill/corporist/rupture/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return

	var/datum/status_effect/stacking/lc_bleed/bleed = target.has_status_effect(/datum/status_effect/stacking/lc_bleed)
	if(!bleed || bleed.stacks < stack_threshold)
		return

	// Consume stacks and deal damage
	bleed.stacks -= stacks_consumed
	target.deal_damage(bonus_damage, RED_DAMAGE)
	to_chat(human_parent, span_nicegreen("Rupture: The wounds burst open! ([bonus_damage] bonus damage)"))
	playsound(target, 'sound/effects/splat.ogg', 40, TRUE)

// ========== TIER 3 ==========

// Vivisection: Hitting bleeding targets below 20% HP deals 100 bonus damage (30s cooldown)
/datum/component/ring_skill/corporist/vivisection
	skill_name = "Vivisection"
	skill_desc = "Hitting bleeding targets below 20% HP deals 100 bonus RED damage (30s cooldown)"
	school = "corporist"
	tier = 3
	choice = "a"

	var/cooldown_time = 30 SECONDS
	var/next_use = 0
	var/hp_threshold = 0.20
	var/bonus_damage = 100

/datum/component/ring_skill/corporist/vivisection/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return

	if(world.time < next_use)
		return

	if(!target_is_bleeding(target))
		return

	var/hp_percent = target.health / target.maxHealth
	if(hp_percent > hp_threshold)
		return

	// Execute!
	target.deal_damage(bonus_damage, RED_DAMAGE)
	next_use = world.time + cooldown_time
	to_chat(human_parent, span_boldwarning("Vivisection: You strike at the vital points! ([bonus_damage] bonus RED damage)"))
	playsound(target, 'sound/effects/splat.ogg', 60, TRUE)

// Exsanguinate: Active buff - next hit consumes all bleed for 5 damage per stack
/datum/component/ring_skill/corporist/exsanguinate
	skill_name = "Exsanguinate"
	skill_desc = "Active (30s CD): Buff your weapon for 10s. Next hit consumes ALL bleed on target, dealing 5 damage per stack."
	school = "corporist"
	tier = 3
	choice = "b"

	var/buff_active = FALSE
	var/buff_duration = 10 SECONDS
	var/damage_per_stack = 5

/datum/component/ring_skill/corporist/exsanguinate/RegisterWithParent()
	. = ..()
	// Grant the activation action
	var/datum/action/cooldown/exsanguinate_activate/action = new(human_parent)
	action.skill_ref = WEAKREF(src)
	action.Grant(human_parent)

/datum/component/ring_skill/corporist/exsanguinate/UnregisterFromParent()
	for(var/datum/action/cooldown/exsanguinate_activate/action in human_parent.actions)
		action.Remove(human_parent)
	. = ..()

/datum/component/ring_skill/corporist/exsanguinate/proc/activate_buff()
	buff_active = TRUE
	to_chat(human_parent, span_nicegreen("Exsanguinate: Your weapon thirsts for blood!"))
	addtimer(CALLBACK(src, PROC_REF(deactivate_buff)), buff_duration)

/datum/component/ring_skill/corporist/exsanguinate/proc/deactivate_buff()
	if(buff_active)
		buff_active = FALSE
		to_chat(human_parent, span_warning("Exsanguinate: The buff fades..."))

/datum/component/ring_skill/corporist/exsanguinate/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!buff_active)
		return
	if(!isliving(target))
		return

	var/datum/status_effect/stacking/lc_bleed/bleed = target.has_status_effect(/datum/status_effect/stacking/lc_bleed)
	if(!bleed || bleed.stacks <= 0)
		return

	// Consume all bleed and deal damage
	var/stacks = bleed.stacks
	var/total_damage = stacks * damage_per_stack
	qdel(bleed) // Remove all bleed

	target.deal_damage(total_damage, RED_DAMAGE)
	buff_active = FALSE

	to_chat(human_parent, span_boldwarning("Exsanguinate: You drain all the blood! ([total_damage] damage from [stacks] stacks)"))
	playsound(target, 'sound/effects/splat.ogg', 70, TRUE)

// Action to activate Exsanguinate
/datum/action/cooldown/exsanguinate_activate
	name = "Exsanguinate"
	desc = "Buff your weapon. Next hit consumes all bleed for massive damage."
	button_icon_state = "yourarthere"
	cooldown_time = 30 SECONDS
	check_flags = AB_CHECK_CONSCIOUS

	var/datum/weakref/skill_ref

/datum/action/cooldown/exsanguinate_activate/Trigger(trigger_flags)
	. = ..()
	if(!.)
		return FALSE
	var/datum/component/ring_skill/corporist/exsanguinate/skill = skill_ref?.resolve()
	if(!skill)
		return FALSE

	skill.activate_buff()
	StartCooldown()
	return TRUE
