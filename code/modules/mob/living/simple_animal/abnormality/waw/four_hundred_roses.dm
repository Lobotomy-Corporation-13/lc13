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
	..()
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


/mob/living/simple_animal/hostile/mini_roses/Move()
	return FALSE

/mob/living/simple_animal/hostile/mini_roses/CanAttack(atom/the_target)
	return FALSE

/mob/living/simple_animal/hostile/mini_roses/Life()
	..()
	if(!boss)
		return
	boss.bloodfeast++
	adjustBruteLoss(-5)

//Meleeing the Roses gives you bleed
/mob/living/simple_animal/hostile/mini_roses/attacked_by(obj/item/I, mob/living/user)
	..()

	if(!user)
		return
	//It's waw level, fuck it.
	user.apply_lc_bleed(3)

