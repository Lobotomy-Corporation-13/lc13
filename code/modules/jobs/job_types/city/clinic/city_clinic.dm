// The City clinic. A Director, two Staff who work inside, two Field Agents who
// do not. Every specialisation runs these same five slots.
//
// Titles are fixed and never change with the specialisation. `title` keys
// SSjob.name_occupations, the lobby preference menu and every assigned_role
// check in the codebase, and ApplyToJobs() runs after name_occupations is
// built, so renaming a job there desyncs the lookup. The faction identity
// rides on display_title, outfit, access and radio instead.
//
// The Director's alt_titles are the pick. SScity_factions reads the chosen one
// off the player's preferences during roundstart assignment and stamps the
// matching variant onto all five jobs, which is early enough that everyone
// spawns already dressed. See FACTIONS.md.
//
// Only the Director carries a company name before the round starts, because the
// Director is the one who chooses it. Staff and Field Agent keep their plain
// titles in the lobby on purpose: at that point nobody has picked yet, and
// advertising them as Mirae would be a promise a K-Corp round breaks. The
// variant renames them the moment it is settled, which is still before anyone
// spawns.

/datum/job/city_clinic
	title = "Clinic Director"
	display_title = "Mirae Clinic Director"
	outfit = /datum/outfit/job/city_clinic
	department_head = list("your own judgement")
	faction = "Station"
	supervisors = "nobody. The clinic answers to whoever is paying."
	selection_color = "#aabbcc"
	total_positions = 0
	spawn_positions = 0
	leader = /datum/job/city_clinic
	faction_positions = 1
	//No plain "Clinic Director" in the picker. Every clinic belongs to someone,
	//and offering the bare title would advertise a neutral one that cannot be
	//played. Choosing nothing still lands on Mirae.
	alt_titles_only = TRUE
	alt_titles = list(
		"Mirae Clinic Director",
		"K-Corp Clinic Director",
	)
	access = list(ACCESS_MEDICAL, "clinic", "clinic_leader")
	minimal_access = list(ACCESS_MEDICAL, "clinic", "clinic_leader")
	radio_channel_name = "Clinic"
	radio_channel_color = "#4a8f7b"
	departments = DEPARTMENT_COMMAND | DEPARTMENT_MEDICAL
	display_order = JOB_DISPLAY_ORDER_MEDICAL
	paycheck = PAYCHECK_MEDIUM
	paycheck_department = ACCOUNT_MED
	exp_requirements = 600
	//Matched to the gear this role is issued. job_attribute_limit caps
	//training, so leaving it under the coat's requirement would hand the
	//Director an overcoat they can never put on.
	job_attribute_limit = 100
	liver_traits = list(TRAIT_MEDICAL_METABOLISM)
	maptype = list("city")
	job_important = "You run the clinic. Your parent company is whichever one \
		you set as this job's title in your preferences, and it decides what \
		your clinic is and what your staff are issued. Set nothing and you \
		are Mirae. Charge for your services."

	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 100,
								PRUDENCE_ATTRIBUTE = 100,
								TEMPERANCE_ATTRIBUTE = 100,
								JUSTICE_ATTRIBUTE = 100
								)

/datum/job/city_clinic/after_spawn(mob/living/carbon/human/H, mob/M, latejoin = FALSE)
	. = ..()
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)

/datum/outfit/job/city_clinic
	name = "Clinic Director"
	jobtype = /datum/job/city_clinic

	belt = /obj/item/pda/medical
	ears = /obj/item/radio/headset/faction/heads
	uniform = /obj/item/clothing/under/suit/lobotomy/plain
	suit = /obj/item/clothing/suit/toggle/labcoat
	shoes = /obj/item/clothing/shoes/sneakers/white
	head = /obj/item/clothing/head/beret/tegu/med
	l_hand = /obj/item/storage/firstaid/medical

	backpack = /obj/item/storage/backpack/medic
	satchel = /obj/item/storage/backpack/satchel/med
	duffelbag = /obj/item/storage/backpack/duffelbag/med
	box = /obj/item/storage/box/survival/medical

// Inside the clinic. These are the ones who actually heal people.
/datum/job/city_clinic/staff
	title = "Clinic Staff"
	//Also inherited from the Director, who does hide their plain title. These
	//two have no alt titles at all, so leaving it set would build an empty
	//picker with nothing in it to choose.
	alt_titles_only = FALSE
	//Cleared, not inherited. Both sub-roles are subtypes of the Director, so
	//without this they pick up "Mirae Clinic Director" as their display name
	//and all three read identically in the lobby. Null lets New() fall back to
	//this job's own title, which is what a player signing up should see.
	display_title = null
	outfit = /datum/outfit/job/city_clinic/staff
	department_head = list("Clinic Director")
	supervisors = "the clinic director"
	selection_color = "#ccddee"
	leader = /datum/job/city_clinic
	faction_positions = 2
	//Cleared: only the Director picks, and inheriting theirs would let a
	//staffer select a Director alt title from their own preferences.
	alt_titles = list()
	access = list(ACCESS_MEDICAL, "clinic")
	minimal_access = list(ACCESS_MEDICAL, "clinic")
	departments = DEPARTMENT_MEDICAL
	display_order = JOB_DISPLAY_ORDER_MEDICALASSIST
	exp_requirements = 180
	//Left where the old clinic sat. The ward coat asks for 20, so this is
	//already more than enough, and Staff are not meant to be a fighting role.
	job_attribute_limit = 40
	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 40,
								PRUDENCE_ATTRIBUTE = 40,
								TEMPERANCE_ATTRIBUTE = 40,
								JUSTICE_ATTRIBUTE = 40
								)
	job_important = "You work the clinic floor. Treat whoever walks in, and \
		make them pay for it."

/datum/outfit/job/city_clinic/staff
	name = "Clinic Staff"
	jobtype = /datum/job/city_clinic/staff

	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/rank/medical/doctor/blue
	suit = null
	head = /obj/item/clothing/head/beret/tegu/med

// Outside the clinic. Both specialisation gimmicks hang off this role, which
// is why it is split off Staff rather than being more of them.
/datum/job/city_clinic/field
	title = "Clinic Field Agent"
	//Also inherited from the Director, who does hide their plain title. These
	//two have no alt titles at all, so leaving it set would build an empty
	//picker with nothing in it to choose.
	alt_titles_only = FALSE
	//Cleared, not inherited. Both sub-roles are subtypes of the Director, so
	//without this they pick up "Mirae Clinic Director" as their display name
	//and all three read identically in the lobby. Null lets New() fall back to
	//this job's own title, which is what a player signing up should see.
	display_title = null
	outfit = /datum/outfit/job/city_clinic/field
	department_head = list("Clinic Director")
	supervisors = "the clinic director"
	selection_color = "#ccddee"
	leader = /datum/job/city_clinic
	faction_positions = 2
	//Cleared: only the Director picks, and inheriting theirs would let a
	//staffer select a Director alt title from their own preferences.
	alt_titles = list()
	access = list(ACCESS_MEDICAL, "clinic")
	minimal_access = list(ACCESS_MEDICAL, "clinic")
	departments = DEPARTMENT_MEDICAL
	display_order = JOB_DISPLAY_ORDER_MEDICALASSIST
	exp_requirements = 180
	job_attribute_limit = 80
	roundstart_attributes = list(
								FORTITUDE_ATTRIBUTE = 80,
								PRUDENCE_ATTRIBUTE = 80,
								TEMPERANCE_ATTRIBUTE = 80,
								JUSTICE_ATTRIBUTE = 80
								)
	job_important = "You work the street rather than the ward. What that means \
		depends on who owns your clinic."

/datum/outfit/job/city_clinic/field
	name = "Clinic Field Agent"
	jobtype = /datum/job/city_clinic/field

	ears = /obj/item/radio/headset/faction
	uniform = /obj/item/clothing/under/rank/medical/paramedic
	suit = /obj/item/clothing/suit/toggle/labcoat/paramedic
	head = /obj/item/clothing/head/soft/paramedic
	backpack_contents = list(/obj/item/pinpointer/crew = 1)
