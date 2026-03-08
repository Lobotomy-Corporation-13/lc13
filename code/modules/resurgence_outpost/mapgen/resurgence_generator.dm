/// Random offset applied to coordinates for biome border intermingling
#define RESURGENCE_BIOME_DRIFT 2

/datum/map_generator/resurgence_generator

/// Generates terrain using a single Perlin noise layer for humidity
/datum/map_generator/resurgence_generator/generate_terrain(list/turfs)
	. = ..()
	var/humidity_seed = rand(0, 50000)
	var/perlin_zoom = 65

	for(var/t in turfs)
		var/turf/gen_turf = t
		var/drift_x = (gen_turf.x + rand(-RESURGENCE_BIOME_DRIFT, RESURGENCE_BIOME_DRIFT)) / perlin_zoom
		var/drift_y = (gen_turf.y + rand(-RESURGENCE_BIOME_DRIFT, RESURGENCE_BIOME_DRIFT)) / perlin_zoom

		var/humidity = text2num(rustg_noise_get_at_coordinates("[humidity_seed]", "[drift_x]", "[drift_y]"))

		var/datum/biome/selected_biome
		if(humidity < 0.5)
			selected_biome = /datum/biome/resurgence/desert
		else
			selected_biome = /datum/biome/resurgence/wasteland

		selected_biome = SSmapping.biomes[selected_biome]
		selected_biome.generate_turf(gen_turf)
		CHECK_TICK
