//Streetlight Office Fixer
/datum/job/streetfixer
	title = "Streetlight Office Fixer"
	outfit = /datum/outfit/job/streetfixer
	department_head = list("Streetlight Office Operator")
	faction = "Station"
	supervisors = "Streetlight Office Operator"
	selection_color = "#b0a766"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/streetop
	faction_positions = 2
	display_order = 106.1
	access = list("streetlight")
	minimal_access = list("streetlight")
	radio_channel_name = "Streetlight"
	radio_channel_color = "#948a40"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 200
	maptype = list("city")
	job_important = "You are a Fixer of the rather shabby Streetlight office, an associate of the Zwei association. \
	you take your orders from the operator, and hope you make enough money to keep on going."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 60,
								PRUDENCE_ATTRIBUTE = 60,
								TEMPERANCE_ATTRIBUTE = 60,
								JUSTICE_ATTRIBUTE = 60
								)

/datum/job/streetop/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()

/datum/outfit/job/streetfixer
	name = "Streetlight Office Fixer"
	jobtype = /datum/job/streetfixer

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	shoes = /obj/item/clothing/shoes/laceup

