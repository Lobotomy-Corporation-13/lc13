#define STATUS_EFFECT_OVERWHELMING_FEAR_RCA /datum/status_effect/rca_overwhelming_fear
//Tank role because of
//Large HP pool
//Self healing
//Considered too strong for combat
/mob/living/simple_animal/hostile/rcorp_abno/hard/censored
	name = "CENSORED"
	desc = "What is this... It's too disgusting to even look at... If that thing touches you... You cant even imagine..."
	/* Stats */
	health = 2900
	maxHealth = 2900
	damage_coeff = list(RED_DAMAGE = 0.6, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 0.4, PALE_DAMAGE = 1)
	melee_damage_type = BLACK_DAMAGE
	melee_damage_lower = 75
	melee_damage_upper = 85
	move_to_delay = 3
	ranged = TRUE
	original_abno = /mob/living/simple_animal/hostile/abnormality/censored

	var/ability_damage = 120 //Wiped 5th pack too hard so lower damage
	var/ability_cooldown
	var/ability_cooldown_time = 6 SECONDS //Lower damage means lower cooldown

	abno_additional_instructions = "<h1>You are CENSORED, A Tank Role Abnormality.</h1><br>\
		<b>|'CENSORED, CENSORED'|: When you click on a tile outside your melee range, you will trigger your ranged attack.<br>\
		When you trigger your ranged attack, there will be a short delay before you will send out a 'CENSORED' towards your target tile.<br>\
		Anyone who is hit by your 'CENSORED' will take BLACK damage and will gain the statues effect 'Overwhelming Fear'<br>\
		If you don't want to trigger you ranged attack when clicking on a tile, you can hold SHIFT while clicking on a tile to disable it.<br>\
		<br>\
		|Overwhelming Fear|: Humans with this statues effect will have their sanity quickly reduce to 30%, And this statues effect lasts for 20 seconds.<br>\
		<br>\
		|'...CENSORED?'|: When you attack a dead human, you will convert them into a mini 'CENSORED'.<br>\
		While converting you take no damage, each time you convert a human into a mini 'CENSORED' you heal 10% of your max HP.<br>\
		However, Once a mini 'CENSORED' is killed, all humans around them heal 40% of their SP.</b>"

/mob/living/simple_animal/hostile/rcorp_abno/hard/censored/Initialize()
	. = ..()
	icon_living = "censored_breach"
	icon_state = icon_living

/mob/living/simple_animal/hostile/rcorp_abno/hard/censored/Life()
	. = ..()
	if(!.)
		return
	// Apply and refresh status effect to all humans nearby
	for(var/mob/living/carbon/human/H in view(7, src))
		if(H.stat == DEAD)
			continue
		if(faction_check_mob(H))
			continue
		H.apply_status_effect(STATUS_EFFECT_OVERWHELMING_FEAR_RCA)

/* Combat */
/mob/living/simple_animal/hostile/rcorp_abno/hard/censored/Move()
	if(!can_act)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/censored/Moved()
	. = ..()
	for(var/mob/living/carbon/human/H in view(1, src))
		if(H.stat >= SOFT_CRIT || H.health < 0)
			Convert(H)
			break

/mob/living/simple_animal/hostile/rcorp_abno/hard/censored/CanAttack(atom/the_target)
	if(isliving(the_target) && !ishuman(the_target))
		var/mob/living/L = the_target
		if(L.stat == DEAD)
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/censored/AttackingTarget(atom/attacked_target)
	. = ..()
	if(!can_act)
		return

	if(!ishuman(attacked_target))
		return

	var/mob/living/carbon/human/H = attacked_target
	if(H.stat >= SOFT_CRIT || H.health < 0)
		return Convert(H)

	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/censored/OpenFire()
	if(!can_act)
		return

	if(client)
		switch(chosen_attack)
			if(1)
				RangedAbility(target)
		return

	if(ability_cooldown <= world.time && prob(50))
		RangedAbility(target)

	return

/mob/living/simple_animal/hostile/rcorp_abno/hard/censored/proc/Convert(mob/living/carbon/human/H)
	if(!istype(H))
		return
	if(!can_act)
		return
	can_act = FALSE
	forceMove(get_turf(H))
	ChangeResistances(list(RED_DAMAGE = 0, WHITE_DAMAGE = 0, BLACK_DAMAGE = 0, PALE_DAMAGE = 0))
	playsound(src, 'sound/abnormalities/censored/convert.ogg', 45, FALSE, 5)
	SLEEP_CHECK_DEATH(3)
	new /obj/effect/temp_visual/censored(get_turf(src))
	for(var/i = 1 to 3)
		new /obj/effect/gibspawner/generic/silent(get_turf(src))
		SLEEP_CHECK_DEATH(5.5)
	var/mob/living/simple_animal/hostile/rca_mini_censored/C = new(get_turf(src))
	if(!QDELETED(H))
		C.desc = "What the hell is this? It shouldn't exist... On the second thought, it reminds you of [H.real_name]..."
		H.gib()
	ChangeResistances(list(RED_DAMAGE = 0.6, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 0.4, PALE_DAMAGE = 1))
	adjustBruteLoss(-(maxHealth*0.1))
	can_act = TRUE

/mob/living/simple_animal/hostile/rcorp_abno/hard/censored/proc/RangedAbility(atom/target)
	if(!can_act)
		return
	if(world.time < ability_cooldown)
		return
	can_act = FALSE
	ability_cooldown = world.time + ability_cooldown_time
	var/turf/T = get_ranged_target_turf_direct(src, get_turf(target), 10, rand(-10,10))
	var/list/turf_list = list()
	playsound(src, 'sound/abnormalities/censored/ability.ogg', 50, FALSE, 5)
	for(var/turf/TT in getline(src, T))
		if(TT.density)
			break
		new /obj/effect/temp_visual/cult/sparks(TT)
		turf_list += TT
		T = TT
	if(!LAZYLEN(turf_list))
		can_act = TRUE
		return
	for(var/i = 1 to 3)
		var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(get_turf(src), src)
		D.alpha = 100
		D.pixel_x = base_pixel_x + rand(-8, 8)
		D.pixel_y = base_pixel_y + rand(-8, 8)
		animate(D, alpha = 0, transform = matrix()*1.2, time = 8)
		SLEEP_CHECK_DEATH(0.15 SECONDS)
	SLEEP_CHECK_DEATH(0.3 SECONDS)
	Beam(T, "censored", time = 10)
	playsound(src, 'sound/weapons/ego/censored3.ogg', 75, FALSE, 5)
	for(var/turf/TT in turf_list)
		for(var/mob/living/L in HurtInTurf(TT, list(), ability_damage, BLACK_DAMAGE, null, TRUE, FALSE, TRUE, hurt_structure = TRUE, attack_type = (ATTACK_TYPE_RANGED | ATTACK_TYPE_SPECIAL)))
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(L), pick(GLOB.alldirs))
			L.apply_status_effect(STATUS_EFFECT_OVERWHELMING_FEAR_RCA)
	can_act = TRUE

/* The mini censoreds */
/mob/living/simple_animal/hostile/rca_mini_censored
	name = "???"
	desc = "What the hell is this? It shouldn't exist..."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "censored_mini"
	icon_living = "censored_mini"
	speak_emote = list("screeches")
	attack_verb_continuous = "attacks"
	attack_verb_simple = "attack"
	attack_sound = 'sound/abnormalities/censored/mini_attack.ogg'
	/* Stats */
	health = 600
	maxHealth = 600
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 1)
	melee_damage_type = BLACK_DAMAGE
	melee_damage_lower = 25
	melee_damage_upper = 30
	speed = 2
	move_to_delay = 2
	robust_searching = TRUE
	stat_attack = HARD_CRIT
	del_on_death = TRUE
	density = TRUE
	var/recoved_sanity = 0.2

/mob/living/simple_animal/hostile/rca_mini_censored/Login()
	. = ..()
	to_chat(src, "<h1>You are a ???, A CENSORED Minion.</h1><br>\
		<b>|Face the Fear|: When killed you recover 20% of max SP for all humans within a 5 tile sightline of yourself.</b>")

/mob/living/simple_animal/hostile/rca_mini_censored/Initialize()
	. = ..()
	playsound(get_turf(src), 'sound/abnormalities/censored/mini_born.ogg', 50, 1, 4)
	base_pixel_x = rand(-6,6)
	pixel_x = base_pixel_x
	base_pixel_y = rand(-6,6)
	pixel_y = base_pixel_y

/mob/living/simple_animal/hostile/mini_censored/Life()
	. = ..()
	if(!.) // Dead
		return FALSE
	for(var/i = 1 to 2)
		addtimer(CALLBACK(src, PROC_REF(ShakePixels)), i*5 + rand(1, 4))
	ShakePixels()
	FearEffect()
	return

/mob/living/simple_animal/hostile/rca_mini_censored/proc/ShakePixels()
	animate(src, pixel_x = base_pixel_x + rand(-3, 3), pixel_y = base_pixel_y + rand(-3, 3), time = 2)
	return

/mob/living/simple_animal/hostile/rca_mini_censored/death(gibbed)
	for(var/mob/living/carbon/human/H in view(5, src))
		if(H.stat == DEAD)
			continue
		if(faction_check_mob(H))
			continue
		H.adjustSanityLoss(-(H.getMaxSanity() * recoved_sanity))
		playsound(H, 'sound/abnormalities/voiddream/skill.ogg', 40, TRUE, 2)
		to_chat(H, span_nicegreen("Good... It is now dead. You feel saner."))
	return ..()

// Status effect applied by CENSORED
/datum/status_effect/rca_overwhelming_fear
	id = "rca_overwhelming_fear"
	status_type = STATUS_EFFECT_REFRESH
	duration = 20 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/rca_overwhelming_fear
	/// The damage will not be done below that percentage of max sanity
	var/sanity_limit_percent = 0.3
	/// How much percents of max sanity is dealt as pure sanity damage each tick
	var/sanity_damage_percent = 0.05

/atom/movable/screen/alert/status_effect/rca_overwhelming_fear
	name = "Overwhelming Fear"
	desc = "You find it difficult to recollect yourself. Your sanity will be slowly lowering to 30%."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "overwhelming_fear"

/datum/status_effect/rca_overwhelming_fear/on_apply()
	if(!ishuman(owner))
		return FALSE
	return ..()

/datum/status_effect/rca_overwhelming_fear/tick()
	. = ..()
	var/mob/living/carbon/human/status_holder = owner
	if(status_holder.getSanityLoss() >= status_holder.getMaxSanity() * sanity_limit_percent)
		return
	status_holder.adjustSanityLoss(status_holder.getMaxSanity() * sanity_damage_percent)

#undef STATUS_EFFECT_OVERWHELMING_FEAR_RCA
