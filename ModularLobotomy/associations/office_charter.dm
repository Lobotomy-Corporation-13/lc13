// Office Charter Item - Used to establish new fixer offices
/obj/item/office_charter
	name = "office charter"
	desc = "An official document for establishing a new fixer office. Use this to create your own office."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "docs_blue"
	w_class = WEIGHT_CLASS_SMALL
	custom_price = 500
	var/used = FALSE

/obj/item/office_charter/attack_self(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("Only humans can establish offices!"))
		return

	var/mob/living/carbon/human/H = user
	if(!H.mind)
		to_chat(user, span_warning("You need a functioning mind to establish an office!"))
		return

	// Check fixer registration on fixers maptype
	if(SSmaptype.maptype == "fixers")
		if(!H.mind.registered_fixer)
			to_chat(user, span_warning("You must be a registered fixer to establish an office. Register at a Fixer Grade Terminal."))
			return

	if(used)
		to_chat(user, span_warning("This charter has already been used!"))
		return

	// Check if user already leads an office
	for(var/datum/fixer_office/F in GLOB.all_fixer_offices)
		if(F.director == H)
			to_chat(user, span_warning("You already lead an office!"))
			return
		if(H in F.members)
			to_chat(user, span_warning("You must leave your current office first!"))
			return

	var/office_name = stripped_input(user, "Enter your office name:", "Office Charter", "Unnamed Office", MAX_NAME_LEN)
	if(!office_name)
		return

	// Choose office type
	var/list/office_types = list(
		"Fishing Office" = /obj/item/structurecapsule/fixer,
		"Combat Office" = /obj/item/structurecapsule/fixer/combat,
		"Delivery Office" = /obj/item/structurecapsule/fixer/delivery,
		"Recon Office" = /obj/item/structurecapsule/fixer/recon,
		"Contract Office" = /obj/item/structurecapsule/fixer/contract
	)

	var/office_type_choice = input(user, "Choose your office type:", "Office Charter") as null|anything in office_types
	if(!office_type_choice)
		return

	var/capsule_type = office_types[office_type_choice]

	// Choose office color
	var/office_color = input(user, "Choose your office color:", "Office Charter") as color|null
	if(!office_color)
		office_color = "#000000"

	// Choose starting armor box
	var/list/armor_boxes = list(
		"Fixer Suit" = /obj/item/storage/box/miscarmor,
		"Fixer Black Suit" = /obj/item/storage/box/miscarmor/two,
		"Fixer Plate Armor" = /obj/item/storage/box/miscarmor/three,
		"Fixer Kimono" = /obj/item/storage/box/miscarmor/four,
		"Fixer Long Jacket" = /obj/item/storage/box/miscarmor/five,
		"Fixer Armored Turtleneck" = /obj/item/storage/box/miscarmor/six
	)

	var/armor_choice = input(user, "Choose your starting armor box:", "Office Charter") as null|anything in armor_boxes
	if(!armor_choice)
		return

	var/armor_type = armor_boxes[armor_choice]

	// Create the office
	var/datum/fixer_office/new_office = new
	new_office.name = office_name
	new_office.director = H
	new_office.office_color = office_color
	new_office.creation_time = world.time

	// Add director to office
	new_office.add_member(H)

	// Give the director recruitment badges
	var/badges_to_give = 5
	to_chat(user, span_notice("You establish [office_name]! Take these recruitment badges to invite others."))
	for(var/i in 1 to badges_to_give)
		var/obj/item/clothing/accessory/office_badge/badge = new(get_turf(user))
		badge.linked_office = new_office
		badge.name = "[office_name] recruitment badge"
		badge.update_icon()
		// Try to put in hands or drop at feet
		if(!H.put_in_hands(badge))
			badge.forceMove(get_turf(user))
		to_chat(user, span_notice("You receive a recruitment badge."))

	// Give the director their office structure capsule
	var/obj/item/structurecapsule/fixer/capsule = new capsule_type(get_turf(user))
	if(!H.put_in_hands(capsule))
		capsule.forceMove(get_turf(user))
	to_chat(user, span_notice("You receive a [office_type_choice] capsule to deploy your office building."))

	// Give the director their starting armor box
	var/obj/item/storage/box/miscarmor/armor_box = new armor_type(get_turf(user))
	if(!H.put_in_hands(armor_box))
		armor_box.forceMove(get_turf(user))
	to_chat(user, span_notice("You receive a [armor_choice] armor kit for your office."))

	qdel(src)

	// Add to global list
	GLOB.all_fixer_offices += new_office

	// Announce office creation
	minor_announce("[office_name] has been established by [H.real_name]!", "Office Registration")

// Office Recruitment Badge
/obj/item/clothing/accessory/office_badge
	name = "office recruitment badge"
	desc = "Use this on someone to invite them to join an office."
	icon = 'icons/obj/clothing/accessories.dmi'
	icon_state = "lawyerbadge"
	w_class = WEIGHT_CLASS_TINY
	var/datum/fixer_office/linked_office
	var/used = FALSE

/obj/item/clothing/accessory/office_badge/examine(mob/user)
	. = ..()
	if(linked_office)
		if(linked_office in GLOB.all_fixer_offices)
			. += span_notice("This badge is for [linked_office.name].")
			if(!used)
				. += span_notice("Representative: [linked_office.director?.real_name || "Unknown"]")
				. += span_notice("Members: [linked_office.members.len]/[linked_office.max_members]")
			else
				. += span_notice("This badge has already been used for recruitment.")
		else
			. += span_warning("This badge is from the now-defunct [linked_office.name].")

/obj/item/clothing/accessory/office_badge/attack(mob/living/carbon/human/M, mob/living/user)
	if(!linked_office)
		to_chat(user, span_warning("This badge is not linked to any office!"))
		return

	// Check if office still exists
	if(!(linked_office in GLOB.all_fixer_offices))
		to_chat(user, span_warning("This office no longer exists!"))
		linked_office = null
		name = "defunct office badge"
		desc = "A badge from a disbanded office."
		update_icon()
		return

	if(used)
		to_chat(user, span_warning("This badge has already been used for recruitment!"))
		return

	if(!ishuman(M))
		to_chat(user, span_warning("Only humans can join offices!"))
		return

	if(!M.mind)
		to_chat(user, span_warning("They need a functioning mind to join an office!"))
		return

	if(M == user && user != linked_office.director)
		to_chat(user, span_warning("You can't invite yourself!"))
		return

	// Check fixer registration on fixers maptype
	if(SSmaptype.maptype == "fixers")
		if(!M.mind.registered_fixer)
			to_chat(user, span_warning("[M] must be a registered fixer to join an office. They need to register at a Fixer Grade Terminal."))
			return

	// Check if target is already in an office
	for(var/datum/fixer_office/F in GLOB.all_fixer_offices)
		if(M in F.members)
			to_chat(user, span_warning("[M] is already in an office!"))
			return

	// Check member limit
	if(linked_office.members.len >= linked_office.max_members)
		to_chat(user, span_warning("[linked_office.name] is at maximum capacity!"))
		return

	// Offer membership
	var/choice = alert(M, "[user] invites you to join [linked_office.name]. Accept?", "Office Invitation", "Yes", "No")
	if(choice != "Yes")
		to_chat(user, span_warning("[M] declined the invitation."))
		return

	// Add to office
	linked_office.add_member(M)
	to_chat(M, span_nicegreen("You have joined [linked_office.name]!"))
	to_chat(user, span_nicegreen("[M] has joined your office!"))

	// Mark the badge as used instead of deleting
	used = TRUE
	name = "[linked_office.name] badge"
	desc = "A badge showing membership in [linked_office.name]."
	to_chat(user, span_notice("The recruitment badge is now a standard office badge."))

/obj/item/clothing/accessory/office_badge/update_icon()
	. = ..()
	if(linked_office && (linked_office in GLOB.all_fixer_offices))
		add_atom_colour(linked_office.office_color, FIXED_COLOUR_PRIORITY)
	else if(linked_office)
		// Office was disbanded
		add_atom_colour("#808080", FIXED_COLOUR_PRIORITY) // Gray color for defunct
	if(used)
		alpha = 200 // Slightly transparent to show it's been used

// The badge can be attached to clothing
/obj/item/clothing/accessory/office_badge/can_attach_accessory(obj/item/clothing/U, mob/user)
	if(!used)
		to_chat(user, span_warning("This is a recruitment badge, not meant to be worn yet!"))
		return FALSE
	return ..()
