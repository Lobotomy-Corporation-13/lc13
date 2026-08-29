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
	// 9 minutes target for the Starlight time bonus.
	expected_time_seconds = 540

	unique_loadout_per_sector = FALSE

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
		list("x" = 350, "y" = 320, "kind" = "combat"),      // 12  nova_core
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
		list("from" = 12, "to" = 13, "shape" = "line"),
	)

	recommended_tier_lines = list(
		"- Bring E.G.O. with stat requirements around 80.",
	)

/datum/refraction_line/nova_flare/New()
	. = ..()

	// ----- Sector 1: Outer Reach -----
	AddNode("nova_s1n1", "nova_s1n1_spawns",
		"The Cries",
		"There is something echoing in the distance, no... They are still screaming for their mentor who shall never reach them.",
		list(
			/mob/living/simple_animal/hostile/netherworld/migo/refracted = 6,
		),
		c_max = 3)

	AddNode("nova_s1n2", "nova_s1n2_spawns",
		"The Family",
		"The same family is still here, still playing the parts they walked in with. The patriarch never came home, and the household has not allowed itself to know it.",
		list(
			/mob/living/simple_animal/hostile/mutant_clown/refracted = 3,
			/mob/living/simple_animal/hostile/mutant_clown/refracted/sister = 2,
			/mob/living/simple_animal/hostile/mutant_clown/refracted/mother = 1,
		),
		c_max = 3)

	AddNode("nova_s1n3", "nova_s1n3_spawns",
		"The Grandfather",
		"The family now cries into the depths of their false shelter. They have endured for so long, HE will be able to fix them again. Just as he kept them togther though this hell.",
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
		"The temple sings with a wet hum now. The scholars who first studied the brood are no longer in the building, and the brood has finished inheriting what they left behind.",
		list(
			/mob/living/simple_animal/hostile/mad_fly_nest/refracted = 3,
		),
		c_max = 2,
		extra_preview = list(
			/mob/living/simple_animal/hostile/mad_fly_swarm/refracted,
		))

	AddNode("nova_s2n2", "nova_s2n2_spawns",
		"The Fallen Guard",
		"The statues still stand watch. The clan that carved them and gave them their post has been quiet for a long age, and none of the elders who remain ever came back to call the watch done.",
		list(
			/mob/living/simple_animal/hostile/clan/stone_guard/refracted = 4,
		),
		c_max = 3)

	AddNode("nova_s2n3", "nova_s2n3_spawns",
		"The Scarlet Garden",
		"Red vines have taken the whole hall. Yet... is there not beauty in watching such a foul place, be returned to nature? It has been contained for far too long, it's only fair for it to feast.",
		list(
			/mob/living/simple_animal/hostile/scarlet_rose/refracted = 1,
		),
		boss = TRUE)

	// ----- Sector 3: the Tinkerer's Keep -----
	AddNode("nova_s3n1", "nova_s3n1_spawns",
		"The Vanguard",
		"The clan's plating, the clan's marching gait, the clan's old cadence kept out of habit. The eyes inside the visors glow the wrong color, and the will those eyes used to answer to was given up — or taken — somewhere a long time ago.",
		list(
			/mob/living/simple_animal/hostile/clan/scout/refracted    = 4,
			/mob/living/simple_animal/hostile/clan/defender/refracted = 2,
			/mob/living/simple_animal/hostile/clan/drone/refracted    = 2,
		),
		c_max = 4)

	AddNode("nova_s3n2", "nova_s3n2_spawns",
		"The Firing Line",
		"The hall is full of guns held by hands that no longer answer their own names. The one moving them was once a member of the clan; he no longer thinks of them that way.",
		list(
			/mob/living/simple_animal/hostile/clan/ranged/gunner/refracted    = 3,
			/mob/living/simple_animal/hostile/clan/ranged/rapid/refracted     = 3,
			/mob/living/simple_animal/hostile/clan/ranged/harpooner/refracted = 2,
			/mob/living/simple_animal/hostile/clan/defender/refracted         = 1,
		),
		c_max = 4)

	AddNode("nova_core", "nova_core_spawns",
		"The Keeper",
		"The hand that once mended the clan's cores has been gone for a long time. What it has built in its absence drops out of the dark to meet the carriage. The line ends here.",
		list(
			/mob/living/simple_animal/hostile/clan/stone_keeper/refracted = 1,
		),
		boss = TRUE,
		extra_preview = list(
			/mob/living/simple_animal/hostile/keeper_piller/refracted,
		))

	sector_briefings = list(
		list(
			"name"        = "Sector 1: What the Family Kept",
			"description" = "A family at the edge of the line, still gathered \
				around the one they grieve. They have not allowed anything \
				to change.",
			"node_ids"    = list("nova_s1n1", "nova_s1n2", "nova_s1n3"),
		),
		list(
			"name"        = "Sector 2: The Hollow Temple",
			"description" = "A place once kept holy now stands hollow. Roots \
				have taken the columns; whatever the scholars here were \
				studying, the building has long since forgotten.",
			"node_ids"    = list("nova_s2n1", "nova_s2n2", "nova_s2n3"),
		),
		list(
			"name"        = "Sector 3: Under Other Eyes",
			"description" = "A clan still patrols this stretch, but the eyes \
				are wrong. Something behind them is driving, and what it has \
				built waits at the end of the road.",
			"node_ids"    = list("nova_s3n1", "nova_s3n2", "nova_core"),
		),
	)
