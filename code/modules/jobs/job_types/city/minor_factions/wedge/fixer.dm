//Wedge Fixer
/datum/job/wedgefixer
	title = "Wedge Office Fixer"
	outfit = /datum/outfit/job/wedgefixer
	department_head = list("Wedge Office Operator")
	faction = "Station"
	supervisors = "Wedge Office Operator"
	selection_color = "#b4b5c2"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/wedge
	faction_positions = 2
	display_order = 108.1
	access = list("wedge")
	minimal_access = list("wedge")
	radio_channel_name = "Wedge"
	radio_channel_color = "#616161"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 200
	maptype = list("city")
	job_important = "You are a fixer of Wedge office, an investigation office under contract of the Liu Association. \
	Follow your Operator to the crime scenes the office radio reports, search them for evidence, and help work out who the culprit is."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 60,
								PRUDENCE_ATTRIBUTE = 60,
								TEMPERANCE_ATTRIBUTE = 60,
								JUSTICE_ATTRIBUTE = 60
								)

/datum/job/wedgefixer/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/wedgefixer
	name = "Wedge Fixer"
	jobtype = /datum/job/wedgefixer
	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list()
	shoes = /obj/item/clothing/shoes/laceup
