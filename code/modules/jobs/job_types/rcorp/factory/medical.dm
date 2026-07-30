/datum/job/medical_officer
	title = "R-Corp Medical Officer"
	faction = "Station"
	department_head = list("Commanders")
	total_positions = 2
	spawn_positions = 2
	supervisors = "the commanders"
	selection_color = "#2fccef"
	exp_requirements = 120
	exp_type = EXP_TYPE_CREW
	maptype = "rcorp_factory"

	outfit = /datum/outfit/job/medical_officer
	display_order = 8

	access = list(ACCESS_MEDICAL)
	minimal_access = list(ACCESS_MEDICAL)

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 40,
								PRUDENCE_ATTRIBUTE = 40,
								TEMPERANCE_ATTRIBUTE = 40,
								JUSTICE_ATTRIBUTE = 40
								)
	rank_title = "CPT"
	job_important = "You take the role of a medical officer."
	job_notice = "You are quite weak in terms of offensive capabilities, however, you have the duty of caring for the fallen r-corp soldiers. \
			Move your medical tent and await the mountain of bodies coming your way."

/datum/job/medical_officer/after_spawn(mob/living/carbon/human/H, mob/M)
	. = ..()
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	SSpersistence.ShowExpeditionNumber(H)

/datum/outfit/job/medical_officer
	name = "R-Corp Medical Officer"
	jobtype = /datum/job/medical_officer

	belt = null
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	shoes = /obj/item/clothing/shoes/sneakers/white
	head = /obj/item/clothing/head/beret/tegu/med
	suit =  /obj/item/clothing/suit/armor/ego_gear/limbus_labs/doctor
	l_hand = /obj/item/storage/firstaid/medical

	implants = list(/obj/item/organ/cyberimp/eyes/hud/security)
	back = /obj/item/storage/backpack/rcorp
	ignore_pack = TRUE
