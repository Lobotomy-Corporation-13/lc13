/obj/machinery/vending/can_be_unfasten_wrench(mob/user, silent)
	. = ..()
	if(!.)
		return FAILED_UNFASTEN

	// Mechanics are in pain right now, as this is the most real thing ever
	to_chat(user, span_warning("Aw dangit, your wrench is for 20 size bolts, but this vendor has size 17 bolts, your wrench keeps slipping!"))
	return FAILED_UNFASTEN

//Links to abnormality consoles when the console spawns
/obj/machinery/containment_panel
	name = "containment panel"
	desc = "A device that logs the location of a abnormality cell when it spawns."
	icon = 'ModularLobotomy/_Lobotomyicons/lc13doorpanels.dmi'
	icon_state = "control"
	density = FALSE
	use_power = 0
	var/obj/machinery/computer/abnormality/linked_console
	var/work
	var/relative_location

/obj/machinery/containment_panel/Initialize()
	. = ..()
	var/turf/closest_department
	for(var/turf/T in GLOB.department_centers)
		if(T.z != z)
			continue
		if(!istype(T.loc, /area/department_main))
			continue
		if(!closest_department)
			closest_department = T
			continue
		if(get_dist(T, src) > get_dist(closest_department, src))
			continue
		closest_department = T
	var/direction = "in an unknown direction"
	var/xdif = closest_department.x - src.x
	var/ydif = closest_department.y - src.y
	if(abs(xdif) > abs(ydif))
		if(xdif < 0)
			direction = "East"
		else
			direction = "West"
	else
		if(ydif < 0)
			direction = "North"
		else
			direction = "South"
	relative_location = "[get_dist(closest_department, src)] meters [direction] from [closest_department.loc.name]."
	icon_state = replacetext("[closest_department.loc.type]", "/area/department_main/", "")

/obj/machinery/containment_panel/proc/console_status(obj/machinery/computer/abnormality/linked_console)
	cut_overlays()
	if(linked_console)
		add_overlay("glow_[icon_state]")
		desc = null

/obj/machinery/containment_panel/proc/console_meltdown()
	cut_overlays()
	desc = "It says Qliphoth Meltdown in progress, agent intervention required."
	if(icon_state == "command")
		add_overlay("glow_[icon_state]_meltdown")
		return
	add_overlay("glow_meltdown")

/obj/machinery/containment_panel/proc/console_working()
	cut_overlays()
	desc = "It says that work is in progress."
	if(icon_state == "command")
		add_overlay("glow_[icon_state]_work_in_progress")
		return
	add_overlay("glow_work_in_progress")

/obj/machinery/containment_panel/proc/AbnormalityInfo()
	if(!linked_console)
		return "ERROR"
	return linked_console.datum_reference.name

/obj/machinery/containment_panel/discipline
	icon_state = "discipline"

/obj/machinery/containment_panel/extraction
	icon_state = "extraction"

/obj/machinery/containment_panel/records
	icon_state = "records"

/obj/machinery/containment_panel/welfare
	icon_state = "welfare"

/obj/machinery/containment_panel/training
	icon_state = "training"

/obj/machinery/containment_panel/information
	icon_state = "information"

/obj/machinery/containment_panel/safety
	icon_state = "safety"

/obj/machinery/containment_panel/command
	icon_state = "command"

/obj/machinery/abnormality_monitor
	name = "facility abnormality list"
	desc = "A screen that shows a list of all currently housed abnormalities and their departments."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "monitor1"
	density = FALSE
	use_power = 0
	var/list/abnormalities = list()

/obj/machinery/abnormality_monitor/Initialize()
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_ABNORMALITY_SPAWN, PROC_REF(UpdateNetwork)) //return a list of the abnormalities

/obj/machinery/abnormality_monitor/examine(mob/user)
	. = ..()
	ui_interact(user)

/obj/machinery/abnormality_monitor/ui_interact(mob/user)
	. = ..()
	if(isliving(user))
		playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
	var/dat
	dat += "<b>FACILITY INFO:</b><br>"
	for(var/i = 1 to abnormalities.len)
		if(!LAZYLEN(abnormalities))
			dat += "[abnormalities[i]]"
		else
			dat += "[abnormalities[i]]"
		dat += "<br>"
	var/datum/browser/popup = new(user, "containment_diagnostics", "Current Containment", 500, 550)
	popup.set_content(dat)
	popup.open()

/obj/machinery/abnormality_monitor/proc/UpdateNetwork()
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(PingFacilityNetwork))

/obj/machinery/abnormality_monitor/proc/PingFacilityNetwork()
	sleep(20) //2 seconds i think. Delay so that the most recently linked containment panel reads its console.
	LAZYCLEARLIST(abnormalities)
	for(var/obj/machinery/containment_panel/C in GLOB.machines)
		if(C.linked_console)
			LAZYADD(abnormalities, "[C.AbnormalityInfo()]: [C.relative_location]")
	sortList(abnormalities)

	/*---------------\
	|Torso Fabricator|
	\---------------*/
#define ANIMATE_FABRICATOR_ACTIVE flick("fab_robot_a", src)
/*
* When someone who has the time to convert tegu cloners
* into ours you can remove this code. -IP
*/
/obj/machinery/body_fabricator
	name = "torso fabricator"
	desc = "A fabricator for constructing humanoid bodies for the bodiless. Place a brain inside and activate! -NO REFUNDS-."
	icon = 'icons/mob/hivebot.dmi'
	icon_state = "fab_robot"
	density = TRUE
	layer = BELOW_OBJ_LAYER
	use_power = NO_POWER_USE
	var/active = FALSE
	var/stored_money = 0
	var/prosthetic_cost = 0
	var/organic_cost = 800
	var/obj/item/organ/brain/slotted_brain

/obj/machinery/body_fabricator/attackby(obj/item/I, mob/user)
	if(istype(I, /obj/item/holochip))
		var/obj/item/holochip/H = I
		var/ahn_amount = H.get_item_credit_value()
		H.spend(ahn_amount)
		AdjustMoney(ahn_amount)
		return

	if(!slotted_brain)
		if(istype(I, /obj/item/bodypart/head))
			var/obj/item/bodypart/head/heed = I
			if(heed.brain)
				SlottedHead(heed)
				return
		if(istype(I, /obj/item/organ/brain))
			var/obj/item/organ/brain/B = I
			SlottedBrain(B)
			return
	..()

/obj/machinery/body_fabricator/ui_interact(mob/user)
	. = ..()
	if(isliving(user))
		playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
	var/dat
	dat += "<b>FABRICATION_FUNDS: [stored_money]</b><br>----------------------<br>"
	if(slotted_brain)
		if(slotted_brain)
			dat += "BRAIN DETECTED|<br>--<br>"
		dat += " <A href='byond://?src=[REF(src)];PRINT_PROSTHETIC=[REF(src)]'>PRINT PROSTHETIC TORSO: [prosthetic_cost] AHN:</A><br>"
		dat += " Areas of the body have been replaced with scrap prosthetics. Clients have claimed to suffer a small attribute decrease.<br>"
		dat += " <A href='byond://?src=[REF(src)];PRINT_ORGANIC=[REF(src)]'>PRINT ORGANIC TORSO: [organic_cost] AHN</A><br>"
		dat += " Through undisclosed means we will print you a new torso with no attribute decay.<br>"
	else
		dat += "<b>NO BRAIN DETECTED|</b><br>--<br>"
	var/datum/browser/popup = new(user, "body_fab", "body fabricator", 500, 550)
	popup.set_content(dat)
	popup.open()
	return

/obj/machinery/body_fabricator/Topic(href, href_list)
	. = ..()
	if(.)
		return .
	if(ishuman(usr))
		usr.set_machine(src)
		add_fingerprint(usr)
		if(href_list["PRINT_PROSTHETIC"])
			if(stored_money < prosthetic_cost)
				return
			ConstructTorso(2)
			AdjustMoney(-prosthetic_cost)
			updateUsrDialog()
			return TRUE
		if(href_list["PRINT_ORGANIC"])
			if(stored_money < organic_cost)
				return
			ConstructTorso(1)
			AdjustMoney(-organic_cost)
			updateUsrDialog()
			return TRUE

/obj/machinery/body_fabricator/proc/AdjustMoney(amount)
	stored_money += amount

/*
* In Library of Ruina there is a fixer that has their body
* damaged by clowns so their coworkers behead them and take
* them to get a new body cloned for them. That is the
* inspiration for the torso fabricator.
*/
/obj/machinery/body_fabricator/proc/SlottedBrain(obj/item/organ/brain/B)
	if(slotted_brain)
		return FALSE
	if(B.brainmob == null)
		return FALSE
	slotted_brain = B
	B.forceMove(src)
	return TRUE

/obj/machinery/body_fabricator/proc/SlottedHead(obj/item/bodypart/head/H)
	if(slotted_brain)
		return FALSE
	if(!H.brain)
		return FALSE
	if(H.brainmob == null)
		return FALSE
	slotted_brain = H.brain
	H.drop_organs()
	slotted_brain.forceMove(src)
	qdel(H)
	return TRUE

/*
* Okay so when your gibbed your head contains your brainmob
* but when your brain is cut out of the head the brain now
* contains the brainmob. The brainmob is the one who has
* the previous owners dna stored in it.
*/
/obj/machinery/body_fabricator/proc/ConstructTorso(biotype = 1)
	playsound(get_turf(src), 'sound/machines/click.ogg', 10, TRUE)
	var/mob/living/carbon/human/H = new /mob/living/carbon/human(src)
	//YOU DIDNT PAY FOR LIMBS
	RemoveAllLimbs(H)

	//DNA TRANSFER GO!!!
	if(slotted_brain)
		var/mob/living/brain/B = locate(/mob/living/brain) in slotted_brain
		var/datum/dna/gibbed_dna = B.stored_dna
		if(gibbed_dna)
			H.real_name = gibbed_dna.real_name
			H.set_species(gibbed_dna.species)
			gibbed_dna.transfer_identity(H)

	//BRAIN INSERTION
	if(slotted_brain)
		slotted_brain.Insert(H)

	//REVIVE
	H.revive(full_heal = FALSE, admin_revive = FALSE)
	H.emote("gasp")
	H.Jitter(100)

	var/list/job_traits = list(TRAIT_WORK_FORBIDDEN, TRAIT_COMBATFEAR_IMMUNE, TRAIT_ATTRIBUTES_VISION, TRAIT_SANITYIMMUNE)
	for(var/trait in slotted_brain.initial_traits)
		if(trait in job_traits)
			ADD_TRAIT(H, trait, JOB_TRAIT)
	H.adjust_attribute_level(FORTITUDE_ATTRIBUTE, slotted_brain.stored_fortitude)
	H.adjust_attribute_level(PRUDENCE_ATTRIBUTE, slotted_brain.stored_prudence)
	H.adjust_attribute_level(TEMPERANCE_ATTRIBUTE, slotted_brain.stored_temperance)
	H.adjust_attribute_level(JUSTICE_ATTRIBUTE, slotted_brain.stored_justice)

	//YOU DIDNT PAY FOR PREMIUM SO WE ARE MAKING YOUR BODY WORSE
	if(biotype == 2)
		RoboticizeBody(H)
		H.adjust_all_attribute_levels(-5)
	H.updateappearance()
	DumpBody(H)

/obj/machinery/body_fabricator/proc/RoboticizeBody(mob/living/carbon/human/H)
	var/obj/item/bodypart/head/robot/robohead = new /obj/item/bodypart/head/robot(src)
	var/old_head = H.get_bodypart(BODY_ZONE_HEAD)
	robohead.replace_limb(H)
	qdel(old_head)

	var/obj/item/bodypart/chest/robot/robobody = new /obj/item/bodypart/chest/robot(src)
	var/refuse = H.get_bodypart(BODY_ZONE_CHEST)
	robobody.replace_limb(H)
	qdel(refuse)

/obj/machinery/body_fabricator/proc/RemoveAllLimbs(mob/living/carbon/human/H)
	var/static/list/zones = list(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG)
	for(var/zone in zones)
		var/obj/item/bodypart/BP = H.get_bodypart(zone)
		if(BP)
			BP.drop_limb()
			qdel(BP)

/obj/machinery/body_fabricator/proc/DumpBody(mob/living/carbon/human/dude)
	slotted_brain = null
	ANIMATE_FABRICATOR_ACTIVE
	playsound(get_turf(src), 'sound/effects/cashregister.ogg', 35, 3, 3)
	sleep(32)
	playsound(get_turf(src), 'sound/effects/bin_close.ogg', 35, 3, 3)
	playsound(get_turf(src), 'sound/misc/splort.ogg', 35, 3, 3)
	dude.forceMove(get_turf(src))

#undef ANIMATE_FABRICATOR_ACTIVE

// here we add some vars to the brain to hold the attributes/traits of a mob
/obj/item/organ/brain
	var/list/initial_traits = list()
	var/stored_fortitude = 0
	var/stored_prudence = 0
	var/stored_temperance = 0
	var/stored_justice = 0

/obj/item/organ/brain/Remove(mob/living/carbon/C, special = 0, no_id_transfer = FALSE)
	if(C)
		stored_fortitude = get_raw_level(C, FORTITUDE_ATTRIBUTE)
		stored_prudence = get_raw_level(C, PRUDENCE_ATTRIBUTE)
		stored_temperance = get_raw_level(C, TEMPERANCE_ATTRIBUTE)
		stored_justice = get_raw_level(C, JUSTICE_ATTRIBUTE)
	. = ..()

/datum/job/after_spawn(mob/living/H, mob/M, latejoin = FALSE)
	. = ..()
	var/obj/item/organ/brain/B = H.getorganslot(ORGAN_SLOT_BRAIN)
	if(B)
		if(length(B.initial_traits) == 0)
			B.initial_traits = H.status_traits

/*---------------------\
|Body Preservation Unit|
\---------------------*/

/obj/machinery/body_preservation_unit
	name = "body preservation unit"
	desc = "A high-tech machine that can store a digital copy of your body and attributes for a fee. In case of death, it can revive you with a small attribute penalty."
	icon = 'icons/obj/machines/body_preservation.dmi'
	icon_state = "bpu"
	var/icon_state_animation = "bpu_animation"
	density = TRUE
	layer = BELOW_OBJ_LAYER
	use_power = NO_POWER_USE
	var/public_use = FALSE
	var/stored_money = 0
	//var/preservation_fee = 500
	var/revival_attribute_penalty = -6
	var/list/stored_bodies = list()
	var/clone_delay_seconds = 120
	var/cost_multiplier = 5
	resistance_flags = INDESTRUCTIBLE
	max_integrity = 1000000

/obj/machinery/body_preservation_unit/Initialize()
	. = ..()
	if(SSmaptype.maptype == "office")
		public_use = TRUE
		clone_delay_seconds = 60
		revival_attribute_penalty = -4
		cost_multiplier = 2

/obj/machinery/body_preservation_unit/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/holochip))
		var/obj/item/holochip/H = I
		var/ahn_amount = H.get_item_credit_value()
		H.spend(ahn_amount)
		AdjustMoney(ahn_amount)
		to_chat(user, "<span class='notice'>You insert [ahn_amount] AHN into the machine.</span>")
		return
	return ..()

/obj/machinery/body_preservation_unit/proc/AdjustMoney(amount)
	stored_money += amount

/obj/machinery/body_preservation_unit/proc/calculate_fee(mob/living/carbon/human/H)
	var/preservation_fee = 0

	for(var/atr_type in H.attributes)
		var/datum/attribute/atr = H.attributes[atr_type]
		preservation_fee += atr.level * cost_multiplier

	return preservation_fee


/obj/machinery/body_preservation_unit/ui_interact(mob/user)
	. = ..()

	var/dat
	dat += "<b>Body Preservation Unit</b><br>"
	dat += "<b>FUNDS: [stored_money]</b><br>----------------------<br>"

	if (!public_use && !(user?.mind?.assigned_role in list("Civilian")))
		dat += "<b>Only civilians can use this machine</b><br>"
	else
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			var/preservation_fee = calculate_fee(H)

			dat += "Preservation Fee: [preservation_fee] AHN<br>"
			dat += "<hr>"


			if(stored_bodies[H.real_name])
				dat += "<a href='byond://?src=[REF(src)];preserve=[REF(H)]'>Update body scan ([preservation_fee] AHN)</a><br>"
			else
				dat += "<a href='byond://?src=[REF(src)];preserve=[REF(H)]'>Create body scan ([preservation_fee] AHN)</a><br>"

		if (isobserver(user))
			dat += "<hr>"

			var/mob/dead/observer/O = user
			var/list/stored_data = stored_bodies[O.real_name]
			if(stored_data)
				var/tod = stored_data["time_of_death"]
				var/sec_since_death = (world.time - tod)/10
				if (sec_since_death < clone_delay_seconds)
					dat += "<span>Seconds to cloning remaining: [clone_delay_seconds - sec_since_death]<br>"
				else
					dat += "<a href='byond://?src=[REF(src)];revive=[O.real_name]'>Revive Stored Body</a><br>"

	var/datum/browser/popup = new(user, "body_preservation", "Body Preservation Unit", 300, 300)
	popup.set_content(dat)
	popup.open()

/obj/machinery/body_preservation_unit/Topic(href, href_list)
	if(..() && !isobserver(usr))
		return

	if(href_list["preserve"])
		var/mob/living/carbon/human/H = locate(href_list["preserve"])
		if(H && ishuman(H))
			var/preservation_fee = calculate_fee(H)
			if(try_payment(preservation_fee, H))
				preserve_body(H)
			else
				to_chat(H, "<span class='notice'>You don't have enough AHN.</span>")

	if(href_list["revive"])
		if (icon_state == icon_state_animation)
			to_chat(usr, "<span class='notice'>BPU busy.</span>")
			return

		var/mob_name = href_list["revive"]
		//var/mob/living/carbon/human/H = locate(stored_bodies[mob_name]["ref"])
		//if(H && ishuman(H))
		//	if(try_payment(revival_fee, H))
		revive_body(mob_name, usr.ckey)

	updateUsrDialog()

/obj/machinery/body_preservation_unit/proc/try_payment(amount, mob/living/carbon/human/H)
	if(stored_money < amount)
		return FALSE
	else
		playsound(get_turf(src), 'sound/effects/cashregister.ogg', 35, 3, 3)
		stored_money -= amount
		return TRUE

/obj/machinery/body_preservation_unit/proc/store_attributes(mob/living/carbon/human/H, list/preserved_data)
	var/list/attributes = list()
	for(var/type in GLOB.attribute_types)
		if(ispath(type, /datum/attribute))
			var/datum/attribute/atr = new type
			attributes[atr.name] = atr
			var/datum/attribute/old_atr = H.attributes[atr.name]
			atr.level = old_atr.level
	preserved_data["attributes"] = attributes

/obj/machinery/body_preservation_unit/proc/store_actions(mob/living/carbon/human/H, list/preserved_data)
	var/list/action_types = list()
	for(var/datum/action/A in H.actions)
		if(istype(A, /datum/action/item_action))
			continue
		if(istype(A, /datum/action/spell_action))
			continue
		action_types += A.type
	preserved_data["action_types"] = action_types

/obj/machinery/body_preservation_unit/proc/store_skills(mob/living/carbon/human/H, list/preserved_data)
	preserved_data["skills"] = serialize_skills(H.mind?.known_skills)

/obj/machinery/body_preservation_unit/proc/serialize_skills(list/known_skills)
	var/list/serializable = list()
	for(var/datum/skill/S as anything in known_skills)
		serializable["[S.type]"] = known_skills[S]
	return json_encode(serializable)

/obj/machinery/body_preservation_unit/proc/deserialize_skills(text)
	var/list/known_skills = list()
	var/list/decoded = json_decode(text)

	for(var/type_text in decoded)
		var/skill_type = text2path(type_text)
		if(!ispath(skill_type, /datum/skill))
			continue
		known_skills[skill_type] = decoded[type_text]

	return known_skills

/obj/machinery/body_preservation_unit/proc/preserve_body(mob/living/carbon/human/H)
	if(!H || !H.mind)
		return
	var/datum/mind/M = H.mind
	var/list/preserved_data = list()
	preserved_data["ref"] = REF(H)
	preserved_data["ckey"] = M.key
	preserved_data["real_name"] = H.real_name
	preserved_data["species"] = H.dna.species.type
	preserved_data["gender"] = H.gender
	var/datum/dna/D = new /datum/dna
	H.dna.copy_dna(D)
	preserved_data["dna"] = D
	preserved_data["assigned_role"] = H.mind.assigned_role
	preserved_data["underwear"] = H.underwear
	preserved_data["underwear_color"] = H.underwear_color

	store_attributes(H, preserved_data)
	store_actions(H, preserved_data)
	store_skills(H, preserved_data)

	stored_bodies[H.real_name] = preserved_data


	var/datum/component/respawnable/R = H.GetComponent(/datum/component/respawnable)
	if (R)
		R.UnregisterDeathSignal()
		R.RemoveComponent()


	// Instead of implanting, add a component
	R = H.AddComponent(/datum/component/respawnable, respawn_time = clone_delay_seconds * 10)
	R.BPU = src
	to_chat(H, span_notice("Your body data has been preserved."))

/obj/machinery/body_preservation_unit/proc/revive_body(real_name, ckey)
	if(!stored_bodies[real_name])
		return

	var/list/stored_data = stored_bodies[real_name]

	// if (stored_data["ckey"] != usr.ckey)
	// 	log_game("Body Preservation Unit: Wrong ckey for [real_name]. Not respawning!")
	// 	return
	var/temp_icon_state = icon_state
	icon_state = icon_state_animation
	sleep(10)
	icon_state = temp_icon_state

	// Create a new body
	var/mob/living/carbon/human/new_body = new(get_turf(src))

	// Set up the new body with stored data
	new_body.real_name = stored_data["real_name"]
	new_body.gender = stored_data["gender"]

	// Check if the stored DNA is valid
	if(istype(stored_data["dna"], /datum/dna))
		var/datum/dna/stored_dna = stored_data["dna"]
		stored_dna.transfer_identity(new_body)
	else
		log_game("Body Preservation Unit: Stored DNA for [real_name] was invalid.")
		qdel(new_body)
		return

	// Check if the species type is valid
	var/species_type = stored_data["species"]
	if(ispath(species_type, /datum/species))
		new_body.set_species(species_type)
	else
		log_game("Body Preservation Unit: Stored species type for [real_name] was invalid.")
		qdel(new_body)
		return

	// Apply attribute penalty and set attributes
	var/list/stored_attributes = stored_data["attributes"]
	if(islist(stored_attributes))
		// TODO Punishment
		new_body.attributes = stored_attributes
		new_body.adjust_all_attribute_levels(revival_attribute_penalty)
		store_attributes(new_body, stored_data)
	else
		log_game("Body Preservation Unit: Stored attributes for [real_name] were invalid.")
		qdel(new_body)
		return

	var/underwear = stored_data["underwear"]
	if (underwear)
		new_body.underwear = underwear

	var/underwear_color = stored_data["underwear_color"]
	if (underwear_color)
		new_body.underwear_color = underwear_color

	var/datum/component/respawnable/R = new_body.AddComponent(/datum/component/respawnable, respawn_time = clone_delay_seconds * 10)
	R.BPU = src

	// Revive the new body
	new_body.revive(full_heal = TRUE, admin_revive = FALSE)
	new_body.updateappearance()

	// if (isnull(usr))
	// 	new_body.ckey = ckey
	// else
	new_body.equipOutfit(/datum/outfit/job/civilian)
	new_body.ckey = ckey

	var/skills_json = stored_data["skills"]
	if (skills_json)
		new_body.mind.known_skills = deserialize_skills(skills_json)

	var/list/stored_action_types = stored_data["action_types"]
	if (islist(stored_action_types))
		for (var/T in stored_action_types)
			var/datum/action/G = new T()
			G.Grant(new_body)

	if (!new_body.ckey)
		log_game("Body Preservation Unit: Created a new body for [real_name] without a ckey.")
		qdel(new_body)
		return

	var/assigned_role = stored_data["assigned_role"]
	if (assigned_role)
		new_body.mind.assigned_role = assigned_role

	playsound(get_turf(src), 'sound/effects/bin_close.ogg', 35, 3, 3)
	playsound(get_turf(src), 'sound/misc/splort.ogg', 35, 3, 3)
	to_chat(new_body, "<span class='warning'>You have been revived in a new body, but your attributes have decreased slightly.</span>")

// New component for handling respawns
/datum/component/respawnable
	var/respawn_time = 10 SECONDS
	var/obj/machinery/body_preservation_unit/BPU

/datum/component/respawnable/Initialize(respawn_time)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	src.respawn_time = respawn_time
	RegisterSignal(parent, COMSIG_LIVING_DEATH, PROC_REF(on_death))

/datum/component/respawnable/proc/UnregisterDeathSignal()
	UnregisterSignal(parent, COMSIG_LIVING_DEATH)

/datum/component/respawnable/proc/on_death(mob/living/L, gibbed)
	SIGNAL_HANDLER
	if (ishuman(L))
		var/mob/living/carbon/human/H = L
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(offer_respawn_global), H.real_name, BPU), respawn_time)
		var/list/stored_data = BPU.stored_bodies[H.real_name]
		stored_data["time_of_death"] = world.time


// Define this as a global proc
/proc/offer_respawn_global(real_name, obj/machinery/body_preservation_unit/BPU)
	var/mob/dead/observer/ghost = find_dead_player(real_name)
	to_chat(ghost, "<span class='notice'>BPU is now ready to rebuild your body, click on the BPU as a ghost to re-build yourself or accept this offer.</span>")
	if(!ghost || !ghost.client)
		return
	if (!istype(BPU) || !BPU.loc)
		return

	var/response = alert(ghost, "Do you want to be cloned at the BPU?", "Respawn Offer", "Yes", "No")
	if(response == "Yes")
//		var/obj/machinery/body_preservation_unit/BPU = locate() in GLOB.machines
		if(BPU.stored_bodies[real_name])
			BPU.revive_body(real_name, ghost.ckey)

/proc/find_dead_player(real_name)
	for(var/mob/dead/observer/O in GLOB.dead_mob_list)
		if(O.real_name == real_name)
			return O
	return null



/*--------------------------\
|League of Nine ID Imprinter|
\--------------------------*/
// heavily based off of hypnochair.dm - look in tgui/packages/tgui/interfaces/idimprinter.js for the ui code
/obj/machinery/idimprinter
	name = "identity imprinter"
	desc = "A recent development by the New League of Nine Littérateurs, this machine extracts an Identity from the Mirror and forces it onto the person. Simply force a person inside and turn it on. Interrupting impritation is ill-advised."
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper" //temporary
	verb_say = "dictates"
	verb_ask = "inquiries"
	verb_exclaim = "dictates"
	density = TRUE
	opacity = FALSE
	use_power = NO_POWER_USE

	var/imprinting = FALSE ///Is the machine imprinting an identity right now?
	var/start_time = 0 ///Time when the imprinting was started, to calculate effect in case of interruption
	var/trigger_phrase = "" ///Trigger phrase to implant
	var/timerid = 0 ///Timer ID for imprinting
	var/message_cooldown = 0 ///Cooldown for breakout message
	var/enter_message = "<span class='notice'><b>You feel dosens of pricks pierce your skin, holding you in place. Was this really a good idea?</b></span>"
	var/identitylevel = 5 /*this decides what "tier" of identity you get. you gotta have a minimum # in each virtue to meet tier requirements cuz of gear & balance
1 - urban legend (mariachi, ting-tang, base fixer gear) - no stats lol
2 - urban plague (low-tier kk, bl, mariachi/tingtang boss, middle young sib, kcorp L1, warp crew, fullstop) 60-stats
3 - urban nightmare (grade 6-5 fixers - molars, normal & east soldatos, mittlehammers, index proselytes, middle young sib, assoc fixer, kcorp3, warp modified/type C) 80-stats
4 - urban nightmare but better (assoc fixers ala cinq west, devyat, liu2, capos (not east), index proxies, middle big sib, assoc vet, r-corp..? check with maintainer) 100-stats
5 - star of the city (eastern capos, sottocapo, messenger, grand inq, directors) 120 stats - literally the only case of you ever getting this is if you sacrifice the assoc director/your boss/a second syndicate leader
*/

/obj/machinery/idimprinter/Initialize()
	. = ..()
	open_machine()
	update_icon()

/obj/machinery/idimprinter/container_resist_act(mob/living/user) //how the imprinter reacts to the occupant trying to break free
	if(!locked)
		open_machine()
		return
	user.changeNext_move(CLICK_CD_BREAKOUT)
	user.last_special = world.time + CLICK_CD_BREAKOUT
	user.visible_message(span_notice("You hear some kind of horrible, scraping sound coming from [src]!"), \
		span_notice("You lean on the back of [src] and start pushing the door open... (this will take about [DisplayTimeText(600)].)"), \
		span_hear("You hear a metallic creaking from [src]."))
		playsound(get_turf(src), 'ModularLobotomy/_Lobotomysounds/id_imprinter_sounds/deny.ogg', 25, TRUE)
		say("WARNING! The subject is attempting to disrupt the imprinting process!")
	if(do_after(user,(600), target = src))
		if(!user || user.stat != CONSCIOUS || user.loc != src || state_open || !locked)
			return
		locked = FALSE
		user.visible_message(span_warning("[user] successfully broke out of [src]!"), \
			span_notice("You successfully break out of [src]!"))
		open_machine()

/obj/machinery/idimprinter/relaymove(mob/living/user, direction)
	if(message_cooldown <= world.time)
		message_cooldown = world.time + 50
		to_chat(user, "<span class='warning'>[src]'s seal won't budge!</span>")

/obj/machinery/idimprinter/ui_state(mob/user)
	return GLOB.notcontained_state

/obj/machinery/idimprinter/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "IDImprinter", name)
		ui.open()

/obj/machinery/idimprinter/ui_data()
	var/list/data = list()
	var/mob/living/mob_occupant = occupant

	data["occupied"] = mob_occupant ? 1 : 0
	data["open"] = state_open
	data["imprinting"] = imprinting

	data["occupant"] = list()
	if(mob_occupant)
		data["occupant"]["name"] = mob_occupant.name
		data["occupant"]["stat"] = mob_occupant.stat

	return data

/obj/machinery/idimprinter/ui_act(action, params) //this is just what interacting with the ui does for the machine. hit door? open/close door.
	. = ..()
	if(.)
		return

	switch(action)
		if("door")
			if(state_open)
				close_machine()
			else
				if(!imprinting)
					open_machine()
			. = TRUE
		if("imprint")
			if(!imprinting)
				imprint()
			else
				interrupt_imprinting()
			. = TRUE

/obj/machinery/idimprinter/proc/imprint() //the proc that handles imprinting the victim and applying the effects
	var/mob/living/carbon/human/H = occupant
	if(!istype(C))
		playsound(get_turf(src), 'ModularLobotomy/_Lobotomysounds/id_imprinter_sounds/deny.ogg', 25, TRUE)
		say("Specimens such as Gene Corp Remnants, animals, and most beings from the Ruins cannot be imprinted.")
		return
	if(var/obj/item/I in H.held_items + H.get_equipped_items()) //marked for destgrok review
		if(!HAS_TRAIT(I, TRAIT_NODROP))
			playsound(get_turf(src), 'ModularLobotomy/_Lobotomysounds/id_imprinter_sounds/deny.ogg', 25, TRUE)
			say("Please remove all non-organic items such as radios, uniforms, and shoes, before using the imprinter.")
			return
	victim = H
	to_chat(H, "<span class='warning'>You can feel those pricks turn into nails, searing past your skin!</span>")
	playsound(get_turf(src), 'ModularLobotomy/_Lobotomysounds/id_imprinter_sounds/print1.ogg', 25, TRUE)
	say("Nagel und Hammer thanks you for your dedication to the new ideal.")
	H.become_blind("idimprinter")
	ADD_TRAIT(H, TRAIT_DEAF, "idimprinter")
	imprinting = TRUE
	START_PROCESSING(SSobj, src)
	start_time = world.time
	update_icon()
	timerid = addtimer(CALLBACK(src, PROC_REF(finish_imprinting)), 450, TIMER_STOPPABLE)

/obj/machinery/idimprinter/process(delta_time) //flavorstuff while imprinting, along with deciding what requirements the victim meets
	var/mob/living/carbon/human/H = occupant
	if(!istype(H) || H != victim)
		interrupt_imprinting()
		return
	if(1)
	if(DT_PROB(5, delta_time))
		to_chat(H, "Infinite possibilities...>[pick(\
			"...My memories - they're being replaced. Is this what I really want..?",\
			"...I feel myself bleeding out...",\
			"...Everything's so violent, so bloody-...",\
			"...I see myself. Why do I look so different..?",\
			"...A whole entire world, shattered before my eyes..."\
		)]</span>")
	var/offset = prob(50) ? -2 : 2
	animate(src, pixel_x = pixel_x + offset, time = 0.2, loop = 450) //start shaking

	var/list/occupant_attributes = H.attributes //ok! lets begin deciding what requirements the victim meets!
	if(!occupant_attributes || !LAZYLEN(occupant_attributes))
		return FALSE // crazy error
	for(var/attr_name in occupant_attributes)
		var/datum/attribute/attr_datum = occupant_attributes[attr_name]
		var/attribute_level = attr_datum.get_raw_level() //raw cuz temporary buffs = bugs
		switch(attribute_level)
		if(120 to INFINITY) //identity level remains as 5 if it already was
			continue
		if(100 to 199)  //identity level set to 4 if it wasnt already lower
			identitylevel = min(identitylevel, 4)
		if(80 to 99) //so on, so forth
			identitylevel = min(identitylevel, 3)
		if(60 to 79)
			identitylevel = min(identitylevel, 2)
		else
			identitylevel = 1

/obj/machinery/idimprinter/proc/finish_imprinting() // this is what happens after succesful imprinting, and when the gear is applied
	var/mob/living/carbon/human/H = occupant
	//write gear shit here

	imprinting = FALSE
	STOP_PROCESSING(SSobj, src)
	update_icon()
	audible_message("<span class='notice'>[src] pings!</span>")
	playsound(src, 'ModularLobotomy/_Lobotomysounds/id_imprinter_sounds/print2.ogg', 30, TRUE)
	say("A new era is upon us. Imprinting complete.")

	if(QDELETED(victim) || victim != occupant)
		victim = null
		return
	victim.cure_blind("idimprinter")
	REMOVE_TRAIT(victim, TRAIT_DEAF, "idimprinter")
	victim = null

/obj/machinery/idimprinter/proc/interrupt_imprinting()
	deltimer(timerid)
	imprinting = FALSE
	STOP_PROCESSING(SSobj, src)
	update_icon()

	if(QDELETED(victim))
		victim = null
		return
	victim.cure_blind("hypnochair")
	REMOVE_TRAIT(victim, TRAIT_DEAF, "hypnochair")
	if(!(victim.get_eye_protection() > 0))
		var/time_diff = world.time - start_time
		switch(time_diff)
			if(0 to 100)
				victim.add_confusion(10)
				victim.Dizzy(100)
				victim.blur_eyes(5)
			if(101 to 200)
				victim.add_confusion(15)
				victim.Dizzy(200)
				victim.blur_eyes(10)
				if(prob(25))
					victim.apply_status_effect(/datum/status_effect/trance, rand(50,150), FALSE)
			if(201 to INFINITY)
				victim.add_confusion(20)
				victim.Dizzy(300)
				victim.blur_eyes(15)
				if(prob(65))
					victim.apply_status_effect(/datum/status_effect/trance, rand(50,150), FALSE)
	victim = null

/obj/machinery/hypnochair/update_icon_state()
	icon_state = initial(icon_state)
	if(state_open)
		icon_state += "_open"
	if(occupant)
		if(interrogating)
			icon_state += "_active"
		else
			icon_state += "_occupied"

/obj/machinery/hypnochair/container_resist_act(mob/living/user)
	user.changeNext_move(CLICK_CD_BREAKOUT)
	user.last_special = world.time + CLICK_CD_BREAKOUT
	user.visible_message("<span class='notice'>You see [user] kicking against the door of [src]!</span>", \
		"<span class='notice'>You lean on the back of [src] and start pushing the door open... (this will take about [DisplayTimeText(600)].)</span>", \
		"<span class='hear'>You hear a metallic creaking from [src].</span>")
	if(do_after(user,(600), target = src))
		if(!user || user.stat != CONSCIOUS || user.loc != src || state_open)
			return
		user.visible_message("<span class='warning'>[user] successfully broke out of [src]!</span>", \
			"<span class='notice'>You successfully break out of [src]!</span>")
		open_machine()

/obj/machinery/hypnochair/relaymove(mob/living/user, direction)
	if(message_cooldown <= world.time)
		message_cooldown = world.time + 50
		to_chat(user, "<span class='warning'>[src]'s door won't budge!</span>")


/obj/machinery/hypnochair/MouseDrop_T(mob/target, mob/user)
	if(HAS_TRAIT(user, TRAIT_UI_BLOCKED) || !Adjacent(user) || !user.Adjacent(target) || !isliving(target) || !ISADVANCEDTOOLUSER(user))
		return

	close_machine(target)


