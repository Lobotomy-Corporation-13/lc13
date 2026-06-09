/*
 * Line 2: Curtain Call. Five-sector run themed as a five-act play staged by
 * an unseen Game Master, Serio Zeal. Every combat node is a boss fight;
 * Serio Zeal is the final node of the last sector.
 *
 * This pass is scaffolding only — combat nodes use a placeholder
 * /mob/living/simple_animal/hostile/netherworld/migo/refracted stock so the
 * line is end-to-end playable for layout / briefing / leaderboard testing
 * while the real per-encounter bosses are authored elsewhere.
 *
 * Subway-map layout: 16 visual nodes (start + 8 boss-combat + 4 checkpoints
 * + 2 boss-wave finale nodes + finish) positioned to evoke the Sculptor
 * constellation rather than a horizontal snake. Authoring conventions: see
 * code/modules/refraction_railway/AUTHORING.md.
 */

/area/refraction/curtain_call
	name = "Refraction Railway: Curtain Call"
	icon_state = "green"

/datum/refraction_line/curtain_call
	id                  = "curtain_call"
	name                = "Line 2: Curtain Call"
	description         = "Four acts a hand we haven't met has rehearsed \
		for you, and a fifth where that hand steps under the lights to \
		introduce itself."
	map_path            = "_maps/refraction_railway/curtain_call.dmm"
	attribute_set_value = 80
	max_lobby_size      = 4
	section_count       = 5
	display_color       = "#22c55e"

	// Curtain Call is hand-balanced per mob, so the wave-scaling tweaks that
	// inflate stock / concurrent caps / batch size / non-boss stats are off.
	// Boss HP × players and compensation pens stay on.
	scale_stock         = FALSE
	scale_concurrent    = FALSE
	scale_spawn_batch   = FALSE
	scale_wave_stats    = FALSE

	// Phases 2 + 3 of the Serio Zeal finale aren't authored yet, so the
	// whole line stays Hub-visible but lobby-locked until they ship.
	locked              = TRUE

	map_viewbox = list("w" = 600, "h" = 400)

	// 16 visual nodes: start, 4×(2 combat + 1 checkpoint), 2 boss-wave
	// nodes (w1 combat + w2 boss — w2 holds Phase 2 and Phase 3 in a
	// single in-node transition), finish. Same 600x400 viewBox as Nova
	// Flare so node sizes render at the same visual scale across both
	// lines. Sector pairs are tightly clustered (~45-55px apart);
	// checkpoints sit far from neighbours (~80-115px) to read as breaks
	// in the chain.
	nodes = list(
		list("x" = 40,  "y" = 90,  "kind" = "start"),       //  1
		list("x" = 110, "y" = 120, "kind" = "combat"),      //  2  zeal_s1n1
		list("x" = 155, "y" = 95,  "kind" = "combat"),      //  3  zeal_s1n2
		list("x" = 235, "y" = 135, "kind" = "checkpoint"),  //  4
		list("x" = 290, "y" = 180, "kind" = "combat"),      //  5  zeal_s2n1
		list("x" = 335, "y" = 200, "kind" = "combat"),      //  6  zeal_s2n2
		list("x" = 370, "y" = 285, "kind" = "checkpoint"),  //  7
		list("x" = 290, "y" = 325, "kind" = "combat"),      //  8  zeal_s3n1
		list("x" = 245, "y" = 345, "kind" = "combat"),      //  9  zeal_s3n2
		list("x" = 360, "y" = 360, "kind" = "checkpoint"),  // 10
		list("x" = 440, "y" = 340, "kind" = "combat"),      // 11  zeal_s4n1
		list("x" = 475, "y" = 305, "kind" = "combat"),      // 12  zeal_s4n2
		list("x" = 510, "y" = 230, "kind" = "checkpoint"),  // 13
		list("x" = 525, "y" = 165, "kind" = "combat"),      // 14  serio_zeal_w1
		list("x" = 555, "y" = 115, "kind" = "boss"),        // 15  serio_zeal_w2 (holds Phase 2 + Phase 3)
		list("x" = 585, "y" = 55,  "kind" = "finish"),      // 16
	)
	edges = list(
		list("from" = 1,  "to" = 2,  "shape" = "line"),
		list("from" = 2,  "to" = 3,  "shape" = "line"),
		list("from" = 3,  "to" = 4,  "shape" = "line"),
		list("from" = 4,  "to" = 5,  "shape" = "line"),
		list("from" = 5,  "to" = 6,  "shape" = "line"),
		list("from" = 6,  "to" = 7,  "shape" = "line"),
		list("from" = 7,  "to" = 8,  "shape" = "line"),
		list("from" = 8,  "to" = 9,  "shape" = "line"),
		list("from" = 9,  "to" = 10, "shape" = "line"),
		list("from" = 10, "to" = 11, "shape" = "line"),
		list("from" = 11, "to" = 12, "shape" = "line"),
		list("from" = 12, "to" = 13, "shape" = "line"),
		list("from" = 13, "to" = 14, "shape" = "line"),
		list("from" = 14, "to" = 15, "shape" = "line", "dashed" = TRUE),
		list("from" = 15, "to" = 16, "shape" = "curve", "dashed" = TRUE),
	)

	recommended_tier_lines = list(
		"- Bring E.G.O. with stat requirements around 80.",
	)

/datum/refraction_line/curtain_call/New()
	. = ..()

	// ----- Sector 1: The Opening Bill -----
	AddNode("zeal_s1n1", "zeal_s1n1_spawns",
		"Sector 1, Act I: The Bill Opens with a Brawl",
		"Two figures step onto the platform in matched colours. The taller \
			is dressed for the audience - a hand-tailored Thumb East \
			black. The smaller pads at his heel, leashless, still red \
			around the mouth. They have rehearsed this scene many \
			times - a pairing the one writing this has been one half \
			of for as long as he has been writing.",
		list(
			/mob/living/simple_animal/hostile/thumb_east_capo/refracted = 1,
			/mob/living/simple_animal/hostile/rat/capo_rat/refracted   = 1,
		),
		c_max = 2,
		boss = TRUE)

	AddNode("zeal_s1n2", "zeal_s1n2_spawns",
		"Sector 1, Act II: The Dealer's Cut",
		"The next performer is dealt onto the stage like a card. Oversized \
			ebony dice clatter across the boards in front of him, every \
			one showing the lowest face. He calls a bet that no shield \
			will refuse - only the table can answer it. It is the kind \
			of bet the one writing this has been losing for a long \
			time. Roll the table high.",
		list(
			/mob/living/simple_animal/hostile/distortion/azarus/refracted = 1,
		),
		boss = TRUE)

	// ----- Sector 2: The Sin Plays -----
	AddNode("zeal_s2n1", "zeal_s2n1_spawns",
		"Sector 2, Act I: Borrowed Faces",
		"The next performer has no face of its own, so it borrows the \
			cast's. It will play role after role at us, and only between \
			costumes can we glimpse the longing thing wearing them - the \
			same complaint someone in the wings has heard about himself \
			more than once, and once mistook for a compliment.",
		list(
			/mob/living/simple_animal/hostile/distortion/understudy = 1,
		),
		boss = TRUE)

	AddNode("zeal_s2n2", "zeal_s2n2_spawns",
		"Sector 2, Act II: The Altar in the Clinic",
		"The next scene is staged in a clinic that has finished turning \
			into a fleshly temple. A bloody copy of a polite man we may \
			have met stands at its altar, and every drop spilt here \
			belongs to him. The playbill notes he was kind once. He \
			thought he was helping - a line someone in the wings has \
			underlined twice in his own copy.",
		list(
			/mob/living/simple_animal/hostile/greed_touched_eric/refracted = 1,
		),
		boss = TRUE)

	// ----- Sector 3: Where the Stage Folds -----
	AddNode("zeal_s3n1", "zeal_s3n1_spawns",
		"Sector 3, Act I: The One That Got Out",
		"The next scene calls in something the audience cannot place. \
			It steps through a crack in the stage with too many versions \
			of itself in tow, and it is hunting the rest of them down so \
			it can keep them. It only ever wanted to be more than it \
			was - a line a young star somewhere keeps a copy of, in \
			case one of his own sent-out pieces ever comes back wrong.",
		list(
			/mob/living/simple_animal/hostile/mirror_shattered_reaper/refracted = 1,
		),
		boss = TRUE)

	AddNode("zeal_s3n2", "zeal_s3n2_spawns",
		"Sector 3, Act II: A Lit Window in the Snow",
		"The line bends through a clearing. A small wooden cabin sits in \
			fresh snow, its windows yellow with warmth. Step closer and \
			the snow turns dense, drawing in toward the windows. Inside, \
			something is being kept safe. It would rather no one ever \
			found it - a young star, perhaps, who sketched a house like \
			this on the inside cover of every notebook he ever owned, \
			and thought he was sketching a refuge.",
		list(
			/mob/living/simple_animal/hostile/snow_cabin/refracted = 1,
		),
		boss = TRUE,
		extra_preview = list(
			/mob/living/simple_animal/hostile/snow_cabin_eye,
			/mob/living/simple_animal/hostile/snow_cabin_mouth,
			/mob/living/simple_animal/hostile/cabin_meatling,
			/mob/living/simple_animal/hostile/cabin_yagaslave,
		))

	// ----- Sector 4: After Humanity -----
	AddNode("zeal_s4n1", "zeal_s4n1_spawns",
		"Sector 4, Act I: A Sermon Without a Mouth",
		"A hooded figure walks the stage in absolute silence. A blade \
			circles them at shoulder height, unsupported, and it is the \
			blade that speaks. He once believed kind people ought to be \
			met with kindness. He has since revised the lesson - and he \
			believes he is helping. It is an argument someone off-stage \
			has met inside their own head and lost to before. They have \
			not warned the audience about that part.",
		list(
			/mob/living/simple_animal/hostile/distortion/blade_priest/refracted = 1,
		),
		boss = TRUE)

	AddNode("zeal_s4n2", "zeal_s4n2_spawns",
		"Sector 4, Act II: The Apotheosis",
		"Someone who came onto the platform to play the lead, and stopped \
			being lead-of-a-play somewhere along the way. The stage has \
			become a temple under her feet; the audience worships in the \
			wings. She will not come down on her own. Someone off-stage \
			has read warnings about her shape their whole career - the \
			cost of staying so long the role becomes the only ground \
			left to stand on - and is afraid they will not feel the \
			moment it happens to them.",
		list(
			/mob/living/simple_animal/hostile/achiyalabopa/refracted = 1,
		),
		boss = TRUE,
		extra_preview = list(
			/mob/living/simple_animal/hostile/mirage_reaper,
			/mob/living/simple_animal/hostile/mirage_reaper/v2,
		))

	// ----- Sector 5: Curtain Fall -----
	// Three sequential boss-waves at one physical arena. Mappers can place
	// the wave-specific start_point landmarks at the same coords if they
	// want a single-room finale.
	AddNode("serio_zeal_w1", "serio_zeal_w1_spawns",
		"Curtain Fall, Wave I: The Writer Enters",
		"The curtain ripples and the writer steps onto the stage in \
			person. He bows once for the audience that has been here \
			the whole time, and signals for the first wave of his \
			finale to begin. Every role he has ever borrowed is loaded \
			into the script of this wave. He is the only one who \
			remembers which performer he was first rehearsing for.",
		list(
			/mob/living/simple_animal/hostile/young_star = 1,
		),
		boss = TRUE,
		locked = TRUE)

	AddNode("serio_zeal_w2", "serio_zeal_w2_spawns",
		"Curtain Fall, Wave II: The Cast Returns",
		"A voice that has been waiting in the wings steps to centre \
			stage. The writer is no longer the one speaking - and what \
			is speaking for him has spent a long time rehearsing the \
			case that he should not be here at all. The lights brighten \
			on the new act. It believes it is helping.",
		list(
			// TODO: replace with the real Serio Zeal Wave II roster
			/mob/living/simple_animal/hostile/netherworld/migo/refracted = 1,
		),
		boss = TRUE,
		locked = TRUE)

	sector_briefings = list(
		list(
			"name"        = "Sector 1: The Opening Bill",
			"description" = "The first act of a play is always cheap, the \
				playbill insists. A street brawl in matched colours, a \
				loaded dice game where every face has been turned the \
				same way. The one writing this borrowed two performers \
				from the city below and put them under the stage lights \
				to see if we'd notice the difference - and to see if \
				anyone notices he has been rehearsing the look of being \
				fine for a very long time.",
			"node_ids"    = list("zeal_s1n1", "zeal_s1n2"),
		),
		list(
			"name"        = "Sector 2: The Sin Plays",
			"description" = "The next two performers are not playing roles; \
				they are the role. One of them wants to be everyone in the \
				audience - would peel a face off the front row if no one \
				stopped him. The other wants what those people are \
				holding - and what they are holding is what runs in their \
				veins. They are very honest about it, which is more than \
				someone in the wings has ever been able to manage about \
				himself.",
			"node_ids"    = list("zeal_s2n1", "zeal_s2n2"),
		),
		list(
			"name"        = "Sector 3: Where the Stage Folds",
			"description" = "The set folds the way it was rehearsed to. \
				Through one crack, more of someone than the audience can \
				keep track of, pulling every spare version back inside. \
				Through another, a small lit cottage in fresh snow whose \
				door has been closed for a long time. The playhouse is \
				more than a playhouse this act. A young star somewhere \
				has stayed up nights worrying he could end up at either \
				address.",
			"node_ids"    = list("zeal_s3n1", "zeal_s3n2"),
		),
		list(
			"name"        = "Sector 4: After Humanity",
			"description" = "Two performers who are no longer playing human \
				roles. One because he believed he could carve the human \
				out and keep the better half - that the kindness people \
				deserved was the cut, and he was being merciful. One \
				because she became something past being human and her \
				audience agreed, and now neither one can let the other \
				come down. They will not return on their own. Someone \
				off-stage has built the rest of the line as a chase \
				between these two endings, and is no longer sure which \
				of them they are running from.",
			"node_ids"    = list("zeal_s4n1", "zeal_s4n2"),
		),
		list(
			"name"        = "Sector 5: Curtain Fall",
			"description" = "The writer steps onto the stage in person at \
				last. The audience has been here the whole time, and so \
				has the script. Every performer in the line has been a \
				piece of him put under the lights to see if we'd \
				recognise it. He has written this finale across two \
				rising waves - the second one containing more than one \
				ending - and he means every word.",
			"node_ids"    = list("serio_zeal_w1", "serio_zeal_w2"),
		),
	)
