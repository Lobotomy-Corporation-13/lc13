//Wedge Operator
/datum/job/wedge
	title = "Wedge Office Operator"
	outfit = /datum/outfit/job/wedge
	department_head = list("The Hana Association")
	faction = "Station"
	supervisors = "The Hana Association"
	selection_color = "#8e8f9e"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/wedge
	faction_positions = 1
	display_order = 108
	access = list("wedge")
	minimal_access = list("wedge")
	radio_channel_name = "Wedge"
	radio_channel_color = "#616161"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 700
	maptype = list("city")
	job_important = "You are the operator of Wedge office, an investigation office under contract of the Liu Association. \
	Your office radio will send you to crime scenes around the city. Lead your fixers in searching each scene for evidence, \
	then use what you found to name the right suspect. Getting it right is how your office earns its keep."


	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 80,
								PRUDENCE_ATTRIBUTE = 80,
								TEMPERANCE_ATTRIBUTE = 80,
								JUSTICE_ATTRIBUTE = 80
								)

/datum/job/wedge/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/wedge
	name = "Wedge Office Operator"
	jobtype = /datum/job/wedge
	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction/heads
	glasses = /obj/item/clothing/glasses/eyepatch/wedgeleader
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list(/obj/item/structurecapsule/fixer/wedge)
	shoes = /obj/item/clothing/shoes/laceup

/obj/structure/sign/wedge
	name = "\improper Wedge Office sign"
	desc = "The emblem of the Wedge Office: a blue-cored spear rising from a fleur-de-lis."
	icon = 'ModularLobotomy/_Lobotomyicons/lc13icons.dmi'
	icon_state = "wedge"
	buildable_sign = FALSE
