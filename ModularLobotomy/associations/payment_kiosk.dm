// Payment Kiosk for taxes and clearing bounties
/obj/machinery/payment_kiosk
	name = "City Payment Kiosk"
	desc = "A terminal for paying taxes and clearing bounties. Access with your ID card. Only registered fixers are required to pay taxes, but in return they gain access to training ampules."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "dispenser"
	density = TRUE
	anchored = TRUE
	var/processing_payment = FALSE

/obj/machinery/payment_kiosk/Initialize()
	. = ..()
	if(SSmaptype.maptype != "fixers")
		return INITIALIZE_HINT_QDEL

/obj/machinery/payment_kiosk/ui_interact(mob/user)
	. = ..()
	if(!ishuman(user))
		to_chat(user, span_warning("This machine can only be used by humans!"))
		return

	var/mob/living/carbon/human/H = user
	if(!H.ckey || !SScity_economy)
		return

	var/datum/city_bounty/bounty = SScity_economy.check_bounty(H)

	var/dat = "<B>City Payment Terminal</B><BR><BR>"

	dat += "<I>Note: Only registered fixers are required to pay taxes. In return, registered fixers gain access to training ampules. Register at a Fixer Grade Terminal.</I><BR><BR>"

	if(bounty)
		dat += "<B><FONT COLOR='red'>OUTSTANDING BOUNTY</FONT></B><BR>"
		dat += "Amount Owed: [bounty.debt_amount] Ahn<BR>"
		dat += "Time Since Bounty: [round((world.time - bounty.bounty_placed_time) / 600)] minutes<BR><BR>"
		dat += "<A href='byond://?src=[REF(src)];pay_bounty=1'>Pay Full Amount</A><BR>"
		dat += "<A href='byond://?src=[REF(src)];partial_payment=1'>Make Partial Payment</A><BR>"
	else
		dat += "<FONT COLOR='green'>No outstanding bounties.</FONT><BR>"
		dat += "You are in good standing with the city.<BR>"
	
	// Show next tax info
	var/time_until_tax = SScity_economy.get_time_until_tax()
	if(time_until_tax > 0)
		var/minutes = round(time_until_tax / 600)
		var/seconds = round((time_until_tax % 600) / 10)
		var/expected_tax = SScity_economy.calculate_tax_for_player(H)
		dat += "<BR><B>Next Tax Due In: [minutes]:[seconds < 10 ? "0[seconds]" : seconds]</B><BR>"
		dat += "Expected Tax Amount: [expected_tax] Ahn<BR>"
		
		// Check if player is in an office
		var/datum/fixer_office/player_office = null
		for(var/datum/fixer_office/F in GLOB.all_fixer_offices)
			if(H in F.members)
				player_office = F
				break
		
		// Check bank balance
		var/obj/item/card/id/player_id = H.get_idcard()
		if(player_id?.registered_account)
			dat += "Bank Balance: [player_id.registered_account.account_balance] Ahn<BR>"
		
		if(player_office && player_office.director != H)
			dat += "<I>Only the office representative can pay taxes for the office.</I><BR>"
		else
			dat += "<A href='byond://?src=[REF(src)];pay_tax_early=1'>Pay Tax Early</A><BR>"

	dat += "<BR><A href='byond://?src=[REF(src)];check_balance=1'>Check Ahn Balance</A><BR>"
	dat += "<BR><A href='byond://?src=[REF(user)];mach_close=payment_kiosk'>Exit</A>"

	var/datum/browser/popup = new(user, "payment_kiosk", "Payment Terminal", 400, 300)
	popup.set_content(dat)
	popup.open()

/obj/machinery/payment_kiosk/Topic(href, href_list)
	if(..())
		return

	var/mob/living/carbon/human/H = usr
	if(!ishuman(H) || !H.ckey)
		return

	if(href_list["check_balance"])
		var/total_ahn = 0
		for(var/obj/item/holochip/chip in H.contents)
			total_ahn += chip.credits
		for(var/obj/item/stack/spacecash/cash in H.contents)
			total_ahn += cash.value * cash.amount
		
		// Also show bank balance
		var/obj/item/card/id/player_id = H.get_idcard()
		if(player_id?.registered_account)
			to_chat(H, span_notice("Bank Balance: [player_id.registered_account.account_balance] Ahn"))
		
		to_chat(H, span_notice("Cash on Hand: [total_ahn] Ahn"))
		ui_interact(H)
		return

	if(href_list["pay_tax_early"])
		if(processing_payment)
			to_chat(H, span_warning("Payment already in progress!"))
			return
		
		// Check if player is in an office
		var/datum/fixer_office/player_office = null
		for(var/datum/fixer_office/F in GLOB.all_fixer_offices)
			if(H in F.members)
				player_office = F
				break
		
		// If in office but not representative, deny payment
		if(player_office && player_office.director != H)
			to_chat(H, span_warning("Only the office representative can pay taxes for the office!"))
			ui_interact(H)
			return
		
		var/tax_amount = SScity_economy.calculate_tax_for_player(H)
		processing_payment = TRUE
		
		// Try bank account first
		var/obj/item/card/id/player_id = H.get_idcard()
		var/paid = FALSE
		
		if(player_id?.registered_account)
			var/datum/bank_account/account = player_id.registered_account
			if(account.has_money(tax_amount))
				account.adjust_money(-tax_amount)
				account.bank_card_talk("Early tax payment of [tax_amount] Ahn processed.")
				// Transfer to city budget
				var/datum/bank_account/department/city_account = SSeconomy.get_dep_account(ACCOUNT_CIV)
				if(city_account)
					city_account.adjust_money(tax_amount)
				paid = TRUE
		
		// Fallback to cash
		if(!paid)
			paid = try_payment(H, tax_amount)
		
		if(paid)
			// Track that this player has paid tax early
			if(!SScity_economy.early_tax_paid)
				SScity_economy.early_tax_paid = list()
			SScity_economy.early_tax_paid[H.ckey] = world.time
			to_chat(H, span_nicegreen("Tax of [tax_amount] Ahn paid early! You will not be charged during the next collection cycle."))
			playsound(src, 'sound/machines/chime.ogg', 50, FALSE)
			
			// Announce via newscaster
			for(var/obj/machinery/newscaster/N in GLOB.allCasters)
				if(player_office)
					N.say("[player_office.name]'s representative [H.real_name] has paid their office taxes early. A model organization!")
				else
					N.say("[H.real_name] has paid their taxes early. A model citizen!")
		else
			to_chat(H, span_warning("Insufficient funds! You need [tax_amount] Ahn."))
		
		processing_payment = FALSE
		ui_interact(H)
		return
	
	var/datum/city_bounty/bounty = SScity_economy.check_bounty(H)
	
	if(href_list["pay_bounty"])
		if(!bounty)
			to_chat(H, span_notice("You have no bounty to pay."))
			return
		if(processing_payment)
			to_chat(H, span_warning("Payment already in progress!"))
			return

		processing_payment = TRUE
		var/paid = FALSE

		// Try bank account first
		var/obj/item/card/id/C = H.get_idcard(TRUE)
		if(C?.registered_account)
			var/datum/bank_account/account = C.registered_account
			if(account.adjust_money(-bounty.debt_amount))
				paid = TRUE
				account.bank_card_talk("Bounty payment of [bounty.debt_amount] Ahn processed.")

		// Fallback to cash
		if(!paid)
			paid = try_payment(H, bounty.debt_amount)

		if(paid)
			SScity_economy.clear_bounty(H)
			to_chat(H, span_nicegreen("Bounty cleared! You are now in good standing."))
			H.playsound_local(get_turf(src), 'sound/effects/cashregister.ogg', 25, 3, 3)
			// Announce via newscasters
			for(var/obj/machinery/newscaster/N in GLOB.allCasters)
				N.say("[H.real_name] has paid their debt and cleared their bounty.")
		else
			to_chat(H, span_warning("Insufficient funds! You need [bounty.debt_amount] Ahn."))
		processing_payment = FALSE
		ui_interact(H)

	else if(href_list["partial_payment"])
		if(!bounty)
			to_chat(H, span_notice("You have no bounty to pay."))
			return
		var/amount = input(H, "How much would you like to pay? (Debt: [bounty.debt_amount] Ahn)", "Partial Payment") as num|null
		if(!amount || amount <= 0)
			return

		if(processing_payment)
			to_chat(H, span_warning("Payment already in progress!"))
			return

		processing_payment = TRUE
		amount = min(amount, bounty.debt_amount) // Can't overpay
		var/paid = FALSE

		// Try bank account first
		var/obj/item/card/id/C = H.get_idcard(TRUE)
		if(C?.registered_account)
			var/datum/bank_account/account = C.registered_account
			if(account.adjust_money(-amount))
				paid = TRUE
				account.bank_card_talk("Partial bounty payment of [amount] Ahn processed.")

		// Fallback to cash
		if(!paid)
			paid = try_payment(H, amount)

		if(paid)
			bounty.debt_amount -= amount
			if(bounty.debt_amount <= 0)
				SScity_economy.clear_bounty(H)
				to_chat(H, span_nicegreen("Bounty cleared! You are now in good standing."))
				H.playsound_local(get_turf(src), 'sound/effects/cashregister.ogg', 25, 3, 3)
				// Announce via newscasters
				for(var/obj/machinery/newscaster/N in GLOB.allCasters)
					N.say("[H.real_name] has paid their debt and cleared their bounty.")
			else
				to_chat(H, span_notice("Payment of [amount] Ahn accepted. Remaining debt: [bounty.debt_amount] Ahn."))
				H.playsound_local(get_turf(src), 'sound/effects/cashregister.ogg', 25, 3, 3)
		else
			to_chat(H, span_warning("Insufficient funds!"))
		processing_payment = FALSE
		ui_interact(H)

/obj/machinery/payment_kiosk/proc/try_payment(mob/living/carbon/human/H, amount)
	var/total_ahn = 0

	// Count total money
	for(var/obj/item/holochip/chip in H.contents)
		total_ahn += chip.credits
	for(var/obj/item/stack/spacecash/cash in H.contents)
		total_ahn += cash.value * cash.amount

	if(total_ahn < amount)
		return FALSE

	// Deduct payment
	var/remaining = amount

	// First try holochips
	for(var/obj/item/holochip/chip in H.contents)
		if(remaining <= 0)
			break
		if(chip.credits >= remaining)
			chip.credits -= remaining
			if(chip.credits <= 0)
				qdel(chip)
			remaining = 0
		else
			remaining -= chip.credits
			qdel(chip)

	// Then try cash stacks
	for(var/obj/item/stack/spacecash/cash in H.contents)
		if(remaining <= 0)
			break
		var/stack_value = cash.value * cash.amount
		if(stack_value >= remaining)
			var/stacks_needed = CEILING(remaining / cash.value, 1)
			cash.use(stacks_needed)
			remaining = 0
		else
			remaining -= stack_value
			qdel(cash)

	return TRUE

/obj/machinery/payment_kiosk/update_icon_state()
	if(processing_payment)
		icon_state = "dispenser_working"
	else
		icon_state = "dispenser"
