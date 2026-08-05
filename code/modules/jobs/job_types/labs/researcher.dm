/datum/job/researcher
	title = "LCE Researcher"
	faction = "Station"
	supervisors = "the Research Lead"
	total_positions = 3
	spawn_positions = 3
	selection_color = "#cd6fd9"

	department_head = list("Research Lead")

	outfit = /datum/outfit/job/researcher

	access = list(ACCESS_RND, ACCESS_SECURITY)
	minimal_access = list(ACCESS_RND, ACCESS_SECURITY)
	departments = DEPARTMENT_SCIENCE

	job_attribute_limit = 20


	display_order = 6
	alt_titles = list()
	maptype = "limbus_labs"
	job_important = "You are an LCE Researcher. Your job is to interact with the specimens, write down notes based on how they reacted, and report your findings to the Research Lead."
	job_abbreviation = "RES"

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 40,
								PRUDENCE_ATTRIBUTE = 40,
								TEMPERANCE_ATTRIBUTE = 40,
								JUSTICE_ATTRIBUTE = 40
								)

/datum/job/researcher/after_spawn(mob/living/carbon/human/H, mob/M, latejoin = FALSE)
	..()
	H.set_attribute_limit(20)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)


/datum/outfit/job/researcher
	name = "LCE Researcher"
	jobtype = /datum/job/researcher

	belt = /obj/item/pda/toxins
	ears = /obj/item/radio/headset/headset_information
	uniform = /obj/item/clothing/under/suit/lce
	accessory = /obj/item/clothing/accessory/armband/lobotomy/extraction/lce
	shoes = /obj/item/clothing/shoes/sneakers/white
	suit = /obj/item/clothing/suit/armor/ego_gear/limbus/lce_longcoat
	l_pocket = /obj/item/radio
