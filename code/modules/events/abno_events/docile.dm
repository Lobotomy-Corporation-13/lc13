/datum/round_event_control/lc13/docile_abno
	name = "Docile Abnormality"
	typepath = /datum/round_event/docile_abno
	max_occurrences = 3
	weight = 10
	earliest_start = 20 MINUTES // We want it to happen when there's at least *some* abnos.

/datum/round_event/docile_abno
	announceWhen = 1
	endWhen = 600
	var/list/affected_abnos = list()
	var/abno_names_string = ""
	var/max_abno_hit = 4 //Maybe make it scale with pop or the current number of abnos? 4 sounds like an okay number for now.


/datum/round_event/docile_abno/announce()
	priority_announce("[abno_names_string] have become uncharacteristically docile, \
	severely increasing their ego and energy production. \
	However, this docility makes them trivial to work with, and will make for subpar agent training. \
	The abnormalities are expected to go back to their regular behavior in 6 minutes.",
	sound = 'sound/misc/notice2.ogg',
	sender_override = "HQ Central Command")

/datum/round_event/docile_abno/start()
	var/list/valid_abno_list = list()
	var/highest_threat_level = ZAYIN_LEVEL
	var/highest_threat_amount = 0
	var/datum/abnormality/highest_abno_threat
	for(var/mob/living/simple_animal/hostile/abnormality/abno in GLOB.abnormality_mob_list)
		if(!abno.can_spawn) //We don't consider unspawnable abnos like rabbit and tutorial ones.
			continue
		var/datum/abnormality/abno_datum = abno.datum_reference
		if(!abno_datum)
			continue
		if(abno_datum.docile)
			continue
		if(abno_datum.threat_level > highest_threat_level)
			highest_abno_threat = abno_datum
			highest_threat_amount = 0
		highest_threat_amount++
		valid_abno_list += abno_datum

	if(highest_abno_threat && highest_threat_amount < 2)
		valid_abno_list -= highest_abno_threat //If the highest threat abno is the only one, we remove them as a valid target so that they still have something to train on.

	var/wanted_abno_hit = rand(2, max_abno_hit) //We want to hit at least two abnos.
	var/list/abno_name_list = list()
	for(var/abno_hit = 1 to wanted_abno_hit)
		if(!valid_abno_list.len)
			break
		var/datum/abnormality/abno_datum = pick(valid_abno_list)
		valid_abno_list -= abno_datum
		affected_abnos += abno_datum
		abno_name_list += abno_datum.name
		abno_datum.docile = TRUE
	abno_names_string = jointext(abno_name_list, ", ")

/datum/round_event/docile_abno/end()
	for(var/datum/abnormality/abno_datum in affected_abnos)
		abno_datum.docile = FALSE
	priority_announce("All docile abnormalities are now back to their regular behavior, making them apt for training once again.",
	sound = 'sound/misc/notice2.ogg',
	sender_override = "HQ Central Command")
