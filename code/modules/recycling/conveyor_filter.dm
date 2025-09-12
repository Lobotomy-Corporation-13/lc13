/obj/machinery/conveyor/filter
	icon = 'icons/obj/recycling.dmi'
	icon_state = "filter0"
	name = "conveyor filter"
	desc = "A filter that checks for specific items."
	var/datum/filter_setting/selected_filter = null
	var/filter_object_name = "Nothing"
	var/filter_output_dir = SOUTH
	var/unfiltered_output_dir = EAST

/obj/machinery/conveyor/filter/Initialize()
	update_desc()
	. = ..()
	
/obj/machinery/conveyor/filter/update_icon_state()
	icon_state = "filter[abs(operating)]" 
	cut_overlays()
	add_overlay(icon('icons/obj/recycling.dmi', "filtered_[filter_output_dir]"))
	add_overlay(icon('icons/obj/recycling.dmi', "unfiltered_[unfiltered_output_dir]"))
	if(selected_filter && selected_filter.filter_typepath.len > 0)
		var/image/I
		switch(selected_filter.filter_typepath.len)
			if(1)
				I = image(selected_filter.get_icon(1))
				I.transform = matrix(selected_filter.overlay_scale, MATRIX_SCALE)
				add_overlay(I)
			if(2)
				I = image(selected_filter.get_icon(1))
				I.transform = matrix(selected_filter.overlay_scale, MATRIX_SCALE) * matrix(-2,0, MATRIX_TRANSLATE)
				add_overlay(I - 5)
				I = image(selected_filter.get_icon(2))
				I.transform = matrix(selected_filter.overlay_scale, MATRIX_SCALE) * matrix(2,0, MATRIX_TRANSLATE)
				add_overlay(I + 5)
			if(3)
				I = image(selected_filter.get_icon(1))
				I.transform = matrix(selected_filter.overlay_scale, MATRIX_SCALE) * matrix(-4,0, MATRIX_TRANSLATE)
				I.transform *= selected_filter.overlay_scale
				add_overlay(I - 7)
				I = image(selected_filter.get_icon(2))
				I.transform = matrix(selected_filter.overlay_scale, MATRIX_SCALE)
				add_overlay(I)
				I = image(selected_filter.get_icon(3))
				I.transform = matrix(selected_filter.overlay_scale, MATRIX_SCALE) * matrix(4,0, MATRIX_TRANSLATE)
				I.transform *= selected_filter.overlay_scale
				add_overlay(I + 7)
			else
				I = image(selected_filter.get_icon(1))
				I.transform = matrix(selected_filter.overlay_scale, MATRIX_SCALE) * matrix(-4,0, MATRIX_TRANSLATE)
				add_overlay(I)
				I = image(selected_filter.get_icon(2))
				I.transform = matrix(selected_filter.overlay_scale, MATRIX_SCALE)
				add_overlay(I)
				I = image(icon('icons/obj/recycling.dmi', "filter_overflow"))
				add_overlay(I)


/obj/machinery/conveyor/filter/proc/update_desc()
	desc = "A filter that checks for specific objects and redirects them in another direction.\nMatches get sent [dir2text(filter_output_dir)], everything else goes [dir2text(unfiltered_output_dir)].\nA screwdriver changes the output direction of filtered items, while a wrench changes the output direction of everything else."
	if(!selected_filter)
		desc += "\nIt currently has no set filter!"
	else
		desc += "\nIt is set to filter out [selected_filter.name]."

/obj/machinery/conveyor/filter/proc/get_it_twisted(angle)
	switch(angle)
		if(NORTH)
			return EAST
		if(EAST)
			return SOUTH
		if(SOUTH)
			return WEST
	return NORTH

/obj/machinery/conveyor/filter/convey(list/affecting)
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
			var/unfiltered = TRUE
			if(selected_filter)
				for(var/filter in selected_filter.filter_typepath)
					if(movable_thing.type == filter)
						step(movable_thing, filter_output_dir)
						unfiltered = FALSE
						break
			if(unfiltered)				
				step(movable_thing, unfiltered_output_dir)
	conveying = FALSE

/obj/machinery/conveyor/filter/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_CROWBAR)
		user.visible_message("<span class='notice'>[user] struggles to pry up \the [src] with \the [I].</span>", \
		"<span class='notice'>You struggle to pry up \the [src] with \the [I].</span>")
		if(I.use_tool(src, user, 40, volume=40))
			if(selected_filter)
				qdel(selected_filter)
			if(!(machine_stat & BROKEN))
				var/obj/item/stack/conveyor_filter/C = new /obj/item/stack/conveyor_filter(loc, 1, TRUE, null, null, id)
				transfer_fingerprints_to(C)
			to_chat(user, "<span class='notice'>You remove the conveyor belt.</span>")
			qdel(src)

	else if(I.tool_behaviour == TOOL_WRENCH) // rotate the output direction if the item does not match
		if(!(machine_stat & BROKEN))
			I.play_tool_sound(src)
			unfiltered_output_dir = get_it_twisted(unfiltered_output_dir)
			update_icon_state()
			to_chat(user, "<span class='notice'>You alter the filter so unfiltered items are sent [dir2text(unfiltered_output_dir)].</span>")

	else if(I.tool_behaviour == TOOL_SCREWDRIVER) // rotate the output direction if the item does match
		if(!(machine_stat & BROKEN))
			I.play_tool_sound(src)
			filter_output_dir = get_it_twisted(filter_output_dir)
			update_icon_state()
			to_chat(user, "<span class='notice'>You alter the filter so filtered items are sent [dir2text(filter_output_dir)].</span>")

	else if(user.a_intent != INTENT_HARM)
		user.transferItemToLoc(I, drop_location())

/obj/machinery/conveyor/filter/ui_interact(mob/user)
	. = ..()
	var/dat
	if(selected_filter)
		dat = "<b>Current filter:</b> " + selected_filter.name + "<br>"
	else
		dat = "<b>Current filter:</b> None<br>"
	dat += {"<div style="float:left; width:20%">
			<b>Materials</b><br>"}
	for(var/filter in subtypesof(/datum/filter_setting/material))
		var/datum/filter_setting/fs = filter
		dat += "<A href='byond://?src=[REF(src)];set_filter=[fs.type]'>[fs.name]</A> <br>"
	dat += {"</div>
			<div style="float:left; width:20%">
			<b>Low Tier Factories</b><br>"}
	for(var/filter in subtypesof(/datum/filter_setting/low))
		var/datum/filter_setting/fs = filter
		dat += "<A href='byond://?src=[REF(src)];set_filter=[fs.type]'>[fs.name]</A> <br>"
	dat += {"</div>
			<div style="float:left; width:20%">
			<b>Medium Tier Factories</b><br>"}
	for(var/filter in subtypesof(/datum/filter_setting/medium))
		var/datum/filter_setting/fs = filter
		dat += "<A href='byond://?src=[REF(src)];set_filter=[fs.type]'>[fs.name]</A> <br>"
	dat += {"</div>
			<div style="float:left; width:20%">
			<b>High Tier Factories</b><br>"}
	for(var/filter in subtypesof(/datum/filter_setting/high))
		var/datum/filter_setting/fs = filter
		dat += "<A href='byond://?src=[REF(src)];set_filter=[fs.type]'>[fs.name]</A> <br>"
	dat += {"</div>
			<div style="float:left; width:20%">
			<b>Misc</b><br>"}
	for(var/filter in subtypesof(/datum/filter_setting/misc))
		var/datum/filter_setting/fs = filter
		dat += "<A href='byond://?src=[REF(src)];set_filter=[fs.type]'>[fs.name]</A> <br>"
	dat += "</div>"
	var/datum/browser/popup = new(user, "conveyor_filter_settings", "Filter Settings", 1200, 700)
	popup.set_content(dat)
	popup.open()

/obj/machinery/conveyor/filter/Topic(href, href_list)
	. = ..()
	if(.)
		return .
	if(ishuman(usr))
		usr.set_machine(src)
		if(selected_filter)
			qdel(selected_filter)
		var/newfilter = href_list["set_filter"]
		if(newfilter)
			selected_filter = new newfilter()
	update_desc()
	update_icon_state()
	add_fingerprint(usr)
	updateUsrDialog()

/obj/item/stack/conveyor_filter
	name = "conveyor filter assembly"
	desc = "A conveyor filter assembly."
	icon = 'icons/obj/recycling.dmi'
	icon_state = "filter_construct"
	max_amount = 30
	singular_name = "conveyor filter"
	w_class = WEIGHT_CLASS_BULKY
	merge_type = /obj/item/stack/conveyor_filter
	var/id = ""

/obj/item/stack/conveyor_filter/afterattack(atom/A, mob/user, proximity)
	. = ..()
	if(!proximity || user.stat || !isfloorturf(A) || istype(A, /area/shuttle))
		return
	var/cdir = get_dir(A, user)
	if(A == user.loc)
		to_chat(user, "<span class='warning'>You cannot place a conveyor filter under yourself!</span>")
		return
	var/obj/machinery/conveyor/filter/C = new(A, cdir, id)
	transfer_fingerprints_to(C)
	use(1)

/obj/item/stack/conveyor_filter/attackby(obj/item/I, mob/user, params)
	..()
	if(istype(I, /obj/item/conveyor_switch_construct))
		to_chat(user, "<span class='notice'>You link the switch to the conveyor filter assembly.</span>")
		var/obj/item/conveyor_switch_construct/C = I
		id = C.id
