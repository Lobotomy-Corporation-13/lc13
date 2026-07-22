/mob/living/simple_animal/hostile/rcorp_abno/easy/puss_in_boots
	name = "Puss in Boots"
	desc = "He's got a sword!"
	maxHealth = 1000
	health = 1000
	del_on_death = FALSE
	melee_damage_type = RED_DAMAGE
	melee_damage_lower = 5
	melee_damage_upper = 15
	rapid_melee = 4
	ranged = TRUE
	var/finisher_cooldown = 0
	var/finisher_cooldown_time = 60 SECONDS
	var/finishing = FALSE
	original_abno = /mob/living/simple_animal/hostile/abnormality/puss_in_boots

	abno_additional_instructions = "<h1>You are Puss in Boots, A Combat Role Abnormality.</h1><br>\
		<b>|En Garde|: When attempting to attack a target at range with your ability enabled you will initiate your Finisher ability. \
		Upon initiating Finisher on your target they will be told be En Garde and be given 4 seconds to break line of sight. \
		If target remains within sight both you and the target will be stunned and you will initiate Execution.<br>\
		<br>\
		<b>|Execution|: Once Execution is triggered from a succesful En Garde you will dash to your target and do a high damage PALE attack which checks for RED armor. \
		The damage of Execution is doubled against non-human targets (of which you will not normally fight). \
		If your target falls into a critical state from this attack they will be instantly bisected. <br></b>"

	//PLAYABLES ATTACKS
	attack_action_types = list(/datum/action/innate/rca_abnormality_attack/toggle/puss_finisher_toggle)

/datum/action/innate/rca_abnormality_attack/toggle/puss_finisher_toggle
	name = "Toggle Finisher"
	button_icon_state = "puss_toggle0"
	chosen_attack_num = 1
	chosen_message = span_colossus("You will now perform a powerful finisher move.")
	button_icon_toggle_activated = "puss_toggle1"
	toggle_attack_num = 2
	toggle_message = span_colossus("You will not perform a finisher anymore.")
	button_icon_toggle_deactivated = "puss_toggle0"

/mob/living/simple_animal/hostile/rcorp_abno/easy/puss_in_boots/Initialize()
	. = ..()
	icon_state = "cat_breached"

/mob/living/simple_animal/hostile/rcorp_abno/easy/puss_in_boots/Move()
	if(!can_act)
		return FALSE
	..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/puss_in_boots/AttackingTarget()
	if(!can_act)
		return FALSE
	..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/puss_in_boots/proc/Execute(target)
	if(finisher_cooldown > world.time)
		return
	if(!isliving(target))
		return
	if(faction_check_mob(target))
		to_chat(src, span_notice("You will not turn your blade on your ally!"))
		return
	var/mob/living/T = target
	finisher_cooldown = world.time + finisher_cooldown_time
	playsound(src, 'sound/abnormalities/crumbling/warning.ogg', 50, 1)
//	icon_state = "cat_prepare" maybe someday we'll have nice things
	can_act = FALSE
	finishing = TRUE
	face_atom(target)
	T.add_overlay(icon('icons/effects/effects.dmi', "zorowarning"))
	addtimer(CALLBACK(T, TYPE_PROC_REF(/atom, cut_overlay), \icon('icons/effects/effects.dmi', "zorowarning")), 40)
	say("En garde!")
	SLEEP_CHECK_DEATH(40)
//	icon_state = "cat_dash" //ditto
	if(target in view(10, src))
		var/turf/jump_turf = get_step(target, pick(GLOB.alldirs))
		if(jump_turf.is_blocked_turf(exclude_mobs = TRUE))
			jump_turf = get_turf(target)
		T.add_overlay(icon('icons/effects/effects.dmi', "zoro"))
		addtimer(CALLBACK(T, TYPE_PROC_REF(/atom, cut_overlay), \
								icon('icons/effects/effects.dmi', "zoro")), 14)
		playsound(target, 'sound/abnormalities/pussinboots/slash.ogg', 50, 0, 2)
		forceMove(jump_turf)
		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			H.Stun(9)
		else
			can_act = TRUE
		SLEEP_CHECK_DEATH(3)
		playsound(target, 'sound/abnormalities/pussinboots/counterslash.ogg', 50, 0, 2)
		SLEEP_CHECK_DEATH(6)
		playsound(target, 'sound/abnormalities/crumbling/attack.ogg', 50, 1)
		Finisher(target)
	can_act = TRUE
	finishing = FALSE

/mob/living/simple_animal/hostile/rcorp_abno/easy/puss_in_boots/proc/Finisher(mob/living/target) //This is super easy to avoid
	target.deal_damage(50, PALE_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL), blocked = target.run_armor_check(null, RED_DAMAGE)) //50% of your health in red damage
	to_chat(target, span_danger("[src] is trying to cut you in half!"))
	if(!ishuman(target))
		target.deal_damage(100, PALE_DAMAGE, src, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)) //bit more than usual DPS in pale damage
		return
	if(target.health > 0)
		return
	var/mob/living/carbon/human/H = target
	new /obj/effect/temp_visual/human_horizontal_bisect(get_turf(H))
	H.set_lying_angle(360) //gunk code I know, but it is the simplest way to override gib_animation() without touching other code. Also looks smoother.
	H.gib()

/mob/living/simple_animal/hostile/rcorp_abno/easy/puss_in_boots/OpenFire()
	if(!can_act)
		return
	if(!client)
		if((finisher_cooldown < world.time) && prob(50))
			Execute(target)
		return
	if(chosen_attack == 1)
		return
	Execute(target)

//Death/Defeat
/mob/living/simple_animal/hostile/rcorp_abno/easy/puss_in_boots/death(gibbed)
	if(health <= 0)
		playsound(get_turf(src), 'sound/effects/limbus_death.ogg', 50, 0, 2)
	density = FALSE
	animate(src, alpha = 0, time = 5 SECONDS)
	QDEL_IN(src, 5 SECONDS)
	..()
