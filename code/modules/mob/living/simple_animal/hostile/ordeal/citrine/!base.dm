//The gimmick of citrine ordeals is that they generate faith.
//Upon reaching maximum faith, all Citrine ordeals get extra attacks.
/mob/living/simple_animal/hostile/ordeal/citrine
	mob_biotypes = MOB_ROBOTIC
	var/faith_per_lifetick = 0
	var/faith_active
	var/faith_line = "He gives us strength! Praise His name!"


//Check your life, add to the ordeals Faith, check the faith goal and then say the faith line.
/mob/living/simple_animal/hostile/ordeal/citrine/Life()
	. = ..()
	if(ordeal_reference && !faith_active)
		var/datum/ordeal/simplespawn/citrine/C = ordeal_reference
		C.current_faith += faith_per_lifetick
		if(C.current_faith >= C.faith_goal)
			SLEEP_CHECK_DEATH(rand(1,30))
			say(faith_line)
			faith_active = TRUE
			FaithActivate()


/mob/living/simple_animal/hostile/ordeal/citrine/proc/FaithActivate()
	return

//Here's the gibs
/mob/living/simple_animal/hostile/ordeal/citrine/spawn_gibs()
	new /obj/effect/gibspawner/scrap_metal(drop_location(), src)

//This is the base Citrine Fire that lasts a short period of time.

/obj/effect/turf_fire/citrine
	damaging = TRUE
	burn_time = 5 SECONDS
	fire_damage = 2


/mob/living/simple_animal/hostile/ordeal/citrine/proc/citrine_fire_line(atom/source, list/turfs, damage)
	var/list/hit_list = list()
	for(var/turf/T in turfs)
		if(istype(T, /turf/closed))
			break
		new /obj/effect/turf_fire/citrine(T)
		for(var/mob/living/L in T.contents)
			if(L in hit_list || istype(L, source.type))
				continue
			hit_list += L
			L.adjustFireLoss(damage)
			to_chat(L, span_userdanger("You're hit by [source]'s fire breath!"))

		// deals damage to mechs
		for(var/obj/vehicle/sealed/mecha/M in T.contents)
			if(M in hit_list)
				continue
			hit_list += M
			M.take_damage(45, MELEE, 1)
		SLEEP_CHECK_DEATH(1.5)
		playsound(T, 'sound/effects/burn.ogg', 75, FALSE, 4)
