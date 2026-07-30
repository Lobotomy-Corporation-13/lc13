//Big Brother
/datum/job/big_brother
	title = "Big Brother"
	outfit = /datum/outfit/job/big_brother
	department_head = list("money and family.")
	faction = "Station"
	supervisors = "money and family."
	selection_color = "#856948"
	total_positions = 0
	spawn_positions = 0
	display_order = JOB_DISPLAY_ORDER_SYNDICATEHEAD
	trusted_only = TRUE
	access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	minimal_access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	departments = DEPARTMENT_COMMAND | DEPARTMENT_CITY_ANTAGONIST
	paycheck = 700
	maptype = list("city")
	job_important = "This is a roleplay role. You are the leader of this Middle section. Your goal is to make money, make sure everyone respects the middle, and have a great time. \
		The Middle values family above all else, so if anyone harms or disrespect your family make sure they will suffer for it. \
		You may write down rules in your book of Vengeance, and if someone breaks one of your rules, give them a fitting punishment of their crime (Such as breaking an arm for stealing hair coupons.). \
		Your Younger Brothers or Little Brothers are your family, protect them and have a great time with them. If someone breaks one of your rules, feel free to send your Brothers against them. \
		You also have a delivery radio at your base. It will allow you earn money by delivering U-Corp goods. \
		Your base is hidden in the alleyway in the east behind the NO ENTRY Door."
	job_notice = "You may harm other players for any disrespect to the middle; avoid killing players for too minor infractions."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 200,
								PRUDENCE_ATTRIBUTE = 200,
								TEMPERANCE_ATTRIBUTE = 100,
								JUSTICE_ATTRIBUTE = 100
								)

/datum/job/big_brother/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	//Don't spawn these goobers without a director.
	for(var/datum/job/processing in SSjob.occupations)
		if(istype(processing, /datum/job/younger_brother))
			processing.total_positions = 2

		if(istype(processing, /datum/job/little_brother))
			processing.total_positions = 4
	. = ..()


/datum/outfit/job/big_brother
	name = "Big Brother"
	jobtype = /datum/job/big_brother

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/syndicatecity/heads
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	glasses = /obj/item/clothing/glasses/middle_sunglasses
	backpack_contents = list(/obj/item/structurecapsule/syndicate/middle, /obj/item/choice_beacon/middle/big)
	shoes = /obj/item/clothing/shoes/laceup
