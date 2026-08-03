//Tank role because he heals and has a truckload of health
/mob/living/simple_animal/hostile/rcorp_abno/hard/nothing_there
	name = "Nothing There"
	desc = "A wicked creature that consists of various human body parts and organs."
	health = 4000
	maxHealth = 4000
	melee_damage_type = RED_DAMAGE
	damage_coeff = list(RED_DAMAGE = 0.3, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.2)
	melee_damage_lower = 55
	melee_damage_upper = 65
	move_to_delay = 3
	del_on_death = FALSE
	original_abno = /mob/living/simple_animal/hostile/abnormality/nothing_there

	var/last_heal_time = 0
	var/heal_percent_per_second = 0.01275
	var/regen_on = TRUE
	var/regen_start = 0.5 //Rabbits kept being stupid so now he only heals up to 50%

	var/datum/looping_sound/nothingthere_ambience/soundloop

	//Speaking Variables, not sure if I want to use the automated speach at the moment.
	var/heard_words = list()
	var/listen_chance = 10 // 20 for testing, 10 for base
	var/utterance = 5 // 10 for testing, 5 for base

	abno_additional_instructions = "<h1>You are Nothing There, A Tank Role Abnormality.</h1><br>\
		<b>|Regenerative|: If your HP falls below 50% you will begin to passively regenerate, if it falls below 30% regeneration rate doubles. \
		If damaged regeneration is interrupted, regeneration will only commence again if you go 10 seconds without being damaged. \
		You only heal up to 50% of your HP.<br>\
		<br>\
		|Mimicry|: You will repeat phrases you hear said by humans. </b>"

/mob/living/simple_animal/hostile/rcorp_abno/hard/nothing_there/Initialize()
	. = ..()
	playsound(get_turf(src), 'sound/abnormalities/nothingthere/breach.ogg', 50, 0, 5)
	soundloop = new(list(src), FALSE)
	soundloop.start()

/mob/living/simple_animal/hostile/rcorp_abno/hard/nothing_there/Destroy()
	soundloop.stop()
	QDEL_NULL(soundloop)
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/nothing_there/Life()
	. = ..()
	var/speak_list = list()
	if(prob(utterance) && LAZYLEN(heard_words))
		speak_list = pick(heard_words)
		speak_list = heard_words[speak_list]
		say(pick(speak_list))
	if(.)
		if(LAZYLEN(heard_words) && prob(utterance))
			var/mob/living/carbon/human/speaker = pick(heard_words)
			speak_list = heard_words[speaker]
			var/line = pick(speak_list)
			say(line)
		if((last_heal_time + 1 SECONDS) < world.time) // One Second between heals guaranteed
			regen_on = TRUE
			if(health > maxHealth * regen_start)
				regen_on = FALSE
			if(regen_on == TRUE)
				var/heal_amount = ((world.time - last_heal_time)/10)*heal_percent_per_second*maxHealth
				if(health <= maxHealth*0.3)
					heal_amount *= 2
				adjustBruteLoss(-heal_amount)
			last_heal_time = world.time

/mob/living/simple_animal/hostile/rcorp_abno/hard/nothing_there/death(gibbed)
	animate(src, alpha = 0, time = 10 SECONDS)
	QDEL_IN(src, 10 SECONDS)
	..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/nothing_there/Hear(message, atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, list/message_mods)
	. = ..()
	if(prob(listen_chance) && istype(speaker, /mob/living/carbon/human))
		if(!(speaker in heard_words)) // No words stored yet
			heard_words[speaker] = list()
		if(!(raw_message in heard_words[speaker]))
			heard_words[speaker] += raw_message
	listen_chance = initial(listen_chance)

/mob/living/simple_animal/hostile/rcorp_abno/hard/nothing_there/PostDamageReaction(damage_amount, damage_type, source, attack_type)
	. = ..()
	if(. < 10)
		return
	last_heal_time = world.time + 10 SECONDS // Heal delayed when taking damage; Doubled because it was a little too quick.

