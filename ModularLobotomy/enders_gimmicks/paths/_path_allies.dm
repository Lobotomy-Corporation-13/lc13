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

	// Build list of nearby living humans
	var/list/nearby = list()
	for(var/mob/living/carbon/human/L in view(7, get_turf(H)))
		if(L == H)
			continue
		if(L.stat == DEAD)
			continue
		var/status = (L in allies) ? " (REMOVE)" : " (ADD)"
		nearby["[L.name][status]"] = L

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

	if(target in allies)
		allies -= target
		to_chat(H, span_warning("[target] removed from your ally list."))
		to_chat(target, span_warning("You are no longer designated as [H]'s ally."))
	else
		allies += target
		to_chat(H, span_nicegreen("[target] added to your ally list."))
		to_chat(target, span_nicegreen("[H] has designated you as an ally. You benefit from their path abilities."))

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
	if(allies)
		for(var/mob/living/ally in allies)
			to_chat(ally, span_warning("You are no longer designated as [H]'s ally."))
	GLOB.path_ally_lists -= H

/// Checks if a target is an ally of the source mob
/proc/IsPathAlly(mob/living/source, mob/living/target)
	if(source == target)
		return TRUE
	var/list/allies = GLOB.path_ally_lists[source]
	if(!allies)
		return FALSE
	return (target in allies)

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
