/obj/effect/spawner/room/wcorp
	name = "wcorp facility spawner"
	icon_state = "random_room"
	room_width = 13
	room_height = 11
	room_type = "wcorp" // Used so we can place landmarks in ruins and such.

/*
 * Every one of these tiles on the main map is one car of the train, so counting them
 * tells the wave system how long the train is. This runs at mapload, well before any
 * room has actually loaded, so GLOB.wave_total_cars is settled before the round starts.
 *
 * Counting the loaded rooms instead would be a trap - they load on random timers, so the
 * count would still be climbing while players were already moving through the train.
 *
 * To run a longer or shorter train, add or remove these spawner tiles (and enough room
 * templates to fill them). The difficulty curve re-spreads itself, no code change needed.
 */
/obj/effect/spawner/room/wcorp/Initialize()
	. = ..()
	// Parent nulls template and qdels itself when there is no room left to claim
	if(template)
		GLOB.wave_total_cars++

/obj/effect/spawner/room/wcorp/LateSpawn()
	// Duplicates the parent so we can see whether the load actually succeeded - a room
	// that silently fails to load would leave wave_total_cars overcounted, which skews
	// the difficulty tier of every car after it
	var/turf/spawn_turf = get_turf(src)
	if(!template.load(spawn_turf, centered = template.centerspawner))
		GLOB.wave_total_cars--
		stack_trace("W-Corp room template [template.name] failed to load at [AREACOORD(spawn_turf)]")
	qdel(src)


/datum/map_template/random_room/wcorp
	centerspawner = FALSE
	template_width = 13
	template_height = 11
	room_type = "wcorp"
	weight = 0
	stock = 1


/datum/map_template/random_room/wcorp/carriage1
	name = "Wcorp - Carriage1"
	room_id = "wcorp_carriage1"
	mappath = "_maps/RandomRooms/wcorp/carriage1.dmm"
	weight = 5

/datum/map_template/random_room/wcorp/carriage2
	name = "Wcorp - Carriage2"
	room_id = "wcorp_carriage2"
	mappath = "_maps/RandomRooms/wcorp/carriage2.dmm"
	weight = 5

/datum/map_template/random_room/wcorp/firstclass1
	name = "Wcorp - First Class 1"
	room_id = "wcorp_firstclass1"
	mappath = "_maps/RandomRooms/wcorp/firstclass.dmm"
	weight = 5

/datum/map_template/random_room/wcorp/passenger1
	name = "Wcorp - passenger1"
	room_id = "wcorp_passenger1"
	mappath = "_maps/RandomRooms/wcorp/passenger1.dmm"
	weight = 5

/datum/map_template/random_room/wcorp/passenger2
	name = "Wcorp - passenger2"
	room_id = "wcorp_passenger2"
	mappath = "_maps/RandomRooms/wcorp/passenger2.dmm"
	weight = 5

/datum/map_template/random_room/wcorp/open1
	name = "Wcorp - Open1"
	room_id = "wcorp_open1"
	mappath = "_maps/RandomRooms/wcorp/open1.dmm"
	weight = 5

/datum/map_template/random_room/wcorp/open2
	name = "Wcorp - Open2"
	room_id = "wcorp_open2"
	mappath = "_maps/RandomRooms/wcorp/open2.dmm"
	weight = 5

/datum/map_template/random_room/wcorp/lounge
	name = "Wcorp - Lounge"
	room_id = "wcorp_lounge"
	mappath = "_maps/RandomRooms/wcorp/lounge.dmm"
	weight = 5

/datum/map_template/random_room/wcorp/library
	name = "Wcorp - Library"
	room_id = "wcorp_library"
	mappath = "_maps/RandomRooms/wcorp/library.dmm"
	weight = 5

/datum/map_template/random_room/wcorp/kitchen
	name = "Wcorp - Kitchen"
	room_id = "wcorp_kitchen"
	mappath = "_maps/RandomRooms/wcorp/kitchen.dmm"
	weight = 5

/datum/map_template/random_room/wcorp/stage
	name = "Wcorp - Stage"
	room_id = "wcorp_stage"
	mappath = "_maps/RandomRooms/wcorp/stage.dmm"
	weight = 5

/datum/map_template/random_room/wcorp/storage1
	name = "Wcorp - Storage 1"
	room_id = "wcorp_storage1"
	mappath = "_maps/RandomRooms/wcorp/storage1.dmm"
	weight = 5

/datum/map_template/random_room/wcorp/zoo
	name = "Wcorp - Zoo"
	room_id = "wcorp_zoo"
	mappath = "_maps/RandomRooms/wcorp/zoo.dmm"
	weight = 5
