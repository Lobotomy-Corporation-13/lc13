// Faction Hub Landmarks
// Special trigger points for faction hub mechanics

// ============================================
// SPAWN LANDMARK
// ============================================

/**
 * Faction Hub Spawn Point
 *
 * Where players appear when they arrive at a faction hub.
 * Place this at the entrance/arrival area of your hub map.
 */
/obj/effect/landmark/faction_hub_spawn
	name = "hub spawn point"
	desc = "Players arriving at this faction hub will spawn here."
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x2"
	invisibility = INVISIBILITY_ABSTRACT
	/// The faction this spawn point belongs to
	var/faction_id = null
	/// Reference to the hub controller
	var/datum/faction_hub_controller/controller

/obj/effect/landmark/faction_hub_spawn/Initialize(mapload)
	. = ..()
	// Attempt to register with global hub controller
	if(faction_id)
		var/datum/faction_hub_controller/hub = get_faction_hub(faction_id)
		if(hub)
			hub.spawn_point = src
			controller = hub

// Faction-specific spawn points for easy mapping
/obj/effect/landmark/faction_hub_spawn/resurgence_clan
	name = "Resurgence Clan spawn point"
	faction_id = "resurgence_clan"

/obj/effect/landmark/faction_hub_spawn/jiajia_ren
	name = "Jiajia-ren Village spawn point"
	faction_id = "jiajia_ren"

/obj/effect/landmark/faction_hub_spawn/santata_factory
	name = "Santata Factory spawn point"
	faction_id = "santata_factory"

/obj/effect/landmark/faction_hub_spawn/cloud_town
	name = "Cloud Town spawn point"
	faction_id = "cloud_town"

/obj/effect/landmark/faction_hub_spawn/insurgence_clan
	name = "Insurgence Clan spawn point"
	faction_id = "insurgence_clan"

// ============================================
// EXIT LANDMARK
// ============================================

/**
 * Faction Hub Exit Point
 *
 * When players step on this, they can choose to leave the hub.
 * Opens a prompt to return to outpost or continue exploring.
 */
/obj/effect/landmark/faction_hub_exit
	name = "hub exit"
	desc = "Step here to leave the faction hub."
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x2"
	invisibility = INVISIBILITY_ABSTRACT
	/// The faction this exit belongs to
	var/faction_id = null
	/// Reference to the hub controller
	var/datum/faction_hub_controller/controller

/obj/effect/landmark/faction_hub_exit/Initialize(mapload)
	. = ..()
	if(faction_id)
		var/datum/faction_hub_controller/hub = get_faction_hub(faction_id)
		if(hub)
			hub.exit_point = src
			controller = hub

/obj/effect/landmark/faction_hub_exit/Crossed(atom/movable/AM)
	. = ..()
	if(!isliving(AM))
		return

	var/mob/living/L = AM
	prompt_exit(L)

/**
 * Prompt the player about leaving the hub
 */
/obj/effect/landmark/faction_hub_exit/proc/prompt_exit(mob/living/user)
	// Check if they're part of an expedition
	var/datum/expedition_party/expedition = null
	for(var/datum/expedition_party/P in GLOB.active_expeditions)
		if(user in P.members)
			expedition = P
			break

	if(!expedition)
		to_chat(user, span_warning("You're not part of an active expedition. You cannot leave this way."))
		return

	// Show exit prompt
	var/html = get_exit_html(user, expedition)
	user << browse(html, "window=hub_exit_[faction_id];size=400x300;can_close=1;can_minimize=0;can_maximize=0;can_resize=0;titlebar=1")

/**
 * Generate the exit prompt HTML
 */
/obj/effect/landmark/faction_hub_exit/proc/get_exit_html(mob/living/user, datum/expedition_party/expedition)
	var/faction_name = "this location"
	if(controller?.faction)
		faction_name = controller.faction.name

	var/html = {"
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>Leave [faction_name]</title>
	<style>
		body {
			font-family: Verdana, sans-serif;
			background-color: #1a1a2e;
			color: #eee;
			padding: 20px;
			margin: 0;
			text-align: center;
		}
		.title {
			font-size: 18px;
			font-weight: bold;
			color: #ffd700;
			margin-bottom: 20px;
		}
		.desc {
			font-size: 14px;
			margin-bottom: 25px;
			line-height: 1.5;
		}
		.btn {
			display: block;
			width: 80%;
			margin: 10px auto;
			padding: 12px 20px;
			font-size: 14px;
			font-weight: bold;
			text-decoration: none;
			border-radius: 5px;
			cursor: pointer;
		}
		.btn-return {
			background-color: #4CAF50;
			color: white;
		}
		.btn-return:hover {
			background-color: #45a049;
		}
		.btn-explore {
			background-color: #2196F3;
			color: white;
		}
		.btn-explore:hover {
			background-color: #1976D2;
		}
		.btn-stay {
			background-color: #555;
			color: #ccc;
		}
		.btn-stay:hover {
			background-color: #666;
		}
	</style>
</head>
<body>
	<div class="title">Leave [faction_name]?</div>
	<div class="desc">
		Choose your next destination.<br>
		You can return to the outpost or continue exploring the world.
	</div>

	<a class="btn btn-return" href="?src=[REF(src)];action=return">
		Return to Outpost
	</a>

	<a class="btn btn-explore" href="?src=[REF(src)];action=explore">
		Open World Map
	</a>

	<a class="btn btn-stay" href="?src=[REF(src)];action=stay">
		Stay Here
	</a>
</body>
</html>
"}
	return html

/**
 * Handle Topic calls from the exit prompt
 */
/obj/effect/landmark/faction_hub_exit/Topic(href, href_list)
	. = ..()
	if(.)
		return

	var/mob/living/user = usr
	if(!isliving(user))
		return

	// Close the window first
	user << browse(null, "window=hub_exit_[faction_id]")

	switch(href_list["action"])
		if("return")
			begin_return_to_outpost(user)
		if("explore")
			open_world_map(user)
		if("stay")
			to_chat(user, span_notice("You decide to stay a while longer."))

/**
 * Begin the journey back to the outpost
 */
/obj/effect/landmark/faction_hub_exit/proc/begin_return_to_outpost(mob/living/user)
	// Find their expedition
	var/datum/expedition_party/expedition = null
	for(var/datum/expedition_party/P in GLOB.active_expeditions)
		if(user in P.members)
			expedition = P
			break

	if(!expedition)
		to_chat(user, span_warning("You're not part of an active expedition!"))
		return

	// Notify hub controller
	if(controller)
		controller.player_departed(user)

	// Calculate route back to outpost
	if(!GLOB.resurgence_world_map)
		to_chat(user, span_warning("World map not available!"))
		return

	var/datum/world_tile/outpost_tile = GLOB.resurgence_world_map.outpost_tile
	if(!outpost_tile)
		to_chat(user, span_warning("Cannot find outpost location!"))
		return

	// Set new destination and route
	expedition.destination = outpost_tile
	expedition.route = GLOB.resurgence_world_map.find_path(expedition.current_tile, outpost_tile)

	if(!length(expedition.route))
		to_chat(user, span_warning("Cannot find a path back to the outpost!"))
		return

	// Start the journey back
	expedition.state = EXPEDITION_TRAVELING
	to_chat(user, span_notice("You begin the journey back to the outpost..."))

	// Use corridor manager to continue
	if(GLOB.expedition_corridor)
		GLOB.expedition_corridor.continue_expedition(expedition)

/**
 * Open the world map for the user to select a new destination
 */
/obj/effect/landmark/faction_hub_exit/proc/open_world_map(mob/living/user)
	// Find their expedition map device
	for(var/obj/item/expedition_map/device in user.contents)
		device.attack_self(user)
		return

	to_chat(user, span_warning("You need an expedition map device to view the world map."))

// Faction-specific exit points for easy mapping
/obj/effect/landmark/faction_hub_exit/resurgence_clan
	name = "Resurgence Clan exit"
	faction_id = "resurgence_clan"

/obj/effect/landmark/faction_hub_exit/jiajia_ren
	name = "Jiajia-ren Village exit"
	faction_id = "jiajia_ren"

/obj/effect/landmark/faction_hub_exit/santata_factory
	name = "Santata Factory exit"
	faction_id = "santata_factory"

/obj/effect/landmark/faction_hub_exit/cloud_town
	name = "Cloud Town exit"
	faction_id = "cloud_town"

/obj/effect/landmark/faction_hub_exit/insurgence_clan
	name = "Insurgence Clan exit"
	faction_id = "insurgence_clan"

// ============================================
// TRADER SPAWN LANDMARK
// ============================================

/**
 * Trader Spawn Point
 *
 * Place this where you want the faction trader NPC to spawn.
 * The trader type is determined by the faction_id.
 */
/obj/effect/landmark/faction_trader_spawn
	name = "trader spawn point"
	desc = "A faction trader will spawn here."
	icon = 'icons/effects/landmarks_static.dmi'
	icon_state = "x2"
	invisibility = INVISIBILITY_ABSTRACT
	/// The faction this trader belongs to
	var/faction_id = null

/obj/effect/landmark/faction_trader_spawn/Initialize(mapload)
	. = ..()
	if(faction_id)
		spawn_trader()
	return INITIALIZE_HINT_QDEL  // Delete landmark after spawning trader

/**
 * Spawn the appropriate trader NPC
 */
/obj/effect/landmark/faction_trader_spawn/proc/spawn_trader()
	var/trader_type
	switch(faction_id)
		if("resurgence_clan")
			trader_type = /mob/living/simple_animal/faction_trader/resurgence_clan
		if("jiajia_ren")
			trader_type = /mob/living/simple_animal/faction_trader/jiajia_ren
		if("santata_factory")
			trader_type = /mob/living/simple_animal/faction_trader/santata_factory
		if("cloud_town")
			trader_type = /mob/living/simple_animal/faction_trader/cloud_town
		else
			trader_type = /mob/living/simple_animal/faction_trader

	new trader_type(get_turf(src))

// Faction-specific trader spawns for easy mapping
/obj/effect/landmark/faction_trader_spawn/resurgence_clan
	name = "Resurgence Clan trader spawn"
	faction_id = "resurgence_clan"

/obj/effect/landmark/faction_trader_spawn/jiajia_ren
	name = "Jiajia-ren trader spawn"
	faction_id = "jiajia_ren"

/obj/effect/landmark/faction_trader_spawn/santata_factory
	name = "Santata Factory trader spawn"
	faction_id = "santata_factory"

/obj/effect/landmark/faction_trader_spawn/cloud_town
	name = "Cloud Town trader spawn"
	faction_id = "cloud_town"
