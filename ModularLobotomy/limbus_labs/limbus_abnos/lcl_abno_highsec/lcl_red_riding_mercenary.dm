/mob/living/simple_animal/hostile/limbus_abno/red_hood
	maxHealth = 2400 // More health than standard
	health = 2400 // Since she was apparently too easy to suppress
	rapid_melee = 2
	speed = 0.5

	melee_damage_lower = 10
	melee_damage_upper = 20

	damage_coeff = list(RED_DAMAGE = 0.6, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 1.5) // Fuck you, blue shepherd.
	ranged = TRUE

	damage_coeff = list(RED_DAMAGE = 0.6, WHITE_DAMAGE = 1.2, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 1.5) // Fuck you, blue shepherd.
	melee_damage_type = RED_DAMAGE

	density = FALSE // Prevents red from getting stuck unable to reach her target
	status_flags = MUST_HIT_PROJECTILE // Allows projectiles to hit even though she's not dense.
	ego_list = list(
		/datum/ego_datum/weapon/crimson,
		/datum/ego_datum/weapon/crimson/gun,
		/datum/ego_datum/armor/crimson
		)

	var/gun_timer = 0
	var/gun_cooldown = 5 SECONDS
	var/gun_cost = 30

	var/throw_timer = 0
	var/throw_cooldown = 11 SECONDS
	var/throw_cost = 10

	var/reaction_chance = 100

	var/obj/effect/proc_holder/ability/aimed/hollowpoint/hollowpoint_round
	var/obj/effect/proc_holder/ability/aimed/red_blade/blade_throw

	//LCL unique Variables
	original_abno = /mob/living/simple_animal/hostile/abnormality/red_hood
	abno_additional_instructions = "You like insight and higher level instinct, \
	You are a supernatural mercenary for hire. Your jobs tend to be hunting \
	your fellow abnormalities with little care for whoever gets in the way. \
	You hold a burning hatred for the Big Bad Wolf. \
	Your monies are used for attacks, -30 for hollowpoint & -10 for throwing \
	knife. You can gain more monies if researchers use ahn on you. Its good business."

	//Was going to make her eat money but i dont know if money exists in LCL
	liked_objects_list = list(
		/obj/structure/chair/wood,
		/obj/item/food/grown/harebell, /obj/item/stack/sheet/leather,
		)
	desire_active = TRUE
	max_counter = 3
	kickstart_timer = 5 MINUTES
	desire_on_talk = 1
	desire_on_pet = 5
	rep_desire_gain = -5

	can_breach = TRUE

	egg_icon = 'ModularLobotomy/_Lobotomyicons/abno_cores/waw.dmi'
	egg_sprite = "little_red"

	attack_action_types = list(
		/datum/action/cooldown/limbus_abno_action/swap_attack/hollowpoint,
		/datum/action/cooldown/limbus_abno_action/swap_attack/knifethrow
		)

	attunement_family = "crimson"
	ego_list = list(/datum/ego_datum/armor/lce/crimson)

	var/monies = 100
	//Determines what sprite she has
	var/mode = 1

/*-----\
|Vitals|
\-----*/
/mob/living/simple_animal/hostile/limbus_abno/red_hood/Initialize(mapload)
	. = ..()
	hollowpoint_round = new
	blade_throw = new

/mob/living/simple_animal/hostile/limbus_abno/red_hood/Destroy()
	if(hollowpoint_round)
		QDEL_NULL(hollowpoint_round)
	if(blade_throw)
		QDEL_NULL(blade_throw)
	return ..()

/*
* When a offical money system is in im going
* to tie monies in with hollowpoint round charges
*/
/mob/living/simple_animal/hostile/limbus_abno/red_hood/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/holochip) && user)
		var/obj/item/holochip/H = W
		var/new_monies = H.credits
		if(new_monies > 0)
			visible_message("[src] snatches the [new_monies] ahn from [user].",
				span_notice("You grab and pocket the [new_monies] ahn."))
			AdjustMonies(new_monies)
			qdel(H)
			return
	return ..()

/mob/living/simple_animal/hostile/limbus_abno/red_hood/update_icon_state()
	if(stat == DEAD)
		icon = egg_icon
		icon_state = egg_sprite
		icon_dead = egg_sprite
		pixel_x = -8
		base_pixel_x = -8
		pixel_y = 0
		base_pixel_y = 0
		return

	switch(mode)
		if(2)
			icon = 'ModularLobotomy/_Lobotomyicons/96x64.dmi'
			icon_state = "redhood_shoot"
			icon_living = "redhood_shoot"
			pixel_x = -32
			base_pixel_x = -32
		else
			icon = 'ModularLobotomy/_Lobotomyicons/48x64.dmi'
			icon_state = "red_hood"
			icon_living = "red_hood"
			pixel_x = -8
			base_pixel_x = -8
	icon_living = icon_state

/*----------\
|Containment|
\----------*/
/mob/living/simple_animal/hostile/limbus_abno/red_hood/Hear(message, atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, list/message_mods)
	. = ..()
	if(istype(speaker, /mob/living/simple_animal/hostile/limbus_abno/big_wolf) && IsContained() && desire_bar > 20)
		if(prob(reaction_chance))
			to_chat(src, span_userdanger("As you hear that growling voice your bindings become weaker."))
			reaction_chance = max(10, reaction_chance / 2)
			//You know that voice
			AdjustDesire(-15)

/mob/living/simple_animal/hostile/limbus_abno/red_hood/Breach()
	breached = TRUE
	unstable = TRUE
	melee_damage_lower = 30
	melee_damage_upper = 45
	return ..()

/mob/living/simple_animal/hostile/limbus_abno/red_hood/Unbreach()
	breached = FALSE
	unstable = FALSE
	melee_damage_lower = 10
	melee_damage_upper = 20
	return ..()

/mob/living/simple_animal/hostile/limbus_abno/red_hood/AdjustHunger(feeding_amount)
	. = ..()
	if(hunger_bar <= 10)
		AdjustDesire(-5)

/mob/living/simple_animal/hostile/limbus_abno/red_hood/AdjustDesire(desire_amount)
	. = ..()
	if(desire_bar <= 10 && 1 > desire_amount)
		AdjustCounter(-1)

/*-----\
|Combat|
\-----*/
/mob/living/simple_animal/hostile/limbus_abno/red_hood/OpenFire()
	if(!can_act) //Openfire doesn't actually check for this normally
		return FALSE
	if(client)
		switch(chosen_attack)
			if(1, 2)
				return FALSE // this should never be the case, 1 isn't an attack, but for safety...
			if(3)
				if(monies >= gun_cost)
					Hollowpoint(target)
					return TRUE
			if(4)
				if(monies >= throw_cost)
					BladeThrow(target)
					return TRUE
		chosen_attack = 1

/mob/living/simple_animal/hostile/limbus_abno/red_hood/proc/BladeThrow(atom/target) // Throw a barrage of piercing blades in the direction of the enemy.
	if(throw_timer > world.time)
		if(client)
			to_chat(src, span_danger("You can't do that now!"))
		return FALSE
	throw_timer = world.time + throw_cooldown
	manual_emote("pulls out several knives from her coat.")
	blade_throw.Perform(target, src)
	AdjustMonies(-throw_cost)

/mob/living/simple_animal/hostile/limbus_abno/red_hood/proc/Hollowpoint(atom/target) // Fire a round in the direction of the enemy. When enraged, shoot multiple times.
	if(world.time < gun_timer)
		if(client)
			to_chat(src, span_danger("You can't do that now!"))
		return FALSE
	gun_timer = world.time + gun_cooldown
	manual_emote("raises her gun.")
	mode = 2
	update_icon()
	hollowpoint_round.Perform(target, src)
	mode = 1
	update_icon()
	AdjustMonies(-gun_cost)

/*---\
|Misc|
\---*/
/mob/living/simple_animal/hostile/limbus_abno/red_hood/SelfStatusReadout()
	. = ..()
	. += "Monies: [monies]"

/mob/living/simple_animal/hostile/limbus_abno/red_hood/proc/AdjustMonies(new_monies)
	monies = max(0, monies + new_monies)
	if(new_monies >= 0)
		AdjustDesire(clamp(new_monies,1,20))

/mob/living/simple_animal/hostile/limbus_abno/red_hood/proc/SpecialReset()
	icon = 'ModularLobotomy/_Lobotomyicons/48x64.dmi'
	icon_state = "red_hood"
	icon_living = icon_state
	pixel_x = -8
	base_pixel_x = -8

/*-----\
|Action|
\-----*/
/datum/action/cooldown/limbus_abno_action/swap_attack/hollowpoint
	name = "Hollowpoint Round"
	desc = "Fire a spray of bullets at the next creature you click on."
	cooldown_time = 3 SECONDS
	swap_attack = 3

/datum/action/cooldown/limbus_abno_action/swap_attack/knifethrow
	name = "Blade Throw"
	desc = "You will now fire at whatever you next click on."
	cooldown_time = 10 SECONDS
	swap_attack = 4
