/mob/living/simple_animal/hostile/abnormality/branch12/statue_of_forgiveness
	name = "Statue of Forgiveness"
	desc = "By praying for its protection, the statue might grant you its gift if you’re worthy"
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/32x64.dmi'
	icon_state = "forgiveness"
	icon_living = "forgiveness"


	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(80, 80, 50, 50, 50),
		ABNORMALITY_WORK_INSIGHT = list(80, 80, 80, 80, 80),
		ABNORMALITY_WORK_ATTACHMENT = list(50, 50, 50, 50, 50),
		ABNORMALITY_WORK_REPRESSION = list(30, 30, 30, 30, 30),
	)
	work_damage_amount = 5
	work_damage_type = WHITE_DAMAGE
	threat_level = ZAYIN_LEVEL
	max_boxes = 10

	ego_list = list(
		/datum/ego_datum/weapon/branch12/serenity,
		/datum/ego_datum/armor/branch12/serenity,
	)
	//gift_type =  /datum/ego_gifts/signal

	abnormality_origin = ABNORMALITY_ORIGIN_BRANCH12
	var/mob/living/carbon/human/gifted_human

/mob/living/simple_animal/hostile/abnormality/branch12/statue_of_forgiveness/SuccessEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(user.stat != DEAD && !gifted_human) //check there's no gifted human and the worker isn't dead
		RegisterSoul(user)
		to_chat(user, span_nicegreen("You feel protected."))
		switch(work_type) //set protection type based on work type
			if(ABNORMALITY_WORK_INSTINCT)
				user.physiology.red_mod *= 0.85
				user.physiology.white_mod *= 1.25
				user.physiology.black_mod *= 1.25
				user.physiology.pale_mod *= 1.25
			if(ABNORMALITY_WORK_INSIGHT)
				user.physiology.red_mod *= 1.25
				user.physiology.white_mod *= 0.85
				user.physiology.black_mod *= 1.25
				user.physiology.pale_mod *= 1.25
			if(ABNORMALITY_WORK_ATTACHMENT)
				user.physiology.red_mod *= 1.25
				user.physiology.white_mod *= 1.25
				user.physiology.black_mod *= 0.85
				user.physiology.pale_mod *= 1.25
			if(ABNORMALITY_WORK_REPRESSION)
				user.physiology.red_mod *= 1.25
				user.physiology.white_mod *= 1.25
				user.physiology.black_mod *= 1.25
				user.physiology.pale_mod *= 0.85

/mob/living/simple_animal/hostile/abnormality/branch12/statue_of_forgiveness/Life() //reset the buff when they die
	. = ..()
	if(!gifted_human)
		return
	if (gifted_human.stat == DEAD)
		UnregisterSoul()

/mob/living/simple_animal/hostile/abnormality/branch12/statue_of_forgiveness/PostWorkEffect(mob/living/carbon/human/user, work_type, pe, work_time, canceled)
	if(user.sanity_lost)
		QDEL_NULL(user.ai_controller)
		user.ai_controller = /datum/ai_controller/insane/murder
		user.InitializeAIController()

/mob/living/simple_animal/hostile/abnormality/branch12/statue_of_forgiveness/Destroy()
	UnregisterSoul()
	return ..()

/mob/living/simple_animal/hostile/abnormality/branch12/statue_of_forgiveness/proc/RegisterSoul(new_link)
	if(!new_link)
		return
	gifted_human = new_link
	RegisterSignal(new_link, list(COMSIG_PARENT_QDELETING, COMSIG_LIVING_DEATH), PROC_REF(UnregisterSoul))

/mob/living/simple_animal/hostile/abnormality/branch12/statue_of_forgiveness/proc/UnregisterSoul()
	if(gifted_human)
		UnregisterSignal(gifted_human, list(COMSIG_PARENT_QDELETING, COMSIG_LIVING_DEATH))
	gifted_human = null
