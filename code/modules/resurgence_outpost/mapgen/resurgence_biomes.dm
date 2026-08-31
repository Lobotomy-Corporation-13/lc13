/// Desert biome - dry, sparse vegetation
/datum/biome/resurgence/desert
	turf_type = /turf/open/floor/plating/ironsand
	flora_types = list(
		/obj/structure/resurgence_tree/dead,
		/obj/structure/flora/ausbushes/grassybush,
		/obj/structure/flora/ausbushes/grassybush,
		/obj/structure/flora/ash/garden/arid,
		/obj/structure/flora/ash/garden/arid,
		/obj/structure/flora/ash/garden/arid
	)
	flora_density = 1

/// Wasteland biome - more humid, denser vegetation
/datum/biome/resurgence/wasteland
	turf_type = /turf/open/floor/plating/dirt/jungle/wasteland
	flora_types = list(
		/obj/structure/resurgence_wild_plant,
		/obj/structure/resurgence_wild_plant,
		/obj/structure/resurgence_wild_plant,
		/obj/structure/resurgence_wild_plant,
		/obj/structure/resurgence_wild_plant,
		/obj/structure/resurgence_tree,
		/obj/structure/resurgence_tree/oak,
		/obj/structure/flora/ash/garden/waste
	)
	flora_density = 3
