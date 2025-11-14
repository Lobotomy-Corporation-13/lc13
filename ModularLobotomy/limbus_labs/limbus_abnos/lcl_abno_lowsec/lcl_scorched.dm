/mob/living/simple_animal/hostile/limbus_abno/scorched_girl
	true_name = "Scorched Girl"
	maxHealth = 400
	health = 400
	damage_coeff = list(RED_DAMAGE = 0.5, WHITE_DAMAGE = 2, BLACK_DAMAGE = 1, PALE_DAMAGE = 2)
	max_counter = 2
	original_abno = /mob/living/simple_animal/hostile/abnormality/scorched_girl
	attack_action_types = list(/datum/action/cooldown/limbus_abno_action/scorched_boom, /datum/action/cooldown/limbus_abno_action/scorched_burn)
	diet_list = list(/obj/item/lighter, /obj/item/match, /obj/item/food/badrecipe, /obj/item/food/bearsteak, /obj/item/food/burger/fivealarm)
	abno_additional_instructions = "You like being hurt, and feeding the flame that hurts you, which means your mood will improve on eating and being beat up. You like bonfires, you relate to them. \
	If you starve for too long, you will suddenly explode, leaving you with only a sliver of your health."
	hunger_cooldown_time =  1 MINUTES
	hunger_bar = 50
	diet_value = 40 //Easy to feed.
	desire_on_eat = 30
	desire_on_eat_threshold = 50
	desire_on_pet = -20
	rep_desire_gain = 0.2
	rep_desire_loss_at_threshold = 100
	rep_threshold = 50
	rep_min_damage = 1
	insight_cooldown_time = 2 MINUTES
	liked_objects_list = list(/obj/structure/bonfire)
	liked_objects_value = 3
	ego_list = list(
		/datum/ego_datum/weapon/match,
		/datum/ego_datum/armor/match,
	)
	breach_overlay_z = 30
	breach_overlay_x = 3
	var/blowing_up = FALSE //To avoid her chaining multiple explosions at the same time.

/mob/living/simple_animal/hostile/limbus_abno/scorched_girl/AdjustHunger()
	..()
	if(starving)
		AdjustDesire(-10)

//Scorched girl dislikes attachment work.
/mob/living/simple_animal/hostile/limbus_abno/scorched_girl/funpet(mob/living/carbon/human/petter)
	BurnArea(TRUE)
	playsound(src, 'sound/items/welder.ogg', 100, TRUE)

/mob/living/simple_animal/hostile/limbus_abno/scorched_girl/AdjustDesire(desire_amount, pos_desire)
	..()
	if(desire_bar < 50 && !pos_desire)
		AdjustCounter(-1)
	else if(desire_bar > 50 && pos_desire)
		AdjustCounter(1)

/mob/living/simple_animal/hostile/limbus_abno/scorched_girl/AdjustCounter(counter_amount)
	..()
	if((counter <= 0) && (desire_bar <= 0))
		ScorchedExplosion(TRUE) //Entirely ignores the cooldown.

/datum/action/cooldown/limbus_abno_action/scorched_burn
	name = "Burn it all"
	desc = "Burn everything in a 2x2 area around you. Improves your mood the more people you hit."
	icon_icon = 'icons/effects/effects.dmi'
	button_icon_state = "visual_fire"
	transparent_when_unavailable = TRUE
	cooldown_time = 30 SECONDS

/datum/action/cooldown/limbus_abno_action/scorched_burn/Trigger()
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/simple_animal/hostile/limbus_abno/scorched_girl/scorched = abno_user
	scorched.BurnArea(FALSE)
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/scorched_boom
	name = "Blow up"
	icon_icon = 'icons/effects/effects.dmi'
	button_icon_state = "blackhole"
	transparent_when_unavailable = TRUE
	cooldown_time = 3 MINUTES
	counter_req = 1

/datum/action/cooldown/limbus_abno_action/scorched_boom/Trigger()
	var/mob/living/simple_animal/hostile/limbus_abno/scorched_girl/scorched = abno_user
	if(scorched.counter > 1)
		to_chat(abno_user, span_warning("Things aren't bad enough for you to blow up."))
		return FALSE
	. = ..()
	if(!.)
		return FALSE
	if(scorched.ScorchedExplosion())
		StartCooldown()

//This explosion isn't lethal to scorched like the original, and generally weaker damage wise, but destroys the environment much more.
//If forced, ignores the do_after and friend check entirely.
/mob/living/simple_animal/hostile/limbus_abno/scorched_girl/proc/ScorchedExplosion(forced = FALSE)
	if(blowing_up)
		return FALSE
	blowing_up = TRUE
	unstable = TRUE
	playsound(get_turf(src), 'sound/abnormalities/scorchedgirl/pre_ability.ogg', 50, 0, 2)
	if(!forced)
		if(!do_after(src, 1.5 SECONDS, target = src))
			return FALSE
	else
		to_chat(src, "<span class='userdanger'>The heat becomes too much to bear!</span>")
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "scorched"
	AddBreachEffect()
	SLEEP_CHECK_DEATH(1.5 SECONDS)
	playsound(get_turf(src), 'sound/abnormalities/scorchedgirl/ability.ogg', 60, 0, 4)
	SLEEP_CHECK_DEATH(3 SECONDS)
	// Ka-boom
	playsound(get_turf(src), 'sound/abnormalities/scorchedgirl/explosion.ogg', 125, 0, 8)
	for(var/mob/living/L in view(7, src))
		if(L == src)
			continue
		if(!IsFriend(L) && !forced)
			continue
		L.deal_damage(150, RED_DAMAGE)
		L.deal_damage(150 * 0.5, FIRE)
		if(L.health < 0)
			L.gib()
	for(var/obj/structure/obstacle in view(5, src))
		obstacle.take_damage(150, RED_DAMAGE)
	new /obj/effect/temp_visual/explosion(get_turf(src))
	var/datum/effect_system/smoke_spread/S = new
	S.set_up(7, get_turf(src))
	S.start()
	adjustHealth(health - 30) //Barely survives with 30HP, but will die to anything that grazes them.
	AdjustCounter(max_counter)
	AdjustDesire(max_desire)
	AdjustHunger(max_hunger)
	blowing_up = FALSE
	icon = 'ModularLobotomy/_Lobotomyicons/tegumobs.dmi'
	icon_state = "scorched"
	unstable = FALSE
	RemoveBreachEffect()
	return TRUE

/mob/living/simple_animal/hostile/limbus_abno/scorched_girl/proc/BurnArea(forced = FALSE)
	for(var/turf/open/T in range(2, src))
		new /obj/effect/temp_visual/fire/fast(T)
		for(var/mob/living/carbon/human/H in T)
			if(IsFriend() && !forced)
				continue
			if(!forced)
				AdjustDesire(20)

			H.adjustRedLoss(20)
			H.adjust_fire_stacks(10)
			H.IgniteMob()

	playsound(src, 'sound/items/welder.ogg', 100, TRUE)
