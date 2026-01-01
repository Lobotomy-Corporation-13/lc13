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
