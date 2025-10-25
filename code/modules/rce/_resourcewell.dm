GLOBAL_VAR_INIT(rcorp_factorymax, 70)

/obj/structure/resourcepoint
	name = "green resource point"
	desc = "A machine that when hit with a wrench, spits out green resources."
	icon = 'ModularLobotomy/_Lobotomyicons/factory.dmi'
	icon_state = "resource_green"
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE
	var/production_time = 600
	var/obj/item = /obj/item/factoryitem/green	//What item you spawn
	var/active = 0	//What level you have
	var/id = "green"	//ID for matching with raid landmarks
	var/rarity = 1	//Rarity value for raid calculations

/obj/structure/resourcepoint/Initialize()
	. = ..()
	SSgamedirector.RegisterResourceWell(src)

/obj/structure/resourcepoint/Destroy()
	SSgamedirector.UnregisterResourceWell(src)
	return ..()

/obj/structure/resourcepoint/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	if(active > 0)
		return
	if(I.tool_behaviour != TOOL_WRENCH)
		return
	playsound(src, 'sound/items/ratchet.ogg', 50, TRUE)
	if(!do_after(user, 7 SECONDS, src))
		return
	active = 1
	SSgamedirector.UpdateActiveStatus(src)
	to_chat(user, "<span class='notice'>You activate the resource point.</span>")
	addtimer(CALLBACK(src, PROC_REF(spit_item)), production_time/active)

/obj/structure/resourcepoint/proc/spit_item()
	if(!active)
		return
	if(prob(20) && active<=10)	//To do: make this less random.
		active+=1

	var/halt_active = FALSE
	for(var/mob/living/simple_animal/hostile/M in range(3, get_turf(src)))
		if(M.stat == DEAD)
			continue
		if(!("neutral" in M.faction))
			continue
		halt_active = TRUE
		break

	if(halt_active)
		active = 0
		SSgamedirector.UpdateActiveStatus(src)
		show_global_blurb(5 SECONDS, "A resource point has stopped production", text_align = "center", screen_location = "LEFT+0,TOP-2")
		return

	addtimer(CALLBACK(src, PROC_REF(spit_item)), production_time/active)
	new item(src.loc)

/obj/structure/resourcepoint/red
	name = "red resource point"
	desc = "A machine that when used, spits out red resources."
	icon_state = "resource_red"
	item = /obj/item/factoryitem/red	//What item you spawn
	id = "red"
	rarity = 1

/obj/structure/resourcepoint/blue
	name = "blue resource point"
	desc = "A machine that when used, spits out blue resources."
	icon_state = "resource_blue"
	item = /obj/item/factoryitem/blue	//What item you spawn
	id = "blue"
	rarity = 2

/obj/structure/resourcepoint/purple
	name = "purple resource point"
	desc = "A machine that when used, spits out purple resources."
	icon_state = "resource_purple"
	item = /obj/item/factoryitem/purple	//What item you spawn
	id = "purple"
	rarity = 2

/obj/structure/resourcepoint/orange
	name = "orange resource point"
	desc = "A machine that when used, spits out orange resources."
	icon_state = "resource_orange"
	item = /obj/item/factoryitem/orange	//What item you spawn
	id = "orange"
	rarity = 4

/obj/structure/resourcepoint/silver
	name = "silver resource point"
	desc = "A machine that when used, spits out silver resources."
	icon_state = "resource_silver"
	item = /obj/item/factoryitem/silver	//What item you spawn
	id = "silver"
	rarity = 4
