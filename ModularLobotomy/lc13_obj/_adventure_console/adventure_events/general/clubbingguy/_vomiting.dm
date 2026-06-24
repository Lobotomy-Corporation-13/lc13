/datum/adventure_event/clubbing
	name = "The Rave"
	desc = "A DARK ROOM"

	adventure_cords = list(
		"Following the advice of the strange man with the mohawk, you visit a nightclub.<br>\
		Downing a few beers, you start to bump with the music.<br>\
		The crowd is electric. In the mosh pit, the bass reverberates through your very soul.<br>\
		After some time, you visit the washroom, and exiting the male's room, is the same strange man.<br>\
		His sunglasses are are vibrant as ever, his mohawk glorious as usual.<br>\
		He looks at you 'Ah, you decided to take up my advice?'<br>\
		He starts to speak again, in a slurred heavy accent.<br>\
		His face is bright pink.<br>\
		'I appreciate you decided to come to the best party in this side of the city!'<br>\
		He then reels back, turns around, and vomits all over the floor.",
		)

	event_locks = "CLUBBING"

/datum/adventure_event/clubbing/EventChoiceFormat(obj/machinery/M, mob/living/carbon/human/H)
	switch(cords)
		if(1)
			AdjustStatNum(GLUTT_STAT, 1)

	return ..()
