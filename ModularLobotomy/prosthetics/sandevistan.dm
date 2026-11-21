/obj/item/organ/cyberimp/chest/sandevistan
	name = "\improper Quicksilver Implant"
	desc = "Experimental military augments made by an unknown Wing before leaked to the market. <br>\
			Increases your speed exponentially but risks"
	syndicate_implant = TRUE
	actions_types = list(/datum/action/item_action/organ_action/use/sandevistan)
	implant_overlay = "implant-reinforcers"

/datum/action/item_action/organ_action/use/sandevistan
	COOLDOWN_DECLARE(sandy_cooldown)

/datum/action/item_action/organ_action/use/sandevistan/Trigger()
	. = ..()
	var/mob/living/carbon/human/user = usr
	if(!COOLDOWN_FINISHED(src, sandy_cooldown))
		to_chat(user, span_warning("Implant is charging up!"))
		return FALSE
	if(prob(5))
		user.SanityLossEffect(PRUDENCE_ATTRIBUTE)
		to_chat(user, span_warning("Augment Psychosis detected"))
	RegisterSignal(user, COMSIG_MOB_APPLY_DAMGE, PROC_REF(sandy_dodge))
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(sandy_visual))
	user.add_movespeed_modifier(/datum/movespeed_modifier/sandevistan)
	user.visible_message("[user.name] is speeding up heavily!", "You feel like you can move faster than sound!")
	COOLDOWN_START(src, sandy_cooldown, 20 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(sandy_down) , user), 15 SECONDS)


/datum/action/item_action/organ_action/use/sandevistan/proc/sandy_down()
	var/mob/living/carbon/human/user = usr
	UnregisterSignal(user, COMSIG_MOB_APPLY_DAMGE)
	UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
	user.remove_movespeed_modifier(/datum/movespeed_modifier/sandevistan)

/datum/action/item_action/organ_action/use/sandevistan/proc/sandy_dodge(datum/source, damage, damagetype, def_zone, attack_source, flags, attack_type)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/user = usr
	if(damage > 0 && prob(100)) //prob 100 to test it for
		user.visible_message("[user.name] dodged the attack completely!", "You dodged the attack easily!")
		playsound(user, pick('sound/weapons/fixer/generic/dodge3.ogg', 'sound/weapons/fixer/generic/dodge.ogg', 'sound/weapons/fixer/generic/dodge2.ogg'), 50, TRUE)
		return COMPONENT_MOB_DENY_DAMAGE

/datum/action/item_action/organ_action/use/sandevistan/proc/sandy_visual(atom/newloc, dir)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/user = usr

	new /obj/effect/sandevistan(user.loc, user)

/datum/movespeed_modifier/sandevistan
	multiplicative_slowdown = -1

/obj/effect/sandevistan

	name = "Za Warudo"
	desc = "..."
	anchored = TRUE
	var/effect_alpha = 155
	var/effect_fadeout = 0.5 SECONDS

/obj/effect/temporis/Initialize(mapload, mob/living/creator)
	. = ..()

	name = creator?.name
	appearance = creator?.appearance
	dir = creator?.dir

	animate(src, pixel_x = rand(-32,32), pixel_y = rand(-32,32), alpha = effect_alpha, time = effect_fadeout)

	// Delete this effect after half a second
	QDEL_IN(src, effect_fadeout)
