// The threshold between the front of house and the ward. Anyone may walk in
// off the street and talk to the company; nobody walks past reception into
// treatment owing it money.

#define MIRAE_GATE_PROMPT_CD (8 SECONDS)

/obj/machinery/scanner_gate/mirae
	name = "mirae accounts gate"
	desc = "A archway with a card reader on the post. It does not care whether \
		you have the card."
	density = FALSE
	locked = TRUE
	use_power = NO_POWER_USE
	idle_power_usage = 0
	active_power_usage = 0
	COOLDOWN_DECLARE(prompt_cd)

/obj/machinery/scanner_gate/mirae/power_change()
	. = ..()
	MiraeSelfPowered(src)

// The stock scan modes are about contraband and species. This one has exactly
// one question, so the whole scanning pipeline is switched off rather than
// configured.
/obj/machinery/scanner_gate/mirae/auto_scan(atom/movable/AM)
	return

/obj/machinery/scanner_gate/mirae/attackby(obj/item/I, mob/user, params)
	return

/obj/machinery/scanner_gate/mirae/emag_act(mob/user)
	return

/// Decides, and nothing else. This runs inside Move() and is expected to be
/// pure, so it must not sleep, chat or play a sound - all of which the
/// settlement prompt does. That lives in Bumped().
/obj/machinery/scanner_gate/mirae/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(!.)
		return
	if(!ishuman(mover))
		return
	if(machine_stat & (BROKEN|NOPOWER))
		return
	if(MiraeDebtOf(mover) <= 0)
		return
	return FALSE

/obj/machinery/scanner_gate/mirae/Bumped(atom/movable/AM)
	. = ..()
	if(!ishuman(AM) || MiraeDebtOf(AM) <= 0)
		return
	if(!COOLDOWN_FINISHED(src, prompt_cd))
		return
	COOLDOWN_START(src, prompt_cd, MIRAE_GATE_PROMPT_CD)
	set_scanline("scanning", 5)
	alarm_beep()
	INVOKE_ASYNC(src, PROC_REF(OfferSettlement), AM)

/obj/machinery/scanner_gate/mirae/proc/OfferSettlement(mob/living/carbon/human/H)
	var/datum/mirae_ledger/L = MiraeLedgerFor(H)
	if(!L || L.debt <= 0)
		return
	// Identity is the mind and the account number is on the ledger, so this
	// works whether or not they are carrying their ID.
	var/datum/bank_account/A = L.GetAccount()
	if(!A)
		to_chat(H, span_warning("[src] finds no account in your name. You owe \
			[L.debt] ahn and cannot settle it here - find the Director."))
		return
	if(!A.has_money(L.debt))
		to_chat(H, span_warning("[src] declines your account. Outstanding: \
			[L.debt] ahn, available: [A.account_balance]. [NearestTerminal(H)]"))
		return
	var/choice = tgui_alert(H, "Mirae Life Insurance is owed [L.debt] ahn. \
		Settle now?", "Accounts Gate", list("Pay", "Not now"))
	if(choice != "Pay")
		to_chat(H, span_warning("[NearestTerminal(H)]"))
		return
	if(L.PayDebt(L.debt))
		playsound(src, 'sound/machines/twobeep_high.ogg', 50, TRUE)
		set_scanline("passive", 5)

/// Which way the nearest terminal is, for somebody who cannot pay here.
/obj/machinery/scanner_gate/mirae/proc/NearestTerminal(mob/living/H)
	var/obj/machinery/mirae_terminal/best
	var/best_dist = INFINITY
	for(var/obj/machinery/mirae_terminal/T in GLOB.mirae_terminals)
		var/d = get_dist(H, T)
		if(d < best_dist)
			best = T
			best_dist = d
	if(!best)
		return "There is no terminal on file."
	return "The nearest terminal is [best_dist] metres [dir2text(get_dir(H, best))]."

#undef MIRAE_GATE_PROMPT_CD
