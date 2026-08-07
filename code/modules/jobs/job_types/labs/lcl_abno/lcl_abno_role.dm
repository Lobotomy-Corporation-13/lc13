//This entire job is gimmicky snowflake bullshit. If you can think of a way to improve it, please do.
//but god, do not copy paste any of this for anything of your own, this code is NOT flexible.
/datum/job/limbus_specimen
	title = "LC Specimen"
	faction = "Station"
	selection_color = "#BB9999"
	total_positions = 6
	spawn_positions = 6 //One per abno cell that exists on the map: four lowsec, two highsec.
	departments = DEPARTMENT_SECURITY
	maptype = "limbus_labs"
	job_abbreviation = "LCS"
	var/mob/living/picked_abno

//This should stop someone to spawn as an abno if none of their preferences are available at round start.
/datum/job/limbus_specimen/unique_job_check(client/C, occupation_divide)
	return attribute_abno(C, occupation_divide)

//Checks if any abnos are available for a latejoin. A dry run of the real assignment, so a
//player who cannot be given a specimen is turned away at the join menu instead of being
//dropped into the facility as a naked human.
/datum/job/limbus_specimen/special_check_latejoin(client/C)
	return attribute_abno(C, TRUE)

//This is absolute jank but it technically works. The job finds a spawner, creates an abnormality, and transfers the mind of the original person into it, then deletes the human.
/datum/job/limbus_specimen/equip(mob/living/carbon/human/H, visualsOnly, announce, latejoin, datum/outfit/outfit_override, client/preference_source = null)
	if(!H?.mind || visualsOnly || !preference_source)
		return FALSE

	if(latejoin)
		attribute_abno(preference_source)

	var/abno_path = LAZYACCESS(GLOB.attributed_lcl_abno, preference_source)
	//The cell is looked up first and only consumed once the specimen is definitely appearing
	//in it. A join that cannot finish used to destroy a landmark on its way out.
	var/obj/effect/landmark/start/limbus_abnospawn/cell = FindCell(abno_path)
	if(isnull(abno_path) || isnull(cell))
		return NothingToBecome(H, preference_source)

	var/turf/abno_turf = get_turf(cell)
	qdel(cell) //Destroy() takes it back out of GLOB.start_landmarks_list.
	var/mob/living/simple_animal/hostile/limbus_abno/LA = new abno_path(abno_turf)
	picked_abno = LA
	H.mind.transfer_to(picked_abno)
	qdel(H)
	GLOB.lcl_spawned_abno += abno_path
	return picked_abno

/datum/job/limbus_specimen/override_latejoin_spawn()
	return TRUE

///The first free cell of this specimen's own wing, or one from the other wing if its own is
///full. The wrong cell still beats no specimen at all.
/datum/job/limbus_specimen/proc/FindCell(abno_path)
	if(isnull(abno_path))
		return null
	var/wanted = (abno_path in GLOB.low_security) ? /obj/effect/landmark/start/limbus_abnospawn/lowsec : /obj/effect/landmark/start/limbus_abnospawn/highsec
	var/obj/effect/landmark/start/limbus_abnospawn/fallback
	for(var/obj/effect/landmark/start/limbus_abnospawn/LAS in GLOB.start_landmarks_list)
		if(istype(LAS, wanted))
			return LAS
		fallback = LAS
	return fallback

///Cells of one wing that are still standing and not already promised to somebody. Roundstart
///hands out every specimen before a single one spawns, so counting landmarks alone would
///promise the same cell to two players.
/datum/job/limbus_specimen/proc/UnclaimedCells(lowsec)
	var/cells = 0
	var/wanted = lowsec ? /obj/effect/landmark/start/limbus_abnospawn/lowsec : /obj/effect/landmark/start/limbus_abnospawn/highsec
	for(var/obj/effect/landmark/start/limbus_abnospawn/LAS in GLOB.start_landmarks_list)
		if(istype(LAS, wanted))
			cells++
	for(var/client/C in GLOB.attributed_lcl_abno)
		var/claimed = GLOB.attributed_lcl_abno[C]
		if(LAZYFIND(GLOB.lcl_spawned_abno, claimed)) //Already awake, its cell is long gone.
			continue
		if((claimed in GLOB.low_security) == lowsec)
			cells--
	return cells

///Nothing left to wake up as. Hand the player back to the lobby rather than leaving a naked
///human wandering the facility, and give the slot and the reservation back to the pool.
/datum/job/limbus_specimen/proc/NothingToBecome(mob/living/carbon/human/H, client/C)
	var/abno_path = LAZYACCESS(GLOB.attributed_lcl_abno, C)
	if(abno_path && !LAZYFIND(GLOB.lcl_spawned_abno, abno_path))
		if(abno_path in GLOB.low_security)
			GLOB.available_low_sec_abno |= abno_path
		else
			GLOB.available_high_sec_abno |= abno_path
	LAZYREMOVE(GLOB.attributed_lcl_abno, C)
	SSjob.FreeRole(title)
	to_chat(C, span_userdanger("There is no specimen left for you to wake up as. You are being sent back to the lobby."))
	//Deferred: the join is still running further up the stack and expects this body to exist.
	addtimer(CALLBACK(src, PROC_REF(SendToLobby), H, C), 1 SECONDS)
	return FALSE

/datum/job/limbus_specimen/proc/SendToLobby(mob/living/carbon/human/H, client/C)
	if(C)
		var/mob/dead/new_player/lobby = new()
		lobby.key = C.key
	if(!QDELETED(H))
		qdel(H)

//Assigns the highest-priority available specimen. Walks tiers HIGH -> MEDIUM -> LOW, picking at
//random within a tier. Fixed order meant everyone who left their preferences alone sat at the
//same MEDIUM tier and the first player assigned always drew whichever specimen happened to be
//first in the list, round after round.
/datum/job/limbus_specimen/proc/attribute_abno(client/C, occupation_divide = FALSE)
	var/found_abno = LAZYACCESS(GLOB.attributed_lcl_abno, C)
	if(LAZYFIND(GLOB.lcl_spawned_abno, found_abno)) //Their abno already spawned, not allowed to try again.
		return FALSE
	if(LAZYFIND(GLOB.attributed_lcl_abno, C))
		return TRUE //Already assigned but not spawned; skip selection.
	C.prefs.reconcile_lcl_prefs()
	var/list/canonical = shuffle(GLOB.low_security + GLOB.high_security)
	for(var/level in list(JP_HIGH, JP_MEDIUM, JP_LOW))
		for(var/path in canonical)
			if(LAZYACCESS(C.prefs.lcl_abno_pref, path) != level)
				continue
			var/lowsec = (path in GLOB.available_low_sec_abno)
			if(!lowsec && !(path in GLOB.available_high_sec_abno))
				continue //Somebody else has it.
			if(UnclaimedCells(lowsec) <= 0)
				continue //Its wing is full, there is nowhere to put it.
			if(!occupation_divide)
				if(lowsec)
					GLOB.available_low_sec_abno -= path
				else
					GLOB.available_high_sec_abno -= path
				LAZYSET(GLOB.attributed_lcl_abno, C, path)
			return TRUE
	return FALSE
