#define BIGBIRD_HYPNOSIS_COOLDOWN (16 SECONDS)
//You see, funnily enough this is a support, while Big Bird is a abno with a instakill it cant use it reliably as 99% of RCorp has ranged weaponry and mechs are immune
//So its thrown into support because of this and its ability to shortly stun which combat abnos can make use of easily
/mob/living/simple_animal/hostile/rcorp_abno/hard/big_bird
	name = "Big Bird"
	desc = "A large, many-eyed bird that patrols the dark forest with an everlasting lamp. \
	Unlike regular birds, it lacks wings and instead has long arms with which it can pick things up. \
	The lamp may draw you closer but avoid proximity at all costs."
	ranged = TRUE
	maxHealth = 2000
	health = 2000
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 1.5)
	see_in_dark = 10
	move_to_delay = 5
	light_color = COLOR_ORANGE
	light_range = 5
	light_power = 7
	melee_damage_type = BLACK_DAMAGE
	melee_damage_lower = 100
	melee_damage_upper = 100
	original_abno = /mob/living/simple_animal/hostile/abnormality/big_bird

	var/bite_cooldown
	var/bite_cooldown_time = 8 SECONDS
	var/hypnosis_cooldown
	var/hypnosis_cooldown_time = 16 SECONDS

	abno_additional_instructions = "<h1>You are Pygmalion, A Support Role Abnormality.</h1><br>\
		|Lamp that Burns Forever|: Your lamp passively emits light within a 5 tile range, alerting others of your location. <br>\
		<br>\
		|Patrol|: Whenever you move you will create loud stomps alerting others of your location. <br>\
		<br>\
		|Dazzle|: When used you will attempt to enchant all hostile humans within a 8 tile sightline of yourself. \
		This will only succeed in 2 out of 3 humans, when it succeeds they will be given 2 seconds to retreat. \
		After those 2 seconds they will become stunned for 2 seconds. <br>\
		<br>\
		|Salvation|: You may not melee humans, instead you will attempt to bite them. \
		When biting a human you will instantly remove their head resulting in death. \
		This has a 8 second cooldown so you are incapable of killing multiple in a row. </b>"

	//PLAYABLES ATTACKS
	attack_action_types = list(/datum/action/cooldown/rca_big_bird_hypnosis)

/datum/action/cooldown/rca_big_bird_hypnosis
	name = "Dazzle"
	icon_icon = 'icons/mob/actions/actions_abnormality.dmi'
	button_icon_state = "big_bird"
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE
	cooldown_time = BIGBIRD_HYPNOSIS_COOLDOWN //16 seconds

/datum/action/cooldown/rca_big_bird_hypnosis/Trigger()
	if(!..())
		return FALSE
	if(!istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/hard/big_bird))
		return FALSE
	var/mob/living/simple_animal/hostile/rcorp_abno/hard/big_bird/big_bird = owner
	StartCooldown()
	big_bird.hypnotize()
	return TRUE

/mob/living/simple_animal/hostile/rcorp_abno/hard/big_bird/OpenFire()
	if(client)
		return

	if(get_dist(src, target) > 2 && hypnosis_cooldown <= world.time)
		hypnotize()

/mob/living/simple_animal/hostile/rcorp_abno/hard/big_bird/Moved()
	. = ..()
	playsound(get_turf(src), 'sound/abnormalities/bigbird/step.ogg', 50, 1)

/mob/living/simple_animal/hostile/rcorp_abno/hard/big_bird/CanAttack(atom/the_target)
	if(ishuman(the_target))
		if(bite_cooldown > world.time)
			return FALSE
		var/mob/living/carbon/human/H = the_target
		var/obj/item/bodypart/head/head = H.get_bodypart("head")
		if(!istype(head)) // You, I'm afraid, are headless
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/big_bird/MovedTryAttack() //To prevent BB from practically having 2 range
	return FALSE

/mob/living/simple_animal/hostile/rcorp_abno/hard/big_bird/AttackingTarget(atom/attacked_target)
	if(ishuman(attacked_target))
		if(bite_cooldown > world.time)
			return FALSE
		var/mob/living/carbon/human/H = attacked_target
		var/obj/item/bodypart/head/head = H.get_bodypart("head")
		H.client?.give_award(/datum/award/achievement/abno/headless, H)
		if(QDELETED(head))
			return
		head.dismember()
		QDEL_NULL(head)
		H.regenerate_icons()
		visible_message(span_danger("\The [src] bites [H]'s head off!"))
		new /obj/effect/gibspawner/generic/silent(get_turf(H))
		playsound(get_turf(src), 'sound/abnormalities/bigbird/bite.ogg', 50, 1, 2)
		flick("big_bird_chomp", src)
		bite_cooldown = world.time + bite_cooldown_time
		return
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/big_bird/proc/hypnotize()
	if(hypnosis_cooldown > world.time)
		return
	hypnosis_cooldown = world.time + hypnosis_cooldown_time
	playsound(get_turf(src), 'sound/abnormalities/bigbird/hypnosis.ogg', 50, 1, 2)
	for(var/mob/living/carbon/C in view(8, src))
		if(faction_check_mob(C, FALSE))
			continue
		if(!CanAttack(C))
			continue
		if(ismoth(C))
			pick(C.emote("scream"), C.visible_message(span_boldwarning("[C] lunges for the light!")))
			C.throw_at((src), 10, 2)
		if(prob(66))
			to_chat(C, span_warning("You feel tired..."))
			C.blur_eyes(5)
			addtimer(CALLBACK (C, TYPE_PROC_REF(/mob, blind_eyes), 2), 2 SECONDS)
			addtimer(CALLBACK (C, TYPE_PROC_REF(/mob/living, Stun), 2 SECONDS), 2 SECONDS)
			var/new_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/tegu_effects.dmi', "enchanted", -HALO_LAYER)
			C.add_overlay(new_overlay)
			addtimer(CALLBACK (C, TYPE_PROC_REF(/atom, cut_overlay), new_overlay), 4 SECONDS)

#undef BIGBIRD_HYPNOSIS_COOLDOWN
