/**
 * Resurgence Outpost - Character Stats System
 *
 * Defines stat helper procs and formulas for the three core stats:
 * - Construction: Affects building speed and beauty of built structures
 * - Crafting: Affects crafting speed and beauty of crafted items
 * - Gathering: Affects gathering speed and resource yield
 *
 * Stats range from 1-20. Level 1 has no speed/yield penalties, only beauty penalties.
 * Higher levels provide bonuses.
 */

/// Base XP required for level 1->2 (increases by 100 each level)
#define STAT_XP_BASE 100

// STAT_MAX_LEVEL is in _resurgence_defines.dm

/**
 * Get the speed modifier for a stat level.
 * Level 1 = 1.0x time (normal, no penalty)
 * Level 20 = 0.5x time (50% faster)
 *
 * Arguments:
 * * level - The stat level (1-20)
 *
 * Returns: Speed multiplier (lower = faster)
 */
/proc/get_stat_speed_modifier(level)
	level = clamp(level, 1, STAT_MAX_LEVEL)
	// Level 1 = 1.0, Level 20 = 0.5
	return 1.0 - (level - 1) * (0.5 / 19)

/**
 * Get the yield modifier for gathering stat level.
 * Level 1 = 1.0x yield (normal, no penalty)
 * Level 20 = 1.5x yield (50% more)
 *
 * Arguments:
 * * level - The stat level (1-20)
 *
 * Returns: Yield multiplier (higher = more resources)
 */
/proc/get_stat_yield_modifier(level)
	level = clamp(level, 1, STAT_MAX_LEVEL)
	// Level 1 = 1.0, Level 20 = 1.5
	return 1.0 + (level - 1) * (0.5 / 19)

/**
 * Get the beauty bonus for a stat level.
 * Level 1 = -2 beauty (penalty for unskilled work)
 * Level 10 = 0 beauty
 * Level 20 = +5 beauty
 *
 * Arguments:
 * * level - The stat level (1-20)
 *
 * Returns: Beauty bonus (integer)
 */
/proc/get_stat_beauty_bonus(level)
	level = clamp(level, 1, STAT_MAX_LEVEL)
	return round(-2 + (level - 1) * (7.0 / 19))

/**
 * Get the XP required to reach the next level.
 * XP doubles every 5 levels:
 * - Levels 1-5: 100 XP each
 * - Levels 6-10: 200 XP each
 * - Levels 11-15: 400 XP each
 * - Levels 16-20: 800 XP each
 *
 * This formula works correctly regardless of starting level
 * (e.g., starting at level 5 means level 6 needs 200 XP).
 *
 * Arguments:
 * * level - The current stat level (1-19)
 *
 * Returns: XP required for next level
 */
/proc/get_xp_for_level(level)
	if(level >= STAT_MAX_LEVEL)
		return 0 // Already max level
	level = clamp(level, 1, STAT_MAX_LEVEL - 1)
	// XP doubles every 5 levels: 100 -> 200 -> 400 -> 800
	var/tier = round((level - 1) / 5) // 0 for levels 1-5, 1 for 6-10, 2 for 11-15, 3 for 16-20
	return STAT_XP_BASE * (2 ** tier) // 100, 200, 400, 800
