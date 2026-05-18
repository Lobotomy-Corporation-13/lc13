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
				"text"     = "140 HP. Every ~2 seconds it has a 10% chance — and \
					always whenever it speaks — to deal 5 WHITE to everything \
					within 7 tiles. No wind-up, no cooldown, cannot be \
					interrupted; with a pack these pulses stack with nothing to \
					dodge.",
			),
			list(
				"title"    = "Mind-Eater",
				"severity" = "medium",
				"text"     = "Basic attack is 4 hits of 3 WHITE. While its \
					target is Insane (0 SP), every one of those 4 hits also \
					deals +5 PALE — up to 20 extra PALE per attack. Stay above 0 \
					SP near it.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_clown/refracted = list(
			list(
				"title"    = "Mask Break",
				"severity" = "high",
				"text"     = "400 HP. Stage 1: keeps ~6 tiles away. Damage taken \
					RED x1.4 / WHITE x0.6 / BLACK x0.8 / PALE x2. At 50% HP \
					(200) the mask breaks: 2.5 seconds taking x0.2 from \
					everything (do not waste burst here), then permanently \
					Stage 2 — can no longer be kept at range, moves faster, \
					basic attack becomes Slam, and damage taken becomes RED \
					x1.6 / WHITE x0.6 / BLACK x0.8 / PALE x2. Never reverts.",
			),
			list(
				"title"    = "Wail and Slam",
				"severity" = "medium",
				"text"     = "Wail (every 6s) applies 2 RED Fragile: +10% RED \
					damage taken per stack for 10s (here +20%), refreshing to \
					the higher stack, max 9. Stage 2 Slam (8-12 RED) is RED, so \
					RED Fragile from ANY clown amplifies it.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_clown/refracted/sister = list(
			list(
				"title"    = "Mask Break",
				"severity" = "high",
				"text"     = "190 HP, frail. Keeps ~8 tiles away and Wails. Mask \
					breaks only at 25% HP (≈48, after losing 75%), so it stays \
					in ranged Stage 1 almost the whole fight. Break = 2.5s at \
					x0.2; Stage 2 RED x1.6 / WHITE x0.6 / BLACK x0.8 / PALE x2.",
			),
			list(
				"title"    = "Wail and Slam",
				"severity" = "high",
				"text"     = "Its Wail (every 6s) applies 5 RED Fragile: +10% \
					RED taken per stack for 10s (here +50%), max 9. It is the \
					family's Fragile engine — kill it first; its own Slam is \
					6-9 RED.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_clown/refracted/mother = list(
			list(
				"title"    = "Mask Break",
				"severity" = "high",
				"text"     = "575 HP, never retreats. Mask breaks at 75% HP \
					(≈431, after losing only 25%), so it enters Stage 2 almost \
					immediately — fast, un-kiteable, Slam. Break = 2.5s at x0.2; \
					Stage 2 RED x1.6 / WHITE x0.6 / BLACK x0.8 / PALE x2.",
			),
			list(
				"title"    = "Wail and Slam",
				"severity" = "medium",
				"text"     = "Its Wail (every 7s) applies 2 RED Fragile (+10% \
					RED taken/stack, 10s, here +20%, max 9). Its Stage 2 Slam is \
					the family's heaviest at 11-17 RED — lethal stacked with the \
					Sister's 5 RED Fragile.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_clown/boss/refracted = list(
			list(
				"title"    = "Beating Hearts",
				"severity" = "high",
				"text"     = "1250 HP (x player count). Spawns ringed by 4 \
					hearts, each at 50% of its scaled max HP (625 solo). While \
					ANY heart lives it cannot move and takes 0 damage. Kill all \
					4 hearts to make it vulnerable.",
			),
			list(
				"title"    = "The Whole Family",
				"severity" = "high",
				"text"     = "While the hearts live it Wails every 15s: 15 \
					WHITE within 7 tiles + 2 RED Fragile, AND summons 1 \
					reinforcement clown per player (70% Son/Father, 20% Sister, \
					10% Mother). It also drops a 40 RED meat bomb (0.9s \
					telegraph, 1 tile) on every player within 7 tiles each \
					~2.5s.",
			),
			list(
				"title"    = "Broken Mask",
				"severity" = "high",
				"text"     = "Hearts gone, mobile. Melee 26-38 RED. At 50% HP \
					(625) the mask breaks: 2.5s at x0.2, then permanent Stage 2 \
					— faster, Slam, RED x1.6 / WHITE x0.6 / BLACK x0.8 / PALE \
					x2. Meat now becomes the Barrage (see attacks).",
			),
			list(
				"title"    = "One Last Laugh",
				"severity" = "medium",
				"text"     = "On death, every clown within 12 tiles dies with \
					it and all hearts are removed.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_heart/refracted = list(
			list(
				"title"    = "Lifeline",
				"severity" = "high",
				"text"     = "625 HP solo (50% of the Grandfather's scaled max, \
					so x player count). Immobile, never attacks. While it lives \
					the Grandfather cannot move and takes 0 damage.",
			),
			list(
				"title"    = "Backlash Shell",
				"severity" = "high",
				"text"     = "Takes x0.5 from projectiles (melee is 2x more \
					effective). Each time it is damaged (max once per 1s) it \
					pulses 3 Defense Level Down onto EVERY living thing within 2 \
					tiles — players AND the boss/clowns. Defense Level Down: all \
					damage taken x(1 + stacks/(stacks+25)); 3 stacks ≈ +11%, \
					decays ~half every 5s.",
			),
		),

		// ---------- Refracted (Sector 2) ----------

		/mob/living/simple_animal/hostile/mad_fly_nest/refracted = list(
			list(
				"title"    = "Endless Brood",
				"severity" = "high",
				"text"     = "1650 HP, immobile, never attacks, won't aggro. \
					Hatches 1 refracted fly at a time, up to 3 alive per nest, \
					roughly one every ~38 seconds (first ~8s). 3 nests this \
					node.",
			),
			list(
				"title"    = "Brood Collapse",
				"severity" = "medium",
				"text"     = "When a nest dies, all of its flies die with it. \
					The node clears only once every nest AND every fly is dead — \
					destroy the nests, don't chase flies.",
			),
			list(
				"title"    = "Tough Hide",
				"severity" = "info",
				"text"     = "While a refracted fly is burrowed inside you, your \
					own hits on any nest deal x1.5 damage — being infested is \
					the fast way to break the nests.",
			),
		),

		/mob/living/simple_animal/hostile/mad_fly_swarm/refracted = list(
			list(
				"title"    = "Swarm",
				"severity" = "low",
				"text"     = "45 HP, very fast. Basic attack is 4 hits of 1 \
					WHITE. Trivial alone; the nests never stop making more.",
			),
			list(
				"title"    = "Infest",
				"severity" = "high",
				"text"     = "On hitting a player at or below 50% sanity (and \
					off its 5s cooldown) it burrows in. Every 2 seconds inside \
					it deals 12 WHITE to your sanity. After at least 2 bites it \
					leaves once your SP is back above 50% (or instantly if you \
					die or go fully Insane), then can't re-burrow anyone for 5 \
					seconds.",
			),
		),

		/mob/living/simple_animal/hostile/clan/stone_guard/refracted = list(
			list(
				"title"    = "Charge Armor",
				"severity" = "high",
				"text"     = "520 HP. Starts at 5 charge (max 20), regains ~1/s. \
					Base damage taken RED x0.6 / WHITE x0.8 / BLACK x1.2 / PALE \
					x1.5. At 10+ charge it hardens to RED/WHITE/BLACK x0.3 / \
					PALE x0.8. Every damage instance it takes removes 1 charge — \
					burn its charge down to trigger Stagger.",
			),
			list(
				"title"    = "Stagger",
				"severity" = "medium",
				"text"     = "At 1 or less charge it Staggers: 4 seconds unable \
					to act, taking RED x1.2 / WHITE x1.6 / BLACK x2.4 / PALE x3 \
					(≈2-3x) — the burst window. Then its charge resets to 15.",
			),
			list(
				"title"    = "Hardened Stone",
				"severity" = "info",
				"text"     = "Melee is 8-11 RED and applies 3 Tremor. Its damage \
					resistances shift with its charge state — see Charge Armor \
					and Stagger.",
			),
		),

		/mob/living/simple_animal/hostile/scarlet_rose/refracted = list(
			list(
				"title"    = "Vine Gauntlet",
				"severity" = "high",
				"text"     = "1400 HP (x player count), immobile, never melees. \
					While ANY vine is within 2 tiles of it it takes only x0.15 \
					incoming; clear the vines next to it and it takes full \
					damage. It spawns surrounded by a full 5-tile vine field \
					and regrows vines — cut a lane (sharp melee cuts fastest; \
					one cut snaps up to 4 neighbours).",
			),
			list(
				"title"    = "Bloodfeast",
				"severity" = "high",
				"text"     = "Thornlash (every 9s) detonates your Bleed: deals \
					BRUTE equal to your current Bleed, then halves your Bleed; \
					repeats up to 4 times, removing Bleed once it falls to 1 or \
					less. Zero effect if you carry no Bleed — don't shove \
					through vines.",
			),
			list(
				"title"    = "Garden Collapse",
				"severity" = "low",
				"text"     = "Cannot move or attack on its own; the only \
					registered enemy here. When it dies every vine is removed \
					instantly and the node clears.",
			),
		),

		/obj/structure/spreading/scarlet_vine/refracted = list(
			list(
				"title"    = "Thornwall",
				"severity" = "medium",
				"text"     = "Blocks movement (must be forced twice to pass; ~10% \
					per forced push roots you + 5 Bleed). A sharp-edged weapon of \
					5+ force cuts it. Destroying a vine by damage snaps up to 4 \
					adjacent vines too — one good cut opens a lane.",
			),
			list(
				"title"    = "Bloodroot",
				"severity" = "info",
				"text"     = "Only 5 integrity, but armored: RED 80 (near-immune \
					to RED), BLACK 40, WHITE 0, FIRE -50 and PALE -50 (takes \
					x1.5). Use fire/PALE/sharp melee, not RED.",
			),
		),

	)
