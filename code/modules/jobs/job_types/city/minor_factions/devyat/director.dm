//Devyat Association Director
/datum/job/devyatdir
	title = "Devyat North Section 3 Director"
	outfit = /datum/outfit/job/devyatdir
	department_head = list("Hana Association")
	faction = "Station"
	supervisors = "Hana Association"
	selection_color = "#51a69c"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/devyatdir
	faction_positions = 1
	display_order = 107
	access = list("devyat")
	minimal_access = list("devyat")
	radio_channel_name = "Devyat Association"
	radio_channel_color = "#8be0d6"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 700
	maptype = list("city")
	job_important = "You are the Devyat Association North Section 3 Director, \
	You are a courier for money. \
	Use the delivery office radio to start deliveries."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 100,
								PRUDENCE_ATTRIBUTE = 100,
								TEMPERANCE_ATTRIBUTE = 100,
								JUSTICE_ATTRIBUTE = 100
								)

/datum/job/devyatdir/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/devyatdir
	name = "Devyat Association North Section 3 Director"
	jobtype = /datum/job/devyatdir
	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction/heads
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list(/obj/item/structurecapsule/fixer/devyat)
	shoes = /obj/item/clothing/shoes/laceup
