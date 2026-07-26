/obj/item/bolus
	name = "bolus template"
	desc = "You should not be seeing this!."
	icon = 'ModularLobotomy/_Lobotomyicons/bolus.dmi'
	icon_state = "bolus"

	//Do not change this please!
	var/capacity = 10

	//I should make this a list but I am coding at 2am
	var/wood_in = 0
	var/water_in = 0
	var/fire_in = 0
	var/earth_in = 0
	var/metal_in = 0

	var/ignores_standard	//Does it do what standard boluses do
	var/activated
	var/list/abilities = list("No effect.")


//Examine Text

/obj/item/bolus/examine(mob/user)
	. = ..()
	for(var/item in abilities)
		. += span_notice(item)

	if(ignores_standard)
		. += span_warning("This bolus does not get the standard buffs from essences.")

	. += span_notice("<a href='byond://?src=[REF(src)];list_attributes=1'>--Essence Information--")
	. += span_notice("Capacity Remaining: [capacity]")
	. += span_notice("Wood Essence: [wood_in]")
	. += span_notice("Water Essence: [water_in]")
	. += span_notice("Fire Essence: [fire_in]")
	. += span_notice("Earth Essence: [earth_in]")
	. += span_notice("Metal Essence: [metal_in]")


/obj/item/bolus/Topic(href, href_list)
	. = ..()
	if(href_list["list_attributes"])
		to_chat(usr, span_notice("--------------------------------------------------------------"))
		to_chat(usr, span_notice("Each Basic element gives standard temporary buffs."))
		to_chat(usr, span_notice("Each Wood gives +7 HP on use"))
		to_chat(usr, span_notice("Each Water gives +7 SP on use"))
		to_chat(usr, span_notice("Each Fire gives +3% Damage on use, for 30 seconds per fire added"))
		to_chat(usr, span_notice("Each Earth gives +2% Movement on use, for 30 seconds per earth added"))
		to_chat(usr, span_notice("Each Metal gives +3% Armor on use, for 30 seconds per Metal added."))


/obj/item/bolus/attackby(obj/item/I, mob/user, params)
	if(!capacity)
		return

	if(!(istype(I, /obj/item/essence)))
		return

	to_chat(user, span_notice("You add the [I] to the [name]..."))
	capacity --
	if(istype(I, /obj/item/essence/wood))
		wood_in ++
	if(istype(I, /obj/item/essence/fire))
		fire_in ++
	if(istype(I, /obj/item/essence/water))
		water_in ++
	if(istype(I, /obj/item/essence/earth))
		earth_in ++
	if(istype(I, /obj/item/essence/metal))
		metal_in ++

	qdel(I)

/obj/item/bolus/attack_self(mob/living/carbon/user)
	if (!ishuman(user))
		return
	if(activated)
		to_chat(user, span_notice("This bolus is used up."))
		return

	if(HAS_TRAIT(user, TRAIT_BOLUSFATIGUE))
		to_chat(user, span_notice("You have used a bolus too recently."))
		return

	ADD_TRAIT(user, TRAIT_BOLUSFATIGUE, GENERIC_ITEM_TRAIT)

	//Make it a little junk object on the ground for a bit.
	name = "used bolus"
	icon_state = "bolus_empty"
	activated = TRUE
	QDEL_IN(src, 10 MINUTES)
	to_chat(user, span_notice("You use the bolus, ridding it of all power."))

	//Okay, run the standard and special stuff
	Bolus_Special(user)
	if(!ignores_standard)
		Bolus_Standard(user)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(AllowBolus), user), 7 MINUTES)


/obj/item/bolus/proc/AllowBolus(mob/living/carbon/user)
	REMOVE_TRAIT(user, TRAIT_BOLUSFATIGUE, GENERIC_ITEM_TRAIT)

//This is all the unique Bolus stuff
/obj/item/bolus/proc/Bolus_Special(mob/living/carbon/human/user)
	return

//This stuff all comes standard.
/obj/item/bolus/proc/Bolus_Standard(mob/living/carbon/human/user)
	if(water_in)
		user.adjustSanityLoss(-water_in*7)

	if(wood_in)
		user.adjustBruteLoss(-wood_in*7)

	if(earth_in)
		user.add_movespeed_modifier(/datum/movespeed_modifier/bolus_earth)
		user.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/bolus_earth, multiplicative_slowdown = earth_in*-0.02)
		addtimer(CALLBACK(user, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/bolus_earth), 300 * earth_in, TIMER_UNIQUE | TIMER_OVERRIDE)

	if(fire_in)
		user.extra_damage += 0.03 * fire_in
		addtimer(CALLBACK(src, PROC_REF(RemoveFire), user), fire_in *300)

	if(metal_in)
		var/metal_mod = metal_in*0.03 + 1
		user.physiology.red_mod /= metal_mod
		user.physiology.white_mod /= metal_mod
		user.physiology.black_mod /= metal_mod
		user.physiology.pale_mod /= metal_mod
		addtimer(CALLBACK(src, PROC_REF(RemoveMetal), user), metal_in *300)
	return


/obj/item/bolus/proc/RemoveFire(mob/living/carbon/human/user)
	user.extra_damage -= 0.03 * fire_in

/obj/item/bolus/proc/RemoveMetal(mob/living/carbon/human/user)
	var/metal_mod = metal_in*0.03 + 1
	user.physiology.red_mod *= metal_mod
	user.physiology.white_mod *= metal_mod
	user.physiology.black_mod *= metal_mod
	user.physiology.pale_mod *= metal_mod

/datum/movespeed_modifier/bolus_earth
	variable = TRUE
	multiplicative_slowdown = 0


