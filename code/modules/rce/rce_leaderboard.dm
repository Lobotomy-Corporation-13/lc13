// RCE Leaderboard System - Tracks expedition statistics across rounds
// End condition defines are in code/__DEFINES/rce.dm
// FILE_RCE_LEADERBOARD is defined in code/controllers/subsystem/persistence.dm

#define MAX_EXPEDITION_HISTORY 50

/datum/rce_leaderboard
	// Current round tracking - players
	var/list/participated_players = list()  // list of list("ckey", "name", "job")
	var/list/survived_players = list()
	var/list/died_players = list()
	var/list/lost_in_caves = list()  // Players alive but on Z=2 at round end

	// Factory tracking
	var/total_items_produced = 0
	var/list/materials_consumed = list(
		"green" = 0,
		"red" = 0,
		"blue" = 0,
		"purple" = 0,
		"orange" = 0,
		"silver" = 0
	)
	var/list/factory_stats = list()  // Keyed by factory type path string

	// Mob kills
	var/total_mob_kills = 0
	var/list/mob_kills_by_type = list()  // Keyed by mob type path string

	// Additional tracking
	var/grenades_primed = 0
	var/conveyor_belts_placed = 0
	var/surgeries_completed = 0
	var/list/player_deaths = list()  // Keyed by ckey, value is list("count", "name")

	// Round state
	var/heart_killed = FALSE
	var/end_condition = RCE_END_UNKNOWN
	var/round_start_time = 0

	// Historical data (loaded from file)
	var/list/expedition_history = list()
	var/list/all_time_stats = list()

/datum/rce_leaderboard/New()
	. = ..()
	round_start_time = world.time
	// Initialize all_time_stats with defaults if empty
	if(!length(all_time_stats))
		all_time_stats = list(
			"total_expeditions" = 0,
			"total_victories" = 0,
			"total_shuttle_escapes" = 0,
			"total_all_died" = 0,
			"total_all_died_lastwave" = 0,
			"total_player_deaths" = 0,
			"total_player_survivals" = 0,
			"total_items_produced" = 0,
			"total_materials_consumed" = list(
				"green" = 0,
				"red" = 0,
				"blue" = 0,
				"purple" = 0,
				"orange" = 0,
				"silver" = 0
			),
			"total_mob_kills" = 0,
			"highest_mob_kills_round" = 0,
			"highest_items_produced_round" = 0,
			"most_participants" = 0,
			"total_grenades_primed" = 0,
			"total_conveyor_belts_placed" = 0,
			"total_surgeries_completed" = 0,
			"total_lost_in_caves" = 0
		)

/// Record factory production - called from _factory.dm spit_item()
/datum/rce_leaderboard/proc/RecordFactoryProduction(factory_type, items, g, r, b, p, o, s)
	total_items_produced += items

	materials_consumed["green"] += g
	materials_consumed["red"] += r
	materials_consumed["blue"] += b
	materials_consumed["purple"] += p
	materials_consumed["orange"] += o
	materials_consumed["silver"] += s

	// Per-factory tracking
	var/type_key = "[factory_type]"
	if(!factory_stats[type_key])
		factory_stats[type_key] = list(
			"items_produced" = 0,
			"materials_consumed" = list(
				"green" = 0,
				"red" = 0,
				"blue" = 0,
				"purple" = 0,
				"orange" = 0,
				"silver" = 0
			)
		)
	factory_stats[type_key]["items_produced"] += items
	factory_stats[type_key]["materials_consumed"]["green"] += g
	factory_stats[type_key]["materials_consumed"]["red"] += r
	factory_stats[type_key]["materials_consumed"]["blue"] += b
	factory_stats[type_key]["materials_consumed"]["purple"] += p
	factory_stats[type_key]["materials_consumed"]["orange"] += o
	factory_stats[type_key]["materials_consumed"]["silver"] += s

/// Record mob kill - called when controlled mob dies
/datum/rce_leaderboard/proc/RecordMobKill(mob_type)
	total_mob_kills += 1
	var/type_key = "[mob_type]"
	if(!mob_kills_by_type[type_key])
		mob_kills_by_type[type_key] = 0
	mob_kills_by_type[type_key] += 1

/// Record grenade primed
/datum/rce_leaderboard/proc/RecordGrenadePrimed()
	grenades_primed += 1

/// Record conveyor belt placed
/datum/rce_leaderboard/proc/RecordConveyorPlaced()
	conveyor_belts_placed += 1

/// Record surgery completed
/datum/rce_leaderboard/proc/RecordSurgeryCompleted()
	surgeries_completed += 1

/// Record player death - tracks deaths per ckey with character name
/datum/rce_leaderboard/proc/RecordPlayerDeathCount(ckey, character_name)
	if(!ckey)
		return
	if(!player_deaths[ckey])
		player_deaths[ckey] = list("count" = 0, "name" = character_name)
	player_deaths[ckey]["count"] += 1
	// Update name in case they changed characters
	player_deaths[ckey]["name"] = character_name

/// Get the player with the most deaths this round
/datum/rce_leaderboard/proc/GetMostDeathsPlayer()
	var/highest_deaths = 0
	var/highest_name = null
	for(var/ckey in player_deaths)
		var/list/data = player_deaths[ckey]
		if(data["count"] > highest_deaths)
			highest_deaths = data["count"]
			highest_name = data["name"]
	if(highest_name)
		return list("name" = highest_name, "deaths" = highest_deaths)
	return null

/// Add a player to the participated list. Returns TRUE if added, FALSE if already exists.
/datum/rce_leaderboard/proc/AddParticipant(ckey, name, job_title)
	if(!ckey)
		return FALSE
	// Check if already added
	for(var/list/player in participated_players)
		if(player["ckey"] == ckey)
			return FALSE
	participated_players += list(list(
		"ckey" = ckey,
		"name" = name,
		"job" = job_title
	))
	return TRUE

/// Record player death
/datum/rce_leaderboard/proc/RecordPlayerDeath(ckey, name, job_title)
	if(!ckey)
		return
	// Check if already in died list
	for(var/list/player in died_players)
		if(player["ckey"] == ckey)
			return
	died_players += list(list(
		"ckey" = ckey,
		"name" = name,
		"job" = job_title
	))

/// Collect survival data at round end
/datum/rce_leaderboard/proc/CollectSurvivalData()
	survived_players = list()
	died_players = list()
	lost_in_caves = list()

	// First, ensure we have all participants from GLOB.joined_player_list
	// This catches anyone who was missed by the signal (e.g., round-start spawns)
	CollectParticipantsFromGlobal()

	for(var/list/player in participated_players)
		var/ckey = player["ckey"]
		var/mob/living/carbon/human/H = get_mob_by_ckey(ckey)

		if(H && H.stat != DEAD)
			// Check Z-level for "lost in caves"
			var/turf/T = get_turf(H)
			if(T && T.z == 2)
				// Lost in caves - counts as died but tracked separately
				lost_in_caves += list(player.Copy())
				died_players += list(player.Copy())
			else
				survived_players += list(player.Copy())
		else
			died_players += list(player.Copy())

/// Collect any missing participants from GLOB.joined_player_list
/datum/rce_leaderboard/proc/CollectParticipantsFromGlobal()
	for(var/player_ckey in GLOB.joined_player_list)
		// Check if already tracked
		var/already_tracked = FALSE
		for(var/list/player in participated_players)
			if(player["ckey"] == player_ckey)
				already_tracked = TRUE
				break
		if(already_tracked)
			continue

		// Find the mob for this ckey
		var/mob/living/carbon/human/H = get_mob_by_ckey(player_ckey)
		var/player_name = "Unknown"
		var/job_title = "Unknown"

		if(H)
			player_name = H.real_name
			if(H.mind?.assigned_role)
				var/datum/job/J = H.mind.assigned_role
				job_title = J.title
		else
			// Try to find in dead mobs or ghosts
			for(var/mob/M in GLOB.mob_list)
				if(M.ckey == player_ckey || M.mind?.key == player_ckey)
					player_name = M.real_name || M.name
					if(ishuman(M))
						var/mob/living/carbon/human/HM = M
						if(HM.mind?.assigned_role)
							var/datum/job/J = HM.mind.assigned_role
							job_title = J.title
					break

		participated_players += list(list(
			"ckey" = player_ckey,
			"name" = player_name,
			"job" = job_title
		))

/// Determine round end condition based on game state
/datum/rce_leaderboard/proc/DetermineEndCondition()
	if(heart_killed)
		return RCE_END_HEART_KILLED

	// Check if anyone survived
	var/anyone_alive = FALSE
	for(var/list/player in participated_players)
		var/ckey = player["ckey"]
		var/mob/living/carbon/human/H = get_mob_by_ckey(ckey)
		if(H && H.stat != DEAD)
			anyone_alive = TRUE
			break

	if(!anyone_alive)
		if(SSgamedirector.last_wave_started)
			return RCE_END_ALL_DIED_LASTWAVE
		else
			return RCE_END_ALL_DIED

	// Default to shuttle escape if people are alive
	return RCE_END_SHUTTLE_ESCAPE

/// Build the expedition record for saving
/datum/rce_leaderboard/proc/BuildExpeditionRecord()
	var/list/record = list()

	record["expedition_number"] = SSpersistence.rce_expedition_number
	record["timestamp"] = time2text(world.realtime, "YYYY-MM-DD hh:mm:ss")
	record["duration_seconds"] = round((world.time - round_start_time) / 10)
	record["end_condition"] = end_condition

	record["players"] = list(
		"participated" = participated_players.Copy(),
		"survived" = survived_players.Copy(),
		"died" = died_players.Copy(),
		"lost_in_caves" = lost_in_caves.Copy()
	)

	record["factory_stats"] = list(
		"total_items" = total_items_produced,
		"materials" = materials_consumed.Copy(),
		"by_factory" = factory_stats.Copy()
	)

	record["mob_kills"] = list(
		"total" = total_mob_kills,
		"by_type" = mob_kills_by_type.Copy()
	)

	record["heart_killed"] = heart_killed

	// Additional stats
	record["grenades_primed"] = grenades_primed
	record["conveyor_belts_placed"] = conveyor_belts_placed
	record["surgeries_completed"] = surgeries_completed

	// Most deaths player
	var/list/most_deaths = GetMostDeathsPlayer()
	if(most_deaths)
		record["most_deaths_player"] = most_deaths
	else
		record["most_deaths_player"] = null

	return record

/// Update all-time stats with the current expedition
/datum/rce_leaderboard/proc/UpdateAllTimeStats(list/expedition)
	all_time_stats["total_expeditions"] += 1

	switch(expedition["end_condition"])
		if(RCE_END_HEART_KILLED)
			all_time_stats["total_victories"] += 1
		if(RCE_END_SHUTTLE_ESCAPE)
			all_time_stats["total_shuttle_escapes"] += 1
		if(RCE_END_ALL_DIED)
			all_time_stats["total_all_died"] += 1
		if(RCE_END_ALL_DIED_LASTWAVE)
			all_time_stats["total_all_died_lastwave"] += 1

	var/list/players = expedition["players"]
	all_time_stats["total_player_deaths"] += length(players["died"])
	all_time_stats["total_player_survivals"] += length(players["survived"])

	var/list/factory = expedition["factory_stats"]
	all_time_stats["total_items_produced"] += factory["total_items"]

	var/list/mats = factory["materials"]
	var/list/all_mats = all_time_stats["total_materials_consumed"]
	all_mats["green"] += mats["green"]
	all_mats["red"] += mats["red"]
	all_mats["blue"] += mats["blue"]
	all_mats["purple"] += mats["purple"]
	all_mats["orange"] += mats["orange"]
	all_mats["silver"] += mats["silver"]

	var/list/mobs = expedition["mob_kills"]
	all_time_stats["total_mob_kills"] += mobs["total"]

	// Update records
	if(mobs["total"] > all_time_stats["highest_mob_kills_round"])
		all_time_stats["highest_mob_kills_round"] = mobs["total"]

	if(factory["total_items"] > all_time_stats["highest_items_produced_round"])
		all_time_stats["highest_items_produced_round"] = factory["total_items"]

	if(length(players["participated"]) > all_time_stats["most_participants"])
		all_time_stats["most_participants"] = length(players["participated"])

	// Update additional stats
	all_time_stats["total_grenades_primed"] += expedition["grenades_primed"]
	all_time_stats["total_conveyor_belts_placed"] += expedition["conveyor_belts_placed"]
	all_time_stats["total_surgeries_completed"] += expedition["surgeries_completed"]
	all_time_stats["total_lost_in_caves"] += length(players["lost_in_caves"])

/// Load leaderboard data from file
/datum/rce_leaderboard/proc/LoadFromFile()
	var/json_file = file(FILE_RCE_LEADERBOARD)
	if(!fexists(json_file))
		return

	var/list/data = json_decode(file2text(json_file))
	if(!data)
		return

	if(data["expeditions"])
		expedition_history = data["expeditions"]

	if(data["all_time"])
		all_time_stats = data["all_time"]

/// Save leaderboard data to file
/datum/rce_leaderboard/proc/SaveToFile()
	// Collect final survival data
	CollectSurvivalData()

	// Determine end condition
	end_condition = DetermineEndCondition()

	// Build expedition record
	var/list/expedition = BuildExpeditionRecord()

	// Add to history (newest first)
	expedition_history.Insert(1, list(expedition))

	// Prune old records
	while(length(expedition_history) > MAX_EXPEDITION_HISTORY)
		expedition_history.Cut(length(expedition_history))

	// Update all-time stats
	UpdateAllTimeStats(expedition)

	// Save to file
	var/list/save_data = list(
		"expeditions" = expedition_history,
		"all_time" = all_time_stats
	)
	fdel(FILE_RCE_LEADERBOARD)
	text2file(json_encode(save_data), FILE_RCE_LEADERBOARD)

/// Get a human-readable factory name from path
/datum/rce_leaderboard/proc/GetFactoryName(factory_path)
	var/path = text2path(factory_path)
	if(!path)
		return factory_path
	var/obj/structure/rcorp_factory/F = path
	return initial(F.name)

/// Get a human-readable mob name from path
/datum/rce_leaderboard/proc/GetMobName(mob_path)
	var/path = text2path(mob_path)
	if(!path)
		return mob_path
	var/mob/living/simple_animal/hostile/M = path
	return initial(M.name)
