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

		// ---------- zeal_s2n1: The Envy of Humanity (form attacks) ----------

		/mob/living/simple_animal/hostile/understudy = list(
			// ---------- City roster (phase 1) ----------
			list(
				"name"     = "Yield My Flesh (Ronin form)",
				"damage"   = "On the riposte: 40 RED + 3 Bleed on the attacker, scaling up to 120 the lower the form's HP",
				"cooldown" = "9 seconds; 2.5s parry window",
				"desc"     = "Enters a 2.5s parry stance (deep-red tint), \
					rooted. First melee or ranged hit landed during the \
					window is consumed and triggers the counter (blinks to a \
					ranged shooter first). The counter scales inversely with \
					the form's current HP — 40 at full HP, up to 120 near \
					death. If no hit lands, the stance ends without a counter.",
			),
			list(
				"name"     = "Backstab (Butcher form)",
				"damage"   = "28 RED in a 5x5 around the form's landing tile",
				"cooldown" = "10 seconds",
				"desc"     = "Blinks to the tile directly behind the target. \
					Telegraphs the 5x5 around the form's new tile, 1.4s \
					wind-up, then resolves.",
			),
			list(
				"name"     = "Junk Lob (Scavenger form)",
				"damage"   = "24 RED in a 5x5 on the target's snapshot tile",
				"cooldown" = "7 seconds",
				"desc"     = "Telegraphs the 5x5 around the target's current \
					tile, 0.8s wind-up, then resolves.",
			),
			list(
				"name"     = "Poise Strike (Kurokumo Captain form)",
				"damage"   = "72 RED in a 3-deep forward arc (the kurokumo blade's built-in 3x crit baked in)",
				"cooldown" = "9 seconds",
				"desc"     = "Rooted 1.4s wind-up. Telegraphs a 3-deep arc in \
					the form's facing direction, then resolves.",
			),
			list(
				"name"     = "Family Comes First (Big Brother form)",
				"damage"   = "On the riposte: 45 BLACK + throw 3 tiles + Knockdown 1s on the attacker, plus 18 BLACK + Knockdown 1s in a 3x3 around the form",
				"cooldown" = "11 seconds; 2.5s parry window",
				"desc"     = "Enters a 2.5s parry stance (purple tint), rooted. \
					First melee or ranged hit landed during the window is \
					consumed and triggers the counter (blinks to a ranged \
					shooter first). If no hit lands, the stance ends without \
					a counter.",
			),
			list(
				"name"     = "Mark & Detonate (Grosshammer form)",
				"damage"   = "32 BLACK in a 3x3 around each marked target's snapshot tile, all detonating simultaneously",
				"cooldown" = "11 seconds",
				"desc"     = "Marks every living enemy within 8 tiles (one mark \
					per enemy). 0.8s wind-up, then every marked 3x3 detonates \
					together.",
			),
			list(
				"name"     = "Prescript (Index Messenger form)",
				"damage"   = "34 BLACK (x1.45 on a target under 50% HP) in a 5x5 on the marked tile",
				"cooldown" = "10 seconds",
				"desc"     = "Rooted 0.8s wind-up. Telegraphs the 5x5 around the \
					target's snapshot tile, then resolves.",
			),
			list(
				"name"     = "Grand Finale (Dieci form)",
				"damage"   = "24 PALE + 4 Sinking + throw outward, in a 7x7 around the form",
				"cooldown" = "9 seconds",
				"desc"     = "Telegraphs the 7x7 around the form's current tile, \
					2s wind-up, then resolves.",
			),
			list(
				"name"     = "Shield Charge (Zwei form)",
				"damage"   = "Dash: 26 RED in the 3-wide path. Shockwave: 18 RED + throw outward + Knockdown 1s in a 5x5 around the landing tile",
				"cooldown" = "10 seconds (and the instant it dons this form)",
				"desc"     = "Dashes down a 3-wide line onto the target, 1.4s \
					wind-up. On landing: telegraphs the 5x5 shockwave, 1.4s \
					wind-up, then resolves.",
			),
			list(
				"name"     = "Flickerstep (Shi form)",
				"damage"   = "First strike: 28 RED in a 3-wide dash line. Second strike: 14 RED in a 3-wide dash line.",
				"cooldown" = "8 seconds (and the instant it dons this form)",
				"desc"     = "Dashes onto the target along a 3-wide line, 1.4s \
					wind-up. Immediately dashes again at the target's new \
					position, 0.8s wind-up.",
			),
			list(
				"name"     = "Burning Charge (Liu form)",
				"damage"   = "22 RED + 6 Overheat in a 3-wide dash line; leaves a fire trail along the dash path",
				"cooldown" = "9 seconds (and the instant it dons this form)",
				"desc"     = "Dashes onto the target along a 3-wide line, 1.4s \
					wind-up. Fire trail along the dash path burns for 10 \
					seconds.",
			),
			list(
				"name"     = "Lunging Thrust (Seven form)",
				"damage"   = "24 RED + 6 Rupture in a 3-wide dash line",
				"cooldown" = "9 seconds (and the instant it dons this form)",
				"desc"     = "Dashes onto the target along a 3-wide line, 1.4s \
					wind-up.",
			),
			list(
				"name"     = "Cargo Drop (Devyat form)",
				"damage"   = "28 RED + Knockdown 2s + 4 Defense Level Down in a 5x5 on the marked tile",
				"cooldown" = "11 seconds",
				"desc"     = "Telegraphs the 5x5 around the target's snapshot \
					tile, 1.4s wind-up. On resolve: leaps onto the marked \
					tile, then the 5x5 hits around it.",
			),
			// ---------- Phase 2: Red Mist ----------
			list(
				"name"     = "Realization (Red Mist ability 1)",
				"damage"   = "32 RED in a 7x7 around the form; heals the form 40 HP per unique target hit (cap 3 targets)",
				"cooldown" = "Slot 1 of Red Mist's rotation; rotation morphs after 5 abilities",
				"desc"     = "Rooted 2s wind-up. Telegraphs the 7x7 around the \
					form's current tile, then resolves.",
			),
			list(
				"name"     = "Onrush (Red Mist ability 2)",
				"damage"   = "26 RED + 3 Bleed in a 3-wide forward dash line; on a kill in the line, chains to the nearest enemy (up to 2 chains)",
				"cooldown" = "Slot 2 of Red Mist's rotation",
				"desc"     = "Telegraphs a 3-wide strip from the form through \
					the target and a couple tiles past it. 1.4s wind-up. On \
					resolve: the form teleports to the line's end (or to the \
					tile just before the first wall in the path, if any) and \
					the strip hits. If anyone in the strip dies from the \
					slash, immediately winds up another dash on the next \
					nearest enemy.",
			),
			list(
				"name"     = "Focus Spirit (Red Mist ability 3)",
				"damage"   = "On release: 45 RED + 4 Bleed in a 5x5 around the form",
				"cooldown" = "Slot 3 of Red Mist's rotation; 1.5s buff stance",
				"desc"     = "Rooted 1.5s self-buff stance — applies 20 Defense \
					Level Up to the form during the wind-up. On stance end: \
					telegraphs the 5x5 around the form, 1.4s wind-up, then \
					resolves.",
			),
			list(
				"name"     = "Greater Split: Vertical (Red Mist ability 4)",
				"damage"   = "500 RED to every enemy caught in the cinematic",
				"cooldown" = "Slot 4 of Red Mist's rotation",
				"desc"     = "Rooted 1.4s wind-up. Telegraphs the 5x5 around the \
					form. On resolve: every living enemy still in the 5x5 is \
					Immobilized 1.52s, plays the Greater Split Vertical \
					cinematic, and takes the damage at its end.",
			),
			list(
				"name"     = "Greater Split: Horizontal (Red Mist ability 5)",
				"damage"   = "750 RED to every enemy caught in the cinematic",
				"cooldown" = "Slot 5 of Red Mist's rotation",
				"desc"     = "Rooted 2s wind-up. Telegraphs the 9x9 around the \
					form. On resolve: every living enemy still in the 9x9 is \
					Immobilized 1.4s, plays the Greater Split Horizontal \
					cinematic, and takes the damage at its end.",
			),
			// ---------- Phase 2: Black Silence ----------
			list(
				"name"     = "Zelkova Slam (Black Silence slot 1)",
				"damage"   = "35 BLACK in a 3x3 on the target's snapshot tile",
				"cooldown" = "Slot 1 of Black Silence's rotation (and the instant it dons this form)",
				"desc"     = "Telegraphs the 3x3 around the target's snapshot \
					tile, 0.8s wind-up, then resolves.",
			),
			list(
				"name"     = "Ranga Dash (Black Silence slot 2)",
				"damage"   = "28 BLACK in a 3-wide dash line",
				"cooldown" = "Slot 2 of Black Silence's rotation",
				"desc"     = "Dashes onto the target along a 3-wide line, 1.4s \
					wind-up.",
			),
			list(
				"name"     = "Old Boys Counter (Black Silence slot 3)",
				"damage"   = "On the riposte: 40 BLACK + throw 3 tiles + Knockdown 1s on the attacker",
				"cooldown" = "Slot 3 of Black Silence's rotation; 1.5s parry window",
				"desc"     = "Enters a 1.5s parry stance (dark-blue tint), rooted. \
					First melee or ranged hit landed during the window is \
					consumed and triggers the counter (blinks to a ranged \
					shooter first). If no hit lands, the stance ends without \
					a counter.",
			),
			list(
				"name"     = "Allas Lunge (Black Silence slot 4)",
				"damage"   = "32 BLACK + Rend Black in a 3-wide dash line",
				"cooldown" = "Slot 4 of Black Silence's rotation",
				"desc"     = "Dashes onto the target along a 3-wide line, 1.4s \
					wind-up.",
			),
			list(
				"name"     = "Mook Cut (Black Silence slot 5)",
				"damage"   = "40 BLACK in a 3x3 on the target's snapshot tile",
				"cooldown" = "Slot 5 of Black Silence's rotation",
				"desc"     = "Telegraphs the 3x3 around the target's snapshot \
					tile, 0.8s wind-up, then resolves.",
			),
			list(
				"name"     = "Logic Shotgun (Black Silence slot 6)",
				"damage"   = "30 BLACK + throw 3 tiles outward, in a 3-tile-deep forward cone (3 tiles wide at its base)",
				"cooldown" = "Slot 6 of Black Silence's rotation",
				"desc"     = "Telegraphs the cone in the form's facing direction, \
					1.4s wind-up, then resolves.",
			),
			list(
				"name"     = "Durandal Strike (Black Silence slot 7)",
				"damage"   = "50 BLACK on the target's snapshot tile (1x1)",
				"cooldown" = "Slot 7 of Black Silence's rotation",
				"desc"     = "Telegraphs the target's snapshot tile, 0.8s \
					wind-up, then resolves on it.",
			),
			list(
				"name"     = "Crystal Dash (Black Silence slot 8)",
				"damage"   = "30 BLACK in a 3-wide dash line",
				"cooldown" = "Slot 8 of Black Silence's rotation",
				"desc"     = "Dashes onto the target along a 3-wide line, 1.4s \
					wind-up. On landing: evade-teleports up to 3 tiles in a \
					random cardinal direction.",
			),
			list(
				"name"     = "Wheels Swing (Black Silence slot 9)",
				"damage"   = "45 BLACK + throw outward, in a 5-tile-deep forward cone (3 tiles wide at its base)",
				"cooldown" = "Slot 9 of Black Silence's rotation",
				"desc"     = "Telegraphs the cone in the form's facing direction, \
					1.4s wind-up, then resolves.",
			),
			list(
				"name"     = "Furioso (Black Silence slot 10) — UNAVOIDABLE",
				"damage"   = "1500 BLACK to the locked target. Target is also Stunned 6s and silenced for the duration.",
				"cooldown" = "Slot 10 of Black Silence's rotation. See **Black Silence — Spent After Furioso**.",
				"desc"     = "Anchors itself in place and becomes invulnerable; \
					the locked target is Stunned and silenced. After ~6 \
					seconds the 1500 BLACK lands on the target directly — no \
					positional dodge, no line-of-sight check. On resolve: \
					invulnerability / anchor / Stun / silence all clear.",
			),
			// ---------- Phase 2: Blue Reverberation ----------
			list(
				"name"     = "Resonant Wave (Blue Reverberation ability 1)",
				"damage"   = "Ring 1: 22 WHITE in a 3x3. Ring 2: 22 WHITE in a 5x5. Ring 3: 26 PALE + 3 Sinking in a 7x7. All centered on the form.",
				"cooldown" = "Slot 1 of Blue Reverberation's rotation; rotation morphs after 5 abilities",
				"desc"     = "Rooted 2.4s total. Each ring telegraphs 0.8s then \
					resolves. Rings fire in order: 3x3, then 5x5, then 7x7.",
			),
			list(
				"name"     = "Tempestuous Danza (Blue Reverberation ability 2)",
				"damage"   = "24 WHITE + 1 Vibration per enemy struck",
				"cooldown" = "Slot 2 of Blue Reverberation's rotation",
				"desc"     = "1.4s wind-up. On resolve: teleport-strikes every \
					living enemy within 8 tiles once each, in sequence.",
			),
			list(
				"name"     = "Grand Finale (Blue Reverberation ability 3)",
				"damage"   = "60 PALE per marked target; 90 PALE if the marked target has 3+ Vibration stacks",
				"cooldown" = "Slot 3 of Blue Reverberation's rotation",
				"desc"     = "Rooted 2s wind-up. Dashes to every living enemy \
					within 10 tiles and tags each (no damage), then teleports \
					back to its starting tile. After 0.8s: every marked target \
					takes the PALE burst at their current position.",
			),
		),

		// ---------- zeal_s2n2: The Greed Touched Clone ----------

		/mob/living/simple_animal/hostile/greed_touched_eric/refracted = list(
			list(
				"name"     = "Sanguine Feast",
				"damage"   = "80 RED + 3 Bleed per human standing on a marked tile when the tendril lands; **non-human mobs under 800 HP on a marked tile are executed instantly** and feed him ~half their max HP in bloodfeast",
				"cooldown" = "~30 seconds",
				"desc"     = "Locks in place and marks the tile under every \
					human in view (~7 tiles). After ~4s a blood tendril \
					rises through each marked tile and spikes whatever \
					stands on it — step off the marked tile during the \
					wind-up to dodge. Catches his own summons too, which \
					is how he refills mid-fight.",
			),
			list(
				"name"     = "Greed Burst",
				"damage"   = "30 RED to every enemy in view (~8 tiles) + 2 Bleed (60 RED if **Glutted**). Each live summon also bursts in place for 50 RED + 2 Bleed in a 3x3 around their tile.",
				"cooldown" = "Auto-fires when his bloodfeast pool fills (~700 in P1, ~500 in P2)",
				"desc"     = "2s telegraph (warning tiles ring the room and he \
					convulses), then a room-wide RED pulse + every live \
					summon is **sacrificed** in place. The minion bursts hit \
					harder than the room-wide pulse because you can step \
					away from them. Each sacrificed minion beams its blood \
					back to him on death, so a fat wave means a fatter \
					shield after the window closes.",
			),
			list(
				"name"     = "Hardblood Arts",
				"damage"   = "90 RED + 3 Bleed + 1s Knockdown per strike, 3 strikes per cycle (eating all three is ~68% of a 200-HP / 50%-DR player's pool)",
				"cooldown" = "~10 seconds in phase 3 only",
				"desc"     = "Phase 3 only. Drops three **blood-sparkle \
					brackets** around the target (one per landing \
					direction, ~1s apart) — these are the tell. Then says \
					'Heart's snare!' and dashes in from each direction in \
					turn, striking with ~1s between each. Step off the \
					target tile between sparkles to break the bracket; \
					Knockdown chains into the next teleport if you eat one.",
			),
			list(
				"name"     = "Sanguine Rush",
				"damage"   = "40 RED + 2 Bleed per tile hit in a 3-wide strip; charges three times per cast (a player caught in all three takes 120+ raw before DR)",
				"cooldown" = "~15 seconds in phase 3 only",
				"desc"     = "Phase 3 only. After a 2s wind-up (he hunches \
					forward, claws weeping crimson) **and a short shout of \
					'BEHOLD, CHILDREN!'**, barrels through up to 7 tiles \
					toward the nearest enemy and back-to-back repeats it \
					two more times. Each step paints a 3x3 strip with \
					blood splatters and tags everything in it. Alternates \
					with **Hardblood Arts** to keep his last phase \
					unpredictable.",
			),
			list(
				"name"     = "P3 Melee",
				"damage"   = "25-35 RED on melee swing",
				"cooldown" = "Standard simple-animal swing cadence",
				"desc"     = "Phase 3 only. He stops being a pure summoner \
					and starts actually swinging at adjacent targets. \
					Pursuit also speeds up (move_to_delay drops from 16 \
					to 6) — staying in melee range becomes a steady chip \
					instead of a free zone.",
			),
		),

		// ---------- zeal_s3n1: The One That Got Out ----------

		/mob/living/simple_animal/hostile/mirror_shattered_reaper/refracted = list(
			list(
				"name"     = "Refraction Sweep",
				"damage"   = "100 BLACK to every mob in a **single forward cone** — **4 tiles deep in P1 (~10 tiles total)**, **5 tiles deep in P2 (~13 tiles total)**. Always 3 wide at the base in front of the Reaper, tapering to a **1-tile tip** at max range.",
				"cooldown" = "~10 seconds",
				"desc"     = "**Faces her target**, then paints the \
					cone tiles in purple mirror-shard chevrons for \
					**1.5 seconds** — the shape is a wide swipe with \
					the broad base right in front of her, narrowing to \
					a single tile at the far edge. **She is rooted in \
					place and can't melee while the cone charges** — \
					this is the safe window to flank her, since the \
					sides and rear are clear. On resolve she **absorbs \
					only the Mirror Variants standing inside the cone** \
					(each refunds its HP share and adds 1 Reverberation \
					Charge) — Variants outside the cone keep walking. \
					**Spawns 2 new Variants (4 in Phase 2)** scattered \
					at random turfs around her (not adjacent — they rift \
					in 2-5 tiles away).",
			),
			list(
				"name"     = "Crossing Over",
				"damage"   = "150 BLACK to every mob inside a **5x5 area in P1, 7x7 in P2**, centered on a snapshot tile",
				"cooldown" = "~18 seconds",
				"desc"     = "Picks a random player, paints **5x5 tiles \
					(7x7 in Phase 2)** around their current position \
					in lighter-purple mirror markers, then **roots \
					herself in place for 1.5 seconds** (she can't move \
					or melee during the windup). On resolve she \
					**teleports to the center of the warning area** \
					and slams it — anyone still inside eats the hit. \
					The warning **does not follow the player** — step \
					off the painted tiles before the timer ends to \
					escape. On impact she **absorbs only the Mirror \
					Variants standing inside the warning area** and \
					**spawns 2 new ones (4 in Phase 2)** scattered \
					around her new position.",
			),
			list(
				"name"     = "Reverberation",
				"damage"   = "35 BLACK per damage instance (split evenly across the instance's rifts). Instance count equals current Reverberation Charge (capped at 15). At cap: **525 BLACK total** spread across the cast (~210 actual damage to a player at 60% DR).",
				"cooldown" = "**45 seconds**, gated by Reverberation Charge ≥ 5 for the first cast. Force-fires once on Phase 2 entry if charges are ready.",
				"desc"     = "**On cast, any still-alive Mirror Variants \
					are yanked back into her regardless of distance** — \
					each one refunds its ~150 HP cost and adds 1 \
					Reverberation Charge before the cast resolves. The \
					Reaper then goes **invisible at her current tile, \
					locked in place** for the entire cast. For every \
					Reverberation Charge (post-absorb total), one \
					**damage instance** plays out: she rifts to **3 or \
					4 random points** in the room, striking a player on \
					each step with the rip_space dash visual. **Every \
					rift deals damage** — no free telegraph hops — but \
					the per-instance total is constant: a 3-rift \
					instance is three larger hits, a 4-rift instance is \
					four smaller hits, both summing to 35 BLACK. After \
					the last instance she rifts back to her starting \
					tile, and all Reverberation Charges reset to 0. \
					**Killing Variants before the ult triggers is the \
					only way to deny her the Charges they'd feed.**",
			),
		),
	)
