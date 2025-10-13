// Notify
/datum/tgs_chat_command/notify
	name = "notify"
	help_text = "Pings the invoker when the round ends"

/datum/tgs_chat_command/notify/Run(datum/tgs_chat_user/sender, params)
	if(!CONFIG_GET(string/chat_announce_new_game))
		return "Notifcations are currently disabled"

	for(var/member in SSdiscord.notify_members) // If they are in the list, take them out
		if(member == sender.mention)
			SSdiscord.notify_members -= sender.mention
			return "You will no longer be notified when the server restarts"

	// If we got here, they arent in the list. Chuck 'em in!
	SSdiscord.notify_members += sender.mention
	return "You will now be notified when the server restarts"

/datum/tgs_chat_command/highpopqueue
	name = "highpopqueue"
	help_text = "Pings the invoker when the highpop threshhold is reached"

/datum/tgs_chat_command/highpopqueue/Run(datum/tgs_chat_user/sender, params)
	if(!CONFIG_GET(flag/high_pop_ping_enabled))
		return "High pop queue pings are currently disabled"

	if(SSdiscord.high_pop_pinged)
		return "There was already a high pop ping this round"

	// See above, remove if invoked again aka person doesn't want ping anymore
	for(var/member in SSdiscord.highpopqueue_members)
		if(member == sender.mention)
			SSdiscord.highpopqueue_members -= sender.mention
			return "You will no longer be notified when the server passes the high pop threshold"

	SSdiscord.highpopqueue_members += sender.mention
	return "You will now be notified when the server passes the high pop threshold"
