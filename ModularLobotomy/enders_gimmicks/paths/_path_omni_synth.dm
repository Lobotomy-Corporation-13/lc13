// Omni-Synthesizer.
// A floating synthesizer that banks Pathstrider materials and converts them:
// Synthesis (3 lower -> 1 higher rarity, same family) and Exchange (2 of one
// path family -> 1 of another, same rarity, path materials only). Also runs a
// small ahn shop for material pouches and Stellaron Fragments.

/obj/machinery/omni_synthesizer
	name = "Omni-Synthesizer"
	desc = "A slowly turning orb of folded space. It banks Pathstrider materials and reshapes them from one form into another."
	icon = 'ModularLobotomy/_Lobotomyicons/omni_synthesizer.dmi'
	icon_state = "omni_idle"
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE
	resistance_flags = INDESTRUCTIBLE
	/// Materials consumed to synthesize one of the next rarity up.
	var/synth_cost = 3
	/// Path-family materials consumed to exchange for one of another family.
	var/exchange_cost = 2
	/// Banked materials: assoc "[typepath]" -> count.
	var/list/stored
	/// An inserted reagent container, for the base-conversion tab.
	var/obj/item/reagent_containers/beaker
	/// Points a material of each tier is worth when ground down (index = tier).
	var/static/list/mat_tier_points = list(2, 6, 18)
	/// Points of ground material per 1 unit of sin chemical.
	var/chem_point_cost = 9
	/// Points of ground trace material per 1 compacted enkephalin.
	var/enk_point_cost = 2
	/// Compacted enkephalin banked here that fuse into one Refined PE Box.
	var/enk_refine_cost = 50
	/// Shared registry: forward["cat"]["key"] = list(tier1, tier2, tier3 types).
	var/static/list/mat_forward
	/// Shared registry: info["[type]"] = list(cat, key, tier, name, icon_state, b64).
	var/static/list/mat_info
	/// Ahn shop entries: id -> list(name, cost, type, desc).
	var/static/list/shop_items
	/// EXP-book recipes: refine banked materials into path EXP items.
	var/static/list/exp_recipes
	/// Banked-book display: "[booktype]" -> list(name, icon).
	var/static/list/book_info
	/// Cached base64 icon of the compacted enkephalin can (for Storage).
	var/static/enk_icon

/obj/machinery/omni_synthesizer/Initialize()
	. = ..()
	stored = list()
	EnsureRegistry()
	update_icon()
	StartHover()

/// Slow, endless up-and-down bob so the orb reads as floating.
/obj/machinery/omni_synthesizer/proc/StartHover()
	animate(src, pixel_y = 5, time = 2 SECONDS, loop = -1, easing = SINE_EASING)
	animate(pixel_y = 0, time = 2 SECONDS, easing = SINE_EASING)

/obj/machinery/omni_synthesizer/update_overlays()
	. = ..()
	var/mutable_appearance/glow = mutable_appearance(icon, "omni_core")
	glow.blend_mode = BLEND_ADD
	. += glow

/obj/machinery/omni_synthesizer/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	default_unfasten_wrench(user, tool)
	return TRUE

// ---- Registry ----

/// Path key -> display name (built once, shared).
/obj/machinery/omni_synthesizer/proc/PathDisplayName(key)
	switch(key)
		if(PATH_KEY_DESTRUCTION) return "Destruction"
		if(PATH_KEY_HUNT) return "The Hunt"
		if(PATH_KEY_ERUDITION) return "Erudition"
		if(PATH_KEY_NIHILITY) return "Nihility"
		if(PATH_KEY_HARMONY) return "Harmony"
		if(PATH_KEY_PRESERVATION) return "Preservation"
		if(PATH_KEY_ABUNDANCE) return "Abundance"
	return key

/// Builds the shared material + shop registries on first use.
/obj/machinery/omni_synthesizer/proc/EnsureRegistry()
	if(mat_forward)
		return
	mat_forward = list("path" = list(), "trace" = list())
	mat_info = list()
	var/list/defs = list(
		list("path", PATH_KEY_DESTRUCTION,  /obj/item/stack/path_material/wrath),
		list("path", PATH_KEY_HUNT,         /obj/item/stack/path_material/envy),
		list("path", PATH_KEY_ERUDITION,    /obj/item/stack/path_material/pride),
		list("path", PATH_KEY_NIHILITY,     /obj/item/stack/path_material/gloom),
		list("path", PATH_KEY_HARMONY,      /obj/item/stack/path_material/lust),
		list("path", PATH_KEY_PRESERVATION, /obj/item/stack/path_material/sloth),
		list("path", PATH_KEY_ABUNDANCE,    /obj/item/stack/path_material/gluttony),
		list("trace", TRACE_FAMILY_FANG,    /obj/item/stack/trace_material/fang),
		list("trace", TRACE_FAMILY_LENS,    /obj/item/stack/trace_material/lens),
		list("trace", TRACE_FAMILY_ICHOR,   /obj/item/stack/trace_material/ichor),
		list("trace", TRACE_FAMILY_WARD,    /obj/item/stack/trace_material/ward),
	)
	for(var/list/d in defs)
		var/cat = d[1]
		var/key = d[2]
		var/base = d[3]
		var/list/tiers = list(base, text2path("[base]/t2"), text2path("[base]/t3"))
		mat_forward[cat][key] = tiers
		for(var/i in 1 to 3)
			var/mat_type = tiers[i]
			var/obj/item/stack/inst = new mat_type()
			mat_info["[mat_type]"] = list(
				"cat" = cat,
				"key" = key,
				"tier" = i,
				"name" = inst.name,
				"b64" = icon2base64(icon(inst.icon, inst.icon_state)),
			)
			qdel(inst)
	shop_items = list(
		"bag" = list(
			"name" = "Cosmic Material Pouch",
			"cost" = 800,
			"type" = /obj/item/storage/bag/path_materials,
			"desc" = "A pouch that holds Pathstrider materials in bulk.",
		),
		"stellaron" = list(
			"name" = "Stellaron Fragment",
			"cost" = 500,
			"type" = /obj/item/path_crystal,
			"desc" = "Awaken a Path. Single use.",
		),
		"extraction" = list(
			"name" = "Abnormality Extraction Module",
			"cost" = 1000,
			"type" = /obj/item/work_console_upgrade/pathstrider_extraction,
			"desc" = "Console attachment: work abnormalities for Path Material, and force-breach them for more.",
		),
	)
	// EXP-book recipes. Only the T1 book is refined from materials (T1 only;
	// Path/main more efficient than Trace). Higher books come from combining
	// 3 of the tier below.
	var/edmi = 'ModularLobotomy/_Lobotomyicons/path_exp_crystals.dmi'
	var/list/rdefs = list(
		list("small", "Traveler's Notes", /obj/item/stack/path_exp_crystal, 1, 3, 5, 1000, "exp_small", "", null, 0),
		list("medium", "Adventurer's Log", /obj/item/stack/path_exp_crystal/medium, 2, 0, 0, 5000, "exp_medium", "Traveler's Notes", /obj/item/stack/path_exp_crystal, 3),
		list("large", "Pathstrider's Guide", /obj/item/stack/path_exp_crystal/large, 3, 0, 0, 20000, "exp_large", "Adventurer's Log", /obj/item/stack/path_exp_crystal/medium, 3),
	)
	exp_recipes = list()
	book_info = list()
	for(var/list/rd in rdefs)
		var/b64 = icon2base64(icon(edmi, rd[8]))
		exp_recipes += list(list(
			"id" = rd[1],
			"name" = rd[2],
			"type" = rd[3],
			"tier" = rd[4],
			"main" = rd[5],
			"trace" = rd[6],
			"exp" = rd[7],
			"icon" = b64,
			"lower_name" = rd[9],
			"lower_type" = rd[10],
			"combine" = rd[11],
		))
		book_info["[rd[3]]"] = list("name" = rd[2], "icon" = b64)
	enk_icon = icon2base64(icon('ModularLobotomy/_Lobotomyicons/compacted_enkephalin.dmi', "enk"))

/// Returns the material typepath for a (category, key, tier), or null.
/obj/machinery/omni_synthesizer/proc/MatType(cat, key, tier)
	var/list/c = mat_forward[cat]
	if(!c)
		return null
	var/list/tiers = c[key]
	if(!tiers || tier < 1 || tier > 3)
		return null
	return tiers[tier]

// ---- Deposits ----

/obj/machinery/omni_synthesizer/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/path_material) || istype(I, /obj/item/stack/trace_material) || istype(I, /obj/item/stack/path_exp_crystal) || istype(I, /obj/item/stack/compacted_enkephalin))
		var/obj/item/stack/S = I
		stored["[S.type]"] += S.amount
		to_chat(user, span_notice("You bank [S.amount] [S.name] into [src]."))
		qdel(S)
		playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 40, TRUE)
		SStgui.update_uis(src)
		return
	if(istype(I, /obj/item/storage/bag/path_materials))
		DepositBag(I, user)
		return
	if(istype(I, /obj/item/reagent_containers) && I.is_open_container())
		var/obj/item/reagent_containers/B = I
		if(beaker)
			to_chat(user, span_warning("[src] already holds [beaker]. Eject it first."))
			return
		if(!user.transferItemToLoc(B, src))
			return
		beaker = B
		to_chat(user, span_notice("You slot [B] into [src]."))
		playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 40, TRUE)
		SStgui.update_uis(src)
		return
	return ..()

/// Returns the inserted container to the user (or drops it).
/obj/machinery/omni_synthesizer/proc/EjectBeaker(mob/user)
	if(!beaker)
		return
	if(user)
		user.put_in_hands(beaker)
	else
		beaker.forceMove(get_turf(src))
	beaker = null
	SStgui.update_uis(src)

/obj/machinery/omni_synthesizer/Destroy()
	QDEL_NULL(beaker)
	return ..()

/obj/machinery/omni_synthesizer/handle_atom_del(atom/A)
	if(A == beaker)
		beaker = null
		SStgui.update_uis(src)
	return ..()

/// Empties every material stack out of a pouch into storage.
/obj/machinery/omni_synthesizer/proc/DepositBag(obj/item/storage/bag/path_materials/bag, mob/user)
	var/total = 0
	for(var/obj/item/stack/S in bag.contents)
		if(!istype(S, /obj/item/stack/path_material) && !istype(S, /obj/item/stack/trace_material))
			continue
		stored["[S.type]"] += S.amount
		total += S.amount
		qdel(S)
	if(total)
		to_chat(user, span_notice("You empty [total] material\s from [bag] into [src]."))
		playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 40, TRUE)
		SStgui.update_uis(src)
	else
		to_chat(user, span_warning("[bag] has no materials to bank."))

/// Spawns `amount` of a material type at the machine, into the user's hands.
/obj/machinery/omni_synthesizer/proc/SpawnMaterial(mat_type, amount, mob/user)
	if(amount <= 0)
		return
	var/obj/item/stack/probe = new mat_type(null, 1, FALSE)
	var/cap = probe.max_amount
	qdel(probe)
	while(amount > 0)
		var/give = min(amount, cap)
		var/obj/item/stack/S = new mat_type(get_turf(src), give, FALSE)
		amount -= give
		if(user)
			user.put_in_hands(S)

// ---- UI ----

/obj/machinery/omni_synthesizer/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/omni_synthesizer/attack_hand(mob/user, list/modifiers)
	. = ..()
	ui_interact(user)

/obj/machinery/omni_synthesizer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "OmniSynthesizer")
		ui.open()

/obj/machinery/omni_synthesizer/ui_data(mob/user)
	var/list/data = list()
	// Full material catalog with owned counts (grid shows all, even 0-owned).
	var/list/catalog = list()
	for(var/cat in mat_forward)
		var/list/families = mat_forward[cat]
		for(var/fkey in families)
			var/list/tiers = families[fkey]
			for(var/i in 1 to 3)
				var/mt = tiers[i]
				var/list/info = mat_info["[mt]"]
				catalog += list(list(
					"ref" = "[mt]",
					"name" = info["name"],
					"cat" = cat,
					"key" = fkey,
					"tier" = i,
					"icon" = info["b64"],
					"owned" = (stored["[mt]"] ? stored["[mt]"] : 0),
				))
	data["catalog"] = catalog

	// Family lists for the Exchange target picker (per category).
	var/list/paths = list()
	for(var/pkey in mat_forward["path"])
		paths += list(list("key" = pkey, "name" = PathDisplayName(pkey)))
	data["path_families"] = paths
	var/list/traces = list()
	for(var/tkey in mat_forward["trace"])
		traces += list(list("key" = tkey, "name" = "[uppertext(copytext(tkey, 1, 2))][copytext(tkey, 2)]"))
	data["trace_families"] = traces

	// Ahn balance.
	var/bal = 0
	var/datum/bank_account/acct = GetAccount(user)
	if(acct)
		bal = acct.account_balance
	data["player_ahn"] = bal

	// Shop.
	var/list/shop = list()
	for(var/id in shop_items)
		var/list/e = shop_items[id]
		shop += list(list(
			"id" = id,
			"name" = e["name"],
			"cost" = e["cost"],
			"desc" = e["desc"],
			"affordable" = (bal >= e["cost"]),
		))
	data["shop"] = shop
	data["synth_cost"] = synth_cost
	data["exchange_cost"] = exchange_cost

	// EXP-book crafting: material cost (T1 only) + book-combine availability.
	var/list/exp_data = list()
	for(var/list/r in exp_recipes)
		exp_data += list(list(
			"id" = r["id"],
			"name" = r["name"],
			"exp" = r["exp"],
			"tier" = r["tier"],
			"icon" = r["icon"],
			"main_cost" = r["main"],
			"trace_cost" = r["trace"],
			"main_have" = r["main"] ? SumStoredByTier("path", r["tier"]) : 0,
			"trace_have" = r["trace"] ? SumStoredByTier("trace", r["tier"]) : 0,
			"lower_name" = r["lower_name"],
			"combine_cost" = r["combine"],
			"lower_have" = r["lower_type"] ? CountBooks(r["lower_type"]) : 0,
		))
	data["exp_recipes"] = exp_data

	// Banked EXP books (shown in Storage, withdrawable like materials).
	var/list/bbooks = list()
	for(var/key in stored)
		var/list/bi = book_info[key]
		if(!bi || stored[key] <= 0)
			continue
		bbooks += list(list(
			"ref" = key,
			"name" = bi["name"],
			"icon" = bi["icon"],
			"count" = stored[key],
		))
	data["banked_books"] = bbooks

	// ---- Base-conversion tab ----
	// Inserted reagent container + its contents (for the coloured bars).
	var/list/bk = list("loaded" = (beaker ? TRUE : FALSE))
	if(beaker)
		bk["name"] = beaker.name
		bk["current"] = beaker.reagents.total_volume
		bk["max"] = beaker.reagents.maximum_volume
		var/list/cont = list()
		for(var/datum/reagent/R in beaker.reagents.reagent_list)
			cont += list(list("name" = R.name, "volume" = R.volume, "color" = R.color))
		bk["contents"] = cont
	data["beaker"] = bk

	// Main path materials -> sin chemicals (per family, with owned per tier).
	var/list/grind = list()
	for(var/pkey in mat_forward["path"])
		var/list/tiers = mat_forward["path"][pkey]
		var/sin_type = PathKeyToSin(pkey)
		var/datum/reagent/sin = sin_type ? GLOB.chemical_reagents_list[sin_type] : null
		grind += list(list(
			"key" = pkey,
			"name" = PathDisplayName(pkey),
			"chem" = sin ? sin.name : "?",
			"color" = sin ? sin.color : "#888888",
			"t1" = (stored["[tiers[1]]"] ? stored["[tiers[1]]"] : 0),
			"t2" = (stored["[tiers[2]]"] ? stored["[tiers[2]]"] : 0),
			"t3" = (stored["[tiers[3]]"] ? stored["[tiers[3]]"] : 0),
		))
	data["grind_families"] = grind

	// Trace materials -> compacted enkephalin (per family, owned per tier).
	var/list/comp = list()
	for(var/tkey in mat_forward["trace"])
		var/list/tiers = mat_forward["trace"][tkey]
		comp += list(list(
			"key" = tkey,
			"name" = "[uppertext(copytext(tkey, 1, 2))][copytext(tkey, 2)]",
			"t1" = (stored["[tiers[1]]"] ? stored["[tiers[1]]"] : 0),
			"t2" = (stored["[tiers[2]]"] ? stored["[tiers[2]]"] : 0),
			"t3" = (stored["[tiers[3]]"] ? stored["[tiers[3]]"] : 0),
		))
	data["compact_families"] = comp

	data["mat_points"] = mat_tier_points
	data["chem_point_cost"] = chem_point_cost
	data["enk_point_cost"] = enk_point_cost
	data["enk_refine_cost"] = enk_refine_cost
	data["enk_banked"] = (stored["[/obj/item/stack/compacted_enkephalin]"] ? stored["[/obj/item/stack/compacted_enkephalin]"] : 0)
	data["enk_ref"] = "[/obj/item/stack/compacted_enkephalin]"
	data["enk_icon"] = enk_icon
	return data

/// Total banked count across all families of a category at a rarity tier.
/obj/machinery/omni_synthesizer/proc/SumStoredByTier(cat, tier)
	var/total = 0
	for(var/key in stored)
		var/list/info = mat_info[key]
		if(info && info["cat"] == cat && info["tier"] == tier)
			total += stored[key]
	return total

/// Consumes `amount` across families of a category at a tier. Assumes enough.
/obj/machinery/omni_synthesizer/proc/ConsumeStoredByTier(cat, tier, amount)
	var/remaining = amount
	for(var/key in stored)
		if(remaining <= 0)
			break
		var/list/info = mat_info[key]
		if(!info || info["cat"] != cat || info["tier"] != tier)
			continue
		var/take = min(remaining, stored[key])
		stored[key] -= take
		remaining -= take

/// How many EXP books of a type are banked in the machine.
/obj/machinery/omni_synthesizer/proc/CountBooks(book_type)
	return stored["[book_type]"] ? stored["[book_type]"] : 0

/// Consumes `amount` banked books of a type (assumes enough).
/obj/machinery/omni_synthesizer/proc/ConsumeBooks(book_type, amount)
	stored["[book_type]"] -= amount

/obj/machinery/omni_synthesizer/proc/GetAccount(mob/user)
	if(!isliving(user))
		return null
	var/mob/living/L = user
	var/obj/item/card/id/C = L.get_idcard(TRUE)
	return C?.registered_account

/obj/machinery/omni_synthesizer/ui_act(action, params)
	. = ..()
	if(.)
		return
	var/mob/user = usr
	switch(action)
		if("withdraw")
			var/mat_type = text2path(params["ref"])
			if(!mat_type || isnull(stored["[mat_type]"]))
				return
			var/have = stored["[mat_type]"]
			var/amount = have
			if(params["amount"])
				amount = clamp(round(text2num(params["amount"])), 1, have)
			stored["[mat_type]"] -= amount
			SpawnMaterial(mat_type, amount, user)
			return TRUE
		if("synthesize")
			return DoSynthesize(params["ref"], text2num(params["amount"]), user)
		if("exchange")
			return DoExchange(params["ref"], params["target"], text2num(params["amount"]), user)
		if("buy")
			return DoBuy(params["item"], user)
		if("craft_exp")
			return DoCraftExp(params["id"], params["source"], user)
		if("eject_beaker")
			EjectBeaker(user)
			return TRUE
		if("grind_chem")
			return DoGrindChem(params["key"], text2num(params["tier"]), text2num(params["amount"]), user)
		if("compact_trace")
			return DoCompactTrace(params["key"], text2num(params["tier"]), text2num(params["amount"]), user)
		if("refine_pe")
			return DoRefinePE(user)

/// Consumes `synth_cost` per output to bank `count` of the next rarity up.
/obj/machinery/omni_synthesizer/proc/DoSynthesize(ref, count, mob/user)
	var/mat_type = text2path(ref)
	var/list/info = mat_info["[mat_type]"]
	if(!info || info["tier"] >= 3)
		return
	count = round(count)
	if(count < 1)
		count = 1
	var/needed = synth_cost * count
	if(stored["[mat_type]"] < needed)
		return
	var/next_type = MatType(info["cat"], info["key"], info["tier"] + 1)
	if(!next_type)
		return
	stored["[mat_type]"] -= needed
	stored["[next_type]"] += count
	Pulse()
	to_chat(user, span_nicegreen("Synthesized [count] [mat_info["[next_type]"]["name"]]."))
	return TRUE

/// Consumes `exchange_cost` per output to bank `count` of a chosen path family.
/obj/machinery/omni_synthesizer/proc/DoExchange(ref, target_key, count, mob/user)
	var/mat_type = text2path(ref)
	var/list/info = mat_info["[mat_type]"]
	if(!info)
		return
	if(!target_key || target_key == info["key"])
		return
	count = round(count)
	if(count < 1)
		count = 1
	var/needed = exchange_cost * count
	if(stored["[mat_type]"] < needed)
		return
	// Exchange stays within the material's own category (path<->path,
	// trace<->trace) and same rarity tier.
	var/out_type = MatType(info["cat"], target_key, info["tier"])
	if(!out_type)
		return
	stored["[mat_type]"] -= needed
	stored["[out_type]"] += count
	Pulse()
	to_chat(user, span_nicegreen("Exchanged for [count] [mat_info["[out_type]"]["name"]]."))
	return TRUE

/// Spends ahn to spawn a shop item into the buyer's hands.
/obj/machinery/omni_synthesizer/proc/DoBuy(item_id, mob/user)
	var/list/e = shop_items[item_id]
	if(!e)
		return
	var/datum/bank_account/acct = GetAccount(user)
	if(!acct || !acct.has_money(e["cost"]))
		to_chat(user, span_warning("Not enough ahn. [e["name"]] costs [e["cost"]]."))
		return
	acct.adjust_money(-e["cost"])
	var/buy_type = e["type"]
	var/obj/item/bought = new buy_type(get_turf(src))
	user.put_in_hands(bought)
	Pulse()
	to_chat(user, span_nicegreen("Purchased [e["name"]] for [e["cost"]] ahn."))
	return TRUE

/// Makes a path EXP book. `source` is "main"/"trace" (refine T1 from banked
/// materials) or "combine" (fuse 3 of the tier below from the user's bag).
/obj/machinery/omni_synthesizer/proc/DoCraftExp(id, source, mob/user)
	var/list/recipe
	for(var/list/r in exp_recipes)
		if(r["id"] == id)
			recipe = r
			break
	if(!recipe)
		return
	if(source == "combine")
		var/lower_type = recipe["lower_type"]
		var/need = recipe["combine"]
		if(!lower_type || need <= 0)
			return
		if(CountBooks(lower_type) < need)
			to_chat(user, span_warning("You need [need] banked [recipe["lower_name"]] to combine. Place them into [src] first."))
			return
		ConsumeBooks(lower_type, need)
	else
		var/cat = (source == "trace") ? "trace" : "path"
		var/cost = (source == "trace") ? recipe["trace"] : recipe["main"]
		if(cost <= 0)
			to_chat(user, span_warning("[recipe["name"]] can only be made by combining lower books."))
			return
		var/tier = recipe["tier"]
		if(SumStoredByTier(cat, tier) < cost)
			to_chat(user, span_warning("Not enough banked [source] materials (need [cost])."))
			return
		ConsumeStoredByTier(cat, tier, cost)
	// Banked into the machine so it can chain into further combines; withdraw
	// it from the Storage tab to use it.
	stored["[recipe["type"]]"] += 1
	Pulse()
	to_chat(user, span_nicegreen("Created 1 [recipe["name"]] (banked)."))
	return TRUE

/// Brief work animation between the idle and work sprites.
/obj/machinery/omni_synthesizer/proc/Pulse()
	icon_state = "omni_work"
	playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 40, TRUE)
	addtimer(CALLBACK(src, PROC_REF(EndPulse)), 1 SECONDS)

/obj/machinery/omni_synthesizer/proc/EndPulse()
	icon_state = "omni_idle"

// ---- Base-gamemode conversions ----

/// The sin reagent a path family's materials grind into.
/obj/machinery/omni_synthesizer/proc/PathKeyToSin(key)
	switch(key)
		if(PATH_KEY_DESTRUCTION) return /datum/reagent/abnormality/sin/wrath
		if(PATH_KEY_HUNT) return /datum/reagent/abnormality/sin/envy
		if(PATH_KEY_ERUDITION) return /datum/reagent/abnormality/sin/pride
		if(PATH_KEY_NIHILITY) return /datum/reagent/abnormality/sin/gloom
		if(PATH_KEY_HARMONY) return /datum/reagent/abnormality/sin/lust
		if(PATH_KEY_PRESERVATION) return /datum/reagent/abnormality/sin/sloth
		if(PATH_KEY_ABUNDANCE) return /datum/reagent/abnormality/sin/gluttony
	return null

/// Grinds banked path materials of a family+tier into their sin chemical,
/// pouring the units into the inserted container. Yield is value-preserving:
/// a material is worth `mat_tier_points[tier]`, and `chem_point_cost` points
/// make one unit (so a top-tier material = 2 units, matching its synth cost).
/obj/machinery/omni_synthesizer/proc/DoGrindChem(key, tier, count, mob/user)
	tier = round(tier)
	var/mat_type = MatType("path", key, tier)
	if(!mat_type || tier < 1 || tier > 3)
		return
	var/have = stored["[mat_type]"] ? stored["[mat_type]"] : 0
	count = clamp(round(count), 1, have)
	if(count < 1)
		return
	if(!beaker)
		to_chat(user, span_warning("Insert a reagent container first."))
		return
	var/sin_type = PathKeyToSin(key)
	if(!sin_type)
		return
	var/points = count * mat_tier_points[tier]
	var/units = (points - (points % chem_point_cost)) / chem_point_cost
	if(units < 1)
		to_chat(user, span_warning("That isn't enough to grind even one unit of chemical."))
		return
	var/free = beaker.reagents.maximum_volume - beaker.reagents.total_volume
	if(free < units)
		to_chat(user, span_warning("[beaker] only has room for [free] more unit\s."))
		return
	stored["[mat_type]"] -= count
	beaker.reagents.add_reagent(sin_type, units)
	var/datum/reagent/sin = GLOB.chemical_reagents_list[sin_type]
	Pulse()
	to_chat(user, span_nicegreen("Ground [count] material\s into [units] unit\s of [sin ? sin.name : "chemical"]."))
	return TRUE

/// Compacts banked trace materials of a family+tier into compacted enkephalin.
/// A trace material is worth `mat_tier_points[tier]`, `enk_point_cost` points
/// per enkephalin (so their value carries their synth cost up the tiers).
/obj/machinery/omni_synthesizer/proc/DoCompactTrace(key, tier, count, mob/user)
	tier = round(tier)
	var/mat_type = MatType("trace", key, tier)
	if(!mat_type || tier < 1 || tier > 3)
		return
	var/have = stored["[mat_type]"] ? stored["[mat_type]"] : 0
	count = clamp(round(count), 1, have)
	if(count < 1)
		return
	var/points = count * mat_tier_points[tier]
	var/made = (points - (points % enk_point_cost)) / enk_point_cost
	if(made < 1)
		to_chat(user, span_warning("That isn't enough to compact even one enkephalin."))
		return
	stored["[mat_type]"] -= count
	SpawnMaterial(/obj/item/stack/compacted_enkephalin, made, user)
	Pulse()
	to_chat(user, span_nicegreen("Compacted [count] trace material\s into [made] compacted enkephalin."))
	return TRUE

/// Fuses `enk_refine_cost` banked compacted enkephalin into one Refined PE Box.
/obj/machinery/omni_synthesizer/proc/DoRefinePE(mob/user)
	var/banked = stored["[/obj/item/stack/compacted_enkephalin]"] ? stored["[/obj/item/stack/compacted_enkephalin]"] : 0
	if(banked < enk_refine_cost)
		to_chat(user, span_warning("You need [enk_refine_cost] banked compacted enkephalin to refine a PE box. Place them into [src] first."))
		return
	stored["[/obj/item/stack/compacted_enkephalin]"] -= enk_refine_cost
	var/obj/item/refinedpe/P = new(get_turf(src))
	user.put_in_hands(P)
	Pulse()
	to_chat(user, span_nicegreen("Refined [enk_refine_cost] compacted enkephalin into a [P.name]."))
	return TRUE

// ---- Compacted enkephalin (Pathstrider -> base-gamemode PE currency) ----

/obj/item/stack/compacted_enkephalin
	name = "compacted enkephalin"
	singular_name = "compacted enkephalin"
	desc = "A canister of fragmentum-tempered enkephalin, pressed dense and gold-veined. The corporate trade console will read it straight as PE."
	icon = 'ModularLobotomy/_Lobotomyicons/compacted_enkephalin.dmi'
	icon_state = "enk"
	w_class = WEIGHT_CLASS_SMALL
	max_amount = 100
	novariants = FALSE
	merge_type = /obj/item/stack/compacted_enkephalin
	/// PE added to the global pool per unit when fed to the trade console.
	var/pe_value = 1

// Feed compacted enkephalin into the corporate trade console for global PE.
/obj/machinery/computer/extraction_cargo/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/compacted_enkephalin))
		var/obj/item/stack/compacted_enkephalin/E = I
		var/pe = E.amount * E.pe_value
		SSlobotomy_corp.AdjustAvailableBoxes(pe)
		to_chat(user, span_notice("You feed [E.amount] compacted enkephalin into [src], adding [pe] PE to the reserve."))
		qdel(E)
		playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 40, TRUE)
		return
	return ..()
