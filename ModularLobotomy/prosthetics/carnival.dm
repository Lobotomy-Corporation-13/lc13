/obj/item/organ/cyberimp/arm/carnival
	name = "carnival tools implants"
	desc = "Countless sharp blades packed into a small compartment, manipulating the blades inside this implant seems less exhausting compared to others."
	contents = newlist(/obj/item/silkknife, /obj/item/ego_weapon/city/carnival_spear)

/obj/item/organ/cyberimp/arm/fixertools/Extend(/obj/item/ego_weapon/city/carnival_spear/item)
	..()
	//stam loss to compensate for the fact this is a free no drop and anti looting system
	owner.adjustStaminaLoss(owner.maxHealth*0.2, TRUE, TRUE)
