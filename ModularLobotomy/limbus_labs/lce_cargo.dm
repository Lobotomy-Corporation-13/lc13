// LCE Cargo. The facility funds itself by extracting from the things it contains.
//
// The loop: a claw scans a specimen and produces Unstable Enkephalin; the boxes go on the export
// pad along with any surplus EGO; the pad ships them to Limbus Company HQ for Ahn; the console
// spends that Ahn on a deliberately short list of supplies, which arrive back on the same pad.
//
// The list is short on purpose. This exists because the map ships with no cable, rods or sheets -
// the only ways to get them are mutating towercaps or smashing the light fixtures that All-Around
// Helper eats - and because an ordering loop is something the unlimited-slot Clerks can actually do.

#define LCE_BOX_BASE_VALUE 150    // A full-quality box. A perfect 5-stage scan is worth 5 of these.
#define LCE_EGO_EXPORT_VALUE 400  // A complete LCE set: armour and its paired weapon together.
#define LCE_CRATE_EXPORT_VALUE 50 // The crate itself. HQ wants its shipping containers back.
#define LCE_EBOX_TIERS 5

/*			UNSTABLE ENKEPHALIN			*/

//Deliberately NOT /obj/item/rawpe. That already exists, uses this same donor sprite, and feeds the
//refinery -> pe_sales loop. Two economies sharing one item would let each be laundered into the
//other, so this is its own type with its own sink.
/obj/item/unstable_enkephalin
	name = "unstable enkephalin"
	desc = "A canister of enkephalin drawn straight out of something that did not offer it. \
		It has not been refined, and it will not keep."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_map/lce_map_obj.dmi'
	icon_state = "lce_ebox_3"
	w_class = WEIGHT_CLASS_BULKY
	///0 to 1. Set at extraction from how close the specimen's bars were to full. Drives both the
	///window art and what HQ pays for it.
	var/quality = 0.5

/obj/item/unstable_enkephalin/Initialize(mapload, set_quality)
	. = ..()
	if(!isnull(set_quality))
		quality = clamp(set_quality, 0, 1)
	update_icon()

/obj/item/unstable_enkephalin/update_icon_state()
	//Tier 1 is the floor: a box that came out of a starving specimen is still a box.
	icon_state = "lce_ebox_[clamp(round(quality * LCE_EBOX_TIERS + 0.5), 1, LCE_EBOX_TIERS)]"
	return ..()

/obj/item/unstable_enkephalin/examine(mob/user)
	. = ..()
	. += span_notice("The window reads about [round(quality * 100)]% charge.")
	. += span_notice("Worth roughly [ExportValue()] Ahn at the pad.")

/obj/item/unstable_enkephalin/proc/ExportValue()
	return round(LCE_BOX_BASE_VALUE * quality)

/*			EXPORT PAD			*/

//Cosmetically the quantum pad. /obj/machinery/quantumpad/warp is only a rename, so the look comes
//from the base: one flick of "qpad-beam" plus the quantum spark system. There is no animate() in
//the original - that really is the whole effect.
/obj/machinery/lce_export_pad
	name = "requisition pad"
	desc = "A bluespace pad wired to Limbus Company HQ. Goods left on it go out; anything ordered \
		comes back down onto it."
	icon = 'icons/obj/telescience.dmi'
	icon_state = "qpad-idle"
	density = FALSE
	use_power = IDLE_POWER_USE
	idle_power_usage = 200
	active_power_usage = 2000
	circuit = null
	resistance_flags = INDESTRUCTIBLE
	var/busy = FALSE
	var/export_cooldown = 5 SECONDS
	var/next_export = 0

/obj/machinery/lce_export_pad/Initialize(mapload)
	. = ..()
	flags_1 |= NODECONSTRUCT_1

///Copied from the quantum pad: sparks, a beam flick and the two sounds.
/obj/machinery/lce_export_pad/proc/PlayShipAnimation()
	playsound(get_turf(src), 'sound/weapons/flash.ogg', 25, TRUE)
	var/datum/effect_system/spark_spread/quantum/sparks = new
	sparks.set_up(5, 1, get_turf(src))
	sparks.start()
	flick("qpad-beam", src)
	playsound(get_turf(src), 'sound/weapons/emitter2.ogg', 25, TRUE)

///Everything on the pad, innermost first, including inside crates and bags.
/obj/machinery/lce_export_pad/proc/GoodsOnPad()
	var/turf/T = get_turf(src)
	if(!T)
		return list()
	var/list/found = list()
	//GetAllContents is recursive and covers crates and storage alike, since both hold their
	//contents natively. reverseRange puts the innermost first - deleting a crate before the items
	//inside it would orphan them, which is why cargo's own export proc does the same.
	for(var/atom/movable/AM in reverseRange(T.GetAllContents()))
		if(AM == src || AM == T || AM.anchored)
			continue
		found += AM
	return found

//Deliveries arrive the same way exports leave: the pad flashes and the goods are simply there.
//No pod, no crate - nothing drops out of the ceiling onto whoever is standing on the tile.
/obj/machinery/lce_export_pad/proc/Deliver(datum/supply_pack/pack)
	var/turf/here = get_turf(src)
	if(!here || !pack)
		return FALSE
	PlayShipAnimation()
	var/spawned = 0
	for(var/item_path in pack.contains)
		//`contains` may be flat or associative. The stock fill() only ever reads the keys, so a
		//`= 8` would silently deliver one light tube; reading the value here makes the count real.
		var/count = pack.contains[item_path] || 1
		for(var/i in 1 to count)
			new item_path(here)
			spawned++
			CHECK_TICK
	visible_message(span_notice("[src] flares, and [spawned] item\s settle onto it."))
	return TRUE

/obj/machinery/lce_export_pad/proc/Export(mob/user)
	if(busy || world.time < next_export)
		to_chat(user, span_warning("The pad is still cycling."))
		return FALSE
	var/datum/bank_account/account = SSeconomy.get_dep_account(ACCOUNT_CAR)
	if(!account)
		to_chat(user, span_warning("No cargo account is responding."))
		return FALSE

	var/turf/here = get_turf(src)
	var/list/goods = GoodsOnPad()
	var/list/shipping = list()
	var/list/crates = list()
	var/earned = 0
	var/refused = 0

	for(var/atom/movable/AM in goods)
		if(istype(AM, /obj/item/unstable_enkephalin))
			var/obj/item/unstable_enkephalin/box = AM
			shipping += box
			earned += box.ExportValue()
			continue
		if(istype(AM, /obj/item/clothing/suit/armor/ego_gear/lce))
			var/obj/item/clothing/suit/armor/ego_gear/lce/suit = AM
			//An LCE suit's Destroy() qdels its paired weapon WHEREVER that weapon is - including
			//out of somebody's hands on the far side of the facility. So a set only ships if both
			//halves are here, and the weapon is shipped explicitly rather than left to the cascade.
			var/obj/item/weapon = suit.tracked_weapon
			if(!weapon || !(weapon in goods))
				refused++
				continue
			shipping += suit
			shipping += weapon
			earned += LCE_EGO_EXPORT_VALUE
			continue
		if(istype(AM, /obj/structure/closet/crate))
			crates += AM
			earned += LCE_CRATE_EXPORT_VALUE

	//Crates go last, and anything inside them that HQ will not buy is tipped onto the pad first.
	//A closet's Destroy() would dump its contents anyway, but doing it here means the spill is a
	//deliberate, visible outcome rather than a side effect - and the operator gets their food back
	//instead of watching it vanish with the box.
	var/spilled = 0
	for(var/obj/structure/closet/crate/box in crates)
		//Copy(): forceMove pulls the item out of box.contents, and DM's for-in walks the live
		//list by index - mutating it mid-loop would skip every second item and leave half the
		//crate inside when it ships.
		for(var/atom/movable/inside in box.contents.Copy())
			if(inside in shipping)
				continue
			inside.forceMove(here)
			spilled++
	shipping += crates

	if(!length(shipping))
		to_chat(user, span_warning(refused \
			? "HQ will not take a half set. Send the armour and its weapon together." \
			: "There is nothing on the pad that HQ wants."))
		return FALSE

	busy = TRUE
	next_export = world.time + export_cooldown
	PlayShipAnimation()
	for(var/atom/movable/AM in shipping)
		if(QDELETED(AM))
			continue
		qdel(AM)
		CHECK_TICK
	account.adjust_money(earned)
	busy = FALSE
	visible_message(span_notice("[src] discharges. Manifest accepted: [earned] Ahn."))
	if(spilled)
		to_chat(user, span_notice("[spilled] item\s HQ had no use for [spilled == 1 ? "was" : "were"] left on the pad."))
	if(refused)
		to_chat(user, span_warning("[refused] EGO piece\s stayed behind - HQ will not take a half set."))
	return TRUE

/*			SUPPLY PACKS			*/

//Curated for this mode. SSshuttle registers every /datum/supply_pack subtype automatically, so
//`special` keeps these out of the stock cargo console's catalogue on other maps; our console lists
//subtypesof(/datum/supply_pack/lce) directly and ignores the flag.
//
//Each category is an abstract parent carrying the `group`, which is what the console tabs on.
//Parents have no `contains`, so both SSshuttle and our own Catalogue() skip them.
/datum/supply_pack/lce
	group = "LCE"
	special = TRUE
	crate_type = /obj/structure/closet/crate

/*  Repair - the reason this feature exists: none of this is mapped into the facility.  */

/datum/supply_pack/lce/repair
	group = "Repair"

/datum/supply_pack/lce/repair/cable
	name = "Cable Coil Crate"
	desc = "Three coils. Enough to repair prosthetics, or to stop a specimen eating the lights."
	cost = 300
	contains = list(/obj/item/stack/cable_coil = 3)
	crate_name = "cable crate"

/datum/supply_pack/lce/repair/metal
	name = "Metal Sheets"
	desc = "Fifty sheets."
	cost = 400
	contains = list(/obj/item/stack/sheet/metal/fifty)
	crate_name = "metal crate"

/datum/supply_pack/lce/repair/rods
	name = "Metal Rods"
	desc = "A bundle of rods, without the detour through mutated mushrooms."
	cost = 250
	contains = list(/obj/item/stack/rods/fifty)
	crate_name = "rod crate"

//Deliberately a small stack, and its own type because the smallest stock glass stack is fifty.
//The request for cargo came with a specific worry attached: a facility with unlimited glass ends
//up as five hundred glass walls and a floor of shards.
/obj/item/stack/sheet/glass/lce_ration
	amount = 20

/datum/supply_pack/lce/repair/glass
	name = "Glass Sheets"
	desc = "Twenty sheets. HQ does not send more than this at a time, and has its reasons."
	cost = 350
	contains = list(/obj/item/stack/sheet/glass/lce_ration)
	crate_name = "glass crate"

/datum/supply_pack/lce/repair/lights
	name = "Light Tube Crate"
	desc = "Replacement tubes. The fixtures themselves cannot be replaced, so mind them."
	cost = 250
	contains = list(/obj/item/light/tube = 8, /obj/item/light/bulb = 4)
	crate_name = "lighting crate"

/datum/supply_pack/lce/repair/tools
	name = "Tool Kit"
	desc = "A full belt of hand tools."
	cost = 400
	contains = list(/obj/item/storage/belt/utility/full/lce)
	crate_name = "tool crate"

/datum/supply_pack/lce/repair/welding
	name = "Welding Supplies"
	desc = "A fuel tank, a welder and a pair of goggles."
	cost = 350
	contains = list(/obj/item/weldingtool/largetank,
					/obj/item/clothing/glasses/welding)
	crate_name = "welding crate"

/*  Food - priced under what a scan on a well-fed specimen returns, so feeding to extract is
    thinly profitable rather than a printing press.  */

/datum/supply_pack/lce/food
	group = "Food"

/datum/supply_pack/lce/food/assorted
	name = "Assorted Specimen Diet"
	desc = "A mixed crate covering most of what the cells will eat."
	cost = 200
	contains = list(/obj/item/food/burger/plain = 3,
					/obj/item/food/sandwich = 3,
					/obj/item/food/meat/steak = 3,
					/obj/item/food/grown/apple = 4)
	crate_name = "ration crate"

/datum/supply_pack/lce/food/sweet
	name = "Confectionery Crate"
	desc = "Cake, pie, donuts and chocolate. Somebody in a cell is very particular about sweets."
	cost = 250
	contains = list(/obj/item/food/cakeslice/plain = 3,
					/obj/item/food/pie/cream = 2,
					/obj/item/food/donut = 4,
					/obj/item/food/chocolatebar = 4)
	crate_name = "confectionery crate"

/datum/supply_pack/lce/food/produce
	name = "Produce Crate"
	desc = "Carrots and greens, for the cells that want them."
	cost = 200
	contains = list(/obj/item/food/grown/carrot = 6,
					/obj/item/food/grown/potato = 4,
					/obj/item/food/grown/berries = 4)
	crate_name = "produce crate"

/datum/supply_pack/lce/food/meat
	name = "Butchery Crate"
	desc = "Raw meat in quantity. You will know if you need this."
	cost = 300
	contains = list(/obj/item/food/meat/slab = 8)
	crate_name = "butchery crate"

/*  Enrichment - things to keep the cells occupied.  */

/datum/supply_pack/lce/enrichment
	group = "Enrichment"

/datum/supply_pack/lce/enrichment/plushies
	name = "Plush Crate"
	desc = "Assorted plush toys. Cheaper than a breach."
	cost = 200
	contains = list(/obj/item/toy/plush/lizardplushie,
					/obj/item/toy/plush/moth,
					/obj/item/toy/plush/slimeplushie,
					/obj/item/toy/plush/carpplushie)
	crate_name = "plush crate"

/datum/supply_pack/lce/enrichment/ducks
	name = "Rubber Ducks"
	desc = "ten rubber ducks. No, HQ did not ask why either."
	cost = 300
	contains = list(/obj/item/bikehorn/rubberducky = 10)
	crate_name = "duck crate"

/datum/supply_pack/lce/enrichment/toys
	name = "Toy Crate"
	desc = "Foam blades and figurines. Safe to hand through a hatch."
	cost = 200
	contains = list(/obj/item/toy/foamblade = 4, /obj/item/toy/figure/clown = 2)
	crate_name = "toy crate"

/*  Medical.  */

/datum/supply_pack/lce/medical
	group = "Medical"

/datum/supply_pack/lce/medical/supplies
	name = "Medical Supplies"
	desc = "Sutures, mesh and medipens."
	cost = 250
	contains = list(/obj/item/stack/medical/suture = 3,
					/obj/item/stack/medical/mesh = 3,
					/obj/item/reagent_containers/hypospray/medipen = 4)
	crate_name = "medical crate"

/datum/supply_pack/lce/medical/surgery
	name = "Surgical Kit"
	desc = "A full duffel. Medical has three people and two of them are usually elsewhere."
	cost = 500
	contains = list(/obj/item/storage/backpack/duffelbag/med/surgery)
	crate_name = "surgical crate"

/datum/supply_pack/lce/medical/defib_cell
	name = "High-Capacity Cell"
	desc = "A charged cell. Used to power up small machines."
	cost = 300
	contains = list(/obj/item/stock_parts/cell/high = 2)
	crate_name = "cell crate"

/*  Security - Udjat ammunition. Three magazines a box, and priced so that spending the
    facility's whole income on specialist rounds is a real decision.  */

/datum/supply_pack/lce/security
	group = "Security"

/datum/supply_pack/lce/security/lasso
	name = "Deterrence Lassos"
	desc = "Two qliphoth deterrence lassos. Halves what a specimen can do, and keeps the corridor \
		lights from going red while it is walked back."
	cost = 800
	contains = list(/obj/item/qliphoth_lasso = 2)
	crate_name = "deterrence crate"

/datum/supply_pack/lce/security/udjat_standard
	name = "Udjat Magazines"
	desc = "Two standard magazines for the Udjat rifle."
	cost = 1500
	contains = list(/obj/item/udjat_mag = 2)
	crate_name = "ammunition crate"

/*  Specimen Care - one package per specimen, built from what each one actually eats and reacts
    to rather than from generic food. These are the difference between a researcher improvising
    and a researcher arriving prepared.  */

/datum/supply_pack/lce/care
	group = "Specimen Care"

/datum/supply_pack/lce/care/scorched
	name = "Scorched Girl Package"
	desc = "Lighters, matches, twenty planks for a bonfire, and food cooked well past edible."
	cost = 350
	contains = list(/obj/item/lighter = 4,
					/obj/item/storage/box/matches = 2,
					/obj/item/stack/sheet/mineral/wood = 20,
					/obj/item/food/badrecipe = 3,
					/obj/item/food/burger/fivealarm = 2,
					/obj/item/food/bearsteak = 2)
	crate_name = "scorched girl package"

/datum/supply_pack/lce/care/pbird
	name = "Punishing Bird Package"
	desc = "Bread, and wheat seeds for whoever would rather grow it than order it again."
	cost = 200
	contains = list(/obj/item/food/bread = 3,
					/obj/item/food/breadslice = 8,
					/obj/item/seeds/wheat = 4)
	crate_name = "punishing bird package"

/datum/supply_pack/lce/care/mermaid
	name = "Piscine Mermaid Package"
	desc = "Fresh fish, cake, and two salt shakers - spilled salt is something she likes, not just \
		something she eats."
	cost = 300
	contains = list(/obj/item/food/freshfish = 6,
					/obj/item/reagent_containers/food/condiment/saltshaker = 2,
					/obj/item/food/cake = 1,
					/obj/item/food/chocolatebar = 3)
	crate_name = "piscine mermaid package"

/datum/supply_pack/lce/care/laetitia
	name = "Laetitia Package"
	desc = "Cake, sweets and a plush. She eats well and she is easy to please."
	cost = 300
	contains = list(/obj/item/food/cake = 2,
					/obj/item/food/cakeslice = 4,
					/obj/item/food/candy = 6,
					/obj/item/food/chocolatebar = 4,
					/obj/item/toy/plush/lizardplushie = 1)
	crate_name = "laetitia package"

/datum/supply_pack/lce/care/lunar
	name = "Lunar Physician Package"
	desc = "Carrots, mochi and puddings, plus the glassware she likes having around."
	cost = 350
	contains = list(/obj/item/food/grown/carrot = 6,
					/obj/item/food/carrotfries = 3,
					/obj/item/food/mochi = 4,
					/obj/item/food/mumupudding = 2,
					/obj/item/reagent_containers/glass/beaker = 4,
					/obj/item/reagent_containers/syringe = 4)
	crate_name = "lunar physician package"

/datum/supply_pack/lce/care/helper
	name = "All-Around Helper Package"
	desc = "Six power cells. This is the whole of its diet, and the reason it stops eating the lights."
	cost = 400
	contains = list(/obj/item/stock_parts/cell/high = 6)
	crate_name = "all-around helper package"

/datum/supply_pack/lce/care/queen_bee
	name = "Queen Bee Package"
	desc = "Raw meat, which is both her diet and the only object she cares about."
	cost = 300
	contains = list(/obj/item/food/meat/slab = 10)
	crate_name = "queen bee package"

/datum/supply_pack/lce/care/mountain
	name = "Mountain Package"
	desc = "Meat and spare organs, in bulk. It is always hungry, and it is not fussy about the source."
	cost = 450
	contains = list(/obj/item/food/meat/slab = 10,
					/obj/item/organ/heart = 2,
					/obj/item/organ/lungs = 2)
	crate_name = "mountain package"

/datum/supply_pack/lce/care/hatred_queen
	name = "Queen of Hatred Package"
	desc = "Plushes, figurines and foam blades. Do not send books; she has opinions about books."
	cost = 300
	contains = list(/obj/item/toy/plush/lizardplushie = 2,
					/obj/item/toy/figure/clown = 2,
					/obj/item/toy/foamblade = 3,
					/obj/item/food/icecreamsandwich = 3)
	crate_name = "queen of hatred package"

/datum/supply_pack/lce/care/despair_knight
	name = "Knight of Despair Package"
	desc = "Despaired Delight, the only thing she will accept, and something soft to keep in the cell."
	cost = 350
	contains = list(/obj/item/food/frozen_treats/despaired_delight = 5,
					/obj/item/toy/plush/lizardplushie = 2)
	crate_name = "knight of despair package"

/datum/supply_pack/lce/care/simple_smile
	name = "Gone with a Simple Smile Package"
	desc = "A box of assorted nothing. It eats anything, so the cheapest thing that fits is correct."
	cost = 200
	contains = list(/obj/item/toy/figure/clown = 3,
					/obj/item/toy/foamblade = 3,
					/obj/item/food/breadslice = 6,
					/obj/item/reagent_containers/glass/beaker = 4)
	crate_name = "assorted feed package"

/*  Costume - ordered more often than anything else on this list, probably.  */

/datum/supply_pack/lce/costume
	group = "Costume"

/datum/supply_pack/lce/costume/formal
	name = "Formal Wear"
	desc = "Suits and dresses, for the shifts that go well enough to warrant them."
	cost = 250
	contains = list(/obj/item/clothing/under/suit/black,
					/obj/item/clothing/under/dress/blacktango,
					/obj/item/clothing/shoes/laceup)
	crate_name = "formal crate"

/*			ORDER CONSOLE			*/

//NOT a subtype of /obj/machinery/computer/cargo. That console's ui_data() dereferences
//SSshuttle.supply, and this map has no shuttle, no docking ports and no quartermaster area - it
//would runtime the moment anybody opened it. Delivery is by pod instead, which needs no map work.
/obj/machinery/computer/lce_cargo
	name = "requisition console"
	desc = "Orders supplies from Limbus Company HQ against whatever the facility has managed to \
		export. No credentials required, which is deliberate."
	icon_screen = "lce_cargo"
	icon_keyboard = "tech_key"
	resistance_flags = INDESTRUCTIBLE
	circuit = null
	///Where deliveries land. Resolved to the nearest pad if not set on the map.
	var/obj/machinery/lce_export_pad/pad

/obj/machinery/computer/lce_cargo/Initialize(mapload)
	. = ..()
	flags_1 |= NODECONSTRUCT_1
	return INITIALIZE_HINT_LATELOAD

//Latched late so the pad has finished initialising wherever it is on the map.
/obj/machinery/computer/lce_cargo/LateInitialize()
	. = ..()
	FindPad()

/obj/machinery/computer/lce_cargo/proc/FindPad()
	if(pad && !QDELETED(pad))
		return pad
	for(var/obj/machinery/lce_export_pad/P in range(7, src))
		pad = P
		return pad
	return null

/obj/machinery/computer/lce_cargo/proc/Catalogue()
	var/static/list/packs
	if(!packs)
		packs = list()
		for(var/pack_type in subtypesof(/datum/supply_pack/lce))
			var/datum/supply_pack/P = new pack_type
			if(!length(P.contains))
				continue
			packs += P
	return packs

/obj/machinery/computer/lce_cargo/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "LimbusCargo")
		ui.open()

/obj/machinery/computer/lce_cargo/ui_data(mob/user)
	var/list/data = list()
	var/datum/bank_account/account = SSeconomy.get_dep_account(ACCOUNT_CAR)
	data["points"] = account ? account.account_balance : 0
	data["pad_found"] = !isnull(FindPad())
	return data

/obj/machinery/computer/lce_cargo/ui_static_data(mob/user)
	var/list/data = list()
	var/list/supplies = list()
	for(var/datum/supply_pack/P in Catalogue())
		if(!supplies[P.group])
			supplies[P.group] = list("name" = P.group, "packs" = list())
		supplies[P.group]["packs"] += list(list(
			"name" = P.name,
			"cost" = P.get_cost(),
			"id" = P.type,
			"desc" = P.desc || P.name,
		))
	data["supplies"] = supplies
	return data

/obj/machinery/computer/lce_cargo/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("export")
			var/obj/machinery/lce_export_pad/landing = FindPad()
			if(!landing)
				say("No requisition pad in range.")
				return TRUE
			landing.Export(usr)
			return TRUE
		if("order")
			var/datum/supply_pack/chosen
			for(var/datum/supply_pack/P in Catalogue())
				if("[P.type]" == params["id"])
					chosen = P
					break
			if(!chosen)
				return
			Order(chosen, usr)
			return TRUE

/obj/machinery/computer/lce_cargo/proc/Order(datum/supply_pack/pack, mob/user)
	var/obj/machinery/lce_export_pad/landing = FindPad()
	if(!landing)
		say("No requisition pad in range. Nothing to deliver onto.")
		return FALSE
	var/datum/bank_account/account = SSeconomy.get_dep_account(ACCOUNT_CAR)
	if(!account)
		return FALSE
	var/cost = pack.get_cost()
	//Charged at order time, the way the express console does it - there is no shuttle round trip
	//to defer it to.
	if(!account.adjust_money(-cost))
		say("Insufficient funds. [pack.name] costs [cost] Ahn.")
		playsound(src, 'sound/machines/buzz-sigh.ogg', 40, FALSE)
		return FALSE
	landing.Deliver(pack)
	say("[pack.name] delivered. [account.account_balance] Ahn remaining.")
	playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
	return TRUE

#undef LCE_BOX_BASE_VALUE
#undef LCE_EGO_EXPORT_VALUE
#undef LCE_CRATE_EXPORT_VALUE
#undef LCE_EBOX_TIERS
