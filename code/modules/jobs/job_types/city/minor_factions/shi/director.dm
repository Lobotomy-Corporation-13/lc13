//Shi Association Director
/datum/job/shidir
	title = "Shi South Section 2 Director"
	outfit = /datum/outfit/job/shidir
	department_head = list("Hana Association")
	faction = "Station"
	supervisors = "Hana Association"
	selection_color = "#693733"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/shidir
	faction_positions = 1
	display_order = 105
	access = list("shisouth")
	minimal_access = list("shisouth")
	radio_channel_name = "Shi Association"
	radio_channel_color = "#693733"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 500
	maptype = list("city")
	job_important = "You are the Shi Association South Section 2 Director, \
	You are an assassin for hire. \
	Take money for kill contracts. You know you want to."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 100,
								PRUDENCE_ATTRIBUTE = 100,
								TEMPERANCE_ATTRIBUTE = 100,
								JUSTICE_ATTRIBUTE = 100
								)

/datum/job/shidir/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/shidir
	name = "Shi Association South Section 2 Director"
	jobtype = /datum/job/shidir
	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list(/obj/item/structurecapsule/fixer/shisouth)
	shoes = /obj/item/clothing/shoes/laceup
