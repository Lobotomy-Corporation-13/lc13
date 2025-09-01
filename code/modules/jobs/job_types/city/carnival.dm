/datum/job/carnival
	title = "Carnival"
	faction = "Station"
	total_positions = 2
	spawn_positions = 2
	supervisors = "your self."
	selection_color = "#555555"
	access = list(ACCESS_CARGO)
	minimal_access = list(ACCESS_CARGO)
	departments = DEPARTMENT_SERVICE
	outfit = /datum/outfit/job/carnival
	display_order = JOB_DISPLAY_ORDER_ANTAG
	exp_requirements = 300

	allow_bureaucratic_error = FALSE
	maptype = "city"
	paycheck = 100

	allow_bureaucratic_error = FALSE
	maptype = list("wonderlabs", "city")
	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 80,
								PRUDENCE_ATTRIBUTE = 80,
								TEMPERANCE_ATTRIBUTE = 80,
								JUSTICE_ATTRIBUTE = 80
								)



/datum/job/carnival/after_spawn(mob/living/carbon/human/H, mob/M, latejoin = FALSE)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	H.set_species(/datum/species/synth/carnival)
	job_important = "You are allowed to enter the ruins to hunt for silk. However, DO NOT LOOT THE WEAPONS, CASH OR ARMOR FROM THE BACKSTREETS! \
			Your primary goal is to kill monsters in the ruins and/or humans to weave silk so you can then sell it to the humans. \
			You have a base on the left side of the nest. \
			You are allowed to hunt down players as you see fit, especially if they are by themselves! (However avoid spawn killing them, by waiting at the entrance.)"
	..()

/datum/outfit/job/carnival
	name = "Carnival"
	jobtype = /datum/job/carnival
	uniform = /obj/item/clothing/under/suit/black
	belt = /obj/item/pda/roboticist
	suit = null
	l_pocket = null
	ears = /obj/item/radio/headset/wcorp/safety
	mask = /obj/item/clothing/mask/carnival_mask
	gloves = /obj/item/clothing/gloves/color/black

	backpack_contents = list(
		/obj/item/book/granter/crafting_recipe/carnival/weaving_armor = 1,
		/obj/item/stack/sheet/silk/indigo_simple = 4,
		/obj/item/stack/sheet/silk/green_simple = 4,
		/obj/item/stack/sheet/silk/amber_simple = 4,
		/obj/item/stack/sheet/silk/steel_simple = 4,
		/obj/item/stack/sheet/silk/human_simple = 1)

	implants = list(
		/obj/item/organ/cyberimp/arm/carnival,		//theyre full body prosthetics, the blades are inside them
		/obj/item/organ/cyberimp/eyes/hud/medical,)	//replaces their med nvg
