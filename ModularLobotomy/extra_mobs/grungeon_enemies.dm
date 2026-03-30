// This file is for enemies meant to be exclusive to the Outskirts Factory (AKA the Grungeon.)

/mob/living/simple_animal/hostile/ordeal/grungeon_shielder //Enemy which makes other simplemobs around it invulnerable
	name = "aegis of answers"
	desc = "A robot rooted to the ground by a teeming mass of cables. The antenna at the top of its frame beeps occasionally, as if sending out some kind of signal."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "grungeon_shielder"
	icon_living = "grungeon_shielder"
	icon_dead = "grungeon_shielder"
	faction = list("green_ordeal")
	gender = NEUTER
	mob_biotypes = MOB_ROBOTIC
	maxHealth = 1000
	health = 1000
	melee_damage_lower = 0
	melee_damage_upper = 0
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1.4, PALE_DAMAGE = 1.2)
	butcher_results = list(/obj/item/food/meat/slab/robot = 6)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/robot = 4)
	silk_results = list(/obj/item/stack/sheet/silk/green_advanced = 2,
						/obj/item/stack/sheet/silk/green_simple = 3)









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
	projectiletype = /obj/projectile/ego_bullet/ego_match
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
	current_beam = Beam(A, icon_state="blood", time = .7 SECONDS)
	can_act = FALSE
	SLEEP_CHECK_DEATH(8)
	if(!(A in view(9, src)))
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
