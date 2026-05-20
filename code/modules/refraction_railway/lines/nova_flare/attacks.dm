/*
 * Nova Flare mob attacks, returned by GetMobAttacks().
 * Each entry: list("name", "damage", "cooldown", "desc").
 * Player-readable language only. See AUTHORING.md Step 5c.
 *
 * Card-writing rules (see AUTHORING.md): the "damage" field is the only
 * place numbers belong. Never restate it in "desc"; never re-explain a
 * glossary status (name it); never spell out synergy/strategy; a basic
 * melee replacement names its type/scaling, not a number. Wrap any
 * reference to another card's name in **double asterisks** (bold).
 */
/datum/refraction_line/nova_flare/GetMobAttacks()
	return list(

		// ---------- G-Corp Steel Battalion ----------

		/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon = list(
			list(
				"name"     = "Self-Destruct",
				"damage"   = "60 RED in a 3-tile radius",
				"cooldown" = "Triggered (see **Last Stand**)",
				"desc"     = "Stops moving. Grows to nearly 2x size with a red glow over 1.5 seconds, then explodes, hitting everything close to it.",
			),
		),

		/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/flying = list(
			list(
				"name"     = "Self-Destruct",
				"damage"   = "60 RED in a 3-tile radius",
				"cooldown" = "Triggered (see **Last Stand**)",
				"desc"     = "Stops moving. Grows to nearly 2x size with a red glow over 1.5 seconds, then explodes, hitting everything close to it.",
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
					next windup is shorter (3 seconds) if a Steel Corporal's **Self-Destruct** went \
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
				"cooldown" = "Triggered (see **Retaliation**)",
				"desc"     = "Sprints forward for 4 seconds, moving much faster than usual. The \
					very next melee swing during the dash launches the target away.",
			),
			list(
				"name"     = "Love Whip",
				"damage"   = "100 RED across a long cone in front of it (about 8 tiles deep, fanning out toward the end)",
				"cooldown" = "Triggered (see **Retaliation**), Stage 2 only",
				"desc"     = "Winds up for 2.5 seconds — cannot move during this. On release, \
					swings a wide cone in the direction of its target. Anything alive caught in \
					the cone is yanked back toward the abomination. 20% chance to immediately \
					follow up with **Bullrush**.",
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
				"damage"   = "5 WHITE in a 7-tile radius",
				"cooldown" = "Constant — no wind-up, no cooldown",
				"desc"     = "Hits everything alive nearby whenever it moves, \
					makes a sound, or at random. Cannot be interrupted.",
			),
			list(
				"name"     = "Feast",
				"damage"   = "Adds PALE per melee hit, up to 4 hits (Insane targets only)",
				"cooldown" = "Only vs an Insane target",
				"desc"     = "Against a target whose sanity has broken, each hit \
					of its rapid melee flurry adds PALE on top of its WHITE \
					melee.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_clown/refracted = list(
			list(
				"name"     = "Wail",
				"damage"   = "12 WHITE in a 7-tile radius, applies 2 RED Fragile",
				"cooldown" = "6 seconds",
				"desc"     = "~0.5s decoy + ~0.6s wind-up (can't move), then \
					hits everything within 7 tiles and applies 2 RED Fragile.",
			),
			list(
				"name"     = "Slam",
				"damage"   = "RED in a 1-tile radius, scales with the target's RED Fragile",
				"cooldown" = "Replaces its basic attack, Stage 2 only",
				"desc"     = "Stage 2 only. Slams the ground around itself.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_clown/refracted/sister = list(
			list(
				"name"     = "Wail",
				"damage"   = "12 WHITE in a 7-tile radius, applies 5 RED Fragile",
				"cooldown" = "6 seconds",
				"desc"     = "~0.5s decoy + ~0.6s wind-up (can't move), then \
					hits everything within 7 tiles and applies 5 RED Fragile.",
			),
			list(
				"name"     = "Slam",
				"damage"   = "RED in a 1-tile radius, scales with the target's RED Fragile",
				"cooldown" = "Replaces its basic attack, Stage 2 only",
				"desc"     = "Stage 2 only. Slams the ground around itself.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_clown/refracted/mother = list(
			list(
				"name"     = "Wail",
				"damage"   = "17 WHITE in a 7-tile radius, applies 2 RED Fragile",
				"cooldown" = "7 seconds",
				"desc"     = "~0.5s decoy + ~0.6s wind-up (can't move), then \
					hits everything within 7 tiles and applies 2 RED Fragile.",
			),
			list(
				"name"     = "Slam",
				"damage"   = "RED in a 1-tile radius, scales with the target's RED Fragile",
				"cooldown" = "Replaces its basic attack, Stage 2 only",
				"desc"     = "Stage 2 only. Slams the ground around itself.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_clown/boss/refracted = list(
			list(
				"name"     = "Wail",
				"damage"   = "15 WHITE in a 7-tile radius, applies 2 RED Fragile",
				"cooldown" = "15 seconds",
				"desc"     = "Hits everything within 7 tiles and applies 2 RED \
					Fragile. While the hearts live, every Wail also summons \
					reinforcement clowns, weighted 70% Son/Father, 20% Sister, \
					10% Mother.",
			),
			list(
				"name"     = "Slam",
				"damage"   = "RED in a 1-tile radius, scales with the target's RED Fragile",
				"cooldown" = "Replaces its basic attack, Stage 2 only",
				"desc"     = "Stage 2 only. Slams the ground around itself.",
			),
			list(
				"name"     = "Meat Drop",
				"damage"   = "40 RED per bomb in a 1-tile radius",
				"cooldown" = "2.5 seconds, while the hearts live",
				"desc"     = "Marks every nearby human on their current tile. \
					Each marker detonates about 0.9 seconds later. One bomb per \
					human, every 2.5 seconds. Once every heart is destroyed, \
					this attack is replaced by **Meat Barrage**.",
			),
			list(
				"name"     = "Meat Barrage",
				"damage"   = "40 RED per bomb in a 1-tile radius",
				"cooldown" = "18 seconds, after the hearts are destroyed",
				"desc"     = "The enhanced form of **Meat Drop**, unlocked once \
					every heart is destroyed. Locks onto one or more players. \
					For 4 seconds, drops a marker on each locked target's \
					current tile every 0.5 seconds; each marker detonates about \
					0.9 seconds after it lands.",
			),
			list(
				"name"     = "Grief Stomp",
				"damage"   = "75 RED in a 2-tile radius + 10 Defense Level Down",
				"cooldown" = "On mask break, then every 10 seconds",
				"desc"     = "~0.7s ground-reticle telegraph, then hits \
					everything within 2 tiles and applies 10 Defense Level \
					Down.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_heart/refracted = list(
			list(
				"name"     = "Backlash",
				"damage"   = "3 Defense Level Down to all living within 2 tiles",
				"cooldown" = "On taking damage, max once per 1 second",
				"desc"     = "When hurt it pulses 3 Defense Level Down to EVERY \
					living thing within 2 tiles — players, the boss and the \
					clowns alike. See its **Backlash Shell** passive.",
			),
		),

		// ---------- Refracted (Sector 2) ----------

		/mob/living/simple_animal/hostile/clan/stone_guard/refracted = list(
			list(
				"name"     = "Transpierce",
				"damage"   = "25 RED + 4 Tremor per tile, line up to 5 tiles",
				"cooldown" = "12 seconds",
				"desc"     = "Calls out + ~0.5s of fading decoys, then spikes \
					every tile in a line up to 5 tiles toward where its target \
					was. If it hits nothing it loses 5 charge.",
			),
		),

		/mob/living/simple_animal/hostile/scarlet_rose/refracted = list(
			list(
				"name"     = "Thornlash",
				"damage"   = "10 RED, then detonate the target's Bleed (BRUTE = the Bleed, halving each pulse) or, under 5 Bleed, +30 Bleed",
				"cooldown" = "9 seconds",
				"desc"     = "Marks the ground under each target ~3s. On the \
					strike it hits everything within 1 tile of a marker. If \
					the target has 5 or more Bleed, that Bleed detonates (up to \
					4 pulses, clearing once it drops to 1 or less); otherwise \
					the target gains 30 Bleed instead.",
			),
			list(
				"name"     = "Tangle",
				"damage"   = "5 Bleed (~10% chance when forced through)",
				"cooldown" = "On contact with its vines",
				"desc"     = "Shoving through one of its vines instead of \
					cutting it can snag your legs and apply Bleed. See \
					**Thornwall**.",
			),
		),

		// ---------- Refracted (Sector 3) ----------

		/mob/living/simple_animal/hostile/clan/ranged/gunner/refracted = list(
			list(
				"name"     = "Burst Fire",
				"damage"   = "3 bolts, each 15 RED",
				"cooldown" = "~10 seconds, 30% chance per ranged shot",
				"desc"     = "Replaces a normal ranged shot with a tight \
					burst of bolts fired in quick succession.",
			),
		),

		/mob/living/simple_animal/hostile/clan/ranged/rapid/refracted = list(
			list(
				"name"     = "Overdrive",
				"damage"   = "Up to 5 bolts per volley, each 5 RED",
				"cooldown" = "~10 seconds, 30% chance per ranged shot",
				"desc"     = "For ~5 seconds its volley count and fire rate \
					climb, then it returns to normal.",
			),
		),

		/mob/living/simple_animal/hostile/clan/ranged/harpooner/refracted = list(
			list(
				"name"     = "Harpoon",
				"damage"   = "20 RED on hit; 50 RED + Knockdown on drop",
				"cooldown" = "~20 seconds, prefers human targets; costs 20 charge (falls back to a normal shot if under-charged)",
				"desc"     = "Fires a chained harpoon at a player. On hit it \
					drags them in (they cannot move away from it) for up to 15 \
					seconds; on arrival within 2 tiles it slams them.",
			),
		),

		/mob/living/simple_animal/hostile/keeper_piller/refracted = list(
			list(
				"name"     = "Sunfall Lasers",
				"damage"   = "60 WHITE + 30 PALE per tile (+60 PALE vs Insane)",
				"cooldown" = "Constant while active",
				"desc"     = "Marks scattered tiles around itself with a brief \
					telegraph; each marker detonates ~1 second later, hitting \
					any human standing on it.",
			),
		),

		/mob/living/simple_animal/hostile/clan/stone_keeper/refracted = list(
			list(
				"name"     = "Slam",
				"damage"   = "PALE in a 2-tile radius",
				"cooldown" = "Replaces its basic attack",
				"desc"     = "~0.8s windup (icon swap), then slams everything \
					within 2 tiles.",
			),
			list(
				"name"     = "Annihilation Beam",
				"damage"   = "100 PALE per tile along the line",
				"cooldown" = "20 seconds",
				"desc"     = "~2.5s charge with a visible aiming beam, then \
					fires a piercing line in its facing direction; stopped by \
					dense walls.",
			),
		),

	)
