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

		// ---------- zeal_s1n2: Azarus, the House ----------

		/mob/living/simple_animal/hostile/azarus/refracted = list(
			list(
				"name"     = "Ante Up",
				"damage"   = "No direct damage; scatters 5 dice (9 in phase 2)",
				"cooldown" = "Fight start, ~15s after each Wager, and on phase change",
				"desc"     = "Flings oversized dice across the floor, kept apart \
					and each starting on 1. Shoot or strike a die to spin it ~3s \
					onto a random face; its face counts toward the table total. A \
					6 locks and can't be re-rolled.",
			),
			list(
				"name"     = "Loaded Dice",
				"damage"   = "BLACK in a 3x3, scaling with the face (5x5 on a 6)",
				"cooldown" = "Whenever a spun die lands",
				"desc"     = "Every die slams the floor when it lands - the higher \
					it rolls, the harder it hits and the wider the blast. Rolling \
					can also tempt the dealer into a **Snake Eyes**.",
			),
			list(
				"name"     = "The Wager",
				"damage"   = "Up to 200 PALE, room-wide and unavoidable; reduced by the table total",
				"cooldown" = "~40s (~30s in phase 2); each landing adds time (cap ~20s out), and hitting Azarus rushes it",
				"desc"     = "A ~6s call (Azarus raises its hands and the screen \
					flashes), then an unavoidable hit to everyone in the room. \
					Damage scales down with the table total - reach the target \
					score and the House busts for near-zero, leaving Azarus \
					staggered for ~5 seconds. The red/gold numbers over its head \
					are the countdown and the current score.",
			),
			list(
				"name"     = "Snake Eyes",
				"damage"   = "35 BLACK in a 3x3 area",
				"cooldown" = "~10 seconds",
				"desc"     = "Flicks a die at the target's tile; after a short \
					telegraph it lands in a 3x3 blast. Step off the marked tiles \
					to dodge. The blast also knocks any die showing 4+ loose for \
					a fresh spin.",
			),
			list(
				"name"     = "House Edge",
				"damage"   = "30 BLACK + knockback in a 5x5 area",
				"cooldown" = "~12 seconds",
				"desc"     = "When players crowd into melee, Azarus telegraphs a \
					5x5 sweep around itself, then strikes and knocks survivors \
					back. Also knocks any die showing 4+ loose for a fresh spin.",
			),
			list(
				"name"     = "Mirror Gambit",
				"damage"   = "No direct damage; each mirror has ~25% of Azarus's max HP",
				"cooldown" = "Once, on entering phase 2",
				"desc"     = "Conjures four stationary mirror-doubles. They never \
					move or melee - they only echo its **Snake Eyes** and **House \
					Edge** a beat after it casts them. Shatter a mirror to stop \
					its echo.",
			),
		),

		// ---------- zeal_s2n1: The Envy of Humanity (form specials) ----------

		/mob/living/simple_animal/hostile/understudy = list(
			list(
				"name"     = "Yield My Flesh (Ronin form)",
				"damage"   = "26 RED along the line, scaling up to ~78 the lower the form's own HP",
				"cooldown" = "~9 seconds",
				"desc"     = "Copies the Blade Lineage katana: a rooted wind-up, \
					then a lunge down a short line that hits harder the closer the \
					skin is to breaking. Step off the line to dodge.",
			),
			list(
				"name"     = "Meat Hook (Butcher form)",
				"damage"   = "28 RED + drag-in",
				"cooldown" = "~10 seconds",
				"desc"     = "Marks a line, then yanks the first person on it back \
					to the form and bites them. Step off the line to dodge.",
			),
			list(
				"name"     = "Junk Lob (Scavenger form)",
				"damage"   = "24 RED in a 3x3 area",
				"cooldown" = "~7 seconds",
				"desc"     = "Hurls debris at the target's tile, marking a 3x3 \
					before it lands. Leave the marked tiles to dodge.",
			),
			list(
				"name"     = "Poise Strike (Kurokumo Captain form)",
				"damage"   = "72 RED (a guaranteed 3x crit) in a wide arc",
				"cooldown" = "~9 seconds",
				"desc"     = "Copies the kurokumo blade's poise: the payoff of a \
					built-up critical, released as a telegraphed two-deep arc in \
					front. Don't stand ahead of it.",
			),
			list(
				"name"     = "Family Comes First (Big Brother form)",
				"damage"   = "45 BLACK + throw + knockdown on the counter",
				"cooldown" = "~11 seconds",
				"desc"     = "Copies the Middle chain: enters a ~2.5s purple guard \
					stance. The first hit it takes during the stance is blocked \
					and countered - it lashes the attacker, throws them clear, and \
					blinks to a shooter first. Don't hit it while it's guarding.",
			),
			list(
				"name"     = "Mark & Detonate (Grosshammer form)",
				"damage"   = "32 BLACK on every marked tile, all at once",
				"cooldown" = "~11 seconds",
				"desc"     = "Copies the N Corp nail + hammer: drops a mark on each \
					nearby target's tile, then slams to detonate every mark \
					simultaneously. Step off your mark to dodge.",
			),
			list(
				"name"     = "Prescript (Index Messenger form)",
				"damage"   = "34 BLACK in a 3x3 (x1.45 vs a target already below half HP)",
				"cooldown" = "~10 seconds",
				"desc"     = "Copies the Index greatsword's execute: marks a tile, \
					then a heavy slam that hits far harder if the marked victim is \
					already wounded. Leave the marked tiles to dodge.",
			),
			list(
				"name"     = "Grand Finale (Dieci form)",
				"damage"   = "24 PALE + 4 Sinking + knockback, 5x5 around itself",
				"cooldown" = "~9 seconds",
				"desc"     = "Copies the Dieci finisher: a PALE shockwave that throws \
					everyone nearby outward and stacks Sinking. Back out of the \
					ring before it lands.",
			),
		),
	)
