/mob/living/simple_animal/hostile/Titania
	name = "Titania"
	desc = "The Queen of Fairies, empowered by a Golden Bough. This wont be an easy fight."
	icon = 'ModularLobotomy/_Lobotomyicons/32x64.dmi'
	icon_state = "titania"
	icon_living = "titania"
	maxHealth = 4000
	health = 4000
	gender = FEMALE
	is_flying_animal = TRUE
	move_to_delay = 4
	melee_damage_lower = 70
	melee_damage_upper = 78
	melee_damage_type = RED_DAMAGE
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 0.3, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 1)
	stat_attack = HARD_CRIT
	faction = ("Fairy")

	var/fairy_spawn_number = 2
	var/fairy_spawn_time = 5 SECONDS
	var/fairy_spawn_limit = 30
	var/list/spawned_mobs = list()

//Laws
	var/list/laws = list("melee", "ranged", "fairy", "armor", "ranged fairy")
	var/currentlaw
	var/nextlaw
	var/law_damage = 30
	var/law_timer = 60 SECONDS
	var/law_startup = 3 SECONDS

/mob/living/simple_animal/hostile/Titania/Life()
	if(prob(30))
		var/mob/living/getting_shelled
		var/list/players_near = list()

		for(var/mob/living/carbon/human/H in view(5, src))
			players_near |= H

		//Got no players :(
		if(!length(players_near))
			return
		getting_shelled = pick(players_near)

		switch(rand(1,2))
			if(1)
				new /obj/effect/titania_aoe(get_turf(getting_shelled))

			if(2)
				for(var/i in 1 to 3)//Make them start to run
					new /obj/effect/titania_small(get_turf(getting_shelled))
					SLEEP_CHECK_DEATH(2)

				SLEEP_CHECK_DEATH(7)

				for(var/i in 1 to 5)//Then make them suffer
					new /obj/effect/titania_small(get_turf(getting_shelled))
					SLEEP_CHECK_DEATH(2)

/mob/living/simple_animal/hostile/Titania/Destroy()
	UnregisterAll()
	new /obj/structure/bough/mining (get_turf(src))
	return ..()

/mob/living/simple_animal/hostile/Titania/AttackingTarget(atom/attacked_target)
	var/mob/living/carbon/human/H = attacked_target
	//Kills the weak immediately.
	if(ishuman(H) && get_user_level(H) < 3)
		say("I rid you of your pain, mere human.")
		//Double Check
		SpawnFairies(fairy_spawn_number * 2, H, ignore_cap = TRUE)
		H.gib()
		return

/mob/living/simple_animal/hostile/Titania/proc/FairyLoop()
	if(IsCombatMap())
		return
	SpawnFairies(fairy_spawn_number)
	addtimer(CALLBACK(src, PROC_REF(FairyLoop)), fairy_spawn_time)

/mob/living/simple_animal/hostile/Titania/proc/SpawnFairies(amount, mob/turf_mob, ignore_cap = FALSE)
	if(!ignore_cap && (length(spawned_mobs) > fairy_spawn_limit))
		return

	var/turf/spawn_turf
	if(turf_mob)
		spawn_turf = get_turf(turf_mob)
	else
		spawn_turf = get_turf(src)

	for(var/i in 1 to amount)
		var/mob/living/simple_animal/hostile/Titania/Fairyswarm/fairy = new(spawn_turf)
		fairy.faction = faction
		RegisterMob(fairy)

//Cleaning fairies
/mob/living/simple_animal/hostile/Titania/death(gibbed)
	for(var/mob/living/A in spawned_mobs)
		A.death()
	return ..()

/mob/living/simple_animal/hostile/Titania/proc/SetLaw()
	if(IsCombatMap())
		return

	var/lawmessage
	nextlaw = pick(laws.Copy() - currentlaw)

	switch(nextlaw)
		if("melee")
			lawmessage = "Thou shalt not hit thy queen with melee attacks."
		if("ranged")
			lawmessage = "Thou shalt not hit thy queen with ranged attacks."
		if("fairy")
			lawmessage = "Mine fairies are now heartier."
		if("armor")
			lawmessage = "Thy queen shalt not be hurt by red damage."
		if("ranged fairy")
			lawmessage = "Mine fairies will come to my aid if you strike me with ranged attacks."

	for(var/mob/living/carbon/human/H in view(20, src))
		to_chat(H, span_colossus("[lawmessage]"))
	addtimer(CALLBACK(src, PROC_REF(ActivateLaw)), law_startup)	//Start Law 3 Seconds


/mob/living/simple_animal/hostile/Titania/proc/ActivateLaw()
	addtimer(CALLBACK(src, PROC_REF(SetLaw)), law_timer)	//Set Laws in 30 Seconds
	currentlaw = nextlaw
	for(var/mob/living/carbon/human/L in view(20, src))
		to_chat(L, span_danger("The new law is now in effect."))

	if(currentlaw == "fairies")
		for(var/mob/living/simple_animal/L in spawned_mobs)
			L.ChangeResistances(list(RED_DAMAGE = 0.2, WHITE_DAMAGE = 0.2, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 1))
	else
		for(var/mob/living/simple_animal/L in spawned_mobs)
			L.ChangeResistances(list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1))


/mob/living/simple_animal/hostile/Titania/proc/Punishment(mob/living/sinner)
	to_chat(sinner, span_userdanger("You are hurt due to breaking Fairy Law."))
	sinner.deal_damage(law_damage, PALE_DAMAGE, src, flags = (DAMAGE_FORCED | DAMAGE_UNTRACKABLE), attack_type = (ATTACK_TYPE_SPECIAL))
	new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(sinner), pick(GLOB.alldirs))

//Ranged stuff
/mob/living/simple_animal/hostile/Titania/bullet_act(obj/projectile/Proj)
	..()

	if(!ishuman(Proj.firer))
		return

	var/mob/living/carbon/human/H = Proj.firer

	if(currentlaw == "ranged")
		Punishment(Proj.firer)
		H.apply_lc_feeble(5)

	if(currentlaw == "armor" && Proj.damage_type == RED_DAMAGE)
		Punishment(Proj.firer)

	if(currentlaw == "ranged fairy")
		SpawnFairies(1)

//Melee stuff
/mob/living/simple_animal/hostile/Titania/attacked_by(obj/item/I, mob/living/user)
	..()

	if(!user)
		return

	if(currentlaw == "melee")
		Punishment(user)
		user.apply_lc_feeble(5)

	if(currentlaw == "armor" && I.damtype == RED_DAMAGE && I.force >= 10)
		Punishment(user)

/mob/living/simple_animal/hostile/Titania/proc/RegisterMob(mob/living/L)
	RegisterSignal(L, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING), PROC_REF(UnregisterMob))
	spawned_mobs += L

/mob/living/simple_animal/hostile/Titania/proc/UnregisterMob(mob/living/L)
	UnregisterSignal(L, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
	spawned_mobs -= L

/mob/living/simple_animal/hostile/Titania/proc/UnregisterAll()
	for(var/mob/living/L in spawned_mobs)
		UnregisterMob(L)
		qdel(L)
	spawned_mobs.Cut()


/mob/living/simple_animal/hostile/Titania/Fairy
	name = "fairy"
	desc = "A tiny, extremely hungry fairy."
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "fairyswarm"
	icon_living = "fairyswarm"
	pass_flags = PASSTABLE | PASSMOB
	is_flying_animal = TRUE
	density = FALSE
	a_intent = INTENT_HARM
	health = 100
	maxHealth = 100
	melee_damage_lower = 5
	melee_damage_upper = 10
	melee_damage_type = RED_DAMAGE
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	attack_verb_continuous = "cuts"
	attack_verb_simple = "cut"
	attack_sound = 'sound/weapons/bladeslice.ogg'
	mob_size = MOB_SIZE_TINY
	del_on_death = TRUE

/mob/living/simple_animal/hostile/Titania/Fairyswarm/Initialize()
	. = ..()
	pixel_x = rand(-16, 16)
	pixel_y = rand(-16, 16)

/mob/living/simple_animal/hostile/Titania/Fairy/AttackingTarget(atom/attacked_target)
	..()
	if(ishuman(attacked_target))
		var/mob/living/carbon/human/H = attacked_target
		H.apply_lc_white_fragile(1)
		H.apply_lc_red_fragile(1)


/mob/living/simple_animal/hostile/Titania/Corroded
// 2 tile AOE, heals /titania mobs in range, icon files included
// For the 2 tile AOE look at ModularLobotomy/rcorp/rcorp_abnos/easyfaction/easycombat/blue_shepard.dm
// for the healing look at /mob/living/simple_animal/hostile/abnormality/eris/proc/healpulse() in code/modules/mob/living/simple_animal/abnormality/he/eris.dm
	name = 'Corroded' //todo confirm if this is correct or not please thanks
	desc = "heals around itself or something idk" //todo hi i dont know what it is so i cant write this
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "fairy_mass"
	icon_living = "fairy_mass"
	icon_dead = "fairy_mass_dead"
	faction = ("Fairy")
	last_heal = 0
	heal_cd = 10 SECONDS
	heal_amount = 25
/mob/living/simple_animal/hostile/Titania/Corroded/Initialize()
	. = ..()
	pixel_x = rand(-16, 16)
	pixel_y = rand(-16, 16)

/mob/living/simple_animal/hostile/Titania/Corroded/Life()
	..()
	healbomb()

/mob/living/simple_animal/hostile/Titania/Corroded/proc/healbomb()
	if(world.time > last_heal + heal_cd)
		last_heal = world.time
		for(var/mob/living/simple_animal/hostile/Titania/T in view(2, src))
			T.adjustBruteLoss(-heal_amount)
			new /obj/effect/temp_visual/heal(get_turf(T), "#FF4444")
