//The Gun
/obj/item/ego_weapon/ranged/city/udjat
	name = "LCA Udjat Rifle"
	desc = "A rifle used by the LCA Udjat staff."
	icon_state = "udjat_gun"
	inhand_icon_state = "udjat_gun"
	force = 14
	damtype = WHITE_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_noise/udjat
	magazine_type = /obj/item/ego_mag/udjat
	magazine_name = "Udjat Magazine"
	ammo_name = "Udjat FMJ"
	weapon_weight = WEAPON_HEAVY
	pellets = 5
	variance = 15
	fire_delay = 10
	shotsleft = 16
	reloadtime = 1 SECONDS
	fire_sound = 'sound/weapons/gun/shotgun/shot_auto.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)

// Heavy gunner stuff
/obj/item/ego_weapon/ranged/city/udjat_sniper
	name = "Udjat Support Rifle"
	desc = "A sniper rifle used by Udjat gunners, accurate but bulky."
	icon_state = "udjat_gun"
	inhand_icon_state = "udjat_gun"
	ammo_name = "Udjat FMJ"
	weapon_weight = WEAPON_HEAVY
	force = 20
	damtype = WHITE_DAMAGE
	fire_sound = 'sound/weapons/gun/sniper/shot.ogg'
	zoom_amt = 10
	zoomable = TRUE
	zoom_out_amt = 5
	projectile_path = /obj/projectile/ego_bullet/ego_noise/udjat_sniper
	magazine_type = /obj/item/ego_mag/udjat_sniper
	magazine_name = "Udjat Sniper Rounds"
	shotsleft = 10
	fire_delay = 20
	reloadtime = 3 SECONDS
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)

/obj/projectile/ego_bullet/ego_noise/udjat_sniper
	name = "lca udjat sniper round"
	damage = 75

/obj/projectile/ego_bullet/ego_noise/udjat
	name = "lca udjat round"
	damage = 20

/obj/item/ego_mag/udjat_sniper
	name = "Udjat Sniper Rounds"
	desc = "Used for the Udjat SSW's sniper, load with care"
	icon = 'ModularLobotomy/_Lobotomyicons/lce_udjat_ammo.dmi'
	icon_state = "udjat_mag_birdshot"

/obj/item/ego_mag/udjat
	name = "udjat mag"
	desc = "load into an Udjat Gun."
	icon = 'ModularLobotomy/_Lobotomyicons/lc13_weapons.dmi'
	icon_state = "udjat_magazine"

/obj/item/ego_weapon/city/udjat_limbus
	name = "LCA Udjat Khopesh"
	desc = "A Khopesh used by the LCA Udjat ."
	special = "Use in hand to prepare a stun attack."
	icon_state = "udjat_khopesh"
	force = 55
	swingstyle = WEAPONSWING_LARGESWEEP
	damtype = RED_DAMAGE
	attack_verb_continuous = list("cleaves", "cuts")
	attack_verb_simple = list("cleaves", "cuts")
	hitsound = 'sound/weapons/fixer/generic/blade4.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)

	var/charged = FALSE

/obj/item/ego_weapon/city/udjat_limbus/attack(mob/living/M, mob/living/user)
	..()
	if(charged)
		M.apply_status_effect(/datum/status_effect/qliphothoverload)
		charged = FALSE

/obj/item/ego_weapon/city/udjat_limbus/attack_self(mob/user)
	if(charged)
		return
	if(do_after(user, 12, src))
		charged = TRUE
		to_chat(user,span_warning("Stun activated."))
		balloon_alert(user, "Stun activated.")


//Ever important weapon, the mask.
/obj/item/clothing/head/udjat
	name = "\improper Udjat mask"
	desc = "A mask worn by The Udjat, a mysterious Grade 1 Fixer office."
	icon_state = "udjat"
	icon = 'ModularLobotomy/_Lobotomyicons/lce_clothing.dmi'
	worn_icon = 'ModularLobotomy/_Lobotomyicons/lce_clothing_worn.dmi'
	flags_inv = HIDEFACIALHAIR | HIDEFACE | HIDEEYES | HIDEEARS | HIDESNOUT
	visor_flags_inv = 0
	dynamic_hair_suffix = ""

//Special Ammo types

/obj/item/ego_mag/udjat/highacc
	name = "udjat high-acc mag"
	desc = "Loaded with High-Accuracy bullets. \
		These bullets don't actually reduce the spread of the gun, but they have an easier time killing non-dense targets."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_udjat_ammo.dmi'
	icon_state = "udjat_mag_birdshot"
	ammo_type = /obj/projectile/ego_bullet/ego_noise/udjat/highacc
	ammo_name = "Udjat HIACC"

//non-dense mob. hit_nondense_targets is the engine's own switch for that - see can_hit_target().
/obj/projectile/ego_bullet/ego_noise/udjat/highacc
	name = "lca high accuracy"
	damage = 14
	hit_nondense_targets = TRUE




/obj/item/ego_mag/udjat/fracture
	name = "udjat fracture mag"
	desc = "Loaded with fracture rounds. Each one leaves a hairline break that does not close \
		on its own while the shooting continues."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_udjat_ammo.dmi'
	icon_state = "udjat_mag_fracture"
	ammo_type = /obj/projectile/ego_bullet/ego_noise/udjat/fracture
	ammo_name = "Udjat FRAC"

/obj/projectile/ego_bullet/ego_noise/udjat/fracture
	name = "lca fracture round"
	damage = 16

/obj/projectile/ego_bullet/ego_noise/udjat/fracture/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(!isliving(target))
		return
	var/mob/living/L = target
	//apply_status_effect refuses to touch a UNIQUE effect that already exists, so an existing
	//one has to be stacked by hand. This is how tremor's own callers do it.
	var/datum/status_effect/stacking/sheut_fracture/existing = L.has_status_effect(/datum/status_effect/stacking/sheut_fracture)
	if(existing)
		existing.add_stacks(1)
	else
		L.apply_status_effect(/datum/status_effect/stacking/sheut_fracture, 1)

/*			SHEUT FRACTURE			*/

/datum/status_effect/stacking/sheut_fracture
	id = "sheut_fracture"
	alert_type = /atom/movable/screen/alert/status_effect/sheut_fracture
	stacking_display_name = "fracture"
	max_stacks = 50
	tick_interval = 10 SECONDS
	consumed_on_threshold = FALSE
	///Set whenever a round lands, cleared by the tick that sees it. A tick that finds it already
	///clear is a tick where nobody kept shooting.
	var/new_stack = TRUE

/atom/movable/screen/alert/status_effect/sheut_fracture
	name = "Sheut Fracture"
	desc = "Something in you is broken along a line, and it is getting worse. Every step is slower."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_status.dmi'
	icon_state = "sheut_fracture"

/datum/status_effect/stacking/sheut_fracture/on_apply()
	. = ..()
	if(!.)
		return
	UpdateSlowdown()

/datum/status_effect/stacking/sheut_fracture/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/sheut_fracture)
	return ..()

/datum/status_effect/stacking/sheut_fracture/can_have_status()
	return (owner.stat != DEAD || !(owner.status_flags & GODMODE))

/datum/status_effect/stacking/sheut_fracture/proc/UpdateSlowdown()
	owner.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/sheut_fracture, \
		multiplicative_slowdown = stacks * 0.1)

//Unlike tremor, this DOES flag itself on a fresh stack. Tremor never sets new_stack back to TRUE,
//so it dies two ticks after the first application no matter how much more is applied - keeping
//pressure on a target has to actually mean something here.
/datum/status_effect/stacking/sheut_fracture/add_stacks(stacks_added)
	. = ..()
	if(stacks_added > 0)
		new_stack = TRUE
	if(!QDELETED(src) && owner)
		UpdateSlowdown()

//Every 10 seconds: if nothing landed since the last check, the break knits and half of it goes.
//Below six stacks there is nothing left worth tracking, so it clears itself.
/datum/status_effect/stacking/sheut_fracture/tick()
	if(new_stack)
		new_stack = FALSE
		return
	stacks = round(stacks * 0.5)
	if(stacks <= 5)
		qdel(src)
		return
	UpdateSlowdown()
	update_stacking_number()

/datum/movespeed_modifier/sheut_fracture
	multiplicative_slowdown = 0
	variable = TRUE

