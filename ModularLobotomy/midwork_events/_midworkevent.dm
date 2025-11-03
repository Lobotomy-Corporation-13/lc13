/*
* Mid work events v1.5
* These are text events that can occur during work.
* Currently it causes a pop up menu with options to occur
* mid work, and the outcome of these options being
* dictated by the datum.
* Expect this system to be reworked in the future.
*/
/datum/work_event
	var/evt_id
	// Event desc appears in the window to describe the event.
	var/evt_desc
	/*
	* Event options are provided to the player in the event prompt
	*/
	var/list/evt_options = list()
	/*
	* If this event only concerns a specific abnormality
	*/
	var/req_abno
	//Required work to have this event occur
	var/evt_req_work
	//If a choice had been made
	var/choice_made = FALSE
	//Spawned browser so we can edit its text and data.
	var/datum/browser/modal/popup
	//The assigned agent who enncountered this event.
	var/mob/living/evt_agent
	//The computer this event originates from.
	var/obj/machinery/computer/abnormality/evt_comp
	//The abnormality datum that belongs to the abno
	var/datum/abnormality/evt_datum
	//The abnormality mob that belongs to the abno
	var/datum/abnormality/evt_abno

/datum/work_event/proc/returnEventInfo(mob/living/eventee, obj/machinery/computer/abnormality/abno_comp)
	if(!ishuman(eventee) || !islist(evt_options) || !abno_comp)
		choice_made = TRUE
		QDEL_IN(src, 1)
		return

	evt_agent = eventee
	evt_comp = abno_comp
	evt_datum = abno_comp.datum_reference

	var/dat = EventText()
	playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
	MakePopup(dat)
	QDEL_IN(src, 1)

//UI text generation
/datum/work_event/proc/EventText()
	. = "[evt_desc]<br>\
		-----<br>"
	for(var/i in evt_options)
		GENERAL_BUTTON(REF(src),"choice",evt_options[i],"[i]")
		. += "<br>"

//Unique consequences to your actions. Can be overrided to make different things happen.
/datum/work_event/proc/Consequences(evt_choice)
	choice_made = TRUE

//Send text in chat and in balloon
/datum/work_event/proc/MessageSend(mob/living/evt_agent, input_text)
	to_chat(evt_agent, span_notice("[input_text]"))
	evt_agent.balloon_alert(evt_agent, "[input_text]")

//So if the pop up is closed the event ends PROPERLY
/datum/work_event/proc/MakePopup(dat)
	//nref needed to be set as this datum so that when the menu is closed with the topright X then it activates this topic.
	popup = new(evt_agent, "MidworkEvent", "MidworkEvent", 500, 300, nref = src,  Timeout = 15 SECONDS)
	popup.set_content(dat)
	popup.open()
	popup.wait()

//For quickly ending the event. Having this in Destroy and a qdel in it is dangerous i know. -IP
/datum/work_event/proc/EndEvent(destroying = FALSE)
	if(popup)
		popup.close()
	if(!choice_made)
		Consequences(0)
	//Very dangerous putting this here.
	if(!destroying)
		qdel(src)

/*
* For making simple tests for attributes.
* Your trying to roll a 1d6 + your raw level
* above the event difficulty.
*/
/datum/work_event/proc/AttributeTest(attribute_to_check, evt_difficulty = 3, mob/living/carbon/human/testee = evt_agent)
	if(!ishuman(evt_agent))
		return
	var/raw_level = get_modified_attribute_level(testee, attribute_to_check)
	var/get_chance = rand(1,6) + raw_level
	return get_chance > evt_difficulty ? TRUE : FALSE

/datum/work_event/Topic(href, href_list)
	. = ..()
	if(href_list["choice"])
		Consequences(text2num(href_list["choice"]))
	popup.close()

/datum/work_event/Destroy()
	EndEvent(TRUE)
	return ..()
