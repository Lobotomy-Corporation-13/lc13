GLOBAL_LIST_EMPTY(estus_holders)	//list of people that have used an estus flask

//The Estus Flask
/obj/item/estus
	name = "Estus Flask"
	desc = "The Undead treasure these dull green flasks. \
			Fill with Estus at Bonfire. Fills HP and SP."
	icon = 'ModularLobotomy/_Lobotomyicons/station_traits.dmi'
	icon_state = "estus"
	slot_flags = ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_SMALL
	var/charges = 5
	var/drinktime = 2 SECONDS
	var/linked_user

/obj/item/estus/attack_self(mob/living/carbon/human/user)
	..()
	if(user in GLOB.estus_holders)
		to_chat(user, span_warning("You already have a class."))
		return

	if(!linked_user)
		linked_user = user
		GLOB.estus_holders |= user

	if(linked_user!=user)
		to_chat(user, span_warning("This flask isn't yours."))
		return

	if(!charges)
		to_chat(user, span_warning("Your flask is empty."))
		return

	if(!do_after(user, drinktime, src)) //gotta reload
		to_chat(user, span_warning("Your drinking is interrupted."))
		return

	to_chat(user, span_notice("You sip of the estus flask."))
	user.adjustBruteLoss(-60)
	user.adjustSanityLoss(-60)
	charges --

/obj/item/estus/examine(mob/living/carbon/human/user)
	. = ..()
	. += span_notice("Charges left: [charges]/5.")
	. += span_notice("Linked Soul: [linked_user].")

/obj/item/estus/Destroy()
	linked_user = null
	. = ..()

/obj/structure/darksouls_bonfire
	name = "Estus-Bonfire"
	desc = "Refill your estus flasks here."
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "bonfire_on_fire"
	light_color = LIGHT_COLOR_FIRE
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE
	light_range = 3
	light_power = 2
	var/filltime = 10 SECONDS

/obj/structure/darksouls_bonfire/attackby(obj/item/I, mob/living/carbon/human/user)
	if(I.type != /obj/item/estus)
		return
	if(!do_after(user, filltime, src))
		to_chat(user, span_warning("You have trouble refilling your flask, and spill it everywhere."))
		return

	var/obj/item/estus/E = I
	E.charges = initial(E.charges)
	to_chat(user, span_nicegreen("You fill your flask with estus."))
