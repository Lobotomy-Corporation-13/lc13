// The counter you buy a policy at, renew it at, cancel it at, and settle a debt
// at. The Director can also write one off from here.
//
// Buying wants a registered ID card in hand; nothing else here does. Opening an
// account is the one moment the company insists on seeing who you are, and from
// then on it has your number and bills you off the ledger - so a client with no
// wallet, or one rebuilt out of a brain, can still keep their cover current.
//
// Company staff get a different screen entirely. They are not customers - the
// clinic does not sell to its own payroll - so what the terminal shows them is
// the book: who has signed up, for what, and who is behind on it. The Director
// is a member of staff who can also close an account.

/// Every terminal on the map, so the scanner gate can point a debtor at the
/// nearest one.
GLOBAL_LIST_EMPTY(mirae_terminals)

/obj/machinery/mirae_terminal
	name = "mirae policy terminal"
	desc = "A payment kiosk in company brown. The screen lists what you are \
		covered for; the slot underneath is for what you are not."
	icon = 'ModularLobotomy/_Lobotomyicons/mirae.dmi'
	icon_state = "mirae_terminal"
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE
	idle_power_usage = 0
	active_power_usage = 0

/obj/machinery/mirae_terminal/Initialize(mapload)
	. = ..()
	GLOB.mirae_terminals += src

/obj/machinery/mirae_terminal/power_change()
	. = ..()
	MiraeSelfPowered(src)

/obj/machinery/mirae_terminal/Destroy()
	GLOB.mirae_terminals -= src
	return ..()

/obj/machinery/mirae_terminal/update_icon_state()
	icon_state = (machine_stat & (BROKEN|NOPOWER)) ? "mirae_terminal_off" : "mirae_terminal"
	return ..()

/obj/machinery/mirae_terminal/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MiraeTerminal")
		ui.open()

/obj/machinery/mirae_terminal/ui_state()
	return GLOB.default_state

/// The price list never changes, so it is sent once rather than every tick.
/obj/machinery/mirae_terminal/ui_static_data(mob/user)
	var/list/data = list()
	// Price and renewal are the same figure. Both are sent anyway, so the
	// interface never has to know that and a split price is one edit away.
	data["tiers"] = list(
		list("flag" = MIRAE_ADDON_DEATH, "name" = "Death Insurance",
			"cost" = MIRAE_PRICE_DEATH, "premium" = MIRAE_PRICE_DEATH,
			"desc" = "We are told the moment you die, we can find you, and \
				neither resuscitation nor reclamation costs you anything."),
		list("flag" = MIRAE_ADDON_BASIC, "name" = "Basic Treatment",
			"cost" = MIRAE_PRICE_BASIC, "premium" = MIRAE_PRICE_BASIC,
			"desc" = "[MIRAE_BASIC_INJECTIONS] sleeper treatments a period at no \
				charge, and wound tending free as often as you need it."),
		list("flag" = MIRAE_ADDON_SURGERY, "name" = "Surgery",
			"cost" = MIRAE_PRICE_SURGERY, "premium" = MIRAE_PRICE_SURGERY,
			"desc" = "Wound tending comes with Basic Treatment instead. This \
				covers the rest:",
			"covers" = MiraeCoveredSurgeries()),
	)
	data["period"] = MIRAE_UPKEEP_INTERVAL
	return data

/obj/machinery/mirae_terminal/ui_data(mob/user)
	var/list/data = list()
	var/staff = MiraeIsStaff(user)
	data["is_staff"] = staff
	data["is_director"] = (user.mind?.assigned_role == "Clinic Director")
	// Staff never see their own figures, because none of the buttons that act
	// on them are offered. Sending the numbers anyway would put a balance on a
	// screen that has nothing to spend it on.
	if(staff)
		data["clients"] = BuildRoster()
		return data
	var/datum/mirae_ledger/L = MiraeLedgerFor(user)
	var/datum/bank_account/A = L?.GetAccount()
	data["balance"] = A ? A.account_balance : 0
	data["has_account"] = !isnull(A)
	data["debt"] = L ? L.debt : 0
	data["held"] = L?.policy ? L.policy.addons : 0
	data["policy_state"] = L?.policy ? L.policy.state : 0
	data["premium"] = L?.policy ? L.policy.premium : 0
	data["covered_left"] = L?.policy ? L.policy.covered_injections : 0
	data["due"] = L?.policy ? L.policy.TimeToDue() : 0
	data["cancelled"] = L?.policy ? L.policy.cancelled : FALSE
	// A card is only wanted to open an account. Shown so somebody who left
	// theirs at home knows that is the reason the buttons are dead.
	data["has_card"] = !isnull(PayCard(user))
	return data

/// The registered card they are holding or wearing, if any.
/obj/machinery/mirae_terminal/proc/PayCard(mob/living/user)
	var/obj/item/card/id/card = user?.get_idcard(TRUE)
	return card?.registered_account

/// Every account the company has opened, plus anyone who owes it money without
/// ever having opened one. Both belong on the book: a debtor with no policy is
/// still a name the clinic has to chase.
/obj/machinery/mirae_terminal/proc/BuildRoster()
	var/list/out = list()
	for(var/datum/mirae_ledger/other in SSmirae.ledgers)
		if(!other.policy && other.debt <= 0)
			continue
		out += list(list(
			"name" = other.holder_name,
			"held" = other.policy ? other.policy.addons : 0,
			"state" = other.policy ? other.policy.state : 0,
			"premium" = other.policy ? other.policy.premium : 0,
			"due" = other.policy ? other.policy.TimeToDue() : 0,
			"cancelled" = other.policy ? other.policy.cancelled : FALSE,
			"debt" = other.debt,
			"ref" = REF(other),
		))
	return out

/obj/machinery/mirae_terminal/ui_act(action, params)
	. = ..()
	if(.)
		return
	var/mob/living/user = usr
	if(!isliving(user))
		return
	// Refused here as well as hidden in the interface. The panels are gone from
	// a staff member's screen, but ui_act is reachable without them.
	if(MiraeIsStaff(user) && action != "writeoff")
		to_chat(user, span_warning("The terminal will not sell to its own staff."))
		return TRUE
	var/datum/mirae_ledger/L = MiraeLedgerFor(user)
	if(!L)
		return
	switch(action)
		if("buy")
			var/wanted = text2num(params["flags"])
			if(!wanted)
				return
			var/datum/bank_account/payer = PayCard(user)
			if(!payer)
				to_chat(user, span_warning("The reader wants a registered ID card to open an account."))
				return TRUE
			if(L.BuyPolicy(wanted, payer))
				playsound(src, 'sound/machines/twobeep_high.ogg', 50, TRUE)
			else
				to_chat(user, span_warning("The terminal refuses the transaction."))
			return TRUE
		if("renew")
			if(!L.policy)
				to_chat(user, span_warning("You have no policy to pay on."))
				return TRUE
			if(L.policy.Renew(1))
				playsound(src, 'sound/machines/twobeep_high.ogg', 50, TRUE)
			else
				to_chat(user, span_warning("Insufficient funds."))
			return TRUE
		if("cancel")
			if(!L.policy)
				return TRUE
			L.policy.SetCancelled(!L.policy.cancelled)
			playsound(src, 'sound/machines/click.ogg', 50, TRUE)
			return TRUE
		if("settle")
			var/amount = text2num(params["amount"])
			if(!L.PayDebt(amount))
				to_chat(user, span_warning("Insufficient funds."))
			else
				playsound(src, 'sound/machines/twobeep_high.ogg', 50, TRUE)
			return TRUE
		if("writeoff")
			if(user.mind?.assigned_role != "Clinic Director")
				return
			var/datum/mirae_ledger/target = locate(params["ref"]) in SSmirae.ledgers
			if(!target)
				return
			if(target.WriteOff())
				to_chat(user, span_nicegreen("[target.holder_name]'s balance is cleared."))
			return TRUE
