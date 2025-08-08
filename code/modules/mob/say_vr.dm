//////////////////////////////////////////////////////
////////////////////SUBTLE COMMAND////////////////////	(ported from citadel, needed for LOOC and flavour text)
//////////////////////////////////////////////////////
/mob
	var/flavor_text = "" //tired of fucking double checking this

/mob/proc/update_flavor_text()
	set name = "Update Flavor Text"
	set category = "IC"
	set src in usr

	if(usr != src)
		to_chat(usr, span_notice("You can't set someone else's flavour text!"))
	var/msg = input(usr, "A snippet of text shown when others examine you, describing what you may look like. This can also be used for OOC notes.", "Flavor Text", html_decode("flavor_text")) as message|null

	if(msg)
		msg = copytext(msg, 1, MAX_MESSAGE_LEN)
		msg = html_encode(msg)

		flavor_text = msg

/mob/proc/print_flavor_text()
	if(flavor_text && flavor_text != "")
		var/msg = replacetext(flavor_text, "\n", " ")
		if(length(msg) <= MAX_SHORTFLAVOR_LEN)
			return "<span class='notice'>[msg]</span>"
		else
			return "<span class='notice'>[copytext(msg, 1, MAX_SHORTFLAVOR_LEN)]... <a href=\"byond://?src=[text_ref(src)];flavor_more=1\">More...</span></a>"
