//In tank category because she has artillery and has decent resists + health
/mob/living/simple_animal/hostile/rcorp_abno/hard/titania
	name = "Titania"
	desc = "A gargantuan fairy. Her stare seems prideful when staring at the weak, best not approach if you are among them."
	maxHealth = 3500
	health = 3500
	is_flying_animal = TRUE
	move_to_delay = 4
	melee_damage_lower = 70
	melee_damage_upper = 78		//Will never one shot you.
	melee_damage_type = RED_DAMAGE
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 0.3, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 1)
	original_abno = /mob/living/simple_animal/hostile/abnormality/titania

	var/fairy_spawn_number = 2
	//Fairy spawn limit only matters for the spawn loop, players she kills and spawned via the law don't count
	var/list/spawned_mobs = list()

	abno_additional_instructions = "<h1>You are Titania, A Tank Role Abnormality.</h1><br>\
		<b>|Wingbeat|: As a fairy you may use your wings to fly over ground terrain such as chasms or water. <br>\
		<br>\
		|Fairy Queen|: When attacking a human below level 4, you will rid them of their pain. \
		This action will instantly kill the human, if done on a corpse it will destroy the body. \
		Upon using this on a human you will create 2 |Fairy Swarm|. \
		If killed all |Fairy Swarm| you have created will disappear along with you. <br>\
		<br>\
		|Fairy Law|: Every Lifetick you have a 30% chance to decree the fairies attack. \
		This attack has 2 variants with a equal chance to be picked. \
		The first variant will create one large 5x5 AoE on the tile of your target dealing 60 WHITE. \
		The second variant will create a quick succession of 1x1 attacks that will track targets, dealing 40 WHITE and applying 3 |White Fragility|. <br>\
		<br>\
		|White Fragility|: Raises WHITE damage taken by 10% per stack. <br>\
		<br>\
		|Fairy Swarm|: Individually weak fairies that deal minimal damage. \
		When attacking a human these fairies will apply 2 |White Fragility|. \
		Due to their small nature these fairies may fly over tables and through people. \
		Fairies are not hit by projectiles unless their sprite is directly clicked by the shooter. </b>"

/mob/living/simple_animal/hostile/rcorp_abno/hard/titania/Life()
	if(prob(30))
		var/mob/living/getting_shelled
		var/list/players_near = list()

		for(var/mob/living/carbon/human/H in view(5, src))
			if(H.stat == DEAD)
				continue
			if(H.sanity_lost)
				continue
			if(faction_check_mob(H))
				continue
			players_near |= H

		//Got no players :(
		if(!length(players_near))
			return
		getting_shelled = pick(players_near)

		switch(rand(1,2))
			if(1)
				new /obj/effect/rca_titania_aoe(get_turf(getting_shelled))

			if(2)
				for(var/i in 1 to 3)//Make them start to run
					new /obj/effect/rca_titania_small(get_turf(getting_shelled))
					SLEEP_CHECK_DEATH(2)

				SLEEP_CHECK_DEATH(7)

				for(var/i in 1 to 5)//Then make them suffer
					new /obj/effect/rca_titania_small(get_turf(getting_shelled))
					SLEEP_CHECK_DEATH(2)

//Clear all fairies
/mob/living/simple_animal/hostile/rcorp_abno/hard/titania/Destroy()
	UnregisterAll()
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/titania/proc/SpawnFairies(amount, mob/turf_mob)
	var/turf/spawn_turf
	if(turf_mob)
		spawn_turf = get_turf(turf_mob)
	else
		spawn_turf = get_turf(src)

	for(var/i in 1 to amount)
		var/mob/living/simple_animal/hostile/rca_fairyswarm/fairy = new(spawn_turf)
		fairy.faction = faction
		RegisterMob(fairy)

//Cleaning fairies
/mob/living/simple_animal/hostile/rcorp_abno/hard/titania/death(gibbed)
	for(var/mob/living/A in spawned_mobs)
		A.death()
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/titania/proc/RegisterMob(mob/living/L)
	RegisterSignal(L, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING), PROC_REF(UnregisterMob))
	spawned_mobs += L

/mob/living/simple_animal/hostile/rcorp_abno/hard/titania/proc/UnregisterMob(mob/living/L)
	UnregisterSignal(L, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	spawned_mobs -= L

/mob/living/simple_animal/hostile/rcorp_abno/hard/titania/proc/UnregisterAll()
	for(var/mob/living/L in spawned_mobs)
		UnregisterMob(L)
		qdel(L)
	spawned_mobs.Cut()

//The Big attacks
/obj/effect/rca_titania_aoe
	name = "titania warning"
	desc = "A target warning you of incoming pain"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "warning_gray"
	move_force = INFINITY
	pull_force = INFINITY
	pixel_x = -32
	pixel_y = -32
	generic_canpass = FALSE
	movement_type = PHASING | FLYING
	var/boom_damage = 60 //Just white.
	var/lifetime = 2 SECONDS
	var/list/faction = list("hostile")
	layer = POINT_LAYER	//We want this HIGH. SUPER HIGH. We want it so that you can absolutely, guaranteed, see exactly what is about to hit you.

/obj/effect/rca_titania_aoe/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(explode)), lifetime)

/obj/effect/rca_titania_aoe/proc/explode()
	playsound(get_turf(src), 'sound/magic/magic_missile.ogg', 50, 0, 8)
	for(var/turf/T in range(2, src))
		new /obj/effect/temp_visual/pale_eye_attack(T)
	for(var/mob/living/L in view(2, src))
		if(faction_check(L.faction, src.faction))
			continue
		L.deal_damage(boom_damage, WHITE_DAMAGE, src, flags = (DAMAGE_FORCED | DAMAGE_UNTRACKABLE), attack_type = (ATTACK_TYPE_SPECIAL))
	qdel(src)

//AOE
/obj/effect/rca_titania_small
	name = "titania warning"
	desc = "A target warning you of incoming pain"
	icon = 'icons/effects/effects.dmi'
	icon_state = "tbird_bolt"
	move_force = INFINITY
	pull_force = INFINITY
	generic_canpass = FALSE
	movement_type = PHASING | FLYING
	var/boom_damage = 40 //Applies fragile
	var/lifetime = 1.2 SECONDS
	var/list/faction = list("hostile")
	layer = POINT_LAYER	//We want this HIGH. SUPER HIGH. We want it so that you can absolutely, guaranteed, see exactly what is about to hit you.

/obj/effect/rca_titania_small/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(explode)), lifetime)

/obj/effect/rca_titania_small/proc/explode()
	playsound(get_turf(src), 'sound/magic/blind.ogg', 50, 0, 8)
	new /obj/effect/temp_visual/pale_eye_attack(get_turf(src))
	for(var/mob/living/L in get_turf(src))
		if(faction_check(L.faction, src.faction))
			continue
		L.deal_damage(boom_damage, WHITE_DAMAGE, src, flags = (DAMAGE_FORCED | DAMAGE_UNTRACKABLE), attack_type = (ATTACK_TYPE_SPECIAL))
		L.apply_lc_white_fragile(3)
	qdel(src)

//The Mini fairies
/mob/living/simple_animal/hostile/rca_fairyswarm
	name = "fairy"
	desc = "A tiny, extremely hungry fairy. Incredibly hard to hit and leave your mind aching."
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "fairyswarm"
	icon_living = "fairyswarm"
	pass_flags = PASSTABLE | PASSMOB
	is_flying_animal = TRUE
	density = FALSE
	a_intent = INTENT_HARM
	health = 80
	maxHealth = 80
	melee_damage_lower = 3
	melee_damage_upper = 5	//They apply fragile
	melee_damage_type = RED_DAMAGE
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	attack_verb_continuous = "cuts"
	attack_verb_simple = "cut"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	mob_size = MOB_SIZE_TINY
	del_on_death = TRUE

/mob/living/simple_animal/hostile/rca_fairyswarm/Login()
	. = ..()
	to_chat(src, "<h1>You are a Fairy, A Titania Minion.</h1><br>\
		<b>|Wingbeat|: As a fairy you may use your wings to fly over ground terrain such as chasms or water. <br>\
		<br>\
		|Fairy Swarm|: You are individually weak and deal minimal damage. \
		When attacking a human you will apply 2 |White Fragility|. \
		Due to your small nature you may fly over tables and through people. \
		You are not hit by projectiles unless your sprite is directly clicked by the shooter. <br>\
		<br>\
		|White Fragility|: Raises WHITE damage taken by 10% per stack. <br>\
		<br>\
		|Queens Retinue|: If Titania is killed you will die in the absence of your queen. </b>")

/mob/living/simple_animal/hostile/rca_fairyswarm/Initialize()
	. = ..()
	pixel_x = rand(-16, 16)
	pixel_y = rand(-16, 16)

/mob/living/simple_animal/hostile/rca_fairyswarm/AttackingTarget(atom/attacked_target)
	..()
	if(ishuman(attacked_target))
		var/mob/living/carbon/human/H = attacked_target
		H.apply_lc_white_fragile(2)
