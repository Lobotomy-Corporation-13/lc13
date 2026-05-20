/*
 * Curtain Call — Sector 1 encounters.
 *
 * Node zeal_s1n1 (Opening Act, scene 1): a duo fight — a Thumb East Capo
 * and their pet Capo Rat. The pair shares a faction so they ignore each
 * other and focus the players.
 *
 * Gimmick details are pending — the stats below are placeholders sized
 * roughly for a mid-tier (atb 90) first-sector boss and will be retuned
 * alongside the encounter's real mechanics.
 */

// ---------- Thumb East Capo (Node zeal_s1n1: boss) ----------
/mob/living/simple_animal/hostile/thumb_east_capo
	name = "Thumb East Capo"
	desc = "A capo of the Thumb East family, dressed for an audience. \
		They are not here for the line — only for the show."
	icon = 'ModularLobotomy/_Lobotomyicons/teaser_mobs.dmi'
	icon_state = "capo_boss"
	icon_living = "capo_boss"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	faction = list("thumb_east")
	maxHealth = 900
	health = 900
	melee_damage_lower = 15
	melee_damage_upper = 20
	melee_damage_type = RED_DAMAGE
	attack_verb_continuous = "strikes"
	attack_verb_simple = "strike"
	attack_sound = 'sound/weapons/punch1.ogg'
	speak_chance = 0
	turns_per_move = 5
	move_to_delay = 6
	stat_attack = HARD_CRIT
	robust_searching = TRUE
	damage_coeff = list(RED_DAMAGE = 1, WHITE_DAMAGE = 1, BLACK_DAMAGE = 1, PALE_DAMAGE = 1)
	del_on_death = TRUE
	loot = list()

/mob/living/simple_animal/hostile/thumb_east_capo/refracted
	// Refraction Railway tuning of the Capo. Currently identical to base;
	// stats / gimmick will diverge here as the encounter is authored.

// ---------- Capo Rat (Node zeal_s1n1: pet) ----------
// Subtype of the base back-alley rat: keeps the gray mouse sprite (rendered
// bright red via `color`), shares the Capo's faction so they don't fight
// each other, and bumps stats so it survives more than a single hit.
/mob/living/simple_animal/hostile/rat/capo_rat
	name = "Capo Rat"
	desc = "Larger than a back-alley rat, dyed red where the Capo's coat \
		brushes it. Stays close to its handler."
	color = "#ff3030"
	faction = list("thumb_east")
	maxHealth = 200
	health = 200
	melee_damage_lower = 8
	melee_damage_upper = 12
	move_to_delay = 4
	del_on_death = TRUE
	loot = list()
	butcher_results = null

// Skip the base rat's deadmouse-food spawn on death — the railway prefers
// a clean room. Parent still handles SSmobs.cheeserats removal.
/mob/living/simple_animal/hostile/rat/capo_rat/death(gibbed)
	SSmobs.cheeserats -= src
	return ..(gibbed = TRUE)

/mob/living/simple_animal/hostile/rat/capo_rat/refracted
	// Refraction Railway tuning of the pet rat. Currently identical to
	// base; stats / gimmick will diverge here as the encounter is authored.
