/obj/structure/den/rce
	name = "X-Corp Attack Pylon"
	desc = "Best destroy this!"
	icon_state = "powerpylon"
	icon = 'icons/obj/hand_of_god_structures.dmi'
	color = "#FF5522"
	light_color = "#FF5522"
	light_range = 3
	light_power = 1
	max_integrity = 500
	moblist = list(
		/mob/living/simple_animal/hostile/xcorp = 4,
		/mob/living/simple_animal/hostile/xcorp/scout = 2,
	)
	var/announce = FALSE
	var/id
	var/assault_type = SEND_ONLY_DEFEATED
	var/max_mobs = 18
	var/generate_new_mob_time = NONE
	var/raider = FALSE

/obj/structure/den/rce/announcer
	light_range = 5
	max_mobs = 40
	moblist = list(
		/mob/living/simple_animal/hostile/xcorp = 2,
		/mob/living/simple_animal/hostile/xcorp/scout = 3,
		/mob/living/simple_animal/hostile/xcorp/sapper = 3,
		/mob/living/simple_animal/hostile/xcorp/tank = 2,
		/mob/living/simple_animal/hostile/xcorp/dps = 2,
	)
	generate_new_mob_time = 50 SECONDS
	raider = TRUE
	announce = TRUE

/obj/structure/den/rce/mid
	light_range = 4
	max_mobs = 10
	moblist = list(
		/mob/living/simple_animal/hostile/xcorp = 2,
		/mob/living/simple_animal/hostile/xcorp/dps = 1,
		/mob/living/simple_animal/hostile/xcorp/tank = 1,
		/mob/living/simple_animal/hostile/xcorp/scout = 1,
	)
	generate_new_mob_time = 22 SECONDS

/obj/structure/den/rce/high
	light_range = 7
	max_mobs = 12
	moblist = list(
		/mob/living/simple_animal/hostile/xcorp/scout = 2,
		/mob/living/simple_animal/hostile/xcorp/sapper = 2,
		/mob/living/simple_animal/hostile/xcorp/dps = 2,
		/mob/living/simple_animal/hostile/xcorp/tank = 3,
	)
	generate_new_mob_time = 15 SECONDS

/obj/structure/den/rce/raider
	light_range = 5
	max_mobs = 30
	moblist = list(
		/mob/living/simple_animal/hostile/xcorp = 2,
		/mob/living/simple_animal/hostile/xcorp/scout = 3,
		/mob/living/simple_animal/hostile/xcorp/sapper = 1,
		/mob/living/simple_animal/hostile/xcorp/tank = 2,
		/mob/living/simple_animal/hostile/xcorp/dps = 2,
	)
	assault_type = SEND_TILL_MAX
	generate_new_mob_time = 30 SECONDS
	raider = TRUE

/obj/structure/den/rce/Initialize(mapload)
	. = ..()
	if(id)
		target = SSgamedirector.GetTargetById(id)
	else
		target = SSgamedirector.GetRandomRaiderTarget()
	AddComponent(/datum/component/monwave_spawner, attack_target = target, max_mobs = max_mobs, assault_type = assault_type, new_wave_order = moblist, try_for_announcer = announce, new_wave_cooldown_time = generate_new_mob_time, raider = raider, register = TRUE)

/obj/structure/den/rce_defender
	name = "X-Corp Defense Pylon"
	desc = "Best destroy this!"
	icon_state = "defensepylon"
	icon = 'icons/obj/hand_of_god_structures.dmi'
	color = "#FF0000"
	max_integrity = 1000
	light_color = "#aa1100"
	light_range = 5
	light_power = 2
	moblist = list(
		/mob/living/simple_animal/hostile/xcorp = 4,
		/mob/living/simple_animal/hostile/xcorp/tank = 4,
		/mob/living/simple_animal/hostile/xcorp/heart = 3,
		/mob/living/simple_animal/hostile/xcorp/heart/ranged = 2,
		/mob/living/simple_animal/hostile/xcorp/heart/dps = 1,
	)
	var/announce = FALSE
	var/id
	var/assault_type = SEND_TILL_MAX
	var/max_mobs = 30
	var/generate_new_mob_time = NONE
	var/raider = FALSE

/obj/structure/den/rce_defender/Initialize(mapload)
	. = ..()
	if(id)
		target = SSgamedirector.GetTargetById(id)
	if(!target)
		target = get_turf(src)
	AddComponent(/datum/component/monwave_spawner, attack_target = target, max_mobs = max_mobs, assault_type = assault_type, new_wave_order = moblist, try_for_announcer = announce, new_wave_cooldown_time = generate_new_mob_time, raider = raider, register = TRUE)

/obj/structure/rce_heart
	name = "X-Corp Heart"
	desc = "Best destroy this!"
	icon_state = "nexus"
	icon = 'icons/obj/hand_of_god_structures.dmi'
	color = "#FF0000"
	max_integrity = 1

/obj/structure/rce_heart/Initialize()
	. = ..()
	AddElement(/datum/element/point_of_interest)

/obj/structure/rce_heart/Destroy()
	SSgamedirector.AnnounceVictory()
	. = ..()

/obj/structure/rce_portal
	name = "Raid Portal"
	desc = span_danger("Click me to register to fight the heart")
	icon = 'icons/obj/hand_of_god_structures.dmi'
	icon_state = "fountain"
	maptext = "<b><span style='color: red;'>EXAMINE ME</span></b>"
	maptext_height = 32
	maptext_width = 64
	maptext_x = -16
	maptext_y = 8
	density = TRUE
	resistance_flags = INDESTRUCTIBLE

/obj/structure/rce_portal/Initialize()
	. = ..()
	SSgamedirector.RegisterPortal(src)

/obj/structure/rce_portal/attack_hand(mob/living/user)
	if(tgui_alert(user, "Do you want to register to fight the Heart of Greed?", "Go die?", list("Yes", "No"), timeout = 30 SECONDS) == "Yes")
		SSgamedirector.RegisterCombatant(user)

/obj/structure/player_blocker
	name = "forcefield"
	desc = "Impassable to some."
	icon = 'icons/effects/cult_effects.dmi'
	icon_state = "cultshield"
	light_color = "#aa0000"
	light_range = 3
	light_power = 1
	alpha = 200
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE
	pass_flags_self = 0

/obj/structure/player_blocker/invisible
	light_color = null
	light_range = 0
	light_power = 0
	alpha = 0

/obj/structure/player_blocker/CanAllowThrough(atom/movable/A, turf/T)
	. = ..()

	if(!isliving(A))
		return FALSE
	if(istype(A, /mob/living/simple_animal))
		return TRUE
	return FALSE

/obj/structure/player_blocker/CanAStarPass(ID, to_dir, requester)
	return TRUE

// Greed Gateway - spawns X-Corp mobs during last wave
/obj/effect/greed_gateway
	name = "Greed Gateway"
	desc = "A swirling vortex of avarice that continuously spawns corrupted beings."
	icon = 'icons/effects/96x96.dmi'
	icon_state = "singularity_s3"
	pixel_x = -32
	pixel_y = -32
	light_range = 6
	light_power = 3
	light_color = "#FF0000"
	anchored = TRUE
	var/list/spawned_mobs = list()
	var/max_spawned_mobs = 50
	var/spawn_cooldown = 0
	var/spawn_cooldown_time = 10 SECONDS
	var/min_spawn_count = 8
	var/max_spawn_count = 12
	var/obj/effect/landmark/fob_escape_shuttle/target_shuttle
	var/list/assault_path = list()
	var/list/active_waves = list()	// Track wave commanders
	var/list/mob_spawn_weights = list(
		/mob/living/simple_animal/hostile/xcorp = 30,
		/mob/living/simple_animal/hostile/xcorp/scout = 20,
		/mob/living/simple_animal/hostile/xcorp/dps = 15,
		/mob/living/simple_animal/hostile/xcorp/tank = 10,
		/mob/living/simple_animal/hostile/xcorp/sapper = 8,
		/mob/living/simple_animal/hostile/xcorp/heart = 7,
		/mob/living/simple_animal/hostile/xcorp/heart/dps = 5,
		/mob/living/simple_animal/hostile/xcorp/heart/ranged = 4,
		/mob/living/simple_animal/hostile/xcorp/heart/pylon = 1
	)

/obj/effect/greed_gateway/Initialize()
	. = ..()
	if(length(SSgamedirector.fob_escape_shuttle))
		target_shuttle = pick(SSgamedirector.fob_escape_shuttle)
	// If no pre-calculated path was passed, schedule calculation for later (fallback)
	if(!length(assault_path) && target_shuttle)
		addtimer(CALLBACK(src, PROC_REF(CalculateFallbackPath)), 1)
	START_PROCESSING(SSobj, src)
	spawn_cooldown = world.time + 3 SECONDS // Initial delay

/obj/effect/greed_gateway/proc/CalculateFallbackPath()
	if(!target_shuttle)
		return
	assault_path = get_path_to(src, target_shuttle, /turf/proc/Distance_cardinal, 0, 400)
	if(!length(assault_path))
		log_game("WARNING: Greed Gateway at [x],[y],[z] could not find path to FoB escape shuttle")

/obj/effect/greed_gateway/Destroy()
	STOP_PROCESSING(SSobj, src)
	for(var/mob/living/simple_animal/hostile/M in spawned_mobs)
		if(!QDELETED(M))
			spawned_mobs -= M
	for(var/obj/effect/wave_commander/commander in active_waves)
		if(!QDELETED(commander))
			qdel(commander)
	return ..()

/obj/effect/greed_gateway/process()
	// Clean up dead/deleted mobs from tracking
	for(var/mob/living/simple_animal/hostile/M in spawned_mobs)
		if(QDELETED(M) || M.stat == DEAD)
			spawned_mobs -= M

	// Check if we can spawn more mobs
	if(world.time < spawn_cooldown)
		return

	if(length(spawned_mobs) >= max_spawned_mobs)
		return

	// Spawn new wave of mobs
	SpawnWave()
	spawn_cooldown = world.time + spawn_cooldown_time

/obj/effect/greed_gateway/proc/SpawnWave()
	var/spawn_count = rand(min_spawn_count, max_spawn_count)
	var/remaining_slots = max_spawned_mobs - length(spawned_mobs)
	spawn_count = min(spawn_count, remaining_slots)

	if(spawn_count <= 0)
		return

	var/list/spawn_turfs = list()
	// Get 3x3 area around gateway for spawning
	for(var/turf/T in range(1, src))
		if(!T.density)
			spawn_turfs += T

	if(!length(spawn_turfs))
		spawn_turfs += get_turf(src) // Fallback to gateway location

	// Create wave commander for this wave
	var/obj/effect/wave_commander/commander = new(get_turf(src))
	active_waves += commander
	RegisterSignal(commander, COMSIG_PARENT_QDELETING, PROC_REF(OnCommanderDeleted))

	var/list/current_wave = list()

	for(var/i in 1 to spawn_count)
		var/mob_type = pickweight(mob_spawn_weights)
		var/turf/spawn_turf = pick(spawn_turfs)

		var/mob/living/simple_animal/hostile/spawned = new mob_type(spawn_turf)
		spawned_mobs += spawned
		current_wave += spawned
		RegisterSignal(spawned, COMSIG_LIVING_DEATH, PROC_REF(OnMobDeath))

		// Make mob follow the wave commander
		walk_to(spawned, commander, rand(0,2), spawned.move_to_delay)

		// Visual effect for spawning
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(spawn_turf, pick(GLOB.alldirs))

	// Send the commander on its path if we have one
	if(length(assault_path))
		commander.DoPath(assault_path.Copy())
	else if(target_shuttle)
		// Fallback: if no path, at least try to move toward target
		var/list/simple_path = list(get_turf(target_shuttle))
		commander.DoPath(simple_path)

/obj/effect/greed_gateway/proc/OnMobDeath(mob/living/simple_animal/hostile/M)
	SIGNAL_HANDLER
	spawned_mobs -= M

/obj/effect/greed_gateway/proc/OnCommanderDeleted(obj/effect/wave_commander/commander)
	SIGNAL_HANDLER
	active_waves -= commander
