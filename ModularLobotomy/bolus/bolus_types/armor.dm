//Super Basic, super common

/obj/item/bolus/armor
	name = "armor bolus"
	desc = "A bolus that is used to apply armor of different types to the user."
	icon_state = "bolus_armor"
	abilities = list(
			"WOOD 3: Applies 2 BLACK Protection for a short period of time.",
			"WATER 3: Applies 2 PALE Protection for a short period of time.",
			"FIRE 3: Applies 2 WHITE Protection for a short period of time.",
			"EARTH 3: Applies 2 RED Protection for a short period of time.",
			"METAL 6: Applies 2 Protection for a short period of time.",
			)

/obj/item/bolus/armor/Bolus_Special(mob/living/carbon/human/user)
	if(wood_in >= 3)
		user.apply_lc_black_protection(2)

	if(water_in >= 3)
		user.apply_lc_pale_protection(2)

	if(fire_in >= 3)
		user.apply_lc_white_protection(2)

	if(earth_in >= 3)
		user.apply_lc_red_protection(2)

	if(metal_in >= 6)
		user.apply_lc_protection(2)


