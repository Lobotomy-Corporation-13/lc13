/obj/item/grenade/r_corp
	name = "r-corp red grenade"
	desc = "An anti-abnormality grenade, this weapon excels at damaging abnormality using the tech from L-Corp. It deals 90% less damage to humans."
	icon_state = "r_corp"
	var/explosion_damage_type = RED_DAMAGE
	var/explosion_damage = 200
	var/explosion_range = 2
	var/carbon_damagemod = 0.1

/obj/item/grenade/r_corp/attack_self(mob/user)
	if(user.mind)
		if(user.mind.has_antag_datum(/datum/antagonist/wizard/arbiter/rcorp))
			to_chat(user, span_notice("You wouldn't stoop so low as to use the weapons of those below you.")) //You are an arbiter not a demoman
			return FALSE
	..()

/obj/item/grenade/r_corp/detonate(mob/living/lanced_by)
	var/aThrower = thrower
	. = ..()
	update_mob()
	new /obj/effect/temp_visual/explosion(get_turf(src))
	playsound(loc, 'sound/effects/ordeals/steel/gcorp_boom.ogg', 75, TRUE)
	for(var/mob/living/simple_animal/H in view(explosion_range, src))
		H.deal_damage(explosion_damage, explosion_damage_type, aThrower, attack_type = (ATTACK_TYPE_SPECIAL))
	for(var/mob/living/carbon/C in view(explosion_range, src))
		C.deal_damage(C == aThrower ? explosion_damage * 0.5 : explosion_damage * carbon_damagemod, explosion_damage_type, aThrower, attack_type = (ATTACK_TYPE_SPECIAL))
	qdel(src)

/obj/item/grenade/r_corp/white
	name = "r-corp white grenade"
	icon_state = "r_corp_white"
	explosion_damage_type = WHITE_DAMAGE

/obj/item/grenade/r_corp/black
	name = "r-corp black grenade"
	icon_state = "r_corp_black"
	explosion_damage_type = BLACK_DAMAGE

/obj/item/grenade/r_corp/pale
	name = "r-corp pale grenade"
	icon_state = "r_corp_pale"
	explosion_damage_type = PALE_DAMAGE
	explosion_damage = 150

/obj/item/grenade/r_corp/thumb
	name = "frag grenade"
	desc = "An anti-personnel fragmentation grenade, this weapon is used by the Thumb."
	icon_state = "frag"
	explosion_damage = 200	//Dude if you get hit by this you dumb as fuck
	carbon_damagemod = 1
	det_time = 20


/obj/item/grenade/r_corp/pyro
	name = "r-corp pyro grenade"
	desc = "An incendiary grenade that sets everything ablaze. Highly effective against biological targets."
	icon_state = "r_corp_pyro"
	explosion_damage = 100 // Half the normal damage
	carbon_damagemod = 0.2 // Still reduced damage to humans

/obj/item/grenade/r_corp/pyro/detonate(mob/living/lanced_by)
	var/aThrower = thrower
	. = ..()
	update_mob()
	new /obj/effect/temp_visual/explosion(get_turf(src))
	playsound(loc, 'sound/effects/ordeals/steel/gcorp_boom.ogg', 75, TRUE)

	// Deal RED damage like normal
	for(var/mob/living/simple_animal/H in view(explosion_range, src))
		H.deal_damage(explosion_damage, explosion_damage_type, source = aThrower, attack_type = (ATTACK_TYPE_SPECIAL))
	for(var/mob/living/carbon/C in view(explosion_range, src))
		C.deal_damage(C == aThrower ? explosion_damage * 0.5 : explosion_damage * carbon_damagemod, explosion_damage_type, source = aThrower, attack_type = (ATTACK_TYPE_SPECIAL))

	// Apply burn and create fire
	for(var/turf/T in view(explosion_range, src))
		if(!locate(/obj/effect/turf_fire) in T)
			new /obj/effect/turf_fire(T)
		for(var/mob/living/L in T)
			L.apply_lc_burn(30)

	qdel(src)

/obj/effect/spawner/lootdrop/grenade
	name = "rcorp grenade spawner"
	lootdoubles = FALSE

	loot = list(
			/obj/item/grenade/r_corp = 3,
			/obj/item/grenade/r_corp/white = 3,
			/obj/item/grenade/r_corp/black = 3,
			/obj/item/grenade/r_corp/pale = 1,
		)

/obj/item/grenade/lobotomy
	name = "anti-abnormality red grenade"
	desc = "A modified version of the grenades used by R-Corp's packs, it features a qliphoth deterrance after effect as well as making the abnormalities fragile against their respect damage types."
	var/explosion_damage_type = RED_DAMAGE
	var/explosion_damage = 50
	var/explosion_range = 2
	icon_state = "r_corp"

/obj/item/grenade/lobotomy/detonate(mob/living/lanced_by) //does not do dmg to humans, there's a lot of weird gimmick stuff that relates to taking dmg in facility
	var/aThrower = thrower
	. = ..()
	update_mob()
	new /obj/effect/temp_visual/explosion(get_turf(src))
	playsound(loc, 'sound/effects/ordeals/steel/gcorp_boom.ogg', 75, TRUE)
	for(var/mob/living/simple_animal/H in view(explosion_range, src))
		H.deal_damage(explosion_damage, explosion_damage_type, aThrower, attack_type = (ATTACK_TYPE_SPECIAL))
		switch(explosion_damage_type)
			if(RED_DAMAGE)
				H.apply_lc_red_fragile(5)
			if(WHITE_DAMAGE)
				H.apply_lc_white_fragile(5)
			if(BLACK_DAMAGE)
				H.apply_lc_black_fragile(5)
			if(PALE_DAMAGE)
				H.apply_lc_pale_fragile(5)
		H.apply_status_effect(/datum/status_effect/qliphothoverload)
	qdel(src)

/obj/item/grenade/lobotomy/white
	name = "anti-abnormality white grenade"
	icon_state = "r_corp_white"
	explosion_damage_type = WHITE_DAMAGE

/obj/item/grenade/lobotomy/black
	name = "anti-abnormality black grenade"
	icon_state = "r_corp_black"
	explosion_damage_type = BLACK_DAMAGE

/obj/item/grenade/lobotomy/pale
	name = "anti-abnormality pale grenade"
	icon_state = "r_corp_pale"
	explosion_damage_type = PALE_DAMAGE

/obj/item/storage/box/lobotomygrenades
	name = "box of grenades"
	desc = "A box, it has a small lobotomy corporation logo on the back."

/obj/item/storage/box/lobotomygrenades/PopulateContents()
	var/static/items_inside = list(
		/obj/item/grenade/lobotomy = 3,
		/obj/item/grenade/lobotomy/white = 3,
		/obj/item/grenade/lobotomy/black = 3,
		/obj/item/grenade/lobotomy/pale = 2)
	generate_items_inside(items_inside,src)
