/**
 * Resurgence Outpost - Delivery Crate
 *
 * Special crate subtype for faction deliveries.
 * - Self-destructs when opened (no free crate loot)
 * - No metal drops on destruction
 * - Dynamic icon based on order size
 * - Can have faction notes attached
 */

/obj/structure/closet/crate/resurgence_delivery
	name = "delivery package"
	desc = "A delivery package from a trading faction."
	icon = 'icons/obj/storage.dmi'
	icon_state = "deliverypackage3"
	anchored = FALSE
	density = TRUE
	// Prevent material drops on destruction
	material_drop = null
	material_drop_amount = 0

	/// The note attached to this delivery
	var/obj/item/paper/attached_note

	/// Size tier of the delivery (1-6)
	var/size_tier = 3

/obj/structure/closet/crate/resurgence_delivery/Initialize(mapload)
	. = ..()
	update_icon_state()

/// Set the size tier and update icon
/obj/structure/closet/crate/resurgence_delivery/proc/set_size_tier(tier)
	size_tier = clamp(tier, 1, 6)
	update_icon_state()

/// Update the icon based on size tier
/obj/structure/closet/crate/resurgence_delivery/update_icon_state()
	switch(size_tier)
		if(1)
			icon_state = "deliverypackage1"
			name = "small delivery package"
		if(2)
			icon_state = "deliverypackage2"
			name = "delivery package"
		if(3)
			icon_state = "deliverypackage3"
			name = "delivery package"
		if(4)
			icon_state = "deliverypackage4"
			name = "large delivery package"
		if(5)
			icon_state = "deliverypackage5"
			name = "large delivery crate"
		if(6)
			icon_state = "deliverybox"
			name = "delivery crate"

/// Attach a note to this delivery
/obj/structure/closet/crate/resurgence_delivery/proc/attach_note(obj/item/paper/note)
	if(attached_note)
		qdel(attached_note)
	attached_note = note
	note.forceMove(src)
	// Add note overlay
	var/mutable_appearance/note_overlay = mutable_appearance(icon, "[icon_state]_note")
	add_overlay(note_overlay)

/obj/structure/closet/crate/resurgence_delivery/examine(mob/user)
	. = ..()
	if(attached_note)
		if(!in_range(user, src))
			. += span_notice("There's a note attached. You can't read it from here.")
		else
			. += span_notice("There's a note attached:")
			. += attached_note.examine(user)

/obj/structure/closet/crate/resurgence_delivery/open(mob/living/user, force)
	// Dump contents first
	var/turf/T = get_turf(src)
	for(var/atom/movable/AM in contents)
		if(AM == attached_note)
			continue  // Handle note separately
		AM.forceMove(T)

	// Drop note for user to read
	if(attached_note)
		attached_note.forceMove(T)
		attached_note = null

	// Play sound and message
	if(user)
		to_chat(user, span_notice("You open the delivery package and retrieve the contents."))
	playsound(src, 'sound/items/poster_ripped.ogg', 50, TRUE)

	// Self-destruct - no free crate
	qdel(src)
	return TRUE

/obj/structure/closet/crate/resurgence_delivery/Destroy()
	// Drop contents on destroy
	var/turf/T = get_turf(src)
	if(T)
		for(var/atom/movable/AM in contents)
			AM.forceMove(T)
	if(attached_note)
		QDEL_NULL(attached_note)
	return ..()

// Override deconstruct to dump contents without dropping metal
/obj/structure/closet/crate/resurgence_delivery/deconstruct(disassembled)
	var/turf/T = get_turf(src)
	if(T)
		for(var/atom/movable/AM in contents)
			AM.forceMove(T)
		if(attached_note)
			attached_note.forceMove(T)
			attached_note = null
	qdel(src)

// ==================== Note Generation ====================

/// Generate a faction note based on purchase amount and reputation
/proc/generate_faction_note(datum/trading_faction/faction, purchase_amount)
	if(!faction)
		return null

	var/obj/item/paper/note = new()
	note.name = "note from [faction.speaker_name]"

	var/note_text = "<center><b>[faction.name]</b></center><br><br>"

	// Get note content based on faction, rep, and purchase amount
	var/message = get_faction_note_message(faction, purchase_amount)
	note_text += message

	// Add signature
	note_text += "<br><br><i>- [faction.speaker_name]</i>"

	note.info = note_text
	return note

/// Get appropriate message based on faction, reputation, and purchase size
/proc/get_faction_note_message(datum/trading_faction/faction, purchase_amount)
	var/rep = faction.reputation

	// Determine purchase size tier
	var/size_label
	if(purchase_amount < 100)
		size_label = "small"
	else if(purchase_amount < 300)
		size_label = "medium"
	else if(purchase_amount < 600)
		size_label = "large"
	else
		size_label = "huge"

	// Get faction-specific messages
	switch(faction.id)
		if("resurgence_clan")
			return get_resurgence_clan_note(rep, size_label)
		if("jiajia_ren")
			return get_jiajia_ren_note(rep, size_label)
		if("santata_factory")
			return get_santata_factory_note(rep, size_label)
		if("cloud_town")
			return get_cloud_town_note(rep, size_label)

	// Generic fallback
	return "Thank you for your purchase."

/proc/get_resurgence_clan_note(rep, size_label)
	if(rep >= 80)
		switch(size_label)
			if("small")
				return "Every bit helps, family. May your cores burn bright."
			if("medium")
				return "The village is grateful for your continued support. Walk safely, kin."
			if("large")
				return "Your generosity will not be forgotten. The Weaver blesses your work."
			if("huge")
				return "You honor us with such faith in our humble goods. The ancestors smile upon you, child of the Resurgence."
	else if(rep >= 60)
		switch(size_label)
			if("small")
				return "Thank you, friend. Safe travels."
			if("medium")
				return "May these goods serve you well."
			if("large")
				return "We packed everything with care. Thank you for the trade."
			if("huge")
				return "Such a large order! We hope everything meets your expectations."
	else if(rep >= 40)
		return "Transaction complete. May your outpost prosper."
	else
		return "Here are your goods. We hope this trade improves relations between us."

/proc/get_jiajia_ren_note(rep, size_label)
	if(rep >= 80)
		switch(size_label)
			if("small")
				return "*Happy chirp* Small trade, big friendship! Flock happy!"
			if("medium")
				return "*Excited whistles* Good trade! Chir-rik picked best goods for you!"
			if("large")
				return "*Joyful trilling* Big trade with friends! Flock dances! Very very good!"
			if("huge")
				return "*LOUD HAPPY SCREECHING* BEST TRADE! BEST FRIENDS! Chir-rik personally blessed every item! Flock sings songs of metal friends!"
	else if(rep >= 60)
		switch(size_label)
			if("small")
				return "*Click* Small package. Shiny inside. Enjoy!"
			if("medium")
				return "*Whistle* Good goods for good traders!"
			if("large")
				return "*Coo* Many things! All quality! Flock approves!"
			if("huge")
				return "*Impressed trill* So much! Flock worked hard! Hope you like!"
	else if(rep >= 40)
		return "*Click click* Trade is trade. Fair deal. Bye bye."
	else
		return "*Low hiss* Here. Take. Flock watching. No tricks."

/proc/get_santata_factory_note(rep, size_label)
	if(rep >= 80)
		switch(size_label)
			if("small")
				return "A small gift-ome! Production hopes you enjoy-ome!"
			if("medium")
				return "Quality goods from our best assembly lines-ome! Dodoru inspected personally-ome!"
			if("large")
				return "The Factory worked overtime just for you-ome! Our favorite customers deserve the best-ome!"
			if("huge")
				return "SUCH A WONDERFUL ORDER-OME! The Factory bells rang in celebration-ome! Dodoru is SO pleased-ome! Perhaps one day you visit the Factory-ome? Hehehe..."
	else if(rep >= 60)
		switch(size_label)
			if("small")
				return "From the Factory with care-ome!"
			if("medium")
				return "Production quality, guaranteed-ome!"
			if("large")
				return "Big order, big effort-ome! Thank you-ome!"
			if("huge")
				return "The assembly lines hummed with joy-ome! Thank you for the business-ome!"
	else if(rep >= 40)
		return "Standard delivery from Santata's Gift Factory-ome. Thank you for your patronage-ome."
	else
		return "Your order-ome. The Factory remembers all transactions-ome."

/proc/get_cloud_town_note(rep, size_label)
	if(rep >= 80)
		switch(size_label)
			if("small")
				return "Take care out there, friends. You're always welcome in Cloud Town."
			if("medium")
				return "Good doing business with you. The hunters send their regards."
			if("large")
				return "We put our best work into this order. You've earned our trust."
			if("huge")
				return "Cloud Town doesn't forget its allies. This order was prepared with pride. If you ever need shelter, our doors are open."
	else if(rep >= 60)
		switch(size_label)
			if("small")
				return "Hope this helps. Stay safe."
			if("medium")
				return "Good trade. Come back anytime."
			if("large")
				return "Big order delivered. Quality guaranteed."
			if("huge")
				return "Impressive order. The whole town pitched in. Take care."
	else if(rep >= 40)
		return "Delivery complete. Fair trade, fair dealing."
	else
		return "Here's your order. Trust is earned, not given."
