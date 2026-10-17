// Mirae Life Insurance: the ledger, the subsystem that keeps it honest, and
// the one proc that moves money.
//
// Two keys, deliberately different. Identity is the mind, because a person
// rebuilt from a severed brain keeps theirs and a debt should follow the
// person. Money is a cached account number, because account_id is written in
// exactly one place - /datum/job/equip() - so a body built out of a brain has
// none, and reading it off the current mob would lose the client the moment
// they most owe us.

/// Runs after SSeconomy so bank accounts exist. Kept here rather than in
/// code/__DEFINES/subsystems.dm because nothing outside this feature reads it.
#define INIT_ORDER_MIRAE 39

/// Department id for the holding account. Deliberately not one of the real
/// ACCOUNT_* ids, so departmental_payouts() never grants it anything and it
/// stays out of the station's totals.
#define MIRAE_ACCOUNT_ID "MIRAE"

#define MIRAE_DEBT_MAX 10000
#define MIRAE_UPKEEP_INTERVAL (15 MINUTES)

// What a service is, for the purpose of deciding who covers it.
#define MIRAE_SERVICE_SLEEPER "sleeper"
// Tending wounds is a surgery, but it is the one a walk-in actually comes for,
// so it is tagged apart from the invasive procedures and sold with the sleeper
// rather than with them.
#define MIRAE_SERVICE_TENDING "tending"
#define MIRAE_SERVICE_SURGERY "surgery"
#define MIRAE_SERVICE_REGEN "regen"
#define MIRAE_SERVICE_REVIVE "revive"

// Policy add-ons. Bought separately, held as a bitfield.
#define MIRAE_ADDON_DEATH (1<<0)
#define MIRAE_ADDON_BASIC (1<<1)
#define MIRAE_ADDON_SURGERY (1<<2)

#define MIRAE_PRICE_DEATH 1000
#define MIRAE_PRICE_BASIC 400
#define MIRAE_PRICE_SURGERY 600

// There is no separate premium. A renewal costs whatever the cover cost to buy,
// every period, and nothing is ever taken automatically - the client has to
// walk back to a terminal and hand it over. That is the whole product: Mirae
// does not sell you insurance, it rents it to you.

/// Free sleeper injections per period on Basic Treatment.
#define MIRAE_BASIC_INJECTIONS 8

// Charge outcomes. Tri-state on purpose: the caller has to be able to tell
// "covered" from "they are maxed out and you should stop".
#define MIRAE_BILL_WAIVED 1
#define MIRAE_BILL_DEBTED 2
#define MIRAE_BILL_REFUSED 3
#define MIRAE_BILL_NOCLIENT 4

#define MIRAE_POLICY_ACTIVE 1
#define MIRAE_POLICY_GRACE 2
#define MIRAE_POLICY_LAPSED 3

/// The company's till when nobody is running it. Income waits here for the
/// first Director to turn up rather than evaporating.
/datum/bank_account/department/mirae
	account_holder = "Mirae Life Insurance (Holding)"

/datum/bank_account/department/mirae/New(dep_id, budget)
	. = ..()
	// The parent reads its holder name out of SSeconomy.department_accounts,
	// which has no entry for an id we invented, so it must be set back after.
	account_holder = initial(account_holder)

/datum/mind
	/// Everything Mirae knows about this person. Created on first contact.
	var/datum/mirae_ledger/mirae_ledger

/datum/mirae_ledger
	/// The mind this belongs to. Never a mob; mobs are temporary.
	var/datum/mind/owner_mind
	/// Outstanding debt, capped at MIRAE_DEBT_MAX.
	var/debt = 0
	/// Cached at first contact and never re-read off the mob. See file header.
	var/account_id
	/// Name to show a Director settling accounts for someone not present.
	var/holder_name = "unknown"
	var/datum/mirae_policy/policy
	/// The body this mind was last seen in, and where. Kept so a tracker ping
	/// does not blink out at the exact moment somebody is gibbed.
	var/mob/living/cached_mob
	var/last_x = 0
	var/last_y = 0
	var/last_z = 0
	/// Set on death, cleared when they are up again. Drives the tracker flash.
	var/dead = FALSE

/datum/mirae_ledger/New(datum/mind/M)
	. = ..()
	owner_mind = M
	holder_name = M?.name || "unknown"
	SSmirae.ledgers += src

/datum/mirae_ledger/Destroy()
	SSmirae.ledgers -= src
	if(cached_mob)
		UnregisterSignal(cached_mob, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
		cached_mob = null
	QDEL_NULL(policy)
	owner_mind = null
	return ..()

/// The ledger for a person, made on demand. Null for anything without a mind,
/// which is the honest answer: a client we cannot identify cannot be billed.
/proc/MiraeLedgerFor(mob/living/L, create = TRUE)
	var/datum/mind/M = L?.mind
	if(!M)
		return null
	if(!M.mirae_ledger && create)
		M.mirae_ledger = new(M)
		M.mirae_ledger.Sync()
	return M.mirae_ledger

/// What somebody owes, from anywhere. The status effect is a display of this,
/// never the other way round.
/proc/MiraeDebtOf(mob/living/L)
	return L?.mind?.mirae_ledger?.debt || 0

/// The only way anything in this feature charges a person.
/proc/MiraeBill(mob/living/patient, amount, service_tag, atom/source)
	var/datum/mirae_ledger/L = MiraeLedgerFor(patient)
	if(!L)
		return MIRAE_BILL_NOCLIENT
	return L.Charge(amount, service_tag, source)

/// The single place a policy is consulted. Every biller goes through here and
/// none of them knows what a policy is.
/datum/mirae_ledger/proc/Charge(amount, service_tag, atom/source)
	if(amount <= 0)
		return MIRAE_BILL_WAIVED
	if(policy?.CoversService(service_tag))
		Notify(span_notice("Your Mirae policy covers this."))
		return MIRAE_BILL_WAIVED
	if(debt >= MIRAE_DEBT_MAX)
		return MIRAE_BILL_REFUSED
	AddDebt(min(amount, MIRAE_DEBT_MAX - debt))
	return MIRAE_BILL_DEBTED

/datum/mirae_ledger/proc/AddDebt(amount)
	if(amount <= 0)
		return
	debt = min(debt + amount, MIRAE_DEBT_MAX)
	Notify(span_warning("Mirae bills you [amount] ahn. You owe [debt]."))
	SyncDebtEffect()

/// Settle some or all of it. Money only moves here and at the terminal, which
/// is what keeps the Director from being paid twice for one service.
/datum/mirae_ledger/proc/PayDebt(amount)
	if(amount <= 0 || amount > debt)
		amount = debt
	if(amount <= 0)
		return 0
	var/datum/bank_account/A = GetAccount()
	if(!A || !MiraeCollect(A, amount, "debt settled by [holder_name]"))
		return 0
	debt -= amount
	SyncDebtEffect()
	Notify(span_nicegreen("Mirae accepts [amount] ahn. Outstanding: [debt]."))
	return amount

/// The Director choosing not to collect. Closes the debt without paying
/// anyone, because no money changed hands.
/datum/mirae_ledger/proc/WriteOff()
	if(debt <= 0)
		return FALSE
	debt = 0
	SyncDebtEffect()
	Notify(span_nicegreen("Mirae has written off your debt."))
	return TRUE

/datum/mirae_ledger/proc/GetAccount()
	if(!account_id)
		return null
	return SSeconomy.bank_accounts_by_id["[account_id]"]

/// Pick up an account number from a body that has one. Bodies built out of a
/// brain do not, so this only ever writes, never clears.
/datum/mirae_ledger/proc/RefreshAccount(mob/living/carbon/human/H)
	if(!ishuman(H) || account_id)
		return
	if(H.account_id)
		account_id = H.account_id

/datum/mirae_ledger/proc/Notify(message)
	if(cached_mob)
		to_chat(cached_mob, message)

/// Bring the mirror in line with the truth. Cheap, and the only place identity,
/// the death hook and the status effect are reconciled.
/datum/mirae_ledger/proc/Sync()
	var/mob/living/now = owner_mind?.current
	if(now != cached_mob)
		if(cached_mob)
			UnregisterSignal(cached_mob, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING))
		cached_mob = now
		if(now)
			RegisterSignal(now, list(COMSIG_LIVING_DEATH, COMSIG_PARENT_QDELETING), PROC_REF(OnDeath))
			RefreshAccount(now)
			SyncDebtEffect()
			if(now.stat != DEAD)
				dead = FALSE
	if(!cached_mob)
		return
	var/turf/T = get_turf(cached_mob)
	if(T)
		last_x = T.x
		last_y = T.y
		last_z = T.z

/datum/mirae_ledger/proc/OnDeath(datum/source)
	SIGNAL_HANDLER
	dead = TRUE
	if(policy && (policy.addons & MIRAE_ADDON_DEATH))
		INVOKE_ASYNC(SSmirae, TYPE_PROC_REF(/datum/controller/subsystem/mirae, AnnounceDeath), src)

/datum/mirae_ledger/proc/SyncDebtEffect()
	if(!cached_mob)
		return
	cached_mob.apply_lc_mirae_debt(debt)

/// Undo the grid dependency /obj/machinery/power_change() has just stamped on.
///
/// Every Mirae machine runs off the company's own supply. The parent decides
/// NOPOWER purely from whether the area is powered, and a clinic capsule lands
/// on a bare lot with no APC and no cable - a ward that only works where
/// somebody else already built a powernet is not one a Director can deploy.
///
/// The parent is still called first, because it is SHOULD_CALL_PARENT and
/// carries the power-restored signals other things listen for.
/proc/MiraeSelfPowered(obj/machinery/M)
	M.set_machine_stat(M.machine_stat & ~NOPOWER)
	M.update_icon()

/// Anyone on the clinic's payroll. They are the one group the terminal will not
/// sell to: a company does not insure itself, and a Director quietly writing
/// off their own staff's debt is the whole system paying for nothing.
/proc/MiraeIsStaff(mob/M)
	var/role = M?.mind?.assigned_role
	if(!role)
		return FALSE
	return role in list("Clinic Director", "Clinic Staff", "Clinic Field Agent")

/// Whether this person should show on a Mirae tracker at all, and as what.
/datum/mirae_ledger/proc/TrackerKind()
	var/insured = policy && policy.state != MIRAE_POLICY_LAPSED
	if(insured && debt > 0)
		return "both"
	if(insured)
		return "client"
	if(debt > 0)
		return "debtor"
	return null

SUBSYSTEM_DEF(mirae)
	name = "Mirae Insurance"
	init_order = INIT_ORDER_MIRAE
	wait = 5 SECONDS
	runlevels = RUNLEVEL_GAME
	/// Every ledger this round.
	var/list/datum/mirae_ledger/ledgers = list()
	/// Cached once found. A dead Director still owns the clinic's income.
	var/datum/bank_account/director_account
	/// Where income waits while there is no Director.
	var/datum/bank_account/department/mirae/holding
	/// Watches currently being worn, so a death alert has somewhere to go.
	var/list/obj/item/clothing/accessory/mirae_watch/watches = list()

/datum/controller/subsystem/mirae/Initialize(timeofday)
	holding = new(MIRAE_ACCOUNT_ID, 0)
	return ..()

/datum/controller/subsystem/mirae/fire(resumed = FALSE)
	for(var/datum/mirae_ledger/L in ledgers)
		L.Sync()
	if(!director_account)
		GetDirectorAccount()

/// Found once, then never searched for again, so a Director who dies keeps
/// their clinic's income instead of it quietly diverting to holding.
/datum/controller/subsystem/mirae/proc/GetDirectorAccount()
	if(director_account)
		return director_account
	for(var/mob/living/carbon/human/H in GLOB.human_list)
		if(H.mind?.assigned_role != "Clinic Director")
			continue
		if(!H.account_id)
			continue
		var/datum/bank_account/B = SSeconomy.bank_accounts_by_id["[H.account_id]"]
		if(!B)
			continue
		director_account = B
		FlushHolding()
		return director_account
	return null

/// Hand the backlog to the first Director who turns up, however late.
/datum/controller/subsystem/mirae/proc/FlushHolding()
	if(!director_account || !holding || holding.account_balance <= 0)
		return
	var/owed = holding.account_balance
	holding.adjust_money(-owed)
	director_account.adjust_money(owed)
	MiraeAnnouncePaid(director_account, owed, "backdated receipts")

/datum/controller/subsystem/mirae/proc/AnnounceDeath(datum/mirae_ledger/L)
	for(var/obj/item/clothing/accessory/mirae_watch/W in watches)
		W.ClientDied(L)

/// Take money from a client and credit the clinic. The one wrapper, used
/// everywhere.
///
/// transfer_money() is never used in this feature: its src is the receiver, and
/// getting that backwards fails silently because adjust_money() refuses a debit
/// it cannot cover rather than erroring.
/proc/MiraeCollect(datum/bank_account/payer, amount, reason)
	if(!payer || amount <= 0)
		return FALSE
	if(!payer.adjust_money(-amount))
		return FALSE
	var/datum/bank_account/till = SSmirae.GetDirectorAccount()
	if(!till)
		// Nobody to tell. Income waits in holding until a Director turns up,
		// and they are told the total when it is handed over.
		SSmirae.holding.adjust_money(amount)
		return TRUE
	till.adjust_money(amount)
	MiraeAnnouncePaid(till, amount, reason)
	return TRUE

/// Tell whoever owns the till that it just went up.
///
/// Resolved by account number rather than by job title. The Director is the one
/// who holds this account, and matching on the number means a Director rebuilt
/// out of a brain - who carries the ledger's number but may be carrying no card
/// at all - still hears their own till.
/proc/MiraeAnnouncePaid(datum/bank_account/account, amount, reason)
	if(!account || amount <= 0)
		return
	var/note = reason ? " ([reason])" : ""
	for(var/mob/living/carbon/human/H in GLOB.human_list)
		if(H.account_id != account.account_id)
			continue
		to_chat(H, span_nicegreen("MIRAE ACCOUNTS: [amount] ahn received[note]. \
			Balance [account.account_balance] ahn."))
		SEND_SOUND(H, sound('sound/machines/twobeep_high.ogg', volume = 30))
