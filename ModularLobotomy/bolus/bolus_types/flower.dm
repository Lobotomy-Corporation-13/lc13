//This is an AOE assist Bolus, like a powder from monster hunter.

/obj/item/bolus/flower
	name = "flower bolus"
	desc = "A bolus that is used to assist others."
	icon_state = "bolus_flower"
	abilities = list(
			"WOOD 1: Lose 10 SP.",
			"WOOD 4: Heal 20 HP to all humans nearby.",
			"WATER 1: Lose 10 SP.",
			"WATER 4: Heal 20 SP to all humans nearby.",
			"FIRE 1: Lose 10 SP.",
			"FIRE 4: Ignite all humans nearby.",
			"EARTH 1: Lose 10 SP.",
			"EARTH 4: Slow all non-humans nearby.",
			"METAL 1: Lose 10 SP.",
			"METAL 4: Apply defense bonus to all humans nearby.",
			)


/obj/item/bolus/flower/Bolus_Special(mob/living/carbon/human/user)
	if(wood_in >= 1)
		user.adjustSanityLoss(10)

	if(water_in >= 1)
		user.adjustSanityLoss(10)

	if(fire_in >= 1)
		user.adjustSanityLoss(10)

	if(earth_in >= 1)
		user.adjustSanityLoss(10)

	if(metal_in >= 1)
		user.adjustSanityLoss(10)

	for(var/mob/living/carbon/human/H in view(5, user))
		if(H == user)
			continue

		if(wood_in >= 4)
			H.adjustBruteLoss(-20)

		if(water_in >= 4)
			H.adjustSanityLoss(-20)

		if(fire_in >= 4)
			H.adjust_fire_stacks(5)
			H.IgniteMob()

		if(metal_in >= 4)
			H.apply_lc_protection(2)

	for(var/mob/living/simple_animal/L in view(5, user))
		if(earth_in >= 4)
			L.apply_status_effect(/datum/status_effect/qliphothoverload)


