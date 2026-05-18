/*
 * Line 1: Nova Flare.
 *
 * Three sectors of three nodes each. Mob composition is placeholder — to be
 * replaced once the line's final encounter design is locked. The third node
 * of sector 3 is the boss (is_boss = TRUE on the node datum).
 *
 * Companion files in this same directory:
 *   passives.dm — /datum/refraction_line/nova_flare/GetMobPassives() override
 *   attacks.dm  — /datum/refraction_line/nova_flare/GetMobAttacks() override
 *
 * Authoring conventions: see code/modules/refraction_railway/AUTHORING.md.
 */

/area/refraction/nova_flare
	name = "Refraction Railway: Nova Flare"
	icon_state = "blue"

/datum/refraction_line/nova_flare
	id                  = "nova_flare"
	name                = "Line 1: Nova Flare"
	description         = "The first run. Steel and starlight, in that order."
	map_path            = "_maps/refraction_railway/nova_flare.dmm"
	attribute_set_value = 80
	max_lobby_size      = 4
	section_count       = 3
	display_color       = "#1e4ba8"

	map_viewbox = list("w" = 600, "h" = 400)

	// 13 visual nodes laid out as a top-to-bottom snake:
	//   sector 1 left→right on row 1, drop to sector 2 right→left on row 2,
	//   drop to sector 3 left→right on row 3 ending in the boss + finish.
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

	// ----- Sector 2: Stellar Currents -----
	AddNode("nova_s2n1", "nova_s2n1_spawns",
		"Updraft",
		"Heated wind rises through the deck plates. Drones ride the thermals.",
		list(
			/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon         = 5,
			/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/flying  = 3,
		),
		c_max = 4)

	AddNode("nova_s2n2", "nova_s2n2_spawns",
		"Crossfire",
		"Two galleries open onto the same hall. Whoever's directing this \
			knows what crossfire is.",
		list(
			/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon = 4,
			/mob/living/simple_animal/hostile/lovetown/slasher             = 4,
		),
		c_max = 4)

	AddNode("nova_s2n3", "nova_s2n3_spawns",
		"Inner Corona",
		"The light here is no longer light. Glass cracks in the heat.",
		list(
			/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/flying = 5,
			/mob/living/simple_animal/hostile/ordeal/steel_dusk                   = 3,
		),
		c_max = 4)

	// ----- Sector 3: Heart -----
	AddNode("nova_s3n1", "nova_s3n1_spawns",
		"Approach",
		"Visibility falls off. The space ahead has been cleared by something \
			that intends to be alone in it.",
		list(
			/mob/living/simple_animal/hostile/ordeal/steel_dusk                   = 4,
			/mob/living/simple_animal/hostile/ordeal/steel_dawn/steel_noon/flying = 3,
		),
		c_max = 4)

	AddNode("nova_s3n2", "nova_s3n2_spawns",
		"Antechamber",
		"Honor guard. They were left here to be killed; whoever they \
			answered to has already moved on.",
		list(
			/mob/living/simple_animal/hostile/ordeal/steel_dusk     = 3,
			/mob/living/simple_animal/hostile/ordeal/sin_pride/noon = 4,
		),
		c_max = 4)

	AddNode("nova_core", "nova_core_spawns",
		"Core",
		"Whatever burns at the center of the flare. The carriage stops here.",
		list(
			/mob/living/simple_animal/hostile/lovetown/abomination = 1,
		),
		boss = TRUE)

	sector_briefings = list(
		list(
			"name"        = "Sector 1: Outer Reach",
			"description" = "The edge of the line never sealed clean. The family \
				that came through it is here — and the one they all answer to \
				is waiting at the end.",
			"node_ids"    = list("nova_s1n1", "nova_s1n2", "nova_s1n3"),
		),
		list(
			"name"        = "Sector 2: Stellar Currents",
			"description" = "Heat rises. Flying drones cut overhead — the corona is no longer just light.",
			"node_ids"    = list("nova_s2n1", "nova_s2n2", "nova_s2n3"),
		),
		list(
			"name"        = "Sector 3: Heart",
			"description" = "Whatever waits at the core of the flare has already \
				noticed us. The carriage burns ahead anyway.",
			"node_ids"    = list("nova_s3n1", "nova_s3n2", "nova_core"),
		),
	)
