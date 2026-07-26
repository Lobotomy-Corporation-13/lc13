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
	var/max_damage_bonus = 1
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
