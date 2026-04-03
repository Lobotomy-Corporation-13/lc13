////////////////////////////////////////////////////////////
// EX THUMB SOTTOCAPO
//
// A trusted player role for a former Sottocapo of the Thumb's spider house
// who dual-wields a rapier and katana with acceleration propellant ammunition.
// They have 150 Fortitude and come equipped with their weapons, armor, ammo,
// Eye of Odin, and a suspicious phone for ordering additional ammo supplies.
////////////////////////////////////////////////////////////

/datum/job/ex_thumb_sottocapo
	title = "Ex Thumb Sottocapo"
	outfit = /datum/outfit/job/ex_thumb_sottocapo
	department_head = list("Thumb Sottocapo")
	faction = "Station"
	supervisors = "the Thumb's hierarchy"
	selection_color = "#8b0000"
	total_positions = 0
	spawn_positions = 0
	display_order = JOB_DISPLAY_ORDER_SYNDICATEHEAD
	trusted_only = TRUE
	access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	minimal_access = list(ACCESS_SYNDICATE, ACCESS_SYNDICATE_LEADER)
	departments = DEPARTMENT_COMMAND | DEPARTMENT_CITY_ANTAGONIST
	paycheck = 1000
	maptype = list("city", "fixers")
	job_important = "You are a former Sottocapo of the Thumb - a high-ranking operative of the spider house. \
		You dual-wield a rapier and katana loaded with acceleration propellant ammunition. \
		Your combo requires weapon-swapping: lunge with one weapon, AoE sweep with the other, then finish with the first. \
		Your Eye of Odin grants precognitive evasion against melee attacks, but overheats if overused. \
		Use your suspicious phone to order additional ammunition."
	job_notice = "You are a Syndicate operative. Act accordingly."

	roundstart_attributes = list(
		FORTITUDE_ATTRIBUTE = 150,
		PRUDENCE_ATTRIBUTE = 100,
		TEMPERANCE_ATTRIBUTE = 100,
		JUSTICE_ATTRIBUTE = 100
	)

/datum/job/ex_thumb_sottocapo/after_spawn(mob/living/carbon/human/H, mob/M)
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, JOB_TRAIT)
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, JOB_TRAIT)

	// Insert the Eye of Odin
	var/obj/item/organ/eyes/robotic/odin_eye/eye = new()
	eye.Insert(H)

	// Equip armor into hand (too bulky for suit slot auto-equip)
	var/obj/item/clothing/suit/armor/ego_gear/city/thumb_spider/ex_sottocapo/armor = new(H)
	H.put_in_l_hand(armor)

	// Put weapons and ammo boxes into backpack directly
	var/obj/item/storage/backpack/BP = locate() in H.contents
	if(BP)
		new /obj/item/ego_weapon/city/thumbfather_rapier(BP)
		new /obj/item/ego_weapon/city/thumbfather_katana(BP)
		new /obj/item/storage/box/thumb_east_ammo/acceleration(BP)
		new /obj/item/storage/box/thumb_east_ammo/acceleration(BP)

	. = ..()

/datum/outfit/job/ex_thumb_sottocapo
	name = "Ex Thumb Sottocapo"
	jobtype = /datum/job/ex_thumb_sottocapo

	id = /obj/item/card/id/silver/plastic
	belt = /obj/item/pda/security
	uniform = /obj/item/clothing/under/suit/charcoal
	shoes = /obj/item/clothing/shoes/laceup
	r_pocket = /obj/item/nursefather_phone
	l_pocket = /obj/item/apprentice_recruitment/thumb_nursefather

////////////////////////////////////////////////////////////
// NURSEFATHER PHONE - Ammo requisition device
//
// A suspicious phone that lets the Ex Thumb Sottocapo order additional
// boxes of acceleration propellant ammunition for 1500 ahn.
////////////////////////////////////////////////////////////

/obj/item/nursefather_phone
	name = "suspicious phone"
	desc = "A heavily encrypted phone used by Thumb operatives to place discreet supply orders. The contact list has a single entry labeled 'Procurement'."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "suspiciousphone"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/nursefather_phone/attack_self(mob/living/user)
	. = ..()
	if(!isliving(user))
		return

	var/obj/item/card/id/C = user.get_idcard(TRUE)
	if(!C)
		to_chat(user, span_warning("You need an ID card to place an order."))
		return
	if(!C.registered_account)
		to_chat(user, span_warning("Your ID card has no registered bank account."))
		return

	var/datum/bank_account/account = C.registered_account
	var/cost = 1500

	if(!account.has_money(cost))
		to_chat(user, span_warning("Insufficient funds. You need [cost] ahn to order ammunition. You have [account.account_balance] ahn."))
		playsound(src, 'sound/machines/buzz-two.ogg', 25, TRUE)
		return

	// Confirm the purchase
	var/confirm = tgui_alert(user, "Order a box of acceleration propellant ammunition for [cost] ahn? (Balance: [account.account_balance] ahn)", "Ammunition Requisition", list("Confirm", "Cancel"))
	if(confirm != "Confirm")
		return
	// Re-check after the alert (user could have moved, spent money, etc.)
	if(!Adjacent(user) || QDELETED(src) || QDELETED(user))
		return
	if(!account.has_money(cost))
		to_chat(user, span_warning("Insufficient funds."))
		playsound(src, 'sound/machines/buzz-two.ogg', 25, TRUE)
		return

	account.adjust_money(-cost)
	var/obj/item/storage/box/thumb_east_ammo/acceleration/ammo_box = new(get_turf(user))
	if(!user.put_in_hands(ammo_box))
		ammo_box.forceMove(get_turf(user))
	playsound(src, 'sound/effects/cashregister.ogg', 25, TRUE)
	to_chat(user, span_notice("Order confirmed. A box of acceleration propellant ammunition has been delivered. Remaining balance: [account.account_balance] ahn."))

/obj/item/nursefather_phone/examine(mob/user)
	. = ..()
	. += span_notice("Use in-hand to order a box of acceleration propellant ammunition for <b>1500 ahn</b>.")

////////////////////////////////////////////////////////////
// THUMB APPRENTICE RECRUITMENT SCROLL
/obj/item/apprentice_recruitment/thumb_nursefather
	name = "thumb apprenticeship scroll"
	desc = "A scroll that allows you to recruit an apprentice into the Thumb's spider house."

/obj/item/apprentice_recruitment/thumb_nursefather/get_offer_text(mob/living/user)
	return "[user] is offering to make you their Thumb Apprentice. Do you accept?"

/obj/item/apprentice_recruitment/thumb_nursefather/get_offer_title()
	return "Apprenticeship Offer"

/obj/item/apprentice_recruitment/thumb_nursefather/recruit_apprentice(mob/living/carbon/human/H, mob/living/user)
	// Set attributes to 40 all
	H.set_attribute_limit(200)

	var/datum/attribute/fort = H.attributes[FORTITUDE_ATTRIBUTE]
	var/datum/attribute/prud = H.attributes[PRUDENCE_ATTRIBUTE]
	var/datum/attribute/temp = H.attributes[TEMPERANCE_ATTRIBUTE]
	var/datum/attribute/just = H.attributes[JUSTICE_ATTRIBUTE]

	if(fort)
		fort.level = 40
		fort.on_update(H)
	if(prud)
		prud.level = 40
		prud.on_update(H)
	if(temp)
		temp.level = 40
		temp.on_update(H)
	if(just)
		just.level = 40
		just.on_update(H)

	// Give armor (tier 1)
	var/obj/item/clothing/suit/armor/ego_gear/city/thumb_spider/apprentice/armor = new(H.loc)
	H.put_in_hands(armor)

	// Give weapons (tier 1)
	var/obj/item/ego_weapon/city/thumbapprentice_katana/katana = new(H.loc)
	H.put_in_hands(katana)
	var/obj/item/ego_weapon/city/thumbapprentice_greatsword/greatsword = new(H.loc)
	H.put_in_hands(greatsword)

	// Update ID card
	update_id_card(H, "Thumb Apprentice")

	// Update mind role
	if(H.mind)
		H.mind.assigned_role = "Thumb Apprentice"

	// Add traits
	ADD_TRAIT(H, TRAIT_COMBATFEAR_IMMUNE, "thumb_apprentice")
	ADD_TRAIT(H, TRAIT_WORK_FORBIDDEN, "thumb_apprentice")

	// Feedback
	to_chat(user, span_notice("You have recruited [H] as your apprentice."))
	playsound(get_turf(H), 'sound/abnormalities/onesin/bless.ogg', 50, 0, 4)

	to_chat(H, span_userdanger("You have become a Thumb Apprentice!"))
	to_chat(H, span_boldnotice("You are now an apprentice of [user], a former Sottocapo of the Thumb's spider house. \
		You have been given a katana and greatsword, along with apprentice armor. \
		Your gear will grow stronger as you do."))
	to_chat(H, span_boldwarning("Follow the orders of your mentor. Act in the Thumb's interest."))
