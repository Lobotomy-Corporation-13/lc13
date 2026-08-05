// LCE Attunement system - base armor logic + the LCE armor suits.
// A worn LCE armor carries an attunement % (0-100). Higher attunement makes its paired
// LCE weapon hit harder; pushing past your personal safe limit inflicts debuffs. The safe
// limit is derived from how much you have bonded with the source abnormality.
// Adding a new LCE set is just config: set attunement_family + paired_weapon here, define
// the weapon in lce_weapons.dm, and add an armor ego_datum in lce_datum.dm.


// ---- Global state ----
// family -> list of live LCE armor instances (worn or not). Used by the abno Communion
// action and by weapons that need to find their armor.
GLOBAL_LIST_EMPTY(lce_armors)
// "[ckey]-[family]" -> accumulated interaction points with that abno family.
GLOBAL_LIST_EMPTY(lce_attunement_affinity)

// Returns the worn LCE armor matching the given family, or null. Used by LCE weapons.
/proc/GetWornLCEArmor(mob/user, family)
	if(!ishuman(user) || !family)
		return null
	var/obj/item/clothing/suit/armor/ego_gear/lce/A = user.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(istype(A) && A.attunement_family == family)
		return A
	return null

// ---- Base LCE armor: attunement state + behavior ----
/obj/item/clothing/suit/armor/ego_gear/lce
	icon = 'icons/obj/clothing/ego_gear/limbus_labs.dmi'
	worn_icon = 'icons/mob/clothing/ego_gear/limbus_labs.dmi'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 20,
							PRUDENCE_ATTRIBUTE = 20,
							TEMPERANCE_ATTRIBUTE = 20,
							JUSTICE_ATTRIBUTE = 20
							)
	actions_types = list(
		/datum/action/item_action/lce_attune_raise,
		/datum/action/item_action/lce_attune_lower,
		/datum/action/item_action/lce_attune_step,
		/datum/action/item_action/lce_locate,
	)
	/// Current attunement, 0-100.
	var/attunement = 0
	/// How much a raise/lower button press changes attunement (1 / 5 / 10).
	var/attunement_step = 5
	/// Safe attunement ceiling for the current wearer, computed on equip.
	var/safe_limit = 0
	/// Floor everyone gets even with no bond to the abno.
	var/safe_limit_floor = 10
	/// Links this armor to its weapon and its source abno.
	var/attunement_family = ""
	/// The LCE weapon spawned with (and bound to) this armor.
	var/paired_weapon = null
	var/obj/item/ego_weapon/tracked_weapon
	/// Rate-limit timer for the over-limit attack burn (so attack speed doesn't matter).
	var/next_overlimit_burn = 0
	var/summon_cooldown = 0
	// --- Per-set attunement tuning. ---
	/// Affinity points needed per +1% safe limit.
	var/attunement_points_per_percent = 3
	/// Max-SP (PRUDENCE) reduction per 1% over the safe limit.
	var/overload_sp_per_over = 0.3
	/// Self-damage per attack per 1% over the safe limit.
	var/overload_dmg_per_over = 0.8
	/// Minimum gap between over-limit burns.
	var/overload_burn_cooldown = 1.5 SECONDS
	/// Cooldown on summoning a lost weapon.
	var/weapon_summon_cooldown = 30 SECONDS

/obj/item/clothing/suit/armor/ego_gear/lce/Initialize(mapload)
	. = ..()
	if(attunement_family)
		if(!GLOB.lce_armors[attunement_family])
			GLOB.lce_armors[attunement_family] = list()
		GLOB.lce_armors[attunement_family] |= src
	if(paired_weapon && get_turf(src))
		SpawnPairedWeapon(get_turf(src))

/obj/item/clothing/suit/armor/ego_gear/lce/Destroy()
	// If destroyed while worn, make sure we don't leave the wearer's SP debuff stuck on.
	if(isliving(loc))
		var/mob/living/L = loc
		L.remove_status_effect(/datum/status_effect/attunement_overload)
	if(attunement_family && GLOB.lce_armors[attunement_family])
		GLOB.lce_armors[attunement_family] -= src
	if(tracked_weapon)
		// Armor destroyed -> its weapon disappears with it.
		UnregisterSignal(tracked_weapon, COMSIG_PARENT_QDELETING)
		qdel(tracked_weapon)
		tracked_weapon = null
	return ..()

// ---- Weapon pairing ----
/obj/item/clothing/suit/armor/ego_gear/lce/proc/SpawnPairedWeapon(atom/where)
	if(!paired_weapon || tracked_weapon)
		return
	var/obj/item/ego_weapon/W = new paired_weapon(where)
	// The weapon comes as part of the set, so anyone who can wear the armor can use it.
	// (Attunement, not attributes, is what makes it strong.)
	W.attribute_requirements = list()
	tracked_weapon = W
	RegisterSignal(W, COMSIG_PARENT_QDELETING, PROC_REF(OnWeaponDestroyed))

/obj/item/clothing/suit/armor/ego_gear/lce/proc/OnWeaponDestroyed(datum/source)
	SIGNAL_HANDLER
	tracked_weapon = null // Now the locate button switches to "summon" mode.

// ---- Equip / unequip ----
/obj/item/clothing/suit/armor/ego_gear/lce/equipped(mob/user, slot)
	. = ..()
	if(slot != ITEM_SLOT_OCLOTHING)
		return
	safe_limit = clamp(safe_limit_floor + round(GetAffinity(user) / attunement_points_per_percent), safe_limit_floor, 100)
	RefreshAttunement(user)

/obj/item/clothing/suit/armor/ego_gear/lce/dropped(mob/user)
	. = ..()
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.remove_status_effect(/datum/status_effect/attunement_overload)

/obj/item/clothing/suit/armor/ego_gear/lce/proc/GetAffinity(mob/user)
	if(!user?.ckey || !attunement_family)
		return 0
	return GLOB.lce_attunement_affinity["[user.ckey]-[attunement_family]"] || 0

// ---- The one place that reconciles buffs/debuffs ----
/obj/item/clothing/suit/armor/ego_gear/lce/proc/RefreshAttunement(mob/living/carbon/human/user)
	if(!istype(user))
		return
	var/over = attunement - safe_limit
	user.remove_status_effect(/datum/status_effect/attunement_overload)
	if(over > 0)
		user.apply_status_effect(/datum/status_effect/attunement_overload, round(over * overload_sp_per_over))

// Over-limit self-damage on attack, rate-limited so fast weapons don't burn you more.
// Called by the paired weapon when it hits while over the safe limit.
/obj/item/clothing/suit/armor/ego_gear/lce/proc/HandleOverLimit(mob/living/user)
	var/over = attunement - safe_limit
	if(over <= 0)
		return
	// Sparks fly off the suit on every over-limit swing, so onlookers can see the strain.
	OverloadSparks(user)
	if(world.time < next_overlimit_burn)
		return
	next_overlimit_burn = world.time + overload_burn_cooldown
	// Direct BRUTE + pure SP damage, so it bypasses EGO armour resistances (a black-armoured
	// LCE suit shouldn't get to soak its own overload backlash).
	var/burn = round(over * overload_dmg_per_over)
	user.adjustBruteLoss(burn)
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		H.adjustSanityLoss(burn)

/obj/item/clothing/suit/armor/ego_gear/lce/proc/OverloadSparks(mob/living/user)
	var/turf/T = get_turf(user)
	if(!T)
		return
	for(var/i in 1 to 3)
		new /obj/effect/temp_visual/lce_overload_spark(T)

// ---- Attunement multiplier the weapons read ----
/obj/item/clothing/suit/armor/ego_gear/lce/proc/AttunementFrac()
	return attunement / 100

// ---- Action buttons ----
/obj/item/clothing/suit/armor/ego_gear/lce/ui_action_click(mob/user, datum/action/source)
	if(istype(source, /datum/action/item_action/lce_attune_raise))
		AdjustAttunement(user, attunement_step)
	else if(istype(source, /datum/action/item_action/lce_attune_lower))
		AdjustAttunement(user, -attunement_step)
	else if(istype(source, /datum/action/item_action/lce_attune_step))
		CycleStep(user)
	else if(istype(source, /datum/action/item_action/lce_locate))
		LocateOrSummon(user)

/obj/item/clothing/suit/armor/ego_gear/lce/proc/AdjustAttunement(mob/user, delta)
	attunement = clamp(attunement + delta, 0, 100)
	RefreshAttunement(user)
	playsound(src, 'sound/machines/click.ogg', 40, TRUE)
	balloon_alert(user, "attunement [attunement]% (safe [safe_limit]%)")

/obj/item/clothing/suit/armor/ego_gear/lce/proc/CycleStep(mob/user)
	switch(attunement_step)
		if(1)
			attunement_step = 5
		if(5)
			attunement_step = 10
		else
			attunement_step = 1
	UpdateStepIcon()
	playsound(src, 'sound/machines/click.ogg', 40, TRUE)
	balloon_alert(user, "step [attunement_step]%")

/obj/item/clothing/suit/armor/ego_gear/lce/proc/UpdateStepIcon()
	for(var/datum/action/item_action/lce_attune_step/S in actions)
		S.button_icon_state = "step_[attunement_step]"
		S.UpdateButtonIcon()

// ---- Locate / summon the paired weapon ----
/obj/item/clothing/suit/armor/ego_gear/lce/proc/LocateOrSummon(mob/living/user)
	if(tracked_weapon && get_turf(tracked_weapon))
		PointToWeapon(user)
	else
		SummonWeapon(user)

// A short trail of sparks toward the dropped weapon, in the rose_sign style.
/obj/item/clothing/suit/armor/ego_gear/lce/proc/PointToWeapon(mob/living/user)
	var/turf/uturf = get_turf(user)
	var/turf/wturf = get_turf(tracked_weapon)
	if(!uturf || !wturf)
		return
	if(uturf.z != wturf.z)
		to_chat(user, span_warning("[tracked_weapon] is beyond your senses."))
		return
	var/turf/step_turf = uturf
	for(var/i in 1 to 8)
		if(step_turf == wturf)
			break
		step_turf = get_step_towards(step_turf, wturf)
		if(!step_turf)
			break
		new /obj/effect/temp_visual/cult/sparks(step_turf)
	to_chat(user, span_notice("You sense [tracked_weapon] to the [dir2text(get_dir(uturf, wturf))]."))

/obj/item/clothing/suit/armor/ego_gear/lce/proc/SummonWeapon(mob/living/user)
	if(!paired_weapon)
		return
	if(world.time < summon_cooldown)
		to_chat(user, span_warning("You cannot recall your EGO weapon again so soon."))
		return
	summon_cooldown = world.time + weapon_summon_cooldown
	SpawnPairedWeapon(get_turf(user))
	if(tracked_weapon)
		user.put_in_hands(tracked_weapon)
		to_chat(user, span_notice("You manifest [tracked_weapon] into your grip."))

// ---- Examine ----
/obj/item/clothing/suit/armor/ego_gear/lce/examine(mob/user)
	. = ..()
	. += span_notice("Attunement: [attunement]% (adjust step: [attunement_step]%).")
	if(ishuman(user) && user.get_item_by_slot(ITEM_SLOT_OCLOTHING) == src)
		. += span_notice("Your safe attunement limit for this EGO is [safe_limit]%. Past it, your mind and body pay the price.")
	else
		. += span_notice("How high it can be safely attuned depends on the wearer's bond with the source abnormality.")

// ---- The four worn action buttons ----
/datum/action/item_action/lce_attune_raise
	name = "Raise Attunement"
	desc = "Raise your EGO attunement by the current step."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lce_actions.dmi'
	button_icon_state = "attune_up"

/datum/action/item_action/lce_attune_lower
	name = "Lower Attunement"
	desc = "Lower your EGO attunement by the current step."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lce_actions.dmi'
	button_icon_state = "attune_down"

/datum/action/item_action/lce_attune_step
	name = "Attunement Step"
	desc = "Cycle how much each adjustment changes your attunement (1% / 5% / 10%)."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lce_actions.dmi'
	button_icon_state = "step_5"

/datum/action/item_action/lce_locate
	name = "Locate EGO Weapon"
	desc = "Sense your paired weapon if it is dropped, or manifest it into your hands if it was destroyed."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/lce_actions.dmi'
	button_icon_state = "locate_weapon"

// ==================================================================================
// The LCE armor suits. Each just sets its stat block + attunement_family + paired_weapon.
// ==================================================================================

//All high Security armor adds to 90.
//LOL THE FIRST EGO IS AN ALEPH
/obj/item/clothing/suit/armor/ego_gear/lce/smile
	name = "LCE EGO: Smile"
	desc = "This armor pulsates with hatred or.... something else."
	icon_state = "smile"
	armor = list(RED_DAMAGE = 20, WHITE_DAMAGE = 20, BLACK_DAMAGE = 40, PALE_DAMAGE = 10)
	attunement_family = "smile"
	paired_weapon = /obj/item/ego_weapon/lce/smile

/obj/item/clothing/suit/armor/ego_gear/lce/hornet
	name = "LCE EGO: Hornet"
	desc = "It's covered in a thin layer of pollen."
	icon_state = "hornet"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = 20, BLACK_DAMAGE = 20, PALE_DAMAGE = 10)
	attunement_family = "hornet"
	paired_weapon = /obj/item/ego_weapon/lce/hornet

//Low-Sec armor adds to 60.
/obj/item/clothing/suit/armor/ego_gear/lce/grinder
	name = "LCE EGO: Grinder MK 4"
	desc = "The broach glows with a soft light."
	icon_state = "grinder"
	armor = list(RED_DAMAGE = 40, WHITE_DAMAGE = -10, BLACK_DAMAGE = 20, PALE_DAMAGE = 10)
	attunement_family = "grinder"
	paired_weapon = /obj/item/ego_weapon/lce/grinder

/obj/item/clothing/suit/armor/ego_gear/lce/unrequited
	name = "LCE EGO: Unrequited Love"
	desc = "The armor is covered in scales, as if scaled like a fish."
	icon_state = "unrequited"
	armor = list(RED_DAMAGE = -10, WHITE_DAMAGE = 30, BLACK_DAMAGE = 20, PALE_DAMAGE = 20)
	attunement_family = "unrequited"
	paired_weapon = /obj/item/ego_weapon/lce/unrequited

/obj/item/clothing/suit/armor/ego_gear/lce/beak
	name = "LCE EGO: Beak"
	desc = "The fabric looks to be an unremarkable quality, as if it's regular clothes."
	icon_state = "beak"
	armor = list(RED_DAMAGE = 30, WHITE_DAMAGE = 30, BLACK_DAMAGE = -10, PALE_DAMAGE = 10)
	attunement_family = "beak"
	paired_weapon = /obj/item/ego_weapon/ranged/lce/beak

/obj/item/clothing/suit/armor/ego_gear/lce/prank
	name = "LCE EGO: Prank"
	desc = "A dress that smells of long-gone candy."
	icon_state = "prank"
	armor = list(RED_DAMAGE = 10, WHITE_DAMAGE = 10, BLACK_DAMAGE = 30, PALE_DAMAGE = 10)
	attunement_family = "prank"
	paired_weapon = /obj/item/ego_weapon/lce/prank

/obj/item/clothing/suit/armor/ego_gear/lce/match
	name = "LCE EGO: Fourth Match Flame"
	desc = "The suit glows with an otherworldly light."
	icon_state = "match"
	armor = list(RED_DAMAGE = 30, WHITE_DAMAGE = 10, BLACK_DAMAGE = 10, PALE_DAMAGE = 10)
	attunement_family = "match"
	paired_weapon = /obj/item/ego_weapon/lce/match

/obj/item/clothing/suit/armor/ego_gear/lce/trick
	name = "LCE EGO: Hat Trick"
	desc = "The Ace on the back of the suit is embroidered beautifully."
	icon_state = "trick"
	armor = list(RED_DAMAGE = 10, WHITE_DAMAGE = 20, BLACK_DAMAGE = 20, PALE_DAMAGE = 10)
	attunement_family = "trick"
	paired_weapon = /obj/item/ego_weapon/lce/trick

/obj/item/clothing/suit/armor/ego_gear/lce/despair
	name = "LCE EGO: Despair"
	desc = "A blue dress stitched from a knight's unspent devotion."
	icon_state = "despair"
	armor = list(RED_DAMAGE = 20, WHITE_DAMAGE = 30, BLACK_DAMAGE = 10, PALE_DAMAGE = 30)
	attunement_family = "despair"
	paired_weapon = /obj/item/ego_weapon/shield/vigil

/obj/item/clothing/suit/armor/ego_gear/lce/acupuncture
	name = "LCE EGO: Acupuncture"
	desc = "Realize that this is good for you."
	icon_state = "acupuncture"
	armor = list(RED_DAMAGE = 0, WHITE_DAMAGE = 10, BLACK_DAMAGE = 20, PALE_DAMAGE = 10)
	slowdown = -0.15
	attunement_family = "acupuncture"
	paired_weapon = /obj/item/ego_weapon/lce/acupuncture

