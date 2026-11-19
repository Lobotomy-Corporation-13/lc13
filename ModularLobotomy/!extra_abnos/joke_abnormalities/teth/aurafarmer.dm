/mob/living/simple_animal/hostile/abnormality/aurafarmer
	name = "Aura Farmer"
	desc = "A flying, magnificent large horse humanoid. Just looking at him fills you with dread and fear."
	icon = 'ModularLobotomy/_Lobotomyicons/128x128.dmi'
	pixel_x = -48
	base_pixel_x = -48
	pixel_y = -10
	base_pixel_y = -10
	icon_state = "aurafarm"
	icon_living = "aurafarm"
	portrait = "aurafarmer"
	maxHealth = 9999//he can have this
	health = 9999
	attack_verb_continuous = "mogs, spares"
	attack_verb_simple = "mog, spare"
	threat_level = TETH_LEVEL
	attack_sound = 'sound/weapons/bite.ogg'//no fun sound since he can't really attack
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 50, 60, 30, 20, 10,
		ABNORMALITY_WORK_INSIGHT = 50, 60, 30, 20, 10,//doesn't like high level agents, his ego is hurt
		ABNORMALITY_WORK_ATTACHMENT = 20,
		ABNORMALITY_WORK_REPRESSION = 60, 70, 40, 30, 20,
	)
	work_damage_amount = 4//if he wanted to hit you for real he would qdel you on spot
	work_damage_type = RED_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/pride
	damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 2)
	is_flying_animal = TRUE
	speak_emote = list("nonchalantly speaks")
	melee_damage_lower = 1//aura
	melee_damage_upper = 1
	can_breach = TRUE
	start_qliphoth = 2
	max_boxes = 15
	can_patrol = FALSE
	wander = FALSE
	light_color = COLOR_WHITE
	light_range = 24
	light_power = 5
	del_on_death = FALSE
	faction = list("friendly")//other abnos will help you kill him

	ego_list = list(
		/datum/ego_datum/weapon/aura,
		/datum/ego_datum/armor/aura,
	)
	gift_type = /datum/ego_gifts/aura_farmer
	abnormality_origin = ABNORMALITY_ORIGIN_JOKE

	observation_prompt = "Before you, flying above the ground is a man with a horse head. <br>\
		He begins his loud speech. You feel unable to say anything in his immense presence. <br>\
		\"Heed me, my pawn\" <br>\
		\"All you need to do is tell me one thing. Who has the most Aura in the City?\" <br>\
		He keeps his intense gaze on you and it makes you feel extremely nervous. <br>\
		He then nonchalantly waves his hands around, no longer keeping his eyes on you. <br>\
		You feel yourself being able to speak once more. <br>W-who has the m-most Aura? You think to yourself."
	observation_choices = list(
		"Camille" = list(FALSE, "You don't even know who this is <br>\
			But it's the first name to come to your mind <br>\
			\"Awful.\" <br>\
			He replies with a cold voice and slowly brings his hand to your forehead. <br>\
			Using all of your remaining willpower, you run out of the chamber safely."),
		"Y-you, my King" = list(FALSE, "You quickly reply with a stammering voice <br>\
			In a few seconds, you feel as if a piece of your mind is missing. <br>\
			He chuckles and doesn't even look at you back, he knew you'd say that. <br>\
			Perhaps you should have shown him some of your dignity."),
		"Me" = list(TRUE, "You must humble his arrogancy, after all he's just a TETH. Who he thinks he is?<br>\
			His hands tremble, your answer gets him off guard, <br>\
			His flying form falters, he's barely keeping himself in air <br>\
			His sunglasses drop to the ground and you know you have to wear them."),
	)

/mob/living/simple_animal/hostile/abnormality/aurafarmer/Move()
	return FALSE

/mob/living/simple_animal/hostile/abnormality/aurafarmer/CanAttack(atom/the_target)
	return FALSE

var/list/combat_lines = list(
		"Think you can defeat me?",
		"My aura farming is supreme.",
		"You can't keep up.",
		"This facility is pretty advanced, eh?",
		"Continue, I'll just laugh at you.",
		"Thinking about giving up yet?",
		"Do something more useful.",
		"L, ratio.",
		"You're just tickling me.",
		"Not even a claw could stop me, what makes you think you will?",
		"If I were yo-.. Actually, I would never be a bum.",
)

/mob/living/simple_animal/hostile/abnormality/aurafarmer/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	if(prob(20))
		say(pick(combat_lines))

/mob/living/simple_animal/hostile/abnormality/aurafarmer/NeutralEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(60))
		datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/aurafarmer/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	datum_reference.qliphoth_change(-2)
	return

/mob/living/simple_animal/hostile/abnormality/aurafarmer/BreachEffect(mob/living/carbon/human/user, breach_type)
	. = ..()
	var/turf/T = pick(GLOB.department_centers)
	icon_living = "aurafarm"
	icon_state = icon_living
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(show_global_blurb), 5 SECONDS, "So the Aura Farming begins...", 25))

/mob/living/simple_animal/hostile/abnormality/aurafarmer/death(gibbed)
	animate(src, alpha = 0, time = 4 SECONDS)
	QDEL_IN(src, 4 SECONDS)
	to_chat(src, span_danger("<b>You simply can't fight me one on one..</b>"))
	return ..()
