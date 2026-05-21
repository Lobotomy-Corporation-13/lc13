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
	)
