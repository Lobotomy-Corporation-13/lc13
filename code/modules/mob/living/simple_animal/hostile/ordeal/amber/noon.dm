// Amber dawn
/mob/living/simple_animal/hostile/ordeal/amber_noon
	name = "fatty food"
	desc = "A tiny worm-like creature covered in boils."
	icon = 'ModularLobotomy/_Lobotomyicons/48x48.dmi'
	icon_state = "amber_noon"
	icon_living = "amber_noon"
	icon_dead = "amber_noon_ded"
	faction = list("amber_ordeal")
	pixel_x = -8
	base_pixel_x = -8
	pixel_x = -8
	base_pixel_x = -8
	maxHealth = 500
	health = 500
	move_to_delay = 4.5
	rapid_melee = 2
	density = TRUE
	status_flags = CANPUSH | MUST_HIT_PROJECTILE
	melee_damage_lower = 25
	melee_damage_upper = 30
	turns_per_move = 2
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	attack_sound = 'sound/effects/ordeals/amber/dawn_attack.ogg'
	attack_sound = 'sound/effects/ordeals/amber/dawn_dead.ogg'
	damage_coeff = list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 2)
	blood_volume = BLOOD_VOLUME_NORMAL
	butcher_results = list(/obj/item/food/meat/slab/worm = 1)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/worm = 1)
	silk_results = list(/obj/item/stack/sheet/silk/amber_simple = 1)

	/// This cooldown responds for both the burrowing and spawning in the dawns
	var/burrow_cooldown
	var/burrow_cooldown_time = 1 MINUTES

	/// If TRUE - cannot move nor attack
	var/burrowing = FALSE
	var/can_burrow_solo = TRUE

/mob/living/simple_animal/hostile/ordeal/amber_noon/Initialize()
	. = ..()
	if(LAZYLEN(butcher_results)) //// It burrows in on spawn, spawned ones shouldn't
		addtimer(CALLBACK(src, PROC_REF(BurrowOut), get_turf(src)))
	if(SSmaptype == "lcorp_city")
		can_burrow_solo = FALSE

/mob/living/simple_animal/hostile/ordeal/amber_noon/death(gibbed)
	alpha = 255
	var/numspawned = rand(3, 8)
	playsound(get_turf(src), 'sound/effects/ordeals/amber/dusk_create.ogg', 50, FALSE)
	for(var/i in 1 to numspawned)
		var/mob/living/simple_animal/hostile/ordeal/amber_bug/spawned/L = new (get_turf(src))
		L.butcher_results = list()
		var/turf/throw_target = pick(range(5, src))
		L.throw_at(throw_target, 10, 2)

		//Cant' forget to add it to the ordeal
		if(ordeal_reference)
			L.ordeal_reference = ordeal_reference
			ordeal_reference.ordeal_mobs += L
	return ..()

/mob/living/simple_animal/hostile/ordeal/amber_noon/Life()
	. = ..()
	if(!.) // Dead
		return FALSE
	if(can_burrow_solo && !burrowing && world.time > burrow_cooldown)
		BurrowIn()

/mob/living/simple_animal/hostile/ordeal/amber_noon/CanAttack(atom/the_target)
	if(burrowing)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/ordeal/amber_noon/Move()
	if(burrowing)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/ordeal/amber_noon/Goto(target, delay, minimum_distance)
	if(burrowing)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/ordeal/amber_noon/DestroySurroundings()
	if(burrowing)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/ordeal/amber_noon/GiveTarget(new_target)
	. = ..()
	if(. && target) //reset burrow cooldown whenever in combat
		burrow_cooldown = world.time + burrow_cooldown_time

/mob/living/simple_animal/hostile/ordeal/amber_noon/AttackingTarget(atom/attacked_target)
	if(burrowing)
		return
	. = ..()	//The Noons are too fat to jump

/mob/living/simple_animal/hostile/ordeal/amber_noon/proc/BurrowIn(turf/T)
	if(!T)
		if(length(GLOB.xeno_spawn))
			T = pick(GLOB.xeno_spawn)

		else if(SSmaptype == "lcorp_city")
			can_burrow_solo = FALSE
			return

		else
			can_burrow_solo = FALSE
			return
	burrowing = TRUE
	visible_message(span_danger("[src] burrows into the ground!"))
	playsound(get_turf(src), 'sound/effects/ordeals/amber/dawn_dig_in.ogg', 25, 1)
	animate(src, alpha = 0, time = 5)
	SLEEP_CHECK_DEATH(5)
	BurrowOut(T)

/mob/living/simple_animal/hostile/ordeal/amber_noon/proc/BurrowOut(turf/T)
	burrowing = TRUE
	alpha = 0
	var/list/valid_turfs = list(T)
	for(var/turf/PT in RANGE_TURFS(2, T))
		if(!PT.is_blocked_turf_ignore_climbable())
			valid_turfs |= PT
	var/turf/target_turf = pick(valid_turfs)
	forceMove(target_turf)
	new /obj/effect/temp_visual/small_smoke/halfsecond(target_turf)
	animate(src, alpha = 255, time = 5)
	playsound(get_turf(src), 'sound/effects/ordeals/amber/dawn_dig_out.ogg', 25, 1)
	visible_message(span_bolddanger("[src] burrows out from the ground!"))
	SLEEP_CHECK_DEATH(5)
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(target_turf, src)
	animate(D, alpha = 0, transform = matrix()*1.5, time = 5)
	for(var/mob/living/L in target_turf)
		if(!faction_check_mob(L))
			L.deal_damage(5, RED_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	burrow_cooldown = world.time + burrow_cooldown_time
	burrowing = FALSE
