//Full Stop Rifleman
/datum/job/rifleman
	title = "Full Stop Rifleman"
	outfit = /datum/outfit/job/rifleman
	department_head = list("Full Stop Operator")
	faction = "Station"
	supervisors = "Full Stop Operator"
	selection_color = "#b0936f"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/operator
	faction_positions = 1
	display_order = JOB_DISPLAY_ORDER_ANTAG
	access = list("fullstop")
	minimal_access = list("fullstop")
	radio_channel_name = "Full Stop"
	radio_channel_color = "#FF69B4"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 200
	maptype = list("city")
	job_important = "You are the designated support rifleman of the Full Stop office, you have an automatic rifle to provide fire support and protection to your Sniper and Operator."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 60,
								PRUDENCE_ATTRIBUTE = 60,
								TEMPERANCE_ATTRIBUTE = 60,
								JUSTICE_ATTRIBUTE = 60
								)

/datum/job/gunner/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/rifleman
	name = "Full Stop Rifleman"
	jobtype = /datum/job/rifleman
	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list()
	shoes = /obj/item/clothing/shoes/laceup
