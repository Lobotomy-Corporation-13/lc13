//This file contains the components of the facility functions that you can fix.

//Warning very W.I.P. code probs nothing of this is final since this is for texting.

/obj/machinery/enkrush_func
	density = TRUE
	anchored = TRUE
	var/department
	var/repaired = FALSE
	var/fixed_state = "exonet_node"

//Unless we make a more complex way to fix them, I suggest adding a required item to fix, atleast for now. Maybe we can implement something like that later?
//	var/required_item


//Checks if a certain department was fixed. If it was, return TRUE, if not. Return FALSE.
/proc/func_check(department)
	if(SSmaptype.maptype == "enkephalin_rush" && SSlobotomy_corp.fixed_departments[department] == FALSE)
		return TRUE
	else
		return FALSE

/obj/machinery/enkrush_func/proc/fix_department(user, announcement)
	icon_state = fixed_state
	repaired = TRUE
	balloon_alert(user, "You fix the [src].")
	SSlobotomy_corp.fixed_departments[department] = TRUE
	priority_announce(announcement ,"Facility Announcement")

/obj/machinery/enkrush_func/attackby(obj/item/P, mob/user, params)
	if(repaired == FALSE)
		fix_department(user, "The [src] has been fixed.")

/obj/machinery/enkrush_func/info
	name = "Information Processing Console"
	icon_state = "exonet_node_off"
	fixed_state = "exonet_node"
	department = "Information"

/obj/machinery/enkrush_func/safety
	name = "Central Regenerator Unit"
	icon_state = "exonet_node_off"
	department = "Safety"

/obj/machinery/enkrush_func/training
	name = "Training Procedure Console"
	icon_state = "exonet_node_off"
	department = "Training"

/obj/machinery/enkrush_func/control
	name = "Agent Work Optimization Algorithm Server"
	icon_state = "exonet_node_off"
	department = "Control"
