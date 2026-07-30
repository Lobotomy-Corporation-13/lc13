//--------------------------------------
// Body Modification Tester Tool
//--------------------------------------

/obj/item/body_modification_tester
	name = "Body Modification Tester"
	desc = "A device that can check what rank of skill modifications the target can use."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "records_stats"
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_SMALL
	var/list/stats = list(
		FORTITUDE_ATTRIBUTE,
		PRUDENCE_ATTRIBUTE,
		TEMPERANCE_ATTRIBUTE,
		JUSTICE_ATTRIBUTE
	)
	var/list/rankAttributeReqs = list(20, 40, 60, 80, 100)

/obj/item/body_modification_tester/afterattack(atom/target, mob/user, proximity_flag)
	. = ..()
	if(!ishuman(target))
		to_chat(user, span_notice("No human identified."))
		return

	playsound(get_turf(src), 'sound/machines/cryo_warning.ogg', 50, TRUE, -1)
	var/mob/living/carbon/human/H = target

	// Check for existing skill modification
	var/obj/item/organ/cyberimp/chest/body_modification/SA = H.getorganslot(ORGAN_SLOT_HEART_AID)
	if(SA && istype(SA, /obj/item/organ/cyberimp/chest/body_modification))
		to_chat(user, span_notice("The target currently has a Rank [SA.rank] skill modification installed."))
		to_chat(user, span_notice("Modification Info:"))
		to_chat(user, span_notice("- Slots: [SA.max_slots]"))
		to_chat(user, span_notice("- Max Charge: [SA.max_charge]"))
		to_chat(user, span_notice("- Current Charge: [SA.current_charge]"))
		to_chat(user, span_notice("- Attached Skills: [length(SA.attached_skills)]"))
		for(var/skill_type in SA.attached_skills)
			var/datum/action/A = skill_type
			to_chat(user, span_notice("  • [initial(A.name)]"))

	// Calculate stat average
	var/stattotal = 0
	for(var/attribute in stats)
		stattotal += get_attribute_level(H, attribute)
	stattotal /= 4 // Average of stats

	// Determine maximum usable rank
	var/best_rank = 0
	for(var/i = 1 to 5)
		if(stattotal >= rankAttributeReqs[i])
			best_rank = i
		else
			break

	// Display results
	to_chat(user, span_notice("Stat Analysis:"))
	to_chat(user, span_notice("- Average stat level: [stattotal]"))

	if(best_rank < 1)
		to_chat(user, span_warning("The target is unable to use any skill modifications (minimum average stat requirement: [rankAttributeReqs[1]])."))
	else
		to_chat(user, span_notice("The target is able to use rank [best_rank] or lower skill modifications."))
		if(best_rank < 5)
			to_chat(user, span_notice("For rank [best_rank + 1], they need an average of [rankAttributeReqs[best_rank + 1]] stats (currently: [stattotal])."))

/obj/item/body_modification_tester/examine(mob/user)
	. = ..()
	. += span_notice("Use on a human to check their skill modification compatibility.")
	. += span_notice("Skill modification stat requirements:")
	for(var/i = 1 to 5)
		. += span_notice("- Rank [i]: Average stats ≥ [rankAttributeReqs[i]]")

//--------------------------------------
// Body Modification Remover Tool
//--------------------------------------

/obj/item/body_modification_remover
	name = "Body Modification Remover"
	desc = "A specialized tool that can remove skill modifications from targets."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "gadget1"
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_SMALL
	var/list/allowed_roles = list("Prosthetics Surgeon", "Office Director", "Office Fixer", "Doctor", "Fixer")

/obj/item/body_modification_remover/examine(mob/user)
	. = ..()
	. += span_notice("Use on a human to remove skill modifications.")
	. += span_notice("Can remove both implanted and injectable skill modifications.")

/obj/item/body_modification_remover/attack(mob/target, mob/user)
	. = ..()
	if(!can_use_remover(user))
		to_chat(user, span_warning("You don't have the expertise to use this tool!"))
		return

	if(!ishuman(target))
		to_chat(user, span_warning("You can only use this on humans!"))
		return

	var/mob/living/carbon/human/H = target

	// Check for implanted skill modification
	var/obj/item/organ/cyberimp/chest/body_modification/SA = H.getorganslot(ORGAN_SLOT_HEART_AID)
	if(SA && istype(SA, /obj/item/organ/cyberimp/chest/body_modification))
		to_chat(user, span_notice("You begin removing the implanted skill modification from [H]..."))

		if(!do_after(user, 5 SECONDS, target = H))
			to_chat(user, span_warning("You stop the removal process."))
			return

		// Remove all granted skills
		for(var/datum/action/A in SA.granted_actions)
			UnregisterSignal(A, COMSIG_ACTION_TRIGGER)
			A.Remove(H)
			qdel(A)
		SA.granted_actions.Cut()

		// Remove the organ and place it on the ground
		SA.Remove(H)
		SA.forceMove(get_turf(H))

		to_chat(user, span_notice("You successfully remove the implanted skill modification from [H]!"))
		to_chat(H, span_warning("You feel your modificationed abilities fading away."))
		playsound(get_turf(H), 'sound/items/deconstruct.ogg', 50, FALSE)
		return

	// Check for injectable skill modification
	for(var/obj/item/body_modification_injectable/inj in H.contents)
		if(inj.used)
			to_chat(user, span_notice("You begin removing the injectable skill modification from [H]..."))

			if(!do_after(user, 3 SECONDS, target = H))
				to_chat(user, span_warning("You stop the removal process."))
				return

			// Remove all skills granted by this injectable
			for(var/skill_type in inj.attached_skills)
				for(var/datum/action/A in H.actions)
					if(A.type == skill_type)
						UnregisterSignal(A, COMSIG_ACTION_TRIGGER)
						A.Remove(H)
						qdel(A)
						break

			// Remove the injectable and place it on the ground
			inj.forceMove(get_turf(H))
			inj.used = FALSE

			to_chat(user, span_notice("You successfully remove the injectable skill modification from [H]!"))
			to_chat(H, span_warning("You feel your modificationed abilities fading away."))
			playsound(get_turf(H), 'sound/items/syringeproj.ogg', 50, FALSE)
			return

	to_chat(user, span_warning("[H] doesn't have any skill modifications to remove!"))

/obj/item/body_modification_remover/proc/can_use_remover(mob/user)
	if(!user?.mind?.assigned_role)
		return FALSE
	return (user.mind.assigned_role in allowed_roles)

//--------------------------------------
// Body Modification Battery Items
//--------------------------------------

/obj/item/body_modification_battery
	name = "body modification battery"
	desc = "A specialized energy cell designed to recharge skill modifications."
	icon = 'icons/obj/power.dmi'
	icon_state = "cell"
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS
	custom_price = 100
	var/charge_amount = 50
	var/tier = 1

/obj/item/body_modification_battery/examine(mob/user)
	. = ..()
	. += span_notice("This is a Tier [tier] battery that restores [charge_amount] charge.")
	. += span_notice("Use in hand while having a skill modification (implanted or injectable) to recharge it.")

/obj/item/body_modification_battery/attack_self(mob/user)
	. = ..()
	if(!ishuman(user))
		to_chat(user, span_warning("Only humans can use skill modification batteries."))
		return

	var/mob/living/carbon/human/H = user

	// Check for implanted skill modification first
	var/obj/item/organ/cyberimp/chest/body_modification/SA = H.getorganslot(ORGAN_SLOT_HEART_AID)
	if(SA && istype(SA, /obj/item/organ/cyberimp/chest/body_modification))
		if(SA.current_charge >= SA.max_charge)
			to_chat(user, span_notice("Your implanted skill modification is already fully charged! ([SA.current_charge]/[SA.max_charge])"))
			return

		to_chat(user, span_notice("You begin connecting the battery to your implanted skill modification..."))
		playsound(src.loc, 'sound/abnormalities/clock/clank.ogg', 50, TRUE)

		if(!do_after(user, 3 SECONDS, target = user))
			to_chat(user, span_warning("You stop the charging process."))
			return

		var/charge_to_add = min(charge_amount, SA.max_charge - SA.current_charge)
		SA.current_charge += charge_to_add

		to_chat(user, span_notice("You successfully charge your implanted skill modification! (+[charge_to_add] charge, now [SA.current_charge]/[SA.max_charge])"))
		playsound(get_turf(user), 'sound/machines/ping.ogg', 50, FALSE)

		qdel(src)
		return

	// Check for injectable skill modification
	for(var/obj/item/body_modification_injectable/inj in H.contents)
		if(inj.used)
			if(inj.current_charge >= inj.max_charge)
				to_chat(user, span_notice("Your injectable skill modification is already fully charged! ([inj.current_charge]/[inj.max_charge])"))
				return

			to_chat(user, span_notice("You begin connecting the battery to your injectable skill modification..."))

			if(!do_after(user, 3 SECONDS, target = user))
				to_chat(user, span_warning("You stop the charging process."))
				return

			var/charge_to_add = min(charge_amount, inj.max_charge - inj.current_charge)
			inj.current_charge += charge_to_add

			to_chat(user, span_notice("You successfully charge your injectable skill modification! (+[charge_to_add] charge, now [inj.current_charge]/[inj.max_charge])"))
			playsound(get_turf(user), 'sound/machines/ping.ogg', 50, FALSE)

			qdel(src)
			return

	to_chat(user, span_warning("You don't have any skill modification installed!"))

/obj/item/body_modification_battery/tier2
	name = "body modification battery MK-II"
	desc = "An improved energy cell with higher capacity for skill modifications."
	icon_state = "hcell"
	custom_price = 200
	charge_amount = 100
	tier = 2

/obj/item/body_modification_battery/tier3
	name = "body modification battery MK-III"
	desc = "An advanced energy cell with substantial charging capacity."
	icon_state = "icell"
	custom_price = 300
	charge_amount = 200
	tier = 3

/obj/item/body_modification_battery/tier4
	name = "body modification battery MK-IV"
	desc = "A top-tier energy cell capable of major charge restoration."
	icon_state = "bscell"
	custom_price = 400
	charge_amount = 300
	tier = 4

// Imported batteries, fixers can get them from vending machines, however they are *3 as expensive.
/obj/item/body_modification_battery/imported
	name = "imported body modification battery"
	desc = "A specialized energy cell designed to recharge skill modifications. Imported from another district."
	color = LIGHT_COLOR_DARK_BLUE
	custom_price = 300

/obj/item/body_modification_battery/tier2/imported
	name = "imported body modification battery MK-II"
	desc = "An improved energy cell with higher capacity for skill modifications. Imported from another district."
	color = LIGHT_COLOR_DARK_BLUE
	custom_price = 600

/obj/item/body_modification_battery/tier3/imported
	name = "imported body modification battery MK-III"
	desc = "An advanced energy cell with substantial charging capacity. Imported from another district."
	color = LIGHT_COLOR_DARK_BLUE
	custom_price = 900

/obj/item/body_modification_battery/tier4/imported
	name = "imported body modification battery MK-IV"
	desc = "A top-tier energy cell capable of major charge restoration. Imported from another district."
	color = LIGHT_COLOR_DARK_BLUE
	custom_price = 1200
