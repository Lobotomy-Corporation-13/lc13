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
	var/plating_tier = 0

/obj/item/clothing/suit/resurgence/Destroy()
	if(attached_fabric)
		QDEL_NULL(attached_fabric)
	return ..()

/obj/item/clothing/suit/resurgence/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/resurgence_fabric))
		attach_fabric(I, user)
		return
	if(istype(I, /obj/item/resurgence_plating))
		var/result = try_attach_plating(src, I, user, plating_tier)
		if(result)
			plating_tier = result
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
	if(plating_tier > 0)
		. += span_notice("It has tier [plating_tier] plating attached.")
	else
		. += span_notice("You can attach clothing plating for armor protection.")

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

// ============================================
// CLOTHING PLATING SYSTEM
// ============================================

/// Armor values for each plating tier
#define PLATING_TIER_1_ARMOR 20
#define PLATING_TIER_2_ARMOR 40
#define PLATING_TIER_3_ARMOR 60
#define PLATING_TIER_4_ARMOR 80

/**
 * Clothing Plating - Tier 1
 * Provides 20 armor to RED, WHITE, BLACK, PALE when attached to resurgence suit.
 */
/obj/item/resurgence_plating
	name = "tier 1 clothing plating"
	desc = "Lightweight metal plating that can be attached to clan-woven suits for protection. Provides 20 armor to all damage types."
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-plasteel"
	w_class = WEIGHT_CLASS_SMALL
	/// The tier of this plating (1-4)
	var/plating_tier = 1
	/// Armor value this plating provides
	var/armor_value = PLATING_TIER_1_ARMOR

/obj/item/resurgence_plating/examine(mob/user)
	. = ..()
	. += span_notice("Attach to clan-woven suits to set armor to [armor_value].")
	if(plating_tier > 1)
		. += span_notice("Requires tier [plating_tier - 1] plating to already be attached.")

/obj/item/resurgence_plating/tier2
	name = "tier 2 clothing plating"
	desc = "Reinforced metal plating that can be attached to clan-woven suits for protection. Provides 40 armor to all damage types. Requires tier 1 plating first."
	plating_tier = 2
	armor_value = PLATING_TIER_2_ARMOR

/obj/item/resurgence_plating/tier3
	name = "tier 3 clothing plating"
	desc = "Heavy metal plating that can be attached to clan-woven suits for protection. Provides 60 armor to all damage types. Requires tier 2 plating first."
	plating_tier = 3
	armor_value = PLATING_TIER_3_ARMOR

/obj/item/resurgence_plating/tier4
	name = "tier 4 clothing plating"
	desc = "Master-crafted metal plating that can be attached to clan-woven suits for protection. Provides 80 armor to all damage types. Requires tier 3 plating first."
	plating_tier = 4
	armor_value = PLATING_TIER_4_ARMOR

/**
 * Helper proc to attach plating to resurgence suit.
 * Checks tier requirements and applies armor values.
 */
/proc/try_attach_plating(obj/item/clothing/suit/resurgence/C, obj/item/resurgence_plating/P, mob/user, current_tier)
	// Check if this clothing already has the same or higher tier
	if(current_tier >= P.plating_tier)
		to_chat(user, span_warning("[C] already has tier [current_tier] plating attached!"))
		return null

	// Check if we need a previous tier first
	if(P.plating_tier > 1 && current_tier != (P.plating_tier - 1))
		to_chat(user, span_warning("[C] needs tier [P.plating_tier - 1] plating before you can attach tier [P.plating_tier]!"))
		return null

	// Apply the plating
	C.armor = list(RED_DAMAGE = P.armor_value, WHITE_DAMAGE = P.armor_value, BLACK_DAMAGE = P.armor_value, PALE_DAMAGE = P.armor_value)

	to_chat(user, span_notice("You attach [P] to [C], setting armor to [P.armor_value]."))
	playsound(C, 'sound/items/Screwdriver.ogg', 50, TRUE)
	qdel(P)
	return P.plating_tier

#undef PLATING_TIER_1_ARMOR
#undef PLATING_TIER_2_ARMOR
#undef PLATING_TIER_3_ARMOR
#undef PLATING_TIER_4_ARMOR
