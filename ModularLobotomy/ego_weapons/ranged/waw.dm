/obj/item/ego_weapon/ranged/correctional
	name = "correctional"
	desc = "In here, you're with us. Forever."
	icon_state = "correctional"
	inhand_icon_state = "correctional"
	force = 33
	damtype = BLACK_DAMAGE
	attack_speed = 1.3
	projectile_path = /obj/projectile/ego_bullet/ego_correctional
	weapon_weight = WEAPON_HEAVY
	pellets = 8
	variance = 20
	fire_delay = 7
	shotsleft = 12
	reloadtime = 0.4 SECONDS
	roundsreload = TRUE
	fire_sound = 'sound/weapons/gun/shotgun/shot_auto.ogg'

	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)

/obj/item/ego_weapon/ranged/hornet
	name = "hornet"
	desc = "The kingdom needed to stay prosperous, and more bees were required for that task. \
	The projectiles relive the legacy of the kingdom as they travel toward the target."
	special = "Attack an enemy with your bayonet to reload."
	icon_state = "hornet"
	inhand_icon_state = "hornet"
	force = 41
	reach = 2
	stuntime = 5	//but a short stun
	projectile_path = /obj/projectile/ego_bullet/ego_hornet
	weapon_weight = WEAPON_HEAVY
	fire_sound = 'sound/weapons/gun/rifle/leveraction.ogg'
	fire_delay = 2
	shotsleft = 10
	reloadtime = 1.4 SECONDS
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80
							)

/obj/item/ego_weapon/ranged/hornet/attack(mob/living/target, mob/living/carbon/human/user)
	..()
	if(shotsleft < initial(shotsleft))
		shotsleft = initial(shotsleft)


/obj/item/ego_weapon/ranged/hatred
	name = "in the name of love and hate"
	desc = "A magic wand surging with the lovely energy of a magical girl. \
	The holy light can cleanse the body and mind of every villain, and they shall be born anew."
	icon_state = "hatred"
	inhand_icon_state = "hatred"
	special = "This weapon heals humans that it hits."
	force = 28
	damtype = BLACK_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_hatred
	weapon_weight = WEAPON_HEAVY
	fire_delay = 10
	shotsleft = 10
	reloadtime = 2 SECONDS

	fire_sound = 'sound/abnormalities/hatredqueen/attack.ogg'

	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)

/obj/item/ego_weapon/ranged/hatred/GunAttackInfo(mob/user)
	return span_notice("Its bullets deal [last_projectile_damage] randomly chosen damage.")

/obj/item/ego_weapon/ranged/hatred/attackby(obj/item/I, mob/living/user, params)
	..()
	if(!istype(I, /obj/item/nihil/heart))
		return
	new /obj/item/ego_weapon/ranged/hatred_nihil(get_turf(src))
	to_chat(user,span_warning("The [I] seems to drain all of the light away as it is absorbed into [src]!"))
	playsound(user, 'sound/abnormalities/nihil/filter.ogg', 15, FALSE, -3)
	qdel(I)
	qdel(src)

// Magic Bullet armour increases attack speed from 30 to 15
// Big Iron armour on the other hand increases damage by a factor of 2.5x80, which will give it 40 more damage than the magic bullet armour
/obj/item/ego_weapon/ranged/magicbullet
	name = "magic bullet"
	desc = "Though the original's power couldn't be fully extracted, the magic this holds is still potent. \
	The weapon's bullets travel across the corridor, along the horizon."
	icon_state = "magic_bullet"
	inhand_icon_state = "magic_bullet"
	special = "This weapon fires extremely slowly. \
		This weapon pierces all targets. \
		This weapon gets a firespeed bonus when wearing the matching armor."
	force = 28
	damtype = BLACK_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_magicbullet
	weapon_weight = WEAPON_HEAVY
	fire_delay = 30	//Put on the armor, jackass.
	shotsleft = 7
	reloadtime = 2.1 SECONDS
	fire_sound = 'sound/abnormalities/freischutz/shoot.ogg'

	attribute_requirements = list(
							TEMPERANCE_ATTRIBUTE = 80
							)
	var/cached_multiplier

/obj/item/ego_weapon/ranged/magicbullet/before_firing(atom/target, mob/user)
	if(cached_multiplier)
		projectile_damage_multiplier = cached_multiplier
	fire_delay = initial(fire_delay)
	var/mob/living/carbon/human/myman = user
	var/obj/item/clothing/suit/armor/ego_gear/he/magicbullet/Y = myman.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	var/obj/item/clothing/suit/armor/ego_gear/realization/bigiron/Z = myman.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(istype(Y))
		fire_delay = 8
	if(istype(Z))
		cached_multiplier = projectile_damage_multiplier
		projectile_damage_multiplier *= 2.5
		fire_delay = 8
	..()


//Funeral guns have two different names;
//Solemn Lament is the white gun, Solemn Vow is the black gun.
//Likewise, they emit butterflies of those respective colors.
/obj/item/ego_weapon/ranged/pistol/solemnlament
	name = "solemn lament"
	desc = "A pistol which carries with it a lamentation for those that live. \
	Can feathers gain their own wings?"
	icon_state = "solemnlament"
	inhand_icon_state = "solemnlament"
	special = "Firing both solemn lament and solemn vow at the same time will increase damage by 1.5x"
	force = 17
	damtype = WHITE_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_solemnlament
	fire_delay = 5
	shotsleft = 18
	reloadtime = 0.7 SECONDS
	fire_sound = 'sound/abnormalities/funeral/spiritgunwhite.ogg'
	fire_sound_volume = 30
	attribute_requirements = list(PRUDENCE_ATTRIBUTE = 80)
	var/cached_multiplier

/obj/item/ego_weapon/ranged/pistol/solemnlament/before_firing(atom/target, mob/user)
	if(cached_multiplier)
		projectile_damage_multiplier = cached_multiplier
	fire_delay = initial(fire_delay)
	var/mob/living/carbon/human/myman = user
	var/obj/item/clothing/suit/armor/ego_gear/realization/eulogy/Z = myman.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(istype(Z))
		cached_multiplier = projectile_damage_multiplier
		projectile_damage_multiplier *= 1.25
	return ..()

/obj/item/ego_weapon/ranged/pistol/solemnlament/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, temporary_damage_multiplier = 1)
	for(var/obj/item/ego_weapon/ranged/pistol/solemnvow/Vow in user.held_items)
		projectile_damage_multiplier = 1.5
		break
	. = ..()
	projectile_damage_multiplier = 1


/obj/item/ego_weapon/ranged/pistol/solemnvow
	name = "solemn vow"
	desc = "A pistol which carries with it grief for those who have perished. \
	Even with wings, no feather can leave this place."
	icon_state = "solemnvow"
	inhand_icon_state = "solemnvow"
	special = "Firing both solemn lament and solemn vow at the same time will increase damage by 1.5x"
	force = 17
	damtype = BLACK_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_solemnvow
	fire_delay = 5
	shotsleft = 18
	reloadtime = 0.7 SECONDS
	fire_sound = 'sound/abnormalities/funeral/spiritgunblack.ogg'
	fire_sound_volume = 30
	var/cached_multiplier
	attribute_requirements = list(JUSTICE_ATTRIBUTE = 80)

/obj/item/ego_weapon/ranged/pistol/solemnvow/before_firing(atom/target, mob/user)
	if(cached_multiplier)
		projectile_damage_multiplier = cached_multiplier
	fire_delay = initial(fire_delay)
	var/mob/living/carbon/human/myman = user
	var/obj/item/clothing/suit/armor/ego_gear/realization/eulogy/Z = myman.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(istype(Z))
		cached_multiplier = projectile_damage_multiplier
		projectile_damage_multiplier *= 1.25
	return ..()

/obj/item/ego_weapon/ranged/pistol/solemnvow/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, temporary_damage_multiplier = 1)
	for(var/obj/item/ego_weapon/ranged/pistol/solemnlament/Lament in user.held_items)
		projectile_damage_multiplier = 1.5
		break
	. = ..()
	projectile_damage_multiplier = 1


/obj/item/ego_weapon/ranged/loyalty
	name = "loyalty"
	desc = "Courtesy of the 16th Ego Rifleman's Brigade."
	special = "This weapon has IFF capabilities."
	icon_state = "loyalty"
	inhand_icon_state = "loyalty"
	force = 28
	projectile_path = /obj/projectile/ego_bullet/ego_loyalty/iff
	weapon_weight = WEAPON_HEAVY
	spread = 26
	shotsleft = 95
	reloadtime = 3.2 SECONDS
	fire_sound = 'sound/weapons/gun/smg/vp70.ogg'
	autofire = 0.08 SECONDS
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80
	)
	alternate_fire_name = "Underslung Grenade Launcher"
	alternate_info = "This rifle has an underslung grenade launcher. Grenades fired from this rifle also have IFF, and knock back enemies while dealing AoE RED damage."
	alternate_shotsleft = 1
	alternate_pellets = 1
	alternate_reload_type = RANGEDEGO_ALTERNATEFIRE_RELOADTYPE_SHARED_RELOAD
	alternate_projectile_path = /obj/projectile/ego_bullet/loyalty_ugl
	alternate_fire_sound = 'sound/weapons/gun/general/grenade_launch.ogg'
	alternate_fire_sound_volume = 70
	alternate_toggle_sound = 'sound/machines/click.ogg'
	alternate_toggle_sound_volume = 65
	alternate_toggle_enabled_message = span_notice("You ready your underslung grenade launcher.")
	alternate_toggle_disabled_message = span_notice("You will no longer use your underslung grenade launcher.")
	// Need to store this to modify the autofire after firing UGL
	var/datum/component/automatic_fire/autofire_component
	var/firing_ugl_extra_shot_delay_coeff = 8

/obj/item/ego_weapon/ranged/loyalty/Initialize(mapload)
	. = ..()
	autofire_component = GetComponent(/datum/component/automatic_fire)

/obj/item/ego_weapon/ranged/loyalty/GunAttackInfo()
	. = ..()
	. += span_notice("\nGrenades fired from the underslung grenade launcher are 'impact' grenades that will attempt to detonate wherever you click. They explode for 180 RED damage and their damage falls off based on distance from the epicenter. \
	After firing the UGL, you'll automatically swap to the primary fire mode.")

/obj/item/ego_weapon/ranged/loyalty/process_chamber()
	. = ..()
	if(alternate_selected)
		DisableAltfire(null, TRUE)

/obj/item/ego_weapon/ranged/loyalty/EnableAltfire(mob/user, silent = TRUE)
	. = ..()
	spread = 0
	autofire_component.autofire_shot_delay = (autofire * firing_ugl_extra_shot_delay_coeff)

/obj/item/ego_weapon/ranged/loyalty/DisableAltfire(mob/user, silent = TRUE)
	. = ..()
	spread = initial(spread)
	autofire_component.autofire_shot_delay = autofire

//Just a funny gold soda pistol. It was originally meant to just be a golden meme weapon, now it is the only pale gun, lol
/obj/item/ego_weapon/ranged/pistol/executive
	name = "executive"
	desc = "A pistol painted in black with a gold finish. Whenever this EGO is used, a faint scent of fillet mignon wafts through the air."
	icon_state = "executive"
	inhand_icon_state = "executive"
	special = "This gun scales with justice."
	force = 12
	damtype = PALE_DAMAGE
	burst_size = 1
	fire_delay = 5
	shotsleft = 10
	reloadtime = 0.7 SECONDS
	fire_sound = 'sound/weapons/gun/pistol/shot.ogg'
	vary_fire_sound = FALSE
	fire_sound_volume = 70
	projectile_path = /obj/projectile/ego_bullet/ego_executive
	attribute_requirements = list(
							JUSTICE_ATTRIBUTE = 80
	)

/obj/item/ego_weapon/ranged/pistol/executive/fire_projectile(atom/target, mob/living/user, params, distro, quiet, zone_override, spread, atom/fired_from, temporary_damage_multiplier)
	if(!ishuman(user))
		return ..()

	var/userjust = get_attribute_level(user, JUSTICE_ATTRIBUTE)
	var/justicemod = 1 + userjust/100
	temporary_damage_multiplier = justicemod
	return ..()

// This gun is buffed while using the Crimson Lust realization, and can be dual-wielded when under the buff its ability gives you.
/obj/item/ego_weapon/ranged/pistol/crimson
	name = "crimson scar"
	desc = "With steel in one hand and gunpowder in the other, there's nothing to fear in this place."
	icon_state = "crimsonscar"
	inhand_icon_state = "crimsonscar"
	force = 17
	projectile_path = /obj/projectile/ego_bullet/ego_crimson
	weapon_weight = WEAPON_MEDIUM
	pellets = 3
	variance = 14
	fire_delay = 7
	shotsleft = 9
	reloadtime = 1 SECONDS
	fire_sound = 'sound/abnormalities/redhood/fire.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
	)
	// All these vars are for the Crimson Lust realization.
	/// Ammo used by this gun when wearing Crimson Lust
	var/realization_default_ammo_type = /obj/projectile/ego_bullet/ego_crimson/lust
	/// Ammo used by this gun when wearing Crimson Lust after loading Hollowpoint
	var/realization_hollowpoint_ammo_type = /obj/projectile/ego_bullet/ego_crimson/lust_hollowpoint
	/// How much slower you fire Hollowpoint shells
	var/realization_hollowpoint_firedelay_malus = 5
	/// Should we be using Hollowpoint rounds?
	var/realization_hollowpoint_active = FALSE
	/// How long it takes to load a Hollowpoint shell
	var/realization_hollowpoint_toggle_delay = 0.6 SECONDS
	// Spam prevention stuff
	var/realization_hollowpoint_spam_prevention_cd
	/// This is TRUE while we're using this gun with No Hesitation active, it gets set on any CrimScars we're holding as it activates, and will be set if we place one in our hands while it's active.
	var/realization_empowered_mode = FALSE
	// These four vars just change our stats when No Hesitation is active.
	var/realization_empowered_pellet_increase = 1
	var/realization_empowered_variance_increase = 5
	var/realization_empowered_spread_increase = 15
	var/realization_empowered_firedelay_decrease = 1

/obj/item/ego_weapon/ranged/pistol/crimson/examine(mob/user)
	. = ..()
	if(ishuman(user))
		var/obj/item/clothing/suit/armor/ego_gear/realization/crimson/our_suit = user.get_item_by_slot(ITEM_SLOT_OCLOTHING)
		if(istype(our_suit))
			. += span_nicegreen("Due to wearing [our_suit] E.G.O. armour, you've unlocked a portion of this weapon's true potential.")
			. += span_info("Ammo is now infinite, and your standard projectiles deal more damage and pierce up to 2 targets.")
			. += span_info("You can reload this weapon to load a single <b>Hollowpoint Shell</b>, which is highly accurate and deals more damage, and will <b>consume a target's Hemorrhage</b> (inflicted by Crimson Claw). You may load this shell while moving.")
			. += span_info("While under the effect of <b>Strike without Hesitation</b>, your firerate increases, you can <b>dual wield</b> this weapon, and you fire [initial(pellets) + realization_empowered_pellet_increase] projectiles per shot.")

/obj/item/ego_weapon/ranged/pistol/crimson/equipped(mob/living/user, slot)
	. = ..()
	var/realization_active = FALSE
	if(ishuman(user) && (slot == ITEM_SLOT_HANDS))
		var/obj/item/clothing/suit/armor/ego_gear/realization/crimson/our_suit = user.get_item_by_slot(ITEM_SLOT_OCLOTHING)
		if(istype(our_suit)) // Wearing Crimson Lust?
			realization_active = TRUE
			var/datum/status_effect/crimlust_no_hesitation/very_angry_very_red_mercenary = user.has_status_effect(/datum/status_effect/crimlust_no_hesitation)
			if(very_angry_very_red_mercenary) // Under the effect of Strike Without Hesitation?
				weapon_weight = WEAPON_LIGHT // You can now dual-wield.
				realization_empowered_mode = TRUE // Weapon is empowered.
				very_angry_very_red_mercenary.modified_guns |= src // So this gets reverted once Strike Without Hesitation falls off
				return

		weapon_weight = initial(weapon_weight)
		realization_empowered_mode = FALSE

		SetAmmoStat(realization_active)

// Replace our reload with loading Hollowpoint if we're wearing Crimson Lust
/obj/item/ego_weapon/ranged/pistol/crimson/attack_self(mob/user)
	if(ishuman(user))
		var/obj/item/clothing/suit/armor/ego_gear/realization/crimson/our_suit = user.get_item_by_slot(ITEM_SLOT_OCLOTHING)
		if(istype(our_suit))
			// Spam prevention
			if(realization_hollowpoint_spam_prevention_cd > world.time)
				return
			realization_hollowpoint_spam_prevention_cd = world.time + realization_hollowpoint_toggle_delay * 2
			INVOKE_ASYNC(src, PROC_REF(ToggleHollowpoint), user)
			return
	. = ..()

// Ensure we're firing the right type of ammo
/obj/item/ego_weapon/ranged/pistol/crimson/before_firing(atom/target, mob/user)
	var/realization_active = FALSE
	if(ishuman(user))
		var/obj/item/clothing/suit/armor/ego_gear/realization/crimson/our_suit = user.get_item_by_slot(ITEM_SLOT_OCLOTHING)
		realization_active = istype(our_suit)
	SetAmmoStat(realization_active)
	. = ..()

// Lose Hollowpoint after firing it once
/obj/item/ego_weapon/ranged/pistol/crimson/process_chamber()
	. = ..()
	if(realization_hollowpoint_active)
		realization_hollowpoint_active = FALSE // You only get one Hollowpoint shot, load it again if you want another.
		SetAmmoStat(TRUE)

/obj/item/ego_weapon/ranged/pistol/crimson/proc/ToggleHollowpoint(mob/living/user)
	playsound(src, reload_start_sound, 50, TRUE)
	is_reloading = TRUE
	if(do_after(user, realization_hollowpoint_toggle_delay, src, timed_action_flags = IGNORE_USER_LOC_CHANGE, interaction_key = "crimscar_hollowpoint", max_interact_count = 1))
		realization_hollowpoint_active = !realization_hollowpoint_active // Load a Hollowpoint, or go back to normal I guess
		SetAmmoStat(TRUE) // We literally can't access this proc without the realization
		playsound(src, reload_success_sound, 50, TRUE)
		var/success_message = realization_hollowpoint_active ? "You will now fire a hollowpoint shell with [src]." : "You will now fire a storm of pellets with [src]."
		to_chat(user, span_info(success_message))
	is_reloading = FALSE

/// Sets the weapon's stats according to whether we're wearing Crimson Lust or not, this proc expects to be passed a bool for that rather than checking by itself.
/obj/item/ego_weapon/ranged/pistol/crimson/proc/SetAmmoStat(realized = FALSE)
	fire_delay = initial(fire_delay)
	pellets = initial(pellets)
	variance = initial(variance)
	spread = initial(spread)
	random_spread = initial(random_spread)


	if(!realized) // Not wearing Crimson Lust, go back to normal behaviour
		projectile_path = initial(projectile_path)
		reloadtime = initial(reloadtime)
		return

	reloadtime = 0 // We are wearing Crimson Lust, so we get infinite ammo

	if(realization_hollowpoint_active) // We have Hollowpoint loaded
		projectile_path = realization_hollowpoint_ammo_type // Realized hollowpoint ammo (consumes hemorrhage)
		fire_delay += realization_hollowpoint_firedelay_malus
		pellets = 1
		variance = 0
		spread = 0
		return

	// If we reach this point we're wearing Crimson Lust and not using Hollowpoint

	projectile_path = realization_default_ammo_type // Realized default ammo (piercing)

	if(realization_empowered_mode) // We're under the No Hesitation status
		fire_delay -= realization_empowered_firedelay_decrease
		pellets += realization_empowered_pellet_increase
		variance += realization_empowered_variance_increase
		spread += realization_empowered_spread_increase
		random_spread = TRUE

	return

/obj/item/ego_weapon/ranged/ecstasy
	name = "ecstasy"
	desc = "Tell the kid today's treat is going to be grape-flavored candy. It's his favorite."
	icon_state = "ecstasy"
	inhand_icon_state = "ecstasy"
	special = "This weapon fires slow bullets with limited range."
	force = 28
	damtype = WHITE_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_ecstasy
	weapon_weight = WEAPON_MEDIUM
	spread = 40
	fire_sound = 'sound/weapons/ego/ecstasy.ogg'
	autofire = 0.08 SECONDS
	shotsleft = 40
	reloadtime = 1.4 SECONDS
	attribute_requirements = list(
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60
	)

/obj/item/ego_weapon/ranged/pistol/praetorian
	name = "praetorian"
	desc = "And with her guard, she conquered all."
	icon_state = "praetorian"
	inhand_icon_state = "executive"
	special = "This weapon fires IFF bullets."
	force = 28
	projectile_path = /obj/projectile/ego_bullet/ego_praetorian
	fire_sound = 'sound/weapons/gun/pistol/tp17.ogg'
	autofire = 0.12 SECONDS
	shotsleft = 12
	reloadtime = 0.6 SECONDS
	fire_sound_volume = 30
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
	)

/obj/item/ego_weapon/ranged/pistol/magic_pistol
	name = "magic pistol"
	desc = "All the power of magic bullet, in a smaller package."
	icon_state = "magic_pistol"
	inhand_icon_state = "magic_pistol"
	special = "This weapon pierces most targets. This weapon fires and reloads faster with the matching armor"
	force = 17
	damtype = BLACK_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_magicpistol
	fire_delay = 7
	shotsleft = 7
	reloadtime = 1.2 SECONDS
	fire_sound = 'sound/abnormalities/freischutz/shoot.ogg'
	attribute_requirements = list(
							TEMPERANCE_ATTRIBUTE = 80
							)
	var/cached_multiplier

/obj/item/ego_weapon/ranged/pistol/magic_pistol/before_firing(atom/target, mob/user)
	if(cached_multiplier)
		projectile_damage_multiplier = cached_multiplier
	fire_delay = initial(fire_delay)
	var/mob/living/carbon/human/myman = user
	var/obj/item/clothing/suit/armor/ego_gear/he/magicbullet/Y = myman.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	var/obj/item/clothing/suit/armor/ego_gear/realization/bigiron/Z = myman.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(istype(Y))
		fire_delay = 5
	if(istype(Z))
		cached_multiplier = projectile_damage_multiplier
		projectile_damage_multiplier *= 2.5
		fire_delay = 5
	..()

/obj/item/ego_weapon/ranged/pistol/magic_pistol/reload_ego(mob/user)
	var/mob/living/carbon/human/myman = user
	var/obj/item/clothing/suit/armor/ego_gear/he/magicbullet/Y = myman.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	var/obj/item/clothing/suit/armor/ego_gear/realization/bigiron/Z = myman.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	reloadtime = initial(reloadtime)
	if(istype(Y) || istype(Z))
		reloadtime = 0.8 SECONDS
	..()

/obj/item/ego_weapon/ranged/pistol/laststop
	name = "last stop"
	desc = "There are no clocks to alert the arrival times."
	icon_state = "laststop"
	inhand_icon_state = "laststop"
	force = 17
	projectile_path = /obj/projectile/ego_bullet/ego_laststop
	weapon_weight = WEAPON_HEAVY
	fire_delay = 5
	shotsleft = 2
	reloadtime = 7 SECONDS
	roundsreload = TRUE
	fire_sound = 'sound/weapons/gun/shotgun/shot_auto.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80
							)

/obj/item/ego_weapon/ranged/intentions
	name = "good intentions"
	desc = "Go ahead and rattle 'em boys."
	special = "This weapon will periodically become more powerful as the lights on its side brighten, its damage and fire rate increasing. \n\
	The lights will brighten over time, and eventually dim. \n\
	Of course, nobody can know the arrival time."
	icon_state = "intentions"
	inhand_icon_state = "intentions"
	force = 17
	projectile_path = /obj/projectile/ego_bullet/ego_intention
	weapon_weight = WEAPON_MEDIUM
	spread = 24
	fire_sound = 'sound/weapons/gun/smg/mp7.ogg'
	autofire = 0.09 SECONDS
	shotsleft = 50
	reloadtime = 2.1 SECONDS
	attribute_requirements = list(
							PRUDENCE_ATTRIBUTE = 80
	)
	/// Reference to our autofire component so we can modify the firerate.
	var/datum/component/automatic_fire/autofire_component
	/// Holds a timer until the next light change.
	var/light_progress_timer
	/// How long each light should last...
	var/light_duration = 1 MINUTES
	/// ...however, the duration of the light may be up to [this value] shorter or longer.
	var/light_duration_variance = 20 SECONDS

	var/current_light = 0

	/// Associate current light to corresponding firerate, projectile damage multiplier and spread.
	var/alist/lights_to_stats = alist(
		0 = list("autofire" = 0.09 SECONDS, "multiplier" = 0, spread = 24),
		1 = list("autofire" = 0.08 SECONDS, "multiplier" = 0.3, spread = 26),
		2 = list("autofire" = 0.08 SECONDS, "multiplier" = 0.5, spread = 28),
		3 = list("autofire" = 0.07 SECONDS, "multiplier" = 0.6, spread = 30),
		4 = list("autofire" = 0.06 SECONDS, "multiplier" = 0.75, spread = 32),
		)

/obj/item/ego_weapon/ranged/intentions/Initialize(mapload)
	. = ..()
	autofire_component = GetComponent(/datum/component/automatic_fire)
	LightProgress(0)

/obj/item/ego_weapon/ranged/intentions/examine(mob/user)
	. = ..()
	. += span_warning("There are <b>[current_light] light(s)</b> burning on the side of the weapon.")

/obj/item/ego_weapon/ranged/intentions/proc/LightProgress(lights)
	if(!istype(autofire_component))
		return
	deltimer(light_progress_timer)
	if(!LAZYLEN(lights_to_stats))
		lights_to_stats = initial(lights_to_stats)

	// Remove whatever projectile damage multiplier we currently have on the gun, that is related to lights and not any external source
	projectile_damage_multiplier -= lights_to_stats[current_light]["multiplier"]

	// This is our new light value
	current_light = lights

	// Apply the new projectile damage multiplier on top of whatever we might have from EO upgrades/Faith&Promise
	projectile_damage_multiplier += lights_to_stats[current_light]["multiplier"]

	// Set the firerate & spread to whatever is appropiate now
	autofire = lights_to_stats[current_light]["autofire"] // This shouldn't be needed but keeps things consistent
	autofire_component.autofire_shot_delay = lights_to_stats[current_light]["autofire"]
	spread = lights_to_stats[current_light]["spread"]

	// Update object sprite
	var/new_icon_state = initial(icon_state)
	if(current_light > 0)
		new_icon_state += "_[current_light]"
	icon_state = new_icon_state
	inhand_icon_state = new_icon_state

	if(istype(src.loc, /mob/living/carbon/human)) // I know this is horrifying but I sadly don't know any procs that let us pull the holder of an item.
		var/mob/living/carbon/human/holder = src.loc
		holder.regenerate_icons()

	// Play a SFX and alert people that this thing changed
	if(current_light == 0)
		playsound(src, 'sound/abnormalities/clock/end.ogg', 50, 0)
		audible_message(span_notice("The lights on [src] fizzle out."))
	else
		playsound(src, 'sound/abnormalities/clock/turn_on.ogg', 50, 0)
		audible_message(span_notice("A new light flickers on [src]."))

	// Prepare the next light switch
	var/next_lights = current_light == 4 ? (0) : (current_light + 1)
	var/next_light_time = light_duration + (rand(-light_duration_variance, light_duration_variance))
	light_progress_timer = addtimer(CALLBACK(src, PROC_REF(LightProgress), (next_lights)), next_light_time, TIMER_STOPPABLE)

/obj/item/ego_weapon/ranged/aroma
	name = "faint aroma"
	desc = "Simply carrying it gives the illusion that you're standing in a forest in the middle of nowhere. \
			The arrowhead is dull and sprouts flowers of vivid color wherever it strikes."
	icon_state = "aroma"
	inhand_icon_state = "aroma"
	force = 28
	damtype = WHITE_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_aroma
	weapon_weight = WEAPON_HEAVY
	fire_delay = 25
	fire_sound = 'sound/weapons/ego/crossbow.ogg'
	attribute_requirements = list(
							PRUDENCE_ATTRIBUTE = 80
	)

/obj/item/ego_weapon/ranged/assonance
	name = "assonance"
	desc = "However, the world is more than simply warmth and light. The sky exists, for so does the land; darkness exists, \
				for so does light; life exists for so does death; hope exists for so does despair."
	icon_state = "assonance"
	inhand_icon_state = "assonance"
	special = "This weapon fires a hitscan beam. \nUpon hitting an enemy, this weapon heals a nearby Discord weapon user."
	force = 28
	damtype = WHITE_DAMAGE
	projectile_path = /obj/projectile/beam/assonance
	weapon_weight = WEAPON_HEAVY
	fire_delay = 10
	shotsleft = 8
	reloadtime = 1.6 SECONDS
	fire_sound = 'sound/weapons/gun/smg/mp7.ogg'
	attribute_requirements = list(
							PRUDENCE_ATTRIBUTE = 80
	)

//It's a magic sword. Cope Egor
/obj/item/ego_weapon/ranged/feather
	name = "feather of honor"
	desc = "A flaming, but very sharp, feather."
	icon_state = "featherofhonor"
	worn_icon_state = "featherofhonor"
	inhand_icon_state = "featherofhonor"
	projectile_path = /obj/projectile/ego_bullet/ego_feather
	weapon_weight = WEAPON_HEAVY
	special = "This weapon is highly effective in melee."
	force = 42
	damtype = WHITE_DAMAGE
	fire_delay = 12
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 60
	)

/obj/item/ego_weapon/ranged/exuviae
	name = "exuviae"
	desc = "A chunk of the naked nest inigrated with a launching mechanism."
	icon_state = "exuviae"
	inhand_icon_state = "exuviae"
	force = 33
	attack_speed = 1.3
	projectile_path = /obj/projectile/ego_bullet/ego_exuviae
	weapon_weight = WEAPON_HEAVY
	special = "Upon hit the targets RED vulnerability is increased by 0.2."
	damtype = RED_DAMAGE
	fire_delay = 30 //5 less than the Rend Armor status effect
	fire_sound = 'sound/misc/moist_impact.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60
	)

//Full manual bow-type E.G.O, must be loaded before firing.
/obj/item/ego_weapon/ranged/warring
	name = "feather of valor"
	desc = "A shimmering bow adorned with carved wooden panels. It crackes with arcing electricity."
	icon_state = "warring"
	inhand_icon_state = "warring"
	special = "This weapon can unleash a special attack by loading a second arrow."
	force = 28
	damtype = BLACK_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_warring
	weapon_weight = WEAPON_HEAVY
	fire_delay = 0//it caused some jank, like failing to charge after the do-after
	spread = 0
	//firing sound 1
	fire_sound = 'sound/weapons/bowfire.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
	)
	var/drawn = 0
	charge = TRUE
	attack_charge_gain = FALSE
	charge_cost = 3
	charge_effect = "fire a beam of electricity."
	var/ammo_2 = /obj/projectile/ego_bullet/ego_warring2

/obj/item/ego_weapon/ranged/warring/examine(mob/user)//attack speed isn't used, so it needs to be overridden
	. = ..()
	. -= span_notice("This weapon fires fast.")//it doesn't
	. += span_notice("This weapon must be loaded manually by activating it in your hand.")

/obj/item/ego_weapon/ranged/warring/can_shoot()
	if(drawn == 0)
		icon_state = "[initial(icon_state)]"
		return FALSE
	return TRUE

/obj/item/ego_weapon/ranged/warring/afterattack(atom/target, mob/user)
	. = ..()
	drawn = 0
	projectile_path = initial(projectile_path)
	icon_state = "[initial(icon_state)]"

/obj/item/ego_weapon/ranged/warring/attack_self(mob/user)
	switch(drawn)
		if(0)
			if(!do_after(user, 1 SECONDS, src, IGNORE_USER_LOC_CHANGE))
				return

			drawn  = 1
			to_chat(user, span_warning("You draw the [src] with all your might."))
			projectile_path = initial(projectile_path)
			fire_sound = 'sound/weapons/bowfire.ogg'
			icon_state = "warring_drawn"
		if(1)
			if(!do_after(user, 1, src, IGNORE_USER_LOC_CHANGE))
				return
			if(drawn != 1 || charge_amount < charge_cost)
				return
			drawn = 2
			charge_amount -= charge_cost
			projectile_path = ammo_2
			playsound(src, 'sound/magic/lightningshock.ogg', 50, TRUE)
			to_chat(user, span_warning("An arrow of lightning appears."))
			fire_sound = 'sound/abnormalities/thunderbird/tbird_beam.ogg'
			icon_state = "warring_firey"
		if(2)
			if(!do_after(user, 1, src, IGNORE_USER_LOC_CHANGE))
				return
			drawn = 1
			charge_amount += charge_cost
			projectile_path = initial(projectile_path)
			fire_sound = 'sound/weapons/bowfire.ogg'
			icon_state = "warring_drawn"
			to_chat(user, span_warning("The lightning fades."))

/// As of a rework in 2025/08, this weapon is a ranged weapon that can use stored bloodfeast to summon bat minions. It can also gather extra blood by melee attacking.
/obj/item/ego_weapon/ranged/banquet
	name = "banquet"
	desc = "Time for a feast! Enjoy the blood-red night imbued with madness to your heart’s content!"
	icon_state = "banquet"
	inhand_icon_state = "banquet"
	special = "This weapon is a staff that fires blood spikes in much the same way as a regular gun.\n\
	It is also able to store blood, automatically siphoning nearby blood and gaining a large amount on melee attacks. Alt-click the weapon to summon a friendly bat in exchange for blood.\n\
	The bat will fight by your side for a while, and will prioritize attacking the last target you shot with this weapon.\n\
	The duration, health and attack damage of your bats linearly scale off of your Temperance, the minimum values being at 80 Temperance and the maximum at 170."
	force = 44
	damtype = BLACK_DAMAGE
	attack_speed = 1.8
	projectile_path = /obj/projectile/ego_bullet/ego_banquet
	weapon_weight = WEAPON_MEDIUM
	fire_delay = 15
	shotsleft = 7
	reloadtime = 2.2 SECONDS
	fire_sound = 'sound/weapons/ego/banquet_fire.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60
	)
	actions_types = list(/datum/action/item_action/banquet_summon_bat)
	var/datum/component/bloodfeast/bloodfeast_component

	/// Blood gained per melee hit.
	var/base_melee_blood_gain = 160

	/// Holds a reference of all active summoned bats. The projectile this weapon fires will GiveTarget() to all of them on impact.
	var/list/bound_bats = list()
	/// How long does it take to spawn a bat?
	var/bat_spawn_windup = 0.8 SECONDS
	/// Avoiding multi-summons...
	var/summoning = FALSE
	/// How much blood does it take to spawn a bat? Consider: a bloodsplatter has 50 units. Also consider: blood is bugged and can have negative bloodiness (????)
	var/bat_spawn_cost = 1000

	/// How long do bats last by default? Increased by Temperance.
	var/bat_base_duration = 20 SECONDS
	/// How tough are bats? Increased by Temperance.
	var/bat_base_health = 145
	/// How hard do bats hit? Increased by Temperance.
	var/bat_base_damage = 14

	// Variables used for Temperance scaling increases to the base stats of a bat.
	var/bat_max_extra_duration = 70 SECONDS
	var/bat_max_extra_health = 230
	var/bat_max_extra_damage = 30
	/// At this, or below this Temperance level, bats have their base stats.
	var/bat_base_temperance = 80
	/// At this, or above this Temperance level, bats have their max stats.
	var/bat_max_temperance = 170

/// Recycled linear scaling from Eldtree Fairy Lure
/obj/item/ego_weapon/ranged/banquet/proc/LinearTempScalingMap(usertemp, max_increase)
	return floor(min(max_increase, ((usertemp - bat_base_temperance) * (max_increase) / (bat_max_temperance - bat_base_temperance))))

/// We need a Bloodfeast component.
/obj/item/ego_weapon/ranged/banquet/Initialize()
	. = ..()
	bloodfeast_component = AddComponent(/datum/component/bloodfeast, siphon = TRUE, range = 2, starting = 1000, threshold = 2600, max_amount = 2600)

/// Show stored blood on Examine.
/obj/item/ego_weapon/ranged/banquet/examine(mob/user)
	. = ..()
	if(bloodfeast_component)
		. += "It has [bloodfeast_component.blood_amount]/[bloodfeast_component.blood_cap] units of stored blood. Summoning a bat costs <b>[bat_spawn_cost] blood</b>."

/// Proc that changes the amount of blood in our bloodfeast component. Feed it negative values to drain, positive to add blood.
/obj/item/ego_weapon/ranged/banquet/proc/AdjustThirst(blood_amount)
	if(bloodfeast_component)
		bloodfeast_component.AdjustBlood(blood_amount)

/// Gain base melee blood gain * justice coeff blood units on melee attack.
/obj/item/ego_weapon/ranged/banquet/attack(mob/living/target, mob/living/carbon/human/user)
	if(!CanUseEgo(user))
		return
	if((!(target.status_flags & GODMODE)) && (target.stat != DEAD) && !(target in bound_bats)) // Do not drain blood off corpses, godmoded stuff or the bats we summoned ourselves.
		var/userjust = (get_modified_attribute_level(user, JUSTICE_ATTRIBUTE))
		var/justicemod = 1 + userjust/100
		AdjustThirst(base_melee_blood_gain * justicemod)
		playsound(get_turf(src), 'sound/abnormalities/nosferatu/bloodcollect.ogg', 18, 1)
	..()

/// Aesthetic: some bloodsplatters when you fire this staff.
/obj/item/ego_weapon/ranged/banquet/process_chamber()
	for(var/i in 1 to 2)
		new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(src), pick(GLOB.alldirs))
	..()

/// Summon a bat by alt-clicking this weapon.
/obj/item/ego_weapon/ranged/banquet/AltClick(mob/user)
	SummonBat(user)

/datum/action/item_action/banquet_summon_bat
	name = "Summon Bat"
	desc = "Spend blood to summon an allied bat to your side. Targets hit by Banquet projectiles will be prioritized by these bats."
	icon_icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	button_icon_state = "nosferatu_mob"

/datum/action/item_action/banquet_summon_bat/Trigger()
	if(!IsAvailable())
		return FALSE
	if(SEND_SIGNAL(src, COMSIG_ACTION_TRIGGER, src) & COMPONENT_ACTION_BLOCK_TRIGGER)
		return FALSE
	if(target && ismob(owner))
		var/obj/item/ego_weapon/ranged/banquet/I = target
		I.SummonBat(owner)
	return TRUE

/obj/item/ego_weapon/ranged/banquet/Destroy(force)
	for(var/mob/living/simple_animal/hostile/banquet_bat/minion in bound_bats)
		minion.master = null
		UnregisterSignal(minion, COMSIG_PARENT_QDELETING)
	bound_bats = null
	return ..()

/obj/item/ego_weapon/ranged/banquet/proc/SummonBat(mob/user)
	// Maybe don't let clerks carry this around to summon an army of bats
	if(!CanUseEgo(user))
		return FALSE
	if(!ishuman(user))
		return FALSE
	if(summoning)
		return FALSE
	var/mob/living/carbon/human/summoner = user

	var/datum/component/bloodfeast/bloodfeast = bloodfeast_component
	if(istype(bloodfeast) && bloodfeast.blood_amount >= bat_spawn_cost)
		summoning = TRUE
		if(do_after(summoner, bat_spawn_windup, timed_action_flags = IGNORE_HELD_ITEM))
			var/final_bat_duration = bat_base_duration
			var/final_bat_health = bat_base_health
			var/final_bat_damage = bat_base_damage

			var/user_temperance = (get_modified_attribute_level(summoner, TEMPERANCE_ATTRIBUTE))
			if((user_temperance > bat_base_temperance) && (bat_base_temperance != bat_max_temperance)) // Activate temp scaling if our temperance is above the minimum for scaling, and that second conditional is to avoid division by zero errors
				// I know this looks like a mess
				// We are essentially linearly mapping the user's temperance between the minimum temp scaling amount and maximum temp scaling amount to a value between 0 and the maximum of the respective scaling.
				// We use min() to ensure you can't get higher values than the maximum scaling allowed, and we use floor() to get rid of decimals.
				// Basically more temp = better
				var/scaled_extra_duration = LinearTempScalingMap(user_temperance, bat_max_extra_duration)
				var/scaled_extra_health = LinearTempScalingMap(user_temperance, bat_max_extra_health)
				var/scaled_extra_damage = LinearTempScalingMap(user_temperance, bat_max_extra_damage)

				final_bat_duration += scaled_extra_duration
				final_bat_health += scaled_extra_health
				final_bat_damage += scaled_extra_damage

			// Woah aesthetic bloodsplatters
			for(var/i in 1 to 4)
				new /obj/effect/temp_visual/dir_setting/bloodsplatter(get_turf(src), pick(GLOB.alldirs))

			// Now we spawn the new bat and set all of its stuff.
			var/mob/living/simple_animal/hostile/banquet_bat/minion = new(get_turf(src), summoner, final_bat_duration, final_bat_health, final_bat_damage)
			RegisterSignal(minion, COMSIG_PARENT_QDELETING, PROC_REF(DestructionCleanup))
			bound_bats += minion
			to_chat(user, span_notice("You use [src]'s stored blood to call forth a friendly bat."))
			playsound(src, 'sound/abnormalities/nosferatu/batspawn.ogg', 65, FALSE)
			AdjustThirst(-bat_spawn_cost)
			user.balloon_alert(user, "You call forth a friendly bat! Blood: ([bloodfeast.blood_amount]/[bloodfeast.blood_cap])")
			summoning = FALSE
			return TRUE
		else
			to_chat(user, span_danger("Your bat-summoning is interrupted!"))
			summoning = FALSE
			return FALSE
	else
		to_chat(user, span_danger("There's not enough blood stored in [src] to summon a bat. Blood: [bloodfeast.blood_amount]/[bloodfeast.blood_cap] (required [bat_spawn_cost])."))
		user.balloon_alert(user, "Not enough blood. ([bloodfeast.blood_amount] / [bat_spawn_cost])")
		return FALSE

/// Called by a signal when the bats are destroyed, removes them from the weapon's reference list of bats.
/obj/item/ego_weapon/ranged/banquet/proc/DestructionCleanup(mob/living/simple_animal/hostile/banquet_bat/destroyed)
	SIGNAL_HANDLER
	bound_bats -= destroyed
	UnregisterSignal(destroyed, COMSIG_PARENT_QDELETING)

// Jumpscare mob definition in the weapons file
/// This is a friendly minion spawned by the Banquet weapon from spending Bloodfeast. It will follow its master, help out for a while then explode.
// I'm making it its own type instead of a subtype of Nosferatu's because I don't want to inherit a bunch of its stuff like the bloodfeast component.
/mob/living/simple_animal/hostile/banquet_bat
	name = "\improper friendly-looking sanguine bat"
	desc = "It looks like a bat. This one doesn't seem hostile to humans. It doesn't seem to be long for this world..."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "nosferatu_mob"
	icon_living = "nosferatu_mob"
	icon_dead = "nosferatu_mob"
	faction = list("neutral") // From what I gather this is the players' faction? This will get set anyway
	is_flying_animal = TRUE
	density = FALSE
	speak_emote = list("screeches")
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	attack_sound = 'sound/abnormalities/nosferatu/bat_attack.ogg'
	health = 130
	maxHealth = 130
	damage_coeff = list(RED_DAMAGE = 1.2, WHITE_DAMAGE = 1.8, BLACK_DAMAGE = 0.6, PALE_DAMAGE = 2)
	melee_damage_type = RED_DAMAGE
	melee_damage_lower = 16
	melee_damage_upper = 20
	rapid_melee = 1.5
	move_to_delay = 1.3
	stat_attack = HARD_CRIT
	area_index = MOB_SIMPLEANIMAL_INDEX // Won't set off regen threat status
	del_on_death = FALSE // We have custom death behaviour, it will get QDEL'd eventually though

	// We kinda need these bats to have patrol behaviour but to not trigger it on their own.
	can_patrol = TRUE
	patrol_cooldown = INFINITY
	patrol_cooldown_time = INFINITY

	/// Will disappear after this timer ends. It's pretty important they don't last forever or people would build up armies of these.
	var/despawn_timer
	/// They'll recover (damage * [this_value]) health per hit.
	var/lifeleech_amount = 0.5
	/// Mob that used the staff to spawn the bats. We will follow them around.
	var/mob/living/master
	/// Coeff for melee damage dealt by our death explosion
	var/deathsplosion_coeff = 2.5
	// Vars that control how often bats can try to AStar back to their master
	var/recall_cooldown
	var/recall_cooldown_duration = 7 SECONDS
	/// Target issued by the staff wielder.
	var/atom/ordered_target
	/// This var is TRUE if we're currently AStar-ing towards a newly issued target.
	var/traveling = FALSE

/mob/living/simple_animal/hostile/banquet_bat/Initialize(mapload, mob/living/carbon/human/summoner, arg_duration = 20 SECONDS, arg_health = 120, arg_damage = 12)
	. = ..()
	if(istype(summoner))
		faction = summoner.faction.Copy()
		master = summoner

	despawn_timer = addtimer(CALLBACK(src, PROC_REF(Despawn)), arg_duration, TIMER_STOPPABLE)

	maxHealth = arg_health
	health = arg_health
	melee_damage_lower = arg_damage
	melee_damage_upper = melee_damage_lower + 3

	AddComponent(/datum/component/swarming, 10, 20) // Visually disperse bats on the same tile

/mob/living/simple_animal/hostile/banquet_bat/Life()
	. = ..()
	if(QDELETED(master))
		return
	// If we're not in combat and not in an ordered movement, and our master is moving away from us, follow them.
	if(!target && !traveling && master.z == src.z && (get_dist(master, src) > 3) && health > 0 && stat < DEAD) // Those last two checks are to avoid heading back to our master when dying
		// If our master is reachable directly, just use the normal walking proc
		if(CheckToolReach(src, master, vision_range))
			walk_to(src, master, 1, move_to_delay)
		// Otherwise, if we're not on cooldown, AStar towards our master.
		else if(recall_cooldown <= world.time)
			walk(src, 0)
			recall_cooldown = world.time + recall_cooldown_duration
			patrol_to(master)

// Small regen on hit.
/mob/living/simple_animal/hostile/banquet_bat/AttackingTarget(atom/attacked_target)
	. = ..()
	if(isliving(attacked_target))
		adjustBruteLoss(-(melee_damage_lower * lifeleech_amount))

// On death, call Despawn.
/mob/living/simple_animal/hostile/banquet_bat/death(gibbed)
	var/stored_target = target
	. = ..()
	target = stored_target
	INVOKE_ASYNC(src, PROC_REF(Despawn)) // This MUST be async or it causes some goofy behaviour

// Do a little exploding animation then delete the mob. Should be called when this mob times out or dies.
/mob/living/simple_animal/hostile/banquet_bat/proc/Despawn()
	deltimer(despawn_timer)

	toggle_ai(AI_OFF)
	if(ordered_target)
		walk_towards(src, ordered_target, move_to_delay)
	else if(target)
		walk_towards(src, target, move_to_delay)
	else
		walk(src, 0)
	density = FALSE
	anchored = TRUE

	var/matrix/M = matrix()
	animate(src, time = 0.2 SECONDS, transform = (M * 0.6))
	animate(time = 0.4 SECONDS, color = "#f76b6b", transform = M * 1.6)
	sleep(0.6 SECONDS)

	var/turf/our_turf = get_turf(src)
	if(our_turf)
		for(var/i in 1 to 4)
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(our_turf, pick(GLOB.alldirs))
		playsound(our_turf, 'sound/effects/ordeals/crimson/dusk_dead.ogg', 15, 1)

		new /obj/effect/decal/cleanable/blood(our_turf) // Believe it or not, this is a part of Banquet's balance

	qdel(src)

// When this mob is deleted by any means, if it still has a master, do a death explosion.
/mob/living/simple_animal/hostile/banquet_bat/Destroy(force)
	var/turf/our_turf = get_turf(src)
	if(!our_turf)
		return ..()
	var/list/surrounding_turfs = RANGE_TURFS(1, our_turf)
	if(QDELETED(master) || !istype(master))
		return ..()
	// Death explosion I guess
	var/list/hitlist = list()
	for(var/turf/T in surrounding_turfs)
		for(var/mob/living/L in T)
			if((faction_check_mob(L)) || (L.stat >= DEAD) || (L in hitlist))
				continue
			hitlist |= L
			L.deal_damage(melee_damage_lower * deathsplosion_coeff, melee_damage_type, source = master, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))
			L.visible_message(span_danger("[L] is splashed by a pressurised burst of blood from [src]!"), span_userdanger("You're splashed by a pressurised burst of blood from [src]!"))
	master = null
	return ..()

// The below section of code for this mob contains a bunch of annoying overrides and procs I had to make for them to be less dumb and be useful followers.
// A bunch of targeting/patrolling nonsense.

// For some reason I need to explicitly tell my batlings that they shouldn't be able to melee things that aren't adjacent to them, or else they start telekinetically biting stuff
/mob/living/simple_animal/hostile/banquet_bat/AttackCondition(atom/attack_target)
	. = TRUE
	if(!Adjacent(attack_target))
		return FALSE

// Always prioritize an ordered target.
/mob/living/simple_animal/hostile/banquet_bat/ValueTarget(atom/target_thing)
	if(target_thing == ordered_target)
		return INFINITY
	. = ..()

// Faction check bypassed against ordered targets. Careful with your FF :fausmol:
/mob/living/simple_animal/hostile/banquet_bat/faction_check_mob(mob/target, exact_match)
	if(ordered_target && (target == ordered_target))
		return FALSE
	. = ..()

// Called by the Banquet staff projectile to assign an ordered target.
/mob/living/simple_animal/hostile/banquet_bat/proc/ReceiveOrderedTarget(mob/living/victim)
	if(!istype(victim) || victim.stat >= DEAD)
		return

	// Replace any previously ordered target.
	if(ordered_target)
		UnregisterSignal(ordered_target, list(COMSIG_PARENT_QDELETING, COMSIG_LIVING_DEATH))
		ordered_target = null

	// Tiny little overlay to make it clear the bats swapped targets.
	var/mutable_appearance/warning = mutable_appearance('icons/effects/32x64.dmi', "nervous", -ABOVE_MOB_LAYER)
	add_overlay(warning)
	addtimer(CALLBACK(src, TYPE_PROC_REF(/atom, cut_overlay), warning), 1 SECONDS)

	ordered_target = victim
	RegisterSignal(victim, list(COMSIG_PARENT_QDELETING, COMSIG_LIVING_DEATH), PROC_REF(RemoveOrderedTarget))

	if(CheckToolReach(src, victim, vision_range)) // We are able to directly run at the target without any issues.
		GiveTarget(victim)
	else // Target is behind a wall, door, window, or outside our vision range.
		LoseTarget()
		traveling = TRUE
		patrol_to(get_turf(victim)) // Will path with AStar and open doors and whatnot

// When ending a patrol, if we have an ordered target and they're on our turf or within reach, go for them immediately.
/mob/living/simple_animal/hostile/banquet_bat/patrol_reset()
	. = ..()
	if((ordered_target) && (get_turf(src) == get_turf(ordered_target) || (CheckToolReach(src, ordered_target, vision_range))))
		GiveTarget(ordered_target)

// Cleanup signal handler proc called when an ordered target dies or is deleted.
/mob/living/simple_animal/hostile/banquet_bat/proc/RemoveOrderedTarget()
	SIGNAL_HANDLER
	UnregisterSignal(ordered_target, list(COMSIG_PARENT_QDELETING, COMSIG_LIVING_DEATH))
	ordered_target = null
	traveling = FALSE
	walk(src, 0)
	FindTarget()

/mob/living/simple_animal/hostile/banquet_bat/FindTarget(list/possible_targets, HasTargetsList)
	// If we have an ordered target and we can see them, stop our ordered movement and go right for them.
	if(!QDELETED(ordered_target) && (ordered_target in possible_targets) && CheckToolReach(src, ordered_target, vision_range))
		traveling = FALSE
		GiveTarget(ordered_target)
		return TRUE
	// If we're currently in an ordered movement, don't bother finding targets.
	else if(traveling)
		return
	. = ..()

// If we're in an ordered movement, add our ordered target as the only possible target if they're within reach, and if they're not, there are no possible targets.
/mob/living/simple_animal/hostile/banquet_bat/ListTargets(max_range)
	if(traveling)
		var/list/possible = list()
		if(CheckToolReach(src, ordered_target, vision_range))
			possible |= ordered_target
		return possible
	. = ..()

/obj/item/ego_weapon/ranged/blind_rage
	name = "Blind Fire"
	desc = "The pain inflicted by rash action and harsh words last longer than most think."
	icon_state = "blind_gun"
	special = "This weapon fires burning bullets. Watch out for friendly fire!"
	projectile_path = /obj/projectile/ego_bullet/ego_blind_rage
	force = 28
	damtype = BLACK_DAMAGE
	weapon_weight = WEAPON_HEAVY
	pellets = 4
	variance = 30
	fire_delay = 8
	shotsleft = 8
	reloadtime = 1.4 SECONDS
	fire_sound = 'sound/weapons/gun/shotgun/shot_auto.ogg'
	attribute_requirements = list(
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 80
							)

/obj/item/ego_weapon/ranged/my_own_bride
	name = "My own Bride"
	desc = "Simply carrying it gives the illusion that you're standing in a forest in the middle of nowhere. \
			The arrowhead is dull and sprouts flowers of vivid color wherever it strikes."
	icon_state = "wife"
	inhand_icon_state = "wife"
	force = 28
	damtype = WHITE_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_bride
	weapon_weight = WEAPON_HEAVY
	fire_delay = 5
	shotsleft = 10
	reloadtime = 0.2 SECONDS
	roundsreload = TRUE
	fire_sound = 'sound/weapons/gun/rifle/leveraction.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80
	)


/obj/item/ego_weapon/ranged/pistol/innocence
	name = "childhood memories"
	desc = "If no one had come in to get me, I would have stayed in that room, not even realizing the passing time."
	icon_state = "innocence_gun"
	inhand_icon_state = "innocence_gun"
	force = 17
	damtype = WHITE_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_innocence
	fire_sound = 'sound/abnormalities/orangetree/ding.ogg'
	vary_fire_sound = TRUE
	autofire = 0.2 SECONDS
	shotsleft = 32
	reloadtime = 2.1 SECONDS
	fire_sound_volume = 20
	attribute_requirements = list(
							PRUDENCE_ATTRIBUTE = 80
	)

/obj/item/ego_weapon/ranged/hypocrisy
	name = "hypocrisy"
	desc = "The tree turned out to be riddled with hypocrisy and deception; those who wear its blessing act in the name of bravery and faith."
	icon_state = "hypocrisy"
	inhand_icon_state = "hypocrisy"
	worn_icon_state = "hypocrisy"
	special = "Use this weapon in hand to place a trap that inflicts \
		50 RED damage and alerts the user of the area it was triggered."
	force = 28
	damtype = WHITE_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_hypocrisy
	weapon_weight = WEAPON_HEAVY
	fire_delay = 25
	fire_sound = 'sound/weapons/ego/crossbow.ogg'
	attribute_requirements = list(
							PRUDENCE_ATTRIBUTE = 80
	)
	var/trap_cooldown = 0

/obj/item/ego_weapon/ranged/hypocrisy/attack_self(mob/living/carbon/user)
	if(locate(/obj/structure/liars_trap) in range(1, get_turf(src)))
		to_chat(user,span_notice("Your too close to another trap."))
		return
	to_chat(user,span_notice("You pull out an arrow and attempt to stab it into the ground."))
	playsound(src, 'sound/items/crowbar.ogg', 50, TRUE)
	if(do_after(user, 3 SECONDS, src))
		if(trap_cooldown >= world.time)
			to_chat(user,span_notice("You cant place a sapling trap yet."))
			return
		playsound(get_turf(user), 'sound/creatures/venus_trap_hurt.ogg', 50, TRUE)
		var/obj/structure/liars_trap/c = new(get_turf(user))
		c.creator = user
		c.faction = user.faction.Copy()
		trap_cooldown = world.time + (10 SECONDS)

//Parasite Tree Ego Weapon Trap
/obj/structure/liars_trap
	gender = PLURAL
	name = "sapling trap"
	desc = "A small harmless looking sapling. Its leaves never seem to wilt."
	icon = 'ModularLobotomy/_Lobotomyicons/32x32.dmi'
	icon_state = "liars_trap"
	anchored = TRUE
	density = FALSE
	resistance_flags = FLAMMABLE
	max_integrity = 15
	var/mob/living/carbon/human/creator
	var/list/faction = list()

/obj/structure/liars_trap/Initialize()
	. = ..()
	if(creator)
		faction = creator.faction.Copy()

/obj/structure/liars_trap/Crossed(atom/movable/AM)
	. = ..()
	if(isliving(AM))
		var/mob/living/L = AM
		if(!faction_check(faction, L.faction))
			playsound(get_turf(src), 'sound/machines/clockcult/steam_whoosh.ogg', 10, 1)
			L.deal_damage(50, RED_DAMAGE, creator, flags = (DAMAGE_UNTRACKABLE), attack_type = (ATTACK_TYPE_ENVIRONMENT))
			new /obj/effect/temp_visual/cloud_swirl(get_turf(L)) //placeholder
			to_chat(creator, span_warning("You feel a itch towards [get_area(L)]."))
			qdel(src)

/obj/item/ego_weapon/ranged/fellbullet
	name = "fell bullet"
	desc = "A Lee-Einfeld bolt-action rifle that fires cursed bullets."
	icon_state = "fell_bullet"
	inhand_icon_state = "fell_bullet"
	special = "This weapon fires extremely slowly. \
		This weapon pierces all targets. \
		Activate in your hand to create a portal, which can be fired into. \
		Attempting to fire with an empty chamber will reload the weapon. \
		You can manually reload this weapon by pressing ALT + left mouse button."
	force = 28
	damtype = RED_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_fellbullet
	weapon_weight = WEAPON_HEAVY
	fire_delay = 20
	shotsleft = 1
	reloadtime = 0.5 SECONDS
	fire_sound = 'sound/abnormalities/fluchschutze/fell_bullet.ogg'
	var/portaling = FALSE
	var/portal_cooldown
	var/portal_cooldown_time = 15 SECONDS
	var/obj/effect/portal/myportal

	attribute_requirements = list(
							JUSTICE_ATTRIBUTE = 80
							)

/obj/item/ego_weapon/ranged/fellbullet/AltClick(mob/user)
	..()
	if(semicd)
		return
	return reload_ego(user)

/obj/item/ego_weapon/ranged/fellbullet/afterattack(atom/target, mob/living/user, flag, params)
	if(!CanUseEgo(user))
		return
	if(portaling)
		portaling = FALSE
		if(!LAZYLEN(get_path_to(src,target, TYPE_PROC_REF(/turf, Distance), 0, 24)))
			to_chat(user, span_notice("Target unreachable."))
			return
		var/obj/effect/portal/fellbullet/P1 = new(user)
		var/obj/effect/portal/fellbullet/P2 = new(get_turf(target))
		P1.link_portal(P2)
		P2.link_portal(P1)
		playsound(src, 'sound/abnormalities/fluchschutze/fell_magic.ogg', 50, TRUE)
		portal_cooldown = world.time + portal_cooldown_time
		myportal = P1
		return
	if(semicd)//stops firing speed anomalies
		return
	if(!can_shoot())
		reload_ego(user)
	..()
	if(!myportal)//If myportal hasn't initialized yet, this prevents it from runtiming.
		return
	if(myportal.loc && !is_reloading)//hide the portal
		myportal.forceMove(user)

/obj/item/ego_weapon/ranged/fellbullet/shoot_with_empty_chamber(mob/living/user as mob|obj)
	//do nothing

/obj/item/ego_weapon/ranged/fellbullet/attack_self(mob/user)
	if(portaling)
		portaling = FALSE
		to_chat(user,span_notice("You will no longer create a circle."))
		return
	if(portal_cooldown > world.time)
		to_chat(user,span_warning("You cannot create a magic circle yet!"))
		return
	portaling = TRUE
	to_chat(user,span_notice("You will now create a magic circle at your target."))

/obj/item/ego_weapon/ranged/fellbullet/reload_ego(mob/user)
	if(is_reloading)
		return
	if(myportal in user)//is it not qdeleted?
		myportal.forceMove(get_turf(user))//move the portal to your turf, line 733 removes it later.
		playsound(src, 'sound/abnormalities/fluchschutze/fell_portal.ogg', 50, FALSE)
	is_reloading = TRUE
	to_chat(user,span_notice("You chamber a round into [src]."))
	playsound(src, 'sound/abnormalities/fluchschutze/fell_aim.ogg', 50, TRUE)
	if(do_after(user, reloadtime, src)) //gotta reload
		shotsleft = initial(shotsleft)
		forced_melee = FALSE //no longer forced to resort to melee
	is_reloading = FALSE

/obj/effect/portal/fellbullet
	name = "magic circle"
	desc = "A circle of red magic featuring a six-pointed star "
	icon = 'icons/effects/effects.dmi'
	icon_state = "fellcircle"
	teleport_channel = TELEPORT_CHANNEL_FREE

/obj/effect/portal/fellbullet/teleport(atom/movable/M, force = FALSE)
	if(!istype(M, /obj/projectile/ego_bullet/ego_fellbullet))
		return
	var/obj/projectile/ego_bullet/ego_fellbullet/B = M
	if(B.damage > 80)
		return
	SpinAnimation(speed = 2, loops = 1, segments = 3, parallel = TRUE)//the abno version should always spin
	B.damage *= 2

	// Award achievement for using Fell Bullet's shotgun interaction (portal shooting)
	if(B.firer && ishuman(B.firer))
		var/mob/living/carbon/human/shooter = B.firer
		shooter.client?.give_award(/datum/award/achievement/lc13/fell_bullet, shooter)

	var/turf/real_target = get_link_target_turf()
	for(var/obj/effect/portal/fellbullet/P in real_target)
		P.SpinAnimation(speed = 5, loops = 1, segments = 3, parallel = TRUE)
		playsound(P, 'sound/abnormalities/fluchschutze/fell_portal.ogg', 50, TRUE)
		playsound(P, 'sound/abnormalities/fluchschutze/fell_bullet2.ogg', 50, TRUE)
	..()

/obj/effect/portal/fellbullet/attack_hand(mob/user)
//the parent behavior will pull you towards it

/obj/effect/portal/fellbullet/Initialize()
	INVOKE_ASYNC(src, PROC_REF(DoAnimation))//60% uptime
	return ..()

/obj/effect/portal/fellbullet/proc/DoAnimation()
	sleep(10 SECONDS)
	animate(src, alpha = 0, time = 1 SECONDS)
	QDEL_IN(src, 1 SECONDS)

/obj/item/ego_weapon/ranged/fellscatter
	name = "fell scatter"
	desc = "A bolt-action rifle fitted with a wider barrel. It fires cursed shells."
	icon_state = "fell_scatter"
	//TODO: inhands
	special = "Activate in your hand to load a magical slug. \
	The slug will penetrate most targets. Shooting a human will deal half damage and produce a special effect. \
	You can manually reload this weapon by pressing ALT + left mouse button."
	force = 28
	damtype = RED_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_fellscatter
	weapon_weight = WEAPON_HEAVY
	pellets = 7
	variance = 10
	fire_delay = 15
	shotsleft = 4
	reloadtime = 0.5 SECONDS
	fire_sound = 'sound/abnormalities/fluchschutze/fell_scatter.ogg'
	var/special_ammo = FALSE
	var/portal_cooldown
	var/portal_cooldown_time = 15 SECONDS
	var/ammo_2 = /obj/projectile/ego_bullet/special_fellbullet

	attribute_requirements = list(
							JUSTICE_ATTRIBUTE = 80
							)

/obj/item/ego_weapon/ranged/fellscatter/AltClick(mob/user)
	..()
	if(semicd)
		return
	return reload_ego(user)

/obj/item/ego_weapon/ranged/fellscatter/afterattack(atom/target, mob/living/user, flag, params)
	if(!CanUseEgo(user))
		return
	if(semicd)//stops firing speed anomalies
		return
	if(!can_shoot())
		reload_ego(user)
		return
	..()
	if(special_ammo)
		ChangeAmmo(user, special_ammo = TRUE)
		special_ammo = FALSE

/obj/item/ego_weapon/ranged/fellscatter/reload_ego(mob/user)
	if(shotsleft == initial(shotsleft))
		return
	is_reloading = TRUE
	to_chat(user,"<span class='notice'>You start loading a bullet.</span>")
	if(do_after(user, reloadtime, src)) //gotta reload
		playsound(src, 'sound/weapons/gun/shotgun/insert_shell.ogg', 50, TRUE)
		shotsleft +=1
		reload_ego(user)
	is_reloading = FALSE

/obj/item/ego_weapon/ranged/fellscatter/attack_self(mob/user)
	if(special_ammo)
		to_chat(user,span_notice("You remove the slug from [src]."))
		ChangeAmmo(special_ammo = TRUE)
		special_ammo = FALSE
		return
	if(shotsleft > 1)
		playsound(user, 'sound/weapons/gun/general/mag_bullet_remove.ogg', 50, TRUE)
		to_chat(user,span_notice("You discard your shells."))
		shotsleft = 0
	ChangeAmmo(user, special_ammo = FALSE)
	special_ammo = TRUE
	to_chat(user,span_notice("You will now fire a magical slug."))

/obj/item/ego_weapon/ranged/fellscatter/proc/ChangeAmmo(mob/living/user, special_ammo)
	if(special_ammo)
		fire_sound = initial(fire_sound)
		shotsleft = 0
		pellets = initial(pellets)
		variance = initial(variance)
		projectile_path = initial(projectile_path)
	else
		if(!do_after(user, 2 SECONDS, src))
			return
		fire_sound = 'sound/abnormalities/fluchschutze/fell_bullet.ogg'
		pellets = 1
		variance  = 0
		shotsleft = 1
		projectile_path = ammo_2
		playsound(src, 'sound/abnormalities/fluchschutze/fell_aim.ogg', 50, TRUE)
