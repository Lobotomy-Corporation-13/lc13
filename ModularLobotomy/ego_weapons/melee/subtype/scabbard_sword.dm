// Weapons that usually come in a pair, a sword and a sheathe.
// The scabbard here is a subtype of the shield, because they're meant to be used as a sheath for the actual weapon, though blocking with a sheath is cool as hell.
// Preferably every scabbard and every scabbard_sword.
/obj/item/ego_weapon/shield/scabbard
	name = "scabbard"
	desc = "placeholder"
	special = "placeholder"
	icon_state = "kurokumo"
	inhand_icon_state = "kurokumo"
	force = 20
	damtype = RED_DAMAGE
	reductions = list(20, 20, 20, 20)
	// the 'stored sword' var
	var/obj/item/ego_weapon/scabbard_sword/sheathed_sword
	// fx and sfx
	var/sheathing_sfx = 'sound/weapons/ego/hwando_sword_sheathe.ogg' // Default Sheathe Noise!
	var/unsheathing_sfx = 'sound/weapons/ego/hwando_sword_draw.ogg' // Default Unsheathing Noise!
	// change this var appropriately if the sheathe isn't meant to be universally used with all scabbard_sword
	var/worthy_sword = /obj/item/ego_weapon/scabbard_sword
	// messages to the user
	var/scabbard_is_not_held_message = span_warning("hold sword to sheathe")
	var/scabbard_is_full = span_warning("already has a sword") // sent when the user tries to sheathe a sword but it's already full
	var/scabbard_is_empty = span_warning("no sword") // sent when the user tries to unsheathe and the scabbard is empty

/obj/item/ego_weapon/shield/scabbard/attackby(obj/item/I, mob/living/user, params) // click with an empty hand to unsheathe! but you must be holding the sheathe to unsheathe the sword out of it
	. = ..()
	if(!istype(I, worthy_sword))
		return FALSE
	if(!(src in user.held_items) || !(src in user.get_item_by_slot(ITEM_SLOT_BELT)))
		to_chat(user, scabbard_is_not_held_message)
		return FALSE

	return Sheathe(user, I)

/obj/item/ego_weapon/shield/scabbard/proc/Sheathe(mob/user, obj/item/ego_weapon/scabbard_sword/sword) // where the actual sheathing happens
	if(!istype(user) || !istype(sword))
		return FALSE
	if(sheathed_sword)
		to_chat(user, scabbard_is_full)
		return FALSE

	// Sheathing the sword
	sheathed_sword = sword
	sheathed_sword.forceMove(src)

	// SFX and VFX
	playsound(get_turf(user), sheathing_sfx, 100, FALSE)

	return TRUE

/obj/item/ego_weapon/shield/scabbard/attack_hand(mob/user) // Makes it so that when you click on it, it doesn't just switch hands.
	if(sheathed_sword && isliving(user))
		UnSheathe(user)
		return
	return ..()

/obj/item/ego_weapon/shield/scabbard/proc/UnSheathe(mob/living/carbon/human/user) // where the actual unsheathing happens
	if(!sheathed_sword)
		to_chat(user, scabbard_is_empty)
		return
	if(!istype(user))
		return
	sheathed_sword.forceMove(get_turf(user))
	user.put_in_active_hand(sheathed_sword)
	to_chat(user, span_notice("unsheathe"))
	playsound(get_turf(user), unsheathing_sfx, 100, FALSE)
	sheathed_sword = null
