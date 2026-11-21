/obj/item/organ/cyberimp/chest/dermal_armor
	name = "\improper Dermal Armor."
	desc = "Armor made from plating and designed to be inserted at the dermal layer for extra protection. \
			Unfortunately it's not made of the same weave out of outfits so the plating makes you a bit slower."
	syndicate_implant = TRUE
	implant_overlay = "chest_resurgence_core"

/obj/item/organ/cyberimp/chest/dermal_armor/Insert(mob/living/carbon/M, special, drop_if_replaced)
	. = ..()
	var/mob/living/carbon/human/user = M
	user.physiology.damage_resistance += 0.1 //Easy armor adjusts for all damage to be at +10%
	user.add_movespeed_modifier(/datum/movespeed_modifier/dermal_armor)


/obj/item/organ/cyberimp/chest/dermal_armor/Remove(mob/living/carbon/M, special)
	. = ..()
	var/mob/living/carbon/human/user = M
	user.physiology.damage_resistance -= 0.1 //Easy armor adjusts for all damage to be at +10%
	user.remove_movespeed_modifier(/datum/movespeed_modifier/dermal_armor)


/datum/movespeed_modifier/dermal_armor

	multiplicative_slowdown = 0.1
