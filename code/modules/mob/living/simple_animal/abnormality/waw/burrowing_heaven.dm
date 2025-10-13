/mob/living/simple_animal/hostile/abnormality/burrowing_heaven
	name = "Burrowing Heaven"
	desc = "A big red and bloody tree."
	icon = 'ModularLobotomy/_Lobotomyicons/96x96.dmi'
	icon_state = "heaven"
	icon_living = "heaven"
	portrait = "heaven"

	pixel_x = -32
	base_pixel_x = -32

	maxHealth = 2000
	health = 2000
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 1.5)

	threat_level = WAW_LEVEL
	can_breach = TRUE
	can_patrol = FALSE
	start_qliphoth = 3
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 0,
		ABNORMALITY_WORK_INSIGHT = list(0, 0, 35, 40, 45),
		ABNORMALITY_WORK_ATTACHMENT = list(50, 50, 50, 55, 55),
		ABNORMALITY_WORK_REPRESSION = list(0, 0, 45, 50, 55),
	)
	work_damage_amount = 10
	work_damage_type = BLACK_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/pride


	ego_list = list(
		/datum/ego_datum/weapon/heaven,
		/datum/ego_datum/armor/heaven,
	)
	//gift_type = /datum/ego_gifts/heaven
	abnormality_origin = ABNORMALITY_ORIGIN_LOBOTOMY
	var/seen
	var/list/spawn_list = list()

//Sight Check
/mob/living/simple_animal/hostile/abnormality/burrowing_heaven/Life()
	. = ..()
	//Who is watching us
	var/people_watching
	for(var/mob/living/carbon/human/L in viewers(world.view + 1, src))
		if(L.client && CanAttack(L) && L.stat != DEAD)
			if(!L.is_blind())
				people_watching+=1

	if(people_watching == 1)
		seen = FALSE
	else	//any amount of people that's not 1.
		seen = TRUE

/mob/living/simple_animal/hostile/abnormality/burrowing_heaven/death()
	..()
	for(var/mob/living/simple_animal/A in spawn_list)
		qdel(A)

//You can't traditionally move nor can you attack
/mob/living/simple_animal/hostile/abnormality/burrowing_heaven/Move()
	return FALSE

/mob/living/simple_animal/hostile/abnormality/burrowing_heaven/AttackingTarget()
	return FALSE

/mob/living/simple_animal/hostile/abnormality/burrowing_heaven/NeutralEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(15))
		datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/burrowing_heaven/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(80))
		datum_reference.qliphoth_change(-1)
	return

//Work stuff
/mob/living/simple_animal/hostile/abnormality/burrowing_heaven/Worktick(mob/living/carbon/human/user, work_type)
	. = ..()
	if(!seen) //You need two people to work this abno without taking damage.
		to_chat(user, span_warning("You are injured by [src]!")) // Keeping it clear that the bad work is from being seen and not just luck.
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(user), pick(GLOB.alldirs))
		user.apply_damage(5, BLACK_DAMAGE, null, user.run_armor_check(null, RED_DAMAGE), spread_damage = TRUE)

/mob/living/simple_animal/hostile/abnormality/burrowing_heaven/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	icon_living = "heaven_breach"
	icon_state = icon_living
	addtimer(CALLBACK(src, PROC_REF(TryTeleport)), 15 SECONDS)

/mob/living/simple_animal/hostile/abnormality/burrowing_heaven/proc/TryTeleport()
	spawn_list = list()
	if(prob(10))	//The most rare one
		Spawn_Babies()
		return

	var/list/living_players = list()
	var/list/breached_abnos = list()
	//Grab players
	for(var/mob/living/carbon/human/L in GLOB.player_list)
		if(L.z != z || L.stat == DEAD)
			continue
		living_players +=L
	//Grab abnos.
	for(var/mob/living/simple_animal/hostile/abnormality/L in GLOB.mob_list)
		if(L.z != z || L.IsContained())
			continue
		if(L == src)
			continue
		breached_abnos += L

	//Everyone is dead and no abno breached
	if(!length(living_players) && !length(breached_abnos))
		emote("twitches.")	//Do this bit of flavor
		return

	//If there's breached abnos, support them
	if(length(breached_abnos) && prob(50))
		var/mob/living/simple_animal/hostile/abnormality/picked_abnormality = pick(breached_abnos)
		Abno_Teleport(picked_abnormality)
		return

	//Otherwise hit a player.
	if(length(living_players))
		var/mob/living/carbon/human/picked_player = pick(living_players)
		Player_Teleport(picked_player)
		return

	//Fallback.
	addtimer(CALLBACK(src, PROC_REF(TryTeleport)), 15 SECONDS)


//The Abno targeting one. Give 1 abno a 10 second speed boost
/mob/living/simple_animal/hostile/abnormality/burrowing_heaven/proc/Abno_Teleport(mob/living/simple_animal/hostile/abnormality/target_abno)
	addtimer(CALLBACK(src, PROC_REF(TryTeleport)), 15 SECONDS)
	animate(src, alpha = 0, time = 5)
	var/turf/orgin = get_turf(target_abno)
	var/list/all_turfs = RANGE_TURFS(1, orgin)
	var/turf/T = pick(all_turfs)

	SLEEP_CHECK_DEATH(20)
	forceMove(T)
	animate(src, alpha = 255, time = 5)
	target_abno.TemporarySpeedChange(-1, 10 SECONDS)



//The player targeted kill
/mob/living/simple_animal/hostile/abnormality/burrowing_heaven/proc/Player_Teleport(mob/living/carbon/human/targeted_human)
	addtimer(CALLBACK(src, PROC_REF(TryTeleport)), 15 SECONDS)
	animate(src, alpha = 0, time = 5)
	var/turf/orgin = get_turf(targeted_human)
	var/list/all_turfs = RANGE_TURFS(1, orgin)
	for(var/turf/T in all_turfs)
		new /obj/effect/temp_visual/burrowing_warning (T)
	SLEEP_CHECK_DEATH(20)

	//Teleport there and gib everyone on the tile.
	forceMove(orgin)
	animate(src, alpha = 255, time = 5)
	playsound(src, 'sound/abnormalities/kog/GreedHit1.ogg',  75, 1)
	for(var/turf/T in all_turfs)
		for(var/mob/living/carbon/human/H in T.contents)
			H.gib()

/obj/effect/temp_visual/burrowing_warning
	duration = 20
	gender = PLURAL
	name = "warning"
	desc = "a warning."
	icon = 'icons/effects/cult_effects.dmi'
	icon_state = "shield-cult"
	anchored = TRUE
	layer = TURF_LAYER
	plane = FLOOR_PLANE
	base_icon_state = "shield-cult"



//The Ruina Breach
/mob/living/simple_animal/hostile/abnormality/burrowing_heaven/proc/Spawn_Babies()
	addtimer(CALLBACK(src, PROC_REF(CheckAOE)), 40 SECONDS)	//40 seconds before the global AOE

	//move to a main room
	animate(src, alpha = 0, time = 5)
	var/turf/T = pick(GLOB.department_centers)
	SLEEP_CHECK_DEATH(20)

	forceMove(T)
	animate(src, alpha = 255, time = 5)
	var/turf/orgin = get_turf(src)
	var/list/all_turfs = RANGE_TURFS(3, orgin)
	for(var/i in 1 to 3)
		var/turf/spawn_spot = pick(all_turfs)
		var/mob/living/simple_animal/hostile/burrowing_spawn/BS = new get_turf(spawn_spot)
		spawn_list += BS

/mob/living/simple_animal/hostile/abnormality/burrowing_heaven/proc/CheckAOE()
	var/aoe = 0
	for(var/mob/living/simple_animal/A in spawn_list)
		if(A && A.stat != DEAD)    //If any of them are alive, fuck them
			aoe ++
		qdel(A)
	if(aoe)
		SpawnAOE(aoe)

/mob/living/simple_animal/hostile/abnormality/burrowing_heaven/proc/SpawnAOE(aoe)
	for(var/mob/living/L in GLOB.alive_mob_list)	//hit everything on the Z level
		if(L.z != z)
			continue
		if(faction_check_mob(L))
			continue
		L.deal_damage(40*aoe, BLACK_DAMAGE)

	addtimer(CALLBACK(src, PROC_REF(TryTeleport)), 5 SECONDS)


/* Burrowing Spawn */
/mob/living/simple_animal/hostile/burrowing_spawn
	name = "burrowing spawn"
	desc = "A little spawn of burrowing heaven."
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "burrowingheaven_minion"
	icon_living = "burrowingheaven_minion"
	health = 450
	maxHealth = 450
	melee_damage_type = RED_DAMAGE
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 0, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 1.5)
	obj_damage = 200
	stat_attack = HARD_CRIT
	del_on_death = TRUE


/mob/living/simple_animal/hostile/burrowing_spawn/Move()
	return FALSE

/mob/living/simple_animal/hostile/burrowing_spawn/AttackingTarget()
	return FALSE

