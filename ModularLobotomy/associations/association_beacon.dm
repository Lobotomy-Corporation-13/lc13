//Captain blade beacon
/obj/item/choice_beacon/association
	name = "director's beacon"
	desc = "A beacon the director uses to ally with an association."

/obj/item/choice_beacon/association/generate_display_names()
	var/static/list/beacon_item_list
	if(!beacon_item_list)
		beacon_item_list = list(
			"Zwei Association Section 6" = /obj/item/storage/box/association/zwei,
			"Seven Association Section 4" = /obj/item/storage/box/association/seven,
			"Dieci Association Section 4" = /obj/item/storage/box/association/dieci,
			// "Cinq Association Section 3" = /obj/item/storage/box/association/cinq,
		)
	return beacon_item_list

/obj/item/choice_beacon/association/spawn_option(obj/choice, mob/living/M)
	// Determine association type from chosen box
	var/association_type
	if(ispath(choice, /obj/item/storage/box/association/zwei))
		association_type = ASSOCIATION_ZWEI
	else if(ispath(choice, /obj/item/storage/box/association/seven))
		association_type = ASSOCIATION_SEVEN
	else if(ispath(choice, /obj/item/storage/box/association/dieci))
		association_type = ASSOCIATION_DIECI
	else if(ispath(choice, /obj/item/storage/box/association/cinq))
		association_type = ASSOCIATION_CINQ
	// Spawn the equipment box
	new choice(get_turf(M))
	if(!association_type || !ishuman(M))
		to_chat(M, span_hear("Make sure you put the equipment in the armory."))
		return
	var/mob/living/carbon/human/director = M
	// Create the squad datum
	var/datum/association_squad/squad = new(association_type, director)
	GLOB.association_squads += squad
	// Register the Director with the squad
	squad.register_member(director, "director")
	// Spawn the registry tool for the Director
	var/obj/item/association_registry/tool = new(get_turf(director))
	tool.squad = squad
	to_chat(director, span_notice("You have aligned your section with [squad.association_name]. Use the Association Registry on your squad members to register them."))
	to_chat(director, span_hear("Make sure you put the equipment in the armory."))


//Zwei Asso
/obj/item/storage/box/association/zwei
	name = "Zwei Association Section 6"
	desc = "A kit from Section 1 containing Zwei association gear."

/obj/item/storage/box/association/zwei/PopulateContents()
	// Associate weapons (3)
	new /obj/item/ego_weapon/city/zweihander(src)
	new /obj/item/ego_weapon/city/zweihander(src)
	new /obj/item/ego_weapon/city/zweibaton(src)
	// Veteran weapon (1)
	new /obj/item/ego_weapon/city/zweihander/vet(src)
	// Director weapon (1)
	new /obj/item/ego_weapon/city/zweihander/vet(src)
	// Associate armor (3)
	new /obj/item/clothing/suit/armor/ego_gear/city/zwei(src)
	new /obj/item/clothing/suit/armor/ego_gear/city/zwei(src)
	new /obj/item/clothing/suit/armor/ego_gear/city/zweiriot(src)
	// Veteran armor (1)
	new /obj/item/clothing/suit/armor/ego_gear/city/zweivet(src)
	// Director armor (1)
	new /obj/item/clothing/suit/armor/ego_gear/city/zweileader(src)


//Dieci Asso
/obj/item/storage/box/association/dieci
	name = "Dieci Association Section 4"
	desc = "A kit from Section 1 containing Dieci association gear."

/obj/item/storage/box/association/dieci/PopulateContents()
	// Associate weapons (3) — fists + key mix
	new /obj/item/ego_weapon/city/dieci(src)
	new /obj/item/ego_weapon/city/dieci(src)
	new /obj/item/ego_weapon/city/dieci/key(src)
	// Veteran weapon (1) + key option
	new /obj/item/ego_weapon/city/dieci/vet(src)
	new /obj/item/ego_weapon/city/dieci/key/vet(src)
	// Director weapon (1) + key option
	new /obj/item/ego_weapon/city/dieci/director(src)
	new /obj/item/ego_weapon/city/dieci/key/director(src)
	// Associate armor (3)
	new /obj/item/clothing/suit/armor/ego_gear/city/dieci(src)
	new /obj/item/clothing/suit/armor/ego_gear/city/dieci(src)
	new /obj/item/clothing/suit/armor/ego_gear/city/dieci(src)
	// Veteran armor (1)
	new /obj/item/clothing/suit/armor/ego_gear/city/dieci/vet(src)
	// Director armor (1)
	new /obj/item/clothing/suit/armor/ego_gear/city/dieci/director(src)
	// Knowledge Tome (one per squad)
	new /obj/item/dieci_tome(src)

//Cinq Asso
/obj/item/storage/box/association/cinq
	name = "Cinq Association Section 3"
	desc = "A kit from Section 1 containing Cinq association gear."

/obj/item/storage/box/association/cinq/PopulateContents()
	// Stub - Cinq gear will be added in a future update
	return

//Liu Asso (deprecated - not selectable from beacon, kept for legacy compatibility)
/obj/item/storage/box/association/liu
	name = "Liu Association Section 5"
	desc = "A kit from Section 1 containing Liu association gear."

/obj/item/storage/box/association/liu/PopulateContents()
	new /obj/item/ego_weapon/city/liu/fist(src)
	new /obj/item/ego_weapon/city/liu/fist(src)
	new /obj/item/ego_weapon/city/liu/fist(src)
	new /obj/item/ego_weapon/city/liu/fist/vet(src)
	new /obj/item/ego_weapon/city/liu/fist/vet(src)
	new /obj/item/clothing/suit/armor/ego_gear/city/liu/section5(src)
	new /obj/item/clothing/suit/armor/ego_gear/city/liu/section5(src)
	new /obj/item/clothing/suit/armor/ego_gear/city/liu/section5(src)
	new /obj/item/clothing/suit/armor/ego_gear/city/liuvet/section5(src)
	new /obj/item/clothing/suit/armor/ego_gear/city/liuleader/section5(src)
	new /obj/item/assoc_skill_granter/liu(src)
	new /obj/item/assoc_skill_granter/liu(src)
	new /obj/item/assoc_skill_granter/liu(src)
	new /obj/item/assoc_skill_granter/liu/veteran(src)
	new /obj/item/assoc_skill_granter/liu/director(src)

//Seven Asso — Section 4 (new Rupture + Adaptive weapons)
/obj/item/storage/box/association/seven
	name = "Seven Association Section 4"
	desc = "A kit from Section 1 containing Seven Association Section 4 gear."

/obj/item/storage/box/association/seven/PopulateContents()
	// Associate weapons (3)
	new /obj/item/ego_weapon/city/seven_s4_blade(src)
	new /obj/item/ego_weapon/city/seven_s4_foil(src)
	new /obj/item/ego_weapon/city/seven_s4_blade(src)
	// Associate sidearms (3)
	new /obj/item/ego_weapon/city/seven_s4_foil(src)
	new /obj/item/ego_weapon/city/seven_s4_foil(src)
	new /obj/item/ego_weapon/city/seven_s4_foil(src)
	// Veteran weapon (1) + sidearm
	new /obj/item/ego_weapon/city/seven_s4_blade/vet(src)
	new /obj/item/ego_weapon/city/seven_s4_foil/dagger(src)
	// Director weapons (blade + cane choice) + sidearm
	new /obj/item/ego_weapon/city/seven_s4_blade/director(src)
	new /obj/item/ego_weapon/city/seven_s4_blade/cane(src)
	new /obj/item/ego_weapon/city/seven_s4_foil/dagger(src)
	// Associate armor (3)
	new /obj/item/clothing/suit/armor/ego_gear/city/seven_s4(src)
	new /obj/item/clothing/suit/armor/ego_gear/city/seven_s4(src)
	new /obj/item/clothing/suit/armor/ego_gear/city/seven_s4/recon(src)
	// Veteran armor (1)
	new /obj/item/clothing/suit/armor/ego_gear/city/seven_s4/vet(src)
	// Director armor (1)
	new /obj/item/clothing/suit/armor/ego_gear/city/seven_s4/director(src)
	// Equipment
	new /obj/item/binoculars(src)
	new /obj/item/binoculars(src)
	// Investigation toolkit
	new /obj/item/camera/seven_intel(src)
	new /obj/item/intel_report(src)
	new /obj/item/intel_report(src)
	new /obj/item/intel_report(src)
	new /obj/item/seven_dossier(src)
	new /obj/item/seven_catalog(src)

//Seven Asso — Section 6 (legacy stored-target weapons)
/obj/item/storage/box/association/seven/section6
	name = "Seven Association Section 6"
	desc = "A kit from Section 1 containing Seven Association Section 6 gear."

/obj/item/storage/box/association/seven/section6/PopulateContents()
	new /obj/item/ego_weapon/city/seven(src)
	new /obj/item/ego_weapon/city/seven(src)
	new /obj/item/ego_weapon/city/seven_fencing(src)
	new /obj/item/ego_weapon/city/seven/vet(src)
	new /obj/item/ego_weapon/city/seven/director(src)
	new /obj/item/ego_weapon/city/seven/cane(src)
	new /obj/item/clothing/suit/armor/ego_gear/city/seven(src)
	new /obj/item/clothing/suit/armor/ego_gear/city/seven(src)
	new /obj/item/clothing/suit/armor/ego_gear/city/sevenrecon(src)
	new /obj/item/clothing/suit/armor/ego_gear/city/sevenvet(src)
	new /obj/item/clothing/suit/armor/ego_gear/city/sevendirector(src)
	new /obj/item/binoculars(src)
	new /obj/item/binoculars(src)

//Middle Choice Beacons
//Little Brother Gear Beacon
/obj/item/choice_beacon/middle/little
	name = "little sibling gear beacon"
	desc = "A beacon to select your Little Brother or Sister gear variant."

/obj/item/choice_beacon/middle/little/generate_display_names()
	var/static/list/beacon_item_list
	if(!beacon_item_list)
		beacon_item_list = list(
			"Little Brother Gear" = /obj/item/middle_gear_package/little_brother,
			"Little Sister Gear" = /obj/item/middle_gear_package/little_sister,
			"Little Tank Top Gear" = /obj/item/middle_gear_package/little_tank
		)
	return beacon_item_list

/obj/item/choice_beacon/middle/little/spawn_option(obj/choice, mob/living/M)
	new choice(get_turf(M))
	to_chat(M, span_notice("Equipment spawned at your location."))

//Younger Brother Gear Beacon
/obj/item/choice_beacon/middle/younger
	name = "younger sibling gear beacon"
	desc = "A beacon to select your Younger Brother or Sister gear variant."

/obj/item/choice_beacon/middle/younger/generate_display_names()
	var/static/list/beacon_item_list
	if(!beacon_item_list)
		beacon_item_list = list(
			"Younger Brother Gear" = /obj/item/middle_gear_package/younger_brother,
			"Younger Sister Gear" = /obj/item/middle_gear_package/younger_sister
		)
	return beacon_item_list

/obj/item/choice_beacon/middle/younger/spawn_option(obj/choice, mob/living/M)
	new choice(get_turf(M))
	to_chat(M, span_notice("Equipment spawned at your location."))

//Big Brother Gear Beacon
/obj/item/choice_beacon/middle/big
	name = "big sibling gear beacon"
	desc = "A beacon to select your Big Brother or Sister gear variant."

/obj/item/choice_beacon/middle/big/generate_display_names()
	var/static/list/beacon_item_list
	if(!beacon_item_list)
		beacon_item_list = list(
			"Big Brother Gear" = /obj/item/middle_gear_package/big_brother,
			"Big Sister Gear" = /obj/item/middle_gear_package/big_sister
		)
	return beacon_item_list

/obj/item/choice_beacon/middle/big/spawn_option(obj/choice, mob/living/M)
	new choice(get_turf(M))
	to_chat(M, span_notice("Equipment spawned at your location."))

//Middle Gear Packages - These handle spawning equipment and updating ID cards
/obj/item/middle_gear_package
	name = "middle gear package"
	desc = "A package containing Middle gear."
	icon = 'icons/obj/storage.dmi'
	icon_state = "deliverypackage3"
	var/armor_type = null
	var/weapon_type = null
	var/book_type = null
	var/new_assignment = null // What to change the ID assignment to

/obj/item/middle_gear_package/attack_self(mob/user)
	// Spawn the gear
	if(armor_type)
		new armor_type(get_turf(user))
	if(weapon_type)
		new weapon_type(get_turf(user))
	if(book_type)
		new book_type(get_turf(user))

	// Update ID card assignment if this is a sister variant
	if(new_assignment && isliving(user))
		var/mob/living/L = user
		var/obj/item/card/id/ID = L.get_idcard(TRUE)
		if(ID)
			ID.assignment = new_assignment
			ID.update_label()
			to_chat(user, span_notice("Your ID card has been updated to: [new_assignment]"))

	to_chat(user, span_notice("You unpack your Middle gear!"))
	qdel(src)

//Little Brother variants
/obj/item/middle_gear_package/little_brother
	name = "little brother gear package"
	armor_type = /obj/item/clothing/suit/armor/ego_gear/city/middle
	weapon_type = /obj/item/ego_weapon/shield/middle_chain
	book_type = /obj/item/storage/book/middle

/obj/item/middle_gear_package/little_sister
	name = "little sister gear package"
	armor_type = /obj/item/clothing/suit/armor/ego_gear/city/middle/little_sister
	weapon_type = /obj/item/ego_weapon/shield/middle_chain
	book_type = /obj/item/storage/book/middle
	new_assignment = "Little Sister"

/obj/item/middle_gear_package/little_tank
	name = "little tank top gear package"
	armor_type = /obj/item/clothing/suit/armor/ego_gear/city/middle/tank_top
	weapon_type = /obj/item/ego_weapon/shield/middle_chain
	book_type = /obj/item/storage/book/middle

//Younger Brother variants
/obj/item/middle_gear_package/younger_brother
	name = "younger brother gear package"
	armor_type = /obj/item/clothing/suit/armor/ego_gear/city/middle_younger
	weapon_type = /obj/item/ego_weapon/shield/middle_chain/younger
	book_type = /obj/item/storage/book/middle/younger

/obj/item/middle_gear_package/younger_sister
	name = "younger sister gear package"
	armor_type = /obj/item/clothing/suit/armor/ego_gear/city/middle_younger/younger_sister
	weapon_type = /obj/item/ego_weapon/shield/middle_chain/younger
	book_type = /obj/item/storage/book/middle/younger
	new_assignment = "Younger Sister"

//Big Brother variants
/obj/item/middle_gear_package/big_brother
	name = "big brother gear package"
	armor_type = /obj/item/clothing/suit/armor/ego_gear/city/middle_big
	weapon_type = /obj/item/ego_weapon/shield/middle_chain/big
	book_type = /obj/item/storage/book/middle/big

/obj/item/middle_gear_package/big_sister
	name = "big sister gear package"
	armor_type = /obj/item/clothing/suit/armor/ego_gear/city/middle_big/big_sister
	weapon_type = /obj/item/ego_weapon/shield/middle_chain/big
	book_type = /obj/item/storage/book/middle/big
	new_assignment = "Big Sister"

