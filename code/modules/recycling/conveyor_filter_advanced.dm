/obj/machinery/conveyor/filter_advanced
	icon = 'icons/obj/recycling.dmi'
	icon_state = "filter_generic_off" // todo: sprite or something ah
	name = "advanced conveyor filter"
	desc = "A filter that checks for specific items."
	var/filter_object_name = "Nothing"
	var/filter_typepath = null
	var/filter_icon_path = null
	var/filter_icon_state = null
	var/filter_output_dir = SOUTH
	var/unfiltered_output_dir = EAST

/obj/machinery/conveyor/filter_advanced/Initialize()
	update_desc()
	. = ..()
	
/obj/machinery/conveyor/filter_advanced/update_icon_state()
	cut_overlays()
	add_overlay(icon('icons/obj/conveyor_filters.dmi', "filter_[filter_output_dir]"))
	add_overlay(icon('icons/obj/conveyor_filters.dmi', "unfiltered_[unfiltered_output_dir]"))
	if(filter_typepath)
		var/image/I = image(icon(filter_icon_path, filter_icon_state))
		I.transform *= 0.5
		add_overlay(I)


/obj/machinery/conveyor/filter_advanced/proc/update_desc()
	desc = "A filter that checks for specific objects and redirects them in another direction.\nMatches get sent [dir2text(filter_output_dir)], everything else goes [dir2text(unfiltered_output_dir)].\nA screwdriver changes the output direction of filtered items, while a wrench changes the output direction of everything else."
	if(!filter_typepath)
		desc += "\nIt currently has no set filter! The first object to move onto it will be filtered."
	else:
		desc += "\nIt is set to filter out [filter_object_name]. The filter can be cleared with an empty hand."

/obj/machinery/conveyor/filter_advanced/proc/get_it_twisted(var/angle)
	switch(angle)
		if(NORTH)
			return EAST
		if(EAST)
			return SOUTH
		if(SOUTH)
			return WEST
	return NORTH

/obj/machinery/conveyor/filter_advanced/convey(list/affecting)
	for(var/am in affecting)
		if(!ismovable(am))
			continue
		var/atom/movable/movable_thing = am
		stoplag()
		if(QDELETED(movable_thing) || (movable_thing.loc != loc))
			continue
		if(iseffect(movable_thing) || isdead(movable_thing))
			continue
		if(isliving(movable_thing))
			var/mob/living/zoommob = movable_thing
			if((zoommob.movement_type & FLYING) && !zoommob.stat)
				continue
		if(!movable_thing.anchored && movable_thing.has_gravity())
			if(!filter_typepath) // Set the filter to the first object that moves over it
				if(istype(movable_thing, /mob/living/carbon/human)) // Otherwise it'll use the name of the person who walks over it
					filter_object_name = "people"
					filter_icon_state = "human_basic"
				else
					filter_object_name = movable_thing.name
					filter_icon_state = movable_thing.icon_state
				filter_typepath = movable_thing.type
				filter_icon_path = movable_thing.icon
				update_desc()
				update_icon_state()
				playsound(src, 'sound/machines/ping.ogg', 50)
			if(movable_thing.type == filter_typepath)
				step(movable_thing, filter_output_dir)
			else
				step(movable_thing, unfiltered_output_dir)
	conveying = FALSE

/obj/machinery/conveyor/filter_advanced/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_CROWBAR)
		user.visible_message("<span class='notice'>[user] struggles to pry up \the [src] with \the [I].</span>", \
		"<span class='notice'>You struggle to pry up \the [src] with \the [I].</span>")
		if(I.use_tool(src, user, 40, volume=40))
			if(!(machine_stat & BROKEN))
				var/obj/item/stack/conveyor_filter_advanced/C = new /obj/item/stack/conveyor_filter_advanced(loc, 1, TRUE, null, null, id)
				transfer_fingerprints_to(C)
			to_chat(user, "<span class='notice'>You remove the conveyor belt.</span>")
			qdel(src)

	else if(I.tool_behaviour == TOOL_WRENCH) // rotate the output direction if the item does not match
		if(!(machine_stat & BROKEN))
			I.play_tool_sound(src)
			//Rotate code here lol
			unfiltered_output_dir = get_it_twisted(unfiltered_output_dir)
			update_icon_state()
			to_chat(user, "<span class='notice'>You alter the filter so unfiltered items are sent [dir2text(unfiltered_output_dir)].</span>")

	else if(I.tool_behaviour == TOOL_SCREWDRIVER) // rotate the output direction if the item does match
		if(!(machine_stat & BROKEN))
			I.play_tool_sound(src)
			//Direction reverse code here lol
			filter_output_dir = get_it_twisted(filter_output_dir)
			update_icon_state()
			to_chat(user, "<span class='notice'>You alter the filter so filtered items are sent [dir2text(filter_output_dir)].</span>")

/obj/machinery/conveyor/filter_advanced/attack_hand(mob/user) // reset the filtered object
	filter_typepath = null
	filter_object_name = "Nothing"
	update_desc()
	update_icon_state()
	to_chat(user, "<span class='notice'>You clear the filtered item. The next item to pass into the filter will be filtered.</span>")
	. = ..()

/obj/item/stack/conveyor_filter_advanced
	name = "advanced conveyor filter assembly"
	desc = "An advanced conveyor filter assembly."
	icon = 'icons/obj/recycling.dmi'
	icon_state = "filter_construct"
	max_amount = 30
	singular_name = "conveyor filter"
	w_class = WEIGHT_CLASS_BULKY
	merge_type = /obj/item/stack/conveyor_filter_advanced
	var/id = ""

/obj/item/stack/conveyor_filter_advanced/afterattack(atom/A, mob/user, proximity)
	. = ..()
	if(!proximity || user.stat || !isfloorturf(A) || istype(A, /area/shuttle))
		return
	var/cdir = get_dir(A, user)
	if(A == user.loc)
		to_chat(user, "<span class='warning'>You cannot place an advanced conveyor filter under yourself!</span>")
		return
	var/obj/machinery/conveyor/filter_advanced/C = new(A, cdir, id)
	transfer_fingerprints_to(C)
	use(1)

/obj/item/stack/conveyor_filter_advanced/attackby(obj/item/I, mob/user, params)
	..()
	if(istype(I, /obj/item/conveyor_switch_construct))
		to_chat(user, "<span class='notice'>You link the switch to the advanced conveyor filter assembly.</span>")
		var/obj/item/conveyor_switch_construct/C = I
		id = C.id

