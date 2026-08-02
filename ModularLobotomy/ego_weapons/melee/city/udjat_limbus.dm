//The Gun
/obj/item/ego_weapon/ranged/city/udjat
	name = "noise"
	desc = "The noises take you back to the very moment of the day that everyone had forgotten."
	icon_state = "udjat_gun"
	inhand_icon_state = "udjat_gun"
	force = 14
	damtype = WHITE_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_noise
	magazine_name = "Udjat Magazine"
	weapon_weight = WEAPON_HEAVY
	pellets = 5
	variance = 20
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
	force = 40
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
