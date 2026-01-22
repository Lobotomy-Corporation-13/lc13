//Base index is Grade 5,
//Proxy is Grade 3,
//Messenger is Grade 2.
/obj/item/ego_weapon/city/index
	name = "index recruit sword"
	desc = "A sheathed sword used by index recruits."
	icon_state = "index"
	inhand_icon_state = "index"
	force = 37
	damtype = PALE_DAMAGE
	swingstyle = WEAPONSWING_LARGESWEEP

	attack_verb_continuous = list("smacks", "hammers", "beats")
	attack_verb_simple = list("smack", "hammer", "beat")
	var/prescript_target
	var/weapon_owner
	attribute_requirements = list(
		FORTITUDE_ATTRIBUTE = 60,
		PRUDENCE_ATTRIBUTE = 60,
		TEMPERANCE_ATTRIBUTE = 60,
		JUSTICE_ATTRIBUTE = 80,
	)

/obj/item/ego_weapon/city/index/attack_self(mob/user)
	..()
	if(force != initial(force))
		to_chat(user, span_notice("The prescript buff is still active."))
		return

	//Okay, check if you have a prescript
	if(prescript_target && user == weapon_owner)
		var/mob/living/simple_animal/hostile/abnormality/Y = prescript_target
		if(Y.stat == DEAD)
			prescript_target = null
			to_chat(user, span_notice("Your prescript has died. Use it in hand to recieve a prescript."))
		else
			to_chat(user, span_notice("Your prescript target is [prescript_target]."))

	//If you don't have one, pick a breached mob if available.
	else if(!prescript_target && user == weapon_owner)
		var/list/breached = list()
		for(var/mob/living/simple_animal/hostile/abnormality/B in GLOB.abnormality_mob_list)
			if(!(B.status_flags & GODMODE) && (B.stat != DEAD))
				breached+=B
		if(LAZYLEN(breached))
			prescript_target = pick(breached)
			to_chat(user, span_userdanger("Your prescript target is [prescript_target]. Slay them, and deal the killing blow with this weapon."))
		else
			to_chat(user, span_notice("There are no prescripts available."))

	//If this weapon has no owner, than make you it.
	else if(!weapon_owner)
		to_chat(user, span_notice("This weapon is now yours. Use it in hand to recieve a prescript."))
		weapon_owner = user

	else
		to_chat(user, span_warning("This is not your weapon!"))


/obj/item/ego_weapon/city/index/attack(mob/living/target, mob/living/user)
	var/living = FALSE
	if(target.stat != DEAD)
		living = TRUE
	if(!..())
		return

	if(target.stat == DEAD && target == prescript_target && living)
		prescript_complete(user)

//Make this do something
/obj/item/ego_weapon/city/index/proc/prescript_complete(mob/living/user)
	prescript_target = null
	to_chat(user, span_userdanger("You have completed your prescript, and you have been graced."))
	force *= 1.45	//BEEG BONUS
	addtimer(CALLBACK(src, PROC_REF(Return), user), 5 MINUTES)

/obj/item/ego_weapon/city/index/proc/Return(mob/living/carbon/human/user)
	force /= 1.45	//BEEG BONUS
	to_chat(user, span_notice("The power from your prescript is now gone."))


//Just gonna set this to the big proxy weapon for requirement reasons
/obj/item/ego_weapon/city/index/proxy
	name = "index longsword"
	desc = "A long sword used by index proxies."
	icon_state = "indexlongsword"
	inhand_icon_state = "indexlongsword"
	attack_verb_continuous = list("slices", "slashes", "stabs")
	attack_verb_simple = list("slice", "slash", "stab")
	hitsound = 'sound/weapons/bladeslice.ogg'
	force = 56
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 100
							)

//Just gonna set this to the big proxy weapon for requirement reasons
/obj/item/ego_weapon/city/index/proxy/spear
	name = "index spear"
	desc = "A spear used by index proxies."
	icon_state = "indexspear"
	inhand_icon_state = "indexspear"
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_left_64x64.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_right_64x64.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	hitsound = 'sound/weapons/fixer/generic/nail1.ogg'
	reach = 2
	force = 64
	stuntime = 5
	swingstyle = WEAPONSWING_THRUST

//Fockin massive sword
/obj/item/ego_weapon/city/index/yan
	name = "index greatsword"
	desc = "A greatsword sword used by a specific index messenger."
	icon_state = "indexgreatsword"
	inhand_icon_state = "indexgreatsword"
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_left_64x64.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_right_64x64.dmi'
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	attack_verb_continuous = list("cleaves", "cuts")
	attack_verb_simple = list("cleaves", "cuts")
	hitsound = 'sound/weapons/fixer/generic/finisher1.ogg'
	force = 130
	attack_speed = 2
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 120
							)

/obj/item/clothing/accessory/index_pager
	name = "index pager"
	desc = "A small pager which the index use to get their prescripts remotely."
	icon = 'icons/obj/index_pager.dmi'
	icon_state = "index_beeper"
	worn_icon_state = "index_beeper"
	lefthand_file = 'icons/obj/index_pager_worn_left.dmi'
	righthand_file = 'icons/obj/index_pager_worn_right.dmi'
	above_suit = FALSE
	minimize_when_attached = TRUE
	attachment_slot = CHEST

	/// The current prescript text
	var/prescript_text
	/// The name of the recipient for this prescript
	var/prescript_recipient
	/// Whether the prescript has been loaded (typewriter finished)
	var/prescript_loaded = FALSE
	/// Whether the prescript is currently being displayed (typewriter in progress)
	var/prescript_displaying = FALSE
	/// Whether the 5-minute pool timer is running
	var/pool_timer_active = FALSE
	/// List of submitted prescripts in pool (ckey -> text)
	var/list/submitted_prescripts = list()
	/// List of ckeys that have prescripts in pool
	var/list/submitted_ckeys = list()
	/// Draft text for each ghost's UI (ckey -> text)
	var/list/ghost_drafts = list()
	/// The looping sound datum for prescript loading
	var/datum/looping_sound/index_pager_prescript/soundloop

/obj/item/clothing/accessory/index_pager/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/point_of_interest)
	soundloop = new(list(src), FALSE)

/obj/item/clothing/accessory/index_pager/Topic(href, href_list)
	. = ..()
	if(href_list["interact"])
		if(isobserver(usr))
			ui_interact(usr)

/obj/item/clothing/accessory/index_pager/Destroy()
	QDEL_NULL(soundloop)
	return ..()

/obj/item/clothing/accessory/index_pager/attack_ghost(mob/user)
	if(!isobserver(user))
		return
	ui_interact(user)
	return ..()

/obj/item/clothing/accessory/index_pager/equipped(mob/user, slot)
	. = ..()
	RegisterSignal(user, COMSIG_PARENT_EXAMINE, PROC_REF(on_carrier_examined))

/obj/item/clothing/accessory/index_pager/dropped(mob/user)
	UnregisterSignal(user, COMSIG_PARENT_EXAMINE)
	return ..()

/obj/item/clothing/accessory/index_pager/on_uniform_equip(obj/item/clothing/under/U, mob/living/user)
	. = ..()
	RegisterSignal(user, COMSIG_PARENT_EXAMINE, PROC_REF(on_carrier_examined))
	playsound(src, 'sound/items/index_beeper_closing.ogg', 50, FALSE)

/obj/item/clothing/accessory/index_pager/on_uniform_dropped(obj/item/clothing/under/U, mob/living/user)
	. = ..()
	UnregisterSignal(user, COMSIG_PARENT_EXAMINE)
	playsound(src, 'sound/items/index_beeper_opening.ogg', 50, FALSE)

/// Called when the person carrying the pager is examined
/obj/item/clothing/accessory/index_pager/proc/on_carrier_examined(datum/source, mob/examiner, list/examine_list)
	SIGNAL_HANDLER
	if(isobserver(examiner))
		INVOKE_ASYNC(src, TYPE_PROC_REF(/datum, ui_interact), examiner)

/obj/item/clothing/accessory/index_pager/attack_self(mob/user)
	. = ..()
	if(!isliving(user))
		return

	// If there's a pending prescript that hasn't been displayed yet
	if(prescript_text && !prescript_loaded && !prescript_displaying)
		StartPrescriptDisplay()
	ui_interact(user)

/obj/item/clothing/accessory/index_pager/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/index_pager),
	)

/obj/item/clothing/accessory/index_pager/ui_state(mob/user)
	// Use always_state since we need both ghosts and living users to interact
	// Permission checks are handled in ui_act
	return GLOB.always_state

/obj/item/clothing/accessory/index_pager/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "IndexPager", name)
		ui.open()

/obj/item/clothing/accessory/index_pager/ui_close(mob/user)
	. = ..()
	// Stop the sound if the user closes the UI while typewriter is running
	if(prescript_displaying && !isobserver(user))
		FinishPrescriptDisplay()

/obj/item/clothing/accessory/index_pager/ui_data(mob/user)
	var/list/data = list()

	data["is_ghost"] = isobserver(user)
	data["on_cooldown"] = pool_timer_active
	data["submission_window_open"] = TRUE  // Always open for submissions
	data["has_submitted"] = (user.ckey in submitted_ckeys)
	data["current_submission"] = submitted_prescripts[user.ckey]  // For editing
	data["prescript_text"] = prescript_text
	data["prescript_recipient"] = prescript_recipient
	data["prescript_loaded"] = prescript_loaded
	data["prescript_displaying"] = prescript_displaying
	data["draft_text"] = ghost_drafts[user.ckey]

	return data

/obj/item/clothing/accessory/index_pager/ui_act(action, params)
	. = ..()
	if(.)
		return

	var/mob/user = usr

	switch(action)
		if("submit_prescript")
			if(!isobserver(user))
				return

			var/text = params["text"]
			if(!text || length(text) < 5 || length(text) > 300)
				to_chat(user, span_warning("Prescript must be between 5 and 300 characters."))
				return

			// Sanitize the text
			text = strip_html(text)

			// Check if updating existing or adding new
			var/is_update = (user.ckey in submitted_ckeys)

			submitted_prescripts[user.ckey] = text
			if(!is_update)
				submitted_ckeys += user.ckey
			ghost_drafts[user.ckey] = null

			// Start the 5-minute pool timer on first submission
			if(!pool_timer_active)
				StartPoolTimer()

			if(is_update)
				to_chat(user, span_notice("Your prescript has been updated."))
			else
				to_chat(user, span_notice("Your prescript has been submitted to the pool."))
			return TRUE

		if("update_draft")
			if(!isobserver(user))
				return
			ghost_drafts[user.ckey] = params["text"]
			return TRUE

		if("typing_complete")
			if(!isobserver(user))
				FinishPrescriptDisplay()
			return TRUE

/// Starts the pool timer - first prescript is sent immediately, then checks every 5 minutes
/obj/item/clothing/accessory/index_pager/proc/StartPoolTimer()
	pool_timer_active = TRUE
	PickFromPool()

/// Picks a random prescript from the pool and delivers it
/obj/item/clothing/accessory/index_pager/proc/PickFromPool()
	if(!length(submitted_prescripts))
		// Pool is empty - keep current prescript, stop timer
		pool_timer_active = FALSE
		return

	// Pick a random submission and REMOVE it from the pool
	var/selected_ckey = pick(submitted_ckeys)
	prescript_text = submitted_prescripts[selected_ckey]
	submitted_prescripts -= selected_ckey
	submitted_ckeys -= selected_ckey

	// Reset display state for new prescript
	prescript_loaded = FALSE
	prescript_displaying = FALSE

	// Determine recipient name
	var/mob/living/holder = loc
	if(istype(holder))
		prescript_recipient = holder.real_name
	else
		prescript_recipient = "Unknown"

	// Log to admins
	message_admins("[selected_ckey] submitted a prescript to [prescript_recipient]: \"[prescript_text]\"")
	log_game("INDEX PAGER: [selected_ckey] submitted prescript to [prescript_recipient]: \"[prescript_text]\"")

	// Deliver the prescript
	DeliverPrescript()

	// Schedule next pick in 5 minutes
	addtimer(CALLBACK(src, PROC_REF(PickFromPool)), 5 MINUTES)

/// Returns the mob wearing this pager, checking both direct hold and uniform attachment
/obj/item/clothing/accessory/index_pager/proc/get_wearer()
	// Check if directly held by a mob
	if(isliving(loc))
		return loc
	// Check if attached to a uniform that's being worn
	if(istype(loc, /obj/item/clothing/under))
		var/obj/item/clothing/under/U = loc
		if(isliving(U.loc))
			return U.loc
	return null

/// Called when a prescript is ready to be delivered to the holder
/obj/item/clothing/accessory/index_pager/proc/DeliverPrescript()
	playsound(src, 'sound/items/index_beeper_alert.ogg', 50, FALSE)
	icon_state = "index_beeper_alert"

	var/mob/living/holder = get_wearer()
	if(holder)
		to_chat(holder, span_userdanger("Your index pager beeps! A new prescript has arrived. Use it in hand to view."))

/// Begins the typewriter animation display
/obj/item/clothing/accessory/index_pager/proc/StartPrescriptDisplay()
	prescript_displaying = TRUE
	icon_state = "index_beeper_prescript_loading"
	soundloop.start()

/// Called when typewriter animation completes
/obj/item/clothing/accessory/index_pager/proc/FinishPrescriptDisplay()
	prescript_displaying = FALSE
	prescript_loaded = TRUE
	icon_state = "index_beeper_prescript"
	soundloop.stop()
