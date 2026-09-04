//Full Stop Operator
/datum/job/Fullop
	title = "Full Stop Operator"
	outfit = /datum/outfit/job/fullop
	department_head = list("")
	faction = "Station"
	supervisors = ""
	selection_color = "#856948"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/fullop
	faction_positions = 1
	display_order = JOB_DISPLAY_ORDER_ANTAG
	trusted_only = TRUE
	access = list("fullstop")
	minimal_access = list("fullstop")
	radio_channel_name = "Full Stop"
	radio_channel_color = "#FF69B4"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 700
	maptype = list("city")
	job_important = "You are the operator of Full Stop office, a Shi contracted office. \
	you specialise in long range takedowns using automatic weaponry, your goal is to make profit by taking down large monsters or take contracts from other factions. \
	you are equipped with a full stop deagle, ammo is expensive so pick your fights."


	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 100,
								PRUDENCE_ATTRIBUTE = 100,
								TEMPERANCE_ATTRIBUTE = 100,
								JUSTICE_ATTRIBUTE = 100
								)

/datum/job/fullop/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/fullop
	name = "Full Stop Operator"
	jobtype = /datum/job/operator
	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction/heads
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list(/obj/item/structurecapsule/fixer/fullstop)
	shoes = /obj/item/clothing/shoes/laceup
