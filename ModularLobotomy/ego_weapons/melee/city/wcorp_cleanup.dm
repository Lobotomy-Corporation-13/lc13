//W-Corp Cleanup Weapons - Cannot attack sane humans, deals WHITE damage to insane targets instead of BLACK

/obj/item/ego_weapon/city/wcorp/cleanup
	name = "w-corp cleanup baton"
	desc = "A glowing blue baton used by W-Corp cleanup crews. It refuses to harm sane humans."
	special = "Cannot attack sane humans. Deals WHITE damage to insane targets instead of BLACK."

/obj/item/ego_weapon/city/wcorp/cleanup/attack(mob/living/target, mob/living/user)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(!H.sanity_lost)
			to_chat(user, span_warning("[src] refuses to harm a sane human!"))
			return FALSE
		//Switch to WHITE damage for insane targets
		var/original_damtype = damtype
		damtype = WHITE_DAMAGE
		. = ..()
		damtype = original_damtype
		return
	return ..()

/obj/item/ego_weapon/city/wcorp/fist/cleanup
	name = "w-corp cleanup gauntlet"
	desc = "A glowing blue fist used by W-Corp cleanup crews. It refuses to harm sane humans."
	special = "Cannot attack sane humans. Deals WHITE damage to insane targets instead of BLACK."

/obj/item/ego_weapon/city/wcorp/fist/cleanup/attack(mob/living/target, mob/living/user)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(!H.sanity_lost)
			to_chat(user, span_warning("[src] refuses to harm a sane human!"))
			return FALSE
		var/original_damtype = damtype
		damtype = WHITE_DAMAGE
		. = ..()
		damtype = original_damtype
		return
	return ..()

/obj/item/ego_weapon/city/wcorp/axe/cleanup
	name = "w-corp cleanup axe"
	desc = "A glowing blue axe used by W-Corp cleanup crews. It refuses to harm sane humans."
	special = "Cannot attack sane humans. Deals WHITE damage to insane targets instead of BLACK."

/obj/item/ego_weapon/city/wcorp/axe/cleanup/attack(mob/living/target, mob/living/user)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(!H.sanity_lost)
			to_chat(user, span_warning("[src] refuses to harm a sane human!"))
			return FALSE
		var/original_damtype = damtype
		damtype = WHITE_DAMAGE
		. = ..()
		damtype = original_damtype
		return
	return ..()

/obj/item/ego_weapon/city/wcorp/spear/cleanup
	name = "w-corp cleanup spear"
	desc = "A glowing blue spear used by W-Corp cleanup crews. It refuses to harm sane humans."
	special = "Cannot attack sane humans. Deals WHITE damage to insane targets instead of BLACK."

/obj/item/ego_weapon/city/wcorp/spear/cleanup/attack(mob/living/target, mob/living/user)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(!H.sanity_lost)
			to_chat(user, span_warning("[src] refuses to harm a sane human!"))
			return FALSE
		var/original_damtype = damtype
		damtype = WHITE_DAMAGE
		. = ..()
		damtype = original_damtype
		return
	return ..()

/obj/item/ego_weapon/city/wcorp/dagger/cleanup
	name = "w-corp cleanup dagger"
	desc = "A glowing blue dagger used by W-Corp cleanup crews. It refuses to harm sane humans."
	special = "Cannot attack sane humans. Deals WHITE damage to insane targets instead of BLACK."

/obj/item/ego_weapon/city/wcorp/dagger/cleanup/attack(mob/living/target, mob/living/user)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(!H.sanity_lost)
			to_chat(user, span_warning("[src] refuses to harm a sane human!"))
			return FALSE
		var/original_damtype = damtype
		damtype = WHITE_DAMAGE
		. = ..()
		damtype = original_damtype
		return
	return ..()

/obj/item/ego_weapon/city/wcorp/hatchet/cleanup
	name = "w-corp cleanup hatchet"
	desc = "A glowing blue W-Corp handaxe used by cleanup crews. It refuses to harm sane humans."
	special = "Cannot attack sane humans. Deals WHITE damage to insane targets instead of BLACK."

/obj/item/ego_weapon/city/wcorp/hatchet/cleanup/attack(mob/living/target, mob/living/user)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(!H.sanity_lost)
			to_chat(user, span_warning("[src] refuses to harm a sane human!"))
			return FALSE
		var/original_damtype = damtype
		damtype = WHITE_DAMAGE
		. = ..()
		damtype = original_damtype
		return
	return ..()

/obj/item/ego_weapon/city/wcorp/hammer/cleanup
	name = "w-corp cleanup warhammer"
	desc = "A glowing blue W-Corp warhammer used by cleanup crews. It refuses to harm sane humans."
	special = "Cannot attack sane humans. Deals WHITE damage to insane targets instead of BLACK."

/obj/item/ego_weapon/city/wcorp/hammer/cleanup/attack(mob/living/target, mob/living/user)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(!H.sanity_lost)
			to_chat(user, span_warning("[src] refuses to harm a sane human!"))
			return FALSE
		var/original_damtype = damtype
		damtype = WHITE_DAMAGE
		. = ..()
		damtype = original_damtype
		return
	return ..()

//Type-C Cleanup Weapons

/obj/item/ego_weapon/city/wcorp/shield/cleanup
	name = "w-corp type-C cleanup shieldblade"
	desc = "A glowing blue W-Corp blade used by cleanup crews. It refuses to harm sane humans."
	special = "Cannot attack sane humans. Deals WHITE damage to insane targets instead of BLACK."

/obj/item/ego_weapon/city/wcorp/shield/cleanup/attack(mob/living/target, mob/living/user)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(!H.sanity_lost)
			to_chat(user, span_warning("[src] refuses to harm a sane human!"))
			return FALSE
		var/original_damtype = damtype
		damtype = WHITE_DAMAGE
		. = ..()
		damtype = original_damtype
		return
	return ..()

/obj/item/ego_weapon/city/wcorp/shield/spear/cleanup
	name = "w-corp type-C cleanup shieldglaive"
	desc = "A glowing blue W-Corp glaive used by cleanup crews. It refuses to harm sane humans."
	special = "Cannot attack sane humans. Deals WHITE damage to insane targets instead of BLACK."

/obj/item/ego_weapon/city/wcorp/shield/spear/cleanup/attack(mob/living/target, mob/living/user)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(!H.sanity_lost)
			to_chat(user, span_warning("[src] refuses to harm a sane human!"))
			return FALSE
		var/original_damtype = damtype
		damtype = WHITE_DAMAGE
		. = ..()
		damtype = original_damtype
		return
	return ..()

/obj/item/ego_weapon/city/wcorp/shield/club/cleanup
	name = "w-corp type-C cleanup shieldclub"
	desc = "A glowing blue W-Corp club used by cleanup crews. It refuses to harm sane humans."
	special = "Cannot attack sane humans. Deals WHITE damage to insane targets instead of BLACK."

/obj/item/ego_weapon/city/wcorp/shield/club/cleanup/attack(mob/living/target, mob/living/user)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(!H.sanity_lost)
			to_chat(user, span_warning("[src] refuses to harm a sane human!"))
			return FALSE
		var/original_damtype = damtype
		damtype = WHITE_DAMAGE
		. = ..()
		damtype = original_damtype
		return
	return ..()

/obj/item/ego_weapon/city/wcorp/shield/axe/cleanup
	name = "w-corp type-C cleanup shieldaxe"
	desc = "A glowing blue W-Corp battleaxe used by cleanup crews. It refuses to harm sane humans."
	special = "Cannot attack sane humans. Deals WHITE damage to insane targets instead of BLACK."

/obj/item/ego_weapon/city/wcorp/shield/axe/cleanup/attack(mob/living/target, mob/living/user)
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(!H.sanity_lost)
			to_chat(user, span_warning("[src] refuses to harm a sane human!"))
			return FALSE
		var/original_damtype = damtype
		damtype = WHITE_DAMAGE
		. = ..()
		damtype = original_damtype
		return
	return ..()
