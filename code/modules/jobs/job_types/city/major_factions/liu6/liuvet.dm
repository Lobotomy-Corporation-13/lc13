//Liu Assoc Veteran
/datum/job/liuvet
	title = "Liu Veteran Fixer"
	outfit = /datum/outfit/job/liuvet
	department_head = list("the director")
	faction = "Station"
	supervisors = "the director."
	selection_color = "#b0936f"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/liuvet
	faction_positions = 1
	display_order = JOB_DISPLAY_ORDER_SYNDICATEVET
	access = list("liu")
	minimal_access = list("liu")
	radio_channel_name = "Liu Association"
	radio_channel_color = "#FF3333"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 200
	maptype = list("city")
	job_important = "You are a veteran in the Liu Association and the right hand to the director, you lead the large group of fixers alongside your director."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 80,
								PRUDENCE_ATTRIBUTE = 80,
								TEMPERANCE_ATTRIBUTE = 80,
								JUSTICE_ATTRIBUTE = 80
								)

/datum/job/capo/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/liuvet
	name = "Liu South Section 6 Veteran"
	jobtype = /datum/job/liuvet

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list()
	shoes = /obj/item/clothing/shoes/laceup
