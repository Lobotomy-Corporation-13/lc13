/* Table Frames
 * Contains:
 *		Frames
 *		Wooden Frames
 */


/*
 * Normal Frames
 */

/obj/structure/table_frame
	name = "table frame"
	desc = "Four metal legs with four framing rods for a table. You could easily pass through this."
	icon = 'icons/obj/structures.dmi'
	icon_state = "nu_table_frame"
	density = FALSE
	anchored = FALSE
	layer = PROJECTILE_HIT_THRESHHOLD_LAYER
	max_integrity = 100
	var/framestack = /obj/item/stack/rods
	var/framestackamount = 2


/obj/structure/table_frame/wrench_act(mob/living/user, obj/item/I)
	to_chat(user, span_notice("You start disassembling [src]..."))
	I.play_tool_sound(src)
	if(!I.use_tool(src, user, 3 SECONDS))
		return TRUE
	playsound(loc, 'sound/items/deconstruct.ogg', 50, TRUE)
	deconstruct(TRUE)
	return TRUE


/obj/structure/table_frame/attackby(obj/item/I, mob/user, params)
	if(isstack(I))
		var/obj/item/stack/material = I
		if(material.tableVariant)
			if(material.get_amount() < 1)
				to_chat(user, span_warning("You need one [material.name] sheet to do this!"))
				return
			if(locate(/obj/structure/table) in loc)
				to_chat(user, span_warning("There's already a table built here!"))
				return
			to_chat(user, span_notice("You start adding [material] to [src]..."))
			if(!do_after(user, 2 SECONDS, target = src) || !material.use(1) || (locate(/obj/structure/table) in loc))
				return
			make_new_table(material.tableVariant)
		else if(istype(material, /obj/item/stack/sheet))
			if(material.get_amount() < 1)
				to_chat(user, span_warning("You need one sheet to do this!"))
				return
			if(locate(/obj/structure/table) in loc)
				to_chat(user, span_warning("There's already a table built here!"))
				return
			to_chat(user, span_notice("You start adding [material] to [src]..."))
			if(!do_after(user, 2 SECONDS, target = src) || !material.use(1) || (locate(/obj/structure/table) in loc))
				return
			var/list/material_list = list()
			if(material.material_type)
				material_list[material.material_type] = MINERAL_MATERIAL_AMOUNT
			make_new_table(/obj/structure/table/greyscale, material_list)
		return
	return ..()


/obj/structure/table_frame/proc/make_new_table(table_type, custom_materials, carpet_type) //makes sure the new table made retains what we had as a frame
	var/obj/structure/table/T = new table_type(loc)
	T.frame = type
	T.framestack = framestack
	T.framestackamount = framestackamount
	if (carpet_type)
		T.buildstack = carpet_type
	if(custom_materials)
		T.set_custom_materials(custom_materials)
	// Transfer resurgence beauty component to the new table
	var/datum/component/resurgence_beauty/beauty_comp = GetComponent(/datum/component/resurgence_beauty)
	if(beauty_comp)
		// Transfer existing beauty plus a material bonus
		var/material_bonus = get_table_material_beauty(custom_materials, table_type)
		T.AddComponent(/datum/component/resurgence_beauty, beauty_comp.beauty + material_bonus)
	qdel(src)

/// Calculate beauty bonus from the material used to build a table
/obj/structure/table_frame/proc/get_table_material_beauty(list/custom_materials, table_type)
	// Fancy wood tables (carpet-topped)
	if(ispath(table_type, /obj/structure/table/wood/fancy))
		return 5
	// Poker tables
	if(ispath(table_type, /obj/structure/table/wood/poker))
		return 3
	// Check custom materials for precious metals
	if(custom_materials)
		for(var/mat_type in custom_materials)
			if(ispath(mat_type, /datum/material/gold))
				return 8
			if(ispath(mat_type, /datum/material/diamond))
				return 10
			if(ispath(mat_type, /datum/material/silver))
				return 6
			if(ispath(mat_type, /datum/material/bronze))
				return 4
			if(ispath(mat_type, /datum/material/uranium))
				return 3
			if(ispath(mat_type, /datum/material/plasma))
				return 3
			if(ispath(mat_type, /datum/material/titanium))
				return 4
			if(ispath(mat_type, /datum/material/bananium))
				return 5
	// Glass table
	if(ispath(table_type, /obj/structure/table/glass))
		return 3
	// Reinforced table
	if(ispath(table_type, /obj/structure/table/reinforced))
		return 2
	// Basic wood or metal table
	if(ispath(table_type, /obj/structure/table/wood))
		return 1
	if(ispath(table_type, /obj/structure/table))
		return 1
	return 0

/obj/structure/table_frame/deconstruct(disassembled = TRUE)
	new framestack(get_turf(src), framestackamount)
	qdel(src)

/obj/structure/table_frame/narsie_act()
	new /obj/structure/table_frame/wood(src.loc)
	qdel(src)

/*
 * Wooden Frames
 */

/obj/structure/table_frame/wood
	name = "wooden table frame"
	desc = "Four wooden legs with four framing wooden rods for a wooden table. You could easily pass through this."
	icon_state = "nu_wood_frame"
	framestack = /obj/item/stack/sheet/mineral/wood
	framestackamount = 2
	resistance_flags = FLAMMABLE

/obj/structure/table_frame/wood/attackby(obj/item/I, mob/user, params)
	if (istype(I, /obj/item/stack))
		var/obj/item/stack/material = I
		var/toConstruct // stores the table variant
		var/carpet_type // stores the carpet type used for construction in case of poker tables
		if(istype(I, /obj/item/stack/sheet/mineral/wood))
			toConstruct = /obj/structure/table/wood
		else if(istype(I, /obj/item/stack/tile/carpet))
			toConstruct = /obj/structure/table/wood/poker
			carpet_type = I.type
		if (toConstruct)
			if(material.get_amount() < 1)
				to_chat(user, span_warning("You need one [material.name] sheet to do this!"))
				return
			to_chat(user, span_notice("You start adding [material] to [src]..."))
			if(do_after(user, 20, target = src) && material.use(1))
				make_new_table(toConstruct, null, carpet_type)
	else
		return ..()
