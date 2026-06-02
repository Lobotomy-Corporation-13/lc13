/*
 * Nova Flare per-mob achievements, returned by GetMobAchievements().
 *
 * id           — unique across ALL lines (the subsystem stack_traces on
 *                collision and drops the second registrant)
 * name / desc  — player-facing
 * reward       — Starlight folded in by AwardStarlightProgression on
 *                run complete, ONLY if the per-ckey state ends earned.
 *                Tune so the rewards in this line sum to ~200, with
 *                harder achievements getting more.
 * default_state — TRUE for "avoid X" defaults-to-pass; FALSE for
 *                "do X" defaults-to-not-earned
 *
 * Current totals (sum to 200):
 *   Grandfather   : 28 + 14 = 42
 *   Rose          : 28
 *   Stone Guard   : 22
 *   Mad Fly       :  8
 *   Drone         : 18
 *   Harpooner     : 22
 *   Keeper        : 18 + 14 + 28 = 60
 *   -----------------
 *   total         : 200
 */
/datum/refraction_line/nova_flare/GetMobAchievements()
	return list(

		// ---------- Sector 1: Grandfather ----------
		/mob/living/simple_animal/hostile/mutant_clown/boss/refracted = list(
			list(
				"id"            = "grandfather_no_meat_hit",
				"name"          = "Untouched by Flesh",
				"desc"          = "Never get hit by the Grandfather's meat-drop attacks.",
				"reward"        = 28,
				"default_state" = TRUE,
			),
			list(
				"id"            = "grandfather_calm",
				"name"          = "Calm Patriarch",
				"desc"          = "Don't let the Grandfather summon more than 3 reinforcements.",
				"reward"        = 14,
				"default_state" = TRUE,
			),
		),

		// ---------- Sector 2: Scarlet Rose ----------
		/mob/living/simple_animal/hostile/scarlet_rose/refracted = list(
			list(
				"id"            = "rose_no_high_bleed",
				"name"          = "Stay Unbled",
				"desc"          = "Never cross 40 Bleed stacks during the Scarlet Rose fight.",
				"reward"        = 28,
				"default_state" = TRUE,
			),
		),

		// ---------- Sector 2: Stone Guard ----------
		/mob/living/simple_animal/hostile/clan/stone_guard/refracted = list(
			list(
				"id"            = "guard_no_black_swap",
				"name"          = "Restraint",
				"desc"          = "Never get hit while carrying enough Tremor to flip the Stone Guard's strike to BLACK.",
				"reward"        = 22,
				"default_state" = TRUE,
			),
		),

		// ---------- Sector 2: Mad Fly Swarm ----------
		/mob/living/simple_animal/hostile/mad_fly_swarm/refracted = list(
			list(
				"id"            = "swarm_let_burrow",
				"name"          = "Welcoming Host",
				"desc"          = "Let a refracted swarm burrow into you at least once.",
				"reward"        = 8,
				"default_state" = FALSE,
			),
		),

		// ---------- Sector 3: Clan Drone ----------
		/mob/living/simple_animal/hostile/clan/drone/refracted = list(
			list(
				"id"            = "drone_no_emergency_heal",
				"name"          = "No Repairs Needed",
				"desc"          = "Don't let the Clan Drone trigger its emergency heal.",
				"reward"        = 18,
				"default_state" = TRUE,
			),
		),

		// ---------- Sector 3: Harpooner ----------
		/mob/living/simple_animal/hostile/clan/ranged/harpooner/refracted = list(
			list(
				"id"            = "harpooner_no_proximity_break",
				"name"          = "Untethered",
				"desc"          = "Don't get chained by the Harpooner — or if chained, break it by breaking line of sight (not by approach or timeout).",
				"reward"        = 22,
				"default_state" = TRUE,
			),
		),

		// ---------- Sector 3: Stone Keeper ----------
		/mob/living/simple_animal/hostile/clan/stone_keeper/refracted = list(
			list(
				"id"            = "keeper_no_mine_hit",
				"name"          = "Mineless",
				"desc"          = "Never take damage from one of the Keeper's mines.",
				"reward"        = 18,
				"default_state" = TRUE,
			),
			list(
				"id"            = "keeper_kill_pillar",
				"name"          = "Topple the Pillar",
				"desc"          = "Destroy one of the Keeper's pillars before the Keeper itself dies.",
				"reward"        = 14,
				"default_state" = FALSE,
			),
			list(
				"id"            = "keeper_no_mine_swarm",
				"name"          = "Mine Hoarder",
				"desc"          = "Don't let 20 or more of the Keeper's mines exist at once.",
				"reward"        = 28,
				"default_state" = TRUE,
			),
		),

	)
