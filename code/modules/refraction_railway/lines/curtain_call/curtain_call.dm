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
 * Subway-map layout: 11 visual nodes (1 start + 9 boss-combat + 1 finish)
 * positioned to evoke the Sculptor constellation rather than a horizontal
 * snake. Authoring conventions: see code/modules/refraction_railway/AUTHORING.md.
 */

/area/refraction/curtain_call
	name = "Refraction Railway: Curtain Call"
	icon_state = "green"

/datum/refraction_line/curtain_call
	id                  = "curtain_call"
	name                = "Line 2: Curtain Call"
	description         = "Four acts an unseen director has rehearsed for \
		you, and a fifth that wants to meet its audience."
	map_path            = "_maps/refraction_railway/curtain_call.dmm"
	attribute_set_value = 90
	max_lobby_size      = 4
	section_count       = 5
	display_color       = "#22c55e"

	map_viewbox = list("w" = 600, "h" = 400)

	// 11 visual nodes arranged as a constellation. The broken-snake turn at
	// node 5 -> 6 and the vertical spur 6 -> 7 give the figure its
	// constellation feel without any node jutting backward out of frame.
	// Viewbox matches Nova Flare's (600x400) so node sizes render at the
	// same visual scale across both lines.
	nodes = list(
		list("x" = 40,  "y" = 80,  "kind" = "start"),       //  1
		list("x" = 130, "y" = 130, "kind" = "combat"),      //  2  s1n1
		list("x" = 210, "y" = 80,  "kind" = "combat"),      //  3  s1n2
		list("x" = 290, "y" = 145, "kind" = "combat"),      //  4  s2n1
		list("x" = 370, "y" = 215, "kind" = "combat"),      //  5  s2n2
		list("x" = 300, "y" = 285, "kind" = "combat"),      //  6  s3n1
		list("x" = 300, "y" = 360, "kind" = "combat"),      //  7  s3n2
		list("x" = 400, "y" = 315, "kind" = "combat"),      //  8  s4n1
		list("x" = 490, "y" = 240, "kind" = "combat"),      //  9  s4n2
		list("x" = 545, "y" = 160, "kind" = "boss"),        // 10  serio_zeal
		list("x" = 585, "y" = 80,  "kind" = "finish"),      // 11
	)
	edges = list(
		list("from" = 1,  "to" = 2,  "shape" = "line"),
		list("from" = 2,  "to" = 3,  "shape" = "line"),
		list("from" = 3,  "to" = 4,  "shape" = "line"),
		list("from" = 4,  "to" = 5,  "shape" = "line"),
		list("from" = 5,  "to" = 6,  "shape" = "line"),
		list("from" = 6,  "to" = 7,  "shape" = "line"),
		list("from" = 6,  "to" = 8,  "shape" = "line"),
		list("from" = 8,  "to" = 9,  "shape" = "line"),
		list("from" = 9,  "to" = 10, "shape" = "line", "dashed" = TRUE),
		list("from" = 10, "to" = 11, "shape" = "curve", "dashed" = TRUE),
	)

	recommended_tier_lines = list(
		"- Bring E.G.O. with stat requirements around 90.",
	)

/datum/refraction_line/curtain_call/New()
	. = ..()

	// ----- Sector 1: The Opening Bill -----
	AddNode("zeal_s1n1", "zeal_s1n1_spawns",
		"Sector 1, Act I: The Bill Opens with a Brawl",
		"Two figures step onto the platform in matched colours. The taller \
			is dressed for the audience - a hand-tailored Thumb East \
			black. The smaller pads at his heel, leashless, still red \
			around the mouth. They have rehearsed this scene.",
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
			will refuse - only the table can answer it. Roll the table \
			high.",
		list(
			/mob/living/simple_animal/hostile/azarus/refracted = 1,
		),
		boss = TRUE)

	// ----- Sector 2: The Sin Plays -----
	AddNode("zeal_s2n1", "zeal_s2n1_spawns",
		"Sector 2, Act I: Borrowed Faces",
		"The next performer has no face of its own, so it borrows the \
			cast's. It will play role after role at us, and only between \
			costumes can we glimpse the longing thing wearing them.",
		list(
			/mob/living/simple_animal/hostile/understudy = 1,
		),
		boss = TRUE)

	AddNode("zeal_s2n2", "zeal_s2n2_spawns",
		"Sector 2, Act II: The Altar in the Clinic",
		"The next scene is staged in a clinic that has finished turning \
			into a fleshly temple. A bloody copy of a polite man we may \
			have met stands at its altar, and every drop spilt here \
			belongs to him.",
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
			it can keep them. It only ever wanted to be more than it was.",
		list(
			/mob/living/simple_animal/hostile/mirror_shattered_reaper/refracted = 1,
		),
		boss = TRUE)

	AddNode("zeal_s3n2", "zeal_s3n2_spawns",
		"Sector 3, Act II: A Lit Window in the Snow",
		"The line bends through a clearing. A small wooden cabin sits in \
			fresh snow, its windows yellow with warmth. Step closer and \
			the snow turns dense, drawing in toward the windows. Inside, \
			something is being kept safe. Whatever it is, it would rather \
			no one ever found it.",
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
			believes he is helping.",
		list(
			// TODO: replace with The Distorted Priest boss mob (lore_notes.md)
			/mob/living/simple_animal/hostile/netherworld/migo/refracted = 1,
		),
		boss = TRUE)

	AddNode("zeal_s4n2", "zeal_s4n2_spawns",
		"Sector 4, Act II: The Apotheosis",
		"Someone who came onto the platform to play the lead, and stopped \
			being lead-of-a-play somewhere along the way. The stage has \
			become a temple under her feet; the audience worships in the \
			wings. She will not come down on her own.",
		list(
			/mob/living/simple_animal/hostile/achiyalabopa/refracted = 1,
		),
		boss = TRUE,
		extra_preview = list(
			/mob/living/simple_animal/hostile/mirage_reaper,
			/mob/living/simple_animal/hostile/mirage_reaper/v2,
		))

	// ----- Sector 5: Curtain Fall -----
	AddNode("serio_zeal", "serio_zeal_spawns",
		"Curtain Fall: The Author Onstage",
		"Whoever has been rehearsing this with us steps out from behind \
			the curtain. They have been watching this whole time, and \
			they are proud of the show.",
		list(
			// TODO: replace with the real Serio Zeal boss mob
			/mob/living/simple_animal/hostile/netherworld/migo/refracted = 1,
		),
		boss = TRUE)

	sector_briefings = list(
		list(
			"name"        = "Sector 1: The Opening Bill",
			"description" = "The first act of a play is always cheap, the \
				playbill insists. A street brawl. A loaded dice game. The \
				director borrowed two performers from the city below and \
				put them under the stage lights just to see if we'd notice \
				the difference.",
			"node_ids"    = list("zeal_s1n1", "zeal_s1n2"),
		),
		list(
			"name"        = "Sector 2: The Sin Plays",
			"description" = "The next two performers are not playing roles; \
				they are the role. One of them wants to be everyone in the \
				audience. The other wants what those people are holding. \
				They are very honest about it.",
			"node_ids"    = list("zeal_s2n1", "zeal_s2n2"),
		),
		list(
			"name"        = "Sector 3: Where the Stage Folds",
			"description" = "The set folds the way it was rehearsed to. \
				Through one crack, more of someone than the audience can \
				keep track of. Through another, a cottage in fresh snow \
				that takes its mark on cue. The playhouse is more than a \
				playhouse this act.",
			"node_ids"    = list("zeal_s3n1", "zeal_s3n2"),
		),
		list(
			"name"        = "Sector 4: After Humanity",
			"description" = "Two performers who are no longer playing human \
				roles. One because he believed he could carve the human out \
				and keep the better half; one because she became something \
				past being human and her audience agreed. They will not \
				return on their own.",
			"node_ids"    = list("zeal_s4n1", "zeal_s4n2"),
		),
		list(
			"name"        = "Sector 5: Curtain Fall",
			"description" = "The director steps onto the stage in person. \
				They mean every word of the story they have written for us, \
				and they will see it finished.",
			"node_ids"    = list("serio_zeal"),
		),
	)
