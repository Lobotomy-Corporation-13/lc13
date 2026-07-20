//The Udjat
/datum/job/udjatsgt
	title = "LCA Udjat Leader"
	faction = "Station"
	supervisors = "District Manager"
	total_positions = 1
	spawn_positions = 1
	exp_requirements = 0
	selection_color = "#555555"
	access = list(ACCESS_ARMORY, ACCESS_SECURITY, ACCESS_RND, ACCESS_MEDICAL, ACCESS_COMMAND, ACCESS_BRIG)
	minimal_access = list(ACCESS_ARMORY, ACCESS_SECURITY, ACCESS_RND, ACCESS_MEDICAL, ACCESS_COMMAND, ACCESS_BRIG)
	departments = DEPARTMENT_SECURITY

	outfit = /datum/outfit/job/udjatsgt
	display_order = 4

	job_important = "You are the LCA Udjat leader. Manage your squad and assist the Researchers when necessary."

	alt_titles = list()
	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 60,
								PRUDENCE_ATTRIBUTE = 60,
								TEMPERANCE_ATTRIBUTE = 60,
								JUSTICE_ATTRIBUTE = 60
								)
	loadalways = FALSE
	maptype = "limbus_labs"
	job_abbreviation = "UDL"


/datum/job/udjatsgt/after_spawn(mob/living/carbon/human/H, mob/M, latejoin = FALSE)
	..()
	H.set_attribute_limit(60)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)

/datum/outfit/job/udjatsgt
	name = "LCA Udjat Leader"
	jobtype = /datum/job/udjatsgt

	head = /obj/item/clothing/head/beret/sec/navywarden
	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/heads/headset_discipline
	glasses = /obj/item/clothing/glasses/sunglasses
	uniform = /obj/item/clothing/under/limbus/labs/commandsec
	backpack_contents = list(/obj/item/melee/classic_baton=1)
	shoes = /obj/item/clothing/shoes/laceup
	gloves = /obj/item/clothing/gloves/color/black
	implants = list(/obj/item/organ/cyberimp/eyes/hud/security)


/datum/job/udjat
	title = "LCA Udjat Agent"
	faction = "Station"
	supervisors = "LCA Udjat Leader"
	total_positions = 2
	spawn_positions = 2
	exp_requirements = 0
	selection_color = "#555555"
	access = list(ACCESS_ARMORY, ACCESS_SECURITY, ACCESS_RND, ACCESS_MEDICAL, ACCESS_COMMAND)
	minimal_access = list(ACCESS_ARMORY, ACCESS_SECURITY, ACCESS_RND, ACCESS_MEDICAL, ACCESS_COMMAND)
	departments = DEPARTMENT_SECURITY

	outfit = /datum/outfit/job/udjatsgt
	display_order = 4

	job_important = "You are an LCA Udjat agent. Assist the researchers when necessary!"

	alt_titles = list()
	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 60,
								PRUDENCE_ATTRIBUTE = 60,
								TEMPERANCE_ATTRIBUTE = 60,
								JUSTICE_ATTRIBUTE = 60
								)
	loadalways = FALSE
	maptype = "limbus_labs"
	job_abbreviation = "UDA"


/datum/job/udjat/after_spawn(mob/living/carbon/human/H, mob/M, latejoin = FALSE)
	..()
	H.set_attribute_limit(60)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)

/datum/outfit/job/udjat
	name = "LCA Udjat"
	jobtype = /datum/job/udjat

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/headset_discipline
	glasses = /obj/item/clothing/glasses/sunglasses
	uniform = /obj/item/clothing/under/limbus/labs/commandsec
	backpack_contents = list(/obj/item/melee/classic_baton=1)
	shoes = /obj/item/clothing/shoes/laceup
	gloves = /obj/item/clothing/gloves/color/black
	implants = list(/obj/item/organ/cyberimp/eyes/hud/security)

