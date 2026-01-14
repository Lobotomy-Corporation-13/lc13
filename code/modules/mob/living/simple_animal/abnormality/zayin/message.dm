//This is a Port of the abnormality "Saga of Man" but more fit for base LC13.

/mob/living/simple_animal/hostile/abnormality/report
	name = "Message of the Future"
	desc = "A sheet of paper sitting on a table. Recorded on it is tidings of the future."
	icon = 'ModularTegustation/Teguicons/32x32.dmi'
	icon_state = "last_report"
	icon_living = "last_report"

	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(50, 40, 30, 30, 30),
		ABNORMALITY_WORK_INSIGHT = list(70, 70, 50, 50, 50),
		ABNORMALITY_WORK_ATTACHMENT = 70,
		ABNORMALITY_WORK_REPRESSION = list(50, 40, 30, 30, 30),
	)
	work_damage_amount = 5
	work_damage_type = WHITE_DAMAGE
	threat_level = ZAYIN_LEVEL
	max_boxes = 10

	ego_list = list(
		/datum/ego_datum/weapon/tidings,
		//datum/ego_datum/armor/placeholder,
	)
	//gift_type =  /datum/ego_gifts/signal

	abnormality_origin = ABNORMALITY_ORIGIN_ORIGINAL
	var/current_saga = "Ready"
	var/last_ordeal = 0

/mob/living/simple_animal/hostile/abnormality/report/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time, canceled)
	..()
	if(current_saga!= "Ready")
		return

	icon_state = "last_report_used"
	current_saga = pick("Health", "Love", "Decay", "Chaos")
	for(var/mob/H in GLOB.player_list)
		to_chat(H, span_spider("The message has been read! The current tidings is of [current_saga]!"))

/mob/living/simple_animal/hostile/abnormality/report/Life()
	..()
	if(SSlobotomy_corp.next_ordeal_level != last_ordeal)
		current_saga = "Ready"	//Make it ready
		icon_state = "saga"
		last_ordeal = SSlobotomy_corp.next_ordeal_level

	switch(current_saga)
		if("Health")
			for(var/mob/living/carbon/human/H in GLOB.mob_list)
				if(prob(5))
					if(H.z!=z)
						continue
					H.adjustBruteLoss(-3)
					to_chat(H, span_warning("You feel in good shape."))

		if("Love")
			for(var/mob/living/carbon/human/H in GLOB.mob_list)
				if(prob(5))
					if(H.z!=z)
						continue
					H.adjustSanityLoss(-3)
					to_chat(H, span_warning("You feel loved."))

		if("Decay")
			for(var/mob/living/carbon/human/H in GLOB.mob_list)
				if(prob(5))
					if(H.z!=z)
						continue
					H.adjustSanityLoss(1)
					to_chat(H, span_warning("You feel uneasy at the state of the world."))

		if("Chaos")
			if(prob(5))
				var/turf/T = pick(GLOB.xeno_spawn)
				for(var/i = 1 to 3)
				new /mob/living/simple_animal/hostile/humanoid/rat (get_turf(T))

