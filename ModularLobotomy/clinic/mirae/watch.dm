// The Mirae pocket watch: where the company's clients are, and which of them
// have stopped being clients and started being debtors.
//
// Everything it knows is shown on its own dial. An earlier version floated each
// tracked person's name over their head in the world, which put the company's
// client list in front of every bystander standing near one of them; the name
// belongs beside the ping, where only the person holding the watch can read it.
//
// It is an accessory rather than a plain item because every Mirae role is
// issued one and none of them should have to give up a belt slot for it. It
// still works held or pocketed - a watch pinned to a coat somebody else is
// wearing is no use to a Recovery Agent.

/// Health fraction at which a ping is fully red.
#define MIRAE_PING_FLOOR 0.15
#define MIRAE_PING_INTERVAL (15 SECONDS)

/obj/item/clothing/accessory/mirae_watch
	name = "mirae pocket watch"
	desc = "A brass hunter-case watch. The dial is a map, and the hands do not \
		tell the time - they point at people who owe the company something."
	icon = 'ModularLobotomy/_Lobotomyicons/teguitems.dmi'
	icon_state = "mirae_watch"
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_left.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_right.dmi'
	inhand_icon_state = "mirae_watch"
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_SMALL
	actions_types = list(/datum/action/item_action/hands_free/mirae_watch)
	/// Shared with the other city maps; generated once a round.
	var/static/datum/contract_citymap/citymap
	/// Whoever is carrying it, so the dial has an audience.
	var/mob/living/bearer
	var/ping_timer

/obj/item/clothing/accessory/mirae_watch/Destroy()
	Unbind()
	return ..()

/obj/item/clothing/accessory/mirae_watch/equipped(mob/user, slot, initial = FALSE)
	. = ..()
	if(!item_action_slot_check(slot, user))
		return
	Bind(user)

/obj/item/clothing/accessory/mirae_watch/dropped(mob/user, silent = FALSE)
	. = ..()
	Unbind()

/obj/item/clothing/accessory/mirae_watch/item_action_slot_check(slot, mob/user)
	return slot & (ITEM_SLOT_BELT | ITEM_SLOT_POCKETS)

/// Pinned to a uniform somebody has put on. An attached accessory is inside the
/// uniform rather than equipped, so equipped() never fires for it and the
/// action has to be handed over here instead.
/obj/item/clothing/accessory/mirae_watch/on_uniform_equip(obj/item/clothing/under/U, mob/living/user)
	. = ..()
	Bind(user, FALSE)

/obj/item/clothing/accessory/mirae_watch/on_uniform_dropped(obj/item/clothing/under/U, mob/living/user)
	. = ..()
	Unbind()

/// Pinned to a uniform that is already being worn. An outfit attaches its
/// accessories with no user, so the parent's hook never fires for the one every
/// Mirae role is issued; bind to whoever is wearing the uniform instead of to
/// whoever did the attaching.
/obj/item/clothing/accessory/mirae_watch/attach(obj/item/clothing/under/U, user)
	. = ..()
	if(!.)
		return
	var/mob/living/carbon/human/H = U.loc
	if(istype(H) && H.w_uniform == U)
		Bind(H, FALSE)

/obj/item/clothing/accessory/mirae_watch/detach(obj/item/clothing/under/U, user)
	Unbind()
	return ..()

/// Start tracking for whoever is carrying it.
///
/// `give_action` is FALSE when the watch is pinned to a uniform. Tracking and
/// the death alert still run - that is what the company issues it for - but no
/// button is added to an already crowded HUD. Open the dial by taking it out.
/obj/item/clothing/accessory/mirae_watch/proc/Bind(mob/living/user, give_action = TRUE)
	if(!isliving(user) || bearer == user)
		return
	Unbind()
	bearer = user
	if(give_action)
		for(var/datum/action/A as anything in actions)
			A.Grant(user)
	SSmirae.watches |= src
	if(!ping_timer)
		var/cb = CALLBACK(src, PROC_REF(Refresh))
		ping_timer = addtimer(cb, MIRAE_PING_INTERVAL, TIMER_STOPPABLE|TIMER_LOOP)
	Refresh()

/// Removes the action whether or not it was ever granted, which Remove()
/// handles, so the attached and carried paths do not need separate teardown.
/obj/item/clothing/accessory/mirae_watch/proc/Unbind()
	if(bearer)
		for(var/datum/action/A as anything in actions)
			A.Remove(bearer)
	bearer = null
	SSmirae.watches -= src
	if(ping_timer)
		deltimer(ping_timer)
		ping_timer = null

/obj/item/clothing/accessory/mirae_watch/ui_action_click(mob/user, actiontype)
	ui_interact(user)

/obj/item/clothing/accessory/mirae_watch/attack_self(mob/user)
	. = ..()
	ui_interact(user)

/obj/item/clothing/accessory/mirae_watch/ui_interact(mob/user, datum/tgui/ui)
	if(!citymap)
		citymap = new /datum/contract_citymap()
		var/turf/our_turf = get_turf(src)
		if(our_turf)
			citymap.GenerateCityMap(our_turf.z)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CityMapDisplay")
		// Pushed by hand every fifteen seconds. Left on autoupdate the dial
		// would refresh every couple of ticks and "last known position" would
		// be a lie.
		ui.set_autoupdate(FALSE)
		ui.open()

/// Deep inventory, not the default state. The default one asks whether the
/// watch is in view(), and nothing carried inside a mob ever is - so the dial
/// silently refused to open from a pocket, a belt or a uniform alike.
/obj/item/clothing/accessory/mirae_watch/ui_state()
	return GLOB.deep_inventory_state

/obj/item/clothing/accessory/mirae_watch/ui_static_data(mob/user)
	var/list/data = list()
	if(citymap?.generated)
		data["mapGrid"] = citymap.GetFullMap()
		data["gridWidth"] = citymap.grid_width
		data["gridHeight"] = citymap.grid_height
		data["offsetX"] = citymap.offset_x
		data["offsetY"] = citymap.offset_y
		data["map_legend"] = citymap.cached_legend
	return data

/obj/item/clothing/accessory/mirae_watch/ui_data(mob/user)
	var/list/data = list()
	var/turf/T = get_turf(user)
	if(T)
		data["player_x"] = T.x
		data["player_y"] = T.y
	data["pings"] = BuildPings()
	return data

/// One entry per person the company has an interest in. Position comes from
/// the ledger's cached coordinates rather than the mob, so somebody who has
/// just been gibbed still has a dot to send a recovery agent to.
///
/// mind.assigned_role is the job title, so a tracked Thumb reads "Fixer". That
/// is the same compromise the clinic's own job titles make and is left alone
/// here rather than half-solved with a lookup that only covers some factions.
/obj/item/clothing/accessory/mirae_watch/proc/BuildPings()
	var/list/out = list()
	for(var/datum/mirae_ledger/L in SSmirae.ledgers)
		var/kind = L.TrackerKind()
		if(!kind || !L.last_x)
			continue
		var/mob/living/M = L.cached_mob
		out += list(list(
			"x" = L.last_x,
			"y" = L.last_y,
			"name" = L.holder_name,
			"role" = M?.mind?.assigned_role || "unaffiliated",
			"cover" = L.policy ? L.policy.AddonText() : "none",
			"debt" = L.debt,
			"health" = (M && M.maxHealth) ? round(100 * clamp(M.health / M.maxHealth, 0, 1)) : 0,
			"kind" = kind,
			"dead" = L.dead,
			"color" = PingColour(L, kind),
		))
	return out

/// Green through to red as a client bleeds out; debtors keep their own colour
/// so the two populations never read as the same thing.
///
/// The dead are one flat bright red rather than something that pulses. The dial
/// is pushed every fifteen seconds and not repainted in between, so anything
/// animated freezes on whichever half of its cycle the last push happened to
/// catch - which read as two different colours meaning two different things.
/obj/item/clothing/accessory/mirae_watch/proc/PingColour(datum/mirae_ledger/L, kind)
	if(L.dead)
		return "#ff2a2a"
	if(kind == "debtor")
		return "#c8a13a"
	var/mob/living/M = L.cached_mob
	if(!M || !M.maxHealth)
		return "#44ff44"
	var/frac = clamp(M.health / M.maxHealth, 0, 1)
	frac = clamp((frac - MIRAE_PING_FLOOR) / (1 - MIRAE_PING_FLOOR), 0, 1)
	var/r = round(255 * (1 - frac))
	var/g = round(200 * frac + 30)
	return "#[num2hex(r, 2)][num2hex(g, 2)]44"

/// Push the dial. Positions come off the ledgers, which SSmirae keeps current,
/// so this only has to ask tgui to redraw.
/obj/item/clothing/accessory/mirae_watch/proc/Refresh()
	if(!bearer?.client)
		return
	SStgui.update_uis(src)

/// A covered client has died. The watch says so and the dial goes red.
/obj/item/clothing/accessory/mirae_watch/proc/ClientDied(datum/mirae_ledger/L)
	if(!bearer)
		return
	to_chat(bearer, span_userdanger("MIRAE CLAIM: [L.holder_name] has died. Recover them."))
	SEND_SOUND(bearer, sound('sound/machines/cryo_warning.ogg'))
	Refresh()

/datum/action/item_action/hands_free/mirae_watch
	name = "Open Ledger Dial"

#undef MIRAE_PING_FLOOR
#undef MIRAE_PING_INTERVAL
