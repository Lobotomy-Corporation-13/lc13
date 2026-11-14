/datum/adventure_event/nothing_left
	name = "Nothing Left"
	desc = "BREATHING BOTH RAPID AND DEEP"
	require_abno = /mob/living/simple_animal/hostile/abnormality/nothing_there
	adventure_cords = list(
		"You sway into conciousness, eyes forcefully peeling back <br>\
		as you force yourself to stand on jellied limbs. <br>",

		"Your vision swims as you take in the metal room. <br>\
		The room is barren except for a door on far end. <br>\
		The sterile air stings in your lungs.",


		"Something enters, its eyes dart across the room. <br>\
		This \"warden\" wears the skin of another, its true nature obscured. <br>\
		What is it hiding?",

		"You want to be near, to unravel this thing pretending to <br>\
		be something else. Your body slumps to the ground, <br>\
		your strength sapped by invisible chains. <br>\
		While your body falters you focus your gaze on your captor. <br>\
		Your bubbling hate for this THING only festering.",

		"The liar, the mockery of something else steps towards you. <br>\
		They attempt to touch you with something as you notice their foot <br>\
		slip over the line.",

		"You can only hear your own breathing and the beating of your heart. <br>\
		The Mockery steps back, its eyes widen as you push forward. The air <br>\
		feels thick against your body as you push yourself towards your target. <br>\
		YOU FEEL HATE <br>\
		The Mockery starts banging on the door screaming. <br>\
		YOUR CHAINS BREAK <br>\
		You will peel the Mockery from its shell and leave this prison. <br>\
		They will not steal who you are. You will take who they are. <br>\
		YOU ARE NOT ME <br>\
		I WILL BE YOU <br>\
		I WILL BE FREE",

		"You fail to break your bindings as the thing takes something from you. <br>\
		LET ME OUT <br>\
		The next time you see the Mockery, it is wearing your skin. <br>\
		Its hides its nature under a stolen skin. <br>\
		GIVE IT BACK",
		)

/datum/adventure_event/nothing_left/EventChoiceFormat(obj/machinery/M, mob/living/carbon/human/H)
	switch(cords)
		if(1)
			BUTTON_FORMAT(2, "WHERE AM I", M)
			return
		if(2)
			BUTTON_FORMAT(3, "BREATH", M)
			return
		if(3)
			BUTTON_FORMAT(4, "REACH", M)
			return
		if(4)
			BUTTON_FORMAT(5, "WAIT", M)
			return
		if(5)
			CHANCE_BUTTON_FORMAT(ReturnStat(WRATH_STAT), "WRATH", M)
			. += CoinFlipping(M)
			return
		if(6)
			CauseBattle(
				"MOCKERY: YOUR NOT ME I AM YOU YOUR SHELL IS MINE THERES NOTHING INSIDE.",
				MON_DAMAGE_HARD,
				50,
				ADV_EVENT_COIN_NORMAL,
				"New Shell"
			)
		if(7)
			AdjustStatNum(LUST_STAT, ADV_EVENT_STAT_EASY)

	return ..()
