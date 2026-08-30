//Udjat Scout
/datum/job/scout
	title = "Thumb Soldato"
	outfit = /datum/outfit/job/scout
	department_head = list("the heavy infantry and the captain")
	faction = "Station"
	supervisors = "the heavy infantry and the captain"
	selection_color = "#b0936f"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/captain
	faction_positions = 6
	display_order = JOB_DISPLAY_ORDER_SYNDICATEGOON
	access = list("udjat")
	minimal_access = list("udjat")
	radio_channel_name = "Udjat"
	radio_channel_color = "#8b0000"
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 100
	maptype = list("city")
	job_important = "You are a soldier in the Thumb Syndicate. You are to stay quiet and follow orders from your capo and sottocapo. Not doing either will result in  death."
	job_notice = "Avoid killing other players without a reason."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 60,
								PRUDENCE_ATTRIBUTE = 60,
								TEMPERANCE_ATTRIBUTE = 60,
								JUSTICE_ATTRIBUTE = 60
								)

/datum/job/scout/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/scout
	name = "Udjat Scout"
	jobtype = /datum/job/scout

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list()
	shoes = /obj/item/clothing/shoes/laceup
