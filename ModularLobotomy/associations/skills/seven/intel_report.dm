// ============================================================
// Seven Association — Intelligence Report System
// ============================================================
// Intel snapshots capture target data from photographs.
// Intel reports reference snapshots and score accuracy for EXP.

// ============================================================
// Intel Snapshot Datum
// ============================================================
/// Captures ground truth intelligence data from a photographed target.
/// Created by the Seven intel camera when a photo is taken.
/// The fixer never sees this data directly — it is used to validate intel reports.
/datum/seven_intel_snapshot
	/// Name of the photographed target
	var/target_name = ""
	/// Job/role of the target (from ID card assignment)
	var/target_role = ""
	/// Area where the target was photographed
	var/area_name = ""
	/// Items the target was holding in their hands
	var/list/held_items = list()
	/// Items in the target's backpack
	var/list/backpack_items = list()
	/// Game timestamp when the snapshot was taken
	var/round_time = ""

/datum/seven_intel_snapshot/New(mob/living/carbon/human/target)
	if(!target)
		return
	target_name = target.name
	// Get role from ID card (more reliable than mind.assigned_role)
	var/obj/item/card/id/ID = target.get_idcard(TRUE)
	if(ID)
		target_role = ID.assignment
	// Capture held items
	for(var/obj/item/I in target.held_items)
		held_items += I.name
	// Capture backpack contents
	if(target.back)
		for(var/obj/item/I in target.back.contents)
			backpack_items += I.name
	var/area/A = get_area(target)
	if(A)
		area_name = A.name
	round_time = gameTimestamp()

// ============================================================
// Intel Report (Item + TGUI)
// ============================================================
/// A Seven Association intelligence report form.
/// Link a photo to establish the ground truth, then manually fill in the fields.
/// The fixer must gather intel from the photo, scanner, and observation — nothing is auto-filled.
/obj/item/intel_report
	name = "blank intel report"
	desc = "A Seven Association intelligence report form. Link a photo, then fill in what you observed."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "alienpaper"
	/// Linked snapshot (ground truth for validation, hidden from fixer)
	var/datum/seven_intel_snapshot/linked_snapshot
	/// The photo placed inside this report
	var/obj/item/photo/attached_photo
	/// User-filled fields
	var/field_target_name = ""
	var/field_target_role = ""
	var/field_round_time = ""
	/// Held items as individual entries (list of strings, one per snapshot held item)
	var/list/field_held_items = list()
	/// Backpack items as individual entries (list of strings, one per snapshot backpack item)
	var/list/field_backpack = list()
	var/field_extra_notes = ""
	/// Whether this report has been filed (submitted to a dossier)
	var/filed = FALSE
	/// Accuracy score (0-10, calculated on filing)
	var/accuracy_score = 0
	/// Scanner description attached by the backpack scanner
	var/scan_description = ""
	/// Accuracy feedback shown after filing
	var/list/accuracy_feedback = list()

/obj/item/intel_report/Destroy()
	QDEL_NULL(attached_photo)
	QDEL_NULL(linked_snapshot)
	return ..()

/obj/item/intel_report/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/photo))
		if(filed)
			to_chat(user, span_warning("This report has already been filed."))
			return
		if(attached_photo)
			to_chat(user, span_warning("This report already has a photo attached."))
			return
		var/obj/item/photo/P = I
		if(!P.picture || !length(P.picture.mobs_seen))
			to_chat(user, span_warning("This photo has no subjects to report on."))
			return
		// Find the snapshot the camera stored for this photo
		var/datum/seven_intel_snapshot/snap
		for(var/datum/seven_intel_snapshot/S in P.seven_snapshots)
			snap = S
			break
		if(!snap)
			to_chat(user, span_warning("This photo was not taken with a Seven intel camera."))
			return
		linked_snapshot = snap
		// Move the photo inside the report — do not auto-fill any fields
		if(!user.transferItemToLoc(P, src))
			P.forceMove(src)
		attached_photo = P
		name = "intel report"
		// Initialize individual item entry lists based on snapshot counts
		field_held_items = list()
		for(var/i in 1 to length(snap.held_items))
			field_held_items += ""
		field_backpack = list()
		for(var/i in 1 to length(snap.backpack_items))
			field_backpack += ""
		to_chat(user, span_notice("Photo attached to report. Fill in your observations."))
		return
	if(istype(I, /obj/item/seven_scanner))
		var/obj/item/seven_scanner/scanner = I
		if(filed)
			to_chat(user, span_warning("This report has already been filed."))
			return
		if(!scanner.last_scan_result)
			to_chat(user, span_warning("The scanner has no scan data. Scan a target first."))
			return
		scan_description = scanner.last_scan_result
		to_chat(user, span_notice("Scanner data attached to report."))
		return
	return ..()

/obj/item/intel_report/attack_self(mob/user)
	ui_interact(user)

/obj/item/intel_report/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SevenIntelReport", name)
		ui.open()

/obj/item/intel_report/ui_state(mob/user)
	return GLOB.physical_state

/obj/item/intel_report/ui_data(mob/user)
	var/list/data = list()
	data["filed"] = filed
	data["has_photo"] = !!attached_photo
	data["field_target_name"] = field_target_name
	data["field_target_role"] = field_target_role
	data["field_round_time"] = field_round_time
	data["field_held_items"] = field_held_items
	data["field_backpack"] = field_backpack
	data["held_count"] = length(field_held_items)
	data["backpack_count"] = length(field_backpack)
	data["field_extra_notes"] = field_extra_notes
	data["accuracy_score"] = accuracy_score
	data["scan_description"] = scan_description
	data["accuracy_feedback"] = accuracy_feedback
	if(attached_photo)
		data["photo_name"] = attached_photo.name
		data["photo_desc"] = attached_photo.desc
		data["photo_ref"] = ref(attached_photo)
	return data

/obj/item/intel_report/ui_act(action, params)
	. = ..()
	if(.)
		return
	if(filed)
		return

	switch(action)
		if("set_field")
			var/field = params["field"]
			var/value = params["value"]
			if(!field || !istext(value))
				return
			value = copytext(value, 1, 256)
			switch(field)
				if("target_name")
					field_target_name = value
				if("target_role")
					field_target_role = value
				if("round_time")
					field_round_time = value
				if("extra_notes")
					field_extra_notes = value
			. = TRUE
		if("set_held_item")
			var/index = text2num(params["index"])
			var/value = params["value"]
			if(!index || index < 1 || index > length(field_held_items))
				return
			if(!istext(value))
				return
			field_held_items[index] = copytext(value, 1, 256)
			. = TRUE
		if("set_backpack_item")
			var/index = text2num(params["index"])
			var/value = params["value"]
			if(!index || index < 1 || index > length(field_backpack))
				return
			if(!istext(value))
				return
			field_backpack[index] = copytext(value, 1, 256)
			. = TRUE
		if("view_photo")
			if(!attached_photo || QDELETED(attached_photo))
				return
			attached_photo.show(usr)
			. = TRUE

/// Calculate accuracy score by comparing filled fields against snapshot data.
/// Returns a score from 0-10. Also populates accuracy_feedback with results.
/obj/item/intel_report/proc/calculate_accuracy()
	accuracy_score = 0
	accuracy_feedback = list()
	if(!linked_snapshot)
		return accuracy_score

	// Name match: 2 points (fuzzy)
	if(field_target_name && findtext(lowertext(linked_snapshot.target_name), lowertext(field_target_name)))
		accuracy_score += 2
		accuracy_feedback += list(list("field" = "Name", "correct" = TRUE, "answer" = linked_snapshot.target_name))
	else
		accuracy_feedback += list(list("field" = "Name", "correct" = FALSE, "answer" = linked_snapshot.target_name))

	// Role match: 2 points
	if(field_target_role && findtext(lowertext(linked_snapshot.target_role), lowertext(field_target_role)))
		accuracy_score += 2
		accuracy_feedback += list(list("field" = "Role", "correct" = TRUE, "answer" = linked_snapshot.target_role))
	else
		accuracy_feedback += list(list("field" = "Role", "correct" = FALSE, "answer" = linked_snapshot.target_role))

	// Time match: 1 point
	if(field_round_time && linked_snapshot.round_time && field_round_time == linked_snapshot.round_time)
		accuracy_score += 1
		accuracy_feedback += list(list("field" = "Time", "correct" = TRUE, "answer" = linked_snapshot.round_time))
	else
		accuracy_feedback += list(list("field" = "Time", "correct" = FALSE, "answer" = linked_snapshot.round_time))

	// Held items: 1 point per matching item, max 2
	if(length(linked_snapshot.held_items))
		var/item_points = 0
		var/list/remaining = linked_snapshot.held_items.Copy()
		var/list/held_feedback = list()
		for(var/i in 1 to length(field_held_items))
			var/entry = field_held_items[i]
			if(!entry)
				held_feedback += list(list("index" = i, "correct" = FALSE, "answer" = (i <= length(linked_snapshot.held_items)) ? linked_snapshot.held_items[i] : ""))
				continue
			var/matched = FALSE
			for(var/snap_item in remaining)
				if(findtext(lowertext(snap_item), lowertext(entry)))
					item_points++
					remaining -= snap_item
					matched = TRUE
					break
			held_feedback += list(list("index" = i, "correct" = matched, "answer" = (i <= length(linked_snapshot.held_items)) ? linked_snapshot.held_items[i] : ""))
		accuracy_score += min(2, item_points)
		accuracy_feedback += list(list("field" = "Held Items", "correct" = (item_points >= length(linked_snapshot.held_items)), "items" = held_feedback))

	// Backpack contents: fuzzy matching
	if(length(linked_snapshot.backpack_items))
		var/matched = 0
		var/list/bp_remaining = linked_snapshot.backpack_items.Copy()
		var/list/bp_feedback = list()
		for(var/i in 1 to length(field_backpack))
			var/entry = field_backpack[i]
			if(!entry)
				bp_feedback += list(list("index" = i, "correct" = FALSE, "answer" = (i <= length(linked_snapshot.backpack_items)) ? linked_snapshot.backpack_items[i] : ""))
				continue
			var/item_matched = FALSE
			for(var/snap_item in bp_remaining)
				if(findtext(lowertext(snap_item), lowertext(entry)))
					matched++
					bp_remaining -= snap_item
					item_matched = TRUE
					break
			bp_feedback += list(list("index" = i, "correct" = item_matched, "answer" = (i <= length(linked_snapshot.backpack_items)) ? linked_snapshot.backpack_items[i] : ""))
		var/total = length(linked_snapshot.backpack_items)
		if(total > 0)
			var/ratio = matched / total
			if(ratio >= 0.7)
				accuracy_score += 3
			else if(ratio >= 0.4)
				accuracy_score += 2
			else if(matched > 0)
				accuracy_score += 1
		accuracy_feedback += list(list("field" = "Backpack", "correct" = (matched >= total), "items" = bp_feedback))

	return accuracy_score
