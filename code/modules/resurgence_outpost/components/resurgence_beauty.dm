/**
 * Resurgence Beauty Component
 *
 * A separate beauty system for Resurgence Outpost that doesn't interfere
 * with the base game's beauty/mood system. This component tracks beauty
 * specifically for resurgence rooms and affects faith-based mood bonuses.
 *
 * Unlike the base beauty component which affects snob moodlets, this system
 * only affects the resurgence room quality calculations.
 */
/datum/component/resurgence_beauty
	/// Beauty value provided by this object
	var/beauty = 0
	dupe_mode = COMPONENT_DUPE_UNIQUE_PASSARGS

/datum/component/resurgence_beauty/Initialize(beauty_amount)
	if(!isatom(parent) || isarea(parent))
		return COMPONENT_INCOMPATIBLE

	// Don't attach beauty to stacks - they merge and cause accumulation bugs
	if(istype(parent, /obj/item/stack))
		return COMPONENT_INCOMPATIBLE

	beauty = beauty_amount

	if(ismovable(parent))
		RegisterSignal(parent, COMSIG_ENTER_AREA, PROC_REF(enter_area))
		RegisterSignal(parent, COMSIG_EXIT_AREA, PROC_REF(exit_area))

	// Add examine text in outpost gamemode
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

	var/area/A = get_area(parent)
	if(A)
		enter_area(null, A)

/datum/component/resurgence_beauty/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	// Only show beauty info in outpost gamemode
	if(SSmaptype.maptype != "outpost")
		return

	if(beauty > 0)
		examine_list += span_notice("This provides <b>+[beauty]</b> beauty to the room.")
	else if(beauty < 0)
		examine_list += span_warning("This provides <b>[beauty]</b> beauty to the room.")

/datum/component/resurgence_beauty/proc/enter_area(datum/source, area/A)
	SIGNAL_HANDLER

	// Only affects resurgence outpost rooms
	var/area/resurgence_outpost/outpost_area = A
	if(!istype(outpost_area))
		return

	if(outpost_area.outdoors)
		return

	outpost_area.total_resurgence_beauty += beauty
	outpost_area.update_resurgence_beauty()

/datum/component/resurgence_beauty/proc/exit_area(datum/source, area/A)
	SIGNAL_HANDLER

	// Only affects resurgence outpost rooms
	var/area/resurgence_outpost/outpost_area = A
	if(!istype(outpost_area))
		return

	if(outpost_area.outdoors)
		return

	outpost_area.total_resurgence_beauty -= beauty
	outpost_area.update_resurgence_beauty()

/datum/component/resurgence_beauty/InheritComponent(datum/component/resurgence_beauty/new_comp, i_am_original, beauty_amount)
	if((beauty + beauty_amount) == 0)
		qdel(src)
		return

	// Sanity check - prevent extreme accumulation
	var/new_beauty = beauty + beauty_amount
	if(new_beauty < -1000 || new_beauty > 1000)
		log_game("RESURGENCE BEAUTY BUG: [parent?.type] has extreme beauty value: [new_beauty] - skipping")
		return  // Don't apply the change

	beauty = new_beauty
	var/area/resurgence_outpost/outpost_area = get_area(parent)
	if(istype(outpost_area) && !outpost_area.outdoors)
		outpost_area.total_resurgence_beauty += beauty_amount
		outpost_area.update_resurgence_beauty()

/datum/component/resurgence_beauty/Destroy()
	. = ..()
	var/area/A = get_area(parent)
	if(A)
		exit_area(null, A)
