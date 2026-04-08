/obj/machinery/computer/ego_purchase
	name = "abnormality EGO purchase console"
	desc = "Used to purchase EGO equipment."
	icon_screen = "extraction_ego"
	resistance_flags = INDESTRUCTIBLE
	/// Currently selected(shown) level of abnormalities whose EGO will be on the interface
	var/selected_level = ZAYIN_LEVEL
	var/delay = 15 SECONDS
	var/static/list/abno_preview_icon_cache = list()

/obj/machinery/computer/ego_purchase/Initialize()
	. = ..()
	if(SSmaptype.chosen_trait == FACILITY_TRAIT_NO_EGO)
		qdel(src)
		return INITIALIZE_HINT_QDEL

/obj/machinery/computer/ego_purchase/examine(mob/user)
	. = ..()
	if(GetFacilityUpgradeValue(UPGRADE_EXTRACTION_2))
		. += span_notice("This console seems to be upgraded. <b>Trained Extraction Officers</b> can extract E.G.O. with greater efficiency, <b>reducing the PE cost by 15%</b>. \
		Untrained personnel will also be shipped E.G.O. at twice the usual speed.")

/// When interacted with...
/obj/machinery/computer/ego_purchase/ui_interact(mob/user, datum/tgui/ui)
	var/client/user_client = user?.client
	if(!user_client || !user_client.prefs)
		return

	// If the user has tgui_fancy as their preference (the default), show the updated TGUI interface
	if(user_client.prefs.tgui_fancy)
		ui = SStgui.try_update_ui(user, src, ui)
		if(!ui)
			ui = new(user, src, "EgoPurchaseConsole", "E.G.O. Purchase Console")
			ui.set_autoupdate(FALSE)
			ui.open()
		return

	// If the user disabled fancy TGUI stuff, show the old interface
	else

		if(isliving(user))
			playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
		var/dat
		for(var/level = ZAYIN_LEVEL to ALEPH_LEVEL)
			dat += "<A href='byond://?src=[REF(src)];set_level=[level]'>[level == selected_level ? "<b><u>[THREAT_TO_NAME[level]]</u></b>" : "[THREAT_TO_NAME[level]]"]</A>"
		dat += "<hr>"
		for(var/datum/abnormality/A in SSlobotomy_corp.all_abnormality_datums)
			if(!LAZYLEN(A.ego_datums))
				continue
			if(A.threat_level != selected_level)
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

	// If we're missing the abno datum, ego datum or the ego datum doesn't have an item path, stop
	if(!abno_datum || !chosen_datum || !ispath(ego_path))
		return

	// Offer a 15% discount to EOs using the console
	var/user_is_extraction_specialist = (user.mind?.assigned_role == "Extraction Officer")
	var/mult = 1
	if(user_is_extraction_specialist)
		if(GetFacilityUpgradeValue(UPGRADE_EXTRACTION_2))
			mult *= 0.85 //15% off
	var/ego_cost = chosen_datum.cost * mult

	// Reject the purchase if we're short on PE
	if(abno_datum.stored_boxes < (ego_cost))
		to_chat(user, span_warning("Not enough PE boxes stored for this operation."))
		playsound(get_turf(src), 'sound/machines/terminal_prompt_deny.ogg', 50, TRUE)
		return FALSE

	// DeliverEgo will handle logic for instant spawn/drop pod/conveyor belt arrival.
	INVOKE_ASYNC(src, PROC_REF(DeliverEgo), ego_path, user)

	// Take away PE spent and log the purchase.
	abno_datum.stored_boxes -= ego_cost
	playsound(get_turf(src), 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
	log_game("[key_name(user)] purchased [ego_path].")
	message_admins("[key_name(user)] purchased [ego_path].")
	updateUsrDialog()
	SSlobotomy_corp.ego_purchase_logs += "\[[worldtime2text()]\] [user.mind.assigned_role] [user.real_name] purchased [chosen_datum.name] ([chosen_datum.item_category]) E.G.O. for [ego_cost] PE ([100 - mult * 100]% discount)."

/obj/machinery/computer/ego_purchase/proc/DeliverEgo(ego_path, mob/living/user, turf/delivery_target_override)
	if(!ispath(ego_path))
		return
	if(!istype(user) || !user.mind)
		return
	var/atom/ego

	if(user.mind.assigned_role == "Extraction Officer")
		if(!delivery_target_override)
			ego = new ego_path(get_turf(src))
			audible_message(span_notice("[usr.name] has dispensed a [ego.name] from [src]."))
			return TRUE
		else
			return TRUE // WIP
	else
		if(GetFacilityUpgradeValue(UPGRADE_EXTRACTION_2))
			delay = initial(delay)/2
		addtimer(CALLBACK(src, PROC_REF(ShipOut), ego_path), delay)
		ego = ego_path
		audible_message(span_notice("[usr.name] has ordered a [ego.name] from [src]. ETA: [delay * 0.1] seconds."))
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

/obj/machinery/computer/ego_purchase/proc/GetPortraitOrPreview(datum/abnormality/abno_datum)
	if(!istype(abno_datum))
		return
	var/wait_did_we_already_do_this = abno_preview_icon_cache[abno_datum.abno_path]
	if(wait_did_we_already_do_this)
		return wait_did_we_already_do_this

	var/mob/living/simple_animal/hostile/abnormality/our_critter = abno_datum.abno_path
	if(!ispath(our_critter, /mob/living/simple_animal/hostile/abnormality))
		return null

	if(abno_datum.GetPortrait() == "UNKNOWN")
		var/base64icon = GetAbnoPreviewIcon(abno_datum)
		abno_preview_icon_cache[abno_datum.abno_path] = base64icon
		return base64icon

	var/icon/lets_see = icon(file("icons/UI_Icons/abnormality_portraits/[abno_datum.GetPortrait()].png"))
	var/base64icon = icon2base64(lets_see)
	return base64icon

// Using this to get a preview icon for Abnormalities. Code 'borrowed' from the RCE Research Machine's bestiary entries
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
	data["abnormalities"] = list()
	data["all_tags"] = list()

	// Get all the EGO tags defined in EGO_TAGS_DESCRIPTION_LIST and send an object consisting of their name and description, also tag_checked so we can easily turn their filtering on and off in the frontend
	for(var/tag in EGO_TAGS_DESCRIPTION_LIST)
		var/list/tag_object = list("tag_name" = tag, "tag_description" = EGO_TAGS_DESCRIPTION_LIST[tag], "tag_checked" = FALSE)
		data["all_tags"] |= list(tag_object)

	for(var/datum/abnormality/AD in SSlobotomy_corp.all_abnormality_datums)
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
				"reference" = REF(ED)
			)

			ego_list |= list(datum_data)

		var/list/abno_data = list(
			"name" = AD.name,
			"desc" = AD.desc,
			"threatclass" = AD.threat_level,
			"boxes" = AD.stored_boxes,
			"ego" = ego_list,
			"reference" = REF(AD),
			"icon" = GetPortraitOrPreview(AD)
		)

		data["abnormalities"] |= list(abno_data)

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
			if(!(level < ZAYIN_LEVEL || level > ALEPH_LEVEL) && level != selected_level)
				selected_level = level
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
