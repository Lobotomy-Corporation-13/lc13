/obj/machinery/city_weather_monitor
	name = "city weather monitor"
	desc = "A machine that monitors atmospheric conditions and predicts incoming storms."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "tdoppler"
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE

/obj/machinery/city_weather_monitor/Initialize()
	. = ..()
	update_icon()

/obj/machinery/city_weather_monitor/update_icon()
	. = ..()
	if(machine_stat & (BROKEN|NOPOWER))
		icon_state = "[initial(icon_state)]-broken"
	else
		icon_state = initial(icon_state)

/obj/machinery/city_weather_monitor/examine(mob/user)
	. = ..()
	if(machine_stat & (BROKEN|NOPOWER))
		. += span_warning("It appears to be non-functional.")
		return

	if(!GLOB.city_weather_controller)
		. += span_notice("No weather system detected.")
		return

	. += span_notice("Weather Status: [GLOB.city_weather_controller.GetStatus()]")
	if(!GLOB.city_weather_controller.storm_active)
		. += span_notice("Next storm: [GLOB.city_weather_controller.GetTimeToNextStorm()]")

/obj/machinery/city_weather_monitor/attack_hand(mob/user)
	. = ..()
	if(.)
		return

	if(machine_stat & (BROKEN|NOPOWER))
		to_chat(user, span_warning("[src] is not functioning!"))
		return

	ui_interact(user)

/obj/machinery/city_weather_monitor/ui_interact(mob/user, datum/tgui/ui)
	if(machine_stat & (BROKEN|NOPOWER))
		return

	if(!GLOB.city_weather_controller)
		to_chat(user, span_notice("No weather system detected. The skies are clear."))
		return

	var/message = "<div class='notice'>"
	message += "<b>City Weather Monitoring System</b><br>"
	message += "━━━━━━━━━━━━━━━━━━━━<br>"

	if(GLOB.city_weather_controller.storm_active)
		message += "<span class='danger'><b>⚠ FREEZING STORM ACTIVE ⚠</b></span><br>"
		message += "Seek shelter immediately!<br>"
		message += "Prolonged exposure causes:<br>"
		message += "• Movement impairment<br>"
		message += "• Hypothermia<br>"
		message += "• Tissue damage at extreme exposure<br>"
	else
		message += "<b>Current Conditions:</b> Clear<br>"
		message += "<b>Next Storm ETA:</b> [GLOB.city_weather_controller.GetTimeToNextStorm()]<br>"
		message += "<br>"
		message += "<b>Storm Advisory:</b><br>"
		message += "• Duration: 4-6 minutes<br>"
		message += "• Indoor areas provide shelter<br>"
		message += "• Cold exposure stacks up to 10 levels<br>"
		message += "• Level 8+ causes tissue damage<br>"

	message += "━━━━━━━━━━━━━━━━━━━━<br>"
	message += "<i>Stay safe, stay warm.</i>"
	message += "</div>"

	to_chat(user, message)

	// Visual feedback
	playsound(src, 'sound/machines/terminal_select.ogg', 25, TRUE)

/obj/machinery/city_weather_monitor/attackby(obj/item/I, mob/user, params)
	if(default_deconstruction_screwdriver(user, "[initial(icon_state)]_open", initial(icon_state), I))
		return

	if(default_deconstruction_crowbar(I))
		return

	return ..()

/obj/machinery/city_weather_monitor/emp_act(severity)
	. = ..()
	if(machine_stat & (BROKEN|NOPOWER))
		return

	if(prob(50 / severity))
		set_machine_stat(machine_stat | BROKEN)
		update_icon()
