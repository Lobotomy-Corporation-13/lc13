//Liu Section 6 Director
/datum/job/liudirector
	title = "Liu South Section 6 Director"
	outfit = /datum/outfit/job/liudirector
	department_head = list("the liu.")
	faction = "Station"
	supervisors = "the liu."
	selection_color = "#856948"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/liudirector
	faction_positions = 1
	display_order = JOB_DISPLAY_ORDER_SYNDICATEHEAD
	trusted_only = TRUE
	access = list("liu", "liu_leader")
	minimal_access = list("liu", "liu_leader")
	radio_channel_name = "Liu Association"
	radio_channel_color = "#FF3333"
	departments = DEPARTMENT_COMMAND | DEPARTMENT_CITY_ANTAGONIST
	paycheck = 700
	maptype = list("city")
	job_important = "This is a roleplay role. You are the director of Liu south section 6, a highly prestigous association. \
	You deal in all out war, the Liu sells their overpowering force to the highest bidder. \
	you shouldn't be working as heros like the zwei, though as an official association should be keeping the reputation of the liu clean in the eyes of the Hana."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 100,
								PRUDENCE_ATTRIBUTE = 100,
								TEMPERANCE_ATTRIBUTE = 100,
								JUSTICE_ATTRIBUTE = 100
								)

/datum/job/sottocapo/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/liudirector
	name = "Liu South Section 6 Director"
	jobtype = /datum/job/liudirector

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction/heads
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list(/obj/item/structurecapsule/syndicate/liu, /obj/item/office_marker/syndicate)
	shoes = /obj/item/clothing/shoes/laceup
