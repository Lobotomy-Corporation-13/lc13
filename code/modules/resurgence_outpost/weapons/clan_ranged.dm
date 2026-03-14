/**
 * Resurgence Outpost - Clan Ranged Weapons
 *
 * All clan ranged weapons in one file: ballistic guns, faith guns, and ammo systems.
 * Ballistic: Damage = base_projectile × gun_rarity × ammo_rarity × faith_mult.
 * Faith: Consume faith per shot, no ammo needed.
 *
 * PISTOLS: Standard, Machine Pistol (burst), Heavy Pistol (1.5x damage)
 * RIFLES: Standard, Assault Rifle (burst), Longrifle (aimed shot gimmick)
 * SMGs: Repeater (overdrive gimmick), Compact SMG (fast/small)
 * SHOTGUNS: Pump Shotgun, Combat Shotgun (semi-auto)
 * FAITH: Void Caster (BLACK), Pale Lance (PALE), Voidstaff (teleport gimmick)
 */

// ================================================================
// PROJECTILES
// ================================================================

/obj/projectile/bullet/clan_pistol
	name = "clan pistol round"
	icon_state = "bullet"
	damage = 18
	damage_type = RED_DAMAGE

/obj/projectile/bullet/clan_rifle
	name = "clan rifle round"
	icon_state = "bullet"
	damage = 35
	damage_type = RED_DAMAGE

/obj/projectile/bullet/clan_smg
	name = "clan SMG round"
	icon_state = "bullet"
	damage = 8
	damage_type = RED_DAMAGE

/obj/projectile/bullet/clan_shotgun
	name = "clan shotgun pellet"
	icon_state = "bullet"
	damage = 8
	damage_type = RED_DAMAGE

// ================================================================
// AMMO CASINGS (all tiers use same projectile, rarity on casing)
// ================================================================

// --- Pistol ---
/obj/item/ammo_casing/clan_pistol
	name = "clan pistol bullet casing"
	desc = "A clan-forged pistol round."
	caliber = CALIBER_CLAN_PISTOL
	projectile_type = /obj/projectile/bullet/clan_pistol
	var/rarity = CLAN_RARITY_REGULAR

/obj/item/ammo_casing/clan_pistol/militia
	name = "militia pistol bullet casing"
	rarity = CLAN_RARITY_MILITIA

/obj/item/ammo_casing/clan_pistol/veteran
	name = "veteran pistol bullet casing"
	rarity = CLAN_RARITY_VETERAN

/obj/item/ammo_casing/clan_pistol/elite
	name = "elite pistol bullet casing"
	rarity = CLAN_RARITY_ELITE

// --- Rifle ---
/obj/item/ammo_casing/clan_rifle
	name = "clan rifle bullet casing"
	desc = "A clan-forged rifle round."
	caliber = CALIBER_CLAN_RIFLE
	projectile_type = /obj/projectile/bullet/clan_rifle
	var/rarity = CLAN_RARITY_REGULAR

/obj/item/ammo_casing/clan_rifle/militia
	name = "militia rifle bullet casing"
	rarity = CLAN_RARITY_MILITIA

/obj/item/ammo_casing/clan_rifle/veteran
	name = "veteran rifle bullet casing"
	rarity = CLAN_RARITY_VETERAN

/obj/item/ammo_casing/clan_rifle/elite
	name = "elite rifle bullet casing"
	rarity = CLAN_RARITY_ELITE

// --- SMG ---
/obj/item/ammo_casing/clan_smg
	name = "clan SMG bullet casing"
	desc = "A clan-forged SMG round."
	caliber = CALIBER_CLAN_SMG
	projectile_type = /obj/projectile/bullet/clan_smg
	var/rarity = CLAN_RARITY_REGULAR

/obj/item/ammo_casing/clan_smg/militia
	name = "militia SMG bullet casing"
	rarity = CLAN_RARITY_MILITIA

/obj/item/ammo_casing/clan_smg/veteran
	name = "veteran SMG bullet casing"
	rarity = CLAN_RARITY_VETERAN

/obj/item/ammo_casing/clan_smg/elite
	name = "elite SMG bullet casing"
	rarity = CLAN_RARITY_ELITE

// --- Shotgun ---
/obj/item/ammo_casing/clan_shotgun
	name = "clan shotgun shell"
	desc = "A clan-forged shotgun shell loaded with pellets."
	caliber = CALIBER_CLAN_SHOTGUN
	projectile_type = /obj/projectile/bullet/clan_shotgun
	pellets = 5
	variance = 25
	var/rarity = CLAN_RARITY_REGULAR

/obj/item/ammo_casing/clan_shotgun/militia
	name = "militia shotgun shell"
	rarity = CLAN_RARITY_MILITIA

/obj/item/ammo_casing/clan_shotgun/veteran
	name = "veteran shotgun shell"
	rarity = CLAN_RARITY_VETERAN

/obj/item/ammo_casing/clan_shotgun/elite
	name = "elite shotgun shell"
	rarity = CLAN_RARITY_ELITE

// ================================================================
// MAGAZINES
// ================================================================

/obj/item/ammo_box/magazine/clan_pistol
	name = "clan pistol magazine"
	desc = "A standard clan pistol magazine."
	icon_state = "9x19p"
	ammo_type = /obj/item/ammo_casing/clan_pistol
	caliber = CALIBER_CLAN_PISTOL
	max_ammo = 20

/obj/item/ammo_box/magazine/clan_rifle
	name = "clan rifle magazine"
	desc = "A standard clan rifle magazine."
	icon_state = "9x19p"
	ammo_type = /obj/item/ammo_casing/clan_rifle
	caliber = CALIBER_CLAN_RIFLE
	max_ammo = 12

/obj/item/ammo_box/magazine/clan_smg
	name = "clan SMG magazine"
	desc = "A standard clan SMG magazine."
	icon_state = "9x19p"
	ammo_type = /obj/item/ammo_casing/clan_smg
	caliber = CALIBER_CLAN_SMG
	max_ammo = 50

// --- Shotgun internal magazines ---
/obj/item/ammo_box/magazine/internal/clan_shotgun
	name = "clan pump shotgun tube"
	ammo_type = /obj/item/ammo_casing/clan_shotgun
	caliber = CALIBER_CLAN_SHOTGUN
	max_ammo = 10

/obj/item/ammo_box/magazine/internal/clan_shotgun/combat
	name = "clan combat shotgun tube"
	max_ammo = 15

// ================================================================
// AMMO BOXES (craftable)
// ================================================================

/obj/item/ammo_box/clan_pistol_ammo
	name = "box of clan pistol rounds"
	desc = "A box of clan-forged pistol rounds."
	icon_state = "9mmbox"
	ammo_type = /obj/item/ammo_casing/clan_pistol
	max_ammo = 30

/obj/item/ammo_box/clan_pistol_ammo/militia
	name = "box of militia pistol rounds"
	ammo_type = /obj/item/ammo_casing/clan_pistol/militia

/obj/item/ammo_box/clan_pistol_ammo/veteran
	name = "box of veteran pistol rounds"
	ammo_type = /obj/item/ammo_casing/clan_pistol/veteran

/obj/item/ammo_box/clan_pistol_ammo/elite
	name = "box of elite pistol rounds"
	ammo_type = /obj/item/ammo_casing/clan_pistol/elite

/obj/item/ammo_box/clan_rifle_ammo
	name = "box of clan rifle rounds"
	desc = "A box of clan-forged rifle rounds."
	icon_state = "762"
	ammo_type = /obj/item/ammo_casing/clan_rifle
	max_ammo = 20

/obj/item/ammo_box/clan_rifle_ammo/militia
	name = "box of militia rifle rounds"
	ammo_type = /obj/item/ammo_casing/clan_rifle/militia

/obj/item/ammo_box/clan_rifle_ammo/veteran
	name = "box of veteran rifle rounds"
	ammo_type = /obj/item/ammo_casing/clan_rifle/veteran

/obj/item/ammo_box/clan_rifle_ammo/elite
	name = "box of elite rifle rounds"
	ammo_type = /obj/item/ammo_casing/clan_rifle/elite

/obj/item/ammo_box/clan_smg_ammo
	name = "box of clan SMG rounds"
	desc = "A box of clan-forged SMG rounds."
	icon_state = "9mmbox"
	ammo_type = /obj/item/ammo_casing/clan_smg
	max_ammo = 50

/obj/item/ammo_box/clan_smg_ammo/militia
	name = "box of militia SMG rounds"
	ammo_type = /obj/item/ammo_casing/clan_smg/militia

/obj/item/ammo_box/clan_smg_ammo/veteran
	name = "box of veteran SMG rounds"
	ammo_type = /obj/item/ammo_casing/clan_smg/veteran

/obj/item/ammo_box/clan_smg_ammo/elite
	name = "box of elite SMG rounds"
	ammo_type = /obj/item/ammo_casing/clan_smg/elite

/obj/item/ammo_box/clan_shotgun_ammo
	name = "box of clan shotgun shells"
	desc = "A box of clan-forged shotgun shells."
	icon_state = "40mm"
	ammo_type = /obj/item/ammo_casing/clan_shotgun
	max_ammo = 20

/obj/item/ammo_box/clan_shotgun_ammo/militia
	name = "box of militia shotgun shells"
	ammo_type = /obj/item/ammo_casing/clan_shotgun/militia

/obj/item/ammo_box/clan_shotgun_ammo/veteran
	name = "box of veteran shotgun shells"
	ammo_type = /obj/item/ammo_casing/clan_shotgun/veteran

/obj/item/ammo_box/clan_shotgun_ammo/elite
	name = "box of elite shotgun shells"
	ammo_type = /obj/item/ammo_casing/clan_shotgun/elite

// ================================================================
// HELPER PROC
// ================================================================

/// Get faith-based damage multiplier for a mob (ranged version)
/proc/get_clan_weapon_faith_multiplier(mob/living/user)
	if(!ishuman(user))
		return 1.0
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!core)
		return 1.0
	if(core.faith >= 80)
		return 1.15
	if(core.faith >= 60)
		return 1.0
	if(core.faith >= 40)
		return 0.9
	if(core.faith >= 20)
		return 0.8
	return 0.7

// ================================================================
// PISTOLS
// ================================================================

// --- Standard Pistol ---
/obj/item/gun/ballistic/automatic/pistol/clan
	name = "clan pistol"
	desc = "A compact sidearm forged by the Resurgence Clan. Reliable and easy to maintain."
	icon_state = "pistol"
	w_class = WEIGHT_CLASS_SMALL
	mag_type = /obj/item/ammo_box/magazine/clan_pistol
	fire_sound = 'sound/weapons/gun/pistol/shot.ogg'
	rack_sound = 'sound/weapons/gun/pistol/rack_small.ogg'
	lock_back_sound = 'sound/weapons/gun/pistol/lock_small.ogg'
	bolt_drop_sound = 'sound/weapons/gun/pistol/drop_small.ogg'
	fire_sound_volume = 90
	can_suppress = FALSE
	burst_size = 1
	fire_delay = 0
	actions_types = list()
	bolt_type = BOLT_TYPE_LOCKING
	bolt_wording = "slide"
	show_bolt_icon = FALSE
	spawnwithmagazine = FALSE
	/// Weapon rarity tier
	var/rarity = CLAN_RARITY_REGULAR

/obj/item/gun/ballistic/automatic/pistol/clan/Initialize()
	. = ..()
	update_rarity_visuals()

/// Set gun rarity and update visuals/name
/obj/item/gun/ballistic/automatic/pistol/clan/proc/set_rarity(new_rarity)
	rarity = new_rarity
	update_rarity_visuals()
	if(rarity == CLAN_RARITY_REGULAR)
		name = "clan pistol"
	else
		name = "[lowertext(clan_rarity_name(rarity))] clan pistol"

/// Update the outline filter to match current rarity
/obj/item/gun/ballistic/automatic/pistol/clan/proc/update_rarity_visuals()
	var/color = clan_rarity_color(rarity)
	remove_filter("clan_rarity")
	add_filter("clan_rarity", 2, list("type" = "outline", "color" = color, "size" = 1))

/// Delete empty magazines on eject
/obj/item/gun/ballistic/automatic/pistol/clan/eject_magazine(mob/user, display_message = TRUE, obj/item/ammo_box/magazine/tac_load = null)
	var/obj/item/ammo_box/magazine/old_mag = magazine
	. = ..()
	if(old_mag && !old_mag.ammo_count())
		QDEL_IN(old_mag, 1)

/obj/item/gun/ballistic/automatic/pistol/clan/examine(mob/user)
	. = ..()
	. += span_notice("Rarity: [clan_rarity_name(rarity)]")

/// Applies rarity × ammo × faith multipliers before the base gun fires
/obj/item/gun/ballistic/automatic/pistol/clan/process_fire(atom/target, mob/living/user, message, params, zone_override, bonus_spread)
	if(chambered)
		var/obj/projectile/P = chambered.BB
		if(P)
			var/gun_mult = clan_rarity_multiplier(rarity)
			var/faith_mult = get_clan_weapon_faith_multiplier(user)
			var/ammo_mult = get_chambered_ammo_rarity()
			P.damage = round(initial(P.damage) * gun_mult * ammo_mult * faith_mult)
	// Call grandparent — skip to /obj/item/gun/ballistic/automatic/process_fire or base gun
	. = ..()

/// Get ammo rarity multiplier from whatever casing is chambered
/obj/item/gun/ballistic/automatic/pistol/clan/proc/get_chambered_ammo_rarity()
	if(!chambered)
		return 1.0
	if(istype(chambered, /obj/item/ammo_casing/clan_pistol))
		var/obj/item/ammo_casing/clan_pistol/C = chambered
		return clan_ammo_rarity_multiplier(C.rarity)
	if(istype(chambered, /obj/item/ammo_casing/clan_smg))
		var/obj/item/ammo_casing/clan_smg/C = chambered
		return clan_ammo_rarity_multiplier(C.rarity)
	return 1.0

/obj/item/gun/ballistic/automatic/pistol/clan/militia
	name = "militia clan pistol"
	desc = "A crude pistol cobbled together from scrap. It works, barely."
	rarity = CLAN_RARITY_MILITIA

/obj/item/gun/ballistic/automatic/pistol/clan/veteran
	name = "veteran clan pistol"
	desc = "A refined pistol with improved accuracy and stopping power."
	rarity = CLAN_RARITY_VETERAN

/obj/item/gun/ballistic/automatic/pistol/clan/elite
	name = "elite clan pistol"
	desc = "A masterwork pistol. Each round it fires carries devastating force."
	rarity = CLAN_RARITY_ELITE

// --- Machine Pistol (burst fire) ---
/obj/item/gun/ballistic/automatic/pistol/clan/machine
	name = "clan machine pistol"
	desc = "A rapid-fire pistol that fires in 2-round bursts. Less accurate but high volume of fire."
	icon_state = "aps"
	burst_size = 2
	fire_delay = 2
	spread = 15

/obj/item/gun/ballistic/automatic/pistol/clan/machine/militia
	name = "militia clan machine pistol"
	rarity = CLAN_RARITY_MILITIA

/obj/item/gun/ballistic/automatic/pistol/clan/machine/veteran
	name = "veteran clan machine pistol"
	rarity = CLAN_RARITY_VETERAN

/obj/item/gun/ballistic/automatic/pistol/clan/machine/elite
	name = "elite clan machine pistol"
	rarity = CLAN_RARITY_ELITE

// --- Heavy Pistol (high damage, slow) ---
/obj/item/gun/ballistic/automatic/pistol/clan/heavy
	name = "clan heavy pistol"
	desc = "A powerful sidearm that fires high-caliber rounds. Slow but devastating per shot."
	icon_state = "deagle"
	fire_delay = 4

/// Heavy pistol gets a 1.5x bonus on top of normal ammo rarity
/obj/item/gun/ballistic/automatic/pistol/clan/heavy/get_chambered_ammo_rarity()
	return ..() * 1.5

/obj/item/gun/ballistic/automatic/pistol/clan/heavy/militia
	name = "militia clan heavy pistol"
	rarity = CLAN_RARITY_MILITIA

/obj/item/gun/ballistic/automatic/pistol/clan/heavy/veteran
	name = "veteran clan heavy pistol"
	rarity = CLAN_RARITY_VETERAN

/obj/item/gun/ballistic/automatic/pistol/clan/heavy/elite
	name = "elite clan heavy pistol"
	rarity = CLAN_RARITY_ELITE

// ================================================================
// RIFLES
// ================================================================

// --- Standard Rifle ---
/obj/item/gun/ballistic/automatic/clan_rifle
	name = "clan rifle"
	desc = "A powerful rifle forged by the Resurgence Clan. Slow to fire but hits hard."
	icon_state = "arg"
	w_class = WEIGHT_CLASS_BULKY
	mag_type = /obj/item/ammo_box/magazine/clan_rifle
	fire_sound = 'sound/weapons/gun/rifle/shot.ogg'
	rack_sound = 'sound/weapons/gun/pistol/rack.ogg'
	lock_back_sound = 'sound/weapons/gun/pistol/slide_lock.ogg'
	bolt_drop_sound = 'sound/weapons/gun/pistol/slide_drop.ogg'
	can_suppress = FALSE
	burst_size = 1
	fire_delay = 6
	actions_types = list()
	bolt_type = BOLT_TYPE_LOCKING
	show_bolt_icon = FALSE
	spawnwithmagazine = FALSE
	/// Weapon rarity tier
	var/rarity = CLAN_RARITY_REGULAR

/obj/item/gun/ballistic/automatic/clan_rifle/Initialize()
	. = ..()
	update_rarity_visuals()

/obj/item/gun/ballistic/automatic/clan_rifle/proc/set_rarity(new_rarity)
	rarity = new_rarity
	update_rarity_visuals()
	if(rarity == CLAN_RARITY_REGULAR)
		name = "clan rifle"
	else
		name = "[lowertext(clan_rarity_name(rarity))] clan rifle"

/obj/item/gun/ballistic/automatic/clan_rifle/proc/update_rarity_visuals()
	var/color = clan_rarity_color(rarity)
	remove_filter("clan_rarity")
	add_filter("clan_rarity", 2, list("type" = "outline", "color" = color, "size" = 1))

/// Delete empty magazines on eject
/obj/item/gun/ballistic/automatic/clan_rifle/eject_magazine(mob/user, display_message = TRUE, obj/item/ammo_box/magazine/tac_load = null)
	var/obj/item/ammo_box/magazine/old_mag = magazine
	. = ..()
	if(old_mag && !old_mag.ammo_count())
		QDEL_IN(old_mag, 1)

/obj/item/gun/ballistic/automatic/clan_rifle/examine(mob/user)
	. = ..()
	. += span_notice("Rarity: [clan_rarity_name(rarity)]")

/obj/item/gun/ballistic/automatic/clan_rifle/process_fire(atom/target, mob/living/user, message, params, zone_override, bonus_spread)
	var/gun_mult = clan_rarity_multiplier(rarity)
	var/faith_mult = get_clan_weapon_faith_multiplier(user)
	var/ammo_mult = 1.0
	if(chambered && istype(chambered, /obj/item/ammo_casing/clan_rifle))
		var/obj/item/ammo_casing/clan_rifle/C = chambered
		ammo_mult = clan_ammo_rarity_multiplier(C.rarity)
	if(chambered)
		var/obj/projectile/P = chambered.BB
		if(P)
			P.damage = round(initial(P.damage) * gun_mult * ammo_mult * faith_mult)
	. = ..()

/// Get ammo rarity multiplier from whatever casing is chambered (for rifle subtypes)
/obj/item/gun/ballistic/automatic/clan_rifle/proc/get_chambered_ammo_rarity()
	if(!chambered)
		return 1.0
	if(istype(chambered, /obj/item/ammo_casing/clan_rifle))
		var/obj/item/ammo_casing/clan_rifle/C = chambered
		return clan_ammo_rarity_multiplier(C.rarity)
	return 1.0

/obj/item/gun/ballistic/automatic/clan_rifle/militia
	name = "militia clan rifle"
	desc = "A crude rifle made from salvaged parts. Inaccurate but functional."
	rarity = CLAN_RARITY_MILITIA

/obj/item/gun/ballistic/automatic/clan_rifle/veteran
	name = "veteran clan rifle"
	desc = "A battle-tested rifle with a reinforced barrel and improved sights."
	rarity = CLAN_RARITY_VETERAN

/obj/item/gun/ballistic/automatic/clan_rifle/elite
	name = "elite clan rifle"
	desc = "A masterwork rifle. Its precision and power are unmatched among clan weaponry."
	rarity = CLAN_RARITY_ELITE

// --- Assault Rifle (burst fire) ---
/obj/item/gun/ballistic/automatic/clan_rifle/assault
	name = "clan assault rifle"
	desc = "A versatile rifle that fires in 2-round bursts. Balances firepower with sustained fire."
	icon_state = "wt550"
	burst_size = 2
	fire_delay = 3
	spread = 5

/obj/item/gun/ballistic/automatic/clan_rifle/assault/militia
	name = "militia clan assault rifle"
	rarity = CLAN_RARITY_MILITIA

/obj/item/gun/ballistic/automatic/clan_rifle/assault/veteran
	name = "veteran clan assault rifle"
	rarity = CLAN_RARITY_VETERAN

/obj/item/gun/ballistic/automatic/clan_rifle/assault/elite
	name = "elite clan assault rifle"
	rarity = CLAN_RARITY_ELITE

// --- Sniper's Longrifle (aimed shot gimmick) ---
/obj/item/gun/ballistic/automatic/clan_rifle/longrifle
	name = "clan longrifle"
	desc = "A precision rifle inspired by clan sniper units. Click in-hand to take aim for a devastating charged shot."
	icon_state = "moistnugget"
	fire_delay = 10
	/// Whether the user is currently aiming
	var/aimed = FALSE
	/// Timer for faith drain while aiming
	var/aim_drain_timer

/obj/item/gun/ballistic/automatic/clan_rifle/longrifle/attack_self(mob/user)
	// If bolt needs racking/dropping, let the parent handle it first
	if(bolt_type == BOLT_TYPE_LOCKING && bolt_locked)
		..()
		return
	if(!chambered && magazine?.ammo_count())
		..()
		return

	// Aim mode toggle
	if(aimed)
		cancel_aim(user)
		return

	if(!ishuman(user))
		return ..()
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!core || core.faith < 3)
		to_chat(user, span_warning("You lack sufficient faith to take aim. (Need 3, have [core ? round(core.faith, 0.1) : 0])"))
		return

	to_chat(user, span_notice("You begin to take aim..."))
	if(!do_after(user, 2 SECONDS))
		to_chat(user, span_warning("Your aim is interrupted."))
		return

	aimed = TRUE
	ADD_TRAIT(user, TRAIT_IMMOBILIZED, "clan_longrifle")
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(on_user_moved))
	to_chat(user, span_notice("You are now aiming. Fire for a precise shot, or click the rifle again to cancel."))

	aim_drain_timer = addtimer(CALLBACK(src, PROC_REF(drain_aim_faith), user), 1 SECONDS, TIMER_STOPPABLE | TIMER_LOOP)

/obj/item/gun/ballistic/automatic/clan_rifle/longrifle/proc/drain_aim_faith(mob/user)
	if(!aimed || !ishuman(user))
		cancel_aim(user)
		return
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!core || core.faith < 1)
		to_chat(user, span_warning("You run out of faith to maintain your aim."))
		cancel_aim(user)
		return
	core.adjust_faith(-1)

/obj/item/gun/ballistic/automatic/clan_rifle/longrifle/proc/cancel_aim(mob/user)
	if(!aimed)
		return
	aimed = FALSE
	if(aim_drain_timer)
		deltimer(aim_drain_timer)
		aim_drain_timer = null
	if(user)
		REMOVE_TRAIT(user, TRAIT_IMMOBILIZED, "clan_longrifle")
		UnregisterSignal(user, COMSIG_MOVABLE_MOVED)
		to_chat(user, span_notice("You lower your aim."))

/obj/item/gun/ballistic/automatic/clan_rifle/longrifle/proc/on_user_moved(datum/source)
	SIGNAL_HANDLER
	cancel_aim(source)

/obj/item/gun/ballistic/automatic/clan_rifle/longrifle/process_fire(atom/target, mob/living/user, message, params, zone_override, bonus_spread)
	var/gun_mult = clan_rarity_multiplier(rarity)
	var/faith_mult = get_clan_weapon_faith_multiplier(user)
	var/ammo_mult = 1.0
	if(chambered && istype(chambered, /obj/item/ammo_casing/clan_rifle))
		var/obj/item/ammo_casing/clan_rifle/C = chambered
		ammo_mult = clan_ammo_rarity_multiplier(C.rarity)

	var/aim_mult = 1.0
	if(aimed)
		aim_mult = 2.0
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
			if(core)
				core.adjust_faith(-3)
		to_chat(user, span_danger("You fire a precisely aimed shot!"))
		cancel_aim(user)

	if(chambered)
		var/obj/projectile/P = chambered.BB
		if(P)
			P.damage = round(initial(P.damage) * gun_mult * ammo_mult * faith_mult * aim_mult)
	. = ..()

/obj/item/gun/ballistic/automatic/clan_rifle/longrifle/dropped(mob/user)
	cancel_aim(user)
	. = ..()

/obj/item/gun/ballistic/automatic/clan_rifle/longrifle/examine(mob/user)
	. = ..()
	. += span_notice("Click in-hand to take aim (2s channel). Aimed shots deal 2x damage but cost 3 faith.")
	if(aimed)
		. += span_danger("Currently aiming — next shot will be a precision strike!")

/obj/item/gun/ballistic/automatic/clan_rifle/longrifle/militia
	name = "militia clan longrifle"
	rarity = CLAN_RARITY_MILITIA

/obj/item/gun/ballistic/automatic/clan_rifle/longrifle/veteran
	name = "veteran clan longrifle"
	rarity = CLAN_RARITY_VETERAN

/obj/item/gun/ballistic/automatic/clan_rifle/longrifle/elite
	name = "elite clan longrifle"
	rarity = CLAN_RARITY_ELITE

// ================================================================
// SMGs
// ================================================================

// --- Repeater (overdrive gimmick) ---
/obj/item/gun/ballistic/automatic/pistol/clan/repeater
	name = "clan repeater"
	desc = "A rapid-fire weapon inspired by clan rapid units. Click in-hand to activate overdrive for a burst of sustained fire."
	icon_state = "c20r"
	mag_type = /obj/item/ammo_box/magazine/clan_smg
	fire_sound = 'sound/weapons/gun/smg/shot.ogg'
	burst_size = 3
	fire_delay = 4
	w_class = WEIGHT_CLASS_NORMAL
	/// Whether overdrive is currently active
	var/overdrive = FALSE
	/// When overdrive expires (world.time)
	var/overdrive_end = 0
	COOLDOWN_DECLARE(overdrive_cd)

/obj/item/gun/ballistic/automatic/pistol/clan/repeater/attack_self(mob/user)
	// If bolt needs racking/dropping, let the parent handle it first
	if(bolt_type == BOLT_TYPE_LOCKING && bolt_locked)
		..()
		return
	if(!chambered && magazine?.ammo_count())
		..()
		return

	// Overdrive activation
	if(overdrive)
		to_chat(user, span_warning("Overdrive is already active!"))
		return

	if(!COOLDOWN_FINISHED(src, overdrive_cd))
		to_chat(user, span_warning("Overdrive is recharging. ([round((overdrive_cd - world.time) / 10)]s remaining)"))
		return

	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!core || core.faith < 5)
		to_chat(user, span_warning("You lack sufficient faith to activate overdrive. (Need 5, have [core ? round(core.faith, 0.1) : 0])"))
		return

	core.adjust_faith(-5)
	overdrive = TRUE
	overdrive_end = world.time + 10 SECONDS
	burst_size = 5
	fire_delay = 2
	add_atom_colour("#ff000040", TEMPORARY_COLOUR_PRIORITY)
	to_chat(user, span_danger("You overclock the repeater! It whirs with energy!"))
	playsound(src, 'sound/machines/click.ogg', 50, TRUE)

/obj/item/gun/ballistic/automatic/pistol/clan/repeater/process_fire(atom/target, mob/living/user, message, params, zone_override, bonus_spread)
	if(overdrive && world.time > overdrive_end)
		end_overdrive(user)
	. = ..()

/obj/item/gun/ballistic/automatic/pistol/clan/repeater/proc/end_overdrive(mob/user)
	overdrive = FALSE
	burst_size = 3
	fire_delay = 4
	remove_atom_colour(TEMPORARY_COLOUR_PRIORITY)
	COOLDOWN_START(src, overdrive_cd, 30 SECONDS)
	if(user)
		to_chat(user, span_notice("The repeater's overdrive cools down."))

/obj/item/gun/ballistic/automatic/pistol/clan/repeater/examine(mob/user)
	. = ..()
	. += span_notice("Click in-hand to activate Overdrive (5 faith, 10s duration, 30s cooldown).")
	if(overdrive)
		. += span_danger("OVERDRIVE ACTIVE — enhanced burst fire!")

/obj/item/gun/ballistic/automatic/pistol/clan/repeater/militia
	name = "militia clan repeater"
	rarity = CLAN_RARITY_MILITIA

/obj/item/gun/ballistic/automatic/pistol/clan/repeater/veteran
	name = "veteran clan repeater"
	rarity = CLAN_RARITY_VETERAN

/obj/item/gun/ballistic/automatic/pistol/clan/repeater/elite
	name = "elite clan repeater"
	rarity = CLAN_RARITY_ELITE

// --- Compact SMG (fast, concealable) ---
/obj/item/gun/ballistic/automatic/pistol/clan/compact_smg
	name = "clan compact SMG"
	desc = "A small, fast-firing submachine gun. Easy to carry but burns through ammo quickly."
	icon_state = "miniuzi"
	mag_type = /obj/item/ammo_box/magazine/clan_smg
	fire_sound = 'sound/weapons/gun/smg/shot.ogg'
	w_class = WEIGHT_CLASS_SMALL
	burst_size = 2
	fire_delay = 2
	spread = 20

/obj/item/gun/ballistic/automatic/pistol/clan/compact_smg/militia
	name = "militia clan compact SMG"
	rarity = CLAN_RARITY_MILITIA

/obj/item/gun/ballistic/automatic/pistol/clan/compact_smg/veteran
	name = "veteran clan compact SMG"
	rarity = CLAN_RARITY_VETERAN

/obj/item/gun/ballistic/automatic/pistol/clan/compact_smg/elite
	name = "elite clan compact SMG"
	rarity = CLAN_RARITY_ELITE

// ================================================================
// SHOTGUNS
// ================================================================

// --- Pump Shotgun (classic pump action) ---
/obj/item/gun/ballistic/shotgun/clan_pump
	name = "clan pump shotgun"
	desc = "A sturdy pump-action shotgun forged by the Resurgence Clan. Slow but hits like a freight train."
	icon_state = "shotgun"
	w_class = WEIGHT_CLASS_BULKY
	mag_type = /obj/item/ammo_box/magazine/internal/clan_shotgun
	fire_sound = 'sound/weapons/gun/shotgun/shot.ogg'
	can_suppress = FALSE
	semi_auto = FALSE
	bolt_type = BOLT_TYPE_STANDARD
	bolt_wording = "pump"
	show_bolt_icon = FALSE
	cartridge_wording = "shell"
	casing_ejector = FALSE
	internal_magazine = TRUE
	pb_knockback = 2
	fire_delay = 8
	spawnwithmagazine = TRUE
	/// Weapon rarity tier
	var/rarity = CLAN_RARITY_REGULAR

/obj/item/gun/ballistic/shotgun/clan_pump/Initialize()
	. = ..()
	var/color = clan_rarity_color(rarity)
	add_filter("clan_rarity", 2, list("type" = "outline", "color" = color, "size" = 1))

/obj/item/gun/ballistic/shotgun/clan_pump/proc/set_rarity(new_rarity)
	rarity = new_rarity
	update_rarity_visuals()
	if(rarity == CLAN_RARITY_REGULAR)
		name = "clan pump shotgun"
	else
		name = "[lowertext(clan_rarity_name(rarity))] clan pump shotgun"

/obj/item/gun/ballistic/shotgun/clan_pump/proc/update_rarity_visuals()
	var/color = clan_rarity_color(rarity)
	remove_filter("clan_rarity")
	add_filter("clan_rarity", 2, list("type" = "outline", "color" = color, "size" = 1))

/obj/item/gun/ballistic/shotgun/clan_pump/examine(mob/user)
	. = ..()
	. += span_notice("Rarity: [clan_rarity_name(rarity)]")

/obj/item/gun/ballistic/shotgun/clan_pump/process_fire(atom/target, mob/living/user, message, params, zone_override, bonus_spread)
	var/gun_mult = clan_rarity_multiplier(rarity)
	var/faith_mult = get_clan_weapon_faith_multiplier(user)
	var/ammo_mult = 1.0
	if(chambered && istype(chambered, /obj/item/ammo_casing/clan_shotgun))
		var/obj/item/ammo_casing/clan_shotgun/C = chambered
		ammo_mult = clan_ammo_rarity_multiplier(C.rarity)
	if(chambered)
		var/obj/projectile/P = chambered.BB
		if(P)
			P.damage = round(initial(P.damage) * gun_mult * ammo_mult * faith_mult)
	. = ..()

/obj/item/gun/ballistic/shotgun/clan_pump/militia
	name = "militia clan pump shotgun"
	rarity = CLAN_RARITY_MILITIA

/obj/item/gun/ballistic/shotgun/clan_pump/veteran
	name = "veteran clan pump shotgun"
	rarity = CLAN_RARITY_VETERAN

/obj/item/gun/ballistic/shotgun/clan_pump/elite
	name = "elite clan pump shotgun"
	rarity = CLAN_RARITY_ELITE

// --- Combat Shotgun (semi-auto, larger magazine) ---
/obj/item/gun/ballistic/shotgun/clan_pump/combat
	name = "clan combat shotgun"
	desc = "A semi-automatic shotgun with an extended tube. Faster follow-up shots at the cost of weight."
	icon_state = "cshotgun"
	w_class = WEIGHT_CLASS_HUGE
	mag_type = /obj/item/ammo_box/magazine/internal/clan_shotgun/combat
	semi_auto = TRUE
	fire_delay = 5
	pb_knockback = 1

/obj/item/gun/ballistic/shotgun/clan_pump/combat/set_rarity(new_rarity)
	rarity = new_rarity
	update_rarity_visuals()
	if(rarity == CLAN_RARITY_REGULAR)
		name = "clan combat shotgun"
	else
		name = "[lowertext(clan_rarity_name(rarity))] clan combat shotgun"

/obj/item/gun/ballistic/shotgun/clan_pump/combat/militia
	name = "militia clan combat shotgun"
	rarity = CLAN_RARITY_MILITIA

/obj/item/gun/ballistic/shotgun/clan_pump/combat/veteran
	name = "veteran clan combat shotgun"
	rarity = CLAN_RARITY_VETERAN

/obj/item/gun/ballistic/shotgun/clan_pump/combat/elite
	name = "elite clan combat shotgun"
	rarity = CLAN_RARITY_ELITE

// ================================================================
// FAITH GUNS (consume faith, no ammo)
// ================================================================

// --- Faith Projectiles ---
/obj/projectile/clan_faith
	name = "faith bolt"
	icon_state = "purplelaser"
	damage = 40
	damage_type = BLACK_DAMAGE

/obj/projectile/clan_faith/void_bolt
	name = "void bolt"
	icon_state = "purplelaser"
	damage = 40
	damage_type = BLACK_DAMAGE

/obj/projectile/clan_faith/pale_bolt
	name = "pale lance bolt"
	icon_state = "laser"
	damage = 30
	damage_type = PALE_DAMAGE
	speed = 0.3

// --- Faith Gun Base ---
/obj/item/gun/clan_faith
	name = "faith weapon"
	desc = "A weapon that channels faith energy into devastating attacks."
	icon = 'icons/obj/guns/energy.dmi'
	icon_state = "laser"
	w_class = WEIGHT_CLASS_NORMAL
	fire_sound = 'sound/weapons/laser.ogg'
	fire_sound_volume = 50
	fire_delay = 8
	/// Faith cost per shot
	var/faith_cost = 3
	/// The projectile type this gun fires
	var/projectile_type = /obj/projectile/clan_faith/void_bolt

/obj/item/gun/clan_faith/can_shoot()
	return TRUE

/obj/item/gun/clan_faith/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	if(user)
		SEND_SIGNAL(user, COMSIG_MOB_FIRED_GUN, src, target, params, zone_override)
	SEND_SIGNAL(src, COMSIG_GUN_FIRED, user, target, params, zone_override)
	add_fingerprint(user)

	if(semicd)
		return FALSE

	if(!ishuman(user))
		to_chat(user, span_warning("You cannot channel faith through this weapon."))
		return FALSE
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!core)
		to_chat(user, span_warning("You lack the faith core needed to power this weapon."))
		return FALSE
	if(core.faith < faith_cost)
		to_chat(user, span_warning("You lack sufficient faith to fire this weapon. (Need [faith_cost], have [round(core.faith, 0.1)])"))
		playsound(src, dry_fire_sound, 30, TRUE)
		return FALSE

	core.adjust_faith(-faith_cost)

	var/turf/curloc = get_turf(src)
	var/obj/projectile/P = new projectile_type(curloc)
	P.preparePixelProjectile(target, user)
	P.firer = user
	P.fire()
	playsound(src, fire_sound, fire_sound_volume, TRUE)

	if(message)
		user.visible_message(span_danger("[user] fires [src]!"), span_danger("You fire [src]! ([round(core.faith, 0.1)] faith remaining)"))

	user.newtonian_move(get_dir(target, user))

	semicd = TRUE
	addtimer(CALLBACK(src, PROC_REF(reset_semicd)), fire_delay)
	return TRUE

/obj/item/gun/clan_faith/examine(mob/user)
	. = ..()
	. += span_notice("This weapon consumes [faith_cost] faith per shot.")
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
		if(core)
			. += span_notice("Current faith: [round(core.faith, 0.1)] ([round(core.faith / faith_cost)] shots available)")

// --- Void Caster (BLACK damage, T4) ---
/obj/item/gun/clan_faith/void_caster
	name = "void caster"
	desc = "A strange weapon that channels faith energy into bolts of pure void. Effective against clan machines, but drains the wielder's faith."
	icon_state = "laser"
	faith_cost = 3
	projectile_type = /obj/projectile/clan_faith/void_bolt
	fire_sound = 'sound/weapons/laser3.ogg'

// --- Pale Lance (PALE damage, T5) ---
/obj/item/gun/clan_faith/pale_lance
	name = "pale lance"
	desc = "An eerie weapon that fires concentrated pale energy. Devastatingly effective against clan machines, but exacts a heavy toll on the wielder's faith."
	icon_state = "laser"
	faith_cost = 5
	projectile_type = /obj/projectile/clan_faith/pale_bolt
	fire_sound = 'sound/weapons/laser3.ogg'
	fire_sound_volume = 70

// --- Warper's Voidstaff (teleport gimmick, T5) ---

/obj/effect/warp_marker
	name = "warp destination"
	desc = "A shimmering purple mark indicating a teleport destination."
	icon = 'icons/effects/effects.dmi'
	icon_state = "yourballstip"
	color = "#cc44ff"
	alpha = 180
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/warp_marker/Initialize()
	. = ..()
	animate(src, alpha = 100, time = 1 SECONDS, loop = -1)
	animate(alpha = 180, time = 1 SECONDS)

/obj/projectile/clan_faith/warp_bolt
	name = "warp bolt"
	icon_state = "purplelaser"
	damage = 25
	damage_type = BLACK_DAMAGE
	/// Reference to the voidstaff that fired this
	var/obj/item/gun/clan_faith/voidstaff/source_staff

/obj/projectile/clan_faith/warp_bolt/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(!isliving(target) || !source_staff || !source_staff.marked_location)
		return

	var/mob/living/firer_mob = firer
	if(!ishuman(firer_mob))
		return
	var/mob/living/carbon/human/H = firer_mob
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!core || core.faith < 5)
		to_chat(firer_mob, span_warning("Not enough faith to complete the warp. (Need 5 additional)"))
		return

	core.adjust_faith(-5)
	var/mob/living/L = target
	var/turf/destination = source_staff.marked_location

	do_teleport(L, destination, forceMove = TRUE, no_effects = TRUE, forced = TRUE)
	L.Knockdown(10)

	new /obj/effect/temp_visual/dir_setting/ninja/phase(get_turf(L))
	to_chat(firer_mob, span_danger("You warp [L] to the marked location!"))
	to_chat(L, span_userdanger("You are violently warped through space!"))

	source_staff.clear_mark()

/obj/item/gun/clan_faith/voidstaff
	name = "warper's voidstaff"
	desc = "An eerie staff inspired by clan warper units. Fires void bolts and can mark a location to teleport targets to."
	icon = 'icons/obj/wizard.dmi'
	icon_state = "staff"
	faith_cost = 3
	projectile_type = /obj/projectile/clan_faith/warp_bolt
	fire_delay = 10
	fire_sound = 'sound/weapons/laser3.ogg'
	/// Marked teleport destination
	var/turf/marked_location
	/// Visual marker effect on the marked tile
	var/obj/effect/warp_marker/marker_effect

/obj/item/gun/clan_faith/voidstaff/proc/fire_projectile(atom/target, mob/living/user)
	var/turf/curloc = get_turf(src)
	var/obj/projectile/clan_faith/warp_bolt/P = new projectile_type(curloc)
	P.preparePixelProjectile(target, user)
	P.firer = user
	P.source_staff = src
	P.fire()
	return P

/obj/item/gun/clan_faith/voidstaff/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	if(user)
		SEND_SIGNAL(user, COMSIG_MOB_FIRED_GUN, src, target, params, zone_override)
	SEND_SIGNAL(src, COMSIG_GUN_FIRED, user, target, params, zone_override)
	add_fingerprint(user)

	if(semicd)
		return FALSE

	if(!ishuman(user))
		to_chat(user, span_warning("You cannot channel faith through this weapon."))
		return FALSE
	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!core)
		to_chat(user, span_warning("You lack the faith core needed to power this weapon."))
		return FALSE
	if(core.faith < faith_cost)
		to_chat(user, span_warning("You lack sufficient faith to fire this weapon. (Need [faith_cost], have [round(core.faith, 0.1)])"))
		playsound(src, dry_fire_sound, 30, TRUE)
		return FALSE

	core.adjust_faith(-faith_cost)

	fire_projectile(target, user)
	playsound(src, fire_sound, fire_sound_volume, TRUE)

	if(message)
		user.visible_message(span_danger("[user] fires [src]!"), span_danger("You fire [src]! ([round(core.faith, 0.1)] faith remaining)"))

	user.newtonian_move(get_dir(target, user))

	semicd = TRUE
	addtimer(CALLBACK(src, PROC_REF(reset_semicd)), fire_delay)
	return TRUE

/obj/item/gun/clan_faith/voidstaff/MiddleClickAction(atom/target, mob/living/user)
	. = ..()
	if(!ishuman(user))
		return
	var/turf/T = get_turf(target)
	if(!T)
		return
	if(!(T in view(10, user)))
		to_chat(user, span_warning("That location is too far away or not visible."))
		return

	var/mob/living/carbon/human/H = user
	var/obj/item/organ/resurgence_core/core = H.getorganslot(ORGAN_SLOT_HEART)
	if(!core || core.faith < 2)
		to_chat(user, span_warning("You lack sufficient faith to mark a location. (Need 2, have [core ? round(core.faith, 0.1) : 0])"))
		return

	core.adjust_faith(-2)
	clear_mark()

	marked_location = T
	marker_effect = new /obj/effect/warp_marker(T)
	QDEL_IN(marker_effect, 60 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(clear_mark)), 60 SECONDS)

	to_chat(user, span_notice("You mark a warp destination."))
	playsound(src, 'sound/magic/blink.ogg', 30, TRUE)

/obj/item/gun/clan_faith/voidstaff/proc/clear_mark()
	marked_location = null
	if(marker_effect && !QDELETED(marker_effect))
		qdel(marker_effect)
	marker_effect = null

/obj/item/gun/clan_faith/voidstaff/examine(mob/user)
	. = ..()
	. += span_notice("Middle-click a tile to mark a warp destination (2 faith). Hitting a mob warps them there (5 extra faith).")
	if(marked_location)
		. += span_notice("A warp destination is currently marked.")

/obj/item/gun/clan_faith/voidstaff/Destroy()
	clear_mark()
	return ..()

// ================================================================
// CASING COLLECTOR — picks up spent casings, recycles into metal
// ================================================================

/// How many casings convert into 1 metal sheet
#define CASINGS_PER_METAL 10

/obj/item/clan_casing_collector
	name = "casing collector"
	desc = "A magnetic sweeper that collects spent ammo casings from the ground. Use in-hand to sweep nearby casings. Use on a crafting table to recycle them into metal."
	icon = 'icons/obj/mining.dmi'
	icon_state = "satchel"
	w_class = WEIGHT_CLASS_NORMAL
	/// Number of casings currently stored
	var/stored_casings = 0
	/// Maximum casings it can hold
	var/max_casings = 200

/obj/item/clan_casing_collector/examine(mob/user)
	. = ..()
	. += span_notice("Contains [stored_casings]/[max_casings] spent casings.")
	if(stored_casings >= CASINGS_PER_METAL)
		. += span_notice("Use on a crafting table to recycle into metal. ([round(stored_casings / CASINGS_PER_METAL)] sheets available)")

/// Use in-hand: sweep all casings in a 3-tile radius
/obj/item/clan_casing_collector/attack_self(mob/user)
	var/collected = 0
	for(var/obj/item/ammo_casing/C in range(3, user))
		if(stored_casings >= max_casings)
			to_chat(user, span_warning("The collector is full!"))
			break
		if(C.BB)
			continue // Skip live rounds
		stored_casings++
		collected++
		qdel(C)

	if(collected)
		to_chat(user, span_notice("You sweep up [collected] spent casing\s. ([stored_casings]/[max_casings])"))
		playsound(src, 'sound/items/pickaxe.ogg', 30, TRUE)
	else
		to_chat(user, span_notice("No spent casings nearby."))

/// Click on a crafting table to recycle casings into metal
/obj/item/clan_casing_collector/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!proximity_flag)
		return
	if(!istype(target, /obj/structure/resurgence_crafting_table))
		return
	if(stored_casings < CASINGS_PER_METAL)
		to_chat(user, span_warning("Not enough casings to recycle. (Need [CASINGS_PER_METAL], have [stored_casings])"))
		return

	var/sheets = round(stored_casings / CASINGS_PER_METAL)
	var/used = sheets * CASINGS_PER_METAL
	stored_casings -= used
	new /obj/item/stack/sheet/metal(get_turf(target), sheets)
	to_chat(user, span_notice("You recycle [used] casings into [sheets] metal sheet\s. ([stored_casings] casings remaining)"))
	playsound(target, 'sound/items/welder.ogg', 40, TRUE)

#undef CASINGS_PER_METAL
