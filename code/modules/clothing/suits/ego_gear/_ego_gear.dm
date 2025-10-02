/obj/item/clothing/suit/armor/ego_gear
	name = "ego gear"
	desc = "You aren't meant to see this."
	icon = 'icons/obj/clothing/ego_gear/suits.dmi'
	worn_icon = 'icons/mob/clothing/ego_gear/suit.dmi'
	blood_overlay_type = null
	flags_inv = HIDEJUMPSUIT
	body_parts_covered = CHEST|GROIN|LEGS|FEET|ARMS|HANDS|HEAD 	// We protect all because magic
	cold_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS|HEAD
	heat_protection = CHEST|GROIN|LEGS|FEET|ARMS|HANDS|HEAD
	w_class = WEIGHT_CLASS_BULKY								//No more stupid 10 egos in bag
	allowed = list(/obj/item/gun, /obj/item/ego_weapon, /obj/item/melee)
	drag_slowdown = 1
	equip_delay_self = 7 SECONDS

	var/obj/item/clothing/head/ego_hat/hat = null // Hat type, see clothing/head/_ego_head.dm
	var/obj/item/clothing/neck/ego_neck/neck = null // Neckwear, see clothing/neck/_neck.dm
	var/obj/item/clothing/mask/ego_mask/mask = null //Mask type, see clothing/mask/_masks.dm
	var/list/attribute_requirements = list()
	var/equip_bonus

/obj/item/clothing/suit/armor/ego_gear/Initialize()
	. = ..()
	if(hat)
		var/obj/effect/proc_holder/ability/hat_ability/HA = new(null, hat)
		var/datum/action/spell_action/ability/item/H = HA.action
		H.SetItem(src)
	if(neck)
		var/obj/effect/proc_holder/ability/neck_ability/NA = new(null, neck)
		var/datum/action/spell_action/ability/item/N = NA.action
		N.SetItem(src)
	if(mask)
		var/obj/effect/proc_holder/ability/mask_ability/MA = new(null, mask)
		var/datum/action/spell_action/ability/item/M = MA.action
		M.SetItem(src)
	if(SSmaptype.chosen_trait == FACILITY_TRAIT_CALLBACK)
		w_class = WEIGHT_CLASS_NORMAL			//Callback to when we had stupid 10 Egos in bag

/obj/item/clothing/suit/armor/ego_gear/mob_can_equip(mob/living/receiver, mob/living/handler, slot, disable_warning, bypass_equip_delay_self)
	if(!(slot_flags & slot)) // Wrong slots so I do not care.
		return ..(receiver, handler, slot, disable_warning, bypass_equip_delay_self)
	if(!handler || receiver == handler) // Self-Dressed
		if(!CanUseEgo(receiver))
			return FALSE
		var/obj/machinery/computer/ego_purchase/A = locate() in range(6, receiver)
		var/obj/machinery/smartfridge/extraction_storage/ego_armor/B = locate() in range(6, receiver)
		if(A || B) // Despite popular desire, this will not be made so you can insta-strip someone near a fridge.
			bypass_equip_delay_self = TRUE
		return ..(receiver, handler, slot, disable_warning, bypass_equip_delay_self)
	if(!CanUseEgo(receiver)) // Dressed By Someone without Stats
		to_chat(handler, span_warning("[receiver] cannot use [src]!"))
		return FALSE
	return ..(receiver, handler, slot, disable_warning, bypass_equip_delay_self) // Dressed By Someone with Stats

/obj/item/clothing/suit/armor/ego_gear/item_action_slot_check(slot)
	if(slot == ITEM_SLOT_OCLOTHING) // Abilities are only granted when worn properly
		return TRUE

/obj/item/clothing/suit/armor/ego_gear/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_OCLOTHING)
		return
	if(hat)
		var/obj/item/clothing/head/headgear = user.get_item_by_slot(ITEM_SLOT_HEAD)
		if(!istype(headgear, hat))
			return
		headgear.Destroy()
	if(neck)
		var/obj/item/clothing/neck/neckwear = user.get_item_by_slot(ITEM_SLOT_NECK)
		if(!istype(neckwear, neck))
			return
		neckwear.Destroy()
	if(mask)
		var/obj/item/clothing/mask/maskwear = user.get_item_by_slot(ITEM_SLOT_MASK)
		if(!istype(maskwear, mask))
			return
		maskwear.Destroy()

/obj/item/clothing/suit/armor/ego_gear/dropped(mob/user)
	. = ..()
	if(hat)
		var/obj/item/clothing/head/headgear = user.get_item_by_slot(ITEM_SLOT_HEAD)
		if(!istype(headgear, hat))
			return
		headgear.Destroy()
	if(neck)
		var/obj/item/clothing/neck/neckwear = user.get_item_by_slot(ITEM_SLOT_NECK)
		if(!istype(neckwear, neck))
			return
		neckwear.Destroy()
	if(mask)
		var/obj/item/clothing/mask/maskwear = user.get_item_by_slot(ITEM_SLOT_MASK)
		if(!istype(maskwear, mask))
			return
		maskwear.Destroy()

/obj/item/clothing/suit/armor/ego_gear/proc/CanUseEgo(mob/living/carbon/human/user)
	if(!ishuman(user))
		return FALSE
	if(user.mind)
		if(user.mind.assigned_role == "Sephirah") //This is an RP role
			return FALSE

	for(var/atr in attribute_requirements)
		if(attribute_requirements[atr] > get_attribute_level(user, atr) + equip_bonus)
			return FALSE
	if(!SpecialEgoCheck(user))
		return FALSE
	return TRUE

/obj/item/clothing/suit/armor/ego_gear/proc/SpecialEgoCheck(mob/living/carbon/human/H)
	return TRUE

/obj/item/clothing/suit/armor/ego_gear/proc/SpecialGearRequirements()
	return

/obj/item/clothing/suit/armor/ego_gear/examine(mob/user)
	. = ..()
	if(LAZYLEN(attribute_requirements))
		if(!ishuman(user))	//You get a notice if you are a ghost or otherwise
			. += span_notice("It has <a href='byond://?src=[REF(src)];list_attributes=1'>certain requirements</a> for the wearer.")
		else if(CanUseEgo(user))	//It's green if you can use it
			. += span_nicegreen("It has <a href='byond://?src=[REF(src)];list_attributes=1'>certain requirements</a> for the wearer.")
		else				//and red if you cannot use it
			. += span_danger("You cannot use this EGO!")
			. += span_danger("It has <a href='byond://?src=[REF(src)];list_attributes=1'>certain requirements</a> for the wearer.")

/obj/item/clothing/suit/armor/ego_gear/Topic(href, href_list)
	. = ..()
	if(href_list["list_attributes"])
		var/display_text = span_boldwarning("It requires the following attributes:")
		for(var/atr in attribute_requirements)
			if(attribute_requirements[atr] > 0)
				display_text += span_warning("\n [atr]: [attribute_requirements[atr]].</span>")
		display_text += SpecialGearRequirements()
		to_chat(usr, display_text)

