/datum/job/limbus_specimen
	title = "LC Specimen"
	faction = "Station"
	selection_color = "#BB9999"
	total_positions = 8
	spawn_positions = 8 //Only put as many positions as there exists LCL abnos and spawn points, even if the special_check_latejoin should stop any issse.
	departments = DEPARTMENT_SECURITY
	maptype = "limbus_labs"
	job_abbreviation = "LCS"
	var/mob/living/picked_abno

//Checks if any abnos are available for a latejoin.
/datum/job/limbus_specimen/special_check_latejoin(client/C)
	for(var/obj/effect/landmark/start/limbus_abnospawn/LAS in GLOB.start_landmarks_list)
		return TRUE
	return FALSE

//This is absolute jank but it technically works. The job finds a spawner, creates an abnormality, and transfers the mind of the original person into it, then deletes the human.
/datum/job/limbus_specimen/equip(mob/living/carbon/human/H, visualsOnly, announce, latejoin, datum/outfit/outfit_override, client/preference_source = null)
	if(!H?.mind || visualsOnly)
		return FALSE

	var/spawning
	var/turf/abno_turf

	spawning = pick_n_take(GLOB.low_security) //Prioritize lowsec spawns first.
	for(var/obj/effect/landmark/start/limbus_abnospawn/lowsec/LS in GLOB.start_landmarks_list)
		GLOB.start_landmarks_list -= LS
		abno_turf = get_turf(LS)
		qdel(LS)
		break

	if(!abno_turf || !spawning) //If no lowsec landlarrks/abno are avilable, we go for highsec.
		spawning = pick_n_take(GLOB.high_security)
		for(var/obj/effect/landmark/start/limbus_abnospawn/highsec/HS in GLOB.start_landmarks_list)
			GLOB.start_landmarks_list -= HS
			abno_turf = get_turf(HS)
			qdel(HS)
			break

	if(!isnull(spawning) && !isnull(abno_turf))
		var/mob/living/simple_animal/hostile/limbus_abno/LA = new spawning(abno_turf)
		picked_abno = LA
		H.mind.transfer_to(picked_abno)
		qdel(H)
		return picked_abno
	return FALSE

/datum/job/limbus_specimen/override_latejoin_spawn()
	return TRUE
