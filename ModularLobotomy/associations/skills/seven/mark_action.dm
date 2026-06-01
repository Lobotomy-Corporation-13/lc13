/// Mark Target action shared by Analyst T1 skills (Case File / Profiling).
/// Press the action button to enter targeting mode, then click a living mob to mark them.
/// Press again or click empty space to cancel. Click the marked target to unmark.
/datum/action/cooldown/seven_mark_target
	name = "Mark Target"
	desc = "Select a target to mark for investigation. Marked targets interact with your Analyst skills."
	icon_icon = 'icons/hud/screen_assoc_trees.dmi'
	button_icon_state = "seven_mark"
	cooldown_time = 1 SECONDS
	/// Currently marked target
	var/mob/living/marked_target
	/// Whether we are in targeting mode (waiting for a click)
	var/targeting = FALSE
	/// Targeting range
	var/mark_range = 7
	/// Mouse pointer icon for targeting mode
	var/targeting_cursor = 'icons/effects/mouse_pointers/throw_target.dmi'

/datum/action/cooldown/seven_mark_target/Trigger()
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
/datum/action/cooldown/seven_mark_target/proc/activate_targeting()
	if(!owner || !owner.client)
		return
	targeting = TRUE
	owner.click_intercept = src
	owner.client.mouse_override_icon = targeting_cursor
	owner.update_mouse_pointer()
	to_chat(owner, span_notice("Click a target to mark them. Click again to cancel."))

/// Exit targeting mode and clean up click intercept.
/datum/action/cooldown/seven_mark_target/proc/deactivate_targeting()
	targeting = FALSE
	if(owner)
		if(owner.click_intercept == src)
			owner.click_intercept = null
		if(owner.client)
			owner.client.mouse_override_icon = null
			owner.update_mouse_pointer()

/// Called by the click intercept system when the owner clicks while targeting.
/datum/action/cooldown/seven_mark_target/proc/InterceptClickOn(mob/living/user, params, atom/target)
	// Always consume the click and leave targeting mode
	deactivate_targeting()
	// Validate target
	if(!isliving(target) || target == owner)
		StartCooldown()
		return TRUE
	var/mob/living/L = target
	if(!(L in view(mark_range, get_turf(owner))))
		to_chat(owner, span_warning("Target is too far away."))
		StartCooldown()
		return TRUE
	// If clicking the current mark, unmark them
	if(L == marked_target)
		clear_mark()
		to_chat(owner, span_warning("Target unmarked."))
		StartCooldown()
		return TRUE
	// Set new mark
	set_mark(L)
	to_chat(owner, span_nicegreen("Target marked: [L.name]"))
	StartCooldown()
	return TRUE

/// Set a new marked target, clearing old mark if any.
/datum/action/cooldown/seven_mark_target/proc/set_mark(mob/living/target)
	if(marked_target)
		clear_mark()
	marked_target = target
	// Apply mark indicator status effect
	var/datum/status_effect/display/seven_mark_indicator/existing = target.has_status_effect(/datum/status_effect/display/seven_mark_indicator)
	if(existing)
		// Another Seven member already has a mark on this target — add ourselves as a viewer
		existing.add_marker(owner)
	else
		target.apply_status_effect(/datum/status_effect/display/seven_mark_indicator, owner)
	// Register death signal to clear mark
	RegisterSignal(target, COMSIG_LIVING_DEATH, PROC_REF(on_marked_death))

/// Clear the current mark.
/datum/action/cooldown/seven_mark_target/proc/clear_mark()
	if(!marked_target)
		return
	UnregisterSignal(marked_target, COMSIG_LIVING_DEATH)
	// Remove ourselves from the mark indicator
	var/datum/status_effect/display/seven_mark_indicator/indicator = marked_target.has_status_effect(/datum/status_effect/display/seven_mark_indicator)
	if(indicator)
		indicator.remove_marker(owner)
	marked_target = null

/// Returns the marked target if still alive and valid.
/datum/action/cooldown/seven_mark_target/proc/get_marked()
	if(!marked_target || QDELETED(marked_target) || marked_target.stat == DEAD)
		return null
	return marked_target

/// Signal handler: marked target died.
/datum/action/cooldown/seven_mark_target/proc/on_marked_death(datum/source)
	SIGNAL_HANDLER
	clear_mark()
	if(owner)
		to_chat(owner, span_warning("Your marked target has died. Mark cleared."))

/datum/action/cooldown/seven_mark_target/Remove(mob/living/L)
	deactivate_targeting()
	clear_mark()
	return ..()

// ============================================================
// Seven Mark Indicator — Display Status Effect
// ============================================================
/// Display status effect shown on marked targets.
/// Only visible to the marked target themselves and the Seven member(s) who marked them.
/datum/status_effect/display/seven_mark_indicator
	id = "seven_mark_indicator"
	duration = -1
	tick_interval = -1
	alert_type = null
	display_name = "seven_mark"
	/// Client-side image shown only to relevant viewers
	var/image/mark_image
	/// List of clients currently seeing this indicator
	var/list/client/viewing_clients = list()
	/// List of mobs who have marked this target (for multi-marker support)
	var/list/mob/living/markers = list()

/datum/status_effect/display/seven_mark_indicator/on_creation(mob/living/new_owner, mob/living/marker)
	if(marker)
		markers += marker
	return ..()

/datum/status_effect/display/seven_mark_indicator/on_apply()
	// Don't call parent — we handle icon display ourselves via client images, not global overlays.
	UpdateStatusDisplay()
	return TRUE

/datum/status_effect/display/seven_mark_indicator/on_remove()
	remove_from_all_clients()
	mark_image = null
	// Don't call parent's on_remove since we didn't use icon_overlay/add_overlay

/// Override: Create a client-side image visible only to the target and marker(s).
/datum/status_effect/display/seven_mark_indicator/AddDisplayIcon(position)
	// Clean up previous image
	remove_from_all_clients()
	// Create the client-side image
	mark_image = image('ModularLobotomy/_Lobotomyicons/tegu_effects10x10.dmi', owner, display_name, -MUTATIONS_LAYER)
	// Position using the same grid as other display effects
	var/column = (WRAP(position, 0, 4) * 10) + (-5)
	var/row = 33 + (round(position * 0.25) * 10)
	mark_image.pixel_x = column
	mark_image.pixel_y = row
	// Add to relevant clients
	add_to_viewers()

/// Add the mark image to the target's client and all marker clients.
/datum/status_effect/display/seven_mark_indicator/proc/add_to_viewers()
	if(!mark_image)
		return
	// Target can see their own mark
	if(owner.client)
		owner.client.images |= mark_image
		viewing_clients |= owner.client
	// Each Seven member who marked this target can see it
	for(var/mob/living/marker in markers)
		if(marker.client)
			marker.client.images |= mark_image
			viewing_clients |= marker.client

/// Remove the image from all viewing clients.
/datum/status_effect/display/seven_mark_indicator/proc/remove_from_all_clients()
	if(!mark_image)
		return
	for(var/client/C in viewing_clients)
		C.images -= mark_image
	viewing_clients.Cut()

/// Refresh which clients can see this indicator.
/datum/status_effect/display/seven_mark_indicator/proc/refresh_viewers()
	remove_from_all_clients()
	add_to_viewers()

/// Add a new marker (Seven member) who can see this indicator.
/datum/status_effect/display/seven_mark_indicator/proc/add_marker(mob/living/marker)
	if(!(marker in markers))
		markers += marker
	if(marker.client && mark_image)
		marker.client.images |= mark_image
		viewing_clients |= marker.client

/// Remove a marker. If no markers remain, remove the status effect entirely.
/datum/status_effect/display/seven_mark_indicator/proc/remove_marker(mob/living/marker)
	markers -= marker
	if(marker.client && mark_image)
		marker.client.images -= mark_image
		viewing_clients -= marker.client
	// If no one is marking this target anymore, remove the effect
	if(!length(markers))
		qdel(src)
