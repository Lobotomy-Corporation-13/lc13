/// Action that lets association members designate other players as allies.
/// Allies benefit from protective and buff skills. Squad members are auto-designated.
/datum/action/cooldown/designate_ally
	name = "Designate Ally"
	desc = "Select a nearby player to add or remove from your ally list. Allies benefit from your protective skills."
	icon_icon = 'icons/hud/screen_skills.dmi'
	button_icon_state = "reraise"
	cooldown_time = 1 SECONDS

/datum/action/cooldown/designate_ally/Trigger()
	. = ..()
	if(!.)
		return FALSE
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/H = owner
	var/datum/component/association_exp/exp = H.GetComponent(/datum/component/association_exp)
	if(!exp)
		return FALSE
	// Build list of nearby living player mobs
	var/list/nearby = list()
	for(var/mob/living/L in view(7, get_turf(H)))
		if(L == H)
			continue
		var/status = (L in exp.designated_allies) ? " (REMOVE)" : " (ADD)"
		nearby["[L.name][status]"] = L
	if(!length(nearby))
		// No players nearby — still refresh our ally images (e.g. after aghost re-enter)
		refresh_ally_indicators(H)
		to_chat(H, span_warning("No players nearby to designate. Ally indicators refreshed."))
		StartCooldown()
		return TRUE
	var/choice = tgui_input_list(H, "Select a player to toggle ally status:", "Designate Ally", nearby)
	if(!choice)
		return FALSE
	var/mob/living/target = nearby[choice]
	if(!target || !istype(target))
		return FALSE
	if(QDELETED(target))
		return FALSE
	// If target is an unregistered association fixer/veteran, register them with our squad
	if(!(target in exp.designated_allies) && exp.squad && ishuman(target) && !target.GetComponent(/datum/component/association_exp))
		var/mob/living/carbon/human/target_human = target
		var/target_role = target_human.mind?.assigned_role
		if(target_role == "Association Fixer" || target_role == "Association Veteran")
			var/rank = (target_role == "Association Veteran") ? "veteran" : "associate"
			exp.squad.register_member(target_human, rank)
			exp.squad.spawn_association_items(target_human, rank)
			to_chat(H, span_nicegreen("You have registered [target_human] with [exp.squad.association_name]."))
			to_chat(target_human, span_nicegreen("[H] has registered you with [exp.squad.association_name]. Open your Skill Tree to view your abilities."))
			playsound(get_turf(H), 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
			StartCooldown()
			return TRUE
	if(target in exp.designated_allies)
		exp.designated_allies -= target
		to_chat(H, span_warning("[target] removed from your ally list."))
		to_chat(target, span_warning("You are no longer designated as [H]'s ally."))
		// Remove ally indicator if target is no longer anyone's ally and has no exp component
		if(!target.GetComponent(/datum/component/association_exp))
			if(!check_has_any_allies(target))
				target.remove_status_effect(/datum/status_effect/display/ally_indicator)
	else
		exp.designated_allies += target
		to_chat(H, span_nicegreen("[target] added to your ally list."))
		to_chat(target, span_nicegreen("[H] has designated you as an ally."))
		// Grant ally indicator to target if they don't have one
		if(!target.has_status_effect(/datum/status_effect/display/ally_indicator))
			target.apply_status_effect(/datum/status_effect/display/ally_indicator)
	// Refresh ally indicator visibility for the owner and the target
	refresh_ally_indicators(H)
	refresh_ally_indicators(target)
	// Grant or remove the View Allies action
	update_view_allies_action(target)
	StartCooldown()
	return TRUE

/// Action button that opens the association skill tree UI.
/datum/action/innate/association_skill_tree
	name = "Association Skill Tree"
	desc = "Open your association's skill tree to view and unlock abilities."
	icon_icon = 'icons/hud/screen_skills.dmi'
	button_icon_state = "dantehadd"
	/// The skill tree datum instance for this player
	var/datum/association_skill_tree/tree

/datum/action/innate/association_skill_tree/Activate()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	if(!tree)
		tree = new(H)
	tree.ui_interact(H)

/datum/action/innate/association_skill_tree/Destroy()
	QDEL_NULL(tree)
	return ..()

/datum/action/innate/association_skill_tree/Remove(mob/M)
	QDEL_NULL(tree)
	return ..()

// ============================================================
// View Allies Action (for non-squad designated allies)
// ============================================================

/// Action granted to non-squad members who have been designated as allies.
/// Lets them see who considers them an ally and refreshes ally indicator images.
/datum/action/innate/view_allies
	name = "View Allies"
	desc = "View who considers you an ally and refresh ally indicator icons."
	icon_icon = 'icons/hud/screen_skills.dmi'
	button_icon_state = "reraise_check"

/datum/action/innate/view_allies/Activate()
	if(!isliving(owner))
		return
	var/mob/living/L = owner
	var/list/ally_names = list()
	// Find all squad members who have us as a designated ally
	for(var/datum/association_squad/squad in GLOB.association_squads)
		for(var/mob/living/M in squad.members)
			var/datum/component/association_exp/exp = M.GetComponent(/datum/component/association_exp)
			if(!exp || !(L in exp.designated_allies))
				continue
			ally_names += M.name
			// Re-add their indicator image to our client directly
			if(L.client)
				var/datum/status_effect/display/ally_indicator/ind = M.has_status_effect(/datum/status_effect/display/ally_indicator)
				if(ind && ind.ally_image)
					L.client.images |= ind.ally_image
					ind.viewing_clients |= L.client
	// Also refresh our own indicator if we have one (e.g. if we're also a squad member)
	var/datum/status_effect/display/ally_indicator/own_ind = L.has_status_effect(/datum/status_effect/display/ally_indicator)
	if(own_ind)
		own_ind.refresh_viewers()
	if(length(ally_names))
		to_chat(L, span_notice("You are allied with: [jointext(ally_names, ", ")]. Ally indicators refreshed."))
	else
		to_chat(L, span_warning("No one currently considers you an ally."))

/// Checks if a mob is a designated ally of any squad member across all squads.
/proc/check_has_any_allies(mob/living/target)
	for(var/datum/association_squad/squad in GLOB.association_squads)
		for(var/mob/living/M in squad.members)
			var/datum/component/association_exp/exp = M.GetComponent(/datum/component/association_exp)
			if(exp && (target in exp.designated_allies))
				return TRUE
	return FALSE

/// Grants or removes the View Allies action based on team/ally status.
/// Squad members (with association_exp) always get it.
/// Non-squad members get it if at least one squad member has them as a designated ally.
/proc/update_view_allies_action(mob/living/target)
	var/datum/action/innate/view_allies/existing = locate() in target.actions
	// Squad members always get View Allies
	if(target.GetComponent(/datum/component/association_exp))
		if(!existing)
			var/datum/action/innate/view_allies/va = new()
			va.Grant(target)
		return
	// Non-squad: grant/remove based on whether anyone has them as an ally
	if(check_has_any_allies(target))
		if(!existing)
			var/datum/action/innate/view_allies/va = new()
			va.Grant(target)
	else
		if(existing)
			existing.Remove(target)
			qdel(existing)

// ============================================================
// Ally Indicator Display Status Effect
// ============================================================

/// Refreshes ally indicator visibility for any mob with the ally indicator.
/// Call this whenever the designated_allies list changes.
/proc/refresh_ally_indicators(mob/living/member)
	var/datum/status_effect/display/ally_indicator/indicator = member.has_status_effect(/datum/status_effect/display/ally_indicator)
	if(indicator)
		indicator.refresh_viewers()

/// Display status effect that shows a small icon over an association member's head.
/// Only visible to designated allies and the owner themselves via client-side images.
/datum/status_effect/display/ally_indicator
	id = "ally_indicator"
	duration = -1
	tick_interval = -1
	alert_type = null
	display_name = "shock"
	/// The client-side image shown only to allies
	var/image/ally_image
	/// List of clients currently seeing this indicator
	var/list/client/viewing_clients = list()

/datum/status_effect/display/ally_indicator/on_apply()
	// Don't call parent — we handle icon display ourselves via client images, not overlays.
	// But we still need to trigger display sorting for other effects on this mob.
	UpdateStatusDisplay()
	return TRUE

/datum/status_effect/display/ally_indicator/on_remove()
	remove_from_all_clients()
	ally_image = null
	// Don't call parent's on_remove since we didn't use icon_overlay/add_overlay

/// Override: Instead of adding a global overlay, create a client-side image visible only to allies.
/datum/status_effect/display/ally_indicator/AddDisplayIcon(position)
	// Clean up previous image from all clients
	remove_from_all_clients()
	// Create the client-side image
	ally_image = image('ModularLobotomy/_Lobotomyicons/tegu_effects10x10.dmi', owner, display_name, -MUTATIONS_LAYER)
	// Position it using the same sorting grid as other display effects
	// Constants from status_effect.dm: ROW_MIN=0, ROW_MAX=4, WIDTH=10, HEIGHT=10, OFFSET=-5
	var/column = (WRAP(position, 0, 4) * 10) + (-5)
	var/row = 33 + (round(position * 0.25) * 10)
	ally_image.pixel_x = column
	ally_image.pixel_y = row
	// Add to allied clients
	add_to_allied_clients()

/// Add the image to all allied players' clients (and the owner's client).
/// Checks both directions: the owner's ally list AND anyone who has the owner as their ally.
/datum/status_effect/display/ally_indicator/proc/add_to_allied_clients()
	if(!ally_image)
		return
	// Owner can always see their own indicator
	if(owner.client)
		owner.client.images |= ally_image
		viewing_clients |= owner.client
	// Forward: show to the owner's designated allies (if owner has exp)
	var/datum/component/association_exp/exp = owner.GetComponent(/datum/component/association_exp)
	if(exp)
		for(var/mob/living/ally in exp.designated_allies)
			if(ally.client)
				ally.client.images |= ally_image
				viewing_clients |= ally.client
	// Reverse: show to anyone who has the owner as THEIR designated ally
	for(var/datum/association_squad/squad in GLOB.association_squads)
		for(var/mob/living/M in squad.members)
			if(M == owner)
				continue
			var/datum/component/association_exp/member_exp = M.GetComponent(/datum/component/association_exp)
			if(member_exp && (owner in member_exp.designated_allies))
				if(M.client)
					M.client.images |= ally_image
					viewing_clients |= M.client

/// Remove the image from all clients that are currently viewing it.
/datum/status_effect/display/ally_indicator/proc/remove_from_all_clients()
	if(!ally_image)
		return
	for(var/client/C in viewing_clients)
		C.images -= ally_image
	viewing_clients.Cut()

/// Refresh which clients can see this indicator. Called when allies change.
/datum/status_effect/display/ally_indicator/proc/refresh_viewers()
	remove_from_all_clients()
	add_to_allied_clients()
