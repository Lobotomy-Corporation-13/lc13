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
	icon_icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'
	button_icon_state = "stardust_ace"
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
	icon_icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'
	button_icon_state = "path_icon"
	/// Reference to the owning path datum
	var/datum/path/linked_path

/datum/action/path_screen/Trigger()
	. = ..()
	if(!.)
		return
	if(!linked_path)
		return
	linked_path.ui_interact(owner)

// ---- Recall Weapon Action ----

/// HUD button for recalling the path weapon to the user's hands
/datum/action/path_recall_weapon
	name = "Recall Weapon"
	desc = "Recall your path weapon to your hands."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/enders_sprites_32x32.dmi'
	button_icon_state = "recall_weapon"
	/// Reference to the owning path datum
	var/datum/path/linked_path

/datum/action/path_recall_weapon/Trigger()
	. = ..()
	if(!.)
		return
	if(!linked_path)
		return
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner

	// Check if weapon still exists
	if(linked_path.weapon && !QDELETED(linked_path.weapon))
		// Already in our hands
		if(linked_path.weapon.loc == H)
			to_chat(H, span_warning("Your path weapon is already in your hands."))
			return
		// Teleport it back
		linked_path.weapon.forceMove(H)
		H.put_in_hands(linked_path.weapon)
		to_chat(H, span_nicegreen("Your path weapon materializes in your hands!"))
	else
		// Weapon was deleted — create a new one
		linked_path.weapon = new linked_path.path_weapon_type()
		linked_path.weapon.linked_path = linked_path
		H.put_in_hands(linked_path.weapon)
		to_chat(H, span_nicegreen("A new path weapon manifests in your hands!"))

	playsound(get_turf(H), 'sound/weapons/saberon.ogg', 40, TRUE)
