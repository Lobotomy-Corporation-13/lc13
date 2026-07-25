#define STATUS_EFFECT_GOLDENSHEEN /datum/status_effect/stacking/rca_golden_sheen
#define STATUS_EFFECT_MAGGOTS /datum/status_effect/stacking/rca_maggots
//Defined as a tank due to its team healing
/mob/living/simple_animal/hostile/rcorp_abno/easy/golden_apple
	name = "Golden Apple"
	desc = "A huge, grotesque apple with limbs."
	var/list/golden_apple_lines = list(
		"I didn't want to die.",
		"None of us wanted to die.",
		"......",
		"What else am I supposed to do? Is it wrong that I survived?",
		"Nhh... Aah.",
	)
	del_on_death = FALSE
	maxHealth = 1200
	health = 1200
	light_color = "D4FAF37"
	light_range = 5
	light_power = 7
	move_to_delay = 4
	melee_damage_lower = 10
	melee_damage_upper = 15
	melee_damage_type = RED_DAMAGE
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1.5, WHITE_DAMAGE = 1, BLACK_DAMAGE = 0.5, PALE_DAMAGE = 2)
	vision_range = 14
	original_abno = /mob/living/simple_animal/hostile/abnormality/golden_apple

	attack_action_types = list(/datum/action/cooldown/rca_gapple_pulse)
	var/datum/action/innate/rca_abnormality_attack/maggot_spread/maggot_attack
	var/datum/action/innate/rca_abnormality_attack/maggot_spread2/maggot_attack2

	var/is_maggot = FALSE
	var/victim_name
	var/say_chance = 7//it's pretty talkative
	var/smash_cooldown
	var/smash_cooldown_time = 15
	var/smash_damage = 12
	var/pulse_cooldown
	var/pulse_cooldown_time = 130 SECONDS//The duraction of the buff is 60 seconds; you can't build stacks at this rate.
	var/pulse_count = 0
	var/pulse_maximum = 5

	abno_additional_instructions = "<h1>You are Golden Apple, A Tank Role Abnormality.</h1><br>\
		<b>|Cracked Gold|: Every 130 seconds you will passively release a pulse of |Golden Sheen| which affects all allied abnormalities.\
		You may also manually send out a pulse however this ability has limited charges.\
		To gain additional charges you must attack a living human or rhino mech. <br>\
		<br>\
		|Golden Sheen|: When applied, this status effect will cause those affected to emit a slight golden glow.\
		For the duration of this effect those affected will passively heal 5 brute per tick, if human they will heal 0.5 brute and sanity instead.\
		Stacks of |Golden Sheen| only last 60 seconds and may be stacked up to 5, additional stacks refresh the expiry duration. \
		Both the glow effect and the heal effect are multiplied per stack of |Golden Sheen| on those affected.<br>\
		<br>\
		|Frail Core|: When killed you lose both |Cracked Gold| and your ability to apply |Golden Sheen|.\
		Upon death you will enter a stasis period, within this state you may be butchered by a knife, killing you permanently. \
		After 15 seconds of stasis you will perform |Metamorphosis|.<br>\
		<br>\
		|Metamorphosis|: Initiate a 3x3 high RED damage AoE attacked centered around yourself. \
		If a human being is taken into a critical state or killed by this attack they will be consumed.\
		Consuming a human will trigger |Together in Rot| if failing to consume one you will enter |False Apple| state after a 5 second period.<br>\
		<br>\
		|False Apple|: Your damage and speed are increased, your resistances are swapped around and your damage is changed to BLACK. \
		Your melee attack is replaced by AoE attacks, these AoE attacks come in two variants.\
		You may select which attack to perform through your abilities, the two available variants being Lunge and slam. \
		Lunge will perform a 3x4 AoE in the direction you attack, Slam will perform a 5x2 Aoe in the direction you attack. \
		If either of these AoE attacks hit a target you will inflict 1 stack of |Maggots| on impacted targets.<br>\
		<br>\
		|Maggots|: Targets inflicted by this effect will take BLACK damage equal to stack every tick. \
		This effect lasts for 15 seconds however it is refreshed whenever a new stack is applied. \
		If those affected are ared killed by the |Maggots| their body will be entirely enveloped by a pile of Maggots. <br>\
		<br>\
		|Together in Rot|: When triggered you will copy the name of the target you have eaten and have your speed and resistances greatly boosted. \
		You will also passively speak as the one you have eaten in a attempt to deceive hostiles.</b>"

/mob/living/simple_animal/hostile/rcorp_abno/easy/golden_apple/examine(mob/user)
	. = ..()
	if(stat == DEAD)
		. += "The apple's brilliant sheen has faded however it still seems alive, best butcher it."
	else if(!is_maggot)
		. += "The apple's brilliant sheen seems to fill entities around it with vigour."
	else if(victim_name)
		. += "The rotten apple seems to have grown considerably stronger from consuming [victim_name]."
	else
		. += "The rotten apple throws maggots around with every movement, best disengage if hit by them."

/datum/action/cooldown/rca_gapple_pulse
	name = "Golden sheen"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	button_icon_state = "golden_sheen_noBG"
	check_flags = AB_CHECK_CONSCIOUS
	transparent_when_unavailable = TRUE
	cooldown_time = 15 SECONDS

/datum/action/innate/rca_abnormality_attack/maggot_spread
	name = "Slam"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	button_icon_state = "maggots_noBG"
	chosen_message = span_colossus("You will now spread maggots within a wide vicinity.")
	chosen_attack_num = 1

/datum/action/innate/rca_abnormality_attack/maggot_spread2
	name = "Lunge"
	icon_icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	button_icon_state = "maggots_noBG"
	chosen_message = span_colossus("You will now spread maggots within a narrow vicinity.")
	chosen_attack_num = 2

/datum/action/cooldown/rca_gapple_pulse/Trigger()
	if(!..())
		return FALSE
	if(!istype(owner, /mob/living/simple_animal/hostile/rcorp_abno/easy/golden_apple))
		return FALSE
	var/mob/living/simple_animal/hostile/rcorp_abno/easy/golden_apple/apple = owner
	if(apple.is_maggot == TRUE)//False apple shouldn't have this ability
		return FALSE
	if(apple.pulse_count == 0)
		to_chat(owner, span_warning("You cannot activate this due to a lack of charges. Attack a hostile target to gain more charges."))
		return FALSE
	apple.pulse_count -= 1
	StartCooldown()
	apple.HealPulse(TRUE)
	to_chat(owner, span_warning("You have [apple.pulse_count] charges remaining."))
	return TRUE

//***Simple Mob Procs***
/mob/living/simple_animal/hostile/rcorp_abno/easy/golden_apple/Initialize()
	icon_state = "gold_apple"
	icon_living = "gold_apple"
	maggot_attack = new /datum/action/innate/rca_abnormality_attack/maggot_spread
	maggot_attack2 = new /datum/action/innate/rca_abnormality_attack/maggot_spread2
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/golden_apple/Life()
	. = ..()
	if(!.)
		return
	if((pulse_cooldown < world.time) && !is_maggot)//First form's regular heal pulse
		HealPulse()
		return
	if(!victim_name)//Automated speech if it's killed someone while tranforming
		return
	if(!prob(say_chance))
		return
	var/line = pick(golden_apple_lines)
	say(line)

/mob/living/simple_animal/hostile/rcorp_abno/easy/golden_apple/say(message as text, language, ignore_spam, forced, sanitize, spans)//UNDER CONSIDERATION: give it access to comms for R corp assault
	if(!victim_name)//Has it killed anyone while transforming?
		return ..()
	name = victim_name
	..()
	name = "False Apple"

/mob/living/simple_animal/hostile/rcorp_abno/easy/golden_apple/proc/HealPulse(manual = FALSE)
	if(manual == FALSE)//Only triggers the cooldown if it's called from life() ticks
		pulse_cooldown = world.time + pulse_cooldown_time
	playsound(src, 'sound/abnormalities/goldenapple/Gold_Sparkle.ogg', 50, 1)
	for(var/mob/living/L in livinginview(12, src))
		var/datum/status_effect/stacking/rca_golden_sheen/G = L.has_status_effect(/datum/status_effect/stacking/rca_golden_sheen)
		if(!faction_check_mob(L))
			continue
		if(!G)
			L.apply_status_effect(STATUS_EFFECT_GOLDENSHEEN)
		else
			G.add_stacks(1)
			G.refresh()

//switch to the second form if var is_maggot is 0
/mob/living/simple_animal/hostile/rcorp_abno/easy/golden_apple/death()
	if(health > 0)
		return
	if(!is_maggot)
		playsound(src, 'sound/abnormalities/goldenapple/Gold_Attack.ogg', 100, 1)
		addtimer(CALLBACK(src, PROC_REF(EatEmployees)), 15 SECONDS)
		return ..()
	density = FALSE
	for(var/atom/movable/AM in src) //morph code
		AM.forceMove(loc)
	playsound(src, 'sound/abnormalities/goldenapple/False_Dead.ogg', 100, 1)
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)
	..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/golden_apple/proc/HandleAbiltyButtons()
	for(var/action_type in actions)
		var/datum/action/dostuff = action_type
		dostuff.Remove(src)
	maggot_attack.Grant(src)
	maggot_attack2.Grant(src)
	if(small_sprite_type)
		var/datum/action/small_sprite/small_action = new small_sprite_type()
		small_action.Grant(src)

/mob/living/simple_animal/hostile/rcorp_abno/easy/golden_apple/proc/BecomeRotten()//phase 2
	if(QDELETED(src))
		return
	if(is_maggot)//prevents the proc from being spammed
		return
	//I dont know why but for some reason revive resets move_to_delay -IP
	HandleAbiltyButtons()
	revive(full_heal = TRUE, admin_revive = FALSE)
	playsound(src, 'sound/abnormalities/goldenapple/Gold_Falsify.ogg', 50, 1)//it's very loud
	icon = 'ModularLobotomy/_Lobotomyicons/96x48.dmi'
	icon_state = "false_apple"
	icon_living = "false_apple"
	icon_dead = "false_dead"
	death_message = "is reduced to a primordial egg."
	name = "False Apple"
	desc = "The apple ruptured and a swarm of maggots crawled inside, metamorphosing into a hideous face."
	pixel_x = -32
	pixel_y = 0
	light_range = 0
	light_power = 0
	attack_sound = "sound/abnormalities/goldenapple/False_Attack3.ogg"
	melee_damage_lower = 30
	melee_damage_upper = 45
	melee_reach = 2
	attack_verb_continuous = "pummels"
	attack_verb_simple = "pummel"
	ChangeResistances(list(RED_DAMAGE = 1.5, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 1, PALE_DAMAGE = 0.5))
	melee_damage_type = BLACK_DAMAGE
	is_maggot = TRUE
	ChangeMoveToDelayBy(-1)

/mob/living/simple_animal/hostile/rcorp_abno/easy/golden_apple/AttackingTarget(atom/attacked_target)//regular attacks or AOE. Determines the outcome for both players and the AI behavior
	if(!can_act)
		return FALSE
	if(!is_maggot)//Is it still in the first form? Start building sheen pulses
		if(pulse_count < pulse_maximum)
			if(isliving(attacked_target))
				var/mob/living/hit = attacked_target
				if((hit.stat == DEAD) ||!ishuman(hit))//if the target is dead or not human
					return ..()
				if(istype(hit, /mob/living/carbon/human/species/pinocchio)) //Will have to change to rca pino later
					return ..()
				pulse_count += 1
			if(ismecha(attacked_target))
				var/inhabited = FALSE
				for(var/mob/living/L in attacked_target.contents)
					if(L.stat == DEAD)
						continue
					inhabited = TRUE
				if(!inhabited)
					return ..()
				pulse_count += 1
		return ..()
	if(client && smash_cooldown < world.time)//playable behavior is nested under here
		switch(chosen_attack)
			if(1)
				Smash(attacked_target)
			if(2)
				Smash(attacked_target, wide = FALSE)
		return
	if(prob(50) && (smash_cooldown < world.time))//AI behavior goes here
		Smash(attacked_target, wide = pick(TRUE, FALSE))
		return
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/easy/golden_apple/proc/EatEmployees()
	var/last_target
	var/target_hit
	can_act = FALSE
	playsound(get_turf(src), 'sound/abnormalities/goldenapple/False_Attack2.ogg', 100, 0, 5)
	for(var/turf/T in view(1, src))
		new /obj/effect/temp_visual/smash_effect(T)
		for(var/mob/living/carbon/L in HurtInTurf(T, list(), 200, RED_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)))
			if(L.stat >= SOFT_CRIT)
				if(!last_target)//only the last person killed counts
					L.forceMove(src)
					last_target = TRUE
					target_hit = TRUE
					addtimer(CALLBACK(src, PROC_REF(DigestPerson), L), 5 SECONDS)
				else
					L.gib(TRUE, TRUE, TRUE)
		if (!target_hit)
			addtimer(CALLBACK(src, PROC_REF(BecomeRotten)), 5 SECONDS)//if nobody got killed
	can_act = TRUE

/mob/living/simple_animal/hostile/rcorp_abno/easy/golden_apple/proc/DigestPerson(mob/living/carbon/human/H)//berserk mode
	victim_name = "Yuri"
	maxHealth = 1500
	BecomeRotten()
	ChangeMoveToDelayBy(-0.5)
	ChangeResistances(list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 0.3))
	if(H)
		victim_name = H.real_name
		NestedItems(src, H.get_item_by_slot(ITEM_SLOT_SUITSTORE))
		NestedItems(src, H.get_item_by_slot(ITEM_SLOT_BELT))
		NestedItems(src, H.get_item_by_slot(ITEM_SLOT_BACK))
		NestedItems(src, H.get_item_by_slot(ITEM_SLOT_OCLOTHING))
		var/obj/item/bodypart/head/myhead = H.get_bodypart(BODY_ZONE_HEAD)
		if(myhead)
			myhead.dismember()
			NestedItems(src, myhead)
		QDEL_IN(H, 1)
	desc = "The apple ruptured and a swarm of maggots crawled inside.. wait a minute, that's [victim_name]'s face."
	med_hud_set_health()//took a page from smock to update medhuds
	med_hud_set_status()
	update_health_hud()

/mob/living/simple_animal/hostile/rcorp_abno/easy/golden_apple/proc/NestedItems(mob/living/simple_animal/hostile/nest, obj/item/nested_item)
	if(nested_item)
		nested_item.forceMove(nest)

//AoE attack taken from woodsman, applies maggots DOT
/mob/living/simple_animal/hostile/rcorp_abno/easy/golden_apple/proc/Smash(target, wide = TRUE)
	if (!client && (get_dist(src, target) > 4))
		return
	smash_cooldown = world.time + smash_cooldown_time
	var/dir_to_target = get_cardinal_dir(get_turf(src), get_turf(target))
	var/turf/source_turf = get_turf(src)
	var/turf/area_of_effect = list()
	var/turf/middle_line = list()
	var/upline = NORTH
	var/downline = SOUTH
	var/smash_length = 2
	var/smash_width = 2
	if(wide)
		playsound(get_turf(src), 'sound/abnormalities/goldenapple/False_Attack.ogg', 50, 0, 5)
	else
		playsound(get_turf(src), 'sound/abnormalities/goldenapple/False_Attack2.ogg', 50, 0, 5)
		smash_length = 4
		smash_width = 1
	middle_line = getline(source_turf, get_ranged_target_turf(source_turf, dir_to_target, smash_length))
	if(dir_to_target == NORTH || dir_to_target == SOUTH)
		upline = EAST
		downline = WEST
	for(var/turf/T in middle_line)
		if(T.density)
			break
		for(var/turf/Y in getline(T, get_ranged_target_turf(T, upline, smash_width)))
			if (Y.density)
				break
			if (Y in area_of_effect)
				continue
			area_of_effect += Y
		for(var/turf/U in getline(T, get_ranged_target_turf(T, downline, smash_width)))
			if (U.density)
				break
			if (U in area_of_effect)
				continue
			area_of_effect += U
	if(!dir_to_target)
		for(var/turf/TT in view(1, src))
			if (TT.density)
				break
			if (TT in area_of_effect)
				continue
			area_of_effect |= TT
	if (!LAZYLEN(area_of_effect))
		return
	can_act = FALSE
	dir = dir_to_target
	for(var/turf/T in area_of_effect)
		new /obj/effect/temp_visual/smash_effect(T)
		for(var/mob/living/L in HurtInTurf(T, list(), smash_damage, BLACK_DAMAGE, check_faction = TRUE, hurt_mechs = TRUE, attack_type = (ATTACK_TYPE_MELEE | ATTACK_TYPE_SPECIAL)))
			var/datum/status_effect/stacking/maggots/G = L.has_status_effect(/datum/status_effect/stacking/rca_maggots)
			if(!G)
				L.apply_status_effect(STATUS_EFFECT_MAGGOTS)
			else
				G.add_stacks(1)
				G.refresh()
	SLEEP_CHECK_DEATH(0.5 SECONDS)
	can_act = TRUE

//***Buff Definitions***
//For now, just a notification. If we ever want to do anything with it, it's here.
/datum/status_effect/stacking/rca_golden_sheen
	id = "sheen"
	status_type = STATUS_EFFECT_MULTIPLE
	duration = 60 SECONDS	//Lasts for a minute
	max_stacks = 5
	stacks = 1
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/rca_golden_sheen
	consumed_on_threshold = FALSE
	var/obj/item/rca_glow_object/glowstuff

/atom/movable/screen/alert/status_effect/rca_golden_sheen
	name = "Golden Sheen"
	desc = "Your body radiates the very same glow as the Golden Apple. You will be highlighted but also passively heal."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "golden_sheen"

/datum/status_effect/stacking/rca_golden_sheen/on_apply()
	glowstuff = new /obj/item/rca_glow_object(owner)
	return ..()

/datum/status_effect/stacking/rca_golden_sheen/on_remove()
	qdel(glowstuff)
	return ..()

/datum/status_effect/stacking/rca_golden_sheen/add_stacks()
	glowstuff.set_light(3, (stacks * 2), "D4FAF37")
	return ..()

/datum/status_effect/stacking/rca_golden_sheen/tick()//TODO:change this to golden apple's life tick for less lag
	if(isanimal(owner))
		owner.adjustBruteLoss(stacks * -5)
		return
	owner.adjustBruteLoss(stacks * -0.5)
	var/mob/living/carbon/human/status_holder = owner
	status_holder.adjustSanityLoss(stacks * -0.5)

/obj/item/rca_glow_object //Normally Id take it from the parent, but I might need to change glow level later incase of balanceslop
	name = "golden apple core"
	desc = "You shouldn't be able to see this."
	light_range = 3
	light_power = 2
	light_color = "D4FAF37"
	light_on = TRUE

//debuff definition

/datum/status_effect/stacking/rca_maggots
	id = "maggots"
	status_type = STATUS_EFFECT_MULTIPLE
	duration = 15 SECONDS	//Lasts for 15 seconds and refreshes when reapplied
	max_stacks = 10
	stacks = 1
	on_remove_on_mob_delete = TRUE
	alert_type = /atom/movable/screen/alert/status_effect/rca_maggots
	consumed_on_threshold = FALSE

/atom/movable/screen/alert/status_effect/rca_maggots
	name = "Maggots"
	desc = "Eugh! Get them off! Take constant stacking black damage, this will continue until effect is allowed to expire."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "maggots"

/datum/status_effect/stacking/rca_maggots/on_apply()
	to_chat(owner, span_warning("You're covered in squirming maggots!"))
	return ..()

/datum/status_effect/stacking/rca_maggots/tick()//change this to golden apple's life tick for less lag
	var/mob/living/carbon/human/status_holder = owner
	status_holder.deal_damage(stacks, BLACK_DAMAGE, attack_type = (ATTACK_TYPE_STATUS))
	if(status_holder.stat < HARD_CRIT)
		return
	var/obj/structure/spider/cocoon/casing = new(status_holder.loc)
	status_holder.forceMove(casing)
	casing.name = "pile of maggots"
	casing.desc = "They're wriggling and writhing over something."
	casing.icon_state = pick(
		"cocoon_large1",
		"cocoon_large2",
		"cocoon_large3",
	)
	casing.density = FALSE
	casing.color = "#01F9C6"
	qdel(src)

#undef STATUS_EFFECT_GOLDENSHEEN
#undef STATUS_EFFECT_MAGGOTS
