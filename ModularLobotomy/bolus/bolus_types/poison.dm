//This one is mostly for flavor.
/obj/item/bolus/poison
	name = "poison bolus"
	desc = "A bolus that is full of rather noxious ingredients."
	icon_state = "bolus_poison"
	abilities = list(
			"WATER 3: Poisons the user.",
			"WOOD 3: Confuses the user.",
			"FIRE 3: Burns the insides of the user.",
			"METAL 3: Blinds the user",
			"EARTH 3: Puts the user to sleep",
			)

/obj/item/bolus/poison/Bolus_Special(mob/living/carbon/human/user)
	if(wood_in >= 3)
		user.set_confusion(10)

	if(water_in >= 3)
		user.adjustToxLoss(30)

	if(fire_in >= 3)
		user.adjustFireLoss(30)

	if(earth_in >= 3)
		user.drowsyness += 30

	if(metal_in >= 3)
		user.adjust_blindness(5)


