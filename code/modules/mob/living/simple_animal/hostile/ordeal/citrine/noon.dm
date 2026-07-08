// Citrine Noon
/mob/living/simple_animal/hostile/ordeal/citrine/priest
	name = "Virtue"
	desc = "A small mechanical priest."
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "mechangel_priest"
	icon_living = "mechangel_priest"
	faction = list("citrine")
	health = 500
	maxHealth = 500
	melee_damage_type = WHITE_DAMAGE
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1.6, PALE_DAMAGE = 0.4)
	melee_damage_lower = 6
	melee_damage_upper = 10
	stat_attack = HARD_CRIT
	del_on_death = TRUE
	attack_verb_continuous = "whacks"
	attack_verb_simple = "whack"
	attack_sound = 'sound/weapons/fixer/generic/club3.ogg'
	speak_emote = list("sings")

	//They are supposed to run away.
	ranged = 1
	retreat_distance = 3
	minimum_distance = 3
	ranged_cooldown_time = 15
	move_to_delay = 4.6
	casingtype = /obj/item/ammo_casing/caseless/citrine_noon

	faith_per_lifetick = 2
	faith_line = "He is risen! Our prayers were answered!"
	var/can_say
	var/can_fire = TRUE

/mob/living/simple_animal/hostile/ordeal/citrine/priest/AttackingTarget(atom/attacked_target)
	//Priests exist to generate Faith primarily.
	if(!faith_active)
		return FALSE
	. = ..()

//The Virtues get attacks only after they fulfill their primary purpose of filling the faith bar
/mob/living/simple_animal/hostile/ordeal/citrine/priest/OpenFire(atom/A)
	if(!faith_active || !can_fire)
		return FALSE

	can_fire = FALSE //dont' want them rapidfiring

	var/list/holy_lines = list("BURN HERETIC!!", "PRAISE HIS NAME!!", "HELLFIRE UPON THEE!!")

	var/delay = 10
	say(pick(holy_lines))
	can_act = FALSE

	new /obj/effect/temp_visual/cult/turf (get_turf(target))
	SLEEP_CHECK_DEATH(delay)
	..()

	can_act = TRUE
	can_fire = TRUE

//Bullets
/obj/projectile/citrine_noon
	name = "flames"
	icon_state = "fireball"
	damage = 30
	damage_type = WHITE_DAMAGE
	white_healing = FALSE
	projectile_piercing = PASSMOB
	speed = 2
	ricochets_max = 2
	ricochet_chance = 100
	ricochet_decay_chance = 1
	ricochet_decay_damage = 1
	ricochet_auto_aim_range = 5
	ricochet_incidence_leeway = 0
	spread = 20

/obj/projectile/citrine_noon/check_ricochet_flag(atom/A)
	if(istype(A, /turf/closed))
		return TRUE
	if(istype(A, /obj/structure/window))
		return TRUE
	if(istype(A, /obj/machinery/door))
		return TRUE

	return FALSE

/obj/projectile/citrine_noon/on_hit(atom/target, blocked = FALSE)
	..()
	if(!ishuman(target))
		return
	var/mob/living/carbon/human/H = target
	H.adjust_fire_stacks(0.1)
	H.IgniteMob()

/obj/item/ammo_casing/caseless/citrine_noon
	name = "citrine casing"
	desc = "A casing."
	projectile_type = /obj/projectile/citrine_noon



//The Knights
/mob/living/simple_animal/hostile/ordeal/citrine/knight
	name = "Power"
	desc = "A floating monstrosity of silicon and steel."
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "mechangel_knight"
	icon_living = "mechangel_knight"
	faction = list("citrine")
	health = 1000
	maxHealth = 1000
	melee_damage_type = WHITE_DAMAGE
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.4, BLACK_DAMAGE = 1.6, PALE_DAMAGE = 1)
	melee_damage_lower = 20
	melee_damage_upper = 24
	stat_attack = HARD_CRIT
	del_on_death = TRUE
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_sound = 'sound/weapons/fixer/generic/blade1.ogg'
	speak_emote = list("sings")

	//They are slow but hurt in melee
	move_to_delay = 4

	faith_line = "Oh! He grants us strength!"

	//Lots of this is being used from Blue Shep, it's a similar melee-based unit with AOEs.
	var/slash_current = 4
	var/slash_cooldown = 4

	//Here's for the large slash
	var/cleave_width = 2
	var/cleave_length = 3
	var/cleave_damage = 40
	var/cleave_delay = 15
	var/cleave_pause = 5

	//This one is for the burn
	var/aoe_size = 2

	//This is for the empowerment.
	var/empowered = FALSE

	//How far does the fire go?
	var/fire_range = 4


/mob/living/simple_animal/hostile/ordeal/citrine/knight/AttackingTarget(atom/attacked_target)
	. = ..()
	//If you are insane, light on fire.
	if(!ishuman(target))
		return
	var/mob/living/carbon/human/H = target
	//You can also light them on fire if you are empowered, but that's rather rare.
	if(H.sanity_lost || empowered)
		H.adjust_fire_stacks(0.5)
		H.IgniteMob()


	slash_current-=1
	if(slash_current == 0)
		slash_current = slash_cooldown
		can_act = FALSE

		var/list/fire_lines = list("Burn!", "Sing, O flame!", "Perish, fool!")
		var/list/pray_lines = list("Give us this day...", "Praise your name...", "Sacrifice for you....")

		if(!faith_active)

			if(prob(10))
				say(pick(pray_lines))
				Pray()

			if(prob(30))
				say(pick(fire_lines))
				SLEEP_CHECK_DEATH(5)
				BurnAOE()

			else
				manual_emote("winds up...")
				playsound(H, 'sound/items/unsheath.ogg', 75, FALSE, 4)
				cleave(target)


		if(faith_active)
			switch(rand(1,4))
				if(1)
					say(pick(fire_lines))
					BurnAOE()
				if(2)
					if(empowered)
						can_act = TRUE
						return FALSE
					say("Empower my blade!")
					SLEEP_CHECK_DEATH(15)
					playsound(H, 'sound/effects/curseattack.ogg', 75, FALSE, 4)
					Empower()

				if(3)
					manual_emote("winds up...")
					playsound(H, 'sound/items/unsheath.ogg', 75, FALSE, 4)
					cleave(target)

				if(4)
					manual_emote("heats up...")
					SLEEP_CHECK_DEATH(15)
					BurnLine()

		can_act = TRUE


/mob/living/simple_animal/hostile/ordeal/citrine/knight/proc/Empower()
	addtimer(CALLBACK(src, PROC_REF(EndPower)), 10 SECONDS)

	//Buffs your slash
	cleave_damage = 60
	cleave_delay = 12
	cleave_pause = 5

	//And Fire AOE
	aoe_size = 4
	fire_range = 6

	//This is for the empowerment.
	empowered = TRUE

/mob/living/simple_animal/hostile/ordeal/citrine/knight/proc/EndPower()
	empowered = FALSE
	aoe_size = initial(aoe_size)
	cleave_damage = initial(cleave_damage)
	cleave_delay = initial(cleave_delay)
	cleave_pause = initial(cleave_pause)
	fire_range = initial(fire_range)



/mob/living/simple_animal/hostile/ordeal/citrine/knight/proc/BurnAOE()
	can_act = FALSE
	SLEEP_CHECK_DEATH(20)
	for(var/i = 1 to aoe_size)
		playsound(src, 'sound/effects/burn.ogg', 75, FALSE, 4)
		for(var/turf/T in range(i, src))
			if(T in range(i - 1, src))
				continue
			new /obj/effect/turf_fire/citrine(T)
		SLEEP_CHECK_DEATH(2)
	can_act = TRUE

/mob/living/simple_animal/hostile/ordeal/citrine/knight/proc/BurnLine()
	var/turf/T = get_ranged_target_turf_direct(src, target, fire_range)
	var/list/burn_turfs = getline(src, T) - get_turf(src)
	citrine_fire_line(src, burn_turfs, 15)

/mob/living/simple_animal/hostile/ordeal/citrine/knight/proc/cleave(target)
	if (get_dist(src, target) > 3)
		can_act = TRUE
		return

	//Turfs we will be hitting
	var/turf/area_of_effect = list()
	//We need 2 numbers. The lower left and the upper right of the square.
	//Lower Left
	var/offsetx1 = 0
	var/offsety1 = 0
	//Upper Right
	var/offsetx2 = 0
	var/offsety2 = 0
	//Give me where theoretically the center of the turf we would be hitting be.
	//Gimme a direction.
	var/dir_to_target = get_cardinal_dir(get_turf(src), get_turf(target))
	switch(dir_to_target)
		if(EAST)
			offsetx1 = 1
			offsety1 = -cleave_width
			offsetx2 = cleave_length
			offsety2 = cleave_width
		if(WEST)
			offsetx1 = -cleave_length
			offsety1 = -cleave_width
			offsetx2 = -1
			offsety2 = cleave_width
		if(SOUTH)
			offsetx1 = -cleave_width
			offsety1 = -cleave_length
			offsetx2 = cleave_width
			offsety2 = -1
		if(NORTH)
			offsetx1 = -cleave_width
			offsety1 = 1
			offsetx2 = cleave_width
			offsety2 = cleave_length
		else
			can_act = TRUE
			return

	//Give me ONLY the turfs between these cords
	area_of_effect = block(x+offsetx1,y+offsety1,z,x+offsetx2,y+offsety2)
	if (!LAZYLEN(area_of_effect))
		can_act = TRUE
		return
	dir = dir_to_target
	playsound(src, 'sound/weapons/etherealmiss.ogg', 100, FALSE, 4)
	SLEEP_CHECK_DEATH(cleave_delay)
	icon_state = icon_living
	var/list/been_hit = list()
	for(var/turf/T in area_of_effect)
		new /obj/effect/temp_visual/smash_effect(T)
		been_hit = HurtInTurf(T, been_hit, cleave_damage, WHITE_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))
	playsound(src, 'sound/weapons/slice.ogg', 75, FALSE, 4)
	SLEEP_CHECK_DEATH(cleave_pause)
	can_act = TRUE



/mob/living/simple_animal/hostile/ordeal/citrine/knight/proc/Pray()
	can_act = FALSE
	SLEEP_CHECK_DEATH(30)
	if(ordeal_reference)
		var/datum/ordeal/simplespawn/citrine/C = ordeal_reference
		C.current_faith += 5	//Get 5 Faith for praying.
	can_act = TRUE

