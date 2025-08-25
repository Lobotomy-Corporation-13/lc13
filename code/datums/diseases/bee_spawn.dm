/datum/disease/bee_spawn
	name = "Bee Infection"
	form = "Infection"
	max_stages = 5
	stage_prob = 33
	spread_text = "Blood"
	disease_flags = CAN_CARRY
	spread_flags = DISEASE_SPREAD_BLOOD
	cure_text = "Nothing"
	viable_mobtypes = list(/mob/living/carbon/human)
	severity = DISEASE_SEVERITY_HARMFUL
	var/affected_mob_type = /mob/living/carbon/human
	var/spawned_bee_type = /mob/living/simple_animal/hostile/worker_bee

/datum/disease/bee_spawn/after_add()
	affected_mob.playsound_local(get_turf(affected_mob), 'sound/abnormalities/bee/infect.ogg', 25, 0)

/datum/disease/bee_spawn/stage_act()
	. = ..()
	if(!.)
		return

	if(!istype(affected_mob, affected_mob_type))
		return

	var/mob/living/carbon/C = affected_mob
	C.apply_damage(stage*2, RED_DAMAGE, null, C.run_armor_check(null, RED_DAMAGE), spread_damage = TRUE)

	if(C.health <= 0)
		var/turf/T = get_turf(C)
		C.visible_message("<span class='danger'>[C] explodes in a shower of gore, as a giant bee appears out of [C.p_them()]!</span>")
		C.emote("scream")
		C.gib()
		new spawned_bee_type(T)
		return

	if((stage >= max_stages) && (C.health >= (C.maxHealth * 0.75)) && prob(C.health * 0.25))
		cure(FALSE)

/datum/disease/bee_spawn/limbus_bee_spawn
	affected_mob_type = /mob/living/carbon
	spawned_bee_type = /mob/living/simple_animal/hostile/worker_bee/lcl_bee
