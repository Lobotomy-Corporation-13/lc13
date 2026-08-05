// LCE weapons. They read their paired worn armor's attunement to scale damage, and take
// a flat penalty (and no scaling) if the matching armor isn't worn. There are two bases:
// a melee base (/obj/item/ego_weapon/lce) and a ranged base (/obj/item/ego_weapon/ranged/lce)
// that scales bullet damage - future LCE guns should subtype the ranged base.

// ============================ MELEE BASE ============================
/obj/item/ego_weapon/lce
	icon = 'icons/obj/lce_egoweapons.dmi'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 20,
							PRUDENCE_ATTRIBUTE = 20,
							TEMPERANCE_ATTRIBUTE = 20,
							JUSTICE_ATTRIBUTE = 20
							)
	/// Must match the paired armor's family for the buffs to apply.
	var/attunement_family = ""
	/// Bonus damage at 100% attunement (1 = +100% force).
	var/max_damage_bonus = 0.5
	/// Damage cut when the matching armor isn't worn (0.5 = -50%).
	var/no_armor_penalty = 0.5

// The attunement-scaled force this weapon should hit for right now. Gimmick weapons that
// deal extra hits reuse this so their bonus damage scales too.
/obj/item/ego_weapon/lce/proc/AttunedForce(mob/user)
	var/obj/item/clothing/suit/armor/ego_gear/lce/armor = GetWornLCEArmor(user, attunement_family)
	if(!armor)
		return round(force * (1 - no_armor_penalty)) // No matching armor: weak and unscaled.
	return round(force * (1 + max_damage_bonus * armor.attunement / 100))

/obj/item/ego_weapon/lce/attack(mob/living/target, mob/living/user)
	var/obj/item/clothing/suit/armor/ego_gear/lce/armor = GetWornLCEArmor(user, attunement_family)
	var/saved_force = force
	force = AttunedForce(user)
	. = ..()
	force = saved_force
	if(armor)
		armor.HandleOverLimit(user) // Over-limit recoil, rate-limited on the armor.

// ============================ MELEE WEAPONS ============================
/obj/item/ego_weapon/lce/smile
	name = "LCE EGO: Smile"
	desc = "Putting your hands into it is rather unpleasant."
	special = "This weapon hits a second time after a windup that heals the user."
	icon_state = "smile"
	force = 40
	attack_speed = 1.6
	damtype = BLACK_DAMAGE
	hitsound = 'sound/weapons/ego/hammer.ogg'
	attunement_family = "smile"

/obj/item/ego_weapon/lce/smile/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return
	. = ..() // First hit, scaled + over-limit recoil handled by the LCE base.
	if(do_after(user, 12, src))
		if(QDELETED(target))
			return
		var/hit_force = AttunedForce(user) // Second hit scales with attunement too.
		target.deal_damage(hit_force, BLACK_DAMAGE, user, attack_type = (ATTACK_TYPE_MELEE))
		playsound(src, 'sound/weapons/fixer/generic/gen2.ogg', 100, TRUE)
		user.adjustBruteLoss(-hit_force/3)
	else
		to_chat(user, "<span class= 'spider'><b>Your attack was interrupted!</b></span>")
		balloon_alert(user, "Your attack was interrupted!")

/obj/item/ego_weapon/lce/hornet
	name = "LCE EGO: Hornet"
	desc = "A stinger honed to a wicked point."
	icon_state = "hornet"
	force = 34
	attack_speed = 1
	damtype = RED_DAMAGE
	attunement_family = "hornet"

//Grinder is supposed to be like the chainswords in Darktide.
/obj/item/ego_weapon/lce/grinder
	name = "LCE EGO: Grinder MK 4"
	desc = "A chainsword that reminds you of something..."
	special = "Use this weapon in hand to rev it up, making it attack 4 times in succession."
	icon_state = "grinder"
	force = 17
	attack_speed = 1 //has a very low DPS so that they can rev it up for multihits
	damtype = RED_DAMAGE
	attack_verb_continuous = list("slices", "saws", "rips")
	attack_verb_simple = list("slice", "saw", "rip")
	hitsound = 'sound/abnormalities/helper/attack.ogg'
	attunement_family = "grinder"
	var/chainsaw_amount = 4
	var/revved = FALSE
	var/saw_speed = 3

/obj/item/ego_weapon/lce/grinder/attack(mob/living/target, mob/living/user)
	if(!CanUseEgo(user))
		return FALSE
	if(revved)
		stuntime = 10
	. = ..() // LCE base scales the hit and handles the over-limit recoil.
	if(revved)
		chainsaw_amount--
		if(chainsaw_amount)
			addtimer(CALLBACK(src, PROC_REF(attack), target, user), saw_speed)
		else
			stuntime = 0
			revved = FALSE
			chainsaw_amount = initial(chainsaw_amount)

/obj/item/ego_weapon/lce/grinder/attack_self(mob/living/user)
	if(!revved)
		revved = TRUE
		to_chat(user, span_warning("You rev up Grinder MK4."))
		balloon_alert(user, "You rev up Grinder MK4.")
	else
		revved = FALSE
		to_chat(user, span_warning("You shut off Grinder MK4."))
		balloon_alert(user, "You shut off Grinder MK4.")
	..()

/obj/item/ego_weapon/lce/unrequited
	name = "LCE EGO: Unrequited Love"
	desc = "A knife that looks like it's made from sharpened bone."
	special = "Use this weapon in hand to dodgeroll."
	icon_state = "unrequited"
	force = 26
	swingstyle = WEAPONSWING_LARGESWEEP
	damtype = WHITE_DAMAGE
	hitsound = 'sound/weapons/fixer/generic/knife2.ogg'
	attunement_family = "unrequited"
	var/dodgelanding

/obj/item/ego_weapon/lce/unrequited/attack_self(mob/living/carbon/user)
	if(user.dir == 1)
		dodgelanding = locate(user.x, user.y + 5, user.z)
	if(user.dir == 2)
		dodgelanding = locate(user.x, user.y - 5, user.z)
	if(user.dir == 4)
		dodgelanding = locate(user.x + 5, user.y, user.z)
	if(user.dir == 8)
		dodgelanding = locate(user.x - 5, user.y, user.z)
	user.adjustStaminaLoss(20, TRUE, TRUE)
	user.throw_at(dodgelanding, 3, 2, spin = TRUE)

/obj/item/ego_weapon/lce/prank
	name = "LCE EGO: Prank"
	desc = "A prop that turned out to be entirely real."
	icon_state = "prank"
	force = 24
	attack_speed = 1
	damtype = BLACK_DAMAGE
	attunement_family = "prank"

/obj/item/ego_weapon/lce/match
	name = "LCE EGO: Fourth Match Flame"
	desc = "It smolders with a light that never quite goes out."
	icon_state = "match"
	force = 28
	attack_speed = 1
	damtype = RED_DAMAGE
	attunement_family = "match"

/obj/item/ego_weapon/lce/trick
	name = "LCE EGO: Hat Trick"
	desc = "A card's edge, sharpened until it bites."
	icon_state = "trick"
	force = 24
	attack_speed = 0.9
	damtype = WHITE_DAMAGE
	attunement_family = "trick"

// Two forms, one needle. Retracted it is a fast, cheap applicator that stacks Mental Decay;
// extended it is a slow lance that cashes those stacks in. Neither form reaches the LCE DPS
// median (26) on its own - retracted sits at ~23, extended at ~22 - because the payoff is
// the loop: stack Decay cheaply, then switch and collect. At 50 stacks (the status effect's
// max) the extended form's +1%/stack takes it to ~33 DPS, comfortably above median, which is
// what the two swaps and the self-stagger are being paid for.
/obj/item/ego_weapon/lce/acupuncture
	name = "LCE EGO: Acupuncture"
	desc = "One man's medicine is another man's poison."
	special = "Use in hand to extend or retract the needle.<br>\
	<b>Retracted:</b> fast and light, and every hit inflicts 2 Mental Decay.<br>\
	<b>Extended:</b> a lance. Slower, reaches 2 tiles, and staggers you on every hit, but it \
	deals 1% more damage per stack of Mental Decay on the target and detonates that Decay.<br><br>\
	(Mental Decay: Deals White damage every 5 seconds, equal to its stack, and then halves it. \
	If it is on a mob, then it deals *4 more damage.)"
	icon_state = "vivisection"
	force = 16
	attack_speed = 0.7
	damtype = BLACK_DAMAGE
	swingstyle = WEAPONSWING_SMALLSWEEP
	attack_verb_continuous = list("jabs", "pricks")
	attack_verb_simple = list("jab", "prick")
	hitsound = 'sound/weapons/fixer/generic/nail1.ogg'
	attunement_family = "acupuncture"
	/// FALSE = retracted needle, TRUE = extended lance. Retracted is the initial() form, so
	/// only the extended numbers need vars.
	var/extended = FALSE
	/// Mental Decay applied per hit while retracted.
	var/decay_inflict = 2
	/// Extended only: bonus damage per stack of Mental Decay already on the target.
	var/decay_damage_per_stack = 0.01
	var/extended_force = 26
	var/extended_speed = 1.2
	var/extended_stuntime = 5
	var/extended_reach = 2
	var/stagger_until = 0

/obj/item/ego_weapon/lce/acupuncture/proc/SetForm(extend, mob/user)
	extended = extend
	if(extended)
		force = extended_force
		attack_speed = extended_speed
		stuntime = extended_stuntime
		reach = extended_reach
		swingstyle = WEAPONSWING_THRUST
		icon_state = "vivisection_extended"
	else
		force = initial(force)
		attack_speed = initial(attack_speed)
		stuntime = initial(stuntime)
		reach = initial(reach)
		swingstyle = initial(swingstyle)
		icon_state = initial(icon_state)
	update_icon()
	if(user)
		user.update_inv_hands()

/obj/item/ego_weapon/lce/acupuncture/attack(mob/living/target, mob/living/user)
	var/saved_force = force
	// Read the stacks BEFORE the hit, and bump force before calling up: the LCE base scales
	// whatever force it finds by attunement, so setting it here makes the two bonuses compose
	// instead of one overwriting the other.
	if(extended && isliving(target))
		var/datum/status_effect/stacking/lc_mental_decay/D = target.has_status_effect(/datum/status_effect/stacking/lc_mental_decay)
		if(D)
			force = round(force * (1 + D.stacks * decay_damage_per_stack))
	. = ..() // LCE base scales the hit and handles the over-limit recoil.
	force = saved_force
	if(extended)
		stagger_until = world.time + stuntime
	if(!isliving(target))
		return
	if(extended)
		DetonateDecay(target) // after the hit, so the damage bonus reads the un-halved stacks
	else
		target.apply_lc_mental_decay(decay_inflict)

/obj/item/ego_weapon/lce/acupuncture/proc/DetonateDecay(mob/living/target)
	var/datum/status_effect/stacking/lc_mental_decay/D = target.has_status_effect(/datum/status_effect/stacking/lc_mental_decay)
	if(!D)
		return
	var/obj/effect/infinity/P = new get_turf(target)
	P.color = COLOR_PURPLE
	playsound(loc, 'sound/magic/staff_animation.ogg', 15, TRUE, extrarange = stealthy_audio ? SILENCED_SOUND_EXTRARANGE : -1, falloff_distance = 0)
	D.statues_damage(FALSE)

/obj/item/ego_weapon/lce/acupuncture/attack_self(mob/user)
	if(!CanUseEgo(user))
		return
	if(stagger_until > world.time)
		balloon_alert(user, "still recovering!")
		to_chat(user, span_warning("You cannot work the mechanism while the thrust is still throwing you off balance."))
		return
	SetForm(!extended, user)
	playsound(src, 'sound/weapons/batonextend.ogg', 40, TRUE)
	balloon_alert(user, extended ? "extended" : "retracted")
	to_chat(user, extended \
		? span_warning("The needle telescopes out into a lance.") \
		: span_notice("The lance folds back down into a needle."))
	..()

// ============================ SHIELD-BASED LCE ============================
// Vigil - the Knight of Despair's set. A tower shield instead of her rapier: she does not
// fight for herself, she stands in front of someone.
//
// It sits on the SHIELD base, not the LCE melee base. DM is single-inheritance and the two
// bases are siblings, so the LCE attunement glue (family, scaled force, over-limit recoil)
// is repeated below rather than inherited. It is kept deliberately identical to
// /obj/item/ego_weapon/lce so the two never drift apart in behaviour.
//
// Gimmick: blocking stores charges, and a charge calls one of the Knight's rapiers out of
// the air. Blocking is the only way to arm it, so the weapon only pays out for players who
// actually stand and take the hit.
/obj/item/ego_weapon/shield/vigil
	name = "LCE EGO: Despair"
	desc = "A tower shield of black plate, its face split by a single steel tear."
	special = "Blocking a source of damage stores a charge. Click a living target while holding a charge \
		to call a rapier out of the air: it takes half a second to form, then flies at wherever its \
		quarry is standing by then. No cooldown beyond the charges themselves. Attunement raises both \
		the rapiers' damage and how many charges you can hold (3 to 7)."
	icon = 'icons/obj/lce_egoweapons.dmi'
	// One state, deliberately: the cracked face is the best of the three and a shield that
	// never changes needs no others. vigil / vigil_raised were dropped from the sheet.
	icon_state = "vigil_cracked"
	force = 40
	attack_speed = 3
	damtype = WHITE_DAMAGE
	hitsound = 'sound/weapons/ego/shield1.ogg'
	// 100 total, in tens like every other shield in the game. Red and White lead because those
	// are what gets swung at whoever she is standing in front of; PALE held to 20 per the
	// shield table's shape, and because she resists it herself anyway.
	reductions = list(30, 30, 20, 20)
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 20,
							PRUDENCE_ATTRIBUTE = 20,
							TEMPERANCE_ATTRIBUTE = 20,
							JUSTICE_ATTRIBUTE = 20
							)
	// --- LCE glue, mirroring /obj/item/ego_weapon/lce ---
	/// Must match the paired armor's family for any of the scaling to apply.
	var/attunement_family = "despair"
	/// Bonus damage at 100% attunement (1 = +100%). Applies to the shield AND the rapiers.
	/// Kept at 0.5 to match this branch's LCE base. The source branch had raised
	/// every LCE weapon to 1; that global change was deliberately not ported.
	var/max_damage_bonus = 0.5
	/// Damage cut when the matching armor isn't worn.
	var/no_armor_penalty = 0.5
	// --- Charges ---
	/// Stored blocks, spent one per summoned rapier.
	var/charges = 0
	/// Charge cap at 0% and at 100% attunement; interpolated in between.
	var/min_max_charges = 3
	var/max_max_charges = 7
	/// Base PALE damage of a summoned rapier before attunement scaling.
	var/rapier_damage = 30
	/// How long a rapier takes to form before it flies.
	var/rapier_delay = 0.5 SECONDS

/obj/item/ego_weapon/shield/vigil/examine(mob/user)
	. = ..()
	. += span_notice("Stored blocks: <b>[charges]/[MaxCharges(user)]</b>.")

// ---- The LCE scaling, same shape as the melee base's ----
/obj/item/ego_weapon/shield/vigil/proc/AttunedForce(mob/user)
	var/obj/item/clothing/suit/armor/ego_gear/lce/armor = GetWornLCEArmor(user, attunement_family)
	if(!armor)
		return round(force * (1 - no_armor_penalty))
	return round(force * (1 + max_damage_bonus * armor.attunement / 100))

/obj/item/ego_weapon/shield/vigil/attack(mob/living/target, mob/living/user)
	var/obj/item/clothing/suit/armor/ego_gear/lce/armor = GetWornLCEArmor(user, attunement_family)
	var/saved_force = force
	force = AttunedForce(user)
	. = ..()
	force = saved_force
	if(armor)
		armor.HandleOverLimit(user)

/obj/item/ego_weapon/shield/vigil/proc/AttunedRapierDamage(mob/user)
	var/obj/item/clothing/suit/armor/ego_gear/lce/armor = GetWornLCEArmor(user, attunement_family)
	if(!armor)
		return round(rapier_damage * (1 - no_armor_penalty))
	return round(rapier_damage * (1 + max_damage_bonus * armor.attunement / 100))

/obj/item/ego_weapon/shield/vigil/proc/MaxCharges(mob/user)
	var/obj/item/clothing/suit/armor/ego_gear/lce/armor = GetWornLCEArmor(user, attunement_family)
	if(!armor)
		return min_max_charges
	return min_max_charges + round((max_max_charges - min_max_charges) * armor.attunement / 100)

// ---- Earning charges: every blocked source of damage is one ----
/obj/item/ego_weapon/shield/vigil/proc/GainCharge(mob/living/user)
	var/cap = MaxCharges(user)
	if(charges >= cap)
		return FALSE
	charges++
	playsound(get_turf(src), 'sound/weapons/ego/rapier1.ogg', 25, TRUE)
	balloon_alert(user, "despair [charges]/[cap]")
	return TRUE

// A blocked hit. The parent's own guard is repeated rather than read off block_success,
// because that flag stays TRUE for the rest of the block window - it says "this block caught
// something at some point", not "this particular hit landed on the shield".
// No SIGNAL_HANDLER here: it expands to `set SpacemanDMM_should_not_sleep`, which is only
// legal on a proc's initial definition. The parent declares it and overrides inherit it - so
// the must-not-sleep contract still applies to this body, it just cannot be restated.
/obj/item/ego_weapon/shield/vigil/AnnounceBlock(datum/source, damage, damagetype, def_zone)
	var/mob/living/carbon/human/H = source
	var/blocked_it = ishuman(source) && H.is_holding(src)
	. = ..()
	if(blocked_it)
		GainCharge(H)

// A deflected projectile counts too - it is still the shield eating a source of damage.
/obj/item/ego_weapon/shield/vigil/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	. = ..()
	if(attack_type == PROJECTILE_ATTACK && attacking)
		GainCharge(owner)

// ---- Spending them: click anything living ----
/obj/item/ego_weapon/shield/vigil/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!isliving(target) || target == user || !ishuman(user))
		return
	if(charges <= 0)
		return
	if(!CanUseEgo(user))
		return
	charges--
	SummonRapier(user, target)

/obj/item/ego_weapon/shield/vigil/proc/SummonRapier(mob/living/user, mob/living/target)
	var/turf/origin = get_step(get_turf(user), pick(GLOB.cardinals))
	if(!origin || origin.density)
		origin = get_turf(user)
	if(!origin)
		return
	var/obj/projectile/despair_rapier/vigil/P = new(origin)
	P.damage = AttunedRapierDamage(user)
	P.firer = user
	P.starting = origin
	P.fired_from = origin
	playsound(get_turf(user), 'sound/abnormalities/despairknight/attack.ogg', 35, FALSE, 3)
	// Calling a rapier is as much of a strain as swinging the shield, so it burns an
	// over-attuned wearer exactly like a melee hit does. HandleOverLimit is rate-limited on
	// the armor itself, so this shares one cooldown with her attacks rather than stacking.
	var/obj/item/clothing/suit/armor/ego_gear/lce/armor = GetWornLCEArmor(user, attunement_family)
	if(armor)
		armor.HandleOverLimit(user)
	balloon_alert(user, "despair [charges]/[MaxCharges(user)]")
	addtimer(CALLBACK(src, PROC_REF(LaunchRapier), P, target, origin), rapier_delay)

/obj/item/ego_weapon/shield/vigil/proc/LaunchRapier(obj/projectile/P, atom/target, turf/origin)
	if(QDELETED(P))
		return
	if(QDELETED(target) || !origin)
		qdel(P)
		return
	// Aimed where the quarry is NOW, not where they stood when it was called. Half a second
	// is long enough to walk out of the line, which is what makes it a telegraph.
	P.yo = target.y - origin.y
	P.xo = target.x - origin.x
	P.original = target
	P.preparePixelProjectile(target, origin)
	P.fire()

// The rapiers Vigil calls. PALE like the Knight's own, but their damage is set per-instance
// from the wearer's attunement rather than being fixed on the type.
/obj/projectile/despair_rapier/vigil
	damage = 25
	spread = 0

/obj/projectile/despair_rapier/vigil/Initialize()
	. = ..()
	animate(src, alpha = 255, time = 5) // Half a second to form, matching rapier_delay.

// ============================ RANGED BASE ============================
// Scales its bullets' damage with the worn matching armor's attunement. Future LCE guns
// subtype this and just set their projectile/ammo stats.
/obj/item/ego_weapon/ranged/lce
	icon = 'icons/obj/lce_egoweapons.dmi'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 20,
							PRUDENCE_ATTRIBUTE = 20,
							TEMPERANCE_ATTRIBUTE = 20,
							JUSTICE_ATTRIBUTE = 20
							)
	/// Must match the paired armor's family for the buffs to apply.
	var/attunement_family = ""
	/// Bonus bullet damage at 100% attunement (0.5 = +50%).
	var/max_damage_bonus = 0.5
	/// Bullet damage cut when the matching armor isn't worn (0.5 = -50%).
	var/no_armor_penalty = 0.5

// before_firing runs right before each projectile is created, so we set the damage
// multiplier here from the current attunement.
/obj/item/ego_weapon/ranged/lce/before_firing(atom/target, mob/user)
	var/obj/item/clothing/suit/armor/ego_gear/lce/armor = GetWornLCEArmor(user, attunement_family)
	if(!armor)
		projectile_damage_multiplier = initial(projectile_damage_multiplier) * (1 - no_armor_penalty)
	else
		projectile_damage_multiplier = initial(projectile_damage_multiplier) * (1 + max_damage_bonus * armor.attunement / 100)
		armor.HandleOverLimit(user)
	return ..()

// ============================ RANGED WEAPONS ============================
// Beak - a two-handed shotgun paired with the Beak armor.
/obj/item/ego_weapon/ranged/lce/beak
	name = "LCE EGO: Beak"
	desc = "A stout scattergun that spits a cone of shot."
	icon_state = "beak"
	force = 12
	damtype = RED_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_beak
	weapon_weight = WEAPON_HEAVY
	fire_delay = 10
	shotsleft = 6
	reloadtime = 1.6 SECONDS
	pellets = 6
	variance = 20
	randomspread = 0
	fire_sound = 'sound/weapons/gun/shotgun/shot.ogg'
	attunement_family = "beak"
