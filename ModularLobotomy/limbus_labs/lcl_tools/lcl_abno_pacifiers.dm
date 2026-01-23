#define FEED "feed"
#define DESIRE "desire"
#define COUNTER "counter"

/obj/item/lcl_pacifiers
	name = "Abnormality Pacifier."
	desc = "After reverse engineering some of the Qlipthoth Detterence technology,\
	Limbus Company was able to create tools capable of instantly satisfying the specific needs of an abnormality, but it has limited uses. Use inhand to change modes."
	///codersprites, should probably get changed by an actual spriter.
	icon = 'ModularLobotomy/_Lobotomyicons/lcl_tools.dmi'
	icon_state = "lcl_pacifier"
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lcorp_left.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lcorp_right.dmi'
	force = 0
	hitsound = 'sound/weapons/ego/justitia2.ogg'
	var/uses = 3
	var/mode_num = 1
	var/mode = DESIRE

/obj/item/lcl_pacifiers/attack_self(mob/user)
	. = ..()
	playsound(src, 'sound/effects/pop.ogg', 100, TRUE, -6)
	mode_num++
	switch(mode_num)
		if(1)
			mode = DESIRE
		if(2)
			mode = FEED
		if(3)
			mode = COUNTER
		else
			mode_num = 1
			mode = DESIRE

	to_chat(user, span_notice("Swapped to [mode] mode!"))

/obj/item/lcl_pacifiers/afterattack(atom/A, mob/living/user, proximity_flag, params)
	var/mob/living/simple_animal/hostile/limbus_abno/LA = A
	if(!istype(LA))
		return ..()
	if(uses < 1)
		to_chat(user, span_warning("It's out of charges!"))
		return
	if(LA.unstable)
		to_chat(user, span_warning("The abnormality is too unstable to be affected by [src]!"))
		return
	if(mode == DESIRE)
		LA.AdjustDesire(LA.max_desire)
		to_chat(user, span_green("The abnormality looks satisfied!"))
	if(mode == FEED)
		LA.AdjustHunger(LA.max_hunger)
		to_chat(user, span_green("The abnormality looks well fed!"))
	if(mode == COUNTER)
		LA.AdjustCounter(LA.max_counter)
		to_chat(user, span_green("The abnormality looks like it calmed down!"))
	uses--

/obj/item/lcl_pacifiers/examine(mob/user)
	. = ..()
	. += "Current mode: [mode]."
	if(uses > 0)
		. += "It has [uses] more uses."
	else
		. += "Its out of charges!"

#undef FEED
#undef DESIRE
#undef COUNTER
