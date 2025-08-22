//Very simple, funny little guy.
/mob/living/simple_animal/hostile/abnormality/lunar_rabbit
	name = "Lunar Physician"
	desc = "A little rabbit girl in a nurse outfit."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "lunar_rabbit"
	icon_living = "lunar_rabbit"
	pixel_x = -8
	base_pixel_x = -8
	del_on_death = TRUE
	maxHealth = 300	//She's a fast motherfucker.
	health = 300
	rapid_melee = 2
	move_to_delay = 1.2
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 2)
	melee_damage_lower = 2		//Varies a lot.
	melee_damage_upper = 25
	melee_damage_type = BLACK_DAMAGE
	stat_attack = HARD_CRIT
	attack_verb_continuous = "cuts"
	attack_verb_simple = "cut"
	attack_sound = 'sound/abnormalities/cleave.ogg'
	faction = list("hostile")
	can_breach = TRUE
	threat_level = TETH_LEVEL
	start_qliphoth = 1

	ranged = 1
	retreat_distance = 3
	minimum_distance = 1
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 60,
		ABNORMALITY_WORK_INSIGHT = 50,
		ABNORMALITY_WORK_ATTACHMENT = 30,
		ABNORMALITY_WORK_REPRESSION = 60,
	)
	work_damage_amount = 12
	work_damage_type = BLACK_DAMAGE

	ego_list = list(
		/datum/ego_datum/weapon/patch,
		/datum/ego_datum/armor/patch
	)
	//gift_type =  /datum/ego_gifts/acupuncture
	abnormality_origin = ABNORMALITY_ORIGIN_ORIGINAL


/mob/living/simple_animal/hostile/abnormality/lunar_rabbit/Initialize(atom/attacked_target)
	.=..()
	var/breachtime = 5 MINUTES + rand(1, 10 MINUTES)
	addtimer(CALLBACK(src, PROC_REF(BreachMe)), breachtime)

/mob/living/simple_animal/hostile/abnormality/lunar_rabbit/proc/BreachMe(atom/attacked_target)
	datum_reference.qliphoth_change(-99)

/mob/living/simple_animal/hostile/abnormality/lunar_rabbit/AttackingTarget(atom/attacked_target)
	. = ..()
	if(ishuman(attacked_target))
		var/mob/living/carbon/human/L = attacked_target

		//Give it the same effects as space drugs
		L.set_drugginess(15)
		if(prob(20))
			L.emote(pick("twitch","drool","moan","giggle"))

/mob/living/simple_animal/hostile/abnormality/lunar_rabbit/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time)
	..()
	say("The doctor is in. Please, show me your arm.")
	SLEEP_CHECK_DEATH(10)
	to_chat(user, span_notice("You feel a tiny prick."))
	SLEEP_CHECK_DEATH(10)
	say("There you are! All better.")

	//Always give you drugs but like it's funny
	user.set_drugginess(15)

/mob/living/simple_animal/hostile/abnormality/lunar_rabbit/SuccessEffect(mob/living/carbon/human/user, work_type, pe)
	..()
	user.adjustBruteLoss(-40)

/mob/living/simple_animal/hostile/abnormality/lunar_rabbit/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	..()
	user.deal_damage(45, BLACK_DAMAGE)


