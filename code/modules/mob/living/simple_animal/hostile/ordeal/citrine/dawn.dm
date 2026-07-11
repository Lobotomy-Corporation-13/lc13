// Citrine Ordeals
/mob/living/simple_animal/hostile/ordeal/citrine/archer
	name = "Cherubim"
	desc = "A floating monstrosity of silicon and steel."
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "mechangel_face"
	icon_living = "mechangel_face"
	icon_dead = "mechangel_dead"
	is_flying_animal = TRUE
	faction = list("citrine")
	health = 100
	maxHealth = 100
	melee_damage_type = WHITE_DAMAGE
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 1.3, PALE_DAMAGE = 0.8)
	melee_damage_lower = 6
	melee_damage_upper = 10
	robust_searching = TRUE
	stat_attack = HARD_CRIT
	attack_verb_continuous = "punches"
	attack_verb_simple = "punches"
	attack_sound = 'sound/weapons/punch2.ogg'
	speak_emote = list("sings")
	ranged = 1
	retreat_distance = 3
	minimum_distance = 3
	ranged_cooldown_time = 15
	move_to_delay = 4.2
	casingtype = /obj/item/ammo_casing/caseless/citrine_dawn
	projectilesound = 'sound/weapons/bowfire.ogg'
	faith_per_lifetick = 1
	butcher_results = list(/obj/item/food/meat/slab/robot = 1)
	guaranteed_butcher_results = list(/obj/item/food/meat/slab/robot = 1)

	var/aoe_size = 2
	var/can_fire = TRUE

/mob/living/simple_animal/hostile/ordeal/citrine/archer/AttackingTarget(atom/attacked_target)

	var/gambling = rand(1,4)
	if(gambling < 4)
		return ..()

	if(faith_active)
		say("His light burns you!")
		aoe_size = 3
	else
		say("My flame will burn you!")

	can_act = FALSE
	SLEEP_CHECK_DEATH(20)
	for(var/i = 1 to aoe_size)
		playsound(src, 'sound/effects/burn.ogg', 75, FALSE, 4)
		for(var/turf/T in range(i, src))
			if(T in range(i - 1, src))
				continue
			new /obj/effect/turf_fire(T)
		SLEEP_CHECK_DEATH(2)
	can_act = TRUE

	return FALSE

/mob/living/simple_animal/hostile/ordeal/citrine/archer/OpenFire(atom/A)
	if(!can_fire)
		return FALSE
	can_fire = FALSE //dont' want them rapidfiring

	playsound(src, 'sound/weapons/bowdraw.ogg', 40, FALSE, 8)
	var/list/normal_lines = list("In my sights!", "Ready to fire!", "Aiming at target!")
	var/list/holy_lines = list("He guides my aim!", "Holy arrows of light!", "My arrow will pierce your soul!")

	var/delay = 12
	if(faith_active)
		delay = 7
		say(pick(holy_lines))
	else
		say(pick(normal_lines))
	can_act = FALSE

	new /obj/effect/temp_visual/cult/turf/floor (get_turf(target))
	SLEEP_CHECK_DEATH(delay)
	..()

	can_act = TRUE
	can_fire = TRUE

//Bullets
/obj/projectile/citrine_dawn
	name = "holy bolt act I"
	icon_state = "chronobolt"
	desc = "a holy arrow."
	speed = 1
	damage = 20		//It deals a bit of damage
	damage_type = WHITE_DAMAGE
	white_healing = FALSE
	var/faith_active = FALSE

/obj/projectile/citrine_dawn/on_hit(atom/target, blocked = FALSE)
	..()
	if(!ishuman(target))
		return
	var/mob/living/carbon/human/H = target
	if(H.sanity_lost || faith_active)
		H.adjust_fire_stacks(0.1)
		H.IgniteMob()

/obj/item/ammo_casing/caseless/citrine_dawn
	name = "citrine casing"
	desc = "A casing."
	projectile_type = /obj/projectile/citrine_dawn
