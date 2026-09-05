//Another basic and common bolus.
//Water Counterpart to the charred bolus

/obj/item/bolus/soaked
	name = "soaked bolus"
	desc = "A bolus that focuses on healing the user."
	icon_state = "bolus_soaked"
	abilities = list(
			"WOOD 2: User heals 10 HP.",
			"WOOD 4: User goes insane for a moment, to heal all sanity after.",
			"WATER 1: User heals 10 HP",
			"WATER 3: User heals 10 HP",
			"WATER 5: User heals 10 HP",
			"FIRE 3: User emits a whole bunch of steam, scalding them.",
			"EARTH 3: User is poisoned.",
			"METAL 2: User heals HP extremely quickly while sleeping for a short period of time.",
			"METAL 4: User gets drowsy.",
			)
	var/sleep_tick = 10

/obj/item/bolus/soaked/Bolus_Special(mob/living/carbon/human/user)
	if(water_in >= 1)
		user.adjustBruteLoss(-10)

	if(water_in >= 3)
		user.adjustBruteLoss(-10)

	if(water_in >= 5)
		user.adjustBruteLoss(-10)

	//Yep, this is bonus healing.
	if(wood_in >= 2)
		user.adjustBruteLoss(-10)

	if(wood_in >= 4)
		if(!user.sanity_lost)
			user.adjustSanityLoss(500)
		QDEL_NULL(user.ai_controller)
		user.ai_controller = /datum/ai_controller/insane/murder
		user.InitializeAIController()
		addtimer(CALLBACK(src, PROC_REF(Resane), user), 5 SECONDS)

	if(fire_in >= 3)
		user.adjustFireLoss(30)
		var/datum/effect_system/smoke_spread/S = new
		S.set_up(2, get_turf(user))
		S.start()
		qdel(S)

	if(earth_in >= 3)
		user.vomit()
		user.adjustToxLoss(10)

	if(metal_in >= 2)
		SleepHeal(user)

	if(metal_in >= 4)
		user.drowsyness += 30


//Sleeping heal

/obj/item/bolus/soaked/proc/SleepHeal(mob/living/carbon/human/user)
	if(sleep_tick > 0)
		addtimer(CALLBACK(src, PROC_REF(SleepHeal), user), 5 SECONDS)

	if(user.IsSleeping())
		user.adjustBruteLoss(-20)


//Sanity Heal from the resane
/obj/item/bolus/soaked/proc/Resane(mob/living/carbon/human/user)
	user.adjustSanityLoss(-500)




