/datum/adventure_event/burn_victim
	name = "Burn Victim"
	desc = "WHISPERING VOICES"
	adventure_cords = list(
		"You enter the medical tent, and the stench of blood reaches your nostrils.<br>\
		You notice one man in the corner is not being attended to.<br>\
		His face is covered in bandages, and his chest rises and falls softly.",

		"You uncover his face, and the smell of putrid flesh hits your nostrils.<br>\
		His face is covered in infected burns. Lips seared off, remnants of the bubbling skin remaining.<br>\
		One of his eyes opens, and looks to you. And you look back.<br>\
		<br>\
		\"He's a lost cause.\" A doctor puts her hand on your shoulder.<br>\
		\"There's nothing we can do but make him comfortable.\"<br>\
		<br>\
		You nod solemnly, and look down at the poor soul laying there.<br>\
		You prepare the medicine for him, to ease his suffering.",

		"You reach to uncover his face, but you stop, the smell of infection reaching your nostrils.<br>\
		Gagging, and stepping back, you look to one of the doctors in the room.<br>\
		\"We can't save him.\" He says. \"There's nothing we can do.\"<br>\
		<br>\
		You nod, and turn away from the table. Nothing can be done.",
		)

/datum/adventure_event/burn_victim/EventChoiceFormat(obj/machinery/M, mob/living/carbon/human/H)
	switch(cords)
		if(1)
			CHANCE_BUTTON_FORMAT(ReturnStat(WRATH_STAT), "UNCOVER HIS FACE", M)
			return
		if(2)
			AdjustStatNum(GLOOM_STAT, ADV_EVENT_STAT_EASY)
		if(3)
			AdjustStatNum(WRATH_STAT, -2)
	return ..()
