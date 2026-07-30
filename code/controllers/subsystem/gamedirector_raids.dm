// This file contains the raid tier and seed type setup procs for the gamedirector subsystem
// Split into a separate file for organization

/datum/controller/subsystem/gamedirector/proc/SetupRaidTiers()
	raid_tiers = list(
		// Basic scout party
		list(
			"name" = "Scout Patrol",
			"min_rarity" = 1,
			"max_rarity" = 2,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/scout/greed = 8,
				/mob/living/simple_animal/hostile/clan/drone/greed = 2
			)
		),
		// Drone support team
		list(
			"name" = "Support Squad",
			"min_rarity" = 1,
			"max_rarity" = 2,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/ranged/gunner/greed = 4,
				/mob/living/simple_animal/hostile/clan/ranged/rapid/greed = 2,
				/mob/living/simple_animal/hostile/clan/drone/greed = 1
			)
		),
		// Rapid response
		list(
			"name" = "Rapid Response",
			"min_rarity" = 2,
			"max_rarity" = 5,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/ranged/gunner/greed = 3,
				/mob/living/simple_animal/hostile/clan/scout/greed = 6
			)
		),
		// Bomber spider swarm
		list(
			"name" = "Spider Swarm",
			"min_rarity" = 1,
			"max_rarity" = 6,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/bomber_spider/greed = 8
			)
		),
		// Sniper with drone support
		list(
			"name" = "Sniper Team",
			"min_rarity" = 1,
			"max_rarity" = 2,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/ranged/sniper/greed = 3,
				/mob/living/simple_animal/hostile/clan/drone/greed = 2
			)
		),
		// Gunner squad
		list(
			"name" = "Gunner Squad",
			"min_rarity" = 4,
			"max_rarity" = 7,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/ranged/gunner/greed = 3,
				/mob/living/simple_animal/hostile/clan/ranged/rapid/greed = 5
			)
		),
		// Defensive formation
		list(
			"name" = "Shield Wall",
			"min_rarity" = 5,
			"max_rarity" = 8,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/defender/greed = 2,
				/mob/living/simple_animal/hostile/clan/ranged/gunner/greed = 5,
				/mob/living/simple_animal/hostile/clan/drone/greed = 1
			)
		),
		// Assassin strike team
		list(
			"name" = "Shadow Strike",
			"min_rarity" = 5,
			"max_rarity" = 9,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/assassin/greed = 2,
				/mob/living/simple_animal/hostile/clan/scout/greed = 7
			)
		),
		// Mixed assault
		list(
			"name" = "Assault Team",
			"min_rarity" = 6,
			"max_rarity" = 9,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/defender/greed = 1,
				/mob/living/simple_animal/hostile/clan/ranged/gunner/greed = 4,
				/mob/living/simple_animal/hostile/clan/ranged/rapid/greed = 4,
				/mob/living/simple_animal/hostile/clan/bomber_spider/greed = 2
			)
		),
		// Sniper overwatch
		list(
			"name" = "Overwatch",
			"min_rarity" = 7,
			"max_rarity" = 10,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/ranged/sniper/greed = 6,
				/mob/living/simple_animal/hostile/clan/defender/greed = 3,
				/mob/living/simple_animal/hostile/clan/drone/greed = 1
			)
		),
		// Warper teleport assault
		list(
			"name" = "Warp Strike",
			"min_rarity" = 5,
			"max_rarity" = 11,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/ranged/warper/greed = 1,
				/mob/living/simple_animal/hostile/clan/assassin/greed = 2,
				/mob/living/simple_animal/hostile/clan/scout/greed = 8
			)
		),
		// Harpooner ambush
		list(
			"name" = "Hook Squad",
			"min_rarity" = 6,
			"max_rarity" = 11,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/ranged/harpooner/greed = 3,
				/mob/living/simple_animal/hostile/clan/ranged/gunner/greed = 6,
				/mob/living/simple_animal/hostile/clan/bomber_spider/greed = 2
			)
		),
		// Heavy assault with demolisher
		list(
			"name" = "Siege Force",
			"min_rarity" = 9,
			"max_rarity" = 20,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/demolisher/greed = 1,
				/mob/living/simple_animal/hostile/clan/defender/greed = 2,
				/mob/living/simple_animal/hostile/clan/drone/greed = 2,
				/mob/living/simple_animal/hostile/clan/ranged/gunner/greed = 6
			)
		),
		// Elite strike force
		list(
			"name" = "Elite Strike",
			"min_rarity" = 10,
			"max_rarity" = 20,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/assassin/greed = 3,
				/mob/living/simple_animal/hostile/clan/ranged/sniper/greed = 4,
				/mob/living/simple_animal/hostile/clan/ranged/warper/greed = 3
			)
		),
		// Maximum spider chaos
		list(
			"name" = "Spider Apocalypse",
			"min_rarity" = 10,
			"max_rarity" = 20,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/bomber_spider/greed = 14
			)
		),
		// Combined arms
		list(
			"name" = "Combined Arms",
			"min_rarity" = 11,
			"max_rarity" = 20,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/ranged/warper/greed = 1,
				/mob/living/simple_animal/hostile/clan/ranged/harpooner/greed = 1,
				/mob/living/simple_animal/hostile/clan/assassin/greed = 1,
				/mob/living/simple_animal/hostile/clan/ranged/sniper/greed = 1,
				/mob/living/simple_animal/hostile/clan/defender/greed = 1,
				/mob/living/simple_animal/hostile/clan/ranged/gunner/greed = 1,
				/mob/living/simple_animal/hostile/clan/ranged/rapid/greed = 6
			)
		),
		// Ultimate assault
		list(
			"name" = "Apocalypse Squad",
			"min_rarity" = 12,
			"max_rarity" = 20,
			"composition" = list(
				/mob/living/simple_animal/hostile/clan/demolisher/greed = 1,
				/mob/living/simple_animal/hostile/clan/ranged/warper/greed = 2,
				/mob/living/simple_animal/hostile/clan/ranged/harpooner/greed = 4,
				/mob/living/simple_animal/hostile/clan/assassin/greed = 2,
				/mob/living/simple_animal/hostile/clan/bomber_spider/greed = 3,
				/mob/living/simple_animal/hostile/clan/ranged/rapid/greed = 6
			)
		)
	)

/datum/controller/subsystem/gamedirector/proc/SetupSeedTypes()
	seed_types = list(
		list(
			"min_rarity" = 1,
			"max_rarity" = 4,
			"types" = list(
				/obj/structure/seed_of_greed/basic/level1,
				/obj/structure/seed_of_greed/shield/level1,
				/obj/structure/seed_of_greed/defensive/level1
			)
		),
		list(
			"min_rarity" = 5,
			"max_rarity" = 8,
			"types" = list(
				/obj/structure/seed_of_greed/basic/level2,
				/obj/structure/seed_of_greed/shield/level2,
				/obj/structure/seed_of_greed/defensive/level2,
				/obj/structure/seed_of_greed/assault/level1
			)
		),
		list(
			"min_rarity" = 9,
			"max_rarity" = 12,
			"types" = list(
				/obj/structure/seed_of_greed/basic/level3,
				/obj/structure/seed_of_greed/shield/level3,
				/obj/structure/seed_of_greed/defensive/level3,
				/obj/structure/seed_of_greed/assault/level2,
				/obj/structure/seed_of_greed/assault/level3
			)
		)
	)
