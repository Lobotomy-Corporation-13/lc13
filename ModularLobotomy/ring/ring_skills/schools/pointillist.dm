// Pointillist School Skills
// Theme: Random status effect application, SP recovery, scaling power.

// TIER 1

// Hematic Coloring: Apply 3 stacks of random effect. If target has it, +10% damage instead.
/datum/component/ring_skill/pointillist/hematic_coloring
	skill_name = "Hematic Coloring"
	skill_desc = "Attacks apply 3 stacks of a random effect. If target already has that effect, deal +10% damage instead."
	school = "pointillist"
	tier = 1
	choice = "a"

	var/stacks_applied = 3
	var/damage_bonus = 10
	var/active_bonus = 0
	var/next_use = 0

/datum/component/ring_skill/pointillist/hematic_coloring/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return
	if(world.time < next_use)
		return
	next_use = world.time + 1 SECONDS

	var/effect_type = pick("bleed", "overheat", "tremor", "mental_decay")

	if(has_effect(target, effect_type))
		// Target already has this effect - bonus damage instead
		active_bonus = damage_bonus
		human_parent.extra_damage += active_bonus
	else
		// Apply the effect (bleed deferred to on_post_attack)
		switch(effect_type)
			if("bleed")
				pending_bleed += stacks_applied
			if("overheat")
				target.apply_lc_overheat(stacks_applied)
			if("tremor")
				target.apply_lc_tremor(stacks_applied, 999)
			if("mental_decay")
				target.apply_lc_mental_decay(stacks_applied)

/datum/component/ring_skill/pointillist/hematic_coloring/on_post_attack(datum/source, mob/living/target, obj/item/weapon)
	if(active_bonus > 0)
		human_parent.extra_damage -= active_bonus
		active_bonus = 0
	..()


// Sanguine Pointillism: Apply 1 stack of TWO random effects. Heal 2 SP for new effects.
/datum/component/ring_skill/pointillist/sanguine_pointillism
	skill_name = "Sanguine Pointillism"
	skill_desc = "Attacks apply 1 stack of TWO random effects. Heal 2 SP whenever you apply an effect the target didn't already have."
	school = "pointillist"
	tier = 1
	choice = "b"

	var/sp_heal = 2
	var/next_use = 0

/datum/component/ring_skill/pointillist/sanguine_pointillism/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return
	if(world.time < next_use)
		return
	next_use = world.time + 1 SECONDS

	var/list/effect_types = list("bleed", "overheat", "tremor", "mental_decay")
	var/sp_healed = 0

	// Apply two random effects
	for(var/i in 1 to 2)
		if(!length(effect_types))
			break

		var/effect_type = pick_n_take(effect_types)
		var/was_new = !has_effect(target, effect_type)

		switch(effect_type)
			if("bleed")
				pending_bleed += 1
			if("overheat")
				target.apply_lc_overheat(1)
			if("tremor")
				target.apply_lc_tremor(1, 999)
			if("mental_decay")
				target.apply_lc_mental_decay(1)

		if(was_new)
			sp_healed += sp_heal

	if(sp_healed > 0 && ishuman(human_parent) && sp_heal_ready())
		set_sp_heal_cooldown()
		human_parent.adjustSanityLoss(-sp_healed)
		to_chat(human_parent, span_nicegreen("Sanguine Pointillism: New colors soothe your mind! (+[sp_healed] SP)"))

// TIER 2

// Assignment Evaluation: Heal 5 SP when hitting targets, +3 SP per status effect on them
/datum/component/ring_skill/pointillist/assignment_evaluation
	skill_name = "Assignment Evaluation"
	skill_desc = "Heal 5 SP when hitting targets, +3 SP per status effect on them"
	school = "pointillist"
	tier = 2
	choice = "a"

	var/base_heal = 5
	var/bonus_per_effect = 3

/datum/component/ring_skill/pointillist/assignment_evaluation/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return
	if(!sp_heal_ready())
		return
	set_sp_heal_cooldown()

	var/effect_count = count_status_effects(target)
	var/total_heal = base_heal + (effect_count * bonus_per_effect)

	human_parent.adjustSanityLoss(-total_heal)
	if(effect_count > 0)
		to_chat(human_parent, span_nicegreen("Assignment Evaluation: [effect_count] effects evaluated! (+[total_heal] SP)"))

// Beat the Brush: +5% damage per status effect on target (max 20%)
/datum/component/ring_skill/pointillist/beat_the_brush
	skill_name = "Beat the Brush"
	skill_desc = "+5% damage per status effect on target (max 20% at 4 effects)"
	school = "pointillist"
	tier = 2
	choice = "b"

	var/damage_per_effect = 5
	var/max_bonus = 20
	var/active_bonus = 0

/datum/component/ring_skill/pointillist/beat_the_brush/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return

	var/effect_count = count_status_effects(target)
	if(effect_count > 0)
		active_bonus = min(effect_count * damage_per_effect, max_bonus)
		human_parent.extra_damage += active_bonus

/datum/component/ring_skill/pointillist/beat_the_brush/on_post_attack(datum/source, mob/living/target, obj/item/weapon)
	if(active_bonus > 0)
		human_parent.extra_damage -= active_bonus
		active_bonus = 0
	..()


// TIER 3

// Paint Over: Random effects apply 2x stacks; 10% chance for all four
/datum/component/ring_skill/pointillist/paint_over
	skill_name = "Paint Over"
	skill_desc = "Random effect application now applies 2x stacks; +10% chance to apply ALL four effects at once"
	school = "pointillist"
	tier = 3
	choice = "a"

	var/all_effects_chance = 10
	var/next_use = 0

/datum/component/ring_skill/pointillist/paint_over/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return
	if(world.time < next_use)
		return
	next_use = world.time + 1 SECONDS

	if(prob(all_effects_chance))
		// Apply all four effects! (bleed deferred to on_post_attack)
		pending_bleed += 2
		target.apply_lc_overheat(2)
		target.apply_lc_tremor(2, 999)
		target.apply_lc_mental_decay(2)
		to_chat(human_parent, span_nicegreen("Paint Over: A masterful stroke! All colors applied!"))
	else
		// Apply one random effect with 2x stacks (bleed deferred to on_post_attack)
		var/effect_type = pick("bleed", "overheat", "tremor", "mental_decay")
		switch(effect_type)
			if("bleed")
				pending_bleed += 2
			if("overheat")
				target.apply_lc_overheat(2)
			if("tremor")
				target.apply_lc_tremor(2, 999)
			if("mental_decay")
				target.apply_lc_mental_decay(2)

// Practices on Aesthetics: +10% damage and +2 bleed per status effect on target
/datum/component/ring_skill/pointillist/practices_on_aesthetics
	skill_name = "Practices on Aesthetics"
	skill_desc = "+10% damage and +2 bleed per status effect on target"
	school = "pointillist"
	tier = 3
	choice = "b"

	var/damage_per_effect = 10
	var/bleed_per_effect = 2
	var/active_bonus = 0
	var/next_use = 0

/datum/component/ring_skill/pointillist/practices_on_aesthetics/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return
	if(world.time < next_use)
		return
	next_use = world.time + 1 SECONDS

	var/effect_count = count_status_effects(target)
	if(effect_count > 0)
		active_bonus = effect_count * damage_per_effect
		human_parent.extra_damage += active_bonus

		// Apply bonus bleed (deferred to on_post_attack)
		pending_bleed += effect_count * bleed_per_effect

/datum/component/ring_skill/pointillist/practices_on_aesthetics/on_post_attack(datum/source, mob/living/target, obj/item/weapon)
	if(active_bonus > 0)
		human_parent.extra_damage -= active_bonus
		active_bonus = 0
	..()

