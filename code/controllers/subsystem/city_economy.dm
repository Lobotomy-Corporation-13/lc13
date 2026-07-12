// City Economy Subsystem - Handles tax collection and bounties
SUBSYSTEM_DEF(city_economy)
	name = "City Economy"
	wait = 15 MINUTES // Tax collection every 15 minutes
	priority = FIRE_PRIORITY_DEFAULT
	flags = SS_BACKGROUND
	runlevels = RUNLEVEL_GAME

	var/base_tax_amount = 200 // Base tax amount for grade 9
	var/tax_per_grade = 50 // Additional tax per grade improvement
	var/list/bounties = list() // Assoc list of ckey = bounty datum
	var/list/strikes = list() // Track missed tax payments per ckey
	var/list/player_balances = list() // Track player ahn balances
	var/list/early_tax_paid = list() // Track players who paid tax early
	var/list/taxed_offices = list() // Track which offices have been taxed this cycle
	var/next_tax_time = 0
	var/tax_cycle = 1

/datum/controller/subsystem/city_economy/Initialize(timeofday)
	// Only run on fixers maptype
	if(SSmaptype.maptype != "fixers")
		can_fire = FALSE
		return ..()

	next_tax_time = world.time + wait
	return ..()

/datum/controller/subsystem/city_economy/fire(resumed = FALSE)
	collect_tax()
	tax_cycle++
	// Clear early tax payments and taxed offices after collection
	early_tax_paid.Cut()
	taxed_offices.Cut()

/datum/controller/subsystem/city_economy/proc/collect_tax()
	// Announce tax collection via newscasters
	for(var/obj/machinery/newscaster/N in GLOB.allCasters)
		N.say("Tax collection in progress. Amount varies by fixer grade.")

	// First, tax all offices
	for(var/datum/fixer_office/office in GLOB.all_fixer_offices)
		process_office_tax(office)

	// Then, tax individual players not in offices
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(!H.client || !H.mind)
			continue

		// Skip unregistered fixers
		if(!H.mind.registered_fixer)
			continue

		// Check if player is in an office
		var/in_office = FALSE
		for(var/datum/fixer_office/F in GLOB.all_fixer_offices)
			if(H in F.members)
				in_office = TRUE
				break

		// Only process solo fixers
		if(!in_office)
			process_tax_payment(H)

	// Update next tax time
	next_tax_time = world.time + wait

/datum/controller/subsystem/city_economy/proc/process_office_tax(datum/fixer_office/office)
	if(!office || (office in taxed_offices))
		return

	// Check if director is online and alive
	if(!office.director || !office.director.client || !office.director.mind)
		return // No director online, skip tax collection

	// Skip if director is dead
	if(office.director.stat == DEAD)
		return

	// Check if director is a registered fixer
	if(!office.director.mind.registered_fixer)
		return // Director not registered, skip tax collection

	// Get online and alive members for notifications
	var/list/online_members = list()
	for(var/mob/living/carbon/human/member in office.members)
		if(member.client && member.mind && member.stat != DEAD)
			online_members += member

	// Check if director paid early
	if(office.director.ckey in early_tax_paid)
		for(var/mob/living/carbon/human/member in online_members)
			to_chat(member, span_notice("Your office tax was already paid early this cycle."))
		taxed_offices += office
		return

	// Calculate office tax based on average grade of online members
	var/total_grade = 0
	var/member_count = 0
	for(var/mob/living/carbon/human/member in online_members)
		var/member_grade = calculate_fixer_grade(member)
		total_grade += member_grade
		member_count++

	var/average_grade = round(total_grade / member_count)
	var/tax_amount = base_tax_amount + ((9 - average_grade) * tax_per_grade)

	// Try to collect tax from director only
	var/tax_paid = try_collect_tax(office.director, tax_amount, office)

	if(!tax_paid)
		// Director couldn't pay - apply bounty to director only (apply_bounty handles messaging)
		apply_bounty(office.director, tax_amount, office)

	taxed_offices += office

/datum/controller/subsystem/city_economy/proc/try_collect_tax(mob/living/carbon/human/H, amount, datum/fixer_office/office = null)
	// Only check bank account - not cash on hand
	var/obj/item/card/id/player_id = H.get_idcard()
	if(player_id?.registered_account)
		var/datum/bank_account/account = player_id.registered_account
		if(account.adjust_money(-amount))
			if(office)
				account.bank_card_talk("Office tax of [amount] Ahn has been collected for [office.name].")
				for(var/mob/living/carbon/human/member in office.members)
					if(member.client)
						to_chat(member, span_notice("Office tax of [amount] Ahn has been paid by [H.real_name]."))
			else
				account.bank_card_talk("City tax of [amount] Ahn has been collected.")
				to_chat(H, span_notice("Tax of [amount] Ahn has been collected from your bank account."))
			// Transfer to city budget
			var/datum/bank_account/department/city_account = SSeconomy.get_dep_account(ACCOUNT_CIV)
			if(city_account)
				city_account.adjust_money(amount)
			return TRUE

	return FALSE

/datum/controller/subsystem/city_economy/proc/process_tax_payment(mob/living/carbon/human/H)
	// For solo fixers only
	// Skip dead players
	if(H.stat == DEAD)
		return

	// Check if player paid early
	if(H.ckey in early_tax_paid)
		to_chat(H, span_notice("Tax already paid early this cycle."))
		return

	// Calculate tax for solo fixer
	var/grade = calculate_fixer_grade(H)
	var/tax_amount = base_tax_amount + ((9 - grade) * tax_per_grade)

	// Try to collect tax
	if(!try_collect_tax(H, tax_amount))
		// Can't pay - apply bounty (apply_bounty handles messaging)
		apply_bounty(H, tax_amount)

/datum/controller/subsystem/city_economy/proc/apply_bounty(mob/living/carbon/human/H, amount, datum/fixer_office/office = null)
	if(!H.ckey)
		return

	// Increment strike counter
	if(!strikes[H.ckey])
		strikes[H.ckey] = 0
	strikes[H.ckey]++

	// First strike - warning only, no bounty
	if(strikes[H.ckey] == 1)
		if(office)
			for(var/mob/living/carbon/human/member in office.members)
				if(member.client)
					to_chat(member, span_boldwarning("WARNING: The office director failed to pay tax of [amount] Ahn! This is their first strike. Another missed payment will result in a bounty!"))
		else
			to_chat(H, span_boldwarning("WARNING: You failed to pay tax of [amount] Ahn! This is your first strike. Miss payment again and a bounty will be placed on your head!"))
		for(var/obj/machinery/newscaster/N in GLOB.allCasters)
			N.say("[H.real_name] has missed a tax payment! One more miss and they will have a bounty!")
		return

	// Second+ strike - apply bounty
	var/datum/city_bounty/B = bounties[H.ckey]
	if(!B)
		B = new /datum/city_bounty()
		B.target = H
		B.target_ckey = H.ckey
		bounties[H.ckey] = B

	B.debt_amount += amount
	B.bounty_placed_time = world.time
	B.apply_bounty_effects()

	// Notify about bounty being placed
	if(office)
		for(var/mob/living/carbon/human/member in office.members)
			if(member.client)
				to_chat(member, span_boldwarning("The office director failed to pay tax of [amount] Ahn! A bounty of [B.debt_amount * 10] Ahn has been placed on the director!"))
	else
		to_chat(H, span_boldwarning("You failed to pay tax of [amount] Ahn! A bounty of [B.debt_amount * 10] Ahn has been placed on your head!"))

	// Announce via newscasters
	for(var/obj/machinery/newscaster/N in GLOB.allCasters)
		N.say("[H.real_name] has failed to pay taxes and now has a bounty of [B.debt_amount * 10] Ahn!")

/datum/controller/subsystem/city_economy/proc/clear_bounty(mob/living/carbon/human/H)
	if(!H.ckey || !bounties[H.ckey])
		return

	var/datum/city_bounty/B = bounties[H.ckey]
	B.clear_bounty()
	bounties -= H.ckey
	strikes -= H.ckey
	qdel(B)

/datum/controller/subsystem/city_economy/proc/check_bounty(mob/living/carbon/human/H)
	if(!H.ckey)
		return null
	return bounties[H.ckey]

/datum/controller/subsystem/city_economy/proc/get_time_until_tax()
	return max(0, next_tax_time - world.time)

// City Bounty Datum
/datum/city_bounty
	var/mob/living/carbon/human/target
	var/target_ckey
	var/debt_amount = 0
	var/bounty_placed_time
	var/obj/effect/proc_holder/spell/targeted/bounty_mark/mark_spell

/datum/city_bounty/proc/apply_bounty_effects()
	if(!target)
		return

	// Add visual indicator
	target.add_overlay(mutable_appearance('icons/effects/effects.dmi', "hyde", -HALO_LAYER))

	// Give them a spell-like indicator in their UI
	if(!mark_spell)
		mark_spell = new
		mark_spell.bounty_datum = src
		target.AddSpell(mark_spell)

/datum/city_bounty/proc/clear_bounty()
	if(!target)
		return

	// Remove visual effects
	target.cut_overlay(mutable_appearance('icons/effects/effects.dmi', "hyde", -HALO_LAYER))

	// Remove spell indicator
	if(mark_spell)
		target.RemoveSpell(mark_spell)
		qdel(mark_spell)
		mark_spell = null

	to_chat(target, span_nicegreen("Your bounty has been cleared!"))

/datum/city_bounty/proc/on_bounty_death()
	if(!target)
		return

	// Check minimum stat threshold
	var/total_stats = 0
	total_stats += get_attribute_level(target, FORTITUDE_ATTRIBUTE)
	total_stats += get_attribute_level(target, PRUDENCE_ATTRIBUTE)
	total_stats += get_attribute_level(target, TEMPERANCE_ATTRIBUTE)
	total_stats += get_attribute_level(target, JUSTICE_ATTRIBUTE)

	// Need at least 80 total stats (20 in each) to drop cash
	if(total_stats >= 80)
		// Drop cash at corpse location - bounty is 10x debt
		var/bounty_amount = debt_amount * 10
		var/drop_amount = min(bounty_amount, 5000) // Cap at 5000 to prevent farming
		new /obj/item/holochip(get_turf(target), drop_amount)

		// Apply stat penalty
		target.adjust_attribute_level(FORTITUDE_ATTRIBUTE, -20)
		target.adjust_attribute_level(PRUDENCE_ATTRIBUTE, -20)
		target.adjust_attribute_level(TEMPERANCE_ATTRIBUTE, -20)
		target.adjust_attribute_level(JUSTICE_ATTRIBUTE, -20)

		to_chat(target, span_userdanger("Your death with a bounty has weakened you! You lose 20 points from all attributes!"))
	else
		to_chat(target, span_warning("You were too weak to drop any cash from your bounty."))

	// Clear the bounty
	SScity_economy.clear_bounty(target)

// Spell-like indicator for bounty status
/obj/effect/proc_holder/spell/targeted/bounty_mark
	name = "Bounty Status"
	desc = "You have an unpaid debt. Pay it off or suffer the consequences!"
	icon_state = "bounty"
	charge_max = 0
	clothes_req = FALSE
	human_req = TRUE
	antimagic_allowed = TRUE
	action_background_icon_state = "bg_ecult_on"
	var/datum/city_bounty/bounty_datum

/obj/effect/proc_holder/spell/targeted/bounty_mark/cast(list/targets, mob/user = usr)
	if(!bounty_datum)
		return
	to_chat(user, span_warning("You currently owe [bounty_datum.debt_amount] Ahn. Pay at any payment kiosk to clear your bounty!"))

/datum/controller/subsystem/city_economy/proc/calculate_tax_for_player(mob/living/carbon/human/H)
	// This is now only used for display purposes and early payment
	// Check if player is in an office
	var/datum/fixer_office/player_office = null
	for(var/datum/fixer_office/F in GLOB.all_fixer_offices)
		if(H in F.members)
			player_office = F
			break

	if(player_office)
		// Calculate average grade for office
		var/total_grade = 0
		var/member_count = 0
		for(var/mob/living/carbon/human/member in player_office.members)
			if(!member.client || !member.mind) // Skip offline members
				continue
			var/member_grade = calculate_fixer_grade(member)
			total_grade += member_grade
			member_count++

		if(member_count > 0)
			var/average_grade = round(total_grade / member_count)
			return base_tax_amount + ((9 - average_grade) * tax_per_grade)

	// Solo fixer - use individual grade
	var/grade = calculate_fixer_grade(H)
	return base_tax_amount + ((9 - grade) * tax_per_grade)

// Copy of grade calculation from fixer_grade_terminal
/datum/controller/subsystem/city_economy/proc/calculate_fixer_grade(mob/living/carbon/human/H)
	var/list/stats = list(
		FORTITUDE_ATTRIBUTE,
		PRUDENCE_ATTRIBUTE,
		TEMPERANCE_ATTRIBUTE,
		JUSTICE_ATTRIBUTE,
	)

	var/stattotal = 0
	for(var/attribute in stats)
		stattotal += get_attribute_level(H, attribute)

	stattotal /= 4
	var/grade_offset = round(stattotal / 20)
	var/grade = 10 - grade_offset

	return clamp(grade, 1, 9)
