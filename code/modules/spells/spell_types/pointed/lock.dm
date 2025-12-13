// Point&Click CC that stops the target from attacking (they can still use special skills and stuff) and deals minor BLACK damage.
// The on-hit overlay of the lock slamming shut on the target was made by amanitaspooder.
/obj/effect/proc_holder/spell/pointed/lock
	name = "Lock"
	desc = "Use the power of J Corp's Singularity to Lock a single living target's offensive potential, dealing low BLACK damage and preventing them from attacking."
	active_msg = "You prepare to use Lock on a target."
	deactive_msg = "You decide not to use Lock for now..."
	charge_max = 180
	clothes_req = FALSE
	base_icon_state = "lock"
	action_icon_state = "lock"
	var/base_damage = 50
	var/simplemob_coeff = 4 // Hits simplemobs harder

/obj/effect/proc_holder/spell/pointed/lock/cast(list/targets, mob/user = usr)
	var/mob/living/unfortunate = pick(targets)
	if(isliving(unfortunate))
		unfortunate.apply_status_effect(/datum/status_effect/arbiter_lock)
		addtimer(CALLBACK(src, PROC_REF(LockHit), unfortunate, user), 0.6 SECONDS)
		unfortunate.visible_message(span_danger("[unfortunate] is hit by energy in the shape of a lock!"))

/obj/effect/proc_holder/spell/pointed/lock/can_target(atom/target, mob/user, silent)
	if(!istype(target, /mob/living))
		return FALSE
	var/mob/living/our_target = target
	if((our_target.stat >= DEAD) || (user.faction_check_mob(our_target, TRUE)))
		return FALSE
	. = ..()

// Timed to hit at a certain point in the animation
/obj/effect/proc_holder/spell/pointed/lock/proc/LockHit(mob/living/target, mob/user)
	var/final_damage = base_damage
	if(isanimal(target))
		final_damage *= simplemob_coeff
	target.deal_damage(final_damage, BLACK_DAMAGE, source = user, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))
	playsound(target, 'sound/magic/arbiter/lock_hit.ogg', 80, FALSE, 6)

/datum/status_effect/arbiter_lock
	id = "arbiter lock"
	duration = 6 SECONDS
	alert_type = null
	status_type = STATUS_EFFECT_UNIQUE
	var/datum/status_effect/display/arbiter_lock_visual/attached_visual_status

/datum/status_effect/arbiter_lock/on_apply()
	. = ..()

	// If we target a human:
	if(istype(owner, /mob/living/carbon/human))
		var/mob/living/carbon/human/unfortunate = owner
		ADD_TRAIT(unfortunate, TRAIT_PACIFISM, "Singularity J - Lock") // Can't attack! Yikes! Technically they can still use their actions, if any, but I don't feel like going through the hell that would be locking those away too

	// If we target a simple_animal/hostile (abnos, distortions, etc):
	if(istype(owner, /mob/living/simple_animal/hostile))
		var/mob/living/simple_animal/hostile/unfortunate = owner
		ADD_TRAIT(unfortunate, TRAIT_INCAPACITATED, "Singularity J - Lock") // This doesn't stop stuff like DF from using their special attacks due to how they're coded.

	// Aesthetics: we play a sound and put a lock overlay on them.
	playsound(owner, 'sound/magic/arbiter/lock_cast.ogg', 80, FALSE, 6)
	var/image/cool_overlay = image('icons/effects/effects.dmi', loc = owner, icon_state = "binah_lock", layer = owner.layer + 2)
	flick_overlay_view(cool_overlay, owner, 1 SECONDS)
	if(!attached_visual_status)
		attached_visual_status = owner.apply_status_effect(/datum/status_effect/display/arbiter_lock_visual)

/datum/status_effect/arbiter_lock/on_remove()
	if(attached_visual_status)
		owner.remove_status_effect(attached_visual_status)
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, "Singularity J - Lock")
	if(istype(owner, /mob/living/simple_animal/hostile))
		REMOVE_TRAIT(owner, TRAIT_INCAPACITATED, "Singularity J - Lock")
	return ..()

// Empty status effect that we use to get the functionality of /status_effect/display to stack icons like tool abnos. Gets removed when the main status is.
/datum/status_effect/display/arbiter_lock_visual
	id = "arbiter_lock_visual"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	alert_type = null
	display_name = "locked"
