// ============================================================
// Dieci Association — Shield HP Component
// ============================================================
// Flat HP shield that absorbs incoming damage before it reaches the mob.
// Built up by Dieci Fist empowerment and Warden skills.
// Decays by half every 10 seconds. Forced damage bypasses the shield.

/// Component providing a damage-absorbing shield HP layer.
/// Registers COMSIG_MOB_APPLY_DAMGE to intercept damage before armor.
/datum/component/dieci_shield_hp
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Current shield HP
	var/shield_health = 0
	/// Maximum shield HP cap
	var/max_shield_health = 500
	/// Looping decay timer ID — halves shield every 10 seconds
	var/decay_timer_id
	/// Optional callback invoked when the shield absorbs damage (for Reactive Ward skill).
	/// Called with (damage_absorbed, atom/damage_source)
	var/datum/callback/on_shield_absorb

/datum/component/dieci_shield_hp/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/dieci_shield_hp/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_damage))

/datum/component/dieci_shield_hp/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_APPLY_DAMGE)
	. = ..()

/datum/component/dieci_shield_hp/Destroy()
	if(decay_timer_id)
		deltimer(decay_timer_id)
		decay_timer_id = null
	on_shield_absorb = null
	// Remove shield visual on cleanup
	var/mob/living/owner = parent
	if(owner && !QDELETED(owner))
		owner.remove_filter("dieci_shield")
	return ..()

// ============================================================
// Shield Management
// ============================================================

/// Add shield HP, capped at max_shield_health. Starts or resets the decay timer.
/datum/component/dieci_shield_hp/proc/add_shield(amount)
	if(amount <= 0)
		return
	shield_health = min(shield_health + amount, max_shield_health)
	if(shield_health > 0 && !decay_timer_id)
		start_decay()
	update_shield_visual()

/// Start the looping 10-second decay timer.
/datum/component/dieci_shield_hp/proc/start_decay()
	if(decay_timer_id)
		deltimer(decay_timer_id)
	decay_timer_id = addtimer(CALLBACK(src, PROC_REF(decay_tick)), 10 SECONDS, TIMER_STOPPABLE | TIMER_LOOP)

/// Halve shield HP each tick. Stop timer when shield is depleted.
/datum/component/dieci_shield_hp/proc/decay_tick()
	shield_health = round(shield_health * 0.5)
	if(shield_health <= 0)
		shield_health = 0
		stop_decay()
	update_shield_visual()

/// Stop the decay timer.
/datum/component/dieci_shield_hp/proc/stop_decay()
	if(decay_timer_id)
		deltimer(decay_timer_id)
		decay_timer_id = null

// ============================================================
// Damage Interception
// ============================================================

/// Signal handler for COMSIG_MOB_APPLY_DAMGE. Absorbs damage into shield HP.
/// Forced damage (DAMAGE_FORCED) bypasses the shield to prevent recursion.
/datum/component/dieci_shield_hp/proc/on_damage(datum/source, damage, damagetype, def_zone, atom/damage_source, flags, attack_type)
	SIGNAL_HANDLER
	// Let forced damage through — prevents recursion from overflow
	if(flags & DAMAGE_FORCED)
		return
	if(shield_health <= 0)
		return
	// Full absorption
	if(damage <= shield_health)
		shield_health -= damage
		spawn_shield_visual()
		if(on_shield_absorb)
			on_shield_absorb.Invoke(damage, damage_source)
		if(shield_health <= 0)
			stop_decay()
			update_shield_visual()
		return COMPONENT_MOB_DENY_DAMAGE
	// Partial absorption — shield breaks, overflow dealt as forced damage
	var/overflow = damage - shield_health
	shield_health = 0
	stop_decay()
	spawn_shield_visual()
	update_shield_visual()
	if(on_shield_absorb)
		on_shield_absorb.Invoke(damage - overflow, damage_source)
	// Deal overflow via INVOKE_ASYNC with DAMAGE_FORCED to skip our handler
	var/mob/living/owner = parent
	INVOKE_ASYNC(owner, TYPE_PROC_REF(/mob/living, deal_damage), overflow, damagetype, damage_source, DAMAGE_FORCED, null, null, def_zone)
	return COMPONENT_MOB_DENY_DAMAGE

// ============================================================
// Visual Feedback
// ============================================================

/// Spawn a brief shield flash visual on the mob.
/datum/component/dieci_shield_hp/proc/spawn_shield_visual()
	var/mob/living/owner = parent
	var/obj/effect/temp_visual/shock_shield/effect = new(get_turf(owner))
	effect.transform *= 0.5
	effect.pixel_x += rand(-8, 8)

/// Update the persistent shield outline visual based on current shield HP.
/datum/component/dieci_shield_hp/proc/update_shield_visual()
	var/mob/living/owner = parent
	if(!owner || QDELETED(owner))
		return
	if(shield_health > 0)
		// Gold outline, intensity scales with shield amount
		var/intensity = clamp(shield_health / max_shield_health, 0.3, 1.0)
		var/size_val = round(1 + intensity)
		owner.add_filter("dieci_shield", 5, list("type" = "outline", "color" = "#FFD70080", "size" = size_val))
	else
		owner.remove_filter("dieci_shield")
