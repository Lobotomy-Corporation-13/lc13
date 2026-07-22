/mob/living/simple_animal/hostile/rcorp_abno/easy/fairy_gentleman
	name = "Fairy Gentleman"
	desc = "A very wide humanoid with long arms made of green, dripping slime. Despite their size they seem quite agile, avoid standing still if they go out of sight."
	maxHealth = 1400
	health = 1400
	ranged = TRUE
	rapid_melee = 1
	melee_queue_distance = 2
	move_to_delay = 2.3
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0.7, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 1, PALE_DAMAGE = 2)
	melee_damage_lower = 20
	melee_damage_upper = 25
	melee_damage_type = WHITE_DAMAGE  //Low damage - makes you drunk on a hit
	is_flying_animal = TRUE
	pixel_x = -34
	base_pixel_x = -34
	original_abno = /mob/living/simple_animal/hostile/abnormality/fairy_gentleman

	var/jump_cooldown = 0
	var/jump_cooldown_time = 8 SECONDS
	var/jump_damage = 100
	var/jump_sound = 'sound/abnormalities/fairygentleman/jump.ogg'
	var/jump_aoe = 2

	var/list/angry = list(
		"I'll wring you out!",
		"Come on, I'm taking you for a ride!",
		"This is all I got!",
		"I'll be havin' this!",
		"Scram!",
	)

	//Action Buttons
	attack_action_types = list(
	/datum/action/innate/rca_abnormality_attack/toggle/FairyJump,
	)

	abno_additional_instructions = "<h1>You are Fairy Gentleman, A Combat Role Abnormality.</h1><br>\
		<b>|Wingbeat|: Due to your fairy wings you are capable of hovering, useful incase of chasms.<br> \
		<br>\
		|Predation|: When attempting to attack a target outside of melee range you will initiate a leap. \
		Upon initiating leap you will briefly disappear before falling onto the targetted area with a delay doing BLACK damage to those hit. \
		If the target falls into a critical state from the leap they will be instantly gibbed. <br> \
		<br>\
		|Stimulating Smell|: Your melee attacks do WHITE, however when attacking insane targets you will instead inflict RED damage. \
		Targets hit by your leap will be made slightly drunk, if the leap hits a target that is overly drunk the damage will be nullified and you will be staggered. <br>\
		</b>"


/mob/living/simple_animal/hostile/rcorp_abno/easy/fairy_gentleman/Initialize()
	. = ..()
	AddComponent(/datum/component/knockback, 1, FALSE, TRUE)

/datum/action/innate/rca_abnormality_attack/toggle/FairyJump
	name = "Toggle Jump"
	button_icon_state = "generic_toggle0"
	chosen_attack_num = 2
	chosen_message = span_colossus("You won't jump anymore.")
	button_icon_toggle_activated = "generic_toggle1"
	toggle_attack_num = 1
	toggle_message = span_colossus("You will now jump with your next attack when possible.")
	button_icon_toggle_deactivated = "generic_toggle0"

/mob/living/simple_animal/hostile/rcorp_abno/easy/fairy_gentleman/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return
	melee_damage_type = WHITE_DAMAGE
	if(jump_cooldown <= world.time && prob(10) && !client)
		FairyJump(attacked_target)
		return
	if(!ishuman(attacked_target))
		return ..()
	var/mob/living/carbon/human/H = attacked_target
	H.drunkenness += 5
	to_chat(H, span_warning("Yuck, some of it got in your mouth!"))
	if(H.sanity_lost)
		melee_damage_type = RED_DAMAGE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/fairy_gentleman/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/fairy_gentleman/OpenFire()
	if(!can_act)
		return FALSE
	if(client)
		if(chosen_attack != 1)
			return
		FairyJump(target)
		return

	var/dist = get_dist(target, src)
	if(jump_cooldown <= world.time)
		var/chance_to_jump = 25
		if(dist > 3)
			chance_to_jump = 100
		if(prob(chance_to_jump))
			FairyJump(target)
		return

// Attacks
/mob/living/simple_animal/hostile/rcorp_abno/easy/fairy_gentleman/proc/FairyJump(mob/living/target)
	if(!isliving(target) && !ismecha(target) || !can_act)
		return
	var/dist = get_dist(target, src)
	if(dist > 1 && jump_cooldown < world.time)
		say(pick(angry))
		jump_cooldown = world.time + jump_cooldown_time
		can_act = FALSE
		SLEEP_CHECK_DEATH(0.25 SECONDS)
		animate(src, alpha = 1, pixel_z = 16, time = 0.1 SECONDS)
		src.pixel_z = 16
		playsound(src, 'sound/abnormalities/ichthys/jump.ogg', 50, FALSE, 4)
		var/turf/target_turf = get_turf(target)
		SLEEP_CHECK_DEATH(1 SECONDS)
		forceMove(target_turf) //look out, someone is rushing you!
		playsound(src, jump_sound, 50, FALSE, 4)
		animate(src, alpha = 255, pixel_z = -16, time = 0.1 SECONDS)
		src.pixel_z = 0
		SLEEP_CHECK_DEATH(0.1 SECONDS)
		var/target_drunk
		for(var/turf/T in view(jump_aoe, src))
			var/obj/effect/temp_visual/small_smoke/halfsecond/FX =  new(T)
			FX.color = "#b52e19"
			for(var/mob/living/L in T)
				if(faction_check_mob(L))
					continue
				if(ishuman(L))
					var/mob/living/carbon/human/H = L
					if(H.drunkenness > 50) // easter egg - being drunk makes you stagger him
						target_drunk = TRUE
						jump_damage = 0
					else
						jump_damage = initial(jump_damage)
				L.deal_damage(jump_damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
				if(L.health < 0)
					L.gib()
			for(var/obj/vehicle/sealed/mecha/V in T)
				V.take_damage(jump_damage, BLACK_DAMAGE)
		var/wait_time = 0.5 SECONDS
		if(target_drunk)
			wait_time += 3.5 SECONDS
			visible_message(span_boldwarning("[src] staggers around, exposing a weak point!"), span_nicegreen("You feel dizzy!"))
		SLEEP_CHECK_DEATH(wait_time)
		can_act = TRUE
