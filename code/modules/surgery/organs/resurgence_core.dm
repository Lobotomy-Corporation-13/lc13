/obj/item/organ/resurgence_core
	name = "mechanical core"
	desc = "A complex mechanical core that powers a resurgence machine, managing their charge."
	icon = 'icons/obj/assemblies/new_assemblies.dmi'
	icon_state = "rawcore_bluespace"
	zone = BODY_ZONE_CHEST
	slot = ORGAN_SLOT_HEART
	organ_flags = ORGAN_SYNTHETIC
	actions_types = list(/datum/action/item_action/organ_action/resurgence_check)

	// Resource variables
	var/charge = 100
	var/max_charge = 100
	var/charge_regen_rate = 1 // per 2 seconds (life tick)

	var/faith = 100
	var/max_faith = 100
	var/faith_decay_rate = 0.5 // per 2 seconds (reduced since life ticks every 2 seconds)

	var/faith_tick_counter = 0 // Track ticks for faith decay

/obj/item/organ/resurgence_core/on_life()
	..()
	if(!owner || owner.stat == DEAD)
		return

	// Regenerate charge
	adjust_charge(charge_regen_rate)

	// Decay faith every ~60 seconds (30 life ticks)
	faith_tick_counter++
	if(faith_tick_counter >= 30)
		adjust_faith(-faith_decay_rate)
		faith_tick_counter = 0

		// Low faith effects
		if(faith < 30)
			if(prob(5))
				to_chat(owner, "<span class='warning'>Your faith wavers... You feel less effective.</span>")
			owner.add_movespeed_modifier(/datum/movespeed_modifier/resurgence_low_faith)
		else
			owner.remove_movespeed_modifier(/datum/movespeed_modifier/resurgence_low_faith)

/obj/item/organ/resurgence_core/proc/adjust_charge(amount)
	charge = clamp(charge + amount, 0, max_charge)

/obj/item/organ/resurgence_core/proc/adjust_faith(amount)
	faith = clamp(faith + amount, 0, max_faith)

/obj/item/organ/resurgence_core/proc/can_use_charge(amount)
	return charge >= amount

/obj/item/organ/resurgence_core/proc/use_charge(amount)
	if(can_use_charge(amount))
		adjust_charge(-amount)
		return TRUE
	return FALSE

/obj/item/organ/resurgence_core/emp_act(severity)
	. = ..()
	if(!owner)
		return

	// EMPs damage the core and drain charge
	switch(severity)
		if(EMP_LIGHT)
			owner.adjustBruteLoss(10)
			adjust_charge(-20)
			to_chat(owner, "<span class='warning'>Your core systems are disrupted by the electromagnetic pulse!</span>")
		if(EMP_HEAVY)
			owner.adjustBruteLoss(20)
			adjust_charge(-40)
			owner.Paralyze(20)
			to_chat(owner, "<span class='danger'>Your core systems are severely disrupted by the electromagnetic pulse!</span>")

// Movespeed modifier for low faith
/datum/movespeed_modifier/resurgence_low_faith
	variable = TRUE
	multiplicative_slowdown = 0.3

// Action for checking resources
/datum/action/item_action/organ_action/resurgence_check
	name = "Check Core Status"
	desc = "Check your mechanical core's charge and faith levels."

/datum/action/item_action/organ_action/resurgence_check/Trigger()
	. = ..()
	if(!istype(target, /obj/item/organ/resurgence_core))
		return

	var/obj/item/organ/resurgence_core/core = target
	if(!core.owner)
		return

	var/mob/living/carbon/human/H = core.owner

	// Charge message
	to_chat(H, "<span class='notice'>Charge: [core.charge]/[core.max_charge]</span>")

	// Faith message with color coding
	var/faith_percentage = (core.faith / core.max_faith) * 100
	var/faith_message
	var/faith_color

	if(faith_percentage >= 80)
		faith_message = "Your faith is unwavering and strong."
		faith_color = "green"
	else if(faith_percentage >= 60)
		faith_message = "Your faith remains steady."
		faith_color = "blue"
	else if(faith_percentage >= 40)
		faith_message = "Your faith is beginning to waver."
		faith_color = "yellow"
	else if(faith_percentage >= 20)
		faith_message = "Your faith is dangerously low. Seek communal activities soon."
		faith_color = "orange"
	else
		faith_message = "Your faith is nearly depleted! You desperately need spiritual restoration!"
		faith_color = "red"

	to_chat(H, "<span style='color: [faith_color];'>Faith: [core.faith]/[core.max_faith] - [faith_message]</span>")
