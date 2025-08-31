//EGO mask, like neck and head its attached to the armor itself
/obj/item/clothing/mask/ego_mask
	name = "ego mask"
	desc = "an ego mask that you shouldn't be seeing!"
	icon = 'icons/obj/clothing/ego_gear/masks.dmi'
	worn_icon = 'icons/mob/clothing/ego_gear/mask.dmi'
	icon_state = ""
	var/perma = FALSE

/obj/item/clothing/mask/ego_mask/Destroy()
	if(perma)
		return ..()
	dropped()
	return ..()

/obj/item/clothing/mask/ego_mask/equipped(mob/user, slot)
	if(perma)
		return ..()
	if(slot != ITEM_SLOT_MASK)
		Destroy()
		return
	. = ..()
