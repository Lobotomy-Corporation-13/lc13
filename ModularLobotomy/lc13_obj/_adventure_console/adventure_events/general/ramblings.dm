/datum/adventure_event/ramblings
	name = "Ramblings of the Mad"
	desc = "A MAN STANDS WITH HIS BACK TURNED"

	adventure_cords = list(
		"A man stands in front of you, his back turned.<br>\
		And as you approach him, he begins to talk, entirely unprompted.<br>\
		<br>\
		\"You ever feel like... this world we live in is a sham built upon the insane?<br>\
		Like, we go our entire lives never contributing anything of note.<br>\
		I feel like a lot of people could do with being a bit more dangerous, a bit more perverted.<br>\
		Chasing one woman at night down a dark alleyway doesnt really accomplish anything of note.<br>\
		But chase enough women down dark alleyways? The wing will make it a taboo.<br>\
		<br>\
		THAT'S making an impact on the world. Your name will be inscribed in code forever.<br>\
		Jump into a pit of goo at your job and get melted into a mulch? They might make rules against that sort of thing.<br>\
		<br>\
		You ever think about how we humans started to drink milk?<br>\
		One pervert did it, realized it was delicious and now we all do it.<br>\
		Sometimes all it takes is the right pervert in the right place.<br>\
		And by god am I the right pervert.\"<br>\
		<br>\
		You back away slowly from this man.",
		)

/datum/adventure_event/ramblings/EventChoiceFormat(obj/machinery/M, mob/living/carbon/human/H)
	switch(cords)
		if(1)
			AdjustStatNum(GLUTT_STAT, ADV_EVENT_STAT_EASY)

	return ..()
