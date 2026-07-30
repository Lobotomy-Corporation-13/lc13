/mob/living/simple_animal/hostile/abnormality/another_portrait
	name = "Portrait of Another World"
	desc = "A seemingly blank portrait."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "another_portrait"
	portrait = "another_portrait"
	maxHealth = 400
	health = 400
	threat_level = HE_LEVEL
	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 50,
		ABNORMALITY_WORK_INSIGHT = list(60, 60, 65, 65, 70),
		ABNORMALITY_WORK_ATTACHMENT = 0,
		ABNORMALITY_WORK_REPRESSION = 40,
	)
	work_damage_amount = 0
	work_damage_type = WHITE_DAMAGE
	chem_type = /datum/reagent/abnormality/sin/pride
	ego_list = list(
		//datum/ego_datum/weapon/solitude,
		//datum/ego_datum/armor/solitude,
	)
	//gift_type =  /datum/ego_gifts/solitude
	abnormality_origin = ABNORMALITY_ORIGIN_ALTERED

	observation_prompt = "As time passes, people change. \
		We may become disabled, lose our minds, be consumed by overwhelming violence, \
		or be willed to disappear, never seen again."
	observation_choices = list(
		"Dissappear" = list(TRUE, "Little by little, as the time goes on, the portrait begins to rot. \
			Over the months, the years, and the decades, the fresco falls away. \
			While you managed to buy yourself a lot longer, in the end time comes for us all."),
		"Stay" = list(FALSE, "You will yourself to stay; against your better judgement. \
			A portrait captures a moment a time. You do not wish to be the same as you are, \
			forever."),
	)
	var/mob/living/carbon/human/bastard

/mob/living/simple_animal/hostile/abnormality/another_portrait/WorktickFailure(mob/living/carbon/human/user)
	user.apply_damage(4, WHITE_DAMAGE, null, H.run_armor_check(null, WHITE_DAMAGE), spread_damage = TRUE)
	bastard.apply_damage(4, WHITE_DAMAGE, null, H.run_armor_check(null, WHITE_DAMAGE), spread_damage = TRUE)
	WorkDamageEffect()

/mob/living/simple_animal/hostile/abnormality/another_portrait/AttemptWork(mob/living/carbon/human/user, work_type)
	var/list/potential_bastards = list()
	for(var/mob/living/human/H in alive_mob_list)
		if(H.z==z)
			potential_bastards+=H
	bastard = pick(potential_bastards)
	to_chat(bastard, span_userdanger("You feel a grip from another world...... [user] reaches out to you...."))
	return TRUE
