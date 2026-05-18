/*
 * Nova Flare mob passives.
 *
 * Returned by /datum/refraction_line/nova_flare/GetMobPassives() — the
 * subsystem walks every line at init and merges these into the canonical
 * SSrefraction_railway.mob_passives table. First registration wins on
 * collision; the loser is dropped with a stack_trace.
 *
 * Each passive entry is a flat assoc list:
 *
 *   list(
 *       "title"    = "Banner title",
 *       "severity" = "info" / "low" / "medium" / "high",
 *       "text"     = "Body paragraph.",
 *   )
 *
 * Severity drives the banner color and warning-icon count in the UI:
 *   info   = brown,  no warning icons (informational only)
 *   low    = yellow, 1 warning icon  (worth knowing about)
 *   medium = orange, 2 warning icons (active mid-combat consideration)
 *   high   = red,    3 warning icons (immediately dangerous)
 *
 * Style rules (see AUTHORING.md Step 5b for the full set):
 *   - Player-readable language only. No proc names, type paths, internal
 *     variable names, or DM expressions like view(N), oview(N), ohearers(N).
 *   - Use "tiles", "seconds", "HP", "moves much faster", "stunned", etc.
 *   - Discrete damage-dealing actions go in this line's attacks.dm. If a
 *     passive triggers an attack, name the attack and let attacks carry
 *     the mechanics.
 */
/datum/refraction_line/nova_flare/GetMobPassives()
	return list(

		// ---------- G-Corp Steel Battalion ----------

		/mob/living/simple_animal/hostile/ordeal/steel_dawn = list(
			list(
				"title"    = "Fall Back",
				"severity" = "low",
				"text"     = "At 50% HP or below (and not currently Zealous), stops attacking \
					and runs to keep at least 5 tiles between itself and you. Slowly heals while \
					retreating, faster when nothing is targeting it.",
			),
		),

		/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon = list(
			list(
				"title"    = "Last Stand",
				"severity" = "high",
				"text"     = "While attacking at 25% HP or below, 75% chance per attack to trigger Self-Destruct.",
			),
			list(
				"title"    = "Zealous Squadmate",
				"severity" = "low",
				"text"     = "When Self-Destruct goes off, every Steel Dawn within 7 tiles \
					becomes Zealous (won't retreat anymore) and is healed to nearly full. Any \
					Steel Manager within 7 tiles speeds up its next Screech (5 seconds → 3 \
					seconds). If the Steel Corporal dies without triggering Self-Destruct, no \
					buff is applied.",
			),
			list(
				"title"    = "Vigor on Strike",
				"severity" = "info",
				"text"     = "Heals 10 HP for every melee hit it lands.",
			),
			list(
				"title"    = "Adrenaline",
				"severity" = "low",
				"text"     = "After being hit by 5 ranged shots, OR if it has gone 15 seconds \
					without landing an attack, the Steel Corporal gains a massive speed boost for \
					10 seconds. 10-second cooldown between activations.",
			),
		),

		/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/flying = list(
			list(
				"title"    = "Last Stand",
				"severity" = "high",
				"text"     = "Inherited from Steel Corporal. While attacking at 25% HP or below, \
					75% chance per attack to trigger Self-Destruct. Air Sweep replaces some \
					attacks, so the trigger rolls less often.",
			),
			list(
				"title"    = "Zealous Squadmate",
				"severity" = "low",
				"text"     = "Inherited from Steel Corporal. When Self-Destruct goes off, every \
					Steel Dawn within 7 tiles becomes Zealous and heals; nearby Steel Managers \
					speed up their next Screech.",
			),
		),

		/mob/living/simple_animal/hostile/ordeal/steel_dusk = list(
			list(
				"title"    = "Squad Orders",
				"severity" = "low",
				"text"     = "Every 18 seconds while it has a target, issues an order to all \
					Gene Corp units within about 9 tiles. The first order is always 'Hold Fast!' \
					(boosts their armor). Later orders alternate randomly between 'Hold Fast!' and \
					'Onslaught!' (boosts their damage). Units already carrying the buff don't \
					restack.",
			),
			list(
				"title"    = "Charge",
				"severity" = "info",
				"text"     = "On first aggro and again every minute, every nearby Steel unit \
					(within 9 tiles) is forced onto the Manager's current target and briefly \
					speeds up. Also delays the Manager's own next Screech by 10 seconds.",
			),
			list(
				"title"    = "Self-Repair",
				"severity" = "info",
				"text"     = "At 50% HP or below, slowly heals over time. Heals about 4x as fast when the Manager is not targeting anyone.",
			),
		),

		// ---------- Peccatulum (Sin) ----------

		/mob/living/simple_animal/hostile/ordeal/sin_pride/noon = list(
			list(
				"title"    = "Long Reach",
				"severity" = "info",
				"text"     = "Hits at 2 tiles of reach.",
			),
		),

		// ---------- Lovetown ----------

		/mob/living/simple_animal/hostile/lovetown/suicidal = list(
			list(
				"title"    = "Scream Only",
				"severity" = "info",
				"text"     = "Has no melee attack. Its only way to deal damage is Echoing Scream.",
			),
		),

		/mob/living/simple_animal/hostile/lovetown/slasher = list(
			list(
				"title"    = "Birthing Pool",
				"severity" = "info",
				"text"     = "On death, has roughly a 1-in-3 chance to spawn a Lovetown Suicidal at a tile next to it.",
			),
		),

		/mob/living/simple_animal/hostile/lovetown/abomination = list(
			list(
				"title"    = "Stage Transition",
				"severity" = "high",
				"text"     = "When its HP drops to 50% or below, enters Stage 2 once and cannot \
					revert. In Stage 2: moves much faster, AoE Slam expands from a 1-tile to a \
					2-tile radius, AoE Slam takes longer to wind up, the damage threshold to arm \
					a counter drops from 500 to 300, and Love Whip becomes available.",
			),
			list(
				"title"    = "Retaliation",
				"severity" = "medium",
				"text"     = "Tracks total damage taken. Once it has taken 500 damage (or 300 \
					in Stage 2), it immediately retaliates: triggers Bullrush (Stage 1, always) \
					or one of Love Whip (Stage 2, 80%) / Bullrush (Stage 2, 20%). The damage \
					counter resets after each retaliation, then starts ticking again.",
			),
			list(
				"title"    = "Stage 2 Vigor",
				"severity" = "medium",
				"text"     = "In Stage 2, heals 40 HP for every melee attack it lands.",
			),
			list(
				"title"    = "Birthing Pool",
				"severity" = "low",
				"text"     = "On death, always spawns 2 Lovetown Suicidals at adjacent open tiles.",
			),
		),

		// ---------- Refracted (Sector 1) ----------

		/mob/living/simple_animal/hostile/netherworld/migo/refracted = list(
			list(
				"title"    = "Constant Wail",
				"severity" = "medium",
				"text"     = "Whenever it moves or makes a sound, and at random, it \
					deals a small WHITE hit to everything within 7 tiles (see \
					Dissonant Wail). No wind-up and no cooldown.",
			),
			list(
				"title"    = "Mind-Eater",
				"severity" = "medium",
				"text"     = "While its target's sanity is broken, each of its melee \
					hits also deals PALE damage on top of the WHITE melee (see \
					Feast).",
			),
		),

		/mob/living/simple_animal/hostile/mutant_clown/refracted = list(
			list(
				"title"    = "Mask Break",
				"severity" = "high",
				"text"     = "Two stages. Stage 1 it keeps its distance and Wails. \
					At 50% HP its mask breaks: for about 2.5 seconds it takes 0.2× \
					from every damage type, then it is permanently Stage 2 — no \
					longer keeps distance, moves faster, and replaces its basic \
					attack with Slam. In Stage 2 it takes RED 1.6×, WHITE 0.6×, \
					BLACK 0.8×, PALE 2×.",
			),
			list(
				"title"    = "Wail and Slam",
				"severity" = "medium",
				"text"     = "Its Wail applies 2 RED Fragile; RED Fragile increases \
					the RED damage that target takes. Its Stage 2 Slam deals RED, so \
					the Slam is increased by RED Fragile applied by any clown.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_clown/refracted/sister = list(
			list(
				"title"    = "Mask Break",
				"severity" = "high",
				"text"     = "Frail and low on HP; keeps about 8 tiles away and \
					Wails. Its mask breaks only after it loses about 75% of its HP. \
					During the break (about 2.5 seconds) it takes 0.2× from every \
					damage type. In Stage 2 it takes RED 1.6×, WHITE 0.6×, BLACK \
					0.8×, PALE 2×.",
			),
			list(
				"title"    = "Wail and Slam",
				"severity" = "medium",
				"text"     = "Its Wail applies 5 RED Fragile; RED Fragile increases \
					the RED damage that target takes. Its Stage 2 Slam deals RED, so \
					the Slam is increased by RED Fragile applied by any clown.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_clown/refracted/mother = list(
			list(
				"title"    = "Mask Break",
				"severity" = "high",
				"text"     = "Large and high-HP; never retreats. Its mask breaks \
					after it loses only about 25% of its HP. During the break (about \
					2.5 seconds) it takes 0.2× from every damage type. In Stage 2 it \
					takes RED 1.6×, WHITE 0.6×, BLACK 0.8×, PALE 2×.",
			),
			list(
				"title"    = "Wail and Slam",
				"severity" = "medium",
				"text"     = "Its Wail applies 2 RED Fragile; RED Fragile increases \
					the RED damage that target takes. Its Stage 2 Slam deals RED, so \
					the Slam is increased by RED Fragile applied by any clown.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_clown/boss/refracted = list(
			list(
				"title"    = "Beating Hearts",
				"severity" = "high",
				"text"     = "It appears ringed by 4 hearts. While any heart \
					still lives it cannot move and takes no damage at all. Each \
					heart has half of the Grandfather's max HP.",
			),
			list(
				"title"    = "The Whole Family",
				"severity" = "medium",
				"text"     = "While the hearts live it wails every 15 seconds \
					and summons reinforcement clowns — more with a larger lobby, \
					mostly Son/Father and only rarely Sister or Mother.",
			),
			list(
				"title"    = "Broken Mask",
				"severity" = "high",
				"text"     = "Once the hearts are gone, at 50% HP its mask \
					breaks: about 2.5 seconds taking 0.2× from everything, then \
					permanently Stage 2 — much faster, and it takes RED 1.6×, \
					WHITE 0.6×, BLACK 0.8×, PALE 2×.",
			),
			list(
				"title"    = "One Last Laugh",
				"severity" = "medium",
				"text"     = "When the Grandfather dies, every clown near it \
					dies with it.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_heart/refracted = list(
			list(
				"title"    = "Lifeline",
				"severity" = "high",
				"text"     = "While it lives the Grandfather takes no damage and \
					cannot move. Has half the Grandfather's max HP. It does not \
					move or attack.",
			),
			list(
				"title"    = "Hardened Shell",
				"severity" = "medium",
				"text"     = "Takes 50% less damage from projectiles — melee is \
					far more effective against it.",
			),
		),

	)
