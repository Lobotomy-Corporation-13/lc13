#define SKILL_MAP_COMBAT_CHECK (SSmaptype.maptype in SSmaptype.combatmaps) ? TRUE : FALSE
/*
* Its becoming difficult to handle several abnormalities who dash
* and may get missed by optimization code. So im turning them
* into spells.
*/
/obj/effect/proc_holder/ability/aimed/dash
	name = "default dash"
	desc = "An ability that allows its user to dash six tiles forward in any direction."
	action_icon_state = "helper_dash0"
	base_icon_state = "helper_dash"
	cooldown_time = 1 SECONDS

	//Amount of time in deciseconds to move from one tile to another.
	var/dash_speed = 1
	//Used inconsistently
	var/dash_damage = 0
	//How many tiles this dash can move if not stopped.
	var/dash_range = 6
	//Delay before the ability actually activates.
	var/windup_delay = 0
	//For attacks that pass through walls
	var/dash_ignore_walls = FALSE
	//If this dash can smash through windows
	var/env_breaking = FALSE
	//For stopping the dash NOW
	var/emergency_stop = FALSE
	//If we only do cardinals
	var/cardinal_only = FALSE

/obj/effect/proc_holder/ability/aimed/dash/can_cast(mob/user = usr)
	if(isabnormalitymob(user))
		var/mob/living/simple_animal/hostile/abnormality/abno = usr
		if(abno.IsContained())
			return FALSE
	return ..()

/obj/effect/proc_holder/ability/aimed/dash/Perform(target, mob/living/user)
	. = ..()
	//reset the emergency stop so we are not forever stuck.
	emergency_stop = FALSE
	if(!user || !target)
		return
	ToggleAct(user,FALSE)
	var/overall_dir = get_dir(get_turf(user), get_turf(target))
	user.setDir(overall_dir)

	var/list/ourpath = Telegraph(target, user)

	if(length(ourpath))
		Finalize(target, user, ourpath)
		return
	EndCharge(user)

//Returns a list of the turfs we are dashing. See spear apostle dash for actual telegraphing.
/obj/effect/proc_holder/ability/aimed/dash/proc/Telegraph(atom/target, mob/living/user)
	. = list()
	if(!target || !user)
		stack_trace("Dash Skill Telegraph was called without a target or user.")
		return list()
	var/dir_to_target
	if(cardinal_only && !QDELETED(target))
		dir_to_target = get_cardinal_dir(get_turf(user), get_turf(target))
	else
		dir_to_target = get_dir(user, target)

	var/turf/T = get_turf(user)
	for(var/i = 1 to dash_range)
		T = get_step(T, dir_to_target)
		if(T.density)
			if(i < 4) // Mob attempted to dash into a wall too close, stop it
				return list()
			break
		. += T

// Truely preforms the dash.
/obj/effect/proc_holder/ability/aimed/dash/proc/Finalize(target, mob/living/user, list/path_list)
	if(windup_delay)
		if(!do_after(user, windup_delay, target = user))
			EndCharge(user)
			return

	if(!path_list)
		var/dir_to_target = get_dir(user, target)
		if(!dir_to_target)
			EndCharge(user)
			return
		var/somehowloc = get_ranged_target_turf(user, dir_to_target, dash_range)
		path_list = get_ranged_target_turf_direct(user, somehowloc, dash_range)

	addtimer(CALLBACK(src, PROC_REF(DashMove), user, get_turf(user), 1, path_list), dash_speed)

//Ends the charge offically
/obj/effect/proc_holder/ability/aimed/dash/proc/DashMove(mob/living/user, turf/last_turf, times_ran = 1, list/dash_list)
	var/list/mobs_to_hit = list()
	if(!islist(dash_list))
		stack_trace("Dash Skill path_list was not a list.")
		return EndCharge(user)

	var/turf/T = popleft(dash_list)

	if(times_ran >= dash_range)
		return EndCharge(user)
	if(!T || !user)
		return EndCharge(user)
	if(last_turf && last_turf != get_turf(user) && !dash_ignore_walls)
		//Really cool interception.
		return EndCharge(user)
	if(emergency_stop || user.stat == DEAD)
		return EndCharge(user)
	if(!PassCriteria(T))
		return EndCharge(user)
	user.forceMove(T)
	last_turf = T
	// Damage
	mobs_to_hit = TurfEffects(T, user, mobs_to_hit)

	//Unsure if sleep would cause issues with this thing so i resorted to the age old method -IP
	addtimer(CALLBACK(src, PROC_REF(DashMove), user, last_turf, (times_ran + 1), dash_list), dash_speed)

//Ends the charge offically
/obj/effect/proc_holder/ability/aimed/dash/proc/EndCharge(mob/living/user)
	if(user)
		AbnoInteraction(user)
		ToggleAct(user,TRUE)
	LAZYCLEARLIST(hit_identifiers)

/*
* If this returns false then the attack stops.
* Scans each turf during Telegraph.
*/
/obj/effect/proc_holder/ability/aimed/dash/proc/PassCriteria(turf/T)
	if(dash_ignore_walls)
		return TRUE
	if(T.density)
		return FALSE
	for(var/obj/structure/window/W in T.contents)
		if(W.density)
			if(!env_breaking)
				return FALSE
			W.obj_destruction(name)
	for(var/obj/machinery/door/MD in T.contents)
		if(!MD.CanAStarPass(null))
			return FALSE
		if(MD.density)
			INVOKE_ASYNC(MD, TYPE_PROC_REF(/obj/machinery/door, open), 2)
	for(var/mob/living/simple_animal/hostile/abnormality/D in T.contents)	//This caused issues earlier
		if(D.density)
			return FALSE
	return TRUE

/*
* Just does damage to people on tiles we havent hit.
*/
/obj/effect/proc_holder/ability/aimed/dash/proc/TurfEffects(turf/T, mob/living/ourthing)
	return

/*
* Gets only the turfs around us. No reason
* to check for all of the items if we are not looking for them
*/
/obj/effect/proc_holder/ability/aimed/dash/proc/GetRange(A, size = 1)
	if(!A)
		return
	var/turf/T = get_turf(A)

	if(size < 1)
		return list(T)
	var/turfz = T.z
	//Lower Left
	var/offsetx1 = T.x -size
	var/offsety1 = T.y -size
	//Upper Right
	var/offsetx2 = T.x +size
	var/offsety2 = T.y +size
	var/list/turfs_to_hit = block(offsetx1,offsety1,turfz,offsetx2,offsety2,turfz)
	turfs_to_hit -= T
	return turfs_to_hit

/*
* Requires a mob/living to call HurtInTurf
* Uses HasIdentList to sort out the things we have already hit.
*/
/obj/effect/proc_holder/ability/aimed/dash/proc/HurtInTurf(mob/living/ourmob, turf/target, list/hit_list = list(), damage = 0, damage_type = RED_DAMAGE, def_zone = null, check_faction = FALSE, exact_faction_match = FALSE, hurt_mechs = FALSE, mech_damage = 0, hurt_hidden = FALSE, hurt_structure = FALSE, break_not_destroy = FALSE, attack_direction = null, flags = null, attack_type = null)
	var/list/do_not_hitlist = list()
	for(var/obj/thing in target)
		if(HasIdentList(thing))
			do_not_hitlist += thing
	for(var/mob/living/L in target)
		if(HasIdentList(L))
			do_not_hitlist += L
	return ourmob.HurtInTurf(target, hit_list, damage, damage_type, def_zone, check_faction, exact_faction_match, hurt_mechs, mech_damage, hurt_hidden, hurt_structure, break_not_destroy, attack_direction, flags, attack_type) - do_not_hitlist

/*----------\
|Abnormality|
\----------*/
//Theroetically, humans could also use these abilities.
/obj/effect/proc_holder/ability/aimed/dash/spear_apostle
	name = "apostle spear dash"
	dash_speed =  0.5
	dash_damage = 300
	dash_range =  50
	windup_delay = 0
	cooldown_time = 10 SECONDS
	env_breaking = FALSE

/obj/effect/proc_holder/ability/aimed/dash/spear_apostle/Finalize(target, mob/living/user, list/path_list)
	for(var/turf/T in path_list)
		FlickOnAtom(T,'icons/effects/cult_effects.dmi',"bloodsparkles",5)
	playsound(get_turf(user), 'sound/abnormalities/whitenight/spear_charge.ogg', 75, 0, 5)
	if(!do_after(user, 2.2 SECONDS, target = user))
		EndCharge(user)
		return
	playsound(get_turf(user), 'sound/abnormalities/whitenight/spear_dash.ogg', 100, 0, 20)
	return ..()

/obj/effect/proc_holder/ability/aimed/dash/spear_apostle/TurfEffects(turf/T, mob/living/ourthing)
	for(var/turf/TF in GetRange(T, 1))
		if(!TF)
			break
		if(isclosedturf(TF))
			continue
		if(!HasIdentList(TF))
			FlickOnAtom(TF,'icons/effects/effects.dmi',"smoke",5)
		var/list/new_hits = HurtInTurf(ourthing, T, list(), dash_damage, BLACK_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, hurt_structure = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		var/flicks = FALSE
		for(var/mob/living/L in new_hits)
			visible_message(span_boldwarning("[ourthing] runs through [L]!"), span_nicegreen("You impaled heretic [L]!"))
			if(!flicks)
				FlickOnAtom(TF,'icons/effects/effects.dmi',"cleave",5)
				flicks  = TRUE
	return ..()


/obj/effect/proc_holder/ability/aimed/dash/big_wolf
	name = "big wolf dash"
	dash_speed =  0.5
	dash_damage = 50
	dash_range =  7
	windup_delay = 1 SECONDS
	cooldown_time = 30 SECONDS

/obj/effect/proc_holder/ability/aimed/dash/big_wolf/Finalize(target, mob/living/user, list/path_list)
	user.do_shaky_animation(2)
	return ..()

/obj/effect/proc_holder/ability/aimed/dash/big_wolf/TurfEffects(turf/T, mob/living/ourthing)
	playsound(T, 'sound/abnormalities/doomsdaycalendar/Lor_Slash_Generic.ogg', 20, 0, 4)
	var/list/hit_mob = list()
	for(var/turf/TF in GetRange(T, 1))
		if(!TF)
			break
		if(isclosedturf(TF))
			continue
		if(!HasIdentList(TF))
			FlickOnAtom(TF,'icons/effects/effects.dmi',"slice",4)
		hit_mob = HurtInTurf(ourthing, TF, hit_mob, dash_damage, RED_DAMAGE, null, TRUE, FALSE, TRUE, hurt_structure = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		if(!istype(ourthing,/mob/living/simple_animal/hostile/abnormality/big_wolf))
			continue
		for(var/mob/living/simple_animal/hostile/abnormality/red_hood/mercenary in hit_mob)
			mercenary.deal_damage(dash_damage * 2, RED_DAMAGE, ourthing, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)) //triple damge to red
	return ..()

/obj/effect/proc_holder/ability/aimed/dash/big_wolf/snowqueen
	name = "big wolf dash"
	dash_speed =  1
	dash_damage = 20
	windup_delay = 0
	cooldown_time = 3 SECONDS

/obj/effect/proc_holder/ability/aimed/dash/big_wolf/snowqueen/Finalize(target, mob/living/user, list/path_list)
	if(!do_after(user, 1 SECONDS, target = user))
		EndCharge(user)
		return
	if(istype(user, /mob/living/simple_animal/hostile/abnormality/snow_queen))
		var/mob/living/simple_animal/hostile/abnormality/snow_queen/abno = user
		abno.startCharge()
	return ..()

/obj/effect/proc_holder/ability/aimed/dash/big_wolf/snowqueen/AbnoInteraction(mob/living/user)
	if(!istype(user, /mob/living/simple_animal/hostile/abnormality/snow_queen))
		return
	var/mob/living/simple_animal/hostile/abnormality/snow_queen/abno = user
	ToggleAct(abno,TRUE)
	abno.endCharge()

/obj/effect/proc_holder/ability/aimed/dash/basilsoup
	name = "basilsoup dash"
	dash_speed =  2
	dash_damage = 50
	dash_range =  10
	cooldown_time = 8 SECONDS

/obj/effect/proc_holder/ability/aimed/dash/basilsoup/TurfEffects(turf/T, mob/living/ourthing)
	for(var/turf/U in GetRange(T, 1))
		if(!U)
			break
		if(isopenturf(U) && !HasIdentList(U))
			FlickOnAtom(U,'icons/effects/effects.dmi',"smoke")
		var/list/new_hits = HurtInTurf(ourthing, U, list(), 0, BLACK_DAMAGE, hurt_mechs = TRUE, flags = (DAMAGE_FORCED | DAMAGE_UNTRACKABLE))
		var/flicks = FALSE
		for(var/mob/living/L in new_hits)
			var/atom/throw_target = get_edge_target_turf(L, get_dir(L, get_step_away(L, get_turf(ourthing))))
			L.visible_message(span_boldwarning("[ourthing] slams into [L]!"), span_userdanger("[ourthing] rends you with its teeth and claws!"))
			playsound(L, 'sound/weapons/genhit2.ogg', 75, 1)
			if(!flicks)
				FlickOnAtom(U,'icons/obj/projectiles.dmi',"kinetic_blast",4)
				flicks = TRUE
			L.deal_damage(dash_damage, BLACK_DAMAGE, ourthing, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			L.throw_at(throw_target, 3, 2)
			for(var/obj/vehicle/V in new_hits)
				var/identifier = AddIdentifier(V)
				if(identifier in hit_identifiers)
					continue
				hit_identifiers += identifier
				V.take_damage(dash_damage, BLACK_DAMAGE, 'sound/abnormalities/mountain/bite.ogg')
				V.visible_message(span_boldwarning("[ourthing] crunches [V]!"))
				playsound(V, 'sound/weapons/genhit2.ogg', 75, 1)
			continue
	playsound(ourthing,'sound/effects/bamf.ogg', 40, TRUE, 20)
	return ..()


/obj/effect/proc_holder/ability/aimed/dash/brazen_bull
	name = "brazen dash"
	dash_speed =  2
	dash_damage = 40
	dash_range =  50
	windup_delay = 2 SECONDS
	cooldown_time = 8 SECONDS

/obj/effect/proc_holder/ability/aimed/dash/brazen_bull/TurfEffects(turf/T, mob/living/ourthing)
	for(var/turf/U in GetRange(T, 1))
		if(!U)
			break
		if(isopenturf(U) && !HasIdentList(U))
			FlickOnAtom(U,'icons/effects/effects.dmi',"smoke")
		var/list/new_hits = HurtInTurf(ourthing, U, list(), 0, RED_DAMAGE, hurt_mechs = TRUE)
		var/flicks = FALSE
		for(var/mob/living/L in new_hits)
			L.visible_message(span_boldwarning("[ourthing] rams [L]!"), span_userdanger("[ourthing] impales you with its horns!"))
			if(!flicks)
				playsound(L, 'sound/weapons/fast_slam.ogg', 75, 1)
				FlickOnAtom(U,'icons/obj/projectiles.dmi',"kinetic_blast",4)
				flicks = TRUE
			L.deal_damage(dash_damage, RED_DAMAGE, ourthing, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			if(L.stat >= HARD_CRIT)
				L.gib(TRUE,TRUE)
				continue
		for(var/obj/vehicle/V in new_hits)
			var/identifier = AddIdentifier(V)
			if(identifier in hit_identifiers)
				continue
			hit_identifiers += identifier
			V.take_damage(dash_damage / 4, RED_DAMAGE, 'sound/weapons/fast_slam.ogg')
			V.visible_message(span_boldwarning("[ourthing] rams [V]!"))
	playsound(ourthing,'sound/effects/bamf.ogg', 70, TRUE, 20)
	return ..()


/obj/effect/proc_holder/ability/aimed/dash/kog
	name = "king of greed dash"
	dash_speed =  2
	dash_damage = 800
	dash_range = 100000
	windup_delay = 2 SECONDS
	cooldown_time = 1 SECONDS
	cardinal_only = TRUE
	env_breaking = TRUE
	var/combat_map = FALSE
	var/charge_damage = 800
	var/growing_charge_damage = 0
	var/nihil_present = FALSE

/obj/effect/proc_holder/ability/aimed/dash/kog/Initialize()
	.  = ..()
	if(SKILL_MAP_COMBAT_CHECK)
		combat_map = TRUE
		dash_damage = 200
		growing_charge_damage = 80

/obj/effect/proc_holder/ability/aimed/dash/kog/Finalize(target, mob/living/user, list/path_list)
	charge_damage = dash_damage
	return ..()

/obj/effect/proc_holder/ability/aimed/dash/kog/TurfEffects(turf/T, mob/living/ourthing)
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
					L.deal_damage(charge_damage, RED_DAMAGE, ourthing, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
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
	if(combat_map)
		charge_damage = charge_damage + growing_charge_damage
	return ..()


/obj/effect/proc_holder/ability/aimed/dash/kog/AbnoInteraction(mob/living/user)
	if(!istype(user, /mob/living/simple_animal/hostile/abnormality/greed_king))
		return
	var/mob/living/simple_animal/hostile/abnormality/greed_king/abno = user
	ToggleAct(abno,TRUE)
	abno.endCharge()

/obj/effect/proc_holder/ability/aimed/dash/thunderbird
	name = "thunderbird dash"
	dash_speed =  1
	dash_damage = 100
	dash_range = 10
	windup_delay = 1.5 SECONDS
	cooldown_time = 4 SECONDS

/obj/effect/proc_holder/ability/aimed/dash/thunderbird/TurfEffects(turf/T, mob/living/ourthing)
	for(var/turf/U in GetRange(T, 1))
		if(!U)
			break
		if(isopenturf(U) && !HasIdentList(U))
			FlickOnAtom(U,'icons/effects/effects.dmi',"smash",5)
		var/list/new_hits = HurtInTurf(ourthing, U, list(), dash_damage, BLACK_DAMAGE, hurt_mechs = TRUE, flags = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		var/flicks = FALSE
		for(var/mob/living/L in new_hits)//damage applied to targets in range
			if(!ourthing.faction_check_mob(L))
				visible_message(span_boldwarning("[ourthing] runs through [L]!"))
				to_chat(L, span_userdanger("[ourthing] rushes past you, arcing electricity throughout the way!"))
				if(!flicks)
					playsound(U, 'sound/abnormalities/thunderbird/tbird_peck.ogg', 75, 1)
					FlickOnAtom(U,'icons/obj/projectiles.dmi',"kinetic_blast",4)
					flicks = TRUE
				if(ishuman(L))
					var/mob/living/carbon/human/H = L
					H.electrocute_act(1, ourthing, flags = SHOCK_NOSTUN)
		for(var/obj/vehicle/sealed/mecha/V in new_hits)
			visible_message(span_boldwarning("[ourthing] runs through [V]!"))
			to_chat(V.occupants, span_userdanger("[ourthing] rushes past you, arcing electricity throughout the way!"))
			if(!flicks)
				playsound(U, 'sound/abnormalities/thunderbird/tbird_peck.ogg', 75, 1)
				flicks = TRUE
	return ..()

/obj/effect/proc_holder/ability/aimed/dash/thunderbird/AbnoInteraction(mob/living/user)
	if(!istype(user, /mob/living/simple_animal/hostile/abnormality/thunder_bird))
		return
	var/mob/living/simple_animal/hostile/abnormality/thunder_bird/abno = user
	ToggleAct(abno,TRUE)
	abno.endCharge()

/obj/effect/proc_holder/ability/aimed/dash/wayward
	name = "wayward dash"
	dash_speed =  1
	dash_damage = 60
	dash_range = 6
	windup_delay = 2 SECONDS
	cooldown_time = 4 SECONDS
	env_breaking = TRUE

/obj/effect/proc_holder/ability/aimed/dash/wayward/TurfEffects(turf/T, mob/living/ourthing)
	playsound(T,"sound/abnormalities/thunderbird/tbird_peck.ogg", rand(50, 70), 1)
	for(var/turf/U in GetRange(T, 1))
		if(!U)
			break
		if(isopenturf(U) && !HasIdentList(U))
			FlickOnAtom(U,'icons/effects/effects.dmi',"smash",5)
		var/list/new_hits = HurtInTurf(ourthing, U, list(), dash_damage, RED_DAMAGE, hurt_mechs = TRUE, flags = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		var/flicks = FALSE
		for(var/mob/living/L in new_hits)//damage applied to targets in range
			if(!ourthing.faction_check_mob(L))
				L.visible_message(span_boldwarning("[ourthing] slices through [L]!"), span_userdanger("[ourthing] rushes past you, searing you with its blades!"))
				if(!flicks)
					playsound(U, 'sound/abnormalities/wayward_passenger/attack2.ogg', 75, 1)
					FlickOnAtom(U,'icons/obj/projectiles.dmi',"kinetic_blast",4)
					flicks = TRUE
		for(var/obj/vehicle/sealed/mecha/V in new_hits)
			V.visible_message(span_boldwarning("[ourthing] slices through [V]!"))
			to_chat(V.occupants, span_userdanger("[ourthing] rushes past you, searing your mech with its blades!"))
			playsound(U, 'sound/abnormalities/wayward_passenger/attack2.ogg', 75, 1)
			if(!flicks)
				FlickOnAtom(U,'icons/obj/projectiles.dmi',"kinetic_blast",4)
				flicks = TRUE
	return ..()

/obj/effect/proc_holder/ability/aimed/dash/wayward/AbnoInteraction(mob/living/user)
	if(!istype(user, /mob/living/simple_animal/hostile/abnormality/wayward))
		return
	var/mob/living/simple_animal/hostile/abnormality/wayward/abno = user
	ToggleAct(abno,TRUE)
	abno.endCharge()

/obj/effect/proc_holder/ability/aimed/dash/corroded
	name = "corroded dash"
	dash_speed =  0.5
	dash_damage = 80
	dash_range = 25
	windup_delay = 8
	cooldown_time = 4 SECONDS
	env_breaking = TRUE
	var/gibbing = TRUE
	var/heal_amount = 250

/obj/effect/proc_holder/ability/aimed/dash/corroded/TurfEffects(turf/T, mob/living/ourthing)
	var/turf/U = T
	if(!U)
		return
	if(isopenturf(U) && !HasIdentList(U))
		FlickOnAtom(U,'icons/effects/effects.dmi',"smash",5)
	var/list/new_hits = HurtInTurf(ourthing, U, list(), dash_damage, RED_DAMAGE, hurt_mechs = TRUE, flags = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	var/flicks = FALSE
	for(var/mob/living/L in new_hits)//damage applied to targets in range
		if(!ourthing.faction_check_mob(L))
			ourthing.visible_message(span_boldwarning("[ourthing] bites [L]!"))
			to_chat(L, span_userdanger("[ourthing] takes a bite out of you!"))
			if(!ishuman(L))
				continue
			var/mob/living/carbon/human/H = L
			if(H.health < 0 && gibbing)
				H.gib(FALSE,FALSE,TRUE)
				playsound(U, "sound/abnormalities/clouded_monk/eat.ogg", 75, 1)
				ourthing.adjustBruteLoss(-heal_amount)
				emergency_stop = TRUE
			if(!flicks)
				FlickOnAtom(U,'icons/obj/projectiles.dmi',"kinetic_blast",4)
				flicks = TRUE
	for(var/obj/vehicle/sealed/mecha/V in new_hits)
		if(!flicks)
			FlickOnAtom(U,'icons/obj/projectiles.dmi',"kinetic_blast",4)
			flicks = TRUE
	return ..()

/obj/effect/proc_holder/ability/aimed/dash/corroded/AbnoInteraction(mob/living/user)
	if(!istype(user, /mob/living/simple_animal/hostile/ordeal/dog_corrosion))
		return
	var/mob/living/simple_animal/hostile/ordeal/dog_corrosion/abno = user
	ToggleAct(abno,TRUE)
	abno.endCharge()

/obj/effect/proc_holder/ability/aimed/dash/corroded/strong
	dash_damage = 100
	dash_range = 30
	cooldown_time = 3 SECONDS

/obj/effect/proc_holder/ability/aimed/dash/firebird
	name = "firebird dash"
	dash_speed =  0.5
	dash_damage = 200
	dash_range = 50
	windup_delay = 0
	cooldown_time = 5 SECONDS
	env_breaking = TRUE

/obj/effect/proc_holder/ability/aimed/dash/firebird/Finalize(target, mob/living/user, list/path_list)
	for(var/turf/T in path_list)
		FlickOnAtom(T,'icons/effects/effects.dmi',"smoke",5)
	playsound(get_turf(user), 'sound/abnormalities/firebird/Firebird_Hit.ogg', 100, 0, 20) //TEMPORARY
	if(!do_after(user, 11, target = user))
		EndCharge(user)
		return
	return ..()

/obj/effect/proc_holder/ability/aimed/dash/firebird/TurfEffects(turf/T, mob/living/ourthing)
	for(var/turf/U in GetRange(T, 1))
		if(!U)
			break
		if(isopenturf(U) && !HasIdentList(U))
			//Real effect since fire produces light
			new /obj/effect/temp_visual/fire/fast(U)
		var/list/new_hits = HurtInTurf(ourthing, U, list(), dash_damage, WHITE_DAMAGE, hurt_mechs = TRUE, flags = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		var/flicks = FALSE
		for(var/mob/living/L in new_hits)//damage applied to targets in range
			visible_message(span_boldwarning("[src] blazes through [L]!"))
			L.deal_damage(dash_damage * 0.1, FIRE, ourthing, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
			if(ishuman(L))
				var/mob/living/carbon/human/H = L
				if(H.sanity_lost) // TODO: TEMPORARY AS HELL
					H.deal_damage(999, FIRE, ourthing, flags = (DAMAGE_FORCED))
			if(!flicks)
				FlickOnAtom(U,'icons/effects/effects.dmi',"cleave",5)
				flicks = TRUE
	return ..()

/obj/effect/proc_holder/ability/aimed/dash/bloodfiend
	name = "bloodfiend dash"
	dash_speed =  0.25
	dash_damage = 25
	dash_range = 4
	windup_delay = 0
	abil_charges = 0
	cooldown_time = 5 SECONDS
	env_breaking = TRUE

/obj/effect/proc_holder/ability/aimed/dash/bloodfiend/Finalize(target, mob/living/user, list/path_list)
	user.do_shaky_animation(1)
	if(!do_after(user, 0.5, target = user))
		EndCharge(user)
		return
	return ..()

/obj/effect/proc_holder/ability/aimed/dash/bloodfiend/PassCriteria(turf/T)
	.  = ..()
	if(.)
		if(locate(/obj/structure/table) in T.contents)
			return FALSE
		if(locate(/obj/structure/railing) in T.contents)
			return FALSE

/obj/effect/proc_holder/ability/aimed/dash/bloodfiend/TurfEffects(turf/T, mob/living/ourthing)
	playsound(T, 'sound/abnormalities/doomsdaycalendar/Lor_Slash_Generic.ogg', 20, 0, 4)
	for(var/turf/U in GetRange(T, 1))
		if(!U)
			break
		if(isopenturf(U) && !HasIdentList(U))
			var/obj/effect/temp_visual/slice/blood = new(U)
			blood.color = "#b52e19"
		HurtInTurf(ourthing, U, list(), dash_damage, RED_DAMAGE, null, TRUE, FALSE, TRUE, hurt_structure = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	return ..()

/obj/effect/proc_holder/ability/aimed/dash/bloodboss
	name = "bloodboss dash"
	dash_speed =  0.25
	dash_damage = 100
	dash_range = 4
	windup_delay = 0
	cooldown_time = 5 SECONDS
	env_breaking = TRUE
	var/safe_tag
	var/cutter_hit = FALSE

/obj/effect/proc_holder/ability/aimed/dash/bloodboss/Finalize(atom/target, mob/living/user, list/path_list)
	user.do_shaky_animation(1)
	var/turf/target_turf = get_turf(target)
	var/dx = user.x - target.x
	var/dy = user.y - target.y
	var/turf/safe_turf = locate(target.x - dx, target.y - dy, target.z)
	if(safe_turf.density)
		safe_turf = locate(target.x, target.y, target.z)
	safe_tag = AddIdentifier(safe_turf)
	for(var/turf/T in view(target_turf, 2))
		if(T == safe_turf)
			FlickOnAtom(T,'icons/effects/eldritch.dmi',"cloud_swirl",15)
			continue;
		FlickOnAtom(T,'icons/effects/eldritch.dmi',"blood_cloud_swirl",15)

	if(!do_after(user, 15, target = user))
		EndCharge(user)
		return

	. = ..()
	safe_tag = null

/obj/effect/proc_holder/ability/aimed/dash/bloodboss/TurfEffects(turf/T, mob/living/ourthing)
	playsound(T, 'sound/abnormalities/doomsdaycalendar/Lor_Slash_Generic.ogg', 20, 0, 4)
	for(var/turf/U in GetRange(T, 2))
		if(!U)
			break
		if(isopenturf(U) && !HasIdentList(U))
			if(AddIdentifier(U) == safe_tag)
				continue
			var/obj/effect/temp_visual/slice/blood = new(U)
			blood.color = "#b52e19"
		var/list/new_hits = HurtInTurf(ourthing, U, list(), dash_damage, RED_DAMAGE, null, TRUE, TRUE, TRUE, hurt_structure = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		for(var/mob/living/L in new_hits)//damage applied to targets in range
			cutter_hit = TRUE
			L.apply_lc_bleed(15)
	return ..()

/obj/effect/proc_holder/ability/aimed/dash/bloodboss/PassCriteria(turf/T)
	.  = ..()
	if(.)
		if(locate(/obj/structure/table) in T.contents)
			return FALSE
		if(locate(/obj/structure/railing) in T.contents)
			return FALSE

/obj/effect/proc_holder/ability/aimed/dash/bloodboss/AbnoInteraction(mob/living/user)
	var/remember_hit = cutter_hit
	cutter_hit = FALSE
	if(!istype(user, /mob/living/simple_animal/hostile/humanoid/blood/fiend/boss))
		return
	var/mob/living/simple_animal/hostile/humanoid/blood/fiend/boss/abno = user
	ToggleAct(abno,TRUE)
	abno.cutter_hit = remember_hit

#undef SKILL_MAP_COMBAT_CHECK
