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

		// ---------- zeal_s3n1: The One That Got Out ----------

		/mob/living/simple_animal/hostile/mirror_shattered_reaper/refracted = list(
			list(
				"title"    = "Mirror Variants",
				"severity" = "high",
				"text"     = "**Refraction Sweep** and **Crossing Over** \
					each crack the Reaper apart — every Variant she \
					spawns comes out at **1.5% of her current Max HP** \
					(≈150 each at base) and she pays that cost per \
					Variant. **3 Variants in Phase 1** = ~4.5% Max HP \
					per wave; **6 Variants in Phase 2** = ~9% Max HP per \
					wave. **A hard cap of 3 alive Variants in P1, 6 in \
					P2** — if she'd spawn into a full board, the extra \
					slots just don't spawn (and she pays no cost for \
					the skipped ones). On the **next** Refraction \
					Sweep or Crossing Over cast, **only the Variants \
					standing inside the AoE's damage area** are absorbed \
					back into her — refunding **their full ≈150 HP \
					each** and granting **+1 Reverberation Charge each** \
					(cap 15). Variants outside the AoE keep walking — \
					they have to be caught by another AoE later, or \
					killed. A Variant killed before absorb leaves its \
					HP share **unrefunded** AND deals **an extra ≈150 \
					HP self-damage** to the Reaper (its summon cost \
					again) — plus strips **1 stack of Resolute Glass**. \
					**At 0 stacks (no resistance), that kill-bonus is \
					multiplied ×2.5** (~375 per kill), so finishing the \
					ladder turns every subsequent kill into a much \
					heavier punish. **Killing the Variants is how you \
					bleed the Reaper and starve Reverberation.** \
					**Visual stockpile cue:** every **4 absorbed \
					Variants** spawns a translucent purple afterimage \
					of her that trails one tile behind her until \
					Reverberation fires.",
			),
			list(
				"title"    = "Resolute Glass",
				"severity" = "high",
				"text"     = "Carries **8 stacks of Resolute Glass** at \
					phase entry — a flat **10% damage reduction per \
					stack** (**80% at full ladder, 0% at empty**). \
					**Loses 1 stack per Mirror Variant killed** \
					(permanent within the phase, no regen). The **only \
					way she gains stacks is by entering a new phase** — \
					she starts P1 with 8, and Phase 2 entry refreshes \
					her back to 8. At 80% DR almost nothing chips her; \
					**every Variant killed is worth 10% of her total \
					damage taken from there on**, so clearing the \
					Variants is the only way to make direct DPS land.",
			),
			list(
				"title"    = "Phase 2: Hood Torn Back",
				"severity" = "high",
				"text"     = "At **50% HP** her hood tears open and the \
					stitched-composite face underneath comes out. \
					**Variants per summon doubles to 6** (the alive-cap \
					rises with it to 6), **Refraction Sweep's cone gains \
					1 tile of depth** (P1's 4-deep / ~10-tile cone → P2's \
					5-deep / ~13-tile cone), **Crossing Over's warning \
					area grows from 5×5 to 7×7**, **Resolute Glass \
					refreshes** back to 8 stacks, and if **Reverberation \
					Charge ≥ 5** she immediately fires Reverberation as \
					the transition. Otherwise the next Reverberation \
					window opens about 20 s later.",
			),
		),

		// ---------- zeal_s3n2: The Apotheosis ----------

		/mob/living/simple_animal/hostile/achiyalabopa/refracted = list(
			list(
				"title"    = "Untouchable Apotheosis",
				"severity" = "high",
				"text"     = "She **cannot be wounded while she stands \
					as a god**. Her divine pose holds for **up to 90 \
					seconds** before she descends on her own, enraged — \
					but you can **break her composure faster** by turning \
					her own storm against her flock (see **Composure \
					Cracks**). She chases and casts AoEs the whole time \
					her pose holds; **enraging her is the only path to \
					damaging her**.",
			),
			list(
				"title"    = "Pressure of Apotheosis (Awe Struck)",
				"severity" = "high",
				"text"     = "Every ~3 seconds she re-applies **Awe \
					Struck** to every human in her sight. Awe Struck \
					itself inflicts no stacks — it's a marker. While \
					awe-struck, **every attack she lands deals 50% \
					more damage**: melee, Divine Judgment, Thunder \
					Whip, and Divine Thunderbolt all multiply on \
					awe-struck targets. **Hope** and **Will of \
					Humanity** both dispel the marker and grant \
					immunity for their duration. Only one player can \
					carry the Coreflame at a time, so the Coreflame \
					bearer should use the **Hope Aura** action to \
					spread the buff to teammates and keep the awe \
					multiplier off them.",
			),
			list(
				"title"    = "Composure Cracks",
				"severity" = "high",
				"text"     = "**Mirage Reapers drip from the storm** \
					around her every ~8 seconds (cap **6 alive**). \
					**Killing them with your own weapons does nothing.** \
					What breaks her is **watching her own storm unmake \
					her flock** — every Reaper struck down by Divine \
					Judgment, Thunder Whip, or Divine Thunderbolt is \
					**instantly unmade** and **brings her enrage 5 \
					seconds closer**. The strong play is stacking as many \
					Reapers as possible into a single AoE for a big \
					composure crack.",
			),
			list(
				"title"    = "Phase 2: Enraged",
				"severity" = "high",
				"text"     = "When her composure finally breaks — by \
					timer or by enough flock-kills — she descends, \
					enraged. Her defenses settle to **80% DR (60% to \
					PALE)**. From this point on, **a Coreflame blooms \
					near her every ~20 seconds** (cap 2 on the ground at \
					once). Pick one up to gain **Will of Humanity** — a \
					**Piercing Strike** spell that calls a divine spear \
					down on a target tile after a **1.5-second delay** \
					(aim where she'll be, not where she is). On a hit \
					she's impaled for an **8-second vulnerability window** \
					(1.5× from RED/WHITE/BLACK, 3× from PALE), the \
					Coreflame burns out, and the bearer gets **15 \
					seconds of Hope** — awe immunity and time to grab \
					the next Coreflame. On a miss, the Coreflame stays \
					— you can try again after the spell cooldown.",
			),
		),

		/mob/living/simple_animal/hostile/mirage_reaper = list(
			list(
				"title"    = "Sacrifice the Flock",
				"severity" = "high",
				"text"     = "**Killing a Mirage Reaper with player damage \
					does nothing.** What hurts Achiyalabopa is watching \
					her **own AoEs** (Divine Judgment, Thunder Whip, \
					Divine Thunderbolt) cut them down — any AoE that \
					touches a Reaper **instantly unmakes it**, no damage \
					roll. **Each Reaper unmade this way cracks her \
					composure and brings her enrage 5 seconds closer**, \
					so the puzzle is herding as many as possible into a \
					single AoE.",
			),
			list(
				"title"    = "Burst on Hope",
				"severity" = "medium",
				"text"     = "A Reaper that touches a **Will of Humanity** \
					holder **burns to nothing instantly** — letting the \
					Coreflame-bearer melee them straight off the field. \
					Note this is a player kill, so her composure is \
					unaffected.",
			),
		),

		// ---------- zeal_s3n2: The Snow Cabin ----------

		/mob/living/simple_animal/hostile/snow_cabin/refracted = list(
			list(
				"title"    = "Untouchable Cabin",
				"severity" = "high",
				"text"     = "All direct damage to the cabin does nothing \
					— melee, items, projectiles, and area effects. Its HP \
					moves only via weakpoint deaths (see **HP / Damage \
					Funnel**).",
			),
			list(
				"title"    = "HP / Damage Funnel",
				"severity" = "high",
				"text"     = "On an **Eye** or **Mouth** death: the cabin \
					takes BRUTE damage equal to the killed weakpoint's max \
					HP.",
			),
			list(
				"title"    = "Weakpoint Spawning",
				"severity" = "medium",
				"text"     = "Every ~1s: refills weakpoints toward a \
					target count on random floor tiles (skipping tiles \
					that already host a weakpoint or hatching event). \
					**Phase 1: 6 Eyes + 4 Mouths. Phase 2: 12 Eyes + 10 \
					Mouths.**",
			),
			list(
				"title"    = "Phase 2 (below 50% HP)",
				"severity" = "high",
				"text"     = "Weakpoint targets shift to the Phase 2 row \
					of **Weakpoint Spawning**. **Bone Stab Line** fires \
					two perpendicular sweeps at once and **Bladed Teeth** \
					covers 40% of the floor instead of 25% — both keep \
					their raw cooldowns. **Ice Spike** and **Ice Shard \
					Spray** cooldowns × 0.75. Begins spawning **Meatpods** \
					and **Ice Prisons**. Adds **Ice Shard Spray** to the \
					attack rotation.",
			),
			list(
				"title"    = "Meatpod",
				"severity" = "medium",
				"text"     = "Phase 2, every 12s: spawns a pulsing fleshy \
					pod on a random floor tile. Cannot be attacked. 4s \
					after spawn it bursts, spawning one **Meatling**. \
					Caps: 3 pre-burst pods, **2 alive Meatlings** \
					(spawning halts when full).",
			),
			list(
				"title"    = "Ice Prison",
				"severity" = "medium",
				"text"     = "Phase 2, every 14s: a small block of ice \
					grows on a random floor tile. Cannot be attacked. \
					Cycles through three growth stages over ~12s, then \
					cracks and spawns one **Yagaslave**. Caps: 2 \
					pre-hatch prisons, **1 alive Yagaslave** (spawning \
					halts when full).",
			),
		),

		/mob/living/simple_animal/hostile/snow_cabin_eye = list(
			list(
				"title"    = "Stationary Watcher",
				"severity" = "info",
				"text"     = "Cannot move. Every 1s: rotates to face the \
					nearest living player.",
			),
			list(
				"title"    = "Cabin Weakpoint",
				"severity" = "medium",
				"text"     = "On its death: deals BRUTE damage to the \
					cabin equal to its own max HP.",
			),
		),

		/mob/living/simple_animal/hostile/snow_cabin_mouth = list(
			list(
				"title"    = "Four-Stage Cycle",
				"severity" = "medium",
				"text"     = "Cycles **closed → opening → open → closing → \
					closed**, repeating. Closed: 4s. Opening: 1.1s. Open: \
					3s. Closing: 1.1s. **Bite** can only fire during the \
					open stage.",
			),
			list(
				"title"    = "Bite",
				"severity" = "high",
				"text"     = "Open stage only: bites adjacent humans via \
					the standard hostile AI tick. The chomp sprite \
					flashes for 0.6s on each connect. Attempted bites in \
					the closed, opening, or closing stages are silently \
					rejected.",
			),
			list(
				"title"    = "Cabin Weakpoint",
				"severity" = "medium",
				"text"     = "On its death: deals BRUTE damage to the \
					cabin equal to its own max HP.",
			),
		),

		/mob/living/simple_animal/hostile/cabin_meatling = list(
			list(
				"title"    = "Summoned by Meatpods",
				"severity" = "info",
				"text"     = "Spawned by a **Meatpod** bursting. Its \
					death does not damage the cabin.",
			),
		),

		/mob/living/simple_animal/hostile/cabin_yagaslave = list(
			list(
				"title"    = "Summoned by Ice Prisons",
				"severity" = "info",
				"text"     = "Spawned by an **Ice Prison** cracking open. \
					Its death does not damage the cabin.",
			),
		),
	)
