/**
 * Resurgence Outpost - Resurgence Clothing
 *
 * Generic clothing types created by the loom that copy visual properties
 * from existing clothing. These can have faith fabrics attached for
 * passive faith bonuses.
 */

// ============================================
// JUMPSUIT (Under)
// ============================================

/obj/item/clothing/under/resurgence
	name = "clan-woven jumpsuit"
	desc = "A jumpsuit carefully woven by the Resurgence Clan."
	icon = 'icons/obj/clothing/under/default.dmi'
	worn_icon = 'icons/mob/clothing/under/default.dmi'
	icon_state = "grey"

	/// Reference to attached faith fabric (if any)
	var/obj/item/resurgence_fabric/attached_fabric

/obj/item/clothing/under/resurgence/Destroy()
	if(attached_fabric)
		QDEL_NULL(attached_fabric)
	return ..()

/obj/item/clothing/under/resurgence/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/resurgence_fabric))
		attach_fabric(I, user)
		return
	return ..()

/obj/item/clothing/under/resurgence/proc/attach_fabric(obj/item/resurgence_fabric/F, mob/user)
	if(attached_fabric)
		to_chat(user, span_warning("[src] already has a fabric attached! Alt-click to detach it first."))
		return

	if(!user.transferItemToLoc(F, src))
		return

	attached_fabric = F
	AddComponent(/datum/component/faith_clothing, F.faith_bonus)
	to_chat(user, span_notice("You attach [F] to [src]. (+[F.faith_bonus] faith when worn)"))
	playsound(src, 'sound/items/Wirecutter.ogg', 50, TRUE)

/obj/item/clothing/under/resurgence/proc/detach_fabric(mob/user)
	if(!attached_fabric)
		to_chat(user, span_warning("There is no fabric attached to [src]."))
		return

	var/datum/component/faith_clothing/FC = GetComponent(/datum/component/faith_clothing)
	if(FC)
		qdel(FC)

	attached_fabric.forceMove(get_turf(src))
	if(user)
		user.put_in_hands(attached_fabric)
		to_chat(user, span_notice("You detach [attached_fabric] from [src]."))
	attached_fabric = null
	playsound(src, 'sound/items/Wirecutter.ogg', 50, TRUE)

/obj/item/clothing/under/resurgence/AltClick(mob/user)
	if(attached_fabric && user.canUseTopic(src, BE_CLOSE))
		detach_fabric(user)
		return
	return ..()

/obj/item/clothing/under/resurgence/examine(mob/user)
	. = ..()
	if(attached_fabric)
		. += span_notice("It has [attached_fabric] attached, granting +[attached_fabric.faith_bonus] faith.")
		. += span_notice("Alt-click to detach the fabric.")
	else
		. += span_notice("You can attach a faith fabric to this garment for passive faith.")

// ============================================
// SUIT (Outerwear)
// ============================================

/obj/item/clothing/suit/resurgence
	name = "clan-woven garment"
	desc = "An outer garment carefully woven by the Resurgence Clan."
	icon = 'icons/obj/clothing/suits.dmi'
	worn_icon = 'icons/mob/clothing/suit.dmi'
	icon_state = "chaplain_hoodie"

	var/obj/item/resurgence_fabric/attached_fabric

/obj/item/clothing/suit/resurgence/Destroy()
	if(attached_fabric)
		QDEL_NULL(attached_fabric)
	return ..()

/obj/item/clothing/suit/resurgence/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/resurgence_fabric))
		attach_fabric(I, user)
		return
	return ..()

/obj/item/clothing/suit/resurgence/proc/attach_fabric(obj/item/resurgence_fabric/F, mob/user)
	if(attached_fabric)
		to_chat(user, span_warning("[src] already has a fabric attached! Alt-click to detach it first."))
		return

	if(!user.transferItemToLoc(F, src))
		return

	attached_fabric = F
	AddComponent(/datum/component/faith_clothing, F.faith_bonus)
	to_chat(user, span_notice("You attach [F] to [src]. (+[F.faith_bonus] faith when worn)"))
	playsound(src, 'sound/items/Wirecutter.ogg', 50, TRUE)

/obj/item/clothing/suit/resurgence/proc/detach_fabric(mob/user)
	if(!attached_fabric)
		to_chat(user, span_warning("There is no fabric attached to [src]."))
		return

	var/datum/component/faith_clothing/FC = GetComponent(/datum/component/faith_clothing)
	if(FC)
		qdel(FC)

	attached_fabric.forceMove(get_turf(src))
	if(user)
		user.put_in_hands(attached_fabric)
		to_chat(user, span_notice("You detach [attached_fabric] from [src]."))
	attached_fabric = null
	playsound(src, 'sound/items/Wirecutter.ogg', 50, TRUE)

/obj/item/clothing/suit/resurgence/AltClick(mob/user)
	if(attached_fabric && user.canUseTopic(src, BE_CLOSE))
		detach_fabric(user)
		return
	return ..()

/obj/item/clothing/suit/resurgence/examine(mob/user)
	. = ..()
	if(attached_fabric)
		. += span_notice("It has [attached_fabric] attached, granting +[attached_fabric.faith_bonus] faith.")
		. += span_notice("Alt-click to detach the fabric.")
	else
		. += span_notice("You can attach a faith fabric to this garment for passive faith.")

// ============================================
// HEAD (Headwear)
// ============================================

/obj/item/clothing/head/resurgence
	name = "clan-woven headwear"
	desc = "Headwear carefully woven by the Resurgence Clan."
	icon = 'icons/obj/clothing/hats.dmi'
	worn_icon = 'icons/mob/clothing/head.dmi'
	icon_state = "beret"

	var/obj/item/resurgence_fabric/attached_fabric

/obj/item/clothing/head/resurgence/Destroy()
	if(attached_fabric)
		QDEL_NULL(attached_fabric)
	return ..()

/obj/item/clothing/head/resurgence/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/resurgence_fabric))
		attach_fabric(I, user)
		return
	return ..()

/obj/item/clothing/head/resurgence/proc/attach_fabric(obj/item/resurgence_fabric/F, mob/user)
	if(attached_fabric)
		to_chat(user, span_warning("[src] already has a fabric attached! Alt-click to detach it first."))
		return

	if(!user.transferItemToLoc(F, src))
		return

	attached_fabric = F
	AddComponent(/datum/component/faith_clothing, F.faith_bonus)
	to_chat(user, span_notice("You attach [F] to [src]. (+[F.faith_bonus] faith when worn)"))
	playsound(src, 'sound/items/Wirecutter.ogg', 50, TRUE)

/obj/item/clothing/head/resurgence/proc/detach_fabric(mob/user)
	if(!attached_fabric)
		to_chat(user, span_warning("There is no fabric attached to [src]."))
		return

	var/datum/component/faith_clothing/FC = GetComponent(/datum/component/faith_clothing)
	if(FC)
		qdel(FC)

	attached_fabric.forceMove(get_turf(src))
	if(user)
		user.put_in_hands(attached_fabric)
		to_chat(user, span_notice("You detach [attached_fabric] from [src]."))
	attached_fabric = null
	playsound(src, 'sound/items/Wirecutter.ogg', 50, TRUE)

/obj/item/clothing/head/resurgence/AltClick(mob/user)
	if(attached_fabric && user.canUseTopic(src, BE_CLOSE))
		detach_fabric(user)
		return
	return ..()

/obj/item/clothing/head/resurgence/examine(mob/user)
	. = ..()
	if(attached_fabric)
		. += span_notice("It has [attached_fabric] attached, granting +[attached_fabric.faith_bonus] faith.")
		. += span_notice("Alt-click to detach the fabric.")
	else
		. += span_notice("You can attach a faith fabric to this garment for passive faith.")

// ============================================
// MASK
// ============================================

/obj/item/clothing/mask/resurgence
	name = "clan-woven mask"
	desc = "A mask carefully woven by the Resurgence Clan."
	icon = 'icons/obj/clothing/masks.dmi'
	worn_icon = 'icons/mob/clothing/mask.dmi'
	icon_state = "rag_mask"

	var/obj/item/resurgence_fabric/attached_fabric

/obj/item/clothing/mask/resurgence/Destroy()
	if(attached_fabric)
		QDEL_NULL(attached_fabric)
	return ..()

/obj/item/clothing/mask/resurgence/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/resurgence_fabric))
		attach_fabric(I, user)
		return
	return ..()

/obj/item/clothing/mask/resurgence/proc/attach_fabric(obj/item/resurgence_fabric/F, mob/user)
	if(attached_fabric)
		to_chat(user, span_warning("[src] already has a fabric attached! Alt-click to detach it first."))
		return

	if(!user.transferItemToLoc(F, src))
		return

	attached_fabric = F
	AddComponent(/datum/component/faith_clothing, F.faith_bonus)
	to_chat(user, span_notice("You attach [F] to [src]. (+[F.faith_bonus] faith when worn)"))
	playsound(src, 'sound/items/Wirecutter.ogg', 50, TRUE)

/obj/item/clothing/mask/resurgence/proc/detach_fabric(mob/user)
	if(!attached_fabric)
		to_chat(user, span_warning("There is no fabric attached to [src]."))
		return

	var/datum/component/faith_clothing/FC = GetComponent(/datum/component/faith_clothing)
	if(FC)
		qdel(FC)

	attached_fabric.forceMove(get_turf(src))
	if(user)
		user.put_in_hands(attached_fabric)
		to_chat(user, span_notice("You detach [attached_fabric] from [src]."))
	attached_fabric = null
	playsound(src, 'sound/items/Wirecutter.ogg', 50, TRUE)

/obj/item/clothing/mask/resurgence/AltClick(mob/user)
	if(attached_fabric && user.canUseTopic(src, BE_CLOSE))
		detach_fabric(user)
		return
	return ..()

/obj/item/clothing/mask/resurgence/examine(mob/user)
	. = ..()
	if(attached_fabric)
		. += span_notice("It has [attached_fabric] attached, granting +[attached_fabric.faith_bonus] faith.")
		. += span_notice("Alt-click to detach the fabric.")
	else
		. += span_notice("You can attach a faith fabric to this garment for passive faith.")

// ============================================
// GLOVES
// ============================================

/obj/item/clothing/gloves/resurgence
	name = "clan-woven gloves"
	desc = "Gloves carefully woven by the Resurgence Clan."
	icon = 'icons/obj/clothing/gloves.dmi'
	worn_icon = 'icons/mob/clothing/hands.dmi'
	icon_state = "white"

	var/obj/item/resurgence_fabric/attached_fabric

/obj/item/clothing/gloves/resurgence/Destroy()
	if(attached_fabric)
		QDEL_NULL(attached_fabric)
	return ..()

/obj/item/clothing/gloves/resurgence/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/resurgence_fabric))
		attach_fabric(I, user)
		return
	return ..()

/obj/item/clothing/gloves/resurgence/proc/attach_fabric(obj/item/resurgence_fabric/F, mob/user)
	if(attached_fabric)
		to_chat(user, span_warning("[src] already has a fabric attached! Alt-click to detach it first."))
		return

	if(!user.transferItemToLoc(F, src))
		return

	attached_fabric = F
	AddComponent(/datum/component/faith_clothing, F.faith_bonus)
	to_chat(user, span_notice("You attach [F] to [src]. (+[F.faith_bonus] faith when worn)"))
	playsound(src, 'sound/items/Wirecutter.ogg', 50, TRUE)

/obj/item/clothing/gloves/resurgence/proc/detach_fabric(mob/user)
	if(!attached_fabric)
		to_chat(user, span_warning("There is no fabric attached to [src]."))
		return

	var/datum/component/faith_clothing/FC = GetComponent(/datum/component/faith_clothing)
	if(FC)
		qdel(FC)

	attached_fabric.forceMove(get_turf(src))
	if(user)
		user.put_in_hands(attached_fabric)
		to_chat(user, span_notice("You detach [attached_fabric] from [src]."))
	attached_fabric = null
	playsound(src, 'sound/items/Wirecutter.ogg', 50, TRUE)

/obj/item/clothing/gloves/resurgence/AltClick(mob/user)
	if(attached_fabric && user.canUseTopic(src, BE_CLOSE))
		detach_fabric(user)
		return
	return ..()

/obj/item/clothing/gloves/resurgence/examine(mob/user)
	. = ..()
	if(attached_fabric)
		. += span_notice("It has [attached_fabric] attached, granting +[attached_fabric.faith_bonus] faith.")
		. += span_notice("Alt-click to detach the fabric.")
	else
		. += span_notice("You can attach a faith fabric to this garment for passive faith.")

// ============================================
// SHOES
// ============================================

/obj/item/clothing/shoes/resurgence
	name = "clan-woven shoes"
	desc = "Shoes carefully woven by the Resurgence Clan."
	icon = 'icons/obj/clothing/shoes.dmi'
	worn_icon = 'icons/mob/clothing/feet.dmi'
	icon_state = "black"

	var/obj/item/resurgence_fabric/attached_fabric

/obj/item/clothing/shoes/resurgence/Destroy()
	if(attached_fabric)
		QDEL_NULL(attached_fabric)
	return ..()

/obj/item/clothing/shoes/resurgence/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/resurgence_fabric))
		attach_fabric(I, user)
		return
	return ..()

/obj/item/clothing/shoes/resurgence/proc/attach_fabric(obj/item/resurgence_fabric/F, mob/user)
	if(attached_fabric)
		to_chat(user, span_warning("[src] already has a fabric attached! Alt-click to detach it first."))
		return

	if(!user.transferItemToLoc(F, src))
		return

	attached_fabric = F
	AddComponent(/datum/component/faith_clothing, F.faith_bonus)
	to_chat(user, span_notice("You attach [F] to [src]. (+[F.faith_bonus] faith when worn)"))
	playsound(src, 'sound/items/Wirecutter.ogg', 50, TRUE)

/obj/item/clothing/shoes/resurgence/proc/detach_fabric(mob/user)
	if(!attached_fabric)
		to_chat(user, span_warning("There is no fabric attached to [src]."))
		return

	var/datum/component/faith_clothing/FC = GetComponent(/datum/component/faith_clothing)
	if(FC)
		qdel(FC)

	attached_fabric.forceMove(get_turf(src))
	if(user)
		user.put_in_hands(attached_fabric)
		to_chat(user, span_notice("You detach [attached_fabric] from [src]."))
	attached_fabric = null
	playsound(src, 'sound/items/Wirecutter.ogg', 50, TRUE)

/obj/item/clothing/shoes/resurgence/AltClick(mob/user)
	if(attached_fabric && user.canUseTopic(src, BE_CLOSE))
		detach_fabric(user)
		return
	return ..()

/obj/item/clothing/shoes/resurgence/examine(mob/user)
	. = ..()
	if(attached_fabric)
		. += span_notice("It has [attached_fabric] attached, granting +[attached_fabric.faith_bonus] faith.")
		. += span_notice("Alt-click to detach the fabric.")
	else
		. += span_notice("You can attach a faith fabric to this garment for passive faith.")
