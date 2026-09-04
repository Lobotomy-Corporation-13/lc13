//Dawn Office Junior
/datum/job/dawnjun
	title = "Dawn Office Junior"
	outfit = /datum/outfit/job/dawnjun
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
	job_important = "You are a junior in the Dawn Office, taken in by the operator you are a low grade fixer given tools and support by the Dawn Office. \
	like the Veteran you wield powerful Stigma Workshop weaponry and take orders from your Operator."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 60,
								PRUDENCE_ATTRIBUTE = 60,
								TEMPERANCE_ATTRIBUTE = 60,
								JUSTICE_ATTRIBUTE = 60
								)

/datum/job/dawnjun/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/dawnjun
	name = "Dawn Office Junior"
	jobtype = /datum/job/dawnjun

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list()
	shoes = /obj/item/clothing/shoes/laceup
