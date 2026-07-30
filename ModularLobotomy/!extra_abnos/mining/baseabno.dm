
/mob/living/simple_animal/hostile/abnormality/mining
	var/recovery_time = 0
	abnormality_origin = ABNORMALITY_DUMMY

//Stuff that Megafauna loves using.
/mob/living/simple_animal/hostile/abnormality/mining/proc/SetRecoveryTime(buffer_time, ranged_buffer_time)
	recovery_time = world.time + buffer_time
	ranged_cooldown = world.time + buffer_time
	if(ranged_buffer_time)
		ranged_cooldown = world.time + ranged_buffer_time

/mob/living/simple_animal/hostile/abnormality/mining/AttackingTarget(atom/attacked_target)
	if(recovery_time >= world.time)
		return
	. = ..()
