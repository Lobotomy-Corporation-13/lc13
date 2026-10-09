/**
 * Resurgence Outpost - UV Light
 *
 * Coal-fueled growth lamp that boosts nearby farm plot growth by 250%.
 * Does not process on its own — farm plots check for nearby UV lights during zone ticks.
 */

/// Coal consumed per zone growth tick
#define UV_LIGHT_COAL_PER_TICK 1
/// Maximum coal capacity
#define UV_LIGHT_MAX_COAL 50
/// Range in tiles to affect farm plots
#define UV_LIGHT_RANGE 5
/// Growth multiplier applied to nearby plots
#define UV_LIGHT_GROWTH_MULT 2.5

/obj/structure/uv_light
	name = "UV growth light"
	desc = "A coal-powered ultraviolet lamp that accelerates plant growth in nearby farm plots."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "floodlight"
	density = TRUE
	anchored = TRUE

	/// Current coal fuel level
	var/coal_count = 0
	/// Maximum coal this machine can hold
	var/max_coal = UV_LIGHT_MAX_COAL
	/// Whether the light is currently active
	var/active = FALSE
	/// Tracks the last world.time fuel was consumed to prevent multi-burn per tick
	var/last_fuel_tick = 0

/obj/structure/uv_light/examine(mob/user)
	. = ..()
	. += span_notice("Coal: [coal_count]/[max_coal]")
	if(active)
		. += span_notice("The light is active and boosting nearby crops.")
	else if(coal_count > 0)
		. += span_notice("The light is off. Click to activate.")
	else
		. += span_warning("No fuel. Load coal to operate.")
	. += span_notice("Boosts farm plots within [UV_LIGHT_RANGE] tiles.")

/obj/structure/uv_light/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/sheet/mineral/coal))
		add_coal(I, user)
		return
	return ..()

/// Load coal into the UV light
/obj/structure/uv_light/proc/add_coal(obj/item/stack/sheet/mineral/coal/coal_stack, mob/user)
	var/space = max_coal - coal_count
	if(space <= 0)
		to_chat(user, span_warning("The coal hopper is full!"))
		return

	var/to_add = min(coal_stack.amount, space)
	coal_stack.use(to_add)
	coal_count += to_add

	to_chat(user, span_notice("You add [to_add] coal to the UV light. ([coal_count]/[max_coal])"))
	playsound(src, 'sound/items/deconstruct.ogg', 30, TRUE)

/obj/structure/uv_light/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return

	if(coal_count <= 0)
		to_chat(user, span_warning("There's no coal to fuel the light."))
		return

	active = !active
	if(active)
		to_chat(user, span_notice("You switch the UV light on."))
	else
		to_chat(user, span_notice("You switch the UV light off."))
	playsound(src, 'sound/machines/click.ogg', 30, TRUE)
	update_icon()

/// Called by farm_plot during zone tick. Returns TRUE if fueled and active.
/obj/structure/uv_light/proc/consume_fuel()
	if(!active || coal_count <= 0)
		return FALSE
	// Only burn one coal per world.time tick cycle
	if(last_fuel_tick != world.time)
		coal_count -= UV_LIGHT_COAL_PER_TICK
		last_fuel_tick = world.time
		if(coal_count <= 0)
			active = FALSE
			visible_message(span_warning("[src] sputters and shuts off — out of coal."))
			update_icon()
	return TRUE

/obj/structure/uv_light/update_icon_state()
	if(active)
		icon_state = "floodlight_on"
		color = "#aa77ff"
	else
		color = null
		icon_state = "floodlight"

#undef UV_LIGHT_COAL_PER_TICK
#undef UV_LIGHT_MAX_COAL
#undef UV_LIGHT_RANGE
#undef UV_LIGHT_GROWTH_MULT
