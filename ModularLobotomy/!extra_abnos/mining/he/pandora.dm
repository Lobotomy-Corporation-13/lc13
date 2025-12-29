/mob/living/simple_animal/hostile/abnormality/mining/pandora
	name = "pandora"
	desc = "A large magic box with similar power and design to the Hierophant.  Once it opens, it's not easy to close it."
	icon_state = "pandora"
	icon_living = "pandora"
	icon_dead = "pandora_dead"
	icon_gib = "syndicate_gib"
	health_doll_icon = "pandora"
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 1, PALE_DAMAGE = 1.5)
	maxHealth = 1200
	health = 1200
	melee_damage_lower = 35
	melee_damage_upper = 35
	melee_damage_type = RED_DAMAGE
	attack_verb_continuous = "smashes into the side of"
	attack_verb_simple = "smash into the side of"
	attack_sound = 'sound/weapons/sonic_jackhammer.ogg'
	speed = 3
	move_to_delay = 4
	minimum_distance = 4
	can_breach = TRUE
	start_qliphoth = 2
	mouse_opacity = MOUSE_OPACITY_ICON
	death_sound = 'sound/magic/repulse.ogg'
	death_message = "'s lights flicker, before its top part falls down."

	attack_action_types = list(/datum/action/innate/elite_attack/singular_shot,
								/datum/action/innate/elite_attack/magic_box,
								/datum/action/innate/elite_attack/pandora_teleport,
								/datum/action/innate/elite_attack/aoe_squares)

	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(30, 30, 40, 50, 50),
		ABNORMALITY_WORK_INSIGHT = list(20, 20, 20, 30, 30),
		ABNORMALITY_WORK_ATTACHMENT = list(50, 50, 70, 70, 70),
		ABNORMALITY_WORK_REPRESSION = list(20, 20, 10, 10, 10),
	)
	threat_level = HE_LEVEL
	work_damage_amount = 7
	work_damage_type = BLACK_DAMAGE
	//Testing
	ego_list = list(
		/datum/ego_datum/weapon/galaxy,
		/datum/ego_datum/armor/galaxy,
	)

	var/sing_shot_length = 8
	var/cooldown_time = 20


/mob/living/simple_animal/hostile/abnormality/mining/pandora/NeutralEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(40))
		datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/mining/pandora/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(80))
		datum_reference.qliphoth_change(-1)
	return

/datum/action/innate/elite_attack/singular_shot
	name = "Singular Shot"
	button_icon_state = "singular_shot"
	chosen_message = span_boldwarning("You are now creating a single linear magic square.")
	chosen_attack_num = SINGULAR_SHOT

/datum/action/innate/elite_attack/magic_box
	name = "Magic Box"
	button_icon_state = "magic_box"
	chosen_message = span_boldwarning("You are now attacking with a box of magic squares.")
	chosen_attack_num = MAGIC_BOX

/datum/action/innate/elite_attack/pandora_teleport
	name = "Line Teleport"
	button_icon_state = "pandora_teleport"
	chosen_message = span_boldwarning("You will now teleport to your target.")
	chosen_attack_num = PANDORA_TELEPORT

/datum/action/innate/elite_attack/aoe_squares
	name = "AOE Blast"
	button_icon_state = "aoe_squares"
	chosen_message = span_boldwarning("Your attacks will spawn an AOE blast at your target location.")
	chosen_attack_num = AOE_SQUARES

/mob/living/simple_animal/hostile/abnormality/mining/pandora/OpenFire()
	if(client)
		switch(chosen_attack)
			if(SINGULAR_SHOT)
				singular_shot(target)
			if(MAGIC_BOX)
				magic_box(target)
			if(PANDORA_TELEPORT)
				pandora_teleport(target)
			if(AOE_SQUARES)
				aoe_squares(target)
		return
	var/aiattack = rand(1,4)
	switch(aiattack)
		if(SINGULAR_SHOT)
			singular_shot(target)
		if(MAGIC_BOX)
			magic_box(target)
		if(PANDORA_TELEPORT)
			pandora_teleport(target)
		if(AOE_SQUARES)
			aoe_squares(target)

/mob/living/simple_animal/hostile/abnormality/mining/pandora/Life()
	. = ..()
	if(health >= maxHealth * 0.5)
		cooldown_time = 2 SECONDS
		return
	if(health < maxHealth * 0.5 && health > maxHealth * 0.25)
		cooldown_time = 1.5 SECONDS
		return
	else
		cooldown_time = 1 SECONDS

/mob/living/simple_animal/hostile/abnormality/mining/pandora/proc/singular_shot(target)
	ranged_cooldown = world.time + (cooldown_time * 0.5)
	var/dir_to_target = get_dir(get_turf(src), get_turf(target))
	var/turf/T = get_step(get_turf(src), dir_to_target)
	singular_shot_line(sing_shot_length, dir_to_target, T)

/mob/living/simple_animal/hostile/abnormality/mining/pandora/proc/singular_shot_line(procsleft, angleused, turf/T)
	if(procsleft <= 0)
		return
	new /obj/effect/temp_visual/hierophant/blast/damaging/pandora/lc13(T, src)
	T = get_step(T, angleused)
	procsleft = procsleft - 1
	addtimer(CALLBACK(src, PROC_REF(singular_shot_line), procsleft, angleused, T), cooldown_time * 0.1)

/mob/living/simple_animal/hostile/abnormality/mining/pandora/proc/magic_box(target)
	ranged_cooldown = world.time + cooldown_time
	var/turf/T = get_turf(target)
	for(var/t in spiral_range_turfs(3, T))
		if(get_dist(t, T) > 1)
			new /obj/effect/temp_visual/hierophant/blast/damaging/pandora/lc13(t, src)

/mob/living/simple_animal/hostile/abnormality/mining/pandora/proc/pandora_teleport(target)
	var/turf/turf_target = get_turf(target)
	if(!(turf_target in view(12, src)))
		return
	ranged_cooldown = world.time + (cooldown_time * 2)
	var/turf/source = get_turf(src)
	new /obj/effect/temp_visual/hierophant/telegraph(turf_target, src)
	new /obj/effect/temp_visual/hierophant/telegraph(source, src)
	playsound(source,'sound/machines/airlockopen.ogg', 200, 1)
	addtimer(CALLBACK(src, PROC_REF(pandora_teleport_2), turf_target, source), 2)

/mob/living/simple_animal/hostile/abnormality/mining/pandora/proc/pandora_teleport_2(turf/T, turf/source)
	new /obj/effect/temp_visual/hierophant/telegraph/teleport(T, src)
	new /obj/effect/temp_visual/hierophant/telegraph/teleport(source, src)
	for(var/t in RANGE_TURFS(1, T))
		new /obj/effect/temp_visual/hierophant/blast/damaging/pandora/lc13(t, src)
	for(var/t in RANGE_TURFS(1, source))
		new /obj/effect/temp_visual/hierophant/blast/damaging/pandora/lc13(t, src)
	animate(src, alpha = 0, time = 2, easing = EASE_OUT) //fade out
	visible_message(span_hierophant_warning("[src] fades out!"))
	density = FALSE
	addtimer(CALLBACK(src, PROC_REF(pandora_teleport_3), T), 2)

/mob/living/simple_animal/hostile/abnormality/mining/pandora/proc/pandora_teleport_3(turf/T)
	forceMove(T)
	animate(src, alpha = 255, time = 2, easing = EASE_IN) //fade IN
	density = TRUE
	visible_message(span_hierophant_warning("[src] fades in!"))

/mob/living/simple_animal/hostile/abnormality/mining/pandora/proc/aoe_squares(target)
	ranged_cooldown = world.time + cooldown_time
	var/turf/T = get_turf(target)
	new /obj/effect/temp_visual/hierophant/blast/damaging/pandora/lc13(T, src)
	var/max_size = 3
	addtimer(CALLBACK(src, PROC_REF(aoe_squares_2), T, 0, max_size), 2)

/mob/living/simple_animal/hostile/abnormality/mining/pandora/proc/aoe_squares_2(turf/T, ring, max_size)
	if(ring > max_size)
		return
	for(var/t in spiral_range_turfs(ring, T))
		if(get_dist(t, T) == ring)
			new /obj/effect/temp_visual/hierophant/blast/damaging/pandora/lc13(t, src)
	addtimer(CALLBACK(src, PROC_REF(aoe_squares_2), T, (ring + 1), max_size), cooldown_time * 0.1)

//The specific version of hiero's squares pandora uses
/obj/effect/temp_visual/hierophant/blast/damaging/pandora/lc13
	damtype = BLACK_DAMAGE
