/*
 * Curtain Call per-mob achievements, returned by GetMobAchievements().
 *
 * Authoring conventions mirror lines/nova_flare/achievements.dm — see
 * that file's header for the entry shape (id / name / desc / reward /
 * default_state / award).
 *
 * Rewards target ~310 Starlight total across 21 achievements; harder
 * "avoid X" trackers carry more weight than do-X markers.
 */
/datum/refraction_line/curtain_call/GetMobAchievements()
	return list(

		// ---------- Sector 1: Thumb East Capo + Capo Rat ----------
		/mob/living/simple_animal/hostile/thumb_east_capo/refracted = list(
			list(
				"id"            = "capo_no_flurry_hit",
				"name"          = "Restrained",
				"desc"          = "Never get hit by the finisher of Capo's Flurry.",
				"reward"        = 18,
				"default_state" = TRUE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_capo_no_flurry,
			),
			list(
				"id"            = "capo_rat_five",
				"name"          = "Leash Holder",
				"desc"          = "Force the Capo Rat into Plays Dead at least five times across the fight.",
				"reward"        = 12,
				"default_state" = FALSE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_capo_rat_five,
			),
		),

		// ---------- Sector 1: Azarus ----------
		/mob/living/simple_animal/hostile/distortion/azarus/refracted = list(
			list(
				"id"            = "azarus_no_wager_hit",
				"name"          = "House Doesn't Win",
				"desc"          = "Beat Azarus without anyone taking a Wager hit.",
				"reward"        = 18,
				"default_state" = TRUE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_azarus_no_wager,
			),
			list(
				"id"            = "azarus_mirror_pre_kill",
				"name"          = "Shattered Reflection",
				"desc"          = "Break at least one of Azarus's mirror-doubles before killing him.",
				"reward"        = 12,
				"default_state" = FALSE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_azarus_mirror,
			),
		),

		// ---------- Sector 2: Understudy ----------
		/mob/living/simple_animal/hostile/distortion/understudy = list(
			list(
				"id"            = "understudy_form_chain",
				"name"          = "Costume Catastrophe",
				"desc"          = "Force-morph four of the Envy of Humanity's worn faces in a row before their abilities resolve.",
				"reward"        = 20,
				"default_state" = FALSE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_understudy_chain,
			),
			list(
				"id"            = "understudy_weapon_pickup",
				"name"          = "Borrowed Steel",
				"desc"          = "Pick up the costume weapon dropped when the Envy of Humanity's first worn form is stripped bare.",
				"reward"        = 10,
				"default_state" = FALSE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_understudy_weapon,
			),
		),

		// ---------- Sector 2: Greed Touched Eric.T ----------
		/mob/living/simple_animal/hostile/greed_touched_eric/refracted = list(
			list(
				"id"            = "eric_no_burst_hit",
				"name"          = "Bloodless",
				"desc"          = "Survive every Greed Burst from Eric.T without taking damage.",
				"reward"        = 15,
				"default_state" = TRUE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_eric_no_burst,
			),
			list(
				"id"            = "eric_pool_drained",
				"name"          = "Drained the Pool",
				"desc"          = "Reduce Eric.T's bloodfeast pool to empty at least once.",
				"reward"        = 15,
				"default_state" = FALSE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_eric_pool_drained,
			),
			list(
				"id"            = "eric_spike_three_summons",
				"name"          = "Skewered Choir",
				"desc"          = "Let Eric.T's Sanguine Feast kill at least three of his own summons.",
				"reward"        = 10,
				"default_state" = FALSE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_eric_spike_3,
			),
		),

		// ---------- Sector 3: Mirror Shattered Reaper ----------
		/mob/living/simple_animal/hostile/mirror_shattered_reaper/refracted = list(
			list(
				"id"            = "reaper_phase2_starved",
				"name"          = "Hall Cut Short",
				"desc"          = "Trigger the Reaper's Phase 2 with fewer than three Reverberation Charges.",
				"reward"        = 18,
				"default_state" = FALSE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_reaper_starved,
			),
			list(
				"id"            = "reaper_cap_ten",
				"name"          = "Hoard Capped",
				"desc"          = "Never let the Reaper's Reverberation Charge rise above ten.",
				"reward"        = 12,
				"default_state" = TRUE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_reaper_cap_10,
			),
		),

		// ---------- Sector 3: Snow Cabin ----------
		/mob/living/simple_animal/hostile/snow_cabin/refracted = list(
			list(
				"id"            = "snow_no_mouth_kill",
				"name"          = "Lip Service",
				"desc"          = "Don't kill any Snow Cabin Mouths during the fight.",
				"reward"        = 15,
				"default_state" = TRUE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_snow_no_mouth_kill,
			),
			list(
				"id"            = "snow_no_mouth_bite",
				"name"          = "Lips Sealed",
				"desc"          = "Don't get hit by a Snow Cabin Mouth's Bite.",
				"reward"        = 15,
				"default_state" = TRUE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_snow_no_mouth_bite,
			),
		),

		// ---------- Sector 4: Blade Priest ----------
		/mob/living/simple_animal/hostile/distortion/blade_priest/refracted = list(
			list(
				"id"            = "priest_no_marked_hit",
				"name"          = "Unmarked Lamb",
				"desc"          = "Never get hit by a Possessed Blade while carrying the Skull Mark.",
				"reward"        = 15,
				"default_state" = TRUE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_priest_no_marked,
			),
			list(
				"id"            = "priest_punish_three",
				"name"          = "Sermon Interrupted",
				"desc"          = "Land at least three hits on the Blade Priest while he is locked Issuing an Order.",
				"reward"        = 15,
				"default_state" = FALSE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_priest_punish_3,
			),
		),

		// ---------- Sector 4: Achiyalabopa ----------
		/mob/living/simple_animal/hostile/achiyalabopa/refracted = list(
			list(
				"id"            = "achiya_storm_endured",
				"name"          = "Reverence",
				"desc"          = "Survive until Achiyalabopa breaks her divine pose without unmaking any Mirage Reaper.",
				"reward"        = 20,
				"default_state" = TRUE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_achiya_storm,
			),
			list(
				"id"            = "achiya_pierced_three",
				"name"          = "Three-Times Pierced",
				"desc"          = "Land at least three Piercing Strikes during Phase 2.",
				"reward"        = 10,
				"default_state" = FALSE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_achiya_pierced_3,
			),
		),

		// ---------- Curtain Fall: Young Star ----------
		/mob/living/simple_animal/hostile/young_star = list(
			list(
				"id"            = "young_star_full_pressure",
				"name"          = "Full Pressure",
				"desc"          = "Reach 100 Pressure on Young Star without anyone being downed.",
				"reward"        = 20,
				"default_state" = TRUE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_ys_full_pressure,
			),
			list(
				"id"            = "young_star_steady",
				"name"          = "Steady Climb",
				"desc"          = "Don't trigger The Show Goes On more than once across the fight.",
				"reward"        = 12,
				"default_state" = TRUE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_ys_steady,
			),
		),

		// ---------- Curtain Fall: Serio Overseer (Phase 1) ----------
		/mob/living/simple_animal/hostile/serio_overseer = list(
			list(
				"id"            = "overseer_low_decay",
				"name"          = "Held the Stage",
				"desc"          = "Clear Phase 1 without anyone's mental decay rising above 30.",
				"reward"        = 15,
				"default_state" = TRUE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_overseer_low_decay,
			),
			list(
				"id"            = "overseer_triple_knockdown",
				"name"          = "Triple Knockdown",
				"desc"          = "Knock the Overseer down three times during Phase 1.",
				"reward"        = 15,
				"default_state" = FALSE,
				"award"         = /datum/award/achievement/lc13/refraction/cc_overseer_triple_kd,
			),
		),

	)
