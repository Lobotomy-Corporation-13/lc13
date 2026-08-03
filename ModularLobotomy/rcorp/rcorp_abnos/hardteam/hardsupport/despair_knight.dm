//Thrown into support due to relying entirely on projectiles while highly vulnerable to a melee rush
/mob/living/simple_animal/hostile/rcorp_abno/hard/despair_knight
	name = "Knight of Despair"
	desc = "A tall humanoid abnormality in a blue dress. \
	Half of her head is black with sharp horn segments protruding out of it. \
	Her swords always pierce true but she seems vulnerable in melee."
	ranged = TRUE
	ranged_cooldown_time = 3 SECONDS
	minimum_distance = 2
	maxHealth = 2000
	health = 2000
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 1.0, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 0.5)
	del_on_death = FALSE
	move_to_delay = 4
	original_abno = /mob/living/simple_animal/hostile/abnormality/despair_knight

	var/special_atk_combo = 0

	abno_additional_instructions = "<h1>You are Thunderbird, A Support Role Abnormality.</h1><br>\
		<b>|A Broken Heart|: You are unable to melee and instead may only perform ranged attacks. <br>\
		<br>\
		|Sword Sharpened With Tears|: When performing a ranged attack you will summon 4 swords behind you. \
		Afterwards these swords will fly at the target, each hitting for 40 PALE.\
		The cooldown for this ranged attack is 3 seconds. <br>\
		<br>\
		|Blessing of Despair|: If no player is in control of Knight of Despair they will gain a new moveset only available to the AI. </b>"

/mob/living/simple_animal/hostile/rcorp_abno/hard/despair_knight/Initialize()
	. = ..()
	icon_living = "despair_breach"
	icon_state = icon_living

/mob/living/simple_animal/hostile/rcorp_abno/hard/despair_knight/AttackingTarget(atom/attacked_target)
	if(!can_act && !client)
		return
	if(!target)
		GiveTarget(attacked_target)
	if(!client && get_dist(get_turf(src), get_turf(attacked_target)) == 1 && attack_cooldown <= world.time && target) //AI Buff
		attack_cooldown = attack_cooldown + 5
		return prob(50) ?  Slash() : HopelessRetort()
	return OpenFire()

/mob/living/simple_animal/hostile/rcorp_abno/hard/despair_knight/OpenFire()
	if(!can_act)
		return FALSE
	if(!client && get_dist(get_turf(src), get_turf(target)) == 1 && attack_cooldown <= world.time && target)
		attack_cooldown = attack_cooldown + 5
		return prob(50) ?  Slash() : HopelessRetort()
	special_atk_combo += 1
	ranged_cooldown = world.time + ranged_cooldown_time
	//Sorry player no funny attacks for you.
	if(special_atk_combo >= 7 && !client)
		return RapidFire()
	var/tries = 8
	for(var/i = 1 to 4)
		if(tries < 1)
			break
		var/turf/T = get_step(get_turf(src), pick(1,2,4,5,6,8,9,10))
		if(T.density)
			i -= 1
			tries--
			continue
		DeferProjectile(/obj/projectile/rca_despair_rapier, target, T, 3)
	SLEEP_CHECK_DEATH(3)
	playsound(get_turf(src), 'sound/abnormalities/despairknight/attack.ogg', 50, 0, 4)
	return

/mob/living/simple_animal/hostile/rcorp_abno/hard/despair_knight/death(gibbed)
	density = FALSE
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/despair_knight/Move()
	if(!can_act)
		return FALSE
	return ..()

/*--------------\
|Special Attacks|
\--------------*/
/mob/living/simple_animal/hostile/rcorp_abno/hard/despair_knight/proc/RapidFire()
	if(!can_act)
		return FALSE
	can_act = FALSE
	var/tries = 10
	for(var/round = 1 to 12)
		if(!target)
			break
		if(tries < 1)
			break
		var/turf/T = get_step(get_turf(src), pick(1,4,5,6,8,9,10))
		if(T.density)
			round -= 1
			tries--
			continue
		if(!do_after(src, 2, target = src))
			break
		DeferProjectile(/obj/projectile/rca_despair_rapier, target, T, 3)
		playsound(get_turf(src), 'sound/abnormalities/despairknight/attack.ogg', 25, 0, 4)
	SLEEP_CHECK_DEATH(2)
	can_act = TRUE
	special_atk_combo = 0

//This proc should make a wall of swords that shoot towards who KoD is facing.
/*
* Originally this was going to use locate to find the cordnates of
* diagonal turfs and then cycle downwards or across with get_step
* but that seemed too convoluted in comparison to range(). -IP
*/
/mob/living/simple_animal/hostile/rcorp_abno/hard/despair_knight/proc/HopelessRetort()
	can_act = FALSE
	var/our_projectile_path = /obj/projectile/rca_despair_rapier
	var/dir_to_target = get_cardinal_dir(get_turf(src), get_turf(target))

	var/list/origin_turfs = list()
	//Give me all the  turfs that are 2 tiles away
	//Default is EAST
	var/invert = -1
	//Ill figure out a way to write this shorter someday
	if(dir_to_target == WEST || dir_to_target == SOUTH)
		invert = 1
	var/positionx = x+(2*invert)
	var/positiony = 0
	if(dir_to_target == NORTH || dir_to_target == SOUTH)
		positionx = 0
		positiony = y+(2*invert)

	for(var/turf/T in orange(get_turf(src),2))
		if(!isopenturf(T))
			continue
		if(positionx && positionx != T.x)
			continue
		if(positiony && positiony != T.y)
			continue
		if(z != T.z)
			//Just in case
			continue
		origin_turfs += T

	if(!length(origin_turfs))
		can_act = TRUE
		return

	var/turf_dir
	var/delay = 3
	for(var/turf/bullet_turfs in origin_turfs)
		if(!turf_dir)
			turf_dir = dir_to_target
		DeferProjectile(our_projectile_path, get_step(bullet_turfs, turf_dir), bullet_turfs, delay)
		delay++
	SLEEP_CHECK_DEATH(5)
	can_act = TRUE

/mob/living/simple_animal/hostile/rcorp_abno/hard/despair_knight/proc/Slash()
	if(!target)
		stack_trace("KoD Slash called without target.")
		return
	can_act = FALSE
	var/dir_to_target = get_cardinal_dir(get_turf(src), get_turf(target))
	var/turf/source_turf = get_step(get_turf(src), dir_to_target)
	var/turf/area_of_effect = list()
	var/turf/middle_line = list()
	var/upline = NORTH
	var/downline = SOUTH
	var/smash_length = 2
	var/smash_width = 1
	playsound(get_turf(src), 'sound/weapons/bladeslice.ogg', 50, 0, 5)
	middle_line = getline(source_turf, get_ranged_target_turf(source_turf, dir_to_target, smash_length))
	if(dir_to_target == NORTH || dir_to_target == SOUTH)
		upline = EAST
		downline = WEST
	for(var/turf/T in middle_line)
		if(T.density)
			break
		for(var/turf/Y in getline(T, get_ranged_target_turf(T, upline, smash_width)))
			if (Y.density)
				break
			if (Y in area_of_effect)
				continue
			area_of_effect += Y
		for(var/turf/U in getline(T, get_ranged_target_turf(T, downline, smash_width)))
			if (U.density)
				break
			if (U in area_of_effect)
				continue
			area_of_effect += U
	if(!dir_to_target)
		for(var/turf/TT in view(1, src))
			if (TT.density)
				break
			if (TT in area_of_effect)
				continue
			area_of_effect |= TT
	if (!LAZYLEN(area_of_effect))
		return
	can_act = FALSE
	dir = dir_to_target
	for(var/turf/T in area_of_effect)
		new /obj/effect/temp_visual/revenant(T)
	SLEEP_CHECK_DEATH(1 SECONDS)
	for(var/turf/T in area_of_effect)
		new /obj/effect/temp_visual/smash_effect(T)
		for(var/mob/living/L in HurtInTurf(T, list(), 20, WHITE_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)))
			playsound(get_turf(src), 'sound/magic/teleport_app.ogg', 30, 1)

	SLEEP_CHECK_DEATH(0.5 SECONDS)
	can_act = TRUE

/obj/projectile/rca_despair_rapier
	name = "enchanted rapier"
	desc = "A magic rapier, enchanted by the sheer despair and suffering the knight has been through."
	icon_state = "despair"
	damage_type = PALE_DAMAGE
	damage = 40
	alpha = 0
	spread = 20

/obj/projectile/rca_despair_rapier/Initialize()
	. = ..()
	hitsound = "sound/weapons/ego/rapier[pick(1,2)].ogg"
	animate(src, alpha = 255, time = 3)

/obj/projectile/rca_despair_rapier/process_hit(turf/T, atom/target, atom/bumped, hit_something = FALSE)
	if(!ishuman(target))
		return ..()
	var/mob/living/carbon/human/H = target
	var/old_stat = H.stat
	. = ..()
	if(.) // Hit passed and damage applied
		if((old_stat < DEAD) && (H.stat >= DEAD))
			H.add_overlay(icon('ModularLobotomy/_Lobotomyicons/tegu_effects.dmi', "despair_kill"))
