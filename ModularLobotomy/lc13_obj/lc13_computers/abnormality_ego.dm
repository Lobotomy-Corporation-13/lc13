/obj/machinery/computer/ego_purchase
	name = "abnormality E.G.O. purchase console"
	desc = "Used to purchase E.G.O. equipment."
	icon_screen = "extraction_ego"
	resistance_flags = INDESTRUCTIBLE
	/// Currently selected(shown) level of abnormalities whose EGO will be on the interface
	var/list/selected_level = list()
	var/delay = 15 SECONDS
	var/static/list/abno_preview_icon_cache = list()
	/// This variable allows us to choose a delivery target when it's turned on. A special version of this machine used by the EO's tablet will be able to use it.
	var/requires_delivery_choice = FALSE
	/// Related to above. An arrival belt that can be delivered to by the EO's tablet.
	var/obj/structure/extraction_belt/linked_structure
	/// To prevent spamming sfx on the console
	var/list/noise_cooldowns = list()
	var/list/type_cooldowns = list()
	var/list/valid_sfx = list("terminal_select", "terminal_success", "terminal_prompt_confirm", "terminal_prompt_deny", "terminal_prompt")

/obj/machinery/computer/ego_purchase/Initialize()
	. = ..()
	if(SSmaptype.chosen_trait == FACILITY_TRAIT_NO_EGO)
		qdel(src)
		return INITIALIZE_HINT_QDEL

/obj/machinery/computer/ego_purchase/Destroy(force)
	linked_structure = null
	return ..()

/obj/machinery/computer/ego_purchase/examine(mob/user)
	. = ..()
	if(GetFacilityUpgradeValue(UPGRADE_EXTRACTION_2))
		. += span_notice("This console seems to be upgraded. <b>Trained Extraction Officers</b> can extract E.G.O. with greater efficiency, <b>reducing the PE cost by 15%</b>. \
		Untrained personnel will also be shipped E.G.O. at twice the usual speed.")

/obj/machinery/computer/ego_purchase/proc/MakeNoise(mob/user, noise)
	if(!noise || !istype(user) || !user.mind)
		return
	if(!(noise in valid_sfx))
		return
	playsound(get_turf(src), "sound/machines/[noise].ogg", 50, TRUE)
	noise_cooldowns[usr.ckey] = world.time + 0.2 SECONDS

/// When interacted with...
/obj/machinery/computer/ego_purchase/ui_interact(mob/user, datum/tgui/ui)
	var/client/user_client = user?.client
	if(!user_client || !user_client.prefs)
		return

	if(!selected_level[user.ckey])
		selected_level[user.ckey] = ZAYIN_LEVEL

	// If the user has tgui_fancy as their preference (the default), show the updated TGUI interface
	if(user_client.prefs.tgui_fancy)
		ui = SStgui.try_update_ui(user, src, ui)
		if(!ui)
			if(isliving(user))
				MakeNoise(user, "terminal_on")
			ui = new(user, src, "EgoPurchaseConsole", "E.G.O. Purchase Console")
			ui.set_autoupdate(FALSE) // Every update flickers tooltips and resets scrolling position.
			ui.open()
		return

	// If the user disabled fancy TGUI stuff, show the old interface
	else

		if(isliving(user))
			playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
		var/dat
		for(var/level = ZAYIN_LEVEL to ALEPH_LEVEL)
			dat += "<A href='byond://?src=[REF(src)];set_level=[level]'>[level == selected_level[user.ckey] ? "<b><u>[THREAT_TO_NAME[level]]</u></b>" : "[THREAT_TO_NAME[level]]"]</A>"
		dat += "<hr>"
		for(var/datum/abnormality/A in SSlobotomy_corp.all_abnormality_datums)
			if(!LAZYLEN(A.ego_datums))
				continue
			if(A.threat_level != selected_level[user.ckey])
				continue
			dat += "[A.name] ([A.stored_boxes] PE):<br>"
			var/mult = 1
			if(user.mind?.assigned_role == "Extraction Officer")
				if (GetFacilityUpgradeValue(UPGRADE_EXTRACTION_2))
					mult *= 0.85
			for(var/datum/ego_datum/E in A.ego_datums)
				dat += " <A href='byond://?src=[REF(src)];purchase=[E.name][E.item_category]'>[E.item_category] - [E.name] ([E.cost * mult] PE)</A>"
				var/info = html_encode(E.PrintOutInfo())
				if(info)
					dat += " - <A href='byond://?src=[REF(src)];info=[info]'>Info</A>"
				dat += "<br>"
			dat += "<br>"
		var/datum/browser/popup = new(user, "ego_purchase", "EGO Purchase Console", 440, 640)
		popup.set_content(dat)
		popup.open()
		return


// This proc will handle attempting a purchase for a specific EGO datum. Has to be handed the actual reference to the datum.
/obj/machinery/computer/ego_purchase/proc/PurchaseEgo(datum/ego_datum/chosen_datum)
	// Stop if we're not actually given an ego datum
	if(!istype(chosen_datum))
		return

	// We need to have a user to check their job
	var/mob/living/carbon/human/user = usr
	if(!istype(user) || !user.client)
		return

	// Pull the abno datum from the ego datum
	var/datum/abnormality/abno_datum = chosen_datum?.linked_abno
	var/ego_path = chosen_datum.item_path
	var/ego_name = chosen_datum.item_path.name

	// If we're missing the abno datum, ego datum or the ego datum doesn't have an item path, stop
	if(!abno_datum || !chosen_datum || !ispath(ego_path))
		return

	// Offer a 15% discount to EOs using the console
	var/user_is_extraction_specialist = (user.mind?.assigned_role == "Extraction Officer")
	var/mult = 1
	if(user_is_extraction_specialist)
		if(GetFacilityUpgradeValue(UPGRADE_EXTRACTION_2))
			mult *= UPGRADE_EXTRACTION_2_PRICE_MULT // 15% off
	var/ego_cost = chosen_datum.cost * mult

	// Reject the purchase if we're short on PE
	if(!EnkephalinCheck(user, abno_datum, ego_cost))
		return FALSE

	// Stop if we're doing something weird by moving away from the console
	var/turf/adjacency_check_turf = get_turf(src)
	if(!user.Adjacent(adjacency_check_turf))
		return

	// This following section is used primarily by the version of this computer that the EO's tablet uses. It determines a destination for EGO delivery.
	var/turf/target = get_turf(src)

	if(requires_delivery_choice)
		switch(tgui_alert(user,"Where will you send this [ego_name]?", "E.G.O. Delivery Prompt", list("Here","An Agent","Arrival", "Cancel")))
			// No change in target is required.
			if("Here")
				target = get_turf(src) // Redundant

			// Set target to the Agent's turf.
			if("An Agent")
				user.playsound_local(user, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
				var/M = input(user,"To whom would you like to send the E.G.O.?","Select Someone") as null|anything in AllLivingAgents()

				if(!M) // Actually, cancel it
					user.playsound_local(user, 'sound/machines/terminal_error.ogg', 50, FALSE)
					to_chat(user, span_warning("Nobody was specified."))
					return

				target = get_turf(M)

			// Set target to the arrival belt's turf.
			if("Arrival")
				if(!linked_structure) // nevermind
					user.playsound_local(user, 'sound/machines/terminal_prompt_deny.ogg', 50, FALSE)
					to_chat(user, span_warning("ERROR - E.G.O. ARRIVAL BELT UNLINKED"))
					return

				target = get_turf(linked_structure)

			// Back out!
			if("Cancel")
				user.playsound_local(user, 'sound/machines/terminal_prompt_deny.ogg', 50, FALSE)
				return

	// Check adjacency again (someone could keep the input open for a while)
	adjacency_check_turf = get_turf(src)
	if(!user.Adjacent(adjacency_check_turf))
		return

	// Uh oh, let's not let people print 5000000 EGOs by input stacking...
	if(!EnkephalinCheck(user, abno_datum, ego_cost))
		return

	// DeliverEgo will handle logic for instant spawn/drop pod/conveyor belt arrival.
	INVOKE_ASYNC(src, PROC_REF(DeliverEgo), ego_path, user, target)

	// Take away PE spent and log the purchase.
	var/list/new_log = list()
	new_log["time"] = worldtime2text()
	new_log["ego_name"] = chosen_datum.item_path.name
	new_log["ego_type"] = ispath(ego_path, /obj/item/ego_weapon) ? "weapon" : ispath(ego_path, /obj/item/clothing/suit/armor/ego_gear) ? "armor" : "auxiliary"
	new_log["abno_name"] = abno_datum.name
	new_log["buyer_name"] = user.real_name
	new_log["buyer_role"] = user.mind?.assigned_role
	new_log["ego_final_cost"] = ego_cost
	new_log["ego_discount_percent"] = 100 - mult * 100
	new_log["abno_previous_balance"] = abno_datum.stored_boxes

	abno_datum.stored_boxes -= ego_cost
	playsound(get_turf(src), 'sound/machines/terminal_success.ogg', 50, TRUE)
	log_game("[key_name(user)] purchased [ego_path].")
	message_admins("[key_name(user)] purchased [ego_path].")
	updateUsrDialog()

	SSlobotomy_corp.ego_purchase_logs += list(new_log)

/obj/machinery/computer/ego_purchase/proc/EnkephalinCheck(mob/user, datum/abnormality/abno_datum, cost = 0)
	if(!abno_datum)
		return FALSE
	if(abno_datum.stored_boxes < cost)
		to_chat(user, span_warning("Not enough PE boxes stored for this operation."))
		playsound(get_turf(src), 'sound/machines/terminal_prompt_deny.ogg', 50, TRUE)
		return FALSE
	return TRUE

// Handles actually delivering purchased E.G.O. - EOs get it immediately, everyone else has to wait a while and then it'll use ShipOut to determine where it lands.
/obj/machinery/computer/ego_purchase/proc/DeliverEgo(ego_path, mob/living/user, turf/delivery_target)
	if(!ispath(ego_path))
		return
	if(!istype(user) || !user.mind)
		return
	var/atom/ego
	var/tablet_delivery = istype(src.loc, /obj/item/extraction/delivery)

	if(tablet_delivery) // If we're delivering E.G.O. from an EO tablet, spawn visual sparks.
		var/datum/effect_system/spark_spread/sparks = new
		sparks.set_up(5, 1, delivery_target)
		sparks.start()

	// If we have a linked arrival belt and our delivery target ISN'T the arrival belt, add a return pad.
	if(linked_structure && !(delivery_target == get_turf(linked_structure)))
		var/obj/structure/return_pad/THEPAD = new(delivery_target)
		THEPAD.linked_structure = linked_structure

	if(user.mind.assigned_role == "Extraction Officer")
		ego = new ego_path(delivery_target)
		ego.visible_message(tablet_delivery ? span_notice("Sparks fly as [ego.name] E.G.O. is shipped in by the Extraction Officer!") : span_notice("[user.name] dispenses [ego] E.G.O. from [src]."))
		return TRUE

	else
		if(GetFacilityUpgradeValue(UPGRADE_EXTRACTION_2))
			delay = initial(delay)/2
		addtimer(CALLBACK(src, PROC_REF(ShipOut), ego_path), delay)
		ego = ego_path
		audible_message(span_notice("[usr.name] has ordered [ego.name] E.G.O. from [src]. ETA: [delay * 0.1] seconds."))
		return TRUE

/obj/machinery/computer/ego_purchase/proc/ShipOut(shipped)
	if(!ispath(shipped))
		return

	var/list/tablesinrange = list()
	var/list/extractioninrange = list()
	var/turf/T
	for(var/obj/structure/table/V in range(3, src))
		tablesinrange+=V
	for(var/obj/structure/extraction_belt/Y in range(8, src))
		extractioninrange+=Y

	if(LAZYLEN(extractioninrange))
		T = get_turf(pick(extractioninrange))
		var/obj/item/egopackage/E = new (T)
		E.contained_ego = shipped
		return

	if(LAZYLEN(tablesinrange))
		T = get_turf(pick(tablesinrange))
	else
		T = get_turf(src)

	var/obj/structure/closet/supplypod/extractionpod/pod = new()
	pod.explosionSize = list(0,0,0,0)
	new shipped(pod)
	new /obj/effect/pod_landingzone(T, pod)
	stoplag(2)

// Returns a base 64 string for display as an Abnormality's image in the UI. Prefers to use their portrait, if they have no portrait set, will use their actual sprite. Uses caching!
/obj/machinery/computer/ego_purchase/proc/GetPortraitOrPreview(datum/abnormality/abno_datum)
	if(!istype(abno_datum))
		return

	// If we already did this before for this abno, no need to do it again
	var/wait_did_we_already_do_this = abno_preview_icon_cache[abno_datum.abno_path]
	if(wait_did_we_already_do_this)
		return wait_did_we_already_do_this

	var/mob/living/simple_animal/hostile/abnormality/our_critter = abno_datum.abno_path
	if(!ispath(our_critter, /mob/living/simple_animal/hostile/abnormality))
		return null

	// Abnormality doesn't have a portrait set. We'll have to use their sprite.
	if(abno_datum.GetPortrait() == "UNKNOWN")
		var/base64icon = GetAbnoPreviewIcon(abno_datum)
		abno_preview_icon_cache[abno_datum.abno_path] = base64icon // Cache it!
		return base64icon

	// If we reached this part, the Abno has a portrait set. We still have to check if there's an actual file for the portrait.
	var/is_this_a_file = file("icons/UI_Icons/abnormality_portraits/[abno_datum.GetPortrait()].png")
	if(!fexists(is_this_a_file))
		return null // so you HAVE a portrait set but there is NO portrait file...? (looking at you rubber duck) In this case, they'll get a missing image as their icon.

	// There IS a portrait file. Make it into an icon, then that into a base64 string.
	var/icon/lets_see = icon(is_this_a_file)
	var/base64icon = icon2base64(lets_see)
	abno_preview_icon_cache[abno_datum.abno_path] = base64icon // Cache it!
	return base64icon

// Using this to get a preview icon for Abnormalities from their sprite. Code 'borrowed' from the RCE Research Machine's bestiary entries
/obj/machinery/computer/ego_purchase/proc/GetAbnoPreviewIcon(datum/abnormality/abno_datum)
	var/mob/living/simple_animal/hostile/abnormality/our_critter = abno_datum.abno_path
	if(!our_critter)
		return null

	var/icon_file = initial(our_critter.icon)
	var/icon_state_name = initial(our_critter.icon_state)
	if(!icon_file || !icon_state_name)
		return null

	var/icon/I = icon(icon_file, icon_state_name, SOUTH, 1)
	var/base64icon = icon2base64(I)
	return base64icon

// !!!!!!!!!!! Updated TGUI Interface Section !!!!!!!!!!!
/obj/machinery/computer/ego_purchase/ui_data(mob/user)
	var/list/data = list()
	data["abnormalities"] = list() // List of Abnormalities, including some basic info and their E.G.O.
	data["log"] = list() // List of E.G.O. purchase logs, for *accountability* (see: lynching).
	data["selected_level"] = selected_level[user.ckey]
	data["user_price_multiplier"] = 1 // Change E.G.O. display prices based on this value.
	if(user.mind?.assigned_role == "Extraction Officer" && GetFacilityUpgradeValue(UPGRADE_EXTRACTION_2)) // This is kinda sloppy, we should probably have a helper proc that gets discount values for an user, no?
		data["user_price_multiplier"] = UPGRADE_EXTRACTION_2_PRICE_MULT

	for(var/list/log in SSlobotomy_corp.ego_purchase_logs)
		data["log"] += list(log)

	for(var/datum/abnormality/AD in SSlobotomy_corp.all_abnormality_datums)

		// Compute each abnormality's list of E.G.O. gear.
		var/list/ego_list = list()
		for(var/datum/ego_datum/ED in AD.ego_datums)
			var/ego_threatclass = ED.CostToThreatClass()
			var/ego_tags = ED.ego_tags
			if(!islist(ego_tags))
				ego_tags = list(ego_tags)

			var/list/datum_data = list(
				"path" = ED.item_path,
				"cost" = ED.cost,
				"information" = ED.information,
				"tags" = ED.ego_tags,
				"icon" = SStestrange.GenerateEgoPreviewIcon(ED.item_path),
				"threatclass" = ego_threatclass,
				"origin" = ED.origin,
				"reference" = REF(ED) // Used to identify the E.G.O. datum when it's time to purchase it.
			)

			ego_list |= list(datum_data)

		// Actual Abnormality data. Portrait not included here, it's in static data and linked to the abno via its reference in the UI.
		var/list/abno_data = list(
			"name" = AD.name,
			"desc" = AD.desc,
			"threatclass" = AD.threat_level,
			"boxes" = AD.stored_boxes,
			"ego" = ego_list,
			"reference" = REF(AD), // Used to identify the Abnormality datum - also acts as a link between abnormality data (dynamic, because of PE boxes) and abnormality portraits (static, because I don't want to send 592305 MB of base64 icons on every refresh)
		)

		data["abnormalities"] |= list(abno_data)

	return data

// This is for data we don't really need to get dynamically updated.
/obj/machinery/computer/ego_purchase/ui_static_data(mob/user)
	var/list/data = list()
	data["all_tags"] = list()
	data["abnormality_portraits"] = list()

	for(var/datum/abnormality/AD in SSlobotomy_corp.all_abnormality_datums)
		var/list/abno_data = list(REF(AD) = GetPortraitOrPreview(AD))

		data["abnormality_portraits"] += abno_data


	// Get all the EGO tags defined in EGO_TAGS_DESCRIPTION_LIST and send an object consisting of their name and description, also tag_checked so we can easily turn their filtering on and off in the frontend
	for(var/tag in EGO_TAGS_DESCRIPTION_LIST)
		var/list/tag_object = list("tag_name" = tag, "tag_description" = EGO_TAGS_DESCRIPTION_LIST[tag], "tag_checked" = FALSE)
		data["all_tags"] |= list(tag_object)

	return data


// The frontend calls this with a certain action and payload.
/obj/machinery/computer/ego_purchase/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	if(action == "print_ego")
		var/chosen_ego = params["chosen_ego"]
		var/datum/ego_datum/chosen_ego_datum = locate(chosen_ego)
		PurchaseEgo(chosen_ego_datum)
		update_icon()
		return FALSE // I know this looks EXTREMELY suspect but I don't want the UI to update when you do this. Else, it resets the scrolling position on the ego list.
	else if(action == "refresh")
		playsound(get_turf(src), 'sound/machines/terminal_processing.ogg', 50, TRUE)
		return TRUE
	else if(action == "noise")
		if(noise_cooldowns[usr.ckey] > world.time)
			return FALSE
		var/chosen_noise = params["sfx"]
		MakeNoise(usr, chosen_noise)
		return FALSE
	else if(action == "type")
		if(type_cooldowns[usr.ckey] > world.time)
			return FALSE
		playsound(get_turf(src), "sound/machines/terminal_button0[rand(1, 8)].ogg", 50, FALSE)
		type_cooldowns[usr.ckey] = world.time + 0.1 SECONDS
		return FALSE
	else if(action == "set_level")
		var/new_level = clamp(params["selected_level"], ZAYIN_LEVEL, ALEPH_LEVEL)
		selected_level[usr.ckey] = new_level
		if(noise_cooldowns[usr.ckey] > world.time)
			return FALSE
		MakeNoise(usr, "terminal_select")
		return TRUE


/obj/machinery/computer/ego_purchase/ui_close(mob/user)
	user.unset_machine()


// !!!!!!!!!!! Old Functionality !!!!!!!!!!!
/obj/machinery/computer/ego_purchase/Topic(href, href_list)
	. = ..()
	if(.)
		return .
	if(ishuman(usr))
		usr.set_machine(src)
		add_fingerprint(usr)
		if(href_list["set_level"])
			var/level = text2num(href_list["set_level"])
			if(!(level < ZAYIN_LEVEL || level > ALEPH_LEVEL) && level != selected_level[usr.ckey])
				selected_level[usr.ckey] = level
				playsound(get_turf(src), 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
				updateUsrDialog()
				return TRUE
			return FALSE
		if(href_list["purchase"])
			var/target_datum = href_list["purchase"]
			var/datum/ego_datum/E = GLOB.ego_datums[target_datum]
			PurchaseEgo(E)

			updateUsrDialog()
			return TRUE

		if(href_list["info"])
			var/dat = html_decode(href_list["info"])
			var/datum/browser/popup = new(usr, "ego_info", "EGO Purchase Console", 340, 400)
			popup.set_content(dat)
			popup.open()
			return



//This exists for flavor. It was asked of me.
/obj/structure/extraction_belt
	name = "Agent E.G.O. extraction arrival"
	desc = "If an agent or non-extraction officer orders E.G.O., it will arrive via this output."
	resistance_flags = INDESTRUCTIBLE
	icon = 'ModularLobotomy/_Lobotomyicons/refiner.dmi'
	icon_state = "extraction_belt"

/obj/item/egopackage
	name = "E.G.O. package"
	desc = "A package containing E.G.O. of some kind."
	icon = 'ModularLobotomy/_Lobotomyicons/refiner.dmi'
	icon_state = "extract_pack"
	var/contained_ego = /obj/item/ego_weapon/training

/obj/item/egopackage/attack_self(mob/user)
	..()
	new contained_ego(get_turf(user))
	qdel(src)
