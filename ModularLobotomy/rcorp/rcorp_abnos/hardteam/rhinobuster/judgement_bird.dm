//High pale mech piercing damage thats why its a rhinobuster, this one is special because it goes through walls
/mob/living/simple_animal/hostile/rcorp_abno/hard/judgement_bird
	name = "Judgement Bird"
	desc = "A bird that used to judge the living in the dark forest, carrying around an unbalanced scale. \
	You feel as if you were being judged even when you break line of sight with it. "
	pixel_x = -8
	base_pixel_x = -8
	del_on_death = FALSE
	ranged = TRUE
	minimum_distance = 6
	maxHealth = 2000
	health = 2000
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 2)
	see_in_dark = 10
	move_to_delay = 4
	original_abno = /mob/living/simple_animal/hostile/abnormality/judgement_bird

	var/judgement_cooldown = 10 SECONDS
	var/judgement_cooldown_base = 10 SECONDS
	var/judgement_damage = 65 //Raised because all of RCA has V armor so his wasnt enough
	var/judgement_range = 12
	var/judging = FALSE

	abno_additional_instructions = "<h1>You are Judgement Bird, A Rhino Piercer Role Abnormality.</h1><br>\
		<b>|Unjust Scale|: You are incapable of performing melee attacks, instead you may perform a pulse of PALE damage. \
		When attempting a ranged attack you will raise your scales instead, after a 2 second delay you will initiate your pulse \
		This pulse has a range of 12 tiles and will go through walls, any targets within its range will take 65 PALE damage. \
		This damage will always pierce through rhino suits and directly hit their pilots instead. \
		If they are killed by this you trigger Ceaseless Judgement. <br>\
		<br>\
		|Ceaseless Judgement|: If a human being is killed by your scales create a noose. \
		If a noose already exists on the location they died in, create another in a adjacent free tile. \
		This feathery nose will act as a obstacle blocking movement and projectiles however it is fragile and easily broken. \
		If a human being interacts with this noose they are given the option to hang themselves. \
		Hanging causes high oxygen damage which leaves one unconscious, but it does not do enough to kill. </b>"

/datum/action/innate/rca_abnormality_attack/judgement
	name = "Judgement"
	icon_icon = 'icons/obj/wizard.dmi'
	button_icon_state = "magicm"
	chosen_message = span_colossus("You will now damage all enemies around you.")
	chosen_attack_num = 1

/mob/living/simple_animal/hostile/rcorp_abno/hard/judgement_bird/Move()
	if(judging)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/judgement_bird/AttackingTarget(atom/attacked_target)
	if(!target)
		GiveTarget(attacked_target)
	return OpenFire()

/mob/living/simple_animal/hostile/rcorp_abno/hard/judgement_bird/OpenFire()
	if(client)
		switch(chosen_attack)
			if(1)
				judgement()
		return

	if(judgement_cooldown <= world.time)
		judgement()

/mob/living/simple_animal/hostile/rcorp_abno/hard/judgement_bird/proc/judgement()
	if(judgement_cooldown > world.time)
		return
	judgement_cooldown = world.time + judgement_cooldown_base
	judging = TRUE
	icon_state = "judgement_bird_attack"
	playsound(get_turf(src), 'sound/abnormalities/judgementbird/pre_ability.ogg', 50, 0, 2)
	SLEEP_CHECK_DEATH(2 SECONDS)
	playsound(get_turf(src), 'sound/abnormalities/judgementbird/ability.ogg', 75, 0, 7)
	for(var/mob/living/L in urange(judgement_range, src))
		if(faction_check_mob(L, FALSE))
			continue
		if(L.stat == DEAD)
			continue
		new /obj/effect/temp_visual/judgement(get_turf(L))
		L.deal_damage(judgement_damage, PALE_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))

		if(L.stat == DEAD)	//Gotta fucking check again in case it kills you. Real moment
			var/turf/T = get_turf(L)
			if(locate(/obj/structure/jbird_noose) in T)
				T = pick_n_take(T.reachableAdjacentTurfs())//if a noose is on this tile, it'll still create another one. You probably shouldn't be letting this many people die to begin with
				L.forceMove(T)
			var/obj/structure/jbird_noose/N = new(get_turf(L))
			N.buckle_mob(L)
			playsound(get_turf(L), 'sound/abnormalities/judgementbird/kill.ogg', 75, 0, 7)
			playsound(get_turf(L), 'sound/abnormalities/judgementbird/hang.ogg', 100, 0, 7)

	for(var/obj/vehicle/V in urange(judgement_range, src))
		for(var/mob/living/occupant in V.occupants)
			if(faction_check_mob(occupant, FALSE))
				continue
			if(occupant.stat == DEAD)
				continue
			new /obj/effect/temp_visual/judgement(get_turf(V))
			occupant.deal_damage(judgement_damage, PALE_DAMAGE, src, attack_type = (ATTACK_TYPE_SPECIAL))

	icon_state = icon_living
	judging = FALSE
	return

//Kill all burds
//Burd down
/mob/living/simple_animal/hostile/rcorp_abno/hard/judgement_bird/death(gibbed)
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)
	..()


