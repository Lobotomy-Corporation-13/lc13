/datum/work_event/past_the_line
	evt_id = "past_the_line"
	evt_desc = "\
		As your writing down the reaction of the abnormality to stimuli,<br>\
		your pen slips from your hand and rolls past the yellow warning line."
	evt_options = list(
		"Step past the line and grab the pen." = 1,
		"It belongs to the abnormality now. Leave it" = 2,
		)

/datum/work_event/past_the_line/Consequences(evt_choice)
	. = ..()
	if(evt_choice == 1)
		if(AttributeTest(JUSTICE_ATTRIBUTE))
			to_chat(evt_agent, span_green("You quickly grab the pen and retreat back past the line before the abnormality has any time to act."))
			evt_agent.deal_damage(-10 , WHITE_DAMAGE)
		else
			to_chat(evt_agent, span_danger("You trip and fall on your stomach, scrambling on the ground you manage to fling yourself and the pen over the line."))
			evt_agent.deal_damage(10 , RED_DAMAGE, flags = (DAMAGE_FORCED))
		return
	to_chat(evt_agent, span_danger("The loss of that pen will go on your record."))
	evt_agent.deal_damage(10 , WHITE_DAMAGE, flags = (DAMAGE_FORCED))
