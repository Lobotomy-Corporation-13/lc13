/obj/item/ego_weapon/ranged/sodarifle
	name = "soda rifle"
	desc = "A gun used by shrimp corp, apparently."
	icon_state = "sodarifle"
	inhand_icon_state = "sodalong"
	force = 14 // These guns don't have any stat requirements so they won't do high damage
	projectile_path = /obj/projectile/ego_bullet/ego_soda/rifle
	weapon_weight = WEAPON_HEAVY
	fire_delay = 3
	fire_sound = 'sound/weapons/gun/rifle/shot.ogg'

/obj/item/ego_weapon/ranged/sodashotty
	name = "soda shotgun"
	desc = "A gun used by shrimp corp, apparently."
	icon_state = "sodashotgun"
	inhand_icon_state = "sodalong"
	force = 18
	attack_speed = 1.3
	projectile_path = /obj/projectile/ego_bullet/ego_soda
	pellets = 3
	variance = 12
	weapon_weight = WEAPON_HEAVY
	fire_delay = 10
	fire_sound = 'sound/weapons/gun/shotgun/shot.ogg'

/obj/item/ego_weapon/ranged/sodasmg
	name = "soda submachinegun"
	desc = "A gun used by shrimp corp, apparently."
	icon_state = "sodasmg"
	inhand_icon_state = "soda"
	force = 14
	projectile_path = /obj/projectile/ego_bullet/ego_soda
	weapon_weight = WEAPON_HEAVY
	spread = 8
	fire_sound = 'sound/weapons/gun/smg/shot.ogg'
	autofire = 0.15 SECONDS

//My sweet orange tree - The cure
/obj/item/ego_weapon/ranged/flammenwerfer
	name = "flamethrower"
	desc = "A shitty flamethrower, great for clearing out infested areas and people."
	special = "Use this in-hand to cover yourself in flames. To prevent infection, of course."
	icon = 'icons/obj/flamethrower.dmi'
	lefthand_file = 'icons/mob/inhands/weapons/flamethrower_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/flamethrower_righthand.dmi'
	icon_state = "flamethrower1"
	inhand_icon_state = "flamethrower_1"
	projectile_path = /obj/projectile/ego_bullet/flammenwerfer
	weapon_weight = WEAPON_HEAVY
	spread = 50
	fire_sound = 'sound/effects/burn.ogg'
	autofire = 0.08 SECONDS
	fire_sound_volume = 5

/obj/item/ego_weapon/ranged/flammenwerfer/attack_self(mob/user)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(do_after(H, 12, src))
		to_chat(H,"<span class='warning'>You cover yourself in flames!</span>")
		H.playsound_local(get_turf(H), 'sound/effects/burn.ogg', 100, 0)
		H.deal_damage(10, RED_DAMAGE, flags = (DAMAGE_FORCED))
		H.adjust_fire_stacks(1)
		H.IgniteMob()

//Nihil Upgrade
/obj/item/ego_weapon/ranged/hatred_nihil
	name = "pointless hate"
	desc = "If I am on the side of good, then someone has to be on the side of evil. Without someone to play the villain, I can’t exist."
	icon_state = "hate"
	inhand_icon_state = "hate"
	fire_delay = 1
	autofire = 0.5 SECONDS
	special = "This weapon heals humans that it hits."
	force = 56
	damtype = BLACK_DAMAGE
	weapon_weight = WEAPON_HEAVY
	projectile_path = /obj/projectile/ego_bullet/ego_hatred
	fire_sound = 'sound/abnormalities/hatredqueen/attack.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 80,
							PRUDENCE_ATTRIBUTE = 100,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 80
							)
	var/can_blast = TRUE
	var/blasting = FALSE
	var/blast_damage = 150

/obj/item/ego_weapon/ranged/hatred_nihil/proc/Recharge(mob/user)
	can_blast = TRUE
	to_chat(user,"<span class='nicegreen'>Arcana beats is ready to fire again.</span>")

/obj/item/ego_weapon/ranged/hatred_nihil/attack_self(mob/user)
	if(!CanUseEgo(user))
		return
	if(!can_blast)
		to_chat(user,"<span class='warning'>You attacked too recently.</span>")
		return
	can_blast = FALSE
	var/obj/effect/qoh_sygil/S = new(get_turf(src))
	S.icon_state = "qoh1"
	switch(user.dir)
		if(EAST)
			S.pixel_x += 16
			var/matrix/new_matrix = matrix()
			new_matrix.Scale(0.5, 1)
			S.transform = new_matrix
			S.layer = (src.layer + 0.1)
		if(WEST)
			S.pixel_x += -16
			var/matrix/new_matrix = matrix()
			new_matrix.Scale(0.5, 1)
			S.transform = new_matrix
			S.layer = (src.layer + 0.1)
		if(SOUTH)
			S.pixel_y += -16
			S.layer = (src.layer + 0.1)
		if(NORTH)
			S.pixel_y += 16
			S.layer -= 0.1
	addtimer(CALLBACK(S, TYPE_PROC_REF(/obj/effect/qoh_sygil, fade_out)), 3 SECONDS)
	if(do_after(user, 15, src))
		var/aoe = blast_damage
		var/userjust = (get_attribute_level(user, JUSTICE_ATTRIBUTE))
		var/justicemod = 1 + userjust/100
		var/firsthit = TRUE //One target takes full damage
		var/turf/stepturf = (get_step(get_step(user, user.dir), user.dir))
		playsound(src, 'sound/abnormalities/hatredqueen/gun.ogg', 65, FALSE, 4)
		aoe*=justicemod
		for(var/turf/T in range(2, stepturf))
			new /obj/effect/temp_visual/revenant(T)
		for(var/mob/living/L in range(2, stepturf)) //knocks enemies away from you
			if(L == user || ishuman(L))
				continue
			L.deal_damage(aoe, BLACK_DAMAGE, user, attack_type = (ATTACK_TYPE_SPECIAL))
			if(firsthit)
				aoe = (aoe / 2)
				firsthit = FALSE
			var/throw_target = get_edge_target_turf(L, get_dir(L, get_step_away(L, src)))
			if(!L.anchored)
				var/whack_speed = (prob(60) ? 1 : 4)
				L.throw_at(throw_target, rand(1, 2), whack_speed, user)
	addtimer(CALLBACK(src, PROC_REF(Recharge), user), 15 SECONDS)

/obj/item/ego_weapon/ranged/pyrogx //Grungeon-exclusive ranged weapon with two firemodes
	name = "pyro-GX prototype"
	desc = "A clunky-looking, highly mechanical gun salvaged from a factory in the Outskirts."
	icon_state = "gaze"
	inhand_icon_state = "gaze"
	fire_delay = 1 //Many dakka for the hitscan mode
	autofire = 0.1 SECONDS
	special = "This weapon can swap modes by using it inhand, with the Vulcan Cannon firing hitscan bullets and the Smart Missiles firing rockets which burst into homing projectiles."
	force = 30
	damtype = RED_DAMAGE
	weapon_weight = WEAPON_HEAVY
	vary_fire_sound = FALSE
	projectile_path = /obj/projectile/beam/vulcan
	fire_sound = 'sound/weapons/gun/rifle/gauss.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 100
							)

/obj/item/ego_weapon/ranged/pyrogx/attack_self(mob/user)


/obj/item/ego_weapon/ranged/plastest
	name = "plasma test gun"
	desc = "A gun made for testing plasma rounds."
	icon_state = "gaze"
	inhand_icon_state = "gaze"
	fire_delay = 8.5
	special = "This weapon can swap modes by using it inhand, with the Vulcan Cannon firing hitscan bullets and the Smart Missiles firing rockets which burst into homing projectiles."
	force = 30
	damtype = RED_DAMAGE
	weapon_weight = WEAPON_HEAVY
	vary_fire_sound = FALSE
	projectile_path = /obj/projectile/ego_bullet/smart_missile
	fire_sound = 'sound/weapons/gun/rifle/vulcan.ogg'
	attribute_requirements = list(
							FORTITUDE_ATTRIBUTE = 100,
							PRUDENCE_ATTRIBUTE = 80,
							TEMPERANCE_ATTRIBUTE = 80,
							JUSTICE_ATTRIBUTE = 100
							)
