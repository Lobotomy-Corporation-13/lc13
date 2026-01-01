/*
Machine Civilian - Base role for Resurgence Clan gamemode
*/
/datum/job/machine_civilian
	title = "Machine Civilian"
	faction = "Station"
	total_positions = -1
	spawn_positions = -1
	supervisors = "the village elders"
	selection_color = "#888888"
	access = list(ACCESS_LAWYER)
	minimal_access = list(ACCESS_LAWYER)
	departments = DEPARTMENT_SERVICE
	maptype = list("outpost")
	outfit = /datum/outfit/job/machine_civilian
	display_order = JOB_DISPLAY_ORDER_CIVILIAN
	allow_bureaucratic_error = FALSE
	paycheck = 0
	job_important = "You are a mechanical being of the Resurgence Clan, establishing an outpost for the Historian's village. \
			Work together to gather resources, build rooms, and complete objectives. \
			Use 'Check Core Status' to view your Faith level and current objectives. \
			Build Living Quarters, a Workshop, Kitchen, Farming Zones, and an Export Warehouse. \
			Once building objectives are complete, export resources back to the village to win. \
			Maintain your Faith through good living conditions, proper rooms, and community."

	roundstart_attributes = list(
		FORTITUDE_ATTRIBUTE = 40,
		PRUDENCE_ATTRIBUTE = 40,
		TEMPERANCE_ATTRIBUTE = 40,
		JUSTICE_ATTRIBUTE = 40
	)

/datum/job/machine_civilian/after_spawn(mob/living/carbon/human/H, mob/M, latejoin = FALSE)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)

	// Create a wig matching the player's original hair before species change removes it
	if(H.hairstyle && H.hairstyle != "Bald")
		var/obj/item/clothing/head/wig/W = new(get_turf(H))
		W.hairstyle = H.hairstyle
		W.add_atom_colour("#[H.hair_color]", FIXED_COLOUR_PRIORITY)
		W.gradient_style = H.gradient_style
		W.gradient_color = H.gradient_color
		W.update_icon()
		H.equip_to_slot_or_del(W, ITEM_SLOT_HEAD)

	H.set_species(/datum/species/resurgence_machine)

	// Initialize the core's faith (charge system is disabled)
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(istype(core))
		// core.charge = 100 // DISABLED
		core.faith = 100

		// Give newcomers a 10-minute grace period to find a home
		// This offsets the homeless penalty and gives time to claim a room
		var/datum/faith_event/newcomer/event = new(
			"Recently awakened - finding your place.",
			1.5, // +1.5 per tick to offset homeless penalty and give buffer
			10 MINUTES,
			"newcomer"
		)
		core.add_faith_event("newcomer", event)

	..()

/datum/outfit/job/machine_civilian
	name = "Machine Civilian"
	jobtype = /datum/job/machine_civilian
	uniform = /obj/item/clothing/under/misc/assistantformal
	suit = /obj/item/clothing/suit/hooded/cloak/goliath
	shoes = /obj/item/clothing/shoes/workboots/mining
	ears = null
	id = /obj/item/card/id

	backpack = /obj/item/storage/backpack
	satchel = /obj/item/storage/backpack/satchel
	duffelbag = /obj/item/storage/backpack/duffelbag

	backpack_contents = list(
		/obj/item/crowbar = 1,
		/obj/item/hatchet/wooden = 1,
		/obj/item/pickaxe/improvised = 1,
		/obj/item/resurgence_outpost_planner = 1,
		/obj/item/weldingtool/experimental = 1,
		/obj/item/folder/resurgence_guides = 1
	)
