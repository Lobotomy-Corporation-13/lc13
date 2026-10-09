/datum/round_event_control/extraction_blitz
	name = "Extraction Blitz"
	typepath = /datum/round_event/extraction_blitz
	weight = 2
	max_occurrences = 1

/datum/round_event/extraction_blitz
	fakeable = FALSE

/datum/round_event/extraction_blitz/start()
	SSabnormality_queue.SpawnAbno()
	priority_announce("HQ has decided that your facility has not met extraction Quota. An Extra abnormality is being sent to you post-haste; should you have the space.", "HQ Central Command")

