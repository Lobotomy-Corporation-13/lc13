/* This file was created to consolidate all the shared behaviour and procs that the different Indigo Ordeals use in their code. As of 2025/08/10, they all have roughly
the same implementations for stuff like devour(), and the Indigo Ordeal reworks that I'm doing all generally wanna use stuff like the Persistence status and
SweeperHealing() proc, so it'd be much cleaner to just... throw all that in here.
It'd also be interesting to simply have a /mob/living/simple_animal/hostile/ordeal/indigo type that they're all subtypes of, to not crowd the /ordeal type's procs.
Pretty much all sweepers have modifications to their targeting, AttackingTarget() and some others, so it'd be nice to... not do that on each file.
Something for a future refactor?
*/
#define STATUS_EFFECT_PERSISTENCE /datum/status_effect/stacking/sweeper_persistence

/mob/living/simple_animal/hostile/ordeal/proc/SweeperDevour(mob/living/L)
	if(!L)
		return FALSE
	if(ishuman(L) && (SSmaptype.maptype in SSmaptype.citymaps))
		return FALSE
	visible_message(
		span_danger("[src] devours [L]!"),
		span_userdanger("You feast on [L], restoring your health!"))
	// Feeding on another sweeper will heal you for 10% of THEIR max health. Feeding on a dawn is 11 health, feeding on a default Noon is 50 health, and so on.
	if(faction_check_mob(L, TRUE)) // This check formerly used SWEEPER_TYPES define, however it... didn't work? So it is a faction check now.
		SweeperHealing(L.maxHealth*0.1)
	// Feeding on a non-sweeper will give us 40% of our max health, capped at a flat 1500 (for the special case of the Matriarch).
	else
		SweeperHealing(min(maxHealth * 0.4), 1500)
	L.gib()
	return TRUE

/mob/living/simple_animal/hostile/ordeal/proc/SweeperHealing(amount)
	src.adjustBruteLoss(-amount)
	new /obj/effect/temp_visual/heal(get_turf(src), "#70f54f")

/mob/living/simple_animal/hostile/ordeal/proc/GainPersistence(stacks_gained)
	var/datum/status_effect/stacking/sweeper_persistence/locked_in = src.has_status_effect(STATUS_EFFECT_PERSISTENCE)
	if(!locked_in)
		src.apply_status_effect(STATUS_EFFECT_PERSISTENCE)
		if(stacks_gained>1)
			var/datum/status_effect/stacking/sweeper_persistence/just_applied = src.has_status_effect(STATUS_EFFECT_PERSISTENCE)
			if(just_applied)
				just_applied.add_stacks(stacks_gained - 1)

	else
		locked_in.add_stacks(stacks_gained)
	return TRUE


/* Persistence Status Effect
It allows them to avoid death when struck, with some VFX/SFX indicating that it was activated.
Every time it activates, it loses a stack, but it can also time out over a long period of time.
*/

/datum/status_effect/stacking/sweeper_persistence
	id = "persistence"
	status_type = STATUS_EFFECT_MULTIPLE
	duration = 45 SECONDS
	alert_type = null
	var/mutable_appearance/overlay
	stacks = 1
	max_stacks = 3
	stack_decay = 0
	consumed_on_threshold = FALSE
	var/base_chance = 25
	var/health_recovery_per_stack = 40

/// I don't really want it to decay, so
/datum/status_effect/stacking/sweeper_persistence/tick()
	if(!can_have_status())
		qdel(src)

/datum/status_effect/stacking/sweeper_persistence/on_apply()
	. = ..()

	if(!owner)
		return
	var/icon/sweepericon = icon(owner.icon, owner.icon_state, owner.dir)
	var/icon_height = sweepericon.Height()
	overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/tegu_effects.dmi', "sweeper_persistence", -MUTATIONS_LAYER)
	overlay.pixel_x = 4
	overlay.pixel_y = icon_height - 28
	if(icon_height == 32)
		overlay.transform *= 0.80
	owner.add_overlay(overlay)
	RegisterSignal(owner, COMSIG_MOB_APPLY_DAMGE, PROC_REF(CheckDeath))

/datum/status_effect/stacking/sweeper_persistence/add_stacks(stacks_added)
	. = ..()
	/// I don't think I have to do any further cleanup, it should get qdel'd by Process() right?
	if(stacks <= 0)
		if(owner)
			owner.remove_status_effect(STATUS_EFFECT_PERSISTENCE)
		return
	/// Refresh the duration on Persistence after gaining or losing a stack.
	refresh()

/datum/status_effect/stacking/sweeper_persistence/on_remove()
	. = ..()
	if(!owner)
		return
	owner.cut_overlay(overlay)
	UnregisterSignal(src, COMSIG_MOB_APPLY_DAMGE)

/// This check was taken from Welfare Core's code. Altered to work on simplemobs instead.
/datum/status_effect/stacking/sweeper_persistence/proc/CheckDeath(datum_source, amount, damagetype, def_zone)
	SIGNAL_HANDLER
	if(!owner)
		return
	var/mob/living/simple_animal/hostile/ordeal/neighbor = owner
	/// We get the resistance from the sweeper's resistances datum.
	var/damage_coefficient = neighbor.damage_coeff.getCoeff(damagetype)
	/// The original damage received is given to us by the signal we're handling.
	var/damage_taken = amount * damage_coefficient
	/// No point in doing anything if the damage wouldn't kill the sweeper.
	if(damage_taken <= 0)
		return
	/// This stores "overkill" damage to reduce the chance of Persistence proccing (60 health takes 100 damage is 40 overkill damage)
	var/overkill_damage = damage_taken - neighbor.health
	/// Chance to proc Persistence is calculated here based on stacks. It can't be higher than 100 because... I don't know what happens if it's higher.
	/// Chances should be as follows (%, stack amt.): 50, 1 | 75, 2 | 100, 3
	/// Chance is lowered by Overkill damage to make using slower weapons less of a pain.
	var/chance = min(base_chance + stacks*25, 100)
	/// This can result in negative chances but it hasn't runtimed in my testing so all's fine right?
	var/final_chance = overkill_damage ? chance - (floor(overkill_damage / 5)) : chance

	var/trigger_healing = health_recovery_per_stack*stacks
	if(damage_taken >= neighbor.health)
		/// But it refused. Persistence goes off, we heal a tiny bit and lose a stack
		if(prob(final_chance))
			playsound(neighbor, 'sound/effects/ordeals/indigo_start.ogg', 33)
			INVOKE_ASYNC(neighbor, TYPE_PROC_REF(/mob/living/simple_animal/hostile/ordeal, SweeperHealing), trigger_healing)
			INVOKE_ASYNC(neighbor, TYPE_PROC_REF(/atom, visible_message), span_danger("[neighbor] endures a fatal hit, some of the fuel being drained from its tank!"), span_userdanger("You suffer a lethal strike, losing some of your fuel!"))
			if(src)
				src.add_stacks(-1)
			return COMPONENT_MOB_DENY_DAMAGE
		/// Tough luck neighbor. Persistence didn't go off so the sweeper dies here. Status should get cleaned up next time it ticks.
		else
			playsound(neighbor, 'sound/misc/splort.ogg', 100)
			owner.cut_overlay(overlay)

	return



#undef STATUS_EFFECT_PERSISTENCE
