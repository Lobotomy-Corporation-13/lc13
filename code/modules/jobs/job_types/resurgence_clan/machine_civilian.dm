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
	outfit = /datum/outfit/job/machine_civilian
	display_order = JOB_DISPLAY_ORDER_CIVILIAN
	allow_bureaucratic_error = FALSE
	paycheck = 0
	job_important = "You are a mechanical being of the Resurgence Clan, living in hiding beneath the City. \
			Work together with your fellow machines to gather resources, maintain your village, and preserve your Faith. \
			Your Charge regenerates over time and is used for abilities. \
			Your Faith slowly decays and must be restored through communal activities and sermons."

	roundstart_attributes = list(
		FORTITUDE_ATTRIBUTE = 40,
		PRUDENCE_ATTRIBUTE = 40,
		TEMPERANCE_ATTRIBUTE = 40,
		JUSTICE_ATTRIBUTE = 40
	)

/datum/job/machine_civilian/after_spawn(mob/living/carbon/human/H, mob/M, latejoin = FALSE)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	H.set_species(/datum/species/resurgence_machine)

	// Initialize the core's charge and faith
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(istype(core))
		core.charge = 100
		core.faith = 100

	..()

/datum/outfit/job/machine_civilian
	name = "Machine Civilian"
	jobtype = /datum/job/machine_civilian
	uniform = /obj/item/clothing/under/suit/charcoal
	shoes = /obj/item/clothing/shoes/sneakers/black
	ears = /obj/item/radio/headset
	id = /obj/item/card/id

	backpack = /obj/item/storage/backpack
	satchel = /obj/item/storage/backpack/satchel
	duffelbag = /obj/item/storage/backpack/duffelbag

	backpack_contents = list(
		/obj/item/flashlight = 1,
		/obj/item/crowbar = 1,
		/obj/item/resurgence_debugger = 1
	)
