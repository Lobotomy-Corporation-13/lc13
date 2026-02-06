/mob/living/simple_animal/hostile/abnormality/mining/herald
	name = "herald"
	desc = "A monstrous beast which fires deadly projectiles at threats and prey."
	icon = 'icons/mob/lavaland/lavaland_elites.dmi'
	icon_state = "herald"
	icon_living = "herald"
	icon_dead = "herald_dying"
	icon_gib = "syndicate_gib"
	health_doll_icon = "herald"
	faction = list("boss")
	maxHealth = 1200
	health = 1200
	ranged = TRUE
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 0.8, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 2)
	melee_damage_type = RED_DAMAGE
	melee_damage_lower = 20
	melee_damage_upper = 20
	attack_verb_continuous = "preaches to"
	attack_verb_simple = "preach to"
	attack_sound = 'sound/magic/clockwork/ratvar_attack.ogg'
	speed = 2
	move_to_delay = 10
	mouse_opacity = MOUSE_OPACITY_ICON
	death_sound = 'sound/magic/demon_dies.ogg'
	death_message = "begins to shudder as it becomes transparent..."

	work_chances = list(
		ABNORMALITY_WORK_INSTINCT = list(80, 80, 50, 50, 50),
		ABNORMALITY_WORK_INSIGHT = 50,
		ABNORMALITY_WORK_ATTACHMENT = 30,
		ABNORMALITY_WORK_REPRESSION = 80
	)

	work_damage_amount = 7
	work_damage_type = RED_DAMAGE
	threat_level = HE_LEVEL
	start_qliphoth = 2
	can_breach = TRUE

	abnormality_origin = ABNORMALITY_ORIGIN_SS13MINING

	attack_action_types = list(/datum/action/innate/elite_attack/herald_trishot,
								/datum/action/innate/elite_attack/herald_directionalshot,
								/datum/action/innate/elite_attack/herald_teleshot,
								/datum/action/innate/elite_attack/herald_mirror)

	//Testing
	ego_list = list(
		/datum/ego_datum/weapon/galaxy,
		/datum/ego_datum/armor/galaxy,
	)

	var/mob/living/simple_animal/hostile/asteroid/elite/herald/mirror/my_mirror = null
	var/is_mirror = FALSE

/mob/living/simple_animal/hostile/abnormality/mining/herald/NeutralEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(40))
		datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/mining/herald/FailureEffect(mob/living/carbon/human/user, work_type, pe)
	. = ..()
	if(prob(80))
		datum_reference.qliphoth_change(-1)
	return


/mob/living/simple_animal/hostile/abnormality/mining/herald/death()
	. = ..()
	if(!is_mirror)
		addtimer(CALLBACK(src, PROC_REF(become_ghost)), 8)
	if(my_mirror != null)
		qdel(my_mirror)

/mob/living/simple_animal/hostile/abnormality/mining/herald/proc/become_ghost()
	icon_state = "herald_ghost"

/mob/living/simple_animal/hostile/abnormality/mining/herald/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	. = ..()
	playsound(get_turf(src), 'sound/magic/clockwork/invoke_general.ogg', 20, TRUE)

/datum/action/innate/elite_attack/herald_trishot
	name = "Triple Shot"
	button_icon_state = "herald_trishot"
	chosen_message = span_boldwarning("You are now firing three shots in your chosen direction.")
	chosen_attack_num = HERALD_TRISHOT

/datum/action/innate/elite_attack/herald_directionalshot
	name = "Circular Shot"
	button_icon_state = "herald_directionalshot"
	chosen_message = span_boldwarning("You are firing projectiles in all directions.")
	chosen_attack_num = HERALD_DIRECTIONALSHOT

/datum/action/innate/elite_attack/herald_teleshot
	name = "Teleport Shot"
	button_icon_state = "herald_teleshot"
	chosen_message = span_boldwarning("You will now fire a shot which teleports you where it lands.")
	chosen_attack_num = HERALD_TELESHOT

/datum/action/innate/elite_attack/herald_mirror
	name = "Summon Mirror"
	button_icon_state = "herald_mirror"
	chosen_message = span_boldwarning("You will spawn a mirror which duplicates your attacks.")
	chosen_attack_num = HERALD_MIRROR

/mob/living/simple_animal/hostile/abnormality/mining/herald/OpenFire()
	if(client)
		switch(chosen_attack)
			if(HERALD_TRISHOT)
				herald_trishot(target)
				if(my_mirror != null)
					my_mirror.herald_trishot(target)
			if(HERALD_DIRECTIONALSHOT)
				herald_directionalshot()
				if(my_mirror != null)
					my_mirror.herald_directionalshot()
			if(HERALD_TELESHOT)
				herald_teleshot(target)
				if(my_mirror != null)
					my_mirror.herald_teleshot(target)
			if(HERALD_MIRROR)
				herald_mirror()
		return
	var/aiattack = rand(1,4)
	switch(aiattack)
		if(HERALD_TRISHOT)
			herald_trishot(target)
			if(my_mirror != null)
				my_mirror.herald_trishot(target)
		if(HERALD_DIRECTIONALSHOT)
			herald_directionalshot()
			if(my_mirror != null)
				my_mirror.herald_directionalshot()
		if(HERALD_TELESHOT)
			herald_teleshot(target)
			if(my_mirror != null)
				my_mirror.herald_teleshot(target)
		if(HERALD_MIRROR)
			herald_mirror()

/mob/living/simple_animal/hostile/abnormality/mining/herald/proc/shoot_projectile(turf/marker, set_angle, is_teleshot, is_trishot)
	var/turf/startloc = get_turf(src)
	var/obj/projectile/heraldlc13/H = null
	if(!is_teleshot)
		H = new /obj/projectile/heraldlc13(startloc)
	else
		H = new /obj/projectile/heraldlc13/teleshot(startloc)
	H.preparePixelProjectile(marker, startloc)
	H.firer = src
	if(target)
		H.original = target
	H.fire(set_angle)
	if(is_trishot)
		shoot_projectile(marker, set_angle + 15, FALSE, FALSE)
		shoot_projectile(marker, set_angle - 15, FALSE, FALSE)

/mob/living/simple_animal/hostile/abnormality/mining/herald/proc/herald_trishot(target)
	ranged_cooldown = world.time + 30
	playsound(get_turf(src), 'sound/magic/clockwork/invoke_general.ogg', 20, TRUE)
	var/target_turf = get_turf(target)
	var/angle_to_target = Get_Angle(src, target_turf)
	shoot_projectile(target_turf, angle_to_target, FALSE, TRUE)
	addtimer(CALLBACK(src, PROC_REF(shoot_projectile), target_turf, angle_to_target, FALSE, TRUE), 2)
	addtimer(CALLBACK(src, PROC_REF(shoot_projectile), target_turf, angle_to_target, FALSE, TRUE), 4)
	if(health < maxHealth * 0.5 && !is_mirror)
		playsound(get_turf(src), 'sound/magic/clockwork/invoke_general.ogg', 20, TRUE)
		addtimer(CALLBACK(src, PROC_REF(shoot_projectile), target_turf, angle_to_target, FALSE, TRUE), 10)
		addtimer(CALLBACK(src, PROC_REF(shoot_projectile), target_turf, angle_to_target, FALSE, TRUE), 12)
		addtimer(CALLBACK(src, PROC_REF(shoot_projectile), target_turf, angle_to_target, FALSE, TRUE), 14)

/mob/living/simple_animal/hostile/abnormality/mining/herald/proc/herald_circleshot(offset)
	var/static/list/directional_shot_angles = list(0, 45, 90, 135, 180, 225, 270, 315)
	for(var/i in directional_shot_angles)
		shoot_projectile(get_turf(src), i + offset, FALSE, FALSE)

/mob/living/simple_animal/hostile/abnormality/mining/herald/proc/unenrage()
	if(stat == DEAD || is_mirror)
		return
	icon_state = "herald"

/mob/living/simple_animal/hostile/abnormality/mining/herald/proc/herald_directionalshot()
	ranged_cooldown = world.time + 3 SECONDS
	if(!is_mirror)
		icon_state = "herald_enraged"
	playsound(get_turf(src), 'sound/magic/clockwork/invoke_general.ogg', 20, TRUE)
	addtimer(CALLBACK(src, PROC_REF(herald_circleshot), 0), 5)
	if(health < maxHealth * 0.5 && !is_mirror)
		playsound(get_turf(src), 'sound/magic/clockwork/invoke_general.ogg', 20, TRUE)
		addtimer(CALLBACK(src, PROC_REF(herald_circleshot), 22.5), 15)
	addtimer(CALLBACK(src, PROC_REF(unenrage)), 20)

/mob/living/simple_animal/hostile/abnormality/mining/herald/proc/herald_teleshot(target)
	ranged_cooldown = world.time + 30
	playsound(get_turf(src), 'sound/magic/clockwork/invoke_general.ogg', 20, TRUE)
	var/target_turf = get_turf(target)
	var/angle_to_target = Get_Angle(src, target_turf)
	shoot_projectile(target_turf, angle_to_target, TRUE, FALSE)

/mob/living/simple_animal/hostile/abnormality/mining/herald/proc/herald_mirror()
	ranged_cooldown = world.time + 4 SECONDS
	playsound(get_turf(src), 'sound/magic/clockwork/invoke_general.ogg', 20, TRUE)
	if(my_mirror != null)
		qdel(my_mirror)
		my_mirror = null
	var/mob/living/simple_animal/hostile/abnormality/mining/herald/mirror/new_mirror = new /mob/living/simple_animal/hostile/abnormality/mining/herald/mirror(loc)
	my_mirror = new_mirror
	my_mirror.my_master = src
	my_mirror.faction = faction.Copy()


//Here's the other stuff

/mob/living/simple_animal/hostile/abnormality/mining/herald/mirror
	name = "herald's mirror"
	desc = "This fiendish work of magic copies the herald's attacks.  Seems logical to smash it."
	health = 60
	maxHealth = 60
	icon_state = "herald_mirror"
	death_message = "shatters violently!"
	death_sound = 'sound/effects/glassbr1.ogg'
	is_flying_animal = TRUE
	del_on_death = TRUE
	is_mirror = TRUE
	var/mob/living/simple_animal/hostile/abnormality/mining/herald/my_master = null
	abnormality_origin = ABNORMALITY_DUMMY	///Wuh oh
	core_enabled = FALSE

/mob/living/simple_animal/hostile/abnormality/mining/herald/mirror/Initialize()
	. = ..()
	toggle_ai(AI_OFF)

/mob/living/simple_animal/hostile/abnormality/mining/herald/mirror/Destroy()
	if(my_master != null)
		my_master.my_mirror = null
	. = ..()

/obj/projectile/heraldlc13
	name ="death bolt"
	icon_state= "chronobolt"
	damage = 30
	speed = 2
	eyeblur = 0
	damage_type = BLACK_DAMAGE
	pass_flags = PASSTABLE

/obj/projectile/heraldlc13/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(isliving(target))
		var/mob/living/L = target
		var/mob/living/F = firer
		if(F != null && istype(F, /mob/living/simple_animal/hostile/abnormality/mining) && F.faction_check_mob(L))
			L.heal_overall_damage(damage)

/obj/projectile/heraldlc13/teleshot13
	name ="golden bolt"
	damage = 0
	color = rgb(255,255,102)

/obj/projectile/heraldlc13/teleshot/on_hit(atom/target, blocked = FALSE)
	. = ..()
	firer.forceMove(get_turf(src))
