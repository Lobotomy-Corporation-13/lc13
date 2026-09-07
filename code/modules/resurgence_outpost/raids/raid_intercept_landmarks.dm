/**
 * Raid Intercept Landmarks
 *
 * Landmarks used in the raid intercept encounter map.
 * These define spawn points for players, enemies, loot, and exits.
 */

/**
 * Player spawn point
 * Players are teleported here when the intercept begins
 */
/obj/effect/landmark/raid_intercept_spawn
	name = "raid intercept spawn"
	invisibility = INVISIBILITY_ABSTRACT

/**
 * Enemy spawn point
 * Raiders spawn at these locations
 * Multiple should be placed around the map
 */
/obj/effect/landmark/raid_intercept_enemy
	name = "raid intercept enemy spawn"
	invisibility = INVISIBILITY_ABSTRACT

/**
 * Exit point
 * Players walk here to leave the encounter after victory
 */
/obj/effect/landmark/raid_intercept_exit
	name = "exit portal"
	desc = "A shimmering portal back to the expedition."
	icon = 'icons/effects/effects.dmi'
	icon_state = "sparks"
	/// Whether the exit is currently enabled
	var/enabled = FALSE

/obj/effect/landmark/raid_intercept_exit/Initialize(mapload)
	. = ..()
	// Start invisible
	invisibility = INVISIBILITY_ABSTRACT
	alpha = 0

/**
 * Enable the exit portal
 */
/obj/effect/landmark/raid_intercept_exit/proc/enable()
	enabled = TRUE
	invisibility = 0
	alpha = 255
	name = "exit portal"
	desc = "A shimmering portal back to the expedition. Step through to leave."

/obj/effect/landmark/raid_intercept_exit/Crossed(atom/movable/AM, oldloc)
	. = ..()
	if(!enabled)
		return
	if(!isliving(AM))
		return

	var/mob/living/M = AM
	if(!GLOB.raid_intercept_controller)
		return

	// Check if this mob is part of the expedition
	var/datum/raid_intercept_controller/controller = GLOB.raid_intercept_controller
	if(!controller.expedition)
		return
	if(!(M in controller.expedition.members))
		return

	// Show confirmation
	var/choice = tgui_alert(M, "Leave the encounter and return to your expedition?", "Exit Intercept", list("Leave", "Stay"))
	if(choice != "Leave")
		return

	// Check we're still valid
	if(!GLOB.raid_intercept_controller)
		return

	var/datum/raid_intercept_controller/ctrl = GLOB.raid_intercept_controller
	ctrl.return_to_expedition()

/obj/effect/landmark/raid_intercept_exit/examine(mob/user)
	. = ..()
	if(enabled)
		. += span_notice("Step through to return to your expedition.")
	else
		. += span_warning("The portal is not yet active. Defeat all enemies first.")

/**
 * Loot spawn point
 * Rewards are spawned here after victory
 */
/obj/effect/landmark/raid_intercept_loot
	name = "raid intercept loot spawn"
	invisibility = INVISIBILITY_ABSTRACT

/**
 * Flee point
 * Players can walk here to flee the battle (with consequences)
 */
/obj/effect/landmark/raid_intercept_flee
	name = "escape route"
	desc = "A path to flee the battle. The raiders will continue to the outpost."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shield-flash"
	invisibility = 0

/obj/effect/landmark/raid_intercept_flee/Crossed(atom/movable/AM, oldloc)
	. = ..()
	if(!isliving(AM))
		return

	var/mob/living/M = AM
	if(!GLOB.raid_intercept_controller)
		return

	// Check if this mob is part of the expedition
	var/datum/raid_intercept_controller/controller = GLOB.raid_intercept_controller
	if(!controller.expedition)
		return
	if(!(M in controller.expedition.members))
		return

	// Show warning
	var/choice = tgui_alert(M, "Flee the battle? The raiding party will continue to your outpost!", "Flee?", list("Flee", "Stay and Fight"))
	if(choice != "Flee")
		return

	// Check we're still valid
	if(!GLOB.raid_intercept_controller)
		return

	var/datum/raid_intercept_controller/ctrl = GLOB.raid_intercept_controller
	ctrl.player_fled(M)

/obj/effect/landmark/raid_intercept_flee/examine(mob/user)
	. = ..()
	. += span_warning("Use this to flee the battle. Warning: The raiders will continue to your outpost!")
