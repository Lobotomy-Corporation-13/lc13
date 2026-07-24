//2 Phase abno with the potential to negate death once makes this a tank
/mob/living/simple_animal/hostile/rcorp_abno/easy/kqe
	name = "KQE-1J-23"
	desc = "A mechanical puppet composed of metal plates, lights, and integrated circuits. Bare wires protrude with its every movement."
	health = 1500
	maxHealth = 1500
	del_on_death = FALSE
	melee_damage_type = BLACK_DAMAGE
	damage_coeff = list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1, PALE_DAMAGE = 1.2)
	melee_damage_lower = 20
	melee_damage_upper = 25
	move_to_delay = 3
	ranged = TRUE
	original_abno = /mob/living/simple_animal/hostile/abnormality/kqe

	var/grab_cooldown
	var/grab_cooldown_time = 15 SECONDS
	var/grab_damage = 120
	var/heart = FALSE
	var/heart_threshold = 700

	//PLAYABLE ATTACKS
	attack_action_types = list(/datum/action/innate/rca_abnormality_attack/toggle/kqe_grab_toggle)

	abno_additional_instructions = "<h1>You are KQE-1J-23, A Tank Role Abnormality.</h1><br>\
		<b>|Initiating Town Tour|: Your melee attack is entirely replaced with a 5x5 choreographed AoE centered around yourself.<br>\
		<br>\
		|Transfer Reg|: Your special ability allows you to target a tile for Transfer Reg.\
		After a 5 second delay you will send a claw down upon the targetted tile and grab any hostile humans within 1 tile of the claw.\
		The claw is also capable of pulling pilots out of mechs, those grabbed are held in place for 6 seconds.<br>\
		<br>\
		|System Error Detected|: When your health falls below 46% your resistances will be greatly increased however you will also enter System Reboot.\
		System Reboot will leave you staggered for 10 seconds in which you are unable to act.</b>"

/mob/living/simple_animal/hostile/rcorp_abno/easy/kqe/examine(mob/user)
	. = ..()
	if(heart)
		. += "It's currently drawing full power out of it's components, it has no weaknesses after rebooting."
	else
		. += "It seems quite weak however it looks to not be using it's full potential."

/datum/action/innate/rca_abnormality_attack/toggle/kqe_grab_toggle
	name = "Toggle Claw Attack"
	button_icon_state = "kqe_toggle0"
	chosen_attack_num = 2
	chosen_message = span_colossus("You won't grab visitors anymore.")
	button_icon_toggle_activated = "kqe_toggle1"
	toggle_attack_num = 1
	toggle_message = span_colossus("You will attempt to grab visitors.")
	button_icon_toggle_deactivated = "kqe_toggle0"

/*** Basic Procs ***/
/mob/living/simple_animal/hostile/rcorp_abno/easy/kqe/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/kqe/Moved()
	playsound(get_turf(src), 'sound/abnormalities/nothingthere/walk.ogg', 50, 0, 3)
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/kqe/Life()
	. = ..()
	if(!.) // Dead
		return FALSE
	if(health >= heart_threshold)
		return
	if(!heart)
		revive(full_heal = TRUE, admin_revive = FALSE)//fully heal and spawn a heart
		say("Please cooperate! Please Cooperrr... Csdk..ppra...@#@%!%^#$")
		heart = TRUE
		ChangeResistances(list(RED_DAMAGE = 0.3, WHITE_DAMAGE = 0.2, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 0.2)) //KQE is often regarded as weak and easily dodged so he is being given this buff as a freebie
		Stagger() //The fact KQE gets stunned for 10 seconds infront of RCorp I believe justifies this
		manual_emote("blares random letters on its terminal before turning it off.")

/mob/living/simple_animal/hostile/rcorp_abno/easy/kqe/death()
	if(!heart)
		return Life()//PRANKED!
	can_act = FALSE
	icon = 'ModularLobotomy/_Lobotomyicons/abno_cores/he.dmi'
	icon_state = icon_dead
	pixel_x = -16
	base_pixel_x = -16
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)
	..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/kqe/proc/Stagger()
	can_act = FALSE
	icon_state = "kqe_prepare"
	SLEEP_CHECK_DEATH(10 SECONDS)
	icon_state = icon_living
	can_act = TRUE

/mob/living/simple_animal/hostile/rcorp_abno/easy/kqe/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return FALSE
	if ((grab_cooldown <= world.time) && prob(35) && (!client))//checks for client since you can still use the claw if you click nearby
		var/turf/target_turf = get_turf(attacked_target)
		return ClawGrab(target_turf)
	if(!target)
		GiveTarget(attacked_target)
	return Whip_Attack()

/mob/living/simple_animal/hostile/rcorp_abno/easy/kqe/proc/Whip_Attack()
	can_act = FALSE
	face_atom(target)
	playsound(get_turf(src), attack_sound, 75, 0, 3)
	icon_state = "kqe_prepare"
	SLEEP_CHECK_DEATH(10)
	for(var/turf/T in view(2, src))
		new /obj/effect/temp_visual/smash_effect(T)
		HurtInTurf(T, list(), melee_damage_upper, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, hurt_structure = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	icon_state = "kqe_prepare2"
	SLEEP_CHECK_DEATH(3)
	icon_state = icon_living
	can_act = TRUE


/mob/living/simple_animal/hostile/rcorp_abno/easy/kqe/OpenFire()
	if(!can_act)
		return
	if(client)
		switch (chosen_attack)
			if (1)
				ClawGrab(target)
			if (2)
				return
		return
	if(grab_cooldown <= world.time)
		ClawGrab(target)
	return

/mob/living/simple_animal/hostile/rcorp_abno/easy/kqe/proc/ClawGrab(target)
	if(grab_cooldown > world.time)
		return
	grab_cooldown = world.time + grab_cooldown_time
	can_act = FALSE
	face_atom(target)
	playsound(get_turf(src), 'sound/abnormalities/kqe/load1.ogg', 75, 0, 3)
	icon_state = "kqe_prepare"
	var/grab_delay = (get_dist(src, target) <= 2) ? (1 SECONDS) : (0.5 SECONDS)
	SLEEP_CHECK_DEATH(grab_delay)
	icon_state = "kqe_grab"
	new /obj/effect/kqe_claw(get_turf(target))
	SLEEP_CHECK_DEATH(5 SECONDS)
	icon_state = icon_living
	can_act = TRUE

//Claw target object
/obj/effect/rca_kqe_claw
	name = "approaching claw"
	desc = "LOOK OUT!"
	icon = 'icons/effects/effects.dmi'
	icon_state = "tbird_bolt"
	color = COLOR_VIOLET
	move_force = INFINITY
	pull_force = INFINITY
	generic_canpass = FALSE
	movement_type = PHASING | FLYING
	var/boom_damage = 90
	var/grabbed
	layer = POINT_LAYER//Sprite should always be visible

/obj/effect/rca_kqe_claw/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(GrabAttack)), 3 SECONDS)

/obj/effect/rca_kqe_claw/proc/GrabAttack()
	playsound(get_turf(src), 'sound/abnormalities/kqe/load2.ogg', 75, 0, 3)
	new /obj/effect/temp_visual/approaching_claw(get_turf(src))
	alpha = 1
	for(var/obj/vehicle/sealed/mecha/M in view(1, src))
		M.ejectall()
	for(var/mob/living/carbon/human/H in view(1, src))
		grabbed = TRUE
		H.deal_damage(boom_damage, BLACK_DAMAGE, src, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))
		H.forceMove(get_turf(src))//pulls them all to the target
		GrabStun(H)
	if(grabbed)
		sleep(10 SECONDS)
	qdel(src)

/obj/effect/rca_kqe_claw/proc/GrabStun(mob/living/carbon/human/target)
	animate(target, pixel_x = 0, pixel_z = 12, time = 5)
	target.Stun(6 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(AnimateBack),target), 6 SECONDS)

/obj/effect/rca_kqe_claw/proc/AnimateBack(mob/living/carbon/human/target)
	animate(target, pixel_x = 0, pixel_z = 0, time = 1 SECONDS)
	return TRUE
