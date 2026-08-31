/**
 * Expedition Crate
 *
 * A specialized crate designed for hauling items on expeditions.
 * Automatically transported during terrain transitions.
 * Can be scanned by faction traders for selling.
 */
/obj/structure/closet/crate/expedition
	name = "expedition crate"
	desc = "A reinforced crate designed for hauling goods on expeditions. Place it near the World Map Console before departing to bring it along."
	icon_state = "privatecrate"
	/// The expedition this crate is associated with (if any)
	var/datum/expedition_party/expedition
	/// Whether this crate has been marked for selling
	var/marked_for_sale = FALSE

/obj/structure/closet/crate/expedition/examine(mob/user)
	. = ..()
	. += span_notice("<b>How to use:</b>")
	. += span_notice("1. Fill this crate with items you want to sell.")
	. += span_notice("2. Place it near the World Map Console BEFORE the expedition departs.")
	. += span_notice("3. The crate will automatically travel with your party through terrain transitions.")
	. += span_notice("4. At a faction hub, talk to the trader and use 'Scan Nearby Crates' to sell contents.")

/obj/structure/closet/crate/expedition/Initialize(mapload)
	. = ..()
	// Add to global list for tracking
	GLOB.expedition_crates += src

/obj/structure/closet/crate/expedition/Destroy()
	GLOB.expedition_crates -= src
	expedition = null
	return ..()

/**
 * Associate this crate with an expedition party
 */
/obj/structure/closet/crate/expedition/proc/join_expedition(datum/expedition_party/party)
	if(!party)
		return FALSE
	expedition = party
	return TRUE

/**
 * Disassociate this crate from its expedition
 */
/obj/structure/closet/crate/expedition/proc/leave_expedition()
	expedition = null

// Global list for tracking expedition crates
GLOBAL_LIST_EMPTY(expedition_crates)
