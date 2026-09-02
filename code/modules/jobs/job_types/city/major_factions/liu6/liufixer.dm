//Liu Assoc Fixer
/datum/job/liufixer
	title = "Liu Fixer"
	outfit = /datum/outfit/job/liufixer
	department_head = list("The director.")
	faction = "Station"
	supervisors = "the director"
	selection_color = "#b0936f"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/liudirector
	faction_positions = 6
	display_order = JOB_DISPLAY_ORDER_SYNDICATEGOON
	access = list("liu")
	minimal_access = list("liu")
	radio_channel_name = "Liu Association"
	radio_channel_color = "#FF3333"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 100
	maptype = list("city")
	job_important = "You are a fixer in the Liu Association, you report to the director and the veteran."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 60,
								PRUDENCE_ATTRIBUTE = 60,
								TEMPERANCE_ATTRIBUTE = 60,
								JUSTICE_ATTRIBUTE = 60
								)

/datum/job/soldato/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/liufixer
	name = "Liu South Section 6 Fixer"
	jobtype = /datum/job/liufixer

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list()
	shoes = /obj/item/clothing/shoes/laceup
