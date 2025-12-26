//W-Corp Cleanup variants of Peccatulum (sin mobs) that cannot dash through wave barriers

//Sloth - has Dash() proc that checks turf blocking
/mob/living/simple_animal/hostile/ordeal/sin_sloth/wave
	name = "Peccatulum Acediae"

/mob/living/simple_animal/hostile/ordeal/sin_sloth/wave/Dash(mob/living/target)
	if(!istype(target))
		return
	var/dist = get_dist(target, src)
	if(dist > 2 && jump_cooldown < world.time && dist < jump_range)
		//Check for wave barriers in path
		var/list/dash_line = getline(src, target)
		for(var/turf/line_turf in dash_line)
			if(locate(/obj/structure/wave_barrier) in line_turf.contents)
				return //Don't dash through barriers
		return ..()

/mob/living/simple_animal/hostile/ordeal/sin_sloth/noon/wave
	name = "Peccatulum Acediae?"

/mob/living/simple_animal/hostile/ordeal/sin_sloth/noon/wave/Dash(mob/living/target)
	if(!istype(target))
		return
	var/dist = get_dist(target, src)
	if(dist > 2 && jump_cooldown < world.time && dist < jump_range)
		//Check for wave barriers in path
		var/list/dash_line = getline(src, target)
		for(var/turf/line_turf in dash_line)
			if(locate(/obj/structure/wave_barrier) in line_turf.contents)
				return //Don't dash through barriers
		return ..()

//Gluttony - doesn't dash, no variant needed but adding for consistency
/mob/living/simple_animal/hostile/ordeal/sin_gluttony/wave
	name = "Peccatulum Gulae"

/mob/living/simple_animal/hostile/ordeal/sin_gluttony/noon/wave
	name = "Peccatulum Gulae?"

//Gloom - dawn doesn't dash, noon has dash in OpenFire
/mob/living/simple_animal/hostile/ordeal/sin_gloom/wave
	name = "Peccatulum Morositatis"

/mob/living/simple_animal/hostile/ordeal/sin_gloom/noon/wave
	name = "Peccatulum Morositatis?"

/mob/living/simple_animal/hostile/ordeal/sin_gloom/noon/wave/OpenFire()
	if(!can_act || !istype(target))
		return
	var/dist = get_dist(target, src)
	if(dist < 6)
		var/list/dash_line = getline(src, target)
		//Check for wave barriers in path
		for(var/turf/line_turf in dash_line)
			if(locate(/obj/structure/wave_barrier) in line_turf.contents)
				return //Don't dash through barriers
		return ..()

//Pride - has Charge() proc
/mob/living/simple_animal/hostile/ordeal/sin_pride/wave
	name = "Peccatulum Superbiae"

/mob/living/simple_animal/hostile/ordeal/sin_pride/wave/Charge(move_dir, times_ran)
	if(health <= 0)
		return
	var/stop_charge = FALSE
	if(times_ran >= dash_num)
		stop_charge = TRUE
	var/turf/T = get_step(get_turf(src), move_dir)
	if(!T)
		charging = FALSE
		return
	if(T.density)
		stop_charge = TRUE
	for(var/obj/structure/window/W in T.contents)
		stop_charge = TRUE
	for(var/obj/machinery/door/poddoor/P in T.contents)
		stop_charge = TRUE
		continue
	//Check for wave barriers
	if(locate(/obj/structure/wave_barrier) in T.contents)
		stop_charge = TRUE
	if(stop_charge)
		charging = FALSE
		icon_state = icon_living
		return
	for(var/obj/machinery/door/D in T.contents)
		if(D.density)
			D.open(2)
	forceMove(T)
	playsound(src, 'sound/weapons/fixer/generic/blade1.ogg', 100, 1)
	for(var/turf/TF in range(dash_range, T))
		new /obj/effect/temp_visual/smash_effect(TF)
	for(var/mob/living/L in range(dash_range, T))
		if(faction_check_mob(L))
			continue
		if(L in been_hit)
			continue
		if(L.z != z)
			continue
		L.visible_message(span_warning("[src] shreds [L] as it passes by!"), span_boldwarning("[src] shreds you!"))
		var/turf/LT = get_turf(L)
		new /obj/effect/temp_visual/kinetic_blast(LT)
		L.deal_damage(dash_damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		been_hit += L
		playsound(L, 'sound/weapons/fixer/generic/sword4.ogg', 75, 1)
	addtimer(CALLBACK(src, PROC_REF(Charge), move_dir, (times_ran + 1)), 1)

/mob/living/simple_animal/hostile/ordeal/sin_pride/noon/wave
	name = "Peccatulum Superbiae?"

/mob/living/simple_animal/hostile/ordeal/sin_pride/noon/wave/Charge(move_dir, times_ran)
	if(health <= 0)
		return
	var/stop_charge = FALSE
	if(times_ran >= dash_num)
		stop_charge = TRUE
	var/turf/T = get_step(get_turf(src), move_dir)
	if(!T)
		charging = FALSE
		return
	if(T.density)
		stop_charge = TRUE
	for(var/obj/structure/window/W in T.contents)
		stop_charge = TRUE
	for(var/obj/machinery/door/poddoor/P in T.contents)
		stop_charge = TRUE
		continue
	//Check for wave barriers
	if(locate(/obj/structure/wave_barrier) in T.contents)
		stop_charge = TRUE
	if(stop_charge)
		charging = FALSE
		icon_state = icon_living
		return
	for(var/obj/machinery/door/D in T.contents)
		if(D.density)
			D.open(2)
	forceMove(T)
	playsound(src, 'sound/weapons/fixer/generic/blade1.ogg', 100, 1)
	for(var/turf/TF in range(dash_range, T))
		new /obj/effect/temp_visual/smash_effect(TF)
	for(var/mob/living/L in range(dash_range, T))
		if(faction_check_mob(L))
			continue
		if(L in been_hit)
			continue
		if(L.z != z)
			continue
		L.visible_message(span_warning("[src] shreds [L] as it passes by!"), span_boldwarning("[src] shreds you!"))
		var/turf/LT = get_turf(L)
		new /obj/effect/temp_visual/kinetic_blast(LT)
		L.deal_damage(dash_damage, BLACK_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
		been_hit += L
		playsound(L, 'sound/weapons/fixer/generic/sword4.ogg', 75, 1)
	addtimer(CALLBACK(src, PROC_REF(Charge), move_dir, (times_ran + 1)), 1)

//Lust - doesn't dash/charge through turfs, uses beam attack
/mob/living/simple_animal/hostile/ordeal/sin_lust/wave
	name = "Peccatulum Luxuriae"

/mob/living/simple_animal/hostile/ordeal/sin_lust/noon/wave
	name = "Peccatulum Luxuriae?"

//Wrath - has Charge() proc using walk_towards
/mob/living/simple_animal/hostile/ordeal/sin_wrath/wave
	name = "Peccatulum Irae"

/mob/living/simple_animal/hostile/ordeal/sin_wrath/wave/Bump(atom/A)
	//Stop charge if we hit a wave barrier
	if(charging && istype(A, /obj/structure/wave_barrier))
		EndCharge(TRUE)
		return
	return ..()

/mob/living/simple_animal/hostile/ordeal/sin_wrath/wave/Charge(atom/chargeat = target, delay = 1 SECONDS, chargepast = 2)
	if(stat == DEAD)
		return
	if(charge_attack_cooldown > world.time || charging || revving_charge)
		return
	if(!chargeat)
		return
	//Check for wave barriers in path
	var/turf/T = get_ranged_target_turf(chargeat, get_dir(src, chargeat), chargepast)
	if(T)
		for(var/turf/line_turf in getline(src, T))
			if(locate(/obj/structure/wave_barrier) in line_turf.contents)
				return //Don't charge through barriers
	return ..()

/mob/living/simple_animal/hostile/ordeal/sin_wrath/noon/wave
	name = "Peccatulum Irae?"

/mob/living/simple_animal/hostile/ordeal/sin_wrath/noon/wave/Bump(atom/A)
	//Stop charge if we hit a wave barrier
	if(charging && istype(A, /obj/structure/wave_barrier))
		EndCharge(TRUE)
		return
	return ..()

/mob/living/simple_animal/hostile/ordeal/sin_wrath/noon/wave/Charge(atom/chargeat = target, delay = 1 SECONDS, chargepast = 2)
	if(stat == DEAD)
		return
	if(charge_attack_cooldown > world.time || charging || revving_charge)
		return
	if(!chargeat)
		return
	//Check for wave barriers in path
	var/turf/T = get_ranged_target_turf(chargeat, get_dir(src, chargeat), chargepast)
	if(T)
		for(var/turf/line_turf in getline(src, T))
			if(locate(/obj/structure/wave_barrier) in line_turf.contents)
				return //Don't charge through barriers
	return ..()
