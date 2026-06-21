
// Green noon
/mob/living/simple_animal/hostile/ordeal/green_bot_big
	name = "process of understanding"
	desc = "A big robot with a saw and a machine gun in place of its hands."
	icon = 'ModularLobotomy/_Lobotomyicons/48x48.dmi'
	icon_state = "green_bot"
	icon_living = "green_bot"
	icon_dead = "green_bot_dead"
	faction = list("green_ordeal")
	pixel_x = -8
	base_pixel_x = -8
	gender = NEUTER
	mob_biotypes = MOB_ROBOTIC
	maxHealth = 900
	health = 900
	speed = 3
	move_to_delay = 6
	melee_damage_lower = 22 // Full damage is done on the entire turf of target
	melee_damage_upper = 26
	attack_verb_continuous = "saws"
	attack_verb_simple = "saw"
	attack_sound = 'sound/effects/ordeals/green/saw.ogg'
	attack_vis_effect = ATTACK_EFFECT_CLAW
	ranged = 1
	rapid = 5
	rapid_fire_delay = 2
	ranged_cooldown_time = 15
	check_friendly_fire = TRUE //stop shooting each other
	projectiletype = /obj/projectile/bullet/c9x19mm/greenbot
	projectilesound = 'sound/effects/ordeals/green/fire.ogg'
	death_sound = 'sound/effects/ordeals/green/noon_dead.ogg'
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.3, BLACK_DAMAGE = 2, PALE_DAMAGE = 1)
	butcher_results = list(/obj/item/food/meat/slab/robot = 2)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/robot = 1)
	silk_results = list(/obj/item/stack/sheet/silk/green_advanced = 1,
						/obj/item/stack/sheet/silk/green_simple = 2)

	/// Can't move/attack when it's TRUE
	var/reloading = FALSE
	var/firing_time = 0
	var/firing_cooldown = 1.2
	/// When at 12 - it will start "reloading"
	var/fire_count = 0

/mob/living/simple_animal/hostile/ordeal/green_bot_big/CanAttack(atom/the_target)
	if(reloading)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/ordeal/green_bot_big/Move()
	if(reloading)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/ordeal/green_bot_big/Goto(target, delay, minimum_distance)
	if(reloading)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/ordeal/green_bot_big/DestroySurroundings()
	if(reloading)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/ordeal/green_bot_big/OpenFire(atom/A)
	if(reloading)
		return FALSE
	firing_time = world.time
	fire_count += 1
	if(fire_count >= 12)
		StartReloading()
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/ordeal/green_bot_big/AttackingTarget(atom/attacked_target)
	if(reloading)
		return FALSE
	if(world.time < firing_time + firing_cooldown SECONDS)
		return FALSE
	. = ..()
	if(.)
		if(!istype(attacked_target, /mob/living))
			return
		var/turf/T = get_turf(attacked_target)
		if(!T)
			return
		for(var/i = 1 to 4)
			if(!T)
				return
			new /obj/effect/temp_visual/saw_effect(T)
			HurtInTurf(T, list(), 8, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_MELEE))
			SLEEP_CHECK_DEATH(1)

/mob/living/simple_animal/hostile/ordeal/green_bot_big/spawn_gibs()
	new /obj/effect/gibspawner/scrap_metal(drop_location(), src)

/mob/living/simple_animal/hostile/ordeal/green_bot_big/spawn_dust()
	return

/mob/living/simple_animal/hostile/ordeal/green_bot_big/proc/StartReloading()
	reloading = TRUE
	icon_state = "green_bot_reload"
	playsound(get_turf(src), 'sound/effects/ordeals/green/cooldown.ogg', 50, FALSE)
	for(var/i = 1 to 8)
		new /obj/effect/temp_visual/green_noon_reload(get_turf(src))
		SLEEP_CHECK_DEATH(8)
	fire_count = 0
	reloading = FALSE
	icon_state = icon_living


//Below by Xeroes
/mob/living/simple_animal/hostile/ordeal/green_bot_rocket //Rocket Noons, thanks to Raye Aleciania on the LC13 discord for providing sprites
	name = "pursuit of purpose"
	desc = "A big robot with a saw and a rocket launcher in place of its hands."
	icon = 'ModularLobotomy/_Lobotomyicons/48x48.dmi'
	icon_state = "green_bot_rocket"
	icon_living = "green_bot_rocket"
	icon_dead = "green_bot_rocket_dead"
	faction = list("green_ordeal")
	pixel_x = -8
	base_pixel_x = -8
	gender = NEUTER
	mob_biotypes = MOB_ROBOTIC
	maxHealth = 1100 //Little bit beefier to compensate for them being easier to dodge
	health = 1100
	speed = 3
	move_to_delay = 6
	melee_damage_lower = 22 // Full damage is done on the entire turf of target
	melee_damage_upper = 26
	attack_verb_continuous = "saws"
	attack_verb_simple = "saw"
	attack_sound = 'sound/effects/ordeals/green/saw.ogg'
	attack_vis_effect = ATTACK_EFFECT_CLAW
	ranged = 1
	ranged_cooldown_time = 15
	projectiletype = /obj/projectile/ego_bullet/grungeon_rocket
	projectilesound = 'sound/weapons/ego/cannon.ogg'
	death_sound = 'sound/effects/ordeals/green/noon_dead.ogg'
	damage_coeff = list(RED_DAMAGE = 0.6, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1.8, PALE_DAMAGE = 1)
	butcher_results = list(/obj/item/food/meat/slab/robot = 4)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/robot = 2)
	silk_results = list(
		/obj/item/stack/sheet/silk/green_advanced = 2,
		/obj/item/stack/sheet/silk/green_simple = 2,
	)
	var/datum/beam/current_beam = null

/mob/living/simple_animal/hostile/ordeal/green_bot_rocket/OpenFire(atom/A)
	if(!can_act)
		return
	if(PrepareToFire(A))
		return ..()
	return ..()

/mob/living/simple_animal/hostile/ordeal/green_bot_rocket/proc/PrepareToFire(atom/A) //Copypasted code from TTLS snipers. Intended to serve as the "warning" for the minigun.
	current_beam = Beam(A, icon_state="blood", time = 0.9 SECONDS)
	can_act = FALSE
	SLEEP_CHECK_DEATH(10)
	if(!(A in view(10, src)))
		can_act = TRUE
		return FALSE
	can_act = TRUE
	return TRUE

/mob/living/simple_animal/hostile/ordeal/green_bot_rocket/AttackingTarget(atom/attacked_target)
	. = ..()
	if(.)
		if(!istype(attacked_target, /mob/living))
			return
		var/turf/T = get_turf(attacked_target)
		if(!T)
			return
		for(var/i = 1 to 4)
			if(!T)
				return
			new /obj/effect/temp_visual/saw_effect(T)
			HurtInTurf(T, list(), 8, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_MELEE))
			SLEEP_CHECK_DEATH(1)

/mob/living/simple_animal/hostile/ordeal/green_bot_rocket/spawn_gibs()
	new /obj/effect/gibspawner/scrap_metal(drop_location(), src)

/mob/living/simple_animal/hostile/ordeal/green_bot_rocket/spawn_dust()
	return

/obj/projectile/ego_bullet/grungeon_rocket
	name = "rocket"
	icon_state = "pulse0"
	damage = 25 // Direct hit
	damage_type = RED_DAMAGE

/obj/projectile/ego_bullet/grungeon_rocket/on_hit(atom/target, blocked = FALSE)
	..()
	for(var/mob/living/L in view(1, target))
		new /obj/effect/temp_visual/fire/fast(get_turf(L))
		L.deal_damage(10, RED_DAMAGE, firer, attack_type = (ATTACK_TYPE_RANGED))
	return BULLET_ACT_HIT

/mob/living/simple_animal/hostile/ordeal/green_bot_rocket/Destroy()
	QDEL_NULL(current_beam)
	return ..()

