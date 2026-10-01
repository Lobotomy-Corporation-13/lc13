//Shi Association Fixer
/datum/job/shifixer
	title = "Shi Fixer"
	outfit = /datum/outfit/job/shifixer
	department_head = list("Shi Director")
	faction = "Station"
	supervisors = "Shi Director"
	selection_color = "#7d514d"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/shidir
	faction_positions = 2
	display_order = 105.1
	access = list("shisouth")
	minimal_access = list("shisouth")
	radio_channel_name = "Shi Association"
	radio_channel_color = "#693733"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 200
	maptype = list("city")
	job_important = "You are a Shi Association fixer, \
	You are an assassin for hire. \
	Take money for kill contracts. You know you want to."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 80,
								PRUDENCE_ATTRIBUTE = 80,
								TEMPERANCE_ATTRIBUTE = 80,
								JUSTICE_ATTRIBUTE = 80
								)

/datum/job/shifixer/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/shifixer
	name = "Shi Fixer"
	jobtype = /datum/job/shifixer
	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list()
	shoes = /obj/item/clothing/shoes/laceup
