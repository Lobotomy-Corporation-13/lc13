/datum/adventure_event/clubbing/street
	name = "Street Party"
	desc = "A LOUD STREET AT NIGHT"

	adventure_cords = list(
		"After a night of drinking in the club,<br>\
		you head back to your hostel.<br>\
		In the street, you see a man with a Mohawk and shades, he's familiar to you.<br>\
		He raises a mug of beer, and the people around him do too.<br>\
		'To the city!' he yells, slamming back the beer, and dashing the mug on the concrete.<br>\
		The crowd returns in kind, with a shout of 'To the city!' before the streets are filled,<br>\
		with the shattering of more than a dozen mugs. A bystander hands you a glass of beer<br>\
		which you graciously accept and sip on the way home.",
		)

/datum/adventure_event/clubbing/street/EventChoiceFormat(obj/machinery/M, mob/living/carbon/human/H)
	switch(cords)
		if(1)
			AdjustStatNum(GLUTT_STAT, 1)

	return ..()
