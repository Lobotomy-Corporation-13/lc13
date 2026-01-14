/obj/structure/itemselling
	name = "item selling machine"
	desc = "A machine used to sell items to the greater city"
	icon = 'ModularLobotomy/_Lobotomyicons/refiner.dmi'
	icon_state = "machine2"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE

	var/list/level_0 = list(
		/obj/item/food/fish,
	)
	var/list/level_1 = list(
		/obj/item/food/meat/slab/sweeper,
		/obj/item/food/meat/slab/worm,
		/obj/item/food/meat/slab/robot,
		/obj/item/food/meat/slab/buggy,
		/obj/item/food/meat/slab/corroded,
		/obj/item/food/meat/slab/sinnew,
		/obj/item/food/meat/slab/crimson,
		/obj/item/rawpe,
		/obj/item/reagent_containers/food/drinks/bottle/wine/unlabeled,
	)
	var/list/level_2 = list(
		/obj/item/clothing/suit/armor/ego_gear/city,
		/obj/item/ego_weapon/city,
		/obj/item/ego_weapon/ranged,
		/obj/item/head_trophy,
		/obj/item/tape/resurgence,
		/obj/item/refinedpe,
		/obj/item/raw_anomaly_core,
	)
	var/list/level_3 = list(
		/obj/item/documents,
		/obj/item/folder/syndicate,
		/obj/item/folder/documents,
	)

	/// This is an association list mapping stack items to their price, per individual item in the stack. A stack of 13 items with a price of 10 will sell for 130 ahn.
	/// It exists so we can allow players to sell stack items properly, with a price corresponding to the amount of items in the stack.
	/// Do not put non-stack items in this list.
	// An alternative way to implement this could be to give the stack type a price variable and here we could just list what we allow the sale of.
	// However, I didn't want to mess with that type for the whole codebase.
	var/list/stack_item_pricing = list(
		/obj/item/stack/thumb_east_ammo = 100,
		/obj/item/stack/thumb_east_ammo/spent = 40,
		/obj/item/stack/thumb_east_ammo/tigermark = 200,
		/obj/item/stack/thumb_east_ammo/spent/tigermark = 100,
		/obj/item/stack/thumb_east_ammo/tigermark/savage = 500,
		/obj/item/stack/thumb_east_ammo/spent/tigermark/savage = 250,
	)

	/// Types that aren't listed with within examine.
	var/list/exclude_listing = list(
		/obj/item/clothing/suit/armor/ego_gear/city = "All Non-'Fixer Suit' Armor",
		/obj/item/ego_weapon/city = "All Non-'Workshop' Weapons",
		/obj/item/food/fish = "All Fish",
	)

/obj/structure/itemselling/Initialize()
	. = ..()
	SetSellables()

/obj/structure/itemselling/proc/SetSellables()
	var/list/temp = list()
	for(var/T in level_0)
		temp.Add(typecacheof(T))
	level_0 = temp.Copy()
	temp.Cut()
	for(var/T in level_1)
		temp.Add(typecacheof(T))
	level_1 = temp.Copy()
	temp.Cut()
	for(var/T in level_2)
		temp.Add(typecacheof(T))
	level_2 = temp.Copy()
	level_2.Remove(typecacheof(/obj/item/clothing/suit/armor/ego_gear/city/misc))
	level_2.Remove(typecacheof(/obj/item/clothing/suit/armor/ego_gear/city/indigo_armor))
	level_2.Remove(typecacheof(/obj/item/clothing/suit/armor/ego_gear/city/steel_armor))
	level_2.Remove(typecacheof(/obj/item/clothing/suit/armor/ego_gear/city/amber_armor))
	level_2.Remove(typecacheof(/obj/item/clothing/suit/armor/ego_gear/city/green_armor))
	level_2.Remove(typecacheof(/obj/item/clothing/suit/armor/ego_gear/city/azure_armor))
	temp.Cut()
	for(var/T in level_3)
		temp.Add(typecacheof(T))
	level_3 = temp.Copy()
	level_3[/obj/item/documents/photocopy] = FALSE
	temp.Cut()
	return

/obj/structure/itemselling/examine(mob/user)
	. = ..()
	. += span_notice("Hit with a storage item to dump all items in it into the machine.")
	. += "<a href='byond://?src=[REF(src)];tier_3=1'>List Tier 3 Prices</a>"
	. += "<a href='byond://?src=[REF(src)];tier_2=1'>List Tier 2 Prices</a>"
	. += "<a href='byond://?src=[REF(src)];tier_1=1'>List Tier 1 Prices</a>"
	. += "<a href='byond://?src=[REF(src)];tier_0=1'>List Tier 0 Prices</a>"
	/**
	. += "Secret Documents - 1000 Ahn"
	. += "Secret Documents Folders - 1000 Ahn"
	. += "Raw Anomaly Core - 1000 Ahn"
	. += "Melee weapons - 200 Ahn"
	. += "Ranged weapons - 200 Ahn"
	. += "Armor - 200 Ahn"
	. += "Sweeper/Robot/Worm Meat - 50 Ahn"
	. += "Fish - 10 Ahn"
	*/

/obj/structure/itemselling/Topic(href, href_list)
	. = ..()
	var/list/said_names = list()
	var/item_name = ""
	var/display_text = ""
	var/list/items = list()
	if(href_list["tier_3"])
		display_text = span_notice("<b>The following items are worth 1000 Ahn:</b>")
		items.Add(level_3)
	if(href_list["tier_2"])
		display_text = span_notice("<b>The following items are worth 200 Ahn:</b>")
		items.Add(level_2)
	if(href_list["tier_1"])
		display_text = span_notice("<b>The following items are worth 50 Ahn:</b>")
		items.Add(level_1)
	if(href_list["tier_0"])
		display_text = span_notice("<b>The following items are worth 10 Ahn:</b>")
		items.Add(level_0)
	for(var/I in items)
		item_name = ""
		for(var/E in exclude_listing)
			if(I in typecacheof(E))
				item_name = exclude_listing[E]
				break
		if(item_name == "")
			var/obj/item/IT = I
			item_name = initial(IT.name)
		var/list/parts = splittext(item_name, " ")
		item_name = ""
		for(var/S in parts)
			if(item_name == "")
				item_name = capitalize(S)
			else
				item_name = item_name + " [capitalize(S)]"
		if(item_name in said_names)
			continue
		said_names += item_name
		display_text += span_notice("\n[item_name]")
	to_chat(usr, display_text)

/obj/structure/itemselling/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/storage)) // Code for storage dumping
		var/obj/item/storage/S = I
		for(var/obj/item/IT in S)
			ManageSales(IT, user)
		to_chat(user, span_notice("\The [S] was dumped into [src]."))
		playsound(I, "rustle", 50, TRUE, -5)
		return TRUE
	return ManageSales(I, user)

/obj/structure/itemselling/proc/ManageSales(obj/item/I, mob/living/user)
	var/spawntype
	if(is_type_in_typecache(I, level_3))
		spawntype = /obj/item/stack/spacecash/c1000
	else if(is_type_in_typecache(I, level_2))
		spawntype = /obj/item/stack/spacecash/c200
	else if(is_type_in_typecache(I, level_1))
		spawntype = /obj/item/stack/spacecash/c50
	else if (is_type_in_typecache(I, level_0))
		spawntype = /obj/item/stack/spacecash/c10
	else if (stack_item_pricing[I.type] > 0)
		ManageStackSale(I, user)
	else
		to_chat(user, span_warning("You cannot sell [I]."))
		return FALSE

	// Check if EGO items are sellable
	if(spawntype)
		if(istype(I, /obj/item/ego_weapon))
			var/obj/item/ego_weapon/ego = I
			if(!ego.sellable)
				to_chat(user, span_warning("[I] cannot be sold."))
				return FALSE
		else if(istype(I, /obj/item/clothing/suit/armor/ego_gear))
			var/obj/item/clothing/suit/armor/ego_gear/gear = I
			if(!gear.sellable)
				to_chat(user, span_warning("[I] cannot be sold."))
				return FALSE

	if(spawntype)
		new spawntype (get_turf(src))
		qdel(I)
	return TRUE

/obj/structure/itemselling/proc/ManageStackSale(obj/item/stack/I, mob/living/user)
	var/total_value = stack_item_pricing[I.type] * I.amount
	if(total_value)
		var/obj/item/holochip/credit_chip = new /obj/item/holochip (get_turf(src))
		credit_chip.credits = total_value
		credit_chip.update_icon()
		qdel(I)

/obj/structure/potential
	name = "Potential estimation machine"
	desc = "A machine used to estimate your poential"
	icon = 'ModularLobotomy/_Lobotomyicons/refiner.dmi'
	icon_state = "machine3"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE
	var/list/stats = list(
		FORTITUDE_ATTRIBUTE,
		PRUDENCE_ATTRIBUTE,
		TEMPERANCE_ATTRIBUTE,
		JUSTICE_ATTRIBUTE,
	)

/obj/structure/potential/Initialize()
	. = ..()
	new /obj/item/paper/fluff/fixer_skills (get_turf(src))
	new /obj/item/paper/fluff/fixer_skills (get_turf(src))

//Very dumb way to implement "empty hand AND full hand."
//These two code blocks are the same except for their triggers - if you've got a better idea, please use it.
/obj/structure/potential/proc/calculate_grade(mob/living/user)
	if (ishuman(user))
		var/mob/living/carbon/human/H = user
		var/stattotal
		var/grade
		for(var/attribute in stats)
			stattotal += get_attribute_level(H, attribute)
		stattotal /= 4	// Potential is an average of stats
		grade = round((stattotal) / 20)	// Get the average level-20, divide by 20
		// Under grade 9 doesn't register
		if (10 - grade >= 10)
			to_chat(user, span_notice("Potential too low to give grade. Not recommended to issue fixer license."))
			return
		if (10 - grade <= 0)	//Once people saw Dong-Hwan, the -7 Grade fixer.
			to_chat(user, "<span class='notice'>Recommended Grade - 1.</span>")
			return

		to_chat(user, "<span class='notice'>Recommended Grade - [max(10-grade, 1)].</span>")
		to_chat(user, "<span class='notice'>This grade may be adjusted by your local Hana representative.</span>")
		return

	to_chat(user, span_notice("No human potential identified."))

/obj/structure/potential/attackby(obj/item/I, mob/living/user, params)
	calculate_grade(user)

/obj/structure/potential/attack_hand(mob/living/user)
	calculate_grade(user)

//Timelocks
/obj/structure/timelock
	name = "T-Corp locking mechanism"
	desc = "A machine that is impossible to pass"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE

/obj/structure/timelock/Initialize()
	..()
	if(SSmaptype.maptype in list("city", "fixers"))
		new /obj/machinery/scanner_gate/officescanner (get_turf(src))
	addtimer(CALLBACK(src, PROC_REF(die)), 15 MINUTES)

/obj/structure/timelock/proc/die()
	qdel(src)

/obj/structure/moneymachine
	name = "Hana funds machine"
	desc = "A machine used by hana to create money."
	icon = 'ModularLobotomy/_Lobotomyicons/refiner.dmi'
	icon_state = "moneymachine"
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE
	var/list/hanaroles = list("Hana Representative", "Hana Administrator")
	var/inflation

/obj/structure/moneymachine/attack_hand(mob/living/user)
	if(!(user?.mind?.assigned_role in hanaroles))
		to_chat(user, "<span class='notice'>The Machine flashes red. You cannot extract money from this machine</span>")
		return
	new /obj/item/stack/spacecash/c1000(get_turf(src))
	inflation ++
	if(inflation%50 == 0)
		message_admins("<span class='notice'>Investigate the high volume of Ahn being printed by Hana Association. They have currently printed [inflation*1000] Ahn. \
			Hana is supposed to print as needed, not bank up large sums of ahn.</span>")

GLOBAL_LIST_EMPTY(loaded_quest_z_levels)

/obj/structure/maploader
	name = "ticker reader"
	desc = "A small machine with a spot to insert tickets. Could give new locations to the bus to travel to."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "minidispenser"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE
	var/obj/machinery/computer/shuttle/quests_console/linked_console = null

/obj/structure/maploader/attackby(obj/item/I, mob/living/user, params)
	if (istype(I, /obj/item/quest_ticket))
		var/obj/item/quest_ticket/T = I
		if (!GLOB.loaded_quest_z_levels.Find(T.map))
			to_chat(user, span_notice("You insert your ticket into [src]"))
			say("Locating path to [T.ticket_name]...")
			GLOB.loaded_quest_z_levels += T.map
			load_new_z_level(T.map, T.map_name)
			if (!linked_console)
				for(var/obj/machinery/computer/shuttle/quests_console/C in range(src, 5))
					linked_console = C
			linked_console.possible_destinations += ";[T.map_name]"
			say("[T.ticket_name] has been located, The bus has been updated with it's coordinates.")

/obj/item/quest_ticket
	name = "'Dilapidated Town' ticket"
	desc = "A small sheet of paper with a barcode. Could be given to a ticket reader to access to a new area."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "ticket"
	inhand_icon_state = "ticket"
	worn_icon_state = "ticket"
	var/map = "_maps/Quests/ruined_town.dmm"
	var/map_name = "ruined_town_floor"
	var/ticket_name = "Dilapidated Town"

/obj/machinery/computer/shuttle/quests_console

/obj/machinery/computer/shuttle/quests_console/connect_to_shuttle(obj/docking_port/mobile/port, obj/docking_port/stationary/dock)
	return

// Gear Buyback Machine
// Allows syndicate members to repurchase their role-specific weapons and armor
// Cost: 400 ahn per item, with separate 5-minute cooldowns for weapons and armor

/obj/machinery/gear_buyback
	name = "syndicate gear buyback machine"
	desc = "A machine used by syndicate members to repurchase lost or damaged equipment. Costs 400 ahn per item."
	icon = 'ModularLobotomy/_Lobotomyicons/refiner.dmi'
	icon_state = "machine2"
	anchored = TRUE
	density = TRUE
	resistance_flags = INDESTRUCTIBLE
	color = COLOR_DARK_RED

	/// Price for each item purchase
	var/purchase_cost = 400

	/// Cooldown duration (5 minutes)
	var/cooldown_duration = 5 MINUTES

	/// Tracks weapon purchase cooldowns by ckey -> world.time
	var/list/weapon_cooldowns = list()

	/// Tracks armor purchase cooldowns by ckey -> world.time
	var/list/armor_cooldowns = list()

	/// Maps roles to their available weapons
	var/list/role_weapons = list(
		// Thumb
		"Thumb Soldato" = list(/obj/item/ego_weapon/ranged/city/thumb),
		"Thumb Capo" = list(/obj/item/ego_weapon/ranged/city/thumb/capo, /obj/item/ego_weapon/city/thumbmelee),
		"Thumb Sottocapo" = list(/obj/item/ego_weapon/ranged/city/thumb/sottocapo, /obj/item/ego_weapon/city/thumbcane),
		"Thumb East Soldato" = list(/obj/item/ego_weapon/city/thumb_east),
		"Thumb East Capo" = list(/obj/item/ego_weapon/city/thumb_east/podao),
		// Index
		"Index Proxy" = list(/obj/item/ego_weapon/city/index/proxy/spear, /obj/item/ego_weapon/city/index/proxy),
		"Index Proselyte" = list(/obj/item/ego_weapon/city/index),
		"Index Messenger" = list(/obj/item/ego_weapon/city/index),
		// Kurokumo
		"Kurokumo Wakashu" = list(/obj/item/ego_weapon/city/kurokumo),
		"Kurokumo Hosa" = list(/obj/item/ego_weapon/city/kurokumo),
		"Kurokumo Kashira" = list(/obj/item/ego_weapon/city/kurokumo),
		// Blade Lineage
		"Blade Lineage Ronin" = list(/obj/item/ego_weapon/city/bladelineage),
		"Blade Lineage Salsu" = list(/obj/item/ego_weapon/city/bladelineage),
		"Blade Lineage Cutthroat" = list(/obj/item/ego_weapon/city/bladelineage),
		// N Corp
		"N Corp Kleinhammer" = list(/obj/item/ego_weapon/city/ncorp_brassnail),
		"N Corp Mittlehammer" = list(/obj/item/ego_weapon/city/ncorp_hammer),
		"N Corp Grosshammer" = list(/obj/item/ego_weapon/city/ncorp_hammer/big),
		"Grand Inquisitor" = list(/obj/item/ego_weapon/city/ncorp_hammer/grippy),
		// Middle
		"Little Brother" = list(/obj/item/ego_weapon/shield/middle_chain),
		"Younger Brother" = list(/obj/item/ego_weapon/shield/middle_chain/younger),
		"Big Brother" = list(/obj/item/ego_weapon/shield/middle_chain/big),
	)

	/// Maps roles to their available armor
	var/list/role_armor = list(
		// Thumb
		"Thumb Soldato" = list(/obj/item/clothing/suit/armor/ego_gear/city/thumb),
		"Thumb Capo" = list(/obj/item/clothing/suit/armor/ego_gear/city/thumb_capo),
		"Thumb Sottocapo" = list(/obj/item/clothing/suit/armor/ego_gear/city/thumb_sottocapo),
		"Thumb East Soldato" = list(/obj/item/clothing/suit/armor/ego_gear/city/thumb_east),
		"Thumb East Capo" = list(/obj/item/clothing/suit/armor/ego_gear/city/thumb_east/capo),
		// Index
		"Index Proxy" = list(/obj/item/clothing/suit/armor/ego_gear/index_proxy),
		"Index Proselyte" = list(/obj/item/clothing/suit/armor/ego_gear/city/index),
		"Index Messenger" = list(/obj/item/clothing/suit/armor/ego_gear/city/index_mess),
		// Kurokumo
		"Kurokumo Wakashu" = list(/obj/item/clothing/suit/armor/ego_gear/city/kurokumo),
		"Kurokumo Hosa" = list(/obj/item/clothing/suit/armor/ego_gear/city/kurokumo/jacket),
		"Kurokumo Kashira" = list(/obj/item/clothing/suit/armor/ego_gear/city/kurokumo/captain),
		// Blade Lineage
		"Blade Lineage Ronin" = list(/obj/item/clothing/suit/armor/ego_gear/city/blade_lineage_admin),
		"Blade Lineage Salsu" = list(/obj/item/clothing/suit/armor/ego_gear/city/blade_lineage_salsu),
		"Blade Lineage Cutthroat" = list(/obj/item/clothing/suit/armor/ego_gear/city/blade_lineage_cutthroat),
		// N Corp
		"N Corp Kleinhammer" = list(/obj/item/clothing/suit/armor/ego_gear/city/ncorp),
		"N Corp Mittlehammer" = list(/obj/item/clothing/suit/armor/ego_gear/city/ncorp),
		"N Corp Grosshammer" = list(/obj/item/clothing/suit/armor/ego_gear/city/ncorp/vet),
		"Grand Inquisitor" = list(/obj/item/clothing/suit/armor/ego_gear/city/ncorpcommander),
		// Middle
		"Little Brother" = list(/obj/item/clothing/suit/armor/ego_gear/city/middle, /obj/item/clothing/suit/armor/ego_gear/city/middle/little_sister, /obj/item/clothing/suit/armor/ego_gear/city/middle/tank_top),
		"Younger Brother" = list(/obj/item/clothing/suit/armor/ego_gear/city/middle_younger, /obj/item/clothing/suit/armor/ego_gear/city/middle_younger/younger_sister),
		"Big Brother" = list(/obj/item/clothing/suit/armor/ego_gear/city/middle_big, /obj/item/clothing/suit/armor/ego_gear/city/middle_big/big_sister),
	)

/obj/machinery/gear_buyback/examine(mob/user)
	. = ..()
	. += span_notice("Each item costs [purchase_cost] ahn.")
	. += span_notice("You can purchase weapons and armor separately.")
	. += span_notice("There is a [cooldown_duration / 10 / 60] minute cooldown between purchases of the same type.")

/obj/machinery/gear_buyback/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return

	if(!ishuman(user))
		to_chat(user, span_warning("This machine is for syndicate members only."))
		return

	var/role = user?.mind?.assigned_role
	if(!role)
		to_chat(user, span_warning("The machine cannot identify your role."))
		return

	// Check if user has access to any gear
	var/has_weapons = role_weapons[role] && length(role_weapons[role]) > 0
	var/has_armor = role_armor[role] && length(role_armor[role]) > 0

	if(!has_weapons && !has_armor)
		to_chat(user, span_warning("Your role does not have access to this machine."))
		return

	// Display available gear
	ShowGearMenu(user)

/obj/machinery/gear_buyback/Topic(href, href_list)
	. = ..()
	if(!ishuman(usr))
		return

	var/mob/living/carbon/human/user = usr
	var/role = user?.mind?.assigned_role

	if(!Adjacent(user))
		return

	if(href_list["buy_weapon"])
		var/weapon_index = text2num(href_list["buy_weapon"])
		var/list/available_weapons = role_weapons[role]
		if(!available_weapons || weapon_index < 1 || weapon_index > length(available_weapons))
			return

		var/weapon_path = available_weapons[weapon_index]
		ProcessPurchase(user, weapon_path, "weapon")

	else if(href_list["buy_armor"])
		var/armor_index = text2num(href_list["buy_armor"])
		var/list/available_armor = role_armor[role]
		if(!available_armor || armor_index < 1 || armor_index > length(available_armor))
			return

		var/armor_path = available_armor[armor_index]
		ProcessPurchase(user, armor_path, "armor")

	else if(href_list["refresh"])
		ShowGearMenu(user)

/// Displays the gear purchase menu to the user
/obj/machinery/gear_buyback/proc/ShowGearMenu(mob/living/carbon/human/user)
	var/role = user?.mind?.assigned_role
	if(!role)
		return

	var/list/available_weapons = role_weapons[role]
	var/list/available_armor = role_armor[role]

	var/display_text = span_notice("<b>[name] - [role]</b>\n")
	display_text += span_notice("Current balance: [GetUserBalance(user)] ahn\n")
	display_text += span_notice("Purchase cost: [purchase_cost] ahn per item\n\n")

	// Display weapons
	if(available_weapons && length(available_weapons) > 0)
		display_text += span_notice("<b>Available Weapons:</b>\n")
		var/weapon_cooldown_remaining = GetRemainingCooldown(user.ckey, "weapon")
		if(weapon_cooldown_remaining > 0)
			display_text += span_warning("Weapon purchase cooldown: [FormatTime(weapon_cooldown_remaining)]\n")
		else
			for(var/i = 1 to length(available_weapons))
				var/weapon_path = available_weapons[i]
				var/obj/item/weapon_item = weapon_path
				var/weapon_name = initial(weapon_item.name)
				display_text += span_notice("<a href='byond://?src=[REF(src)];buy_weapon=[i]'>[capitalize(weapon_name)]</a> - [purchase_cost] ahn\n")
		display_text += "\n"

	// Display armor
	if(available_armor && length(available_armor) > 0)
		display_text += span_notice("<b>Available Armor:</b>\n")
		var/armor_cooldown_remaining = GetRemainingCooldown(user.ckey, "armor")
		if(armor_cooldown_remaining > 0)
			display_text += span_warning("Armor purchase cooldown: [FormatTime(armor_cooldown_remaining)]\n")
		else
			for(var/i = 1 to length(available_armor))
				var/armor_path = available_armor[i]
				var/obj/item/armor_item = armor_path
				var/armor_name = initial(armor_item.name)
				display_text += span_notice("<a href='byond://?src=[REF(src)];buy_armor=[i]'>[capitalize(armor_name)]</a> - [purchase_cost] ahn\n")

	display_text += "\n<a href='byond://?src=[REF(src)];refresh=1'>Refresh</a>"

	to_chat(user, display_text)

/// Processes a purchase attempt
/obj/machinery/gear_buyback/proc/ProcessPurchase(mob/living/carbon/human/user, item_path, purchase_type)
	// Check cooldown
	var/cooldown_remaining = GetRemainingCooldown(user.ckey, purchase_type)
	if(cooldown_remaining > 0)
		to_chat(user, span_warning("You must wait [FormatTime(cooldown_remaining)] before purchasing another [purchase_type]."))
		return FALSE

	// Check balance
	var/current_balance = GetUserBalance(user)
	if(current_balance < purchase_cost)
		to_chat(user, span_warning("Insufficient funds. You need [purchase_cost] ahn but only have [current_balance] ahn."))
		return FALSE

	// Deduct payment
	if(!DeductCost(user, purchase_cost))
		to_chat(user, span_warning("Payment failed."))
		return FALSE

	// Spawn item
	var/obj/item/new_item = new item_path(get_turf(src))
	if(!new_item)
		to_chat(user, span_warning("Item creation failed. Please report this."))
		// Refund
		RefundCost(user, purchase_cost)
		return FALSE

	// Set cooldown
	SetCooldown(user.ckey, purchase_type)

	// Success message
	playsound(get_turf(src), 'sound/effects/cashregister.ogg', 50, TRUE)
	to_chat(user, span_notice("You purchase [new_item]. [purchase_cost] ahn has been deducted from your account."))

	log_game("[key_name(user)] purchased [new_item.type] from [src] for [purchase_cost] ahn at [AREACOORD(src)]")

	return TRUE

/// Gets the user's current account balance
/obj/machinery/gear_buyback/proc/GetUserBalance(mob/living/carbon/human/user)
	var/obj/item/card/id/C = user.get_idcard(TRUE)
	if(!C || !C.registered_account)
		return 0
	return C.registered_account.account_balance

/// Deducts cost from user's account
/obj/machinery/gear_buyback/proc/DeductCost(mob/living/carbon/human/user, amount)
	var/obj/item/card/id/C = user.get_idcard(TRUE)
	if(!C || !C.registered_account)
		return FALSE

	if(!C.registered_account.adjust_money(-amount))
		return FALSE

	return TRUE

/// Refunds cost to user's account
/obj/machinery/gear_buyback/proc/RefundCost(mob/living/carbon/human/user, amount)
	var/obj/item/card/id/C = user.get_idcard(TRUE)
	if(!C || !C.registered_account)
		return FALSE

	C.registered_account.adjust_money(amount)
	return TRUE

/// Sets a cooldown for a purchase type
/obj/machinery/gear_buyback/proc/SetCooldown(ckey, purchase_type)
	if(purchase_type == "weapon")
		weapon_cooldowns[ckey] = world.time + cooldown_duration
	else if(purchase_type == "armor")
		armor_cooldowns[ckey] = world.time + cooldown_duration

/// Gets the remaining cooldown time in deciseconds
/obj/machinery/gear_buyback/proc/GetRemainingCooldown(ckey, purchase_type)
	var/cooldown_end = 0

	if(purchase_type == "weapon")
		cooldown_end = weapon_cooldowns[ckey] || 0
	else if(purchase_type == "armor")
		cooldown_end = armor_cooldowns[ckey] || 0

	var/remaining = cooldown_end - world.time
	return max(0, remaining)

/// Formats time in deciseconds to a readable string
/obj/machinery/gear_buyback/proc/FormatTime(deciseconds)
	var/seconds = round(deciseconds / 10)
	var/minutes = round(seconds / 60)
	seconds = seconds % 60

	if(minutes > 0)
		return "[minutes] minute[minutes != 1 ? "s" : ""] [seconds] second[seconds != 1 ? "s" : ""]"
	else
		return "[seconds] second[seconds != 1 ? "s" : ""]"
