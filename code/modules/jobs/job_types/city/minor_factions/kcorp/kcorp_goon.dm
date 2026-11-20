//Full Stop Operator
/datum/job/kcorp_goon
	title = "Kcorp Filmographer"
	outfit = /datum/outfit/job/kcorp_goon
	department_head = list("The Hana Association")
	faction = "Station"
	supervisors = "The Director"
	selection_color = "#8e8f9e"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/kcorp_goon
	faction_positions = 1
	display_order = 103
	trusted_only = TRUE
	access = list("kcorp")
	minimal_access = list("kcorp")
	radio_channel_name = "Kcorp"
	radio_channel_color = "#26294F"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 100
	maptype = list("city")
	job_important = "."

/datum/job/kcorp_goon/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/kcorp_goon
	name = "Full Stop Operator"
	jobtype = /datum/job/kcorp_goon
	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction/heads
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	shoes = /obj/item/clothing/shoes/laceup
