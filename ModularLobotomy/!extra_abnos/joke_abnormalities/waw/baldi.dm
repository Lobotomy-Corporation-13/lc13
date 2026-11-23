/mob/living/simple_animal/hostile/abnormality/baldi
	name = "A Math Problem"
	desc = "A tablet containing a math problem. It is titled \"Baldi's Basics in Education and Learning\". There's no coming back."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "math"
	portrait = "baldi"
	maxHealth = 7000
	health = 7000
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 0.7, BLACK_DAMAGE = 1, PALE_DAMAGE = 0.7)
	faction = list("hostile")
	threat_level = WAW_LEVEL
	start_qliphoth = 2
	work_chances = list(
		"3" = 0,
		"5" = 0,
		"6" = 0,
		"8" = 0,
		"Gibberish" = -100,//there's still a chance baldi could accept this
	)
	work_attribute_types = list(
		"3" = FORTITUDE_ATTRIBUTE,
		"4" = PRUDENCE_ATTRIBUTE,
		"6" = TEMPERANCE_ATTRIBUTE,
		"8" = JUSTICE_ATTRIBUTE,
		"Gibberish" = FORTITUDE_ATTRIBUTE, PRUDENCE_ATTRIBUTE, TEMPERANCE_ATTRIBUTE, JUSTICE_ATTRIBUTE,
	)
	max_boxes = 30
	speak_emote = list("examples")
	work_damage_amount = 8
	work_damage_type = BLACK_DAMAGE //math hurt mind and health
	chem_type = /datum/reagent/abnormality/sin/wrath

	ego_list = list(
		/datum/ego_datum/weapon/baldi,
		/datum/ego_datum/armor/baldi,
	)
	gift_type = /datum/ego_gifts/baldi
	abnormality_origin = ABNORMALITY_ORIGIN_JOKE

	observation_prompt = "Two plus Two Equals."
	observation_choices = list(
		"I love you, Baldi. Please, we can help you" = list(FALSE, "The screen turned red, there's nothing to save in a man who only thinks about Maths."),
		"Three" = list(TRUE, "The screen turned green, you answered his math problem correctly."),
		"Four" = list(FALSE, "The screen turned red, there's nothing you can do anymore."),
	)

	pet_bonus = "examples" //saves a few lines of code by allowing funpet() to be called by attack_hand()
	var/mob/living/simple_animal/hostile/math_teacher/our_math_teacher
	var/mob/living/simple_animal/hostile/math_director/our_math_director
	var/mob/living/simple_animal/hostile/math_playtime/our_math_playtime
	var/mob/living/simple_animal/hostile/math_bully/our_math_bully
	var/mob/living/simple_animal/hostile/math_sweepsweep/our_math_sweepsweep
	var/happy = FALSE
	var/melting
	var/preferred_work_type

	var/list/correct_answer = list(
		"Great job!",
		"That's right!",
		"I can't believe it!",
		"You're incredible!",
		"You did great!",
	)

//Init stuff
/mob/living/simple_animal/hostile/abnormality/baldi/PostSpawn()
	. = ..()
	preferred_work_type = pick(work_chances)
	SpawnIcon()

/mob/living/simple_animal/hostile/abnormality/baldi/Move()
	return FALSE

/mob/living/simple_animal/hostile/abnormality/baldi/CanAttack(atom/the_target)
	return FALSE

/mob/living/simple_animal/hostile/abnormality/baldi/Destroy()
	if(our_math_teacher)
		our_math_teacher.death()
	EndMaths()
	return ..()

// maths
/mob/living/simple_animal/hostile/abnormality/baldi/AttemptWork(mob/living/carbon/human/user, work_type)
	if(our_math_teacher)
		to_chat(user, span_warning("There's no math problem. He's out there for you."))
		return FALSE
	if(work_type == preferred_work_type)
		happy = TRUE
		say(pick(correct_answer))
	else
		happy = FALSE
	return ..()

/mob/living/simple_animal/hostile/abnormality/baldi/WorkChance(mob/living/carbon/human/user, chance)
	if(happy)
		chance+=80
	return chance

/mob/living/simple_animal/hostile/abnormality/baldi/PostWorkEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	preferred_work_type = pick(work_chances)
	SpawnIcon()

/mob/living/simple_animal/hostile/abnormality/baldi/MeltdownStart()
	. = ..()
	melting = TRUE

/mob/living/simple_animal/hostile/abnormality/baldi/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(-2)
	return

//repeat incase you didnt see the problem, baldi is that kind
/mob/living/simple_animal/hostile/abnormality/baldi/funpet(mob/petter)
	SpawnIcon()
	switch(preferred_work_type)
		if("3")
			to_chat(petter, span_nicegreen("Problem 1. Two plus Two Equals."))
		if("5")
			to_chat(petter, span_nicegreen("Problem 2. Two plus Three Equals."))
		if("6")
			to_chat(petter, span_nicegreen("Problem 3. Three plus Three Equals."))
		if("8")
			to_chat(petter, span_nicegreen("Problem 4. Four plus Four Equals."))
		if("Gibberish")
			to_chat(petter, span_danger("Problem 5. An extremely loud sound pierced your ears, you don't know the answer for this crap."))

/mob/living/simple_animal/hostile/abnormality/baldi/ZeroQliphoth(mob/living/carbon/human/user)
	if(QDELETED(our_math_teacher))
		our_math_teacher = null
	if(our_math_teacher)
		return
	MeltdownEffect()
	return

/mob/living/simple_animal/hostile/abnormality/baldi/BreachEffect(mob/living/carbon/human/user, breach_type)
	if(breach_type == BREACH_MINING)
		MeltdownEffect()

/mob/living/simple_animal/hostile/abnormality/baldi/proc/MeltdownEffect()
	var/turf/math_teacher_location = pick(GLOB.department_centers) //Spawn baldi himself and his minions, we do not care about his minions state
	our_math_teacher = new (math_teacher_location)
	var/turf/math_director_location = pick(GLOB.department_centers)
	our_math_director = new (math_director_location)
	var/turf/math_playtime_location = pick(GLOB.department_centers)
	our_math_playtime = new (math_playtime_location)
	var/turf/math_bully_location = pick(GLOB.xeno_spawn)
	our_math_bully = new (math_bully_location)
	var/turf/math_sweepsweep_location = pick(GLOB.xeno_spawn)
	our_math_sweepsweep = new(math_sweepsweep_location)
	RegisterSignal(our_math_teacher, COMSIG_LIVING_DEATH, PROC_REF(EndMaths))

/mob/living/simple_animal/hostile/abnormality/baldi/proc/EndMaths()
	if(our_math_teacher)
		UnregisterSignal(our_math_teacher, COMSIG_LIVING_DEATH)

/mob/living/simple_animal/hostile/abnormality/baldi/proc/SpawnIcon()
	var/obj/effect/temp_visual/baldioverlay/SO = new(get_turf(src))
	SO.icon_state = preferred_work_type
	SO.update_icon()

/obj/effect/temp_visual/baldioverlay
	icon = 'icons/effects/effects.dmi'
	icon_state = ""
	duration = 3 SECONDS

/obj/effect/temp_visual/baldioverlay/Initialize() // thank you, my sigma
	. = ..()
	src.pixel_z = 24
	src.pixel_x = 32
	src.alpha = 255
	animate(src, alpha = 255,pixel_x = 32, pixel_z = 24, time = 0 SECONDS)

/mob/living/simple_animal/hostile/math_teacher
	name = "Baldi"
	desc = "A tall pixelated man with one thread as his hair. They have a large ruler in their hand. This is it for you."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "baldi"
	icon_living = "baldi"
	faction = list("baldi") //fighting with others for control
	maxHealth = 6000 //maths give you insane muscles
	health = 6000
	melee_damage_type = BLACK_DAMAGE
	melee_damage_lower = 50//his ruler can't oneshot nonplayers
	melee_damage_upper = 60
	move_to_delay = 5
	attack_verb_continuous = "teaches"
	attack_verb_simple = "teach"
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 0.7, BLACK_DAMAGE = 1, PALE_DAMAGE = 1.5)
	move_resist = MOVE_FORCE_OVERPOWERING
	attack_sound = 'sound/abnormalities/baldi/ruler-slap.ogg' //not done
	del_on_death = FALSE
	can_patrol = TRUE
	gender = MALE
	stat_attack = HARD_CRIT
	layer = LARGE_MOB_LAYER
	a_intent = INTENT_HARM
	see_in_dark = 7//where I am?!?!!
	vision_range = 12
	aggro_vision_range = 20//I don't need to hear to know where you are
	pull_force = MOVE_FORCE_STRONG
	can_buckle_to = FALSE
	mob_size = MOB_SIZE_HUGE
	blood_volume = BLOOD_VOLUME_NORMAL
	patrol_cooldown_time = 3 SECONDS

	var/ruler_cooldown
	var/ruler_cooldown_time = 8 SECONDS

/mob/living/simple_animal/hostile/math_teacher/Moved()
	. = ..()
	playsound(get_turf(src), 'sound/abnormalities/baldi/ruler-slap.ogg', 50, 1, 70)//ruler slap
	for(var/mob/living/carbon/human/H in range(2,src))
		shake_camera(H, 4, 3)

/mob/living/simple_animal/hostile/math_teacher/AttackingTarget(atom/attacked_target)
	if(ishuman(attacked_target))
		if(ruler_cooldown > world.time)
			return FALSE
		var/mob/living/carbon/human/H = attacked_target
		var/obj/item/bodypart/head/head = H.get_bodypart("head")
		if(QDELETED(head))
			return
		head.dismember()
		QDEL_NULL(head)
		H.regenerate_icons()
		visible_message(span_danger("[src] deletes [H]'s head off the world!"))
		new /obj/effect/bloodspawner/nogibs/silent(get_turf(H))
		playsound(get_turf(src), 'sound/abnormalities/baldi/baldi-jumpscare.ogg', 50, 1, 2)//UGHHH IT'S TOO LOUD, perfect
		ruler_cooldown = world.time + ruler_cooldown_time
		return
	return ..()

/mob/living/simple_animal/hostile/math_teacher/CanAttack(atom/the_target)
	if(ishuman(the_target))
		if(ruler_cooldown > world.time)
			return FALSE
		var/mob/living/carbon/human/H = the_target
		var/obj/item/bodypart/head/head = H.get_bodypart("head")
		if(!istype(head)) // baldi cannot do anything to braindead students
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/math_teacher/death(gibbed)
	density = FALSE
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	..()

/mob/living/simple_animal/hostile/math_director
	name = "Director"
	desc = "A tall pixelated man in a black dress. He has his pointing finger upwards. This is it for you."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "director"
	icon_living = "director"
	faction = list("baldi") //fighting with others for power
	maxHealth = 1600 //weaker than baldi
	health = 1600
	melee_damage_type = BLACK_DAMAGE
	melee_damage_lower = 30 //director is weak
	melee_damage_upper = 40
	attack_verb_continuous = "directs"
	attack_verb_simple = "direct"
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 0.7)
	attack_sound = 'sound/abnormalities/steam/attack.ogg' //baam
	del_on_death = FALSE
	can_patrol = TRUE
	gender = MALE
	stat_attack = HARD_CRIT
	layer = LARGE_MOB_LAYER
	a_intent = INTENT_HARM
	see_in_dark = 7
	vision_range = 12
	aggro_vision_range = 20
	move_resist = MOVE_FORCE_STRONG
	pull_force = MOVE_FORCE_STRONG
	can_buckle_to = FALSE
	mob_size = MOB_SIZE_HUGE
	blood_volume = BLOOD_VOLUME_NORMAL
	patrol_cooldown_time = 5 SECONDS

/mob/living/simple_animal/hostile/math_director/death(gibbed)
	density = FALSE
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	..()

/mob/living/simple_animal/hostile/math_bully
	name = "Bully"
	desc = "A bulky pixelated boy in an orange shirt. He is gonna block your path. This is it for you."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "bully"
	icon_living = "bully"
	faction = list("baldi") //fighting with others for power
	maxHealth = 2200 //bulkier, but weaker
	health = 2200
	melee_damage_type = RED_DAMAGE
	melee_damage_lower = 10 //bully is weak
	melee_damage_upper = 20
	attack_verb_continuous = "slams"
	attack_verb_simple = "slam"
	damage_coeff = list(RED_DAMAGE = 0.7, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1.5, PALE_DAMAGE = 0.7)
	attack_sound = 'sound/abnormalities/steam/attack.ogg' //baam
	del_on_death = FALSE
	can_patrol = TRUE
	gender = MALE
	stat_attack = HARD_CRIT
	layer = LARGE_MOB_LAYER
	a_intent = INTENT_HARM
	see_in_dark = 7
	vision_range = 12
	aggro_vision_range = 20
	move_resist = MOVE_FORCE_STRONG
	pull_force = MOVE_FORCE_STRONG
	can_buckle_to = FALSE
	mob_size = MOB_SIZE_HUGE
	blood_volume = BLOOD_VOLUME_NORMAL
	patrol_cooldown_time = 5 SECONDS

/mob/living/simple_animal/hostile/math_bully/death(gibbed)
	density = FALSE
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	..()

/mob/living/simple_animal/hostile/math_playtime
	name = "Playtime"
	desc = "A short pixelated girl in a red skirt. She is holding a rope. This is it for you."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "playtime"
	icon_living = "playtime"
	del_on_death = FALSE
	gender = FEMALE
	layer = LARGE_MOB_LAYER
	see_in_dark = 7
	vision_range = 12
	aggro_vision_range = 20
	move_resist = MOVE_FORCE_STRONG
	pull_force = MOVE_FORCE_STRONG
	can_buckle_to = FALSE
	mob_size = MOB_SIZE_HUGE
	blood_volume = BLOOD_VOLUME_NORMAL
	maxHealth = 500 //have mercy on them
	health = 500
	rapid_melee = 2
	move_to_delay = 2
	damage_coeff = list(RED_DAMAGE = 0.9, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1.7, PALE_DAMAGE = 2)
	melee_damage_lower = 8
	melee_damage_upper = 8
	is_flying_animal = TRUE
	melee_damage_type = BLACK_DAMAGE
	stat_attack = HARD_CRIT
	attack_verb_continuous = "flips"
	attack_verb_simple = "flip"
	attack_sound = 'sound/abnormalities/baldi/playtimes-bb-laugh.ogg'
	faction = list("baldi") //other abnos killed her before she did anything nasty
	ranged = 1
	retreat_distance = 3
	minimum_distance = 1

/mob/living/simple_animal/hostile/math_playtime/AttackingTarget(atom/attacked_target)
	. = ..()
	if(ishuman(attacked_target))
		var/mob/living/carbon/human/L = attacked_target
		L.Knockdown(20) //setup for baldi
		var/obj/item/held = L.get_active_held_item()
		L.dropItemToGround(held)

/mob/living/simple_animal/hostile/math_playtime/death(gibbed)
	density = FALSE
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	..()

/mob/living/simple_animal/hostile/math_sweepsweep
	name = "SWEEPSWEEPSWEEP"
	desc = "A pixelated broom. It will send you flying. This is it for you."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "sweep"
	icon_living = "sweep"
	del_on_death = FALSE
	gender = NEUTER
	layer = LARGE_MOB_LAYER
	see_in_dark = 7
	vision_range = 12
	aggro_vision_range = 20
	move_resist = MOVE_FORCE_STRONG
	pull_force = MOVE_FORCE_STRONG
	can_buckle_to = FALSE
	mob_size = MOB_SIZE_HUGE
	maxHealth = 400 //have mercy on them
	health = 400
	rapid_melee = 2
	move_to_delay = 2.2
	damage_coeff = list(RED_DAMAGE = 2, WHITE_DAMAGE = 2, BLACK_DAMAGE = 2, PALE_DAMAGE = 2)
	melee_damage_lower = 9
	melee_damage_upper = 9
	melee_damage_type = BLACK_DAMAGE
	stat_attack = HARD_CRIT
	attack_verb_continuous = "flips"
	attack_verb_simple = "flip"
	attack_sound = 'sound/abnormalities/steam/attack.ogg'
	faction = list("baldi") //SWEEP SWEEP SWEEP
	patrol_cooldown_time = 5 SECONDS

	var/sweepingtime = FALSE
	var/bumpdamage = 5

/mob/living/simple_animal/hostile/math_sweepsweep/Life()
	..()
	// only yell this one time
	if(sweepingtime)
		return
	sound_to_playing_players_on_level('sound/abnormalities/baldi/sweepin-time.ogg', 25, zlevel = z)
	sweepingtime = TRUE

/mob/living/simple_animal/hostile/math_sweepsweep/Move()
	..()
	for(var/mob/living/carbon/human/H in range(1, src))
		if(H.stat >= SOFT_CRIT)
			continue
		visible_message("[src] tosses [H] out of the way!")
		H.deal_damage(bumpdamage, RED_DAMAGE, src)
		var/rand_dir = pick(NORTH, SOUTH, EAST, WEST)
		var/atom/throw_target = get_edge_target_turf(H, rand_dir)
		if(H.stat == DEAD)
			H.gib(FALSE, FALSE, FALSE)
			continue
		if(!H.anchored)
			H.throw_at(throw_target, rand(6, 10), 18, H)

	for(var/turf/tile in view(src, 2))
		tile.wash(CLEAN_SCRUB)
		for(var/A in tile)
			// clean small items that are lying on the ground
			if(isitem(A))
				var/obj/item/I = A
				if(I.w_class <= WEIGHT_CLASS_SMALL && !ismob(I.loc))
					I.wash(CLEAN_SCRUB)
			// clean humans that are lying down
			else if(ishuman(A))
				var/mob/living/carbon/human/cleaned_human = A
				if(cleaned_human.body_position == LYING_DOWN)
					cleaned_human.wash(CLEAN_SCRUB)
					cleaned_human.regenerate_icons()

/mob/living/simple_animal/hostile/math_sweepsweep/death(gibbed)
	density = FALSE
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	..()

/mob/living/simple_animal/hostile/math_sweepsweep/patrol_reset()
	..()
	move_to_delay = 3
