//Placed in support due to choreographed AoE spam
/mob/living/simple_animal/hostile/rcorp_abno/hard/ebony_queen
	name = "Ebony Queen’s Apple"
	desc = "An Abnormality taking the form of a tall humanoid with a rotted apple for a head, wearing a regal robe. Seems immune to BLACK."
	maxHealth = 2000
	health = 2000
	melee_damage_type = BLACK_DAMAGE
	melee_damage_lower = 35
	melee_damage_upper = 45
	speed = 6
	move_to_delay = 6
	ranged = TRUE
	ranged_cooldown_time = 1 //fast!
	rapid_melee = 8 // every 1/4 second
	damage_coeff = list(RED_DAMAGE = 1.0, WHITE_DAMAGE = 1.3, BLACK_DAMAGE = 0, PALE_DAMAGE = 0.7)
	ranged = TRUE
	original_abno = /mob/living/simple_animal/hostile/abnormality/ebony_queen

	var/barrier_cooldown
	var/barrier_cooldown_time = 4 SECONDS
	var/barrage_cooldown
	var/barrage_cooldown_time = 8 SECONDS
	var/burst_cooldown
	var/burst_cooldown_time = 10 SECONDS
	var/barrage_range = 10

	//PLAYABLES ATTACKS
	attack_action_types = list(
		/datum/action/innate/rca_abnormality_attack/ebony_root,
		/datum/action/innate/rca_abnormality_attack/ebony_barrier,
		/datum/action/innate/rca_abnormality_attack/ebony_barrage,
		/datum/action/cooldown/rca_ebony_burst,
	)

	abno_additional_instructions = "<h1>You are Ebony Queen's Apple, A Support Role Abnormality.</h1><br>\
		<b>|Ebony Queen|: You are immune to BLACK damage. <br>\
		<br>\
		|Entangling Roots|: Your melee attack is entirely replaced with ranged AoEs, each having their own cooldown. \
		You have three variants of AoE attacks you may use, those being: Root Spike, Thorn Barrier, Root Barrage. \
		When selected you will perform the attack you chose when attempting a ranged attack. \
		All variants do the same damage of 65 BLACK, only cooldown and pattern changes between variants. \
		All your thorn attacks apply a knockback of 1 tile, this knockback cannot stun. <br>\
		<br>\
		|Root Spike|: This attack has a 0.1 second cooldown and targets only one tile being the one you selected. <br>\
		<br>\
		|Thorn Barrier|: This attack has a 4 second cooldown and targets tiles in a 3x3 AoE centered around the tile you selected. <br>\
		<br>\
		|Root Barrage|: This attack has a 8 second cooldown and targets tiles in a straight line starting from yourself up to 10 tiles in the direction of which you targetted. <br>\
		<br>\
		|The Audacity...!|: Your Thorn Burst action is not tied to your standard attacks and is instead it's own ability. \
		When used you will initiate a 5x5 expanding AoE centered around yourself, the speed at which the AoE expands increases as it expands. \
		It's damage is the same as your standard attacks. </b>"

/datum/action/innate/rca_abnormality_attack/ebony_root
	name = "Root Spike"
	button_icon_state = "ebony_root"
	chosen_message = span_colossus("You will now shoot your roots from the ground.")
	chosen_attack_num = 1

/datum/action/innate/rca_abnormality_attack/ebony_barrier
	name = "Thorn Barrier"
	button_icon_state = "ebony_barrier"
	chosen_message = span_colossus("You will now create a barrier of thorns.")
	chosen_attack_num = 2

/datum/action/innate/rca_abnormality_attack/ebony_barrage
	name = "Root Barrage"
	button_icon_state = "ebony_barrage"
	chosen_message = span_colossus("You will now shoot a devastating line of roots.")
	chosen_attack_num = 3

/datum/action/cooldown/rca_ebony_burst
	name = "Thorn Burst"
	icon_icon = 'icons/mob/actions/actions_abnormality.dmi'
	button_icon_state = "ebony_burst"
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE
	cooldown_time = 10 SECONDS

/datum/action/cooldown/rca_ebony_burst/Trigger()
	if(!..())
		return FALSE
	var/mob/living/simple_animal/hostile/rcorp_abno/hard/ebony_queen/EQ = owner
	if(!istype(EQ))
		return FALSE
	if(EQ.barrier_cooldown > world.time && !EQ.client || !EQ.can_act)
		return FALSE
	StartCooldown()
	EQ.thornBurst()
	return TRUE

/mob/living/simple_animal/hostile/rcorp_abno/hard/ebony_queen/Move()
	if(!can_act)
		return
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/ebony_queen/Goto(target, delay, minimum_distance)
	if(!can_act)
		return
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/ebony_queen/MoveToTarget(list/possible_targets)
	if(!can_act)
		return TRUE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/ebony_queen/DestroySurroundings()
	if(!can_act)
		return
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/ebony_queen/death(gibbed)
	icon = 'ModularLobotomy/_Lobotomyicons/abno_cores/waw.dmi'
	density = FALSE
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/ebony_queen/AttackingTarget(atom/attacked_target)
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

/mob/living/simple_animal/hostile/rcorp_abno/hard/ebony_queen/OpenFire()
	if(!can_act)
		return

	ranged_cooldown = world.time + ranged_cooldown_time

	if(client)
		switch(chosen_attack)
			if(1)
				rootStab(target)
			if(2)
				thornBarrier(target)
			if(3)
				rootBarrage(target)
		return

	if((barrage_cooldown <= world.time) && get_dist(src, target) >= 2 && prob(50))
		rootBarrage(target)
	else if((barrier_cooldown <= world.time) && prob(50))
		thornBarrier(target)
	else
		rootStab(target)
	return

/obj/effect/temp_visual/rca_root
	name = "pale stem"
	desc = "A target warning you of incoming pain"
	icon = 'ModularLobotomy/_Lobotomyicons/tegu_effects.dmi'
	icon_state = "vines"
	duration = 6
	layer = RIPPLE_LAYER	//We want this HIGH. SUPER HIGH. We want it so that you can absolutely, guaranteed, see exactly what is about to hit you.
	var/root_damage = 65 //Black Damage
	var/mob/living/caster //who made this, anyway

/obj/effect/temp_visual/rca_root/Initialize(mapload, new_caster)
	. = ..()
	if(new_caster)
		caster = new_caster
	addtimer(CALLBACK(src, PROC_REF(explode)), 0.5 SECONDS)

/obj/effect/temp_visual/rca_root/proc/explode()
	var/turf/target_turf = get_turf(src)
	if(!target_turf)
		return
	if(QDELETED(caster) || caster?.stat == DEAD || !caster)
		return
	playsound(target_turf, 'sound/abnormalities/ebonyqueen/attack.ogg', 40, 0, 8)
	new /obj/effect/temp_visual/thornspike(target_turf)
	var/list/hit = caster.HurtInTurf(target_turf, list(), damage = root_damage, damage_type = BLACK_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, mech_damage = root_damage/2, attack_type = (ATTACK_TYPE_SPECIAL))
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

	//Special attacks; there are four of them
/mob/living/simple_animal/hostile/rcorp_abno/hard/ebony_queen/proc/rootStab(atom/attack_target) //single target
	if(!can_act)
		return
	can_act = FALSE
	playsound(get_turf(src), 'sound/creatures/venus_trap_hurt.ogg', 75, 0, 5)
	icon_state = "ebonyqueen_attack2"
	var/turf/T = get_turf(attack_target)
	SLEEP_CHECK_DEATH(1)
	new /obj/effect/temp_visual/root(T, src)
	SLEEP_CHECK_DEATH(4)
	icon_state = icon_living
	SLEEP_CHECK_DEATH(2)
	can_act = TRUE

/mob/living/simple_animal/hostile/rcorp_abno/hard/ebony_queen/proc/thornBarrier(atom/attack_target) //barrier of thorns
	if(barrier_cooldown > world.time || !can_act)
		return
	barrier_cooldown = world.time + barrier_cooldown_time
	can_act = FALSE
	playsound(get_turf(src), 'sound/abnormalities/ebonyqueen/charge.ogg', 175, 0, 5) //very quiet sound file
	icon_state = "ebonyqueen_attack3"
	SLEEP_CHECK_DEATH(7.75)
	//check if target still exists after the sleep and bail if not
	if(QDELETED(attack_target))
		if(!client && FindTarget())
			attack_target = target
		else
			icon_state = icon_living
			SLEEP_CHECK_DEATH(3)
			can_act = TRUE
			return
	var/turf/target_turf = get_turf(attack_target)
	SLEEP_CHECK_DEATH(0.25) //slight offset
	for(var/turf/T in RANGE_TURFS(1, target_turf))
		new /obj/effect/temp_visual/root(T, src)
	SLEEP_CHECK_DEATH(7)
	icon_state = icon_living
	SLEEP_CHECK_DEATH(3)
	can_act = TRUE

/mob/living/simple_animal/hostile/rcorp_abno/hard/ebony_queen/proc/thornBurst() //expanding square in melee
	if(burst_cooldown > world.time || !can_act)
		return
	burst_cooldown = world.time + burst_cooldown_time
	can_act = FALSE
	var/turf/origin = get_turf(src)
	playsound(origin, 'sound/abnormalities/ebonyqueen/strongcharge.ogg', 75, 0, 5)
	playsound(origin, 'sound/creatures/venus_trap_hurt.ogg', 75, 0, 5)
	icon_state = "ebonyqueen_attack4"
	SLEEP_CHECK_DEATH(9)
	var/last_dist = 0
	for(var/turf/T in spiral_range_turfs(2, origin))
		if(!T)
			continue
		var/dist = get_dist(origin, T)
		if(dist > last_dist)
			last_dist = dist
			SLEEP_CHECK_DEATH(1 + min(2 - last_dist, 12) * 0.25) //gets faster as it gets further out
		new /obj/effect/temp_visual/root(T, src)
	SLEEP_CHECK_DEATH(8)
	icon_state = icon_living
	SLEEP_CHECK_DEATH(3)
	can_act = TRUE

/mob/living/simple_animal/hostile/rcorp_abno/hard/ebony_queen/proc/rootBarrage(atom/attack_target) //line attack
	if(barrage_cooldown > world.time || !can_act)
		return
	barrage_cooldown = world.time + barrage_cooldown_time
	can_act = FALSE
	playsound(get_turf(src), 'sound/abnormalities/ebonyqueen/strongcharge.ogg', 75, 0, 5)
	icon_state = "ebonyqueen_attack1"
	SLEEP_CHECK_DEATH(7)
	//check if target still exists after the sleep and bail if not
	if(QDELETED(attack_target))
		if(!client && FindTarget())
			attack_target = target
		else
			icon_state = icon_living
			SLEEP_CHECK_DEATH(3)
			can_act = TRUE
			return

	var/turf/target_turf = get_ranged_target_turf_direct(src, attack_target, barrage_range)
	var/count = 0
	for(var/turf/T in getline(get_turf(src), target_turf))
		if(T.density)
			break
		count = count + 1
		if(get_dist(src, T) < 2)
			continue
		addtimer(CALLBACK(src, PROC_REF(stabHit), T), (3 * ((count*0.50)+1)) + 0.25 SECONDS)
	SLEEP_CHECK_DEATH(10)
	icon_state = icon_living
	SLEEP_CHECK_DEATH(3)
	can_act = TRUE

/mob/living/simple_animal/hostile/rcorp_abno/hard/ebony_queen/proc/stabHit(turf/T)
	if(QDELETED(src) || stat == DEAD)
		return
	new /obj/effect/temp_visual/root(T, src)

