//Another basic and common bolus.
//Earth Counterpart to the charred bolus

/obj/item/bolus/clay
	name = "clay bolus"
	desc = "A bolus that focuses on movement speed."
	icon_state = "bolus_clay"
	abilities = list(
			"WOOD 2: User heals 15 HP and SP.",
			"WOOD 4: User's body rejects the medication, taking mild poisoning.",
			"WATER 3: User gains PALE/WHITE Fragile 3.",
			"FIRE 3: User gains RED/BLACK Fragile 3.",
			"EARTH 1: Get a small speed bonus for a some time. After this, the user will be confused.",
			"EARTH 3: Get a medium speed bonus for a small bit of time. After this time, the user will be knocked down.",
			"EARTH 5: Get a huge speed bonus for a tiny bit of time. After this time ends, the user will be stunned.",
			"METAL 2: User gains Protection 1",
			"METAL 4: User gains Fragile 2",
			)

/obj/item/bolus/clay/Bolus_Special(mob/living/carbon/human/user)
	if(wood_in >= 2)
		user.adjustBruteLoss(-15)
		user.adjustSanityLoss(-15)

	if(wood_in >= 4)
		user.adjustToxLoss(5)

	if(water_in >= 3)
		user.apply_lc_white_fragile(3)
		user.apply_lc_pale_fragile(3)

	if(fire_in >= 3)
		user.apply_lc_red_fragile(3)
		user.apply_lc_black_fragile(3)

	if(earth_in >= 1)
		user.add_movespeed_modifier(/datum/movespeed_modifier/clay_1)
		addtimer(CALLBACK(src, PROC_REF(RemoveClay1), user), 60 SECONDS)

	if(earth_in >= 3)
		user.add_movespeed_modifier(/datum/movespeed_modifier/clay_2)
		addtimer(CALLBACK(src, PROC_REF(RemoveClay2), user), 30 SECONDS)

	if(earth_in >= 5)
		user.add_movespeed_modifier(/datum/movespeed_modifier/clay_3)
		addtimer(CALLBACK(src, PROC_REF(RemoveClay3), user), 3 SECONDS)

	if(metal_in >= 2)
		user.apply_lc_protection(1)

	if(metal_in >= 4)
		user.apply_lc_fragile(2)




/obj/item/bolus/clay/proc/RemoveClay1(mob/living/carbon/human/user)
		user.remove_movespeed_modifier(/datum/movespeed_modifier/clay_1)
		user.set_confusion(30)

/obj/item/bolus/clay/proc/RemoveClay2(mob/living/carbon/human/user)
		user.remove_movespeed_modifier(/datum/movespeed_modifier/clay_2)
		user.Knockdown(30)

/obj/item/bolus/clay/proc/RemoveClay3(mob/living/carbon/human/user)
		user.remove_movespeed_modifier(/datum/movespeed_modifier/clay_3)
		user.Immobilize(30)
		user.Knockdown(30)




//Movespeed boost
/datum/movespeed_modifier/clay_1
	multiplicative_slowdown = -0.13

/datum/movespeed_modifier/clay_2
	multiplicative_slowdown = -0.24

/datum/movespeed_modifier/clay_3	//Good luck making use of this.
	multiplicative_slowdown = -0.75

