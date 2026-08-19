//thumb sottocapo
/datum/job/sottocapo
	title = "Thumb Sottocapo"
	outfit = /datum/outfit/job/sottocapo
	department_head = list("money and order.")
	faction = "Station"
	supervisors = "money and order."
	selection_color = "#856948"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/sottocapo
	faction_positions = 1
	display_order = JOB_DISPLAY_ORDER_SYNDICATEHEAD
	trusted_only = TRUE
	access = list("thumb_south", "thumb_south_leader")
	minimal_access = list("thumb_south", "thumb_south_leader")
	radio_channel_name = "Thumb South"
	radio_channel_color = "#8b0000"
	departments = DEPARTMENT_COMMAND | DEPARTMENT_CITY_ANTAGONIST
	paycheck = 700
	maptype = list("city")
	job_important = "This is a roleplay role. You are the leader of this thumb branch. Your goal is to make money and riches, and exert the thumb's will. \
		You are not to tolerate anyone talking down to you, and none of the thumb may use disguises. \
		You may order the death of any other player aside from the Hana association and Association Director that does not give you the respect you deserve. \
		You may order the death of any of your capos or soldatos for so much as questioning you. \
		You yourself probably does not need to fight, and can guide from your office if needed. \
		Your base is hidden in the alleyway in the east behind the NO ENTRY Door."
	job_notice = "You may kill other players for any major disrespect; avoid killing players for minor infractions."

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


/datum/outfit/job/sottocapo
	name = "Thumb Sottocapo"
	jobtype = /datum/job/sottocapo

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction/heads
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	glasses = /obj/item/clothing/glasses/sunglasses
	backpack_contents = list(/obj/item/structurecapsule/syndicate/thumb, /obj/item/office_marker/syndicate)
	shoes = /obj/item/clothing/shoes/laceup
