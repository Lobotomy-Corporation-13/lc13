#define STATUS_EFFECT_COLD_EXPOSURE /datum/status_effect/stacking/cold_exposure

/datum/weather/city_freezing_storm
	name = "freezing storm"
	desc = "A bitter cold storm sweeps through the city streets."
	immunity_type = "freezing"

	telegraph_message = span_warning("The temperature is dropping rapidly. A freezing storm is approaching!")
	telegraph_duration = 30 SECONDS
	telegraph_overlay = "snowfall_calm"
	// telegraph_sound = 'sound/weather/wind/wind_2_1.ogg'

	weather_message = span_userdanger("<i>The freezing storm has arrived! Seek shelter!</i>")
	weather_overlay = "snowfall_blizzard"
	perpetual = TRUE //should make it last forever
	// weather_sound = 'sound/weather/wind/wind_2_2.ogg'

	end_message = span_boldannounce("The freezing storm begins to subside.")
	end_overlay = "snowfall_calm"
	end_duration = 10 SECONDS
	// end_sound = 'sound/weather/wind/wind_2_1.ogg'

	area_type = /area
	protect_indoors = TRUE
	target_trait = ZTRAIT_STATION

/datum/weather/city_freezing_storm/weather_act(mob/living/L)
	if(!ishuman(L))
		return

	var/mob/living/carbon/human/H = L

	// Check for cold protection from worn clothing
	var/has_cold_protection = FALSE

	// Check outer clothing (suits, coats, armor)
	var/obj/item/clothing/suit/worn_suit = H.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(worn_suit && worn_suit.cold_protection)
		has_cold_protection = TRUE

	// If wearing cold protection, don't apply the effect
	if(has_cold_protection)
		return

	var/datum/status_effect/stacking/cold_exposure/cold = H.has_status_effect(STATUS_EFFECT_COLD_EXPOSURE)

	if(!cold)
		H.apply_status_effect(STATUS_EFFECT_COLD_EXPOSURE)
	else
		cold.add_stacks(1)

/datum/status_effect/stacking/cold_exposure
	id = "cold_exposure"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	tick_interval = 20 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/cold_exposure
	stacks = 1
	max_stacks = 10
	consumed_on_threshold = FALSE
	on_remove_on_mob_delete = TRUE
	stack_decay = 1
	stack_threshold = -1

/atom/movable/screen/alert/status_effect/cold_exposure
	name = "Cold Exposure"
	desc = "You're freezing! The cold is slowing you down."
	icon = 'ModularLobotomy/_Lobotomyicons/status_sprites.dmi'
	icon_state = "freezing"

/datum/status_effect/stacking/cold_exposure/on_apply()
	. = ..()
	to_chat(owner, span_warning("The freezing wind chills you to the bone!"))
	UpdateSlowdown()

/datum/status_effect/stacking/cold_exposure/on_remove()
	to_chat(owner, span_nicegreen("You feel warm again."))
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/cold_exposure)
	. = ..()

/datum/status_effect/stacking/cold_exposure/add_stacks(stacks_added)
	. = ..()
	if(!stacks_added)
		return

	UpdateSlowdown()

	// Damage at high stacks
	if(stacks >= 8)
		owner.apply_damage(10, BRUTE, null, owner.run_armor_check(null, PALE_DAMAGE), spread_damage = TRUE)
		to_chat(owner, span_userdanger("The extreme cold is damaging your body!"))
		owner.playsound_local(owner, 'sound/effects/glassbr1.ogg', 50, TRUE)
	else if(stacks == 7)
		to_chat(owner, span_danger("You're reaching dangerous levels of cold exposure!"))
	else if(stacks == 5)
		to_chat(owner, span_warning("The cold is becoming unbearable!"))
	else if(stacks == 3)
		to_chat(owner, span_warning("You're getting very cold!"))

/datum/status_effect/stacking/cold_exposure/tick()
	// Passive stack reduction
	if(stacks > 0)
		add_stacks(-stack_decay)
		if(stacks <= 0)
			qdel(src)
			return
		UpdateSlowdown()

/datum/status_effect/stacking/cold_exposure/proc/UpdateSlowdown()
	if(!owner)
		return

	// Slowdown scales with stacks
	var/slowdown_amount = stacks * 0.3
	owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/cold_exposure, multiplicative_slowdown = slowdown_amount)

/datum/movespeed_modifier/cold_exposure
	variable = TRUE
	multiplicative_slowdown = 0

#undef STATUS_EFFECT_COLD_EXPOSURE
