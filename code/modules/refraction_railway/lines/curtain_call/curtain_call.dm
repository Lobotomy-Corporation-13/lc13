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

	map_viewbox = list("w" = 900, "h" = 550)

	// 11 visual nodes arranged as the Sculptor constellation. The two
	// branches off node 6 (zeal_s3n1) are the deliberately broken-snake
	// connections that give the figure its constellation feel.
	nodes = list(
		list("x" = 50,  "y" = 130, "kind" = "start"),       //  1
		list("x" = 180, "y" = 80,  "kind" = "combat"),      //  2  s1n1
		list("x" = 300, "y" = 160, "kind" = "combat"),      //  3  s1n2
		list("x" = 420, "y" = 100, "kind" = "combat"),      //  4  s2n1
		list("x" = 520, "y" = 210, "kind" = "combat"),      //  5  s2n2
		list("x" = 380, "y" = 290, "kind" = "combat"),      //  6  s3n1
		list("x" = 240, "y" = 360, "kind" = "combat"),      //  7  s3n2
		list("x" = 470, "y" = 410, "kind" = "combat"),      //  8  s4n1
		list("x" = 640, "y" = 320, "kind" = "combat"),      //  9  s4n2
		list("x" = 740, "y" = 200, "kind" = "boss"),        // 10  serio_zeal
		list("x" = 850, "y" = 80,  "kind" = "finish"),      // 11
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

	// ----- Sector 1: Opening Act -----
	AddNode("zeal_s1n1", "zeal_s1n1_spawns",
		"Sector 1, Act I: The Capo and Their Rat",
		"A capo of the Thumb East family steps onto the platform with a \
			red-stained rat at their heel. They have rehearsed this scene.",
		list(
			/mob/living/simple_animal/hostile/thumb_east_capo/refracted = 1,
			/mob/living/simple_animal/hostile/rat/capo_rat/refracted   = 1,
		),
		c_max = 2,
		boss = TRUE)

	AddNode("zeal_s1n2", "zeal_s1n2_spawns",
		"Sector 1, Act II: Azarus, the House",
		"The Game Master deals a gambling demon onto the stage. Azarus scatters \
			loaded dice across the floor and calls a bet that cannot be dodged \
			- only out-gambled. Roll the table high to fold the House's hand.",
		list(
			/mob/living/simple_animal/hostile/azarus/refracted = 1,
		),
		boss = TRUE)

	// ----- Sector 2: Rising Action -----
	AddNode("zeal_s2n1", "zeal_s2n1_spawns",
		"Sector 2, Act I: The Envy of Humanity",
		"The next performer has no face of its own, so it borrows the \
			cast's. It will play role after role at us, and only between \
			costumes can you see the envious thing wearing them.",
		list(
			/mob/living/simple_animal/hostile/understudy = 1,
		),
		boss = TRUE)

	AddNode("zeal_s2n2", "zeal_s2n2_spawns",
		"Sector 2, Act II: The Greed Touched Clone",
		"The next scene is staged in a clinic that has finished turning \
			into a fleshly temple. A bloody copy of a polite man we may \
			have met stands at its altar, and every drop spilt here \
			belongs to him.",
		list(
			/mob/living/simple_animal/hostile/greed_touched_eric/refracted = 1,
		),
		boss = TRUE)

	// ----- Sector 3: The Twist -----
	AddNode("zeal_s3n1", "zeal_s3n1_spawns",
		"Sector 3, Act I: The One That Got Out",
		"This scene was not in the script. Something stepped through a \
			crack in the stage with too many versions of itself in tow, \
			and it is hunting the rest of them down so it can keep them. \
			It only ever wanted to be more than it was.",
		list(
			/mob/living/simple_animal/hostile/mirror_shattered_reaper/refracted = 1,
		),
		boss = TRUE)

	AddNode("zeal_s3n2", "zeal_s3n2_spawns",
		"Sector 3, Act II: <pending>",
		"<pending flavor — admin-event reference goes here>.",
		list(
			// TODO: replace with this sector's boss mob
			/mob/living/simple_animal/hostile/netherworld/migo/refracted = 1,
		),
		boss = TRUE)

	// ----- Sector 4: Climax -----
	AddNode("zeal_s4n1", "zeal_s4n1_spawns",
		"Sector 4, Act I: <pending>",
		"<pending flavor — admin-event reference goes here>.",
		list(
			// TODO: replace with this sector's boss mob
			/mob/living/simple_animal/hostile/netherworld/migo/refracted = 1,
		),
		boss = TRUE)

	AddNode("zeal_s4n2", "zeal_s4n2_spawns",
		"Sector 4, Act II: <pending>",
		"<pending flavor — admin-event reference goes here>.",
		list(
			// TODO: replace with this sector's boss mob
			/mob/living/simple_animal/hostile/netherworld/migo/refracted = 1,
		),
		boss = TRUE)

	// ----- Sector 5: Curtain Fall -----
	AddNode("serio_zeal", "serio_zeal_spawns",
		"Curtain Fall: Serio Zeal",
		"The Young Star steps out from behind the curtain. They have been \
			watching this whole time, and they are proud of the show.",
		list(
			// TODO: replace with the real Serio Zeal boss mob
			/mob/living/simple_animal/hostile/netherworld/migo/refracted = 1,
		),
		boss = TRUE)

	sector_briefings = list(
		list(
			"name"        = "Sector 1: The Opening Double-Bill",
			"description" = "The curtain rises on a double-bill — two headline \
				acts queued back to back before the show has even found its \
				feet. Clear one, and the next is already taking the stage.",
			"node_ids"    = list("zeal_s1n1", "zeal_s1n2"),
		),
		list(
			"name"        = "Sector 2: Rising Action",
			"description" = "The director is no longer holding back. Each \
				stop sharpens what the last one taught us — and what we did \
				not.",
			"node_ids"    = list("zeal_s2n1", "zeal_s2n2"),
		),
		list(
			"name"        = "Sector 3: The Twist",
			"description" = "Something the script did not promise is waiting \
				on the line. The director seems to have been counting on us \
				to notice.",
			"node_ids"    = list("zeal_s3n1", "zeal_s3n2"),
		),
		list(
			"name"        = "Sector 4: Climax",
			"description" = "The line tightens. Whatever the play was \
				building toward is here, in two pieces, before its author.",
			"node_ids"    = list("zeal_s4n1", "zeal_s4n2"),
		),
		list(
			"name"        = "Sector 5: Curtain Fall",
			"description" = "Serio Zeal — the Young Star — steps onto the \
				stage in person. They mean every word of the story they \
				have written for us, and they will see it finished.",
			"node_ids"    = list("serio_zeal"),
		),
	)
