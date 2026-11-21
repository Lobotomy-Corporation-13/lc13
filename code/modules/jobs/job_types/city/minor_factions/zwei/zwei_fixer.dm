//Zwei Assoc Fixer
/datum/job/zweiFixer
	title = "Zwei Fixer"
	outfit = /datum/outfit/job/zweiFixer
	department_head = list("The veteran superior.")
	faction = "Station"
	supervisors = "the veteran"
	selection_color = "#326ba8"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/zweiVet
	faction_positions = 6
	display_order = 1.2
	access = list("zwei")
	minimal_access = list("zwei")
	radio_channel_name = "Zwei Assocation"
	radio_channel_color = "#326ba8"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 100
	maptype = list("city")
	job_important = "You are a fixer in the Zwei Assocation. You report to the Veteran as the Director is not locally available."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 60,
								PRUDENCE_ATTRIBUTE = 60,
								TEMPERANCE_ATTRIBUTE = 60,
								JUSTICE_ATTRIBUTE = 60
								)

/datum/job/zweiFixer/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/zweiFixer
	name = "Zwei South Section Fixer"
	jobtype = /datum/job/zweiFixer

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list()
	shoes = /obj/item/clothing/shoes/laceup
