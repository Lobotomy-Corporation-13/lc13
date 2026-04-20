//gubo
/datum/job/leagueofninefellbullet
	title = "Member of the New League of Nine"
	outfit = /datum/outfit/job/leagueofninefellbullet
	department_head = list("the project supervisor.")
	faction = "Station"
	supervisors = "the project supervisor."
	selection_color = "#2C375E"
	total_positions = 0
	spawn_positions = 0
	display_order = JOB_DISPLAY_ORDER_SYNDICATEGOON
	access = list(ACCESS_SYNDICATE)
	minimal_access = list(ACCESS_SYNDICATE)
	departments = DEPARTMENT_CITY_ANTAGONIST
	paycheck = 200
	maptype = list("city")
	job_important = "You are a member of the New League of Nine Littérateurs. \
			You're just below the project supervisor's rank. Your main goal is to mass-imprint the populace, \
			as this disrupts the Mirror Worlds. You may trade information about the Mirror with potential subjects, as needed."
	job_notice = "Avoid killing other players without a reason."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 80,
								PRUDENCE_ATTRIBUTE = 80,
								TEMPERANCE_ATTRIBUTE = 80,
								JUSTICE_ATTRIBUTE = 80
								)

/datum/job/leagueofninefellbullet/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()


/datum/outfit/job/leagueofninefellbullet
	name = "N Corp Fell Bullet"
	jobtype = /datum/job/leagueofninefellbullet

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/syndicatecity
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list()
	shoes = /obj/item/clothing/shoes/laceup
