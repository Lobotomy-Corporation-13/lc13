/// Mark for Protection action shared by Client Protection T1 skills (Designated Ward / Threatening Presence).
/// Press the action button to enter targeting mode, then click a living mob to set as your ward.
/// Press again or click empty space to cancel. Click the current ward to remove them.
/datum/action/cooldown/zwei_mark_for_protection
	name = "Mark for Protection"
	desc = "Select a player to designate as your ward. Your Client Protection skills will focus on protecting them."
	icon_icon = 'icons/hud/screen_assoc_trees.dmi'
	button_icon_state = "zwei_protect"
	cooldown_time = 1 SECONDS
	/// Currently designated ward
	var/mob/living/ward
	/// Whether we are in targeting mode (waiting for a click)
	var/targeting = FALSE
	/// Targeting range
	var/ward_range = 7
	/// Mouse pointer icon for targeting mode
	var/targeting_cursor = 'icons/effects/mouse_pointers/throw_target.dmi'
	/// Callbacks to notify child skills when the ward changes
	var/list/datum/callback/ward_change_callbacks = list()

/datum/action/cooldown/zwei_mark_for_protection/Trigger()
	. = ..()
	if(!.)
		return FALSE
	if(!ishuman(owner))
		return FALSE
	// Toggle targeting mode
	if(targeting)
		deactivate_targeting()
		return TRUE
	activate_targeting()
	return TRUE

/// Enter targeting mode — intercept the owner's next click.
/datum/action/cooldown/zwei_mark_for_protection/proc/activate_targeting()
	if(!owner || !owner.client)
		return
	targeting = TRUE
	owner.click_intercept = src
	owner.client.mouse_override_icon = targeting_cursor
	owner.update_mouse_pointer()
	to_chat(owner, span_notice("Click a player to designate as your ward. Click again to cancel."))

/// Exit targeting mode and clean up click intercept.
/datum/action/cooldown/zwei_mark_for_protection/proc/deactivate_targeting()
	targeting = FALSE
	if(owner)
		if(owner.click_intercept == src)
			owner.click_intercept = null
		if(owner.client)
			owner.client.mouse_override_icon = null
			owner.update_mouse_pointer()

/// Called by the click intercept system when the owner clicks while targeting.
/datum/action/cooldown/zwei_mark_for_protection/proc/InterceptClickOn(mob/living/user, params, atom/target)
	// Always consume the click and leave targeting mode
	deactivate_targeting()
	// Validate target
	if(!isliving(target) || target == owner)
		StartCooldown()
		return TRUE
	var/mob/living/L = target
	if(!(L in view(ward_range, get_turf(owner))))
		to_chat(owner, span_warning("Target is too far away."))
		StartCooldown()
		return TRUE
	// If clicking the current ward, remove them
	if(L == ward)
		clear_ward()
		to_chat(owner, span_warning("Ward designation removed."))
		StartCooldown()
		return TRUE
	// Set new ward
	set_ward(L)
	to_chat(owner, span_nicegreen("Ward designated: [L.name]"))
	StartCooldown()
	return TRUE

/// Set a new ward, clearing old ward if any.
/datum/action/cooldown/zwei_mark_for_protection/proc/set_ward(mob/living/target)
	if(ward)
		clear_ward()
	ward = target
	// Apply ward indicator status effect
	var/datum/status_effect/display/zwei_ward_indicator/existing = target.has_status_effect(/datum/status_effect/display/zwei_ward_indicator)
	if(existing)
		// Another Zwei member already has a ward designation on this target — add ourselves as a viewer
		existing.add_marker(owner)
	else
		target.apply_status_effect(/datum/status_effect/display/zwei_ward_indicator, owner)
	// Register death signal to clear ward
	RegisterSignal(target, COMSIG_LIVING_DEATH, PROC_REF(on_ward_death))
	// Notify child skills of ward change
	notify_ward_change()

/// Clear the current ward.
/datum/action/cooldown/zwei_mark_for_protection/proc/clear_ward()
	if(!ward)
		return
	UnregisterSignal(ward, COMSIG_LIVING_DEATH)
	// Remove ourselves from the ward indicator
	var/datum/status_effect/display/zwei_ward_indicator/indicator = ward.has_status_effect(/datum/status_effect/display/zwei_ward_indicator)
	if(indicator)
		indicator.remove_marker(owner)
	ward = null
	// Notify child skills of ward change
	notify_ward_change()

/// Returns the ward if still alive and valid.
/datum/action/cooldown/zwei_mark_for_protection/proc/get_ward()
	if(!ward || QDELETED(ward) || ward.stat == DEAD)
		return null
	return ward

/// Signal handler: ward died.
/datum/action/cooldown/zwei_mark_for_protection/proc/on_ward_death(datum/source)
	SIGNAL_HANDLER
	clear_ward()
	if(owner)
		to_chat(owner, span_warning("Your ward has died. Ward designation cleared."))

/// Notify all child skills that the ward has changed.
/datum/action/cooldown/zwei_mark_for_protection/proc/notify_ward_change()
	for(var/datum/callback/CB in ward_change_callbacks)
		CB.Invoke(ward)

/datum/action/cooldown/zwei_mark_for_protection/Remove(mob/living/L)
	deactivate_targeting()
	clear_ward()
	ward_change_callbacks.Cut()
	return ..()

// ============================================================
// Zwei Ward Indicator — Display Status Effect
// ============================================================
/// Display status effect shown on warded targets.
/// Only visible to the warded target themselves and the Zwei member(s) who designated them.
/datum/status_effect/display/zwei_ward_indicator
	id = "zwei_ward_indicator"
	duration = -1
	tick_interval = -1
	alert_type = null
	display_name = "zwei_ward"
	/// Client-side image shown only to relevant viewers
	var/image/ward_image
	/// List of clients currently seeing this indicator
	var/list/client/viewing_clients = list()
	/// List of mobs who have designated this target as ward (for multi-marker support)
	var/list/mob/living/markers = list()

/datum/status_effect/display/zwei_ward_indicator/on_creation(mob/living/new_owner, mob/living/marker)
	if(marker)
		markers += marker
	return ..()

/datum/status_effect/display/zwei_ward_indicator/on_apply()
	// Don't call parent — we handle icon display ourselves via client images, not global overlays.
	UpdateStatusDisplay()
	return TRUE

/datum/status_effect/display/zwei_ward_indicator/on_remove()
	remove_from_all_clients()
	ward_image = null
	// Don't call parent's on_remove since we didn't use icon_overlay/add_overlay

/// Override: Create a client-side image visible only to the target and marker(s).
/datum/status_effect/display/zwei_ward_indicator/AddDisplayIcon(position)
	// Clean up previous image
	remove_from_all_clients()
	// Create the client-side image
	ward_image = image('ModularLobotomy/_Lobotomyicons/tegu_effects10x10.dmi', owner, display_name, -MUTATIONS_LAYER)
	// Position using the same grid as other display effects
	var/column = (WRAP(position, 0, 4) * 10) + (-5)
	var/row = 33 + (round(position * 0.25) * 10)
	ward_image.pixel_x = column
	ward_image.pixel_y = row
	// Add to relevant clients
	add_to_viewers()

/// Add the ward image to the target's client and all marker clients.
/datum/status_effect/display/zwei_ward_indicator/proc/add_to_viewers()
	if(!ward_image)
		return
	// Target can see their own ward designation
	if(owner.client)
		owner.client.images |= ward_image
		viewing_clients |= owner.client
	// Each Zwei member who designated this target can see it
	for(var/mob/living/marker in markers)
		if(marker.client)
			marker.client.images |= ward_image
			viewing_clients |= marker.client

/// Remove the image from all viewing clients.
/datum/status_effect/display/zwei_ward_indicator/proc/remove_from_all_clients()
	if(!ward_image)
		return
	for(var/client/C in viewing_clients)
		C.images -= ward_image
	viewing_clients.Cut()

/// Refresh which clients can see this indicator.
/datum/status_effect/display/zwei_ward_indicator/proc/refresh_viewers()
	remove_from_all_clients()
	add_to_viewers()

/// Add a new marker (Zwei member) who can see this indicator.
/datum/status_effect/display/zwei_ward_indicator/proc/add_marker(mob/living/marker)
	if(!(marker in markers))
		markers += marker
	if(marker.client && ward_image)
		marker.client.images |= ward_image
		viewing_clients |= marker.client

/// Remove a marker. If no markers remain, remove the status effect entirely.
/datum/status_effect/display/zwei_ward_indicator/proc/remove_marker(mob/living/marker)
	markers -= marker
	if(marker.client && ward_image)
		marker.client.images -= ward_image
		viewing_clients -= marker.client
	// If no one is designating this target as ward anymore, remove the effect
	if(!length(markers))
		qdel(src)

// ============================================================
// Helper proc
// ============================================================
/// Returns the Zwei mark for protection action on a mob, if it has one.
/proc/get_zwei_ward_action(mob/living/L)
	if(!L)
		return null
	for(var/datum/action/cooldown/zwei_mark_for_protection/action in L.actions)
		return action
	return null
