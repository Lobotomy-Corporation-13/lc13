/datum/adventure_event/shimple_company
	name = "A Shrimple Agreement"
	desc = "THE CRASHING OF WAVES"
	adventure_cords = list(
		"Beneath a sappire blue sky you find yourself <br>\
		sat on a pier throwing scraps of bread into the water. <br>\
		You watch as scavengers swarm beneath your feet, <br>\
		minnows and shrimp side by side as they feast. <br>\
		Your wasting your few hours away from work <br>\
		feeding fish, the pointlessness of this moment <br>\
		weighing heavy on your mind.",

		"The chunk of bread plops into the water, <br>\
		sitting in tense stillness before the <br>\
		starving mob rushes to its new meal. <br>\
		The squeeling of tires and loud K-pop music breaks <br>\
		your focus as you turn to the road at the top of <br>\
		the bank. A obnoxiously purple van with an ungodly <br>\
		amount of graffiti parks nearby. <br>\
		The front door opens revealing two humanoid <br>\
		shrimp in overalls who start trudging through the <br>\
		sand towards you.",

		"One of the shimp pulls out a speak and spell <br>\
		and hands it to the other. <br>\
		\"H E L L O, BUDDY, NEED WORK, NEED HELP\" <br>\
		The shrimp both stare at you.",

		"The shrimp without the speak and spell <br>\
		points towards the bridge. <br>\
		\"PASS BRIDGE, NEED DRIVER\" <br>\
		The bridge is a minor checkpoint that you <br>\
		crossed an hour ago. Only residents are <br>\
		allowed across",

		"The two shrimp stare at you silently. <br>\
		The two shrimp men look at eachother before <br>\
		shrugging. The speak and spell is handed back <br>\
		to the other shrimp before being chucked <br>\
		at your face. As you squirm on <br>\
		the sand the shrimp retrieve <br>\
		the speak and spell and your residential ID <br>\
		before fleeing back to their van. <br>\
		As you attempt to stand up one of the shrimp <br>\
		runs back and kicks sand in your face before <br>\
		jumping into the van.",
		//6
		"The shrimp without the speak and spell <br>\
		starts clapping before leading you back <br>\
		to the van. Underneath all the graffiti <br>\
		you see \"WELLCHEERS\" spelled out in <br>\
		pink paint.",

		"The shrimp in the passenger seat stares <br>\
		forward as you drive upto the checkpoint <br>\
		the gaurd looks at you and then the shrimp. <br>\
		The passenger shrimp hands you a soda and <br>\
		offers it to the gaurd who hesitantly takes <br>\
		it before letting you pass. <br>\
		The shrimp hands you a wad of cash stained <br>\
		with soda and then types into the <br>\
		speak and spell. <br>\
		\"GOOD, MONEY, GOOD, JOB\" <br>\
		The shrimp then points down the road to a <br>\
		warehouse.",

		"You take the cash and step out of the car. <br>\
		The shrimp waves and hands you a <br>\
		cherry Wellcheers soda before driving away.",

		)

/datum/adventure_event/shimple_company/EventChoiceFormat(obj/machinery/M, mob/living/carbon/human/H)
	switch(cords)
		if(1)
			BUTTON_FORMAT(2, "THROW BREAD", M)
			return
		if(2)
			BUTTON_FORMAT(3, "HELLO", M)
			return
		if(3 to 4)
			if(cords == 3)
				BUTTON_FORMAT(4, "WHAT WORK", M)
			BUTTON_FORMAT(6, "YES?", M)
			BUTTON_FORMAT(5, "GO AWAY", M)
			return
		if(5)
			AdjustHitPoint(-20)
			AdjustStatNum(GLOOM_STAT,3)
		if(6)
			BUTTON_FORMAT(7, "DRIVE", M)
			return
		if(7)
			AdjustCurrency(1)
			AdjustStatNum(LUST_STAT,3)
			BUTTON_FORMAT(9, "DRIVE TO WAREHOUSE", M)
			BUTTON_FORMAT(8, "STOP HERE", M)
			return
		if(8)
			AdjustHitPoint(10)
		if(9)
			RewardKey("WELLCHEERS CAR KEYS")
			spend_event = TRUE
	return ..()
