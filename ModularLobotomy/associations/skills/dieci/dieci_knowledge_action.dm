// ============================================================
// Dieci Association — Knowledge Viewer Action
// ============================================================
// HUD action button that opens a TGUI to view and manage Active Knowledge.
// Granted automatically when a Dieci fixer receives the dieci_knowledge component.

/// Action button that opens the Active Knowledge viewer TGUI.
/datum/action/innate/dieci_knowledge_viewer
	name = "Active Knowledge"
	desc = "View and manage your active knowledge entries."
	icon_icon = 'icons/hud/screen_assoc_trees.dmi'
	button_icon_state = "active_knowledge"

/datum/action/innate/dieci_knowledge_viewer/Activate()
	if(!ishuman(owner))
		return
	ui_interact(owner)

/datum/action/innate/dieci_knowledge_viewer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "DieciKnowledge", "Active Knowledge")
		ui.open()

/datum/action/innate/dieci_knowledge_viewer/ui_state(mob/user)
	return GLOB.always_state

/datum/action/innate/dieci_knowledge_viewer/ui_data(mob/user)
	var/list/data = list()
	var/datum/component/dieci_knowledge/dk
	if(ishuman(owner))
		dk = owner.GetComponent(/datum/component/dieci_knowledge)
	if(dk)
		data["active_knowledge"] = dk.active_knowledge
		data["max_knowledge"] = dk.max_knowledge
		data["synthesis_cost"] = dk.synthesis_cost
		data["conserve_knowledge"] = dk.conserve_knowledge
	else
		data["active_knowledge"] = list()
		data["max_knowledge"] = DIECI_MAX_KNOWLEDGE
		data["synthesis_cost"] = 3
		data["conserve_knowledge"] = FALSE
	return data

/datum/action/innate/dieci_knowledge_viewer/ui_act(action, params)
	. = ..()
	if(.)
		return
	if(!ishuman(owner))
		return
	var/datum/component/dieci_knowledge/dk = owner.GetComponent(/datum/component/dieci_knowledge)
	if(!dk)
		return

	switch(action)
		if("remove_active")
			var/index = text2num(params["index"])
			if(!index || index < 1 || index > length(dk.active_knowledge))
				return
			var/list/entry = dk.active_knowledge[index]
			dk.active_knowledge.Cut(index, index + 1)
			to_chat(owner, span_notice("Removed [entry["type"]] L[entry["level"]] knowledge."))
			return TRUE
		if("toggle_conserve")
			dk.conserve_knowledge = !dk.conserve_knowledge
			if(dk.conserve_knowledge)
				to_chat(owner, span_notice("Knowledge conservation enabled. Passive skills will not consume knowledge."))
			else
				to_chat(owner, span_notice("Knowledge conservation disabled. Passive skills will consume knowledge normally."))
			return TRUE
