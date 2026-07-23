/mob/living/simple_animal/hostile/rcorp_abno/easy/ppodae
	name = "Ppodae"
	desc = "The Goodest Boy in the World"
	maxHealth = 550 //fast but low hp abno
	health = 550
	move_to_delay = 1
	damage_coeff = list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1, PALE_DAMAGE = 2)
	vision_range = 14
	original_abno = /mob/living/simple_animal/hostile/abnormality/ppodae

	attack_action_types = list(/datum/action/cooldown/rca_ppodae_transform)

	var/smash_damage_low = 32
	var/smash_damage_high = 40
	var/smash_length = 2
	var/smash_width = 1
	var/buff_form = FALSE
	//Buff Form stuff
	var/buff_resist_red = 0.5
	var/buff_resist_white = 0.5
	var/buff_resist_black = 0.5
	var/buff_resist_pale = 0.5
	var/buff_speed = 2
	var/can_slam = FALSE
	//Cute Form stuff
	var/cute_resist_red = 1.5
	var/cute_resist_white = 0.8
	var/cute_resist_black = 1
	var/cute_resist_pale = 2
	var/cute_speed = 1
	//Other Stuff
	var/limb_heal = 0.02

	abno_additional_instructions = "<h1>You are Ppodae, A Support Role Abnormality.</h1><br>\
		<b>|How adorable!|: You are able to switch between a 'Cute' and 'Buff' form. \
		Switching between forms has a 10 second cooldown and each time you switch forms you create smoke which lasts for 9 seconds.<br>\
		<br>\
		|Cute!|: While you are in your 'Cute' form, you have a MASSIVE speed boost and if you try to melee attack mechs or living mobs, you will crawl under them.<br>\
		<br>\
		|Strong!|: While you are in your 'Buff' form, you take 50% less damage from all attacks and you perfrom a 3x3 AoE attack when you try to melee attack, (Really good at breaking down Structures)<br>\
		<br>\
		|He's just Playing|: When you melee attack a unconscious or dead human body, you are able to tear off a limb, which heals you 2% of your max HP. (You can do this 4 time per body)</b>"

/datum/action/cooldown/rca_ppodae_transform
	name = "Transform!"
	icon_icon = 'icons/mob/actions/actions_abnormality.dmi'
	button_icon_state = "ppodae_transform"
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE
	cooldown_time = 12.5 SECONDS

/datum/action/cooldown/rca_ppodae_transform/Trigger()
	if(!..())
		return FALSE
	if(!istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/easy/ppodae))
		return FALSE
	var/mob/living/simple_animal/hostile/rcorp_abno/easy/ppodae/ppodae = owner
	StartCooldown()
	if(ppodae.buff_form)
		ppodae.buff_form = FALSE
		ppodae.UpdateForm()
	else
		ppodae.buff_form = TRUE
		ppodae.UpdateForm()
	return TRUE

/mob/living/simple_animal/hostile/rcorp_abno/easy/ppodae/proc/UpdateForm()
	if(buff_form)
		ChangeResistances(list(RED_DAMAGE = buff_resist_red, WHITE_DAMAGE = buff_resist_white, BLACK_DAMAGE = buff_resist_black, PALE_DAMAGE = buff_resist_pale))
		move_to_delay = buff_speed
		icon_state = "ppodae_active"
		can_slam = TRUE
	else
		ChangeResistances(list(RED_DAMAGE = cute_resist_red, WHITE_DAMAGE = cute_resist_white, BLACK_DAMAGE = cute_resist_black, PALE_DAMAGE = cute_resist_pale))
		move_to_delay = cute_speed
		icon_state = "ppodae"
		can_slam = FALSE
	var/datum/effect_system/smoke_spread/smoke = new
	smoke.set_up(1, src)
	smoke.start()
	qdel(smoke)
	UpdateSpeed()
	playsound(get_turf(src), 'sound/abnormalities/scaredycat/cateleport.ogg', 50, 0, 5)

/mob/living/simple_animal/hostile/rcorp_abno/easy/ppodae/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/ppodae/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return FALSE
	var/mob/living/carbon/L = attacked_target
	if(iscarbon(attacked_target) && (L.stat == DEAD))
		LimbSteal(L)
		return

			// Taken from eldritch_demons.dm
	if(can_slam)
		return Smash(attacked_target)
	else if(isvehicle(attacked_target))
		var/obj/vehicle/V = attacked_target
		var/turf/target_turf = get_turf(V)
		forceMove(target_turf)
		manual_emote("crawls under [V]!")
	else if (istype(attacked_target, /mob/living))
		if (attacked_target != src)
			var/turf/target_turf = get_turf(attacked_target)
			forceMove(target_turf)
			manual_emote("crawls under [attacked_target]!")
	else if(can_slam)
		return Smash(attacked_target)

/mob/living/simple_animal/hostile/rcorp_abno/easy/ppodae/proc/LimbSteal(mob/living/carbon/L)
	if(HAS_TRAIT(L, TRAIT_NODISMEMBER))
		return
	var/list/parts = list()
	for(var/X in L.bodyparts)
		var/obj/item/bodypart/bp = X
		if(bp.body_part != HEAD && bp.body_part != CHEST)
			if(bp.dismemberable)
				parts += bp
	if(length(parts))
		var/obj/item/bodypart/bp = pick(parts)
		bp.dismember()
		adjustHealth(-(maxHealth * limb_heal))
		QDEL_NULL(src)

//AoE attack taken from woodsman
/mob/living/simple_animal/hostile/rcorp_abno/easy/ppodae/proc/Smash(target)
	if (get_dist(src, target) > 1)
		return
	var/dir_to_target = get_cardinal_dir(get_turf(src), get_turf(target))
	var/turf/source_turf = get_turf(src)
	var/turf/area_of_effect = list()
	var/turf/middle_line = list()
	switch(dir_to_target)
		if(EAST)
			middle_line = getline(source_turf, get_ranged_target_turf(source_turf, EAST, smash_length))
			for(var/turf/T in middle_line)
				if(T.density)
					break
				for(var/turf/Y in getline(T, get_ranged_target_turf(T, NORTH, smash_width)))
					if (Y.density)
						break
					if (Y in area_of_effect)
						continue
					area_of_effect += Y
				for(var/turf/U in getline(T, get_ranged_target_turf(T, SOUTH, smash_width)))
					if (U.density)
						break
					if (U in area_of_effect)
						continue
					area_of_effect += U
		if(WEST)
			middle_line = getline(source_turf, get_ranged_target_turf(source_turf, WEST, smash_length))
			for(var/turf/T in middle_line)
				if(T.density)
					break
				for(var/turf/Y in getline(T, get_ranged_target_turf(T, NORTH, smash_width)))
					if (Y.density)
						break
					if (Y in area_of_effect)
						continue
					area_of_effect += Y
				for(var/turf/U in getline(T, get_ranged_target_turf(T, SOUTH, smash_width)))
					if (U.density)
						break
					if (U in area_of_effect)
						continue
					area_of_effect += U
		if(SOUTH)
			middle_line = getline(source_turf, get_ranged_target_turf(source_turf, SOUTH, smash_length))
			for(var/turf/T in middle_line)
				if(T.density)
					break
				for(var/turf/Y in getline(T, get_ranged_target_turf(T, EAST, smash_width)))
					if (Y.density)
						break
					if (Y in area_of_effect)
						continue
					area_of_effect += Y
				for(var/turf/U in getline(T, get_ranged_target_turf(T, WEST, smash_width)))
					if (U.density)
						break
					if (U in area_of_effect)
						continue
					area_of_effect += U
		if(NORTH)
			middle_line = getline(source_turf, get_ranged_target_turf(source_turf, NORTH, smash_length))
			for(var/turf/T in middle_line)
				if(T.density)
					break
				for(var/turf/Y in getline(T, get_ranged_target_turf(T, EAST, smash_width)))
					if (Y.density)
						break
					if (Y in area_of_effect)
						continue
					area_of_effect += Y
				for(var/turf/U in getline(T, get_ranged_target_turf(T, WEST, smash_width)))
					if (U.density)
						break
					if (U in area_of_effect)
						continue
					area_of_effect += U
		else
			for(var/turf/T in view(1, src))
				if (T.density)
					break
				if (T in area_of_effect)
					continue
				area_of_effect |= T
	if (!LAZYLEN(area_of_effect))
		return
	can_act = FALSE
	dir = dir_to_target
	var/smash_damage = rand(smash_damage_low, smash_damage_high)
	for(var/turf/T in area_of_effect)
		new /obj/effect/temp_visual/smash_effect(T)
		HurtInTurf(T, list(), smash_damage, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, hurt_structure = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	playsound(get_turf(src), 'sound/abnormalities/ppodae/bark.wav', 100, 0, 5)
	playsound(get_turf(src), 'sound/abnormalities/ppodae/attack.wav', 50, 0, 5)
	SLEEP_CHECK_DEATH(0.5 SECONDS)
	can_act = TRUE


