// Base Apprentice Recruitment Item
// Shared logic for recruitment scrolls/contracts used by Nursefather roles.
// Subtype this and override get_offer_text(), get_offer_title(), and recruit_apprentice().

/obj/item/apprentice_recruitment
	icon = 'icons/obj/wizard.dmi'
	icon_state = "scroll"
	w_class = WEIGHT_CLASS_TINY
	/// Whether this item has been used
	var/used = FALSE

/obj/item/apprentice_recruitment/attack(mob/living/target, mob/living/user)
	if(used)
		to_chat(user, span_warning("This has already been used."))
		return
	if(!ishuman(target))
		to_chat(user, span_warning("You can only recruit humans."))
		return
	if(target == user)
		to_chat(user, span_warning("You cannot recruit yourself."))
		return

	var/mob/living/carbon/human/H = target

	// Block recruitment of cuckoospawn
	if(istype(H.dna?.species, /datum/species/cuckoospawn))
		to_chat(user, span_warning("[H] is not human enough to be recruited."))
		return

	// Block recruitment of trusted roles (too high-ranking)
	if(H.mind)
		var/datum/job/target_job = SSjob.GetJob(H.mind.assigned_role)
		if(target_job?.trusted_only)
			to_chat(user, span_warning("[H] holds too important a position to be recruited."))
			return

	// Ask target if they accept
	var/response = alert(H, get_offer_text(user), get_offer_title(), "Accept", "Decline")

	if(response != "Accept")
		to_chat(user, span_warning("[H] declined your offer."))
		return

	// Check if user still has the item and is nearby
	if(QDELETED(src) || used || !user.is_holding(src))
		return
	if(get_dist(user, H) > 2)
		to_chat(user, span_warning("[H] is too far away now."))
		return

	// Notify any prior Nursefather role on the target so it can self-clean before we overwrite it.
	SEND_SIGNAL(H, COMSIG_NURSEFATHER_RECRUITMENT_OVERRIDE, user, src)

	// Mark as used
	used = TRUE

	// Perform subtype-specific recruitment
	recruit_apprentice(H, user)

	// Consume the item
	qdel(src)

/// Returns the text shown to the target when offered recruitment
/obj/item/apprentice_recruitment/proc/get_offer_text(mob/living/user)
	return "[user] is offering to recruit you. Do you accept?"

/// Returns the title of the offer alert dialog
/obj/item/apprentice_recruitment/proc/get_offer_title()
	return "Recruitment Offer"

/// Override this to perform subtype-specific recruitment logic
/obj/item/apprentice_recruitment/proc/recruit_apprentice(mob/living/carbon/human/H, mob/living/user)
	return

/// Helper to update target's ID card assignment
/obj/item/apprentice_recruitment/proc/update_id_card(mob/living/carbon/human/H, assignment)
	var/obj/item/card/id/id_card = H.get_idcard(TRUE)

	// If no ID found directly, check PDA
	if(!id_card)
		for(var/obj/item/pda/P in H.GetAllContents())
			if(P.id)
				id_card = P.id
				break

	if(id_card)
		id_card.assignment = assignment
		id_card.update_label()
		id_card.update_icon()
