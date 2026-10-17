//Shi Association Fixer
/datum/job/devyatfixer
	title = "Devyat Fixer"
	outfit = /datum/outfit/job/devyat
	department_head = list("Devyat Director")
	faction = "Station"
	supervisors = "Devyat Director"
	selection_color = "#8be0d6"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/devyatdir
	faction_positions = 1
	display_order = 107.1
	access = list("devyat")
	minimal_access = list("devyat")
	radio_channel_name = "Devyat Association"
	radio_channel_color = "#8be0d6"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 300
	maptype = list("city")
	job_important = "You are a Devyat Association fixer, \
	A simple courier for money. \
	Follow the instructions of your director, and make ."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 80,
								PRUDENCE_ATTRIBUTE = 80,
								TEMPERANCE_ATTRIBUTE = 80,
								JUSTICE_ATTRIBUTE = 80
								)

/datum/job/devyatfixer/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/devyat
	name = "Devyat Fixer"
	jobtype = /datum/job/devyatfixer
	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list()
	shoes = /obj/item/clothing/shoes/laceup
