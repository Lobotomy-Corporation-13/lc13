//Udjat Gunner
/datum/job/gunner
	title = "Udjat Heavy Gunner"
	outfit = /datum/outfit/job/gunner
	department_head = list("The Captain")
	faction = "Station"
	supervisors = "The Captain"
	selection_color = "#b0936f"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/captain
	faction_positions = 1
	display_order = JOB_DISPLAY_ORDER_SYNDICATEVET
	access = list("udjat")
	minimal_access = list("udjat")
	radio_channel_name = "Udjat"
	radio_channel_color = "#caa75f"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 200
	maptype = list("city")
	job_important = "You are the designated heavy gunner of the udjat, you report directly to the captain. you have an Udjat SSW to assist your squad at range."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 80,
								PRUDENCE_ATTRIBUTE = 80,
								TEMPERANCE_ATTRIBUTE = 80,
								JUSTICE_ATTRIBUTE = 80
								)

/datum/job/gunner/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/gunner
	name = "Udjat Heavy Gunner"
	jobtype = /datum/job/gunner

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list()
	shoes = /obj/item/clothing/shoes/laceup
