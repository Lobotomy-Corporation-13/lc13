// --------- SHRIMP DUNGEON ENEMIES ---------
// --------- (badly) MADE BY XEROS  ---------

//Original enemies

/mob/living/simple_animal/hostile/shrimp_security
	name = "wellcheers corp security officer"
	desc = "A security officer who happens to also be a shrimp. Packs a mean tackle and rocks a pair of sunglasses."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "wellcheers_sec"
	icon_living = "wellcheers_sec"
	icon_dead = "wellcheers_sec_dead"
	faction = list("hostile") //Not fooled by the shrimp injector
	health = 1200
	maxHealth = 1200
	melee_damage_type = RED_DAMAGE
	damage_coeff = list(RED_DAMAGE = 0.8, WHITE_DAMAGE = 1.5, BLACK_DAMAGE = 1, PALE_DAMAGE = 2)
	melee_damage_lower = 16
	move_to_delay = 4.5
	melee_damage_upper = 20
	robust_searching = TRUE
	stat_attack = HARD_CRIT
	del_on_death = TRUE
	attack_verb_continuous = "bashes"
	attack_verb_simple = "bashes"
	attack_sound = 'sound/effects/meteorimpact.ogg'
	speak_emote = list("burbles")
	butcher_results = list(/obj/item/stack/spacecash/c100 = 1, /obj/item/stack/spacecash/c50 = 1)
	silk_results = list(/obj/item/stack/sheet/silk/shrimple_simple = 12, /obj/item/stack/sheet/silk/shrimple_advanced = 6)




//Modified enemies

/mob/living/simple_animal/hostile/shrimp/dungeon
	name = "wellcheers corp dock worker"
	faction = list("hostile") //Not fooled by the shrimp injector

/mob/living/simple_animal/hostile/senior_shrimp/dungeon
	name = "wellcheers corp senior hauler"
	faction = list("hostile") //Also not fooled by the shrimp injector

/mob/living/simple_animal/hostile/shrimp_soldier/dungeon
	name = "wellcheers corp senior security"
	faction = list("hostile") //Shrimp injector might not work on them
