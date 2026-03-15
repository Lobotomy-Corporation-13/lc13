// ============================================================
// Path Actions — HUD Action Buttons
// ============================================================
// Ultimate and Path Screen action buttons granted to pathstriders.
// Burst/Skill is handled by the path weapon's attack_self().
// ============================================================

// ---- Ultimate Action ----

/// HUD button for activating the path's Ultimate ability
/datum/action/path_ultimate
	name = "Ultimate Action"
	desc = "At maximum energy, unleash your path's Ultimate ability."
	icon_icon = 'icons/hud/actions.dmi'
	button_icon_state = "yourstate"
	/// Reference to the owning path datum
	var/datum/path/linked_path

/datum/action/path_ultimate/Trigger()
	. = ..()
	if(!.)
		return
	if(!linked_path || !linked_path.ultimate_action)
		return
	if(linked_path.energy < linked_path.max_energy)
		to_chat(owner, span_warning("Not enough Energy! ([linked_path.energy]/[linked_path.max_energy])"))
		return
	linked_path.ultimate_action.Activate(owner)

/datum/action/path_ultimate/UpdateButtonIcon(status_only, force)
	. = ..()
	if(!linked_path)
		return
	// Could glow/highlight when energy is full
	if(linked_path.energy >= linked_path.max_energy)
		button.color = rgb(255, 255, 100)
	else
		button.color = rgb(255, 255, 255)

// ---- Path Screen Action ----

/// HUD button for opening the Path details and skill tree UI
/datum/action/path_screen
	name = "Path Screen"
	desc = "Open your Path details and skill tree."
	icon_icon = 'icons/hud/actions.dmi'
	button_icon_state = "yourstate"
	/// Reference to the owning path datum
	var/datum/path/linked_path

/datum/action/path_screen/Trigger()
	. = ..()
	if(!.)
		return
	if(!linked_path)
		return
	linked_path.ui_interact(owner)
