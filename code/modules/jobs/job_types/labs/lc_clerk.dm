
/datum/job/staff
	title = "LCE Clerk"
	faction = "Station"
	supervisors = "the LCE Lead Researcher and the Researchers"
	total_positions = -1
	spawn_positions = -1
	selection_color = "#bbbbbb"

	outfit = /datum/outfit/job/staff

	access = list()	//No Acess
	minimal_access = list()
	departments = DEPARTMENT_SCIENCE

	job_attribute_limit = 0


	display_order = 999
	alt_titles = list()
	maptype = "limbus_labs"
	job_important = "You are a LCE Clerk. You have little responsibilities, but are encouraged to assist around the facility."
	job_abbreviation = "CLK"



/datum/outfit/job/staff
	name = "LCE Clerk"
	jobtype = /datum/job/staff

	belt = /obj/item/pda/toxins
	ears = /obj/item/radio/headset
	uniform = /obj/item/clothing/under/suit/lce
	accessory = /obj/item/clothing/accessory/armband/lobotomy/extraction/lce
	shoes = /obj/item/clothing/shoes/sneakers/white
	l_pocket = /obj/item/radio
