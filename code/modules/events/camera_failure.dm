/datum/round_event_control/lc13/extraction_blitz
	name = "Extraction Blitz"
	typepath = /datum/round_event/extraction_blitz
	weight = 30
	max_occurrences = 5
	//The RO should probably see this happening.

/datum/round_event/extraction_blitz
	fakeable = FALSE

/datum/round_event/extraction_blitz/start()
	SSabnormality_queue.SpawnAbno()

