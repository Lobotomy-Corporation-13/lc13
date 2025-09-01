/*
Axe Gang Member
*/
/datum/job/axegang
	title = "Axe Gang Member"
	faction = "Station"
	total_positions = 0
	spawn_positions = 0
	supervisors = "your leader"
	selection_color = "#555555"
	access = list(ACCESS_LAWYER)
	minimal_access = list(ACCESS_LAWYER)
	departments = DEPARTMENT_FIXERS // Even closer than rats
	outfit = /datum/outfit/job/axegang
	display_order = JOB_DISPLAY_ORDER_ANTAG
	exp_requirements = 300
	job_important = "Make deals, follow your Leader's orders and perform contracts. You are not allowed to target members of your own gang. \
		You are encouraged to make deals with both fixers and other syndicates to maximize profits, even if it means double crossing the contractor."

	allow_bureaucratic_error = FALSE
	maptype = "city"
	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 40,
								PRUDENCE_ATTRIBUTE = 40,
								TEMPERANCE_ATTRIBUTE = 40,
								JUSTICE_ATTRIBUTE = 40
								)



/datum/job/axegang/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)

	to_chat(src,span_userdanger("Make deals, follow your Leader's orders and perform contracts. You are not allowed to target members of your own gang. \
			You are encouraged to make deals with both fixers and other syndicates to maximize profits, even if it means double crossing the contractor"))

	. = ..()

	var/weapon = /obj/item/ego_weapon/city/axegang
	var/armor = /obj/item/clothing/suit/armor/ego_gear/city/misc/axegang
	H.equip_to_slot_or_del(new armor(H),ITEM_SLOT_HANDS)
	H.equip_to_slot_or_del(new weapon(H),ITEM_SLOT_HANDS)

/datum/outfit/job/axegang
	name = "Civilan"
	jobtype = /datum/job/civilian
	uniform = /obj/item/clothing/under/suit/charcoal
	belt = null
	ears = null
