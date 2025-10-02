//Coded by Coxswain, sprite by Mel
/mob/living/simple_animal/hostile/abnormality/beanstalk
	name = "Beanstalk without Jack"
	desc = "A gigantic stem that reaches higher than the eye can see."
	icon = 'ModularLobotomy/_Lobotomyicons/64x98.dmi'
	icon_state = "beanstalk"
	portrait = "beanstalk"
	maxHealth = 500
	health = 500
	threat_level = TETH_LEVEL
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(35, 45, 55, 0, 10),
		ABNORMALITY_WORK_INSIGHT = 55,
		ABNORMALITY_WORK_ATTACHMENT = 55,
		ABNORMALITY_WORK_REPRESSION = 35,
	)
	pixel_x = -16
	base_pixel_x = -16
	work_damage_amount = 7
	work_damage_type = BLACK_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/wrath
	pet_bonus = TRUE

	ego_list = list(
		/datum/ego_datum/weapon/bean,
		/datum/ego_datum/weapon/giant,
		/datum/ego_datum/armor/bean,
	)
	gift_type = /datum/ego_gifts/bean
	abnormality_origin = ABNORMALITY_ORIGIN_ARTBOOK

	observation_prompt = "You remember an employee was obsessed with this abnormality. <br>\"\
		If you reach the top, you'll find what you've been looking for!\", He'd tell every employee. <br>\
		One day he did climb the beanstalk, and never came back down. <br>Perhaps he's doing okay up there."
	observation_choices = list( //TODO: Make this event a bit special
		"Chop it down" = list(TRUE, "If something's too big to understand, it's too big to be allowed to exist. The axe bites into the stem..."),
		"Climb the beanstalk" = list(FALSE, "You begin to climb the beanstalk, but no matter how much you climb there's always more stalk. You peer at the clouds, squinting your eyes, but still can't see anyone..."),
	)

	var/climbing = FALSE
	var/list/beanstalkloot= list( //unsure what to put in the loot table here
		/obj/item/coin/gold,
		/obj/item/coin/silver,
		/obj/item/coin/diamond,
		/obj/structure/lootcrate/limbus,
		/obj/structure/lootcrate/backstreets,
		/obj/item/fireaxe,
		/obj/item/hatchet,
		/obj/structure/lootcrate/jcorp,
		/obj/item/clothing/suit/armor/ego_gear/teth/bean,
		/obj/item/ego_weapon/mini/bean,
		/obj/item/storage/box/fireworks
	)

/mob/living/simple_animal/hostile/abnormality/beanstalk/Move()
	return FALSE

/mob/living/simple_animal/hostile/abnormality/beanstalk/CanAttack(atom/the_target)
	return FALSE

//Performing instinct work at >4 fortitude starts a special work
/mob/living/simple_animal/hostile/abnormality/beanstalk/AttemptWork(mob/living/carbon/human/user, work_type)
	if((get_attribute_level(user, FORTITUDE_ATTRIBUTE) >= 80) && (work_type == ABNORMALITY_WORK_INSTINCT))
		work_damage_amount = 25 //hope you put on some armor
		climbing = TRUE
	return TRUE

/mob/living/simple_animal/hostile/abnormality/beanstalk/proc/climbinganimation(mob/living/carbon/human/user)
	user.Stun(3 SECONDS)
	step_towards(user, src)
	sleep(0.5 SECONDS)
	if(QDELETED(user))
		return
	step_towards(user, src)
	sleep(0.5 SECONDS)
	if(QDELETED(user))
		return
	animate(user, alpha = 1,pixel_x = 0, pixel_z = 16, time = 3 SECONDS)
	user.pixel_z = 16
	user.Stun(10 SECONDS)

/mob/living/simple_animal/hostile/abnormality/beanstalk/proc/headexplode(mob/living/carbon/human/user)
	user.adjustBruteLoss(500)
	var/obj/item/bodypart/head/head = user.get_bodypart("head")
	if(user == null)
		return
	if(QDELETED(head))
		return
	playsound(user, 'sound/effects/wounds/pierce1.ogg', 75, FALSE, -1)
	head.dismember()
	QDEL_NULL(head)
	new /obj/effect/gibspawner/generic/silent(get_turf(user))

/mob/living/simple_animal/hostile/abnormality/beanstalk/proc/fallinganimation(mob/living/carbon/human/user)
	user.pixel_z = 128
	user.set_lying_angle(pick(90, 270))
	user.set_body_position(LYING_DOWN)
	playsound(user, 'sound/abnormalities/roadhome/Cartoon_Falling_Sound_Effect.ogg', 75, FALSE, -1)
	animate(user, pixel_z = 0, alpha = 255, time = 3 SECONDS)

/mob/living/simple_animal/hostile/abnormality/beanstalk/funpet(mob/living/carbon/human/user)
	var/user_fort = get_attribute_level(user, FORTITUDE_ATTRIBUTE)
	var/user_prud = get_attribute_level(user, PRUDENCE_ATTRIBUTE)
	var/user_temp = get_attribute_level(user, TEMPERANCE_ATTRIBUTE)
	if(user_fort >= 40) //check if can climb
		climbinganimation(user)
		to_chat(user, span_userdanger("You begin to climb!"))
		sleep(7 SECONDS)
		if(user_prud < 40) //deathcheck
			to_chat(user, span_userdanger("You climb, and climb, and climb but the top never seems to appear."))
			QDEL_IN(user, 1)
			return
		else //item time
			sleep(3 SECONDS)
			user.Stun(15 SECONDS)
			to_chat(user, span_userdanger("You notice a variety of items and previous climbers all hanging from branches of the beanstalk!"))
			sleep(5 SECONDS)
			var/turf/get_tile = get_step(src, SOUTHEAST)
			var/beanstalklootget = pick(beanstalkloot)
			var/obj/spawned_item = new beanstalklootget(get_tile)
			to_chat(user, span_userdanger("You toss the [spawned_item] down and begin to climb back down."))
			spawned_item.pixel_z = 128
			spawned_item.alpha = 1
			animate(spawned_item, alpha = 255,pixel_x = 0, pixel_z = 0, time = 3 SECONDS)
			playsound(spawned_item, 'sound/abnormalities/roadhome/Cartoon_Falling_Sound_Effect.ogg', 75, FALSE, -1)
			sleep(3 SECONDS)
			playsound(spawned_item, 'sound/effects/grillehit.ogg', 75, FALSE, -1)
			sleep(4 SECONDS)
			animate(user, alpha = 255,pixel_x = 0, pixel_z = 0, time = 3 SECONDS)
			return
	else if(user_temp < 40)
		climbinganimation(user)
		to_chat(user, span_userdanger("You begin to climb!"))
		sleep(5 SECONDS)
		to_chat(user, span_userdanger("You slip and fall, and watch the beanstalk grow further away from you."))
		if(prob(50)) //death
			fallinganimation(user)
			sleep(3 SECONDS)
			headexplode(user)
		else //brain damage
			fallinganimation(user)
			sleep(3 SECONDS)
			user.deal_damage(50, RED_DAMAGE)
			user.gain_trauma_type(BRAIN_TRAUMA_SEVERE, TRAUMA_RESILIENCE_LOBOTOMY)
			playsound(user, 'sound/effects/wounds/crack1.ogg', 75, FALSE, -1)
			return
	else
		to_chat(user, span_notice("You probably shouldn't try to climb this."))
		return

/mob/living/simple_animal/hostile/abnormality/beanstalk/PostWorkEffect(mob/living/carbon/human/user, work_type, pe)
	var/user_fort = get_attribute_level(user, FORTITUDE_ATTRIBUTE)
	var/user_prud = get_attribute_level(user, PRUDENCE_ATTRIBUTE)
	var/user_temp = get_attribute_level(user, TEMPERANCE_ATTRIBUTE)
	if(user.sanity_lost)
		climbinganimation(user)
		sleep(5 SECONDS)
		fallinganimation(user)
		sleep(3 SECONDS)
		headexplode(user)
		return
	if(climbing)
		if(user.sanity_lost || user.stat >= SOFT_CRIT || user.stat == DEAD)
			work_damage_amount = 7
			climbing = FALSE
			return

		user.Stun(3 SECONDS)
		step_towards(user, src)
		sleep(0.5 SECONDS)
		if(QDELETED(user))
			work_damage_amount = 7
			climbing = FALSE
			return
		step_towards(user, src)
		sleep(0.5 SECONDS)
		if(QDELETED(user))
			work_damage_amount = 7
			climbing = FALSE
			return
		to_chat(user, span_userdanger("You start to climb!"))
		animate(user, alpha = 1,pixel_x = 0, pixel_z = 16, time = 3 SECONDS)
		user.pixel_z = 16
		user.Stun(10 SECONDS)
		sleep(6 SECONDS)
		if(QDELETED(user))
			work_damage_amount = 7
			climbing = FALSE
			return
		var/datum/ego_gifts/giant/BWJEG = new
		BWJEG.datum_reference = datum_reference
		user.Apply_Gift(BWJEG)
		animate(user, alpha = 255,pixel_x = 0, pixel_z = -16, time = 3 SECONDS)
		user.pixel_z = 0
		to_chat(user, span_userdanger("You return with the giant's treasure!"))
		work_damage_amount = 7
		climbing = FALSE
		return
	if(user_fort >= 40) //check if can climb
		if(user_temp < 60) //hypnotized or not
			climbinganimation(user)
			to_chat(user, span_userdanger("Greed overwhelms you, you stride towards the beanstalk and start climbing."))
			sleep(7 SECONDS)
			if(user_prud < 40) //deathcheck
				to_chat(user, span_userdanger("You climb, and climb, and climb but the top never seems to appear."))
				QDEL_IN(user, 1)
				return
			else //item time
				to_chat(user, span_userdanger("You snap out of your stupor!"))
				sleep(3 SECONDS)
				to_chat(user, span_userdanger("You notice a variety of items and previous climbers all hanging from branches of the beanstalk!"))
				user.Stun(15 SECONDS)
				sleep(5 SECONDS)
				var/turf/get_tile = get_step(src, SOUTHEAST)
				var/beanstalklootget = pick(beanstalkloot)
				var/obj/spawned_item = new beanstalklootget(get_tile)
				spawned_item.pixel_z = 128
				spawned_item.alpha = 1
				to_chat(user, span_userdanger("You toss the [spawned_item] down and begin to climb back down."))
				animate(spawned_item, alpha = 255,pixel_x = 0, pixel_z = 0, time = 3 SECONDS)
				playsound(spawned_item, 'sound/abnormalities/roadhome/Cartoon_Falling_Sound_Effect.ogg', 75, FALSE, -1)
				sleep(3 SECONDS)
				playsound(spawned_item, 'sound/effects/grillehit.ogg', 75, FALSE, -1)
				sleep(4 SECONDS)
				animate(user, alpha = 255,pixel_x = 0, pixel_z = 0, time = 3 SECONDS)
				return
	else if(user_temp < 40)
		climbinganimation(user)
		to_chat(user, span_userdanger("Greed overwhelms you, you stride towards the beanstalk and start climbing."))
		sleep(5 SECONDS)
		to_chat(user, span_userdanger("You slip and fall, and watch the beanstalk grow further away from you."))
		if(prob(50)) //death
			fallinganimation(user)
			sleep(3 SECONDS)
			headexplode(user)
		else //brain damage
			fallinganimation(user)
			sleep(3 SECONDS)
			user.deal_damage(50, RED_DAMAGE)
			user.gain_trauma_type(BRAIN_TRAUMA_SEVERE, TRAUMA_RESILIENCE_LOBOTOMY)
			playsound(user, 'sound/effects/wounds/crack1.ogg', 75, FALSE, -1)
			return
	else
		to_chat(user, span_userdanger("You overcome the urge to climb, knowing that you're too weak to climb it."))
		return

/datum/ego_gifts/giant
	name = "Giant"
	icon_state = "giant"
	fortitude_bonus = 8
	slot = LEFTBACK
