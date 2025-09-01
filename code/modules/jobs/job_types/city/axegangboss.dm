/*
Axe Gang Leader
*/
/datum/job/axegangleader
	title = "Axe Gang Leader"
	faction = "Station"
	total_positions = 0
	spawn_positions = 0
	supervisors = "your wallet"
	selection_color = "#555555"
	access = list(ACCESS_LAWYER)
	minimal_access = list(ACCESS_LAWYER)
	departments = DEPARTMENT_FIXERS // Even closer than rats
	outfit = /datum/outfit/job/axegangleader
	display_order = JOB_DISPLAY_ORDER_ANTAG
	exp_requirements = 300
	job_important = "Your goal is to make as much money as possible by carrying out unauthorized contracts. \
		Find dirty jobs, rake in money and take care of your crew. Do not accept jobs that involve hunting down your own gang. \
		You are encouraged to make deals with both fixers and other syndicates to maximize profits, even if it means double crossing the contractor."

	allow_bureaucratic_error = FALSE
	maptype = "city"
	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 60,
								PRUDENCE_ATTRIBUTE = 60,
								TEMPERANCE_ATTRIBUTE = 60,
								JUSTICE_ATTRIBUTE = 60
								)



/datum/job/axegangleader/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)

	//Don't spawn these goons without a boss.
	for(var/datum/job/processing in SSjob.occupations)
		if(istype(processing, /datum/job/axegang))
			processing.total_positions = 2
	. = ..()




	var/weapon = /obj/item/ego_weapon/city/axegang/leader
	var/armor = /obj/item/clothing/suit/armor/ego_gear/city/misc/axegang_boss
	H.equip_to_slot_or_del(new armor(H),ITEM_SLOT_HANDS)
	H.equip_to_slot_or_del(new weapon(H),ITEM_SLOT_HANDS)

/datum/outfit/job/axegangleader
	name = "Civilan"
	jobtype = /datum/job/civilian
	uniform = /obj/item/clothing/under/suit/charcoal
	belt = null
	ears = null
