#define JANGSAN_FEAR_COOLDOWN (8 SECONDS)

//Jangsan is in the tank category due to his projectile absorption
//Code by Coxswain, EGO sprites by Sky_ and abnormality sprites by Mel
/mob/living/simple_animal/hostile/rcorp_abno/easy/jangsan
	name = "Jangsan Tiger"
	desc = "A monster that eats children. Reforms its face for a friendly image. It's mouth is quite large... maybe avoid getting closer if you don't feel you're strong."
	ranged = TRUE
	maxHealth = 1200
	health = 1200
	var/icon_aggro = "jangsan"
	damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1.5, PALE_DAMAGE = 2)
	see_in_dark = 10
	move_to_delay = 7
	melee_damage_type = RED_DAMAGE
	melee_damage_lower = 40
	melee_damage_upper = 60
	original_abno = /mob/living/simple_animal/hostile/abnormality/jangsan

	var/true_name = "Jangsan Tiger" //This var is just the name it reverts to, useful incase someone varedits him
	var/bullet_threshold = 300 //Normally 150 which is complete immunity against rcorp guns, raised to 300 to avoid being FFd by allies
	var/weak_counter
	var/weak_attribute = 61 //Stat amount at which you become weak
	var/weakness_required = 4 //How many counts of weakness you need to be seen as prey
	var/list/stats = list(
		FORTITUDE_ATTRIBUTE,
		PRUDENCE_ATTRIBUTE,
		TEMPERANCE_ATTRIBUTE,
		JUSTICE_ATTRIBUTE,
	)

//attack vars
	var/bite_cooldown
	var/bite_cooldown_time = 8 SECONDS
	var/chase_cooldown
	var/chase_cooldown_time = 8 SECONDS

	var/list/speak_list = list(
		";Hey guys",
		";Over here",
		";Im inside",
	)
	var/list/speak_list2 = list(
		", let's have a pizza party!",
		", i'll protect you!",
		", let's work together!",
	)

	abno_additional_instructions = "<h1>You are Jangsan Tiger, A Tank Role Abnormality.</h1><br>\
		<b>|Thick Fluffy Fur|: Projectiles will get stuck in your fur and cause zero harm if their damage is 300 or lower.<br>\
		<br>\
		|Plucked Flowers|: When attacking someone with 60 or lower on all stats you will bite their head off leading to instant death. <br>\
		<br>\
		|Beloved Mascot|: Your fear ability causes any targets with 60 stats or lower within 3 tile sightline of you to be paralyzed in fear.\
		This fear causes armor-piercing WHITE damage and stun for 5 seconds, it is easily followed up by a bite.\
		The fear ability will also mimic the voice of one random human being in a attempt to lure others into following you in the dark. \
		</b>"

//PLAYABLES ATTACKS
	attack_action_types = list(/datum/action/cooldown/rca_jangsan_fear)

/datum/action/cooldown/rca_jangsan_fear
	name = "Fear"
	icon_icon = 'icons/mob/actions/actions_abnormality.dmi'
	button_icon_state = "jangsan"
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE
	cooldown_time = JANGSAN_FEAR_COOLDOWN

/datum/action/cooldown/rca_jangsan_fear/Trigger()
	if(!..())
		return FALSE
	if(!istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/easy/jangsan))
		return FALSE
	var/mob/living/simple_animal/hostile/rcorp_abno/easy/jangsan/jangsan = owner
	StartCooldown()
	jangsan.TryFearStun()
	jangsan.LureSpeak()
	return TRUE

/mob/living/simple_animal/hostile/abnormality/jangsan/Initialize()
	. = ..()
	icon_state = "jangsan"

/mob/living/simple_animal/hostile/rcorp_abno/easy/jangsan/Moved()
	. = ..()
	playsound(get_turf(src), 'sound/abnormalities/bigbird/step.ogg', 50, 1)

//Combat
/mob/living/simple_animal/hostile/rcorp_abno/easy/jangsan/proc/FearStun(mob/living/carbon/human/H)
	H.apply_status_effect(/datum/status_effect/panicked_lvl_4)
	H.adjustSanityLoss(30)
	H.Immobilize(1 SECONDS)
	to_chat(target, span_warning("Is that what it really looks like? It's over... I can’t even move my legs..."))
	return

/mob/living/simple_animal/hostile/rcorp_abno/easy/jangsan/proc/TryFearStun()
	playsound(get_turf(src), 'sound/abnormalities/scaredycat/catgrunt.ogg', 50, 1, 2)
	for(var/mob/living/carbon/human/H in view(3, src))
		if(faction_check_mob(H, FALSE))
			continue
		if(H.stat == DEAD)
			continue
		icon_state = "jangsan_bite"
		FearStun(H)

/mob/living/simple_animal/hostile/rcorp_abno/easy/jangsan/proc/LureSpeak()
	var/list/Players = list()
	for (var/mob/living/carbon/human/H in GLOB.human_list)
		if(H.z != z) // Not on our level
			continue
		if(H.stat == DEAD) // No dead people
			continue
		if(faction_check_mob(H)) //No pinocchio
			continue
		Players += H

	if(!Players.len)
		name = pick(
			"Unassuming Friendly Guy",
			"Zeta 123",
			"Bong Bong",
			"John Lobotomy",
		)
	else
		var/Sucker = pick(Players)
		name = "[Sucker]"
	playsound(get_turf(src), 'sound/abnormalities/scaredycat/catgrunt.ogg', 50, 1, 2)
	say(pick(speak_list) + pick(speak_list2))
	name = true_name


/mob/living/simple_animal/hostile/rcorp_abno/easy/jangsan/bullet_act(obj/projectile/P)
	if(P.damage <= bullet_threshold)
		visible_message(span_userdanger("[P] is caught in [src]'s thick fur!"))
		P.Destroy()
		return
	return ..()

#undef JANGSAN_FEAR_COOLDOWN
