/// Standalone city holomap display machine.
/// Shows the full color-coded city map with a "you are here" player marker.
/// Uses the same contract_citymap datum for map generation.
/// Styled to match the facility holomap aesthetic.
/obj/machinery/city_map_display
	name = "city holomap"
	desc = "A holographic display showing a detailed map of the city and surrounding areas."
	icon = 'icons/obj/machines/facilitymap.dmi'
	icon_state = "station_map"
	density = FALSE
	anchored = TRUE
	layer = ABOVE_WINDOW_LAYER
	light_color = "#64c864"
	light_range = 4
	light_power = 1
	light_system = STATIC_LIGHT
	/// Shared city map data singleton (generated once per round)
	var/static/datum/contract_citymap/citymap

/obj/machinery/city_map_display/Initialize(mapload)
	. = ..()
	flags_1 |= ON_BORDER_1
	// Set pixel offsets based on facing direction (same as facility_holomap)
	if(dir == NORTH)
		pixel_x = 0
		pixel_y = -32
	if(dir == SOUTH)
		pixel_x = 0
		pixel_y = 32
	if(dir == WEST)
		pixel_x = 32
		pixel_y = 0
	if(dir == EAST)
		pixel_x = -32
		pixel_y = 0
	if(!citymap)
		addtimer(CALLBACK(src, PROC_REF(delayed_map_init)), 10 SECONDS)

/// Delayed initialization for the city map.
/obj/machinery/city_map_display/proc/delayed_map_init()
	if(!citymap)
		citymap = new /datum/contract_citymap()
		var/turf/our_turf = get_turf(src)
		if(our_turf)
			citymap.GenerateCityMap(our_turf.z)

/obj/machinery/city_map_display/attack_hand(mob/user)
	if(machine_stat & (NOPOWER|BROKEN))
		return
	ui_interact(user)

/obj/machinery/city_map_display/ui_interact(mob/user, datum/tgui/ui)
	if(!citymap)
		citymap = new /datum/contract_citymap()
		var/turf/our_turf = get_turf(src)
		if(our_turf)
			citymap.GenerateCityMap(our_turf.z)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CityMapDisplay")
		ui.open()

/obj/machinery/city_map_display/ui_state()
	return GLOB.default_state

/// Static data sent once on UI open — the full map grid, legend, and dimensions.
/obj/machinery/city_map_display/ui_static_data(mob/user)
	var/list/data = list()
	if(citymap?.generated)
		data["mapGrid"] = citymap.GetFullMap()
		data["gridWidth"] = citymap.grid_width
		data["gridHeight"] = citymap.grid_height
		data["offsetX"] = citymap.offset_x
		data["offsetY"] = citymap.offset_y
		data["map_legend"] = citymap.cached_legend
	return data

/// Dynamic data sent on each update — player position.
/obj/machinery/city_map_display/ui_data(mob/user)
	var/list/data = list()
	var/turf/T = get_turf(user)
	if(T)
		data["player_x"] = T.x
		data["player_y"] = T.y
	return data

/obj/machinery/city_map_display/power_change()
	. = ..()
	update_icon()
	if(machine_stat & NOPOWER)
		set_light_on(FALSE)
	else
		set_light_on(TRUE)

/obj/machinery/city_map_display/update_icon_state()
	. = ..()
	if(machine_stat & BROKEN)
		icon_state = "station_mapb"
	else if((machine_stat & NOPOWER) || !anchored)
		icon_state = "station_map0"
	else
		icon_state = "station_map"

/// Handheld city map device. Use in hand to open the city holomap.
/obj/item/city_map
	name = "portable city map"
	desc = "A handheld holographic device displaying a detailed map of the city."
	icon = 'icons/obj/telescience.dmi'
	icon_state = "gps-c"
	inhand_icon_state = "electronic"
	w_class = WEIGHT_CLASS_SMALL
	/// Shared city map data singleton (same as the wall-mounted version)
	var/static/datum/contract_citymap/citymap

/obj/item/city_map/attack_self(mob/user)
	. = ..()
	ui_interact(user)

/obj/item/city_map/ui_interact(mob/user, datum/tgui/ui)
	if(!citymap)
		citymap = new /datum/contract_citymap()
		var/turf/our_turf = get_turf(src)
		if(our_turf)
			citymap.GenerateCityMap(our_turf.z)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CityMapDisplay")
		ui.open()

/obj/item/city_map/ui_state()
	return GLOB.default_state

/obj/item/city_map/ui_static_data(mob/user)
	var/list/data = list()
	if(citymap?.generated)
		data["mapGrid"] = citymap.GetFullMap()
		data["gridWidth"] = citymap.grid_width
		data["gridHeight"] = citymap.grid_height
		data["offsetX"] = citymap.offset_x
		data["offsetY"] = citymap.offset_y
		data["map_legend"] = citymap.cached_legend
	return data

/obj/item/city_map/ui_data(mob/user)
	var/list/data = list()
	var/turf/T = get_turf(user)
	if(T)
		data["player_x"] = T.x
		data["player_y"] = T.y
	return data
