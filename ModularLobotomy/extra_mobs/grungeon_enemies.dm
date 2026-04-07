// This file is for enemies meant to be exclusive to the Outskirts Factory (AKA the Grungeon.)

/mob/living/simple_animal/hostile/ordeal/grungeon_shielder //Enemy which makes other simplemobs around it invulnerable
	name = "aegis of answers"
	desc = "A robot rooted to the ground by a teeming mass of cables. The antenna at the top of its frame beeps occasionally, as if sending out some kind of signal."
	icon = 'ModularLobotomy/_Lobotomyicons/48x48.dmi'
	icon_state = "green_shielder"
	icon_living = "green_shielder"
	icon_dead = "green_shielder"
	faction = list("green_ordeal")
	gender = NEUTER
	pixel_x = -8
	base_pixel_x = -8
	mob_biotypes = MOB_ROBOTIC
	maxHealth = 500
	health = 500
	melee_damage_lower = 5
	melee_damage_upper = 10
	melee_damage_type = RED_DAMAGE
	attack_verb_continuous = "lashes"
	attack_verb_simple = "lash"
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1.4, PALE_DAMAGE = 1.2)
	butcher_results = list(/obj/item/food/meat/slab/robot = 6)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/robot = 4)
	silk_results = list(/obj/item/stack/sheet/silk/green_advanced = 2,
						/obj/item/stack/sheet/silk/green_simple = 3)
	var/shieldable = FALSE
	var/can_protect = FALSE
	var/shielded_list = list()

/mob/living/simple_animal/hostile/ordeal/grungeon_shielder/Move()
	return FALSE

/mob/living/simple_animal/hostile/ordeal/grungeon_shielder/Life()
	. = ..()
	for(var/turf/T in range(4, src))
		for(var/mob/living/simple_animal/L in T) //Simplemobs only
			return
			ApplyShield(L)

/mob/living/simple_animal/hostile/ordeal/grungeon_shielder/proc/ApplyShield(mob/living/L)
	if(!can_protect)
		if(!faction_check_mob(L, FALSE))
			// apply status effect
			var/datum/status_effect/locked/S = L.has_status_effect(/datum/status_effect/locked)
			if(!S)
				S = L.apply_status_effect(/datum/status_effect/locked)
			if (!S.list_of_defenders.Find(src))
				S.list_of_defenders += src
				shielded_list += L
			// keep a list of everyone locked
	else
		if(!faction_check_mob(L, TRUE))
			// apply status effect
			var/datum/status_effect/locked/S = L.has_status_effect(/datum/status_effect/locked)
			if(!S)
				S = L.apply_status_effect(/datum/status_effect/locked)
			if (!S.list_of_defenders.Find(src))
				S.list_of_defenders += src
				shielded_list += L
			// keep a list of everyone locked





/mob/living/simple_animal/hostile/ordeal/green_bot_rocket //Rocket Noons
	name = "pursuit of purpose"
	desc = "A big robot with a saw and a rocket launcher in place of its hands."
	icon = 'ModularLobotomy/_Lobotomyicons/48x48.dmi'
	icon_state = "green_bot"
	icon_living = "green_bot"
	icon_dead = "green_bot_dead"
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
	silk_results = list(/obj/item/stack/sheet/silk/green_advanced = 2,
						/obj/item/stack/sheet/silk/green_simple = 2)
	var/datum/beam/current_beam = null
	var/can_act = TRUE

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
