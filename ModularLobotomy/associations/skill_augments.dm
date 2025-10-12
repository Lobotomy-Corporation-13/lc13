//--------------------------------------
// Skill Augment Fabricator System
//--------------------------------------

// Design datum for temporary storage during fabrication
/datum/skill_augment_design
	var/rank = 1
	var/max_slots = 1
	var/max_charge = 40
	var/list/selected_skills = list()
	var/total_slot_cost = 0
	var/list/material_cost = list()
	var/name = "Skill Augment"

//--------------------------------------
// The Skill Augment Fabricator Machine
//--------------------------------------

/obj/machinery/skill_augment_fabricator
	name = "Skill Augment Fabricator"
	desc = "A specialized machine for creating skill-enhanced cybernetic augmentations."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "circuit_imprinter"
	anchored = TRUE
	density = TRUE

	var/busy = FALSE
	var/fabrication_time = 10 SECONDS

	// Material storage
	var/list/stored_materials = list()

	// Current design being worked on
	var/datum/skill_augment_design/current_design

	// Role restrictions
	var/list/allowed_roles = list("Prosthetics Surgeon", "Office Director", "Office Fixer", "Doctor", "Fixer", "Workshop Attendant")

	// Available templates based on rank
	var/list/available_templates = list(
		"Rank 1 - Basic" = list(
			"rank" = 1,
			"slots" = 4,
			"charge" = 60,
			"material_cost" = list(
				/obj/item/tresmetal = 2
			)
		),
		"Rank 2 - Enhanced" = list(
			"rank" = 2,
			"slots" = 6,
			"charge" = 100,
			"material_cost" = list(
				/obj/item/tresmetal = 2,
				/obj/item/tresmetal/steel = 1
			)
		),
		"Rank 3 - Advanced" = list(
			"rank" = 3,
			"slots" = 6,
			"charge" = 160,
			"material_cost" = list(
				/obj/item/tresmetal/goldsteel = 2,
				/obj/item/tresmetal/silversteel = 1
			)
		),
		"Rank 4 - Superior" = list(
			"rank" = 4,
			"slots" = 8,
			"charge" = 250,
			"material_cost" = list(
				/obj/item/tresmetal/silversteel = 2,
				/obj/item/tresmetal/puremetal = 1
			)
		),
		"Rank 5 - Masterwork" = list(
			"rank" = 5,
			"slots" = 9,
			"charge" = 350,
			"material_cost" = list(
				/obj/item/tresmetal/puremetal = 2,
				/obj/item/tresmetal/pinksteel = 2
			)
		),

		// Injectable Templates (50% reduced charge)
		"Injectable Rank 1 - Basic" = list(
			"rank" = 1,
			"slots" = 4,
			"charge" = 30,
			"injectable" = TRUE,
			"material_cost" = list(
				/obj/item/tresmetal = 3
			)
		),
		"Injectable Rank 2 - Enhanced" = list(
			"rank" = 2,
			"slots" = 6,
			"charge" = 50,
			"injectable" = TRUE,
			"material_cost" = list(
				/obj/item/tresmetal = 3,
				/obj/item/tresmetal/steel = 2
			)
		),
		"Injectable Rank 3 - Advanced" = list(
			"rank" = 3,
			"slots" = 6,
			"charge" = 80,
			"injectable" = TRUE,
			"material_cost" = list(
				/obj/item/tresmetal/goldsteel = 3,
				/obj/item/tresmetal/silversteel = 2
			)
		),
		"Injectable Rank 4 - Superior" = list(
			"rank" = 4,
			"slots" = 8,
			"charge" = 125,
			"injectable" = TRUE,
			"material_cost" = list(
				/obj/item/tresmetal/silversteel = 3,
				/obj/item/tresmetal/puremetal = 2
			)
		),
		"Injectable Rank 5 - Masterwork" = list(
			"rank" = 5,
			"slots" = 9,
			"charge" = 175,
			"injectable" = TRUE,
			"material_cost" = list(
				/obj/item/tresmetal/puremetal = 3,
				/obj/item/tresmetal/pinksteel = 3
			)
		)
	)

	// Available skills with their costs - ALL skills from fixerskills/skills.dm
	var/list/skill_data = list(
		// Level 1 Skills (13 skills)
		/datum/action/cooldown/dash = list(
			"name" = "Dash",
			"slot_cost" = 1,
			"charge_cost" = 15,
			"skill_level" = 1,
			"desc" = "Dash forwards a few tiles."
		),
		/datum/action/cooldown/dash/back = list(
			"name" = "Backstep",
			"slot_cost" = 1,
			"charge_cost" = 15,
			"skill_level" = 1,
			"desc" = "Hop back a few tiles."
		),
		/datum/action/cooldown/smokedash = list(
			"name" = "Smokedash",
			"slot_cost" = 1,
			"charge_cost" = 20,
			"skill_level" = 1,
			"desc" = "Drop a smoke bomb and dash forwards a few tiles"
		),
		/datum/action/cooldown/assault = list(
			"name" = "Assault",
			"slot_cost" = 2,
			"charge_cost" = 25,
			"skill_level" = 1,
			"desc" = "Increase movement speed by 10% for 5 seconds."
		),
		/datum/action/cooldown/retreat = list(
			"name" = "Retreat",
			"slot_cost" = 1,
			"charge_cost" = 20,
			"skill_level" = 1,
			"desc" = "Increase movement speed by 30% and decrease defenses by 30% for 5 seconds"
		),
		/datum/action/cooldown/healing = list(
			"name" = "Healing",
			"slot_cost" = 1,
			"charge_cost" = 10,
			"skill_level" = 1,
			"desc" = "Heal HP by 15 for each human in a 2 tile range."
		),
		/datum/action/cooldown/soothing = list(
			"name" = "Soothing",
			"slot_cost" = 1,
			"charge_cost" = 10,
			"skill_level" = 1,
			"desc" = "Heal SP by 15 for each human in a 2 tile range."
		),
		/datum/action/cooldown/curing = list(
			"name" = "Curing",
			"slot_cost" = 1,
			"charge_cost" = 15,
			"skill_level" = 1,
			"desc" = "Heal HP and SP by 5 for each human in a 2 tile range."
		),
		/datum/action/cooldown/firstaid = list(
			"name" = "First Aid",
			"slot_cost" = 1,
			"charge_cost" = 12,
			"skill_level" = 1,
			"desc" = "Increase defenses by 20% and immobilize for 5 seconds. Heal for 30 HP after."
		),
		/datum/action/cooldown/meditation = list(
			"name" = "Meditation",
			"slot_cost" = 1,
			"charge_cost" = 8,
			"skill_level" = 1,
			"desc" = "Increase defenses by 20% and immobilize for 5 seconds. Heal for 30 SP after."
		),
		/datum/action/cooldown/hunkerdown = list(
			"name" = "Hunker Down",
			"slot_cost" = 3,
			"charge_cost" = 15,
			"skill_level" = 1,
			"desc" = "Increase defenses by 40% and increase slowdown to 1.5x for 10 seconds"
		),
		/datum/action/cooldown/mark = list(
			"name" = "Mark",
			"slot_cost" = 1,
			"charge_cost" = 5,
			"skill_level" = 1,
			"desc" = "Mark targets for increased damage"
		),
		/datum/action/cooldown/light = list(
			"name" = "Light",
			"slot_cost" = 1,
			"charge_cost" = 5,
			"skill_level" = 1,
			"desc" = "Creates light source"
		),

		// Level 2 Skills (7 skills)
		/datum/action/cooldown/butcher = list(
			"name" = "Butcher",
			"slot_cost" = 2,
			"charge_cost" = 30,
			"skill_level" = 2,
			"desc" = "Butcher all non-human, butcherable corpses in a 2 tile radius."
		),
		/datum/action/cooldown/solarflare = list(
			"name" = "Solar Flare",
			"slot_cost" = 2,
			"charge_cost" = 35,
			"skill_level" = 2,
			"desc" = "Applies blindness to all humans in a 7 tile radius for 2 seconds"
		),
		/datum/action/cooldown/confusion = list(
			"name" = "Confusion",
			"slot_cost" = 2,
			"charge_cost" = 35,
			"skill_level" = 2,
			"desc" = "Applies a variety of debuffs to all humans in a 7 tile radius"
		),
		/datum/action/cooldown/lockpick = list(
			"name" = "Lockpick",
			"slot_cost" = 1,
			"charge_cost" = 20,
			"skill_level" = 2,
			"desc" = "Unlock all doors in a 1 tile radius."
		),
		/datum/action/cooldown/lifesteal = list(
			"name" = "Lifesteal",
			"slot_cost" = 3,
			"charge_cost" = 40,
			"skill_level" = 2,
			"desc" = "Drain HP and SP from all living things in a 2 tile radius"
		),
		/datum/action/cooldown/skulk = list(
			"name" = "Skulk",
			"slot_cost" = 2,
			"charge_cost" = 25,
			"skill_level" = 2,
			"desc" = "Temporary stealth"
		),
		/datum/action/cooldown/autoloader = list(
			"name" = "Autoloader",
			"slot_cost" = 2,
			"charge_cost" = 30,
			"skill_level" = 2,
			"desc" = "Automatically reload weapons"
		),

		// Level 3 Skills (4 skills - all innate/passive)
		/datum/action/innate/healthhud = list(
			"name" = "Healthsight",
			"slot_cost" = 3,
			"charge_cost" = 0,
			"skill_level" = 3,
			"desc" = "Adds a medical hud to see the HP and SP of all mobs."
		),
		/datum/action/innate/bulletproof = list(
			"name" = "Bulletproof",
			"slot_cost" = 4,
			"charge_cost" = 0,
			"skill_level" = 3,
			"desc" = "40% chance to ignore incoming bullets."
		),
		/datum/action/innate/battleready = list(
			"name" = "Veteran",
			"slot_cost" = 3,
			"charge_cost" = 0,
			"skill_level" = 3,
			"desc" = "Increase defenses by 20%."
		),
		/datum/action/innate/fleetfoot = list(
			"name" = "Fleetfoot",
			"slot_cost" = 3,
			"charge_cost" = 0,
			"skill_level" = 3,
			"desc" = "Increase movement speed by 10%."
		),

		// Level 4 Skills (7 skills - all high power)
		/datum/action/cooldown/timestop = list(
			"name" = "Timestop",
			"slot_cost" = 5,
			"charge_cost" = 100,
			"skill_level" = 4,
			"desc" = "Stop time in a range of 2 tiles, for 2 seconds."
		),
		/datum/action/cooldown/dismember = list(
			"name" = "Dismember",
			"slot_cost" = 4,
			"charge_cost" = 80,
			"skill_level" = 4,
			"desc" = "Dismember a random arm from every human in a 1 tile range"
		),
		/datum/action/cooldown/shockwave = list(
			"name" = "Shockwave",
			"slot_cost" = 4,
			"charge_cost" = 80,
			"skill_level" = 4,
			"desc" = "Knock everything in a radius back"
		),
		/datum/action/cooldown/warbanner = list(
			"name" = "Warbanner",
			"slot_cost" = 3,
			"charge_cost" = 70,
			"skill_level" = 4,
			"desc" = "All humans in a 3 tile radius gain a 70% damage reduction for 10 seconds."
		),
		/datum/action/cooldown/warcry = list(
			"name" = "Warcry",
			"slot_cost" = 3,
			"charge_cost" = 50,
			"skill_level" = 4,
			"desc" = "All humans in a 3 tile radius move 50% faster for 10 seconds."
		),
		// /datum/action/cooldown/nuke = list(
		// 	"name" = "Nuke",
		// 	"slot_cost" = 6,
		// 	"charge_cost" = 120,
		// 	"skill_level" = 4,
		// 	"desc" = "Devastating area attack"
		// ),
		// /datum/action/cooldown/reraise = list(
		// 	"name" = "Reraise",
		// 	"slot_cost" = 4,
		// 	"charge_cost" = 90,
		// 	"skill_level" = 4,
		// 	"desc" = "Automatic revival on death"
		// ),

		// Fishing Skills - Level 1 (11 skills)
		/datum/action/cooldown/fishing/detect = list(
			"name" = "Fishing: Detect",
			"slot_cost" = 1,
			"charge_cost" = 8,
			"skill_level" = 1,
			"desc" = "Detect nearby entities"
		),
		/datum/action/cooldown/fishing/scry = list(
			"name" = "Fishing: Scry",
			"slot_cost" = 1,
			"charge_cost" = 10,
			"skill_level" = 1,
			"desc" = "Remote viewing"
		),
		/datum/action/cooldown/fishing/planet = list(
			"name" = "Fishing: Planet",
			"slot_cost" = 1,
			"charge_cost" = 12,
			"skill_level" = 1,
			"desc" = "Planetary manipulation"
		),
		/datum/action/cooldown/fishing/planet2 = list(
			"name" = "Fishing: Planet II",
			"slot_cost" = 1,
			"charge_cost" = 15,
			"skill_level" = 1,
			"desc" = "Enhanced planetary power"
		),
		/datum/action/cooldown/fishing/prayer = list(
			"name" = "Fishing: Prayer",
			"slot_cost" = 1,
			"charge_cost" = 8,
			"skill_level" = 1,
			"desc" = "Divine intervention"
		),
		/datum/action/cooldown/fishing/sacredword = list(
			"name" = "Fishing: Sacred Word",
			"slot_cost" = 1,
			"charge_cost" = 12,
			"skill_level" = 1,
			"desc" = "Holy incantation"
		),
		/datum/action/cooldown/fishing/love = list(
			"name" = "Fishing: Love",
			"slot_cost" = 1,
			"charge_cost" = 10,
			"skill_level" = 1,
			"desc" = "Charm enemies"
		),
		/datum/action/cooldown/fishing/moonmove = list(
			"name" = "Fishing: Moon Move",
			"slot_cost" = 1,
			"charge_cost" = 18,
			"skill_level" = 1,
			"desc" = "Lunar-powered movement"
		),
		/datum/action/cooldown/fishing/commune = list(
			"name" = "Fishing: Commune",
			"slot_cost" = 1,
			"charge_cost" = 15,
			"skill_level" = 1,
			"desc" = "Communicate with nature"
		),
		/datum/action/cooldown/fishing/fishlockpick = list(
			"name" = "Fishing: Lockpick",
			"slot_cost" = 1,
			"charge_cost" = 12,
			"skill_level" = 1,
			"desc" = "Mystical lock opening"
		),
		/datum/action/cooldown/fishing/fishtelepathy = list(
			"name" = "Fishing: Telepathy",
			"slot_cost" = 1,
			"charge_cost" = 15,
			"skill_level" = 1,
			"desc" = "Read minds"
		),

		// Fishing Skills - Level 2 (4 skills)
		/datum/action/cooldown/fishing/smite = list(
			"name" = "Fishing: Smite",
			"slot_cost" = 2,
			"charge_cost" = 35,
			"skill_level" = 2,
			"desc" = "Divine punishment"
		),
		/datum/action/cooldown/fishing/might = list(
			"name" = "Fishing: Might",
			"slot_cost" = 2,
			"charge_cost" = 30,
			"skill_level" = 2,
			"desc" = "Enhance physical power"
		),
		/datum/action/cooldown/fishing/awe = list(
			"name" = "Fishing: Awe",
			"slot_cost" = 2,
			"charge_cost" = 25,
			"skill_level" = 2,
			"desc" = "Inspire fear or reverence"
		),
		/datum/action/cooldown/fishing/chakra = list(
			"name" = "Fishing: Chakra",
			"slot_cost" = 2,
			"charge_cost" = 40,
			"skill_level" = 2,
			"desc" = "Energy manipulation"
		),

		// Fishing Skills - Level 4 (3 skills)
		/datum/action/cooldown/fishing/supernova = list(
			"name" = "Fishing: Supernova",
			"slot_cost" = 5,
			"charge_cost" = 110,
			"skill_level" = 4,
			"desc" = "Stellar explosion"
		),
		/datum/action/cooldown/fishing/alignment = list(
			"name" = "Fishing: Alignment",
			"slot_cost" = 4,
			"charge_cost" = 85,
			"skill_level" = 4,
			"desc" = "Cosmic alignment power"
		),
		/datum/action/cooldown/fishing/planetstop = list(
			"name" = "Fishing: Planet Stop",
			"slot_cost" = 6,
			"charge_cost" = 130,
			"skill_level" = 4,
			"desc" = "Halt planetary motion"
		)
	)

/obj/machinery/skill_augment_fabricator/proc/get_skill_data()
	return skill_data

/obj/machinery/skill_augment_fabricator/Initialize()
	. = ..()
	current_design = new /datum/skill_augment_design()

/obj/machinery/skill_augment_fabricator/Destroy()
	QDEL_NULL(current_design)
	return ..()

/obj/machinery/skill_augment_fabricator/attackby(obj/item/I, mob/user)
	if(busy)
		to_chat(user, span_warning("[src] is currently busy!"))
		return TRUE

	// Handle material insertion
	if(istype(I, /obj/item/tresmetal))
		var/obj/item/tresmetal/T = I
		var/mat_type = T.type

		if(!stored_materials[mat_type])
			stored_materials[mat_type] = 0

		stored_materials[mat_type]++
		to_chat(user, span_notice("You insert [T] into [src]."))
		playsound(src, 'sound/machines/click.ogg', 50, TRUE)
		qdel(T)
		update_icon()
		SStgui.update_uis(src)
		return TRUE

	return ..()

/obj/machinery/skill_augment_fabricator/attack_hand(mob/user)
	. = ..()
	if(!can_use_machine(user))
		to_chat(user, span_warning("You don't have the expertise to use this machine!"))
		return

	ui_interact(user)

/obj/machinery/skill_augment_fabricator/proc/can_use_machine(mob/user)
	if(!user?.mind?.assigned_role)
		return FALSE
	return (user.mind.assigned_role in allowed_roles)

/obj/machinery/skill_augment_fabricator/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SkillAugmentFabricator")
		ui.open()

/obj/machinery/skill_augment_fabricator/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/skill_augment_fabricator/ui_data(mob/user)
	var/list/data = list()
	var/list/current_skill_data = get_skill_data()

	// Current design info
	data["current_rank"] = current_design.rank
	data["current_slots"] = current_design.max_slots
	data["current_charge"] = current_design.max_charge
	data["selected_skills"] = list()
	data["total_slot_cost"] = current_design.total_slot_cost

	// Selected skills
	for(var/skill_type in current_design.selected_skills)
		var/list/skill_info = current_skill_data[skill_type]
		if(skill_info)
			data["selected_skills"] += list(list(
				"name" = skill_info["name"],
				"slot_cost" = skill_info["slot_cost"],
				"charge_cost" = skill_info["charge_cost"],
				"type_path" = "[skill_type]"
			))

	// Available templates
	data["templates"] = list()
	for(var/template_name in available_templates)
		var/list/template = available_templates[template_name]
		var/can_afford = can_afford_template(template)
		data["templates"] += list(list(
			"name" = template_name,
			"rank" = template["rank"],
			"slots" = template["slots"],
			"charge" = template["charge"],
			"can_afford" = can_afford,
			"materials_needed" = get_material_cost_display(template["material_cost"])
		))

	// Available skills filtered by rank
	data["available_skills"] = list()
	for(var/skill_type in current_skill_data)
		var/list/skill_info = current_skill_data[skill_type]
		if(skill_info["skill_level"] <= current_design.rank)
			data["available_skills"] += list(list(
				"name" = skill_info["name"],
				"desc" = skill_info["desc"],
				"slot_cost" = skill_info["slot_cost"],
				"charge_cost" = skill_info["charge_cost"],
				"skill_level" = skill_info["skill_level"],
				"type_path" = "[skill_type]",
				"can_add" = (current_design.total_slot_cost + skill_info["slot_cost"] <= current_design.max_slots)
			))

	// Stored materials
	data["stored_materials"] = list()
	for(var/mat_type in stored_materials)
		var/obj/item/tresmetal/T = mat_type
		data["stored_materials"] += list(list(
			"name" = initial(T.name),
			"amount" = stored_materials[mat_type]
		))

	data["busy"] = busy

	return data

/obj/machinery/skill_augment_fabricator/ui_act(action, params)
	. = ..()
	if(.)
		return

	if(busy)
		to_chat(usr, span_warning("[src] is currently busy!"))
		return

	switch(action)
		if("select_template")
			var/template_name = params["template"]
			if(!(template_name in available_templates))
				return

			var/list/template = available_templates[template_name]
			if(!can_afford_template(template))
				to_chat(usr, span_warning("Insufficient materials!"))
				return

			current_design.rank = template["rank"]
			current_design.max_slots = template["slots"]
			current_design.max_charge = template["charge"]
			current_design.material_cost = template["material_cost"]
			current_design.name = template_name
			current_design.selected_skills = list()
			current_design.total_slot_cost = 0
			return TRUE

		if("add_skill")
			var/skill_path = text2path(params["skill_type"])
			var/list/current_skill_data = get_skill_data()
			if(!skill_path || !(skill_path in current_skill_data))
				return

			if(skill_path in current_design.selected_skills)
				to_chat(usr, span_warning("This skill is already selected!"))
				return

			var/list/skill_info = current_skill_data[skill_path]
			if(current_design.total_slot_cost + skill_info["slot_cost"] > current_design.max_slots)
				to_chat(usr, span_warning("Not enough slots remaining!"))
				return

			current_design.selected_skills += skill_path
			current_design.total_slot_cost += skill_info["slot_cost"]
			return TRUE

		if("remove_skill")
			var/skill_path = text2path(params["skill_type"])
			if(!skill_path || !(skill_path in current_design.selected_skills))
				return

			var/list/current_skill_data = get_skill_data()
			var/list/skill_info = current_skill_data[skill_path]
			current_design.selected_skills -= skill_path
			current_design.total_slot_cost -= skill_info["slot_cost"]
			return TRUE

		if("fabricate")
			if(!current_design.rank || !length(current_design.selected_skills))
				to_chat(usr, span_warning("Design incomplete!"))
				return

			if(!can_afford_template(available_templates[current_design.name]))
				to_chat(usr, span_warning("Insufficient materials!"))
				return

			start_fabrication(usr)
			return TRUE

		if("clear_design")
			current_design = new /datum/skill_augment_design()
			return TRUE

/obj/machinery/skill_augment_fabricator/proc/can_afford_template(list/template)
	for(var/mat_type in template["material_cost"])
		var/required = template["material_cost"][mat_type]
		var/available = stored_materials[mat_type] || 0
		if(available < required)
			return FALSE
	return TRUE

/obj/machinery/skill_augment_fabricator/proc/get_material_cost_display(list/cost)
	var/list/display = list()
	for(var/mat_type in cost)
		var/obj/item/tresmetal/T = mat_type
		display += "[cost[mat_type]]x [initial(T.name)]"
	return display.Join(", ")

/obj/machinery/skill_augment_fabricator/proc/start_fabrication(mob/user)
	if(busy)
		return

	busy = TRUE
	playsound(src, 'sound/machines/buzz-sigh.ogg', 50, FALSE)
	to_chat(user, span_notice("You begin fabricating the skill augment..."))

	// Consume materials
	for(var/mat_type in current_design.material_cost)
		stored_materials[mat_type] -= current_design.material_cost[mat_type]
		if(stored_materials[mat_type] <= 0)
			stored_materials -= mat_type

	addtimer(CALLBACK(src, PROC_REF(finish_fabrication), user), fabrication_time)
	SStgui.update_uis(src)

/obj/machinery/skill_augment_fabricator/proc/finish_fabrication(mob/user)
	busy = FALSE

	// Check if this is an injectable template
	if(available_templates[current_design.name] && available_templates[current_design.name]["injectable"])
		// Create injectable skill augment item
		var/obj/item/skill_augment_injectable/SA = new(get_turf(src))
		SA.rank = current_design.rank
		SA.max_slots = current_design.max_slots
		SA.max_charge = current_design.max_charge
		SA.current_charge = SA.max_charge
		SA.attached_skills = current_design.selected_skills.Copy()
		SA.name = "injectable skill augment (Rank [SA.rank])"
		SA.desc = "An injectable skill augmentation containing [length(SA.attached_skills)] programmed skills. Can be administered by hitting a target."

		// Store skill charge costs
		for(var/skill_type in SA.attached_skills)
			var/list/skill_info = skill_data[skill_type]
			SA.skill_charge_costs[skill_type] = skill_info["charge_cost"]

		playsound(src, 'sound/machines/ping.ogg', 50, FALSE)
		visible_message(span_notice("[src] finishes fabrication of an injectable augment."))
	else
		// Create regular implantable organ
		var/obj/item/organ/cyberimp/chest/skill_augment/SA = new(get_turf(src))
		SA.rank = current_design.rank
		SA.max_slots = current_design.max_slots
		SA.max_charge = current_design.max_charge
		SA.current_charge = SA.max_charge
		SA.attached_skills = current_design.selected_skills.Copy()
		SA.name = "skill augment (Rank [SA.rank])"
		SA.desc = "A cybernetic augmentation containing [length(SA.attached_skills)] programmed skills."

		// Store skill charge costs for BLACK damage penalty
		for(var/skill_type in SA.attached_skills)
			var/list/skill_info = skill_data[skill_type]
			SA.skill_charge_costs[skill_type] = skill_info["charge_cost"]

		playsound(src, 'sound/machines/ping.ogg', 50, FALSE)
		visible_message(span_notice("[src] finishes fabrication."))

	// Reset design
	current_design = new /datum/skill_augment_design()
	SStgui.update_uis(src)

//--------------------------------------
// The Skill Augment Organ
//--------------------------------------

/obj/item/organ/cyberimp/chest/skill_augment
	name = "skill augment"
	desc = "A cybernetic chest implant that grants access to various combat skills."
	icon_state = "chest_implant"
	implant_color = "#FFD700"
	slot = ORGAN_SLOT_HEART_AID

	var/rank = 1
	var/max_slots = 1
	var/max_charge = 40
	var/current_charge = 40
	var/recharge_rate = 0.5 // Charge per second, scales with rank
	var/list/attached_skills = list()
	var/list/granted_actions = list()
	var/list/skill_charge_costs = list()

	// Stat requirements from augments.dm
	var/list/rankAttributeReqs = list(20, 40, 60, 80, 100)
	var/list/stats = list(
		FORTITUDE_ATTRIBUTE,
		PRUDENCE_ATTRIBUTE,
		TEMPERANCE_ATTRIBUTE,
		JUSTICE_ATTRIBUTE
	)

/obj/item/organ/cyberimp/chest/skill_augment/Initialize()
	. = ..()
	// Scale recharge rate with rank
	recharge_rate = 0.5 + (rank * 0.1)

/obj/item/organ/cyberimp/chest/skill_augment/Insert(mob/living/carbon/M, special = FALSE, drop_if_replaced = TRUE)
	. = ..()

	// Check stat requirements
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		var/stattotal = 0
		for(var/attribute in stats)
			stattotal += get_attribute_level(H, attribute)
		stattotal /= 4 // Average of stats

		if(stattotal < rankAttributeReqs[rank])
			to_chat(H, span_warning("Your stats are too low for this Rank [rank] augment! (Required: [rankAttributeReqs[rank]], Current: [stattotal])"))
			Remove(H)
			return FALSE

	// Grant all attached skills
	for(var/skill_type in attached_skills)
		var/datum/action/A = new skill_type()
		A.Grant(M)
		granted_actions += A

		// Hook into the action's Trigger to consume charge
		if(istype(A, /datum/action/cooldown))
			var/datum/action/cooldown/CA = A
			RegisterSignal(CA, COMSIG_ACTION_TRIGGER, PROC_REF(on_skill_used))

	to_chat(M, span_notice("The skill augment integrates with your body, granting you new abilities."))

/obj/item/organ/cyberimp/chest/skill_augment/Remove(mob/living/carbon/M, special = FALSE)
	// Remove all granted skills
	for(var/datum/action/A in granted_actions)
		UnregisterSignal(A, COMSIG_ACTION_TRIGGER)
		A.Remove(M)
		qdel(A)
	granted_actions.Cut()

	return ..()

// Removed passive charge regeneration - charge must be restored manually

/obj/item/organ/cyberimp/chest/skill_augment/proc/on_skill_used(datum/action/source)
	SIGNAL_HANDLER

	var/skill_type = source.type
	if(!(skill_type in skill_charge_costs))
		return

	var/cost = skill_charge_costs[skill_type]

	// Check charge - if insufficient, deal BURN damage instead of blocking
	if(current_charge < cost)
		var/shortfall = cost - current_charge
		var/burn_damage = shortfall * 2 // 2 BURN damage per missing charge point

		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			H.deal_damage(burn_damage, FIRE)
			to_chat(owner, span_boldwarning("CRITICAL AUGMENT OVERLOAD! Your skill augment tears at your skin!"))

			// Dramatic visual effect (removed emote due to signal handler constraints)
			playsound(get_turf(H), 'sound/weapons/ego/devyat_overclock.ogg', 25, 0, 4)

		// Still consume what charge we have
		current_charge = 0
		to_chat(owner, span_danger("Augment charge: [current_charge]/[max_charge] - DEPLETED!"))
		return

	// Normal operation - consume charge
	current_charge -= cost
	to_chat(owner, span_notice("Augment charge: [current_charge]/[max_charge]"))

	// Low charge warning
	if(current_charge < max_charge * 0.2)
		to_chat(owner, span_warning("Augment charge critical!"))

/obj/item/organ/cyberimp/chest/skill_augment/examine(mob/user)
	. = ..()
	. += span_notice("Rank: [rank]")
	. += span_notice("Slots: [max_slots]")
	. += span_notice("Max Charge: [max_charge]")
	. += span_notice("Attached Skills:")
	for(var/skill_type in attached_skills)
		var/datum/action/A = skill_type
		. += span_notice("- [initial(A.name)]")

//--------------------------------------
// Note: Skill charge costs are handled through
// the skill_data list in the fabricator machine
// to avoid modifying base skill definitions
//--------------------------------------

//--------------------------------------
// Skill Augment Tester Tool
//--------------------------------------

/obj/item/skill_augment_tester
	name = "Skill Augment Tester"
	desc = "A device that can check what rank of skill augments the target can use."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "records_stats"
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_SMALL
	var/list/stats = list(
		FORTITUDE_ATTRIBUTE,
		PRUDENCE_ATTRIBUTE,
		TEMPERANCE_ATTRIBUTE,
		JUSTICE_ATTRIBUTE
	)
	var/list/rankAttributeReqs = list(20, 40, 60, 80, 100)

/obj/item/skill_augment_tester/afterattack(atom/target, mob/user, proximity_flag)
	. = ..()
	if(!ishuman(target))
		to_chat(user, span_notice("No human identified."))
		return

	playsound(get_turf(src), 'sound/machines/cryo_warning.ogg', 50, TRUE, -1)
	var/mob/living/carbon/human/H = target

	// Check for existing skill augment
	var/obj/item/organ/cyberimp/chest/skill_augment/SA = H.getorganslot(ORGAN_SLOT_HEART_AID)
	if(SA && istype(SA, /obj/item/organ/cyberimp/chest/skill_augment))
		to_chat(user, span_notice("The target currently has a Rank [SA.rank] skill augment installed."))
		to_chat(user, span_notice("Augment Info:"))
		to_chat(user, span_notice("- Slots: [SA.max_slots]"))
		to_chat(user, span_notice("- Max Charge: [SA.max_charge]"))
		to_chat(user, span_notice("- Current Charge: [SA.current_charge]"))
		to_chat(user, span_notice("- Attached Skills: [length(SA.attached_skills)]"))
		for(var/skill_type in SA.attached_skills)
			var/datum/action/A = skill_type
			to_chat(user, span_notice("  • [initial(A.name)]"))

	// Calculate stat average
	var/stattotal = 0
	for(var/attribute in stats)
		stattotal += get_attribute_level(H, attribute)
	stattotal /= 4 // Average of stats

	// Determine maximum usable rank
	var/best_rank = 0
	for(var/i = 1 to 5)
		if(stattotal >= rankAttributeReqs[i])
			best_rank = i
		else
			break

	// Display results
	to_chat(user, span_notice("Stat Analysis:"))
	to_chat(user, span_notice("- Average stat level: [stattotal]"))

	if(best_rank < 1)
		to_chat(user, span_warning("The target is unable to use any skill augments (minimum average stat requirement: [rankAttributeReqs[1]])."))
	else
		to_chat(user, span_notice("The target is able to use rank [best_rank] or lower skill augments."))
		if(best_rank < 5)
			to_chat(user, span_notice("For rank [best_rank + 1], they need an average of [rankAttributeReqs[best_rank + 1]] stats (currently: [stattotal])."))

/obj/item/skill_augment_tester/examine(mob/user)
	. = ..()
	. += span_notice("Use on a human to check their skill augment compatibility.")
	. += span_notice("Skill augment stat requirements:")
	for(var/i = 1 to 5)
		. += span_notice("- Rank [i]: Average stats ≥ [rankAttributeReqs[i]]")

//--------------------------------------
// Skill Augment Battery Items
//--------------------------------------

/obj/item/skill_augment_battery
	name = "skill augment battery"
	desc = "A specialized energy cell designed to recharge skill augments."
	icon = 'icons/obj/power.dmi'
	icon_state = "cell"
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS
	custom_price = 200
	var/charge_amount = 50
	var/tier = 1

/obj/item/skill_augment_battery/examine(mob/user)
	. = ..()
	. += span_notice("This is a Tier [tier] battery that restores [charge_amount] charge.")
	. += span_notice("Use in hand while having a skill augment to recharge it.")

/obj/item/skill_augment_battery/attack_self(mob/user)
	. = ..()
	if(!ishuman(user))
		to_chat(user, span_warning("Only humans can use skill augment batteries."))
		return

	var/mob/living/carbon/human/H = user
	var/obj/item/organ/cyberimp/chest/skill_augment/SA = H.getorganslot(ORGAN_SLOT_HEART_AID)

	if(!SA || !istype(SA, /obj/item/organ/cyberimp/chest/skill_augment))
		to_chat(user, span_warning("You don't have a skill augment installed!"))
		return

	if(SA.current_charge >= SA.max_charge)
		to_chat(user, span_notice("Your skill augment is already fully charged! ([SA.current_charge]/[SA.max_charge])"))
		return

	to_chat(user, span_notice("You begin connecting the battery to your skill augment..."))

	if(!do_after(user, 3 SECONDS, target = user))
		to_chat(user, span_warning("You stop the charging process."))
		return

	var/charge_to_add = min(charge_amount, SA.max_charge - SA.current_charge)
	SA.current_charge += charge_to_add

	to_chat(user, span_notice("You successfully charge your skill augment! (+[charge_to_add] charge, now [SA.current_charge]/[SA.max_charge])"))
	playsound(get_turf(user), 'sound/machines/ping.ogg', 50, FALSE)

	qdel(src)

/obj/item/skill_augment_battery/tier2
	name = "skill augment battery MK-II"
	desc = "An improved energy cell with higher capacity for skill augments."
	icon_state = "hcell"
	custom_price = 400
	charge_amount = 100
	tier = 2

/obj/item/skill_augment_battery/tier3
	name = "skill augment battery MK-III"
	desc = "An advanced energy cell with substantial charging capacity."
	icon_state = "icell"
	custom_price = 600
	charge_amount = 200
	tier = 3

/obj/item/skill_augment_battery/tier4
	name = "skill augment battery MK-IV"
	desc = "A top-tier energy cell capable of major charge restoration."
	icon_state = "bscell"
	custom_price = 800
	charge_amount = 300
	tier = 4

//--------------------------------------
// Injectable Skill Augment Items
//--------------------------------------

/obj/item/skill_augment_injectable
	name = "injectable skill augment"
	desc = "An injectable skill augmentation that can be administered by hitting a target."
	icon = 'icons/obj/syringe.dmi'
	icon_state = "maintenance"
	w_class = WEIGHT_CLASS_SMALL
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS

	var/rank = 1
	var/max_slots = 1
	var/max_charge = 40
	var/current_charge = 40
	var/list/attached_skills = list()
	var/list/skill_charge_costs = list()
	var/used = FALSE

	// Stat requirements
	var/list/rankAttributeReqs = list(20, 40, 60, 80, 100)
	var/list/stats = list(
		FORTITUDE_ATTRIBUTE,
		PRUDENCE_ATTRIBUTE,
		TEMPERANCE_ATTRIBUTE,
		JUSTICE_ATTRIBUTE
	)
	var/list/allowed_roles = list("Prosthetics Surgeon", "Office Director", "Office Fixer", "Doctor", "Fixer")

/obj/item/skill_augment_injectable/examine(mob/user)
	. = ..()
	if(used)
		. += span_warning("This augment has already been used.")
		return
	. += span_notice("Rank: [rank]")
	. += span_notice("Slots: [max_slots]")
	. += span_notice("Max Charge: [max_charge]")
	. += span_notice("Attached Skills: [length(attached_skills)]")
	for(var/skill_type in attached_skills)
		var/datum/action/A = skill_type
		. += span_notice("- [initial(A.name)]")
	. += span_notice("Use on a human to inject this skill augment.")

/obj/item/skill_augment_injectable/attack(mob/target, mob/user)
	. = ..()
	if(used)
		to_chat(user, span_warning("[src] has already been used!"))
		return

	if(!can_use_injector(user))
		to_chat(user, span_warning("You don't have the expertise to use this injector!"))
		return

	if(!ishuman(target))
		to_chat(user, span_warning("You can only use this on humans!"))
		return

	var/mob/living/carbon/human/H = target

	// Check if target already has a skill augment
	var/obj/item/organ/cyberimp/chest/skill_augment/existing_SA = H.getorganslot(ORGAN_SLOT_HEART_AID)
	var/obj/item/skill_augment_injectable/existing_inj = null

	// Check for existing injectable augments in inventory
	for(var/obj/item/skill_augment_injectable/inj in H.contents)
		if(inj.used)
			existing_inj = inj
			break

	if(existing_SA && istype(existing_SA, /obj/item/organ/cyberimp/chest/skill_augment))
		to_chat(user, span_warning("[H] already has a skill augment installed!"))
		return

	if(existing_inj)
		to_chat(user, span_warning("[H] already has an injectable skill augment!"))
		return

	// Check stat requirements
	var/stattotal = 0
	for(var/attribute in stats)
		stattotal += get_attribute_level(H, attribute)
	stattotal /= 4 // Average of stats

	if(stattotal < rankAttributeReqs[rank])
		to_chat(user, span_warning("[H]'s stats are too low for this Rank [rank] augment! (Required: [rankAttributeReqs[rank]], Current: [stattotal])"))
		return

	to_chat(user, span_notice("You begin injecting [src] into [H]..."))

	if(!do_after(user, 3 SECONDS, target = H))
		to_chat(user, span_warning("You stop the injection process."))
		return

	// Move the augment into the target and mark as used
	forceMove(H)
	used = TRUE

	// Grant all attached skills
	for(var/skill_type in attached_skills)
		var/datum/action/A = new skill_type()
		A.Grant(H)

		// Hook into the action's Trigger to consume charge
		if(istype(A, /datum/action/cooldown))
			var/datum/action/cooldown/CA = A
			RegisterSignal(CA, COMSIG_ACTION_TRIGGER, PROC_REF(on_skill_used))

	to_chat(user, span_notice("You successfully inject [src] into [H]!"))
	to_chat(H, span_notice("You feel new abilities coursing through your body!"))
	playsound(get_turf(H), 'sound/items/syringeproj.ogg', 50, FALSE)

/obj/item/skill_augment_injectable/proc/can_use_injector(mob/user)
	if(!user?.mind?.assigned_role)
		return FALSE
	return (user.mind.assigned_role in allowed_roles)

/obj/item/skill_augment_injectable/proc/on_skill_used(datum/action/source)
	SIGNAL_HANDLER

	// Get charge cost
	var/cost = skill_charge_costs[source.type] || 10

	// Check charge - if insufficient, deal BURN damage instead of blocking
	if(current_charge < cost)
		var/shortfall = cost - current_charge
		var/burn_damage = shortfall * 2 // 2 BURN damage per missing charge point

		if(ishuman(loc))
			var/mob/living/carbon/human/H = loc
			H.deal_damage(burn_damage, FIRE)
			to_chat(H, span_boldwarning("CRITICAL AUGMENT OVERLOAD! Your skill augment tears at your skin!"))

			// Dramatic visual effect
			playsound(get_turf(H), 'sound/weapons/ego/devyat_overclock.ogg', 25, 0, 4)

		// Still consume what charge we have
		current_charge = 0
		if(ishuman(loc))
			to_chat(loc, span_danger("Augment charge: [current_charge]/[max_charge] - DEPLETED!"))
		return

	// Normal operation - consume charge
	current_charge -= cost
	if(ishuman(loc))
		to_chat(loc, span_notice("Augment charge: [current_charge]/[max_charge]"))

		// Low charge warning
		if(current_charge < max_charge * 0.2)
			to_chat(loc, span_warning("Augment charge critical!"))

//--------------------------------------
// Skill Augment Remover Tool
//--------------------------------------

/obj/item/skill_augment_remover
	name = "Skill Augment Remover"
	desc = "A specialized tool that can remove skill augments from targets."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "gadget1"
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_SMALL
	var/list/allowed_roles = list("Prosthetics Surgeon", "Office Director", "Office Fixer", "Doctor", "Fixer")

/obj/item/skill_augment_remover/examine(mob/user)
	. = ..()
	. += span_notice("Use on a human to remove skill augments.")
	. += span_notice("Can remove both implanted and injectable skill augments.")

/obj/item/skill_augment_remover/attack(mob/target, mob/user)
	. = ..()
	if(!can_use_remover(user))
		to_chat(user, span_warning("You don't have the expertise to use this tool!"))
		return

	if(!ishuman(target))
		to_chat(user, span_warning("You can only use this on humans!"))
		return

	var/mob/living/carbon/human/H = target

	// Check for implanted skill augment
	var/obj/item/organ/cyberimp/chest/skill_augment/SA = H.getorganslot(ORGAN_SLOT_HEART_AID)
	if(SA && istype(SA, /obj/item/organ/cyberimp/chest/skill_augment))
		to_chat(user, span_notice("You begin removing the implanted skill augment from [H]..."))

		if(!do_after(user, 5 SECONDS, target = H))
			to_chat(user, span_warning("You stop the removal process."))
			return

		// Remove all granted skills
		for(var/datum/action/A in SA.granted_actions)
			UnregisterSignal(A, COMSIG_ACTION_TRIGGER)
			A.Remove(H)
			qdel(A)
		SA.granted_actions.Cut()

		// Remove the organ and place it on the ground
		SA.Remove(H)
		SA.forceMove(get_turf(H))

		to_chat(user, span_notice("You successfully remove the implanted skill augment from [H]!"))
		to_chat(H, span_warning("You feel your augmented abilities fading away."))
		playsound(get_turf(H), 'sound/items/deconstruct.ogg', 50, FALSE)
		return

	// Check for injectable skill augment
	for(var/obj/item/skill_augment_injectable/inj in H.contents)
		if(inj.used)
			to_chat(user, span_notice("You begin removing the injectable skill augment from [H]..."))

			if(!do_after(user, 3 SECONDS, target = H))
				to_chat(user, span_warning("You stop the removal process."))
				return

			// Remove all skills granted by this injectable
			for(var/skill_type in inj.attached_skills)
				for(var/datum/action/A in H.actions)
					if(A.type == skill_type)
						UnregisterSignal(A, COMSIG_ACTION_TRIGGER)
						A.Remove(H)
						qdel(A)
						break

			// Remove the injectable and place it on the ground
			inj.forceMove(get_turf(H))
			inj.used = FALSE

			to_chat(user, span_notice("You successfully remove the injectable skill augment from [H]!"))
			to_chat(H, span_warning("You feel your augmented abilities fading away."))
			playsound(get_turf(H), 'sound/items/syringeproj.ogg', 50, FALSE)
			return

	to_chat(user, span_warning("[H] doesn't have any skill augments to remove!"))

/obj/item/skill_augment_remover/proc/can_use_remover(mob/user)
	if(!user?.mind?.assigned_role)
		return FALSE
	return (user.mind.assigned_role in allowed_roles)
