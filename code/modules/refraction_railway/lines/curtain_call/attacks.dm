/*
 * Curtain Call mob attacks, returned by GetMobAttacks().
 * Each entry: list("name", "damage", "cooldown", "desc").
 * Same card-writing rules as Nova Flare's attacks.dm header.
 */
/datum/refraction_line/curtain_call/GetMobAttacks()
	return list(

		// ---------- zeal_s1n1: The Capo and Their Rat ----------

		/mob/living/simple_animal/hostile/thumb_east_capo/refracted = list(
			list(
				"name"     = "Lunge",
				"damage"   = "20 RED (up to +50% via **Tiantui Star**) + 1 Tremor + 2 Overheat per tile, in a 3x3 strip",
				"cooldown" = "~6 seconds; costs 1 ammo",
				"desc"     = "Marks a 3x3 strip running from the Capo through \
					the target's snapshot tile and 4 tiles further. After \
					~1.3s the strip resolves and the Capo teleports to the \
					end of the line. Stops at the first wall or water tile. \
					Tremor does not burst from this attack.",
			),
			list(
				"name"     = "Sweep",
				"damage"   = "18 RED (up to +50% via **Tiantui Star**) + 1 Tremor + 2 Overheat in a 5x5 area",
				"cooldown" = "~8 seconds; costs 1 ammo",
				"desc"     = "Melee only. Marks the 5x5 around the target's \
					snapshot tile, holds for ~0.9s, then strikes everyone \
					still inside. Capo cannot move during the wind-up. \
					Tremor on this hit detonates a stacked target (burst at 25).",
			),
			list(
				"name"     = "Leap Finisher",
				"damage"   = "35 RED (up to +50% via **Tiantui Star**) + Knockdown + 2 Tremor + 2 Overheat in a 5x5 area",
				"cooldown" = "~15 seconds; costs 2 ammo",
				"desc"     = "Picks the target's snapshot tile, marks the 5x5 \
					around it for ~1.9 seconds, then leaps in. Briefly airborne \
					(non-dense) during the jump. Tremor detonates (burst at 25).",
			),
			list(
				"name"     = "Savage Tigerslayer's Perfected Flurry of Blades",
				"damage"   = "5x (1-wide line, 15 RED + 1 Tremor + 2 Overheat per tile), then 25 RED + Knockdown + 2 Tremor + 3 Overheat in a 3x3 (all up to +50% via **Tiantui Star**)",
				"cooldown" = "~25 seconds; costs 6 ammo (a full magazine)",
				"desc"     = "Five rapid line-dashes — each one a 1-wide line \
					re-snapshotting the target's current tile so a moving \
					target can break the pattern — then a finisher whose \
					marker tracks the target for ~2 seconds, locks in place \
					for ~1.5 seconds, and lands a 3x3 Knockdown on the locked \
					tile (step off it to dodge). Only the finisher detonates \
					Tremor (burst at 25).",
			),
			list(
				"name"     = "Basic Melee",
				"damage"   = "15-20 RED + 1 Tremor + 1 Overheat",
				"cooldown" = "Replaces basic melee",
				"desc"     = "Even the Capo's plain swing tags the target with \
					Tremor; while the Capo still has rounds loaded, it also \
					stacks Overheat. Cannot burst.",
			),
		),

		/mob/living/simple_animal/hostile/rat/capo_rat/refracted = list(
			list(
				"name"     = "Hogtie",
				"damage"   = "7+1/hit melee + 4 Defense Level Down per hit, up to 8 hits",
				"cooldown" = "~12 seconds",
				"desc"     = "Telegraphs a leap (~4 seconds; rat cannot move \
					during the wind-up), then throws itself at the target. \
					On impact, pins humans for ~4 seconds and rips them up \
					to 8 times, speeding up by 0.1s and gaining +1 damage \
					each hit. Taking ~200 damage during the sequence \
					interrupts it.",
			),
		),
	)
