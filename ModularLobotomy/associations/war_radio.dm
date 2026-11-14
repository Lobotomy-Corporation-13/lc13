
/obj/structure/warradio
	name = "War radio"
	desc = "A radio used by the Udjat to locate distortions."
	icon = 'icons/obj/radio.dmi'
	icon_state = "radio"
	max_integrity = 300
	density = 1
	anchored = 1
	resistance_flags = INDESTRUCTIBLE
	var/isready = TRUE
	var/list/deploy_pool = list()

/obj/structure/warradio/attack_hand(mob/user)
	if(!isready)
		say("The streets are clear, for now.")
		return

	isready = FALSE
	FindTarget(user)

/obj/structure/warradio/proc/FindTarget(mob/living/user)
	var/list/available_targets = list(
		/mob/living/simple_animal/hostile/ordeal/indigo_dawn,
		/mob/living/simple_animal/hostile/ordeal/green_bot,
		/mob/living/simple_animal/hostile/ordeal/steel_dawn,
		/mob/living/simple_animal/hostile/clan/scout,
		/mob/living/simple_animal/hostile/humanoid/blood/bag,
	)

	var/nexttarget = pick(available_targets)
	for(var/obj/effect/landmark/cityspawner/landmark in GLOB.landmarks_list)
		deploy_pool += landmark
	if(!length(deploy_pool))
		return
	var/turf/deploy_spot = get_turf(pick(deploy_pool))
	for(var/i in 1 to 10)
		new nexttarget(deploy_spot)
	say("New target detected, payment issued preemptively.")
	new /obj/item/stack/spacecash/c1000 (get_turf(src))
	addtimer(CALLBACK(src, PROC_REF(NewTarget)), 10 MINUTES)

/obj/structure/warradio/proc/NewTarget()
	isready = TRUE

