//Zwei Assoc Veteran
/datum/job/zweiVet
	title = "Zwei Veteran Fixer"
	outfit = /datum/outfit/job/zweiVet
	department_head = list("the director")
	faction = "Station"
	supervisors = "the director."
	selection_color = "#326ba8"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/zweiVet
	faction_positions = 1
	display_order = 1.1
	access = list("zwei")
	minimal_access = list("zwei")
	radio_channel_name = "Zwei Assocation"
	radio_channel_color = "#326ba8"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 200
	maptype = list("city")
	job_important = "You are a veteran in the Zwei Assocation and the right hand to the director, you lead the current group of fixers while your director is away."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 80,
								PRUDENCE_ATTRIBUTE = 80,
								TEMPERANCE_ATTRIBUTE = 80,
								JUSTICE_ATTRIBUTE = 80
								)

/datum/job/zweiVet/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/zweiVet
	name = "Zwei South Section Veteran"
	jobtype = /datum/job/zweiVet

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list()
	shoes = /obj/item/clothing/shoes/laceup
