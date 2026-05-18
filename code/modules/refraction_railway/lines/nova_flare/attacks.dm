/*
 * Nova Flare mob attacks.
 *
 * Returned by /datum/refraction_line/nova_flare/GetMobAttacks() — the
 * subsystem walks every line at init and merges these into the canonical
 * SSrefraction_railway.mob_attacks table. First registration wins on
 * collision; the loser is dropped with a stack_trace.
 *
 * Each attack entry is a flat assoc list:
 *
 *   list(
 *       "name"     = "Attack name",
 *       "damage"   = "Damage value + type + area",
 *       "cooldown" = "Player-readable cooldown phrase",
 *       "desc"     = "Short paragraph describing the attack.",
 *   )
 *
 * Cooldown conventions:
 *   "15 seconds"                            — clean interval
 *   "4 seconds, 30% chance per attack"      — interval + probability
 *   "Replaces basic melee"                  — always-on
 *   "Triggered (see Last Stand)"            — armed by a passive; references it
 *   ", Stage 2 only"                        — append for stage-locked attacks
 *
 * Style rules (see AUTHORING.md Step 5c for the full set):
 *   - Player-readable language only. No proc names, type paths, or DM
 *     expressions.
 *   - Use tile counts, seconds, "winds up", "stunned", "knocks back".
 *
 * Like passives, attacks only surface on the *revealed* mob card.
 */
/datum/refraction_line/nova_flare/GetMobAttacks()
	return list(

		// ---------- G-Corp Steel Battalion ----------

		/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon = list(
			list(
				"name"     = "Self-Destruct",
				"damage"   = "60 RED in a 3-tile radius",
				"cooldown" = "Triggered (see Last Stand)",
				"desc"     = "Stops moving. Grows to nearly 2x size with a red glow over 1.5 seconds. Then explodes, hitting everything close to it.",
			),
		),

		/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/flying = list(
			list(
				"name"     = "Self-Destruct",
				"damage"   = "60 RED in a 3-tile radius",
				"cooldown" = "Triggered (see Last Stand)",
				"desc"     = "Stops moving. Grows to nearly 2x size with a red glow over 1.5 seconds. Then explodes, hitting everything close to it.",
			),
			list(
				"name"     = "Air Sweep",
				"damage"   = "30 RED on the target hit, plus knockback",
				"cooldown" = "15 seconds, 30% chance per attack",
				"desc"     = "Leaps upward and hovers in place for 2 seconds. Then charges in \
					a straight line up to 7 tiles toward where its target was. The first thing it \
					hits along the way takes the damage; if it's player-sized or smaller, it gets \
					knocked back. If something interrupts the hover, the Scout crashes and take \
					100 RED damage.",
			),
		),

		/mob/living/simple_animal/hostile/ordeal/steel_dusk = list(
			list(
				"name"     = "Screech",
				"damage"   = "60 WHITE in a 10-tile radius",
				"cooldown" = "15 seconds",
				"desc"     = "Spends 5 seconds winding up — cannot move or attack during this \
					time. On release, blasts a shockwave that hits everything in the area. The \
					next windup is shorter (3 seconds) if a Steel Corporal's Self-Destruct went \
					off near it.",
			),
		),

		// ---------- Peccatulum (Sin) ----------

		/mob/living/simple_animal/hostile/ordeal/sin_pride/noon = list(
			list(
				"name"     = "Wheel Dash",
				"damage"   = "60 RED in a 2-tile radius around the landing spot",
				"cooldown" = "4 seconds",
				"desc"     = "Charges up to 6 tiles toward its target, then slams down on the landing spot in a small area.",
			),
		),

		// ---------- Lovetown ----------

		/mob/living/simple_animal/hostile/lovetown/suicidal = list(
			list(
				"name"     = "Echoing Scream",
				"damage"   = "5 WHITE in a 3-tile radius (ignores armor)",
				"cooldown" = "6 seconds, 50% chance per attempt",
				"desc"     = "Spends about 2 seconds spawning three drifting decoy images, one \
					every 0.6 seconds. Cannot move during this. After the third decoy, screams \
					and damages everything close to it.",
			),
		),

		/mob/living/simple_animal/hostile/lovetown/abomination = list(
			list(
				"name"     = "AoE Slam",
				"damage"   = "30-40 RED in a 1-tile radius (Stage 1) or 2-tile radius (Stage 2)",
				"cooldown" = "Replaces basic melee",
				"desc"     = "Faces the target and winds up: half a second in Stage 1, one full \
					second in Stage 2. Then slams an area around itself. Cannot move or attack \
					during the wind. About a third of a second of recovery after.",
			),
			list(
				"name"     = "Bullrush",
				"damage"   = "30-40 RED plus a hard knockback (target is thrown several tiles)",
				"cooldown" = "Triggered (see Retaliation)",
				"desc"     = "Sprints forward for 4 seconds, moving much faster than usual. The \
					very next melee swing during the dash launches the target away.",
			),
			list(
				"name"     = "Love Whip",
				"damage"   = "100 RED across a long cone in front of it (about 8 tiles deep, fanning out toward the end)",
				"cooldown" = "Triggered (see Retaliation), Stage 2 only",
				"desc"     = "Winds up for 2.5 seconds — cannot move during this. On release, \
					swings a wide cone in the direction of its target. Anything alive caught in \
					the cone is yanked back toward the abomination. 20% chance to immediately \
					follow up with Bullrush.",
			),
			list(
				"name"     = "Finisher",
				"damage"   = "Outright kills the held player. Also deals 50 WHITE to every player within 7 tiles (ignores armor)",
				"cooldown" = "Only when attacking a downed player",
				"desc"     = "When swinging at a player who is in critical condition, grabs \
					them, lifts them upward, and holds for 2.5 seconds. If the player is still \
					in the abomination's grip at the end, kills them outright and damages every \
					nearby player. Allies can save the victim by pulling them out of reach during \
					the wind.",
			),
		),

		// ---------- Refracted (Sector 1) ----------

		/mob/living/simple_animal/hostile/netherworld/migo/refracted = list(
			list(
				"name"     = "Dissonant Wail",
				"damage"   = "6 WHITE in a 7-tile radius",
				"cooldown" = "Constant — no wind-up, no cooldown",
				"desc"     = "Deals 6 WHITE to everything alive within 7 tiles \
					whenever it moves or makes a sound, and at random. Cannot be \
					interrupted.",
			),
			list(
				"name"     = "Feast",
				"damage"   = "6 PALE per melee hit, up to 4 hits per attack",
				"cooldown" = "Only vs an Insane target (see Mind-Eater)",
				"desc"     = "Against a target whose sanity has broken, each hit of \
					its rapid melee flurry deals 6 PALE on top of its WHITE melee.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_clown/refracted = list(
			list(
				"name"     = "Wail",
				"damage"   = "16 WHITE in a 7-tile radius, applies 2 RED Fragile",
				"cooldown" = "6 seconds",
				"desc"     = "Winds up for about 0.5 seconds, then deals 16 WHITE \
					to everything within 7 tiles and applies 2 RED Fragile. Cannot \
					move while screaming.",
			),
			list(
				"name"     = "Slam",
				"damage"   = "10-16 RED in a 1-tile radius",
				"cooldown" = "Replaces its basic attack, Stage 2 only",
				"desc"     = "Stage 2 only. Slams the ground, dealing 10-16 RED to \
					everything within 1 tile. Increased by the target's RED \
					Fragile.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_clown/refracted/sister = list(
			list(
				"name"     = "Wail",
				"damage"   = "16 WHITE in a 7-tile radius, applies 5 RED Fragile",
				"cooldown" = "6 seconds",
				"desc"     = "Winds up for about 0.5 seconds, then deals 16 WHITE \
					to everything within 7 tiles and applies 5 RED Fragile. Cannot \
					move while screaming.",
			),
			list(
				"name"     = "Slam",
				"damage"   = "8-12 RED in a 1-tile radius",
				"cooldown" = "Replaces its basic attack, Stage 2 only",
				"desc"     = "Stage 2 only. Slams the ground, dealing 8-12 RED to \
					everything within 1 tile. Increased by the target's RED \
					Fragile.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_clown/refracted/mother = list(
			list(
				"name"     = "Wail",
				"damage"   = "22 WHITE in a 7-tile radius, applies 2 RED Fragile",
				"cooldown" = "7 seconds",
				"desc"     = "Winds up for about 0.5 seconds, then deals 22 WHITE \
					to everything within 7 tiles and applies 2 RED Fragile. Cannot \
					move while screaming.",
			),
			list(
				"name"     = "Slam",
				"damage"   = "14-22 RED in a 1-tile radius",
				"cooldown" = "Replaces its basic attack, Stage 2 only",
				"desc"     = "Stage 2 only. Slams the ground, dealing 14-22 RED to \
					everything within 1 tile. Increased by the target's RED \
					Fragile.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_clown/boss/refracted = list(
			list(
				"name"     = "Wail",
				"damage"   = "20 WHITE in a 7-tile radius, applies 2 RED Fragile",
				"cooldown" = "15 seconds",
				"desc"     = "Wails for 20 WHITE to everything within 7 tiles and \
					applies 2 RED Fragile. While the hearts live, every wail also \
					summons reinforcement clowns.",
			),
			list(
				"name"     = "Slam",
				"damage"   = "35-50 RED in a 1-tile radius",
				"cooldown" = "Replaces its basic attack, Stage 2 only",
				"desc"     = "Stage 2 only. Slams the ground, dealing 35-50 RED to \
					everything within 1 tile. Increased by the target's RED \
					Fragile.",
			),
			list(
				"name"     = "Meat Drop",
				"damage"   = "40 RED in a 1-tile radius",
				"cooldown" = "2.5 seconds",
				"desc"     = "Marks the target's tile with bloated meat; it \
					detonates after about 0.9 seconds for RED in a 1-tile \
					radius. Its standard ranged attack until the hearts are \
					destroyed.",
			),
			list(
				"name"     = "Meat Barrage",
				"damage"   = "40 RED per bomb in a 1-tile radius",
				"cooldown" = "6 seconds, after the hearts are destroyed",
				"desc"     = "Once every heart is destroyed the Meat Drop \
					escalates: it scatters several markers across the area (more \
					with a larger lobby), each detonating after about 0.9 \
					seconds.",
			),
			list(
				"name"     = "Grief Stomp",
				"damage"   = "40 RED in a 2-tile radius, applies 10 Defense \
					Level Down",
				"cooldown" = "On mask break, then every 10 seconds",
				"desc"     = "Telegraphs the ground for about 0.7 seconds, then \
					stomps everything within 2 tiles for RED and weakens their \
					defenses.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_heart/refracted = list(
			list(
				"name"     = "Backlash",
				"damage"   = "3 Defense Level Down to every living thing within \
					2 tiles",
				"cooldown" = "Whenever it is damaged, 1 second",
				"desc"     = "Each time the heart is hurt it pulses, raising all \
					damage taken by everything within 2 tiles. Stacks and decays \
					over time.",
			),
		),

	)
