/*!
 * Copyright (c) 2020 Aleksej Komarov
 * SPDX-License-Identifier: MIT
 */

SUBSYSTEM_DEF(chat)
	name = "Chat"
	flags = SS_TICKER
	wait = 1
	priority = FIRE_PRIORITY_CHAT
	init_order = INIT_ORDER_CHAT

	var/list/payload_by_client = list()

/datum/controller/subsystem/chat/fire()
	for(var/key in payload_by_client)
		var/client/client = key
		var/list/payload = payload_by_client[key]
		payload_by_client -= key
		if(client)
			// Lazy-build a distorted payload only if any message needs mangling.
			var/list/dispatched = payload
			var/list/distorted_payload
			for(var/i in 1 to length(payload))
				var/list/m = payload[i]
				var/list/d = arayashiki_distort_message(client, m)
				if(d)
					if(!distorted_payload)
						distorted_payload = payload.Copy()
					distorted_payload[i] = d
			if(distorted_payload)
				dispatched = distorted_payload
			// Send to tgchat
			client.tgui_panel?.window.send_message("chat/message", dispatched)
			// Send to old chat
			for(var/message in dispatched)
				SEND_TEXT(client, message_to_html(message))
			// Track approximate chat-line count for chat-consuming abilities (Arayashiki/Sangria).
			client.chat_message_count += length(dispatched)
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/chat/proc/queue(target, message)
	if(islist(target))
		for(var/_target in target)
			var/client/client = CLIENT_FROM_VAR(_target)
			if(client)
				LAZYADD(payload_by_client[client], list(message))
		return
	var/client/client = CLIENT_FROM_VAR(target)
	if(client)
		LAZYADD(payload_by_client[client], list(message))
