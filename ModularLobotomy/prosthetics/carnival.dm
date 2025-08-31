/obj/item/organ/cyberimp/arm/carnival
	name = "carnival tools implants"
	desc = "Countless sharp blades packed into a small compartment, manipulating the blades inside this implant seems less exhausting compared to others."
	contents = newlist(/obj/item/silkknife, /obj/item/ego_weapon/city/carnival_spear/arm)

/obj/item/organ/cyberimp/arm/carnival/Extend(/obj/item/item)
	..()
	//low stam loss due to the fact that you will use this for butchering and combat however stam loss nonetheless
	owner.adjustStaminaLoss(owner.maxHealth*0.1, TRUE, TRUE)

/obj/item/organ/cyberimp/arm/carnival/l
	zone = BODY_ZONE_L_ARM

/obj/item/ego_weapon/city/carnival_spear/arm/equipped(mob/user, slot)
	. = ..()
	if(slot != ITEM_SLOT_HANDS)
		return
	//This stacks with the previous stamloss so you specifically lose more stamloss if you draw the weapon
	var/mob/living/carbon/human/H = user
	H.adjustStaminaLoss(H.maxHealth*0.1, TRUE, TRUE)

