/*
 * Line 1: Nova Flare. Three sectors of three nodes each.
 * Authoring conventions: see code/modules/refraction_railway/AUTHORING.md.
 */

/area/refraction/nova_flare
	name = "Refraction Railway: Nova Flare"
	icon_state = "blue"

/datum/refraction_line/nova_flare
	id                  = "nova_flare"
	name                = "Line 1: Nova Flare"
	description         = "As the Young Star steps on to the empty stage, they take it upon themselves to fill this stage with their tales. Only then, they shall make an impact on their unseen audience."
	map_path            = "_maps/refraction_railway/nova_flare.dmm"
	attribute_set_value = 80
	max_lobby_size      = 4
	section_count       = 3
	display_color       = "#1e4ba8"

	// Nova Flare enforces unique loadouts per sector: a weapon or armor
	// piece chosen in a prior sector this run gets crossed out and locked
	// in the loadout UI on subsequent sectors.
	unique_loadout_per_sector = TRUE

	map_viewbox = list("w" = 600, "h" = 400)

	// 13 visual nodes laid out as a top-to-bottom snake.
	nodes = list(
		list("x" = 50,  "y" = 80,  "kind" = "start"),       //  1
		list("x" = 150, "y" = 80,  "kind" = "combat"),      //  2  s1n1
		list("x" = 250, "y" = 80,  "kind" = "combat"),      //  3  s1n2
		list("x" = 350, "y" = 80,  "kind" = "combat"),      //  4  s1n3
		list("x" = 450, "y" = 80,  "kind" = "checkpoint"),  //  5
		list("x" = 450, "y" = 200, "kind" = "combat"),      //  6  s2n1
		list("x" = 350, "y" = 200, "kind" = "combat"),      //  7  s2n2
		list("x" = 250, "y" = 200, "kind" = "combat"),      //  8  s2n3
		list("x" = 150, "y" = 200, "kind" = "checkpoint"),  //  9
		list("x" = 150, "y" = 320, "kind" = "combat"),      // 10  s3n1
		list("x" = 250, "y" = 320, "kind" = "combat"),      // 11  s3n2
		list("x" = 350, "y" = 320, "kind" = "boss"),        // 12  nova_core
		list("x" = 450, "y" = 320, "kind" = "finish"),      // 13
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
		list("from" = 12, "to" = 13, "shape" = "curve", "dashed" = TRUE),
	)

	recommended_tier_lines = list(
		"- Bring E.G.O. with stat requirements around 80.",
	)

/datum/refraction_line/nova_flare/New()
	. = ..()

	// ----- Sector 1: Outer Reach -----
	AddNode("nova_s1n1", "nova_s1n1_spawns",
		"The Gap",
		"The line thins here. Something the railway should have kept out is \
			already through.",
		list(
			/mob/living/simple_animal/hostile/netherworld/migo/refracted = 6,
		),
		c_max = 3)

	AddNode("nova_s1n2", "nova_s1n2_spawns",
		"The Family",
		"A side gallery the survivors never left. They still call each \
			other by name.",
		list(
			/mob/living/simple_animal/hostile/mutant_clown/refracted = 3,
			/mob/living/simple_animal/hostile/mutant_clown/refracted/sister = 2,
			/mob/living/simple_animal/hostile/mutant_clown/refracted/mother = 1,
		),
		c_max = 3)

	AddNode("nova_s1n3", "nova_s1n3_spawns",
		"The Grandfather",
		"The sector ends here. The Grandfather will not fall while the hearts \
			still beat for it.",
		list(
			/mob/living/simple_animal/hostile/mutant_clown/boss/refracted = 1,
		),
		boss = TRUE,
		extra_preview = list(
			/mob/living/simple_animal/hostile/mutant_heart/refracted,
			/mob/living/simple_animal/hostile/mutant_clown/refracted,
			/mob/living/simple_animal/hostile/mutant_clown/refracted/sister,
			/mob/living/simple_animal/hostile/mutant_clown/refracted/mother,
		))

	// ----- Sector 2: the Garden Below -----
	AddNode("nova_s2n1", "nova_s2n1_spawns",
		"The Hive",
		"Gel and resin coat the walls. The nests do not stop feeding the \
			air with wings.",
		list(
			/mob/living/simple_animal/hostile/mad_fly_nest/refracted = 3,
		),
		c_max = 2,
		extra_preview = list(
			/mob/living/simple_animal/hostile/mad_fly_swarm/refracted,
		))

	AddNode("nova_s2n2", "nova_s2n2_spawns",
		"The Clan Wall",
		"Stone statues with a clan etched into their backs. They were left \
			here to hold the line, and they still do.",
		list(
			/mob/living/simple_animal/hostile/clan/stone_guard/refracted = 4,
		),
		c_max = 3)

	AddNode("nova_s2n3", "nova_s2n3_spawns",
		"The Scarlet Garden",
		"Red vines have taken the whole hall. Something at the center is \
			still feeding them.",
		list(
			/mob/living/simple_animal/hostile/scarlet_rose/refracted = 1,
		),
		boss = TRUE)

	// ----- Sector 3: the Tinkerer's Keep -----
	AddNode("nova_s3n1", "nova_s3n1_spawns",
		"The Vanguard",
		"A clan etched into steel backs holds the approach. One of them \
			walks the line mending the others.",
		list(
			/mob/living/simple_animal/hostile/clan/scout/refracted    = 4,
			/mob/living/simple_animal/hostile/clan/defender/refracted = 2,
			/mob/living/simple_animal/hostile/clan/drone/refracted    = 2,
		),
		c_max = 4)

	AddNode("nova_s3n2", "nova_s3n2_spawns",
		"The Firing Line",
		"The hall narrows under their guns. Get dragged out of cover and \
			the rest will not miss.",
		list(
			/mob/living/simple_animal/hostile/clan/ranged/gunner/refracted    = 3,
			/mob/living/simple_animal/hostile/clan/ranged/rapid/refracted     = 3,
			/mob/living/simple_animal/hostile/clan/ranged/harpooner/refracted = 2,
			/mob/living/simple_animal/hostile/clan/defender/refracted         = 1,
		),
		c_max = 4)

	AddNode("nova_core", "nova_core_spawns",
		"The Keeper",
		"The Tinkerer's guardian drops out of the dark to meet the \
			carriage. The line ends here.",
		list(
			/mob/living/simple_animal/hostile/clan/stone_keeper/refracted = 1,
		),
		boss = TRUE,
		extra_preview = list(
			/mob/living/simple_animal/hostile/keeper_piller/refracted,
		))

	sector_briefings = list(
		list(
			"name"        = "Sector 1: Outer Reach",
			"description" = "The edge of the line never sealed clean. The family \
				that came through it is here — and the one they all answer to \
				is waiting at the end.",
			"node_ids"    = list("nova_s1n1", "nova_s1n2", "nova_s1n3"),
		),
		list(
			"name"        = "Sector 2: the Garden Below",
			"description" = "The line runs through something overgrown. A hive \
				feeds the air, a clan holds the wall, and a red garden waits \
				over the far end.",
			"node_ids"    = list("nova_s2n1", "nova_s2n2", "nova_s2n3"),
		),
		list(
			"name"        = "Sector 3: the Tinkerer's Keep",
			"description" = "Past the garden the line was never abandoned. A \
				clan still holds it, and the Tinkerer's Keeper waits at the \
				end of the carriage's road.",
			"node_ids"    = list("nova_s3n1", "nova_s3n2", "nova_core"),
		),
	)
