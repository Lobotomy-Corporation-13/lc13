//Younger Brother
/datum/job/younger_brother
	title = "Younger Brother"
	outfit = /datum/outfit/job/younger_brother
	department_head = list("Big Brother.")
	faction = "Station"
	supervisors = "Big Brother."
	selection_color = "#b0936f"
	total_positions = 0
	spawn_positions = 0
	display_order = JOB_DISPLAY_ORDER_SYNDICATEVET
	access = list(ACCESS_SYNDICATE)
	minimal_access = list(ACCESS_SYNDICATE)
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 200
	maptype = list("city")
	job_important = "The Younger Brother of this Middle section. Your goal is to follow the orders of your Big Brother and lead your Little Brothers. \
		The Middle values family above all else, so if anyone harms or disrespect your family make sure they will suffer for it. \
		You also have a delivery radio at your base. It will allow you earn money by delivering U-Corp goods. \
		Your base is hidden in the alleyway in the east behind the NO ENTRY Door."
	job_notice = "You may harm other players for any disrespect to the middle; avoid killing players for too minor infractions."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 80,
								PRUDENCE_ATTRIBUTE = 80,
								TEMPERANCE_ATTRIBUTE = 80,
								JUSTICE_ATTRIBUTE = 80
								)

/datum/job/younger_brother/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/younger_brother
	name = "Younger Brother"
	jobtype = /datum/job/younger_brother

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/syndicatecity/heads
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	glasses = /obj/item/clothing/glasses/middle_sunglasses
	backpack_contents = list(/obj/item/choice_beacon/middle/younger)
	shoes = /obj/item/clothing/shoes/laceup
