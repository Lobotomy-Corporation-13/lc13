//Blade Lineage Salsu
/datum/job/salsu
	title = "Blade Lineage Cutthroat"
	outfit = /datum/outfit/job/cutthroat
	department_head = list("You answer to Nobody")
	faction = "Station"
	supervisors = "You answer to Nobody"
	selection_color = "#b0936f"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/cutthroat
	faction_positions = 1
	display_order = JOB_DISPLAY_ORDER_ANTAG
	access = list("bladelin")
	minimal_access = list("bladelin")
	radio_channel_name = "Blade Lineage"
	radio_channel_color = "#2E347C"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 500
	maptype = list("city")
	job_important = "You are a roaming Blade Lineage cutthroat,\
	you have no direct power over your salsu's, the blade lineage are allies not a strict heirachy like the kurokumo. Treat your salsu with respect. \
	you draw your blade for any number of reasons, but should seek to kill the Kurokumo Clan if they ever show their face in your territory."

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


/datum/outfit/job/cutthroat
	name = "Blade Lineage Cutthroat"
	jobtype = /datum/job/salsu
	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list(/obj/item/structurecapsule/fixer/bladelin)
	shoes = /obj/item/clothing/shoes/laceup
