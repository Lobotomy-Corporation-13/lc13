/*
 * Nova Flare mob passives, returned by GetMobPassives().
 * Each entry: list("title", "severity", "text").
 * severity: info / low / medium / high. See AUTHORING.md Step 5b.
 *
 * Card-writing rules (see AUTHORING.md):
 *  - The card UI already shows the mob's data sheet (HP, move speed,
 *    resistance row, melee damage + type + cadence, ranged details).
 *    For mobs with 0/0 melee the data sheet renders "no basic melee
 *    attack" automatically. Never restate any of that in a card —
 *    including qualitative paraphrases ("fast", "fragile", "tanky") or
 *    a redundant "no melee" / "never attacks" line. Saying a mob is
 *    "immobile" / "can't move" IS allowed (the data sheet's move-delay
 *    row doesn't make immobility obvious).
 *  - Never state a mob's HP pool or basic-melee damage numbers nor its
 *    melee damage TYPE, nor any player-count / railway scaling. Say
 *    only what its melee INFLICTS (status / mechanical effect, e.g.
 *    "applies 3 Tremor"). Percentage thresholds are fine.
 *  - Never re-explain a status the glossary defines (Bleed, Tremor, RED
 *    Fragile, Defense Level Down, ...). Name it; the hover does the rest.
 *  - Never repeat what another card says, and never spell out the synergy
 *    between cards. State each effect once; refer to other cards by name,
 *    wrapping the referenced card name in **double asterisks** so it
 *    renders bold.
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
				"text"     = "While attacking at 25% HP or below, 75% chance per attack to trigger **Self-Destruct**.",
			),
			list(
				"title"    = "Zealous Squadmate",
				"severity" = "low",
				"text"     = "When **Self-Destruct** goes off, every Steel Dawn within 7 tiles \
					becomes Zealous (won't retreat anymore) and is healed to nearly full. Any \
					Steel Manager within 7 tiles speeds up its next Screech (5 seconds → 3 \
					seconds). If the Steel Corporal dies without triggering **Self-Destruct**, no \
					buff is applied.",
			),
			list(
				"title"    = "Vigor on Strike",
				"severity" = "info",
				"text"     = "Heals for every melee hit it lands.",
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
					75% chance per attack to trigger **Self-Destruct**. **Air Sweep** replaces some \
					attacks, so the trigger rolls less often.",
			),
			list(
				"title"    = "Zealous Squadmate",
				"severity" = "low",
				"text"     = "Inherited from Steel Corporal. When **Self-Destruct** goes off, every \
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
					speeds up. Also delays the Manager's own next **Screech** by 10 seconds.",
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
				"text"     = "Its only way to deal damage is **Echoing Scream**.",
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
					a counter drops from 500 to 300, and **Love Whip** becomes available.",
			),
			list(
				"title"    = "Retaliation",
				"severity" = "medium",
				"text"     = "Tracks total damage taken. Once it has taken 500 damage (or 300 \
					in Stage 2), it immediately retaliates: triggers **Bullrush** (Stage 1, always) \
					or one of **Love Whip** (Stage 2, 80%) / **Bullrush** (Stage 2, 20%). The damage \
					counter resets after each retaliation, then starts ticking again.",
			),
			list(
				"title"    = "Stage 2 Vigor",
				"severity" = "medium",
				"text"     = "In Stage 2, heals for every melee attack it lands.",
			),
			list(
				"title"    = "Birthing Pool",
				"severity" = "low",
				"text"     = "On death, always spawns 2 Lovetown Suicidals at adjacent open tiles.",
			),
		),

		// ---------- Refracted (Sector 1) ----------

		/mob/living/simple_animal/hostile/mutant_clown/refracted = list(
			list(
				"title"    = "Mask Break",
				"severity" = "high",
				"text"     = "Stage 1: keeps ~6 tiles away. Damage taken RED x1.4 \
					/ WHITE x0.6 / BLACK x0.8 / PALE x2. At 50% HP the mask \
					breaks: 2.5 seconds taking x0.2 from everything, then \
					permanently Stage 2 — can no longer be kept at range, moves \
					faster, its basic attack becomes **Slam**, and damage taken \
					becomes RED x1.6 / WHITE x0.6 / BLACK x0.8 / PALE x2. Never \
					reverts. The other clowns share this break window and \
					Stage-2 profile.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_clown/refracted/sister = list(
			list(
				"title"    = "Mask Break",
				"severity" = "high",
				"text"     = "Frail. Keeps ~8 tiles away. Its mask breaks only at \
					25% HP (after losing 75%), so it stays in ranged Stage 1 \
					almost the whole fight. Same break window and Stage-2 \
					profile as the Refracted Clown's **Mask Break**.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_clown/refracted/mother = list(
			list(
				"title"    = "Mask Break",
				"severity" = "high",
				"text"     = "Never retreats. Its mask breaks at 75% HP (after \
					losing only 25%), so it enters Stage 2 almost immediately. \
					Same break window and Stage-2 profile as the Refracted \
					Clown's **Mask Break**.",
			),
		),

		/mob/living/simple_animal/hostile/mutant_clown/boss/refracted = list(
			list(
				"title"    = "Beating Hearts",
				"severity" = "high",
				"text"     = "Spawns ringed by 4 hearts. While ANY heart lives \
					it cannot move and takes 0 damage; with all 4 dead it \
					becomes vulnerable.",
			),
			list(
				"title"    = "The Whole Family",
				"severity" = "high",
				"text"     = "While the hearts live, every **Wail** also summons \
					reinforcement clowns and it uses **Meat Drop** on nearby \
					players. Once every heart is destroyed, **Wail** stops \
					summoning and **Meat Drop** becomes **Meat Barrage**. See \
					those attacks.",
			),
			list(
				"title"    = "Broken Mask",
				"severity" = "high",
				"text"     = "Once the hearts are gone it can move. At 50% HP the \
					mask breaks with the same window and Stage-2 profile as the \
					Refracted Clown's **Mask Break**, and it begins **Grief \
					Stomp** (see attacks).",
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
				"text"     = "Immobile. Gates the Grandfather's **Beating \
					Hearts** — see that passive.",
			),
			list(
				"title"    = "Backlash Shell",
				"severity" = "high",
				"text"     = "Takes x0.5 from projectiles. Its **Backlash** \
					pulses 3 Defense Level Down onto EVERY living thing within 2 \
					tiles — players, the boss and the clowns alike — whenever \
					it is hurt. See the **Backlash** attack.",
			),
		),

		// ---------- Refracted (Sector 2) ----------

		/mob/living/simple_animal/hostile/mad_fly_nest/refracted = list(
			list(
				"title"    = "Endless Brood",
				"severity" = "high",
				"text"     = "Immobile, won't aggro. Hatches 1 refracted fly \
					every ~16 seconds, capped at 1 alive per nest (the \
					first hatch is almost immediate).",
			),
			list(
				"title"    = "Rupturing Brood",
				"severity" = "high",
				"text"     = "Every time a nest loses another 33% of its max HP \
					it ruptures, bursting 1 extra fly on the spot — capped at \
					the nest's 1-fly limit, so the burst is suppressed while a \
					fly is still alive. At most one burst per 10 seconds.",
			),
			list(
				"title"    = "Caustic Hide",
				"severity" = "medium",
				"text"     = "Every hit you land on a nest leaves you WHITE \
					Fragile, scaling with how hurt the nest is: 1 stack near \
					full, up to 5 once it has lost 90% of its max HP.",
			),
			list(
				"title"    = "Brood Collapse",
				"severity" = "medium",
				"text"     = "When a nest dies, all of its flies die with it.",
			),
			list(
				"title"    = "Tough Hide",
				"severity" = "info",
				"text"     = "While a refracted fly is burrowed inside you, your \
					own hits on any nest deal x1.5 damage.",
			),
		),

		/mob/living/simple_animal/hostile/mad_fly_swarm/refracted = list(
			list(
				"title"    = "Infest",
				"severity" = "high",
				"text"     = "On hitting a player at or below 50% sanity (and \
					off its 5s cooldown) it burrows in. Every 2 seconds inside \
					it deals 12 RED. After at least 2 bites it leaves once your \
					SP is back above 50% (or instantly if you die or go fully \
					Insane), then can't re-burrow anyone for 5 seconds.",
			),
		),

		/mob/living/simple_animal/hostile/clan/stone_guard/refracted = list(
			list(
				"title"    = "Charge Armor",
				"severity" = "high",
				"text"     = "Starts at 10 charge (max 20), regains ~1/s. Base \
					damage taken RED x0.6 / WHITE x0.8 / BLACK x1.2 / PALE x1.5. \
					At 10+ charge it hardens to RED/WHITE/BLACK x0.3 / PALE x0.8. \
					Every damage instance it takes removes 1 charge, and a \
					missed **Transpierce** costs 5. At 1 or less charge it \
					enters **Stagger**.",
			),
			list(
				"title"    = "Stagger",
				"severity" = "medium",
				"text"     = "At 1 or less charge it Staggers: 4 seconds unable \
					to act, taking RED x1.2 / WHITE x1.6 / BLACK x2.4 / PALE x3 \
					(≈2-3x). Then its charge resets to 15.",
			),
			list(
				"title"    = "Hardened Stone",
				"severity" = "info",
				"text"     = "Its melee applies 2 Tremor. Its damage resistances \
					shift with its charge state — see **Charge Armor** and \
					**Stagger**.",
			),
			list(
				"title"    = "Fault Line",
				"severity" = "high",
				"text"     = "Striking a target carrying 30 or more Tremor flips \
					its melee from RED to BLACK on that strike.",
			),
		),

		/mob/living/simple_animal/hostile/scarlet_rose/refracted = list(
			list(
				"title"    = "Vine Gauntlet",
				"severity" = "high",
				"text"     = "Immobile. Takes 5% less incoming damage for every \
					refracted vine within 2 tiles of it, stacking up to a 40% \
					cap (8+ vines); with no vines next to it, full damage. It \
					spawns surrounded by a full 5-tile vine field and regrows \
					them. See the vine's **Thornwall**.",
			),
			list(
				"title"    = "Garden Collapse",
				"severity" = "low",
				"text"     = "When it dies, every vine it spread is removed \
					instantly.",
			),
			list(
				"title"    = "Thornwall",
				"severity" = "medium",
				"text"     = "Its vines block movement (forced twice to pass), \
					and a vine that grows onto your tile applies 4 Bleed. A \
					sharp 5+ force weapon cuts a vine; destroying one by damage \
					snaps up to 4 adjacent vines too. Shoving through instead of \
					cutting risks Bleed (see the **Tangle** attack).",
			),
			list(
				"title"    = "Bloodroot",
				"severity" = "info",
				"text"     = "Each vine has only 5 integrity but is armored: RED \
					80 (near-immune to RED), BLACK 40, WHITE 0, FIRE -50 and \
					PALE -50 (takes x1.5).",
			),
		),

		// ---------- Refracted (Sector 3) ----------

		/mob/living/simple_animal/hostile/clan/scout/refracted = list(
			list(
				"title"    = "Charge",
				"severity" = "info",
				"text"     = "Starts at 5 charge, max 10. Gains 1 every 2 \
					seconds.",
			),
			list(
				"title"    = "Overclock",
				"severity" = "medium",
				"text"     = "The more charge it has, the faster it moves and \
					the more times its basic attack lands per swing (up to 4 \
					hits per swing). Each hit it lands spends 2 charge.",
			),
		),

		/mob/living/simple_animal/hostile/clan/defender/refracted = list(
			list(
				"title"    = "Charge",
				"severity" = "info",
				"text"     = "Starts at 5 charge, max 10. Gains 1 every 2 \
					seconds (paused while locked).",
			),
			list(
				"title"    = "Lockdown",
				"severity" = "high",
				"text"     = "At full charge (10), on its next melee, it plants \
					and projects a field that roots everything within 2 tiles \
					(they cannot move away from it). For ~10 seconds it cannot \
					move; resistances shift from RED x0.6 / WHITE x0.8 / BLACK \
					x1.2 / PALE x1.5 to RED/WHITE/BLACK x0.4 / PALE x1.0. When \
					the lock ends its charge resets to 0.",
			),
		),

		/mob/living/simple_animal/hostile/clan/drone/refracted = list(
			list(
				"title"    = "Charge",
				"severity" = "info",
				"text"     = "Starts at 10 charge, max 20. Gains 1 every 1 \
					second.",
			),
			list(
				"title"    = "Mender",
				"severity" = "high",
				"text"     = "Targets only clan allies, never players. Locks a \
					heal beam onto the most-wounded clan ally within ~6 tiles, \
					healing it every tick and feeding it 1 charge per tick.",
			),
			list(
				"title"    = "Emergency Repairs",
				"severity" = "medium",
				"text"     = "When its beam target drops to 20% HP or below, \
					it dumps its charge into them as a burst heal (charge x 25 \
					— up to 500 at full charge). 5-second cooldown.",
			),
		),

		/mob/living/simple_animal/hostile/clan/ranged/gunner/refracted = list(
			list(
				"title"    = "Charge",
				"severity" = "info",
				"text"     = "Starts at 10 charge, max 20. Gains 1 every 2 \
					seconds. **Burst Fire** costs 5 charge.",
			),
		),

		/mob/living/simple_animal/hostile/clan/ranged/rapid/refracted = list(
			list(
				"title"    = "Charge",
				"severity" = "info",
				"text"     = "Starts at 10 charge, max 20. Gains 1 every 2 \
					seconds. **Overdrive** costs 5 charge.",
			),
		),

		/mob/living/simple_animal/hostile/clan/ranged/harpooner/refracted = list(
			list(
				"title"    = "Charge",
				"severity" = "info",
				"text"     = "Starts at 10 charge, max 20. Gains 1 every 2 \
					seconds. **Harpoon** costs 20 charge.",
			),
		),

		/mob/living/simple_animal/hostile/keeper_piller/refracted = list(
			list(
				"title"    = "Mimic Pillar",
				"severity" = "medium",
				"text"     = "Immobile. On arrival it drops from above, RED to \
					everything beneath it. Dies when the boss dies.",
			),
		),

		/mob/living/simple_animal/hostile/clan/stone_keeper/refracted = list(
			list(
				"title"    = "Entrance",
				"severity" = "low",
				"text"     = "On encounter start it drops from above, RED to \
					everything beneath it.",
			),
			list(
				"title"    = "Charge",
				"severity" = "info",
				"text"     = "Starts at 15 charge, max 20. Gains 1 every 30 \
					seconds. Each hit it takes spends 1 charge.",
			),
			list(
				"title"    = "Charge Shield",
				"severity" = "high",
				"text"     = "While its charge is 5 or more it is shielded: \
					damage taken RED/WHITE/BLACK x0.1 / PALE x0.5. While its \
					charge is under 5 it is bare: damage taken RED x0.6 / \
					WHITE x0.8 / BLACK x1.2 / PALE x1.5.",
			),
			list(
				"title"    = "The Pillars",
				"severity" = "high",
				"text"     = "Below half HP it raises area-denial **Mimic \
					Pillar**s at fixed points around the arena. When it dies, \
					every pillar it raised falls with it.",
			),
			list(
				"title"    = "Mine Scatter",
				"severity" = "medium",
				"text"     = "After every **Slam** it scatters 2-3 blue \
					**Keeper Mine**s onto random open tiles within 2 tiles of \
					itself. After every **Annihilation Beam** it scatters 7 \
					mines onto random open tiles within 3 tiles of itself. On \
					taking projectile damage it also drops 1 mine within 2 \
					tiles (1-second cooldown). Each mine lasts 30 seconds. \
					Stacking is allowed but uncommon — the first roll on an \
					already-mined tile re-rolls once.",
			),
			list(
				"title"    = "Keeper Mine",
				"severity" = "medium",
				"text"     = "Falls in from above on spawn and is only \
					triggerable after ~0.5 seconds. If a player then steps \
					within 1 tile of one, the mine hops up, beeps for ~1 \
					second, then explodes at the start of its descent for 30 \
					PALE in the 3x3 area around where it stood and \
					disappears. Each target hit gains 3 PALE Fragile, or +1 \
					above their current stack if they already have it.",
			),
		),

	)
