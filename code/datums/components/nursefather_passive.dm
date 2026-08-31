// Shared passive component for Nursefather roles (Index Oracle Proxy, Ring Corporist Maestro,
// Thumb Ex Sottocapo) and their apprentices. Grants precognitive evasion at the cost of
// permanent clone damage on every wound.
//
// Effects:
//   - Guaranteed evade once every 30 seconds against melee/ranged attacks.
//   - 50% random dodge against melee/ranged attacks when not holding an ego weapon.
//   - 5% of all incoming damage applied as unhealable clone damage (excluding simple mob sources).
/datum/component/nursefather_passive
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Whether the guaranteed evade is available
	var/guaranteed_evade_ready = TRUE

/datum/component/nursefather_passive/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE

/datum/component/nursefather_passive/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_damage_taken))

/datum/component/nursefather_passive/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_APPLY_DAMGE)

/datum/component/nursefather_passive/proc/on_damage_taken(datum/source, damage, damagetype, def_zone, attack_source, flags, attack_type)
	SIGNAL_HANDLER
	if(!damage || damage <= 0)
		return

	var/mob/living/carbon/human/H = parent
	if(!istype(H))
		return

	var/is_evadable_attack = (attack_type & ATTACK_TYPE_MELEE) || (attack_type & ATTACK_TYPE_RANGED)

	if(is_evadable_attack && guaranteed_evade_ready)
		var/turf/T = get_step(H, pick(GLOB.cardinals))
		if(T && !T.density)
			H.forceMove(T)
			playsound(H, 'sound/weapons/black_silence/evasion.ogg', 50, TRUE)
			guaranteed_evade_ready = FALSE
			addtimer(CALLBACK(src, PROC_REF(recharge_guaranteed_evade)), 30 SECONDS)
			return COMPONENT_MOB_DENY_DAMAGE

	var/obj/item/held = H.get_active_held_item()
	var/holding_ego_weapon = istype(held, /obj/item/ego_weapon)

	if(!holding_ego_weapon && is_evadable_attack && prob(50))
		var/turf/T = get_step(H, pick(GLOB.cardinals))
		if(T && !T.density)
			H.forceMove(T)
			playsound(H, 'sound/weapons/black_silence/evasion.ogg', 50, TRUE)
			return COMPONENT_MOB_DENY_DAMAGE

	if(!istype(attack_source, /mob/living/simple_animal))
		var/clone_damage = damage * 0.05
		if(clone_damage > 0)
			INVOKE_ASYNC(src, PROC_REF(apply_clone_damage), clone_damage)

/datum/component/nursefather_passive/proc/recharge_guaranteed_evade()
	guaranteed_evade_ready = TRUE

/datum/component/nursefather_passive/proc/apply_clone_damage(damage)
	var/mob/living/L = parent
	if(QDELETED(L) || L.stat == DEAD)
		return
	L.adjustCloneLoss(damage)

/// Middle Nursefather variant: no dodge, 2.5% clone damage instead of 5%
/datum/component/nursefather_passive/middle

/datum/component/nursefather_passive/middle/on_damage_taken(datum/source, damage, damagetype, def_zone, attack_source, flags, attack_type)
	if(!damage || damage <= 0)
		return

	var/mob/living/carbon/human/H = parent
	if(!istype(H))
		return

	if(!istype(attack_source, /mob/living/simple_animal))
		var/clone_damage = damage * 0.025
		if(clone_damage > 0)
			INVOKE_ASYNC(src, PROC_REF(apply_clone_damage), clone_damage)
