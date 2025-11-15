/// Violently spins the target and banishes them to the realm of sealed regrets
/datum/smite/repentance_banish
	name = "Banish to Repentance Dimension"

/datum/smite/repentance_banish/effect(client/user, mob/living/target)
	. = ..()

	if(!isliving(target))
		return

	if(!ishuman(target))
		to_chat(user, span_warning("Only humans can be banished to the realm of sealed regrets."), confidential = TRUE)
		return

	var/mob/living/carbon/human/H = target

	// Check if already trapped
	if(IsTrappedInRepentance(H))
		to_chat(user, span_warning("[H] is already trapped in the realm of sealed regrets."), confidential = TRUE)
		return

	// Dramatic message
	to_chat(H, span_userdanger("The fabric of reality tears open beneath you! You feel yourself being pulled into a dimension of eternal regret!"), confidential = TRUE)
	H.visible_message(span_warning("[H] is violently twisted by unseen forces as reality tears around them!"))

	// Send them to the dimension with spinning
	var/message = "You have been banished to the realm of sealed regrets by divine judgment!"
	SendToRepentanceDimension(H, message, TRUE)

	// Admin log
	log_admin("[key_name(user)] banished [key_name(H)] to the realm of sealed regrets.")
	message_admins("[key_name_admin(user)] banished [key_name_admin(H)] to the realm of sealed regrets.")
