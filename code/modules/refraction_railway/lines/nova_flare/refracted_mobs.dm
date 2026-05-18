/*
 * Nova Flare — refracted Sector 1 mobs.
 *
 * "Refracted" subtypes of base-game mobs, tuned for the Nova Flare line's
 * solo 80-stat player profile. Base mobs are left untouched so non-railway
 * content keeps its original balance. Player-facing briefing text for these
 * lives in passives.dm and attacks.dm.
 */

// ---------- Mi-Go (Node 1: "The Gap") ----------
// Health and damage only. Inherits the parent wail (WHITE), insane-melee
// PALE, disabled teleport, damage_coeff, rapid_melee, speed and icons.

/mob/living/simple_animal/hostile/netherworld/migo/refracted
	name = "drifting thing"
	desc = "Something the line let through. It does not belong in any of the directions you can point."
	maxHealth = 110
	health = 110
	scream_damage = 6

// ---------- Mutant Clowns (Node 2: "The Family") ----------
// Two-stage mask-break kept (rebalanced down). Scream keeps its WHITE hit
// and additionally leaves humans RED Fragile.

/mob/living/simple_animal/hostile/mutant_clown/refracted
	name = "'Son'"
	desc = "A survivor the blast did not finish. It still wears the face it had."
	maxHealth = 320
	health = 320
	melee_damage_lower = 10
	melee_damage_upper = 16
	scream_damage = 16
	scream_cooldown_time = 6 SECONDS
	move_to_delay = 16
	move_speed_maskbreak = 7
	retreat_distance = 6
	minimum_distance = 6
	// Refracted mobs are disposable — no human corpse on death and no
	// mask-break gibspawner (handled in BreakMask override below).
	loot = list()
	/// RED Fragile stacks applied to each human caught in a Scream.
	var/scream_fragile_stacks = 2
	/// Mask breaks once health drops to this fraction of maxHealth.
	var/maskbreak_threshold = 0.5

/mob/living/simple_animal/hostile/mutant_clown/refracted/Initialize(mapload)
	. = ..()
	if(type == /mob/living/simple_animal/hostile/mutant_clown/refracted)
		name = pick("'Son'", "'Father'")

/mob/living/simple_animal/hostile/mutant_clown/refracted/Scream()
	..()
	for(var/mob/living/carbon/human/H in view(7, src))
		if(!faction_check_mob(H))
			H.apply_lc_red_fragile(scream_fragile_stacks)

// The parent fires BreakMask() at a hardcoded 50% HP. Drive it at
// maskbreak_threshold instead: trigger here (handles thresholds above
// 50%, which the parent's 50% check is too late for) and gate the parent's
// own call so it can't break early or twice.
/mob/living/simple_animal/hostile/mutant_clown/refracted/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(current_stage == 1 && health <= (maxHealth * maskbreak_threshold))
		BreakMask()

// Inlined copy of the parent BreakMask() minus the gibspawner spawn so
// refracted mobs leave no remains. Kept in sync with
// /mob/living/simple_animal/hostile/mutant_clown/BreakMask().
/mob/living/simple_animal/hostile/mutant_clown/refracted/BreakMask()
	if(current_stage != 1)
		return
	if(health > (maxHealth * maskbreak_threshold))
		return
	can_act = FALSE
	icon_living = icon_state + "_unmasked"
	icon_state = icon_living
	desc += "Now with their mask broken... You can see their mutated face."
	current_stage = 2
	retreat_distance = 0
	minimum_distance = 0
	say(maskbreak_say_1)
	move_to_delay = move_speed_maskbreak
	UpdateSpeed()
	playsound(get_turf(src), 'sound/creatures/lc13/lovetown/scream.ogg', 50, TRUE, 3)
	ChangeResistances(list(RED_DAMAGE = 0.2, WHITE_DAMAGE = 0.2, BLACK_DAMAGE = 0.2, PALE_DAMAGE = 0.2))
	SLEEP_CHECK_DEATH(25)
	ChangeResistances(list(BRUTE = 1, RED_DAMAGE = 1.6, WHITE_DAMAGE = 0.6, BLACK_DAMAGE = 0.8, PALE_DAMAGE = 2))
	say(maskbreak_say_2)
	can_act = TRUE

/mob/living/simple_animal/hostile/mutant_clown/refracted/sister
	name = "'Sister'"
	desc = "Lighter than the others. It keeps its distance and screams instead."
	icon_state = "pie spewer"
	icon_living = "pie spewer"
	maxHealth = 150
	health = 150
	melee_damage_lower = 8
	melee_damage_upper = 12
	move_to_delay = 14
	retreat_distance = 8
	minimum_distance = 8
	scream_fragile_stacks = 5
	maskbreak_threshold = 0.25

/mob/living/simple_animal/hostile/mutant_clown/refracted/mother
	name = "'Mother?'"
	desc = "Too large to have survived intact. It does not retreat."
	icon_state = "glutton"
	icon_living = "glutton"
	base_pixel_x = -16
	pixel_x = -16
	maxHealth = 460
	health = 460
	melee_damage_lower = 14
	melee_damage_upper = 22
	move_to_delay = 22
	move_speed_maskbreak = 10
	scream_damage = 22
	scream_cooldown_time = 7 SECONDS
	retreat_distance = 0
	minimum_distance = 0
	maskbreak_threshold = 0.75
