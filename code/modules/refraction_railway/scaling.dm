/*
 * Per-room mob scaling for refraction railway. Constants here so they can be
 * tuned in one place; called from the run datum's room-activation hook.
 *
 *  HP   multiplier: 1 + 0.20 * (n - 1)
 *  Dmg  multiplier: 1 + 0.10 * (n - 1)
 *
 * Wave reserve scaling is handled by WAVE_MOBS_PER_PLAYER inside the wave
 * controller; this file does not duplicate it.
 */

#define REFRACTION_HP_PER_EXTRA_PLAYER         0.20
#define REFRACTION_DMG_PER_EXTRA_PLAYER        0.10
#define REFRACTION_STOCK_PER_EXTRA_PLAYER      0.20
#define REFRACTION_CONCURRENT_PER_EXTRA_PLAYER 0.20

/// Returns the HP multiplier for a given lobby size (n >= 1).
/proc/refraction_hp_mult(num_players)
	return 1 + REFRACTION_HP_PER_EXTRA_PLAYER * max(0, num_players - 1)

/// Returns the damage multiplier for a given lobby size (n >= 1).
/proc/refraction_damage_mult(num_players)
	return 1 + REFRACTION_DMG_PER_EXTRA_PLAYER * max(0, num_players - 1)

/// Returns the per-mob-type stock multiplier for a given lobby size.
/// Authored stock (1-player baseline) is multiplied by this at activation.
/proc/refraction_stock_mult(num_players)
	return 1 + REFRACTION_STOCK_PER_EXTRA_PLAYER * max(0, num_players - 1)

/// Returns the concurrent-cap multiplier for a given lobby size. Mirrors the
/// stock multiplier so authored `concurrent_max` reflects the 1-player
/// baseline; larger lobbies see proportionally more mobs at once. Bosses
/// skip this (see wave_system.dm) so their authored cap is honored exactly.
/proc/refraction_concurrent_mult(num_players)
	return 1 + REFRACTION_CONCURRENT_PER_EXTRA_PLAYER * max(0, num_players - 1)

/// Scales the given hostile mob's HP and melee damage by the lobby-size multipliers.
/// Ability damage and other custom hooks are out of scope for this helper.
/proc/refraction_scale_hostile(mob/living/simple_animal/hostile/H, num_players)
	if(!istype(H) || num_players <= 1)
		return
	var/hp_mult = refraction_hp_mult(num_players)
	var/dmg_mult = refraction_damage_mult(num_players)
	var/new_max = round(H.maxHealth * hp_mult)
	H.maxHealth = new_max
	H.health = new_max
	H.melee_damage_lower = round(H.melee_damage_lower * dmg_mult)
	H.melee_damage_upper = round(H.melee_damage_upper * dmg_mult)
