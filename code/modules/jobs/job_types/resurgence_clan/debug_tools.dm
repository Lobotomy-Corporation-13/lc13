// Debug item for testing resurgence machine resources
/obj/item/resurgence_debugger
	name = "resurgence core debugger"
	desc = "A debug tool for adjusting charge and faith values."
	icon = 'icons/obj/device.dmi'
	icon_state = "multitool"
	w_class = WEIGHT_CLASS_SMALL
	var/mode = "charge" // "charge", "faith", or "faith_rate"

/obj/item/resurgence_debugger/attack_self(mob/user)
	switch(mode)
		if("charge")
			mode = "faith"
		if("faith")
			mode = "faith_rate"
		if("faith_rate")
			mode = "charge"
	to_chat(user, span_notice("Switched to [mode] adjustment mode."))
	playsound(src, 'sound/weapons/empty.ogg', 50, TRUE)

/obj/item/resurgence_debugger/afterattack(mob/living/carbon/human/M, mob/living/user, proximity)
	if(!proximity)
		return
	if(!istype(M))
		return

	if(!istype(M.dna?.species, /datum/species/resurgence_machine))
		to_chat(user, span_warning("[M] is not a resurgence machine!"))
		return

	var/obj/item/organ/resurgence_core/core = M.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		to_chat(user, span_warning("[M] has no resurgence core!"))
		return

	switch(mode)
		// CHARGE DEBUG DISABLED - charge system is disabled
		// if("charge")
		// 	var/amount = input(user, "Adjust charge by how much? (Current: [core.charge]/[core.max_charge])", "Charge Adjustment", 10) as num
		// 	if(!amount)
		// 		return
		// 	core.adjust_charge(amount)
		// 	to_chat(user, span_notice("Adjusted [M]'s charge by [amount]. New value: [core.charge]/[core.max_charge]"))

		if("faith")
			// Directly adjust faith value
			var/amount = input(user, "Adjust faith by how much? (Current: [core.faith]/[core.max_faith])", "Faith Adjustment", 10) as num
			if(isnull(amount))
				return
			core.faith = clamp(core.faith + amount, 0, core.max_faith)
			to_chat(user, span_notice("Adjusted [M]'s faith by [amount]. New value: [core.faith]/[core.max_faith]"))

		if("faith_rate")
			// Add a debug faith rate event
			var/rate = input(user, "Set debug faith rate? (Current rate: [core.faith_change_rate] per 5 sec)\nPositive = gaining, Negative = losing, 0 = clear", "Faith Rate", 1) as num
			if(isnull(rate))
				return
			if(rate == 0)
				core.clear_faith_event("debug")
				to_chat(user, span_notice("Cleared debug faith rate event. Current rate: [core.faith_change_rate] per 5 sec"))
			else
				core.add_faith_event("debug", new /datum/faith_event/debug(
					"Debug rate adjustment",
					rate,
					null,
					"debug"
				))
				to_chat(user, span_notice("Added debug faith rate ([rate >= 0 ? "+" : ""][rate] per 5 sec). Current total rate: [core.faith_change_rate] per 5 sec"))

/obj/item/resurgence_debugger/examine(mob/user)
	. = ..()
	. += span_notice("Currently in <b>[mode]</b> adjustment mode.")
	. += span_notice("Use in hand to cycle modes: charge -> faith -> faith_rate -> charge")
	switch(mode)
		if("charge")
			. += span_notice("Click on a resurgence machine to adjust their charge directly.")
		if("faith")
			. += span_notice("Click on a resurgence machine to adjust their faith directly.")
		if("faith_rate")
			. += span_notice("Click on a resurgence machine to add a faith rate modifier.")
			. += span_notice("Enter 0 to clear the debug rate event.")
