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

// ---------- Retroactive ----------

/datum/award/achievement/lc13/refraction/curtain_call_pre_patch
	name = "Before the Patch"
	desc = "Cleared Curtain Call (Refraction Railway Line 2) before the rebalance patch."
	title = "Pre-Patch Veteran"
	database_id = MEDAL_REFRACTION_CC_PRE_PATCH
	difficulty = ACHIEVEMENT_HARDEST

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

// ---------- Curtain Call ----------

/datum/award/achievement/lc13/refraction/cc_capo_no_flurry
	name = "Restrained"
	desc = "Beat Capo without taking a hit from his full Tiantui Flurry finisher."
	title = "Restrained"
	database_id = MEDAL_REFRACTION_CC_CAPO_NO_FLURRY
	difficulty = ACHIEVEMENT_HARD

/datum/award/achievement/lc13/refraction/cc_capo_rat_five
	name = "Leash Holder"
	desc = "Killed the Capo Rat at least five times across the fight."
	title = "Leash Holder"
	database_id = MEDAL_REFRACTION_CC_CAPO_RAT_FIVE
	difficulty = ACHIEVEMENT_NORMAL

/datum/award/achievement/lc13/refraction/cc_azarus_no_wager
	name = "House Doesn't Win"
	desc = "Beat Azarus without anyone taking a Wager hit."
	title = "House-Beater"
	database_id = MEDAL_REFRACTION_CC_AZARUS_NO_WAGER
	difficulty = ACHIEVEMENT_HARD

/datum/award/achievement/lc13/refraction/cc_azarus_mirror
	name = "Shattered Reflection"
	desc = "Broke one of Azarus's mirror copies before killing him."
	title = "Mirror-Breaker"
	database_id = MEDAL_REFRACTION_CC_AZARUS_MIRROR
	difficulty = ACHIEVEMENT_NORMAL

/datum/award/achievement/lc13/refraction/cc_understudy_chain
	name = "Costume Catastrophe"
	desc = "Forced the Understudy to cancel its special-form attack four times in a row."
	title = "Costume Critic"
	database_id = MEDAL_REFRACTION_CC_UNDERSTUDY_CHAIN
	difficulty = ACHIEVEMENT_HARD

/datum/award/achievement/lc13/refraction/cc_understudy_weapon
	name = "Borrowed Steel"
	desc = "Picked up one of the weapons the Understudy's true forms leave behind."
	title = "Borrowed Steel"
	database_id = MEDAL_REFRACTION_CC_UNDERSTUDY_WEAPON
	difficulty = ACHIEVEMENT_NORMAL

/datum/award/achievement/lc13/refraction/cc_eric_no_burst
	name = "Bloodless"
	desc = "Survived every Greed Burst from Greed Touched Eric.T without taking damage."
	title = "Bloodless"
	database_id = MEDAL_REFRACTION_CC_ERIC_NO_BURST
	difficulty = ACHIEVEMENT_HARD

/datum/award/achievement/lc13/refraction/cc_eric_pool_drained
	name = "Drained the Pool"
	desc = "Reduced Eric.T's blood pool to empty at least once during the fight."
	title = "Pool-Drainer"
	database_id = MEDAL_REFRACTION_CC_ERIC_POOL_DRAINED
	difficulty = ACHIEVEMENT_NORMAL

/datum/award/achievement/lc13/refraction/cc_eric_spike_3
	name = "Skewered Choir"
	desc = "Let Eric.T's spike attack kill at least three of his own summons."
	title = "Choir Master"
	database_id = MEDAL_REFRACTION_CC_ERIC_SPIKE_3
	difficulty = ACHIEVEMENT_NORMAL

/datum/award/achievement/lc13/refraction/cc_reaper_starved
	name = "Hall Cut Short"
	desc = "Triggered the Mirror Shattered Reaper's Phase 2 with fewer than three absorbed clones."
	title = "Hall-Breaker"
	database_id = MEDAL_REFRACTION_CC_REAPER_STARVED
	difficulty = ACHIEVEMENT_HARD

/datum/award/achievement/lc13/refraction/cc_reaper_cap_10
	name = "Hoard Capped"
	desc = "Never let the Mirror Shattered Reaper's absorbed-clone counter rise above ten."
	title = "Hoard-Capper"
	database_id = MEDAL_REFRACTION_CC_REAPER_CAP_10
	difficulty = ACHIEVEMENT_NORMAL

/datum/award/achievement/lc13/refraction/cc_snow_no_mouth_kill
	name = "Lip Service"
	desc = "Beat the Snow Cabin without killing any of its Mouths."
	title = "Lip Server"
	database_id = MEDAL_REFRACTION_CC_SNOW_NO_MOUTH_KILL
	difficulty = ACHIEVEMENT_NORMAL

/datum/award/achievement/lc13/refraction/cc_snow_no_mouth_bite
	name = "Lips Sealed"
	desc = "Survived the Snow Cabin without taking a Mouth open-state bite."
	title = "Lip-Sealed"
	database_id = MEDAL_REFRACTION_CC_SNOW_NO_MOUTH_BITE
	difficulty = ACHIEVEMENT_HARD

/datum/award/achievement/lc13/refraction/cc_priest_no_marked
	name = "Unmarked Lamb"
	desc = "Never got hit by the Blade Priest's blade while carrying his skull mark."
	title = "Unmarked Lamb"
	database_id = MEDAL_REFRACTION_CC_PRIEST_NO_MARKED
	difficulty = ACHIEVEMENT_HARD

/datum/award/achievement/lc13/refraction/cc_priest_punish_3
	name = "Sermon Interrupted"
	desc = "Landed at least three hits on the Blade Priest during his order-lock punish window."
	title = "Sermon-Breaker"
	database_id = MEDAL_REFRACTION_CC_PRIEST_PUNISH_3
	difficulty = ACHIEVEMENT_NORMAL

/datum/award/achievement/lc13/refraction/cc_achiya_storm
	name = "Reverence"
	desc = "Survived the full Storm of Heaven without killing a Mirage Reaper."
	title = "Reverent"
	database_id = MEDAL_REFRACTION_CC_ACHIYA_STORM
	difficulty = ACHIEVEMENT_HARD

/datum/award/achievement/lc13/refraction/cc_achiya_pierced_3
	name = "Three-Times Pierced"
	desc = "Landed at least three Piercing Strikes on Achiyalabopa during Phase 2."
	title = "Strike-Caller"
	database_id = MEDAL_REFRACTION_CC_ACHIYA_PIERCED_3
	difficulty = ACHIEVEMENT_NORMAL

/datum/award/achievement/lc13/refraction/cc_ys_full_pressure
	name = "Full Pressure"
	desc = "Reached 100 Pressure on Young Star without anyone being downed."
	title = "Pressure-Holder"
	database_id = MEDAL_REFRACTION_CC_YS_FULL_PRESSURE
	difficulty = ACHIEVEMENT_HARD

/datum/award/achievement/lc13/refraction/cc_ys_steady
	name = "Steady Climb"
	desc = "Beat Young Star without triggering more than one Railroad refill."
	title = "Steady Climber"
	database_id = MEDAL_REFRACTION_CC_YS_STEADY
	difficulty = ACHIEVEMENT_NORMAL

/datum/award/achievement/lc13/refraction/cc_overseer_low_decay
	name = "Held the Stage"
	desc = "Cleared Serio Overseer's Phase 1 without anyone reaching 30 mental decay."
	title = "Stage-Holder"
	database_id = MEDAL_REFRACTION_CC_OVERSEER_LOW_DECAY
	difficulty = ACHIEVEMENT_NORMAL

/datum/award/achievement/lc13/refraction/cc_overseer_triple_kd
	name = "Triple Knockdown"
	desc = "Knocked down the Serio Overseer three times during Phase 1."
	title = "Knockdown Artist"
	database_id = MEDAL_REFRACTION_CC_OVERSEER_TRIPLE_KD
	difficulty = ACHIEVEMENT_NORMAL
