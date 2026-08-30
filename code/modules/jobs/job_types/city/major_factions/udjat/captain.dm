//Udjat Captain
/datum/job/captain
	title = "Udjat Captain"
	outfit = /datum/outfit/job/captain
	department_head = list("Lady Dias")
	faction = "Station"
	supervisors = "Lady Dias"
	selection_color = "#856948"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/captain
	faction_positions = 1
	display_order = JOB_DISPLAY_ORDER_SYNDICATEHEAD
	trusted_only = TRUE
	access = list("udjat", "udjat_leader")
	minimal_access = list("udjat", "udjat_leader")
	radio_channel_name = "Udjat"
	radio_channel_color = "#caa75f"
	departments = DEPARTMENT_COMMAND | DEPARTMENT_CITY_ANTAGONIST
	paycheck = 700
	maptype = list("city")
	job_important = "This is a roleplay role. You are the leader of this section of the udjat. Your goal is to combat distortions for money and exert the will of lady Dias. \
	Your job is to lead the udjat in the area to combat distortions, earn money & lead your men into combat against other factions. \
	In your base is a vendor to dispense ammunition for your udjat weapons, your scouts do not get rifles. \
	Ammo is expensive and you should seek to use it sparingly."


	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 100,
								PRUDENCE_ATTRIBUTE = 100,
								TEMPERANCE_ATTRIBUTE = 100,
								JUSTICE_ATTRIBUTE = 100
								)

/datum/job/captain/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/captain
	name = "Udjat Captain"
	jobtype = /datum/job/captain

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction/heads
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list(/obj/item/structurecapsule/syndicate/thumb, /obj/item/office_marker/syndicate)
	shoes = /obj/item/clothing/shoes/laceup
