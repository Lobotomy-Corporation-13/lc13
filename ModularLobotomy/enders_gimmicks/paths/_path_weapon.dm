// ============================================================
// Path Weapon - Custom EGO weapon for the Paths system
// ============================================================
// Each path provides a custom weapon where:
//   attack()      = Basic Attack (path damage, no LC13 damage)
//   attack_self() = Burst/Skill (5s cooldown + AP cost)
// Ultimate and Passive are handled separately (action button + signals).
//
// force = 0 ensures attacked_by() in item_attack.dm skips
// the entire LC13 damage formula. Path damage is applied
// directly via linked_path.OnWeaponHit().
// ============================================================

/obj/item/ego_weapon/path_weapon
	name = "Path Weapon"
	desc = "A weapon manifested from your chosen path."
	icon = 'icons/obj/ego_weapons.dmi'
	icon_state = "penitence"
	force = 0
	damtype = RED_DAMAGE
	attribute_requirements = list()
	knockback = FALSE
	w_class = WEIGHT_CLASS_BULKY
	swingstyle = WEAPONSWING_SMALLSWEEP

	/// Reference to the owning path datum
	var/datum/path/linked_path

	/// The EGO weapon type currently being mimicked (null = default appearance)
	var/disguised_as_type

	/// Stored base attack speed before disguise modification
	var/base_attack_speed = 1

/obj/item/ego_weapon/path_weapon/Initialize()
	. = ..()
	base_attack_speed = attack_speed

// ---- Core Attack Procs ----

/// Override attack to deal path damage instead of LC13 damage
/obj/item/ego_weapon/path_weapon/attack(mob/living/target, mob/living/user)
	if(!linked_path)
		to_chat(user, span_warning("This weapon has no path linked!"))
		return FALSE
	// Play our own hitsound since force=0 would play tap.ogg
	if(hitsound)
		playsound(loc, hitsound, get_clamped_volume(), TRUE, -1)
	. = ..()
	if(!.)
		return
	if(!isliving(target))
		return
	// Path damage is dealt here — attacked_by() did nothing (force=0)
	// OnWeaponHit handles per-swing damage scaling and turn-based AP/energy gating
	linked_path.OnWeaponHit(target, user)

/// Override attack_self for Burst/Skill activation (consumes the current turn)
/obj/item/ego_weapon/path_weapon/attack_self(mob/living/user)
	if(!linked_path || !linked_path.burst_action)
		return
	// Turn system check: must be in READY state (not already attacked or skilled this turn)
	if(linked_path.turn_state != PATH_TURN_READY)
		to_chat(user, span_warning("You already acted this turn! Wait for next turn."))
		return
	if(linked_path.action_points < linked_path.burst_action.ap_cost)
		to_chat(user, span_warning("Not enough Action Points! ([linked_path.action_points]/[linked_path.burst_action.ap_cost])"))
		return
	linked_path.SpendActionPoint()
	linked_path.GainEnergy(linked_path.burst_action.energy_gain)
	linked_path.burst_action.Activate(user)
	linked_path.turn_state = PATH_TURN_SKILLED

/// Path weapons are always usable if linked to a valid path
/obj/item/ego_weapon/path_weapon/CanUseEgo(mob/living/user)
	return !!linked_path

// ---- Examine ----

/// Override examine to show path info instead of standard EGO weapon stats
/obj/item/ego_weapon/path_weapon/examine(mob/user)
	. = ..()
	if(!linked_path)
		. += span_warning("This weapon has no path linked.")
		return

	. += span_notice("<b>Path:</b> [linked_path.name]")
	. += span_notice("[linked_path.desc]")

	// Path stats
	var/atk = linked_path.GetStat("ATK")
	var/spd = linked_path.GetStat("SPD")
	. += span_notice("<b>ATK:</b> [atk] | <b>SPD:</b> [spd]")

	// Abilities
	if(linked_path.basic_attack)
		. += span_notice("<b>Basic:</b> [linked_path.basic_attack.name] (Lv.[linked_path.basic_attack.level])")
	if(linked_path.burst_action)
		. += span_notice("<b>Skill:</b> [linked_path.burst_action.name] (Lv.[linked_path.burst_action.level]) — Z key, [linked_path.burst_action.ap_cost] AP, costs 1 turn")
	if(linked_path.ultimate_action)
		. += span_notice("<b>Ultimate:</b> [linked_path.ultimate_action.name] (Lv.[linked_path.ultimate_action.level])")
	if(linked_path.passive_effect)
		. += span_notice("<b>Passive:</b> [linked_path.passive_effect.name] (Lv.[linked_path.passive_effect.level])")

	// Resources
	. += span_notice("<b>Energy:</b> [linked_path.energy]/[linked_path.max_energy]")
	. += span_notice("<b>AP:</b> [linked_path.action_points]/[linked_path.max_action_points]")

	// Turn system info
	var/turn_dur = round(linked_path.GetTurnDuration() / 10, 0.1)
	switch(linked_path.turn_state)
		if(PATH_TURN_READY)
			. += span_nicegreen("Turn: READY ([turn_dur]s per turn)")
		if(PATH_TURN_ATTACKED)
			var/remaining = round(max(linked_path.next_turn_time - world.time, 0) / 10, 0.1)
			. += span_warning("Turn: ATTACKED (next turn in [remaining]s)")
		if(PATH_TURN_SKILLED)
			var/remaining = round(max(linked_path.next_turn_time - world.time, 0) / 10, 0.1)
			. += span_warning("Turn: SKILLED (next turn in [remaining]s)")

	// Disguise info
	if(disguised_as_type)
		. += span_notice("<i>(Appearance copied from another EGO weapon)</i>")

/// Override EgoAttackInfo to show path damage info
/obj/item/ego_weapon/path_weapon/EgoAttackInfo(mob/user)
	if(!linked_path)
		return span_notice("No path linked.")
	var/atk = linked_path.GetStat("ATK")
	return span_notice("Path ATK: [atk] ([linked_path.name])")

// ---- Appearance Disguise System ----

/// Opens selection list of EGO weapons to copy appearance from
/obj/item/ego_weapon/path_weapon/proc/SelectDisguise(mob/user)
	var/list/ego_options = list()
	for(var/ego_type in subtypesof(/obj/item/ego_weapon))
		// Exclude path weapons from the list
		if(ispath(ego_type, /obj/item/ego_weapon/path_weapon))
			continue
		var/obj/item/ego_weapon/E = ego_type
		var/ego_name = initial(E.name)
		var/ego_icon = initial(E.icon_state)
		if(!ego_icon)
			continue
		ego_options["[ego_name]"] = ego_type

	var/picked = input(user, "Select weapon appearance:", "Path Weapon Disguise") as null|anything in sortList(ego_options)
	if(!picked || !user.Adjacent(src))
		return
	var/picked_type = ego_options[picked]
	if(!picked_type)
		return
	ApplyDisguise(picked_type)
	to_chat(user, span_notice("Your path weapon now resembles [picked]."))

/// Copies visual and feel properties from an EGO weapon type
/obj/item/ego_weapon/path_weapon/proc/ApplyDisguise(ego_type)
	var/obj/item/ego_weapon/E = ego_type

	// Visual properties
	name = initial(E.name)
	desc = initial(E.desc)
	icon = initial(E.icon)
	icon_state = initial(E.icon_state)
	inhand_icon_state = initial(E.inhand_icon_state)
	lefthand_file = initial(E.lefthand_file)
	righthand_file = initial(E.righthand_file)
	inhand_x_dimension = initial(E.inhand_x_dimension)
	inhand_y_dimension = initial(E.inhand_y_dimension)

	// Sound
	hitsound = initial(E.hitsound)

	// Mechanical feel (does NOT affect path damage)
	swingstyle = initial(E.swingstyle)
	reach = initial(E.reach)
	attack_speed = initial(E.attack_speed)

	// Validate swingstyle/reach combo
	if(swingstyle == WEAPONSWING_SMALLSWEEP && reach > 1)
		swingstyle = WEAPONSWING_THRUST

	disguised_as_type = ego_type
	update_icon()

	// Update held appearance if someone is holding it
	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_hands()

/// Restores the weapon to its original path appearance
/obj/item/ego_weapon/path_weapon/proc/ClearDisguise()
	name = initial(name)
	desc = initial(desc)
	icon = initial(icon)
	icon_state = initial(icon_state)
	inhand_icon_state = initial(inhand_icon_state)
	lefthand_file = initial(lefthand_file)
	righthand_file = initial(righthand_file)
	inhand_x_dimension = initial(inhand_x_dimension)
	inhand_y_dimension = initial(inhand_y_dimension)
	hitsound = initial(hitsound)
	swingstyle = initial(swingstyle)
	reach = initial(reach)
	attack_speed = base_attack_speed

	disguised_as_type = null
	update_icon()

	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_hands()

// ---- Disguise Action Button ----

/// HUD action button for changing weapon appearance
/datum/action/item_action/path_weapon_disguise
	name = "Change Weapon Appearance"
	desc = "Copy the appearance of any EGO weapon onto your path weapon."
	icon_icon = 'icons/hud/actions.dmi'
	button_icon_state = "yourstate"

/datum/action/item_action/path_weapon_disguise/Trigger()
	. = ..()
	if(!.)
		return
	var/obj/item/ego_weapon/path_weapon/PW = target
	if(!istype(PW))
		return
	PW.SelectDisguise(owner)
