/datum/adventure_event/shimple_company
	name = "A Shrimple Agreement"
	desc = "THE CRASHING OF WAVES"
	adventure_cords = list(
		"",

		""
		)

/datum/adventure_event/shimple_company/EventChoiceFormat(obj/machinery/M, mob/living/carbon/human/H)
	switch(cords)
		if(1)
			CHANCE_BUTTON_FORMAT(ReturnStat(PRIDE_STAT), "PRIDE", M)
			return
		if(2)
			AdjustStatNum(PRIDE_STAT,-5)
			CauseBattle(
				"The Skinned Lady: A woman with long black hair and skinned face.",
				MON_DAMAGE_HARD,
				300,
			)

		if(3)
			AdjustStatNum(PRIDE_STAT,2)		//Bit of pride
	return ..()
