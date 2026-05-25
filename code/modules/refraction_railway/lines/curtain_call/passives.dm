/*
 * Curtain Call mob passives, returned by GetMobPassives().
 * Each entry: list("title", "severity", "text").
 * severity: info / low / medium / high. See AUTHORING.md Step 5b.
 *
 * Same card-writing rules as Nova Flare's passives.dm header.
 */
/datum/refraction_line/curtain_call/GetMobPassives()
	return list(

		// ---------- zeal_s1n1: The Capo and Their Rat ----------

		/mob/living/simple_animal/hostile/thumb_east_capo/refracted = list(
			list(
				"title"    = "Tiantui Ammunition",
				"severity" = "info",
				"text"     = "Carries 8 rounds; specials cost ammo (**Lunge** 1, \
					**Sweep** 1, **Leap Finisher** 2, **Flurry** 6). Rounds are \
					spent at cast, so missed specials still burn rounds.",
			),
			list(
				"title"    = "Out of Ammo",
				"severity" = "medium",
				"text"     = "With no rounds left, can only basic-melee until \
					reloaded.",
			),
			list(
				"title"    = "Star's Blade Footwork",
				"severity" = "info",
				"text"     = "**Lunge**, **Sweep** and **Leap Finisher** snapshot \
					the target's tile at cast — step off the marked tiles before \
					they resolve to dodge. **Flurry** re-snapshots between hits.",
			),
			list(
				"title"    = "Heat From the Magazine",
				"severity" = "medium",
				"text"     = "Every strike applies Tremor. While the Capo still \
					has rounds in the magazine, every strike also applies \
					Overheat — so emptying the magazine cools the pressure.",
			),
			list(
				"title"    = "Tremor Burst",
				"severity" = "high",
				"text"     = "Only **Sweep**, **Leap Finisher**, and the **Flurry** \
					finisher detonate Tremor (burst threshold 25). Every other \
					strike stacks Tremor without bursting.",
			),
			list(
				"title"    = "Tiantui Star",
				"severity" = "high",
				"text"     = "Below 60% HP: its specials deal more damage the \
					lower its HP — scaling with missing HP up to +25% ability \
					damage near death (e.g. +10% at 40% missing) — and while it \
					has ammo every Overheat infliction is +1. Below 40% HP this \
					becomes Shin - Tiantui Star: the cap rises to +50% ability \
					damage, and every infliction gains +2 Tremor and +2 \
					Overheat. The damage bonus applies only to its specials, \
					never its basic melee.",
			),
		),

		/mob/living/simple_animal/hostile/rat/capo_rat/refracted = list(
			list(
				"title"    = "Pet of the Family",
				"severity" = "info",
				"text"     = "Every melee bite applies 3 Defense Level Down.",
			),
			list(
				"title"    = "Reload Run",
				"severity" = "medium",
				"text"     = "When the **Thumb East Capo** is out of ammo, the \
					rat stops fighting, runs to its reload point, picks up a \
					package, and runs the package back — reaching the Capo \
					refills its magazine. Killing the rat mid-run leaves the \
					Capo dry.",
			),
			list(
				"title"    = "Plays Dead",
				"severity" = "high",
				"text"     = "At 1 HP it falls down, takes no damage, and gets \
					back up after 10 seconds at full HP. If the **Thumb East \
					Capo** runs dry while it is down, it springs up early at \
					half HP to run a reload.",
			),
		),

		// ---------- zeal_s1n2: Azarus, the House ----------

		/mob/living/simple_animal/hostile/azarus/refracted = list(
			list(
				"title"    = "The Table",
				"severity" = "info",
				"text"     = "Azarus scatters oversized dice across the floor, \
					each starting on 1. Shoot or strike one to make it spin ~3 \
					seconds and land on a random face. A die that lands slams \
					the floor for BLACK in a small area - bigger on a high roll - \
					so rolling is a risk as well as a reward.",
			),
			list(
				"title"    = "Lock on a Six",
				"severity" = "medium",
				"text"     = "A die that lands on 6 locks and can't be re-rolled. \
					Other dice can be hit again to gamble higher - but Azarus's \
					own blasts knock any die showing 4 or more loose for a fresh \
					spin, so a good table isn't safe.",
			),
			list(
				"title"    = "The Wager",
				"severity" = "high",
				"text"     = "On a timer (the red number over its head), Azarus \
					calls an unavoidable, room-wide PALE hit. Its damage drops \
					with the table total (the gold number); max the table out \
					and the House **busts** - the Wager whiffs and Azarus is left \
					staggered and wide open.",
			),
			list(
				"title"    = "Stalling the Bet",
				"severity" = "medium",
				"text"     = "Every die that lands pushes the Wager's countdown \
					back a little (it can't be held more than ~20 seconds out), \
					while hitting Azarus rushes it. After a Wager resolves the \
					whole table is swept away for ~15 seconds before fresh dice \
					are dealt.",
			),
			list(
				"title"    = "Raising the Stakes",
				"severity" = "high",
				"text"     = "At or below 50% HP Azarus forces any pending Wager \
					off at once, then doubles down: more dice, a higher score to \
					bust, a faster Wager, and four stationary mirror-doubles. Each \
					mirror has a quarter of the House's HP and echoes its attacks; \
					shatter them to cut the extra pressure.",
			),
		),

		// ---------- zeal_s2n1: The Envy of Humanity ----------

		/mob/living/simple_animal/hostile/understudy = list(
			list(
				"title"    = "Wears a Face",
				"severity" = "info",
				"text"     = "On spawn: dons a random form from the city roster \
					(Ronin, Butcher, Scavenger, Kurokumo Captain, Big Brother, \
					Grosshammer, Messenger, Dieci, Zwei, Shi, Liu, Seven, \
					Devyat) and fights through it. Has no basic melee of its \
					own; the worn form does the attacking.",
			),
			list(
				"title"    = "Untouchable While Worn",
				"severity" = "medium",
				"text"     = "While wearing a form: cannot be targeted, hit, or \
					moved. All damage and crowd-control land on the worn form \
					instead. The worn form keeps its gear locked in-hand, takes \
					~250 HP to break (~375 for the phase-2 faces), and is \
					immune to stun, knockback, and sleep.",
			),
			list(
				"title"    = "Stripped Bare",
				"severity" = "high",
				"text"     = "On the worn form's death: emerges on its tile, \
					takes 300 BRUTE chip, stays visible and damageable for \
					~5 seconds, then dons a new face.",
			),
			list(
				"title"    = "Threadbare",
				"severity" = "high",
				"text"     = "Each Stripped Bare worsens its resistances by one \
					tier (cap 5). RED / WHITE / BLACK / PALE: \
					0.6/0.6/0.4/0.8 → 0.8/0.8/0.6/1.0 → 1.0/1.0/0.8/1.2 → \
					1.25/1.25/1.0/1.5 → 1.5/1.5/1.25/2.0.",
			),
			list(
				"title"    = "Carry-Over HP",
				"severity" = "info",
				"text"     = "On a form rotation (not death): the new form \
					spawns at full HP, then takes BRUTE equal to the previous \
					form's missing HP (capped to leave at least 1 HP). Faces \
					after the first don't reset the boss's effective HP.",
			),
			list(
				"title"    = "Phase 2: Final Faces",
				"severity" = "high",
				"text"     = "Below 25% HP: HP cannot drop further until phase 2 \
					triggers. The attack that would cross the floor caps damage \
					there and swaps the form pool from city skins to three \
					hostile cabals (**Red Mist**, **Black Silence**, **Blue \
					Reverberation**). Each phase-2 face stays for a fixed \
					number of abilities before rotating: Red Mist and Blue \
					Reverberation 5, Black Silence 10.",
			),
			// ---------- Phase-2 form passives ----------
			list(
				"title"    = "Red Mist — The Strongest",
				"severity" = "low",
				"text"     = "While worn: moves at roughly 4x the city-skin pace.",
			),
			list(
				"title"    = "Black Silence — Honed Edge",
				"severity" = "medium",
				"text"     = "After each ability resolves: gains 8 Offense Level Up.",
			),
			list(
				"title"    = "Black Silence — Weapon Rotation",
				"severity" = "medium",
				"text"     = "Cycles 9 workshop weapons + Furioso in fixed order: \
					Zelkova → Ranga → Old Boys → Allas → Mook → Logic → \
					Durandal → Crystal → Wheels → **Furioso**. The held weapon \
					icon visibly swaps each slot.",
			),
			list(
				"title"    = "Black Silence — Spent After Furioso",
				"severity" = "high",
				"text"     = "On the resolve of **Furioso**: force-morphs to a \
					new face regardless of damage taken.",
			),
			list(
				"title"    = "Blue Reverberation — Resonant Hum",
				"severity" = "medium",
				"text"     = "Every 8 seconds: applies 1 Vibration to every enemy \
					within 5 tiles.",
			),
		),

		// ---------- zeal_s2n2: The Greed Touched Clone ----------

		/mob/living/simple_animal/hostile/greed_touched_eric/refracted = list(
			list(
				"title"    = "Greed Touched",
				"severity" = "info",
				"text"     = "Doesn't strike on his own. Spawns waves of \
					followers — **X-Corp fixers in phase 1**, **greed-touched \
					clan units in phase 2** — **3 per wave every 12s**, \
					**capped at 6 alive**. Each kill beams blood back to \
					him: **+(maxHealth ÷ 3) bloodfeast** per kill (a 180-HP \
					scout = 60; a 550-HP defender = 183). If **20s pass \
					with no minion death**, the next wave size **doubles**.",
			),
			list(
				"title"    = "Unholy Presence",
				"severity" = "info",
				"text"     = "In phases 1 and 2 he creeps toward whoever \
					he's locked onto at **~1.6 seconds per tile** and tries \
					to settle **1 tile away (adjacent)**. He never swings — \
					being adjacent is just where he channels his ranged \
					feast from.",
			),
			list(
				"title"    = "Bloodfeast Shield",
				"severity" = "high",
				"text"     = "**Subtracts up to 150 raw damage** from every \
					hit. Almost every workshop weapon bounces clean off \
					him while his pool is full; only very heavy crits chip \
					through. The subtracted amount scales linearly with \
					his bloodfeast pool: **150 at a full pool, 0 when \
					empty**. **Killing his summons is the way to drop the \
					shield** — direct DPS is wasted until the pool empties \
					out (or a Greed Burst forces the window).",
			),
			list(
				"title"    = "Sanguine Feast",
				"severity" = "high",
				"text"     = "Marks the tile under **every human player in \
					view (7 tiles)**, then **locks in place for 4s** while \
					the markers resolve. On resolve a blood tendril rises \
					through each marked tile and spikes whatever stands on \
					it: **120 RED + 3 Bleed** to a human; any **non-human \
					mob with under 800 max HP** on the tile is **executed \
					instantly** and feeds him **+(its maxHealth ÷ 2) \
					bloodfeast** — easily 200+ blood if multiple summons \
					get caught. **30s cooldown.**",
			),
			list(
				"title"    = "Greed Burst",
				"severity" = "high",
				"text"     = "When his pool fills (**700 in P1, 500 in \
					P2**): **2s telegraph**, then a **room-wide pulse for \
					30 RED + 2 Bleed** (every enemy in view 8 tiles, \
					unavoidable), AND every live follower **bursts in place \
					for 50 RED + 2 Bleed in a 3×3** around them (avoidable \
					by spacing). After the burst his shield drops for \
					**6s** — the window to push damage.",
			),
			list(
				"title"    = "The Famine",
				"severity" = "high",
				"text"     = "Below 50% HP: the X-Corp roster gives way to \
					the **greed-touched clan** (defender, gunner, sniper, \
					harpooner, drone, scout). His **bloodfeast cap drops \
					from 700 to 500**, so bursts come noticeably faster. \
					Wave cadence and vulnerable window length are unchanged.",
			),
			list(
				"title"    = "Hardblood Greed",
				"severity" = "high",
				"text"     = "Below 25% HP: **summons stop entirely** and \
					his shield **permanently collapses** (blood_resistance \
					forced to 0). On a **10s cycle** he teleport-strikes \
					the closest target **3 times in a row, 1s between \
					strikes**: each lands **90 RED + 3 Bleed + 1s \
					Knockdown**. Knockdown chains into the next teleport, \
					so missing a dodge floors you for the follow-up. \
					Alternates with **Sanguine Rush** (15s cooldown), a \
					three-dash bloody charge along a 3x3 strip.",
			),
			list(
				"title"    = "Glutted",
				"severity" = "medium",
				"text"     = "If **two Greed Bursts** fire without him \
					taking any HP damage in the windows between them, the \
					**next burst's room-wide pulse doubles (30 → 60 RED)**. \
					Resets the moment he takes damage during a window.",
			),
		),
	)
