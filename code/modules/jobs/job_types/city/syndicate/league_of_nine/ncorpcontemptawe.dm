//jia huan
/datum/job/ncorpcontemptawe
	title = "New League of Nine Project Supervisor"
	outfit = /datum/outfit/job/ncorpcontemptawe
	department_head = list("Nagel und Hammer")
	faction = "Station"
	supervisors = "Nagel und Hammer."
	selection_color = "#b5a357"
	total_positions = 0
	spawn_positions = 0
	display_order = JOB_DISPLAY_ORDER_SYNDICATEHEAD
	trusted_only = TRUE
	access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	minimal_access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	departments = DEPARTMENT_COMMAND | DEPARTMENT_CITY_ANTAGONIST
	paycheck = 700
	maptype = list("city")
	job_important = "You are a member of the New League of Nine Littérateurs. \
		You've been designated as the project leader for the Identity Imprintation Matrix. \
		Your main goal is to recruit/kidnap partipants for ID imprintation. \
		You're not authorized to leave your E.G.O. unattended, do not wear disguises. \
		Your base is hidden in the alleyway in the east behind the NO ENTRY Door."
	job_notice = "Avoid killing other players without a reason."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 120,
								PRUDENCE_ATTRIBUTE = 120,
								TEMPERANCE_ATTRIBUTE = 120,
								JUSTICE_ATTRIBUTE = 120
								)

/datum/job/ncorpcontemptawe/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	//Don't spawn these goobers without a director.
	for(var/datum/job/processing in SSjob.occupations)
		if(istype(processing, /datum/job/leagueofninefellbullet))
			processing.total_positions = 1

		if(istype(processing, /datum/job/)) //change me 2 fairy
			processing.total_positions = 2
	. = ..()


/datum/outfit/job/ncorpcontemptawe
	name = "New League of Nine Project Supervisor"
	jobtype = /datum/job/ncorpcontemptawe

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/syndicatecity/heads
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	backpack_contents = list(/obj/item/structurecapsule/syndicate/ncorp, /obj/item/office_marker/syndicate)
	shoes = /obj/item/clothing/shoes/laceup
