/// Tactical Map HUD Glasses
/datum/action/item_action/open_tactical_map
	name = "Open Tactical Map"
	desc = "Opens the facility tactical map interface for coordination and planning."

/// Provides security HUD functionality with added tactical map access
/obj/item/clothing/glasses/hud/security/tactical
	name = "tactical map HUD"
	desc = "A heads-up display that scans the humanoids in view and provides accurate data about their ID status and security records. Features integrated tactical map access for facility coordination."
	icon_state = "healthhud"
	actions_types = list(/datum/action/item_action/open_tactical_map)

/// Called when the action button is pressed
/obj/item/clothing/glasses/hud/security/tactical/ui_action_click(mob/user)
	open_tactical_map(user)

/// Only allow the action when worn in the eyes slot
/obj/item/clothing/glasses/hud/security/tactical/item_action_slot_check(slot)
	if(slot == ITEM_SLOT_EYES)
		return TRUE
	return FALSE

/// Opens the tactical map interface for the current z-level
/obj/item/clothing/glasses/hud/security/tactical/proc/open_tactical_map(mob/user)
	if(!user)
		return

	// Find a tactical map machine on the same z-level
	var/obj/machinery/facility_tactical_map/nearest_map = null
	var/shortest_distance = INFINITY

	for(var/obj/machinery/facility_tactical_map/M in GLOB.facility_tactical_maps)
		if(M.map_z_level == user.z)
			var/distance = get_dist(user, M)
			if(distance < shortest_distance)
				shortest_distance = distance
				nearest_map = M

	// If no map found on this z-level, try to find any map and use its z-level
	if(!nearest_map && length(GLOB.facility_tactical_maps))
		nearest_map = GLOB.facility_tactical_maps[1]
		to_chat(user, span_notice("Connecting to tactical map system..."))

	if(nearest_map)
		// Open the tactical map UI
		nearest_map.ui_interact(user)
	else
		to_chat(user, span_warning("No tactical map system available!"))

/// Night vision variant with tactical map access
/obj/item/clothing/glasses/hud/security/tactical/night
	name = "night vision tactical map HUD"
	desc = "An advanced heads-up display that provides security data, tactical map access, and vision in complete darkness."
	icon_state = "healthhudnight"
	darkness_view = 8
	flash_protect = FLASH_PROTECTION_SENSITIVE
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
	glass_colour_type = /datum/client_colour/glass_colour/green

/// Sunglasses variant with tactical map access
/obj/item/clothing/glasses/hud/security/tactical/sunglasses
	name = "tactical HUDSunglasses"
	desc = "Sunglasses with a medical HUD and integrated tactical map access."
	icon_state = "sunhudmed"
	darkness_view = 1
	flash_protect = FLASH_PROTECTION_FLASH
	tint = 1
	glass_colour_type = /datum/client_colour/glass_colour/blue
