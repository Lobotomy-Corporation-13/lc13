//Full Stop Operator
/datum/job/kcorp_goon
	title = "Kcorp Filmographer"
	outfit = /datum/outfit/job/kcorp_goon
	department_head = list("Kcorp Lead Film Director")
	faction = "Station"
	supervisors = "Kcorp Lead Film Director"
	selection_color = "#8e8f9e"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/kcorpdrone
	faction_positions = 2
	display_order = 110.1
	trusted_only = FALSE
	access = list("kcorp")
	minimal_access = list("kcorp")
	radio_channel_name = "Kcorp"
	radio_channel_color = COLOR_VERY_PALE_LIME_GREEN
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 100
	maptype = list("city")
	job_important = "Years of film school has lead you to working under the Film and \
		Media branch of K-Corp. Generally you will linger around the K corp drone that \
		functions as both a camera and a superior. Assist your boss in gathering footage \
		of human death to send back to your benefactors."

/datum/job/kcorp_goon/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	return ..()

/datum/outfit/job/kcorp_goon
	name = "Kcorp Filmographer"
	jobtype = /datum/job/kcorp_goon
	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/suit/lobotomy/kcorp
	backpack_contents = list(/obj/item/camera, /obj/item/camera_film,
		/obj/item/camera_film,)
	shoes = /obj/item/clothing/shoes/laceup
