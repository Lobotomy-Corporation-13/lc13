/datum/work_event/spider
	evt_id = "spider"
	evt_desc = "\
		As you are correcting the abnormalities environment. You encounter a above average sized spider.<br>\
		Its web is currently blocking a area you havent attended to yet."
	evt_options = list(
		"Carefully wipe away the web." = 1,
		"Clean the surrounding area again until it is gone." = 2,
		)
	evt_req_work = ABNORMALITY_WORK_INSIGHT

/datum/work_event/spider/Consequences(evt_choice)
	. = ..()
	if(evt_choice == 1)
		if(AttributeTest(FORTITUDE_ATTRIBUTE, 1))
			to_chat(evt_agent, span_green("The web is swept away to the ground as the spider flees into the air vents."))
			evt_agent.deal_damage(-10 , WHITE_DAMAGE, flags = (DAMAGE_FORCED))
		else
			to_chat(evt_agent, span_danger("Somehow, by some mistake of movement or other reasonable action, the web sticks to your arm and the spider takes this chance to flee towards your face."))
			evt_agent.deal_damage(10 , WHITE_DAMAGE, flags = (DAMAGE_FORCED))
		return
	to_chat(evt_agent, span_danger("You go back and clean the surrounding area again until the spider is gone."))
	evt_agent.apply_status_effect(/datum/status_effect/workspeed_buff/debuff)

