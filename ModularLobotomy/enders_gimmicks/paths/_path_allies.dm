// ============================================================
// Path Ally System
// ============================================================
// Allows Pathstriders to designate nearby humans as allies.
// Allies benefit from supportive path abilities (Harmony buffs,
// Preservation shields, Abundance heals, etc.).
//
// Based on the association designate_ally pattern but tied to
// the path system instead of association squads.
// ============================================================

/// List of path allies per mob, stored globally since multiple systems may query it
GLOBAL_LIST_EMPTY(path_ally_lists)

/// X offset for the overhead marker. Mirrors STATUS_ICON_OFFSET in
/// status_effect.dm, which is #undef'd at the end of that file.
#define STATUS_ICON_OFFSET_LOCAL -5

// ---- Designate Ally Action ----

/// Action that lets Pathstriders designate nearby humans as allies.
/datum/action/cooldown/path_designate_ally
	name = "Designate Ally"
	desc = "Select a nearby player to add or remove from your ally list. Allies benefit from your supportive path abilities."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'
	button_icon_state = "pick_allies"
	cooldown_time = 1 SECONDS
	/// Reference to the owning path datum
	var/datum/path/linked_path

/datum/action/cooldown/path_designate_ally/Trigger()
	. = ..()
	if(!.)
		return FALSE
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/H = owner
	var/list/allies = GetAllyList(H)

	// Show current allies
	if(length(allies))
		var/list/ally_names = list()
		for(var/mob/living/ally in allies)
			if(QDELETED(ally))
				continue
			ally_names += ally.name
		if(length(ally_names))
			to_chat(H, span_notice("<b>Current allies:</b> [ally_names.Join(", ")]"))
		else
			to_chat(H, span_notice("<b>Current allies:</b> None"))
	else
		to_chat(H, span_notice("<b>Current allies:</b> None"))

	// Build list of nearby living humans. Existing allies also get a FOCUS entry,
	// so single-target support can be aimed instead of always hitting whoever
	// happens to be closest.
	var/list/nearby = list()
	for(var/mob/living/carbon/human/L in view(7, get_turf(H)))
		if(L == H)
			continue
		if(L.stat == DEAD)
			continue
		if(L in allies)
			nearby["[L.name] (REMOVE)"] = L
			if(linked_path && linked_path.focus_ally != L)
				nearby["[L.name] (FOCUS)"] = L
		else
			nearby["[L.name] (ADD)"] = L

	if(!length(nearby))
		to_chat(H, span_warning("No players nearby to designate as allies."))
		StartCooldown()
		return TRUE

	var/choice = tgui_input_list(H, "Select a player to toggle ally status:", "Designate Ally", nearby)
	if(!choice)
		return FALSE
	var/mob/living/carbon/human/target = nearby[choice]
	if(!target || QDELETED(target))
		return FALSE

	// Focus does not change designation, it just aims support abilities
	if(findtext(choice, "(FOCUS)"))
		if(linked_path)
			linked_path.focus_ally = target
			to_chat(H, span_nicegreen("Support abilities will now prioritise [target]."))
		StartCooldown()
		return TRUE

	if(target in allies)
		allies -= target
		to_chat(H, span_warning("[target] removed from your ally list."))
		to_chat(target, span_warning("You are no longer designated as [H]'s ally."))
		// Drop the marker once nobody has them designated any more
		if(!HasAnyPathAlly(target))
			target.remove_status_effect(/datum/status_effect/display/path_ally_indicator)
	else
		allies += target
		to_chat(H, span_nicegreen("[target] added to your ally list."))
		to_chat(target, span_nicegreen("[H] has designated you as an ally. You benefit from their path abilities."))
		if(!target.has_status_effect(/datum/status_effect/display/path_ally_indicator))
			target.apply_status_effect(/datum/status_effect/display/path_ally_indicator)
		if(IsMutualPathAlly(H, target))
			to_chat(H, span_nicegreen("You and [target] are now mutual allies. Action Points are shared between you."))
			to_chat(target, span_nicegreen("You and [H] are now mutual allies. Action Points are shared between you."))

	// Designation changed on both sides, so both markers may need restating
	RefreshPathAllyIndicator(H)
	RefreshPathAllyIndicator(target)

	StartCooldown()
	return TRUE

// ---- Ally List Management ----

/// Gets or creates the ally list for a mob
/proc/GetAllyList(mob/living/carbon/human/H)
	if(!GLOB.path_ally_lists[H])
		GLOB.path_ally_lists[H] = list()
	return GLOB.path_ally_lists[H]

/// Clears a mob's ally list (called on path removal)
/proc/ClearAllyList(mob/living/carbon/human/H)
	// Notify allies they're being removed
	var/list/allies = GLOB.path_ally_lists[H]
	var/list/former = allies ? allies.Copy() : list()
	if(allies)
		for(var/mob/living/ally in allies)
			to_chat(ally, span_warning("You are no longer designated as [H]'s ally."))
	GLOB.path_ally_lists -= H
	// Their markers may no longer be warranted, and ours is stale either way
	for(var/mob/living/ally in former)
		if(QDELETED(ally))
			continue
		if(!HasAnyPathAlly(ally))
			ally.remove_status_effect(/datum/status_effect/display/path_ally_indicator)
		else
			RefreshPathAllyIndicator(ally)
	if(!QDELETED(H))
		H.remove_status_effect(/datum/status_effect/display/path_ally_indicator)

/// Resolves a mob found by an ability's target scan into the thing that should
/// actually be hit, or null if it is not a valid target.
///
/// Multitile mobs are represented on their outer tiles by invisible
/// projectile blocker dummies, which forward damage to the mob they belong to.
/// A scan that returns the dummy has really found the mob, so resolve to the
/// parent rather than discarding the hit; discarding it would make large mobs
/// unhittable whenever the scan only reaches their edge tiles.
///
/// Callers scanning an area should keep a seen-list, since several dummies of
/// one mob can resolve to the same parent.
/proc/GetPathTarget(mob/living/L, mob/living/user)
	if(!istype(L) || L == user)
		return null
	if(istype(L, /mob/living/simple_animal/projectile_blocker_dummy))
		var/mob/living/simple_animal/projectile_blocker_dummy/blocker = L
		L = blocker.parent
		if(!istype(L) || L == user)
			return null
	if(L.stat == DEAD)
		return null
	// Contained/invulnerable things must not soak abilities or grant resources
	if(L.status_flags & GODMODE)
		return null
	// The crew are not targets at all while the trait runs, so area scans skip
	// them outright rather than selecting them and then dealing nothing.
	if(!PathCanHarm(L))
		return null
	if(IsPathAlly(user, L))
		return null
	return L

/// Checks if a target is an ally of the source mob
/proc/IsPathAlly(mob/living/source, mob/living/target)
	if(source == target)
		return TRUE
	var/list/allies = GLOB.path_ally_lists[source]
	if(!allies)
		return FALSE
	return (target in allies)

// ---- Ally Indicator ----
// A marker over a designated ally's head, shown only to the players involved.
// Ported from the association pattern in associations/skills/_designate_ally.dm;
// the path ally list had the designation toggle but none of the visual layer,
// so there was no way to tell who your allies were.
//
// Each viewer gets their own image, because whether a designation is mutual
// depends on who is looking. Mutual matters: GetMutualPathAllies() only shares
// AP between players who have designated each other.

/// TRUE when both mobs have designated each other.
/proc/IsMutualPathAlly(mob/living/a, mob/living/b)
	return IsPathAlly(a, b) && IsPathAlly(b, a)

/// Everyone who should be able to see `subject`'s indicator: the subject, the
/// people they designated, and the people who designated them.
/proc/GetPathIndicatorViewers(mob/living/subject)
	var/list/viewers = list(subject)
	var/list/theirs = GLOB.path_ally_lists[subject]
	if(theirs)
		for(var/mob/living/ally in theirs)
			if(!QDELETED(ally))
				viewers |= ally
	for(var/mob/living/other in GLOB.path_ally_lists)
		if(QDELETED(other) || other == subject)
			continue
		var/list/their_allies = GLOB.path_ally_lists[other]
		if(their_allies && (subject in their_allies))
			viewers |= other
	return viewers

/// TRUE if anyone still has `target` designated, i.e. the indicator should stay.
/proc/HasAnyPathAlly(mob/living/target)
	for(var/mob/living/other in GLOB.path_ally_lists)
		if(QDELETED(other) || other == target)
			continue
		var/list/allies = GLOB.path_ally_lists[other]
		if(allies && (target in allies))
			return TRUE
	return FALSE

/// Rebuilds a mob's indicator viewers after any designation change.
/proc/RefreshPathAllyIndicator(mob/living/target)
	var/datum/status_effect/display/path_ally_indicator/ind = target.has_status_effect(/datum/status_effect/display/path_ally_indicator)
	if(ind)
		ind.RefreshViewers()

/datum/status_effect/display/path_ally_indicator
	id = "path_ally_indicator"
	duration = -1
	tick_interval = -1
	alert_type = null
	display_icon = 'ModularLobotomy/_Lobotomyicons/path_ally.dmi'
	display_name = "path_ally"
	/// client -> the image that client is currently shown
	var/list/viewer_images = list()
	/// Grid offsets handed to us by the last AddDisplayIcon call
	var/icon_px = STATUS_ICON_OFFSET_LOCAL
	var/icon_py = 33

/datum/status_effect/display/path_ally_indicator/on_apply()
	// Not calling parent: the marker is per-viewer rather than a global overlay,
	// but display sorting for other effects on this mob still has to run.
	UpdateStatusDisplay()
	return TRUE

/datum/status_effect/display/path_ally_indicator/on_remove()
	ClearViewers()

/datum/status_effect/display/path_ally_indicator/AddDisplayIcon(position)
	// Same sorting grid the other display effects use. The constants in
	// status_effect.dm are #undef'd at the end of that file, so they are
	// repeated here exactly as the association implementation does.
	icon_px = (WRAP(position, 0, 4) * 10) + STATUS_ICON_OFFSET_LOCAL
	icon_py = 33 + (round(position * 0.25) * 10)
	RefreshViewers()

/// Drops every image we handed out.
/datum/status_effect/display/path_ally_indicator/proc/ClearViewers()
	for(var/client/C in viewer_images)
		C.images -= viewer_images[C]
	viewer_images.Cut()

/// Rebuilds each viewer's image, picking mutual or one-way per viewer.
/datum/status_effect/display/path_ally_indicator/proc/RefreshViewers()
	ClearViewers()
	if(QDELETED(owner))
		return
	for(var/mob/living/viewer in GetPathIndicatorViewers(owner))
		if(!viewer.client)
			continue
		var/state = IsMutualPathAlly(viewer, owner) ? "path_ally_mutual" : "path_ally"
		if(viewer == owner)
			state = HasAnyPathAlly(owner) ? state : "path_ally"
		var/image/marker = image(display_icon, owner, state, -MUTATIONS_LAYER)
		marker.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		marker.pixel_x = icon_px
		marker.pixel_y = icon_py
		viewer.client.images |= marker
		viewer_images[viewer.client] = marker

// ---- Support Targeting ----

/datum/path
	/// Ally that single-target support abilities prefer. Set from the Designate
	/// Ally menu. Falls back to nearest when unset, dead or out of range.
	var/mob/living/focus_ally

/// Picks who a single-target support ability should affect: the focused ally if
/// they are alive and in range, otherwise the nearest designated ally.
/// Returns null when no ally qualifies.
/datum/path/proc/GetSupportTarget(mob/living/user, range_tiles = 7)
	if(focus_ally && !QDELETED(focus_ally) && focus_ally.stat != DEAD)
		if(get_dist(user, focus_ally) <= range_tiles && IsPathAlly(user, focus_ally))
			return focus_ally
	var/mob/living/best_ally
	var/best_dist = INFINITY
	for(var/mob/living/ally in GetAllyList(user))
		if(QDELETED(ally) || ally.stat == DEAD)
			continue
		var/d = get_dist(user, ally)
		if(d <= range_tiles && d < best_dist)
			best_dist = d
			best_ally = ally
	return best_ally

/// Gets all allies within a given range of the source mob (including self)
/proc/GetPathAlliesInRange(mob/living/source, range_tiles)
	var/list/result = list(source)
	var/list/allies = GLOB.path_ally_lists[source]
	if(!allies)
		return result
	for(var/mob/living/ally in allies)
		if(QDELETED(ally) || ally.stat == DEAD)
			continue
		if(get_dist(source, ally) <= range_tiles)
			result += ally
	return result

/// Returns a list of /datum/path objects belonging to allies who:
/// - Are path holders themselves
/// - Have mutually designated `source` as one of their allies
/// Used by the AP-sharing system to propagate gain/spend to teammates.
/proc/GetMutualPathAllies(mob/living/source)
	var/list/result = list()
	if(!ishuman(source))
		return result
	var/list/source_allies = GLOB.path_ally_lists[source]
	if(!source_allies)
		return result
	for(var/mob/living/ally in source_allies)
		if(QDELETED(ally) || ally.stat == DEAD)
			continue
		if(!ishuman(ally))
			continue
		var/mob/living/carbon/human/human_ally = ally
		var/datum/path/ally_path = human_ally.GetPath()
		if(!ally_path)
			continue
		// Must be a mutual designation — ally has source in their list too.
		var/list/their_allies = GLOB.path_ally_lists[ally]
		if(!their_allies || !(source in their_allies))
			continue
		result += ally_path
	return result
