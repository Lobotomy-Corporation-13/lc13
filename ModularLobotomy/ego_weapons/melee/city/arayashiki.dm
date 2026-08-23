// Arayashiki - Ryoshu's blade. Severs threads, erodes the wielder's perception.
// See ModularLobotomy/ego_weapons/melee/city/arayashiki_effects.dm for status effects,
// and ModularLobotomy/ego_weapons/melee/city/arayashiki_bladewound.dm for the permanent scar component.

GLOBAL_LIST_EMPTY(arayashiki_blades)

/obj/item/ego_weapon/city/arayashiki
	name = "Tiansha Star's Blade - Arayashiki \u963F\u983C\u8036\u8B58"
	desc = "The heavens themselves are not spared-heaven, earth, man, and the self. This star rises only for the one who perceives all existence and time as a single whole to sever them all."
	special = "On hit, applies <b>Sever the Thread \u5207\u7D72</b>. At 10 stacks, the next strike severs a limb \
	(or an eye / tongue if it lands on the head) and leaves a permanent <b>Bladewound</b>. \
	Each swing fills you with <b>Muga \u7121\u6211</b>; perception erodes as it grows."
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "hfrequency0"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	force = 55
	damtype = RED_DAMAGE
	attack_speed = 0.7
	hitsound = 'sound/weapons/ego/justitia1.ogg'
	attack_verb_continuous = list("severs", "slices", "cuts")
	attack_verb_simple = list("sever", "slice", "cut")
	swingstyle = WEAPONSWING_LARGESWEEP
	var/mob/living/carbon/human/current_wielder
	/// Current per-tick passive Muga gain. Resets to initial(3) on equip/drop/death/destroy. Grows by +2 each tick.
	var/passive_muga_amount = 3
	/// world.time at which the next passive Muga tick fires.
	var/passive_muga_next = 0

/obj/item/ego_weapon/city/arayashiki/Initialize()
	. = ..()
	GLOB.arayashiki_blades += src

/obj/item/ego_weapon/city/arayashiki/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(current_wielder)
		current_wielder.remove_status_effect(/datum/status_effect/muga)
		ClearWielder()
	GLOB.arayashiki_blades -= src
	return ..()

/obj/item/ego_weapon/city/arayashiki/equipped(mob/user, slot)
	. = ..()
	if(ishuman(user) && (slot == ITEM_SLOT_HANDS))
		SetWielder(user)
		passive_muga_next = world.time + 5 SECONDS
		START_PROCESSING(SSobj, src)

/// Remembers who holds the blade, following them if they are deleted
/obj/item/ego_weapon/city/arayashiki/proc/SetWielder(mob/living/carbon/human/user)
	ClearWielder()
	current_wielder = user
	RegisterSignal(current_wielder, COMSIG_PARENT_QDELETING, PROC_REF(on_wielder_deleted))

/obj/item/ego_weapon/city/arayashiki/proc/ClearWielder()
	if(!current_wielder)
		return
	UnregisterSignal(current_wielder, COMSIG_PARENT_QDELETING)
	current_wielder = null

/obj/item/ego_weapon/city/arayashiki/proc/on_wielder_deleted(datum/source)
	SIGNAL_HANDLER
	current_wielder = null
	STOP_PROCESSING(SSobj, src)
	passive_muga_amount = initial(passive_muga_amount)

/obj/item/ego_weapon/city/arayashiki/dropped(mob/user)
	. = ..()
	if(current_wielder == user)
		ClearWielder()
		STOP_PROCESSING(SSobj, src)
		passive_muga_amount = initial(passive_muga_amount)

/// Passive: every 5 seconds while wielded, grants Muga to the wielder. Per-tick amount starts
/// at 3 and grows by +2 each tick. Resets when the wielder drops the blade or dies.
/obj/item/ego_weapon/city/arayashiki/process()
	if(!current_wielder || current_wielder.stat == DEAD)
		STOP_PROCESSING(SSobj, src)
		passive_muga_amount = initial(passive_muga_amount)
		return
	if(world.time < passive_muga_next)
		return
	passive_muga_next = world.time + 5 SECONDS
	var/datum/status_effect/muga/Mu = current_wielder.has_status_effect(/datum/status_effect/muga)
	if(!Mu)
		Mu = current_wielder.apply_status_effect(/datum/status_effect/muga)
	if(Mu)
		Mu.AddMuga(passive_muga_amount)
	passive_muga_amount += 2

/obj/item/ego_weapon/city/arayashiki/attack(mob/living/M, mob/living/user)
	// The wielder cannot strike themselves with Arayashiki - the blade refuses.
	if(M == user)
		to_chat(user, span_warning("Arayashiki refuses your hand. The blade cannot turn upon its wielder."))
		return FALSE

	// Clamp before the parent attack: a post-damage heal cannot undo an overkill
	var/original_force = force
	var/clamped_for_floor = FALSE
	if(M && isliving(M) && M.maxHealth > 0 && !QDELETED(M) && M.stat != DEAD)
		var/floor_hp = M.maxHealth * 0.05
		var/headroom = max(1, M.health - floor_hp)  // never below 1 - 0 damage skips hitsound/feedback
		if(force > headroom)
			force = headroom
			clamped_for_floor = TRUE

	. = ..()

	if(clamped_for_floor)
		force = original_force

	if(!. || !iscarbon(M))
		return .

	// Threshold check FIRST: if the victim was armed by a prior hit, this strike severs.
	// Stacks are NOT reset - they keep climbing toward 100 to deepen distortion on client victims.
	var/datum/status_effect/stacking/sever_the_thread/S = M.has_status_effect(/datum/status_effect/stacking/sever_the_thread)
	if(S && S.armed)
		DoDismemberZone(M, user.zone_selected, user)
		TryAttachBladewound(M)
		S.armed = FALSE

	// Bonus stacks come off the wielder's Muga before this swing's increment
	var/bonus_stacks = 0
	var/datum/status_effect/muga/CurMuga = ishuman(user) ? user.has_status_effect(/datum/status_effect/muga) : null
	if(CurMuga)
		bonus_stacks = min(round(CurMuga.muga / 10), 4)
	var/total_stacks = 1 + bonus_stacks

	S = M.has_status_effect(/datum/status_effect/stacking/sever_the_thread)
	if(!S)
		M.apply_status_effect(/datum/status_effect/stacking/sever_the_thread, total_stacks)
	else
		S.add_stacks(total_stacks)

	// Wielder gains 1 Muga per swing (after computing bonus, so this swing's bonus is based on prior Muga).
	if(ishuman(user))
		if(!CurMuga)
			CurMuga = user.apply_status_effect(/datum/status_effect/muga)
		if(CurMuga)
			CurMuga.AddMuga(1)

	// Re-fetch S because the apply path above may have just created it.
	S = M.has_status_effect(/datum/status_effect/stacking/sever_the_thread)

	// Erasing Me, Erasing You: hitting a target at 100 Sever the Thread triggers the finisher.
	if(S && S.stacks >= 100 && !S.cutscene_active)
		S.cutscene_active = TRUE
		INVOKE_ASYNC(src, PROC_REF(PerformErasingMeErasingYou), M, user)
		return .

	// Damage floor: while a target has Sever the Thread, the blade cannot reduce them
	// below 1% maxHealth. They survive at 1% until the cutscene erases them.
	if(S && M && !QDELETED(M) && M.maxHealth > 0 && M.stat != DEAD)
		var/floor_hp = M.maxHealth * 0.01
		if(M.health < floor_hp)
			var/needed = floor_hp - M.health
			if(needed > 0)
				M.heal_overall_damage(brute = needed)
				M.updatehealth()

	return .

/// Picks a random dismemberable limb zone (excluding head and chest) on M.
/// Returns null if no valid limb exists.
/obj/item/ego_weapon/city/arayashiki/proc/PickRandomLimbZone(mob/living/carbon/M)
	var/static/list/limb_zones = list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	var/list/candidates = list()
	for(var/z in limb_zones)
		var/obj/item/bodypart/limb = M.get_bodypart(z)
		if(limb && limb.dismemberable)
			candidates += z
	if(length(candidates))
		return pick(candidates)
	return null

/// Severs a limb at the given zone, or removes a random head organ if zone is the head.
/// If the targeted zone is the chest (or unavailable), redirects to a random other limb -
/// the blade never severs the chest directly.
/obj/item/ego_weapon/city/arayashiki/proc/DoDismemberZone(mob/living/carbon/M, zone, mob/living/user)
	if(!iscarbon(M))
		return
	playsound(M, 'sound/effects/dismember.ogg', 80, TRUE)
	if(zone == BODY_ZONE_HEAD)
		var/list/options = list(ORGAN_SLOT_EYES, ORGAN_SLOT_TONGUE)
		var/picked = pick(options)
		var/obj/item/organ/O = M.getorganslot(picked)
		if(!O)
			options -= picked
			O = M.getorganslot(options[1])
		if(O)
			M.visible_message(span_userdanger("[user] severs something from [M]'s head - the strike erases [O.name] entirely!"), \
				span_userdanger("Arayashiki \u963F\u983C\u8036\u8B58 takes your [O.name]. It is gone."))
			O.Remove(M)
			qdel(O)
			return
	var/obj/item/bodypart/BP = M.get_bodypart(zone)
	// Chest is sacred - redirect to a random limb. Also handles the case where the
	// originally-targeted zone is missing or undismemberable.
	if(zone == BODY_ZONE_CHEST || !BP || !BP.dismemberable)
		var/redirect = PickRandomLimbZone(M)
		if(redirect)
			BP = M.get_bodypart(redirect)
		else
			BP = null
	if(BP && BP.dismemberable)
		M.visible_message(span_userdanger("[user]'s blade severs [M]'s [BP.name]!"), \
			span_userdanger("Arayashiki \u963F\u983C\u8036\u8B58 severs your [BP.name] from your body."))
		BP.dismember(BRUTE)

/// Applies the permanent Bladewound component if not already present. Idempotent.
/obj/item/ego_weapon/city/arayashiki/proc/TryAttachBladewound(mob/living/carbon/M)
	if(!iscarbon(M))
		return
	if(M.GetComponent(/datum/component/tiansha_bladewound))
		return
	M.AddComponent(/datum/component/tiansha_bladewound)

/// Erasing Me, Erasing You - the finisher that fires when the target hits 100 Sever the Thread.
/// Five-second loop of dashes/slashes around the target, ends with a teleport-on-top final stroke.
/// Then a 2-second white-out and a 5-second alpha fade, followed by qdel.
/// During the fade, the target is no longer immobilized and can speak.
/// No damage is dealt - the cutscene is the kill via qdel.
/obj/item/ego_weapon/city/arayashiki/proc/PerformErasingMeErasingYou(mob/living/target, mob/living/user)
	set waitfor = FALSE
	if(QDELETED(target) || QDELETED(user))
		return

	target.visible_message(span_userdanger("[user] vanishes - Arayashiki is erasing [target] entirely!"), \
		span_userdanger("\"Erasing Me, Erasing You.\" Arayashiki severs your existence from the world."))
	playsound(target, 'sound/weapons/ego/justitia1.ogg', 100, TRUE)

	// Immobilize, not Stun: Stun makes mobs drop the blade at cutscene start
	target.Immobilize(6 SECONDS, ignore_canstun = TRUE)
	user.Immobilize(6 SECONDS, ignore_canstun = TRUE)

	var/end_time = world.time + 5 SECONDS
	while(world.time < end_time)
		if(QDELETED(target) || QDELETED(user))
			return
		if(prob(20))
			// "Stop next to them and slash" - 3 to 5 rapid slashes.
			var/list/adj = list()
			for(var/turf/open/T in orange(1, target))
				adj += T
			if(length(adj))
				user.forceMove(pick(adj))
				user.setDir(get_dir(user, target))
			for(var/i in 1 to rand(3, 5))
				if(QDELETED(target))
					return
				playsound(target, 'sound/weapons/bladeslice.ogg', 60, TRUE)
				new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(target), pick(GLOB.cardinals))
				sleep(1)
			sleep(rand(2, 4))
		else
			// "Dash through them" - teleport across to the opposite side.
			var/dir = pick(GLOB.cardinals)
			var/turf/start = get_step(get_turf(target), dir)
			var/turf/finish = get_step(get_turf(target), turn(dir, 180))
			if(start)
				user.forceMove(start)
				user.setDir(turn(dir, 180))
			sleep(1)
			playsound(target, 'sound/weapons/bladeslice.ogg', 70, TRUE)
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(target), dir)
			if(finish)
				user.forceMove(finish)
			sleep(rand(2, 4))

	if(QDELETED(target) || QDELETED(user))
		return

	// Final stroke: teleport on top, slash across.
	user.forceMove(get_turf(target))
	playsound(target, 'sound/weapons/ego/justitia2.ogg', 100, TRUE)
	for(var/d in GLOB.cardinals)
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(target), d)
	target.visible_message(span_userdanger("[user] cleaves [target] across with a final stroke!"))
	sleep(2)

	if(QDELETED(target))
		return

	// Target keeps Immobilize through the white + fade phases, but can still speak
	target.SetStun(0)
	target.Immobilize(7 SECONDS, ignore_canstun = TRUE)
	user.SetStun(0)
	user.SetImmobilized(0)

	// A matrix, not "#ffffff": colour multiplication would leave the target unchanged
	target.color = list(0,0,0, 0,0,0, 0,0,0, 1,1,1)
	sleep(2 SECONDS)

	if(QDELETED(target))
		return

	// Fade phase: alpha animates to 0 over 5 seconds.
	animate(target, alpha = 0, time = 5 SECONDS)
	sleep(5 SECONDS)

	if(QDELETED(target))
		return
	qdel(target)
