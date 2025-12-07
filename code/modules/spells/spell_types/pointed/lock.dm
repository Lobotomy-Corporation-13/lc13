/obj/effect/proc_holder/spell/pointed/lock
	name = "Lock"
	desc = "Use the power of J Corp's Singularity to Lock a single target's offensive potential, preventing them from attacking."
	active_msg = "You prepare to use Chain on a target."
	deactive_msg = "You decide not to use Chain for now..."
	charge_max = 20
	clothes_req = FALSE
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	action_icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	action_icon_state = "lock"

/obj/effect/proc_holder/spell/pointed/lock/cast(list/targets, mob/user = usr)
	var/mob/living/unfortunate = pick(targets)
	unfortunate.apply_status_effect(/datum/status_effect/arbiter_lock)

/obj/effect/proc_holder/spell/pointed/lock/can_target(atom/target, mob/user, silent)
	if(!istype(target, /mob/living))
		return FALSE
	var/mob/living/our_target = target
	if(faction_check(user.faction, our_target.faction, TRUE))
		return FALSE
	. = ..()

/datum/status_effect/arbiter_lock
	id = "arbiter lock"
	duration = 6 SECONDS
	alert_type = null
	status_type = STATUS_EFFECT_UNIQUE
	var/statuseffectvisual

/datum/status_effect/arbiter_lock/on_apply()
	. = ..()

	// If we target a human:
	if(istype(owner, /mob/living/carbon/human))
		var/mob/living/carbon/human/unfortunate = owner
		ADD_TRAIT(unfortunate, TRAIT_PACIFISM, "Singularity J") // Can't attack! Yikes! Technically they can still use their actions, if any, but I don't feel like going through the hell that would be locking those away too

	// If we target a simple_animal/hostile (abnos, distortions, etc):
	if(istype(owner, /mob/living/simple_animal/hostile))
		var/mob/living/simple_animal/hostile/unfortunate = owner
		ADD_TRAIT(unfortunate, TRAIT_INCAPACITATED, "Singularity J") // This doesn't stop stuff like DF from using their special attacks due to how they're coded.

	// Aesthetics: we play a sound and put a lock overlay on them.
	playsound(owner, 'sound/abnormalities/lighthammer/chain.ogg', 40)
	var/mutable_appearance/effectvisual = mutable_appearance('icons/obj/clockwork_objects.dmi', "vanguard")
	effectvisual.pixel_x = -owner.pixel_x
	effectvisual.pixel_y = -owner.pixel_y
	statuseffectvisual = effectvisual
	owner.add_overlay(statuseffectvisual)

/datum/status_effect/arbiter_lock/on_remove()
	owner.cut_overlay(statuseffectvisual)
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, "Singularity J")
	if(istype(owner, /mob/living/simple_animal/hostile))
		REMOVE_TRAIT(owner, TRAIT_INCAPACITATED, "Singularity J")
	return ..()
