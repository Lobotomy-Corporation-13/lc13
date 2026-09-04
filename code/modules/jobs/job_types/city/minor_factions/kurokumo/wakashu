//Kurokumo Clan Wakashu
/datum/job/wakashu
	title = "Kurokumo Clan Wakashu"
	outfit = /datum/outfit/job/wakashu
	department_head = list("The kurokumo captain")
	faction = "Station"
	supervisors = "The kurokumo captain"
	selection_color = "#b0936f"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/kcaptain
	faction_positions = 2
	display_order = JOB_DISPLAY_ORDER_ANTAG
	access = list("kuro")
	minimal_access = list("kuro")
	radio_channel_name = "Kurokumo"
	radio_channel_color = "#2E347C"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 200
	maptype = list("city")
	job_important = "You are a Wakashu of the kurokumo clan, a subsidiary of the thumb. In the thumb, hierachy is king. Do not disrespect your captain or anyone above you. \
	if the Blade Bineage dare show their face around here, show em not to mess with the Kurokumo clan."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 60,
								PRUDENCE_ATTRIBUTE = 60,
								TEMPERANCE_ATTRIBUTE = 60,
								JUSTICE_ATTRIBUTE = 60
								)

/datum/job/wakashu/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/wakashu
	name = "Kurokumo Clan Wakashu"
	jobtype = /datum/job/wakashu

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list()
	shoes = /obj/item/clothing/shoes/laceup
