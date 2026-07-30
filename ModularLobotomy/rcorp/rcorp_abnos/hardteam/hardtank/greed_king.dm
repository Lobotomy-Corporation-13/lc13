//Placed in tank because it tends to brutally maim 99% of Rcorp when they dont realise its there, TLDR too strong for support so its in tank
/mob/living/simple_animal/hostile/rcorp_abno/hard/greed_king
	name = "King of Greed"
	desc = "A shell of what she once was, the longer she charges the more devastating her bite."
	health = 3200
	ranged = TRUE
	damage_coeff = list(RED_DAMAGE = 0, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 1.5)
	vision_range = 14
	melee_damage_lower = 60	//Shouldn't really attack unless a player in controlling it, I guess.
	melee_damage_upper = 80
	damage_effect_scale = 1.2
	secret_chance = TRUE
	original_abno = /mob/living/simple_animal/hostile/abnormality/greed_king

	//Some Variables cannibalized from helper
	var/charge_check_time = 1 SECONDS
	var/obj/effect/proc_holder/ability/aimed/rca_dash/kog/ourdash

	//PLAYABLES ATTACKS
	attack_action_types = list(/datum/action/innate/rca_abnormality_attack/kog_dash,)

/mob/living/simple_animal/hostile/rcorp_abno/hard/greed_king/Initialize()
	.  = ..()
	ourdash = new()
	//I thought itd be funny
	if(secret_abnormality)
		name = "Magical Girl of Happiness"
		desc = "A real magical girl! Wait why is she angry"
		icon = 'ModularLobotomy/_Lobotomyicons/48x64.dmi'
		icon_state = "kog"
		pixel_x = -8
		base_pixel_x = -8
		pixel_y = 0
		base_pixel_y = 0
		attack_verb_continuous = "punches"
		attack_verb_simple = "punch"
	else
		icon = 'ModularLobotomy/_Lobotomyicons/64x48.dmi'
		//Center it on a hallway
		offsets_pixel_x = list("south" = -16, "north" = -16, "west" = -16, "east" = -16)
		offsets_pixel_y = list("south" = -8, "north" = -8, "west" = -8, "east" = -8)
		transform = matrix(1.5, MATRIX_SCALE)
	SetOccupiedTiles(1, 1, 1, 1)

/mob/living/simple_animal/hostile/rcorp_abno/hard/greed_king/Login()
	. = ..()
	to_chat(src, "<h1>You are King of Greed, A Tank Role Abnormality.</h1><br>\
		<b>|Gilded Cage|: Your size is 3 by 3 tiles wide, however you can still fit in 1 by 1 areas.<br>\
		<br>\
		|Endless Hunger|: When you click on a tile outside your melee range, you will start charging into the direction you clicked.<br>\
		Once you start charging into a direction you will constantly move in one direction.<br>\
		Initialy, your charge deal 200 RED damage, but for every tile you move you deal an extra 40 RED damage.<br>\
		Your charge ends after you move into a wall, or any dense object. (RHINOS/OTHER ABNORMALITIES WILL STOP YOUR CHARGE)</b>")

/datum/action/innate/rca_abnormality_attack/kog_dash
	name = "Ravenous Charge"
	button_icon_state = "kog_charge"
	chosen_message = span_colossus("You will now dash in that direction.")
	chosen_attack_num = 1

/mob/living/simple_animal/hostile/rcorp_abno/hard/greed_king/Life()
	. = ..()
	if(!.) // Dead
		return FALSE
	if(!(!can_act || client))
		charge_check()

/mob/living/simple_animal/hostile/rcorp_abno/hard/greed_king/AttackingTarget()
	if(!can_act)
		return
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/greed_king/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/greed_king/proc/charge_check()
	if(!can_act)
		return
	var/list/possible_targets = list()
	for(var/mob/living/carbon/human/H in view(20, src))
		possible_targets += H
	if(LAZYLEN(possible_targets))
		FindTarget(list(pick(possible_targets)), TRUE) // The list(pick()) here makes it equally likely for anyone to be targeted. If you removed it, it'd be based on individual threat level
		if(target)
			ourdash.Perform(target, src)
			return
	return

/obj/effect/proc_holder/ability/aimed/rca_dash/kog
	name = "king of greed dash"
	dash_speed =  2
	dash_damage = 200
	dash_range = 100000
	windup_delay = 2 SECONDS
	cooldown_time = 1 SECONDS
	cardinal_only = TRUE
	env_breaking = TRUE
	var/initial_damage = 200
	var/growing_charge_damage = 80
	var/nihil_present = FALSE
	var/finish_pause = 7 SECONDS

/obj/effect/proc_holder/ability/aimed/rca_dash/kog/Finalize(target, mob/living/user, list/path_list)
	dash_damage = initial_damage
	return ..()

/obj/effect/proc_holder/ability/aimed/rca_dash/kog/TurfEffects(turf/T, mob/living/ourthing)
	var/turf_flicks = FALSE
	for(var/turf/U in GetRange(T, 1))
		if(!U)
			break
		if(isopenturf(U) && !HasIdentList(U))
			FlickOnAtom(U,'icons/effects/effects.dmi',"smoke",5)
		var/list/new_hits = HurtInTurf(ourthing, U, list(), 0, RED_DAMAGE, hurt_mechs = TRUE, flags = (DAMAGE_FORCED | DAMAGE_UNTRACKABLE))
		var/flicks = FALSE
		for(var/obj/vehicle/V in new_hits)
			if(nihil_present)
				break
			turf_flicks = TRUE
			V.take_damage(80, RED_DAMAGE)
			V.visible_message(span_boldwarning("[ourthing] crunches [V]!"))

		for(var/mob/living/L in new_hits)
			turf_flicks = TRUE
			if(!nihil_present)
				L.visible_message(span_boldwarning("[ourthing] crunches [L]!"), span_userdanger("[ourthing] rends you with its teeth!"))
				if(!flicks)
					playsound(L, 'sound/abnormalities/kog/GreedHit1.ogg', 75, 1)
					FlickOnAtom(U,'icons/obj/projectiles.dmi',"kinetic_blast",4)
					flicks = TRUE
				if(ishuman(L))
					L.deal_damage(dash_damage, RED_DAMAGE, ourthing, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
				else
					L.adjustRedLoss(80)
				if(L.stat >= HARD_CRIT)
					L.gib(TRUE,TRUE,TRUE)
				continue

			if(!ishuman(L))
				L.visible_message(span_boldwarning("[ourthing] smashes [L]!"), span_userdanger("[ourthing] smashes you with her massive fist!"))
				if(!flicks)
					playsound(L, 'sound/abnormalities/kog/GreedHit1.ogg', 75, 1)
					FlickOnAtom(U,'icons/obj/projectiles.dmi',"kinetic_blast", 4)
					flicks = TRUE
				L.adjustRedLoss(80)
				if(L.stat >= HARD_CRIT)
					L.gib(TRUE,TRUE,TRUE)
					continue


	if(turf_flicks)
		playsound(T, 'sound/abnormalities/kog/GreedHit1.ogg', 20, 1)
		playsound(T, 'sound/abnormalities/kog/GreedHit2.ogg', 50, 1)

	playsound(ourthing,'sound/effects/bamf.ogg', 70, TRUE, 20)
	dash_damage = dash_damage + growing_charge_damage
	return ..()

/obj/effect/proc_holder/ability/aimed/rca_dash/kog/EndCharge(mob/living/user)
	do_after(user, finish_pause, timed_action_flags = IGNORE_USER_LOC_CHANGE, target = user)
	return ..()

/obj/effect/proc_holder/ability/aimed/rca_dash/kog/AbnoInteraction(mob/living/user)
	if(!istype(user, /mob/living/simple_animal/hostile/abnormality/greed_king))
		return
	var/mob/living/simple_animal/hostile/abnormality/greed_king/abno = user
	ToggleAct(abno,TRUE)
	abno.endCharge()

/mob/living/simple_animal/hostile/rcorp_abno/hard/greed_king/OpenFire() // This exists so players can manually charge during playable abnormalities.
	if(!can_act)
		return
	switch(chosen_attack)
		if(1)
			ourdash.Perform(target, src)
	return


