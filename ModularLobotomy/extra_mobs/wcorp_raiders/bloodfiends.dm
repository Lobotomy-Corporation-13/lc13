//W-Corp Cleanup variants of bloodfiends that cannot dash through wave barriers

/mob/living/simple_animal/hostile/humanoid/blood/fiend/wave
	name = "bloodfiend"

/mob/living/simple_animal/hostile/humanoid/blood/fiend/wave/ClearSky(turf/T)
	. = ..()
	if(.)
		if(locate(/obj/structure/wave_barrier) in T.contents)
			return FALSE

/mob/living/simple_animal/hostile/humanoid/blood/fiend/wave/Leap(mob/living/target)
	if(!isliving(target) && !ismecha(target) || !can_act)
		return
	//Check if there's a wave barrier between us and target
	var/turf/target_turf = get_turf(target)
	for(var/turf/T in getline(src, target_turf))
		if(locate(/obj/structure/wave_barrier) in T.contents)
			return //Don't leap through barriers
	return ..()

/mob/living/simple_animal/hostile/humanoid/blood/fiend/boss/wave
	name = "royal bloodfiend"

/mob/living/simple_animal/hostile/humanoid/blood/fiend/boss/wave/ClearSky(turf/T)
	. = ..()
	if(.)
		if(locate(/obj/structure/wave_barrier) in T.contents)
			return FALSE

//Bloodbag doesn't need a variant - it doesn't dash
/mob/living/simple_animal/hostile/humanoid/blood/bag/wave
	name = "bloodbag"
	melee_damage_lower = 2
	melee_damage_upper = 3
	maxHealth = 300
	health = 300
