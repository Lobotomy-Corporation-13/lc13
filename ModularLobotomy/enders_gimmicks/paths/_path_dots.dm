// ============================================================
// Path DoT — Damage Over Time Status Effects
// ============================================================
// 4 elemental DoTs: Bleed, Burn, Shock, Wind Shear.
// DoTs tick at turn start for path holders (via OnTurnReset),
// or every 5 seconds for regular mobs (via tick()).
// DoTs cannot crit and use the path damage pipeline.
// ============================================================

/datum/status_effect/path_dot
	id = "path_dot"
	duration = 20 SECONDS
	tick_interval = 5 SECONDS
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null

	/// DoT type string (PATH_DOT_BLEED, etc.)
	var/dot_type
	/// Snapshotted attacker ATK at time of application
	var/attacker_atk = 0
	/// Snapshotted target maxHealth at time of application
	var/target_max_hp = 0
	/// Reference to attacker's path (for damage pipeline)
	var/datum/path/attacker_path
	/// Stack count (only used by Wind Shear)
	var/stacks = 1
	/// Whether this DoT should use tick() for mob ticking
	var/use_mob_tick = FALSE

/datum/status_effect/path_dot/on_apply()
	// Snapshot target HP
	if(isanimal(owner))
		var/mob/living/simple_animal/SA = owner
		target_max_hp = SA.maxHealth
	else
		target_max_hp = owner.maxHealth

	// Determine tick mode
	// Path holders: DoTs tick via OnTurnReset(), not via tick()
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(H.HasPath())
			use_mob_tick = FALSE
			tick_interval = -1
		else
			use_mob_tick = TRUE
	else
		use_mob_tick = TRUE

	return TRUE

/datum/status_effect/path_dot/tick()
	if(!use_mob_tick)
		return
	DoTick()

/datum/status_effect/path_dot/on_remove()
	attacker_path = null

/// Calculates and deals DoT damage. Called by turn system or tick().
/datum/status_effect/path_dot/proc/DoTick()
	if(!owner || QDELETED(owner))
		return
	if(owner.stat == DEAD)
		return

	var/base_dmg = 0
	switch(dot_type)
		if(PATH_DOT_BLEED)
			// 16% maxHP for normal mobs, 7% for bosses
			var/rate = 0.16
			if(isanimal(owner))
				var/mob/living/simple_animal/SA = owner
				if(SA.maxHealth >= 3000)
					rate = 0.07
			base_dmg = target_max_hp * rate
			// Cap at 2x attacker ATK
			base_dmg = min(base_dmg, attacker_atk * 2)

		if(PATH_DOT_BURN)
			base_dmg = attacker_atk * 1.0

		if(PATH_DOT_SHOCK)
			base_dmg = attacker_atk * 2.0

		if(PATH_DOT_WIND_SHEAR)
			base_dmg = attacker_atk * 1.0 * stacks

	// Apply through path damage pipeline (no crit)
	if(base_dmg > 0 && attacker_path)
		attacker_path.deal_path_damage(owner, base_dmg, do_crit = FALSE)
	else if(base_dmg > 0)
		// Fallback: direct health adjustment if no path ref
		if(isanimal(owner))
			var/mob/living/simple_animal/SA = owner
			SA.adjustHealth(base_dmg)
		else
			owner.adjustBruteLoss(base_dmg)

// ============================================================
// DoT Subtypes
// ============================================================

/// Physical DoT — scales off target maxHP
/datum/status_effect/path_dot/bleed
	id = "path_dot_bleed"
	var/dot_type_init = PATH_DOT_BLEED

/datum/status_effect/path_dot/bleed/on_apply()
	dot_type = PATH_DOT_BLEED
	return ..()

/// Fire DoT — flat scaling off attacker ATK
/datum/status_effect/path_dot/burn
	id = "path_dot_burn"

/datum/status_effect/path_dot/burn/on_apply()
	dot_type = PATH_DOT_BURN
	return ..()

/// Lightning DoT — 2x Burn damage
/datum/status_effect/path_dot/shock
	id = "path_dot_shock"

/datum/status_effect/path_dot/shock/on_apply()
	dot_type = PATH_DOT_SHOCK
	return ..()

/// Wind DoT — stacks up to 5, each stack adds damage
/datum/status_effect/path_dot/wind_shear
	id = "path_dot_wind_shear"

/datum/status_effect/path_dot/wind_shear/on_apply()
	dot_type = PATH_DOT_WIND_SHEAR
	return ..()

// ============================================================
// Global Helper: apply_path_dot()
// ============================================================

/// Applies a DoT status effect to a target. Handles Wind Shear stacking.
/proc/apply_path_dot(mob/living/target, dot_type, datum/path/source_path, duration = 20 SECONDS)
	if(!target || QDELETED(target))
		return null

	var/atk_snapshot = source_path ? source_path.GetStat("ATK") : 0

	// Wind Shear: stack instead of reapply
	if(dot_type == PATH_DOT_WIND_SHEAR)
		var/datum/status_effect/path_dot/wind_shear/existing = locate() in target.status_effects
		if(existing)
			existing.stacks = min(existing.stacks + 1, 5)
			existing.attacker_atk = atk_snapshot
			existing.attacker_path = source_path
			existing.refresh()
			return existing

	// Determine effect type
	var/effect_type
	switch(dot_type)
		if(PATH_DOT_BLEED)
			effect_type = /datum/status_effect/path_dot/bleed
		if(PATH_DOT_BURN)
			effect_type = /datum/status_effect/path_dot/burn
		if(PATH_DOT_SHOCK)
			effect_type = /datum/status_effect/path_dot/shock
		if(PATH_DOT_WIND_SHEAR)
			effect_type = /datum/status_effect/path_dot/wind_shear
		else
			return null

	// Remove existing DoT of same type (refresh)
	var/datum/status_effect/path_dot/existing = locate(effect_type) in target.status_effects
	if(existing)
		qdel(existing)

	// Apply new DoT
	var/datum/status_effect/path_dot/effect = target.apply_status_effect(effect_type)
	if(effect)
		effect.attacker_path = source_path
		effect.attacker_atk = atk_snapshot
	return effect
