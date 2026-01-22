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
	var/control_bee_on_death = FALSE
	var/spore_damage = 2

/datum/disease/bee_spawn/after_add()
	affected_mob.playsound_local(get_turf(affected_mob), 'sound/abnormalities/bee/infect.ogg', 25, 0)

/datum/disease/bee_spawn/stage_act()
	. = ..()
	if(!.)
		return

	if(!istype(affected_mob, affected_mob_type))
		return

	var/mob/living/carbon/human/H = affected_mob
	H.deal_damage(stage*spore_damage, RED_DAMAGE, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_STATUS))

	if(H.health <= 0)
		var/turf/T = get_turf(H)
		H.visible_message("<span class='danger'>[H] explodes in a shower of gore, as a giant bee appears out of [H.p_them()]!</span>")
		H.emote("scream")
		var/mob/living/simple_animal/hostile/worker_bee/bee = new spawned_bee_type(T)
		if(control_bee_on_death && H.mind)
			H.mind.transfer_to(bee)
		H.gib()
		return

	if((stage >= max_stages) && (H.health >= (H.maxHealth * 0.75)) && prob(H.health * 0.25))
		cure(FALSE)

/datum/disease/bee_spawn/limbus_bee_spawn
	affected_mob_type = /mob/living/carbon
	spawned_bee_type = /mob/living/simple_animal/hostile/worker_bee/lcl_bee
	control_bee_on_death = TRUE
	spore_damage = 0.2 //10% of the original damage.
