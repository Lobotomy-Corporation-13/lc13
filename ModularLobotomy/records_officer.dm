// Records Officer Agent Preservation Tool
// A handheld device that can store one agent's data and revive them once after death

/obj/item/agent_preservation_tool
	name = "agent preservation watch"
	desc = "A high-tech handheld watch that can store a digital backup of an agent's biological data. Can restore them after death with temporary attribute penalties. Single use per person."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "watch_copper"
	w_class = WEIGHT_CLASS_SMALL
	var/list/stored_agent_data = list()
	var/list/used_ckeys = list() // Track who has been revived
	var/scan_cooldown = 0
	var/scan_cooldown_time = 3 SECONDS
	var/revival_justice_penalty = -100
	var/revival_penalty_duration = 300 // 5 minutes in seconds
	var/is_loaded = FALSE

/obj/item/agent_preservation_tool/examine(mob/user)
	. = ..()
	if(is_loaded)
		. += span_notice("Device is loaded with agent data for: [stored_agent_data["real_name"]]")
		if(stored_agent_data["ckey"] in used_ckeys)
			. += span_warning("This agent has already been revived once and cannot be revived again.")
	else
		. += span_notice("Device is empty. Use on a living agent to store their data.")

/obj/item/agent_preservation_tool/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag)
		return

	if(!ishuman(target))
		return

	// Check if user is Records Officer
	if(!ishuman(user))
		to_chat(user, span_warning("Only the Records Officer can use this device!"))
		return

	var/mob/living/carbon/human/user_human = user
	if(user_human.mind?.assigned_role != "Records Officer")
		to_chat(user, span_warning("Only the Records Officer can use this device!"))
		return

	var/mob/living/carbon/human/H = target

	// Check if target is an agent (allow mindless for debugging)
	if(H.mind && !(H.mind.assigned_role in list("Agent", "Senior Agent", "Captain", "Lieutenant", "Officer", "Clerk")))
		to_chat(user, span_warning("This device only works on L-Corp agents!"))
		return

	// Check if target is alive
	if(H.stat == DEAD)
		to_chat(user, span_warning("Cannot scan dead agents!"))
		return

	// Check cooldown
	if(world.time < scan_cooldown)
		to_chat(user, span_warning("Device is recharging... ([round((scan_cooldown - world.time)/10)] seconds remaining)"))
		return

	// Check if already loaded
	if(is_loaded)
		to_chat(user, span_warning("Device already contains agent data! Clear it first or use it to check status."))
		return

	// Scan the agent
	scan_agent(H, user)

/obj/item/agent_preservation_tool/proc/scan_agent(mob/living/carbon/human/H, mob/user)
	if(!H)
		return FALSE

	to_chat(user, span_notice("Scanning [H.real_name]..."))
	playsound(src, 'sound/machines/beep.ogg', 50, TRUE)

	// Store agent data
	stored_agent_data = list()
	stored_agent_data["ref"] = REF(H)
	stored_agent_data["ckey"] = H.ckey
	stored_agent_data["real_name"] = H.real_name
	stored_agent_data["species"] = H.dna.species.type
	stored_agent_data["gender"] = H.gender
	stored_agent_data["assigned_role"] = H.mind?.assigned_role || "Agent"
	stored_agent_data["underwear"] = H.underwear
	stored_agent_data["underwear_color"] = H.underwear_color

	// Store DNA
	var/datum/dna/D = new /datum/dna
	H.dna.copy_dna(D)
	stored_agent_data["dna"] = D

	// Store attributes
	var/list/attributes = list()
	for(var/type in GLOB.attribute_types)
		if(ispath(type, /datum/attribute))
			var/datum/attribute/atr = new type
			attributes[atr.name] = atr
			var/datum/attribute/old_atr = H.attributes[atr.name]
			atr.level = old_atr.level
	stored_agent_data["attributes"] = attributes

	// Store skills
	stored_agent_data["skills"] = serialize_skills(H.mind?.known_skills)

	// Store actions
	var/list/action_types = list()
	for(var/datum/action/A in H.actions)
		if(istype(A, /datum/action/item_action))
			continue
		if(istype(A, /datum/action/spell_action))
			continue
		action_types += A.type
	stored_agent_data["action_types"] = action_types

	is_loaded = TRUE
	scan_cooldown = world.time + scan_cooldown_time

	to_chat(user, span_notice("Agent data stored successfully!"))
	to_chat(H, span_notice("Your biological data has been backed up to [user]'s preservation device."))

	// Visual effect
	H.visible_message(span_notice("[H] glows briefly as their data is scanned."))

	return TRUE

/obj/item/agent_preservation_tool/attack_self(mob/user)
	. = ..()

	// Check if user is Records Officer
	if(!ishuman(user))
		to_chat(user, span_warning("Only the Records Officer can use this device!"))
		return

	var/mob/living/carbon/human/user_human = user
	if(user_human.mind?.assigned_role != "Records Officer")
		to_chat(user, span_warning("Only the Records Officer can use this device!"))
		return

	if(!is_loaded)
		to_chat(user, span_warning("No agent data stored. Use on a living agent to scan them."))
		return

	// Check agent status
	var/agent_name = stored_agent_data["real_name"]
	var/agent_ckey = stored_agent_data["ckey"]
	var/mob/living/carbon/human/original = locate(stored_agent_data["ref"])

	var/dat = "<b>Agent Preservation Device</b><br>"
	dat += "<hr>"
	dat += "<b>Stored Agent:</b> [agent_name]<br>"
	dat += "<b>Status:</b> "

	if(original && original.stat != DEAD)
		dat += "<span style='color:green'>ALIVE</span><br>"
		dat += "<i>Agent is still alive. Revival not available.</i><br>"
	else
		dat += "<span style='color:red'>DECEASED</span><br>"
		if(agent_ckey in used_ckeys)
			dat += "<span style='color:orange'><b>This agent has already been revived once.</b></span><br>"
			dat += "<i>Cannot revive the same person twice.</i><br>"
		else
			dat += "<a href='byond://?src=[REF(src)];revive=1'>INITIATE REVIVAL PROTOCOL</a><br>"
			dat += "<i>Warning: Agent will have -100 Justice for 5 minutes after revival.</i><br>"

	dat += "<hr>"
	dat += "<a href='byond://?src=[REF(src)];clear=1'>Clear Stored Data</a><br>"

	var/datum/browser/popup = new(user, "preservation_device", "Agent Preservation Device", 400, 300)
	popup.set_content(dat)
	popup.open()

/obj/item/agent_preservation_tool/Topic(href, href_list)
	if(..())
		return

	// Check if user is Records Officer
	if(!ishuman(usr))
		to_chat(usr, span_warning("Only the Records Officer can use this device!"))
		return

	var/mob/living/carbon/human/user_human = usr
	if(user_human.mind?.assigned_role != "Records Officer")
		to_chat(usr, span_warning("Only the Records Officer can use this device!"))
		return

	if(href_list["revive"])
		if(!is_loaded)
			return

		var/agent_ckey = stored_agent_data["ckey"]
		if(agent_ckey in used_ckeys)
			to_chat(usr, span_warning("This agent has already been revived once!"))
			return

		// Find ghost
		var/mob/dead/observer/ghost = find_agent_ghost(stored_agent_data["real_name"], agent_ckey)
		if(!ghost)
			to_chat(usr, span_warning("Cannot find agent's spirit. They may have respawned elsewhere or disconnected."))
			return

		var/response = alert(ghost, "Do you want to be revived by the Agent Preservation Device? You will have -100 Justice for 5 minutes.", "Revival Offer", "Yes", "No")
		if(response == "Yes")
			revive_agent(usr)

	if(href_list["clear"])
		stored_agent_data = list()
		is_loaded = FALSE
		to_chat(usr, span_notice("Agent data cleared."))

	updateUsrDialog()

/obj/item/agent_preservation_tool/proc/find_agent_ghost(real_name, ckey)
	for(var/mob/dead/observer/O in GLOB.dead_mob_list)
		if(O.real_name == real_name || O.ckey == ckey)
			return O
	return null

/obj/item/agent_preservation_tool/proc/revive_agent(mob/user)
	if(!is_loaded || !stored_agent_data)
		return FALSE

	var/agent_ckey = stored_agent_data["ckey"]

	// Double check they haven't been revived
	if(agent_ckey in used_ckeys)
		to_chat(user, span_warning("This agent has already been revived!"))
		return FALSE

	// Find the ghost again
	var/mob/dead/observer/ghost = find_agent_ghost(stored_agent_data["real_name"], agent_ckey)
	if(!ghost || !ghost.client)
		to_chat(user, span_warning("Agent's spirit is not available!"))
		return FALSE

	to_chat(user, span_notice("Initiating revival protocol..."))
	playsound(src, 'sound/effects/phasein.ogg', 50, TRUE)

	// Create new body at tool location
	var/mob/living/carbon/human/new_body = new(get_turf(src))

	// Set up identity
	new_body.real_name = stored_agent_data["real_name"]
	new_body.gender = stored_agent_data["gender"]

	// Transfer DNA
	if(istype(stored_agent_data["dna"], /datum/dna))
		var/datum/dna/stored_dna = stored_agent_data["dna"]
		stored_dna.transfer_identity(new_body)

	// Set species
	var/species_type = stored_agent_data["species"]
	if(ispath(species_type, /datum/species))
		new_body.set_species(species_type)

	// Set attributes
	var/list/stored_attributes = stored_agent_data["attributes"]
	if(islist(stored_attributes))
		new_body.attributes = stored_attributes

	// Set appearance
	if(stored_agent_data["underwear"])
		new_body.underwear = stored_agent_data["underwear"]
	if(stored_agent_data["underwear_color"])
		new_body.underwear_color = stored_agent_data["underwear_color"]

	// Revive and transfer player
	new_body.revive(full_heal = TRUE, admin_revive = FALSE)
	new_body.updateappearance()
	new_body.ckey = ghost.ckey

	// Restore role
	if(stored_agent_data["assigned_role"])
		new_body.mind.assigned_role = stored_agent_data["assigned_role"]
		// Equip appropriate outfit based on role
		switch(stored_agent_data["assigned_role"])
			if("Agent")
				new_body.equipOutfit(/datum/outfit/job/agent)
			if("Clerk")
				new_body.equipOutfit(/datum/outfit/job/staff)
			if("Captain")
				new_body.equipOutfit(/datum/outfit/job/agent/captain)
			if("Lieutenant")
				new_body.equipOutfit(/datum/outfit/job/agent)
			else
				new_body.equipOutfit(/datum/outfit/job/agent) // Default to agent

	// Restore skills
	if(stored_agent_data["skills"])
		new_body.mind.known_skills = deserialize_skills(stored_agent_data["skills"])

	// Restore actions
	var/list/stored_action_types = stored_agent_data["action_types"]
	if(islist(stored_action_types))
		for(var/T in stored_action_types)
			var/datum/action/G = new T()
			G.Grant(new_body)

	// Apply justice penalty as buff (negative buff = debuff)
	new_body.adjust_attribute_bonus(JUSTICE_ATTRIBUTE, revival_justice_penalty)

	// Add component to track and restore the penalty
	new_body.AddComponent(/datum/component/temporary_justice_penalty, revival_justice_penalty, revival_penalty_duration)

	// Mark this ckey as used
	used_ckeys += agent_ckey

	// Clear stored data
	stored_agent_data = list()
	is_loaded = FALSE

	// Effects and messages
	new_body.visible_message(span_notice("[new_body] materializes in a flash of light!"))
	to_chat(new_body, span_userdanger("You have been revived by an Agent Preservation Device!"))
	to_chat(new_body, span_warning("Your Justice attribute has been severely reduced for the next 5 minutes!"))
	to_chat(user, span_notice("Revival successful! Device memory cleared."))

	playsound(get_turf(new_body), 'sound/effects/hokma_meltdown.ogg', 50, TRUE)

	return TRUE

// Helper procs for skills serialization
/obj/item/agent_preservation_tool/proc/serialize_skills(list/known_skills)
	var/list/serializable = list()
	for(var/datum/skill/S as anything in known_skills)
		serializable["[S.type]"] = known_skills[S]
	return json_encode(serializable)

/obj/item/agent_preservation_tool/proc/deserialize_skills(text)
	var/list/known_skills = list()
	var/list/decoded = json_decode(text)
	for(var/type_text in decoded)
		var/skill_type = text2path(type_text)
		if(!ispath(skill_type, /datum/skill))
			continue
		known_skills[skill_type] = decoded[type_text]
	return known_skills

// Temporary Justice Penalty Component
/datum/component/temporary_justice_penalty
	var/penalty_amount
	var/end_time

/datum/component/temporary_justice_penalty/Initialize(penalty, duration)
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE

	var/mob/living/carbon/human/H = parent
	penalty_amount = penalty
	end_time = world.time + (duration * 10) // Convert seconds to deciseconds

	// Set up restoration timer
	addtimer(CALLBACK(src, PROC_REF(restore_justice)), duration * 10)

	RegisterSignal(H, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))

/datum/component/temporary_justice_penalty/proc/restore_justice()
	var/mob/living/carbon/human/H = parent
	if(!H || QDELETED(H))
		qdel(src)
		return

	// Remove the penalty buff (negative of negative = positive)
	H.adjust_attribute_bonus(JUSTICE_ATTRIBUTE, -penalty_amount)
	to_chat(H, span_nicegreen("Your Justice attribute has been restored!"))

	qdel(src)

/datum/component/temporary_justice_penalty/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	var/time_left = round((end_time - world.time) / 10)
	if(time_left > 0)
		examine_list += span_warning("They appear weakened! (Justice penalty: [time_left] seconds remaining)")

/datum/component/temporary_justice_penalty/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_PARENT_EXAMINE)
	return ..()
