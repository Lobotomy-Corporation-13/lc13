///Spawns a cargo pod containing a random cargo supply pack on a random area of the station
/datum/round_event_control/lc13/abno_breach
	name = "Qliphoth Containment Failure"
	typepath = /datum/round_event_control/lc13/abno_breach
	weight = 20
	max_occurrences = 999
	earliest_start = 10 MINUTES

/datum/round_event/abno_breach/setup()
	priority_announce("ATTENTION: Our sensors have detected that the containment of one of your abnormalities is nearing failure.", "HQ Discipline")
	startWhen = rand(20, 40)

///Spawns a random crate
/datum/round_event/abno_breach/start()
	var/list/qliphoth_abnos = list()
	for(var/mob/living/simple_animal/hostile/abnormality/V in GLOB.abnormality_mob_list)
		if(V.IsContained() && V.can_breach)
			qliphoth_abnos += V

	if(LAZYLEN(qliphoth_abnos))
		var/mob/living/simple_animal/hostile/abnormality/meltem = pick(qliphoth_abnos)
		meltem.datum_reference.qliphoth_change(-1)
