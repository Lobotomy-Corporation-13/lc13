// Refraction Railway — per-mob achievements, mirrored as standard
// LC13 medals so they show up in the player's profile / achievements
// HUD alongside the rest of the LC13 awards. The railway's own
// in-run `achievement_state` plumbing still drives the Starlight
// bonus; this layer is purely cosmetic / record-keeping.
//
// Granted by `AwardStarlightProgression` in
// `code/modules/refraction_railway/run_datum.dm` when an
// achievement resolves TRUE at run completion. Each Nova Flare
// `GetMobAchievements()` entry carries an `"award"` field pointing
// to one of the subtypes below.
//
// Add new entries here when authoring new railway achievements
// in `lines/<line>/achievements.dm`. Keep `database_id` keyed off a
// `MEDAL_REFRACTION_*` define in `code/__DEFINES/achievements.dm`.

/datum/award/achievement/lc13/refraction
	category = "LobotomyCorp/RefractionRailway"
	icon = "refraction"

// ---------- Nova Flare ----------

/datum/award/achievement/lc13/refraction/rose_no_high_bleed
	name = "Stay Unbled"
	desc = "Cleared the Scarlet Rose without anyone crossing 40 Bleed stacks."
	title = "Pristine"
	database_id = MEDAL_REFRACTION_ROSE_NO_HIGH_BLEED
	difficulty = ACHIEVEMENT_HARD

/datum/award/achievement/lc13/refraction/guard_no_black_swap
	name = "Restraint"
	desc = "Survived the Stone Guard without taking a single Tremor-fueled BLACK strike."
	title = "Restrained"
	database_id = MEDAL_REFRACTION_GUARD_NO_BLACK_SWAP
	difficulty = ACHIEVEMENT_NORMAL

/datum/award/achievement/lc13/refraction/swarm_let_burrow
	name = "Welcoming Host"
	desc = "Let a refracted swarm burrow into you, willingly."
	title = "the Host"
	database_id = MEDAL_REFRACTION_SWARM_LET_BURROW
	difficulty = ACHIEVEMENT_EASY

/datum/award/achievement/lc13/refraction/grandfather_no_meat_hit
	name = "Untouched by Flesh"
	desc = "Cleared the Grandfather without taking a single meat-drop hit."
	title = "Untouched"
	database_id = MEDAL_REFRACTION_GRANDFATHER_NO_MEAT_HIT
	difficulty = ACHIEVEMENT_HARD

/datum/award/achievement/lc13/refraction/grandfather_calm
	name = "Calm Patriarch"
	desc = "Kept the Grandfather from summoning more than three reinforcements."
	title = "the Patriarch's Match"
	database_id = MEDAL_REFRACTION_GRANDFATHER_CALM
	difficulty = ACHIEVEMENT_EASY

/datum/award/achievement/lc13/refraction/drone_no_emergency_heal
	name = "No Repairs Needed"
	desc = "Killed the Clan Drone before it triggered its emergency heal."
	title = "Drone-Buster"
	database_id = MEDAL_REFRACTION_DRONE_NO_EMERGENCY_HEAL
	difficulty = ACHIEVEMENT_NORMAL

/datum/award/achievement/lc13/refraction/harpooner_no_proximity_break
	name = "Untethered"
	desc = "Beat the Harpooner without anyone breaking its chain by approach or timeout."
	title = "Untethered"
	database_id = MEDAL_REFRACTION_HARPOONER_NO_PROX_BREAK
	difficulty = ACHIEVEMENT_NORMAL

/datum/award/achievement/lc13/refraction/keeper_no_mine_hit
	name = "Mineless"
	desc = "Survived the Stone Keeper without taking damage from a single mine."
	title = "Mineless"
	database_id = MEDAL_REFRACTION_KEEPER_NO_MINE_HIT
	difficulty = ACHIEVEMENT_NORMAL

/datum/award/achievement/lc13/refraction/keeper_kill_pillar
	name = "Topple the Pillar"
	desc = "Destroyed one of the Stone Keeper's pillars before the boss itself died."
	title = "Pillar-Toppler"
	database_id = MEDAL_REFRACTION_KEEPER_KILL_PILLAR
	difficulty = ACHIEVEMENT_NORMAL

/datum/award/achievement/lc13/refraction/keeper_no_mine_swarm
	name = "Mine Hoarder"
	desc = "Held the Stone Keeper's mine field under 20 simultaneous mines."
	title = "Mine Hoarder"
	database_id = MEDAL_REFRACTION_KEEPER_NO_MINE_SWARM
	difficulty = ACHIEVEMENT_HARD
