/datum/job/research_lead
	title = "Research Lead"
	faction = "Station"
	supervisors = "the District Manager"
	total_positions = 1
	spawn_positions = 1
	selection_color = "#cd6fd9"

	outfit = /datum/outfit/job/researcher/lead

	//Researcher access plus Command, the same step up the Udjat Leader gets over their agents.
	access = list(ACCESS_RND, ACCESS_SECURITY, ACCESS_COMMAND)
	minimal_access = list(ACCESS_RND, ACCESS_SECURITY, ACCESS_COMMAND)
	departments = DEPARTMENT_SCIENCE

	job_attribute_limit = 20

	display_order = 5.5
	alt_titles = list()
	maptype = "limbus_labs"
	job_important = "You are the Research Lead. You run the research arm: decide who covers which specimen, collect what your researchers find, and answer for it to the District Manager."
	job_abbreviation = "RSL"

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 40,
								PRUDENCE_ATTRIBUTE = 40,
								TEMPERANCE_ATTRIBUTE = 40,
								JUSTICE_ATTRIBUTE = 40
								)

/datum/job/research_lead/after_spawn(mob/living/carbon/human/H, mob/M, latejoin = FALSE)
	..()
	H.set_attribute_limit(20)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)

//Subtypes the researcher outfit so the lead always wears whatever the researchers wear. The
//beret and the department-head headset are the only differences.
/datum/outfit/job/researcher/lead
	name = "Research Lead"
	jobtype = /datum/job/research_lead

	head = /obj/item/clothing/head/beret/tegu/lce_research
	ears = /obj/item/radio/headset/heads/headset_information
