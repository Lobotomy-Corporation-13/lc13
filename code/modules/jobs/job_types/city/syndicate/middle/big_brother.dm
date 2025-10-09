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
	job_important = "This is a roleplay role. You are the leader of this Middle branch. Your goal is to make money and riches, and exert the Middle's will. \
		You are not to tolerate anyone talking down to you, and none of the Middle may use disguises. \
		You may order the death of any other player aside from Hana association and Association Director that does not give you the respect you deserve. \
		You may order the death of any of your Younger Brothers or Little Brothers for so much as questioning you. \
		You yourself probably does not need to fight, and can guide from your office if needed. \
		Your base is hidden in the alleyway in the east behind the NO ENTRY Door."
	job_notice = "You may kill other players for any major disrespect; avoid killing players for minor infractions."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 100,
								PRUDENCE_ATTRIBUTE = 100,
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
	backpack_contents = list(/obj/item/structurecapsule/syndicate/thumb, /obj/item/choice_beacon/middle/big)
	shoes = /obj/item/clothing/shoes/laceup
