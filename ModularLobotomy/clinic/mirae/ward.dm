// The ward: the equipment that generates the bills, and the surgeries that do.
//
// The surgeries below are overrides on the stock types, not Mirae subtypes of
// them. A subtype would have shown up in the operating computer's list
// alongside the vanilla one it copied, and `replaced_by` cannot be set on a
// stock type from a modular file - so the patient would pick whichever of the
// two duplicates they liked and half of them would be free. Overriding
// complete() on the existing type has neither problem and adds no new surgery
// to the game.
//
// Because those overrides are global, every one of them is gated on the
// patient actually lying on the company's furniture. Without that a surgery
// performed on a back-alley floor in another district would bill Mirae debt
// for a service Mirae did not provide, which is both wrong and a way to
// saddle somebody with a balance they can never have consented to.

#define MIRAE_PRICE_INJECTION 100
#define MIRAE_PRICE_TENDING 250
#define MIRAE_PRICE_IMPLANT 400
#define MIRAE_PRICE_PROSTHETIC 600
#define MIRAE_PRICE_REVIVE 1000

/obj/machinery/sleeper/mirae
	name = "mirae treatment sleeper"
	desc = "A clinic sleeper with a card reader bolted to the headboard. The \
		reader is newer than the sleeper."
	icon = 'ModularLobotomy/_Lobotomyicons/mirae.dmi'
	icon_state = "mirae_sleeper"
	controls_inside = TRUE
	use_power = NO_POWER_USE
	idle_power_usage = 0
	active_power_usage = 0

/obj/machinery/sleeper/mirae/power_change()
	. = ..()
	MiraeSelfPowered(src)

/obj/machinery/sleeper/mirae/inject_chem(chem, mob/user)
	. = ..()
	if(!.)
		return
	// The parent injects a hardcoded ten units, so ten ahn a unit is a hundred
	// a press. Billed here rather than in ui_act so an emag or any other route
	// into inject_chem still charges.
	MiraeBill(occupant, MIRAE_PRICE_INJECTION, MIRAE_SERVICE_SLEEPER, src)

// The company defibrillator. It never runs out and it never gives anything
// away: bringing somebody back is the most expensive thing Mirae does for
// free, so the bill for doing it uninsured is the price of the policy that
// would have covered it.
/obj/item/defibrillator/mirae
	name = "mirae resuscitation unit"
	desc = "A defibrillator in company brown, sealed shut. The panel above the \
		dial reads CLAIM PENDING and does not clear."
	icon = 'ModularLobotomy/_Lobotomyicons/mirae.dmi'
	icon_state = "mirae_defib"
	inhand_icon_state = "mirae_defib"
	// The worn sprite is looked up by icon_state in the back slot's own sheet,
	// so it is named here as well rather than left to be inferred.
	worn_icon_state = "mirae_defib"
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_left.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_right.dmi'
	paddle_type = /obj/item/shockpaddles/mirae

/obj/item/defibrillator/mirae/Initialize()
	. = ..()
	cell = new /obj/item/stock_parts/cell/infinite(src)
	update_power()

// Sealed, the way the combat unit is. The parent lets a screwdriver lift the
// cell straight out, and an infinite cell loose in the round is worth a great
// deal more than the defibrillator it came out of.
/obj/item/defibrillator/mirae/attackby(obj/item/W, mob/user, params)
	if(W == paddles)
		toggle_paddles()

/obj/item/shockpaddles/mirae
	name = "mirae resuscitation paddles"
	desc = "Company paddles. Somewhere behind them a meter is running."
	icon = 'ModularLobotomy/_Lobotomyicons/mirae.dmi'
	icon_state = "mirae_paddles0"
	inhand_icon_state = "mirae_paddles0"
	base_icon_state = "mirae_paddles"
	lefthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_left.dmi'
	righthand_file = 'ModularLobotomy/_Lobotomyicons/lc13_right.dmi'

/// Billed on the difference the shock made, not on the shock.
///
/// do_help also restarts a stopped heart, and somebody whose heart stopped was
/// never dead - so comparing their state either side of the parent is what
/// separates a resuscitation the company can charge for from first aid it
/// cannot.
/obj/item/shockpaddles/mirae/do_help(mob/living/carbon/H, mob/living/user)
	var/was_dead = (H.stat == DEAD)
	. = ..()
	if(was_dead && H.stat != DEAD)
		MiraeBill(H, MIRAE_PRICE_REVIVE, MIRAE_SERVICE_REVIVE, src)

/obj/machinery/stasis/mirae
	name = "mirae stasis bed"
	desc = "A stasis bed on the company's inventory. Holding someone still is \
		free. Everything after that is not."
	icon = 'ModularLobotomy/_Lobotomyicons/mirae.dmi'
	icon_state = "mirae_stasis"
	mattress_state = "mirae_stasis_on"
	use_power = NO_POWER_USE
	idle_power_usage = 0
	active_power_usage = 0

/obj/machinery/stasis/mirae/power_change()
	. = ..()
	MiraeSelfPowered(src)

/// The parent writes the three vanilla state names in as string literals rather
/// than reading them off initial(icon_state), so a reskinned bed is reset to a
/// state its own sheet does not have the first time anything calls update_icon
/// - which power_change does before the round has started.
/obj/machinery/stasis/mirae/update_icon_state()
	if(machine_stat & BROKEN)
		icon_state = "mirae_stasis_broken"
		return
	if(panel_open || machine_stat & MAINT)
		icon_state = "mirae_stasis_maintenance"
		return
	icon_state = "mirae_stasis"

/obj/structure/table/optable/mirae
	name = "mirae operating table"
	desc = "Scrubbed steel with a claim number stencilled on the rail."
	icon = 'ModularLobotomy/_Lobotomyicons/mirae.dmi'
	icon_state = "mirae_optable"

/obj/machinery/computer/operating/mirae
	name = "mirae operating computer"
	desc = "Tracks the procedure and, more carefully, its cost."
	icon = 'ModularLobotomy/_Lobotomyicons/mirae.dmi'
	icon_state = "mirae_comp"
	icon_screen = "mirae_screen"
	icon_keyboard = "mirae_key"
	use_power = NO_POWER_USE
	idle_power_usage = 0
	active_power_usage = 0

/obj/machinery/computer/operating/mirae/power_change()
	. = ..()
	MiraeSelfPowered(src)

/// Whether a patient is on Mirae's own bed, table or sleeper.
///
/// The optable never contains anyone - a patient is simply a mob resting on
/// its turf - while the stasis bed buckles and the sleeper holds. All three
/// have to be asked differently.
/proc/MiraeOnCompanyBed(mob/living/target)
	if(!target)
		return FALSE
	if(istype(target.buckled, /obj/machinery/stasis/mirae))
		return TRUE
	if(istype(target.loc, /obj/machinery/sleeper/mirae))
		return TRUE
	var/turf/T = get_turf(target)
	if(!T)
		return FALSE
	if(locate(/obj/structure/table/optable/mirae) in T)
		return TRUE
	if(locate(/obj/machinery/stasis/mirae) in T)
		return TRUE
	return FALSE

/// Bill for a completed procedure, if the company was the one providing it.
///
/// Called before the parent complete(), never after: that qdels the surgery
/// and Destroy() nulls `target`, so billing afterwards is a null dereference
/// at the exact moment of payment.
/proc/MiraeBillSurgery(datum/surgery/S, amount, tag = MIRAE_SERVICE_SURGERY)
	if(!S?.target || !MiraeOnCompanyBed(S.target))
		return
	MiraeBill(S.target, amount, tag, null)

/// The procedures the Surgery tier waives, with what each costs without it.
///
/// Kept beside the complete() overrides below, because the two have to agree:
/// a procedure that bills and is missing from here is one a client paid for
/// after being told it was covered. Names are read off the surgery singletons
/// rather than restated, so a renamed procedure renames itself on the terminal.
/proc/MiraeCoveredSurgeries()
	var/list/priced = list(
		/datum/surgery/organ_manipulation = MIRAE_PRICE_PROSTHETIC,
		/datum/surgery/prosthetic_replacement = MIRAE_PRICE_PROSTHETIC,
		/datum/surgery/implant_removal = MIRAE_PRICE_IMPLANT,
	)
	var/list/out = list()
	for(var/datum/surgery/S in GLOB.surgeries_list)
		if(!(S.type in priced))
			continue
		out += list(list("name" = S.name, "cost" = priced[S.type]))
	return out

// Tending wounds. Overriding the parent covers brute, burn and combo and all
// their upgraded variants in one place, which is also why the price is flat.
// Tagged as tending rather than as surgery, so Basic Treatment waives it and
// the Surgery tier is left selling the invasive work below.
/datum/surgery/healing/complete()
	MiraeBillSurgery(src, MIRAE_PRICE_TENDING, MIRAE_SERVICE_TENDING)
	return ..()

/datum/surgery/revival/complete()
	MiraeBillSurgery(src, MIRAE_PRICE_REVIVE)
	return ..()

/datum/surgery/organ_manipulation/complete()
	MiraeBillSurgery(src, MIRAE_PRICE_PROSTHETIC)
	return ..()

/datum/surgery/prosthetic_replacement/complete()
	MiraeBillSurgery(src, MIRAE_PRICE_PROSTHETIC)
	return ..()

/datum/surgery/implant_removal/complete()
	MiraeBillSurgery(src, MIRAE_PRICE_IMPLANT)
	return ..()

#undef MIRAE_PRICE_INJECTION
#undef MIRAE_PRICE_TENDING
#undef MIRAE_PRICE_IMPLANT
#undef MIRAE_PRICE_PROSTHETIC
#undef MIRAE_PRICE_REVIVE
