///More or less the same as the original, with some tweaks making it more of a menace, like the ability to trigger murderous insanity on combo beak hits.
/mob/living/simple_animal/hostile/limbus_abno/pbird
	true_name = "Punishing Bird"
	maxHealth = 600
	health = 600
	melee_damage_lower = 1
	melee_damage_upper = 2
	melee_damage_type = RED_DAMAGE
	damage_coeff = list(RED_DAMAGE = 2, WHITE_DAMAGE = 2, BLACK_DAMAGE = 2, PALE_DAMAGE = 2)
	density = FALSE
	speak_emote = list("chirps")
	attack_sound = 'sound/weapons/pbird_bite.ogg'
	abno_additional_instructions = "The world is full of sinners, and they must be punished, so that they know not to do it again. \
	When taking damage, you will be able to dish out one singular extremely powerful strike. \
	Otherwise, pecking people with your beak is enough to rise your mood, and also restore the sanity of your target, if they have not sinned, of course.\
	If someone hurts you more than once, it is only fair that you strike them back as many times as they did, but if your target cannot be found, you will wait patiently in a more mercifull form"
	original_abno = /mob/living/simple_animal/hostile/abnormality/punishing_bird

	diet_list = list(/obj/item/seeds, /obj/item/food/breadslice, /obj/item/food/bread)
	attack_action_types = list(/datum/action/cooldown/limbus_abno_action/bodyblock,
	/datum/action/cooldown/limbus_abno_action/blind_punishment,
	/datum/action/cooldown/limbus_abno_action/pecking_frenzy)
	diet_value = 100
	hunger_cooldown_time = 1 MINUTES
	desire_cooldown_time = 1 MINUTES
	desire_loss = 15
	desire_on_pet = 40
	desire_on_eat = 40
	desire_on_talk = 1
	rep_desire_gain = -100
	ego_list = list(
		/datum/ego_datum/weapon/beak,
		/datum/ego_datum/weapon/beakmagnum,
		/datum/ego_datum/armor/beak,
	)
	//Evil bird mode.
	var/bird_angry = FALSE
	//If true, ignores the sinner list entirely, letting them hit anyone once while enraged.
	var/blind_punishment = FALSE
	//List of people who hurt the bird.
	var/list/sinners = list()
	var/mob/living/carbon/human/combo_target
	var/calm_down_ratio = 0.3
	var/active_combo_timer_id
	var/combo_active = FALSE
	var/combo_counter = 1

//Being hit multiple times might add the same person more than one time in the sinner's list. That's on purpose as pbird gets a free angry hit on someone for everytime they hurt it.
/mob/living/simple_animal/hostile/limbus_abno/pbird/attackby(obj/item/W, mob/user, params)
	. = ..()
	if(HealthCheck())
		Retaliate()
		sinners += user

/mob/living/simple_animal/hostile/limbus_abno/pbird/attack_animal(mob/living/simple_animal/M)
	. = ..()
	if(HealthCheck())
		Retaliate()
		sinners += M

/mob/living/simple_animal/hostile/limbus_abno/pbird/bullet_act(obj/projectile/P)
	. = ..()
	if(HealthCheck())
		Retaliate()
		sinners += P.firer

/mob/living/simple_animal/hostile/limbus_abno/pbird/attack_hand(mob/living/carbon/human/M)
	..()
	if(M.a_intent == INTENT_HARM)
		sinners += M
		Retaliate(M)

/mob/living/simple_animal/hostile/limbus_abno/pbird/proc/HealthCheck()
	if(health < (maxHealth * calm_down_ratio))
		if(bird_angry)
			CalmDown()
		return FALSE
	return TRUE

/mob/living/simple_animal/hostile/limbus_abno/pbird/proc/Retaliate(mob/living/user)
	if(bird_angry)
		return
	visible_message(span_danger("\The [src] turns its insides out as a giant bloody beak appears!"))
	flick("pbird_transition", src)
	AdjustStun(12, ignore_canstun = TRUE)
	icon_state = "pbird_red"
	icon_living = "pbird_red"
	attack_verb_continuous = "eviscerates"
	attack_verb_simple = "eviscerate"
	melee_damage_type = RED_DAMAGE
	rapid_melee = 1
	melee_damage_lower = 500
	melee_damage_upper = 500
	//other damage done later
	obj_damage = 2500
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	stat_attack = DEAD
	ChangeResistances(list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 0.5, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 0.5))
	bird_angry = TRUE
	addtimer(CALLBACK(src, PROC_REF(CalmDown)), 2 MINUTES)

/mob/living/simple_animal/hostile/limbus_abno/pbird/proc/CalmDown()
	if(!bird_angry)
		return
	visible_message(span_notice("[src] turns back into a fuzzy looking bird!"))
	sinners = list()
	icon_state = original_abno.icon_state
	icon_living = original_abno.icon_living
	pixel_x = initial(pixel_x)
	pixel_y = initial(pixel_y)
	base_pixel_x = initial(base_pixel_x)
	base_pixel_y = initial(base_pixel_y)
	attack_verb_continuous = initial(attack_verb_continuous)
	attack_verb_simple = initial(attack_verb_simple)
	rapid_melee = initial(rapid_melee)
	melee_damage_lower = initial(melee_damage_lower)
	melee_damage_upper = initial(melee_damage_upper)
	melee_damage_type = WHITE_DAMAGE
	AdjustHunger(max_hunger)
	AdjustDesire(max_desire)
	adjustHealth(-maxHealth) // Full restoration
	ChangeResistances(list(RED_DAMAGE = 2, WHITE_DAMAGE = 2, BLACK_DAMAGE = 2, PALE_DAMAGE = 2))
	bird_angry = FALSE
	update_icon()

/mob/living/simple_animal/hostile/limbus_abno/pbird/AttackingTarget(atom/attacked_target)
	if(IsFriend(attacked_target))
		to_chat(src, span_warning("This one is a friend, they're innocent, they must be!"))
		return

	if(!bird_angry)
		if(target != src && isliving(target))
			AdjustDesire(10)
		if(!ishuman(attacked_target))
			return ..()

		var/mob/living/carbon/human/H = attacked_target
		if(!combo_target && combo_active)
			combo_target = H

		if(combo_target != H && combo_active)
			combo_counter = 1
			ResetCombo()
		else if(combo_target == H && combo_active)
			to_chat(src, span_warning("You peck [H] harder!"))
			H.adjustWhiteLoss(20 * combo_counter)
			combo_counter += 1
			if(!active_combo_timer_id)
				active_combo_timer_id = addtimer(CALLBACK(src, PROC_REF(ResetCombo)), 10 SECONDS, TIMER_STOPPABLE) //You have 10 seconds to maximize your damage before it resets.
		else
			melee_damage_lower = initial(melee_damage_lower)
			melee_damage_upper = initial(melee_damage_upper)
			H.adjustWhiteLoss(-20)

		..()
		if(H.sanity_lost && combo_active) //This sanity checks happens AFTER the damage has been done.
			QDEL_NULL(H.ai_controller)
			H.ai_controller = /datum/ai_controller/insane/murder
			H.InitializeAIController()
		return

	//The part of the code where the bird is angry and attacks.
	if(isliving(attacked_target))
		if(LAZYFIND(sinners, attacked_target) && !blind_punishment)
			..()
			sinners -= attacked_target
			if(!sinners.len)
				CalmDown()
				return
		else if(blind_punishment)
			..()
			blind_punishment = FALSE
			if(!sinners.len)
				CalmDown()
		else
			to_chat(src, span_warning("You can't punish innocent people!"))
	else
		return ..()

/mob/living/simple_animal/hostile/limbus_abno/pbird/proc/StartCombo()
	combo_active = TRUE
	active_combo_timer_id = addtimer(CALLBACK(src, PROC_REF(ResetCombo)), 30 SECONDS, TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/limbus_abno/pbird/proc/ResetCombo()
	combo_counter = 1
	if(active_combo_timer_id)
		deltimer(active_combo_timer_id)
		active_combo_timer_id = null
		to_chat(src, span_boldwarning("Your peck frenzy is over."))
		combo_active = FALSE
	combo_target = null
	if(!bird_angry)
		melee_damage_lower = initial(melee_damage_lower)
		melee_damage_lower = initial(melee_damage_upper)

///Extra way to be annoying for no reason. Also puts you in harm intent so that the block actually works even on people that are on help intent.
/datum/action/cooldown/limbus_abno_action/bodyblock
	name = "Bodyblock"
	desc = "You focus on blocking people's way, making them more likely to hurt you on accident. The effect will last until you reactivate this skill."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lc13icons.dmi'
	button_icon_state = "Guard_this_wagie"
	transparent_when_unavailable = TRUE
	cooldown_time = 2 SECONDS

/datum/action/cooldown/limbus_abno_action/bodyblock/Trigger()
	. = ..()
	if(!.)
		return FALSE
	if(abno_user.density)
		abno_user.density = FALSE
	else
		abno_user.density = TRUE
	StartCooldown()
	return TRUE

///This might be abused, but that's kind of the point.
/datum/action/cooldown/limbus_abno_action/blind_punishment
	name = "Blind Punishment"
	desc = "Someone needs to be punished, anyone will do. Lets you get one singular angry hit, regardless of their sins, but can only be used at very low desire."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	button_icon_state = "punishment_noBG"
	transparent_when_unavailable = TRUE
	cooldown_time = 3 MINUTES
	desire_req = 20

/datum/action/cooldown/limbus_abno_action/blind_punishment/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/pbird/bird = abno_user
	if(bird.blind_punishment)
		return FALSE //Don't start a CD if they still have a punishment charged up
	bird.blind_punishment = TRUE
	bird.Retaliate()
	StartCooldown()
	return TRUE

///Heals everyone that hears it, including pbird itself.
/datum/action/cooldown/limbus_abno_action/pecking_frenzy
	name = "Pecking frenzy"
	desc = "Your pecks will deal increasing sanity damage with each peck for 30 seconds on the same target, always leading to a violent insanity. Hitting another target ends the frenzy."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	button_icon_state = "musical_addiction"
	transparent_when_unavailable = TRUE
	cooldown_time = 1.5 MINUTES

/datum/action/cooldown/limbus_abno_action/pecking_frenzy/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/pbird/bird = abno_user
	bird.StartCombo() //You have 30 seconds to maximize your damage before it resets.
	StartCooldown()
	return TRUE
