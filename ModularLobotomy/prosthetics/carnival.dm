/obj/item/organ/cyberimp/arm/carnival
	name = "carnival tools implants"
	desc = "Countless sharp blades packed into a small compartment, manipulating the blades inside this implant seems less exhausting compared to others."
	contents = newlist(/obj/item/storage/bag/silk/arm, /obj/item/silkknife/arm, /obj/item/ego_weapon/city/carnival_spear/arm)

/obj/item/ego_weapon/city/carnival_spear/arm
	name = "long carnival claw"
	desc = "One of the many claws the carnival hide beneath their robes for their hunts"

/obj/item/silkknife/arm
	name = "silk weaver"
	desc = "A small set of claws and tendrils which tear apart their victims to produce silk"

/obj/item/storage/bag/silk/arm
	name = "carnival tendrils"
	desc = "Multiple tendrils which stretch out from under the robes of the Carnival, used to collect their silk"

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

