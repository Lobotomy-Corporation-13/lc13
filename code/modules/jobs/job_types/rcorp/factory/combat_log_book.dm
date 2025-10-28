/obj/item/combat_log_book
	name = "combat log book"
	desc = "A specialized field manual for recording hostile entity data. Use on creatures to scan them."
	icon = 'icons/obj/library.dmi'
	icon_state = "stealthmanual"
	w_class = WEIGHT_CLASS_SMALL
	var/list/creature_database = list()
	var/current_page = 1
	var/scanning_range = 1

/obj/item/combat_log_book/attack_self(mob/user)
	if(!user.client)
		return
	ui_interact(user)

/obj/item/combat_log_book/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!istype(target, /mob/living/simple_animal/hostile))
		return

	var/mob/living/simple_animal/hostile/H = target
	if(!H.stat == DEAD && H.client)
		to_chat(user, span_warning("You can only scan unconscious or non-human/sub-human creatures!"))
		return

	// Check if this type is already scanned
	var/mob_type = H.type
	for(var/list/entry in creature_database)
		if(entry["type"] == mob_type)
			to_chat(user, span_notice("This type of [H.name] is already in your database."))
			return

	// Extract creature data
	var/list/creature_data = list()
	creature_data["type"] = H.type
	creature_data["name"] = H.name
	creature_data["icon"] = icon2base64(getFlatIcon(H))
	creature_data["notes"] = ""

	// Get health and damage info
	creature_data["health"] = H.health
	creature_data["max_health"] = H.maxHealth

	// Get movement speed
	creature_data["move_to_delay"] = H.move_to_delay

	// Get resistances
	var/list/resistances = list()
	if(H.damage_coeff)
		var/datum/dam_coeff/DC = H.damage_coeff
		resistances["red"] = DC.red
		resistances["white"] = DC.white
		resistances["black"] = DC.black
		resistances["pale"] = DC.pale
	else
		resistances["red"] = "?"
		resistances["white"] = "?"
		resistances["black"] = "?"
		resistances["pale"] = "?"

	// Get melee damage
	creature_data["melee_damage_lower"] = H.melee_damage_lower
	creature_data["melee_damage_upper"] = H.melee_damage_upper
	creature_data["melee_damage_type"] = H.melee_damage_type

	// Get melee attack speed
	if(H.rapid_melee > 1)
		creature_data["rapid_melee"] = H.rapid_melee
	else if(H.attack_cooldown > 0)
		creature_data["attack_cooldown"] = H.attack_cooldown
	else
		creature_data["rapid_melee"] = 1

	// Check if ranged
	if(H.casingtype)
		var/obj/item/ammo_casing/casing = new H.casingtype
		if(casing.projectile_type)
			var/obj/projectile/P = new casing.projectile_type
			creature_data["ranged_damage"] = P.damage
			creature_data["ranged_damage_type"] = P.damage_type
			qdel(P)
		qdel(casing)
		creature_data["is_ranged"] = TRUE
		creature_data["ranged_cooldown_time"] = H.ranged_cooldown_time
		if(H.rapid > 0)
			creature_data["rapid"] = H.rapid
			creature_data["rapid_fire_delay"] = H.rapid_fire_delay
	else if(H.projectiletype)
		var/obj/projectile/P = new H.projectiletype
		creature_data["ranged_damage"] = P.damage
		creature_data["ranged_damage_type"] = P.damage_type
		qdel(P)
		creature_data["is_ranged"] = TRUE
		creature_data["ranged_cooldown_time"] = H.ranged_cooldown_time
		if(H.rapid > 0)
			creature_data["rapid"] = H.rapid
			creature_data["rapid_fire_delay"] = H.rapid_fire_delay
	else
		creature_data["is_ranged"] = FALSE

	creature_data["resistances"] = resistances

	creature_database += list(creature_data)
	to_chat(user, span_notice("You scan [H.name] and add it to your log book."))
	playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)

/obj/item/combat_log_book/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CombatLogBook", name)
		ui.open()

/obj/item/combat_log_book/ui_data(mob/user)
	var/list/data = list()
	data["creatures"] = creature_database
	data["current_page"] = current_page
	data["total_pages"] = length(creature_database)

	if(length(creature_database) > 0 && current_page <= length(creature_database))
		data["current_creature"] = creature_database[current_page]
	else
		data["current_creature"] = null

	return data

/obj/item/combat_log_book/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("next_page")
			if(current_page < length(creature_database))
				current_page++
				. = TRUE

		if("prev_page")
			if(current_page > 1)
				current_page--
				. = TRUE

		if("update_notes")
			if(length(creature_database) > 0 && current_page <= length(creature_database))
				creature_database[current_page]["notes"] = params["notes"]
				. = TRUE

		if("create_report")
			if(length(creature_database) > 0 && current_page <= length(creature_database))
				var/mob/living/user = usr
				var/obj/item/creature_report/report = new(get_turf(user))
				var/list/data_to_copy = creature_database[current_page]
				report.creature_data = data_to_copy.Copy()
				if(report.creature_data && report.creature_data["name"])
					report.name = "[report.creature_data["name"]] report"
				user.put_in_hands(report)
				to_chat(user, span_notice("You create a report for [creature_database[current_page]["name"]]."))
				. = TRUE

// Creature Report - Read-only version
/obj/item/creature_report
	name = "creature report"
	desc = "A field report containing data on a specific hostile entity."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "docs_part"
	w_class = WEIGHT_CLASS_TINY
	var/list/creature_data = list()

/obj/item/creature_report/Initialize()
	. = ..()
	if(creature_data && creature_data["name"])
		name = "[creature_data["name"]] report"

/obj/item/creature_report/attack_self(mob/user)
	if(!user.client)
		return
	ui_interact(user)

/obj/item/creature_report/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CreatureReport", name)
		ui.open()

/obj/item/creature_report/ui_data(mob/user)
	var/list/data = list()
	data["creature"] = creature_data
	return data

/obj/item/creature_report/ui_state(mob/user)
	return GLOB.inventory_state
