//Example of a transformation bolus.

/obj/item/bolus/volatile/slime
	name = "slime bolus"
	desc = "A bolus that can turn one to goop with enough refinement."
	icon_state = "bolus_slim"
	abilities = list(
			"FIRE 6: User permanently gains 5 Combat Bonus.",
			"WATER 8: User gains a slime body.",
			"EARTH 6: User permanently gains 8 HP.",
			"WOOD 7: User permanently gains 7 SP.",
			"METAL 7: User permanently gains 4% armor.",
			)

/obj/item/bolus/volatile/slime/Bolus_Special(mob/living/carbon/human/user)
	if(wood_in >= 7)
		user.adjust_attribute_bonus(FORTITUDE_ATTRIBUTE, 5)

	if(water_in >= 6)
		user.set_species(/datum/species/jelly)

	if(fire_in >= 6)
		user.adjust_attribute_bonus(JUSTICE_ATTRIBUTE, 5)

	if(earth_in >= 6)
		user.adjust_attribute_bonus(FORTITUDE_ATTRIBUTE, 5)

	if(metal_in >= 6)
		user.physiology.red_mod /= 1.04
		user.physiology.white_mod /= 1.04
		user.physiology.black_mod /= 1.04
		user.physiology.pale_mod /= 1.04
