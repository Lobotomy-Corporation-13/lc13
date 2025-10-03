GLOBAL_DATUM(city_weather_controller, /datum/city_weather_controller)

/datum/city_weather_controller
	var/active = FALSE
	var/next_storm_time = 0
	var/storm_active = FALSE
	var/datum/weather/city_freezing_storm/current_weather
	var/z_level
	var/min_time_between_storms = 10 MINUTES
	var/max_time_between_storms = 15 MINUTES
	var/min_storm_duration = 4 MINUTES
	var/max_storm_duration = 6 MINUTES

/datum/city_weather_controller/New(zlevel)
	..()
	z_level = zlevel
	active = TRUE
	ScheduleNextStorm()

/datum/city_weather_controller/proc/ScheduleNextStorm()
	if(!active)
		return

	var/delay = rand(min_time_between_storms, max_time_between_storms)
	next_storm_time = world.time + delay
	addtimer(CALLBACK(src, PROC_REF(StartStorm)), delay)

/datum/city_weather_controller/proc/StartStorm()
	if(!active || storm_active)
		return

	storm_active = TRUE
	var/duration = rand(min_storm_duration, max_storm_duration)

	// Start the weather
	SSweather.run_weather(/datum/weather/city_freezing_storm)

	// Schedule storm end
	addtimer(CALLBACK(src, PROC_REF(EndStorm)), duration)

/datum/city_weather_controller/proc/EndStorm()
	if(!active)
		return

	storm_active = FALSE
	SSweather.end_weather(/datum/weather/city_freezing_storm)

	ScheduleNextStorm()

/datum/city_weather_controller/proc/GetTimeToNextStorm()
	if(storm_active)
		return "Storm in progress"
	if(next_storm_time > world.time)
		var/time_left = next_storm_time - world.time
		return "[round(time_left / 600)] minutes"
	return "Any moment now"

/datum/city_weather_controller/proc/GetStatus()
	if(!active)
		return "System inactive"
	if(storm_active)
		return "Freezing storm active"
	return "Clear weather"
