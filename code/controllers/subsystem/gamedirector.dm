SUBSYSTEM_DEF(gamedirector)
	name = "Game Director"
	flags = SS_BACKGROUND | SS_KEEP_TIMING
	wait = 10 SECONDS
	init_order = INIT_ORDER_GAMEDIRECTOR
	runlevels = RUNLEVEL_GAME

	var/list/obj/effect/landmark/rce_fob = list()
	var/list/obj/effect/landmark/rce_target/rce_targets = list()
	var/list/obj/effect/landmark/rce_target/fob_entrance = list()
	var/list/obj/effect/landmark/rce_target/low_level = list()
	var/list/obj/effect/landmark/rce_target/mid_level = list()
	var/list/obj/effect/landmark/rce_target/high_level = list()
	var/list/obj/effect/landmark/rce_target/xcorp_base = list()
	var/list/obj/effect/landmark/rce_arena_teleport = list()
	var/list/obj/effect/landmark/rce_postfight_teleport = list()
	var/list/obj/effect/landmark/heartfight_pylon = list()
	var/list/obj/effect/landmark/lastwave_gateway = list()
	var/list/obj/effect/landmark/fob_escape_shuttle = list()
	var/list/obj/effect/greed_gateway/active_gateways = list()
	var/list/mob/living/simple_animal/hostile/controlled_mobs = list()
	var/list/targets_by_id = list()
	var/datum/component/monwave_spawner/wave_announcer
	var/list/datum/component/monwave_spawner/spawners = list()
	var/first_announce = TRUE
	var/mob/living/simple_animal/hostile/megafauna/xcorp_heart/heart
	var/list/mob/living/combatants = list()
	var/obj/structure/rce_portal/portal
	var/fightstage = PHASE_NOT_STARTED
	var/gamestage = PHASE_PRE_INIT
	var/rematch = FALSE
	var/timestamp_warning = 50000 // Stop announcing shit on other modes dumbass
	var/timestamp_finalwave = 50000
	var/timestamp_end = 50000

	// Resource Well Raids variables
	var/list/resourcewells = list()
	var/list/active_resourcewells = list()
	var/list/raid_spots = list()
	var/next_raid_time = 0
	var/raid_cooldown_min = 8 MINUTES
	var/raid_cooldown_max = 10 MINUTES

	// Seed spawning variables
	var/next_active_seed_time = 0
	var/active_seed_cooldown_min = 20 MINUTES
	var/active_seed_cooldown_max = 24 MINUTES
	var/next_passive_seed_time = 0
	var/passive_seed_cooldown = 20 MINUTES
	var/list/wells_with_passive_seeds = list()

	// Corrupter spawning variables
	var/next_corrupter_time = 0
	var/corrupter_cooldown_min = 20 MINUTES
	var/corrupter_cooldown_max = 30 MINUTES
	var/corrupter_rarity_threshold = 6

	// FoB entrance raid variables
	var/fob_entrances_unlocked = FALSE
	var/fob_unlock_time = 30 MINUTES
	var/last_wave_started = FALSE
	var/next_fob_raid_time = 0
	var/fob_raid_cooldown = 4 MINUTES

	var/list/raid_tiers = list()
	var/list/seed_types = list()

/datum/controller/subsystem/gamedirector/Initialize()
	. = ..()
	if(SSmaptype.maptype != "rcorp_factory")
		wait = 5 HOURS // Changing the flags to make the subsystem not run requires a MC restart, so we do this :3
		gamestage = PHASE_NOT_RCE
	else
		gamestage = PHASE_NORMAL_GAME
		// Initialize resource well raids
		SetupRaidTiers()
		SetupSeedTypes()
		next_raid_time = world.time + rand(raid_cooldown_min, raid_cooldown_max)
		next_active_seed_time = world.time + 35 MINUTES
		next_passive_seed_time = world.time + passive_seed_cooldown
		next_corrupter_time = world.time + rand(corrupter_cooldown_min, corrupter_cooldown_max)

/datum/controller/subsystem/gamedirector/fire(resumed = FALSE)
	if(fightstage != PHASE_FIGHT && SSticker.current_state != GAME_STATE_FINISHED && gamestage < PHASE_NOT_RCE)
		if(world.time > timestamp_end && gamestage < PHASE_ENDROUND)
			gamestage = PHASE_ENDROUND
			// Let the shuttle handle the evacuation
		else if(world.time > timestamp_finalwave && gamestage < PHASE_LASTWAVE_PASSED)
			to_chat(world, span_userdanger("A huge wave of greed is approaching!"))
			gamestage = PHASE_LASTWAVE_PASSED
			StartLastWave()
			CallEvacuation()
		else if(world.time > timestamp_warning && gamestage < PHASE_WARNING_PASSED)
			to_chat(world, span_userdanger("There are 20 minutes left to kill the heart!"))
			gamestage = PHASE_WARNING_PASSED

	// Resource Well Raids processing
	if(SSmaptype.maptype == "rcorp_factory")
		// Check for FoB entrance unlock at 30 minutes
		if(!fob_entrances_unlocked && world.time >= fob_unlock_time)
			fob_entrances_unlocked = TRUE

		// Handle raids based on whether last wave has started
		if(last_wave_started)
			// After last wave, spawn powerful raids at FoB entrances every 4 minutes
			if(world.time >= next_fob_raid_time)
				TriggerFoBRaid()
				next_fob_raid_time = world.time + fob_raid_cooldown
		else
			// Normal raid spawning (before last wave)
			if(world.time >= next_raid_time)
				TriggerRaid()
				next_raid_time = world.time + rand(raid_cooldown_min, raid_cooldown_max)

		if(world.time >= next_active_seed_time)
			SpawnActiveSeed()
			next_active_seed_time = world.time + rand(active_seed_cooldown_min, active_seed_cooldown_max)

		if(world.time >= next_passive_seed_time)
			SpawnPassiveSeed()
			next_passive_seed_time = world.time + passive_seed_cooldown

		// Check for corrupter spawning
		if(world.time >= next_corrupter_time)
			var/total_rarity = 0
			for(var/obj/structure/resourcepoint/well in active_resourcewells)
				total_rarity += well.rarity

			if(total_rarity >= corrupter_rarity_threshold)
				SpawnCorrupter()

			next_corrupter_time = world.time + rand(corrupter_cooldown_min, corrupter_cooldown_max)
	return

/datum/controller/subsystem/gamedirector/proc/SetTimes(warningtime, endtime)
	timestamp_warning = world.time + warningtime
	timestamp_finalwave = world.time + warningtime + 10 MINUTES
	timestamp_end = world.time + endtime

/datum/controller/subsystem/gamedirector/proc/GetRandomTarget()
	return pick(rce_targets)

/datum/controller/subsystem/gamedirector/proc/GetRandomRaiderTarget()
	switch(rand(1, 10))
		if(1 to 5)
			return pick(mid_level)
		if(6 to 9)
			return pick(high_level)
		if(10)
			return pick(low_level)

/datum/controller/subsystem/gamedirector/proc/RegisterAsWaveAnnouncer(datum/component/monwave_spawner/applicant)
	if(!wave_announcer)
		wave_announcer = applicant
		return TRUE
	return FALSE

/datum/controller/subsystem/gamedirector/proc/StartLastWave()
	last_wave_started = TRUE
	next_fob_raid_time = world.time + fob_raid_cooldown

	var/gateway_count = 0
	// Process each gateway spawn landmark
	for(var/obj/effect/landmark/lastwave_gateway/gateway_spawn in lastwave_gateway)
		var/turf/T = get_turf(gateway_spawn)
		if(!T)
			continue

		switch(gateway_spawn.gateway_type)
			if(GATEWAY_TYPE_AIR)
				T.ChangeTurf(/turf/open/indestructible/necropolis/air)
			if(GATEWAY_TYPE_WALL)
				T.ChangeTurf(/turf/closed/indestructible/necropolis)
			if(GATEWAY_TYPE_GATEWAY)
				var/obj/effect/greed_gateway/gateway = new(T)
				// Pass the pre-calculated path to the gateway
				if(length(gateway_spawn.assault_path))
					gateway.assault_path = gateway_spawn.assault_path.Copy()
				active_gateways += gateway
				gateway_count++

	if(gateway_count > 0)
		show_global_blurb(10 SECONDS, "CRITICAL: [gateway_count] Greed Gateway\s [gateway_count > 1 ? "have" : "has"] opened! Infinite X-Corp reinforcements incoming!", text_align = "center", screen_location = "LEFT+0,TOP-2", text_color = "#FF0000")

	// Direct existing controlled mobs to escape shuttle
	if(length(fob_escape_shuttle))
		var/obj/effect/landmark/fob_escape_shuttle/target_shuttle = pick(fob_escape_shuttle)
		for(var/mob/living/simple_animal/hostile/M in controlled_mobs)
			walk_to(M, target_shuttle, 5, 50, M.move_to_delay)

/datum/controller/subsystem/gamedirector/proc/RegisterTarget(obj/effect/landmark/rce_target/target, type, id = NONE)
	rce_targets.Add(target)
	switch(type)
		if(RCE_TARGET_TYPE_FOB_ENTRANCE)
			fob_entrance.Add(target)
		if(RCE_TARGET_TYPE_LOW_LEVEL)
			low_level.Add(target)
		if(RCE_TARGET_TYPE_MID_LEVEL)
			mid_level.Add(target)
		if(RCE_TARGET_TYPE_HIGH_LEVEL)
			high_level.Add(target)
		if(RCE_TARGET_TYPE_XCORP_BASE)
			xcorp_base.Add(target)

	if(id)
		targets_by_id[id] = target

/datum/controller/subsystem/gamedirector/proc/GetTargetById(id)
	return targets_by_id[id]


/datum/controller/subsystem/gamedirector/proc/AnnounceWave()
	if(first_announce)
		first_announce = FALSE
		return
	var/text = "A strong X-Corp attack wave is inbound."
	show_global_blurb(5 SECONDS, text, 1 SECONDS, 2 SECONDS, "red", "black")

	sleep(30)
	wave_announcer.SwitchTarget(pick(rce_targets))

/datum/controller/subsystem/gamedirector/proc/RegisterSpawner(datum/component/monwave_spawner/spawner)
	spawners += spawner

/datum/controller/subsystem/gamedirector/proc/RegisterHeart(mob/heart)
	heart = heart

/datum/controller/subsystem/gamedirector/proc/RegisterMob(mob/living/simple_animal/hostile/M)
	controlled_mobs.Add(M)

/datum/controller/subsystem/gamedirector/proc/AnnounceVictory()
	var/text = "The X-Corp Heart has been destroyed! Victory achieved."
	show_global_blurb(60 SECONDS, text, 1 SECONDS, 2 SECONDS, "gold", "white")
	SSticker.force_ending = 1

/datum/controller/subsystem/gamedirector/proc/RegisterPortal(obj/structure/rce_portal/portal)
	portal = portal

/datum/controller/subsystem/gamedirector/proc/RegisterLobby(obj/effect/landmark/lobby)
	rce_arena_teleport += lobby

/datum/controller/subsystem/gamedirector/proc/RegisterFOB(obj/effect/landmark/fob)
	rce_fob += fob

/datum/controller/subsystem/gamedirector/proc/RegisterVictoryTeleport(obj/effect/landmark/postfight)
	rce_postfight_teleport += postfight

/datum/controller/subsystem/gamedirector/proc/RegisterHeartfightPylon(obj/effect/landmark/pylon)
	heartfight_pylon += pylon

/datum/controller/subsystem/gamedirector/proc/RegisterGatewaySpawn(obj/effect/landmark/lastwave_gateway/gateway)
	lastwave_gateway += gateway

/datum/controller/subsystem/gamedirector/proc/RegisterEscapeShuttle(obj/effect/landmark/fob_escape_shuttle/shuttle)
	fob_escape_shuttle += shuttle

/datum/controller/subsystem/gamedirector/proc/BeginPrefightPhase()
	fightstage = PHASE_PREFIGHT
	show_global_blurb(10 SECONDS, "The Heart of Greed has been challenged! Register quickly!", text_color = "#cc2200", outline_color = "#000000", text_align = "center", screen_location="LEFT+0,TOP-1")

/datum/controller/subsystem/gamedirector/proc/BeginRematchPhase()
	print_command_report("The Heart is tired from the fight and is going to sleep, no rematch today. Thank you for playing the RCE demo.", "Heart of Greed Tired", TRUE)
	SSticker.force_ending = 1

/datum/controller/subsystem/gamedirector/proc/RegisterCombatant(mob/living/combatant)
	if(fightstage == PHASE_NOT_STARTED || fightstage == PHASE_PREFIGHT || fightstage == PHASE_OVER_LOST)
		if(length(combatants) == 0)
			if(fightstage == PHASE_OVER_LOST)
				BeginRematchPhase()
			else
				BeginPrefightPhase()
		combatants += combatant
		RegisterSignal(combatant, COMSIG_LIVING_DEATH, PROC_REF(CombatantSlain))
		combatant.forceMove(get_turf(pick(rce_arena_teleport)))
		to_chat(combatant, span_alert("You find yourself in front of the arena! Prepare!"))
	else if(fightstage == PHASE_FIGHT)
		to_chat(combatant, span_danger("The intense aura of the fight prevents you from joining!"))
	else if(fightstage == PHASE_OVER_WON)
		combatant.forceMove(get_turf(pick(rce_postfight_teleport)))
		to_chat(combatant, span_alert("You find yourself at the end of the trial..."))

/datum/controller/subsystem/gamedirector/proc/CombatantSlain(mob/living/combatant)
	SIGNAL_HANDLER

// Resource Well Raid procedures
/datum/controller/subsystem/gamedirector/proc/RegisterResourceWell(obj/structure/resourcepoint/well)
	resourcewells += well

/datum/controller/subsystem/gamedirector/proc/UnregisterResourceWell(obj/structure/resourcepoint/well)
	resourcewells -= well
	active_resourcewells -= well

/datum/controller/subsystem/gamedirector/proc/RegisterRaidSpot(obj/effect/landmark/clan_raid_spot/spot)
	if(!raid_spots[spot.id])
		raid_spots[spot.id] = list()
	raid_spots[spot.id] += spot

/datum/controller/subsystem/gamedirector/proc/UpdateActiveStatus(obj/structure/resourcepoint/well)
	if(well.active > 0)
		active_resourcewells |= well
		wells_with_passive_seeds -= well
	else
		active_resourcewells -= well

/datum/controller/subsystem/gamedirector/proc/TriggerRaid()
	if(!length(active_resourcewells))
		return

	// 15% chance to spawn at FoB entrance instead (if unlocked and available)
	if(fob_entrances_unlocked && prob(15) && length(raid_spots["fob_entrance"]))
		var/list/spawn_spots = raid_spots["fob_entrance"]
		if(spawn_spots && length(spawn_spots))
			var/total_rarity = 0
			for(var/obj/structure/resourcepoint/well in active_resourcewells)
				total_rarity += well.rarity

			var/list/raid_data = GetRaidData(total_rarity)
			if(raid_data)
				var/raid_name = raid_data["name"]
				var/list/raid_composition = raid_data["composition"]
				show_global_blurb(10 SECONDS, "Warning: Greed-touched '[raid_name]' breaching FoB entrance!", text_align = "center", screen_location = "LEFT+0,TOP-2", text_color = "#FF0000")
				addtimer(CALLBACK(src, PROC_REF(SpawnRaid), spawn_spots, raid_composition, null, raid_name), 12 SECONDS)
				return

	var/obj/structure/resourcepoint/target_well

	// 15% chance to ignore priority system
	if(prob(15))
		target_well = pick(active_resourcewells)
	else
		target_well = GetPriorityRaidTarget()

	if(!target_well)
		target_well = pick(active_resourcewells)

	var/total_rarity = 0
	for(var/obj/structure/resourcepoint/well in active_resourcewells)
		total_rarity += well.rarity

	var/list/spawn_spots = raid_spots[target_well.id]
	if(!spawn_spots || !length(spawn_spots))
		return

	var/list/raid_data = GetRaidData(total_rarity)
	if(!raid_data)
		return

	var/raid_name = raid_data["name"]
	var/list/raid_composition = raid_data["composition"]

	show_global_blurb(10 SECONDS, "Warning: Greed-touched '[raid_name]' detected approaching [target_well.name]!", text_align = "center", screen_location = "LEFT+0,TOP-2", text_color = "#FF0000")

	addtimer(CALLBACK(src, PROC_REF(SpawnRaid), spawn_spots, raid_composition, target_well, raid_name), 12 SECONDS)

/datum/controller/subsystem/gamedirector/proc/SpawnRaid(list/spawn_spots, list/raid_composition, obj/structure/resourcepoint/target_well, raid_name)
	var/spot_index = 1
	var/list/available_spots = spawn_spots.Copy()

	for(var/mob_type in raid_composition)
		var/spawn_count = raid_composition[mob_type]
		for(var/i in 1 to spawn_count)
			var/turf/spawn_turf
			if(length(available_spots))
				var/obj/effect/landmark/spot = pick(available_spots)
				spawn_turf = get_turf(spot)
			else
				var/obj/effect/landmark/spot = spawn_spots[spot_index]
				spawn_turf = get_turf(spot)
				spot_index++
				if(spot_index > length(spawn_spots))
					spot_index = 1

			var/obj/structure/closet/supplypod/extractionpod/pod = new()
			pod.explosionSize = list(0,0,0,0)
			pod.icon_state = "pod"
			pod.door = "pod_door"
			pod.decal = "cultist"
			pod.resistance_flags = INDESTRUCTIBLE
			new mob_type(pod)
			new /obj/effect/pod_landingzone(spawn_turf, pod)
			stoplag(2)

	if(target_well)
		show_global_blurb(5 SECONDS, "The '[raid_name]' has arrived at [target_well.name]!", text_align = "center", screen_location = "LEFT+0,TOP-2", text_color = "#FF0000")
	else
		show_global_blurb(5 SECONDS, "The '[raid_name]' has breached the FoB entrance!", text_align = "center", screen_location = "LEFT+0,TOP-2", text_color = "#FF0000")

/datum/controller/subsystem/gamedirector/proc/TriggerFoBRaid()
	// Check if fob_entrance spots exist in raid_spots
	if(!raid_spots["fob_entrance"] || !length(raid_spots["fob_entrance"]))
		return

	var/list/spawn_spots = raid_spots["fob_entrance"]

	// Use powerful raid composition for FoB raids after last wave
	var/list/raid_data = GetPowerfulRaidData()
	if(!raid_data)
		return

	var/raid_name = raid_data["name"]
	var/list/raid_composition = raid_data["composition"]

	show_global_blurb(10 SECONDS, "CRITICAL: Elite Greed forces '[raid_name]' assaulting FoB entrance!", text_align = "center", screen_location = "LEFT+0,TOP-2", text_color = "#FF0000")

	addtimer(CALLBACK(src, PROC_REF(SpawnRaid), spawn_spots, raid_composition, null, raid_name), 12 SECONDS)

/datum/controller/subsystem/gamedirector/proc/GetRaidData(rarity)
	var/list/valid_raids = list()
	for(var/list/raid in raid_tiers)
		if(rarity >= raid["min_rarity"] && rarity <= raid["max_rarity"])
			valid_raids += list(raid)

	if(!length(valid_raids))
		return null

	var/list/chosen_raid = pick(valid_raids)
	return chosen_raid

/datum/controller/subsystem/gamedirector/proc/GetPowerfulRaidData()
	// Elite raid compositions for FoB entrance raids after last wave
	var/list/powerful_raids = list(
		list(
			"name" = "Elite Siege Force",
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/demolisher/greed = 2,
				/mob/living/simple_animal/hostile/clan/defender/greed = 4,
				/mob/living/simple_animal/hostile/clan/ranged/sniper/greed = 4,
				/mob/living/simple_animal/hostile/clan/drone/greed = 4
			)
		),
		list(
			"name" = "Elite Warper Battalion",
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/ranged/warper/greed = 3,
				/mob/living/simple_animal/hostile/clan/ranged/harpooner/greed = 5,
				/mob/living/simple_animal/hostile/clan/assassin/greed = 4,
				/mob/living/simple_animal/hostile/clan/ranged/rapid/greed = 10
			)
		),
		list(
			"name" = "Elite Extermination Squad",
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/demolisher/greed = 1,
				/mob/living/simple_animal/hostile/clan/ranged/warper/greed = 4,
				/mob/living/simple_animal/hostile/clan/ranged/gunner/greed = 6,
				/mob/living/simple_animal/hostile/clan/bomber_spider/greed = 8,
				/mob/living/simple_animal/hostile/clan/ranged/sniper/greed = 4
			)
		),
		list(
			"name" = "Elite Apocalypse Force",
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/demolisher/greed = 1,
				/mob/living/simple_animal/hostile/clan/defender/greed = 3,
				/mob/living/simple_animal/hostile/clan/ranged/warper/greed = 2,
				/mob/living/simple_animal/hostile/clan/ranged/harpooner/greed = 6,
				/mob/living/simple_animal/hostile/clan/scout/greed = 12
			)
		)
	)

	return pick(powerful_raids)

/datum/controller/subsystem/gamedirector/proc/GetPriorityRaidTarget()
	// Define the two priority lanes
	// Lane 1: green -> blue -> orange (priority: orange > blue > green)
	// Lane 2: red -> purple -> silver (priority: silver > purple > red)

	var/list/lane1_priority = list("orange", "blue", "green")
	var/list/lane2_priority = list("silver", "purple", "red")

	// Check what's active in each lane
	var/list/active_lane1 = list()
	var/list/active_lane2 = list()

	for(var/obj/structure/resourcepoint/well in active_resourcewells)
		if(well.id in lane1_priority)
			active_lane1[well.id] = well
		else if(well.id in lane2_priority)
			active_lane2[well.id] = well

	// Find the highest priority target in lane 1
	var/obj/structure/resourcepoint/lane1_target
	for(var/priority_id in lane1_priority)
		if(active_lane1[priority_id])
			lane1_target = active_lane1[priority_id]
			break

	// Find the highest priority target in lane 2
	var/obj/structure/resourcepoint/lane2_target
	for(var/priority_id in lane2_priority)
		if(active_lane2[priority_id])
			lane2_target = active_lane2[priority_id]
			break

	// Choose between the two lanes based on which has higher priority
	if(lane1_target && lane2_target)
		// Compare priorities - lower index = higher priority
		var/lane1_priority_index = lane1_priority.Find(lane1_target.id)
		var/lane2_priority_index = lane2_priority.Find(lane2_target.id)

		// Lower index means higher priority
		if(lane1_priority_index < lane2_priority_index)
			return lane1_target
		else if(lane2_priority_index < lane1_priority_index)
			return lane2_target
		else
			// Equal priority, pick randomly
			return pick(lane1_target, lane2_target)
	else if(lane1_target)
		return lane1_target
	else if(lane2_target)
		return lane2_target
	else
		return null

/datum/controller/subsystem/gamedirector/proc/SpawnActiveSeed()
	if(!length(active_resourcewells))
		return

	var/obj/structure/resourcepoint/target_well = pick(active_resourcewells)

	var/total_rarity = 0
	for(var/obj/structure/resourcepoint/well in active_resourcewells)
		total_rarity += well.rarity

	var/seed_type = GetSeedType(total_rarity)
	if(!seed_type)
		return

	show_global_blurb(10 SECONDS, "Warning: Seed of Greed detected materializing at [target_well.name]!", text_align = "center", screen_location = "LEFT+0,TOP-2", text_color = "#FF0000")

	addtimer(CALLBACK(src, PROC_REF(PlaceSeed), target_well, seed_type), 12 SECONDS)

/datum/controller/subsystem/gamedirector/proc/SpawnPassiveSeed()
	var/list/inactive_wells = resourcewells - active_resourcewells - wells_with_passive_seeds

	if(!length(inactive_wells))
		return

	var/obj/structure/resourcepoint/target_well = pick(inactive_wells)
	wells_with_passive_seeds += target_well

	// Always spawn level 1 seeds on inactive wells
	var/list/level1_seeds = list(
		/obj/structure/seed_of_greed/basic/level1,
		/obj/structure/seed_of_greed/shield/level1,
		/obj/structure/seed_of_greed/defensive/level1
	)

	var/seed_type = pick(level1_seeds)

	// No warning for passive seeds - they spawn silently
	new seed_type(get_turf(target_well))

/datum/controller/subsystem/gamedirector/proc/PlaceSeed(obj/structure/resourcepoint/target_well, seed_type)
	new seed_type(get_turf(target_well))
	show_global_blurb(5 SECONDS, "Seed of Greed has materialized at [target_well.name]!", text_align = "center", screen_location = "LEFT+0,TOP-2", text_color = "#FF0000")

/datum/controller/subsystem/gamedirector/proc/GetSeedType(rarity)
	for(var/list/tier in seed_types)
		if(rarity >= tier["min_rarity"] && rarity <= tier["max_rarity"])
			var/list/types = tier["types"]
			return pick(types)
	return null

/datum/controller/subsystem/gamedirector/proc/SpawnCorrupter()
	// Get all raid spots from all IDs
	var/list/all_raid_spots = list()
	for(var/id in raid_spots)
		all_raid_spots += raid_spots[id]

	if(!length(all_raid_spots))
		return

	var/obj/effect/landmark/clan_raid_spot/chosen_spot = pick(all_raid_spots)
	var/turf/spawn_turf = get_turf(chosen_spot)

	if(!spawn_turf)
		return

	// Find the nearest resource well to give location context
	var/obj/structure/resourcepoint/nearest_well = null
	var/min_dist = 15
	for(var/obj/structure/resourcepoint/well in resourcewells)
		var/dist = get_dist(spawn_turf, well)
		if(dist < min_dist)
			min_dist = dist
			nearest_well = well

	var/location_text = nearest_well ? "near [nearest_well.name]" : "at unknown location"

	// Warning message with location
	show_global_blurb(10 SECONDS, "CRITICAL WARNING: Greed-touched Corrupter detected materializing near [location_text]!", text_align = "center", screen_location = "LEFT+0,TOP-2", text_color = "#FF0000")

	// Spawn the corrupter after delay
	addtimer(CALLBACK(src, PROC_REF(ActuallySpawnCorrupter), spawn_turf, location_text), 12 SECONDS)

/datum/controller/subsystem/gamedirector/proc/ActuallySpawnCorrupter(turf/spawn_turf, location_text)
	new /mob/living/simple_animal/hostile/clan/ranged/corrupter/greed(spawn_turf)
	show_global_blurb(5 SECONDS, "Greed-touched Corrupter has arrived near [location_text]! Extreme caution advised!", text_align = "center", screen_location = "LEFT+0,TOP-2", text_color = "#FF0000")

/datum/controller/subsystem/gamedirector/proc/CallEvacuation()
	// Ensure security level is not RED or DELTA for 20 minute evacuation
	var/security_num = seclevel2num(get_security_level())
	if(security_num >= SEC_LEVEL_RED)
		set_security_level(SEC_LEVEL_BLUE)

	// Call the evacuation shuttle
	SSshuttle.requestEvac(null, "Critical threat detected: R-Corp evacuation protocols activated. Final defensive wave initiated.")
