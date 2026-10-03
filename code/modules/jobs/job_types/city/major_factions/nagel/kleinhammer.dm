//Kleinhammer
/datum/job/kleinhammer
	title = "N Corp Kleinhammer"
	outfit = /datum/outfit/job/kleinhammer
	department_head = list("the will of the grandinquisitor.")
	faction = "Station"
	supervisors = "the will of the grandinquisitor."
	selection_color = "#bdb9aa"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/grandinquis
	faction_positions = 3
	display_order = 5.3
	access = list("nagel")
	minimal_access = list("nagel")
	radio_channel_name = "Nagel Und Hammer"
	radio_channel_color = "#ada890"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 10
	maptype = list("city")
	job_important = "You are an NCorp kleinhammer. Your main goal is to kill and maim all prosthetic users. \
			Follow the orders of the Grand Inquisitor, as they will lead you to battle."
	job_notice = "You may kill anyone with prosthetics, or anyone sympathetic to prosthetics."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 60,
								PRUDENCE_ATTRIBUTE = 60,
								TEMPERANCE_ATTRIBUTE = 60,
								JUSTICE_ATTRIBUTE = 60
								)

/datum/job/kleinhammer/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/kleinhammer
	name = "N Corp Kleinhammer"
	jobtype = /datum/job/kleinhammer

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list()
	shoes = /obj/item/clothing/shoes/laceup
