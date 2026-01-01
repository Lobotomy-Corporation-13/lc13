/**
 * Faith Event System for Resurgence Machines
 *
 * Faith events are temporary or permanent modifiers that affect the RATE
 * at which a machine's faith changes. Positive values increase faith over time,
 * negative values decrease it.
 *
 * Categories ensure only one event of each type can be active at once.
 */

/datum/faith_event
	/// Text description shown to player when checking faith
	var/description = ""
	/// Rate of faith change per second (positive = gaining, negative = losing)
	var/faith_change = 0
	/// Duration before event expires in deciseconds (null = permanent until cleared)
	var/timeout = null
	/// Category key - only one event per category can be active
	var/category = "generic"
	/// If TRUE, not shown in faith check display
	var/hidden = FALSE
	/// Reference to the core this event is attached to
	var/obj/item/organ/resurgence_core/parent_core
	/// World time when this event expires (null = permanent)
	var/expiration_time = null

/datum/faith_event/New(desc, change, time = null, cat = "generic", hidden_event = FALSE)
	. = ..()
	description = desc
	faith_change = change
	timeout = time
	category = cat
	hidden = hidden_event
	if(timeout)
		expiration_time = world.time + timeout
		addtimer(CALLBACK(src, PROC_REF(expire)), timeout)

/// Returns the time remaining in seconds, or null if permanent
/datum/faith_event/proc/get_time_remaining()
	if(!expiration_time)
		return null
	var/remaining = expiration_time - world.time
	if(remaining <= 0)
		return 0
	return round(remaining / 10) // Convert deciseconds to seconds

/datum/faith_event/Destroy()
	if(parent_core)
		parent_core.on_faith_event_deleted(src)
		parent_core = null
	return ..()

/// Called when the timeout expires
/datum/faith_event/proc/expire()
	qdel(src)

/// Sets the parent core reference
/datum/faith_event/proc/set_parent(obj/item/organ/resurgence_core/core)
	parent_core = core

// ============================================
// Specific Faith Event Subtypes
// ============================================

/// Faith events from wearing clan-woven clothing (permanent until clothing removed)
/datum/faith_event/clothing
	category = "clothing"

/datum/faith_event/clothing/New(desc, change, cat = "clothing")
	description = desc
	faith_change = change
	category = cat
	timeout = null // Permanent - removed when clothing is unequipped
	hidden = FALSE

/// Faith events from being in a designated shelter/room
/datum/faith_event/shelter
	category = "shelter"

/// Faith events from being near other machines
/datum/faith_event/community
	category = "community"

/// Faith events from contributing to the monument
/datum/faith_event/monument
	category = "monument"

/// Faith events related to sustenance (recharging)
/datum/faith_event/sustenance
	category = "sustenance"

/// Faith events from witnessing death
/datum/faith_event/death
	category = "death"

/// Faith events from being injured
/datum/faith_event/injury
	category = "injury"

/// Faith events from low charge anxiety
/datum/faith_event/charge_anxiety
	category = "charge_anxiety"

/// Faith events from room type bonuses
/datum/faith_event/room
	category = "room"

/// Debug faith event for testing
/datum/faith_event/debug
	category = "debug"

/// Faith events from room ownership status (having a personal room or being homeless)
/datum/faith_event/room_ownership
	category = "room_ownership"

/// Faith events from room quality/beauty level
/datum/faith_event/room_quality
	category = "room_quality"

/// Faith events from being in a cramped room
/datum/faith_event/room_cramped
	category = "room_cramped"

/// Faith events from eating in a common room
/datum/faith_event/common_eating
	category = "common_eating"

/// Faith events from eating quality food (1 minute duration)
/datum/faith_event/meal_quality
	category = "meal_quality"

/// Faith events for newcomers (grace period to find a home)
/datum/faith_event/newcomer
	category = "newcomer"
