//A Pink midnight

/mob/living/simple_animal/hostile/ordeal/pink_midnight
	name = "A Party Everlasting"
	desc = "An overturned teacup, a party everlasting."
	icon = 'ModularLobotomy/_Lobotomyicons/64x96.dmi'
	icon_state = "party"
	icon_living = "party"
	faction = list("pink_midnight")
	layer = LARGE_MOB_LAYER
	pixel_x = -16
	base_pixel_x = -16
	maxHealth = 4000
	health = 4000
	melee_damage_type = PALE_DAMAGE
	rapid_melee = 2
	melee_damage_lower = 14
	melee_damage_upper = 14
	attack_verb_continuous = "bashes"
	attack_verb_simple = "bashes"
	attack_sound = 'sound/weapons/teasmack.ogg'
	ranged = 1
	ranged_cooldown_time = 40

	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 0.3, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 0.3)

	var/list/blacklist = list(
				/mob/living/simple_animal/hostile/abnormality/melting_love,
				/mob/living/simple_animal/hostile/abnormality/distortedform,
				/mob/living/simple_animal/hostile/abnormality/white_night,
				/mob/living/simple_animal/hostile/abnormality/nihil,
				/mob/living/simple_animal/hostile/abnormality/hatred_queen,
				/mob/living/simple_animal/hostile/abnormality/wrath_servant,
				/mob/living/simple_animal/hostile/abnormality/highway_devotee,
				)
	can_act = TRUE
	var/counter	//Are you countering
	var/bullet_riccochet //are you repelling bullets rn?
	var/can_move = TRUE
	var/aoe_damage = 100
	var/list/fire_turfs = list()


/mob/living/simple_animal/hostile/ordeal/pink_midnight/AttackingTarget(atom/attacked_target)
	var/gambling = rand(1,4)
	if(gambling < 4)
		return ..()
	if(prob(50))
		playsound(get_turf(src), 'sound/magic/summonitems_generic.ogg', 50, 0, 8)
		CounterMode()
		return
	OpenFire(attacked_target)


/mob/living/simple_animal/hostile/ordeal/pink_midnight/OpenFire(atom/A)
	if(!can_act)
		return
	switch(rand(1,3))
		if(1)
			playsound(get_turf(src), 'sound/magic/magic_missile.ogg', 50, 0, 8)
			BulletReflect()

		if(2)
			WhiteAOE(4)

		if(3)
			new /obj/effect/temp_visual/voidout(get_turf(src))
			playsound(get_turf(src), 'sound/magic/demon_dies.ogg', 50, 0, 8)
			PaleAOE()

//The Attacks Below

//Both Counters use the same Endcounter.
/mob/living/simple_animal/hostile/ordeal/pink_midnight/proc/BulletReflect()
	bullet_riccochet = TRUE
	can_move = FALSE
	can_act = FALSE
	color = "#0000FF"	//Go blue so you are good
	addtimer(CALLBACK(src, PROC_REF(EndCounter)), 3 SECONDS)

	fire_turfs = RANGE_TURFS(7, src)


/mob/living/simple_animal/hostile/ordeal/pink_midnight/proc/CounterMode()
	counter = TRUE
	can_move = FALSE
	can_act = FALSE
	color = "#FF0000"	//Go red so you are evil
	addtimer(CALLBACK(src, PROC_REF(EndCounter)), 5 SECONDS)

/mob/living/simple_animal/hostile/ordeal/pink_midnight/proc/EndCounter()
	counter = FALSE
	can_move = TRUE
	can_act = TRUE
	bullet_riccochet = FALSE
	color = null


/mob/living/simple_animal/hostile/ordeal/pink_midnight/proc/WhiteAOE(range)
	new /obj/effect/temp_visual/voidout(get_turf(src))
	playsound(get_turf(src), 'sound/magic/demon_dies.ogg', 50, 0, 8)
	can_move = FALSE
	can_act = FALSE
	SLEEP_CHECK_DEATH(8)
	for(var/i = 1 to range)
		for(var/turf/T in range(i, src))
			if(T in range(i - 1, src))
				continue // skip tiles already hit

			// hit only the new outer ring
			new /obj/effect/temp_visual/small_smoke/halfsecond(T)
			for(var/mob/living/been_hit in T)
				HurtInTurf(T, been_hit, aoe_damage, WHITE_DAMAGE, null, TRUE, FALSE, TRUE, hurt_hidden = FALSE, hurt_structure = TRUE, break_not_destroy = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL))

		SLEEP_CHECK_DEATH(2)
	can_move = TRUE
	can_act = TRUE

//Black Sun is being reworked, so this will be kinda fun for this boss instead.

/mob/living/simple_animal/hostile/ordeal/pink_midnight/proc/PaleAOE()

	can_move = FALSE
	can_act = FALSE

	var/list/all_turfs = RANGE_TURFS(7, src)
	for(var/turf/open/F in all_turfs)
		if(prob(30))
			addtimer(CALLBACK(src, PROC_REF(Firelaser), F), rand(1,30)) //offset so it looks like you're tossing a buncha shit around the room

	SLEEP_CHECK_DEATH(2 SECONDS)
	can_move = TRUE
	can_act = TRUE

/mob/living/simple_animal/hostile/ordeal/pink_midnight/proc/Firelaser(turf/open/F)
	new /obj/effect/temp_visual/pink_laser(F)


//The Counter stuff
/mob/living/simple_animal/hostile/ordeal/pink_midnight/bullet_act(obj/projectile/Proj)
	if(bullet_riccochet)
		for(var/turf/open/F in fire_turfs)
			if(prob(5))
				addtimer(CALLBACK(src, PROC_REF(Firelaser), F), rand(1,30)) //offset so it looks like you're tossing a buncha shit around the room
		if(prob(10))
			CallEnemy()

	..()


/mob/living/simple_animal/hostile/ordeal/pink_midnight/attacked_by(obj/item/I, mob/living/user)
	..()

	if(!user)
		return
	if(!counter)
		return
	WhiteAOE(2)
	if(prob(50))
		CallEnemy()



//Yeah I should compile a list only once, however compiling lists isn't super intensive plus the code for this shit is super weird.
//Due to how we are running Breach Effect and just hoping for it to return true!
/mob/living/simple_animal/hostile/ordeal/pink_midnight/proc/CallEnemy()
	var/list/abnos = list()
	for(var/mob/living/simple_animal/hostile/abnormality/A in GLOB.abnormality_mob_list)
		//Anything in this list REALLY should not be breached.
		if(A.type in blacklist)
			continue

		if(A.IsContained() && (A.z == z))
			abnos+= A

	var/mob/living/simple_animal/hostile/abnormality/A = pick(abnos)
	if(!length(abnos))
		return
	if(!A.BreachEffect(null, BREACH_PINK)) // We try breaching them our way!
		return // If they can't we just go home!

	if(A.status_flags & GODMODE)
		return // Some special "breaches" don't stay breached!

	A.faction += "pink_midnight"
	/// This does a significant bit of trolling and fucks with the facility on a much wider range.
	/// By making them walk there, certain ones like Blue Star are less centralized and can become a background threat,
	/// While others like NT immediately are in the hallways being an active threat. Also solves the issue of wall-abnos.
	var/turf/destination = pick(get_adjacent_open_turfs(src))
	if(!destination)
		destination = get_turf(src)
	if(!A.patrol_to(destination))
		A.forceMove(destination)
	if(ordeal_reference)
		ordeal_reference.ordeal_mobs |= A




//Scream at the start to give you a few goobers
/mob/living/simple_animal/hostile/ordeal/pink_midnight/Initialize(gibbed)
	. = ..()
	Scream()
	addtimer(CALLBACK(src, PROC_REF(Scream)), 30 SECONDS)

//The Scream is on a loop. These don't necessarily breach
/mob/living/simple_animal/hostile/ordeal/pink_midnight/proc/Scream()
	for(var/i in 1 to 3)
		CallEnemy()
	addtimer(CALLBACK(src, PROC_REF(Scream)), 30 SECONDS)

/mob/living/simple_animal/hostile/ordeal/pink_midnight/death(gibbed)
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	..()

/mob/living/simple_animal/hostile/ordeal/pink_midnight/Move()
	if(!can_move)
		return FALSE
	..()


//The AOE, similar to Black Sun
/obj/effect/temp_visual/pink_laser
	name = "pink laser"
	icon = 'ModularLobotomy/_Lobotomyicons/32x64.dmi'
	icon_state = "pink_strike"
	duration = 15

/obj/effect/temp_visual/pink_laser/Initialize()
	..()
	addtimer(CALLBACK(src, PROC_REF(blowup)), 10) //this is how long the animation takes

/obj/effect/temp_visual/pink_laser/proc/blowup()
	playsound(src, 'sound/weapons/laser.ogg', 10, FALSE, 4)
	for(var/mob/living/carbon/human/H in src.loc)
		H.deal_damage(60, PALE_DAMAGE, attack_type = (ATTACK_TYPE_SPECIAL | ATTACK_TYPE_ENVIRONMENT))
		if(H.sanity_lost)
			H.gib()


