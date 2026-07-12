// ============================================================
// Seven Association — Investigation Dossier
// ============================================================
// Collects filed intel reports, tracks subjects, and grants EXP.

/// A classified dossier for filing intelligence reports.
/// Accepts intel reports, calculates accuracy, and grants EXP.
/obj/item/seven_dossier
	name = "Seven investigation dossier"
	desc = "A classified dossier for filing intelligence reports. Tracks subjects and accuracy scores."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "folder_green"
	w_class = WEIGHT_CLASS_SMALL
	/// Filed reports: list(subject_name = list(report_data...))
	var/list/filed_reports = list()
	/// Per-target cooldown: list(subject_name = world.time)
	var/list/filing_cooldowns = list()
	/// Total reports filed
	var/total_filed = 0

/obj/item/seven_dossier/examine(mob/user)
	. = ..()
	. += span_notice("[total_filed] reports filed across [length(filed_reports)] subjects.")

/obj/item/seven_dossier/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/intel_report))
		var/obj/item/intel_report/report = I
		if(report.filed)
			to_chat(user, span_warning("This report has already been filed."))
			return
		if(!report.field_target_name)
			to_chat(user, span_warning("The report has no target name filled in."))
			return
		// Check 2-minute cooldown per target
		var/target_key = lowertext(report.field_target_name)
		if(filing_cooldowns[target_key] && world.time < filing_cooldowns[target_key] + 2 MINUTES)
			var/remaining = round((filing_cooldowns[target_key] + 2 MINUTES - world.time) / 10)
			to_chat(user, span_warning("You filed a report on [report.field_target_name] recently. Wait [remaining] seconds."))
			return
		// Calculate accuracy and file the report
		report.calculate_accuracy()
		report.filed = TRUE
		report.icon_state = "alienpaper_words"
		filing_cooldowns[target_key] = world.time
		// Store report data
		if(!filed_reports[target_key])
			filed_reports[target_key] = list()
		filed_reports[target_key] += list(list(
			"target_name" = report.field_target_name,
			"target_role" = report.field_target_role,
			"round_time" = report.field_round_time,
			"held_items" = report.field_held_items.Join(", "),
			"backpack" = report.field_backpack.Join(", "),
			"extra_notes" = report.field_extra_notes,
			"accuracy" = report.accuracy_score,
			"has_photo" = !!report.attached_photo,
			"photo_ref" = report.attached_photo ? ref(report.attached_photo) : null,
			"filed_time" = gameTimestamp()
		))
		total_filed++
		// Grant EXP: 5 base + accuracy bonus
		var/exp_gained = (5 + report.accuracy_score) * 10
		var/datum/component/association_exp/exp = user.GetComponent(/datum/component/association_exp)
		if(exp && exp.association_type == ASSOCIATION_SEVEN)
			exp.modify_exp(exp_gained)
		to_chat(user, span_notice("Report filed on [report.field_target_name]."))
		to_chat(user, span_notice("Accuracy: [report.accuracy_score]/10 | EXP earned: [exp_gained]"))
		// Show accuracy feedback — what was right and wrong
		for(var/list/fb in report.accuracy_feedback)
			if(fb["items"])
				// Item list feedback (held items / backpack)
				var/list/item_fb = fb["items"]
				for(var/list/ifb in item_fb)
					if(ifb["correct"])
						to_chat(user, span_nicegreen("  [fb["field"]] #[ifb["index"]]: Correct"))
					else
						to_chat(user, span_warning("  [fb["field"]] #[ifb["index"]]: Wrong — was [ifb["answer"]]"))
			else
				if(fb["correct"])
					to_chat(user, span_nicegreen("  [fb["field"]]: Correct"))
				else
					to_chat(user, span_warning("  [fb["field"]]: Wrong — was [fb["answer"]]"))
		// Check for active investigate_person contracts on this target
		if(exp && exp.squad)
			for(var/datum/association_contract/investigate_person/IC in exp.squad.active_contracts)
				if(IC.state != CONTRACT_STATE_ACTIVE)
					continue
				if(!IC.target_mob)
					continue
				if(lowertext(IC.target_mob.name) == target_key)
					IC.on_report_filed()
					break
		// Move report into the dossier
		if(!user.transferItemToLoc(report, src))
			report.forceMove(src)
		// Add paper overlay on first report filed
		if(total_filed == 1)
			add_overlay("folder_paper")
		return
	return ..()

/obj/item/seven_dossier/attack_self(mob/user)
	ui_interact(user)

/obj/item/seven_dossier/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SevenDossier", name)
		ui.open()

/obj/item/seven_dossier/ui_state(mob/user)
	return GLOB.physical_state

/obj/item/seven_dossier/ui_data(mob/user)
	var/list/data = list()
	data["total_filed"] = total_filed
	var/list/subjects = list()
	for(var/subject_key in filed_reports)
		var/list/reports = filed_reports[subject_key]
		if(!length(reports))
			continue
		var/total_accuracy = 0
		var/list/report_entries = list()
		for(var/list/R in reports)
			total_accuracy += R["accuracy"]
			report_entries += list(list(
				"target_name" = R["target_name"],
				"target_role" = R["target_role"],
				"round_time" = R["round_time"],
				"extra_notes" = R["extra_notes"],
				"accuracy" = R["accuracy"],
				"has_photo" = R["has_photo"],
				"photo_ref" = R["photo_ref"],
				"filed_time" = R["filed_time"]
			))
		subjects += list(list(
			"key" = subject_key,
			"name" = reports[1]["target_name"],
			"count" = length(reports),
			"avg_accuracy" = round(total_accuracy / length(reports), 0.1),
			"reports" = report_entries
		))
	data["subjects"] = subjects
	return data

/obj/item/seven_dossier/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("view_photo")
			var/photo_ref = params["photo_ref"]
			if(!photo_ref)
				return
			var/obj/item/photo/P = locate(photo_ref)
			if(!istype(P) || QDELETED(P))
				to_chat(usr, span_warning("That photo is no longer available."))
				return
			P.show(usr)
			. = TRUE
