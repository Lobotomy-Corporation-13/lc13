/obj/effect/landmark/rce_fob
	name = "RCE FOB"

/obj/effect/landmark/rce_fob/Initialize()
	. = ..()
	SSgamedirector.RegisterFOB(src)
	// Also register as a raid spot for FoB entrance raids
	if(!SSgamedirector.raid_spots["fob_entrance"])
		SSgamedirector.raid_spots["fob_entrance"] = list()
	SSgamedirector.raid_spots["fob_entrance"] += src

/obj/effect/landmark/rce_arena_teleport
	name = "Combatant Lobby Warp"

/obj/effect/landmark/rce_arena_teleport/Initialize()
	. = ..()
	SSgamedirector.RegisterLobby(src)

/obj/effect/landmark/rce_postfight_teleport
	name = "Heart Victory Warp"

/obj/effect/landmark/rce_postfight_teleport/Initialize()
	. = ..()
	SSgamedirector.RegisterVictoryTeleport(src)

/obj/effect/landmark/heartfight_pylon
	name = "Heart Fight Pylon marker"

/obj/effect/landmark/heartfight_pylon/Initialize()
	. = ..()
	SSgamedirector.RegisterHeartfightPylon(src)

/obj/effect/landmark/rce_target
	name = "X-Corp Attack Target"
	var/id
	var/landmark_type = RCE_TARGET_TYPE_GENERIC

/obj/effect/landmark/rce_target/Initialize(mapload)
	..()
	GLOB.rce_targets += get_turf(src)
	if(id)
		SSgamedirector.RegisterTarget(src, landmark_type, id)
	else
		SSgamedirector.RegisterTarget(src, landmark_type)

/obj/effect/landmark/rce_target/fob_entrance
	landmark_type = RCE_TARGET_TYPE_FOB_ENTRANCE

/obj/effect/landmark/rce_target/low_level
	landmark_type = RCE_TARGET_TYPE_LOW_LEVEL

/obj/effect/landmark/rce_target/mid_level
	landmark_type = RCE_TARGET_TYPE_MID_LEVEL

/obj/effect/landmark/clan_raid_spot
	name = "Clan Raid Spot"
	var/id = ""	//ID to match with resourcewell

/obj/effect/landmark/clan_raid_spot/Initialize()
	. = ..()
	SSgamedirector.RegisterRaidSpot(src)

// Specific clan raid spots for each resource well type
/obj/effect/landmark/clan_raid_spot/green
	name = "Clan Raid Spot (Green)"
	id = "green"

/obj/effect/landmark/clan_raid_spot/red
	name = "Clan Raid Spot (Red)"
	id = "red"

/obj/effect/landmark/clan_raid_spot/blue
	name = "Clan Raid Spot (Blue)"
	id = "blue"

/obj/effect/landmark/clan_raid_spot/purple
	name = "Clan Raid Spot (Purple)"
	id = "purple"

/obj/effect/landmark/clan_raid_spot/orange
	name = "Clan Raid Spot (Orange)"
	id = "orange"

/obj/effect/landmark/clan_raid_spot/silver
	name = "Clan Raid Spot (Silver)"
	id = "silver"

/obj/effect/landmark/clan_raid_spot/fob_entrance
	name = "FoB Entrance Raid Spot"
	id = "fob_entrance"

/obj/effect/landmark/rce_target/high_level
	landmark_type = RCE_TARGET_TYPE_HIGH_LEVEL

/obj/effect/landmark/rce_target/xcorp_base
	landmark_type = RCE_TARGET_TYPE_XCORP_BASE

/obj/effect/landmark/rce_spawn/xcorp_heart
	name = "xcorp heart spawn"

/obj/effect/landmark/rce_spawn/xcorp_heart/Initialize(mapload)
	..()
	new /mob/living/simple_animal/hostile/megafauna/xcorp_heart(get_turf(src))

// Last Wave Gateway Landmarks
/obj/effect/landmark/lastwave_gateway
	name = "Last Wave Gateway Spawn"
	icon_state = "x"
	var/gateway_type = GATEWAY_TYPE_AIR
	var/list/assault_path = list()

/obj/effect/landmark/lastwave_gateway/Initialize()
	. = ..()
	SSgamedirector.RegisterGatewaySpawn(src)
	// Calculate path for gateway-type landmarks
	if(gateway_type == GATEWAY_TYPE_GATEWAY)
		addtimer(CALLBACK(src, PROC_REF(CalculatePath)), 1)

/obj/effect/landmark/lastwave_gateway/proc/CalculatePath()
	// Find the FoB escape shuttle to path to
	if(length(SSgamedirector.fob_escape_shuttle))
		var/obj/effect/landmark/fob_escape_shuttle/target = pick(SSgamedirector.fob_escape_shuttle)
		assault_path = get_path_to(src, target, /turf/proc/Distance_cardinal, 0, 400)
		if(!length(assault_path))
			log_game("WARNING: Gateway landmark at [x],[y],[z] could not find path to FoB escape shuttle")

/obj/effect/landmark/lastwave_gateway/air
	name = "Last Wave Gateway Spawn (Air)"
	gateway_type = GATEWAY_TYPE_AIR

/obj/effect/landmark/lastwave_gateway/wall
	name = "Last Wave Gateway Spawn (Wall)"
	gateway_type = GATEWAY_TYPE_WALL

/obj/effect/landmark/lastwave_gateway/gateway
	name = "Last Wave Gateway Spawn (Gateway)"
	gateway_type = GATEWAY_TYPE_GATEWAY
	icon_state = "x4"

/obj/effect/landmark/fob_escape_shuttle
	name = "FoB Escape Shuttle"
	icon_state = "abno_room"

/obj/effect/landmark/fob_escape_shuttle/Initialize()
	. = ..()
	SSgamedirector.RegisterEscapeShuttle(src)
