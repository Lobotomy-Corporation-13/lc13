//Streetlight Office Operator
/datum/job/streetop
	title = "Streetlight Office Operator"
	outfit = /datum/outfit/job/streetop
	department_head = list("The Hana Association")
	faction = "Station"
	supervisors = "The Hana Association"
	selection_color = "#948a40"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/streetop
	faction_positions = 1
	display_order = 106
	access = list("streetlight")
	minimal_access = list("streetlight")
	radio_channel_name = "Streetlight"
	radio_channel_color = "#948a40"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 500
	maptype = list("city")
	job_important = "You are the Operator of the rather shabby Streetlight office, an associate of the Zwei association. \
	you take jobs related to security and small scale crime."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 80,
								PRUDENCE_ATTRIBUTE = 80,
								TEMPERANCE_ATTRIBUTE = 80,
								JUSTICE_ATTRIBUTE = 80
								)

/datum/job/streetop/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()

/datum/outfit/job/streetop
	name = "Streetlight Office Operator"
	jobtype = /datum/job/streetop

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list(/obj/item/structurecapsule/fixer/streetlight)
	shoes = /obj/item/clothing/shoes/laceup

