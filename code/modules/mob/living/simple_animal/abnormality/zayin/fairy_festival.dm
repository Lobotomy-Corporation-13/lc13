/mob/living/simple_animal/hostile/abnormality/fairy_festival
	name = "Fairy Festival"
	desc = "The abnormality is similar to a fairy, having two pairs of wings and a small body. The small fairies around it act as a cluster."
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "fairy"
	icon_living = "fairy"
	portrait = "fairy_festival"
	core_icon = "fairy"
	maxHealth = 800
	health = 800
	move_to_delay = 5
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 1.3, PALE_DAMAGE = 2)
	melee_damage_lower = 8
	melee_damage_upper = 15
	stat_attack = DEAD
	attack_sound = 'sound/abnormalities/fairyfestival/fairyqueen_hit.ogg'
	is_flying_animal = TRUE
	threat_level = ZAYIN_LEVEL
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 70,
		ABNORMALITY_WORK_INSIGHT = list(50, 40, 30, 30, 30),
		ABNORMALITY_WORK_ATTACHMENT = list(70, 60, 50, 50, 50),
		ABNORMALITY_WORK_REPRESSION = list(50, 40, 30, 30, 30),
	)
	work_damage_amount = 6
	work_damage_type = RED_DAMAGE
	max_boxes = 10

	ego_list = list(
		/datum/ego_datum/weapon/wingbeat,
		/datum/ego_datum/armor/wingbeat,
	)
	gift_type =  /datum/ego_gifts/wingbeat
	gift_message = "Fairy Dust covers your hands..."

	var/summon_count = 0
	var/summon_type = /mob/living/simple_animal/hostile/mini_fairy
	var/summon_cooldown
	var/summon_cooldown_time = 30 SECONDS
	var/seek_cooldown
	var/seek_cooldown_time = 10 SECONDS
	var/summon_group_size = 6
	var/summon_maximum = 0
	var/eat_threshold = 0.8
	abnormality_origin = ABNORMALITY_ORIGIN_LOBOTOMY

	grouped_abnos = list(
		/mob/living/simple_animal/hostile/abnormality/fairy_gentleman = 1.5,
		/mob/living/simple_animal/hostile/abnormality/fairy_longlegs = 1.5,
		/mob/living/simple_animal/hostile/abnormality/faelantern = 1.5,
	)

	chem_type = /datum/reagent/abnormality/fairy_festival
	harvest_phrase = span_notice("A fairy presents you a small flower, then pours its contents into %VESSEL.")
	harvest_phrase_third = "A fairy presents %PERSON with a small flower, then pours it into %VESSEL."

	observation_prompt = "A gaggle of fairies flitter to and fro about the containment cell, they giggle as you approach.<br>\
		\"You're a peaceful child, aren't you? You're lucky to accept our care.\" <br>\
		They say in a sing-song all around you. \"Only good people ever speak to us, you're a good person too, right?\""
	observation_choices = list(
		"Accept their care" = list(TRUE, "The fairies sprinkle their powder around you and it collects upon your hands. <br>You feel special. <br>\
			You retreat from the cell and the fairies' hungry gazes. <br>You've always known the true meaning of The Fairies' Care."),
	)

/mob/living/simple_animal/hostile/abnormality/fairy_festival/SuccessEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(user.stat != DEAD && istype(user))
		if(user.has_status_effect(/datum/status_effect/fairy_care))
			return
		flick("fairy_blessing",src)
		user.apply_status_effect(/datum/status_effect/fairy_care)
	return

/mob/living/simple_animal/hostile/abnormality/fairy_festival/NeutralEffect(mob/living/carbon/human/user, work_type, pe)
	SuccessEffect(user, work_type, pe)
	return

/mob/living/simple_animal/hostile/abnormality/fairy_festival/Life()
	. = ..()
	if(summon_count >= summon_maximum)
		return
	if((summon_cooldown < world.time) && !(status_flags & GODMODE))
		SummonGuys(summon_type)

/mob/living/simple_animal/hostile/abnormality/fairy_festival/BreachEffect(mob/living/carbon/human/user, breach_type)
	if(breach_type == BREACH_PINK)
		summon_cooldown_time = 20 SECONDS
		summon_maximum = 15
		SummonGuys(summon_type)
	if(breach_type == BREACH_MINING)
		can_breach = TRUE
		summon_type = /mob/living/simple_animal/hostile/fairy_mass
		summon_group_size = 1
		summon_maximum = 4
		SummonGuys(summon_type)
		icon = 'ModularLobotomy/_Lobotomyicons/96x48.dmi'
		icon_state = "fairy_queen"
		pixel_x = -16
		maxHealth = 500
		playsound(get_turf(src), "sound/abnormalities/seasons/fall_change.ogg", 100, FALSE)
		playsound(get_turf(src), "sound/abnormalities/fairyfestival/fairyqueen_growl.ogg", 100, FALSE)
	return ..()

/mob/living/simple_animal/hostile/abnormality/fairy_festival/AttackingTarget(atom/attacked_target)
	. = ..()
	if(summon_type != /mob/living/simple_animal/hostile/fairy_mass)//does she have fairy masses?
		return
	if(istype(attacked_target, /mob/living/simple_animal/hostile/fairy_mass))
		var/mob/living/L = attacked_target
		if(L.health > 0)//fairies have to be alive; scarred meat isn't tasty
			L.gib(TRUE,TRUE,TRUE)
			ProcessKill()
			playsound(get_turf(src), "sound/abnormalities/fairyfestival/fairyqueen_growl.ogg", 100, FALSE)
			return
		eat_threshold -= 0.2
	if(. && isliving(attacked_target))
		var/mob/living/L = attacked_target
		if(isliving(attacked_target) && (L.health < 0 || L.stat == DEAD))
			playsound(get_turf(src), "sound/abnormalities/fairyfestival/fairyqueen_growl.ogg", 100, FALSE)
			if(ishuman(L))
				ProcessKill()
			L.gib(TRUE,TRUE,TRUE)

//Cannibalism
/mob/living/simple_animal/hostile/abnormality/fairy_festival/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(summon_type != /mob/living/simple_animal/hostile/fairy_mass)//does she have fairy masses?
		return
	if(health < (maxHealth * eat_threshold)) //80% health or lower, 20% less for each eat.
		var/fairy_hp = 300
		var/mob/living/mytarget
		if(seek_cooldown < world.time)//this check can only be done once every ten seconds, for performance
			for(var/mob/living/simple_animal/hostile/fairy_mass/M in range(12, src))//finds the fairy with the lowest HP in the vicinity
				if(M.health <= 0)
					mytarget = M
					break
				if(M.health <= fairy_hp)
					fairy_hp = M.health
					mytarget = M
			if(mytarget)
				mytarget.faction = list("neutral")
				LoseTarget()
				GiveTarget(mytarget)
			seek_cooldown = world.time + seek_cooldown_time

/mob/living/simple_animal/hostile/abnormality/fairy_festival/proc/SummonGuys(summon_type)
	summon_cooldown = world.time + summon_cooldown_time
	var/mob/living/simple_animal/hostile/ordeal/pink_midnight/pink = locate() in GLOB.mob_living_list
	for(var/i = 1 to summon_group_size)
		var/turf/target_turf = get_turf(pink ? pink : src)
		var/mob/living/simple_animal/hostile/mini_fairy/new_fairy
		new_fairy = new summon_type(target_turf)
		summon_count += 1
		if(pink)
			new_fairy.faction += "pink_midnight"

/mob/living/simple_animal/hostile/abnormality/fairy_festival/proc/ProcessKill()
	eat_threshold -= 0.2
	adjustBruteLoss(-maxHealth)//FRESH MEAT!
	playsound(get_turf(src), "sound/abnormalities/fairyfestival/fairyqueen_growl.ogg", 100, FALSE)
	if(move_to_delay>1)
		ChangeMoveToDelayBy(-1)

/*------------\
|Status Effect|
\------------*/
/datum/status_effect/fairy_care
	id = "fairy care"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 120 SECONDS
	tick_interval = 2 SECONDS
	alert_type = null
	on_remove_on_mob_delete = TRUE
	var/heal_amount = 0.05
	var/leftover_duration
	var/healing = TRUE
	var/image/fairy_overlay

/datum/status_effect/fairy_care/on_apply()
	. = ..()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/status_holder = owner
	ApplyFairyOverlay()
	RegisterSignal(status_holder, COMSIG_WORK_STARTED, PROC_REF(FairyPause))
	RegisterSignal(status_holder, COMSIG_WORK_COMPLETED, PROC_REF(FairyRestart))
	to_chat(status_holder, span_nicegreen("You feel at peace under the fairies' care."))
	playsound(get_turf(status_holder), 'sound/abnormalities/fairyfestival/fairylaugh.ogg', 50, 0, 2)

/datum/status_effect/fairy_care/tick()
	if(owner.stat != DEAD)
		if(healing)
			var/mob/living/L = owner
			var/our_max_health = L.getMaxHealth()
			L.adjustBruteLoss(-heal_amount*our_max_health)
			L.adjustFireLoss(-heal_amount*our_max_health)
			return
		var/list/ominous_warnings = list("Some light green fluid drips onto your shoulder.",
			"Out of the corner of your vision you see a fairy staring at you with its mouth hanging open.",
			"You occasionally hear the fluttering of fairy wings as they reposition themselves on your shoulder.",
			"Very faintly you hear a gurgle.",
			"Some of the fairies follow close to the back of your ankles while you work.",
			"You stumble and for a moment the beating of fairy wings grows louder.",
			"")
		if(prob(15))
			to_chat(owner, span_notice("[pick(ominous_warnings)]"))
	return ..()

/datum/status_effect/fairy_care/on_remove()
	. = ..()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/status_holder = owner
	RemoveFairyOverlay()
	to_chat(status_holder, span_notice("The fairies giggle before returning to their queen."))
	UnregisterSignal(status_holder, COMSIG_WORK_STARTED)
	UnregisterSignal(status_holder, COMSIG_WORK_COMPLETED)

/datum/status_effect/fairy_care/proc/ApplyFairyOverlay()
	fairy_overlay = mutable_appearance('ModularLobotomy/_Lobotomyicons/tegu_effects.dmi',"fairy_heal", -HALO_LAYER)
	var/mob/living/L = owner
	L.add_overlay(fairy_overlay)

/datum/status_effect/fairy_care/proc/RemoveFairyOverlay()
	var/mob/living/L = owner
	L.cut_overlay(fairy_overlay)
	fairy_overlay = null

/datum/status_effect/fairy_care/proc/FairyPause(datum/source, datum/abnormality/datum_sent, mob/living/carbon/human/user, work_type)
	SIGNAL_HANDLER
	//sloppy i know -IP
	healing = FALSE
	leftover_duration = duration - world.time
	duration = world.time + 5 MINUTES
	to_chat(user, span_notice("The fairies suddenly go eerily quiet."))

/datum/status_effect/fairy_care/proc/FairyRestart(datum/source, datum/abnormality/datum_sent, mob/living/carbon/human/user, work_type)
	SIGNAL_HANDLER
	healing = TRUE
	to_chat(user, span_nicegreen("The fairies start giggling and playing once more."))
	playsound(get_turf(user), 'sound/abnormalities/fairyfestival/fairylaugh.ogg', 50, 0, 2)
	duration = world.time + leftover_duration

/* not called by anything anymore, left here if somebody wants to readd it later for any reason.
/datum/status_effect/fairy_care/proc/FairyGib(datum/source, datum/abnormality/datum_sent, mob/living/carbon/human/user, work_type)
	SIGNAL_HANDLER
	if(!(GODMODE in user.status_flags))
		to_chat(user, span_userdanger("With a beat of their wings, the fairies pounce on you and ravenously consume your body!"))
		playsound(get_turf(user), 'sound/magic/demon_consume.ogg', 75, 0)
		user.gib(TRUE,TRUE,TRUE)
*/

/datum/reagent/abnormality/fairy_festival
	name = "Nectar of an Unknown Flower"
	description = "The fairies got this for you..."
	color = "#e4d0b2"
	health_restore = 2
	armor_mods = list(-2, 0, 0, 0)

/mob/living/simple_animal/hostile/mini_fairy
	name = "\improper Lost Fairy"
	desc = "They wander in search of food."
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "fairy_bastard"
	icon_living = "fairy_bastard"
	maxHealth = 83
	health = 83
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	is_flying_animal = TRUE
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1.2, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 1.2)
	faction = list("hostile", "fairy")
	melee_damage_lower = 1
	melee_damage_upper = 5
	melee_damage_type = RED_DAMAGE
	obj_damage = 3
	rapid_melee = 3
	attack_sound = 'sound/abnormalities/fairyfestival/fairy_festival_bite.ogg'
	density = FALSE
	move_to_delay = 2
	del_on_death = TRUE
	stat_attack = DEAD

/mob/living/simple_animal/hostile/mini_fairy/Initialize()
	. = ..()
	AddComponent(/datum/component/swarming)
	summon_backup()

/mob/living/simple_animal/hostile/mini_fairy/AttackingTarget(atom/attacked_target)
	. = ..()
	var/friends = 0
	for(var/mob/living/simple_animal/hostile/mini_fairy/fren in ohearers(6, src))
		friends++
	if(friends < 3)
		summon_backup()
	if(ishuman(attacked_target))
		var/mob/living/L = attacked_target
		if(L.health < 0 || L.stat == DEAD)
			var/mob/living/simple_animal/hostile/mini_fairy/MF = new(get_turf(L))
			MF.faction = src.faction
			playsound(get_turf(src), 'sound/magic/demon_consume.ogg', 75, 0)
			L.gib()
			summon_backup()

/mob/living/simple_animal/hostile/mini_fairy/summon_backup(distance = 6)
	for(var/mob/living/simple_animal/hostile/M in oview(distance, targets_from))
		if(faction_check_mob(M, TRUE))
			if(M.AIStatus == AI_OFF)
				continue
			else
				M.Goto(src,M.move_to_delay,M.minimum_distance)

/mob/living/simple_animal/hostile/fairy_mass
	name = "\improper Fairy Mass"
	desc = "They wander in search of food."
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "fairy_mass"
	icon_living = "fairy_mass"
	icon_dead = "fairy_mass_dead"
	maxHealth = 150
	health = 150
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	is_flying_animal = TRUE
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1.2, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 1.2, PALE_DAMAGE = 1.2)
	faction = list("hostile", "fairy")
	melee_damage_lower = 1
	melee_damage_upper = 5
	melee_damage_type = RED_DAMAGE
	obj_damage = 3
	rapid_melee = 3
	attack_sound = 'sound/abnormalities/fairyfestival/fairy_festival_bite.ogg'
	density = FALSE
	move_to_delay = 2
	stat_attack = DEAD
	guaranteed_butcher_results = list(/obj/item/food/meat/slab = 1)

/mob/living/simple_animal/hostile/fairy_mass/AttackingTarget(atom/attacked_target)
	. = ..()
	if(iscarbon(attacked_target))
		var/mob/living/L = attacked_target
		if(L.health < 0 || L.stat == DEAD)
			playsound(get_turf(src), 'sound/magic/demon_consume.ogg', 75, 0)
			L.gib()
