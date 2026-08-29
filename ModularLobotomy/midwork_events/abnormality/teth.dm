
// Today's Shy Look
/datum/work_event/shy
	evt_id = "shy"
	evt_desc = "\
		As your observing O-01-92 for physical differences<br>\
		you find a angle where you can slightly see whats behind the skin.<br>\
		You can guess whats there, but knowing for sure will improve understanding."
	evt_options = list(
		"Indulge curiosity." = 1,
		"Do not look." = 2,
		)
	req_abno = /mob/living/simple_animal/hostile/abnormality/shy_look

/datum/work_event/shy/Consequences(evt_choice)
	. = ..()
	if(evt_choice == 1)
		to_chat(evt_agent, span_danger("You dont know what you were expecting to see behind the skin. You write down what you saw and improve your understanding."))
		evt_agent.deal_damage(15 , WHITE_DAMAGE, flags = (DAMAGE_FORCED))
		if(evt_comp)
			//Max understanding is 10 usually.
			evt_comp.datum_reference.understanding += 1
		return
	to_chat(evt_agent, span_danger("Its best to not know."))
