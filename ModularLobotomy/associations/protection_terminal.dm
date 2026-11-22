
/obj/structure/protection
	name = "protection contract radio"
	desc = "A radio used by Zwei associated offices to get contracts. payment is made in timed intervals based on performance"
	icon = 'icons/obj/radio.dmi'
	icon_state = "radio"
	max_integrity = 300
	density = 1
	anchored = 1
	resistance_flags = INDESTRUCTIBLE
	var/livingplayers = 0
	var/isstarted = FALSE

/obj/structure/protection/attack_hand(mob/user)
	if(isstarted == FALSE)
		FindLiving()
		isstarted = TRUE
	else
		say("Contract already accepted.")

/obj/structure/protection/proc/FindLiving(mob/living/user)
	livingplayers = 0
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.z != z)
			continue
		if(H.stat == DEAD)
			continue
		livingplayers += 1
		new /obj/item/stack/spacecash/c100 (get_turf(src))
	say("Currently, there are [livingplayers] citizens alive. Payment issued.")

	addtimer(CALLBACK(src, PROC_REF(FindLiving)), 5 MINUTES) //automatically continues after the first manual activation. they should always be protecting.

