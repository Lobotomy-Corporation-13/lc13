///Spawns a cargo pod containing a random cargo supply pack on a random area of the station
/datum/round_event_control/lc13/rats
	name = "Rat Invasion"
	typepath = /datum/round_event/rats
	weight = 30
	max_occurrences = 2
	earliest_start = 10 MINUTES


/datum/round_event/rats/announce(fake)
	priority_announce("Sensors show that a couple street rats have wound up inside your facility. Rid of them.", "HQ Discipline")

///Spawns a random crate
/datum/round_event/rats/start()
	var/spawn_amount = 3

	for(var/i = 1 to spawn_amount)
		var/potential_locs = pick(GLOB.xeno_spawn)
		new /mob/living/simple_animal/hostile/humanoid/rat (potential_locs)
		new /mob/living/simple_animal/hostile/humanoid/rat/zippy(potential_locs)
		new /mob/living/simple_animal/hostile/humanoid/rat/hammer(potential_locs)
