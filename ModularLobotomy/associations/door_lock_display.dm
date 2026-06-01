/// A status display that can lock linked airlocks for a set duration.
/// Shares an id_tag with airlocks to control them.
/obj/machinery/status_display/door_lock
	name = "door lock display"
	desc = "A display terminal used to lock doors for a set period of time."
	/// The id_tag used to find linked airlocks.
	var/lock_id = null
	/// The remaining seconds on the lock timer.
	var/time_remaining = 0
	/// Whether the timer is currently active.
	var/timer_active = FALSE
	/// Maximum time in seconds that can be set.
	var/max_time = 600
	/// Minimum time in seconds that can be set.
	var/min_time = 10

/obj/machinery/status_display/door_lock/Initialize()
	. = ..()
	update_display("READY", "")

/obj/machinery/status_display/door_lock/examine(mob/user)
	. = ..()
	if(lock_id)
		. += span_notice("It is linked to door ID: '[lock_id]'.")
	else
		. += span_warning("It has no linked door ID.")
	if(timer_active)
		. += span_notice("Time remaining: [time_remaining] seconds.")
	else
		. += span_notice("The timer is not active.")

/obj/machinery/status_display/door_lock/process()
	if(machine_stat & NOPOWER)
		remove_display()
		return PROCESS_KILL

	if(!timer_active)
		update_display("READY", "")
		return PROCESS_KILL

	time_remaining--
	if(time_remaining <= 0)
		time_remaining = 0
		timer_active = FALSE
		unlock_doors()
		update_display("READY", "")
		return PROCESS_KILL

	// Format time as MM:SS
	var/minutes = round(time_remaining / 60)
	var/seconds = time_remaining % 60
	var/time_str = "[minutes]:[seconds < 10 ? "0" : ""][seconds]"
	update_display("LOCK", time_str)

/// Finds and bolts all linked airlocks.
/obj/machinery/status_display/door_lock/proc/lock_doors()
	for(var/obj/machinery/door/airlock/door in GLOB.airlocks)
		if(door.id_tag == lock_id)
			door.bolt()

/// Finds and unbolts all linked airlocks.
/obj/machinery/status_display/door_lock/proc/unlock_doors()
	for(var/obj/machinery/door/airlock/door in GLOB.airlocks)
		if(door.id_tag == lock_id)
			door.unbolt()

/obj/machinery/status_display/door_lock/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	if(machine_stat & NOPOWER)
		return
	if(!lock_id)
		to_chat(user, span_warning("[src] has no linked door ID!"))
		return

	if(timer_active)
		// Allow cancelling the timer
		var/choice = tgui_alert(user, "The lock timer is active with [time_remaining] seconds remaining. Cancel it?", "Door Lock", list("Cancel Timer", "Leave Active"))
		if(!choice || choice == "Leave Active")
			return
		if(!Adjacent(user) || machine_stat & NOPOWER)
			return
		timer_active = FALSE
		time_remaining = 0
		unlock_doors()
		update_display("READY", "")
		START_PROCESSING(SSmachines, src)
		return

	var/input_time = input(user, "Set lock duration in seconds ([min_time]-[max_time]):", "Door Lock Timer", 60) as num|null
	if(!input_time)
		return
	if(!Adjacent(user) || machine_stat & NOPOWER)
		return

	input_time = clamp(input_time, min_time, max_time)
	time_remaining = input_time
	timer_active = TRUE
	lock_doors()
	START_PROCESSING(SSmachines, src)
