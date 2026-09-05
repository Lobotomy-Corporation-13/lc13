/datum/work_event/intel
	evt_id = "intel"
	evt_desc = "\
		The abnormality looks rather aggravated.<br>\
		This might be a good time to pay attention and learn more."
	evt_options = list(
		"Look, Listen and observe." = 1,
		"Continue working as normal." = 2,
		)
	evt_req_work = ABNORMALITY_WORK_INSIGHT

/datum/work_event/intel/Consequences(evt_choice)
	. = ..()
	if(evt_choice == 1)
		MessageSend(evt_agent, "You learn something new about the abnormality.")
		evt_datum.understanding++
		evt_agent.apply_status_effect(/datum/status_effect/workspeed_buff/debuff)
		return

	to_chat(evt_agent, span_danger("You decide that it's better to slow down and work safely."))
	evt_agent.apply_status_effect(/datum/status_effect/workspeed_buff/debuff)

