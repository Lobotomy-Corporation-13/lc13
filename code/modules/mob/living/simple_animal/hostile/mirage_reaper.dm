/// Mirage Reaper - Hostile mob spawned during Achiyalabopa's storm
/mob/living/simple_animal/hostile/mirage_reaper
	name = "Mirage Reaper"
	desc = "A feathery entity that materializes from the dark storm."
	icon = 'ModularLobotomy/_Lobotomyicons/bird_reaper.dmi'
	icon_state = "reaper1"
	icon_living = "reaper1"
	icon_dead = "reaper1_dead"
	maxHealth = 300
	health = 300
	melee_damage_lower = 14
	melee_damage_upper = 20
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.5)
	melee_damage_type = BLACK_DAMAGE
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	move_to_delay = 4
	vision_range = 10
	aggro_vision_range = 15
	attack_verb_continuous = "strikes"
	attack_verb_simple = "strike"
	attack_sound = 'sound/creatures/lc13/lovetown/slam.ogg'
	death_sound = 'sound/effects/ghost.ogg'
	emote_hear = list("echoes", "screeches")
	speak_chance = 5
	speed = 2
	del_on_death = TRUE
	can_patrol = TRUE
	patrol_cooldown_time = 30 SECONDS

/mob/living/simple_animal/hostile/mirage_reaper/patrol_select()
	if(!GLOB.mirage_reaper_spawns || !length(GLOB.mirage_reaper_spawns))
		return

	// Pick a random landmark to patrol to
	var/obj/effect/landmark/mirage_reaper_spawn/target = pick(GLOB.mirage_reaper_spawns)
	if(!target)
		return

	patrol_path = get_path_to(src, get_turf(target), /turf/proc/Distance_cardinal, 0, 200)

/// Gwyliwr Nos - Placeholder for existing mob reference (if it doesn't exist, create basic version)
/mob/living/simple_animal/hostile/gwyliwr_nos
	name = "Gwyliwr Nos"
	desc = "A night watcher, enhanced by the dark storm."
	icon = 'ModularLobotomy/_Lobotomyicons/bird_gwyliwr.dmi'
	icon_state = "gwyliwr_nos"
	icon_living = "gwyliwr_nos"
	icon_dead = "gwyliwr_nos_dead"
	maxHealth = 2400
	health = 2400
	pixel_x = -16
	base_pixel_x = -16
	melee_damage_lower = 30
	melee_damage_upper = 45
	damage_coeff = list(RED_DAMAGE = 0.9, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 1.3)
	melee_damage_type = WHITE_DAMAGE
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	move_to_delay = 3
	vision_range = 12
	aggro_vision_range = 18
	attack_verb_continuous = "strikes"
	attack_verb_simple = "strike"
	attack_sound = 'sound/weapons/punch1.ogg'
	death_sound = 'sound/effects/ghost2.ogg'
	del_on_death = TRUE
	blood_volume = 0
