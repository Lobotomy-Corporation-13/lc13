// The old town doctor. No longer a City job - the City runs /datum/job/city_clinic
// instead - but still the doctor on wonderlabs, fixers, lcorp_city and
// enkephalin_rush, which is why this is not in old_jobs. Do not re-add "city"
// to these maptypes without deleting the clinic faction first; both would open
// at once.
/datum/job/doctor
	title = "Doctor"
	faction = "Station"
	total_positions = 1
	spawn_positions = 1
	selection_color = "#aabbcc"

	outfit = /datum/outfit/job/doctor

	access = list(ACCESS_MEDICAL)
	minimal_access = list(ACCESS_MEDICAL)
	departments = DEPARTMENT_COMMAND | DEPARTMENT_MEDICAL
	paycheck = PAYCHECK_MEDIUM
	paycheck_department = ACCOUNT_MED

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 40,
								PRUDENCE_ATTRIBUTE = 40,
								TEMPERANCE_ATTRIBUTE = 40,
								JUSTICE_ATTRIBUTE = 40
								)



	job_attribute_limit = 40

	liver_traits = list(TRAIT_MEDICAL_METABOLISM)
	exp_requirements = 600

	display_order = JOB_DISPLAY_ORDER_MEDICAL
	//alt_titles for this job live in ModularLobotomy/altjobtitles/altjobtitles.dm
	maptype = list("wonderlabs", "fixers", "lcorp_city", "enkephalin_rush")
	job_important = "You are the town doctor, visit your clinic to the east of town and start healing peopl who come in. You must charge money for your services."

/datum/job/doctor/after_spawn(mob/living/carbon/human/H, mob/M, latejoin = FALSE)
	..()
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)


/datum/outfit/job/doctor
	name = "Doctor"
	jobtype = /datum/job/doctor

	belt = /obj/item/pda/medical
	ears = /obj/item/radio/headset/headset_welfare
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	shoes = /obj/item/clothing/shoes/sneakers/white
	head = /obj/item/clothing/head/beret/tegu/med
	suit =  /obj/item/clothing/suit/toggle/labcoat
	l_hand = /obj/item/storage/firstaid/medical

	backpack = /obj/item/storage/backpack/medic
	satchel = /obj/item/storage/backpack/satchel/med
	duffelbag = /obj/item/storage/backpack/duffelbag/med
	box = /obj/item/storage/box/survival/medical



//Doctor assistants
/datum/job/doctor/nurse
	title = "Nurse"
	selection_color = "#ccddee"
	department_head = list("Doctor")
	supervisors = "the doctor"

	outfit = /datum/outfit/job/doctor/nurse

	//Authored slots, not faction slots. The Clinic faction used to open this
	//and no longer owns it, so nothing else will.
	total_positions = 2
	spawn_positions = 2
	exp_requirements = 180

	display_order = JOB_DISPLAY_ORDER_MEDICALASSIST
	maptype = list("wonderlabs", "fixers", "lcorp_city")
	job_important = "You are an assistant to the town doctor, visit your clinic to the east of town and start healing people who come in. You must charge money for your services."

/datum/outfit/job/doctor/nurse
	name = "Nurse"
	jobtype = /datum/job/doctor/nurse

	uniform = /obj/item/clothing/under/rank/medical/doctor/blue
	head = /obj/item/clothing/head/beret/tegu/med
	suit =  null

//Paramedic but with a gun
/datum/job/doctor/fixer
	title = "Medical Fixer Assistant"
	selection_color = "#ccddee"
	department_head = list("Doctor")
	supervisors = "the doctor"

	outfit = /datum/outfit/job/doctor/fixer

	total_positions = 1
	spawn_positions = 1
	exp_requirements = 180

	display_order = JOB_DISPLAY_ORDER_MEDICALASSIST
	departments = DEPARTMENT_MEDICAL | DEPARTMENT_FIXERS
	maptype = list("wonderlabs", "fixers")
	job_important = "You are an a medical fixer. Your job is to explore the backstreets to grab dead fixers to bring back to the clinic."


/datum/outfit/job/doctor/fixer
	name = "Medical Fixer Assistant"
	jobtype = /datum/job/doctor/fixer

	uniform = /obj/item/clothing/under/rank/medical/paramedic
	head = /obj/item/clothing/head/soft/paramedic
	suit =  /obj/item/clothing/suit/toggle/labcoat/paramedic
	backpack_contents = list(/obj/item/pinpointer/crew=1)
	l_hand = /obj/item/ego_weapon/ranged/pistol/kcorp
