//The Oracle's Proxy
/datum/job/oracles_proxy
	title = "Oracle Proxy"
	outfit = /datum/outfit/job/oracles_proxy
	department_head = list("the will of the prescript")
	faction = "Station"
	supervisors = "the will of the prescript"
	selection_color = "#cccccc"
	total_positions = 0
	spawn_positions = 0
	display_order = JOB_DISPLAY_ORDER_SYNDICATEHEAD
	trusted_only = TRUE
	access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	minimal_access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	departments = DEPARTMENT_COMMAND | DEPARTMENT_CITY_ANTAGONIST
	paycheck = 1000
	maptype = list("city", "fixers")
	job_important = "You are a wandering proxy of the Index, carrying out prescripts delivered to you by the Oracle. \
		You are not inherently hostile, but you must follow the prescripts you receive. \
		Use your index pager to receive and view your prescripts."
	job_notice = "Avoid killing other players without a reason. Killing a player for stopping your prescripts is a valid reason."

	roundstart_attributes = list(
		FORTITUDE_ATTRIBUTE = 300,
		PRUDENCE_ATTRIBUTE = 300,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100
	)

/datum/job/oracles_proxy/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	. = ..()

/datum/outfit/job/oracles_proxy
	name = "Oracle Proxy"
	jobtype = /datum/job/oracles_proxy

	id = /obj/item/card/id/silver/plastic
	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/headset_cent
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	glasses = /obj/item/clothing/glasses/sunglasses
	shoes = /obj/item/clothing/shoes/laceup
	l_hand = /obj/item/ego_weapon/index_vial
	r_hand = /obj/item/clothing/suit/armor/ego_gear/city/index_proxy_wanderer
	accessory = /obj/item/clothing/accessory/index_pager
