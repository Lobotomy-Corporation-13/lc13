
/obj/structure/distortionradio
	name = "Distortion radio"
	desc = "A radio used by the Udjat to locate distortions. You could sell solidified sins here."
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
	var/resolve_payment = 750
	var/list/sin_prices = list(
		/obj/item/solidified_sin = 1250,
	)
	var/list/cash_types = list(
		/obj/item/stack/spacecash/c10000,
		/obj/item/stack/spacecash/c1000,
		/obj/item/stack/spacecash/c500,
		/obj/item/stack/spacecash/c200,
		/obj/item/stack/spacecash/c100,
		/obj/item/stack/spacecash/c50,
		/obj/item/stack/spacecash/c20,
		/obj/item/stack/spacecash/c10,
		/obj/item/stack/spacecash/c1,
	)

/obj/structure/distortionradio/attackby(obj/item/I, mob/living/user, params)
	for(var/sin_type in sin_prices)
		if(!istype(I, sin_type))
			continue
		say("Solidified sin received. Issuing payment.")
		SpawnCash(sin_prices[sin_type])
		qdel(I)
		return TRUE
	return ..()

//This should allow for easier custom prices in the future.
/obj/structure/distortionradio/proc/SpawnCash(value)
	for(var/obj/item/stack/spacecash/cash as anything in cash_types)
		var/count = round(value / initial(cash.value))
		if(!count)
			continue
		new cash(get_turf(src), count)
		value -= count * initial(cash.value)

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
		SpawnCash(resolve_payment)
		target = null
		docheck = FALSE
	else
		say("Current distortion still active.")
		return

//For testing, we are only keeping the advanced distortions.
/obj/structure/distortionradio/proc/FindTarget(mob/living/user)
	var/list/available_targets = list(
		/mob/living/simple_animal/hostile/distortion/advanced/another_day,
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

