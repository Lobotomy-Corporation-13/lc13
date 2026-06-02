/*
 * Per-mob achievement framework. Each line declares its achievements via
 * GetMobAchievements() (same authoring shape as GetMobPassives /
 * GetMobAttacks), bound to a specific mob path. The subsystem merges all
 * lines' contributions into:
 *   - SSrefraction_railway.mob_achievements[mob_path] = list of entries
 *   - SSrefraction_railway.achievements_by_id[id] = entry
 *
 * Each entry is an assoc list with these keys:
 *   - "id"            unique-across-all-lines string key
 *   - "name"          player-facing display name
 *   - "desc"          one-line description of the criterion
 *   - "reward"        Starlight bonus on success (int)
 *   - "default_state" TRUE = "avoid X" (passes by default, flip to FALSE
 *                     on the failing event); FALSE = "do X" (defaults to
 *                     not earned, flip to TRUE on the qualifying event)
 *
 * Per-run state lives on the /datum/refraction_run as `achievement_state`
 * (ckey → id → TRUE/FALSE). At run complete, AwardStarlightProgression
 * folds the matched rewards into the final SL grant.
 */

/// Override in subtypes to declare per-mob achievements:
///   mob_path = list( list("id"=…, "name"=…, …), … )
/datum/refraction_line/proc/GetMobAchievements()
	return list()
