//Placed in combat for being very frontal
/mob/living/simple_animal/hostile/rcorp_abno/hard/clown
	name = "Clown Smiling at Me"
	desc = "An unnerving clown."
	maxHealth = 1800
	health = 1800
	rapid_melee = 4
	melee_queue_distance = 4
	damage_coeff = list(BRUTE = 1.0, RED_DAMAGE = 1.0, WHITE_DAMAGE = 1.0, BLACK_DAMAGE = 1.3, PALE_DAMAGE = 1.5)
	melee_damage_lower = 20 //Increased damage due to being fragile
	melee_damage_upper = 20
	melee_damage_type = RED_DAMAGE
	see_in_dark = 10
	stat_attack = DEAD
	move_to_delay = 2.3 //Faster because this is a hardteam combatant and its fragile
	speak_chance = 2
	ranged = TRUE
	ranged_cooldown_time = 1.5 SECONDS //Shortened ranged cooldown to encourage knife spam
	projectiletype = /obj/projectile/clown_throw_rca
	del_on_death = FALSE
	original_abno = /mob/living/simple_animal/hostile/abnormality/clown

	var/finishing = FALSE
	var/step = FALSE
	var/finishing_small_damage = 12
	var/finishing_big_damage = 80 //Damage on finishing small and big increased due to corpses being a primary resource for abnos

	abno_additional_instructions = "<h1>You are Clown Smiling at Me, A Combat Role Abnormality.</h1><br>\
		<b>|Dark Carnival|: When you click on a tile which is outside your melee range, you will throw a knife towards that tile. Your knife will deal no damage to abnormalities, and will pass through them. \
		If you hit a human with this knife, you will deal RED damage to them, slow them down massively and inflict 8 'Bleed'. \
		Also, You blades are able to bounch against walls! Each time they bounch against a wall, their damage will be doubled! \
		Your blades also go through friendly abnormalities, however do note they are also easily stopped by obstacles.<br>\
		<br>\
		|Jovial Cutting|: When you attack a dead human, you will start rapidly gutting them, which will deal WHITE damage to all humans watching. \
		A few seconds after gutting that human, you will gib them.<br>\
		<br>\
		|Bleed|: When a target with bleed moves, they will take True damage equal to the stack, then it reduces by half. \
		They may prevent this by either standing still until the stack expires or walking instead of running. <br>\
		<br>\
		|A Show’s End|: Once you reach 0 HP, you will explode which deal great RED damage to nearby humans, inflict 30 'Bleed' and leave behind a few trails of lube, which can slip humans who cross them.</b>"

//A clown isn't a clown without his shoes
/mob/living/simple_animal/hostile/rcorp_abno/hard/clown/Initialize()
	. = ..()
	icon_state = "clown_breach"
	pixel_y = 0
	base_pixel_y = 0
	AddElement(/datum/element/waddling)
	playsound(get_turf(src), 'sound/abnormalities/clownsmiling/announce.ogg', 75, 1)

/mob/living/simple_animal/hostile/rcorp_abno/hard/clown/Moved()
	. = ..()
	if(step)
		playsound(get_turf(src), 'sound/effects/clownstep2.ogg', 30, 0, 3)
		step = FALSE
		return
	playsound(get_turf(src), 'sound/effects/clownstep1.ogg', 30, 0, 3)
	step = TRUE

//Execution code from green dawn with inflated damage numbers
/mob/living/simple_animal/hostile/rcorp_abno/hard/clown/CanAttack(atom/the_target)
	if(isliving(the_target) && !ishuman(the_target))
		var/mob/living/L = the_target
		if(L.stat == DEAD)
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/clown/AttackingTarget(atom/attacked_target)
	. = ..()
	if(.)
		if(!ishuman(attacked_target))
			return
		var/mob/living/carbon/human/TH = attacked_target
		if(TH.health < 0)
			finishing = TRUE
			TH.Stun(4 SECONDS)
			forceMove(get_turf(TH))
			for(var/i = 1 to 7)
				if(!targets_from.Adjacent(TH) || QDELETED(TH))
					finishing = FALSE
					return
				TH.attack_animal(src)
				for(var/mob/living/carbon/human/H in ohearers(7, get_turf(src)))
					H.deal_damage(finishing_small_damage, WHITE_DAMAGE, src, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))
				SLEEP_CHECK_DEATH(2)
			if(!targets_from.Adjacent(TH) || QDELETED(TH))
				finishing = FALSE
				return
			playsound(get_turf(src), 'sound/abnormalities/clownsmiling/final_stab.ogg', 50, 1)
			TH.gib()
			for(var/mob/living/carbon/human/H in ohearers(7, get_turf(src)))
				H.deal_damage(finishing_big_damage, WHITE_DAMAGE, src, flags = (DAMAGE_FORCED), attack_type = (ATTACK_TYPE_SPECIAL))

/mob/living/simple_animal/hostile/rcorp_abno/hard/clown/MoveToTarget(list/possible_targets)
	if(ranged_cooldown <= world.time)
		OpenFire(target)
	return ..()

// Prevents knife throwing in mele range
/mob/living/simple_animal/hostile/rcorp_abno/hard/clown/OpenFire(atom/A)
	if(get_dist(src, A) <= 2) //no shooty in mele
		return FALSE
	return ..()

//Death explosion
/mob/living/simple_animal/hostile/rcorp_abno/hard/clown/death(gibbed)
	animate(src, transform = matrix()*1.8, color = "#FF0000", time = 20)
	addtimer(CALLBACK(src, PROC_REF(DeathExplosion)), 20)
	..()

/mob/living/simple_animal/hostile/rcorp_abno/hard/clown/proc/DeathExplosion()
	if(QDELETED(src))
		return
	visible_message(span_danger("[src] suddenly explodes!"))
	playsound(get_turf(src), 'sound/abnormalities/clownsmiling/announcedead.ogg', 75, 1)
	for(var/mob/living/L in view(5, src))
		if(!faction_check_mob(L))
			L.deal_damage(25, RED_DAMAGE, attack_type = (ATTACK_TYPE_SPECIAL))
			L.apply_lc_bleed(30)
	new /obj/effect/particle_effect/foam(get_turf(src))
	gib()

/obj/projectile/clown_throw_rca
	name = "blade"
	desc = "A blade thrown maliciously"
	icon_state = "clown"
	damage_type = RED_DAMAGE
	nodamage = TRUE
	damage = 0
	projectile_piercing = PASSMOB
	ricochets_max = 2
	ricochet_chance = 100
	ricochet_decay_chance = 1
	ricochet_decay_damage = 2
	ricochet_auto_aim_range = 3
	ricochet_incidence_leeway = 0

/obj/projectile/clown_throw_rca/Initialize()
	. = ..()
	SpinAnimation()

/obj/projectile/clown_throw_rca/check_ricochet_flag(atom/A)
	if(istype(A, /turf/closed))
		return TRUE
	return FALSE

/obj/projectile/clown_throw_rca/on_hit(atom/target, blocked = FALSE)
	if(ishuman(target))
		damage = 5
		nodamage = FALSE
		var/mob/living/carbon/human/H = target
		H.apply_lc_bleed(6)
		H.add_movespeed_modifier(/datum/movespeed_modifier/clowned)
		addtimer(CALLBACK(H, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/clowned), 1 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE)
		qdel(src)

	if(isrcabnormalitymob(target))
		to_chat(target, "The [src] flies right past you!")
		return
	..()
