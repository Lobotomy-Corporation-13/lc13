/mob/living/simple_animal/hostile/abnormality/gossypium //That fucking flower that I hate, coded by Xeros

	name = "Drenched Gossypium"
	desc = "A large, round cluster of white flowers, marred by patches of bloodstains. Its roots dangle beneath the cluster."
	icon = 'ModularLobotomy/_Lobotomyicons/32x48.dmi'
	icon_state = "fragment"
	icon_living = "fragment"
	portrait = "fragment"
	maxHealth = 900
	health = 900
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1.5, PALE_DAMAGE = 1.5)
	ranged = TRUE
	melee_damage_lower = 8
	melee_damage_upper = 12
	ranged_cooldown_time = 2
	rapid_melee = 2
	melee_damage_type = BLACK_DAMAGE
	stat_attack = HARD_CRIT
	attack_sound = 'sound/abnormalities/fragment/attack.ogg'
	attack_verb_continuous = "stabs"
	attack_verb_simple = "stab"
	faction = list("hostile")
	can_breach = TRUE
	threat_level = TETH_LEVEL
	start_qliphoth = 5
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 60,
		ABNORMALITY_WORK_INSIGHT = 40,
		ABNORMALITY_WORK_ATTACHMENT = 40,
		ABNORMALITY_WORK_REPRESSION = 40,
	)
	work_damage_amount = 5
	work_damage_type = RED_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/lust

	ego_list = list(
		/datum/ego_datum/weapon/fragment,
		/datum/ego_datum/armor/fragment,
	)
	gift_type =  /datum/ego_gifts/fragments
	abnormality_origin = ABNORMALITY_ORIGIN_LIMBUS

	var/burst_cooldown
	var/burst_cooldown_time = 10 SECONDS

/mob/living/simple_animal/hostile/abnormality/gossypium/Initialize(mapload) //Code shamelessly yoinked from Nosferatu
	. = ..()
	AddComponent(/datum/component/bloodfeast, siphon = TRUE, range = 2, starting = 0)

/mob/living/simple_animal/hostile/abnormality/gossypium/Life()
	. = ..()
	var/datum/component/bloodfeast/gathered_blood = GetComponent(/datum/component/bloodfeast)
	if(gathered_blood.blood_amount > 500)
		Enrage(gathered_blood)
		gathered_blood.blood_amount -= 500 //Prevent it from looping
	return

/mob/living/simple_animal/hostile/abnormality/gossypium/proc/Enrage(datum/component/bloodfeast/bloodfeast_component)
	if(IsContained()) // No bricking the mob by Berzerking when we aren't supposed to.
		return
	playsound(get_turf(src), 'sound/abnormalities/nosferatu/transform.ogg', 35, 8)
	animate(src, 1 SECONDS, color = "#882020", transform = matrix()*1.10)
	ranged_cooldown_time -= 0.1
	rapid_melee += 0.5 //Was gonna have this douche calm down after a while and not stack but it kept breaking so you'll just have to deal with the bastard snowballing

/mob/living/simple_animal/hostile/abnormality/gossypium/Move()
	if(!can_act)
		return
	return ..()

/mob/living/simple_animal/hostile/abnormality/gossypium/Goto(target, delay, minimum_distance)
	if(!can_act)
		return
	return ..()

/mob/living/simple_animal/hostile/abnormality/gossypium/MoveToTarget(list/possible_targets)
	if(!can_act)
		return TRUE
	return ..()

/mob/living/simple_animal/hostile/abnormality/gossypium/DestroySurroundings()
	if(!can_act)
		return
	return ..()


/mob/living/simple_animal/hostile/abnormality/gossypium/AttackingTarget(atom/attacked_target)
	if(!can_act)
		return

	if(!target)
		GiveTarget(attacked_target)

	if(client)
		OpenFire()
		return

	if(attacked_target) // You'd think this should be "attacked_target" but no this shit still uses target I hate it. // Now uses attacked_target I love it.
		if(ismecha(attacked_target))
			if(burst_cooldown <= world.time && prob(50))
				thornBurst()
			else
				OpenFire()
			return
		else if(isliving(attacked_target))
			var/mob/living/L = attacked_target
			if(L.stat != DEAD)
				if(burst_cooldown <= world.time && prob(50))
					thornBurst()
				else
					OpenFire()
			return
	return ..()

/mob/living/simple_animal/hostile/abnormality/gossypium/proc/thornBurst() //expanding square in melee
	if(burst_cooldown > world.time || !can_act)
		return
	burst_cooldown = world.time + burst_cooldown_time
	can_act = FALSE
	var/turf/origin = get_turf(src)
	playsound(origin, 'sound/abnormalities/ebonyqueen/strongcharge.ogg', 75, 0, 5)
	playsound(origin, 'sound/creatures/venus_trap_hurt.ogg', 75, 0, 5)
	SLEEP_CHECK_DEATH(9)
	var/last_dist = 0
	for(var/turf/T in spiral_range_turfs(2, origin))
		if(!T)
			continue
		var/dist = get_dist(origin, T)
		if(dist > last_dist)
			last_dist = dist
			SLEEP_CHECK_DEATH(1 + min(2 - last_dist, 12) * 0.25) //gets faster as it gets further out
		new /obj/effect/temp_visual/vine(T, src)
	SLEEP_CHECK_DEATH(8)
	icon_state = icon_living
	SLEEP_CHECK_DEATH(3)
	can_act = TRUE

/mob/living/simple_animal/hostile/abnormality/gossypium/OpenFire()
	if(!can_act)
		return

	ranged_cooldown = world.time + ranged_cooldown_time
	vineStab(target)

/mob/living/simple_animal/hostile/abnormality/gossypium/proc/vineStab(atom/attack_target) //single target
	if(!can_act)
		return
	can_act = FALSE
	playsound(get_turf(src), 'sound/creatures/venus_trap_hurt.ogg', 75, 0, 5)
	icon_state = "ebonyqueen_attack2"
	var/turf/T = get_turf(attack_target)
	SLEEP_CHECK_DEATH(1)
	new /obj/effect/temp_visual/vine(T, src)
	SLEEP_CHECK_DEATH(4)
	icon_state = icon_living
	SLEEP_CHECK_DEATH(2)
	can_act = TRUE






















/obj/effect/temp_visual/vine //Keeping this shit far away for organization purposes
	name = "thirsting vines"
	desc = "A target warning you of incoming pain"
	icon = 'ModularLobotomy/_Lobotomyicons/tegu_effects.dmi'
	icon_state = "vines"
	duration = 6
	layer = RIPPLE_LAYER	//We want this HIGH. SUPER HIGH. We want it so that you can absolutely, guaranteed, see exactly what is about to hit you.
	var/vine_damage = 25 //40 less Black Damage than Ebony
	var/mob/living/source //who made this, anyway


/obj/effect/temp_visual/vine/Initialize(mapload, new_source)
	. = ..()
	if(new_source)
		source = new_source
	addtimer(CALLBACK(src, PROC_REF(explode)), 0.5 SECONDS)

/obj/effect/temp_visual/vine/proc/explode()
	var/turf/target_turf = get_turf(src)
	if(!target_turf)
		return
	if(QDELETED(source) || source?.stat == DEAD || !source)
		return
	playsound(target_turf, 'sound/abnormalities/ebonyqueen/attack.ogg', 40, 0, 8)
	new /obj/effect/temp_visual/thornspike(target_turf)
	var/list/hit = source.HurtInTurf(target_turf, list(), damage = vine_damage, damage_type = BLACK_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, mech_damage = vine_damage/2, attack_type = (ATTACK_TYPE_SPECIAL))
	for(var/mob/living/L in hit)
		if(L.stat == DEAD || L.throwing)
			continue
		L.visible_message(span_userdanger("[src] knocks [L] away!"), span_userdanger("[src] knocks you away!"))
		var/turf/thrownat = get_ranged_target_turf(src, pick(GLOB.alldirs), 2)
		L.throw_at(thrownat, 1, 1, spin = TRUE, force = MOVE_FORCE_OVERPOWERING, gentle = TRUE)
	for(var/obj/vehicle/sealed/mecha/M in hit) //also damage mechs.
		for(var/O in M.occupants)
			var/mob/living/occupant = O
			to_chat(occupant, span_userdanger("Your [M.name] is struck by [src]!"))
	qdel(src)
