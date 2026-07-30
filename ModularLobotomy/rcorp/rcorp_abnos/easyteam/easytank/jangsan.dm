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

/mob/living/simple_animal/hostile/rcorp_abno/easy/jangsan/proc/StatCheck(mob/living/carbon/human/user)
	weak_counter = 0 //Counts how many stats are below 61 AKA level 3
	for(var/attribute in stats)
		if(get_attribute_level(user, attribute)< weak_attribute)
			weak_counter += 1
	return

/mob/living/simple_animal/hostile/rcorp_abno/easy/jangsan/funpet(mob/petter)
	KillCheck(petter)

//Combat
/mob/living/simple_animal/hostile/rcorp_abno/easy/jangsan/CanAttack(atom/the_target)
	if(!ishuman(the_target))
		return ..()

	var/mob/living/carbon/human/H = the_target
	var/obj/item/bodypart/head/head = H.get_bodypart("head")
	if(!istype(head)) // You, I'm afraid, are headless
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/jangsan/AttackingTarget(atom/attacked_target)
	if(bite_cooldown < world.time)
		KillCheck(attacked_target)
	icon_state = icon_aggro
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/jangsan/proc/KillCheck(mob/living/target)
	if(!ishuman(target))
		return
	if(target.status_flags & GODMODE)
		return
	var/mob/living/carbon/human/H = target
	StatCheck(H)
	if(weak_counter >= weakness_required)
		var/obj/item/bodypart/head/head = H.get_bodypart("head")
		if(QDELETED(head))
			return
		head.dismember()
		QDEL_NULL(head)
		H.regenerate_icons()
		visible_message(span_danger("\The [src] bites [H]'s head off!"))
		new /obj/effect/gibspawner/generic/silent(get_turf(H))
		new /obj/effect/halo(get_turf(H))
		playsound(get_turf(src), 'sound/abnormalities/bigbird/bite.ogg', 50, 1, 2)
		return

/mob/living/simple_animal/hostile/rcorp_abno/easy/jangsan/proc/FearStun(mob/living/carbon/human/H)
	H.apply_status_effect(/datum/status_effect/panicked_lvl_4)
	H.adjustSanityLoss(-50)
	H.Stun(5 SECONDS)
	to_chat(target, span_warning("Is that what it really looks like? It's over... I can’t even move my legs..."))
	return

/mob/living/simple_animal/hostile/rcorp_abno/easy/jangsan/proc/TryFearStun()
	playsound(get_turf(src), 'sound/abnormalities/scaredycat/catgrunt.ogg', 50, 1, 2)
	for(var/mob/living/carbon/human/H in view(3, src))
		StatCheck(H)
		if(faction_check_mob(H, FALSE))
			continue
		if(H.stat == DEAD)
			continue
		if(weak_counter >= weakness_required)
			icon_state = "jangsan_bite"
			FearStun(H)
			chase_cooldown = world.time + chase_cooldown_time
			break

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

//targetting
/mob/living/simple_animal/hostile/rcorp_abno/easy/jangsan/PickTarget(list/Targets) //Stolen from MOSB
	var/list/highest_priority = list()
	var/list/lower_priority = list()
	for(var/mob/living/L in Targets)
		if(!CanAttack(L))
			continue
		if(ishuman(L))
			StatCheck(L)
			if(weak_counter >= weakness_required)
				highest_priority += L
			else
				lower_priority += L
		else
			lower_priority += L
	if(LAZYLEN(highest_priority))
		return pick(highest_priority)
	if(LAZYLEN(lower_priority))
		return pick(lower_priority)
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/jangsan/MoveToTarget(list/possible_targets)
	if(ishuman(target))
		if(chase_cooldown > world.time)
			return ..()
		var/mob/living/carbon/human/H = target
		StatCheck(H)
		if(weak_counter >= weakness_required && get_dist(src, target) < 4) //clerk got too close time to die
			icon_state = "jangsan_bite"
			FearStun(target)
			chase_cooldown = world.time + chase_cooldown_time
			return ..()
	icon_state = icon_aggro
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/jangsan/bullet_act(obj/projectile/P)
	if(P.damage <= bullet_threshold)
		visible_message(span_userdanger("[P] is caught in [src]'s thick fur!"))
		P.Destroy()
		return
	return ..()

#undef JANGSAN_FEAR_COOLDOWN
