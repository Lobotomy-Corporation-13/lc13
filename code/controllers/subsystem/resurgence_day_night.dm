/**
 * Day/Night Cycle Subsystem for Resurgence Outpost
 *
 * Manages ambient daylight changes using a fullscreen darkness overlay on LIGHTING_PLANE.
 * Light sources using MOVABLE_LIGHT automatically punch through the darkness via the
 * existing alpha_mask_filter on the lighting plane master.
 *
 * Performance: One fullscreen overlay per player, updated every fire(). No per-turf cost.
 */
SUBSYSTEM_DEF(day_night)
	name = "Day Night Cycle"
	wait = 10 SECONDS
	flags = SS_BACKGROUND

	/// Current cycle time (0.0=midnight, 0.5=noon, 1.0=midnight)
	var/cycle_time = 0.25
	/// Speed: how much cycle_time advances per fire()
	var/cycle_speed = 0.0015
	/// Current darkness alpha (0=bright day, 200=dark night)
	var/darkness_alpha = 0
	/// Whether cycle is active (only on outpost maptype)
	var/active = FALSE
	/// Current sky tint color for outdoor areas
	var/sky_tint = "#ffffff"
	/// Previous time-of-day name, for announcing transitions
	var/previous_time_name = ""
	/// Assoc list of door ref → sunlight_bleed effect for open doors
	var/list/open_door_effects = list()
	/// Assoc list of window ref → sunlight_bleed effect (always on, windows are transparent)
	var/list/open_window_effects = list()
	/// Maximum light range for sunlight bleed at noon
	var/max_sunlight_range = 6
	/// Current computed sunlight range based on time of day
	var/current_sunlight_range = 0
	/// Current computed sunlight color based on time of day
	var/current_sunlight_color = "#FFFFEE"

/datum/controller/subsystem/day_night/Initialize(start_timeofday)
	if(SSmaptype.maptype != "outpost")
		active = FALSE
		return ..()

	active = TRUE
	// Start at noon (0.5) for bright white start
	cycle_time = 0.5
	darkness_alpha = calculate_darkness(cycle_time)
	sky_tint = calculate_sky_tint(cycle_time)
	previous_time_name = get_time_name()
	current_sunlight_range = calculate_sunlight_range()
	current_sunlight_color = calculate_sunlight_color()
	return ..()

/datum/controller/subsystem/day_night/fire(resumed)
	if(!active)
		return

	// Advance cycle
	cycle_time += cycle_speed
	if(cycle_time >= 1.0)
		cycle_time -= 1.0

	// Calculate new darkness and tint
	darkness_alpha = calculate_darkness(cycle_time)
	sky_tint = calculate_sky_tint(cycle_time)

	// Announce phase transitions
	var/current_time_name = get_time_name()
	if(current_time_name != previous_time_name)
		announce_time_change(current_time_name)
		previous_time_name = current_time_name

	// Update all living mobs
	for(var/mob/living/L in GLOB.alive_mob_list)
		if(!L.client)
			continue
		update_mob_darkness(L)

	// Update outdoor area tinting
	update_area_tint()

	// Update sunlight bleed through open doors
	current_sunlight_range = calculate_sunlight_range()
	current_sunlight_color = calculate_sunlight_color()
	update_sunlight_ranges()

/// Calculate darkness alpha (0-200) from cycle_time using keyframe interpolation
/datum/controller/subsystem/day_night/proc/calculate_darkness(time)
	// Keyframes: list of list(time, alpha)
	var/list/keyframes = list(
		list(0.00, 180),
		list(0.20, 180),
		list(0.25, 100),
		list(0.35, 20),
		list(0.50, 0),
		list(0.65, 20),
		list(0.75, 100),
		list(0.80, 180),
		list(1.00, 180)
	)

	// Find surrounding keyframes and interpolate
	for(var/i in 1 to (keyframes.len - 1))
		var/list/kf_a = keyframes[i]
		var/list/kf_b = keyframes[i + 1]
		if(time >= kf_a[1] && time <= kf_b[1])
			var/range = kf_b[1] - kf_a[1]
			if(range <= 0)
				return kf_a[2]
			var/t = (time - kf_a[1]) / range
			return round(kf_a[2] + (kf_b[2] - kf_a[2]) * t)

	return 180 // fallback (midnight)

/// Calculate sky tint color from cycle_time
/// Uses the same darkness curve — white at noon, black at midnight
/datum/controller/subsystem/day_night/proc/calculate_sky_tint(time)
	// Reuse the darkness alpha (0-180) to derive a grayscale tint
	// alpha 0 = full white (#ffffff), alpha 180 = black (#000000)
	var/dark = calculate_darkness(time)
	var/brightness = round(255 * (1.0 - dark / 180.0))
	brightness = clamp(brightness, 0, 255)
	return rgb(brightness, brightness, brightness)

/// Update darkness overlay for a single mob
/datum/controller/subsystem/day_night/proc/update_mob_darkness(mob/living/M)
	if(!M.client)
		return

	// Check if mob is on the resurgence z-level
	var/turf/T = get_turf(M)
	if(!T || !SSmapping.level_trait(T.z, ZTRAIT_RESURGENCE))
		M.clear_fullscreen("day_night")
		return

	// Apply/update darkness overlay — all resurgence areas get the same darkness
	var/atom/movable/screen/fullscreen/F = M.overlay_fullscreen("day_night", /atom/movable/screen/fullscreen/day_night_darkness)
	if(F)
		animate(F, alpha = darkness_alpha, time = 5 SECONDS)

/// Update area color tinting for atmosphere — applies to all resurgence outpost areas
/// Rooms use DYNAMIC_LIGHTING_FORCED so they are dark by default (no tint needed)
/datum/controller/subsystem/day_night/proc/update_area_tint()
	for(var/area/resurgence_outpost/A in GLOB.sortedAreas)
		if(istype(A, /area/resurgence_outpost/room))
			continue
		A.color = sky_tint

/// Get human-readable time of day name
/datum/controller/subsystem/day_night/proc/get_time_name()
	if(cycle_time >= 0.22 && cycle_time < 0.30)
		return "Dawn"
	if(cycle_time >= 0.30 && cycle_time < 0.70)
		return "Day"
	if(cycle_time >= 0.70 && cycle_time < 0.82)
		return "Dusk"
	return "Night"

/// Announce time-of-day phase change to all resurgence players
/datum/controller/subsystem/day_night/proc/announce_time_change(new_phase)
	var/message
	switch(new_phase)
		if("Dawn")
			message = span_notice("The sun begins to rise. A new day dawns.")
		if("Day")
			message = span_notice("Daylight fills the outskirts.")
		if("Dusk")
			message = span_warning("The sun begins to set. Darkness approaches.")
		if("Night")
			message = span_warning("Night has fallen. Stay near the light.")

	if(!message)
		return

	for(var/mob/living/L in GLOB.alive_mob_list)
		if(!L.client)
			continue
		var/turf/T = get_turf(L)
		if(T && SSmapping.level_trait(T.z, ZTRAIT_RESURGENCE))
			to_chat(L, message)

/// Force-update all mobs and areas to current darkness/tint values immediately
/datum/controller/subsystem/day_night/proc/force_update()
	for(var/mob/living/L in GLOB.alive_mob_list)
		if(!L.client)
			continue
		update_mob_darkness(L)
	update_area_tint()
	current_sunlight_range = calculate_sunlight_range()
	current_sunlight_color = calculate_sunlight_color()
	update_sunlight_ranges()

/// Set cycle time and immediately apply. Used by debug tools.
/datum/controller/subsystem/day_night/proc/set_time(new_time)
	cycle_time = clamp(new_time, 0.0, 0.99)
	darkness_alpha = calculate_darkness(cycle_time)
	sky_tint = calculate_sky_tint(cycle_time)
	previous_time_name = get_time_name()
	force_update()

// ---- Sunlight bleed through open doors ----

/// Calculate sunlight light range based on current darkness (0 at night, max_sunlight_range at noon)
/datum/controller/subsystem/day_night/proc/calculate_sunlight_range()
	return round(max_sunlight_range * (1 - darkness_alpha / 180), 0.1)

/// Calculate sunlight color based on time of day
/// Warm white (#FFFFEE) that darkens as night approaches
/datum/controller/subsystem/day_night/proc/calculate_sunlight_color()
	if(darkness_alpha >= 180)
		return "#000000"
	// Darken warm white based on how much sunlight remains
	var/brightness = clamp(1 - darkness_alpha / 180, 0, 1)
	var/r = round(255 * brightness)
	var/g = round(255 * brightness)
	var/b = round(238 * brightness)
	return rgb(r, g, b)

/// Check if a door has an adjacent outdoor resurgence area
/datum/controller/subsystem/day_night/proc/door_adjacent_to_outdoors(obj/structure/mineral_door/D)
	var/turf/door_turf = get_turf(D)
	if(!door_turf)
		return FALSE
	for(var/dir in GLOB.cardinals)
		var/turf/T = get_step(door_turf, dir)
		if(!T)
			continue
		var/area/A = T.loc
		if(A?.outdoors)
			return TRUE
	return FALSE

/// Register a mineral door for sunlight bleed tracking
/datum/controller/subsystem/day_night/proc/register_door(obj/structure/mineral_door/D)
	RegisterSignal(D, COMSIG_MINERAL_DOOR_OPEN, PROC_REF(on_door_opened))
	RegisterSignal(D, COMSIG_MINERAL_DOOR_CLOSE, PROC_REF(on_door_closed))
	RegisterSignal(D, COMSIG_PARENT_QDELETING, PROC_REF(on_door_deleted))
	// If door is already open at round start, create the effect now
	if(D.door_opened && initial(D.opacity))
		create_sunlight_effect(D)

/// Unregister a mineral door from sunlight bleed tracking
/datum/controller/subsystem/day_night/proc/unregister_door(obj/structure/mineral_door/D)
	UnregisterSignal(D, list(COMSIG_MINERAL_DOOR_OPEN, COMSIG_MINERAL_DOOR_CLOSE, COMSIG_PARENT_QDELETING))
	remove_sunlight_effect(D)

/// Signal handler: mineral door opened
/datum/controller/subsystem/day_night/proc/on_door_opened(obj/structure/mineral_door/source)
	SIGNAL_HANDLER
	// Skip transparent doors — light already passes through them
	if(!initial(source.opacity))
		return
	create_sunlight_effect(source)

/// Signal handler: mineral door closed
/datum/controller/subsystem/day_night/proc/on_door_closed(obj/structure/mineral_door/source)
	SIGNAL_HANDLER
	remove_sunlight_effect(source)

/// Signal handler: mineral door deleted
/datum/controller/subsystem/day_night/proc/on_door_deleted(obj/structure/mineral_door/source)
	SIGNAL_HANDLER
	remove_sunlight_effect(source)

/// Create a sunlight bleed effect on a door's turf
/datum/controller/subsystem/day_night/proc/create_sunlight_effect(obj/structure/mineral_door/D)
	if(open_door_effects[D])
		return // Already has an effect
	// Only create sunlight for doors adjacent to outdoor areas
	if(!door_adjacent_to_outdoors(D))
		return
	var/obj/effect/sunlight_bleed/S = new(get_turf(D))
	if(current_sunlight_range > 0)
		S.set_light_range(current_sunlight_range)
		S.set_light_power(1)
		S.set_light_color(current_sunlight_color)
		S.set_light_on(TRUE)
	open_door_effects[D] = S

/// Remove a sunlight bleed effect from a door
/datum/controller/subsystem/day_night/proc/remove_sunlight_effect(obj/structure/mineral_door/D)
	var/obj/effect/sunlight_bleed/S = open_door_effects[D]
	if(S)
		qdel(S)
	open_door_effects -= D

/// Update light range on all active sunlight bleed effects (doors and windows)
/datum/controller/subsystem/day_night/proc/update_sunlight_ranges()
	for(var/door in open_door_effects)
		var/obj/effect/sunlight_bleed/S = open_door_effects[door]
		if(!S)
			continue
		if(current_sunlight_range <= 0)
			S.set_light_on(FALSE)
		else
			S.set_light_range(current_sunlight_range)
			S.set_light_color(current_sunlight_color)
			S.set_light_on(TRUE)
	for(var/window in open_window_effects)
		var/obj/effect/sunlight_bleed/S = open_window_effects[window]
		if(!S)
			continue
		if(current_sunlight_range <= 0)
			S.set_light_on(FALSE)
		else
			S.set_light_range(current_sunlight_range)
			S.set_light_color(current_sunlight_color)
			S.set_light_on(TRUE)

// ---- Sunlight bleed through windows (always on) ----

/// Check if a window has an adjacent outdoor resurgence area
/datum/controller/subsystem/day_night/proc/window_adjacent_to_outdoors(obj/structure/window/W)
	var/turf/window_turf = get_turf(W)
	if(!window_turf)
		return FALSE
	for(var/dir in GLOB.cardinals)
		var/turf/T = get_step(window_turf, dir)
		if(!T)
			continue
		var/area/A = T.loc
		if(A?.outdoors)
			return TRUE
	return FALSE

/// Register a window for always-on sunlight bleed tracking
/datum/controller/subsystem/day_night/proc/register_window(obj/structure/window/W)
	RegisterSignal(W, COMSIG_PARENT_QDELETING, PROC_REF(on_window_deleted))
	// Windows are always transparent - create sunlight effect immediately
	if(!window_adjacent_to_outdoors(W))
		return
	var/obj/effect/sunlight_bleed/S = new(get_turf(W))
	if(current_sunlight_range > 0)
		S.set_light_range(current_sunlight_range)
		S.set_light_power(1)
		S.set_light_color(current_sunlight_color)
		S.set_light_on(TRUE)
	open_window_effects[W] = S

/// Unregister a window from sunlight bleed tracking
/datum/controller/subsystem/day_night/proc/unregister_window(obj/structure/window/W)
	UnregisterSignal(W, COMSIG_PARENT_QDELETING)
	var/obj/effect/sunlight_bleed/S = open_window_effects[W]
	if(S)
		qdel(S)
	open_window_effects -= W

/// Signal handler: window deleted
/datum/controller/subsystem/day_night/proc/on_window_deleted(obj/structure/window/source)
	SIGNAL_HANDLER
	var/obj/effect/sunlight_bleed/S = open_window_effects[source]
	if(S)
		qdel(S)
	open_window_effects -= source

/// Invisible light-emitting effect for sunlight bleeding through open doors
/// Uses MOVABLE_LIGHT matching lantern setup for proper light rendering
/obj/effect/sunlight_bleed
	name = "sunlight"
	icon_state = "" // No visible sprite
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	light_system = MOVABLE_LIGHT
	light_range = 6
	light_power = 1
	light_color = "#FFFFEE"
	light_on = FALSE

// ---- Debug item ----

/// Admin debug item for controlling the day/night cycle
/obj/item/day_night_debugger
	name = "day/night debugger"
	desc = "A debug tool for controlling the day/night cycle. Admin only."
	icon = 'icons/obj/device.dmi'
	icon_state = "multitool"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/day_night_debugger/attack_self(mob/user)
	if(!check_rights(R_DEBUG))
		return
	if(!SSday_night.active)
		to_chat(user, span_warning("Day/night cycle is not active (maptype is not outpost). Activating manually."))
		SSday_night.active = TRUE

	var/list/options = list(
		"Midnight (0.0)",
		"Dawn (0.25)",
		"Morning (0.35)",
		"Noon (0.5)",
		"Afternoon (0.65)",
		"Dusk (0.75)",
		"Night (0.8)",
		"Custom...",
		"Toggle Pause",
		"Set Speed"
	)

	var/choice = input(user, "Current: [SSday_night.get_time_name()] ([SSday_night.cycle_time])\nSpeed: [SSday_night.cycle_speed]\nDarkness alpha: [SSday_night.darkness_alpha]", "Day/Night Debugger") as null|anything in options
	if(!choice)
		return

	switch(choice)
		if("Midnight (0.0)")
			SSday_night.set_time(0.0)
		if("Dawn (0.25)")
			SSday_night.set_time(0.25)
		if("Morning (0.35)")
			SSday_night.set_time(0.35)
		if("Noon (0.5)")
			SSday_night.set_time(0.5)
		if("Afternoon (0.65)")
			SSday_night.set_time(0.65)
		if("Dusk (0.75)")
			SSday_night.set_time(0.75)
		if("Night (0.8)")
			SSday_night.set_time(0.8)
		if("Custom...")
			var/new_time = input(user, "Enter cycle time (0.0 = midnight, 0.5 = noon):", "Custom Time", SSday_night.cycle_time) as null|num
			if(isnull(new_time))
				return
			SSday_night.set_time(new_time)
		if("Toggle Pause")
			if(SSday_night.cycle_speed == 0)
				SSday_night.cycle_speed = initial(SSday_night.cycle_speed)
				to_chat(user, span_notice("Day/night cycle resumed."))
			else
				SSday_night.cycle_speed = 0
				to_chat(user, span_notice("Day/night cycle paused."))
			message_admins("[key_name_admin(user)] [SSday_night.cycle_speed ? "resumed" : "paused"] the day/night cycle.")
			return
		if("Set Speed")
			var/new_speed = input(user, "Enter cycle speed (default [initial(SSday_night.cycle_speed)], higher = faster):", "Cycle Speed", SSday_night.cycle_speed) as null|num
			if(isnull(new_speed))
				return
			SSday_night.cycle_speed = new_speed
			to_chat(user, span_notice("Cycle speed set to [new_speed]."))
			message_admins("[key_name_admin(user)] set day/night cycle speed to [new_speed].")
			return

	message_admins("[key_name_admin(user)] set day/night time to [SSday_night.cycle_time] ([SSday_night.get_time_name()]).")

// ---- Fullscreen overlay type ----

/// Darkness overlay that sits on LIGHTING_PLANE above the backdrop.
/// MOVABLE_LIGHT sources automatically mask through this via the plane master's alpha_mask_filter.
/atom/movable/screen/fullscreen/day_night_darkness
	icon = 'icons/hud/screen_gen.dmi'
	icon_state = "flash"
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	plane = LIGHTING_PLANE
	layer = BACKGROUND_LAYER + 22
	blend_mode = BLEND_OVERLAY
	color = "#000000"
	alpha = 0
	show_when_dead = TRUE
