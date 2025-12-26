// Debug item for testing resurgence machine resources
/obj/item/resurgence_debugger
	name = "resurgence core debugger"
	desc = "A debug tool for adjusting charge and faith values."
	icon = 'icons/obj/device.dmi'
	icon_state = "multitool"
	w_class = WEIGHT_CLASS_SMALL
	var/mode = "charge" // "charge" or "faith"

/obj/item/resurgence_debugger/attack_self(mob/user)
	mode = mode == "charge" ? "faith" : "charge"
	to_chat(user, "<span class='notice'>Switched to [mode] adjustment mode.</span>")
	playsound(src, 'sound/weapons/empty.ogg', 50, TRUE)

/obj/item/resurgence_debugger/afterattack(mob/living/carbon/human/M, mob/living/user, proximity)
	if(!proximity)
		return
	if(!istype(M))
		return

	if(!istype(M.dna?.species, /datum/species/resurgence_machine))
		to_chat(user, "<span class='warning'>[M] is not a resurgence machine!</span>")
		return

	var/obj/item/organ/resurgence_core/core = M.getorganslot(ORGAN_SLOT_HEART)
	if(!istype(core))
		to_chat(user, "<span class='warning'>[M] has no resurgence core!</span>")
		return

	if(mode == "charge")
		var/amount = input(user, "Adjust charge by how much? (Current: [core.charge]/[core.max_charge])", "Charge Adjustment", 10) as num
		if(!amount)
			return
		core.adjust_charge(amount)
		to_chat(user, "<span class='notice'>Adjusted [M]'s charge by [amount]. New value: [core.charge]/[core.max_charge]</span>")
	else
		var/amount = input(user, "Adjust faith by how much? (Current: [core.faith]/[core.max_faith])", "Faith Adjustment", 10) as num
		if(!amount)
			return
		core.adjust_faith(amount)
		to_chat(user, "<span class='notice'>Adjusted [M]'s faith by [amount]. New value: [core.faith]/[core.max_faith]</span>")

/obj/item/resurgence_debugger/examine(mob/user)
	. = ..()
	. += "<span class='notice'>Currently in <b>[mode]</b> adjustment mode.</span>"
	. += "<span class='notice'>Use in hand to switch modes.</span>"
	. += "<span class='notice'>Click on a resurgence machine to adjust their [mode].</span>"
