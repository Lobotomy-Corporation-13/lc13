/obj/effect/proc_holder/spell/pointed/chain
	name = "Chain"
	desc = "Use the power of J Corp's Singularity to chain down a single target and prevent them from moving for a limited amount of time."
	active_msg = "You prepare to use Chain on a target."
	deactive_msg = "You decide not to use Chain for now..."
	charge_max = 140
	clothes_req = FALSE
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	action_icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	action_icon_state = "lock"

/obj/effect/proc_holder/spell/pointed/chain/cast(list/targets, mob/user = usr)
	var/mob/living/unfortunate = pick(targets)
	unfortunate.apply_status_effect(/datum/status_effect/arbiter_chain)

/obj/effect/proc_holder/spell/pointed/chain/can_target(atom/target, mob/user, silent)
	if(!istype(target, /mob/living))
		return FALSE
	var/mob/living/our_target = target
	if(faction_check(user.faction, our_target.faction, TRUE))
		return FALSE
	. = ..()

/datum/status_effect/arbiter_chain
	id = "arbiter chain"
	duration = 4 SECONDS
	alert_type = null
	status_type = STATUS_EFFECT_UNIQUE
	var/statuseffectvisual

/datum/status_effect/arbiter_chain/on_apply()
	. = ..()

	// If we target a human:
	if(istype(owner, /mob/living/carbon/human))
		var/mob/living/carbon/human/unfortunate = owner
		// If they're insane, the sanity controller is moving them, and so Immobilize and some other methods of binding them don't work. We use the Incapacitated trait.
		// This has the side effect of preventing them from attacking, too.
		if(unfortunate.sanity_lost)
			ADD_TRAIT(unfortunate, TRAIT_INCAPACITATED, "Singularity J")
		// If the human isn't insane then we just immobilize them. This lets them fight back but they can't move.
		else
			unfortunate.Immobilize(duration, TRUE)
	// If we target a simple_animal/hostile (abnos, distortions, etc)
	if(istype(owner, /mob/living/simple_animal/hostile))
		var/mob/living/simple_animal/hostile/unfortunate = owner
		// I know this looks strange: let me explain.
		// Simplemobs don't really care about you setting Immobilize on them. You can put the Incapacitated trait on them, and they'll stop attacking, but they'll keep moving.
		// I tried some things like increasing their next_move, but it just doesn't work.
		// The only way to actually get them to be still is to shut off their AI and cancel any ongoing movements.
		// Unfortunately this basically deactivates all their thinking and acting. But... well, we just don't have any other way to stop them from moving.

		unfortunate.toggle_ai(AI_OFF)
		unfortunate.Goto(get_turf(unfortunate))
		unfortunate.patrol_reset()

	// Aesthetics: we play a sound and put a lock overlay on them.
	playsound(owner, 'sound/abnormalities/lighthammer/chain.ogg', 40)
	var/mutable_appearance/effectvisual = mutable_appearance('icons/obj/clockwork_objects.dmi', "vanguard")
	effectvisual.pixel_x = -owner.pixel_x
	effectvisual.pixel_y = -owner.pixel_y
	statuseffectvisual = effectvisual
	owner.add_overlay(statuseffectvisual)

/datum/status_effect/arbiter_chain/on_remove()
	owner.cut_overlay(statuseffectvisual)
	if(ishuman(owner))
		REMOVE_TRAIT(owner, TRAIT_INCAPACITATED, "Singularity J")
	var/mob/living/simple_animal/unfortunate = owner
	if(istype(unfortunate))
		unfortunate.toggle_ai(AI_ON)
	return ..()
