/datum/job/lce_cmo
	title = "Chief Medical Officer"
	faction = "Station"
	supervisors = "the District Manager"
	total_positions = 1
	spawn_positions = 1
	//Matches the nurses. The lead should not be the easier of the two medical roles to take.
	exp_requirements = 180
	selection_color = "#ccddee"

	department_head = list("District Manager")

	outfit = /datum/outfit/job/lcb_nurse/cmo

	//Nurse access plus Command, the same step up the Udjat Leader gets over their agents.
	access = list(ACCESS_MEDICAL, ACCESS_SECURITY, ACCESS_COMMAND)
	minimal_access = list(ACCESS_MEDICAL, ACCESS_SECURITY, ACCESS_COMMAND)
	departments = DEPARTMENT_MEDICAL

	job_attribute_limit = 0

	liver_traits = list(TRAIT_MEDICAL_METABOLISM)

	display_order = 5
	alt_titles = list()
	maptype = "limbus_labs"
	job_important = "You are the Chief Medical Officer. Medical is yours to run: set the triage order, keep the defibrillators charged, and decide who your nurses treat first."
	job_abbreviation = "CMO"

/datum/job/lce_cmo/after_spawn(mob/living/carbon/human/H, mob/M, latejoin = FALSE)
	..()
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)

//Subtypes the nurse outfit so the CMO always carries whatever the nurses carry, including the
//medical HUD implant. The beret and the department-head headset are the only differences.
/datum/outfit/job/lcb_nurse/cmo
	name = "Chief Medical Officer (LCE)"
	jobtype = /datum/job/lce_cmo

	head = /obj/item/clothing/head/beret/tegu/lce_medical
	ears = /obj/item/radio/headset/heads/headset_welfare
