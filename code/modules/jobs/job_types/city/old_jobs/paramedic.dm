// Retired with the clinic rework. This was the City's only Paramedic and the
// Clinic Field Agent replaces it; it is kept rather than deleted because the
// outfit is still a reasonable base for anyone wanting a stretcher role back.
// Not in the .dme.

/datum/job/doctor/medic
	title = "Paramedic"
	selection_color = "#ccddee"
	department_head = list("Doctor")
	supervisors = "the doctor"

	outfit = /datum/outfit/job/doctor/medic

	total_positions = 0
	spawn_positions = 0
	faction_positions = 1
	exp_requirements = 180

	display_order = JOB_DISPLAY_ORDER_MEDICALASSIST
	maptype = list("city")
	job_important = "You are an assistant to the town doctor, visit your clinic to the east of town and assist the doctor by bringing bodies in."


/datum/outfit/job/doctor/medic
	name = "Paramedic"
	jobtype = /datum/job/doctor/medic

	uniform = /obj/item/clothing/under/rank/medical/paramedic
	head = /obj/item/clothing/head/soft/paramedic
	suit =  /obj/item/clothing/suit/toggle/labcoat/paramedic
	backpack_contents = list(/obj/item/pinpointer/crew = 1, /obj/item/paramedic_cloak = 1)

