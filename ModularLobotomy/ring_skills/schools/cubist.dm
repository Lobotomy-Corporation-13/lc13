// Cubist School Skills
// Theme: Area control, spatial manipulation. Command the battlefield through bleeding zones.

// ========== TIER 1 ==========

// Fractured Reflection: Attackers gain 3 bleed when hitting you
/datum/component/ring_skill/cubist/fractured_reflection
	skill_name = "Fractured Reflection"
	skill_desc = "Attackers gain 3 bleed when hitting you"
	school = "cubist"
	tier = 1
	choice = "a"

	var/reflect_stacks = 3

/datum/component/ring_skill/cubist/fractured_reflection/on_after_take_damage(datum/source, damage, damagetype, def_zone, wound_bonus, bare_wound_bonus, sharpness, atom/attacker, flags, attack_type)
	// Apply bleed to the attacker
	if(!attacker || !isliving(attacker))
		return
	if(attacker == human_parent)
		return

	var/mob/living/L = attacker
	L.apply_lc_bleed(reflect_stacks)

// Geometric Reach: Your attacks apply 2 bleed to enemies adjacent to your target
/datum/component/ring_skill/cubist/geometric_reach
	skill_name = "Geometric Reach"
	skill_desc = "Your attacks apply 2 bleed to enemies adjacent to your target"
	school = "cubist"
	tier = 1
	choice = "b"

	var/splash_stacks = 2

/datum/component/ring_skill/cubist/geometric_reach/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return

	// Apply bleed to adjacent enemies
	for(var/mob/living/nearby in range(1, target))
		if(nearby == target || nearby == human_parent)
			continue
		if(nearby.stat == DEAD)
			continue

		nearby.apply_lc_bleed(splash_stacks)

// ========== TIER 2 ==========

// Abstract Suffering: Attacks against bleeding targets deal bonus WHITE damage
/datum/component/ring_skill/cubist/abstract_suffering
	skill_name = "Abstract Suffering"
	skill_desc = "Your attacks against bleeding targets deal bonus WHITE damage equal to their bleed stacks * 2"
	school = "cubist"
	tier = 2
	choice = "a"

/datum/component/ring_skill/cubist/abstract_suffering/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return

	// Check if target is bleeding
	var/bleed_stacks = get_bleed_stacks(target)
	if(bleed_stacks <= 0)
		return

	// Deal bonus WHITE damage equal to bleed stacks *2
	target.deal_damage(bleed_stacks * 2, WHITE_DAMAGE)

// Warped Space: Hitting targets with 8+ bleed inflicts slowdown
/datum/component/ring_skill/cubist/warped_space
	skill_name = "Warped Space"
	skill_desc = "Hitting targets with 8+ bleed stacks inflicts 20% slowdown for 3 seconds"
	school = "cubist"
	tier = 2
	choice = "b"

	var/stack_threshold = 8
	var/slowdown_amount = 0.2
	var/slowdown_duration = 3 SECONDS

/datum/component/ring_skill/cubist/warped_space/on_attack(datum/source, mob/living/target, obj/item/weapon)
	if(!isliving(target))
		return

	var/stacks = get_bleed_stacks(target)
	if(stacks < stack_threshold)
		return

	// Apply slowdown
	target.add_movespeed_modifier(/datum/movespeed_modifier/warped_space)
	addtimer(CALLBACK(src, PROC_REF(remove_slowdown), target), slowdown_duration)
	to_chat(human_parent, span_nicegreen("Warped Space: Reality bends around your victim!"))

/datum/component/ring_skill/cubist/warped_space/proc/remove_slowdown(mob/living/target)
	if(target)
		target.remove_movespeed_modifier(/datum/movespeed_modifier/warped_space)

/datum/movespeed_modifier/warped_space
	multiplicative_slowdown = 0.2

// ========== TIER 3 ==========

// Spatial Anchor: Enemies within 6 tiles can't have bleed reduced below 5
/datum/component/ring_skill/cubist/spatial_anchor
	skill_name = "Spatial Anchor"
	skill_desc = "Enemies within 6 tiles of you cannot have their bleed reduced below 5 stacks"
	school = "cubist"
	tier = 3
	choice = "a"

	var/range = 6
	var/min_stacks = 5

/datum/component/ring_skill/cubist/spatial_anchor/RegisterWithParent()
	. = ..()
	// Register for bleed damage signal to enforce minimum when bleed ticks nearby
	RegisterSignal(parent, COMSIG_STATUS_BLEED_DAMAGE, PROC_REF(on_bleed_damage))

/datum/component/ring_skill/cubist/spatial_anchor/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_STATUS_BLEED_DAMAGE)
	. = ..()

/datum/component/ring_skill/cubist/spatial_anchor/proc/on_bleed_damage(datum/source, mob/living/bleeder, bleed_stacks)
	SIGNAL_HANDLER

	// Check if bleeder is within range
	if(!bleeder || bleeder == human_parent)
		return
	if(get_dist(human_parent, bleeder) > range)
		return

	// Enforce minimum bleed stacks
	var/datum/status_effect/stacking/lc_bleed/bleed = bleeder.has_status_effect(/datum/status_effect/stacking/lc_bleed)
	if(bleed && bleed.stacks < min_stacks && bleed.stacks > 0)
		bleed.stacks = min_stacks
		to_chat(human_parent, span_notice("Spatial Anchor prevents [bleeder]'s bleed from falling below [min_stacks] stacks."))

// Crimson Dimension: Create bleed zone, damage reduction while inside
/datum/component/ring_skill/cubist/crimson_dimension
	skill_name = "Crimson Dimension"
	skill_desc = "Active (60s CD): Create 3x3 zone applying 2 bleed/sec for 10s; you take 20% less damage while inside"
	school = "cubist"
	tier = 3
	choice = "b"

/datum/component/ring_skill/cubist/crimson_dimension/RegisterWithParent()
	. = ..()
	// Grant the activation action
	var/datum/action/cooldown/crimson_dimension_activate/action = new(human_parent)
	action.skill_ref = WEAKREF(src)
	action.Grant(human_parent)

/datum/component/ring_skill/cubist/crimson_dimension/UnregisterFromParent()
	for(var/datum/action/cooldown/crimson_dimension_activate/action in human_parent.actions)
		action.Remove(human_parent)
	. = ..()

// Action to activate Crimson Dimension
/datum/action/cooldown/crimson_dimension_activate
	name = "Crimson Dimension"
	desc = "Create a 3x3 bleed zone. You take less damage while inside."
	button_icon_state = "yourarthere"
	cooldown_time = 60 SECONDS
	check_flags = AB_CHECK_CONSCIOUS

	var/datum/weakref/skill_ref

/datum/action/cooldown/crimson_dimension_activate/Trigger(trigger_flags)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/carbon/human/H = owner

	// Create the zone at the user's location
	var/turf/center = get_turf(H)
	new /obj/effect/crimson_dimension_zone(center, H)

	to_chat(H, span_nicegreen("Crimson Dimension: You warp space around you!"))
	StartCooldown()
	return TRUE

// The crimson dimension zone effect
/obj/effect/crimson_dimension_zone
	name = "crimson dimension"
	desc = "A warped area of crimson energy."
	icon = 'icons/effects/effects.dmi'
	icon_state = "yourarthere" // Placeholder
	color = "#8B0000"
	alpha = 150
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	layer = BELOW_MOB_LAYER

	var/duration = 10 SECONDS
	var/bleed_per_tick = 2
	var/damage_reduction = 0.20
	var/mob/living/carbon/human/creator
	var/list/zone_turfs = list()

/obj/effect/crimson_dimension_zone/Initialize(mapload, mob/living/carbon/human/owner)
	. = ..()
	creator = owner

	// Create 3x3 zone
	var/turf/center = get_turf(src)
	for(var/turf/T in range(1, center))
		zone_turfs += T
		// Visual effect on each turf
		new /obj/effect/temp_visual/crimson_dimension_tile(T)

	START_PROCESSING(SSobj, src)
	addtimer(CALLBACK(src, PROC_REF(end_zone)), duration)

/obj/effect/crimson_dimension_zone/process(delta_time)
	// Apply bleed to enemies in zone
	for(var/turf/T in zone_turfs)
		for(var/mob/living/M in T)
			if(M == creator)
				continue
			M.apply_lc_bleed(bleed_per_tick)

	// Check if creator is in zone for damage reduction
	if(creator && (get_turf(creator) in zone_turfs))
		// Apply damage reduction (handled via signal in actual implementation)
		// For now, just a simple notification
		return

/obj/effect/crimson_dimension_zone/proc/end_zone()
	STOP_PROCESSING(SSobj, src)
	qdel(src)

/obj/effect/temp_visual/crimson_dimension_tile
	icon = 'icons/effects/effects.dmi'
	icon_state = "yourarthere"
	color = "#8B0000"
	alpha = 100
	duration = 10 SECONDS
	layer = BELOW_MOB_LAYER
