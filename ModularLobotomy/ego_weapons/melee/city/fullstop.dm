//Guns that gotta be reloaded.
/obj/item/ego_weapon/ranged/city/fullstop
	name = "fullstop template"
	desc = "a template for fullstop."
	icon_state = "fullstop"
	inhand_icon_state = "fullstop"
	force = 14
	projectile_path = /obj/projectile/ego_bullet/tendamage
	weapon_weight = WEAPON_HEAVY
	fire_sound = 'sound/weapons/gun/rifle/shot_alt.ogg'
	special = "Use in hand to reload"
	shotsleft = 10
	reloadtime = 2 SECONDS

	magazine_type = /obj/item/ego_mag/fullstop
	magazine_name = "Fullstop Magazine"
	ammo_name = "Fullstop FMJ"

//The actual weapons
/obj/item/ego_weapon/ranged/city/fullstop/assault
	name = "fullstop assault gun"
	desc = "A heavy rifle. Guns like these are expensive in the City. You could buy a whole other weapon of good quality with the money for this one's bullets."
	icon_state = "fullstop"
	inhand_icon_state = "fullstop"
	force = 20
	fire_sound = 'sound/weapons/gun/rifle/shot_alt.ogg'
	projectile_path = /obj/projectile/ego_bullet/fullstop_rifle
	shotsleft = 60	//Extendo Mag.
	reloadtime = 3 SECONDS

	autofire = 0.15 SECONDS
	spread = 10
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)


/obj/item/ego_weapon/ranged/city/fullstop/pistol
	name = "fullstop pistol"
	desc = "A fullstop pistol. Looks familiar."
	icon_state = "fullstoppistol"
	inhand_icon_state = "fullstopsniper"
	weapon_weight = WEAPON_LIGHT
	ammo_name = "Fullstop 9mm"
	force = 12
	attack_speed = 0.5
	shotsleft = 17	//It's a G17 lol
	projectile_path = /obj/projectile/ego_bullet/fullstop_pistol
	fire_delay = 5
	reloadtime = 1.3 SECONDS
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)

/obj/item/ego_weapon/ranged/city/fullstop/sniper
	name = "fullstop sniper"
	desc = "A sniper rifle. Despite the cost and heavy regulations, you could still kill someone stealthily from a good distance with this."
	icon_state = "fullstopsniper"
	inhand_icon_state = "fullstopsniper"
	ammo_name = "Fullstop Heavy FMJ"
	force = 20
	fire_sound = 'sound/weapons/gun/sniper/shot.ogg'
	zoom_amt = 10 //Long range, enough to see in front of you, but no tiles behind you.
	zoomable = TRUE
	zoom_out_amt = 5
	projectile_path = /obj/projectile/ego_bullet/fullstop_sniper
	shotsleft = 10
	fire_delay = 20
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)

/obj/item/ego_weapon/ranged/city/fullstop/deagle
	name = "fullstop magnum"
	desc = "An expensive pistol. Keep your hands steady. It's not over yet."
	icon_state = "fullstopdeagle"
	inhand_icon_state = "fullstopdeagle"
	ammo_name = "Fullstop .50 Action Express"
	force = 17
	attack_speed = 0.5
	projectile_path = /obj/projectile/ego_bullet/fullstop_deagle
	fire_sound = 'sound/weapons/gun/rifle/shot_alt.ogg'
	shotsleft = 9
	reloadtime = 1 SECONDS
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)

/obj/item/ego_weapon/ranged/city/fullstop/lmg
	name = "fullstop light machine gun"
	desc = "An lmg. The bullets were gotten on sale. \
		Guns like these are expensive in the City. You could buy a whole other weapon of good quality with the money for this one's bullets."
	icon_state = "fullstoplmg"
	inhand_icon_state = "fullstoplmg"
	force = 20
	fire_sound = 'sound/weapons/gun/rifle/shot_alt.ogg'
	projectile_path = /obj/projectile/ego_bullet/fullstop_lmg
	shotsleft = 200
	reloadtime = 5 SECONDS

	autofire = 0.12 SECONDS
	spread = 10
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 60,
							PRUDENCE_ATTRIBUTE = 60,
							TEMPERANCE_ATTRIBUTE = 60,
							JUSTICE_ATTRIBUTE = 60
							)

/obj/item/ego_mag/fullstop
	name = "fullstop magazine"
	desc = "Load into fullstop guns of various types."
	icon_state = "fullstop_ammo"


//finally they get they own bullets.

/obj/projectile/ego_bullet/fullstop_rifle
	name = "bullet"
	damage = 17

/obj/projectile/ego_bullet/fullstop_lmg
	name = "bullet"
	damage = 10

/obj/projectile/ego_bullet/fullstop_pistol
	name = "bullet"
	damage = 22	//You get way less per mag.

/obj/projectile/ego_bullet/fullstop_sniper
	name = "bullet"
	damage = 80	//This SHOULD almost kill someone.

/obj/projectile/ego_bullet/fullstop_deagle
	name = "bullet"
	damage = 45	//It's 50AE.
