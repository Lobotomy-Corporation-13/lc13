
/obj/structure/distortionradio
	name = "Distortion radio"
	desc = "A radio used by the Udjat to locate distortions."
	icon = 'icons/obj/radio.dmi'
	icon_state = "radio"
	max_integrity = 300
	density = 1
	anchored = 1
	resistance_flags = INDESTRUCTIBLE
	var/isready = TRUE
	var/docheck = FALSE
	var/mob/living/target
	var/list/deploy_pool = list()

/obj/structure/distortionradio/attack_hand(mob/user)
	if(!isready)
		say("No new distortions located.")

		if(docheck)
			CheckTarget()
		return

	isready = FALSE
	FindTarget(user)
	docheck = TRUE

/obj/structure/distortionradio/proc/CheckTarget()
	if(!target || target.stat == DEAD)
		say("Distortion resolved. Issuing payment.")
		new /obj/item/stack/spacecash/c1000 (get_turf(src))
		target = null
		docheck = FALSE
	else
		say("Current distortion still active.")
		return

/obj/structure/distortionradio/proc/FindTarget(mob/living/user)
	var/list/available_targets = list(
		/mob/living/simple_animal/hostile/distortion/papa_bongy,
		/mob/living/simple_animal/hostile/distortion/another_day_work,
		/mob/living/simple_animal/hostile/distortion/bunnyman,
		/mob/living/simple_animal/hostile/distortion/lantern,
	)

	var/nexttarget = pick(available_targets)
	for(var/obj/effect/landmark/cityspawner/landmark in GLOB.landmarks_list)
		deploy_pool += landmark
	var/deploy_spot = pick(deploy_pool)
	var/mob/living/simple_animal/hostile/M = new nexttarget(get_turf(deploy_spot))
	target = M
	say("New target detected.")
	addtimer(CALLBACK(src, PROC_REF(NewTarget)), 10 MINUTES)

/obj/structure/distortionradio/proc/NewTarget()
	isready = TRUE

