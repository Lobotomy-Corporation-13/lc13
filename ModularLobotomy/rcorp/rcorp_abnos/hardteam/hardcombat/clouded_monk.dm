//Placed in combat for obvious reasons
/mob/living/simple_animal/hostile/rcorp_abno/hard/clouded_monk
	name = "Clouded Monk"
	desc = "A monk that has forgotten he has become a demon. It resembles a preta from legends. Seems ravenous and agile, likely to have a devastating charge."
	maxHealth = 2500
	health = 2500
	rapid_melee = 2
	ranged = TRUE
	damage_coeff = list(BRUTE = 1.0, RED_DAMAGE = 1.2, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.5)
	melee_damage_lower = 30
	melee_damage_upper = 45
	obj_damage = 22 //otherwise his charge just destroys everything
	melee_damage_type = RED_DAMAGE
	see_in_dark = 10
	original_abno = /mob/living/simple_animal/hostile/abnormality/clouded_monk

	var/datum/looping_sound/cloudedmonk_ambience/soundloop
	var/charging = FALSE
	var/revving_charge = FALSE
	var/charge_ready = FALSE
	var/monk_charge_cooldown = 0
	var/monk_charge_cooldown_time = 6 SECONDS
	var/deathcount
	var/heal_amount = 250
	var/charge_damage = 350
	var/eaten = FALSE
	var/damage_taken
	var/slam_damage = 100

	abno_additional_instructions = "<h1>You are Clouded Monk, A Combat Role Abnormality.</h1><br>\
		<b>|Amrita|: When taking 200 damage (losing 8% of your total health) your charge will be ready. \
		Once a charge is ready future damage will not contribute towards a new charge until the current one is used. \
		After attempting a ranged attack you will initiate the charge at wherever you clicked. \
		For the duration of the charge you will not take any form of damage. \
		You will perform 3 charges back and forth, making a 5x5 slam centered around yourself at the end of each charge. \
		If you directly impact with your charge you will trigger |Sarira|, directly impacting a living being also ends the charge. <br>\
		<br>\
		|Sarira|: When your charge directly hits a living being instead of slamming you will instead bite down for incredibly high damage and prematurely end the charge. \
		Non-humans only take 10% of charge damage, if the damaged being is human and is taken into critical state by this attack they will be consumed. \
		Consuming a human heals you for 10% of your HP. \
		Impacting a vehicle such as a mech will deal 150% of charge damage instead. \
		If impacting a structure or vehicle instead of biting you will instead maul it, repeatedly attacking until broken our out of your way.</b>"

	attack_action_types = list(/datum/action/innate/rca_abnormality_attack/toggle/monk_charge,)

/datum/action/innate/rca_abnormality_attack/toggle/monk_charge
	name = "Toggle Triple Charge"
	button_icon_state = "kog_charge" //placeholder, also recode toggle actions to not need this var
	chosen_attack_num = 0
	chosen_message = span_colossus("You won't charge anymore.")
	button_icon_toggle_activated = "kog_charge1"
	toggle_attack_num = 1 //Activate() and Deactivate() need to be flipped for this naming to make sense
	toggle_message = span_colossus("You will now triple charge at the target you click on if damaged enough.")
	button_icon_toggle_deactivated = "kog_charge"

/mob/living/simple_animal/hostile/rcorp_abno/hard/clouded_monk/Initialize()
	. = ..()
	playsound(src, 'sound/abnormalities/clouded_monk/howl.ogg', 50, 1)
	playsound(src, 'sound/abnormalities/clouded_monk/transform.ogg', 50, 1)
	icon_state = "pretamonk"
	soundloop = new(list(src), FALSE)
	soundloop.start()

/mob/living/simple_animal/hostile/rcorp_abno/hard/clouded_monk/Destroy()
	soundloop.stop()
	QDEL_NULL(soundloop)
	return ..()

//breach code
/mob/living/simple_animal/hostile/rcorp_abno/hard/clouded_monk/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(revving_charge || charging) //ignore damage taken while charging, we reset it after a triple charge
		return
	if(. > 0)
		damage_taken += .
	if(damage_taken >= 200 && !charge_ready)
		charge_ready = TRUE
		to_chat(src, span_userdanger("YOU ARE READY TO CHARGE!"))

/mob/living/simple_animal/hostile/rcorp_abno/hard/clouded_monk/Goto(target, delay, minimum_distance)
	if(revving_charge || charging)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/clouded_monk/MoveToTarget(list/possible_targets)
	if(revving_charge || charging)
		return TRUE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/clouded_monk/Move()
	if(revving_charge)
		return FALSE
	if(charging)
		new /obj/effect/temp_visual/decoy/fading(loc,src)
		DestroySurroundings() //to break tables ssin the way
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/clouded_monk/AttackingTarget(atom/attacked_target)
	if(revving_charge || charging)
		return
	if(monk_charge_cooldown <= world.time && prob(33) && !client && charge_ready)
		TripleCharge(attacked_target)
		return
	. = ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/clouded_monk/OpenFire()
	if(revving_charge || charging)
		return
	if(client && monk_charge_cooldown <= world.time && charge_ready)
		switch(chosen_attack)
			if(1)
				TripleCharge(target)
		return

	if(monk_charge_cooldown <= world.time && prob(33) && charge_ready)
		TripleCharge(target)

/mob/living/simple_animal/hostile/rcorp_abno/hard/clouded_monk/proc/TripleCharge(atom/target_atom)
	if(revving_charge || charging || monk_charge_cooldown > world.time)
		return
	for(var/i in 1 to 3)
		Charge(chargeat = target_atom, delay = (2 SECONDS/(2*i))) //1 second, 0.5 second, 0.25 second delays
	ResetCharge()

//charge code
/mob/living/simple_animal/hostile/rcorp_abno/hard/clouded_monk/proc/Charge(atom/chargeat = target, delay = 1 SECONDS, chargepast = 3)
	if(stat == DEAD)
		return
	if(monk_charge_cooldown > world.time || charging || revving_charge)
		return
	if(!chargeat)
		return
	face_atom(chargeat)
	var/turf/T = get_ranged_target_turf(chargeat, dir, chargepast)
	if(!T)
		return
	var/turf/chargeturf = get_turf(chargeat)
	if(chargeturf) //for some reason this can end up being null
		new /obj/effect/temp_visual/cult/sparks(chargeturf) //in case the big effect is behind a wall
	new /obj/effect/temp_visual/dragon_swoop/bubblegum(T)
	icon_state = "pretarage"
	revving_charge = TRUE
	charge_ready = FALSE
	walk(src, 0)
	if(!eaten) //different sfx before and after eating someone
		playsound(src, 'sound/abnormalities/clouded_monk/monk_cast.ogg', 100, 1)
	else
		playsound(src, 'sound/abnormalities/clouded_monk/monk_groggy.ogg', 150, 1)
	SLEEP_CHECK_DEATH(delay)
	if(!revving_charge) //to end charges prematurely
		return
	charging = TRUE
	revving_charge = FALSE
	var/movespeed = 0.8
	walk_towards(src, T, movespeed)
	SLEEP_CHECK_DEATH(get_dist(src, T) * movespeed)
	EndCharge()

/mob/living/simple_animal/hostile/rcorp_abno/hard/clouded_monk/proc/EndCharge(bump = FALSE)
	if(!charging)
		return
	charging = FALSE
	revving_charge = FALSE
	walk(src, 0) // cancel the movement
	icon_state = "pretamonk"

	if (!bump)
		var/turf/T = get_turf(src)
		for(var/turf/TF in range(2, T))//Smash AOE visual
			new /obj/effect/temp_visual/smash_effect(TF)
		for(var/mob/living/L in range(2, T))//damage applied to targets in range
			if(faction_check_mob(L))
				continue
			if(L.z != z)
				continue
			visible_message(span_boldwarning("[src] slams [L]!"))
			to_chat(L, span_userdanger("[src] slams you!"))
			var/turf/LT = get_turf(L)
			new /obj/effect/temp_visual/kinetic_blast(LT)
			L.deal_damage(slam_damage, RED_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			playsound(L, 'sound/creatures/lc13/lovetown/slam.ogg', 75, 1)

/mob/living/simple_animal/hostile/rcorp_abno/hard/clouded_monk/proc/ResetCharge()
	monk_charge_cooldown = world.time + monk_charge_cooldown_time
	charge_ready = FALSE //redundancy is good
	damage_taken = 0

/mob/living/simple_animal/hostile/rcorp_abno/hard/clouded_monk/Bump(atom/A)
	if(charging)
		if(isliving(A))
			var/mob/living/L = A
			if(!faction_check_mob(L))
				visible_message(span_boldwarning("[src] bites [L]!"), span_boldwarning("You take a bite out of [L]!"), ignored_mobs = L)
				to_chat(L, span_userdanger("[src] takes a bite out of you!"))
				do_attack_animation(L, ATTACK_EFFECT_BITE)
				playsound(src, 'sound/abnormalities/clouded_monk/monk_bite.ogg', 75, 1)
				shake_camera(L, 4, 3)
				shake_camera(src, 2, 3)
				if(ishuman(L))
					var/mob/living/carbon/human/H = A
					H.deal_damage(charge_damage, RED_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
					if(H.health < 0)
						H.gib()
						adjustBruteLoss(-heal_amount)
						if(!eaten)
							playsound(src, 'sound/abnormalities/clouded_monk/eat.ogg', 75, 1)
							eaten = TRUE
						else
							playsound(src, 'sound/abnormalities/clouded_monk/eat_groggy.ogg', 75, 1)
				else
					L.adjustRedLoss(charge_damage/10)
				EndCharge(TRUE)
				ResetCharge()
		else if(isvehicle(A))
			var/obj/vehicle/V = A
			V.take_damage(charge_damage*1.5, RED_DAMAGE)
			for(var/mob/living/occupant in V.occupants)
				to_chat(occupant, span_userdanger("Your [V.name] is bit by [src]!"))
			EndCharge(FALSE)
	return ..()
