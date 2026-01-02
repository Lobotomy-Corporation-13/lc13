//--------------------------------------
// Body Modification Fabricator System
//--------------------------------------

// Design datum for temporary storage during fabrication
/datum/body_modification_design
	var/rank = 1
	var/max_slots = 1
	var/max_charge = 40
	var/list/selected_skills = list()
	var/total_slot_cost = 0
	var/material_cost = 0
	var/name = "Body Modification"

//--------------------------------------
// The Body Modification Fabricator Machine
//--------------------------------------

/obj/machinery/body_modification_fabricator
	name = "Body Modification Fabricator"
	desc = "A specialized machine for creating skill-enhanced cybernetic body modifications."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "circuit_imprinter"
	anchored = TRUE
	density = TRUE

	var/busy = FALSE
	var/fabrication_time = 4 SECONDS

	// Material storage
	var/total_materials = 0

	// Current design being worked on
	var/datum/body_modification_design/current_design

	// Role restrictions
	var/list/allowed_roles = list("Prosthetics Surgeon", "Office Director", "Office Fixer", "Doctor", "Fixer", "Workshop Attendant")

	// Available templates based on rank
	var/list/available_templates = list(
		"Rank 1 - Basic" = list(
			"rank" = 1,
			"slots" = 4,
			"charge" = 180,
			"material_cost" = 25
		),
		"Rank 2 - Enhanced" = list(
			"rank" = 2,
			"slots" = 6,
			"charge" = 300,
			"material_cost" = 50
		),
		"Rank 3 - Advanced" = list(
			"rank" = 3,
			"slots" = 6,
			"charge" = 480,
			"material_cost" = 75
		),
		"Rank 4 - Superior" = list(
			"rank" = 4,
			"slots" = 8,
			"charge" = 750,
			"material_cost" = 100
		),
		"Rank 5 - Masterwork" = list(
			"rank" = 5,
			"slots" = 9,
			"charge" = 1050,
			"material_cost" = 150
		),

		// Injectable Templates (50% reduced charge)
		"Injectable Rank 1 - Basic" = list(
			"rank" = 1,
			"slots" = 4,
			"charge" = 90,
			"injectable" = TRUE,
			"material_cost" = 20
		),
		"Injectable Rank 2 - Enhanced" = list(
			"rank" = 2,
			"slots" = 6,
			"charge" = 150,
			"injectable" = TRUE,
			"material_cost" = 40
		),
		"Injectable Rank 3 - Advanced" = list(
			"rank" = 3,
			"slots" = 6,
			"charge" = 240,
			"injectable" = TRUE,
			"material_cost" = 60
		),
		"Injectable Rank 4 - Superior" = list(
			"rank" = 4,
			"slots" = 8,
			"charge" = 380,
			"injectable" = TRUE,
			"material_cost" = 80
		),
		"Injectable Rank 5 - Masterwork" = list(
			"rank" = 5,
			"slots" = 9,
			"charge" = 530,
			"injectable" = TRUE,
			"material_cost" = 120
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
			"desc" = "Creates 4 flashing light zones that explode after 2 seconds, dealing WHITE damage and blinding humans"
		),
		/datum/action/cooldown/confusion = list(
			"name" = "Confusion",
			"slot_cost" = 2,
			"charge_cost" = 35,
			"skill_level" = 2,
			"desc" = "After 1 second green glow, affects targets looking at you: confuses humans, damages simple mobs, reduces damage by 40%"
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
			"desc" = "Become invisible for 10 seconds, but you are pacified for 12 seconds"
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
		// /datum/action/cooldown/timestop = list(
		// 	"name" = "Timestop",
		// 	"slot_cost" = 5,
		// 	"charge_cost" = 100,
		// 	"skill_level" = 4,
		// 	"desc" = "Stop time in a range of 2 tiles, for 2 seconds."
		// ),
		// /datum/action/cooldown/dismember = list(
		// 	"name" = "Execute",
		// 	"slot_cost" = 4,
		// 	"charge_cost" = 80,
		// 	"skill_level" = 4,
		// 	"desc" = "Execute adjacent targets below 25% HP. Dismembers arms from humans, gibs simple animals"
		// ),
		// /datum/action/cooldown/shockwave = list(
		// 	"name" = "Shockwave",
		// 	"slot_cost" = 4,
		// 	"charge_cost" = 80,
		// 	"skill_level" = 4,
		// 	"desc" = "Knock everything in a radius back"
		// ),
		// /datum/action/cooldown/warbanner = list(
		// 	"name" = "Warbanner",
		// 	"slot_cost" = 3,
		// 	"charge_cost" = 70,
		// 	"skill_level" = 4,
		// 	"desc" = "All humans in a 3 tile radius gain a 70% damage reduction for 10 seconds."
		// ),
		// /datum/action/cooldown/warcry = list(
		// 	"name" = "Warcry",
		// 	"slot_cost" = 3,
		// 	"charge_cost" = 50,
		// 	"skill_level" = 4,
		// 	"desc" = "All humans in a 3 tile radius move 50% faster for 10 seconds."
		// ),
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

/obj/machinery/body_modification_fabricator/proc/get_skill_data()
	return skill_data

/obj/machinery/body_modification_fabricator/Initialize()
	. = ..()
	current_design = new /datum/body_modification_design()

/obj/machinery/body_modification_fabricator/Destroy()
	QDEL_NULL(current_design)
	return ..()

/obj/machinery/body_modification_fabricator/attackby(obj/item/I, mob/user)
	if(busy)
		to_chat(user, span_warning("[src] is currently busy!"))
		return TRUE

	// Handle skill modification ticket processing
	if(istype(I, /obj/item/body_modification_ticket))
		var/obj/item/body_modification_ticket/ticket = I

		// Check if user has authorization
		if(!can_use_machine(user))
			to_chat(user, span_warning("You don't have the expertise to process modification tickets!"))
			return TRUE

		// Check if ticket is valid
		if(!ticket.template_name || !length(ticket.selected_skills))
			to_chat(user, span_warning("This ticket appears to be invalid or incomplete!"))
			return TRUE

		// Check if we have enough materials
		if(total_materials < ticket.material_cost)
			to_chat(user, span_warning("Insufficient materials! Need [ticket.material_cost], have [total_materials]."))
			return TRUE

		// Process the ticket
		process_modification_ticket(ticket, user)
		return TRUE

	// Handle material insertion
	if(istype(I, /obj/item/tresmetal))
		var/obj/item/tresmetal/T = I

		// Add material density to total materials
		total_materials += T.mat_density

		to_chat(user, span_notice("You insert [T] into [src]. (+[T.mat_density] materials, Total: [total_materials])"))
		playsound(src, 'sound/machines/click.ogg', 50, TRUE)
		qdel(T)
		update_icon()
		SStgui.update_uis(src)
		return TRUE

	return ..()

/obj/machinery/body_modification_fabricator/attack_hand(mob/user)
	. = ..()
	if(!can_use_machine(user))
		to_chat(user, span_warning("You don't have the expertise to use this machine!"))
		return

	ui_interact(user)

/obj/machinery/body_modification_fabricator/proc/can_use_machine(mob/user)
	if(!user?.mind?.assigned_role)
		return FALSE
	return (user.mind.assigned_role in allowed_roles)

/obj/machinery/body_modification_fabricator/ui_interact(mob/user, datum/tgui/ui)
	if(!can_use_machine(user))
		to_chat(user, span_warning("You don't have the expertise to use this machine!"))
		return

	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SkillAugmentFabricator")
		ui.open()

/obj/machinery/body_modification_fabricator/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/body_modification_fabricator/ui_data(mob/user)
	if(!can_use_machine(user))
		return list()

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

	// Stored materials (single total value now)
	data["total_materials"] = total_materials

	data["busy"] = busy

	return data

/obj/machinery/body_modification_fabricator/ui_act(action, params)
	. = ..()
	if(.)
		return

	if(!can_use_machine(usr))
		return FALSE

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
			current_design = new /datum/body_modification_design()
			return TRUE

/obj/machinery/body_modification_fabricator/proc/can_afford_template(list/template)
	return (total_materials >= template["material_cost"])

/obj/machinery/body_modification_fabricator/proc/get_material_cost_display(cost)
	return "[cost] material"

/obj/machinery/body_modification_fabricator/proc/process_modification_ticket(obj/item/body_modification_ticket/ticket, mob/user)
	if(busy)
		to_chat(user, span_warning("[src] is already processing something!"))
		return

	// Set up the design from the ticket
	current_design.rank = ticket.rank
	current_design.max_slots = ticket.max_slots
	current_design.max_charge = ticket.max_charge
	current_design.selected_skills = ticket.selected_skills.Copy()
	current_design.material_cost = ticket.material_cost
	current_design.name = ticket.template_name

	// Calculate total slot cost for validation
	var/total_slots = 0
	for(var/skill_type in ticket.selected_skills)
		var/list/skill_info = skill_data[skill_type]
		if(skill_info)
			total_slots += skill_info["slot_cost"]
	current_design.total_slot_cost = total_slots

	to_chat(user, span_notice("Processing modification ticket from [ticket.orderer_name]..."))
	to_chat(user, span_notice("Template: [ticket.template_name] | Skills: [length(ticket.selected_skills)] | Cost: [ticket.material_cost] materials"))

	// Start fabrication
	start_fabrication(user)

	// Delete the ticket
	qdel(ticket)

	// Update UI for any observers
	SStgui.update_uis(src)

/obj/machinery/body_modification_fabricator/proc/start_fabrication(mob/user)
	if(busy)
		return

	busy = TRUE
	playsound(src, 'sound/machines/terminal_processing.ogg', 50, TRUE)
	icon_state = "circuit_imprinter_ani"
	to_chat(user, span_notice("You begin fabricating the skill modification..."))

	// Consume materials
	total_materials -= current_design.material_cost

	addtimer(CALLBACK(src, PROC_REF(finish_fabrication), user), fabrication_time)
	SStgui.update_uis(src)

/obj/machinery/body_modification_fabricator/proc/finish_fabrication(mob/user)
	busy = FALSE
	icon_state = "circuit_imprinter"

	// Check if this is an injectable template
	if(available_templates[current_design.name] && available_templates[current_design.name]["injectable"])
		// Create injectable skill modification item
		var/obj/item/body_modification_injectable/SA = new(get_turf(src))
		SA.rank = current_design.rank
		SA.max_slots = current_design.max_slots
		SA.max_charge = current_design.max_charge
		SA.current_charge = SA.max_charge
		SA.attached_skills = current_design.selected_skills.Copy()
		SA.name = "injectable skill modification (Rank [SA.rank])"
		SA.desc = "An injectable skill modificationation containing [length(SA.attached_skills)] programmed skills. Can be administered by hitting a target."

		// Store skill charge costs
		for(var/skill_type in SA.attached_skills)
			var/list/skill_info = skill_data[skill_type]
			SA.skill_charge_costs[skill_type] = skill_info["charge_cost"]

		playsound(src, 'sound/machines/ping.ogg', 50, FALSE)
		visible_message(span_notice("[src] finishes fabrication of an injectable modification."))
	else
		// Create regular implantable organ
		var/obj/item/organ/cyberimp/chest/body_modification/SA = new(get_turf(src))
		SA.rank = current_design.rank
		SA.max_slots = current_design.max_slots
		SA.max_charge = current_design.max_charge
		SA.current_charge = SA.max_charge
		SA.attached_skills = current_design.selected_skills.Copy()
		SA.name = "skill modification (Rank [SA.rank])"
		SA.desc = "A cybernetic modificationation containing [length(SA.attached_skills)] programmed skills."

		// Store skill charge costs
		for(var/skill_type in SA.attached_skills)
			var/list/skill_info = skill_data[skill_type]
			SA.skill_charge_costs[skill_type] = skill_info["charge_cost"]

		playsound(src, 'sound/machines/ping.ogg', 50, FALSE)
		visible_message(span_notice("[src] finishes fabrication."))

	// Reset design
	current_design = new /datum/body_modification_design()
	SStgui.update_uis(src)
