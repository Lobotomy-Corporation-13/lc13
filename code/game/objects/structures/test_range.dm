// EGO Printer
// This machine is heavily linked to the Test Range subsystem. Take a look at it if reading or editing this code.
/obj/machinery/ego_printer
	name = "E.G.O. printer"
	desc = "This device is capable of printing most E.G.O. on demand. It can even replicate non-E.G.O. armaments from the City at large. \n\
	You may alt-click this machine to change between the new and old interfaces for printing E.G.O. \n\
	You may also insert any unwanted item into this machine to shred it."
	icon = 'icons/obj/machines/droneDispenser.dmi'
	icon_state = "on"
	resistance_flags = INDESTRUCTIBLE
	/// A list of instantiated ego datums this printer can vend. NEVER delete this as it can be a reference to SStestrange's list. This var is here so you can make custom lists of datums for other printers
	var/list/ego_datums = list()
	/// Only the EGO paths, for the old version of the interface. No relevance to the TGUI interface.
	var/list/ego_datum_paths = list()
	/// This var limits how much EGO each ckey can print before having to get rid of some. Specific to each printer.
	var/ego_per_person_limit = 15
	/// Associates ckey to printed EGO references.
	var/list/printed_ego = list()
	/// Holds ckeys that have disabled the new TGUI version of the interface.
	var/list/disabled_tgui = list()
	/// Anything in this list will be rejected if you try to shred it in the EGO printer.
	// As of Test Range Update 2, you can now print Attribute Injectors & Scrying Orbs, so there's nothing to put in this blacklist ATM
	var/static/blacklisted_shred_items = list()

/* ---------- Shared TGUI/Old EGO printer stuff ---------- */

/obj/machinery/ego_printer/Initialize(mapload)
	. = ..()
	SStestrange.linked_ego_printers += src
	if(SStestrange.ego_datums_initialized) // If we're being created after datums were already initialized, then pull the ego datum lists
		ego_datums = SStestrange.ego_datums
		ego_datum_paths = SStestrange.ego_datum_paths

/// Alt clicking the printer swaps between new and old interfaces.
// Temporary; we can make this a Pref later if we ever update the real EGO purchase console to use TGUI
/obj/machinery/ego_printer/AltClick(mob/user)
	disabled_tgui ^= user.ckey // Allegedly this is an XOR operator which should "toggle" the value
	to_chat(user, span_notice("Toggled interface type for EGO printer."))
	balloon_alert(user, "Toggled interface type for EGO printer.")

/obj/machinery/ego_printer/Destroy(force)
	SStestrange.linked_ego_printers -= src
	return ..()

/// We use this to bounce attempts to access the printer before it's assembled the full list of EGO datums.
/obj/machinery/ego_printer/proc/CheckInitializedDatums(mob/living/user)
	if(SStestrange.ego_datums_initializing || !(SStestrange.ego_datums_initialized))
		var/not_ready_message = "System is still initializing. Please wait. [SStestrange.ego_datums ? length(SStestrange.ego_datums) : "0"] E.G.O. currently loaded."
		if(istype(user) && user.stat < DEAD)
			say(not_ready_message)
			playsound(get_turf(src), 'sound/machines/synth_no.ogg', 40, TRUE)
		else
			to_chat(user, span_warning(not_ready_message))
		return FALSE
	return TRUE

/// SStestrange calls this on all its linked printers when it finishes loading EGO datums to warn players that it's ready for operation
/obj/machinery/ego_printer/proc/ReadyMessage()
	visible_message(span_nicegreen("The [src.name] beeps, now displaying a list of E.G.O. ready to print."))
	say("System initialization complete!")
	playsound(get_turf(src), 'sound/machines/terminal_success.ogg', 40, TRUE)

/// Let someone qdel items by hitting this machine with it. It's this specific override and ..() happens at the end so we can bypass attribute requirements.
// I'm letting people qdel any item here, I swear if people start abusing this.........................................................
/obj/machinery/ego_printer/attackby(obj/item/I, mob/living/user, params)
	if(!(I.type in blacklisted_shred_items))
		to_chat(user, span_danger("You begin inserting [I] into a dangerous-looking compartment in the machine..."))
		if(do_after(user, 1 SECONDS, src, interaction_key = "ego_printer_shred", max_interact_count = 1))
			visible_message(span_warning("The [src.name] makes a concerning sound as [user] inserts [I] into it."))
			playsound(get_turf(src), 'sound/machines/juicer.ogg', 20, TRUE)
			qdel(I) // Its removal from the user's printed ego list is handled by a signal.
			return
		else
			to_chat(user, span_warning("You decide not to destroy [I]."))
	. = ..()

/// If the user isn't at the limit of printed EGO, print whatever ego_path is (this could be literally anything but is hopefully an /obj/item)
/obj/machinery/ego_printer/proc/DispenseEgo(mob/living/user, ego_path)
	if(!ego_path)
		return

	var/user_prints = printed_ego[user.ckey]

	// Firstly, don't allow users to print too much EGO. This is just spam prevention since now it is very easy to spawn 50000000000 chaos dunks which could cause [A Bit] of lag
	if(islist(user_prints))
		var/list/thats_a_lot_of_ego = user_prints

		// Clean up the user's deleted EGO from its list. I know having a bunch of ghost references in their list is iffy but the alternative is attaching a signal to everything we print to remove it from the list as it gets qdeleted...
		for(var/atom/thing in thats_a_lot_of_ego)
			if(QDELETED(thing))
				thats_a_lot_of_ego -= thing

		if(length(thats_a_lot_of_ego) >= ego_per_person_limit)
			to_chat(user, span_warning("You've printed too much E.G.O. gear. Place some back into the printer."))
			playsound(src, 'sound/machines/buzz-two.ogg', 50)
			return

	var/atom/dispensed_item = new ego_path((get_turf(user)))

	if(istype(dispensed_item)) // Could register signals on it or whatever if you need to here
		RegisterSignal(dispensed_item, COMSIG_PARENT_QDELETING, PROC_REF(CleanupPrintedEgo))
		visible_message(span_nicegreen("The [src.name] beeps as it prints [dispensed_item] for [user]."))
		playsound(get_turf(src), 'sound/machines/ping.ogg', 50, TRUE)
		if(islist(user_prints))
			user_prints |= dispensed_item
		else
			printed_ego[user.ckey] = list(dispensed_item)
		return

	to_chat(user, span_warning("Something's gone horribly wrong with the E.G.O. printing process... contact a coder and tell them [ego_path] is bugged on the testing range printer."))
	playsound(src, 'sound/machines/buzz-two.ogg', 50)

/// Called by an EGO we printed and previously registered into a player's printed EGO list, when it is being deleted. This is so we don't have a buncha qdeleted stuff sitting in a list.
/obj/machinery/ego_printer/proc/CleanupPrintedEgo(datum/source)
	SIGNAL_HANDLER
	for(var/ckey in printed_ego)
		if(source in printed_ego[ckey])
			printed_ego[ckey] -= source
			break
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)
	return

/* ---------- TGUI EGO Printer stuff ---------- */

// Happens when someone touches this machine with their bare hand.
/obj/machinery/ego_printer/ui_interact(mob/user, datum/tgui/ui)
	if(!CheckInitializedDatums(user))
		return

	if((user.ckey in disabled_tgui))
		INVOKE_ASYNC(src, PROC_REF(ShowOldInterface), user)
		return

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TestRangeEgoPrinter", "E.G.O. Printer")
		ui.set_autoupdate(FALSE)
		ui.open()

// Static data because we really don't expect the EGO datums for this to dynamically change.
/obj/machinery/ego_printer/ui_static_data(mob/user)
	var/list/data = list()
	data["ego_weapon_datums"] = list()
	data["ego_armor_datums"] = list()
	data["ego_auxiliary_datums"] = list()
	data["all_tags"] = list()

	// Get all the EGO tags defined in EGO_TAGS_DESCRIPTION_LIST and send an object consisting of their name and description, also tag_checked so we can easily turn their filtering on and off in the frontend
	for(var/tag in EGO_TAGS_DESCRIPTION_LIST)
		var/list/tag_object = list("tag_name" = tag, "tag_description" = EGO_TAGS_DESCRIPTION_LIST[tag], "tag_checked" = FALSE)
		data["all_tags"] |= list(tag_object)

	for(var/datum/ego_datum/ED in ego_datums)
		if(!ED.item_path)
			continue

		var/ego_threatclass = ED.CostToThreatClass()
		var/ego_tags = ED.ego_tags
		if(!islist(ego_tags))
			ego_tags = list(ego_tags)

		var/list/datum_data = list(
			"path" = ED.item_path,
			"cost" = ED.cost,
			"information" = ED.information,
			"tags" = ED.ego_tags,
			"icon" = SStestrange.GenerateEgoPreviewIcon(ED.item_path),
			"threatclass" = ego_threatclass,
			"origin" = ED.origin
		)
		if(istype(ED, /datum/ego_datum/weapon))
			data["ego_weapon_datums"] |= list(datum_data)
		else if(istype(ED, /datum/ego_datum/armor))
			data["ego_armor_datums"] |= list(datum_data)
		else if(istype(ED, /datum/ego_datum/auxiliary))
			datum_data["category"] = ED.item_category
			data["ego_auxiliary_datums"] |= list(datum_data)

	return data

// The frontend calls this with a certain action and payload.
/obj/machinery/ego_printer/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	if(action == "print_ego")
		var/chosen_ego = params["chosen_ego"]
		DispenseEgo(usr, chosen_ego)
		update_icon()
		return FALSE // I know this looks EXTREMELY suspect but I don't want the UI to update when you do this. Else, it resets the scrolling position on the ego list.

/* ---------- Old EGO Printer stuff ---------- */

/// Not 1:1 to old logic, we use the new version of the ego datum list and rip the paths out of it, also uses the new dispense proc.
/obj/machinery/ego_printer/proc/ShowOldInterface(mob/living/user)
	var/list/ego_list = ego_datum_paths

	user.playsound_local(user, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
	var/chosen_ego = tgui_input_list(user,"Which EGO do you want to print","Select EGO", ego_list)
	if((!chosen_ego))
		user.playsound_local(user, 'sound/machines/terminal_error.ogg', 50, FALSE)
		to_chat(user, span_warning("No EGO was specified."))
		return
	DispenseEgo(user, chosen_ego)

/*
* ABNORMALITY SPAWNER
*
*
*
*/
/obj/machinery/computer/testrangespawner
	name = "Threat Simulator"
	desc = "This device is used to spawn hostiles to fight against."
	resistance_flags = INDESTRUCTIBLE
	// Holds the string corresponding to the arena we're currently using. Randomly set by SStestrange on its Initialize.
	var/current_arena
	var/arena_change_cooldown_duration = 5 SECONDS
	var/arena_change_cooldown

	// Camera implementation studied and 'borrowed' from CentcomPodLauncher and CameraConsole.
	// Stuff needed to render the map
	var/map_name
	var/atom/movable/screen/map_view/cam_screen
	/// All the plane masters that need to be applied.
	var/list/cam_plane_masters
	var/atom/movable/screen/background/cam_background
	var/camera_range = 15

/obj/machinery/computer/testrangespawner/Initialize(mapload)
	. = ..()
	SStestrange.linked_threat_simulators += src // Important: This happens before SStestrange initializes, at least for the instances of this type already on the map.

// Tell the players to shove off if we're not done initializing yet
/obj/machinery/computer/testrangespawner/proc/CheckInitializedDatums(mob/living/user)
	if(SStestrange.threat_datums_initializing || !(SStestrange.threat_datums_initialized))
		var/not_ready_message = "System is still initializing. Please wait. [SStestrange.test_range_threat_datums ? length(SStestrange.test_range_threat_datums) : "0"] threats currently loaded."
		if(istype(user) && user.stat < DEAD)
			say(not_ready_message)
			playsound(get_turf(src), 'sound/machines/synth_no.ogg', 40, TRUE)
		else
			to_chat(user, span_warning(not_ready_message))
		return FALSE
	return TRUE

// Sets up camera feed to the arena.
/obj/machinery/computer/testrangespawner/proc/InitializeCamera()
	map_name = "testrangespawner_[REF(src)]_map"

	cam_screen = new
	cam_screen.name = "screen"
	cam_screen.assigned_map = map_name
	cam_screen.del_on_map_removal = FALSE
	cam_screen.screen_loc = "[map_name]:1,1"
	cam_plane_masters = list()

	for(var/plane in subtypesof(/atom/movable/screen/plane_master))
		var/atom/movable/screen/instance = new plane()
		instance.assigned_map = map_name
		instance.del_on_map_removal = FALSE
		instance.screen_loc = "[map_name]:CENTER"
		cam_plane_masters += instance

	cam_background = new
	cam_background.assigned_map = map_name
	cam_background.del_on_map_removal = FALSE

	UpdateCameraView()

// Called every time we need to update our arena camfeed.
/obj/machinery/computer/testrangespawner/proc/UpdateCameraView()
	var/list/visible_turfs = list()

	var/obj/effect/landmark/test_range_arena/landmark_thingy = SStestrange.test_range_arenas[current_arena]
	var/turf/camera_center = get_turf(landmark_thingy)
	var/x_offset = landmark_thingy.camera_offset["x"]
	var/y_offset = landmark_thingy.camera_offset["y"]
	camera_center = locate((camera_center.x + x_offset), (camera_center.y + y_offset), (camera_center.z))

	var/list/visible_things = range(camera_range, camera_center)

	for(var/turf/visible_turf in visible_things)
		visible_turfs += visible_turf

	var/list/bbox = get_bbox_of_atoms(visible_turfs)
	var/size_x = bbox[3] - bbox[1] + 1
	var/size_y = bbox[4] - bbox[2] + 1

	cam_screen.vis_contents = visible_turfs
	cam_background.icon_state = "clear"
	cam_background.fill_rect(1, 1, size_x, size_y)

/obj/machinery/computer/testrangespawner/ui_interact(mob/user, datum/tgui/ui)
	if(!CheckInitializedDatums(user))
		return

	UpdateCameraView()

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		user.client.register_map_obj(cam_screen)
		for(var/plane in cam_plane_masters)
			user.client.register_map_obj(plane)
		user.client.register_map_obj(cam_background)

		ui = new(user, src, "TestRangeThreatSimulator", "Threat Simulator")
		ui.set_autoupdate(FALSE)
		ui.open()

// Dynamic data sent to TGUI.
/obj/machinery/computer/testrangespawner/ui_data(mob/user)
	var/list/data = list()
	data["threats"] = list() // The only reason this is dynamic is because current_spawns can change. In theory I can probably find a way to separate it, and make this static data?
	data["current_arena"] = current_arena

	for(var/datum/test_range_threat/TD in SStestrange.test_range_threat_datums)
		var/list/datum_data = list(
			"name" = TD.name,
			"icon" = SStestrange.GenerateThreatPreviewIcon(TD), // This is cached
			"desc" = TD.desc,
			"origin" = TD.origin,
			"origin_detailed" = TD.origin_detailed,
			"battle_guide" = TD.battle_guide,
			"difficulty" = TD.estimated_difficulty,
			"mob_path" = TD.mob_path,
			"current_spawns" = length(TD.currently_spawned),
			"max_spawns" = TD.max_spawns,
			"tuning_name" = TD.tuning_name,
			"tuning_min" = TD.tuning_min,
			"tuning_limit" = TD.tuning_limit,
			"reference" = REF(TD)
			)

		data["threats"] += list(datum_data)
	return data

// Unchanging data sent to TGUI. I mean, they CAN change if admins mess with them, but they really shouldn't
/obj/machinery/computer/testrangespawner/ui_static_data(mob/user)
	var/list/data = list()
	data["map_ref"] = map_name
	data["arenas"] = list()
	for(var/A in SStestrange.test_range_arenas)
		data["arenas"] += A

	return data

/obj/machinery/computer/testrangespawner/proc/ArenaChangeReady()
	if(arena_change_cooldown > world.time)
		to_chat(usr, span_danger("Arena switching is on cooldown. Wait a few seconds and try again."))
		playsound(get_turf(src), 'sound/machines/synth_no.ogg', 40, TRUE)
		return FALSE

	return TRUE

/obj/machinery/computer/testrangespawner/ui_act(action, list/params)
	. = ..()
	if(.)
		return

	var/mob/living/user = usr

	if(action == "spawn_threat")
		var/chosen_threat = params["chosen_threat"]
		var/tuning = params["tuning"]
		var/datum/test_range_threat/found_datum = locate(chosen_threat) in SStestrange.test_range_threat_datums
		if(found_datum && istype(found_datum))
			SpawnThreat(found_datum, SStestrange.test_range_arenas[current_arena], tuning)
		return TRUE

	if(action == "change_camera")
		var/chosen_arena = params["arena"]
		if(!chosen_arena)
			return FALSE
		var/obj/effect/landmark/test_range_arena/TRA = SStestrange.test_range_arenas[chosen_arena]
		if(!TRA)
			return FALSE

		if(!ArenaChangeReady())
			return FALSE
		current_arena = chosen_arena


		var/obj/machinery/quantumpad/warp/lobby_pad = SStestrange.test_range_telepads["lobby"]
		lobby_pad.linked_pad = SStestrange.test_range_telepads[current_arena]

		arena_change_cooldown = arena_change_cooldown_duration + world.time

		UpdateCameraView()
		return TRUE

	if(action == "despawn_one")
		var/chosen_threat = params["chosen_threat"]
		var/datum/test_range_threat/found_datum = locate(chosen_threat) in SStestrange.test_range_threat_datums
		if(found_datum && istype(found_datum))
			if(found_datum.DespawnOne())
				say("[user] ([user.ckey]) despawned 1 instance of [found_datum.name].")
				playsound(get_turf(src), 'sound/machines/terminal_success.ogg', 40, FALSE)
			else
				say("Error: there are no instances of [found_datum.name] to despawn.")
				playsound(get_turf(src), 'sound/machines/terminal_prompt_deny.ogg', 40, FALSE)
		return TRUE

	if(action == "despawn_all") // Refers to despawning all of a certain type of threat, not all threats ever spawned by this machine.
		var/chosen_threat = params["chosen_threat"]
		var/datum/test_range_threat/found_datum = locate(chosen_threat) in SStestrange.test_range_threat_datums
		if(found_datum && istype(found_datum))
			found_datum.DespawnAll()
			say("[user] ([user.ckey]) despawned ALL [found_datum.name] instances.")
			playsound(get_turf(src), 'sound/machines/triple_beep.ogg', 40, FALSE)
		return TRUE

// Most logic for actual spawning of threats is handled in test_range_threat's procs.
/obj/machinery/computer/testrangespawner/proc/SpawnThreat(datum/test_range_threat/most_perilous_challenge, obj/effect/landmark/test_range_arena/arena, list/tuning)
	if(!istype(most_perilous_challenge) || !istype(arena))
		return
	var/turf/T = get_turf(arena)
	var/mob/living/user = usr

	if(most_perilous_challenge.Start(T, tuning))
		say("[user] ([user.ckey]) spawned [most_perilous_challenge.name] in the [arena.arena_name] Arena.")
		// Maybe add logging for this? Not sure
		playsound(get_turf(src), 'sound/machines/terminal_success.ogg', 40, FALSE)
	else
		say("Failed to spawn [most_perilous_challenge.name]!")
		playsound(get_turf(src), 'sound/machines/triple_beep.ogg', 40, FALSE)


/*
* TEST RANGE SLEEPER (SPAWN POINT)
* This thing is actually defined in \code\game\objects\structures\ghost_role_spawners.dm
* We just need to override the spawning process to add a few signals to our test range agents.
* Also a couple signal handler procs.
*/

/obj/effect/mob_spawn/human/testrange/equip(mob/living/carbon/human/H)
	. = ..()
	SStestrange.test_range_agents |= H
	RegisterSignal(H, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING), PROC_REF(ProcessAgentDeath))
	RegisterSignal(H, COMSIG_HUMAN_INSANE, PROC_REF(MurderInsanityProtection)) // We don't want fort insanes in the lobby

// Might as well put the signal handler procs here for clarity.
/obj/effect/mob_spawn/human/testrange/proc/ProcessAgentDeath(mob/living/carbon/human/dead_test_range_agent)
	SIGNAL_HANDLER
	UnregisterSignal(dead_test_range_agent, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING, COMSIG_HUMAN_INSANE, COMSIG_ENTER_AREA))
	SStestrange.test_range_agents -= dead_test_range_agent
	SStestrange.CleanupCheck() // Check to see if this was the last living Test Range Agent.

// When someone goes insane, if they go murder insane/jekyll insane, check their area. If it's the lobby, kill them instantly. If it's not, add a signal that checks for them changing area, and then kill them if they enter the lobby.
/obj/effect/mob_spawn/human/testrange/proc/MurderInsanityProtection(mob/living/carbon/human/insane_agent, attribute)
	SIGNAL_HANDLER
	if(!(attribute == FORTITUDE_ATTRIBUTE || (insane_agent.has_status_effect(/datum/status_effect/display/hyde)) || (insane_agent.has_status_effect(/datum/status_effect/display/dr_jekyll))))
		return
	var/area/agent_area = get_area(insane_agent)
	if(!istype(agent_area, /area/test_range_arena))
		QDEL_NULL(insane_agent.ai_controller)
		addtimer(CALLBACK(SStestrange, TYPE_PROC_REF(/datum/controller/subsystem/testrange, Despawn), insane_agent), rand(5, 10))
	else
		RegisterSignal(insane_agent, COMSIG_ENTER_AREA, PROC_REF(AreaCheck))

// Kills the insane person we're listening to if they enter the test range lobby.
/obj/effect/mob_spawn/human/testrange/proc/AreaCheck(mob/living/soon_to_be_ded, area/entered_area)
	SIGNAL_HANDLER
	if(istype(entered_area, /area/test_range_arena))
		return
	QDEL_NULL(soon_to_be_ded.ai_controller)
	SStestrange.Despawn(soon_to_be_ded)

/*
* TEST RANGE LANDMARK (SPAWN POINT)
* Supplies the name for the arena, as well as the camera viewpoint and the mob spawn location.
*
*
*/

/obj/effect/landmark/test_range_arena
	name = "Test Range Arena"
	var/arena_name = "Placeholder Arena Name"
	var/camera_offset = list("x" = 0, "y" = 0)

/obj/effect/landmark/test_range_arena/Initialize(mapload)
	. = ..()
	SStestrange.test_range_arenas[arena_name] = src

/*
* TEST RANGE CLEANER (BUTTON)
* Spawns a /obj/effect/test_range_cleaner to sweep up garbage in the lobby/arenas.
*
*
*/
/obj/machinery/button/indestructible/test_range_cleanup
	name = "Test Range Cleaner"
	desc = "A small button labeled \"cl e a n\". You suppose it will clean the room. \n\
	Alt-click to disable animation."
	var/cooldown
	var/cooldown_duration = 15 SECONDS
	var/fancy = TRUE
	var/cleaning_radius = 20

/obj/machinery/button/indestructible/test_range_cleanup/AltClick(mob/user)
	. = ..()
	fancy = !fancy
	to_chat(user, fancy ? span_notice("[src] will now play an animation.") : span_notice("[src] will no longer play an animation."))

/obj/machinery/button/indestructible/test_range_cleanup/attack_hand(mob/user)
	if(cooldown > world.time)
		to_chat(user, span_danger("The Janitor is resting. Wait a moment and try again."))
		return
	. = ..()
	cooldown = cooldown_duration + world.time
	new /obj/effect/test_range_cleaner(get_turf(user), fancy, cleaning_radius, TRUE)

/*
* TEST RANGE SLEEPER (EFFECT)
* Can actually be spawned independently if you want.
* Will delete EVERYTHING that matches one of things_to_remove in the area&radius it spawns in.
* Also deletes dead living mobs.
*/
/obj/effect/test_range_cleaner
	name = "The Janitor"
	desc = "!!!! OVERWHELMED !!!!"
	icon = 'icons/mob/aibots.dmi'
	icon_state = "cleanbot0"
	alpha = 0
	pixel_z = 256
	movement_type = PHASING | FLYING
	var/area/area_to_clean
	var/list/turfs_to_check = list()
	var/radius = 20
	var/list/things_to_remove = list(
		/obj/effect/decal/cleanable,
		/obj/item/bodypart,
		/obj/item/organ,
		/obj/item/ego_weapon,
		/obj/item/clothing,
		/obj/item/storage/backpack,
		/obj/item/card,
		/obj/item/radio,
		/obj/item/pda,
		/obj/item/stack/thumb_east_ammo,
		/obj/item/ammo_casing,
		/obj/structure/abno_core,
		/obj/structure/meatfloor,
		/obj/structure/barricade/meatbags,
		/obj/item/food/meat/slab,
	)

/obj/effect/test_range_cleaner/Initialize(mapload, fancy = TRUE, radius_override, being_used_in_test_range = FALSE)
	. = ..()
	if(radius_override && radius_override > 0)
		src.radius = radius_override

	var/turf/own_turf = get_turf(src)
	if(!own_turf)
		qdel(src)
		return

	area_to_clean = get_area(own_turf)
	if(!area_to_clean)
		qdel(src)
		return

	for(var/turf/T in RANGE_TURFS(radius, own_turf))
		if(!(get_area(T) == area_to_clean))
			continue
		turfs_to_check |= T

	// Play an animation if 'fancy' is TRUE.
	if(fancy)
		transform *= 2
		playsound(get_turf(src), 'sound/magic/clockwork/invoke_general.ogg', 50, TRUE)
		RegisterSignal(src, COMSIG_MOVABLE_MOVED, PROC_REF(MovementEffect))
		animate(src, time = 1.2 SECONDS, alpha = 255, pixel_z = 0, easing = QUAD_EASING)
		addtimer(CALLBACK(src, PROC_REF(DoCleaningAnimation)), 1.6 SECONDS)
	// Or just instantly clean things around us.
	else
		ActuallyClean()

/obj/effect/test_range_cleaner/Destroy(force)
	area_to_clean = null
	turfs_to_check = null
	things_to_remove = null
	return ..()

// Entirely scripted animation. Will early cancel and just do a fast cleanup if we're using this somewhere weird that would cause an error.
/obj/effect/test_range_cleaner/proc/DoCleaningAnimation()
	var/turf/T1 = get_ranged_target_turf(src, SOUTHWEST, radius*0.4)
	if(!T1)
		ActuallyClean()
		return
	var/turf/T2 = get_ranged_target_turf(T1, EAST, radius*0.5)
	if(!T2)
		ActuallyClean()
		return
	var/turf/T3 = get_ranged_target_turf(T2, NORTHWEST, radius*0.4)
	if(!T3)
		ActuallyClean()
		return
	var/turf/T4 = get_ranged_target_turf(T3, NORTHEAST, radius*0.3)
	if(!T4)
		ActuallyClean()
		return
	var/turf/T5 = get_ranged_target_turf(T4, SOUTH, radius*0.8)
	if(!T5)
		ActuallyClean()
		return

	setDir(SOUTHWEST)
	walk_towards(src, T1, 0)
	sleep(5)
	setDir(EAST)
	walk_towards(src, T2, 0)
	sleep(6)
	setDir(NORTHWEST)
	walk_towards(src, T3, 0)
	sleep(5)
	setDir(NORTHEAST)
	walk_towards(src, T4, 0)
	sleep(4)
	setDir(SOUTH)
	walk_towards(src, T5, 0)
	sleep(13)
	walk(src, 0)
	animate(src, time = 1.2 SECONDS, pixel_z = 256, alpha = 0)

	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
	addtimer(CALLBACK(src, PROC_REF(ActuallyClean)), 0.2 SECONDS)

// Actually takes care of removing anything found in turfs_to_check that has a type which is included in the things_to_remove list.
/obj/effect/test_range_cleaner/proc/ActuallyClean()
	for(var/turf/T in turfs_to_check)
		for(var/atom/thing in T)
			if(isliving(thing))
				var/mob/living/this_is_a_mob = thing
				if(this_is_a_mob.stat >= DEAD)
					qdel(this_is_a_mob)
					continue
			for(var/type_of_thing in things_to_remove)
				if(istype(thing, type_of_thing))
					qdel(thing)
					break

	qdel(src)

// Funny little effects for when the animation happens.
/obj/effect/test_range_cleaner/proc/MovementEffect(datum/source, OldLoc, Dir, Forced)
	SIGNAL_HANDLER
	var/obj/effect/test_range_cleaner/owner = source
	if(!istype(owner))
		return
	var/obj/effect/temp_visual/decoy/D = new /obj/effect/temp_visual/decoy(OldLoc, owner)
	D.alpha = 190
	animate(D, alpha = 0, time = 5)
	for(var/turf/T in RANGE_TURFS(1, owner))
		new /obj/effect/temp_visual/dir_setting/slash(T, owner.dir)
	playsound(get_turf(src), 'sound/weapons/fwoosh.ogg', 70, TRUE)

/obj/effect/test_range_cleaner/Destroy(force)
	UnregisterSignal(src, COMSIG_MOVABLE_MOVED)
	return ..()

// If you wanna spawn one to clean up corpses, blood, gibs, limbs, but not potentially gameplay relevant items.
/obj/effect/test_range_cleaner/bio_only
	name = "The Janitor (Merciful)"
	things_to_remove = list(
		/obj/effect/decal/cleanable,
		/obj/item/bodypart,
		/obj/item/organ,
		/obj/item/food/meat/slab,
	)
