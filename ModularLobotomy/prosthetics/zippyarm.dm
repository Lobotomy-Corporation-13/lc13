/obj/item/organ/cyberimp/arm/zippy
	name = "Zippy 3000 implant"
	desc = "A cheap pistol implant made by XX corp. May or may not be recommended for use."
	contents = newlist(/obj/item/ego_weapon/ranged/pistol/rats)
	//Doesn't need a nerf, the gun's kinda shit lmao

/obj/item/organ/cyberimp/arm/zippy/l
	zone = BODY_ZONE_L_ARM


/obj/item/organ/cyberimp/arm/good_zippy
	name = "Zippy 3500 implant"
	desc = "A cheap pistol implant made by XX corp. May or may not be recommended for use. Modified to be an actual good gun"
	contents = newlist(/obj/item/ego_weapon/ranged/city/fullstop/pistol)

/obj/item/organ/cyberimp/arm/good_zippy/l
	zone = BODY_ZONE_L_ARM


/obj/item/organ/cyberimp/arm/good_zippy/Extend(obj/item/item)
	. = ..()
	//little bit of stam loss
	owner.adjustStaminaLoss(owner.maxHealth*0.25, TRUE, TRUE)
