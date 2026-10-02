
/obj/structure/assassination
	name = "assassination contract radio"
	desc = "A radio used by assassin offices to get contracts. Confirm kills with the Assassin's Confirmation"
	icon = 'icons/obj/radio.dmi'
	icon_state = "radio"
	max_integrity = 300
	density = 1
	anchored = 1
	resistance_flags = INDESTRUCTIBLE
	var/isready = TRUE
	var/mob/target

/obj/structure/assassination/attack_hand(mob/user)
	if(!isready)
		say("No new targets available.")
		return

	if(target)
		say("Current Target: [target.name]")
		return


	isready = FALSE

	var/list/available_targets = list()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H == user)
			continue
		if(H.stat == DEAD)
			continue
		available_targets += H

	target = pick(available_targets)
	say("Target Selected: [target.name].")

/obj/structure/assassination/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	if(I.type != /obj/item/assassin_link)
		attack_hand(user)
		return

	var/obj/item/assassin_link/link = I
	if(link.held_target == target)
		say("Target Slain. Issuing payment.")
		new /obj/item/stack/spacecash/c1000 (get_turf(src))
	else
		say("Invalid Target.")
	addtimer(CALLBACK(src, PROC_REF(NewTarget)), 10 MINUTES)


/obj/structure/assassination/proc/NewTarget()
	isready = TRUE


/obj/item/assassin_link
	name = "assassin's confirmation"
	desc = "A trinket that stores the last killed human in it's database"
	icon = 'icons/obj/radio.dmi'
	icon_state = "assassin_trinket"
	var/mob/held_target


/obj/item/assassin_link/attack(mob/living/target, mob/living/user)
	if(target.stat != DEAD)
		to_chat(user,span_warning("Target must be dead."))
		return

	to_chat(user,span_nicegreen("Target logged."))
	held_target = target

/obj/item/assassin_link/examine(mob/user)
	. = ..()
	if(held_target)
		to_chat(user,span_nicegreen("Target logged: [held_target.name]"))