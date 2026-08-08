//Wave-based monster spawning system for W-Corp Cleanup gamemode
//Used for train car progression - clear waves to unlock barrier to next car

GLOBAL_LIST_EMPTY(wave_controllers)
GLOBAL_LIST_EMPTY(wave_mob_sources) //Assoc list: mob -> spawner source
GLOBAL_VAR_INIT(wave_cars_activated, 0) //How many cars players have triggered so far - decides car numbering
GLOBAL_VAR_INIT(wave_total_cars, 0) //How many normal cars exist this round, counted from the map's room spawners
GLOBAL_VAR_INIT(wave_cars_loaded, 0) //How many normal cars actually registered a controller - verification only
GLOBAL_VAR_INIT(wave_enemy_faction, "") //Which faction enemies come from this round

/// Spawn delay before mob appears (in deciseconds)
#define WAVE_SPAWN_DELAY 6
/// Cooldown between spawner activations (in deciseconds)
#define WAVE_SPAWNER_COOLDOWN 3 SECONDS
/// Target mobs per player for wave reserves (20 players = 35 mobs means 1.75 per player)
#define WAVE_MOBS_PER_PLAYER 1.75
/// Minimum mobs for a wave (even with few players)
#define WAVE_MIN_MOBS 8
/// controller_id of the boss car, hardcoded into the main map rather than a random room
#define WAVE_BOSS_CONTROLLER_ID "final_boss"
/// Difficulty tier cutoffs, as a fraction of the way through the train (see GetDifficultyTier)
#define WAVE_TIER2_CUTOFF 0.34
#define WAVE_TIER3_CUTOFF 0.78
#define WAVE_TIER4_CUTOFF 0.89

/*
 * Blurb screen positions.
 *
 * Every blurb is a separate overlay - show_blurb() never clears an existing one - so two
 * blurbs sharing a screen_loc render on top of each other. Blurbs are 64px (2 tiles) tall,
 * so these lanes have to stay at least 2 apart or they will clip.
 *
 * One lane per scope, because these can be on screen at the same time: clearing a car and
 * walking straight into the next one puts the "CAR N CLEARED" line, the "CAR N+1" banner
 * and that car's first "WAVE 1/X" line up together.
 */
/// Car finished - "CAR N CLEARED", "BOSS DEFEATED"
#define WAVE_BLURB_CAR_STATUS "CENTER,BOTTOM+6"
/// Car entered - "CAR N", "FINAL CAR - BOSS"
#define WAVE_BLURB_CAR_ENTRY "CENTER,BOTTOM+4"
/// Wave lines - "WAVE N/X - Y HOSTILES", "WAVE N CLEARED", "FINAL WAVE"
#define WAVE_BLURB_WAVE "CENTER,BOTTOM+2"

/*
 * Wave Controller Datum
 * Manages waves for a single train car/room
 * Links triggers, spawners, and barriers via controller_id
 *
 * Difficulty scales based on:
 * 1. Population - more players = more mobs (base 1.0x + 0.3x per player)
 * 2. Wave count - reserves split across waves (1 wave = 1.0x, 2 waves = 0.6x each, 3 waves = 0.4x each)
 *
 * Enemy difficulty increases with how deep into the train the car is, expressed as a
 * tier from GetDifficultyTier() rather than an absolute car number, so the curve
 * re-spreads automatically if the map gains or loses cars:
 * - Tier 1 (first third): Easy enemies, 1 wave
 * - Tier 2 (middle): Mix of easy/medium enemies, 2 waves
 * - Tier 3 (second to last): Medium/hard enemies, 3 waves
 * - Tier 4 (last car and boss car): Hardest enemies, 3 waves
 *
 * Car numbers are assigned when players trigger a car, NOT when the car loads - the
 * random rooms finish loading in an arbitrary order, so creation order says nothing
 * about where a car sits in the train. Barriers force strictly linear progress, so the
 * order players trigger cars in is the order the cars are physically arranged.
 */
/datum/wave_controller
	/// Unique identifier to link landmarks together
	var/id
	/// Which car in the train this is (1 = first car players trigger). 0 until activated.
	var/controller_number = 0
	/// Whether this is the boss car, which always ends the round regardless of car number
	var/is_boss_car = FALSE
	/// List of spawn landmarks associated with this controller
	var/list/wave_spawners = list()
	/// List of barriers to unlock when complete (supports multiple barriers per controller)
	var/list/barriers = list()
	/// Reference to the trigger landmark
	var/obj/effect/landmark/wave_trigger/trigger
	/// Current wave number (0 = not started)
	var/current_wave = 0
	/// Total waves to complete (calculated from spawners)
	var/max_waves = 1
	/// List of mobs spawned by this controller that are still alive
	var/list/living_mobs = list()
	/// Whether the controller has been triggered
	var/activated = FALSE
	/// Whether all waves are complete
	var/completed = FALSE
	/// Total mobs remaining in current wave's reserve (across all spawners)
	var/wave_reserve_remaining = 0
	/// Number of spawn effects currently pending (mob not yet created)
	var/pending_spawns = 0

/datum/wave_controller/New(new_id)
	. = ..()
	id = new_id
	is_boss_car = (id == WAVE_BOSS_CONTROLLER_ID)
	//Counted for verification against GLOB.wave_total_cars - not used for any game logic
	if(!is_boss_car)
		GLOB.wave_cars_loaded++
	GLOB.wave_controllers += src

/datum/wave_controller/Destroy()
	GLOB.wave_controllers -= src
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)
	return ..()

/// Returns the difficulty tier (1 = easiest, 4 = hardest) from how deep into the train this car is
/// Expressed as a fraction of the total car count so the curve re-spreads by itself when
/// cars are added to or removed from the map - nothing here should hardcode a car count
/datum/wave_controller/proc/GetDifficultyTier()
	if(is_boss_car)
		return 4
	var/progress = controller_number / max(GLOB.wave_total_cars, 1)
	if(progress <= WAVE_TIER2_CUTOFF)
		return 1
	if(progress <= WAVE_TIER3_CUTOFF)
		return 2
	if(progress <= WAVE_TIER4_CUTOFF)
		return 3
	return 4

/// Returns the number of waves for this car
/// The wave thresholds line up exactly with the difficulty tiers, so tier 4 (last car and
/// the boss car) caps at 3 waves - on the boss car that means 2 normal waves then the boss
/datum/wave_controller/proc/GetWaveCount()
	return min(GetDifficultyTier(), 3)

/// Returns the target total mobs for a wave based on player count
/// 20 players = 35 mobs, scales linearly (1.75 mobs per player, minimum 8)
/datum/wave_controller/proc/GetTargetMobCount()
	if(is_boss_car)
		return WAVE_MIN_MOBS //Boss car uses minimum

	//Count living W-Corp players
	var/player_count = 0
	for(var/mob/living/carbon/human/H in GLOB.human_list)
		if(H.stat != DEAD && H.ckey)
			player_count++

	//Calculate target: 1.75 mobs per player, minimum 8
	var/target_mobs = round(player_count * WAVE_MOBS_PER_PLAYER)
	return max(target_mobs, WAVE_MIN_MOBS)

/// Returns the multiplier for splitting reserves across multiple waves
/// 1 wave = 1.0x, 2 waves = 0.6x each, 3 waves = 0.4x each
/datum/wave_controller/proc/GetWaveReserveMultiplier()
	switch(max_waves)
		if(2)
			return 0.6
		if(3)
			return 0.4
	return 1.0

/// Called when the trigger is activated - starts wave spawning
/datum/wave_controller/proc/Activate()
	if(activated)
		return
	activated = TRUE
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH, PROC_REF(OnMobDeath))

	//Claim our place in the train. Rooms load in a random order, so creation order is
	//meaningless - but barriers force players through the cars one at a time, so the
	//order cars get triggered in IS the order they are physically arranged.
	if(!controller_number)
		controller_number = ++GLOB.wave_cars_activated
	log_game("W-Corp wave: car [id] activated as car [controller_number]/[GLOB.wave_total_cars] (tier [GetDifficultyTier()][is_boss_car ? ", boss" : ""])")

	//Start the mission clock on the first car players trigger - time spent preparing in
	//the staging area shouldn't count against the deadline. Only the first call arms it.
	var/datum/game_mode/combat/combat_mode = SSticker.mode
	if(istype(combat_mode))
		combat_mode.StartWcorpTimer()

	//Set wave count based on difficulty tier
	max_waves = GetWaveCount()

	//Announce car number with blurb
	var/car_name = "CAR [controller_number]"
	if(is_boss_car)
		car_name = "FINAL CAR - BOSS"
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(show_global_blurb), 3 SECONDS, car_name, 1 SECONDS, 5, "#1b7ced", "black", "left", WAVE_BLURB_CAR_ENTRY)

	//Small delay before first wave
	sleep(1 SECONDS)
	StartNextWave()

/// Spawns the next wave of mobs
/datum/wave_controller/proc/StartNextWave()
	current_wave++
	if(current_wave > max_waves)
		CompleteWaves()
		return

	//Boss car final wave - spawn boss instead of normal mobs
	if(is_boss_car && current_wave == max_waves)
		SpawnBossWave()
		return

	//Calculate total reserve for this wave based on player count (shared pool)
	var/target_mobs = round(GetTargetMobCount() * GetWaveReserveMultiplier())
	wave_reserve_remaining = max(target_mobs, 4) //Minimum 4 mobs per wave

	//Reset all active spawners for this wave
	for(var/obj/effect/landmark/wave_spawn/spawner in wave_spawners)
		if(spawner.wave_number == 0 || spawner.wave_number == current_wave)
			spawner.ResetForWave()

	//Announce wave start with blurb
	var/wave_text = "WAVE [current_wave]/[max_waves] - [wave_reserve_remaining] HOSTILES"
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(show_global_blurb), 2 SECONDS, wave_text, 0.5 SECONDS, 5, "#1b7ced", "black", "left", WAVE_BLURB_WAVE)

	//Initial spawn from all spawners for this wave (pulls from shared pool)
	for(var/obj/effect/landmark/wave_spawn/spawner in wave_spawners)
		if(spawner.wave_number == 0 || spawner.wave_number == current_wave)
			spawner.InitialSpawn(src)

	//If no mobs were spawned (misconfigured), move to next wave
	if(!LAZYLEN(living_mobs) && wave_reserve_remaining <= 0)
		StartNextWave()

/// Spawns the boss wave - picks a random spawner location and spawns the boss there
/datum/wave_controller/proc/SpawnBossWave()
	wave_reserve_remaining = 1

	//Announce boss wave
	var/wave_text = "FINAL WAVE - BOSS INCOMING"
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(show_global_blurb), 3 SECONDS, wave_text, 1 SECONDS, 5, "#ff0000", "black", "left", WAVE_BLURB_WAVE)

	//Pick a random spawner location for the boss
	var/list/valid_spawners = list()
	for(var/obj/effect/landmark/wave_spawn/spawner in wave_spawners)
		valid_spawners += spawner

	if(!LAZYLEN(valid_spawners))
		//No spawners, just complete
		CompleteWaves()
		return

	var/obj/effect/landmark/wave_spawn/chosen_spawner = pick(valid_spawners)
	var/turf/spawn_turf = get_turf(chosen_spawner)

	//Pick a boss type
	var/list/boss_types = list(/mob/living/simple_animal/hostile/lovetown/abomination, /mob/living/simple_animal/hostile/ordeal/white_lake_corrosion)
	var/boss_type = pick(boss_types)

	//Create spawn effect for boss
	pending_spawns++
	new /obj/effect/wave_mob_spawn/boss(spawn_turf, boss_type, src, chosen_spawner)

/// Called when any mob dies - checks if it was one of ours
/datum/wave_controller/proc/OnMobDeath(datum/source, mob/living/dead_mob)
	SIGNAL_HANDLER

	if(!(dead_mob in living_mobs))
		return

	living_mobs -= dead_mob

	//Find which spawner this mob came from and try to spawn a replacement
	var/obj/effect/landmark/wave_spawn/source_spawner = GLOB.wave_mob_sources[dead_mob]
	if(source_spawner && (source_spawner.wave_number == 0 || source_spawner.wave_number == current_wave))
		INVOKE_ASYNC(source_spawner, TYPE_PROC_REF(/obj/effect/landmark/wave_spawn, TrySpawnReplacement), src)
	GLOB.wave_mob_sources -= dead_mob

	//Check if wave is cleared (no living mobs AND no reserve left AND no pending spawns)
	if(!LAZYLEN(living_mobs) && wave_reserve_remaining <= 0 && pending_spawns <= 0)
		INVOKE_ASYNC(src, PROC_REF(WaveCleared))
	//If no living mobs but reserve remains, try to force spawns from any available spawner
	else if(!LAZYLEN(living_mobs) && wave_reserve_remaining > 0 && pending_spawns <= 0)
		INVOKE_ASYNC(src, PROC_REF(TryForceSpawns))

/// Called when all mobs in current wave are dead and reserve depleted
/datum/wave_controller/proc/WaveCleared()
	//Announce wave cleared with prominent blurb
	var/clear_text = "WAVE [current_wave] CLEARED"
	if(current_wave < max_waves)
		clear_text += " - NEXT WAVE INCOMING"
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(show_global_blurb), 3 SECONDS, clear_text, 0.5 SECONDS, 5, "#00ff00", "black", "left", WAVE_BLURB_WAVE)

	//Heal all living humans for 50% of missing HP/SP
	HealAllPlayers()

	//Clean up blood decals to reduce visual clutter and lag
	CleanupBlood()

	//Longer delay between waves for clarity
	sleep(4 SECONDS)
	StartNextWave()

/// Heals all living humans for 50% of their missing HP and SP
/datum/wave_controller/proc/HealAllPlayers()
	for(var/mob/living/carbon/human/H in GLOB.human_list)
		if(H.stat == DEAD)
			continue
		if(!H.ckey)
			continue
		//Heal 50% of missing health
		var/missing_health = H.maxHealth - H.health
		if(missing_health > 0)
			H.adjustBruteLoss(-(missing_health * 0.5))
		//If insane, deal WHITE damage to cure them (WHITE heals insane humans)
		if(H.sanity_lost)
			H.deal_damage(999, WHITE_DAMAGE)
		else
			//Heal 50% of missing sanity
			var/missing_sanity = H.maxSanity - H.sanityhealth
			if(missing_sanity > 0)
				H.adjustSanityLoss(-(missing_sanity * 0.5))

/// Cleans up all blood decals in the world to reduce clutter
/datum/wave_controller/proc/CleanupBlood()
	for(var/obj/effect/decal/cleanable/blood/B in world)
		qdel(B)

/// Called when all waves are complete
/datum/wave_controller/proc/CompleteWaves()
	completed = TRUE
	UnregisterSignal(SSdcs, COMSIG_GLOB_MOB_DEATH)

	//Announce completion with blurb
	var/complete_text
	if(is_boss_car)
		complete_text = "BOSS DEFEATED - VICTORY!"
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(show_global_blurb), 5 SECONDS, complete_text, 1 SECONDS, 5, "#ffd700", "black", "left", WAVE_BLURB_CAR_STATUS)
		//End the round in victory after a short delay
		addtimer(CALLBACK(src, PROC_REF(EndRoundVictory)), 10 SECONDS)
	else
		complete_text = "CAR [controller_number] CLEARED - PROCEED"
		INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(show_global_blurb), 3 SECONDS, complete_text, 0.5 SECONDS, 5, "#00ff00", "black", "left", WAVE_BLURB_CAR_STATUS)

	//Unlock all barriers
	for(var/obj/structure/wave_barrier/B in barriers)
		B.Unlock()

/// Ends the round in victory
/datum/wave_controller/proc/EndRoundVictory()
	SSticker.force_ending = TRUE
	to_chat(world, span_userdanger("W-Corp has successfully cleared the train! Round ending in victory."))

/// Registers a spawn landmark with this controller
/datum/wave_controller/proc/RegisterSpawner(obj/effect/landmark/wave_spawn/spawner)
	wave_spawners += spawner
	//Update max_waves based on highest wave_number
	if(spawner.wave_number > max_waves)
		max_waves = spawner.wave_number

/// Registers a barrier with this controller (supports multiple barriers)
/datum/wave_controller/proc/RegisterBarrier(obj/structure/wave_barrier/new_barrier)
	barriers += new_barrier

/// Registers a trigger with this controller
/datum/wave_controller/proc/RegisterTrigger(obj/effect/landmark/wave_trigger/new_trigger)
	trigger = new_trigger

/// Adds a spawned mob to tracking
/datum/wave_controller/proc/TrackMob(mob/living/spawned_mob, obj/effect/landmark/wave_spawn/source)
	living_mobs += spawned_mob
	GLOB.wave_mob_sources[spawned_mob] = source

/// Attempts to spawn from any available spawner when mobs are dead but reserve remains
/datum/wave_controller/proc/TryForceSpawns()
	//Safety check - if mobs exist or spawns pending, don't force
	if(LAZYLEN(living_mobs) || pending_spawns > 0)
		return

	if(wave_reserve_remaining <= 0)
		INVOKE_ASYNC(src, PROC_REF(WaveCleared))
		return

	var/spawned_any = FALSE
	for(var/obj/effect/landmark/wave_spawn/spawner in wave_spawners)
		if(wave_reserve_remaining <= 0)
			break
		//wave_number 0 means spawner is active for all waves
		if(spawner.wave_number != 0 && spawner.wave_number != current_wave)
			continue
		if(spawner.current_alive >= spawner.concurrent_max)
			continue
		//Try to spawn - use retry mechanism
		INVOKE_ASYNC(spawner, TYPE_PROC_REF(/obj/effect/landmark/wave_spawn, TrySpawnWithRetry), src)
		spawned_any = TRUE

	//If no spawners could spawn but reserve remains, all spawners are at capacity - wait for deaths
	if(!spawned_any && wave_reserve_remaining > 0)
		return //Wait for mobs to die and free up spawner slots

/// Increments pending spawn counter (called when spawn effect is created)
/datum/wave_controller/proc/AddPendingSpawn()
	pending_spawns++

/// Decrements pending spawn counter and checks wave completion (called when mob actually spawns)
/datum/wave_controller/proc/ResolvePendingSpawn()
	pending_spawns = max(0, pending_spawns - 1)
	//Check wave completion in case all mobs died while spawns were pending
	if(!LAZYLEN(living_mobs) && wave_reserve_remaining <= 0 && pending_spawns <= 0)
		INVOKE_ASYNC(src, PROC_REF(WaveCleared))

/*
 * Wave Trigger Landmark
 * When a human walks over this, activates the linked wave controller
 */
/obj/effect/landmark/wave_trigger
	name = "wave trigger"
	desc = "Triggers a wave spawn when crossed. Notify a coder if you see this."
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x2"
	/// ID to link to wave controller
	var/controller_id = "wave_1"
	/// Reference to linked controller
	var/datum/wave_controller/controller
	/// Has this trigger been used?
	var/triggered = FALSE

/obj/effect/landmark/wave_trigger/Initialize()
	. = ..()
	//Find or create controller with matching ID
	for(var/datum/wave_controller/C in GLOB.wave_controllers)
		if(C.id == controller_id)
			controller = C
			break
	if(!controller)
		controller = new /datum/wave_controller(controller_id)
	controller.RegisterTrigger(src)

/obj/effect/landmark/wave_trigger/Crossed(atom/movable/AM)
	. = ..()
	if(triggered)
		return
	if(!ishuman(AM))
		return
	if(isobserver(AM))
		return

	triggered = TRUE
	controller.Activate()

/*
 * Wave Spawn Landmark
 * Spawns mobs when activated by wave controller
 * Maintains concurrent_max mobs at a time, spawning from reserve when one dies
 */
/obj/effect/landmark/wave_spawn
	name = "wave spawner"
	desc = "Spawns mobs during a wave. Notify a coder if you see this."
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x3"
	/// ID to link to wave controller
	var/controller_id = "wave_1"
	/// Which wave number this spawner activates on (0 = all waves)
	var/wave_number = 0
	/// List of possible mob types to spawn (picks one randomly) - used if not using dynamic spawning
	var/list/spawn_types = list()
	/// Maximum concurrent mobs from this spawner at once
	var/concurrent_max = 2
	/// Reference to linked controller
	var/datum/wave_controller/controller
	/// Current number of living mobs from this spawner
	var/current_alive = 0
	/// Whether to use dynamic faction-based spawning
	var/use_dynamic_spawning = TRUE
	/// Whether this spawner is on cooldown
	var/on_cooldown = FALSE

/obj/effect/landmark/wave_spawn/Initialize()
	. = ..()
	//Find or create controller with matching ID
	for(var/datum/wave_controller/C in GLOB.wave_controllers)
		if(C.id == controller_id)
			controller = C
			break
	if(!controller)
		controller = new /datum/wave_controller(controller_id)
	controller.RegisterSpawner(src)

/// Resets spawner state for a new wave (shared pool is managed by controller)
/obj/effect/landmark/wave_spawn/proc/ResetForWave()
	current_alive = 0

/// Initial spawn when wave starts - spawns up to concurrent_max from shared pool
/obj/effect/landmark/wave_spawn/proc/InitialSpawn(datum/wave_controller/wave_controller)
	var/to_spawn = min(concurrent_max, wave_controller.wave_reserve_remaining)
	for(var/i = 1 to to_spawn)
		if(wave_controller.wave_reserve_remaining <= 0)
			break
		SpawnOneMob(wave_controller)

/// Gets the appropriate mob type based on difficulty tier and faction
/obj/effect/landmark/wave_spawn/proc/GetSpawnType(tier)
	//If we have manual spawn_types set, use those
	if(LAZYLEN(spawn_types) && !use_dynamic_spawning)
		return pick(spawn_types)

	//Otherwise use dynamic faction-based spawning
	var/faction = GLOB.wave_enemy_faction
	if(!faction)
		//Pick a random faction if not set
		faction = pick("lovetown", "peccatulum", "gcorp")
		GLOB.wave_enemy_faction = faction

	//Select mob based on difficulty tier
	switch(faction)
		if("lovetown")
			return GetLovetownMob(tier)
		if("gcorp")
			return GetGcorpMob(tier)
		if("peccatulum")
			return GetPeccatulumMob(tier)

	//Fallback
	return /mob/living/simple_animal/hostile/ordeal/steel_dawn

/// Lovetown mob selection based on difficulty tier
/obj/effect/landmark/wave_spawn/proc/GetLovetownMob(tier)
	switch(tier)
		//Tier 1: Easy - Suicidals, Slashers, Stabbers
		if(1)
			switch(rand(1, 100))
				if(1 to 50)
					return /mob/living/simple_animal/hostile/lovetown/suicidal
				if(51 to 75)
					return /mob/living/simple_animal/hostile/lovetown/slasher
				else
					return /mob/living/simple_animal/hostile/lovetown/stabber

		//Tier 2: Medium - Less suicidals, add Slammers
		if(2)
			switch(rand(1, 100))
				if(1 to 20)
					return /mob/living/simple_animal/hostile/lovetown/suicidal
				if(21 to 45)
					return /mob/living/simple_animal/hostile/lovetown/slasher
				if(46 to 70)
					return /mob/living/simple_animal/hostile/lovetown/stabber
				else
					return /mob/living/simple_animal/hostile/lovetown/slammer

		//Tiers 3-4: Hard - Mix of all, with Shamblers and Slumberers
		if(3 to 4)
			switch(rand(1, 100))
				if(1 to 10)
					return /mob/living/simple_animal/hostile/lovetown/suicidal
				if(11 to 25)
					return /mob/living/simple_animal/hostile/lovetown/slasher
				if(26 to 40)
					return /mob/living/simple_animal/hostile/lovetown/stabber
				if(41 to 55)
					return /mob/living/simple_animal/hostile/lovetown/slammer
				if(56 to 75)
					return /mob/living/simple_animal/hostile/lovetown/shambler
				else
					return /mob/living/simple_animal/hostile/lovetown/slumberer

	return /mob/living/simple_animal/hostile/lovetown/suicidal

/// G-Corp mob selection based on difficulty tier
/obj/effect/landmark/wave_spawn/proc/GetGcorpMob(tier)
	switch(tier)
		//Tier 1: Easy - Mostly Dawn, some Noon
		if(1)
			if(prob(85))
				return /mob/living/simple_animal/hostile/ordeal/steel_dawn
			return /mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon

		//Tier 2: Medium - Mix of Dawn/Noon, some Flying
		if(2)
			switch(rand(1, 100))
				if(1 to 40)
					return /mob/living/simple_animal/hostile/ordeal/steel_dawn
				if(41 to 75)
					return /mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon
				else
					return /mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/flying

		//Tiers 3-4: Hard - Mix of all, with Dusk managers
		if(3 to 4)
			switch(rand(1, 100))
				if(1 to 15)
					return /mob/living/simple_animal/hostile/ordeal/steel_dawn
				if(16 to 40)
					return /mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon
				if(41 to 65)
					return /mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/flying
				else
					return /mob/living/simple_animal/hostile/ordeal/steel_dusk

	return /mob/living/simple_animal/hostile/ordeal/steel_dawn

/// Peccatulum mob selection based on difficulty tier (uses /wave variants that can't dash through barriers)
/obj/effect/landmark/wave_spawn/proc/GetPeccatulumMob(tier)
	switch(tier)
		//Tier 1: Easy - Gluttony, Sloth
		if(1)
			if(prob(70))
				return /mob/living/simple_animal/hostile/ordeal/sin_gluttony/wave
			return /mob/living/simple_animal/hostile/ordeal/sin_sloth/wave

		//Tier 2: Medium - Add Gloom, some Noon variants (no Pride/Gloom noon)
		if(2)
			switch(rand(1, 100))
				if(1 to 25)
					return /mob/living/simple_animal/hostile/ordeal/sin_gluttony/wave
				if(26 to 45)
					return /mob/living/simple_animal/hostile/ordeal/sin_sloth/wave
				if(46 to 65)
					return /mob/living/simple_animal/hostile/ordeal/sin_gloom/wave
				if(66 to 80)
					return /mob/living/simple_animal/hostile/ordeal/sin_gluttony/noon/wave
				else
					return /mob/living/simple_animal/hostile/ordeal/sin_sloth/noon/wave

		//Tier 3: Hard - Noon variants but no Pride/Gloom noon yet, always chance for T1
		if(3)
			switch(rand(1, 100))
				if(1 to 15)
					return /mob/living/simple_animal/hostile/ordeal/sin_gluttony/wave
				if(16 to 30)
					return /mob/living/simple_animal/hostile/ordeal/sin_sloth/wave
				if(31 to 45)
					return /mob/living/simple_animal/hostile/ordeal/sin_gloom/wave
				if(46 to 60)
					return /mob/living/simple_animal/hostile/ordeal/sin_wrath/noon/wave
				if(61 to 75)
					return /mob/living/simple_animal/hostile/ordeal/sin_lust/noon/wave
				if(76 to 88)
					return /mob/living/simple_animal/hostile/ordeal/sin_gluttony/noon/wave
				else
					return /mob/living/simple_animal/hostile/ordeal/sin_sloth/noon/wave

		//Tier 4: Hardest - Pride/Gloom noon can spawn, always chance for T1
		if(4)
			switch(rand(1, 100))
				if(1 to 10)
					return /mob/living/simple_animal/hostile/ordeal/sin_gluttony/wave
				if(11 to 20)
					return /mob/living/simple_animal/hostile/ordeal/sin_sloth/wave
				if(21 to 30)
					return /mob/living/simple_animal/hostile/ordeal/sin_gloom/wave
				if(31 to 45)
					return /mob/living/simple_animal/hostile/ordeal/sin_pride/noon/wave
				if(46 to 60)
					return /mob/living/simple_animal/hostile/ordeal/sin_gloom/noon/wave
				if(61 to 75)
					return /mob/living/simple_animal/hostile/ordeal/sin_wrath/noon/wave
				if(76 to 88)
					return /mob/living/simple_animal/hostile/ordeal/sin_lust/noon/wave
				else
					return /mob/living/simple_animal/hostile/ordeal/sin_gluttony/noon/wave

	return /mob/living/simple_animal/hostile/ordeal/sin_gluttony/wave

/// Bloodfiend mob selection based on difficulty tier (uses /wave variants that can't dash through barriers)
/obj/effect/landmark/wave_spawn/proc/GetBloodfiendMob(tier)
	switch(tier)
		//Tier 1: Easy - Mostly bags, some fiends
		if(1)
			if(prob(80))
				return /mob/living/simple_animal/hostile/humanoid/blood/bag/wave
			return /mob/living/simple_animal/hostile/humanoid/blood/fiend/wave

		//Tier 2: Medium - Mix of bags and fiends
		if(2)
			if(prob(50))
				return /mob/living/simple_animal/hostile/humanoid/blood/bag/wave
			return /mob/living/simple_animal/hostile/humanoid/blood/fiend/wave

		//Tiers 3-4: Hard - Mix of all, with bosses
		if(3 to 4)
			switch(rand(1, 100))
				if(1 to 25)
					return /mob/living/simple_animal/hostile/humanoid/blood/bag/wave
				if(26 to 70)
					return /mob/living/simple_animal/hostile/humanoid/blood/fiend/wave
				else
					return /mob/living/simple_animal/hostile/humanoid/blood/fiend/boss/wave

	return /mob/living/simple_animal/hostile/humanoid/blood/bag/wave

/// Spawns a single mob and tracks it (creates spawn effect first)
/obj/effect/landmark/wave_spawn/proc/SpawnOneMob(datum/wave_controller/wave_controller)
	if(wave_controller.wave_reserve_remaining <= 0)
		return FALSE
	if(on_cooldown)
		return FALSE

	//Start cooldown
	on_cooldown = TRUE
	addtimer(CALLBACK(src, PROC_REF(EndCooldown)), WAVE_SPAWNER_COOLDOWN)

	var/spawn_type = GetSpawnType(wave_controller.GetDifficultyTier())

	//Track pending spawn before creating effect
	wave_controller.AddPendingSpawn()

	//Pick a random turf within view 5 of the spawner
	var/turf/spawn_turf = GetRandomSpawnTurf()

	//Create spawn effect that will spawn the mob after delay
	new /obj/effect/wave_mob_spawn(spawn_turf, spawn_type, wave_controller, src)

	wave_controller.wave_reserve_remaining--
	current_alive++
	return TRUE

/// Returns a random valid turf within view 5 of the spawner
/obj/effect/landmark/wave_spawn/proc/GetRandomSpawnTurf()
	var/list/valid_turfs = list()
	var/turf/src_turf = get_turf(src)
	for(var/turf/T in view(5, src))
		if(T.density)
			continue
		if(locate(/obj/structure/wave_barrier) in T.contents)
			continue
		//Check line between spawner and turf for wave barriers
		var/barrier_in_path = FALSE
		for(var/turf/line_turf in getline(src_turf, T))
			if(locate(/obj/structure/wave_barrier) in line_turf.contents)
				barrier_in_path = TRUE
				break
		if(barrier_in_path)
			continue
		valid_turfs += T
	if(!LAZYLEN(valid_turfs))
		return src_turf //Fallback to spawner location
	return pick(valid_turfs)

/// Ends the spawner cooldown
/obj/effect/landmark/wave_spawn/proc/EndCooldown()
	on_cooldown = FALSE

/// Called by the spawn effect when mob is actually created
/obj/effect/landmark/wave_spawn/proc/RegisterSpawnedMob(mob/living/spawned_mob, datum/wave_controller/wave_controller)
	wave_controller.TrackMob(spawned_mob, src)

/// Called when a mob from this spawner dies - tries to spawn replacement
/obj/effect/landmark/wave_spawn/proc/TrySpawnReplacement(datum/wave_controller/wave_controller)
	current_alive = max(0, current_alive - 1)

	//If shared pool has reserve and room for more concurrent mobs, spawn one
	if(wave_controller.wave_reserve_remaining > 0 && current_alive < concurrent_max)
		sleep(0.5 SECONDS) //Small delay before replacement spawns
		TrySpawnWithRetry(wave_controller)

/// Attempts to spawn a mob, retrying if on cooldown
/obj/effect/landmark/wave_spawn/proc/TrySpawnWithRetry(datum/wave_controller/wave_controller, attempts = 0)
	if(attempts > 10) //Safety limit - stop after ~30 seconds of trying
		return
	if(wave_controller.wave_reserve_remaining <= 0)
		return
	if(!SpawnOneMob(wave_controller))
		//Failed due to cooldown, try again after cooldown ends
		addtimer(CALLBACK(src, PROC_REF(TrySpawnWithRetry), wave_controller, attempts + 1), WAVE_SPAWNER_COOLDOWN + 1)

/*
 * Wave Spawn Subtypes - Pre-configured for specific factions (optional, can use dynamic instead)
 */

//Lovetown spawners (manual, non-dynamic)
/obj/effect/landmark/wave_spawn/lovetown
	name = "lovetown wave spawner"
	use_dynamic_spawning = FALSE
	spawn_types = list(
		/mob/living/simple_animal/hostile/lovetown/suicidal,
		/mob/living/simple_animal/hostile/lovetown/slasher,
		/mob/living/simple_animal/hostile/lovetown/stabber
	)

/obj/effect/landmark/wave_spawn/lovetown/hard
	spawn_types = list(
		/mob/living/simple_animal/hostile/lovetown/slammer,
		/mob/living/simple_animal/hostile/lovetown/shambler,
		/mob/living/simple_animal/hostile/lovetown/slumberer
	)

//G-Corp spawners (manual, non-dynamic)
/obj/effect/landmark/wave_spawn/gcorp
	name = "gcorp wave spawner"
	use_dynamic_spawning = FALSE
	spawn_types = list(
		/mob/living/simple_animal/hostile/ordeal/steel_dawn,
		/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon
	)

/obj/effect/landmark/wave_spawn/gcorp/hard
	spawn_types = list(
		/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon,
		/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/flying,
		/mob/living/simple_animal/hostile/ordeal/steel_dusk
	)

//Peccatulum spawners (manual, non-dynamic)
/obj/effect/landmark/wave_spawn/peccatulum
	name = "peccatulum wave spawner"
	use_dynamic_spawning = FALSE
	spawn_types = list(
		/mob/living/simple_animal/hostile/ordeal/sin_gluttony,
		/mob/living/simple_animal/hostile/ordeal/sin_sloth,
		/mob/living/simple_animal/hostile/ordeal/sin_gloom
	)

/obj/effect/landmark/wave_spawn/peccatulum/hard
	spawn_types = list(
		/mob/living/simple_animal/hostile/ordeal/sin_pride,
		/mob/living/simple_animal/hostile/ordeal/sin_wrath,
		/mob/living/simple_animal/hostile/ordeal/sin_lust
	)

//Bloodfiend spawners (manual, non-dynamic)
/obj/effect/landmark/wave_spawn/bloodfiend
	name = "bloodfiend wave spawner"
	use_dynamic_spawning = FALSE
	spawn_types = list(
		/mob/living/simple_animal/hostile/humanoid/blood/bag,
		/mob/living/simple_animal/hostile/humanoid/blood/fiend
	)

/obj/effect/landmark/wave_spawn/bloodfiend/hard
	spawn_types = list(
		/mob/living/simple_animal/hostile/humanoid/blood/fiend,
		/mob/living/simple_animal/hostile/humanoid/blood/fiend/boss
	)

//Dynamic spawner - uses faction-based scaling automatically
/obj/effect/landmark/wave_spawn/dynamic
	name = "dynamic wave spawner"
	use_dynamic_spawning = TRUE

//Boss spawner - for final car (single spawn, no replacement)
/obj/effect/landmark/wave_spawn/boss
	name = "boss wave spawner"
	icon_state = "x4"
	concurrent_max = 1
	use_dynamic_spawning = FALSE
	spawn_types = list(
		/mob/living/simple_animal/hostile/lovetown/abomination,
		/mob/living/simple_animal/hostile/ordeal/white_lake_corrosion
	)

/*
 * Wave Mob Spawn Effect
 * Visual warning effect before mob spawns
 */
/obj/effect/wave_mob_spawn
	name = "distortion"
	desc = "Reality warps as something prepares to emerge."
	icon = 'icons/effects/cult_effects.dmi'
	icon_state = "bloodin"
	move_force = INFINITY
	pull_force = INFINITY
	generic_canpass = FALSE
	movement_type = PHASING | FLYING
	layer = POINT_LAYER
	/// The mob type to spawn
	var/mob_type
	/// Reference to the wave controller
	var/datum/wave_controller/controller
	/// Reference to the spawner landmark
	var/obj/effect/landmark/wave_spawn/spawner

/obj/effect/wave_mob_spawn/Initialize(mapload, spawn_type, datum/wave_controller/wave_controller, obj/effect/landmark/wave_spawn/source_spawner)
	. = ..()
	mob_type = spawn_type
	controller = wave_controller
	spawner = source_spawner
	addtimer(CALLBACK(src, PROC_REF(SpawnMob)), WAVE_SPAWN_DELAY)

/obj/effect/wave_mob_spawn/proc/SpawnMob()
	if(!mob_type || !controller || !spawner)
		//Still need to resolve pending spawn even if we fail
		if(controller)
			controller.ResolvePendingSpawn()
		qdel(src)
		return

	var/mob/living/simple_animal/hostile/H = new mob_type(get_turf(src))
	H.can_patrol = TRUE
	H.patrol_cooldown_time = 10 SECONDS
	//Delete on death to reduce lag, except bloodbags and lovetown mobs which have special death behavior
	if(!istype(H, /mob/living/simple_animal/hostile/humanoid/blood/bag) && !istype(H, /mob/living/simple_animal/hostile/lovetown))
		H.del_on_death = TRUE
	spawner.RegisterSpawnedMob(H, controller)
	controller.ResolvePendingSpawn()
	qdel(src)

/*
 * Boss Wave Mob Spawn Effect
 * Special spawn effect for boss mobs - longer delay, different visual
 */
/obj/effect/wave_mob_spawn/boss
	name = "massive distortion"
	desc = "Reality tears as something powerful prepares to emerge."

/obj/effect/wave_mob_spawn/boss/Initialize(mapload, spawn_type, datum/wave_controller/wave_controller, obj/effect/landmark/wave_spawn/source_spawner)
	. = ..()
	//Override the timer with a longer delay for boss dramatic effect
	deltimer(CALLBACK(src, PROC_REF(SpawnMob)))
	addtimer(CALLBACK(src, PROC_REF(SpawnMob)), 3 SECONDS)

/obj/effect/wave_mob_spawn/boss/SpawnMob()
	if(!mob_type || !controller)
		if(controller)
			controller.ResolvePendingSpawn()
		qdel(src)
		return

	var/mob/living/simple_animal/hostile/H = new mob_type(get_turf(src))
	H.can_patrol = TRUE
	H.patrol_cooldown_time = 10 SECONDS
	//Boss tracks directly to controller, not through spawner
	controller.living_mobs += H
	controller.ResolvePendingSpawn()
	qdel(src)

/*
 * Wave Barrier
 * A structure that prevents passage until waves are cleared
 */
/obj/structure/wave_barrier
	name = "energy barrier"
	desc = "An barrier blocking the way forward. Clear all enemies to proceed."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield-old"
	anchored = TRUE
	density = TRUE
	opacity = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	/// ID to link to wave controller
	var/controller_id = "wave_1"
	/// Reference to linked controller
	var/datum/wave_controller/controller

/obj/structure/wave_barrier/Initialize()
	. = ..()
	//Find or create controller with matching ID
	for(var/datum/wave_controller/C in GLOB.wave_controllers)
		if(C.id == controller_id)
			controller = C
			break
	if(!controller)
		controller = new /datum/wave_controller(controller_id)
	controller.RegisterBarrier(src)

/obj/structure/wave_barrier/Bumped(atom/movable/AM)
	. = ..()
	if(ishuman(AM))
		to_chat(AM, span_warning("A barrier blocks your path. Clear all enemies to proceed!"))

/// Called by controller when waves are complete
/obj/structure/wave_barrier/proc/Unlock()
	visible_message(span_nicegreen("The barrier ahead dissipates!"))
	qdel(src)
