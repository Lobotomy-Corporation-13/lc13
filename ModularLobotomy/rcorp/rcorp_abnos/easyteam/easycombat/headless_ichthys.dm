/mob/living/simple_animal/hostile/rcorp_abno/easy/headless_ichthys
	name = "Headless Ichthys"
	desc = "A giant, headless sea creature."
	maxHealth = 1200
	health = 1200
	ranged = TRUE
	melee_damage_lower = 20
	melee_damage_upper = 35
	rapid_melee = 1
	melee_queue_distance = 2
	melee_damage_type = BLACK_DAMAGE
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1.2, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 2)
	del_on_death = FALSE
	original_abno = /mob/living/simple_animal/hostile/abnormality/headless_ichthys

	abno_additional_instructions = "<h1>You are Headless Ichthys, A Combat Role Abnormality.</h1><br>\
		<b>|Pressing Sac|: You can select between two attacks to perform when attacking at range, the first being Pressing Sac. \
		When Pressing Sac is used you will initiate a leap at your targets last location. \
		Upon initiating a leap you will briefly disappear before falling onto the targetted area doing BLACK damage in a 2 tile radius around yourself.<br>\
		<br>\
		<b>|Blood Cannon|: You can select between two attacks to perform when attacking at range, the second being Blood Cannon. \
		When Blood Cannon is used you will be immobilized and fire a 3 tile wide beam for a prolonged duration of which you are vulnerable. \
		Non-humans (of which you normally do not encounter) only take half damage from the beam, mechs still take full damage. <br> \
		<br>\
		|Fluid Sac|: If Blood Cannon is used while your health is at or below 30% you will enter Fluid Sac state. \
		Upon entering Fluid Sac state your damage will be increased and your cooldowns will be reduced.\
		Your Pressing Sac also has it's AoE range increased to 3 tiles. <br></b>"

	var/jump_cooldown = 0
	var/jump_cooldown_time = 8 SECONDS
	var/jump_damage = 50
	var/jump_sound = 'sound/abnormalities/ichthys/hammer2.ogg'
	var/jump_aoe = 2
	var/cannon_cooldown = 0
	var/cannon_cooldown_time = 30 SECONDS
	var/enraged = FALSE
// Blood beam vars ripped off of Queen of hatred
	var/beam_damage = 25
	var/beam_maximum_ticks = 20
	var/datum/beam/current_beam

	attack_action_types = list(
		/datum/action/innate/rca_abnormality_attack/IchthysJump,
		/datum/action/innate/rca_abnormality_attack/BloodCannon,
	)

/mob/living/simple_animal/hostile/rcorp_abno/easy/headless_ichthys/Initialize()
	. = ..()
	AddComponent(/datum/component/knockback, 2, FALSE, TRUE)

// Player-Controlled code
/datum/action/innate/rca_abnormality_attack/IchthysJump
	name = "Pressing Sac"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	button_icon_state = "_HE"
	chosen_message = span_colossus("You will now jump with your next attack.")
	chosen_attack_num = 1

/datum/action/innate/rca_abnormality_attack/BloodCannon
	name = "Blood Cannon"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/toolabnormalities.dmi'
	button_icon_state = "heart"
	chosen_message = span_colossus("You will now fire a blood cannon.")
	chosen_attack_num = 2

// Attacks
/mob/living/simple_animal/hostile/rcorp_abno/easy/headless_ichthys/proc/IchthysJump(mob/living/target)
	if(!isliving(target) && !ismecha(target) || !can_act)
		return
	var/dist = get_dist(target, src)
	if(dist > 1 && jump_cooldown < world.time)
		jump_cooldown = world.time + jump_cooldown_time
		can_act = FALSE
		icon_state = enraged ? "headless_ichthys_charging_enraged" : "headless_ichthys_charging"
		SLEEP_CHECK_DEATH(0.25 SECONDS)
		animate(src, alpha = 1,pixel_x = 0, pixel_z = 16, time = 0.1 SECONDS)
		src.pixel_z = 16
		playsound(src, 'sound/abnormalities/ichthys/jump.ogg', 50, FALSE, 4)
		var/turf/target_turf = get_turf(target)
		SLEEP_CHECK_DEATH(1 SECONDS)
		if(target_turf)
			forceMove(target_turf) //look out, someone is rushing you!
		playsound(src, jump_sound, 50, FALSE, 4)
		animate(src, alpha = 255,pixel_x = 0, pixel_z = -16, time = 0.1 SECONDS)
		src.pixel_z = 0
		SLEEP_CHECK_DEATH(0.1 SECONDS)
		icon_state = enraged ? "headless_ichthys_enraged" : "headless_ichthys"
		for(var/turf/T in view(jump_aoe, src))
			var/obj/effect/temp_visual/small_smoke/halfsecond/FX =  new(T)
			FX.color = "#b52e19"
			for(var/mob/living/L in T)
				if(faction_check_mob(L))
					continue
				L.deal_damage(jump_damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
				if(L.health < 0)
					L.gib()
			for(var/obj/vehicle/sealed/mecha/V in T)
				V.take_damage(jump_damage, BLACK_DAMAGE)
		SLEEP_CHECK_DEATH(0.5 SECONDS)
		can_act = TRUE

/mob/living/simple_animal/hostile/rcorp_abno/easy/headless_ichthys/proc/BloodCannon(target)
	if(cannon_cooldown > world.time)
		return FALSE
	if(!can_act)
		return FALSE
	if(!target)
		return FALSE
	cannon_cooldown = world.time + cannon_cooldown_time
	icon_state = enraged ? "headless_ichthys_charging_enraged" : "headless_ichthys_charging"
	var/turf/target_turf = get_turf(target)
	face_atom(target_turf)
	var/turf/my_turf = get_turf(src)
	can_act = FALSE
	playsound(src, "sound/abnormalities/ichthys/charge.ogg", 50, FALSE)
	var/turf/TT = get_ranged_target_turf_direct(my_turf, target_turf, 15)
	SLEEP_CHECK_DEATH(2 SECONDS) //Chargin' mah lazor
	icon_state = enraged ? "headless_ichthys_firing_enraged" : "headless_ichthys_firing"
	var/list/target_line = getline(my_turf, TT) //gets a line 15 tiles away
	for(var/turf/TF in target_line) //checks if that line has anything in the way, resets TT as the new beam end location
		if(TF.density)
			TT = TF
			break
	var/list/hit_line = getline(my_turf, TT) //old target_line is discarded with hit_line which respects walls
	for(var/turf/TF in hit_line) //spawns blood effects, separate loop because we only want to do it once
		if(TF.density)
			break
		var/obj/effect/decal/cleanable/blood/B  = new(TF)
		B.bloodiness = 100
	current_beam = my_turf.Beam(TT, "qoh")
	playsound(src, "sound/abnormalities/ichthys/blast.ogg", 50, FALSE)
	for(var/h = 1 to beam_maximum_ticks) //from this point on it's basically the same as queenie's but with balance adjustments
		var/list/already_hit = list()
		current_beam.visuals.color = COLOR_RED
		for(var/turf/TF in hit_line)
			if(TF.density)
				break
			var/list/turfs_to_check = range(1, TF)
			for(var/mob/living/L in turfs_to_check)
				if(L.status_flags & GODMODE)
					continue
				if(L == src) //stop hitting yourself
					continue
				if(L in already_hit)
					continue
				if(L.stat == DEAD)
					continue
				if(faction_check_mob(L))
					continue
				if(!(is_A_facing_B(src,L))) //so it doesn't hit people behind the mob
					continue
				already_hit += L
				var/truedamage = ishuman(L) ? beam_damage : beam_damage/2 //half damage dealt to nonhumans
				L.deal_damage(truedamage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL))
			for(var/obj/vehicle/sealed/mecha/V in turfs_to_check)
				if(V in already_hit)
					continue
				V.take_damage(beam_damage, BLACK_DAMAGE, attack_dir = get_dir(V, src))
				already_hit += V
		SLEEP_CHECK_DEATH(1.71)
	QDEL_NULL(current_beam)
	SLEEP_CHECK_DEATH(4 SECONDS) //Rest after laser beam
	if(health <= (maxHealth * 0.3))
		Enrage()
	icon_state = enraged ? "headless_ichthys_enraged" : "headless_ichthys"
	can_act = TRUE

// Breach Stuff
/mob/living/simple_animal/hostile/rcorp_abno/easy/headless_ichthys/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return
	if(jump_cooldown <= world.time && prob(10) && !client)
		IchthysJump(attacked_target)
		return
	if(cannon_cooldown <= world.time && prob(5) && !client)
		BloodCannon(attacked_target)
		return
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/headless_ichthys/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/headless_ichthys/OpenFire()
	if(!can_act)
		return FALSE
	if(client)
		switch(chosen_attack)
			if(1)
				IchthysJump(target)
			if(2)
				BloodCannon(target)
		return

	var/dist = get_dist(target, src)
	if(jump_cooldown <= world.time)
		var/chance_to_jump = 25
		if(dist > 3)
			chance_to_jump = 100
		if(prob(chance_to_jump))
			IchthysJump(target)
			return

	if(cannon_cooldown <= world.time && dist > 1)
		BloodCannon(target)
		return

/mob/living/simple_animal/hostile/rcorp_abno/easy/headless_ichthys/proc/Enrage() //gains 25% more damage dealt and shorter cooldowns
	if(enraged)
		return
	src.visible_message(span_userdanger("[src] looks angry!"))
	enraged = TRUE
	icon_state = "[icon_state]" + "_enraged"
	melee_damage_lower = 25
	melee_damage_upper = 44
	jump_cooldown_time = 6 SECONDS
	jump_damage = 62
	cannon_cooldown_time = 22.5 SECONDS
	beam_damage = 31
	attack_sound = 'sound/abnormalities/ichthys/hardslap.ogg'
	jump_sound = 'sound/abnormalities/ichthys/hammer3.ogg'
	jump_aoe = 3
	return

/mob/living/simple_animal/hostile/rcorp_abno/easy/headless_ichthys/face_atom() //VERY important; prevents spinning while firing bloodcannon
	if(!can_act)
		return
	..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/headless_ichthys/death(gibbed)
	playsound(src, 'sound/effects/limbus_death.ogg', 60, 1)
	animate(src, transform = matrix()*0.6,time = 0)
	icon_state = "headless_ichthys"
	icon = 'ModularLobotomy/_Lobotomyicons/abno_cores/he.dmi'
	QDEL_NULL(current_beam)
	update_icon_state()
	density = FALSE
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	..()
