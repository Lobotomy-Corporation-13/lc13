/mob/living/simple_animal/hostile/abnormality/branch12/make_anything
	name = "I Can Make Anything"
	desc = "A human-sized container with a skull shaped head"
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/32x32.dmi'
	icon_state = "makeanything"
	icon_living = "makeanything"

	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = 70,
		ABNORMALITY_WORK_INSIGHT = 40,
		ABNORMALITY_WORK_ATTACHMENT = 25,
		ABNORMALITY_WORK_REPRESSION = 70,
	)
	work_damage_amount = 5
	work_damage_type = PALE_DAMAGE
	threat_level = ZAYIN_LEVEL
	max_boxes = 10

	abnormality_origin = ABNORMALITY_ORIGIN_BRANCH12

	ego_list = list(
		/datum/ego_datum/weapon/branch12/making,
		//datum/ego_datum/armor/branch12/making,
	)


/mob/living/simple_animal/hostile/abnormality/branch12/make_anything/SuccessEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(60))
		return
	var/item = rand(1, 3)
	switch(item)
		if(1)
			var/grenade = pick(/obj/item/grenade/r_corp/white, /obj/item/grenade/r_corp, /obj/item/grenade/r_corp/black)
			new grenade(get_turf(user))
		if(2)
			new /obj/item/powered_gadget/handheld_taser/xcorp(get_turf(user))
		if(3)
			new /obj/item/xcorp_capsule(get_turf(user))


//The taser
/obj/item/powered_gadget/handheld_taser/xcorp
	name = "XX-Corp Advanced Taser"
	desc = "A portable electricution device. Two settings, stun and slow. Automatically slows abnormalities instead of stunning them. \
	This one costs no power and runs off mysterious energy."
	icon_state = "taser"
	default_icon = "taser"
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/gadgets.dmi'
	batterycost = 0
	batterycost_stun = 0
	batterycost_slow = 0

//xxcorp healing Capsules
/obj/item/xcorp_capsule
	name = "XX-Corp Healing Capsule"
	desc = "A small capsule that heals humans around you."
	icon = 'ModularLobotomy/_Lobotomyicons/branch12/gadgets.dmi'
	icon_state = "healing"
	slot_flags = ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_SMALL
	var/heal_amount = 20
	var/heal_range = 4

/obj/item/xcorp_capsule/attack_self(mob/living/carbon/human/user)
	..()
	to_chat(user, span_notice("You open the capsule and healing gas wafts to everyone around you."))
	for (var/mob/living/carbon/human/H in range(heal_range, src))
		H.adjustBruteLoss(-heal_amount)
		H.adjustSanityLoss(-heal_amount)
	qdel(src)
