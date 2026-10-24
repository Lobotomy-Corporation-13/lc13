//used for holding information about unique properties of maps
//feed it json files that match the datum layout
//defaults to box
//  -Cyberboss

/datum/map_config
	// Metadata
	var/config_filename = "_maps/alphacorp.json"
	var/defaulted = TRUE  // set to FALSE by LoadConfig() succeeding
	// Config from maps.txt
	var/config_max_users = 0
	var/config_min_users = 0
	var/voteweight = 1
	var/votable = FALSE

	// Config actually from the JSON - should default to Meta
	var/map_name = "Facility A-098 ALPHA"
	var/map_path = "map_files/Alpha"
	var/map_file = "alphacorp.dmm"
	var/maptype = "standard"

	var/traits = null
	var/space_ruin_levels = 0
	var/space_empty_levels = 0

	var/minetype = "none"
	var/faction = "Station"

	var/allow_custom_shuttles = TRUE
	var/shuttles = list(
		"cargo" = "cargo_box",
		"ferry" = "ferry_fancy",
		"whiteship" = "whiteship_box",
		"emergency" = "emergency_box")

	/// Dictionary of job sub-typepath to template changes dictionary
	var/job_changes = list()

	/// If this map has multiple submaps to choose from.
	var/has_submaps = FALSE
	/// What happens when no submap is chosen?
	// code/__DEFINES/configuration.dm: current options are SUBMAP_DEFAULT_STANDARD ("standard") and SUBMAP_DEFAULT_RANDOM ("random")
	var/no_submap_behavior = SUBMAP_DEFAULT_STANDARD
	/// List of available submaps if has_submaps was set
	// This should be an associative list. The keys are the map files and their value is their display name.
	// e.g: "city.dmm": "Standard City"
	var/list/available_submaps = list()

/proc/load_map_config(filename = "data/next_map.json", default_to_box, delete_after, error_if_missing = TRUE)
	var/datum/map_config/config = new
	if (default_to_box)
		return config
	if (!config.LoadConfig(filename, error_if_missing))
		qdel(config)
		config = new /datum/map_config  // Fall back to Box
	if (delete_after)
		fdel(filename)
	return config

#define CHECK_EXISTS(X) if(!istext(json[X])) { log_world("[##X] missing from json!"); return; }
/datum/map_config/proc/LoadConfig(filename, error_if_missing)
	if(!fexists(filename))
		if(error_if_missing)
			log_world("map_config not found: [filename]")
		return

	var/json = file(filename)
	if(!json)
		log_world("Could not open map_config: [filename]")
		return

	json = file2text(json)
	if(!json)
		log_world("map_config is not text: [filename]")
		return

	json = json_decode(json)
	if(!json)
		log_world("map_config is not json: [filename]")
		return

	config_filename = filename

	if(!json["version"])
		log_world("map_config missing version!")
		return

	if(json["version"] != MAP_CURRENT_VERSION)
		log_world("map_config has invalid version [json["version"]]!")
		return

	CHECK_EXISTS("map_name")
	map_name = json["map_name"]
	CHECK_EXISTS("map_path")
	map_path = json["map_path"]
	CHECK_EXISTS("maptype")
	maptype = json["maptype"]

	map_file = json["map_file"]
	// "map_file": "MetaStation.dmm"
	if(istext(map_file))
		if (!fexists("_maps/[map_path]/[map_file]"))
			log_world("Map file ([map_path]/[map_file]) does not exist!")
			return
	// "map_file": ["Lower.dmm", "Upper.dmm"]
	else if(islist(map_file))
		for(var/file in map_file)
			if(!fexists("_maps/[map_path]/[file]"))
				log_world("Map file ([map_path]/[file]) does not exist!")
				return
	else
		log_world("map_file missing from json!")
		return

	has_submaps = json["has_submaps"]
	// Just in case someone puts weird stuff in this field
	if(has_submaps != TRUE)
		has_submaps = FALSE
	else
		has_submaps = TRUE

	// If this is a map with submaps available, make sure all the listed ones have files for them.
	if(has_submaps)
		available_submaps = json["available_submaps"]
		if(islist(json["available_submaps"]) && length(available_submaps) > 1)
			for(var/file in available_submaps)
				if(!fexists("_maps/[map_path]/[file]"))
					log_world("Submap file ([map_path]/[file]) does not exist!")
					return
		no_submap_behavior = json["no_submap_behavior"]

	if(islist(json["shuttles"]))
		var/list/L = json["shuttles"]
		for(var/key in L)
			var/value = L[key]
			shuttles[key] = value
	else if("shuttles" in json)
		log_world("map_config shuttles is not a list!")
		return

	traits = json["traits"]
	// "traits": [{"Linkage": "Cross"}, {"Space Ruins": true}]
	if (islist(traits))
		// "Station" is set by default, but it's assumed if you're setting
		// traits you want to customize which level is cross-linked
		for (var/level in traits)
			if (!(ZTRAIT_STATION in level))
				level[ZTRAIT_STATION] = TRUE
	// "traits": null or absent -> default
	else if (!isnull(traits))
		log_world("map_config traits is not a list!")
		return

	var/temp = json["space_ruin_levels"]
	if (isnum(temp))
		space_ruin_levels = temp
	else if (!isnull(temp))
		log_world("map_config space_ruin_levels is not a number!")
		return

	temp = json["space_empty_levels"]
	if (isnum(temp))
		space_empty_levels = temp
	else if (!isnull(temp))
		log_world("map_config space_empty_levels is not a number!")
		return

	if ("minetype" in json)
		minetype = json["minetype"]

	if("faction" in json)
		faction = json["faction"]

	allow_custom_shuttles = json["allow_custom_shuttles"] != FALSE

	if ("job_changes" in json)
		if(!islist(json["job_changes"]))
			log_world("map_config \"job_changes\" field is missing or invalid!")
			return
		job_changes = json["job_changes"]

	if("maptype" in json)
		maptype = json["maptype"]

	defaulted = FALSE
	return TRUE
#undef CHECK_EXISTS

/datum/map_config/proc/GetFullMapPaths()
	if (istext(map_file))
		return list("_maps/[map_path]/[map_file]")
	. = list()
	for (var/file in map_file)
		. += "_maps/[map_path]/[file]"

/datum/map_config/proc/MakeNextMap()
	// If we have a selected submap, we need to write a new JSON with just that file
	if(has_submaps && istext(map_file))
		var/json_value = list(
			"version" = MAP_CURRENT_VERSION,
			"map_name" = map_name,
			"map_path" = map_path,
			"map_file" = map_file, // This is now a single file, not a list
			"shuttles" = shuttles,
			"traits" = traits,
			"space_ruin_levels" = space_ruin_levels,
			"space_empty_levels" = space_empty_levels,
			"minetype" = minetype,
			// These two help us identify when we're already playing on a submap for certain reasons like the stat panel accurately displaying its name
			"has_submaps" = has_submaps,
			"available_submaps" = available_submaps
		)

		if(faction)
			json_value["faction"] = faction
		if(job_changes && length(job_changes))
			json_value["job_changes"] = job_changes
		if(maptype)
			json_value["maptype"] = maptype

		// Remove old file and write new one
		if(fexists("data/next_map.json"))
			fdel("data/next_map.json")
		text2file(json_encode(json_value), "data/next_map.json")
		return TRUE

	// Default behavior - just copy the file
	return config_filename == "data/next_map.json" || fcopy(config_filename, "data/next_map.json")

/datum/map_config/proc/SetSelectedSubmap(selected_file)
	if(!has_submaps)
		return FALSE
	// We got "random" as our selected_file. Random submap!
	if(selected_file == SUBMAP_DEFAULT_RANDOM)
		return RandomSubmap()
	// We didn't get a selected file, but we have submaps. Choose one based on a possibly defined no_submap_behavior
	if(!selected_file && islist(available_submaps) && length(available_submaps) > 1)
		switch(no_submap_behavior)
			// Pick the very first listed available submap as the default.
			if(SUBMAP_DEFAULT_STANDARD)
				map_file = available_submaps[1]
				to_chat(world, span_boldannounce("Map variant set to the default: [available_submaps[map_file]]"))
				return TRUE
			// Pick a random submap.
			if(SUBMAP_DEFAULT_RANDOM)
				return RandomSubmap()

		// We don't have a defined no_submap_behavior...
		return FALSE

	map_file = selected_file
	to_chat(world, span_boldannounce("Map variant selected: [available_submaps[map_file]]"))

	return TRUE

/datum/map_config/proc/RandomSubmap()
	if(!has_submaps)
		return FALSE
	var/picked = pick(available_submaps)
	map_file = picked
	to_chat(world, span_boldannounce("Map variant randomly rolled to: [available_submaps[map_file]]"))
	return TRUE
