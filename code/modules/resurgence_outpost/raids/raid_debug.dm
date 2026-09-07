/**
 * Resurgence Outpost - Raid Debug Tool
 *
 * Admin/debug tool for testing the raid system.
 */

/obj/item/raid_debug_tool
	name = "raid debugger"
	desc = "A debug tool for testing the raid system. Admin use only."
	icon = 'icons/obj/device.dmi'
	icon_state = "multitool"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/raid_debug_tool/attack_self(mob/user)
	if(!check_rights_for(user.client, R_DEBUG))
		to_chat(user, span_warning("You don't have permission to use this."))
		return

	var/list/options = list(
		"Trigger Basic Raid",
		"Trigger Siege Raid",
		"Trigger Pillage Raid",
		"Trigger Assassination Raid",
		"Trigger Overwhelming Raid",
		"End All Raids",
		"List Active Raids",
		"Set Insurgence Rep to 5",
		"Set Insurgence Rep to 50",
		"Toggle Raid System",
		"Show Debug Info",
		"Show Current Tier",
		"Spawn Test Raider"
	)

	var/choice = input(user, "Select raid action", "Raid Debug") as null|anything in options
	if(!choice)
		return

	switch(choice)
		if("Trigger Basic Raid")
			trigger_raid_type(user, RAID_TYPE_BASIC)
		if("Trigger Siege Raid")
			trigger_raid_type(user, RAID_TYPE_SIEGE)
		if("Trigger Pillage Raid")
			trigger_raid_type(user, RAID_TYPE_PILLAGE)
		if("Trigger Assassination Raid")
			trigger_raid_type(user, RAID_TYPE_ASSASSINATION)
		if("Trigger Overwhelming Raid")
			trigger_raid_type(user, RAID_TYPE_OVERWHELMING)
		if("End All Raids")
			end_all_raids(user)
		if("List Active Raids")
			list_active_raids(user)
		if("Set Insurgence Rep to 5")
			set_faction_rep(user, "insurgence_clan", 5)
		if("Set Insurgence Rep to 50")
			set_faction_rep(user, "insurgence_clan", 50)
		if("Toggle Raid System")
			toggle_raid_system(user)
		if("Show Debug Info")
			show_debug_info(user)
		if("Show Current Tier")
			show_current_tier(user)
		if("Spawn Test Raider")
			spawn_test_raider(user)

/obj/item/raid_debug_tool/proc/trigger_raid_type(mob/user, raid_type)
	var/datum/resurgence_raid/raid = SSresurgence_raids.force_raid("insurgence_clan", raid_type)
	if(raid)
		to_chat(user, span_notice("Triggered [raid.name]"))
		message_admins("[key_name(user)] triggered a [raid_type] raid via debug tool")
	else
		to_chat(user, span_warning("Failed to trigger raid - check spawn points"))

/obj/item/raid_debug_tool/proc/end_all_raids(mob/user)
	SSresurgence_raids.end_all_raids()
	to_chat(user, span_notice("All raids ended."))
	message_admins("[key_name(user)] ended all raids via debug tool")

/obj/item/raid_debug_tool/proc/list_active_raids(mob/user)
	if(!SSresurgence_raids.active_raids.len)
		to_chat(user, span_notice("No active raids."))
		return

	to_chat(user, span_notice("Active Raids:"))
	for(var/datum/resurgence_raid/raid in SSresurgence_raids.active_raids)
		var/state_name = "Unknown"
		switch(raid.raid_state)
			if(RAID_STATE_PENDING)
				state_name = "Pending"
			if(RAID_STATE_SPAWNING)
				state_name = "Spawning"
			if(RAID_STATE_WAITING)
				state_name = "Waiting"
			if(RAID_STATE_ACTIVE)
				state_name = "Active"
			if(RAID_STATE_RETREATING)
				state_name = "Retreating"
			if(RAID_STATE_COMPLETE)
				state_name = "Complete"

		to_chat(user, span_notice("- [raid.name]: [state_name], Raiders: [raid.get_alive_raider_count()]/[raid.initial_raider_count]"))

/obj/item/raid_debug_tool/proc/set_faction_rep(mob/user, faction_id, amount)
	if(!GLOB.resurgence_trading)
		to_chat(user, span_warning("Trading system not initialized."))
		return

	var/datum/trading_faction/faction = GLOB.resurgence_trading.get_faction(faction_id)
	if(!faction)
		to_chat(user, span_warning("Faction '[faction_id]' not found."))
		return

	faction.reputation = amount
	to_chat(user, span_notice("Set [faction.name] reputation to [amount]."))
	message_admins("[key_name(user)] set [faction.name] reputation to [amount] via debug tool")

/obj/item/raid_debug_tool/proc/toggle_raid_system(mob/user)
	SSresurgence_raids.raids_enabled = !SSresurgence_raids.raids_enabled
	to_chat(user, span_notice("Raid system [SSresurgence_raids.raids_enabled ? "enabled" : "disabled"]."))
	message_admins("[key_name(user)] [SSresurgence_raids.raids_enabled ? "enabled" : "disabled"] the raid system")

/obj/item/raid_debug_tool/proc/show_debug_info(mob/user)
	var/list/info = SSresurgence_raids.get_debug_info()

	to_chat(user, span_notice("=== Raid System Debug Info ==="))
	to_chat(user, span_notice("Enabled: [info["raids_enabled"]]"))
	to_chat(user, span_notice("Cooldown remaining: [info["cooldown_remaining"] / 10] seconds"))
	to_chat(user, span_notice("Active raids: [info["active_raids"]]"))
	to_chat(user, span_notice("Spawn points: [GLOB.raid_spawn_points.len]"))

	// Show faction reputation
	if(GLOB.resurgence_trading)
		var/datum/trading_faction/insurgence = GLOB.resurgence_trading.get_faction("insurgence_clan")
		if(insurgence)
			to_chat(user, span_notice("Insurgence Clan rep: [insurgence.reputation]"))

	// Show room count
	var/room_count = 0
	for(var/area/resurgence_outpost/room/R in GLOB.sortedAreas)
		if(R.contents.len > 0)
			room_count++
	to_chat(user, span_notice("Resurgence rooms: [room_count]"))

/obj/item/raid_debug_tool/proc/show_current_tier(mob/user)
	// Create a temporary raid datum to check tier
	var/datum/resurgence_raid/temp = new()
	var/tier = temp.get_current_raid_tier()
	qdel(temp)
	var/tier_name
	switch(tier)
		if(RAID_TIER_MILITIA)
			tier_name = "Tier 1 - Militia"
		if(RAID_TIER_REGULAR)
			tier_name = "Tier 2 - Regular"
		if(RAID_TIER_VETERAN)
			tier_name = "Tier 3 - Veteran"
		if(RAID_TIER_ELITE)
			tier_name = "Tier 4 - Elite"
	to_chat(user, span_notice("Current Raid Tier: [tier_name]"))
	to_chat(user, span_notice("Round time: [round(world.time / (1 MINUTES))] minutes"))
	to_chat(user, span_notice("Regular at [RAID_REGULAR_THRESHOLD / (1 MINUTES)] min, Veteran at [RAID_VETERAN_THRESHOLD / (1 MINUTES)] min, Elite at [RAID_ELITE_THRESHOLD / (1 MINUTES)] min"))

/obj/item/raid_debug_tool/proc/spawn_test_raider(mob/user)
	var/turf/T = get_turf(user)
	if(!T)
		log_admin("RAID DEBUG: spawn_test_raider() failed - could not get user turf")
		return

	// Create a scout with raider component
	var/mob/living/simple_animal/hostile/clan/raider/scout/raider = new(T)
	raider.faction = list("insurgence_raiders")

	// Find a target
	var/atom/target = null
	var/list/rooms = get_resurgence_room_areas(FALSE)
	log_admin("RAID DEBUG: spawn_test_raider() found [rooms.len] rooms")
	if(rooms.len)
		var/area/resurgence_outpost/room/R = pick(rooms)
		target = get_random_turf_in_room(R)
		log_admin("RAID DEBUG: spawn_test_raider() targeting room [R.name], turf: [target ? AREACOORD(target) : "NULL"]")
	if(!target)
		target = user
		log_admin("RAID DEBUG: spawn_test_raider() no rooms found - targeting user instead (raider may not move properly!)")

	// Add component
	raider.AddComponent(/datum/component/raider, null, target, null)

	to_chat(user, span_notice("Spawned test raider targeting [target]. Check game logs for debug info."))
	message_admins("[key_name(user)] spawned a test raider via debug tool")

// ==================== Admin Verb ====================

/client/proc/raid_debug_panel()
	set name = "Raid Debug Panel"
	set category = "Debug"

	if(!check_rights(R_DEBUG))
		return

	var/list/options = list(
		"Trigger Basic Raid",
		"Trigger Siege Raid",
		"Trigger Pillage Raid",
		"Trigger Assassination Raid",
		"Trigger Overwhelming Raid",
		"End All Raids",
		"Toggle Raid System",
		"Show Debug Info",
		"Show Current Tier"
	)

	var/choice = input(usr, "Select raid action", "Raid Debug") as null|anything in options
	if(!choice)
		return

	switch(choice)
		if("Trigger Basic Raid")
			SSresurgence_raids.force_raid("insurgence_clan", RAID_TYPE_BASIC)
		if("Trigger Siege Raid")
			SSresurgence_raids.force_raid("insurgence_clan", RAID_TYPE_SIEGE)
		if("Trigger Pillage Raid")
			SSresurgence_raids.force_raid("insurgence_clan", RAID_TYPE_PILLAGE)
		if("Trigger Assassination Raid")
			SSresurgence_raids.force_raid("insurgence_clan", RAID_TYPE_ASSASSINATION)
		if("Trigger Overwhelming Raid")
			SSresurgence_raids.force_raid("insurgence_clan", RAID_TYPE_OVERWHELMING)
		if("End All Raids")
			SSresurgence_raids.end_all_raids()
			to_chat(usr, span_notice("All raids ended."))
		if("Toggle Raid System")
			SSresurgence_raids.raids_enabled = !SSresurgence_raids.raids_enabled
			to_chat(usr, span_notice("Raid system [SSresurgence_raids.raids_enabled ? "enabled" : "disabled"]."))
		if("Show Debug Info")
			var/list/info = SSresurgence_raids.get_debug_info()
			to_chat(usr, span_notice("Raids enabled: [info["raids_enabled"]], Active: [info["active_raids"]], Cooldown: [info["cooldown_remaining"]/10]s"))
		if("Show Current Tier")
			var/datum/resurgence_raid/temp = new()
			var/tier = temp.get_current_raid_tier()
			qdel(temp)
			var/tier_names = list("Militia", "Regular", "Veteran", "Elite")
			to_chat(usr, span_notice("Current Raid Tier: [tier] - [tier_names[tier]] (Round: [round(world.time / (1 MINUTES))] min)"))
