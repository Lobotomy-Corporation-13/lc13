/datum/adventure_event/clubman_start
	name = "The Clubman"
	desc = "A PACKED SUBWAY"
	adventure_cords = list(
		"The subway is packed, and the only seat open is next to a strange man.<br>\
		He is wearing a mohawk, sunglasses and a leather jacket.<br>\
		He looks towards you and begins to speak.<br>\
		'Have you tried the nightlife in this city?'.<br>\
		His words barely understandable through his thick accent.<br>\
		'It's wonderful. I go to the club, then the afterparty.<br>\
		Then I go to the club again. My party is just getting started'<br>\
		He looks very pleased with himself.<br>\
		'Do I like it? No. But someone has to keep the club culture alive.<br>\
		It's me. I'm that guy'.<br>\
		...<br>\
		What?",
		)

/datum/adventure_event/clubman_start/EventChoiceFormat(obj/machinery/M, mob/living/carbon/human/H)
	switch(cords)
		if(1)
			AdjustStatNum(GLUTT_STAT, 1)
			RewardKey("CLUBBING")
			spend_event = TRUE

	return ..()
