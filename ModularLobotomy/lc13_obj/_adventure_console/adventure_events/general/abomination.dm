/datum/adventure_event/abomination
	name = "The Abomination"
	desc = "SHAMBLING FORMS APPROACH"
	adventure_cords = list(
		"Shambling towards you are what appears to be three fleshy forms.<br>\
		Two look vaguely male, and one looks vaguely female.",

		"You decide to wait to see what they will do.<br>\
		After a moment of waiting, a male and female form embrace,<br>\
		their flesh melding together in an unholy abomination.<br>\
		<br>\
		Fearing for your life, you draw your weapon.",

		"Without hesitation, you slash at the male form, felling it in one strike.<br>\
		As if reacting to their fallen ally, the remaining two figures embrace,<br>\
		their naked, fleshy forms melding together into an abomination.",

		"You draw your blade, felling the female form in one strike.<br>\
		The two other forms start to retreat, and you fell them both in turn.",
		)

/datum/adventure_event/abomination/EventChoiceFormat(obj/machinery/M, mob/living/carbon/human/H)
	switch(cords)
		if(1)
			BUTTON_FORMAT(2, "OBSERVE", M)
			BUTTON_FORMAT(3, "ATTACK THE MALE FORM", M)
			BUTTON_FORMAT(4, "ATTACK THE FEMALE FORM", M)
			return

		if(2)
			AdjustStatNum(LUST_STAT, 7)
			CauseBattle(
				"Fleshy Abomination: A horrific melding of two fleshy forms, writhing as one.",
				MON_DAMAGE_HARD,
				MON_HP_RAND_NORMAL,
			)
			gamer.travel_mode = ADVENTURE_MODE_BATTLE

		if(3)
			AdjustStatNum(LUST_STAT, 7)
			CauseBattle(
				"Fleshy Abomination: A horrific melding of two fleshy forms, writhing as one.",
				MON_DAMAGE_HARD,
				MON_HP_RAND_NORMAL,
			)
			gamer.travel_mode = ADVENTURE_MODE_BATTLE

		if(4)
			AdjustStatNum(WRATH_STAT, 2)
			AdjustStatNum(LUST_STAT, -1)

	return ..()
