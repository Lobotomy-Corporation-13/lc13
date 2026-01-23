// Point&Click CC that immobilizes your target (in the case of Simplemobs it just shuts off their AI since can_move isn't generalized yet) and deals some damage.
// The on-hit overlay of the chains wrapping around the target was made by Akulvo.
/obj/effect/proc_holder/spell/pointed/chain
	name = "Chain"
	desc = "Use the power of J Corp's Singularity to Chain down a single target, dealing low BLACK damage and sealing their capacity to move for a limited amount of time."
	active_msg = "You prepare to use Chain on a target."
	deactive_msg = "You decide not to use Chain for now..."
	charge_max = 140
	clothes_req = FALSE
	base_icon_state = "chain"
	action_icon_state = "chain"
	var/base_damage = 40
	var/simplemob_coeff = 4 // Hits simplemobs harder

/obj/effect/proc_holder/spell/pointed/chain/cast(list/targets, mob/user = usr)
	var/mob/living/unfortunate = pick(targets)
	if(isliving(unfortunate))
		unfortunate.apply_status_effect(/datum/status_effect/arbiter_chain)
		addtimer(CALLBACK(src, PROC_REF(ChainHit), unfortunate, user), 0.8 SECONDS)
		unfortunate.visible_message(span_danger("[unfortunate] is trapped by strange chains!"))

/obj/effect/proc_holder/spell/pointed/chain/can_target(atom/target, mob/user, silent)
	if(!istype(target, /mob/living))
		return FALSE
	var/mob/living/our_target = target
	if((user.faction_check_mob(our_target, TRUE)))
		return FALSE
	. = ..()

// Timed to hit at a certain point in the animation. Deals minor BLACK damage
/obj/effect/proc_holder/spell/pointed/chain/proc/ChainHit(mob/living/target, mob/user)
	var/final_damage = base_damage
	if(isanimal(target))
		final_damage *= simplemob_coeff
	target.deal_damage(final_damage, BLACK_DAMAGE, source = user, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))
	playsound(target, 'sound/magic/arbiter/chain_hit.ogg', 80, FALSE, 6)

/datum/status_effect/arbiter_chain
	id = "arbiter chain"
	duration = 5 SECONDS
	alert_type = null
	status_type = STATUS_EFFECT_REPLACE
	var/trait_source = "Singularity J - Chain"
	var/datum/status_effect/display/arbiter_chain_visual/attached_visual_status
	var/should_show_chain_overlay = TRUE

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
		unfortunate.toggle_ai(AI_OFF)
		walk_to(unfortunate, 0)

	// Aesthetics: we play a sound and put a lock overlay on them.
	playsound(owner, 'sound/abnormalities/lighthammer/chain.ogg', 40)
	if(should_show_chain_overlay)
		var/image/cool_overlay = image('icons/effects/effects.dmi', loc = owner, icon_state = "binah_chain", layer = owner.layer + 2)
		flick_overlay_view(cool_overlay, owner, 2 SECONDS)
	if(!attached_visual_status)
		attached_visual_status = owner.apply_status_effect(/datum/status_effect/display/arbiter_chain_visual)

	// Ignore this snippet of code. It doesn't matter but I'm keeping here in case I wanna come back to it (it's for scaling the overlay to bigger targets)
	/*var/image/cool_overlay = image('icons/effects/effects.dmi', loc = owner, icon_state = "chain", layer = owner.layer + 1)
	var/icon/target_icon = icon(owner.icon, owner.icon_state, owner.dir)
	var/icon_height = target_icon.Height()
	var/icon_width = target_icon.Width()
	var/width_diff = 32 - icon_width
	cool_overlay.pixel_x -= (width_diff * 0.5)
	if((icon_height > 0) && (icon_width > 0))
		var/matrix/old_matrix = cool_overlay.transform
		var/height_ratio = icon_height / 32
		var/width_ratio = icon_width / 32
		old_matrix.Scale(height_ratio, width_ratio)
		cool_overlay.transform = old_matrix
		cool_overlay.layer += 0.1
	flick_overlay_view(cool_overlay, owner, initial(duration))
	*/

/datum/status_effect/arbiter_chain/on_remove()
	if(ishuman(owner))
		REMOVE_TRAIT(owner, TRAIT_INCAPACITATED, trait_source)
	var/mob/living/simple_animal/unfortunate = owner
	if(istype(unfortunate))
		unfortunate.toggle_ai(AI_ON)
	if(attached_visual_status)
		owner.remove_status_effect(attached_visual_status)
	return ..()

/datum/status_effect/arbiter_chain/be_replaced()
	if(attached_visual_status)
		owner.remove_status_effect(attached_visual_status)
	var/mob/living/simple_animal/unfortunate = owner
	if(istype(unfortunate))
		unfortunate.toggle_ai(AI_OFF)
	. = ..()

// This is an empty status effect that we just use to get the functionality of /status_effect/display so we can stack the icons like tool abnos. Gets removed when the main status is removed.
/datum/status_effect/display/arbiter_chain_visual
	id = "arbiter_chain_visual"
	status_type = STATUS_EFFECT_REPLACE
	duration = -1
	alert_type = null
	display_name = "chained"
