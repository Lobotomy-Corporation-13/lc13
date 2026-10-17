// The limb regenerator: what Mirae sells Death Insurance for.
//
// Named mirae_regenerator and not /obj/machinery/regenerator, because that
// path already exists as an orphan - Sleeper.dm defines a Destroy() on it that
// was plainly meant to be the sleeper's - and a new type there would silently
// inherit it.
//
// A patient is buckled to the pod rather than held in its contents, the way
// the stasis bed and the operating table hold theirs. That is not only tidier:
// client/Move relays a buckled mob's movement before it checks whether they can
// walk at all, so a patient with no legs - which is most of them, in a machine
// that exists to regrow legs - can still step out. A contents-based pod fails
// that check two lines earlier and traps them.
//
// A severed head or a bare brain cannot be buckled to anything: a head is an
// item and its brainmob is not a carbon. Those get a body built out of their
// stored DNA first, the way the body fabricator does, and are then buckled like
// any other patient.

/obj/machinery/mirae_regenerator
	name = "mirae reclamation pod"
	desc = "A tank of cloudy suspension with a body in it, usually. The meter \
		on the side counts limbs, not minutes."
	icon = 'ModularLobotomy/_Lobotomyicons/cloning/cloning_pod.dmi'
	icon_state = "pod_0"
	density = TRUE
	anchored = TRUE
	use_power = NO_POWER_USE
	idle_power_usage = 0
	active_power_usage = 0
	can_buckle = TRUE
	buckle_lying = 0
	/// When the next limb is due.
	var/next_limb = 0
	/// What the tank had in front of it when they went in, for the read-out.
	var/initial_missing = 0
	var/initial_damage = 0
	/// Set when the pod stops because the client cannot pay any more.
	var/stalled = FALSE
	/// How long one limb takes to grow.
	var/regen_interval = 10 SECONDS
	/// Charged per limb grown.
	var/limb_cost = 400
	/// How far up the tank a suspended patient floats.
	var/float_height = 18
	/// Health restored per second in the tank.
	var/mend_rate = 2
	/// Health restored per block billed, and what a block costs.
	var/mend_block = 10
	var/mend_cost = 10
	/// Health restored but not yet paid for. Carried between ticks so a slow
	/// one is not rounded away into free care.
	var/unbilled = 0

/obj/machinery/mirae_regenerator/Initialize(mapload)
	. = ..()
	occupant_typecache = GLOB.typecache_living

/obj/machinery/mirae_regenerator/power_change()
	. = ..()
	MiraeSelfPowered(src)

/obj/machinery/mirae_regenerator/Destroy()
	unbuckle_all_mobs(TRUE)
	return ..()

/obj/machinery/mirae_regenerator/attackby(obj/item/I, mob/user, params)
	if(occupant)
		to_chat(user, span_warning("[src] is occupied."))
		return
	if(istype(I, /obj/item/bodypart/head))
		var/obj/item/bodypart/head/H = I
		if(!H.brain || !H.brain.brainmob)
			to_chat(user, span_warning("There is nothing in that head worth reclaiming."))
			return
		if(!user.transferItemToLoc(I, src))
			return
		BuildFrom(H.brain, user)
		H.drop_organs()
		qdel(H)
		return
	if(istype(I, /obj/item/organ/brain))
		var/obj/item/organ/brain/B = I
		if(!B.brainmob)
			to_chat(user, span_warning("That brain is empty."))
			return
		if(!user.transferItemToLoc(I, src))
			return
		BuildFrom(B, user)
		return
	return ..()

/// Grow a body around a brain, then treat it as an ordinary patient.
///
/// The rebuilt mob is brand new and so has no account_id of its own; without
/// copying the ledger's the person we just put back together would have no way
/// to pay for it.
/obj/machinery/mirae_regenerator/proc/BuildFrom(obj/item/organ/brain/B, mob/user)
	var/mob/living/brain/BM = B.brainmob
	var/datum/dna/stored = BM?.stored_dna
	if(!stored)
		return
	var/mob/living/carbon/human/H = new(get_turf(src))
	H.real_name = stored.real_name
	H.set_species(stored.species)
	stored.transfer_identity(H)
	for(var/zone in list(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG))
		var/obj/item/bodypart/BP = H.get_bodypart(zone)
		if(BP)
			BP.drop_limb()
			qdel(BP)
	B.Insert(H)
	H.revive(full_heal = FALSE, admin_revive = FALSE)
	var/datum/mirae_ledger/L = MiraeLedgerFor(H)
	if(L && L.account_id)
		H.account_id = L.account_id
	visible_message(span_notice("[src] closes around a half-formed body."))
	buckle_mob(H, force = TRUE, check_loc = FALSE)

/obj/machinery/mirae_regenerator/post_buckle_mob(mob/living/L)
	if(!can_be_occupant(L))
		return
	set_occupant(L)
	L.pixel_y = float_height
	stalled = FALSE
	unbilled = 0
	initial_missing = length(L.get_missing_limbs())
	initial_damage = MendableDamage(L)
	next_limb = world.time + regen_interval
	update_icon()
	START_PROCESSING(SSmachines, src)

/obj/machinery/mirae_regenerator/post_unbuckle_mob(mob/living/L)
	L.pixel_y = initial(L.pixel_y)
	if(L == occupant)
		set_occupant(null)
	STOP_PROCESSING(SSmachines, src)
	next_limb = 0
	initial_missing = 0
	initial_damage = 0
	stalled = FALSE
	// Anything under one block is forgiven. Chasing a client out of the door
	// for nine points of mending is not worth the paperwork.
	unbilled = 0
	update_icon()

/// Walking out. The default tells you that you cannot move while buckled; here
/// the buckle is a treatment you are free to refuse.
/obj/machinery/mirae_regenerator/relaymove(mob/living/user, direction)
	if(user != occupant)
		return
	visible_message(span_notice("[user] pulls free of [src]."))
	unbuckle_mob(user, TRUE)

/obj/machinery/mirae_regenerator/process(delta_time)
	var/mob/living/carbon/human/H = occupant
	// Not unbuckled here: unbuckle_mob CRASHes on a mob whose buckled is not
	// us, which is exactly the case this branch catches.
	if(!ishuman(H) || H.buckled != src)
		set_occupant(null)
		STOP_PROCESSING(SSmachines, src)
		update_icon()
		return
	// Redrawn every tick; the bob in the overlay is what makes the tank read
	// as liquid rather than as a still picture.
	update_icon()
	Mend(H, delta_time)
	if(world.time < next_limb)
		return
	var/list/missing = H.get_missing_limbs()
	if(!length(missing))
		// Held until they are actually whole and actually well, or somebody
		// who walked in merely wounded would be ejected before the pod had
		// done anything for them.
		if(H.health >= H.maxHealth)
			unbuckle_mob(H, TRUE)
		return
	// Charged before the limb is grown, and only grown if the charge landed.
	// Reversed, a client at their debt ceiling would be handed free limbs.
	if(!Charge(H, limb_cost))
		return
	H.regenerate_limb(pick(missing), FALSE)
	next_limb = world.time + regen_interval

/// One charge, and the stall flag that follows from it.
/obj/machinery/mirae_regenerator/proc/Charge(mob/living/H, amount)
	if(MiraeBill(H, amount, MIRAE_SERVICE_REGEN, src) == MIRAE_BILL_REFUSED)
		if(!stalled)
			stalled = TRUE
			say("Reclamation suspended. Outstanding balance exceeds the limit.")
		return FALSE
	stalled = FALSE
	return TRUE

/// Mend a little, and bill for exactly what was mended.
///
/// heal_ordered_damage is what does the measuring: it heals only up to the
/// damage actually present and returns how much that came to, so the bill can
/// never be for care the patient did not get.
///
/// Health is deliberately not used to measure it. updatehealth() recomputes
/// maxHealth out of Fortitude every time it runs, so `health` moves whenever a
/// stat bonus does - and a patient sitting at full health billed themselves for
/// the drift. Damage removed is the only figure here that means one thing.
///
/// Only whole blocks are charged and the remainder is carried, so a slow tick
/// is not rounded away into free treatment.
///
/// Last tick's care is paid for before this tick's is given, and nothing more
/// is given until it is. Doing it the other way round would let a client at
/// their ceiling be mended to full for nothing.
/obj/machinery/mirae_regenerator/proc/Mend(mob/living/carbon/human/H, delta_time)
	if(unbilled >= mend_block)
		var/blocks = round(unbilled / mend_block)
		if(!Charge(H, blocks * mend_cost))
			return
		unbilled -= blocks * mend_block
	unbilled += H.heal_ordered_damage(mend_rate * delta_time,
		list(BRUTE, FIRE, OXY))

/// How close the occupant is to walking out, as a percentage of the work the
/// tank had in front of it when they went in.
///
/// Limbs and wounds are both converted to the time each actually takes, so the
/// figure tracks the wait rather than the injury: somebody with three limbs to
/// grow is nowhere near done however shallow their remaining cuts are.
/obj/machinery/mirae_regenerator/proc/Recovery()
	var/mob/living/carbon/human/H = occupant
	if(!ishuman(H))
		return 0
	var/total = WorkFor(initial_missing, initial_damage)
	if(total <= 0)
		return 100
	var/left = WorkFor(length(H.get_missing_limbs()), MendableDamage(H))
	return round(100 * clamp((total - left) / total, 0, 1))

/// The damage this tank can actually do anything about, which is not the same
/// as how hurt somebody is: toxins and clone damage are not on its list, and
/// counting them would leave the read-out stuck short of full forever.
/obj/machinery/mirae_regenerator/proc/MendableDamage(mob/living/H)
	return H.getBruteLoss() + H.getFireLoss() + H.getOxyLoss()

/// Deciseconds of tank time a given amount of damage represents.
/obj/machinery/mirae_regenerator/proc/WorkFor(limbs, damage)
	return limbs * regen_interval + (mend_rate ? (damage / mend_rate) * 10 : 0)

/obj/machinery/mirae_regenerator/update_icon_state()
	icon_state = occupant ? "pod_1" : "pod_0"
	return ..()

/obj/machinery/mirae_regenerator/update_overlays()
	. = ..()
	. += "panel"
	if(!occupant)
		return
	// The patient is a real mob standing on our turf, so the glass has to be
	// drawn over the top of them or they read as standing in front of the pod
	// rather than suspended inside it.
	var/mutable_appearance/glass = mutable_appearance(icon, "cover-on", ABOVE_MOB_LAYER)
	. += glass

/obj/machinery/mirae_regenerator/examine(mob/user)
	. = ..()
	if(!occupant)
		. += span_notice("The tank is empty. Drag someone onto it to begin.")
		return
	var/mob/living/carbon/human/H = occupant
	var/left = ishuman(H) ? length(H.get_missing_limbs()) : 0
	. += span_notice("[H.real_name] is suspended inside. [left] limb\s left to grow.")
	. += span_notice("Recovery [Recovery()]% complete. Mending is billed at \
		[mend_cost] ahn per [mend_block] health restored.")
	if(stalled)
		// No countdown while stalled: the meter is not running, and a time
		// that is not going to arrive is worse than no time at all.
		. += span_warning("The meter is flashing. The account will not take another charge.")
	else if(left)
		var/next = max(0, next_limb - world.time)
		var/total = next + (left - 1) * regen_interval
		. += span_notice("Next limb in [DisplayTimeText(next)]. \
			[DisplayTimeText(total)] until they are whole.")
	else if(H.health < H.maxHealth)
		// Why somebody with all four limbs is still in the tank.
		. += span_notice("Limbs are done. The tank is closing what is left of the wounds.")
	. += span_notice("Moving, or a hand on the release, will open it.")
