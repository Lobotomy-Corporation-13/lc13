//The Gun
/obj/item/ego_weapon/ranged/city/udjat
	name = "LCA Udjat Rifle"
	desc = "A rifle used by the LCA Udjat staff."
	icon_state = "udjat_gun"
	inhand_icon_state = "udjat_gun"
	force = 14
	damtype = WHITE_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_noise/udjat
	magazine_name = "Udjat Magazine"
	weapon_weight = WEAPON_HEAVY
	pellets = 5
	variance = 15
	fire_delay = 10
	shotsleft = 16
	reloadtime = 1 SECONDS
	fire_sound = 'sound/weapons/gun/shotgun/shot_auto.ogg'
	magazine_type = /obj/item/udjat_mag
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)


/obj/projectile/ego_bullet/ego_noise/udjat
	name = "lca udjat round"
	damage = 20

/obj/item/udjat_mag
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


//Ever important weapon, the mask. On the mask slot, so it does not fight a helmet for the head.
/obj/item/clothing/mask/udjat
	name = "\improper Udjat mask"
	desc = "A mask worn by The Udjat, a mysterious Grade 1 Fixer office."
	icon_state = "udjat"
	icon = 'ModularLobotomy/_Lobotomyicons/lce_clothing.dmi'
	worn_icon = 'ModularLobotomy/_Lobotomyicons/lce_clothing_worn.dmi'
	flags_inv = HIDEFACIALHAIR | HIDEFACE | HIDEEYES | HIDEEARS | HIDESNOUT
	visor_flags_inv = 0
	dynamic_hair_suffix = ""


//The below is discontinued until a magazine refactor is completed.

/*
// ============================ SPECIALIST AMMUNITION ============================
// The rifle reloads by being hit with a magazine, and the stock reload does not care which one -
// it just refills the counter. These magazines carry the round they are loaded with, and the
// rifle's attackby swaps its projectile to match, so which box you brought actually matters.

/*			MAGAZINES			*/

/obj/item/udjat_mag
	name = "udjat birdshot mag"
	desc = "Loaded with birdshot. The spread is wide enough to catch things that are not \
		properly there."
	///The round this magazine is loaded with. Read off by the rifle on a successful reload.
	var/loaded_projectile = /obj/projectile/ego_bullet/ego_noise/udjat
	///Shown to whoever reloads, so they know what they just chambered.
	var/round_name = "standard"

/obj/item/udjat_mag/examine(mob/user)
	. = ..()
	. += span_notice("Loaded with [round_name] rounds.")

/obj/item/udjat_mag/birdshot
	name = "udjat birdshot mag"
	desc = "Loaded with birdshot. The spread is wide enough to catch things that are not \
		properly there."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_udjat_ammo.dmi'
	icon_state = "udjat_mag_birdshot"
	loaded_projectile = /obj/projectile/ego_bullet/ego_noise/udjat/birdshot
	round_name = "birdshot"

/obj/item/udjat_mag/fracture
	name = "udjat fracture mag"
	desc = "Loaded with fracture rounds. Each one leaves a hairline break that does not close \
		on its own while the shooting continues."
	icon = 'ModularLobotomy/_Lobotomyicons/lce_udjat_ammo.dmi'
	icon_state = "udjat_mag_fracture"
	loaded_projectile = /obj/projectile/ego_bullet/ego_noise/udjat/fracture
	round_name = "fracture"

/obj/item/ego_weapon/ranged/city/udjat/examine(mob/user)
	. = ..()
	. += span_notice("Chambered: [loaded_round_name] rounds.")

//The stock attackby refills the counter and qdels the magazine, but never touches the projectile.
//Everything here is read BEFORE ..(), because after it the magazine is gone.
/obj/item/ego_weapon/ranged/city/udjat/attackby(obj/item/I, mob/user, params)
	if(!istype(I, /obj/item/udjat_mag))
		return ..()
	var/obj/item/udjat_mag/mag = I
	var/new_projectile = mag.loaded_projectile
	var/new_name = mag.round_name
	. = ..()
	//The parent returns nothing useful and bails silently on a fumbled reload, so a deleted
	//magazine is the only reliable signal that the reload actually happened.
	if(!QDELETED(mag))
		return
	projectile_path = new_projectile
	loaded_round_name = new_name
	to_chat(user, span_notice("[src] is now firing [new_name] rounds."))

/*			ROUNDS			*/

//Punishing Bird spends most of its time non-dense, and a normal bullet sails straight past a
//non-dense mob. hit_nondense_targets is the engine's own switch for that - see can_hit_target().
/obj/projectile/ego_bullet/ego_noise/udjat/birdshot
	name = "lca birdshot round"
	damage = 14
	hit_nondense_targets = TRUE

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
*/
