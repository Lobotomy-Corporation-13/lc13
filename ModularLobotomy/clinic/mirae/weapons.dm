// Mirae Life Insurance clinic gear.
//
// Neither weapon pays the wielder for a kill. Mirae's whole premise is that
// the money moves toward whoever got hurt, so both of these spend something of
// the user's to put someone else back on their feet.

/obj/item/ego_weapon/city/mirae_cane
	name = "mirae director's cane"
	desc = "A black lacquer cane with a steel head. The grip is worn smooth on \
		one side, which is not where a walking stick wears."
	special = "Use in hand to release a spreading cone of settlement gas. Each \
		notice hits as it goes up, and again as the gas clears; both pay you \
		back a tenth of what they do as healing. Hits harder against \
		non-humans, by 1% per point of Justice. On hit, voids all stacks of \
		one status ailment you are carrying."
	icon_state = "miraecane"
	inhand_icon_state = "miraecane"
	force = 42
	damtype = WHITE_DAMAGE
	attack_verb_continuous = list("cracks", "raps", "strikes")
	attack_verb_simple = list("crack", "rap", "strike")
	//Same tier as the coat this role is issued with. Both are gated by the
	//variant's stat block, so a company that trains its Director lower must
	//also arm them lower or the cane is unusable.
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 100,
							JUSTICE_ATTRIBUTE = 100,
							)
	/// How far the cone reaches.
	var/cone_range = 5
	/// Between one rank's notice going up and the next one's.
	var/cone_step = 2
	/// WHITE damage a rank does as its notice goes up.
	var/cone_damage = 75
	/// And again, smaller, once the gas over that rank has cleared.
	var/cone_residue = 25
	/// Fraction of everything the cone dealt that comes back as brute healing.
	var/cone_drain = 0.1
	var/cone_cooldown
	var/cone_cooldown_time = 12 SECONDS
	var/void_cooldown
	var/void_cooldown_time = 8 SECONDS
	/// Every LC13 stacking debuff the policy clause can void. Listed as exact
	/// types because the family is not a single branch: the four damtype
	/// fragilities are siblings under different parents, not subtypes of one.
	var/list/voidable = list(
		/datum/status_effect/stacking/protection/fragile,
		/datum/status_effect/stacking/damtype_protection/fragile,
		/datum/status_effect/stacking/damtype_protection/white/fragile,
		/datum/status_effect/stacking/damtype_protection/black/fragile,
		/datum/status_effect/stacking/damtype_protection/pale/fragile,
		/datum/status_effect/stacking/defense_level_up/defense_level_down,
		/datum/status_effect/stacking/damage_up/down,
		/datum/status_effect/stacking/damtype_damage_up/down,
		/datum/status_effect/stacking/damtype_damage_up/white/down,
		/datum/status_effect/stacking/damtype_damage_up/black/down,
		/datum/status_effect/stacking/damtype_damage_up/pale/down,
		/datum/status_effect/stacking/offense_level_up/offense_level_down,
		/datum/status_effect/stacking/sinking,
		/datum/status_effect/stacking/rupture,
	)

/// The cone does not land at once. Each rank is telegraphed, and detonates a
/// half second later, so the whole thing rolls away from the user and can be
/// stepped out of by anything quick enough to read it.
/obj/item/ego_weapon/city/mirae_cane/attack_self(mob/living/carbon/human/user)
	if(!CanUseEgo(user))
		return
	if(cone_cooldown > world.time)
		to_chat(user, span_warning("The policy has not renewed yet."))
		return
	cone_cooldown = world.time + cone_cooldown_time
	user.visible_message(span_danger("[user] sweeps [src] out in a low arc!"),
		span_notice("You file the claim."))
	playsound(user, 'sound/effects/smoke.ogg', 60, TRUE)
	var/turf/origin = get_turf(user)
	var/facing = user.dir
	for(var/rank in 1 to cone_range)
		var/delay = (rank - 1) * cone_step
		addtimer(CALLBACK(src, PROC_REF(TelegraphRank), origin, facing, rank, user), delay)

/// One rank of the cone. The notice goes up and bites as it does, the gas
/// follows it, and the rank bites again once that gas has cleared - so standing
/// in the cone costs twice and walking out between the two costs once.
/obj/item/ego_weapon/city/mirae_cane/proc/TelegraphRank(turf/origin, facing, rank, mob/living/user)
	var/list/turfs = ConeRank(origin, facing, rank)
	if(!length(turfs))
		return
	var/obj/effect/temp_visual/mirae_cone_warn/notice
	for(var/turf/T in turfs)
		notice = new(T)
	StrikeRank(turfs, user, cone_damage)
	//Timed off the notice's own lifetime rather than off a matching number
	//kept here, so what the player is looking at and what the weapon is
	//waiting for cannot drift apart.
	addtimer(CALLBACK(src, PROC_REF(DetonateRank), turfs, user), notice.duration)

/obj/item/ego_weapon/city/mirae_cane/proc/DetonateRank(list/turfs, mob/living/user)
	var/obj/effect/temp_visual/mirae_cone_gas/cloud
	for(var/turf/T in turfs)
		cloud = new(T)
	addtimer(CALLBACK(src, PROC_REF(DissipateRank), turfs, user), cloud.duration)

/obj/item/ego_weapon/city/mirae_cane/proc/DissipateRank(list/turfs, mob/living/user)
	StrikeRank(turfs, user, cone_residue)

/// Everything standing in the rank takes WHITE, and a tenth of it comes back to
/// the user as brute healing.
///
/// The payout is a share of what was thrown at each target, not of the health
/// they lost. WHITE against a human is nerve damage and moves no health at all,
/// so measuring the drop paid the Director nothing for most of what they hit.
/obj/item/ego_weapon/city/mirae_cane/proc/StrikeRank(list/turfs, mob/living/user, amount)
	if(amount <= 0 || QDELETED(user))
		return
	var/justice = 1 + get_attribute_level(user, JUSTICE_ATTRIBUTE) / 100
	var/dealt = 0
	for(var/turf/T in turfs)
		for(var/mob/living/L in T)
			if(L == user)
				continue
			// Simple mobs are what a Director actually swings this at, and
			// what every other city weapon scales its attribute bonus against.
			var/hit = ishuman(L) ? amount : amount * justice
			L.deal_damage(hit, WHITE_DAMAGE, user, attack_type = ATTACK_TYPE_SPECIAL)
			dealt += hit
	var/payout = round(dealt * cone_drain)
	if(payout <= 0)
		return
	user.adjustBruteLoss(-payout)
	to_chat(user, span_nicegreen("The policy pays out: [payout]."))

/// Turfs `dist` ahead of `origin`, widening as it goes. Three across at the
/// user's feet, one wider every second rank after that.
/obj/item/ego_weapon/city/mirae_cane/proc/ConeRank(turf/origin, facing, dist)
	var/turf/centre = origin
	for(var/i in 1 to dist)
		centre = get_step(centre, facing)
		if(!centre)
			return list()
	var/list/row = list(centre)
	var/half = 1 + round((dist - 1) * 0.5)
	var/turf/left = centre
	var/turf/right = centre
	for(var/i in 1 to half)
		left = get_step(left, turn(facing, 90))
		right = get_step(right, turn(facing, -90))
		if(left)
			row += left
		if(right)
			row += right
	return row

/// Hitting something voids one of the user's own ailments outright. Which one
/// is not chosen, matching the clause it is named for.
/obj/item/ego_weapon/city/mirae_cane/afterattack(atom/A, mob/living/user, proximity_flag, params)
	. = ..()
	if(!proximity_flag || !isliving(A) || A == user)
		return
	if(void_cooldown > world.time)
		return
	var/list/held = list()
	for(var/datum/status_effect/S in user.status_effects)
		if(S.type in voidable)
			held += S
	if(!length(held))
		return
	void_cooldown = world.time + void_cooldown_time
	var/datum/status_effect/voided = pick(held)
	to_chat(user, span_nicegreen("Policy form: [voided.id] is voided."))
	qdel(voided)

/obj/item/ego_weapon/city/mirae_case
	name = "mirae insurer's case"
	desc = "A brown leather case with steel fittings. Heavy enough to swing, \
		and it is not the paperwork that makes it heavy."
	special = "Use in hand to open the case. While open, click a person out of \
		reach to spend 15% of your own health and a quarter of your sanity \
		restoring a tenth of theirs. Click bare ground and it finds the \
		nearest person to it instead. Needs more than a quarter of your \
		sanity left, and takes five seconds to write up again."
	icon_state = "mirae_insurer_case"
	inhand_icon_state = "mirae_insurer_case"
	force = 34
	damtype = WHITE_DAMAGE
	attack_verb_continuous = list("smashes", "bashes")
	attack_verb_simple = list("smash", "bash")
	//Same tier as the insurer's coat.
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80,
							)
	/// Whether clicking at range pays out instead of doing nothing.
	var/open = FALSE
	/// How long a payout takes to sign off.
	var/payout_time = 2 SECONDS
	/// Taken from the insurer, as a share of their maximum.
	var/premium = 0.15
	/// Given to the patient, as a share of theirs.
	var/coverage = 0.1
	/// How far from a clicked tile to look for somebody to treat.
	var/scan_range = 1
	/// Taken from the insurer's nerve, as a share of their maximum.
	var/sanity_cost = 0.25
	/// Sanity, as a share of maximum, at or below which no claim can be filed.
	/// Signing off on a payout is the part of the job that costs an insurer
	/// something, and there is a point past which they will not sign.
	var/sanity_floor = 0.25
	var/payout_cooldown
	var/payout_cooldown_time = 5 SECONDS

/obj/item/ego_weapon/city/mirae_case/attack_self(mob/living/carbon/human/user)
	if(!CanUseEgo(user))
		return
	open = !open
	UpdateLatch()
	to_chat(user, open \
		? span_nicegreen("You unclasp the case. Claims can be filed at range.") \
		: span_notice("You close the case."))
	playsound(user, 'sound/effects/bin_close.ogg', 50, TRUE)
	user.update_inv_hands()

/// Whether the case is open is the only thing that says the tool is armed, so
/// it has to be visible on the item and in hand rather than only in chat.
/obj/item/ego_weapon/city/mirae_case/proc/UpdateLatch()
	icon_state = open ? "mirae_insurer_case_open" : "mirae_insurer_case"
	inhand_icon_state = icon_state
	update_icon()

/// Filing a claim at range. Clicking a person treats them; clicking bare
/// ground treats whoever is nearest to it, so a body on the floor does not
/// have to be clicked precisely in a fight.
/obj/item/ego_weapon/city/mirae_case/afterattack(atom/A, mob/living/user, proximity_flag, params)
	. = ..()
	if(!open || proximity_flag || !isliving(user))
		return
	var/mob/living/patient = null
	if(isliving(A))
		patient = A
	else
		var/turf/T = get_turf(A)
		if(T)
			patient = NearestPatient(T, user)
	if(!patient || patient == user)
		return
	if(payout_cooldown > world.time)
		to_chat(user, span_warning("You are still writing up the last claim."))
		return
	if(user.sanityhealth <= user.maxSanity * sanity_floor)
		to_chat(user, span_warning("You cannot bring yourself to sign another."))
		return
	Payout(patient, user)

/// Closest living thing to a tile, ignoring the insurer themselves.
/obj/item/ego_weapon/city/mirae_case/proc/NearestPatient(turf/T, mob/living/user)
	var/mob/living/best = null
	var/best_dist = INFINITY
	for(var/mob/living/L in range(scan_range, T))
		if(L == user)
			continue
		var/dist = get_dist(T, L)
		if(dist < best_dist)
			best = L
			best_dist = dist
	return best

/// The insurer stands still and signs. The patient does not have to; a claim
/// is on the person, not the place, so only the insurer moving voids it.
///
/// The cooldown starts here rather than on success. do_after sleeps, so a
/// second click during those two seconds would otherwise open a second claim.
/obj/item/ego_weapon/city/mirae_case/proc/Payout(mob/living/patient, mob/living/user)
	payout_cooldown = world.time + payout_cooldown_time
	user.visible_message(span_notice("[user] opens [src] toward [patient]."),
		span_notice("You start filing a claim for [patient]."))
	if(!do_after(user, payout_time, patient, IGNORE_TARGET_LOC_CHANGE))
		to_chat(user, span_warning("The claim lapses."))
		return
	if(QDELETED(patient) || QDELETED(user))
		return
	var/cost = round(user.maxHealth * premium)
	var/paid = round(patient.maxHealth * coverage)
	user.deal_damage(cost, WHITE_DAMAGE, user, flags = DAMAGE_FORCED, attack_type = ATTACK_TYPE_SPECIAL)
	//The floor is only checked when the claim is opened. Somebody who took
	//sanity damage across those two seconds still pays in full, which is the
	//risk of signing one in the middle of a fight.
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.adjustSanityLoss(H.maxSanity * sanity_cost)
	patient.heal_ordered_damage(paid, list(BRUTE, FIRE, OXY, TOX))
	user.visible_message(span_nicegreen("[user] closes [src]. [patient] looks steadier."))
	to_chat(user, span_notice("Claim settled. [paid] covered, [cost] and a quarter of your nerve out of your own pocket."))
	playsound(user, 'sound/effects/bin_close.ogg', 50, TRUE)

/obj/effect/temp_visual/mirae_cone_warn
	name = "settlement notice"
	icon = 'icons/effects/effects.dmi'
	icon_state = "mirae_cone_warn"
	layer = BELOW_MOB_LAYER
	duration = 5
	randomdir = FALSE

/obj/effect/temp_visual/mirae_cone_gas
	name = "settlement"
	icon = 'icons/effects/effects.dmi'
	icon_state = "mirae_cone_gas"
	duration = 6
	randomdir = FALSE

