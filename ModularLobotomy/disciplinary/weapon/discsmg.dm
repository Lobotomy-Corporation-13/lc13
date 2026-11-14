//Guns that gotta be reloaded.
//These sprites are all temporary

/obj/item/ego_weapon/ranged/discsmg
	name = "disciplinary smg V1"
	desc = "a rifle used by the discipline team. Loads into either red or white damage."
	icon = 'ModularLobotomy/_Lobotomyicons/discweapons.dmi'
	icon_state = "lsmg"
	inhand_icon_state = "lsmg"
	force = 14
	projectile_path = /obj/projectile/ego_bullet/discsmg
	weapon_weight = WEAPON_MEDIUM
	fire_sound = 'sound/weapons/gun/smg/mp7.ogg'
	autofire = 0.08 SECONDS
	fire_delay = 1
	shotsleft = 40
	reloadtime = 1.2 SECONDS

	magazine_type = /obj/item/ego_mag/discsmg
	magazine_name = "Discipline SMG Magazine"
	ammo_name = "Discipline SMG (Red)"

/obj/item/ego_mag/discsmg
	name = "discipline smg mag (red)"
	desc = "Load into the discipline SMG."
	icon = 'ModularLobotomy/_Lobotomyicons/discweapons.dmi'
	icon_state = "smg_magazine"
	ammo_type = /obj/projectile/ego_bullet/discsmg
	ammo_name = "Discipline SMG (Red)"

/obj/item/ego_mag/discsmg/white
	name = "discipline smg mag (white)"
	desc = "Loaded with white damage."
	icon = 'ModularLobotomy/_Lobotomyicons/discweapons.dmi'
	icon_state = "smg_magazinew"
	ammo_type = /obj/projectile/ego_bullet/discsmg_white
	ammo_name = "Discipline SMG (White)"

/obj/projectile/ego_bullet/discsmg
	name = "disc round"
	damage = 8
	damage_type = RED_DAMAGE

/obj/projectile/ego_bullet/discsmg_white
	name = "disc white round"
	damage = 8
	damage_type = WHITE_DAMAGE
