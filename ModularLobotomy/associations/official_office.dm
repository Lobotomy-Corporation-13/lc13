/obj/item/office_marker
	desc = "A small device which allows hana to assign official offices."
	name = "office marker"
	icon = 'icons/obj/grenade.dmi'
	icon_state = "delivery"
	inhand_icon_state = "flashbang"
	var/list/usable_roles = list("Hana Representative", "Hana Administrator", "Hana Intern")
	var/current_office

/obj/item/office_marker/examine(mob/user)
	. = ..()
	. += span_notice("This marker currently adds people to the [current_office] office.")

/obj/item/office_marker/attack_self(mob/living/carbon/human/user)
	//only hana can use this.
	if(!(user?.mind?.assigned_role in usable_roles))
		to_chat(user, span_danger("You cannot use this item, as you are not a part of Hana Association."))
		return

	current_office = input("Set a new office", "Set Office") as null | text
	to_chat(user, span_nicegreen("[src] will now add people to the [current_office] Office."))

/obj/item/office_marker/afterattack(atom/target, mob/user, proximity_flag)
	. = ..()
	if(!(user?.mind?.assigned_role in usable_roles))
		to_chat(user, span_danger("You cannot use this item, as you are not a part of Hana Association."))
		return
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		if(!H.assigned_office)
			H.assigned_office = current_office
			to_chat(user, span_nicegreen("You added [target] to the [current_office] Office."))
		else
			var/hana_ask = alert("Target is a a part of the [H.assigned_office] Office, do you wish to remove them?", "Office Update", "Yes", "No")
			if(hana_ask == "Yes")
				H.assigned_office = null
				to_chat(user, span_nicegreen("You removed [target] from the [H.assigned_office] Office."))

/obj/item/office_marker/syndicate
	desc = "A small device which allows syndicates to bypass the office gates."
	name = "syndicate bypass"
	icon = 'icons/obj/grenade.dmi'
	icon_state = "delivery"
	inhand_icon_state = "flashbang"
	usable_roles = list("Blade Lineage Cutthroat", "Index Messenger", "Kurokumo Kashira", "Grand Inquisitor", "Thumb Sottocapo", "Thumb East Capo")

/obj/item/office_marker/syndicate/attack_self(mob/living/carbon/human/user)
	return

/obj/item/office_marker/syndicate/afterattack(atom/target, mob/user, proximity_flag)
	if(!(user?.mind?.assigned_role in usable_roles))
		to_chat(user, span_danger("You cannot use this item, as you are not a part of a syndicate."))
		return
	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		H.assigned_office = "syndicate_bypass"
		to_chat(user, span_nicegreen("You gave the bypass to [H]."))

/obj/item/attribute_increase/fixer/office
	name = "office n corp training accelerator"
	desc = "A fluid used to increase the stats of a non-association fixer. Use in hand to activate. Increases stats more the lower your potential. Effects eveyone a part of your office."
	amount = 1
	var/public_use = FALSE

/obj/item/attribute_increase/fixer/office/proc/ApplyBenefit(mob/living/carbon/human/H)
	// Check fixer registration on fixers maptype
	if(SSmaptype.maptype == "fixers")
		if(!H.mind?.registered_fixer)
			to_chat(H, span_danger("You must be a registered fixer to benefit from this item. Register at a Fixer Grade Terminal."))
			return FALSE

	if(!public_use)
		if(!(H?.mind?.assigned_role in usable_roles))
			to_chat(H, span_danger("You cannot use this item, as you must not belong to an association."))
			return FALSE

	//max stats can't gain stats
	if(get_attribute_level(H, TEMPERANCE_ATTRIBUTE)>=130)
		to_chat(H, span_danger("You feel like you won't gain anything."))
		return FALSE

	to_chat(H, span_nicegreen("You suddenly feel different."))
	//Guarantee one
	H.adjust_all_attribute_levels(amount)
	to_chat(H, "<span class='nicegreen'>You gain 1 potential!</span>")

	//Adjust by an extra attribute under level 2
	if(get_attribute_level(H, TEMPERANCE_ATTRIBUTE)<=40)
		H.adjust_all_attribute_levels(amount)
		H.adjust_all_attribute_levels(amount)
		to_chat(H, "<span class='nicegreen'>You gain 1 potential!</span>")

	//And one more under level 3
	if(get_attribute_level(H, TEMPERANCE_ATTRIBUTE)<=60)
		H.adjust_all_attribute_levels(amount)
		to_chat(H, "<span class='nicegreen'>You gain 1 potential!</span>")

	return TRUE

/obj/item/attribute_increase/fixer/office/attack_self(mob/living/carbon/human/user)
	// Check fixer registration on fixers maptype
	if(SSmaptype.maptype == "fixers")
		if(!user.mind?.registered_fixer)
			to_chat(user, span_danger("You must be a registered fixer to use this item. Register at a Fixer Grade Terminal."))
			return

	if(!public_use)
		if(!(user?.mind?.assigned_role in usable_roles))
			to_chat(user, span_danger("You cannot use this item, as you must not belong to an association."))
			return

	// Check if user is part of a new fixer office system
	var/datum/fixer_office/user_office = null
	for(var/datum/fixer_office/F in GLOB.all_fixer_offices)
		if(user in F.members)
			user_office = F
			break

	// Check if user has old assigned_office
	var/user_has_old_office = user.assigned_office && user.assigned_office != "syndicate_bypass"

	// User must be in one of the office systems
	if(!user_office && !user_has_old_office)
		to_chat(user, span_danger("You cannot use this item, as you are not a part of an office."))
		return

	var/list/affected_members = list()

	// Apply to nearby office members
	for(var/mob/living/carbon/human/H in range(5, get_turf(src)))
		if(H == user) // Skip user for now, we'll apply to them at the end
			continue

		var/should_apply = FALSE

		// Check new office system
		if(user_office && (H in user_office.members))
			should_apply = TRUE
		// Check old office system
		else if(user_has_old_office && H.assigned_office == user.assigned_office)
			should_apply = TRUE

		if(should_apply)
			if(ApplyBenefit(H))
				affected_members += H

	// Apply to the user as well
	if(ApplyBenefit(user))
		affected_members += user

	if(affected_members.len)
		var/office_name = user_office ? user_office.name : user.assigned_office
		visible_message(span_notice("[user] uses [src], empowering [affected_members.len] member\s of [office_name]!"))

	. = ..()

/obj/machinery/scanner_gate/officescanner
	name = "office scanner gate"
	density = FALSE
	locked = TRUE
	use_power = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/list/check_times = list()
	var/list/usable_roles = list("Civilian", "Office Representative", "Office Fixer",
		"Subsidary Office Representative", "Fixer")

/obj/machinery/scanner_gate/officescanner/auto_scan(atom/movable/AM)
	return

/obj/machinery/scanner_gate/officescanner/attackby(obj/item/W, mob/user, params)
	return

/obj/machinery/scanner_gate/officescanner/emag_act(mob/user)
	return

#define OFFICE_MESSAGE_COOLDOWN 50
/obj/machinery/scanner_gate/officescanner/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(!ishuman(mover))
		return
	var/mob/living/carbon/human/H = mover
	set_scanline("scanning", 5)

	// Only registered fixers can pass
	if(!H.mind?.registered_fixer)
		if(!check_times[H] || check_times[H] < world.time)
			to_chat(H, span_boldwarning("ACCESS DENIED. Only registered fixers may pass. Register at a Fixer Grade Terminal."))
			check_times[H] = world.time + OFFICE_MESSAGE_COOLDOWN
		alarm_beep()
		return FALSE

#undef OFFICE_MESSAGE_COOLDOWN
