//This entire job is gimmicky snowflake bullshit. If you can think of a way to improve it, please do.
//but god, do not copy paste any of this for anything of your own, this code is NOT flexible.
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

//This should stop someone to spawn as an abno if none of their preferences are available at round start.
/datum/job/limbus_specimen/unique_job_check(client/C, occupation_divide)
	if(!LAZYLEN(return_sec_list(GLOB.low_security.Copy(), C)) && !LAZYLEN(return_sec_list(GLOB.high_security.Copy(), C)))
		return FALSE
	return attribute_abno(C, occupation_divide)

//Checks if any abnos are available for a latejoin.
/datum/job/limbus_specimen/special_check_latejoin(client/C)
	var/found_abno = LAZYACCESS(GLOB.attributed_lcl_abno, C)
	if(LAZYFIND(GLOB.lcl_spawned_abno, found_abno)) //The player's attributed abno has already been spawned, not allowed to try again.
		return FALSE
	for(var/obj/effect/landmark/start/limbus_abnospawn/LAS in GLOB.start_landmarks_list)
		if(LAZYLEN(return_sec_list(GLOB.available_low_sec_abno.Copy(), C)) || LAZYLEN(return_sec_list(GLOB.available_high_sec_abno.Copy(), C)))
			return TRUE
	return FALSE

//This is absolute jank but it technically works. The job finds a spawner, creates an abnormality, and transfers the mind of the original person into it, then deletes the human.
/datum/job/limbus_specimen/equip(mob/living/carbon/human/H, visualsOnly, announce, latejoin, datum/outfit/outfit_override, client/preference_source = null)
	if(!H?.mind || visualsOnly || !preference_source)
		return FALSE

	if(latejoin)
		attribute_abno(preference_source)

	var/abno_path = LAZYACCESS(GLOB.attributed_lcl_abno, preference_source)
	var/turf/abno_turf

	if(LAZYFIND(GLOB.low_security, abno_path))
		for(var/obj/effect/landmark/start/limbus_abnospawn/lowsec/LS in GLOB.start_landmarks_list)
			GLOB.start_landmarks_list -= LS
			abno_turf = get_turf(LS)
			qdel(LS)
			break
	else
		for(var/obj/effect/landmark/start/limbus_abnospawn/highsec/HS in GLOB.start_landmarks_list)
			GLOB.start_landmarks_list -= HS
			abno_turf = get_turf(HS)
			qdel(HS)
			break

	if(!isnull(abno_path) && !isnull(abno_turf))
		var/mob/living/simple_animal/hostile/limbus_abno/LA = new abno_path(abno_turf)
		picked_abno = LA
		H.mind.transfer_to(picked_abno)
		qdel(H)
		GLOB.lcl_spawned_abno += abno_path
		return picked_abno
	return FALSE

/datum/job/limbus_specimen/override_latejoin_spawn()
	return TRUE

//Returns the subset of abno_list the player is willing to play (priority level above NEVER).
/datum/job/limbus_specimen/proc/return_sec_list(list/abno_list, client/C)
	C.prefs.reconcile_lcl_prefs()
	var/list/out = list()
	for(var/path in abno_list)
		if(LAZYACCESS(C.prefs.lcl_abno_pref, path)) //truthy = HIGH/MEDIUM/LOW; 0/absent = NEVER
			out += path
	return out

//Assigns the highest-priority available specimen. Walks tiers HIGH -> MEDIUM -> LOW,
//lowsec before highsec within a tier. First-come-first-served between players.
/datum/job/limbus_specimen/proc/attribute_abno(client/C, occupation_divide = FALSE)
	var/found_abno = LAZYACCESS(GLOB.attributed_lcl_abno, C)
	if(LAZYFIND(GLOB.lcl_spawned_abno, found_abno)) //Their abno already spawned, not allowed to try again.
		return FALSE
	if(LAZYFIND(GLOB.attributed_lcl_abno, C))
		return TRUE //Already assigned but not spawned; skip selection.
	C.prefs.reconcile_lcl_prefs()
	var/list/canonical = GLOB.low_security + GLOB.high_security //lowsec first
	for(var/level in list(JP_HIGH, JP_MEDIUM, JP_LOW))
		for(var/path in canonical)
			if(LAZYACCESS(C.prefs.lcl_abno_pref, path) != level)
				continue
			if(path in GLOB.available_low_sec_abno)
				if(!occupation_divide)
					GLOB.available_low_sec_abno -= path
					LAZYSET(GLOB.attributed_lcl_abno, C, path)
				return TRUE
			if(path in GLOB.available_high_sec_abno)
				if(!occupation_divide)
					GLOB.available_high_sec_abno -= path
					LAZYSET(GLOB.attributed_lcl_abno, C, path)
				return TRUE
	return FALSE
