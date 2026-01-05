/**
 * Beauty component, makes the indoor area the parent is in prettier or uglier depending on the beauty var.
 * Clean and well decorated areas lead to positive moodlets for passerbies, while shabbier, dirtier ones
 * lead to negative moodlets exclusive to characters with the snob quirk.
 *
 * Keep in mind AddComponent is used for BOTH adding and removing beauty value here,
 * so please don't use qdel/RemoveComponent unless necessary.
 */
/datum/component/beauty
	var/beauty = 0
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS

/datum/component/beauty/Initialize(beautyamount)
	if(!isatom(parent) || isarea(parent))
		return COMPONENT_INCOMPATIBLE

	// Don't attach beauty to stacks - they merge and cause accumulation bugs
	if(istype(parent, /obj/item/stack))
		return COMPONENT_INCOMPATIBLE

	beauty = beautyamount

	if(ismovable(parent))
		RegisterSignal(parent, COMSIG_ENTER_AREA, PROC_REF(enter_area))
		RegisterSignal(parent, COMSIG_EXIT_AREA, PROC_REF(exit_area))

	// Add examine text in outpost gamemode
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

	var/area/A = get_area(parent)
	if(A)
		enter_area(null, A)

/datum/component/beauty/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	// Only show beauty info in outpost gamemode
	if(SSmaptype.maptype != "outpost")
		return

	if(beauty > 0)
		examine_list += span_notice("This provides <b>+[beauty]</b> beauty to the room.")
	else if(beauty < 0)
		examine_list += span_warning("This provides <b>[beauty]</b> beauty to the room.")

/datum/component/beauty/proc/enter_area(datum/source, area/A)
	SIGNAL_HANDLER

	if(A.outdoors)
		return
	A.totalbeauty += beauty
	A.update_beauty()

/datum/component/beauty/proc/exit_area(datum/source, area/A)
	SIGNAL_HANDLER

	if(A.outdoors)
		return
	A.totalbeauty -= beauty
	A.update_beauty()

/datum/component/beauty/InheritComponent(datum/component/beauty/new_comp , i_am_original, beautyamount)
	if((beauty + beautyamount) == 0)
		qdel(src)
		return

	// Sanity check - prevent extreme accumulation
	var/new_beauty = beauty + beautyamount
	if(new_beauty < -1000 || new_beauty > 1000)
		log_game("BEAUTY BUG: [parent?.type] has extreme beauty value: [new_beauty] - skipping")
		return  // Don't apply the change

	beauty = new_beauty
	var/area/A = get_area(parent)
	if(A && !A.outdoors)
		A.totalbeauty += beautyamount
		A.update_beauty()

/datum/component/beauty/Destroy()
	. = ..()
	var/area/A = get_area(parent)
	if(A)
		exit_area(null, A)
