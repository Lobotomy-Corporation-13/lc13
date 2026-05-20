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
				"damage"   = "20 RED + 4 Tremor per tile in a line up to 5 tiles",
				"cooldown" = "~6 seconds; costs 1 ammo",
				"desc"     = "Marks every tile in a line up to 5 tiles toward \
					where the target was, then dashes through them; anything \
					still standing on a marked tile takes the hit.",
			),
			list(
				"name"     = "Sweep",
				"damage"   = "18 RED + 2 Tremor in a 3x3 area",
				"cooldown" = "~8 seconds; costs 1 ammo",
				"desc"     = "Picks the target's tile, marks the 3x3 around it, \
					then strikes everyone still inside.",
			),
			list(
				"name"     = "Leap Finisher",
				"damage"   = "35 RED + Knockdown in a 5x5 area; 3 Tremor",
				"cooldown" = "~15 seconds; costs 2 ammo",
				"desc"     = "Picks the target's tile, marks the 5x5 around it \
					for ~1.5 seconds, then leaps in. Briefly airborne \
					(non-dense) during the jump.",
			),
			list(
				"name"     = "Savage Tigerslayer's Perfected Flurry of Blades",
				"damage"   = "5x (15 RED + 2 Tremor on the target's tile), then 25 RED + Knockdown in a 3x3",
				"cooldown" = "~25 seconds; costs 6 ammo (a full magazine)",
				"desc"     = "Six rapid hits, each re-snapshotting the target's \
					current tile so a moving target can break the pattern. \
					First five are single-tile; the sixth is the burst finisher.",
			),
		),

		/mob/living/simple_animal/hostile/rat/capo_rat/refracted = list(
			list(
				"name"     = "Dash",
				"damage"   = "12 RED + Knockdown per tile in a line up to 5 tiles",
				"cooldown" = "~12 seconds",
				"desc"     = "Marks a straight line up to 5 tiles toward the \
					target, then charges through it tile by tile; anything \
					still on a marked tile takes the hit.",
			),
		),
	)
