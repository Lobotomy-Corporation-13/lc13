/**
 * Resurgence Outpost - Art Items
 *
 * Painting frames and signs with persistence support for the Resurgence Clan.
 * Paintings placed in these frames are saved and can be reloaded.
 */

/// Resurgence wallframe that creates a painting sign with persistence
/obj/item/wallframe/painting/resurgence
	name = "clan painting frame"
	desc = "A painting frame crafted by the Resurgence Clan. Paintings hung here will be preserved for future generations."
	result_path = /obj/structure/sign/painting/resurgence

/// Resurgence painting sign with persistence support
/obj/structure/sign/painting/resurgence
	name = "Clan Painting"
	desc = "A painting frame crafted by the Resurgence Clan. Art hung here will be preserved."
	desc_with_canvas = "A painting lovingly crafted and preserved by the Resurgence Clan."
	persistence_id = "resurgence_outpost"

// ===== Paperwork Items =====

/// Empty paper bin - starts with no paper
/obj/item/paper_bin/empty
	name = "empty paper bin"
	desc = "A paper bin with no paper inside. Fill it with paper to use."
	total_paper = 0

// ===== Signs =====

/// A simple sign that can hold one piece of paper
/obj/structure/resurgence_sign
	name = "sign"
	desc = "A simple wooden sign. You can attach a piece of paper to it."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "sign"
	density = FALSE
	anchored = TRUE
	max_integrity = 100

	/// The paper attached to this sign
	var/obj/item/paper/attached_paper = null

/obj/structure/resurgence_sign/Destroy()
	if(attached_paper)
		QDEL_NULL(attached_paper)
	return ..()

/obj/structure/resurgence_sign/examine(mob/user)
	. = ..()
	if(attached_paper)
		. += span_notice("There is a paper attached to it.")
		. += span_notice("<b>It reads:</b>")
		// Show the paper's contents
		if(attached_paper.info)
			. += attached_paper.info
		else
			. += "<i>(blank)</i>"
		. += span_notice("Click to remove the paper.")
	else
		. += span_notice("Click with paper to attach it.")

/obj/structure/resurgence_sign/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/paper))
		if(attached_paper)
			to_chat(user, span_warning("There is already a paper on this sign. Remove it first."))
			return
		if(!user.transferItemToLoc(I, src))
			return
		attached_paper = I
		icon_state = "sign_text"
		to_chat(user, span_notice("You attach [I] to the sign."))
		playsound(src, 'sound/items/poster_ripped.ogg', 30, TRUE)
		return
	return ..()

/obj/structure/resurgence_sign/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	if(attached_paper)
		// Remove the paper
		attached_paper.forceMove(get_turf(src))
		user.put_in_hands(attached_paper)
		to_chat(user, span_notice("You remove [attached_paper] from the sign."))
		playsound(src, 'sound/items/poster_ripped.ogg', 30, TRUE)
		attached_paper = null
		icon_state = "sign"
