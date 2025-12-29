/mob/living/simple_animal/hostile/abnormality/branch12/relic_of_virtue
	name = "Relic of Virtue"
	desc = "A bone in a golden skull on a pedestal."
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/32x32.dmi'
	icon_state = "relic"
	icon_living = "relic"


	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(80, 60, 50, 40, 30),
		ABNORMALITY_WORK_INSIGHT = list(80, 60, 50, 40, 30),
		ABNORMALITY_WORK_ATTACHMENT = list(80, 60, 50, 40, 30),
		ABNORMALITY_WORK_REPRESSION = list(80, 60, 50, 30, 30),
		"Consume" = 100,
	)
	work_damage_amount = 5
	work_damage_type = WHITE_DAMAGE
	threat_level = ZAYIN_LEVEL
	max_boxes = 10
	light_color = COLOR_YELLOW
	light_range = 30
	light_power = 7

	ego_list = list(
		/datum/ego_datum/weapon/branch12/virtue,
		//datum/ego_datum/armor/branch12/virtue,
	)
	//gift_type =  /datum/ego_gifts/signal

	abnormality_origin = ABNORMALITY_ORIGIN_BRANCH12

	//What's the current ordeal, and are we active?
	var/active = FALSE
	var/current_state = 1

	//Okay, who ate the bone.
	var/mob/living/carbon/human/eaten

	//Now it's thrown up
	var/thrown_up = FALSE

/mob/living/simple_animal/hostile/abnormality/branch12/relic_of_virtue/Initialize()
	..()
	addtimer(CALLBACK(src, PROC_REF(SetActive)), 10 MINUTES)

/mob/living/simple_animal/hostile/abnormality/branch12/relic_of_virtue/proc/SetActive()
	active = TRUE


/mob/living/simple_animal/hostile/abnormality/branch12/relic_of_virtue/AttemptWork(mob/living/carbon/human/user, work_type)
	..()
	if(eaten)
		if(work_type == "Consume")
			to_chat(user, span_danger("What is there to eat?"))
			return FALSE
		return TRUE		//It doesn't scale after eating it.

	if(work_type == "Consume")
		light_range = 0
		light_power = 0
		eaten = user
		switch(rand(1,4))
			if(1)
				to_chat(user, span_danger("You take the bone off the pedestal and crush it between your teeth."))
				user.adjust_attribute_level(FORTITUDE_ATTRIBUTE, 20)
			if(2)
				to_chat(user, span_danger("You take the bone off the pedestal and suckle on it until it turns to dust."))
				user.adjust_attribute_level(PRUDENCE_ATTRIBUTE, 20)
			if(3)
				to_chat(user, span_danger("You take the bone, snap it with your hands and pop it into your mouth."))
				user.adjust_attribute_level(TEMPERANCE_ATTRIBUTE, 20)
			if(4)
				user.adjust_attribute_level(JUSTICE_ATTRIBUTE, 20)
				to_chat(user, span_danger("You take the bone off the pedestal and chew."))
		return FALSE

	if(!active)
		return TRUE

	current_state = SSlobotomy_corp.next_ordeal_level
	switch(current_state)
		if(2)
			work_damage_amount = 7
			threat_level = TETH_LEVEL
			max_boxes = 12
		if(3)
			work_damage_amount = 9
			threat_level = HE_LEVEL
			max_boxes = 18
		if(4)
			work_damage_amount = 12
			threat_level = WAW_LEVEL
			max_boxes = 24
		if(5)
			work_damage_amount = 16
			threat_level = ALEPH_LEVEL
			max_boxes = 30
	return TRUE


/mob/living/simple_animal/hostile/abnormality/branch12/relic_of_virtue/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(eaten)
		return
	to_chat(user, span_danger("You feel like you are punished for failing."))
	//Failing a work sets your virtues to 0.
	user.adjust_attribute_level(FORTITUDE_ATTRIBUTE, -200)
	user.adjust_attribute_level(PRUDENCE_ATTRIBUTE, -200)
	user.adjust_attribute_level(TEMPERANCE_ATTRIBUTE, -200)
	user.adjust_attribute_level(JUSTICE_ATTRIBUTE, -200)


//Here's the miracles and smites.
/mob/living/simple_animal/hostile/abnormality/branch12/relic_of_virtue/Life()
	..()
	if(!eaten || thrown_up)
		return
	if(prob(99))
		return
	switch(rand(1,4))
		if(1)
			to_chat(eaten, span_nicegreen("You feel the power of the saint coursing through you."))
			eaten.adjustBruteLoss(-30)
			eaten.adjustSanityLoss(-30)
			eaten.apply_lc_strength(3)
		if(2)
			to_chat(eaten, span_danger("You are punished for your sins."))
			eaten.vomit(20, FALSE, distance = 5)
			eaten.adjustToxLoss(10)
			if(prob(10))
				to_chat(eaten, span_danger("You throw up the bone you ate earlier."))
				thrown_up = TRUE

		if(3)
			to_chat(eaten, span_danger("You are punished for your sins."))
			eaten.apply_lc_fragile(5)
		if(4)
			to_chat(eaten, span_danger("You are punished for your sins."))
			eaten.apply_lc_feeble(5)
