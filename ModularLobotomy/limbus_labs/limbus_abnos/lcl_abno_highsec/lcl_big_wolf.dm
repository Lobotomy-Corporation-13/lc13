
/mob/living/simple_animal/hostile/limbus_abno/big_wolf
	speak_emote = list("growls")

	pixel_x = -16
	base_pixel_x = -16

	maxHealth = 2500
	health = 2500
	del_on_death = FALSE
	damage_coeff = list(BRUTE = 1, RED_DAMAGE = 1, WHITE_DAMAGE = 0.7, BLACK_DAMAGE = 0.7, PALE_DAMAGE = 1)
	see_in_dark = 10
	rapid_melee = 1.5
	melee_damage_type = RED_DAMAGE
	ego_list = list(
		/datum/ego_datum/weapon/cobalt,
		/datum/ego_datum/armor/cobalt,
	)

	var/fluffy = FALSE
	var/obj/effect/proc_holder/ability/aimed/dash/big_wolf/ourdash

	//LCL unique Variables

	attack_action_types = list(
		/datum/action/cooldown/limbus_abno_action/eat_employee,
		/datum/action/cooldown/limbus_abno_action/vomit_employee,
		/datum/action/cooldown/limbus_abno_action/toggle_breached_form
		)

	original_abno = /mob/living/simple_animal/hostile/abnormality/big_wolf
	abno_additional_instructions = "You like instinct and attachment, \
	long ago your guts were spilled and now your always hungry. You can eat employees whole \
	without killing them. When you breach you will take on a form that is more suited for combat. \
	A Red Hooded Mercenary is on a eternal quest to slay you, if you are aware of this is up to you."

	hunger_active = TRUE
	insight_cooldown_time = 3 MINUTES
	//A rustic feel
	liked_objects_list = list(
		/obj/item/food/meat, /obj/structure/chair/wood,
		/obj/item/food/grown/harebell, /obj/item/stack/sheet/leather,
		)
	liked_objects_value = 5
	diet_list = list(/obj/item/organ, /obj/item/food/meat, /obj/item/bodypart)
	hunger_loss = 10
	kickstart_timer = 5 MINUTES
	hunger_bar = 100
	diet_value  = 30
	desire_on_eat = 10
	desire_on_pet = 5
	rep_desire_gain = -5
	max_counter = 2
	counter = 2

	egg_icon = 'ModularLobotomy/_Lobotomyicons/abno_cores/waw.dmi'
	egg_sprite = "big_wolf"

	can_breach = TRUE

	attunement_family = "cobalt"
	ego_list = list(/datum/ego_datum/armor/lce/cobalt)

/*-----\
|Vitals|
\-----*/
/mob/living/simple_animal/hostile/limbus_abno/big_wolf/Initialize()
	.  = ..()
	if(prob(30))
		fluffy = TRUE
		update_icon()
	attack_sound = 'sound/items/toysqueak1.ogg'

/mob/living/simple_animal/hostile/limbus_abno/big_wolf/update_icon_state()
	if(stat == DEAD)
		icon = egg_icon
		icon_state = egg_sprite
		icon_dead = egg_sprite
		pixel_x = -8
		base_pixel_x = -8
		pixel_y = 0
		base_pixel_y = 0
		return

	var/alt_stuff = fluffy ? "_alt" : ""
	if(IsContained())
		icon = 'ModularLobotomy/_Lobotomyicons/abnormality/big_wolf64x64.dmi'
		icon_state = "big_wolf[alt_stuff]"
		pixel_x = initial(pixel_x)
		base_pixel_x = initial(base_pixel_x)
		var/L = locate(/mob/living/carbon/human) in contents
		if(L)
			icon_state = "wolf_full[alt_stuff]"
	else
		icon = 'ModularLobotomy/_Lobotomyicons/96x64.dmi'
		pixel_x = -32
		base_pixel_x = -32
		icon_state = "big_wolf"
	icon_living = icon_state

/mob/living/simple_animal/hostile/limbus_abno/big_wolf/death(gibbed)
	SpewStomach()
	return ..()

/mob/living/simple_animal/hostile/limbus_abno/big_wolf/attackby(obj/item/W, mob/user)
	var/health_percent = 100 * (health / maxHealth)
	if(health_percent <= 60 && length(contents) && IsContained())
		if(W.force > 0)
			SpewStomach()
			return
	if(fluffy && istype(W, /obj/item/razor))
		fluffy = FALSE
		update_icon()
		return
	return ..()

/*--\
|Fun|
\--*/
/mob/living/simple_animal/hostile/limbus_abno/big_wolf/ShowEmotion(emotion)
	var/L = locate(/mob/living/carbon/human) in contents
	if(IsContained() && !L)
		var/alt_stuff = fluffy ? "_alt" : ""
		switch(emotion)
			if("abno_wave")
				icon_state = "wolf_wave[alt_stuff]"
			if("abno_cry")
				icon_state = "wolf_sad[alt_stuff]"
			if("abno_loom")
				flick("wolf_loom[alt_stuff]", src)
				icon_state = "wolf_looming[alt_stuff]"
		return ..()

/*----------\
|Containment|
\----------*/
/mob/living/simple_animal/hostile/limbus_abno/big_wolf/Breach()
	breached = TRUE
	unstable = TRUE
	if(!ourdash)
		ourdash = new
	AddSpell(ourdash)
	melee_damage_lower = 20
	melee_damage_upper = 40
	attack_sound = 'sound/abnormalities/big_wolf/Wolf_Scratch.ogg'
	return ..()

/mob/living/simple_animal/hostile/limbus_abno/big_wolf/Unbreach()
	breached = FALSE
	unstable = FALSE
	RemoveSpell(ourdash)
	ourdash = null
	melee_damage_lower = 0
	melee_damage_upper = 1
	SpewStomach()
	update_icon()
	attack_sound = 'sound/items/toysqueak1.ogg'
	return ..()

/mob/living/simple_animal/hostile/limbus_abno/big_wolf/InsightRoomResults(room_score, list/room_obj_list)
	if(starving && room_score > 0)
		to_chat(src,span_notice("Your too hungry to care about your surroundings."))
		return
	return ..()

/mob/living/simple_animal/hostile/limbus_abno/big_wolf/AdjustHunger(feeding_amount)
	. = ..()
	if(hunger_bar <= 10)
		AdjustDesire(-5)
	if(hunger_bar >= 100 && length(contents))
		SpewStomach()

/mob/living/simple_animal/hostile/limbus_abno/big_wolf/AdjustDesire(desire_amount)
	var/mod_desire = desire_amount
	if(starving)
		mod_desire -= 10
	. = ..(mod_desire)
	if(desire_bar == 0 && 1 > desire_amount)
		AdjustCounter(-1)

/*-----\
|Eating|
\-----*/

/mob/living/simple_animal/hostile/limbus_abno/big_wolf/AbnoEat(atom/food)
	if(istype(food, /obj/item/bodypart/head))
		to_chat(src, span_warning("The electronic chip in this bodypart will upset your stomach."))
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/limbus_abno/big_wolf/proc/EatWorker(mob/living/L)
	if(!L || !isliving(L))
		return FALSE
	playsound(get_turf(src), 'sound/effects/ordeals/crimson/noon_bite.ogg', 75, 1)
	ADD_TRAIT(L, TRAIT_NOBREATH, type)
	ADD_TRAIT(L, TRAIT_INCAPACITATED, type)
	ADD_TRAIT(L, TRAIT_IMMOBILIZED, type)
	ADD_TRAIT(L, TRAIT_HANDS_BLOCKED, type)
	L.adjustBruteLoss(-maxHealth * 0.2)
	// if(!L.client)
	// 	dropHardClothing(L, get_turf(L))
	// 	qdel(L)
	// else
	// 	L.forceMove(src)
	L.forceMove(src)
	AdjustHunger(20)
	update_icon()
	return TRUE

/mob/living/simple_animal/hostile/limbus_abno/big_wolf/proc/SpewStomach()
	var/spew_turf = pick(get_adjacent_open_turfs(src))
	playsound(get_turf(src), 'sound/abnormalities/big_wolf/Wolf_EatOut.ogg', 75, 1)
	for(var/mob/living/i in contents)
		if(isliving(i))
			var/mob/living/L = i
			L.Knockdown(10, FALSE)
			REMOVE_TRAIT(L, TRAIT_NOBREATH, type)
			REMOVE_TRAIT(L, TRAIT_INCAPACITATED, type)
			REMOVE_TRAIT(L, TRAIT_IMMOBILIZED, type)
			REMOVE_TRAIT(L, TRAIT_HANDS_BLOCKED, type)
			if(hunger_bar > 40)
				AdjustHunger(-25)
		i.forceMove(spew_turf)

	if(IsContained())
		fluffy = TRUE
		sleep(1 SECONDS)
		ShowEmotion("abno_cry")
		sleep(3 SECONDS)
		update_icon_state()

/*------------------\
|ABNO LIMBUS ACTIONS|
\------------------*/
/datum/action/cooldown/limbus_abno_action/eat_employee
	name = "Eat Carbon."
	desc = "Eat a nearby carbon."
	icon_icon = 'icons/hud/screen_gen.dmi'
	button_icon_state = "mood_happiness_bad"
	transparent_when_unavailable = TRUE
	hunger_req = 25
	cooldown_time = 10 SECONDS

/datum/action/cooldown/limbus_abno_action/eat_employee/IsAvailable()
	. = ..()
	if(!.)
		return .
	if(isnull(abno_user))
		return FALSE
	if(!abno_user.IsContained() || abno_user.stat == DEAD)
		return FALSE

/datum/action/cooldown/limbus_abno_action/eat_employee/Trigger()
	. = ..()
	if(!.)
		return .
	var/mob/living/simple_animal/hostile/limbus_abno/big_wolf/B = abno_user
	var/mob/living/carbon/human/H = locate(/mob/living/carbon/human) in view(1, get_turf(B))
	if(!H)
		return
	B.EatWorker(H)
	StartCooldown()

/datum/action/cooldown/limbus_abno_action/vomit_employee
	name = "Vomit Employee."
	desc = "Your gut cant handle a meal like this."
	icon_icon = 'icons/hud/screen_gen.dmi'
	button_icon_state = "mood_happiness_bad"
	transparent_when_unavailable = TRUE
	cooldown_time = 5 SECONDS

/datum/action/cooldown/limbus_abno_action/vomit_employee/IsAvailable()
	var/L = locate(/mob/living/carbon/human) in abno_user.contents
	. = ..()
	if(!.)
		return .
	if(isnull(abno_user))
		return FALSE
	if(!abno_user.IsContained())
		return FALSE
	if(length(abno_user.contents) < 1 || length(abno_user.contents) >= 3)
		return FALSE
	if(!L)
		return FALSE

/datum/action/cooldown/limbus_abno_action/vomit_employee/Trigger()
	. = ..()
	if(!.)
		return .
	var/mob/living/simple_animal/hostile/limbus_abno/big_wolf/B = abno_user
	StartCooldown()
	B.SpewStomach()

