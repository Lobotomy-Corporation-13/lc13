//Dawn Office Operator
/datum/job/dawnop
	title = "Dawn Office Operator"
	outfit = /datum/outfit/job/dawnop
	department_head = list("The Hana Association")
	faction = "Station"
	supervisors = "The Hana Association"
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
	paycheck = 500
	maptype = list("city")
	job_important = "You are the Operator of the prestigous Dawn Office, an associate of the Liu association. \
	your weapons are custom made by Stigma Workshop to burn targets, you take odd jobs mainly relating to investigating and taking down high scale targets."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 80,
								PRUDENCE_ATTRIBUTE = 80,
								TEMPERANCE_ATTRIBUTE = 80,
								JUSTICE_ATTRIBUTE = 80
								)

/datum/job/dawnop/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/dawnop
	name = "Dawn Office Operator"
	jobtype = /datum/job/dawnop

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list(/obj/item/structurecapsule/fixer/dawn)
	shoes = /obj/item/clothing/shoes/laceup
