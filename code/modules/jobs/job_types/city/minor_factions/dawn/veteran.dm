//Dawn Office Veteran
/datum/job/dawnvet
	title = "Dawn Office Veteran"
	outfit = /datum/outfit/job/dawnvet
	department_head = list("Dawn Office Operator")
	faction = "Station"
	supervisors = "Dawn Office Operator"
	selection_color = "#b0936f"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/dawnop
	faction_positions = 1
	display_order = JOB_DISPLAY_ORDER_ANTAG
	access = list("dawn")
	minimal_access = list("dawn")
	radio_channel_name = "Dawn Office"
	radio_channel_color = "#f0a129"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 200
	maptype = list("city")
	job_important = "You are a Veteran fixer of the Dawn Office, you use a case with mechanical fittings made by Stigma Workshop to burn opponents. \
	You report to the operator."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 80,
								PRUDENCE_ATTRIBUTE = 80,
								TEMPERANCE_ATTRIBUTE = 80,
								JUSTICE_ATTRIBUTE = 80
								)

/datum/job/dawnvet/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/dawnvet
	name = "Dawn Office Veteran"
	jobtype = /datum/job/dawnvet
	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list()
	shoes = /obj/item/clothing/shoes/laceup
