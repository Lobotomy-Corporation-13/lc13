//Little Brother
/datum/job/little_brother
	title = "Little Brother"
	outfit = /datum/outfit/job/little_brother
	department_head = list("Younger Brother and Big Brother.")
	faction = "Station"
	supervisors = "Younger Brother and Big Brother."
	selection_color = "#b0936f"
	total_positions = 0
	spawn_positions = 0
	display_order = JOB_DISPLAY_ORDER_SYNDICATEGOON
	access = list(ACCESS_SYNDICATE)
	minimal_access = list(ACCESS_SYNDICATE)
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 100
	maptype = list("city")
	job_important = "The little brother of this Middle section. Your goal is to follow the orders of your younger and big brothers. \
		The Middle values family above all else, so if anyone harms or disrespect your family make sure they will suffer for it. \
		You also have a delivery radio at your base. It will allow you earn money by delivering U-Corp goods. \
		Your base is hidden in the alleyway in the east behind the NO ENTRY Door."
	job_notice = "You may harm other players for any disrespect to the middle; avoid killing players for too minor infractions."


	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 60,
								PRUDENCE_ATTRIBUTE = 60,
								TEMPERANCE_ATTRIBUTE = 60,
								JUSTICE_ATTRIBUTE = 60
								)

/datum/job/little_brother/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/little_brother
	name = "Little Brother"
	jobtype = /datum/job/little_brother

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/syndicatecity
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	glasses = /obj/item/clothing/glasses/middle_sunglasses
	backpack_contents = list(/obj/item/choice_beacon/middle/little)
	shoes = /obj/item/clothing/shoes/laceup
