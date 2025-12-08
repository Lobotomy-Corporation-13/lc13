/obj/effect/proc_holder/spell/pointed/chain
	name = "Chain"
	desc = "Use the power of J Corp's Singularity to Chain down a single target, sealing their capacity to move for a limited amount of time."
	active_msg = "You prepare to use Chain on a target."
	deactive_msg = "You decide not to use Chain for now..."
	charge_max = 140
	clothes_req = FALSE
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	action_icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	action_icon_state = "lock"
	var/damage_type = BLACK_DAMAGE
	var/base_damage = 40
	var/simplemob_coeff = 4
	var/pale_coeff = 0.8

/obj/effect/proc_holder/spell/pointed/chain/cast(list/targets, mob/user = usr)
	var/mob/living/unfortunate = pick(targets)

	var/final_damage = base_damage
	if(damage_type == PALE_DAMAGE)
		final_damage *= pale_coeff
	if(isanimal(unfortunate))
		final_damage *= simplemob_coeff
	unfortunate.deal_damage(final_damage, damage_type, source = user, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))

	unfortunate.apply_status_effect(/datum/status_effect/arbiter_chain, damage_type)

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
	var/trait_source = "Singularity J - Chain"
	var/damage_type = BLACK_DAMAGE

/datum/status_effect/arbiter_chain/on_creation(mob/living/new_owner, damagetype, ...)
	. = ..()
	damage_type = damagetype

/datum/status_effect/arbiter_chain/on_apply()
	. = ..()

	// If we target a human:
	if(istype(owner, /mob/living/carbon/human))
		var/mob/living/carbon/human/unfortunate = owner
		// If they're insane, the sanity controller is moving them, and so Immobilize and some other methods of binding them don't work. We use the Incapacitated trait.
		// This has the side effect of preventing them from attacking, too.
		if(unfortunate.sanity_lost)
			ADD_TRAIT(unfortunate, TRAIT_INCAPACITATED, trait_source)
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

		unfortunate.patrol_reset()
		unfortunate.Goto(get_turf(unfortunate))
		unfortunate.toggle_ai(AI_OFF)

	// Aesthetics: we play a sound and put a lock overlay on them.
	playsound(owner, 'sound/abnormalities/lighthammer/chain.ogg', 40)
	var/image/cool_overlay = image('icons/effects/effects.dmi', loc = owner, icon_state = "chain", layer = owner.layer + 1)
	var/icon/target_icon = icon(owner.icon, owner.icon_state, owner.dir)
	var/icon_height = target_icon.Height()
	var/icon_width = target_icon.Width()
	var/width_diff = 32 - icon_width
	cool_overlay.pixel_x -= (width_diff * 0.5)
	var/appropiate_color = "#DABB04"
	switch(damage_type)
		if(RED_DAMAGE)
			appropiate_color = "#D70000"
		if(WHITE_DAMAGE)
			appropiate_color = "#DDDDDD"
		if(BLACK_DAMAGE)
			appropiate_color = "#DABB04"
		if(PALE_DAMAGE)
			appropiate_color = "#45F7F7"
	cool_overlay.color = appropiate_color
	if((icon_height > 0) && (icon_width > 0))
		var/matrix/old_matrix = cool_overlay.transform
		var/height_ratio = icon_height / 32
		var/width_ratio = icon_width / 32
		old_matrix.Scale(height_ratio, width_ratio)
		cool_overlay.transform = old_matrix
		cool_overlay.layer += 0.1
	flick_overlay_view(cool_overlay, owner, initial(duration))

/datum/status_effect/arbiter_chain/on_remove()
	if(ishuman(owner))
		REMOVE_TRAIT(owner, TRAIT_INCAPACITATED, trait_source)
	var/mob/living/simple_animal/unfortunate = owner
	if(istype(unfortunate))
		unfortunate.toggle_ai(AI_ON)
	return ..()
