//Grand Inquisitor
/datum/job/grandinquis
	title = "Grand Inquisitor"
	outfit = /datum/outfit/job/grandinquis
	department_head = list("the glory of righteousness.")
	faction = "Station"
	supervisors = "the glory of righteousness."
	selection_color = "#ada890"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/grandinquis
	faction_positions = 1
	display_order = 5
	trusted_only = TRUE
	access = list("nagel")
	minimal_access = list("nagel")
	departments = DEPARTMENT_COMMAND | DEPARTMENT_CITY_ANTAGONIST
	paycheck = 700
	maptype = list("city")
	job_important = "This is a roleplay role. You are the leader of this NCorp inquisition. \
		Your goal is simple, kill and torture everyone with prosthetics, and anyone who defends them."
	job_notice = "You may kill anyone with prosthetics, or anyone sympathetic to prosthetics."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 120,
								PRUDENCE_ATTRIBUTE = 120,
								TEMPERANCE_ATTRIBUTE = 120,
								JUSTICE_ATTRIBUTE = 120
								)

/datum/job/grandinquis/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/grandinquis
	name = "Grand Inquisitor"
	jobtype = /datum/job/grandinquis

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction/heads
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list(/obj/item/structurecapsule/major/nagel, /obj/item/office_marker/syndicate)
	shoes = /obj/item/clothing/shoes/laceup
