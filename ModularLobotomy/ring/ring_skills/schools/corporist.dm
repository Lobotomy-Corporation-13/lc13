// Corporist School Skills
// Theme: Duality of pain and power. Inflict negative effects on targets while gaining positive effects.
// When both occur simultaneously, trigger Artistic Synergy bonuses.
// "Those who utilize the interaction between human bones and muscles, the contraction and elongation thereof."

// ========== TIER 1 ==========

// Butcher - Ribs: On hit, apply 2 bleed to target and gain 1 Protection.
// Artistic Synergy: Heal 5% max SP. If at max SP, gain 1 Damage Up instead.
/datum/component/ring_skill/corporist/butcher_ribs
	skill_name = "Butcher - Ribs"
	skill_desc = "On Hit: Apply 2 bleed to target and gain 1 Protection. Heal 5% max SP. If at max SP, gain 1 Damage Up instead."
	school = "corporist"
	tier = 1
	choice = "a"

	var/bleed_stacks = 2
	var/protection_stacks = 1
	var/sp_heal_percent = 0.05
	var/next_use = 0

/datum/component/ring_skill/corporist/butcher_ribs/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target) || target.stat == DEAD)
		return
	if(world.time < next_use)
		return
	next_use = world.time + 1 SECONDS

	// Inflict negative effect (deferred to on_post_attack)
	pending_bleed += bleed_stacks

	// Gain positive effect
	add_ring_protection(human_parent, protection_stacks)

	// Artistic Synergy: both occurred simultaneously
	if(!sp_heal_ready())
		return
	set_sp_heal_cooldown()
	if(human_parent.sanityhealth >= human_parent.maxSanity)
		// At max SP - gain Damage Up instead
		add_ring_strength(human_parent, 1)
		to_chat(human_parent, span_nicegreen("Butcher - Ribs: Your artistry empowers you! (+1 Damage Up)"))
	else
		var/sp_heal = round(human_parent.maxSanity * sp_heal_percent)
		human_parent.adjustSanityLoss(-sp_heal)
		to_chat(human_parent, span_nicegreen("Butcher - Ribs: Your creative vision soothes your mind. (+[sp_heal] SP)"))

// Rotator Crush: On hit, apply 2 bleed to target and gain 1 Damage Up.
// Artistic Synergy: Heal 5% max SP. If at max SP, gain 1 Protection instead.
/datum/component/ring_skill/corporist/rotator_crush
	skill_name = "Rotator Crush"
	skill_desc = "On Hit: Apply 2 bleed to target and gain 1 Damage Up. Heal 5% max SP. If at max SP, gain 1 Protection instead."
	school = "corporist"
	tier = 1
	choice = "b"

	var/bleed_stacks = 2
	var/damage_up_stacks = 1
	var/sp_heal_percent = 0.05
	var/next_use = 0

/datum/component/ring_skill/corporist/rotator_crush/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target) || target.stat == DEAD)
		return
	if(world.time < next_use)
		return
	next_use = world.time + 1 SECONDS

	// Inflict negative effect (deferred to on_post_attack)
	pending_bleed += bleed_stacks

	// Gain positive effect
	add_ring_strength(human_parent, damage_up_stacks)

	// Artistic Synergy: both occurred simultaneously
	if(!sp_heal_ready())
		return
	set_sp_heal_cooldown()
	if(human_parent.sanityhealth >= human_parent.maxSanity)
		// At max SP - gain Protection instead
		add_ring_protection(human_parent, 1)
		to_chat(human_parent, span_nicegreen("Rotator Crush: Your artistry shields you! (+1 Protection)"))
	else
		var/sp_heal = round(human_parent.maxSanity * sp_heal_percent)
		human_parent.adjustSanityLoss(-sp_heal)
		to_chat(human_parent, span_nicegreen("Rotator Crush: Your creative tension soothes your mind. (+[sp_heal] SP)"))

// ========== TIER 2 ==========

// Repressed Flesh: When you have a positive effect and hit a bleeding target,
// heal 5 HP and apply 2 extra bleed. If target has 10+ bleed, also gain 1 extra Protection. (5s CD)
/datum/component/ring_skill/corporist/repressed_flesh
	skill_name = "Repressed Flesh"
	skill_desc = "On Hit: If target is bleeding and you have a positive effect, heal 5 HP and apply 2 extra bleed. If target has 10+ bleed, gain 1 extra Protection. (5s cooldown)"
	school = "corporist"
	tier = 2
	choice = "a"

	var/cooldown_time = 5 SECONDS
	var/next_use = 0
	var/heal_amount = 5
	var/extra_bleed = 2
	var/bleed_threshold = 10

/datum/component/ring_skill/corporist/repressed_flesh/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target) || target.stat == DEAD)
		return

	if(world.time < next_use)
		return

	// Check conditions: target must be bleeding, user must have a positive effect
	if(!target_is_bleeding(target))
		return

	if(!has_positive_effect(human_parent))
		return

	// Synergy triggered
	human_parent.adjustBruteLoss(-heal_amount)
	pending_bleed += extra_bleed
	next_use = world.time + cooldown_time

	// Bonus at high bleed
	if(get_bleed_stacks(target) >= bleed_threshold)
		add_ring_protection(human_parent, 1)
		to_chat(human_parent, span_nicegreen("Repressed Flesh: The artwork deepens! (+[heal_amount] HP, +1 Protection)"))
	else
		to_chat(human_parent, span_nicegreen("Repressed Flesh: You absorb vitality from your work. (+[heal_amount] HP)"))

// Tendon Tear: When you have a positive effect and hit a bleeding target,
// deal 20 bonus RED damage. If you have 3+ Damage Up stacks, deal additional 15 RED damage.
/datum/component/ring_skill/corporist/tendon_tear
	skill_name = "Tendon Tear"
	skill_desc = "On Hit: If target is bleeding and you have a positive effect, deal 10 bonus RED damage. If you have 3+ Damage Up, deal additional 15 RED damage."
	school = "corporist"
	tier = 2
	choice = "b"

	var/base_bonus_damage = 10
	var/extra_bonus_damage = 15
	var/damage_up_threshold = 3

/datum/component/ring_skill/corporist/tendon_tear/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target) || target.stat == DEAD)
		return

	// Check conditions: target must be bleeding, user must have positive
	if(!target_is_bleeding(target))
		return

	if(!has_positive_effect(human_parent))
		return

	// Base bonus damage
	var/total_damage = base_bonus_damage

	// Check for enhanced damage from Damage Up stacks
	var/datum/status_effect/stacking/damage_up/dup = human_parent.has_status_effect(/datum/status_effect/stacking/damage_up)
	if(dup && dup.stacks >= damage_up_threshold)
		total_damage += extra_bonus_damage
		to_chat(human_parent, span_boldwarning("Tendon Tear: Muscles tear apart! ([total_damage] bonus RED damage)"))
	else
		to_chat(human_parent, span_nicegreen("Tendon Tear: Bones crack! ([total_damage] bonus RED damage)"))

	target.deal_damage(total_damage, RED_DAMAGE)
	playsound(target, 'sound/effects/splat.ogg', 40, TRUE)

// ========== TIER 3 ==========

// Anatomize: When you have both Protection and Damage Up and hit a bleeding target
// below 25% HP, consume all bleed stacks to deal 5 RED damage per stack. Also fully restore SP. (30s CD)
/datum/component/ring_skill/corporist/anatomize
	skill_name = "Anatomize"
	skill_desc = "On Hit: If target is bleeding and below 25% HP, and you have both Protection and Damage Up, consume all bleed to deal 5 RED damage per stack and fully restore SP. (30s CD)"
	school = "corporist"
	tier = 3
	choice = "a"

	var/cooldown_time = 30 SECONDS
	var/next_use = 0
	var/damage_per_stack = 5
	var/hp_threshold = 0.25

/datum/component/ring_skill/corporist/anatomize/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target) || target.stat == DEAD)
		return

	if(world.time < next_use)
		return

	// Must have both Protection and Damage Up
	if(!human_parent.has_status_effect(/datum/status_effect/stacking/protection))
		return

	if(!human_parent.has_status_effect(/datum/status_effect/stacking/damage_up))
		return

	// Target must be bleeding and below HP threshold
	var/datum/status_effect/stacking/lc_bleed/bleed = target.has_status_effect(/datum/status_effect/stacking/lc_bleed)
	if(!bleed || bleed.stacks <= 0)
		return

	var/hp_percent = target.health / target.maxHealth
	if(hp_percent > hp_threshold)
		return

	// Execute!
	var/stacks = bleed.stacks
	var/total_damage = stacks * damage_per_stack
	qdel(bleed)

	target.deal_damage(total_damage, RED_DAMAGE)
	human_parent.adjustSanityLoss(-human_parent.maxSanity) // Fully restore SP
	next_use = world.time + cooldown_time

	to_chat(human_parent, span_boldwarning("Anatomize: A transcendent dissection! ([total_damage] RED damage from [stacks] stacks, SP fully restored)"))
	playsound(target, 'sound/effects/splat.ogg', 70, TRUE)

// Exhibition Arrangements: Active (30s CD) - For 8 seconds, every attack applies 3 bleed + 1 random
// negative effect AND grants 1 Protection + 1 Damage Up. Guaranteed synergy every hit.
// Heal 5% max SP per hit (or +2 Damage Up if at max SP). When buff expires, consume all bleed
// on most recent target for 3 RED damage per stack.
/datum/component/ring_skill/corporist/exhibition_arrangements
	skill_name = "Exhibition Arrangements"
	skill_desc = "Active (30s CD): For 8s, attacks apply 3 bleed + 1 random negative effect AND grant 1 Protection + 1 Damage Up. Heal 5% max SP per hit (at max SP: +2 Damage Up). On expiry, consume all bleed on last target for 3 dmg/stack."
	school = "corporist"
	tier = 3
	choice = "b"

	var/buff_active = FALSE
	var/buff_duration = 8 SECONDS
	var/buff_timer_id
	var/mob/living/last_target
	var/next_use = 0

/datum/component/ring_skill/corporist/exhibition_arrangements/RegisterWithParent()
	. = ..()
	// Grant the activation action
	var/datum/action/cooldown/exhibition_arrangements_activate/action = new(human_parent)
	action.skill_ref = WEAKREF(src)
	action.Grant(human_parent)

/datum/component/ring_skill/corporist/exhibition_arrangements/UnregisterFromParent()
	for(var/datum/action/cooldown/exhibition_arrangements_activate/action in human_parent.actions)
		action.Remove(human_parent)
	if(buff_timer_id)
		deltimer(buff_timer_id)
	last_target = null
	. = ..()

/datum/component/ring_skill/corporist/exhibition_arrangements/proc/activate_buff()
	buff_active = TRUE
	last_target = null
	to_chat(human_parent, span_nicegreen("Exhibition Arrangements: You begin arranging your masterpiece!"))
	if(buff_timer_id)
		deltimer(buff_timer_id)
	buff_timer_id = addtimer(CALLBACK(src, PROC_REF(deactivate_buff)), buff_duration, TIMER_STOPPABLE)

/datum/component/ring_skill/corporist/exhibition_arrangements/proc/deactivate_buff()
	buff_timer_id = null
	if(!buff_active)
		return
	buff_active = FALSE

	// Consume all bleed on last target
	if(last_target && !QDELETED(last_target) && last_target.stat != DEAD)
		var/datum/status_effect/stacking/lc_bleed/bleed = last_target.has_status_effect(/datum/status_effect/stacking/lc_bleed)
		if(bleed && bleed.stacks > 0)
			var/stacks = bleed.stacks
			var/total_damage = stacks * 3
			qdel(bleed)
			last_target.deal_damage(total_damage, RED_DAMAGE)
			to_chat(human_parent, span_boldwarning("Exhibition Arrangements: The exhibition opens! ([total_damage] RED damage from [stacks] stacks)"))
			playsound(last_target, 'sound/effects/splat.ogg', 60, TRUE)
		else
			to_chat(human_parent, span_warning("Exhibition Arrangements: The exhibition closes."))
	else
		to_chat(human_parent, span_warning("Exhibition Arrangements: The exhibition closes."))

	last_target = null

/datum/component/ring_skill/corporist/exhibition_arrangements/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!buff_active || !isliving(target) || target.stat == DEAD)
		return
	if(world.time < next_use)
		return
	next_use = world.time + 1 SECONDS

	last_target = target

	// Apply negative effects (bleed deferred to on_post_attack)
	pending_bleed += 3
	var/effect_name = apply_random_effect(target, 1) // 1 stack of random negative effect

	// Gain positive effects
	add_ring_protection(human_parent, 1)
	add_ring_strength(human_parent, 1)

	// Synergy bonus
	if(!sp_heal_ready())
		return
	set_sp_heal_cooldown()
	if(human_parent.sanityhealth >= human_parent.maxSanity)
		add_ring_strength(human_parent, 2)
		to_chat(human_parent, span_nicegreen("Exhibition Arrangements: Perfect arrangement! (+3 bleed, +[effect_name], +1 Protection, +3 Damage Up)"))
	else
		var/sp_heal = round(human_parent.maxSanity * 0.05)
		human_parent.adjustSanityLoss(-sp_heal)
		to_chat(human_parent, span_nicegreen("Exhibition Arrangements: Artistic flow! (+3 bleed, +[effect_name], +1 Protection, +1 Damage Up, +[sp_heal] SP)"))

// Action to activate Exhibition Arrangements
/datum/action/cooldown/exhibition_arrangements_activate
	name = "Exhibition Arrangements"
	desc = "Begin arranging your exhibition - a masterpiece of destruction."
	icon_icon = 'icons/obj/spider_house/ring/ring_icons.dmi'
	button_icon_state = "exhibition_arrangements"
	cooldown_time = 30 SECONDS
	check_flags = AB_CHECK_CONSCIOUS

	var/datum/weakref/skill_ref

/datum/action/cooldown/exhibition_arrangements_activate/Trigger(trigger_flags)
	. = ..()
	if(!.)
		return FALSE
	if(owner.stat == DEAD)
		return FALSE
	var/datum/component/ring_skill/corporist/exhibition_arrangements/skill = skill_ref?.resolve()
	if(!skill)
		return FALSE

	skill.activate_buff()
	StartCooldown()
	return TRUE
