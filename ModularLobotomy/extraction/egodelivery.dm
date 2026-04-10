//Extraction tool delivery item
/obj/item/extraction/delivery
	name = "E.G.O. Dissemination Device"
	desc = "A portable extraction console that can only be used by the extraction officer."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "coffin_empty"
	var/obj/machinery/computer/ego_purchase/eo_tablet/internal_computer
	var/obj/structure/extraction_belt/linked_structure

/obj/item/extraction/delivery/Destroy()
	stored_item = null
// This is a special subtype of the EGO purchase console that is slotted internally into this tablet. Basically so I don't have to make a component/duplicate a ton of code. The EO tablet acts as a proxy that interacts with this console.
/obj/machinery/computer/ego_purchase/eo_tablet
	invisibility = INVISIBILITY_ABSTRACT
	density = FALSE
	requires_delivery_choice = TRUE

// Override to avoid an adjacency check in the parent implementation
/obj/machinery/computer/ego_purchase/eo_tablet/can_interact(mob/user)
	. = ..()
	if(isliving(user))
		var/mob/living/L = user
		if(L.incapacitated())
			return FALSE
		else
			return TRUE

	return FALSE

/obj/machinery/computer/ego_purchase/eo_tablet/Topic(href, href_list)
	. = ..()
	ui_interact(usr) // Need to refresh the UI manually - update user dialog checks for adjacency

// Point at the tablet we're slotted into as the actual host of the UI, so TGUI doesn't mistakenly close it due to non adjacency
/obj/machinery/computer/ego_purchase/eo_tablet/ui_host(mob/user)
	return istype(src.loc, /obj/item/extraction/delivery) ? src.loc : src

// ---- Actual tablet procs section ----

// Slot an EGO purchase console into this tablet.
/obj/item/extraction/delivery/Initialize(mapload)
	. = ..()
	internal_computer = new(src)

// Avoid hard dels (who would shoot an EO tablet until it's destroyed?)
/obj/item/extraction/delivery/Destroy(force)
	internal_computer.linked_structure = null
	QDEL_NULL(internal_computer)
	linked_structure = null
	return ..()

/obj/item/extraction/delivery/examine(mob/user)
	. = ..()
	if(user.mind.assigned_role == "Extraction Officer")
		if (GetFacilityUpgradeValue(UPGRADE_EXTRACTION_2))
			. += span_notice("This tool seems to be upgraded, reducing the cost needed to extract by 15%.")
	if(linked_structure)
		. += span_nicegreen("This tool is linked to an extraction arrival belt.")
	else
		. += span_red("This tool needs to be linked to an extraction arrival belt in order to perform E.G.O. returns.")

// Using this tool will call ui_interact...
/obj/item/extraction/delivery/tool_action(mob/user)
	ui_interact(user)
	return

// ...and ui_interact will call the internal computer's ui_interact in turn.
/obj/item/extraction/delivery/ui_interact(mob/user)
	. = ..()
	playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
	internal_computer.ui_interact(user)
	return

// Telepad-related code
/obj/item/extraction/delivery/pre_attack(atom/A, mob/living/user, params)
	. = ..()
	if(!tool_checks(user))
		return TRUE //You can't do any special interactions
	if(istype(A, /obj/structure/extraction_belt))
		linked_structure = A
		internal_computer.linked_structure = A
		to_chat(usr, span_nicegreen("Device link successful."))
		return TRUE
	return FALSE
