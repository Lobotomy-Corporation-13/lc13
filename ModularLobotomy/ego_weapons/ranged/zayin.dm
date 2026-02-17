// All zayin pistols use the default 6 force for ego_gun pistols
/obj/item/ego_weapon/ranged/pistol/soda
	name = "soda pistol"
	desc = "A pistol painted in a refreshing purple. Whenever this EGO is used, a faint scent of grapes wafts through the air."
	special = "Perish while wearing matching armor and Wellcheers shrimp will arrive to mourn you."
	icon_state = "soda"
	inhand_icon_state = "soda"
	projectile_path = /obj/projectile/ego_bullet/ego_soda
	burst_size = 1
	fire_delay = 5
	shotsleft = 12
	reloadtime = 0.8 SECONDS
	fire_sound = 'sound/weapons/gun/pistol/shot.ogg'
	vary_fire_sound = FALSE
	fire_sound_volume = 70
	var/shrimp_chosen

/obj/item/ego_weapon/ranged/pistol/soda/pickup(mob/user)
	. = ..()
	shrimp_chosen = user
	RegisterSignal(shrimp_chosen, COMSIG_LIVING_DEATH, PROC_REF(ShrimpFuneral))

/obj/item/ego_weapon/ranged/pistol/soda/dropped(mob/user)
	. = ..()
	UnregisterSignal(shrimp_chosen, COMSIG_LIVING_DEATH)
	shrimp_chosen = null

/obj/item/ego_weapon/ranged/pistol/soda/Destroy(mob/user)
	if(shrimp_chosen)
		UnregisterSignal(shrimp_chosen, COMSIG_LIVING_DEATH)
	shrimp_chosen = null
	return ..()

/obj/item/ego_weapon/ranged/pistol/soda/proc/ShrimpFuneral(mob/user)
	var/obj/item/clothing/suit/armor/ego_gear/zayin/soda/S = user.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(istype(S))
		user.playsound_local(get_turf(user), 'sound/abnormalities/wellcheers/shrimptaps.ogg', 50, 0)
		for(var/i in 1 to 2)
			new /mob/living/simple_animal/hostile/shrimp/grieving(get_turf(user))

/obj/item/ego_weapon/ranged/pistol/nostalgia
	name = "nostalgia"
	desc = "An old-looking pistol made of wood"
	special = "Use this weapon in your hand when wearing matching armor to heal the SP of others nearby."
	icon_state = "nostalgia"
	inhand_icon_state = "nostalgia"
	projectile_path = /obj/projectile/ego_bullet/ego_nostalgia
	fire_sound = 'sound/weapons/gun/pistol/shot.ogg'
	vary_fire_sound = FALSE
	fire_sound_volume = 70
	fire_delay = 12

	var/pulse_startup
	var/pulse_startup_time = 10 SECONDS
	var/pulse_cooldown = 1 SECONDS
	var/pulse_healing = -0.5 //negative damage
	var/pulse_enabled = FALSE

/obj/item/ego_weapon/ranged/pistol/nostalgia/attack_self(mob/user)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(pulse_startup > world.time)
		to_chat(H, "<span class='warning'>You have used this ability too recently!</span>")
		return
	pulse_startup = world.time + pulse_startup_time
	var/obj/item/clothing/suit/armor/ego_gear/zayin/nostalgia/N = H.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(istype(N))
		pulse_enabled = TRUE
		to_chat(H, "<span class='warning'>You use the [src] to emit sanity healing pulses!</span>")
		H.playsound_local(get_turf(H), 'sound/abnormalities/old_lady/oldlady_debuff.ogg', 25, 0)
		HealPulse(user, 0)
	else
		pulse_enabled = FALSE
		to_chat(H, "<span class='warning'>You must have the corrosponding armor equipped to use this ability!</span>")

/obj/item/ego_weapon/ranged/pistol/nostalgia/dropped(mob/user)
	. = ..()
	pulse_enabled = FALSE

/obj/item/ego_weapon/ranged/pistol/nostalgia/Destroy(mob/user)
	. = ..()
	pulse_enabled = FALSE

/obj/item/ego_weapon/ranged/pistol/nostalgia/proc/HealPulse(mob/living/carbon/human/user, count)
	if(!pulse_enabled)
		return
	if(count >= 10)
		return
	for(var/mob/living/carbon/human/L in livinginview(4, user))
		if(L.stat == DEAD || L == user || L.is_working) //no self-healing
			continue
		L.adjustSanityLoss(pulse_healing)
		to_chat(L, "<span class='nicegreen'>A pulse from [user] makes your mind feel a bit clearer.</span>")
	addtimer(CALLBACK(src, PROC_REF(HealPulse), user, count += 1), pulse_cooldown)

/obj/item/ego_weapon/ranged/pistol/nightshade
	name = "nightshade"
	desc = "Strange that it was more than just a bleeding person in a vegetative state."
	special = "If you are wearing the matching armor, fired shots will heal friendlies on hit."
	icon_state = "nightshade"
	inhand_icon_state = "nightshade"
	damtype = BLACK_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_nightshade
	burst_size = 1
	fire_delay = 10
	fire_sound = 'sound/weapons/bowfire.ogg'
	vary_fire_sound = FALSE
	fire_sound_volume = 50

/obj/item/ego_weapon/ranged/pistol/nightshade/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0, temporary_damage_multiplier = 1)
	var/obj/item/clothing/suit/armor/ego_gear/zayin/nightshade/C = user.get_item_by_slot(ITEM_SLOT_OCLOTHING)
	if(istype(C))
		projectile_path = /obj/projectile/ego_bullet/ego_nightshade/healing
	else
		projectile_path = /obj/projectile/ego_bullet/ego_nightshade
	return ..()

/obj/item/ego_weapon/ranged/pistol/oceanic
	name = "a taste of the ocean"
	desc = "A pistol painted in a refreshing orange. Whenever this EGO is used, a faint scent of orange wafts through the air."
	icon_state = "oceanic"
	inhand_icon_state = "oceanic"
	damtype = WHITE_DAMAGE
	projectile_path = /obj/projectile/ego_bullet/ego_oceanic
	burst_size = 1
	fire_delay = 5
	shotsleft = 7
	reloadtime = 1.2 SECONDS
	fire_sound = 'sound/weapons/gun/pistol/shot.ogg'
	vary_fire_sound = FALSE
	fire_sound_volume = 70

