/datum/work_event/bugged_console
	evt_id = "consolebug"
	evt_desc = "\
		The work console is glitched. Seems to be skipping safety checks.<br>\
		While worrying, this is quite an opportunity."
	evt_options = list(
		"Let the glitch continue." = 1,
		"Slow down the work and fix." = 2,
		)

/datum/work_event/bugged_console/Consequences(evt_choice)
	. = ..()
	if(evt_choice == 1)
		MessageSend(evt_agent, "You get shocked by the machine, but the glitch continues.")
		evt_agent.deal_damage(10, FIRE, flags = (DAMAGE_FORCED))
		evt_agent.apply_status_effect(/datum/status_effect/workspeed_buff)
		return

	to_chat(evt_agent, span_danger("You decide that it's better to slow down and work safely."))
	evt_agent.apply_status_effect(/datum/status_effect/workspeed_buff/debuff)

