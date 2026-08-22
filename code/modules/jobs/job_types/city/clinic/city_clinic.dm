// The City clinic. A Director, two Staff who work inside, two Field Agents who
// do not. Every specialisation runs these same five slots.
//
// Titles are fixed and never change with the specialisation. `title` keys
// SSjob.name_occupations, the lobby preference menu and every assigned_role
// check in the codebase, and ApplyToJobs() runs after name_occupations is
// built, so renaming a job there desyncs the lookup. The faction identity
// rides on display_title, outfit, access and radio instead.
//
// The Director's alt_titles are the pick. SScity_factions reads the chosen one
// off the player's preferences during roundstart assignment and stamps the
// matching variant onto all five jobs, which is early enough that everyone
// spawns already dressed. See FACTIONS.md.
//
// Every display_title below is Mirae's, because Mirae is the faction's default
// variant and there is no such thing as an unbranded clinic round. The generic
// titles still exist, but only as lookup keys - a player who sees one in the
// lobby would reasonably think a plain clinic was on offer, and it is not.

/datum/job/city_clinic
	title = "Clinic Director"
	display_title = "Mirae Clinic Director"
	outfit = /datum/outfit/job/city_clinic
	department_head = list("your own judgement")
	faction = "Station"
	supervisors = "nobody. The clinic answers to whoever is paying."
	selection_color = "#aabbcc"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/city_clinic
	faction_positions = 1
	alt_titles = list(
		"Mirae Clinic Director",
		"K-Corp Clinic Director",
	)
	access = list(ACCESS_MEDICAL, "clinic", "clinic_leader")
	minimal_access = list(ACCESS_MEDICAL, "clinic", "clinic_leader")
	radio_channel_name = "Clinic"
	radio_channel_color = "#4a8f7b"
	departments = DEPARTMENT_COMMAND | DEPARTMENT_MEDICAL
	display_order = JOB_DISPLAY_ORDER_MEDICAL
	paycheck = PAYCHECK_MEDIUM
	paycheck_department = ACCOUNT_MED
	exp_requirements = 600
	job_attribute_limit = 40
	liver_traits = list(TRAIT_MEDICAL_METABOLISM)
	maptype = list("city")
	job_important = "You run the clinic. Your parent company is whichever one \
		you set as this job's title in your preferences, and it decides what \
		your clinic is and what your staff are issued. Set nothing and you \
		are Mirae. Charge for your services."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 40,
								PRUDENCE_ATTRIBUTE = 40,
								TEMPERANCE_ATTRIBUTE = 40,
								JUSTICE_ATTRIBUTE = 40
								)

/datum/job/city_clinic/after_spawn(mob/living/carbon/human/H, mob/M, latejoin = FALSE)
	. = ..()
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)

/datum/outfit/job/city_clinic
	name = "Clinic Director"
	jobtype = /datum/job/city_clinic

	belt = /obj/item/pda/medical
	ears = /obj/item/radio/headset/faction/heads
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	suit = /obj/item/clothing/suit/toggle/labcoat
	shoes = /obj/item/clothing/shoes/sneakers/white
	head = /obj/item/clothing/head/beret/tegu/med
	l_hand = /obj/item/storage/firstaid/medical

	backpack = /obj/item/storage/backpack/medic
	satchel = /obj/item/storage/backpack/satchel/med
	duffelbag = /obj/item/storage/backpack/duffelbag/med
	box = /obj/item/storage/box/survival/medical

// Inside the clinic. These are the ones who actually heal people.
/datum/job/city_clinic/staff
	title = "Clinic Staff"
	display_title = "Mirae Claims Physician"
	outfit = /datum/outfit/job/city_clinic/staff
	department_head = list("Clinic Director")
	supervisors = "the clinic director"
	selection_color = "#ccddee"
	leader = /datum/job/city_clinic
	faction_positions = 2
	//Cleared: only the Director picks, and inheriting theirs would let a
	//staffer select a Director alt title from their own preferences.
	alt_titles = list()
	access = list(ACCESS_MEDICAL, "clinic")
	minimal_access = list(ACCESS_MEDICAL, "clinic")
	departments = DEPARTMENT_MEDICAL
	display_order = JOB_DISPLAY_ORDER_MEDICALASSIST
	exp_requirements = 180
	job_important = "You work the clinic floor. Treat whoever walks in, and \
		make them pay for it."

/datum/outfit/job/city_clinic/staff
	name = "Clinic Staff"
	jobtype = /datum/job/city_clinic/staff

	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/rank/medical/doctor/blue
	suit = null
	head = /obj/item/clothing/head/beret/tegu/med

// Outside the clinic. Both specialisation gimmicks hang off this role, which
// is why it is split off Staff rather than being more of them.
/datum/job/city_clinic/field
	title = "Clinic Field Agent"
	display_title = "Mirae Recovery Agent"
	outfit = /datum/outfit/job/city_clinic/field
	department_head = list("Clinic Director")
	supervisors = "the clinic director"
	selection_color = "#ccddee"
	leader = /datum/job/city_clinic
	faction_positions = 2
	//Cleared: only the Director picks, and inheriting theirs would let a
	//staffer select a Director alt title from their own preferences.
	alt_titles = list()
	access = list(ACCESS_MEDICAL, "clinic")
	minimal_access = list(ACCESS_MEDICAL, "clinic")
	departments = DEPARTMENT_MEDICAL
	display_order = JOB_DISPLAY_ORDER_MEDICALASSIST
	exp_requirements = 180
	job_important = "You work the street rather than the ward. What that means \
		depends on who owns your clinic."

/datum/outfit/job/city_clinic/field
	name = "Clinic Field Agent"
	jobtype = /datum/job/city_clinic/field

	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/rank/medical/paramedic
	suit = /obj/item/clothing/suit/toggle/labcoat/paramedic
	head = /obj/item/clothing/head/soft/paramedic
	backpack_contents = list(/obj/item/pinpointer/crew = 1)
