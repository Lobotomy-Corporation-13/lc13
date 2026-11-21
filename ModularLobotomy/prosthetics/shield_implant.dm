/obj/item/organ/cyberimp/chest/omni_shield
	name = "\improper Omni-Shield Emitter Implant"
	desc = "Prototypes from an anonymous Workshop that were slavaging L Corp technology. <br>\
			Costs 50 Sanity to apply LC13 Omnishield. Also apply 10% slowdown."
	syndicate_implant = TRUE
	actions_types = list(/datum/action/item_action/organ_action/use/omni_shield)
	implant_overlay = "implant-reinforcers"


/obj/item/organ/cyberimp/chest/omni_shield/Insert(mob/living/carbon/M, special, drop_if_replaced)
	. = ..()
	var/mob/living/carbon/human/user = M
	user.add_movespeed_modifier(/datum/movespeed_modifier/omni_shield_implant)

/obj/item/organ/cyberimp/chest/omni_shield/Remove(mob/living/carbon/M, special, drop_if_replaced)
	. = ..()
	var/mob/living/carbon/human/user = M
	user.remove_movespeed_modifier(/datum/movespeed_modifier/omni_shield_implant)

/datum/action/item_action/organ_action/use/omni_shield/Trigger()
	. = ..()

	if(ishuman(owner))
		var/mob/living/carbon/human/user = owner
		if(user.sanityhealth < 50) //not enough sanity
			to_chat(user, span_boldwarning("Not enough sanity to activate implant."))
		user.apply_status_effect(/datum/status_effect/interventionshield/quad)
		user.adjustSanityLoss(50)

/datum/movespeed_modifier/omni_shield_implant
	multiplicative_slowdown = 0.1
