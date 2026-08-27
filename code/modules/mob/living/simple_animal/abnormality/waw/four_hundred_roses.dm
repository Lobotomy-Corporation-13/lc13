/mob/living/simple_animal/hostile/abnormality/roses_waw
	name = "Four hundred Roses"
	desc = "A monsterous, towering rose."
	icon = 'ModularLobotomy/_Lobotomyicons/64x96.dmi'
	icon_state = "roses_waw"
	icon_living = "roses_waw"
	//portrait = "roses_waw"
	pixel_x = -16
	base_pixel_x = -16
	pixel_y = -32
	base_pixel_y = -32
	maxHealth = 400
	health = 400
	start_qliphoth = 2
	threat_level = WAW_LEVEL
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 60,
		ABNORMALITY_WORK_INSIGHT = list(40, 30, 20, 20, 20),
		ABNORMALITY_WORK_ATTACHMENT = list(55, 55, 60, 60, 60),
		ABNORMALITY_WORK_REPRESSION = 0,
	)
	work_damage_amount = 10
	work_damage_type = RED_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/wrath

	ego_list = list(
		/datum/ego_datum/weapon/yearning,
		/datum/ego_datum/weapon/mircalla,
		/datum/ego_datum/armor/yearningmircalla,
	)
	//gift_type =  /datum/ego_gifts/mircala
	abnormality_origin = ABNORMALITY_ORIGIN_LIMBUS

//Plant Based stuff
	grouped_abnos = list(
		/mob/living/simple_animal/hostile/abnormality/fallen_amurdad = 1.5,
		/mob/living/simple_animal/hostile/abnormality/little_prince = 1.5,
		/mob/living/simple_animal/hostile/abnormality/parasite_tree = 1.5,
	)

	generic_bubbles = alist(
		1 = list("%ABNO leaks sap onto %PERSON's foot."),
		2 = list("%ABNO's vines seem to coil around %PERSON."),
		3 = list("%ABNO sways with an invisible wind."),
		4 = list("%ABNO's eyes seem to blink slowly."),
		5 = list("%ABNO shirks away from %PERSON."),
	)
	work_bubbles = list(
		ABNORMALITY_WORK_INSTINCT = list("Blood drips onto the floor."),
		ABNORMALITY_WORK_INSIGHT = list("%PERSON takes some clippings from %ABNO."),
		ABNORMALITY_WORK_ATTACHMENT = list("%PERSON starts to sing to %ABNO."),
		ABNORMALITY_WORK_REPRESSION = list("Scabs appear to form on %ABNO."),
	)

	//When this reaches, 100, Bleed and Fragile everyone.
	var/bloodfeast = 0

	//when this reaches 25, lower counter and reset.
	var/bad_tick_counter = 0

/mob/living/simple_animal/hostile/abnormality/roses_waw/WorktickFailure(mob/living/carbon/human/user)
	..()
	bad_tick_counter ++
	if(bad_tick_counter >= 25)
		bad_tick_counter = 0
		datum_reference.qliphoth_change(-1)

/mob/living/simple_animal/hostile/abnormality/roses_waw/ZeroQliphoth(mob/living/carbon/human/user)
	..()
	datum_reference.qliphoth_change(2)
	for(var/i = 1 to 3)
		var/turf/W = pick(GLOB.xeno_spawn)
		var/mob/living/simple_animal/hostile/mini_roses/E = new(get_turf(W))
		E.boss = src

/mob/living/simple_animal/hostile/abnormality/roses_waw/Life()
	. = ..()
	if(bloodfeast == 100)
		BleedAll()


/mob/living/simple_animal/hostile/abnormality/roses_waw/proc/BleedAll()
	for(var/mob/living/L in GLOB.player_list)
		if(L.z!=z || L.stat == DEAD)
			continue
		//You let it get this bad.
		L.apply_lc_bleed(20)
		L.apply_lc_red_fragile(3)
	bloodfeast = 0



//You can put these guys about to guard an area.
/mob/living/simple_animal/hostile/mini_roses
	name = "one of the roses"
	desc = "A rose that belongs to Four Hundred Roses."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "hundred_roses"
	icon_living = "hundred_roses"
	health = 500	//They're here to help
	maxHealth = 500
	melee_damage_type = RED_DAMAGE
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 0.7, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 2)
	melee_damage_lower = 2
	melee_damage_upper = 2
	del_on_death = TRUE
	attack_verb_continuous = "bops"
	attack_verb_simple = "bops"
	attack_sound = 'sound/weapons/bite.ogg'
	var/mob/living/simple_animal/hostile/abnormality/roses_waw/boss
	var/list/vines = list()
	var/blood_range = 5


/mob/living/simple_animal/hostile/mini_roses/Move()
	return FALSE

/mob/living/simple_animal/hostile/mini_roses/CanAttack(atom/the_target)
	return FALSE

/mob/living/simple_animal/hostile/mini_roses/Destroy()
	boss = null
	for(var/obj/structure/spreading/apple_vine/A in vines)
		qdel(A)

	vines = list()
	..()

/mob/living/simple_animal/hostile/mini_roses/Life()
	. = ..()
	if(prob(30))
		switch(rand(1,3))
			if(1)
				BloodAOE()
			if(2)
				SpreadVines()
			if(3)
				BloodFire()

	adjustBruteLoss(-5)

	if(!boss)
		return
	boss.bloodfeast++


/mob/living/simple_animal/hostile/mini_roses/proc/BloodAOE()
	for(var/i = 1 to 4)
		for(var/turf/T in range(i, src))
			if(T in range(i - 1, src))
				continue
			new /obj/effect/temp_visual/cult/sparks(T)
			for(var/mob/living/L in T)
				L.apply_lc_bleed(3)
		SLEEP_CHECK_DEATH(2)


/mob/living/simple_animal/hostile/mini_roses/proc/SpreadVines()
	for(var/turf/T in view(10, get_turf(src)))
		if(prob(90))
			continue	//Only spread a bit of vines
		if(!isturf(T) || isspaceturf(T))
			continue
		if(locate(/obj/structure/spreading/apple_vine) in T)
			continue
		var/obj/structure/spreading/apple_vine/A = new(T)
		vines += A

//Blood Line attack
/mob/living/simple_animal/hostile/mini_roses/proc/BloodFire()
	var/list/blood_targets = list()
	for(var/mob/living/H in view(8, src))
		blood_targets += H
	if(!length(blood_targets))
		return

	var/mob/living/L = pick(blood_targets)
	var/turf/T = get_ranged_target_turf_direct(src, L, blood_range)
	var/list/blood_turfs = getline(src, T) - get_turf(src)
	BloodLine(src, blood_turfs, 15)

/mob/living/simple_animal/hostile/mini_roses/proc/BloodLine(atom/source, list/turfs, damage)
	can_act = FALSE
	for(var/turf/T in turfs)
		if(istype(T, /turf/closed))
			break
		new /obj/effect/roses_bleed(T)
		SLEEP_CHECK_DEATH(1.5)
		playsound(T, 'sound/effects/meatslap.ogg', 75, FALSE, 4)
	can_act = TRUE


//Ranged Counter
/mob/living/simple_animal/hostile/mini_roses/bullet_act(obj/projectile/Proj)
	..()
	if(!ishuman(Proj.firer))
		return
	var/mob/living/carbon/human/H = Proj.firer
	new /obj/effect/roses_bleed (get_turf(H))


//Blood fall
/obj/effect/roses_bleed
	name = "rose warning"
	desc = "A target warning you of incoming pain"
	icon = 'icons/effects/blood.dmi'
	icon_state = "itemblood"
	move_force = INFINITY
	pull_force = INFINITY
	generic_canpass = FALSE
	movement_type = PHASING | FLYING
	var/lifetime = 1 SECONDS
	layer = POINT_LAYER

/obj/effect/roses_bleed/Initialize()
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(explode)), lifetime)

/obj/effect/roses_bleed/proc/explode()
	playsound(get_turf(src), 'sound/magic/blind.ogg', 50, 0, 8)
	new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(src), pick(GLOB.alldirs))
	for(var/mob/living/L in get_turf(src))
		L.apply_lc_bleed(8)
		L.deal_damage(30, RED_DAMAGE, flags = (DAMAGE_FORCED))
	qdel(src)
